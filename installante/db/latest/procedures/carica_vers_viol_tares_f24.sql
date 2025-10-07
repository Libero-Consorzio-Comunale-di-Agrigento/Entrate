--liquibase formatted sql 
--changeset abrandolini:20250326_152423_carica_vers_viol_tares_f24 stripComments:false runOnChange:true 
 
create or replace procedure CARICA_VERS_VIOL_TARES_F24
/*************************************************************************
 03/09/25  DM      #82789
                   Gestione codice tributo 3920
 16/03/23   VM     #55165 - Aggiunto parametro a_cod_fiscale.
                   Aggiunto filtro cod_fiscale su popolamento cursori.
 14/03/23  VM      #60197 - Aggiunto il parametro a_log_documento.
                   Dopo l'inserimento del versamento viene lanciato
                   controllo per popolare il messaggio se presenti
                   ruoli coattivi su sanzioni pratica.
 16/03/21  VD      Gestione nuovo codice tributo per TEFA
 11/01/21  VD      Gestione nuovo campo note_versamento della tabella
                   WRK_VERSAMENTI: il contenuto viene copiato nel campo
                   note della tabella VERSAMENTI.
 29/04/19  VD      Corretta gestione campo rateazione con spazi: allineate
                   condizioni di where della delete da wrk_tras_anci.
 29/01/19  VD      Corretto inserimento rateazione in wrk_versamenti per
                   versamento gia' presente.
 16/07/18  VD/AB   Lasciato lo zero nella maggiorazione TARES solo per gli
                   anni in cui e' prevista. Altrimenti ltrim('0').
                   Modificato controllo su rata: in presenza del numero
                   pratica puo' valere da 0 a 36.
 21/07/17  VD      Corretto test numericita' rateazione; afc.is_numeric
                   restituisce 1 se il campo e' numerico e 0 se non lo e'
 10/04/17  VD      Modificato controllo su data pagamento in fase di
                   eliminazione: convertita in formato char la data di
                   confronto
 15/06/16  VD      Aggiunto controllo tipo record in query principale:
                   si trattano solo i record G1 - versamenti
 04/12/15  VD      Aggiunta upper in selezione id_operazione
 01/02/15  VD      Aggiunta gestione identificativo di tipo "RUOL%"
 30/01/15  VD      Aggiunto controllo su rata: se il valore indicato nel
                   file non è tra quelli previsti, si valorizza a 1
 16/01/15  VD      Aggiunta gestione documento_id e nome_documento
 12/12/14  VD      Aggiunta gestione nuovo campo IDENTIFICATIVO_OPERAZIONE
                   In presenza di identificativo operazione il versamento
                   viene caricato nella tabella versamenti
 29/10/14 Betta T. Aggiunti codici tributo 3956 e 3957
 23/10/14 Betta T. Aggiunta nota per spiegare codici tributo utilizzati
 16/10/14 Betta T. La modifica di togliere la group by per rata aveva fatto
                   separare il versamento della maggiorazione tares
                   dal versamento dell'imposta.
                   Ho modificato la select per prendere sempre la max rata
                   nel caso di maggiorazione TARES, così da versare la
                   maggiorazione insieme alla rata di saldo (se c'è)
 15/10/14 Betta T. Tolta group by per rata e data versamento. In questa proc.
                   non si faceva il test di versamento gia presente
 15/10/14 Betta T. Cambiato il test su tipo imposta per modifiche al tracciato
                   del ministero
 Causali errore:   50200     Versamento con codici violazione senza Ravvedimento
                   50300     Versamento già presente
                   50309     Contribuente non codificato
                   50350     Pratica di ravvedimento non presente
                   50351     Data Pagamento precedente a Data Notifica Pratica
                   50352     Pratica non Notificata
 Codici tributo usati
 3945 - TARI - TASSA SUI RIFIUTI - ART. 1, C. 639, L. N. 147/2013 - TARES - ART. 14 DL N. 201/2011 - INTERESSI
 3946 - TARI - TASSA SUI RIFIUTI - ART. 1, C. 639, L. N. 147/2013 - TARES - ART. 14 DL N. 201/2011 - SANZIONI
 3951 - (TARI) TARIFFA - ART. 1, C. 668, L. N. 147/2013 - ART. 14, C. 29 DL N. 201/2011 - INTERESSI
 3952 - (TARI) TARIFFA - ART. 1, C. 668, L. N. 147/2013 - ART. 14, C. 29 DL N. 201/2011 - SANZIONI
 366E - EP TARI - tassa sui rifiuti - art.1, c.639,L.147/2013 -TARES - art. 14, d.l. n. 201/2011 - INTERESSI
 367E - EP TARI - tassa sui rifiuti - art.1, c.639, L. n.147/2013 - TARES - art. 14, d.l. n. 201/2011 - SANZIONI
 369E - EP (TARI) TARIFFA - art. 1, c. 668, L. n. 147/2013 - art. 14, c. 29, d.l. n. 201/2011 - INTERESSI
 370E - EP (TARI) TARIFFA - art. 1, c. 668, L. n. 147/2013 -art. 14, c. 29, d.l. n. 201/2011 - SANZIONI
 372E - EP MAGGIORAZIONE - art. 14, c. 13, d.l. n. 201/2011 e succ. modif. - INTERESSI
 373E - EP MAGGIORAZIONE - art. 14, c. 13, d.l. n. 201/2011 e succ. modif. - SANZIONI
 3956 - INTERESSI MAGGIORAZIONE
 3957 - SANZIONI MAGGIORAZIONE
 di Questi codici, nessuno viene usato x determinare gli importi. Cosa facciamo?
*************************************************************************/
( a_documento_id            documenti_caricati.documento_id%type default null,
  a_cod_fiscale             in                                   varchar2 default '%',
  a_messaggio               in out                               varchar2)
