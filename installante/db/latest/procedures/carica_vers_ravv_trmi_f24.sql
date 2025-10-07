--liquibase formatted sql 
--changeset abrandolini:20250326_152423_carica_vers_ravv_trmi_f24 stripComments:false runOnChange:true 
 
create or replace procedure CARICA_VERS_RAVV_TRMI_F24
/*************************************************************************
 NOME:        CARICA_VERS_RAVV_TRMI_F24
 DESCRIZIONE: Tratta i versamenti di ravvedimenti relativi ai tributi minori
              (TOSAP/COSAP/ICP/PUBBL) presenti nella tabella WRK_TRAS_ANCI
              ed eventuali record scartati e successivamente bonificati.
 NOTE:
 Causali errore:        50100     Versamento già presente
                        50109     Contribuente non codificato
                        50150     Pratica di ravvedimento non presente
                        50180     Presenti più pratiche di ravvedimento
 Rev.    Data        Autore       Descrizione
 008     16/03/2023  VM           #55165 - Aggiunto parametro a_cod_fiscale.
                                  Aggiunto filtro cod_fiscale su popolamento cursori.
 007     24/06/2021  VD           Modificata gestione contribuente assente:
                                  ora il contribuente viene inserito anche
                                  in fase di caricamento da file (sempre se
                                  esiste gia' il soggetto).
 006     11/01/2021  VD           Gestione nuovo campo note_versamento
                                  della tabella WRK_VERSAMENTI: il contenuto
                                  viene copiato nel campo note della tabella
                                  VERSAMENTI.
 005     26/08/2020  VD           Aggiunto parametro provenienza in
                                  richiamo procedure CREA_RAVVEDIMENTO.
 004     02/05/2019  VD           Aggiunto raggruppamento per rateazione
                                  in query su wrk_trans_anci e relativa
                                  delete.
                                  Modificata valorizzazione rata a seconda
                                  della presenza o meno dell'identificativo
                                  operazione.
                                  Aggiunti controlli di congruenza con trigger
                                  sul valore della rata.
 003     30/04/2019  VD           Corretta condizione di where su
                                  codici_f24: ora controlla anche il campo
                                  descrizione_titr (per evitare il prodotto
                                  cartesiano sui codici tributo TOSAP)
 002     24/10/2018  VD           Corretta gestione campo rateazione
                                  inserito con spazi a sinistra
 001     25/09/2018  VD           Modifiche per gestione versamenti su
                                  pratiche rateizzate
 000     31/05/2018  VD           Prima emissione.
*************************************************************************/
( a_documento_id            documenti_caricati.documento_id%type default null,
  a_cod_fiscale             in                                   varchar2 default '%')
