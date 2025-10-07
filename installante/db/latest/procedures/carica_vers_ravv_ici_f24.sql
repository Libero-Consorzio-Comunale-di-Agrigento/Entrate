--liquibase formatted sql 
--changeset abrandolini:20250326_152423_carica_vers_ravv_ici_f24 stripComments:false runOnChange:true 
 
create or replace procedure CARICA_VERS_RAVV_ICI_F24
/*************************************************************************
 Versione  Data         Autore    Descrizione
 019       17/04/2025   VM        #78860
                                  Gestione errori durante CREA_RAVVEDIMENTO_DA_VERS
 018       16/03/2023   VM        #55165 - Aggiunto parametro a_cod_fiscale.
                                  Aggiunto filtro cod_fiscale su popolamento cursori.
 17        24/06/2021   VD        Modificata gestione contribuente assente:
                                  ora il contribuente viene inserito anche
                                  in fase di caricamento da file (sempre se
                                  esiste gia' il soggetto).
 16        09/04/2021   VD        Modificata gestione contribuente assente:
                                  aggiunti controlli per evitare l'inserimento
                                  di NI già presenti in CONTRIBUENTI.
 15        11/01/2021   VD        Gestione nuovo campo note_versamento
                                  della tabella WRK_VERSAMENTI: il contenuto
                                  viene copiato nel campo note della tabella
                                  VERSAMENTI.
 14        01/10/2020   VD        Gestione contribuente mancante: si
                                  trattano anche i contribuenti con flag
                                  nullo.
 13        15/09/2020   VD        Gestione nuova causale di errore nel caso
                                  in cui la creazione della pratica di
                                  ravvedimento non vada a buon fine.
 12        06/07/2020   VD        Aggiunta creazione pratica di ravvedimento
                                  senza oggetti.
                                  Aggiunta gestione contribuente assente: il
                                  contribuente viene inserito in presenza di
                                  anagrafica soggetti anche se il flag non e'
                                  attivo.
 11        10/06/2020   VD        Aggiunta gestione nuovo codice tributo
                                  3939 - FABBRICATI COSTRUITI E DESTINATI
                                  DALL'IMPRESA COSTRUTTRICE ALLA VENDITA
 10        05/05/2020   VD        Aggiunti codici sanzione relativi a
                                  ravvedimento lungo nel test di esistenza
                                  della pratica di ravvedimento
                                  Eliminata union nella query principale
                                  perchè nei ravvedimenti non esistono i codici
                                  tributo relativi a sanzioni e interessi.
 9         25/09/2018   VD        Modifiche per gestione versamenti su
                                  pratiche rateizzate
 8         09/05/2018   VD        Aggiunta gestione exception in ricerca
                                  pratica di ravvedimento
 7         30/10/2017   VD        Aggiunto controllo sui codici sanzione
                                  nelle query di verifica di esistenza
                                  della pratica di ravvedimento per
                                  identificare la pratica corretta
                                  (Acconto/Saldo)
 6         16/05/2017   VD        Aggiunto raggruppamento per data versamento
                                  per gestire versamenti dello stesso tipo
                                  effettuati in date diverse
 5         15/06/2016   VD        Aggiunto controllo tipo record in query
                                  principale: si trattano solo i record G1
                                  (versamenti)
 4         04/12/2015   VD        Aggiunta upper in selezione identificativo
                                  operazione
 3         28/01/2015   VD        Aggiunta distinzione versamenti per:
                                  - Imposta
                                  - Sanzioni e interessi
 2         16/01/2015   VD        Aggiunta gestione documento_id e
                                  nome_documento
 1         11/12/2014   VD        Aggiunta gestione nuovo campo
                                  identificativo_operazione
                                  In presenza di identificativo
                                  operazione si ricerca la pratica
                                  relativa; se l'identificativo è nullo
                                  la ricerca viene eseguita con il metodo
                                  precedente
 Causali errore:        50100     Versamento già presente
                        50109     Contribuente non codificato
                        50150     Pratica di ravvedimento non presente
                        50180     Presenti più pratiche di ravvedimento
                        50190     Errore in creazione pratica di ravvedimento
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
 3906 - ICI Interessi
 3907 - ICI Sanzioni
 3923 - IMU Interessi da accertamento
 3924 - IMU Sanzioni da accertamento
 357E - IMU Interessi da accertamento (Enti pubblici)
 358E - IMU Sanzioni da accertamento (Enti pubblici)
*************************************************************************/
( a_documento_id            documenti_caricati.documento_id%type default null,
  a_cod_fiscale             in                                   varchar2 default '%')
