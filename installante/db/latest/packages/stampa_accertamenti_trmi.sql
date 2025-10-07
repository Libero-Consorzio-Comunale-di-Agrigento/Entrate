--liquibase formatted sql 
--changeset abrandolini:20250326_152429_stampa_accertamenti_trmi stripComments:false runOnChange:true 
 
create or replace package STAMPA_ACCERTAMENTI_TRMI is
/******************************************************************************
 NOME:        STAMPA_ACCERTAMENTI_TRMI
 DESCRIZIONE: Funzione per stampa avvisi di accertamento tributi minori
              TributiWeb
 ANNOTAZIONI: -
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 005   04/07/2024  RV      #73581
                           Aggiunto totale imposta e totale imposta netta in CANONI e PRINCIPALE
 004   14/06/2024  RV      #55525
                           Aggiunto INTERESSI_DETTAGLIO
 003   29/03/2024  RV      #71295
                           Aggiunto dati occupazione ad estrazione canoni
 002   27/02/2023  RV      #62507
                           Modificato select CANONI data_concessione su dett_conc
 001   21/02/2023  RV      #62507
                           Modificato select CANONI per oggetti con imposta zero x CUNI
 000   15/03/2022  VD      Prima emissione
******************************************************************************/
  function principale
  ( a_pratica              number default -1
  , a_modello              number default -1
  , a_ni_erede             number default -1
  ) return sys_refcursor;
  function contribuente
  ( a_pratica                           number default -1
  , a_ni_erede             number default -1
  ) return sys_refcursor;
  function oggetti
  ( a_pratica                           number default -1
  , a_modello                           number default -1
  ) return sys_refcursor;
  function canoni
  ( a_pratica                           number default -1
  , a_modello                           number default -1
  ) return sys_refcursor;
  function versamenti
  ( a_pratica                           number default -1
  , a_modello                           number default -1
  ) return sys_refcursor;
  function imposta_evasa
  ( a_pratica                           number default -1
  , a_modello                           number default -1
  ) return sys_refcursor;
  function sanzioni_interessi
  ( a_pratica                           number default -1
  , a_modello                           number default -1
  ) return sys_refcursor;
  function riepilogo_f24
  ( a_pratica                           number default -1
  , a_modello                           number default -1
  ) return sys_refcursor;
  function aggi_dilazioni
  ( a_pratica                                   number default -1
  , a_modello                                   number default -1
  ) return sys_refcursor;
  function interessi_dettaglio
  ( a_pratica               number default -1
  , a_modello               number default -1
  ) return sys_refcursor;
  function eredi
  ( a_ni_deceduto           number default -1
  , a_ni_erede_da_escludere number default -1
  ) return sys_refcursor;
end STAMPA_ACCERTAMENTI_TRMI;
/
create or replace package body STAMPA_ACCERTAMENTI_TRMI is
/*************************************************************************
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 005   04/07/2024  RV      #73581
                           Aggiunto totale imposta e totale imposta netta in CANONI e PRINCIPALE
 004   14/06/2024  RV      #55525
                           Aggiunto INTERESSI_DETTAGLIO
 003   29/03/2024  RV      #71295
                           Aggiunto dati occupazione ad estrazione canoni
 002   27/02/2023  RV      #62507
                           Modificato select CANONI data_concessione su dett_conc
 001   21/02/2023  RV      #62507
                           Modificato select CANONI per oggetti con imposta zero x CUNI
 000   15/03/2022  VD      Prima emissione
*************************************************************************/
----------------------------------------------------------------------------------
  function CONTRIBUENTE
  ( a_pratica                           number default -1
  , a_ni_erede             number default -1
  ) return sys_refcursor is
  /******************************************************************************
    NOME:        CONTRIBUENTE.
    DESCRIZIONE: Restituisce tutti i dati relativi al contribuente per il tipo
                 tributo indicato.
                 Richiama funzione standard del package STAMPA_COMMON.
    RITORNA:     ref_cursor.
    NOTE:
  ******************************************************************************/
    rc sys_refcursor;
  begin
    rc := stampa_common.contribuente(a_pratica, a_ni_erede);
    return rc;
  end;
