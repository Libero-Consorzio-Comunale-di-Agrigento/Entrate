--liquibase formatted sql 
--changeset abrandolini:20250326_152423_web_carica_pratica_k stripComments:false runOnChange:true 
 
CREATE OR REPLACE procedure     WEB_CARICA_PRATICA_K
/*************************************************************************
  Rev.    Date         Author      Note
  4       29/02/2024   AB          #69780
                                   Utilizzo delle procedure _NR per poter utilizzare le nuove sequence
  3       20/03/2015   SC          Dati di ogpr.indirizzo_occ in ogim
  2       05/12/2014   SC          Delete di pratiche precedenti
  1       05/12/2014   VD          Aggiunta gestione nuovi campi mesi
                                   occupazione su OGGETTI_CONTRIBUENTE
                                   Valorizzazione flag_al_ridotta
                                   (se sono indicati dei mesi occupazione)
*************************************************************************/
(
   a_tipo_tributo    IN     VARCHAR2,
   a_cod_fiscale     IN     VARCHAR2,
   a_anno_rif        IN     NUMBER,
   a_utente          IN     VARCHAR2,
   a_crea_contatto   IN     VARCHAR2,
   a_pratica         IN OUT NUMBER)
IS
   w_conta_calc_imp         NUMBER;
   w_aliquota_base          NUMBER;
   w_tipo_aliquota_ab       NUMBER;
   w_aliquota_ab            NUMBER;
   w_aliquota_prec          NUMBER;
   w_tipo_aliquota_prec     NUMBER;
   w_aliquota_ogim          NUMBER;
   w_oggetto_pratica        NUMBER;
   w_oggetto_imposta        NUMBER;
   w_aliquota_rire          NUMBER;
   w_valore                 NUMBER;
   w_valore_dic             NUMBER;
   w_tipo_aliquota          NUMBER;
   w_detrazioni_prec        NUMBER;
   w_esiste_ogco            VARCHAR2 (1);
   w_detrazioni_made        NUMBER;
   w_mesi_possesso          NUMBER;
   w_mesi_possesso_prec     NUMBER;
   w_mesi_possesso_1s       NUMBER;
   w_data_inizio_possesso   DATE;
   w_data_fine_possesso     DATE;
   w_dal_possesso           DATE;
   w_al_possesso            DATE;
   w_dal_possesso_1s        DATE;
   w_al_possesso_1s         DATE;
   w_anno_s                 NUMBER;
   w_flag_possesso          VARCHAR2 (1);
   w_flag_possesso_prec     VARCHAR2 (1);
   w_flag_esclusione        VARCHAR2 (1);
   w_flag_riduzione         VARCHAR2 (1);
   w_flag_al_ridotta        VARCHAR2 (1);
   errore                   EXCEPTION;
   w_errore                 VARCHAR2 (2000);
   CURSOR sel_ogco
   IS
      SELECT ogco.tipo_rapporto,
             ogco.anno anno_ogco,
             ogco.cod_fiscale cod_fiscale_ogco,
             NVL (riog.categoria_catasto,
                  NVL (ogpr.categoria_catasto, ogge.categoria_catasto))
                categoria_catasto_ogge,
             ogpr.oggetto_pratica,
             ogog.sequenza sequenza_ogog,
             ogpr.oggetto oggetto_ogpr,
             NVL (ogpr.categoria_catasto, ogge.categoria_catasto)
                categoria_catasto_ogpr,
             ogco.flag_possesso,
             ogco.perc_possesso,
             NVL (
                ogog.mesi_possesso,
                DECODE (ogco.anno,
                        a_anno_rif, NVL (ogco.mesi_possesso, 12),
                        12))
                mesi_possesso,
             NVL (ogog.mesi_possesso_1sem, ogco.mesi_possesso_1sem)
                mesi_possesso_1sem,
             ogco.flag_esclusione,
             ogco.flag_riduzione,
             ogco.flag_ab_principale flag_ab_principale,
             ogco.flag_al_ridotta,
             DECODE (
                ogpr.tipo_oggetto,
                1, f_round (ogpr.valore / NVL (molt.moltiplicatore, 1), 0),
                3, f_round (
                        ogpr.valore
                      / DECODE (
                              NVL (ogpr.imm_storico, 'N')
                           || TO_CHAR (SIGN (2012 - a_anno_rif)),
                           'S1', 100,
                           NVL (molt.moltiplicatore, 1)),
                      0),
                55, f_round (
                         ogpr.valore
                       / DECODE (
                               NVL (ogpr.imm_storico, 'N')
                            || TO_CHAR (SIGN (2012 - a_anno_rif)),
                            'S1', 100,
                            NVL (molt.moltiplicatore, 1)),
                       0),
                ogpr.valore)
                valore,
             riog.rendita,
             riog.inizio_validita,
             riog.fine_validita,
             ogim.detrazione detrazione,
             NVL (riog.classe_catasto,
                  NVL (ogpr.classe_catasto, ogge.classe_catasto))
                classe_catasto_ogge,
             ogpr.tipo_oggetto tipo_oggetto,
             NVL (ogog.tipo_aliquota, ogim.tipo_aliquota) tipo_aliquota_ogim,
             NVL (ogog.aliquota, ogim.aliquota) aliquota_ogim,
             NVL (ogog.aliquota_erariale, ogim.aliquota_erariale)
                aliquota_erariale_ogim,
             NVL (ogog.aliquota_std, ogim.aliquota_std) aliquota_std_ogim,
             molt.moltiplicatore,
             ogim.oggetto_imposta,
             ogim.detrazione_acconto detrazione_acconto,
             ogim.detrazione_figli,
             ogim.detrazione_figli_acconto,
             ogpr.imm_storico,
             ogpr.flag_valore_rivalutato,
             prtr.tipo_pratica,
             DECODE (ogim.tipo_aliquota,
                     2, ogpr.oggetto_pratica_rif_ap,
                     TO_NUMBER (NULL))
                oggetto_pratica_rif_ap
        FROM moltiplicatori molt,
             riferimenti_oggetto riog,
             maggiori_detrazioni made,
             oggetti ogge,
             oggetti_imposta ogim,
             pratiche_tributo prtr,
             oggetti_pratica ogpr,
             oggetti_contribuente ogco,
             aliquote aliq,
             oggetti_ogim ogog
       WHERE prtr.tipo_pratica IN ('A', 'D')
             AND molt.anno(+) = ogco.anno
             AND molt.categoria_catasto(+) =
                    f_dato_riog (ogco.cod_fiscale,
                                 ogco.oggetto_pratica,
                                 a_anno_rif,
                                 'CA')
             AND made.anno(+) = a_anno_rif
             AND made.cod_fiscale(+) = ogco.cod_fiscale
             AND made.tipo_tributo(+) = a_tipo_tributo
             AND riog.da_anno(+) <= a_anno_rif
             AND NVL (riog.a_anno(+), 9999) >= a_anno_rif
             AND riog.oggetto(+) = ogge.oggetto
             AND ogco.anno || ogco.tipo_rapporto || 'S' =
                    (SELECT MAX (
                                  ogco_sub.anno
                               || ogco_sub.tipo_rapporto
                               || ogco_sub.flag_possesso)
                       FROM pratiche_tributo prtr_sub,
                            oggetti_pratica ogpr_sub,
                            oggetti_contribuente ogco_sub
                      WHERE  (       prtr_sub.data_notifica IS NOT NULL
                                    AND prtr_sub.tipo_pratica || '' = 'A'
                                    AND NVL (prtr_sub.stato_accertamento,
                                             'D') = 'D'
                                    AND NVL (prtr_sub.flag_denuncia, ' ') =
                                           'S'
                                    AND prtr_sub.anno < a_anno_rif
                                 OR     prtr_sub.data_notifica IS NULL
                                    AND prtr_sub.tipo_pratica || '' = 'D'
                                    AND NVL (ogco_sub.flag_possesso, 'N') =
                                           DECODE (
                                              a_tipo_tributo,
                                              'TASI', 'S',
                                              NVL (ogco_sub.flag_possesso,
                                                   'N')))
                            AND prtr_sub.anno <= a_anno_rif
                            AND prtr_sub.tipo_tributo = prtr.tipo_tributo
                            AND prtr_sub.pratica = ogpr_sub.pratica
                            AND ogpr_sub.oggetto = ogpr.oggetto
                            AND ogpr_sub.oggetto_pratica =
                                   ogco_sub.oggetto_pratica
                            AND ogco_sub.tipo_rapporto IN ('A',
                                                           'C',
                                                           'D',
                                                           'E')
                            AND ogco_sub.cod_fiscale = ogco.cod_fiscale)
             AND ogge.oggetto = ogpr.oggetto
             AND ogim.oggetto_pratica(+) = ogco.oggetto_pratica
             AND ogim.anno(+) = a_anno_rif
             AND ogim.cod_fiscale(+) = ogco.cod_fiscale
             AND ogog.oggetto_pratica(+) = ogim.oggetto_pratica
             AND ogog.anno(+) = ogim.anno
             AND ogog.cod_fiscale(+) = ogim.cod_fiscale
             AND prtr.tipo_tributo || '' = a_tipo_tributo
             AND prtr.pratica = ogpr.pratica
             AND ogpr.oggetto_pratica = ogco.oggetto_pratica
             --   and ogco.flag_esclusione                             is null
             AND DECODE (ogco.anno,
                         a_anno_rif, NVL (ogco.mesi_possesso, 12),
                         12) > 0
             AND ogco.flag_possesso = 'S'
             AND ogco.cod_fiscale LIKE a_cod_fiscale
             AND aliq.anno = a_anno_rif
             AND aliq.tipo_tributo = a_tipo_tributo
             AND aliq.tipo_aliquota = 2
      UNION
      SELECT ogco.tipo_rapporto,
             ogco.anno anno_ogco,
             ogco.cod_fiscale cod_fiscale_ogco,
             NVL (riog.categoria_catasto,
                  NVL (ogpr.categoria_catasto, ogge.categoria_catasto))
                categoria_catasto_ogge,
             ogpr.oggetto_pratica,
             ogog.sequenza sequenza_ogog,
             ogpr.oggetto oggetto_ogpr,
             NVL (ogpr.categoria_catasto, ogge.categoria_catasto)
                categoria_catasto_ogpr,
             ogco.flag_possesso,
             ogco.perc_possesso,
             NVL (
                ogog.mesi_possesso,
                DECODE (ogco.anno,
                        a_anno_rif, NVL (ogco.mesi_possesso, 12),
                        12))
                mesi_possesso,
             NVL (ogog.mesi_possesso_1sem, ogco.mesi_possesso_1sem)
                mesi_possesso_1sem,
             ogco.flag_esclusione,
             ogco.flag_riduzione,
             ogco.flag_ab_principale flag_ab_principale,
             ogco.flag_al_ridotta,
             DECODE (
                ogpr.tipo_oggetto,
                1, f_round (ogpr.valore / NVL (molt.moltiplicatore, 1), 0),
                3, f_round (
                        ogpr.valore
                      / DECODE (
                              NVL (ogpr.imm_storico, 'N')
                           || TO_CHAR (SIGN (2012 - a_anno_rif)),
                           'S1', 100,
                           NVL (molt.moltiplicatore, 1)),
                      0),
                55, f_round (
                         ogpr.valore
                       / DECODE (
                               NVL (ogpr.imm_storico, 'N')
                            || TO_CHAR (SIGN (2012 - a_anno_rif)),
                            'S1', 100,
                            NVL (molt.moltiplicatore, 1)),
                       0),
                ogpr.valore)
                valore,
             riog.rendita,
             riog.inizio_validita,
             riog.fine_validita,
             ogim.detrazione detrazione,
             NVL (riog.classe_catasto,
                  NVL (ogpr.classe_catasto, ogge.classe_catasto))
                classe_catasto_ogge,
             ogpr.tipo_oggetto tipo_oggetto,
             NVL (ogog.tipo_aliquota, ogim.tipo_aliquota) tipo_aliquota_ogim,
             NVL (ogog.aliquota, ogim.aliquota) aliquota_ogim,
             NVL (ogog.aliquota_erariale, ogim.aliquota_erariale)
                aliquota_erariale_ogim,
             NVL (ogog.aliquota_std, ogim.aliquota_std) aliquota_std_ogim,
             molt.moltiplicatore,
             ogim.oggetto_imposta,
             ogim.detrazione_acconto detrazione_acconto,
             ogim.detrazione_figli,
             ogim.detrazione_figli_acconto,
             ogpr.imm_storico,
             ogpr.flag_valore_rivalutato,
             prtr.tipo_pratica,
             DECODE (ogim.tipo_aliquota,
                     2, ogpr.oggetto_pratica_rif_ap,
                     TO_NUMBER (NULL))
                oggetto_pratica_rif_ap
        FROM moltiplicatori molt,
             riferimenti_oggetto riog,
             maggiori_detrazioni made,
             oggetti ogge,
             oggetti_imposta ogim,
             pratiche_tributo prtr,
             oggetti_pratica ogpr,
             oggetti_contribuente ogco,
             aliquote aliq,
             oggetti_ogim ogog
       WHERE molt.anno(+) = ogco.anno
             AND molt.categoria_catasto(+) =
                    f_dato_riog (ogco.cod_fiscale,
                                 ogco.oggetto_pratica,
                                 a_anno_rif,
                                 'CA')
             AND made.anno(+) = a_anno_rif
             AND made.cod_fiscale(+) = ogco.cod_fiscale
             AND made.tipo_tributo(+) = a_tipo_tributo
             AND riog.da_anno(+) <= a_anno_rif
             AND NVL (riog.a_anno(+), 9999) >= a_anno_rif
             AND riog.oggetto(+) = ogge.oggetto
             AND ogge.oggetto = ogpr.oggetto
             AND prtr.tipo_pratica = 'D'
             AND ogim.oggetto_pratica(+) = ogco.oggetto_pratica
             AND ogim.anno(+) = ogco.anno
             AND ogim.cod_fiscale(+) = ogco.cod_fiscale
             AND ogog.oggetto_pratica(+) = ogim.oggetto_pratica
             AND ogog.anno(+) = ogim.anno
             AND ogog.cod_fiscale(+) = ogim.cod_fiscale
             AND prtr.tipo_tributo || '' = a_tipo_tributo
             AND prtr.pratica = ogpr.pratica
             AND ogpr.oggetto_pratica = ogco.oggetto_pratica
             AND ogco.flag_possesso IS NULL
             AND ogco.anno = a_anno_rif
             --    and ogco.flag_esclusione                                  is null
             AND DECODE (ogco.anno,
                         a_anno_rif, NVL (ogco.mesi_possesso, 12),
                         12) > 0
             AND ogco.cod_fiscale LIKE a_cod_fiscale
             AND NVL (ogco.mesi_possesso, 12) > 0
             AND aliq.anno = a_anno_rif
             AND aliq.tipo_tributo = a_tipo_tributo
             AND aliq.tipo_aliquota = 2
      ORDER BY 3, 4, 5;