IS
w_tipo_tributo       varchar2(5) := 'TARSU';
w_progressivo        number;
w_sequenza           number;
w_conta              number;
w_pratica            number;
w_anno_pratica       number;
w_rata_pratica       number;
w_ruolo              number := to_number(null);
w_magg_tares         number;
w_errore             varchar2(2000);
errore               exception;
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
      ,wkve.rateazione
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
   and wkve.causale         in ('50200','50300','50309','50350','50351','50352')  -- VIOLAZIONI
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
cursor sel_vers is
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
      ,to_date(substr(wkta.dati,67,8),'yyyymmdd')         data_pagamento
      ,sum((to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100)
                                                          importo_versato
      ,sum(decode(substr(wkta.dati,79,4)
                 ,'3945',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,'3951',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,'3956',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,'366E',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,'369E',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,'372E',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,'3921',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100                 
                 ,0
                 )
          )                                               importo_interessi
      ,sum(decode(substr(wkta.dati,79,4)
                 ,'TEFN',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,0
                 )
          )                                               importo_interessi_add_pro
      ,sum(decode(substr(wkta.dati,79,4)
                 ,'3946',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,'3922',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100                 
                 ,'3952',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,'3957',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,'367E',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,'370E',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,'373E',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,0
                 )
          )                                               importo_sanzioni
      ,sum(decode(substr(wkta.dati,79,4)
                 ,'TEFZ',(to_number(substr(wkta.dati,96,15)) - to_number(substr(wkta.dati,111,15))) / 100
                 ,0
                 )
          )                                               importo_sanzioni_add_pro
      ,replace(substr(wkta.dati,84,4),' ','0')            rateazione
      ,to_number(null)                                    addizionale_pro
      ,0                                                  maggiorazione_tares
      ,0                                                  fabbricati
      ,9                                                  fonte
      ,'F24'                                              utente
      ,trunc(sysdate)                                     data_variazione
      ,max(to_date(substr(wkta.dati,3,8),'yyyymmdd'))     data_reg
  from wrk_tras_anci         wkta
      ,contribuenti          cont
      ,soggetti              sogg
 where cont.cod_fiscale     (+) = rtrim(substr(wkta.dati,50,16))
   and sogg.ni              (+) = cont.ni
   and wkta.anno                = 2
   and substr(wkta.dati,79,4) in ('3945','3946','3951','3952','3956','3957',
                                  '366E','367E','369E','370E','372E','373E',
                                  'TEFN','TEFZ', '3921', '3922')  -- si prendono solo i codici tributo della TARES relativi a interessi e sanzioni.
   and to_number(substr(wkta.dati,126,1))  <> 1  -- si escludono i versamenti su ravvedimenti
   and substr(wkta.dati,260,1) in ('A','T')      -- TARSU/TARES/TARI il tracciato riportava T, ma nel file c è A
   and substr(wkta.dati,1,2) = 'G1'              -- si trattano solo i versamenti
 group by rtrim(substr(wkta.dati,50,16))                        -- cod_fiscale
         ,to_number(substr(wkta.dati,88,4))                     -- anno
         ,to_date(substr(wkta.dati,67,8),'yyyymmdd')            -- data_pagamento
         ,decode(substr(wkta.dati,128,2)
                ,'00','U','01','S','10','A','11','U',null
                )                                               -- tipo_versamento
         ,upper(rtrim(substr(wkta.dati,279,18)))                -- id.operazione
         ,substr(wkta.dati,84,4)                                -- rata
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
return NUMBER
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
  nProgr := nProgr + 1;
  return nProgr;
end F_SELEZIONA_PROGRESSIVO;
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
                                    'Versamento con codici violazione Contribuente ('||rec_errati.cod_fiscale||') sconosciuto'
          where wkve.progressivo  = rec_errati.progressivo
         ;
      else
         w_pratica := F_F24_PRATICA(rec_errati.cod_fiscale,rec_errati.id_operazione,rec_errati.data_pagamento,w_tipo_tributo);
         --
         -- Se il risultato della function è -1, significa che la pratica non esiste
         -- oppure non è congruente con i dati indicati.
         -- Si inserisce il versamento in WRK_VERSAMENTI con il codice (50350) e il
         -- messaggio di errore
         -- Se il risultato della function è null, significa che non è stato indicato
         -- l'identificativo operazione, quindi il versamento viene gestito come prima
         -- (rimane in wrk_versamenti con codice 50200)
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
                  --                                     ,-1,  'Versamento con codici violazione Pratica non presente o incongruente'
                  --                                     ,-2,  'Versamento con codici violazione Data Pagamento precedente a Data Notifica Pratica'
                  --                                          ,'Versamento con codici violazione Pratica non Notificata')
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
            -- (VD - 25/09/2018)
            -- Arrivati a questo punto, la pratica e' sicuramente presente
            -- nell'archivio pratiche ed è del tipo richiesto. Si estrapola
            -- l'anno per evitare di inserire versamenti con anno diverso
            -- da quello della pratica
            -- (VD - 29/10/2018): si seleziona anche il numero rata
            --                    dall'identificativo operazione
            --
            w_anno_pratica := to_number(substr(rec_errati.id_operazione,5,4));
            w_rata_pratica := to_number(substr(rec_errati.id_operazione,9,2));
            if w_rata_pratica = 0 then
               w_rata_pratica := nvl(rec_errati.rata,0);
            end if;
            --
            -- (VD - 16/07/2018): modificato test validita' rata
            --
            if w_pratica is null and w_rata_pratica not in (0,1,2,3,4,11,12,22) then
               w_rata_pratica := 1;
            end if;
            --
            if w_pratica is not null and w_rata_pratica not between 0 and 36 then
               w_rata_pratica := 36;
            end if;
            --
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
                     and nvl(vers.pratica,-1)        = nvl(w_pratica,-1)
                   -- modifica: ora la fonte viene richiesta come parametro per i versamenti da cnc
                   --  and vers.fonte                  = 9
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
               -- Se tutti i controlli vengono superati, si inserisce la riga
               -- nella tabella VERSAMENTI e si elimina la riga da WRK_VERSAMENTI
               --
               -- Si controlla la validità del numero rata per l'inserimento
               -- in tabella VERSAMENTI
               -- (VD - 25/09/2018): controllo inutile. In questa procedure non si
               --                    trattano ruoli, ma solo pratiche (i ruoli non
               --                    prevedono il versamento di sanzioni/interessi).               --
               /*if rec_errati.id_operazione like 'RUOL%' then
                  w_ruolo := f_f24_ruolo(rec_errati.id_operazione);
                  if afc.is_numeric(substr(rec_errati.id_operazione,9,2)) = 1 then
                     w_rata := to_number(substr(rec_errati.id_operazione,9,2));
                  else
                     w_rata := nvl(rec_errati.rata,0);
                  end if;
               else
                  w_ruolo := to_number(null);
                  w_rata := nvl(rec_errati.rata,0);
               end if; */
               --
               -- (VD - 16/07/2018): si verifica se per l'anno del versamento
               --                    e' prevista la maggiorazione TARES
               w_magg_tares := F_CATA_MAGG_TARES(nvl(w_anno_pratica,rec_errati.anno));
               --
               BEGIN -- Assegnazione Numero Progressivo
                  select nvl(max(vers.sequenza),0)+1
                    into w_sequenza
                    from versamenti vers
                   where vers.cod_fiscale     = rec_errati.cod_fiscale
                     and vers.anno            = nvl(w_anno_pratica,rec_errati.anno)
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
                       ,w_rata_pratica
                       ,w_ruolo
                       ,case
                          when nvl(w_anno_pratica,rec_errati.anno) < 2021 then to_number(null)
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
                       ,rec_errati.sanzioni_1
                       ,rec_errati.interessi
                       ,case
                          when nvl(w_anno_pratica,rec_errati.anno) < 2021 then to_number(null)
                          else rec_errati.sanzioni_add_pro
                        end
                       ,case
                          when nvl(w_anno_pratica,rec_errati.anno) < 2021 then to_number(null)
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
                where wkve.progressivo  = rec_errati.progressivo;
               if a_documento_id = rec_errati.documento_id then
                 --
                 -- (VM - #60197) Lancia procedura per elaborazione messaggio se presenti ruoli coattivi
                 --
                 a_messaggio := F_CTR_VERS_RUOLI_COATTIVI(w_pratica, rec_errati.cod_fiscale, a_messaggio);
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
     -- Si controlla la validità del numero rata per l'inserimento in tabella
     -- VERSAMENTI; su WRK_VERSAMENTI invece rimane la rata originale
     -- (VD - 25/09/2018): controllo inutile. In questa procedure non si
     --                    trattano ruoli, ma solo pratiche (i ruoli non
     --                    prevedono il versamento di sanzioni/interessi).
     --
     /*w_pratica := to_number(null);
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
        w_rata := nvl(rec_vers.rateazione,0);
     end if; */
     --
     if rec_vers.cod_fiscale is null then
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
              ,rateazione
              ,sanzioni_1
              ,interessi
              ,sanzioni_add_pro
              ,interessi_add_pro
              )
        values(w_progressivo,w_tipo_tributo,'F24',rec_vers.anno,null,rec_vers.cod_fiscale_vers,
               rec_vers.cognome_nome,'50309',w_progressivo,sysdate,
               'Sanzioni e Interessi - Versamento su Ravvedimento Contribuente ('||rec_vers.cod_fiscale_vers||') sconosciuto',
               rec_vers.tipo_versamento,rec_vers.ufficio_pt,rec_vers.data_pagamento,
               rec_vers.data_reg,rec_vers.fabbricati,rec_vers.importo_versato
              ,to_number(substr(rec_vers.rateazione,1,2))
              ,rec_vers.addizionale_pro
              ,rec_vers.maggiorazione_tares
              ,rec_vers.id_operazione
              ,a_documento_id
              ,rec_vers.rateazione
              ,rec_vers.importo_sanzioni
              ,rec_vers.importo_interessi
              ,rec_vers.importo_sanzioni_add_pro
              ,rec_vers.importo_interessi_add_pro
               );
     else
        w_pratica := F_F24_PRATICA(rec_vers.cod_fiscale,rec_vers.id_operazione,rec_vers.data_pagamento,w_tipo_tributo);
        --
        -- Se il risultato della function è -1, significa che la pratica non esiste
        -- oppure non è congruente con i dati indicati.
        -- Si inserisce il versamento in WRK_VERSAMENTI con il codice (50350) e il
        -- messaggio di errore
        -- Se il risultato della function è null, significa che non è stato indicato
        -- l'identificativo operazione, quindi il versamento viene gestito come prima
        -- (rimane in wrk_versamenti con codice 50200)
        --
        -- (VD - 18/12/2014): aggiunta gestione nuove causali errore.
        --                    50351 - data pagamento < data notifica
        --                    50352 - data notifica nulla e data pagamento non nulla
        --
        if nvl(w_pratica,-1) < 0 then
           w_progressivo := F_SELEZIONA_PROGRESSIVO;
           insert into wrk_versamenti
                  (progressivo
                  ,tipo_tributo
                  ,tipo_incasso
                  ,anno
                  ,ruolo
                  ,cod_fiscale
                  ,cognome_nome
                  ,causale
                  ,disposizione
                  ,data_variazione
                  ,note
                  ,tipo_versamento
                  ,ufficio_pt
                  ,data_pagamento
                  ,data_reg
                  ,fabbricati
                  ,importo_versato
                  ,rata
                  ,addizionale_pro
                  ,maggiorazione_tares
                  ,identificativo_operazione
                  ,documento_id
                  ,rateazione
                  ,sanzioni_1
                  ,interessi
                  ,sanzioni_add_pro
                  ,interessi_add_pro
                  )
            select w_progressivo
                  ,w_tipo_tributo
                  ,'F24'
                  ,rec_vers.anno
                  ,null
                  ,rec_vers.cod_fiscale_vers
                  ,rec_vers.cognome_nome
                  -- (VD - 25/09/2018): nuova funzione di decodifica errore
                  --,decode(w_pratica,null,'50200'
                  --                 ,-1  ,'50350'
                  --                 ,-2  ,'50351'
                  --                      ,'50352')
                  ,decode(w_pratica,null,'50200'
                                        ,f_f24_causale_errore(w_pratica,'C'))
                  ,w_progressivo
                  ,sysdate
                  -- (VD - 25/09/2018): nuova funzione di decodifica errore
                  --,'Sanzioni e Interessi - '||
                  --  decode(w_pratica,null,'Versamento con codici violazione senza Ravvedimento'
                  --                  ,-1  ,'Versamento con codici violazione Pratica non presente o incongruente'
                  --                  ,-2  ,'Versamento con codici violazione Data Pagamento precedente a Data Notifica Pratica'
                  --                       ,'Versamento con codici violazione Pratica non Notificata')
                  ,'Sanzioni e Interessi - '||
                    decode(w_pratica,null,'Versamento con codici violazione senza Ravvedimento'
                                         ,f_f24_causale_errore(w_pratica,'D'))
                  ,rec_vers.tipo_versamento
                  ,rec_vers.ufficio_pt
                  ,rec_vers.data_pagamento
                  ,rec_vers.data_reg
                  ,rec_vers.fabbricati
                  ,rec_vers.importo_versato
                  ,to_number(substr(rec_vers.rateazione,1,2))
                  ,rec_vers.addizionale_pro
                  ,rec_vers.maggiorazione_tares
                  ,rec_vers.id_operazione
                  ,a_documento_id
                  ,rec_vers.rateazione
                  ,rec_vers.importo_sanzioni
                  ,rec_vers.importo_interessi
                  ,rec_vers.importo_sanzioni_add_pro
                  ,rec_vers.importo_interessi_add_pro
              from dual;
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
           w_anno_pratica := to_number(substr(rec_vers.id_operazione,5,4));
           w_rata_pratica := to_number(substr(rec_vers.id_operazione,9,2));
           if w_rata_pratica = 0 then
              w_rata_pratica := nvl(substr(rec_vers.rateazione,1,2),0);
           end if;
           --
           -- (VD - 16/07/2018): modificato test validita' rata
           --
           if w_pratica is null and w_rata_pratica not in (0,1,2,3,4,11,12,22) then
              w_rata_pratica := 1;
           end if;
           --
           if w_pratica is not null and w_rata_pratica not between 0 and 36 then
              w_rata_pratica := 36;
           end if;
           --
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
                    and nvl(vers.rata,999)          = nvl(rec_vers.rateazione,999)
                    and nvl(vers.pratica,-1)        = nvl(w_pratica,-1)
                 -- modifica: ora la fonte viene richiesta come parametro per i versamenti da cnc
                 --   and vers.fonte                  = rec_vers.fonte
                 ;
              END;
           else
              begin
                 select count(*)
                   into w_conta
                   from versamenti vers
                  where vers.cod_fiscale  = rec_vers.cod_fiscale
                    and vers.anno         = nvl(w_anno_pratica,rec_vers.anno)
                    and vers.tipo_tributo = w_tipo_tributo
                    and vers.pratica      = w_pratica
                    and vers.rata         = w_rata_pratica
                    and vers.importo_versato = rec_vers.importo_versato;
              EXCEPTION
                 WHEN others THEN
                      w_errore := 'Errore in conteggio'||
                                  ' di '||rec_vers.cod_fiscale||' progressivo '||
                                  to_char(rec_vers.progressivo)||' ('||sqlerrm||')';
                      RAISE errore;
              END;
           end if;
           if w_conta > 0 then
              w_progressivo := F_SELEZIONA_PROGRESSIVO;
  -- dbms_output.put_line('ins wrk2  '||w_progressivo||' '||SQLERRM);
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
                    ,rateazione
                    ,sanzioni_1
                    ,interessi
                    ,sanzioni_add_pro
                    ,interessi_add_pro
                    )
              values(w_progressivo,w_tipo_tributo,'F24',rec_vers.anno,null,rec_vers.cod_fiscale_vers,
                     rec_vers.cognome_nome,
                     decode(w_rata_pratica,0,'50300','50362'),
                     w_progressivo,sysdate,
                     'Sanzioni e Interessi - '||decode(w_rata_pratica,0,'Versamento con codici violazione gia` Presente in data '||to_char(rec_vers.data_pagamento,'dd/mm/yyyy')
                                                                       ,'Pratica rateizzata: Rata gia'' versata'),
                     rec_vers.tipo_versamento,rec_vers.ufficio_pt,rec_vers.data_pagamento,
                     rec_vers.data_reg,rec_vers.fabbricati,rec_vers.importo_versato
                    ,to_number(substr(rec_vers.rateazione,1,2))
                    ,rec_vers.addizionale_pro
                    ,rec_vers.maggiorazione_tares
                    ,rec_vers.id_operazione
                    ,a_documento_id
                    ,rec_vers.rateazione
                    ,rec_vers.importo_sanzioni
                    ,rec_vers.importo_interessi
                    ,rec_vers.importo_sanzioni_add_pro
                    ,rec_vers.importo_interessi_add_pro
                    );
           else
              --
              -- (VD - 16/07/2018): si verifica se per l'anno del versamento
              --                    e' prevista la maggiorazione TARES
              w_magg_tares := F_CATA_MAGG_TARES(nvl(w_anno_pratica,rec_vers.anno));
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
                       ,sanzioni_1
                       ,interessi
                       ,sanzioni_add_pro
                       ,interessi_add_pro
                       )
                 select rec_vers.cod_fiscale
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
                       ,w_rata_pratica
                       ,w_ruolo
                       ,case
                          when nvl(w_anno_pratica,rec_vers.anno) < 2021 then to_number(null)
                          else rec_vers.addizionale_pro
                        end
                       --,decode(w_magg_tares,to_number(null),to_number(null),rec_vers.maggiorazione_tares)
                       ,decode(w_magg_tares,null,to_number(ltrim(rec_vers.maggiorazione_tares,'0')),rec_vers.maggiorazione_tares)
                       ,f_f24_note_versamento(rec_vers.id_operazione
                                             ,w_pratica
                                             ,'S'
                                             ,a_documento_id
                                             ,w_tipo_tributo
                                             )
                       ,a_documento_id
                       ,rec_vers.importo_sanzioni
                       ,rec_vers.importo_interessi
                       ,case
                          when nvl(w_anno_pratica,rec_vers.anno) < 2021 then to_number(null)
                          else rec_vers.importo_sanzioni_add_pro
                        end
                       ,case
                          when nvl(w_anno_pratica,rec_vers.anno) < 2021 then to_number(null)
                          else rec_vers.importo_interessi_add_pro
                        end
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
              a_messaggio := F_CTR_VERS_RUOLI_COATTIVI(w_pratica, rec_vers.cod_fiscale, a_messaggio);
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
           and substr(wkta.dati,79,4) in ('3945','3946','3951','3952','366E'
                                         ,'367E','369E','370E','372E','373E'
                                         ,'3956','3957','TEFN','TEFZ', '3921', '3922')  -- si prendono solo i codici tributo della TARES.
           and to_number(substr(wkta.dati,126,1))  <> 1  -- si escludono i versamenti su ravvedimenti
           and substr(wkta.dati,260,1) in ('A','T')      -- TARSU/TARES/TARI il tracciato riportava T, ma nel file c è A
           and substr(wkta.dati,1,2) = 'G1'              -- si trattano solo i versamenti
           --and to_date(substr(wkta.dati,67,8),'yyyymmdd') = rec_vers.data_pagamento
           and substr(wkta.dati,67,8) = to_char(rec_vers.data_pagamento,'yyyymmdd')
           and nvl(upper(rtrim(substr(wkta.dati,279,18))),'*') = nvl(rec_vers.id_operazione,'*')
           and replace(substr(wkta.dati,84,4),' ','0') = rec_vers.rateazione
        ;
     EXCEPTION
        WHEN others THEN
           w_errore := 'Errore in eliminazione wrk_tras_anci - VIOL'||
                       ' progressivo '||to_char(rec_vers.progressivo)||
                       ' cf '||to_char(rec_vers.cod_fiscale_vers)||
                       ' ('||sqlerrm||')';
           RAISE errore;
     END;
   END LOOP;
EXCEPTION
   WHEN errore THEN
      RAISE_APPLICATION_ERROR(-20999,w_errore);
END;
/* End Procedure: CARICA_VERS_VIOL_TARES_F24 */
/
