--liquibase formatted sql 
--changeset abrandolini:20250326_152423_gestione_successioni_titr stripComments:false runOnChange:true 
 
create or replace procedure GESTIONE_SUCCESSIONI_TITR
/*************************************************************************
 NOME:        GESTIONE_SUCCESSIONI_TITR
 DESCRIZIONE: Carica le pratiche per il defunto e gli eredi inerenti
              al tipo tributo passato come parametro
 NOTE:        A_CTR_DENUNCIA assume i seguenti valori:
              'S' - controlla se esiste gia' una denuncia per il
                    contribuente da trattare
              'N' - Inserisce sempre una nuova denuncia
              A_SEZIONE_UNICA assume i seguenti valori:
              'S' - per il trattamento dei dati catastali si considera la
                    sezione = null
              'N' - per il trattamento dei dati catastali si considera la
                    sezione presente sul file
  Rev.    Date         Author      Note
  8       07/06/2023   VM          #63046 - Controllo su validita del denominatore_quota 
                                   per il calcolo della percentuale possesso dell'erede
  7       11/02/2020   VD          Aggiunto test indice array per non
                                   lanciare l'archiviazione se l'array
                                   e' vuoto
  6       10/01/2020   VD          Aggiunta archiviazione denunce
  5       18/10/2019   VD          Corretta composizione estremi catasto:
                                   sostituita RPAD con LPAD
  4       19/03/2019   VD          Correzione errori vari: se denuncia gia'
                                   esistente aggiornava la pratica nella
                                   tabella SUCCESSIONE_TRIBUTO_DEFUNTI con
                                   l'ultima pratica inserita (invece che con
                                   null). Inoltre, se l'ultima pratica
                                   inserita veniva eliminata per mancanza
                                   di oggetti, cercava comunque di aggiornare
                                   con una pratica non esistente.
                                   Ora, se denuncia gia' esistente aggiorna
                                   la tabella con il valore null, se denuncia
                                   non esistente aggiorna la tabella con
                                   la denuncia relativa al defunto.
                                   Nel caso di TASI pre 2014, aggiorna con
                                   pratica defunto null.
  3       26/11/2018   VD          Aggiunta memorizzazione valore immobile
                                   presente sul file (se il valore di denuncia
                                   non viene trovato)
  2       15/05/2017   VD          Corretta join con RAPPORTI_TRIBUTO
                                   Modificata gestione oggetti nel caso
                                   di TASI ante 2014 (i dati degli oggetti
                                   vengono memorizzati negli array anche
                                   se la pratica per il defunto non viene
                                   inserita)
  1       23/03/2015   VD          Modificata query principale per
                                   analogia con calcolo imposta ICI:
                                   nella subquery non si considera più
                                   il flag_possesso = 'S'
                                   (vv modifica CALCOLO_IMPOSTA_TASI)
  0                                Prima emissione
*************************************************************************/
( a_documento_id           in      number
, a_utente                 in      varchar2
, a_ctr_denuncia           in      varchar2
, a_sezione_unica          in      varchar2
, a_fonte                  in      number
, a_tipo_tributo           in      varchar2
, a_nuove_pratiche         in out  number
, a_nuovi_oggetti          in out  number
, a_nuovi_contribuenti     in out  number
, a_nuovi_soggetti         in out  number
, a_pratiche_gia_inserite  in out  number
)
is
-- w_commenti abilita le dbms_outpt, può avere i seguenti valori:
--  0  =   Nessun Commento
--  1  =   Commenti principali Abilitati
w_commenti                             number := 0;
w_errore                               varchar(2000) := NULL;
errore                                 exception;
sql_errm                               varchar2(100);
w_cod_istat                            varchar2(6);
w_flag_integrato                       varchar2(1);
w_tipo_residente                       number(1);
w_controllo                            number;
w_estremi_catasto                      varchar(20);
w_cod_via                              number;
w_oggetto                              number;
w_tipo_oggetto                         number;
w_categoria                            varchar2(3);
w_sezione                              varchar2(3);
w_rendita                              number(15,2);
w_valore_ogpr                          number(15,2);
w_valore_ogpr_den_def_prec             number(15,2);
w_anno_den_def_prec                    number(4);
w_tipo_pratica_den_def_prec            varchar2(1);
w_flag_valore_riv_den_def_prec         varchar2(1);
w_cod_fiscale_def                      varchar2(16);
w_ni_def                               number(10);
w_cod_fiscale_erede                    varchar2(16);
w_ni_erede                             number(10);
w_cod_com_nas                          number(3) := null;
w_cod_pro_nas                          number(3) := null;
w_cod_com_res                          number(3) := null;
w_cod_pro_res                          number(3) := null;
w_comune_def                           varchar2(4);
w_comune_erede                         varchar2(4);
w_anno_denuncia                        number(4);
w_defunto_pre_2014_tasi                number(4) := 0; -- per i defunti pre 2014, la pratica TASI si carica solo per gli eredi
w_detrazione_base                      number(15,2);
w_perc_possesso_def                    number(5,2);
w_perc_possesso_erede                  number(5,2);
w_pratica                              number(10);
w_pratica_defunto                      number(10);
w_oggetto_pratica                      number(10);
w_num_ordine                           number;
w_pratica_esistente                    number := 0;
w_pratica_inserita                     varchar2(1);
w_mesi_possesso_def                    number(2);
w_mesi_possesso_1sem_def               number(2);
w_flag_ab_principale                   varchar2(1);
w_flag_possesso_prec                   varchar2(1);
w_detrazione                           number(15,2);
w_mesi_possesso_erede                  number(2);
w_mesi_possesso_1sem_erede             number(2);
w_num_nuove_pratiche                   number := 0;
w_num_nuovi_oggetti                    number := 0;
w_num_nuovi_contribuenti               number := 0;
w_num_nuovi_soggetti                   number := 0;
w_pratiche_gia_inserite                number := 0;
w_num_nuovi_ogpr                       number := 0;
w_max_numero_ordine_erede              number := 0;
w_perc_possesso_prec                   number(5,2);
w_tipo_oggetto_prec                    number;
w_categoria_prec                       varchar2(3);
w_classe_prec                          varchar2(2);
w_valore_prec                          number(15,2);
w_titolo_prec                          varchar2(1);
w_flag_esclusione_prec                 varchar2(1);
w_flag_ab_princ_prec                   varchar2(1);
w_detrazione_prec                      number(15,2);
w_anno_den_ere_prec                    number;
w_tipo_pratica_prec                    varchar2(1);
w_flag_valore_riv_prec                 varchar2(1);
w_conta_ogpr                           number;
w_trova_erede                          number;
TYPE type_oggetto IS TABLE OF oggetti.oggetto%TYPE
INDEX BY varchar2(15);
TYPE type_tipo_oggetto IS TABLE OF oggetti.tipo_oggetto%TYPE
INDEX BY varchar2(15);
TYPE type_categoria IS TABLE OF oggetti.categoria_catasto%TYPE
INDEX BY varchar2(15);
TYPE type_perc_pos_def IS TABLE OF oggetti_contribuente.perc_possesso%TYPE
INDEX BY varchar2(15);
TYPE type_valore_ogpr IS TABLE OF oggetti_pratica.valore%TYPE
INDEX BY varchar2(15);
TYPE type_stato_successione IS TABLE OF successioni_defunti.stato_successione%TYPE
INDEX BY varchar2(10);
t_oggetto        type_oggetto;
t_tipo_oggetto   type_tipo_oggetto;
t_categoria      type_categoria;
t_perc_pos_def   type_perc_pos_def;
t_valore_ogpr    type_valore_ogpr;
t_stsu           type_stato_successione;
-- (VD - 10/01/2020): Variabili per archiviazione denunce
TYPE type_pratica IS TABLE OF pratiche_tributo.pratica%type
INDEX BY BINARY_INTEGER;
t_pratica        type_pratica;
w_ind            number := 0;
CURSOR sel_def IS
   select sude.cod_fiscale
        , sude.successione
        , sude.comune
        , sude.anno
        , sude.cognome
        , sude.nome
        , sude.sesso
        , sude.citta_res
        , sude.prov_res
        , sude.indirizzo
        , sude.citta_nas
        , sude.prov_nas
        , sude.data_nas
        , sude.data_apertura
     from successioni_defunti  sude, successioni_tributo_defunti sutd
    where sude.successione = sutd.successione
      and sutd.stato_successione = 'DA GESTIRE'
      and sutd.tipo_tributo = a_tipo_tributo
 order by sude.data_apertura
        ;
CURSOR sel_immo (p_successione number) IS
   select suim.progressivo
        , suim.catasto
        , suim.natura
        , suim.sezione
        , suim.foglio          foglio
        , suim.particella_1    numero
        , decode(suim.subalterno_1
                ,0,null
                ,suim.subalterno_1
                )              subalterno
        , suim.denuncia_1      protocollo_catasto
        , suim.anno_denuncia   anno_catasto
        , suim.indirizzo
        , suim.superficie_mq
        , suim.superficie_ettari
        , suim.vani
        , suim.numeratore_quota_def
        , suim.denominatore_quota_def
        , suim.valore
     from successioni_immobili suim
    where suim.successione = p_successione
        ;
CURSOR sel_eredi (p_successione number) IS
   select suer.progressivo
        , suer.progr_erede
        , suer.cod_fiscale
        , suer.cognome
        , suer.nome
        , suer.denominazione
        , suer.sesso
        , suer.citta_res
        , suer.prov_res
        , suer.indirizzo
        , suer.citta_nas
        , suer.prov_nas
        , suer.data_nas
     from successioni_eredi suer
    where suer.successione = p_successione
        ;
CURSOR sel_imer (p_successione number, p_progr_erede number) IS
   select sudv.progressivo         dev_progressivo
        , sudv.denominatore_quota
        , sudv.numeratore_quota
        , sudv.progr_immobile
        , suim.progressivo         imm_progressivo
        , suim.indirizzo
        , lpad(to_char(suim.successione),10,'0')||lpad(to_char(suim.progressivo),5,'0')  immobile
     from successioni_devoluzioni sudv
        , successioni_immobili    suim
    where suim.successione = p_successione
      and sudv.successione = p_successione
      and sudv.progr_erede = p_progr_erede
      and sudv.progr_immobile = suim.progr_immobile
        ;