BEGIN
   IF a_crea_contatto = 'S'
   THEN
      BEGIN
         UPDATE contatti_contribuente
            SET pratica_k = NULL
          WHERE     anno = a_anno_rif
                AND tipo_tributo || '' = a_tipo_tributo
                AND cod_fiscale = a_cod_fiscale
                AND tipo_contatto = 4
                AND pratica_k IN (SELECT pratica
                                    FROM pratiche_tributo
                                   WHERE     anno = a_anno_rif
                                         AND tipo_tributo || '' =
                                                a_tipo_tributo
                                         AND cod_fiscale = a_cod_fiscale
                                         AND tipo_pratica = 'K'
                                         AND utente != 'WEB');
         DELETE pratiche_tributo
          WHERE     anno = a_anno_rif
                AND tipo_tributo || '' = a_tipo_tributo
                AND cod_fiscale = a_cod_fiscale
                AND tipo_pratica = 'K'
                AND utente != 'WEB';
      EXCEPTION
         WHEN OTHERS
         THEN
            w_errore :=
                  'Cancellazione precedenti pratiche di calcolo '
               || TO_CHAR (a_anno_rif)
               || ' ('
               || SQLERRM
               || ')';
            RAISE errore;
      END;
   END IF;
   w_anno_s := LPAD (TO_CHAR (a_anno_rif), 4, '0');
   BEGIN
      SELECT aliquota
        INTO w_aliquota_base
        FROM aliquote
       WHERE     anno = a_anno_rif
             AND tipo_tributo = a_tipo_tributo
             AND tipo_aliquota = 1;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         w_errore :=
               'Manca record in Aliquote - base -'
            || TO_CHAR (a_anno_rif)
            || ' ('
            || SQLERRM
            || ')';
         RAISE errore;
      WHEN OTHERS
      THEN
         w_errore :=
               'Errore in ricerca Aliquote - ogim -'
            || TO_CHAR (a_anno_rif)
            || ' ('
            || SQLERRM
            || ')';
         RAISE errore;
   END;
   BEGIN
      SELECT tipo_aliquota, aliquota
        INTO w_tipo_aliquota_ab, w_aliquota_ab
        FROM aliquote
       WHERE     anno = a_anno_rif
             AND flag_ab_principale IS NOT NULL
             AND tipo_tributo = a_tipo_tributo;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         w_errore :=
               'Manca record in Aliquote - ab.principale -'
            || TO_CHAR (a_anno_rif)
            || ' ('
            || SQLERRM
            || ')';
         RAISE errore;
      WHEN OTHERS
      THEN
         w_errore :=
               'Errore in ricerca Aliquote - ogim -'
            || TO_CHAR (a_anno_rif)
            || ' ('
            || SQLERRM
            || ')';
         RAISE errore;
   END;
   BEGIN
      SELECT detrazione
        INTO w_detrazioni_made
        FROM maggiori_detrazioni
       WHERE     cod_fiscale = a_cod_fiscale
             AND anno = a_anno_rif - 1
             AND tipo_tributo = a_tipo_tributo;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         w_detrazioni_made := NULL;
      WHEN OTHERS
      THEN
         w_errore :=
               'Errore in Ricerca Maggiori Detrazioni '
            || TO_CHAR (a_anno_rif - 1)
            || ' per '
            || a_cod_fiscale
            || ' ('
            || SQLERRM
            || ')';
         RAISE errore;
   END;
