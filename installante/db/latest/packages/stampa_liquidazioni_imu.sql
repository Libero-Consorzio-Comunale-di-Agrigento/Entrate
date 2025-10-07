--liquibase formatted sql 
--changeset abrandolini:20250326_152429_stampa_liquidazioni_imu stripComments:false runOnChange:true 
 
create or replace package stampa_liquidazioni_imu is
/******************************************************************************
 NOME:        STAMPA_LIQUIDAZIONI_IMU
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
   000   xx/xx/xxxx  xx      Versione iniziale
   001   14/02/2023  RV      #41758
                             Scomposizione codici F24 3924/3918 per ICI e
                             scomposizione codici F24 3963/3961 per TASI
                             (Viene richiamato da STAMPA_LIQUIDAZIONI_TASI)
   002   09/06/2023  AB      #65140
                             Sistemati i campi di riepilogo nella importi_riep
                             e nelle importi_riep_comune
   003   31/07/2023  DM      issue #66215: aggiunti nvl in calcoli
                             importi_riep_deim_comune e importi_riep_deim_stato
   004   02/08/2023  DM      issue #66215: corretta formattazione a 0 dell'importo
                             in acconto
   005   17/08/2023  AB      #65140: aggiunti due campi _Arr relativi al comune
                             che mancavano, ed erano i doppi eliminati in precedenza
                             che non avevano il nome corretto
   006   06/11/2023  RV      #66896
                             Aggiunto valori arrotondati in versamenti e importi_riep
   007   09/04/2024  RV      #71628
                             Rivisto IMMOBILI e RIOG per campi categoria e classe
   008   29/05/2024  RV      #71595
                             Rivisto IMMOBILI per campo imm_storico
   009   14/06/2024  RV      #55525
                             Aggiunto INTERESSI_DETTAGLIO
   010  11/02/2025           #78514
                             Aggiunta formattazione per campi IMPOSTA_EVASA_STR e IMPORTO_STR
*****************************************************************************/
  function contribuente(a_pratica  number default -1
                      , a_ni_erede            number default -1) return sys_refcursor;
  function immobili(a_cf           varchar2 default '',
                    a_pratica      number default -1,
                    a_tipi_oggetto varchar2 default '',
                    a_modello      number default -1) return sys_refcursor;
  function riog(a_pratica number default -1,
                p_anno    number default -1,
                a_oggetto number default -1) return sys_refcursor;
  function imposta_denuncia(a_pratica         number default -1,
                            a_oggetto_pratica number default -1,
                            a_subtesto        varchar2 default '')
    return sys_refcursor;
  function imposta_rendita(a_pratica         number default -1,
                           a_oggetto_pratica number default -1,
                           a_subtesto        varchar2 default '')
    return sys_refcursor;
  function versamenti(a_cf      varchar2 default '',
                      a_pratica number default -1,
                      a_anno    number default -1) return sys_refcursor;
  function versamenti_vuoto(a_cf      varchar2 default '',
                            a_pratica number default -1,
                            a_anno    number default -1) return sys_refcursor;
  function importi_comune_stato(a_pratica      number,
                                a_tipo_importo varchar2,
                                a_tipo_ente    varchar2) return number;
  function importi_riep(a_cf      varchar2 default '',
                        a_pratica number default -1,
                        a_anno    number default -1,
                        a_data    varchar2 default '') return sys_refcursor;
  function importi_riep_deim_comune(a_cf             varchar2 default '',
                                    a_pratica        number default -1,
                                    a_anno           number default -1,
                                    a_data           varchar2 default '',
                                    a_tot_dovuto     varchar2 default '',
                                    a_tot_versato    varchar2 default '',
                                    a_tot_differenza varchar2 default '',
                                    a_st_comune      varchar2 default '')
    return sys_refcursor;
  function importi_riep_deim_stato(a_cf             varchar2 default '',
                                   a_pratica        number default -1,
                                   a_anno           number default -1,
                                   a_data           varchar2 default '',
                                   a_tot_dovuto     varchar2 default '',
                                   a_tot_versato    varchar2 default '',
                                   a_tot_differenza varchar2 default '',
                                   a_st_stato       varchar2 default '')
    return sys_refcursor;
  function importi_riep_acconto_saldo(a_pratica number default -1)
    return sys_refcursor;
  function importi(a_pratica      number default -1,
                   a_modello      number default -1,
                   a_modello_rimb number default -1) return sys_refcursor;
  function sanzioni(a_pratica number default -1) return sys_refcursor;
  function interessi(a_pratica number default -1) return sys_refcursor;
  function interessi_dettaglio
  ( a_pratica               number default -1
  , a_modello               number default -1
  ) return sys_refcursor;
  function riepilogo_dovuto(a_pratica number default -1,
                            a_modello number default -1) return sys_refcursor;
  function riepilogo_da_versare(a_pratica number default -1)
    return sys_refcursor;
  function interessi_g_applicati(a_tipo_tributo varchar2 default '',
                                 a_anno         number default -1,
                                 a_data         varchar2 default '')
    return sys_refcursor;
  function principale(a_cf           varchar2 default '',
                      a_vett_prat    varchar2 default '',
                      a_modello      number default -1,
                      a_modello_rimb number default -1,
                      a_ni_erede     number default -1) return sys_refcursor;
  function aggi_dilazione(a_pratica number default -1,
                          a_modello number default -1) return sys_refcursor;
  function eredi(a_pratica        number default -1,
                 a_ni_primo_erede number default -1) return sys_refcursor;
  function F_GET_COD_TRIBUTO_F24(a_oggetto_imposta number,
                                 a_destinatario    varchar2) return varchar2;
end stampa_liquidazioni_imu;
/
create or replace package body stampa_liquidazioni_imu is
/******************************************************************************
 NOME:        STAMPA_LIQUIDAZIONI_IMU
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
   000   xx/xx/xxxx  xx      Versione iniziale
   001   14/02/2023  RV      #41758
                             Scomposizione codici F24 3924/3918 per ICI e
                             scomposizione codici F24 3963/3961 per TASI
                             (Viene richiamato da STAMPA_LIQUIDAZIONI_TASI)
   002   09/06/2023  AB      #65140
                             Sistemati i campi di riepilogo nella importi_riep
                             e nelle importi_riep_comune
   003   31/07/2023  DM      issue #66215: aggiunti nvl in calcoli
                             importi_riep_deim_comune e importi_riep_deim_stato
   004   02/08/2023  DM      issue #66215: corretta formattazione a 0 dell'importo
                             in acconto
   005   17/08/2023  AB      #65140: aggiunti due campi _Arr relativi al comune
                             che mancavano, ed erano i doppi eliminati in precedenza
                             che non avevano il nome corretto
   006   06/11/2023  RV      #66896
                             Aggiunto valori arrotondati in versamenti e importi_riep
   007   09/04/2024  RV      #71628
                             Rivisto IMMOBILI e RIOG per campi categoria e classe
   008   29/05/2024  RV      #71595
                             Rivisto IMMOBILI per campo imm_storico
   009   14/06/2024  RV      #55525
                             Aggiunto INTERESSI_DETTAGLIO
*****************************************************************************/
  function contribuente
  ( a_pratica              number
  , a_ni_erede            number default -1
  ) return sys_refcursor is
    rc sys_refcursor;
  begin
    rc := stampa_common.contribuente(a_pratica, a_ni_erede);
    return rc;
  end;
------------------------------------------------------------------
  function immobili(a_cf varchar2,
                    a_pratica number,
                    a_tipi_oggetto varchar2,
                    a_modello number default -1) return sys_refcursor is
    rc sys_refcursor;
  begin
    open rc for
      select stampa_common.f_formatta_numero(importo1_acconto_num,'I') importo1_acconto,
             stampa_common.f_formatta_numero(decode(nvl(importo1_num, 0),
                                      0,importo1_num,
                                        importo1_num - nvl(importo1_acconto_num, 0)),
                               'I'
                              ) importo1_saldo,
             stampa_common.f_formatta_numero(importo2_acconto_num,'I') importo2_acconto,
             stampa_common.f_formatta_numero(decode(nvl(importo2_num, 0),
                                      0,importo2_num,
                                        importo1_num - nvl(importo1_acconto_num, 0)),
                               'I'
                              ) importo2_saldo,
             imp.*,
             -- Alias per compatibilita con i modelli esistenti
             imp.cat_ogg cat,
             imp.classe_ren classe,
             --
             a_modello
        from (select distinct
                     -- CAMPI AGGIUNTI --
                     a_pratica as pratica,
                     ogim.imposta_dovuta importo1_num,
                     ogim.imposta_dovuta_acconto importo1_acconto_num,
                     decode(prtr.tipo_tributo,'ICI',
                            decode(nvl(ogim.imposta, 0),
                            nvl(ogim.imposta_dovuta, 0),
                            to_number(null),
                            ogim.imposta),
                            ogim.imposta) importo2_num,
                     decode(prtr.tipo_tributo,'ICI',
                            decode(nvl(ogim.imposta_acconto, 0),
                            nvl(ogim.imposta_dovuta_acconto, 0),
                            to_number(null),
                            ogim.imposta),
                            ogim.imposta_acconto) importo2_acconto_num,
                     -- FINE CAMPI AGGIUNTI --
                     ogpr.oggetto_pratica,
                     decode(f_conta_costi_storici(ogpr.oggetto_pratica),
                            0,
                            '',
                            '[COSTI_STORICI') costi_storici,
                     decode(ogim.tipo_aliquota,
                            null,
                            '',
                            ' (' || stampa_common.f_formatta_numero(ogim.aliquota,'I','S') || ')'
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
                     lpad(nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto),
                          2) tipo_oggetto,
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
                     lpad(nvl(ogge.categoria_catasto, ' '), 4) cat_ogg,
                     lpad(nvl(ogge.classe_catasto, ' '), 6) classe_ogg,
                     lpad(nvl(nvl(ogpr.categoria_catasto,ogge.categoria_catasto), ' '), 4) cat_liq,
                     lpad(nvl(nvl(ogpr.classe_catasto,ogge.classe_catasto), ' '), 6) classe_liq,
                     lpad(nvl(ogge.partita, ' '), 8) partita,
                     lpad(nvl(ogge.sezione, ' '), 4) sezione,
                     lpad(nvl(ogge.foglio, ' '), 6) foglio,
                     lpad(nvl(ogge.numero, ' '), 6) numero,
                     lpad(nvl(ogge.subalterno, ' '), 4) subalterno,
                     lpad(nvl(ogge.zona, ' '), 4) zona,
                     stampa_common.f_formatta_numero(ogge.superficie,'I') superficie,
                     lpad(nvl(ogge.protocollo_catasto, ' '), 6) prot_cat,
                     lpad(nvl(to_char(ogge.anno_catasto), ' '), 4) anno_cat,
                     stampa_common.f_formatta_numero(ogpr_dic.valore,'I','S') valore_dic,
                     decode(nvl(f_descrizione_timp(a_modello,'DATI_DIC'),'NO'),
                            'NO',null,
                                 'CALCOLATO PER L''ANNO DI RIFERIMENTO'
                           ) st_valore_riv,
                     decode(nvl(f_descrizione_timp(a_modello,'DATI_DIC'),'NO'),
                            'NO',null,
                            stampa_common.f_formatta_numero(
                                          f_valore(ogpr_dic.valore,
                                                   nvl(ogpr_dic.tipo_oggetto, ogge.tipo_oggetto),
                                                   prtr_dic.anno,
                                                   ogim.anno,
                                                   nvl(ogpr_dic.categoria_catasto, ogge.categoria_catasto),
                                                   prtr_dic.tipo_pratica,
                                                   ogpr_dic.flag_valore_rivalutato),
                                                            'I','S')
                           ) valore_riv,
                     decode(nvl(f_descrizione_timp(a_modello,'DATI_DIC'),'NO'),
                            'NO',null,
                            stampa_common.f_formatta_numero(f_rendita(f_valore(ogpr_dic.valore,
                                                         nvl(ogpr_dic.tipo_oggetto,
                                                             ogge.tipo_oggetto),
                                                         prtr_dic.anno,
                                                         ogim.anno,
                                                         nvl(ogpr_dic.categoria_catasto,
                                                             ogge.categoria_catasto),
                                                         prtr_dic.tipo_pratica,
                                                         ogpr_dic.flag_valore_rivalutato),
                                                nvl(ogpr_dic.tipo_oggetto,
                                                    ogge.tipo_oggetto),
                                                prtr.anno,
                                                nvl(ogpr_dic.categoria_catasto,
                                                    ogge.categoria_catasto)),
                                      'I','S'
                                     )) rendita_valore_riv,
                     decode(ogpr.valore,
                            null,
                            /*decode(prtr.tipo_tributo,
                                   'ICI','SULLA BASE DELLA RENDITA DEFINITIVA',*/
                                          f_descrizione_timp(a_modello,'DES_RIS_CAT')
                                 -- )
                                 ,
                            null) st_pre_riog,
                     decode(ogpr.valore,
                            null, null,
                            /*decode(prtr.tipo_tributo,
                                  'ICI',
                                   -- Prompt ST_VALORE_SUBASE per ICI/IMU
                                  decode(ogpr.valore,
                                         ogpr_dic.valore, null,
                                         f_valore(ogpr_dic.valore
                                                 ,nvl(ogpr_dic.tipo_oggetto, ogge.tipo_oggetto)
                                                 ,prtr_dic.anno
                                                 ,ogim.anno
                                                 ,nvl(ogpr_dic.categoria_catasto,ogge.categoria_catasto)
                                                 ,prtr_dic.tipo_pratica
                                                 ,ogpr_dic.flag_valore_rivalutato), null,
                                         'SULLA BASE DELLA RENDITA DEFINITIVA'),*/
                                  -- Prompt ST_VALORE_SUBASE per TASI
                            decode(f_descrizione_timp(a_modello,'DATI_DIC'),
                                   'NO',f_descrizione_timp(a_modello,'DES_RIS_CAT'),
                                   decode(ogpr.valore,
                                          ogpr_dic.valore, null,
                                          f_valore(ogpr_dic.valore
                                                  ,nvl(ogpr_dic.tipo_oggetto, ogge.tipo_oggetto)
                                                  ,prtr_dic.anno
                                                  ,ogim.anno
                                                  ,nvl(ogpr_dic.categoria_catasto
                                                      ,ogge.categoria_catasto)
                                                  ,prtr_dic.tipo_pratica
                                                  ,ogpr_dic.flag_valore_rivalutato), null,
                                          f_descrizione_timp(a_modello,'DES_RIS_CAT')
                                         )
                                  )
                               -- )
                           ) st_valore_subase,
                     decode(ogpr.valore,
                            null, null,
                            /*decode(prtr.tipo_tributo,
                                   'ICI',
                                   -- valore per ICI/IMU
                                   decode(ogpr.valore
                                         ,ogpr_dic.valore, null
                                         ,f_valore(ogpr_dic.valore
                                                  ,nvl(ogpr_dic.tipo_oggetto, ogge.tipo_oggetto)
                                                  ,prtr_dic.anno
                                                  ,ogim.anno
                                                  ,nvl(ogpr_dic.categoria_catasto,ogge.categoria_catasto)
                                                  ,prtr_dic.tipo_pratica
                                                  ,ogpr_dic.flag_valore_rivalutato), null
                                         ,stampa_common.f_formatta_numero(ogpr.valore,'I','S')
                                         ), */
                                   -- valore per TASI
                            decode(f_descrizione_timp(a_modello,'DATI_DIC'),
                                   'NO',stampa_common.f_formatta_numero(ogpr.valore,'I','S'),
                                   decode(ogpr.valore,
                                          ogpr_dic.valore, null,
                                          f_valore(ogpr_dic.valore
                                                  ,nvl(ogpr_dic.tipo_oggetto,ogge.tipo_oggetto)
                                                  ,prtr_dic.anno
                                                  ,ogim.anno
                                                  ,nvl(ogpr_dic.categoria_catasto,ogge.categoria_catasto)
                                                  ,prtr_dic.tipo_pratica
                                                  ,ogpr_dic.flag_valore_rivalutato
                                                  ), null,
                                          stampa_common.f_formatta_numero(ogpr.valore,'I','S')
                                         )
                                  )
                                  --)
                           ) valore_subase,
                     decode(ogpr.valore,
                            null,null,
                            /*decode(prtr.tipo_tributo,
                                   'ICI',
                                   -- rendita per IMU/ICI
                                   decode(ogpr.valore,
                                          ogpr_dic.valore,null,
                                          f_valore(ogpr_dic.valore,
                                                   nvl(ogpr_dic.tipo_oggetto,ogge.tipo_oggetto),
                                                   prtr_dic.anno,
                                                   ogim.anno,
                                                   nvl(ogpr_dic.categoria_catasto,ogge.categoria_catasto),
                                                   prtr_dic.tipo_pratica,
                                                   ogpr_dic.flag_valore_rivalutato
                                                   ),null,
                                          decode(f_rendita_anno_riog(ogpr.oggetto,prtr.anno),
                                                 null,'',
                                                 stampa_common.f_formatta_numero(
                                                               f_rendita_anno_riog(ogpr.oggetto,prtr.anno),
                                                                                'I'
                                                                                )
                                                )
                                         ), */
                                   -- rendita TASI
                            decode(nvl(ogpr_dic.tipo_oggetto,ogge.tipo_oggetto),
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
                                          ogpr_dic.valore, null,
                                          f_valore(ogpr_dic.valore,
                                                   nvl(ogpr_dic.tipo_oggetto, ogge.tipo_oggetto),
                                                   prtr_dic.anno,
                                                   ogim.anno,
                                                   nvl(ogpr_dic.categoria_catasto,ogge.categoria_catasto),
                                                   prtr_dic.tipo_pratica,
                                                   ogpr_dic.flag_valore_rivalutato
                                                   ), null,
                                          decode(f_rendita_anno_riog(ogpr.oggetto, prtr.anno),
                                                 null, null,
                                                 stampa_common.f_formatta_numero(
                                                               f_rendita_anno_riog(ogpr.oggetto,prtr.anno),
                                                                                 'I')
                                                )
                                         )
                                  )
                                 -- )
                           )) rendita_valore_subase,
                     decode(ogco.perc_possesso,
                            null,'',
                            stampa_common.f_formatta_numero(ogco.perc_possesso,'I','S') || '%'
                           ) perc_poss,
                     to_char(nvl(ogco.mesi_possesso, 12), '99') mp,
                     decode(nvl(ogco.mesi_riduzione, 0),
                            0,'',
                              to_char(ogco.mesi_riduzione, '99')) mr,
                     decode(nvl(ogco.mesi_esclusione, 0),
                            0,'',
                              to_char(ogco.mesi_esclusione, '99')) me,
                     decode(ogim.detrazione,
                            null,'',
                                 'DETRAZIONE APPLICATA: ') detr,
                     stampa_common.f_formatta_numero(ogim.detrazione,'I') detrazione,
                     rpad(decode(ogco_dic.detrazione,
                                 null,'',
                                      'DETRAZIONE DICHIARATA'),
                                   54) detr_dic,
                              stampa_common.f_formatta_numero(ogco_dic.detrazione,'I') detrazione_dic,
                     prtr.anno anno,
                     rpad('VALORE DICHIARATO', 54) st_valdic,
                     'PERCENTUALE POSSESSO:' st_percposs,
                     'MESI POSSESSO:' st_mesposs,
                     decode(nvl(ogco.mesi_riduzione, 0),
                            0,'',
                            'MESI RIDUZIONE') st_mesrid,
                     decode(nvl(ogco.mesi_esclusione, 0),
                            0,'',
                            'MESI ESCLUSIONE') st_mesescl,
                     decode(f_cate_riog_null(ogpr.oggetto,prtr.anno),
                            null,null,
                            rpad('CAT. CATASTALE SULLA BASE DELLA RENDITA DEFINITIVA',
                                 54)) st_catren,
                     decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto),
                            1,'',
                            'Classe') st_int_classeriog,
                     decode(ogpr.valore,
                            null,null,
                            decode(f_descrizione_timp(a_modello,'DATI_DIC'),
                                   'NO',nvl(f_cate_riog_null(ogpr.oggetto, prtr.anno),
                                            nvl(ogpr.categoria_catasto,ogge.categoria_catasto)),
                                        decode(ogpr.valore,
                                               ogpr_dic.valore, null,
                                               f_valore(ogpr_dic.valore,
                                                        nvl(ogpr_dic.tipo_oggetto, ogge.tipo_oggetto),
                                                        prtr_dic.anno,
                                                        ogim.anno,
                                                        nvl(ogpr_dic.categoria_catasto,ogge.categoria_catasto),
                                                        prtr_dic.tipo_pratica,
                                                        ogpr_dic.flag_valore_rivalutato
                                                       ), null,
                                               nvl(f_cate_riog_null(ogpr.oggetto, prtr.anno), ' ')
                                              )
                                  )
                           ) cat_ren,
                     decode(ogpr.valore,
                            null,null,
                            decode(f_descrizione_timp(a_modello,'DATI_DIC'),
                                   'NO',nvl(f_classe_riog_null(ogpr.oggetto, prtr.anno),
                                            nvl(ogpr.classe_catasto,ogge.classe_catasto)),
                                        decode(ogpr.valore,
                                               ogpr_dic.valore, null,
                                               f_valore(ogpr_dic.valore,
                                                        nvl(ogpr_dic.tipo_oggetto, ogge.tipo_oggetto),
                                                        prtr_dic.anno,
                                                        ogim.anno,
                                                        nvl(ogpr_dic.categoria_catasto,ogge.categoria_catasto),
                                                        prtr_dic.tipo_pratica,
                                                        ogpr_dic.flag_valore_rivalutato
                                                       ), null,
                                               nvl(f_classe_riog_null(ogpr.oggetto, prtr.anno), ' ')
                                              )
                                  )
                           ) classe_ren,
                     decode(ogpr_dic.categoria_catasto,
                            null,null,
                            rpad('CAT. CATASTALE DICHIARATA', 54)) st_catdic,
                     decode(nvl(f_descrizione_timp(a_modello,'DATI_DIC'),'NO'),
                            'NO',null,
                            nvl(ogpr_dic.categoria_catasto, ' ')) cat_dic,
                     /*decode(prtr.tipo_tributo,
                            'ICI',
                            -- IMPOSTA_TESTO1 per ICI/IMU
                            decode(nvl(ogim.imposta_dovuta, 0),
                                   nvl(ogim.imposta, 0),
                                   'IMPOSTA CALCOLATA' ||
                                   decode(ogim.imposta_mini,
                                          null,'',
                                          ' (MINI IMU 2013)') ||
                                   decode(nvl(ogim.imposta_dovuta, 0),
                                          0,' : 0',
                                          ''),
                                   'IMPOSTA CALCOLATA SULLA BASE DELLA DENUNCIA' ||
                                   decode(ogim.imposta_mini,
                                          null,'',
                                          ' (MINI IMU 2013)')),*/
                            -- IMPOSTA_TESTO1 per TASI
                     decode(nvl(f_descrizione_timp(a_modello,'DATI_DIC'),'NO'),
                            'NO',null,
                            'IMPOSTA CALCOLATA '||
                            f_descrizione_timp(a_modello,'DES_RIS_CAT')
                           ) imposta_testo1,
                     decode(ogim.imposta_mini,
                            null,'',
                            '(MINI IMU 2013)') st_mini_imu,
                     decode(nvl(ogim.imposta_dovuta, 0),
                            0,'',
                            '   Dettaglio codici tributo per versamento:') imposta_subtesto1,
                     decode(nvl(ogim.imposta_dovuta, 0),
                            0,'',
                            stampa_common.f_formatta_numero(ogim.imposta_dovuta,'I')) importo1,
                     decode(nvl(ogim.imposta_dovuta, 0),
                            0,'',
                            lpad('_________________', 72)) linea_importo1,
                     /*decode(prtr.tipo_tributo,'ICI',
                            -- IMPOSTA_TESTO2 per IMU/ICI
                            decode(nvl(ogim.imposta, 0),
                                   nvl(ogim.imposta_dovuta, 0),null,
                                   'IMPOSTA CALCOLATA SULLA BASE DELLA RENDITA DEFINITIVA' ||
                                   decode(nvl(ogim.imposta_dovuta, 0),
                                          0,' : 0',
                                          '')), */
                            -- IMPOSTA TESTO2 per TASI
                            'IMPOSTA CALCOLATA '||
                            f_descrizione_timp(a_modello,'DES_RIS_CAT') ||
                            decode(nvl(ogim.imposta, 0),
                                   0,' : 0',
                                   '') imposta_testo2,
                     /*decode(prtr.tipo_tributo,
                            'TASI','   Dettaglio codici tributo per versamento:',
                            decode(nvl(ogim.imposta, 0),
                                   nvl(ogim.imposta_dovuta, 0),null, */
                                  '   Dettaglio codici tributo per versamento:' --)
                           --)
                           imposta_subtesto2,
                     decode(nvl(ogim.imposta, 0),
                            nvl(ogim.imposta_dovuta, 0),null,
                            lpad('_________________', 72)) linea_importo2,
                     /*decode(prtr.tipo_tributo,'ICI',
                            decode(nvl(ogim.imposta, 0),
                                   nvl(ogim.imposta_dovuta, 0),null,
                                   stampa_common.f_formatta_numero(ogim.imposta,'I','S')
                                  ), */
                            stampa_common.f_formatta_numero(ogim.imposta,'I','S')
                           -- )
                           importo2,
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
                      decode(ogpr.imm_storico,'S','S',' ') imm_storico,
                    ' ' x
                from tipi_aliquota        tial,
                     archivio_vie         arvi,
                     tipi_oggetto         tiog,
                     oggetti              ogge,
                     oggetti_contribuente ogco,
                     oggetti_pratica      ogpr,
                     oggetti_pratica      ogpr_dic,
                     pratiche_tributo     prtr_dic,
                     oggetti_contribuente ogco_dic,
                     oggetti_imposta      ogim,
                     pratiche_tributo     prtr,
                     dati_generali
               where (tial.tipo_aliquota =
                     nvl(ogim.tipo_aliquota, tial.tipo_aliquota))
                 and (tiog.tipo_oggetto =
                     nvl(ogpr.tipo_oggetto,
                          nvl(ogpr_dic.tipo_oggetto, ogge.tipo_oggetto)))
                 and (ogim.cod_fiscale = ogco.cod_fiscale)
                 and (ogim.oggetto_pratica = ogco.oggetto_pratica)
                 and (ogge.oggetto = ogpr.oggetto)
                 and (ogpr_dic.oggetto_pratica = ogpr.oggetto_pratica_rif)
                 and (prtr_dic.pratica = ogpr_dic.pratica)
                 and (ogpr_dic.oggetto_pratica = ogco_dic.oggetto_pratica)
                 and ogco_dic.cod_fiscale = a_cf
                 and (ogim.anno = prtr.anno)
                 and (arvi.cod_via(+) = ogge.cod_via)
                 and (ogpr.pratica = prtr.pratica)
                 and (ogpr.oggetto_pratica = ogco.oggetto_pratica)
                 and ogco.cod_fiscale = a_cf
                 and prtr.pratica = a_pratica
                 and tial.tipo_tributo = prtr.tipo_tributo
                 and instr(nvl(a_tipi_oggetto,'1,2,3,4')||',',
                           to_char(nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto))||',') > 0
               order by ogge.oggetto,
                        lpad(nvl(ogge.classe_catasto, ' '), 6),
                        lpad(nvl(ogge.sezione, ' '), 4),
                        lpad(nvl(ogge.foglio, ' '), 6),
                        lpad(nvl(ogge.numero, ' '), 6),
                        lpad(nvl(ogge.subalterno, ' '), 4)) imp;
    return rc;
  end;
