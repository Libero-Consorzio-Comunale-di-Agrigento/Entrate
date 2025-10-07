--liquibase formatted sql 
--changeset abrandolini:20250326_152423_carica_versamenti_trmi_f24 stripComments:false runOnChange:true 
 
create or replace procedure CARICA_VERSAMENTI_TRMI_F24
/*************************************************************************
 NOME:        CARICA_VERSAMENTI_TRMI_F24
 DESCRIZIONE: Tratta i versamenti relativi ai tributi minori
              (TOSAP/COSAP/ICP/PUBBL) presenti nella tabella WRK_TRAS_ANCI
              ed eventuali record scartati e successivamente bonificati.
 NOTE:
 Causali errore:       50000     Versamento già presente
                       50009     Contribuente non codificato
                       50050     Denuncia non presente o incongruente
                       --50350     Pratica non presente o incongruente
                       --50351     Data Pagamento precedente a Data Notifica Pratica
                       --50352     Pratica non Notificata
                       --50360     Pratica rateizzata: versamento antecedente
                                 alla data di rateazione
                       --50361     Pratica rateizzata: rata errata
                       --50362     Pratica rateizzata: rata gia' versata
 Codici tributo trattati:
 3931 - Tassa/canone per l'occupazione permanente di spazi ed aree
        pubbliche (TOSAP/COSAP)
 3932 - Tassa/canone per l'occupazione temporanea di spazi ed aree
        pubbliche (TOSAP/COSAP)
 3964 - Imposta comunale sulla pubblicità/canone per l¿installazione di
        mezzi pubblicitari (ICP DPA/CIMP)
 Rev.    Date         Author      Note
 012     13/03/2024   VM          #71019 - Conversione di versamenti e wrk_versamenti (anomalie) 
                                  da TOSAP a CUNI per Provincia di Frosinone 
 011     16/03/2023   VM          #55165 - Aggiunto parametro a_cod_fiscale.
                                  Aggiunto filtro cod_fiscale su popolamento cursori.
 010     14/03/2023   VM          #60197 - Aggiunto il parametro a_log_documento 
                                  che viene passato alla subprocedure per la 
                                  valorizzazione di eventuali errori
 009     17/09/2021   VD          Corretta funzione F_CHECK_VERSAMENTI:
                                  mancava la "return" del risultato della
                                  query
 008     24/06/2021   VD          Modificata gestione contribuente assente:
                                  ora il contribuente viene inserito anche
                                  in fase di caricamento da file (sempre se
                                  esiste gia' il soggetto).
 007     11/01/2021   VD          Gestione nuovo campo note_versamento
                                  della tabella WRK_VERSAMENTI: il contenuto
                                  viene copiato nel campo note della tabella
                                  VERSAMENTI.
 006     16/06/2020   VD          Corretta gestione versamenti su violazione:
                                  si trattano solo i versamenti in bonifica
                                  relativi alle causali 50000, 50009 e 50050
                                 (versamenti di imposta)
 005     15/10/2019   VD          Aggiunto trattamento causale errore 50050
 004     02/05/2019   VD          Aggiunto raggruppamento per rateazione
                                  in query su wrk_trans_anci e relativa
                                  delete.
                                  Modificata valorizzazione rata a seconda
                                  della presenza o meno dell'identificativo
                                  operazione.
                                  Aggiunti controlli di congruenza con trigger
                                  sul valore della rata.
 003     30/04/2019   VD          Corretta condizione di where su
                                  codici_f24: ora controlla anche il campo
                                  descrizione_titr (per evitare il prodotto
                                  cartesiano sui codici tributo TOSAP)
 002     24/10/2018   VD          Corretta gestione campo rateazione
                                  inserito con spazi a sinistra
 001     25/09/2018   VD          Modifiche per gestione versamenti su
                                  pratiche rateizzate
 000     31/05/2018   VD          Prima emissione.
*************************************************************************/
( a_documento_id            documenti_caricati.documento_id%type default null,
  a_cod_fiscale             in                                   varchar2 default '%',
  a_log_documento           in out                               varchar2)
