--liquibase formatted sql 
--changeset abrandolini:20250326_152429_cer_conferimenti stripComments:false runOnChange:true 
 
create or replace package cer_conferimenti is
/******************************************************************************
 NOME:        CER_CONFERIMENTI
 DESCRIZIONE: Procedure e Funzioni per gestione conferimenti a centri raccolta.
              Versione per comune di Pontedera / Geofor.
 ANNOTAZIONI: Utilizzato per i seguenti codici ISTAT:
              050029 - Pontedera
              036013 - Fiorano Modenese
              037006 - Bologna - Per prove interne ADS
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 000   31/08/2017  VD      Prima emissione.
 001   23/02/2018  AB      Tolto il ';' alla fine dei record e commentate alcune
                           condizioni nella select estrazione file completo
 002   20/08/2018  VD      Aggiunta gestione conferimenti Fiorano Modenese
 003   19/09/2018  VD      Aggiunta procedure per inserire tabella
                           ANOMALIE_CARICAMENTO
 *****************************************************************************/
  -- Revisione del Package
  s_revisione constant afc.t_revision := 'V1.02';
  -- Public function and procedure declarations
  procedure DELETE_WRK_TRASMISSIONI;
  procedure INSERT_WRK_TRASMISSIONI
  ( p_descr_chiave           varchar2
  , p_campo_chiave           varchar2
  , p_numero                 number
  , p_dati                   varchar2
  , p_dati2                  varchar2 default null
  , p_dati3                  varchar2 default null
  , p_dati4                  varchar2 default null
  , p_dati5                  varchar2 default null
  , p_dati6                  varchar2 default null
  , p_dati7                  varchar2 default null
  , p_dati8                  varchar2 default null
  );
  procedure INSERT_ANOMALIE_CARICAMENTO
  ( p_documento_id          number
  , p_sequenza              number
  , p_cognome               varchar2
  , p_nome                  varchar2
  , p_cod_fiscale           varchar2
  , p_descrizione           varchar2
  , p_note                  varchar2
  );
  procedure ESTRAZIONE_FILE_COMPLETO
  ( p_anno                 in number
  , p_righe_estratte      out number
  );
  procedure CARICA_CONFERIMENTI_CER
  ( p_documento_id     in      number
  , p_utente           in      varchar2
  , p_messaggio        in out  varchar2
  );
  procedure CALCOLO_PERIODO_CONF
  ( p_ruolo            in      number
  , p_dal              in out  date
  , p_al               in out  date
  );
  function CALCOLO_FAMILIARI
  ( p_ni               in      number
  , p_dal              in      date
  , p_al               in      date
  ) return number;
  procedure DETERMINA_SCONTO_PERIODO
  ( p_anno             in      number
  , p_ruolo            in      number
  , p_tipo_ruolo       in      number
  , p_tipo_emissione   in      varchar2
  , p_cod_fiscale      in      varchar2
  , p_num_familiari    in      number
  , p_dal              in      date
  , p_al               in      date
  , p_utente           in      varchar2
  );
  procedure DETERMINA_SCONTO_CONF
  ( p_anno             in      number
  , p_ruolo            in      number
  , p_tipo_ruolo       in      number
  , p_tipo_emissione   in      varchar2
  , p_cod_fiscale      in      varchar2
  , p_utente           in      varchar2
  );
  procedure ELIMINA_RUOLO_CONF
  ( p_ruolo            in      number
  , p_cod_fiscale      in      varchar2
  );
  function F_ULTIMO_RUOLO_CONF
  ( p_cod_fiscale      in      varchar2
  , p_anno             in      number
  , p_tipo_utenza      in      varchar2
  , p_data_conferimento in     date
  , p_codice_cer       in      varchar2
  ) return number;
  function F_IMPORTO_RUOLO_CONF
  ( p_cod_fiscale      in      varchar2
  , p_anno             in      number
  , p_tipo_utenza      in      varchar2
  , p_data_conferimento in     date
  , p_codice_cer       in      varchar2
  , p_ruolo            in      number default null
  ) return number;
  function F_CONF_MODIFICABILE
  ( p_cod_fiscale      in      varchar2
  , p_anno             in      number
  , p_tipo_utenza      in      varchar2
  , p_data_conferimento in     date
  , p_codice_cer       in      varchar2
  ) return number;
  function F_CONF_QTA_MODIFICABILE
  ( p_cod_fiscale      in      varchar2
  , p_anno             in      number
  , p_tipo_utenza      in      varchar2
  , p_data_conferimento in     date
  , p_codice_cer       in      varchar2
  ) return number;
  function F_CONF_RUOLO_MODIFICABILE
  ( p_ruolo            in      number
  ) return number;
/*
  procedure DETERMINA_SCONTO_CONF_ACC
  ( p_anno             in      number
  , p_ruolo            in      number
  , p_cod_fiscale      in      varchar2
  , p_sconto_dom       out     number
  , p_sconto_nd        out     number
  );*/
end cer_conferimenti;
/

