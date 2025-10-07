--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_aliquota_mobile stripComments:false runOnChange:true 
 
create or replace function F_ALIQUOTA_MOBILE
/*************************************************************************
La funzione restituisce, in presenza di dati nella tabella
ALIQUOTE_MOBILI, l'aliquota da applicare in base allo scaglione
relativo alla rendita catastale di abitazione principale + pertinenze .
a_ogpr_rottura viene calcolato dall'esterno sulla base del flag_ab_principale
e delle relazioni tra oggetti (con F_CALCOLA_ROTTURA_DEMO).
Il cursore principale estrare tutti gli oggetto con lo stesso oggetto di rottura,
e per quelli fa la somma delle rendite medie e calcola quindi l'aliquota
corrispondente.
Si escludono gli 'A01','A08','A09'.
Versione  Data              Autore    Descrizione
0         25/05/2015        VD        Prima emissione
1         13/07/2015        SC        Il calcolo va fatto sulla
                                      singola abitazione principale e sue
                                      pertinenze.
*************************************************************************/
                                             (
   a_tipo_tributo         VARCHAR2,
   a_cod_fiscale          VARCHAR2,
   a_ogpr_rottura         NUMBER,
   a_anno_rif             NUMBER,
   a_ravvedimento         VARCHAR2)
   RETURN NUMBER
