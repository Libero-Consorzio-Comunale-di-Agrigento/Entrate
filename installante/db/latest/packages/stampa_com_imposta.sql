--liquibase formatted sql 
--changeset abrandolini:20250326_152429_stampa_com_imposta stripComments:false runOnChange:true 
 
CREATE OR REPLACE package     STAMPA_COM_IMPOSTA is
/******************************************************************************
 NOME:        STAMPA_COM_IMPOSTA
 DESCRIZIONE: Funzioni per stampa comunicazione imposta da situazione
              contribuente TributiWeb.
 ANNOTAZIONI: -
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 002   28/05/2024  AB      Sistemata la Dati_oggetto per prelevare anche oggetti che non
                           hanno il tipo_aliquota in OGIM
 001   14/04/2022  VD      Nuova funzione DATI_RENDITE.
 000   03/09/2021  VD      Prima emissione.
******************************************************************************/
  type t_record is record
  ( tipo_tributo                       varchar2(5)
  , cod_fiscale                        varchar2(16)
  , anno                               number
  , dovuto_versato                     varchar2(1)
  , modello                            number
  , descrizione                        varchar2(100)
  , codice_f24                         varchar2(20)
  , num_fabbricati                     number
  , importo_acc                        number
  , importo_acc_arr                    number
  , importo_sal                        number
  , importo_sal_arr                    number
  , importo_tot                        number
  , importo_tot_arr                    number
  , st_importo_acc                     varchar2(20)
  , st_importo_acc_arr                 varchar2(20)
  , st_importo_sal                     varchar2(20)
  , st_importo_sal_arr                 varchar2(20)
  , st_importo_tot                     varchar2(20)
  , st_importo_tot_arr                 varchar2(20)
  );
  TYPE type_riep_imposta IS TABLE OF t_record;
  t_riep_imposta                       type_riep_imposta := type_riep_imposta();
  function F_GET_COLLECTION
  return type_riep_imposta pipelined;
  procedure IMPORTI_IMU
  ( a_cod_fiscale            in     varchar2 default ''
  , a_anno                   in     number   default -1
  , a_tipo_versamento        in     varchar2 default ''
  , a_dovuto_versato         in     varchar2 default ''
  , a_terreni_comu           in out number
  , a_terreni_stato          in out number
  , a_aree_comu              in out number
  , a_aree_stato             in out number
  , a_ab_comu                in out number
  , a_detrazione             in out number
  , a_rurali_comu            in out number
  , a_altri_comu             in out number
  , a_altri_stato            in out number
  , a_fabb_d_comu            in out number
  , a_fabb_d_stato           in out number
  , a_fabb_merce             in out number
  , a_num_terreni            in out number
  , a_num_aree               in out number
  , a_num_fabb_ab            in out number
  , a_num_fabb_rurali        in out number
  , a_num_fabb_altri         in out number
  , a_num_fabb_d             in out number
  , a_num_fabb_merce         in out number
  );
  procedure IMPORTI_F24_IMU
  ( a_cod_fiscale            in     varchar2 default ''
  , a_anno                   in     number   default -1
  , a_tipo_versamento        in     varchar2 default ''
  , a_dovuto_versato         in     varchar2 default ''
  , a_terreni_comu           in out number
  , a_terreni_stato          in out number
  , a_aree_comu              in out number
  , a_aree_stato             in out number
  , a_ab_comu                in out number
  , a_detrazione             in out number
  , a_rurali_comu            in out number
  , a_altri_comu             in out number
  , a_altri_stato            in out number
  , a_fabb_d_comu            in out number
  , a_fabb_d_stato           in out number
  , a_fabb_merce             in out number
  , a_num_terreni            in out number
  , a_num_aree               in out number
  , a_num_fabb_ab            in out number
  , a_num_fabb_rurali        in out number
  , a_num_fabb_altri         in out number
  , a_num_fabb_d             in out number
  , a_num_fabb_merce         in out number
  );
  procedure IMPORTI_TASI
  ( a_cod_fiscale            in     varchar2 default ''
  , a_anno                   in     number   default -1
  , a_tipo_versamento        in     varchar2 default ''
  , a_dovuto_versato         in     varchar2 default ''
  , a_terreni_comu           in out number
  , a_aree_comu              in out number
  , a_ab_comu                in out number
  , a_detrazione             in out number
  , a_rurali_comu            in out number
  , a_altri_comu             in out number
  , a_num_terreni            in out number
  , a_num_aree               in out number
  , a_num_fabb_ab            in out number
  , a_num_fabb_rurali        in out number
  , a_num_fabb_altri         in out number
  , a_fabb_d_comu            in out number
  , a_num_fabb_d             in out number
  );
  procedure IMPORTI_F24_TASI
  ( a_cod_fiscale            in     varchar2 default ''
  , a_anno                   in     number   default -1
  , a_tipo_versamento        in     varchar2 default ''
  , a_dovuto_versato         in     varchar2 default ''
  , a_terreni_comu           in out number
  , a_aree_comu              in out number
  , a_ab_comu                in out number
  , a_detrazione             in out number
  , a_rurali_comu            in out number
  , a_altri_comu             in out number
  , a_num_terreni            in out number
  , a_num_aree               in out number
  , a_num_fabb_ab            in out number
  , a_num_fabb_rurali        in out number
  , a_num_fabb_altri         in out number
  , a_fabb_d_comu            in out number
  , a_num_fabb_d             in out number
  );
  function PRINCIPALE
  ( a_tipo_tributo                     varchar2   default ''
  , a_cod_fiscale                      varchar2   default ''
  , a_anno                             number     default -1
  , a_dovuto_versato                   varchar2   default ''
  , a_modello                          number     default -1
  ) return sys_refcursor;
  function CONTRIBUENTE
  ( a_ni                               number     default -1
  , a_tipo_tributo                     varchar2   default ''
  , a_cod_fiscale                      varchar2   default ''
  , a_ruolo                            number     default -1
  , a_modello                          number     default -1
  , a_anno                             number   default -1
  ) return sys_refcursor;
  function DATI_OGGETTI
  ( a_tipo_tributo                     varchar2 default ''
  , a_cod_fiscale                      varchar2 default ''
  , a_anno                             number   default -1
  , a_modello                          number   default -1
  ) return sys_refcursor;
  function DATI_RENDITE
  ( a_tipo_tributo                     varchar2 default ''
  , a_cod_fiscale                      varchar2 default ''
  , a_anno                             number   default -1
  , a_oggetto                          number   default -1
  , a_oggetto_pratica                  number   default -1
  ) return sys_refcursor;
  function RIEPILOGO_IMPOSTA_ANNUALE
  ( a_tipo_tributo           in     varchar2 default ''
  , a_cod_fiscale            in     varchar2 default ''
  , a_anno                   in     number   default -1
  , a_dovuto_versato         in     varchar2 default ''
  , a_modello                in     number   default -1
  ) return sys_refcursor;
  function RIEPILOGO_IMPOSTA_F24
  ( a_tipo_tributo           in     varchar2 default ''
  , a_cod_fiscale            in     varchar2 default ''
  , a_anno                   in     number   default -1
  , a_dovuto_versato         in     varchar2 default ''
  , a_modello                in     number   default -1
  ) return sys_refcursor;
end STAMPA_COM_IMPOSTA;
/
CREATE OR REPLACE package body     STAMPA_COM_IMPOSTA is
/******************************************************************************
 NOME:        STAMPA_COM_IMPOSTA
 DESCRIZIONE: Funzioni per stampa comunicazione imposta da situazione
              contribuente TributiWeb.
 ANNOTAZIONI: -
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 000   03/09/2021  VD      Prima emissione.
******************************************************************************/
  function F_GET_COLLECTION
  /******************************************************************************
   NOME:        F_GET_COLLECTION
   DESCRIZIONE: Restituisce un ref_cursor formato da tutti gli elementi di un
                array di record
   ANNOTAZIONI: -
   REVISIONI:
   Rev.  Data        Autore  Descrizione
   ----  ----------  ------  ----------------------------------------------------
   000   13/09/2021  VD      Prima emissione.
  ******************************************************************************/
  return type_riep_imposta pipelined
  is
  begin
    for i in 1..t_riep_imposta.count loop
      pipe row(t_riep_imposta(i));
    end loop;
    return;
  end;
