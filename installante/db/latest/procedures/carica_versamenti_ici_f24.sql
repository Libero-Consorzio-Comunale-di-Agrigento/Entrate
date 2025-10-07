--liquibase formatted sql 
--changeset abrandolini:20250326_152423_carica_versamenti_ici_f24 stripComments:false runOnChange:true 
 
CREATE OR REPLACE procedure         CARICA_VERSAMENTI_ICI_F24
/*************************************************************************
 Versione  Data        Autore    Descrizione
 016       05/09/2023  VM        #66516
 015       16/03/2023  VM        #55165 - Aggiunto parametro a_cod_fiscale.
                                 Aggiunto filtro cod_fiscale su popolamento cursori.
 014       15/03/2023  VM        #60197 - Aggiunto il parametro a_log_documento
                                 che viene passato alla subprocedure per la
                                 valorizzazione di eventuali errori sul documento
 13        24/06/2021  VD        Modificata gestione contribuente assente:
                                 ora il contribuente viene inserito anche
                                 in fase di caricamento da file (sempre se
                                 esiste gia' il soggetto).
 12        07/04/2021  VD        Modificata gestione contribuente assente:
                                 aggiunti controlli per evitare l'inserimento
                                 di NI già presenti in CONTRIBUENTI.
                                 Creata funzione interna F_CHECK_VERSAMENTI
                                 per verificare se il versamento che si sta
                                 caricando esiste gia', richiamata al posto
                                 delle select nel trattamento dei versamenti
                                 in bonifica e dei versamenti da file.
 11        17/02/2021  VD        Modificata gestione contribuente assente:
                                 il contribuente viene creato comunque se
                                 esiste l'anagrafica in SOGGETTI.
 10        11/01/2021  VD        Gestione nuovo campo note_versamento
                                 della tabella WRK_VERSAMENTI: il contenuto
                                 viene copiato nel campo note della tabella
                                 VERSAMENTI.
 9         16/06/2020  VD        Corretta gestione versamenti su violazione:
                                 si trattano solo i versamenti in bonifica
                                 relativi alle causali 50000 e 50009
                                 (versamenti di imposta)
 8         10/06/2020  VD        Aggiunta gestione nuovo codice tributo
                                 3939 - FABBRICATI COSTRUITI E DESTINATI
                                 DALL'IMPRESA COSTRUTTRICE ALLA VENDITA
 7         25/09/2018  VD        Modifiche per gestione versamenti su
                                 pratiche rateizzate
 6         16/05/2017  VD        Aggiunto raggruppamento per data versamento
                                 per gestire versamenti dello stesso tipo
                                 effettuati in date diverse
 5         05/07/2016  VD        Aggiunto caricamento revoche e ripristini
                                 per tipo tributo ICI
 4         15/06/2016  VD        Aggiunto controllo tipo record in query
                                 principale: si trattano solo i record G1 -
                                 versamenti
 3         04/12/2015  VD        Aggiunta upper in selezione identificativo
                                 operazione
 2         16/01/2015  VD        Aggiunta gestione documento_id e nome_documento
 1         10/12/2014  VD        Aggiunta gestione nuovo campo
                                 identificativo_operazione.
                                 In realtà nei versamenti "normali" tale
                                 identificativo non viene gestito, quindi
                                 se è valorizzato ma la pratica non esiste
                                 in PRATICHE_TRIBUTO, si considera null.
                                 Viene comunque gestito l'inserimento sia
                                 nella riga di VERSAMENTI che in quella
                                 di WRK_VERSAMENTI.
 Causali errore:       50000     Versamento già presente
                       50009     Contribuente non codificato
                       --50350     Pratica non presente o incongruente
                       --50351     Data Pagamento precedente a Data Notifica Pratica
                       --50352     Pratica non Notificata
                       --50360     Pratica rateizzata: versamento antecedente
                       --          alla data di rateazione
                       --50361     Pratica rateizzata: rata errata
                       --50362     Pratica rateizzata: rata gia' versata
 Codici tributo trattati:
 3901 - ICI Abitazione principale
 3902 - ICI Terreni agricoli
 3903 - ICI Aree fabbricabili
 3904 - ICI Altri fabbricati
 3912 - IMU Abitazione principale - COMUNE
 3913 - IMU Fabbricati rurali ad uso strumentale - COMUNE
 3914 - IMU Terreni - COMUNE
 3915 - IMU Terreni - STATO
 3916 - IMU Aree fabbricabili - COMUNE
 3917 - IMU Aree fabbricabili - STATO
 3918 - IMU Altri fabbricati - COMUNE
 3919 - IMU Altri fabbricati - STATO
 3925 - IMU Immobili ad uso produttivo gruppo catastale D - STATO
 3930 - IMU Immobili ad uso produttivo gruppo catastale D - COMUNE
 3939 - IMU Fabbricati costruiti e destinati alla vendita - COMUNE
 3940 - ICI Abitazione principale
 3941 - ICI Terreni agricoli
 3942 - ICI Aree fabbricabili
 3943 - ICI Altri fabbricati
 350E - IMU Fabbricati rurali ad uso strumentale - COMUNE (Enti Pubblici)
 351E - IMU Terreni - COMUNE (Enti Pubblici)
 352E - IMU Terreni - STATO (Enti Pubblici)
 353E - IMU Aree fabbricabili - COMUNE (Enti Pubblici)
 354E - IMU Aree fabbricabili - STATO (Enti Pubblici)
 355E - IMU Altri fabbricati - COMUNE (Enti Pubblici)
 356E - IMU Altri fabbricati - STATO (Enti Pubblici)
 359E - IMU Immobili ad uso produttivo gruppo catastale D - STATO (Enti Pubblici)
 360E - IMU Immobili ad uso produttivo gruppo catastale D - COMUNE (Enti Pubblici)
*************************************************************************/
( a_documento_id            documenti_caricati.documento_id%type default null,
  a_cod_fiscale             in                                   varchar2 default '%',
  a_log_documento           in out                               varchar2)
