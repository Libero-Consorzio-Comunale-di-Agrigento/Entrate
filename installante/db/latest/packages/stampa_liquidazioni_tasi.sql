--liquibase formatted sql 
--changeset abrandolini:20250326_152429_stampa_liquidazioni_tasi stripComments:false runOnChange:true 
 
create or replace package stampa_liquidazioni_tasi is
/******************************************************************************
 NOME:        STAMPA_LIQUIDAZIONI_TASI
 DESCRIZIONE: Funzioni per stampa liquidazioni TASI - TributiWeb.
              La maggior parte delle funzioni riutilizza le analoghe funzioni
              del package STAMPA_LIQUIDAZIONI_IMU.
 ANNOTAZIONI: -
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 002   14/06/2024  RV      #55525
                           Aggiunto INTERESSI_DETTAGLIO
 001   03/02/2022  VD      Issue #53742: aggiunti importi arrotondati e
                           riepilogo acconto/saldo per tipologia tributo
                           (codice tributo F24).
 000   21/04/2021  VD      Prima emissione.
******************************************************************************/
  function contribuente
  ( a_pratica             number default -1
  , a_ni_erede            number default -1
  ) return sys_refcursor;
  function immobili(a_cf varchar2 default '',
                    a_pratica number default -1,
                    a_tipi_oggetto varchar2 default '',
                    a_modello number default -1)
    return sys_refcursor;
  function riog(a_pratica number default -1,
                p_anno    number default -1,
                a_oggetto number default -1) return sys_refcursor;
  function imposta_denuncia(a_pratica         number default -1,
                            a_oggetto_pratica number default -1,
                            a_subtesto        varchar2 default '',
                            a_modello         number default -1)
    return sys_refcursor;
  function imposta_rendita(a_pratica         number default -1,
                           a_oggetto_pratica number default -1,
                           a_subtesto        varchar2 default '',
                           a_modello         number default -1)
    return sys_refcursor;
  function versamenti(a_cf      varchar2 default '',
                      a_pratica number default -1,
                      a_anno    number default -1) return sys_refcursor;
  function versamenti_vuoto(a_cf      varchar2 default '',
                            a_pratica number default -1,
                            a_anno    number default -1) return sys_refcursor;
  function importo_per_codice_f24
  ( a_pratica                      number
  , a_codice_f24                   varchar2
  , a_tipo_importo                 varchar2
  ) return number;
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
  function importi_riep_acconto_saldo(a_pratica number default -1) return sys_refcursor;
  function importi(a_pratica      number default -1,
                   a_modello      number default -1,
                   a_modello_rimb number default -1) return sys_refcursor;
  function sanzioni(a_pratica number default -1) return sys_refcursor;
  function interessi(a_pratica number default -1) return sys_refcursor;
  function interessi_dettaglio
  ( a_pratica               number default -1
  , a_modello               number default -1
  ) return sys_refcursor;
  function riepilogo_dovuto(a_pratica number default -1) return sys_refcursor;
  function riepilogo_da_versare(a_pratica number default -1)
    return sys_refcursor;
  function interessi_g_applicati(a_tipo_tributo varchar2 default '',
                                 a_anno         number default -1,
                                 a_data         varchar2 default '')
    return sys_refcursor;
  function aggi_dilazione
  ( a_pratica                                   number default -1
  , a_modello                                   number default -1
  ) return sys_refcursor;
  function eredi
  ( a_ni_deceduto           number default -1
  , a_ni_erede_da_escludere number default -1
  ) return sys_refcursor;
  function principale(a_cf           varchar2 default '',
                      a_vett_prat    varchar2 default '',
                      a_modello      number default -1,
                      a_modello_rimb number default -1,
                      a_ni_erede     number default -1) return sys_refcursor;