IS
   w_aliquota                     NUMBER;
   w_flag_pertinenze              VARCHAR2 (1);
   w_conta_rif_ap_ab_principale   NUMBER;
   w_rif_ap_ab_principale         VARCHAR2 (1);
   w_rendita                      NUMBER;
   w_rendita_totale               NUMBER;
   w_flag_possesso_prec           VARCHAR2 (1);
   w_mesi_possesso                NUMBER;
   w_mesi_possesso_1sem           NUMBER;
   w_mesi_esclusione              NUMBER;
   w_data_inizio_possesso         DATE;
   w_data_fine_possesso           DATE;
   w_data_inizio_possesso_1s      DATE;
   w_data_fine_possesso_1s        DATE;
   w_valore                       NUMBER;
   w_valore_1s                    NUMBER;
   w_esiste_det_ogco              VARCHAR2 (1);
   CURSOR sel_ogco(p_ogpr_rottura number)
   IS
      SELECT ogpr.tipo_oggetto,
             ogpr.pratica pratica_ogpr,
             ogpr.oggetto oggetto_ogpr,
             f_dato_riog (ogco.cod_fiscale,
                          ogco.oggetto_pratica,
                          a_anno_rif,
                          'CA')
                categoria_catasto_ogpr,
             ogpr.oggetto_pratica oggetto_pratica_ogpr,
             ogco.anno anno_ogco,
             ogco.flag_possesso,
             DECODE (ogco.anno, a_anno_rif, NVL (ogco.mesi_possesso, 12), 12)
                mesi_possesso,
             DECODE (ogco.anno, a_anno_rif, ogco.mesi_possesso_1sem, 6)
                mesi_possesso_1sem,
             DECODE (
                ogco.anno,
                a_anno_rif, DECODE (
                               ogco.flag_esclusione,
                               'S', NVL (ogco.mesi_esclusione,
                                         NVL (ogco.mesi_possesso, 12)),
                               NVL (ogco.mesi_esclusione, 0)),
                DECODE (ogco.flag_esclusione, 'S', 12, 0))
                mesi_esclusione,
             ogco.flag_ab_principale flag_ab_principale,
             f_valore (
                NVL (f_valore_d (ogpr.oggetto_pratica, a_anno_rif),
                     ogpr.valore),
                ogpr.tipo_oggetto,
                prtr.anno,
                a_anno_rif,
                NVL (ogpr.categoria_catasto, ogge.categoria_catasto),
                prtr.tipo_pratica,
                ogpr.FLAG_VALORE_RIVALUTATO)
                valore,
             ogco.detrazione detrazione_ogco,
             DECODE (
                ogpr.tipo_oggetto,
                1, NVL (molt.moltiplicatore, 1),
                3, DECODE (
                         NVL (ogpr.imm_storico, 'N')
                      || TO_CHAR (SIGN (2012 - a_anno_rif)),
                      'S1', 100,
                      NVL (molt.moltiplicatore, 1)),
                1)
                moltiplicatore,
             ogpr.imm_storico,
             ogpr.oggetto_pratica_rif_ap,
             rire.aliquota aliquota_rivalutazione,
             prtr.anno anno_titr
        FROM rivalutazioni_rendita rire,
             moltiplicatori molt,
             oggetti ogge,
             pratiche_tributo prtr,
             oggetti_pratica ogpr,
             oggetti_contribuente ogco
       WHERE     rire.anno(+) = a_anno_rif
             AND rire.tipo_oggetto(+) = ogpr.tipo_oggetto
             AND molt.anno(+) = a_anno_rif
             AND molt.categoria_catasto(+) =
                    f_dato_riog (ogco.cod_fiscale,
                                 ogco.oggetto_pratica,
                                 a_anno_rif,
                                 'CA')
             AND ogco.anno || ogco.tipo_rapporto || 'S' =
                    (SELECT MAX (
                               b.anno || b.tipo_rapporto || b.flag_possesso)
                       FROM pratiche_tributo c,
                            oggetti_contribuente b,
                            oggetti_pratica a
                      WHERE     (       c.data_notifica IS NOT NULL
                                    AND c.tipo_pratica || '' = 'A'
                                    AND NVL (c.stato_accertamento, 'D') = 'D'
                                    AND NVL (c.flag_denuncia, ' ') = 'S'
                                    AND c.anno < a_anno_rif
                                 OR (    c.data_notifica IS NULL
                                     AND c.tipo_pratica || '' = 'D'))
                            AND c.anno <= a_anno_rif
                            AND c.tipo_tributo || '' = prtr.tipo_tributo
                            AND c.pratica = a.pratica
                            AND a.oggetto_pratica = b.oggetto_pratica
                            AND a.oggetto = ogpr.oggetto
                            AND b.tipo_rapporto IN ('A',
                                                    'C',
                                                    'D',
                                                    'E')
                            AND b.cod_fiscale = ogco.cod_fiscale)
             AND ogge.oggetto = ogpr.oggetto
             AND prtr.tipo_tributo || '' = 'TASI'
             AND NVL (prtr.stato_accertamento, 'D') = 'D'
             AND prtr.pratica = ogpr.pratica
             AND ogpr.oggetto_pratica = ogco.oggetto_pratica
             AND DECODE (ogco.anno,
                         a_anno_rif, NVL (ogco.mesi_possesso, 12),
                         12) >= 0
             AND DECODE (
                    ogco.anno,
                    a_anno_rif, DECODE (
                                   ogco.flag_esclusione,
                                   'S', NVL (ogco.mesi_esclusione,
                                             NVL (ogco.mesi_possesso, 12)),
                                   NVL (ogco.mesi_esclusione, 0)),
                    DECODE (ogco.flag_esclusione, 'S', 12, 0)) <=
                    DECODE (ogco.anno,
                            a_anno_rif, NVL (ogco.mesi_possesso, 12),
                            12)
             AND ogco.flag_possesso = 'S'
             AND ogco.cod_fiscale = a_cod_fiscale
             AND a_ravvedimento = 'N'
             AND f_dato_riog (ogco.cod_fiscale,
                              ogco.oggetto_pratica,
                              a_anno_rif,
                              'CA') NOT IN ('A01', 'A08', 'A09')
            AND decode(ogco.flag_ab_principale,'S',-1,F_CALCOLA_ROTTURA_DEMO (ogco.oggetto_pratica,
                            ogpr.oggetto_pratica_rif_ap,
                            ogco.cod_fiscale,
                            ogco.flag_ab_principale,
                            a_anno_rif,
                            a_ravvedimento)) = p_ogpr_rottura
      UNION ALL
      SELECT ogpr.tipo_oggetto,
             ogpr.pratica pratica_ogpr,
             ogpr.oggetto oggetto_ogpr,
             f_dato_riog (ogco.cod_fiscale,
                          ogco.oggetto_pratica,
                          a_anno_rif,
                          'CA')
                categoria_catasto_ogpr,
             ogpr.oggetto_pratica oggetto_pratica_ogpr,
             ogco.anno anno_ogco,
             ogco.flag_possesso,
             DECODE (ogco.anno, a_anno_rif, NVL (ogco.mesi_possesso, 12), 12)
                mesi_possesso,
             DECODE (ogco.anno, a_anno_rif, ogco.mesi_possesso_1sem, 6)
                mesi_possesso_1sem,
             DECODE (
                ogco.anno,
                a_anno_rif, DECODE (
                               ogco.flag_esclusione,
                               'S', NVL (ogco.mesi_esclusione,
                                         NVL (ogco.mesi_possesso, 12)),
                               NVL (ogco.mesi_esclusione, 0)),
                DECODE (ogco.flag_esclusione, 'S', 12, 0)),
             ogco.flag_ab_principale flag_ab_principale,
             f_valore (ogpr.valore,
                       ogpr.tipo_oggetto,
                       prtr.anno,
                       a_anno_rif,
                       NVL (ogpr.categoria_catasto, ogge.categoria_catasto),
                       prtr.tipo_pratica,
                       ogpr.flag_valore_rivalutato)
                valore,
             ogco.detrazione detrazione_ogco,
             DECODE (
                ogpr.tipo_oggetto,
                1, NVL (molt.moltiplicatore, 1),
                3, DECODE (
                         NVL (ogpr.imm_storico, 'N')
                      || TO_CHAR (SIGN (2012 - a_anno_rif)),
                      'S1', 100,
                      NVL (molt.moltiplicatore, 1)),
                1)
                moltiplicatore,
             ogpr.imm_storico,
             ogpr.oggetto_pratica_rif_ap,
             rire.aliquota aliquota_rivalutazione,
             prtr.anno
        FROM rivalutazioni_rendita rire,
             moltiplicatori molt,
             oggetti ogge,
             pratiche_tributo prtr,
             oggetti_pratica ogpr,
             oggetti_contribuente ogco
       WHERE     rire.anno(+) = a_anno_rif
             AND rire.tipo_oggetto(+) = ogpr.tipo_oggetto
             AND molt.anno(+) = a_anno_rif
             AND molt.categoria_catasto(+) =
                    f_dato_riog (ogco.cod_fiscale,
                                 ogco.oggetto_pratica,
                                 a_anno_rif,
                                 'CA')
             AND ogge.oggetto = ogpr.oggetto
             AND (   (    prtr.tipo_pratica || '' = 'D'
                      AND ogco.flag_possesso IS NULL
                      AND a_ravvedimento = 'N')
                  OR (    prtr.tipo_pratica || '' = 'V'
                      AND a_ravvedimento = 'S'
                      AND NOT EXISTS
                             (SELECT 'x'
                                FROM sanzioni_pratica sapr
                               WHERE sapr.pratica = prtr.pratica)))
             AND prtr.tipo_tributo || '' = 'TASI'
             AND NVL (prtr.stato_accertamento, 'D') = 'D'
             AND prtr.pratica = ogpr.pratica
             AND ogpr.oggetto_pratica = ogco.oggetto_pratica
             AND ogco.anno = a_anno_rif
             AND DECODE (
                    ogco.anno,
                    a_anno_rif, DECODE (
                                   ogco.flag_esclusione,
                                   'S', NVL (ogco.mesi_esclusione,
                                             NVL (ogco.mesi_possesso, 12)),
                                   NVL (ogco.mesi_esclusione, 0)),
                    DECODE (ogco.flag_esclusione, 'S', 12, 0)) <=
                    DECODE (ogco.anno,
                            a_anno_rif, NVL (ogco.mesi_possesso, 12),
                            12)
             AND DECODE (ogco.anno,
                         a_anno_rif, NVL (ogco.mesi_possesso, 12),
                         12) >= 0
             AND ogco.cod_fiscale = a_cod_fiscale
             AND f_dato_riog (ogco.cod_fiscale,
                              ogco.oggetto_pratica,
                              a_anno_rif,
                              'CA') NOT IN ('A01', 'A08', 'A09')
            AND decode(ogco.flag_ab_principale,'S',-1,F_CALCOLA_ROTTURA_DEMO (ogco.oggetto_pratica,
                            ogpr.oggetto_pratica_rif_ap,
                            ogco.cod_fiscale,
                            ogco.flag_ab_principale,
                            a_anno_rif,
                            a_ravvedimento)) = p_ogpr_rottura
      ORDER BY 7;
