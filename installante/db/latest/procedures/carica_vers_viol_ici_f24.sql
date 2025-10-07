--liquibase formatted sql 
--changeset abrandolini:20250326_152423_carica_vers_viol_ici_f24 stripComments:false runOnChange:true 
 
create or replace procedure CARICA_VERS_VIOL_ICI_F24
/*************************************************************************
 Versione  Data         Autore    Descrizione
 011       16/03/2023   VM        #55165 - Aggiunto parametro a_cod_fiscale.
                                  Aggiunto filtro cod_fiscale su popolamento cursori.
 010       14/03/2023   VM        #60197 - Aggiunto il parametro a_log_documento.
                                  Dopo l'inserimento del versamento viene lanciato
                                  controllo per popolare il messaggio se presenti
                                  ruoli coattivi su sanzioni pratica.
 9         11/01/2021   VD        Gestione nuovo campo note_versamento
                                  della tabella WRK_VERSAMENTI: il contenuto
                                  viene copiato nel campo note della tabella
                                  VERSAMENTI.
 8         26/10/2018   VD        Gestione importi sanzioni e interessi
 7         25/09/2018   VD        Modifiche per gestione versamenti su
                                  pratiche rateizzate
 6         16/05/2017   VD        Aggiunto raggruppamento per data versamento
                                  per gestire versamenti dello stesso tipo
                                  effettuati in date diverse
 5         15/06/2016   VD        Aggiunto controllo tipo record in query
                                  principale: si trattano solo i record G1 -
                                  versamenti
 4         04/12/2015   VD        Aggiunta upper in selezione identificativo
                                  operazione
 3         16/01/2015   VD        Aggiunta gestione documento_id e nome_documento
 2         18/12/2014   VD        Aggiunte nuove causali errore:
                                  50531 - data pagamento < data notifica
                                  50532 - data notifica nulla e data
                                  pagamento nulla
 1         11/12/2014   VD        Aggiunta gestione nuovo campo
                                  identificativo_operazione
                                  In presenza di identificativo
                                  operazione il versamento viene
                                  caricato nella tabella versamenti
 Causali errore:        50200     Versamento con codici violazione senza Ravvedimento
                        50300     Versamento già presente
                        50309     Contribuente non codificato
                        50350     Pratica di ravvedimento non presente
                        50351     Data pagamento < data notifica
                        50352     Data notifica nulla e data pagamento
                                  non nulla
                        50360     Pratica rateizzata: versamento antecedente
                                  alla data di rateazione
                        50361     Pratica rateizzata: rata errata
                        50362     Pratica rateizzata: rata gia' versata
*************************************************************************/
( a_documento_id            documenti_caricati.documento_id%type default null,
  a_cod_fiscale             in                                   varchar2 default '%',
  a_log_documento           in out                               varchar2 )