IS
w_tipo_tributo       varchar2(5) := 'ICI';
w_nome_documento     documenti_caricati.nome_documento%type;
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
w_step               number;
w_progr_delega       varchar2(4000);
-- nella prima fase faccio diventare contribuenti i titolari dei versamenti
-- per cui è stato indicato il flag_contribuente
-- N.B. In pratica si selezionano da wrk_versamenti i versamenti che
--      non sono passati nella tabella effettiva perchè il contribuente
--      non era codificato
-- (VD - 10/12/2014): Aggiunta selezione id. operazione
-- (VD - 04/12/2015): Aggiunta upper in selezione id. operazione
-- (VD - 10/06/2020): Aggiunta selezione nuovi campi fabbricati merce
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
      ,wkve.rurali                       rurali
      ,wkve.fabbricati_d                 fabbricati_d
      ,wkve.fabbricati_merce             fabbricati_merce
      ,wkve.detrazione                   detrazione
      ,wkve.fabbricati                   fabbricati
      ,wkve.tipo_versamento              tipo_versamento
      ,wkve.data_pagamento               data_pagamento
      ,wkve.ufficio_pt                   ufficio_pt
      ,wkve.data_reg                     data_reg
      ,wkve.flag_contribuente            flag_contribuente
      ,cont.cod_fiscale                  cod_fiscale_cont
      ,sogg.cognome_nome                 cognome_nome
      ,wkve.rurali_erariale
      ,wkve.rurali_comune
      ,wkve.terreni_erariale
      ,wkve.terreni_comune
      ,wkve.aree_erariale
      ,wkve.aree_comune
      ,wkve.altri_erariale
      ,wkve.altri_comune
      ,wkve.fabbricati_d_erariale
      ,wkve.fabbricati_d_comune
      ,wkve.num_fabbricati_ab
      ,wkve.num_fabbricati_rurali
      ,wkve.num_fabbricati_terreni
      ,wkve.num_fabbricati_aree
      ,wkve.num_fabbricati_altri
      ,wkve.num_fabbricati_d
      ,wkve.num_fabbricati_merce
      ,wkve.rata
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
   and wkve.causale         = '50009'
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
-- (VD - 10/12/2014): Aggiunta selezione id. operazione
-- (VD - 04/12/2015): Aggiunta upper in selezione id. operazione
-- (VD - 10/06/2020): Aggiunta selezione nuovi campi fabbricati merce
-- (VD - 16/06/2020): Si trattano solo versamenti di imposta (causali 50000 e 50009)
-- (VD - 11/01/2021): Aggiunta selezione nuovo campo note_versamento
cursor sel_errati is
select wkve.progressivo                  progressivo
      ,wkve.anno                         anno
      ,wkve.cod_fiscale                  cod_fiscale
      ,wkve.importo_versato              importo_versato
      ,wkve.ab_principale                ab_principale
      ,wkve.terreni_agricoli             terreni_agricoli
      ,wkve.aree_fabbricabili            aree_fabbricabili
      ,wkve.altri_fabbricati             altri_fabbricati
      ,wkve.rurali
      ,wkve.fabbricati_d
      ,wkve.fabbricati_merce             fabbricati_merce
      ,wkve.detrazione                   detrazione
      ,wkve.fabbricati                   fabbricati
      ,wkve.tipo_versamento              tipo_versamento
      ,wkve.data_pagamento               data_pagamento
      ,wkve.ufficio_pt                   ufficio_pt
      ,wkve.data_reg                     data_reg
      ,wkve.flag_contribuente            flag_contribuente
      ,cont.cod_fiscale                  cod_fiscale_cont
      ,sogg.cognome_nome                 cognome_nome
      ,wkve.rurali_erariale
      ,wkve.rurali_comune
      ,wkve.terreni_erariale
      ,wkve.terreni_comune
      ,wkve.aree_erariale
      ,wkve.aree_comune
      ,wkve.altri_erariale
      ,wkve.altri_comune
      ,wkve.fabbricati_d_erariale
      ,wkve.fabbricati_d_comune
      ,wkve.num_fabbricati_ab
      ,wkve.num_fabbricati_rurali
      ,wkve.num_fabbricati_terreni
      ,wkve.num_fabbricati_aree
      ,wkve.num_fabbricati_altri
      ,wkve.num_fabbricati_d
      ,wkve.num_fabbricati_merce
      ,wkve.rata
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
-- (VD - 10/06/2020): Aggiunta gestione codice tributo 3939
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
      ,max(to_date(substr(wkta.dati, 13, 8),'yyyymmdd'))      data_ripartizione
      ,max(to_date(substr(wkta.dati, 23, 8),'yyyymmdd'))      data_bonifico
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
                 ,'3901',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,'3940',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,'3912',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,0
                 )
          )                                               ab_principale
      ,sum(decode(substr(wkta.dati,79,4)
                 ,'3902',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,'3941',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,'3914',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,'3915',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,'351E',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,'352E',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,0
                 )
          )                                               terreni_agricoli
      ,sum(decode(substr(wkta.dati,79,4)
                 ,'3914',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,'351E',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,0
                 )
          )                                               terreni_agricoli_comune
      ,sum(decode(substr(wkta.dati,79,4)
                 ,'3915',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,'352E',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,0
                 )
          )                                               terreni_agricoli_stato
      ,sum(decode(substr(wkta.dati,79,4)
                 ,'3903',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,'3942',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,'3916',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,'3917',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,'353E',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,'354E',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,0
                 )
          )                                               aree_fabbricabili
      ,sum(decode(substr(wkta.dati,79,4)
                 ,'3916',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,'353E',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,0
                 )
          )                                               aree_fabbricabili_comune
      ,sum(decode(substr(wkta.dati,79,4)
                 ,'3917',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,'354E',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,0
                 )
          )                                               aree_fabbricabili_stato
      ,sum(decode(substr(wkta.dati,79,4)
                 ,'3913',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,'350E',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,0
                 )
          )                                               rurali
      ,sum(decode(substr(wkta.dati,79,4)
                 ,'XXXX',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,0
                 )
          )                                               rurali_erariale
      ,sum(decode(substr(wkta.dati,79,4)
                 ,'3913',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,'350E',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,0
                 )
          )                                               rurali_comune
      ,sum(decode(substr(wkta.dati,79,4)
                 ,'3904',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,'3943',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,'3918',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,'3919',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,'355E',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,'356E',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,0
                 )
          )                                               altri_fabbricati
      ,sum(decode(substr(wkta.dati,79,4)
                 ,'3918',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,'355E',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,0
                 )
          )                                               altri_fabbricati_comune
      ,sum(decode(substr(wkta.dati,79,4)
                 ,'3919',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,'356E',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,0
                 )
          )                                               altri_fabbricati_stato
      ,sum(decode(substr(wkta.dati,79,4)
                 ,'3925',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,'3930',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,'359E',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,'360E',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,0
                 )
          )                                               fabbricati_d
      ,sum(decode(substr(wkta.dati,79,4)
                 ,'3930',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,'360E',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,0
                 )
          )                                               fabbricati_d_comune
      ,sum(decode(substr(wkta.dati,79,4)
                 ,'3925',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,'359E',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,0
                 )
          )                                               fabbricati_d_erariale
      ,sum(decode(substr(wkta.dati,79,4)
                 ,'3939',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,0
                 )
          )                                               fabbricati_merce
      ,max(decode(substr(wkta.dati,79,4)
                 ,'3912',substr(wkta.dati,84,4)
                 ,''
                 )
           )                                              rateazione
      ,max(decode(substr(wkta.dati,79,4)
                 ,'3912',to_number(substr(wkta.dati,130,3))
                 ,to_number(null)
                 )
          )                                               num_fabbricati_ab
      ,max(decode(substr(wkta.dati,79,4)
                 ,'3914',to_number(substr(wkta.dati,130,3))
                 ,'3915',to_number(substr(wkta.dati,130,3))
                 ,'351E',to_number(substr(wkta.dati,130,3))
                 ,'352E',to_number(substr(wkta.dati,130,3))
                 ,to_number(null)
                 )
          )                                               num_fabbricati_terreni
      ,max(decode(substr(wkta.dati,79,4)
                 ,'3916',to_number(substr(wkta.dati,130,3))
                 ,'3917',to_number(substr(wkta.dati,130,3))
                 ,'353E',to_number(substr(wkta.dati,130,3))
                 ,'354E',to_number(substr(wkta.dati,130,3))
                 ,to_number(null)
                 )
          )                                               num_fabbricati_aree
      ,max(decode(substr(wkta.dati,79,4)
                 ,'3913',to_number(substr(wkta.dati,130,3))
                 ,'350E',to_number(substr(wkta.dati,130,3))
                 ,to_number(null)
                 )
          )                                               num_fabbricati_rurali
      ,max(decode(substr(wkta.dati,79,4)
                 ,'3918',to_number(substr(wkta.dati,130,3))
                 ,'3919',to_number(substr(wkta.dati,130,3))
                 ,'355E',to_number(substr(wkta.dati,130,3))
                 ,'356E',to_number(substr(wkta.dati,130,3))
                 ,to_number(null)
                 )
          )                                               num_fabbricati_altri
      ,max(decode(substr(wkta.dati,79,4)
                 ,'3925',to_number(substr(wkta.dati,130,3))
                 ,'3930',to_number(substr(wkta.dati,130,3))
                 ,'359E',to_number(substr(wkta.dati,130,3))
                 ,'360E',to_number(substr(wkta.dati,130,3))
                 ,to_number(null)
                 )
          )                                               num_fabbricati_d
      ,max(decode(substr(wkta.dati,79,4)
                 ,'3939',to_number(substr(wkta.dati,130,3))
                 ,to_number(null)
                 )
          )                                               num_fabbricati_merce
      ,sum(decode(substr(wkta.dati,79,4)
                 ,'3901',to_number(substr(wkta.dati,130,3))
                 ,'3904',to_number(substr(wkta.dati,130,3))
                 ,'3912',to_number(substr(wkta.dati,130,3))
                 ,'3913',to_number(substr(wkta.dati,130,3))
                 ,'3918',to_number(substr(wkta.dati,130,3))
                 ,'3930',to_number(substr(wkta.dati,130,3))
                 ,'3939',to_number(substr(wkta.dati,130,3))
                 ,'3940',to_number(substr(wkta.dati,130,3))
                 ,'3943',to_number(substr(wkta.dati,130,3))
                 ,'350E',to_number(substr(wkta.dati,130,3))
                 ,'355E',to_number(substr(wkta.dati,130,3))
                 ,'359E',to_number(substr(wkta.dati,130,3))
                 ,0
                 )
          )                                               fabbricati
      ,9                                                  fonte
      ,'F24'                                              utente
      ,trunc(sysdate)                                     data_variazione
      ,max(to_date(substr(wkta.dati,3,8),'yyyymmdd'))     data_reg
      ,sum(to_number(substr(wkta.dati,134,15)) / 100)     detrazione
      ,to_number(substr(wkta.dati,31,6))                  progr_delega
  from wrk_tras_anci         wkta
      ,contribuenti          cont
      ,soggetti              sogg
 where cont.cod_fiscale     (+) = rtrim(substr(wkta.dati,50,16))
   and sogg.ni              (+) = cont.ni
   and wkta.anno                = 2
   --and substr(wkta.dati,79,4) not in ('3906','3907','3923','3924','3926','3927','3928','357E','358E')  -- si escludono i versamenti su violazioni e imposta di scopo
   and substr(wkta.dati,79,4) in ('3901','3902','3903','3904','3912'
                                 ,'3913','3914','3915','3916','3917'
                                 ,'3918','3919','3925','3930','3939'
                                 ,'3940','3941','3942','3943'
                                 ,'350E','351E','352E','353E','354E'
                                 ,'355E','356E','359E','360E')
   and to_number(substr(wkta.dati,126,1))  <> 1  -- si escludono i versamenti su ravvedimenti
   and substr(wkta.dati,260,1) = 'I' -- ICI/IMU
   and substr(wkta.dati,1,2) = 'G1'  -- Si trattano solo i versamenti
 group by rtrim(substr(wkta.dati,50,16))             -- codice fiscale "versante"
         ,to_number(substr(wkta.dati,88,4))          -- anno
         ,decode(substr(wkta.dati,128,2)
                ,'00','U','01','S','10','A','11','U',null
                )                                    -- tipo versamento
         ,upper(rtrim(substr(wkta.dati,279,18)))     -- id. operazione
         ,to_date(substr(wkta.dati,67,8),'yyyymmdd') -- data_pagamento
         ,to_number(substr(wkta.dati,31,6))          -- progr_delega
 order by min(wkta.progressivo)
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
-- confermati da operatore (solo contribuenti effettivamente inesistenti)
--
w_step := 1;
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
               END;*/
               -- (VD - 25/09/2018): per contribuenti inesistenti non ha senso
               --                    lanciare la function di ricerca pratica
               -- w_pratica := F_F24_PRATICA(rec_ins_cont.cod_fiscale,rec_ins_cont.id_operazione,rec_ins_cont.data_pagamento,w_tipo_tributo);
               --
               -- Se il risultato della function è negativo, significa che la pratica
               -- non esiste oppure non è congruente con i dati indicati
               -- Si assume che in assenza di contribuente non esista neanche la pratica
               --
               --if nvl(w_pratica,0) < 0 then
               --   w_pratica := to_number(null);
               --end if;
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
              --
              -- (VD - 29/10/2018): arrivati a questo punto, se la pratica esiste
              --                    e' corretta
              if nvl(w_pratica,0) > 0 then
                 w_anno_pratica := to_number(substr(rec_ins_cont.id_operazione,5,4));
                 w_rata_pratica := to_number(substr(rec_ins_cont.id_operazione,9,2));
              else
                 w_anno_pratica := to_number(null);
                 w_rata_pratica := 0;
              end if;
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
                 w_sequenza := to_number(null);
                 VERSAMENTI_NR ( w_cod_fiscale, nvl(w_anno_pratica, rec_ins_cont.anno)
                               , w_tipo_tributo, w_sequenza );
                 -- (VD - 10/06/2020): aggiunti nuovi campi fabbricati merce
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
                        ,terreni_erariale
                        ,terreni_comune
                        ,aree_erariale
                        ,aree_comune
                        ,altri_erariale
                        ,altri_comune
                        ,num_fabbricati_ab
                        ,num_fabbricati_rurali
                        ,num_fabbricati_terreni
                        ,num_fabbricati_aree
                        ,num_fabbricati_altri
                        ,rata
                        ,fabbricati_d
                        ,fabbricati_d_erariale
                        ,fabbricati_d_comune
                        ,num_fabbricati_d
                        ,rurali_erariale
                        ,rurali_comune
                        ,note
                        ,documento_id
                        ,sanzioni_1
                        ,interessi
                        ,fabbricati_merce
                        ,num_fabbricati_merce)
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
                        ,rec_ins_cont.terreni_erariale
                        ,rec_ins_cont.terreni_comune
                        ,rec_ins_cont.aree_erariale
                        ,rec_ins_cont.aree_comune
                        ,rec_ins_cont.altri_erariale
                        ,rec_ins_cont.altri_comune
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
                        ,rec_ins_cont.fabbricati_d_erariale
                        ,rec_ins_cont.fabbricati_d_comune
                        ,rec_ins_cont.num_fabbricati_d
                        ,rec_ins_cont.rurali_erariale
                        ,rec_ins_cont.rurali_comune
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
                        ,rec_ins_cont.fabbricati_merce
                        ,rec_ins_cont.num_fabbricati_merce
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
                 --
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
w_step := 2;
   FOR rec_errati IN sel_errati
   LOOP
      --
      -- Se il codice fiscale del contribuente è nullo, significa che il contribuente
      -- non esiste in tabella CONTRIBUENTI. Si aggiornano il codice (50009) e il
      -- messaggio di errore
      --
      if rec_errati.cod_fiscale_cont is null then
         -- dbms_output.put_line('upd wrk 50009 '||rec_errati.progressivo||' '||SQLERRM);
         update wrk_versamenti wkve
            set wkve.cognome_nome = rec_errati.cognome_nome
               ,wkve.causale      = '50009'
               ,wkve.note         = decode(rec_errati.tipo_messaggio,'I','Imposta - '
                                                                    ,'S','Sanzioni e Interessi - '
                                                                        ,'')||
                                    'Contribuente ('||rec_errati.cod_fiscale||') sconosciuto'
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
                      --                                                         ,'')||
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
            --
            -- (VD - 29/10/2018): arrivati a questo punto, se la pratica esiste
            --                    e' corretta. Si estraggono anno e rata
            --                    dall'identificativo operazione
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
                   -- and vers.fonte                  = 9
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
            end if;*/
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
               END; */
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
                        ,terreni_erariale
                        ,terreni_comune
                        ,aree_erariale
                        ,aree_comune
                        ,altri_erariale
                        ,altri_comune
                        ,num_fabbricati_ab
                        ,num_fabbricati_rurali
                        ,num_fabbricati_terreni
                        ,num_fabbricati_aree
                        ,num_fabbricati_altri
                        ,rata
                        ,fabbricati_d
                        ,fabbricati_d_erariale
                        ,fabbricati_d_comune
                        ,num_fabbricati_d
                        ,rurali_erariale
                        ,rurali_comune
                        ,note
                        ,documento_id
                        ,sanzioni_1
                        ,interessi
                        ,fabbricati_merce
                        ,num_fabbricati_merce
                        )
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
                        ,rec_errati.terreni_erariale
                        ,rec_errati.terreni_comune
                        ,rec_errati.aree_erariale
                        ,rec_errati.aree_comune
                        ,rec_errati.altri_erariale
                        ,rec_errati.altri_comune
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
                        ,rec_errati.fabbricati_d_erariale
                        ,rec_errati.fabbricati_d_comune
                        ,rec_errati.num_fabbricati_d
                        ,rec_errati.rurali_erariale
                        ,rec_errati.rurali_comune
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
                        ,rec_errati.sanzioni_1
                        ,rec_errati.interessi
                        ,rec_errati.fabbricati_merce
                        ,rec_errati.num_fabbricati_merce
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
w_step := 3;
   FOR rec_vers IN sel_vers
   LOOP
      --
      -- Se il codice fiscale del contribuente è nullo, significa che il
      -- contribuente non esiste in tabella CONTRIBUENTI.
      -- Si inserisce il versamento in WRK_VERSAMENTI con il codice (50009)
      -- e il messaggio di errore
      -- (VD - 24/06/2021): se il contribuente non esiste ma esiste un
      --                    soggetto con lo stesso codice fiscale, si crea
      --                    un nuovo contribuente
      --
      if rec_vers.cod_fiscale is null then
         w_cod_fiscale := f_crea_contribuente(rec_vers.cod_fiscale_vers,w_errore);
         if w_cod_fiscale is null then
            w_progressivo := F_SELEZIONA_PROGRESSIVO;
            insert into wrk_versamenti
                  (progressivo,tipo_tributo,tipo_incasso,anno,ruolo,cod_fiscale,
                   cognome_nome,causale,disposizione,data_variazione,note,
                   tipo_versamento,ufficio_pt,data_pagamento,ab_principale,
                   terreni_agricoli,aree_fabbricabili,altri_fabbricati,
                   data_reg,detrazione,fabbricati,importo_versato
                  ,rurali
                  ,terreni_erariale
                  ,terreni_comune
                  ,aree_erariale
                  ,aree_comune
                  ,altri_erariale
                  ,altri_comune
                  ,num_fabbricati_ab
                  ,num_fabbricati_rurali
                  ,num_fabbricati_terreni
                  ,num_fabbricati_aree
                  ,num_fabbricati_altri
                  ,rata
                  ,fabbricati_d
                  ,fabbricati_d_erariale
                  ,fabbricati_d_comune
                  ,num_fabbricati_d
                  ,rurali_erariale
                  ,rurali_comune
                  ,identificativo_operazione
                  ,documento_id
                  ,rateazione
                  ,fabbricati_merce
                  ,num_fabbricati_merce
                  )
            values(w_progressivo,w_tipo_tributo,'F24',rec_vers.anno,null,rec_vers.cod_fiscale_vers,
                   rec_vers.cognome_nome,'50009',w_progressivo,sysdate,
                   'Imposta - '||decode(w_errore,
                                        null,'Contribuente ('||rec_vers.cod_fiscale_vers||') sconosciuto',
                                        substr(w_errore,1,2000)),
                   rec_vers.tipo_versamento,rec_vers.ufficio_pt,rec_vers.data_pagamento,
                   rec_vers.ab_principale,rec_vers.terreni_agricoli,
                   rec_vers.aree_fabbricabili,rec_vers.altri_fabbricati,
                   rec_vers.data_reg,rec_vers.detrazione,rec_vers.fabbricati,
                   rec_vers.importo_versato
                  ,rec_vers.rurali
                  ,rec_vers.terreni_agricoli_stato
                  ,rec_vers.terreni_agricoli_comune
                  ,rec_vers.aree_fabbricabili_stato
                  ,rec_vers.aree_fabbricabili_comune
                  ,rec_vers.altri_fabbricati_stato
                  ,rec_vers.altri_fabbricati_comune
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
                  ,rec_vers.fabbricati_d_erariale
                  ,rec_vers.fabbricati_d_comune
                  ,rec_vers.num_fabbricati_d
                  ,rec_vers.rurali_erariale
                  ,rec_vers.rurali_comune
                  ,rec_vers.id_operazione
                  ,a_documento_id
                  ,rec_vers.rateazione
                  ,rec_vers.fabbricati_merce
                  ,rec_vers.num_fabbricati_merce
                  );
         end if;
      else
         w_cod_fiscale := rec_vers.cod_fiscale;
      end if;
      -- (VD - 24/06/2021): se il contribuente esisteva gia' oppure e' appena
      --                    stato inserito, si prosegue il trattamento
