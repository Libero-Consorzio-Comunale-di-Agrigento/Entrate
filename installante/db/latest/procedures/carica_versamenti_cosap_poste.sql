--liquibase formatted sql 
--changeset abrandolini:20250326_152423_carica_versamenti_cosap_poste stripComments:false runOnChange:true 
 
create or replace procedure CARICA_VERSAMENTI_COSAP_POSTE
is
--Seleziona i versamenti escludendo il record riepilogativo
CURSOR sel_vers IS
   select wrta.progressivo
        , substr(wrta.dati,1,8)    progr_caricamento
        , substr(wrta.dati,9,7)    progr_selezione
        , substr(wrta.dati,16,12)  cc_beenficiario
        , substr(wrta.dati,34,3)   tipo_documento
        , decode(substr(wrta.dati,34,3)
                                     , '999', null --to_date('19800129','yyyymmdd')
                                     , to_date(decode(sign(substr(wrta.dati,28,2)-50)
                                                                                    , 1, '19'||substr(wrta.dati,28,6)
                                                                                    , '20' || substr(wrta.dati,28,6))
                                            , 'yyyymmdd')) data_pagamento
        , to_number(substr(wrta.dati,37,10))/100  importo_versato
        , substr(wrta.dati,47,8)       ufficio_sportello
        , substr(wrta.dati,55,1)       divisa
        , substr(wrta.dati,56,6)       data_accredito
        , substr(wrta.dati,62,4)       anno
        , substr(wrta.dati,66,1)       rata
        , to_number(substr(dati,67,8)) ni
        , substr(wrta.dati,62,1)       ultima_cifra_anno
        , substr(wrta.dati,78,123) filler
        , wrta.progressivo         progr_anci
/*       , decode(substr(wrta.dati,34,3)
                                     , '999', 'S'
                                     , 'N') rec_riepilogativo*/
        , decode(substr(wrta.dati,34,3)
               , '999', to_number(substr(wrta.dati,45,12))/100
               , null) importo_versato_totale --Ha senso solo per il record riepilogativo
    from wrk_tras_anci wrta
   where wrta.anno            = 3
