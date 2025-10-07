--liquibase formatted sql 
--changeset abrandolini:20250326_152423_carica_versamenti_tares_f24 stripComments:false runOnChange:true 
 
create or replace procedure CARICA_VERSAMENTI_TARES_F24
/*************************************************************************
 03/09/25  DM      #82789
                   Gestione codice tributo 3920
 16/03/23  VM      #55165 - Aggiunto parametro a_cod_fiscale.
                   Aggiunto filtro cod_fiscale su popolamento cursori.
 14/03/23  VM      #60197 - Aggiunto il parametro a_log_documento
                   che viene passato alla subprocedure per la
                   valorizzazione di eventuali errori
 24/06/21  VD      Modificata gestione contribuente assente: ora il
                   contribuente viene inserito anche in fase di caricamento
                   da file (sempre se esiste gia' il soggetto).
 07/04/21  VD      Modificata gestione contribuente assente:
                   aggiunti controlli per evitare l'inserimento
                   di NI già presenti in CONTRIBUENTI.
                   Creata funzione interna F_CHECK_VERSAMENTI per verificare
                   se il versamento che si sta caricando esiste gia',
                   richiamata al posto delle select nel trattamento dei
                   versamenti in bonifica e dei versamenti da file.
                   Creata funzione interna F_CHECK_RUOLI per verificare se
                   il contribuente e' iscritto a ruolo, richiamata nel
                   trattamento dei versamenti in bonifica e dei versamenti
                   da file.
 16/03/21  VD      Gestione nuovo codice tributo per TEFA
 11/01/21  VD      Gestione nuovo campo note_versamento della tabella
                   WRK_VERSAMENTI: il contenuto viene copiato nel campo
                   note della tabella VERSAMENTI.
 16/06/20  VD      Corretta gestione versamenti su violazione:
                   si trattano solo i versamenti in bonifica relativi
                   alle causali 50000, 50009 e 50010 (versamenti di imposta)
 09/09/19  VD      Corretta gestione rata su versamenti con rata diversa
                   nello stesso file
 25/09/18  VD      Modifiche per gestione versamenti su pratiche rateizzate
 16/07/18  VD/AB   Lasciato lo zero nella maggiorazione TARES solo per gli
                   anni in cui e' prevista. Altrimenti ltrim('0').
                   Modificato controllo su rata: in presenza del numero
                   pratica puo' valere da 0 a 36.
 21/07/17  VD      Corretto test numericita' rateazione; afc.is_numeric
                   restituisce 1 se il campo e' numerico e 0 se non lo e'
 10/04/17  VD      Modificato controllo su data pagamento in fase di
                   eliminazione: convertita in formato char la data di
                   confronto
 05/07/16  VD      Aggiunto caricamento revoche e ripristini
                   per tipo tributo TARSU
 15/06/16 VD       Aggiunto controllo tipo record in query principale:
                   si trattano solo i record G1 - versamenti
 01/06/16 VD       Aggiunto controllo numericita' rata per caricamento
                   versamenti
 04/12/15 VD       Aggiunta upper in selezione id_operazione
 30/01/15 VD       Aggiunto controllo su rata: se il valore indicato nel
                   file non è tra quelli previsti, si valorizza a 1
 29/01/15 VD       Aggiunta gesione id_operazione per ruolo (RUOL%)
 16/01/15 VD       Aggiunta gestione documento_id e nome_documento
 30/12/14 Betta    Modificato controllo su contribuente non attivo:
                   se abbiamo trovato la pratica non dobbiamo controllare se
                   il contribuente era a ruolo. Questo perchè potremmo aver
                   fatto solo un accertamento per omessa e quindi il
                   contribuente non figura a ruolo
 12/12/14 VD       Aggiunta gestione nuovo campo IDENTIFICATIVO_OPERAZIONE
                   In realtà nei versamenti "normali" tale identificativo
                   non viene gestito, quindi se è valorizzato ma la
                   pratica non esiste in PRATICHE_TRIBUTO, si considera null.
                   Viene comunque gestito l inserimento sia nella riga di
                   VERSAMENTI che in quella di WRK_VERSAMENTI.
 23/10/14 Betta T. Aggiunta nota per spiegare codici tributo utilizzati
 16/10/14 Betta T. La modifica di togliere la group by per rata aveva fatto
                   separare il versamento della maggiorazione tares
                   dal versamento dell imposta.
                   Ho modificato la select per prendere sempre la max rata
                   nel caso di maggiorazione TARES, così da versare la
                   maggiorazione insieme alla rata di saldo (se c è)
 15/10/14 Betta T. Controllo versamento gia inserito, non considerava la
                   rata per i versamenti errati (per quelli da wrk_tras_anci
                   il controllo era gia stato messo)
 14/10/14 Betta T. Cambiato il test su tipo imposta per modifiche al tracciato
                   del ministero
 25/09/14 Betta T. tolta group by per rata e data versamento
 Causali errore:   50000       Versamento gia  presente
                   50009       Contribuente sconosciuto
                   50010       Contribuente non attivo
                   --50350       Pratica non presente o incongruente
                   --50351       Data Pagamento precedente a Data Notifica Pratica
                   --50352       Pratica non Notificata
                   --50360       Pratica rateizzata: versamento antecedente
                   --            alla data di rateazione
                   --50361       Pratica rateizzata: rata errata
                   --50362       Pratica rateizzata: rata gia' versata
 Codici tributo usati
 Tributo:
 3944 - Tari -tassa sui rifiuti -articolo 1- comma 639-legge 147 del 27/12//2013 / tares - articolo 14, decreto legge n. 201 del 6/12//2011
 3950 - (TARI) Tariffa - articolo 1 comma 668 legge n.147 del 27/12/2013 / articolo 14, comma 29, decreto legge n. 201 del 6/12//2011
 365E - EP TARI -Tassa sui rifiuti - art.1,c.639,L.n.147/2013 - TARES - art. 14, d.l. n. 201/2011
 368E - EP (TARI) TARIFFA - art. 1, c.668, L. n.147/2013 - art. 14, c. 29, d.l. n. 201/2011
 Maggiorazione
 3955 - MAGGIORAZIONE - ART. 14, C. 13, D.L. N. 201/2011 E SUCC. MODIF
 371E - MAGGIORAZIONE - art. 14, c. 13, d.l. n. 201/2011 e succ. modif.
 Secondo me è ok. A meno di codici tributo che mancano.
 TEFA - TRIBUTO PER L'ESERCIZIO DELLE FUNZIONI DI TUTELA, PROTEZIONE E IGIENE DELL'AMBIENTE
*************************************************************************/
( a_documento_id            documenti_caricati.documento_id%type default null,
  a_cod_fiscale             in                                   varchar2 default '%',
  a_log_documento           in out                               varchar2)