IS
w_progressivo               number;
w_sequenza                  number;
w_conta                     number;
w_conta_cont                number;
w_ni                        number;
w_pratica                   number;
w_anno_pratica              number;
w_rata_pratica              number;
w_cod_fiscale               varchar2(16);
w_errore                    varchar2(2000);
errore                      exception;
-- nella prima fase faccio diventare contribuenti i titolari dei versamenti
-- per cui è stato indicato il flag_contribuente
-- (VD - 11/01/2021): Aggiunta selezione nuovo campo note_versamento
cursor sel_ins_cont is
select wkve.progressivo
      ,wkve.tipo_tributo
      ,wkve.anno
      ,wkve.cod_fiscale
      ,wkve.importo_versato
      ,wkve.data_pagamento
      ,wkve.ufficio_pt
      ,wkve.data_reg
      ,wkve.flag_contribuente
      ,cont.cod_fiscale                         cod_fiscale_cont
      ,sogg.cognome_nome
      ,wkve.rata
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
   and wkve.causale         = '50009'
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
-- (VD - 11/01/2021): Aggiunta selezione nuovo campo note_versamento
--
cursor sel_errati is
select wkve.progressivo
      ,wkve.tipo_tributo
      ,wkve.anno
      ,wkve.cod_fiscale
      ,wkve.importo_versato
      ,wkve.data_pagamento
      ,wkve.ufficio_pt
      ,wkve.data_reg
      ,wkve.flag_contribuente
      ,cont.cod_fiscale                         cod_fiscale_cont
      ,sogg.cognome_nome
      ,wkve.rata
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
   and wkve.causale         in ('50000','50009','50050',
                                '50350','50351','50352',
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
-- (VD - 02/05/2019): Aggiunto raggruppamento per rateazione
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
      ,substr(wkta.dati,79,4)                            codice_tributo
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
   and substr(wkta.dati,79,4)                             = cof2.tributo_f24
   and f_descrizione_titr(decode(substr(wkta.dati,260,1),'O','TOSAP','ICP'),to_number(substr(wkta.dati,88,4))) = cof2.descrizione_titr
   and cof2.tipo_codice                                   = 'C'  -- si escludono i versamenti su violazioni
   and to_number(substr(wkta.dati,126,1))  <> 1           -- si escludono i versamenti su ravvedimenti
   and substr(wkta.dati,260,1) in ('O','C')               -- TOSAP/ICP
   and substr(wkta.dati,1,2)    = 'G1'                    -- Si trattano solo i versamenti
 group by rtrim(substr(wkta.dati,50,16))                  -- cod. fiscale
         ,to_number(substr(wkta.dati,88,4))               -- anno rif.
         ,decode(substr(wkta.dati,260,1),'O','TOSAP','ICP')  -- tipo_tributo
         ,upper(rtrim(substr(wkta.dati,279,18)))             -- id.operazione
         ,to_date(substr(wkta.dati,67,8),'yyyymmdd')         -- data pagamento
         ,substr(wkta.dati,79,4)                             -- cod. tributo
         ,replace(substr(wkta.dati,84,4),' ','0')            -- rateazione
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
, p_descrizione                     varchar2
, p_ufficio_pt                      varchar2
, p_data_pagamento                  date
, p_importo_versato                 number
, p_pratica                         number
, p_anno_pratica                    number
, p_rata_pratica                    number
) return number
is
  w_conta                     number;
BEGIN
  if p_rata_pratica = 0 then
     BEGIN
       select count(*)
         into w_conta
         from versamenti vers
        where vers.cod_fiscale            = p_cod_fiscale
          and vers.anno                   = p_anno
          and vers.tipo_tributo           = p_tipo_tributo
          and vers.descrizione            = p_descrizione
          and vers.ufficio_pt             = p_ufficio_pt
          and vers.data_pagamento         = p_data_pagamento
          and vers.importo_versato        = p_importo_versato
          and nvl(vers.pratica,-1)        = nvl(p_pratica,-1)
          ;
     EXCEPTION
       WHEN others THEN
            w_errore := 'Errore in conteggio'||
                        ' di '||p_cod_fiscale||'/'||p_tipo_tributo||
                        '/'||p_anno||' ('||sqlerrm||')';
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
                         ' di '||p_cod_fiscale||'/'||p_tipo_tributo||
                         '/'||nvl(p_anno_pratica,p_anno)||' ('||sqlerrm||')';
             RAISE errore;
     END;
  end if;
  --
  return w_conta;
  --