------------------------------------------------------------------
  function riog(a_pratica number, p_anno number, a_oggetto number)
    return sys_refcursor is
    rc sys_refcursor;
  begin
    open rc for
      select distinct
             stampa_common.f_formatta_numero(
                           f_round(nvl(riog.rendita, 0) *
                                   decode(cat.tipo_oggetto,
                                          1,nvl(molt.moltiplicatore, 1),
                                          3,nvl(molt.moltiplicatore, 1),
                                          1
                                         ) * (100 + rire.aliquota) / 100,
                                   2),
                                             'I'
                                            ) valore,
             stampa_common.f_formatta_numero(riog.rendita,'I') rendita,
             to_char(riog.inizio_validita, 'DD/MM/YYYY') inizio_validita_char,
             to_char(riog.fine_validita, 'DD/MM/YYYY') fine_validita_char,
             riog.inizio_validita inizio_validita,
             riog.fine_validita fine_validita,
             cat.categoria_catasto categoria_catasto,
             cat.classe_catasto classe_catasto
        from riferimenti_oggetto riog,
             moltiplicatori molt,
             rivalutazioni_rendita rire,
             (select nvl(riog2.categoria_catasto,
                         nvl(ogpr2.categoria_catasto, ogge2.categoria_catasto)) categoria_catasto,
                     nvl(riog2.classe_catasto,
                         nvl(ogpr2.classe_catasto, ogge2.classe_catasto)) classe_catasto,
                     riog2.inizio_validita inizio_validita,
                     nvl(ogpr2.tipo_oggetto, ogge2.tipo_oggetto) tipo_oggetto
                from riferimenti_oggetto riog2,
                     oggetti_pratica     ogpr2,
                     oggetti             ogge2
               where riog2.oggetto = a_oggetto
                 and ogpr2.oggetto = a_oggetto
                 and ogpr2.pratica = a_pratica
                 and ogge2.oggetto = a_oggetto
               order by riog2.inizio_validita) cat
       where cat.categoria_catasto = molt.categoria_catasto(+)
         and cat.inizio_validita = riog.inizio_validita
         and molt.anno(+) = p_anno
         and riog.oggetto = a_oggetto
         and rire.anno = p_anno
         and rire.tipo_oggetto = cat.tipo_oggetto
         and p_anno between riog.da_anno and riog.a_anno
       order by riog.inizio_validita;
    return rc;
  end;
------------------------------------------------------------------
  function imposta_denuncia(a_pratica         number,
                            a_oggetto_pratica number,
                            a_subtesto        varchar2) return sys_refcursor is
    rc sys_refcursor;
  begin
    open rc for
      select imm.*,
             a_subtesto as subtesto,
             stampa_common.f_formatta_numero(imposta_num,'I','S') imposta,
             stampa_common.f_formatta_numero(imposta_acconto_num,'I','S') imposta_acconto,
             stampa_common.f_formatta_numero((imposta_num - imposta_acconto_num),'I','S') imposta_saldo,
             stampa_common.f_formatta_numero(sum(imposta_num) over(),'I','S') imposta_tot,
             stampa_common.f_formatta_numero(sum(imposta_acconto_num) over(),'I','S') imposta_acconto_tot,
             stampa_common.f_formatta_numero(sum(imposta_num - imposta_acconto_num)
                                    over(),'I','S') imposta_saldo_tot
        from (select --
               sum(nvl(ogim.imposta_dovuta, 0)) imposta_num,
               sum(nvl(ogim.imposta_dovuta_acconto, 0)) imposta_acconto_num,
                     --
               '3912' codice_tributo,
               rpad('IMU - AB. PRINC. E PERTINENZE - COMUNE', 44) des_tributo
                from oggetti_imposta ogim,
                     oggetti_pratica ogpr,
                     oggetti         ogge
               where ogpr.oggetto_pratica = ogim.oggetto_pratica
                 and ogpr.oggetto = ogge.oggetto
                 and ogpr.pratica = a_pratica
                 and ogpr.oggetto_pratica = a_oggetto_pratica
                 and f_get_cod_tributo_f24(ogim.oggetto_imposta,'C') = '3912'
              having sum(nvl(ogim.imposta_dovuta, 0)) != 0
              union
              select --
               sum(nvl(ogim.imposta_dovuta, 0)),
               sum(nvl(ogim.imposta_dovuta_acconto, 0)),
                     --
               '3913' codice_tributo,
               rpad('IMU - FABB. RUR. AD USO STRUMENTALE - COMUNE', 44) des_tributo
                from oggetti_imposta ogim,
                     oggetti_pratica ogpr,
                     oggetti         ogge
               where ogpr.oggetto_pratica = ogim.oggetto_pratica
                 and ogpr.oggetto = ogge.oggetto
                 and ogpr.pratica = a_pratica
                 and ogpr.oggetto_pratica = a_oggetto_pratica
                 and f_get_cod_tributo_f24(ogim.oggetto_imposta,'C') = '3913'
              having sum(nvl(ogim.imposta_dovuta, 0)) != 0
              union
              select --
               sum(nvl(ogim.imposta_dovuta, 0) -
                   nvl(ogim.imposta_erariale_dovuta, 0)),
               sum(nvl(ogim.imposta_dovuta_acconto, 0) -
                   nvl(ogim.imposta_erariale_dovuta_acc, 0)),
                     --
               '3914' codice_tributo,
               rpad('IMU - TERRENI - COMUNE', 44) des_tributo
                from oggetti_imposta ogim,
                     oggetti_pratica ogpr,
                     oggetti         ogge
               where ogpr.oggetto_pratica = ogim.oggetto_pratica
                 and ogpr.oggetto = ogge.oggetto
                 and ogpr.pratica = a_pratica
                 and ogpr.oggetto_pratica = a_oggetto_pratica
                 and f_get_cod_tributo_f24(ogim.oggetto_imposta,'C') = '3914'
               having
               sum(nvl(ogim.imposta_dovuta, 0) -
                   nvl(ogim.imposta_erariale_dovuta, 0)) != 0
              union
              select --
               sum(nvl(ogim.imposta_erariale_dovuta, 0)),
               sum(nvl(ogim.imposta_erariale_dovuta_acc, 0)),
                     --
               '3915' codice_tributo,
               rpad('IMU - TERRENI - STATO', 44) des_tributo
                from oggetti_imposta ogim,
                     oggetti_pratica ogpr,
                     oggetti         ogge
               where ogpr.oggetto_pratica = ogim.oggetto_pratica
                 and ogpr.oggetto = ogge.oggetto
                 and ogpr.pratica = a_pratica
                 and ogpr.oggetto_pratica = a_oggetto_pratica
                 and f_get_cod_tributo_f24(ogim.oggetto_imposta,'S') = '3915'
               having sum(nvl(ogim.imposta_erariale_dovuta, 0)) != 0
              union
              select --
               sum(nvl(ogim.imposta_dovuta, 0) -
                   nvl(ogim.imposta_erariale_dovuta, 0)),
               sum(nvl(ogim.imposta_dovuta_acconto, 0) -
                   nvl(ogim.imposta_erariale_dovuta_acc, 0)),
                     --
               '3916' codice_tributo,
               rpad('IMU - AREE FABBRICABILI - COMUNE', 44) des_tributo
                from oggetti_imposta ogim,
                     oggetti_pratica ogpr,
                     oggetti         ogge
               where ogpr.oggetto_pratica = ogim.oggetto_pratica
                 and ogpr.oggetto = ogge.oggetto
                 and ogpr.pratica = a_pratica
                 and ogpr.oggetto_pratica = a_oggetto_pratica
                 and f_get_cod_tributo_f24(ogim.oggetto_imposta,'C') = '3916'
               having
               sum(nvl(ogim.imposta_dovuta, 0) -
                   nvl(ogim.imposta_erariale_dovuta, 0)) != 0
              union
              select --
               sum(nvl(ogim.imposta_erariale_dovuta, 0)),
               sum(nvl(ogim.imposta_erariale_dovuta_acc, 0)),
                     --
               '3917' codice_tributo,
               rpad('IMU - AREE FABBRICABILI - STATO', 44) des_tributo
                from oggetti_imposta ogim,
                     oggetti_pratica ogpr,
                     oggetti         ogge
               where ogpr.oggetto_pratica = ogim.oggetto_pratica
                 and ogpr.oggetto = ogge.oggetto
                 and ogpr.pratica = a_pratica
                 and ogpr.oggetto_pratica = a_oggetto_pratica
                 and f_get_cod_tributo_f24(ogim.oggetto_imposta,'S') = '3917'
               having sum(nvl(ogim.imposta_erariale_dovuta, 0)) != 0
              union
              select --
               f_altri_importo(a_pratica,
                               a_oggetto_pratica,
                               'COMUNE',
                               ogpr.anno,
                               'DOVUTA'),
               f_altri_importo_acconto(a_pratica,
                                       a_oggetto_pratica,
                                       'COMUNE',
                                       ogpr.anno,
                                       'DOVUTA'),
               --
               '3918' codice_tributo,
               rpad('IMU - ALTRI FABBRICATI - COMUNE', 44) des_tributo
                from oggetti_imposta ogim,
                     oggetti_pratica ogpr,
                     oggetti         ogge
               where ogpr.oggetto_pratica = ogim.oggetto_pratica
                 and ogpr.oggetto = ogge.oggetto
                 and ogpr.pratica = a_pratica
                 and ogpr.oggetto_pratica = a_oggetto_pratica
                 and f_get_cod_tributo_f24(ogim.oggetto_imposta,'C') = '3918'
                 and f_altri_importo(a_pratica,
                                     a_oggetto_pratica,
                                     'COMUNE',
                                     ogpr.anno,
                                     'DOVUTA') > 0
              union
              select --
               f_altri_importo(a_pratica,
                               a_oggetto_pratica,
                               'STATO',
                               ogpr.anno,
                               'DOVUTA'),
               f_altri_importo_acconto(a_pratica,
                                       a_oggetto_pratica,
                                       'STATO',
                                       ogpr.anno,
                                       'DOVUTA'),
               --
               '3919' codice_tributo,
               rpad('IMU - ALTRI FABBRICATI - STATO', 44) des_tributo
                from oggetti_imposta ogim,
                     oggetti_pratica ogpr,
                     oggetti         ogge
               where ogpr.oggetto_pratica = ogim.oggetto_pratica
                 and ogpr.oggetto = ogge.oggetto
                 and ogpr.pratica = a_pratica
                 and ogpr.oggetto_pratica = a_oggetto_pratica
                 and f_get_cod_tributo_f24(ogim.oggetto_imposta,'S') = '3919'
                 and f_altri_importo(a_pratica,
                                     a_oggetto_pratica,
                                     'STATO',
                                     ogpr.anno,
                                     'DOVUTA') > 0
              union
              select --
               sum(nvl(ogim.imposta_dovuta, 0) -
                   nvl(ogim.imposta_erariale_dovuta, 0)),
               sum(nvl(ogim.imposta_dovuta_acconto, 0) -
                   nvl(ogim.imposta_erariale_dovuta_acc, 0)),
                     --
               '3930' codice_tributo,
               rpad('IMU - IMM. PROD. (GR. CAT. D) - INCR. COMUNE', 44) des_tributo
                from oggetti_imposta ogim,
                     oggetti_pratica ogpr,
                     oggetti         ogge
               where ogpr.oggetto_pratica = ogim.oggetto_pratica
                 and ogpr.oggetto = ogge.oggetto
                 and ogpr.pratica = a_pratica
                 and ogpr.oggetto_pratica = a_oggetto_pratica
                 and f_get_cod_tributo_f24(ogim.oggetto_imposta,'C') = '3930'
                 and ogpr.anno >= 2013
              having
               sum(nvl(ogim.imposta_dovuta, 0) -
                   nvl(ogim.imposta_erariale_dovuta, 0)) != 0
              union
              select --
               sum(nvl(ogim.imposta_erariale_dovuta, 0)),
               sum(nvl(ogim.imposta_erariale_dovuta_acc, 0)),
                     --
               '3925' codice_tributo,
               rpad('IMU - IMM. PROD. (GR. CAT. D) - STATO', 44) des_tributo
                from oggetti_imposta ogim,
                     oggetti_pratica ogpr,
                     oggetti         ogge
               where ogpr.oggetto_pratica = ogim.oggetto_pratica
                 and ogpr.oggetto = ogge.oggetto
                 and ogpr.pratica = a_pratica
                 and ogpr.oggetto_pratica = a_oggetto_pratica
                 and f_get_cod_tributo_f24(ogim.oggetto_imposta,'S') = '3925'
              having sum(nvl(ogim.imposta_erariale_dovuta, 0)) != 0
              union
              select --
               sum(nvl(ogim.imposta_dovuta, 0)),
               sum(nvl(ogim.imposta_dovuta_acconto, 0)),
                     --
               '3939' codice_tributo,
               rpad('IMU - FABB. COSTR. DEST. VENDITA - COMUNE', 44) des_tributo
                from oggetti_imposta ogim,
                     oggetti_pratica ogpr,
                     oggetti         ogge
               where ogpr.oggetto_pratica = ogim.oggetto_pratica
                 and ogpr.oggetto = ogge.oggetto
                 and ogpr.pratica = a_pratica
                 and ogpr.oggetto_pratica = a_oggetto_pratica
                 and f_get_cod_tributo_f24(ogim.oggetto_imposta,'C') = '3939'
               having sum(nvl(ogim.imposta_dovuta, 0)) != 0
                order by 4) imm;
    return rc;
  end;