--   BEGIN
--      SELECT NVL (MAX (pratica), 0) + 1
--        INTO a_pratica
--        FROM pratiche_tributo;
--   EXCEPTION
--      WHEN OTHERS
--      THEN
--         w_errore :=
--            'Errore in ricerca Pratiche Tributo' || ' (' || SQLERRM || ')';
--         RAISE errore;
--   END;

   a_pratica             := NULL;  --Nr della pratica
   pratiche_tributo_nr(a_pratica); --Assegnazione Numero Progressivo

   BEGIN
      INSERT INTO pratiche_tributo (pratica,
                                    cod_fiscale,
                                    tipo_tributo,
                                    anno,
                                    tipo_pratica,
                                    tipo_evento,
                                    DATA,
                                    utente)
           VALUES (a_pratica,
                   a_cod_fiscale,
                   a_tipo_tributo,
                   a_anno_rif,
                   'K',
                   'U',
                   TRUNC (SYSDATE),
                   a_utente);
   EXCEPTION
      WHEN OTHERS
      THEN
         w_errore :=
               'Errore in inserimento Pratiche Tributo'
            || ' ('
            || SQLERRM
            || ')';
         RAISE errore;
   END;
   BEGIN
      INSERT INTO rapporti_tributo (pratica, cod_fiscale)
           VALUES (a_pratica, a_cod_fiscale);
   EXCEPTION
      WHEN OTHERS
      THEN
         w_errore :=
               'Errore in inserimento Pratiche Tributo'
            || ' ('
            || SQLERRM
            || ')';
         RAISE errore;
   END;
   --         w_errore := 'Controllo a_utente '||NVL(a_utente,'nullo')||
   --           ' ('||SQLERRM||')';
   --         RAISE errore;
   --         w_errore := 'Controllo a_tipo_tributo '||NVL(a_tipo_tributo,'nullo')||
   --           ' ('||SQLERRM||')';
   --         RAISE errore;
   IF NVL (a_utente, 'TR4') != 'WEB' AND a_crea_contatto = 'S'
   THEN
      BEGIN
         update contatti_contribuente
            set pratica_k = a_pratica
          where cod_fiscale = a_cod_fiscale
            and DATA = trunc(sysdate)
            and anno = a_anno_rif
            and tipo_contatto = 4
            and tipo_richiedente = 2
            and tipo_tributo = a_tipo_tributo;
         if sql%rowcount = 0 then
             INSERT INTO contatti_contribuente (cod_fiscale,
                                                DATA,
                                                anno,
                                                tipo_contatto,
                                                tipo_richiedente,
                                                tipo_tributo,
                                                pratica_k)
                  VALUES (a_cod_fiscale,
                          TRUNC (SYSDATE),
                          a_anno_rif,
                          4,
                          2,
                          a_tipo_tributo,
                          a_pratica);
         end if;
      EXCEPTION
         WHEN OTHERS
         THEN
            w_errore :=
                  'Errore in inserimento Contatti Contribuente'
               || ' ('
               || SQLERRM
               || ')';
            RAISE errore;
      END;
   END IF;
   SELECT COUNT (*)
     INTO w_conta_calc_imp
     FROM oggetti_imposta
    WHERE     cod_fiscale = a_cod_fiscale
          AND anno = a_anno_rif
          AND flag_calcolo = 'S'
          AND tipo_tributo = a_tipo_tributo;
   IF w_conta_calc_imp = 0
   THEN
      IF a_tipo_tributo = 'ICI'
      THEN
         calcolo_imposta_ici (a_anno_rif,
                              a_cod_fiscale,
                              a_utente,
                              'N');
      ELSE
         calcolo_imposta_tasi (a_anno_rif,
                               a_cod_fiscale,
                               a_utente,
                               'N');
      END IF;
   END IF;
   FOR rec_ogco IN sel_ogco
   LOOP
      w_mesi_possesso_1s := rec_ogco.mesi_possesso_1sem;
      w_flag_possesso := rec_ogco.flag_possesso;
      w_mesi_possesso := rec_ogco.mesi_possesso;
      w_flag_esclusione := rec_ogco.flag_esclusione;
      w_flag_riduzione := rec_ogco.flag_riduzione;
      w_flag_al_ridotta := rec_ogco.flag_al_ridotta;
      IF rec_ogco.anno_ogco = a_anno_rif AND w_flag_possesso IS NULL
      THEN
         BEGIN
              SELECT LTRIM (MAX (NVL (ogco.flag_possesso, ' ')))
                INTO w_flag_possesso_prec
                FROM oggetti_contribuente ogco,
                     oggetti_pratica ogpr,
                     pratiche_tributo prtr
               WHERE ogco.cod_fiscale = rec_ogco.cod_fiscale_ogco
                     AND ogpr.oggetto = rec_ogco.oggetto_ogpr
                     AND ogpr.oggetto_pratica = ogco.oggetto_pratica
                     AND prtr.pratica = ogpr.pratica
                     AND prtr.tipo_tributo || '' = a_tipo_tributo
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
                              WHERE   (       c.data_notifica IS NOT NULL
                                            AND c.tipo_pratica || '' = 'A'
                                            AND NVL (c.stato_accertamento, 'D') =
                                                   'D'
                                            AND NVL (c.flag_denuncia, ' ') =
                                                   'S'
                                         OR     c.data_notifica IS NULL
                                            AND c.tipo_pratica || '' = 'D')
                                    AND c.pratica = a.pratica
                                    AND a.oggetto_pratica = b.oggetto_pratica
                                    AND c.tipo_tributo || '' = a_tipo_tributo
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
      -- Nel caso di presenza di OGGETTI_OGIM vengono sempre utilizzati
      -- i mesi di possesso 1 semestre di oggetti_ogim
      IF NVL (rec_ogco.sequenza_ogog, 0) = 0
      THEN
         determina_mesi_possesso_ici (w_flag_possesso,
                                      w_flag_possesso_prec,
                                      a_anno_rif,
                                      w_mesi_possesso,
                                      w_mesi_possesso_1s,
                                      w_dal_possesso,
                                      w_al_possesso,
                                      w_dal_possesso_1s,
                                      w_al_possesso_1s);
         /*
          Se esiste un riog che non ricopre interamente il periodo di possesso,
          si azzerano i mesi di possesso e si obbliga ad introdurli.
         */
         IF rec_ogco.inizio_validita IS NOT NULL
         THEN
            IF        rec_ogco.inizio_validita > w_dal_possesso
                  AND rec_ogco.inizio_validita < w_al_possesso
               OR     rec_ogco.fine_validita > w_dal_possesso
                  AND rec_ogco.fine_validita < w_al_possesso
            THEN
               w_mesi_possesso := NULL;
               w_mesi_possesso_1s := NULL;
            END IF;
         END IF;
      END IF;
      BEGIN
         SELECT NVL (rire.aliquota, 0)
           INTO w_aliquota_rire
           FROM rivalutazioni_rendita rire
          WHERE     tipo_oggetto = rec_ogco.tipo_oggetto
                AND anno = rec_ogco.anno_ogco;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            w_aliquota_rire := 0;
         WHEN OTHERS
         THEN
            w_errore :=
                  'Errore in calcolo rivalutazione rendita'
               || ' ('
               || SQLERRM
               || ')';
            RAISE errore;
      END;
      SELECT DECODE (
                rec_ogco.tipo_oggetto,
                4, rec_ogco.valore,
                NVL (
                   rec_ogco.rendita,
                   DECODE (
                         rec_ogco.tipo_pratica
                      || NVL (rec_ogco.flag_valore_rivalutato, 'N'),
                      'AN', rec_ogco.valore,
                      (  rec_ogco.valore
                       / (100 + NVL (w_aliquota_rire, 0))
                       * 100)))),
             DECODE (
                rec_ogco.tipo_oggetto,
                4, rec_ogco.valore,
                (rec_ogco.valore / (100 + NVL (w_aliquota_rire, 0)) * 100))
        INTO w_valore, w_valore_dic
        FROM DUAL;
      w_valore := ROUND (w_valore, 2);
      w_valore_dic := ROUND (w_valore_dic, 2);
      --       -- gestione degli immobili di catecoria catasto B
      --       -- se l'anno della pratica è minore del 2007 e
      --       -- l'anno d'imposta è maggiore del 2006 va aggiunta la rivalutazione del 40%
      --       if substr(rec_ogco.categoria_catasto_ogpr,1,1) = 'B'
      --          and rec_ogco.anno_ogco < 2007 and a_anno_rif > 2006 then
      --             w_valore     := round(w_valore * 1.4 , 2);
      --             w_valore_dic := round(w_valore_dic * 1.4 , 2);
      --       end if;
      --
      --    Determinazione detrazione di acconto ICI per anni > 2000
      --
      IF a_anno_rif > 2000
      THEN
         IF rec_ogco.anno_ogco < a_anno_rif
         THEN
            w_esiste_ogco := 'S';
         ELSE
            w_esiste_ogco := 'N';
         END IF;
         IF w_esiste_ogco = 'S'
         THEN
            IF rec_ogco.detrazione IS NULL
            THEN
               w_detrazioni_prec := NULL;
            ELSE
               w_detrazioni_prec :=
                  f_round (
                       NVL (w_detrazioni_made, rec_ogco.detrazione)
                     / w_mesi_possesso_prec
                     * w_mesi_possesso_1s,
                     0);
            END IF;
         ELSE
            w_detrazioni_prec := w_detrazioni_made;
         END IF;
      END IF;