END;
------------------------------------
-- Procedure CONVERTI_VERSAMENTI_A_CUNI
------------------------------------
PROCEDURE CONVERTI_VERSAMENTI_A_CUNI is
  w_cod_cliente    varchar2(6);
  w_flag_provincia varchar(1);
  cursor sel_versamenti_tosap is
    select vers.cod_fiscale, vers.anno, vers.tipo_tributo, vers.sequenza
      from versamenti vers
     where vers.tipo_tributo = 'TOSAP';
BEGIN
  begin
    select lpad(to_char(dage.pro_cliente), 3, '0') ||
           lpad(to_char(dage.com_cliente), 3, '0'),
           dage.flag_provincia
      into w_cod_cliente, w_flag_provincia
      from dati_generali dage;
  exception
    when others then
      w_errore := 'Errore in recupero comune dati_generali ' || ' (' ||
                  sqlerrm || ')';
      raise errore;
  end;
  -- Provincia di Frosinone
  if w_cod_cliente = '060038' and w_flag_provincia = 'S' then
    for rec_vers_tosap in sel_versamenti_tosap loop
      begin
        update versamenti v1
           set tipo_tributo = 'CUNI',
               sequenza    =
               (select nvl(max(v2.sequenza), 0) + 1
                  from versamenti v2
                 where v2.cod_fiscale = v1.cod_fiscale
                   and v2.anno = v1.anno
                   and v2.tipo_tributo = 'CUNI')
         where v1.cod_fiscale = rec_vers_tosap.cod_fiscale
           and v1.anno = rec_vers_tosap.anno
           and v1.tipo_tributo = rec_vers_tosap.tipo_tributo
           and v1.sequenza = rec_vers_tosap.sequenza;
      exception
        when others then
          w_errore := 'Errore in aggiornamento versamenti da TOSAP a CUNI' || ' (' ||
                      sqlerrm || ')';
          raise errore;
      end;
    end loop;
    begin
      update wrk_versamenti wrve
         set wrve.tipo_tributo = 'CUNI'
       where wrve.tipo_tributo = 'TOSAP';
    exception
      when others then
        w_errore := 'Errore in aggiornamento wrk_versamenti da TOSAP a CUNI' || ' (' ||
                    sqlerrm || ')';
        raise errore;
    end;
  end if;