create or replace package body cer_conferimenti is
  /******************************************************************************
    NOME:        CER_CONFERIMENTI.
    DESCRIZIONE: Procedure e Funzioni per gestione conferimenti a centri raccolta.
                 Versione per comune di Pontedera / Geofor.
    ANNOTAZIONI: Utilizzato per i seguenti codici ISTAT:
                 050029 - Pontedera
                 036013 - Fiorano Modenese
                 037006 - Bologna - Per prove interne ADS
    REVISIONI: .
    Rev.  Data        Autore  Descrizione.
    00    31/08/2017  VD      Prima emissione.
    01    23/02/2018  AB      Tolto il ';' alla fine dei record e commentate alcune
                              condizioni nella select estrazione file completo
    02    26/02/2018  VD      Aggiunto azzeramento variabile w_contarighe in
                              procedure ESTRAZIONE_FILE_COMPLETO, per evitare
                              che in caso di piu' elaborazioni successive il
                              numero delle righe estratte venisse sempre
                              incrementato.
    03    20/08/2018  VD      Aggiunta gestione conferimenti Fiorano Modenese
    04    19/09/2018  VD      Aggiunta procedure per inserire tabella
                              ANOMALIE_CARICAMENTO.
                              Pontedera: aggiunta gestione conferimenti doppi.
  ******************************************************************************/
  s_revisione_body   constant afc.t_revision := '003';
  s_cod_comune       constant number := 11;   -- Comune di Pontedera per GEOFOR
  s_tipo_tributo     constant varchar2(5) := 'TARSU';
  w_riga                      varchar2(32767);
  w_contarighe                number := 0;
  w_errore                    varchar2(4000);
  errore                      exception;
  ----------------------------------------------------------------------------------
  function versione return varchar2 is
  /******************************************************************************
    NOME:        versione.
    DESCRIZIONE: Restituisce versione e revisione di distribuzione del package.
    RITORNA:     VARCHAR2 stringa contenente versione e revisione.
    NOTE:        Primo numero  : versione compatibilita del Package.
                 Secondo numero: revisione del Package specification.
                 Terzo numero  : revisione del Package body.
  ******************************************************************************/
  begin
     return s_revisione || '.' || s_revisione_body;
  end versione;
  ----------------------------------------------------------------------------------
  procedure DELETE_WRK_TRASMISSIONI is
  /******************************************************************************
    NOME:        DELETE_WRK_TRASMISSIONI.
    DESCRIZIONE: Elimina dalla tabella WRK_TRASMISSIONI le righe delle
                 elaborazioni precedenti.
    RITORNA:
    NOTE:
  ******************************************************************************/
  begin
    delete wrk_trasmissioni;
  exception
    when others then
      raise_application_error(-20999,'Errore in pulizia tabella di lavoro '||
                                     ' ('||sqlerrm||')');
  end;
  ----------------------------------------------------------------------------------
  procedure INSERT_WRK_TRASMISSIONI
  ( p_descr_chiave     varchar2
  , p_campo_chiave     varchar2
  , p_numero           number
  , p_dati             varchar2
  , p_dati2            varchar2 default null
  , p_dati3            varchar2 default null
  , p_dati4            varchar2 default null
  , p_dati5            varchar2 default null
  , p_dati6            varchar2 default null
  , p_dati7            varchar2 default null
  , p_dati8            varchar2 default null
  ) is
  /******************************************************************************
    NOME:        INSERT_WRK_TRASMISSIONI.
    DESCRIZIONE: Inserisce la riga preparata nella tabella WRK_TRASMISSIONI.
    RITORNA:
    NOTE:
  ******************************************************************************/
  begin
    insert into wrk_trasmissioni ( numero
                                 , dati
                                 , dati2
                                 , dati3
                                 , dati4
                                 , dati5
                                 , dati6
                                 , dati7
                                 , dati8
                                 )
    values ( lpad(to_char(p_numero),15,'0')
           , p_dati
           , p_dati2
           , p_dati3
           , p_dati4
           , p_dati5
           , p_dati6
           , p_dati7
           , p_dati8
           );
  exception
    when others then
      raise_application_error(-209999,'Ins. WRK_TRASMISSIONI riga n. ' ||to_char(p_numero)||
                                      ', '||p_descr_chiave||' '||p_campo_chiave||' - '||
                                      sqlerrm);
  end;
  ----------------------------------------------------------------------------------
  procedure INSERT_ANOMALIE_CARICAMENTO
  ( p_documento_id          number
  , p_sequenza              number
  , p_cognome               varchar2
  , p_nome                  varchar2
  , p_cod_fiscale           varchar2
  , p_descrizione           varchar2
  , p_note                  varchar2
  ) is
  /******************************************************************************
    NOME:        INSERT_ANOMALIE_CARICAMENTO.
    DESCRIZIONE: Inserisce la riga nella tabella ANOMALIE_CARICAMENTO.
    RITORNA:
    NOTE:
  ******************************************************************************/
  begin
    insert into anomalie_caricamento
                ( documento_id
                , sequenza
                , cognome
                , nome
                , cod_fiscale
                , descrizione
                , note
                )
         values ( p_documento_id
                , p_sequenza
                , p_cognome
                , p_nome
                , p_cod_fiscale
                , p_descrizione
                , p_note
                );
  exception
    when others then
      raise_application_error(-20999,'Ins. anomalie_caricamento '
                                     || ' (' || sqlerrm || ')');
  end;
  ----------------------------------------------------------------------------------
  procedure ESTRAZIONE_FILE_COMPLETO
  ( p_anno              in number
  , p_righe_estratte   out number
  ) is
  /******************************************************************************
    NOME:        ESTRAZIONE_FILE_COMPLETO.
    DESCRIZIONE: Estrae i dati completi da inviare ai centri di raccolta.
    RITORNA:     NUMBER        Numero di righe estratte.
    NOTE:
  ******************************************************************************/
    w_data_rif                   date;
    w_flag_dom                   number;
    w_cod_cliente                varchar2(18);
  begin
  cer_conferimenti.delete_wrk_trasmissioni;
  w_contarighe := 0;
  w_data_rif := to_date('0101'||p_anno,'ddmmyyyy');
  for cont in (select cont.cod_fiscale
                    , cont.ni
                    , sogg.tipo
                    , sogg.cod_fam
                    , min(decode(nvl(cate.flag_domestica,'N'),'S',2,3)) flag_dom_min
                    , max(decode(nvl(cate.flag_domestica,'N'),'S',2,3)) flag_dom_max
                 from contribuenti     cont
                    , soggetti         sogg
                    , oggetti_validita ogva
                    , oggetti_pratica  ogpr
                    , categorie        cate
                where ogva.tipo_tributo    = s_tipo_tributo
--                  and cont.cod_fiscale     is not null
                  and cont.ni              = sogg.ni
                  and cont.cod_fiscale     = ogva.cod_fiscale
                  and ogva.oggetto_pratica = ogpr.oggetto_pratica
                  and cate.tributo         = ogpr.tributo
                  and cate.categoria       = ogpr.categoria
--                  and ogpr.oggetto_pratica_rif_ap is null
--                  and ogpr.titolo_occupazione     is not null
--                  and ogpr.natura_occupazione     is not null
--                  and ogpr.destinazione_uso       is not null
                  and nvl(ogva.al,to_date('31/12/9999','dd/mm/yyyy')) >= w_data_rif
                group by cont.cod_fiscale, cont.ni, sogg.tipo, sogg.cod_fam
                order by 1
              )
  loop
    --
    -- Se per lo stesso contribuente esistono sia utenze domestiche che non domestiche,
    -- si registrano 2 righe per lo stesso codice fiscale con codici cliente diversi
    -- Il codice cliente è composto dal codice fiscale seguito da "/" e dalla lettera "D"
    -- per le utenze domestiche e dalla lettera "N" per le utenze non domestiche
    --
    w_flag_dom := cont.flag_dom_min;
    for w_flag_dom in cont.flag_dom_min..cont.flag_dom_max
    loop
      -- Si compone il codice cliente
      if w_flag_dom = 2 then
         w_cod_cliente := cont.cod_fiscale||'/D';
      else
         w_cod_cliente := cont.cod_fiscale||'/N';
      end if;
    --
      w_riga := '"'||cont.cod_fiscale||'";'||    -- cod. fiscale
                s_cod_comune||';'||              -- cod. comune
                '"'||w_cod_cliente||'";'||       -- cod. cliente
                w_flag_dom||';'||                -- id. Categoria utente
                1;                               -- Intestatario
      --
      w_contarighe := w_contarighe + 1;
      CER_CONFERIMENTI.INSERT_WRK_TRASMISSIONI ( 'Cod.fiscale intestatario'
                                               , cont.cod_fiscale
                                               , w_contarighe
                                               , w_riga
                                               );
      --
      if cont.cod_fam <> 0 then
         for fam in (select sogg.cod_fiscale
                       from soggetti sogg
                      where sogg.cod_fiscale is not null
                        and sogg.fascia + 0 = 1
                        and sogg.cod_fam = cont.cod_fam
                        and sogg.ni <> cont.ni
                        and add_months(sogg.data_nas,12*18) <= w_data_rif
                      order by sogg.cod_fiscale)
         loop
           w_riga := '"'||fam.cod_fiscale||'";'||   -- cod. fiscale
                     s_cod_comune||';'||            -- cod. comune
                     '"'||w_cod_cliente||'";'||     -- cod. cliente
                     w_flag_dom||';'||              -- id. Categoria utente
                     0;                             -- Intestatario
      --
           w_contarighe := w_contarighe + 1;
           CER_CONFERIMENTI.INSERT_WRK_TRASMISSIONI ( 'Cod.fiscale familiare'
                                                    , cont.cod_fiscale
                                                    , w_contarighe
                                                    , w_riga
                                                    );
         end loop;
      end if;
    end loop;
    w_flag_dom := w_flag_dom + 1;
  end loop;
  --
  p_righe_estratte := w_contarighe;
  end;
