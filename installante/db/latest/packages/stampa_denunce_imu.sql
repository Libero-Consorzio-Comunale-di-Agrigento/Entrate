--liquibase formatted sql 
--changeset abrandolini:20250326_152429_stampa_denunce_imu stripComments:false runOnChange:true 
 
create or replace package STAMPA_DENUNCE_IMU is
/******************************************************************************
 NOME:        STAMPA_DENUNCE_IMU
 DESCRIZIONE: Funzione per stampa comunicazioni di denuncia IMU

 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 000   06/04/2023  RV       #Issue63502
                            Emissione iniziale
 ****************************************************************************/

  function contribuente
  ( a_pratica              number default -1
  ) return sys_refcursor;

  function frontespizio
  ( a_cf                   varchar2 default ''
  , a_pratica              number default -1
  , a_modello              number default -1
  ) return sys_refcursor;

  function contitolari
  ( a_cf                   varchar2 default ''
  , a_pratica              number default -1
  , a_modello              number default -1
  ) return sys_refcursor;

  function immobili
  ( a_cf                   varchar2 default ''
  , a_pratica              number default -1
  , a_tipi_oggetto         varchar2 default ''
  , a_modello              number default -1
  ) return sys_refcursor;
  
  function f_codice_esenzione
  ( a_cf                   varchar2, 
    a_ogpr                 number
  ) return number;
  
  function f_codice_riduzione
  ( a_cf                   varchar2, 
    a_ogpr                 number
  ) return number;

