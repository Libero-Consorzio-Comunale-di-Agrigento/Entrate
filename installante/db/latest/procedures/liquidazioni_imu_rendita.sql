--liquibase formatted sql 
--changeset abrandolini:20250326_152423_liquidazioni_imu_rendita stripComments:false runOnChange:true 
 
create or replace procedure LIQUIDAZIONI_IMU_RENDITA
/*************************************************************************
 NOME:        LIQUIDAZIONI_IMU_RENDITA
 DESCRIZIONE: Calcolo liquidazione IMU per variazioni di rendita
 Rev.    Date         Author      Note
 018     05/06/2025   RV          #78725
                                  Modifica query determinazione importi
                                  Ora prende i dati pure da oggetti_ogim, se presenti
 017     14/04/2025   RV          #77608
                                  Adeguamento gestione sequenza sanzioni 
 016     30/05/2024   AB          #73009 Acquisito anche imm_storico di ogpr e inserito nella Liq
 015     08/04/2024   AB          #71613 Utilizzato il campo w_mese_inizio in relazione ai mesi
                                  di inizio periodo per individuare un unico record e cosi
                                  avere la rendita e il valore corretti, altrimenti null
 014     25/09/2023   RV          #66351 Accetta valore_dic null per tipi 1 e tipi 3 con Ctg. E ed F
 013     22/08/2023   AB          #66402 Aggiunti controlli per valorizzare correttamente
                                  mese inizio e fine, nel caso di da_mese > 12
 012     09/08/2023   AB          Aggiunti controlli per valorizzare correttamente
                                  mese inizio e fine
 011     02/08/2023   VM          #65986 - Fix calcolo mesi esclusione in base al flag esclusione
 010     08/05/2023   AB          Controllo periodi considerando data_fine >= w_anno
 009     31/01/2023   AB          Controllo date utilizzando anche periodi_riog
 008     21/12/2022   AB          Nel caso di importo a 0 e mesi esclusione
                                  presenti o flag_esclsuione = 'S'
                                  prendo il valore da valore_dic rivalutato
 007     15/12/2022   AB          Gestione del da_mese_possesso per il
                                  controllo dei riog e annullo rev 6
 006     02/08/2022   VD          Aggiunto test su flag esclusione per non
                                  trattare gli immobili esclusi
 005     23/09/2020   VD          Aggiunta gestione fabbricati merce
 004     22/10/2019   VD          Aggiunto motivo di non liquidabilita del
                                  contribuente in inserimento wrk_generale
 003     22/07/2016   VD          Aggiunta gestione variabili di I/O
                                  per versamenti mini IMU
                                  (totale/ab.princ./terreni)
 002     19/07/2016   VD          Aggiunta gestione variabili di I/O
                                  per mini IMU (totale/ab.princ./terreni)
 001     08/07/2016   VD          Aggiunta gestione campi per mini IMU
                                  in inserimento OGGETTI_IMPOSTA
 000     05/09/2013   --          Prima emissione.
*************************************************************************/
(a_anno                                  number,
 a_pratica                               number,
 a_cod_fiscale                           varchar2,
 a_imp_dov                        IN OUT number,
 a_imp_dov_acconto                IN OUT number,
 a_imp_dov_dic                    IN OUT number,
 a_imp_dov_acconto_dic            IN OUT number,
 a_imp_dovuta_ab                  IN OUT number,
 a_imp_dovuta_acconto_ab          IN OUT number,
 a_imp_dovuta_dic_ab              IN OUT number,
 a_imp_dovuta_acconto_dic_ab      IN OUT number,
 a_imp_dovuta_ter                 IN OUT number,
 a_imp_dovuta_acconto_ter         IN OUT number,
 a_imp_dovuta_dic_ter             IN OUT number,
 a_imp_dovuta_acconto_dic_ter     IN OUT number,
 a_imp_dov_ter_comu               IN OUT number,
 a_imp_dov_acc_ter_comu           IN OUT number,
 a_imp_dov_dic_ter_comu           IN OUT number,
 a_imp_dov_acc_dic_ter_comu       IN OUT number,
 a_imp_dov_ter_erar               IN OUT number,
 a_imp_dov_acc_ter_erar           IN OUT number,
 a_imp_dov_dic_ter_erar           IN OUT number,
 a_imp_dov_acc_dic_ter_erar       IN OUT number,
 a_imp_dovuta_aree                IN OUT number,
 a_imp_dovuta_acconto_aree        IN OUT number,
 a_imp_dovuta_dic_aree            IN OUT number,
 a_imp_dovuta_acconto_dic_aree    IN OUT number,
 a_imp_dov_aree_comu              IN OUT number,
 a_imp_dov_acc_aree_comu          IN OUT number,
 a_imp_dov_dic_aree_comu          IN OUT number,
 a_imp_dov_acc_dic_aree_comu      IN OUT number,
 a_imp_dov_aree_erar              IN OUT number,
 a_imp_dov_acc_aree_erar          IN OUT number,
 a_imp_dov_dic_aree_erar          IN OUT number,
 a_imp_dov_acc_dic_aree_erar      IN OUT number,
 a_imp_dov_rur                    IN OUT number,
 a_imp_dov_acc_rur                IN OUT number,
 a_imp_dov_dic_rur                IN OUT number,
 a_imp_dov_acc_dic_rur            IN OUT number,
 a_imp_dov_fab_d_comu             IN OUT number,
 a_imp_dov_acc_fab_d_comu         IN OUT number,
 a_imp_dov_dic_fab_d_comu         IN OUT number,
 a_imp_dov_acc_dic_fab_d_comu     IN OUT number,
 a_imp_dov_fab_d_erar             IN OUT number,
 a_imp_dov_acc_fab_d_erar         IN OUT number,
 a_imp_dov_dic_fab_d_erar         IN OUT number,
 a_imp_dov_acc_dic_fab_d_erar     IN OUT number,
 a_imp_dovuta_altri               IN OUT number,
 a_imp_dovuta_acconto_altri       IN OUT number,
 a_imp_dovuta_dic_altri           IN OUT number,
 a_imp_dovuta_acconto_dic_altri   IN OUT number,
 a_imp_dov_altri_comu             IN OUT number,
 a_imp_dov_acc_altri_comu         IN OUT number,
 a_imp_dov_dic_altri_comu         IN OUT number,
 a_imp_dov_acc_dic_altri_comu     IN OUT number,
 a_imp_dov_altri_erar             IN OUT number,
 a_imp_dov_acc_altri_erar         IN OUT number,
 a_imp_dov_dic_altri_erar         IN OUT number,
 a_imp_dov_acc_dic_altri_erar     IN OUT number,
 a_imp_dovuta_fab_m               IN OUT number,
 a_imp_dovuta_acconto_fab_m       IN OUT number,
 a_imp_dovuta_dic_fab_m           IN OUT number,
 a_imp_dovuta_acconto_dic_fab_m   IN OUT number,
 a_imp_dov_mini                   IN OUT number,
 a_imp_dov_mini_dic               IN OUT number,
 a_imp_dovuta_mini_ab             IN OUT number,
 a_imp_dovuta_mini_dic_ab         IN OUT number,
 a_imp_dovuta_mini_ter            IN OUT number,
 a_imp_dovuta_mini_dic_ter        IN OUT number,
 a_versamenti                     IN OUT number,
 a_versamenti_acconto             IN OUT number,
 a_versamenti_ab                  IN OUT number,
 a_versamenti_acconto_ab          IN OUT number,
 a_versamenti_ter                 IN OUT number,
 a_versamenti_acconto_ter         IN OUT number,
 a_versamenti_aree                IN OUT number,
 a_versamenti_acconto_aree        IN OUT number,
 a_versamenti_altri               IN OUT number,
 a_versamenti_acconto_altri       IN OUT number,
 a_vers_rurali                    IN OUT number,
 a_vers_acconto_rurali            IN OUT number,
 a_vers_ter_comu                  IN OUT number,
 a_vers_acconto_ter_comu          IN OUT number,
 a_vers_ter_erar                  IN OUT number,
 a_vers_acconto_ter_erar          IN OUT number,
 a_vers_aree_comu                 IN OUT number,
 a_vers_acconto_aree_comu         IN OUT number,
 a_vers_aree_erar                 IN OUT number,
 a_vers_acconto_aree_erar         IN OUT number,
 a_vers_altri_comu                IN OUT number,
 a_vers_acconto_altri_comu        IN OUT number,
 a_vers_altri_erar                IN OUT number,
 a_vers_acconto_altri_erar        IN OUT number,
 a_vers_fab_d_comu                IN OUT number,
 a_vers_acconto_fab_d_comu        IN OUT number,
 a_vers_fab_d_erar                IN OUT number,
 a_vers_acconto_fab_d_erar        IN OUT number,
 a_vers_fabb_merce                IN OUT number,
 a_vers_acconto_fabb_merce        IN OUT number,
 a_versamenti_mini                IN OUT number,
 a_versamenti_mini_ab             IN OUT number,
 a_versamenti_mini_ter            IN OUT number,
 a_cont_non_liq                   IN OUT number,
 a_utente                                varchar2
)
IS
    --
    C_TIPO_TRIBUTO                   CONSTANT varchar2(5) := 'ICI';
    --
    C_DIFF_REND_30_ACC               CONSTANT number := 10;
    C_DIFF_REND_30_SAL               CONSTANT number := 20;
    --
    C_NUOVO                          CONSTANT number := 100;
    --
    errore                           exception;
    w_errore                         varchar2(2000);
    --
    w_oggetto_pratica                number;
    w_oggetto_imposta                number;
    w_num_riog                       number;
    w_min_dal_riog                   date;
    w_max_al_riog                    date;
    w_valore_ogpr                    number;
-- w_versamenti              number; --MAI USATO
-- w_versamenti_acconto      number; --MAI USATO
    w_detr_acconto                   number;
    w_imponibile_10_acconto          number;
    w_imponibile_10_saldo            number;
    w_cod_sanzione                   number;
    w_check                          number;
    w_cont_non_liq                   number;
    w_esiste_categoria               number;
    w_bError                         boolean := FALSE;
    w_mError                         varchar2(2000);
    wf                               number;
    w_anno                           number;
    w_mese_inizio                    number;
    w_mese_fine                      number;
    --
    w_imp_10_acconto_ab              number;
    w_imp_10_saldo_ab                number;
    w_imp_10_acconto_ter             number;
    w_imp_10_saldo_ter               number;
    w_imp_10_acconto_aree            number;
    w_imp_10_saldo_aree              number;
    w_imp_10_acconto_altri           number;
    w_imp_10_saldo_altri             number;
    --
    w_data_scad_acconto              date; --Data scadenza acconto
    w_data_scad_saldo                date; --Data scadenza saldo
    --
