--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_web_calcolo_individuale stripComments:false runOnChange:true 
 
create or replace function F_WEB_CALCOLO_INDIVIDUALE
   (
   a_pratica         NUMBER,
   a_tipo_tributo    VARCHAR2,
   a_tipo_calcolo    VARCHAR2,
   a_cod_fiscale     VARCHAR2,
   a_anno            NUMBER,
   a_utente          VARCHAR2)
   RETURN NUMBER
IS
   a_id_wcin                   NUMBER;
   a_dep_terreni               NUMBER;
   a_dep_terreni_erar          NUMBER;
   a_acconto_terreni           NUMBER;
   a_saldo_terreni             NUMBER;
   a_dep_aree                  NUMBER;
   a_dep_aree_erar             NUMBER;
   a_acconto_aree              NUMBER;
   a_saldo_aree                NUMBER;
   a_dep_ab                    NUMBER;
   a_acconto_ab                NUMBER;
   a_saldo_ab                  NUMBER;
   a_dep_altri                 NUMBER;
   a_dep_altri_erar            NUMBER;
   a_acconto_altri             NUMBER;
   a_saldo_altri               NUMBER;
   a_acconto_detrazione        NUMBER;
   a_saldo_detrazione          NUMBER;
   a_totale_terreni            NUMBER;
   a_numero_fabbricati         NUMBER;
   a_acconto_terreni_erar      NUMBER;
   a_saldo_terreni_erar        NUMBER;
   a_acconto_aree_erar         NUMBER;
   a_saldo_aree_erar           NUMBER;
   a_acconto_altri_erar        NUMBER;
   a_saldo_altri_erar          NUMBER;
   a_dep_rurali                NUMBER;
   a_acconto_rurali            NUMBER;
   a_saldo_rurali              NUMBER;
   a_num_fabbricati_ab         NUMBER;
   a_num_fabbricati_rurali     NUMBER;
   a_num_fabbricati_altri      NUMBER;
   a_dep_uso_prod              NUMBER;
   a_dep_uso_prod_erar         NUMBER;
   a_acconto_uso_prod          NUMBER;
   a_saldo_uso_prod            NUMBER;
   a_num_fabbricati_uso_prod   NUMBER;
   a_acconto_uso_prod_erar     NUMBER;
   a_saldo_uso_prod_erar       NUMBER;
   a_saldo_detrazione_std      NUMBER;
   a_acconto_fabb_merce        NUMBER;
   a_saldo_fabb_merce          NUMBER;
   a_num_fabbricati_merce      NUMBER;
   a_dep_fabb_merce            NUMBER;
   a_flag_versamenti           VARCHAR2(1);