--      BEGIN
--         SELECT NVL (MAX (oggetto_pratica), 0) + 1
--           INTO w_oggetto_pratica
--           FROM oggetti_pratica;
--      EXCEPTION
--         WHEN OTHERS
--         THEN
--            w_errore :=
--               'Errore in ricerca Oggetti Pratica' || ' (' || SQLERRM || ')';
--            RAISE errore;
--      END;
      DBMS_OUTPUT.put_line ('rec_ogco.detrazione ' || rec_ogco.detrazione);
      DBMS_OUTPUT.put_line ('w_detrazioni_made ' || w_detrazioni_made);
      DBMS_OUTPUT.put_line ('w_detrazioni_prec ' || w_detrazioni_prec);

      w_oggetto_pratica := null;
      oggetti_pratica_nr(w_oggetto_pratica); --Assegnazione Numero Progressivo

      BEGIN
         INSERT INTO oggetti_pratica (oggetto_pratica,
                                      oggetto,
                                      pratica,
                                      categoria_catasto,
                                      classe_catasto,
                                      valore,
                                      utente,
                                      tipo_oggetto,
                                      anno,
                                      note,
                                      imm_storico,
                                      oggetto_pratica_rif_ap)
                 VALUES (
                           w_oggetto_pratica,
                           rec_ogco.oggetto_ogpr,
                           a_pratica,
                           rec_ogco.categoria_catasto_ogge,
                           rec_ogco.classe_catasto_ogge,
                           w_valore,
                           a_utente,
                           rec_ogco.tipo_oggetto,
                           a_anno_rif,
                              RPAD (
                                 NVL (rec_ogco.categoria_catasto_ogpr, ' '),
                                 3,
                                 ' ')
                           || TO_CHAR (w_valore_dic * 100),
                           rec_ogco.imm_storico,
                           rec_ogco.oggetto_pratica_rif_ap);
      EXCEPTION
         WHEN OTHERS
         THEN
            w_errore :=
                  'Errore in inserimento Oggetti Pratica'
               || ' ('
               || SQLERRM
               || ')';
            RAISE errore;
      END;
      IF rec_ogco.oggetto_pratica_rif_ap IS NOT NULL
      THEN
         aggiornamento_ogpr_rif_ap (w_oggetto_pratica,
                                    rec_ogco.oggetto_pratica_rif_ap);
      END IF;
      BEGIN
         INSERT INTO costi_storici (oggetto_pratica, anno, costo)
            SELECT w_oggetto_pratica, anno, costo
              FROM costi_storici
             WHERE oggetto_pratica = rec_ogco.oggetto_pratica;
      EXCEPTION
         WHEN OTHERS
         THEN
            w_errore :=
                  'Errore in inserimento Costi Storici'
               || ' ('
               || SQLERRM
               || ')';
            RAISE errore;
      END;
      BEGIN
         DBMS_OUTPUT.put_line (
            'INSERISCO IN OGCO rec_ogco.detrazione ' || rec_ogco.detrazione);
         INSERT INTO oggetti_contribuente (cod_fiscale,
                                           oggetto_pratica,
                                           anno,
                                           perc_possesso,
                                           mesi_possesso,
                                           mesi_possesso_1sem,
                                           detrazione,
                                           flag_possesso,
                                           flag_esclusione,
                                           flag_riduzione,
                                           flag_ab_principale,
                                           flag_al_ridotta,
                                           utente,
                                           tipo_rapporto_k)
                 VALUES (
                           a_cod_fiscale,
                           w_oggetto_pratica,
                           a_anno_rif,
                           rec_ogco.perc_possesso,
                           w_mesi_possesso,
                           w_mesi_possesso_1s,
                           rec_ogco.detrazione,
                           w_flag_possesso,
                           w_flag_esclusione,
                           w_flag_riduzione,
                           DECODE (rec_ogco.tipo_aliquota_ogim,
                                   2, 'S',
                                   rec_ogco.flag_ab_principale),
                           rec_ogco.flag_al_ridotta,
                           a_utente,
                           rec_ogco.tipo_rapporto);
      EXCEPTION
         WHEN OTHERS
         THEN
            w_errore :=
                  'Errore in inserimento Oggetti Contribuente'
               || ' ('
               || SQLERRM
               || ')';
            RAISE errore;
      END;
      w_tipo_aliquota := TO_NUMBER ('');
      BEGIN
         SELECT 3
           INTO w_tipo_aliquota
           FROM aliquote aliq, utilizzi_oggetto utog
          WHERE     aliq.anno = a_anno_rif
                AND aliq.tipo_aliquota = 3
                AND utog.tipo_utilizzo = 1
                AND utog.oggetto = rec_ogco.oggetto_ogpr
                AND aliq.tipo_tributo = a_tipo_tributo
                AND utog.tipo_tributo = a_tipo_tributo
                AND a_anno_rif BETWEEN utog.anno
                                   AND NVL (
                                          TO_CHAR (utog.data_scadenza,
                                                   'yyyy'),
                                          a_anno_rif)
                AND ROWNUM = 1;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            NULL;
         WHEN OTHERS
         THEN
            w_errore :=
               'Errore in ricerca Utilizzi Oggetto' || ' (' || SQLERRM || ')';
            RAISE errore;
      END;
      w_aliquota_ogim := TO_NUMBER ('');
      IF    rec_ogco.tipo_aliquota_ogim IS NOT NULL
         OR w_tipo_aliquota IS NOT NULL
      THEN
         BEGIN
            SELECT aliquota
              INTO w_aliquota_ogim
              FROM aliquote
             WHERE     anno = a_anno_rif
                   AND tipo_aliquota =
                          NVL (rec_ogco.tipo_aliquota_ogim, w_tipo_aliquota)
                   AND tipo_tributo = a_tipo_tributo;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               NULL;
            WHEN OTHERS
            THEN
               w_errore :=
                     'Errore in ricerca Aliquote - ogim -'
                  || ' ('
                  || SQLERRM
                  || ')';
               RAISE errore;
         END;
      END IF;
