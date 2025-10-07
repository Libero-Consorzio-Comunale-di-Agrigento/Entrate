--liquibase formatted sql 
--changeset abrandolini:20250326_152423_importa_vers_mav_inc1 stripComments:false runOnChange:true 
 
create or replace procedure IMPORTA_VERS_MAV_INC1
   (
       a_documento_id     in      number
     , a_utente           in      varchar2
     , a_messaggio        in out  varchar2
   ) is
w_documento_blob        blob;
w_number_temp           number;
w_versamenti_trattati   number := 0;
w_versamenti_inseriti   number := 0;
w_versamenti_gia_presenti number := 0;
w_vers_gia_presente     number;
w_numero_righe          number;
w_riga                  varchar2(202);
w_tipo_documento        varchar2(3);
w_riferimento_incasso   varchar2(18);
w_importo_versato       number;
w_divisa                varchar2(1);
w_ruolo                 number;
w_anno                  number;
w_rata                  number;
w_ni                    number;
w_data_pagamento        date;
 w_fonte                number;
w_importo_totale_complessivo number; --Calcolato quando si inserisce un versamento
w_importo_versato_totale     number; --Estratto dal record riepilogativo
w_sequenza                   number;
w_cod_fiscale                varchar2(16);
w_cognome_nome               varchar2(60);
w_data_variazione            varchar2(10); --Per gestire i versamenti duplicati
--Gestione delle eccezioni
sql_errm           varchar2(200);
w_errore           varchar2(2000);
errore             exception;
BEGIN
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
   w_numero_righe := w_number_temp / 122;
   --DBMS_OUTPUT.Put_Line(to_char(w_numero_righe));
   w_importo_totale_complessivo := 0;
   FOR i IN 0 .. w_numero_righe - 1 LOOP
      w_riga := utl_raw.cast_to_varchar2(
                      dbms_lob.substr(w_documento_blob,122, (122 * i ) + 1)
                                        );
      --DBMS_OUTPUT.Put_Line(to_char(i));
      w_tipo_documento    := substr(w_riga,1,2);
      IF w_tipo_documento = '  ' THEN
         w_importo_versato     := to_number(substr(w_riga,32,10))/100 ;
         w_divisa              := substr(w_riga,31,1);
         w_riferimento_incasso := substr(w_riga,3,18);
         w_ni                  := to_number(substr(w_riferimento_incasso,1,8));
         w_ruolo               := to_number(substr(w_riferimento_incasso,9,5));
         w_rata                := to_number(substr(w_riferimento_incasso,15,2));
         if substr(w_riferimento_incasso,14,1) = '9' then
            w_fonte  := 24;
         else
            w_fonte  := 23;
         end if;
         w_data_pagamento      := to_date(substr(w_riga,42,4)||'20'||substr(w_riga,46,2)
                                         ,'ddmmyyyy'
                                         );
         w_versamenti_trattati := w_versamenti_trattati + 1;
         --Recupero il codice fiscale
         BEGIN
            select cont.cod_fiscale
              into w_cod_fiscale
              from contribuenti cont
             where cont.ni = w_ni
                 ;
         EXCEPTION
            WHEN others THEN
               w_errore := 'Errore ricerca Cod. Fiscale in Contribuenti ni:'||to_char(w_ni) || ' ('||sqlerrm||')';
               RAISE errore;
         END;
         --Recupero dell'anno
         BEGIN
            select ruol.anno_ruolo
              into w_anno
              from ruoli ruol
             where ruol.ruolo = w_ruolo
                 ;
         EXCEPTION
            WHEN others THEN
               w_errore := 'Errore ricerca Anno Ruolo per Contribuente ni:'||to_char(w_ni)
               ||' Ruolo: '||to_char(w_ruolo)
               || ' ('||sqlerrm||')';
               RAISE errore;
         END;
         --ricerca in Versamenti per evitare di inserire versamenti duplicati
         BEGIN
            select to_char(vers.data_variazione,'dd/mm/yyyy')
              into w_data_variazione
              from versamenti vers
             where vers.cod_fiscale     = w_cod_fiscale
               and vers.anno            = w_anno
               and vers.tipo_tributo    = 'TARSU'
               and vers.rata            = w_rata
               and vers.importo_versato = w_importo_versato
               and vers.data_pagamento  = w_data_pagamento
                 ;
         EXCEPTION
            WHEN no_data_found THEN
               w_data_variazione := '00/00/0000'; --Versamente non duplicato
            WHEN others THEN
               w_errore := 'Errore ricerca in Versamenti per evitare versamenti duplicati' || ' ('||sqlerrm||')';
               RAISE errore;
         END;
         IF w_data_variazione != '00/00/0000' THEN --Versamento duplicato
            --Recupero Cognome Nome
            BEGIN
               select translate(sogg.COGNOME_NOME,'/',' ') cognome_nome
                 into w_cognome_nome
                 from soggetti sogg
                 where ni = w_ni
                    ;
            EXCEPTION
               WHEN others THEN
                  w_errore := 'Errore ricerca Cognome Nome in soggetti ' || ' ('||sqlerrm||')';
                  RAISE errore;
            END;
            -- Assegnazione Numero Progressivo
            BEGIN
               select nvl(max(wver.progressivo),0)+1
                 into w_sequenza
                 from wrk_versamenti wver
                    ;
            EXCEPTION
               WHEN others THEN
                  w_errore := 'Errore ricerca sequenza in wrk_versamenti ' || ' ('||sqlerrm||')';
                  RAISE errore;
            END;
            BEGIN
               insert into wrk_versamenti(progressivo
                                        , tipo_tributo
                                        , tipo_incasso
                                        , anno
                                        , cod_fiscale
                                        , cognome_nome
                                        , rata
                                        , importo_versato
                                        , note
                                        , data_pagamento)
               values ( w_sequenza
                      , 'TARSU'
                      , 'MAV'
                      , w_anno
                      , w_cod_fiscale
                      , w_cognome_nome
                      , w_rata
                      , w_importo_versato
                      , 'Versamento già presente in data ' || w_data_variazione
                      , w_data_pagamento)
                     ;
            EXCEPTION
               WHEN others THEN
                  w_errore := 'Errore in inserimento wrk_versamenti '
                           || 'Riferimento Incasso: ' || w_riferimento_incasso
                           || ' ('||sqlerrm||')';
                  RAISE errore;
            END;
            w_versamenti_gia_presenti := w_versamenti_gia_presenti + 1;
         ELSE --Inserimento in Versamenti
            -- Assegnazione Numero Progressivo
            BEGIN
               select nvl(max(vers.sequenza),0)+1
                 into w_sequenza
                 from versamenti vers
                where vers.cod_fiscale     = w_cod_fiscale
                  and vers.anno            = w_anno
                  and vers.tipo_tributo    = 'TARSU'
                    ;
            EXCEPTION
               WHEN others THEN
                  w_errore := 'Errore ricerca sequenza in Versamenti ' || ' ('||sqlerrm||')';
                  RAISE errore;
            END;
            BEGIN
               insert into versamenti(cod_fiscale
                                    , anno
                                    , tipo_tributo
                                    , rata
                                    , descrizione
                                    , data_pagamento
                                    , importo_versato
                                    , ruolo
                                    , fonte
                                    , utente
                                    , data_variazione
                                    , data_reg
                                    , sequenza)
              values ( w_cod_fiscale
                     , w_anno
                     , 'TARSU'
                     , w_rata
                     , 'VERSAMENTO IMPORTATO INC1'
                     , w_data_pagamento
                     , w_importo_versato
                     , w_ruolo
                     , w_fonte
                     , a_utente
                     , trunc(sysdate)
                     , trunc(sysdate)
                     , w_sequenza)
                   ;
            EXCEPTION
            WHEN others THEN
               w_errore := 'Errore in inserimento versamento cf ' || w_cod_fiscale || ' ('||sqlerrm||')';
               RAISE errore;
            END;
            w_versamenti_inseriti := w_versamenti_inseriti + 1;
         END IF;
         w_importo_totale_complessivo := w_importo_totale_complessivo + w_importo_versato;
      ELSIF w_tipo_documento = 'EF' THEN --Record riepilogativo
         --Controlla che l'importo versato totale sia coerente con quello riportato nel record riepilogativo
         w_importo_versato_totale := to_number(substr(w_riga,23,11))/100 ;
         IF w_importo_versato_totale <> w_importo_totale_complessivo THEN
            rollback;
            w_errore := 'Importo versato errato' || ' ('||sqlerrm||')';
            RAISE errore;
         END IF;
         -- Occorre azzerrare la variabele seguente perchè il file di ingresso può contenere
         -- diversi record riepilogativiche fanno riferimento ai record precednti
         w_importo_totale_complessivo := 0;
      END IF;
   END LOOP;
   -- Aggiornamneto Stato
   begin
      update documenti_caricati
         set stato = 2
           , data_variazione = sysdate
           , utente = a_utente
           , note = 'Versamenti Trattati: '||to_char(w_versamenti_trattati)
                  ||' - Versamenti Inseriti: '||to_char(w_versamenti_inseriti)
                  ||' - Versamenti Gia Presenti: '||to_char(w_versamenti_gia_presenti)
       where documento_id = a_documento_id
           ;
   EXCEPTION
      WHEN others THEN
         sql_errm  := substr(SQLERRM,1,100);
         w_errore := 'Errore in Aggiornamneto Stato del documento '||
                                    ' ('||sql_errm||')';
   end;
   a_messaggio := 'Versamenti Trattati: '||to_char(w_versamenti_trattati)||chr(13)
                  ||'Versamenti Inseriti: '||to_char(w_versamenti_inseriti)||chr(13)
                  ||'Versamenti Gia Presenti: '||to_char(w_versamenti_gia_presenti);
EXCEPTION
   WHEN errore THEN
      ROLLBACK;
      RAISE_APPLICATION_ERROR(-20999, w_errore);
   WHEN others THEN
      ROLLBACK;
      RAISE_APPLICATION_ERROR (-20999, 'Errore in importa_vers_mav_inc1 '
                                    || 'Riferimento Incasso: ' || w_riferimento_incasso
                                    || '('||SQLERRM||')');
END;
/* End Procedure: IMPORTA_VERS_MAV_INC1 */
/