----------------------------------------------------------------------------------
  procedure IMPORTI_IMU
  /*************************************************************************
   NOME:        IMPORTI_IMU
   DESCRIZIONE: Prepara gli importi suddivisi per tipologia per l'imposta
                di un anno.
                Se si tratta di ICI, la selezione dei dati avviene
                direttamente dalle tabelle.
                Se si tratta di IMU, la selezione dei dati avviene
                dalla vista DETTAGLI_IMU che contiene la suddivisione
                degli importi anche per comune ed erario.
   NOTE:
    Rev.    Date         Author      Note
    001     14/04/2022   VD          Aggiunto calcolo numero terreni e
                                     numero aree fabbricabili.
                                     Per ICI modificata select dati.
                                     Per IMU modificata vista DETTAGLI_IMU
                                     e select dati.
    000     14/09/2021   VD          Prima emissione
  *************************************************************************/
  ( a_cod_fiscale            in     varchar2 default ''
  , a_anno                   in     number   default -1
  , a_tipo_versamento        in     varchar2 default ''
  , a_dovuto_versato         in     varchar2 default ''
  , a_terreni_comu           in out number
  , a_terreni_stato          in out number
  , a_aree_comu              in out number
  , a_aree_stato             in out number
  , a_ab_comu                in out number
  , a_detrazione             in out number
  , a_rurali_comu            in out number
  , a_altri_comu             in out number
  , a_altri_stato            in out number
  , a_fabb_d_comu            in out number
  , a_fabb_d_stato           in out number
  , a_fabb_merce             in out number
  , a_num_terreni            in out number
  , a_num_aree               in out number
  , a_num_fabb_ab            in out number
  , a_num_fabb_rurali        in out number
  , a_num_fabb_altri         in out number
  , a_num_fabb_d             in out number
  , a_num_fabb_merce         in out number
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
  w_tot_detrazione        number;
  w_acconto_detrazione    number;
  w_tot_rurali            number;
  w_acconto_rurali        number;
  w_tot_altri             number;
  w_acconto_altri         number;
  w_tot_altri_erar        number;
  w_acconto_altri_erar    number;
  w_tot_fabb_d            number;
  w_acconto_fabb_d        number;
  w_tot_fabb_d_erar       number;
  w_acconto_fabb_d_erar   number;
  w_tot_fabb_merce        number;
  w_acconto_fabb_merce    number;
  w_num_terreni           number;
  w_num_aree              number;
  w_num_fabb_ab           number;
  w_num_fabb_rurali       number;
  w_num_fabb_altri        number;
  w_num_fabb_fabb_d       number;
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
                            ,1,1
                            ,0
                            )
                     )                                                                     num_terreni
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
                , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                            ,2,1
                            ,0
                            )
                     )                                                                     num_aree
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
                 , w_num_terreni
                 , w_tot_aree
                 , w_acconto_aree
                 , w_tot_aree_erar
                 , w_acconto_aree_erar
                 , w_num_aree
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
             w_num_terreni          := 0;
             w_tot_aree             := 0;
             w_acconto_aree         := 0;
             w_tot_aree_erar        := 0;
             w_acconto_aree_erar    := 0;
             w_num_aree             := 0;
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
        w_vers_ab                := 0;
        w_vers_altri_comu        := 0;
        w_vers_altri_erar        := 0;
        w_vers_aree_comu         := 0;
        w_vers_aree_erar         := 0;
        w_vers_detrazione        := 0;
        w_vers_fabb_d_comu       := 0;
        w_vers_fabb_d_erar       := 0;
        w_vers_fabb_merce        := 0;
        w_vers_rurali            := 0;
        w_vers_terreni_comu      := 0;
        w_vers_terreni_erar      := 0;
     else
        begin
          select nvl(terreni_comu,0) + nvl(terreni_erar,0)
               , nvl(terreni_comu_acc,0) + nvl(terreni_erar_acc,0) -- terreni_comu_acc
               , terreni_erar
               , terreni_erar_acc
               , n_terreni
               , nvl(aree_comu,0) + nvl(aree_erar,0)
               , nvl(aree_comu_acc,0) + nvl(aree_erar_acc,0)       -- aree_comu_acc
               , aree_erar
               , aree_erar_acc
               , n_aree
               , ab_comu
               , ab_comu_acc
               , n_fab_ab
               , detr_comu
               , detr_comu_acc
               , rurali_comu
               , rurali_comu_acc
               , n_fab_rurali
               , nvl(altri_comu,0) + nvl(altri_erar,0)
               , nvl(altri_comu_acc,0) + nvl(altri_erar_acc,0)     -- altri_comu_acc
               , altri_erar
               , altri_erar_acc
               , n_fab_altri
               , nvl(fabb_d_comu,0) + nvl(fabb_d_erar,0)
               , nvl(fabb_d_comu_acc,0) + nvl(fabb_d_erar_acc,0)   -- fabb_d_comu_acc
               , fabb_d_erar
               , fabb_d_erar_acc
               , n_fab_fabb_d
               , fabb_merce_comu
               , fabb_merce_comu_acc
               , n_fab_merce
               , decode(a_dovuto_versato,'V',nvl(vers_ab_princ,0),0)
               , decode(a_dovuto_versato,'V',nvl(vers_rurali,0),0)
               , decode(a_dovuto_versato,'V',nvl(vers_altri_comu,0),0)
               , decode(a_dovuto_versato,'V',nvl(vers_altri_erar,0),0)
               , decode(a_dovuto_versato,'V',nvl(vers_terreni_comu,0),0)
               , decode(a_dovuto_versato,'V',nvl(vers_terreni_erar,0),0)
               , decode(a_dovuto_versato,'V',nvl(vers_aree_comu,0),0)
               , decode(a_dovuto_versato,'V',nvl(vers_aree_erar,0),0)
               , decode(a_dovuto_versato,'V',nvl(vers_fab_d_comu,0),0)
               , decode(a_dovuto_versato,'V',nvl(vers_fab_d_erar,0),0)
               , decode(a_dovuto_versato,'V',nvl(vers_fab_merce,0),0)
               , decode(a_dovuto_versato,'V',nvl(vers_detrazione,0),0)
            into w_tot_terreni
               , w_acconto_terreni
               , w_tot_terreni_erar
               , w_acconto_terreni_erar
               , w_num_terreni
               , w_tot_aree
               , w_acconto_aree
               , w_tot_aree_erar
               , w_acconto_aree_erar
               , w_num_aree
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
        a_terreni_comu   := w_acconto_terreni - w_acconto_terreni_erar;
        a_terreni_stato  := w_acconto_terreni_erar;
        a_aree_comu      := w_acconto_aree - w_acconto_aree_erar;
        a_aree_stato     := w_acconto_aree_erar;
        a_ab_comu        := w_acconto_ab;
        a_detrazione     := w_acconto_detrazione;
        a_rurali_comu    := w_acconto_rurali;
        a_altri_comu     := w_acconto_altri - w_acconto_altri_erar;
        a_altri_stato    := w_acconto_altri_erar;
        a_fabb_d_comu    := w_acconto_fabb_d - w_acconto_fabb_d_erar;
        a_fabb_d_stato   := w_acconto_fabb_d_erar;
        a_fabb_merce     := w_acconto_fabb_merce;
     elsif a_tipo_versamento = 'S' then
        if a_dovuto_versato = 'V' then
           a_terreni_comu   := (w_tot_terreni - w_tot_terreni_erar) - w_vers_terreni_comu;
           a_terreni_stato  := w_tot_terreni_erar - w_vers_terreni_erar;
           a_aree_comu      := (w_tot_aree - w_tot_aree_erar) - w_vers_aree_comu;
           a_aree_stato     := w_tot_aree_erar - w_vers_aree_erar;
           a_ab_comu        := w_tot_ab - w_vers_ab;
           a_detrazione     := w_tot_detrazione - w_vers_detrazione;
           a_rurali_comu    := w_tot_rurali - w_vers_rurali;
           a_altri_comu     := (w_tot_altri - w_tot_altri_erar) - w_vers_altri_comu;
           a_altri_stato    := w_tot_altri_erar - w_vers_altri_erar;
           a_fabb_d_comu    := (w_tot_fabb_d - w_tot_fabb_d_erar) - w_vers_fabb_d_comu;
           a_fabb_d_stato   := w_tot_fabb_d_erar - w_vers_fabb_d_erar;
           a_fabb_merce     := w_tot_fabb_merce - w_vers_fabb_merce;
        else
           a_terreni_comu   := (w_tot_terreni - w_tot_terreni_erar) - (w_acconto_terreni - w_acconto_terreni_erar);
           a_terreni_stato  := w_tot_terreni_erar - w_acconto_terreni_erar;
           a_aree_comu      := (w_tot_aree - w_tot_aree_erar) - (w_acconto_aree - w_acconto_aree_erar);
           a_aree_stato     := w_tot_aree_erar - w_acconto_aree_erar;
           a_ab_comu        := w_tot_ab - w_acconto_ab;
           a_detrazione     := w_tot_detrazione - w_acconto_detrazione;
           a_rurali_comu    := w_tot_rurali - w_acconto_rurali;
           a_altri_comu     := (w_tot_altri - w_tot_altri_erar) - (w_acconto_altri - w_acconto_altri_erar);
           a_altri_stato    := w_tot_altri_erar - w_acconto_altri_erar;
           a_fabb_d_comu    := (w_tot_fabb_d - w_tot_fabb_d_erar) - (w_acconto_fabb_d - w_acconto_fabb_d_erar);
           a_fabb_d_stato   := w_tot_fabb_d_erar - w_acconto_fabb_d_erar;
           a_fabb_merce     := w_tot_fabb_merce - w_acconto_fabb_merce;
        end if;
     else
        a_terreni_comu   := w_tot_terreni - w_tot_terreni_erar;
        a_terreni_stato  := w_tot_terreni_erar;
        a_aree_comu      := w_tot_aree - w_tot_aree_erar;
        a_aree_stato     := w_tot_aree_erar;
        a_ab_comu        := w_tot_ab;
        a_detrazione     := w_tot_detrazione;
        a_rurali_comu    := w_tot_rurali;
        a_altri_comu     := w_tot_altri - w_tot_altri_erar;
        a_altri_stato    := w_tot_altri_erar;
        a_fabb_d_comu    := w_tot_fabb_d - w_tot_fabb_d_erar;
        a_fabb_d_stato   := w_tot_fabb_d_erar;
        a_fabb_merce     := w_tot_fabb_merce;
     end if;
     a_num_terreni     := w_num_terreni;
     a_num_aree        := w_num_aree;
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
----------------------------------------------------------------------------------
  procedure IMPORTI_F24_IMU
  /*************************************************************************
   NOME:        IMPORTI_F24_IMU
   DESCRIZIONE: Prepara gli importi suddivisi per tipologia per l'imposta
                di un anno arrotondati per la stampa dell'F24.
                Se si tratta di ICI, la selezione dei dati avviene
                direttamente dalle tabelle.
                Se si tratta di IMU, la selezione dei dati avviene
                dalla vista DETTAGLI_IMU che contiene la suddivisione
                degli importi anche per comune ed erario.
   NOTE:
    Rev.    Date         Author      Note
    001     21/06/2022   VD          Prima emissione
  *************************************************************************/
  ( a_cod_fiscale            in     varchar2 default ''
  , a_anno                   in     number   default -1
  , a_tipo_versamento        in     varchar2 default ''
  , a_dovuto_versato         in     varchar2 default ''
  , a_terreni_comu           in out number
  , a_terreni_stato          in out number
  , a_aree_comu              in out number
  , a_aree_stato             in out number
  , a_ab_comu                in out number
  , a_detrazione             in out number
  , a_rurali_comu            in out number
  , a_altri_comu             in out number
  , a_altri_stato            in out number
  , a_fabb_d_comu            in out number
  , a_fabb_d_stato           in out number
  , a_fabb_merce             in out number
  , a_num_terreni            in out number
  , a_num_aree               in out number
  , a_num_fabb_ab            in out number
  , a_num_fabb_rurali        in out number
  , a_num_fabb_altri         in out number
  , a_num_fabb_d             in out number
  , a_num_fabb_merce         in out number
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
  w_tot_detrazione        number;
  w_acconto_detrazione    number;
  w_tot_rurali            number;
  w_acconto_rurali        number;
  w_tot_altri             number;
  w_acconto_altri         number;
  w_tot_altri_erar        number;
  w_acconto_altri_erar    number;
  w_tot_fabb_d            number;
  w_acconto_fabb_d        number;
  w_tot_fabb_d_erar       number;
  w_acconto_fabb_d_erar   number;
  w_tot_fabb_merce        number;
  w_acconto_fabb_merce    number;
  w_num_terreni           number;
  w_num_aree              number;
  w_num_fabb_ab           number;
  w_num_fabb_rurali       number;
  w_num_fabb_altri        number;
  w_num_fabb_fabb_d       number;
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
                        ,1,1
                        ,0
                        )
                 )                                                                     num_terreni
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
            , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                        ,2,1
                        ,0
                        )
                 )                                                                     num_aree
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
             , w_num_terreni
             , w_tot_aree
             , w_acconto_aree
             , w_tot_aree_erar
             , w_acconto_aree_erar
             , w_num_aree
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
         w_num_terreni          := 0;
         w_tot_aree             := 0;
         w_acconto_aree         := 0;
         w_tot_aree_erar        := 0;
         w_acconto_aree_erar    := 0;
         w_num_aree             := 0;
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
           , n_terreni
           , aree_comu     --nvl(aree_comu,0) + nvl(aree_erar,0)
           , aree_comu_acc --nvl(aree_comu_acc,0) + nvl(aree_erar_acc,0)       -- aree_comu_acc
           , aree_erar
           , aree_erar_acc
           , n_aree
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
           , decode(a_dovuto_versato,'V',nvl(vers_ab_princ,0),0)
           , decode(a_dovuto_versato,'V',nvl(vers_rurali,0),0)
           , decode(a_dovuto_versato,'V',nvl(vers_altri_comu,0),0)
           , decode(a_dovuto_versato,'V',nvl(vers_altri_erar,0),0)
           , decode(a_dovuto_versato,'V',nvl(vers_terreni_comu,0),0)
           , decode(a_dovuto_versato,'V',nvl(vers_terreni_erar,0),0)
           , decode(a_dovuto_versato,'V',nvl(vers_aree_comu,0),0)
           , decode(a_dovuto_versato,'V',nvl(vers_aree_erar,0),0)
           , decode(a_dovuto_versato,'V',nvl(vers_fab_d_comu,0),0)
           , decode(a_dovuto_versato,'V',nvl(vers_fab_d_erar,0),0)
           , decode(a_dovuto_versato,'V',nvl(vers_fab_merce,0),0)
           , decode(a_dovuto_versato,'V',nvl(vers_detrazione,0),0)
        into w_tot_terreni
           , w_acconto_terreni
           , w_tot_terreni_erar
           , w_acconto_terreni_erar
           , w_num_terreni
           , w_tot_aree
           , w_acconto_aree
           , w_tot_aree_erar
           , w_acconto_aree_erar
           , w_num_aree
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
    if a_dovuto_versato = 'V' then
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
 a_num_terreni     := w_num_terreni;
 a_num_aree        := w_num_aree;
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
----------------------------------------------------------------------------------
  procedure IMPORTI_TASI
  ( a_cod_fiscale            in     varchar2 default ''
  , a_anno                   in     number   default -1
  , a_tipo_versamento        in     varchar2 default ''
  , a_dovuto_versato         in     varchar2 default ''
  , a_terreni_comu           in out number
  , a_aree_comu              in out number
  , a_ab_comu                in out number
  , a_detrazione             in out number
  , a_rurali_comu            in out number
  , a_altri_comu             in out number
  , a_num_terreni            in out number
  , a_num_aree               in out number
  , a_num_fabb_ab            in out number
  , a_num_fabb_rurali        in out number
  , a_num_fabb_altri         in out number
  , a_fabb_d_comu            in out number
  , a_num_fabb_d             in out number
  )
  IS
    w_errore                varchar2(2000);
    errore                  exception;
  BEGIN
    select decode(a_tipo_versamento
                 ,'A',deta.ab_comu_acc
                 ,'S',deta.ab_comu - decode(a_dovuto_versato
                                           ,'V',nvl(deta.vers_ab_princ,0)
                                           ,deta.ab_comu_acc
                                           )
                 ,deta.ab_comu
                 )                                                         ab_comu
         , deta.n_fab_ab
         , decode(a_tipo_versamento
                 ,'A',deta.detr_comu_acc
                 ,'S',deta.detr_comu - decode(a_dovuto_versato
                                               ,'V',nvl(deta.vers_detrazione,0)
                                             ,deta.detr_comu_acc
                                             )
                 ,deta.detr_comu
                 )                                                         detr_comu
         , decode(a_tipo_versamento
                 ,'A',deta.rurali_comu_acc
                 ,'S',deta.rurali_comu - decode(a_dovuto_versato
                                               ,'V',nvl(deta.vers_rurali,0)
                                               ,deta.rurali_comu_acc
                                               )
                 ,deta.rurali_comu
                 )                                                         rurali_comu
         , deta.n_fab_rurali
         , decode(a_tipo_versamento
                 ,'A',deta.terreni_comu_acc
                 ,'S',deta.terreni_comu - decode(a_dovuto_versato
                                                 ,'V',nvl(deta.vers_terreni_comu,0)
                                                ,deta.terreni_comu_acc
                                                )
                 ,deta.terreni_comu
                 )                                                         terreni_comu
         , deta.n_terreni
         , decode(a_tipo_versamento
                 ,'A',deta.aree_comu_acc
                 ,'S',deta.aree_comu - decode(a_dovuto_versato
                                               ,'V',nvl(deta.vers_aree_comu,0)
                                             ,deta.aree_comu_acc
                                             )
                 ,deta.aree_comu
                 )                                                         aree_comu
         , deta.n_aree
         , decode(a_tipo_versamento
                 ,'A',deta.altri_comu_acc
                 ,'S',deta.altri_comu - decode(a_dovuto_versato
                                              ,'V',nvl(deta.vers_altri_comu,0)
                                              ,deta.altri_comu_acc
                                              )
                 ,deta.altri_comu
                 )                                                         altri_comu
         , deta.n_fab_altri
         , to_number(null) fabbricati_d_comu
         , to_number(null) n_fab_d
      into a_ab_comu
         , a_num_fabb_ab
         , a_detrazione
         , a_rurali_comu
         , a_num_fabb_rurali
         , a_terreni_comu
         , a_num_terreni
         , a_aree_comu
         , a_num_aree
         , a_altri_comu
         , a_num_fabb_altri
         , a_fabb_d_comu
         , a_num_fabb_d
      from dettagli_tasi deta
      where deta.anno        = a_anno
        and deta.cod_fiscale = a_cod_fiscale
  ;
  if a_detrazione <= 0 then
     a_detrazione := to_number(null);
  end if;
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
----------------------------------------------------------------------------------
  procedure IMPORTI_F24_TASI
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
  , a_num_terreni             in out number
  , a_num_aree                in out number
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
       , deta.n_terreni
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
       , deta.n_aree
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
       , a_num_terreni
       , a_aree_comu
       , a_num_aree
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
----------------------------------------------------------------------------------
  function PRINCIPALE
  ( a_tipo_tributo                     varchar2   default ''
  , a_cod_fiscale                      varchar2   default ''
  , a_anno                             number     default -1
  , a_dovuto_versato                   varchar2   default ''
  , a_modello                          number     default -1
  ) return sys_refcursor is
  /******************************************************************************
    NOME:        CONTRIBUENTE.
    DESCRIZIONE: Restituisce tutti i dati relativi al contribuente per il tipo
                 tributo indicato.
                 Richiama funzione standard del package STAMPA_COMMON.
    RITORNA:     ref_cursor.
    NOTE:
  ******************************************************************************/
    rc           sys_refcursor;
  begin
    open rc for
      select a_tipo_tributo tipo_tributo
           , a_cod_fiscale    cod_fiscale
           , a_anno           anno
           , a_dovuto_versato dovuto_versato
           , a_modello        modello
        from dual;
    return rc;
  end;
