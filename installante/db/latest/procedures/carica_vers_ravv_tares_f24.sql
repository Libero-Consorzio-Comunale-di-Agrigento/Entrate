--liquibase formatted sql
--changeset abrandolini:20250326_152423_carica_vers_ravv_tares_f24 stripComments:false runOnChange:true 
 
create or replace procedure CARICA_VERS_RAVV_TARES_F24
/*************************************************************************
 16/03/23  VM      #55165 - Aggiunto parametro a_cod_fiscale.
                   Aggiunto filtro cod_fiscale su popolamento cursori.
 05/04/22  VD      Aggiunta gestione caso versamento su accertamento con
                   flag ravvedimento attivo: nel caso in cui la pratica non
                   sia stata notificata o che il versamento sia antecedente
                   alla data di notifica il versamento viene messo in
                   bonifica con la causale 50351 o 50352 (relative alle
                   violazioni e non ai ravvedimenti).
 24/06/21  VD      Modificata gestione contribuente assente:
                   ora il contribuente viene inserito anche in fase di
                   caricamento da file (sempre se esiste gia' il soggetto).
 16/03/21  VD      Gestione nuovo codice tributo per TEFA
 11/01/21  VD      Gestione nuovo campo note_versamento della tabella
                   WRK_VERSAMENTI: il contenuto viene copiato nel campo
                   note della tabella VERSAMENTI.
 25/09/18  VD      Modificata gestione rata su identificativo operazione.
 16/07/18  VD/AB   Lasciato lo zero nella maggiorazione TARES solo per gli
                   anni in cui e' prevista. Altrimenti ltrim('0').
                   Modificato controllo su rata: in presenza del numero
                   pratica puo' valere da 0 a 36.
 09/05/18  VD      Aggiunta gestione exception in ricerca pratica di
                   ravvedimento
 21/07/17  VD      Corretto test numericita' rateazione; afc.is_numeric
                   restituisce 1 se il campo e' numerico e 0 se non lo e'
 10/04/17  VD      Modificato controllo su data pagamento in fase di
                   eliminazione: convertita in formato char la data di
                   confronto
 15/06/15 VD       Aggiunto controllo tipo record in query principale:
                   si trattano solo i record G1 - versamenti
 04/12/15 VD       Aggiunta upper in selezione id_operazione
 30/01/15 VD       Aggiunto controllo su rata: se il valore indicato nel
                   file non è tra quelli previsti, si valorizza a 1
                   Aggiunta gesione id_operazione per ruolo (RUOL%)
 28/01/15 VD       Aggiunta distinzione versamenti per:
                                  - Imposta
                                  - Sanzioni e interessi
 16/01/15 VD       Aggiunta gestione documento_id e nome_documento
 12/12/14 VD       Aggiunta gestione nuovo campo IDENTIFICATIVO_OPERAZIONE
 29/10/14 Betta T. Aggiunti codici tributo 3956 e 3957
 23/10/14 Betta T. Aggiunta nota per spiegare codici tributo utilizzati
 16/10/14 Betta T. La modifica di togliere la group by per rata aveva fatto
                   separare il versamento della maggiorazione tares
                   dal versamento dell imposta.
                   Ho modificato la select per prendere sempre la max rata
                   nel caso di maggiorazione TARES, così da versare la
                   maggiorazione insieme alla rata di saldo (se c è)
 15/10/14 Betta T. Tolta group by per rata e data versamento. Contestualmente
                   corretto test di versamento gia presente
 15/10/14 Betta T. Cambiato il test su tipo imposta per modifiche al tracciato
                   del ministero
 Causali errore:   50100   Versamento su Ravvedimento gia` Presente
                   50109   Versamento su Ravvedimento - Contribuente sconosciuto
                   50150   Versamento su Ravvedimento - Pratica di Ravvedimento non Presente
                   50180   Versamento su Ravvedimento - Più di una Pratica di Ravvedimento Presente
 Codici tributo usati
 3944 - Tari -tassa sui rifiuti -articolo 1- comma 639-legge 147 del 27/12//2013 / tares - articolo 14, decreto legge n. 201 del 6/12//2011
 3955 - MAGGIORAZIONE - ART. 14, C. 13, D.L. N. 201/2011 E SUCC. MODIF
 3945 - TARI - TASSA SUI RIFIUTI - ART. 1, C. 639, L. N. 147/2013 - TARES - ART. 14 DL N. 201/2011 - INTERESSI
 3946 - TARI - TASSA SUI RIFIUTI - ART. 1, C. 639, L. N. 147/2013 - TARES - ART. 14 DL N. 201/2011 - SANZIONI
 3950 - (TARI) TARIFFA - ART. 1, c. 668, L. N. 147/2013- ART. 14, C. 29 DL N. 201/2011
 3951 - (TARI) TARIFFA - ART. 1, C. 668, L. N. 147/2013 - ART. 14, C. 29 DL N. 201/2011 - INTERESSI
 3952 - (TARI) TARIFFA - ART. 1, C. 668, L. N. 147/2013 - ART. 14, C. 29 DL N. 201/2011 - SANZIONI
 365E - EP TARI - Tassa sui rifiuti - art.1,c.639,L.n.147/2013 - TARES - art. 14, d.l. n. 201/2011
 366E - EP TARI - tassa sui rifiuti - art.1, c.639,L.147/2013 -TARES - art. 14, d.l. n. 201/2011 - INTERESSI
 367E - EP TARI - tassa sui rifiuti - art.1, c.639, L. n.147/2013 - TARES - art. 14, d.l. n. 201/2011 - SANZIONI
 368E - EP (TARI) TARIFFA - art. 1, c.668, L. n.147/2013 - art. 14, c. 29, d.l. n. 201/2011
 369E - EP (TARI) TARIFFA - art. 1, c. 668, L. n. 147/2013 - art. 14, c. 29, d.l. n. 201/2011 - INTERESSI
 370E - EP (TARI) TARIFFA - art. 1, c. 668, L. n. 147/2013 -art. 14, c. 29, d.l. n. 201/2011 - SANZIONI
 371E - EP MAGGIORAZIONE - art. 14, c. 13, d.l. n. 201/2011 e succ. modif.
 372E - EP MAGGIORAZIONE - art. 14, c. 13, d.l. n. 201/2011 e succ. modif. - INTERESSI
 373E - EP MAGGIORAZIONE - art. 14, c. 13, d.l. n. 201/2011 e succ. modif. - SANZIONI
 3956 - INTERESSI MAGGIORAZIONE
 3957 - SANZIONI MAGGIORAZIONE
 Nell imposta selezioniamo 3944,3950,365E,368E
 Nella maggiorazione selezioniamo 3955,371E
 mancano quindi 3945,3946,3951,3952,366E,367E,369E,370E,372E,373E,3956,3957 ovvero interessi e sanzioni
 dove li dobbiamo mettere?
 TEFA - TRIBUTO PER L'ESERCIZIO DELLE FUNZIONI DI TUTELA, PROTEZIONE E IGIENE DELL'AMBIENTE
*************************************************************************/
( a_documento_id            documenti_caricati.documento_id%type default null,
  a_cod_fiscale             in                                   varchar2 default '%')
