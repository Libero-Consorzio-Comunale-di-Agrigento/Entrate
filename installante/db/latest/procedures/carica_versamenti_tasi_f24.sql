--liquibase formatted sql 
--changeset abrandolini:20250326_152423_carica_versamenti_tasi_f24 stripComments:false runOnChange:true 
 
CREATE OR REPLACE procedure         CARICA_VERSAMENTI_TASI_F24
/*************************************************************************
 Versione  Data        Autore    Descrizione
 018       05/09/2023  VM        #66516
 017       16/03/2023  VM        #55165 - Aggiunto parametro a_cod_fiscale.
                                 Aggiunto filtro cod_fiscale su popolamento cursori.
 016       14/03/2023  VM        #60197 - Aggiunto il parametro a_log_documento
                                 che viene passato alla subprocedure per la
                                 valorizzazione di eventuali errori
 15        24/01/2023  AB        Sistyemata la decode per determinare la causale
                                 Prima poteva uscire anche il null perchè era:
                                 decode(w_rata_pratica,'50000','50362')
                                 anziche decode(w_rata_pratica,0,'50000','50362')
                                 Modificata gestione contribuente assente:
 14        24/06/2021  VD        Modificata gestione contribuente assente:
                                 ora il contribuente viene inserito anche
                                 in fase di caricamento da file (sempre se
                                 esiste gia' il soggetto).
 13        07/04/2021  VD        Modificata gestione contribuente assente:
                                 aggiunti controlli per evitare l'inserimento
                                 di NI già presenti in CONTRIBUENTI.
                                 Creata funzione interna F_CHECK_VERSAMENTI
                                 per verificare se il versamento che si sta
                                 caricando esiste gia', richiamata al posto
                                 delle select nel trattamento dei versamenti
                                 in bonifica e dei versamenti da file.
 12        17/02/2021  VD        Modificata gestione contribuente assente:
                                 il contribuente viene creato comunque se
                                 esiste l'anagrafica in SOGGETTI.
 11        11/01/2021  VD        Gestione nuovo campo note_versamento
                                 della tabella WRK_VERSAMENTI: il contenuto
                                 viene copiato nel campo note della tabella
                                 VERSAMENTI.
 10        16/06/2020  VD        Corretta gestione versamenti su violazione:
                                 si trattano solo i versamenti in bonifica
                                 relativi alle causali 50000 e 50009
                                 (versamenti di imposta)
 9         25/09/2018  VD        Modifiche per gestione versamenti su
                                 pratiche rateizzate
 8         16/05/2017  VD        Aggiunto raggruppamento per data versamento
                                 per gestire versamenti dello stesso tipo
                                 effettuati in date diverse
 7         05/07/2016  VD        Aggiunto caricamento revoche e ripristini
                                 per tipo tributo TASI
 6         15/06/2016  VD        Aggiunto controllo tipo record in query principale:
                                 si trattano solo i record G1 - versamenti
 5         04/12/2015  VD        Aggiunta upper in selezione id_operazione
 4         16/01/2015  VD        Aggiunta gestione documento_id e nome_documento
 3         12/12/2014  VD        Aggiunta gestione nuovo campo IDENTIFICATIVO_OPERAZIONE
                                 In realtà nei versamenti "normali" tale identificativo
                                 non viene gestito, quindi se è valorizzato ma la pratica
                                 non esiste in PRATICHE_TRIBUTO, si considera null.
                                 Viene comunque gestito l inserimento sia nella riga di
                                 VERSAMENTI che in quella di WRK_VERSAMENTI.
 2         10/11/2014  Betta T.  Ricontrollati codici tributo per allinearli
                                 ai dati estratti
 1         14/10/2014  Betta T.  Cambiato il test su tipo imposta per modifiche
                                 al tracciato del ministero
 Causali errore:       50000     Versamento già presente
                       50009     Contribuente non codificato
                       --50350     Pratica non presente o incongruente
                       --50351     Data Pagamento precedente a Data Notifica Pratica
                       --50352     Pratica non Notificata
                       --50360     Pratica rateizzata: versamento antecedente
                       --          alla data di rateazione
                       --50361     Pratica rateizzata: rata errata
                       --50362     Pratica rateizzata: rata gia' versata
 Codici tributo utilizzati
 3958 - TASI- TRIBUTO PER I SERVIZI INDIVISIBILI SU ABITAZIONE PRINCIPALE E
        RELATIVE PERTINENZE ART.1.C.639-L.N.147/2013 E SUCCESSIVE MODIFICAZIONI
 3959 - TASI- TRIBUTO PER I SERVIZI INDIVISIBILI PER FABBRICATI RURALI AD USO
        STRUMENTALE-ART.1.C.639-L.N.147/2013 E SUCCESSIVE MODIFICAZIONI
 3960 - TASI- TRIBUTO PER I SERVIZI INDIVISIBILI PER LE AREE FABBRICABILI -
        ART.1.C.639-L.N.147/2013 E SUCCESSIVE MODIFICAZIONI
 3961 - TASI- TRIBUTO PER I SERVIZI INDIVISIBILI PER ALTRI FABBRICATI -
        ART.1.C.639-L.N.147/2013 E SUCCESSIVE MODIFICAZIONI
 3962 - TASI- TRIBUTO PER I SERVIZI INDIVISIBILI -ART.1.C.639-L.N.147/2013 E
        SUCCESSIVE MODIFICHE-INTERESSI
 3963 - TASI- TRIBUTO PER I SERVIZI INDIVISIBILI -ART.1.C.639-L.N.147/2013 E
        SUCCESSIVE MODIFICAZIONI-SANZIONI
 374E - TASI - tributo per i servizi indivisibili per fabbricati rurali ad
        uso strumentale - art. 1, c. 639, L.n.147/2013 e succ. modif.
 375E - TASI - tributo per i servizi indivisibili per le aree fabbricabili
        - art.1, c. 639,L.n.147/2013 e succ. modif.
 376E - TASI - tributo per i servizi indivisibili per altri fabbricati -
        art. 1, c. 639, L.n.147/2013 e succ.modif.
 377E - TASI - tributo per i servizi indivisibili - art. 1, c. 639,
        L.n.147/2013 e succ. modif. -INTERESSI
 378E - TASI - tributo per i servizi indivisibili - art. 1, c. 639, L. n.
        147/2013 e succ.modif. SANZIONI
*************************************************************************/
( a_documento_id            documenti_caricati.documento_id%type default null,
  a_cod_fiscale             in                                   varchar2 default '%',
  a_log_documento           in out                               varchar2)
