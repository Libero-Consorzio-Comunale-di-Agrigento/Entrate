--liquibase formatted sql 
--changeset abrandolini:20250326_152423_calcolo_detrazioni_mobili_tasi stripComments:false runOnChange:true 
 
create or replace procedure CALCOLO_DETRAZIONI_MOBILI_TASI
/*************************************************************************
 Procedure da lanciare prima del calcolo_imposta_tasi per ogni contribuente in modo
 che vengano ricalcolate le maggiori_detrazioni sulla base delle detrazioni_mobili
 Si lancia una volta per ogni contribuente.
  Rev.    Date         Author      Note
  1       13/10/2014   Betta T.    Corretto per errore in determinazione
                                   detrazioni mancava la rottura a livello di
                                   oggetto principale
  2       11/11/2014   VD          Modificato raggruppamento oggetti per
                                   calcolo detrazioni: si raggruppano oggetti
                                   con flag abitazione principale attivato
  3       23/03/2015   VD          Modificata query principale per
                                   analogia con calcolo imposta ICI:
                                   nella subquery non si considera più
                                   il flag_possesso = 'S'
                                   (vv modifica CALCOLO_IMPOSTA_TASI)
  4       17/04/2015   PM/VD       Modificato calcolo rendita: non si
                                   utilizza più la funzione interna
                                   F_CALCOLO_RENDITA, ma si usa la procedure
                                   CALCOLO_RIOG_MULTIPLO e la funzione
                                   F_RENDITA.
  5       28/05/2015   VD          Modificata tabella DETRAZIONI_MOBILI:
                                   i campi DA_VALORE e A_VALORE ora si
                                   chiamano DA_RENDITA e A_RENDITA
  6       03/07/2015   SC          Modificato ancora l'oggetto_rottura:
                                   nel caso in cui un'immobile ha flag_ab_principale
                                   a S, c'è poi un C con flag_ab_principale a S
                                   e anche un C senza flag_ab_principale ma
                                   che è riferito al primo immobile, i due
                                   C andavano in due gruppi di rottura diversi.
                                   Tramite F_CALCOLA_ROTTURA_DEMO faccio
                                   in modo che vadano nello stesso gruppo.
*************************************************************************/
( a_anno_rif       IN NUMBER,
  a_cod_fiscale    IN VARCHAR2,
  a_ravvedimento   IN VARCHAR2 := 'N')
IS
   errore                         EXCEPTION;
   w_errore                       VARCHAR2 (200);
   w_rendita_totale               NUMBER := 0;
   w_flag_pertinenze              VARCHAR2 (1);
   w_detrazioni                   NUMBER := 0;
   w_flag_possesso_prec           VARCHAR2 (1);
   w_mesi_possesso                NUMBER;
   w_mesi_possesso_1sem           NUMBER;
   w_mesi_esclusione              NUMBER;
   w_data_inizio_possesso         date;
   w_data_fine_possesso           date;
   w_data_inizio_possesso_1s      date;
   w_data_fine_possesso_1s        date;
   w_valore                       number;
   w_valore_1s                    number;
   w_esiste_det_ogco              VARCHAR2 (1);
   w_rif_ap_ab_principale         VARCHAR2 (1);
   w_cod_fiscale                  VARCHAR2 (16);
   w_cod_fiscale_precedente       VARCHAR2 (16) := ' ';
   w_oggetto_rottura_precedente   number;
   w_conta_rif_ap_ab_principale   NUMBER;
   w_tipo_tributo                 tipi_tributo.tipo_tributo%TYPE := 'TASI';
   w_motivo_detrazione            motivi_detrazione.motivo_detrazione%TYPE
                                     := 90;
   w_perc                         NUMBER := 0;
   w_cod_istat                    VARCHAR2 (6) := '000000';
   w_detrazione_mobile            detrazioni_mobili.detrazione%TYPE;
   w_det_mobile_1sem              maggiori_detrazioni.detrazione_acconto%TYPE;
   w_detrazione_mobile_tot        detrazioni_mobili.detrazione%TYPE;
   w_det_mobile_1sem_tot          maggiori_detrazioni.detrazione_acconto%TYPE;
   CURSOR sel_ogco
   IS