----------------------------------------------------------------------------------
  function PRINCIPALE
  ( a_pratica                           number default -1
  , a_modello                           number default -1
  , a_ni_erede                          number default -1
  ) return sys_refcursor is
  /******************************************************************************
    NOME:        PRINCIPALE.
    DESCRIZIONE: Restituisce tutti i dati relativi alla pratica indicata
    RITORNA:     ref_cursor.

    Rev.  Data        Autore  Descrizione
    ----  ----------  ------  ----------------------------------------------------
    001   04/07/2024  RV      #73581
                              Aggiunto st_imposta_totale ed st_imposta_netta_totale
    000   15/03/2022  VD      Prima emissione
  ******************************************************************************/
    --
    rc                          sys_refcursor;
    v_rc                        sys_refcursor;
    --
    v_imposta_totale            varchar2(40);
    v_imposta_netta_totale      varchar2(40);
    --
    type t_dati_canoni is record
    ( descrizione_utenza        varchar2(60),
      descrizione_codice        varchar2(100),
      descrizione_tariffa       varchar2(2000),
      descrizione_tariffa_magg  varchar2(2000),
      importo_tariffa           varchar2(100),
      periodo_tariffa           varchar2(20),
      occupazione_tariffa       varchar2(100),
      dati_categoria            varchar2(200),
      indirizzo_utenza          varchar2(2000),
      localita_utenza           varchar2(60), 
      comune_utenza             varchar2(60), 
      provincia_utenza          varchar2(60), 
      sigla_prov_utenza         varchar2(10), 
      dati_tariffa              varchar2(100),
      periodo_imposta           varchar2(100),
      estremi_catastali         varchar2(100),
      categoria_catasto         varchar2(10),
      superficie                varchar2(20),
      descrizione_perc_poss     varchar2(10),
      base_tariffa              varchar2(20),
      coeff_tariffa             varchar2(20),
      riduz_tariffa             varchar2(20),
      magg_tariffa              varchar2(20),
      descrizione_perc_detr     varchar2(40),
      descrizione_perc_magg     varchar2(40),
      note_tariffa              varchar2(2000), 
      periodo_ruolo             varchar2(100),
      imposta                   varchar2(20),
      imposta_netta             varchar2(20),
      oggetto_pratica           number(10,0),
      oggetto_imposta           number(10,0),
      oggetto                   number(10,0),
      flag_domestica            varchar2(10),
      inizio_occ                varchar2(12),
      fine_occ                  varchar2(12),
      inizio_conc               varchar2(12),
      fine_conc                 varchar2(12),
      conc_numero               number(10,0),
      conc_data                 varchar2(12),
      dett_conc                 varchar2(200),
      larghezza                 number(7,2),
      profondita                number(7,2),
      mq_reali                  number(8,2),
      quantita                  number(6,0),
      mq                        number(8,2),
      dett_cons                 varchar2(200),
      imposta_totale            varchar2(20),
      imposta_netta_totale      varchar2(20),
      modello                   number(10)
    );
    v_dati_canoni t_dati_canoni;
    --
  begin
    --
    v_imposta_totale := null;
    v_imposta_netta_totale := null;
    --
    v_rc := canoni(a_pratica, a_modello);
    loop
      fetch v_rc
        into v_dati_canoni;
      exit when v_rc%notfound;
      v_imposta_totale := v_dati_canoni.imposta_totale;
      v_imposta_netta_totale := v_dati_canoni.imposta_netta_totale;
      exit;
    end loop;
    --
    open rc for
      select a_modello modello
           , prtr_acc.pratica
           , prtr_acc.anno
           , to_char(prtr_acc.data,'dd/mm/yyyy') data
           , prtr_acc.numero
           , f_descrizione_timp(a_modello,'TOT') l_importo_totale
           , stampa_common.f_formatta_numero(f_round(prtr_acc.importo_totale,1),'I','S') st_importo_totale
           -- (VD - 04/04/2022): su indicazione di Elisabetta A. l'importo arrotondato viene sempre
           --                    valorizzato, indipendentemente dai parametri
           --, decode(f_descrizione_timp(a_modello,'VIS_TOT_ARR')
           --        ,'SI',decode(titr.flag_canone
           --                    ,null,f_descrizione_timp(a_modello,'TOT_ARR')
           --                    ,null)
           --        ,null)              l_importo_totale_arrotondato
           , f_descrizione_timp(a_modello,'TOT_ARR') l_importo_totale_arrotondato
           --, decode(f_descrizione_timp(a_modello,'VIS_TOT_ARR')
           --        ,'SI',decode(titr.flag_canone
           --                    ,null,stampa_common.f_formatta_numero(round(prtr_acc.importo_totale,0),'I','S')
           --                    ,null)
           --        ,null)              st_importo_totale_arrotondato
           , stampa_common.f_formatta_numero(round(prtr_acc.importo_totale,0),'I','S') st_importo_totale_arrotondato
            , decode(f_round(prtr_acc.importo_totale,1)
                   ,f_round(prtr_acc.importo_ridotto,1),null
                   ,decode(prtr_acc.tipo_tributo
                          ,'TOSAP',f_descrizione_timp(a_modello,'TOT_AD')
                          ,null)
                   )                   l_importo_ridotto
           , decode(f_round(prtr_acc.importo_totale,1)
                   ,f_round(prtr_acc.importo_ridotto,1),null
                   ,stampa_common.f_formatta_numero(f_round(prtr_acc.importo_ridotto,1),'I','S')
                   )                   st_importo_ridotto
           -- (VD - 04/04/2022): su indicazione di Elisabetta A. l'importo arrotondato viene sempre
           --                    valorizzato, indipendentemente dai parametri
           --, decode(f_descrizione_timp(a_modello,'VIS_TOT_ARR')
           --        ,'SI',decode(f_round(prtr_acc.importo_totale,1)
           --                    ,f_round(prtr_acc.importo_ridotto,1),null
           --                    ,decode(titr.flag_canone
           --                           ,null,f_descrizione_timp(a_modello,'TOT_AD_ARR')
           --                           ,null))
           --        ,null)              l_importo_ridotto_arrotondato
           , f_descrizione_timp(a_modello,'TOT_AD_ARR') l_importo_ridotto_arrotondato
           --, decode(f_descrizione_timp(a_modello,'VIS_TOT_ARR')
           --        ,'SI',decode(f_round(prtr_acc.importo_totale,1)
           --                    ,f_round(prtr_acc.importo_ridotto,1),null
           --                    ,decode(titr.flag_canone
           --                           ,null,stampa_common.f_formatta_numero(round(prtr_acc.importo_ridotto,0),'I','S')
           --                           ,null))
           --        ,null)             st_importo_ridotto_arrotondato
           , stampa_common.f_formatta_numero(round(prtr_acc.importo_ridotto,0),'I','S') st_importo_ridotto_arrotondato
           , translate(prtr_acc.motivo,chr(013)||chr(010),'  ')  motivo
           , decode(prtr_acc.tipo_tributo
                   ,'TOSAP',f_descrizione_timp(a_modello,'TOT_IMP_COMP')
                   ,null) l_totale_imposta_complessiva
           , decode(prtr_acc.tipo_tributo
                   ,'TOSAP',trim(f_descrizione_timp(a_modello,'RIE_SOM_DOV'))
                   ,null) l_riepilogo_somme_dovute
           , v_imposta_totale as st_imposta_totale
           , v_imposta_netta_totale as st_imposta_netta_totale
           , a_ni_erede   ni_erede
        from PRATICHE_TRIBUTO       PRTR_ACC
           , TIPI_TRIBUTO           TITR
       where titr.tipo_tributo           = prtr_acc.tipo_tributo
         and prtr_acc.pratica            = a_pratica
       order by prtr_acc.anno
              , prtr_acc.data
              , prtr_acc.numero;
    return rc;
  end;
----------------------------------------------------------------------------------
  procedure GET_DATI_PRATICA
  ( a_pratica                           in number
  , a_tipo_tributo                      in out varchar2
  , a_cod_fiscale                       in out varchar2
  , a_anno                              in out number
  , a_data_pratica                      in out date
  ) is
  /******************************************************************************
    NOME:        GET_DATI_PRATICA.
    DESCRIZIONE: Restituisce i dati della pratica che si sta trattando.
    NOTE:
  ******************************************************************************/
    w_tipo_tributo                      varchar2(5);
    w_cod_fiscale                       varchar2(16);
    w_anno                              number;
    w_data_pratica                      date;
  begin
    -- Selezione dati pratica
    -- Gestione del valore -1 per estrazione campi in csv
    if a_pratica = -1 then
       w_tipo_tributo := null;
       w_cod_fiscale  := null;
       w_anno         := to_number(null);
       w_data_pratica := to_date(null);
    else
       begin
         select tipo_tributo
              , cod_fiscale
              , anno
              , data
           into w_tipo_tributo
              , w_cod_fiscale
              , w_anno
              , w_data_pratica
           from PRATICHE_TRIBUTO
          where pratica = a_pratica;
       exception
         when others then
           raise_application_error(-20999,'Errore in ricerca pratica '||a_pratica||' - '||sqlerrm);
       end;
    end if;
    a_tipo_tributo := w_tipo_tributo;
    a_cod_fiscale  := w_cod_fiscale;
    a_anno         := w_anno;
    a_data_pratica := w_data_pratica;
  end;
