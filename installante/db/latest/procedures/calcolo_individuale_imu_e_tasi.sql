--liquibase formatted sql 
--changeset abrandolini:20250326_152423_calcolo_individuale_imu_e_tasi stripComments:false runOnChange:true 
 
create or replace procedure CALCOLO_INDIVIDUALE_IMU_E_TASI
/*************************************************************************
 Versione  Data              Autore    Descrizione
 3         21/10/2020        VD        Modifiche per cambio parametri
                                       CALCOLO_INDIVIDUALE
 2      07/08/2020        VD        IMU - Aggiunta gestione fabbricati
                                       merce
 1         17/08/2015        SC        Individua le
                                       pratiche K IMU e TASI
                                       del cf passato per l'anno passato.
                                       Se non le trova entrambe da errore.
                                       Se le trova, per ognuna
                                       esegue il calcolo e restituisce
                                       nelle var in output i valori.
*************************************************************************/
(a_cf                             IN     VARCHAR2,
 a_anno                           IN     NUMBER,
 a_tipo_calcolo                   IN     VARCHAR2,
 a_dep_terreni_ici                IN OUT NUMBER,
 a_acconto_terreni_ici            IN OUT NUMBER,
 a_saldo_terreni_ici              IN OUT NUMBER,
 a_dep_aree_ici                   IN OUT NUMBER,
 a_acconto_aree_ici               IN OUT NUMBER,
 a_saldo_aree_ici                 IN OUT NUMBER,
 a_dep_ab_ici                     IN OUT NUMBER,
 a_acconto_ab_ici                 IN OUT NUMBER,
 a_saldo_ab_ici                   IN OUT NUMBER,
 a_dep_altri_ici                  IN OUT NUMBER,
 a_acconto_altri_ici              IN OUT NUMBER,
 a_saldo_altri_ici                IN OUT NUMBER,
 a_acconto_detrazione_ici         IN OUT NUMBER,
 a_saldo_detrazione_ici           IN OUT NUMBER,
 a_totale_terreni_ici             IN OUT NUMBER,
 a_numero_fabbricati_ici          IN OUT NUMBER,
 a_acconto_terreni_erar_ici       IN OUT NUMBER,
 a_saldo_terreni_erar_ici         IN OUT NUMBER,
 a_acconto_aree_erar_ici          IN OUT NUMBER,
 a_saldo_aree_erar_ici            IN OUT NUMBER,
 a_acconto_altri_erar_ici         IN OUT NUMBER,
 a_saldo_altri_erar_ici           IN OUT NUMBER,
 a_dep_rurali_ici                 IN OUT NUMBER,
 a_acconto_rurali_ici             IN OUT NUMBER,
 a_saldo_rurali_ici               IN OUT NUMBER,
 a_num_fabbricati_ab_ici          IN OUT NUMBER,
 a_num_fabbricati_rurali_ici      IN OUT NUMBER,
 a_num_fabbricati_altri_ici       IN OUT NUMBER,
 a_acconto_uso_prod_ici           IN OUT NUMBER,
 a_saldo_uso_prod_ici             IN OUT NUMBER,
 a_num_fabbricati_uso_prod_ici    IN OUT NUMBER,
 a_acconto_uso_prod_erar_ici      IN OUT NUMBER,
 a_saldo_uso_prod_erar_ici        IN OUT NUMBER,
 a_saldo_detrazione_std_ici       IN OUT NUMBER,
 a_acconto_fabb_merce_ici         IN OUT NUMBER,
 a_saldo_fabb_merce_ici           IN OUT NUMBER,
 a_num_fabbricati_merce_ici       IN OUT NUMBER,
 a_dep_terreni_tasi               IN OUT NUMBER,
 a_acconto_terreni_tasi           IN OUT NUMBER,
 a_saldo_terreni_tasi             IN OUT NUMBER,
 a_dep_aree_tasi                  IN OUT NUMBER,
 a_acconto_aree_tasi              IN OUT NUMBER,
 a_saldo_aree_tasi                IN OUT NUMBER,
 a_dep_ab_tasi                    IN OUT NUMBER,
 a_acconto_ab_tasi                IN OUT NUMBER,
 a_saldo_ab_tasi                  IN OUT NUMBER,
 a_dep_altri_tasi                 IN OUT NUMBER,
 a_acconto_altri_tasi             IN OUT NUMBER,
 a_saldo_altri_tasi               IN OUT NUMBER,
 a_acconto_detrazione_tasi        IN OUT NUMBER,
 a_saldo_detrazione_tasi          IN OUT NUMBER,
 a_totale_terreni_tasi            IN OUT NUMBER,
 a_numero_fabbricati_tasi         IN OUT NUMBER,
 a_acconto_terreni_erar_tasi      IN OUT NUMBER,
 a_saldo_terreni_erar_tasi        IN OUT NUMBER,
 a_acconto_aree_erar_tasi         IN OUT NUMBER,
 a_saldo_aree_erar_tasi           IN OUT NUMBER,
 a_acconto_altri_erar_tasi        IN OUT NUMBER,
 a_saldo_altri_erar_tasi          IN OUT NUMBER,
 a_dep_rurali_tasi                IN OUT NUMBER,
 a_acconto_rurali_tasi            IN OUT NUMBER,
 a_saldo_rurali_tasi              IN OUT NUMBER,
 a_num_fabbricati_ab_tasi         IN OUT NUMBER,
 a_num_fabbricati_rurali_tasi     IN OUT NUMBER,
 a_num_fabbricati_altri_tasi      IN OUT NUMBER,
 a_acconto_uso_prod_tasi          IN OUT NUMBER,
 a_saldo_uso_prod_tasi            IN OUT NUMBER,
 a_num_fabbricati_uso_prod_tasi   IN OUT NUMBER,
 a_acconto_uso_prod_erar_tasi     IN OUT NUMBER,
 a_saldo_uso_prod_erar_tasi       IN OUT NUMBER,
 a_saldo_detrazione_std_tasi      IN OUT NUMBER)
