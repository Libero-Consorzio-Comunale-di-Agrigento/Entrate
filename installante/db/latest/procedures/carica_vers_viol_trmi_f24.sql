--liquibase formatted sql 
--changeset abrandolini:20250326_152423_carica_vers_viol_trmi_f24 stripComments:false runOnChange:true 
 
create or replace procedure CARICA_VERS_VIOL_TRMI_F24
/*******************************************************************************
 NOME:        CARICA_VERS_VIOL_TRMI_F24
 DESCRIZIONE: Tratta i versamenti relativi a violazioni sui tributi minori
              (TOSAP/COSAP/ICP/PUBBL) presenti nella tabella WRK_TRAS_ANCI
              ed eventuali record scartati e successivamente bonificati.
 NOTE:
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
 Codici tributo trattati:
 3933 - Tassa/canone per l'occupazione di spazi ed aree pubbliche
        (TOSAP/COSAP) - Interessi
 3934 - Tassa/canone per l'occupazione di spazi ed aree pubbliche
        (TOSAP/COSAP) - Sanzioni
 3965 - Imposta comunale sulla pubblicità/canone per l'installazione di
        mezzi pubblicitari (ICP DPA/CIMP) - Interessi
 3966 - Imposta comunale sulla pubblicità/canone per l'installazione di
        mezzi pubblicitari (ICP DPA/CIMP) - Sanzioni
 Rev.    Date         Author      Note
 007     16/03/2023   VM          #55165 - Aggiunto parametro a_cod_fiscale.
                                  Aggiunto filtro cod_fiscale su popolamento cursori.
 006     14/03/2023   VM          #60197 - Aggiunto il parametro a_log_documento.
                                  Dopo l'inserimento del versamento viene lanciato
                                  controllo per popolare il messaggio se presenti
                                  ruoli coattivi su sanzioni pratica.
 005     11/01/2021   VD          Gestione nuovo campo note_versamento
                                  della tabella WRK_VERSAMENTI: il contenuto
                                  viene copiato nel campo note della tabella
                                  VERSAMENTI.
 004     02/05/2019   VD          Modificata valorizzazione rata a seconda
                                  della presenza o meno dell'identificativo
                                  operazione.
                                  Aggiunti controlli di congruenza con trigger
                                  sul valore della rata.
 004     30/04/2019   VD          Corretta condizione di where su
                                  codici_f24: ora controlla anche il campo
                                  descrizione_titr (per evitare il prodotto
                                  cartesiano sui codici tributo TOSAP)
 003     26/10/2018   VD          Gestione importi sanzioni e interessi
 002     24/10/2018   VD          Corretta gestione campo rateazione
                                  inserito con spazi a sinistra
 001     25/09/2018   VD          Modifiche per gestione versamenti su
                                  pratiche rateizzate
 000     31/05/2018   VD          Prima emissione.
********************************************************************************/
( a_documento_id                  documenti_caricati.documento_id%type default null,
  a_cod_fiscale                   in                                   varchar2 default '%',
  a_log_documento                 in out                               varchar2)