--      BEGIN
--         SELECT NVL (MAX (oggetto_imposta), 0) + 1
--           INTO w_oggetto_imposta
--           FROM oggetti_imposta;
--      EXCEPTION
--         WHEN OTHERS
--         THEN
--            w_errore :=
--               'Errore in ricerca Oggetti Imposta' || ' (' || SQLERRM || ')';
--            RAISE errore;
--      END;
      BEGIN

         w_oggetto_imposta := null;
         oggetti_imposta_nr(w_oggetto_imposta); --Assegnazione Numero Progressivo

         DBMS_OUTPUT.put_line ('A w_oggetto_imposta ' || w_oggetto_imposta);
         DBMS_OUTPUT.put_line (
            'A rec_ogco.detrazione ' || rec_ogco.detrazione);
         DBMS_OUTPUT.put_line ('A w_flag_possesso ' || w_flag_possesso);
         DBMS_OUTPUT.put_line (
               'A rec_ogco.tipo_aliquota_ogim '
            || rec_ogco.tipo_aliquota_ogim
            || ' rec_ogco.aliquota_ogim '
            || rec_ogco.aliquota_ogim);
         INSERT INTO oggetti_imposta (oggetto_imposta,
                                      cod_fiscale,
                                      anno,
                                      oggetto_pratica,
                                      imposta,
                                      tipo_aliquota,
                                      aliquota,
                                      aliquota_erariale,
                                      aliquota_std,
                                      utente,
                                      detrazione,
                                      detrazione_acconto,
                                      detrazione_figli,
                                      detrazione_figli_acconto,
                                      detrazione_std,
                                      tipo_tributo)
            SELECT w_oggetto_imposta,
                   a_cod_fiscale,
                   a_anno_rif,
                   w_oggetto_pratica,
                   0,
                   rec_ogco.tipo_aliquota_ogim,
                   rec_ogco.aliquota_ogim,
                   rec_ogco.aliquota_erariale_ogim,
                   rec_ogco.aliquota_std_ogim,
                   a_utente,
                   rec_ogco.detrazione,
                   rec_ogco.detrazione_acconto,
                   rec_ogco.detrazione_figli,
                   rec_ogco.detrazione_figli_acconto,
                   DECODE (rec_ogco.aliquota_std_ogim,
                           NULL, NULL,
                           rec_ogco.detrazione),
                   a_tipo_tributo
              FROM DUAL;
      EXCEPTION
         WHEN OTHERS
         THEN
            w_errore :=
                  'Errore in inserimento Oggetti Imposta'
               || ' ('
               || SQLERRM
               || ')';
            RAISE errore;
      END;
      IF a_anno_rif > 2000
      THEN
         BEGIN
            IF w_aliquota_ogim IS NULL
            THEN
               IF rec_ogco.flag_ab_principale IS NULL
               THEN
                  w_tipo_aliquota_prec := 1;                           -- Base
               ELSE
                  w_tipo_aliquota_prec := w_tipo_aliquota_ab;
               END IF;
            ELSE
               IF NVL (rec_ogco.tipo_aliquota_ogim, w_tipo_aliquota) IS NULL
               THEN
                  IF rec_ogco.flag_ab_principale IS NULL
                  THEN
                     w_tipo_aliquota_prec := 1;                        -- Base
                  ELSE
                     w_tipo_aliquota_prec := w_tipo_aliquota_ab;
                  END IF;
               ELSE
                  w_tipo_aliquota_prec :=
                     NVL (rec_ogco.tipo_aliquota_ogim, w_tipo_aliquota);
               END IF;
            END IF;
            IF a_anno_rif < 2012
            THEN
               IF w_tipo_aliquota_prec IS NULL
               THEN
                  w_aliquota_prec := 0;
               ELSE
                  BEGIN
                     SELECT aliquota
                       INTO w_aliquota_prec
                       FROM aliquote
                      WHERE     anno = a_anno_rif - 1
                            AND tipo_aliquota = w_tipo_aliquota_prec
                            AND tipo_tributo = a_tipo_tributo;
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        w_errore :=
                              'Manca record in Aliquote per Tipo '
                           || TO_CHAR (w_tipo_aliquota_prec)
                           || ' e anno '
                           || TO_CHAR (a_anno_rif - 1)
                           || ' ('
                           || SQLERRM
                           || ')';
                        RAISE errore;
                     WHEN OTHERS
                     THEN
                        w_errore :=
                              'Errore in ricerca Aliquote - ogim -'
                           || TO_CHAR (a_anno_rif - 1)
                           || ' ('
                           || SQLERRM
                           || ')';
                        RAISE errore;
                  END;
               END IF;
               BEGIN
                  SELECT f_aliquota_alca (a_anno_rif - 1,
                                          w_tipo_aliquota_prec,
                                          rec_ogco.categoria_catasto_ogge,
                                          w_aliquota_prec,
                                          0,
                                          a_cod_fiscale,
                                          a_tipo_tributo)
                    INTO w_aliquota_prec
                    FROM DUAL;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     NULL;
               END;
            ELSE
               w_tipo_aliquota_prec := rec_ogco.tipo_aliquota_ogim;
               IF w_tipo_aliquota_prec IS NULL
               THEN
                  w_aliquota_prec := 0;
               ELSE
                  BEGIN
                     SELECT NVL (aliquota_base, aliquota)
                       INTO w_aliquota_prec
                       FROM aliquote
                      WHERE     anno = a_anno_rif
                            AND tipo_aliquota = w_tipo_aliquota_prec
                            AND tipo_tributo = a_tipo_tributo;
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        w_errore :=
                              'Manca record in Aliquote per Tipo '
                           || TO_CHAR (w_tipo_aliquota_prec)
                           || ' e anno '
                           || TO_CHAR (a_anno_rif)
                           || ' ('
                           || SQLERRM
                           || ')';
                        RAISE errore;
                     WHEN OTHERS
                     THEN
                        w_errore :=
                              'Errore in ricerca Aliquote - ogim -'
                           || TO_CHAR (a_anno_rif)
                           || ' ('
                           || SQLERRM
                           || ')';
                        RAISE errore;
                  END;
               END IF;
               --dbms_output.put_line(a_anno_rif||'-'|| w_tipo_aliquota_prec||'-'|| rec_ogco.categoria_catasto_ogge||'-'|| w_aliquota_prec||'-'|| w_oggetto_pratica||'-'|| a_cod_fiscale||'-'||a_tipo_tributo);
               -- messo w_oggetto_pratica al posto di 0 per recuperare l'aliquota della pertinenza di 13/8/14 AB
               BEGIN
                  SELECT f_aliquota_alca (a_anno_rif,
                                          w_tipo_aliquota_prec,
                                          rec_ogco.categoria_catasto_ogge,
                                          w_aliquota_prec,
                                          w_oggetto_pratica,
                                          a_cod_fiscale,
                                          a_tipo_tributo)
                    --                  select F_ALIQUOTA_ALCA(a_anno_rif, w_tipo_aliquota_prec, rec_ogco.categoria_catasto_ogge, w_aliquota_prec, 0, a_cod_fiscale,a_tipo_tributo)
                    INTO w_aliquota_prec
                    FROM DUAL;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     NULL;
               END;
            END IF;
            DBMS_OUTPUT.put_line (
               'w_aliquota_pre ' || w_aliquota_prec || ' ');
            BEGIN
               UPDATE oggetti_pratica
                  SET indirizzo_occ =
                            LPAD (TO_CHAR (w_tipo_aliquota_prec), 2, '0')
                         || LPAD (TO_CHAR (w_aliquota_prec * 100), 6, '0')
                         || LPAD (
                               TO_CHAR (
                                  NVL (rec_ogco.detrazione_acconto, 0) * 100),
                               15,
                               '0')
                         || LPAD (
                               TO_CHAR (
                                  rec_ogco.aliquota_erariale_ogim * 100),
                               6,
                               '0')
                WHERE oggetto_pratica = w_oggetto_pratica;
            EXCEPTION
               WHEN OTHERS
               THEN
                  w_errore :=
                        'Errore in Aggiornamento Dati Anno Precedente - ogpr -'
                     || ' ('
                     || SQLERRM
                     || ')';
                  RAISE errore;
            END;