----------------------------------------------------------------------------------
  function OGGETTI
  ( a_pratica                           number default -1
  , a_modello                           number default -1
  ) return sys_refcursor is
  /******************************************************************************
    NOME:        OGGETTI.
    DESCRIZIONE: Restituisce gli oggetti della pratica di accertamento e i loro
                 dati.
    RITORNA:     ref_cursor.
    NOTE:
  ******************************************************************************/
    w_tipo_tributo                      varchar2(5);
    w_cod_fiscale                       varchar2(16);
    w_anno                              number;
    w_data_pratica                      date;
    rc                                  sys_refcursor;
  begin
    -- Selezione dati pratica
    get_dati_pratica(a_pratica,w_tipo_tributo,w_cod_fiscale,w_anno,w_data_pratica);
    --
    open rc for
      select a_modello
           , prtr_acc.pratica              pratica
           , ogdic.oggetto_imposta_d       oggetto_imposta_dic
           , ogim_acc.oggetto_imposta
           , case
               when (prtr_acc.tipo_tributo = 'TOSAP' and
                     f_descrizione_timp(a_modello,'ACC_ELENCO') = 'SI') or
                     prtr_acc.tipo_tributo <> 'TOSAP'
                 then cate.descrizione
                 else null
             end                           descr_categoria
           , ogdic.descr_categoria_d       descr_categoria_dic
           , ogim_acc.anno                 anno
           , ogdic.a_anno                  anno_dic
           , prtr_acc.numero               prtr_numero
           , prtr_acc.anno                 prtr_anno
           , decode(ogpr_acc.oggetto_pratica_rif,null,null,'DICHIARATI') l_dichiarati
           , case
               when (prtr_acc.tipo_tributo = 'TOSAP' and
                     f_descrizione_timp(a_modello,'ACC_ELENCO') = 'SI') or
                     prtr_acc.tipo_tributo <> 'TOSAP'
                 then to_char(ogpr_acc.data_concessione,'dd/mm/yyyy')
                 else null
             end                           data_concessione
           , case
               when (prtr_acc.tipo_tributo = 'TOSAP' and
                     f_descrizione_timp(a_modello,'ACC_ELENCO') = 'SI') or
                     prtr_acc.tipo_tributo <> 'TOSAP'
                 then to_char(ogco_acc.inizio_occupazione,'dd/mm/yyyy')
                 else null
             end                           data_inizio_occupazione
           , case
               when (prtr_acc.tipo_tributo = 'TOSAP' and
                     f_descrizione_timp(a_modello,'ACC_ELENCO') = 'SI') or
                     prtr_acc.tipo_tributo <> 'TOSAP'
                 then to_char(ogco_acc.fine_occupazione,'dd/mm/yyyy')
                 else null
             end                           data_fine_occupazione
           , to_char(ogdic.data_concessione_d,'dd/mm/yyyy')    data_concessione_dic
           , to_char(ogdic.inizio_occupazione_d,'dd/mm/yyyy')  data_inizio_occupazione_dic
           , to_char(ogdic.fine_occupazione_d,'dd/mm/yyyy')    data_fine_occupazione_dic
           , decode(ogpr_acc.data_concessione
                   ,null,decode(ogdic.data_concessione_d
                               ,null,null
                               ,'DATA CONCESSIONE:')
                   ,'DATA CONCESSIONE:') l_data_concessione
           , decode(ogco_acc.inizio_occupazione
                   ,null,decode(ogdic.inizio_occupazione_d
                               ,null,null
                               ,'INIZIO OCCUPAZ. :')
                   ,'INIZIO OCCUPAZ. :') l_inizio_occupazione
           , decode(ogco_acc.fine_occupazione
                   ,null,decode(ogdic.fine_occupazione_d
                               ,null,null
                               ,'FINE OCCUPAZIONE:')
                   ,'FINE OCCUPAZIONE:') l_fine_occupazione
           , decode(prtr_acc.tipo_tributo
                   ,'TOSAP',decode(f_descrizione_timp(a_modello,'ACC_ELENCO')
                                  ,'SI',stampa_common.f_formatta_numero(ogim_acc.importo_versato,'I','N')
                                  ,null)
                   ,stampa_common.f_formatta_numero(ogim_acc.importo_versato,'I','N')
                   )                     st_importo_versato
           , stampa_common.f_formatta_numero(ogdic.importo_versato_d,'I','N') importo_versato_dic
           , case
               when (prtr_acc.tipo_tributo = 'TOSAP' and
                     f_descrizione_timp(a_modello,'ACC_ELENCO') = 'SI') or
                     prtr_acc.tipo_tributo <> 'TOSAP'
                 then stampa_common.f_formatta_numero(ogim_acc.imposta,'I','N')
                 else null
             end                         st_imposta_dovuta
           , stampa_common.f_formatta_numero(ogdic.imposta,'I','N') st_imposta_dovuta_dic
           , case
               when nvl(ogim_acc.importo_versato,0) <> 0 or
                    nvl(ogdic.importo_versato_d,0) <> 0
                 then 'IMPORTO VERSATO :'
                 else null
             end                          l_importo_versato
           , case
               when nvl(ogim_acc.imposta,0) = 0 and
                    nvl(ogdic.imposta,0) = 0
               then null
               else
                 case
                   when prtr_acc.tipo_tributo = 'TOSAP'
                     then f_descrizione_timp(a_modello,'DIC ACC IMP DOV')||' :'
                     else 'IMPOSTA DOVUTA :'
                 end
             end                          l_imposta_dovuta
           , to_char(prtr_acc.data,'dd/mm/yyyy') data_acc
           , case
               when (prtr_acc.tipo_tributo = 'TOSAP' and
                     rtrim(f_descrizione_timp(a_modello,'INTE')) = 'DEFAULT') or
                     prtr_acc.tipo_tributo <> 'TOSAP'
                 then 'Accertamento per '||
                      decode(ogpr_acc.tipo_occupazione||
                             ogpr_acc.consistenza     ||
                             ogpr_acc.tributo         ||
                             ogpr_acc.categoria       ||
                             ogpr_acc.tipo_tariffa    ||
                             ogco_acc.perc_possesso
                            ,ogdic.tipo_occupazione   ||
                             ogdic.cons               ||
                             ogdic.tributo            ||
                             ogdic.categoria          ||
                             ogdic.tipo_tariffa       ||
                             ogdic.perc_possesso_d ,'parziale/omesso versamento'
                            ,'infedele/omessa denuncia')
                 else
                      rtrim(f_descrizione_timp(a_modello,'INTE'))
             end tipo_accertamento
           , decode(ogdic.cons
                   ,null,null
                   ,decode(sign(ogpr_acc.consistenza - ogdic.cons)
                          ,1,'UTENZA GIA'' A RUOLO PER '|| ogdic.cons ||' MQ.', null)
                   ) consistenza_dic
           , ceil(months_between(decode(ogco_acc.data_cessazione
                                       ,null,to_date(decode(ogco_acc.data_decorrenza
                                                           ,null,'31/12/1900'
                                                           ,'31/12/'||to_char(ogco_acc.data_decorrenza,'yyyy'))
                                                    ,'dd/mm/yyyy')
                                       ,ogco_acc.data_cessazione)
                                ,decode(ogco_acc.data_decorrenza
                                       ,null,to_date(decode(ogco_acc.data_cessazione
                                                           ,null,'01/01/1901'
                                                           ,'01/01/'||to_char(ogco_acc.data_cessazione,'yyyy'))
                                                    ,'dd/mm/yyyy')
                                       ,ogco_acc.data_decorrenza))) mesi
           , ceil(months_between(decode(ogdic.data_cessazione_d
                                       ,null,to_date(decode(ogdic.data_decorrenza_d
                                                           ,null,'31/12/1900'
                                                           ,'31/12/'||to_char(ogdic.data_decorrenza_d,'yyyy'))
                                                    ,'dd/mm/yyyy')
                                       ,ogdic.data_cessazione_d)
                                ,decode(ogdic.data_decorrenza_d
                                       ,null,to_date(decode(ogdic.data_cessazione_d
                                                           ,null,'01/01/1901'
                                                           ,'01/01/'||to_char(ogdic.data_cessazione_d,'yyyy'))
                                                    ,'dd/mm/yyyy')
                                       ,ogdic.data_decorrenza_d))) mesi_dic
           , case
               when (prtr_acc.tipo_tributo = 'TOSAP' and
                     f_descrizione_timp(a_modello,'ACC_ELENCO') = 'SI') or
                     prtr_acc.tipo_tributo <> 'TOSAP'
                 then
                     stampa_common.f_formatta_numero(tari.tariffa,'T','N')
                 else null
             end                           st_tariffa
           , case
               when (prtr_acc.tipo_tributo = 'TOSAP' and
                     f_descrizione_timp(a_modello,'ACC_ELENCO') = 'SI') or
                     prtr_acc.tipo_tributo <> 'TOSAP'
                 then tari.descrizione
                 else null
             end                           descr_tariffa
           , stampa_common.f_formatta_numero(ogdic.tariffa_d,'T','N') st_tariffa_dic
           , ogdic.descr_tariffa_d descr_tariffa_dic
           , case
               when (prtr_acc.tipo_tributo = 'TOSAP' and
                     f_descrizione_timp(a_modello,'ACC_ELENCO') = 'SI') or
                     prtr_acc.tipo_tributo <> 'TOSAP'
                 then decode(ogpr_acc.tipo_occupazione
                            ,'P','PERMANENTE'
                            ,'T','TEMPORANEA'
                            ,null)
                 else null
             end tipo_occupazione
           , decode(ogdic.tipo_occupazione
                   ,'P','PERMANENTE'
                   ,'T','TEMPORANEA'
                   ,null) tipo_occupazione_dic
           , decode(oggetti.cod_via
                   ,null,oggetti.indirizzo_localita
                   ,archivio_vie.denom_uff)||
                    decode(oggetti.num_civ,null,'',', '||oggetti.num_civ)||
                    decode(oggetti.suffisso,null,'', '/'||oggetti.suffisso)  indirizzo_oggetto
           , case
               when (prtr_acc.tipo_tributo = 'TOSAP' and
                     f_descrizione_timp(a_modello,'ACC_ELENCO') = 'SI') or
                     prtr_acc.tipo_tributo <> 'TOSAP'
                 then stampa_common.f_formatta_numero(ogpr_acc.consistenza,'I','N')
                 else null
             end                           st_superficie
           , stampa_common.f_formatta_numero(ogdic.cons,'I','N') st_superficie_dic
           , case
               when (prtr_acc.tipo_tributo = 'TOSAP' and
                     f_descrizione_timp(a_modello,'ACC_ELENCO') = 'SI') or
                     prtr_acc.tipo_tributo <> 'TOSAP'
                 then stampa_common.f_formatta_numero(nvl(ogco_acc.perc_possesso,100),'P','S')
                 else null
             end                           st_perc_possesso
           , decode(ogpr_acc.oggetto_pratica_rif
                   ,null,null
                   ,stampa_common.f_formatta_numero(nvl(ogdic.perc_possesso_d,100),'P','S')
                   ) st_perc_possesso_dic
           , case
               when prtr_acc.tipo_tributo = 'TOSAP' and
                    f_descrizione_timp(a_modello,'ACC_ELENCO') = 'SI'
                 then f_descrizione_timp(a_modello,'ACC')
                 else null
             end                           l_accertati
           , oggetti.oggetto
           , decode(oggetti.descrizione,null,'','DESCRIZIONE :') l_descrizione
           , oggetti.descrizione
        from archivio_vie
           , oggetti
           , categorie cate
           , tariffe tari
           , oggetti_imposta      ogim_acc
           , oggetti_contribuente ogco_acc
           , oggetti_pratica      ogpr_acc
           , pratiche_tributo     prtr_acc
           ,(select ogpr_dic.consistenza cons
                  , ogpr_dic.oggetto_pratica    ogpr
                  , ogim_dic.oggetto_imposta    oggetto_imposta_d
                  , ogim_dic.anno  a_anno
                  , ogim_dic.imposta  imposta
                  , ogim_dic.importo_versato    importo_versato_d
                  , ogpr_dic.tipo_occupazione
                  , ogpr_dic.tributo
                  , ogpr_dic.categoria
                  , ogpr_dic.tipo_tariffa
                  , ogpr_dic.data_concessione   data_concessione_d
                  , ogco_dic.inizio_occupazione inizio_occupazione_d
                  , ogco_dic.fine_occupazione   fine_occupazione_d
                  , ogco_dic.perc_possesso      perc_possesso_d
                  , ogco_dic.data_decorrenza    data_decorrenza_d
                  , ogco_dic.data_cessazione    data_cessazione_d
                  , cate_dic.descrizione        descr_categoria_d
                  , tari_dic.tariffa            tariffa_d
                  , tari_dic.descrizione        descr_tariffa_d
               from tariffe               tari_dic
                  , categorie             cate_dic
                  , oggetti_contribuente  ogco_dic
                  , oggetti_pratica       ogpr_dic
                  , oggetti_imposta       ogim_dic
                  , pratiche_tributo      prtr_dic
              where prtr_dic.pratica            = ogpr_dic.pratica
                and prtr_dic.tipo_pratica       = 'D'
                and prtr_dic.tipo_tributo||''   = 'TOSAP'
                and cate_dic.categoria          = tari_dic.categoria
                and cate_dic.tributo            = tari_dic.tributo
                and tari_dic.anno               = w_anno
                and tari_dic.tributo            = ogpr_dic.tributo
                and tari_dic.categoria          = ogpr_dic.categoria
                and tari_dic.tipo_tariffa       = ogpr_dic.tipo_tariffa
                and ogim_dic.ruolo  (+)         is null
                and ogim_dic.cod_fiscale(+)     = ogco_dic.cod_fiscale
                and ogim_dic.oggetto_pratica(+) = ogco_dic.oggetto_pratica
                and ogim_dic.flag_calcolo (+)   = 'S'
                and ogim_dic.anno (+)           = w_anno
                and ogco_dic.oggetto_pratica    = ogpr_dic.oggetto_pratica
                and ogco_dic.cod_fiscale        = w_cod_fiscale
              group by ogpr_dic.consistenza
                     , ogpr_dic.oggetto_pratica
                     , ogim_dic.oggetto_imposta
                     , ogim_dic.anno
                     , ogim_dic.imposta
                     , ogim_dic.importo_versato
                     , ogpr_dic.tipo_occupazione
                     , ogpr_dic.tributo
                     , ogpr_dic.categoria
                     , ogpr_dic.tipo_tariffa
                     , ogpr_dic.data_concessione
                     , ogco_dic.inizio_occupazione
                     , ogco_dic.fine_occupazione
                     , ogco_dic.perc_possesso
                     , ogco_dic.data_decorrenza
                     , ogco_dic.data_cessazione
                     , cate_dic.descrizione
                     , tari_dic.tariffa
                     , tari_dic.descrizione) ogdic
       where oggetti.cod_via              = archivio_vie.cod_via (+)
         and oggetti.oggetto              = ogpr_acc.oggetto
         and cate.tributo                 = tari.tributo
         and cate.categoria               = tari.categoria
         and tari.anno                    = prtr_acc.anno
         and tari.tributo                 = ogpr_acc.tributo
         and tari.categoria               = ogpr_acc.categoria
         and tari.tipo_tariffa            = ogpr_acc.tipo_tariffa
         and ogim_acc.anno (+)            = ogco_acc.anno
         and ogim_acc.cod_fiscale (+)     = ogco_acc.cod_fiscale
         and ogim_acc.oggetto_pratica (+) = ogco_acc.oggetto_pratica
         and ogco_acc.cod_fiscale         = w_cod_fiscale
         and ogco_acc.oggetto_pratica     = ogpr_acc.oggetto_pratica
         and nvl(ogpr_acc.oggetto_pratica_rif_v,ogpr_acc.oggetto_pratica_rif)
                                          = ogdic.ogpr (+)
         and ogpr_acc.pratica             = prtr_acc.pratica
         and prtr_acc.pratica             = a_pratica;
    return rc;
  end;