--------------------------------------------------------------------------
  procedure CARICA_CONFERIMENTI_CER
  ( p_documento_id     in      number
  , p_utente           in      varchar2
  , p_messaggio        in out  varchar2
  ) is
  /*************************************************************************
   NOME:        CARICA_CONFERIMENTI
   DESCRIZIONE: Caricamento dati conferimenti da file (Pontedera)
   RITORNA:     Messaggio di errore
   NOTE:
   Rev.    Author      Description
   03      VD          Aggiunta gestione conferimenti Fiorano Modenese
                       subordinata al codice ISTAT del comune di riferimento
   04      VD          Pontedera: aggiunta gestione conferimenti doppi.
                       Nel nuovo tracciato non sono previsti i secondi
                       nella data conferimento, quindi, se si effettuano
                       2 conferimenti nello stesso minuto, il secondo non
                       viene registrato per errore di chiave duplicata.
                       Modificato controllo su conferimento gia' presente:
                       ora controlla anche lo scontrino e la quantità.
                       Se esiste una riga con gli stessi valori di chiave
                       ma scontrino e quantità diversi, si memorizza
                       comunque il nuovo conferimento incrementando la data
                       di un secondo.
  *************************************************************************/
   -- w_commenti abilita le dbms_outpt, può avere i seguenti valori:
   --  0  =   Nessun Commento
   --  1  =   Commenti principali Ablitati
   w_commenti              number := 0;
   d_cod_istat             varchar2(6);
   w_documento_blob        blob;
   w_documento_clob        clob;
   dest_offset             number := 1;
   src_offset              number := 1;
   amount                  integer := DBMS_LOB.lobmaxsize;
   blob_csid               number  := DBMS_LOB.default_csid;
   lang_ctx                integer := DBMS_LOB.default_lang_ctx;
   warning                 integer;
   w_stato                 number;
   w_nome_documento        documenti_caricati.nome_documento%type;
   w_dimensione_file       number;
   w_posizione             number;
   w_posizione_old         number;
   w_riga                  varchar2 (32767);
   w_campo                 varchar2 (32767);
   w_cognome_nome          varchar2 (32767);
   w_separatore            varchar2(1) := ';';
   w_num_separatori        number;
   w_lunghezza_riga        number;
   w_inizio                number := 0;
   w_fine                  number;
   w_occorrenza            number;
   w_righe_presenti        number := 0;
   w_righe_caricate        number := 0;
   w_conta_anomalie        number := 0;
   w_cognome               soggetti.cognome%type;
   w_nome                  soggetti.nome%type;
   w_scontrino             conferimenti_cer.scontrino%type;
   w_quantita              conferimenti_cer.quantita%type;
   rec_conf                conferimenti_cer%rowtype;
   w_errore                varchar(2000) := NULL;
   errore                  exception;
   sql_errm                varchar2(100);
 begin
    if w_commenti > 0 then
       DBMS_OUTPUT.Put_Line('---- Inizio ----');
    end if;
    -- Estrazione dati cliente
    begin
      select lpad(to_char(pro_cliente),3,'0')||
             lpad(to_char(com_cliente),3,'0')
        into d_cod_istat
        from dati_generali;
    exception
      when others then
        sql_errm  := substr(SQLERRM,1,100);
        w_errore := 'Errore in selezione dati generali '||
                                      ' ('||sql_errm||')';
    end;
    -- Estrazione BLOB
    begin
      select contenuto
           , stato
           , nome_documento
        into w_documento_blob
           , w_stato
           , w_nome_documento
        from documenti_caricati doca
       where doca.documento_id  = p_documento_id
      ;
    end;
    if w_stato = 1 then
      -- Verifica dimensione file caricato
      w_dimensione_file:= DBMS_LOB.GETLENGTH(w_documento_blob);
      if nvl(w_dimensione_file,0) = 0 then
         w_errore := 'Attenzione File caricato Vuoto - Verificare Client Oracle';
         raise errore;
      end if;
      -- Trasformazione in CLOB
      begin
        DBMS_LOB.createtemporary (lob_loc =>   w_documento_clob
                                 ,cache =>     true
                                 ,dur =>       DBMS_LOB.session
                                 );
        DBMS_LOB.converttoclob (w_documento_clob
                               ,w_documento_blob
                               ,amount
                               ,dest_offset
                               ,src_offset
                               ,blob_csid
                               ,lang_ctx
                               ,warning
                               );
      exception
        when others then
          w_errore :=
            'Errore in trasformazione Blob in Clob  (' || sqlerrm || ')';
          raise errore;
      end;
      --
      w_posizione_old     := 1;
      w_posizione         := 1;
      --
      while w_posizione < w_dimensione_file
      loop
        w_posizione     := instr (w_documento_clob, chr (10), w_posizione_old);
        -- Se la posizione è 0, significa che siamo sull'ultima riga e manca il CR/LF finale
        if w_posizione = 0 then
           w_riga := substr (w_documento_clob, w_posizione_old);
           w_posizione := w_dimensione_file;
        else
           w_riga := substr (w_documento_clob, w_posizione_old, w_posizione-w_posizione_old+1);
        end if;
        w_righe_presenti := w_righe_presenti + 1;
        w_posizione_old := w_posizione + 1;
        -- Se l'ultimo carattere della riga non è ";", si aggiunge
        /*if substr(w_riga,-1) <> ';' then
           w_riga := w_riga || ';';
        end if;*/
        -- Determinazione numero di separatori presenti nella riga
        w_num_separatori      := length(w_riga) - length(replace(w_riga,w_separatore,''));
        w_lunghezza_riga      := length(w_riga);
        w_inizio              := 1;
        w_occorrenza          := 1;
        rec_conf              := null;
        rec_conf.documento_id := p_documento_id;
        --
        begin
          while w_occorrenza <= w_num_separatori
          loop
            w_fine := instr(w_riga,w_separatore,w_inizio,1);
            w_campo := rtrim(substr(w_riga,w_inizio,w_fine - w_inizio));
            --
            if d_cod_istat = '050029' then
               --
               -- Trattamento tracciato conferimenti per Pontedera
               --
               if w_occorrenza = 2 then
                  rec_conf.scontrino := w_campo;
               elsif
                  w_occorrenza = 4 then
                  rec_conf.codice_cer := w_campo;
               elsif
                  w_occorrenza = 6 then
                  rec_conf.data_conferimento := to_date(w_campo,'dd/mm/yyyy hh24:mi:ss');
                  --
                  -- Se il conferimento e' stato effettuato dal 1/7 in poi, viene
                  -- considerato di competenza dell'anno successivo
                  --
                 if to_number(to_char(to_date(w_campo,'dd/mm/yyyy hh24:mi:ss'),'mm')) > 6 then
                     rec_conf.anno := to_number(to_char(rec_conf.data_conferimento,'yyyy')) + 1;
                  else
                     rec_conf.anno := to_number(to_char(rec_conf.data_conferimento,'yyyy'));
                  end if;
               elsif
                  w_occorrenza = 7 then
                  rec_conf.quantita := to_number(replace(w_campo,',','.'),'9999d99');
               elsif
                  w_occorrenza = 8 then
                  rec_conf.cod_fiscale_conferente := w_campo;
               elsif
                  w_occorrenza = 9 then
                  rec_conf.cod_fiscale := replace(replace(w_campo,'/D',''),'/N','');
                  rec_conf.tipo_utenza := substr(w_campo,-1);
               end if;
            else
               -- Trattamento tracciato conferimenti per Fiorano Modenese
               rec_conf.codice_cer := '999999';
               if w_occorrenza = 1 then
                  rec_conf.scontrino := ltrim(w_campo,'0000RMO');
               elsif
                  w_occorrenza = 5 then
                  rec_conf.cod_fiscale := w_campo;
                  rec_conf.cod_fiscale_conferente := w_campo;
               elsif
                  w_occorrenza = 6 then
                  if nvl(rec_conf.cod_fiscale,'*') = '*' then
                     rec_conf.cod_fiscale := ltrim(w_campo,'IT');
                     rec_conf.cod_fiscale_conferente := ltrim(w_campo,'IT');
                  end if;
               elsif
                  w_occorrenza = 7 then
                  w_cognome_nome := w_campo;
               elsif
                  w_occorrenza = 10 then
                  if upper(substr(w_campo,1,9)) = 'DOMESTICI' then
                     rec_conf.tipo_utenza := 'D';
                  else
                     rec_conf.tipo_utenza := 'N';
                  end if;
               elsif
                  w_occorrenza = 13 then
                  --rec_conf.data_conferimento := to_date(w_campo,'dd/mm/yyyy');
                  rec_conf.data_conferimento := to_date('30/06/'||to_char(sysdate,'yyyy'),'dd/mm/yyyy');
                  --
                  -- Se il conferimento e' stato effettuato dal 1/7 in poi, viene
                  -- considerato di competenza dell'anno successivo
                  --
                 if to_number(to_char(to_date(w_campo,'dd/mm/yyyy'),'mm')) > 6 then
                     rec_conf.anno := to_number(to_char(rec_conf.data_conferimento,'yyyy')) + 1;
                  else
                     rec_conf.anno := to_number(to_char(rec_conf.data_conferimento,'yyyy'));
                  end if;
               elsif
                  w_occorrenza = 15 then
                  rec_conf.quantita := to_number(w_campo) * -1;
               end if;
            end if;
            w_occorrenza := w_occorrenza + 1;
            w_inizio := instr(w_riga,w_separatore,w_inizio,1) + 1;
          end loop;
        exception
           when others then
             w_errore := substr('Riga : '||w_riga||' - '||sqlerrm,1,2000);
             raise errore;
        end;
        -- Controllo esistenza contribuente
        begin
          select sogg.cognome
               , sogg.nome
               , null
            into w_cognome
               , w_nome
               , w_errore
            from contribuenti cont
               , soggetti     sogg
           where cont.ni          = sogg.ni
             and cont.cod_fiscale = rec_conf.cod_fiscale;
        exception
          when no_data_found then
            w_errore := 'Contribuente non presente';
            w_conta_anomalie := w_conta_anomalie + 1;
            -- inserimento anomalia caricamento - contribuente non esistente
            insert_anomalie_caricamento ( p_documento_id
                                        , w_conta_anomalie
                                        , substr(w_cognome_nome,1,60)
                                        , null
                                        , rec_conf.cod_fiscale
                                        , substr(w_errore,1,100)
                                        , substr(w_riga,1,2000)
                                        );
        end;
        if w_errore is null then
           if nvl(rec_conf.cod_fiscale,'*') <> '*'
           and rec_conf.anno              is not null
           and rec_conf.tipo_utenza       is not null
           and rec_conf.data_conferimento is not null
           and rec_conf.codice_cer        is not null
           and rec_conf.quantita          is not null then
              --
              -- Controllo esistenza record
              --
              begin
                select scontrino
                     , quantita
                  into w_scontrino
                     , w_quantita
                  from conferimenti_cer
                 where cod_fiscale       = rec_conf.cod_fiscale
                   and anno              = rec_conf.anno
                   and tipo_utenza       = rec_conf.tipo_utenza
                   and data_conferimento = rec_conf.data_conferimento
                   and codice_cer        = rec_conf.codice_cer;
              exception
                when no_data_found then
                  w_scontrino := null;
                  w_quantita := to_number(null);
                when too_many_rows then
                  w_errore := 'Conferimenti multipli: '||rec_conf.cod_fiscale||' '||
                              to_char(rec_conf.data_conferimento,'dd/mm/yyyy hh24.mi.ss')||' '||
                              rec_conf.codice_cer;
              end;
              if w_scontrino is not null then
                 if w_scontrino = rec_conf.scontrino and
                    w_quantita = rec_conf.quantita then
                    -- inserimento anomalia caricamento - dati gia' presenti
                    w_errore := 'Dati gia'' presenti';
                    w_conta_anomalie := w_conta_anomalie + 1;
                    insert_anomalie_caricamento ( p_documento_id
                                                , w_conta_anomalie
                                                , w_cognome
                                                , w_nome
                                                , rec_conf.cod_fiscale
                                                , substr(w_errore,1,100)
                                                , substr(w_riga,1,2000)
                                                );
                 else
                    rec_conf.data_conferimento := rec_conf.data_conferimento + 1/24/60/60;
                 end if;
              end if;
              if w_errore is null then
                 rec_conf.utente := p_utente;
                 rec_conf.note   := 'Caricamento da file '||w_nome_documento;
                 begin
                    insert into conferimenti_cer
                    values rec_conf;
                 exception
                   when others then
                     w_errore := substr('Ins. CONFERIMENTI (Contribuente: '
                              ||rec_conf.cod_fiscale||', Data conferimento: '||
                              to_char(rec_conf.data_conferimento,'dd/mm/yyyy hh24.mi.ss')
                              ||') - '
                              || sqlerrm,1,2000);
                     raise errore;
                 end;
                 w_righe_caricate := w_righe_caricate + 1;
              end if;
           end if;
        end if;
      end loop;
      -- Aggiornamento Stato
      begin
         update documenti_caricati
            set stato = 2
              , data_variazione = sysdate
              , utente = p_utente
              , note = 'Conferimenti: righe caricate '|| to_char(w_righe_caricate) ||', righe scartate: '||to_char(w_conta_anomalie)
          where documento_id = p_documento_id
              ;
      EXCEPTION
         WHEN others THEN
            sql_errm  := substr(SQLERRM,1,100);
            w_errore := 'Errore in Aggiornamento Stato del documento '||
                                       ' ('||sql_errm||')';
      end;
      p_messaggio := 'Caricate '|| to_char(w_righe_caricate) ||' righe di conferimenti.';
    end if;
  EXCEPTION
     WHEN ERRORE THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20999,nvl(w_errore,'vuoto'));
     WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20999,'Riga: '||w_righe_presenti||' '||to_char(SQLCODE)||' - '||substr(SQLERRM,1,100));
  end;
  procedure CALCOLO_PERIODO_CONF
  ( p_ruolo            in      number
  , p_dal              in out  date
  , p_al               in out  date
  )
  is
  /*************************************************************************
   NOME:        CALCOLO_PERIODO_CONF
   DESCRIZIONE: Determina il periodo per cui considerare i conferimenti in
                base al tipo di emissione del ruolo.
   RITORNA:     dal - data inizio periodo
                al  - data fine periodo
   NOTE:
   Rev.    Author      Description
   03      VD          Aggiunta gestione conferimenti Fiorano Modenese
                       subordinata al codice ISTAT del comune di riferimento
   *************************************************************************/
   d_cod_istat             varchar2(6);
   d_dal                   date;
   d_al                    date;
   sql_errm                varchar2(100);
   begin
     --
     -- Si controlla che il cliente sia Pontedera, altrimenti si restituiscono
     -- entrambe le date nulle
     --
     begin
       select lpad(to_char(pro_cliente),3,'0')||
              lpad(to_char(com_cliente),3,'0')
         into d_cod_istat
         from dati_generali;
     exception
       when others then
         sql_errm  := substr(SQLERRM,1,100);
         w_errore := 'Errore in selezione dati generali '||
                                       ' ('||sql_errm||')';
     end;
     --
     if d_cod_istat in ('050029','036013','037006') then
        begin
         select decode(tipo_emissione,'S',to_date('0101'||to_char(anno_ruolo),'ddmmyyyy')
                                         ,to_date('0107'||to_char(anno_ruolo - 1),'ddmmyyyy'))
              , decode(tipo_emissione,'A',to_date('3112'||to_char(anno_ruolo - 1),'ddmmyyyy')
                                         ,to_date('3006'||to_char(anno_ruolo),'ddmmyyyy'))
            into d_dal
               , d_al
            from ruoli
           where ruolo = p_ruolo;
        exception
          when others then
            d_dal := to_date(null);
            d_al := to_date(null);
        end;
     else
        d_dal := to_date(null);
        d_al := to_date(null);
     end if;
   --
   p_dal := d_dal;
   p_al  := d_al;
   end;
  function CALCOLO_FAMILIARI
  ( p_ni               in      number
  , p_dal              in      date
  , p_al               in      date
  ) return number
  is
  /*************************************************************************
   NOME:        CALCOLO_FAMILIARI
   DESCRIZIONE: Determina il numero dei familiari del contribuente per il
                periodo indicato.
   RITORNA:     Totale dei familiari ottenunto sommando i familiari per ogni
                mese del periodo indicato.
   NOTE:
   *************************************************************************/
    w_num_familiari            number;
    w_data_rif                 date;
  begin
    --
    -- Calcolo familiari per mese: per calcolare il peso massimo
    -- su cui applicare lo sconto, occorre conoscere il numero dei
    -- familiari per ogni mese del periodo
    --
    w_num_familiari := 0;
    w_data_rif := last_day(p_dal);
    while w_data_rif <= p_al
    loop
      --
      -- Per ogni mese compreso nel periodo si calcola il numero dei familiari
      -- e si memorizza nell'elemento del vettore relativo alla data di riferimento
      --
      w_num_familiari := w_num_familiari + f_numero_familiari_al_faso(p_ni,w_data_rif);
      w_data_rif := add_months(w_data_rif,1);
    end loop;
    --
    if w_num_familiari = 0 then
       w_num_familiari := 1;
    end if;
    --
    return w_num_familiari;
  --
  end;
  procedure DETERMINA_SCONTO_PERIODO
  ( p_anno             in      number
  , p_ruolo            in      number
  , p_tipo_ruolo       in      number
  , p_tipo_emissione   in      varchar2
  , p_cod_fiscale      in      varchar2
  , p_num_familiari    in      number
  , p_dal              in      date
  , p_al               in      date
  , p_utente           in      varchar2
  ) is
  /*************************************************************************
   NOME:        DETERMINA_SCONTO_PERIODO
   DESCRIZIONE: Determina l'importo da scontare in base ai conferimenti
                effettuati nel periodo indicato.
                Inserisce gli sconti calcolati nella tabella
                CONFERIMENTI_CER_RUOLO.
   RITORNA:
   NOTE:
   *************************************************************************/
    w_peso_max                 number;
    w_tot_peso                 number;
    w_quantita                 number;
    w_sconto                   number;
    w_note                     varchar2(2000);
  begin
    --
    -- Determinazione del peso massimo di materiale conferito per il quale
    -- applicare lo sconto: si divide per 12 il valore presente nel dizionario
    -- (per determinare il peso massimo conferibile al mese), lo si moltiplica
    -- per il numero dei familiari del mese e si totalizza.
    -- Una volta ottenuto un valore complessivo, si verifica se il conferimento
    -- rientra tutto o in parte nel massimo peso conferibile
    --
    for rice in ( select rice.anno
                       , rice.tipo_utenza
                       , rice.codice_cer
                       , rice.peso_max
                       , round(rice.peso_max / 12,2) peso_mens
                       , rice.sconto_kg
                    from RIDUZIONI_CER rice
                   where rice.anno = p_anno
                     and exists (select 'x' from conferimenti_cer coce
                                  where coce.cod_fiscale = p_cod_fiscale
                                    and coce.anno = rice.anno
                                    and coce.tipo_utenza = rice.tipo_utenza
                                    and coce.codice_cer = rice.codice_cer
                                    and trunc(coce.data_conferimento) between p_dal and p_al)
                   order by 1,2,3
                )
    loop
      -- Per le utenze domestiche, si considera il peso massimo conferibile mensile moltiplicato
      -- per il numero di familiari di ogni mese.
      -- Per le utenze non domestiche, si considera il peso massimo semestrale (peso massimo
      -- presente sul dizionario / 2).
      if rice.tipo_utenza = 'D' then
         w_peso_max := rice.peso_mens * p_num_familiari;
      else
         w_peso_max := round(rice.peso_max / 2,0);
      end if;
      --
      -- Si scorrono i conferimenti del periodo e si determina lo sconto
      --
      w_tot_peso := 0;
      for conf in ( select coce.data_conferimento
                         , coce.quantita
                      from CONFERIMENTI_CER coce
                     where coce.anno = rice.anno
                       and coce.cod_fiscale = p_cod_fiscale
                       and trunc(coce.data_conferimento) between p_dal and p_al
                       and coce.tipo_utenza = rice.tipo_utenza
                       and coce.codice_cer = rice.codice_cer
                     order by 1
                  )
      loop
        if w_tot_peso + conf.quantita < w_peso_max then
           w_quantita := conf.quantita;
        else
           w_quantita:= w_peso_max - w_tot_peso;
        end if;
        w_sconto   := round(rice.sconto_kg * w_quantita,2);
        w_tot_peso := w_tot_peso + w_quantita;
        --
        -- Si inserisce la riga nella tabella CONFERIMENTI_CER_RUOLO per memorizzare
        -- in quale ruolo è stato conteggiato il conferimento
        --
        if w_sconto > 0 then
           begin
             insert into CONFERIMENTI_CER_RUOLO
                    ( cod_fiscale, anno, tipo_utenza,
                      data_conferimento, codice_cer,
                      sequenza, quantita, importo_calcolato,
                      ruolo, utente, data_variazione, note
                    )
             values ( p_cod_fiscale, rice.anno, rice.tipo_utenza,
                      conf.data_conferimento, rice.codice_cer,
                      null, w_quantita, w_sconto,
                      p_ruolo, p_utente, trunc(sysdate), w_note
                    );
           exception
             when others then
               w_errore := 'Errore in Inserimento CONFERIMENTI_CER_RUOLO (cf: ' || p_cod_fiscale ||
                           ') - ';
               raise;
           end;
        end if;
      end loop;
    end loop;