IS
w_progressivo        number;
w_sequenza           number;
w_conta              number;
w_pratica            number;
w_anno_pratica       number;
w_rata_pratica       number;
w_errore             varchar2(2000);
errore               exception;
--
-- Esiste una fase iniziale di bonifica di eventuali anomalie presenti nella
-- tabella intermedia wrk_versamenti. Si tenta di ri-inserire il versamento;
-- se questo va a buon fine, allora si elimina la tabella wrk, altrimenti si
-- lascia la registrazione come in precedenza. Al massimo varia il motivo di
-- errore nel qual caso si cambiano la causale e le note.
-- (VD - 11/01/2021): Aggiunta selezione nuovo campo note_versamento
--
cursor sel_errati is
select wkve.progressivo
      ,wkve.tipo_tributo
      ,wkve.anno
      ,wkve.cod_fiscale
      ,wkve.importo_versato
      ,wkve.rata
      ,wkve.data_pagamento
      ,wkve.ufficio_pt
      ,wkve.data_reg
      ,wkve.flag_contribuente
      ,cont.cod_fiscale                         cod_fiscale_cont
      ,sogg.cognome_nome
      ,upper(wkve.identificativo_operazione)    id_operazione
      ,substr(wkve.note,1,1)                    tipo_messaggio
      ,substr(wkve.note,1001)                   note
      ,wkve.documento_id
      ,wkve.rateazione
      ,wkve.sanzioni_1
      ,wkve.interessi
      ,wkve.note_versamento
  from wrk_versamenti wkve
      ,contribuenti   cont
      ,soggetti       sogg
 where wkve.tipo_incasso    = 'F24'
   and wkve.tipo_tributo    in ('TOSAP','ICP')
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
--
CURSOR sel_vers IS
select max(cont.cod_fiscale)                             cod_fiscale
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
      ,replace(substr(wkta.dati,84,4),' ','0')            rateazione
      ,sum((to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100)
                                                          importo_versato
      ,sum(decode(cof2.tipo_codice
                 ,'I',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                     ,0))                                 importo_interessi
      ,sum(decode(cof2.tipo_codice
                 ,'S',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                     ,0))                                 importo_sanzioni
      ,9                                                  fonte
      ,'F24'                                              utente
      ,trunc(sysdate)                                     data_variazione
      ,max(to_date(substr(wkta.dati,3,8),'yyyymmdd'))     data_reg
  from wrk_tras_anci         wkta
      ,contribuenti          cont
      ,soggetti              sogg
      ,codici_f24            cof2
 where cont.cod_fiscale     (+) = rtrim(substr(wkta.dati,50,16))
   and sogg.ni              (+) = cont.ni
   and wkta.anno                = 2
   and decode(substr(wkta.dati,260,1),'O','TOSAP','ICP')  = cof2.tipo_tributo
   and substr(wkta.dati,79,4)   = cof2.tributo_f24
   and f_descrizione_titr(decode(substr(wkta.dati,260,1),'O','TOSAP','ICP'),to_number(substr(wkta.dati,88,4))) = cof2.descrizione_titr
   and cof2.tipo_codice         in ('S','I')                   -- solo i versamenti su violazioni
   and to_number(substr(wkta.dati,126,1))  <> 1                -- si escludono i versamenti su ravvedimenti
   and substr(wkta.dati,260,1)  in ('O','C')                   -- TOSAP/COSAP/ICP
   and substr(wkta.dati,1,2)    = 'G1'                         -- Si trattano solo i versamenti
 group by rtrim(substr(wkta.dati,50,16))                       -- cod.fiscale
         ,to_number(substr(wkta.dati,88,4))                    -- anno
         ,decode(substr(wkta.dati,260,1),'O','TOSAP','ICP')    -- tipo tributo
         ,upper(rtrim(substr(wkta.dati,279,18)))               -- id. operazione
         ,to_date(substr(wkta.dati,67,8),'yyyymmdd')           -- data pagamento
         ,replace(substr(wkta.dati,84,4),' ','0')              -- rateazione
 order by min(wkta.progressivo)
;
-- se si cambia la select, ricordarsi la delete in fondo.
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
-----------------------------------------------------------
-- Trattamento versamenti errati da tabella WRK_VERSAMENTI
-----------------------------------------------------------
   FOR rec_errati IN sel_errati
   LOOP
      if rec_errati.cod_fiscale_cont is null then
         update wrk_versamenti wkve
            set wkve.cognome_nome = rec_errati.cognome_nome
               ,wkve.causale      = '50309'
               ,wkve.note         = rpad(decode(rec_errati.tipo_messaggio,'I','Imposta - '
                                                                         ,'S','Sanzioni e Interessi - '
                                                                             ,'')||
                                         'Versamento con codici violazione contribuente ('||rec_errati.cod_fiscale||') sconosciuto',1000)||
                                    rec_errati.note
          where wkve.progressivo  = rec_errati.progressivo
         ;
      else
         w_pratica := F_F24_PRATICA(rec_errati.cod_fiscale_cont,rec_errati.id_operazione,rec_errati.data_pagamento,rec_errati.tipo_tributo);
         --
         -- Se il risultato della function è negativo, significa che la pratica
         -- non esiste oppure non è congruente con i dati indicati
         -- Si aggiornano il codice (50350) e il messaggio di errore
         -- Se il risultato della function è null, significa che non è stato
         -- indicato l'identificativo operazione, quindi il versamento viene
         -- gestito come prima (rimane in wrk_versamenti con codice 50200)
         -- (VD - 26/10/2018): Aggiunta gestione pratiche rateizzate.
         --                    Il codice e la descrizione dell'errore
         --                    vengono ricavate con apposita funzione.
         --
         if nvl(w_pratica,-1) < 0 then
            update wrk_versamenti wkve
               set wkve.cognome_nome = rec_errati.cognome_nome
                  -- (VD - 25/09/2018): nuova funzione di decodifica errore
                  --,wkve.causale      = decode(w_pratica,null,'50200'
                  --                                     ,-1  ,'50350'
                  --                                     ,-4  ,'50350'
                  --                                     ,-2  ,'50351'
                  --                                          ,'50352')
                  --,wkve.note         = rpad(decode(rec_errati.tipo_messaggio,'I','Imposta - '
                  --                                                          ,'S','Sanzioni e Interessi - '
                  --                                                              ,'')||
                  --                          decode(w_pratica,null,'Versamento con codici violazione senza Ravvedimento'
                  --                                          ,-1,  'Versamento con codici violazione Pratica non presente o incongruente'
                  --                                          ,-4,  'Versamento con codici violazione Pratica non presente o incongruente'
                  --                                          ,-2,  'Versamento con codici violazione Data Pagamento precedente a Data Notifica Pratica'
                  --                                               ,'Versamento con codici violazione Pratica non Notificata'),1000)||
                  --                     rec_errati.note
                  ,wkve.causale      = decode(w_pratica,null,'50200'
                                                       ,f_f24_causale_errore(w_pratica,'C'))
                  ,wkve.note         = rpad(decode(rec_errati.tipo_messaggio,'I','Imposta - '
                                                                            ,'S','Sanzioni e Interessi - '
                                                                                ,'')||
                                            decode(w_pratica,null,'Versamento con codici violazione senza Ravvedimento'
                                                                 ,f_f24_causale_errore(w_pratica,'D')),1000)||
                                       rec_errati.note
             where wkve.progressivo  = rec_errati.progressivo
            ;
         else
            --
            -- Arrivati a questo punto, la pratica e  sicuramente presente
            -- nell archivio pratiche ed è del tipo richiesto. Si estrapola
            -- l anno per evitare di inserire versamenti con anno diverso
            -- da quello della pratica
            -- (VD - 26/10/2018): aggiunta estrapolazione rata da
            --                    identificativo operazione per evitare
            --                    controlli inutili/sbagliat sui versamenti
            --
            --if afc.is_numeric(substr(rec_errati.id_operazione,5)) = 1 then
            --   w_anno_pratica := to_number(substr(rec_errati.id_operazione,5,4));
            --   w_rata_pratica := to_number(substr(rec_errati.id_operazione,9,2));
            --else
            --   w_anno_pratica := to_number(null);
            --   w_rata_pratica := 0;
            --end if;
            -- (VD - 02/05/2019): Modificata valorizzazione rata
            if nvl(w_pratica,0) > 0 then
               w_anno_pratica := to_number(substr(rec_errati.id_operazione,5,4));
               w_rata_pratica := to_number(substr(rec_errati.id_operazione,9,2));
            else
               w_anno_pratica := to_number(null);
               --
               -- (VD - 02/05/2019): modificata valorizzazione rata in
               --                    assenza di pratica di riferimento
               if rec_errati.rateazione is null then
                  w_rata_pratica := rec_errati.rata;
               else
                  if rec_errati.rateazione = '0101' then
                     w_rata_pratica := 0;
                  else
                     if afc.is_numeric(substr(rec_errati.rateazione,1,2)) = 1 then
                        w_rata_pratica := to_number(substr(rec_errati.rateazione,1,2));
                     else
                        w_rata_pratica := 1;
                     end if;
                  end if;
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
            if w_rata_pratica = 0 then
               BEGIN
                  select count(*)
                    into w_conta
                    from versamenti vers
                   where vers.cod_fiscale            = rec_errati.cod_fiscale_cont
                     and vers.anno                   = rec_errati.anno
                     and vers.tipo_tributo           = rec_errati.tipo_tributo
                     and vers.descrizione            = 'VERSAMENTO IMPORTATO DA MODELLO F24'
                     and vers.ufficio_pt             = rec_errati.ufficio_pt
                     and vers.data_pagamento         = rec_errati.data_pagamento
                     and vers.importo_versato        = rec_errati.importo_versato
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
                   where vers.cod_fiscale  = rec_errati.cod_fiscale_cont
                     and vers.anno         = nvl(w_anno_pratica,rec_errati.anno)
                     and vers.tipo_tributo = rec_errati.tipo_tributo
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
            if w_conta > 0 then
               begin
                   update wrk_versamenti wkve
                      set wkve.cognome_nome = rec_errati.cognome_nome
                         ,wkve.causale      = decode(w_rata_pratica,0,'50300','50362')
                         ,wkve.note         = rpad(decode(rec_errati.tipo_messaggio,'I','Imposta - '
                                                                                   ,'S','Sanzioni e Interessi - '
                                                                                       ,'')
                                                 ||decode(w_rata_pratica,0,'Versamento con codici violazione gia` Presente in data '||
                                                                           to_char(rec_errati.data_pagamento,'dd/mm/yyyy')
                                                                          ,'Pratica rateizzata: Rata gia'' versata'),1000)
                                                 ||rec_errati.note
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
               --
               BEGIN -- Assegnazione Numero Progressivo
                  select nvl(max(vers.sequenza),0)+1
                    into w_sequenza
                    from versamenti vers
                   where vers.cod_fiscale     = rec_errati.cod_fiscale_cont
                     and vers.anno            = nvl(w_anno_pratica,rec_errati.anno)
                     and vers.tipo_tributo    = rec_errati.tipo_tributo
                       ;
               END;
               BEGIN
                 insert into versamenti
                        (cod_fiscale
                        ,anno
                        ,pratica
                        ,tipo_tributo
                        ,sequenza
                        ,descrizione
                        ,ufficio_pt
                        ,data_pagamento
                        ,importo_versato
                        ,rata
                        ,fonte
                        ,utente
                        ,data_variazione
                        ,data_reg
                        ,note
                        ,documento_id
                        ,sanzioni_1
                        ,interessi
                        )
                  select rec_errati.cod_fiscale_cont
                        ,nvl(w_anno_pratica,rec_errati.anno)
                        ,w_pratica
                        ,rec_errati.tipo_tributo
                        ,w_sequenza
                        ,'VERSAMENTO IMPORTATO DA MODELLO F24'
                        ,rec_errati.ufficio_pt
                        ,rec_errati.data_pagamento
                        ,rec_errati.importo_versato
                        -- (VD - 25/09/2018): modifica per gestione pratiche
                        --                    rateizzate
                        --,rec_errati.rata
                        -- (VD - 02/05/2019): spostato controllo prima di insert
                        --,decode(w_rata_pratica
                        --       ,0,decode(rec_errati.rateazione
                        --                ,null  ,rec_errati.rata
                        --                ,'0101',0
                        --                       ,to_number(substr(rec_errati.rateazione,1,2))
                        --                )
                        --       )
                        ,w_rata_pratica
                        ,9
                        ,'F24'
                        ,trunc(sysdate)
                        ,rec_errati.data_reg
                        ,substr(trim(rec_errati.note_versamento)||';'||
                                trim(rec_errati.note),1,2000)
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
      if rec_vers.cod_fiscale is null then
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
               ,sanzioni_1
               ,interessi
               )
         values(w_progressivo
               ,rec_vers.tipo_tributo
               ,'F24'
               ,rec_vers.anno
               ,rec_vers.cod_fiscale_vers
               ,rec_vers.cognome_nome
               ,'50009'
               ,w_progressivo
               ,sysdate
               ,rpad('Sanzioni e Interessi - Contribuente ('||rec_vers.cod_fiscale_vers||') sconosciuto',1000)||
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
               ,rec_vers.importo_sanzioni
               ,rec_vers.importo_interessi
               );
      else
         w_pratica := F_F24_PRATICA(rec_vers.cod_fiscale,rec_vers.id_operazione,rec_vers.data_pagamento,rec_vers.tipo_tributo);
         if nvl(w_pratica,-1) < 0 then
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
                  ,sanzioni_1
                  ,interessi
                  )
            values(w_progressivo
                  ,rec_vers.tipo_tributo
                  ,'F24'
                  ,rec_vers.anno
                  ,rec_vers.cod_fiscale_vers
                  ,rec_vers.cognome_nome
                  -- (VD - 25/09/2018): nuova funzione di decodifica errore
                  --,decode(w_pratica,null,'50200'
                  --                 ,-1  ,'50350'
                  --                 ,-4  ,'50350'
                  --                 ,-2  ,'50351'
                  --                      ,'50352')
                  ,decode(w_pratica,null,'50200'
                                        ,f_f24_causale_errore(w_pratica,'C'))
                  ,w_progressivo
                  ,sysdate
                  -- (VD - 25/09/2018): nuova funzione di decodifica errore
                  --,rpad('Sanzioni e Interessi - '||
                  --      decode(w_pratica,null,'Versamento con codici violazione senza Ravvedimento'
                  --                      ,-1  ,'Versamento con codici violazione Pratica non presente o incongruente'
                  --                      ,-2  ,'Versamento con codici violazione Data Pagamento precedente a Data Notifica Pratica'
                  --                      ,-3  ,'Versamento con codici violazione Pratica non Notificata'
                  --                           ,'Denuncia non presente o incongruente'),1000)||
                  -- f_f24_note_versamento(rec_vers.id_operazione,to_number(null),'I',a_documento_id,rec_vers.tipo_tributo,to_char(null),rec_vers.rateazione)
                  ,rpad('Sanzioni e Interessi - '||
                        decode(w_pratica,null,'Versamento con codici violazione senza Ravvedimento'
                                             ,f_f24_causale_errore(w_pratica,'D')),1000)||
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
                  ,rec_vers.importo_sanzioni
                  ,rec_vers.importo_interessi
                  );
         else
            --
            -- Arrivati a questo punto, la pratica e  sicuramente presente
            -- nell archivio pratiche ed è del tipo richiesto. Si estrapola
            -- l anno per evitare di inserire versamenti con anno diverso
            -- da quello della pratica
            -- (VD - 26/10/2018): gestione pratiche rateizzate.
            --                    Si estrapola anche il numero rata
            --                    dall'identificativo operazione
            --if afc.is_numeric(substr(rec_vers.id_operazione,5)) = 1 then
            --   w_anno_pratica := to_number(substr(rec_vers.id_operazione,5,4));
            --   w_rata_pratica := to_number(substr(rec_vers.id_operazione,9,2));
            --else
            --   w_anno_pratica := to_number(null);
            --   w_rata_pratica := 0;
            --end if;            -- (VD - 02/05/2019): Modificata valorizzazione rata
            if nvl(w_pratica,0) > 0 then
               w_anno_pratica := to_number(substr(rec_vers.id_operazione,5,4));
               w_rata_pratica := to_number(substr(rec_vers.id_operazione,9,2));
            else
               w_anno_pratica := to_number(null);
               --
               -- (VD - 02/05/2019): modificata valorizzazione rata in
               --                    assenza di pratica di riferimento
               if rec_vers.rateazione = '0101' then
                  w_rata_pratica := 0;
               else
                  if afc.is_numeric(substr(rec_vers.rateazione,1,2)) = 1 then
                     w_rata_pratica := to_number(substr(rec_vers.rateazione,1,2));
                  else
                     w_rata_pratica := 1;
                  end if;
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
            if w_rata_pratica = 0 then
               BEGIN
                  select count(*)
                    into w_conta
                    from versamenti vers
                   where vers.cod_fiscale            = rec_vers.cod_fiscale
                     and vers.anno                   = rec_vers.anno
                     and vers.tipo_tributo           = rec_vers.tipo_tributo
                     and vers.descrizione            = rec_vers.descrizione
                     and vers.ufficio_pt             = rec_vers.ufficio_pt
                     and vers.data_pagamento         = rec_vers.data_pagamento
                     and vers.importo_versato        = rec_vers.importo_versato
                     and nvl(vers.pratica,-1)        = nvl(w_pratica,-1)
                  ;
               END;
            else
               begin
                  select count(*)
                    into w_conta
                    from versamenti vers
                   where vers.cod_fiscale  = rec_vers.cod_fiscale
                     and vers.anno         = nvl(w_anno_pratica,rec_vers.anno)
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
            if w_conta > 0 then
               w_progressivo := F_SELEZIONA_PROGRESSIVO;
   -- dbms_output.put_line('ins wrk2  '||w_progressivo||' '||SQLERRM);
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
                     ,sanzioni_1
                     ,interessi
                     )
               values(w_progressivo
                     ,rec_vers.tipo_tributo
                     ,'F24'
                     ,rec_vers.anno
                     ,rec_vers.cod_fiscale_vers
                     ,rec_vers.cognome_nome
                     ,decode(w_rata_pratica,0,'50000','50362')
                     ,w_progressivo
                     ,sysdate
                     ,rpad('Sanzioni e Interessi - '||decode(w_rata_pratica,0,'Versamento gia` Presente in data '||to_char(rec_vers.data_pagamento,'dd/mm/yyyy')
                                                                             ,'Pratica rateizzata: Rata gia'' versata'),1000)||
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
                     ,rec_vers.importo_sanzioni
                     ,rec_vers.importo_interessi
                     );
            else
               --
               -- Se tutti i controlli vengono superati, si inserisce la riga
               -- nella tabella VERSAMENTI
               --
               BEGIN -- Assegnazione Numero Progressivo
                  select nvl(max(vers.sequenza),0)+1
                    into w_sequenza
                    from versamenti vers
                   where vers.cod_fiscale     = rec_vers.cod_fiscale
                     and vers.anno            = nvl(w_anno_pratica,rec_vers.anno)
                     and vers.tipo_tributo    = rec_vers.tipo_tributo
                  ;
               END;
               BEGIN
   -- dbms_output.put_line('ins vers2 '||rec_vers.cod_fiscale||' '||SQLERRM);
                  insert into versamenti
                        (cod_fiscale
                        ,anno
                        ,pratica
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
                        ,rata
                        ,note
                        ,documento_id
                        ,sanzioni_1
                        ,interessi
                        )
                  select rec_vers.cod_fiscale
                        ,nvl(w_anno_pratica,rec_vers.anno)
                        ,w_pratica
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
                        -- (VD - 25/09/2018): gestione pratiche rateizzate
                        -- se si tratta di pratica rateizzata la rata si
                        -- ricava dall'identificativo operazione, altrimenti
                        -- si considera quella presente sul versamento
                        --,decode(rec_vers.rateazione,'0101',0,to_number(substr(rec_vers.rateazione,1,2)))
                        -- (VD - 02/05/2019): spostati controlli prima di insert
                        --,decode(w_rata_pratica
                        --       ,0,decode(rec_vers.rateazione
                        --                ,'0101',0
                        --                       ,to_number(substr(rec_vers.rateazione,1,2)))
                        --         ,w_rata_pratica
                        --       )
                        ,w_rata_pratica
                        ,f_f24_note_versamento(rec_vers.id_operazione,to_number(null),'I',a_documento_id,rec_vers.tipo_tributo,to_char(null),rec_vers.rateazione)
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
      -- (VD - 26/10/2018): aggiunta condizione di where su rateazione
      BEGIN
         delete wrk_tras_anci wkta
          where rtrim(substr(wkta.dati,50,16))      = rec_vers.cod_fiscale_vers
            and to_number(substr(wkta.dati,88,4))   = rec_vers.anno
            and wkta.anno                           = 2
            and substr(wkta.dati,79,4)  in ('3933','3934','3965','3966')  -- solo i versamenti su violazioni
            and to_number(substr(wkta.dati,126,1))  <> 1  -- si escludono i versamenti su ravvedimenti
            and substr(wkta.dati,260,1) in ('O','C')      -- TOSAP/COSAP e ICP
            and substr(wkta.dati,1,2)    = 'G1'           -- Si trattano solo i versamenti
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
/* End Procedure: CARICA_VERS_VIOL_TRMI_F24 */
/