------------------------------------------------------------------
  function imposta_rendita(a_pratica         number,
                           a_oggetto_pratica number,
                           a_subtesto        varchar2) return sys_refcursor is
    rc sys_refcursor;
  begin
    open rc for
      select imm.*,
             a_subtesto as subtesto,
             stampa_common.f_formatta_numero(imposta_num,'I','S') imposta,
             stampa_common.f_formatta_numero(imposta_acconto_num,'I','S') imposta_acconto,
             stampa_common.f_formatta_numero((imposta_num - imposta_acconto_num),'I','S') imposta_saldo,
             stampa_common.f_formatta_numero(sum(imposta_acconto_num) over(),'I','S') imposta_acconto_tot,
             stampa_common.f_formatta_numero(sum(imposta_num) over(),'I','S') imposta_tot,
             stampa_common.f_formatta_numero(sum(imposta_num - imposta_acconto_num)
                                    over(),'I','S') imposta_saldo_tot
        from (select --
               sum(nvl(ogim.imposta, 0)) imposta_num,
               sum(nvl(ogim.imposta_acconto, 0)) imposta_acconto_num,
               --
               '3912' codice_tributo,
               rpad('IMU - AB. PRINC. E PERTINENZE - COMUNE', 44) des_tributo
                from oggetti_imposta ogim,
                     oggetti_pratica ogpr,
                     oggetti         ogge
               where ogpr.oggetto_pratica = ogim.oggetto_pratica
                 and ogpr.oggetto = ogge.oggetto
                 and ogpr.pratica = a_pratica
                 and ogpr.oggetto_pratica = a_oggetto_pratica
                 and f_get_cod_tributo_f24(ogim.oggetto_imposta,'C') = '3912'
               having sum(nvl(ogim.imposta, 0)) != 0
              union
              select --
               sum(nvl(ogim.imposta, 0)),
               sum(nvl(ogim.imposta_acconto, 0)),
                     --
               '3913' codice_tributo,
               rpad('IMU - FABB. RUR. AD USO STRUMENTALE - COMUNE', 44) des_tributo
                from oggetti_imposta ogim,
                     oggetti_pratica ogpr,
                     oggetti         ogge
               where ogpr.oggetto_pratica = ogim.oggetto_pratica
                 and ogpr.oggetto = ogge.oggetto
                 and ogpr.pratica = a_pratica
                 and ogpr.oggetto_pratica = a_oggetto_pratica
                 and f_get_cod_tributo_f24(ogim.oggetto_imposta,'C') = '3913'
               having sum(nvl(ogim.imposta, 0)) != 0
              union
              select sum(nvl(ogim.imposta, 0) -
                         nvl(ogim.imposta_erariale, 0)),
                     sum(nvl(ogim.imposta_acconto, 0) -
                         nvl(ogim.imposta_erariale_acconto, 0)),
                     '3914' codice_tributo,
                     rpad('IMU - TERRENI - COMUNE', 44) des_tributo
                from oggetti_imposta ogim,
                     oggetti_pratica ogpr,
                     oggetti         ogge
               where ogpr.oggetto_pratica = ogim.oggetto_pratica
                 and ogpr.oggetto = ogge.oggetto
                 and ogpr.pratica = a_pratica
                 and ogpr.oggetto_pratica = a_oggetto_pratica
                 and f_get_cod_tributo_f24(ogim.oggetto_imposta,'C') = '3914'
               having sum(nvl(ogim.imposta, 0) -
                          nvl(ogim.imposta_erariale, 0)) != 0
              union
              select --
               sum(nvl(ogim.imposta_erariale, 0)),
               sum(nvl(ogim.imposta_erariale_acconto, 0)),
                     --
               '3915' codice_tributo,
               rpad('IMU - TERRENI - STATO', 44) des_tributo
                from oggetti_imposta ogim,
                     oggetti_pratica ogpr,
                     oggetti         ogge
               where ogpr.oggetto_pratica = ogim.oggetto_pratica
                 and ogpr.oggetto = ogge.oggetto
                 and ogpr.pratica = a_pratica
                 and ogpr.oggetto_pratica = a_oggetto_pratica
                 and f_get_cod_tributo_f24(ogim.oggetto_imposta,'S') = '3915'
               having sum(nvl(ogim.imposta_erariale, 0)) != 0
              union
              select --
               sum(nvl(ogim.imposta, 0) -
                   nvl(ogim.imposta_erariale, 0)),
               sum(nvl(ogim.imposta_acconto, 0) -
                   nvl(ogim.imposta_erariale_acconto, 0)),
                     --
               '3916' codice_tributo,
               rpad('IMU - AREE FABBRICABILI - COMUNE', 44) des_tributo
                from oggetti_imposta ogim,
                     oggetti_pratica ogpr,
                     oggetti         ogge
               where ogpr.oggetto_pratica = ogim.oggetto_pratica
                 and ogpr.oggetto = ogge.oggetto
                 and ogpr.pratica = a_pratica
                 and ogpr.oggetto_pratica = a_oggetto_pratica
                 and f_get_cod_tributo_f24(ogim.oggetto_imposta,'C') = '3916'
               having sum(nvl(ogim.imposta, 0) -
                          nvl(ogim.imposta_erariale, 0)) != 0
              union
              select --
               sum(nvl(ogim.imposta_erariale, 0)),
               sum(nvl(ogim.imposta_erariale_acconto, 0)),
                     --
               '3917' codice_tributo,
               rpad('IMU - AREE FABBRICABILI - STATO', 44) des_tributo
                from oggetti_imposta ogim,
                     oggetti_pratica ogpr,
                     oggetti         ogge
               where ogpr.oggetto_pratica = ogim.oggetto_pratica
                 and ogpr.oggetto = ogge.oggetto
                 and ogpr.pratica = a_pratica
                 and ogpr.oggetto_pratica = a_oggetto_pratica
                 and f_get_cod_tributo_f24(ogim.oggetto_imposta,'S') = '3917'
               having sum(nvl(ogim.imposta_erariale, 0)) != 0
              union
              select --
               f_altri_importo(a_pratica,
                               a_oggetto_pratica,
                               'COMUNE',
                               ogpr.anno,
                               'RENDITA'),
               f_altri_importo_acconto(a_pratica,
                                       a_oggetto_pratica,
                                       'COMUNE',
                                       ogpr.anno,
                                       'RENDITA'),
               --
               '3918' codice_tributo,
               rpad('IMU - ALTRI FABBRICATI - COMUNE', 44) des_tributo
                from oggetti_imposta ogim,
                     oggetti_pratica ogpr,
                     oggetti         ogge
               where ogpr.oggetto_pratica = ogim.oggetto_pratica
                 and ogpr.oggetto = ogge.oggetto
                 and ogpr.pratica = a_pratica
                 and ogpr.oggetto_pratica = a_oggetto_pratica
                 and f_get_cod_tributo_f24(ogim.oggetto_imposta,'C') = '3918'
                 and f_altri_importo(a_pratica,
                                     a_oggetto_pratica,
                                     'COMUNE',
                                     ogpr.anno,
                                     'RENDITA') > 0
              union
              select --
               f_altri_importo(a_pratica,
                               a_oggetto_pratica,
                               'STATO',
                               ogpr.anno,
                               'RENDITA'),
               f_altri_importo_acconto(a_pratica,
                                       a_oggetto_pratica,
                                       'STATO',
                                       ogpr.anno,
                                       'RENDITA'),
                      --
               '3919' codice_tributo,
               rpad('IMU - ALTRI FABBRICATI - STATO', 44) des_tributo
                from oggetti_imposta ogim,
                     oggetti_pratica ogpr,
                     oggetti         ogge
               where ogpr.oggetto_pratica = ogim.oggetto_pratica
                 and ogpr.oggetto = ogge.oggetto
                 and ogpr.pratica = a_pratica
                 and ogpr.oggetto_pratica = a_oggetto_pratica
                 and f_get_cod_tributo_f24(ogim.oggetto_imposta,'S') = '3919'
                 and f_altri_importo(a_pratica,
                                     a_oggetto_pratica,
                                     'STATO',
                                     ogpr.anno,
                                     'RENDITA') > 0
              union
              select --
               sum(nvl(ogim.imposta, 0) -
                   nvl(ogim.imposta_erariale, 0)),
               sum(nvl(ogim.imposta_acconto, 0) -
                   nvl(ogim.imposta_erariale_acconto, 0)),
                     --
               '3930' codice_tributo,
               rpad('IMU - IMM. PROD. (GR. CAT. D) - INCR. COMUNE', 44) des_tributo
                from oggetti_imposta ogim,
                     oggetti_pratica ogpr,
                     oggetti         ogge
               where ogpr.oggetto_pratica = ogim.oggetto_pratica
                 and ogpr.oggetto = ogge.oggetto
                 and ogpr.pratica = a_pratica
                 and ogpr.oggetto_pratica = a_oggetto_pratica
                 and f_get_cod_tributo_f24(ogim.oggetto_imposta,'C') = '3930'
               having sum(nvl(ogim.imposta, 0) -
                          nvl(ogim.imposta_erariale, 0)) != 0
              union
              select --
               sum(nvl(ogim.imposta_erariale, 0)),
               sum(nvl(ogim.imposta_erariale_acconto, 0)),
                     --
               '3925' codice_tributo,
               rpad('IMU - IMM. PROD. (GR. CAT. D) - STATO', 44) des_tributo
                from oggetti_imposta ogim,
                     oggetti_pratica ogpr,
                     oggetti         ogge
               where ogpr.oggetto_pratica = ogim.oggetto_pratica
                 and ogpr.oggetto = ogge.oggetto
                 and ogpr.pratica = a_pratica
                 and ogpr.oggetto_pratica = a_oggetto_pratica
                 and f_get_cod_tributo_f24(ogim.oggetto_imposta,'S') = '3925'
               having sum(nvl(ogim.imposta_erariale, 0)) != 0
              union
              select --
               sum(nvl(ogim.imposta, 0)),
               sum(nvl(ogim.imposta_acconto, 0)),
                     --
               '3939' codice_tributo,
               rpad('IMU - FABB. COSTR. DEST. VENDITA - COMUNE', 44) des_tributo
                from oggetti_imposta ogim,
                     oggetti_pratica ogpr,
                     oggetti         ogge
               where ogpr.oggetto_pratica = ogim.oggetto_pratica
                 and ogpr.oggetto = ogge.oggetto
                 and ogpr.pratica = a_pratica
                 and ogpr.oggetto_pratica = a_oggetto_pratica
                 and f_get_cod_tributo_f24(ogim.oggetto_imposta,'C') = '3939'
               having sum(nvl(ogim.imposta, 0)) != 0
               order by 4) imm;
    return rc;
  end;
------------------------------------------------------------------
  function principale(a_cf           varchar2,
                      a_vett_prat    varchar2,
                      a_modello      number,
                      a_modello_rimb number,
                      a_ni_erede     number default -1) return sys_refcursor is
    rc sys_refcursor;
  begin
    open rc for
      select -- CAMPI AGGIUNTI --
       '(Identificativo Operazione LIQP' || prtr.anno ||
       lpad(prtr.pratica, 10, '0') || ')' as id_operazione_char,
       'LIQP' || prtr.anno ||
       lpad(prtr.pratica, 10, '0') as id_operazione,
       a_modello as modello,
       a_modello_rimb as modello_rimb,
       decode(nvl(prtr.imposta_dovuta_totale, 0),
              nvl(prtr.imposta_totale, 0),
              null,
              stampa_common.f_formatta_numero(
              (select sum(ogim.imposta_acconto)
                 from oggetti_pratica ogpr, oggetti_imposta ogim
                where ogpr.oggetto_pratica = ogim.oggetto_pratica
                  and ogim.cod_fiscale = a_cf
                  and ogpr.pratica = prtr.pratica)
                               ,'I')
             ) imposta2_acconto,
       decode(nvl(prtr.imposta_dovuta_totale, 0),
              nvl(prtr.imposta_totale, 0),
              null,
              stampa_common.f_formatta_numero(
              (select sum(ogim.imposta) - sum(ogim.imposta_acconto)
                 from oggetti_pratica ogpr, oggetti_imposta ogim
                where ogpr.oggetto_pratica = ogim.oggetto_pratica
                  and ogim.cod_fiscale = a_cf
                  and ogpr.pratica = prtr.pratica)
                               ,'I')
             ) imposta2_saldo,
       stampa_common.f_formatta_numero((select sum(ogim.imposta_dovuta_acconto)
          from oggetti_pratica ogpr, oggetti_imposta ogim
         where ogpr.oggetto_pratica = ogim.oggetto_pratica
           and ogim.cod_fiscale = a_cf
           and ogpr.pratica = prtr.pratica),'I', 'S') imposta1_acconto,
       stampa_common.f_formatta_numero((select sum(ogim.imposta_dovuta) - sum(ogim.imposta_dovuta_acconto)
          from oggetti_pratica ogpr, oggetti_imposta ogim
         where ogpr.oggetto_pratica = ogim.oggetto_pratica
           and ogim.cod_fiscale = a_cf
           and ogpr.pratica = prtr.pratica),'I') imposta1_saldo,
       --prtr.tipo_tributo,
       -- FINE CAMPI AGGIUNTI --
       decode(sign(round(prtr.importo_totale, 0)),
              1,
              f_descrizione_timp(a_modello, 'INTESTAZIONE'),
              f_descrizione_timp(a_modello_rimb, 'INTESTAZIONE_RIMB')) intestazione,
       to_char(prtr.data, 'dd/mm/yyyy') data,
       -- prtr.anno anno,
       -- prtr.tipo_evento tiev,
       prtr.numero num,
       decode(prtr.motivo,
              null,
              '',
              'MOTIVAZIONE: ' ||
              translate(prtr.motivo, chr(013) || chr(010), '  ')) motivo,
       stampa_common.f_formatta_numero(prtr.importo_totale,'I') imp_cal,
       lpad(nvl(prtr.numero, ' '), 15, '0') prtr_numero,
       decode(sign(prtr.importo_totale),
              -1,
              rpad('TOTALE DA RIMBORSARE (ARROTONDATO)', 67),
              rpad('TOTALE DOVUTO (ARROTONDATO)', 67)) tot_desc,
       decode(nvl(prtr.imposta_dovuta_totale, 0),
              0,
              rpad(' ', 27),
              decode(nvl(prtr.imposta_dovuta_totale, 0),
                     nvl(prtr.imposta_totale, 0),
                     'TOTALE IMPOSTA CALCOLATA', -- CAMPO MODIFICATO
                     'SULLA BASE DELLA DENUNCIA ')) testo1,
       decode(nvl(prtr.imposta_dovuta_totale, 0),
              0,
              '', --rpad(' ', 62),
              decode(nvl(prtr.imposta_dovuta_totale, 0),
                     nvl(prtr.imposta_totale, 0),
                     '', --rpad(' ', 62),
                     'SULLA BASE DELLA RENDITA DEFINITIVA  ')) testo2,
       decode(nvl(prtr.imposta_dovuta_totale, 0),
              0,
              stampa_common.f_formatta_numero(f_round(prtr.imposta_totale, 0),
                                'I','S'
                               ),
              decode(nvl(prtr.imposta_dovuta_totale, 0),
                     nvl(prtr.imposta_totale, 0),
                     stampa_common.f_formatta_numero(f_round(prtr.imposta_totale, 0),
                                       'I','S'
                                      ),
                     stampa_common.f_formatta_numero(f_round(prtr.imposta_dovuta_totale,0),
                                      'I','S'
                                      )
                     )
             ) imposta1,
       decode(nvl(prtr.imposta_dovuta_totale, 0),
             0,
             null,
             decode(nvl(prtr.imposta_dovuta_totale, 0),
                    nvl(prtr.imposta_totale, 0),
                    null,
                    stampa_common.f_formatta_numero(f_round(prtr.imposta_totale, 0),
                                      'I','S'
                                     )
                   )
             ) imposta2,
       decode(sign(round(prtr.importo_totale, 0)),
              1,
              rpad('TOTALE DOVUTO', 45),
              rpad('TOTALE DA RIMBORSARE', 45)) l_importo_totale,
       stampa_common.f_formatta_numero(f_round(prtr.importo_totale, 1),
                         'I','S'
                        ) importo_totale,
       decode(sign(round(prtr.importo_totale, 0)),
              1,
              rpad('TOTALE DOVUTO ARROTONDATO', 45),
              rpad('TOTALE DA RIMBORSARE ARROTONDATO', 45)) l_importo_totale_arrotondato,
       stampa_common.f_formatta_numero(round(prtr.importo_totale, 0),
                         'I','S'
                        ) importo_totale_arrotondato,
       decode(fase_euro, 1, 'PARI AD EURO', '') pari_euro,
       decode(fase_euro,
              1,
              stampa_common.f_formatta_numero(round((round(((prtr.importo_totale - 1) / 1000),
                                             0) * 1000) /
                                      dati_generali.cambio_euro,
                                      2),
                                'I','S'
                               ),
              '') importo_totale_euro,
       decode(round(prtr.importo_ridotto, 0),
              round(prtr.importo_totale, 0),
              null,
              'TOTALE CON ADESIONE FORMALE ARROTONDATO') l_importo_ridotto_arrotondato,
       decode(round(prtr.importo_ridotto, 0),
              round(prtr.importo_totale, 0),
              null,
              stampa_common.f_formatta_numero(f_round(prtr.importo_ridotto, 1),
                                'I','S'
                               )
             ) importo_ridotto,
       decode(round(prtr.importo_ridotto, 0),
              round(prtr.importo_totale, 0),
              null,
              stampa_common.f_formatta_numero(round(prtr.importo_ridotto, 0),
                                'I','S'
                               )
             ) importo_ridotto_arrotondato,
       decode(fase_euro,
              1,
              stampa_common.f_formatta_numero(round((round(((prtr.importo_ridotto - 1) / 1000),
                                             0) * 1000) /
                                      dati_generali.cambio_euro,
                                      2),
                                'I','S'
                               ),
              '') importo_ridotto_euro,
       decode(f_round(prtr.importo_totale, 1),
              f_round(prtr.importo_ridotto, 1),
              rpad('TOTALE (ARROTONDATO)', 45),
              rpad('TOTALE CON ADESIONE FORMALE ARROTONDATO', 45)) tot_ad_form_arr,
       dati_generali.fase_euro,
       -- prtr.pratica,
       f_descrizione_titr(prtr.tipo_tributo, prtr.anno) descr_titr,
       sopr.*,
       -- prtr.cod_fiscale,
       a_ni_erede                            ni_erede
        from soggetti_pratica sopr
           , pratiche_tributo prtr
           , dati_generali
       where prtr.cod_fiscale = a_cf
         and prtr.pratica = a_vett_prat
         and sopr.pratica = a_vett_prat
       order by prtr.numero asc;
    return rc;
  end;
