--liquibase formatted sql 
--changeset abrandolini:20250326_152423_piano_finanziario stripComments:false runOnChange:true 
 
create or replace procedure PIANO_FINANZIARIO
AS
   w_anno_elaborazione   NUMBER;
   w_codice_fam          VARCHAR2 (10)                 := 'FAM_';
   w_codice_cat          VARCHAR2 (10)                 := 'CAT_';
   w_codice_cota         VARCHAR2 (10)                 := 'COSTO_';
   w_tipo_comune         VARCHAR2 (10);
   w_area                VARCHAR2 (10);
   w_tributo             codici_tributo.tributo%TYPE;
   w_des_comune VARCHAR2(60);
BEGIN
   w_anno_elaborazione := f_valore_wpf (0, 1, 'ANNO');
   IF w_anno_elaborazione IS NULL
   THEN
      raise_application_error
         (-20999,
          'Non è stato indicato l''anno dell''elaborazionde del Piano Finanziario'
         );
   END IF;
   w_tipo_comune := f_valore_wpf (w_anno_elaborazione, 1, 'TIPO_COM');
   IF w_tipo_comune IS NULL
   THEN
      raise_application_error
         (-20999,
          'Non è stato indicato il tipo di comune dell''elaborazionde del Piano Finanziario'
         );
   END IF;
   w_area := f_valore_wpf (w_anno_elaborazione, 1, 'AREA');
   IF w_area IS NULL
   THEN
      raise_application_error
         (-20999,
          'Non è stato indicata l''area dell''elaborazionde del Piano Finanziario'
         );
   END IF;
   w_tributo := f_valore_wpf (w_anno_elaborazione, 1, 'TRIBUTO');
   IF w_tributo IS NULL
   THEN
      raise_application_error
         (-20999,
          'Non è stato indicata il tributo dell''elaborazionde del Piano Finanziario'
         );
   END IF;
   BEGIN
     SELECT acom.denominazione
      INTO w_des_comune
      FROM dati_generali dage, ad4_comuni acom
     WHERE acom.provincia_stato = dage.pro_cliente
        AND acom.comune            = dage.com_cliente