--
-- VD (11/11/2014): se il flag abitazione principale e' attivo, si indica -1
--                  nell'oggetto rottura, in modo da raggruppare le rendite
--                  di tutti gli oggetti
--
      SELECT decode(ogco.flag_ab_principale,'S',-1,F_CALCOLA_ROTTURA_DEMO (ogco.oggetto_pratica,
                            ogpr.oggetto_pratica_rif_ap,
                            ogco.cod_fiscale,
                            ogco.flag_ab_principale,
                            a_anno_rif,
                            a_ravvedimento)) oggetto_rottura,
      --nvl(ogpr.oggetto_pratica_rif_ap,ogpr.oggetto_pratica)) oggetto_rottura,
             ogpr.tipo_oggetto,
             ogpr.pratica pratica_ogpr,
             ogpr.oggetto oggetto_ogpr,
             f_dato_riog (ogco.cod_fiscale,
                          ogco.oggetto_pratica,
                          a_anno_rif,
                          'CA')
                categoria_catasto_ogpr,
             ogpr.oggetto_pratica oggetto_pratica_ogpr,
             ogco.anno anno_ogco,
             ogco.cod_fiscale cod_fiscale_ogco,
             ogco.flag_possesso,
             DECODE (F_ABILITA_FUNZIONE('DETRAZIONE_MOBILE_POSS'), 'S',
                     ogco.perc_possesso,
                     nvl(ogco.perc_detrazione,0)) --Carnate, Tresigallo, Formignana, Malnate
                perc,
             DECODE (ogco.anno, a_anno_rif, NVL (ogco.mesi_possesso, 12), 12)
                mesi_possesso,
             DECODE (ogco.anno, a_anno_rif, ogco.mesi_possesso_1sem, 6)
                mesi_possesso_1sem,
             ogco.flag_al_ridotta,
             DECODE (
                ogco.anno,
                a_anno_rif, DECODE (
                               ogco.flag_al_ridotta,
                               'S', NVL (ogco.mesi_aliquota_ridotta,
                                         NVL (ogco.mesi_possesso, 12)),
                               NVL (ogco.mesi_aliquota_ridotta, 0)),
                DECODE (ogco.flag_al_ridotta, 'S', 12, 0))
                mesi_aliquota_ridotta,
             ogco.flag_esclusione,
             DECODE (
                ogco.anno,
                a_anno_rif, DECODE (
                               ogco.flag_esclusione,
                               'S', NVL (ogco.mesi_esclusione,
                                         NVL (ogco.mesi_possesso, 12)),
                               NVL (ogco.mesi_esclusione, 0)),
                DECODE (ogco.flag_esclusione, 'S', 12, 0))
                mesi_esclusione,
             ogco.flag_riduzione,
             DECODE (
                ogco.anno,
                a_anno_rif, DECODE (
                               ogco.flag_riduzione,
                               'S', NVL (ogco.mesi_riduzione,
                                         NVL (ogco.mesi_possesso, 12)),
                               NVL (ogco.mesi_riduzione, 0)),
                DECODE (ogco.flag_riduzione, 'S', 12, 0))
                mesi_riduzione,
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
             f_valore (
                NVL (f_valore_d (ogpr.oggetto_pratica, a_anno_rif),
                     ogpr.valore),
                ogpr.tipo_oggetto,
                prtr.anno,
                a_anno_rif,
                NVL (ogpr.categoria_catasto, ogge.categoria_catasto),
                prtr.tipo_pratica,
                ogpr.FLAG_VALORE_RIVALUTATO)
                valore_d,
             ogco.detrazione detrazione_ogco,
             NVL (ogpr.categoria_catasto, ogge.categoria_catasto)
                categoria_catasto_ogge,
             ogpr.IMM_STORICO,
             ogpr.oggetto_pratica_rif_ap,
             prtr.tipo_pratica,
             prtr.anno anno_titr,
             ogco.tipo_rapporto,
             decode(ogpr.tipo_oggetto
                   ,1,nvl(molt.moltiplicatore,1)
                   ,3,decode(nvl(ogpr.imm_storico,'N')||to_char(sign(2012 - a_anno_rif))
                            ,'S1',100
                            ,nvl(molt.moltiplicatore,1)
                            )
                   ,1)     moltiplicatore,
             rire.aliquota aliquota_rivalutazione
        FROM oggetti ogge,
             pratiche_tributo prtr,
             oggetti_pratica ogpr,
             oggetti_contribuente ogco,
             rivalutazioni_rendita rire,
             moltiplicatori molt
       WHERE     ogco.tipo_rapporto = 'D'
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
                            AND b.cod_fiscale = ogco.cod_fiscale