--
BEGIN
   --
   -- Selezione flag pertinenze
   --
   BEGIN
      SELECT flag_pertinenze
        INTO w_flag_pertinenze
        FROM aliquote
       WHERE     flag_ab_principale = 'S'
             AND tipo_tributo = 'TASI'
             AND anno = a_anno_rif;
   EXCEPTION
      WHEN NO_DATA_FOUND OR TOO_MANY_ROWS
      THEN
         w_flag_pertinenze := 'N';
   END;
   --VECCHIO
   FOR rec_ogco IN sel_ogco(a_ogpr_rottura)
   LOOP
      IF rec_ogco.tipo_oggetto = 3
      THEN
         BEGIN
            SELECT detraz.det
              INTO w_esiste_det_ogco
              FROM (SELECT 'S' det
                      FROM detrazioni_ogco deog
                     WHERE     deog.cod_fiscale = a_cod_fiscale
                           AND deog.oggetto_pratica =
                                  rec_ogco.oggetto_pratica_ogpr
                           AND deog.anno = a_anno_rif
                           AND deog.tipo_tributo = a_tipo_tributo
                           AND NOT EXISTS
                                      (SELECT 'S'
                                         FROM aliquote_ogco alog
                                        WHERE     alog.cod_fiscale =
                                                     a_cod_fiscale
                                              AND tipo_tributo =
                                                     a_tipo_tributo
                                              AND alog.oggetto_pratica =
                                                     rec_ogco.oggetto_pratica_ogpr
                                              AND a_anno_rif BETWEEN TO_NUMBER (
                                                                        TO_CHAR (
                                                                           alog.dal,
                                                                           'yyyy'))
                                                                 AND TO_NUMBER (
                                                                        TO_CHAR (
                                                                           alog.al,
                                                                           'yyyy')))
                    UNION
                    SELECT 'S'
                      FROM detrazioni_ogco deog2
                     WHERE     deog2.cod_fiscale = a_cod_fiscale
                           AND deog2.oggetto_pratica =
                                  rec_ogco.oggetto_pratica_rif_ap
                           AND deog2.anno = a_anno_rif
                           AND deog2.tipo_tributo = a_tipo_tributo
                           AND f_dato_riog (deog2.cod_fiscale,
                                            deog2.oggetto_pratica,
                                            a_anno_rif,
                                            'CA') NOT IN ('A01', 'A08', 'A09')
                           AND NOT EXISTS
                                      (SELECT 'S'
                                         FROM aliquote_ogco alog
                                        WHERE     alog.cod_fiscale =
                                                     a_cod_fiscale
                                              AND tipo_tributo =
                                                     a_tipo_tributo
                                              AND alog.oggetto_pratica =
                                                     deog2.oggetto_pratica
                                              AND a_anno_rif BETWEEN TO_NUMBER (
                                                                        TO_CHAR (
                                                                           alog.dal,
                                                                           'yyyy'))
                                                                 AND TO_NUMBER (
                                                                        TO_CHAR (
                                                                           alog.al,
                                                                           'yyyy'))))
                   detraz;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               w_esiste_det_ogco := 'N';
         END;
      END IF;
      -- Verifico se l'ogpr a cui la pertinenza è collegata è abitazione principale
      IF     rec_ogco.tipo_oggetto = 3
         AND rec_ogco.categoria_catasto_ogpr LIKE 'C%'
         AND rec_ogco.oggetto_pratica_rif_ap IS NOT NULL
      THEN
         BEGIN
            SELECT COUNT (1)
              INTO w_conta_rif_ap_ab_principale
              FROM oggetti_pratica ogpr, oggetti_contribuente ogco
             WHERE     ogpr.oggetto_pratica = ogco.oggetto_pratica
                   AND ogpr.oggetto_pratica = rec_ogco.oggetto_pratica_rif_ap
                   AND f_dato_riog (ogco.cod_fiscale,
                                    ogco.oggetto_pratica,
                                    a_anno_rif,
                                    'CA') NOT IN ('A01', 'A08', 'A09')
                   AND (   ogco.flag_ab_principale = 'S'
                        OR     ogco.detrazione IS NOT NULL
                           AND ogco.anno = a_anno_rif);
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               w_conta_rif_ap_ab_principale := 0;
         END;
         IF w_conta_rif_ap_ab_principale > 0
         THEN
            w_rif_ap_ab_principale := 'S';
         ELSE
            w_rif_ap_ab_principale := 'N';
         END IF;
      ELSE
         w_rif_ap_ab_principale := 'N';
      END IF;
      --
      IF     rec_ogco.tipo_oggetto IN (3, 55)
         AND (   rec_ogco.flag_ab_principale = 'S'
              OR rec_ogco.detrazione_ogco IS NOT NULL
              OR w_esiste_det_ogco = 'S'
              OR w_rif_ap_ab_principale = 'S' -- Serve per gestire le pertinenze con pertinenza_di
                                             )
         AND (   w_flag_pertinenze = 'S'
              OR (    w_flag_pertinenze IS NULL
                  AND rec_ogco.categoria_catasto_ogpr LIKE 'A%'))
      THEN
         IF     rec_ogco.anno_ogco = a_anno_rif
            AND rec_ogco.flag_possesso IS NULL
         THEN
            BEGIN
                 SELECT LTRIM (MAX (NVL (ogco.flag_possesso, ' ')))
                   INTO w_flag_possesso_prec
                   FROM oggetti_contribuente ogco,
                        oggetti_pratica ogpr,
                        pratiche_tributo prtr
                  WHERE     ogco.cod_fiscale = a_cod_fiscale
                        AND ogpr.oggetto = rec_ogco.oggetto_ogpr
                        AND ogpr.oggetto_pratica = ogco.oggetto_pratica
                        AND prtr.pratica = ogpr.pratica
                        AND prtr.tipo_tributo || '' = 'TASI'
                        AND prtr.anno < rec_ogco.anno_ogco
                        AND    ogco.anno
                            || ogco.tipo_rapporto
                            || NVL (ogco.flag_possesso, 'N') =
                               (SELECT MAX (
                                             b.anno
                                          || b.tipo_rapporto
                                          || NVL (b.flag_possesso, 'N'))
                                  FROM pratiche_tributo c,
                                       oggetti_contribuente b,
                                       oggetti_pratica a
                                 WHERE     (       c.data_notifica IS NOT NULL
                                               AND c.tipo_pratica || '' = 'A'
                                               AND NVL (c.stato_accertamento,
                                                        'D') = 'D'
                                               AND NVL (c.flag_denuncia, ' ') =
                                                      'S'
                                            OR     c.data_notifica IS NULL
                                               AND c.tipo_pratica || '' = 'D')
                                       AND c.pratica = a.pratica
                                       AND a.oggetto_pratica =
                                              b.oggetto_pratica
                                       AND c.tipo_tributo || '' = 'TASI'
                                       AND NVL (c.stato_accertamento, 'D') =
                                              'D'
                                       AND c.anno < rec_ogco.anno_ogco
                                       AND b.cod_fiscale = ogco.cod_fiscale
                                       AND a.oggetto = rec_ogco.oggetto_ogpr)
               GROUP BY rec_ogco.oggetto_ogpr;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  w_flag_possesso_prec := NULL;
            END;
         ELSE
            w_flag_possesso_prec := NULL;
         END IF;
         --
         -- La determinazione dei mesi di possesso viene calcolata come per l'ICI
         -- e il valore viene determinato con la procedure CALCOLO_RIOG_MULTIPLO
         --
         w_mesi_possesso := NVL (rec_ogco.mesi_possesso, 0);
         w_mesi_possesso_1sem := NVL (rec_ogco.mesi_possesso_1sem, 0);
         w_mesi_esclusione := NVL (rec_ogco.mesi_esclusione, 0);
         determina_mesi_possesso_ici (
            rec_ogco.flag_possesso,
            w_flag_possesso_prec,
            a_anno_rif,
            w_mesi_possesso - NVL (w_mesi_esclusione, 0),
            w_mesi_possesso_1sem,
            w_data_inizio_possesso,
            w_data_fine_possesso,
            w_data_inizio_possesso_1s,
            w_data_fine_possesso_1s);
         --
         BEGIN
            CALCOLO_RIOG_MULTIPLO (rec_ogco.oggetto_ogpr,
                                   rec_ogco.valore,
                                   w_data_inizio_possesso,
                                   w_data_fine_possesso,
                                   w_data_inizio_possesso_1s,
                                   w_data_fine_possesso_1s,
                                   rec_ogco.moltiplicatore,
                                   rec_ogco.aliquota_rivalutazione,
                                   rec_ogco.tipo_oggetto,
                                   rec_ogco.anno_titr,
                                   a_anno_rif,
                                   rec_ogco.imm_storico,
                                   w_valore,
                                   w_valore_1s);