----------------------------------------------------------------------------------
  function CANONI
  ( a_pratica                           number default -1
  , a_modello                           number default -1
  ) return sys_refcursor is
  /******************************************************************************
    NOME:        CANONI.
    DESCRIZIONE: Restituisce i canoni della pratica di accertamento CUNI e i loro
                 dati.
    RITORNA:     ref_cursor.

    Rev.  Data        Autore  Descrizione
    ----  ----------  ------  ----------------------------------------------------
    001   04/07/2024  RV      #73581
                              Aggiunto imposta_totale ed imposta_netta_totale
    000   15/03/2022  VD      Prima emissione
  ******************************************************************************/
    w_tipo_tributo                      varchar2(5);
    w_cod_fiscale                       varchar2(16);
    w_anno                              number;
    w_data_pratica                      date;
    rc                                  sys_refcursor;
  begin
    -- Selezione dati pratica
    get_dati_pratica(a_pratica,w_tipo_tributo,w_cod_fiscale,w_anno,w_data_pratica);
    --
    -- (RV - 21/02/2023) : modificato clause su valore imposta,
    --                     prende solo se > 0 oppure >= 0 se CUNI
    open rc for
    select decode(ogge.descrizione,null,'--',ogge.descrizione) as descrizione_utenza,
           decode(cotr.descrizione_ruolo,null,'--',cotr.descrizione_ruolo) as descrizione_codice,
           decode(w_tipo_tributo
                  ,'CUNI',case nvl(tari.tariffa_quota_fissa,0)
                           when 0 then ''
                         else
                           'Base ' || stampa_avvisi_cuni.f_formatta_numero(tari.tariffa_quota_fissa,'V','S') ||
                           ' - Coefficiente ' || (stampa_avvisi_cuni.f_formatta_numero(tari.tariffa,'N3','S') ||
                           decode(tari.limite
                                 ,null,''
                                 ,' fino a '||stampa_avvisi_cuni.f_formatta_numero(nvl(tari.limite,0),'N0','S') ||
                                  decode(tari.riduzione_quota_variabile,201,' gg','') ||
                                  ' poi '||stampa_avvisi_cuni.f_formatta_numero(tari.tariffa_superiore,'N3','S'))) ||
                                  ' - Riduzione ' || stampa_avvisi_cuni.f_formatta_numero(tari.perc_riduzione,'P','S') || '%'
                         end
                 , '') descrizione_tariffa,
           decode(w_tipo_tributo
                 ,'CUNI',case nvl(tari.tariffa_quota_fissa,0)
                           when 0 then ''
                         else
                           'Base ' || stampa_avvisi_cuni.f_formatta_numero(tari.tariffa_quota_fissa,'V','S') ||
                           ' - Coefficiente ' || (stampa_avvisi_cuni.f_formatta_numero(tari.tariffa,'N3','S') ||
                           decode(tari.limite
                                 ,null,''
                                 ,' fino a '||stampa_avvisi_cuni.f_formatta_numero(nvl(tari.limite,0),'N0','S') ||
                                  decode(tari.riduzione_quota_variabile,201,' gg','') ||
                                  ' poi '||stampa_avvisi_cuni.f_formatta_numero(tari.tariffa_superiore,'N3','S'))) ||
                                  ' - Maggiorazione ' || stampa_avvisi_cuni.f_formatta_numero(tari.perc_riduzione,'P','S') || '%'
                         end
                 , '') descrizione_tariffa_magg,
           decode(w_tipo_tributo
                 ,'CUNI',stampa_avvisi_cuni.f_formatta_numero(nvl(tari.tariffa_quota_fissa,0) * nvl(tari.tariffa,0) *
                                                             (100 - nvl(tari.perc_riduzione,0)) * 0.01,'V','S') ||
                         decode(tari.limite,null,'',' poi ' ||
                         stampa_avvisi_cuni.f_formatta_numero(nvl(tari.tariffa_quota_fissa,0) * nvl(tari.tariffa_superiore,0) *
                                                             (100 - nvl(tari.perc_riduzione,0)) * 0.01,'V','S'))
                 , stampa_avvisi_cuni.f_formatta_numero(tari.tariffa,'V','S')
                 ) ||
                 ' / '||decode(ogpr.tipo_occupazione,'T','Giorno','Anno') importo_tariffa,
           decode(ogpr.tipo_occupazione,'T','Giornaliera','Annuale') periodo_tariffa,
           decode(ogpr.tipo_occupazione,'T','Temporanea (' ||
                  stampa_avvisi_cuni.f_formatta_numero(nvl(ogco.data_cessazione,TO_DATE('20991231','YYYYMMDD')) -
                                                       nvl(ogco.data_decorrenza,TO_DATE('19010101','YYYYMMDD')),'N0','S') || 'gg)'
                  ,'Permanente') occupazione_tariffa,
           decode(w_tipo_tributo
                 ,'CUNI',case nvl(tari.tariffa_quota_fissa,0)
                           when 0 then ''
                         else
                           decode(cate.descrizione,null, '', cate.descrizione)
                         end
                 ,' Cat. '||cate.categoria || decode(cate.descrizione,null, '', ' - '||cate.descrizione)) dati_categoria,
           decode(ogge.cod_via
                 ,null,ogge.indirizzo_localita
                 ,arvi.denom_uff
                 ) ||
           decode(ogge.num_civ
                 ,null, ''
                 , ', ' || to_char(ogge.num_civ)
                 ) ||
           decode(ogge.suffisso
                 ,null, ''
                 , '/' || ogge.suffisso
                 ) ||
           decode(ogpr.indirizzo_occ
                 ,null, ''
                 ,' Località '|| ogpr.indirizzo_occ
                 ) ||
           decode(cmoc.denominazione
                 ,null, ''
                 ,', '|| cmoc.denominazione
                 ) ||
           decode(pvoc.sigla
                 ,null, ''
                 ,' ('||pvoc.sigla||')'
                 ) ||
           decode(ogpr.da_chilometro
                 ,null, ''
                 , ' KM ' || stampa_avvisi_cuni.f_formatta_numero(ogpr.da_chilometro,'I','S')
                 ) ||
           decode(ogpr.lato
                 ,null, ''
                 , ' Lato ' || decode(ogpr.lato,'S','SX','D','DX',ogpr.lato)
                 ) indirizzo_utenza,
           ogpr.indirizzo_occ localita_utenza,
           cmoc.denominazione comune_utenza,
           pvoc.denominazione provincia_utenza,
           decode(pvoc.sigla,null,'','('||pvoc.sigla||')') sigla_prov_utenza,
           decode(tari.descrizione
                 ,null, ''
                 , tari.descrizione) dati_tariffa,
           decode(ogpr.tipo_occupazione
                 ,'T','Dal ' || to_char(ogco.data_decorrenza, 'dd/mm/yyyy') ||
                      ' al ' || to_char(ogco.data_cessazione, 'dd/mm/yyyy')
                 ,'Annualità'
                 ) periodo_imposta,
           nvl(ltrim(decode(ogge.partita,null,'',' Part.'||trim(ogge.partita))
                     ||decode(ogge.sezione,null,'',' Sez.'||trim(ogge.sezione))
                     ||decode(ogge.foglio,null,'',' Fg.'||trim(ogge.foglio))
                     ||decode(ogge.numero,null,'',' Num.'||trim(ogge.numero))
                     ||decode(ogge.subalterno,null,'',' Sub.'||trim(ogge.subalterno))
                     ||decode(ogge.zona,null,'',' Zona '||trim(ogge.zona)))
               , '-') estremi_catastali
         , decode(ogge.categoria_catasto
                 ,null,''
                 ,'Cat.'||OGGE.categoria_catasto
                 ) categoria_catasto
         , decode(ogpr.consistenza
                 ,null,''
                 ,'mq ' || stampa_avvisi_cuni.f_formatta_numero(ogpr.consistenza,'I','S')
                 ) superficie
         , stampa_avvisi_cuni.f_formatta_numero(nvl(ogco.perc_possesso,100),'P','S') || '%' descrizione_perc_poss
         , stampa_avvisi_cuni.f_formatta_numero(tari.tariffa_quota_fissa,'I','S') base_tariffa
         , stampa_avvisi_cuni.f_formatta_numero(tari.tariffa,'N3','S') ||
           decode(tari.tariffa_superiore
                 ,null,''
                 ,'/'||stampa_avvisi_cuni.f_formatta_numero(tari.tariffa_superiore,'N3','S')) coeff_tariffa
         , case
             when NVL(tari.perc_riduzione,0) > 0
               then stampa_avvisi_cuni.f_formatta_numero(tari.perc_riduzione,'P','S') || '%'
             else '-'
           end riduz_tariffa
         , case
             when NVL(tari.perc_riduzione,0) < 0
               then stampa_avvisi_cuni.f_formatta_numero(-tari.perc_riduzione,'P','S') || '%'
             else '-'
           end magg_tariffa
         , case when nvl(ogco.perc_detrazione,0) > 0
                  then stampa_avvisi_cuni.f_formatta_numero(ogco.perc_detrazione,'P','S') || '%'
                else '-'
                end descrizione_perc_detr
         , case
             when nvl(ogco.perc_detrazione,0) < 0
               then stampa_avvisi_cuni.f_formatta_numero(-ogco.perc_detrazione,'P','S') || '%'
             else '-'
           end descrizione_perc_magg
         , nvl(ogpr.note,'-') note_tariffa
         , '' periodo_ruolo
         , stampa_avvisi_cuni.f_formatta_numero(nvl(ogim.imposta_dovuta,ogim.imposta),'I','S') imposta
         , stampa_avvisi_cuni.f_formatta_numero(ogim.imposta,'I','S') imposta_netta
         , ogpr.oggetto_pratica
         , ogim.oggetto_imposta
         , ogpr.oggetto
         , cate.flag_domestica
         , to_char(ogco.inizio_occupazione, 'dd/mm/yyyy') as inizio_occ
         , to_char(ogco.fine_occupazione, 'dd/mm/yyyy') as fine_occ
         , to_char(ogpr.inizio_concessione, 'dd/mm/yyyy') as inizio_conc
         , to_char(ogpr.fine_concessione, 'dd/mm/yyyy') as fine_conc
         , ogpr.num_concessione as conc_numero
         , to_char(ogpr.data_concessione, 'dd/mm/yyyy') as conc_data
         , case when (ogpr.inizio_concessione is not null) or (ogpr.fine_concessione is not null) or
                     (ogpr.num_concessione is not null) or (ogpr.data_concessione is not null)
           then 'Concessione'
                ||decode(ogpr.inizio_concessione,null,'',' dal '||to_char(ogpr.inizio_concessione,'dd/mm/yyyy'))
                ||decode(ogpr.fine_concessione,null,'',' al '||to_char(ogpr.fine_concessione,'dd/mm/yyyy'))
                ||decode(ogpr.num_concessione,null,'',' numero '||to_char(ogpr.num_concessione))
                ||decode(ogpr.data_concessione,null,'',' del '||to_char(ogpr.data_concessione,'dd/mm/yyyy'))
           else '' end dett_conc
         , ogpr.larghezza as larghezza
         , ogpr.profondita as profondita
         , ogpr.consistenza_reale as mq_reali
         , ogpr.quantita as quantita
         , ogpr.consistenza mq
         , case when (ogpr.larghezza is not null) or (ogpr.profondita is not null) or
                     (ogpr.consistenza_reale is not null) or (ogpr.quantita is not null)
           then decode(ogpr.larghezza,null,'',decode(cotr.tipo_tributo_prec,'ICP',' L ',' larghezza ')||to_char(ogpr.larghezza)||'m')
                ||decode(ogpr.profondita,null,'',decode(cotr.tipo_tributo_prec,'ICP',' H ',' profondità ')||to_char(ogpr.profondita)||'m')
                ||decode(ogpr.consistenza_reale,null,'',' superficie '||to_char(ogpr.consistenza_reale)||'mq')
                ||decode(ogpr.quantita,null,'',' quantità '||to_char(ogpr.quantita))
           else '' end dett_cons
         , stampa_avvisi_cuni.f_formatta_numero(sum(nvl(ogim.imposta_dovuta,nvl(ogim.imposta,0))) over(),'I','S') imposta_totale
         , stampa_avvisi_cuni.f_formatta_numero(sum(nvl(ogim.imposta,0)) over(),'I','S') imposta_netta_totale
         , a_modello modello
     from oggetti_imposta ogim,
          oggetti_pratica ogpr,
          oggetti_contribuente ogco,
          pratiche_tributo prtr,
          oggetti ogge,
          codici_tributo cotr,
          categorie cate,
          tariffe tari,
          archivio_vie arvi,
          ad4_comuni cmoc,
          ad4_provincie pvoc
    where prtr.pratica         = a_pratica
      and ogim.anno            = prtr.anno
      and ogim.tipo_tributo    = prtr.tipo_tributo
      and ogim.cod_fiscale     = prtr.cod_fiscale
      and ogpr.oggetto_pratica = ogim.oggetto_pratica
      and ogco.oggetto_pratica = ogim.oggetto_pratica
      and ogco.cod_fiscale     = ogim.cod_fiscale
      and prtr.cod_fiscale     = ogim.cod_fiscale
      and prtr.pratica         = ogpr.pratica
      and cotr.tributo         = ogpr.tributo
      and cate.tributo         = ogpr.tributo
      and cate.categoria       = ogpr.categoria
      and tari.anno            = ogim.anno
      and tari.tributo         = ogpr.tributo
      and tari.categoria       = ogpr.categoria
      and tari.tipo_tariffa    = ogpr.tipo_tariffa
      and ogge.oggetto         = ogpr.oggetto
      and arvi.cod_via (+)     = ogge.cod_via
      and cmoc.provincia_stato = pvoc.provincia (+)
      and ogpr.cod_pro_occ     = cmoc.provincia_stato (+)
      and ogpr.cod_com_occ     = cmoc.comune (+)
      and ((ogim.imposta > 0) or
           ((ogim.imposta = 0) and (prtr.tipo_tributo = 'CUNI'))
          )
  order by
      pvoc.denominazione,
      cmoc.denominazione,
      decode(ogge.cod_via,null,ogge.indirizzo_localita
                     ,arvi.denom_uff
                     || decode(ogge.num_civ, null, '', ', ' || ogge.num_civ)
                     || decode(ogge.suffisso, null, '', '/' || ogge.suffisso))
    , ogim.imposta desc
    ;
  --
  return rc;
  end canoni;