----------------------------------------------------------------------------------
  function CONTRIBUENTE
  ( a_ni                        number     default -1
  , a_tipo_tributo              varchar2   default ''
  , a_cod_fiscale               varchar2   default ''
  , a_ruolo                     number     default -1
  , a_modello                   number     default -1
  , a_anno                      number   default -1
  ) return sys_refcursor is
  /******************************************************************************
    NOME:        CONTRIBUENTE.
    DESCRIZIONE: Restituisce tutti i dati relativi al contribuente per il tipo
                 tributo indicato.
                 Richiama funzione standard del package STAMPA_COMMON.
    RITORNA:     ref_cursor.
    NOTE:
  ******************************************************************************/
    rc sys_refcursor;
  begin
    rc := stampa_common.contribuenti_ente(to_number(null),a_tipo_tributo,a_cod_fiscale,-1,a_modello,a_anno);
    return rc;
  end contribuente;
----------------------------------------------------------------------------------
  function DATI_OGGETTI
  ( a_tipo_tributo                     varchar2 default ''
  , a_cod_fiscale                      varchar2 default ''
  , a_anno                             number default -1
  , a_modello                          number default -1
 ) return sys_refcursor is
  /******************************************************************************
    NOME:        DATI_OGGETTI.
    DESCRIZIONE: Restituisce un ref_cursor contenente l'elenco degli oggetti
                 del contribuente, filtrato per anno e tipo tributo.
    RITORNA:     ref_cursor.
    NOTE:
    REVISIONI:
    Rev.  Data        Autore  Descrizione
    ----  ----------  ------  --------------------------------------------------
    003   04/05/2023  AB      Passaggio a f_rendita di prtr.anno anziche ogim.anno
    002   26/04/2022  VD      Modificata selezione dati catastali:
                              - eliminata partita
                              - categoria e classe catasto solo se tipo oggetto
                              diverso da 1 (terreni) e 2 (aree fabbricabili)
    001   14/04/2022  VD      Aggiunti i seguenti dati:
                              - flag abitazione principale
                              - flag immobile storico
                              - numero mesi esclusione
                              - numero mesi riduzione
                              Corretta determinazione rendita e valore.
    000   03/09/2021  VD      Prima emissione.
  ******************************************************************************/
    rc sys_refcursor;
  begin
    open rc for
      select a_modello modello
           , a_tipo_tributo tipo_tributo
           , a_anno         anno
           , a_cod_fiscale  cod_fiscale
           , decode(ogge.oggetto, null, rpad('',10), rpad('Oggetto',10)||':') t_oggetto
           , ogge.oggetto
           , ogpr.oggetto_pratica
           , decode( ogge.cod_via, null, ogge.indirizzo_localita, arvi.denom_uff
                      ||decode( ogge.num_civ,null,'', ', '||ogge.num_civ )||decode( ogge.suffisso,null,'', '/'
                      ||ogge.suffisso ))
                      indirizzo
           , rpad('Indirizzo',19)||(':') t_indirizzo
           , decode(--ogge.partita||
                    ogge.sezione||
                    ogge.foglio||ogge.numero||ogge.subalterno||
                    ogge.zona||ogge.protocollo_catasto||to_char(ogge.anno_catasto)||
                    ogpr.categoria_catasto||ogpr.classe_catasto
                   ,null,rpad('',31),'Estremi Catastali: ') t_estremi
           , ltrim(
             --decode(ogge.partita,null,'',' Partita '||ogge.partita)||
             decode(ogge.sezione,null,'',' Sez. '||ogge.sezione)||
             decode(ogge.foglio,null,'',' Foglio '||ogge.foglio)||
             decode(ogge.numero,null,'',' Num. '||ogge.numero)||
             decode(ogge.subalterno,null,'',' Sub. '||ogge.subalterno)||
             decode(ogge.zona,null,'',' Zona '||ogge.zona)) estremi_catasto1
           , ltrim(decode(/*ogge.partita||*/ogge.sezione||ogge.foglio||ogge.numero||ogge.subalterno||ogge.zona
                          ,'',decode(ogge.protocollo_catasto,null,'',' Protocollo Numero '||ogge.protocollo_catasto)||
                              decode(ogge.anno_catasto,null,'',' Protocollo Anno '||to_char(ogge.anno_catasto))
                          ,''
                          )||
              decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                    ,1,''
                    ,2,''
                    ,decode(nvl(ogpr.categoria_catasto,ogge.categoria_catasto)
                           ,null,'',' Cat. '||nvl(ogpr.categoria_catasto,ogge.categoria_catasto))||
                                      decode(nvl(ogpr.classe_catasto,ogge.classe_catasto)
                                            ,null,'',' Cl. '||nvl(ogpr.classe_catasto,ogge.classe_catasto)
                                            )
                    )
                   )                         estremi_catasto2
           , ogge.partita partita
           , nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto) tipo_oggetto
           , tiog.descrizione desc_tipo_oggetto
           , decode(ogim.aliquota, null, '', 'Aliquota  : ') t_aliquota
           , ltrim(translate(to_char(ogim.aliquota,'990.00'),'.,',',.')) aliquota
           , decode(ogim.tipo_aliquota, null, '', ' - ') t_tipoaliquota
           , tial.descrizione    tipo_aliquota
           , ltrim(translate(to_char(ogco.perc_possesso,'990.00'),'.,',',.')) perc_possesso
           , decode(ogim.anno
                   ,ogco.anno,ogco.mesi_possesso
                   ,12
                   )       mesi_possesso
           , decode(ogim.anno
                   ,ogco.anno,ogco.mesi_possesso_1sem
                   ,6
                   )       mesi_possesso_1sem
           , decode(ogco.perc_possesso, null, '', '% Possesso: ') t_perc_possesso
           , decode(decode(ogim.anno
                          ,ogco.anno,ogco.mesi_possesso
                          ,12
                          )
                   , null, '', 'Mesi: ') t_mesi_possesso
           , decode(decode(ogim.anno
                          ,ogco.anno,ogco.mesi_possesso_1sem
                          ,6
                          )
                   , null, '', '1sem: ') t_mesi_poss_1sem
           , decode(ogim.anno
                   ,ogco.anno,ogco.mesi_esclusione
                   ,decode(ogco.flag_esclusione
                          ,'S',12,null)
                   )       mesi_esclusione
           , decode(ogim.anno
                   ,ogco.anno,ogco.mesi_riduzione
                   ,decode(ogco.flag_riduzione
                          ,'S',12,null)
                   )       mesi_riduzione
           , decode(f_get_ab_principale(ogco.cod_fiscale
                                       ,ogco.anno
                                       ,ogpr.oggetto_pratica
                                       )
                   ,'S','SI'
                   ,decode(f_get_ab_principale(ogco.cod_fiscale
                                              ,ogco.anno
                                              ,ogpr.oggetto_pratica_rif_ap
                                              )
                          ,'S','SI'
                          ,null)
                   ) flag_ab_principale
           , decode(ogpr.imm_storico
                   ,'S','SI'
                   ,null) imm_storico
           , decode(ogim.detrazione
                   ,null,''
                   ,'Detrazione COMUNALE ab. principale: '
                   ) t_detrazione_comunale
           , ltrim(translate(to_char(ogim.detrazione,'9,999,999,999,990.00'),'.,',',.')) detrazione_comunale
           , decode(ogim.detrazione_imponibile
                   ,null,''
                   ,decode(ogim.detrazione
                          ,null,''
                          ,' - '
                          )||'Detrazione STATALE ab. principale: '
                   ) t_detrazione_statale
           , ltrim(translate(to_char(ogim.detrazione_imponibile,'9,999,999,999,990.00'),'.,',',.')) detrazione_statale
           , decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                   ,2,'Valore: '
                   ,'Valore Riv: ')||
             stampa_common.f_formatta_numero(
               decode(f_rendita_anno_riog(ogge.oggetto,ogim.anno)
                   ,null,f_valore(ogpr.valore
                                 ,nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                 ,prtr.anno
                                 ,ogim.anno
                                 ,nvl(ogpr.categoria_catasto,ogge.categoria_catasto)
                                 ,prtr.tipo_pratica
                                 ,ogpr.flag_valore_rivalutato
                                 )
                   ,f_valore_da_rendita(f_rendita_anno_riog(ogge.oggetto,ogim.anno)
                                        ,nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto)
                                       ,ogim.anno
                                       ,nvl(ogpr.categoria_catasto,ogge.categoria_catasto)
                                       ,ogpr.imm_storico
                                       )
                   ),'I','S')   valore
           , ltrim(translate(to_char(ogim.imposta,'9,999,999,999,990.00'),'.,',',.')) imposta
           , decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                   ,1,'Reddito dom.: '
                   ,2,''
                   ,'Rendita: ')||
             decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                   ,2,null
                   ,stampa_common.f_formatta_numero(
                      decode(f_rendita_anno_riog(ogpr.oggetto, a_anno)
                            ,null,f_rendita(ogpr.valore
                                         ,nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                         ,prtr.anno  --ogim.anno  AB 04/05/2023
                                         ,nvl(ogpr.categoria_catasto,ogge.categoria_catasto)
                                         )
                          ,f_rendita_anno_riog(ogpr.oggetto,a_anno)
                          )
                          ,'I','S'
                          )
                   )   rendita
           , decode(ogim.imposta, null, '', 'Imposta   : ') simposta
           , replace(f_dettaglio_riog(ogpr.oggetto
                                     ,ogim.anno
                                     ,nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                     ,nvl(ogpr.categoria_catasto,ogge.categoria_catasto)
                                     )
                    ,'[a_capo','') dettaglio_riog
        from OGGETTI_IMPOSTA      ogim
           , OGGETTI_PRATICA      ogpr
           , PRATICHE_TRIBUTO     prtr
           , OGGETTI_CONTRIBUENTE ogco
           , OGGETTI              ogge
           , ARCHIVIO_VIE         arvi
           , TIPI_ALIQUOTA        tial
           , TIPI_OGGETTO         tiog
       where arvi.cod_via       (+) = ogge.cod_via
         and tial.tipo_aliquota (+) = ogim.tipo_aliquota
         and tiog.tipo_oggetto    = nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
         and ogim.tipo_aliquota  is not null
         and ogco.cod_fiscale     = ogim.cod_fiscale
         and ogco.oggetto_pratica = ogim.oggetto_pratica
         and ogpr.pratica         = prtr.pratica
         and ogpr.oggetto         = ogge.oggetto
         and ogpr.oggetto_pratica = ogim.oggetto_pratica
         and prtr.tipo_tributo    = a_tipo_tributo
         and tial.tipo_tributo    = a_tipo_tributo
         and ogim.flag_calcolo    = 'S'
         and ogim.cod_fiscale     = a_cod_fiscale
         and ogim.anno            = a_anno
      union
      select a_modello modello
           , a_tipo_tributo tipo_tributo
           , a_anno         anno
           , a_cod_fiscale  cod_fiscale
           , decode(ogge.oggetto, null, rpad('',10), rpad('Oggetto',10)||':') t_oggetto
           , ogge.oggetto
           , ogpr.oggetto_pratica
           , decode( ogge.cod_via, null, ogge.indirizzo_localita, arvi.denom_uff
                      ||decode( ogge.num_civ,null,'', ', '||ogge.num_civ )||decode( ogge.suffisso,null,'', '/'
                      ||ogge.suffisso ))
                      indirizzo
           , rpad('Indirizzo',19)||(':') t_indirizzo
           , decode(--ogge.partita||
                    ogge.sezione||
                    ogge.foglio||ogge.numero||ogge.subalterno||
                    ogge.zona||ogge.protocollo_catasto||to_char(ogge.anno_catasto)||
                    ogpr.categoria_catasto||ogpr.classe_catasto
                   ,null,rpad('',31),'Estremi Catastali: ') t_estremi
           , ltrim(
             --decode(ogge.partita,null,'',' Partita '||ogge.partita)||
             decode(ogge.sezione,null,'',' Sez. '||ogge.sezione)||
             decode(ogge.foglio,null,'',' Foglio '||ogge.foglio)||
             decode(ogge.numero,null,'',' Num. '||ogge.numero)||
             decode(ogge.subalterno,null,'',' Sub. '||ogge.subalterno)||
             decode(ogge.zona,null,'',' Zona '||ogge.zona)) estremi_catasto1
           , ltrim(decode(/*ogge.partita||*/ogge.sezione||ogge.foglio||ogge.numero||ogge.subalterno||ogge.zona
                          ,'',decode(ogge.protocollo_catasto,null,'',' Protocollo Numero '||ogge.protocollo_catasto)||
                              decode(ogge.anno_catasto,null,'',' Protocollo Anno '||to_char(ogge.anno_catasto))
                          ,''
                          )||
              decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                    ,1,''
                    ,2,''
                    ,decode(nvl(ogpr.categoria_catasto,ogge.categoria_catasto)
                           ,null,'',' Cat. '||nvl(ogpr.categoria_catasto,ogge.categoria_catasto))||
                                      decode(nvl(ogpr.classe_catasto,ogge.classe_catasto)
                                            ,null,'',' Cl. '||nvl(ogpr.classe_catasto,ogge.classe_catasto)
                                            )
                    )
                   )                         estremi_catasto2
           , ogge.partita partita
           , nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto) tipo_oggetto
           , tiog.descrizione desc_tipo_oggetto
           , decode(ogim.aliquota, null, '', 'Aliquota  : ') t_aliquota
           , nvl(ltrim(translate(to_char(ogim.aliquota,'990.00'),'.,',',.')),'*ALIQ.'||chr(13)||'MULTI') aliquota
           , decode(ogim.tipo_aliquota, null, '', ' - ') t_tipoaliquota
           , '**ALIQUOTE MULTIPLE**'      tipo_aliquota
           , ltrim(translate(to_char(ogco.perc_possesso,'990.00'),'.,',',.')) perc_possesso
           , decode(ogim.anno
                   ,ogco.anno,ogco.mesi_possesso
                   ,12
                   )       mesi_possesso
           , decode(ogim.anno
                   ,ogco.anno,ogco.mesi_possesso_1sem
                   ,6
                   )       mesi_possesso_1sem
           , decode(ogco.perc_possesso, null, '', '% Possesso: ') t_perc_possesso
           , decode(decode(ogim.anno
                          ,ogco.anno,ogco.mesi_possesso
                          ,12
                          )
                   , null, '', 'Mesi: ') t_mesi_possesso
           , decode(decode(ogim.anno
                          ,ogco.anno,ogco.mesi_possesso_1sem
                          ,6
                          )
                   , null, '', '1sem: ') t_mesi_poss_1sem
           , decode(ogim.anno
                   ,ogco.anno,ogco.mesi_esclusione
                   ,decode(ogco.flag_esclusione
                          ,'S',12,null)
                   )       mesi_esclusione
           , decode(ogim.anno
                   ,ogco.anno,ogco.mesi_riduzione
                   ,decode(ogco.flag_riduzione
                          ,'S',12,null)
                   )       mesi_riduzione
           , decode(f_get_ab_principale(ogco.cod_fiscale
                                       ,ogco.anno
                                       ,ogpr.oggetto_pratica
                                       )
                   ,'S','SI'
                   ,decode(f_get_ab_principale(ogco.cod_fiscale
                                              ,ogco.anno
                                              ,ogpr.oggetto_pratica_rif_ap
                                              )
                          ,'S','SI'
                          ,null)
                   ) flag_ab_principale
           , decode(ogpr.imm_storico
                   ,'S','SI'
                   ,null) imm_storico
           , decode(ogim.detrazione
                   ,null,''
                   ,'Detrazione COMUNALE ab. principale: '
                   ) t_detrazione_comunale
           , ltrim(translate(to_char(ogim.detrazione,'9,999,999,999,990.00'),'.,',',.')) detrazione_comunale
           , decode(ogim.detrazione_imponibile
                   ,null,''
                   ,decode(ogim.detrazione
                          ,null,''
                          ,' - '
                          )||'Detrazione STATALE ab. principale: '
                   ) t_detrazione_statale
           , ltrim(translate(to_char(ogim.detrazione_imponibile,'9,999,999,999,990.00'),'.,',',.')) detrazione_statale
           , decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                   ,2,'Valore: '
                   ,'Valore Riv: ')||
             stampa_common.f_formatta_numero(
               decode(f_rendita_anno_riog(ogge.oggetto,ogim.anno)
                   ,null,f_valore(ogpr.valore
                                 ,nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                 ,prtr.anno
                                 ,ogim.anno
                                 ,nvl(ogpr.categoria_catasto,ogge.categoria_catasto)
                                 ,prtr.tipo_pratica
                                 ,ogpr.flag_valore_rivalutato
                                 )
                   ,f_valore_da_rendita(f_rendita_anno_riog(ogge.oggetto,ogim.anno)
                                        ,nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto)
                                       ,ogim.anno
                                       ,nvl(ogpr.categoria_catasto,ogge.categoria_catasto)
                                       ,ogpr.imm_storico
                                       )
                   ),'I','S')   valore
           , ltrim(translate(to_char(ogim.imposta,'9,999,999,999,990.00'),'.,',',.')) imposta
           , decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                   ,1,'Reddito dom.: '
                   ,2,''
                   ,'Rendita: ')||
             decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                   ,2,null
                   ,stampa_common.f_formatta_numero(
                      decode(f_rendita_anno_riog(ogpr.oggetto, a_anno)
                            ,null,f_rendita(ogpr.valore
                                         ,nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                         ,prtr.anno  --ogim.anno  AB 04/05/2023
                                         ,nvl(ogpr.categoria_catasto,ogge.categoria_catasto)
                                         )
                          ,f_rendita_anno_riog(ogpr.oggetto,a_anno)
                          )
                          ,'I','S'
                          )
                   )   rendita
           , decode(ogim.imposta, null, '', 'Imposta   : ') simposta
           , replace(f_dettaglio_riog(ogpr.oggetto
                                     ,ogim.anno
                                     ,nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                     ,nvl(ogpr.categoria_catasto,ogge.categoria_catasto)
                                     )
                    ,'[a_capo','') dettaglio_riog
        from OGGETTI_IMPOSTA      ogim
           , OGGETTI_PRATICA      ogpr
           , PRATICHE_TRIBUTO     prtr
           , OGGETTI_CONTRIBUENTE ogco
           , OGGETTI              ogge
           , ARCHIVIO_VIE         arvi