IS
w_tipo_tributo           varchar2(5) := 'ICI';
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
--                    perchè si inserisce solo il contribuente.
--                    Eliminate colonne inutili.
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
--   and nvl(wkve.flag_contribuente,'N') = 'S'
   ;
--
-- Esiste una fase iniziale di bonifica di eventuali anomalie presenti nella
-- tabella intermedia wrk_versamenti. Si tenta di ri-inserire il versamento;
-- se questo va a buon fine, allora si elimina la tabella wrk, altrimenti si
-- lascia la registrazione come in precedenza. Al massimo varia il motivo di
-- errore nel qual caso si cambiano la causale e le note.
--
-- (VD - 04/12/2015): Aggiunta upper in selezione id. operazione
-- (VD - 10/06/2020): Aggiunta selezione nuovi campi fabbricati merce
--
cursor sel_errati is
select wkve.progressivo                  progressivo
      ,wkve.anno                         anno
      ,wkve.cod_fiscale                  cod_fiscale
      ,wkve.importo_versato              importo_versato
      ,wkve.ab_principale                ab_principale
      ,wkve.terreni_agricoli             terreni_agricoli
      ,wkve.aree_fabbricabili            aree_fabbricabili
      ,wkve.rurali
      ,wkve.altri_fabbricati             altri_fabbricati
      ,wkve.fabbricati_d
      ,wkve.fabbricati_merce
      ,wkve.detrazione                   detrazione
      ,wkve.fabbricati                   fabbricati
      ,wkve.tipo_versamento              tipo_versamento
      ,wkve.data_pagamento               data_pagamento
      ,wkve.ufficio_pt                   ufficio_pt
      ,wkve.data_reg                     data_reg
      ,wkve.sanzione_ravvedimento        sanzione_ravvedimento
      ,cont.cod_fiscale                  cod_fiscale_cont
      ,sogg.cognome_nome                 cognome_nome
      ,wkve.terreni_erariale
      ,wkve.terreni_comune
      ,wkve.aree_erariale
      ,wkve.aree_comune
      ,wkve.rurali_erariale
      ,wkve.rurali_comune
      ,wkve.altri_erariale
      ,wkve.altri_comune
      ,wkve.fabbricati_d_erariale
      ,wkve.fabbricati_d_comune
      ,wkve.num_fabbricati_ab
      ,wkve.num_fabbricati_terreni
      ,wkve.num_fabbricati_aree
      ,wkve.num_fabbricati_rurali
      ,wkve.num_fabbricati_altri
      ,wkve.num_fabbricati_d
      ,wkve.num_fabbricati_merce
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
--AND WKVE.PROGRESSIVO = 33562
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
--
-- (VD - 28/01/2015): aggiunta union per selezionare separatamente
--                    imposta e sanzioni/interessi
-- (VD - 04/12/2015): Aggiunta upper in selezione id. operazione
-- (VD - 15/06/2016): Aggiunto test su tipo record G1 - versamento
-- (VD - 16/05/2017): Aggiunto raggruppamento per data versamento
-- (VD - 10/06/2020): Aggiunta gestione codice tributo 3939
--
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
                 ,'3925',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,'359E',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,0
                 )
          )                                               fabbricati_d_erariale
      ,sum(decode(substr(wkta.dati,79,4)
                 ,'3930',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,'360E',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,0
                 )
          )                                               fabbricati_d_comune
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
      ,'I'                                                tipo_messaggio
  from wrk_tras_anci         wkta
      ,contribuenti          cont
      ,soggetti              sogg
 where cont.cod_fiscale     (+) = rtrim(substr(wkta.dati,50,16))
   and sogg.ni              (+) = cont.ni
   and wkta.anno                = 2
   and substr(wkta.dati,79,4) in ('3901','3902','3903','3904','3912'
                                 ,'3913','3914','3915','3916','3917'
                                 ,'3918','3919','3925','3930','3939'
                                 ,'3940','3941','3942','3943'
                                 ,'350E','351E','352E','353E','354E'
                                 ,'355E','356E','359E','360E')
   and to_number(substr(wkta.dati,126,1))  = 1            -- solo versamenti su ravvedimenti
   and substr(wkta.dati,260,1) = 'I'                      -- ICI/IMU
   and substr(wkta.dati,1,2) = 'G1'                       -- Si trattano solo i versamenti
 group by rtrim(substr(wkta.dati,50,16))                  -- codice fiscale di chi ha effettuato il versamento
         ,to_number(substr(wkta.dati,88,4))               -- anno
         ,decode(substr(wkta.dati,128,2)                  -- Acconto/Saldo
                ,'00','U','01','S','10','A','11','U',null
                )
         ,upper(rtrim(substr(wkta.dati,279,18)))          -- Identificativo operazione
         ,to_date(substr(wkta.dati,67,8),'yyyymmdd')      -- Data pagamento
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
      ,to_number(null)                                    terreni_agricoli
      ,to_number(null)                                    terreni_agricoli_comune
      ,to_number(null)                                    terreni_agricoli_stato
      ,to_number(null)                                    aree_fabbricabili
      ,to_number(null)                                    aree_fabbricabili_comune
      ,to_number(null)                                    aree_fabbricabili_stato
      ,to_number(null)                                    rurali
      ,to_number(null)                                    rurali_erariale
      ,to_number(null)                                    rurali_comune
      ,to_number(null)                                    altri_fabbricati
      ,to_number(null)                                    altri_fabbricati_comune
      ,to_number(null)                                    altri_fabbricati_stato
      ,to_number(null)                                    fabbricati_d
      ,to_number(null)                                    fabbricati_d_erariale
      ,to_number(null)                                    fabbricati_d_comune
      ,to_number(null)                                    fabbricati_merce
      ,to_char(null)                                      rateazione
      ,to_number(null)                                    num_fabbricati_ab
      ,to_number(null)                                    num_fabbricati_rurali
      ,to_number(null)                                    num_fabbricati_terreni
      ,to_number(null)                                    num_fabbricati_aree
      ,to_number(null)                                    num_fabbricati_altri
      ,to_number(null)                                    num_fabbricati_d
      ,to_number(null)                                    num_fabbricati_merce
      ,to_number(null)                                    fabbricati
      ,9                                                  fonte
      ,'F24'                                              utente
      ,trunc(sysdate)                                     data_variazione
      ,max(to_date(substr(wkta.dati,3,8),'yyyymmdd'))     data_reg
      ,sum(to_number(substr(wkta.dati,134,15)) / 100)     detrazione
      ,'S'                                                tipo_messaggio
  from wrk_tras_anci         wkta
      ,contribuenti          cont
      ,soggetti              sogg
 where cont.cod_fiscale     (+) = rtrim(substr(wkta.dati,50,16))
   and sogg.ni              (+) = cont.ni
   and wkta.anno                = 2
   and substr(wkta.dati,79,4) in ('3906','3907','3923','3924','357E','358E')
   and to_number(substr(wkta.dati,126,1))  = 1            -- solo versamenti su ravvedimenti
   and substr(wkta.dati,260,1) = 'I'                      -- ICI/IMU
   and substr(wkta.dati,1,2) = 'G1'                       -- Si trattano solo i versamenti
 group by rtrim(substr(wkta.dati,50,16))                  -- codice fiscale di chi ha effettuato il versamento
         ,to_number(substr(wkta.dati,88,4))               -- anno
         ,decode(substr(wkta.dati,128,2)                  -- Acconto/Saldo
                ,'00','U','01','S','10','A','11','U',null
                )
         ,upper(rtrim(substr(wkta.dati,279,18)))          -- Identificativo operazione
         ,to_date(substr(wkta.dati,67,8),'yyyymmdd')      -- Data pagamento
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
--------------------------
-- INIZIO ELABORAZIONE  --
--------------------------
BEGIN
-----------------------------------------------------------------------------
-- Trattamento versamenti con contribuente assente in tabella WRK_VERSAMENTI
-- In questa fase si inseriscono i contribuenti mancanti in tabella
-- CONTRIBUENTI, ma il versamento rimane comunque in bonifica
-----------------------------------------------------------------------------
   FOR rec_ins_cont IN sel_ins_cont  -- gestione flag_contribuente
   LOOP
      --dbms_output.put_line('Contribuente assente: '||rec_ins_cont.cod_fiscale);
      if rec_ins_cont.cod_fiscale_cont is null then
        w_cod_fiscale := f_crea_contribuente(rec_ins_cont.cod_fiscale,w_errore);
        if w_cod_fiscale is null then
           if w_errore is not null then
              update wrk_versamenti wkve
                 set note = substr(decode(note,'','',note||' - ')||w_errore,1,2000)
               where wkve.progressivo  = rec_ins_cont.progressivo;
           end if;
        end if;
         /* begin
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
            -- dbms_output.put_line('Ins contribuenti. '||SQLERRM);
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
         end if;*/
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
                                    'Versamento su Ravvedimento: Contribuente ('||rec_errati.cod_fiscale||') sconosciuto'
          where wkve.progressivo  = rec_errati.progressivo
         ;
      else
         --DBMS_OUTPUT.PUT_LINE('Contribuente: '||rec_errati.cod_fiscale_cont);
         --DBMS_OUTPUT.PUT_LINE('Identificativo operazione: '||rec_errati.id_operazione);
         w_pratica := F_F24_PRATICA(rec_errati.cod_fiscale,rec_errati.id_operazione,rec_errati.data_pagamento,w_tipo_tributo);
         w_messaggio := null;
         w_crea_ravv := 0;
         if nvl(w_pratica,-1) < 0 then
            --DBMS_OUTPUT.PUT_LINE('Pratica assente');
            w_pratica := to_number(null);
            --
            -- (VD - 30/10/2017): aggiunto controllo su codici sanzione
            -- (VD - 05/05/2020): aggiunto controllo su nuovi codici sanzione
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
                                      and sapr.cod_sanzione           in (153,154,156,159,160,167,168,
                                                                          511,512,513,514)
                                      or  rec_errati.tipo_versamento  = 'U'
                                      and sapr.cod_sanzione           in (151,152,153,154,155,
                                                                          156,157,158,159,160,
                                                                          165,166,167,168,
                                                                          511,512,513,514)
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
            --DBMS_OUTPUT.PUT_LINE('w_conta: '||w_conta);
            --
            -- (VD - 30/10/2017): aggiunto controllo su codici sanzione
            -- (VD - 05/05/2020): aggiunto controllo su nuovi codici sanzione
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
                                      and sapr.cod_sanzione           in (153,154,156,159,160,167,168,
                                                                          511,512,513,514)
                                      or  rec_errati.tipo_versamento  = 'U'
                                      and sapr.cod_sanzione           in (151,152,153,154,155,
                                                                          156,157,158,159,160,
                                                                          165,166,167,168,
                                                                          511,512,513,514)
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
            --DBMS_OUTPUT.PUT_LINE('w_conta_importo_esatto: '||w_conta_importo_esatto);
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
                                                'Versamento su Ravvedimento: Piu'' di una Pratica di Ravvedimento Presente'
                where wkve.progressivo  = rec_errati.progressivo
                    ;
            else
               if w_conta = 1 then
                  --
                  -- (VD - 30/10/2017): aggiunto controllo su codici sanzione
                  -- (VD - 05/05/2020): aggiunto controllo su nuovi codici sanzione
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
                                            and sapr.cod_sanzione           in (153,154,156,159,160,167,168,
                                                                                511,512,513,514)
                                            or  rec_errati.tipo_versamento  = 'U'
                                            and sapr.cod_sanzione           in (151,152,153,154,155,
                                                                                156,157,158,159,160,
                                                                                165,166,167,168,
                                                                                511,512,513,514)
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
                  -- (VD - 05/05/2020): aggiunto controllo su nuovi codici sanzione
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
                                            and sapr.cod_sanzione           in (153,154,156,159,160,167,168,
                                                                                511,512,513,514)
                                            or  rec_errati.tipo_versamento  = 'U'
                                            and sapr.cod_sanzione           in (151,152,153,154,155,
                                                                                156,157,158,159,160,
                                                                                165,166,167,168,
                                                                                511,512,513,514)
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
            if rec_errati.anno >= 1 and rec_errati.anno <= 9999 then
              BEGIN
                CREA_RAVVEDIMENTO_DA_VERS(rec_errati.cod_fiscale,rec_errati.anno,
                                          rec_errati.data_pagamento,rec_errati.tipo_versamento,
                                          '','TR4',w_tipo_tributo,
                                          to_number(null),rec_errati.importo_versato,
                                          w_pratica,w_messaggio,
                                          rec_errati.ab_principale,
                                          rec_errati.rurali,
                                          rec_errati.terreni_comune,
                                          rec_errati.terreni_erariale,
                                          rec_errati.aree_comune,
                                          rec_errati.aree_erariale,
                                          rec_errati.altri_comune,
                                          rec_errati.altri_erariale,
                                          rec_errati.fabbricati_d_comune,
                                          rec_errati.fabbricati_d_erariale,
                                          rec_errati.fabbricati_merce
                                          );
              EXCEPTION
                 WHEN errore THEN
                   w_messaggio := w_errore;
                 WHEN OTHERS THEN
                   w_messaggio := to_char(SQLCODE)||' - '||substr(SQLERRM,1,100);
              END;
            else
              w_messaggio := 'Anno '||to_char(rec_errati.anno)||' non valido';
            end if;
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
            -- (VD - 06/07/2020): inserimento versamento
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
            --DBMS_OUTPUT.PUT_LINE('Inserimento versamento');
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
                     ,terreni_agricoli
                     ,aree_fabbricabili
                     ,altri_fabbricati
                     ,pratica
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
                     ,rec_errati.terreni_agricoli
                     ,rec_errati.aree_fabbricabili
                     ,rec_errati.altri_fabbricati
                     ,w_pratica
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
                                           ,rec_errati.note_versamento)
                     ,rec_errati.documento_id
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
            dbms_output.put_line('Dopo delete wrk');
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
                   tipo_versamento,ufficio_pt,data_pagamento,ab_principale,
                   terreni_agricoli,aree_fabbricabili,altri_fabbricati,
                   data_reg,detrazione,fabbricati
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
                   rec_vers.cognome_nome,'50109',w_progressivo,sysdate,
                   decode(rec_vers.tipo_messaggio,'I','Imposta - ',
                                                  'S','Sanzioni e interessi - ')||
                         'Versamento su Ravvedimento: Contribuente ('||rec_vers.cod_fiscale_vers||') sconosciuto',
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
                  -- (VD - 25/09/2018): la rata verrà ricavata dal campo rateazione
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
      if w_cod_fiscale is not null then
         w_messaggio := null;
         --w_pratica := F_F24_PRATICA(rec_vers.cod_fiscale,rec_vers.id_operazione,rec_vers.data_pagamento,w_tipo_tributo);
         w_pratica := F_F24_PRATICA(w_cod_fiscale,rec_vers.id_operazione,rec_vers.data_pagamento,w_tipo_tributo);
         if nvl(w_pratica,-1) < 0 then
            w_pratica := to_number(null);
            w_crea_ravv:= 0;
            --
            -- (VD - 30/10/2017): aggiunto controllo su codici sanzione
            -- (VD - 05/05/2020): aggiunto controllo su nuovi codici sanzione
            --                    (ravv. lungo)
            -- (VD - 06/07/2020): aggiunto controllo su esistenza versamenti
            --                    Se esistono gia' dei versamenti associati
            --                    alla pratica, la pratica non e' da considerare
            --
            BEGIN
               select count(*)
                 into w_conta
                 from pratiche_tributo prtr
                where prtr.cod_fiscale            = w_cod_fiscale --rec_vers.cod_fiscale
                  and prtr.anno                   = rec_vers.anno
                  and prtr.tipo_tributo           = rec_vers.tipo_tributo
                  and prtr.tipo_pratica           = 'V'
                  and exists (select 'x' from sanzioni_pratica sapr
                               where prtr.pratica                     = sapr.pratica
                                 and ( rec_vers.tipo_versamento     = 'A'
                                      and sapr.cod_sanzione           in (151,152,155,157,158,165,166)
                                      or  rec_vers.tipo_versamento  = 'S'
                                      and sapr.cod_sanzione           in (153,154,156,159,160,167,168,
                                                                          511,512,513,514)
                                      or  rec_vers.tipo_versamento  = 'U'
                                      and sapr.cod_sanzione           in (151,152,153,154,155,
                                                                          156,157,158,159,160,
                                                                          165,166,167,168,
                                                                          511,512,513,514)
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
            -- (VD - 05/05/2020): aggiunto controllo su nuovi codici sanzione
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
                                      and sapr.cod_sanzione           in (153,154,156,159,160,167,168,
                                                                          511,512,513,514)
                                      or  rec_vers.tipo_versamento  = 'U'
                                      and sapr.cod_sanzione           in (151,152,153,154,155,
                                                                          156,157,158,159,160,
                                                                          165,166,167,168,
                                                                          511,512,513,514)
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
            if w_conta = 0 then
               -- (VD - 06/07/2020): si attiva il flag per creare la pratica
               --                    di ravvedimento
               w_crea_ravv := 1;
            elsif w_conta > 1 and w_conta_importo_esatto <> 1 then
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
                      rec_vers.cognome_nome,'50180',w_progressivo,sysdate,
                      decode(rec_vers.tipo_messaggio,'I','Imposta - ',
                                                     'S','Sanzioni e interessi - ')||
                            'Versamento su Ravvedimento - Più di una Pratica di Ravvedimento Presente',
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
                     -- (VD - 25/09/2018): la rata verrà ricavata dal campo rateazione
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
            else
               if w_conta = 1 then
                  --
                  -- (VD - 30/10/2017): aggiunto controllo su codici sanzione
                  -- (VD - 05/05/2020): aggiunto controllo su nuovi codici sanzione
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
                                            and sapr.cod_sanzione           in (153,154,156,159,160,167,168,
                                                                                511,512,513,514)
                                            or  rec_vers.tipo_versamento  = 'U'
                                            and sapr.cod_sanzione           in (151,152,153,154,155,
                                                                                156,157,158,159,160,
                                                                                165,166,167,168,
                                                                                511,512,513,514)
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
                  end;
               else
                  --
                  -- (VD - 30/10/2017): aggiunto controllo su codici sanzione
                  -- (VD - 05/05/2020): aggiunto controllo su nuovi codici sanzione
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
                        and prtr.TIPO_PRATICA                = 'V'
                        and (   prtr.importo_totale          = rec_vers.importo_versato
                             or round(prtr.importo_totale,0) = rec_vers.importo_versato
                            )
                        and exists (select 'x' from sanzioni_pratica sapr
                                     where prtr.pratica                   = sapr.pratica
                                       and ( rec_vers.tipo_versamento     = 'A'
                                            and sapr.cod_sanzione           in (151,152,155,157,158,165,166)
                                            or  rec_vers.tipo_versamento  = 'S'
                                            and sapr.cod_sanzione           in (153,154,156,159,160,167,168,
                                                                                511,512,513,514)
                                            or  rec_vers.tipo_versamento  = 'U'
                                            and sapr.cod_sanzione           in (151,152,153,154,155,
                                                                                156,157,158,159,160,
                                                                                165,166,167,168,
                                                                                511,512,513,514)
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
         if w_pratica is null and
            w_crea_ravv = 1 then
            if rec_vers.anno >= 1 and rec_vers.anno <= 9999 then
            --CREA_RAVVEDIMENTO_DA_VERS(rec_vers.cod_fiscale,rec_vers.anno,
              BEGIN
                CREA_RAVVEDIMENTO_DA_VERS(w_cod_fiscale,rec_vers.anno,
                                        rec_vers.data_pagamento,rec_vers.tipo_versamento,
                                        '','TR4',rec_vers.tipo_tributo,
                                        to_number(null),rec_vers.importo_versato,
                                        w_pratica,w_messaggio,
                                        rec_vers.ab_principale,
                                        rec_vers.rurali,
                                        rec_vers.terreni_agricoli_comune,
                                        rec_vers.terreni_agricoli_stato,
                                        rec_vers.aree_fabbricabili_comune,
                                        rec_vers.aree_fabbricabili_stato,
                                        rec_vers.altri_fabbricati_comune,
                                        rec_vers.altri_fabbricati_stato,
                                        rec_vers.fabbricati_d_comune,
                                        rec_vers.fabbricati_d_erariale,
                                        rec_vers.fabbricati_merce
                                        );
              EXCEPTION
                 WHEN errore THEN
                   w_messaggio := w_errore;
                 WHEN OTHERS THEN
                   w_messaggio := to_char(SQLCODE)||' - '||substr(SQLERRM,1,100);
              END;
            else
              w_messaggio := 'Anno '||to_char(rec_vers.anno)||' non valido';
            end if;
            if w_messaggio is not null then
               -- (VD - 06/07/2020): se si rileva un qualche errore in fase
               -- di creazione della pratica, si lascia il versamento
               -- in bonifica (nuovo codice: 50190)
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
                      rec_vers.cognome_nome,'50190',w_progressivo,sysdate,
                      substr(decode(rec_vers.tipo_messaggio,'I','Imposta - ',
                                                     'S','Sanzioni e interessi - ')||
                            'Versamento su Ravvedimento - Errore in creazione pratica di ravvedimento: '||w_messaggio,1.2000),
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
                     -- (VD - 25/09/2018): la rata verrà ricavata dal campo rateazione
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
         end if;
         if w_pratica is not null and w_messaggio is null then
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
                          , rec_vers.tipo_tributo, w_sequenza );
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
                     ,terreni_agricoli
                     ,aree_fabbricabili
                     ,altri_fabbricati
                     ,pratica
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
                     ,rec_vers.terreni_agricoli
                     ,rec_vers.aree_fabbricabili
                     ,rec_vers.altri_fabbricati
                     ,w_pratica
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
                     ,rec_vers.fabbricati_d
                     ,rec_vers.fabbricati_d_erariale
                     ,rec_vers.fabbricati_d_comune
                     ,rec_vers.num_fabbricati_d
                     ,rec_vers.rurali_erariale
                     ,rec_vers.rurali_comune
                     ,f_f24_note_versamento(rec_vers.id_operazione,w_pratica,rec_vers.tipo_messaggio,a_documento_id)
                     ,a_documento_id
                     ,rec_vers.fabbricati_merce
                     ,rec_vers.num_fabbricati_merce
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
                  substr(wkta.dati,79,4) in ('3901','3902','3903','3904','3912'
                                            ,'3913','3914','3915','3916','3917'
                                            ,'3918','3919','3925','3930','3939'
                                            ,'3940','3941','3942','3943'
                                            ,'350E','351E','352E','353E','354E'
                                            ,'355E','356E','359E','360E')) or
                 (rec_vers.tipo_messaggio = 'S' and
                  substr(wkta.dati,79,4) in ('3906','3907','3923','3924','357E','358E')))
            and to_number(substr(wkta.dati,126,1))  = 1           -- solo versamenti su ravvedimenti
            and substr(wkta.dati,260,1) = 'I'                     -- ICI/IMU
            and substr(wkta.dati,1,2)   = 'G1'                    -- si trattano solo i versamenti
            and nvl(upper(rtrim(substr(wkta.dati,279,18))),'*') = nvl(rec_vers.id_operazione,'*')  -- identificativo operazione
            and substr(wkta.dati,67,8) = to_char(rec_vers.data_pagamento,'yyyymmdd')               -- Data pagamento
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
/* End Procedure: CARICA_VERS_RAVV_ICI_F24 */
/