--
-- (VD - 08/07/2016): Aggiunta selezione campi per mini IMU
-- (VD - 23/09/2020): Aggiunta selezione campi fabbricati merce
--
CURSOR sel_ogim (p_anno number, p_cod_fiscale varchar2) IS
       select ogpr.oggetto,ogpr.tipo_oggetto
            , ogpr.oggetto_pratica
            , f_dato_riog(p_cod_fiscale,ogco.oggetto_pratica,p_anno,'CA')       categoria_catasto
            , f_dato_riog(p_cod_fiscale,ogco.oggetto_pratica,p_anno,'CL')       classe_catasto
            , to_number(f_dato_riog(p_cod_fiscale
                                   ,ogco.oggetto_pratica
                                   ,p_anno
                                   ,'VT'
                                   ))                                           valore
            , f_valore(nvl(f_valore_d(ogpr.oggetto_pratica,p_anno),ogpr.valore)
                      ,ogpr.tipo_oggetto
                      ,prtr.anno
                      ,p_anno
                      ,nvl(ogpr.categoria_catasto,ogge.categoria_catasto)
                      ,prtr.tipo_pratica
                      ,ogpr.FLAG_VALORE_RIVALUTATO
                      )                                                         valore_dic
             , ogco.tipo_rapporto
             , ogco.perc_possesso
             , decode(ogco.anno,p_anno,nvl(ogco.mesi_possesso,12),nvl(ogim.mesi_possesso,12))           mesi_possesso
             , ogco.mesi_possesso_1sem
             , decode(ogco.anno
                     ,p_anno
                     ,decode(ogco.flag_esclusione
                            ,'S'
                            ,nvl(ogco.mesi_esclusione,nvl(ogco.mesi_possesso,12))
                            ,ogco.mesi_esclusione
                     )
                     ,decode(ogco.flag_esclusione,'S',12,0)
             )                                                                  mesi_esclusione
             , decode(ogco.anno
                     ,p_anno
                     ,decode(ogco.flag_riduzione
                            ,'S'
                            ,nvl(ogco.mesi_riduzione,nvl(ogco.mesi_possesso,12))
                            ,ogco.mesi_riduzione
                     )
                     ,decode(ogco.flag_riduzione,'S',12,0)
             )                                                                  mesi_riduzione
             , decode(ogco.anno
                     ,p_anno,nvl(ogco.mesi_aliquota_ridotta,nvl(ogco.mesi_possesso,12))
                     ,0)                                                        mesi_aliquota_ridotta
             , decode(ogco.anno
                     ,p_anno,nvl(ogco.da_mese_possesso,1),
                     1)                                                         da_mese_possesso
             , decode(ogco.detrazione
                     ,'',''
                     ,nvl(made.detrazione,ogco.detrazione)
                     )                                                          detrazione
            , ogco.flag_possesso
            , ogco.flag_esclusione
            , ogco.flag_riduzione
            , ogco.flag_ab_principale
            , ogco.flag_al_ridotta
            , ogim.imposta
            , ogim.imposta_acconto
            , prtr.tipo_pratica
            , prtr.anno
            , ogim.imposta_dovuta
            , ogim.imposta_dovuta_acconto
            , ogim.imposta_erariale
             ,ogim.imposta_erariale_acconto
            , ogim.imposta_erariale_dovuta
            , ogim.imposta_erariale_dovuta_acc
            , ogim.detrazione                                                   detrazione_ogim
            , ogim.detrazione_acconto                                           detrazione_acc_ogim
            , ogim.tipo_aliquota
            , ogim.aliquota
            , ogim.aliquota_erariale
               -- Mini IMU
            , ogim.aliquota_std
            , ogim.imposta_aliquota
            , ogim.imposta_std
            , ogim.imposta_mini
            , ogim.imposta_dovuta_std
            , ogim.imposta_dovuta_mini
            , ogim.detrazione_std                                               detrazione_std_ogim
               -- Abitazione Principale --
            , decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                    ,1,0
                    ,2,0
                    ,decode(ogim.tipo_aliquota
                           ,2,nvl(ogim.imposta, 0)
                           ,0
                           )
                    )                                                           imp_dovuta_ab
            , decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                    ,1,0
                    ,2,0
                    ,decode(ogim.tipo_aliquota
                           ,2,nvl(ogim.imposta_mini, 0)
                           ,0
                           )
                    )                                                           imp_dovuta_mini_ab
            , decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                     ,1,0
                     ,2,0
                     ,decode(ogim.tipo_aliquota
                            ,2,nvl(ogim.imposta_acconto, 0)
                            ,0
                            )
                     )                                                          imp_dovuta_acconto_ab
             , decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                      ,1,0
                      ,2,0
                      ,decode(ogim.tipo_aliquota
                             ,2,nvl(decode(titr.flag_liq_riog
                                             ,'S',ogim.imposta
                                             ,decode(noog.anno_notifica
                                                    ,null,ogim.imposta_dovuta
                                                    ,ogim.imposta
                                                    )
                                             )
                                      , 0)
                             ,0
                             )
                      )                                                         imp_dovuta_dic_ab
             , decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                      ,1,0
                      ,2,0
                      ,decode(ogim.tipo_aliquota
                             ,2,nvl(decode(titr.flag_liq_riog
                                             ,'S',ogim.imposta_mini
                                             ,decode(noog.anno_notifica
                                                    ,null,ogim.imposta_dovuta_mini
                                                    ,ogim.imposta_mini
                                                    )
                                             )
                                      , 0)
                             ,0
                             )
                      )                                                         imp_dovuta_mini_dic_ab
             , decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                      ,1,0
                      ,2,0
                      ,decode(ogim.tipo_aliquota
                             ,2,nvl(decode(titr.flag_liq_riog
                                             ,'S',ogim.imposta_acconto
                                             ,decode(noog.anno_notifica
                                                    ,null,ogim.imposta_dovuta_acconto
                                                    ,ogim.imposta_acconto
                                                    )
                                             )
                                  , 0)
                             ,0
                             )
                      )                                                         imp_dovuta_acconto_dic_ab
               -- Terreni --
             , decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                      ,1,nvl(ogim.imposta, 0)
                      ,0
                      )                                                         imp_dovuta_ter
             , decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                      ,1,nvl(ogim.imposta_mini, 0)
                      ,0
                      )                                                         imp_dovuta_mini_ter
             , decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                      ,1,nvl(ogim.imposta_acconto, 0)
                      ,0
                      )                                                         imp_dovuta_acconto_ter
             , decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                      ,1,nvl(decode(titr.flag_liq_riog
                                   ,'S',ogim.imposta
                                   ,decode(noog.anno_notifica
                                          ,null,ogim.imposta_dovuta
                                          ,ogim.imposta
                                          )
                                   )
                            , 0)
                      ,0
                      )                                                         imp_dovuta_dic_ter
             , decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                      ,1,nvl(decode(titr.flag_liq_riog
                                   ,'S',ogim.imposta_mini
                                   ,decode(noog.anno_notifica
                                          ,null,ogim.imposta_dovuta_mini
                                          ,ogim.imposta_mini
                                          )
                                   )
                            , 0)
                      ,0
                      )                                                         imp_dovuta_mini_dic_ter
             , decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                         ,1,nvl(decode(titr.flag_liq_riog
                                      ,'S',ogim.imposta_acconto
                                      ,decode(noog.anno_notifica
                                             ,null,ogim.imposta_dovuta_acconto
                                             ,ogim.imposta_acconto
                                             )
                                      )
                               , 0)
                         ,0
                         )                                                      imp_dovuta_acconto_dic_ter
             , decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                      ,1,nvl(ogim.imposta, 0) - nvl(ogim.imposta_erariale, 0)
                      ,0
                      )                                                         imp_dovuta_ter_comu
             , decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                      ,1,nvl(ogim.imposta_acconto, 0) - nvl(ogim.imposta_erariale_acconto, 0)
                      ,0
                      )                                                         imp_dovuta_acc_ter_comu
             , decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                      ,1,nvl(decode(titr.flag_liq_riog
                                   ,'S',ogim.imposta - nvl(ogim.imposta_erariale, 0)
                                   ,decode(noog.anno_notifica
                                          ,null,ogim.imposta_dovuta - nvl(ogim.imposta_erariale_dovuta, 0)
                                          ,ogim.imposta - nvl(ogim.imposta_erariale, 0)
                                          )
                                   )
                            , 0)
                      ,0
                      )                                                         imp_dovuta_dic_ter_comu
             , decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                      ,1,nvl(decode(titr.flag_liq_riog
                                   ,'S',ogim.imposta_acconto - nvl(ogim.imposta_erariale_acconto, 0)
                                   ,decode(noog.anno_notifica
                                          ,null,ogim.imposta_dovuta_acconto - nvl(ogim.imposta_erariale_dovuta_acc, 0)
                                          ,ogim.imposta_acconto - nvl(ogim.imposta_erariale_acconto, 0)
                                          )
                                   )
                            , 0)
                      ,0
                      )                                                         imp_dovuta_acc_dic_ter_comu
             , decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                      ,1,nvl(ogim.imposta_erariale, 0)
                      ,0
                      )                                                         imp_dovuta_ter_erar
             , decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                         ,1,nvl(ogim.imposta_erariale_acconto, 0)
                         ,0
                         )                                                      imp_dovuta_acc_ter_erar
             , decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                      ,1,nvl(decode(titr.flag_liq_riog
                                   ,'S',nvl(ogim.imposta_erariale, 0)
                                   ,decode(noog.anno_notifica
                                          ,null,nvl(ogim.imposta_erariale_dovuta, 0)
                                          ,nvl(ogim.imposta_erariale, 0)
                                          )
                                   )
                            , 0)
                      ,0
                      )                                                         imp_dovuta_dic_ter_erar
             , decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                      ,1,nvl(decode(titr.flag_liq_riog
                                   ,'S',nvl(ogim.imposta_erariale_acconto, 0)
                                   ,decode(noog.anno_notifica
                                          ,null,nvl(ogim.imposta_erariale_dovuta_acc, 0)
                                          ,nvl(ogim.imposta_erariale_acconto, 0)
                                          )
                                   )
                            , 0)
                      ,0
                      )                                                         imp_dovuta_acc_dic_ter_erar
      -- Aree --
             , decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                      ,2,nvl(ogim.imposta, 0)
                      ,0
                      )                                                         imp_dovuta_aree
             , decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                      ,2,nvl(ogim.imposta_acconto, 0)
                      ,0
                      )                                                         imp_dovuta_acconto_aree
             , decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                      ,2,nvl(decode(titr.flag_liq_riog
                                   ,'S',ogim.imposta
                                   ,decode(noog.anno_notifica
                                          ,null,ogim.imposta_dovuta
                                          ,ogim.imposta
                                          )
                                   )
                            , 0)
                      ,0
                      )                                                         imp_dovuta_dic_aree
             , decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                      ,2,nvl(decode(titr.flag_liq_riog
                                   ,'S',ogim.imposta_acconto
                                   ,decode(noog.anno_notifica
                                          ,null,ogim.imposta_dovuta_acconto
                                          ,ogim.imposta_acconto
                                          )
                                   )
                            , 0)
                      ,0
                      )                                                         imp_dovuta_acconto_dic_aree
             , decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                      ,2,nvl(ogim.imposta, 0) - nvl(ogim.imposta_erariale, 0)
                      ,0
                      )                                                         imp_dovuta_aree_comu
             , decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                      ,2,nvl(ogim.imposta_acconto, 0) - nvl(ogim.imposta_erariale_acconto, 0)
                      ,0
                      )                                                         imp_dovuta_acc_aree_comu
             , decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                      ,2,nvl(decode(titr.flag_liq_riog
                                   ,'S',ogim.imposta  - nvl(ogim.imposta_erariale, 0)
                                   ,decode(noog.anno_notifica
                                          ,null,ogim.imposta_dovuta  - nvl(ogim.imposta_erariale_dovuta, 0)
                                          ,ogim.imposta  - nvl(ogim.imposta_erariale, 0)
                                          )
                                   )
                            , 0)
                      ,0
                      )                                                         imp_dovuta_dic_aree_comu
             , decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                      ,2,nvl(decode(titr.flag_liq_riog
                                   ,'S',ogim.imposta_acconto - nvl(ogim.imposta_erariale_acconto, 0)
                                   ,decode(noog.anno_notifica
                                          ,null,ogim.imposta_dovuta_acconto - nvl(ogim.imposta_erariale_dovuta_acc, 0)
                                          ,ogim.imposta_acconto - nvl(ogim.imposta_erariale_acconto, 0)
                                          )
                                   )
                            , 0)
                      ,0
                      )                                                         imp_dovuta_acc_dic_aree_comu
             , decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                      ,2,nvl(ogim.imposta_erariale, 0)
                      ,0
                      )                                                         imp_dovuta_aree_erar
             , decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                      ,2,nvl(ogim.imposta_erariale_acconto, 0)
                      ,0
                      )                                                         imp_dovuta_acc_aree_erar
             , decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                      ,2,nvl(decode(titr.flag_liq_riog
                                   ,'S',nvl(ogim.imposta_erariale, 0)
                                   ,decode(noog.anno_notifica
                                          ,null,nvl(ogim.imposta_erariale_dovuta, 0)
                                          ,nvl(ogim.imposta_erariale, 0)
                                          )
                                   )
                            , 0)
                      ,0
                      )                                                         imp_dovuta_dic_aree_erar
             , decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                      ,2,nvl(decode(titr.flag_liq_riog
                                   ,'S',nvl(ogim.imposta_erariale_acconto, 0)
                                   ,decode(noog.anno_notifica
                                          ,null,nvl(ogim.imposta_erariale_dovuta_acc, 0)
                                          ,nvl(ogim.imposta_erariale_acconto, 0)
                                          )
                                   )
                            , 0)
                      ,0
                      )                                                         imp_dovuta_acc_dic_aree_erar
      -- Fabbricati Rurali --
             , decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                      ,1,0
                      ,2,0
                      ,decode(ogim.tipo_aliquota
                             ,2,0
                             ,decode(nvl(aliq.flag_fabbricati_merce,'N')
                                    ,'S',0
                                    ,decode(ogim.aliquota_erariale
                                           ,null,ogim.imposta
                                           ,0
                                           )
                                    )
                             )
                      )                                                         imp_dovuta_rurali
             , decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                      ,1,0
                      ,2,0
                      ,decode(ogim.tipo_aliquota
                             ,2,0
                             ,decode(nvl(aliq.flag_fabbricati_merce,'N')
                                    ,'S',0
                                    ,decode(ogim.aliquota_erariale
                                           ,null,nvl(ogim.imposta_acconto,0)
                                           ,0
                                           )
                                    )
                             )
                      )                                                         imp_dovuta_acc_rurali
             , decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                      ,1,0
                      ,2,0
                      ,decode(ogim.tipo_aliquota
                             ,2,0
                             ,decode(nvl(aliq.flag_fabbricati_merce,'N')
                                    ,'S',0
                                    ,decode(ogim.aliquota_erariale
                                           ,null,nvl(decode(titr.flag_liq_riog
                                                           ,'S',ogim.imposta
                                                           ,decode(noog.anno_notifica
                                                                  ,null,ogim.imposta_dovuta
                                                                  ,ogim.imposta
                                                                  )
                                                           )
                                                    ,0)
                                           ,0
                                           )
                                    )
                             )
                      )                                                         imp_dovuta_dic_rurali
             , decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                      ,1,0
                      ,2,0
                      ,decode(ogim.tipo_aliquota
                             ,2,0
                             ,decode(nvl(aliq.flag_fabbricati_merce,'N')
                                    ,'S',0
                                    ,decode(ogim.aliquota_erariale
                                           ,null,nvl(decode(titr.flag_liq_riog
                                                           ,'S',ogim.imposta_acconto
                                                           ,decode(noog.anno_notifica
                                                                  ,null,ogim.imposta_dovuta_acconto
                                                                  ,ogim.imposta_acconto
                                                                  )
                                                           )
                                                    ,0)
                                           ,0
                                           )
                                    )
                             )
                      )                                                         imp_dovuta_acc_dic_rurali
      -- Fabbricati D --
             , decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                      ,1,0
                      ,2,0
                      ,decode(ogim.tipo_aliquota
                             ,2,0
                             ,decode(ogim.aliquota_erariale
                                    ,null,0
                                    ,decode(sign(ogim.anno - 2012)
                                           ,1,decode(substr(ogpr.categoria_catasto,1,1)||to_char(ogim.tipo_aliquota)
                                                    ,'D9',ogim.imposta - nvl(ogim.imposta_erariale,0)
                                                    ,0
                                                    )
                                           ,0
                                           )
                                    )
                             )
                      )                                                         imp_dovuta_fab_d_comu
             , decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                      ,1,0
                      ,2,0
                      ,decode(ogim.tipo_aliquota
                             ,2,0
                             ,decode(ogim.aliquota_erariale
                                    ,null,0
                                    ,decode(sign(ogim.anno - 2012)
                                           ,1,decode(substr(ogpr.categoria_catasto,1,1)||to_char(ogim.tipo_aliquota)
                                                    ,'D9',nvl(ogim.imposta_acconto,0) - nvl(ogim.imposta_erariale_acconto,0)
                                                    ,0
                                                    )
                                           ,0
                                           )
                                    )
                             )
                      )                                                         imp_dovuta_acc_fab_d_comu
             , decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                      ,1,0
                      ,2,0
                      ,decode(ogim.tipo_aliquota
                             ,2,0
                             ,decode(ogim.aliquota_erariale
                                    ,null,0
                                    ,decode(sign(ogim.anno - 2012)
                                           ,1,decode(substr(ogpr.categoria_catasto,1,1)||to_char(ogim.tipo_aliquota)
                                                    ,'D9',nvl(decode(titr.flag_liq_riog
                                                                    ,'S',nvl(ogim.imposta,0) - nvl(ogim.imposta_erariale,0)
                                                                    ,decode(noog.anno_notifica
                                                                           ,null,nvl(ogim.imposta_dovuta,0) - nvl(ogim.imposta_erariale_dovuta,0)
                                                                           ,nvl(ogim.imposta,0) - nvl(ogim.imposta_erariale,0)
                                                                           )
                                                                    )
                                                             ,0)
                                                    ,0
                                                    )
                                           ,0
                                           )
                                    )
                             )
                      )                                                         imp_dovuta_dic_fab_d_comu
             , decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                      ,1,0
                      ,2,0
                      ,decode(ogim.tipo_aliquota
                             ,2,0
                             ,decode(ogim.aliquota_erariale
                                    ,null,0
                                    ,decode(sign(ogim.anno - 2012)
                                           ,1,decode(substr(ogpr.categoria_catasto,1,1)||to_char(ogim.tipo_aliquota)
                                                    ,'D9',nvl(decode(titr.flag_liq_riog
                                                                    ,'S',nvl(ogim.imposta_acconto,0) - nvl(ogim.imposta_erariale_acconto,0)
                                                                    ,decode(noog.anno_notifica
                                                                           ,null,nvl(ogim.imposta_dovuta_acconto,0) - nvl(ogim.imposta_erariale_dovuta_acc,0)
                                                                           ,nvl(ogim.imposta_acconto,0) - nvl(ogim.imposta_erariale_acconto,0)
                                                                           )
                                                                    )
                                                             ,0)
                                                    ,0
                                                    )
                                           ,0
                                           )
                                    )
                             )
                      )                                                         imp_dovuta_acc_dic_fab_d_comu
             , decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                      ,1,0
                      ,2,0
                      ,decode(ogim.tipo_aliquota
                             ,2,0
                             ,decode(ogim.aliquota_erariale
                                    ,null,0
                                    ,decode(sign(ogim.anno - 2012)
                                           ,1,decode(substr(ogpr.categoria_catasto,1,1)||to_char(ogim.tipo_aliquota)
                                                    ,'D9',nvl(ogim.imposta_erariale,0)
                                                    ,0
                                                    )
                                           ,0
                                           )
                                    )
                             )
                      )                                                         imp_dovuta_fab_d_erar
             , decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                      ,1,0
                      ,2,0
                      ,decode(ogim.tipo_aliquota
                             ,2,0
                             ,decode(ogim.aliquota_erariale
                                    ,null,0
                                    ,decode(sign(ogim.anno - 2012)
                                           ,1,decode(substr(ogpr.categoria_catasto,1,1)||to_char(ogim.tipo_aliquota)
                                                    ,'D9',nvl(ogim.imposta_erariale_acconto,0)
                                                    ,0
                                                    )
                                           ,0
                                           )
                                    )
                             )
                      )                                                         imp_dovuta_acc_fab_d_erar
             , decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                      ,1,0
                      ,2,0
                      ,decode(ogim.tipo_aliquota
                             ,2,0
                             ,decode(ogim.aliquota_erariale
                                    ,null,0
                                    ,decode(sign(ogim.anno - 2012)
                                           ,1,decode(substr(ogpr.categoria_catasto,1,1)||to_char(ogim.tipo_aliquota)
                                                    ,'D9',nvl(decode(titr.flag_liq_riog
                                                                    ,'S',nvl(ogim.imposta_erariale,0)
                                                                    ,decode(noog.anno_notifica
                                                                           ,null,nvl(ogim.imposta_erariale_dovuta,0)
                                                                           ,nvl(ogim.imposta_erariale,0)
                                                                           )
                                                                    )
                                                             ,0)
                                                    ,0
                                                    )
                                           ,0
                                           )
                                    )
                             )
                      )                                                         imp_dovuta_dic_fab_d_erar
             , decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                      ,1,0
                      ,2,0
                      ,decode(ogim.tipo_aliquota
                             ,2,0
                             ,decode(ogim.aliquota_erariale
                                    ,null,0
                                    ,decode(sign(ogim.anno - 2012)
                                           ,1,decode(substr(ogpr.categoria_catasto,1,1)||to_char(ogim.tipo_aliquota)
                                                    ,'D9',nvl(decode(titr.flag_liq_riog
                                                                    ,'S',nvl(ogim.imposta_erariale_acconto,0)
                                                                    ,decode(noog.anno_notifica
                                                                           ,null,nvl(ogim.imposta_erariale_dovuta_acc,0)
                                                                           ,nvl(ogim.imposta_erariale_acconto,0)
                                                                           )
                                                                    )
                                                             ,0)
                                                    ,0
                                                    )
                                           ,0
                                           )
                                    )
                             )
                      )                                                         imp_dovuta_acc_dic_fab_d_erar
      -- Altri Fabbricati --
             , decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                      ,1,0
                      ,2,0
                      ,decode(ogim.tipo_aliquota
                             ,2,0
                             ,decode(ogim.aliquota_erariale
                                    ,null,0
                                    ,decode(sign(ogim.anno - 2012)
                                           ,1,decode(substr(ogpr.categoria_catasto,1,1)||to_char(ogim.tipo_aliquota)
                                                    ,'D9',0
                                                    ,decode(nvl(aliq.flag_fabbricati_merce,'N')
                                                           ,'S',0
                                                           ,ogim.imposta
                                                           )
                                                    )
                                           ,ogim.imposta
                                           )
                                    )
                             )
                      )                                                         imp_dovuta_altri
             , decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                      ,1,0
                      ,2,0
                      ,decode(ogim.tipo_aliquota
                             ,2,0
                             ,decode(ogim.aliquota_erariale
                                    ,null,0
                                    ,decode(sign(ogim.anno - 2012)
                                           ,1,decode(substr(ogpr.categoria_catasto,1,1)||to_char(ogim.tipo_aliquota)
                                                    ,'D9',0
                                                    ,decode(nvl(aliq.flag_fabbricati_merce,'N')
                                                           ,'S',0
                                                           ,nvl(ogim.imposta_acconto,0)
                                                           )
                                                    )
                                           ,nvl(ogim.imposta_acconto,0)
                                           )
                                    )
                             )
                      )                                                         imp_dovuta_acconto_altri
             , decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                      ,1,0
                      ,2,0
                      ,decode(ogim.tipo_aliquota
                             ,2,0
                             ,decode(ogim.aliquota_erariale
                                    ,null,0
                                    ,decode(sign(ogim.anno - 2012)
                                           ,1,decode(substr(ogpr.categoria_catasto,1,1)||to_char(ogim.tipo_aliquota)
                                                    ,'D9',0
                                                    ,decode(nvl(aliq.flag_fabbricati_merce,'N')
                                                           ,'S',0
                                                           ,nvl(decode(titr.flag_liq_riog
                                                                      ,'S',nvl(ogim.imposta,0)
                                                                      ,decode(noog.anno_notifica
                                                                             ,null,nvl(ogim.imposta_dovuta,0)
                                                                             ,nvl(ogim.imposta,0)
                                                                             )
                                                                      )
                                                               ,0)
                                                           )
                                                    )
                                           ,nvl(decode(titr.flag_liq_riog
                                                      ,'S',nvl(ogim.imposta,0)
                                                      ,decode(noog.anno_notifica
                                                             ,null,nvl(ogim.imposta_dovuta,0)
                                                             ,nvl(ogim.imposta,0)
                                                              )
                                                      )
                                               ,0)
                                           )
                                    )
                             )
                      )                                                         imp_dovuta_dic_altri
             , decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                      ,1,0
                      ,2,0
                      ,decode(ogim.tipo_aliquota
                             ,2,0
                             ,decode(ogim.aliquota_erariale
                                    ,null,0
                                    ,decode(sign(ogim.anno - 2012)
                                           ,1,decode(substr(ogpr.categoria_catasto,1,1)||to_char(ogim.tipo_aliquota)
                                                    ,'D9',0
                                                    ,decode(nvl(aliq.flag_fabbricati_merce,'N')
                                                           ,'S',0
                                                           ,nvl(decode(titr.flag_liq_riog
                                                                      ,'S',nvl(ogim.imposta_acconto,0)
                                                                      ,decode(noog.anno_notifica
                                                                             ,null,nvl(ogim.imposta_dovuta_acconto,0)
                                                                             ,nvl(ogim.imposta_acconto,0)
                                                                             )
                                                                      )
                                                               ,0)
                                                           )
                                                    )
                                           ,nvl(decode(titr.flag_liq_riog
                                                      ,'S',nvl(ogim.imposta_acconto,0)
                                                      ,decode(noog.anno_notifica
                                                             ,null,nvl(ogim.imposta_dovuta_acconto,0)
                                                             ,nvl(ogim.imposta_acconto,0)
                                                             )
                                                      )
                                               ,0)
                                           )
                                    )
                             )
                      )                                                         imp_dovuta_acconto_dic_altri
             , decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                      ,1,0
                      ,2,0
                      ,decode(ogim.tipo_aliquota
                             ,2,0
                             ,decode(ogim.aliquota_erariale
                                    ,null,0
                                    ,decode(sign(ogim.anno - 2012)
                                           ,1,decode(substr(ogpr.categoria_catasto,1,1)||to_char(ogim.tipo_aliquota)
                                                    ,'D9',0
                                                    ,decode(nvl(aliq.flag_fabbricati_merce,'N')
                                                           ,'S',0
                                                           ,ogim.imposta - nvl(ogim.imposta_erariale,0)
                                                           )
                                                    )
                                           ,ogim.imposta - nvl(ogim.imposta_erariale,0)
                                           )
                                    )
                             )
                      )                                                         imp_dovuta_altri_comu
             , decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                      ,1,0
                      ,2,0
                      ,decode(ogim.tipo_aliquota
                             ,2,0
                             ,decode(ogim.aliquota_erariale
                                    ,null,0
                                    ,decode(sign(ogim.anno - 2012)
                                           ,1,decode(substr(ogpr.categoria_catasto,1,1)||to_char(ogim.tipo_aliquota)
                                                    ,'D9',0
                                                    ,decode(nvl(aliq.flag_fabbricati_merce,'N')
                                                           ,'S',0
                                                           ,nvl(ogim.imposta_acconto,0) - nvl(ogim.imposta_erariale_acconto,0)
                                                           )
                                                    )
                                           ,nvl(ogim.imposta_acconto,0) - nvl(ogim.imposta_erariale_acconto,0)
                                           )
                                    )
                             )
                      )                                                         imp_dovuta_acc_altri_comu
             , decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                      ,1,0
                      ,2,0
                      ,decode(ogim.tipo_aliquota
                             ,2,0
                             ,decode(ogim.aliquota_erariale
                                    ,null,0
                                    ,decode(sign(ogim.anno - 2012)
                                           ,1,decode(substr(ogpr.categoria_catasto,1,1)||to_char(ogim.tipo_aliquota)
                                                    ,'D9',0
                                                    ,decode(nvl(aliq.flag_fabbricati_merce,'N')
                                                           ,'S',0
                                                           ,nvl(decode(titr.flag_liq_riog
                                                                      ,'S',nvl(ogim.imposta,0) - nvl(ogim.imposta_erariale,0)
                                                                      ,decode(noog.anno_notifica
                                                                             ,null,nvl(ogim.imposta_dovuta,0) - nvl(ogim.imposta_erariale_dovuta,0)
                                                                             ,nvl(ogim.imposta,0) - nvl(ogim.imposta_erariale,0)
                                                                             )
                                                                      )
                                                               ,0)
                                                           )
                                                    )
                                           ,nvl(decode(titr.flag_liq_riog
                                                      ,'S',nvl(ogim.imposta,0) - nvl(ogim.imposta_erariale,0)
                                                      ,decode(noog.anno_notifica
                                                             ,null,nvl(ogim.imposta_dovuta,0) - nvl(ogim.imposta_erariale_dovuta,0)
                                                             ,nvl(ogim.imposta,0) - nvl(ogim.imposta_erariale,0)
                                                              )
                                                      )
                                               ,0)
                                           )
                                    )
                             )
                      )                                                         imp_dovuta_dic_altri_comu
             , decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                      ,1,0
                      ,2,0
                      ,decode(ogim.tipo_aliquota
                             ,2,0
                             ,decode(ogim.aliquota_erariale
                                    ,null,0
                                    ,decode(sign(ogim.anno - 2012)
                                           ,1,decode(substr(ogpr.categoria_catasto,1,1)||to_char(ogim.tipo_aliquota)
                                                    ,'D9',0
                                                    ,decode(nvl(aliq.flag_fabbricati_merce,'N')
                                                           ,'S',0
                                                           ,nvl(decode(titr.flag_liq_riog
                                                                      ,'S',nvl(ogim.imposta_acconto,0) - nvl(ogim.imposta_erariale_acconto,0)
                                                                      ,decode(noog.anno_notifica
                                                                             ,null,nvl(ogim.imposta_dovuta_acconto,0) - nvl(ogim.imposta_erariale_dovuta_acc,0)
                                                                             ,nvl(ogim.imposta_acconto,0) - nvl(ogim.imposta_erariale_acconto,0)
                                                                             )
                                                                      )
                                                               ,0)
                                                           )
                                                    )
                                           ,nvl(decode(titr.flag_liq_riog
                                                      ,'S',nvl(ogim.imposta_acconto,0) - nvl(ogim.imposta_erariale_acconto,0)
                                                      ,decode(noog.anno_notifica
                                                             ,null,nvl(ogim.imposta_dovuta_acconto,0) - nvl(ogim.imposta_erariale_dovuta_acc,0)
                                                             ,nvl(ogim.imposta_acconto,0) - nvl(ogim.imposta_erariale_acconto,0)
                                                             )
                                                      )
                                               ,0)
                                           )
                                    )
                             )
                      )                                                         imp_dovuta_acc_dic_altri_comu
             , decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                      ,1,0
                      ,2,0
                      ,decode(ogim.tipo_aliquota
                             ,2,0
                             ,decode(ogim.aliquota_erariale
                                    ,null,0
                                    ,decode(sign(ogim.anno - 2012)
                                           ,1,decode(substr(ogpr.categoria_catasto,1,1)||to_char(ogim.tipo_aliquota)
                                                    ,'D9',0
                                                    ,decode(nvl(aliq.flag_fabbricati_merce,'N')
                                                           ,'S',0
                                                           ,nvl(ogim.imposta_erariale,0)
                                                           )
                                                    )
                                           ,nvl(ogim.imposta_erariale,0)
                                           )
                                    )
                             )
                      )                                                         imp_dovuta_altri_erar
             , decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                      ,1,0
                      ,2,0
                      ,decode(ogim.tipo_aliquota
                             ,2,0
                             ,decode(ogim.aliquota_erariale
                                    ,null,0
                                    ,decode(sign(ogim.anno - 2012)
                                           ,1,decode(substr(ogpr.categoria_catasto,1,1)||to_char(ogim.tipo_aliquota)
                                                    ,'D9',0
                                                    ,decode(nvl(aliq.flag_fabbricati_merce,'N')
                                                           ,'S',0
                                                           ,nvl(ogim.imposta_erariale_acconto,0)
                                                           )
                                                    )
                                           ,nvl(ogim.imposta_erariale_acconto,0)
                                           )
                                    )
                             )
                      )                                                         imp_dovuta_acc_altri_erar
             , decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                      ,1,0
                      ,2,0
                      ,decode(ogim.tipo_aliquota
                             ,2,0
                             ,decode(ogim.aliquota_erariale
                                    ,null,0
                                    ,decode(sign(ogim.anno - 2012)
                                           ,1,decode(substr(ogpr.categoria_catasto,1,1)||to_char(ogim.tipo_aliquota)
                                                    ,'D9',0
                                                    ,decode(nvl(aliq.flag_fabbricati_merce,'N')
                                                           ,'S',0
                                                           ,nvl(decode(titr.flag_liq_riog
                                                                      ,'S',nvl(ogim.imposta_erariale,0)
                                                                      ,decode(noog.anno_notifica
                                                                             ,null,nvl(ogim.imposta_erariale_dovuta,0)
                                                                             ,nvl(ogim.imposta_erariale,0)
                                                                             )
                                                                      )
                                                               ,0)
                                                           )
                                                    )
                                           ,nvl(decode(titr.flag_liq_riog
                                                      ,'S',nvl(ogim.imposta_erariale,0)
                                                      ,decode(noog.anno_notifica
                                                             ,null,nvl(ogim.imposta_erariale_dovuta,0)
                                                             ,nvl(ogim.imposta_erariale,0)
                                                              )
                                                      )
                                               ,0)
                                           )
                                    )
                             )
                      )                                                         imp_dovuta_dic_altri_erar
             , decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                      ,1,0
                      ,2,0
                      ,decode(ogim.tipo_aliquota
                             ,2,0
                             ,decode(ogim.aliquota_erariale
                                    ,null,0
                                    ,decode(sign(ogim.anno - 2012)
                                           ,1,decode(substr(ogpr.categoria_catasto,1,1)||to_char(ogim.tipo_aliquota)
                                                    ,'D9',0
                                                    ,decode(nvl(aliq.flag_fabbricati_merce,'N')
                                                           ,'S',0
                                                           ,nvl(decode(titr.flag_liq_riog
                                                                      ,'S',nvl(ogim.imposta_erariale_acconto,0)
                                                                      ,decode(noog.anno_notifica
                                                                             ,null,nvl(ogim.imposta_erariale_dovuta_acc,0)
                                                                             ,nvl(ogim.imposta_erariale_acconto,0)
                                                                             )
                                                                      )
                                                               ,0)
                                                           )
                                                    )
                                           ,nvl(decode(titr.flag_liq_riog
                                                      ,'S',nvl(ogim.imposta_erariale_acconto,0)
                                                      ,decode(noog.anno_notifica
                                                             ,null,nvl(ogim.imposta_erariale_dovuta_acc,0)
                                                             ,nvl(ogim.imposta_erariale_acconto,0)
                                                             )
                                                      )
                                               ,0)
                                           )
                                    )
                             )
                      )                                                         imp_dovuta_acc_dic_altri_erar
      -- Fabbricati Merce --
             , decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                      ,1,0
                      ,2,0
                      ,decode(nvl(aliq.flag_fabbricati_merce,'N')
                             ,'S',ogim.imposta
                             ,0
                             )
                      )                                                         imp_dovuta_fabb_merce
             , decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                      ,1,0
                      ,2,0
                      ,decode(nvl(aliq.flag_fabbricati_merce,'N')
                             ,'S',nvl(ogim.imposta_acconto,0)
                             ,0
                             )
                      )                                                         imp_dovuta_acc_fabb_merce
             , decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                      ,1,0
                      ,2,0
                      ,decode(nvl(aliq.flag_fabbricati_merce,'N')
                             ,'S',nvl(decode(titr.flag_liq_riog
                                            ,'S',ogim.imposta
                                            ,decode(noog.anno_notifica
                                                   ,null,ogim.imposta_dovuta
                                                   ,ogim.imposta
                                                   )
                                            )
                                     ,0)
                             ,0
                             )
                      )                                                         imp_dovuta_dic_fabb_merce
             , decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                      ,1,0
                      ,2,0
                      ,decode(nvl(aliq.flag_fabbricati_merce,'N')
                             ,'S',nvl(decode(titr.flag_liq_riog
                                            ,'S',ogim.imposta_acconto
                                            ,decode(noog.anno_notifica
                                                   ,null,ogim.imposta_dovuta_acconto
                                                   ,ogim.imposta_acconto
                                                   )
                                            )
                                     ,0)
                             ,0
                             )
                      )                                                         imp_dovuta_acc_dic_fabb_merce
              , nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)                        tipo_ogg_ogpr
              , ogpr.imm_storico
         from rivalutazioni_rendita rire
            , moltiplicatori        molt
            , maggiori_detrazioni   made
            , oggetti               ogge
            , pratiche_tributo      prtr
            , oggetti_pratica       ogpr
            , oggetti_contribuente  ogco
            , oggetti_imposta_ogim  ogim
            , notifiche_oggetto     noog
            , tipi_tributo          titr
            , aliquote              aliq
        where rire.anno     (+)          = p_anno
          and rire.tipo_oggetto (+)      = ogpr.tipo_oggetto
          and ogim.cod_fiscale           = p_cod_fiscale
          and ogim.anno                  = p_anno
          and ogim.flag_calcolo          = 'S'
          and ogim.oggetto_pratica       = ogpr.oggetto_pratica
          and prtr.pratica               = ogpr.pratica
          and ogco.cod_fiscale           = ogim.cod_fiscale
          and ogco.oggetto_pratica       = ogim.oggetto_pratica
          and made.anno         (+)      = p_anno
          and made.cod_fiscale  (+)      = ogco.cod_fiscale
          and made.tipo_tributo  (+)     = 'ICI'
          and prtr.tipo_tributo||''      = 'ICI'
          and ogpr.oggetto               = ogge.oggetto
          and nvl(prtr.stato_accertamento,'D') = 'D'
          and ogpr.flag_contenzioso      is null
          -- (AB - 05/12/2022): tolto test su flag_esclusione
          -- (VD - 02/08/2022): aggiunto test su flag_esclusione
          -- and ogco.flag_esclusione       is null
          and molt.anno (+)              = p_anno
          and molt.categoria_catasto (+) =
              f_dato_riog(p_cod_fiscale,ogco.oggetto_pratica,p_anno,'CA')
          and noog.cod_fiscale (+)      = p_cod_fiscale
          and noog.anno_notifica (+)    < a_anno
          and noog.oggetto (+)          = ogpr.oggetto
          and titr.tipo_tributo         = prtr.tipo_tributo
          and ogim.tipo_tributo         = aliq.tipo_tributo (+)
          and ogim.anno                 = aliq.anno (+)
          and ogim.tipo_aliquota        = aliq.tipo_aliquota (+)
    ;