--
-- (VD) 23/03/2015 - Modificata in analogia al CALCOLO_ICI/TASI
--
--                            AND b.flag_possesso = 'S'
                    )
             AND ogge.oggetto = ogpr.oggetto
             AND prtr.tipo_tributo || '' = w_tipo_tributo
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
             AND ogco.cod_fiscale LIKE a_cod_fiscale
             AND a_ravvedimento = 'N'
             and molt.anno(+)            = a_anno_rif
             and molt.categoria_catasto(+)   =
                 f_dato_riog(ogco.cod_fiscale,ogco.oggetto_pratica,a_anno_rif,'CA')
             and rire.anno     (+)       = a_anno_rif
             and rire.tipo_oggetto (+)   = ogpr.tipo_oggetto
      UNION ALL
      SELECT decode(ogco.flag_ab_principale,'S',-1,F_CALCOLA_ROTTURA_DEMO (ogco.oggetto_pratica,
                            ogpr.oggetto_pratica_rif_ap,
                            ogco.cod_fiscale,
                            ogco.flag_ab_principale,
                            a_anno_rif,
                            a_ravvedimento)) oggetto_rottura,
      --nvl(ogpr.oggetto_pratica_rif_ap,ogpr.oggetto_pratica)) oggetto_rottura,
             ogpr.tipo_oggetto,
             ogpr.pratica pratica_ogpr,
             ogpr.oggetto oggetto_ogpr,
             f_dato_riog (ogco.cod_fiscale,
                          ogco.oggetto_pratica,
                          a_anno_rif,
                          'CA')
                categoria_catasto_ogpr,
             ogpr.oggetto_pratica oggetto_pratica_ogpr,
             ogco.anno anno_ogco,
             ogco.cod_fiscale cod_fiscale_ogco,
             ogco.flag_possesso,
             DECODE (F_ABILITA_FUNZIONE('DETRAZIONE_MOBILE_POSS'), 'S',
                     ogco.perc_possesso,
                     nvl(ogco.perc_detrazione, 0)) --Carnate, Tresigallo, Formignana, Malnate
                perc,
             DECODE (ogco.anno, a_anno_rif, NVL (ogco.mesi_possesso, 12), 12)
                mesi_possesso,
             DECODE (ogco.anno, a_anno_rif, ogco.mesi_possesso_1sem, 6)
                mesi_possesso_1sem,
             ogco.flag_al_ridotta,
             DECODE (
                ogco.anno,
                a_anno_rif, DECODE (
                               ogco.flag_al_ridotta,
                               'S', NVL (ogco.mesi_aliquota_ridotta,
                                         NVL (ogco.mesi_possesso, 12)),
                               NVL (ogco.mesi_aliquota_ridotta, 0)),
                DECODE (ogco.flag_al_ridotta, 'S', 12, 0))
                mesi_aliquota_ridotta,
             ogco.flag_esclusione,
             DECODE (
                ogco.anno,
                a_anno_rif, DECODE (
                               ogco.flag_esclusione,
                               'S', NVL (ogco.mesi_esclusione,
                                         NVL (ogco.mesi_possesso, 12)),
                               NVL (ogco.mesi_esclusione, 0)),
                DECODE (ogco.flag_esclusione, 'S', 12, 0)),
             ogco.flag_riduzione,
             DECODE (
                ogco.anno,
                a_anno_rif, DECODE (
                               ogco.flag_riduzione,
                               'S', NVL (ogco.mesi_riduzione,
                                         NVL (ogco.mesi_possesso, 12)),
                               NVL (ogco.mesi_riduzione, 0)),
                DECODE (ogco.flag_riduzione, 'S', 12, 0))
                mesi_riduzione,
             ogco.flag_ab_principale flag_ab_principale,
             f_valore (ogpr.valore,
                       ogpr.tipo_oggetto,
                       prtr.anno,
                       a_anno_rif,
                       NVL (ogpr.categoria_catasto, ogge.categoria_catasto),
                       prtr.tipo_pratica,
                       ogpr.FLAG_VALORE_RIVALUTATO)
                valore,
             f_valore (ogpr.valore,
                       ogpr.tipo_oggetto,
                       prtr.anno,
                       a_anno_rif,
                       NVL (ogpr.categoria_catasto, ogge.categoria_catasto),
                       prtr.tipo_pratica,
                       ogpr.FLAG_VALORE_RIVALUTATO)
                valore_d,
             ogco.detrazione detrazione_ogco,
             ogge.categoria_catasto categoria_catasto_ogge,
             ogpr.IMM_STORICO,
             ogpr.oggetto_pratica_rif_ap,
             prtr.tipo_pratica,
             prtr.anno,
             ogco.tipo_rapporto,
             decode(ogpr.tipo_oggetto
                   ,1,nvl(molt.moltiplicatore,1)
                   ,3,decode(nvl(ogpr.imm_storico,'N')||to_char(sign(2012 - a_anno_rif))
                            ,'S1',100
                            ,nvl(molt.moltiplicatore,1)
                            )
                   ,1)     moltiplicatore,
             rire.aliquota aliquota_rivalutazione
        FROM oggetti ogge,
             pratiche_tributo prtr,
             oggetti_pratica ogpr,
             oggetti_contribuente ogco,
             rivalutazioni_rendita rire,
             moltiplicatori molt
       WHERE     ogco.tipo_rapporto = 'D'
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
             AND prtr.tipo_tributo || '' = w_tipo_tributo
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
             AND ogco.cod_fiscale LIKE a_cod_fiscale
             and molt.anno (+)           = a_anno_rif
             and molt.categoria_catasto(+)   =
                 f_dato_riog(ogco.cod_fiscale,ogco.oggetto_pratica,a_anno_rif,'CA')
             and rire.anno (+)           = a_anno_rif
             and rire.tipo_oggetto (+)   = ogpr.tipo_oggetto
      ORDER BY 8,1, 5 desc
      ;
   PROCEDURE SET_MADE (p_cod_fiscale          VARCHAR2,
                       p_detrazione_mobile    NUMBER,
                       p_det_mobile_1sem     NUMBER,
                       p_anno                 NUMBER,
                       p_tipo_tributo         VARCHAR2,
                       p_motivo_detrazione    NUMBER)
   IS
      w_made_exists      NUMBER;
      w_made_90_exists   NUMBER;
      w_detr_made        maggiori_detrazioni.detrazione%TYPE;
      w_detr_acc_made    maggiori_detrazioni.detrazione_acconto%TYPE;
      w_detr_base_made   maggiori_detrazioni.detrazione_base%TYPE;
      w_flag_made        maggiori_detrazioni.flag_detrazione_possesso%TYPE;
      w_mode_made        maggiori_detrazioni.motivo_detrazione%TYPE;
      w_note_made        maggiori_detrazioni.note%TYPE;
   BEGIN
     -- DBMS_OUTPUT.PUT_LINE('SET MADE 1');
      if nvl(p_detrazione_mobile,0) < 0 then
         return;
      end if;
      SELECT COUNT (*)
            ,count(decode(maggiori_detrazioni.motivo_detrazione,p_motivo_detrazione,1,null))
        INTO w_made_exists
           , w_made_90_exists
        FROM maggiori_detrazioni
       WHERE     cod_fiscale = p_cod_fiscale
             AND anno = p_anno
             AND tipo_tributo = p_tipo_tributo;
      --dbms_output.put_line ('p_detrazione_mobile ' || p_detrazione_mobile);
      IF w_made_exists > 0
      THEN
         if w_made_90_exists > 0 then
         -- Se la detrazione nell anno è quella del motivo detrazione che stiamo
         -- trattando la salviamo e poi la riemettiamo
         -- altrimenti non facciamo nulla
           BEGIN
              INSERT INTO detrazioni (anno,
                                      tipo_tributo,
                                      detrazione,
                                      detrazione_base)
                   VALUES (p_anno - 1000,
                           p_tipo_tributo,
                           0,
                           0);
           EXCEPTION
              WHEN DUP_VAL_ON_INDEX
              THEN
                 NULL;
              WHEN OTHERS
              THEN
                 IF SQLCODE = -20007
                 THEN
                    NULL;
                 ELSE
                    RAISE;
                 END IF;
           END;
           BEGIN
              SELECT detrazione,
                     detrazione_acconto,
                     detrazione_base,
                     flag_detrazione_possesso,
                     motivo_detrazione,
                     note
                INTO w_detr_made,
                     w_detr_acc_made,
                     w_detr_base_made,
                     w_flag_made,
                     w_mode_made,
                     w_note_made
                FROM maggiori_detrazioni
               WHERE     cod_fiscale = p_cod_fiscale
                     AND anno = p_anno
                     AND tipo_tributo = p_tipo_tributo;
              INSERT INTO maggiori_detrazioni (anno,
                                               cod_fiscale,
                                               detrazione,
                                               detrazione_acconto,
                                               detrazione_base,
                                               flag_detrazione_possesso,
                                               motivo_detrazione,
                                               note,
                                               tipo_tributo)
                   VALUES (p_anno - 1000,
                           p_cod_fiscale,
                           w_detr_made,
                           w_detr_acc_made,
                           w_detr_base_made,
                           w_flag_made,
                           w_mode_made,
                           w_note_made,
                           p_tipo_tributo);
           EXCEPTION
              WHEN DUP_VAL_ON_INDEX
              THEN
                 NULL;
              WHEN OTHERS
              THEN
                 IF SQLCODE = -20007
                 THEN
                    NULL;
                 ELSE
                    RAISE;
                 END IF;
           END;
           UPDATE maggiori_detrazioni
              SET detrazione = p_detrazione_mobile,
                  motivo_detrazione = p_motivo_detrazione,
                  detrazione_acconto =nvl(p_det_mobile_1sem,0),
                  detrazione_base = NULL,
                  flag_detrazione_possesso = NULL,
                  note = NULL
            WHERE     cod_fiscale = p_cod_fiscale
                  AND anno = p_anno
                  AND tipo_tributo = p_tipo_tributo;
         end if;
      ELSE
         INSERT INTO maggiori_detrazioni (anno,
                                          cod_fiscale,
                                          detrazione,
                                          detrazione_acconto,
                                          detrazione_base,
                                          flag_detrazione_possesso,
                                          motivo_detrazione,
                                          note,
                                          tipo_tributo)
              VALUES (p_anno,
                      p_cod_fiscale,
                      p_detrazione_mobile,
                      nvl(p_det_mobile_1sem,0),
                      NULL,
                      NULL,
                      p_motivo_detrazione,
                      NULL,
                      p_tipo_tributo);
      END IF;
   EXCEPTION
   WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(-20999, 'Errore in inserimento Maggiori detrazioni ('||sqlerrm||')');
   END; /*end SET_MADE*/
   PROCEDURE CALCOLA_DETRAZIONE
   ( p_cod_fiscale VARCHAR2
   , p_tipo_tributo VARCHAR2
   , p_anno_rif NUMBER, p_motivo_detrazione NUMBER, p_perc NUMBER
   , p_mesi_possesso NUMBER, p_mesi_possesso_1sem NUMBER
   , p_detrazione_mobile in out number, p_det_mobile_1sem in out number)
   IS
   w_dep_detrazione_mobile     detrazioni_mobili.detrazione%TYPE;
   BEGIN
   DBMS_OUTPUT.PUT_LINE(' rendita '||w_rendita_totale);
   DBMS_OUTPUT.PUT_LINE('  p_perc    '||p_perc);
   DBMS_OUTPUT.PUT_LINE(' p_mesi_possesso '||p_mesi_possesso);
      w_detrazione_mobile := 0;
      w_det_mobile_1sem := 0;
      BEGIN
      SELECT detrazione
        INTO w_dep_detrazione_mobile
        FROM detrazioni_mobili
       WHERE tipo_tributo = p_tipo_tributo
         AND anno = p_anno_rif
         AND motivo_detrazione = p_motivo_detrazione
         AND w_rendita_totale BETWEEN NVL (da_rendita, 0)
                                  AND NVL (a_rendita,
                                             999999999999999);
      EXCEPTION
       WHEN NO_DATA_FOUND THEN
          w_dep_detrazione_mobile := 0;
       WHEN OTHERS THEN
          raise_application_error(-20999, 'Errore in individuazione detrazione mobile ('||sqlerrm||')');
      END;
      IF w_dep_detrazione_mobile >= 0
      THEN
         w_dep_detrazione_mobile := (w_dep_detrazione_mobile * p_perc) / 100;
         p_detrazione_mobile :=
           (w_dep_detrazione_mobile / 12) * p_mesi_possesso;