IS
w_progressivo            number;
w_sequenza               number;
w_conta                  number;
w_conta_importo_esatto   number;
w_pratica                number;
w_flag_infrazione        varchar(1);
w_errore                 varchar2(2000);
w_anno_pratica           number;
w_rata_pratica           number;
w_cod_fiscale            varchar2(16);
errore                   exception;
--
-- Esiste una fase iniziale di bonifica di eventuali anomalie presenti nella
-- tabella intermedia wrk_versamenti. Si tenta di ri-inserire il versamento;
-- se questo va a buon fine, allora si elimina la tabella wrk, altrimenti si
-- lascia la registrazione come in precedenza. Al massimo varia il motivo di
-- errore nel qual caso si cambiano la causale e le note.
-- (VD - 11/01/2021): Aggiunta selezione nuovo campo note_versamento
cursor sel_errati is
select wkve.progressivo                  progressivo
      ,wkve.tipo_tributo                 tipo_tributo
      ,wkve.anno                         anno
      ,wkve.cod_fiscale                  cod_fiscale
      ,wkve.importo_versato              importo_versato
      ,wkve.data_pagamento               data_pagamento
      ,wkve.ufficio_pt                   ufficio_pt
      ,wkve.data_reg                     data_reg
      ,wkve.sanzione_ravvedimento        sanzione_ravvedimento
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
      ,substr(wkve.note,1001)                   note
      ,wkve.documento_id
      ,wkve.rateazione
      ,wkve.note_versamento
  from wrk_versamenti wkve
      ,contribuenti   cont
      ,soggetti       sogg
 where wkve.tipo_incasso    = 'F24'
   and wkve.tipo_tributo    in ('TOSAP','ICP')
   and wkve.causale         in ('50100','50109','50150','50180')  -- RAVVEDIMENTO
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
-- (VD - 02/05/2019): Aggiunto raggruppamento per rateazione
--
CURSOR sel_vers IS
select min(wkta.progressivo)
      ,max(cont.cod_fiscale)                             cod_fiscale
      ,max(sogg.cognome_nome)                            cognome_nome
      ,rtrim(substr(wkta.dati,50,16))                    cod_fiscale_vers
      ,min(wkta.progressivo)                             progressivo
      ,to_number(substr(wkta.dati,88,4))                 anno
      ,decode(substr(wkta.dati,260,1),'O','TOSAP','ICP') tipo_tributo
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
      ,sum((to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100)
                                                          importo_versato
      ,replace(substr(wkta.dati,84,4),' ','0')            rateazione
      ,9                                                  fonte
      ,'F24'                                              utente
      ,trunc(sysdate)                                     data_variazione
      ,max(to_date(substr(wkta.dati,3,8),'yyyymmdd'))     data_reg
      , 'I'                                               tipo_messaggio
  from wrk_tras_anci         wkta
      ,contribuenti          cont
      ,soggetti              sogg
      ,codici_f24            cof2
 where cont.cod_fiscale     (+) = rtrim(substr(wkta.dati,50,16))
   and sogg.ni              (+) = cont.ni
   and wkta.anno                = 2
   and decode(substr(wkta.dati,260,1),'O','TOSAP','ICP')  = cof2.tipo_tributo
   and substr(wkta.dati,79,4)                             = cof2.tributo_f24
   and f_descrizione_titr(decode(substr(wkta.dati,260,1),'O','TOSAP','ICP'),to_number(substr(wkta.dati,88,4))) = cof2.descrizione_titr
   and cof2.tipo_codice                                   = 'C'  -- si escludono i versamenti su violazioni
   and to_number(substr(wkta.dati,126,1))  = 1                   -- solo versamenti su ravvedimenti
   and substr(wkta.dati,260,1) in ('O','C')                      -- TOSAP/COSAP e ICP
   and substr(wkta.dati,1,2) = 'G1'                              -- Si trattano solo i versamenti
 group by rtrim(substr(wkta.dati,50,16))
         ,to_number(substr(wkta.dati,88,4))
         ,decode(substr(wkta.dati,260,1),'O','TOSAP','ICP')      -- tipo_tributo
         ,upper(rtrim(substr(wkta.dati,279,18)))                 -- id. operazione
         ,to_date(substr(wkta.dati,67,8),'yyyymmdd')             -- data_pagamento
         ,replace(substr(wkta.dati,84,4),' ','0')                -- rateazione
union
select min(wkta.progressivo)
      ,max(cont.cod_fiscale)                             cod_fiscale
      ,max(sogg.cognome_nome)                            cognome_nome
      ,rtrim(substr(wkta.dati,50,16))                    cod_fiscale_vers
      ,min(wkta.progressivo)                             progressivo
      ,to_number(substr(wkta.dati,88,4))                 anno
      ,decode(substr(wkta.dati,260,1),'O','TOSAP','ICP') tipo_tributo
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
      ,sum((to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100)
                                                          importo_versato
      ,replace(substr(wkta.dati,84,4),' ','0')            rateazione
      ,9                                                  fonte
      ,'F24'                                              utente
      ,trunc(sysdate)                                     data_variazione
      ,max(to_date(substr(wkta.dati,3,8),'yyyymmdd'))     data_reg
      , 'S'                                               tipo_messaggio
  from wrk_tras_anci         wkta
      ,contribuenti          cont
      ,soggetti              sogg
      ,codici_f24            cof2
 where cont.cod_fiscale     (+) = rtrim(substr(wkta.dati,50,16))
   and sogg.ni              (+) = cont.ni
   and wkta.anno                = 2
   and decode(substr(wkta.dati,260,1),'O','TOSAP','ICP')  = cof2.tipo_tributo
   and substr(wkta.dati,79,4)                             = cof2.tributo_f24
   and cof2.tipo_codice                                   in ('S','I')  -- si trattano i versamenti su violazioni
   and f_descrizione_titr(decode(substr(wkta.dati,260,1),'O','TOSAP','ICP'),to_number(substr(wkta.dati,88,4))) = cof2.descrizione_titr
   and to_number(substr(wkta.dati,126,1))  = 1  -- solo versamenti su ravvedimenti
   and substr(wkta.dati,260,1) in ('O','C')     -- TOSAP/COSAP e ICP
   and substr(wkta.dati,1,2) = 'G1'             -- Si trattano solo i versamenti
 group by rtrim(substr(wkta.dati,50,16))
         ,to_number(substr(wkta.dati,88,4))
         ,decode(substr(wkta.dati,260,1),'O','TOSAP','ICP')   -- tipo_tributo
         ,upper(rtrim(substr(wkta.dati,279,18)))              -- id. operazione
         ,to_date(substr(wkta.dati,67,8),'yyyymmdd')          -- data_pagamento
         ,replace(substr(wkta.dati,84,4),' ','0')             -- rateazione
 order by 1
;
--se si cambia la select ricordarsi la delete in fondo
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
      if rec_errati.cod_fiscale_cont is null then
         w_cod_fiscale := f_crea_contribuente(rec_errati.cod_fiscale,w_errore);
         if w_cod_fiscale is null then
            if w_errore is not null then
               update wrk_versamenti wkve
                  set note = substr(decode(note,'','',note||' - ')||w_errore,1,2000)
                where wkve.progressivo  = rec_errati.progressivo;
            else
               update wrk_versamenti wkve
                  set wkve.cognome_nome = rec_errati.cognome_nome
                     ,wkve.causale      = '50109'
                     ,wkve.note         = rpad(decode(rec_errati.tipo_messaggio,'I','Imposta - '
                                                                               ,'S','Sanzioni e Interessi - '
                                                                               ,'')||
                                               'Versamento su Ravvedimento Contribuente ('||rec_errati.cod_fiscale||') sconosciuto',1000)||
                                          rec_errati.note
                where wkve.progressivo  = rec_errati.progressivo
               ;
            end if;
            goto fine_tratta_errati;
         end if;
      else
         w_cod_fiscale := rec_errati.cod_fiscale_cont;
      end if;
      --
      --w_pratica := F_F24_PRATICA(rec_errati.cod_fiscale_cont,rec_errati.id_operazione,rec_errati.data_pagamento,rec_errati.tipo_tributo);
      w_pratica := F_F24_PRATICA(w_cod_fiscale,rec_errati.id_operazione,rec_errati.data_pagamento,rec_errati.tipo_tributo);
      if nvl(w_pratica,-1) < 0 then
         w_pratica := to_number(null);
         BEGIN
            select count(*)
              into w_conta
              from pratiche_tributo prtr
             where prtr.cod_fiscale            = w_cod_fiscale -- rec_errati.cod_fiscale_cont
               and prtr.anno                   = rec_errati.anno
               and prtr.tipo_tributo           = rec_errati.tipo_tributo
               and prtr.tipo_pratica           = 'V'
               and exists (select 'x' from sanzioni_pratica sapr
                            where prtr.pratica = sapr.pratica
                          )
                 ;
         END;
         if w_conta = 0  and rec_errati.sanzione_ravvedimento is not null then
            if rec_errati.sanzione_ravvedimento = 'N' then
               w_flag_infrazione := NULL;
            else
               w_flag_infrazione := rec_errati.sanzione_ravvedimento;
            end if;
            CREA_RAVVEDIMENTO(w_cod_fiscale -- rec_errati.cod_fiscale_cont
                             ,rec_errati.anno
                             ,rec_errati.data_pagamento
                             ,''            -- rec_errati.tipo_versamento
                             ,w_flag_infrazione
                             ,'TR4'
                             ,rec_errati.tipo_tributo
                             ,w_pratica
                             ,'TR4'
                             );
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
             where prtr.cod_fiscale            = w_cod_fiscale --rec_errati.cod_fiscale_cont
               and prtr.anno                   = rec_errati.anno
               and prtr.tipo_tributo           = rec_errati.tipo_tributo
               and prtr.tipo_pratica           = 'V'
               and (   prtr.importo_totale          = rec_errati.importo_versato
                    or round(prtr.importo_totale,0) = rec_errati.importo_versato
                   )
               and exists (select 'x' from sanzioni_pratica sapr
                            where prtr.pratica      = sapr.pratica
                          )
                 ;
         END;
         if w_conta = 0 then
            update wrk_versamenti wkve
               set wkve.cognome_nome = rec_errati.cognome_nome
                  ,wkve.causale      = '50150'
                  ,wkve.note         = rpad(decode(rec_errati.tipo_messaggio,'I','Imposta - '
                                                                            ,'S','Sanzioni e Interessi - '
                                                                                ,'')||
                                            'Versamento su Ravvedimento - Pratica di Ravvedimento non Presente',1000)||
                                       rec_errati.note
             where wkve.progressivo  = rec_errati.progressivo
                 ;
         elsif w_conta > 1 and w_conta_importo_esatto <> 1 then
            update wrk_versamenti wkve
               set wkve.cognome_nome = rec_errati.cognome_nome
                  ,wkve.causale      = '50180'
                  ,wkve.note         = rpad(decode(rec_errati.tipo_messaggio,'I','Imposta - '
                                                                            ,'S','Sanzioni e Interessi - '
                                                                                ,'')||
                                            'Versamento su Ravvedimento - Più di una Pratica di Ravvedimento Presente',1000)||
                                       rec_errati.note
             where wkve.progressivo  = rec_errati.progressivo
                 ;
         else
            if w_conta = 1 then
               begin
                  select prtr.pratica
                       , prtr.anno
                    into w_pratica
                       , w_anno_pratica
                    from pratiche_tributo prtr
                   where prtr.cod_fiscale            = w_cod_fiscale --rec_errati.cod_fiscale_cont
                     and prtr.anno                   = rec_errati.anno
                     and prtr.tipo_tributo           = rec_errati.tipo_tributo
                     and prtr.tipo_pratica           = 'V'
                     and exists (select 'x' from sanzioni_pratica sapr
                                  where prtr.pratica                     = sapr.pratica
                                )
                       ;
               exception
                 when others then
                   w_pratica      := to_number(null);
                   w_anno_pratica := to_number(null);
               end;
            else
               BEGIN
                  select prtr.pratica
                       , prtr.anno
                    into w_pratica
                       , w_anno_pratica
                    from pratiche_tributo prtr
                   where prtr.cod_fiscale                 = w_cod_fiscale -- rec_errati.cod_fiscale_cont
                     and prtr.anno                        = rec_errati.anno
                     and prtr.tipo_tributo                = rec_errati.tipo_tributo
                     and prtr.tipo_pratica                = 'V'
                     and (   prtr.importo_totale          = rec_errati.importo_versato
                          or round(prtr.importo_totale,0) = rec_errati.importo_versato
                         )
                     and exists (select 'x' from sanzioni_pratica sapr
                                  where prtr.pratica      = sapr.pratica
                                )
                       ;
               exception
                 when others then
                   w_pratica      := to_number(null);
                   w_anno_pratica := to_number(null);
               END;
            end if;
         end if;
      end if;
      --
      -- (VD - 02/05/2019): modificata valorizzazione rata.
      --                    In caso di ravvedimento, la rata si ricava
      --                    comunque dal campo rateazione e non
      --                    dall'identificativo operazione.
      if rec_errati.rateazione = '0101' then
         w_rata_pratica := 0;
      else
         if afc.is_numeric(substr(rec_errati.rateazione,1,2)) = 1 then
            w_rata_pratica := to_number(substr(rec_errati.rateazione,1,2));
         else
            w_rata_pratica := 1;
         end if;
      end if;
      -- (VD - 02/05/2019): si controlla che il valore della rata sia
      --                    congruente con i valori previsti nel trigger
      --                    di data integrity della tabella versamenti.
      if w_pratica is null and w_rata_pratica not in (0,1,2,3,4,11,12,22) then
         w_rata_pratica := 1;
      end if;
      --
      if w_pratica is not null and w_rata_pratica not between 0 and 36 then
         w_rata_pratica := 36;
      end if;
      if w_pratica is not null then
         BEGIN
            select count(*)
              into w_conta
              from versamenti vers
             where vers.cod_fiscale            = w_cod_fiscale --rec_errati.cod_fiscale_cont
               and vers.anno                   = rec_errati.anno
               and vers.tipo_tributo           = rec_errati.tipo_tributo
               and vers.descrizione            = 'VERSAMENTO IMPORTATO DA MODELLO F24'
               and vers.ufficio_pt             = rec_errati.ufficio_pt
               and vers.data_pagamento         = rec_errati.data_pagamento
               and vers.importo_versato        = rec_errati.importo_versato
               and nvl(vers.pratica,-1)        = nvl(w_pratica,-1)
            ;
         END;
         if w_conta > 0 then
            update wrk_versamenti wkve
               set wkve.cognome_nome = rec_errati.cognome_nome
                  ,wkve.causale      = '50100'
                  ,wkve.note         = rpad(decode(rec_errati.tipo_messaggio,'I','Imposta - '
                                                                            ,'S','Sanzioni e Interessi - '
                                                                                ,'')||
                                            'Versamento su Ravvedimento gia` Presente in data '||
                                            to_char(rec_errati.data_pagamento,'dd/mm/yyyy'),1000)||
                                       rec_errati.note
             where wkve.progressivo  = rec_errati.progressivo
            ;
         else
            /*BEGIN -- Assegnazione Numero Progressivo
               select nvl(max(vers.sequenza),0)+1
                 into w_sequenza
                 from versamenti vers
                where vers.cod_fiscale     = rec_errati.cod_fiscale
                  and vers.anno            = rec_errati.anno
                  and vers.tipo_tributo    = rec_errati.tipo_tributo
                    ;
            END;*/
            w_sequenza := to_number(null);
            VERSAMENTI_NR ( w_cod_fiscale, rec_errati.anno
                          , rec_errati.tipo_tributo, w_sequenza );
            BEGIN
               insert into versamenti
                     (cod_fiscale
                     ,anno
                     ,tipo_tributo
                     ,sequenza
                     ,descrizione
                     ,ufficio_pt
                     ,data_pagamento
                     ,importo_versato
                     ,fonte
                     ,utente
                     ,data_variazione
                     ,data_reg
                     ,pratica
                     ,rata
                     ,note
                     ,documento_id
                     )
               select w_cod_fiscale -- rec_errati.cod_fiscale_cont
                     ,rec_errati.anno
                     ,rec_errati.tipo_tributo
                     ,w_sequenza
                     ,'VERSAMENTO IMPORTATO DA MODELLO F24'
                     ,rec_errati.ufficio_pt
                     ,rec_errati.data_pagamento
                     ,rec_errati.importo_versato
                     ,9
                     ,'F24'
                     ,trunc(sysdate)
                     ,rec_errati.data_reg
                     ,w_pratica
                     --(VD - 25/09/2018): la rata viene ricavata dal
                     -- dato originale dell'F24
                     --,rec_errati.rata
                     -- (VD - 02/05/2019): spostati controlli prima di insert
                     --,decode(rec_errati.rateazione
                     --       ,null  ,rec_errati.rata
                     --       ,'0101',0
                     --              ,to_number(substr(rec_errati.rateazione,1,2))
                     --       )
                     ,w_rata_pratica
                     ,substr(trim(rec_errati.note_versamento)||';'||
                             trim(rec_errati.note),1,2000)
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
      if rec_vers.cod_fiscale is null then
         w_cod_fiscale := f_crea_contribuente(rec_vers.cod_fiscale_vers,w_errore);
         if w_cod_fiscale is null then
            w_progressivo := F_SELEZIONA_PROGRESSIVO;
            insert into wrk_versamenti
                  (progressivo
                  ,tipo_tributo
                  ,tipo_incasso
                  ,anno
                  ,cod_fiscale
                  ,cognome_nome
                  ,causale
                  ,disposizione
                  ,data_variazione
                  ,note
                  ,ufficio_pt
                  ,data_pagamento
                  ,data_reg
                  ,importo_versato
                  ,rata
                  ,identificativo_operazione
                  ,documento_id
                  ,rateazione
                  )
            values(w_progressivo
                  ,rec_vers.tipo_tributo
                  ,'F24'
                  ,rec_vers.anno
                  ,rec_vers.cod_fiscale_vers
                  ,rec_vers.cognome_nome
                  ,'50109'
                  ,w_progressivo
                  ,sysdate
                  ,rpad(decode(rec_vers.tipo_messaggio,'I','Imposta - ',
                                                       'S','Sanzioni e interessi - ')||
                               'Versamento su Ravvedimento Contribuente ('||rec_vers.cod_fiscale_vers||') sconosciuto',1000)||
                   f_f24_note_versamento(rec_vers.id_operazione,to_number(null),'I',a_documento_id,rec_vers.tipo_tributo,to_char(null),rec_vers.rateazione)
                  ,rec_vers.ufficio_pt
                  ,rec_vers.data_pagamento
                  ,rec_vers.data_reg
                  ,rec_vers.importo_versato
                  -- (VD - 25/09/2018): sui versamenti da bonificare si memorizza
                  --                    la rateazione originale
                  --,decode(rec_vers.rateazione,'0101',0,to_number(substr(rec_vers.rateazione,1,2)))
                  ,to_number(null)
                  ,rec_vers.id_operazione
                  ,a_documento_id
                  ,rec_vers.rateazione
                  );
         end if;
      else
         w_cod_fiscale := rec_vers.cod_fiscale;
      end if;
      --
      if w_cod_fiscale is not null then
         --w_pratica := F_F24_PRATICA(rec_vers.cod_fiscale,rec_vers.id_operazione,rec_vers.data_pagamento,rec_vers.tipo_tributo);
         w_pratica := F_F24_PRATICA(w_cod_fiscale,rec_vers.id_operazione,rec_vers.data_pagamento,rec_vers.tipo_tributo);
         if nvl(w_pratica,-1) < 0 then
            w_pratica := to_number(null);
            --
            -- Nota: non so quali codici sanzione controllare per la TOSAP/ICP,
            -- quindi controllo la generica esistenza di sanzioni su pratica
            -- di ravvedimento
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
                               where prtr.pratica = sapr.pratica
                             )
                    ;
            END;
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
                               where prtr.pratica      = sapr.pratica
                             )
                    ;
            END;
            if w_conta = 0 then
               w_progressivo := F_SELEZIONA_PROGRESSIVO;
               insert into wrk_versamenti
                     (progressivo
                     ,tipo_tributo
                     ,tipo_incasso
                     ,anno
                     ,cod_fiscale
                     ,cognome_nome
                     ,causale
                     ,disposizione
                     ,data_variazione
                     ,note
                     ,ufficio_pt
                     ,data_pagamento
                     ,data_reg
                     ,importo_versato
                     ,rata
                     ,identificativo_operazione
                     ,documento_id
                     ,rateazione
                     )
               values(w_progressivo
                     ,rec_vers.tipo_tributo
                     ,'F24'
                     ,rec_vers.anno
                     ,rec_vers.cod_fiscale_vers
                     ,rec_vers.cognome_nome
                     ,'50150'
                     ,w_progressivo
                     ,sysdate
                     ,rpad(decode(rec_vers.tipo_messaggio,'I','Imposta - ',
                                                          'S','Sanzioni e interessi - ')||
                                 'Versamento su Ravvedimento - Pratica di Ravvedimento non Presente',1000)||
                      f_f24_note_versamento(rec_vers.id_operazione,to_number(null),'I',a_documento_id,rec_vers.tipo_tributo,to_char(null),rec_vers.rateazione)
                     ,rec_vers.ufficio_pt
                     ,rec_vers.data_pagamento
                     ,rec_vers.data_reg
                     ,rec_vers.importo_versato
                     -- (VD - 25/09/2018): sui versamenti da bonificare si memorizza
                     --                    la rateazione originale
                     --,decode(rec_vers.rateazione,'0101',0,to_number(substr(rec_vers.rateazione,1,2)))
                     ,to_number(null)
                     ,rec_vers.id_operazione
                     ,a_documento_id
                     ,rec_vers.rateazione
                     );
            elsif w_conta > 1 and w_conta_importo_esatto <> 1 then
               w_progressivo := F_SELEZIONA_PROGRESSIVO;
               insert into wrk_versamenti
                     (progressivo
                     ,tipo_tributo
                     ,tipo_incasso
                     ,anno
                     ,cod_fiscale
                     ,cognome_nome
                     ,causale
                     ,disposizione
                     ,data_variazione
                     ,note
                     ,ufficio_pt
                     ,data_pagamento
                     ,data_reg
                     ,importo_versato
                     ,rata
                     ,identificativo_operazione
                     ,documento_id
                     ,rateazione
                     )
               values(w_progressivo
                     ,rec_vers.tipo_tributo
                     ,'F24'
                     ,rec_vers.anno
                     ,rec_vers.cod_fiscale_vers
                     ,rec_vers.cognome_nome
                     ,'50180'
                     ,w_progressivo
                     ,sysdate
                     ,rpad(decode(rec_vers.tipo_messaggio,'I','Imposta - ',
                                                          'S','Sanzioni e interessi - ')||
                                  'Versamento su Ravvedimento - Più di una Pratica di Ravvedimento Presente',1000)||
                      f_f24_note_versamento(rec_vers.id_operazione,to_number(null),'I',a_documento_id,rec_vers.tipo_tributo,to_char(null),rec_vers.rateazione)
                     ,rec_vers.ufficio_pt
                     ,rec_vers.data_pagamento
                     ,rec_vers.data_reg
                     ,rec_vers.importo_versato
                     -- (VD - 25/09/2018): sui versamenti da bonificare si memorizza
                     --                    la rateazione originale
                     --,decode(rec_vers.rateazione,'0101',0,to_number(substr(rec_vers.rateazione,1,2)))
                     ,to_number(null)
                     ,rec_vers.id_operazione
                     ,a_documento_id
                     ,rec_vers.rateazione
                     );
            else
               if w_conta = 1 then
               --
               -- Nota: non so quali codici sanzione controllare per la TOSAP/ICP,
               -- quindi controllo la generica esistenza di sanzioni su pratica
               -- di ravvedimento
               --
                  begin
                     select prtr.pratica
                          , prtr.anno
                       into w_pratica
                          , w_anno_pratica
                       from pratiche_tributo prtr
                      where prtr.cod_fiscale            = w_cod_fiscale --rec_vers.cod_fiscale
                        and prtr.anno                   = rec_vers.anno
                        and prtr.tipo_tributo           = rec_vers.tipo_tributo
                        and prtr.tipo_pratica           = 'V'
                        and exists (select 'x' from sanzioni_pratica sapr
                                     where prtr.pratica = sapr.pratica
                                   )
                          ;
                  exception
                    when others then
                      w_pratica      := to_number(null);
                      w_anno_pratica := to_number(null);
                  end;
               else
                  --
                  -- Nota: non so quali codici sanzione controllare per la TOSAP/ICP,
                  -- quindi controllo la generica esistenza di sanzioni su pratica
                  -- di ravvedimento
                  --
                  BEGIN
                     select prtr.pratica
                          , prtr.anno
                       into w_pratica
                          , w_anno_pratica
                       from pratiche_tributo prtr
                      where prtr.cod_fiscale                 = w_cod_fiscale --rec_vers.cod_fiscale
                        and prtr.anno                        = rec_vers.anno
                        and prtr.tipo_tributo                = rec_vers.tipo_tributo
                        and prtr.tipo_pratica                = 'V'
                        and (   prtr.importo_totale          = rec_vers.importo_versato
                             or round(prtr.importo_totale,0) = rec_vers.importo_versato
                            )
                        and exists (select 'x' from sanzioni_pratica sapr
                                     where prtr.pratica      = sapr.pratica
                                   )
                          ;
                  exception
                    when others then
                      w_pratica      := to_number(null);
                      w_anno_pratica := to_number(null);
                  END;
               end if;
            end if;
         end if;
         --
         -- (VD - 02/05/2019): modificata valorizzazione rata.
         --                    In caso di ravvedimento, la rata si ricava
         --                    comunque dal campo rateazione e non
         --                    dall'identificativo operazione.
         if rec_vers.rateazione = '0101' then
            w_rata_pratica := 0;
         else
            if afc.is_numeric(substr(rec_vers.rateazione,1,2)) = 1 then
               w_rata_pratica := to_number(substr(rec_vers.rateazione,1,2));
            else
               w_rata_pratica := 1;
            end if;
         end if;
         -- (VD - 02/05/2019): si controlla che il valore della rata sia
         --                    congruente con i valori previsti nel trigger
         --                    di data integrity della tabella versamenti.
         if w_pratica is null and w_rata_pratica not in (0,1,2,3,4,11,12,22) then
            w_rata_pratica := 1;
         end if;
         --
         if w_pratica is not null and w_rata_pratica not between 0 and 36 then
            w_rata_pratica := 36;
         end if;
         --
         if w_pratica is not null then
            BEGIN
               select count(*)
                 into w_conta
                 from versamenti vers
                where vers.cod_fiscale            = w_cod_fiscale --rec_vers.cod_fiscale
                  and vers.anno                   = rec_vers.anno
                  and vers.tipo_tributo           = rec_vers.tipo_tributo
                  and vers.descrizione            = rec_vers.descrizione
                  and vers.ufficio_pt             = rec_vers.ufficio_pt
                  and vers.data_pagamento         = rec_vers.data_pagamento
                  and vers.importo_versato        = rec_vers.importo_versato
                  and nvl(vers.pratica,-1)        = nvl(w_pratica,-1)
               ;
            END;
            if w_conta > 0 then
               w_progressivo := F_SELEZIONA_PROGRESSIVO;
               insert into wrk_versamenti
                     (progressivo
                     ,tipo_tributo
                     ,tipo_incasso
                     ,anno
                     ,cod_fiscale
                     ,cognome_nome
                     ,causale
                     ,disposizione
                     ,data_variazione
                     ,note
                     ,ufficio_pt
                     ,data_pagamento
                     ,data_reg
                     ,importo_versato
                     ,rata
                     ,identificativo_operazione
                     ,documento_id
                     ,rateazione
                     )
               values(w_progressivo
                     ,rec_vers.tipo_tributo
                     ,'F24'
                     ,rec_vers.anno
                     ,rec_vers.cod_fiscale_vers
                     ,rec_vers.cognome_nome
                     ,'50100'
                     ,w_progressivo
                     ,sysdate
                     ,rpad(decode(rec_vers.tipo_messaggio,'I','Imposta - ',
                                                          'S','Sanzioni e interessi - ')||
                                  'Versamento su Ravvedimento gia` Presente in data '||to_char(rec_vers.data_pagamento,'dd/mm/yyyy'),1000)||
                      f_f24_note_versamento(rec_vers.id_operazione,w_pratica,'I',a_documento_id,rec_vers.tipo_tributo,to_char(null),rec_vers.rateazione)
                     ,rec_vers.ufficio_pt
                     ,rec_vers.data_pagamento
                     ,rec_vers.data_reg
                     ,rec_vers.importo_versato
                     -- (VD - 25/09/2018): sui versamenti da bonificare si memorizza
                     --                    la rateazione originale
                     --,decode(rec_vers.rateazione,'0101',0,to_number(substr(rec_vers.rateazione,1,2)))
                     ,to_number(null)
                     ,rec_vers.id_operazione
                     ,a_documento_id
                     ,rec_vers.rateazione
                     );
            else
               --
               -- Arrivati a questo punto, la pratica e  sicuramente presente
               -- nell archivio pratiche ed è del tipo richiesto. Si estrapola
               -- l anno per evitare di inserire versamenti con anno diverso
               -- da quello della pratica
               --
               --if w_pratica is not null then
               --   w_anno_pratica := to_number(substr(rec_vers.id_operazione,5,4));
               --   w_rata_pratica := to_number(substr(rec_vers.id_operazione,9,2));
               --else
               --   w_anno_pratica := to_number(null);
               --   w_rata_pratica := 0;
               --end if;
               --
               -- Se tutti i controlli vengono superati, si inserisce la riga
               -- nella tabella VERSAMENTI
               --
               /*BEGIN -- Assegnazione Numero Progressivo
                  select nvl(max(vers.sequenza),0)+1
                    into w_sequenza
                    from versamenti vers
                   where vers.cod_fiscale     = rec_vers.cod_fiscale
                     and vers.anno            = nvl(w_anno_pratica,rec_vers.anno)
                     and vers.tipo_tributo    = rec_vers.tipo_tributo
                  ;
               END; */
               w_sequenza := to_number(null);
               VERSAMENTI_NR ( w_cod_fiscale, rec_vers.anno
                             , rec_vers.tipo_tributo, w_sequenza );
               BEGIN
                  insert into versamenti
                        (cod_fiscale
                        ,anno
                        ,tipo_tributo
                        ,sequenza
                        ,descrizione
                        ,ufficio_pt
                        ,data_pagamento
                        ,importo_versato
                        ,fonte
                        ,utente
                        ,data_variazione
                        ,data_reg
                        ,pratica
                        ,rata
                        ,note
                        ,documento_id
                        )
                  values(w_cod_fiscale -- rec_vers.cod_fiscale
                        ,nvl(w_anno_pratica,rec_vers.anno)
                        ,rec_vers.tipo_tributo
                        ,w_sequenza
                        ,rec_vers.descrizione
                        ,rec_vers.ufficio_pt
                        ,rec_vers.data_pagamento
                        ,rec_vers.importo_versato
                        ,rec_vers.fonte
                        ,rec_vers.utente
                        ,rec_vers.data_variazione
                        ,rec_vers.data_reg
                        ,w_pratica
                        -- (VD - 25/09/2018): in caso di ravvedimento,
                        -- la pratica esiste ma le rate si ricavano
                        -- dalla rateazione del versamento (e non
                        -- dall'identificativo operazione)
                        -- (VD - 02/05/2019): spostati controlli prima di insert
                        -- ,decode(rec_vers.rateazione,'0101',0,to_number(substr(rec_vers.rateazione,1,2)))
                        ,w_rata_pratica
                        ,f_f24_note_versamento(rec_vers.id_operazione,w_pratica,rec_vers.tipo_messaggio,a_documento_id,rec_vers.tipo_tributo,to_char(null),rec_vers.rateazione)
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
      end if;
      --
      -- Si eliminano le righe di wrk_tras_anci trattate in questa fase
      -- (VD - 02/05/2018): aggiunta condizione di where su rateazione
      --
      BEGIN
         delete wrk_tras_anci wkta
          where rtrim(substr(wkta.dati,50,16))      = rec_vers.cod_fiscale_vers
            and to_number(substr(wkta.dati,88,4))   = rec_vers.anno
            and wkta.anno                           = 2
            and ((rec_vers.tipo_messaggio = 'I' and
                  substr(wkta.dati,79,4) in (select tributo_f24
                                               from codici_f24 cof2
                                              where cof2.tipo_tributo = rec_vers.tipo_tributo
                                                and cof2.tipo_codice = 'C'))
                 or
                 (rec_vers.tipo_messaggio = 'S' and
                  substr(wkta.dati,79,4) in (select tributo_f24
                                               from codici_f24 cof2
                                              where cof2.tipo_tributo = rec_vers.tipo_tributo
                                                and cof2.tipo_codice in ('I','S'))))
            and to_number(substr(wkta.dati,126,1))  = 1  -- solo versamenti su ravvedimenti
            and substr(wkta.dati,260,1) in ('O','C')     -- TOSAP/COSAP e ICP
            and substr(wkta.dati,1,2)   = 'G1'           -- Si trattano solo i versamenti
            and nvl(upper(rtrim(substr(wkta.dati,279,18))),'*') = nvl(rec_vers.id_operazione,'*')
            and substr(wkta.dati,67,8) = to_char(rec_vers.data_pagamento,'yyyymmdd')
            and replace(substr(wkta.dati,84,4),' ','0') = rec_vers.rateazione
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
/* End Procedure: CARICA_VERS_RAVV_TRMI_F24 */
/

