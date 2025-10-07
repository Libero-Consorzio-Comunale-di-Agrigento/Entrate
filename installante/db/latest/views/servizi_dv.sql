--liquibase formatted sql 
--changeset abrandolini:20250326_152401_servizi_dv stripComments:false runOnChange:true 
 
create or replace force view servizi_dv as
select 'SERVIZI_DOVUTO_VERSATO' fonte
 , /*   decode (F_SERV_CONT_CATA (ogim_anno.anno,ogim_anno.tipo_tributo,cont.COD_FISCALE)+
  F_SERV_CONT_NO_CATA (ogim_anno.anno,ogim_anno.tipo_tributo,cont.COD_FISCALE)+
  F_SERV_CONT_OGGE_CATA (ogim_anno.anno,ogim_anno.tipo_tributo,cont.COD_FISCALE),
    0,'Contribuente con Catasto Coerente',
   'Contribuente con Catasto NON Coerente')*/
  ' ' segnalazione
 ,sogg.cognome_nome ragionesociale
 ,ogim_anno.cod_fiscale codicefiscale
 ,ogim_anno.anno anno
 ,ogim_anno.num_oggetti numoggetti
 ,ogim_anno_fabb.num_fabbr numfabbricati
 ,ogim_anno_terr.num_terr numterreni
 ,ogim_anno_aree.num_aree numaree