--
-- VD (11/11/2014): modificato test su mesi possesso: si considerano solo quelli
--                  del primo semestre
--                  Aggiunto azzeramento variabile di I/O detrazione acconto
--                  in assenza di mesi di possesso I semestre
--
--       if p_mesi_possesso > 0 then
         if p_mesi_possesso_1sem > 0 then
            p_det_mobile_1sem := (w_dep_detrazione_mobile / 12) * p_mesi_possesso_1sem;
         else
            p_det_mobile_1sem := 0;
         end if;
DBMS_OUTPUT.PUT_LINE(' p_detrazione_mobile '||p_detrazione_mobile);
DBMS_OUTPUT.PUT_LINE(' p_det_mobile_1sem '||p_det_mobile_1sem);
--        SET_MADE (p_cod_fiscale,
--                          w_detrazione_mobile,
--                          w_det_mobile_1sem,
--                          p_anno_rif,
--                          p_tipo_tributo,
--                          p_motivo_detrazione);
      END IF;
   EXCEPTION
     WHEN OTHERS THEN
       RAISE;
   END; /*CALCOLA_E_REGISTRA*/
--
-- 17/04/2015 (VD): Funzione non più usata, sostituita con CALCOLO_RIOG_MULTIPLO
--
FUNCTION F_CALCOLA_RENDITA (p_oggetto NUMBER, p_mese NUMBER, p_anno NUMBER, p_valore NUMBER,
                            p_categoria VARCHAR2, p_tipo_oggetto NUMBER)
