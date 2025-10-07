--liquibase formatted sql 
--changeset abrandolini:20250326_152423_importi_f24_tasi stripComments:false runOnChange:true 
 
create or replace procedure IMPORTI_F24_TASI
( a_cod_fiscale             in     varchar2
, a_anno                    in     number
, a_tipo_versamento         in     varchar2
, a_dovuto_versato          in     varchar2
, a_terreni_comu            in out number
, a_aree_comu               in out number
, a_ab_comu                 in out number
, a_detrazione              in out number
, a_rurali_comu             in out number
, a_altri_comu              in out number
, a_num_fabb_ab             in out number
, a_num_fabb_rurali         in out number
, a_num_fabb_altri          in out number
, a_fabb_d_comu             in out number
, a_num_fabb_d              in out number
)
IS
  w_errore                  varchar2(2000);
  errore                    exception;
BEGIN
  select decode(a_tipo_versamento
               ,'A',round(deta.ab_comu_acc)
               ,'S',round(deta.ab_comu) - decode(a_dovuto_versato,'V'
                                                ,deta.vers_ab_princ
                                                ,round(deta.ab_comu_acc)
                                                )
               ,round(deta.ab_comu_acc) + (round(deta.ab_comu) - round(deta.ab_comu_acc))
               )                                ab_comu
              , n_fab_ab
              , decode(a_tipo_versamento
                      ,'A',deta.detr_comu_acc
                      ,'S',deta.detr_comu - decode(a_dovuto_versato,'V'
                                                  ,deta.vers_detrazione
                                                  ,deta.detr_comu_acc
                                                  )
                      ,deta.detr_comu
                      )                           detr_comu
              , decode(a_tipo_versamento
                      ,'A',round(deta.rurali_comu_acc)
                      ,'S',round(deta.rurali_comu) -
                           decode(a_dovuto_versato
                                 ,'V',deta.vers_rurali
                                 ,round(deta.rurali_comu_acc)
                                 )
                      ,round(deta.rurali_comu_acc) +
                       (round(deta.rurali_comu) - round(deta.rurali_comu_acc))
                      )                          rurali_comu
              , n_fab_rurali
              , decode(a_tipo_versamento
                      ,'A',round(deta.terreni_comu_acc)
                      ,'S',round(deta.terreni_comu) -
                           decode(a_dovuto_versato
                                 ,'V',deta.vers_terreni_comu
                                 ,round(deta.terreni_comu_acc)
                                 )
                      ,round(deta.terreni_comu_acc) +
                      (round(deta.terreni_comu) + round(deta.terreni_comu))
                      )                          terreni_comu
              , decode(a_tipo_versamento
                      ,'A',round(deta.aree_comu_acc)
                      ,'S',round(deta.aree_comu) -
                           decode(a_dovuto_versato
                                 ,'V',deta.vers_aree_comu
                                 ,round(deta.aree_comu_acc)
                                 )
                      ,round(deta.aree_comu_acc) +
                      (round(deta.aree_comu) - round(deta.aree_comu_acc))
                      )                          aree_comu
              , decode(a_tipo_versamento
                      ,'A',round(deta.altri_comu_acc)
                      ,'S',round(deta.altri_comu) -
                           decode(a_dovuto_versato
                                 ,'V',deta.vers_altri_comu
                                 ,round(deta.altri_comu_acc)
                                 )
                      ,round(deta.altri_comu_acc) +
                      (round(deta.altri_comu) - round(deta.altri_comu_acc))
                      )                           altri_comu
              , n_fab_altri
              , to_number(null) fabbricati_d_comu
              , to_number(null) n_fab_d
           into a_ab_comu
              , a_num_fabb_ab
              , a_detrazione
              , a_rurali_comu
              , a_num_fabb_rurali
              , a_terreni_comu
              , a_aree_comu
              , a_altri_comu
              , a_num_fabb_altri
              , a_fabb_d_comu
              , a_num_fabb_d
           from DETTAGLI_TASI deta
          where deta.anno        = a_anno
            and deta.cod_fiscale = a_cod_fiscale
;
  if a_detrazione <= 0 then
     a_detrazione := null;
  end if;
EXCEPTION
  WHEN errore THEN
       ROLLBACK;
       RAISE_APPLICATION_ERROR
      (-20999,w_errore);
  WHEN others THEN
       ROLLBACK;
       RAISE_APPLICATION_ERROR
         (-20999,'Errore in Importi F24 TASI'||'('||SQLERRM||')');
END;
/* End Procedure: IMPORTI_F24_TASI */
/