--           , TIPI_ALIQUOTA        tial
           , TIPI_OGGETTO         tiog
       where arvi.cod_via       (+) = ogge.cod_via
--         and tial.tipo_aliquota (+) = ogim.tipo_aliquota
         and ogim.tipo_aliquota is null
         and tiog.tipo_oggetto    = nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
         and ogco.cod_fiscale     = ogim.cod_fiscale
         and ogco.oggetto_pratica = ogim.oggetto_pratica
         and ogpr.pratica         = prtr.pratica
         and ogpr.oggetto         = ogge.oggetto
         and ogpr.oggetto_pratica = ogim.oggetto_pratica
         and prtr.tipo_tributo    = a_tipo_tributo
--         and tial.tipo_tributo    = a_tipo_tributo
         and ogim.flag_calcolo    = 'S'
         and ogim.cod_fiscale     = a_cod_fiscale
         and ogim.anno            = a_anno
      ;
   return rc;
   end DATI_OGGETTI;
----------------------------------------------------------------------------------
  function DATI_RENDITE
  ( a_tipo_tributo                     varchar2 default ''
  , a_cod_fiscale                      varchar2 default ''
  , a_anno                             number   default -1
  , a_oggetto                          number   default -1
  , a_oggetto_pratica                  number   default -1
  ) return sys_refcursor is
  /******************************************************************************
    NOME:        DATI_RENDITE.
    DESCRIZIONE: Restituisce un ref_cursor contenente l'elenco delle rendite
                 catastali associate all'oggetto dato.
    RITORNA:     ref_cursor.
    NOTE:
    REVISIONI:
    Rev.  Data        Autore  Descrizione
    ----  ----------  ------  ---------------------------------------------------
    001   04/05/2023  AB      Passaggio a f_rendita di wrkp.anno anziche a_anno
                              Aggiunto anche il parametro oggetto_pratica per
                              ottenere le rendite corrette
    000   14/04/2022  VD      Prima emissione.
  ******************************************************************************/
    rc sys_refcursor;
  begin
    open rc for
      select 'Dal' l_data_inizio
           , to_char(greatest(to_date('0101'||a_anno,'ddmmyyyy'),wrkp.inizio_validita),'dd/mm/yyyy') data_inizio
           , 'Al' l_data_fine
           , to_char(least(to_date('3112'||a_anno,'ddmmyyyy'),wrkp.fine_validita),'dd/mm/yyyy') data_fine
           , decode(nvl(wrkp.tipo_oggetto,ogge.tipo_oggetto)
                   ,2,null
                   ,1,'Reddito dom.'
                   ,'Rendita'
                   ) l_rendita
           , decode(nvl(wrkp.tipo_oggetto,ogge.tipo_oggetto)
                   ,2,null
                   ,stampa_common.f_formatta_numero(
                    decode(f_rendita_data_riog(ogge.oggetto,wrkp.inizio_validita)
                          ,null,round(f_rendita(wrkp.valore
                                               ,nvl(wrkp.tipo_oggetto,ogge.tipo_oggetto)
                                               ,wrkp.anno --a_anno    AB 04/05/2023
                                               ,nvl(wrkp.categoria_catasto,ogge.categoria_catasto)
                                               )
                                     ,2
                                     )
                          ,f_rendita_data_riog(ogge.oggetto,wrkp.inizio_validita)
                          ),'I','S')
                   ) st_rendita
            , 'Valore' l_valore
            , stampa_common.f_formatta_numero(
              decode(f_rendita_data_riog(ogge.oggetto
                                        ,wrkp.inizio_validita
                                        )
                    ,null,f_valore(wrkp.valore
                                  ,nvl(wrkp.tipo_oggetto, ogge.tipo_oggetto)
                                  ,wrkp.anno
                                  ,a_anno
                                  ,nvl(wrkp.categoria_catasto,ogge.categoria_catasto)
                                  ,wrkp.tipo_pratica
                                  ,'S'
                                  )
                    ,f_valore_da_rendita(f_rendita_data_riog(ogge.oggetto
                                                            ,wrkp.inizio_validita
                                                            )
                                        ,nvl(wrkp.tipo_oggetto, ogge.tipo_oggetto)
                                        ,a_anno
                                        ,nvl(wrkp.categoria_catasto,ogge.categoria_catasto)
                                        ,wrkp.imm_storico
                                        )
                    )
              ,'I','S') st_valore
         from periodi_ogco_riog wrkp
            , oggetti           ogge
        where wrkp.cod_fiscale = a_cod_fiscale
          and wrkp.tipo_tributo = a_tipo_tributo
          and wrkp.oggetto = a_oggetto
          and wrkp.oggetto_pratica = a_oggetto_pratica
          and wrkp.oggetto = ogge.oggetto
          and wrkp.inizio_validita <= to_date('3112'||a_anno,'ddmmyyyy')
          and wrkp.fine_validita >= to_date('0101'||a_anno,'ddmmyyyy')
        order by inizio_validita;
    return rc;
  end DATI_RENDITE;