end stampa_liquidazioni_tasi;
/
create or replace package body stampa_liquidazioni_tasi is
/******************************************************************************
 NOME:        STAMPA_LIQUIDAZIONI_TASI
 DESCRIZIONE: Funzioni per stampa liquidazioni TASI - TributiWeb.
              La maggior parte delle funzioni riutilizza le analoghe funzioni
              del package STAMPA_LIQUIDAZIONI_IMU.
 ANNOTAZIONI: -
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 002   14/06/2024  RV      #55525
                           Aggiunto INTERESSI_DETTAGLIO
 001   03/02/2022  VD      Issue #53742: aggiunti importi arrotondati e
                           riepilogo acconto/saldo per tipologia tributo
                           (codice tributo F24).
 000   21/04/2021  VD      Prima emissione.
******************************************************************************/
  function contribuente
  ( a_pratica             number
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
    rc := stampa_liquidazioni_imu.immobili(a_cf,a_pratica,a_tipi_oggetto,a_modello);
    return rc;
  end;
------------------------------------------------------------------
  function riog(a_pratica number, p_anno number, a_oggetto number)
    return sys_refcursor is
    rc sys_refcursor;
  begin
    rc := stampa_liquidazioni_imu.riog(a_pratica,p_anno,a_oggetto);
    return rc;
  end;
------------------------------------------------------------------
  function imposta_denuncia(a_pratica         number,
                            a_oggetto_pratica number,
                            a_subtesto        varchar2,
                            a_modello         number) return sys_refcursor is
    rc sys_refcursor;
  begin
    open rc for
      select imm.*,
             a_subtesto as subtesto,
             stampa_common.f_formatta_numero(imposta_acconto_num,'I','S') imposta_acconto,
             stampa_common.f_formatta_numero((imposta_num - imposta_acconto_num),'I','S') imposta_saldo,
             stampa_common.f_formatta_numero(sum(imposta_acconto_num) over(),'I','S') imposta_acconto_tot,
             stampa_common.f_formatta_numero(sum(imposta_num) over(),'I','S') imposta_tot,
             stampa_common.f_formatta_numero(sum(imposta_num - imposta_acconto_num)
                                    over(),'I','S') imposta_saldo_tot
        from (select --
                     sum(nvl(ogim.imposta_dovuta, 0)) imposta_num,
                     sum(nvl(ogim.imposta_dovuta_acconto, 0)) imposta_acconto_num,
                     --
                     stampa_common.f_formatta_numero(sum (nvl (ogim.imposta_dovuta, 0)),'I','S') imposta,
                     '3958' codice_tributo,
                     rpad ('TASI - Abitazioni Principali', 44) des_tributo
                from oggetti_imposta ogim, oggetti_pratica ogpr, oggetti ogge
               where ogpr.oggetto_pratica = ogim.oggetto_pratica
                 and ogpr.oggetto = ogge.oggetto
                 and ogpr.pratica = a_pratica
                 and ogpr.oggetto_pratica = a_oggetto_pratica
                 and ogim.tipo_aliquota = 2
                 and nvl(f_descrizione_timp(a_modello,'DATI_DIC'),'NO') = 'SI'
              having sum (nvl (ogim.imposta_dovuta, 0)) <> 0
              union
              select
                     --
                     sum(nvl(ogim.imposta_dovuta, 0)),
                     sum(nvl(ogim.imposta_dovuta_acconto, 0)),
                     --
                     stampa_common.f_formatta_numero(sum (nvl(ogim.imposta_dovuta,0)),'I','S') imposta_rur_3913,
                     '3959' codice_tributo,
                     rpad ('TASI - Fabbricati Rurali', 44) des_tributo
                     from oggetti_imposta ogim, oggetti_pratica ogpr, oggetti ogge
                    where ogpr.oggetto_pratica = ogim.oggetto_pratica
                      and ogpr.oggetto = ogge.oggetto
                      and ogpr.pratica = a_pratica
                      and ogpr.oggetto_pratica = a_oggetto_pratica
                      and ogim.tipo_aliquota <> 2
                      and nvl (ogpr.tipo_oggetto, ogge.tipo_oggetto) not in (1, 2)
                      and nvl(f_descrizione_timp(a_modello,'DATI_DIC'),'NO') = 'SI'
                   having sum (nvl (ogim.imposta_dovuta, 0)) != 0
              union
              select
                     --
                     sum(nvl(ogim.imposta_dovuta, 0)),
                     sum(nvl(ogim.imposta_dovuta_acconto, 0)),
                     --
                     stampa_common.f_formatta_numero(sum (nvl (ogim.imposta_dovuta, 0)),'I','S') imposta_aree_com_3916,
                     '3960' codice_tributo,
                     rpad ('TASI - Aree Fabbricabili', 44) des_tributo
                from oggetti_imposta ogim, oggetti_pratica ogpr, oggetti ogge
               where ogpr.oggetto_pratica = ogim.oggetto_pratica
                 and ogpr.oggetto = ogge.oggetto
                 and ogpr.pratica = a_pratica
                 and ogpr.oggetto_pratica = a_oggetto_pratica
                 and nvl (ogpr.tipo_oggetto, ogge.tipo_oggetto) = 2
                 and nvl(f_descrizione_timp(a_modello,'DATI_DIC'),'NO') = 'SI'
              having sum (nvl (ogim.imposta_dovuta, 0)) != 0
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
                     stampa_common.f_formatta_numero(f_altri_importo (a_pratica,
                                                        a_oggetto_pratica,
                                                        'COMUNE',
                                                        ogpr.anno,
                                                        'DOVUTA'
                                                       ),
                                       'I','S') imposta_altri_com_3918,
                     '3961' codice_tributo,
                     rpad ('TASI - Altri Fabbricati', 44) des_tributo
                from oggetti_imposta ogim, oggetti_pratica ogpr, oggetti ogge
               where ogpr.oggetto_pratica = ogim.oggetto_pratica
                 and ogpr.oggetto = ogge.oggetto
                 and ogpr.pratica = a_pratica
                 and ogpr.oggetto_pratica = a_oggetto_pratica
                 and ogim.tipo_aliquota != 2
                 and nvl (ogpr.tipo_oggetto, ogge.tipo_oggetto) not in (1, 2)
                 and aliquota_erariale is not null
                 and f_altri_importo (a_pratica, a_oggetto_pratica, 'COMUNE', ogpr.anno, 'DOVUTA') > 0
                 and nvl(f_descrizione_timp(a_modello,'DATI_DIC'),'NO') = 'SI'
               order by 4) imm;
    return rc;
  end;
------------------------------------------------------------------
  function imposta_rendita(a_pratica         number,
                           a_oggetto_pratica number,
                           a_subtesto        varchar2,
                           a_modello         number) return sys_refcursor is
    rc sys_refcursor;
  begin
    open rc for
      select imm.*,
             a_subtesto as subtesto,
             stampa_common.f_formatta_numero(imposta_acconto_num,'I','S') imposta_acconto,
             stampa_common.f_formatta_numero((imposta_num - imposta_acconto_num),'I','S') imposta_saldo,
             stampa_common.f_formatta_numero(sum(imposta_acconto_num) over(),
                               'I','S') imposta_acconto_tot,
             stampa_common.f_formatta_numero(sum(imposta_num) over(),
                               'I','S') imposta_tot,
             stampa_common.f_formatta_numero(sum(imposta_num - imposta_acconto_num) over(),
                               'I','S') imposta_saldo_tot
        from (select --
                     sum(nvl(ogim.imposta, 0)) imposta_num,
                     sum(nvl(ogim.imposta_acconto, 0)) imposta_acconto_num,
                     --
                     stampa_common.f_formatta_numero(sum (nvl (ogim.imposta, 0)),'I','S') imposta,
                     '3958' codice_tributo,
                     rpad ('TASI - Abitazioni Principali', 44) des_tributo
                from oggetti_imposta ogim, oggetti_pratica ogpr, oggetti ogge
               where ogpr.oggetto_pratica = ogim.oggetto_pratica
                 and ogpr.oggetto = ogge.oggetto
                 and ogpr.pratica = a_pratica
                 and ogpr.oggetto_pratica = a_oggetto_pratica
                 and ogim.tipo_aliquota = 2
                 and (nvl(f_descrizione_timp(a_modello,'DATI_DIC'),'NO') = 'NO' or
                      nvl (ogim.imposta_dovuta, 0) <> nvl (ogim.imposta, 0))
              having sum (nvl (ogim.imposta, 0)) <> 0
              union
              select --
                     sum(decode(aliquota_erariale,
                                null,
                                nvl(ogim.imposta, 0),
                                0)),
                     sum(decode(aliquota_erariale,
                                null,
                                nvl(ogim.imposta_acconto, 0),
                                0)),
                     --
                     stampa_common.f_formatta_numero(sum (decode (aliquota_erariale,
                                                    null, nvl (ogim.imposta, 0),
                                                         0
                                                   )
                                           ),
                                       'I', 'S'
                                      ) imposta_rur_3913,
                     '3959' codice_tributo,
                     rpad ('TASI - Fabbricati Rurali', 44) des_tributo
                from oggetti_imposta ogim, oggetti_pratica ogpr, oggetti ogge
               where ogpr.oggetto_pratica = ogim.oggetto_pratica
                 and ogpr.oggetto = ogge.oggetto
                 and ogpr.pratica = a_pratica
                 and ogpr.oggetto_pratica = a_oggetto_pratica
                 and ogim.tipo_aliquota != 2
                 and nvl (ogpr.tipo_oggetto, ogge.tipo_oggetto) not in (1, 2)
                 and (nvl(f_descrizione_timp(a_modello,'DATI_DIC'),'NO') = 'NO' or
                     nvl (ogim.imposta_dovuta, 0) != nvl (ogim.imposta, 0))
              having sum (nvl (ogim.imposta, 0)) != 0
                 and sum (decode (aliquota_erariale, null, nvl (ogim.imposta, 0), 0)) <> 0
              union
              select --
                     sum(nvl(ogim.imposta, 0) -
                         nvl(ogim.imposta_erariale, 0)
                        ),
                     sum(nvl(ogim.imposta_acconto, 0) -
                         nvl(ogim.imposta_erariale_acconto, 0)
                        ),
                     --
                     stampa_common.f_formatta_numero(sum(nvl(ogim.imposta, 0) -
                                                         nvl(ogim.imposta_erariale, 0)
                                                        ),
                                                     'I','S'
                                                    ) imposta_aree_com_3916,
                     '3960' codice_tributo,
                     rpad ('TASI - Aree Fabbricabili', 44) des_tributo
                from oggetti_imposta ogim,
                     oggetti_pratica ogpr,
                     oggetti         ogge
               where ogpr.oggetto_pratica = ogim.oggetto_pratica
                 and ogpr.oggetto = ogge.oggetto
                 and ogpr.pratica = a_pratica
                 and ogpr.oggetto_pratica = a_oggetto_pratica
                 and nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto) = 2
                 and (nvl(f_descrizione_timp(a_modello,'DATI_DIC'),'NO') = 'NO' or
                      nvl (ogim.imposta_dovuta, 0) <> nvl (ogim.imposta, 0))
               having sum(nvl(ogim.imposta, 0) -
                          nvl(ogim.imposta_erariale, 0)) <> 0
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
                                             'DOVUTA'),
                     --
                     stampa_common.f_formatta_numero(f_altri_importo (a_pratica,
                                                                      a_oggetto_pratica,
                                                                      'COMUNE',
                                                                      ogpr.anno,
                                                                      'RENDITA'
                                                                     ),
                                                     'I','S'
                                                    ) imposta_altri_com_3918,
                     '3961' codice_tributo,
                     rpad ('TASI - Altri Fabbricati', 44) des_tributo
                from oggetti_imposta ogim, oggetti_pratica ogpr, oggetti ogge
               where ogpr.oggetto_pratica = ogim.oggetto_pratica
                 and ogpr.oggetto = ogge.oggetto
                 and ogpr.pratica = a_pratica
                 and ogpr.oggetto_pratica = a_oggetto_pratica
                 and ogim.tipo_aliquota != 2
                 and nvl (ogpr.tipo_oggetto, ogge.tipo_oggetto) not in (1, 2)
                 and aliquota_erariale is not null
                 and (nvl(f_descrizione_timp(a_modello,'DATI_DIC'),'NO') = 'NO' or
                     nvl (ogim.imposta_dovuta, 0) <> nvl (ogim.imposta, 0))
                 and f_altri_importo (a_pratica, a_oggetto_pratica, 'COMUNE', ogpr.anno, 'RENDITA') > 0
               order by 4) imm;
    return rc;
  end;