----------------------------------------------------------------------------------
  function VERSAMENTI
  ( a_pratica                           number default -1
  , a_modello                           number default -1
  ) return sys_refcursor is
  /******************************************************************************
    NOME:        VERSAMENTI.
    DESCRIZIONE: Restituisce i versamenti dell'anno per il contribuente.
    RITORNA:     ref_cursor.
    NOTE:
  ******************************************************************************/
    w_tipo_tributo                      varchar2(5);
    w_cod_fiscale                       varchar2(16);
    w_anno                              number;
    w_data_pratica                      date;
    rc                                  sys_refcursor;
  begin
    -- Selezione dati pratica
    get_dati_pratica(a_pratica,w_tipo_tributo,w_cod_fiscale,w_anno,w_data_pratica);
    --
    open rc for
      select vers.*
           , stampa_common.f_formatta_numero(sum(vers.importo_versato) over(),'I','S') st_totale_versato
           , decode(sum(decode(l_vers_ravv,'RAVVED.*',1,0)) over()
                    ,0,''
                   ,f_descrizione_timp(a_modello,'NOTE_VERS_RAVV')
                   ) l_nota_vers_ravv
           , decode(w_tipo_tributo
                   ,'TOSAP',rtrim(f_descrizione_timp(a_modello,'DET_VER_OGIM'))
                   ,null) l_dett_versamenti_ogim
           , decode(w_tipo_tributo
                   ,'TOSAP',f_descrizione_timp(a_modello,'DIFFERENZA')
                   ,null) l_differenza_imposta
           , decode(w_tipo_tributo
                   ,'TOSAP',f_descrizione_timp(a_modello,'TOT_DETT_VERS')
                   ,null) l_totale_dett_versamenti
           , decode(w_tipo_tributo
                   ,'TOSAP',f_descrizione_timp(a_modello,'TOT_IMP')
                   ,null) l_totale_imposta
           , decode(w_tipo_tributo
                   ,'TOSAP',f_descrizione_timp(a_modello,'TOT_VERS_RIEP')
                   ,null) l_totale_versamenti
           , decode(w_tipo_tributo
                   ,'TOSAP',rtrim(f_descrizione_timp(a_modello,'RIEP_DETT_OGIM'))
                   ,null) l_riepilogo
        from
     (select to_char(vers.rata,99) st_rata
           , to_char(vers.data_pagamento,'dd/mm/yyyy') data_versamento
           , to_char(scad.data_scadenza,'dd/mm/yyyy')  data_scadenza
           , vers.importo_versato
           , stampa_common.f_formatta_numero(vers.importo_versato,'I','S') st_importo_versato
           , null l_vers_ravv
        from versamenti       vers
           , scadenze         scad
       where vers.cod_fiscale           = w_cod_fiscale
         and vers.anno                  = w_anno
         and vers.tipo_tributo          = w_tipo_tributo
         and vers.data_pagamento       <= w_data_pratica
         and (vers.pratica               is null or
             (vers.pratica               <> a_pratica
              and exists (select 'x'
                            from pratiche_tributo prtr
                               , oggetti_pratica  ogpr
                           where prtr.pratica          = vers.pratica
                             and prtr.tipo_pratica     = 'D'
                             and prtr.anno             = w_anno
                             and prtr.pratica          = ogpr.pratica
                             and ogpr.tipo_occupazione = 'P'
                         )))
         and vers.anno                  = scad.anno (+)
         and vers.rata                  = scad.rata (+)
         and vers.tipo_tributo          = scad.tipo_tributo (+)
       union
      select to_char(vers.rata,99) st_rata
           , to_char(vers.data_pagamento,'dd/mm/yyyy') data_versamento
           , null data_scadenza
           , f_importo_vers_ravv(w_cod_fiscale
                                ,w_tipo_tributo
                                ,w_anno
                                ,to_char(vers.rata)
                                ) importo_versato
           , stampa_common.f_formatta_numero(f_importo_vers_ravv(w_cod_fiscale
                                                                ,w_tipo_tributo
                                                                ,w_anno
                                                                ,to_char(vers.rata)
                                                                )
                                            ,'I','S'
                                            ) st_importo_versato
           , 'RAVVED.*'
        from versamenti vers
           , pratiche_tributo prtr
       where vers.cod_fiscale     = w_cod_fiscale
         and vers.anno            = w_anno
         and vers.tipo_tributo    = w_tipo_tributo
         and vers.data_pagamento <= w_data_pratica
         and vers.pratica         = prtr.pratica
         and prtr.tipo_pratica    = 'V'
         and prtr.numero is not null
         and nvl(prtr.stato_accertamento, 'D') = 'D'
         and f_importo_vers_ravv(w_cod_fiscale
                                ,w_tipo_tributo
                                ,w_anno
                                ,to_char(vers.rata)
                                ) > 0
       order by 1,2) vers;
  return rc;
  end;