w_step := 3.1;
      if w_cod_fiscale is not null then
         --w_pratica := F_F24_PRATICA(rec_vers.cod_fiscale,rec_vers.id_operazione,rec_vers.data_pagamento,w_tipo_tributo);
         w_pratica := F_F24_PRATICA(w_cod_fiscale,rec_vers.id_operazione,rec_vers.data_pagamento,w_tipo_tributo);
         --
         -- Se il risultato della function è < 0, significa che la pratica
         -- non esiste oppure non è congruente con i dati indicati.
         --
w_step := 3.2;
         if nvl(w_pratica,0) < 0 then
            w_progressivo := F_SELEZIONA_PROGRESSIVO;
w_step := 3.3;
            insert into wrk_versamenti
                  (progressivo,tipo_tributo,tipo_incasso,anno,ruolo,cod_fiscale,
                   cognome_nome,causale,disposizione,data_variazione,note,
                   tipo_versamento,ufficio_pt,data_pagamento,ab_principale,
                   terreni_agricoli,aree_fabbricabili,altri_fabbricati,
                   data_reg,detrazione,fabbricati,importo_versato
                  ,rurali
                  ,terreni_erariale
                  ,terreni_comune
                  ,aree_erariale
                  ,aree_comune
                  ,altri_erariale
                  ,altri_comune
                  ,num_fabbricati_ab
                  ,num_fabbricati_rurali
                  ,num_fabbricati_terreni
                  ,num_fabbricati_aree
                  ,num_fabbricati_altri
                  ,rata
                  ,fabbricati_d
                  ,fabbricati_d_erariale
                  ,fabbricati_d_comune
                  ,num_fabbricati_d
                  ,rurali_erariale
                  ,rurali_comune
                  ,identificativo_operazione
                  ,documento_id
                  ,rateazione
                  ,fabbricati_merce
                  ,num_fabbricati_merce
                  )
            select w_progressivo,w_tipo_tributo,'F24',rec_vers.anno,null,rec_vers.cod_fiscale_vers,
                   rec_vers.cognome_nome,
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
                   --                        -3,'Versamento con codici violazione Pratica non Notificata'),
                   'Imposta - '||f_f24_causale_errore(w_pratica,'D'),  -- note
                   rec_vers.tipo_versamento,rec_vers.ufficio_pt,rec_vers.data_pagamento,
                   rec_vers.ab_principale,rec_vers.terreni_agricoli,rec_vers.aree_fabbricabili,
                   rec_vers.altri_fabbricati,rec_vers.data_reg,rec_vers.detrazione,rec_vers.fabbricati,
                   rec_vers.importo_versato
                  ,rec_vers.rurali
                  ,rec_vers.terreni_agricoli_stato
                  ,rec_vers.terreni_agricoli_comune
                  ,rec_vers.aree_fabbricabili_stato
                  ,rec_vers.aree_fabbricabili_comune
                  ,rec_vers.altri_fabbricati_stato
                  ,rec_vers.altri_fabbricati_comune
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
                  ,rec_vers.fabbricati_d_erariale
                  ,rec_vers.fabbricati_d_comune
                  ,rec_vers.num_fabbricati_d
                  ,rec_vers.rurali_erariale
                  ,rec_vers.rurali_comune
                  ,rec_vers.id_operazione
                  ,a_documento_id
                  ,rec_vers.rateazione
                  ,rec_vers.fabbricati_merce
                  ,rec_vers.num_fabbricati_merce
              from dual;
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
            END;*/
            --(VD - 25/09/2018): si estrae la rata dall'identificativo
            -- operazione. Se è zero, si considererà la rateazione
            -- presente sul versamento
            --