order by wrta.progressivo
;
w_importo_totale_complessivo number; --Calcolato quando si inserisce un versamento
w_importo_versato number; --Estratto dal record riepilogativo
w_sequenza        number;
w_cod_fiscale     varchar2(16);
w_cognome_nome varchar2(60);
w_data_variazione varchar2(10); --Per gestire i versamenti duplicati
--Gestione delle eccezioni
w_errore            varchar2(2000);
errore               exception;
BEGIN
   w_importo_totale_complessivo := 0;
   FOR rec_vers IN sel_vers LOOP
      IF rec_vers.tipo_documento != '999' THEN
         IF rec_vers.tipo_documento in ('247','896','674') THEN
            --Recupero il codice fiscale
            BEGIN
               select cont.cod_fiscale
                 into w_cod_fiscale
                 from contribuenti cont
                where cont.ni = rec_vers.ni
                    ;
            EXCEPTION
               WHEN others THEN
                  w_errore := 'Errore ricerca Cod. Fiscale in Contribuenti ni:'||to_char(rec_vers.ni) || ' ('||sqlerrm||')';
                  RAISE errore;
            END;
            --ricerca in Versamenti per evitare di inserire versamenti duplicati
            BEGIN
               select to_char(vers.data_variazione,'dd/mm/yyyy')
                 into w_data_variazione
                 from versamenti vers
                where vers.cod_fiscale     = w_cod_fiscale
                  and vers.anno            = rec_vers.anno
                  and vers.tipo_tributo    = 'TOSAP'
                  and vers.rata            = rec_vers.rata
                  and vers.importo_versato = rec_vers.importo_versato
                  and vers.data_pagamento  = rec_vers.data_pagamento
                  and vers.fonte           = '12'
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
                    where ni = rec_vers.ni
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
                         , 'TOSAP'
                         , 'POSTE'
                         , rec_vers.anno
                         , w_cod_fiscale
                         , w_cognome_nome
                         , rec_vers.rata
                         , rec_vers.importo_versato
                         , 'Versamento già presente in data ' || w_data_variazione
                         , rec_vers.data_pagamento)
                        ;
               EXCEPTION
                  WHEN others THEN
                     w_errore := 'Errore in inserimento wrk_versamenti ' || rec_vers.progr_anci || ' ('||sqlerrm||')';
                     RAISE errore;
               END;
            ELSE --Inserimento in Versamenti
               -- Assegnazione Numero Progressivo
               BEGIN
                  select nvl(max(vers.sequenza),0)+1
                    into w_sequenza
                    from versamenti vers
                   where vers.cod_fiscale     = w_cod_fiscale
                     and vers.anno            = rec_vers.anno
                     and vers.tipo_tributo    = 'TOSAP'
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
                                       , ufficio_pt
                                       , data_pagamento
                                       , importo_versato
                                       , progr_anci
                                       , fonte
                                       , utente
                                       , data_variazione
                                       , data_reg
                                       , sequenza)
                 values ( w_cod_fiscale
                        , rec_vers.anno
                        , 'TOSAP'
                        , rec_vers.rata
                        , 'VERSAMENTO IMPORTATO DA POSTE'
                        , rec_vers.ufficio_sportello
                        , rec_vers.data_pagamento
                        , rec_vers.importo_versato
                        , rec_vers.progr_anci
                        , 12
                        , 'POSTE'
                        , trunc(sysdate)
                        , trunc(sysdate)
                        , w_sequenza)
                      ;
               EXCEPTION
               WHEN others THEN
                  w_errore := 'Errore in inserimento versamento progressivo ' || rec_vers.progr_anci || ' ('||sqlerrm||')';
                  RAISE errore;
               END;
            END IF;
         ELSE --Tipo documento: 451, 123
            --Per quei record dove nn è possibile l aggancio del NI inserisco i dati in wrk_versamenti
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
                                        , importo_versato
                                        , note
                                        , data_pagamento)
               values ( w_sequenza
                      , 'TOSAP'
                      , 'POSTE'
                      , '200' || rec_vers.ultima_cifra_anno
                      , rec_vers.importo_versato
                      , 'Progr. caricamento: ' || rec_vers.progr_caricamento || ' Progr. selezione: ' || rec_vers.progr_selezione
                      , rec_vers.data_pagamento)
                     ;
            EXCEPTION
               WHEN others THEN
                  w_errore := 'Errore in inserimento wrk_versamenti ' || rec_vers.progr_anci || ' ('||sqlerrm||')';
                  RAISE errore;
            END;
         END IF; --247, 896, 674
         w_importo_totale_complessivo := w_importo_totale_complessivo + rec_vers.importo_versato;
         BEGIN
            delete wrk_tras_anci
             where progressivo = rec_vers.progr_anci
               and anno = 3;
         EXCEPTION
            WHEN others THEN
               w_errore := 'Errore in eliminazione wrk_tras_anci progressivo ' || rec_vers.progr_anci || ' ('||sqlerrm||')';
               RAISE errore;
         END;
      ELSE --Record riepilogativo
         --Controlla che l importo versato totale sia coerente con quello riportato nel record riepilogativo
         w_importo_versato := rec_vers.importo_versato_totale;
         IF w_importo_versato <> w_importo_totale_complessivo THEN
            w_errore := 'Importo versato errato' || ' ('||sqlerrm||')';
            RAISE errore;
         END IF;
         --Eliminazione record riepilogativo
         BEGIN
            delete wrk_tras_anci
             where progressivo = rec_vers.progr_anci
               and anno = 3;
         EXCEPTION
            WHEN others THEN
               w_errore := 'Errore in eliminazione wrk_tras_anci progressivo ' || rec_vers.progr_anci || ' ('||sqlerrm||')';
               RAISE errore;
         END;
         w_importo_totale_complessivo := 0;
      END IF;
   END LOOP;
EXCEPTION
   WHEN errore THEN
      ROLLBACK;
      RAISE_APPLICATION_ERROR(-20999, w_errore);
   WHEN others THEN
      ROLLBACK;
      RAISE_APPLICATION_ERROR (-20999, 'Errore in carica_versamenti_cosap_poste ' || '('||SQLERRM||')');
END;
/* End Procedure: CARICA_VERSAMENTI_COSAP_POSTE */
/