BEGIN
   calcolo_individuale (a_pratica,
                        a_tipo_calcolo,
                        a_dep_terreni,
                        a_acconto_terreni,
                        a_saldo_terreni,
                        a_dep_aree,
                        a_acconto_aree,
                        a_saldo_aree,
                        a_dep_ab,
                        a_acconto_ab,
                        a_saldo_ab,
                        a_dep_altri,
                        a_acconto_altri,
                        a_saldo_altri,
                        a_acconto_detrazione,
                        a_saldo_detrazione,
                        a_totale_terreni,
                        a_numero_fabbricati,
                        a_acconto_terreni_erar,
                        a_saldo_terreni_erar,
                        a_acconto_aree_erar,
                        a_saldo_aree_erar,
                        a_acconto_altri_erar,
                        a_saldo_altri_erar,
                        a_dep_rurali,
                        a_acconto_rurali,
                        a_saldo_rurali,
                        a_num_fabbricati_ab,
                        a_num_fabbricati_rurali,
                        a_num_fabbricati_altri,
                        a_acconto_uso_prod,
                        a_saldo_uso_prod,
                        a_num_fabbricati_uso_prod,
                        a_acconto_uso_prod_erar,
                        a_saldo_uso_prod_erar,
                        a_saldo_detrazione_std,
                        a_acconto_fabb_merce,
                        a_saldo_fabb_merce,
                        a_num_fabbricati_merce,
                        a_dep_uso_prod,
                        a_dep_uso_prod_erar,
                        a_dep_terreni_erar,
                        a_dep_aree_erar,
                        a_dep_altri_erar,
                        a_dep_fabb_merce,
                        a_flag_versamenti);
   DELETE web_calcolo_individuale
    WHERE PRATICA = a_pratica;
   INSERT INTO web_calcolo_individuale (pratica,
                                        tipo_tributo,
                                        cod_fiscale,
                                        anno,
                                        utente,
                                        tipo_calcolo,
                                        numero_fabbricati,
                                        totale_terreni_ridotti,
                                        saldo_detrazione_std)
        VALUES (a_pratica,
                a_tipo_tributo,
                a_cod_fiscale,
                a_anno,
                a_utente,
                a_tipo_calcolo,
                a_numero_fabbricati,
                a_totale_terreni,
                a_saldo_detrazione_std);
   SELECT id_calcolo_individuale
     INTO a_id_wcin
     FROM web_calcolo_individuale
    WHERE     cod_fiscale = a_cod_fiscale
          AND anno = a_anno
          AND tipo_tributo = a_tipo_tributo
          AND tipo_calcolo = a_tipo_calcolo
          AND utente = a_utente
          AND pratica = a_pratica;
   --dettaglio TERRENI
   INSERT INTO web_calcolo_dettagli (ID_CALCOLO_INDIVIDUALE,
                                     UTENTE,
                                     TIPO_OGGETTO,
                                     VERS_ACCONTO,
                                     VERS_ACCONTO_ERAR,
                                     ACCONTO,
                                     SALDO,
                                     ACCONTO_ERAR,
                                     SALDO_ERAR)
        VALUES (a_id_wcin,
                a_utente,
                'TERRENO',
                a_dep_terreni,
                a_dep_terreni_erar,
                a_acconto_terreni,
                a_saldo_terreni,
                a_acconto_terreni_erar,
                a_saldo_terreni_erar);
   -- dettaglio AREE
   INSERT INTO WEB_CALCOLO_DETTAGLI (ID_CALCOLO_INDIVIDUALE,
                                     UTENTE,
                                     TIPO_OGGETTO,
                                     VERS_ACCONTO,
                                     VERS_ACCONTO_ERAR,
                                     ACCONTO,
                                     SALDO,
                                     ACCONTO_ERAR,
                                     SALDO_ERAR)
        VALUES (a_id_wcin,
                a_utente,
                'AREA',
                a_dep_AREE,
                a_dep_AREE_erar,
                a_acconto_AREE,
                a_saldo_AREE,
                a_acconto_AREE_erar,
                a_saldo_AREE_erar);
   --dettaglio ABITAZIONE PRINCIPALE
   INSERT INTO WEB_CALCOLO_DETTAGLI (ID_CALCOLO_INDIVIDUALE,
                                     UTENTE,
                                     TIPO_OGGETTO,
                                     VERS_ACCONTO,
                                     ACCONTO,
                                     SALDO,
                                     NUM_FABBRICATI)
        VALUES (a_id_wcin,
                a_utente,
                'ABITAZIONE_PRINCIPALE',
                a_dep_ab,
                a_acconto_ab,
                a_saldo_ab,
                a_num_fabbricati_ab);
   --dettaglio ALTRO FABBRICATO
   INSERT INTO WEB_CALCOLO_DETTAGLI (ID_CALCOLO_INDIVIDUALE,
                                     UTENTE,
                                     TIPO_OGGETTO,
                                     VERS_ACCONTO,
                                     VERS_ACCONTO_ERAR,
                                     ACCONTO,
                                     SALDO,
                                     ACCONTO_ERAR,
                                     SALDO_ERAR,
                                     NUM_FABBRICATI)
        VALUES (a_id_wcin,
                a_utente,
                'ALTRO_FABBRICATO',
                a_dep_altri,
                a_dep_altri_erar,
                a_acconto_altri,
                a_saldo_altri,
                a_acconto_altri_erar,
                a_saldo_altri_erar,
                a_num_fabbricati_altri);
   --dettaglio RURALE
   INSERT INTO WEB_CALCOLO_DETTAGLI (ID_CALCOLO_INDIVIDUALE,
                                     UTENTE,
                                     TIPO_OGGETTO,
                                     VERS_ACCONTO,
                                     ACCONTO,
                                     SALDO,
                                     NUM_FABBRICATI)
        VALUES (a_id_wcin,
                a_utente,
                'RURALE',
                a_dep_rurali,
                a_acconto_rurali,
                a_saldo_rurali,
                a_num_fabbricati_rurali);
   --dettaglio FABBRICATO D
   INSERT INTO WEB_CALCOLO_DETTAGLI (ID_CALCOLO_INDIVIDUALE,
                                     UTENTE,
                                     TIPO_OGGETTO,
                                     VERS_ACCONTO,
                                     VERS_ACCONTO_ERAR,
                                     ACCONTO,
                                     SALDO,
                                     ACCONTO_ERAR,
                                     SALDO_ERAR,
                                     NUM_FABBRICATI)
        VALUES (a_id_wcin,
                a_utente,
                'FABBRICATO_D',
                a_dep_uso_prod,
                a_dep_uso_prod_erar,
                a_acconto_uso_prod,
                a_saldo_uso_prod,
                a_acconto_uso_prod_erar,
                a_saldo_uso_prod_erar,
                a_num_fabbricati_uso_prod);
   --dettaglio FABBRICATI MERCE
   INSERT INTO WEB_CALCOLO_DETTAGLI (ID_CALCOLO_INDIVIDUALE,
                                     UTENTE,
                                     TIPO_OGGETTO,
                                     VERS_ACCONTO,
                                     ACCONTO,
                                     SALDO,
                                     NUM_FABBRICATI)
        VALUES (a_id_wcin,
                a_utente,
                'FABBRICATO_MERCE',
                to_number(null), --a_dep_ab,
                a_acconto_fabb_merce,
                a_saldo_fabb_merce,
                a_num_fabbricati_merce);
   --dettaglio DETRAZIONE
   INSERT INTO WEB_CALCOLO_DETTAGLI (ID_CALCOLO_INDIVIDUALE,
                                     UTENTE,
                                     TIPO_OGGETTO,
                                     ACCONTO,
                                     SALDO)
        VALUES (a_id_wcin,
                a_utente,
                'DETRAZIONE',
                a_acconto_detrazione,
                a_saldo_detrazione);
   RETURN a_id_wcin;
END;
/* End Function: F_WEB_CALCOLO_INDIVIDUALE */
/