------------------------------------------------------------------
  function versamenti(a_cf varchar2, a_pratica number, a_anno number)
    return sys_refcursor is
    rc sys_refcursor;
  begin
    rc := stampa_liquidazioni_imu.versamenti(a_cf,a_pratica,a_anno);
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
  function importo_per_codice_f24
  ( a_pratica                      number
  , a_codice_f24                   varchar2
  , a_tipo_importo                 varchar2
  ) return number is
    w_importo                      number;
  begin
    -- TASI - ABITAZIONI PRINCIPALI
    if a_codice_f24 =  3958 then
       select round(nvl(sum(decode(a_tipo_importo
                                  ,'A',ogim.imposta_acconto
                                  ,'S',ogim.imposta - ogim.imposta_acconto
                                  ,ogim.imposta
                                  )
                            ),0))
          into w_importo
          from oggetti_imposta ogim
             , oggetti_pratica ogpr
         where ogim.oggetto_pratica = ogpr.oggetto_pratica
           and ogpr.pratica = a_pratica
           and ogim.tipo_aliquota = 2;
    end if;
    --
    if a_codice_f24 = 3959 then
       select round(nvl(sum(decode(a_tipo_importo
                                  ,'A',ogim.imposta_acconto
                                  ,'S',ogim.imposta - ogim.imposta_acconto
                                  ,ogim.imposta
                                  )
                            ),0))
          into w_importo
          from oggetti_imposta ogim
              ,oggetti_pratica ogpr
              ,oggetti ogge
         where ogim.oggetto_pratica = ogpr.oggetto_pratica
           and ogpr.pratica = a_pratica
           and ogpr.oggetto = ogge.oggetto
           and ogim.tipo_aliquota <> 2
           and nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto) not in (1,2)
           and aliquota_erariale is null;
    end if;
    -- TASI - AREE FABBRICABILI
    if a_codice_f24 = 3960 then
       select round(nvl(sum(decode(a_tipo_importo
                                  ,'A',ogim.imposta_acconto
                                  ,'S',ogim.imposta - ogim.imposta_acconto
                                  ,ogim.imposta
                                  )
                            ),0))
          into w_importo
          from oggetti_imposta ogim
              ,oggetti_pratica ogpr
              ,oggetti ogge
         where ogim.oggetto_pratica = ogpr.oggetto_pratica
           and ogpr.pratica = a_pratica
           and ogpr.oggetto = ogge.oggetto
           and nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto) = 2;
    end if;
    -- TASI - ALTRI FABBRICATI
    if a_codice_f24 = 3961 then
       select round(nvl(sum(decode(a_tipo_importo
                                  ,'A',ogim.imposta_acconto
                                  ,'S',ogim.imposta - ogim.imposta_acconto
                                  ,ogim.imposta
                                  )
                            ),0))
          into w_importo
          from oggetti_imposta ogim
              ,oggetti_pratica ogpr
              ,oggetti ogge
         where ogim.oggetto_pratica = ogpr.oggetto_pratica
           and ogpr.pratica = a_pratica
           and ogpr.oggetto = ogge.oggetto
           and ogim.tipo_aliquota <> 2
           and nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto) not in (1,2)
           and aliquota_erariale is not null;
     end if;
     return nvl(w_importo,0);
  end;