IS
w_tipo_tributo       varchar2(5) := 'TASI';
w_progressivo        number;
w_sequenza           number;
w_conta              number;
w_conta_cont         number;
w_ni                 number;
w_pratica            number;
w_anno_pratica       number;
w_rata_pratica       number;
w_cod_fiscale        varchar2(16);
w_errore             varchar2(2000);
errore               exception;
w_count_viol_delega  number;
-- nella prima fase faccio diventare contribuenti i titolari dei versamenti
-- per cui è stato indicato il flag_contribuente
-- (VD - 12/12/2014): Aggiunta selezione id. operazione
-- (VD - 04/12/2015): Aggiunta upper in selezione id. operazione
-- (VD - 11/01/2021): Aggiunta selezione nuovo campo note_versamento
-- (VD - 17/02/2021): Eliminata condizione di where su flag_contribuente:
--                    ora il contribuente viene creato comunque se esiste
--                    l'anagrafica in soggetti.
cursor sel_ins_cont is
select wkve.progressivo                  progressivo
      ,wkve.anno                         anno
      ,wkve.cod_fiscale                  cod_fiscale
      ,wkve.importo_versato              importo_versato
      ,wkve.ab_principale                ab_principale
      ,wkve.terreni_agricoli             terreni_agricoli
      ,wkve.aree_fabbricabili            aree_fabbricabili
      ,wkve.altri_fabbricati             altri_fabbricati
      ,wkve.detrazione                   detrazione
      ,wkve.fabbricati                   fabbricati
      ,wkve.tipo_versamento              tipo_versamento
      ,wkve.data_pagamento               data_pagamento
      ,wkve.ufficio_pt                   ufficio_pt
      ,wkve.data_reg                     data_reg
      ,wkve.flag_contribuente            flag_contribuente
      ,cont.cod_fiscale                  cod_fiscale_cont
      ,sogg.cognome_nome                 cognome_nome
      ,wkve.rurali
      ,wkve.terreni_erariale
      ,wkve.terreni_comune
      ,wkve.aree_erariale
      ,wkve.aree_comune
      ,wkve.altri_erariale
      ,wkve.altri_comune
      ,wkve.num_fabbricati_ab
      ,wkve.num_fabbricati_rurali
      ,wkve.num_fabbricati_terreni
      ,wkve.num_fabbricati_aree
      ,wkve.num_fabbricati_altri
      ,wkve.rata
      ,wkve.fabbricati_d
      ,wkve.fabbricati_d_erariale
      ,wkve.fabbricati_d_comune
      ,wkve.num_fabbricati_d
      ,wkve.rurali_erariale
      ,wkve.rurali_comune
      ,upper(wkve.identificativo_operazione)    id_operazione
      ,substr(wkve.note,1,1)                    tipo_messaggio
      ,wkve.documento_id
      ,wkve.rateazione
      ,wkve.sanzioni_1
      ,wkve.interessi
      ,wkve.note_versamento
  from wrk_versamenti wkve
      ,contribuenti   cont
      ,soggetti       sogg
 where wkve.tipo_incasso    = 'F24'
   and wkve.tipo_tributo    = w_tipo_tributo
   and wkve.CAUSALE         ='50009'
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
-- (VD - 12/12/2014): Aggiunta selezione id. operazione
-- (VD - 04/12/2015): Aggiunta upper in selezione id. operazione
-- (VD - 16/06/2020): Si trattano solo versamenti di imposta (causali 50000 e 50009)
-- (VD - 11/01/2021): Aggiunta selezione nuovo campo note_versamento
--
cursor sel_errati is
select wkve.progressivo                  progressivo
      ,wkve.anno                         anno
      ,wkve.cod_fiscale                  cod_fiscale
      ,wkve.importo_versato              importo_versato
      ,wkve.ab_principale                ab_principale
      ,wkve.terreni_agricoli             terreni_agricoli
      ,wkve.aree_fabbricabili            aree_fabbricabili
      ,wkve.altri_fabbricati             altri_fabbricati
      ,wkve.detrazione                   detrazione
      ,wkve.fabbricati                   fabbricati
      ,wkve.tipo_versamento              tipo_versamento
      ,wkve.data_pagamento               data_pagamento
      ,wkve.ufficio_pt                   ufficio_pt
      ,wkve.data_reg                     data_reg
      ,wkve.flag_contribuente            flag_contribuente
      ,cont.cod_fiscale                  cod_fiscale_cont
      ,sogg.cognome_nome                 cognome_nome
      ,wkve.rurali
      ,wkve.terreni_erariale
      ,wkve.terreni_comune
      ,wkve.aree_erariale
      ,wkve.aree_comune
      ,wkve.altri_erariale
      ,wkve.altri_comune
      ,wkve.num_fabbricati_ab
      ,wkve.num_fabbricati_rurali
      ,wkve.num_fabbricati_terreni
      ,wkve.num_fabbricati_aree
      ,wkve.num_fabbricati_altri
      ,wkve.rata
      ,wkve.fabbricati_d
      ,wkve.fabbricati_d_erariale
      ,wkve.fabbricati_d_comune
      ,wkve.num_fabbricati_d
      ,wkve.rurali_erariale
      ,wkve.rurali_comune
      ,upper(wkve.identificativo_operazione)    id_operazione
      ,substr(wkve.note,1,1)                    tipo_messaggio
      ,wkve.documento_id
      ,wkve.rateazione
      ,wkve.sanzioni_1
      ,wkve.interessi
      ,wkve.note_versamento
  from wrk_versamenti wkve
      ,contribuenti   cont
      ,soggetti       sogg
 where wkve.tipo_incasso    = 'F24'
   and wkve.tipo_tributo    = w_tipo_tributo
   and wkve.causale         in ('50000','50009', '50200'
--                               ,'50350','50351','50352'
--                               ,'50360','50361','50362'
                               )
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
--                    Nei versamenti "normali" in realtà la pratica non è
--                    gestita, quindi se non esiste nella tabella pratiche_tributo
--                    viene considerata nulla
-- (VD - 04/12/2015): Aggiunta upper in selezione id. operazione
-- (VD - 15/06/2016): Aggiunto test su tipo record G1 - versamento
-- (VD - 16/05/2017): Aggiunto raggruppamento per data versamento
--
CURSOR sel_vers IS
select max(cont.cod_fiscale)                             cod_fiscale
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
      ,max(to_date(substr(wkta.dati, 13, 8),'yyyymmdd')) data_ripartizione
      ,max(to_date(substr(wkta.dati, 23, 8),'yyyymmdd')) data_bonifico
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
                 ,'XXXX',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,'XXXX',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,'XXXX',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,'XXXX',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,'XXXX',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,'XXXX',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,0
                 )
          )                                               terreni_agricoli
      ,sum(decode(substr(wkta.dati,79,4)
                 ,'XXXX',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,'XXXX',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,0
                 )
          )                                               terreni_agricoli_comune
     ,sum(decode(substr(wkta.dati,79,4)
                 ,'XXXX',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,'XXXX',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,0
                 )
          )                                               terreni_agricoli_stato
      ,sum(decode(substr(wkta.dati,79,4)
                 ,'3960',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,'375E',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
  --               ,'375E',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,0
                 )
          )                                               aree_fabbricabili
      ,sum(decode(substr(wkta.dati,79,4)
                 ,'3960',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,'375E',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,0
                 )
          )                                               aree_fabbricabili_comune
      ,sum(decode(substr(wkta.dati,79,4)
                 ,'XXXX',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,'XXXX',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,0
                 )
          )                                               aree_fabbricabili_stato
      ,sum(decode(substr(wkta.dati,79,4)
                 ,'3961',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,'376E',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,0
                 )
          )                                               altri_fabbricati
      ,sum(decode(substr(wkta.dati,79,4)
                 ,'3961',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,'376E',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,0
                 )
          )                                               altri_fabbricati_comune
      ,sum(decode(substr(wkta.dati,79,4)
                 ,'XXXX',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,'XXXX',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,0
                 )
          )                                               altri_fabbricati_stato
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
                 ,'XXXX',to_number(substr(wkta.dati,130,3))
                 ,'XXXX',to_number(substr(wkta.dati,130,3))
                 ,'XXXX',to_number(substr(wkta.dati,130,3))
                 ,'XXXX',to_number(substr(wkta.dati,130,3))
                 ,to_number(null)
                 )
          )                                               num_fabbricati_terreni
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
      ,sum(decode(substr(wkta.dati,79,4)
                 ,'XXXX',0
                 ,'XXXX',0
                 ,'XXXX',0
                 ,'XXXX',0
                 ,'XXXX',0
                 ,'XXXX',0
                 ,to_number(substr(wkta.dati,130,3))
                 )
          )                                               fabbricati
      ,sum(decode(substr(wkta.dati,79,4)
                 ,'XXXX',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,'XXXX',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,0
                 )
          )                                               fabbricati_d
      ,sum(decode(substr(wkta.dati,79,4)
                 ,'XXXX',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,0
                 )
          )                                               fabbricati_d_erariale
      ,sum(decode(substr(wkta.dati,79,4)
                 ,'XXXX',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,0
                 )
          )                                               fabbricati_d_comune
      ,max(decode(substr(wkta.dati,79,4)
                 ,'XXXX',to_number(substr(wkta.dati,130,3))
                 ,'XXXX',to_number(substr(wkta.dati,130,3))
                 ,to_number(null)
                 )
          )                                               num_fabbricati_d
      ,sum(decode(substr(wkta.dati,79,4)
                 ,'XXXX',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,0
                 )
          )                                               rurali_erariale
      ,sum(decode(substr(wkta.dati,79,4)
                 ,'3959',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,'374E',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,0
                 )
          )                                               rurali_comune
      ,to_number(substr(wkta.dati,31,6))                  progr_delega
  from wrk_tras_anci         wkta
      ,contribuenti          cont
      ,soggetti              sogg
 where cont.cod_fiscale     (+) = rtrim(substr(wkta.dati,50,16))
   and sogg.ni              (+) = cont.ni
   and wkta.anno                = 2
   and substr(wkta.dati,79,4)  in ('3958','3959','3960','3961','374E','375E','376E')  -- si escludono i versamenti su violazioni e imposta di scopo
   and to_number(substr(wkta.dati,126,1))  <> 1  -- si escludono i versamenti su ravvedimenti
   and substr(wkta.dati,260,1) in ('I','U')      -- TASI (nei primi file c era I adesso hanno messo U)
   and substr(wkta.dati,1,2)    = 'G1'           -- Si trattano solo i versamenti
 group by rtrim(substr(wkta.dati,50,16))
         ,to_number(substr(wkta.dati,88,4))
         ,decode(substr(wkta.dati,128,2)
                ,'00','U','01','S','10','A','11','U',null
                )
         ,upper(rtrim(substr(wkta.dati,279,18)))
         ,to_date(substr(wkta.dati,67,8),'yyyymmdd')
         ,to_number(substr(wkta.dati,31,6))      -- progr_delega
 order by min(wkta.progressivo)