--------------------------------------------------------------------------------
-- DATA_SCADENZA_VERS
--------------------------------------------------------------------------------
PROCEDURE data_scadenza_vers
( p_anno              IN number
, p_tipo_trib         IN varchar2
, p_tipo_vers         IN varchar2
, p_cod_fiscale       IN varchar
, w_data_scad         IN OUT date
)
IS
BEGIN
   w_data_scad := f_scadenza(p_anno, p_tipo_trib, p_tipo_vers, p_cod_fiscale);
     if w_data_scad is null THEN
        IF p_tipo_vers = 'A' THEN
          w_errore := 'Manca la data scadenza dell''acconto per l''anno indicato: '||p_anno||' trib: '||p_tipo_trib||' vers: '||p_tipo_vers||' CF: '||p_cod_fiscale||' ('||SQLERRM||')';
        ELSE
          w_errore := 'Manca la data scadenza del saldo per l''anno indicato ('||SQLERRM||')';
        END IF;
        raise errore;
     end if;
EXCEPTION
     WHEN errore THEN RAISE;
 WHEN others THEN
      IF p_tipo_vers = 'A' THEN
        w_errore := 'Errore in ricerca Scadenze (Acconto) ('||SQLERRM||')';
      ELSE
        w_errore := 'Errore in ricerca Scadenze (Saldo) ('||SQLERRM||')';
      END IF;
      RAISE errore;