------------------------------------------------------------------
  function importi_riep(a_cf      varchar2,
                        a_pratica number,
                        a_anno    number,
                        a_data    varchar2) return sys_refcursor is
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
       lpad(stampa_common.f_formatta_numero(vd.deim_tot,'I','S'),43) deim_tot,
       lpad(stampa_common.f_formatta_numero(vd.deim_vers_tot,'I','S'),18) deim_vers_tot,
       lpad(stampa_common.f_formatta_numero(vd.deim_tot - vd.deim_vers_tot,'I','S'),18) deim_diff_tot,
       lpad(stampa_common.f_formatta_numero(vd.deim_tot_arr,'I','S'),43) deim_tot_arr,
       lpad(stampa_common.f_formatta_numero(vd.deim_tot_arr - vd.deim_vers_tot,'I','S'),18) deim_diff_tot_arr,
       decode(rtrim(replace(replace(replace(vd.deim_tot ||
                                            vd.deim_vers_tot,
                                            '0',
                                            ''),
                                    ',',
                                    ''),
                            '.',
                            '')),
              null,
              null,
              lpad(' ', 43) || rpad(' _', 18, '_') || rpad(' _', 18, '_') ||
              rpad(' _', 18, '_')) line_comune
        from (select sum(ogim.imposta) deim_tot,
                     round(importo_per_codice_f24(a_pratica,3958,'U')) +
                     round(importo_per_codice_f24(a_pratica,3959,'U')) +
                     round(importo_per_codice_f24(a_pratica,3960,'U')) +
                     round(importo_per_codice_f24(a_pratica,3961,'U')) deim_tot_arr,
                     max(vers.ab_principale) +
                     max(f_importo_vers_ravv_dett(a_cf,
                                                  p_tipo_tributo, --'TASI',
                                                  a_anno,
                                                  'U',
                                                  'ABP',
                                                  p_data)) +
                     max(vers.rurali) +
                     max(f_importo_vers_ravv_dett(a_cf,
                                                  p_tipo_tributo, --'TASI',
                                                  a_anno,
                                                  'U',
                                                  'RUR',
                                                  p_data)) +
                     max(vers.terreni_agricoli) +
                     max(f_importo_vers_ravv_dett(a_cf,
                                                  p_tipo_tributo, --'TASI',
                                                  a_anno,
                                                  'U',
                                                  'TEC',
                                                  p_data)) +
                     max(vers.aree_fabbricabili) +
                     max(f_importo_vers_ravv_dett(a_cf,
                                                  p_tipo_tributo, --'TASI',
                                                  a_anno,
                                                  'U',
                                                  'ARC',
                                                  p_data)) +
                     max(vers.altri_fabbricati) +
                     max(f_importo_vers_ravv_dett(a_cf,
                                                  p_tipo_tributo, --'TASI',
                                                  a_anno,
                                                  'U',
                                                  'ALC',
                                                  p_data)) +
                     max(vers.fabbricati_d) +
                     max(f_importo_vers_ravv_dett(a_cf,
                                                  p_tipo_tributo, --'TASI',
                                                  a_anno,
                                                  'U',
                                                  'FDC',
                                                  p_data)) deim_vers_tot
                from oggetti_imposta ogim,
                     oggetti_pratica ogpr,
                     oggetti ogge,
                     (select nvl(sum(ab_principale), 0) ab_principale,
                             nvl(sum(rurali), 0) rurali,
                             nvl(sum(terreni_agricoli), 0) terreni_agricoli,
                             nvl(sum(aree_fabbricabili), 0) aree_fabbricabili,
                             nvl(sum(altri_fabbricati), 0) altri_fabbricati,
                             nvl(sum(fabbricati_d), 0) fabbricati_d
                        from versamenti vers
                       where vers.tipo_tributo || '' = p_tipo_tributo --'TASI'
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
  /******************************************************************************
    NOME:        IMPORTI_RIEP_DEIM_COMUNE.
    DESCRIZIONE: Restituisce un ref_cursor contenente l'elenco degli imposte
                 dovute al comune suddivise per tipologia (codice tributo F24).
    RITORNA:     ref_cursor.
    NOTE:
    Rev.  Data        Autore  Descrizione
    ----  ----------  ------  ----------------------------------------------------
    001   29/12/2021  VD      Issue #53742: aggiunti importi arrotondati.
  ******************************************************************************/
    return sys_refcursor is
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
             a_tot_dovuto as tot_dovuto,
             a_tot_versato as tot_versato,
             a_tot_differenza as tot_differenza,
             a_st_comune as st_comune,
             deim.descrizione,
             deim.codice,
             stampa_common.f_formatta_numero(deim.dovuto,'I','S') dovuto,
             stampa_common.f_formatta_numero(deim.versato,'I','S') versato,
             stampa_common.f_formatta_numero(deim.dovuto - deim.versato,'I','S') differenza,
             stampa_common.f_formatta_numero(round(deim.dovuto),'I','S') dovuto_arr,
             stampa_common.f_formatta_numero(round(deim.dovuto) - deim.dovuto,'I','S') arrotondamento,
             stampa_common.f_formatta_numero(round(deim.dovuto) - deim.versato,'I','S') differenza_arr,
             stampa_common.f_formatta_numero(sum(round(deim.dovuto)) over(),'I','S') tot_dovuto_arr,
             stampa_common.f_formatta_numero(sum(deim.versato) over(),'I','S') tot_versato_arr,
             stampa_common.f_formatta_numero(sum(round(deim.dovuto) - deim.versato) over(),'I','S') tot_differenza_arr
        from (select 'C' cod_sorgente,
                     rpad('TASI - Abitazioni Principali', 39) descrizione,
                     3958 codice,
                     sum(ogim.imposta) dovuto,
                     max(vers.ab_principale)
                      + max(f_importo_vers_ravv_dett(a_cf
                                                    ,'TASI'
                                                    ,a_anno
                                                    ,'U'
                                                    ,'ABP'
                                                    ,p_data)) versato
                from oggetti_imposta ogim
                    ,oggetti_pratica ogpr
                    ,(select nvl(sum(ab_principale), 0) ab_principale
                        from versamenti vers
                       where vers.tipo_tributo || '' = 'TASI'
                         and vers.pratica is null
                         and vers.anno = a_anno
                         and vers.cod_fiscale = a_cf
                         and vers.data_pagamento <= p_data) vers
               where ogim.oggetto_pratica = ogpr.oggetto_pratica
                 and ogpr.pratica = a_pratica
                 and ogim.tipo_aliquota = 2
              having sum(decode(ogim.tipo_aliquota, 2, ogim.imposta, 0)) > 0
                  or   max(vers.ab_principale)
                     + max(f_importo_vers_ravv_dett(a_cf
                                                   ,'TASI'
                                                   ,a_anno
                                                   ,'U'
                                                   ,'ABP'
                                                   ,p_data)) > 0
              union
              select 'C',
                     rpad('TASI - Fabbricati Rurali', 39),
                     3959,
                     sum(ogim.imposta),
                     max(vers.rurali)
                      + max(f_importo_vers_ravv_dett(a_cf
                                                    ,'TASI'
                                                    ,a_anno
                                                    ,'U'
                                                    ,'RUR'
                                                    ,p_data))
                from oggetti_imposta ogim
                    ,oggetti_pratica ogpr
                    ,oggetti ogge
                    ,(select nvl(sum(rurali), 0) rurali
                        from versamenti vers
                       where vers.tipo_tributo || '' = 'TASI'
                         and vers.pratica is null
                         and vers.anno = a_anno
                         and vers.cod_fiscale = a_cf
                         and vers.data_pagamento <= p_data) vers
               where ogim.oggetto_pratica = ogpr.oggetto_pratica
                 and ogpr.pratica = a_pratica
                 and ogpr.oggetto = ogge.oggetto
                 and ogim.tipo_aliquota <> 2
                 and nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto) not in (1,2)
                 and aliquota_erariale is null
              having sum(ogim.imposta) > 0
                  or   max(vers.rurali)
                     + max(f_importo_vers_ravv_dett(a_cf
                                                   ,'TASI'
                                                   ,a_anno
                                                   ,'U'
                                                   ,'RUR'
                                                   ,p_data)) > 0
              union
              select 'C',
                     rpad('TASI - Aree Fabbricabili', 39),
                     3960,
                     sum(ogim.imposta - nvl(ogim.imposta_erariale, 0)),
                     max(vers.aree_comune)
                     + max(f_importo_vers_ravv_dett(a_cf
                                                   ,'TASI'
                                                   ,a_anno
                                                   ,'U'
                                                   ,'ARC'
                                                   ,p_data))
                from oggetti_imposta ogim
                    ,oggetti_pratica ogpr
                    ,oggetti ogge
                    ,(select nvl(sum(aree_fabbricabili), 0) aree_comune
                        from versamenti vers
                       where vers.tipo_tributo || '' = 'TASI'
                         and vers.pratica is null
                         and vers.anno = a_anno
                         and vers.cod_fiscale = a_cf
                         and vers.data_pagamento <= p_data) vers
               where ogim.oggetto_pratica = ogpr.oggetto_pratica
                 and ogpr.pratica = a_pratica
                 and ogpr.oggetto = ogge.oggetto
                 and nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto) = 2
              having sum(ogim.imposta - nvl(ogim.imposta_erariale, 0)) > 0
                  or   max(vers.aree_comune)
                     + max(f_importo_vers_ravv_dett(a_cf
                                                   ,'TASI'
                                                   ,a_anno
                                                   ,'U'
                                                   ,'ARC'
                                                   ,p_data)) > 0
              union
              select 'C',
                     rpad('TASI - Altri Fabbricati', 39),
                     3961,
                     sum(ogim.imposta - nvl(ogim.imposta_erariale,0)),
                     max(vers.altri_comune)
                     + max(f_importo_vers_ravv_dett(a_cf
                                                   ,'TASI'
                                                   ,a_anno
                                                   ,'U'
                                                   ,'ALC'
                                                   ,p_data))
                from oggetti_imposta ogim
                    ,oggetti_pratica ogpr
                    ,oggetti ogge
                    ,(select nvl(sum(altri_fabbricati), 0) altri_comune
                        from versamenti vers
                       where vers.tipo_tributo || '' = 'TASI'
                         and vers.pratica is null
                         and vers.anno = a_anno
                         and vers.cod_fiscale = a_cf
                         and vers.data_pagamento <= p_data) vers
               where ogim.oggetto_pratica = ogpr.oggetto_pratica
                 and ogpr.pratica = a_pratica
                 and ogpr.oggetto = ogge.oggetto
                 and ogim.tipo_aliquota <> 2
                 and nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto) not in (1,2)
                 and aliquota_erariale is not null
              having sum(ogim.imposta - nvl(ogim.imposta_erariale,0)) > 0
                  or   max(vers.altri_comune)
                     + max(f_importo_vers_ravv_dett(a_cf
                                                   ,'TASI'
                                                   ,a_anno
                                                   ,'U'
                                                   ,'ALC'
                                                   ,p_data)) > 0) deim
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
    001   03/01/2022  VD      Prima emissione.
                              Issue #53742: aggiunti importi arrotondati.
  ******************************************************************************/
    rc sys_refcursor;
  begin
    open rc for
    select codice,
           descr,
           stampa_common.f_formatta_numero(acconto, 'I', 'S') imposta_acconto,
           stampa_common.f_formatta_numero(saldo, 'I', 'S')   imposta_saldo,
           stampa_common.f_formatta_numero(nvl(acconto,0) + nvl(saldo,0), 'I', 'S') imposta_totale,
           stampa_common.f_formatta_numero(sum(sum(acconto)) over(), 'I', 'S') totale_acconto,
           stampa_common.f_formatta_numero(sum(sum(saldo)) over(), 'I', 'S')   totale_saldo,
           stampa_common.f_formatta_numero(sum(sum(nvl(acconto,0) + nvl(saldo,0))) over(), 'I', 'S') totale
      from
    (select 3958 codice,
            'TASI - ABITAZIONI PRINCIPALI' descr,
            round(nvl(sum(ogim.imposta_acconto),0)) acconto,
            round(nvl(sum(ogim.imposta),0)) -
            round(nvl(sum(ogim.imposta_acconto),0)) saldo
       from oggetti_imposta ogim
          , oggetti_pratica ogpr
      where ogim.oggetto_pratica = ogpr.oggetto_pratica
        and ogpr.pratica = a_pratica
        and ogim.tipo_aliquota = 2
     having sum(ogim.imposta) > 0
    union
    select 3959 codice,
           'TASI - FABBRICATI RURALI' descr,
           round(nvl(sum(ogim.imposta_acconto),0)) acconto,
           round(nvl(sum(ogim.imposta),0)) -
           round(nvl(sum(ogim.imposta_acconto),0)) saldo
      from oggetti_imposta ogim
          ,oggetti_pratica ogpr
          ,oggetti ogge
     where ogim.oggetto_pratica = ogpr.oggetto_pratica
       and ogpr.pratica = a_pratica
       and ogpr.oggetto = ogge.oggetto
       and ogim.tipo_aliquota <> 2
       and nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto) not in (1,2)
       and aliquota_erariale is null
    having sum(ogim.imposta) > 0
    union
    select 3960 codice,
           'TASI - AREE FABBRICABILI' descr,
           round(nvl(sum(ogim.imposta_acconto),0)) acconto,
           round(nvl(sum(ogim.imposta),0)) -
           round(nvl(sum(ogim.imposta_acconto),0)) saldo
      from oggetti_imposta ogim
          ,oggetti_pratica ogpr
          ,oggetti ogge
     where ogim.oggetto_pratica = ogpr.oggetto_pratica
       and ogpr.pratica = a_pratica
       and ogpr.oggetto = ogge.oggetto
       and nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto) = 2
    having sum(ogim.imposta) > 0
    union
    select 3961 codice,
           'TASI - ALTRI FABBRICATI' descr,
           round(nvl(sum(ogim.imposta_acconto),0)) acconto,
           round(nvl(sum(ogim.imposta),0)) -
           round(nvl(sum(ogim.imposta_acconto),0)) saldo
      from oggetti_imposta ogim
          ,oggetti_pratica ogpr
          ,oggetti ogge
     where ogim.oggetto_pratica = ogpr.oggetto_pratica
       and ogpr.pratica = a_pratica
       and ogpr.oggetto = ogge.oggetto
       and ogim.tipo_aliquota <> 2
       and nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto) not in (1,2)
       and aliquota_erariale is not null
    having sum(ogim.imposta) > 0
     order by codice)
     group by codice, descr, acconto, saldo;
    return rc;
  end;