----------------------------------------------------------------------------------
  function RIEPILOGO_IMPOSTA_ANNUALE
  ( a_tipo_tributo           in     varchar2 default ''
  , a_cod_fiscale            in     varchar2 default ''
  , a_anno                   in     number   default -1
  , a_dovuto_versato         in     varchar2 default ''
  , a_modello                in     number   default -1
  )
  return sys_refcursor is
  /*************************************************************************
   NOME:        RIEPILOGO_IMPOSTA_ANNUALE
   DESCRIZIONE: TributiWeb: stampa comunicazione da folder "Imposte" di
                situazione contribuente
   PARAMETRI:   Tipo tributo        ICI/TASI
                Codice fiscale      Codice fiscale del contribuente
                Anno                Anno di riferimento
                Dovuto Versato.     Solo per F24 a saldo
                                    D - Dovuto: calcola gli importi in base
                                        all'imposta dovuta (totale - acconto)
                                    V - Versato: calcola gli importi in base
                                        a quanto gia' eventualmente versato
                                        (totale - versato)
   RITORNA:     ref_cursor          Elenco imposte suddivise per tipologia
   NOTE:
   Rev.    Date         Author      Note
   000     03/09/2021   VD          Prima emissione.
  *************************************************************************/
  a_terreni_comu_acc                number;
  a_terreni_erar_acc                number;
  a_aree_comu_acc                   number;
  a_aree_erar_acc                   number;
  a_ab_comu_acc                     number;
  a_detrazione_acc                  number;
  a_rurali_comu_acc                 number;
  a_altri_comu_acc                  number;
  a_altri_erar_acc                  number;
  a_fabb_d_comu_acc                 number;
  a_fabb_d_erar_acc                 number;
  a_fabb_merce_acc                  number;
  a_terreni_comu_sal                number;
  a_terreni_erar_sal                number;
  a_aree_comu_sal                   number;
  a_aree_erar_sal                   number;
  a_ab_comu_sal                     number;
  a_detrazione_sal                  number;
  a_rurali_comu_sal                 number;
  a_altri_comu_sal                  number;
  a_altri_erar_sal                  number;
  a_fabb_d_comu_sal                 number;
  a_fabb_d_erar_sal                 number;
  a_fabb_merce_sal                  number;
  a_terreni_comu                    number;
  a_terreni_erar                    number;
  a_aree_comu                       number;
  a_aree_erar                       number;
  a_ab_comu                         number;
  a_detrazione                      number;
  a_rurali_comu                     number;
  a_altri_comu                      number;
  a_altri_erar                      number;
  a_fabb_d_comu                     number;
  a_fabb_d_erar                     number;
  a_fabb_merce                      number;
  a_num_terreni                     number;
  a_num_aree                        number;
  a_num_fabb_ab                     number;
  a_num_fabb_rurali                 number;
  a_num_fabb_altri                  number;
  a_num_fabb_d                      number;
  a_num_fabb_merce                  number;
  w_tot_fabbricati                  number;
  w_tot_acconto                     number;
  w_tot_saldo                       number;
  w_totale                          number;
  w_ind                             number;
  rc                                sys_refcursor;