IS
w_tipo_tributo           varchar2(5) := 'TARSU';
w_progressivo            number;
w_sequenza               number;
w_conta                  number;
w_conta_importo_esatto   number;
w_pratica                number;
w_ruolo                  number;
w_rata                   number;
w_flag_infrazione        varchar(1);
w_magg_tares             number;
w_cod_fiscale            varchar2(16);
w_errore                 varchar2(2000);
errore                   exception;
--
-- Esiste una fase iniziale di bonifica di eventuali anomalie presenti nella
-- tabella intermedia wrk_versamenti. Si tenta di ri-inserire il versamento;
-- se questo va a buon fine, allora si elimina la tabella wrk, altrimenti si
-- lascia la registrazione come in precedenza. Al massimo varia il motivo di
-- errore nel qual caso si cambiano la causale e le note.
--
-- (VD - 04/12/2015): Aggiunta upper in selezione id. operazione
-- (VD - 11/01/2021): Aggiunta selezione nuovo campo note_versamento
cursor sel_errati is
select wkve.progressivo                  progressivo
      ,wkve.anno                         anno
      ,wkve.cod_fiscale                  cod_fiscale
      ,wkve.importo_versato              importo_versato
      ,wkve.addizionale_pro              addizionale_pro
      ,wkve.maggiorazione_tares          maggiorazione_tares
      ,wkve.fabbricati                   fabbricati
      ,wkve.tipo_versamento              tipo_versamento
      ,wkve.data_pagamento               data_pagamento
      ,wkve.ufficio_pt                   ufficio_pt
      ,wkve.data_reg                     data_reg
      ,wkve.sanzione_ravvedimento        sanzione_ravvedimento
      ,wkve.flag_contribuente            flag_contribuente
      ,cont.cod_fiscale                  cod_fiscale_cont
      ,sogg.cognome_nome                 cognome_nome
      ,wkve.rata
      ,upper(wkve.identificativo_operazione)    id_operazione
      ,substr(wkve.note,1,1)                    tipo_messaggio
      ,wkve.documento_id
      ,wkve.note_versamento
  from wrk_versamenti wkve
      ,contribuenti   cont
      ,soggetti       sogg
 where wkve.tipo_incasso    = 'F24'
   and wkve.tipo_tributo    = w_tipo_tributo
   and wkve.CAUSALE         in ('50100','50109','50150','50180')  -- RAVVEDIMENTO
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
-- (VD - 15/12/2014): Modificato per gestire il nuovo campo identificativo
--                    operazione anche come raggruppamento
--
-- (VD - 28/01/2015): aggiunta union per selezionare separatamente
--                    imposta e sanzioni/interessi
-- (VD - 04/12/2015): Aggiunta upper in selezione id. operazione
-- (VD - 15/06/2016): Aggiunto test su tipo record G1 - versamento
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
      ,'VERSAMENTO IMPORTATO DA MODELLO F24'             descrizione
      ,max(decode(substr(wkta.dati,44,1)
                 ,'B','Banca - ABI '||substr(wkta.dati,39,5)||' CAB '||substr(wkta.dati,45,5)
                 ,'C','Concessionario - Codice '||substr(wkta.dati,39,5)
                 ,'P','Poste - Codice '||substr(wkta.dati,39,5)
                 ,'I','Internet'
                     ,null
                 )
          )                                               ufficio_pt
      ,to_date(substr(wkta.dati,67,8),'yyyymmdd')         data_pagamento
      ,sum((to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100)
                                                          importo_versato
      ,sum(decode(substr(wkta.dati,79,4)
                 ,'3944',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,'3920',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100                 
                 ,'3950',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,'365E',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,'368E',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,0
                 )
          )                                               importo
      ,sum(decode(substr(wkta.dati,79,4)
                 ,'TEFA',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,0
                 )
          )                                               addizionale_pro
      ,sum(decode(substr(wkta.dati,79,4)
                 ,'3955',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,'371E',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,0
                 )
          )                                               maggiorazione_tares
      ,decode(substr(wkta.dati,79,4)
             ,'3944',substr(wkta.dati,84,2)
             ,'3920',substr(wkta.dati,84,2)             
             ,'3950',substr(wkta.dati,84,2)
             ,'365E',substr(wkta.dati,84,2)
             ,'368E',substr(wkta.dati,84,2)
             ,'TEFA',substr(wkta.dati,84,2)
             ,'3955',max_rata.rata
             ,'371E',max_rata.rata
             ,''
             )                                            rateazione
      ,9                                                  fonte
      ,'F24'                                              utente
      ,trunc(sysdate)                                     data_variazione
      ,max(to_date(substr(wkta.dati,3,8),'yyyymmdd'))     data_reg
      ,max(decode(substr(wkta.dati,79,4)
                 ,'3944',to_number(substr(wkta.dati,130,3))
                 ,'3920',to_number(substr(wkta.dati,130,3))                 
                 ,'3950',to_number(substr(wkta.dati,130,3))
                 ,'365E',to_number(substr(wkta.dati,130,3))
                 ,'368E',to_number(substr(wkta.dati,130,3))
                 ,0
                 )
          )                                               fabbricati
      ,'I'                                                tipo_messaggio
  from wrk_tras_anci         wkta
      ,contribuenti          cont
      ,soggetti              sogg
      ,(select rtrim(substr(wkta.dati,50,16))             cod_fiscale
              ,to_number(substr(wkta.dati,88,4))          anno_rif
              ,to_date(substr(wkta.dati,67,8),'yyyymmdd') data_pagamento
              ,upper(rtrim(substr(wkta.dati,279,18)))     id_operazione
              ,max(decode(substr(wkta.dati,79,4)
                         ,'3944',substr(wkta.dati,84,2)
                         ,'3920',substr(wkta.dati,84,2)                         
                         ,'3950',substr(wkta.dati,84,2)
                         ,'365E',substr(wkta.dati,84,2)
                         ,'368E',substr(wkta.dati,84,2)
                         ,'TEFA',substr(wkta.dati,84,2)
                         ,''
                         )) rata
          from wrk_tras_anci         wkta
         where wkta.anno                = 2
           and substr(wkta.dati,79,4) in ('3944','3955','3950','365E','368E','371E','TEFA', '3920')   -- si prendono solo i codici tributo della TARES.
           and to_number(substr(wkta.dati,126,1))  = 1    -- solo versamenti su ravvedimenti
           and substr(wkta.dati,260,1) in ('A','T')       -- TARSU/TARES/TARI il tracciato riportava T, ma nel file c è A
           and substr(wkta.dati,1,2) = 'G1'               -- Si trattano solo i versamenti
         group by  rtrim(substr(wkta.dati,50,16))         -- cod_fiscale
              ,to_number(substr(wkta.dati,88,4))          -- anno_rif
              ,to_date(substr(wkta.dati,67,8),'yyyymmdd') -- data_pagamento
              ,upper(rtrim(substr(wkta.dati,279,18)))     -- id_operazione
        ) max_rata
 where cont.cod_fiscale     (+) = rtrim(substr(wkta.dati,50,16))
   and sogg.ni              (+) = cont.ni
   and wkta.anno                = 2
   and substr(wkta.dati,79,4) in ('3944','3955','3950','365E','368E','371E','TEFA', '3920')    -- si prendono solo i codici tributo della TARES.
   and to_number(substr(wkta.dati,126,1))  = 1  -- solo versamenti su ravvedimenti
   and substr(wkta.dati,260,1) in ('A','T')     -- TARSU/TARES/TARI il tracciato riportava T, ma nel file c è A
   and rtrim(substr(wkta.dati,50,16)) = max_rata.cod_fiscale
   and to_number(substr(wkta.dati,88,4)) = max_rata.anno_rif
   and to_date(substr(wkta.dati,67,8),'yyyymmdd') = max_rata.data_pagamento
   and nvl(upper(rtrim(substr(wkta.dati,279,18))),'*') = nvl(max_rata.id_operazione,'*')
   and substr(wkta.dati,1,2) = 'G1'                   -- Si trattano solo i versamenti
 group by rtrim(substr(wkta.dati,50,16))              -- cod fiscale
         ,to_number(substr(wkta.dati,88,4))           -- anno rif
         ,to_date(substr(wkta.dati,67,8),'yyyymmdd')  -- data_pagamento
         ,decode(substr(wkta.dati,128,2)
                ,'00','U','01','S','10','A','11','U',null
                )                                     -- acconto o saldo
         ,upper(rtrim(substr(wkta.dati,279,18)))      -- id. operazione
         ,decode(substr(wkta.dati,79,4)
             ,'3944',substr(wkta.dati,84,2)
             ,'3920',substr(wkta.dati,84,2)             
             ,'3950',substr(wkta.dati,84,2)
             ,'365E',substr(wkta.dati,84,2)
             ,'368E',substr(wkta.dati,84,2)
             ,'TEFA',substr(wkta.dati,84,2)
             ,'3955',max_rata.rata
             ,'371E',max_rata.rata
             ,''
             )  -- rata
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
      ,'VERSAMENTO IMPORTATO DA MODELLO F24'             descrizione
      ,max(decode(substr(wkta.dati,44,1)
                 ,'B','Banca - ABI '||substr(wkta.dati,39,5)||' CAB '||substr(wkta.dati,45,5)
                 ,'C','Concessionario - Codice '||substr(wkta.dati,39,5)
                 ,'P','Poste - Codice '||substr(wkta.dati,39,5)
                 ,'I','Internet'
                     ,null
                 )
          )                                               ufficio_pt
      ,to_date(substr(wkta.dati,67,8),'yyyymmdd')         data_pagamento
      ,sum((to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100)
                                                          importo_versato
      ,to_number(null)                                    importo
      ,to_number(null)                                    maggiorazione_tares
      ,to_number(null)                                    addizionale_pro
      ,to_char(null)                                      rateazione
      ,9                                                  fonte
      ,'F24'                                              utente
      ,trunc(sysdate)                                     data_variazione
      ,max(to_date(substr(wkta.dati,3,8),'yyyymmdd'))     data_reg
      ,max(decode(substr(wkta.dati,79,4)
                 ,'3944',to_number(substr(wkta.dati,130,3))
                 ,'3920',to_number(substr(wkta.dati,130,3))                 
                 ,'3950',to_number(substr(wkta.dati,130,3))
                 ,'365E',to_number(substr(wkta.dati,130,3))
                 ,'368E',to_number(substr(wkta.dati,130,3))
                 ,0
                 )
          )                                               fabbricati
      ,'S'                                                tipo_messaggio
  from wrk_tras_anci         wkta
      ,contribuenti          cont
      ,soggetti              sogg
      ,(select rtrim(substr(wkta.dati,50,16))             cod_fiscale
              ,to_number(substr(wkta.dati,88,4))          anno_rif
              ,to_date(substr(wkta.dati,67,8),'yyyymmdd') data_pagamento
              ,upper(rtrim(substr(wkta.dati,279,18)))     id_operazione
              ,max(decode(substr(wkta.dati,79,4)
                         ,'3944',substr(wkta.dati,84,2)
                         ,'3920',substr(wkta.dati,84,2)                         
                         ,'3950',substr(wkta.dati,84,2)
                         ,'365E',substr(wkta.dati,84,2)
                         ,'368E',substr(wkta.dati,84,2)
                         ,'TEFA',substr(wkta.dati,84,2)
                         ,''
                         )) rata
          from wrk_tras_anci         wkta
         where wkta.anno                = 2
           and substr(wkta.dati,79,4) in ('3945','3946','3951','3952','366E',
                                          '367E','369E','370E','372E','373E',
                                          '3956','3957','TEFN','TEFZ', '3921', '3922')    -- si prendono solo i codici tributo per sanzioni e interessi della TARES.
           and to_number(substr(wkta.dati,126,1))  = 1    -- solo versamenti su ravvedimenti
           and substr(wkta.dati,260,1) in ('A','T')       -- TARSU/TARES/TARI il tracciato riportava T, ma nel file c è A
           and substr(wkta.dati,1,2) = 'G1'               -- Si trattano solo i versamenti
         group by  rtrim(substr(wkta.dati,50,16))         -- cod_fiscale
              ,to_number(substr(wkta.dati,88,4))          -- anno_rif
              ,to_date(substr(wkta.dati,67,8),'yyyymmdd') -- data_pagamento
              ,upper(rtrim(substr(wkta.dati,279,18)))     -- id_operazione
        ) max_rata
 where cont.cod_fiscale     (+) = rtrim(substr(wkta.dati,50,16))
   and sogg.ni              (+) = cont.ni
   and wkta.anno                = 2
   and substr(wkta.dati,79,4) in ('3945','3946','3951','3952','366E','367E',
                                  '369E','370E','372E','373E','3956','3957',
                                  'TEFN','TEFZ', '3921', '3922')   -- si prendono solo i codici tributo per sanzioni e interessi della TARES.
   and to_number(substr(wkta.dati,126,1))  = 1  -- solo versamenti su ravvedimenti
   and substr(wkta.dati,260,1) in ('A','T')     -- TARSU/TARES/TARI il tracciato riportava T, ma nel file c è A
   and rtrim(substr(wkta.dati,50,16)) = max_rata.cod_fiscale
   and to_number(substr(wkta.dati,88,4)) = max_rata.anno_rif
   and to_date(substr(wkta.dati,67,8),'yyyymmdd') = max_rata.data_pagamento
   and nvl(upper(rtrim(substr(wkta.dati,279,18))),'*') = nvl(max_rata.id_operazione,'*')
   and substr(wkta.dati,1,2) = 'G1'                   -- Si trattano solo i versamenti
 group by rtrim(substr(wkta.dati,50,16))              -- cod fiscale
         ,to_number(substr(wkta.dati,88,4))           -- anno rif
         ,to_date(substr(wkta.dati,67,8),'yyyymmdd')  -- data_pagamento
         ,decode(substr(wkta.dati,128,2)
                ,'00','U','01','S','10','A','11','U',null
                )                                     -- acconto o saldo
         ,upper(rtrim(substr(wkta.dati,279,18)))      -- id. operazione
         ,decode(substr(wkta.dati,79,4)
             ,'3944',substr(wkta.dati,84,2)
             ,'3920',substr(wkta.dati,84,2)             
             ,'3950',substr(wkta.dati,84,2)
             ,'365E',substr(wkta.dati,84,2)
             ,'368E',substr(wkta.dati,84,2)
             ,'TEFA',substr(wkta.dati,84,2)
             ,'3955',max_rata.rata
             ,'371E',max_rata.rata
             ,''
             )  -- rata
 order by 1
;
------------------------------------
-- Funzione F_CATA_MAGG_TARES
------------------------------------
--
-- (VD - 16/07/2018): si seleziona da CARICHI_TARSU la percentuale
--                    di maggiorazione TARES per verificare se e'
--                    prevista per l'anno
function F_CATA_MAGG_TARES
( p_anno                      number
) return number
is
begin
  begin
    select maggiorazione_tares
      into w_magg_tares
      from carichi_tarsu
     where anno = p_anno;
  exception
    when others then
      w_magg_tares := to_number(null);
  end;
--
  return w_magg_tares;
--
end;
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
---------------------------------------------------------------
-- Trattamento versamenti con errori da tabella WRK_VERSAMENTI
---------------------------------------------------------------
   FOR rec_errati IN sel_errati
   LOOP
      if rec_errati.cod_fiscale_cont is null then
         w_cod_fiscale := f_crea_contribuente(rec_errati.cod_fiscale,w_errore);
         if w_cod_fiscale is null then
            if w_errore is not null then
               update wrk_versamenti wkve
                  set note = substr(decode(note,'','',note||' - ')||w_errore,1,2000)
                where wkve.progressivo  = rec_errati.progressivo;
            end if;
            goto fine_tratta_errati;
         end if;
      else
         w_cod_fiscale := rec_errati.cod_fiscale_cont;
      end if;
      --
      w_pratica := F_F24_PRATICA(w_cod_fiscale,rec_errati.id_operazione,rec_errati.data_pagamento,w_tipo_tributo);
      if nvl(w_pratica,0) < 0 then
         w_pratica := to_number(null);
         BEGIN
            select count(*)
              into w_conta
              from pratiche_tributo prtr
             where prtr.cod_fiscale            = w_cod_fiscale
               and prtr.anno                   = rec_errati.anno
               and prtr.tipo_tributo           = w_tipo_tributo
               and prtr.tipo_pratica           = 'V'
                 ;
         END;
         if w_conta = 0  and rec_errati.sanzione_ravvedimento is not null then
            if rec_errati.sanzione_ravvedimento = 'N' then
               w_flag_infrazione := NULL;
            else
               w_flag_infrazione := rec_errati.sanzione_ravvedimento;
            end if;
            --CREA_RAVVEDIMENTO(rec_errati.cod_fiscale
            --                 ,rec_errati.anno
            --                 ,rec_errati.data_pagamento
            --                 ,rec_errati.tipo_versamento
            --                 ,w_flag_infrazione
            --                 ,'TR4'
            --                 ,w_pratica
            --                 );
            if w_pratica is null then
               w_conta := 0;
            else
               w_conta := 1;
            end if;
         end if;
         BEGIN
            select count(*)
              into w_conta_importo_esatto
              from pratiche_tributo prtr
             where prtr.cod_fiscale            = w_cod_fiscale
               and prtr.anno                   = rec_errati.anno
               and prtr.tipo_tributo           = w_tipo_tributo
               and prtr.tipo_pratica           = 'V'
               and (   prtr.importo_totale          = rec_errati.importo_versato
                    or round(prtr.importo_totale,0) = rec_errati.importo_versato
                   )
                 ;
         END;
         if w_conta = 0 then
            update wrk_versamenti wkve
               set wkve.cognome_nome = rec_errati.cognome_nome
                  ,wkve.causale      = '50150'
                  ,wkve.note         = decode(rec_errati.tipo_messaggio,'I','Imposta - '
                                                                       ,'S','Sanzioni e Interessi - '
                                                                       ,'')||
                                             'Versamento su Ravvedimento - Pratica di Ravvedimento non Presente'
             where wkve.progressivo  = rec_errati.progressivo
                 ;
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
               begin
                  select prtr.pratica
                    into w_pratica
                    from pratiche_tributo prtr
                   where prtr.cod_fiscale            = w_cod_fiscale
                     and prtr.anno                   = rec_errati.anno
                     and prtr.tipo_tributo           = w_tipo_tributo
                     and prtr.TIPO_PRATICA           = 'V'
                       ;
               exception
                 when others then
                   w_pratica := to_number(null);
               end;
            else
               BEGIN
                  select prtr.pratica
                    into w_pratica
                    from pratiche_tributo prtr
                   where prtr.cod_fiscale                 = w_cod_fiscale
                     and prtr.anno                        = rec_errati.anno
                     and prtr.tipo_tributo                = w_tipo_tributo
                     and prtr.TIPO_PRATICA                = 'V'
                     and (   prtr.importo_totale          = rec_errati.importo_versato
                          or round(prtr.importo_totale,0) = rec_errati.importo_versato
                         )
                       ;
               exception
                 when others then
                   w_pratica := to_number(null);
               END;
            end if;
         end if;
      end if;
      if w_pratica is not null then
         BEGIN
            select count(*)
              into w_conta
              from versamenti vers
             where vers.cod_fiscale            = w_cod_fiscale
               and vers.anno                   = rec_errati.anno
               and vers.tipo_tributo           = w_tipo_tributo
               and vers.tipo_versamento        = rec_errati.tipo_versamento
               and vers.descrizione            = 'VERSAMENTO IMPORTATO DA MODELLO F24'
               and vers.ufficio_pt             = rec_errati.ufficio_pt
               and vers.data_pagamento         = rec_errati.data_pagamento
               and vers.importo_versato        = rec_errati.importo_versato
               and nvl(vers.rata,999)          = nvl(rec_errati.rata,999)
               and nvl(vers.pratica,-1)        = nvl(w_pratica,-1)
            -- modifica: ora la fonte viene richiesta come parametro per i versamenti da cnc
            --   and vers.fonte                  = 9
            ;
         END;
         --dbms_output.put_line('w_conta_vers: '||w_conta);
         if w_conta > 0 then
            update wrk_versamenti wkve
               set wkve.cognome_nome = rec_errati.cognome_nome
                  ,wkve.causale      = '50100'
                  ,wkve.note         = decode(rec_errati.tipo_messaggio,'I','Imposta - '
                                                                       ,'S','Sanzioni e Interessi - '
                                                                       ,'')||
                                             'Versamento su Ravvedimento gia` Presente in data '||
                                       to_char(rec_errati.data_pagamento,'dd/mm/yyyy')
             where wkve.progressivo  = rec_errati.progressivo
            ;
         else
            --
            -- Si controlla la validità del numero rata per l'inserimento
            -- in tabella VERSAMENTI
            --
            if rec_errati.id_operazione like 'RUOL%' then
               w_ruolo := f_f24_ruolo(rec_errati.id_operazione);
               if w_ruolo is not null and
                  afc.is_numeric(substr(rec_errati.id_operazione,9,2)) = 1 then
                  w_rata := to_number(substr(rec_errati.id_operazione,9,2));
               else
                  w_rata := nvl(rec_errati.rata,0);
               end if;
            else
               w_ruolo := to_number(null);
               w_rata  := 0;
               if w_pratica is not null and
                  afc.is_numeric(substr(rec_errati.id_operazione,9,2)) = 1 then
                  w_rata := to_number(substr(rec_errati.id_operazione,9,2));
               end if;
               if w_rata = 0 then
                  w_rata := nvl(rec_errati.rata,0);
               end if;
            end if;
            --
            -- (VD - 16/07/2018): modificato test validita' rata
            --
            if w_pratica is null and w_rata not in (0,1,2,3,4,11,12,22) then
               w_rata := 1;
            end if;
            --
            if w_pratica is not null and w_rata not between 0 and 36 then
               w_rata := 36;
            end if;
            --
            -- (VD - 16/07/2018): si verifica se per l'anno del versamento
            --                    e' prevista la maggiorazione TARES
            w_magg_tares := F_CATA_MAGG_TARES(rec_errati.anno);
            /*BEGIN -- Assegnazione Numero Progressivo
               select nvl(max(vers.sequenza),0)+1
                 into w_sequenza
                 from versamenti vers
                where vers.cod_fiscale     = w_cod_fiscale
                  and vers.anno            = rec_errati.anno
                  and vers.tipo_tributo    = w_tipo_tributo
                    ;
            END; */
            w_sequenza := to_number(null);
            VERSAMENTI_NR ( w_cod_fiscale, rec_errati.anno
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
                    ,utente
                    ,data_variazione
                    ,data_reg
                    ,fabbricati
                    ,rata
                    ,ruolo
                    ,addizionale_pro
                    ,maggiorazione_tares
                    ,note
                    ,documento_id
                    )
              select w_cod_fiscale
                    ,rec_errati.anno
                    ,w_pratica
                    ,w_tipo_tributo
                    ,w_sequenza
                    ,rec_errati.tipo_versamento
                    ,'VERSAMENTO IMPORTATO DA MODELLO F24'
                    ,rec_errati.ufficio_pt
                    ,rec_errati.data_pagamento
                    ,rec_errati.importo_versato
                    ,9
                    ,'F24'
                    ,trunc(sysdate)
                    ,rec_errati.data_reg
                    ,rec_errati.fabbricati
                    ,w_rata
                    ,w_ruolo
                    ,case
                       when rec_errati.anno < 2021 then to_number(null)
                       else rec_errati.addizionale_pro
                     end
                    --,decode(w_magg_tares,null,to_number(null),rec_errati.maggiorazione_tares)
                    ,decode(w_magg_tares,null,to_number(ltrim(rec_errati.maggiorazione_tares,'0')),rec_errati.maggiorazione_tares)
                    -- (VD - 11/01/2021): aggiunto campo note_versamento per
                    --                    composizione note
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
      << fine_tratta_errati >>
      null;
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
                   cognome_nome,causale,disposizione,data_variazione,
                   note,
                   tipo_versamento,ufficio_pt,data_pagamento,
                   data_reg,fabbricati,importo_versato
                  ,rata
                  ,addizionale_pro
                  ,maggiorazione_tares
                  ,identificativo_operazione
                  ,documento_id
                  )
            select w_progressivo,w_tipo_tributo,'F24',rec_vers.anno,null,rec_vers.cod_fiscale_vers,
                   rec_vers.cognome_nome,'50109',w_progressivo,sysdate,
                   decode(rec_vers.tipo_messaggio,'I','Imposta - ',
                                                  'S','Sanzioni e interessi - ')||
                         'Versamento su Ravvedimento Contribuente ('||rec_vers.cod_fiscale_vers||') sconosciuto',
                   rec_vers.tipo_versamento,rec_vers.ufficio_pt,rec_vers.data_pagamento,
                   rec_vers.data_reg,rec_vers.fabbricati,rec_vers.importo_versato
                  ,rec_vers.rateazione
                  ,rec_vers.addizionale_pro
                  ,rec_vers.maggiorazione_tares
                  ,rec_vers.id_operazione
                  ,a_documento_id
                  from dual;
         end if;
      else
         w_cod_fiscale := rec_vers.cod_fiscale;
      end if;
      -- (VD - 24/06/2021): se il contribuente esisteva gia' oppure e' appena
      --                    stato inserito, si prosegue il trattamento
      if w_cod_fiscale is not null then
         --w_pratica := F_F24_PRATICA(rec_vers.cod_fiscale,rec_vers.id_operazione,rec_vers.data_pagamento,w_tipo_tributo);
         w_conta   := 0;
         w_pratica := F_F24_PRATICA(w_cod_fiscale,rec_vers.id_operazione,rec_vers.data_pagamento,w_tipo_tributo);
         dbms_output.put_line('Cod.fiscale: '||w_cod_fiscale||', pratica: '||w_pratica);
         if nvl(w_pratica,-1) < 0 then
            if nvl(w_pratica,-1) = -1 then
               w_pratica := to_number(null);
               BEGIN
                  select count(*)
                    into w_conta
                    from pratiche_tributo prtr
                   where prtr.cod_fiscale            = w_cod_fiscale --rec_vers.cod_fiscale
                     and prtr.anno                   = rec_vers.anno
                     and prtr.tipo_tributo           = rec_vers.tipo_tributo
                     and prtr.tipo_pratica           = 'V'
                       ;
               END;
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
                       ;
               END;
            end if;
         dbms_output.put_line('w_conta: '||w_conta||', pratica: '||w_pratica);
            if w_conta = 0 or nvl(w_pratica,0) < 0 then
               w_progressivo := F_SELEZIONA_PROGRESSIVO;
               insert into wrk_versamenti
                     (progressivo,tipo_tributo,tipo_incasso,anno,ruolo,cod_fiscale,
                      cognome_nome,causale,disposizione,data_variazione,
                      note,
                      tipo_versamento,ufficio_pt,data_pagamento,
                      data_reg,fabbricati,importo_versato
                     ,rata
                     ,addizionale_pro
                     ,maggiorazione_tares
                     ,identificativo_operazione
                     ,documento_id
                     )
               select w_progressivo,w_tipo_tributo,'F24',rec_vers.anno,null,rec_vers.cod_fiscale_vers,
                      rec_vers.cognome_nome,
                      decode(w_pratica,-2,'50351',
                                       -3,'50352','50150'),
                      w_progressivo,sysdate,
                      decode(rec_vers.tipo_messaggio,'I','Imposta - ',
                                                     'S','Sanzioni e interessi - ')||
                      decode(w_pratica,-2,'Data Pagamento precedente a Data Notifica Pratica',
                            -3,'Pratica non notificata'
                            ,'Versamento su Ravvedimento - Pratica di Ravvedimento non Presente'),
                      rec_vers.tipo_versamento,rec_vers.ufficio_pt,rec_vers.data_pagamento,
                      rec_vers.data_reg,rec_vers.fabbricati,rec_vers.importo_versato
                     ,rec_vers.rateazione
                     ,rec_vers.addizionale_pro
                     ,rec_vers.maggiorazione_tares
                     ,rec_vers.id_operazione
                     ,a_documento_id
                 from dual;
               w_pratica := to_number(null);
            elsif w_conta > 1 and w_conta_importo_esatto <> 1 then
               w_progressivo := F_SELEZIONA_PROGRESSIVO;
               insert into wrk_versamenti
                     (progressivo,tipo_tributo,tipo_incasso,anno,ruolo,cod_fiscale,
                      cognome_nome,causale,disposizione,data_variazione,
                      note,
                      tipo_versamento,ufficio_pt,data_pagamento,
                      data_reg,fabbricati,importo_versato
                     ,rata
                     ,addizionale_pro
                     ,maggiorazione_tares
                     ,identificativo_operazione
                     ,documento_id
                     )
               select w_progressivo,w_tipo_tributo,'F24',rec_vers.anno,null,rec_vers.cod_fiscale_vers,
                      rec_vers.cognome_nome,'50180',w_progressivo,sysdate,
                      decode(rec_vers.tipo_messaggio,'I','Imposta - ',
                                                     'S','Sanzioni e interessi - ')||
                            'Versamento su Ravvedimento - Più di una Pratica di Ravvedimento Presente',
                      rec_vers.tipo_versamento,rec_vers.ufficio_pt,rec_vers.data_pagamento,
                      rec_vers.data_reg,rec_vers.fabbricati,rec_vers.importo_versato
                     ,rec_vers.rateazione
                     ,rec_vers.addizionale_pro
                     ,rec_vers.maggiorazione_tares
                     ,rec_vers.id_operazione
                     ,a_documento_id
                 from dual;
            else
               if w_conta = 1 then
                  begin
                     select prtr.pratica
                       into w_pratica
                       from pratiche_tributo prtr
                      where prtr.cod_fiscale            = w_cod_fiscale --rec_vers.cod_fiscale
                        and prtr.anno                   = rec_vers.anno
                        and prtr.tipo_tributo           = rec_vers.tipo_tributo
                        and prtr.tipo_pratica           = 'V'
                          ;
                  exception
                    when others then
                      w_pratica := to_number(null);
                  end;
               else
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
                          ;
                  exception
                    when others then
                      w_pratica := to_number(null);
                  END;
               end if;
            end if;
         end if;
         if w_pratica is not null then
            BEGIN
               select count(*)
                 into w_conta
                 from versamenti vers
                where vers.cod_fiscale            = w_cod_fiscale --rec_vers.cod_fiscale
                  and vers.anno                   = rec_vers.anno
                  and vers.tipo_tributo           = rec_vers.tipo_tributo
                  and vers.tipo_versamento        = rec_vers.tipo_versamento
                  and vers.descrizione            = rec_vers.descrizione
                  and vers.ufficio_pt             = rec_vers.ufficio_pt
                  and vers.data_pagamento         = rec_vers.data_pagamento
                  and vers.importo_versato        = rec_vers.importo_versato
                  and nvl(vers.rata,999)          = nvl(rec_vers.rateazione,999)
                  and nvl(vers.pratica,-1)        = nvl(w_pratica,-1)
                -- modifica: ora la fonte viene richiesta come parametro per i versamenti da cnc
                --  and vers.fonte                  = rec_vers.fonte
               ;
            END;
            if w_conta > 0 then
               w_progressivo := F_SELEZIONA_PROGRESSIVO;
               insert into wrk_versamenti
                     (progressivo,tipo_tributo,tipo_incasso,anno,ruolo,cod_fiscale,
                      cognome_nome,causale,disposizione,data_variazione,
                      note,
                      tipo_versamento,ufficio_pt,data_pagamento,
                      data_reg,fabbricati,importo_versato
                     ,rata
                     ,addizionale_pro
                     ,maggiorazione_tares
                     ,identificativo_operazione
                     ,documento_id
                     )
                select w_progressivo,w_tipo_tributo,'F24',rec_vers.anno,null,rec_vers.cod_fiscale_vers,
                       rec_vers.cognome_nome,'50100',w_progressivo,sysdate,
                       decode(rec_vers.tipo_messaggio,'I','Imposta - ',
                                                      'S','Sanzioni e interessi - ')||
                             'Versamento su Ravvedimento gia` Presente in data '||to_char(rec_vers.data_pagamento,'dd/mm/yyyy'),
                       rec_vers.tipo_versamento,rec_vers.ufficio_pt,rec_vers.data_pagamento,
                       rec_vers.data_reg,rec_vers.fabbricati,rec_vers.importo_versato
                      ,rec_vers.rateazione
                      ,rec_vers.addizionale_pro
                      ,rec_vers.maggiorazione_tares
                      ,rec_vers.id_operazione
                      ,a_documento_id
                  from dual;
            else
               --
               -- Si controlla la validità del numero rata per l'inserimento
               -- in tabella VERSAMENTI; su WRK_VERSAMENTI invece rimane
               -- la rata originale
               --
               if rec_vers.id_operazione like 'RUOL%' then
                  w_ruolo := f_f24_ruolo(rec_vers.id_operazione);
                  if w_ruolo is not null and
                     afc.is_numeric(substr(rec_vers.id_operazione,9,2)) = 1 then
                     w_rata := to_number(substr(rec_vers.id_operazione,9,2));
                  else
                     w_rata := nvl(rec_vers.rateazione,0);
                  end if;
               else
                  w_ruolo := to_number(null);
                  w_rata  := 0;
                  if w_pratica is not null and
                     afc.is_numeric(substr(rec_vers.id_operazione,9,2)) = 1 then
                     w_rata := to_number(substr(rec_vers.id_operazione,9,2));
                  end if;
                  if w_rata = 0 then
                     w_rata := nvl(rec_vers.rateazione,0);
                  end if;
               end if;
               --
               if w_pratica is null and w_rata not in (0,1,2,3,4,11,12,22) then
                  w_rata := 1;
               end if;
               --
               if w_pratica is not null and w_rata not between 0 and 36 then
                  w_rata := 36;
               end if;
               --
               -- (VD - 16/07/2018): si verifica se per l'anno del versamento
               --                    e' prevista la maggiorazione TARES
               w_magg_tares := F_CATA_MAGG_TARES(rec_vers.anno);
               --
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
                        ,pratica
                        ,tipo_tributo
                        ,sequenza
                        ,tipo_versamento
                        ,descrizione
                        ,ufficio_pt
                        ,data_pagamento
                        ,importo_versato
                        ,fonte
                        ,utente
                        ,data_variazione
                        ,data_reg
                        ,fabbricati
                        ,rata
                        ,ruolo
                        ,addizionale_pro
                        ,maggiorazione_tares
                        ,note
                        ,documento_id
                        )
                  select w_cod_fiscale --rec_vers.cod_fiscale
                        ,rec_vers.anno
                        ,w_pratica
                        ,rec_vers.tipo_tributo
                        ,w_sequenza
                        ,rec_vers.tipo_versamento
                        ,rec_vers.descrizione
                        ,rec_vers.ufficio_pt
                        ,rec_vers.data_pagamento
                        ,rec_vers.importo_versato
                        ,rec_vers.fonte
                        ,rec_vers.utente
                        ,rec_vers.data_variazione
                        ,rec_vers.data_reg
                        ,rec_vers.fabbricati
                        ,w_rata
                        ,w_ruolo
                        ,case
                           when rec_vers.anno < 2021 then to_number(null)
                           else rec_vers.addizionale_pro
                         end