----------------------------------------------------------------------------------
  function IMPOSTA_EVASA
  ( a_pratica                           number default -1
  , a_modello                           number default -1
  ) return sys_refcursor is
  /******************************************************************************
    NOME:        IMPOSTA_EVASA.
    DESCRIZIONE: Restituisce le sanzioni relative all'imposta evasa.
    RITORNA:     ref_cursor.
    NOTE:
  ******************************************************************************/
    rc                                  sys_refcursor;
  begin
    open rc for
      select sanzioni.descrizione descrizione
           , stampa_common.f_formatta_numero(sapr.importo,'I','S')     st_importo_sanz
           , stampa_common.f_formatta_numero(sapr.percentuale,'P','N') st_perc_sanzione
           , stampa_common.f_formatta_numero(sapr.riduzione,'P','N')   st_perc_riduzione
        from sanzioni_pratica sapr
           , sanzioni
           , pratiche_tributo prtr_acc
       where prtr_acc.pratica = a_pratica
         and prtr_acc.tipo_tributo = sanzioni.tipo_tributo
         and sapr.pratica = prtr_acc.pratica
         and sanzioni.cod_sanzione = sapr.cod_sanzione
         and sanzioni.sequenza = sapr.sequenza_sanz
         and sanzioni.flag_imposta = 'S'
         and sanzioni.tipo_causale = 'E'
       union
      select 'TOTALE' descrizione
           , stampa_common.f_formatta_numero(sum(sapr.importo),'I','S') st_importo_sanz
           , null                                                       st_perc_sanzione
           , null                                                       st_perc_riduzione
        from sanzioni_pratica sapr
           , sanzioni
           , pratiche_tributo prtr_acc
       where prtr_acc.pratica = a_pratica
         and prtr_acc.tipo_tributo = sanzioni.tipo_tributo
         and sapr.pratica = prtr_acc.pratica
         and sanzioni.cod_sanzione = sapr.cod_sanzione
         and sanzioni.sequenza = sapr.sequenza_sanz         
         and sanzioni.flag_imposta = 'S'
         and sanzioni.tipo_causale = 'E'
        order by 1;
    return rc;
  end;