RETURN NUMBER
IS
nRendita number;
BEGIN
 --  DBMS_OUTPUT.PUT_LINE('F_CALCOLA_RENDITA 1');
   begin
      select nvl(riog.rendita,0)
        into nRendita
        from riferimenti_oggetto riog
       where riog.oggetto                = p_oggetto
         and riog.fine_validita         >= to_date('01'||
                                                   lpad(to_char(p_mese),2,'0')||
                                                   lpad(to_char(p_anno),4,'0'),'ddmmyyyy'
                                                  )
         and riog.inizio_validita       <= last_day(to_date('01'||
                                                            lpad(to_char(p_mese),2,'0')||
                                                            lpad(to_char(p_anno),4,'0'),'ddmmyyyy'
                                                           )
                                            )
      and least(last_day(to_date('01'||lpad(to_char(p_mese),2,'0')||lpad(to_char(p_anno),4,'0'),'ddmmyyyy'
                                   )
            ),riog.fine_validita) + 1 -
             greatest(to_date('01'||lpad(to_char(p_mese),2,'0')||lpad(to_char(p_anno),4,'0'),'ddmmyyyy'
                             ),riog.inizio_validita)
                                   >= 15
         and riog.inizio_validita   =
            (select max(rio2.inizio_validita)
               from riferimenti_oggetto rio2
              where rio2.oggetto           = riog.oggetto
                and rio2.inizio_validita  <= last_day(to_date('01'||
                                                              lpad(to_char(p_mese),2,'0')||
                                                              lpad(to_char(p_anno),4,'0'),'ddmmyyyy'
                                                             )
                                             )
                and rio2.fine_validita    >= to_date('01'||
                                                     lpad(to_char(p_mese),2,'0')||
                                                     lpad(to_char(p_anno),4,'0'),'ddmmyyyy'
                                                    )
             and least(last_day(to_date('01'||lpad(to_char(p_mese),2,'0')||lpad(to_char(p_anno),4,'0'),'ddmmyyyy'
                                  )
                   ),rio2.fine_validita) + 1 -
                    greatest(to_date('01'||lpad(to_char(p_mese),2,'0')||lpad(to_char(p_anno),4,'0'),'ddmmyyyy'
                                     ),rio2.inizio_validita)
                                            >= 15
          )
      ;
   exception
   when others then
      nRendita := null;
   end;
   if nRendita is null then
      nRendita := nvl(f_rendita (p_valore,
                            p_tipo_oggetto,
                            p_anno,
                            p_categoria), 0);
   end if;
   return nRendita;
END /*END F_CALCOLA_RENDITA*/;
/****************************
INIZIO
****************************/
BEGIN
    declare
    f_abilitata number;
   BEGIN
    select 1
      into f_abilitata
      from dual
     where F_ABILITA_FUNZIONE('DETRAZIONE_MOBILE') = 'S';