--                        ,decode(w_magg_tares,null,to_number(null),rec_vers.maggiorazione_tares)
                        ,decode(w_magg_tares,null,to_number(ltrim(rec_vers.maggiorazione_tares,'0')),rec_vers.maggiorazione_tares)
                        ,f_f24_note_versamento(rec_vers.id_operazione
                                              ,w_pratica
                                              ,rec_vers.tipo_messaggio
                                              ,a_documento_id
                                              ,w_tipo_tributo
                                              )
                        ,a_documento_id
                    from dual
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
      end if;
      BEGIN
         delete wrk_tras_anci wkta
          where rtrim(substr(wkta.dati,50,16))      = rec_vers.cod_fiscale_vers
            and to_number(substr(wkta.dati,88,4))   = rec_vers.anno
            and decode(substr(wkta.dati,128,2),'00','U','01','S','10','A','11','U',null)
                                                    = rec_vers.tipo_versamento
            and wkta.anno                           = 2
            and ((rec_vers.tipo_messaggio = 'I' and
                  substr(wkta.dati,79,4) in ('3944','3955','3950','365E','368E'
                                            ,'371E','TEFA', '3920')) or
                 (rec_vers.tipo_messaggio = 'S' and
                  substr(wkta.dati,79,4) in ('3945','3946','3951','3952','366E'
                                            ,'367E','369E','370E','372E','373E'
                                            ,'3956','3957','TEFN','TEFZ', '3921', '3922')))
            and to_number(substr(wkta.dati,126,1))  = 1           -- solo versamenti su ravvedimenti
            and substr(wkta.dati,260,1) in ('A','T')              -- TARSU/TARES/TARI il tracciato riportava T, ma nel file c è A
            and substr(wkta.dati,1,2) = 'G1'                      -- si trattano solo i versamenti
            --and to_date(substr(wkta.dati,67,8),'yyyymmdd') = rec_vers.data_pagamento
            and substr(wkta.dati,67,8) = to_char(rec_vers.data_pagamento,'yyyymmdd')
            and nvl(upper(rtrim(substr(wkta.dati,279,18))),'*') = nvl(rec_vers.id_operazione,'*')
            and nvl(decode(substr(wkta.dati,79,4)
                          ,'3944',substr(wkta.dati,84,2)
                          ,'3920',substr(wkta.dati,84,2)                          
                          ,'3950',substr(wkta.dati,84,2)
                          ,'365E',substr(wkta.dati,84,2)
                          ,'368E',substr(wkta.dati,84,2)
                          ,'TEFA',substr(wkta.dati,84,2)
                          ,'3955',decode(rec_vers.maggiorazione_tares,null,'',rec_vers.rateazione)
                          ,'371E',decode(rec_vers.maggiorazione_tares,null,'',rec_vers.rateazione)
                          ,''
                          ),999)  = nvl(rec_vers.rateazione,999)
         ;
      EXCEPTION
         WHEN others THEN
            w_errore := 'Errore in eliminazione wrk_tras_anci ravv'||
                        ' progressivo '||to_char(rec_vers.progressivo)||
                        ' cf '||to_char(rec_vers.cod_fiscale_vers)||
                        ' anno '||to_char(rec_vers.anno)||
                        ' ('||sqlerrm||')';
            RAISE errore;
      END;
   END LOOP;
EXCEPTION
   WHEN errore THEN
      RAISE_APPLICATION_ERROR(-20999,w_errore);
END;
/* End Procedure: CARICA_VERS_RAVV_TARES_F24 */
/