------------------------------------------------------------------
  function versamenti(a_cf varchar2, a_pratica number, a_anno number)
    return sys_refcursor is
    rc sys_refcursor;
    p_tipo_tributo                  varchar2(5);
  begin
    -- (VD - 13/02/2020): aggiunta selezione tipo_tributo da pratiche_tributo per utilizzare
    --                    il package anche per la TASI
    P_tipo_tributo := stampa_common.f_get_tipo_tributo(a_pratica);
    open rc for
      select vers.*,
             stampa_common.f_formatta_numero(sum(importo_versato) over(),
                               'I','S'
                              ) totale_versato,
             stampa_common.f_formatta_numero(sum(importo_versato_arr) over(),
                               'I','S'
                              ) totale_versato_arr,
             decode(sum(decode(tipo_versamento, 'RAVVED.*', 1, 0)) over(),
                    0,
                    '',
                    '* è stato rilevato un versamento su ravvedimento non corretto. L''importo indicato è ottenuto riproporzionando l''intero versamento su ravvedimento all''effettiva imposta dovuta, al netto di sanzioni e interessi.') as ravvedimento
        from (select -- CAMPI AGGIUNTI --
               stampa_common.f_formatta_numero(versamenti.importo_versato,
                                 'I','S'
                                ) as importo_versato_str, -- FINE CAMPI AGGIUNTI --
               versamenti.importo_versato,
               --
               stampa_common.f_formatta_numero(round(versamenti.importo_versato),
                                 'I','S'
                                ) as importo_versato_arr_str,
               round(versamenti.importo_versato) importo_versato_arr,
               --
               nvl(to_char(versamenti.data_pagamento, 'dd/mm/yyyy'),
                   '          ') data_versamento,
               decode(versamenti.tipo_versamento,
                      'A',
                      'ACCONTO ',
                      'S',
                      'SALDO   ',
                      'U',
                      'UNICO   ',
                      '      ') tipo_versamento,
               decode(f_get_tipo_imu(a_pratica),
                      2,
                      to_char(f_scadenza_mini_imu(versamenti.anno, a_pratica),
                              'dd/mm/yyyy'),
                      nvl(to_char(f_scadenza(versamenti.anno,
                                             p_tipo_tributo,  --'ICI',
                                             versamenti.tipo_versamento,
                                             versamenti.cod_fiscale),
                                  'dd/mm/yyyy'),
                          '          ')) data_scadenza,
               decode(f_get_tipo_imu(a_pratica),
                      2,
                      decode(sign(trunc(f_scadenza_mini_imu(versamenti.anno,
                                                            a_pratica) -
                                        versamenti.data_pagamento)),
                             -1,
                             lpad(trunc(f_scadenza_mini_imu(versamenti.anno,
                                                            a_pratica) -
                                        versamenti.data_pagamento),
                                  6),
                             ''),
                      decode(sign(trunc(f_scadenza(versamenti.anno,
                                                   p_tipo_tributo,  --'ICI',
                                                   versamenti.tipo_versamento,
                                                   versamenti.cod_fiscale) -
                                        "VERSAMENTI"."DATA_PAGAMENTO")),
                             -1,
                             lpad(trunc(f_scadenza(versamenti.anno,
                                                   p_tipo_tributo,  --'ICI',
                                                   versamenti.tipo_versamento,
                                                   versamenti.cod_fiscale) -
                                        "VERSAMENTI"."DATA_PAGAMENTO"),
                                  6),
                             '')) gio_dif,
               decode(f_get_tipo_imu(a_pratica),
                      0,
                      '[a_capo' || rpad(' ', 30) || 'Scadenza Mini IMU      ' ||
                      to_char(f_scadenza_mini_imu(versamenti.anno, a_pratica),
                              'dd/mm/yyyy') || lpad(' ', 10) ||
                      decode(sign(trunc(f_scadenza_mini_imu(versamenti.anno,
                                                            a_pratica) -
                                        versamenti.data_pagamento)),
                             -1,
                             lpad(trunc(f_scadenza_mini_imu(versamenti.anno,
                                                            a_pratica) -
                                        versamenti.data_pagamento),
                                  6),
                             ''),
                      '') dati_mini_imu,
               versamenti.sequenza,
               1 ord
                from versamenti
               where versamenti.pratica is null
                 and versamenti.anno = a_anno
                 and versamenti.cod_fiscale = a_cf
                 and versamenti.tipo_tributo = p_tipo_tributo  --'ICI'
                 and versamenti.data_pagamento <=
                     (select min(prtr.data)
                        from pratiche_tributo prtr
                       where prtr.pratica = a_pratica)
              union
              select -- CAMPI AGGIUNTI --
               stampa_common.f_formatta_numero(f_importo_vers_ravv_dett(prtr.cod_fiscale,
                                                          p_tipo_tributo,  --'ICI',
                                                          prtr.anno,
                                                          'U',
                                                          'TOT',
                                                          data_elab.data),
                                 'I','S'
                                ) as importo_versato_str, -- FINE CAMPI AGGIUNTI --
               f_importo_vers_ravv_dett(prtr.cod_fiscale,
                                        p_tipo_tributo,  --'ICI',
                                        prtr.anno,
                                        'U',
                                        'TOT',
                                        data_elab.data),
               --
               stampa_common.f_formatta_numero(round(f_importo_vers_ravv_dett(prtr.cod_fiscale,
                                                          p_tipo_tributo,  --'ICI',
                                                          prtr.anno,
                                                          'U',
                                                          'TOT',
                                                          data_elab.data)),
                                 'I','S'
                                ),
               round(f_importo_vers_ravv_dett(prtr.cod_fiscale,
                                        p_tipo_tributo,  --'ICI',
                                        prtr.anno,
                                        'U',
                                        'TOT',
                                        data_elab.data)),
               --
               nvl(to_char(f_data_max_vers_ravv(prtr.cod_fiscale,
                                                p_tipo_tributo,  --'ICI',
                                                prtr.anno,
                                                'U'),
                           'dd/mm/yyyy'),
                   '          '),
               'RAVVED.*',
               '          ',
               '',
               '',
               to_number(''),
               2
                from pratiche_tributo prtr,
                     (select min(prtr.data) data
                        from pratiche_tributo prtr
                       where prtr.pratica = a_pratica) data_elab
               where prtr.tipo_pratica = 'V'
                 and prtr.anno = a_anno
                 and prtr.cod_fiscale = a_cf
                 and prtr.numero is not null
                 and prtr.tipo_tributo || '' = p_tipo_tributo  --'ICI'
                 and nvl(prtr.stato_accertamento, 'D') = 'D'
                 and prtr.data <= data_elab.data
                 and f_importo_vers_ravv_dett(prtr.cod_fiscale,
                                              p_tipo_tributo,  --'ICI',
                                              prtr.anno,
                                              'U',
                                              'TOT',
                                              data_elab.data) > 0
               order by ord, data_versamento, sequenza) vers;
    return rc;
  end;
------------------------------------------------------------------
  function versamenti_vuoto(a_cf varchar2, a_pratica number, a_anno number)
    return sys_refcursor is
    rc sys_refcursor;
  begin
    open rc for
      select a_cf as cod_fiscale, a_pratica as pratica, a_anno as anno
        from dual;
    return rc;
  end;
------------------------------------------------------------------
  function importi_comune_stato
  ( a_pratica                     number
  , a_tipo_importo                varchar2
  , a_tipo_ente                   varchar2
  ) return number is
    w_importo                     number;
  begin
    select sum(decode(a_tipo_importo,
                      'A',acconto,
                      'S',saldo,
                      totale
                      )
              )
      into w_importo
      from (select 'IMU - AB. PRINC. E PERT.' descr,
                   'C' codice,
                   round(nvl(sum(ogim.imposta_acconto),0)) acconto,
                   round(nvl(sum(ogim.imposta),0)) -
                   round(nvl(sum(ogim.imposta_acconto),0)) saldo,
                   round(nvl(sum(ogim.imposta),0)) totale
              from oggetti_imposta ogim,
                   oggetti_pratica ogpr
             where ogim.oggetto_pratica = ogpr.oggetto_pratica
               and ogpr.pratica = a_pratica
               and nvl(ogim.tipo_aliquota,-1) = 2
            having sum(ogim.imposta) > 0
            union
            select 'IMU - FABB. RUR. AD USO STRUM.',
                   'C',
                   round(nvl(sum(ogim.imposta_acconto),0)) acconto,
                   round(nvl(sum(ogim.imposta),0)) -
                   round(nvl(sum(ogim.imposta_acconto),0)) saldo,
                   round(nvl(sum(ogim.imposta),0)) totale
              from oggetti_imposta ogim,
                   oggetti_pratica ogpr,
                   oggetti ogge,
                   aliquote aliq
             where ogim.oggetto_pratica = ogpr.oggetto_pratica
               and ogpr.pratica = a_pratica
               and ogpr.oggetto = ogge.oggetto
               and ogim.tipo_tributo = aliq.tipo_tributo (+)
               and ogim.anno = aliq.anno (+)
               and nvl(ogim.tipo_aliquota,-1) = aliq.tipo_aliquota (+)
               and nvl(ogim.tipo_aliquota,-1) <> 2
               and nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto) not in (1,2)
               and nvl(aliq.flag_fabbricati_merce,'N') <> 'S'
               and ogim.aliquota_erariale is null
            having sum(ogim.imposta) > 0
            union
            select 'IMU - TERRENI',
                   'C',
                   round(nvl(sum(ogim.imposta_acconto - nvl(ogim.imposta_erariale_acconto,0)),0)) acconto,
                   round(nvl(sum(ogim.imposta - nvl(ogim.imposta_erariale,0)),0)) -
                   round(nvl(sum(ogim.imposta_acconto - nvl(ogim.imposta_erariale_acconto,0)),0)) saldo,
                   round(nvl(sum(ogim.imposta - nvl(ogim.imposta_erariale,0)),0)) totale
              from oggetti_imposta ogim,
                   oggetti_pratica ogpr,
                   oggetti ogge
             where ogim.oggetto_pratica = ogpr.oggetto_pratica
               and ogpr.pratica = a_pratica
               and ogpr.oggetto = ogge.oggetto
               and nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto) = 1
            having sum(ogim.imposta - nvl(ogim.imposta_erariale,0)) > 0
            union
            select 'IMU - AREE FABBRICABILI',
                   'C',
                   round(nvl(sum(ogim.imposta_acconto - nvl(ogim.imposta_erariale_acconto,0)),0)) +
                   round(nvl(sum(ogim.imposta_erariale_acconto),0)) acconto,
                   (round(nvl(sum(ogim.imposta - nvl(ogim.imposta_erariale,0)),0)) +
                   round(nvl(sum(ogim.imposta_erariale),0))) -
                   round(nvl(sum(ogim.imposta_acconto - nvl(ogim.imposta_erariale_acconto,0)),0)) +
                   round(nvl(sum(ogim.imposta_erariale_acconto),0)) saldo,
                   round(nvl(sum(ogim.imposta - nvl(ogim.imposta_erariale,0)),0)) totale
              from oggetti_imposta ogim,
                   oggetti_pratica ogpr,
                   oggetti ogge
             where ogim.oggetto_pratica = ogpr.oggetto_pratica
               and ogpr.pratica = a_pratica
               and ogpr.oggetto = ogge.oggetto
               and nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto) = 2
            having sum(ogim.imposta - nvl(ogim.imposta_erariale,0)) > 0
            union
            select 'IMU - ALTRI FABBRICATI',
                   'C',
                   round(nvl(sum(decode(sign(ogim.anno - 2012),
                                 1,decode(substr(ogpr.categoria_catasto,1,1) ||
                                          to_char(nvl(ogim.tipo_aliquota,-1)),
                                          'D9',0,
                                          decode(nvl(aliq.flag_fabbricati_merce,'N'),
                                                 'S',0,
                                                 ogim.imposta_acconto - nvl(ogim.imposta_erariale_acconto,0))),
                                 ogim.imposta_acconto - nvl(ogim.imposta_erariale_acconto,0))),0)) acconto,
                   round(nvl(sum(decode(sign(ogim.anno - 2012),
                                 1,decode(substr(ogpr.categoria_catasto,1,1) ||
                                          to_char(nvl(ogim.tipo_aliquota,-1)),
                                          'D9',0,
                                          decode(nvl(aliq.flag_fabbricati_merce,'N'),
                                                 'S',0,
                                                 ogim.imposta - nvl(ogim.imposta_erariale,0))),
                                 ogim.imposta - nvl(ogim.imposta_erariale,0))),0)) -
                   round(nvl(sum(decode(sign(ogim.anno - 2012),
                                 1,decode(substr(ogpr.categoria_catasto,1,1) ||
                                          to_char(nvl(ogim.tipo_aliquota,-1)),
                                          'D9',0,
                                          decode(nvl(aliq.flag_fabbricati_merce,'N'),
                                                 'S',0,
                                                 ogim.imposta_acconto - nvl(ogim.imposta_erariale_acconto,0))),
                                 ogim.imposta_acconto - nvl(ogim.imposta_erariale_acconto,0))),0)) saldo,
                   round(nvl(sum(decode(sign(ogim.anno - 2012),
                                 1,decode(substr(ogpr.categoria_catasto,1,1) ||
                                          to_char(nvl(ogim.tipo_aliquota,-1)),
                                          'D9',0,
                                          decode(nvl(aliq.flag_fabbricati_merce,'N'),
                                                 'S',0,
                                                 ogim.imposta - nvl(ogim.imposta_erariale,0))),
                                 ogim.imposta - nvl(ogim.imposta_erariale,0))),0)) totale
              from oggetti_imposta ogim,
                   oggetti_pratica ogpr,
                   oggetti ogge,
                   aliquote aliq
             where ogim.oggetto_pratica = ogpr.oggetto_pratica
               and ogpr.pratica = a_pratica
               and ogpr.oggetto = ogge.oggetto
               and ogim.tipo_tributo = aliq.tipo_tributo (+)
               and ogim.anno = aliq.anno (+)
               and nvl(ogim.tipo_aliquota,-1) = aliq.tipo_aliquota (+)
               and nvl(ogim.tipo_aliquota,-1) <> 2
               and nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto) not in (1,2)
               and ogim.aliquota_erariale is not null
            having sum(decode(sign(ogim.anno - 2012),
                       1,decode(substr(ogpr.categoria_catasto,1,1) ||
                                to_char(nvl(ogim.tipo_aliquota,-1)),
                                'D9',0,
                                decode(nvl(aliq.flag_fabbricati_merce,'N'),
                                       'S',0,
                                       ogim.imposta - nvl(ogim.imposta_erariale,0))),
                       ogim.imposta - nvl(ogim.imposta_erariale,0))) > 0
            union
            select 'IMU - IMM. PROD. (GR.C.D)',
                   'C',
                   round(nvl(sum(decode(sign(ogim.anno - 2012),
                                 1,decode(substr(ogpr.categoria_catasto,1,1) ||
                                          to_char(nvl(ogim.tipo_aliquota,-1)),
                                          'D9',ogim.imposta_acconto - nvl(ogim.imposta_erariale_acconto,0),
                                          0),
                                 0)),0)) acconto,
                   round(nvl(sum(decode(sign(ogim.anno - 2012),
                                 1,decode(substr(ogpr.categoria_catasto,1,1) ||
                                          to_char(nvl(ogim.tipo_aliquota,-1)),
                                          'D9',ogim.imposta - nvl(ogim.imposta_erariale,0),
                                          0),
                                 0)),0)) -
                   round(nvl(sum(decode(sign(ogim.anno - 2012),
                                 1,decode(substr(ogpr.categoria_catasto,1,1) ||
                                          to_char(nvl(ogim.tipo_aliquota,-1)),
                                          'D9',ogim.imposta_acconto - nvl(ogim.imposta_erariale_acconto,0),
                                          0),
                                 0)),0)) saldo,
                   round(nvl(sum(decode(sign(ogim.anno - 2012),
                                 1,decode(substr(ogpr.categoria_catasto,1,1) ||
                                          to_char(nvl(ogim.tipo_aliquota,-1)),
                                          'D9',ogim.imposta - nvl(ogim.imposta_erariale,0),
                                          0),
                                 0)),0)) totale
              from oggetti_imposta ogim,
                   oggetti_pratica ogpr,
                   oggetti ogge
             where ogim.oggetto_pratica = ogpr.oggetto_pratica
               and ogpr.pratica = a_pratica
               and ogpr.oggetto = ogge.oggetto
               and nvl(ogim.tipo_aliquota,-1) <> 2
               and nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto) not in (1,2)
               and aliquota_erariale is not null
            having sum(decode(sign(ogim.anno - 2012),
                       1,decode(substr(ogpr.categoria_catasto,1,1) ||
                                to_char(nvl(ogim.tipo_aliquota,-1)),
                                'D9',ogim.imposta - nvl(ogim.imposta_erariale,0),
                                0),
                       0)) > 0
            union
            select 'IMU - IMM.COSTR.DEST.VENDITA',
                   'C',
                   round(nvl(sum(ogim.imposta_acconto - nvl(ogim.imposta_erariale_acconto,0)),0)) acconto,
                   round(nvl(sum(ogim.imposta - nvl(ogim.imposta_erariale,0)),0)) -
                   round(nvl(sum(ogim.imposta_acconto - nvl(ogim.imposta_erariale_acconto,0)),0)) saldo,
                   round(nvl(sum(ogim.imposta - nvl(ogim.imposta_erariale,0)),0)) totale
              from oggetti_imposta ogim,
                   oggetti_pratica ogpr,
                   oggetti ogge,
                   aliquote aliq
             where ogim.oggetto_pratica = ogpr.oggetto_pratica
               and ogpr.pratica = a_pratica
               and ogpr.oggetto = ogge.oggetto
               and ogim.tipo_tributo = aliq.tipo_tributo (+)
               and ogim.anno = aliq.anno (+)
               and nvl(ogim.tipo_aliquota,-1) = aliq.tipo_aliquota (+)
               and nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto) not in (1,2)
               and nvl(aliq.flag_fabbricati_merce,'N') = 'S'
            having sum(ogim.imposta - nvl(ogim.imposta_erariale,0)) > 0
            union
            select rpad('IMU - TERRENI', 39) descr,
                   'S' codice,
                   round(nvl(sum(imposta_erariale_acconto),0)) acconto,
                   round(nvl(sum(imposta_erariale),0)) -
                   round(nvl(sum(imposta_erariale_acconto),0)) saldo,
                   round(nvl(sum(imposta_erariale),0)) totale
              from oggetti_imposta ogim,
                   oggetti_pratica ogpr,
                   oggetti ogge
             where ogim.oggetto_pratica = ogpr.oggetto_pratica
               and ogpr.pratica = a_pratica
               and ogpr.oggetto = ogge.oggetto
               and nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto) = 1
            having sum(imposta_erariale) > 0
             union
            select 'IMU - AREE FABBRICABILI',
                   'S',
                   round(nvl(sum(ogim.imposta_erariale_acconto),0)) acconto,
                   round(nvl(sum(ogim.imposta_erariale),0)) -
                   round(nvl(sum(ogim.imposta_erariale_acconto),0)) saldo,
                   round(nvl(sum(imposta_erariale),0)) totale
              from oggetti_imposta ogim,
                   oggetti_pratica ogpr,
                   oggetti ogge
             where ogim.oggetto_pratica = ogpr.oggetto_pratica
               and ogpr.pratica = a_pratica
               and ogpr.oggetto = ogge.oggetto
               and nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto) = 2
            having sum(ogim.imposta_erariale) > 0
            union
            select 'IMU - ALTRI FABBRICATI',
                   'S',
                   round(nvl(sum(decode(sign(ogim.anno - 2012),
                                             1,decode(substr(ogpr.categoria_catasto,1,1) ||
                                                      to_char(nvl(ogim.tipo_aliquota,-1)),
                                                      'D9',0,
                                                      decode(nvl(aliq.flag_fabbricati_merce,'N'),
                                                             'S',0,
                                                             ogim.imposta_erariale_acconto)),
                                         ogim.imposta_erariale_acconto)),0)) acconto,
                   round(nvl(sum(decode(sign(ogim.anno - 2012),
                                             1,decode(substr(ogpr.categoria_catasto,1,1) ||
                                                      to_char(nvl(ogim.tipo_aliquota,-1)),
                                                      'D9',0,
                                                      decode(nvl(aliq.flag_fabbricati_merce,'N'),
                                                             'S',0,
                                                             ogim.imposta_erariale)),
                                         ogim.imposta_erariale)),0)) -
                   round(nvl(sum(decode(sign(ogim.anno - 2012),
                                             1,decode(substr(ogpr.categoria_catasto,1,1) ||
                                                      to_char(nvl(ogim.tipo_aliquota,-1)),
                                                      'D9',0,
                                                      decode(nvl(aliq.flag_fabbricati_merce,'N'),
                                                             'S',0,
                                                             ogim.imposta_erariale_acconto)),
                                         ogim.imposta_erariale_acconto)),0)) saldo,
                   round(nvl(sum(decode(sign(ogim.anno - 2012),
                                             1,decode(substr(ogpr.categoria_catasto,1,1) ||
                                                      to_char(nvl(ogim.tipo_aliquota,-1)),
                                                      'D9',0,
                                                      decode(nvl(aliq.flag_fabbricati_merce,'N'),
                                                             'S',0,
                                                             ogim.imposta_erariale)),
                                         ogim.imposta_erariale)),0)) totale
              from oggetti_imposta ogim,
                   oggetti_pratica ogpr,
                   oggetti ogge,
                   aliquote aliq
             where ogim.oggetto_pratica = ogpr.oggetto_pratica
               and ogpr.pratica = a_pratica
               and ogpr.oggetto = ogge.oggetto
               and ogim.tipo_tributo = aliq.tipo_tributo (+)
               and ogim.anno = aliq.anno (+)
               and nvl(ogim.tipo_aliquota,-1) = aliq.tipo_aliquota (+)
               and nvl(ogim.tipo_aliquota,-1) <> 2
               and nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto) not in (1,2)
               and ogim.aliquota_erariale is not null
            having sum(decode(sign(ogim.anno - 2012),
                              1,decode(substr(ogpr.categoria_catasto,1,1) ||
                                       to_char(nvl(ogim.tipo_aliquota,-1)),
                                       'D9',0,
                                       decode(nvl(aliq.flag_fabbricati_merce,'N'),
                                              'S',0,
                                              ogim.imposta_erariale)),
                              ogim.imposta_erariale)) > 0
            union
            select 'IMU - IMM. PROD. (GR.C.D)',
                   'S',
                   round(nvl(sum(decode(sign(ogim.anno - 2012),
                                 1,decode(substr(ogpr.categoria_catasto,1,1) ||
                                          to_char(nvl(ogim.tipo_aliquota,-1)),
                                          'D9',ogim.imposta_erariale_acconto,
                                          0),
                                 0)),0)) acconto,
                   round(nvl(sum(decode(sign(ogim.anno - 2012),
                                 1,decode(substr(ogpr.categoria_catasto,1,1) ||
                                          to_char(nvl(ogim.tipo_aliquota,-1)),
                                          'D9',ogim.imposta_erariale,
                                          0),
                                 0)),0)) -
                   round(nvl(sum(decode(sign(ogim.anno - 2012),
                                 1,decode(substr(ogpr.categoria_catasto,1,1) ||
                                          to_char(nvl(ogim.tipo_aliquota,-1)),
                                          'D9',ogim.imposta_erariale_acconto,
                                          0),
                                 0)),0)) saldo,
                   round(nvl(sum(decode(sign(ogim.anno - 2012),
                                 1,decode(substr(ogpr.categoria_catasto,1,1) ||
                                          to_char(nvl(ogim.tipo_aliquota,-1)),
                                          'D9',ogim.imposta_erariale,
                                          0),
                                 0)),0)) totale
              from oggetti_imposta ogim,
                   oggetti_pratica ogpr,
                   oggetti ogge
             where ogim.oggetto_pratica = ogpr.oggetto_pratica
               and ogpr.pratica = a_pratica
               and ogpr.oggetto = ogge.oggetto
               and nvl(ogim.tipo_aliquota,-1) <> 2
               and nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto) not in (1,2)
               and aliquota_erariale is not null
            having sum(decode(sign(ogim.anno - 2012),
                       1,decode(substr(ogpr.categoria_catasto,1,1) ||
                                to_char(nvl(ogim.tipo_aliquota,-1)),
                                'D9',ogim.imposta_erariale,
                                0),
                       0)) > 0)
     where codice = nvl(a_tipo_ente,codice);
    return nvl(w_importo,0);
  end;