-- 20/03/2015 SC
           BEGIN
              update oggetti_imposta
                 set tipo_aliquota_prec = w_tipo_aliquota_prec
                   , aliquota_prec = w_aliquota_prec * 100
                   , detrazione_prec = rec_ogco.detrazione_acconto
                   , aliquota_erar_prec = rec_ogco.aliquota_erariale_ogim
               where oggetto_pratica = w_oggetto_pratica
              ;
           EXCEPTION
             WHEN others THEN
             w_errore := 'Errore in Aggiornamento Dati Anno Precedente - ogim -'||
                      ' ('||SQLERRM||')';
                RAISE errore;
           END;
         END;
      END IF;
   END LOOP;
   IF w_conta_calc_imp = 0
   THEN
      BEGIN
         DELETE oggetti_imposta
          WHERE     cod_fiscale = a_cod_fiscale
                AND anno = a_anno_rif
                AND flag_calcolo = 'S'
                AND tipo_tributo = a_tipo_tributo;
      EXCEPTION
         WHEN OTHERS
         THEN
            w_errore :=
                  'Errore in Cancellazione oggetti_imposta temporanei'
               || ' ('
               || SQLERRM
               || ')';
            RAISE errore;
      END;
   END IF;
EXCEPTION
   WHEN errore
   THEN
      ROLLBACK;
      raise_application_error (-20999, w_errore);
   WHEN OTHERS
   THEN
      ROLLBACK;
      raise_application_error (
         -20999,
            'Errore in inserimento pratica di calcolo '
         || ' ('
         || SQLERRM
         || ')');
END;
/* End Procedure: WEB_CARICA_PRATICA_K */
/