IS
w_tipo_tributo              varchar2(5) := 'TARSU';
w_progressivo               number;
w_sequenza                  number;
w_conta                     number;
w_conta_cont                number;
w_ni                        number;
w_pratica                   number;
w_anno_pratica              number;
w_rata                      number;
w_ruolo                     number;
w_magg_tares                number;
w_cod_fiscale               varchar2(16);
w_errore                    varchar2(2000);
errore                      exception;
-- nella prima fase faccio diventare contribuenti i titolari dei versamenti
-- per cui è stato indicato il flag_contribuente
-- Lo lasciamo anche se per la Tarsu per ora non lo gestiamo (03/12/13) AB
-- (VD - 04/12/2015): Aggiunta upper in selezione id. operazione
-- (VD - 11/01/2021): Aggiunta selezione nuovo campo note_versamento
-- (VD - 16/03/2021): Aggiunta selezione addizionale_pro (TEFA)
cursor sel_ins_cont is
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
      ,wkve.flag_contribuente            flag_contribuente
      ,cont.cod_fiscale                  cod_fiscale_cont
      ,sogg.cognome_nome                 cognome_nome
      ,wkve.rata
      ,upper(wkve.identificativo_operazione)    id_operazione
      ,substr(wkve.note,1,1)                    tipo_messaggio
      ,wkve.documento_id
      ,wkve.sanzioni_1
      ,wkve.interessi
      ,wkve.sanzioni_add_pro
      ,wkve.interessi_add_pro
      ,wkve.note_versamento
  from wrk_versamenti wkve
      ,contribuenti   cont
      ,soggetti       sogg
 where wkve.tipo_incasso    = 'F24'
   and wkve.tipo_tributo    = w_tipo_tributo
   and wkve.causale         ='50009'-- contribuente sconosciuto
   and cont.cod_fiscale (+) = wkve.cod_fiscale
   and sogg.ni          (+) = cont.ni
   and nvl(wkve.flag_contribuente,'N') = 'S'
   and (cont.cod_fiscale like a_cod_fiscale or a_cod_fiscale = '%')
   ;
--
-- Esiste una fase iniziale di bonifica di eventuali anomalie presenti nella
-- tabella intermedia wrk_versamenti. Si tenta di ri-inserire il versamento;
-- se questo va a buon fine, allora si elimina la tabella wrk, altrimenti si
-- lascia la registrazione come in precedenza. Al massimo varia il motivo di
-- errore nel qual caso si cambiano la causale e le note.
--
-- (VD - 04/12/2015): Aggiunta upper in selezione id. operazione
-- (VD - 11/01/2021): Aggiunta selezione nuovo campo note_versamento
-- (VD - 16/03/2021): Aggiunta selezione addizionale_pro (TEFA)
cursor sel_errati is
select wkve.progressivo                  progressivo
      ,wkve.anno                         anno
      ,wkve.cod_fiscale                  cod_fiscale
      ,wkve.importo_versato              importo_versato
      ,wkve.causale                      causale
      ,wkve.addizionale_pro              addizionale_pro
      ,wkve.maggiorazione_tares          maggiorazione_tares
      ,wkve.fabbricati                   fabbricati
      ,wkve.tipo_versamento              tipo_versamento
      ,wkve.data_pagamento               data_pagamento
      ,wkve.ufficio_pt                   ufficio_pt
      ,wkve.data_reg                     data_reg
      ,wkve.flag_contribuente            flag_contribuente
      ,cont.cod_fiscale                  cod_fiscale_cont
      ,sogg.cognome_nome                 cognome_nome
      ,wkve.rata
      ,upper(wkve.identificativo_operazione)    id_operazione
      ,substr(wkve.note,1,1)                    tipo_messaggio
      ,wkve.documento_id
      ,wkve.sanzioni_1
      ,wkve.interessi
      ,wkve.sanzioni_add_pro
      ,wkve.interessi_add_pro
      ,wkve.note_versamento
  from wrk_versamenti wkve
      ,contribuenti   cont
      ,soggetti       sogg
 where wkve.tipo_incasso    = 'F24'
   and wkve.tipo_tributo    = w_tipo_tributo
   and wkve.causale         in ('50000','50009','50010','50350','50351','50352',
                                '50360','50361','50362')
   and cont.cod_fiscale (+) = wkve.cod_fiscale
   and sogg.ni          (+) = cont.ni
   and (cont.cod_fiscale like a_cod_fiscale or a_cod_fiscale = '%')