----------------------------------------------------------------------------------
  function SANZIONI_INTERESSI
  ( a_pratica                           number default -1
  , a_modello                           number default -1
  ) return sys_refcursor is
  /******************************************************************************
    NOME:        SANZIONI_INTERESSI.
    DESCRIZIONE: Restituisce le sanzioni per omesso/parziale versamento e gli
                 eventuali interessi.
    RITORNA:     ref_cursor.
    NOTE:
  ******************************************************************************/
    rc                                  sys_refcursor;
  begin
    open rc for
      select sapr.cod_sanzione
           , sanz.descrizione                                          descr_sanzione
           , nvl(sapr.importo,0)                                       importo
           , stampa_common.f_formatta_numero(sapr.percentuale,'P','N') st_perc_sanzione
           , stampa_common.f_formatta_numero(sapr.riduzione,'P','N')   st_perc_riduzione
           , to_char(nvl(sapr.giorni,sapr.semestri),'9999')            giorni_semestri
           , stampa_common.f_formatta_numero(sapr.importo,'I','S')     st_importo
           , cf24.tributo_f24                                          codice_f24
           , cf24.descrizione                                          descr_codice_f24
           , rtrim(f_descrizione_timp(a_modello,'IRR_SANZ_INT'))       l_irrogazioni_sanz_int
        from sanzioni_pratica sapr
           , sanzioni         sanz
           , codici_f24       cf24
       where sapr.pratica                = a_pratica
         and sapr.cod_sanzione           = sanz.cod_sanzione
         and sapr.sequenza_sanz          = sanz.sequenza        
         and sapr.tipo_tributo           = sanz.tipo_tributo
         --and sapr.cod_sanzione not in (888, 889, 891, 892, 893, 894)
         and sanz.tipo_causale          != 'E'
         and nvl(sanz.flag_imposta,'N') != 'S'
         and sanz.cod_tributo_f24        = cf24.tributo_f24 (+)
       union
      select 9999                                                       cod_sanzione
           , 'TOTALE'                                                   descr_sanzione
           , sum(sapr.importo)                                          importo
           , null                                                       st_perc_sanzione
           , null                                                       st_perc_riduzione
           , null                                                       giorni_semestri
           , stampa_common.f_formatta_numero(sum(sapr.importo),'I','S') st_importo
           , null                                                       codice_f24
           , null                                                       descr_codice_f24
           , rtrim(f_descrizione_timp(a_modello,'IRR_SANZ_INT'))        l_irrogazioni_sanz_int
        from sanzioni_pratica sapr
           , sanzioni         sanz
       where sapr.pratica                = a_pratica
         and sapr.cod_sanzione           = sanz.cod_sanzione
         and sapr.sequenza_sanz          = sanz.sequenza
         and sapr.tipo_tributo           = sanz.tipo_tributo
         --and sapr.cod_sanzione not in (888, 889, 891, 892, 893, 894)
         and sanz.tipo_causale          != 'E'
         and nvl(sanz.flag_imposta,'N') != 'S'
       order by 1;
    return rc;
  end;