;
-- se si cambia la select ricordarsi la delete in fondo
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
------------------------------------
-- Funzione F_CHECK_VERSAMENTI
------------------------------------
FUNCTION F_CHECK_VERSAMENTI
( p_cod_fiscale                     varchar2
, p_anno                            number
, p_tipo_tributo                    varchar2
, p_tipo_versamento                 varchar2
, p_descrizione                     varchar2
, p_ufficio_pt                      varchar2
, p_data_pagamento                  date
, p_importo_versato                 number
, p_detrazione                      number
, p_pratica                         number
, p_anno_pratica                    number
, p_rata_pratica                    number
) return number
is
  w_conta                           number;
begin
  if p_rata_pratica = 0 then
     BEGIN
       select count(*)
         into w_conta
         from versamenti vers
        where vers.cod_fiscale            = p_cod_fiscale
          and vers.anno                   = p_anno
          and vers.tipo_tributo           = p_tipo_tributo
          and vers.tipo_versamento        = p_tipo_versamento
          and vers.descrizione            = p_descrizione
          and vers.ufficio_pt             = p_ufficio_pt
          and vers.data_pagamento         = p_data_pagamento
          and vers.importo_versato        = p_importo_versato
        -- modifica: ora la fonte viene richiesta come parametro per i versamenti da cnc
        -- and vers.fonte                  = 9
          and nvl(vers.detrazione,0)      = nvl(p_detrazione,0)
          and nvl(vers.pratica,-1)        = nvl(p_pratica,-1)
       ;
     EXCEPTION
       WHEN others THEN
            w_errore := 'Errore in conteggio versamenti '||
                        ' di '||p_cod_fiscale||'/'||p_tipo_tributo||'/'||
                        p_anno||' ('||sqlerrm||')';
            RAISE errore;
     END;
  else
     begin
       select count(*)
         into w_conta
         from versamenti vers
        where vers.cod_fiscale  = p_cod_fiscale
          and vers.anno         = nvl(p_anno_pratica,p_anno)
          and vers.tipo_tributo = p_tipo_tributo
          and vers.pratica      = p_pratica
          and vers.rata         = p_rata_pratica;
     EXCEPTION
       WHEN others THEN
            w_errore := 'Errore in conteggio'||
                        ' di '||p_cod_fiscale||'/'||p_tipo_tributo||'/'||
                        nvl(p_anno_pratica,p_anno)||' ('||sqlerrm||')';
            RAISE errore;
     END;
  end if;
--
  return w_conta;