------------------------------------------------------------------
  function importi_riep(a_cf      varchar2,
                        a_pratica number,
                        a_anno    number,
                        a_data    varchar2) return sys_refcursor is
  /******************************************************************************
    NOME:        IMPORTI_RIEP
    DESCRIZIONE: Restituisce un ref_cursor contenente l'elenco delle imposte dovute
    RITORNA:     ref_cursor.
    NOTE:
    Rev.  Data        Autore  Descrizione
    ----  ----------  ------  ----------------------------------------------------
    002   06/11/2023  RV      Issue #66896: sistemato deim_vers_tot_arr, aggiunto deim_diff_tot_arr.
    001   XX/XX/XXXX  XX      Versione iniziale
  ******************************************************************************/
    rc     sys_refcursor;
    p_data date;
    p_tipo_tributo varchar2(5);
  begin
    p_data := to_date(a_data, 'DD/MM/YYYY');
    p_tipo_tributo := stampa_common.f_get_tipo_tributo(a_pratica);
    open rc for
      select
      -- CAMPI AGGIUNTI --
       a_cf      as cod_fiscale,
       a_pratica as pratica,
       a_anno    as anno,
       a_data    as data,
       -- FINE CAMPI AGGIUNTI --
       decode(nvl(vd.deim_tot_comune,0) + nvl(vd.deim_vers_tot_comune,0)
             ,0,null
             ,lpad(stampa_common.f_formatta_numero(vd.deim_tot_comune,
                                                  'I','N'
                                                  ),
                   18)
             ) deim_tot_comune,
       decode(nvl(vd.deim_tot_comune,0) + nvl(vd.deim_vers_tot_comune,0)
             ,0,null
             ,lpad(stampa_common.f_formatta_numero(importi_comune_stato(a_pratica
                                                                       ,'U'
                                                                       ,'C'
                                                                       ),
                                                  'I','N'
                                                  ),
                   18)
             ) deim_tot_comune_arr,
       decode(nvl(vd.deim_tot_comune,0) + nvl(vd.deim_vers_tot_comune,0)
             ,0,null
             ,lpad(stampa_common.f_formatta_numero(vd.deim_vers_tot_comune,
                                                   'I','N'
                                                  ),
                  18)
             ) deim_vers_tot_comune,
       decode(nvl(vd.deim_tot_comune,0) + nvl(vd.deim_vers_tot_comune,0)
             ,0,null
             ,lpad(stampa_common.f_formatta_numero(vd.deim_diff_tot_comune,
                                                   'I','N'
                                                  ),
                  18)
             ) deim_diff_tot_comune,
--   campo doppio, ma poi rinominato il secondo come _arr
       decode(nvl(vd.deim_tot_comune,0) + nvl(vd.deim_vers_tot_comune,0)
             ,0,null
             ,lpad(stampa_common.f_formatta_numero(importi_comune_stato(a_pratica
                                                                       ,'U'
                                                                       ,'C'
                                                                       ) -
                                                   nvl(vd.deim_vers_tot_comune,0),
                                                   'I','N'
                                                  ),
                  18)
             ) deim_diff_tot_comune_arr,
       decode(nvl(vd.deim_tot_stato,0) + nvl(vd.deim_vers_tot_stato,0)
             ,0,null
             ,lpad(stampa_common.f_formatta_numero(vd.deim_tot_stato,
                                                   'I','N'
                                                  ),
                  18)
             ) deim_tot_stato,
       decode(nvl(vd.deim_tot_stato,0) + nvl(vd.deim_vers_tot_stato,0)
             ,0,null
             ,lpad(stampa_common.f_formatta_numero(importi_comune_stato(a_pratica
                                                                       ,'U'
                                                                       ,'S'
                                                                       ),
                                                   'I','N'
                                                  ),
                  18)
             ) deim_tot_stato_arr,
       decode(nvl(vd.deim_tot_stato,0) + nvl(vd.deim_vers_tot_stato,0)
             ,0,null
             ,lpad(stampa_common.f_formatta_numero(vd.deim_vers_tot_stato,
                                                   'I','N'
                                                  ),
                  18)
             ) deim_vers_tot_stato,
       decode(nvl(vd.deim_tot_stato,0) + nvl(vd.deim_vers_tot_stato,0)
             ,0,null
             ,lpad(stampa_common.f_formatta_numero(vd.deim_diff_tot_stato,
                                                   'I','N'
                                                  ),
                  18)
             ) deim_diff_tot_stato,
       decode(nvl(vd.deim_tot_stato,0) + nvl(vd.deim_vers_tot_stato,0)
             ,0,null
             ,lpad(stampa_common.f_formatta_numero(importi_comune_stato(a_pratica
                                                                       ,'U'
                                                                       ,'S'
                                                                       ) -
                                                   nvl(vd.deim_vers_tot_stato,0),
                                                   'I','N'
                                                  ),
                  18)
             ) deim_diff_tot_stato_arr,
       lpad(stampa_common.f_formatta_numero(vd.deim_tot,'I','S'),43) deim_tot,
       lpad(stampa_common.f_formatta_numero(importi_comune_stato(a_pratica
                                                                       ,'U'
                                                                       ,''
                                                                       ),'I','S'),43) deim_tot_arr,
       lpad(stampa_common.f_formatta_numero(vd.deim_vers_tot,'I','S'),18) deim_vers_tot,
       lpad(stampa_common.f_formatta_numero(vd.deim_diff_tot,'I','S'),18) deim_diff_tot,
       lpad(stampa_common.f_formatta_numero(importi_comune_stato(a_pratica
                                                                       ,'U'
                                                                       ,''
                                                                       ) -
                                            nvl(vd.deim_vers_tot,0)
                                            ,'I','S'),18) deim_diff_tot_arr,
       decode(nvl(vd.deim_tot_comune,0) + nvl(vd.deim_vers_tot_comune,0)
             ,0,null
             ,rpad('Comune Totale', 43)) st_comune,
       decode(nvl(vd.deim_tot_comune,0) + nvl(vd.deim_vers_tot_comune,0)
             ,0,null
             ,lpad(' ', 43) || rpad(' _', 18, '_') || rpad(' _', 18, '_') ||
              rpad(' _', 18, '_')) line_comune,
       decode(nvl(vd.deim_tot_comune,0) + nvl(vd.deim_vers_tot_comune,0)
             ,0,null
             ,lpad(' ', 97, ' ')) line_comune_2,
       decode(nvl(vd.deim_tot_stato,0) + nvl(vd.deim_vers_tot_stato,0)
             ,0,null
             ,lpad(' ', 43) || rpad(' _', 18, '_') || rpad(' _', 18, '_') ||
              rpad(' _', 18, '_')) line_stato,
       decode(nvl(vd.deim_tot_stato,0) + nvl(vd.deim_vers_tot_stato,0)
             ,0,null
             ,rpad('Stato Totale', 43)) st_stato,
       decode(nvl(vd.deim_tot_stato,0) + nvl(vd.deim_vers_tot_stato,0)
             ,0,null
             ,lpad(' ', 43) || rpad(' _', 18, '_') || rpad(' _', 18, '_') ||
              rpad(' _', 18, '_')) line_stato_2
        from (select sum(ogim.imposta - nvl(ogim.imposta_erariale, 0)) deim_tot_comune,
                     max(vers.ab_principale) +
                     max(f_importo_vers_ravv_dett(a_cf,
                                                  p_tipo_tributo, --'ICI',
                                                  a_anno,
                                                  'U',
                                                  'ABP',
                                                  p_data)) +
                     max(vers.rurali) +
                     max(f_importo_vers_ravv_dett(a_cf,
                                                  p_tipo_tributo, --'ICI',
                                                  a_anno,
                                                  'U',
                                                  'RUR',
                                                  p_data)) +
                     max(vers.terreni_comune) +
                     max(f_importo_vers_ravv_dett(a_cf,
                                                  p_tipo_tributo, --'ICI',
                                                  a_anno,
                                                  'U',
                                                  'TEC',
                                                  p_data)) +
                     max(vers.aree_comune) +
                     max(f_importo_vers_ravv_dett(a_cf,
                                                  p_tipo_tributo, --'ICI',
                                                  a_anno,
                                                  'U',
                                                  'ARC',
                                                  p_data)) +
                     max(vers.altri_comune) +
                     max(f_importo_vers_ravv_dett(a_cf,
                                                  p_tipo_tributo, --'ICI',
                                                  a_anno,
                                                  'U',
                                                  'ALC',
                                                  p_data)) +
                     max(vers.fabb_d_comune) +
                     max(f_importo_vers_ravv_dett(a_cf,
                                                  p_tipo_tributo, --'ICI',
                                                  a_anno,
                                                  'U',
                                                  'FDC',
                                                  p_data)) +
                     max(vers.fabbricati_merce) +
                     max(f_importo_vers_ravv_dett(a_cf,
                                                  p_tipo_tributo, --'ICI',
                                                  a_anno,
                                                  'U',
                                                  'FAM',
                                                  p_data)) deim_vers_tot_comune,
                     sum(ogim.imposta - nvl(ogim.imposta_erariale, 0)) -
                    (max(vers.ab_principale) +
                     max(f_importo_vers_ravv_dett(a_cf,
                                                  p_tipo_tributo, --'ICI',
                                                  a_anno,
                                                  'U',
                                                  'ABP',
                                                  p_data)) +
                     max(vers.rurali) +
                     max(f_importo_vers_ravv_dett(a_cf,
                                                  p_tipo_tributo, --'ICI',
                                                  a_anno,
                                                  'U',
                                                  'RUR',
                                                  p_data)) +
                     max(vers.terreni_comune) +
                     max(f_importo_vers_ravv_dett(a_cf,
                                                  p_tipo_tributo, --'ICI',
                                                  a_anno,
                                                  'U',
                                                  'TEC',
                                                  p_data)) +
                     max(vers.aree_comune) +
                     max(f_importo_vers_ravv_dett(a_cf,
                                                  p_tipo_tributo, --'ICI',
                                                  a_anno,
                                                  'U',
                                                  'ARC',
                                                  p_data)) +
                     max(vers.altri_comune) +
                     max(f_importo_vers_ravv_dett(a_cf,
                                                  p_tipo_tributo, --'ICI',
                                                  a_anno,
                                                  'U',
                                                  'ALC',
                                                  p_data)) +
                     max(vers.fabb_d_comune) +
                     max(f_importo_vers_ravv_dett(a_cf,
                                                  p_tipo_tributo, --'ICI',
                                                  a_anno,
                                                  'U',
                                                  'FDC',
                                                  p_data)) +
                     max(vers.fabbricati_merce) +
                     max(f_importo_vers_ravv_dett(a_cf,
                                                  p_tipo_tributo, --'ICI',
                                                  a_anno,
                                                  'U',
                                                  'FAM',
                                                  p_data))) deim_diff_tot_comune,
                     sum(ogim.imposta_erariale) deim_tot_stato,
                     max(vers.terreni_erariale) +
                     max(f_importo_vers_ravv_dett(a_cf,
                                                  p_tipo_tributo, --'ICI',
                                                  a_anno,
                                                  'U',
                                                  'TEE',
                                                  p_data)) +
                     max(vers.aree_erariale) +
                     max(f_importo_vers_ravv_dett(a_cf,
                                                  p_tipo_tributo, --'ICI',
                                                  a_anno,
                                                  'U',
                                                  'ARE',
                                                  p_data)) +
                     max(vers.altri_erariale) +
                     max(f_importo_vers_ravv_dett(a_cf,
                                                  p_tipo_tributo, --'ICI',
                                                  a_anno,
                                                  'U',
                                                  'ALE',
                                                  p_data)) +
                     max(vers.fabb_d_erariale) +
                     max(f_importo_vers_ravv_dett(a_cf,
                                                  p_tipo_tributo, --'ICI',
                                                  a_anno,
                                                  'U',
                                                  'FDE',
                                                  p_data)) deim_vers_tot_stato,
                     nvl(sum(ogim.imposta_erariale),0) -
                    (max(vers.terreni_erariale) +
                     max(f_importo_vers_ravv_dett(a_cf,
                                                  p_tipo_tributo, --'ICI',
                                                  a_anno,
                                                  'U',
                                                  'TEE',
                                                  p_data)) +
                     max(vers.aree_erariale) +
                     max(f_importo_vers_ravv_dett(a_cf,
                                                  p_tipo_tributo, --'ICI',
                                                  a_anno,
                                                  'U',
                                                  'ARE',
                                                  p_data)) +
                     max(vers.altri_erariale) +
                     max(f_importo_vers_ravv_dett(a_cf,
                                                  p_tipo_tributo, --'ICI',
                                                  a_anno,
                                                  'U',
                                                  'ALE',
                                                  p_data)) +
                     max(vers.fabb_d_erariale) +
                     max(f_importo_vers_ravv_dett(a_cf,
                                                  p_tipo_tributo, --'ICI',
                                                  a_anno,
                                                  'U',
                                                  'FDE',
                                                  p_data))) deim_diff_tot_stato,
                     sum(ogim.imposta) deim_tot,
                     max(vers.ab_principale) +
                     max(f_importo_vers_ravv_dett(a_cf,
                                                  p_tipo_tributo, --'ICI',
                                                  a_anno,
                                                  'U',
                                                  'ABP',
                                                  p_data)) +
                     max(vers.rurali) +
                     max(f_importo_vers_ravv_dett(a_cf,
                                                  p_tipo_tributo, --'ICI',
                                                  a_anno,
                                                  'U',
                                                  'RUR',
                                                  p_data)) +
                     max(vers.terreni_comune) +
                     max(f_importo_vers_ravv_dett(a_cf,
                                                  p_tipo_tributo, --'ICI',
                                                  a_anno,
                                                  'U',
                                                  'TEC',
                                                  p_data)) +
                     max(vers.aree_comune) +
                     max(f_importo_vers_ravv_dett(a_cf,
                                                  p_tipo_tributo, --'ICI',
                                                  a_anno,
                                                  'U',
                                                  'ARC',
                                                  p_data)) +
                     max(vers.altri_comune) +
                     max(f_importo_vers_ravv_dett(a_cf,
                                                  p_tipo_tributo, --'ICI',
                                                  a_anno,
                                                  'U',
                                                  'ALC',
                                                  p_data)) +
                     max(vers.fabb_d_comune) +
                     max(f_importo_vers_ravv_dett(a_cf,
                                                  p_tipo_tributo, --'ICI',
                                                  a_anno,
                                                  'U',
                                                  'FDC',
                                                  p_data)) +
                     max(vers.terreni_erariale) +
                     max(f_importo_vers_ravv_dett(a_cf,
                                                  p_tipo_tributo, --'ICI',
                                                  a_anno,
                                                  'U',
                                                  'TEE',
                                                  p_data)) +
                     max(vers.aree_erariale) +
                     max(f_importo_vers_ravv_dett(a_cf,
                                                  p_tipo_tributo, --'ICI',
                                                  a_anno,
                                                  'U',
                                                  'ARE',
                                                  p_data)) +
                     max(vers.altri_erariale) +
                     max(f_importo_vers_ravv_dett(a_cf,
                                                  p_tipo_tributo, --'ICI',
                                                  a_anno,
                                                  'U',
                                                  'ALE',
                                                  p_data)) +
                     max(vers.fabb_d_erariale) +
                     max(f_importo_vers_ravv_dett(a_cf,
                                                  p_tipo_tributo, --'ICI',
                                                  a_anno,
                                                  'U',
                                                  'FDE',
                                                  p_data)) +
                     max(vers.fabbricati_merce) +
                     max(f_importo_vers_ravv_dett(a_cf,
                                                  p_tipo_tributo, --'ICI',
                                                  a_anno,
                                                  'U',
                                                  'FAM',
                                                  p_data)) deim_vers_tot,
                     sum(ogim.imposta) - (max(vers.ab_principale) +
                                         max(f_importo_vers_ravv_dett(a_cf,
                                                                      p_tipo_tributo, --'ICI',
                                                                      a_anno,
                                                                      'U',
                                                                      'ABP',
                                                                      p_data)) +
                                         max(vers.rurali) +
                                         max(f_importo_vers_ravv_dett(a_cf,
                                                                      p_tipo_tributo, --'ICI',
                                                                      a_anno,
                                                                      'U',
                                                                      'RUR',
                                                                      p_data)) +
                                         max(vers.terreni_comune) +
                                         max(f_importo_vers_ravv_dett(a_cf,
                                                                      p_tipo_tributo, --'ICI',
                                                                      a_anno,
                                                                      'U',
                                                                      'TEC',
                                                                      p_data)) +
                                         max(vers.aree_comune) +
                                         max(f_importo_vers_ravv_dett(a_cf,
                                                                      p_tipo_tributo, --'ICI',
                                                                      a_anno,
                                                                      'U',
                                                                      'ARC',
                                                                      p_data)) +
                                         max(vers.altri_comune) +
                                         max(f_importo_vers_ravv_dett(a_cf,
                                                                      p_tipo_tributo, --'ICI',
                                                                      a_anno,
                                                                      'U',
                                                                      'ALC',
                                                                      p_data)) +
                                         max(vers.fabb_d_comune) +
                                         max(f_importo_vers_ravv_dett(a_cf,
                                                                      p_tipo_tributo, --'ICI',
                                                                      a_anno,
                                                                      'U',
                                                                      'FDC',
                                                                      p_data)) +
                                         max(vers.terreni_erariale) +
                                         max(f_importo_vers_ravv_dett(a_cf,
                                                                      p_tipo_tributo, --'ICI',
                                                                      a_anno,
                                                                      'U',
                                                                      'TEE',
                                                                      p_data)) +
                                         max(vers.aree_erariale) +
                                         max(f_importo_vers_ravv_dett(a_cf,
                                                                      p_tipo_tributo, --'ICI',
                                                                      a_anno,
                                                                      'U',
                                                                      'ARE',
                                                                      p_data)) +
                                         max(vers.altri_erariale) +
                                         max(f_importo_vers_ravv_dett(a_cf,
                                                                      p_tipo_tributo, --'ICI',
                                                                      a_anno,
                                                                      'U',
                                                                      'ALE',
                                                                      p_data)) +
                                         max(vers.fabb_d_erariale) +
                                         max(f_importo_vers_ravv_dett(a_cf,
                                                                      p_tipo_tributo, --'ICI',
                                                                      a_anno,
                                                                      'U',
                                                                      'FDE',
                                                                      p_data)) +
                                        max(vers.fabbricati_merce) +
                                        max(f_importo_vers_ravv_dett(a_cf,
                                                                     p_tipo_tributo, --'ICI',
                                                                     a_anno,
                                                                     'U',
                                                                     'FAM',
                                                                     p_data))) deim_diff_tot
                from oggetti_imposta ogim,
                     oggetti_pratica ogpr,
                     oggetti ogge,
                     (select nvl(sum(ab_principale), 0) ab_principale,
                             nvl(sum(rurali_comune), 0) rurali,
                             nvl(sum(terreni_comune), 0) terreni_comune,
                             nvl(sum(aree_comune), 0) aree_comune,
                             nvl(sum(altri_comune), 0) altri_comune,
                             nvl(sum(fabbricati_d_comune), 0) fabb_d_comune,
                             nvl(sum(terreni_erariale), 0) terreni_erariale,
                             nvl(sum(aree_erariale), 0) aree_erariale,
                             nvl(sum(altri_erariale), 0) altri_erariale,
                             nvl(sum(fabbricati_d_erariale), 0) fabb_d_erariale,
                             nvl(sum(fabbricati_merce),0) fabbricati_merce
                        from versamenti vers
                       where vers.tipo_tributo || '' = p_tipo_tributo --'ICI'
                         and vers.anno >= 2012
                         and vers.pratica is null
                         and vers.anno = a_anno
                         and vers.cod_fiscale = a_cf
                         and vers.data_pagamento <= p_data) vers
               where ogim.oggetto_pratica = ogpr.oggetto_pratica
                 and ogpr.pratica = a_pratica
                 and ogpr.oggetto = ogge.oggetto) vd;
    return rc;
  end;
