--liquibase formatted sql 
--changeset abrandolini:20250326_152423_importi_f24_imu stripComments:false runOnChange:true 
 
create or replace procedure IMPORTI_F24_IMU
/*************************************************************************
 NOME:        IMPORTI_F24_IMU
 DESCRIZIONE: Prepara gli importi da esporre nel modello F24
              per l'imposta di un anno.
              Se si tratta di ICI, la selezione dei dati avviene
              direttamente dalle tabelle.
              Se si tratta di IMU, la selezione dei dati avviene
              dalla vista DETTAGLI_IMU che contiene la suddivisione
              degli importi anche per comune ed erario.
 NOTE:
  Rev.    Date         Author      Note
  3       10/09/2020   VD          Aggiunta gestione importi fabbricati merce
  2       15/06/2020   VD          Aggiunto calcolo importo per fabbricati D
                                   in caso di tipo versamento U
  1       18/09/2019   VD          Aggiunti commenti
                                   Corretta selezione imposta totale
                                   acconto divisa per tipologia per
                                   l'IMU: non considerava l'importo
                                   destinato all'erario.
  0       30/12/2009               Prima emissione
*************************************************************************/
( a_cod_fiscale            in     varchar2
, a_anno                   in     number
, a_tipo_versamento        in     varchar2
, a_terreni_comu           in out number
, a_terreni_stato          in out number
, a_aree_comu              in out number
, a_aree_stato             in out number
, a_ab_comu                in out number
, a_detrazione             in out number
, a_rurali_comu            in out number
, a_altri_comu             in out number
, a_altri_stato            in out number
, a_num_fabb_ab            in out number
, a_num_fabb_rurali        in out number
, a_num_fabb_altri         in out number
, a_fabb_d_comu            in out number
, a_fabb_d_stato           in out number
, a_num_fabb_d             in out number
, a_fabb_merce             in out number
, a_num_fabb_merce         in out number
, a_tipo_calcolo           in     varchar2 default null
)
IS
    w_errore                varchar2(2000);
    errore                  exception;
    w_tot_terreni           number;
    w_acconto_terreni       number;
    w_tot_terreni_erar      number;
    w_acconto_terreni_erar  number;
    w_tot_aree              number;
    w_acconto_aree          number;
    w_tot_aree_erar         number;
    w_acconto_aree_erar     number;
    w_tot_ab                number;
    w_acconto_ab            number;
    w_num_fabb_ab           number;
    w_tot_detrazione        number;
    w_acconto_detrazione    number;
    w_tot_rurali            number;
    w_acconto_rurali        number;
    w_num_fabb_rurali       number;
    w_tot_altri             number;
    w_acconto_altri         number;
    w_tot_altri_erar        number;
    w_acconto_altri_erar    number;
    w_num_fabb_altri        number;
    w_tot_fabb_d            number;
    w_acconto_fabb_d        number;
    w_tot_fabb_d_erar       number;
    w_acconto_fabb_d_erar   number;
    w_num_fabb_fabb_d       number;
    w_tot_fabb_merce        number;
    w_acconto_fabb_merce    number;
    w_num_fabb_merce        number;
    w_vers_ab               number;
    w_vers_rurali           number;
    w_vers_altri_comu       number;
    w_vers_altri_erar       number;
    w_vers_terreni_comu     number;
    w_vers_terreni_erar     number;
    w_vers_aree_comu        number;
    w_vers_aree_erar        number;
    w_vers_fabb_d_comu      number;
    w_vers_fabb_d_erar      number;
    w_vers_fabb_merce       number;
    w_vers_detrazione       number;
