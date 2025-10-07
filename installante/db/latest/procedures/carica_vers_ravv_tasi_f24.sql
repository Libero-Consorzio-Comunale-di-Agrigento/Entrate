--liquibase formatted sql 
--changeset abrandolini:20250326_152423_carica_vers_ravv_tasi_f24 stripComments:false runOnChange:true 
 
create or replace procedure CARICA_VERS_RAVV_TASI_F24
/*******************************************************************************
 Versione  Data        Autore    Descrizione
 14        16/03/2023  VM        #55165 - Aggiunto parametro a_cod_fiscale.
                                 Aggiunto filtro cod_fiscale su popolamento cursori.
 13        24/06/2021  VD        Modificata gestione contribuente assente:
                                 ora il contribuente viene inserito anche
                                 in fase di caricamento da file (sempre se
                                 esiste gia' il soggetto).
 17        09/04/2021  VD        Modificata gestione contribuente assente:
                                 aggiunti controlli per evitare l'inserimento
                                 di NI già presenti in CONTRIBUENTI.
 16        11/01/2021  VD        Gestione nuovo campo note_versamento
                                 della tabella WRK_VERSAMENTI: il contenuto
                                 viene copiato nel campo note della tabella
                                 VERSAMENTI.
 15        01/10/2020  VD        Gestione contribuente mancante: si
                                 trattano anche i contribuenti con flag
                                 nullo.
 14        15/09/2020  VD        Gestione nuova causale di errore nel caso
                                 in cui la creazione della pratica di
                                 ravvedimento non vada a buon fine.
 13        06/07/2020  VD        Aggiunta creazione pratica di ravvedimento
                                 senza oggetti
                                 Aggiunta gestione contribuente assente: il
                                 contribuente viene inserito in presenza di
                                 anagrafica soggetti anche se il flag non e'
                                 attivo.
 12        06/05/2020  VD        Aggiunti codici sanzione relativi a
                                 ravvedimento lungo nel test di esistenza
                                 della pratica di ravvedimento
                                 Eliminata union nella query principale
                                 perchè nei ravvedimenti non esistono i codici
                                 tributo relativi a sanzioni e interessi.
 11        25/09/2018  VD        Modifiche per gestione versamenti su
                                 pratiche rateizzate
 10        09/05/2018  VD        Aggiunta gestione exception in ricerca
                                 pratica di ravvedimento
 9         30/10/2017  VD        Aggiunto controllo sui codici sanzione
                                 nelle query di verifica di esistenza
                                 della pratica di ravvedimento per
                                 identificare la pratica corretta
                                 (Acconto/Saldo)
 8         16/05/2017  VD        Aggiunto raggruppamento per data versamento
                                 per gestire versamenti dello stesso tipo
                                 effettuati in date diverse
 7         15/06/2016  VD        Aggiunto controllo tipo record in query
                                 principale: si trattano solo i record G1 -
                                 versamenti
 6         04/12/2015  VD        Aggiunta upper in selezione id_operazione
 5         28/01/2015  VD        Aggiunta distinzione versamenti per:
                                  - Imposta
                                  - Sanzioni e interessi
 4         16/01/2015  VD        Aggiunta gestione documento_id e nome_documento
 3         12/12/2014  VD        Aggiunta gestione nuovo campo
                                 IDENTIFICATIVO_OPERAZIONE
 2         11/11/2014  Betta T.  Ricontrollati codici tributo per allinearli
                                 ai dati estratti
 1         15/10/2014  Betta T.  Cambiato il test su tipo imposta per modifiche
                                 al tracciato del ministero
 Causali errore:        50100     Versamento già presente
                        50109     Contribuente non codificato
                        50150     Pratica di ravvedimento non presente
                        50180     Presenti più pratiche di ravvedimento
                        50190     Errore in creazione pratica di ravvedimento
*******************************************************************************/
( a_documento_id            documenti_caricati.documento_id%type default null,
  a_cod_fiscale             in                                   varchar2 default '%')
IS
w_tipo_tributo           varchar2(5) := 'TASI';
w_progressivo            number;
w_sequenza               number;
w_conta_cont             number;
w_ni                     number;
w_conta                  number;
w_conta_importo_esatto   number;
w_pratica                number;
w_flag_infrazione        varchar(1);
w_cod_fiscale            varchar2(16);
w_errore                 varchar2(2000);
errore                   exception;
-- (VD - 06/07/2020)
w_crea_ravv              number;
w_messaggio              varchar2(2000);
-- nella prima fase faccio diventare contribuenti i titolari dei versamenti
-- per cui è stato indicato il flag_contribuente
-- N.B. In pratica si selezionano da wrk_versamenti i versamenti che
--      non sono passati nella tabella effettiva perchè il contribuente
--      non era codificato
-- (VD - 11/01/2021): in questa query non si selezionano le note versamento
--                    perchè si inserisce solo il contribuente
cursor sel_ins_cont is
select wkve.progressivo                  progressivo
      ,wkve.cod_fiscale                  cod_fiscale
      ,cont.cod_fiscale                  cod_fiscale_cont
      ,sogg.cognome_nome                 cognome_nome
  from wrk_versamenti wkve
      ,contribuenti   cont
      ,soggetti       sogg
 where wkve.tipo_incasso    = 'F24'
   and wkve.tipo_tributo    = w_tipo_tributo
   and wkve.causale         = '50109'
   and cont.cod_fiscale (+) = wkve.cod_fiscale
   and sogg.ni          (+) = cont.ni
   and (cont.cod_fiscale like a_cod_fiscale or a_cod_fiscale = '%')
   --and nvl(wkve.flag_contribuente,'N') = 'S'
   ;
--
-- Esiste una fase iniziale di bonifica di eventuali anomalie presenti nella
-- tabella intermedia wrk_versamenti. Si tenta di ri-inserire il versamento;
-- se questo va a buon fine, allora si elimina la tabella wrk, altrimenti si
-- lascia la registrazione come in precedenza. Al massimo varia il motivo di
-- errore nel qual caso si cambiano la causale e le note.
-- (VD - 04/12/2015): Aggiunta upper in selezione id. operazione
cursor sel_errati is
select wkve.progressivo                  progressivo
      ,wkve.anno                         anno
      ,wkve.cod_fiscale                  cod_fiscale
      ,wkve.importo_versato              importo_versato
      ,wkve.ab_principale                ab_principale
      ,wkve.rurali                       rurali
      ,wkve.aree_fabbricabili            aree_fabbricabili
      ,wkve.altri_fabbricati             altri_fabbricati
      ,wkve.detrazione                   detrazione
      ,wkve.fabbricati                   fabbricati
      ,wkve.tipo_versamento              tipo_versamento
      ,wkve.data_pagamento               data_pagamento
      ,wkve.ufficio_pt                   ufficio_pt
      ,wkve.data_reg                     data_reg
      ,wkve.sanzione_ravvedimento        sanzione_ravvedimento
      ,cont.cod_fiscale                  cod_fiscale_cont
      ,sogg.cognome_nome                 cognome_nome
      ,wkve.num_fabbricati_ab
      ,wkve.num_fabbricati_rurali
      ,wkve.num_fabbricati_aree
      ,wkve.num_fabbricati_altri
      ,wkve.rata
      ,upper(wkve.identificativo_operazione)    id_operazione
      ,substr(wkve.note,1,1)                    tipo_messaggio
      ,wkve.documento_id
      ,wkve.rateazione
      ,wkve.note_versamento
  from wrk_versamenti wkve
      ,contribuenti   cont
      ,soggetti       sogg
 where wkve.tipo_incasso    = 'F24'
   and wkve.tipo_tributo    = w_tipo_tributo
   and wkve.causale         in ('50100','50109','50150','50180','50190')  -- RAVVEDIMENTO
   and cont.cod_fiscale (+) = wkve.cod_fiscale
   and sogg.ni          (+) = cont.ni
   and (cont.cod_fiscale like a_cod_fiscale or a_cod_fiscale = '%')