;
--
-- Il cursore esegue il raggruppamento per contribuente, anno, tipo di versamento
-- data versamento e rata
-- perche` viene fornito un dato per ogni tipologia di oggetto.
-- Anche se in realta` i seguenti dati dovrebbero essere gli stessi, nel caso di
-- ufficio_p, e data di registrazione vengono presi i valori massimi.
-- La eliminazione delle registrazioni di input inserite non avviene piu`
-- per progressivo (una riga alla volta), ma per raggruppamento trattato, ovvero
-- per contribuente, anno, tipo di versamento, data_versamento e rata.
-- Gli importi versati e le detrazioni sono sommati per ogni raggruppamento.
--
-- (VD - 11/12/2014): Modificato per gestire il nuovo campo identificativo
--                    operazione anche come raggruppamento
-- (VD - 04/12/2015): Aggiunta upper in selezione id. operazione
-- (VD - 15/06/2016): Aggiunto test su tipo record G1 - versamento
-- (VD - 16/03/2021): Aggiunta selezione importi per codice tributo TEFA
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
      ,'VERSAMENTO IMPORTATO DA MODELLO F24'             descrizione
      ,max(decode(substr(wkta.dati,44,1)
                 ,'B','Banca - ABI '||substr(wkta.dati,39,5)||' CAB '||substr(wkta.dati,45,5)
                 ,'C','Concessionario - Codice '||substr(wkta.dati,39,5)
                 ,'P','Poste - Codice '||substr(wkta.dati,39,5)
                 ,'I','Internet'
                     ,null
                 )
          )                                               ufficio_pt
      ,to_date(substr(wkta.dati,67,8),'yyyymmdd')    data_pagamento
      ,sum((to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100)
                                                          importo_versato
      ,sum(decode(substr(wkta.dati,79,4)
                 ,'3944',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,'3950',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,'365E',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,'368E',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,'3920',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,0
                 )
          )                                               importo
      ,sum(decode(substr(wkta.dati,79,4)
                 ,'3955',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,'371E',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,0
                 )
          )                                               maggiorazione_tares
      ,sum(decode(substr(wkta.dati,79,4)
                 ,'TEFA',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,0
                 )
          )                                               addizionale_pro
      ,decode(substr(wkta.dati,79,4)
             ,'3944',substr(wkta.dati,84,2)
             ,'3950',substr(wkta.dati,84,2)
             ,'365E',substr(wkta.dati,84,2)
             ,'368E',substr(wkta.dati,84,2)
             ,'TEFA',substr(wkta.dati,84,2)
             ,'3920',substr(wkta.dati,84,2)             
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
                 ,'3950',to_number(substr(wkta.dati,130,3))
                 ,'365E',to_number(substr(wkta.dati,130,3))
                 ,'368E',to_number(substr(wkta.dati,130,3))
                 ,'3920',to_number(substr(wkta.dati,130,3))                 
                 ,0
                 )
          )                                               fabbricati
  from wrk_tras_anci         wkta
      ,contribuenti          cont
      ,soggetti              sogg
      ,(select rtrim(substr(wkta.dati,50,16))             cod_fiscale
              ,to_number(substr(wkta.dati,88,4))          anno_rif
              ,to_date(substr(wkta.dati,67,8),'yyyymmdd') data_pagamento
              ,upper(rtrim(substr(wkta.dati,279,18)))     id_operazione
              ,max(decode(substr(wkta.dati,79,4)
                         ,'3944',substr(wkta.dati,84,2)
                         ,'3950',substr(wkta.dati,84,2)
                         ,'365E',substr(wkta.dati,84,2)
                         ,'368E',substr(wkta.dati,84,2)
                         ,'TEFA',substr(wkta.dati,84,2)
                         ,'3920',substr(wkta.dati,84,2)                         
                         ,''
                         )) rata
          from wrk_tras_anci         wkta
         where wkta.anno                = 2
           and substr(wkta.dati,79,4) in ('3944','3950','365E','368E','TEFA', '3920')  -- si prendono solo i codici tributo della TARES.
           and to_number(substr(wkta.dati,126,1))  <> 1                               -- si escludono i versamenti su ravvedimenti
           and substr(wkta.dati,260,1) in ('A','T')                                   -- TARSU/TARES/TARI il tracciato riportava T, ma nel file c è A
           and substr(wkta.dati,1,2) = 'G1'                                           -- Si trattano solo i versamenti
         group by  rtrim(substr(wkta.dati,50,16))                                     -- cod_fiscale
              ,to_number(substr(wkta.dati,88,4))                                      -- anno_rif
              ,upper(rtrim(substr(wkta.dati,279,18)))                                 -- id. operazione
              ,to_date(substr(wkta.dati,67,8),'yyyymmdd')                             -- data_pagamento
        ) max_rata
 where cont.cod_fiscale     (+) = rtrim(substr(wkta.dati,50,16))
   and sogg.ni              (+) = cont.ni
   and wkta.anno                = 2
   and substr(wkta.dati,79,4) in ('3944','3950','365E','368E','3955','371E','TEFA', '3920')  -- si prendono solo i codici tributo della TARES.
   and to_number(substr(wkta.dati,126,1))  <> 1      -- si escludono i versamenti su ravvedimenti
   and substr(wkta.dati,260,1) in ('A','T')          -- TARSU/TARES/TARI il tracciato riportava T, ma nel file c è A
   and rtrim(substr(wkta.dati,50,16)) = max_rata.cod_fiscale
   and to_number(substr(wkta.dati,88,4)) = max_rata.anno_rif
   and to_date(substr(wkta.dati,67,8),'yyyymmdd') = max_rata.data_pagamento
   and nvl(upper(rtrim(substr(wkta.dati,279,18))),'*') = nvl(max_rata.id_operazione,'*')
   and substr(wkta.dati,1,2) = 'G1'                  -- Si trattano solo i versamenti
 group by rtrim(substr(wkta.dati,50,16))             -- cod fiscale
         ,to_number(substr(wkta.dati,88,4))          -- anno rif
         ,to_date(substr(wkta.dati,67,8),'yyyymmdd') -- data vers.
         ,decode(substr(wkta.dati,128,2)
                ,'00','U','01','S','10','A','11','U',null
                )                                    -- acconto o saldo
         ,upper(rtrim(substr(wkta.dati,279,18)))     -- id. operazione
         ,decode(substr(wkta.dati,79,4)
             ,'3944',substr(wkta.dati,84,2)
             ,'3950',substr(wkta.dati,84,2)
             ,'365E',substr(wkta.dati,84,2)
             ,'368E',substr(wkta.dati,84,2)
             ,'TEFA',substr(wkta.dati,84,2)
             ,'3920',substr(wkta.dati,84,2)             
             ,'3955',max_rata.rata
             ,'371E',max_rata.rata
             ,''
             )                                       -- rata
 order by min(wkta.progressivo)
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
function F_SELEZIONA_PROGRESSIVO
return number
is
  nProgr    number;
begin
  begin
    select nvl(max(progressivo),0)
      into nProgr
      from wrk_versamenti
    ;
  exception
    when no_data_found then
      nProgr := 0;
  end;
  nprogr := nprogr + 1;
  return nprogr;
end F_SELEZIONA_PROGRESSIVO;
------------------------------------
-- Funzione  F_CHECK_VERSAMENTI
------------------------------------
function F_CHECK_VERSAMENTI
( p_cod_fiscale                     varchar2
, p_anno                            number
, p_tipo_tributo                    varchar2
, p_tipo_versamento                 varchar2
, p_descrizione                     varchar2
, p_ufficio_pt                      varchar2
, p_data_pagamento                  date
, p_importo_versato                 number
, p_rata                            number
, p_pratica                         number
) return number
is
  w_conta                           number;
begin
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
        and nvl(vers.rata,999)          = nvl(p_rata,999)
        and nvl(vers.pratica,-1)        = nvl(p_pratica,-1)
     ;
  EXCEPTION
     WHEN others THEN
          w_errore := 'Errore in conteggio versamenti'||
                      ' di '||p_cod_fiscale||'/'||p_tipo_tributo||
                      '/'||p_anno||' ('||sqlerrm||')';
          RAISE errore;
  END;
  --
  return w_conta;
  --
end;
------------------------------------
-- Funzione  F_CHECK_RUOLI
------------------------------------
function F_CHECK_RUOLI
( p_cod_fiscale                     varchar2
, p_anno                            number
, p_tipo_tributo                    varchar2
) return number
is
  w_conta             number;
begin
  BEGIN
     select count(*)
       into w_conta
       from ruoli ruol, ruoli_contribuente ruco
      where ruco.cod_fiscale            = p_cod_fiscale
        and ruol.anno_ruolo             = p_anno
        and ruol.tipo_tributo           = p_tipo_tributo
        and ruol.ruolo                  = ruco.ruolo
        and ruol.invio_consorzio        is not null
     ;
  END;
  --
  return w_conta;
  --
end;
---------------------------
--  INIZIO ELABORAZIONE  --
---------------------------
begin
-- dbms_output.put_line('Siamo entrati nella Procedure, quindi l''errore e'' qui...'||SQLERRM);
--
-- Si trattano i contribuenti precedentemente scartati e successivamente
-- confermati da operatore
--
  for rec_ins_cont in sel_ins_cont  -- gestione flag_contribuente
  loop
    -- (VD - 08/04/2021): modificata gestione inserimento contribuente con
    --                    nuova funzione F_CREA_CONTRIBUENTE
    if rec_ins_cont.cod_fiscale_cont is null then
       w_cod_fiscale := f_crea_contribuente(rec_ins_cont.cod_fiscale,w_errore);
       if w_cod_fiscale is null then
          if w_errore is not null then
             update wrk_versamenti wkve
                set note = substr(decode(note,'','',note||' - ')||w_errore,1,2000)
              where wkve.progressivo  = rec_ins_cont.progressivo;
          end if;
          goto fine_tratta_ins_cont;
       end if;
       -- (VD - 08/04/2021): Ripristinato controllo su pratica per
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
       --
       -- Se il risultato della function è negativo, significa che la pratica
       -- non esiste oppure non è congruente con i dati indicati.
       if nvl(w_pratica,0) < 0 then
          begin
            update wrk_versamenti wkve
               set wkve.causale      = f_f24_causale_errore(nvl(w_pratica,-1),'C')
                  ,wkve.note         = decode(rec_ins_cont.tipo_messaggio,'I','Imposta - '
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
          goto fine_tratta_ins_cont;
       end if;
       --
       if w_pratica is not null then
          w_ruolo := to_number(null);
          if afc.is_numeric(substr(rec_ins_cont.id_operazione,5,4)) = 1 then
             w_anno_pratica := to_number(substr(rec_ins_cont.id_operazione,5,4));
          else
             w_anno_pratica := to_number(null);
          end if;
          if afc.is_numeric(substr(rec_ins_cont.id_operazione,9,2)) = 1 then
             w_rata := to_number(substr(rec_ins_cont.id_operazione,9,2));
          end if;
          if nvl(w_rata,0) = 0 then
             w_rata := nvl(rec_ins_cont.rata,0);
          end if;
       else
          -- Se la pratica e' nulla, si controlla se il contribuente e'
          -- inserito a ruolo per l'anno del versamento
          w_conta := F_CHECK_RUOLI ( rec_ins_cont.cod_fiscale
                                   , rec_ins_cont.anno
                                   , w_tipo_tributo
                                   );
          if w_conta = 0 then
             begin
               update wrk_versamenti wkve
                  set wkve.causale      = '50010'
                     ,wkve.note         = decode(rec_ins_cont.tipo_messaggio
                                                ,'I','Imposta - '
                                                ,'S','Sanzioni e Interessi - '
                                                ,'')||
                                          'Contribuente da Sconosciuto a non Attivo'
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
             goto fine_tratta_ins_cont;
          else
             --
             -- Si controlla la validità del numero rata per l'inserimento
             -- in tabella VERSAMENTI
             --
             w_anno_pratica := to_number(null);
             if rec_ins_cont.id_operazione like 'RUOL%' then
                w_ruolo := f_f24_ruolo(rec_ins_cont.id_operazione);
                if w_ruolo is not null and
                   afc.is_numeric(substr(rec_ins_cont.id_operazione,9,2)) = 1 then
                   w_rata := to_number(substr(rec_ins_cont.id_operazione,9,2));
                else
                   w_rata := nvl(rec_ins_cont.rata,0);
                end if;
             else
                w_ruolo := to_number(null);
                w_rata := nvl(rec_ins_cont.rata,0);
             end if;
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
       w_magg_tares := F_CATA_MAGG_TARES(rec_ins_cont.anno);
       w_sequenza := to_number(null);
       --VERSAMENTI_NR ( rec_ins_cont.cod_fiscale, nvl(w_anno_pratica,rec_ins_cont.anno)
       VERSAMENTI_NR ( w_cod_fiscale, nvl(w_anno_pratica,rec_ins_cont.anno)
                     , w_tipo_tributo, w_sequenza );
       --dbms_output.put_line('Ins versamenti: cf '||rec_ins_cont.cod_fiscale||' '||SQLERRM);
       -- (VD - 16/03/2021): Aggiunto inserimento addizionale_pro (TEFA)
       begin
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
              ,sanzioni_1
              ,interessi
              ,sanzioni_add_pro
              ,interessi_add_pro
              )
        values(w_cod_fiscale --rec_ins_cont.cod_fiscale
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
              ,'F24'
              ,trunc(sysdate)
              ,rec_ins_cont.data_reg
              ,rec_ins_cont.fabbricati
              ,w_rata
              ,w_ruolo
              ,case
                 when rec_ins_cont.anno < 2021 then to_number(null)
                 else rec_ins_cont.addizionale_pro
               end
              -- ,decode(w_magg_tares,null,to_number(null),rec_ins_cont.maggiorazione_tares)
              ,decode(w_magg_tares,null,to_number(ltrim(rec_ins_cont.maggiorazione_tares,'0')),rec_ins_cont.maggiorazione_tares)
              -- (VD - 11/01/2021): aggiunto campo note_versamento per
              --                    composizione note
              ,f_f24_note_versamento(rec_ins_cont.id_operazione
                                    ,w_pratica
                                    ,rec_ins_cont.tipo_messaggio
                                    ,rec_ins_cont.documento_id
                                    ,w_tipo_tributo
                                    ,null
                                    ,null
                                    ,rec_ins_cont.note_versamento
                                    )
              ,rec_ins_cont.documento_id
              ,rec_ins_cont.sanzioni_1
              ,rec_ins_cont.interessi
              ,case
                 when nvl(w_anno_pratica,rec_ins_cont.anno) < 2021 then to_number(null)
                 else rec_ins_cont.sanzioni_add_pro
               end
              ,case
                 when nvl(w_anno_pratica,rec_ins_cont.anno) < 2021 then to_number(null)
                 else rec_ins_cont.interessi_add_pro
               end
              )
              ;
       exception
         when others then
           --CONTRIBUENTI_CHK_DEL(rec_ins_cont.cod_fiscale,null);
           CONTRIBUENTI_CHK_DEL(w_cod_fiscale,null);
           w_errore := 'Errore in inserimento versamento bonificato'||
                       ' di '||w_cod_fiscale||' progressivo '||
                       to_char(rec_ins_cont.progressivo)||' ('||sqlerrm||')';
           raise errore;
       END;
       --dbms_output.put_line('del wrk '||rec_ins_cont.progressivo||' '||SQLERRM);
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
    << fine_tratta_ins_cont >>
    null;
  end loop;    -- gestione flag_contribuente
-----------------------------------------------------------
-- Trattamento versamenti errati da tabella WRK_VERSAMENTI
-----------------------------------------------------------
   FOR rec_errati IN sel_errati
   LOOP
     if rec_errati.cod_fiscale_cont is null then
        --dbms_output.put_line('upd wrk 50009 '||rec_errati.progressivo||' '||SQLERRM);
        update wrk_versamenti wkve
           set wkve.cognome_nome = rec_errati.cognome_nome
              ,wkve.causale      = '50009'
              ,wkve.note         = decode(rec_errati.tipo_messaggio,'I','Imposta - '
                                                                   ,'S','Sanzioni e Interessi - '
                                                                       ,'')||
                                   'Contribuente ('||rec_errati.cod_fiscale||') sconosciuto'
         where wkve.progressivo  = rec_errati.progressivo
        ;
        goto fine_tratta_errati;
     end if;
     -- Si verifica se il versamento si riferisce ad una pratica (accertamento?)
     w_pratica := F_F24_PRATICA(rec_errati.cod_fiscale,rec_errati.id_operazione,rec_errati.data_pagamento,w_tipo_tributo);
     --
     -- Se il risultato della function è negativo, significa che la pratica
     -- non esiste oppure non è congruente con i dati indicati.
     if nvl(w_pratica,0) < 0 then
        begin
          update wrk_versamenti wkve
             set wkve.cognome_nome = rec_errati.cognome_nome
                -- (VD - 25/09/2018): nuova funzione di decodifica errore
                --,wkve.causale      = decode(w_pratica,-1  ,'50350'
                --                                     ,-2  ,'50351'
                --                                          ,'50352')
                --,wkve.note         = decode(rec_errati.tipo_messaggio,'I','Imposta - '
                --                                                     ,'S','Sanzioni e Interessi - '
                --                                                         ,'')||
                --                     decode(w_pratica,-1  ,'Versamento con codici violazione Pratica non presente o incongruente'
                --                                     ,-2  ,'Versamento con codici violazione Data Pagamento precedente a Data Notifica Pratica'
                --                                          ,'Versamento con codici violazione Pratica non Notificata')
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
        goto fine_tratta_errati;
     end if;
     --
     if w_pratica is not null then
        w_ruolo := to_number(null);
        if afc.is_numeric(substr(rec_errati.id_operazione,5,4)) = 1 then
           w_anno_pratica := to_number(substr(rec_errati.id_operazione,5,4));
        else
           w_anno_pratica := to_number(null);
        end if;
        if afc.is_numeric(substr(rec_errati.id_operazione,9,2)) = 1 then
           w_rata := to_number(substr(rec_errati.id_operazione,9,2));
        end if;
        if nvl(w_rata,0) = 0 then
           w_rata := nvl(rec_errati.rata,0);
        end if;
     else
        -- Se la pratica e' nulla, si controlla se il contribuente e'
        -- inserito a ruolo per l'anno del versamento
        w_conta := F_CHECK_RUOLI ( rec_errati.cod_fiscale
                                 , rec_errati.anno
                                 , w_tipo_tributo
                                 );
        if w_conta = 0 then
           begin
             update wrk_versamenti wkve
                set wkve.causale      = '50010'
                   ,wkve.note         = decode(rec_errati.tipo_messaggio,'I','Imposta - '
                                                                        ,'S','Sanzioni e Interessi - '
                                                                            ,'')||
                                        decode(rec_errati.causale,'50009','Contribuente da Sconosciuto a non Attivo'
                                                                         ,'Contribuente da Vers gia'' presente a non Attivo')
                   ,wkve.flag_contribuente = NULL
              where wkve.progressivo  = rec_errati.progressivo
                  and wkve.causale    = rec_errati.causale
             ;
           EXCEPTION
             WHEN others THEN
                w_errore := 'Errore in update wrk_versamenti'||
                            ' di '||rec_errati.cod_fiscale||' progressivo '||
                            to_char(rec_errati.progressivo)||' ('||sqlerrm||')';
                RAISE errore;
           end;
           goto fine_tratta_errati;
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
              end if;
              if nvl(w_rata,0) = 0 then
                 w_rata := nvl(rec_errati.rata,0);
              end if;
           else
              w_ruolo := to_number(null);
              w_rata := nvl(rec_errati.rata,0);
           end if;
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
     -- Controllo esistenza versamento
     w_conta := F_CHECK_VERSAMENTI ( rec_errati.cod_fiscale
                                   , rec_errati.anno
                                   , w_tipo_tributo
                                   , rec_errati.tipo_versamento
                                   , 'VERSAMENTO IMPORTATO DA MODELLO F24'
                                   , rec_errati.ufficio_pt
                                   , rec_errati.data_pagamento
                                   , rec_errati.importo_versato
                                   , w_rata
                                   , w_pratica
                                   );
     --
     if w_conta > 0 then  -- conta versamenti uguali
        --dbms_output.put_line('upd wrk 50000 '||rec_errati.progressivo||' '||SQLERRM);
        begin
          update wrk_versamenti wkve
             set wkve.cognome_nome = rec_errati.cognome_nome
                ,wkve.causale      = '50000'
                ,wkve.note         = decode(rec_errati.tipo_messaggio,'I','Imposta - '
                                                                     ,'S','Sanzioni e Interessi - '
                                                                         ,'')||
                                     'Versamento gia` Presente in data '||
                                     to_char(rec_errati.data_pagamento,'dd/mm/yyyy')
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
        -- Controlli superati: si inserisce il versamento
        w_sequenza := to_number(null);
        VERSAMENTI_NR ( rec_errati.cod_fiscale, nvl(w_anno_pratica,rec_errati.anno)
                      , w_tipo_tributo, w_sequenza);
        -- (VD - 16/07/2018): si verifica se per l'anno del versamento
        --                    e' prevista la maggiorazione TARES
        w_magg_tares := F_CATA_MAGG_TARES(nvl(w_anno_pratica,rec_errati.anno));
        -- (VD - 16/03/2021): Aggiunto inserimento addizionale_pro (TEFA)
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
                    ,sanzioni_1
                    ,interessi
                    ,sanzioni_add_pro
                    ,interessi_add_pro
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
                    -- ,decode(w_magg_tares,null,to_number(null),rec_errati.maggiorazione_tares)
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
                    ,rec_errati.sanzioni_1
                    ,rec_errati.interessi
                    ,case
                       when rec_errati.anno < 2021 then to_number(null)
                       else rec_errati.sanzioni_add_pro
                     end
                    ,case
                       when rec_errati.anno < 2021 then to_number(null)
                       else rec_errati.interessi_add_pro
                     end
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
     end if;    -- w_conta > 0 versamenti uguali
     << fine_tratta_errati>>
     null;
   END LOOP;