end STAMPA_DENUNCE_IMU;
/
create or replace package body STAMPA_DENUNCE_IMU is
/******************************************************************************
 NOME:        STAMPA_DENUNCE_IMU
 DESCRIZIONE: Funzione per stampa comunicazioni di denuncia IMU
 ANNOTAZIONI: -
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 003   01/09/2025  DM       #Issue63478
                            Modifiche per generazione modello ministeriale
 002   09/05/2023  RV       #Issue63502-FeedBack
                            Immobili rivisto formato rendita e valore
 001   19/04/2023  RV       #Issue63502-FeedBack
                            Immobili + ESTREMI_CATASTO1, ESTREMI_CATASTO2, DESC_TIPO_OGGETTO
 000   07/04/2023  RV       #Issue63502
                            Emissione iniziale
******************************************************************************/

  function contribuente
  ( a_pratica                           number
  ) return sys_refcursor is
  
    rc sys_refcursor;
  begin
    rc := stampa_common.contribuente(a_pratica);
    return rc;
  end contribuente;
  
  function frontespizio
  ( a_cf                   varchar2 default ''
  , a_pratica              number default -1
  , a_modello              number default -1
  ) return sys_refcursor is
    rc                                 sys_refcursor;
  begin
    open rc for
      select
        prtr.pratica,
        prtr.anno,
        prtr.tipo_tributo,
        prtr.tipo_pratica,
        prtr.tipo_evento,
        prtr.numero,
        deic.denuncia,
        to_char(prtr.data, 'DD/MM/YYYY') data,
        prtr.cod_fiscale,
        deic.prefisso_telefonico,
        deic.num_telefonico,
        deic.flag_firma,
        deic.flag_denunciante,
        prtr.indirizzo_den,
        comu.denominazione,
        prtr.tipo_carica,
        prtr.cod_fiscale_den,
        prtr.cod_pro_den,
        prtr.cod_com_den,
        nvl(f_recapito(sogg_den.ni, prtr.tipo_tributo, 2), f_recapito(sogg_den.ni, prtr.tipo_tributo, 3)) email_den,
        deic.flag_cf,
        prtr.denunciante,
        prtr.utente,
        prtr.note,
        comu.sigla_cfis cod_catasto,
        prtr.motivo,
        to_char(deic.data_variazione, 'DD/MM/YYYY') data_variazione,
        f_esiste_dato_caricamento(to_number(null),prtr.cod_fiscale,'ici',a_pratica) esiste_enc,
        a_modello modello
      from
        denunce_ici deic,
        pratiche_tributo prtr,
        ad4_comuni comu,
        ad4_provincie prov,
        soggetti sogg_Den
      where
        (comu.provincia_stato = prov.provincia (+)) and
        (prtr.cod_pro_den = comu.provincia_stato (+)) and
        (prtr.cod_com_den = comu.comune (+)) and
        (deic.pratica = prtr.pratica) and
        ((prtr.cod_fiscale = a_cf) and
        (prtr.pratica = a_pratica))
        and sogg_den.cod_fiscale (+) = prtr.cod_fiscale_den;
    
    return rc;    
  end frontespizio;

  function contitolari
  ( a_cf                   varchar2 default ''
  , a_pratica              number default -1
  , a_modello              number default -1
  ) return sys_refcursor is
  
    rc sys_refcursor;
  begin
    open rc for
      select
        sogg.ni,
        ogco.cod_fiscale,
        ogco.oggetto_pratica,
        ogco.anno,
        ogco.tipo_rapporto,
        ogge.oggetto,
        ogpr.tipo_oggetto,
        ogge.num_civ,
        ogge.suffisso,
        ogge.scala,
        ogge.piano,
        ogge.interno,
        ogge.partita,
        ogge.sezione,
        ogge.foglio,
        ogge.numero,
        ogge.subalterno,
        ogge.anno_catasto,
        ogge.protocollo_catasto,
        ogpr.categoria_catasto,
        ogpr.classe_catasto,
        ogpr.num_ordine,
        ogpr.imm_storico,
        ogpr.valore,
        ogpr.titolo,
        ogpr.estremi_titolo,
        ogpr.modello,
        ogpr.fonte,
        ogpr.flag_provvisorio,
        ogco.perc_possesso,
        ogco.mesi_possesso,
        ogco.mesi_possesso_1sem,
        ogco.mesi_esclusione,
        ogco.mesi_riduzione,
        ogco.detrazione,
        ogco.mesi_aliquota_ridotta,
        ogco.flag_possesso,
        ogco.flag_esclusione,
        ogco.flag_riduzione,
        ogco.flag_ab_principale,
        ogco.flag_al_ridotta,
        decode(ogco.flag_possesso,null,'','P') as flag_possesso_descr,
        decode(ogco.flag_esclusione,null,'','E') as flag_esclusione_descr,
        decode(ogco.flag_riduzione,null,'','R') as flag_riduzione_descr,
        decode(ogco.flag_ab_principale,null,'','AP') as flag_ab_principale_descr,
        decode(ogco.flag_al_ridotta,null,'','AR') as flag_al_ridotta_descr,
        sogg.cognome_nome,
        nvl(sogg.cap,comu_res.cap) cap_res,
        --sogg.num_civ,
        --sogg.suffisso,
        --sogg.scala,
        --sogg.piano,
        --sogg.interno,
        prov_res.sigla prov_res,
        comu_res.denominazione comune_res,
        prov_nas.sigla prov_nas,
        comu_nas.denominazione comune_nas,
        '' dep_catasto,
        '' dep_protocollo,
        decode(sogg.cod_via,null,sogg.denominazione_via,avies.denom_uff|| decode(sogg.num_civ, null,'', ', '|| sogg.num_civ|| decode( sogg.suffisso, null, '', '/'||sogg.suffisso))) indirizzo_sogg,
        decode(ogge.cod_via,null,ogge.indirizzo_localita,avieo.denom_uff) indirizzo_ogg  ,
        to_char(ogco.data_variazione, 'DD/MM/YYYY') data_variazione,
        a_cf cod_fiscale_tit,
        a_modello modello,
        sogg.data_nas,
        sogg.sesso
      from
        oggetti ogge,
        oggetti_pratica ogpr,
        oggetti_contribuente ogco,
        pratiche_tributo prtr,
        soggetti sogg,
        contribuenti cont,
        archivio_vie avieo,
        ad4_comuni comu_res,
        ad4_provincie prov_res,
        ad4_comuni comu_nas,
        ad4_provincie prov_nas,        
        archivio_vie avies
      where
        (ogge.cod_via = avieo.cod_via (+)) and
        (comu_res.provincia_stato = prov_res.provincia (+)) and
        (sogg.cod_pro_res = comu_res.provincia_stato (+)) and
        (sogg.cod_com_res = comu_res.comune (+)) and
        
        (comu_nas.provincia_stato = prov_nas.provincia (+)) and
        (sogg.cod_pro_nas = comu_nas.provincia_stato (+)) and
        (sogg.cod_com_nas = comu_nas.comune (+)) and
        
        (sogg.cod_via = avies.cod_via (+)) and
        (ogge.oggetto = ogpr.oggetto) and
        (ogpr.oggetto_pratica = ogco.oggetto_pratica) and
        (sogg.ni = cont.ni) and
        (ogco.cod_fiscale = cont.cod_fiscale) and
        (ogpr.pratica = prtr.pratica) and
        (prtr.pratica = a_pratica) and
        (ogco.tipo_rapporto = 'C')
      order by ogge.oggetto asc;

    return rc;
  end contitolari;

  function immobili
  ( a_cf                   varchar2 default ''
  , a_pratica              number default -1
  , a_tipi_oggetto         varchar2 default ''
  , a_modello              number default -1
  ) return sys_refcursor is
  
    rc sys_refcursor;
  begin
    open rc for
      select
        ogpr.oggetto_pratica,
        ogpr.oggetto,
        ogpr.pratica,
        ogpr.tipo_oggetto,
        ogge.num_civ,
        ogge.suffisso,
        ogge.scala,
        ogge.piano,
        ogge.interno,
        ogge.partita,
        ogge.sezione,
        ogge.foglio,
        ogge.numero,
        ogge.subalterno,
        ogge.anno_catasto,
        ogge.protocollo_catasto,
        ogge.qualita,
        ogge.tipo_qualita,
        ogpr.categoria_catasto,
        ogpr.classe_catasto,
        ogpr.num_ordine,
        ogpr.imm_storico,
        stampa_common.f_formatta_numero(f_rendita(ogpr.valore,nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto),
                        prtr.anno,nvl(ogpr.categoria_catasto,ogge.categoria_catasto)),'I') rendita,
        stampa_common.f_formatta_numero(ogpr.valore,'I') valore,
        ogpr.titolo,
        ogpr.estremi_titolo,
        ogpr.modello,
        ogpr.fonte,
        ogpr.qualita,
        ogpr.tipo_qualita,
        ogpr.oggetto_pratica_rif_ap,
        ogpr_rif_ap.oggetto oggetto_ap,
        ogco.perc_possesso,
        ogco.mesi_possesso,
        ogco.da_mese_possesso,
        ogco.mesi_esclusione,
        ogco.mesi_riduzione,
        ogco.mesi_aliquota_ridotta,
        ogco.detrazione,
        ogco.flag_possesso,
        ogco.flag_esclusione,
        ogco.flag_riduzione,
        ogco.flag_ab_principale,
        ogco.flag_al_ridotta,
        decode(ogco.flag_possesso,null,'','P') as flag_possesso_descr,
        decode(ogco.flag_esclusione,null,'','E') as flag_esclusione_descr,
        decode(ogco.flag_riduzione,null,'','R') as flag_riduzione_descr,
        decode(ogco.flag_ab_principale,null,'','AP') as flag_ab_principale_descr,
        decode(ogco.flag_al_ridotta,null,'','AR') as flag_al_ridotta_descr,
        ogco.successione,
        ogco.progressivo_sudv,
        ogge.cod_via,
        decode(ogge.cod_via,null,ogge.indirizzo_localita,avie.denom_uff) indirizzo_ogg,
        ogco.mesi_possesso_1sem,
        ogpr.flag_provvisorio,
        ogpr.anno,
        ogpr.note,
        prtr.anno anno_pratica ,
        f_esiste_detrazione_ogco(ogco.oggetto_pratica,ogco.cod_fiscale,'ICI') detrazione_ogco,
        f_esiste_aliquota_ogco(ogco.oggetto_pratica,ogco.cod_fiscale,'ICI') aliquota_ogco,
        f_esiste_dato_caricamento(ogco.oggetto_pratica,ogco.cod_fiscale,'ICI') esiste_daco,
        to_char(ogco.data_variazione, 'DD/MM/YYYY') data_variazione,
        decode(ogge.cod_via,null,ogge.indirizzo_localita,avie.denom_uff)||
          decode(ogge.num_civ,null,null,', '||ogge.num_civ)||
          decode(ogge.suffisso,null,null,'/'||ogge.suffisso)||
          decode(ogge.interno,null,null,' Int. '||ogge.interno)||
          decode(ogge.scala,null,null,' Sc. '||ogge.scala)||
          decode(ogge.piano,null,null,' P. '||ogge.piano) indirizzo_completo,
        ltrim(
          decode(ogge.sezione,null,'',' Sez. '||ogge.sezione)||
          decode(ogge.foglio,null,'',' Foglio '||ogge.foglio)||
          decode(ogge.numero,null,'',' Num. '||ogge.numero)||
          decode(ogge.subalterno,null,'',' Sub. '||ogge.subalterno)||
          decode(ogge.zona,null,'',' Zona '||ogge.zona)) estremi_catasto1,
        ltrim(decode(ogge.sezione||ogge.foglio||ogge.numero||ogge.subalterno||ogge.zona
                      ,'',decode(ogge.protocollo_catasto,null,'',' Protocollo Numero '||ogge.protocollo_catasto)||
                          decode(ogge.anno_catasto,null,'',' Protocollo Anno '||to_char(ogge.anno_catasto))
                      ,'')||
              decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                      ,1,''
                      ,2,''
                      ,decode(nvl(ogpr.categoria_catasto,ogge.categoria_catasto)
                         ,null,'',' Cat. '||nvl(ogpr.categoria_catasto,ogge.categoria_catasto))||
                                    decode(nvl(ogpr.classe_catasto,ogge.classe_catasto)
                         ,null,'',' Cl. '||nvl(ogpr.classe_catasto,ogge.classe_catasto)
                                          ))) estremi_catasto2,
        tiog.descrizione desc_tipo_oggetto,
        a_cf cod_fiscale_tit,
        a_modello modello,
        nvl(ogco.data_evento,
          decode(nvl(ogco.flag_possesso, 'N'), 'S',
                 f_get_data_inizio_da_mese(prtr.anno, ogco.da_mese_possesso),
                 f_get_data_fine_da_mese(prtr.anno, ogco.mesi_possesso, ogco.da_mese_possesso)
          )
        ) data_evento,
        f_codice_esenzione(a_cf, ogpr.oggetto_pratica) cod_esenzione,
        f_codice_riduzione(a_cf, ogpr.oggetto_pratica) cod_riduzione
      from
        oggetti_contribuente ogco,
        oggetti_pratica ogpr,
        oggetti_pratica ogpr_rif_ap,
        oggetti ogge,
        tipi_oggetto tiog,
        pratiche_tributo prtr,
        archivio_vie avie
      where
        (ogge.cod_via = avie.cod_via (+)) and
        (ogge.oggetto = ogpr.oggetto) and
        tiog.tipo_oggetto = nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto) and
        (ogpr.oggetto_pratica = ogco.oggetto_pratica) and
        (ogpr.pratica = prtr.pratica) and
        (prtr.pratica = a_pratica) and
        (ogco.tipo_rapporto = 'D')  and
        (ogpr_rif_ap.oggetto_pratica (+) = ogpr.oggetto_pratica_rif_ap)
      order by
        lpad(nvl(decode(instr(ogpr.num_ordine,'/'),0,ogpr.num_ordine
          ,substr(ogpr.num_ordine,1,instr(ogpr.num_ordine,'/') -1 )),'0'),4,'0')
        ,lpad(nvl(decode(instr(ogpr.num_ordine,'/'),0,'0'
          ,substr(ogpr.num_ordine,instr(ogpr.num_ordine,'/') +1 )),'0'),4,'0');
    
    return rc;
  end immobili;
  
  function f_codice_esenzione
  ( a_cf                   varchar2, 
    a_ogpr                 number
  ) return number is
  
    w_codice_esenzione number(1);
  begin
    select decode(nvl(ogco.flag_esclusione, 'N'),
                  'S',
                  nvl(enim.cod_esenzione, 3),
                  0)
      into w_codice_esenzione
      from oggetti_pratica      ogpr,
           oggetti_contribuente ogco,
           wrk_enc_immobili     enim
     where ogpr.oggetto_pratica = ogco.oggetto_pratica
       and ogpr.oggetto_pratica = a_ogpr
       and ogco.cod_fiscale = a_cf
       and enim.tr4_oggetto_pratica_ici (+) = ogpr.oggetto_pratica;
  
    return w_codice_esenzione;
  end;
  
  /*
    In presenza di riduzione se ne determina il codice:
    - se presente si restituisce il codice importato dai flussi
    - altrimenti, in caso di immobile storico, si restituisce 1
    - altrimenti 5
    
    La funziona restituisce 0 in assenza di riduzioni.
    I codici sono quelli definiti nel tracciato ministerial:
    1 = Immobile storico
    5 = Altre riduzioni
  */
  function f_codice_riduzione
  ( a_cf                   varchar2, 
    a_ogpr                 number
  ) return number is
  
    w_codice_riduzione number(1);
  begin
    select decode(nvl(ogco.flag_riduzione, 'N'),
                  'S',
                  nvl(
                     enim.cod_riduzione, 
                     decode(ogpr.imm_storico, 'S', 1, 5)
                  ),
                  0)
      into w_codice_riduzione
      from oggetti_pratica      ogpr,
           oggetti_contribuente ogco,
           wrk_enc_immobili     enim
     where ogpr.oggetto_pratica = ogco.oggetto_pratica
       and ogpr.oggetto_pratica = a_ogpr
       and ogco.cod_fiscale = a_cf
       and enim.tr4_oggetto_pratica_ici (+) = ogpr.oggetto_pratica;
  
    return w_codice_riduzione;
  end;
end STAMPA_DENUNCE_IMU;
/