----------------------------------------------------------------------------------
  function RIEPILOGO_F24
  ( a_pratica                           number default -1
  , a_modello                           number default -1
  ) return sys_refcursor is
  /******************************************************************************
    NOME:        RIEPILOGO_F24.
    DESCRIZIONE: Restituisce tutte le sanzioni riepilogate per codice tributo F24.
    RITORNA:     ref_cursor.
    NOTE:
  ******************************************************************************/
    w_tipo_tributo                      varchar2(5);
    w_cod_fiscale                       varchar2(16);
    w_anno                              number;
    w_data_pratica                      date;
    rc                                  sys_refcursor;
  begin
    -- Selezione dati pratica
    get_dati_pratica(a_pratica,w_tipo_tributo,w_cod_fiscale,w_anno,w_data_pratica);
    --
    open rc for
      select cf24.tributo_f24                                           codice_f24
           , cf24.descrizione                                           descr_codice_f24
           , sum(sapr.importo)                                          importo
           , stampa_common.f_formatta_numero(sum(sapr.importo),'I','S') st_importo
        from sanzioni_pratica sapr
           , sanzioni         sanz
           , codici_f24       cf24
       where sapr.pratica                = a_pratica
         and sapr.cod_sanzione            = sanz.cod_sanzione
         and sapr.sequenza_sanz            = sanz.sequenza
         and sapr.tipo_tributo            = sanz.tipo_tributo
         --and sapr.cod_sanzione not in (888, 889, 891, 892, 893, 894)
         and sanz.cod_tributo_f24        = cf24.tributo_f24 (+)
         and cf24.descrizione_titr(+)    = f_descrizione_titr(w_tipo_tributo,w_anno)
       group by cf24.tributo_f24
              , cf24.descrizione
       union
      select 'ZZZZ'                                                     cod_sanzione
           , 'TOTALE'                                                   descr_sanzione
           , sum(sapr.importo)                                          importo
           , stampa_common.f_formatta_numero(sum(sapr.importo),'I','S') st_importo
        from sanzioni_pratica sapr
           , sanzioni         sanz
       where sapr.pratica                = a_pratica
         and sapr.cod_sanzione           = sanz.cod_sanzione
         and sapr.sequenza_sanz            = sanz.sequenza
         and sapr.tipo_tributo            = sanz.tipo_tributo
         --and sapr.cod_sanzione not in (888, 889, 891, 892, 893, 894)
       order by 1;
    return rc;
  end;
----------------------------------------------------------------------------------
  function aggi_dilazioni
  ( a_pratica                                   number default -1
  , a_modello                                   number default -1
  ) return sys_refcursor is
    rc         sys_refcursor;
  begin
    open rc for
    select stampa_common.f_formatta_numero(prtr.importo_totale,'I','S') st_importo_totale
         , stampa_common.f_formatta_numero(prtr.importo_ridotto,'I','S') st_importo_ridotto
         , stampa_common.f_formatta_numero(aggi_60.aliquota,'P','S') st_aliquota_60
         , stampa_common.f_formatta_numero(least(round(prtr.importo_totale * aggi_60.aliquota / 100,2)
                                               ,aggi_60.importo_massimo),'I','S') st_aggio_60
         , stampa_common.f_formatta_numero(prtr.importo_totale +
                                           (least(round(prtr.importo_totale * aggi_60.aliquota / 100,2)
                                               ,aggi_60.importo_massimo))
        ,'I','S'
        ) st_importo_da_versare_60
         , stampa_common.f_formatta_numero(aggi_120.aliquota,'P','S') st_aliquota_120
         , stampa_common.f_formatta_numero(least(round(prtr.importo_totale * aggi_120.aliquota / 100,2)
                                               ,aggi_120.importo_massimo),'I','S') st_aggio_120
         , stampa_common.f_formatta_numero(prtr.importo_totale +
                                           (least(round(prtr.importo_totale * aggi_120.aliquota / 100,2)
                                               ,aggi_120.importo_massimo))
        ,'I','S'
        ) st_importo_da_versare_120
         , stampa_common.f_formatta_numero(inte.aliquota,'P','S') st_aliquota_interessi
         , round(prtr.imposta_totale * inte.aliquota / 36500,6) st_interesse_giornaliero
         , (select stampa_common.f_formatta_numero(sum(sapr.importo),'I') importo
            from sanzioni_pratica sapr, sanzioni sanz
            where sapr.pratica = a_pratica
              and sapr.tipo_tributo = sanz.tipo_tributo
              and sapr.cod_sanzione = sanz.cod_sanzione
              and sapr.sequenza_sanz = sanz.sequenza              
              and sanz.flag_imposta = 'S'
              and nvl(sanz.tipo_causale, 'X') = 'E') st_differenza_imposta
    from pratiche_tributo prtr
       , aggi aggi_60
       , aggi aggi_120
       , interessi inte
    where prtr.pratica = a_pratica
      and prtr.tipo_tributo = aggi_60.tipo_tributo
      and aggi_60.aliquota > 0
      and aggi_60.giorno_inizio < 90
      and prtr.tipo_tributo = aggi_120.tipo_tributo
      and aggi_120.aliquota > 0
      and aggi_120.giorno_inizio > 90
      and inte.tipo_tributo = prtr.tipo_tributo
      and inte.tipo_interesse = 'D'
      and prtr.data between inte.data_inizio
        and inte.data_fine
    ;
    return rc;
  end;
------------------------------------------------------------------
  function interessi_dettaglio
  ( a_pratica               number default -1
  , a_modello               number default -1
  ) return sys_refcursor is
  /******************************************************************************
    NOME:        INTERESSI_DETTAGLIO
    DESCRIZIONE: Restituisce un ref_cursor contenente il dettaglio degli interessi
    RITORNA:     ref_cursor.
    NOTE:
    Rev.  Data        Autore  Descrizione
    ----  ----------  ------  ----------------------------------------------------
    000   14/06/2024  RV      #55525
                              Versione iniziale
  ******************************************************************************/
    rc sys_refcursor;
  begin
    rc := stampa_common.interessi(a_pratica);
    return rc;
  end;
------------------------------------------------------------------
  function eredi
  ( a_ni_deceduto           number default -1
  , a_ni_erede_da_escludere number default -1
  ) return sys_refcursor is
    rc         sys_refcursor;
  begin
    rc := stampa_common.eredi(a_ni_deceduto,a_ni_erede_da_escludere);
    return rc;
  end;
end STAMPA_ACCERTAMENTI_TRMI;
/