/*           elsif p_tipo_emissione = 'S' and
              p_tipo_ruolo = 2 and
              to_char(p_dal,'ddmm') = '0101' then
              begin
                select quantita
                     , importo_scalato
                     , 'Sconto su conferimenti su ruolo suppletivo'
                  into w_qta_da_scalare
                     , w_imp_da_scalare
                     , w_note
                  from CONFERIMENTI_CER_RUOLO cocr
                     , RUOLI                  ruol
                 where cocr.cod_fiscale = p_cod_fiscale
--                   and cocr.anno = p_anno
                   and cocr.tipo_utenza = rice.tipo_utenza
                   and cocr.data_conferimento = conf.data_conferimento
                   and cocr.codice_cer = rice.codice_cer
                   and cocr.ruolo <> p_ruolo
                   and cocr.ruolo = ruol.ruolo
                   and ruol.anno_ruolo = p_anno
                   and ruol.tipo_tributo = s_tipo_tributo
                   and nvl(ruol.tipo_emissione,'T') = 'S'
                   and ruol.tipo_ruolo = 1
                   and ruol.invio_consorzio is not null;
              exception
                when others then
                  w_qta_da_scalare  := 0;
                  w_imp_da_scalare  := 0;
                  w_note            := '';
              end;
           else
              w_qta_da_scalare  := 0;
              w_imp_da_scalare  := 0;
              w_note            := '';
           end if; */
   exception
    when others then
      raise_application_error(-20999,w_errore||sqlerrm);
  end;
  procedure DETERMINA_SCONTO_CONF
  ( p_anno             in      number
  , p_ruolo            in      number
  , p_tipo_ruolo       in      number
  , p_tipo_emissione   in      varchar2
  , p_cod_fiscale      in      varchar2
  , p_utente           in      varchar2
  ) is
  /*************************************************************************
   NOME:        DETERMINA_SCONTO_CONF
   DESCRIZIONE: Determina l'importo da scontare in base ai conferimenti
                effettuati per i contribuenti per cui è stato emesso il
                ruolo. Successivamente scala l'importo calcolato dal
                ruolo emesso.
   RITORNA:
   NOTE:        Il periodo per trattare i conferimenti viene così determinato:
                - se tipo emissione ruolo = 'A' (Acconto), dal 01/07 al 31/12
                  dell'anno precedente a quello del ruolo;
                - se tipo emissione ruolo = 'S' (Saldo), dal 01/01 al 30/06
                  dell'anno del ruolo
                - se tipo emissione ruolo = 'T' (Totale), dal 01/07 dell'anno
                  precedente al 30/06 dell'anno del ruolo.
   *************************************************************************/
    w_dal                      date;
    w_al                       date;
    w_dal_acc                  date;
    w_al_acc                   date;
    w_dal_sal                  date;
    w_al_sal                   date;
    w_ni                       number;
    w_num_familiari            number;
    w_ruolo_acc                number;
  begin
    --
    -- Annullamento eventuali elaborazioni precedenti
    --
    cer_conferimenti.elimina_ruolo_conf ( p_ruolo, p_cod_fiscale );
    --
    -- Determinazione periodi per calcolo conferimenti
    --
    begin
      select to_date('0107'||to_char(p_anno - 1),'ddmmyyyy')
           , to_date('3112'||to_char(p_anno - 1),'ddmmyyyy')
            , decode(p_tipo_emissione,'A',to_date(null)
                                        ,to_date('0101'||to_char(p_anno),'ddmmyyyy'))
           , decode(p_tipo_emissione,'A',to_date(null)
                                        ,to_date('3006'||to_char(p_anno),'ddmmyyyy'))
           , to_date('0107'||to_char(p_anno - 1),'ddmmyyyy')
            , to_date('3006'||to_char(p_anno),'ddmmyyyy')
        into w_dal_acc
           , w_al_acc
           , w_dal_sal
           , w_al_sal
           , w_dal
           , w_al
        from dual;
    exception
      when others then
        w_errore := 'Calcolo periodo - '||sqlerrm;
        raise;
    end;
    --
    -- Se si sta trattando un ruolo totale, si controlla se esiste
    -- un ruolo in acconto gia' inviato
    --
    begin
      select ruolo
        into w_ruolo_acc
        from ruoli
       where anno_ruolo = p_anno
         and tipo_tributo = s_tipo_tributo
         and nvl(tipo_emissione,'T') = 'A'
         and invio_consorzio is not null;
    exception
      when others then
        w_ruolo_acc := to_number(null);
    end;
    --
    -- Si esegue un ciclo sui contribuenti che hanno effettuato conferimenti
    -- nel periodo determinato e per ognuno si calcolano gli sconti
    --
    for cont in (select distinct coce.cod_fiscale
                   from conferimenti_cer coce
                      , riduzioni_cer    rice
                  where coce.cod_fiscale like p_cod_fiscale
                    and coce.anno = p_anno
                    and coce.data_conferimento between w_dal and w_al
                    and coce.anno = rice.anno
                    and coce.tipo_utenza = rice.tipo_utenza
                    and coce.codice_cer = rice.codice_cer
                  order by 1)
    loop
      --
      -- Determinazione dell'ni del contribuente per il calcolo
      -- dei familiari
      --
      begin
        select ni
          into w_ni
          from contribuenti
         where cod_fiscale = cont.cod_fiscale;
      exception
        when others then
          w_errore := 'Ricerca ni '||cont.cod_fiscale||' - '||sqlerrm;
          raise;
      end;
      --
      -- Si calcolano i familiari e i conferimenti relativi al periodo
      -- del ruolo di acconto (secondo semestre dell'anno precedente)
      --
      if p_tipo_emissione = 'A' then
         w_num_familiari := cer_conferimenti.calcolo_familiari ( w_ni
                                                               , w_dal_acc
                                                               , w_al_acc
                                                               );
         cer_conferimenti.determina_sconto_periodo ( p_anno
                                                   , p_ruolo
                                                   , p_tipo_ruolo
                                                   , p_tipo_emissione
                                                   , cont.cod_fiscale
                                                   , w_num_familiari
                                                   , w_dal_acc
                                                   , w_al_acc
                                                   , p_utente
                                                   );
      end if;
      --
      -- Se si tratta di un ruolo a saldo o totale si calcolano
      -- i familiari e i conferimenti relativi al periodo
      -- del ruolo a saldo (primo semestre dell'anno)
      --
      if p_tipo_emissione in ('S','T') then
         w_num_familiari := cer_conferimenti.calcolo_familiari ( w_ni
                                                               , w_dal_sal
                                                               , w_al_sal
                                                               );
         cer_conferimenti.determina_sconto_periodo ( p_anno
                                                   , p_ruolo
                                                   , p_tipo_ruolo
                                                   , p_tipo_emissione
                                                   , cont.cod_fiscale
                                                   , w_num_familiari
                                                   , w_dal_sal
                                                   , w_al_sal
                                                   , p_utente
                                                   );
         --
         -- In caso di ruolo totale (o a saldo?), si riportano gli stessi sconti effettuati sul ruolo
         -- in acconto sul ruolo totale
         --
         --if p_tipo_emissione = 'T' and
         if p_tipo_ruolo = 1 then
            if w_ruolo_acc is null then
               --
               -- Se non esiste un ruolo in acconto inviato, si calcolano i
               -- conferimenti dell'acconto con la procedura standard
               --
               w_num_familiari := cer_conferimenti.calcolo_familiari ( w_ni
                                                                     , w_dal_acc
                                                                     , w_al_acc
                                                                     );
               cer_conferimenti.determina_sconto_periodo ( p_anno
                                                         , p_ruolo
                                                         , p_tipo_ruolo
                                                         , p_tipo_emissione
                                                         , cont.cod_fiscale
                                                         , w_num_familiari
                                                         , w_dal_acc
                                                         , w_al_acc
                                                         , p_utente
                                                         );
            else
               --
               -- Se esiste un ruolo in acconto gia' inviato, si
               -- attribuiscono i conferimenti già calcolati anche
               -- al ruolo totale
               --
               for acc in (select cocr.cod_fiscale
                                , cocr.anno
                                , cocr.tipo_utenza
                                , cocr.data_conferimento
                                , cocr.codice_cer
                                , cocr.quantita
                                , p_ruolo
                                , cocr.importo_scalato
                             from CONFERIMENTI_CER_RUOLO cocr
                            where cocr.cod_fiscale = p_cod_fiscale
                              and cocr.anno = p_anno
                              and cocr.ruolo <> p_ruolo
                              and cocr.ruolo = w_ruolo_acc)
               loop
                 begin
                   insert into CONFERIMENTI_CER_RUOLO
                          ( cod_fiscale, anno, tipo_utenza,
                            data_conferimento, codice_cer,
                            sequenza, quantita, importo_calcolato,
                            ruolo, utente, data_variazione, note
                          )
                   values ( acc.cod_fiscale, acc.anno, acc.tipo_utenza,
                            acc.data_conferimento, acc.codice_cer,
                            null, acc.quantita, acc.importo_scalato,
                            p_ruolo, p_utente, trunc(sysdate),
                            'Sconto per conferimenti su ruolo acconto'
                          );
                 exception
                   when others then
                     w_errore := 'Errore in Inserimento CONFERIMENTI_CER_RUOLO (cf: ' || p_cod_fiscale ||
                                 ') - ';
                     raise;
                 end;
               end loop;
            end if;
         end if;
      end if;
    end loop;
  --
  -- Al termine del trattamento dei contribuenti che hanno effettuato conferimenti nel periodo indicato,
  -- in caso di ruolo a saldo
  --
  exception
    when others then
      raise_application_error(-20999,w_errore||sqlerrm);
  end;
/*  procedure DETERMINA_SCONTO_CONF_ACC
  ( p_anno             in      number
  , p_ruolo            in      number
  , p_cod_fiscale      in      varchar2
  , p_sconto_dom       out     number
  , p_sconto_nd        out     number
  ) is
  \*************************************************************************
   NOME:        DETERMINA_SCONTO_CONF_ACC
   DESCRIZIONE: Utilizzata nel trattamento dei ruoli totali o a saldo.
                Determina l'importo già scontato nei ruoli in acconto.
   RITORNA:     Importo da scontare, diviso per utenza domestica e non
                domestica
   NOTE:
  *************************************************************************\
    w_tipo_emissione     ruoli.tipo_emissione%type;
    w_sconto_dom         number := 0;
    w_sconto_nd          number := 0;
  begin
    --
    -- Determinazione del tipo emissione del ruolo
    --
    begin
      select tipo_emissione
        into w_tipo_emissione
        from ruoli
       where ruolo = p_ruolo;
    exception
      when others then
        w_errore := 'Select RUOLI ('||p_ruolo||') - '||sqlerrm;
        raise;
    end;
    --
    -- Se si tratta di un ruolo a saldo o totale, si ricercano
    -- i ruoli in acconto per calcolare gli eventuali kg già
    -- conferiti e scontati precedentemente
    --
    if w_tipo_emissione in ('T','S') then
       select sum(decode(tipo_utenza,'D',importo_scalato,0))
            , sum(decode(tipo_utenza,'D',0,importo_scalato))
         into w_sconto_dom
            , w_sconto_nd
         from CONFERIMENTI_CER coce
            , RUOLI            ruol
        where coce.anno = p_anno
          and coce.cod_fiscale = p_cod_fiscale
          and coce.ruolo is not null
          and coce.ruolo = ruol.ruolo
          and ruol.anno_ruolo = p_anno
          and nvl(ruol.tipo_emissione,'T') = 'A'
          and ruol.invio_consorzio is not null;
    else
       w_sconto_dom := 0;
       w_sconto_nd  := 0;
    end if;
  --
    p_sconto_dom := nvl(w_sconto_dom,0);
    p_sconto_nd  := nvl(w_sconto_nd,0);
  --
  exception
    when others then
      raise_application_error(-20999,w_errore||sqlerrm);
  end;*/
  procedure ELIMINA_RUOLO_CONF
  ( p_ruolo            in      number
  , p_cod_fiscale      in      varchar2
  ) is
  /*************************************************************************
   NOME:        ELIMINA_RUOLO_CONF
   DESCRIZIONE: Cancella tutte le righe della tabella SCONTI_CONFERIMENTO_CER
                del ruolo indicato.
   RITORNA:
   NOTE:
  *************************************************************************/
  begin
    begin
      delete CONFERIMENTI_CER_RUOLO
       where cod_fiscale like p_cod_fiscale
         and ruolo = p_ruolo;
    exception
      when others then
        raise_application_error(-20999,'Eliminazione ruolo '||p_ruolo||': '||sqlerrm);
    end;
  end;
  function F_ULTIMO_RUOLO_CONF
  ( p_cod_fiscale      in      varchar2
  , p_anno             in      number
  , p_tipo_utenza      in      varchar2
  , p_data_conferimento in     date
  , p_codice_cer       in      varchar2
  ) return number
  is
  /*************************************************************************
   NOME:        F_ULTIMO_RUOLO_CONF
   DESCRIZIONE: Determina l'ultimo ruolo in cui è stato inserito un certo
                conferimento
   RITORNA:     Ruolo.
   NOTE:
   *************************************************************************/
   d_tipo_tributo         varchar2(5) := 'TARSU';
   d_contarighe           number := 0;
   d_ruolo                number;
   begin
     d_ruolo := to_number(null);
     for ruol in (select ruolo
                       , anno_ruolo
                       , invio_consorzio
                    from RUOLI ruol
                   where ruol.tipo_tributo = d_tipo_tributo
                     and ruol.invio_consorzio is not null
                     and exists (select 'x'
                                   from CONFERIMENTI_CER_RUOLO cer
                                  where cer.cod_fiscale       = p_cod_fiscale
                                    and cer.anno              = p_anno
                                    and cer.tipo_utenza         = p_tipo_utenza
                                    and cer.data_conferimento = p_data_conferimento
                                    and cer.codice_cer        = p_codice_cer
                                    and cer.ruolo             = ruol.ruolo)
                   order by 3 desc)
     loop
       d_contarighe := d_contarighe + 1;
       if d_contarighe = 1 then
          d_ruolo := ruol.ruolo;
       else
          exit;
       end if;
     end loop;
     --
     -- Se il risultato e' nullo, si esegue la ricerca sui ruoli non inviati
     --
     if d_ruolo is null then
        for ruol in (select ruolo
                          , anno_ruolo
                          , data_emissione
                       from RUOLI ruol
                      where ruol.tipo_tributo = d_tipo_tributo
                        and ruol.invio_consorzio is null
                        and exists (select 'x'
                                      from CONFERIMENTI_CER_RUOLO cer
                                     where cer.cod_fiscale       = p_cod_fiscale
                                       and cer.anno              = p_anno
                                       and cer.tipo_utenza         = p_tipo_utenza
                                       and cer.data_conferimento = p_data_conferimento
                                       and cer.codice_cer        = p_codice_cer
                                       and cer.ruolo             = ruol.ruolo)
                      order by 3 desc)
        loop
          d_contarighe := d_contarighe + 1;
          if d_contarighe = 1 then
             d_ruolo := ruol.ruolo;
          else
             exit;
          end if;
        end loop;
     end if;
   --
     return d_ruolo;
   --
  end;
  function F_IMPORTO_RUOLO_CONF
  ( p_cod_fiscale      in      varchar2
  , p_anno             in      number
  , p_tipo_utenza      in      varchar2
  , p_data_conferimento in     date
  , p_codice_cer       in      varchar2
  , p_ruolo            in      number default null
  ) return number
  is
  /*************************************************************************
   NOME:        F_IMPORTO_RUOLO_CONF
   DESCRIZIONE: Determina l'importo scontato sul ruolo relativamente al
                singolo conferimento
   RITORNA:     Importo scontato.
   NOTE:
   *************************************************************************/
   d_importo_scalato      number;
   d_ruolo                number;
   begin
     if p_ruolo is null then
        d_ruolo := cer_conferimenti.f_ultimo_ruolo_conf ( p_cod_fiscale
                                                        , p_anno
                                                        , p_tipo_utenza
                                                        , p_data_conferimento
                                                        , p_codice_cer
                                                        );
     else
        d_ruolo := p_ruolo;
     end if;
  --
     if d_ruolo is not null then
        select sum(importo_scalato)
          into d_importo_scalato
          from CONFERIMENTI_CER_RUOLO cer
         where cer.cod_fiscale       = p_cod_fiscale
           and cer.anno              = p_anno
           and cer.tipo_utenza         = p_tipo_utenza
           and cer.data_conferimento = p_data_conferimento
           and cer.codice_cer        = p_codice_cer
           and cer.ruolo             = d_ruolo;
     else
        d_importo_scalato := to_number(null);
     end if;
  --
     return d_importo_scalato;
  --
   end;
  function F_CONF_MODIFICABILE
  ( p_cod_fiscale      in      varchar2
  , p_anno             in      number
  , p_tipo_utenza      in      varchar2
  , p_data_conferimento in     date
  , p_codice_cer       in      varchar2
  ) return number
  is
  /*************************************************************************
   NOME:        F_CONF_MODIFICABILE
   DESCRIZIONE: Verifica se il conferimento indicato è stato assegnato a
                uno o più ruoli.
   RITORNA:     0 - Riga modificabile
                1 - Riga non modificabile.
   NOTE:
   *************************************************************************/
   d_result                    number;
   begin
     --
     -- Se il conferimento non è ancora stato inserito in nessun ruolo,
     -- i dati sono completamente modificabili
     --
     begin
       select 0
         into d_result
         from dual
        where not exists (select 'x'
                            from conferimenti_cer_ruolo coce
                           where coce.cod_fiscale       = p_cod_fiscale
                             and coce.anno              = p_anno
                             and coce.tipo_utenza         = p_tipo_utenza
                             and coce.data_conferimento = p_data_conferimento
                             and coce.codice_cer        = p_codice_cer
                             and coce.importo_scalato   > 0
                             and coce.ruolo             is not null);
     exception
       when others then
         d_result := 1;
     end;
   --
     return d_result;
   --
   end;
  function F_CONF_QTA_MODIFICABILE
  ( p_cod_fiscale      in      varchar2
  , p_anno             in      number
  , p_tipo_utenza      in      varchar2
  , p_data_conferimento in     date
  , p_codice_cer       in      varchar2
  ) return number
  is
  /*************************************************************************
   NOME:        F_CONF_QTA_MODIFICABILE
   DESCRIZIONE: Verifica se il conferimento indicato è stato assegnato a
                uno o più ruoli inviati; se
   RITORNA:     0 - Riga modificabile
                1 - Riga non modificabile.
   NOTE:
   *************************************************************************/
   d_result                    number;
   begin
     --
     -- Se il conferimento è stato inserito solo in ruoli non inviati,
     -- la quantità è modificabile solo da menù contestuale
     --
     begin
       select 0
         into d_result
         from dual
        where not exists (select 'x'
                            from conferimenti_cer_ruolo coce
                               , ruoli                  ruol
                           where coce.cod_fiscale       = p_cod_fiscale
                             and coce.anno              = p_anno
                             and coce.tipo_utenza         = p_tipo_utenza
                             and coce.data_conferimento = p_data_conferimento
                             and coce.codice_cer        = p_codice_cer
                             and coce.importo_scalato   > 0
                             and coce.ruolo             = ruol.ruolo
                             and ruol.invio_consorzio is not null);
     exception
       when others then
         d_result := 1;
     end;
     --
     return d_result;
     --
   end;
  function F_CONF_RUOLO_MODIFICABILE
  ( p_ruolo            in      number
  ) return number
  is
  /*************************************************************************
   NOME:        F_CONF_RUOLO_MODIFICABILE
   DESCRIZIONE: Verifica se il ruolo presente sulla tabella CONFERIMENTI_CER_RUOLO
                è stato inviato: se sì, la riga non nè modificabile nè
                cancellabile.
   RITORNA:     0 - Riga modificabile
                1 - Riga non modificabile.
   NOTE:
   *************************************************************************/
   d_result                    number;
   begin
     begin
       select 0
         into d_result
         from ruoli
        where ruolo = p_ruolo
          and invio_consorzio is null;
     exception
       when others then
         d_result := 1;
     end;
   --
     return d_result;
   --
   end;
end cer_conferimenti;
/

