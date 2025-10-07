--liquibase formatted sql 
--changeset abrandolini:20250326_152429_stampa_accertamenti_ici stripComments:false runOnChange:true 
 
create or replace package STAMPA_ACCERTAMENTI_ICI is
/******************************************************************************
 NOME:        STAMPA_ACCERTAMENTI_ICI
 DESCRIZIONE: Funzione per stampa avvisi di accertamento ICI/IMU
 ANNOTAZIONI: -
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 000   19/12/2022  RV      #60432
                           Emissione iniziale partendo da base STAMPA_ACCERTAMENTI_TARSU
 001   04/01/2023  RV      Prima revisione, depurato suoperfluo e sistemato query per ICI/IMU
 002   11/01/2023  RV      Seconda revisione, per solo TIPO_EVENTO = 'U'
 003   14/02/2023  RV      Scomposizione F24 3924/3918
 004   05/05/2023  RV      #61153
                           Integrazioni per Infedele, aggiunto aggi e dilazioni
 005   16/11/2023  RV      #61153
                           Integrazioni per Infedele, aggiunto dati liquidazione
 006   20/11/2023  RV      #65966
                           Aggiunto gestione sanzione minima su riduzione
 007   14/06/2024  RV      #55525
                           Aggiunto INTERESSI_DETTAGLIO
 008   11/12/2024  AB      #76942
                           Nuovo regime sanzionatorio
 009   17/12/2024  RV      #76026
                           Rivisto MAN_IMMOBILI x Valore e Rendita OGPR
 010   06/02/2025  RV      #77116
                           Flag sanz_min_rid da pratica non da inpa
*****************************************************************************/

  function man_contribuente
  ( a_pratica              number default -1
  , a_ni_erede             number default -1
  ) return sys_refcursor;

  function man_principale
  ( a_cf                   varchar2 default ''
  , a_prat                 number default -1
  , a_modello              number default -1
  , a_ni_erede             number default -1
  ) return sys_refcursor;

  function man_immobili
  ( a_cf                   varchar2 default ''
  , a_pratica              number default -1
  , a_tipi_oggetto         varchar2 default ''
  , a_modello              number default -1
  ) return sys_refcursor;

  function man_versamenti
  ( a_cf                   varchar2 default ''
  , a_pratica              number default -1
  , a_modello              number default -1
  ) return sys_refcursor;

  function man_versamenti_vuoto
  ( a_cf                   varchar2 default ''
  , a_pratica              number default -1
  , a_anno                 number default -1
  , a_modello              number default -1
  ) return sys_refcursor;

  function man_acc_imposta
  ( a_prat                 number default -1
  , a_modello              number default -1
  ) return sys_refcursor;

  function man_sanz_int
  ( a_prat                 number default -1
  , a_modello              number default -1
  ) return sys_refcursor;

  function man_riep_vers
  ( a_prat                 number default -1
  , a_modello              number default -1
  ) return sys_refcursor;

  function man_aggi_dilazione
  ( a_pratica              number default -1
  , a_modello              number default -1
  ) return sys_refcursor;

  function f_get_cod_tributo_f24
  ( a_oggetto_imposta      number
  , a_destinatario         varchar2
  ) return varchar2;

  function interessi_dettaglio
  ( a_pratica number default -1
  , a_modello              number default -1
  ) return sys_refcursor;

  function eredi
  ( a_ni_deceduto           number default -1
  , a_ni_erede_da_escludere number default -1
  ) return sys_refcursor;

end STAMPA_ACCERTAMENTI_ICI;
/
create or replace package body STAMPA_ACCERTAMENTI_ICI is
/******************************************************************************
 NOME:        STAMPA_ACCERTAMENTI_ICI
 DESCRIZIONE: Funzione per stampa avvisi di accertamento ICI/IMU
 ANNOTAZIONI: -
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 000   19/12/2022  RV      #60432
                           Emissione iniziale partendo da base STAMPA_ACCERTAMENTI_TARSU
 001   04/01/2023  RV      Prima revisione, depurato suoperfluo e sistemato query per ICI/IMU
 002   11/01/2023  RV      Seconda revisione, per solo TIPO_EVENTO = 'U'
 003   14/02/2023  RV      Scomposizione F24 3924/3918
 004   05/05/2023  RV      #61153
                           Integrazioni per Infedele, aggiunto aggi e dilazioni
 005   16/11/2023  RV      #61153
                           Integrazioni per Infedele, aggiunto dati liquidazione
 006   20/11/2023  RV      #65966
                           Aggiunto gestione sanzione minima su riduzione
 007   14/06/2024  RV      #55525
                           Aggiunto INTERESSI_DETTAGLIO
 008   11/12/2024  AB      #76942
                           Nuovo regime sanzionatorio
 009   17/12/2024  RV      #76026
                           Rivisto MAN_IMMOBILI x Valore e Rendita OGPR
 010   06/02/2025  RV      #77116
                           Flag sanz_min_rid da pratica non da inpa
******************************************************************************/