IS
   w_pratica_tasi              NUMBER;
   w_pratica_ici               NUMBER;
   w_acconto_fabb_merce_tasi   NUMBER;
   w_saldo_fabb_merce_tasi     NUMBER;
   w_num_fabbricati_merce_tasi NUMBER;
   -- Variabili per cambio parametri CALCOLO_INDIVIDUALE
   w_dep_uso_prod_ici          NUMBER;
   w_dep_uso_prod_erar_ici     NUMBER;
   w_dep_terreni_erar_ici      NUMBER;
   w_dep_aree_erar_ici         NUMBER;
   w_dep_altri_erar_ici        NUMBER;
   w_dep_fabb_merce_ici        NUMBER;
   w_flag_versamenti_ici       VARCHAR2(1);
   w_dep_uso_prod_tasi         NUMBER;
   w_dep_uso_prod_erar_tasi    NUMBER;
   w_dep_terreni_erar_tasi     NUMBER;
   w_dep_aree_erar_tasi        NUMBER;
   w_dep_altri_erar_tasi       NUMBER;
   w_dep_fabb_merce_tasi       NUMBER;
   w_flag_versamenti_tasi      VARCHAR2(1);
BEGIN
   BEGIN
      SELECT pratica
        INTO w_pratica_ici
        FROM pratiche_tributo prtr
       WHERE     tipo_pratica = 'K'
             AND anno = a_anno
             AND cod_fiscale = a_cf
             AND tipo_tributo || '' = 'ICI';
   EXCEPTION
      WHEN OTHERS
      THEN
         RAISE_APPLICATION_ERROR (
            -20999,
            'Errore in calcolo individuale: non è stato possibile individuare la pratica ICI di calcolo.');
   END;
   BEGIN
      SELECT pratica
        INTO w_pratica_tasi
        FROM pratiche_tributo prtr
       WHERE     tipo_pratica = 'K'
             AND anno = a_anno
             AND cod_fiscale = a_cf
             AND tipo_tributo || '' = 'TASI';
   EXCEPTION
      WHEN OTHERS
      THEN
         RAISE_APPLICATION_ERROR (
            -20999,
            'Errore in calcolo individuale: non è stato possibile individuare la pratica TASI di calcolo.');
   END;
   BEGIN
      CALCOLO_INDIVIDUALE (W_PRATICA_ICI,
                           A_TIPO_CALCOLO,
                           A_DEP_TERRENI_ICI,
                           A_ACCONTO_TERRENI_ICI,
                           A_SALDO_TERRENI_ICI,
                           A_DEP_AREE_ICI,
                           A_ACCONTO_AREE_ICI,
                           A_SALDO_AREE_ICI,
                           A_DEP_AB_ICI,
                           A_ACCONTO_AB_ICI,
                           A_SALDO_AB_ICI,
                           A_DEP_ALTRI_ICI,
                           A_ACCONTO_ALTRI_ICI,
                           A_SALDO_ALTRI_ICI,
                           A_ACCONTO_DETRAZIONE_ICI,
                           A_SALDO_DETRAZIONE_ICI,
                           A_TOTALE_TERRENI_ICI,
                           A_NUMERO_FABBRICATI_ICI,
                           A_ACCONTO_TERRENI_ERAR_ICI,
                           A_SALDO_TERRENI_ERAR_ICI,
                           A_ACCONTO_AREE_ERAR_ICI,
                           A_SALDO_AREE_ERAR_ICI,
                           A_ACCONTO_ALTRI_ERAR_ICI,
                           A_SALDO_ALTRI_ERAR_ICI,
                           A_DEP_RURALI_ICI,
                           A_ACCONTO_RURALI_ICI,
                           A_SALDO_RURALI_ICI,
                           A_NUM_FABBRICATI_AB_ICI,
                           A_NUM_FABBRICATI_RURALI_ICI,
                           A_NUM_FABBRICATI_ALTRI_ICI,
                           A_ACCONTO_USO_PROD_ICI,
                           A_SALDO_USO_PROD_ICI,
                           A_NUM_FABBRICATI_USO_PROD_ICI,
                           A_ACCONTO_USO_PROD_ERAR_ICI,
                           A_SALDO_USO_PROD_ERAR_ICI,
                           A_SALDO_DETRAZIONE_STD_ICI,
                           A_ACCONTO_FABB_MERCE_ICI,
                           A_SALDO_FABB_MERCE_ICI,
                           A_NUM_FABBRICATI_MERCE_ICI,
                           W_DEP_USO_PROD_ICI,
                           W_DEP_USO_PROD_ERAR_ICI,
                           W_DEP_TERRENI_ERAR_ICI,
                           W_DEP_AREE_ERAR_ICI,
                           W_DEP_ALTRI_ERAR_ICI,
                           W_DEP_FABB_MERCE_ICI,
                           W_FLAG_VERSAMENTI_ICI
                           );
   EXCEPTION
      WHEN OTHERS
      THEN
         RAISE_APPLICATION_ERROR (-20999, 'ICI - ' || SQLERRM);
   END;
