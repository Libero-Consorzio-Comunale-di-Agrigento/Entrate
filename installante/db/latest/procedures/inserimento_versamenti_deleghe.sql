--liquibase formatted sql 
--changeset abrandolini:20250326_152423_inserimento_versamenti_deleghe stripComments:false runOnChange:true 
 
create or replace procedure INSERIMENTO_VERSAMENTI_DELEGHE
      ( a_tipo_tributo IN varchar2,
        a_anno         IN number,
        a_ruolo        IN number,
        a_rata         IN number )
    IS
    w_data_pagamento date;
    w_errore         varchar2(2000);
    errore           exception;
CURSOR sel_vers
     ( p_tipo_tributo varchar2
     , p_ruolo        number
     , p_rata         number ) IS
select deba.cod_fiscale
      ,ogim.oggetto_imposta
      ,raim.rata_imposta
      ,raim.imposta importo_versato
  from deleghe_bancarie deba
      ,ruoli_contribuente ruco
      ,oggetti_imposta ogim
      ,rate_imposta raim
 where deba.tipo_tributo    = p_tipo_tributo
   and deba.cod_fiscale     = ruco.cod_fiscale
   and ruco.ruolo           = p_ruolo
   and ogim.oggetto_imposta = ruco.oggetto_imposta
   and raim.oggetto_imposta = ogim.oggetto_imposta
   and raim.rata            = p_rata
   and not exists          (select 'x'
                              from versamenti vers
                             where vers.rata_imposta = raim.rata_imposta)
 order by deba.cod_fiscale;
BEGIN
  BEGIN
    select decode(a_rata
                 ,0,ruol.scadenza_prima_rata
                 ,1,ruol.scadenza_prima_rata
                 ,2,ruol.scadenza_rata_2
                 ,3,ruol.scadenza_rata_2
                 ,4,ruol.scadenza_rata_2
                 )
           data_scadenza
      into w_data_pagamento
      from ruoli ruol
     where ruol.ruolo = a_ruolo
     ;
  EXCEPTION
    WHEN others THEN
      w_errore := 'Errore in ricerca data scadenza della rata per il ruolo'
                  ||' - ('||SQLERRM||')';
      RAISE errore;
  END;
  w_errore := 'Errore: verificare le scadenze sul Ruolo';
  RAISE errore;
  FOR rec_vers
      IN sel_vers (a_tipo_tributo, a_ruolo, a_rata)
  LOOP
    BEGIN
      insert into versamenti
            (cod_fiscale, anno, tipo_tributo, oggetto_imposta, rata_imposta,
             rata, data_pagamento, importo_versato, fonte, utente, data_variazione, data_reg )
      values (rec_vers.cod_fiscale, a_anno, a_tipo_tributo, rec_vers.oggetto_imposta,
              rec_vers.rata_imposta, a_rata, w_data_pagamento, rec_vers.importo_versato,
              6, 'TR4', trunc(sysdate), trunc(sysdate) );
    EXCEPTION
      WHEN others THEN
        w_errore := 'Errore in inserimento versamenti '||
                    ' per '||rec_vers.cod_fiscale||' - ('||SQLERRM||')';
        RAISE errore;
    END;
  END LOOP;
EXCEPTION
   WHEN errore THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20999,w_errore);
  WHEN others THEN
       ROLLBACK;
       RAISE_APPLICATION_ERROR
       (-20999,'Errore in Inserimento Versamenti - ('||SQLERRM||')');
END;
/* End Procedure: INSERIMENTO_VERSAMENTI_DELEGHE */
/

