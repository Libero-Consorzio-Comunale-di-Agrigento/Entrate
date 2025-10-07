--liquibase formatted sql 
--changeset abrandolini:20250326_152423_alde_andata stripComments:false runOnChange:true 
 
create or replace procedure ALDE_ANDATA
   (
       a_tipo_tributo     in      varchar2
     , a_nome_supporto    in      varchar2
     , a_utente           in      varchar2
     , a_messaggio        in out  varchar2
   ) is
CURSOR sel_alde (p_tipo_tributo in varchar2) IS
select sogg.ni                                                                  ni
     , replace(nvl(sogg.cognome_nome,' '),'/',' ')                              cognome_nome
     , cont.cod_fiscale                                                         cod_fiscale
     , decode(arvi.cod_via
             , null, substr(nvl(sogg.denominazione_via,' '),1,20)
             , substr(nvl(arvi.denom_uff,' '),1,20)
             )
        || decode(sogg.num_civ
                 , null, to_char(null)
                 , ', ' || substr(sogg.num_civ,1,5)
                 )
        || decode(sogg.suffisso
                 , null, null
                 , '/' || substr(sogg.suffisso,1,2)
                 )                                                              indirizzo
     , nvl(sogg.cap,nvl(comu.cap,0))                                            cap
     , substr(nvl(comu.denominazione,' '),1,20)
        || ' ' || decode(prov.sigla
                        , null, null
                        ,'('||prov.sigla||')'
                        )                                                       comune
     , substr(nvl(comu.denominazione,' '),1,15)                                 comune_2
     , alde.cin_bancario                                                        cin_delega
     , alde.cod_abi                                                             abi_delega
     , alde.cod_cab                                                             cab_delega
     , alde.conto_corrente                                                      conto_corrente_delega
     , alde.codice_fiscale_int                                                  codice_fiscale_intestatario
     , alde.cognome_nome_int                                                    cognome_nome_intestatario
     , alde.IBAN_PAESE                                                          codice_paese
     , alde.IBAN_CIN_EUROPA                                                     check_digit
  from ad4_provincie                             prov
     , ad4_comuni                                comu
     , archivio_vie                              arvi
     , soggetti                                  sogg
     , contribuenti                              cont
     , allineamento_deleghe                      alde
 where prov.provincia       (+) = sogg.cod_pro_res
   and comu.provincia_stato (+) = sogg.cod_pro_res
   and comu.comune          (+) = sogg.cod_com_res
   and arvi.cod_via         (+) = sogg.cod_via
   and sogg.ni                  = cont.ni
   and cont.cod_fiscale         = alde.cod_fiscale
   and alde.tipo_tributo        = p_tipo_tributo
   and alde.cod_abi             is not null
   and alde.cod_cab             is not null
   and alde.conto_corrente      is not null
   and alde.stato               = 'DA INVIARE'
 order by
       cont.cod_fiscale