END data_scadenza_vers;
-----------------------------------
-- LIQUIDAZIONI_IMU_RENDITA
-----------------------------------
BEGIN 
   wf := 0;
   w_cont_non_liq := a_cont_non_liq;  --w_cont_non_liq non viene mai usato
   --
   data_scadenza_vers(a_anno,C_TIPO_TRIBUTO,'A',a_cod_fiscale,w_data_scad_acconto);
   data_scadenza_vers(a_anno,C_TIPO_TRIBUTO,'S',a_cod_fiscale,w_data_scad_saldo);
   --
   w_mError := '';
   FOR rec_ogim IN sel_ogim (a_anno, a_cod_fiscale) LOOP
      IF nvl(rec_ogim.mesi_possesso,12)
            < (nvl(rec_ogim.mesi_riduzione,0) + nvl(rec_ogim.mesi_esclusione,0)) THEN
            w_bError := TRUE;
            w_mError := 'La somma dei mesi esclusione e dei mesi riduzione è superiore ai mesi di possesso (M.E.: '
                ||rec_ogim.mesi_esclusione||', M.R.: '||rec_ogim.mesi_riduzione||', M.P.: '||rec_ogim.mesi_possesso||')';
        ELSIF nvl(rec_ogim.mesi_possesso,12)
            < nvl(rec_ogim.mesi_aliquota_ridotta,0) THEN
         w_bError := TRUE;
         w_mError := 'Mesi aliquota ridotta superiori ai mesi di possesso (M.R.: '
                  ||rec_ogim.mesi_aliquota_ridotta||', M.P.: '||rec_ogim.mesi_possesso||')';
      ELSIF rec_ogim.flag_ab_principale IS NOT NULL and rec_ogim.tipo_oggetto not in (3,4,55) THEN
         w_bError := TRUE;
         w_mError := 'Abitazione principale non compatibile con tipologia oggetto';
      ELSIF nvl(rec_ogim.perc_possesso,0) = 0 THEN
         w_bError := TRUE;
         w_mError := 'Percentuale di possesso non presente';
      ELSIF (rec_ogim.valore_dic IS NULL) AND
            (rec_ogim.tipo_ogg_ogpr != 1) AND
            ((rec_ogim.tipo_ogg_ogpr != 3) OR (substr(rec_ogim.categoria_catasto, 1, 1) not in ('E', 'F')))
            THEN   -- blocco solo il caso null e non il caso di zero
         w_bError := TRUE;
         w_mError := 'Valore dichiarato non presente';
      ELSIF rec_ogim.tipo_oggetto in (3,4,55) THEN
         begin
          select count(1)
           into w_esiste_categoria
           from categorie_catasto cate
          where cate.categoria_catasto  = rec_ogim.categoria_catasto
            and cate.flag_reale = 'S'
              ;
         EXCEPTION
              WHEN others THEN
                w_errore := 'Errore in controllo categorie catasto '||SQLERRM;
                RAISE errore;
         END;
         if w_esiste_categoria = 0 then
            w_bError := TRUE;
            w_mError := 'Categoria catasto non codificata ('||rec_ogim.categoria_catasto||')';
         end if;
      --ELSIF w_bError THEN
      ELSE
         w_bError := FALSE;
      END IF;
      IF w_bError THEN
         wf := 1;
         BEGIN
            delete pratiche_tributo
             where pratica = a_pratica
            ;
         EXCEPTION
            WHEN others THEN
            w_errore := 'Errore in Eliminazione Liquidazione (Pratica: '||a_pratica||')';
            raise errore;
         END;
         a_cont_non_liq := a_cont_non_liq +1;
         -- Gestione dei contribuenti non Liquidabili
         BEGIN
            insert into wrk_generale
                  (tipo_trattamento,anno,progressivo,dati,note)
            values ('LIQUIDAZIONE ICI',a_anno,to_number(to_char(sysdate,'yyyymmddhhMM'))*1000 + a_cont_non_liq
                   ,a_cod_fiscale,w_mError)
            ;
         EXCEPTION
            WHEN others THEN
               w_errore := 'Errore in inserimento wrk_generale ('||SQLERRM||')';
               RAISE errore;
         END;
         EXIT;
      ELSE
         wf := 2;
         IF rec_ogim.tipo_pratica = 'A' and rec_ogim.anno = a_anno THEN
            a_imp_dov                       := a_imp_dov - nvl(rec_ogim.imposta_dovuta,0);
            a_imp_dov_acconto               := a_imp_dov_acconto - nvl(rec_ogim.imposta_dovuta_acconto,0);
            a_imp_dov_dic                   := a_imp_dov_dic - nvl(rec_ogim.imposta_dovuta,0);
            a_imp_dov_acconto_dic           := a_imp_dov_acconto_dic - nvl(rec_ogim.imposta_dovuta_acconto,0);
            a_imp_dovuta_ab                 := a_imp_dovuta_ab - nvl(rec_ogim.imp_dovuta_ab,0);
            a_imp_dovuta_acconto_ab         := a_imp_dovuta_acconto_ab - nvl(rec_ogim.imp_dovuta_acconto_ab,0);
            a_imp_dovuta_dic_ab             := a_imp_dovuta_dic_ab - nvl(rec_ogim.imp_dovuta_dic_ab,0);
            a_imp_dovuta_acconto_dic_ab     := a_imp_dovuta_acconto_dic_ab - nvl(rec_ogim.imp_dovuta_acconto_dic_ab,0);
            a_imp_dovuta_ter                := a_imp_dovuta_ter - nvl(rec_ogim.imp_dovuta_ter,0);
            a_imp_dovuta_acconto_ter        := a_imp_dovuta_acconto_ter - nvl(rec_ogim.imp_dovuta_acconto_ter,0);
            a_imp_dovuta_dic_ter            := a_imp_dovuta_dic_ter - nvl(rec_ogim.imp_dovuta_dic_ter,0);
            a_imp_dovuta_acconto_dic_ter    := a_imp_dovuta_acconto_dic_ter - nvl(rec_ogim.imp_dovuta_acconto_dic_ter,0);
            a_imp_dov_ter_comu              := a_imp_dov_ter_comu - nvl(rec_ogim.imp_dovuta_ter_comu,0);
            a_imp_dov_acc_ter_comu          := a_imp_dov_acc_ter_comu - nvl(rec_ogim.imp_dovuta_acc_ter_comu,0);
            a_imp_dov_dic_ter_comu          := a_imp_dov_dic_ter_comu - nvl(rec_ogim.imp_dovuta_dic_ter_comu,0);
            a_imp_dov_acc_dic_ter_comu      := a_imp_dov_acc_dic_ter_comu - nvl(rec_ogim.imp_dovuta_acc_dic_ter_comu,0);
            a_imp_dov_ter_erar              := a_imp_dov_ter_erar - nvl(rec_ogim.imp_dovuta_ter_erar,0);
            a_imp_dov_acc_ter_erar          := a_imp_dov_acc_ter_erar - nvl(rec_ogim.imp_dovuta_acc_ter_erar,0);
            a_imp_dov_dic_ter_erar          := a_imp_dov_dic_ter_erar - nvl(rec_ogim.imp_dovuta_dic_ter_erar,0);
            a_imp_dov_acc_dic_ter_erar      := a_imp_dov_acc_dic_ter_erar - nvl(rec_ogim.imp_dovuta_acc_dic_ter_erar,0);
            a_imp_dovuta_aree               := a_imp_dovuta_aree - nvl(rec_ogim.imp_dovuta_aree,0);
            a_imp_dovuta_acconto_aree       := a_imp_dovuta_acconto_aree - nvl(rec_ogim.imp_dovuta_acconto_aree,0);
            a_imp_dovuta_dic_aree           := a_imp_dovuta_dic_aree - nvl(rec_ogim.imp_dovuta_dic_aree,0);
            a_imp_dovuta_acconto_dic_aree   := a_imp_dovuta_acconto_dic_aree - nvl(rec_ogim.imp_dovuta_acconto_dic_aree,0);
            a_imp_dov_aree_comu             := a_imp_dov_aree_comu - nvl(rec_ogim.imp_dovuta_aree_comu,0);
            a_imp_dov_acc_aree_comu         := a_imp_dov_acc_aree_comu - nvl(rec_ogim.imp_dovuta_acc_aree_comu,0);
            a_imp_dov_dic_aree_comu         := a_imp_dov_dic_aree_comu - nvl(rec_ogim.imp_dovuta_dic_aree_comu,0);
            a_imp_dov_acc_dic_aree_comu     := a_imp_dov_acc_dic_aree_comu - nvl(rec_ogim.imp_dovuta_acc_dic_aree_comu,0);
            a_imp_dov_aree_erar             := a_imp_dov_aree_erar - nvl(rec_ogim.imp_dovuta_aree_erar,0);
            a_imp_dov_acc_aree_erar         := a_imp_dov_acc_aree_erar - nvl(rec_ogim.imp_dovuta_acc_aree_erar,0);
            a_imp_dov_dic_aree_erar         := a_imp_dov_dic_aree_erar - nvl(rec_ogim.imp_dovuta_dic_aree_erar,0);
            a_imp_dov_acc_dic_aree_erar     := a_imp_dov_acc_dic_aree_erar - nvl(rec_ogim.imp_dovuta_acc_dic_aree_erar,0);
            a_imp_dov_rur                   := a_imp_dov_rur - nvl(rec_ogim.imp_dovuta_rurali,0);
            a_imp_dov_acc_rur               := a_imp_dov_acc_rur - nvl(rec_ogim.imp_dovuta_acc_rurali,0);
            a_imp_dov_dic_rur               := a_imp_dov_dic_rur - nvl(rec_ogim.imp_dovuta_dic_rurali,0);
            a_imp_dov_acc_dic_rur           := a_imp_dov_acc_dic_rur - nvl(rec_ogim.imp_dovuta_acc_dic_rurali,0);
            a_imp_dov_fab_d_comu            := a_imp_dov_fab_d_comu - nvl(rec_ogim.imp_dovuta_fab_d_comu,0);
            a_imp_dov_acc_fab_d_comu        := a_imp_dov_acc_fab_d_comu - nvl(rec_ogim.imp_dovuta_acc_fab_d_comu,0);
            a_imp_dov_dic_fab_d_comu        := a_imp_dov_dic_fab_d_comu - nvl(rec_ogim.imp_dovuta_dic_fab_d_comu,0);
            a_imp_dov_acc_dic_fab_d_comu    := a_imp_dov_acc_dic_fab_d_comu - nvl(rec_ogim.imp_dovuta_acc_dic_fab_d_comu,0);
            a_imp_dov_fab_d_erar            := a_imp_dov_fab_d_erar - nvl(rec_ogim.imp_dovuta_fab_d_erar,0);
            a_imp_dov_acc_fab_d_erar        := a_imp_dov_acc_fab_d_erar - nvl(rec_ogim.imp_dovuta_acc_fab_d_erar,0);
            a_imp_dov_dic_fab_d_erar        := a_imp_dov_dic_fab_d_erar - nvl(rec_ogim.imp_dovuta_dic_fab_d_erar,0);
            a_imp_dov_acc_dic_fab_d_erar    := a_imp_dov_acc_dic_fab_d_erar - nvl(rec_ogim.imp_dovuta_acc_dic_fab_d_erar,0);
            a_imp_dovuta_altri              := a_imp_dovuta_altri - nvl(rec_ogim.imp_dovuta_altri,0);
            a_imp_dovuta_acconto_altri      := a_imp_dovuta_acconto_altri - nvl(rec_ogim.imp_dovuta_acconto_altri,0);
            a_imp_dovuta_dic_altri          := a_imp_dovuta_dic_altri - nvl(rec_ogim.imp_dovuta_dic_altri,0);
            a_imp_dovuta_acconto_dic_altri  := a_imp_dovuta_acconto_dic_altri - nvl(rec_ogim.imp_dovuta_acconto_dic_altri,0);
            a_imp_dov_altri_comu            := a_imp_dov_altri_comu - nvl(rec_ogim.imp_dovuta_altri_comu,0);
            a_imp_dov_acc_altri_comu        := a_imp_dov_acc_altri_comu - nvl(rec_ogim.imp_dovuta_acc_altri_comu,0);
            a_imp_dov_dic_altri_comu        := a_imp_dov_dic_altri_comu - nvl(rec_ogim.imp_dovuta_dic_altri_comu,0);
            a_imp_dov_acc_dic_altri_comu    := a_imp_dov_acc_dic_altri_comu - nvl(rec_ogim.imp_dovuta_acc_dic_altri_comu,0);
            a_imp_dov_altri_erar            := a_imp_dov_altri_erar - nvl(rec_ogim.imp_dovuta_altri_erar,0);
            a_imp_dov_acc_altri_erar        := a_imp_dov_acc_altri_erar - nvl(rec_ogim.imp_dovuta_acc_altri_erar,0);
            a_imp_dov_dic_altri_erar        := a_imp_dov_dic_altri_erar - nvl(rec_ogim.imp_dovuta_dic_altri_erar,0);
            a_imp_dov_acc_dic_altri_erar    := a_imp_dov_acc_dic_altri_erar - nvl(rec_ogim.imp_dovuta_acc_dic_altri_erar,0);
            -- Fabbricati Merce
            a_imp_dovuta_fab_m              := a_imp_dovuta_fab_m - nvl(rec_ogim.imp_dovuta_fabb_merce,0);
            a_imp_dovuta_acconto_fab_m      := a_imp_dovuta_acconto_fab_m - nvl(rec_ogim.imp_dovuta_acc_fabb_merce,0);
            a_imp_dovuta_dic_fab_m          := a_imp_dovuta_dic_fab_m - nvl(rec_ogim.imp_dovuta_dic_fabb_merce,0);
            a_imp_dovuta_acconto_dic_fab_m  := a_imp_dovuta_acconto_dic_fab_m - nvl(rec_ogim.imp_dovuta_acc_dic_fabb_merce,0);
            -- Mini IMU
            a_imp_dov_mini                  := a_imp_dov_mini - nvl(rec_ogim.imposta_dovuta_mini,0);
            a_imp_dov_mini_dic              := a_imp_dov_mini_dic - nvl(rec_ogim.imposta_dovuta_mini,0);
            a_imp_dovuta_mini_ab            := a_imp_dovuta_mini_ab - nvl(rec_ogim.imp_dovuta_mini_ab,0);
            a_imp_dovuta_mini_dic_ab        := a_imp_dovuta_mini_dic_ab - nvl(rec_ogim.imp_dovuta_mini_dic_ab,0);
            a_imp_dovuta_mini_ter           := a_imp_dovuta_mini_ter - nvl(rec_ogim.imp_dovuta_mini_ter,0);
            a_imp_dovuta_mini_dic_ter       := a_imp_dovuta_mini_dic_ter - nvl(rec_ogim.imp_dovuta_mini_dic_ter,0);
            a_versamenti                    := a_versamenti - nvl(rec_ogim.imposta_dovuta,0);
            a_versamenti_acconto            := a_versamenti_acconto - nvl(rec_ogim.imposta_dovuta_acconto,0);
            a_versamenti_ab                 := a_versamenti_ab - nvl(rec_ogim.imp_dovuta_ab,0);
            a_versamenti_acconto_ab         := a_versamenti_acconto_ab - nvl(rec_ogim.imp_dovuta_acconto_ab,0);
            a_versamenti_ter                := a_versamenti_ter - nvl(rec_ogim.imp_dovuta_ter,0);
            a_versamenti_acconto_ter        := a_versamenti_acconto_ter - nvl(rec_ogim.imp_dovuta_acconto_ter,0);
            a_versamenti_aree               := a_versamenti_aree - nvl(rec_ogim.imp_dovuta_aree,0);
            a_versamenti_acconto_aree       := a_versamenti_acconto_aree - nvl(rec_ogim.imp_dovuta_acconto_aree,0);
            a_versamenti_altri              := a_versamenti_altri - nvl(rec_ogim.imp_dovuta_altri,0);
            a_versamenti_acconto_altri      := a_versamenti_acconto_altri - nvl(rec_ogim.imp_dovuta_acconto_altri,0);
            a_vers_rurali                   := a_vers_rurali - nvl(rec_ogim.imp_dovuta_rurali,0);
            a_vers_acconto_rurali           := a_vers_acconto_rurali - nvl(rec_ogim.imp_dovuta_acc_rurali,0);
            a_vers_ter_comu                 := a_vers_ter_comu - nvl(rec_ogim.imp_dovuta_ter_comu,0);
            a_vers_acconto_ter_comu         := a_vers_acconto_ter_comu - nvl(rec_ogim.imp_dovuta_acc_ter_comu,0);
            a_vers_ter_erar                 := a_vers_ter_erar - nvl(rec_ogim.imp_dovuta_ter_erar,0);
            a_vers_acconto_ter_erar         := a_vers_acconto_ter_erar - nvl(rec_ogim.imp_dovuta_acc_ter_erar,0);
            a_vers_aree_comu                := a_vers_aree_comu - nvl(rec_ogim.imp_dovuta_aree_comu,0);
            a_vers_acconto_aree_comu        := a_vers_acconto_aree_comu - nvl(rec_ogim.imp_dovuta_acc_aree_comu,0);
            a_vers_aree_erar                := a_vers_aree_erar - nvl(rec_ogim.imp_dovuta_aree_erar,0);
            a_vers_acconto_aree_erar        := a_vers_acconto_aree_erar - nvl(rec_ogim.imp_dovuta_acc_aree_erar,0);
            a_vers_altri_comu               := a_vers_altri_comu - nvl(rec_ogim.imp_dovuta_altri_comu,0);
            a_vers_acconto_altri_comu       := a_vers_acconto_altri_comu - nvl(rec_ogim.imp_dovuta_acc_altri_comu,0);
            a_vers_altri_erar               := a_vers_altri_erar - nvl(rec_ogim.imp_dovuta_altri_erar,0);
            a_vers_acconto_altri_erar       := a_vers_acconto_altri_erar - nvl(rec_ogim.imp_dovuta_acc_altri_erar,0);
            a_vers_fab_d_comu               := a_vers_fab_d_comu - nvl(rec_ogim.imp_dovuta_fab_d_comu,0);
            a_vers_acconto_fab_d_comu       := a_vers_acconto_fab_d_comu - nvl(rec_ogim.imp_dovuta_acc_fab_d_comu,0);
            a_vers_fab_d_erar               := a_vers_fab_d_erar - nvl(rec_ogim.imp_dovuta_fab_d_erar,0);
            a_vers_acconto_fab_d_erar       := a_vers_acconto_fab_d_erar - nvl(rec_ogim.imp_dovuta_acc_fab_d_erar,0);
            -- Fabbricati Merce
            a_vers_fabb_merce               := a_vers_fabb_merce - nvl(rec_ogim.imp_dovuta_fabb_merce,0);
            a_vers_acconto_fabb_merce       := a_vers_acconto_fabb_merce - nvl(rec_ogim.imp_dovuta_acc_fabb_merce,0);
            -- Mini IMU
            a_versamenti_mini               := a_versamenti_mini     - nvl(rec_ogim.imposta_dovuta_mini,0);
            a_versamenti_mini_ab            := a_versamenti_mini_ab  - nvl(rec_ogim.imp_dovuta_mini_ab,0);
            a_versamenti_mini_ter           := a_versamenti_mini_ter - nvl(rec_ogim.imp_dovuta_mini_ter,0);
         ELSE
            wf := 3;
            w_oggetto_pratica := NULL;
            oggetti_pratica_nr(w_oggetto_pratica);
            w_oggetto_imposta := NULL;
            oggetti_imposta_nr(w_oggetto_imposta);
            w_anno := a_anno;
            --
            -- AB (08/04/2024) Spostato sopra la select per considerare anche il w_mese_inizio
            --
            -- AB (09/08/2023) Aggiunti per gestire i casi di mese iniziuo e fine che davano errore
            -- x mesi_possesso = 0 da_mese possesso 1
            if rec_ogim.da_mese_possesso < 1 then
                w_mese_inizio := 1;
            elsif rec_ogim.da_mese_possesso > 12 then
                w_mese_inizio := 12;
            else
                w_mese_inizio := rec_ogim.da_mese_possesso;
            end if;
            if (rec_ogim.da_mese_possesso+rec_ogim.mesi_possesso-1) < 1 then
                w_mese_fine := 1;
            elsif (rec_ogim.da_mese_possesso+rec_ogim.mesi_possesso-1) > 12 then
                w_mese_fine := 12;
            else
                w_mese_fine := (rec_ogim.da_mese_possesso+rec_ogim.mesi_possesso-1);
            end if;

            BEGIN