--      SELECT    LPAD (TO_CHAR (dage.pro_cliente), 3, '0')
--             || LPAD (TO_CHAR (dage.com_cliente), 3, '0')
--        INTO w_cod_istat
--        FROM dati_generali dage
--       WHERE    LPAD (TO_CHAR (dage.pro_cliente), 3, '0')
--             || LPAD (TO_CHAR (dage.com_cliente), 3, '0') IN ('108016' --Carnate
--                                                                      ,
--                                                              '038009' -- Formignana
--                                                                      ,
--                                                              '038024' -- Tresigallo
--                                                                      ,
--                                                              '017025' -- Bovezzo
--                                                              ,
--                                                              '012096' -- Malnate
--                                                              ,
--                                                              '015192' --San Donato Milanese
--                                                              ,
--                                                              '015175' --Pioltello
--                                                              ,
--                                                              '050029' --Pontedera
--                                                                  );
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN;
   END;
   -- Se non ci sono detrazioni mobili non si deve fare nulla
   DECLARE
      w_exists_demo   NUMBER := 0;
   BEGIN
      SELECT COUNT (*)
        INTO w_exists_demo
        FROM detrazioni_mobili
       WHERE anno = a_anno_rif
         AND tipo_tributo = w_tipo_tributo
         AND motivo_detrazione = w_motivo_detrazione;
      IF w_exists_demo = 0
      THEN
         RETURN;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN;
   END;
   BEGIN
      SELECT flag_pertinenze
        INTO w_flag_pertinenze
        FROM detrazioni
       WHERE anno = a_anno_rif AND tipo_tributo = w_tipo_tributo;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         raise_application_error (
            -20999,
               'Registrazione in Detrazioni assente per l''anno '
            || a_anno_rif
            || ' e tipo tributo '
            || w_tipo_tributo);
      WHEN OTHERS
      THEN
         RAISE;
   END;
   w_detrazione_mobile_tot := 0;
   w_det_mobile_1sem_tot := 0;
   FOR rec_ogco IN sel_ogco
   LOOP
   DBMS_OUTPUT.PUT_LINE('** oggetto '||rec_ogco.oggetto_ogpr);
      w_cod_fiscale := rec_ogco.cod_fiscale_ogco;
      IF w_cod_fiscale_precedente = ' '
      THEN
         w_cod_fiscale_precedente := w_cod_fiscale;
         w_oggetto_rottura_precedente := rec_ogco.oggetto_rottura;
      END IF;
      -- a cambio cf inserisco i valori in made  per quello precedente
      -- di cui ho appena finito di sommare le rendite
      IF w_cod_fiscale_precedente <> w_cod_fiscale
      THEN
         BEGIN
            DBMS_OUTPUT.PUT_LINE(' 1');
           CALCOLA_DETRAZIONE (w_cod_fiscale_precedente
                              , w_tipo_tributo
                              , a_anno_rif, w_motivo_detrazione, w_perc
                              , w_mesi_possesso,  w_mesi_possesso_1sem
                              , w_detrazione_mobile, w_det_mobile_1sem);
           w_detrazione_mobile_tot := w_detrazione_mobile_tot + nvl(w_detrazione_mobile,0);
           w_det_mobile_1sem_tot := w_det_mobile_1sem_tot + nvl(w_det_mobile_1sem,0);
           SET_MADE (w_cod_fiscale_precedente,
                     w_detrazione_mobile_tot,
                     w_det_mobile_1sem_tot,
                     a_anno_rif,
                     w_tipo_tributo,
                     w_motivo_detrazione);
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               NULL;
         END;
         w_rendita_totale := 0;
         w_perc := NULL;
         w_mesi_possesso := NULL;
         w_mesi_possesso_1sem := NULL;
         w_cod_fiscale_precedente := w_cod_fiscale;
         w_oggetto_rottura_precedente := rec_ogco.oggetto_rottura;
         w_detrazione_mobile_tot := 0;
         w_det_mobile_1sem_tot := 0;
      END IF;
      if w_oggetto_rottura_precedente <> rec_ogco.oggetto_rottura
      then
      DBMS_OUTPUT.PUT_lINE('ROTTURA');
         CALCOLA_DETRAZIONE (w_cod_fiscale_precedente
                            , w_tipo_tributo
                            , a_anno_rif, w_motivo_detrazione, w_perc
                            , w_mesi_possesso,  w_mesi_possesso_1sem
                            , w_detrazione_mobile, w_det_mobile_1sem);
         w_detrazione_mobile_tot := w_detrazione_mobile_tot + nvl(w_detrazione_mobile,0);
         DBMS_OUTPUT.PUT_lINE('ROTTURA w_detrazione_mobile_tot '||w_detrazione_mobile_tot);
         w_det_mobile_1sem_tot := w_det_mobile_1sem_tot + nvl(w_det_mobile_1sem,0);
         w_oggetto_rottura_precedente := rec_ogco.oggetto_rottura;
         w_rendita_totale := 0;
