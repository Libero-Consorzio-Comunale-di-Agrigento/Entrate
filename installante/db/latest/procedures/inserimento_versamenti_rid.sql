--liquibase formatted sql 
--changeset abrandolini:20250326_152423_inserimento_versamenti_rid stripComments:false runOnChange:true 
 
create or replace procedure INSERIMENTO_VERSAMENTI_RID
      ( a_tipo_tributo in varchar2
      , a_ruolo        in number
      , a_utente       in varchar2
      , a_messaggio   out varchar2)
    IS
    w_data_pagamento       date;
    w_vers_gia_presente    number;
    w_versamenti_inseriti  number := 0;
    w_errore               varchar2(2000);
    errore                 exception;
cursor sel_fatt (p_ruolo number) is
  select fatt.cod_fiscale       cod_fiscale
       , fatt.fattura           fattura
       , fatt.anno              anno
       , fatt.importo_totale    importo_totale
    from fatture         fatt
       , ( select fattura
                , ruolo
             from oggetti_imposta
            where fattura is not null
           group by fattura
                  , ruolo
         )               ogim
       , ruoli           ruol
   where nvl(fatt.flag_delega,'N') = 'S'
     and fatt.fattura = ogim.fattura
     and ogim.ruolo   = p_ruolo
     and fatt.fattura not in (select riim.fattura
                                from rid_impagati riim
                               where riim.ruolo = p_ruolo
                              )
       ;
BEGIN
   begin
     select ruol.scadenza_prima_rata
       into w_data_pagamento
       from ruoli           ruol
      where ruol.ruolo = a_ruolo
        ;
   EXCEPTION
      WHEN others THEN
         w_errore := ('Errore recupero Data Scadenza Ruolo '|| to_char(a_ruolo) || ' (' || SQLERRM || ')' );
         raise errore;
   end;
   for rec_fatt in sel_fatt(a_ruolo) loop
      -- Verifica presenza versamento
      w_vers_gia_presente := 0;
      begin
         select count(1)
           into w_vers_gia_presente
           from versamenti
          where anno         = rec_fatt.anno
            and cod_fiscale  = rec_fatt.cod_fiscale
            and tipo_tributo = 'TARSU'
            and importo_versato = rec_fatt.importo_totale
            and data_pagamento  = w_data_pagamento
              ;
      EXCEPTION
         when no_data_found then
            w_vers_gia_presente := 0;
         WHEN others THEN
            w_errore := ('Errore in verifica versamenti cf:'|| rec_fatt.cod_fiscale || ' (' || SQLERRM || ')' );
            raise errore;
      end;
      if w_vers_gia_presente = 0 then
         begin
            insert into versamenti
                 ( cod_fiscale
                 , anno
                 , tipo_tributo
                 , rata
                 , data_pagamento
                 , importo_versato
                 , fattura
                 , ruolo
                 , fonte
                 , utente
                 , note)
          values ( rec_fatt.cod_fiscale
                 , rec_fatt.anno
                 , a_tipo_tributo
                 , 1
                 , w_data_pagamento
                 , rec_fatt.importo_totale
                 , rec_fatt.fattura
                 , a_ruolo
                 , 21
                 , a_utente
                 , ''
                 )
               ;
         EXCEPTION
            WHEN others THEN
               w_errore := ('Errore in inserimento versamento di '|| rec_fatt.cod_fiscale || ' (' || SQLERRM || ')' );
               raise errore;
         end;
         w_versamenti_inseriti := w_versamenti_inseriti + 1;
      end if;
   end loop;
   -- Aggiornamento Stato Ruolo
   begin
      update ruoli
         set stato_ruolo = 'RID_CARICATI'
       where ruolo = a_ruolo
       ;
   EXCEPTION
      WHEN others THEN
          w_errore := 'Errore in Aggiornamento stato_ruolo '
                    ||'('||SQLERRM||')';
         RAISE errore;
   end;
   a_messaggio := 'Versamenti Inseriti: '||to_char(w_versamenti_inseriti);
EXCEPTION
   WHEN errore THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20999,w_errore);
  WHEN others THEN
       ROLLBACK;
       RAISE_APPLICATION_ERROR
       (-20999,'Errore in Inserimento Versamenti RID - ('||SQLERRM||')');
END;
/* End Procedure: INSERIMENTO_VERSAMENTI_RID */
/