-- ,decode(ogim_anno.tipo_tributo
--  ,'ICI', nvl(ogim_anno.dovuto, 0) -
--    nvl(supporto_servizi_pkg.f_serv_tot_vers(ogim_anno.anno
--     ,'ICI'
--     ,ogim_anno.cod_fiscale
--     )
--    ,0
--    )
--  ,0
--  )
--   differenza_imu
-- ,nvl(ogim_tasi.dovuto_tasi, 0) -
--  nvl(supporto_servizi_pkg.f_serv_tot_vers(ogim_anno.anno
--   ,'TASI'
--   ,ogim_anno.cod_fiscale
--   )
--  ,0
--  )
--   differenza_imposta_tasi
 ,decode(ogim_anno.tipo_tributo
  ,'ICI', nvl(ogim_anno.dovuto, 0) -
    nvl(supporto_servizi_pkg.f_serv_tot_vers(ogim_anno.anno
     ,'ICI'
     ,ogim_anno.cod_fiscale
     )
    ,0
    )
  ,'TASI', nvl(ogim_tasi.dovuto_tasi, 0) -
  nvl(supporto_servizi_pkg.f_serv_tot_vers(ogim_anno.anno
      ,'TASI'
      ,ogim_anno.cod_fiscale
      )
    ,0
    )
   ,0
  )
   differenza_imposta
 , /*   DECODE (
   DECODE (
   sogg.tipo_residente,
   0,
   f_ult_eve_AL (
   sogg.matricola,
   TO_NUMBER(TO_CHAR (
    TO_DATE (
    '0101' || TO_CHAR (ogim_anno.anno),
    'ddmmyyyy'
    ),
    'J'
    )),
   'FASCIA'
   ),
   NULL
   ),
   1,
   'RESIDENTE'
   )*/
  null res_storico_gsd_inizio_anno
 , /* DECODE (
 DECODE (
    sogg.tipo_residente,
    0,
    f_ult_eve_AL (
    sogg.matricola,
    TO_NUMBER(TO_CHAR (
     TO_DATE (
     '3112' || TO_CHAR (ogim_anno.anno),
     'ddmmyyyy'
     ),
     'J'
  )),
    'FASCIA'
    ),
    NULL
 ),
 1,
 'RESIDENTE'
 )*/
  null res_storico_gsd_fine_anno
 , /* TO_DATE (
 DECODE (
 sogg.tipo_residente,
 0,
 f_ult_eve_AL (
    sogg.matricola,
    TO_NUMBER(TO_CHAR (
  TO_DATE (
     '0101' || TO_CHAR (ogim_anno.anno),
     'ddmmyyyy'
  ),
  'J'
  )),
    'DATA_EVE'
 ),
 NULL
 ),
 'j'
 )*/
  to_number(null) residente_dal
 ,decode(sogg.tipo
  ,1, 'PersonaFisica'
  ,2, 'PersonaGiuridica'
  ,'IntestazioniParticolari'
  )
   personafisica
 ,data_nas data_nascita
 , /* DECODE (
    DECODE (
    sogg.tipo_residente,
    0,
    f_ult_eve_AL (
    sogg.matricola,
    TO_NUMBER(TO_CHAR (
     TO_DATE (
     '0101' || TO_CHAR (ogim_anno.anno),
     'ddmmyyyy'
     ),
     'J'
     )),
    'FASCIA'
    ),
    NULL
    ),
    3,
    'AIRE'
 )*/
  null aire_storico_gsd_inizio_anno
 , /*   DECODE (
   DECODE (
   sogg.tipo_residente,
   0,
   f_ult_eve_AL (
   sogg.matricola,
   TO_NUMBER(TO_CHAR (
    TO_DATE (
    '3112' || TO_CHAR (ogim_anno.anno),
    'ddmmyyyy'
    ),
    'J'
    )),
   'FASCIA'
   ),
   NULL
   ),
   3,
   'AIRE'
   )*/
  null aire_storico_gsd_fine_anno
 ,decode(sogg.stato, 50, 'Deceduto') deceduto
 ,decode(sogg.stato, 50, data_ult_eve) datadecesso
 ,null xxcontribuente_da_fare
 ,ogim_anno.min_max_perc_possesso min_max_perc_possesso
 ,supporto_servizi_pkg.f_serv_cont_cata(ogim_anno.anno
   ,ogim_anno.tipo_tributo
   ,cont.cod_fiscale
   )
   differenza_oggetti_catasto
 ,supporto_servizi_pkg.f_serv_cont_cata_terr(ogim_anno.anno
     ,cont.cod_fiscale
     )
   differenza_terreni_catasto
 ,supporto_servizi_pkg.f_serv_cont_no_cata(ogim_anno.anno
   ,ogim_anno.tipo_tributo
   ,cont.cod_fiscale
   )
   oggetti_non_catasto
 ,supporto_servizi_pkg.f_serv_cont_no_cata_terr(ogim_anno.anno
     ,cont.cod_fiscale
     )
   terreni_non_catasto
 ,supporto_servizi_pkg.f_serv_cont_ogge_cata(ogim_anno.anno
     ,ogim_anno.tipo_tributo
     ,cont.cod_fiscale
     )
   cata_no_tr4
 ,supporto_servizi_pkg.f_serv_cont_terre_cata(ogim_anno.anno
      ,cont.cod_fiscale
      )
   cata_no_tr4_terreni
 ,supporto_servizi_pkg.f_serv_num_prat(ogim_anno.anno
     ,ogim_anno.tipo_tributo
     ,ogim_anno.cod_fiscale
     ,'L'
     ) +
  supporto_servizi_pkg.f_serv_num_prat(ogim_anno.anno
     ,ogim_anno.tipo_tributo
     ,ogim_anno.cod_fiscale
     ,'A'
     )
   liquidazione_accertamento
 ,supporto_servizi_pkg.f_serv_num_prat_ads(ogim_anno.anno
   ,ogim_anno.tipo_tributo
   ,ogim_anno.cod_fiscale
   ,'L'
   )
   liquidazione_ads
 ,supporto_servizi_pkg.f_serv_num_iter_ads(ogim_anno.anno
   ,ogim_anno.tipo_tributo
   ,ogim_anno.cod_fiscale
   ,'L'
   )
   iter_ads
 ,supporto_servizi_pkg.f_serv_num_prat(ogim_anno.anno
     ,ogim_anno.tipo_tributo
     ,ogim_anno.cod_fiscale
     ,'V'
     )
   ravvedimento_imu
 ,ogim_anno.tipo_tributo
 ,supporto_servizi_pkg.f_serv_tot_vers(ogim_anno.anno
     ,ogim_anno.tipo_tributo
     ,ogim_anno.cod_fiscale
     )
   versato
 ,ogim_anno.dovuto
 ,ogim_anno.dovuto_comunale
 ,ogim_anno.dovuto_erariale
 ,ogim_anno.dovuto_acconto
 ,ogim_anno.dovuto_comunale_acconto
 ,ogim_anno.dovuto_erariale_acconto
 , /*  F_IMPOSTA_SEVIZI_DOVuto (ogim_anno.cod_fiscale,
   2015,
   2018,
   ogim_anno.tipo_tributo)
  - F_IMPOSTA_SEVIZI_VERSATO (ogim_anno.cod_fiscale,
   2015,
   2018,
   ogim_anno.tipo_tributo)   */
  to_number(null) diff_tot_contr
 ,supporto_servizi_pkg.f_serv_num_prat(ogim_anno.anno
     ,ogim_anno.tipo_tributo
     ,ogim_anno.cod_fiscale
     ,'D'
     )
   denunce_imu
 ,cont.cod_attivita codice_attivita_cont
 ,decode(sogg.tipo_residente
  ,0, (decode(fascia, 1, 'RESIDENTE', ''))
  ,''
  )
   residente_oggi
 ,ogim_ab_p.ab_pr ab_pr
 ,ogim_ab_p.pert pert
 ,ogim_tipo.altri_fabbricati altri_fabbricati
 ,ogim_tipo.fabb_d fabbricati_d
 ,ogim_tipo.terreni terreni
 ,ogim_tipo.terreni_ridotti terreni_ridotti
 ,ogim_tipo.aree aree
 ,ogim_tipo.abitativo abitativo
 ,ogim_tipo.commercialiartigianali commercialiartigianali
 ,ogim_tipo.rurali rurali
 ,supporto_servizi_pkg.f_serv_max_prat(ogim_anno.anno
     ,ogim_anno.tipo_tributo
     ,ogim_anno.cod_fiscale
     ,'L'
   )
  ultima_liquidazione
   from (  select sum(ogim.imposta) dovuto
  ,sum(ogim.imposta) - sum(nvl(ogim.imposta_erariale, 0)) dovuto_comunale
  ,sum(nvl(ogim.imposta_erariale, 0)) dovuto_erariale
  ,sum(ogim.imposta_acconto) dovuto_acconto
  ,sum(ogim.imposta_acconto) - sum(ogim.imposta_erariale_acconto) dovuto_comunale_acconto
  ,sum(nvl(ogim.imposta_erariale_acconto, 0)) dovuto_erariale_acconto
  ,ogim.cod_fiscale
  ,ogim.anno
  ,prtr.tipo_tributo
  ,count(ogpr.oggetto) num_oggetti
  ,min(ogco.perc_possesso) || '-' || max(ogco.perc_possesso) min_max_perc_possesso
 from oggetti_imposta ogim
  ,oggetti_pratica ogpr
  ,pratiche_tributo prtr
  ,oggetti_contribuente ogco
   where prtr.pratica = ogpr.pratica
  and ogim.oggetto_pratica = ogpr.oggetto_pratica
  and ogim.flag_calcolo = 'S'
  and ogpr.oggetto_pratica = ogco.oggetto_pratica
  and ogim.tipo_tributo || '' in ('ICI', 'TASI')
  --  AND OGIM.ANNO IN (2014, 2015)
  --  and ogim.anno between 2017 and 2021
  and ogim.anno >= 2016
  and ogim.cod_fiscale = ogco.cod_fiscale
  and (ogco.flag_esclusione is null
 or  nvl(mesi_esclusione, 0) > 0) -- 09/05 Escludiamo esenti per scartare nude proprieta
   group by ogim.cod_fiscale
  ,ogim.anno
  ,prtr.tipo_tributo) ogim_anno
 , -- oggetti imposta dell nno
  (  select ogim.cod_fiscale
  ,ogim.anno
  ,prtr.tipo_tributo
  ,count(ogpr.oggetto) num_fabbr
 from oggetti_imposta ogim
  ,oggetti_pratica ogpr
  ,pratiche_tributo prtr
  ,oggetti ogge
   where prtr.pratica = ogpr.pratica
  and ogim.oggetto_pratica = ogpr.oggetto_pratica
  and ogim.flag_calcolo = 'S'
  and ogpr.oggetto = ogge.oggetto
--  and ogim.anno between 2017 and 2021
  --  AND ogim.anno IN (2014, 2015)  -- da togliere
  and ogim.anno >= 2016
  and ogim.tipo_tributo || '' in ('ICI', 'TASI')
  and nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto) = 3
   group by ogim.cod_fiscale
  ,ogim.anno
  ,prtr.tipo_tributo) ogim_anno_fabb
 , -- fabbricati di tipo 3 per anno
  (  select ogim.cod_fiscale
  ,ogim.anno
  ,prtr.tipo_tributo
  ,count(ogpr.oggetto) num_terr
 from oggetti_imposta ogim
  ,oggetti_pratica ogpr
  ,pratiche_tributo prtr
  ,oggetti ogge
   where prtr.pratica = ogpr.pratica
  and ogim.oggetto_pratica = ogpr.oggetto_pratica
  and ogim.flag_calcolo = 'S'
  and ogpr.oggetto = ogge.oggetto
--  and ogim.anno between 2017 and 2021
  -- AND ogim.anno IN (2014, 2015)  -- da togliere
  and ogim.anno >= 2016
  and ogim.tipo_tributo || '' in ('ICI', 'TASI')
  and nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto) = 1
   group by ogim.cod_fiscale
  ,ogim.anno
  ,prtr.tipo_tributo) ogim_anno_terr
 , -- terreni di tipo 1 per anno
  (  select ogim.cod_fiscale
  ,ogim.anno
  ,prtr.tipo_tributo
  ,count(ogpr.oggetto) num_aree
 from oggetti_imposta ogim
  ,oggetti_pratica ogpr
  ,pratiche_tributo prtr
  ,oggetti ogge
   where prtr.pratica = ogpr.pratica
  and ogim.oggetto_pratica = ogpr.oggetto_pratica
  and ogim.flag_calcolo = 'S'
  and ogpr.oggetto = ogge.oggetto
--  and ogim.anno between 2017 and 2021
  --  AND ogim.anno IN (2014, 2015)  -- da togliere
  and ogim.anno >= 2016
  and ogim.tipo_tributo || '' in ('ICI', 'TASI')
  and nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto) = 2
   group by ogim.cod_fiscale
  ,ogim.anno
  ,prtr.tipo_tributo) ogim_anno_aree
 , -- aree di tipo 2 per anno
  (  select ogim.cod_fiscale
  ,ogim.anno
  ,prtr.tipo_tributo
  , -- count(*)
   sum(decode(substr(nvl(ogpr.categoria_catasto, ogge.categoria_catasto)
     ,1
     ,1
     )
    ,'A', 1
    ,0
    ))
    ab_pr
  ,sum(decode(substr(nvl(ogpr.categoria_catasto, ogge.categoria_catasto)
     ,1
     ,1
     )
    ,'C', 1
    ,0
    ))
    pert
 from oggetti_imposta ogim
  ,oggetti_pratica ogpr
  ,pratiche_tributo prtr
  ,oggetti ogge
   where prtr.pratica = ogpr.pratica
  and ogim.oggetto_pratica = ogpr.oggetto_pratica
  and ogim.flag_calcolo = 'S'
  and ogpr.oggetto = ogge.oggetto
--  and ogim.anno between 2017 and 2021
  --  AND ogim.anno IN (2014, 2015)  -- da togliere
  and ogim.anno >= 2016
  and ogim.tipo_tributo || '' in ('ICI', 'TASI')
  and tipo_aliquota = 2
   group by ogim.cod_fiscale
  ,ogim.anno
  ,prtr.tipo_tributo) ogim_ab_p
 , -- OGGETTI_IMPOSTA ABITAZIONE PRINCIPALE
  (  select ogim.cod_fiscale
  ,ogim.anno
  ,prtr.tipo_tributo
  , -- count(*)
   sum(decode(nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto), 1, 1, 0)
   )
    terreni
  ,sum(decode(nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto), 1, decode(mesi_riduzione, 'S', 1, 0), 0)
   )
    terreni_ridotti
  ,sum(decode(nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto), 3, 1, 0)
   )
    altri_fabbricati
  ,sum(decode((substr(nvl(ogpr.categoria_catasto, ogge.categoria_catasto)
   ,1
   ,1
   ))
    ,'D', 1
    ,0
    ))
    fabb_d
  ,sum(decode(nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto), 2, 1, 0)
   )
    aree
  ,sum(decode((substr(nvl(ogpr.categoria_catasto, ogge.categoria_catasto)
   ,1
   ,2
   ))
    ,'A0', 1
    ,0
    ))
    abitativo
  ,sum(decode((substr(nvl(ogpr.categoria_catasto, ogge.categoria_catasto)
   ,1
   ,3
   ))
    ,'C01', 1
    ,0
    ))
    commercialiartigianali
  ,to_number(null) rurali
 from oggetti_imposta ogim
  ,oggetti_pratica ogpr
  ,pratiche_tributo prtr
  ,oggetti ogge
  ,oggetti_contribuente ogco
   where prtr.pratica = ogpr.pratica
  and ogim.oggetto_pratica = ogpr.oggetto_pratica
  and ogim.flag_calcolo = 'S'
  and ogpr.oggetto = ogge.oggetto