-----------------------------------------------------------------------------------------
-- FUNZIONI PER STAMPA AVVISO DI ACCERTAMENTO MANUALE (TIPO_EVENTO = 'U')
-----------------------------------------------------------------------------------------
  function man_contribuente
  ( a_pratica                           number
  , a_ni_erede             number default -1
  ) return sys_refcursor is
    rc sys_refcursor;
  begin
    rc := stampa_common.contribuente(a_pratica, a_ni_erede);
    return rc;
  end;

  function man_principale
  ( a_cf                                varchar2
  , a_prat                              number
  , a_modello                           number
  , a_ni_erede                          number default -1
  ) return sys_refcursor is

    rc                                  sys_refcursor;
    v_rc                                sys_refcursor;

    v_acc_imposta_importo_tot           varchar2(20);
    v_sanz_int_importo_tot              varchar2(20);
    v_sanz_int_importo_tot_arr          varchar2(20);
    v_importo_vers_tot                  varchar2(20);
    v_importo_vers_rid                  varchar2(20);

    v_imposta_acconto_tot               varchar2(20);
    v_imposta_saldo_tot                 varchar2(20);
    v_imposta_tot                       varchar2(20);
    v_versato_ogg_tot                   varchar2(20);
    v_importo_diff_tot                  varchar2(20);

    v_importo_tot                       number(15, 2);
    v_importo_rid                       number(15, 2);

    type t_acc_cols is record
    ( cod_sanzione                      number(4),
      sanz_ord1                         varchar2(50),
      sanz_ord                          varchar2(50),
      ord                               number(5),
      perc_sanzione                     varchar2(10),
      perc_riduzione                    varchar2(10),
      giorni_semestri                   varchar2(5),
      importo_sanzione                  varchar2(20),
      cod_tributo_f24                   varchar2(4),
      descrizione                       varchar2(100),
      accertamento_imposta              varchar2(100),
      st_importo_tot                    varchar2(20)
    );
    v_acc_cols t_acc_cols;

    type t_sanz_cols is record
    ( cod_sanzione                      number(4),
      perc_sanzione                     varchar2(10),
      perc_riduzione                    varchar2(10),
      giorni_semestri                   varchar2(5),
      importo_sanzione                  varchar2(20),
      cod_tributo_f24                   varchar2(4),
      descrizione                       varchar2(100),
      irrogazioni_sanz_int              varchar2(100),
      st_importo_tot                    varchar2(20),
      st_importo_tot_arr                varchar2(20)
    );
    v_sanz_cols t_sanz_cols;

    type t_riep_vers is record
    ( cod_tributo                      number(4),
      descr_tributo                    varchar2(100),
      importo                          varchar2(14),
      imp_ridotto                      varchar2(14),
      importo_non_st                   number(10, 2),
      importo_ridotto_non_st           number(10, 2),
      f24_intestazione                 varchar2(100),
      f24_totale                       varchar2(100),
      st_importo_vers_tot              varchar2(14),
      st_importo_vers_rid              varchar2(14),
      importo_vers_tot                 number(15, 2),
      importo_vers_rid                 number(15, 2)
    );
    v_riep_vers t_riep_vers;

    type t_immobili is record
    (
      importo1_acconto                   varchar2(14),
      importo1_saldo                     varchar2(14),
      importo2_acconto                   varchar2(14),
      importo2_saldo                     varchar2(14),
      importo1_acconto_tot               varchar2(14),
      importo1_saldo_tot                 varchar2(14),
      importo1_tot                       varchar2(14),
      importo_versato                    varchar2(14),
      importo_versato_tot                varchar2(14),
      importo1_differenza_tot            varchar2(14),
      pratica                            number,
      importo1_num                       number(10, 2),
      importo1_acconto_num               number(10, 2),
      importo2_num                       number(10, 2),
      importo2_acconto_num               number(10, 2),
      importo1_tot_num                   number(10, 2),
      importo1_acconto_tot_num           number(10, 2),
      importo_versato_num                number(10, 2),
      importo_versato_tot_num            number(10, 2),
      codice_f24                         varchar2(14),
      oggetto_pratica                    number,
      num_ordine                         number,
      costi_storici                      varchar2(100),
      aliquota                           varchar2(100),
      st_tial                            varchar2(100),
      st_aliquota_std                    varchar2(100),
      oggetto                            number,
      descr_tiog                         varchar2(100),
      tipo_oggetto                       varchar2(10),
      indirizzo_ok                       varchar2(2000),
      cat                                varchar2(10),
      classe                             varchar2(10),
      partita                            varchar2(20),
      sezione                            varchar2(10),
      foglio                             varchar2(10),
      numero                             varchar2(10),
      subalterno                         varchar2(10),
      zona                               varchar2(10),
      prot_cat                           varchar2(100),
      anno_cat                           varchar2(100),
      st_valore_riv                      varchar2(100),
      valore_riv                         varchar2(100),
      rendita_valore_riv                 varchar2(100),
      st_pre_riog                        varchar2(100),
      st_valore_subase                   varchar2(100),
      valore_subase                      varchar2(100),
      rendita_valore_subase              varchar2(100),
      valore_ogpr                        varchar2(100),
      rendita_valore_ogpr                varchar2(100),
      perc_poss                          varchar2(10),
      mp                                 varchar2(4),
      mip                                varchar2(4),
      mp1s                               varchar2(4),
      mr                                 varchar2(4),
      me                                 varchar2(4),
      mar                                varchar2(4),
      fp                                 varchar2(4),
      fe                                 varchar2(4),
      fr                                 varchar2(4),
      fap                                varchar2(4),
      fpr                                varchar2(4),
      fc                                 varchar2(4),
      detr                               varchar2(100),
      detrazione                         varchar2(100),
      anno                               varchar2(10),
      st_percposs                        varchar2(100),
      st_mesposs                         varchar2(100),
      st_mesrid                          varchar2(100),
      st_mesescl                         varchar2(100),
      st_catren                          varchar2(100),
      cat_ren                            varchar2(10),
      --
      imposta_testo1                     varchar2(100),
      imposta_subtesto1                  varchar2(100),
      linea_importo1                     varchar2(100),
      importo1                           varchar2(100),
      --
      imposta_testo2                     varchar2(100),
      imposta_subtesto2                 varchar2(100),
      importo2                           varchar2(100),
      linea_importo2                     varchar2(100),
      --
      st_mini_imu                        varchar2(100),
      --
      note                               varchar2(2000),
      tipo_rapporto                      varchar2(100),
      --
      cat_acc                            varchar2(10),
      --
      st_valdic                          varchar2(100),
      st_catdic                          varchar2(100),
      detr_dic                           varchar2(100),
      --
      valore_dic                         varchar2(20),
      detrazione_dic                     varchar2(20),
      cat_dic                            varchar2(10),
      tipo_oggetto_dic                   varchar2(10),
      perc_dic                           varchar2(10),
      mp_dic                             varchar2(4),
      mip_dic                            varchar2(4),
      mp1s_dic                           varchar2(4),
      mr_dic                             varchar2(4),
      me_dic                             varchar2(4),
      mar_dic                            varchar2(4),
      fp_dic                             varchar2(2),
      fe_dic                             varchar2(2),
      fr_dic                             varchar2(2),
      fap_dic                            varchar2(2),
      fpr_dic                            varchar2(2),
      fc_dic                             varchar2(2),
      rendita_dic                        varchar2(20),
      imposta_dic                        varchar2(20),
      imposta_acc_dic                    varchar2(20),
      imposta_sal_dic                    varchar2(20),
      versato_dic                        varchar2(20),
      tipo_aliquota_dic                  varchar2(10),
      aliquota_dic                       varchar2(10),
      des_aliquota_dic                   varchar2(100),
      note_dic                           varchar2(2000),
      --
      valore_liq                         varchar2(20),
      detrazione_liq                     varchar2(20),
      cat_liq                            varchar2(10),
      tipo_oggetto_liq                   varchar2(10),
      perc_liq                           varchar2(10),
      mp_liq                             varchar2(4),
      mip_liq                            varchar2(4),
      mp1s_liq                           varchar2(4),
      mr_liq                             varchar2(4),
      me_liq                             varchar2(4),
      mar_liq                            varchar2(4),
      fp_liq                             varchar2(2),
      fe_liq                             varchar2(2),
      fr_liq                             varchar2(2),
      fap_liq                            varchar2(2),
      fpr_liq                            varchar2(2),
      fc_liq                             varchar2(2),
      rendita_liq                        varchar2(20),
      imposta_liq                        varchar2(20),
      imposta_acc_liq                    varchar2(20),
      imposta_sal_liq                    varchar2(20),
      versato_liq                        varchar2(20),
      tipo_aliquota_liq                  varchar2(10),
      aliquota_liq                       varchar2(10),
      des_aliquota_liq                   varchar2(100),
      note_liq                           varchar2(2000),
      --
      modello                            number
    );
    v_immobili t_immobili;

  begin
    v_rc := man_acc_imposta(a_prat, a_modello);
    loop
      fetch v_rc
        into v_acc_cols;
      exit when v_rc%notfound;
      v_acc_imposta_importo_tot := v_acc_cols.st_importo_tot;
      exit;
    end loop;

    v_rc := man_sanz_int(a_prat, a_modello);
    loop
      fetch v_rc
        into v_sanz_cols;
      exit when v_rc%notfound;
      v_sanz_int_importo_tot := v_sanz_cols.st_importo_tot;
      v_sanz_int_importo_tot_arr := v_sanz_cols.st_importo_tot_arr;
      exit;
    end loop;

    v_importo_tot := 0;
    v_importo_rid := 0;
    v_importo_vers_tot := null;
    v_importo_vers_rid := null;
    v_rc := man_riep_vers(a_prat, a_modello);
    loop
      fetch v_rc
        into v_riep_vers;
      exit when v_rc%notfound;
      v_importo_vers_tot := v_riep_vers.st_importo_vers_tot;
      v_importo_vers_rid := v_riep_vers.st_importo_vers_rid;
      v_importo_tot := v_riep_vers.importo_vers_tot;
      v_importo_rid := v_riep_vers.importo_vers_rid;
      exit;
    end loop;

    v_imposta_acconto_tot := '';
    v_imposta_saldo_tot := '';
    v_imposta_tot := '';
    v_importo_diff_tot := '';
    -- 2023/01/31 (RV) - Richiesto che sia sempre compilato anche se nullo o zero
    v_versato_ogg_tot := '0.00';
    v_rc := man_immobili(a_cf, a_prat, null, a_modello);
    loop
      fetch v_rc
        into v_immobili;
      exit when v_rc%notfound;
      v_imposta_acconto_tot := v_immobili.importo1_acconto_tot;
      v_imposta_saldo_tot := v_immobili.importo1_saldo_tot;
      v_imposta_tot := v_immobili.importo1_tot;
      v_importo_diff_tot := v_immobili.importo1_differenza_tot;
      v_versato_ogg_tot := v_immobili.importo_versato_tot;
      exit;
    end loop;
    --
    open rc for
    select '(Identificativo Operazione ACCU' || prtr_acc.anno ||
           lpad(prtr_acc.pratica, 10, '0') || ')' as id_operazione_char
         , 'ACCU' || prtr_acc.anno ||
           lpad(prtr_acc.pratica, 10, '0') as id_operazione
         , a_modello modello
         , a_cf cod_fiscale
         , prtr_acc.pratica pratica
         , translate (prtr_acc.motivo, chr (013) || chr (010), '  ') motivo
         , lpad(prtr_acc.anno, 4) anno
         , lpad(nvl (prtr_acc.numero, ' '), 15, '0') prtr_numero
         , nvl(prtr_acc.numero, ' ') prtr_numero_vis
         , prtr_acc.anno prtr_anno
         , nvl(to_char (prtr_acc.data, 'dd/mm/yyyy'), ' ') data
         , decode(rtrim (f_descrizione_timp (a_modello, 'INTE'))
                 -- (VD - 21/02/2022): in caso di stampa da TributiWeb si stampa sempre "Atto"
             --  ,'DEFAULT',f_tipo_accertamento(ogpr_acc.oggetto_pratica)
                 ,'DEFAULT','ATTO'
                 ,rtrim(f_descrizione_timp(a_modello, 'INTE'))
                 ) tipo_acc
         , stampa_common.f_formatta_numero(f_round(prtr_acc.importo_totale
                                                  ,1
                                                  )
                                          ,'I','S'
                                          ) importo_totale
         , decode(f_descrizione_timp(a_modello, 'VIS_TOT_ARR')
                 ,'SI',v_importo_vers_tot
                 ,null
                 ) importo_totale_arrotondato
         , decode(prtr_acc.importo_ridotto
                 ,prtr_acc.importo_totale, null
                 ,stampa_common.f_formatta_numero(f_round(prtr_acc.importo_ridotto
                                                         ,1
                                                         )
                                                 ,'I','S'
                                                 )
                 ) importo_ridotto
         , decode(f_descrizione_timp(a_modello,'VIS_TOT_ARR')
                 ,'SI',v_importo_vers_rid
                 ,null
                 ) importo_ridotto_arrotondato
         , f_descrizione_timp(a_modello,'TOT') totale
         , decode(titr.flag_tariffa
                 ,null,decode(f_descrizione_timp(a_modello,'VIS_TOT_ARR')
                             ,'SI',f_descrizione_timp(a_modello,'TOT_ARR')
                             ,null
                             )
                 ,null
                 ) totale_arr
         , decode(prtr_acc.importo_ridotto
                 ,prtr_acc.importo_totale, null
                 ,f_descrizione_timp(a_modello,'TOT_AD')
                 ) totale_ad
         , decode(prtr_acc.importo_ridotto
                 ,prtr_acc.importo_totale,null
                 ,decode(titr.flag_tariffa
                        ,null,decode(f_descrizione_timp(a_modello,'VIS_TOT_ARR')
                                    ,'SI',f_descrizione_timp(a_modello,'TOT_AD_ARR')
                                    ,null
                                    )
                        ,null
                        )
                 ) totale_ad_arr
         , f_descrizione_timp(a_modello,'TOT_IMP_COMP') totale_imposta_complessiva
         , trim(f_descrizione_timp(a_modello,'RIE_SOM_DOV')) riepilogo_somme_dovute
         , prtr_acc.tipo_evento
         , f_descrizione_titr(prtr_acc.tipo_tributo,prtr_acc.anno) descr_titr
         , sopr.*
         , f_importi_acc(prtr_acc.pratica,'N','TASSA_EVASA') tot_imposta
         , f_importi_acc(prtr_acc.pratica,'N','TASSA_EVASA') tot_imposta_lorda
         , decode(v_acc_imposta_importo_tot,
                  NULL,
                  NULL,
                  f_descrizione_timp(a_modello, 'TOT_ACC_IMP')) label_acc_imposta_importo_tot,
           v_acc_imposta_importo_tot acc_imposta_importo_tot,
           decode(v_sanz_int_importo_tot,
                  null,
                  null,
                  f_descrizione_timp(a_modello, 'TOT_SANZ')) label_sanz_int_importo_tot,
           v_sanz_int_importo_tot sanz_int_importo_tot,
           stampa_common.f_formatta_numero(v_importo_tot - round(f_importi_acc(prtr_acc.pratica,'N','TASSA_EVASA'),0)
                                          ,'I','S') sanz_int_importo_tot_arr,
           stampa_common.f_formatta_numero(f_importi_acc(prtr_acc.pratica,'N','TASSA_EVASA')
                                          ,'I','S') acc_imp_lorda_importo_tot,
          f_descrizione_timp(a_modello, 'INTESTAZIONE') intestazione,
          to_char(prtr_acc.data, 'dd/mm/yyyy') data,
          prtr_acc.numero num,
          v_imposta_acconto_tot imposta_acconto_tot,
          v_imposta_saldo_tot imposta_saldo_tot,
          v_imposta_tot imposta_tot,
          v_versato_ogg_tot versato_ogg_tot,
          v_importo_diff_tot importo_diff_tot,
          a_ni_erede         ni_erede
      from PRATICHE_TRIBUTO prtr_acc
         , TIPI_TRIBUTO titr
         , soggetti_pratica sopr
   where prtr_acc.tipo_tributo = titr.tipo_tributo
     and prtr_acc.pratica in (a_prat)
     and sopr.pratica = a_prat
   order by prtr_acc.pratica;
    return rc;
  end;