END CONVERTI_VERSAMENTI_A_CUNI;
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
               END; */
     if rec_ins_cont.cod_fiscale_cont is null then
        w_cod_fiscale := f_crea_contribuente(rec_ins_cont.cod_fiscale,w_errore);
        if w_cod_fiscale is null then
           if w_errore is not null then
              update wrk_versamenti wkve
                 set note = substr(decode(note,'','',note||' - ')||w_errore,1,2000)
               where wkve.progressivo  = rec_ins_cont.progressivo;
           end if;
        else
           -- (VD - 09/04/2021): ripristinato controllo pratica per il caso
           --                    di versamento inserito con codice fiscale
           --                    diverso da quello del contribuente
           -- (VD - 24/06/2021): In realta' il controllo non serve, in quanto
           --                    non utilizziamo mai un codice fiscale diverso
           --                    da quello presente sul versamento. Quindi, se
           --                    il contribuente non esiste, non possono
           --                    esistere pratiche.
           --                    Lo lascio comunque attivo per comodita'.
           w_pratica := F_F24_PRATICA(w_cod_fiscale,rec_ins_cont.id_operazione
                                     ,rec_ins_cont.data_pagamento,rec_ins_cont.tipo_tributo);
           --
           -- Se il risultato della function è negativo, significa che la pratica
           -- non esiste oppure non è congruente con i dati indicati
           --
           if nvl(w_pratica,0) < 0 then
              begin
                update wrk_versamenti wkve
                   set wkve.causale      = f_f24_causale_errore(nvl(w_pratica,-1),'C')
                      ,wkve.note         = rpad(decode(rec_ins_cont.tipo_messaggio
                                                      ,'I','Imposta - '
                                                      ,'S','Sanzioni e Interessi - '
                                                      ,'')||
                                                f_f24_causale_errore(nvl(w_pratica,-1),'D'),1000)||
                                           rec_ins_cont.note
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
              -- Se la pratica e' null oppure è positiva, significa che i controlli
              -- sulle pratiche sono stati superati
              if nvl(w_pratica,0) > 0 then
                 w_anno_pratica := to_number(substr(rec_ins_cont.id_operazione,5,4));
                 w_rata_pratica := to_number(substr(rec_ins_cont.id_operazione,9,2));
              else
                 w_anno_pratica := to_number(null);
                 -- (VD - 02/05/2019): modificata valorizzazione rata in
                 --                    assenza di pratica di riferimento
                 if rec_ins_cont.rateazione is null then
                    w_rata_pratica := rec_ins_cont.rata;
                 else
                    if rec_ins_cont.rateazione = '0101' then
                       w_rata_pratica := 0;
                    else
                       if afc.is_numeric(substr(rec_ins_cont.rateazione,1,2)) = 1 then
                          w_rata_pratica := to_number(substr(rec_ins_cont.rateazione,1,2));
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
              --
              w_conta := F_CHECK_VERSAMENTI ( w_cod_fiscale
                                            , rec_ins_cont.anno
                                            , rec_ins_cont.tipo_tributo
                                            , 'VERSAMENTO IMPORTATO DA MODELLO F24'
                                            , rec_ins_cont.ufficio_pt
                                            , rec_ins_cont.data_pagamento
                                            , rec_ins_cont.importo_versato
                                            , w_pratica
                                            , w_anno_pratica
                                            , w_rata_pratica
                                            );
              if w_conta > 0 then
                 begin
                   update wrk_versamenti wkve
                      set wkve.causale      = decode(w_rata_pratica,0,'50000','50362')
                         ,wkve.note         = rpad(decode(rec_ins_cont.tipo_messaggio
                                                         ,'I','Imposta - '
                                                         ,'S','Sanzioni e Interessi - '
                                                         ,'')||
                                                   decode(w_rata_pratica
                                                         ,0,'Versamento gia` Presente in data '||
                                                            to_char(rec_ins_cont.data_pagamento,'dd/mm/yyyy')
                                                         ,'Pratica rateizzata: Rata gia'' versata'),1000)||
                                              rec_ins_cont.note
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
                       and vers.tipo_tributo    = rec_ins_cont.tipo_tributo
                            ;
                 END;*/
                 w_sequenza := to_number(null);
                 VERSAMENTI_NR ( w_cod_fiscale, nvl(w_anno_pratica,rec_ins_cont.anno)
                               , rec_ins_cont.tipo_tributo, w_sequenza );
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
                         ,rata
                         ,note
                         ,documento_id
                         ,sanzioni_1
                         ,interessi
                         )
                   select w_cod_fiscale
                         ,rec_ins_cont.anno
                         ,rec_ins_cont.tipo_tributo
                         ,w_sequenza
                         ,'VERSAMENTO IMPORTATO DA MODELLO F24'
                         ,rec_ins_cont.ufficio_pt
                         ,rec_ins_cont.data_pagamento
                         ,rec_ins_cont.importo_versato
                         ,9
                         ,'F24'
                         ,trunc(sysdate)
                         ,rec_ins_cont.data_reg
                         -- (VD - 25/09/2018): per contribuenti inesistenti si
                         -- assume la rata presente sul versamento come valida
                         -- (VD - 02/05/2019): spostato controllo rata prima di
                         --                    inserimento
                         --,decode(rec_ins_cont.rateazione
                         --       ,null,rec_ins_cont.rata
                         --       ,'0101',0
                         --              ,to_number(substr(rec_ins_cont.rateazione,1,2)))
                         ,w_rata_pratica
                         ,substr(trim(rec_ins_cont.note_versamento)||';'||
                                 trim(rec_ins_cont.note),1,2000)
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
                  ,wkve.note         = rpad('Contribuente ('||rec_errati.cod_fiscale||') sconosciuto',1000)||
                                       rec_errati.note
             where wkve.progressivo  = rec_errati.progressivo
            ;
      else
         w_pratica := F_F24_PRATICA(rec_errati.cod_fiscale_cont,rec_errati.id_operazione,rec_errati.data_pagamento,rec_errati.tipo_tributo);
         --
         -- Se il risultato della function è negativo, significa che la pratica
         -- non esiste oppure non è congruente con i dati indicati
         --
         if nvl(w_pratica,0) < 0 then
            begin
                update wrk_versamenti wkve
                   set wkve.cognome_nome = rec_errati.cognome_nome
                      -- (VD - 25/09/2018): nuova funzione di decodifica errore
                      --,wkve.causale      = decode(w_pratica,-1,'50350'
                      --                                     ,-4,'50350'
                      --                                     ,-2,'50351'
                      --                                        ,'50352')
                      --,wkve.note         = rpad(decode(rec_errati.tipo_messaggio,'I','Imposta - '
                      --                                                          ,'S','Sanzioni e Interessi - '
                      --                                                              ,'')||
                      --                          decode(w_pratica,-1,'Versamento con codici violazione Pratica non presente o incongruente'
                      --                                          ,-2,'Versamento con codici violazione Data Pagamento precedente a Data Notifica Pratica'
                      --                                          ,-3,'Versamento con codici violazione Pratica non Notificata'
                      --                                             ,'Denuncia non presente o incongruente'),1000)||
                      --                     rec_errati.note
                      ,wkve.causale      = f_f24_causale_errore(nvl(w_pratica,-1),'C')
                      ,wkve.note         = rpad(decode(rec_errati.tipo_messaggio,'I','Imposta - '
                                                                                ,'S','Sanzioni e Interessi - '
                                                                                    ,'')||
                                                f_f24_causale_errore(nvl(w_pratica,-1),'D'),1000)||
                                           rec_errati.note
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
            -- Se la pratica e' null oppure è positiva, significa che i controlli
            -- sulle pratiche sono stati superati
            --
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
            --
            w_conta := F_CHECK_VERSAMENTI ( rec_errati.cod_fiscale_cont
                                          , rec_errati.anno
                                          , rec_errati.tipo_tributo
                                          , 'VERSAMENTO IMPORTATO DA MODELLO F24'
                                          , rec_errati.ufficio_pt
                                          , rec_errati.data_pagamento
                                          , rec_errati.importo_versato
                                          , w_pratica
                                          , w_anno_pratica
                                          , w_rata_pratica
                                          );
            if w_conta > 0 then
               begin
                 update wrk_versamenti wkve
                    set wkve.cognome_nome = rec_errati.cognome_nome
                       ,wkve.causale      = decode(w_rata_pratica,0,'50000','50362')
                       ,wkve.note         = rpad(decode(rec_errati.tipo_messaggio,'I','Imposta - '
                                                                                 ,'S','Sanzioni e Interessi - '
                                                                                 ,'')||
                                                 decode(w_rata_pratica,0,'Versamento gia` Presente in data '||
                                                                         to_char(rec_errati.data_pagamento,'dd/mm/yyyy')
                                                                        ,'Pratica rateizzata: Rata gia'' versata'),1000)||
                                            rec_errati.note
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
               /*BEGIN -- Assegnazione Numero Progressivo
                 select nvl(max(vers.sequenza),0)+1
                   into w_sequenza
                   from versamenti vers
                  where vers.cod_fiscale    = rec_errati.cod_fiscale_cont
                    and vers.anno           = nvl(w_anno_pratica,rec_errati.anno)
                    and vers.tipo_tributo   = rec_errati.tipo_tributo
                 ;
               END;*/
               w_sequenza := to_number(null);
               VERSAMENTI_NR ( rec_errati.cod_fiscale_cont, nvl(w_anno_pratica,rec_errati.anno)
                             , rec_errati.tipo_tributo, w_sequenza);
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
                       ,fonte
                       ,utente
                       ,data_variazione
                       ,data_reg
                       ,rata
                       ,note
                       ,documento_id
                       ,sanzioni_1
                       ,interessi)
                 select rec_errati.cod_fiscale_cont
                       ,nvl(w_anno_pratica,rec_errati.anno)
                       ,w_pratica
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
                       -- (VD - 25/09/2018): modifica per gestione pratiche
                       --                    rateizzate
                       --,rec_errati.rata
                       -- (VD - 02/05/2019): spostati controlli prima di insert
                       --,decode(w_rata_pratica
                       --       ,0,decode(rec_errati.rateazione
                       --                ,null,rec_errati.rata
                       --                ,'0101',0
                       --                       ,to_number(substr(rec_errati.rateazione,1,2))
                       --                )
                       --       ,w_rata_pratica
                       --       )
                       ,w_rata_pratica
                       ,substr(trim(rec_errati.note_versamento)||';'||
                               trim(rec_errati.note),1,2000)
                       ,rec_errati.documento_id
                       ,rec_errati.sanzioni_1
                       ,rec_errati.interessi
                   from dual
                     ;
               EXCEPTION
                 WHEN others THEN
                 dbms_output.put_line(sqlerrm);
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
      --dbms_output.put_line('Tipo tributo: '||rec_vers.tipo_tributo);
      --dbms_output.put_line('Cod.fiscale '||rec_vers.cod_fiscale||'/'||rec_vers.cod_fiscale_vers);
      if rec_vers.cod_fiscale is null then
         -- Contribuente non codificato
         -- (VD - 24/06/2021): se il contribuente non esiste ma esiste un
         --                    soggetto con lo stesso codice fiscale, si crea
         --                    un nuovo contribuente
         w_cod_fiscale := f_crea_contribuente(rec_vers.cod_fiscale_vers,w_errore);
         if w_cod_fiscale is null then
            w_progressivo := F_SELEZIONA_PROGRESSIVO;
            -- dbms_output.put_line('ins wrk  '||w_progressivo||' '||SQLERRM);
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
                  ,rateazione)
            values(w_progressivo
                  ,rec_vers.tipo_tributo
                  ,'F24'
                  ,rec_vers.anno
                  ,rec_vers.cod_fiscale_vers
                  ,rec_vers.cognome_nome
                  ,'50009'
                  ,w_progressivo
                  ,sysdate
                  ,rpad('Imposta - Contribuente ('||rec_vers.cod_fiscale_vers||') sconosciuto',1000)||
                   f_f24_note_versamento(rec_vers.id_operazione,to_number(null),'I',a_documento_id,rec_vers.tipo_tributo,rec_vers.codice_tributo,rec_vers.rateazione)
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
                  ,rec_vers.rateazione);
         end if;
      else
         w_cod_fiscale := rec_vers.cod_fiscale;
      end if;
      -- (VD - 24/06/2021): se il contribuente esisteva gia' oppure e' appena
      --                    stato inserito, si prosegue il trattamento
      if w_cod_fiscale is not null then
         --w_pratica := F_F24_PRATICA(rec_vers.cod_fiscale,rec_vers.id_operazione,rec_vers.data_pagamento,rec_vers.tipo_tributo);
         w_pratica := F_F24_PRATICA(w_cod_fiscale,rec_vers.id_operazione,rec_vers.data_pagamento,rec_vers.tipo_tributo);
         --
         -- Se il risultato della function è negativo, significa che la pratica
         -- non esiste oppure non è congruente con i dati indicati.
         --
         if nvl(w_pratica,0) < 0 then
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
                  -- (VD - 25/09/2018): nuova funzione di decodifica errore
                  --,decode(w_pratica,-1,'50350'
                  --                 ,-4,'50350'
                  --                 ,-2,'50351'
                  --                    ,'50352')
                  ,f_f24_causale_errore(w_pratica,'C')    -- causale
                  ,w_progressivo
                  ,sysdate
                  -- (VD - 25/09/2018): nuova funzione di decodifica errore
                  --,rpad(decode(w_pratica,null,'','Imposta - ')||
                  --      decode(w_pratica,-1,'Versamento con codici violazione: Pratica non presente o incongruente'
                  --                      ,-2,'Versamento con codici violazione: Data Pagamento precedente a Data Notifica Pratica'
                  --                      ,-3,'Versamento con codici violazione: Pratica non Notificata'
                  --                         ,'Pratica non presente o incongruente'),1000)||
                  -- f_f24_note_versamento(rec_vers.id_operazione,to_number(null),'I',a_documento_id,rec_vers.tipo_tributo,rec_vers.codice_tributo,rec_vers.rateazione)
                  ,rpad(decode(w_pratica,null,'','Imposta - ')||f_f24_causale_errore(w_pratica,'D'),1000)||
                   f_f24_note_versamento(rec_vers.id_operazione,to_number(null),'I',a_documento_id,rec_vers.tipo_tributo,rec_vers.codice_tributo,rec_vers.rateazione)
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
            -- Se la pratica e' null oppure è positiva, significa che i controlli
            -- sulle pratiche sono stati superati
            --
            if w_pratica is not null then
               w_anno_pratica := to_number(substr(rec_vers.id_operazione,5,4));
               w_rata_pratica := to_number(substr(rec_vers.id_operazione,9,2));
            else
               w_anno_pratica := to_number(null);
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
            --
            -- Controllo esistenza versamento
            --
            -- (VD - 02/05/2019): Modificato controllo esistenza versamenti:
            --                    il controllo viene eseguito anche con la
            --                    rata (se presente)
            --
            --dbms_output.put_line('Check versamenti: '||w_cod_fiscale||'-'||
            --                     rec_vers.anno||'-'||rec_vers.tipo_tributo||'-'||
            --                     rec_vers.descrizione||'-'||rec_vers.ufficio_pt||'-'||
            --                     rec_vers.data_pagamento||'-'||rec_vers.importo_versato||'-'||
            --                     w_pratica||'-'||w_anno_pratica||'-'||w_rata_pratica);
            w_conta := F_CHECK_VERSAMENTI ( w_cod_fiscale --rec_vers.cod_fiscale
                                          , rec_vers.anno
                                          , rec_vers.tipo_tributo
                                          , rec_vers.descrizione
                                          , rec_vers.ufficio_pt
                                          , rec_vers.data_pagamento
                                          , rec_vers.importo_versato
                                          , w_pratica
                                          , w_anno_pratica
                                          , w_rata_pratica
                                          );
            --dbms_output.put_line('Conta: '||w_conta);
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
                     )
               values(w_progressivo
                     ,rec_vers.tipo_tributo
                     ,'F24'
                     ,rec_vers.anno
                     ,rec_vers.cod_fiscale_vers
                     ,rec_vers.cognome_nome
                     ,'50000'
                     ,w_progressivo
                     ,sysdate
                     ,rpad('Versamento gia` Presente in data '||to_char(rec_vers.data_pagamento,'dd/mm/yyyy'),1000)||
                      f_f24_note_versamento(rec_vers.id_operazione,to_number(null),'I',a_documento_id,rec_vers.tipo_tributo,rec_vers.codice_tributo,rec_vers.rateazione)
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
                         ,documento_id)
                   select w_cod_fiscale --rec_vers.cod_fiscale
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
                         -- (VD - 02/05/2018): spostato controllo prima di insert
                         --,decode(w_rata_pratica
                         --       ,0,decode(rec_vers.rateazione
                         --                ,'0101',0
                         --                       ,to_number(substr(rec_vers.rateazione,1,2))
                         --                )
                         --         ,w_rata_pratica
                         --       )
                         ,w_rata_pratica
                         ,f_f24_note_versamento(rec_vers.id_operazione,to_number(null),'I',a_documento_id
                                               ,rec_vers.tipo_tributo,rec_vers.codice_tributo,rec_vers.rateazione)
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
      --
      -- Si eliminano le righe di wrk_tras_anci trattate in questa fase
      -- (VD - 02/05/2019): aggiunta condizione di where su rateazione
      --
      BEGIN
         delete wrk_tras_anci wkta
          where rtrim(substr(wkta.dati,50,16))      = rec_vers.cod_fiscale_vers
            and to_number(substr(wkta.dati,88,4))   = rec_vers.anno
            and wkta.anno                           = 2
            and substr(wkta.dati,79,4)              = rec_vers.codice_tributo
            and to_number(substr(wkta.dati,126,1))  <> 1  -- si escludono i versamenti su ravvedimenti
            and substr(wkta.dati,260,1) = decode(rec_vers.tipo_tributo,'TOSAP','O','C')  -- TOSAP/ICP
            and substr(wkta.dati,1,2)   = 'G1'            -- Si trattano solo i versamenti
            and nvl(upper(rtrim(substr(wkta.dati,279,18))),'*') = nvl(rec_vers.id_operazione,'*')
            and substr(wkta.dati,67,8)              = to_char(rec_vers.data_pagamento,'yyyymmdd')
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
----------------------------------------------------
-- Trattamento dei versamenti su ravvedimento
----------------------------------------------------
--dbms_output.put_line('Ravvedimenti');
CARICA_VERS_RAVV_TRMI_F24(a_documento_id, a_cod_fiscale);
----------------------------------------------------
-- Trattamento dei versamenti su violazioni
----------------------------------------------------
--dbms_output.put_line('Violazioni');
CARICA_VERS_VIOL_TRMI_F24(a_documento_id, a_cod_fiscale, a_log_documento);

CONVERTI_VERSAMENTI_A_CUNI;

EXCEPTION
   WHEN errore THEN
      RAISE_APPLICATION_ERROR(-20999,w_errore);
END;
/* End Procedure: CARICA_VERSAMENTI_TRMI_F24 */
/