;
w_data_elaborazione       number;
w_numero                  number;
w_codice_utente           varchar2(16);
w_codice_riferimento      varchar2(15);
w_pro_cliente             number;
w_com_cliente             number;
w_istat                   varchar2(6);
w_progressivo             number;
w_mes_delega              varchar2(100);
--Gestione delle eccezioni
w_errore                  varchar2(2000);
w_err_par                 varchar2(50);
errore                    exception;
BEGIN
   --Inizializzazione variabili
   w_data_elaborazione := 0;
   w_progressivo := 0;
   w_numero := 0;
   --Svuotamento della tabella di lavoro
   BEGIN
      delete wrk_trasmissioni
           ;
   EXCEPTION
      WHEN others THEN
         w_errore := ('Errore nella delete della tabella wrk_trasmissioni' || ' (' || SQLERRM || ')' );
            raise errore;
   END;
   --Recupero dei dati dell'ente
   BEGIN
      select to_char(sysdate,'ddmmyy')
           , dage.pro_cliente
           , dage.com_cliente
           , lpad(to_char(dage.pro_cliente),3,'0')
             || lpad(to_char(dage.com_cliente),3,'0')
        into w_data_elaborazione
           , w_pro_cliente
           , w_com_cliente
           , w_istat
        from dati_generali dage
           ;
   EXCEPTION
      WHEN others THEN
         w_errore := ('Errore in estrazione Dati Ente ' || ' (' || SQLERRM || ')' );
         raise errore;
   END;
   w_progressivo := w_progressivo + 1;
   --Inserimento del record di testa 'IM'
   BEGIN
      insert into wrk_trasmissioni(numero
                                 , dati)
      values(lpad(w_progressivo,5,0)
           , ' '                                                                -- Filler
             || 'AL'                                                            -- Tipo Record
             || 'A1KPA'                                                         -- Mittente
             || '02008'                                                         -- Ricevente
             || lpad(w_data_elaborazione,6,'0')                                 -- Data creazione
             || rpad(a_nome_supporto,20,' ')                                    -- Nome supporto
             || rpad(' ',6,' ')                                                 -- Campo a disposizione
             || rpad(' ',75,' ')                                                -- Filler
            )
      ;
   EXCEPTION
      WHEN others THEN
         w_errore := ('Errore in inserimento dati (Record AL) ' || ' (' || SQLERRM || ')' );
         raise errore;
   END;
   FOR rec_alde IN sel_alde(a_tipo_tributo)
   LOOP
      w_progressivo   := w_progressivo + 1;
      w_numero        := w_numero + 1;  --Uguale per ogni contribuente, coincide con il numero delle disposizioni
      w_codice_utente  := rpad(a_tipo_tributo,5,' ')|| lpad(rec_alde.ni,11,'0');       -- record 12
      w_codice_riferimento := rpad(a_tipo_tributo,5,' ')|| lpad(rec_alde.ni,10,'0');   -- record 70
      --Inserimento Record 12
      BEGIN
         insert into wrk_trasmissioni(numero
                                    , dati)
         select lpad(w_progressivo,5,0)
              , ' '                                                             -- Filler
                || '12'                                                         -- Tipo Record
                || lpad(to_char(w_numero),7,'0')                                -- Numero progressivo
                || w_data_elaborazione                                          -- data creazione disposizione
                || rpad(' ',12,' ')                                             -- Filler
                || '90211'                                                      -- Causale
                || rpad(' ',10,' ')                                             -- Filler
                || rpad(nvl(rec_alde.codice_paese,' ' ),2,' ')                  -- Codice Paese
                || lpad(nvl(to_char(rec_alde.check_digit),' ' ),2,' ')          -- Check Digit
                || '02008'                                                      -- Codice ABI banca
                || rpad(' ',16,' ')                                             -- Filler
                || nvl(rec_alde.cin_delega,' ')                                 -- CIN Coordinate Bancarie
                || lpad(to_char(rec_alde.abi_delega),5,'0')                     -- ABI Banca conto addebito
                || lpad(to_char(rec_alde.cab_delega),5,'0')                     -- CAB Banca conto addebito
                || lpad(rec_alde.conto_corrente_delega,12,'0')                  -- Conto Corrente di addebito
                || 'A1KPA'                                                      -- Codice Azienda
                || '4'                                                          -- Tipo codice
                || w_codice_utente                                              -- Codice cliente debitore
                || rpad(' ',7,' ')                                              -- Filler
           from dual
              ;
      EXCEPTION
         WHEN others THEN
            w_errore := ('Errore in inserimento dati (Record 12) ' || ' (' || SQLERRM || ')' );
            raise errore;
      END;
      --Inserimento Record 30
      w_progressivo := w_progressivo + 1;
      BEGIN
         insert into wrk_trasmissioni(numero
                                    , dati)
         values(lpad(w_progressivo,5,0)
              , ' '                                                             -- Filler
                || '30'                                                         -- Tipo Record
                || lpad(to_char(w_numero),7,'0')                                -- Numero Progressivo
                || rpad(substr(rec_alde.cognome_nome,1,30),30,' ')              -- Cognome Nome sottoscrittore
                || rpad(rec_alde.indirizzo,30,' ')                              -- Indirizzo sottoscrittore
                || rpad(rec_alde.comune_2,14,' ')                               -- Localita sottoscrittore
                || rpad(rec_alde.cod_fiscale,16,' ')                            -- Codice fiscale
                || rpad(nvl(rec_alde.codice_fiscale_intestatario
                           ,rec_alde.cod_fiscale),16,' ')                       -- Codice fiscale Intestatario CC
                || rpad(' ',4,' ')                                              -- Filler
               )
         ;
      EXCEPTION
         WHEN others THEN
            w_errore := ('Errore in inserimento dati (Record 30) ' || ' (' || SQLERRM || ')' );
            raise errore;
      END;
      --Inserimento Record 40
      w_progressivo := w_progressivo + 1;
      BEGIN
         insert into wrk_trasmissioni(numero
                                 , dati)
         values(lpad(w_progressivo,5,0)
              , ' '                                                             -- Filler
                || '40'                                                         -- Tipo Record
                || lpad(to_char(w_numero),7,'0')                                -- Numero Progressivo
                || rpad(decode(rec_alde.cognome_nome_intestatario
                              ,'',rec_alde.indirizzo
                              ,' '
                              ),30,' ')                                         -- Indirizzo
                || decode(rec_alde.cognome_nome_intestatario
                              ,'',lpad(rec_alde.CAP,5,'0')
                              ,lpad(' ',5,' ')
                              )                                                 -- CAP
                || rpad(decode(rec_alde.cognome_nome_intestatario
                              ,'',rec_alde.comune
                              ,' '
                              ),25,' ')                                         -- Comune e sigla provincia
                || rpad(substr(nvl(rec_alde.cognome_nome_intestatario
                                  ,rec_alde.cognome_nome),1,50),50,' ')         -- Nominativo/Ragione Sociale intestatario conto corrente addebito
               )
         ;
      EXCEPTION
         WHEN others THEN
            w_errore := ('Errore in inserimento dati (Record 40) ' || ' (' || SQLERRM || ')' );
            raise errore;
      END;
      --Inserimento Record 70
      w_progressivo := w_progressivo + 1;
      BEGIN
         insert into wrk_trasmissioni(numero
                                 , dati)
         values(lpad(w_progressivo,5,0)
               , ' '                                                            -- Filler
                 || '70'                                                        -- Tipo Record
                 || lpad(to_char(w_numero),7,'0')                               -- Numero Progressivo
                 || w_codice_riferimento                                        -- Codice di riferimento
                 || '%'                                                        -- Carattere speciale
                 || rpad(' ',69,' ')                                            -- Filler
                 || '1'                                                         -- Flag di Storno
                 || 'E'                                                         -- Codice divisa
                 || rpad(' ',23,' ')                                            -- Filler
               )
              ;
      EXCEPTION
         WHEN others THEN
            w_errore := ('Errore in inserimento dati (Record 70) ' || ' (' || SQLERRM || ')' );
            raise errore;
      END;
      begin
         update allineamento_deleghe
            set stato = 'INVIATA'
          where cod_fiscale = rec_alde.cod_fiscale
            and tipo_tributo = a_tipo_tributo
              ;
      EXCEPTION
         WHEN others THEN
            w_errore := ('Errore in aggiornamneto ALDE ' || ' (' || SQLERRM || ')' );
            raise errore;
      end;
   END LOOP;
   --Inserimento Record di Coda
   w_progressivo := w_progressivo + 1;
   BEGIN
      insert into wrk_trasmissioni(numero
                                 , dati)
      values(lpad(w_progressivo,5,0)
           , ' '                                              --Filler
             || 'EF'                                          --Tipo Record
             || 'A1KPA'                                       --Mittente
             || '02008'                                       --Ricevente
             || lpad(w_data_elaborazione,6,'0')               --Data Creazione
             || rpad(a_nome_supporto,20,' ')                  --Nome Supporto
             || rpad(' ',6,' ')                               --Campo a disposizione
             || lpad(to_char(w_numero),7,'0')                 --Numero disposizioni
             || rpad(' ',30,' ')                              --Filler
             || lpad(to_char(w_progressivo),7,'0')            --Numero Record
             || rpad(' ',31,' ')                              --Filler
            )
         ;
   EXCEPTION
      WHEN others THEN
         w_errore := ('Errore in inserimento dati (Record EF) ' || ' (' || SQLERRM || ')' );
         raise errore;
   END;
   if w_numero = 1 then
      w_mes_delega := ' delega';
   else
      w_mes_delega := ' deleghe';
   end if;
   a_messaggio := 'Creato file con ' ||to_char(w_numero)
               ||w_mes_delega
               ||' DA INVIARE';
EXCEPTION
  WHEN errore THEN
       ROLLBACK;
       RAISE_APPLICATION_ERROR (-20999,w_errore||' ('||SQLERRM||')');
END;
/* End Procedure: ALDE_ANDATA */
/