FUNCTION check_esistenza_pratica( p_tipo_tributo  varchar2
                                , p_cod_fiscale   varchar2
                                , p_anno          number
                                , p_mesi_possesso number)
return number
as
w_esiste            number := 0;
begin
-- se esiste una pratica con flag_possesso = S per l'anno
-- ma il contribuente è defunto nel corso dello stesso anno
-- allora la 'annullo' in modo che venga caricata nuova
-- coi dati reali.
-- Annullare significa mettere a zero i mesi di possesso
-- e flag_possesso = null.
--
-- (VD - 15/05/2017): aggiunte condizioni di where
--                    per join con RAPPORTI_TRIBUTO
--
    begin
        for oc in (select ogco.oggetto_pratica
                     from oggetti_pratica       ogpr
                        , pratiche_tributo      prtr
                        , oggetti_contribuente  ogco
                        , rapporti_tributo ratr
                    where ogpr.pratica          = prtr.pratica
                      and ogpr.oggetto_pratica  = ogco.oggetto_pratica
                      and prtr.tipo_tributo||'' = p_tipo_tributo
                      and ogco.cod_fiscale      = p_cod_fiscale
                      and prtr.anno             = p_anno
                      and prtr.tipo_pratica     = 'D'
                      and ratr.cod_fiscale      = p_cod_fiscale
                      and ratr.pratica          = prtr.pratica
                      and ratr.tipo_rapporto in ('C','D','E')
                      and nvl(ogco.flag_possesso,'N') = 'S'
                      and ogco.successione  is null) loop
            update oggetti_contribuente
               set flag_possesso = null
                 , mesi_possesso = 0
                 , mesi_possesso_1sem = 0
             where oggetto_pratica = oc.oggetto_pratica
            ;
        end loop;
    exception
    when others then
         null;
    end;
--
-- (VD - 15/05/2017): aggiunte condizioni di where
--                    per join con RAPPORTI_TRIBUTO
--
    select count(1)
      into w_esiste
      from oggetti_pratica       ogpr
         , pratiche_tributo      prtr
         , oggetti_contribuente  ogco
         , rapporti_tributo ratr
     where ogpr.pratica          = prtr.pratica
       and ogpr.oggetto_pratica  = ogco.oggetto_pratica
       and prtr.tipo_tributo||'' = p_tipo_tributo
     --  and ogpr.oggetto          = w_oggetto
       and ogco.cod_fiscale      = p_cod_fiscale
       and prtr.anno             = p_anno
       and prtr.tipo_pratica     = 'D'
       and ogco.mesi_possesso    = p_mesi_possesso
       and ratr.cod_fiscale      = p_cod_fiscale
       and ratr.pratica          = prtr.pratica
       and ratr.tipo_rapporto in ('C','D','E')
       and nvl(ogco.flag_possesso,'N') = 'N'
       and ogco.successione  is null
    ;
    return w_esiste;
 exception
    when no_data_found then
        w_esiste := 0;
    when others then
        w_errore := 'Errore controllo esistenza pratica '||p_cod_fiscale||' '
                    ||f_descrizione_titr(p_tipo_tributo, p_anno)
                    ||' ('||SQLERRM||')';
        raise errore;
 end;
PROCEDURE upd_sutd (
   p_successione         NUMBER,
   p_tipo_tributo        VARCHAR2,
   p_stato_successione   VARCHAR2,
   p_pratica             VARCHAR2
)
AS
BEGIN
      update successioni_tributo_defunti
         set pratica = nvl(p_pratica, pratica)
           , stato_successione = nvl(p_stato_successione, stato_successione)
       where successione = p_successione
         and tipo_tributo = p_tipo_tributo
      ;
EXCEPTION
   WHEN OTHERS
   THEN
      sql_errm := SUBSTR (SQLERRM, 1, 100);
      w_errore :=
            'Errore in modifica successioni_tributo_defunti '
         || ' tipo_tributo = '||p_tipo_tributo||' '
         || ' successione = '||p_successione||' '
         || ' pratica = '||p_pratica
         || ' '
         || ' ('
         || sql_errm
         || ')';
      RAISE errore;
END;
PROCEDURE ins_upd_sute (
   p_successione         NUMBER,
   p_tipo_tributo        VARCHAR2,
   p_progressivo         NUMBER,
   p_pratica             VARCHAR2
)
AS
w_esiste_sute number;
BEGIN
   select nvl(count(*),0)
     into w_esiste_sute
     from successioni_tributo_eredi
    where successione    = p_successione
      and tipo_tributo   = p_tipo_tributo
      and progressivo    = p_progressivo
   ;
   if w_esiste_sute = 0 then
       INSERT INTO successioni_tributo_eredi
                   (successione,
                    tipo_tributo, progressivo, pratica
                   )
            VALUES (p_successione,
                    p_tipo_tributo, p_progressivo, p_pratica);
   else
      update successioni_tributo_eredi
         set pratica = nvl(p_pratica, pratica)
       where successione  = p_successione
         and tipo_tributo = p_tipo_tributo
         and progressivo  = p_progressivo
      ;
   end if;
EXCEPTION
   WHEN OTHERS
   THEN
      sql_errm := SUBSTR (SQLERRM, 1, 100);
      w_errore :=
            'Errore in modifica successioni_tributo_eredi '
         || ' tipo_tributo = '||p_tipo_tributo||' '
         || ' successione = '||p_successione||' '
         || ' progressivo '||p_progressivo||' '
         || ' '
         || ' ('
         || sql_errm
         || ')';
      RAISE errore;
END ins_upd_sute;
begin
   BEGIN
      select lpad(to_char(pro_cliente), 3, '0') ||
             lpad(to_char(com_cliente), 3, '0')
           , flag_integrazione_gsd
        into w_cod_istat
           , w_flag_integrato
        from dati_generali;
   EXCEPTION
      WHEN no_data_found THEN
         null;
      WHEN others THEN
         w_errore := 'Errore in ricerca Codice Istat del Comune '
                     ||a_tipo_tributo
                     || ' (' ||
                     SQLERRM || ')';
         RAISE errore;
   END;
   if w_commenti > 0 then
     DBMS_OUTPUT.Put_Line('---- Inizio 2 ---- '||a_tipo_tributo);
   end if;
   FOR rec_def IN sel_def  LOOP
      if w_commenti > 0 then
         DBMS_OUTPUT.Put_Line('--- Defunto  '||rec_def.cod_fiscale);
      end if;
      w_anno_denuncia  := to_number(to_char(rec_def.data_apertura,'yyyy'));
      -- (VD - 12/05/2017): aggiunto azzeramento flag w_defunto_pre_2014_tasi
      --                    Una volta valorizzato non veniva piu' azzerato
      w_defunto_pre_2014_tasi := 0;
      if a_tipo_tributo = 'TASI' and w_anno_denuncia < 2014 then
         w_anno_denuncia := 2014;
         w_defunto_pre_2014_tasi := 1;
      end if;
      begin
         select detrazione_base
           into w_detrazione_base
           from detrazioni
          where anno = w_anno_denuncia
            and tipo_tributo = a_tipo_tributo
              ;
      exception
         when others then
            if w_anno_denuncia < 2014 and a_tipo_tributo = 'TASI' then
               null;
            else
               w_errore := 'Errore in estrazione detrazione base anno: '||to_char(w_anno_denuncia)||
                            ' cf: '||rec_def.cod_fiscale||' '
                            ||f_descrizione_titr(a_tipo_tributo, w_anno_denuncia)
                            || ' ('||SQLERRM||')';
               raise errore;
            end if;
      end;
      --------------------------------------------------------------------------
      -- Gestione Defunto ------------------------------------------------------
      --------------------------------------------------------------------------
      --Verifica contribuente
      begin
         select cont.cod_fiscale
              , cont.ni
           into w_cod_fiscale_def
              , w_ni_def
           from contribuenti  cont
          where cont.cod_fiscale   = rec_def.cod_fiscale
            ;
      exception
          when no_data_found then
             w_cod_fiscale_def := null;
          when others then
             w_errore := 'Errore in verifica Codice Fiscale (Defunto) per '||rec_def.cod_fiscale||' '
                         ||f_descrizione_titr(a_tipo_tributo, w_anno_denuncia)
                         ||' ('||SQLERRM||')';
             raise errore;
      end;
      if w_cod_fiscale_def is null then  -- Contribuente non trovato
         -- Verifica del soggetto
         begin
            select sogg.ni
              into w_ni_def
              from soggetti      sogg
             where sogg.cod_fiscale   = rec_def.cod_fiscale
               and sogg.nome          = rec_def.nome
               and sogg.cognome       = rec_def.cognome
               ;
         exception
             when no_data_found then
                w_ni_def := null;
             when others then
                w_errore := 'Errore in verifica soggetto (Defunto) per '||rec_def.cod_fiscale||' '
                            ||f_descrizione_titr(a_tipo_tributo, w_anno_denuncia)
                            ||' ('||SQLERRM||')';
                raise errore;
         end;
         if w_ni_def is null then
            -- Inserimento Nuovo Soggetto
            begin
                select com.comune
                     , com.provincia_stato
                  into w_cod_com_nas
                     , w_cod_pro_nas
                  from ad4_comuni    com
                     , ad4_provincie pro
                 where com.provincia_stato = pro.provincia
                   and com.denominazione   = rec_def.citta_nas
                   and pro.sigla           = rec_def.prov_nas
                 ;
            exception
                   when others then
                   w_cod_com_nas := null;
                   w_cod_pro_nas := null;
            end ;
            begin
                select com.comune
                     , com.provincia_stato
                  into w_cod_com_res
                     , w_cod_pro_res
                  from ad4_comuni    com
                     , ad4_provincie pro
                 where com.provincia_stato = pro.provincia
                   and com.denominazione   = rec_def.citta_res
                   and pro.sigla           = rec_def.prov_res
                 ;
            exception
                   when others then
                   w_cod_com_res := null;
                   w_cod_pro_res := null;
            end ;
            -- Tipo Residente
            if nvl(w_flag_integrato,'N') = 'S' and
               w_cod_istat = lpad(to_char(w_cod_pro_res), 3, '0') ||lpad(to_char(w_cod_com_res), 3, '0') then
               w_tipo_residente := 0;
            else
               w_tipo_residente := 1;
            end if;
            w_ni_def := null;
            SOGGETTI_NR(w_ni_def);
            begin
                insert into soggetti
                       (ni
                       ,tipo_residente
                       ,cod_fiscale
                       ,cognome_nome
                       ,data_nas
                       ,cod_com_nas
                       ,cod_pro_nas
                       ,sesso
                       ,denominazione_via
                       ,cod_com_res
                       ,cod_pro_res
                       ,tipo
                       ,fonte
                       ,utente
                       ,data_variazione)
                values (w_ni_def
                       ,w_tipo_residente
                       ,rec_def.cod_fiscale
                       ,rec_def.cognome||'/'||rec_def.nome
                       ,rec_def.data_nas
                       ,w_cod_com_nas
                       ,w_cod_pro_nas
                       ,rec_def.sesso
                       ,rec_def.indirizzo
                       ,w_cod_com_res
                       ,w_cod_pro_res
                       ,0
                       ,a_fonte
                       ,a_utente
                       ,trunc(sysdate))
                   ;
            exception
                when others then
                     w_errore := 'Errore inser Sogg '||rec_def.cod_fiscale||' '
                                 ||f_descrizione_titr(a_tipo_tributo, w_anno_denuncia)
                                 ||' ('||SQLERRM||')';
                     raise errore;
            end;
            w_num_nuovi_soggetti := w_num_nuovi_soggetti + 1;
         end if; --if w_ni is null
         w_cod_fiscale_def := rec_def.cod_fiscale;