IS
w_tipo_tributo       varchar2(5) := 'ICI';
w_progressivo        number;
w_sequenza           number;
w_conta              number;
w_errore             varchar2(2000);
w_pratica            number;
w_anno_pratica       number;
w_rata_pratica       number;
errore               exception;
--
-- Esiste una fase iniziale di bonifica di eventuali anomalie presenti nella
-- tabella intermedia wrk_versamenti. Si tenta di ri-inserire il versamento;
-- se questo va a buon fine, allora si elimina la tabella wrk, altrimenti si
-- lascia la registrazione come in precedenza. Al massimo varia il motivo di
-- errore nel qual caso si cambiano la causale e le note.
-- (VD - 12/12/2014): Aggiunta selezione id. operazione
-- (VD - 04/12/2015): Aggiunta upper in selezione id. operazione
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
   and wkve.causale         in ('50200','50300','50309','50350','50351','50352',
                                '50360','50361','50362')
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
-- (VD - 11/12/2014): Modificato per gestire il nuovo campo identificativo
--                    operazione anche come raggruppamento
-- (VD - 04/12/2015): Aggiunta upper in selezione id. operazione
-- (VD - 15/06/2016): Aggiunto test su tipo record G1 - versamento
-- (VD - 16/05/2017): Aggiunto raggruppamento per data pagamento
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
                 ,'3906',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,'3923',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,'357E',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,0
                 )
          )                                               importo_interessi
      ,sum(decode(substr(wkta.dati,79,4)
                 ,'3907',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,'3924',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,'358E',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,0
                 )
          )                                               importo_sanzioni
      ,0                                                  ab_principale
      ,0                                                  rurali
      ,0                                                  terreni_agricoli
      ,0                                                  terreni_agricoli_comune
      ,0                                                  terreni_agricoli_stato
      ,0                                                  aree_fabbricabili
      ,0                                                  aree_fabbricabili_comune
      ,0                                                  aree_fabbricabili_stato
      ,0                                                  altri_fabbricati
      ,0                                                  altri_fabbricati_comune
      ,0                                                  altri_fabbricati_stato
      ,substr(wkta.dati,84,4)                             rateazione
      ,to_number(null)                                    num_fabbricati_ab
      ,to_number(null)                                    num_fabbricati_rurali
      ,to_number(null)                                    num_fabbricati_terreni
      ,to_number(null)                                    num_fabbricati_aree
      ,to_number(null)                                    num_fabbricati_altri
      ,9                                                  fonte
      ,'F24'                                              utente
      ,trunc(sysdate)                                     data_variazione
      ,max(to_date(substr(wkta.dati,3,8),'yyyymmdd'))     data_reg
      ,sum(to_number(substr(wkta.dati,134,15)) / 100)     detrazione
      ,sum(to_number(substr(wkta.dati,130,3)))            fabbricati
      ,0                                                  fabbricati_d
      ,0                                                  fabbricati_d_erariale
      ,0                                                  fabbricati_d_comune
      ,to_number(null)                                    num_fabbricati_d
      ,0                                                  rurali_erariale
      ,0                                                  rurali_comune
  from wrk_tras_anci         wkta
      ,contribuenti          cont
      ,soggetti              sogg
 where cont.cod_fiscale     (+) = rtrim(substr(wkta.dati,50,16))
   and sogg.ni              (+) = cont.ni
   and wkta.anno                = 2
   and substr(wkta.dati,79,4) in ('3906','3907','3923','3924','357E','358E')  -- solo i versamenti su violazioni
   and to_number(substr(wkta.dati,126,1))  <> 1                               -- si escludono i versamenti su ravvedimenti
   and substr(wkta.dati,260,1) = 'I'                                          -- ICI/IMU
   and substr(wkta.dati,1,2)   = 'G1'                                         -- Si trattano solo i versamenti
 group by rtrim(substr(wkta.dati,50,16))                                      -- codice fiscale di chi ha effettuato il versamento
         ,to_number(substr(wkta.dati,88,4))                                   -- anno
         ,decode(substr(wkta.dati,128,2)
                ,'00','U','01','S','10','A','11','U',null                     -- Acconto/Saldo
                )
      ,upper(rtrim(substr(wkta.dati,279,18)))                                 -- Id. operazione
      ,to_date(substr(wkta.dati,67,8),'yyyymmdd')                             -- data_pagamento
      ,substr(wkta.dati,84,4)                                                 -- rateazione
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
---------------------------
--  INIZIO ELABORAZIONE  --
---------------------------
BEGIN
   FOR rec_errati IN sel_errati
   LOOP
      --
      -- Se il codice fiscale del contribuente è nullo, significa che il contribuente
      -- non esiste in tabella CONTRIBUENTI. Si aggiornano il codice (50309) e il
      -- messaggio di errore
      --
      if rec_errati.cod_fiscale_cont is null then
         update wrk_versamenti wkve
            set wkve.cognome_nome = rec_errati.cognome_nome
               ,wkve.causale      = '50309'
               ,wkve.note         = decode(rec_errati.tipo_messaggio,'I','Imposta - '
                                                                    ,'S','Sanzioni e Interessi - '
                                                                        ,'')||
                                    'Versamento con codici violazione: Contribuente ('||rec_errati.cod_fiscale||') sconosciuto'
          where wkve.progressivo  = rec_errati.progressivo
         ;
      else
         w_pratica := F_F24_PRATICA(rec_errati.cod_fiscale,rec_errati.id_operazione,rec_errati.data_pagamento,w_tipo_tributo);
         --
         -- Se il risultato della function è -1, significa che la pratica
         -- non esiste oppure non è congruente con i dati indicati.
         -- Si aggiornano il codice (50350) e il messaggio di errore
         -- Se il risultato della function è null, significa che non è stato
         -- indicato l'identificativo operazione, quindi il versamento viene
         -- gestito come prima (rimane in wrk_versamenti con codice 50200)
         -- (VD - 18/12/2014): aggiunta gestione nuove causali errore.
         --                    50351 - data pagamento < data notifica
         --                    50352 - data notifica nulla e data pagamento non nulla
         --
         if nvl(w_pratica,-1) < 0 then
            update wrk_versamenti wkve
               set wkve.cognome_nome = rec_errati.cognome_nome
                  -- (VD - 25/09/2018): nuova funzione di decodifica errore
                  --,wkve.causale      = decode(w_pratica,null,'50200'
                  --                                     ,-1  ,'50350'
                  --                                     ,-2  ,'50351'
                  --                                          ,'50352')
                  --,wkve.note         = decode(rec_errati.tipo_messaggio,'I','Imposta - '
                  --                                                     ,'S','Sanzioni e Interessi - '
                  --                                                         ,'')||
                  --                     decode(w_pratica,null,'Versamento con codici violazione senza Ravvedimento'
                  --                                     ,-1,  'Versamento con codici violazione: Pratica non presente o incongruente'
                  --                                     ,-2,  'Versamento con codici violazione: Data Pagamento precedente a Data Notifica Pratica'
                  --                                          ,'Versamento con codici violazione: Pratica non Notificata')
                  ,wkve.causale      = decode(w_pratica,null,'50200'
                                                            ,f_f24_causale_errore(w_pratica,'C'))
                  ,wkve.note         = decode(rec_errati.tipo_messaggio,'I','Imposta - '
                                                                       ,'S','Sanzioni e Interessi - '
                                                                           ,'')||
                                       decode(w_pratica,null,'Versamento con codici violazione senza Ravvedimento'
                                                            ,f_f24_causale_errore(w_pratica,'D'))
             where wkve.progressivo  = rec_errati.progressivo
            ;
         else
            --
            -- Arrivati a questo punto, la pratica e' sicuramente presente
            -- nell'archivio pratiche ed è del tipo richiesto. Si estrapola
            -- l'anno per evitare di inserire versamenti con anno diverso
            -- da quello della pratica
            -- (VD - 25/09/2018): gestione pratiche rateizzate.
            --                    Si estrapola anche il numero di rata
            --                    da indicare sul versamento
            --
            w_anno_pratica := to_number(substr(rec_errati.id_operazione,5,4));
            w_rata_pratica := to_number(substr(rec_errati.id_operazione,9,2));
            if w_rata_pratica = 0 then
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
                     and vers.rata         = w_rata_pratica
                     and vers.importo_versato = rec_errati.importo_versato;
               EXCEPTION
                  WHEN others THEN
                       w_errore := 'Errore in conteggio'||
                                   ' di '||rec_errati.cod_fiscale||' progressivo '||
                                   to_char(rec_errati.progressivo)||' ('||sqlerrm||')';
                       RAISE errore;
               END;
            end if;
            --
            -- Se w_conta è > 0, significa che esiste già un versamento uguale a quello che
            -- si vuole caricare.
            -- Si aggiornano il codice (50300) e il messaggio di errore
            --
            if w_conta > 0 then
               begin
                   update wrk_versamenti wkve
                      set wkve.cognome_nome = rec_errati.cognome_nome
                         ,wkve.causale      = decode(w_rata_pratica,0,'50300','50362')
                         ,wkve.note         = decode(rec_errati.tipo_messaggio,'I','Imposta - '
                                                                              ,'S','Sanzioni e Interessi - '
                                                                                  ,'')||
                                              decode(w_rata_pratica,0,'Versamento con codici violazione gia` Presente in data '||
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
               --
               -- Se tutti i controlli vengono superati, si inserisce la riga nella tabella
               -- VERSAMENTI e si elimina la riga da WRK_VERSAMENTI
               BEGIN -- Assegnazione Numero Progressivo
                  select nvl(max(vers.sequenza),0)+1
                    into w_sequenza
                    from versamenti vers
                   where vers.cod_fiscale     = rec_errati.cod_fiscale
                     and vers.anno            = w_anno_pratica   -- rec_errati.anno
                     and vers.tipo_tributo    = w_tipo_tributo
                  ;
               END;
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
                        ,interessi)
                  select rec_errati.cod_fiscale
                        ,w_anno_pratica       -- rec_errati.anno
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
                where wkve.progressivo  = rec_errati.progressivo;
               if a_documento_id = rec_errati.documento_id then
                 --
                 -- (VM - #60197) Lancia procedura per elaborazione messaggio se presenti ruoli coattivi
                 --
                 a_log_documento := F_CTR_VERS_RUOLI_COATTIVI(w_pratica, rec_errati.cod_fiscale, a_log_documento);
               end if;
            end if;
         end if;
      end if;
   END LOOP;
------------------------------------------------------------
-- Trattamento versamenti caricati in tabella WRK_TRAS_ANCI
------------------------------------------------------------
   FOR rec_vers IN sel_vers
   LOOP
      --
      -- Se il codice fiscale del contribuente è nullo, significa che il contribuente
      -- non esiste in tabella CONTRIBUENTI. Si inserisce il versamento in
      -- WRK_VERSAMENTI con il codice (50309) e il messaggio di errore
      --
      if rec_vers.cod_fiscale is null then
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
               ,sanzioni_1
               ,interessi)
         values(w_progressivo,w_tipo_tributo,'F24',rec_vers.anno,null,rec_vers.cod_fiscale_vers,
                rec_vers.cognome_nome,'50309',w_progressivo,sysdate,
                'Sanzioni e Interessi - Versamento con codici violazione Contribuente ('||rec_vers.cod_fiscale_vers||') sconosciuto',
                rec_vers.tipo_versamento,rec_vers.ufficio_pt,rec_vers.data_pagamento,
                rec_vers.ab_principale,rec_vers.terreni_agricoli,
                rec_vers.aree_fabbricabili,rec_vers.altri_fabbricati,
                rec_vers.data_reg,rec_vers.detrazione,rec_vers.fabbricati
               ,rec_vers.importo_versato
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
               ,rec_vers.importo_sanzioni
               ,rec_vers.importo_interessi
               );
      else
         w_pratica := F_F24_PRATICA(rec_vers.cod_fiscale,rec_vers.id_operazione,rec_vers.data_pagamento,w_tipo_tributo);
         --
         -- Se il risultato della function è -1, significa che la pratica
         -- non esiste oppure non è congruente con i dati indicati.
         -- Si inserisce il versamento in WRK_VERSAMENTI con il codice 50350
         -- e il messaggio di errore
         -- Se il risultato della function è null, significa che non è stato
         -- indicato l'identificativo operazione oppure non è nel formato
         -- previsto da TR4, quindi il versamento viene gestito come prima
         -- (rimane in wrk_versamenti con codice 50200)
         -- (VD - 18/12/2014): aggiunta gestione nuove causali errore.
         --                    50351 - data pagamento < data notifica
         --                    50352 - data notifica nulla e data pagamento non nulla
         --
         if nvl(w_pratica,-1) < 0 then
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
                  ,sanzioni_1
                  ,interessi)
            select w_progressivo,w_tipo_tributo,'F24',rec_vers.anno,null,rec_vers.cod_fiscale_vers,
                   rec_vers.cognome_nome,
                   -- (VD - 25/09/2018): nuova funzione di decodifica errore
                   --decode(w_pratica,null,'50200'
                   --                ,-1  ,'50350'
                   --                ,-2  ,'50351'
                   --                     ,'50352'),
                   decode(w_pratica,null,'50200'
                                        ,f_f24_causale_errore(w_pratica,'C')),
                   w_progressivo,sysdate,
                   -- (VD - 25/09/2018): nuova funzione di decodifica errore
                   --'Sanzioni e Interessi - '||
                   --decode(w_pratica,null,'Versamento con codici violazione senza Ravvedimento'
                   --                ,-1  ,'Versamento con codici violazione Pratica non presente o incongruente'
                   --                ,-2  ,'Versamento con codici violazione Data Pagamento precedente a Data Notifica Pratica'
                   --                     ,'Versamento con codici violazione Pratica non Notificata'),
                   'Sanzioni e Interessi - '||
                   decode(w_pratica,null,'Versamento con codici violazione senza Ravvedimento'
                                        ,f_f24_causale_errore(w_pratica,'D')),
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
                  ,rec_vers.importo_sanzioni
                  ,rec_vers.importo_interessi
              from dual;
         else
            --
            -- Arrivati a questo punto, la pratica e' sicuramente presente
            -- nell'archivio pratiche ed è del tipo richiesto. Si estrapola
            -- l'anno per evitare di inserire versamenti con anno diverso
            -- da quello della pratica
            -- (VD - 25/09/2018): gestione pratica rateizzata
            --                    si estrae la rata dall'identificativo
            --                    operazione
            --
            w_anno_pratica := to_number(substr(rec_vers.id_operazione,5,4));
            w_rata_pratica := to_number(substr(rec_vers.id_operazione,9,2));
            if w_rata_pratica = 0 then
               BEGIN
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
               END;
            else
               begin
                  select count(*)
                    into w_conta
                    from versamenti vers
                   where vers.cod_fiscale  = rec_vers.cod_fiscale
                     and vers.anno         = rec_vers.anno
                     and vers.tipo_tributo = rec_vers.tipo_tributo
                     and vers.pratica      = w_pratica
                     and vers.rata         = w_rata_pratica
                     and vers.importo_versato = rec_vers.importo_versato;
               EXCEPTION
                  WHEN others THEN
                       w_errore := 'Errore in conteggio versamenti'||
                                   ' di '||rec_vers.cod_fiscale||' ('||sqlerrm||')';
                       RAISE errore;
               END;
            end if;
            --
            -- Se w_conta è > 0, significa che esiste già un versamento uguale
            -- a quello che si vuole caricare.
            -- Si inserisce il versamento in WRK_VERSAMENTI con il codice (50300)
            -- e il messaggio di errore
            --
            if w_conta > 0 then
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
                     ,sanzioni_1
                     ,interessi)
               values(w_progressivo,w_tipo_tributo,'F24',rec_vers.anno,null,rec_vers.cod_fiscale_vers,
                      rec_vers.cognome_nome,
                      decode(w_rata_pratica,0,'50300','50362'),
                      w_progressivo,sysdate,
                      'Sanzioni e Interessi - '||decode(w_rata_pratica,0,'Versamento con codici violazione gia` Presente in data '||to_char(rec_vers.data_pagamento,'dd/mm/yyyy')
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
                     ,rec_vers.importo_sanzioni
                     ,rec_vers.importo_interessi);
            else
               --
               -- Se tutti i controlli vengono superati, si inserisce la riga nella tabella
               -- VERSAMENTI
               --
               BEGIN -- Assegnazione Numero Progressivo
                  select nvl(max(vers.sequenza),0)+1
                    into w_sequenza
                    from versamenti vers
                   where vers.cod_fiscale     = rec_vers.cod_fiscale
                     and vers.anno            = w_anno_pratica       -- rec_vers.anno
                     and vers.tipo_tributo    = rec_vers.tipo_tributo
                  ;
               END;
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
                        ,interessi)
                  select rec_vers.cod_fiscale
                        ,w_anno_pratica                              -- rec_vers.anno
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
                        -- (VD - 25/09/2018): gestione pratiche rateizzate
                        -- se si tratta di pratica rateizzata la rata si
                        -- ricava dall'identificativo operazione, altrimenti
                        -- si considera quella presente sul versamento
                        --,decode(rec_vers.rateazione
                        --       ,'0101',11
                        --       ,'0102',12
                        --       ,'0202',22
                        --       ,to_number(null)
                        --       )
                        ,decode(w_rata_pratica,0
                                              ,decode(rec_vers.rateazione
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
                        ,f_f24_note_versamento(rec_vers.id_operazione,w_pratica,'S',a_documento_id,null,null,rec_vers.rateazione)
                        ,a_documento_id
                        ,rec_vers.importo_sanzioni
                        ,rec_vers.importo_interessi
                    from dual
                  ;
               EXCEPTION
                  WHEN others THEN
                     w_errore := 'Errore in inserimento versamento'||
                                 ' di '||rec_vers.cod_fiscale||' progressivo '||
                                 to_char(rec_vers.progressivo)||' ('||sqlerrm||')';
                     RAISE errore;
               END;
               --
               -- (VM - #60197) Lancia procedura per elaborazione messaggio se presenti ruoli coattivi
               --
               a_log_documento := F_CTR_VERS_RUOLI_COATTIVI(w_pratica, rec_vers.cod_fiscale, a_log_documento);
            end if;
         end if;
      end if;
      --
      -- Si eliminano le righe di wrk_tras_anci trattate in questa fase
      -- (VD - 16/05/2017): aggiunta condizione di where su data pagamento
      -- (VD - 26/10/2018): aggiunta condizione di where su rateazione
      --
      BEGIN
         delete wrk_tras_anci wkta
          where rtrim(substr(wkta.dati,50,16))      = rec_vers.cod_fiscale_vers
            and to_number(substr(wkta.dati,88,4))   = rec_vers.anno
            and decode(substr(wkta.dati,128,2),'00','U','01','S','10','A','11','U',null)
                                                    = rec_vers.tipo_versamento
            and wkta.anno                           = 2
            and substr(wkta.dati,79,4) in ('3906','3907','3923','3924','357E','358E')    -- solo i versamneti su violazioni
            and to_number(substr(wkta.dati,126,1))  <> 1  -- si escludono i versamenti su ravvedimenti
            and substr(wkta.dati,260,1) = 'I'             -- ICI/IMU
            and substr(wkta.dati,1,2)   = 'G1'            -- Si trattano solo i versamenti
            and nvl(upper(rtrim(substr(wkta.dati,279,18))),'*') = nvl(rec_vers.id_operazione,'*')
            and substr(wkta.dati,67,8) = to_char(rec_vers.data_pagamento,'yyyymmdd')
            and substr(wkta.dati,84,4) = rec_vers.rateazione
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
/* End Procedure: CARICA_VERS_VIOL_ICI_F24 */
/