w_step := 3.4;
            if w_pratica is not null then
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
            -- Se w_conta è > 0, significa che esiste già un versamento uguale a quello che
            -- si vuole caricare.
            -- Si inserisce il versamento in WRK_VERSAMENTI con il codice (50000) e il
            -- messaggio di errore
w_step := 3.5;
            if w_conta > 0 then
               w_progressivo := F_SELEZIONA_PROGRESSIVO;
               insert into wrk_versamenti
                     (progressivo,tipo_tributo,tipo_incasso,anno,ruolo,cod_fiscale,
                      cognome_nome,causale,disposizione,data_variazione,note,
                      tipo_versamento,ufficio_pt,data_pagamento,
                      ab_principale,terreni_agricoli,aree_fabbricabili,
                      altri_fabbricati,data_reg,detrazione,fabbricati
                     ,importo_versato
                     ,rurali
                     ,terreni_erariale
                     ,terreni_comune
                     ,aree_erariale
                     ,aree_comune
                     ,altri_erariale
                     ,altri_comune
                     ,num_fabbricati_ab
                     ,num_fabbricati_rurali
                     ,num_fabbricati_terreni
                     ,num_fabbricati_aree
                     ,num_fabbricati_altri
                     ,rata
                     ,fabbricati_d
                     ,fabbricati_d_erariale
                     ,fabbricati_d_comune
                     ,num_fabbricati_d
                     ,rurali_erariale
                     ,rurali_comune
                     ,identificativo_operazione
                     ,documento_id
                     ,rateazione
                     ,fabbricati_merce
                     ,num_fabbricati_merce
                     )
               values(w_progressivo,w_tipo_tributo,'F24',rec_vers.anno,null,rec_vers.cod_fiscale_vers,
                      rec_vers.cognome_nome,'50000',w_progressivo,sysdate,
                      decode(w_pratica,null,'','Imposta - ')||
                      decode(w_rata_pratica
                            ,0,'Versamento gia` Presente in data '||to_char(rec_vers.data_pagamento,'dd/mm/yyyy')
                            ,'Pratica rateizzata: Rata gia'' versata'),
                      rec_vers.tipo_versamento,rec_vers.ufficio_pt,rec_vers.data_pagamento,
                      rec_vers.ab_principale,rec_vers.terreni_agricoli,rec_vers.aree_fabbricabili,
                      rec_vers.altri_fabbricati,rec_vers.data_reg,rec_vers.detrazione,rec_vers.fabbricati,
                      rec_vers.importo_versato
                     ,rec_vers.rurali
                     ,rec_vers.terreni_agricoli_stato
                     ,rec_vers.terreni_agricoli_comune
                     ,rec_vers.aree_fabbricabili_stato
                     ,rec_vers.aree_fabbricabili_comune
                     ,rec_vers.altri_fabbricati_stato
                     ,rec_vers.altri_fabbricati_comune
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
                     ,rec_vers.fabbricati_d_erariale
                     ,rec_vers.fabbricati_d_comune
                     ,rec_vers.num_fabbricati_d
                     ,rec_vers.rurali_erariale
                     ,rec_vers.rurali_comune
                     ,rec_vers.id_operazione
                     ,a_documento_id
                     ,rec_vers.rateazione
                     ,rec_vers.fabbricati_merce
                     ,rec_vers.num_fabbricati_merce
                     );