--
end;
---------------------------
--  INIZIO ELABORAZIONE  --
---------------------------
BEGIN
-- dbms_output.put_line('Siamo entrati nella Procedure, quindi l''errore e'' qui...'||SQLERRM);
   --
   -- Si trattano i contribuenti precedentemente scartati e successivamente
   -- confermati da operatore
   --
   FOR rec_ins_cont IN sel_ins_cont  -- gestione flag_contribuente
   LOOP
      /*if rec_ins_cont.cod_fiscale_cont is null then
         begin
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
               -- (VD - 25/09/2018): per contribuenti inesistenti non ha senso
               --                    lanciare la function di ricerca pratica
               -- w_pratica := F_F24_PRATICA(rec_ins_cont.cod_fiscale,rec_ins_cont.id_operazione,rec_ins_cont.data_pagamento,w_tipo_tributo);
               --
               -- Se il risultato della function è -1, significa che la pratica non esiste
               -- oppure non è congruente con i dati indicati
               -- Si assume che in assenza di contribuente non esista neanche la pratica
               --
               --if nvl(w_pratica,0) < 0 then
                  w_pratica := to_number(null);
               --end if
            ;*/
     -- (VD - 07/04/2021): modificata gestione inserimento contribuente con
     --                    nuova funzione F_CREA_CONTRIBUENTE
     if rec_ins_cont.cod_fiscale_cont is null then
        w_cod_fiscale := f_crea_contribuente(rec_ins_cont.cod_fiscale,w_errore);
        if w_cod_fiscale is null then
           if w_errore is not null then
              update wrk_versamenti wkve
                 set note = substr(decode(note,'','',note||' - ')||w_errore,1,2000)
               where wkve.progressivo  = rec_ins_cont.progressivo;
           end if;
        else
           -- (VD - 07/04/2021): Ripristinato controllo su pratica per
           --                    versamenti effettuati con codice fiscale
           --                    diverso da quello presente in TR4
           -- (VD - 24/06/2021): In realta' il controllo non serve, in quanto
           --                    non utilizziamo mai un codice fiscale diverso
           --                    da quello presente sul versamento. Quindi, se
           --                    il contribuente non esiste, non possono
           --                    esistere pratiche.
           --                    Lo lascio comunque attivo per comodita'.
           w_pratica := F_F24_PRATICA(w_cod_fiscale,rec_ins_cont.id_operazione
                                     ,rec_ins_cont.data_pagamento,w_tipo_tributo);
           if nvl(w_pratica,0) < 0 then
              begin
                update wrk_versamenti wkve
                   set wkve.causale      = f_f24_causale_errore(nvl(w_pratica,-1),'C')
                      ,wkve.note         = decode(rec_ins_cont.tipo_messaggio
                                                 ,'I','Imposta - '
                                                 ,'S','Sanzioni e Interessi - '
                                                 ,'')||
                                           f_f24_causale_errore(nvl(w_pratica,-1),'D')
                      ,wkve.flag_contribuente = NULL
                 where wkve.progressivo  = rec_ins_cont.progressivo
                ;
              EXCEPTION
                WHEN others THEN
                     w_errore := 'Errore in update wrk_versamenti'||
                                 ' di '||rec_ins_cont.cod_fiscale||' progressivo '||
                                 to_char(rec_ins_cont.progressivo)||' ('||sqlerrm||')';
                     RAISE errore;
              end;
           else
              -- (VD - 29/10/2018): arrivati a questo punto, se la pratica esiste
              --                    e' corretta
              if nvl(w_pratica,0) > 0 then
                 w_anno_pratica := to_number(substr(rec_ins_cont.id_operazione,5,4));
                 w_rata_pratica := to_number(substr(rec_ins_cont.id_operazione,9,2));
              else
                 w_anno_pratica := to_number(null);
                 w_rata_pratica := 0;
              end if;
              -- (VD - 07/04/2021): nuova funzione di controllo versamento gia'
              --                    presente
              w_conta := F_CHECK_VERSAMENTI ( w_cod_fiscale
                                            , rec_ins_cont.anno
                                            , w_tipo_tributo
                                            , rec_ins_cont.tipo_versamento
                                            , 'VERSAMENTO IMPORTATO DA MODELLO F24'
                                            , rec_ins_cont.ufficio_pt
                                            , rec_ins_cont.data_pagamento
                                            , rec_ins_cont.importo_versato
                                            , rec_ins_cont.detrazione
                                            , w_pratica
                                            , w_anno_pratica
                                            , w_rata_pratica
                                            );
              --
              -- Se w_conta è > 0, significa che esiste già un versamento uguale
              -- a quello che si vuole caricare.
              -- Si aggiornano il codice (50000) e il messaggio di errore
              --
              if w_conta > 0 then
                 begin
                     update wrk_versamenti wkve
                        set wkve.causale      = decode(w_rata_pratica,0,'50000','50362')
                           ,wkve.note         = decode(rec_ins_cont.tipo_messaggio
                                                      ,'I','Imposta - '
                                                      ,'S','Sanzioni e Interessi - '
                                                      ,'')||
                                                decode(w_rata_pratica
                                                      ,0,'Versamento gia` Presente in data '||
                                                          to_char(rec_ins_cont.data_pagamento,'dd/mm/yyyy')
                                                      ,'Pratica rateizzata: Rata gia'' versata')
                           ,wkve.flag_contribuente = NULL
                      where wkve.progressivo  = rec_ins_cont.progressivo
                     ;
                 EXCEPTION
                    WHEN others THEN
                       w_errore := 'Errore in update wrk_versamenti'||
                                   ' di '||rec_ins_cont.cod_fiscale||' progressivo '||
                                   to_char(rec_ins_cont.progressivo)||' ('||sqlerrm||')';
                       RAISE errore;
                 end;
              else
                 /*BEGIN -- Assegnazione Numero Progressivo
                    select nvl(max(vers.sequenza),0)+1
                      into w_sequenza
                      from versamenti vers
                     where vers.cod_fiscale     = rec_ins_cont.cod_fiscale
                       and vers.anno            = rec_ins_cont.anno
                       and vers.tipo_tributo    = w_tipo_tributo
                            ;
                 END;*/
                 -- dbms_output.put_line('Ins versamenti: cf '||rec_ins_cont.cod_fiscale||' '||SQLERRM);
                 w_sequenza := to_number(null);
                 VERSAMENTI_NR ( w_cod_fiscale, nvl(w_anno_pratica, rec_ins_cont.anno)
                               , w_tipo_tributo, w_sequenza );
                 BEGIN
                    insert into versamenti
                         (cod_fiscale
                         ,anno
                         ,pratica
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
                         ,terreni_agricoli
                         ,aree_fabbricabili
                         ,altri_fabbricati
                         ,rurali
                         ,num_fabbricati_ab
                         ,num_fabbricati_rurali
                         ,num_fabbricati_terreni
                         ,num_fabbricati_aree
                         ,num_fabbricati_altri
                         ,rata
                         ,fabbricati_d
                         ,num_fabbricati_d
                         ,note
                         ,documento_id
                         ,sanzioni_1
                         ,interessi
                         )
                   select w_cod_fiscale
                         ,rec_ins_cont.anno
                         ,w_pratica
                         ,w_tipo_tributo
                         ,w_sequenza
                         ,rec_ins_cont.tipo_versamento
                         ,'VERSAMENTO IMPORTATO DA MODELLO F24'
                         ,rec_ins_cont.ufficio_pt
                         ,rec_ins_cont.data_pagamento
                         ,rec_ins_cont.importo_versato
                         ,9
                         ,rec_ins_cont.detrazione
                         ,'F24'
                         ,trunc(sysdate)
                         ,rec_ins_cont.data_reg
                         ,rec_ins_cont.fabbricati
                         ,rec_ins_cont.ab_principale
                         ,rec_ins_cont.terreni_agricoli
                         ,rec_ins_cont.aree_fabbricabili
                         ,rec_ins_cont.altri_fabbricati
                         ,rec_ins_cont.rurali
                         ,rec_ins_cont.num_fabbricati_ab
                         ,rec_ins_cont.num_fabbricati_rurali
                         ,rec_ins_cont.num_fabbricati_terreni
                         ,rec_ins_cont.num_fabbricati_aree
                         ,rec_ins_cont.num_fabbricati_altri
                         -- (VD - 25/09/2018): per contribuenti inesistenti si
                         -- assume la rata presente sul versamento come valida
                         --,rec_ins_cont.rata
                         ,decode(rec_ins_cont.rateazione
                                ,null,rec_ins_cont.rata
                                ,'0101',11
                                ,'0102',12
                                ,'0202',22
                                ,to_number(null)
                                )
                         ,rec_ins_cont.fabbricati_d
                         ,rec_ins_cont.num_fabbricati_d
                         ,f_f24_note_versamento(rec_ins_cont.id_operazione
                                               ,w_pratica
                                               ,rec_ins_cont.tipo_messaggio
                                               ,rec_ins_cont.documento_id
                                               ,w_tipo_tributo
                                               ,null
                                               ,rec_ins_cont.rateazione
                                               ,rec_ins_cont.note_versamento
                                               )
                         ,rec_ins_cont.documento_id
                         ,rec_ins_cont.sanzioni_1
                         ,rec_ins_cont.interessi
                     from dual
                        ;
                 EXCEPTION
                     WHEN others THEN
                         --CONTRIBUENTI_CHK_DEL(rec_ins_cont.cod_fiscale,null);
                         CONTRIBUENTI_CHK_DEL(w_cod_fiscale,null);
                         w_errore := 'Errore in inserimento versamento bonificato'||
                                     ' di '||w_cod_fiscale||' progressivo '||
                                     to_char(rec_ins_cont.progressivo)||' ('||sqlerrm||')';
                        RAISE errore;
                 END;
                 -- dbms_output.put_line('del wrk '||rec_ins_cont.progressivo||' '||SQLERRM);
                 BEGIN
                    delete wrk_versamenti wkve
                     where wkve.progressivo  = rec_ins_cont.progressivo
                      ;
                 EXCEPTION
                     WHEN others THEN
                        w_errore := 'Errore in cancellazione wrk_versamenti '||
                                   to_char(rec_ins_cont.progressivo)||' ('||sqlerrm||')';
                        RAISE errore;
                 END;
              end if;
           end if;
        end if;
     end if;
   END LOOP;    -- gestione flag_contribuente