------------------------------------------------------------------
  function importi(a_pratica      number,
                   a_modello      number,
                   a_modello_rimb number) return sys_refcursor is
    rc sys_refcursor;
  begin
    rc := stampa_liquidazioni_imu.importi(a_pratica,a_modello,a_modello_rimb);
    return rc;
  end;
------------------------------------------------------------------
  function sanzioni(a_pratica number) return sys_refcursor is
    rc sys_refcursor;
  begin
    rc := stampa_liquidazioni_imu.sanzioni(a_pratica);
    return rc;
  end;
------------------------------------------------------------------
  function interessi(a_pratica number) return sys_refcursor is
    rc sys_refcursor;
  begin
    rc := stampa_liquidazioni_imu.interessi(a_pratica);
    return rc;
  end;
------------------------------------------------------------------
  function interessi_dettaglio
  ( a_pratica               number default -1
  , a_modello               number default -1
  ) return sys_refcursor is
    rc sys_refcursor;
  begin
    rc := stampa_liquidazioni_imu.interessi_dettaglio(a_pratica,a_modello);
    return rc;
  end;
------------------------------------------------------------------
  function riepilogo_dovuto(a_pratica number) return sys_refcursor is
    rc sys_refcursor;
  begin
    rc := stampa_liquidazioni_imu.riepilogo_dovuto(a_pratica);
    return rc;
  end;