;
   EXCEPTION
     WHEN OTHERS THEN
       raise_application_error
         (-20999,'Manca la decodifica del comune ');
    END;
   set_valore_wpf (w_anno_elaborazione,
                      1,
                      'COMUNE',
                      w_des_comune
                     );
   BEGIN
     DELETE wrk_piano_finanziario
      WHERE anno = w_anno_elaborazione
         AND (codice LIKE '' OR codice LIKE '' OR codice LIKE '')
          ;
   EXCEPTION
     WHEN OTHERS THEN
       raise_application_error
         (-20999,'Errore in delete wrk_piano_finanziario ');
    END;
   FOR coda IN (SELECT   DECODE (w_tipo_comune,
                                 'INF', coeff_adattamento,
                                 coeff_adattamento_sup
                                ) coeff_adattamento,
                         coeff_produttivita_min, coeff_produttivita_max,
                         coeff_produttivita_med, numero_familiari
                    FROM coeff_domestici_area
                   WHERE area = w_area
                ORDER BY numero_familiari)
   LOOP
      set_valore_wpf (w_anno_elaborazione,
                      1,
                      w_codice_fam || coda.numero_familiari,
                      coda.coeff_adattamento
                     );
      set_valore_wpf (w_anno_elaborazione,
                      2,
                      w_codice_fam || coda.numero_familiari,
                      coda.coeff_produttivita_min
                     );
      set_valore_wpf (w_anno_elaborazione,
                      3,
                      w_codice_fam || coda.numero_familiari,
                      coda.coeff_produttivita_max
                     );
      set_valore_wpf (w_anno_elaborazione,
                      4,
                      w_codice_fam || coda.numero_familiari,
                      coda.coeff_produttivita_med
                     );
   END LOOP;
   FOR cnda IN (SELECT   coeff_potenziale_min, coeff_potenziale_max,
                         coeff_produzione_min, coeff_produzione_max,
                         categoria
                    FROM coeff_non_domestici_area
                   WHERE tributo = w_tributo
                     AND tipo_comune = w_tipo_comune
                     AND area = w_area
                ORDER BY categoria)
   LOOP
      set_valore_wpf (w_anno_elaborazione,
                      1,
                      w_codice_cat || cnda.categoria,
                      cnda.coeff_potenziale_min
                     );
      set_valore_wpf (w_anno_elaborazione,
                      2,
                      w_codice_cat || cnda.categoria,
                      cnda.coeff_potenziale_max
                     );
      set_valore_wpf (w_anno_elaborazione,
                      3,
                      w_codice_cat || cnda.categoria,
                      cnda.coeff_produzione_min
                     );
      set_valore_wpf (w_anno_elaborazione,
                      4,
                      w_codice_cat || cnda.categoria,
                      cnda.coeff_produzione_max
                     );
   END LOOP;
   FOR cota IN (SELECT   cota.sequenza, cota.tipo_costo||' - '||tics.descrizione descrizione, cota.costo_fisso, cota.costo_variabile
                    FROM costi_tarsu cota, tipi_costo tics
                   WHERE cota.anno = w_anno_elaborazione
                     AND cota.tipo_costo = tics.tipo_costo
                ORDER BY sequenza)
   LOOP
      set_valore_wpf (w_anno_elaborazione,
                      1,
                      w_codice_cota || cota.sequenza,
                      cota.descrizione
                     );
      set_valore_wpf (w_anno_elaborazione,
                      2,
                      w_codice_cota || cota.sequenza,
                      cota.costo_fisso
                     );
      set_valore_wpf (w_anno_elaborazione,
                      3,
                      w_codice_cota || cota.sequenza,
                      cota.costo_variabile
                     );
   END LOOP;
   -- Utenze Non Domestiche --
   FOR ogva IN
        (SELECT decode(sign(cate.categoria - 1000)
                                 ,1, cate.categoria - 1000
                                 ,decode(sign(cate.categoria - 100)
                                           ,1, cate.categoria - 100
                                 ,cate.categoria
                                            ))                      categoria
              , COUNT (1)                    tot
              , SUM (ogpr.consistenza)       cons
           FROM oggetti_validita ogva
              , oggetti_pratica    ogpr
              , categorie          cate
          WHERE ogva.tipo_tributo        = 'TARSU'
            AND ogva.flag_ab_principale IS NULL
            AND ogva.oggetto_pratica     = ogpr.oggetto_pratica
            AND ogpr.categoria           = cate.categoria
            AND ogpr.tributo             = cate.tributo
            AND cate.flag_domestica     IS NULL
            AND ogpr.tipo_occupazione    = 'P'
            AND ogpr.flag_contenzioso   IS NULL
--            and w_anno_elaborazione between nvl(to_number(to_char(ogva.dal,'yyyy')),1900)
--                                                         and nvl(to_number(to_char(ogva.al,'yyyy')),9999)
            AND DECODE (w_anno_elaborazione,
                        TO_CHAR (SYSDATE, 'YYYY'), TRUNC (SYSDATE),
                        TO_DATE ('01/01/' || w_anno_elaborazione,
                                 'DD/MM/YYYY')
                       ) BETWEEN ogva.dal
                             AND NVL (ogva.al,
                                      TO_DATE ('31/12/9999', 'dd/mm/yyyy')
                                     )
            AND ogpr.tributo||'' = w_tributo
       GROUP BY decode(sign(cate.categoria - 1000)
                                 ,1, cate.categoria - 1000
                                 ,decode(sign(cate.categoria - 100)
                                           ,1, cate.categoria - 100
                                 ,cate.categoria
                                            ))
       ORDER BY decode(sign(cate.categoria - 1000)
                                 ,1, cate.categoria - 1000
                                 ,decode(sign(cate.categoria - 100)
                                           ,1, cate.categoria - 100
                                 ,cate.categoria
                                            )))
   LOOP
      set_valore_wpf (w_anno_elaborazione,
                      1,
                      'D_CAT_' || ogva.categoria,
                      ogva.tot
                     );
      set_valore_wpf (w_anno_elaborazione,
                      2,
                      'D_CAT_' || ogva.categoria,
                      ogva.cons
                     );
   END LOOP;
   -- Utenze Domestiche con Numero Familiari e Abitazione Principale --
   FOR ogva IN
        (SELECT decode(faso.numero_familiari,1,1,2,2,3,3,4,4,5,5,6)  numero_familiari
              , COUNT (1) tot,
                SUM (ogpr.consistenza) cons
           FROM soggetti sogg,
                familiari_soggetto faso,
                contribuenti cont,
                oggetti_validita ogva,
                oggetti_pratica ogpr,
                categorie cate
          WHERE sogg.ni = cont.ni
            AND cont.cod_fiscale = ogva.cod_fiscale
            AND ogva.tipo_tributo = 'TARSU'
            AND ogva.flag_ab_principale IS NOT NULL
            AND faso.ni = sogg.ni
            AND faso.anno = w_anno_elaborazione
            AND faso.dal =
                   (SELECT MAX (fas2.dal)
                      FROM familiari_soggetto fas2
                     WHERE fas2.ni = sogg.ni
                       AND fas2.anno = w_anno_elaborazione)
            AND ogva.oggetto_pratica = ogpr.oggetto_pratica
            AND ogpr.tipo_occupazione = 'P'
            AND ogpr.flag_contenzioso IS NULL
            AND DECODE (w_anno_elaborazione,
                        TO_CHAR (SYSDATE, 'YYYY'), TRUNC (SYSDATE),
                        TO_DATE ('01/01/' || w_anno_elaborazione,
                                 'DD/MM/YYYY')
                       ) BETWEEN ogva.dal
                             AND NVL (ogva.al,
                                      TO_DATE ('31/12/9999', 'dd/mm/yyyy')
                                     )
            AND ogpr.categoria           = cate.categoria
            AND ogpr.tributo             = cate.tributo
            AND cate.flag_domestica      IS NOT NULL
            AND ogpr.tributo||''         = w_tributo
       GROUP BY decode(faso.numero_familiari,1,1,2,2,3,3,4,4,5,5,6)
       ORDER BY decode(faso.numero_familiari,1,1,2,2,3,3,4,4,5,5,6))
   LOOP
      set_valore_wpf (w_anno_elaborazione,
                      1,
                      'D_FAM_' || ogva.numero_familiari,
                      ogva.tot
                     );
      set_valore_wpf (w_anno_elaborazione,
                      2,
                      'D_FAM_' || ogva.numero_familiari,
                      ogva.cons
                     );
   END LOOP;
   -- Utenze Domestiche con Numero Familiari e Senza Abitazione Principale --
   FOR ogva IN
        (SELECT decode(ogpr.numero_familiari,1,1,2,2,3,3,4,4,5,5,6)  numero_familiari
              , COUNT (1) tot
              , SUM (ogpr.consistenza) cons
           FROM oggetti_validita ogva,
                oggetti_pratica ogpr,
                categorie cate
          WHERE ogva.tipo_tributo = 'TARSU'
            AND ogva.flag_ab_principale IS NULL
            AND ogpr.numero_familiari   is not null
            AND ogva.oggetto_pratica = ogpr.oggetto_pratica
            AND ogpr.tipo_occupazione = 'P'
            AND ogpr.flag_contenzioso IS NULL
            AND DECODE (w_anno_elaborazione,
                        TO_CHAR (SYSDATE, 'YYYY'), TRUNC (SYSDATE),
                        TO_DATE ('01/01/' || w_anno_elaborazione,
                                 'DD/MM/YYYY')
                       ) BETWEEN ogva.dal
                             AND NVL (ogva.al,
                                      TO_DATE ('31/12/9999', 'dd/mm/yyyy')
                                     )
            AND ogpr.categoria           = cate.categoria
            AND ogpr.tributo             = cate.tributo
            AND cate.flag_domestica      IS NOT NULL
            AND ogpr.tributo||''         = w_tributo
       GROUP BY decode(ogpr.numero_familiari,1,1,2,2,3,3,4,4,5,5,6)
       ORDER BY decode(ogpr.numero_familiari,1,1,2,2,3,3,4,4,5,5,6))
   LOOP
      set_valore_wpf (w_anno_elaborazione,
                      1,
                      'DF_FAM_' || ogva.numero_familiari,
                      ogva.tot
                     );
      set_valore_wpf (w_anno_elaborazione,
                      2,
                      'DF_FAM_' || ogva.numero_familiari,
                      ogva.cons
                     );
   END LOOP;
   -- Componenti Superficie per Domestiche senza Numero Familiari --
   FOR ogva IN
      (SELECT   cosu.numero_familiari
              , COUNT (1)   tot
              , SUM (ogpr.consistenza) cons
           FROM oggetti_validita       ogva
              , oggetti_pratica        ogpr
              , categorie              cate
              , componenti_superficie  cosu
          WHERE ogva.tipo_tributo        = 'TARSU'
            AND ogva.flag_ab_principale IS NULL
            AND ogva.oggetto_pratica     = ogpr.oggetto_pratica
            AND ogpr.categoria           = cate.categoria
            AND ogpr.tributo             = cate.tributo
            AND ogpr.tributo||''         = w_tributo
            and ogpr.numero_familiari   IS NULL
            AND cate.flag_domestica     IS NOT NULL
            AND ogpr.tipo_occupazione    = 'P'
            AND ogpr.flag_contenzioso   IS NULL
            AND DECODE (w_anno_elaborazione,
                        TO_CHAR (SYSDATE, 'YYYY'), TRUNC (SYSDATE),
                        TO_DATE ('01/01/' || w_anno_elaborazione,
                                 'DD/MM/YYYY')
                       ) BETWEEN ogva.dal
                             AND NVL (ogva.al,
                                      TO_DATE ('31/12/9999', 'dd/mm/yyyy')
                                     )
            AND cosu.anno                = w_anno_elaborazione
            AND ogpr.consistenza    BETWEEN cosu.da_consistenza
                                        AND cosu.a_consistenza
       GROUP BY cosu.numero_familiari
       ORDER BY cosu.numero_familiari
            )
   LOOP
      set_valore_wpf (w_anno_elaborazione,
                      1,
                      'DS_FAM_' || ogva.numero_familiari,
                      ogva.tot
                     );
      set_valore_wpf (w_anno_elaborazione,
                      2,
                      'DS_FAM_' || ogva.numero_familiari,
                      ogva.cons
                     );
   END LOOP;
   COMMIT;
EXCEPTION
   WHEN OTHERS
   THEN
      ROLLBACK;
      RAISE;
END;
/* End Procedure: PIANO_FINANZIARIO */
/