begin
  t_riep_imposta.delete;
  w_ind := 0;
  if a_tipo_tributo is not null then
     if a_tipo_tributo = 'ICI' then
        -- Calcolo importi acconto
        stampa_com_imposta.importi_imu ( a_cod_fiscale, a_anno
                                       , 'A', a_dovuto_versato
                                       , a_terreni_comu_acc, a_terreni_erar_acc
                                       , a_aree_comu_acc, a_aree_erar_acc
                                       , a_ab_comu_acc, a_detrazione_acc
                                       , a_rurali_comu_acc
                                       , a_altri_comu_acc, a_altri_erar_acc
                                       , a_fabb_d_comu_acc, a_fabb_d_erar_acc
                                       , a_fabb_merce_acc
                                       , a_num_terreni, a_num_aree
                                       , a_num_fabb_ab, a_num_fabb_rurali, a_num_fabb_altri
                                       , a_num_fabb_d, a_num_fabb_merce
                                       );
        -- Calcolo importi saldo
        stampa_com_imposta.importi_imu ( a_cod_fiscale, a_anno
                                       , 'S', a_dovuto_versato
                                       , a_terreni_comu_sal, a_terreni_erar_sal
                                       , a_aree_comu_sal, a_aree_erar_sal
                                       , a_ab_comu_sal, a_detrazione_sal
                                       , a_rurali_comu_sal
                                       , a_altri_comu_sal, a_altri_erar_sal
                                       , a_fabb_d_comu_sal, a_fabb_d_erar_sal
                                       , a_fabb_merce_sal
                                       , a_num_terreni, a_num_aree
                                       , a_num_fabb_ab, a_num_fabb_rurali, a_num_fabb_altri
                                       , a_num_fabb_d, a_num_fabb_merce
                                       );
        -- Calcolo importi totali
        stampa_com_imposta.importi_imu ( a_cod_fiscale, a_anno
                                       , 'U', a_dovuto_versato
                                       , a_terreni_comu, a_terreni_erar
                                       , a_aree_comu, a_aree_erar
                                       , a_ab_comu, a_detrazione, a_rurali_comu
                                       , a_altri_comu, a_altri_erar
                                       , a_fabb_d_comu, a_fabb_d_erar
                                       , a_fabb_merce
                                       , a_num_terreni, a_num_aree
                                       , a_num_fabb_ab, a_num_fabb_rurali, a_num_fabb_altri
                                       , a_num_fabb_d, a_num_fabb_merce
                                       );
        if a_ab_comu <> 0 then
           t_riep_imposta.extend(1);
           w_ind := w_ind + 1;
           t_riep_imposta(w_ind).descrizione    := 'Abitazione principale';
           t_riep_imposta(w_ind).num_fabbricati := a_num_fabb_ab;
           t_riep_imposta(w_ind).importo_acc    := a_ab_comu_acc;
           t_riep_imposta(w_ind).importo_sal    := a_ab_comu_sal;
           t_riep_imposta(w_ind).importo_tot    := a_ab_comu;
        end if;
        if a_rurali_comu <> 0 then
           t_riep_imposta.extend(1);
           w_ind := w_ind + 1;
           t_riep_imposta(w_ind).descrizione    := 'Fabbr.Rurali Uso Strum.';
           t_riep_imposta(w_ind).num_fabbricati := a_num_fabb_rurali;
           t_riep_imposta(w_ind).importo_acc    := a_rurali_comu_acc;
           t_riep_imposta(w_ind).importo_sal    := a_rurali_comu_sal;
           t_riep_imposta(w_ind).importo_tot    := a_rurali_comu;
        end if;
        if (a_terreni_comu + a_terreni_erar) <> 0 then
           t_riep_imposta.extend(1);
           w_ind := w_ind + 1;
           t_riep_imposta(w_ind).descrizione    := 'Terreni Agricoli';
           t_riep_imposta(w_ind).num_fabbricati := a_num_terreni;
           t_riep_imposta(w_ind).importo_acc    := a_terreni_comu_acc + a_terreni_erar_acc;
           t_riep_imposta(w_ind).importo_sal    := a_terreni_comu_sal + a_terreni_erar_sal;
           t_riep_imposta(w_ind).importo_tot    := a_terreni_comu + a_terreni_erar;
        end if;
        if (a_aree_comu + a_aree_erar) <> 0 then
           t_riep_imposta.extend(1);
           w_ind := w_ind + 1;
           t_riep_imposta(w_ind).descrizione    := 'Aree Fabbricabili';
           t_riep_imposta(w_ind).num_fabbricati := a_num_aree;
           t_riep_imposta(w_ind).importo_acc    := a_aree_comu_acc + a_aree_erar_acc;
           t_riep_imposta(w_ind).importo_sal    := a_aree_comu_sal + a_aree_erar_sal;
           t_riep_imposta(w_ind).importo_tot    := a_aree_comu + a_aree_erar;
        end if;
        if (a_altri_comu + a_altri_erar) <> 0 then
           t_riep_imposta.extend(1);
           w_ind := w_ind + 1;
           t_riep_imposta(w_ind).descrizione    := 'Altri Fabbricati';
           t_riep_imposta(w_ind).num_fabbricati := a_num_fabb_altri;
           t_riep_imposta(w_ind).importo_acc    := a_altri_comu_acc + a_altri_erar_acc;
           t_riep_imposta(w_ind).importo_sal    := a_altri_comu_sal + a_altri_erar_sal;
           t_riep_imposta(w_ind).importo_tot    := a_altri_comu + a_altri_erar;
        end if;
        if (a_fabb_d_comu + a_fabb_d_erar) <> 0 then
           t_riep_imposta.extend(1);
           w_ind := w_ind + 1;
           t_riep_imposta(w_ind).descrizione    := 'Fabbr.Uso Produttivo';
           t_riep_imposta(w_ind).num_fabbricati := a_num_fabb_d;
           t_riep_imposta(w_ind).importo_acc    := a_fabb_d_comu_acc + a_fabb_d_erar_acc;
           t_riep_imposta(w_ind).importo_sal    := a_fabb_d_comu_sal + a_fabb_d_erar_sal;
           t_riep_imposta(w_ind).importo_tot    := a_fabb_d_comu + a_fabb_d_erar;
        end if;
        if a_fabb_merce <> 0 then
           t_riep_imposta.extend(1);
           w_ind := w_ind + 1;
           t_riep_imposta(w_ind).descrizione    := 'Fabbricati Merce';
           t_riep_imposta(w_ind).num_fabbricati := a_num_fabb_merce;
           t_riep_imposta(w_ind).importo_acc    := a_fabb_merce_acc;
           t_riep_imposta(w_ind).importo_sal    := a_fabb_merce_sal;
           t_riep_imposta(w_ind).importo_tot    := a_fabb_merce;
        end if;
     else
        -- Calcolo importi acconto
        stampa_com_imposta.importi_tasi ( a_cod_fiscale, a_anno, 'A', nvl(a_dovuto_versato,'D')
                                        , a_terreni_comu_acc, a_aree_comu_acc
                                        , a_ab_comu_acc, a_detrazione_acc
                                        , a_rurali_comu_acc, a_altri_comu_acc
                                        , a_num_terreni, a_num_aree
                                        , a_num_fabb_ab, a_num_fabb_rurali
                                        , a_num_fabb_altri
                                        , a_fabb_d_comu_acc, a_num_fabb_d
                                        );
        -- Calcolo importi saldo
        stampa_com_imposta.importi_tasi ( a_cod_fiscale, a_anno, 'S', nvl(a_dovuto_versato,'D')
                                        , a_terreni_comu_sal, a_aree_comu_sal
                                        , a_ab_comu_sal, a_detrazione_sal
                                        , a_rurali_comu_sal, a_altri_comu_sal
                                        , a_num_terreni, a_num_aree
                                        , a_num_fabb_ab, a_num_fabb_rurali
                                        , a_num_fabb_altri
                                        , a_fabb_d_comu_sal, a_num_fabb_d
                                        );
        -- Calcolo importi totali
        stampa_com_imposta.importi_tasi ( a_cod_fiscale, a_anno, 'U', nvl(a_dovuto_versato,'D')
                                        , a_terreni_comu, a_aree_comu
                                        , a_ab_comu, a_detrazione
                                        , a_rurali_comu, a_altri_comu
                                        , a_num_terreni, a_num_aree
                                        , a_num_fabb_ab, a_num_fabb_rurali
                                        , a_num_fabb_altri
                                        , a_fabb_d_comu, a_num_fabb_d
                                        );
        if a_ab_comu <> 0 then
           t_riep_imposta.extend(1);
           w_ind := w_ind + 1;
           t_riep_imposta(w_ind).descrizione    := 'Abitazione principale';
           t_riep_imposta(w_ind).num_fabbricati := a_num_fabb_ab;
           t_riep_imposta(w_ind).importo_acc    := a_ab_comu_acc;
           t_riep_imposta(w_ind).importo_sal    := a_ab_comu_sal;
           t_riep_imposta(w_ind).importo_tot    := a_ab_comu;
        end if;
        if a_rurali_comu <> 0 then
           t_riep_imposta.extend(1);
           w_ind := w_ind + 1;
           t_riep_imposta(w_ind).descrizione    := 'Fabbr.Rurali Uso Strum.';
           t_riep_imposta(w_ind).num_fabbricati := a_num_fabb_rurali;
           t_riep_imposta(w_ind).importo_acc    := a_rurali_comu_acc;
           t_riep_imposta(w_ind).importo_sal    := a_rurali_comu_sal;
           t_riep_imposta(w_ind).importo_tot    := a_rurali_comu;
        end if;
        if a_aree_comu <> 0 then
           t_riep_imposta.extend(1);
           w_ind := w_ind + 1;
           t_riep_imposta(w_ind).descrizione    := 'Aree Fabbricabili';
           t_riep_imposta(w_ind).num_fabbricati := a_num_aree;
           t_riep_imposta(w_ind).importo_acc    := a_aree_comu_acc;
           t_riep_imposta(w_ind).importo_sal    := a_aree_comu_sal;
           t_riep_imposta(w_ind).importo_tot    := a_aree_comu;
        end if;
        if a_altri_comu <> 0 then
           t_riep_imposta.extend(1);
           w_ind := w_ind + 1;
           t_riep_imposta(w_ind).descrizione    := 'Altri Fabbricati';
           t_riep_imposta(w_ind).num_fabbricati := a_num_fabb_altri;
           t_riep_imposta(w_ind).importo_acc    := a_altri_comu_acc;
           t_riep_imposta(w_ind).importo_sal    := a_altri_comu_sal;
           t_riep_imposta(w_ind).importo_tot    := a_altri_comu;
        end if;
     end if;
  end if;
  -- Calcolo totali finali
  w_tot_fabbricati := 0;
  w_tot_acconto    := 0;
  w_tot_saldo      := 0;
  w_totale         := 0;
  if t_riep_imposta.count() > 0 then
     for i in t_riep_imposta.first..t_riep_imposta.last
     loop
       t_riep_imposta(i).tipo_tributo   := a_tipo_tributo;
       t_riep_imposta(i).cod_fiscale    := a_cod_fiscale;
       t_riep_imposta(i).anno           := a_anno;
       t_riep_imposta(i).dovuto_versato := nvl(a_dovuto_versato,'D');
       t_riep_imposta(i).modello        := a_modello;
       w_tot_fabbricati            := w_tot_fabbricati + nvl(t_riep_imposta(i).num_fabbricati,0);
       w_tot_acconto               := w_tot_acconto    + t_riep_imposta(i).importo_acc;
       w_tot_saldo                 := w_tot_saldo      + t_riep_imposta(i).importo_sal;
       w_totale                    := w_totale         + t_riep_imposta(i).importo_tot;
       t_riep_imposta(i).st_importo_acc := stampa_common.f_formatta_numero(t_riep_imposta(i).importo_acc,'I');
       t_riep_imposta(i).st_importo_sal := stampa_common.f_formatta_numero(t_riep_imposta(i).importo_sal,'I');
       t_riep_imposta(i).st_importo_tot := stampa_common.f_formatta_numero(t_riep_imposta(i).importo_tot,'I');
     end loop;
  end if;
  -- Inserimento riga di totale
  w_ind := t_riep_imposta.count;
  t_riep_imposta.extend(1);
  w_ind := w_ind + 1;
  t_riep_imposta(w_ind).tipo_tributo    := a_tipo_tributo;
  t_riep_imposta(w_ind).cod_fiscale     := a_cod_fiscale;
  t_riep_imposta(w_ind).anno            := a_anno;
  t_riep_imposta(w_ind).dovuto_versato  := nvl(a_dovuto_versato,'D');
  t_riep_imposta(w_ind).modello         := a_modello;
  t_riep_imposta(w_ind).descrizione     := 'Totale Calcolato';
  t_riep_imposta(w_ind).num_fabbricati  := w_tot_fabbricati;
  t_riep_imposta(w_ind).importo_acc     := w_tot_acconto;
  t_riep_imposta(w_ind).importo_sal     := w_tot_saldo;
  t_riep_imposta(w_ind).importo_tot     := w_totale;
  t_riep_imposta(w_ind).st_importo_acc  := stampa_common.f_formatta_numero(w_tot_acconto,'I');
  t_riep_imposta(w_ind).st_importo_sal  := stampa_common.f_formatta_numero(w_tot_saldo,'I');
  t_riep_imposta(w_ind).st_importo_tot  := stampa_common.f_formatta_numero(w_totale,'I');
  --
  open rc for select * from table(f_get_collection);
  return rc;
  --
end;
----------------------------------------------------------------------------------
  function RIEPILOGO_IMPOSTA_F24
  ( a_tipo_tributo           in     varchar2 default ''
  , a_cod_fiscale            in     varchar2 default ''
  , a_anno                   in     number   default -1
  , a_dovuto_versato         in     varchar2 default ''
  , a_modello                in     number   default -1
  )
  return sys_refcursor is
  /*************************************************************************
   NOME:        RIEPILOGO_IMPOSTA_ANNUALE
   DESCRIZIONE: TributiWeb: stampa comunicazione da folder "Imposte" di
                situazione contribuente
   PARAMETRI:   Tipo tributo        ICI/TASI
                Codice fiscale      Codice fiscale del contribuente
                Anno                Anno di riferimento
   RITORNA:     ref_cursor          Elenco imposte suddivise per tipologia
   NOTE:
   Rev.    Date         Author      Note
   000     03/09/2021   VD          Prima emissione.
  *************************************************************************/
  a_terreni_comu_acc                number;
  a_terreni_erar_acc                number;
  a_aree_comu_acc                   number;
  a_aree_erar_acc                   number;
  a_ab_comu_acc                     number;
  a_detrazione_acc                  number;
  a_rurali_comu_acc                 number;
  a_altri_comu_acc                  number;
  a_altri_erar_acc                  number;
  a_fabb_d_comu_acc                 number;
  a_fabb_d_erar_acc                 number;
  a_fabb_merce_acc                  number;
  a_num_terreni_acc                 number;
  a_num_aree_acc                    number;
  a_num_fabb_ab_acc                 number;
  a_num_fabb_rurali_acc             number;
  a_num_fabb_altri_acc              number;
  a_num_fabb_d_acc                  number;
  a_num_fabb_merce_acc              number;
  a_terreni_comu_sal                number;
  a_terreni_erar_sal                number;
  a_aree_comu_sal                   number;
  a_aree_erar_sal                   number;
  a_ab_comu_sal                     number;
  a_detrazione_sal                  number;
  a_rurali_comu_sal                 number;
  a_altri_comu_sal                  number;
  a_altri_erar_sal                  number;
  a_fabb_d_comu_sal                 number;
  a_fabb_d_erar_sal                 number;
  a_fabb_merce_sal                  number;
  a_num_terreni_sal                 number;
  a_num_aree_sal                    number;
  a_num_fabb_ab_sal                 number;
  a_num_fabb_rurali_sal             number;
  a_num_fabb_altri_sal              number;
  a_num_fabb_d_sal                  number;
  a_num_fabb_merce_sal              number;
  w_tot_acconto                     number;
  w_tot_acc_arr                     number;
  w_tot_saldo                       number;
  w_tot_sal_arr                     number;
  w_totale                          number;
  w_totale_arr                      number;
  w_ind                             number;
  rc                                sys_refcursor;
