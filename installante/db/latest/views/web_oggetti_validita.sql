--liquibase formatted sql 
--changeset abrandolini:20250326_152401_web_oggetti_validita stripComments:false runOnChange:true 
 
CREATE OR REPLACE FORCE VIEW WEB_OGGETTI_VALIDITA AS
SELECT ogco.cod_fiscale,
 ogco.oggetto_pratica,
 ogpr.oggetto,
 ogco.flag_ab_principale,
 NVL (ogpr.oggetto_pratica_rif, ogpr.oggetto_pratica)
 oggetto_pratica_rif,
 ogco.data_decorrenza dal,
 DECODE (
 NVL (ogpr.tipo_occupazione, 'P'),
 'T', ogco.data_cessazione,
 NVL (
 ogco.data_cessazione,
 DECODE (
    prtr.tipo_pratica,
    'A', NVL (
   f_fine_validita (
   NVL (ogpr.oggetto_pratica_rif,
     ogpr.oggetto_pratica),
   ogco.cod_fiscale,
   ogco.data_decorrenza,
   '%'),
   f_cessazione_accertamento (ogco.cod_fiscale,
      ogpr.oggetto,
      ogco.data_decorrenza,
      prtr.tipo_tributo)),
    f_fine_validita (
    NVL (ogpr.oggetto_pratica_rif, ogpr.oggetto_pratica),
    ogco.cod_fiscale,
    ogco.data_decorrenza,
    '%'))))
 al,
 prtr.pratica,
 prtr.numero,
 prtr.data,
 prtr.anno,
 prtr.tipo_tributo,
 prtr.tipo_pratica,
 prtr.tipo_evento,
 NVL (ogpr.tipo_occupazione, 'P') tipo_occupazione,
 prtr.stato_accertamento,
 prtr.flag_denuncia,
 OGCO.PERC_POSSESSO,
 OGCO.MESI_POSSESSO,
 OGCO.MESI_ESCLUSIONE,
 OGCO.MESI_RIDUZIONE,
 OGCO.FLAG_POSSESSO,
 OGCO.FLAG_ESCLUSIONE,
 OGCO.FLAG_RIDUZIONE,
 OGPR.VALORE,
 OGPR.FLAG_PROVVISORIO,
 OGPR.TIPO_OGGETTO,
 OGCO.DETRAZIONE,
 OGPR.OGGETTO_PRATICA_RIF_AP
  FROM oggetti_contribuente ogco,
 oggetti_pratica ogpr,
 pratiche_tributo prtr
 WHERE  ogpr.oggetto_pratica = ogco.oggetto_pratica
 AND prtr.pratica = ogpr.pratica
 AND DECODE (prtr.tipo_pratica, 'A', prtr.flag_denuncia, 'S') = 'S'
 AND DECODE (
  prtr.tipo_pratica,
  'A', DECODE (
    prtr.flag_adesione,
    'S', TO_DATE ('01011900', 'ddmmyyyy'),
   NVL (prtr.data_notifica,
  TO_DATE ('31122999', 'ddmmyyyy'))
    + 60),
  TO_DATE ('01011900', 'ddmmyyyy')) < SYSDATE
 AND prtr.tipo_pratica IN ('D', 'A')
 AND NVL (prtr.stato_accertamento, 'D') = 'D'
 AND DECODE (
  prtr.tipo_pratica,
  'D', NVL (ogco.data_decorrenza,
   TO_DATE ('01011900', 'ddmmyyyy')),
  NVL (ogco.data_decorrenza, ogco.data_cessazione))
  IS NOT NULL
 AND prtr.tipo_evento <> 'C'
 AND prtr.flag_annullamento IS NULL
 AND NOT EXISTS
   (SELECT 1
   FROM oggetti_contribuente ogc1,
  oggetti_pratica ogp1,
  pratiche_tributo prt1
  WHERE  ogp1.oggetto_pratica = ogc1.oggetto_pratica
  AND prt1.pratica = ogp1.pratica
  AND DECODE (prt1.tipo_pratica,
     'A', prt1.flag_denuncia,
     'S') = 'S'
  AND DECODE (
   prt1.tipo_pratica,
   'D', NVL (
     ogc1.data_decorrenza,
     TO_DATE ('01011900', 'ddmmyyyy')),
   NVL (ogc1.data_decorrenza,
     ogc1.data_cessazione))
   IS NOT NULL
  AND prt1.tipo_pratica IN ('D', 'A')
  AND NVL (prt1.stato_accertamento, 'D') = 'D'
  AND DECODE (
   prt1.tipo_pratica,
   'A', DECODE (
     prt1.flag_adesione,
     'S', TO_DATE ('01011900',
    'ddmmyyyy'),
    NVL (
    prt1.data_notifica,
    TO_DATE ('31122999',
    'ddmmyyyy'))
     + 60),
   TO_DATE ('01011900', 'ddmmyyyy')) <
   SYSDATE
  AND prt1.tipo_evento <> 'C'
  AND prt1.flag_annullamento IS NULL
  AND ogc1.cod_fiscale = ogco.cod_fiscale
  AND prt1.tipo_tributo || '' = prtr.tipo_tributo
  AND NVL (ogp1.oggetto_pratica_rif,
     ogp1.oggetto_pratica) =
   NVL (ogpr.oggetto_pratica_rif,
     ogpr.oggetto_pratica)
  AND NVL (ogc1.data_decorrenza,
     TO_DATE ('01011900', 'ddmmyyyy')) =
   NVL (ogco.data_decorrenza,
     TO_DATE ('01011900', 'ddmmyyyy'))
  AND (   NVL (prt1.data,
   TO_DATE ('01011900', 'ddmmyyyy')) >
    NVL (
    prtr.data,
    TO_DATE ('01011900', 'ddmmyyyy'))
    OR  NVL (
     prt1.data,
     TO_DATE ('01011900', 'ddmmyyyy')) =
     NVL (
     prtr.data,
     TO_DATE ('01011900',
     'ddmmyyyy'))
    AND prt1.pratica > prtr.pratica));
comment on table WEB_OGGETTI_VALIDITA is 'WEB_OGGETTI_VALIDITA';