------------------------------------------------------------------
  function importi_riep_deim_comune(a_cf             varchar2,
                                    a_pratica        number,
                                    a_anno           number,
                                    a_data           varchar2,
                                    a_tot_dovuto     varchar2,
                                    a_tot_versato    varchar2,
                                    a_tot_differenza varchar2,
                                    a_st_comune      varchar2)
    return sys_refcursor is
  /******************************************************************************
    NOME:        IMPORTI_RIEP_DEIM_COMUNE.
    DESCRIZIONE: Restituisce un ref_cursor contenente l'elenco delle imposte
                 dovute al comune suddivise per tipologia (codice tributo F24).
    RITORNA:     ref_cursor.
    NOTE:
    Rev.  Data        Autore  Descrizione
    ----  ----------  ------  ----------------------------------------------------
    002   06/11/2023  RV      Issue #66896: sistemato tot_versato_arr, aggiunto versato_arr.
    001   29/12/2021  VD      Issue #53742: aggiunti importi arrotondati.
  ******************************************************************************/
    rc     sys_refcursor;
    p_data date;
  begin
    p_data := to_date(a_data, 'DD/MM/YYYY');
    open rc for
      select decode(row_number() over(partition by deim.cod_sorgente order by
                         deim.codice),
                    1,
                    'Comune',
                    '') origine,
             deim.cod_sorgente,
             a_tot_dovuto as tot_dovuto,
             a_tot_versato as tot_versato,
             a_tot_differenza as tot_differenza,
             a_st_comune as st_comune,
             deim.descrizione,
             deim.codice,
             stampa_common.f_formatta_numero(deim.dovuto,'I','S') dovuto,
             stampa_common.f_formatta_numero(deim.versato,'I','S') versato,
             stampa_common.f_formatta_numero(nvl(deim.dovuto, 0) - nvl(deim.versato, 0),'I','S') differenza,
             stampa_common.f_formatta_numero(round(deim.dovuto),'I','S') dovuto_arr,
             stampa_common.f_formatta_numero(round(deim.versato),'I','S') versato_arr,
             stampa_common.f_formatta_numero(round(nvl(deim.dovuto, 0)) -
                                             round(nvl(deim.versato, 0)),'I','S') differenza_arr,
             stampa_common.f_formatta_numero(sum(round(nvl(deim.dovuto, 0))) over(),'I','S') tot_dovuto_arr,
             stampa_common.f_formatta_numero(sum(round(nvl(deim.versato, 0))) over(),'I','S') tot_versato_arr,
             stampa_common.f_formatta_numero(sum(round(nvl(deim.dovuto, 0)) -
                                                 round(nvl(deim.versato, 0))) over(),'I','S') tot_differenza_arr
--AB 09/06/2023 aggiornati come quelli relativi allo stato, per queste due righe
--             stampa_common.f_formatta_numero(round(deim.dovuto) - deim.versato,'I','S') differenza_arr,
--             stampa_common.f_formatta_numero(sum(round(deim.dovuto) - deim.versato) over(),'I','S') tot_differenza_arr
        from (select 'C' cod_sorgente,
                     'IMU - AB. PRINC. E PERT.' descrizione,
                     3912 codice,
                     sum(decode(f_get_cod_tributo_f24(ogim.oggetto_imposta,'C')
                               ,'3912',ogim.imposta
                               ,0
                               )
                        ) dovuto,
                     max(vers.ab_principale) +
                     max(f_importo_vers_ravv_dett(a_cf,
                                                  'ICI',
                                                  a_anno,
                                                  'U',
                                                  'ABP',
                                                  p_data)) versato
                from oggetti_imposta ogim,
                     oggetti_pratica ogpr,
                     (select nvl(sum(ab_principale), 0) ab_principale
                        from versamenti vers
                       where vers.tipo_tributo || '' = 'ICI'
                         and vers.anno >= 2012
                         and vers.pratica is null
                         and vers.anno = a_anno
                         and vers.cod_fiscale = a_cf
                         and vers.data_pagamento <= p_data) vers
               where ogim.oggetto_pratica = ogpr.oggetto_pratica
                 and ogpr.pratica = a_pratica
              having sum(decode(f_get_cod_tributo_f24(ogim.oggetto_imposta,'C')
                               ,'3912',ogim.imposta
                               ,0
                               )
                        ) > 0
                  or max(vers.ab_principale) +
                     max(f_importo_vers_ravv_dett(a_cf,
                                                  'ICI',
                                                  a_anno,
                                                  'U',
                                                  'ABP',
                                                  p_data)) > 0
              union
              select 'C' cod_sorgente,
                     'IMU - FABB. RUR. AD USO STRUM.',
                     3913,
                     sum(decode(f_get_cod_tributo_f24(ogim.oggetto_imposta,'C')
                               ,'3913',ogim.imposta
                               ,0
                               )
                        ),
                     max(vers.rurali) +
                     max(f_importo_vers_ravv_dett(a_cf,
                                                  'ICI',
                                                  a_anno,
                                                  'U',
                                                  'RUR',
                                                  p_data))
                from oggetti_imposta ogim,
                     oggetti_pratica ogpr,
                     oggetti ogge,
                     (select nvl(sum(rurali_comune), 0) rurali
                        from versamenti vers
                       where vers.tipo_tributo || '' = 'ICI'
                         and vers.anno >= 2012
                         and vers.pratica is null
                         and vers.anno = a_anno
                         and vers.cod_fiscale = a_cf
                         and vers.data_pagamento <= p_data) vers
               where ogim.oggetto_pratica = ogpr.oggetto_pratica
                 and ogpr.pratica = a_pratica
                 and ogpr.oggetto = ogge.oggetto
              having sum(decode(f_get_cod_tributo_f24(ogim.oggetto_imposta,'C')
                               ,'3913',ogim.imposta
                               ,0
                               )
                        ) > 0
                  or max(vers.rurali) +
                     max(f_importo_vers_ravv_dett(a_cf,
                                                  'ICI',
                                                  a_anno,
                                                  'U',
                                                  'RUR',
                                                  p_data)) > 0
              union
              select 'C' cod_sorgente,
                     'IMU - TERRENI',
                     3914,
                     sum(decode(f_get_cod_tributo_f24(ogim.oggetto_imposta,'C')
                               ,'3914',ogim.imposta - nvl(ogim.imposta_erariale, 0)
                               ,0
                               )
                        ),
                     max(vers.terreni_comune) +
                     max(f_importo_vers_ravv_dett(a_cf,
                                                  'ICI',
                                                   a_anno,
                                                   'U',
                                                   'TEC',
                                                   p_data))
                from oggetti_imposta ogim,
                     oggetti_pratica ogpr,
                     oggetti ogge,
                     (select nvl(sum(terreni_comune), 0) terreni_comune
                        from versamenti vers
                       where vers.tipo_tributo || '' = 'ICI'
                         and vers.anno >= 2012
                         and vers.pratica is null
                         and vers.anno = a_anno
                         and vers.cod_fiscale = a_cf
                         and vers.data_pagamento <= p_data) vers
               where ogim.oggetto_pratica = ogpr.oggetto_pratica
                 and ogpr.pratica = a_pratica
                 and ogpr.oggetto = ogge.oggetto
              having sum(decode(f_get_cod_tributo_f24(ogim.oggetto_imposta,'C')
                               ,'3914',ogim.imposta - nvl(ogim.imposta_erariale, 0)
                               ,0
                               )
                        ) > 0
                  or max(vers.terreni_comune) +
                     max(f_importo_vers_ravv_dett(a_cf,
                                                  'ICI',
                                                  a_anno,
                                                  'U',
                                                  'TEC',
                                                  p_data)) > 0
              union
              select 'C' cod_sorgente,
                     'IMU - AREE FABBRICABILI',
                     3916,
                     sum(decode(f_get_cod_tributo_f24(ogim.oggetto_imposta,'C')
                               ,'3916',ogim.imposta - nvl(ogim.imposta_erariale, 0)
                               ,0
                               )
                        ),
                     max(vers.aree_comune) +
                     max(f_importo_vers_ravv_dett(a_cf,
                                                  'ICI',
                                                   a_anno,
                                                   'U',
                                                   'ARC',
                                                   p_data))
                from oggetti_imposta ogim,
                     oggetti_pratica ogpr,
                     oggetti ogge,
                     (select nvl(sum(aree_comune), 0) aree_comune
                        from versamenti vers
                       where vers.tipo_tributo || '' = 'ICI'
                         and vers.anno >= 2012
                         and vers.pratica is null
                         and vers.anno = a_anno
                         and vers.cod_fiscale = a_cf
                         and vers.data_pagamento <= p_data) vers
               where ogim.oggetto_pratica = ogpr.oggetto_pratica
                 and ogpr.pratica = a_pratica
                 and ogpr.oggetto = ogge.oggetto
              having sum(decode(f_get_cod_tributo_f24(ogim.oggetto_imposta,'C')
                               ,'3916',ogim.imposta - nvl(ogim.imposta_erariale, 0)
                               ,0
                               )
                        ) > 0
                  or max(vers.aree_comune) +
                     max(f_importo_vers_ravv_dett(a_cf,
                                                  'ICI',
                                                  a_anno,
                                                  'U',
                                                  'ARC',
                                                  p_data)) > 0
              union
              select 'C' cod_sorgente,
                     'IMU - ALTRI FABBRICATI',
                     3918,
                     sum(decode(f_get_cod_tributo_f24(ogim.oggetto_imposta,'C')
                               ,'3918',ogim.imposta - nvl(ogim.imposta_erariale,0)
                               )
                        ),
                     max(vers.altri_comune) +
                     max(f_importo_vers_ravv_dett(a_cf,
                                                  'ICI',
                                                   a_anno,
                                                   'U',
                                                   'ALC',
                                                   p_data))
                from oggetti_imposta ogim,
                     oggetti_pratica ogpr,
                     oggetti ogge,
                     (select nvl(sum(altri_comune), 0) altri_comune
                        from versamenti vers
                       where vers.tipo_tributo || '' = 'ICI'
                         and vers.anno >= 2012
                         and vers.pratica is null
                         and vers.anno = a_anno
                         and vers.cod_fiscale = a_cf
                         and vers.data_pagamento <= p_data) vers
               where ogim.oggetto_pratica = ogpr.oggetto_pratica
                 and ogpr.pratica = a_pratica
                 and ogpr.oggetto = ogge.oggetto
              having sum(decode(f_get_cod_tributo_f24(ogim.oggetto_imposta,'C')
                               ,'3918',ogim.imposta - nvl(ogim.imposta_erariale,0)
                               )
                        ) > 0
                  or max(vers.altri_comune) +
                     max(f_importo_vers_ravv_dett(a_cf,
                                                  'ICI',
                                                  a_anno,
                                                  'U',
                                                  'ALC',
                                                  p_data)) > 0
              union
              select 'C' cod_sorgente,
                     'IMU - IMM. PROD. (GR.C.D)-INC.',
                     3930,
                     sum(decode(f_get_cod_tributo_f24(ogim.oggetto_imposta,'C')
                               ,'3930',ogim.imposta - nvl(ogim.imposta_erariale,0)
                               )
                        ),
                     max(vers.fabb_d_comune) +
                     max(f_importo_vers_ravv_dett(a_cf,
                                                  'ICI',
                                                   a_anno,
                                                   'U',
                                                   'FDC',
                                                   p_data))
                from oggetti_imposta ogim,
                     oggetti_pratica ogpr,
                     oggetti ogge,
                     (select nvl(sum(fabbricati_d_comune), 0) fabb_d_comune
                        from versamenti vers
                       where vers.tipo_tributo || '' = 'ICI'
                         and vers.anno >= 2012
                         and vers.pratica is null
                         and vers.anno = a_anno
                         and vers.cod_fiscale = a_cf
                         and vers.data_pagamento <= p_data) vers
               where ogim.oggetto_pratica = ogpr.oggetto_pratica
                 and ogpr.pratica = a_pratica
                 and ogpr.oggetto = ogge.oggetto
              having sum(decode(f_get_cod_tributo_f24(ogim.oggetto_imposta,'C')
                               ,'3930',ogim.imposta - nvl(ogim.imposta_erariale,0)
                               )
                        ) > 0
                  or max(vers.fabb_d_comune) +
                     max(f_importo_vers_ravv_dett(a_cf,
                                                  'ICI',
                                                  a_anno,
                                                  'U',
                                                  'FDC',
                                                  p_data)) > 0
              union
              select 'C' cod_sorgente,
                     'IMU - IMM.COSTR.DEST.VENDITA',
                     3939,
                     sum(decode(f_get_cod_tributo_f24(ogim.oggetto_imposta,'C')
                               ,'3939',ogim.imposta - nvl(ogim.imposta_erariale,0)
                               )
                        ),
                     max(vers.fabbricati_merce) +
                     max(f_importo_vers_ravv_dett(a_cf,
                                                  'ICI',
                                                   a_anno,
                                                   'U',
                                                   'FAM',
                                                   p_data))
                from oggetti_imposta ogim,
                     oggetti_pratica ogpr,
                     oggetti ogge,
                     (select nvl(sum(fabbricati_merce), 0) fabbricati_merce
                        from versamenti vers
                       where vers.tipo_tributo || '' = 'ICI'
                         and vers.anno >= 2012
                         and vers.pratica is null
                         and vers.anno = a_anno
                         and vers.cod_fiscale = a_cf
                         and vers.data_pagamento <= p_data) vers
               where ogim.oggetto_pratica = ogpr.oggetto_pratica
                 and ogpr.pratica = a_pratica
                 and ogpr.oggetto = ogge.oggetto
              having sum(decode(f_get_cod_tributo_f24(ogim.oggetto_imposta,'C')
                               ,'3939',ogim.imposta - nvl(ogim.imposta_erariale,0)
                               )
                        ) > 0
                  or max(vers.fabbricati_merce) +
                     max(f_importo_vers_ravv_dett(a_cf,
                                                  'ICI',
                                                  a_anno,
                                                  'U',
                                                  'FAM',
                                                  p_data)) > 0) deim
       order by deim.codice;
    return rc;
  end;
