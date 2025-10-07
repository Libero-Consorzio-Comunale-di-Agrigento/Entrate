--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_f24_imu_tasi stripComments:false runOnChange:true 
 
create or replace function F_F24_IMU_TASI
(
   a_riga                      NUMBER,
   a_ab_comu_ici               NUMBER,
   a_rurali_comu_ici           NUMBER,
   a_terreni_comu_ici          NUMBER,
   a_terreni_erar_ici          NUMBER,
   a_aree_comu_ici             NUMBER,
   a_aree_erar_ici             NUMBER,
   a_altri_comu_ici            NUMBER,
   a_altri_erar_ici            NUMBER,
   a_ab_comu_tasi              NUMBER,
   a_rurali_comu_tasi          NUMBER,
   a_terreni_comu_tasi         NUMBER,
   a_terreni_erar_tasi         NUMBER,
   a_aree_comu_tasi            NUMBER,
   a_aree_erar_tasi            NUMBER,
   a_altri_comu_tasi           NUMBER,
   a_altri_erar_tasi           NUMBER,
   a_num_fabb_ab_ici           NUMBER,
   a_num_fabb_rurali_ici       NUMBER,
   a_num_fabb_altri_ici        NUMBER,
   a_num_fabb_ab_tasi          NUMBER,
   a_num_fabb_rurali_tasi      NUMBER,
   a_num_fabb_altri_tasi       NUMBER,
   a_fabbricati_d_comu_ici     NUMBER DEFAULT NULL,
   a_fabbricati_d_erar_ici     NUMBER DEFAULT NULL,
   a_fabbricati_d_comu_tasi    NUMBER DEFAULT NULL,
   a_fabbricati_d_erar_tasi    NUMBER DEFAULT NULL,
   a_num_fabb_d_ici            NUMBER DEFAULT NULL,
   a_num_fabb_d_tasi           NUMBER DEFAULT NULL,
   a_fabbricati_merce_ici      NUMBER DEFAULT NULL,
   a_num_fabb_merce_ici        NUMBER DEFAULT NULL,
   a_sanzioni                  NUMBER DEFAULT NULL,
   a_interessi                 NUMBER DEFAULT NULL)
   RETURN VARCHAR2
IS
   w_stringa_imu       VARCHAR2 (32000);
   w_stringa_tasi      VARCHAR2 (32000);
   w_conta_righe_imu   NUMBER;
BEGIN
   BEGIN
      w_conta_righe_imu :=
         F_F24_IMU_CONTA_RIGHE (a_ab_comu_ici,
                                a_rurali_comu_ici,
                                a_terreni_comu_ici,
                                a_terreni_erar_ici,
                                a_aree_comu_ici,
                                a_aree_erar_ici,
                                a_altri_comu_ici,
                                a_altri_erar_ici,
                                a_num_fabb_ab_ici,
                                a_num_fabb_rurali_ici,
                                a_num_fabb_altri_ici,
                                a_fabbricati_d_comu_ici,
                                a_fabbricati_d_erar_ici,
                                a_num_fabb_d_ici,
                                a_fabbricati_merce_ici,
                                a_num_fabb_merce_ici,
                                a_sanzioni,
                                a_interessi);
   EXCEPTION
      WHEN OTHERS
      THEN
         DBMS_OUTPUT.put_line ('ERRORE CONTA IMU ' || SQLERRM);
   END;
   DBMS_OUTPUT.put_line ('----w_conta_righe_imu ' || w_conta_righe_imu);
   IF a_riga <= w_conta_righe_imu
   THEN
      BEGIN
         w_stringa_imu :=
            F_F24_IMU (a_riga,
                       a_ab_comu_ici,
                       a_rurali_comu_ici,
                       a_terreni_comu_ici,
                       a_terreni_erar_ici,
                       a_aree_comu_ici,
                       a_aree_erar_ici,
                       a_altri_comu_ici,
                       a_altri_erar_ici,
                       a_num_fabb_ab_ici,
                       a_num_fabb_rurali_ici,
                       a_num_fabb_altri_ici,
                       a_fabbricati_d_comu_ici,
                       a_fabbricati_d_erar_ici,
                       a_num_fabb_d_ici,
                       a_fabbricati_merce_ici,
                       a_num_fabb_merce_ici,
                       a_sanzioni,
                       a_interessi);
      EXCEPTION
         WHEN OTHERS
         THEN
            DBMS_OUTPUT.put_line ('ERRORE stringa IMU ' || SQLERRM);
      END;
      DBMS_OUTPUT.put_line ('w_stringa_imu ' || w_stringa_imu);
      RETURN w_stringa_imu;
   ELSE
      BEGIN
         w_stringa_tasi :=
            F_F24_TASI (a_riga - w_conta_righe_imu,
                        a_ab_comu_tasi,
                        a_rurali_comu_tasi,
                        a_terreni_comu_tasi,
                        a_terreni_erar_tasi,
                        a_aree_comu_tasi,
                        a_aree_erar_tasi,
                        a_altri_comu_tasi,
                        a_altri_erar_tasi,
                        a_num_fabb_ab_tasi,
                        a_num_fabb_rurali_tasi,
                        a_num_fabb_altri_tasi,
                        a_fabbricati_d_comu_tasi,
                        a_fabbricati_d_erar_tasi,
                        a_num_fabb_d_tasi,
                        a_sanzioni,
                        a_interessi);
      EXCEPTION
         WHEN OTHERS
         THEN
            DBMS_OUTPUT.put_line ('ERRORE stringa tasi ' || SQLERRM);
      END;
      DBMS_OUTPUT.put_line ('w_stringa_tasi ' || w_stringa_tasi);
      RETURN w_stringa_tasi;
   END IF;
END;
/* End Function: F_F24_IMU_TASI */
/

