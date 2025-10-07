--liquibase formatted sql 
--changeset abrandolini:20250326_152423_alde_risposta stripComments:false runOnChange:true 
 
create or replace procedure ALDE_RISPOSTA
   (
       a_documento_id     in      number
     , a_nome_supporto    in      varchar2
     , a_utente           in      varchar2
     , a_messaggio        in out  varchar2
   ) is
w_documento_blob        blob;
--w_documento_clob        clob;
w_number_temp           number;
--dest_offset             number  := 1;
--src_offset              number  := 1;
--amount                  integer := dbms_lob.lobmaxsize;
--blob_csid               number  := dbms_lob.default_csid;
--lang_ctx                integer := dbms_lob.default_lang_ctx;
--warning                 integer;
w_deleghe_trattate      number := 0;
w_deleghe_inserite      number := 0;
w_deleghe_accettate     number := 0;
w_deleghe_negate        number := 0;
w_deleghe_stornate      number := 0;
w_richieste_non_gestite number := 0;
w_deleghe_variate       number := 0;
w_deleghe_revocate      number := 0;
w_90212                 number := 0;
w_90316                 number := 0;
w_90311                 number := 0;
w_90312                 number := 0;
w_90313                 number := 0;
w_90314                 number := 0;
w_90210                 number := 0;
w_90420                 number := 0;
w_90421                 number := 0;
w_90430                 number := 0;
w_90830                 number := 0;
w_numero_righe          number;
w_riga                  varchar2(122);
w_causale               varchar2(5);
w_codice_individuale    varchar2(16);
w_tipo_tributo          varchar2(5);
w_ni                    varchar2(16);
w_cod_fiscale           varchar2(16);
w_delega_presente       number;
w_data_creazione        date;
w_iban_cin_europa       deleghe_bancarie.iban_cin_europa%type;
w_iban_paese            deleghe_bancarie.iban_paese%type;
w_cod_controllo_cc      deleghe_bancarie.cod_controllo_cc%type;
w_cin_bancario          deleghe_bancarie.cin_bancario%type;
w_abi                   deleghe_bancarie.cod_abi%type;
w_cab                   deleghe_bancarie.cod_cab%type;
w_conto_corrente        deleghe_bancarie.conto_corrente%type;
w_cognome_nome_int      deleghe_bancarie.cognome_nome_int%type;
w_cod_fiscale_int       deleghe_bancarie.codice_fiscale_int%type;
w_indirizzo             soggetti.denominazione_via%type;
w_cap                   soggetti.cap%type;
w_localita              varchar2(25);
w_intestatario_conto    soggetti.cognome_nome%type;
w_data_elaborazione     number;
w_numero                number;
w_pro_cliente           number;
w_com_cliente           number;
w_istat                 varchar2(6);
w_progressivo           number;
w_causale_risposta      varchar2(5);
w_flag_delega_cessata   varchar2(1);
w_messaggio             varchar2(2000);
w_mittente              varchar2(5);
w_ricevente             varchar2(5);
sql_errm                varchar2(200);
errore                  exception;
w_errore                varchar2(200);
w_delega_ok             boolean;
w_note                  varchar2(1600) := '';
w_ni_errati             number := 0;
BEGIN
   w_data_elaborazione := 0;
   w_progressivo       := 0;
   w_numero            := 0;
   -- Cambio stato in caricamento in corso per gestione Web
   update documenti_caricati
           set stato = 15
             , data_variazione = sysdate
             , utente = a_utente
         where documento_id = a_documento_id
         ;
   commit;
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
   -- Se il parametro non è presente viene inserito il codice di Bovezzo
   -- per mantenere la compatibilità con Bovezzo
   w_mittente  := nvl(f_inpa_valore('ALDE_MITT'),'A1KPA');
   w_ricevente := nvl(f_inpa_valore('ALDE_RICE'),'02008');
   w_progressivo := w_progressivo + 1;
   --Inserimento del record di testa 'IM'
   BEGIN
      insert into wrk_trasmissioni(numero
                                 , dati)
      values(lpad(w_progressivo,5,0)
           , ' '                                                                -- Filler
             || 'AL'                                                            -- Tipo Record
             || w_mittente                                                      -- Mittente
             || w_ricevente                                                     -- Ricevente
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
   -- Estrazione BLOB
   begin
      select contenuto
        into w_documento_blob
        from documenti_caricati doca
       where doca.documento_id  = a_documento_id
           ;
   end;
   -- Verifica dimensione file caricato
   w_number_temp:= DBMS_LOB.GETLENGTH(w_documento_blob);
   if nvl(w_number_temp,0) = 0 then
     w_errore := 'Attenzione File caricato Vuoto - Verificare Client Oracle';
     raise errore;
   end if;
   --DBMS_OUTPUT.Put_Line(to_char(w_number_temp));
   -- Trasformazione in CLOB
--   begin
--     DBMS_LOB.CREATETEMPORARY(lob_loc=>w_documento_clob, cache=>TRUE, dur=>dbms_lob.SESSION);
--     DBMS_LOB.CONVERTTOCLOB(w_documento_clob,w_documento_blob,amount,dest_offset,src_offset,blob_csid,lang_ctx,warning);
--      exception
--         when others then
--            w_errore := 'Errore in trasformazione Blob in Clob  ('||SQLERRM||')';
--            raise errore;
--   end;
   w_numero_righe := w_number_temp / 122;
   --DBMS_OUTPUT.Put_Line(to_char(w_numero_righe));
   FOR i IN 0 .. w_numero_righe - 1 LOOP
      w_riga := utl_raw.cast_to_varchar2(
                      dbms_lob.substr(w_documento_blob,122, (122 * i ) + 1)
                                        );
      --DBMS_OUTPUT.Put_Line(to_char(i));
      if substr(w_riga, 2,2) = '12' then
         w_causale := substr(w_riga, 29,5);
         w_codice_individuale := substr(w_riga, 98,16);
         w_tipo_tributo := rtrim(substr(w_codice_individuale,1,5));
         if w_istat = '037054' then --. San Lazzaro
            if w_tipo_tributo = 'TARSU' then
               w_delega_ok := true;
            else
               w_delega_ok := false;
            end if;
         else
            w_delega_ok := true;
         end if;
         if w_delega_ok then
            w_ni := ltrim(ltrim(substr(w_codice_individuale,7,10)),'0');
            begin
               select cod_fiscale
                 into w_cod_fiscale
                 from contribuenti
                where ni = to_number(w_ni)
                    ;
            EXCEPTION
               WHEN others THEN
                w_delega_ok := false;
                w_note      := w_note||w_ni||';';
                w_ni_errati := w_ni_errati + 1;
            end;
         end if;
         if w_delega_ok then
            w_deleghe_trattate := w_deleghe_trattate + 1;
            if w_causale in ('90212','90316') then
               begin
                  select count(1)
                    into w_delega_presente
                    from deleghe_bancarie
                   where cod_fiscale  = w_cod_fiscale
                     and tipo_tributo = w_tipo_tributo
                     ;
               EXCEPTION
                  when no_data_found then
                      w_delega_presente := 0;
                  WHEN others THEN
                     w_errore := ('Errore in verifica presenza delega di '|| w_cod_fiscale || ' (' || SQLERRM || ')' );
                     raise errore;
               end;
               if w_delega_presente = 0 then
                  begin
                     insert into deleghe_bancarie
                          ( cod_fiscale
                          , tipo_tributo
                          , cod_abi
                          , cod_cab
                          , conto_corrente
                          , cod_controllo_cc
                          , cin_bancario
                          , iban_paese
                          , iban_cin_europa
                          , codice_fiscale_int
                          , cognome_nome_int
                          , utente)
                     select cod_fiscale
                          , tipo_tributo
                          , cod_abi
                          , cod_cab
                          , conto_corrente
                          , cod_controllo_cc
                          , cin_bancario
                          , iban_paese
                          , iban_cin_europa
                          , codice_fiscale_int
                          , cognome_nome_int
                          , a_utente
                       from allineamento_deleghe
                      where cod_fiscale  = w_cod_fiscale
                        and tipo_tributo = w_tipo_tributo
                        and stato        = 'INVIATA'
                        ;
                  EXCEPTION
                     WHEN others THEN
                        w_errore := ('Errore in inserimento delega di '|| w_cod_fiscale || ' (' || SQLERRM || ')' );
                        raise errore;
                  end;
                  w_deleghe_inserite := w_deleghe_inserite + 1;
               end if;
               begin
                  update allineamento_deleghe
                     set stato = decode(w_causale
                                       ,'90212','INSERITA'
                                       ,'90316','STORNATA'
                                       )
                       , utente = a_utente
                   where cod_fiscale  = w_cod_fiscale
                     and tipo_tributo = w_tipo_tributo
                     and stato        = 'INVIATA'
                      ;
               EXCEPTION
                  WHEN others THEN
                     w_errore := ('Errore in aggiornamento stato ALDE di '|| w_cod_fiscale || ' (' || SQLERRM || ')' );
                     raise errore;
               end;
               if w_causale = '90212' then
                  w_deleghe_accettate := w_deleghe_accettate + 1;
               else
                  w_deleghe_stornate := w_deleghe_stornate + 1;
               end if;
            elsif w_causale in ('90311', '90312', '90313', '90314' )then
               begin
                  update allineamento_deleghe
                     set stato = 'NEGATA'
                       , note  = note||'Causale Diniego: '||w_causale
                       , utente = a_utente
                   where cod_fiscale  = w_cod_fiscale
                     and tipo_tributo = w_tipo_tributo
                     and stato        = 'INVIATA'
                      ;
               EXCEPTION
                  WHEN others THEN
                     w_errore := ('Errore in aggiornamento stato ALDE di '|| w_cod_fiscale || ' (' || SQLERRM || ')' );
                     raise errore;
               end;
               w_deleghe_negate := w_deleghe_negate + 1;
            elsif w_causale in ('90210','90420','90421','90430','90830') then
               w_iban_paese      := substr(w_riga, 44,2);                          -- codice_paese
               w_iban_cin_europa := to_number(substr(w_riga, 46,2));               -- check_digit
               w_cin_bancario    := substr(w_riga, 69,1);                          -- cin
               w_abi             := to_number(substr(w_riga, 70,5));
               w_cab             := to_number(substr(w_riga, 75,5));
               w_conto_corrente  := substr(w_riga, 80,12);
               w_data_creazione := to_date(substr(w_riga, 11,6),'ddmmyy');
               w_numero      := w_numero + 1;
               w_progressivo := w_progressivo + 1;
               if w_causale = '90210' then
                  w_causale_risposta := '90310';
               elsif w_causale = '90420' or w_causale = '90421' then
                  w_causale_risposta := '90520';
               elsif w_causale = '90430' or w_causale = '90830' then
                  w_causale_risposta := '90530';
               else
                  w_causale_risposta := '     ';
               end if;
               BEGIN
                  insert into wrk_trasmissioni(numero
                                             , dati)
                  values(lpad(w_progressivo,5,0)
                        , ' 12'
                        ||lpad(to_char(w_numero),7,'0')                            -- numero progressivo
                        ||to_char(sysdate,'ddmmyy')                                -- data_creazione disposizione
                        ||rpad(' ',12,' ')                                         -- filler
                        ||w_causale_risposta                                       -- causale risosta
                        ||substr(w_riga, 34,19)
                        ||rpad(' ',16,' ')
                        ||substr(w_riga, 69,45)
                        ||rpad(' ',7,' ')
                        )
                  ;
               EXCEPTION
                  WHEN others THEN
                     w_errore := ('Errore in inserimento dati (12) ' || ' (' || SQLERRM || ')' );
                     raise errore;
               END;
            else
               w_richieste_non_gestite := w_richieste_non_gestite + 1;
            end if;
         else
            w_richieste_non_gestite := w_richieste_non_gestite + 1;
         end if;
      elsif substr(w_riga, 2,2) = '30'  and w_delega_ok then
         if w_causale = 90210 then
            w_cognome_nome_int := rtrim(substr(w_riga, 11,60));
            w_cod_fiscale_int  := rtrim(substr(w_riga, 85,16));
         end if;
      elsif substr(w_riga, 2,2) = '40' and w_delega_ok then
         if w_causale = 90210 then
            w_indirizzo          := rtrim(substr(w_riga, 11,40));
            w_cap                := rtrim(substr(w_riga, 41,5));
            w_localita           := rtrim(substr(w_riga, 46,25));
            w_intestatario_conto := rtrim(substr(w_riga, 71,50));
         end if;
      elsif substr(w_riga, 2,2) = '45' and w_delega_ok then
         if w_causale in (90430,90830) then
            w_progressivo := w_progressivo + 1;
            BEGIN
               insert into wrk_trasmissioni(numero
                                          , dati)
               values(lpad(w_progressivo,5,0)
                     , ' 45'
                     ||lpad(to_char(w_numero),7,'0')
                     ||substr(w_riga, 11,110)
                     )
               ;
            EXCEPTION
               WHEN others THEN
                  w_errore := ('Errore in inserimento dati (45) ' || ' (' || SQLERRM || ')' );
                  raise errore;
            END;
         end if;
      elsif substr(w_riga, 2,2) = '70' and w_delega_ok then
         if w_causale = '90210' then
            -- prima verifico se è già presente una delega
            begin
               select nvl(flag_delega_cessata,'N')
                 into w_flag_delega_cessata
                 from deleghe_bancarie
                where cod_fiscale  = w_cod_fiscale
                  and tipo_tributo = w_tipo_tributo
                  ;
            EXCEPTION
               WHEN others THEN
                  w_flag_delega_cessata := 'X';
            end;
            if w_flag_delega_cessata = 'N' then -- esiste una delega non cessata per il contribunete
               w_errore := 'Delega non cessata gia'' presente per '||w_cod_fiscale||' (ni:'||w_ni||')';
               raise errore;
            else
               if w_flag_delega_cessata = 'S' then -- esiste una delega cessata che vado a cancellare
                  begin
                     delete deleghe_bancarie
                      where cod_fiscale  = w_cod_fiscale
                        and tipo_tributo = w_tipo_tributo
                        ;
                  EXCEPTION
                     WHEN others THEN
                        sql_errm  := substr(SQLERRM,1,100);
                        w_errore := 'Errore in delete deba cf: '||w_cod_fiscale||
                                    ' Nome: '||w_intestatario_conto||
                                    ' ('||sql_errm||')';
                  end;
               end if;
               begin
                  insert into deleghe_bancarie
                     ( COD_FISCALE
                     , TIPO_TRIBUTO
                     , COD_ABI
                     , COD_CAB
                     , CONTO_CORRENTE
                     , COD_CONTROLLO_CC
                     , UTENTE
                     , DATA_VARIAZIONE
                     , NOTE
                     , CODICE_FISCALE_INT
                     , COGNOME_NOME_INT
                     , FLAG_DELEGA_CESSATA
                     , DATA_RITIRO_DELEGA
                     , FLAG_RATA_UNICA
                     , CIN_BANCARIO
                     , IBAN_PAESE
                     , IBAN_CIN_EUROPA
                     )
                  Values
                     ( w_cod_fiscale      -- cod_fiscale
                     , w_tipo_tributo
                     , w_abi
                     , w_cab
                     , w_conto_corrente
                     , NULL               -- cod_controllo_cc
                     , a_utente
                     , trunc(sysdate)
                     , NULL               -- note
                     , w_cod_fiscale_int
                     , w_cognome_nome_int
                     , NULL               -- flag_delega_cessata
                     , NULL               -- data_ritiro_delega
                     , NULL               -- flag_rata_unica
                     , w_cin_bancario     -- cin
                     , w_iban_paese       -- codice_paese
                     , w_iban_cin_europa  -- check_digit
                     );
               EXCEPTION
                  WHEN others THEN
                     sql_errm  := substr(SQLERRM,1,100);
                     w_errore := 'Errore in insert deba cf: '||w_cod_fiscale||
                                 ' Nome: '||w_intestatario_conto||
                                 ' ('||sql_errm||')';
               end;
               w_deleghe_inserite := w_deleghe_inserite + 1;
               w_progressivo := w_progressivo + 1;
               BEGIN
                  insert into wrk_trasmissioni(numero
                                             , dati)
                  values(lpad(w_progressivo,5,0)
                        , ' 50'
                        ||lpad(to_char(w_numero),7,'0')
                        ||substr(w_riga, 11,110)
                        )
                  ;
               EXCEPTION
                  WHEN others THEN
                     w_errore := ('Errore in inserimento dati (50) ' || ' (' || SQLERRM || ')' );
                     raise errore;
               END;
               w_progressivo := w_progressivo + 1;
               BEGIN
                  insert into wrk_trasmissioni(numero
                                             , dati)
                  values(lpad(w_progressivo,5,0)
                        , ' 70'
                        ||lpad(to_char(w_numero),7,'0')
                        ||rpad(' ',110,' ')
                        )
                  ;
               EXCEPTION
                  WHEN others THEN
                     w_errore := ('Errore in inserimento dati (70) ' || ' (' || SQLERRM || ')' );
                     raise errore;
               END;
            end if;
         elsif w_causale in ('90420','90421') then
            begin
               update deleghe_bancarie
                  set flag_delega_cessata = 'S'
                    , data_ritiro_delega = w_data_creazione
                where cod_fiscale = w_cod_fiscale
                  and tipo_tributo = w_tipo_tributo
               ;
            EXCEPTION
               WHEN others THEN
                  sql_errm  := substr(SQLERRM,1,100);
                  w_errore := 'Errore in revoca deba cf: '||w_cod_fiscale||
                              ' ('||sql_errm||')';
            end;
            w_deleghe_revocate := w_deleghe_revocate + 1;
            w_progressivo := w_progressivo + 1;
            BEGIN
               insert into wrk_trasmissioni(numero
                                          , dati)
               values(lpad(w_progressivo,5,0)
                     , ' 50'
                     ||lpad(to_char(w_numero),7,'0')
                     ||substr(w_riga, 11,110)
                     )
               ;
            EXCEPTION
               WHEN others THEN
                  w_errore := ('Errore in inserimento dati (50) ' || ' (' || SQLERRM || ')' );
                  raise errore;
            END;
            w_progressivo := w_progressivo + 1;
            BEGIN
               insert into wrk_trasmissioni(numero
                                          , dati)
               values(lpad(w_progressivo,5,0)
                     , ' 70'
                     ||lpad(to_char(w_numero),7,'0')
                     ||rpad(' ',110,' ')
                     )
               ;
            EXCEPTION
               WHEN others THEN
                  w_errore := ('Errore in inserimento dati (70) ' || ' (' || SQLERRM || ')' );
                  raise errore;
            END;
         elsif w_causale in ('90430','90830') then
            -- prima verifico se è già presente una delega
            begin
               select nvl(flag_delega_cessata,'N')
                 into w_flag_delega_cessata
                 from deleghe_bancarie
                where cod_fiscale  = w_cod_fiscale
                  and tipo_tributo = w_tipo_tributo
                  ;
            EXCEPTION
               WHEN others THEN
                  w_flag_delega_cessata := 'X';
            end;
            if w_flag_delega_cessata <> 'N' then -- NON esiste una delega non cessata per il contribunete
               w_errore := 'Delega da variare non presente o cessata per '||w_cod_fiscale||' (ni:'||w_ni||')';
               raise errore;
            else
               begin
                  update deleghe_bancarie
                     set cod_abi         = w_abi
                       , cod_cab         = w_cab
                       , conto_corrente  = w_conto_corrente
                       , cin_bancario    = w_cin_bancario
                       , iban_paese      = w_iban_paese
                       , iban_cin_europa = w_iban_cin_europa
                   where cod_fiscale     = w_cod_fiscale
                     and tipo_tributo = w_tipo_tributo
                  ;
               EXCEPTION
                  WHEN others THEN
                     sql_errm  := substr(SQLERRM,1,100);
                     w_errore := 'Errore in upd deba cf: '||w_cod_fiscale||
                                 ' ('||sql_errm||')';
               end;
               w_deleghe_variate := w_deleghe_variate + 1;
               w_progressivo := w_progressivo + 1;
               BEGIN
                  insert into wrk_trasmissioni(numero
                                             , dati)
                  values(lpad(w_progressivo,5,0)
                        , ' 50'
                        ||lpad(to_char(w_numero),7,'0')              -- numero progressivo
                        ||substr(w_riga, 11,110)
                        )
                  ;
               EXCEPTION
                  WHEN others THEN
                     w_errore := ('Errore in inserimento dati (50) ' || ' (' || SQLERRM || ')' );
                     raise errore;
               END;
               w_progressivo := w_progressivo + 1;
               BEGIN
                  insert into wrk_trasmissioni(numero
                                             , dati)
                  values(lpad(w_progressivo,5,0)
                        , ' 70'
                        ||lpad(to_char(w_numero),7,'0')
                        ||rpad(' ',110,' ')
                        )
                  ;
               EXCEPTION
                  WHEN others THEN
                     w_errore := ('Errore in inserimento dati (70) ' || ' (' || SQLERRM || ')' );
                     raise errore;
               END;
            end if;
         end if;
      end if;
   END LOOP;
   --Inserimento Record di Coda
   w_progressivo := w_progressivo + 1;
   BEGIN
      insert into wrk_trasmissioni(numero
                                 , dati)
      values(lpad(w_progressivo,5,0)
           , ' '                                              --Filler
             || 'EF'                                          --Tipo Record
             || w_mittente                                    --Mittente
             || w_ricevente                                   --Ricevente
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
   a_messaggio := w_messaggio;
   -- Aggiornamneto Stato
   begin
      update documenti_caricati
         set stato = 2
           , data_variazione = sysdate
           , utente = a_utente
           , note = 'Trattate: '||to_char(w_deleghe_trattate)
                  ||' - Inserite: '||to_char(w_deleghe_inserite)
                  ||' - Accettate: '||to_char(w_deleghe_accettate)
                  ||' - Stornate: '||to_char(w_deleghe_stornate)
                  ||' - Negate: '||to_char(w_deleghe_negate)
                  ||' - Variate: '||to_char(w_deleghe_variate)
                  ||' - Revocate: '||to_char(w_deleghe_revocate)
                  ||' - Non Gestite: '||to_char(w_richieste_non_gestite)
                  ||decode(w_ni_errati
                          ,0,''
                          ,' - NI Errati: '||w_note
                          )
       where documento_id = a_documento_id
           ;
   EXCEPTION
      WHEN others THEN
         sql_errm  := substr(SQLERRM,1,100);
         w_errore := 'Errore in Aggiornamneto Stato del documento '||
                                    ' ('||sql_errm||')';
   end;
   a_messaggio := 'Deleghe: '||chr(13)
                  ||'Trattate: '||to_char(w_deleghe_trattate)||chr(13)
                  ||'Inserite: '||to_char(w_deleghe_inserite)||chr(13)
                  ||'Accettate: '||to_char(w_deleghe_accettate)||chr(13)
                  ||'Stornate: '||to_char(w_deleghe_stornate)||chr(13)
                  ||'Negate: '||to_char(w_deleghe_negate)||chr(13)
                  ||'Variate: '||to_char(w_deleghe_variate)||chr(13)
                  ||'Revocate: '||to_char(w_deleghe_revocate)||chr(13)
                  ||'Non Gestite: '||to_char(w_richieste_non_gestite)||chr(13)
                  ||'NI Errati: '||to_char(w_ni_errati);
EXCEPTION
  WHEN errore THEN
       ROLLBACK;
       RAISE_APPLICATION_ERROR (-20999,w_errore||' ('||SQLERRM||')');
END;
/* End Procedure: ALDE_RISPOSTA */
/