------------------------------------------------------------------
  function importi_riep_deim_stato(a_cf             varchar2,
                                   a_pratica        number,
                                   a_anno           number,
                                   a_data           varchar2,
                                   a_tot_dovuto     varchar2,
                                   a_tot_versato    varchar2,
                                   a_tot_differenza varchar2,
                                   a_st_stato       varchar2)
    return sys_refcursor is
  /******************************************************************************
    NOME:        IMPORTI_RIEP_DEIM_STATO.
    DESCRIZIONE: Restituisce un ref_cursor contenente l'elenco delle imposte
                 dovute all'erario suddivise per tipologia (codice tributo F24).
    RITORNA:     ref_cursor.
    NOTE:
    Rev.  Data        Autore  Descrizione
    ----  ----------  ------  ----------------------------------------------------
    002   06/11/2023  RV      Issue #66896: sistemato tot_versato_arr, aggiunto versato_arr.
    001   29/12/2021  VD      Issue #53742: aggiunti importi arrotondati.
  ******************************************************************************/
    rc     sys_refcursor;
    p_data date;
  begin
    p_data := to_date(a_data, 'DD/MM/YYYY');
    open rc for
      select decode(row_number() over(partition by deim.cod_sorgente order by
                         deim.codice),
                    1,
                    'Stato',
                    '') origine,
             deim.cod_sorgente,
             a_tot_dovuto as tot_dovuto,
             a_tot_versato as tot_versato,
             a_tot_differenza as tot_differenza,
             a_st_stato as st_stato,
             deim.descrizione,
             deim.codice,
             stampa_common.f_formatta_numero(deim.dovuto,'I','S') dovuto,
             stampa_common.f_formatta_numero(deim.versato,'I','S') versato,
             stampa_common.f_formatta_numero(nvl(deim.dovuto, 0) - nvl(deim.versato, 0),'I','S') differenza,
             stampa_common.f_formatta_numero(round(deim.dovuto),'I','S') dovuto_arr,
             stampa_common.f_formatta_numero(round(deim.versato),'I','S') versato_arr,
             stampa_common.f_formatta_numero(round(nvl(deim.dovuto, 0)) -
                                             round(nvl(deim.versato, 0)),'I','S') differenza_arr,
             stampa_common.f_formatta_numero(sum(round(nvl(deim.dovuto, 0))) over(),'I','S') tot_dovuto_arr,
             stampa_common.f_formatta_numero(sum(round(nvl(deim.versato, 0))) over(),'I','S') tot_versato_arr,
             stampa_common.f_formatta_numero(sum(round(nvl(deim.dovuto, 0)) -
                                                 round(nvl(deim.versato, 0))) over(),'I','S') tot_differenza_arr
        from (select 'S' cod_sorgente,
                     'IMU - TERRENI' descrizione,
                     3915 codice,
                     sum(decode(f_get_cod_tributo_f24(ogim.oggetto_imposta,'S')
                               ,'3915',imposta_erariale
                               ,0
                               )
                        ) dovuto,
                     max(vers.terreni_erariale) +
                     max(f_importo_vers_ravv_dett(a_cf,
                                                   'ICI',
                                                   a_anno,
                                                   'U',
                                                   'TEE',
                                                   p_data)) versato
                from oggetti_imposta ogim,
                     oggetti_pratica ogpr,
                     oggetti ogge,
                     (select nvl(sum(terreni_erariale), 0) terreni_erariale
                        from versamenti vers
                       where vers.tipo_tributo || '' = 'ICI'
                         and vers.anno >= 2012
                         and vers.pratica is null
                         and vers.anno = a_anno
                         and vers.cod_fiscale = a_cf
                         and vers.data_pagamento <= p_data) vers
               where ogim.oggetto_pratica = ogpr.oggetto_pratica
                 and ogpr.pratica = a_pratica
                 and ogpr.oggetto = ogge.oggetto
              having sum(decode(f_get_cod_tributo_f24(ogim.oggetto_imposta,'S')
                               ,'3915',imposta_erariale
                               ,0
                               )
                        ) > 0
                  or max(vers.terreni_erariale) +
                     max(f_importo_vers_ravv_dett(a_cf,
                                                  'ICI',
                                                  a_anno,
                                                  'U',
                                                  'TEE',
                                                  p_data)) > 0
              union
              select 'S' cod_sorgente,
                     'IMU - AREE FABBRICABILI',
                     3917,
                     sum(decode(f_get_cod_tributo_f24(ogim.oggetto_imposta,'S')
                               ,'3917',ogim.imposta_erariale
                               ,0)
                        ),
                     max(vers.aree_erariale) +
                     max(f_importo_vers_ravv_dett(a_cf,
                                                   'ICI',
                                                   a_anno,
                                                   'U',
                                                   'ARE',
                                                   p_data))
                from oggetti_imposta ogim,
                     oggetti_pratica ogpr,
                     oggetti ogge,
                     (select nvl(sum(aree_erariale), 0) aree_erariale
                        from versamenti vers
                       where vers.tipo_tributo || '' = 'ICI'
                         and vers.anno >= 2012
                         and vers.pratica is null
                         and vers.anno = a_anno
                         and vers.cod_fiscale = a_cf
                         and vers.data_pagamento <= p_data) vers
               where ogim.oggetto_pratica = ogpr.oggetto_pratica
                 and ogpr.pratica = a_pratica
                 and ogpr.oggetto = ogge.oggetto
              having sum(decode(f_get_cod_tributo_f24(ogim.oggetto_imposta,'S')
                               ,'3917',ogim.imposta_erariale
                               ,0)
                        ) > 0
                  or max(vers.aree_erariale) +
                     max(f_importo_vers_ravv_dett(a_cf,
                                                  'ICI',
                                                  a_anno,
                                                  'U',
                                                  'ARE',
                                                  p_data)) > 0
              union
              select 'S' cod_sorgente,
                     'IMU - ALTRI FABBRICATI',
                     3919,
                     sum(decode(f_get_cod_tributo_f24(ogim.oggetto_imposta,'S')
                               ,'3919',ogim.imposta_erariale
                               ,0)
                        ),
                     max(vers.altri_erariale) +
                     max(f_importo_vers_ravv_dett(a_cf,
                                                   'ICI',
                                                   a_anno,
                                                   'U',
                                                   'ALE',
                                                   p_data))
                from oggetti_imposta ogim,
                     oggetti_pratica ogpr,
                     oggetti ogge,
                     (select nvl(sum(altri_erariale), 0) altri_erariale
                        from versamenti vers
                       where vers.tipo_tributo || '' = 'ICI'
                         and vers.anno >= 2012
                         and vers.pratica is null
                         and vers.anno = a_anno
                         and vers.cod_fiscale = a_cf
                         and vers.data_pagamento <= p_data) vers
               where ogim.oggetto_pratica = ogpr.oggetto_pratica
                 and ogpr.pratica = a_pratica
                 and ogpr.oggetto = ogge.oggetto
              having sum(decode(f_get_cod_tributo_f24(ogim.oggetto_imposta,'S')
                               ,'3919',ogim.imposta_erariale
                               ,0)
                        ) > 0
                  or max(vers.altri_erariale) +
                     max(f_importo_vers_ravv_dett(a_cf,
                                                  'ICI',
                                                  a_anno,
                                                  'U',
                                                  'ALE',
                                                  p_data)) > 0
              union
              select 'S' sorgente,
                     'IMU - IMM. PROD. (GR.C.D)',
                     3925,
                     sum(decode(f_get_cod_tributo_f24(ogim.oggetto_imposta,'S')
                               ,'3925',ogim.imposta_erariale
                               ,0)
                        ),
                     max(vers.fabb_d_erariale) +
                     max(f_importo_vers_ravv_dett(a_cf,
                                                   'ICI',
                                                   a_anno,
                                                   'U',
                                                   'FDE',
                                                   p_data))
                from oggetti_imposta ogim,
                     oggetti_pratica ogpr,
                     oggetti ogge,
                     (select nvl(sum(fabbricati_d_erariale), 0) fabb_d_erariale
                        from versamenti vers
                       where vers.tipo_tributo || '' = 'ICI'
                         and vers.anno >= 2012
                         and vers.pratica is null
                         and vers.anno = a_anno
                         and vers.cod_fiscale = a_cf
                         and vers.data_pagamento <= p_data) vers
               where ogim.oggetto_pratica = ogpr.oggetto_pratica
                 and ogpr.pratica = a_pratica
                 and ogpr.oggetto = ogge.oggetto
              having sum(decode(f_get_cod_tributo_f24(ogim.oggetto_imposta,'S')
                               ,'3925',ogim.imposta_erariale
                               ,0)
                        ) > 0
                  or max(vers.fabb_d_erariale) +
                     max(f_importo_vers_ravv_dett(a_cf,
                                                  'ICI',
                                                  a_anno,
                                                  'U',
                                                  'FDE',
                                                  p_data)) > 0) deim
       order by deim.codice;
    return rc;
  end;
------------------------------------------------------------------
  function importi_riep_acconto_saldo(a_pratica number default -1) return sys_refcursor is
  /******************************************************************************
    NOME:        IMPORTI_RIEP_ACCONTO_SALDO.
    DESCRIZIONE: Restituisce un ref_cursor contenente l'elenco delle imposte
                 dovute in acconto/saldo/totale suddivise per tipologia
                 (codice tributo F24).
    RITORNA:     ref_cursor.
    NOTE:
    Rev.  Data        Autore  Descrizione
    ----  ----------  ------  ----------------------------------------------------
    000   29/12/2021  VD      Prima emissione.
                              Issue #53742: aggiunti importi arrotondati.
  ******************************************************************************/
    rc sys_refcursor;
  begin
    open rc for
    select codice,
           descr,
           stampa_common.f_formatta_numero(sum(acconto), 'I', 'S') imposta_acconto,
           stampa_common.f_formatta_numero(sum(saldo), 'I', 'S')   imposta_saldo,
           stampa_common.f_formatta_numero(sum(nvl(acconto,0) + nvl(saldo,0)), 'I', 'S') imposta_totale,
           stampa_common.f_formatta_numero(sum(sum(acconto)) over(), 'I', 'S') totale_acconto,
           stampa_common.f_formatta_numero(sum(sum(saldo)) over(), 'I', 'S')   totale_saldo,
           stampa_common.f_formatta_numero(sum(sum(nvl(acconto,0) + nvl(saldo,0))) over(), 'I', 'S') totale
      from
           (select 'IMU - AB. PRINC. E PERT.' descr,
                   1 codice,
                   round(nvl(sum(ogim.imposta_acconto),0)) acconto,
                   round(nvl(sum(ogim.imposta),0)) -
                   round(nvl(sum(ogim.imposta_acconto),0)) saldo
              from oggetti_imposta ogim,
                   oggetti_pratica ogpr
             where ogim.oggetto_pratica = ogpr.oggetto_pratica
               and ogpr.pratica = a_pratica
               and nvl(ogim.tipo_aliquota,-1) = 2
            having sum(ogim.imposta) > 0
            union
            select 'IMU - FABB. RUR. AD USO STRUM.',
                   2,
                   round(nvl(sum(ogim.imposta_acconto),0)) acconto,
                   round(nvl(sum(ogim.imposta),0)) -
                   round(nvl(sum(ogim.imposta_acconto),0)) saldo
              from oggetti_imposta ogim,
                   oggetti_pratica ogpr,
                   oggetti ogge,
                   aliquote aliq
             where ogim.oggetto_pratica = ogpr.oggetto_pratica
               and ogpr.pratica = a_pratica
               and ogpr.oggetto = ogge.oggetto
               and ogim.tipo_tributo = aliq.tipo_tributo (+)
               and ogim.anno = aliq.anno (+)
               and nvl(ogim.tipo_aliquota,-1) = aliq.tipo_aliquota (+)
               and nvl(ogim.tipo_aliquota,-1) <> 2
               and nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto) not in (1,2)
               and nvl(aliq.flag_fabbricati_merce,'N') <> 'S'
               and ogim.aliquota_erariale is null
            having sum(ogim.imposta) > 0
            union
            select 'IMU - TERRENI',
                   3,
                   round(nvl(sum(ogim.imposta_acconto - nvl(ogim.imposta_erariale_acconto,0)),0)) acconto,
                   round(nvl(sum(ogim.imposta - nvl(ogim.imposta_erariale,0)),0)) -
                   round(nvl(sum(ogim.imposta_acconto - nvl(ogim.imposta_erariale_acconto,0)),0)) saldo
              from oggetti_imposta ogim,
                   oggetti_pratica ogpr,
                   oggetti ogge
             where ogim.oggetto_pratica = ogpr.oggetto_pratica
               and ogpr.pratica = a_pratica
               and ogpr.oggetto = ogge.oggetto
               and nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto) = 1
            having sum(ogim.imposta - nvl(ogim.imposta_erariale,0)) > 0
            union
            select 'IMU - AREE FABBRICABILI',
                   4,
                   round(nvl(sum(ogim.imposta_acconto - nvl(ogim.imposta_erariale_acconto,0)),0)) +
                   round(nvl(sum(ogim.imposta_erariale_acconto),0)) acconto,
                   (round(nvl(sum(ogim.imposta - nvl(ogim.imposta_erariale,0)),0)) +
                   round(nvl(sum(ogim.imposta_erariale),0))) -
                   round(nvl(sum(ogim.imposta_acconto - nvl(ogim.imposta_erariale_acconto,0)),0)) +
                   round(nvl(sum(ogim.imposta_erariale_acconto),0)) saldo
              from oggetti_imposta ogim,
                   oggetti_pratica ogpr,
                   oggetti ogge
             where ogim.oggetto_pratica = ogpr.oggetto_pratica
               and ogpr.pratica = a_pratica
               and ogpr.oggetto = ogge.oggetto
               and nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto) = 2
            having sum(ogim.imposta - nvl(ogim.imposta_erariale,0)) > 0
            union
            select 'IMU - ALTRI FABBRICATI',
                   5,
                   round(nvl(sum(decode(sign(ogim.anno - 2012),
                                 1,decode(substr(ogpr.categoria_catasto,1,1) ||
                                          to_char(nvl(ogim.tipo_aliquota,-1)),
                                          'D9',0,
                                          decode(nvl(aliq.flag_fabbricati_merce,'N'),
                                                 'S',0,
                                                 ogim.imposta_acconto - nvl(ogim.imposta_erariale_acconto,0))),
                                 ogim.imposta_acconto - nvl(ogim.imposta_erariale_acconto,0))),0)) acconto,
                   round(nvl(sum(decode(sign(ogim.anno - 2012),
                                 1,decode(substr(ogpr.categoria_catasto,1,1) ||
                                          to_char(nvl(ogim.tipo_aliquota,-1)),
                                          'D9',0,
                                          decode(nvl(aliq.flag_fabbricati_merce,'N'),
                                                 'S',0,
                                                 ogim.imposta - nvl(ogim.imposta_erariale,0))),
                                 ogim.imposta - nvl(ogim.imposta_erariale,0))),0)) -
                   round(nvl(sum(decode(sign(ogim.anno - 2012),
                                 1,decode(substr(ogpr.categoria_catasto,1,1) ||
                                          to_char(nvl(ogim.tipo_aliquota,-1)),
                                          'D9',0,
                                          decode(nvl(aliq.flag_fabbricati_merce,'N'),
                                                 'S',0,
                                                 ogim.imposta_acconto - nvl(ogim.imposta_erariale_acconto,0))),
                                 ogim.imposta_acconto - nvl(ogim.imposta_erariale_acconto,0))),0)) saldo
              from oggetti_imposta ogim,
                   oggetti_pratica ogpr,
                   oggetti ogge,
                   aliquote aliq
             where ogim.oggetto_pratica = ogpr.oggetto_pratica
               and ogpr.pratica = a_pratica
               and ogpr.oggetto = ogge.oggetto
               and ogim.tipo_tributo = aliq.tipo_tributo (+)
               and ogim.anno = aliq.anno (+)
               and nvl(ogim.tipo_aliquota,-1) = aliq.tipo_aliquota (+)
               and nvl(ogim.tipo_aliquota,-1) <> 2
               and nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto) not in (1,2)
               and ogim.aliquota_erariale is not null
            having sum(decode(sign(ogim.anno - 2012),
                       1,decode(substr(ogpr.categoria_catasto,1,1) ||
                                to_char(nvl(ogim.tipo_aliquota,-1)),
                                'D9',0,
                                decode(nvl(aliq.flag_fabbricati_merce,'N'),
                                       'S',0,
                                       ogim.imposta - nvl(ogim.imposta_erariale,0))),
                       ogim.imposta - nvl(ogim.imposta_erariale,0))) > 0
            union
            select 'IMU - IMM. PROD. (GR.C.D)',
                   6,
                   round(nvl(sum(decode(sign(ogim.anno - 2012),
                                 1,decode(substr(ogpr.categoria_catasto,1,1) ||
                                          to_char(nvl(ogim.tipo_aliquota,-1)),
                                          'D9',ogim.imposta_acconto - nvl(ogim.imposta_erariale_acconto,0),
                                          0),
                                 0)),0)) acconto,
                   round(nvl(sum(decode(sign(ogim.anno - 2012),
                                 1,decode(substr(ogpr.categoria_catasto,1,1) ||
                                          to_char(nvl(ogim.tipo_aliquota,-1)),
                                          'D9',ogim.imposta - nvl(ogim.imposta_erariale,0),
                                          0),
                                 0)),0)) -
                   round(nvl(sum(decode(sign(ogim.anno - 2012),
                                 1,decode(substr(ogpr.categoria_catasto,1,1) ||
                                          to_char(nvl(ogim.tipo_aliquota,-1)),
                                          'D9',ogim.imposta_acconto - nvl(ogim.imposta_erariale_acconto,0),
                                          0),
                                 0)),0)) saldo
              from oggetti_imposta ogim,
                   oggetti_pratica ogpr,
                   oggetti ogge
             where ogim.oggetto_pratica = ogpr.oggetto_pratica
               and ogpr.pratica = a_pratica
               and ogpr.oggetto = ogge.oggetto
               and nvl(ogim.tipo_aliquota,-1) <> 2
               and nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto) not in (1,2)
               and aliquota_erariale is not null
            having sum(decode(sign(ogim.anno - 2012),
                       1,decode(substr(ogpr.categoria_catasto,1,1) ||
                                to_char(nvl(ogim.tipo_aliquota,-1)),
                                'D9',ogim.imposta - nvl(ogim.imposta_erariale,0),
                                0),
                       0)) > 0
            union
            select 'IMU - IMM.COSTR.DEST.VENDITA',
                   7,
                   round(nvl(sum(ogim.imposta_acconto - nvl(ogim.imposta_erariale_acconto,0)),0)) acconto,
                   round(nvl(sum(ogim.imposta - nvl(ogim.imposta_erariale,0)),0)) -
                   round(nvl(sum(ogim.imposta_acconto - nvl(ogim.imposta_erariale_acconto,0)),0)) saldo
              from oggetti_imposta ogim,
                   oggetti_pratica ogpr,
                   oggetti ogge,
                   aliquote aliq
             where ogim.oggetto_pratica = ogpr.oggetto_pratica
               and ogpr.pratica = a_pratica
               and ogpr.oggetto = ogge.oggetto
               and ogim.tipo_tributo = aliq.tipo_tributo (+)
               and ogim.anno = aliq.anno (+)
               and nvl(ogim.tipo_aliquota,-1) = aliq.tipo_aliquota (+)
               and nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto) not in (1,2)
               and nvl(aliq.flag_fabbricati_merce,'N') = 'S'
            having sum(ogim.imposta - nvl(ogim.imposta_erariale,0)) > 0
            union
            select rpad('IMU - TERRENI', 39) descr,
                   3 codice,
                   round(nvl(sum(imposta_erariale_acconto),0)) acconto,
                   round(nvl(sum(imposta_erariale),0)) -
                   round(nvl(sum(imposta_erariale_acconto),0)) saldo
              from oggetti_imposta ogim,
                   oggetti_pratica ogpr,
                   oggetti ogge
             where ogim.oggetto_pratica = ogpr.oggetto_pratica
               and ogpr.pratica = a_pratica
               and ogpr.oggetto = ogge.oggetto
               and nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto) = 1
            having sum(imposta_erariale) > 0
             union
            select 'IMU - AREE FABBRICABILI',
                   4,
                   round(nvl(sum(ogim.imposta_erariale_acconto),0)) acconto,
                   round(nvl(sum(ogim.imposta_erariale),0)) -
                   round(nvl(sum(ogim.imposta_erariale_acconto),0)) saldo
              from oggetti_imposta ogim,
                   oggetti_pratica ogpr,
                   oggetti ogge
             where ogim.oggetto_pratica = ogpr.oggetto_pratica
               and ogpr.pratica = a_pratica
               and ogpr.oggetto = ogge.oggetto
               and nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto) = 2
            having sum(ogim.imposta_erariale) > 0
            union
            select 'IMU - ALTRI FABBRICATI',
                   5,
                   round(nvl(sum(decode(sign(ogim.anno - 2012),
                                             1,decode(substr(ogpr.categoria_catasto,1,1) ||
                                                      to_char(nvl(ogim.tipo_aliquota,-1)),
                                                      'D9',0,
                                                      decode(nvl(aliq.flag_fabbricati_merce,'N'),
                                                             'S',0,
                                                             ogim.imposta_erariale_acconto)),
                                         ogim.imposta_erariale_acconto)),0)) acconto,
                   round(nvl(sum(decode(sign(ogim.anno - 2012),
                                             1,decode(substr(ogpr.categoria_catasto,1,1) ||
                                                      to_char(nvl(ogim.tipo_aliquota,-1)),
                                                      'D9',0,
                                                      decode(nvl(aliq.flag_fabbricati_merce,'N'),
                                                             'S',0,
                                                             ogim.imposta_erariale)),
                                         ogim.imposta_erariale)),0)) -
                   round(nvl(sum(decode(sign(ogim.anno - 2012),
                                             1,decode(substr(ogpr.categoria_catasto,1,1) ||
                                                      to_char(nvl(ogim.tipo_aliquota,-1)),
                                                      'D9',0,
                                                      decode(nvl(aliq.flag_fabbricati_merce,'N'),
                                                             'S',0,
                                                             ogim.imposta_erariale_acconto)),
                                         ogim.imposta_erariale_acconto)),0)) saldo
              from oggetti_imposta ogim,
                   oggetti_pratica ogpr,
                   oggetti ogge,
                   aliquote aliq
             where ogim.oggetto_pratica = ogpr.oggetto_pratica
               and ogpr.pratica = a_pratica
               and ogpr.oggetto = ogge.oggetto
               and ogim.tipo_tributo = aliq.tipo_tributo (+)
               and ogim.anno = aliq.anno (+)
               and nvl(ogim.tipo_aliquota,-1) = aliq.tipo_aliquota (+)
               and nvl(ogim.tipo_aliquota,-1) <> 2
               and nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto) not in (1,2)
               and ogim.aliquota_erariale is not null
            having sum(decode(sign(ogim.anno - 2012),
                              1,decode(substr(ogpr.categoria_catasto,1,1) ||
                                       to_char(nvl(ogim.tipo_aliquota,-1)),
                                       'D9',0,
                                       decode(nvl(aliq.flag_fabbricati_merce,'N'),
                                              'S',0,
                                              ogim.imposta_erariale)),
                              ogim.imposta_erariale)) > 0
            union
            select 'IMU - IMM. PROD. (GR.C.D)',
                   6,
                   round(nvl(sum(decode(sign(ogim.anno - 2012),
                                 1,decode(substr(ogpr.categoria_catasto,1,1) ||
                                          to_char(nvl(ogim.tipo_aliquota,-1)),
                                          'D9',ogim.imposta_erariale_acconto,
                                          0),
                                 0)),0)) acconto,
                   round(nvl(sum(decode(sign(ogim.anno - 2012),
                                 1,decode(substr(ogpr.categoria_catasto,1,1) ||
                                          to_char(nvl(ogim.tipo_aliquota,-1)),
                                          'D9',ogim.imposta_erariale,
                                          0),
                                 0)),0)) -
                   round(nvl(sum(decode(sign(ogim.anno - 2012),
                                 1,decode(substr(ogpr.categoria_catasto,1,1) ||
                                          to_char(nvl(ogim.tipo_aliquota,-1)),
                                          'D9',ogim.imposta_erariale_acconto,
                                          0),
                                 0)),0)) saldo
              from oggetti_imposta ogim,
                   oggetti_pratica ogpr,
                   oggetti ogge
             where ogim.oggetto_pratica = ogpr.oggetto_pratica
               and ogpr.pratica = a_pratica
               and ogpr.oggetto = ogge.oggetto
               and nvl(ogim.tipo_aliquota,-1) <> 2
               and nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto) not in (1,2)
               and aliquota_erariale is not null
            having sum(decode(sign(ogim.anno - 2012),
                       1,decode(substr(ogpr.categoria_catasto,1,1) ||
                                to_char(nvl(ogim.tipo_aliquota,-1)),
                                'D9',ogim.imposta_erariale,
                                0),
                       0)) > 0)
        group by codice,descr;
    return rc;
  end;