--   A_ACCONTO_TERRENI_ICI := A_ACCONTO_TERRENI_ICI * 100;
--   A_SALDO_TERRENI_ICI := A_SALDO_TERRENI_ICI * 100;
--   A_ACCONTO_AREE_ICI := A_ACCONTO_AREE_ICI * 100;
--   A_SALDO_AREE_ICI := A_SALDO_AREE_ICI * 100;
--   A_ACCONTO_AB_ICI := A_ACCONTO_AB_ICI * 100;
--   A_SALDO_AB_ICI := A_SALDO_AB_ICI * 100;
--   A_ACCONTO_ALTRI_ICI := A_ACCONTO_ALTRI_ICI * 100;
--   A_SALDO_ALTRI_ICI := A_SALDO_ALTRI_ICI * 100;
--   A_ACCONTO_DETRAZIONE_ICI := A_ACCONTO_DETRAZIONE_ICI * 100;
--   A_SALDO_DETRAZIONE_ICI := A_SALDO_DETRAZIONE_ICI * 100;
--   A_TOTALE_TERRENI_ICI := A_TOTALE_TERRENI_ICI * 100;
--   A_ACCONTO_TERRENI_ERAR_ICI := A_ACCONTO_TERRENI_ERAR_ICI * 100;
--   A_SALDO_TERRENI_ERAR_ICI := A_SALDO_TERRENI_ERAR_ICI * 100;
--   A_ACCONTO_AREE_ERAR_ICI := A_ACCONTO_AREE_ERAR_ICI * 100;
--   A_SALDO_AREE_ERAR_ICI := A_SALDO_AREE_ERAR_ICI * 100;
--   A_ACCONTO_ALTRI_ERAR_ICI := A_ACCONTO_ALTRI_ERAR_ICI * 100;
--   A_SALDO_ALTRI_ERAR_ICI := A_SALDO_ALTRI_ERAR_ICI * 100;
--   A_ACCONTO_RURALI_ICI := A_ACCONTO_RURALI_ICI * 100;
--   A_SALDO_RURALI_ICI := A_SALDO_RURALI_ICI * 100;
--   A_ACCONTO_USO_PROD_ICI := A_ACCONTO_USO_PROD_ICI * 100;
--   A_SALDO_USO_PROD_ICI := A_SALDO_USO_PROD_ICI * 100;
--   A_ACCONTO_USO_PROD_ERAR_ICI := A_ACCONTO_USO_PROD_ERAR_ICI * 100;
--   A_SALDO_USO_PROD_ERAR_ICI := A_SALDO_USO_PROD_ERAR_ICI * 100;
--   A_SALDO_DETRAZIONE_STD_ICI := A_SALDO_DETRAZIONE_STD_ICI * 100;
   BEGIN
      CALCOLO_INDIVIDUALE (W_PRATICA_TASI,
                           A_TIPO_CALCOLO,
                           A_DEP_TERRENI_TASI,
                           A_ACCONTO_TERRENI_TASI,
                           A_SALDO_TERRENI_TASI,
                           A_DEP_AREE_TASI,
                           A_ACCONTO_AREE_TASI,
                           A_SALDO_AREE_TASI,
                           A_DEP_AB_TASI,
                           A_ACCONTO_AB_TASI,
                           A_SALDO_AB_TASI,
                           A_DEP_ALTRI_TASI,
                           A_ACCONTO_ALTRI_TASI,
                           A_SALDO_ALTRI_TASI,
                           A_ACCONTO_DETRAZIONE_TASI,
                           A_SALDO_DETRAZIONE_TASI,
                           A_TOTALE_TERRENI_TASI,
                           A_NUMERO_FABBRICATI_TASI,
                           A_ACCONTO_TERRENI_ERAR_TASI,
                           A_SALDO_TERRENI_ERAR_TASI,
                           A_ACCONTO_AREE_ERAR_TASI,
                           A_SALDO_AREE_ERAR_TASI,
                           A_ACCONTO_ALTRI_ERAR_TASI,
                           A_SALDO_ALTRI_ERAR_TASI,
                           A_DEP_RURALI_TASI,
                           A_ACCONTO_RURALI_TASI,
                           A_SALDO_RURALI_TASI,
                           A_NUM_FABBRICATI_AB_TASI,
                           A_NUM_FABBRICATI_RURALI_TASI,
                           A_NUM_FABBRICATI_ALTRI_TASI,
                           A_ACCONTO_USO_PROD_TASI,
                           A_SALDO_USO_PROD_TASI,
                           A_NUM_FABBRICATI_USO_PROD_TASI,
                           A_ACCONTO_USO_PROD_ERAR_TASI,
                           A_SALDO_USO_PROD_ERAR_TASI,
                           A_SALDO_DETRAZIONE_STD_TASI,
                           W_ACCONTO_FABB_MERCE_TASI,
                           W_SALDO_FABB_MERCE_TASI,
                           W_NUM_FABBRICATI_MERCE_TASI,
                           W_DEP_USO_PROD_TASI,
                           W_DEP_USO_PROD_ERAR_TASI,
                           W_DEP_TERRENI_ERAR_TASI,
                           W_DEP_AREE_ERAR_TASI,
                           W_DEP_ALTRI_ERAR_TASI,
                           W_DEP_FABB_MERCE_TASI,
                           W_FLAG_VERSAMENTI_TASI
                          );
   EXCEPTION
      WHEN OTHERS
      THEN
         RAISE_APPLICATION_ERROR (-20999, 'TASI - ' || SQLERRM);
   END;