---------------------------------------------------------------
-- Trattamento versamenti con errore da tabella WRK_VERSAMENTI
---------------------------------------------------------------
   FOR rec_errati IN sel_errati
   LOOP
      if rec_errati.cod_fiscale_cont is null then
         -- dbms_output.put_line('upd wrk 50009 '||rec_errati.progressivo||' '||SQLERRM);
         update wrk_versamenti wkve
            set wkve.cognome_nome = rec_errati.cognome_nome
               ,wkve.causale      = '50009'
               ,wkve.note         = 'Contribuente ('||rec_errati.cod_fiscale||') sconosciuto'
          where wkve.progressivo  = rec_errati.progressivo
         ;
      else
         w_pratica := F_F24_PRATICA(rec_errati.cod_fiscale,rec_errati.id_operazione,rec_errati.data_pagamento,w_tipo_tributo);
         --
         -- Se il risultato della function è negativo, significa che la pratica
         -- non esiste oppure non è congruente con i dati indicati
         if nvl(w_pratica,0) < 0 then
            begin
              update wrk_versamenti wkve
                 set wkve.cognome_nome = rec_errati.cognome_nome
                    -- (VD - 25/09/2018): nuova funzione di decodifica errore
                    --,wkve.causale      = decode(w_pratica,-1,'50350'
                    --                                     ,-2,'50351'
                    --                                        ,'50352')
                    --,wkve.note         = decode(rec_errati.tipo_messaggio,'I','Imposta - '
                    --                                                     ,'S','Sanzioni e Interessi - '
                    --                                                     ,'')||
                    --                     decode(w_pratica,-1,'Versamento con codici violazione Pratica non presente o incongruente'
                    --                                     ,-2,'Versamento con codici violazione Data Pagamento precedente a Data Notifica Pratica'
                    --                                        ,'Versamento con codici violazione Pratica non Notificata')
                    ,wkve.causale      = f_f24_causale_errore(nvl(w_pratica,-1),'C')
                    ,wkve.note         = decode(rec_errati.tipo_messaggio,'I','Imposta - '
                                                                         ,'S','Sanzioni e Interessi - '
                                                                         ,'')||
                                         f_f24_causale_errore(nvl(w_pratica,-1),'D')
                    ,wkve.flag_contribuente = NULL
               where wkve.progressivo  = rec_errati.progressivo
              ;
            EXCEPTION
               WHEN others THEN
                  w_errore := 'Errore in update wrk_versamenti'||
                              ' di '||rec_errati.cod_fiscale||' progressivo '||
                              to_char(rec_errati.progressivo)||' ('||sqlerrm||')';
                  RAISE errore;
            end;
         else
            if nvl(w_pratica,0) > 0 then
               w_anno_pratica := to_number(substr(rec_errati.id_operazione,5,4));
               w_rata_pratica := to_number(substr(rec_errati.id_operazione,9,2));
            else
               w_anno_pratica := to_number(null);
               w_rata_pratica := 0;
            end if;
            /*if w_rata_pratica = 0 then
               BEGIN
                  select count(*)
                    into w_conta
                    from versamenti vers
                   where vers.cod_fiscale            = rec_errati.cod_fiscale
                     and vers.anno                   = rec_errati.anno
                     and vers.tipo_tributo           = w_tipo_tributo
                     and vers.tipo_versamento        = rec_errati.tipo_versamento
                     and vers.descrizione            = 'VERSAMENTO IMPORTATO DA MODELLO F24'
                     and vers.ufficio_pt             = rec_errati.ufficio_pt
                     and vers.data_pagamento         = rec_errati.data_pagamento
                     and vers.importo_versato        = rec_errati.importo_versato
                   -- modifica: ora la fonte viene richiesta come parametro per i versamenti da cnc
                   --  and vers.fonte                  = 9
                     and nvl(vers.detrazione,0)      = nvl(rec_errati.detrazione,0)
                     and nvl(vers.pratica,-1)        = nvl(w_pratica,-1)
                  ;
               EXCEPTION
                  WHEN others THEN
                       w_errore := 'Errore in conteggio'||
                                   ' di '||rec_errati.cod_fiscale||' progressivo '||
                                   to_char(rec_errati.progressivo)||' ('||sqlerrm||')';
                       RAISE errore;
               END;
            else
               begin
                  select count(*)
                    into w_conta
                    from versamenti vers
                   where vers.cod_fiscale  = rec_errati.cod_fiscale
                     and vers.anno         = nvl(w_anno_pratica,rec_errati.anno)
                     and vers.tipo_tributo = w_tipo_tributo
                     and vers.pratica      = w_pratica
                     and vers.rata         = w_rata_pratica;
               EXCEPTION
                  WHEN others THEN
                       w_errore := 'Errore in conteggio'||
                                   ' di '||rec_errati.cod_fiscale||' progressivo '||
                                   to_char(rec_errati.progressivo)||' ('||sqlerrm||')';
                       RAISE errore;
               END;
            end if; */
            -- (VD - 07/04/2021): nuova funzione di controllo versamento gia'
            --                    presente
            w_conta := F_CHECK_VERSAMENTI ( rec_errati.cod_fiscale
                                          , rec_errati.anno
                                          , w_tipo_tributo
                                          , rec_errati.tipo_versamento
                                          , 'VERSAMENTO IMPORTATO DA MODELLO F24'
                                          , rec_errati.ufficio_pt
                                          , rec_errati.data_pagamento
                                          , rec_errati.importo_versato
                                          , rec_errati.detrazione
                                          , w_pratica
                                          , w_anno_pratica
                                          , w_rata_pratica
                                          );
            -- Se w_conta è > 0, significa che esiste già un versamento uguale
            -- a quello che si vuole caricare.
            -- Si aggiornano il codice (50000) e il messaggio di errore
            if w_conta > 0 then
               begin
                   update wrk_versamenti wkve
                      set wkve.cognome_nome = rec_errati.cognome_nome
                         ,wkve.causale      = decode(w_rata_pratica,0,'50000','50362')
                         ,wkve.note         = decode(rec_errati.tipo_messaggio,'I','Imposta - '
                                                                              ,'S','Sanzioni e Interessi - '
                                                                              ,'')||
                                              decode(w_rata_pratica,0,'Versamento gia` Presente in data '||
                                                                      to_char(rec_errati.data_pagamento,'dd/mm/yyyy')
                                                                     ,'Pratica rateizzata: Rata gia'' versata')
                         ,wkve.flag_contribuente = NULL
                    where wkve.progressivo  = rec_errati.progressivo
                   ;
               EXCEPTION
                  WHEN others THEN
                     w_errore := 'Errore in update wrk_versamenti'||
                                 ' di '||rec_errati.cod_fiscale||' progressivo '||
                                 to_char(rec_errati.progressivo)||' ('||sqlerrm||')';
                     RAISE errore;
               end;
            else
               /*BEGIN -- Assegnazione Numero Progressivo
                  select nvl(max(vers.sequenza),0)+1
                    into w_sequenza
                    from versamenti vers
                   where vers.cod_fiscale     = rec_errati.cod_fiscale
                     and vers.anno            = nvl(w_anno_pratica,rec_errati.anno)
                     and vers.tipo_tributo    = w_tipo_tributo
                  ;
               END;*/
               --
               -- Se tutti i controlli vengono superati, si inserisce la riga
               -- nella tabella VERSAMENTI e si elimina la riga da WRK_VERSAMENTI
               --
               w_sequenza := to_number(null);
               VERSAMENTI_NR ( rec_errati.cod_fiscale, nvl(w_anno_pratica,rec_errati.anno)
                             , w_tipo_tributo, w_sequenza );
               BEGIN
                  insert into versamenti
                        (cod_fiscale
                        ,anno
                        ,pratica
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
                        ,terreni_agricoli
                        ,aree_fabbricabili
                        ,altri_fabbricati
                        ,rurali
                        ,num_fabbricati_ab
                        ,num_fabbricati_rurali
                        ,num_fabbricati_terreni
                        ,num_fabbricati_aree
                        ,num_fabbricati_altri
                        ,rata
                        ,fabbricati_d
                        ,num_fabbricati_d
                        ,note
                        ,documento_id
                        ,sanzioni_1
                        ,interessi)
                  select rec_errati.cod_fiscale
                        ,nvl(w_anno_pratica,rec_errati.anno)
                        ,w_pratica
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
                        ,rec_errati.terreni_agricoli
                        ,rec_errati.aree_fabbricabili
                        ,rec_errati.altri_fabbricati
                        ,rec_errati.rurali
                        ,rec_errati.num_fabbricati_ab
                        ,rec_errati.num_fabbricati_rurali
                        ,rec_errati.num_fabbricati_terreni
                        ,rec_errati.num_fabbricati_aree
                        ,rec_errati.num_fabbricati_altri
                        -- (VD - 25/09/2018): modifica per gestione pratiche
                        --                    rateizzate
                        --,rec_errati.rata
                        ,decode(w_rata_pratica
                               ,0,decode(rec_errati.rateazione
                                        ,null,rec_errati.rata
                                        ,'0101',11
                                        ,'0102',12
                                        ,'0202',22
                                        ,to_number(null)
                                        )
                                 ,w_rata_pratica
                               )
                        ,rec_errati.fabbricati_d
                        ,rec_errati.num_fabbricati_d
                        ,f_f24_note_versamento(rec_errati.id_operazione
                                              ,w_pratica
                                              ,rec_errati.tipo_messaggio
                                              ,rec_errati.documento_id
                                              ,w_tipo_tributo
                                              ,null
                                              ,rec_errati.rateazione
                                              ,rec_errati.note_versamento
                                              )
                        ,rec_errati.documento_id
                        ,rec_errati.sanzioni_1
                        ,rec_errati.interessi
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
      end if;
   END LOOP;