------------------------------------------------------------------
  function riepilogo_da_versare(a_pratica number) return sys_refcursor is
    rc sys_refcursor;
  begin
    rc := stampa_liquidazioni_imu.riepilogo_da_versare(a_pratica);
    return rc;
  end;
------------------------------------------------------------------
  function interessi_g_applicati(a_tipo_tributo varchar2,
                                 a_anno         number,
                                 a_data         varchar2)
    return sys_refcursor is
    rc         sys_refcursor;
  begin
    rc := stampa_liquidazioni_imu.interessi_g_applicati(a_tipo_tributo,a_anno,a_data);
    return rc;
  end;
------------------------------------------------------------------
  function aggi_dilazione
  ( a_pratica                                   number default -1
  , a_modello                                   number default -1
  ) return sys_refcursor is
    rc         sys_refcursor;
  begin
    rc := stampa_liquidazioni_imu.aggi_dilazione(a_pratica,a_modello);
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
------------------------------------------------------------------
  function principale(a_cf           varchar2,
                      a_vett_prat    varchar2,
                      a_modello      number,
                      a_modello_rimb number,
                      a_ni_erede     number default -1) return sys_refcursor is
    rc sys_refcursor;
  begin
    rc := stampa_liquidazioni_imu.principale(a_cf,a_vett_prat,a_modello,a_modello_rimb,a_ni_erede);
    return rc;
  end;
------------------------------------------------------------------
end stampa_liquidazioni_tasi;
/