--               select count(*)
--                     ,min(nvl(riog.inizio_validita,to_date('01011900','ddmmyyyy')))
--                     ,max(nvl(riog.fine_validita,to_date('31122999','ddmmyyyy')))
--                 into w_num_riog
--                     ,w_min_dal_riog
--                     ,w_max_al_riog
--                 from riferimenti_oggetto riog
--                where w_anno between nvl(riog.da_anno,0) and nvl(riog.a_anno,9999)
--                  and riog.oggetto = rec_ogim.oggetto
                -- AB 31/01/2023 aggiunta la select da periodo_riog per avere gia il dato
                -- corretto del primo o dell'ultimo giorno del mese
                select count(*)
                      ,min(nvl(peri.inizio_validita,to_date('01011900','ddmmyyyy')))
                      ,max(nvl(peri.fine_validita,to_date('31122999','ddmmyyyy')))
                  into w_num_riog
                      ,w_min_dal_riog
                      ,w_max_al_riog
                  from periodi_riog peri, riferimenti_oggetto riog
                 where w_anno between nvl(riog.da_anno,0) and nvl(riog.a_anno,9999)
                   and riog.oggetto = peri.oggetto
                   -- and to_char(peri.fine_validita,'yyyy') >= w_anno  --AB 08/05/2022 aggiunto controllo
                   -- and peri.inizio_validita_eff is not null
                   and w_anno between to_char(peri.inizio_validita,'yyyy') and to_char(peri.fine_validita,'yyyy')  -- AB 27/09/2022 aggiunto ulteriore controllo
                   and peri.inizio_validita_eff = riog.inizio_validita
                   and riog.oggetto = rec_ogim.oggetto