--  and ogim.anno between 2017 and 2021
  --  AND ogim.anno IN (2014, 2015)  -- da togliere
  and ogim.anno >= 2016
  and ogim.tipo_tributo || '' in ('TASI', 'ICI')
  and nvl(tipo_aliquota, 0) != 2
  and ogco.oggetto_pratica = ogpr.oggetto_pratica
   --  and prtr.cod_fiscale='STFRRT52C15A231A'
   group by ogim.cod_fiscale
  ,ogim.anno
  ,prtr.tipo_tributo) ogim_tipo
 , -- OGGETTI_IMPOSTA per tipo
  (  select sum(ogim.imposta) dovuto_tasi
  ,sum(ogim.imposta_acconto) dovuto_tasi_acconto
  ,sum(ogim.imposta_acconto) acconto_tasi
  ,ogim.cod_fiscale cod_fiscale_tasi
  ,ogim.anno anno_tasi
  ,prtr.tipo_tributo tipo_tributo_tasi
  ,count(ogpr.oggetto) num_oggetti
 from oggetti_imposta ogim
  ,oggetti_pratica ogpr
  ,pratiche_tributo prtr
  ,oggetti_contribuente ogco
   where prtr.pratica = ogpr.pratica
  and ogim.oggetto_pratica = ogpr.oggetto_pratica
  and ogim.flag_calcolo = 'S'
  and ogpr.oggetto_pratica = ogco.oggetto_pratica
  and ogim.cod_fiscale = ogco.cod_fiscale
  and ogim.tipo_tributo || '' = 'TASI'
  and ogim.anno >= 2016
--  and ogim.anno between 2017 and 2021
   --   AND OGIM.ANNO IN (2014, 2015)
   group by ogim.cod_fiscale
  ,ogim.anno
  ,prtr.tipo_tributo) ogim_tasi
 , -- dovuto TASI
  contribuenti cont
 ,soggetti sogg
  where cont.ni = sogg.ni
 and ogim_anno.cod_fiscale = cont.cod_fiscale
 and ogim_anno.cod_fiscale = ogim_anno_fabb.cod_fiscale(+)
 and ogim_anno.tipo_tributo = ogim_anno_fabb.tipo_tributo(+)
 and ogim_anno.anno = ogim_anno_fabb.anno(+) -- da togliere
 and ogim_anno.cod_fiscale = ogim_anno_terr.cod_fiscale(+)
 and ogim_anno.tipo_tributo = ogim_anno_terr.tipo_tributo(+)
 and ogim_anno.anno = ogim_anno_terr.anno(+) -- da togliere
 and ogim_anno.cod_fiscale = ogim_anno_aree.cod_fiscale(+)
 and ogim_anno.tipo_tributo = ogim_anno_aree.tipo_tributo(+)
 and ogim_anno.anno = ogim_anno_aree.anno(+) -- da togliere
 and ogim_anno.cod_fiscale = ogim_ab_p.cod_fiscale(+)
 and ogim_anno.anno = ogim_ab_p.anno(+) -- da togliere
 and ogim_anno.tipo_tributo = ogim_ab_p.tipo_tributo(+)
 and ogim_anno.cod_fiscale = ogim_tipo.cod_fiscale(+)
 and ogim_anno.anno = ogim_tipo.anno(+) -- da togliere
 and ogim_anno.tipo_tributo = ogim_tipo.tipo_tributo(+)
 and ogim_anno.cod_fiscale = ogim_tasi.cod_fiscale_tasi(+)
 and ogim_anno.anno = ogim_tasi.anno_tasi(+)
--   and ogim_anno.cod_fiscale='DRCNRC27A14A757K'
;
comment on table SERVIZI_DV is 'SEDV - Servizi DV';