--         if w_commenti > 0 then
--            DBMS_OUTPUT.Put_Line('CF: '||w_cod_fiscale_def||' - ni: '||to_char(w_ni_def));
--         end if;
         -- Inserimento nuovo Contribuente
         begin
            insert into contribuenti
                   (cod_fiscale,ni)
            values (w_cod_fiscale_def,w_ni_def)
                   ;
         exception
            when others then
                w_errore := 'Errore inser Contr '||w_cod_fiscale_def||' '
                            ||f_descrizione_titr(a_tipo_tributo, w_anno_denuncia)
                            ||' ('||SQLERRM||')';
                raise errore;
         end;
         w_num_nuovi_contribuenti := w_num_nuovi_contribuenti + 1;
      end if; -- if w_cod_fiscale is null
      -- Mesi di Possesso Denuncia Defunto
      w_mesi_possesso_def := to_number(to_char(rec_def.data_apertura,'mm'));
      if to_number(to_char(rec_def.data_apertura,'dd')) <= 15 then
         w_mesi_possesso_def := w_mesi_possesso_def - 1;
      end if;
      if rec_def.data_apertura >
          to_date('3006'||to_char(rec_def.data_apertura,'yyyy'),'ddmmyyyy') then
         w_mesi_possesso_1sem_def := 6;
      else
         w_mesi_possesso_1sem_def := to_number(to_char(rec_def.data_apertura,'mm'));
         if to_number(to_char(rec_def.data_apertura,'dd')) <= 15 then
            w_mesi_possesso_1sem_def := w_mesi_possesso_1sem_def - 1;
         end if;
      end if;
      -- Controllo esistenza Pratica
      if nvl(a_ctr_denuncia,'N') = 'S' then
         w_pratica_esistente := check_esistenza_pratica( a_tipo_tributo
                                                       , w_cod_fiscale_def
                                                       , w_anno_denuncia
                                                       , w_mesi_possesso_def);
      else
         w_pratica_esistente := 0;
      end if;
--      if w_commenti > 0 then
--         dbms_output.put_line('Pratica esistente: '||w_pratica_esistente);
--      end if;
      if w_pratica_esistente = 0 then
      -- se il defunto è pre 2014 e il titr è TASI, per il defunto non faccio nulla
      -- mentre inserisco la pratica TASI  per gli eredi
         if w_defunto_pre_2014_tasi = 0 then
             -- inserimento pratica defunto
             w_pratica := null;
             PRATICHE_TRIBUTO_NR(w_pratica);
             w_pratica_defunto := w_pratica;
             w_ind := w_ind + 1;
             t_pratica(w_ind) := w_pratica;
