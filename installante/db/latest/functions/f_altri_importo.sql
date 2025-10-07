--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_altri_importo stripComments:false runOnChange:true 
 
create or replace function F_ALTRI_IMPORTO
(  a_pratica           NUMBER,
   a_oggetto_pratica   NUMBER,
   a_richiesta         VARCHAR2,
   a_anno              NUMBER,
   a_tipo              VARCHAR2
)
   RETURN NUMBER
IS
   dep_ret                NUMBER := 0;
   w_imposta_altri_com    NUMBER := 0;
   w_imposta_altri_sta    NUMBER := 0;
   w_imposta_fabb_d_com   NUMBER := 0;
   w_imposta_fabb_d_sta   NUMBER := 0;
   w_se_anno_fabb_d       NUMBER;
BEGIN
   IF a_anno >= 2013
   THEN
      w_se_anno_fabb_d := 1;
   ELSE
      w_se_anno_fabb_d := 0;
   END IF;
   BEGIN
      SELECT SUM (DECODE (ogim.tipo_aliquota,
                          2, 0,
                          DECODE (NVL (ogpr.tipo_oggetto, ogge.tipo_oggetto),
                                  1, 0,
                                  2, 0,
                                  decode (nvl(aliq.flag_fabbricati_merce,'N'),
                                          'S', 0,
                                          DECODE (ogim.aliquota_erariale,
                                                  NULL, 0,
                                                  NVL (DECODE (a_tipo,
                                                               'RENDITA', ogim.imposta,
                                                               ogim.imposta_dovuta
                                                              ),
                                                       0
                                                      )
                                                - NVL (DECODE (a_tipo,
                                                               'RENDITA', ogim.imposta_erariale,
                                                               ogim.imposta_erariale_dovuta
                                                              ),
                                                       0
                                                      )
                                                 )
                                         )
                                 )
                         )
                 ) imposta_altri_com,
             SUM (DECODE (ogim.tipo_aliquota,
                          2, 0,
                          DECODE (NVL (ogpr.tipo_oggetto, ogge.tipo_oggetto),
                                  1, 0,
                                  2, 0,
                                  decode (nvl(aliq.flag_fabbricati_merce,'N'),
                                          'S', 0,
                                          DECODE (ogim.aliquota_erariale,
                                                  NULL, 0,
                                                  NVL (DECODE (a_tipo,
                                                                 'RENDITA', ogim.imposta_erariale,
                                                                 ogim.imposta_erariale_dovuta
                                                                ),
                                                             0)
                                                 )
                                         )
                                 )
                         )
                 ) imposta_altri_sta,
             SUM(DECODE(ogim.tipo_aliquota,
                        9, DECODE(NVL(ogpr.tipo_oggetto, ogge.tipo_oggetto),
                                  1, 0,
                                  2, 0,
                                  DECODE(prtr.tipo_tributo,
                                         'TASI',0,
                                         decode(SUBSTR(ogpr.categoria_catasto, 1, 1),
                                                'D', DECODE(w_se_anno_fabb_d,
                                                            1,NVL(DECODE(a_tipo,
                                                                         'RENDITA',ogim.imposta,
                                                                                   ogim.imposta_dovuta
                                                                        ),
                                                                  0
                                                                 )
                                                            - NVL(DECODE(a_tipo,
                                                                         'RENDITA',ogim.imposta_erariale,
                                                                                   ogim.imposta_erariale_dovuta
                                                                        ),
                                                                  0
                                                                  ),
                                                              0
                                                           ),
                                                     0
                                               )
                                        )
                                   ),
                           0
                        )
                ) imposta_fabb_d_com,
             SUM(DECODE(ogim.tipo_aliquota,
                        9, DECODE(NVL(ogpr.tipo_oggetto, ogge.tipo_oggetto),
                                  1, 0,
                                  2, 0,
                                  DECODE(prtr.tipo_tributo,
                                         'TASI',0,
                                         DECODE(SUBSTR(ogpr.categoria_catasto, 1, 1),
                                               'D',DECODE(w_se_anno_fabb_d,
                                                          1, NVL(DECODE(a_tipo,
                                                                        'RENDITA',ogim.imposta_erariale,
                                                                                  ogim.imposta_erariale_dovuta
                                                                       ),
                                                                 0
                                                                ),
                                                          0
                                                         ),
                                                   0
                                               )
                                        )
                                 ),
                           0
                       )
                ) imposta_fabb_d_sta
        INTO w_imposta_altri_com,
             w_imposta_altri_sta,
             w_imposta_fabb_d_com,
             w_imposta_fabb_d_sta
        FROM oggetti_imposta ogim,
             oggetti_pratica ogpr,
             oggetti ogge,
             pratiche_tributo prtr,
             aliquote aliq
       WHERE ogpr.oggetto_pratica = ogim.oggetto_pratica
         AND ogpr.oggetto = ogge.oggetto
         and ogpr.pratica = prtr.pratica
         -- (VD - 29/06/2021): Aggiunta outer join su tabella ALIQUOTE
         --                    per gestire la presenza di OGGETTI_OGIM
         --                    (dove il tipo aliquota di OGGETTI_IMPOSTA
         --                    e' nullo
         and ogim.tipo_tributo = aliq.tipo_tributo (+)
         and ogim.anno = aliq.anno (+)
         and ogim.tipo_aliquota = aliq.tipo_aliquota (+)
         AND ogpr.pratica = a_pratica
         AND ogpr.oggetto_pratica = a_oggetto_pratica;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         w_imposta_altri_com := 0;
         w_imposta_altri_sta := 0;
         w_imposta_fabb_d_com := 0;
         w_imposta_fabb_d_sta := 0;
   END;
   w_imposta_altri_com := w_imposta_altri_com - w_imposta_fabb_d_com;
   w_imposta_altri_sta := w_imposta_altri_sta - w_imposta_fabb_d_sta;
   IF a_richiesta = 'STATO'
   THEN
      dep_ret := w_imposta_altri_sta;
   ELSE
      dep_ret := w_imposta_altri_com;
   END IF;
   RETURN dep_ret;
END;
/* End Function: F_ALTRI_IMPORTO */
/