-- AB (08/04/2024 per avere solo il pezzetto corretto nel caso di due o pi record nell'anno
                   and w_mese_inizio = decode(to_char(peri.inizio_validita,'yyyy'),
                                              w_anno,
                                                 to_number(to_char(peri.inizio_validita,'mm')),
                                                 1)
               ;
            END;
           --dbms_output.put_line('oggetto pratica '||to_char(w_oggetto_pratica));
           --dbms_output.put_line('oggetto '||to_char(rec_ogim.oggetto));
           --dbms_output.put_line('pratica '||to_char(a_pratica));
           --dbms_output.put_line('anno '||to_char(a_anno));
           --dbms_output.put_line('Categoria/Classe '||rec_ogim.categoria_catasto||'/'||rec_ogim.classe_catasto);

            if  w_num_riog = 1
             and w_min_dal_riog <= to_date('01'||lpad(w_mese_inizio,2,'0')||lpad(to_char(w_anno),4,'0'),'ddmmyyyy')
--             and w_max_al_riog  >= to_date('3112'||lpad(to_char(w_anno),4,'0'),'ddmmyyyy')
                        and w_max_al_riog  >= last_day(
                            to_date('01'||lpad(w_mese_fine,2,'0')||
                                    lpad(to_char(w_anno),4,'0'),'ddmmyyyy'))
                    or w_num_riog = 0
                then
                    w_valore_ogpr := rec_ogim.valore;
                    --              if rec_ogim.oggetto = 162912 then
--                  dbms_output.put_line('valore '||to_char(rec_ogim.valore));
--                    w_errore := 'valore '||to_char(rec_ogim.valore)||' '||SQLERRM;
--                    RAISE errore;
--              end if;
                else
                    w_valore_ogpr := null;
                    --dbms_output.put_line('Valore Nullo per multi riog');
                end if;
-- AB (21/12/2022) Aggiunto per avere il valore e la rendita nella liquidazione
            if w_valore_ogpr = 0
            and (rec_ogim.mesi_esclusione > 0 or rec_ogim.flag_esclusione = 'S') then
                w_valore_ogpr := rec_ogim.valore_dic;
            end if;
            BEGIN
              insert into oggetti_pratica
                     (oggetto_pratica,oggetto,pratica,anno,
                      categoria_catasto,classe_catasto,valore,
                      oggetto_pratica_rif,utente,data_variazione,
                      tipo_oggetto,imm_storico)
              select  w_oggetto_pratica,rec_ogim.oggetto,a_pratica,
                      a_anno,rec_ogim.categoria_catasto,
                      rec_ogim.classe_catasto,
                      w_valore_ogpr,rec_ogim.oggetto_pratica,
                      a_utente,trunc(sysdate),rec_ogim.tipo_oggetto,
                      rec_ogim.imm_storico
                 from dual
              ;
            EXCEPTION
              WHEN others THEN
                w_errore := 'Errore in inserimento oggetto pratica '||SQLERRM;
                RAISE errore;
            END;
            BEGIN
              insert into costi_storici
                    (oggetto_pratica,anno,costo,utente,data_variazione,note)
              select w_oggetto_pratica,anno,costo,a_utente,trunc(sysdate),note
                from costi_storici
               where oggetto_pratica = rec_ogim.oggetto_pratica
              ;
            EXCEPTION
              WHEN others THEN
                 w_errore := 'Errore in inserimento costi storici ';
                 RAISE errore;
            END;
            BEGIN
              wf := 4;
              insert into oggetti_contribuente
                     (cod_fiscale,oggetto_pratica,anno,
                      perc_possesso,mesi_possesso,mesi_possesso_1sem,
                      mesi_esclusione,mesi_riduzione,mesi_aliquota_ridotta,
                      detrazione,flag_possesso,flag_esclusione,
                      flag_riduzione,flag_ab_principale,
                      flag_al_ridotta,
                      utente,data_variazione)
              values (a_cod_fiscale,w_oggetto_pratica,a_anno,
                      rec_ogim.perc_possesso,rec_ogim.mesi_possesso,
                      rec_ogim.mesi_possesso_1sem,
                      rec_ogim.mesi_esclusione,rec_ogim.mesi_riduzione,
                      rec_ogim.mesi_aliquota_ridotta,
                      rec_ogim.detrazione,rec_ogim.flag_possesso,
                      rec_ogim.flag_esclusione,
                      rec_ogim.flag_riduzione,rec_ogim.flag_ab_principale,
                      rec_ogim.flag_al_ridotta,
                      a_utente,trunc(sysdate))
              ;
            EXCEPTION
              WHEN others THEN
                w_errore := 'Errore in inserimento oggetto contribuente '||'cf:'||a_cod_fiscale||' ogpr:'||to_char(w_oggetto_pratica);
                RAISE errore;
            END;
            BEGIN
              wf := 5;
              insert into oggetti_imposta
                     (oggetto_imposta,cod_fiscale,anno,
                      oggetto_pratica,imposta,imposta_acconto,
                      imposta_dovuta,imposta_dovuta_acconto,
                      imposta_erariale,imposta_erariale_acconto,
                      imposta_erariale_dovuta,imposta_erariale_dovuta_acc,
                      tipo_aliquota,aliquota,aliquota_erariale,
                      detrazione,detrazione_acconto,
                      -- Mini IMU
                      aliquota_std,imposta_aliquota,
                      imposta_std,imposta_mini,
                      imposta_dovuta_std,imposta_dovuta_mini,
                      detrazione_std,
                      utente,data_variazione, tipo_tributo)
              values (w_oggetto_imposta,a_cod_fiscale,a_anno,
                      w_oggetto_pratica,rec_ogim.imposta,
                      rec_ogim.imposta_acconto,
                      rec_ogim.imposta_dovuta,
                      rec_ogim.imposta_dovuta_acconto,
                      rec_ogim.imposta_erariale,
                      rec_ogim.imposta_erariale_acconto,
                      rec_ogim.imposta_erariale_dovuta,
                      rec_ogim.imposta_erariale_dovuta_acc,
                      rec_ogim.tipo_aliquota,rec_ogim.aliquota,
                      rec_ogim.aliquota_erariale,
                      rec_ogim.detrazione_ogim,rec_ogim.detrazione_acc_ogim,
                      rec_ogim.aliquota_std,rec_ogim.imposta_aliquota,
                      rec_ogim.imposta_std,rec_ogim.imposta_mini,
                      rec_ogim.imposta_dovuta_std,rec_ogim.imposta_dovuta_mini,
                      rec_ogim.detrazione_std_ogim,
                      a_utente,trunc(sysdate), 'ICI')
              ;
            EXCEPTION
              WHEN others THEN
                w_errore := 'Errore in inserimento oggetto imposta '||'cf:'||a_cod_fiscale||' ogpr:'||to_char(w_oggetto_pratica);
                RAISE errore;
            END;
            IF nvl(rec_ogim.valore,0) > nvl(rec_ogim.valore_dic,0)
              AND nvl(rec_ogim.valore_dic,0) > 0
              AND nvl(rec_ogim.imposta,0) > 0
              AND sign(nvl(rec_ogim.valore,0) - (nvl(rec_ogim.valore_dic,0) * 1.3)) = 1
              THEN
               IF nvl(rec_ogim.detrazione,0) != 0 THEN
                  w_detr_acconto := f_round(nvl(rec_ogim.imposta_acconto,0)
                                     * nvl(rec_ogim.detrazione,0)
                                     / nvl(rec_ogim.imposta,0),0);
               END IF;
               w_imponibile_10_acconto := f_round(nvl(rec_ogim.imposta_acconto,0) - nvl(rec_ogim.imposta_dovuta_acconto,0),1);
               w_imponibile_10_saldo   := f_round(nvl(rec_ogim.imposta,0) - nvl(rec_ogim.imposta_dovuta,0),1)
                                           - w_imponibile_10_acconto;
               IF nvl(w_imponibile_10_acconto,0) > 0 THEN  -- INIZIO CONTROLLO ANOMALIE 10 , 110
                  w_cod_sanzione := C_DIFF_REND_30_ACC;
                  w_check := f_check_sanzione(a_pratica,w_cod_sanzione,w_data_scad_acconto);
                  IF w_check = 0 THEN
                    wf := 6;
                    inserimento_sanzione_liq_imu(w_cod_sanzione,C_TIPO_TRIBUTO
                                            ,a_pratica,NULL
                                            ,w_imponibile_10_acconto,NULL
                                            ,NULL
                                            ,NULL,NULL
                                            ,NULL,NULL
                                            ,NULL
                                            ,NULL,NULL
                                            ,NULL,NULL
                                            ,NULL
                                            ,a_utente
                                            ,w_data_scad_acconto);
                  ELSIF w_check = 1 THEN
                    aggiornamento_sanzione_liq_imu(w_cod_sanzione,C_TIPO_TRIBUTO
                                              ,a_pratica,NULL,w_imponibile_10_acconto,NULL
                                              ,NULL
                                              ,NULL,NULL
                                              ,NULL,NULL
                                              ,NULL
                                              ,NULL,NULL
                                              ,NULL,NULL
                                              ,NULL
                                              ,a_utente
                                              ,w_data_scad_acconto);
                  ELSE
                    w_errore := 'Errore f_check_sanzione per sanzione: '||w_cod_sanzione;
                  END IF;
                  w_cod_sanzione := w_cod_sanzione + C_NUOVO;
                  w_check := f_check_sanzione(a_pratica,w_cod_sanzione,w_data_scad_acconto);
                  wf := 7;
                  IF w_check = 0 THEN
                     inserimento_sanzione_liq_imu(w_cod_sanzione,C_TIPO_TRIBUTO
                                             ,a_pratica,NULL
                                             ,w_imponibile_10_acconto,NULL
                                             ,NULL
                                             ,NULL,NULL
                                             ,NULL,NULL
                                             ,NULL
                                             ,NULL,NULL
                                             ,NULL,NULL
                                             ,NULL
                                             ,a_utente
                                             ,w_data_scad_acconto);
                  ELSIF w_check = 1 THEN
                     wf := 8;
                     aggiornamento_sanzione_liq_imu(w_cod_sanzione,C_TIPO_TRIBUTO
                                               ,a_pratica,NULL,w_imponibile_10_acconto,NULL
                                               ,NULL
                                               ,NULL,NULL
                                               ,NULL,NULL
                                               ,NULL
                                               ,NULL,NULL
                                               ,NULL,NULL
                                               ,NULL
                                               ,a_utente
                                               ,w_data_scad_acconto);
                  ELSE
                     w_errore := 'Errore f_check_sanzione per sanzione: '||w_cod_sanzione;
                  END IF;
               END IF; -- FINE CONTROLLO ANOMALIE 10 , 110
               IF nvl(w_imponibile_10_saldo,0) > 0 THEN -- INIZIO CONTROLLO ANOMALIE 20 , 120
                  w_cod_sanzione := C_DIFF_REND_30_SAL;
                  w_check := f_check_sanzione(a_pratica,w_cod_sanzione,w_data_scad_saldo);
                  IF w_check = 0 THEN
                     wf := 9;
                     inserimento_sanzione_liq_imu(w_cod_sanzione,C_TIPO_TRIBUTO
                                             ,a_pratica,NULL
                                             ,w_imponibile_10_saldo,NULL
                                             ,NULL
                                             ,NULL,NULL
                                             ,NULL,NULL
                                             ,NULL
                                             ,NULL,NULL
                                             ,NULL,NULL
                                             ,NULL
                                             ,a_utente
                                             ,w_data_scad_saldo);
                  ELSIF w_check = 1 THEN
                    wf := 10;
                    aggiornamento_sanzione_liq_imu(w_cod_sanzione,C_TIPO_TRIBUTO
                                              ,a_pratica,NULL,w_imponibile_10_saldo,NULL
                                              ,NULL
                                              ,NULL,NULL
                                              ,NULL,NULL
                                              ,NULL
                                              ,NULL,NULL
                                              ,NULL,NULL
                                              ,NULL
                                              ,a_utente
                                              ,w_data_scad_saldo);
                  ELSE
                    w_errore := 'Errore f_check_sanzione per sanzione: '||w_cod_sanzione;
                  END IF;
                  w_cod_sanzione := w_cod_sanzione + C_NUOVO;
                  w_check := f_check_sanzione(a_pratica,w_cod_sanzione,w_data_scad_saldo);
                  IF w_check = 0 THEN
                     inserimento_sanzione_liq_imu(w_cod_sanzione,C_TIPO_TRIBUTO
                                             ,a_pratica,NULL
                                             ,w_imponibile_10_saldo,NULL
                                             ,NULL
                                             ,NULL,NULL
                                             ,NULL,NULL
                                             ,NULL
                                             ,NULL,NULL
                                             ,NULL,NULL
                                             ,NULL
                                             ,a_utente
                                             ,w_data_scad_saldo);
                  ELSIF w_check = 1 THEN
                    wf := 11;
                    aggiornamento_sanzione_liq_imu(w_cod_sanzione,C_TIPO_TRIBUTO
                                              ,a_pratica,NULL,w_imponibile_10_saldo,NULL
                                              ,NULL
                                              ,NULL,NULL
                                              ,NULL,NULL
                                              ,NULL
                                              ,NULL,NULL
                                              ,NULL,NULL
                                              ,NULL
                                              ,a_utente
                                              ,w_data_scad_saldo);
                  ELSE
                  w_errore := 'Errore f_check_sanzione per sanzione: '||w_cod_sanzione;
                  END IF;
               END IF; -- FINE CONTROLLO ANOMALIE 20 , 120
            END IF; -- FINE CONTROLLO ANOMALIE 10 , 20 , 110 , 120
         END IF; -- rec_ogim.tipo_pratica = 'A' and rec_ogim.anno = a_anno
      END IF; -- nvl(rec_ogim.mesi_possesso,12).....
   END LOOP;
EXCEPTION
    WHEN errore THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR (-20999,w_errore,TRUE);
    WHEN others THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR (-20999,'Errore in LIQUIDAZIONI IMU RENDITA -'||to_char(wf)||'- ('||SQLERRM||')');
END;
/* End Procedure: LIQUIDAZIONI_IMU_RENDITA */
/