w_step := 3.6;
            else
w_step := 3.7;
               --
               -- (14/04/2023 - VM - #61996)
               -- Se sono presenti versamenti su violazioni su stesso progressivo delega
               -- si inserisce il versamento in WRK_VERSAMENTI con il codice (50200)
               -- e il messaggio di errore
               w_progr_delega := rec_vers.progr_delega||' data_rip. '||rec_vers.data_ripartizione||
                                 ' data_bon: '||rec_vers.data_bonifico ;
               select count(*)
               into w_count_viol_delega
               from wrk_tras_anci wkta
               where
                    substr(wkta.dati,79,4) in ('3906','3907','3923','3924','357E','358E')          -- versamenti su violazioni
                    and to_number(substr(wkta.dati,126,1))  <> 1                                   -- si escludono i versamenti su ravvedimenti
                    and substr(wkta.dati,260,1) = 'I'                                              -- ICI/IMU
                    and substr(wkta.dati,1,2)   = 'G1'                                             -- Si trattano solo i versamenti
                    and to_number(substr(wkta.dati,31,6)) = rec_vers.progr_delega                  -- progressivo delega
                    and to_date(decode(substr(wkta.dati, 13, 8),'99999999','99991231',
                                       substr(wkta.dati, 13, 8)),'yyyymmdd') = rec_vers.data_ripartizione  -- data ripartizione
                    and to_date(decode(substr(wkta.dati, 23, 8),'99999999','99991231',
                                       substr(wkta.dati, 23, 8)),'yyyymmdd') = rec_vers.data_bonifico      -- data bonifico
               ;
w_step := 3.71;
               if w_count_viol_delega > 0 then
                  w_progressivo := F_SELEZIONA_PROGRESSIVO;
                  insert into wrk_versamenti
                        (progressivo,tipo_tributo,tipo_incasso,anno,ruolo,cod_fiscale,
                         cognome_nome,causale,disposizione,data_variazione,note,
                         tipo_versamento,ufficio_pt,data_pagamento,ab_principale,
                         terreni_agricoli,aree_fabbricabili,altri_fabbricati,
                         data_reg,detrazione,fabbricati,importo_versato
                        ,rurali
                        ,terreni_erariale
                        ,terreni_comune
                        ,aree_erariale
                        ,aree_comune
                        ,altri_erariale
                        ,altri_comune
                        ,num_fabbricati_ab
                        ,num_fabbricati_rurali
                        ,num_fabbricati_terreni
                        ,num_fabbricati_aree
                        ,num_fabbricati_altri
                        ,rata
                        ,fabbricati_d
                        ,fabbricati_d_erariale
                        ,fabbricati_d_comune
                        ,num_fabbricati_d
                        ,rurali_erariale
                        ,rurali_comune
                        ,identificativo_operazione
                        ,documento_id
                        ,rateazione
                        ,fabbricati_merce
                        ,num_fabbricati_merce
                        )
                  select w_progressivo,w_tipo_tributo,'F24',rec_vers.anno,null,rec_vers.cod_fiscale_vers,
                         rec_vers.cognome_nome,
                         '50200',                     -- causale
                         w_progressivo,sysdate,
                         'Imposta - ' || f_get_descr_errore('50200', 'D'), -- note
                         rec_vers.tipo_versamento,rec_vers.ufficio_pt,rec_vers.data_pagamento,
                         rec_vers.ab_principale,rec_vers.terreni_agricoli,rec_vers.aree_fabbricabili,
                         rec_vers.altri_fabbricati,rec_vers.data_reg,rec_vers.detrazione,rec_vers.fabbricati,
                         rec_vers.importo_versato
                        ,rec_vers.rurali
                        ,rec_vers.terreni_agricoli_stato
                        ,rec_vers.terreni_agricoli_comune
                        ,rec_vers.aree_fabbricabili_stato
                        ,rec_vers.aree_fabbricabili_comune
                        ,rec_vers.altri_fabbricati_stato
                        ,rec_vers.altri_fabbricati_comune
                        ,rec_vers.num_fabbricati_ab
                        ,rec_vers.num_fabbricati_rurali
                        ,rec_vers.num_fabbricati_terreni
                        ,rec_vers.num_fabbricati_aree
                        ,rec_vers.num_fabbricati_altri
                        ,to_number(null)
                        ,rec_vers.fabbricati_d
                        ,rec_vers.fabbricati_d_erariale
                        ,rec_vers.fabbricati_d_comune
                        ,rec_vers.num_fabbricati_d
                        ,rec_vers.rurali_erariale
                        ,rec_vers.rurali_comune
                        ,rec_vers.id_operazione
                        ,a_documento_id
                        ,rec_vers.rateazione
                        ,rec_vers.fabbricati_merce
                        ,rec_vers.num_fabbricati_merce
                    from dual
                 ;
w_step := 3.72;
               else
                 -- Se tutti i controlli vengono superati, si inserisce la riga
                 -- nella tabella VERSAMENTI (arrivati a questo punto, la
                 -- variabile w_pratica o e' nulla o contiene il numero di
                 -- pratica di riferimento)
                 /*BEGIN -- Assegnazione Numero Progressivo
                    select nvl(max(vers.sequenza),0)+1
                      into w_sequenza
                      from versamenti vers
                     where vers.cod_fiscale     = rec_vers.cod_fiscale
                       and vers.anno            = nvl(w_anno_pratica,rec_vers.anno)
                       and vers.tipo_tributo    = rec_vers.tipo_tributo
                    ;
                 END; */
w_step := 3.8;
                 w_sequenza := to_number(null);
                 --VERSAMENTI_NR ( rec_vers.cod_fiscale, nvl(w_anno_pratica,rec_vers.anno)
                 VERSAMENTI_NR ( w_cod_fiscale, nvl(w_anno_pratica,rec_vers.anno)
                               , rec_vers.tipo_tributo, w_sequenza );
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
                          ,terreni_erariale
                          ,terreni_comune
                          ,aree_erariale
                          ,aree_comune
                          ,altri_erariale
                          ,altri_comune
                          ,num_fabbricati_ab
                          ,num_fabbricati_rurali
                          ,num_fabbricati_terreni
                          ,num_fabbricati_aree
                          ,num_fabbricati_altri
                          ,rata
                          ,fabbricati_d
                          ,fabbricati_d_erariale
                          ,fabbricati_d_comune
                          ,num_fabbricati_d
                          ,rurali_erariale
                          ,rurali_comune
                          ,note
                          ,documento_id
                          ,fabbricati_merce
                          ,num_fabbricati_merce
                          )
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
                          ,rec_vers.terreni_agricoli_stato
                          ,rec_vers.terreni_agricoli_comune
                          ,rec_vers.aree_fabbricabili_stato
                          ,rec_vers.aree_fabbricabili_comune
                          ,rec_vers.altri_fabbricati_stato
                          ,rec_vers.altri_fabbricati_comune
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
                          ,rec_vers.fabbricati_d_erariale
                          ,rec_vers.fabbricati_d_comune
                          ,rec_vers.num_fabbricati_d
                          ,rec_vers.rurali_erariale
                          ,rec_vers.rurali_comune
                          ,f_f24_note_versamento(rec_vers.id_operazione
                                                ,w_pratica
                                                ,'I'
                                                ,a_documento_id
                                                ,w_tipo_tributo
                                                ,null
                                                ,rec_vers.rateazione
                                                )
                          ,a_documento_id
                          ,rec_vers.fabbricati_merce
                          ,rec_vers.num_fabbricati_merce
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
w_step := 3.9;
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
            --and substr(wkta.dati,79,4) not in ('3906','3907','3923','3924','3926','3927','3928','357E','358E')  -- si escludono i versamneti su violazioni  e imposta di scopo
            and substr(wkta.dati,79,4) in ('3901','3902','3903','3904','3912'
                                          ,'3913','3914','3915','3916','3917'
                                          ,'3918','3919','3925','3930','3939'
                                          ,'3940','3941','3942','3943'
                                          ,'350E','351E','352E','353E','354E'
                                          ,'355E','356E','359E','360E')
            and to_number(substr(wkta.dati,126,1))  <> 1                                           -- si escludono i versamenti su ravvedimenti
            and substr(wkta.dati,260,1) = 'I'                                                      -- ICI/IMU
            and substr(wkta.dati,1,2)   = 'G1'                                                     -- si trattano solo i versamenti
            and nvl(upper(rtrim(substr(wkta.dati,279,18))),'*') = nvl(rec_vers.id_operazione,'*')  -- identificativo operazione
            and substr(wkta.dati,67,8) = to_char(rec_vers.data_pagamento,'yyyymmdd')               -- data pagamento
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
w_step := 4;
CARICA_VERS_RAVV_ICI_F24 (a_documento_id, a_cod_fiscale);
----------------------------------------------------
-- Trattamento dei versamenti su violazioni
----------------------------------------------------
w_step := 5;
CARICA_VERS_VIOL_ICI_F24 (a_documento_id, a_cod_fiscale, a_log_documento);
--------------------------------------------------------
-- (VD - 05/07/2016) Trattamento di revoche e ripristini
--------------------------------------------------------
w_step := 6;
CARICA_ANNULLAMENTI_F24 (a_documento_id, w_tipo_tributo, a_cod_fiscale);
EXCEPTION
   WHEN errore THEN
      RAISE_APPLICATION_ERROR(-20999,w_errore);
   WHEN OTHERS THEN
      ROLLBACK;
      RAISE_APPLICATION_ERROR(-20999,'Step ICI: '||w_step||' '||'progr_delega: '||w_progr_delega||' '||to_char(SQLCODE)||' - '||substr(SQLERRM,1,100));
END;
/* End Procedure: CARICA_VERSAMENTI_ICI_F24 */
/