------------------------------------------------------------------
  function importi(a_pratica      number,
                   a_modello      number,
                   a_modello_rimb number) return sys_refcursor is
    rc sys_refcursor;
  begin
    open rc for
      select -- CAMPI AGGIUNTI --
       stampa_common.f_formatta_numero(sum(sapr.importo) over(), 'I', 'S') as importo_totale,
       stampa_common.f_formatta_numero(sapr.percentuale, 'P') as percentuale,
       stampa_common.f_formatta_numero(sapr.riduzione, 'P') || '  ' ||
            decode(nvl(sapr.giorni, sapr.semestri),
                   null,
                   '     ',
                   to_char(nvl(sapr.giorni, sapr.semestri), '9999')) as riduzione,
       stampa_common.f_formatta_numero(sapr.importo, 'I', 'S') as importo,
       -- FINE CAMPI AGGIUNTI --
       decode(sign(round(importo_totale, 0)),
              1,
              f_descrizione_timp(a_modello, 'INT_IMPOSTA_INTERESSI'),
              f_descrizione_timp(a_modello_rimb,
                                 'INT_IMPOSTA_INTERESSI_RIMB')) intestazione,
       sapr.cod_sanzione,
       sapr.pratica,
       sapr.utente,
       stampa_common.f_formatta_numero(sapr.percentuale, 'P') || '  ' ||
       stampa_common.f_formatta_numero(sapr.riduzione, 'P')   || '  ' ||
       decode(nvl(sapr.giorni, sapr.semestri),
              null,
              '',
              to_char(nvl(sapr.giorni, sapr.semestri), '9999')) || '  ' ||
       stampa_common.f_formatta_numero(sapr.importo, 'I', 'S') perc_ed_importo,
       sapr.semestri,
       sapr.percentuale,
       sapr.riduzione,
       substr(sanz.descrizione, 1, 49) descrizione
        from sanzioni_pratica sapr, sanzioni sanz, pratiche_tributo prtr
       where sapr.cod_sanzione = sanz.cod_sanzione(+)
         and sapr.sequenza_sanz = sanz.sequenza (+)
         and sapr.tipo_tributo = sanz.tipo_tributo(+)
         and sapr.pratica = a_pratica
         and prtr.pratica = a_pratica
         and sapr.cod_sanzione not in (888, 889)
         and (sanz.cod_sanzione in (1, 100, 101) or
             ((sanz.tipo_tributo = 'TARSU' and
             (sanz.tipo_causale || nvl(sanz.flag_magg_tares, 'N') = 'EN' or
             sanz.tipo_causale || nvl(sanz.flag_magg_tares, 'N') = 'IN')) or
             (sanz.tipo_tributo != 'TARSU' and flag_imposta = 'S')))
       order by sapr.cod_sanzione asc;
    return rc;
  end;
------------------------------------------------------------------
  function sanzioni(a_pratica number) return sys_refcursor is
    rc sys_refcursor;
  begin
    open rc for
      select sapr.cod_sanzione,
             sapr.pratica,
             rpad(substr(sanz.descrizione, 1, 49), 49) descrizione,
             sapr.utente,
             -- CAMPI AGGIUNTI --
             (select stampa_common.f_formatta_numero(sap1.importo, 'I', 'S')
                from sanzioni_pratica sap1, sanzioni san1
               where sap1.cod_sanzione = san1.cod_sanzione
                 and sap1.sequenza_sanz = san1.sequenza
                 and sap1.pratica = a_pratica
                 and san1.flag_imposta = 'S'
                 and sap1.tipo_tributo = sapr.tipo_tributo
                 and sap1.tipo_tributo = san1.tipo_tributo
                 and san1.tipo_versamento = sanz.tipo_versamento
                 and sanz.tipo_causale <> 'T') imposta_evasa_str,
             (select stampa_common.f_formatta_numero(round(sap1.importo,0), 'I', 'S')
                from sanzioni_pratica sap1, sanzioni san1
               where sap1.cod_sanzione = san1.cod_sanzione
                 and sap1.sequenza_sanz = san1.sequenza
                 and sap1.pratica = a_pratica
                 and san1.flag_imposta = 'S'
                 and sap1.tipo_tributo = sapr.tipo_tributo
                 and sap1.tipo_tributo = san1.tipo_tributo
                 and san1.tipo_versamento = sanz.tipo_versamento
                 and sanz.tipo_causale <> 'T') imposta_evasa_arr,
             decode(sapr.percentuale, null, null, sapr.percentuale) percentuale_str,
             stampa_common.f_formatta_numero(sum(sapr.importo) over(), 'I', 'S') importo_totale_str,
             sum(sapr.importo) over() importo_totale,
             stampa_common.f_formatta_numero(sapr.importo, 'I', 'S') importo_str,
             -- FINE CAMPI AGGIUNTI --
             stampa_common.f_formatta_numero(sapr.percentuale, 'P') percentuale,
             stampa_common.f_formatta_numero(sapr.riduzione, 'P') riduzione,
             stampa_common.f_formatta_numero(sapr.riduzione_2, 'P') riduzione2,
             stampa_common.f_formatta_numero(sapr.importo, 'I', 'S') importo,
             sanz.cod_tributo_f24
        from sanzioni_pratica sapr, sanzioni sanz
       where (sapr.cod_sanzione = sanz.cod_sanzione(+))
         and (sapr.sequenza_sanz = sanz.sequenza(+))
         and (sapr.tipo_tributo = sanz.tipo_tributo(+))
         and (sapr.cod_sanzione not in (888, 889))
         and (sapr.pratica = a_pratica)
         and sanz.flag_imposta is null
         and nvl(sanz.tipo_causale, 'X') in ('O', 'P', 'T') -- Omessi/Parziali Versamenti + Tardivi
       order by sapr.cod_sanzione asc;
    return rc;
  end;
------------------------------------------------------------------
  function interessi(a_pratica number) return sys_refcursor is
    rc sys_refcursor;
  begin
    open rc for
      select
      -- CAMPI AGGIUNTI --
       sapr.percentuale percentuale_str,
       sapr.importo as importo_str,
       sum(sapr.importo) over() importo_totale_str,
       sapr.giorni gg_interesse,
       -- FINE CAMPI AGGIUNTI --
       sapr.cod_sanzione,
       sapr.pratica,
       rpad(substr(sanz.descrizione, 1, 49), 49) descrizione,
       sapr.utente,
       stampa_common.f_formatta_numero(sapr.percentuale, 'P') percentuale,
       stampa_common.f_formatta_numero(sapr.riduzione, 'P') riduzione,
       stampa_common.f_formatta_numero(sapr.riduzione_2, 'P') riduzione2,
       stampa_common.f_formatta_numero(sapr.importo, 'I', 'S') importo,
       sanz.cod_tributo_f24
        from sanzioni_pratica sapr, sanzioni sanz
       where (sapr.cod_sanzione = sanz.cod_sanzione(+))
         and (sapr.sequenza_sanz = sanz.sequenza(+))
         and (sapr.tipo_tributo = sanz.tipo_tributo(+))
         and (sapr.cod_sanzione not in (888, 889))
         and (sapr.pratica = a_pratica)
         and sanz.flag_imposta is null
         and nvl(sanz.tipo_causale, 'X') = 'I' -- 'I'=Interessi
       order by sapr.cod_sanzione asc;
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
  function riepilogo_dovuto(a_pratica number,
                    a_modello number default -1) return sys_refcursor is
    rc sys_refcursor;
  begin
    open rc for
      select 1,
             '(a)' lettera,
             sanza.descrizione,
             stampa_common.f_formatta_numero(sum(sanza.importo),'I') importo
      from (select decode(prat.tipo_tributo,'ICI','3918','TASI','3961',sanz.cod_tributo_f24)
                   ||' - '||nvl(f_descrizione_timp(a_modello,'SOMME_DOVUTE_DES_IMPOSTA_EVASA'),'TOTALE MAGGIOR TRIBUTO') descrizione,
                   sapr.importo importo
              from pratiche_tributo prat,
                   sanzioni_pratica sapr,
                   sanzioni sanz
             where prat.pratica = a_pratica
               and sapr.pratica = prat.pratica
               and sapr.tipo_tributo = sanz.tipo_tributo
               and sapr.cod_sanzione = sanz.cod_sanzione
               and sapr.sequenza_sanz = sanz.sequenza
               and sanz.flag_imposta = 'S'
               and nvl(sanz.tipo_causale, 'X') = 'E'
               ) sanza
       group by descrizione
      union
      select 2,
             '(b)' lettera,
             sanz.cod_tributo_f24||' - TOTALE SANZIONI',
             stampa_common.f_formatta_numero(sum(sapr.importo),'I')
        from sanzioni_pratica sapr, sanzioni sanz
       where sapr.pratica = a_pratica
         and sapr.tipo_tributo = sanz.tipo_tributo
         and sapr.cod_sanzione = sanz.cod_sanzione
         and sapr.sequenza_sanz = sanz.sequenza
         and sanz.flag_imposta is null
         and nvl(sanz.tipo_causale, 'X') in ('O', 'P', 'T')
       group by sanz.cod_tributo_f24
      union
      select 3,
             '(c)' lettera,
             sanz.cod_tributo_f24||' - TOTALE INTERESSI',
             stampa_common.f_formatta_numero(sum(sapr.importo),'I')
        from sanzioni_pratica sapr, sanzioni sanz
       where sapr.pratica = a_pratica
         and sapr.tipo_tributo = sanz.tipo_tributo
         and sapr.cod_sanzione = sanz.cod_sanzione
         and sapr.sequenza_sanz = sanz.sequenza
         and sanz.flag_imposta is null
         and nvl(sanz.tipo_causale, 'X') = 'I'
       group by sanz.cod_tributo_f24
      union
      select 4,
             '(d)' lettera,
             'TOTALE DOVUTO (a)+(b)+(c)',
             stampa_common.f_formatta_numero(sum(sapr.importo),'I')
        from sanzioni_pratica sapr, sanzioni sanz
       where sapr.pratica = a_pratica
         and sapr.tipo_tributo = sanz.tipo_tributo
         and sapr.cod_sanzione = sanz.cod_sanzione
         and sapr.sequenza_sanz = sanz.sequenza
         and nvl(sanz.tipo_causale, 'X') <> 'S'
      union
      select 5,
             '(e)' lettera,
             sanz.cod_tributo_f24||' - '||sanz.descrizione,
             stampa_common.f_formatta_numero(sum(sapr.importo),'I')
        from sanzioni_pratica sapr, sanzioni sanz
       where sapr.pratica = a_pratica
         and sapr.tipo_tributo = sanz.tipo_tributo
         and sapr.cod_sanzione = sanz.cod_sanzione
         and sapr.sequenza_sanz = sanz.sequenza
         and sanz.flag_imposta is null
         and nvl(sanz.tipo_causale, 'X') = 'S'
       group by sanz.cod_tributo_f24
              , sanz.descrizione
      union
      select 6, ' ' lettera,
             'IMPORTO TOTALE DELL''AVVISO (d)+(e)',
             stampa_common.f_formatta_numero(sum(sapr.importo),'I')
        from sanzioni_pratica sapr, sanzioni sanz
       where sapr.pratica = a_pratica
         and sapr.tipo_tributo = sanz.tipo_tributo
         and sapr.cod_sanzione = sanz.cod_sanzione
         and sapr.sequenza_sanz = sanz.sequenza
       order by 1;
    return rc;
  end;
------------------------------------------------------------------
  function riepilogo_da_versare(a_pratica number) return sys_refcursor is
    rc sys_refcursor;
  begin
    open rc for
      select vers.*,
             stampa_common.f_formatta_numero(sum(vers.importo_1) over(),'I') importo_tot,
             stampa_common.f_formatta_numero(sum(vers.importo_arr_1) over(),'I') importo_tot_arr
        from (select 1,
                     sanza.lettera,
                     sum(sanza.importo) importo_1,
                     round(sum(sanza.importo)) importo_arr_1,
                     stampa_common.f_formatta_numero(sum(sanza.importo),'I') importo,
                     stampa_common.f_formatta_numero(round(sum(sanza.importo)),'I') importo_arr
              from (select decode(prat.tipo_tributo,'ICI','3918','TASI','3961',sanz.cod_tributo_f24)
                           ||' (a)' lettera,
                           sapr.importo
                      from pratiche_tributo prat,
                           sanzioni_pratica sapr,
                           sanzioni sanz
                     where prat.pratica = a_pratica
                       and sapr.pratica = prat.pratica
                       and sapr.tipo_tributo = sanz.tipo_tributo
                       and sapr.cod_sanzione = sanz.cod_sanzione
                       and sapr.sequenza_sanz = sanz.sequenza
                       and nvl(sanz.tipo_causale, 'X') = 'E') sanza
               group by lettera
              union
              select 2,
                     sanz.cod_tributo_f24||' (c)' lettera,
                     sum(sapr.importo) importo_1,
                     round(sum(sapr.importo)) importo_arr_1,
                     stampa_common.f_formatta_numero(sum(sapr.importo),'I') importo,
                     stampa_common.f_formatta_numero(round(sum(sapr.importo)),'I') importo_arr
                from sanzioni_pratica sapr, sanzioni sanz
               where sapr.pratica = a_pratica
                 and sapr.tipo_tributo = sanz.tipo_tributo
                 and sapr.cod_sanzione = sanz.cod_sanzione
                 and sapr.sequenza_sanz = sanz.sequenza
                 and sanz.flag_imposta is null
                 and nvl(sanz.tipo_causale, 'X') = 'I'
               group by sanz.cod_tributo_f24
              union
              select 3,
                     sanz.cod_tributo_f24||' (b) + (e)' lettera,
                     sum(sapr.importo) importo_1,
                     round(sum(sapr.importo)) importo_arr_1,
                     stampa_common.f_formatta_numero(sum(sapr.importo),'I') importo,
                     stampa_common.f_formatta_numero(round(sum(sapr.importo)),'I') importo_arr
                from sanzioni_pratica sapr, sanzioni sanz
               where sapr.pratica = a_pratica
                 and sapr.tipo_tributo = sanz.tipo_tributo
                 and sapr.cod_sanzione = sanz.cod_sanzione
                 and sapr.sequenza_sanz = sanz.sequenza
                 and nvl(sanz.tipo_causale, 'X') not in ('E','I')
               group by sanz.cod_tributo_f24
               order by 1) vers;
    return rc;
  end;
------------------------------------------------------------------
  function interessi_g_applicati(a_tipo_tributo varchar2,
                                 a_anno         number,
                                 a_data         varchar2)
    return sys_refcursor is
    p_min_data varchar2(10);
    rc         sys_refcursor;
  begin
    select min(data_scadenza)
      into p_min_data
      from scadenze
     where tipo_tributo = a_tipo_tributo
       and tipo_scadenza = 'V'
       and anno = a_anno;
    open rc for
      select inte.tipo_tributo,
             inte.sequenza,
             to_char(inte.data_inizio, 'DD/MM/YYYY') data_inizio,
             to_char(inte.data_fine, 'DD/MM/YYYY') data_fine,
             inte.aliquota,
             inte.tipo_interesse
        from interessi inte
       where inte.tipo_tributo = a_tipo_tributo
         and inte.tipo_interesse = 'G'
         and (p_min_data between inte.data_inizio and inte.data_fine or
             to_date(a_data, 'DD/MM/YYYY') between inte.data_inizio and
             inte.data_fine or
             (inte.data_inizio > p_min_data and
             inte.data_fine < to_date(a_data, 'DD/MM/YYYY')))
         and inte.tipo_interesse = 'G'
       order by inte.data_inizio;
    return rc;
  end;
------------------------------------------------------------------
  function aggi_dilazione
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
  function eredi(a_pratica        number default -1,
                 a_ni_primo_erede number default -1) return sys_refcursor is
    rc sys_refcursor;
  begin
    rc := stampa_common.eredi(a_pratica, a_ni_primo_erede);
    return rc;
  end;
------------------------------------------------------------------
  function F_GET_COD_TRIBUTO_F24
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
end stampa_liquidazioni_imu;
/