begin
  t_riep_imposta.delete;
  w_ind := 0;
  if a_tipo_tributo is not null then
    if a_tipo_tributo = 'ICI' then
       -- Calcolo importi acconto
       stampa_com_imposta.importi_imu ( a_cod_fiscale, a_anno
                                      , 'A', a_dovuto_versato
                                      , a_terreni_comu_acc, a_terreni_erar_acc
                                      , a_aree_comu_acc, a_aree_erar_acc
                                      , a_ab_comu_acc, a_detrazione_acc
                                      , a_rurali_comu_acc
                                      , a_altri_comu_acc, a_altri_erar_acc
                                      , a_fabb_d_comu_acc, a_fabb_d_erar_acc
                                      , a_fabb_merce_acc
                                      , a_num_terreni_acc, a_num_aree_acc
                                      , a_num_fabb_ab_acc, a_num_fabb_rurali_acc
                                      , a_num_fabb_altri_acc
                                      , a_num_fabb_d_acc, a_num_fabb_merce_acc
                                      );
       -- Calcolo importi a saldo
       stampa_com_imposta.importi_imu ( a_cod_fiscale, a_anno
                                      , 'S', a_dovuto_versato
                                      , a_terreni_comu_sal, a_terreni_erar_sal
                                      , a_aree_comu_sal, a_aree_erar_sal
                                      , a_ab_comu_sal, a_detrazione_sal
                                      , a_rurali_comu_sal
                                      , a_altri_comu_sal, a_altri_erar_sal
                                      , a_fabb_d_comu_sal, a_fabb_d_erar_sal
                                      , a_fabb_merce_sal
                                      , a_num_terreni_sal, a_num_aree_sal
                                      , a_num_fabb_ab_sal, a_num_fabb_rurali_sal, a_num_fabb_altri_sal
                                      , a_num_fabb_d_sal, a_num_fabb_merce_sal
                                      );
       if nvl(a_ab_comu_acc,0) <> 0 or nvl(a_ab_comu_sal,0) <> 0 then
          t_riep_imposta.extend(1);
          w_ind := w_ind + 1;
          t_riep_imposta(w_ind).descrizione    := 'Abitazione principale';
          t_riep_imposta(w_ind).codice_f24     := '3912';
          t_riep_imposta(w_ind).num_fabbricati := a_num_fabb_ab_sal;
          t_riep_imposta(w_ind).importo_acc    := a_ab_comu_acc;
          t_riep_imposta(w_ind).importo_sal    := a_ab_comu_sal;
       end if;
       if nvl(a_rurali_comu_acc,0) <> 0 or nvl(a_rurali_comu_sal,0) <> 0 then
          t_riep_imposta.extend(1);
          w_ind := w_ind + 1;
          t_riep_imposta(w_ind).descrizione    := 'Fabbr.Rurali Uso Strum.';
          t_riep_imposta(w_ind).codice_f24     := '3913';
          t_riep_imposta(w_ind).num_fabbricati := a_num_fabb_rurali_sal;
          t_riep_imposta(w_ind).importo_acc    := a_rurali_comu_acc;
          t_riep_imposta(w_ind).importo_sal    := a_rurali_comu_sal;
       end if;
       if nvl(a_terreni_comu_acc,0) <> 0 or nvl(a_terreni_comu_sal,0) <> 0 then
          t_riep_imposta.extend(1);
          w_ind := w_ind + 1;
          t_riep_imposta(w_ind).descrizione    := 'Terreni Agricoli';
          t_riep_imposta(w_ind).codice_f24     := '3914 - Comune';
          t_riep_imposta(w_ind).num_fabbricati := a_num_terreni_sal;
          t_riep_imposta(w_ind).importo_acc    := a_terreni_comu_acc;
          t_riep_imposta(w_ind).importo_sal    := a_terreni_comu_sal;
       end if;
       if nvl(a_terreni_erar_acc,0) <> 0 or nvl(a_terreni_erar_sal,0) <> 0 then
          t_riep_imposta.extend(1);
          w_ind := w_ind + 1;
          t_riep_imposta(w_ind).descrizione    := 'Terreni Agricoli';
          t_riep_imposta(w_ind).codice_f24     := '3915 - Stato';
          t_riep_imposta(w_ind).num_fabbricati := a_num_terreni_sal;
          t_riep_imposta(w_ind).importo_acc    := a_terreni_erar_acc;
          t_riep_imposta(w_ind).importo_sal    := a_terreni_erar_sal;
       end if;
       if nvl(a_aree_comu_acc,0) <> 0 or nvl(a_aree_comu_sal,0) <> 0 then
          t_riep_imposta.extend(1);
          w_ind := w_ind + 1;
          t_riep_imposta(w_ind).descrizione    := 'Aree Fabbricabili';
          t_riep_imposta(w_ind).codice_f24     := '3916 - Comune';
          t_riep_imposta(w_ind).num_fabbricati := a_num_aree_sal;
          t_riep_imposta(w_ind).importo_acc    := a_aree_comu_acc;
          t_riep_imposta(w_ind).importo_sal    := a_aree_comu_sal;
       end if;
       if nvl(a_aree_erar_acc,0) <> 0 or nvl(a_aree_erar_sal,0) <> 0 then
          t_riep_imposta.extend(1);
          w_ind := w_ind + 1;
          t_riep_imposta(w_ind).descrizione    := 'Aree Fabbricabili';
          t_riep_imposta(w_ind).codice_f24     := '3917 - Stato';
          t_riep_imposta(w_ind).num_fabbricati := a_num_aree_sal;
          t_riep_imposta(w_ind).importo_acc    := a_aree_erar_acc;
          t_riep_imposta(w_ind).importo_sal    := a_aree_erar_sal;
       end if;
       if nvl(a_altri_comu_acc,0) <> 0 or nvl(a_altri_comu_sal,0) <> 0 then
          t_riep_imposta.extend(1);
          w_ind := w_ind + 1;
          t_riep_imposta(w_ind).descrizione    := 'Altri Fabbricati';
          t_riep_imposta(w_ind).codice_f24     := '3918 - Comune';
          t_riep_imposta(w_ind).num_fabbricati := a_num_fabb_altri_sal;
          t_riep_imposta(w_ind).importo_acc    := a_altri_comu_acc;
          t_riep_imposta(w_ind).importo_sal    := a_altri_comu_sal;
       end if;
       if nvl(a_altri_erar_acc,0) <> 0 or nvl(a_altri_erar_sal,0) <> 0 then
          t_riep_imposta.extend(1);
          w_ind := w_ind + 1;
          t_riep_imposta(w_ind).descrizione    := 'Altri Fabbricati';
          t_riep_imposta(w_ind).codice_f24     := '3919 - Stato';
          t_riep_imposta(w_ind).num_fabbricati := a_num_fabb_altri_sal;
          t_riep_imposta(w_ind).importo_acc    := a_altri_erar_acc;
          t_riep_imposta(w_ind).importo_sal    := a_altri_erar_sal;
       end if;
       if nvl(a_fabb_d_comu_acc,0) <> 0 or nvl(a_fabb_d_comu_sal,0) <> 0 then
          t_riep_imposta.extend(1);
          w_ind := w_ind + 1;
          t_riep_imposta(w_ind).descrizione    := 'Fabbr.Uso Produttivo';
          t_riep_imposta(w_ind).codice_f24     := '3930 - Comune';
          t_riep_imposta(w_ind).num_fabbricati := a_num_fabb_d_sal;
          t_riep_imposta(w_ind).importo_acc    := a_fabb_d_comu_acc;
          t_riep_imposta(w_ind).importo_sal    := a_fabb_d_comu_sal;
       end if;
       if nvl(a_fabb_d_erar_acc,0) <> 0 or nvl(a_fabb_d_erar_sal,0) <> 0 then
          t_riep_imposta.extend(1);
          w_ind := w_ind + 1;
          t_riep_imposta(w_ind).descrizione    := 'Fabbr.Uso Produttivo';
          t_riep_imposta(w_ind).codice_f24     := '3925 - Stato';
          t_riep_imposta(w_ind).num_fabbricati := a_num_fabb_d_sal;
          t_riep_imposta(w_ind).importo_acc    := a_fabb_d_erar_acc;
          t_riep_imposta(w_ind).importo_sal    := a_fabb_d_erar_sal;
       end if;
       if nvl(a_fabb_merce_acc,0) <> 0 or nvl(a_fabb_merce_sal,0) <> 0 then
          t_riep_imposta.extend(1);
          w_ind := w_ind + 1;
          t_riep_imposta(w_ind).descrizione    := 'Fabbricati Merce';
          t_riep_imposta(w_ind).codice_f24     := '3939';
          t_riep_imposta(w_ind).num_fabbricati := a_num_fabb_merce_sal;
          t_riep_imposta(w_ind).importo_acc    := a_fabb_merce_acc;
          t_riep_imposta(w_ind).importo_sal    := a_fabb_merce_sal;
       end if;
    else
       -- Calcolo importi acconto
       stampa_com_imposta.importi_tasi ( a_cod_fiscale, a_anno, 'A', nvl(a_dovuto_versato,'D')
                                       , a_terreni_comu_acc, a_aree_comu_acc
                                       , a_ab_comu_acc, a_detrazione_acc
                                       , a_rurali_comu_acc, a_altri_comu_acc
                                       , a_num_terreni_acc, a_num_aree_acc
                                       , a_num_fabb_ab_acc, a_num_fabb_rurali_acc
                                       , a_num_fabb_altri_acc
                                       , a_fabb_d_comu_acc, a_num_fabb_d_acc
                                       );
       -- Calcolo importi a saldo
       stampa_com_imposta.importi_tasi ( a_cod_fiscale, a_anno, 'S', nvl(a_dovuto_versato,'D')
                                       , a_terreni_comu_sal, a_aree_comu_sal
                                       , a_ab_comu_sal, a_detrazione_sal
                                       , a_rurali_comu_sal, a_altri_comu_sal
                                       , a_num_terreni_sal, a_num_aree_sal
                                       , a_num_fabb_ab_sal, a_num_fabb_rurali_sal
                                       , a_num_fabb_altri_sal
                                       , a_fabb_d_comu_sal, a_num_fabb_d_sal
                                       );
       if nvl(a_ab_comu_acc,0) <> 0 or nvl(a_ab_comu_sal,0) <> 0 then
          t_riep_imposta.extend(1);
          w_ind := w_ind + 1;
          t_riep_imposta(w_ind).descrizione    := 'Abitazione principale';
          t_riep_imposta(w_ind).codice_f24     := '3958';
          t_riep_imposta(w_ind).num_fabbricati := a_num_fabb_ab_sal;
          t_riep_imposta(w_ind).importo_acc    := a_ab_comu_acc;
          t_riep_imposta(w_ind).importo_sal    := a_ab_comu_sal;
       end if;
       if nvl(a_rurali_comu_acc,0) <> 0 or nvl(a_rurali_comu_sal,0) <> 0 then
          t_riep_imposta.extend(1);
          w_ind := w_ind + 1;
          t_riep_imposta(w_ind).descrizione    := 'Fabbr.Rurali Uso Strum.';
          t_riep_imposta(w_ind).codice_f24     := '3959';
          t_riep_imposta(w_ind).num_fabbricati := a_num_fabb_rurali_sal;
          t_riep_imposta(w_ind).importo_acc    := a_rurali_comu_acc;
          t_riep_imposta(w_ind).importo_sal    := a_rurali_comu_sal;
       end if;
       if nvl(a_aree_comu_acc,0) <> 0 or nvl(a_aree_comu_sal,0) <> 0 then
          t_riep_imposta.extend(1);
          w_ind := w_ind + 1;
          t_riep_imposta(w_ind).descrizione    := 'Aree Fabbricabili';
          t_riep_imposta(w_ind).codice_f24     := '3960';
          t_riep_imposta(w_ind).num_fabbricati := a_num_aree_sal;
          t_riep_imposta(w_ind).importo_acc    := a_aree_comu_acc;
          t_riep_imposta(w_ind).importo_sal    := a_aree_comu_sal;
       end if;
       if nvl(a_altri_comu_acc,0) <> 0 or nvl(a_altri_comu_sal,0) <> 0 then
          t_riep_imposta.extend(1);
          w_ind := w_ind + 1;
          t_riep_imposta(w_ind).descrizione    := 'Altri Fabbricati';
          t_riep_imposta(w_ind).codice_f24     := '3961';
          t_riep_imposta(w_ind).num_fabbricati := a_num_fabb_altri_sal;
          t_riep_imposta(w_ind).importo_acc    := a_altri_comu_acc;
          t_riep_imposta(w_ind).importo_sal    := a_altri_comu_sal;
       end if;
    end if;
  end if;
  -- Calcolo importo totale e importi arrotondati
  w_tot_acconto := 0;
  w_tot_acc_arr := 0;
  w_tot_saldo   := 0;
  w_tot_sal_arr := 0;
  w_totale      := 0;
  w_totale_arr  := 0;
  if t_riep_imposta.count() > 0 then
     for i in t_riep_imposta.first..t_riep_imposta.last
     loop
       t_riep_imposta(i).tipo_tributo     := a_tipo_tributo;
       t_riep_imposta(i).cod_fiscale      := a_cod_fiscale;
       t_riep_imposta(i).anno             := a_anno;
       t_riep_imposta(i).dovuto_versato   := nvl(a_dovuto_versato,'D');
       t_riep_imposta(i).modello          := a_modello;
       t_riep_imposta(i).importo_tot      := t_riep_imposta(i).importo_acc + t_riep_imposta(i).importo_sal;
       t_riep_imposta(i).importo_tot_arr  := round(t_riep_imposta(i).importo_tot);
       t_riep_imposta(i).importo_acc_arr  := round(t_riep_imposta(i).importo_acc);
       t_riep_imposta(i).importo_sal_arr  := t_riep_imposta(i).importo_tot_arr - t_riep_imposta(i).importo_acc_arr;
       t_riep_imposta(i).st_importo_acc     := stampa_common.f_formatta_numero(t_riep_imposta(i).importo_acc,'I');
       t_riep_imposta(i).st_importo_sal     := stampa_common.f_formatta_numero(t_riep_imposta(i).importo_sal,'I');
       t_riep_imposta(i).st_importo_tot     := stampa_common.f_formatta_numero(t_riep_imposta(i).importo_tot,'I');
       t_riep_imposta(i).st_importo_acc_arr := stampa_common.f_formatta_numero(t_riep_imposta(i).importo_acc_arr,'I');
       t_riep_imposta(i).st_importo_sal_arr := stampa_common.f_formatta_numero(t_riep_imposta(i).importo_sal_arr,'I');
       t_riep_imposta(i).st_importo_tot_arr := stampa_common.f_formatta_numero(t_riep_imposta(i).importo_tot_arr,'I');
       w_tot_acconto := w_tot_acconto + t_riep_imposta(i).importo_acc;
       w_tot_acc_arr := w_tot_acc_arr + t_riep_imposta(i).importo_acc_arr;
       w_tot_saldo   := w_tot_saldo   + t_riep_imposta(i).importo_sal;
       w_tot_sal_arr := w_tot_sal_arr + t_riep_imposta(i).importo_sal_arr;
       w_totale      := w_totale      + t_riep_imposta(i).importo_tot;
       w_totale_arr  := w_totale_arr  + t_riep_imposta(i).importo_tot_arr;
    end loop;
  end if;
  -- Inserimento riga di totale
  w_ind := t_riep_imposta.count;
  t_riep_imposta.extend;
  w_ind := w_ind + 1;
  t_riep_imposta(w_ind).tipo_tributo    := a_tipo_tributo;
  t_riep_imposta(w_ind).cod_fiscale     := a_cod_fiscale;
  t_riep_imposta(w_ind).anno            := a_anno;
  t_riep_imposta(w_ind).dovuto_versato  := nvl(a_dovuto_versato,'D');
  t_riep_imposta(w_ind).modello         := a_modello;
  t_riep_imposta(w_ind).descrizione     := 'Totale Calcolato';
  t_riep_imposta(w_ind).importo_acc     := w_tot_acconto;
  t_riep_imposta(w_ind).importo_acc_arr := w_tot_acc_arr;
  t_riep_imposta(w_ind).importo_sal     := w_tot_saldo;
  t_riep_imposta(w_ind).importo_sal_arr := w_tot_sal_arr;
  t_riep_imposta(w_ind).importo_tot     := w_totale;
  t_riep_imposta(w_ind).importo_tot_arr := w_totale_arr;
  t_riep_imposta(w_ind).st_importo_acc     := stampa_common.f_formatta_numero(t_riep_imposta(w_ind).importo_acc,'I');
  t_riep_imposta(w_ind).st_importo_sal     := stampa_common.f_formatta_numero(t_riep_imposta(w_ind).importo_sal,'I');
  t_riep_imposta(w_ind).st_importo_tot     := stampa_common.f_formatta_numero(t_riep_imposta(w_ind).importo_tot,'I');
  t_riep_imposta(w_ind).st_importo_acc_arr := stampa_common.f_formatta_numero(t_riep_imposta(w_ind).importo_acc_arr,'I');
  t_riep_imposta(w_ind).st_importo_sal_arr := stampa_common.f_formatta_numero(t_riep_imposta(w_ind).importo_sal_arr,'I');
  t_riep_imposta(w_ind).st_importo_tot_arr := stampa_common.f_formatta_numero(t_riep_imposta(w_ind).importo_tot_arr,'I');
  --
  open rc for select * from table(f_get_collection);
  return rc;
  --