--             if w_commenti > 0 then
--                dbms_output.put_line('Inserimento pratica: '||w_pratica);
--             end if;
             BEGIN
               insert into pratiche_tributo
                      (pratica
                      ,cod_fiscale
                      ,tipo_tributo
                      ,anno
                      ,tipo_pratica
                      ,tipo_evento
                      ,data
                      ,utente
                      ,data_variazione
                      ,note)
               values (w_pratica
                      ,w_cod_fiscale_def
                      ,a_tipo_tributo
                      ,w_anno_denuncia
                      ,'D'
                      ,'I'
                      ,rec_def.data_apertura
                      ,a_utente
                      ,trunc(sysdate)
                      ,'Successioni Defunto ('||to_char(sysdate,'dd/mm/yyyy')||')')
                       ;
             EXCEPTION
                 WHEN others THEN
                    sql_errm  := substr(SQLERRM,1,100);
                    w_errore := 'Errore inser nuova pratica '
                                ||f_descrizione_titr(a_tipo_tributo, w_anno_denuncia)
                                ||' ('||sql_errm||')';
                    raise errore;
             END;
             w_num_nuove_pratiche := w_num_nuove_pratiche + 1;
             w_num_ordine := 1;
             BEGIN
                insert into rapporti_tributo
                       (pratica,cod_fiscale,tipo_rapporto)
                values (w_pratica,w_cod_fiscale_def,'D')
                ;
             EXCEPTION
                WHEN others THEN
                    sql_errm  := substr(SQLERRM,1,100);
                    w_errore := 'Errore inser ratr '
                                ||f_descrizione_titr(a_tipo_tributo, w_anno_denuncia)
                                ||' ('||sql_errm||')';
             END;
             IF a_tipo_tributo = 'ICI' THEN
                 BEGIN
                    insert into denunce_ici
                           (pratica,denuncia,fonte,utente,data_variazione)
                    values (w_pratica,w_pratica,a_fonte,a_utente,trunc(sysdate))
                           ;
                 EXCEPTION
                    WHEN others THEN
                       sql_errm  := substr(SQLERRM,1,100);
                       w_errore := 'Errore inser denunce_ici'||
                                   ' ('||sql_errm||')';
                 END;
             ELSE
                 BEGIN
                    insert into denunce_tasi
                           (pratica,denuncia,fonte,utente,data_variazione)
                    values (w_pratica,w_pratica,a_fonte,a_utente,trunc(sysdate))
                           ;
                 EXCEPTION
                    WHEN others THEN
                       sql_errm  := substr(SQLERRM,1,100);
                       w_errore := 'Errore inser denunce_tasi'||
                                   ' ('||sql_errm||')';
                 END;
             END IF;
             -- Aggiornamento SUDE (Pratica)
             upd_sutd(rec_def.successione, a_tipo_tributo, null, w_pratica);
             --Recupero sigla comune Defunto
             begin
                 select comu.sigla_cfis
                   into w_comune_def
                   from ad4_comuni    comu
                      , contribuenti  cont
                      , soggetti      sogg
                  where cont.ni = sogg.ni
                    and cont.cod_fiscale = w_cod_fiscale_def
                    and sogg.cod_com_res = comu.comune
                    and sogg.cod_pro_res = comu.provincia_stato
                  ;
             EXCEPTION
                WHEN others THEN
                   w_comune_def := '';
             end;
         else
            w_pratica_defunto := to_number(null);
         end if;
         --
         -- (VD - 15/05/2017): il trattamento degli immobili viene fatto
         --                    comunque per memorizzare i dati negli array
         --                    utili all'inserimento delle pratiche degli
         --                    eredi
         --
         --------------------------------------------------------------------------
         -- Inserimento Immobili --------------------------------------------------
         --------------------------------------------------------------------------
         FOR rec_immo IN sel_immo (rec_def.successione) LOOP
            if w_commenti > 0 then
               DBMS_OUTPUT.Put_Line('Immobile: '||rec_def.successione||'-'||rec_immo.progressivo);
            end if;
            IF rec_immo.catasto = 'U' THEN -- inizio trattamento fabbricati
               w_tipo_oggetto := 3;
               w_categoria := rec_immo.natura;
               --Sistemazione Categoria
               if length(w_categoria) = 2 then
                  begin
                     select decode(w_categoria
                                  ,'A1','A01'
                                  ,'A2','A02'
                                  ,'A3','A03'
                                  ,'A4','A04'
                                  ,'A5','A05'
                                  ,'A6','A06'
                                  ,'A7','A07'
                                  ,'A8','A08'
                                  ,'A9','A09'
                                  ,'B1','B01'
                                  ,'B2','B02'
                                  ,'B3','B03'
                                  ,'B4','B04'
                                  ,'B5','B05'
                                  ,'B6','A06'
                                  ,'B7','B07'
                                  ,'B8','B08'
                                  ,'C1','C01'
                                  ,'C2','C02'
                                  ,'C3','C03'
                                  ,'C4','C04'
                                  ,'C5','C05'
                                  ,'C6','C06'
                                  ,'C7','C07'
                                  ,'D1','D01'
                                  ,'D2','D02'
                                  ,'D3','D03'
                                  ,'D4','D04'
                                  ,'D5','D05'
                                  ,'D6','D06'
                                  ,'D7','D07'
                                  ,'D8','D08'
                                  ,'D9','D09'
                                  ,'E1','E01'
                                  ,'E2','E02'
                                  ,'E3','E03'
                                  ,'E4','E04'
                                  ,'E5','E05'
                                  ,'E6','E06'
                                  ,'E7','E07'
                                  ,'E8','E08'
                                  ,'E9','E09'
                                  ,'F1','F01'
                                  ,'F2','F02'
                                  ,'F3','F03'
                                  ,'F4','F04'
                                  ,'F5','F05'
                                  ,w_categoria
                                  )
                       into w_categoria
                       from dual
                       ;
                  EXCEPTION
                     WHEN others THEN
                        sql_errm  := substr(SQLERRM,1,100);
                        w_errore := 'Errore in sistemazione categoria '
                                    ||f_descrizione_titr(a_tipo_tributo, w_anno_denuncia)
                                    ||' ('||sql_errm||')';
                        raise errore;
                  end;
               end if;
            ELSIF rec_immo.catasto = 'T' THEN -- inizio trattamento terreni
               w_tipo_oggetto := 1;
               w_categoria    := 'T';
            else
               w_errore := 'Tipo oggetto non definito: '||rec_immo.catasto||' '
                           ||f_descrizione_titr(a_tipo_tributo, w_anno_denuncia);
               raise errore;
            end if;
            if nvl(a_sezione_unica,'N') = 'S' then
               w_sezione := '';
            else
               w_sezione := rec_immo.sezione;
            end if;
            w_oggetto := 0;
            IF rec_immo.foglio
             ||rec_immo.numero
             ||rec_immo.subalterno is not null THEN
               w_estremi_catasto := lpad(ltrim(nvl(w_sezione,' '),'0'),3,' ')
                             ||
                             lpad(ltrim(nvl(rec_immo.foglio,' '),'0'),5,' ')
                             ||
                             lpad(ltrim(nvl(rec_immo.numero,' '),'0'),5,' ')
                             ||
                             lpad(ltrim(nvl(to_char(rec_immo.subalterno),' '),'0'),4,' ')
                             ||
                             lpad(' ',3);
               BEGIN
                  select max(oggetto)
                    into w_oggetto
                    from oggetti ogge
                   where ( (    ogge.tipo_oggetto + 0         in (3,4,55)
                            and w_tipo_oggetto = 3
                           )
                        or (    ogge.tipo_oggetto + 0         in (1,2)
                            and w_tipo_oggetto = 1
                           )
                         )
                     and ogge.estremi_catasto          = w_estremi_catasto
                     and nvl(substr(ogge.categoria_catasto,1,1),'   ')    = nvl(substr(w_categoria,1,1),'   ')
                       ;
               EXCEPTION
                  WHEN others THEN
                     sql_errm  := substr(SQLERRM,1,100);
                     w_errore := 'Errore in controllo esistenza ogge dati catastali '
                                 ||f_descrizione_titr(a_tipo_tributo, w_anno_denuncia)
                                 ||' ('||sql_errm||')';
                     raise errore;
               END;
            else
               BEGIN
                  select max(oggetto)
                    into w_oggetto
                    from oggetti ogge
                   where ( (    ogge.tipo_oggetto + 0         in (3,4,55)
                            and w_tipo_oggetto = 3
                           )
                        or (    ogge.tipo_oggetto + 0         in (1,2)
                            and w_tipo_oggetto = 1
                           )
                         )
                     and nvl(ogge.sezione,'   ')  = rpad(ltrim(nvl(w_sezione,' '),'0'),3,' ')
                     and ogge.protocollo_catasto  = rec_immo.protocollo_catasto
                     and ogge.anno_catasto        = rec_immo.anno_catasto
                     and nvl(substr(ogge.categoria_catasto,1,1),'   ')    = nvl(substr(w_categoria,1,1),'   ')
                       ;
               EXCEPTION
                  WHEN others THEN
                     sql_errm  := substr(SQLERRM,1,100);
                     w_errore := 'Errore controllo esistenza ogge denuncia accatastamento '
                                 ||f_descrizione_titr(a_tipo_tributo, w_anno_denuncia)
                                 ||' ('||sql_errm||')';
                     raise errore;
               END;
            END IF;
            -- Recupero valore dell' Oggetto
            if nvl(w_oggetto,0) > 0 then -- Oggetto trovato
               -- Ricavo il valore da un riog presente alla data di successione sull'oggetto
               begin
                  select riog.rendita
                    into w_rendita
                    from riferimenti_oggetto  riog
                   where riog.oggetto = w_oggetto
                     and rec_def.data_apertura between inizio_validita
                                                   and fine_validita
                       ;
               EXCEPTION
                  WHEN others THEN
                     w_rendita := -1;
               end;
               if w_rendita > 0 then
                  w_valore_ogpr := F_VALORE_DA_RENDITA
                                   ( w_rendita
                                   , w_tipo_oggetto
                                   , w_anno_denuncia
                                   , w_categoria
                                   , '');
               else
               -- Se non si trova il riog si utilizza il valore dell'oggetto della denuncia di iscrizione del defunto
                  begin
                    select ogpr.valore
                         , prtr.anno
                         , prtr.tipo_pratica
                         , ogpr.flag_valore_rivalutato
                      into w_valore_ogpr_den_def_prec
                         , w_anno_den_def_prec
                         , w_tipo_pratica_den_def_prec
                         , w_flag_valore_riv_den_def_prec
                      from PRATICHE_TRIBUTO     PRTR
                         , OGGETTI_PRATICA      OGPR
                         , OGGETTI_CONTRIBUENTE OGCO
                     where ogco.oggetto_pratica  = ogpr.oggetto_pratica
                       and ogpr.pratica          = prtr.pratica
                       and prtr.tipo_tributo||'' = a_tipo_tributo
                       and ogco.cod_fiscale      = w_cod_fiscale_def
                       and ogpr.oggetto          = w_oggetto
                       and ogco.flag_possesso    = 'S'
                       and (ogco.anno||ogco.tipo_rapporto||'S') =
                           ( select max (ogco_sub.anno||ogco_sub.tipo_rapporto||ogco_sub.flag_possesso)
                               from PRATICHE_TRIBUTO PRTR_SUB,
                                    OGGETTI_PRATICA OGPR_SUB,
                                    OGGETTI_CONTRIBUENTE OGCO_SUB
                              where prtr_sub.tipo_tributo||''  = prtr.tipo_tributo
                                and ( (     prtr_sub.tipo_pratica||''   = 'D'
                                        and prtr_sub.data_notifica is null
                                      )
                                     or
                                      (     prtr_sub.tipo_pratica||'' = 'A'
                                        and prtr_sub.data_notifica is not null
                                        and nvl(prtr_sub.stato_accertamento,'D') = 'D'
                                        and nvl(prtr_sub.flag_denuncia,' ') = 'S'
                                        and prtr_sub.anno <= w_anno_denuncia
                                      )
                                    )
                                and prtr_sub.pratica         = ogpr_sub.pratica
                                and ogco_sub.anno           <= w_anno_denuncia
                                and ogco_sub.cod_fiscale     = ogco.cod_fiscale
                                and ogco_sub.oggetto_pratica = ogpr_sub.oggetto_pratica
                                and ogpr_sub.oggetto         = ogpr.oggetto
                                and ogco_sub.tipo_rapporto in ('C', 'D','E')
                                --
                                -- (VD) 23/03/2015 - Modificata in analogia al CALCOLO_ICI/TASI
                                --
                                --  and nvl(ogco_sub.flag_possesso, 'N') = decode(a_tipo_tributo, 'TASI', 'S', nvl(ogco_sub.flag_possesso, 'N'))
                           )
                      union
                    select ogpr.valore
                         , prtr.anno
                         , prtr.tipo_pratica
                         , ogpr.flag_valore_rivalutato
                      from PRATICHE_TRIBUTO     PRTR
                         , OGGETTI_PRATICA      OGPR
                         , OGGETTI_CONTRIBUENTE OGCO
                     where ogco.oggetto_pratica    = ogpr.oggetto_pratica
                       and ogpr.pratica            = prtr.pratica
                       and prtr.tipo_tributo||''   = a_tipo_tributo
                       and prtr.tipo_pratica||''  in ('V','D')
                       and ogco.flag_possesso     is null
                       and ogco.cod_fiscale        = w_cod_fiscale_def
                       and ogpr.oggetto            = w_oggetto
                       and ogco.anno               = w_anno_denuncia
                         ;
                  exception
                     when others then
                         w_valore_ogpr_den_def_prec := to_number(null);
                         w_anno_den_def_prec        := to_number(null);
                         w_tipo_pratica_den_def_prec     := to_number(null);
                         w_flag_valore_riv_den_def_prec  := to_number(null);
                  end;
                  w_valore_ogpr := F_VALORE( w_valore_ogpr_den_def_prec
                                           , w_tipo_oggetto
                                           , w_anno_den_def_prec
                                           , w_anno_denuncia
                                           , w_categoria
                                           , w_tipo_pratica_den_def_prec
                                           , w_flag_valore_riv_den_def_prec
                                           );
               end if;
            else
               w_valore_ogpr := to_number(null);
            end if;
            --
            -- (VD - 26/11/2018): se il valore determinato e' nullo, si
            --                    memorizza il valore presente nel file
            --
            if w_valore_ogpr is null then
               w_valore_ogpr := rec_immo.valore;
            end if;
            --
            IF nvl(w_oggetto,0) = 0 THEN  -- Oggetto non trovato
               BEGIN
                  select cod_via
                    into w_cod_via
                    from denominazioni_via devi
                   where rec_immo.indirizzo like chr(37)||devi.descrizione||chr(37)
                     and devi.descrizione is not null
                     and not exists (select 'x'
                                       from denominazioni_via devi1
                                      where rec_immo.indirizzo
                                       like chr(37)||devi1.descrizione||chr(37)
                                        and devi1.descrizione is not null
                                        and devi1.cod_via != devi.cod_via)
                     and rownum = 1
                       ;
               EXCEPTION
                  WHEN no_data_found then
                   w_cod_via := 0;
               WHEN others THEN
                    sql_errm  := substr(SQLERRM,1,100);
                    w_errore := 'Errore controllo esistenza indirizzo ogge'||
                                'indir: '||rec_immo.indirizzo||' '
                                ||f_descrizione_titr(a_tipo_tributo, w_anno_denuncia)
                                ||' ('||sql_errm||')';
                    raise errore;
               END;
               IF w_categoria is not null THEN
                  BEGIN
                    select count(1)
                      into w_controllo
                      from categorie_catasto
                     where categoria_catasto = w_categoria
                         ;
                  EXCEPTION
                     WHEN others THEN
                        sql_errm  := substr(SQLERRM,1,100);
                        w_errore := 'Errore in ricerca Categorie Catasto '
                                    ||f_descrizione_titr(a_tipo_tributo, w_anno_denuncia)
                                    ||' ('||sql_errm||')';
                        raise errore;
                  END;
                  if nvl(w_controllo,0) = 0 then
                        BEGIN
                           insert into categorie_catasto
                                  (categoria_catasto,descrizione)
                           values (w_categoria,'DA CARICAMENTO DATI SUCCESSIONI')
                               ;
                        EXCEPTION
                           WHEN others THEN
                              sql_errm  := substr(SQLERRM,1,100);
                              w_errore := 'Errore in inserimento Categorie Catasto '
                                          ||f_descrizione_titr(a_tipo_tributo, w_anno_denuncia)
                                          ||' ('||sql_errm||')';
                              raise errore;
                        END;
                  end if;
               END IF; -- fine controllo categoria not null
               w_oggetto := null;
               OGGETTI_NR(w_oggetto);
               BEGIN
                  insert into oggetti
                         (oggetto
                         ,tipo_oggetto
                         ,indirizzo_localita
                         ,cod_via
                         ,num_civ
                         ,suffisso
                         ,sezione
                         ,foglio
                         ,numero
                         ,subalterno
                         ,categoria_catasto
                         ,protocollo_catasto
                         ,anno_catasto
                         ,consistenza
                         ,ettari
                         ,vani
                         ,fonte
                         ,utente
                         ,data_variazione)
                  values (w_oggetto
                         ,w_tipo_oggetto
                         ,decode(w_cod_via,0,substr(rec_immo.indirizzo,1,36),'')
                         ,decode(w_cod_via,0,null,w_cod_via)
                         ,''
                         ,''
                         ,w_sezione
                         ,rec_immo.foglio
                         ,rec_immo.numero
                         ,rec_immo.subalterno
                         ,w_categoria
                         ,rec_immo.protocollo_catasto
                         ,rec_immo.anno_catasto
                         ,rec_immo.superficie_MQ
                         ,rec_immo.superficie_ettari
                         ,rec_immo.vani
                         ,a_fonte
                         ,a_utente
                         ,trunc(sysdate))
                         ;
               EXCEPTION
                   WHEN others THEN
                      sql_errm  := substr(SQLERRM,1,100);
                      w_errore := 'Errore inser oggetto '
                                  ||f_descrizione_titr(a_tipo_tributo, w_anno_denuncia)
                                  ||' ('||sql_errm||')';
                      raise errore;
               END;
               w_num_nuovi_oggetti := w_num_nuovi_oggetti + 1;
            END IF; -- fine controllo se immobile gia' presente
            -- Inserimento dell'oggetto in SUIM
            begin
               update successioni_immobili
                  set oggetto = w_oggetto
                where successione = rec_def.successione
                  and progressivo = rec_immo.progressivo
                  ;
            EXCEPTION
                WHEN others THEN
                   sql_errm  := substr(SQLERRM,1,100);
                   w_errore := 'Errore upd suim (oggetto) '
                               ||f_descrizione_titr(a_tipo_tributo, w_anno_denuncia)
                               ||' ('||sql_errm||')';
                   raise errore;
            end;
            -- Inserimento riferimento Immobile,
            t_oggetto(lpad(to_char(rec_def.successione),10,'0')||lpad(to_char(rec_immo.progressivo),5,'0'))       := w_oggetto;
            t_tipo_oggetto(lpad(to_char(rec_def.successione),10,'0')||lpad(to_char(rec_immo.progressivo),5,'0'))  := w_tipo_oggetto;
            t_categoria(lpad(to_char(rec_def.successione),10,'0')||lpad(to_char(rec_immo.progressivo),5,'0'))     := w_categoria;
            t_valore_ogpr(lpad(to_char(rec_def.successione),10,'0')||lpad(to_char(rec_immo.progressivo),5,'0'))   := w_valore_ogpr;
            --
            -- (VD - 15/05/2017): spostata valorizzazione percentuale di possesso
            --                    per gestire anche gli immobili per cui non si
            --                    inserisce la pratica sul defunto (TASI ante 2014)
            --
            w_perc_possesso_def := rec_immo.numeratore_quota_def / rec_immo.denominatore_quota_def * 100;
            t_perc_pos_def(lpad(to_char(rec_def.successione),10,'0')||lpad(to_char(rec_immo.progressivo),5,'0'))  := w_perc_possesso_def;
            --
            -- (VD - 15/05/2017): l'inserimento di oggetti_pratica e
            --                    oggetti_contribuente si fa solo se non
            --                    si tratta di TASI ante 2014
            --
            if w_defunto_pre_2014_tasi = 0 then
                -- Inserimento oggetto_pratica Defunto
                w_oggetto_pratica := null;
                OGGETTI_PRATICA_NR(w_oggetto_pratica);
                BEGIN
                   insert into oggetti_pratica
                         (oggetto_pratica
                         ,oggetto
                         ,tipo_oggetto
                         ,pratica
                         ,anno
                         ,num_ordine
                         ,categoria_catasto
                         ,valore
                         ,flag_valore_rivalutato
                         ,fonte
                         ,utente
                         ,data_variazione)
                  values (w_oggetto_pratica
                         ,w_oggetto
                         ,w_tipo_oggetto
                         ,w_pratica
                         ,w_anno_denuncia
                         ,to_char(w_num_ordine)
                         ,w_categoria
                         ,w_valore_ogpr
                         ,decode(sign(1996 - w_anno_denuncia),
                                     -1,'S','')
                         ,a_fonte
                         ,a_utente
                         ,trunc(sysdate)
                         )
                          ;
                EXCEPTION
                   WHEN others THEN
                      sql_errm  := substr(SQLERRM,1,100);
                      w_errore := 'Errore inser ogpr '
                                  ||f_descrizione_titr(a_tipo_tributo, w_anno_denuncia)
                                  ||' ('||sql_errm||')';
                END;
                w_num_nuovi_ogpr := w_num_nuovi_ogpr + 1;
                w_num_ordine := w_num_ordine + 1;
                --
                -- (VD - 15/05/2017): spostata valorizzazione perc. possesso
                --                    fuori dal trattamento di oggetti_pratica
                --
                --w_perc_possesso_def := rec_immo.numeratore_quota_def / rec_immo.denominatore_quota_def * 100;
                --t_perc_pos_def(lpad(to_char(rec_def.successione),10,'0')||lpad(to_char(rec_immo.progressivo),5,'0'))     := w_perc_possesso_def;
                -- Recupero Detrazione
                if rec_def.indirizzo = rec_immo.indirizzo and
                   rec_def.comune    = w_comune_def then
                    if substr(w_categoria,1,1) = 'A' and nvl(w_perc_possesso_def,0) = 100 then
                       w_detrazione         := round(w_detrazione_base / 12 * w_mesi_possesso_def,2);
                    else
                       w_detrazione         := null;
                    end if;
                else
                    w_detrazione         := null;
                end if;
                -- inserimento oggetto_contribuente defunto
                BEGIN
                   insert into oggetti_contribuente
                          (cod_fiscale
                          ,oggetto_pratica
                          ,anno
                          ,tipo_rapporto
                          ,perc_possesso
                          ,mesi_possesso
                          ,mesi_possesso_1sem
                          ,flag_possesso
                          ,flag_ab_principale
                          ,detrazione
                          ,successione
                          ,utente
                          ,data_variazione
                          ,perc_detrazione)
                   values (w_cod_fiscale_def
                          ,w_oggetto_pratica
                          ,w_anno_denuncia
                          ,'D'
                          ,w_perc_possesso_def
                          ,w_mesi_possesso_def
                          ,w_mesi_possesso_1sem_def
                          ,''
                          ,''
                          ,w_detrazione
                          ,rec_def.successione
                          ,a_utente
                          ,trunc(sysdate)
                          ,decode(w_detrazione,null,null,100))
                     ;
                EXCEPTION
                   WHEN others THEN
                      sql_errm  := substr(SQLERRM,1,100);
                      w_errore := 'Errore in inserim. ogco '
                                  ||f_descrizione_titr(a_tipo_tributo, w_anno_denuncia)
                                  ||' ('||sql_errm||')';
                END;
            end if;
         end loop; -- rec_immo
         -- Mesi di Possesso Denunce Eredi
         if w_defunto_pre_2014_TASI = 0 then
             w_mesi_possesso_erede := 13 - to_number(to_char(rec_def.data_apertura,'mm'));
             if to_number(to_char(rec_def.data_apertura,'dd')) > 15 then
                w_mesi_possesso_erede := w_mesi_possesso_erede - 1;
             end if;
             if rec_def.data_apertura >
                 to_date('3006'||to_char(rec_def.data_apertura,'yyyy'),'ddmmyyyy') then
                w_mesi_possesso_1sem_erede := 0;
             else
                w_mesi_possesso_1sem_erede := 7 - to_number(to_char(rec_def.data_apertura,'mm'));
                if to_number(to_char(rec_def.data_apertura,'dd')) > 15 then
                   w_mesi_possesso_1sem_erede := w_mesi_possesso_1sem_erede - 1;
                end if;
             end if;
         else
            w_mesi_possesso_erede := 12;
            w_mesi_possesso_1sem_erede := 6;
         end if;
         -- estrazione max numero_ordine erede
         begin
            select nvl(max(nvl(numero_ordine,0)),0)
              into w_max_numero_ordine_erede
              from eredi_soggetto
             where ni = w_ni_def
                 ;
         exception
            when others then
               w_max_numero_ordine_erede := 0;
         end;
         --------------------------------------------------------------------------
         -- Gestione Eredi --------------------------------------------------------
         --------------------------------------------------------------------------
         FOR rec_eredi IN sel_eredi (rec_def.successione) LOOP
             if w_commenti > 0 then
                DBMS_OUTPUT.Put_Line('Erede: '||rec_def.successione||'-'||rec_eredi.cod_fiscale);
             end if;
            w_ni_erede            := null;
            w_cod_fiscale_erede   := null;
            --Verifica contribunete
            begin
               select cont.cod_fiscale
                    , cont.ni
                 into w_cod_fiscale_erede
                    , w_ni_erede
                 from contribuenti  cont
                where cont.cod_fiscale   = rec_eredi.cod_fiscale
                  ;
            exception
                when no_data_found then
                   w_cod_fiscale_erede := null;
                when others then
                   w_errore := 'Errore in verifica Codice Fiscale (Erede) per '||rec_eredi.cod_fiscale||' '
                               ||f_descrizione_titr(a_tipo_tributo, w_anno_denuncia)
                               ||' ('||SQLERRM||')';
                   raise errore;
            end;
            if w_cod_fiscale_erede is null then  -- Contribuente non trovato
               -- Verifica del soggetto
               begin
                  select sogg.ni
                    into w_ni_erede
                    from soggetti      sogg
                   where nvl(sogg.cod_fiscale,sogg.partita_iva) = rec_eredi.cod_fiscale
                     and sogg.cognome_nome       = nvl(rec_eredi.denominazione, (rec_eredi.cognome||'/'||rec_eredi.nome))
                     ;
               exception
                   when no_data_found then
                      w_ni_erede := null;
                   when others then
                      w_errore := 'Errore in verifica soggetto (Erede) per '||rec_eredi.cod_fiscale||' '
                                  ||f_descrizione_titr(a_tipo_tributo, w_anno_denuncia)
                                  ||' ('||SQLERRM||')';
                      raise errore;
               end;
               if w_ni_erede is null then
                  -- Inserimento Nuovo Soggetto
                  begin
                      select com.comune
                           , com.provincia_stato
                        into w_cod_com_nas
                           , w_cod_pro_nas
                        from ad4_comuni    com
                           , ad4_provincie pro
                       where com.provincia_stato = pro.provincia
                         and com.denominazione   = rec_eredi.citta_nas
                         and pro.sigla           = rec_eredi.prov_nas
                       ;
                  exception
                         when others then
                         w_cod_com_nas := null;
                         w_cod_pro_nas := null;
                  end ;
                  begin
                      select com.comune
                           , com.provincia_stato
                        into w_cod_com_res
                           , w_cod_pro_res
                        from ad4_comuni    com
                           , ad4_provincie pro
                       where com.provincia_stato = pro.provincia
                         and com.denominazione   = rec_eredi.citta_res
                         and pro.sigla           = rec_eredi.prov_res
                       ;
                  exception
                         when others then
                         w_cod_com_res := null;
                         w_cod_pro_res := null;
                  end ;
                  -- Tipo Residente
                  if nvl(w_flag_integrato,'N') = 'S' and
                     w_cod_istat = lpad(to_char(w_cod_pro_res), 3, '0') ||lpad(to_char(w_cod_com_res), 3, '0') then
                     w_tipo_residente := 0;
                  else
                     w_tipo_residente := 1;
                  end if;
                  w_ni_erede := null;
                  SOGGETTI_NR(w_ni_erede);
                  begin
                      insert into soggetti
                             (ni
                             ,tipo_residente
                             ,cod_fiscale
                             ,cognome_nome
                             ,data_nas
                             ,cod_com_nas
                             ,cod_pro_nas
                             ,sesso
                             ,denominazione_via
                             ,cod_com_res
                             ,cod_pro_res
                             ,tipo
                             ,fonte
                             ,utente
                             ,data_variazione)
                      values (w_ni_erede
                             ,w_tipo_residente
                             ,rec_eredi.cod_fiscale
                             ,nvl(rec_eredi.denominazione,rec_eredi.cognome||'/'||rec_eredi.nome)
                             ,rec_eredi.data_nas
                             ,w_cod_com_nas
                             ,w_cod_pro_nas
                             ,rec_eredi.sesso
                             ,rec_eredi.indirizzo
                             ,w_cod_com_res
                             ,w_cod_pro_res
                             ,decode(rec_eredi.sesso
                                    ,'M',0
                                    ,'F',0
                                    ,1)
                             ,a_fonte
                             ,a_utente
                             ,trunc(sysdate))
                         ;
                  exception
                      when others then
                        --   w_errore := 'Errore inser Sogg '||rec_eredi.cod_fiscale||' ('||SQLERRM||')';
                           w_errore := SQLERRM;
                           raise errore;
                  end;
                  w_num_nuovi_soggetti := w_num_nuovi_soggetti + 1;
               end if; --if w_ni is null
               w_cod_fiscale_erede := rec_eredi.cod_fiscale;
               if w_commenti > 0 then
                  DBMS_OUTPUT.Put_Line('CF: '||w_cod_fiscale_erede||' - ni: '||to_char(w_ni_erede));
               end if;
               -- Inserimento nuovo Contribuente
               begin
                  insert into contribuenti
                         (cod_fiscale,ni)
                  values (w_cod_fiscale_erede,w_ni_erede)
                         ;
               exception
                  when others then
                      w_errore := 'Errore inser Contr '||w_cod_fiscale_erede||' '
                      ||f_descrizione_titr(a_tipo_tributo, w_anno_denuncia)
                      ||' ('||SQLERRM||')';
                      raise errore;
               end;
               w_num_nuovi_contribuenti := w_num_nuovi_contribuenti + 1;
            end if; -- if w_cod_fiscale is null
            -- Inserimento pratica Erede
                w_pratica := null;
                PRATICHE_TRIBUTO_NR(w_pratica);
                w_ind := w_ind + 1;
                t_pratica(w_ind) := w_pratica;
                BEGIN
                  insert into pratiche_tributo
                         (pratica
                         ,cod_fiscale
                         ,tipo_tributo
                         ,anno
                         ,tipo_pratica
                         ,tipo_evento
                         ,data
                         ,utente
                         ,data_variazione
                         ,note)
                  values (w_pratica
                         ,w_cod_fiscale_erede
                         ,a_tipo_tributo
                         ,w_anno_denuncia
                         ,'D'
                         ,'I'
                         ,rec_def.data_apertura
                         ,a_utente
                         ,trunc(sysdate)
                         ,'Successioni Erede ('||to_char(sysdate,'dd/mm/yyyy')||')')
                          ;
                EXCEPTION
                    WHEN others THEN
                       sql_errm  := substr(SQLERRM,1,100);
                       w_errore := 'Errore in inserimento nuova pratica '
                                   ||f_descrizione_titr(a_tipo_tributo, w_anno_denuncia)
                                   ||' ('||sql_errm||')';
                       raise errore;
                END;
                w_num_ordine := 1;
                BEGIN
                   insert into rapporti_tributo
                          (pratica,cod_fiscale,tipo_rapporto)
                   values (w_pratica,w_cod_fiscale_erede,'D')
                    ;
                EXCEPTION
                   WHEN others THEN
                       sql_errm  := substr(SQLERRM,1,100);
                       w_errore := 'Errore inser ratr '
                                   ||f_descrizione_titr(a_tipo_tributo, w_anno_denuncia)
                                   ||' ('||sql_errm||')';
                END;
                IF a_tipo_tributo = 'ICI' THEN
                    BEGIN
                       insert into denunce_ici
                              (pratica,denuncia,fonte,utente,data_variazione)
                       values (w_pratica,w_pratica,a_fonte,a_utente,trunc(sysdate))
                              ;
                    EXCEPTION
                       WHEN others THEN
                          sql_errm  := substr(SQLERRM,1,100);
                          w_errore := 'Errore inser denunce_ici '||
                                      ' ('||sql_errm||')';
                    END;
                ELSE
                    BEGIN
                       insert into denunce_tasi
                              (pratica,denuncia,fonte,utente,data_variazione)
                       values (w_pratica,w_pratica,a_fonte,a_utente,trunc(sysdate))
                              ;
                    EXCEPTION
                       WHEN others THEN
                          sql_errm  := substr(SQLERRM,1,100);
                          w_errore := 'Errore inser denunce_tasi '||
                                      ' ('||sql_errm||')';
                    END;
                END IF;
                --Rrecupero sigla comune Erede
                begin
                    select comu.sigla_cfis
                      into w_comune_erede
                      from ad4_comuni    comu
                         , contribuenti  cont
                         , soggetti      sogg
                     where cont.ni = sogg.ni
                       and cont.cod_fiscale = w_cod_fiscale_erede
                       and sogg.cod_com_res = comu.comune
                       and sogg.cod_pro_res = comu.provincia_stato
                     ;
                EXCEPTION
                   WHEN others THEN
                      w_comune_def := '';
                end;
                -------------------------------------------------------------------
                -- Gestione Immobili Eredi ----------------------------------------
                -------------------------------------------------------------------
                FOR rec_imer IN sel_imer (rec_def.successione, rec_eredi.progr_erede) LOOP
                   if w_commenti > 0 then
                      DBMS_OUTPUT.Put_Line('Imm.Erede: '||rec_def.successione||'-'||rec_imer.imm_progressivo);
                   end if;
                   w_oggetto      := t_oggetto(rec_imer.immobile);
                   w_tipo_oggetto := t_tipo_oggetto(rec_imer.immobile);
                   w_categoria    := t_categoria(rec_imer.immobile);
                   w_valore_ogpr  := t_valore_ogpr(rec_imer.immobile);
                   if w_commenti > 0 then
                      DBMS_OUTPUT.Put_Line('Fine attribuzione variabili da array');
                   end if;
                   -- Verifico se l'oggetto della denuncia è già presente per il contribunete
                   -- in caso positivo la percentuale di possesso va calcolata in base a quella
                   -- dell'oggetto posseduto perchè quella indicata nel tracciato è la variazione
                   -- di percentuale di possesso rispetto a quella esistente.
                   begin
                     SELECT ogco.perc_possesso
                          , ogpr.tipo_oggetto
                          , ogpr.categoria_catasto
                          , ogpr.classe_catasto
                          , ogpr.valore
                          , ogpr.titolo
                          , ogco.flag_esclusione
                          , ogco.flag_ab_principale
                          , prtr.anno
                          , prtr.tipo_pratica
                          , ogpr.flag_valore_rivalutato
                          , ogco.flag_possesso
                       into w_perc_possesso_prec
                          , w_tipo_oggetto_prec
                          , w_categoria_prec
                          , w_classe_prec
                          , w_valore_prec
                          , w_titolo_prec
                          , w_flag_esclusione_prec
                          , w_flag_ab_princ_prec
                          , w_anno_den_ere_prec
                          , w_tipo_pratica_prec
                          , w_flag_valore_riv_prec
                          , w_flag_possesso_prec
                       FROM PRATICHE_TRIBUTO     PRTR
                          , OGGETTI_PRATICA      OGPR
                          , OGGETTI_CONTRIBUENTE OGCO
                      WHERE OGCO.OGGETTO_PRATICA = OGPR.OGGETTO_PRATICA
                        and OGPR.PRATICA         = PRTR.PRATICA
                        and OGCO.COD_FISCALE     = w_cod_fiscale_erede
                        and ogpr.oggetto         = w_oggetto
                        and OGCO.FLAG_POSSESSO   = 'S'
                        and PRTR.TIPO_TRIBUTO||''   = a_tipo_tributo
                        and (OGCO.ANNO||OGCO.TIPO_RAPPORTO||'S') =
                            ( SELECT max (OGCO_SUB.ANNO||OGCO_SUB.TIPO_RAPPORTO||OGCO_SUB.FLAG_POSSESSO)
                                FROM PRATICHE_TRIBUTO PRTR_SUB,
                                     OGGETTI_PRATICA OGPR_SUB,
                                     OGGETTI_CONTRIBUENTE OGCO_SUB
                               WHERE PRTR_SUB.TIPO_TRIBUTO||''   = a_tipo_tributo
                                 and ( (     PRTR_SUB.TIPO_PRATICA||''   = 'D'
                                         and PRTR_SUB.DATA_NOTIFICA is null
                                       )
                                      or
                                       (     PRTR_SUB.TIPO_PRATICA||'' = 'A'
                                         and PRTR_SUB.DATA_NOTIFICA is not null
                                         and nvl(PRTR_SUB.STATO_ACCERTAMENTO,'D') = 'D'
                                         and nvl(PRTR_SUB.FLAG_DENUNCIA,' ') = 'S'
                                         and PRTR_SUB.ANNO <= w_anno_denuncia
                                       )
                                     )
                                 and PRTR_SUB.PRATICA         = OGPR_SUB.PRATICA
                                 and OGCO_SUB.ANNO           <= w_anno_denuncia
                                 and OGCO_SUB.COD_FISCALE     = OGCO.COD_FISCALE
                                 and OGCO_SUB.OGGETTO_PRATICA = OGPR_SUB.OGGETTO_PRATICA
                                 and OGPR_SUB.OGGETTO         = OGPR.OGGETTO
                                 and ogco_sub.tipo_rapporto in ('C', 'D','E')
                                 --
                                 -- (VD) 23/03/2015 - Modificata in analogia al CALCOLO_ICI/TASI
                                 --
                                 --  and nvl(ogco_sub.flag_possesso, 'N') = decode(a_tipo_tributo, 'TASI', 'S', nvl(ogco_sub.flag_possesso, 'N'))
                            )
                       UNION
                     SELECT OGCO.PERC_POSSESSO
                          , ogpr.tipo_oggetto
                          , ogpr.categoria_catasto
                          , ogpr.classe_catasto
                          , ogpr.valore
                          , ogpr.titolo
                          , ogco.flag_esclusione
                          , ogco.flag_ab_principale
                          , prtr.anno
                          , prtr.tipo_pratica
                          , ogpr.flag_valore_rivalutato
                          , ogco.flag_possesso
                       FROM PRATICHE_TRIBUTO     PRTR
                          , OGGETTI_PRATICA      OGPR
                          , OGGETTI_CONTRIBUENTE OGCO
                      WHERE OGCO.OGGETTO_PRATICA    = OGPR.OGGETTO_PRATICA
                        and OGPR.PRATICA            = PRTR.PRATICA
                        and PRTR.TIPO_TRIBUTO||''   = a_tipo_tributo
                        and PRTR.TIPO_PRATICA||''  in ('V','D')
                        and OGCO.FLAG_POSSESSO     IS NULL
                        and OGCO.COD_FISCALE        = w_cod_fiscale_erede
                        and ogpr.oggetto            = w_oggetto
                        and OGCO.ANNO               = w_anno_denuncia
                          ;
                   exception
                      when no_data_found then
                          w_perc_possesso_prec := 0;
                          w_tipo_oggetto_prec  := null;
                          w_categoria_prec     := null;
                          w_classe_prec        := null;
                          w_valore_prec        := null;
                          w_titolo_prec        := null;
                          w_flag_esclusione_prec := null;
                          w_flag_ab_princ_prec := null;
                          w_anno_den_ere_prec  := null;
                          w_tipo_pratica_prec  := null;
                          w_flag_valore_riv_prec := null;
                          w_flag_possesso_prec := null;
                      when others then
                          w_perc_possesso_prec := 0;
                          w_tipo_oggetto_prec  := null;
                          w_categoria_prec     := null;
                          w_classe_prec        := null;
                          w_valore_prec        := null;
                          w_titolo_prec        := null;
                          w_flag_esclusione_prec := null;
                          w_flag_ab_princ_prec := null;
                          w_anno_den_ere_prec  := null;
                          w_tipo_pratica_prec  := null;
                          w_flag_valore_riv_prec := null;
                          w_flag_possesso_prec := null;
                   end;
                   -- Gestione del doppio quadro per variazioni di %pos
                   -- inserimento di un ogpr e ogco
                   -- inserisco il doppio quadro se l'oggetto era precedentemente posseduto
                   if w_perc_possesso_prec <> 0 then
                      -- se risulta pratica TASI per il 2014 con flag_possesso = S
                      -- viene da caricamento automatico, la 'annullo' per far caricare la muova.
                      if a_tipo_tributo = 'TASI'
                     and w_anno_denuncia = 2014
                     and w_flag_possesso_prec is not null then
                     --    if w_cod_fiscale_erede = 'CSLMVT49A60I310H' then
                     --    raise_application_error(-20999, 'ci sono');
                     --    end if;
                         update oggetti_contribuente
                            set flag_possesso = null
                              , mesi_possesso = 0
                              , mesi_esclusione = 0
                              , mesi_possesso_1sem = 0
                              , mesi_riduzione = 0
                        where (oggetto_pratica, cod_fiscale) in
                                                  (SELECT ogco.oggetto_pratica, ogco.cod_fiscale
                                                     FROM oggetti_pratica ogpr,
                                                          pratiche_tributo prtr,
                                                          oggetti_contribuente ogco,
                                                          rapporti_tributo ratr
                                                    WHERE ogpr.pratica = prtr.pratica
                                                      AND ogpr.oggetto_pratica = ogco.oggetto_pratica
                                                      AND prtr.tipo_tributo || '' = a_tipo_tributo
                                                      AND ogpr.oggetto = w_oggetto
                                                      AND ogco.cod_fiscale = w_cod_fiscale_erede
                                                      AND prtr.anno = w_anno_denuncia
                                                      AND prtr.tipo_pratica = 'D'
                                                      AND ratr.cod_fiscale = prtr.cod_fiscale
                                                      AND ratr.pratica = prtr.pratica
                                                      AND ratr.tipo_rapporto in ('C', 'D', 'E')
                                                      AND NVL (ogco.flag_possesso, 'N') = 'S');
                     end if;
                      w_valore_prec := F_VALORE( w_valore_prec
                                               , w_tipo_oggetto_prec
                                               , w_anno_den_ere_prec
                                               , w_anno_denuncia
                                               , w_categoria_prec
                                               , w_tipo_pratica_prec
                                               , w_flag_valore_riv_prec
                                               );
                      w_oggetto_pratica := null;
                      OGGETTI_PRATICA_NR(w_oggetto_pratica);
                      BEGIN
                         insert into oggetti_pratica
                               (oggetto_pratica
                               ,oggetto
                               ,tipo_oggetto
                               ,pratica
                               ,anno
                               ,num_ordine
                               ,categoria_catasto
                               ,classe_catasto
                               ,valore
                               ,flag_valore_rivalutato
                               ,titolo
                               ,fonte
                               ,utente
                               ,data_variazione)
                        values (w_oggetto_pratica
                               ,w_oggetto
                               ,w_tipo_oggetto_prec
                               ,w_pratica
                               ,w_anno_denuncia
                               ,to_char(w_num_ordine)
                               ,w_categoria_prec
                               ,w_classe_prec
                               ,w_valore_prec
                               ,decode(sign(1996 - w_anno_denuncia),
                                           -1,'S','')
                               ,w_titolo_prec
                               ,a_fonte
                               ,a_utente
                               ,trunc(sysdate)
                               )
                                ;
                      EXCEPTION
                         WHEN others THEN
                            sql_errm  := substr(SQLERRM,1,100);
                            w_errore := 'Errore inser ogpr doppio quadro '
                                        ||f_descrizione_titr(a_tipo_tributo, w_anno_denuncia)
                                        ||' ('||sql_errm||')';
                      END;
                   if w_commenti > 0 then
                      DBMS_OUTPUT.Put_Line('Imm.Erede: '||rec_def.successione||'-'||rec_imer.imm_progressivo||'Ins. OGPR def.');
                   end if;
                      w_num_nuovi_ogpr := w_num_nuovi_ogpr + 1;
                      w_num_ordine := w_num_ordine + 1;
                      if w_flag_ab_princ_prec = 'S'
                         and substr(w_categoria_prec,1,1) = 'A'
                         and nvl(w_perc_possesso_prec,0) = 100       then
                          w_detrazione_prec         := round(w_detrazione_base / 12 * (12 - w_mesi_possesso_erede),2);
                      else
                          w_detrazione_prec         := null;
                      end if;
                      BEGIN
                         insert into oggetti_contribuente
                                (cod_fiscale
                                ,oggetto_pratica
                                ,anno
                                ,tipo_rapporto
                                ,perc_possesso
                                ,mesi_possesso
                                ,mesi_possesso_1sem
                                ,mesi_esclusione
                                ,flag_possesso
                                ,flag_esclusione
                                ,flag_ab_principale
                                ,detrazione
                                ,utente
                                ,data_variazione
                                ,perc_detrazione)
                         values (w_cod_fiscale_erede
                                ,w_oggetto_pratica
                                ,w_anno_denuncia
                                ,'D'
                                ,w_perc_possesso_prec
                                ,12 - w_mesi_possesso_erede
                                ,6 - w_mesi_possesso_1sem_erede
                                ,decode(w_flag_esclusione_prec
                                       ,'S',12 - w_mesi_possesso_erede
                                       ,null
                                       )
                                ,null
                                ,null
                                ,null
                                ,w_detrazione_prec
                                ,a_utente
                                ,trunc(sysdate)
                                ,decode(w_detrazione_prec,null,null,100))
                           ;
                      EXCEPTION
                         WHEN others THEN
                            sql_errm  := substr(SQLERRM,1,100);
                            w_errore := 'Errore in inserim. ogco '
                                        ||f_descrizione_titr(a_tipo_tributo, w_anno_denuncia)
                                        ||' ('||sql_errm||')';
                      END;
                   end if; -- w_perc_possesso_prec <> 0
                   -- Inserimento oggetto_pratica Erede
                   if w_commenti > 0 then
                      DBMS_OUTPUT.Put_Line('Imm.Erede: '||rec_def.successione||'-'||rec_imer.imm_progressivo||' Ins. OGPR');
                   end if;
                   w_oggetto_pratica := null;
                   OGGETTI_PRATICA_NR(w_oggetto_pratica);
                   BEGIN
                      insert into oggetti_pratica
                            (oggetto_pratica
                            ,oggetto
                            ,tipo_oggetto
                            ,pratica
                            ,anno
                            ,num_ordine
                            ,categoria_catasto
                            ,valore
                            ,flag_valore_rivalutato
                            ,fonte
                            ,utente
                            ,data_variazione)
                     values (w_oggetto_pratica
                            ,w_oggetto
                            ,w_tipo_oggetto
                            ,w_pratica
                            ,w_anno_denuncia
                            ,to_char(w_num_ordine)
                            ,w_categoria
                            ,w_valore_ogpr
                            ,decode(sign(1996 - w_anno_denuncia),
                                        -1,'S','')
                            ,a_fonte
                            ,a_utente
                            ,trunc(sysdate)
                            )
                             ;
                   EXCEPTION
                      WHEN others THEN
                         sql_errm  := substr(SQLERRM,1,100);
                         w_errore := 'Errore inser ogpr '
                                     ||f_descrizione_titr(a_tipo_tributo, w_anno_denuncia)
                                     ||' ('||sql_errm||')';
                   END;
                   w_num_nuovi_ogpr := w_num_nuovi_ogpr + 1;
                   w_num_ordine := w_num_ordine + 1;
                   -- #63046 - Se denominatore quota non è valido mi tengo la percentuale possesso precedente
                   if rec_imer.denominatore_quota > 0 then
                     w_perc_possesso_erede := rec_imer.numeratore_quota / rec_imer.denominatore_quota * t_perc_pos_def(rec_imer.immobile)
                                            + w_perc_possesso_prec ;
                   end if;
                   -- Recupero Detrazione e Flag Ab principale
                   if rec_eredi.indirizzo = rec_imer.indirizzo and
                      rec_def.comune    = w_comune_erede then
                       if substr(w_categoria,1,1) = 'A' and nvl(w_perc_possesso_erede,0) = 100 then
                          w_detrazione         := round(w_detrazione_base / 12 * w_mesi_possesso_erede,2);
                       else
                          w_detrazione         := null;
                       end if;
                       w_flag_ab_principale := 'S';
                   else
                       w_detrazione         := null;
                       w_flag_ab_principale := null;
                   end if;
                   -- inserimento oggetto_contribuente erede
                   if w_commenti > 0 then
                      DBMS_OUTPUT.Put_Line('Imm.Erede: '||rec_def.successione||'-'||rec_imer.imm_progressivo||' Ins. OGCO');
                   end if;
                   BEGIN
                      insert into oggetti_contribuente
                             (cod_fiscale
                             ,oggetto_pratica
                             ,anno
                             ,tipo_rapporto
                             ,perc_possesso
                             ,mesi_possesso
                             ,mesi_possesso_1sem
                             ,flag_possesso
                             ,flag_ab_principale
                             ,detrazione
                             ,successione
                             ,progressivo_sudv
                             ,utente
                             ,data_variazione
                             ,perc_detrazione)
                      values (w_cod_fiscale_erede
                             ,w_oggetto_pratica
                             ,w_anno_denuncia
                             ,'D'
                             ,w_perc_possesso_erede
                             ,w_mesi_possesso_erede
                             ,w_mesi_possesso_1sem_erede
                             ,'S'
                             ,w_flag_ab_principale
                             ,w_detrazione
                             ,rec_def.successione
                             ,rec_imer.dev_progressivo
                             ,a_utente
                             ,trunc(sysdate)
                             ,decode(w_detrazione,null, null,100))
                        ;
                   EXCEPTION
                      WHEN others THEN
                         sql_errm  := substr(SQLERRM,1,100);
                         w_errore := 'Errore inserim. ogco '
                                     ||f_descrizione_titr(a_tipo_tributo, w_anno_denuncia)
                                     ||' ('||sql_errm||')';
                   END;
                end loop; -- rec_imer
                begin
                   select count(1)
                     into w_conta_ogpr
                     from oggetti_pratica
                    where pratica = w_pratica
                    ;
                EXCEPTION
                   WHEN others THEN
                       w_conta_ogpr := 0;
                end;
                if nvl(w_conta_ogpr,0) = 0 then
                   -- cancellazione pratica
                   begin
                      delete pratiche_tributo
                       where pratica = w_pratica
                           ;
                   EXCEPTION
                       WHEN others THEN
                          sql_errm  := substr(SQLERRM,1,100);
                          w_errore := 'Errore cancellazione pratica no_ogpr '
                                      ||f_descrizione_titr(a_tipo_tributo, w_anno_denuncia)
                                      ||' ('||sql_errm||')';
                          raise errore;
                   end;
                else
                   w_num_nuove_pratiche := w_num_nuove_pratiche + 1;
                   -- Aggiornamento SUER (Pratica)
                   ins_upd_sute(rec_def.successione, a_tipo_tributo, rec_eredi.progressivo, w_pratica);
                   -- Inserimento eredi_soggetto
                   begin
                      select count(1)
                        into w_trova_erede
                        from eredi_soggetto
                       where ni = w_ni_def
                         and ni_erede = w_ni_erede
                         ;
                   EXCEPTION
                      when no_data_found then
                         w_trova_erede := 0;
                      WHEN others THEN
                         sql_errm  := substr(SQLERRM,1,100);
                         w_errore := 'Errore verifica eredi_soggetto '
                                     ||f_descrizione_titr(a_tipo_tributo, w_anno_denuncia)
                                     ||' ('||sql_errm||')';
                   end;
                   if w_trova_erede = 0 then
                      begin
                         insert into eredi_soggetto
                                ( ni
                                , ni_erede
                                , numero_ordine
                                , utente)
                         values ( w_ni_def
                                , w_ni_erede
                                , w_max_numero_ordine_erede + rec_eredi.progressivo
                                , a_utente
                                )
                                ;
                      EXCEPTION
                         WHEN others THEN
                            sql_errm  := substr(SQLERRM,1,100);
                            w_errore := 'Errore inserim. eredi_soggetto '
                                        ||f_descrizione_titr(a_tipo_tributo, w_anno_denuncia)
                                        ||' ('||sql_errm||')';
                      end;
                   end if;
                end if;-- w_conta_ogpr = 0
         end loop;  --rec_eredi
         -- Modifica stato successione (nuova denuncia)
         --upd_sutd(rec_def.successione, a_tipo_tributo, 'CARICATA', null);
         upd_sutd(rec_def.successione, a_tipo_tributo, 'CARICATA', w_pratica_defunto);
      else
         -- Modifica stato successione (denuncia esistente)
         --upd_sutd(rec_def.successione, a_tipo_tributo, 'GIA'' CARICATA', w_pratica);
         upd_sutd(rec_def.successione, a_tipo_tributo, 'GIA'' CARICATA', null);
         w_pratiche_gia_inserite := w_pratiche_gia_inserite + 1;
      end if; -- w_pratica_esistente = 0
   end loop; -- rec_def
   --
   -- (VD - 10/01/2020): a fine elaborazione, si archiviano tutte le
   --                    denunce inserite
   -- (VD - 11/02/2020): aggiunto test indice array, per non lanciare
   --                    l'archiviazione se l'array e' vuoto
   --
   if w_ind > 0 then
      for w_ind in t_pratica.first .. t_pratica.last
      loop
        if t_pratica(w_ind) is not null then
           archivia_denunce('','',t_pratica(w_ind));
        end if;
      end loop;
   end if;
   a_nuove_pratiche        := w_num_nuove_pratiche;
   a_nuovi_oggetti         := w_num_nuovi_oggetti;
   a_nuovi_contribuenti    := w_num_nuovi_contribuenti;
   a_nuovi_soggetti        := w_num_nuovi_soggetti;
   a_pratiche_gia_inserite := w_pratiche_gia_inserite;
EXCEPTION
   WHEN ERRORE THEN
      ROLLBACK;
      RAISE_APPLICATION_ERROR(-20999,nvl(w_errore,'vuoto'));
   WHEN OTHERS THEN
      ROLLBACK;
      RAISE_APPLICATION_ERROR(-20999,substr(SQLERRM,1,200));
end;
/* End Procedure: GESTIONE_SUCCESSIONI_TITR */
/