DBMS_OUTPUT.PUT_LINE('VALORE RIOG MULTIPLO '||w_valore) ;
DBMS_OUTPUT.PUT_LINE('RENDITA RIOG MULTIPLO '||NVL (f_rendita (w_valore,
                                 rec_ogco.tipo_oggetto,
                                 a_anno_rif,
                                 rec_ogco.categoria_catasto_ogpr),
                      0)) ;
            w_rendita_totale :=
                 NVL(w_rendita_totale, 0)
               + NVL (f_rendita (w_valore,
                                 rec_ogco.tipo_oggetto,
                                 a_anno_rif,
                                 rec_ogco.categoria_catasto_ogpr),
                      0);
         END;
      END IF;
   END LOOP;
   BEGIN
      DBMS_OUTPUT.put_line ('fine w_rendita_totale ' || w_rendita_totale);
      SELECT aliquota
        INTO w_aliquota
        FROM aliquote_mobili
       WHERE     tipo_tributo = a_tipo_tributo
             AND anno = a_anno_rif
             AND w_rendita_totale BETWEEN da_rendita
                                      AND NVL (a_rendita, 9999999999);
   EXCEPTION
      WHEN OTHERS
      THEN
         w_aliquota := TO_NUMBER (NULL);
   END;
   --
   RETURN w_aliquota;
END;
/* End Function: F_ALIQUOTA_MOBILE */
/