--   A_ACCONTO_TERRENI_TASI := A_ACCONTO_TERRENI_TASI * 100;
--   A_SALDO_TERRENI_TASI := A_SALDO_TERRENI_TASI * 100;
--   A_ACCONTO_AREE_TASI := A_ACCONTO_AREE_TASI * 100;
--   A_SALDO_AREE_TASI := A_SALDO_AREE_TASI * 100;
--   A_ACCONTO_AB_TASI := A_ACCONTO_AB_TASI * 100;
--   A_SALDO_AB_TASI := A_SALDO_AB_TASI * 100;
--   A_ACCONTO_ALTRI_TASI := A_ACCONTO_ALTRI_TASI * 100;
--   A_SALDO_ALTRI_TASI := A_SALDO_ALTRI_TASI * 100;
--   A_ACCONTO_DETRAZIONE_TASI := A_ACCONTO_DETRAZIONE_TASI * 100;
--   A_SALDO_DETRAZIONE_TASI := A_SALDO_DETRAZIONE_TASI * 100;
--   A_TOTALE_TERRENI_TASI := A_TOTALE_TERRENI_TASI * 100;
--   A_ACCONTO_TERRENI_ERAR_TASI := A_ACCONTO_TERRENI_ERAR_TASI * 100;
--   A_SALDO_TERRENI_ERAR_TASI := A_SALDO_TERRENI_ERAR_TASI * 100;
--   A_ACCONTO_AREE_ERAR_TASI := A_ACCONTO_AREE_ERAR_TASI * 100;
--   A_SALDO_AREE_ERAR_TASI := A_SALDO_AREE_ERAR_TASI * 100;
--   A_ACCONTO_ALTRI_ERAR_TASI := A_ACCONTO_ALTRI_ERAR_TASI * 100;
--   A_SALDO_ALTRI_ERAR_TASI := A_SALDO_ALTRI_ERAR_TASI * 100;
--   A_ACCONTO_RURALI_TASI := A_ACCONTO_RURALI_TASI * 100;
--   A_SALDO_RURALI_TASI := A_SALDO_RURALI_TASI * 100;
--   A_ACCONTO_USO_PROD_TASI := A_ACCONTO_USO_PROD_TASI * 100;
--   A_SALDO_USO_PROD_TASI := A_SALDO_USO_PROD_TASI * 100;
--   A_ACCONTO_USO_PROD_ERAR_TASI := A_ACCONTO_USO_PROD_ERAR_TASI * 100;
--   A_SALDO_USO_PROD_ERAR_TASI := A_SALDO_USO_PROD_ERAR_TASI * 100;
--   A_SALDO_DETRAZIONE_STD_TASI := A_SALDO_DETRAZIONE_STD_TASI * 100;
END;
/* End Procedure: CALCOLO_INDIVIDUALE_IMU_E_TASI */
/