-- VD (11/11/2014): aggiunto azzeramento variabili abitazione principale
--
         w_perc := NULL;
         w_mesi_possesso := NULL;
         w_mesi_possesso_1sem := NULL;
      end if;
      IF rec_ogco.tipo_oggetto = 3
      THEN
         BEGIN
            SELECT detraz.det
              INTO w_esiste_det_ogco
              FROM (SELECT 'S' det
                      FROM detrazioni_ogco deog
                     WHERE     deog.cod_fiscale = w_cod_fiscale
                           AND deog.oggetto_pratica =
                                  rec_ogco.oggetto_pratica_ogpr
                           AND deog.anno = a_anno_rif
                           AND deog.tipo_tributo = w_tipo_tributo
                           AND NOT EXISTS
                                      (SELECT 'S'
                                         FROM aliquote_ogco alog
                                        WHERE     alog.cod_fiscale =
                                                     w_cod_fiscale
                                              AND tipo_tributo =
                                                     w_tipo_tributo
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
                      FROM detrazioni_ogco deog2, oggetti_pratica ogpr2
                     WHERE     deog2.cod_fiscale = w_cod_fiscale
                           AND deog2.oggetto_pratica =
                                  ogpr2.oggetto_pratica_rif_ap
                           AND deog2.anno = a_anno_rif
                           AND deog2.tipo_tributo = w_tipo_tributo
                           AND ogpr2.oggetto_pratica =
                                  rec_ogco.oggetto_pratica_ogpr
                           AND NOT EXISTS
                                      (SELECT 'S'
                                         FROM aliquote_ogco alog
                                        WHERE     alog.cod_fiscale =
                                                     w_cod_fiscale
                                              AND tipo_tributo =
                                                     w_tipo_tributo
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
     dbms_output.put_line ('w_cod_fiscale ' || w_cod_fiscale);
     dbms_output.put_line ('rec_ogco.tipo_oggetto ' || rec_ogco.tipo_oggetto);
     dbms_output.put_line ('rec_ogco.detrazione_ogco ' || rec_ogco.detrazione_ogco);
     dbms_output.put_line ('w_esiste_det_ogco ' || w_esiste_det_ogco);
     dbms_output.put_line ('w_rif_ap_ab_principale ' || w_rif_ap_ab_principale);
     Dbms_output.put_line ('w_flag_pertinenze ' || w_flag_pertinenze);
     dbms_output.put_line ('rec_ogco.categoria_catasto_ogpr ' || rec_ogco.categoria_catasto_ogpr);
      IF     rec_ogco.tipo_oggetto = 3
         AND (   rec_ogco.flag_ab_principale = 'S'
              OR rec_ogco.detrazione_ogco IS NOT NULL
              OR w_esiste_det_ogco = 'S'
              OR w_rif_ap_ab_principale = 'S' -- Serve per gestire le pertinenze con pertinenza_di
                                             )
         AND (   w_flag_pertinenze = 'S'
              OR (    w_flag_pertinenze IS NULL
                  AND rec_ogco.categoria_catasto_ogpr LIKE 'A%'))
      THEN
      DBMS_OUTPUT.PUT_LINE('CI SONO '||rec_ogco.OGGETTO_OGPR);
      DBMS_OUTPUT.PUT_LINE('CI SONO  rec_ogco.flag_ab_principale '|| rec_ogco.flag_ab_principale);
      DBMS_OUTPUT.PUT_LINE('CI SONO  w_rif_ap_ab_principale  '|| w_rif_ap_ab_principale );
      DBMS_OUTPUT.PUT_LINE('CI SONO  w_flag_pertinenze  '|| w_flag_pertinenze );
      DBMS_OUTPUT.PUT_LINE('CI SONO  rec_ogco.categoria_catasto_ogpr  '|| rec_ogco.categoria_catasto_ogpr );
         -- I dati per anno precedente l'anno di denuncia sono significativi solo se l'anno d'imposta e' uguale a quello di denuncia
         -- e solo se  il flag possesso e' nullo  (Piero 18/05/2006)
         if rec_ogco.anno_ogco = a_anno_rif and rec_ogco.flag_possesso is null then
            BEGIN
               select ltrim(max(nvl(ogco.flag_possesso,' ')))
                 into w_flag_possesso_prec
                 from oggetti_contribuente      ogco
                     ,oggetti_pratica           ogpr
                     ,pratiche_tributo          prtr
                where ogco.cod_fiscale                        = rec_ogco.cod_fiscale_ogco
                  and ogpr.oggetto                            = rec_ogco.oggetto_ogpr
                  and ogpr.oggetto_pratica                    = ogco.oggetto_pratica
                  and prtr.pratica                            = ogpr.pratica
                  and prtr.tipo_tributo||''                   = 'TASI'
                  and prtr.anno                               < rec_ogco.anno_ogco
                  and ogco.anno||ogco.tipo_rapporto||nvl(ogco.flag_possesso,'N')
                                                              =
                     (select max(b.anno||b.tipo_rapporto||nvl(b.flag_possesso,'N'))
                        from pratiche_tributo     c,
                             oggetti_contribuente b,
                             oggetti_pratica      a
                       where(    c.data_notifica             is not null
                             and c.tipo_pratica||''            = 'A'
                             and nvl(c.stato_accertamento,'D') = 'D'
                             and nvl(c.flag_denuncia,' ')      = 'S'
                             or  c.data_notifica              is null
                             and c.tipo_pratica||''            = 'D'
                            )
                         and c.pratica                         = a.pratica
                         and a.oggetto_pratica                 = b.oggetto_pratica
                         and c.tipo_tributo||''                = 'TASI'
                         and nvl(c.stato_accertamento,'D')     = 'D'
                         and c.anno                            < rec_ogco.anno_ogco
                         and b.cod_fiscale                     = ogco.cod_fiscale
                         and a.oggetto                         = rec_ogco.oggetto_ogpr
                     )
                 group by rec_ogco.oggetto_ogpr
               ;
            EXCEPTION
               WHEN NO_DATA_FOUND THEN
                  w_flag_possesso_prec   := null;
            END;
         else
             w_flag_possesso_prec := null;
         end if;
--
-- La determinazione dei mesi di possesso viene calcolata come per l'ICI
-- e il valore viene determinato con la procedure CALCOLO_RIOG_MULTIPLO
--
         w_perc := rec_ogco.perc;
         DBMS_OUTPUT.PUT_LINE('** W_PERC '||w_perc);
         w_mesi_possesso := nvl(rec_ogco.mesi_possesso,12);
         DBMS_OUTPUT.PUT_LINE('** w_mesi_possesso '||w_mesi_possesso);
         w_mesi_possesso_1sem := rec_ogco.mesi_possesso_1sem;
         DBMS_OUTPUT.PUT_LINE('** w_mesi_possesso_1sem '||w_mesi_possesso_1sem);
         w_mesi_esclusione := nvl(rec_ogco.mesi_esclusione,0);
         DBMS_OUTPUT.PUT_LINE('** w_mesi_esclusione '||w_mesi_esclusione);
         determina_mesi_possesso_ici(rec_ogco.flag_possesso, w_flag_possesso_prec, a_anno_rif, w_mesi_possesso - nvl(w_mesi_esclusione,0),
                                     w_mesi_possesso_1sem,w_data_inizio_possesso, w_data_fine_possesso, w_data_inizio_possesso_1s,
                                     w_data_fine_possesso_1s);
--
         BEGIN
           CALCOLO_RIOG_MULTIPLO(rec_ogco.oggetto_ogpr
                                ,rec_ogco.valore
                                ,w_data_inizio_possesso
                                ,w_data_fine_possesso
                                ,w_data_inizio_possesso_1s
                                ,w_data_fine_possesso_1s
                                ,rec_ogco.moltiplicatore
                                ,rec_ogco.aliquota_rivalutazione
                                ,rec_ogco.tipo_oggetto
                                ,rec_ogco.anno_titr
                                ,a_anno_rif
                                ,rec_ogco.imm_storico
                                ,w_valore
                                ,w_valore_1s
                                );
dbms_output.put_line('w_valore '||w_valore);
            w_rendita_totale :=
                 w_rendita_totale
               + nvl(f_rendita (w_valore,
                                rec_ogco.tipo_oggetto,
                                a_anno_rif,
                                rec_ogco.categoria_catasto_ogpr), 0);
dbms_output.put_line('*w_rendita_totale '||w_rendita_totale);
              --f_rendita (rec_ogco.valore_d,
              --           rec_ogco.tipo_oggetto,
              --           a_anno_rif,
              --           rec_ogco.categoria_catasto_ogpr);
         END;
      END IF;
   END LOOP;
            --RAISE_APPLICATION_ERROR(-20999,'RENDITA '||w_rendita_totale);
   -- faccio il calcolo per l'ultimo cf del cursore
   IF w_cod_fiscale IS NOT NULL
   THEN
      BEGIN
      DBMS_OUTPUT.PUT_lINE('2 pre w_detrazione_mobile_tot '||w_detrazione_mobile_tot);
           CALCOLA_DETRAZIONE (w_cod_fiscale
                              , w_tipo_tributo
                              , a_anno_rif, w_motivo_detrazione, w_perc
                              , w_mesi_possesso,  w_mesi_possesso_1sem
                              , w_detrazione_mobile, w_det_mobile_1sem);
           DBMS_OUTPUT.PUT_lINE('2 w_detrazione_mobile '||w_detrazione_mobile);
           w_detrazione_mobile_tot := w_detrazione_mobile_tot + nvl(w_detrazione_mobile,0);
           DBMS_OUTPUT.PUT_lINE('2 w_detrazione_mobile_tot '||w_detrazione_mobile_tot);
           w_det_mobile_1sem_tot := w_det_mobile_1sem_tot + nvl(w_det_mobile_1sem,0);
           SET_MADE (w_cod_fiscale,
                     w_detrazione_mobile_tot,
                     w_det_mobile_1sem_tot,
                     a_anno_rif,
                     w_tipo_tributo,
                     w_motivo_detrazione);
      END;
   END IF;
EXCEPTION
   WHEN errore
   THEN
   --   dbms_output.put_line ('w_errore ' || w_errore);
      ROLLBACK;
      RAISE_APPLICATION_ERROR (-20999,
                               w_errore || ' (' || SQLERRM || ')',
                               TRUE);
   WHEN OTHERS
   THEN
      ROLLBACK;
      RAISE_APPLICATION_ERROR (
         -20999,
            'Errore in Calcolo Detrazioni Mobili TASI di '
         || w_cod_fiscale
         || ' '
         || '('
         || SQLERRM
         || ')');
END;
/* End Procedure: CALCOLO_DETRAZIONI_MOBILI_TASI */
/

