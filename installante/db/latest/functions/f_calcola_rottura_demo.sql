--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_calcola_rottura_demo stripComments:false runOnChange:true 
 
create or replace function F_CALCOLA_ROTTURA_DEMO
(  p_oggetto_pratica           NUMBER,
   p_oggetto_pratica_rif_ap    NUMBER,
   p_cod_fiscale               VARCHAR2,
   p_flag_ab_principale        VARCHAR2,
   p_anno_rif                  NUMBER,
   p_ravvedimento  IN VARCHAR2)
   RETURN NUMBER
/*************************************************************************
 Function utilizzata in CALCOLO_DETRAZIONI_MOBILI_TASI per stabilire
 un valore di raggruppamento degli immobili.
 Restituisce
 -1 se p_oggetto_pratica_rif punta ad un oggetto valido all'anno
                        e che ha
                        flag_ab_principale = 'S';
 p_oggetto_pratica negli altri casi.
  Rev.    Date         Author      Note
  1       03/07/2015   SC          Creazione
*************************************************************************/
AS
   dep_rottura   NUMBER;
BEGIN
   IF p_flag_ab_principale = 'S'
   THEN
      RETURN -1;
   END IF;
   IF p_oggetto_pratica_rif_ap IS NOT NULL
   THEN
      BEGIN
         SELECT DECODE (flag_ab_principale, 'S', -1, ogpr.oggetto_pratica)
           INTO dep_rottura
           FROM oggetti_pratica ogpr,
                oggetti_contribuente ogco,
                pratiche_tributo prtr
          WHERE     ogpr.oggetto_pratica = p_oggetto_pratica_rif_ap
                AND ogpr.oggetto_pratica = ogco.oggetto_pratica
                AND ogco.cod_fiscale = p_cod_fiscale
                AND prtr.pratica = ogpr.pratica
                AND ogco.anno || ogco.tipo_rapporto || 'S' =
                       (SELECT MAX (
                                     b.anno
                                  || b.tipo_rapporto
                                  || b.flag_possesso)
                          FROM pratiche_tributo c,
                               oggetti_contribuente b,
                               oggetti_pratica a
                         WHERE     (       c.data_notifica IS NOT NULL
                                       AND c.tipo_pratica || '' = 'A'
                                       AND NVL (c.stato_accertamento, 'D') =
                                              'D'
                                       AND NVL (c.flag_denuncia, ' ') = 'S'
                                       AND c.anno < p_anno_rif
                                    OR (    c.data_notifica IS NULL
                                        AND c.tipo_pratica || '' = 'D'))
                               AND c.anno <= p_anno_rif
                               AND c.tipo_tributo || '' = prtr.tipo_tributo
                               AND c.pratica = a.pratica
                               AND a.oggetto_pratica = b.oggetto_pratica
                               AND a.oggetto = ogpr.oggetto
                               AND b.tipo_rapporto IN ('A', 'C', 'D', 'E')
                               AND b.cod_fiscale = ogco.cod_fiscale)
                and decode(ogco.anno,p_anno_rif,nvl(ogco.mesi_possesso,12),12) >= 0
                and decode(ogco.anno
                  ,p_anno_rif,decode(ogco.flag_esclusione
                                    ,'S',nvl(ogco.mesi_esclusione,nvl(ogco.mesi_possesso,12))
                                        ,nvl(ogco.mesi_esclusione,0)
                                    )
                             ,decode(ogco.flag_esclusione,'S',12,0)
                 )                     <=
            decode(ogco.anno,p_anno_rif,nvl(ogco.mesi_possesso,12),12)
                and ogco.flag_possesso       = 'S'
                and p_ravvedimento           = 'N'
         UNION
         SELECT DECODE (flag_ab_principale, 'S', -1, ogpr.oggetto_pratica)
         --DECODE(OGCO.DETRAZIONE, NULL, ogpr.oggetto_pratica, -1)
           FROM pratiche_tributo prtr,
                oggetti_pratica ogpr,
                oggetti_contribuente ogco
          WHERE     ogpr.oggetto_pratica = p_oggetto_pratica_rif_ap
                AND (   (    prtr.tipo_pratica || '' = 'D'
                         AND ogco.flag_possesso IS NULL
                         AND p_ravvedimento = 'N')
                     OR (    prtr.tipo_pratica || '' = 'V'
                         AND p_ravvedimento = 'S'
                         AND NOT EXISTS
                                (SELECT 'x'
                                   FROM sanzioni_pratica sapr
                                  WHERE sapr.pratica = prtr.pratica)))
                AND NVL (prtr.stato_accertamento, 'D') = 'D'
                AND prtr.pratica = ogpr.pratica
                AND ogpr.oggetto_pratica = ogco.oggetto_pratica
                AND ogco.anno = p_anno_rif
                AND DECODE (
                       ogco.anno,
                       p_anno_rif, DECODE (
                                      ogco.flag_esclusione,
                                      'S', NVL (ogco.mesi_esclusione,
                                                NVL (ogco.mesi_possesso, 12)),
                                      NVL (ogco.mesi_esclusione, 0)),
                       DECODE (ogco.flag_esclusione, 'S', 12, 0)) <=
                       DECODE (ogco.anno,
                               p_anno_rif, NVL (ogco.mesi_possesso, 12),
                               12)
                AND DECODE (ogco.anno,
                            p_anno_rif, NVL (ogco.mesi_possesso, 12),
                            12) >= 0
                AND ogco.cod_fiscale = p_cod_fiscale;
      EXCEPTION
         WHEN OTHERS
         THEN
            dep_rottura := p_oggetto_pratica;
      END;
      RETURN dep_rottura;
   ELSE
      RETURN p_oggetto_pratica;
   END IF;
END;
/* End Function: F_CALCOLA_ROTTURA_DEMO */
/