;
--
-- Il cursore esegue il raggruppamento per contribuente, anno e tipo di versamento
-- perche` viene fornito un dato per ogni tipologia di oggetto.
-- Anche se in realta` i seguenti dati dovrebbero essere gli stessi, nel caso di
-- ufficio_pt, data di versamento e data di registrazione vengono presi i valori
-- massimi.
-- La eliminazione delle registrazioni di input inserite non avviene piu`
-- per progressivo (una riga alla volta), ma per raggruppamento trattato, ovvero
-- per contribuente, anno e tipo di versamento.
-- Gli importi versati e le detrazioni sono sommati per ogni raggruppamento.
-- (VD - 10/12/2014): Modificato per gestire il nuovo campo identificativo
--                    operazione anche come raggruppamento
-- (VD - 04/12/2015): Aggiunta upper in selezione id. operazione
-- (VD - 15/06/2016): Aggiunto test su tipo record G1 - versamento
-- (VD - 16/05/2017): Aggiunto raggruppamento per data versamento
--------------------------------------------------------------------------------
--SE SI CAMBIA LA SELECT RICORDARSI LA DELETE IN FONDO
--------------------------------------------------------------------------------
CURSOR sel_vers IS
select min(wkta.progressivo)
      ,max(cont.cod_fiscale)                             cod_fiscale
      ,max(sogg.cognome_nome)                            cognome_nome
      ,rtrim(substr(wkta.dati,50,16))                    cod_fiscale_vers
      ,min(wkta.progressivo)                             progressivo
      ,to_number(substr(wkta.dati,88,4))                 anno
      ,w_tipo_tributo                                    tipo_tributo
      ,decode(substr(wkta.dati,128,2)
             ,'00','U','01','S','10','A','11','U',null
             )                                           tipo_versamento
      ,upper(rtrim(substr(wkta.dati,279,18)))            id_operazione
      ,to_date(substr(wkta.dati,67,8),'yyyymmdd')        data_pagamento
      ,'VERSAMENTO IMPORTATO DA MODELLO F24'             descrizione
      ,max(decode(substr(wkta.dati,44,1)
                 ,'B','Banca - ABI '||substr(wkta.dati,39,5)||' CAB '||substr(wkta.dati,45,5)
                 ,'C','Concessionario - Codice '||substr(wkta.dati,39,5)
                 ,'P','Poste - Codice '||substr(wkta.dati,39,5)
                 ,'I','Internet'
                     ,null
                 )
          )                                               ufficio_pt
      --,max(to_date(substr(wkta.dati,67,8),'yyyymmdd'))    data_pagamento
      ,sum((to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100)
                                                          importo_versato
      ,sum(decode(substr(wkta.dati,79,4)
                 ,'3958',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,0
                 )
          )                                               ab_principale
      ,sum(decode(substr(wkta.dati,79,4)
                 ,'3959',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,'374E',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,0
                 )
          )                                               rurali
      ,sum(decode(substr(wkta.dati,79,4)
                 ,'3960',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,'375E',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,0
                 )
          )                                               aree_fabbricabili
      ,sum(decode(substr(wkta.dati,79,4)
                 ,'3961',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,'376E',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,0
                 )
          )                                               altri_fabbricati
      ,max(decode(substr(wkta.dati,79,4)
                 ,'3958',substr(wkta.dati,84,4)
                 ,''
                 )
           )                                              rateazione
/* Questo test lo abbiamo ereditato da IMU pechè un anno è stata gestita la rateazione solo sull''abitazione
   principale. In TASI probabilmente carichiamo sempre 0000 nella rateazione delle abitazioni principali
   che viene poi trasformato in null nella insert in versamenti */
      ,max(decode(substr(wkta.dati,79,4)
                 ,'3958',to_number(substr(wkta.dati,130,3))
                 ,to_number(null)
                 )
          )                                               num_fabbricati_ab
      ,max(decode(substr(wkta.dati,79,4)
                 ,'3959',to_number(substr(wkta.dati,130,3))
                 ,'374E',to_number(substr(wkta.dati,130,3))
                 ,to_number(null)
                 )
          )                                               num_fabbricati_rurali
      ,max(decode(substr(wkta.dati,79,4)
                 ,'3960',to_number(substr(wkta.dati,130,3))
                 ,'375E',to_number(substr(wkta.dati,130,3))
                 ,to_number(null)
                 )
          )                                               num_fabbricati_aree
      ,max(decode(substr(wkta.dati,79,4)
                 ,'3961',to_number(substr(wkta.dati,130,3))
                 ,'376E',to_number(substr(wkta.dati,130,3))
                 ,to_number(null)
                 )
          )                                               num_fabbricati_altri
      ,9                                                  fonte
      ,'F24'                                              utente
      ,trunc(sysdate)                                     data_variazione
      ,max(to_date(substr(wkta.dati,3,8),'yyyymmdd'))     data_reg
      ,sum(to_number(substr(wkta.dati,134,15)) / 100)     detrazione
      ,sum(to_number(substr(wkta.dati,130,3)))            fabbricati
      , 'I'                                               tipo_messaggio
  from wrk_tras_anci         wkta
      ,contribuenti          cont
      ,soggetti              sogg
 where cont.cod_fiscale     (+) = rtrim(substr(wkta.dati,50,16))
   and sogg.ni              (+) = cont.ni
   and wkta.anno                = 2
   and substr(wkta.dati,79,4) in ('3958','3959','3960','3961','374E','375E','376E') -- si escludono gli importi per imposta di scopo
   and to_number(substr(wkta.dati,126,1))  = 1  -- solo versamenti su ravvedimenti
   and substr(wkta.dati,260,1) in ('I','U')     -- TASI (nei primi file c era I adesso hanno messo U)
   and substr(wkta.dati,1,2) = 'G1'             -- Si trattano solo i versamenti
 group by rtrim(substr(wkta.dati,50,16))
         ,to_number(substr(wkta.dati,88,4))
         ,decode(substr(wkta.dati,128,2)
                ,'00','U','01','S','10','A','11','U',null
                )                                       -- Acconto/Saldo
         ,upper(rtrim(substr(wkta.dati,279,18)))        -- id. operazione
         ,to_date(substr(wkta.dati,67,8),'yyyymmdd')    -- data_pagamento
union
select min(wkta.progressivo)
      ,max(cont.cod_fiscale)                             cod_fiscale
      ,max(sogg.cognome_nome)                            cognome_nome
      ,rtrim(substr(wkta.dati,50,16))                    cod_fiscale_vers
      ,min(wkta.progressivo)                             progressivo
      ,to_number(substr(wkta.dati,88,4))                 anno
      ,w_tipo_tributo                                    tipo_tributo
      ,decode(substr(wkta.dati,128,2)
             ,'00','U','01','S','10','A','11','U',null
             )                                           tipo_versamento
      ,upper(rtrim(substr(wkta.dati,279,18)))            id_operazione
      ,to_date(substr(wkta.dati,67,8),'yyyymmdd')        data_pagamento
      ,'VERSAMENTO IMPORTATO DA MODELLO F24'             descrizione
      ,max(decode(substr(wkta.dati,44,1)
                 ,'B','Banca - ABI '||substr(wkta.dati,39,5)||' CAB '||substr(wkta.dati,45,5)
                 ,'C','Concessionario - Codice '||substr(wkta.dati,39,5)
                 ,'P','Poste - Codice '||substr(wkta.dati,39,5)
                 ,'I','Internet'
                     ,null
                 )
          )                                               ufficio_pt
      --,max(to_date(substr(wkta.dati,67,8),'yyyymmdd'))    data_pagamento
      ,sum((to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100)
                                                          importo_versato
      ,to_number(null)                                    ab_principale
      ,to_number(null)                                    rurali
      ,to_number(null)                                    aree_fabbricabili
      ,to_number(null)                                    altri_fabbricati
      ,to_char(null)                                      rateazione
/* Questo test lo abbiamo ereditato da IMU pechè un anno è stata gestita la rateazione solo sull''abitazione
   principale. In TASI probabilmente carichiamo sempre 0000 nella rateazione delle abitazioni principali
   che viene poi trasformato in null nella insert in versamenti */
      ,to_number(null)                                    num_fabbricati_ab
      ,to_number(null)                                    num_fabbricati_rurali
      ,to_number(null)                                    num_fabbricati_aree
      ,to_number(null)                                    num_fabbricati_altri
      ,9                                                  fonte
      ,'F24'                                              utente
      ,trunc(sysdate)                                     data_variazione
      ,max(to_date(substr(wkta.dati,3,8),'yyyymmdd'))     data_reg
      ,sum(to_number(substr(wkta.dati,134,15)) / 100)     detrazione
      ,sum(to_number(substr(wkta.dati,130,3)))            fabbricati
      , 'S'                                               tipo_messaggio
  from wrk_tras_anci         wkta
      ,contribuenti          cont
      ,soggetti              sogg
 where cont.cod_fiscale     (+) = rtrim(substr(wkta.dati,50,16))
   and sogg.ni              (+) = cont.ni
   and wkta.anno                = 2
   and substr(wkta.dati,79,4) in ('3962','3963','377E','378E') -- solo sanzioni e interessi
   and to_number(substr(wkta.dati,126,1))  = 1  -- solo versamenti su ravvedimenti
   and substr(wkta.dati,260,1) in ('I','U')     -- TASI (nei primi file c era I adesso hanno messo U)
   and substr(wkta.dati,1,2) = 'G1'             -- Si trattano solo i versamenti
 group by rtrim(substr(wkta.dati,50,16))
         ,to_number(substr(wkta.dati,88,4))
         ,decode(substr(wkta.dati,128,2)
                ,'00','U','01','S','10','A','11','U',null
                )                                       -- Acconto/Saldo
         ,upper(rtrim(substr(wkta.dati,279,18)))        -- id. operazione
         ,to_date(substr(wkta.dati,67,8),'yyyymmdd')    -- data_pagamento
 order by 1
;
------------------------------------
-- Funzione F_SELEZIONA_PROGRESSIVO
------------------------------------
FUNCTION F_SELEZIONA_PROGRESSIVO
RETURN NUMBER
is
nProgr    number;
BEGIN
   BEGIN
      select nvl(max(progressivo),0)
        into nProgr
        from wrk_versamenti
      ;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         nProgr := 0;
   END;
   nProgr := nProgr + 1;
   RETURN nProgr;
END F_SELEZIONA_PROGRESSIVO;
---------------------------
--  INIZIO ELABORAZIONE  --
---------------------------
BEGIN
-----------------------------------------------------------------------------
-- Trattamento versamenti con contribuente assente in tabella WRK_VERSAMENTI
-----------------------------------------------------------------------------
   FOR rec_ins_cont IN sel_ins_cont  -- gestione flag_contribuente
   LOOP
     if rec_ins_cont.cod_fiscale_cont is null then
        w_cod_fiscale := f_crea_contribuente(rec_ins_cont.cod_fiscale,w_errore);
        if w_cod_fiscale is null then
           if w_errore is not null then
              update wrk_versamenti wkve
                 set note = substr(decode(note,'','',note||' - ')||w_errore,1,2000)
               where wkve.progressivo  = rec_ins_cont.progressivo;
           end if;
        end if;
        /*begin
            select count(1)
              into w_conta_cont
              from contribuenti
             where cod_fiscale = rec_ins_cont.cod_fiscale
                ;
         EXCEPTION
            WHEN others THEN
              w_conta_cont := 0;
         end;
         if w_conta_cont = 0 then
            begin
               select nvl(max(ni),0)
                 into w_ni
                 from soggetti
                where nvl(cod_fiscale,partita_iva) = rec_ins_cont.cod_fiscale
                ;
            EXCEPTION
               WHEN others THEN
                 w_ni := 0;
            end;
            if nvl(w_ni,0) > 0 then
               BEGIN
                  insert into contribuenti
                         (cod_fiscale, ni)
                  values (rec_ins_cont.cod_fiscale,w_ni)
                     ;
               EXCEPTION
                  WHEN others THEN
                      w_errore := 'Errore ins cont cf:'||rec_ins_cont.cod_fiscale||
                                 ' ni:'||to_char(w_ni)||' ('||sqlerrm||')';
                      RAISE errore;
               END;
            end if;
         end if; */
     end if;
   end loop;
------------------------------------------------------------------------
-- Trattamento versamenti con errore caricati in tabella WRK_VERSAMENTI
------------------------------------------------------------------------
   FOR rec_errati IN sel_errati
   LOOP
      if rec_errati.cod_fiscale_cont is null then
         update wrk_versamenti wkve
            set wkve.cognome_nome = rec_errati.cognome_nome
               ,wkve.causale      = '50109'
               ,wkve.note         = decode(rec_errati.tipo_messaggio,'I','Imposta - '
                                                                    ,'S','Sanzioni e Interessi - '
                                                                    ,'')||
                                    'Versamento su Ravvedimento Contribuente ('||rec_errati.cod_fiscale||') sconosciuto'
          where wkve.progressivo  = rec_errati.progressivo
         ;
      else
         w_pratica := F_F24_PRATICA(rec_errati.cod_fiscale,rec_errati.id_operazione,rec_errati.data_pagamento,w_tipo_tributo);
         w_messaggio := null;
         w_crea_ravv := 0;
         if nvl(w_pratica,-1) < 0 then
            w_pratica := to_number(null);
            --
            -- (VD - 30/10/2017): aggiunto controllo su codici sanzione
            -- (VD - 06/06/2020): aggiunto controllo su nuovi codici sanzione
            --                    (ravv. lungo)
            -- (VD - 06/07/2020): aggiunto controllo su esistenza versamenti
            --                    Se esistono gia' dei versamenti associati
            --                    alla pratica, la pratica non e' da considerare
            --
            BEGIN
               select count(*)
                 into w_conta
                 from pratiche_tributo prtr
                where prtr.cod_fiscale            = rec_errati.cod_fiscale
                  and prtr.anno                   = rec_errati.anno
                  and prtr.tipo_tributo           = w_tipo_tributo
                  and prtr.tipo_pratica           = 'V'
                  and exists (select 'x' from sanzioni_pratica sapr
                               where prtr.pratica                     = sapr.pratica
                                 and ( rec_errati.tipo_versamento     = 'A'
                                      and sapr.cod_sanzione           in (151,152,155,157,158,165,166)
                                      or  rec_errati.tipo_versamento  = 'S'
                                      and sapr.cod_sanzione           in (153,154,156,159,160,167,168)
                                      or  rec_errati.tipo_versamento  = 'U'
                                      and sapr.cod_sanzione           in (151,152,153,154,155,
                                                                          156,157,158,159,160,
                                                                          165,166,167,168)
                                     )
                             )
                  -- (VD - 06/07/2020): verifica esistenza versamenti
                  and not exists (select 'x' from versamenti vers
                                   where vers.tipo_tributo = w_tipo_tributo
                                     and vers.anno         = rec_errati.anno
                                     and vers.cod_fiscale  = rec_errati.cod_fiscale
                                     and vers.pratica      = prtr.pratica)
                    ;
            END;
            --
            -- (VD - 30/10/2017): aggiunto controllo su codici sanzione
            -- (VD - 06/06/2020): aggiunto controllo su nuovi codici sanzione
            --                    (ravv. lungo)
            -- (VD - 06/07/2020): aggiunto controllo su esistenza versamenti
            --                    Se esistono gia' dei versamenti associati
            --                    alla pratica, la pratica non e' da considerare
            --
            BEGIN
               select count(*)
                 into w_conta_importo_esatto
                 from pratiche_tributo prtr
                where prtr.cod_fiscale            = rec_errati.cod_fiscale
                  and prtr.anno                   = rec_errati.anno
                  and prtr.tipo_tributo           = w_tipo_tributo
                  and prtr.tipo_pratica           = 'V'
                  and (   prtr.importo_totale          = rec_errati.importo_versato
                       or round(prtr.importo_totale,0) = rec_errati.importo_versato
                      )
                  and exists (select 'x' from sanzioni_pratica sapr
                               where prtr.pratica                     = sapr.pratica
                                 and ( rec_errati.tipo_versamento     = 'A'
                                      and sapr.cod_sanzione           in (151,152,155,157,158,165,166)
                                      or  rec_errati.tipo_versamento  = 'S'
                                      and sapr.cod_sanzione           in (153,154,156,159,160,167,168)
                                      or  rec_errati.tipo_versamento  = 'U'
                                      and sapr.cod_sanzione           in (151,152,153,154,155,
                                                                          156,157,158,159,160,
                                                                          165,166,167,168)
                                     )
                             )
                  -- (VD - 06/07/2020): verifica esistenza versamenti
                  and not exists (select 'x' from versamenti vers
                                   where vers.tipo_tributo = w_tipo_tributo
                                     and vers.anno         = rec_errati.anno
                                     and vers.cod_fiscale  = rec_errati.cod_fiscale
                                     and vers.pratica      = prtr.pratica)
                    ;
            END;
            if w_conta = 0 then
               -- (VD - 06/07/2020): si attiva il flag per creare la pratica
               --                    di ravvedimento
               w_crea_ravv := 1;
            elsif w_conta > 1 and w_conta_importo_esatto <> 1 then
               update wrk_versamenti wkve
                  set wkve.cognome_nome = rec_errati.cognome_nome
                     ,wkve.causale      = '50180'
                     ,wkve.note         = decode(rec_errati.tipo_messaggio,'I','Imposta - '
                                                                          ,'S','Sanzioni e Interessi - '
                                                                          ,'')||
                                                'Versamento su Ravvedimento - Più di una Pratica di Ravvedimento Presente'
                where wkve.progressivo  = rec_errati.progressivo
                    ;
            else
               if w_conta = 1 then
                  --
                  -- (VD - 30/10/2017): aggiunto controllo su codici sanzione
                  -- (VD - 06/06/2020): aggiunto controllo su nuovi codici sanzione
                  --                    (ravv. lungo)
                  -- (VD - 06/07/2020): aggiunto controllo su esistenza versamenti
                  --                    Se esistono gia' dei versamenti associati
                  --                    alla pratica, la pratica non e' da considerare
                  --
                  begin
                     select prtr.pratica
                       into w_pratica
                       from pratiche_tributo prtr
                      where prtr.cod_fiscale            = rec_errati.cod_fiscale
                        and prtr.anno                   = rec_errati.anno
                        and prtr.tipo_tributo           = w_tipo_tributo
                        and prtr.tipo_pratica           = 'V'
                        and exists (select 'x' from sanzioni_pratica sapr
                                     where prtr.pratica                     = sapr.pratica
                                       and ( rec_errati.tipo_versamento     = 'A'
                                            and sapr.cod_sanzione           in (151,152,155,157,158,165,166)
                                            or  rec_errati.tipo_versamento  = 'S'
                                            and sapr.cod_sanzione           in (153,154,156,159,160,167,168)
                                            or  rec_errati.tipo_versamento  = 'U'
                                            and sapr.cod_sanzione           in (151,152,153,154,155,
                                                                                156,157,158,159,160,
                                                                                165,166,167,168)
                                           )
                                   )
                        -- (VD - 06/07/2020): verifica esistenza versamenti
                        and not exists (select 'x' from versamenti vers
                                         where vers.tipo_tributo = w_tipo_tributo
                                           and vers.anno         = rec_errati.anno
                                           and vers.cod_fiscale  = rec_errati.cod_fiscale
                                           and vers.pratica      = prtr.pratica)
                          ;
                  exception
                    when others then
                      w_pratica := to_number(null);
                      w_crea_ravv := 1;
                  end;
               else
                  --
                  -- (VD - 30/10/2017): aggiunto controllo su codici sanzione
                  -- (VD - 06/06/2020): aggiunto controllo su nuovi codici sanzione
                  --                    (ravv. lungo)
                  -- (VD - 06/07/2020): aggiunto controllo su esistenza versamenti
                  --                    Se esistono gia' dei versamenti associati
                  --                    alla pratica, la pratica non e' da considerare
                  --
                  BEGIN
                     select prtr.pratica
                       into w_pratica
                       from pratiche_tributo prtr
                      where prtr.cod_fiscale                 = rec_errati.cod_fiscale
                        and prtr.anno                        = rec_errati.anno
                        and prtr.tipo_tributo                = w_tipo_tributo
                        and prtr.tipo_pratica                = 'V'
                        and (   prtr.importo_totale          = rec_errati.importo_versato
                             or round(prtr.importo_totale,0) = rec_errati.importo_versato
                            )
                        and exists (select 'x' from sanzioni_pratica sapr
                                     where prtr.pratica                     = sapr.pratica
                                       and ( rec_errati.tipo_versamento     = 'A'
                                            and sapr.cod_sanzione           in (151,152,155,157,158,165,166)
                                            or  rec_errati.tipo_versamento  = 'S'
                                            and sapr.cod_sanzione           in (153,154,156,159,160,167,168)
                                            or  rec_errati.tipo_versamento  = 'U'
                                            and sapr.cod_sanzione           in (151,152,153,154,155,
                                                                                156,157,158,159,160,
                                                                                165,166,167,168)
                                           )
                                   )
                        -- (VD - 06/07/2020): verifica esistenza versamenti
                        and not exists (select 'x' from versamenti vers
                                         where vers.tipo_tributo = w_tipo_tributo
                                           and vers.anno         = rec_errati.anno
                                           and vers.cod_fiscale  = rec_errati.cod_fiscale
                                           and vers.pratica      = prtr.pratica)
                          ;
                  exception
                    when others then
                      w_pratica := to_number(null);
                      w_crea_ravv := 1;
                  END;
               end if;
            end if;
         end if;
         -- (VD - 06/07/2020): se non esiste la pratica di ravvedimento,
         -- la si crea
         if w_pratica is null and
            w_crea_ravv = 1 then
            CREA_RAVVEDIMENTO_DA_VERS(rec_errati.cod_fiscale,rec_errati.anno,
                                      rec_errati.data_pagamento,rec_errati.tipo_versamento,
                                      '','TR4',w_tipo_tributo,
                                      to_number(null),rec_errati.importo_versato,
                                      w_pratica,w_messaggio,
                                      rec_errati.ab_principale,
                                      rec_errati.rurali,
                                      0,
                                      0,
                                      rec_errati.aree_fabbricabili,
                                      0,
                                      rec_errati.altri_fabbricati,
                                      0,
                                      0,
                                      0,
                                      0
                                      );
            if w_messaggio is not null then
               --dbms_output.put_line(w_messaggio);
               -- (VD - 06/07/2020): se si rileva un qualche errore in fase
               -- di creazione della pratica, si aggiorna la segnalazione
               -- nel versamento in bonifica (nuovo codice: 50190).
               update wrk_versamenti wkve
                  set wkve.cognome_nome = rec_errati.cognome_nome
                     ,wkve.causale      = '50190'
                     ,wkve.note         = substr(decode(rec_errati.tipo_messaggio,'I','Imposta - '
                                                                                 ,'S','Sanzioni e Interessi - '
                                                                                 ,'')||
                                                 'Versamento su Ravvedimento - Errore in creazione pratica di ravvedimento: '||
                                                 w_messaggio,1,2000)
                where wkve.progressivo  = rec_errati.progressivo;
               --dbms_output.put_line('Dopo update');
            end if;
         end if;
         if w_pratica is not null and w_messaggio is null then
            /*BEGIN -- Assegnazione Numero Progressivo
               select nvl(max(vers.sequenza),0)+1
                 into w_sequenza
                 from versamenti vers
                where vers.cod_fiscale     = rec_errati.cod_fiscale
                  and vers.anno            = rec_errati.anno
                  and vers.tipo_tributo    = w_tipo_tributo
                    ;
            END;*/
            w_sequenza := to_number(null);
            VERSAMENTI_NR ( rec_errati.cod_fiscale, rec_errati.anno
                          , w_tipo_tributo, w_sequenza );
            BEGIN
               insert into versamenti
                     (cod_fiscale
                     ,anno
                     ,tipo_tributo
                     ,sequenza
                     ,tipo_versamento
                     ,descrizione
                     ,ufficio_pt
                     ,data_pagamento
                     ,importo_versato
                     ,fonte
                     ,detrazione
                     ,utente
                     ,data_variazione
                     ,data_reg
                     ,fabbricati
                     ,ab_principale
                     ,rurali
                     ,aree_fabbricabili
                     ,altri_fabbricati
                     ,pratica
                     ,num_fabbricati_ab
                     ,num_fabbricati_rurali
                     ,num_fabbricati_aree
                     ,num_fabbricati_altri
                     ,rata
                     ,note
                     ,documento_id
                     )
               select rec_errati.cod_fiscale
                     ,rec_errati.anno
                     ,w_tipo_tributo
                     ,w_sequenza
                     ,rec_errati.tipo_versamento
                     ,'VERSAMENTO IMPORTATO DA MODELLO F24'
                     ,rec_errati.ufficio_pt
                     ,rec_errati.data_pagamento
                     ,rec_errati.importo_versato
                     ,9
                     ,rec_errati.detrazione
                     ,'F24'
                     ,trunc(sysdate)
                     ,rec_errati.data_reg
                     ,rec_errati.fabbricati
                     ,rec_errati.ab_principale
                     ,rec_errati.rurali
                     ,rec_errati.aree_fabbricabili
                     ,rec_errati.altri_fabbricati
                     ,w_pratica
                     ,rec_errati.num_fabbricati_ab
                     ,rec_errati.num_fabbricati_rurali
                     ,rec_errati.num_fabbricati_aree
                     ,rec_errati.num_fabbricati_altri
                     --(VD - 25/09/2018): la rata viene ricavata dal
                     -- dato originale dell'F24
                     --,rec_errati.rata
                     ,decode(rec_errati.rateazione
                            ,null,rec_errati.rata
                            ,'0101',11
                            ,'0102',12
                            ,'0202',22
                            ,to_number(null)
                            )
                     ,f_f24_note_versamento(rec_errati.id_operazione
                                           ,w_pratica
                                           ,rec_errati.tipo_messaggio
                                           ,rec_errati.documento_id
                                           ,w_tipo_tributo
                                           ,null
                                           ,null
                                           ,rec_errati.note_versamento
                                           )
                     ,rec_errati.documento_id
                 from dual
               ;
            EXCEPTION
               WHEN others THEN
                  w_errore := 'Errore in inserimento versamento bonificato'||
                              ' di '||rec_errati.cod_fiscale||' progressivo '||
                              to_char(rec_errati.progressivo)||' ('||sqlerrm||')';
                  RAISE errore;
            END;
            delete from wrk_versamenti wkve
             where wkve.progressivo  = rec_errati.progressivo
                 ;
         end if;
      end if;
   END LOOP;
------------------------------------------------------------
-- Trattamento versamenti caricati in tabella WRK_TRAS_ANCI
------------------------------------------------------------
   FOR rec_vers IN sel_vers
   LOOP
      -- (VD - 24/06/2021): se il contribuente non esiste ma esiste un
      --                    soggetto con lo stesso codice fiscale, si crea
      --                    un nuovo contribuente
      if rec_vers.cod_fiscale is null then
         w_cod_fiscale := f_crea_contribuente(rec_vers.cod_fiscale_vers,w_errore);
         if w_cod_fiscale is null then
            w_progressivo := F_SELEZIONA_PROGRESSIVO;
            insert into wrk_versamenti
                  (progressivo,tipo_tributo,tipo_incasso,anno,ruolo,cod_fiscale,
                   cognome_nome,causale,disposizione,data_variazione,note,
                   tipo_versamento,ufficio_pt,data_pagamento,
                   ab_principale,rurali,
                   aree_fabbricabili,altri_fabbricati,
                   data_reg,detrazione,fabbricati
                  ,importo_versato
                  ,num_fabbricati_ab
                  ,num_fabbricati_rurali
                  ,num_fabbricati_aree
                  ,num_fabbricati_altri
                  ,rata
                  ,identificativo_operazione
                  ,documento_id
                  ,rateazione
                  )
            values(w_progressivo,w_tipo_tributo,'F24',rec_vers.anno,null,rec_vers.cod_fiscale_vers,
                   rec_vers.cognome_nome,'50109',w_progressivo,sysdate,
                   decode(rec_vers.tipo_messaggio,'I','Imposta - ',
                                                  'S','Sanzioni e interessi - ')||
                         'Versamento su Ravvedimento: Contribuente ('||rec_vers.cod_fiscale_vers||') sconosciuto',
                   rec_vers.tipo_versamento,rec_vers.ufficio_pt,rec_vers.data_pagamento,
                   rec_vers.ab_principale,rec_vers.rurali,
                   rec_vers.aree_fabbricabili,rec_vers.altri_fabbricati,
                   rec_vers.data_reg,rec_vers.detrazione,rec_vers.fabbricati
                  ,rec_vers.importo_versato
                  ,rec_vers.num_fabbricati_ab
                  ,rec_vers.num_fabbricati_rurali
                  ,rec_vers.num_fabbricati_aree
                  ,rec_vers.num_fabbricati_altri
                  -- (VD - 25/09/2018): la rata verrà ricavata dal campo rateazione
                  --,decode(rec_vers.rateazione
                  --       ,'0101',11
                  --       ,'0102',12
                  --       ,'0202',22
                  --       ,to_number(null)
                  --       )
                  ,to_number(null)
                  ,rec_vers.id_operazione
                  ,a_documento_id
                  ,rec_vers.rateazione
                  );
         end if;
      else
         w_cod_fiscale := rec_vers.cod_fiscale;
      end if;
      -- (VD - 24/06/2021): se il contribuente esisteva gia' oppure e' appena
      --                    stato inserito, si prosegue il trattamento
      if w_cod_fiscale is not null then
         w_messaggio := null;
         --w_pratica := F_F24_PRATICA(rec_vers.cod_fiscale,rec_vers.id_operazione,rec_vers.data_pagamento,w_tipo_tributo);
         w_pratica := F_F24_PRATICA(w_cod_fiscale,rec_vers.id_operazione,rec_vers.data_pagamento,w_tipo_tributo);
         if nvl(w_pratica,-1) < 0 then
            w_pratica := to_number(null);
            w_crea_ravv:= 0;
            --
            -- (VD - 30/10/2017): aggiunto controllo su codici sanzione
            -- (VD - 06/06/2020): aggiunto controllo su nuovi codici sanzione
            --                    (ravv. lungo)
            -- (VD - 06/07/2020): aggiunto controllo su esistenza versamenti
            --                    Se esistono gia' dei versamenti associati
            --                    alla pratica, la pratica non e' da considerare            --
            BEGIN
               select count(*)
                 into w_conta
                 from pratiche_tributo prtr
                where prtr.cod_fiscale            = w_cod_fiscale --rec_vers.cod_fiscale
                  and prtr.anno                   = rec_vers.anno
                  and prtr.tipo_tributo           = rec_vers.tipo_tributo
                  and prtr.tipo_pratica           = 'V'
                  and exists (select 'x' from sanzioni_pratica sapr
                               where prtr.pratica                   = sapr.pratica
                                 and ( rec_vers.tipo_versamento     = 'A'
                                      and sapr.cod_sanzione           in (151,152,155,157,158,165,166)
                                      or  rec_vers.tipo_versamento  = 'S'
                                      and sapr.cod_sanzione           in (153,154,156,159,160,167,168)
                                      or  rec_vers.tipo_versamento  = 'U'
                                      and sapr.cod_sanzione           in (151,152,153,154,155,
                                                                          156,157,158,159,160,
                                                                          165,166,167,168)
                                     )
                             )
                  -- (VD - 06/07/2020): verifica esistenza versamenti
                  and not exists (select 'x' from versamenti vers
                                   where vers.tipo_tributo = rec_vers.tipo_tributo
                                     and vers.anno         = rec_vers.anno
                                     and vers.cod_fiscale  = w_cod_fiscale --rec_vers.cod_fiscale
                                     and vers.pratica      = prtr.pratica)
                    ;
            END;
            --
            -- (VD - 30/10/2017): aggiunto controllo su codici sanzione
            -- (VD - 06/06/2020): aggiunto controllo su nuovi codici sanzione
            --                    (ravv. lungo)
            -- (VD - 06/07/2020): aggiunto controllo su esistenza versamenti
            --                    Se esistono gia' dei versamenti associati
            --                    alla pratica, la pratica non e' da considerare
            --
            BEGIN
               select count(*)
                 into w_conta_importo_esatto
                 from pratiche_tributo prtr
                where prtr.cod_fiscale            = w_cod_fiscale --rec_vers.cod_fiscale
                  and prtr.anno                   = rec_vers.anno
                  and prtr.tipo_tributo           = rec_vers.tipo_tributo
                  and prtr.tipo_pratica           = 'V'
                  and (   prtr.importo_totale          = rec_vers.importo_versato
                       or round(prtr.importo_totale,0) = rec_vers.importo_versato
                      )
                  and exists (select 'x' from sanzioni_pratica sapr
                               where prtr.pratica                   = sapr.pratica
                                 and ( rec_vers.tipo_versamento     = 'A'
                                      and sapr.cod_sanzione           in (151,152,155,157,158,165,166)
                                      or  rec_vers.tipo_versamento  = 'S'
                                      and sapr.cod_sanzione           in (153,154,156,159,160,167,168)
                                      or  rec_vers.tipo_versamento  = 'U'
                                      and sapr.cod_sanzione           in (151,152,153,154,155,
                                                                          156,157,158,159,160,
                                                                          165,166,167,168)
                                     )
                             )
                  and not exists (select 'x' from versamenti vers
                                   where vers.tipo_tributo = rec_vers.tipo_tributo
                                     and vers.anno         = rec_vers.anno
                                     and vers.cod_fiscale  = w_cod_fiscale --rec_vers.cod_fiscale
                                     and vers.pratica      = prtr.pratica)
                    ;
            END;
            if w_conta = 0 then
               -- (VD - 06/07/2020): si attiva il flag per creare la pratica
               --                    di ravvedimento
               w_crea_ravv := 1;
            elsif w_conta > 1 and w_conta_importo_esatto <> 1 then
               w_progressivo := F_SELEZIONA_PROGRESSIVO;
               insert into wrk_versamenti
                     (progressivo,tipo_tributo,tipo_incasso,anno,ruolo,cod_fiscale,
                      cognome_nome,causale,disposizione,data_variazione,note,
                      tipo_versamento,ufficio_pt,data_pagamento,
                      ab_principale,rurali,
                      aree_fabbricabili,altri_fabbricati,
                      data_reg,detrazione,fabbricati,importo_versato
                     ,num_fabbricati_ab
                     ,num_fabbricati_rurali
                     ,num_fabbricati_aree
                     ,num_fabbricati_altri
                     ,rata
                     ,identificativo_operazione
                     ,documento_id
                     ,rateazione
                     )
               values(w_progressivo,w_tipo_tributo,'F24',rec_vers.anno,null,rec_vers.cod_fiscale_vers,
                      rec_vers.cognome_nome,'50180',w_progressivo,sysdate,
                      decode(rec_vers.tipo_messaggio,'I','Imposta - ',
                                                     'S','Sanzioni e interessi - ')||
                            'Versamento su Ravvedimento - Più di una Pratica di Ravvedimento Presente',
                      rec_vers.tipo_versamento,rec_vers.ufficio_pt,rec_vers.data_pagamento,
                      rec_vers.ab_principale,rec_vers.rurali,
                      rec_vers.aree_fabbricabili,rec_vers.altri_fabbricati,
                      rec_vers.data_reg,rec_vers.detrazione,rec_vers.fabbricati,
                      rec_vers.importo_versato
                     ,rec_vers.num_fabbricati_ab
                     ,rec_vers.num_fabbricati_rurali
                     ,rec_vers.num_fabbricati_aree
                     ,rec_vers.num_fabbricati_altri
                     -- (VD - 25/09/2018): la rata verrà ricavata dal campo rateazione
                     --,decode(rec_vers.rateazione
                     --       ,'0101',11
                     --       ,'0102',12
                     --       ,'0202',22
                     --       ,to_number(null)
                     --       )
                     ,to_number(null)
                     ,rec_vers.id_operazione
                     ,a_documento_id
                     ,rec_vers.rateazione
                     );
            else
               if w_conta = 1 then
                  --
                  -- (VD - 30/10/2017): aggiunto controllo su codici sanzione
                  -- (VD - 06/06/2020): aggiunto controllo su nuovi codici sanzione
                  --                    (ravv. lungo)
                  -- (VD - 06/07/2020): aggiunto controllo su esistenza versamenti
                  --                    Se esistono gia' dei versamenti associati
                  --                    alla pratica, la pratica non e' da considerare
                  --
                  begin
                     select prtr.pratica
                       into w_pratica
                       from pratiche_tributo prtr
                      where prtr.cod_fiscale            = w_cod_fiscale --rec_vers.cod_fiscale
                        and prtr.anno                   = rec_vers.anno
                        and prtr.tipo_tributo           = rec_vers.tipo_tributo
                        and prtr.tipo_pratica           = 'V'
                        and exists (select 'x' from sanzioni_pratica sapr
                                     where prtr.pratica                   = sapr.pratica
                                       and ( rec_vers.tipo_versamento     = 'A'
                                            and sapr.cod_sanzione           in (151,152,155,157,158,165,166)
                                            or  rec_vers.tipo_versamento  = 'S'
                                            and sapr.cod_sanzione           in (153,154,156,159,160,167,168)
                                            or  rec_vers.tipo_versamento  = 'U'
                                            and sapr.cod_sanzione           in (151,152,153,154,155,
                                                                                156,157,158,159,160,
                                                                                165,166,167,168)
                                           )
                                   )
                        and not exists (select 'x' from versamenti vers
                                         where vers.tipo_tributo = rec_vers.tipo_tributo
                                           and vers.anno         = rec_vers.anno
                                           and vers.cod_fiscale  = w_cod_fiscale --rec_vers.cod_fiscale
                                           and vers.pratica      = prtr.pratica)
                          ;
                  exception
                    when others then
                      w_pratica := to_number(null);
                  end;
               else
                  --
                  -- (VD - 30/10/2017): aggiunto controllo su codici sanzione
                  -- (VD - 06/06/2020): aggiunto controllo su nuovi codici sanzione
                  --                    (ravv. lungo)
                  -- (VD - 06/07/2020): aggiunto controllo su esistenza versamenti
                  --                    Se esistono gia' dei versamenti associati
                  --                    alla pratica, la pratica non e' da considerare
                  --
                  BEGIN
                     select prtr.pratica
                       into w_pratica
                       from pratiche_tributo prtr
                      where prtr.cod_fiscale                 = w_cod_fiscale --rec_vers.cod_fiscale
                        and prtr.anno                        = rec_vers.anno
                        and prtr.tipo_tributo                = rec_vers.tipo_tributo
                        and prtr.tipo_pratica                = 'V'
                        and (   prtr.importo_totale          = rec_vers.importo_versato
                             or round(prtr.importo_totale,0) = rec_vers.importo_versato
                            )
                        and exists (select 'x' from sanzioni_pratica sapr
                                     where prtr.pratica                   = sapr.pratica
                                       and ( rec_vers.tipo_versamento     = 'A'
                                            and sapr.cod_sanzione           in (151,152,155,157,158,165,166)
                                            or  rec_vers.tipo_versamento  = 'S'
                                            and sapr.cod_sanzione           in (153,154,156,159,160,167,168)
                                            or  rec_vers.tipo_versamento  = 'U'
                                            and sapr.cod_sanzione           in (151,152,153,154,155,
                                                                                156,157,158,159,160,
                                                                                165,166,167,168)
                                           )
                                   )
                        -- (VD - 06/07/2020): verifica esistenza versamenti
                        and not exists (select 'x' from versamenti vers
                                         where vers.tipo_tributo = rec_vers.tipo_tributo
                                           and vers.anno         = rec_vers.anno
                                           and vers.cod_fiscale  = w_cod_fiscale --rec_vers.cod_fiscale
                                           and vers.pratica      = prtr.pratica)
                          ;
                  exception
                    when others then
                      w_pratica := to_number(null);
                  END;
               end if;
            end if;
         end if;
         -- (VD - 06/07/2020): se non esiste la pratica di ravvedimento,
         -- la si crea
         if w_pratica is null and
            w_crea_ravv = 1 then
            --CREA_RAVVEDIMENTO_DA_VERS(rec_vers.cod_fiscale,rec_vers.anno,
            CREA_RAVVEDIMENTO_DA_VERS(w_cod_fiscale,rec_vers.anno,
                                      rec_vers.data_pagamento,rec_vers.tipo_versamento,
                                      '','TR4',w_tipo_tributo,
                                      to_number(null),rec_vers.importo_versato,
                                      w_pratica,w_messaggio,
                                      rec_vers.ab_principale,
                                      rec_vers.rurali,
                                      0,
                                      0,
                                      rec_vers.aree_fabbricabili,
                                      0,
                                      rec_vers.altri_fabbricati,
                                      0,
                                      0,
                                      0,
                                      0
                                      );
            if w_messaggio is not null then
               -- (VD - 06/07/2020): se si rileva un qualche errore in fase
               -- di creazione della pratica, si lascia il versamento
               -- in bonifica (nuovo codice: 50190) e si cancella il versamento
               -- appena inserito.
               w_progressivo := F_SELEZIONA_PROGRESSIVO;
               insert into wrk_versamenti
                     (progressivo,tipo_tributo,tipo_incasso,anno,ruolo,cod_fiscale,
                      cognome_nome,causale,disposizione,data_variazione,note,
                      tipo_versamento,ufficio_pt,data_pagamento,
                      ab_principale,rurali,
                      aree_fabbricabili,altri_fabbricati,
                      data_reg,detrazione,fabbricati
                     ,importo_versato
                     ,num_fabbricati_ab
                     ,num_fabbricati_rurali
                     ,num_fabbricati_aree
                     ,num_fabbricati_altri
                     ,rata
                     ,identificativo_operazione
                     ,documento_id
                     ,rateazione
                     )
               values(w_progressivo,w_tipo_tributo,'F24',rec_vers.anno,null,rec_vers.cod_fiscale_vers,
                      rec_vers.cognome_nome,'50190',w_progressivo,sysdate,
                      substr(decode(rec_vers.tipo_messaggio,'I','Imposta - ',
                                                        'S','Sanzioni e interessi - ')||
                               'Versamento su Ravvedimento - Errore in creazione pratica di ravvedimento: '||w_messaggio,1.2000),
                      rec_vers.tipo_versamento,rec_vers.ufficio_pt,rec_vers.data_pagamento,
                      rec_vers.ab_principale,rec_vers.rurali,
                      rec_vers.aree_fabbricabili,rec_vers.altri_fabbricati,
                      rec_vers.data_reg,rec_vers.detrazione,rec_vers.fabbricati
                     ,rec_vers.importo_versato
                     ,rec_vers.num_fabbricati_ab
                     ,rec_vers.num_fabbricati_rurali
                     ,rec_vers.num_fabbricati_aree
                     ,rec_vers.num_fabbricati_altri
                     -- (VD - 25/09/2018): la rata verrà ricavata dal campo rateazione
                     --,decode(rec_vers.rateazione
                     --       ,'0101',11
                     --       ,'0102',12
                     --       ,'0202',22
                     --       ,to_number(null)
                     --       )
                     ,to_number(null)
                     ,rec_vers.id_operazione
                     ,a_documento_id
                     ,rec_vers.rateazione
                     );
            end if;
         end if;
         if w_pratica is not null and w_messaggio is null then
            -- (VD - 06/07/2020): se si e' trovata una pratica di ravvedimento
            --                    senza versamenti oppure e' stato attivato
            --                    il flag per crearne una nuova, si inserisce
            --                    il versamento che servirà da base per la
            --                    creazione della pratica stessa
            /*BEGIN -- Assegnazione Numero Progressivo
               select nvl(max(vers.sequenza),0)+1
                 into w_sequenza
                 from versamenti vers
                where vers.cod_fiscale     = rec_vers.cod_fiscale
                  and vers.anno            = rec_vers.anno
                  and vers.tipo_tributo    = rec_vers.tipo_tributo
               ;
            END;*/
            w_sequenza := to_number(null);
            VERSAMENTI_NR ( w_cod_fiscale, rec_vers.anno
                          , w_tipo_tributo, w_sequenza );
            BEGIN
               insert into versamenti
                     (cod_fiscale
                     ,anno
                     ,tipo_tributo
                     ,sequenza
                     ,tipo_versamento
                     ,descrizione
                     ,ufficio_pt
                     ,data_pagamento
                     ,importo_versato
                     ,fonte
                     ,detrazione
                     ,utente
                     ,data_variazione
                     ,data_reg
                     ,fabbricati
                     ,ab_principale
                     ,rurali
                     ,aree_fabbricabili
                     ,altri_fabbricati
                     ,pratica
                     ,num_fabbricati_ab
                     ,num_fabbricati_rurali
                     ,num_fabbricati_aree
                     ,num_fabbricati_altri
                     ,rata
                     ,note
                     ,documento_id
                     )
               values(w_cod_fiscale --rec_vers.cod_fiscale
                     ,rec_vers.anno
                     ,rec_vers.tipo_tributo
                     ,w_sequenza
                     ,rec_vers.tipo_versamento
                     ,rec_vers.descrizione
                     ,rec_vers.ufficio_pt
                     ,rec_vers.data_pagamento
                     ,rec_vers.importo_versato
                     ,rec_vers.fonte
                     ,rec_vers.detrazione
                     ,rec_vers.utente
                     ,rec_vers.data_variazione
                     ,rec_vers.data_reg
                     ,rec_vers.fabbricati
                     ,rec_vers.ab_principale
                     ,rec_vers.rurali
                     ,rec_vers.aree_fabbricabili
                     ,rec_vers.altri_fabbricati
                     ,w_pratica
                     ,rec_vers.num_fabbricati_ab
                     ,rec_vers.num_fabbricati_rurali
                     ,rec_vers.num_fabbricati_aree
                     ,rec_vers.num_fabbricati_altri
                     -- (VD - 25/09/2018): in caso di ravvedimento,
                     -- la pratica esiste ma le rate si ricavano
                     -- dalla rateazione del versamento (e non
                     -- dall'identificativo operazione)
                     ,decode(rec_vers.rateazione
                            ,'0101',11
                            ,'0102',12
                            ,'0202',22
                            ,to_number(null)
                            )
                     ,f_f24_note_versamento(rec_vers.id_operazione
                                           ,w_pratica
                                           ,rec_vers.tipo_messaggio
                                           ,a_documento_id
                                           ,w_tipo_tributo
                                           )
                     ,a_documento_id
                     )
               ;
            EXCEPTION
               WHEN others THEN
                  w_errore := 'Errore in inserimento versamento'||
                              ' di '||w_cod_fiscale||' progressivo '||
                              to_char(rec_vers.progressivo)||' ('||sqlerrm||')';
                  RAISE errore;
            END;
         end if;
      end if;
      --
      -- Si eliminano le righe di wrk_tras_anci trattate in questa fase
      -- (VD - 16/05/2017): aggiunta condizione di where su data pagamento
      --
      BEGIN
         delete wrk_tras_anci wkta
          where rtrim(substr(wkta.dati,50,16))      = rec_vers.cod_fiscale_vers
            and to_number(substr(wkta.dati,88,4))   = rec_vers.anno
            and decode(substr(wkta.dati,128,2),'00','U','01','S','10','A','11','U',null)
                                                    = rec_vers.tipo_versamento
            and wkta.anno                           = 2
            and ((rec_vers.tipo_messaggio = 'I' and
                  substr(wkta.dati,79,4) in ('3958','3959','3960','3961','374E','375E','376E')) or -- si escludono gli importi per imposta di scopo
                 (rec_vers.tipo_messaggio = 'S' and
                  substr(wkta.dati,79,4)  in('3962','3963','377E','378E')))
            and to_number(substr(wkta.dati,126,1))  = 1  -- solo versamenti su ravvedimenti
            and substr(wkta.dati,260,1) in ('I','U')     -- TASI (nei primi file c era I adesso hanno messo U)
            and substr(wkta.dati,1,2)   = 'G1'           -- Si trattano solo i versamenti
            and nvl(upper(rtrim(substr(wkta.dati,279,18))),'*') = nvl(rec_vers.id_operazione,'*')
            and substr(wkta.dati,67,8) = to_char(rec_vers.data_pagamento,'yyyymmdd')
         ;
      EXCEPTION
         WHEN others THEN
            w_errore := 'Errore in eliminazione wrk_tras_anci'||
                        ' progressivo '||to_char(rec_vers.progressivo)||
                        ' ('||sqlerrm||')';
            RAISE errore;
      END;
   END LOOP;
EXCEPTION
   WHEN errore THEN
      RAISE_APPLICATION_ERROR(-20999,w_errore);
END;
/* End Procedure: CARICA_VERS_RAVV_TASI_F24 */
/

