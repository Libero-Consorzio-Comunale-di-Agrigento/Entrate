--liquibase formatted sql 
--changeset abrandolini:20250326_152423_trasmissione_sgravio stripComments:false runOnChange:true 
 
create or replace procedure TRASMISSIONE_SGRAVIO
(a_ruolo      IN number,
 a_da_num   IN number,
 a_a_num   IN number,
 a_da_data   IN date,
 a_a_data   IN date
)
IS
w_cod_ente            varchar2(8);
w_data_elaborazione      number:=0;
w_numero_protocollo      varchar2(15);
w_num_articolo         number:=0;
w_ni_prec         number:=0;
CURSOR sel_sgra IS
    select sogg.ni,
           sogg.tipo,
            decode(sogg.tipo,
             0,
           rpad(substr(nvl(sogg.cognome,' '),1,25),25)||rpad(substr(nvl(sogg.nome,' '),1,25),25)||
              rpad(substr(nvl(comu.denominazione,' '),1,30),30)||rpad(to_char(sogg.data_nas,'ddmmyyyy'),8)||
              rpad(nvl(cont.cod_fiscale,' '),16),
             rpad(substr(nvl(sogg.cognome_nome,' '),1,50),50)||rpad(nvl(cont.cod_fiscale,' '),11))
            dati_contribuente,
            lpad(ruco.tributo,4,'0') tributo,
               ruol.anno_ruolo,
           ruol.anno_emissione anno_emissione,
           decode(sign(ruol.anno_emissione-1999),-1,
            'S',
           'D') tipo_provvedimento,
            lpad(to_char(
            round(ruco.importo
                 * (100 + decode(ruol.importo_lordo
                                ,'S',0
                                    ,(nvl(cata.addizionale_pro  ,0) +
                                      nvl(cata.addizionale_eca  ,0) +
                                      nvl(cata.maggiorazione_eca,0) +
                                      nvl(cata.aliquota         ,0)
                                     )
                                )
                   ) / 100
                 ,2
                 ) * 100),15,'0') importo_ruolo,
            lpad(to_char(
            round(sgra.importo
                 * (100 + decode(ruol.importo_lordo
                                ,'S',0
                                    ,(nvl(cata.addizionale_pro  ,0) +
                                      nvl(cata.addizionale_eca  ,0) +
                                      nvl(cata.maggiorazione_eca,0) +
                                      nvl(cata.aliquota         ,0)
                                     )
                                )
                   ) / 100
                 ,2
                 ) * 100),15,'0') importo_sgravio,
            sgra.cod_concessione,
            sgra.num_ruolo
       from ad4_comuni comu,
            soggetti sogg, contribuenti cont, carichi_tarsu cata,
            ruoli ruol, sgravi sgra, ruoli_contribuente ruco
      where comu.comune          (+) = sogg.cod_com_nas
        and comu.provincia_stato (+) = sogg.cod_pro_nas
        and sogg.ni               = cont.ni
        and cont.cod_fiscale      = ruco.cod_fiscale
        and ruol.ruolo            = ruco.ruolo
        and sgra.ruolo            = ruco.ruolo
        and sgra.cod_fiscale      = ruco.cod_fiscale
        and sgra.sequenza         = ruco.sequenza
        and cata.anno    (+)      = ruol.anno_ruolo
        and ruco.ruolo            = a_ruolo
        and ((sgra.data_elenco between a_da_data and a_a_data)
             and (sgra.numero_elenco between a_da_num and a_a_num))
      order by sogg.ni
   ;
/*
Estrazione dei dati del Comune, commentata ma.....
potrebbe servire per eventuali personalizzazioni alla procedure
  BEGIN
    select lpad(to_char(pro_cliente),3,'0')||lpad(to_char(com_cliente),3,'0')
   into w_cod_istat
   from dati_generali
    ;
  EXCEPTION
  WHEN no_data_found THEN
       null;
  WHEN others THEN
       w_errore := 'Errore in ricerca Codice Istat del Comune ' ||
                   ' ('||SQLERRM||')');
       RAISE errore;
  END;
*/
BEGIN
  BEGIN
    select to_char(sysdate,'ddmmyyyy/hh24mmss'),
        to_char(sysdate,'ddmmyyyy'),
           'EUR'||cod_ente
      into w_numero_protocollo,
        w_data_elaborazione,
        w_cod_ente
      from ruoli ruol, tipi_tributo titr
     where titr.tipo_tributo = ruol.tipo_tributo
    and ruol.ruolo        = a_ruolo
    ;
  EXCEPTION
  WHEN no_data_found THEN
    RAISE_APPLICATION_ERROR
      (-20999,'Manca Codice Ente Creditore! '||
                   ' ('||SQLERRM||')');
  WHEN others THEN
    RAISE_APPLICATION_ERROR
      (-20999,'Errore in ricerca Codice Ente Creditore '||
                   ' ('||SQLERRM||')');
  END;
  BEGIN
    delete wrk_trasmissioni
    ;
  EXCEPTION
  WHEN others THEN
    RAISE_APPLICATION_ERROR
      (-20999,'Errore in pulizia tabella di lavoro '||
                   ' ('||SQLERRM||')');
  END;
--COMMIT;
--   TRATTAMENTO
FOR rec_sgra IN sel_sgra LOOP
 IF w_ni_prec = rec_sgra.ni OR w_ni_prec = 0 THEN
  w_num_articolo := w_num_articolo + 1;
 ELSE
  w_num_articolo := 1;
 END IF;
  BEGIN
    insert into wrk_trasmissioni
           (numero,
       dati)
    values (w_numero_protocollo,
       rpad(w_numero_protocollo,15,' ')||
       lpad(w_data_elaborazione,8,'0')||
       rec_sgra.tipo_provvedimento||w_cod_ente||
       rpad(' ',7)||lpad(to_char(nvl(rec_sgra.cod_concessione,0)),3,'0')||
       lpad(to_char(nvl(rec_sgra.num_ruolo,0)),6,'0')||rec_sgra.anno_emissione||
       decode(rec_sgra.tipo,0,
         rpad(rec_sgra.dati_contribuente,104,' ')||rpad(' ',61),
         rpad(' ',104)||rpad(rec_sgra.dati_contribuente,61,' '))||
       rpad(' ',96)||
       lpad(rec_sgra.tributo,4,'0')||rec_sgra.anno_ruolo||
       lpad(w_num_articolo,3,'0')||lpad(rec_sgra.importo_ruolo,15,'0')||
       lpad(rec_sgra.importo_sgravio,15,'0'))
    ;
  EXCEPTION
    WHEN others THEN
      RAISE_APPLICATION_ERROR
        (-20999,'Errore in inserimento dati ' ||
                     ' ('||SQLERRM||')');
  END;
 w_ni_prec := rec_sgra.ni;
END LOOP;
EXCEPTION
  WHEN others THEN
     ROLLBACK;
     RAISE_APPLICATION_ERROR
     (-20999,'Errore in Trasmissione Sgravio su supporto magnetico' ||
      ' ('||SQLERRM||')');
END;
/* End Procedure: TRASMISSIONE_SGRAVIO */
/