------------------------------------------------------------
-- Trattamento versamenti caricati in tabella WRK_TRAS_ANCI
------------------------------------------------------------
   FOR rec_vers IN sel_vers
   LOOP
      if rec_vers.cod_fiscale is null then
      -- (VD - 24/06/2021): se il contribuente non esiste ma esiste un
      --                    soggetto con lo stesso codice fiscale, si crea
      --                    un nuovo contribuente
      --
         w_cod_fiscale := f_crea_contribuente(rec_vers.cod_fiscale_vers,w_errore);
         if w_cod_fiscale is null then
            w_progressivo := F_SELEZIONA_PROGRESSIVO;
            -- dbms_output.put_line('ins wrk  '||w_progressivo||' '||SQLERRM);
            insert into wrk_versamenti
                  (progressivo,tipo_tributo,tipo_incasso,anno,ruolo,cod_fiscale,
                   cognome_nome,causale,disposizione,data_variazione,note,
                   tipo_versamento,ufficio_pt,data_pagamento,ab_principale,
                   terreni_agricoli,aree_fabbricabili,altri_fabbricati,
                   data_reg,detrazione,fabbricati
                  ,importo_versato
                  ,rurali
                  ,num_fabbricati_ab
                  ,num_fabbricati_rurali
                  ,num_fabbricati_terreni
                  ,num_fabbricati_aree
                  ,num_fabbricati_altri
                  ,rata
                  ,fabbricati_d
                  ,num_fabbricati_d
                  ,identificativo_operazione
                  ,documento_id
                  ,rateazione)
            values(w_progressivo,w_tipo_tributo,'F24',rec_vers.anno,null,rec_vers.cod_fiscale_vers,
                   rec_vers.cognome_nome,'50009',w_progressivo,sysdate,
                   'Imposta - Contribuente ('||rec_vers.cod_fiscale_vers||') sconosciuto',
                   rec_vers.tipo_versamento,rec_vers.ufficio_pt,rec_vers.data_pagamento,
                   rec_vers.ab_principale,rec_vers.terreni_agricoli,
                   rec_vers.aree_fabbricabili,rec_vers.altri_fabbricati,
                   rec_vers.data_reg,rec_vers.detrazione,rec_vers.fabbricati
                  ,rec_vers.importo_versato
                  ,rec_vers.rurali
                  ,rec_vers.num_fabbricati_ab
                  ,rec_vers.num_fabbricati_rurali
                  ,rec_vers.num_fabbricati_terreni
                  ,rec_vers.num_fabbricati_aree
                  ,rec_vers.num_fabbricati_altri
                  -- (VD - 25/09/2018): sui versamenti da bonificare si memorizza
                  --                    la rateazione originale
                  --,decode(rec_vers.rateazione
                  --       ,'0101',11
                  --       ,'0102',12
                  --       ,'0202',22
                  --       ,to_number(null)
                  --       )
                  ,to_number(null)
                  ,rec_vers.fabbricati_d
                  ,rec_vers.num_fabbricati_d
                  ,rec_vers.id_operazione
                  ,a_documento_id
                  ,rec_vers.rateazione);
         end if;
      else
         w_cod_fiscale := rec_vers.cod_fiscale;
      end if;
      -- (VD - 24/06/2021): se il contribuente esisteva gia' oppure e' appena
      --                    stato inserito, si prosegue il trattamento
      if w_cod_fiscale is not null then
         w_pratica := F_F24_PRATICA(w_cod_fiscale,rec_vers.id_operazione,rec_vers.data_pagamento,w_tipo_tributo);
         --
         -- Se il risultato della function è negativo, significa che la pratica
         -- non esiste oppure non è congruente con i dati indicati.
         --
         if nvl(w_pratica,0) < 0 then
            w_progressivo := F_SELEZIONA_PROGRESSIVO;
            insert into wrk_versamenti
                  (progressivo,tipo_tributo,tipo_incasso,anno,ruolo,
                   cod_fiscale,cognome_nome,
                   causale,
                   disposizione,data_variazione,
                   note,
                   tipo_versamento,ufficio_pt,data_pagamento,ab_principale,
                   terreni_agricoli,aree_fabbricabili,altri_fabbricati,
                   data_reg,detrazione,fabbricati,importo_versato
                  ,rurali
                  ,num_fabbricati_ab
                  ,num_fabbricati_rurali
                  ,num_fabbricati_terreni
                  ,num_fabbricati_aree
                  ,num_fabbricati_altri
                  ,rata
                  ,fabbricati_d
                  ,num_fabbricati_d
                  ,identificativo_operazione
                  ,documento_id
                  ,rateazione
                  )
            values(w_progressivo,w_tipo_tributo,'F24',rec_vers.anno,null,
                   rec_vers.cod_fiscale_vers,rec_vers.cognome_nome,
                   -- (VD - 25/09/2018): nuova funzione di decodifica errore
                   --decode(w_pratica,-1,'50350'
                   --                ,-2,'50351'
                   --                   ,'50352'),
                   f_f24_causale_errore(w_pratica,'C'),    -- causale
                   w_progressivo,sysdate,
                   -- (VD - 25/09/2018): nuova funzione di decodifica errore
                   --decode(w_pratica,null,'','Imposta - ')||
                   --       decode(w_pratica,-1,'Versamento con codici violazione Pratica non presente o incongruente'
                   --                       ,-2,'Versamento con codici violazione Data Pagamento precedente a Data Notifica Pratica'
                   --                          ,'Versamento con codici violazione Pratica non Notificata'),
                   'Imposta - '||f_f24_causale_errore(w_pratica,'D'),  -- note
                   rec_vers.tipo_versamento,rec_vers.ufficio_pt,rec_vers.data_pagamento,
                   rec_vers.ab_principale,rec_vers.terreni_agricoli,rec_vers.aree_fabbricabili,
                   rec_vers.altri_fabbricati,rec_vers.data_reg,rec_vers.detrazione,rec_vers.fabbricati
                  ,rec_vers.importo_versato
                  ,rec_vers.rurali
                  ,rec_vers.num_fabbricati_ab
                  ,rec_vers.num_fabbricati_rurali
                  ,rec_vers.num_fabbricati_terreni
                  ,rec_vers.num_fabbricati_aree
                  ,rec_vers.num_fabbricati_altri
                  -- (VD - 25/09/2018): sui versamenti da bonificare si memorizza
                  --                    la rateazione originale
                  --,decode(rec_vers.rateazione
                  --       ,'0101',11
                  --       ,'0102',12
                  --       ,'0202',22
                  --       ,to_number(null)
                  --       )
                  ,to_number(null)
                  ,rec_vers.fabbricati_d
                  ,rec_vers.num_fabbricati_d
                  ,rec_vers.id_operazione
                  ,a_documento_id
                  ,rec_vers.rateazione
                  );
         else
            /*BEGIN
               select count(*)
                 into w_conta
                 from versamenti vers
                where vers.cod_fiscale            = rec_vers.cod_fiscale
                  and vers.anno                   = rec_vers.anno
                  and vers.tipo_tributo           = rec_vers.tipo_tributo
                  and vers.tipo_versamento        = rec_vers.tipo_versamento
                  and vers.descrizione            = rec_vers.descrizione
                  and vers.ufficio_pt             = rec_vers.ufficio_pt
                  and vers.data_pagamento         = rec_vers.data_pagamento
                  and vers.importo_versato        = rec_vers.importo_versato
               -- modifica: ora la fonte viene richiesta come parametro per i versamenti da cnc
               --   and vers.fonte                  = rec_vers.fonte
                  and nvl(vers.detrazione,0)      = nvl(rec_vers.detrazione,0)
                  and nvl(vers.pratica,-1)        = nvl(w_pratica,-1)
               ;
            END; */
            --(VD - 25/09/2018): si estrae la rata dall'identificativo
            -- operazione. Se è zero, si considererà la rateazione
            -- presente sul versamento
            --
            if nvl(w_pratica,0) > 0 then
               w_anno_pratica := to_number(substr(rec_vers.id_operazione,5,4));
               w_rata_pratica := to_number(substr(rec_vers.id_operazione,9,2));
            else
               w_anno_pratica := to_number(null);
               w_rata_pratica := 0;
            end if;
            w_conta := F_CHECK_VERSAMENTI ( w_cod_fiscale --rec_vers.cod_fiscale
                                          , rec_vers.anno
                                          , w_tipo_tributo
                                          , rec_vers.tipo_versamento
                                          , rec_vers.descrizione
                                          , rec_vers.ufficio_pt
                                          , rec_vers.data_pagamento
                                          , rec_vers.importo_versato
                                          , rec_vers.detrazione
                                          , w_pratica
                                          , w_anno_pratica
                                          , w_rata_pratica
                                          );
            if w_conta > 0 then
               w_progressivo := F_SELEZIONA_PROGRESSIVO;
               -- dbms_output.put_line('ins wrk2  '||w_progressivo||' '||SQLERRM);
               insert into wrk_versamenti
                     (progressivo,tipo_tributo,tipo_incasso,anno,ruolo,cod_fiscale,
                      cognome_nome,causale,disposizione,data_variazione,note,
                      tipo_versamento,ufficio_pt,data_pagamento,ab_principale,
                      terreni_agricoli,aree_fabbricabili,altri_fabbricati,
                      data_reg,detrazione,fabbricati
                     ,importo_versato
                     ,rurali
                     ,num_fabbricati_ab
                     ,num_fabbricati_rurali
                     ,num_fabbricati_terreni
                     ,num_fabbricati_aree
                     ,num_fabbricati_altri
                     ,rata
                     ,fabbricati_d
                     ,num_fabbricati_d
                     ,identificativo_operazione
                     ,documento_id
                     ,rateazione
                     )
               values(w_progressivo,w_tipo_tributo,'F24',rec_vers.anno,null,rec_vers.cod_fiscale_vers,
                      rec_vers.cognome_nome,'50000',w_progressivo,sysdate,
                      decode(w_pratica,null,'','Imposta - ')||
                      decode(w_rata_pratica,0,'Versamento gia` Presente in data '||to_char(rec_vers.data_pagamento,'dd/mm/yyyy'),
                             'Pratica rateizzata: Rata gia'' versata'),
                      rec_vers.tipo_versamento,rec_vers.ufficio_pt,rec_vers.data_pagamento,
                      rec_vers.ab_principale,rec_vers.terreni_agricoli,rec_vers.aree_fabbricabili,
                      rec_vers.altri_fabbricati,rec_vers.data_reg,rec_vers.detrazione,rec_vers.fabbricati
                     ,rec_vers.importo_versato
                     ,rec_vers.rurali
                     ,rec_vers.num_fabbricati_ab
                     ,rec_vers.num_fabbricati_rurali
                     ,rec_vers.num_fabbricati_terreni
                     ,rec_vers.num_fabbricati_aree
                     ,rec_vers.num_fabbricati_altri
                     -- (VD - 25/09/2018): sui versamenti da bonificare si memorizza
                     --                    la rateazione originale
                     --,decode(rec_vers.rateazione
                     --       ,'0101',11
                     --       ,'0102',12
                     --       ,'0202',22
                     --       ,to_number(null)
                     --       )
                     ,to_number(null)
                     ,rec_vers.fabbricati_d
                     ,rec_vers.num_fabbricati_d
                     ,rec_vers.id_operazione
                     ,a_documento_id
                     ,rec_vers.rateazione
                     );
            else
               --
               -- (22/06/2023 - VM - #61996)
               -- Se sono presenti versamenti su violazioni su stesso progressivo delega
               -- si inserisce il versamento in WRK_VERSAMENTI con il codice (50200)
               -- e il messaggio di errore
               select count(*)
               into w_count_viol_delega
               from wrk_tras_anci wkta
               where
                    substr(wkta.dati,79,4) in ('3962','3963','357E','358E')                        -- versamenti su violazioni
                    and to_number(substr(wkta.dati,126,1))  <> 1                                   -- si escludono i versamenti su ravvedimenti
                    and substr(wkta.dati,260,1) in ('I','U')                                       -- TASI (nei primi file c era I adesso hanno messo U)                                            -- ICI/IMU
                    and substr(wkta.dati,1,2)   = 'G1'                                             -- Si trattano solo i versamenti
                    and to_number(substr(wkta.dati,31,6)) = rec_vers.progr_delega                  -- progressivo delega
                    and to_date(decode(substr(wkta.dati, 13, 8),'99999999','99991231',
                                       substr(wkta.dati, 13, 8)),'yyyymmdd') = rec_vers.data_ripartizione  -- data ripartizione
                    and to_date(decode(substr(wkta.dati, 23, 8),'99999999','99991231',
                                       substr(wkta.dati, 23, 8)),'yyyymmdd') = rec_vers.data_bonifico      -- data bonifico
               ;
               
               if w_count_viol_delega > 0 then
                  w_progressivo := F_SELEZIONA_PROGRESSIVO;
                  insert into wrk_versamenti
                    (progressivo,
                     tipo_tributo,
                     tipo_incasso,
                     anno,
                     ruolo,
                     cod_fiscale,
                     cognome_nome,
                     causale,
                     disposizione,
                     data_variazione,
                     note,
                     tipo_versamento,
                     ufficio_pt,
                     data_pagamento,
                     ab_principale,
                     terreni_agricoli,
                     aree_fabbricabili,
                     altri_fabbricati,
                     data_reg,
                     detrazione,
                     fabbricati,
                     importo_versato,
                     rurali,
                     num_fabbricati_ab,
                     num_fabbricati_rurali,
                     num_fabbricati_terreni,
                     num_fabbricati_aree,
                     num_fabbricati_altri,
                     rata,
                     fabbricati_d,
                     num_fabbricati_d,
                     identificativo_operazione,
                     documento_id,
                     rateazione)
                  values
                    (w_progressivo,
                     w_tipo_tributo,
                     'F24',
                     rec_vers.anno,
                     null,
                     rec_vers.cod_fiscale_vers,
                     rec_vers.cognome_nome,
                     '50200', -- causale
                     w_progressivo,
                     sysdate,
                     'Imposta - ' || f_get_descr_errore('50200', 'D'), -- note
                     rec_vers.tipo_versamento,
                     rec_vers.ufficio_pt,
                     rec_vers.data_pagamento,
                     rec_vers.ab_principale,
                     rec_vers.terreni_agricoli,
                     rec_vers.aree_fabbricabili,
                     rec_vers.altri_fabbricati,
                     rec_vers.data_reg,
                     rec_vers.detrazione,
                     rec_vers.fabbricati,
                     rec_vers.importo_versato,
                     rec_vers.rurali,
                     rec_vers.num_fabbricati_ab,
                     rec_vers.num_fabbricati_rurali,
                     rec_vers.num_fabbricati_terreni,
                     rec_vers.num_fabbricati_aree,
                     rec_vers.num_fabbricati_altri,
                     to_number(null),
                     rec_vers.fabbricati_d,
                     rec_vers.num_fabbricati_d,
                     rec_vers.id_operazione,
                     a_documento_id,
                     rec_vers.rateazione);
               else
                 /*BEGIN -- Assegnazione Numero Progressivo
                    select nvl(max(vers.sequenza),0)+1
                      into w_sequenza
                      from versamenti vers
                     where vers.cod_fiscale     = rec_vers.cod_fiscale
                       and vers.anno            = nvl(w_anno_pratica,rec_vers.anno)
                       and vers.tipo_tributo    = rec_vers.tipo_tributo
                    ;
                 END;*/
                 w_sequenza := to_number(null);
                 --VERSAMENTI_NR ( rec_vers.cod_fiscale, nvl(w_anno_pratica,rec_vers.anno)
                 VERSAMENTI_NR ( w_cod_fiscale, nvl(w_anno_pratica,rec_vers.anno)
                               , rec_vers.tipo_tributo, w_sequenza );
                 BEGIN
                    -- dbms_output.put_line('ins vers2 '||rec_vers.cod_fiscale||' '||SQLERRM);
                    insert into versamenti
                          (cod_fiscale
                          ,anno
                          ,pratica
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
                          ,terreni_agricoli
                          ,aree_fabbricabili
                          ,altri_fabbricati
                          ,rurali
                          ,num_fabbricati_ab
                          ,num_fabbricati_rurali
                          ,num_fabbricati_terreni
                          ,num_fabbricati_aree
                          ,num_fabbricati_altri
                          ,rata
                          ,fabbricati_d
                          ,num_fabbricati_d
                          ,note
                          ,documento_id)
                    select w_cod_fiscale --rec_vers.cod_fiscale
                          ,nvl(w_anno_pratica,rec_vers.anno)
                          ,w_pratica
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
                          ,rec_vers.terreni_agricoli
                          ,rec_vers.aree_fabbricabili
                          ,rec_vers.altri_fabbricati
                          ,rec_vers.rurali
                          ,rec_vers.num_fabbricati_ab
                          ,rec_vers.num_fabbricati_rurali
                          ,rec_vers.num_fabbricati_terreni
                          ,rec_vers.num_fabbricati_aree
                          ,rec_vers.num_fabbricati_altri
                          -- (VD - 25/09/2018): modifica per gestione pratiche
                          --                    rateizzate
                          --,decode(rec_vers.rateazione
                          --       ,'0101',11
                          --       ,'0102',12
                          --       ,'0202',22
                          --       ,to_number(null)
                          --       )
                          ,decode(w_rata_pratica
                                 ,0,decode(rec_vers.rateazione
                                          ,'0101',11
                                          ,'0102',12
                                          ,'0202',22
                                          ,to_number(null)
                                          )
                                      ,w_rata_pratica
                                 )
                          ,rec_vers.fabbricati_d
                          ,rec_vers.num_fabbricati_d
                          ,f_f24_note_versamento(rec_vers.id_operazione
                                                ,w_pratica
                                                ,'I'
                                                ,a_documento_id
                                                ,w_tipo_tributo
                                                ,null
                                                ,rec_vers.rateazione
                                                )
                          ,a_documento_id
                      from dual
                    ;
                 EXCEPTION
                    WHEN others THEN
                       w_errore := 'Errore in inserimento versamento'||
                                   ' di '||rec_vers.cod_fiscale||' progressivo '||
                                   to_char(rec_vers.progressivo)||' ('||sqlerrm||')';
                       RAISE errore;
                 END;
               end if;
            end if;
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
            and substr(wkta.dati,79,4)  in ('3958','3959','3960','3961','374E','375E','376E')  -- si escludono i versamneti su violazioni  e imposta di scopo
            and to_number(substr(wkta.dati,126,1))  <> 1  -- si escludono i versamenti su ravvedimenti
            and substr(wkta.dati,260,1) in ('I','U')      -- TASI (nei primi file c era I adesso hanno messo U)
            and substr(wkta.dati,1,2)    = 'G1'           -- Si trattano solo i versamenti
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
----------------------------------------------------
-- Trattamento dei versamenti su ravvedimento
----------------------------------------------------
CARICA_VERS_RAVV_TASI_F24(a_documento_id, a_cod_fiscale);
----------------------------------------------------
-- Trattamento dei versamenti su violzioni
----------------------------------------------------
CARICA_VERS_VIOL_TASI_F24(a_documento_id, a_cod_fiscale, a_log_documento);
--------------------------------------------------------
-- (VD - 05/07/2016) Trattamento di revoche e ripristini
--------------------------------------------------------
CARICA_ANNULLAMENTI_F24 (a_documento_id,w_tipo_tributo, a_cod_fiscale);
EXCEPTION
   WHEN errore THEN
      RAISE_APPLICATION_ERROR(-20999,w_errore);
END;
/* End Procedure: CARICA_VERSAMENTI_TASI_F24 */
/