end;
----------------------------------------------------------------------------------
  function DATI_OGGETTI_PRATICA_OLD
  ( a_cod_fiscale                      varchar2 default ''
  , a_tipo_tributo                     varchar2 default ''
  , a_anno                             number default -1
  , a_modello                          number default -1
  ) return sys_refcursor is
  /******************************************************************************
    NOME:        DATI_OGGETTI_PRATICA.
    DESCRIZIONE: Restituisce un ref_cursor contenente l'elenco degli oggetti
                 del contribuente, filtrato per anno e tipo tributo.
                 Se tipo_tributo = '%' si considerano tutti i tipi tributo.
                 Se anno = 9999 si considerano tutti gli anni.
    RITORNA:     ref_cursor.
    NOTE:
  ******************************************************************************/
    rc                              sys_refcursor;
  begin
    open rc for
      select a_modello modello,
             ogco.anno,
             ogco.tipo_rapporto,
             ogco.data_decorrenza,
             ogco.data_cessazione,
             ogco.mesi_possesso,
             ogpr.tributo,
             ogpr.categoria categoria_ogpr,
             ogpr.tipo_tariffa,
             ogpr.consistenza,
             ogpr.valore,
             prtr.tipo_tributo,
             f_descrizione_titr(prtr.tipo_tributo,prtr.anno) descr_tipo_tributo,
             prtr.tipo_pratica,
             prtr.tipo_evento,
             decode( ogge.cod_via, null, indirizzo_localita, denom_uff||decode( num_civ, null, '',  ', '||num_civ )||decode( suffisso, null, '', '/'||suffisso )||decode( interno, null, '', ' int. '||interno )) indir,
             decode( ogge.cod_via, null, indirizzo_localita, denom_uff) indirizzo,
             to_char(ogge.num_civ) num_civ,
             ogge.suffisso suff,
             /*21/01/2015 Betta e Andrea se tarsu si visualizza il tipo oggetto dell oggetto*/
             decode(prtr.tipo_tributo,'TARSU', ogge.tipo_oggetto,nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)) tipo_oggetto,
             ogge.partita,
             ogge.sezione,
             ogge.foglio,
             ogge.numero,
             ogge.subalterno,
             ogge.zona,
             ogge.oggetto,
             ogge.descrizione,
             nvl(ogpr.categoria_catasto,ogge.categoria_catasto)  categoria,
             nvl(ogpr.classe_catasto,ogge.classe_catasto)  classe,
             decode(prtr.tipo_tributo,'ICI',flag_possesso, 'TASI',flag_possesso,null) flag_p,
             ogco.perc_possesso,
             ogco.flag_esclusione,
             ogpr.flag_contenzioso,
             prtr.pratica,
             ogge.data_cessazione,
             decode(ogge.data_cessazione,null,null,'S'),
             ogpr.oggetto_pratica,
             ogco.flag_ab_principale,
             decode(flag_ab_principale, null, nvl(ogpr.numero_familiari, cosu.numero_familiari), f_ultimo_faso(cont.ni,a_anno)) numero_familiari
        from ARCHIVIO_VIE ARVI,
             OGGETTI OGGE,
             PRATICHE_TRIBUTO PRTR,
             OGGETTI_PRATICA OGPR,
             OGGETTI_CONTRIBUENTE OGCO,
             CONTRIBUENTI CONT,
             COMPONENTI_SUPERFICIE COSU
       WHERE arvi.cod_via (+)          = ogge.cod_via          and
             prtr.pratica              = ogpr.pratica          and
             ogge.oggetto              = ogpr.oggetto          and
             ogpr.oggetto_pratica      = ogco.oggetto_pratica  and
             ogco.cod_fiscale          = a_cod_fiscale         and
             cont.cod_fiscale          = ogco.cod_fiscale      and
             cosu.anno (+)             = decode(a_anno,9999,to_number(to_char(sysdate,'yyyy')),a_anno)   and
             ogpr.consistenza between cosu.da_consistenza (+) and cosu.a_consistenza (+) and
             prtr.tipo_tributo         like a_tipo_tributo     and
             prtr.tipo_pratica         in ('A','D','L')        and
             prtr.flag_annullamento is null                    and
             nvl(to_number(to_char(ogco.data_decorrenza,'YYYY')),nvl(ogco.anno,0))
                                      <= a_anno               and
             /* inserita il 22/10/2003 la decode per risolvere per anno 9999
                da controllare e verifica re per D e A < anno
                e A con flag_possesso is null */
             ogpr.oggetto_pratica      = f_max_ogpr_cont_ogge(ogge.oggetto
                                                             ,a_cod_fiscale
                                                             ,prtr.tipo_tributo
                                                             ,decode(a_anno,9999,'%',prtr.tipo_pratica)
                                                             ,a_anno
                                                             ,'%'
                                                             ) and
              decode(prtr.tipo_tributo
                    ,'ICI',decode(flag_possesso
                                   ,'S',flag_possesso
                                  ,decode(a_anno,9999,'S',prtr.anno,'S',null)
                                 )
                    ,'S'
                    )                  = 'S';
    return rc;
  end dati_oggetti_pratica_old;
end STAMPA_COM_IMPOSTA;
/