function man_immobili
  ( a_cf varchar2
  , a_pratica number
  , a_tipi_oggetto varchar2
  , a_modello number default -1
  ) return sys_refcursor is
  --
    rc sys_refcursor;
  --
    w_anno number;
  --
  begin
    -- Estrae anno accertamento
    begin
      select prtr.anno
        into w_anno
        from pratiche_tributo prtr
       where prtr.pratica = a_pratica;
    exception
      when others then
        w_anno              := to_number(null);
    end;
    --
    open rc for
      select stampa_common.f_formatta_numero(importo1_acconto_num,'I','S') importo1_acconto,
             stampa_common.f_formatta_numero(decode(nvl(importo1_num, 0),
                                      0,importo1_num,
                                        importo1_num - nvl(importo1_acconto_num, 0)),
                               'I','S'
                              ) importo1_saldo,
             --
             stampa_common.f_formatta_numero(importo2_acconto_num,'I','S') importo2_acconto,
             stampa_common.f_formatta_numero(decode(nvl(importo2_num, 0),
                                      0,importo2_num,
                                        importo2_num - nvl(importo2_acconto_num, 0)),
                               'I','S'
                              ) importo2_saldo,
             --
             stampa_common.f_formatta_numero(importo1_acconto_tot_num,'I') importo1_acconto_tot,
             stampa_common.f_formatta_numero(importo1_tot_num - importo1_acconto_tot_num,'I') importo1_saldo_tot,
             stampa_common.f_formatta_numero(importo1_tot_num,'I') importo1_tot,
             --
             stampa_common.f_formatta_numero(importo_versato_num,'I','N') importo_versato,
             -- 2023/01/31 (RV) - Richiesto che sia sempre compilato anche nullo o zero
             stampa_common.f_formatta_numero(importo_versato_tot_num,'I','S') importo_versato_tot,
             stampa_common.f_formatta_numero(importo1_tot_num - importo_versato_tot_num,'I') importo1_differenza_tot,
             imp.*,
             a_modello as modello
        from (select -- distinct
                     a_pratica as pratica,
                     --
                     ogim.imposta importo1_num,
                     ogim.imposta_acconto importo1_acconto_num,
                     --
                     decode(nvl(ogim.imposta, 0),
                            nvl(ogim.imposta_dovuta, 0),
                            to_number(null),
                            ogim.imposta_dovuta) importo2_num,
                     decode(nvl(ogim.imposta_acconto, 0),
                            nvl(ogim.imposta_dovuta_acconto, 0),
                            to_number(null),
                            ogim.imposta_dovuta_acconto) importo2_acconto_num,
                     --
                     sum(nvl(ogim.imposta,0)) over() importo1_tot_num,
                     sum(nvl(ogim.imposta_acconto,0)) over() importo1_acconto_tot_num,
                     --
                     nvl(ogim.importo_versato,0) importo_versato_num,
                     sum(nvl(ogim.importo_versato,0)) over() importo_versato_tot_num,
                     f_get_cod_tributo_f24(ogim.oggetto_imposta,'C') as codice_f24,
                     --
                     ogpr.oggetto_pratica,
                     ogpr.num_ordine,
                     decode(f_conta_costi_storici(ogpr.oggetto_pratica),
                            0,
                            '',
                            '[COSTI_STORICI') costi_storici,
                     decode(ogim.tipo_aliquota,
                            null,
                            '',
                            stampa_common.f_formatta_numero(ogim.aliquota,'I','S')
                           ) aliquota,
                     trim(decode(ogim.tipo_aliquota,
                                 null,
                                 null,
                                 'ALIQUOTA APPLICATA: ' ||
                                 tial.descrizione || ' '
                                )
                         ) st_tial,
                     decode(ogim.aliquota_std,
                            null,
                            '',
                            ' - (ALIQUOTA STANDARD ' ||
                            stampa_common.f_formatta_numero(ogim.aliquota_std,'I','S') || ')'
                           ) st_aliquota_std,
                     ogge.oggetto oggetto,
                     tiog.descrizione descr_tiog,
                     lpad(nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto),2) tipo_oggetto,
                     --
                     decode(ogge.cod_via,
                            null,
                            indirizzo_localita,
                            denom_uff ||
                            decode(ogge.num_civ,
                                   null,
                                   '',
                                   ', ' || ogge.num_civ) ||
                            decode(ogge.suffisso,
                                   null,
                                   '',
                                   '/' || ogge.suffisso) ||
                            decode(ogge.interno,
                                   null,
                                   '',
                                   ' int. ' || ogge.interno)) indirizzo_ok,
                     lpad(nvl(ogge.categoria_catasto, ' '), 4) cat,
                     lpad(nvl(ogge.classe_catasto, ' '), 6) classe,
                     lpad(nvl(ogge.partita, ' '), 8) partita,
                     lpad(nvl(ogge.sezione, ' '), 4) sezione,
                     lpad(nvl(ogge.foglio, ' '), 6) foglio,
                     lpad(nvl(ogge.numero, ' '), 6) numero,
                     lpad(nvl(ogge.subalterno, ' '), 4) subalterno,
                     lpad(nvl(ogge.zona, ' '), 4) zona,
                     lpad(nvl(ogge.protocollo_catasto, ' '), 6) prot_cat,
                     lpad(nvl(to_char(ogge.anno_catasto), ' '), 4) anno_cat,
                     --
                     decode(nvl(f_descrizione_timp(a_modello,'DATI_DIC'),'NO'),
                            'NO',null,
                                 'CALCOLATO PER L''ANNO DI RIFERIMENTO'
                           ) st_valore_riv,
                     decode(nvl(f_descrizione_timp(a_modello,'DATI_DIC'),'NO'),
                            'NO',null,
                            stampa_common.f_formatta_numero(
                                          f_valore(data_dic.valore,
                                                   nvl(data_dic.tipo_oggetto, ogge.tipo_oggetto),
                                                   data_dic.anno,
                                                   ogim.anno,
                                                   nvl(data_dic.categoria_catasto, ogge.categoria_catasto),
                                                   data_dic.tipo_pratica,
                                                   data_dic.flag_valore_rivalutato),
                                                            'I','S')
                           ) valore_riv,
                     decode(nvl(f_descrizione_timp(a_modello,'DATI_DIC'),'NO'),
                            'NO',null,
                            stampa_common.f_formatta_numero(f_rendita(f_valore(data_dic.valore,
                                                         nvl(data_dic.tipo_oggetto,
                                                             ogge.tipo_oggetto),
                                                         data_dic.anno,
                                                         ogim.anno,
                                                         nvl(data_dic.categoria_catasto,
                                                             ogge.categoria_catasto),
                                                         data_dic.tipo_pratica,
                                                         data_dic.flag_valore_rivalutato),
                                                nvl(data_dic.tipo_oggetto,
                                                    ogge.tipo_oggetto),
                                                prtr.anno,
                                                nvl(data_dic.categoria_catasto,
                                                    ogge.categoria_catasto)),
                                      'I','S'
                                     )) rendita_valore_riv,
                     decode(ogpr.valore,
                            null,
                            f_descrizione_timp(a_modello,'DES_RIS_CAT'),
                            null) st_pre_riog,
                     decode(ogpr.valore,
                            null, null,
                            decode(f_descrizione_timp(a_modello,'DATI_DIC'),
                                   'NO',f_descrizione_timp(a_modello,'DES_RIS_CAT'),
                                   decode(ogpr.valore,
                                          data_dic.valore, null,
                                          f_valore(data_dic.valore
                                                  ,nvl(data_dic.tipo_oggetto, ogge.tipo_oggetto)
                                                  ,data_dic.anno
                                                  ,ogim.anno
                                                  ,nvl(data_dic.categoria_catasto
                                                      ,ogge.categoria_catasto)
                                                  ,data_dic.tipo_pratica
                                                  ,data_dic.flag_valore_rivalutato), null,
                                          f_descrizione_timp(a_modello,'DES_RIS_CAT')
                                         )
                                  )
                           ) st_valore_subase,
                     decode(ogpr.valore,
                            null, null,
                            decode(f_descrizione_timp(a_modello,'DATI_DIC'),
                                   'NO',stampa_common.f_formatta_numero(ogpr.valore,'I','S'),
                                   decode(ogpr.valore,
                                          data_dic.valore, null,
                                          f_valore(data_dic.valore
                                                  ,nvl(data_dic.tipo_oggetto,ogge.tipo_oggetto)
                                                  ,data_dic.anno
                                                  ,ogim.anno
                                                  ,nvl(data_dic.categoria_catasto,ogge.categoria_catasto)
                                                  ,data_dic.tipo_pratica
                                                  ,data_dic.flag_valore_rivalutato
                                                  ), null,
                                          stampa_common.f_formatta_numero(ogpr.valore,'I','S')
                                         )
                                  )
                           ) valore_subase,
                     decode(ogpr.valore,
                            null,null,
                            decode(nvl(data_dic.tipo_oggetto,ogge.tipo_oggetto),
                                   2,null,
                            decode(f_descrizione_timp(a_modello,'DATI_DIC'),'NO',
                                   decode(f_rendita_anno_riog(ogpr.oggetto, prtr.anno),
                                          null,stampa_common.f_formatta_numero(
                                                             f_rendita(ogpr.valore,
                                                                       nvl(ogpr.tipo_oggetto,
                                                                           ogge.tipo_oggetto),
                                                                       prtr.anno,
                                                                       nvl(ogpr.categoria_catasto,
                                                                           ogge.categoria_catasto)
                                                                      ),
                                                                              'I')
                                             ,stampa_common.f_formatta_numero(
                                                            f_rendita_anno_riog(ogpr.oggetto,prtr.anno),
                                                                              'I')
                                         ),
                                   decode(ogpr.valore,
                                          data_dic.valore, null,
                                          f_valore(data_dic.valore,
                                                   nvl(data_dic.tipo_oggetto, ogge.tipo_oggetto),
                                                   data_dic.anno,
                                                   ogim.anno,
                                                   nvl(data_dic.categoria_catasto,ogge.categoria_catasto),
                                                   data_dic.tipo_pratica,
                                                   data_dic.flag_valore_rivalutato
                                                   ), null,
                                          decode(f_rendita_anno_riog(ogpr.oggetto, prtr.anno),
                                                 null, null,
                                                 stampa_common.f_formatta_numero(
                                                               f_rendita_anno_riog(ogpr.oggetto,prtr.anno),
                                                                                 'I')
                                                )
                                         )
                                  )
                           )) rendita_valore_subase,
                     --
                     decode(ogpr.valore,
                            null,'',
                            stampa_common.f_formatta_numero(ogpr.valore,'I')
                     ) as valore_ogpr,
                     decode(ogpr.tipo_oggetto,
                            2,'',
                            stampa_common.f_formatta_numero(
                            f_rendita(ogpr.valore,ogpr.tipo_oggetto,ogpr.anno,
                                      nvl(ogpr.categoria_catasto,ogge.categoria_catasto))
                            ,'I')
                     ) as rendita_ogpr,
                     --
                     decode(ogco.perc_possesso,
                            null,'',
                            stampa_common.f_formatta_numero(ogco.perc_possesso,'I','S') || '%'
                           ) perc_poss,
                     to_char(nvl(ogco.mesi_possesso, 12), '99') mp,
                     to_char(nvl(ogco.da_mese_possesso, 1), '99') mip,
                     to_char(nvl(ogco.mesi_possesso_1sem, 6), '99') mp1s,
                     decode(nvl(ogco.mesi_riduzione, 0), 0,'', to_char(ogco.mesi_riduzione, '99')) mr,
                     decode(nvl(ogco.mesi_esclusione, 0), 0,'', to_char(ogco.mesi_esclusione, '99')) me,
                     decode(nvl(ogco.mesi_aliquota_ridotta, 0), 0,'', to_char(ogco.mesi_aliquota_ridotta, '99')) mar,
                     ogco.flag_possesso fp,
                     ogco.flag_esclusione fe,
                     ogco.flag_riduzione fr,
                     ogco.flag_ab_principale fap,
                     ogpr.flag_provvisorio fpr,
                     ogpr.flag_contenzioso fc,
                     decode(ogim.detrazione,
                            null,'',
                                 'DETRAZIONE APPLICATA: ') detr,
                     stampa_common.f_formatta_numero(ogim.detrazione,'I') detrazione,
                     prtr.anno anno,
                     'PERCENTUALE POSSESSO:' st_percposs,
                     'MESI POSSESSO:' st_mesposs,
                     decode(nvl(ogco.mesi_riduzione, 0),
                            0,'',
                            'MESI RIDUZIONE:') st_mesrid,
                     decode(nvl(ogco.mesi_esclusione, 0),
                            0,'',
                            'MESI ESCLUSIONE:') st_mesescl,
                     decode(f_cate_riog_null(ogpr.oggetto,prtr.anno),
                            null,null,
                            rpad('CAT. CATASTALE SULLA BASE DELLA RENDITA DEFINITIVA',
                                 54)) st_catren,
                     decode(ogpr.valore,
                            null,null,
                            decode(f_descrizione_timp(a_modello,'DATI_DIC'),
                                   'NO',nvl(f_cate_riog_null(ogpr.oggetto, prtr.anno),
                                            nvl(ogpr.categoria_catasto,ogge.categoria_catasto)),
                                        decode(ogpr.valore,
                                               data_dic.valore, null,
                                               f_valore(data_dic.valore,
                                                        nvl(data_dic.tipo_oggetto, ogge.tipo_oggetto),
                                                        data_dic.anno,
                                                        ogim.anno,
                                                        nvl(data_dic.categoria_catasto,ogge.categoria_catasto),
                                                        data_dic.tipo_pratica,
                                                        data_dic.flag_valore_rivalutato
                                                       ), null,
                                               nvl(f_cate_riog_null(ogpr.oggetto, prtr.anno), ' ')
                                              )
                                  )
                           ) cat_ren,
                     --
                     'IMPOSTA CALCOLATA '||
                            f_descrizione_timp(a_modello,'DES_RIS_CAT') ||
                            decode(nvl(ogim.imposta, 0),
                                  0,' : 0',
                                  '') imposta_testo1,
                     '   Dettaglio codici tributo per versamento:' imposta_subtesto1,
                            decode(nvl(ogim.imposta, 0),
                                   nvl(ogim.imposta_dovuta, 0),null,
                                   lpad('_________________', 72)) linea_importo1,
                     stampa_common.f_formatta_numero(ogim.imposta,'I','S') importo1,
                     --
                     decode(nvl(ogim.imposta_dovuta, 0),
                            0,'',
                           decode(nvl(f_descrizione_timp(a_modello,'DATI_DIC'),'NO'),
                                  'NO',null,
                                  'IMPOSTA CALCOLATA '||
                                  f_descrizione_timp(a_modello,'DES_RIS_CAT')
                                 )) imposta_testo2,
                     decode(nvl(ogim.imposta_dovuta, 0),
                            0,'',
                            '   Dettaglio codici tributo per versamento:') imposta_subtesto2,
                     decode(nvl(ogim.imposta_dovuta, 0),
                            0,'',
                            lpad('_________________', 72)) linea_importo2,
                     decode(nvl(ogim.imposta_dovuta, 0),
                            0,'',
                            stampa_common.f_formatta_numero(ogim.imposta_dovuta,'I')) importo2,
                     --
                     decode(ogim.imposta_mini,
                            null,'',
                            '(MINI IMU 2013)') st_mini_imu,
                     --
                     ogpr.note note,
                     decode(ogim.tipo_rapporto,
                            'D','PROPRIETARIO QUOTA: '||
                                decode(nvl(ogim.mesi_affitto,0),0,'100,00%',
                                       stampa_common.f_formatta_numero(
                                                     100 - nvl(f_get_perc_occupante(prtr.tipo_tributo,prtr.anno,1),0),
                                                                       'P','S')||'%'||
                                       decode(nvl(ogim.mesi_possesso,12),
                                              nvl(ogim.mesi_affitto,0),'',
                                             ' PER '||nvl(ogim.mesi_affitto,0)||' MESI - 100,00% PER '||
                                             to_char(nvl(ogim.mesi_possesso,12) - nvl(ogim.mesi_affitto,0))||' MESI')),
                            'A','OCCUPANTE QUOTA: '||stampa_common.f_formatta_numero(nvl(ogim.percentuale,100),'P')||'%',''
                           ) tipo_rapporto,
                     --
                     lpad(nvl(ogpr.categoria_catasto,ogge.categoria_catasto), 4) cat_acc,
                     --
                     rpad(decode(data_dic.detrazione,
                                 null,'',
                                      'VALORE DICHIARATO'),
                                   54) st_valdic,
                     decode(data_dic.categoria_catasto,
                            null,null,
                            rpad('CAT. CATASTALE DICHIARATA', 54)) st_catdic,
                     rpad(decode(data_dic.detrazione,
                                 null,'',
                                      'DETRAZIONE DICHIARATA'),
                                   54) detr_dic,
                     --
                     stampa_common.f_formatta_numero(data_dic.valore,'I','N') valore_dic,
                     stampa_common.f_formatta_numero(data_dic.detrazione,'I','N') detrazione_dic,
                     lpad(nvl(data_dic.categoria_catasto,' '), 4) cat_dic,
                     lpad(data_dic.tipo_oggetto,2) tipo_oggetto_dic,
                     decode(data_dic.perc_possesso,
                        null,'',
                        stampa_common.f_formatta_numero(data_dic.perc_possesso,'I','S') || '%'
                         ) perc_dic,
                     decode(nvl(data_dic.mesi_possesso, 0), 0,'', to_char(data_dic.mesi_possesso, '99')) mp_dic,
                     decode(nvl(data_dic.da_mese_possesso, 0), 0,'', to_char(data_dic.da_mese_possesso, '99')) mip_dic,
                     decode(nvl(data_dic.mesi_possesso_1sem, 0), 0,'', to_char(data_dic.mesi_possesso_1sem, '99')) mp1s_dic,
                     decode(nvl(data_dic.mesi_riduzione, 0), 0,'', to_char(data_dic.mesi_riduzione, '99')) mr_dic,
                     decode(nvl(data_dic.mesi_esclusione, 0), 0,'', to_char(data_dic.mesi_esclusione, '99')) me_dic,
                     decode(nvl(data_dic.mesi_aliquota_ridotta, 0), 0,'', to_char(data_dic.mesi_aliquota_ridotta, '99')) mar_dic,
                     data_dic.flag_possesso fp_dic,
                     data_dic.flag_esclusione fe_dic,
                     data_dic.flag_riduzione fr_dic,
                     data_dic.flag_ab_principale fap_dic,
                     data_dic.flag_provvisorio fpr_dic,
                     data_dic.flag_contenzioso fc_dic,
                     stampa_common.f_formatta_numero(data_dic.rendita,'I','N') as rendita_dic,
                     stampa_common.f_formatta_numero(data_dic.imposta,'I','N') as imposta_dic,
                     stampa_common.f_formatta_numero(data_dic.imposta_acconto,'I','N') as imposta_acc_dic,
                     stampa_common.f_formatta_numero(data_dic.imposta_saldo,'I','N') as imposta_sal_dic,
                     stampa_common.f_formatta_numero(data_dic.importo_versato,'I','N') as versato_dic,
                     data_dic.tipo_aliquota as tipo_aliquota_dic,
                     stampa_common.f_formatta_numero(data_dic.aliquota,'I','N') as aliquota_dic,
                     data_dic.des_aliquota as des_aliquota_dic,
                     data_dic.note note_dic,
                     --
                     stampa_common.f_formatta_numero(data_liq.valore,'I','N') valore_liq,
                     stampa_common.f_formatta_numero(data_liq.detrazione,'I','N') detrazione_liq,
                     lpad(nvl(data_liq.categoria_catasto,' '), 4) cat_liq,
                     lpad(data_liq.tipo_oggetto,2) tipo_oggetto_liq,
                     decode(data_liq.perc_possesso,
                        null,'',
                        stampa_common.f_formatta_numero(data_liq.perc_possesso,'I','S') || '%'
                         ) perc_liq,
                     decode(nvl(data_liq.mesi_possesso, 0), 0,'', to_char(data_liq.mesi_possesso, '99')) mp_liq,
                     decode(nvl(data_liq.da_mese_possesso, 0), 0,'', to_char(data_liq.da_mese_possesso, '99')) mip_liq,
                     decode(nvl(data_liq.mesi_possesso_1sem, 0), 0,'', to_char(data_liq.mesi_possesso_1sem, '99')) mp1s_liq,
                     decode(nvl(data_liq.mesi_riduzione, 0), 0,'', to_char(data_liq.mesi_riduzione, '99')) mr_liq,
                     decode(nvl(data_liq.mesi_esclusione, 0), 0,'', to_char(data_liq.mesi_esclusione, '99')) me_liq,
                     decode(nvl(data_liq.mesi_aliquota_ridotta, 0), 0,'', to_char(data_liq.mesi_aliquota_ridotta, '99')) mar_liq,
                     data_liq.flag_possesso fp_liq,
                     data_liq.flag_esclusione fe_liq,
                     data_liq.flag_riduzione fr_liq,
                     data_liq.flag_ab_principale fap_liq,
                     data_liq.flag_provvisorio fpr_liq,
                     data_liq.flag_contenzioso fc_liq,
                     stampa_common.f_formatta_numero(data_liq.rendita,'I','N') as rendita_liq,
                     stampa_common.f_formatta_numero(data_liq.imposta,'I','N') as imposta_liq,
                     stampa_common.f_formatta_numero(data_liq.imposta_acconto,'I','N') as imposta_acc_liq,
                     stampa_common.f_formatta_numero(data_liq.imposta_saldo,'I','N') as imposta_sal_liq,
                     stampa_common.f_formatta_numero(data_liq.importo_versato,'I','N') as versato_liq,
                     data_liq.tipo_aliquota as tipo_aliquota_liq,
                     stampa_common.f_formatta_numero(data_liq.aliquota,'I','N') as aliquota_liq,
                     data_liq.des_aliquota as des_aliquota_liq,
                     data_liq.note note_liq
                     --
                from tipi_aliquota        tial,
                     archivio_vie         arvi,
                     tipi_oggetto         tiog,
                     oggetti              ogge,
                     oggetti_contribuente ogco,
                     oggetti_pratica      ogpr,
                     oggetti_imposta      ogim,
                     pratiche_tributo     prtr,
                     -- Dichiarato
                    (select
                        ogpr_dic1.oggetto_pratica,
                        null as ogg_pr_rif,
                        ogpr_dic1.num_ordine as num_ordine,
                        nvl(ogpr_dic1.tipo_oggetto,ogge_dic1.tipo_oggetto) as tipo_oggetto,
                        nvl(ogpr_dic1.categoria_catasto,ogge_dic1.categoria_catasto) as categoria_catasto,
                        --
                        ogpr_dic1.flag_contenzioso,
                        ogpr_dic1.numero_familiari,
                        ogpr_dic1.consistenza,
                        ogco_dic1.data_decorrenza,
                        ogco_dic1.data_cessazione,
                        ogco_dic1.inizio_occupazione,
                        ogco_dic1.fine_occupazione,
                        ogco_dic1.perc_possesso,
                        decode(w_anno,prtr_dic1.anno,ogco_dic1.mesi_possesso,12) mesi_possesso,
                        decode(w_anno,prtr_dic1.anno,ogco_dic1.mesi_possesso_1sem,6) mesi_possesso_1sem,
                        decode(w_anno,prtr_dic1.anno,
                            decode(ogco_dic1.flag_esclusione,'S',
                               nvl(ogco_dic1.mesi_esclusione,nvl(ogco_dic1.mesi_possesso,12)),
                               ogco_dic1.mesi_esclusione),
                            decode(ogco_dic1.flag_esclusione,'S',12,null)) mesi_esclusione,
                        decode(w_anno,prtr_dic1.anno,
                            decode(ogco_dic1.flag_riduzione,'S',
                               nvl(ogco_dic1.mesi_riduzione,nvl(ogco_dic1.mesi_possesso,12)),
                               ogco_dic1.mesi_riduzione),
                            decode(ogco_dic1.flag_riduzione,'S',12,null)) mesi_riduzione,
                        ogco_dic1.mesi_aliquota_ridotta,
                        decode(w_anno,prtr_dic1.anno,ogco_dic1.da_mese_possesso,1) da_mese_possesso,
                        ogco_dic1.flag_possesso,
                        ogco_dic1.flag_esclusione,
                        ogco_dic1.flag_riduzione,
                        ogco_dic1.flag_ab_principale,
                        ogpr_dic1.flag_provvisorio,
                        ogpr_dic1.note,
                        --
                        ogim_dic1.imposta as imposta,
                        ogim_dic1.imposta_acconto as imposta_acconto,
                        (ogim_dic1.imposta - ogim_dic1.imposta_acconto) as imposta_saldo,
                        ogim_dic1.importo_versato as importo_versato,
                        ogim_dic1.tipo_aliquota as tipo_aliquota,
                        ogim_dic1.aliquota as aliquota,
                        tial_dic1.descrizione as des_aliquota,
                        nvl(to_number(f_max_riog(ogpr_dic1.oggetto_pratica,w_anno,'RE')),
                          f_rendita(ogpr_dic1.valore,nvl(ogpr_dic1.tipo_oggetto,ogge_dic1.tipo_oggetto),
                                    ogpr_dic1.anno,nvl(ogpr_dic1.categoria_catasto,ogge_dic1.categoria_catasto))) as rendita,
                        ogco_dic1.detrazione as detrazione,
                        nvl(f_valore((to_number(f_max_riog(ogpr_dic1.oggetto_pratica,w_anno,'RE')) *
                                        decode(ogge_dic1.tipo_oggetto
                                            ,1,nvl(molt_dic1.moltiplicatore,1)
                                            ,3,nvl(molt_dic1.moltiplicatore,1),1))
                                       , ogge_dic1.tipo_oggetto, 1996, w_anno, ' '
                                       ,prtr_dic1.tipo_pratica
                                       ,ogpr_dic1.flag_valore_rivalutato)
                                    , f_valore(ogpr_dic1.valore,nvl(ogpr_dic1.tipo_oggetto,ogge_dic1.tipo_oggetto)
                                         , prtr_dic1.anno, w_anno
                                         ,nvl(ogpr_dic1.categoria_catasto,ogge_dic1.categoria_catasto)
                                         ,prtr_dic1.tipo_pratica
                                         ,ogpr_dic1.flag_valore_rivalutato)) as valore,
                        ogpr_dic1.flag_valore_rivalutato as flag_valore_rivalutato,
                        prtr_dic1.anno as anno,
                        prtr_dic1.tipo_pratica as tipo_pratica
                    from
                        oggetti_pratica      ogpr_dic1,
                        oggetti              ogge_dic1,
                        oggetti_imposta      ogim_dic1,
                        pratiche_tributo     prtr_dic1,
                        oggetti_contribuente ogco_dic1,
                        tipi_aliquota        tial_dic1,
                        moltiplicatori       molt_dic1
                    where
                         prtr_dic1.pratica = ogpr_dic1.pratica
                     and ogpr_dic1.oggetto = ogge_dic1.oggetto
                     and ogpr_dic1.oggetto_pratica = ogco_dic1.oggetto_pratica
                     and ogco_dic1.cod_fiscale = a_cf
                     and ogim_dic1.tipo_tributo = tial_dic1.tipo_tributo (+)
                     and ogim_dic1.tipo_aliquota = tial_dic1.tipo_aliquota (+)
                     and ogco_dic1.oggetto_pratica = ogim_dic1.oggetto_pratica (+)
                     and ogco_dic1.cod_fiscale = ogim_dic1.cod_fiscale (+)
                     and ogim_dic1.anno(+) = w_anno
                     and molt_dic1.anno(+) = w_anno
                     and molt_dic1.categoria_catasto(+) = f_max_riog(ogpr_dic1.oggetto_pratica,w_anno,'CA')
                     ) data_dic,
                     -- Liquidato
                    (select
                      ogpr_liq.oggetto_pratica,
                      ogpr_liq.oggetto_pratica_rif as ogg_pr_rif,
                      ogpr_liq.num_ordine as num_ordine,
                      nvl(ogpr_liq.tipo_oggetto,ogge_liq.tipo_oggetto) as tipo_oggetto,
                      nvl(ogpr_liq.categoria_catasto,ogge_liq.categoria_catasto) as categoria_catasto,
                      --
                      ogpr_liq.flag_contenzioso,
                      ogpr_liq.numero_familiari,
                      ogpr_liq.consistenza,
                      ogco_liq.data_decorrenza,
                      ogco_liq.data_cessazione,
                      ogco_liq.inizio_occupazione,
                      ogco_liq.fine_occupazione,
                      ogco_liq.perc_possesso,
                      ogco_liq.mesi_possesso,
                      ogco_liq.mesi_possesso_1sem,
                      ogco_liq.mesi_esclusione,
                      ogco_liq.mesi_riduzione,
                      ogco_liq.mesi_aliquota_ridotta,
                      ogco_liq.da_mese_possesso,
                      ogco_liq.flag_possesso,
                      ogco_liq.flag_esclusione,
                      ogco_liq.flag_riduzione,
                      ogco_liq.flag_ab_principale,
                      ogpr_liq.flag_provvisorio,
                      ogpr_liq.note,
                      --
                      ogim_liq.imposta as imposta,
                      ogim_liq.imposta_acconto as imposta_acconto,
                      (ogim_liq.imposta - ogim_liq.imposta_acconto) as imposta_saldo,
                      ogim_liq.importo_versato as importo_versato,
                      ogim_liq.tipo_aliquota as tipo_aliquota,
                      ogim_liq.aliquota as aliquota,
                      tial_liq.descrizione as des_aliquota,
                      f_rendita(ogpr_liq.valore,nvl(ogpr_liq.tipo_oggetto,ogge_liq.tipo_oggetto),w_anno,nvl(ogpr_liq.categoria_catasto,ogge_liq.categoria_catasto)) as rendita,
                      ogco_liq.detrazione as detrazione,
                      ogpr_liq.valore as valore,
                      ogpr_liq.flag_valore_rivalutato as flag_valore_rivalutato,
                      prtr_liq.anno as anno,
                      prtr_liq.tipo_pratica as tipo_pratica
                    from
                      oggetti_contribuente ogco_liq,
                      oggetti_pratica ogpr_liq,
                      oggetti ogge_liq,
                      oggetti_imposta ogim_liq,
                      pratiche_tributo prtr_liq,
                      pratiche_tributo prtr_acc,
                      tipi_aliquota tial_liq
                    where
                      prtr_acc.pratica = a_pratica and
                      prtr_liq.tipo_tributo||'' = 'ICI' and
                      prtr_liq.tipo_pratica = 'L' and
                      prtr_liq.tipo_evento = 'U' and
                      prtr_liq.anno = prtr_acc.anno and
                      prtr_liq.pratica = ogpr_liq.pratica and
                      prtr_liq.data_notifica is not null and
                      ogim_liq.anno(+) = ogco_liq.anno and
                      ogim_liq.cod_fiscale(+) = ogco_liq.cod_fiscale and
                      ogim_liq.oggetto_pratica(+) = ogco_liq.oggetto_pratica and
                      ogco_liq.cod_fiscale = a_cf and
                      ogco_liq.oggetto_pratica = ogpr_liq.oggetto_pratica and
                      ogpr_liq.oggetto = ogge_liq.oggetto and
                      ogim_liq.tipo_tributo = tial_liq.tipo_tributo (+) and
                      ogim_liq.tipo_aliquota = tial_liq.tipo_aliquota (+) and
                      (not exists
                      (select 1
                         from
                          oggetti_contribuente ogco_liq,
                          oggetti_pratica ogpr_liq,
                          oggetti_imposta ogim_liq,
                          pratiche_tributo prtr_liq
                        where
                          prtr_liq.tipo_pratica = 'L' and
                          prtr_liq.tipo_evento = 'R' and
                          prtr_liq.anno = prtr_acc.anno and
                          prtr_liq.pratica = ogpr_liq.pratica and
                          prtr_liq.data_notifica is not null and
                          ogim_liq.anno(+) = ogco_liq.anno and
                          ogim_liq.cod_fiscale(+) = ogco_liq.cod_fiscale and
                          ogim_liq.oggetto_pratica(+) = ogco_liq.oggetto_pratica and
                          ogco_liq.cod_fiscale = a_cf and
                          ogco_liq.oggetto_pratica = ogpr_liq.oggetto_pratica
                        )
                      )
                    union
                    select
                      ogpr_liq.oggetto_pratica,
                      ogpr_liq.oggetto_pratica_rif as ogg_pr_rif,
                      ogpr_liq.num_ordine as num_ordine,
                      nvl(ogpr_liq.tipo_oggetto,ogge_liq.tipo_oggetto) as tipo_oggetto,
                      nvl(ogpr_liq.categoria_catasto,ogge_liq.categoria_catasto) as categoria_catasto,
                      --
                      ogpr_liq.flag_contenzioso,
                      ogpr_liq.numero_familiari,
                      ogpr_liq.consistenza,
                      ogco_liq.data_decorrenza,
                      ogco_liq.data_cessazione,
                      ogco_liq.inizio_occupazione,
                      ogco_liq.fine_occupazione,
                      ogco_liq.perc_possesso,
                      ogco_liq.mesi_possesso,
                      ogco_liq.mesi_possesso_1sem,
                      ogco_liq.mesi_esclusione,
                      ogco_liq.mesi_riduzione,
                      ogco_liq.mesi_aliquota_ridotta,
                      ogco_liq.da_mese_possesso,
                      ogco_liq.flag_possesso,
                      ogco_liq.flag_esclusione,
                      ogco_liq.flag_riduzione,
                      ogco_liq.flag_ab_principale,
                      ogpr_liq.flag_provvisorio,
                      ogpr_liq.note,
                      --
                      ogim_liq.imposta as imposta,
                      ogim_liq.imposta_acconto as imposta_acconto,
                      (ogim_liq.imposta - ogim_liq.imposta_acconto) as imposta_saldo,
                      ogim_liq.importo_versato as importo_versato,
                      ogim_liq.tipo_aliquota as tipo_aliquota,
                      ogim_liq.aliquota as aliquota,
                      tial_liq.descrizione as des_aliquota,
                      f_rendita(ogpr_liq.valore,nvl(ogpr_liq.tipo_oggetto,ogge_liq.tipo_oggetto),w_anno,nvl(ogpr_liq.categoria_catasto,ogge_liq.categoria_catasto)) as rendita,
                      ogco_liq.detrazione as detrazione,
                      ogpr_liq.valore as valore,
                      ogpr_liq.flag_valore_rivalutato as flag_valore_rivalutato,
                      prtr_liq.anno as anno,
                      prtr_liq.tipo_pratica as tipo_pratica
                    from
                      oggetti_contribuente ogco_liq,
                      oggetti_pratica ogpr_liq,
                      oggetti ogge_liq,
                      oggetti_imposta ogim_liq,
                      pratiche_tributo prtr_liq,
                      pratiche_tributo prtr_acc,
                      tipi_aliquota tial_liq
                    where
                      prtr_acc.pratica = a_pratica and
                      prtr_liq.tipo_tributo||'' = 'ICI' and
                      prtr_liq.tipo_pratica = 'L' and
                      prtr_liq.tipo_evento = 'R' and
                      prtr_liq.anno = prtr_acc.anno and
                      prtr_liq.pratica = ogpr_liq.pratica and
                      prtr_liq.data_notifica is not null and
                      ogim_liq.anno(+) = ogco_liq.anno and
                      ogim_liq.cod_fiscale(+) = ogco_liq.cod_fiscale and
                      ogim_liq.oggetto_pratica(+) = ogco_liq.oggetto_pratica and
                      ogco_liq.cod_fiscale = a_cf and
                      ogco_liq.oggetto_pratica = ogpr_liq.oggetto_pratica and
                      ogpr_liq.oggetto = ogge_liq.oggetto and
                      ogim_liq.tipo_tributo = tial_liq.tipo_tributo (+) and
                      ogim_liq.tipo_aliquota = tial_liq.tipo_aliquota (+)
                     ) data_liq,
                     --
                     dati_generali        dage
               where (tial.tipo_aliquota =
                     nvl(ogim.tipo_aliquota, tial.tipo_aliquota))
                 and (tiog.tipo_oggetto =
                     nvl(ogpr.tipo_oggetto,
                          nvl(data_dic.tipo_oggetto, ogge.tipo_oggetto)))
                 and (ogim.cod_fiscale = ogco.cod_fiscale)
                 and (ogim.oggetto_pratica = ogco.oggetto_pratica)
                 and (ogge.oggetto = ogpr.oggetto)
                 and ogpr.oggetto_pratica_rif = data_dic.oggetto_pratica (+)
                 and (ogim.anno = prtr.anno)
                 and (arvi.cod_via(+) = ogge.cod_via)
                 and (ogpr.pratica = prtr.pratica)
                 and (ogpr.oggetto_pratica = ogco.oggetto_pratica)
                 and ogco.cod_fiscale = a_cf
                 and prtr.pratica = a_pratica
                 and tial.tipo_tributo = prtr.tipo_tributo
                 and ((data_dic.oggetto_pratica(+) is not null) and (data_dic.oggetto_pratica = data_liq.ogg_pr_rif(+)))
                 and instr(nvl(a_tipi_oggetto,'1,2,3,4')||',',
                           to_char(nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto))||',') > 0
               order by ogpr.num_ordine,
                        ogge.oggetto,
                        lpad(nvl(ogge.classe_catasto, ' '), 6),
                        lpad(nvl(ogge.sezione, ' '), 4),
                        lpad(nvl(ogge.foglio, ' '), 6),
                        lpad(nvl(ogge.numero, ' '), 6),
                        lpad(nvl(ogge.subalterno, ' '), 4)) imp;

    return rc;
  end;

  function man_versamenti
  ( a_cf                                varchar2
  , a_pratica                           number
  , a_modello                           number
  ) return sys_refcursor is
  rc sys_refcursor;
  begin
    open rc for
      select nvl(to_char(versamenti.rata,99),'  ') rata
           , versamenti.importo_versato importo_versato_no_st
           , stampa_common.f_formatta_numero(versamenti.importo_versato,'I','S') importo_versato
           , nvl(to_char(versamenti.data_pagamento,'dd/mm/yyyy'),'          ') data_versamento
           , nvl(versamenti.tipo_versamento,' ') tipo_vers
           , nvl(to_char(decode(versamenti.rata
                               ,0,nvl(ruol.scadenza_rata_unica, ruol.scadenza_prima_rata)
                               ,1,ruol.scadenza_prima_rata
                               ,2,ruol.scadenza_rata_2
                               ,3,ruol.scadenza_rata_3
                               ,4,ruol.scadenza_rata_4
                               )
                        ,'dd/mm/yyyy'
                        )
                ,'          '
                ) data_scadenza
           , rtrim(f_descrizione_timp(a_modello,'DETT_VERS')) st_dettaglio_versamenti
           , f_descrizione_timp(a_modello,'DIFF_PRT') st_differenza_imposta
           , f_descrizione_timp(a_modello,'TOT_DETT_VERS_PRT') st_totale_dettaglio_versamenti
           , f_descrizione_timp(a_modello,'TOT_IMP_PRT') st_totale_imposta
           , f_descrizione_timp(a_modello,'TOT_VERS_RIEP_PRT') st_totale_versamento
           , rtrim(f_descrizione_timp(a_modello,'RIEP_DETT_PRT')) st_riepilogo
           , sum(versamenti.importo_versato) over() tot_versato_no_st
           , stampa_common.f_formatta_numero(sum(versamenti.importo_versato) over(),'I','S') tot_versato
        from versamenti
           , pratiche_tributo prtr
           , ruoli            ruol
       where versamenti.pratica               is null
         and versamenti.oggetto_imposta       is null
         and versamenti.cod_fiscale           = a_cf
         and versamenti.anno                  = prtr.anno
         and prtr.pratica                     = a_pratica
         and versamenti.tipo_tributo          = 'ICI'
         and versamenti.ruolo                 = ruol.ruolo (+)
         -- (VD - 28/01/2022): eliminato test su sanzioni per omessa/infedele denuncia
         --                    Normalmente negli avvisi per omessa/infedele denuncia
         --                    i versamenti non vengono stampati.
         --                    Si e' deciso (EA - 27/01/2022) di prevedere comunque un
         --                    riepilogo degli eventuali versamenti spontanei effettuati
         --                    e lasciare al cliente la scelta se stamparli o meno nell'avviso
         /*and not exists (select sapr.cod_sanzione
                           from sanzioni_pratica sapr
                          where sapr.cod_sanzione in (2,3,4,5,6,102,103,104,105,106)
                                -- omesse, infedeli e tardive denunce
                            and sapr.pratica = a_pratica
                        ) */
       order by 1,3;
    return rc;
  end;

  function man_versamenti_vuoto(a_cf varchar2, a_pratica number, a_anno number, a_modello number)
    return sys_refcursor is
    rc sys_refcursor;
  begin
    open rc for
      select a_cf as cod_fiscale, a_pratica as pratica, a_anno as anno, a_modello as modello
        from dual;
    return rc;
  end;

  function man_acc
  ( a_prat        number default -1
  , a_tipo_record varchar2 default ''
  , a_modello     number default -1
  ) return sys_refcursor  is
    rc sys_refcursor;
  begin
    open rc for
      select imp_acc.cod_sanzione
           , imp_acc.sanz_ord1
           , imp_acc.sanz_ord
           , imp_acc.ord
           , imp_acc.perc_sanzione
           , imp_acc.perc_riduzione
           , imp_acc.semestri
           , imp_acc.importo_sanzione
           , imp_acc.cod_tributo_f24
           , imp_acc.descr_sanzione
           , imp_acc.st_accertamento_imposta
           --, sum(imp_acc.importo) over() totale
           , stampa_common.f_formatta_numero(sum(imp_acc.importo) over(),'I','S') importo_tot
      from
      (select sanzioni_pratica.cod_sanzione
            ,trunc(sanzioni_pratica.cod_sanzione / 100) sanz_ord1
            ,sanzioni.tipo_causale || nvl (sanzioni.flag_magg_tares, 'N') sanz_ord
            ,1 ord
            ,decode(a_tipo_record
                   ,'X', nvl(sanzioni_pratica.importo,0)
                   ,sanzioni_pratica.importo
                   ) importo
            ,decode(sanzioni_pratica.percentuale
                   ,null, ''
                   ,stampa_common.f_formatta_numero(sanzioni_pratica.percentuale
                                                   ,'P','S'
                                                   )
                   ) perc_sanzione
            ,decode(sanzioni_pratica.riduzione
                   ,null, ''
                   ,stampa_common.f_formatta_numero(sanzioni_pratica.riduzione
                                                   ,'P','S'
                                                   )
                   ) perc_riduzione
            ,decode(sanzioni_pratica.semestri
                   ,null, ''
                   ,to_char(sanzioni_pratica.semestri,'99')
                   ) semestri
            ,stampa_common.f_formatta_numero
                   (decode(a_tipo_record
                          ,'X',nvl(sanzioni_pratica.importo,0)
                          ,sanzioni_pratica.importo
                          )
                ,'I','S'
                ) importo_sanzione
            ,decode(f_descrizione_timp(a_modello,'VIS_COD_TRIB')
                   ,'SI',nvl(sanzioni.cod_tributo_f24
                            ,'3923'
                            )
                   ,''
                   ) cod_tributo_f24
            ,sanzioni.descrizione descr_sanzione
            ,rtrim(decode(a_tipo_record
                         ,'I',f_descrizione_timp(a_modello,'ACC_IMP')
                         ,null
                         )
                  ) st_accertamento_imposta
        from SANZIONI_PRATICA
            ,SANZIONI
            ,PRATICHE_TRIBUTO
            ,(select nvl(max(nvl(cotr.flag_ruolo,'N')),'N') flag_ruolo
                from CODICI_TRIBUTO cotr
                   , OGGETTI_PRATICA ogpr
                   , PRATICHE_TRIBUTO PRTR
               where cotr.tributo = ogpr.tributo
                 and ogpr.pratica = prtr.pratica
                 AND prtr.pratica_rif = a_prat) ogpr
       where sanzioni_pratica.cod_sanzione = sanzioni.cod_sanzione
         and sanzioni_pratica.sequenza_sanz = sanzioni.sequenza
         and sanzioni_pratica.tipo_tributo = sanzioni.tipo_tributo
         and ( (pratiche_tributo.tipo_tributo = 'ICI' and
                sanzioni.tipo_causale = 'E')
           or  (pratiche_tributo.tipo_tributo != 'ICI' and
               sanzioni.flag_imposta = 'S'))
         and sanzioni.cod_sanzione not in (888, 889)
         and sanzioni_pratica.pratica = a_prat
         and (a_tipo_record = 'X'
           or (a_tipo_record = 'I' and
               nvl(sanzioni.flag_magg_tares,'N') = 'N')
           or (a_tipo_record = 'M' and
               nvl(sanzioni.flag_magg_tares,'N') != 'N'))
         and pratiche_tributo.pratica = a_prat
      union
      select sanzioni_pratica.cod_sanzione
            ,trunc(sanzioni_pratica.cod_sanzione / 100) sanz_ord1
            ,sanzioni.tipo_causale || nvl (sanzioni.flag_magg_tares, 'N') sanz_ord
            ,2 ord
            ,decode (a_tipo_record
                    ,'X', nvl(sanzioni_pratica.importo,0)
                    ,
                    0
                    ) importo
            ,decode(sanzioni_pratica.percentuale
                   ,null, ''
                   ,stampa_common.f_formatta_numero(sanzioni_pratica.percentuale
                                                   ,'P','S'
                                                   )
                   ) perc_sanzione
            ,decode(sanzioni_pratica.riduzione
                   ,null,''
                   ,stampa_common.f_formatta_numero(sanzioni_pratica.riduzione
                                                   ,'P','S'
                                                   )
                   ) perc_riduzione
            ,decode(sanzioni_pratica.semestri
                   ,null,''
                   ,to_char(sanzioni_pratica.semestri,'99')
                   ) semestri
            ,stampa_common.f_formatta_numero
                (decode(a_tipo_record
                       ,'X',nvl(sanzioni_pratica.importo,0)
                       ,0
                       )
                ,'I','S'
                ) importo_sanzione
            ,decode(f_descrizione_timp(a_modello, 'VIS_COD_TRIB')
                   ,'SI',nvl(sanzioni.cod_tributo_f24
                            ,'3923'
                            )
                   ,''
                   ) cod_tributo_f24
            ,null descr_sanzione
            ,rtrim(decode(a_tipo_record
                         ,'I',f_descrizione_timp(a_modello,'ACC_IMP')
                         ,null
                         )
                  ) st_accertamento_imposta
        from SANZIONI_PRATICA
            ,SANZIONI
            ,PRATICHE_TRIBUTO
            ,(select nvl (max (nvl (cotr.flag_ruolo, 'N')), 'N') flag_ruolo
                from codici_tributo cotr, oggetti_pratica ogpr, PRATICHE_TRIBUTO PRTR
               where cotr.tributo = ogpr.tributo
                 and ogpr.pratica = prtr.pratica
                 and prtr.pratica_rif = a_prat) ogpr
       where sanzioni_pratica.cod_sanzione = sanzioni.cod_sanzione
         and sanzioni_pratica.sequenza_sanz = sanzioni.sequenza
         and sanzioni_pratica.tipo_tributo = sanzioni.tipo_tributo
         and ( (pratiche_tributo.tipo_tributo = 'ICI' and
                sanzioni.tipo_causale = 'E')
           or (pratiche_tributo.tipo_tributo != 'ICI' and
               sanzioni.flag_imposta = 'S'))
         and (sanzioni.cod_sanzione not in (888, 889))
         and (sanzioni_pratica.pratica = a_prat)
         and (a_tipo_record = 'X'
           or (a_tipo_record = 'I'
           and nvl(sanzioni.flag_magg_tares,'N') = 'N')
           or (a_tipo_record = 'M'
           and nvl(sanzioni.flag_magg_tares,'N') != 'N'))
         and pratiche_tributo.pratica = a_prat
      order by 3, 1, 4) imp_acc;
    return rc;
  end;

  function man_acc_imposta
  ( a_prat number default -1
  , a_modello number default -1
  ) return sys_refcursor is
  begin
    return man_acc(a_prat, 'I', a_modello);
  end;

  function man_sanz
  ( a_prat        number default -1
  , a_tipo_record varchar2 default ''
  , a_modello     number default -1
  ) return sys_refcursor is
    rc sys_refcursor;
  begin
    open rc for
      select imp_sanz.cod_sanzione
           , imp_sanz.perc_sanzione
           , imp_sanz.perc_riduzione
           , imp_sanz.giorni_semestri
           , imp_sanz.importo_sanzione
           , imp_sanz.cod_tributo_f24
           , imp_sanz.descrizione
           , imp_sanz.st_irrogazioni_sanz_int
           , stampa_common.f_formatta_numero(imp_sanz.totale
                                            ,'I','S'
                                            ) importo_tot
           , stampa_common.f_formatta_numero(imp_sanz.totale_arr
                                            ,'I','S'
                                            ) importo_tot_arr
        from
     (select sanzioni_pratica.cod_sanzione
           , nvl(sanzioni_pratica.importo,0) importo
           , decode(sanzioni_pratica.percentuale
                   ,null,''
                   ,stampa_common.f_formatta_numero(sanzioni_pratica.percentuale
                                                   ,'P','S'
                                                   )
                   ) perc_sanzione
           , decode(sanzioni_pratica.riduzione
                   ,null,''
                   ,stampa_common.f_formatta_numero(sanzioni_pratica.riduzione
                                                   ,'P','S'
                                                   )
                   ) perc_riduzione
           , decode(nvl(sanzioni_pratica.giorni,sanzioni_pratica.semestri)
                   ,null,''
                   ,to_char(nvl(sanzioni_pratica.giorni,sanzioni_pratica.semestri)
                                ,'9999'
                                )
                   ) giorni_semestri
           , stampa_common.f_formatta_numero(sanzioni_pratica.importo
                                            ,'I','S'
                                            ) importo_sanzione
           , decode(sanzioni.tipo_tributo
                   ,'ICI',decode(f_descrizione_timp(a_modello,'VIS_COD_TRIB')
                                  ,'SI',nvl(sanzioni.cod_tributo_f24
                                           ,'3923'
                                           )
                                  ,''
                                  )
                   ,''
                   ) cod_tributo_f24
           , sanzioni.descrizione descrizione
           , rtrim(f_descrizione_timp(a_modello,'IRR_SANZ_INT')) st_irrogazioni_sanz_int
           , SUM(importo) over() totale
           , SUM(round(importo,0)) over() totale_arr
        from sanzioni_pratica
           , sanzioni
       where sanzioni_pratica.cod_sanzione = sanzioni.cod_sanzione
         and sanzioni_pratica.sequenza_sanz = sanzioni.sequenza
         and sanzioni_pratica.tipo_tributo = sanzioni.tipo_tributo
         and sanzioni_pratica.cod_sanzione not in (888, 889, 891, 892, 893, 894)
         and ( (sanzioni.tipo_tributo = 'ICI' and NVL(sanzioni.tipo_causale,'X') != 'E')
            or (sanzioni.tipo_tributo != 'ICI' and nvl(sanzioni.flag_imposta,'N') != 'S'))
         and sanzioni_pratica.pratica = a_prat
         and (a_tipo_record = 'X'
           or (a_tipo_record = 'I' and nvl (sanzioni.flag_magg_tares, 'N') = 'N')
           or (a_tipo_record = 'M' and nvl (sanzioni.flag_magg_tares, 'N') != 'N'))
    order by 1) imp_sanz;
    return rc;
  end;

  function man_sanz_int
  ( a_prat number default -1
  , a_modello number default -1
  ) return sys_refcursor is
  begin
    return man_sanz(a_prat, 'I', a_modello);
  end;

  function man_riep_vers
  ( a_prat number
  , a_modello number
  ) return sys_refcursor is
    rc sys_refcursor;
  begin
    open rc for
         select
            vers.*,
             stampa_common.f_formatta_numero(sum(vers.importo_non_st) over(),'I') st_importo_vers_tot,
             stampa_common.f_formatta_numero(sum(vers.importo_ridotto_non_st) over(),'I') st_importo_vers_rid,
             sum(vers.importo_non_st) over() importo_vers_tot,
             sum(vers.importo_ridotto_non_st) over() importo_vers_rid
         from
             (
      select cod_tributo,
             descr_tributo,
             lpad(stampa_common.f_formatta_numero(sum(importo), 'I','S'),
                  14,
                  ' ') importo,
             lpad(stampa_common.f_formatta_numero(sum(importo_ridotto), 'I','S'),
                  14,
                  ' ') imp_ridotto,
             sum(importo) importo_non_st,
             sum(importo_ridotto) importo_ridotto_non_st,
             rtrim(f_descrizione_timp(a_modello, 'F24_INT')) f24_intestazione,
             rpad(rtrim(f_descrizione_timp(a_modello, 'F24_TOT')), 24) f24_totale
        from (
        ------------
              select importi.cod_tributo_f24 cod_tributo,
                     cf24.descrizione descr_tributo,
                     round(sum(importi.importo),0) importo,
                     round(sum(importi.importo_ridotto),0) importo_ridotto
              from (select
                            prtr.pratica,
                            prtr.tipo_tributo,
                            sapr.cod_sanzione,
                            (case when nvl(sanz.tipo_causale,'X') = 'E' then '3918'
                            else sanz.cod_tributo_f24
                            end) cod_tributo_f24,
                            f_importo_f24_viol(sapr.importo,
                                                        sapr.riduzione,
                                                        'N',
                                                        prtr.tipo_tributo,
                                                        prtr.anno,
                                                        sanz.tipo_causale,
                                                        sanz.flag_magg_tares) importo,
                            f_importo_f24_viol(sapr.importo,
                                                        sapr.riduzione,
                                                        'S',
                                                        prtr.tipo_tributo,
                                                        prtr.anno,
                                                        sanz.tipo_causale,
                                                        sanz.flag_magg_tares,
                                                        (case when prtr.flag_sanz_min_rid = 'S'
                                                         then sanz.sanzione_minima
                                                         else null end)) importo_ridotto
                       from pratiche_tributo prtr,
                            sanzioni_pratica sapr,
                            sanzioni sanz
                      where sapr.pratica = prtr.pratica
                        and sapr.cod_sanzione = sanz.cod_sanzione
                        and sapr.sequenza_sanz = sanz.sequenza
                        and sapr.tipo_tributo = sanz.tipo_tributo
                        and prtr.pratica in (a_prat)) importi,
                    codici_f24 cf24
              where importi.cod_tributo_f24 = cf24.tributo_f24 (+)
                and importi.tipo_tributo = cf24.tipo_tributo (+)
              group by
                    importi.pratica,
                    importi.cod_tributo_f24,
                    cf24.descrizione
        ------------
        )
       group by cod_tributo, descr_tributo
      having nvl(sum(importo), 0) <> 0 or nvl(sum(importo_ridotto), 0) <> 0
      ) vers;
    return rc;
  end;

  function man_aggi_dilazione
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

  function f_get_cod_tributo_f24
  ( a_oggetto_imposta                  number
  , a_destinatario                     varchar2
  ) return varchar2 is
    d_return                           varchar2(4);
    w_anno                             number;
    w_tipo_oggetto                     number;
    w_categoria_catasto                varchar2(3);
    w_tipo_aliquota                    number;
    w_aliquota_erariale                number;
    w_flag_fabb_merce                  varchar2(1);
  begin
    -- Selezione dati identificativi oggetto imposta
    begin
      select ogim.anno
           , nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
           , nvl(ogpr.categoria_catasto,ogge.categoria_catasto)
           , ogim.tipo_aliquota
           , ogim.aliquota_erariale
           , nvl(aliq.flag_fabbricati_merce,'N')
        into w_anno
           , w_tipo_oggetto
           , w_categoria_catasto
           , w_tipo_aliquota
           , w_aliquota_erariale
           , w_flag_fabb_merce
        from oggetti_imposta ogim,
             oggetti_pratica ogpr,
             oggetti ogge,
             aliquote aliq
       where ogim.oggetto_imposta = a_oggetto_imposta
         and ogim.oggetto_pratica = ogpr.oggetto_pratica
         and ogpr.oggetto = ogge.oggetto
         and ogim.tipo_tributo = aliq.tipo_tributo (+)
         and ogim.anno = aliq.anno (+)
         and ogim.tipo_aliquota = aliq.tipo_aliquota (+);
    exception
      when others then
        w_anno              := to_number(null);
        w_tipo_oggetto      := to_number(null);
        w_categoria_catasto := null;
        w_tipo_aliquota     := to_number(null);
        w_aliquota_erariale := to_number(null);
        w_flag_fabb_merce   := null;
    end;
    if w_tipo_aliquota is null then
       -- Si verifica se per l'oggetto_imposta esistono oggetti_ogim
       begin
         select ogog.tipo_aliquota
           into w_tipo_aliquota
           from oggetti_ogim    ogog
              , oggetti_imposta ogim
          where ogim.oggetto_imposta = a_oggetto_imposta
            and ogim.oggetto_pratica = ogog.oggetto_pratica
            and ogim.cod_fiscale = ogog.cod_fiscale
            and ogim.anno = ogog.anno
            and ogog.sequenza = (select min(ogox.sequenza)
                                   from oggetti_ogim ogox
                                  where ogox.cod_fiscale = ogog.cod_fiscale
                                    and ogox.anno = ogog.anno
                                    and ogox.oggetto_pratica = ogog.oggetto_pratica);
       exception
         when others then
           w_tipo_aliquota := null;
       end;
    end if;
    -- Tipo aliquota non determinabile - codice tributo F24 non determinabile
    if w_tipo_aliquota is null then
       --d_return := '0000';
       --return d_return;
       w_tipo_aliquota := -1;
    end if;
    if a_destinatario = 'C' then
       -- Abitazione principale
       if w_tipo_aliquota = 2 then
          d_return := '3912';
       elsif
          w_tipo_aliquota <> 2 and
          w_tipo_oggetto not in (1,2) and
          (w_categoria_catasto = 'D10' or
          w_aliquota_erariale is null) and
          w_flag_fabb_merce <> 'S' then
          d_return := '3913';
       elsif
          w_tipo_oggetto = 1 then
          d_return := '3914';
       elsif
          w_tipo_oggetto = 2 then
          d_return := '3916';
       elsif
         (w_anno >= 2013 and
          w_tipo_oggetto not in (1,2) and
          w_aliquota_erariale is not null and
          substr(w_categoria_catasto,1,1) <> 'D' and
          w_flag_fabb_merce <> 'S') or
         (w_anno < 2012 and
          w_aliquota_erariale is not null and
          w_tipo_aliquota <> 2) then
          d_return := '3918';
       elsif
          w_anno >= 2013 and
          w_tipo_oggetto not in (1,2) and
          w_aliquota_erariale is not null and
          substr(w_categoria_catasto,1,1) = 'D' and
          w_flag_fabb_merce <> 'S' then
          d_return := '3930';
       elsif
          w_anno >= 2020 and
          w_flag_fabb_merce = 'S' then
          d_return := '3939';
       end if;
    end if;
   if a_destinatario = 'S' then
      if w_tipo_oggetto = 1 then
         d_return := '3915';
      elsif
         w_tipo_oggetto = 2 then
         d_return := '3917';
      elsif
        (w_anno >= 2013 and
         w_tipo_oggetto not in (1,2) and
         w_aliquota_erariale is not null and
         substr(w_categoria_catasto,1,1) <> 'D' and
         w_flag_fabb_merce <> 'S') or
        (w_anno < 2012 and
         w_aliquota_erariale is not null and
         w_tipo_aliquota <> 2) then
         d_return := '3919';
       elsif
          w_anno >= 2013 and
          w_tipo_oggetto not in (1,2) and
          w_aliquota_erariale is not null and
          substr(w_categoria_catasto,1,1) = 'D' and
          w_flag_fabb_merce <> 'S' then
          d_return := '3925';
      end if;
   end if;
   if d_return is null then
      d_return := '0000';
   end if;

   return d_return;

  end;

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

  function eredi
  ( a_ni_deceduto           number default -1
  , a_ni_erede_da_escludere number default -1
  ) return sys_refcursor is
    rc         sys_refcursor;
  begin
    rc := stampa_common.eredi(a_ni_deceduto,a_ni_erede_da_escludere);
    return rc;
  end;

end STAMPA_ACCERTAMENTI_ICI;
/