BEGIN
   if a_anno < 2012 then
      begin
         select sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                          ,1,ogim.imposta
                          ,0
                          )
                   )                                                                     tot_terreni
              , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                          ,1,ogim.imposta_acconto
                          ,0
                          )
                   )                                                                     acconto_terreni
              , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                          ,1,ogim.imposta_erariale
                          ,0
                          )
                   )                                                                     tot_terreni_erar
              , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                          ,1,ogim.imposta_erariale_acconto
                          ,0
                          )
                   )                                                                     acconto_terreni_erar
              , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                          ,2,ogim.imposta
                          ,0
                          )
                   )                                                                     tot_aree
              , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                          ,2,ogim.imposta_acconto
                          ,0
                          )
                   )                                                                     acconto_aree
              , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                          ,2,ogim.imposta_erariale
                          ,0
                          )
                   )                                                                     tot_aree_erar
              , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                          ,2,ogim.imposta_erariale_acconto
                          ,0
                          )
                   )                                                                     acconto_aree_erar
              , sum(decode(ogim.tipo_aliquota
                          ,2,ogim.imposta
                          ,0
                          )
                   )                                                                     tot_ab
              , sum(decode(ogim.tipo_aliquota
                          ,2,ogim.imposta_acconto
                          ,0
                          )
                   )                                                                     acconto_ab
              , sum(decode(ogim.tipo_aliquota
                          ,2,1
                          ,0
                          )
                   )                                                                     num_fabb_ab
              , sum(ogim.detrazione)                                                     tot_detrazione
              , sum(ogim.detrazione_acconto)                                             acconto_detrazione
              , sum(decode(ogim.tipo_aliquota
                          ,2,0
                          ,decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                 ,1,0
                                 ,2,0
                                 ,decode(aliquota_erariale
                                        ,null,ogim.imposta
                                        ,0
                                        )
                                 )
                          )
                   )                                                                     tot_rurali
              , sum(decode(ogim.tipo_aliquota
                          ,2,0
                          ,decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                 ,1,0
                                 ,2,0
                                 ,decode(aliquota_erariale
                                        ,null,ogim.imposta_acconto
                                        ,0
                                        )
                                 )
                          )
                   )                                                                     acconto_rurali
              , sum(decode(ogim.tipo_aliquota
                          ,2,0
                          ,decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                 ,1,0
                                 ,2,0
                                 ,decode(aliquota_erariale
                                        ,null,1
                                        ,0
                                        )
                                 )
                          )
                   )                                                                     num_fabb_rurali
              , sum(decode(ogim.tipo_aliquota
                          ,2,0
                          ,decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                 ,1,0
                                 ,2,0
                                 ,decode(aliquota_erariale
                                        ,null,0
                                        ,ogim.imposta
                                        )
                                 )
                          )
                   )                                                                     tot_altri
              , sum(decode(ogim.tipo_aliquota
                          ,2,0
                          ,decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                 ,1,0
                                 ,2,0
                                 ,decode(aliquota_erariale
                                        ,null,0
                                        ,ogim.imposta_acconto
                                        )
                                 )
                          )
                   )                                                                     acconto_altri
              , sum(decode(ogim.tipo_aliquota
                          ,2,0
                          ,decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                 ,1,0
                                 ,2,0
                                 ,decode(aliquota_erariale
                                        ,null,0
                                        ,ogim.imposta_erariale
                                        )
                                 )
                          )
                   )                                                                     tot_altri_erar
              , sum(decode(ogim.tipo_aliquota
                          ,2,0
                          ,decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                 ,1,0
                                 ,2,0
                                 ,decode(aliquota_erariale
                                        ,null,0
                                        ,ogim.imposta_erariale_acconto
                                        )
                                 )
                          )
                   )                                                                     acconto_altri_erar
              , sum(decode(ogim.tipo_aliquota
                          ,2,0
                          ,decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                 ,1,0
                                 ,2,0
                                 ,decode(aliquota_erariale
                                        ,null,0
                                        ,1
                                        )
                                 )
                          )
                   )                                                                     num_fabb_altri
            into w_tot_terreni
               , w_acconto_terreni
               , w_tot_terreni_erar
               , w_acconto_terreni_erar
               , w_tot_aree
               , w_acconto_aree
               , w_tot_aree_erar
               , w_acconto_aree_erar
               , w_tot_ab
               , w_acconto_ab
               , w_num_fabb_ab
               , w_tot_detrazione
               , w_acconto_detrazione
               , w_tot_rurali
               , w_acconto_rurali
               , w_num_fabb_rurali
               , w_tot_altri
               , w_acconto_altri
               , w_tot_altri_erar
               , w_acconto_altri_erar
               , w_num_fabb_altri
           from oggetti_imposta        ogim
              , oggetti_pratica        ogpr
              , oggetti                ogge
              , pratiche_tributo       prtr
          where ogim.anno             = a_anno
            and ogim.cod_fiscale      = a_cod_fiscale
            and ogim.flag_calcolo     = 'S'
            and ogim.oggetto_pratica  = ogpr.oggetto_pratica
            and ogpr.oggetto          = ogge.oggetto
            and ogpr.pratica          = prtr.pratica
            and prtr.tipo_tributo||'' = 'ICI'
         group by ogim.cod_fiscale
              ;
      EXCEPTION
        WHEN others THEN
           w_tot_terreni          := 0;
           w_acconto_terreni      := 0;
           w_tot_terreni_erar     := 0;
           w_acconto_terreni_erar := 0;
           w_tot_aree             := 0;
           w_acconto_aree         := 0;
           w_tot_aree_erar        := 0;
           w_acconto_aree_erar    := 0;
           w_tot_ab               := 0;
           w_acconto_ab           := 0;
           w_num_fabb_ab          := 0;
           w_tot_detrazione       := 0;
           w_acconto_detrazione   := 0;
           w_tot_rurali           := 0;
           w_acconto_rurali       := 0;
           w_num_fabb_rurali      := 0;
           w_tot_altri            := 0;
           w_acconto_altri        := 0;
           w_tot_altri_erar       := 0;
           w_acconto_altri_erar   := 0;
           w_num_fabb_altri       := 0;
      end;
      w_tot_fabb_d             := 0;
      w_acconto_fabb_d         := 0;
      w_tot_fabb_d_erar        := 0;
      w_acconto_fabb_d_erar    := 0;
      w_num_fabb_fabb_d        := 0;
      w_tot_fabb_merce         := 0;
      w_acconto_fabb_merce     := 0;
      w_num_fabb_merce         := 0;
   else
      begin
        select terreni_comu     --nvl(terreni_comu,0) + nvl(terreni_erar,0)
             , terreni_comu_acc --nvl(terreni_comu_acc,0) + nvl(terreni_erar_acc,0) -- terreni_comu_acc
             , terreni_erar
             , terreni_erar_acc
             , aree_comu     --nvl(aree_comu,0) + nvl(aree_erar,0)
             , aree_comu_acc --nvl(aree_comu_acc,0) + nvl(aree_erar_acc,0)       -- aree_comu_acc
             , aree_erar
             , aree_erar_acc
             , ab_comu
             , ab_comu_acc
             , n_fab_ab
             , detr_comu
             , detr_comu_acc
             , rurali_comu
             , rurali_comu_acc
             , n_fab_rurali
             , altri_comu      --nvl(altri_comu,0) + nvl(altri_erar,0)
             , altri_comu_acc  --nvl(altri_comu_acc,0) + nvl(altri_erar_acc,0)     -- altri_comu_acc
             , altri_erar
             , altri_erar_acc
             , n_fab_altri
             , fabb_d_comu     --nvl(fabb_d_comu,0) + nvl(fabb_d_erar,0)
             , fabb_d_comu_acc --nvl(fabb_d_comu_acc,0) + nvl(fabb_d_erar_acc,0)   -- fabb_d_comu_acc
             , fabb_d_erar
             , fabb_d_erar_acc
             , n_fab_fabb_d
             , fabb_merce_comu
             , fabb_merce_comu_acc
             , n_fab_merce
             , decode(a_tipo_calcolo,'V',nvl(vers_ab_princ,0),0)
             , decode(a_tipo_calcolo,'V',nvl(vers_rurali,0),0)
             , decode(a_tipo_calcolo,'V',nvl(vers_altri_comu,0),0)
             , decode(a_tipo_calcolo,'V',nvl(vers_altri_erar,0),0)
             , decode(a_tipo_calcolo,'V',nvl(vers_terreni_comu,0),0)
             , decode(a_tipo_calcolo,'V',nvl(vers_terreni_erar,0),0)
             , decode(a_tipo_calcolo,'V',nvl(vers_aree_comu,0),0)
             , decode(a_tipo_calcolo,'V',nvl(vers_aree_erar,0),0)
             , decode(a_tipo_calcolo,'V',nvl(vers_fab_d_comu,0),0)
             , decode(a_tipo_calcolo,'V',nvl(vers_fab_d_erar,0),0)
             , decode(a_tipo_calcolo,'V',nvl(vers_fab_merce,0),0)
             , decode(a_tipo_calcolo,'V',nvl(vers_detrazione,0),0)
          into w_tot_terreni
             , w_acconto_terreni
             , w_tot_terreni_erar
             , w_acconto_terreni_erar
             , w_tot_aree
             , w_acconto_aree
             , w_tot_aree_erar
             , w_acconto_aree_erar
             , w_tot_ab
             , w_acconto_ab
             , w_num_fabb_ab
             , w_tot_detrazione
             , w_acconto_detrazione
             , w_tot_rurali
             , w_acconto_rurali
             , w_num_fabb_rurali
             , w_tot_altri
             , w_acconto_altri
             , w_tot_altri_erar
             , w_acconto_altri_erar
             , w_num_fabb_altri
             , w_tot_fabb_d
             , w_acconto_fabb_d
             , w_tot_fabb_d_erar
             , w_acconto_fabb_d_erar
             , w_num_fabb_fabb_d
             , w_tot_fabb_merce
             , w_acconto_fabb_merce
             , w_num_fabb_merce
             , w_vers_ab
             , w_vers_rurali
             , w_vers_altri_comu
             , w_vers_altri_erar
             , w_vers_terreni_comu
             , w_vers_terreni_erar
             , w_vers_aree_comu
             , w_vers_aree_erar
             , w_vers_fabb_d_comu
             , w_vers_fabb_d_erar
             , w_vers_fabb_merce
             , w_vers_detrazione
          from dettagli_imu deim
          where deim.anno             = a_anno
            and deim.cod_fiscale      = a_cod_fiscale
         ;
      end;
   end if;
   if a_tipo_versamento = 'A' then
      a_terreni_comu   := round(w_acconto_terreni,0); --round(w_acconto_terreni - w_acconto_terreni_erar,0);
      a_terreni_stato  := round(w_acconto_terreni_erar,0);
      a_aree_comu      := round(w_acconto_aree,0);    --round(w_acconto_aree - w_acconto_aree_erar,0);
      a_aree_stato     := round(w_acconto_aree_erar,0);
      a_ab_comu        := round(w_acconto_ab,0);
      a_detrazione     := round(w_acconto_detrazione,0);
      a_rurali_comu    := round(w_acconto_rurali,0);
      a_altri_comu     := round(w_acconto_altri,0);   --round(w_acconto_altri - w_acconto_altri_erar,0);
      a_altri_stato    := round(w_acconto_altri_erar,0);
      a_fabb_d_comu    := round(w_acconto_fabb_d,0);  --round(w_acconto_fabb_d - w_acconto_fabb_d_erar,0);
      a_fabb_d_stato   := round(w_acconto_fabb_d_erar,0);
      a_fabb_merce     := round(w_acconto_fabb_merce,0);
   elsif a_tipo_versamento = 'S' then
      if a_tipo_calcolo = 'V' then
         a_terreni_comu   := round(w_tot_terreni - w_vers_terreni_comu,0); --round((w_tot_terreni - w_tot_terreni_erar) - w_vers_terreni_comu,0);
         a_terreni_stato  := round(w_tot_terreni_erar - w_vers_terreni_erar,0);
         a_aree_comu      := round(w_tot_aree - w_vers_aree_comu,0); --round((w_tot_aree - w_tot_aree_erar) - w_vers_aree_comu,0);
         a_aree_stato     := round(w_tot_aree_erar - w_vers_aree_erar,0);
         a_ab_comu        := round(w_tot_ab - w_vers_ab,0);
         a_detrazione     := round(w_tot_detrazione - w_vers_detrazione,0);
         a_rurali_comu    := round(w_tot_rurali - w_vers_rurali,0);
         a_altri_comu     := round(w_tot_altri - w_vers_altri_comu,0); --round((w_tot_altri - w_tot_altri_erar) - w_vers_altri_comu,0);
         a_altri_stato    := round(w_tot_altri_erar - w_vers_altri_erar,0);
         a_fabb_d_comu    := round(w_tot_fabb_d - w_vers_fabb_d_comu,0); --round((w_tot_fabb_d - w_tot_fabb_d_erar) - w_vers_fabb_d_comu,0);
         a_fabb_d_stato   := round(w_tot_fabb_d_erar - w_vers_fabb_d_erar,0);
         a_fabb_merce     := round(w_tot_fabb_merce - w_vers_fabb_merce,0);
      else
         a_terreni_comu   := round(w_tot_terreni,0) - round(w_acconto_terreni,0); --round((w_tot_terreni - w_tot_terreni_erar) - (w_acconto_terreni - w_acconto_terreni_erar),0);
         a_terreni_stato  := round(w_tot_terreni_erar,0) - round(w_acconto_terreni_erar,0);
         a_aree_comu      := round(w_tot_aree,0) - round(w_acconto_aree,0); --round((w_tot_aree - w_tot_aree_erar) - (w_acconto_aree - w_acconto_aree_erar),0);
         a_aree_stato     := round(w_tot_aree_erar,0) - round(w_acconto_aree_erar,0);
         a_ab_comu        := round(w_tot_ab,0) - round(w_acconto_ab,0);
         a_detrazione     := round(w_tot_detrazione,0) - round(w_acconto_detrazione,0);
         a_rurali_comu    := round(w_tot_rurali,0) - round(w_acconto_rurali,0);
         a_altri_comu     := round(w_tot_altri,0) - round(w_acconto_altri,0); --round((w_tot_altri - w_tot_altri_erar) - (w_acconto_altri - w_acconto_altri_erar),0);
         a_altri_stato    := round(w_tot_altri_erar,0) - round(w_acconto_altri_erar,0);
         a_fabb_d_comu    := round(w_tot_fabb_d,0) - round(w_acconto_fabb_d,0); --round((w_tot_fabb_d - w_tot_fabb_d_erar) - (w_acconto_fabb_d - w_acconto_fabb_d_erar),0);
         a_fabb_d_stato   := round(w_tot_fabb_d_erar,0) - round(w_acconto_fabb_d_erar,0);
         a_fabb_merce     := round(w_tot_fabb_merce,0) - round(w_acconto_fabb_merce,0);
      end if;
   else
      a_terreni_comu   := round(w_tot_terreni,0);                --round(w_tot_terreni - w_tot_terreni_erar,0);
      a_terreni_stato  := round(w_tot_terreni_erar,0);
      a_aree_comu      := round(w_tot_aree,0);                   --round(w_tot_aree - w_tot_aree_erar,0);
      a_aree_stato     := round(w_tot_aree_erar,0);
      a_ab_comu        := round(w_tot_ab,0);
      a_detrazione     := round(w_tot_detrazione,0);
      a_rurali_comu    := round(w_tot_rurali,0);
      a_altri_comu     := round(w_tot_altri,0);                  --round(w_tot_altri - w_tot_altri_erar,0);
      a_altri_stato    := round(w_tot_altri_erar,0);
      a_fabb_d_comu    := round(w_tot_fabb_d,0);                 --round(w_tot_fabb_d - w_tot_fabb_d_erar,0);
      a_fabb_d_stato   := round(w_tot_fabb_d_erar,0);
      a_fabb_merce     := round(w_tot_fabb_merce,0);
   end if;
   a_num_fabb_ab     := w_num_fabb_ab;
   a_num_fabb_altri  := w_num_fabb_altri;
   a_num_fabb_rurali := w_num_fabb_rurali;
   a_num_fabb_d      := w_num_fabb_fabb_d;
   a_num_fabb_merce  := w_num_fabb_merce;
EXCEPTION
  WHEN errore THEN
       ROLLBACK;
       RAISE_APPLICATION_ERROR
      (-20999,w_errore);
  WHEN others THEN
       ROLLBACK;
       RAISE_APPLICATION_ERROR
         (-20999,'Errore in Importi F24 IMU'||'('||SQLERRM||')');
END;
/* End Procedure: IMPORTI_F24_IMU */
/

