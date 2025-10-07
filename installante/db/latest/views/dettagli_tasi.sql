--liquibase formatted sql 
--changeset abrandolini:20250326_152401_dettagli_tasi stripComments:false runOnChange:true 
 
create or replace force view dettagli_tasi as
select dett.cod_fiscale cod_fiscale
         ,translate(max(sogg.cognome_nome)
                   ,'/'
                   ,' '
                   )
           cognome_nome
         ,dett.anno anno
         ,sum(dett.ab_comu) ab_comu
         ,sum(dett.ab_comu_acc) ab_comu_acc
         ,sum(dett.n_fab_ab) n_fab_ab
         ,sum(dett.detr_comu) detr_comu
         ,sum(dett.detr_comu_acc) detr_comu_acc
         ,sum(dett.rurali_comu) rurali_comu
         ,sum(dett.rurali_comu_acc) rurali_comu_acc
         ,sum(dett.n_fab_rurali) n_fab_rurali
         ,sum(dett.terreni_comu) terreni_comu
         ,sum(dett.terreni_comu_acc) terreni_comu_acc
         ,sum(dett.terreni_erar) terreni_erar
         ,sum(dett.terreni_erar_acc) terreni_erar_acc
         ,sum(dett.n_terreni) n_terreni
         ,sum(dett.aree_comu) aree_comu
         ,sum(dett.aree_comu_acc) aree_comu_acc
         ,sum(dett.aree_erar) aree_erar
         ,sum(dett.aree_erar_acc) aree_erar_acc
         ,sum(dett.n_aree) n_aree
         ,sum(dett.fabb_d_comu) fabb_d_comu
         ,sum(dett.fabb_d_comu_acc) fabb_d_comu_acc
         ,sum(dett.fabb_d_erar) fabb_d_erar
         ,sum(dett.fabb_d_erar_acc) fabb_d_erar_acc
         ,sum(dett.n_fab_fabb_d) n_fab_fabb_d
         ,sum(dett.altri_comu) altri_comu
         ,sum(dett.altri_comu_acc) altri_comu_acc
         ,sum(dett.altri_erar) altri_erar
         ,sum(dett.altri_erar_acc) altri_erar_acc
         ,sum(dett.n_fab_altri) n_fab_altri
         ,sum(dett.vers_ab_princ) vers_ab_princ
         ,sum(dett.vers_ab_princ_acc) vers_ab_princ_acc
         ,sum(dett.vers_detrazione) vers_detrazione
         ,sum(dett.vers_detrazione_acc) vers_detrazione_acc
         ,sum(dett.vers_rurali) vers_rurali
         ,sum(dett.vers_rurali_acc) vers_rurali_acc
         ,sum(dett.vers_altri_comu) vers_altri_comu
         ,sum(dett.vers_altri_comu_acc) vers_altri_comu_acc
         ,sum(dett.vers_altri_erar) vers_altri_erar
         ,sum(dett.vers_altri_erar_acc) vers_altri_erar_acc
         ,sum(dett.vers_terreni_comu) vers_terreni_comu
         ,sum(dett.vers_terreni_comu_acc) vers_terreni_comu_acc
         ,sum(dett.vers_terreni_erar) vers_terreni_erar
         ,sum(dett.vers_terreni_erar_acc) vers_terreni_erar_acc
         ,sum(dett.vers_aree_comu) vers_aree_comu
         ,sum(dett.vers_aree_comu_acc) vers_aree_comu_acc
         ,sum(dett.vers_aree_erar) vers_aree_erar
         ,sum(dett.vers_aree_erar_acc) vers_aree_erar_acc
         ,sum(dett.vers_fab_d_comu) vers_fab_d_comu
         ,sum(dett.vers_fab_d_comu_acc) vers_fab_d_comu_acc
         ,sum(dett.vers_fab_d_erar) vers_fab_d_erar
         ,sum(dett.vers_fab_d_erar_acc) vers_fab_d_erar_acc
         ,nvl(sum(dett.ab_comu), 0) +
          nvl(sum(dett.rurali_comu), 0) +
          nvl(sum(dett.terreni_comu), 0) +
          nvl(sum(dett.aree_comu), 0) +
          nvl(sum(dett.fabb_d_comu), 0) +
          nvl(sum(dett.altri_comu), 0)
           imposta_comu
         ,nvl(sum(dett.ab_comu_acc), 0) +
          nvl(sum(dett.rurali_comu_acc), 0) +
          nvl(sum(dett.terreni_comu_acc), 0) +
          nvl(sum(dett.aree_comu_acc), 0) +
          nvl(sum(dett.fabb_d_comu_acc), 0) +
          nvl(sum(dett.altri_comu_acc), 0)
           imposta_comu_acc
         ,nvl(sum(dett.terreni_erar), 0) +
          nvl(sum(dett.aree_erar), 0) +
          nvl(sum(dett.fabb_d_erar), 0) +
          nvl(sum(dett.altri_erar), 0)
           imposta_erar
         ,nvl(sum(dett.terreni_erar_acc), 0) +
          nvl(sum(dett.aree_erar_acc), 0) +
          nvl(sum(dett.fabb_d_erar_acc), 0) +
          nvl(sum(dett.altri_erar_acc), 0)
           imposta_erar_acc
         ,nvl(sum(dett.vers_ab_princ), 0) +
          nvl(sum(dett.vers_rurali), 0) +
          nvl(sum(dett.vers_altri_comu), 0) +
          nvl(sum(dett.vers_terreni_comu), 0) +
          nvl(sum(dett.vers_aree_comu), 0) +
          nvl(sum(dett.vers_fab_d_comu), 0)
           versamenti_comu
         ,nvl(sum(dett.vers_ab_princ_acc), 0) +
          nvl(sum(dett.vers_rurali_acc), 0) +
          nvl(sum(dett.vers_altri_comu_acc), 0) +
          nvl(sum(dett.vers_terreni_comu_acc), 0) +
          nvl(sum(dett.vers_aree_comu_acc), 0) +
          nvl(sum(dett.vers_fab_d_comu_acc), 0)
           versamenti_comu_acc
         ,nvl(sum(dett.vers_altri_erar), 0) +
          nvl(sum(dett.vers_terreni_erar), 0) +
          nvl(sum(dett.vers_aree_erar), 0) +
          nvl(sum(dett.vers_fab_d_erar), 0)
           versamenti_erar
         ,nvl(sum(dett.vers_altri_erar_acc), 0) +
          nvl(sum(dett.vers_terreni_erar_acc), 0) +
          nvl(sum(dett.vers_aree_erar_acc), 0) +
          nvl(sum(dett.vers_fab_d_erar_acc), 0)
           versamenti_erar_acc
     from contribuenti cont
         ,soggetti sogg
         ,(  select ogim.cod_fiscale cod_fiscale
                   ,ogim.anno anno
                   ,sum(decode(ogim.tipo_aliquota, 2, ogim.imposta, 0)) ab_comu
                   ,sum(decode(ogim.tipo_aliquota, 2, ogim.imposta_acconto, 0))
                     ab_comu_acc
                   ,sum(decode(ogim.tipo_aliquota, 2, 1, 0)) n_fab_ab
                   ,sum(ogim.detrazione) detr_comu
                   ,sum(ogim.detrazione_acconto) detr_comu_acc
                   ,sum(decode(ogim.tipo_aliquota, 2, 0, decode(nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto),  1, 0,  2, 0,  decode(aliquota_erariale, null, ogim.imposta, 0)))
                       )
                     rurali_comu
                   ,sum(decode(ogim.tipo_aliquota, 2, 0, decode(nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto),  1, 0,  2, 0,  decode(aliquota_erariale, null, ogim.imposta_acconto, 0)))
                       )
                     rurali_comu_acc
                   ,sum(decode(ogim.tipo_aliquota, 2, 0, decode(nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto),  1, 0,  2, 0,  decode(aliquota_erariale, null, 1, 0)))
                       )
                     n_fab_rurali
                   ,sum(decode(nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto), 1, ogim.imposta - nvl(ogim.imposta_erariale, 0), 0)
                       )
                     terreni_comu
                   ,sum(decode(nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto), 1, ogim.imposta_acconto - nvl(ogim.imposta_erariale_acconto, 0), 0)
                       )
                     terreni_comu_acc
                   ,sum(decode(nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto), 1, ogim.imposta_erariale, 0)
                       )
                     terreni_erar
                   ,sum(decode(nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto), 1, ogim.imposta_erariale_acconto, 0)
                       )
                     terreni_erar_acc
                   ,sum(decode(nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto), 1, 1, 0)) n_terreni
                   ,sum(decode(nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto), 2, ogim.imposta - nvl(ogim.imposta_erariale, 0), 0)
                       )
                     aree_comu
                   ,sum(decode(nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto), 2, ogim.imposta_acconto - nvl(ogim.imposta_erariale_acconto, 0), 0)
                       )
                     aree_comu_acc
                   ,sum(decode(nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto), 2, ogim.imposta_erariale, 0)
                       )
                     aree_erar
                   ,sum(decode(nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto), 2, ogim.imposta_erariale_acconto, 0)
                       )
                     aree_erar_acc
                   ,sum(decode(nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto), 2, 1, 0)) n_aree
                   ,sum(decode(ogim.tipo_aliquota
                              ,2, 0
                              ,decode(nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto)
                                     ,1, 0
                                     ,2, 0
                                     ,decode(aliquota_erariale
                                            ,null, 0
                                            ,decode(sign(ogim.anno - 2012)
                                                   ,1, decode(substr(nvl(ogpr.categoria_catasto, ogge.categoria_catasto)
                                                                    ,1
                                                                    ,1
                                                                    ) ||
                                                              to_char(ogim.tipo_aliquota
                                                                     )
                                                             ,'D9', ogim.imposta -
                                                                    nvl(ogim.
                                                                          imposta_erariale
                                                                       ,0
                                                                       )
                                                             ,0
                                                             )
                                                   ,0
                                                   )
                                            )
                                     )
                              )
                       )
                     fabb_d_comu
                   ,sum(decode(ogim.tipo_aliquota
                              ,2, 0
                              ,decode(nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto)
                                     ,1, 0
                                     ,2, 0
                                     ,decode(aliquota_erariale
                                            ,null, 0
                                            ,decode(sign(ogim.anno - 2012)
                                                   ,1, decode(substr(nvl(ogpr.categoria_catasto, ogge.categoria_catasto)
                                                                    ,1
                                                                    ,1
                                                                    ) ||
                                                              to_char(ogim.tipo_aliquota
                                                                     )
                                                             ,'D9', ogim.
                                                                      imposta_acconto -
                                                                    nvl(ogim.
                                                                          imposta_erariale_acconto
                                                                       ,0
                                                                       )
                                                             ,0
                                                             )
                                                   ,0
                                                   )
                                            )
                                     )
                              )
                       )
                     fabb_d_comu_acc
                   ,sum(decode(ogim.tipo_aliquota
                              ,2, 0
                              ,decode(nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto)
                                     ,1, 0
                                     ,2, 0
                                     ,decode(aliquota_erariale
                                            ,null, 0
                                            ,decode(sign(ogim.anno - 2012)
                                                   ,1, decode(substr(nvl(ogpr.categoria_catasto, ogge.categoria_catasto)
                                                                    ,1
                                                                    ,1
                                                                    ) ||
                                                              to_char(ogim.tipo_aliquota
                                                                     )
                                                             ,'D9', ogim.
                                                                      imposta_erariale
                                                             ,0
                                                             )
                                                   ,0
                                                   )
                                            )
                                     )
                              )
                       )
                     fabb_d_erar
                   ,sum(decode(ogim.tipo_aliquota
                              ,2, 0
                              ,decode(nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto)
                                     ,1, 0
                                     ,2, 0
                                     ,decode(aliquota_erariale
                                            ,null, 0
                                            ,decode(sign(ogim.anno - 2012)
                                                   ,1, decode(substr(nvl(ogpr.categoria_catasto, ogge.categoria_catasto)
                                                                    ,1
                                                                    ,1
                                                                    ) ||
                                                              to_char(ogim.tipo_aliquota
                                                                     )
                                                             ,'D9', ogim.
                                                                      imposta_erariale_acconto
                                                             ,0
                                                             )
                                                   ,0
                                                   )
                                            )
                                     )
                              )
                       )
                     fabb_d_erar_acc
                   ,sum(decode(ogim.tipo_aliquota
                              ,2, 0
                              ,decode(nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto)
                                     ,1, 0
                                     ,2, 0
                                     ,decode(aliquota_erariale
                                            ,null, 0
                                            ,decode(sign(ogim.anno - 2012)
                                                   ,1, decode(substr(nvl(ogpr.categoria_catasto, ogge.categoria_catasto)
                                                                    ,1
                                                                    ,1
                                                                    ) ||
                                                              to_char(ogim.tipo_aliquota
                                                                     )
                                                             ,'D9', 1
                                                             ,0
                                                             )
                                                   ,0
                                                   )
                                            )
                                     )
                              )
                       )
                     n_fab_fabb_d
                   ,sum(decode(ogim.tipo_aliquota, 2, 0, decode(nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto),  1, 0,  2, 0,  decode(aliquota_erariale, null, 0, ogim.imposta - nvl(ogim.imposta_erariale, 0))))
                       )
                     altri_comu
                   ,sum(decode(ogim.tipo_aliquota, 2, 0, decode(nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto),  1, 0,  2, 0,  decode(aliquota_erariale, null, 0, ogim.imposta_acconto - nvl(ogim.imposta_erariale_acconto, 0))))
                       )
                     altri_comu_acc
                   ,sum(decode(ogim.tipo_aliquota
                              ,2, 0
                              ,decode(nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto)
                                     ,1, 0
                                     ,2, 0
                                     ,decode(aliquota_erariale
                                            ,null, 0
                                            ,decode(sign(ogim.anno - 2012)
                                                   ,1, decode(substr(nvl(ogpr.categoria_catasto, ogge.categoria_catasto)
                                                                    ,1
                                                                    ,1
                                                                    ) ||
                                                              to_char(ogim.tipo_aliquota
                                                                     )
                                                             ,'D9', 0
                                                             ,ogim.
                                                                imposta_erariale
                                                             )
                                                   ,ogim.imposta_erariale
                                                   )
                                            )
                                     )
                              )
                       )
                     altri_erar
                   ,sum(decode(ogim.tipo_aliquota
                              ,2, 0
                              ,decode(nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto)
                                     ,1, 0
                                     ,2, 0
                                     ,decode(aliquota_erariale
                                            ,null, 0
                                            ,decode(sign(ogim.anno - 2012)
                                                   ,1, decode(substr(nvl(ogpr.categoria_catasto, ogge.categoria_catasto)
                                                                    ,1
                                                                    ,1
                                                                    ) ||
                                                              to_char(ogim.tipo_aliquota
                                                                     )
                                                             ,'D9', 0
                                                             ,ogim.
                                                                imposta_erariale_acconto
                                                             )
                                                   ,ogim.imposta_erariale_acconto
                                                   )
                                            )
                                     )
                              )
                       )
                     altri_erar_acc
                   ,sum(decode(ogim.tipo_aliquota
                              ,2, 0
                              ,decode(nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto)
                                     ,1, 0
                                     ,2, 0
                                     ,decode(aliquota_erariale
                                            ,null, 0
                                            ,decode(sign(ogim.anno - 2012)
                                                   ,1, decode(substr(nvl(ogpr.categoria_catasto, ogge.categoria_catasto)
                                                                    ,1
                                                                    ,1
                                                                    ) ||
                                                              to_char(ogim.tipo_aliquota
                                                                     )
                                                             ,'D9', 0
                                                             ,1
                                                             )
                                                   ,1
                                                   )
                                            )
                                     )
                              )
                       )
                     n_fab_altri
                   ,to_number('') vers_ab_princ
                   ,to_number('') vers_ab_princ_acc
                   ,to_number('') vers_detrazione
                   ,to_number('') vers_detrazione_acc
                   ,to_number('') vers_rurali
                   ,to_number('') vers_rurali_acc
                   ,to_number('') vers_altri_comu
                   ,to_number('') vers_altri_comu_acc
                   ,to_number('') vers_altri_erar
                   ,to_number('') vers_altri_erar_acc
                   ,to_number('') vers_terreni_comu
                   ,to_number('') vers_terreni_comu_acc
                   ,to_number('') vers_terreni_erar
                   ,to_number('') vers_terreni_erar_acc
                   ,to_number('') vers_aree_comu
                   ,to_number('') vers_aree_comu_acc
                   ,to_number('') vers_aree_erar
                   ,to_number('') vers_aree_erar_acc
                   ,to_number('') vers_fab_d_comu
                   ,to_number('') vers_fab_d_comu_acc
                   ,to_number('') vers_fab_d_erar
                   ,to_number('') vers_fab_d_erar_acc
               from contribuenti cont
                   ,oggetti_imposta ogim
                   ,oggetti_pratica ogpr
                   ,oggetti ogge
                   ,pratiche_tributo prtr
              where ogim.cod_fiscale = cont.cod_fiscale
                and ogim.anno >= 2012
                and ogim.flag_calcolo = 'S'
                and ogim.oggetto_pratica = ogpr.oggetto_pratica
                and ogpr.oggetto = ogge.oggetto
                and ogpr.pratica = prtr.pratica
                and prtr.tipo_tributo || '' = 'TASI'
                and ((prtr.tipo_pratica in ('D', 'C'))
                  or  (prtr.tipo_pratica = 'A'
                   and ogim.anno > prtr.anno
                   and prtr.flag_denuncia = 'S'))
           group by ogim.cod_fiscale
                   ,ogim.anno
           union all
             select vers.cod_fiscale
                   ,vers.anno
                   ,to_number('') ab_comu
                   ,to_number('') ab_comu_acc
                   ,to_number('') n_fab_ab
                   ,to_number('') detr_comu
                   ,to_number('') detr_comu_acc
                   ,to_number('') rurali_comu
                   ,to_number('') rurali_comu_acc
                   ,to_number('') n_fab_rurali
                   ,to_number('') terreni_comu
                   ,to_number('') terreni_comu_acc
                   ,to_number('') terreni_erar
                   ,to_number('') terreni_erar_acc
                   ,to_number('') n_terreni
                   ,to_number('') aree_comu
                   ,to_number('') aree_comu_acc
                   ,to_number('') aree_erar
                   ,to_number('') aree_erar_acc
                   ,to_number('') n_aree
                   ,to_number('') fabb_d_comu
                   ,to_number('') fabb_d_comu_acc
                   ,to_number('') fabb_d_erar
                   ,to_number('') fabb_d_erar_acc
                   ,to_number('') n_fab_fabb_d
                   ,to_number('') altri_comu
                   ,to_number('') altri_comu_acc
                   ,to_number('') altri_erar
                   ,to_number('') altri_erar_acc
                   ,to_number('') n_fab_altri
                   ,nvl(sum(vers.ab_principale), 0) +
                    f_importo_vers_ravv_dett(vers.cod_fiscale
                                            ,'TASI'
                                            ,vers.anno
                                            ,'U'
                                            ,'ABP'
                                            ,trunc(sysdate)
                                            )
                     vers_ab_principale
                   ,nvl(sum(decode(vers.tipo_versamento, 'A', vers.ab_principale, 0)
                           )
                       ,0
                       ) +
                    f_importo_vers_ravv_dett(vers.cod_fiscale
                                            ,'TASI'
                                            ,vers.anno
                                            ,'A'
                                            ,'ABP'
                                            ,trunc(sysdate)
                                            )
                     vers_ab_principale_acc
                   ,sum(vers.detrazione) vers_detrazione
                   ,sum(decode(vers.tipo_versamento, 'A', vers.detrazione, null))
                     vers_detrazione_acc
                   ,nvl(sum(vers.rurali), 0) +
                    f_importo_vers_ravv_dett(vers.cod_fiscale
                                            ,'TASI'
                                            ,vers.anno
                                            ,'U'
                                            ,'RUR'
                                            ,trunc(sysdate)
                                            )
                     vers_rurali
                   ,nvl(sum(decode(vers.tipo_versamento, 'A', vers.rurali, 0))
                       ,0
                       ) +
                    f_importo_vers_ravv_dett(vers.cod_fiscale
                                            ,'TASI'
                                            ,vers.anno
                                            ,'A'
                                            ,'RUR'
                                            ,trunc(sysdate)
                                            )
                     vers_rurali_acc
                   ,nvl(sum(vers.altri_fabbricati), 0) +
                    f_importo_vers_ravv_dett(vers.cod_fiscale
                                            ,'TASI'
                                            ,vers.anno
                                            ,'U'
                                            ,'ALC'
                                            ,trunc(sysdate)
                                            )
                     vers_altri_comu
                   ,nvl(sum(decode(vers.tipo_versamento, 'A', vers.altri_comune, 0)
                           )
                       ,0
                       ) +
                    f_importo_vers_ravv_dett(vers.cod_fiscale
                                            ,'TASI'
                                            ,vers.anno
                                            ,'A'
                                            ,'ALC'
                                            ,trunc(sysdate)
                                            )
                     vers_altri_comu_acc
                   -- gli importi erariale per la TASI non sono gestiti
                   ,sum(vers.altri_erariale) vers_altri_erar
                   ,sum(decode(vers.tipo_versamento, 'A', vers.altri_erariale, 0)
                       )
                     vers_altri_erar_acc
                   --
                   ,nvl(sum(vers.terreni_comune), 0) +
                    f_importo_vers_ravv_dett(vers.cod_fiscale
                                            ,'TASI'
                                            ,vers.anno
                                            ,'U'
                                            ,'TEC'
                                            ,trunc(sysdate)
                                            )
                     vers_terreni_comu
                   ,nvl(sum(decode(vers.tipo_versamento, 'A', vers.terreni_comune, 0)
                           )
                       ,0
                       ) +
                    f_importo_vers_ravv_dett(vers.cod_fiscale
                                            ,'TASI'
                                            ,vers.anno
                                            ,'A'
                                            ,'TEC'
                                            ,trunc(sysdate)
                                            )
                     vers_terreni_comu_acc
                   -- gli importi erariale per la TASI non sono gestiti
                   ,sum(vers.terreni_erariale) vers_terreni_erar
                   ,sum(decode(vers.tipo_versamento, 'A', vers.terreni_erariale, 0)
                       )
                     vers_terreni_erar_acc
                   --
                   ,nvl(sum(vers.aree_fabbricabili), 0) +
                    f_importo_vers_ravv_dett(vers.cod_fiscale
                                            ,'TASI'
                                            ,vers.anno
                                            ,'U'
                                            ,'ARC'
                                            ,trunc(sysdate)
                                            )
                     vers_aree_comu
                   ,nvl(sum(decode(vers.tipo_versamento, 'A', vers.aree_comune, 0)
                           )
                       ,0
                       ) +
                    f_importo_vers_ravv_dett(vers.cod_fiscale
                                            ,'TASI'
                                            ,vers.anno
                                            ,'A'
                                            ,'ARC'
                                            ,trunc(sysdate)
                                            )
                     vers_aree_comu_acc
                   -- gli importi erariale per la TASI non sono gestiti
                   ,sum(vers.aree_erariale) vers_aree_erar
                   ,sum(decode(vers.tipo_versamento, 'A', vers.aree_erariale, 0))
                     vers_aree_erar_acc
                   --
                   ,nvl(sum(vers.fabbricati_d_comune), 0) +
                    f_importo_vers_ravv_dett(vers.cod_fiscale
                                            ,'TASI'
                                            ,vers.anno
                                            ,'U'
                                            ,'FDC'
                                            ,trunc(sysdate)
                                            )
                     vers_fab_d_comu
                   ,nvl(sum(decode(vers.tipo_versamento, 'A', vers.fabbricati_d_comune, 0)
                           )
                       ,0
                       ) +
                    f_importo_vers_ravv_dett(vers.cod_fiscale
                                            ,'TASI'
                                            ,vers.anno
                                            ,'A'
                                            ,'FDC'
                                            ,trunc(sysdate)
                                            )
                     vers_fab_d_comu_acc
                   -- gli importi erariale per la TASI non sono gestiti
                   ,sum(vers.fabbricati_d_erariale) vers_fab_d_erar
                   ,sum(decode(vers.tipo_versamento, 'A', vers.fabbricati_d_erariale, 0)
                       )
                     vers_fab_d_erar_acc
               --
               from versamenti vers --, pratiche_tributo prtr
              where vers.tipo_tributo || '' = 'TASI'
                and vers.anno >= 2012
           /*AND vers.pratica = prtr.pratica(+)
           AND prtr.tipo_pratica(+) = 'V'*/
           group by vers.cod_fiscale
                   ,vers.anno) dett
    where dett.cod_fiscale = cont.cod_fiscale
      and cont.ni = sogg.ni
 group by dett.cod_fiscale
         ,dett.anno
;
comment on table DETTAGLI_TASI is 'DTSI - Dettagli TASI';