------------------------------------------------------------
-- Trattamento versamenti caricati in tabella WRK_TRAS_ANCI
------------------------------------------------------------
   FOR rec_vers IN sel_vers
   LOOP
     --
     -- Se il codice fiscale del contribuente è nullo, significa che il contribuente
     -- non esiste in tabella CONTRIBUENTI. Si inserisce il versamento in
     -- WRK_VERSAMENTI con il codice (50009) e il messaggio di errore
     -- (VD - 16/03/2021): Aggiunto inserimento addizionale_pro (TEFA)
     -- (VD - 24/06/2021): se il contribuente non esiste ma esiste un
     --                    soggetto con lo stesso codice fiscale, si crea
     --                    un nuovo contribuente
     --
     --
      if rec_vers.cod_fiscale is null then
         w_cod_fiscale := f_crea_contribuente(rec_vers.cod_fiscale_vers,w_errore);
         if w_cod_fiscale is null then
            w_progressivo := F_SELEZIONA_PROGRESSIVO;
            insert into wrk_versamenti
                  (progressivo,tipo_tributo,tipo_incasso,anno,ruolo,
                   cod_fiscale,cognome_nome,
                   causale,
                   disposizione,data_variazione,
                   note,
                   tipo_versamento,ufficio_pt,data_pagamento,
                   data_reg,fabbricati,importo_versato
                  ,rata
                  ,addizionale_pro
                  ,maggiorazione_tares
                  ,identificativo_operazione
                  ,documento_id)
            values(w_progressivo,w_tipo_tributo,'F24',rec_vers.anno,null,
                   rec_vers.cod_fiscale_vers,
                   rec_vers.cognome_nome,'50009',w_progressivo,sysdate,
                   'Imposta - Contribuente ('||rec_vers.cod_fiscale_vers||') sconosciuto',
                   rec_vers.tipo_versamento,rec_vers.ufficio_pt,rec_vers.data_pagamento,
                   rec_vers.data_reg,rec_vers.fabbricati,rec_vers.importo_versato
                  ,rec_vers.rateazione
                  ,rec_vers.addizionale_pro
                  ,rec_vers.maggiorazione_tares
                  ,rec_vers.id_operazione
                  ,a_documento_id);
            goto fine_tratta_vers;
         end if;
      else
         w_cod_fiscale := rec_vers.cod_fiscale;
      end if;
      --w_pratica := F_F24_PRATICA(rec_vers.cod_fiscale,rec_vers.id_operazione,rec_vers.data_pagamento,w_tipo_tributo);
      w_pratica := F_F24_PRATICA(w_cod_fiscale,rec_vers.id_operazione,rec_vers.data_pagamento,w_tipo_tributo);
      --
      -- Se il risultato della function è negativo, significa che la pratica
      -- non esiste oppure non è congruente con i dati indicati.
      -- Se invece e' null, significa che non si tratta di una pratica
      -- di accertamento ma potrebbe essere un ruolo
      --
      if nvl(w_pratica,0) < 0 then
         -- (VD - 16/03/2021): Aggiunto inserimento addizionale_pro (TEFA)
         w_progressivo := F_SELEZIONA_PROGRESSIVO;
         insert into wrk_versamenti
               (progressivo,tipo_tributo,tipo_incasso,anno,ruolo,
                cod_fiscale,cognome_nome,
                causale,
                disposizione,data_variazione,
                note,
                tipo_versamento,ufficio_pt,data_pagamento,
                data_reg,fabbricati,importo_versato
               ,rata
               ,addizionale_pro
               ,maggiorazione_tares
               ,identificativo_operazione
               ,documento_id)
         values(w_progressivo,w_tipo_tributo,'F24',rec_vers.anno,null,
                rec_vers.cod_fiscale_vers,rec_vers.cognome_nome,
                -- (VD - 25/09/2018): nuova funzione di decodifica errore
                --decode(w_pratica,-1,'50350'
                --                ,-2,'50351'
                --                   ,'50352'),
                f_f24_causale_errore(w_pratica,'C'),
                w_progressivo,sysdate,
                -- (VD - 25/09/2018): nuova funzione di decodifica errore
                --decode(w_pratica,null,'','Imposta - ')||
                --decode(w_pratica,-1,'Versamento con codici violazione Pratica non presente o incongruente'
                --                ,-2,'Versamento con codici violazione Data Pagamento precedente a Data Notifica Pratica'
                --                   ,'Versamento con codici violazione Pratica non Notificata'),
                'Imposta - '||f_f24_causale_errore(w_pratica,'D'),
                rec_vers.tipo_versamento,rec_vers.ufficio_pt,rec_vers.data_pagamento,
                rec_vers.data_reg,rec_vers.fabbricati,rec_vers.importo_versato
               ,rec_vers.rateazione
               ,rec_vers.addizionale_pro
               ,rec_vers.maggiorazione_tares
               ,rec_vers.id_operazione
               ,a_documento_id);
         goto fine_tratta_vers;
      end if;
      if nvl(w_pratica,0) > 0 then
         -- se abbiamo trovato la pratica non dobbiamo controllare se il contribuente era
         -- a ruolo. Questo perchè potremmo aver fatto solo un accertamento per omessa
         -- e quindi il contribuente non figura a ruolo
         w_ruolo := to_number(null);
         w_rata  := 0;
         w_anno_pratica := to_number(substr(rec_vers.id_operazione,5,4));
         if afc.is_numeric(substr(rec_vers.id_operazione,9,2)) = 1 then
            w_rata := to_number(substr(rec_vers.id_operazione,9,2));
         end if;
         if w_rata = 0 then
            w_rata := nvl(rec_vers.rateazione,0);
         end if;
      else
         w_anno_pratica := to_number(null);
         w_conta := F_CHECK_RUOLI ( rec_vers.cod_fiscale
                                  , rec_vers.anno
                                  , rec_vers.tipo_tributo
                                  );
         if w_conta = 0 then
            w_progressivo := F_SELEZIONA_PROGRESSIVO;
            --   dbms_output.put_line('ins wrk3  '||w_progressivo||' '||SQLERRM);
            -- (VD - 16/03/2021): Aggiunto inserimento addizionale_pro (TEFA)
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
                  ,documento_id)
            values(w_progressivo,w_tipo_tributo,'F24',rec_vers.anno,null,rec_vers.cod_fiscale_vers,
                   rec_vers.cognome_nome,'50010',w_progressivo,sysdate,
                   'Contribuente non Attivo',
                   rec_vers.tipo_versamento,rec_vers.ufficio_pt,rec_vers.data_pagamento,
                   rec_vers.data_reg,rec_vers.fabbricati,rec_vers.importo_versato
                  ,rec_vers.rateazione
                  ,rec_vers.addizionale_pro
                  ,rec_vers.maggiorazione_tares
                  ,rec_vers.id_operazione
                  ,a_documento_id);
            goto fine_tratta_vers;
         end if;
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
               if w_rata = 0 then
                  w_rata := nvl(rec_vers.rateazione,0);
               end if;
            else
               w_rata := nvl(rec_vers.rateazione,0);
            end if;
         else
            w_ruolo := to_number(null);
            w_rata  := nvl(rec_vers.rateazione,0);
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
      -- Controllo esistenza versamenti
      w_conta := F_CHECK_VERSAMENTI ( w_cod_fiscale --rec_vers.cod_fiscale
                                    , rec_vers.anno
                                    , rec_vers.tipo_tributo
                                    , rec_vers.tipo_versamento
                                    , rec_vers.descrizione
                                    , rec_vers.ufficio_pt
                                    , rec_vers.data_pagamento
                                    , rec_vers.importo_versato
                                    , w_rata
                                    , w_pratica
                                    );
      if w_conta > 0 then
         -- (VD - 16/03/2021): Aggiunto inserimento addizionale_pro (TEFA)
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
               ,documento_id)
         values(w_progressivo,w_tipo_tributo,'F24',rec_vers.anno,null,rec_vers.cod_fiscale_vers,
                rec_vers.cognome_nome,'50000',w_progressivo,sysdate,
                decode(w_pratica,null,'','Imposta - ')||'Versamento gia` Presente in data '||to_char(rec_vers.data_pagamento,'dd/mm/yyyy'),
                rec_vers.tipo_versamento,rec_vers.ufficio_pt,rec_vers.data_pagamento,
                rec_vers.data_reg,rec_vers.fabbricati,rec_vers.importo_versato
               ,rec_vers.rateazione
               ,rec_vers.addizionale_pro
               ,rec_vers.maggiorazione_tares
               ,rec_vers.id_operazione
               ,a_documento_id);
      else
         --
         -- (VD - 16/07/2018): si verifica se per l'anno del versamento
         --                    e' prevista la maggiorazione TARES
         w_magg_tares := F_CATA_MAGG_TARES(nvl(w_anno_pratica,rec_vers.anno));
         w_sequenza := to_number(null);
         --VERSAMENTI_NR ( rec_vers.cod_fiscale, nvl(w_anno_pratica,rec_vers.anno)
         VERSAMENTI_NR ( w_cod_fiscale, nvl(w_anno_pratica,rec_vers.anno)
                       , rec_vers.tipo_tributo, w_sequenza );
         -- (VD - 16/03/2021): Aggiunto inserimento addizionale_pro (TEFA)
         BEGIN
            --   dbms_output.put_line('ins vers2 '||rec_vers.cod_fiscale||' '||SQLERRM);
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
                  ,rec_vers.utente
                  ,rec_vers.data_variazione
                  ,rec_vers.data_reg
                  ,rec_vers.fabbricati
                  ,w_rata
                  ,w_ruolo
                  ,case
                     when nvl(w_anno_pratica,rec_vers.anno) < 2021 then to_number(null)
                     else rec_vers.addizionale_pro
                   end
                  -- ,decode(w_magg_tares,null,to_number(null),rec_vers.maggiorazione_tares)
                  ,decode(w_magg_tares,null,to_number(ltrim(rec_vers.maggiorazione_tares,'0')),rec_vers.maggiorazione_tares)
                  ,f_f24_note_versamento(rec_vers.id_operazione
                                        ,w_pratica
                                        ,'I'
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
      << fine_tratta_vers >>
      BEGIN
         -- dbms_output.put_line('del wrk_tra'||rec_vers.cod_fiscale_vers||' '||SQLERRM);
         delete wrk_tras_anci wkta
          where rtrim(substr(wkta.dati,50,16))      = rec_vers.cod_fiscale_vers
            and to_number(substr(wkta.dati,88,4))   = rec_vers.anno
            and wkta.anno                           = 2
            and substr(wkta.dati,79,4) in ('3944','3950','365E','368E','3955','371E','TEFA', '3920')  -- si prendono solo i codici tributo TARES.
            and substr(wkta.dati,1,2) = 'G1'              -- si trattano solo i versamenti
            and to_number(substr(wkta.dati,126,1)) <> 1   -- si escludono i versamenti su ravvedimenti
            and substr(wkta.dati,260,1) in ('A','T')      -- TARSU/TARES il tracciato riportava T, ma nel file c è A
            --and to_date(substr(wkta.dati,67,8),'yyyymmdd') = rec_vers.data_pagamento
            and substr(wkta.dati,67,8) = to_char(rec_vers.data_pagamento,'yyyymmdd')
            and decode(substr(wkta.dati,128,2)
                      ,'00','U','01','S','10','A','11','U',null
                      ) = rec_vers.tipo_versamento
            and nvl(upper(rtrim(substr(wkta.dati,279,18))),'*') = nvl(rec_vers.id_operazione,'*')
            and nvl(decode(substr(wkta.dati,79,4)
                          ,'3944',substr(wkta.dati,84,2)
                          ,'3950',substr(wkta.dati,84,2)
                          ,'365E',substr(wkta.dati,84,2)
                          ,'368E',substr(wkta.dati,84,2)
                          ,'TEFA',substr(wkta.dati,84,2)
                          ,'3920',substr(wkta.dati,84,2)                          
                          ,'3955',decode(rec_vers.maggiorazione_tares,null,'',rec_vers.rateazione)
                          ,'371E',decode(rec_vers.maggiorazione_tares,null,'',rec_vers.rateazione)
                          ,''
                          ),999)  = nvl(rec_vers.rateazione,999)
         ;
      -- N.B. Per la magg. dobbiamo cancellare il record quando trattiamo quello del versamento associato
      EXCEPTION
         WHEN others THEN
            w_errore := 'Errore in eliminazione wrk_tras_anci - 1'||
                        ' progressivo '||to_char(rec_vers.progressivo)||
                        ' cf '||to_char(rec_vers.cod_fiscale_vers)||
                        ' ('||sqlerrm||')';
            RAISE errore;
      END;
   END LOOP;
----------------------------------------------------
-- Trattamento dei versamenti su ravvedimento
----------------------------------------------------
CARICA_VERS_RAVV_TARES_F24 (a_documento_id, a_cod_fiscale);
----------------------------------------------------
-- Trattamento dei versamenti su violazioni
----------------------------------------------------
CARICA_VERS_VIOL_TARES_F24 (a_documento_id, a_cod_fiscale, a_log_documento);
--------------------------------------------------------
-- (VD - 05/07/2016) Trattamento di revoche e ripristini
--------------------------------------------------------
CARICA_ANNULLAMENTI_F24 (a_documento_id, w_tipo_tributo, a_cod_fiscale);
EXCEPTION
   WHEN errore THEN
      RAISE_APPLICATION_ERROR(-20999,w_errore);
END;
/* End Procedure: CARICA_VERSAMENTI_TARES_F24 */
/
