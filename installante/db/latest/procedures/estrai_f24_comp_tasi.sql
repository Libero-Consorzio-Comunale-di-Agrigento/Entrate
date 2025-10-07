--liquibase formatted sql 
--changeset abrandolini:20250326_152423_estrai_f24_comp_tasi stripComments:false runOnChange:true 
 
create or replace procedure ESTRAI_F24_COMP_TASI
(p_anno           in number
,p_tipo_contatto  in number
,p_saldo_dv       in varchar2
) is
-- 23/10/2014 Nuovo estrazione F24 completa (x S. Lazzaro)
nProgressivo                             number;
errore                                   exception;
sErrore                                  varchar2(2000);
nMesi_aa                                 number;
dDal_aa                                  date;
dAl_aa                                   date;
nMesi_1s                                 number;
dDal_1s                                  date;
dAl_1s                                   date;
dDal_riog_1                              date;
dAl_riog_1                               date;
sCategoria_catasto_riog_1                varchar2(3);
sDes_categoria_catasto_riog_1            varchar2(200);
sClasse_catasto_riog_1                   varchar2(2);
nRendita_riog_1                          number;
nMoltiplicatore_riog_1                   number;
dDal_riog_2                              date;
dAl_riog_2                               date;
sCategoria_catasto_riog_2                varchar2(3);
sDes_categoria_catasto_riog_2            varchar2(200);
sClasse_catasto_riog_2                   varchar2(2);
nRendita_riog_2                          number;
nMoltiplicatore_riog_2                   number;
cursor sel_ogim   (p_anno number,p_tipo_contatto number) is
select cont.cod_fiscale                      cod_fiscale
      ,max(replace(sogg.cognome_nome,'/',' '))
                                             cognome_nome
      ,max(decode(sogg.ni_presso
                 ,null,f_recapito(sogg.ni, prtr.tipo_tributo, 1, trunc(sysdate),'PR')
                      ,replace(sog2.cognome_nome,'/',' ')
                 )
          )                                  presso
      ,max(decode(sogg.ni_presso
                 ,null,nvl(f_recapito(sogg.ni, prtr.tipo_tributo, 1, trunc(sysdate))
                          ,decode(sogg.cod_via
                                 ,null,sogg.denominazione_via
                                      ,arvi.denom_uff
                                 )
                           ||decode(sogg.num_civ,null,null,', '||to_char(sogg.num_civ))
                           ||decode(sogg.suffisso,null,null,'/'||sogg.suffisso)
                           ||decode(sogg.scala,'','',' Sc.'||sogg.scala)
                           ||decode(sogg.interno,'','',' Int.'||sogg.interno)
                          )
                 ,decode(sog2.cod_via
                        ,null,sog2.denominazione_via
                        ,arv2.denom_uff
                        )||
                  decode(sog2.num_civ,null,null,', '||to_char(sog2.num_civ))||
                  decode(sog2.suffisso,null,null,'/'||sog2.suffisso)
                  ||decode(sog2.scala,'','',' Sc.'||sog2.scala)
                  ||decode(sog2.interno,'','',' Int.'||sog2.interno)
                 )
          )                                  indirizzo
      ,max(decode(sogg.ni_presso
                 ,null,nvl(f_recapito(sogg.ni, prtr.tipo_tributo, 1, trunc(sysdate),'CAP')
                          ,nvl(sogg.cap,core.cap))
                      ,nvl(sog2.cap,cor2.cap)
                 )
          )                                  cap
      ,max(decode(sogg.ni_presso
                 ,null,nvl(f_recapito(sogg.ni, prtr.tipo_tributo, 1, trunc(sysdate),'CO')
                          ,core.denominazione)
                      ,cor2.denominazione
                 )
          )                                  comune
      ,max(decode(sogg.ni_presso
                 ,null,nvl(f_recapito(sogg.ni, prtr.tipo_tributo, 1, trunc(sysdate),'SP')
                          ,prre.sigla)
                      ,prr2.sigla
                 )
          )                                  provincia
      ,max(prtr.tipo_tributo)                tipo_tributo
      ,max(ogim.anno)                        anno
      ,max(coen.denominazione)               ente
      ,max(coen.sigla_cfis)                  sigla_cfis
      ,max(titr.conto_corrente)              conto_corrente
      ,max(titr.descrizione_cc)              descrizione_cc
      ,round(sum(ogim.imposta),0)            imposta_totale
      ,sum(decode(decode(ogco.anno
                        ,p_anno,decode(ogco.detrazione
                                      ,null,ogco.flag_ab_principale
                                           ,'S'
                                      )
                               ,ogco.flag_ab_principale
                        )
                 ,'S',decode(substr(f_dato_riog(cont.cod_fiscale
                                               ,ogpr.oggetto_pratica
                                               ,p_anno
                                               ,'CA'
                                               ),1,1
                                   )
                            ,'A',ogim.imposta
                                ,0
                            )
                     ,0
                 )
          )                                  imposta_totale_ap
      ,sum(decode(decode(ogco.anno
                        ,p_anno,decode(ogco.detrazione
                                      ,null,ogco.flag_ab_principale
                                           ,'S'
                                      )
                               ,ogco.flag_ab_principale
                        )
                 ,'S',decode(substr(f_dato_riog(cont.cod_fiscale
                                               ,ogpr.oggetto_pratica
                                               ,p_anno
                                               ,'CA'
                                               ),1,1
                                   )
                            ,'A',0
                                ,ogim.imposta
                            )
                     ,0
                 )
          )                                  imposta_totale_pert
      ,sum(decode(decode(ogco.anno
                        ,p_anno,decode(ogco.detrazione
                                      ,null,ogco.flag_ab_principale
                                           ,'S'
                                      )
                               ,ogco.flag_ab_principale
                        )
                 ,null,decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                             ,1,0
                             ,2,0
                               ,ogim.imposta
                             )
                      ,0
                 )
          )                                  imposta_totale_altri
      ,sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                 ,1,ogim.imposta
                   ,0
                 )
          )                                  imposta_totale_terreni
      ,sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                 ,2,ogim.imposta
                   ,0
                 )
          )                                  imposta_totale_aree
      ,sum(nvl(ogim.detrazione,0))           detrazione_totale
      ,sum(decode(decode(ogco.anno
                        ,p_anno,decode(ogco.detrazione
                                      ,null,ogco.flag_ab_principale
                                           ,'S'
                                      )
                               ,ogco.flag_ab_principale
                        )
                 ,'S',decode(substr(f_dato_riog(cont.cod_fiscale
                                               ,ogpr.oggetto_pratica
                                               ,p_anno
                                               ,'CA'
                                               ),1,1
                                   )
                            ,'A',nvl(ogim.detrazione,0)
                                ,0
                            )
                     ,0
                 )
          )                                  detrazione_totale_ap
      ,sum(decode(decode(ogco.anno
                        ,p_anno,decode(ogco.detrazione
                                      ,null,ogco.flag_ab_principale
                                           ,'S'
                                      )
                               ,ogco.flag_ab_principale
                        )
                 ,'S',decode(substr(f_dato_riog(cont.cod_fiscale
                                               ,ogpr.oggetto_pratica
                                               ,p_anno
                                               ,'CA'
                                               ),1,1
                                   )
                            ,'A',0
                                ,nvl(ogim.detrazione,0)
                            )
                     ,nvl(ogim.detrazione,0)
                 )
          )                                  detrazione_totale_pert
      ,round(sum(nvl(ogim.imposta_acconto,0)),0)      imposta_acconto
      ,sum(decode(decode(ogco.anno
                        ,p_anno,decode(ogco.detrazione
                                      ,null,ogco.flag_ab_principale
                                           ,'S'
                                      )
                               ,ogco.flag_ab_principale
                        )
                 ,'S',decode(substr(f_dato_riog(cont.cod_fiscale
                                               ,ogpr.oggetto_pratica
                                               ,p_anno
                                               ,'CA'
                                               ),1,1
                                   )
                            ,'A',nvl(ogim.imposta_acconto,0)
                                ,0
                            )
                     ,0
                 )
          )                                  imposta_acconto_ap
      ,sum(decode(decode(ogco.anno
                        ,p_anno,decode(ogco.detrazione
                                      ,null,ogco.flag_ab_principale
                                           ,'S'
                                      )
                               ,ogco.flag_ab_principale
                        )
                 ,'S',decode(substr(f_dato_riog(cont.cod_fiscale
                                               ,ogpr.oggetto_pratica
                                               ,p_anno
                                               ,'CA'
                                               ),1,1
                                   )
                            ,'A',0
                                ,nvl(ogim.imposta_acconto,0)
                            )
                     ,0
                 )
          )                                  imposta_acconto_pert
/*      ,sum(decode(ogim.tipo_aliquota
                 ,2, 0
                 ,decode(nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto)
                        ,1, 0
                        ,2, 0
                        ,decode(aliquota_erariale
                               ,null, 0
                               ,decode(sign(ogim.anno - 2012)
                                      ,1, decode(   substr(nvl(ogpr.categoria_catasto,ogge.categoria_catasto)
                                                          ,1
                                                          ,1)
                                                 || to_char(ogim.tipo_aliquota)
                                                ,'D9',   ogim.imposta_acconto
                                                ,0)
                                      ,0)))))
        imposta_acconto_fabb_d
       ,sum(decode(ogim.tipo_aliquota
                  ,2, 0
                  ,decode(nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto)
                         ,1, 0
                         ,2, 0
                         ,decode(aliquota_erariale
                                ,null, 0
                                ,decode(sign(ogim.anno - 2012)
                                       ,1, decode(   substr(nvl(ogpr.categoria_catasto,ogge.categoria_catasto)
                                                           ,1
                                                           ,1)
                                                  || to_char(ogim.tipo_aliquota)
                                                 ,'D9', 0
                                                 ,  ogim.imposta_acconto
                                       ,  ogim.imposta_acconto)
                                       )))))*/
      ,sum(decode(decode(ogco.anno
                        ,p_anno,decode(ogco.detrazione
                                      ,null,ogco.flag_ab_principale
                                           ,'S'
                                      )
                               ,ogco.flag_ab_principale
                        )
                 ,null,decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                             ,1,0
                             ,2,0
                               ,nvl(ogim.imposta_acconto,0)
                             )
                      ,0
                 )
          )
                                            imposta_acconto_altri
      ,sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                 ,1,nvl(ogim.imposta_acconto,0)
                   ,0
                 )
          )                                  imposta_acconto_terreni
      ,sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                 ,2,nvl(ogim.imposta_acconto,0)
                   ,0
                 )
          )                                  imposta_acconto_aree
      ,sum(nvl(ogim.detrazione_acconto,0))   detrazione_acconto
      ,sum(decode(decode(ogco.anno
                        ,p_anno,decode(ogco.detrazione
                                      ,null,ogco.flag_ab_principale
                                           ,'S'
                                      )
                               ,ogco.flag_ab_principale
                        )
                 ,'S',decode(substr(f_dato_riog(cont.cod_fiscale
                                               ,ogpr.oggetto_pratica
                                               ,p_anno
                                               ,'CA'
                                               ),1,1
                                   )
                            ,'A',nvl(ogim.detrazione_acconto,0)
                                ,0
                            )
                     ,0
                 )
          )                                  detrazione_acconto_ap
      ,sum(decode(decode(ogco.anno
                        ,p_anno,decode(ogco.detrazione
                                      ,null,ogco.flag_ab_principale
                                           ,'S'
                                      )
                               ,ogco.flag_ab_principale
                        )
                 ,'S',decode(substr(f_dato_riog(cont.cod_fiscale
                                               ,ogpr.oggetto_pratica
                                               ,p_anno
                                               ,'CA'
                                               ),1,1
                                   )
                            ,'A',0
                                ,nvl(ogim.detrazione_acconto,0)
                            )
                     ,nvl(ogim.detrazione_acconto,0)
                 )
          )                                  detrazione_acconto_pert
    --  ,sum(ogim.imposta - nvl(ogim.imposta_acconto,0))
      ,round(sum(ogim.imposta),0) - round(sum(nvl(ogim.imposta_acconto,0)),0)
                                             imposta_saldo
      ,sum(decode(decode(ogco.anno
                        ,p_anno,decode(ogco.detrazione
                                      ,null,ogco.flag_ab_principale
                                           ,'S'
                                      )
                               ,ogco.flag_ab_principale
                        )
                 ,'S',decode(substr(f_dato_riog(cont.cod_fiscale
                                               ,ogpr.oggetto_pratica
                                               ,p_anno
                                               ,'CA'
                                               ),1,1
                                   )
                            ,'A',ogim.imposta - nvl(ogim.imposta_acconto,0)
                                ,0
                            )
                     ,0
                 )
          )                                  imposta_saldo_ap
      ,sum(decode(decode(ogco.anno
                        ,p_anno,decode(ogco.detrazione
                                      ,null,ogco.flag_ab_principale
                                           ,'S'
                                      )
                               ,ogco.flag_ab_principale
                        )
                 ,'S',decode(substr(f_dato_riog(cont.cod_fiscale
                                               ,ogpr.oggetto_pratica
                                               ,p_anno
                                               ,'CA'
                                               ),1,1
                                   )
                            ,'A',0
                                ,ogim.imposta - nvl(ogim.imposta_acconto,0)
                            )
                     ,0
                 )
          )                                  imposta_saldo_pert
/*      ,sum(decode(ogim.tipo_aliquota
                 ,2, 0
                 ,decode(nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto)
                        ,1, 0
                        ,2, 0
                        ,decode(aliquota_erariale
                               ,null, 0
                               ,decode(sign(ogim.anno - 2012)
                                      ,1, decode(   substr(nvl(ogpr.categoria_catasto,ogge.categoria_catasto)
                                                          ,1
                                                          ,1)
                                                 || to_char(ogim.tipo_aliquota)
                                                ,'D9',   ogim.imposta
                                                       - nvl(ogim.imposta_acconto
                                                            ,0)
                                                ,0)
                                      ,0))))) imposta_saldo_fabb_d
    ,sum(decode(ogim.tipo_aliquota
               ,2, 0
               ,decode(nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto)
                      ,1, 0
                      ,2, 0
                      ,decode(aliquota_erariale
                             ,null, 0
                             ,decode(sign(ogim.anno - 2012)
                                    ,1, decode(   substr(nvl(ogpr.categoria_catasto,ogge.categoria_catasto)
                                                        ,1
                                                        ,1)
                                               || to_char(ogim.tipo_aliquota)
                                              ,'D9', 0
                                              ,  ogim.imposta
                                               - nvl(ogim.imposta_acconto
                                                    ,0))
                                    ,  ogim.imposta
                                     - nvl(ogim.imposta_acconto, 0))))))*/
      ,sum(decode(decode(ogco.anno
                        ,p_anno,decode(ogco.detrazione
                                      ,null,ogco.flag_ab_principale
                                           ,'S'
                                      )
                               ,ogco.flag_ab_principale
                        )
                 ,null,decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                             ,1,0
                             ,2,0
                               ,ogim.imposta - nvl(ogim.imposta_acconto,0)
                             )
                      ,0
                 )
          )
                                            imposta_saldo_altri
      ,sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                 ,1,ogim.imposta - nvl(ogim.imposta_acconto,0)
                   ,0
                 )
          )                                  imposta_saldo_terreni
      ,sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                 ,2,ogim.imposta - nvl(ogim.imposta_acconto,0)
                   ,0
                 )
          )                                  imposta_saldo_aree
      ,sum(decode(sign(nvl(ogim.detrazione,0) - nvl(ogim.detrazione_acconto,0))
                 ,-1,0
                    ,nvl(ogim.detrazione,0) - nvl(ogim.detrazione_acconto,0)
                 )
          )                                  detrazione_saldo
      ,sum(decode(decode(ogco.anno
                        ,p_anno,decode(ogco.detrazione
                                      ,null,ogco.flag_ab_principale
                                           ,'S'
                                      )
                               ,ogco.flag_ab_principale
                        )
                 ,'S',decode(substr(f_dato_riog(cont.cod_fiscale
                                               ,ogpr.oggetto_pratica
                                               ,p_anno
                                               ,'CA'
                                               ),1,1
                                   )
                            ,'A',decode(sign(nvl(ogim.detrazione,0) - nvl(ogim.detrazione_acconto,0))
                                       ,-1,0
                                          ,nvl(ogim.detrazione,0) - nvl(ogim.detrazione_acconto,0)
                                       )
                                ,0
                            )
                     ,0
                 )
          )                                  detrazione_saldo_ap
      ,sum(decode(decode(ogco.anno
                        ,p_anno,decode(ogco.detrazione
                                      ,null,ogco.flag_ab_principale
                                           ,'S'
                                      )
                               ,ogco.flag_ab_principale
                        )
                 ,'S',decode(substr(f_dato_riog(cont.cod_fiscale
                                               ,ogpr.oggetto_pratica
                                               ,p_anno
                                               ,'CA'
                                               ),1,1
                                   )
                            ,'A',0
                                ,decode(sign(nvl(ogim.detrazione,0) - nvl(ogim.detrazione_acconto,0))
                                       ,-1,0
                                          ,nvl(ogim.detrazione,0) - nvl(ogim.detrazione_acconto,0)
                                       )
                            )
                     ,decode(sign(nvl(ogim.detrazione,0) - nvl(ogim.detrazione_acconto,0))
                            ,-1,0
                               ,nvl(ogim.detrazione,0) - nvl(ogim.detrazione_acconto,0)
                            )
                 )
          )                                  detrazione_saldo_pert
      ,sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                 ,1,0
                 ,2,0
                   ,1
                 )
          )                                  numero_fabbricati
      ,'NO'                                  ravvedimento
      ,max(ogim.num_bollettino)              num_bollettino
      ,max(scaa.data_scadenza)               scadenza_acconto
      ,max(scas.data_scadenza)               scadenza_saldo
      ,sum(nvl(ogim.detrazione_imponibile,0))                   detrazione_imponibile_tot
      ,sum(nvl(ogim.detrazione_imponibile_acconto,0))           detrazione_imponibile_acc_tot
      ,sum(decode(sign(nvl(ogim.detrazione_imponibile,0) - nvl(ogim.detrazione_imponibile_acconto,0))
                 ,-1,0
                    ,nvl(ogim.detrazione_imponibile,0) - nvl(ogim.detrazione_imponibile_acconto,0)
                 )
          )                                                     detrazione_imponibile_sal_tot
    -- SEZIONE IMU/TASI --
      ,sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
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
      ,sum(decode(ogim.tipo_aliquota
                 ,2, 0
                 ,decode(nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto)
                        ,1, 0
                        ,2, 0
                        ,decode(aliquota_erariale
                               ,null, 0
                               ,decode(sign(ogim.anno - 2012)
                                      ,1, decode(   substr(nvl(ogpr.categoria_catasto,ogge.categoria_catasto)
                                                          ,1
                                                          ,1)
                                                 || to_char(ogim.tipo_aliquota)
                                                ,'D9',   ogim.imposta
                                                ,0)
                                      ,0))))) tot_fabb_d
              ,sum(decode(ogim.tipo_aliquota
                         ,2, 0
                         ,decode(nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto)
                                ,1, 0
                                ,2, 0
                                ,decode(aliquota_erariale
                                       ,null, 0
                                       ,decode(sign(ogim.anno - 2012)
                                              ,1, decode(   substr(nvl(ogpr.categoria_catasto,ogge.categoria_catasto)
                                                                  ,1
                                                                  ,1)
                                                         || to_char(ogim.tipo_aliquota)
                                                        ,'D9', 0
                                                        ,  ogim.imposta)
                                              ,  ogim.imposta)))))
--     , sum(decode(ogim.tipo_aliquota
--                 ,2,0
--                 ,decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
--                        ,1,0
--                        ,2,0
--                        ,decode(aliquota_erariale
--                               ,null,0
--                               ,ogim.imposta
--                               )
--                        )
--                 )
--          )
                                                                     tot_altri
      ,sum(decode(ogim.tipo_aliquota
                 ,2, 0
                 ,decode(nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto)
                        ,1, 0
                        ,2, 0
                        ,decode(aliquota_erariale
                               ,null, 0
                               ,decode(sign(ogim.anno - 2012)
                                      ,1, decode(   substr(nvl(ogpr.categoria_catasto,ogge.categoria_catasto)
                                                          ,1
                                                          ,1)
                                                 || to_char(ogim.tipo_aliquota)
                                                ,'D9',   ogim.imposta_acconto
                                                ,0)
                                      ,0)))))
        acconto_fabb_d
              ,sum(decode(ogim.tipo_aliquota
                         ,2, 0
                         ,decode(nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto)
                                ,1, 0
                                ,2, 0
                                ,decode(aliquota_erariale
                                       ,null, 0
                                       ,decode(sign(ogim.anno - 2012)
                                              ,1, decode(   substr(nvl(ogpr.categoria_catasto,ogge.categoria_catasto)
                                                                  ,1
                                                                  ,1)
                                                         || to_char(ogim.tipo_aliquota)
                                                        ,'D9', 0
                                                        ,  ogim.imposta_acconto
                                                         - nvl(ogim.imposta_erariale_acconto
                                                              ,0))
                                              ,  ogim.imposta_acconto
                                                    )))))
--     , sum(decode(ogim.tipo_aliquota
--                 ,2,0
--                 ,decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
--                        ,1,0
--                        ,2,0
--                        ,decode(aliquota_erariale
--                               ,null,0
--                               ,ogim.imposta_acconto
--                               )
--                        )
--                 )
--          )
                                                                               acconto_altri
      ,sum(decode(ogim.tipo_aliquota
                 ,2, 0
                 ,decode(nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto)
                        ,1, 0
                        ,2, 0
                        ,decode(aliquota_erariale
                               ,null, 0
                               ,decode(sign(ogim.anno - 2012)
                                      ,1, decode(   substr(nvl(ogpr.categoria_catasto,ogge.categoria_catasto)
                                                          ,1
                                                          ,1)
                                                 || to_char(ogim.tipo_aliquota)
                                                ,'D9', ogim.imposta_erariale
                                                ,0)
                                      ,0)))))
        tot_fabb_d_erar
--     , sum(decode(ogim.tipo_aliquota
--                 ,2,0
--                 ,decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
--                        ,1,0
--                        ,2,0
--                        ,decode(aliquota_erariale
--                               ,null,0
--                               ,ogim.imposta_erariale
--                               )
--                        )
--                 )
--          )
      ,sum(decode(ogim.tipo_aliquota
                 ,2, 0
                 ,decode(nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto)
                        ,1, 0
                        ,2, 0
                        ,decode(aliquota_erariale
                               ,null, 0
                               ,decode(sign(ogim.anno - 2012)
                                      ,1, decode(   substr(nvl(ogpr.categoria_catasto,ogge.categoria_catasto)
                                                          ,1
                                                          ,1)
                                                 || to_char(ogim.tipo_aliquota)
                                                ,'D9', 0
                                                ,ogim.imposta_erariale)
                                      ,ogim.imposta_erariale)))))
                                                                               tot_altri_erar
              ,sum(decode(ogim.tipo_aliquota
                         ,2, 0
                         ,decode(nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto)
                                ,1, 0
                                ,2, 0
                                ,decode(aliquota_erariale
                                       ,null, 0
                                       ,decode(sign(ogim.anno - 2012)
                                              ,1, decode(   substr(nvl(ogpr.categoria_catasto,ogge.categoria_catasto)
                                                                  ,1
                                                                  ,1)
                                                         || to_char(ogim.tipo_aliquota)
                                                        ,'D9', ogim.imposta_erariale_acconto
                                                        ,0)
                                              ,0)))))
                acconto_fabb_d_erar
--     , sum(decode(ogim.tipo_aliquota
--                 ,2,0
--                 ,decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
--                        ,1,0
--                        ,2,0
--                        ,decode(aliquota_erariale
--                               ,null,0
--                               ,ogim.imposta_erariale_acconto
--                               )
--                        )
--                 )
--          )
      ,sum(decode(ogim.tipo_aliquota
                 ,2, 0
                 ,decode(nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto)
                        ,1, 0
                        ,2, 0
                        ,decode(aliquota_erariale
                               ,null, 0
                               ,decode(sign(ogim.anno - 2012)
                                      ,1, decode(   substr(nvl(ogpr.categoria_catasto,ogge.categoria_catasto)
                                                          ,1
                                                          ,1)
                                                 || to_char(ogim.tipo_aliquota)
                                                ,'D9', 0
                                                ,ogim.imposta_erariale_acconto)
                                      ,ogim.imposta_erariale_acconto)))))
                                                                     acconto_altri_erar
              ,sum(decode(ogim.tipo_aliquota
                         ,2, 0
                         ,decode(nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto)
                                ,1, 0
                                ,2, 0
                                ,decode(aliquota_erariale
                                       ,null, 0
                                       ,decode(sign(ogim.anno - 2012)
                                              ,1, decode(   substr(nvl(ogpr.categoria_catasto,ogge.categoria_catasto)
                                                                  ,1
                                                                  ,1)
                                                         || to_char(ogim.tipo_aliquota)
                                                        ,'D9', 1
                                                        ,0)
                                              ,0)))))
                num_fabb_fabb_d
--      , sum(decode(ogim.tipo_aliquota
--                 ,2,0
--                 ,decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
--                        ,1,0
--                        ,2,0
--                        ,decode(aliquota_erariale
--                               ,null,0
--                                ,1
--                               )
--                        )
--                 )
--          )
      ,sum(decode(ogim.tipo_aliquota
                 ,2, 0
                 ,decode(nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto)
                        ,1, 0
                        ,2, 0
                        ,decode(aliquota_erariale
                               ,null, 0
                               ,decode(sign(ogim.anno - 2012)
                                      ,1, decode(   substr(nvl(ogpr.categoria_catasto,ogge.categoria_catasto)
                                                          ,1
                                                          ,1)
                                                 || to_char(ogim.tipo_aliquota)
                                                ,'D9', 0
                                                ,1)
                                      ,1)))))
                                                             num_fabb_altri
          -- SEZIONE TASI GIA VFERSATO--
     , max(vers.vers_tot_ab_principale)      vers_tot_ab_principale
     , max(vers.vers_num_fabbricati_ab)      vers_num_fabbricati_ab
     , max(vers.vers_detrazione)             vers_detrazione
     , max(vers.versato_tot_rurali)          versato_tot_rurali
     , max(vers.vers_num_fabbricati_rurali)  vers_num_fabbricati_rurali
     , max(vers.vers_tot_terreni_agricoli)   vers_tot_terreni_agricoli
     , max(vers.vers_terreni_erariale)       vers_terreni_erariale
     , max(vers.vers_terreni_comune)         vers_terreni_comune
     , max(vers.vers_num_fabbricati_terreni) vers_num_fabbricati_terreni
     , max(vers.vers_tot_aree_fabbricabili)  vers_tot_aree_fabbricabili
     , max(vers.vers_aree_erariale)          vers_aree_erariale
     , max(vers.vers_aree_comune)            vers_aree_comune
     , max(vers.vers_num_fabbricati_aree)    vers_num_fabbricati_aree
     , max(vers.vers_tot_altri_fabbricati)   vers_tot_altri_fabbricati
     , max(vers.vers_altri_erariale)         vers_altri_erariale
     , max(vers.vers_altri_comune)           vers_altri_comune
     , max(vers.vers_num_fabbricati_altri)   vers_num_fabbricati_altri
     , max(vers.vers_tot_fabbricati_d)       vers_tot_fabbricati_d
     , max(vers.vers_fabbricati_d_comune)    vers_fabbricati_d_comune
     , max(vers.vers_fabbricati_d_erariale)  vers_fabbricati_d_erariale
     , max(vers.vers_num_fabbricati_d)       vers_num_fabbricati_d
     , max(sogg.cognome)                                                        cognome
     , max(sogg.nome)                                                           nome
     , max(to_char(sogg.data_nas,'ddmmyyyy'))                                   data_nascita
     , max(sogg.sesso)                                                          sesso
     , max(cona.denominazione)                                                  comune_nas
     , max(prna.sigla)                                                          sigla_provincia_nas
-- campi aggiunti x TASI S. Lazzaro
     , sum(ogim.imposta)                                   imp_tot_no_Arr
     , max(vers.vers_tot)                                  vers_tot
     , sum(ogim.imposta) - nvl(max(vers.vers_tot),0)       differenza_dovuto_vers
     , round(nvl(sum(ogim.imposta),0) - decode(p_saldo_dv,'D',round(sum(nvl(ogim.imposta_acconto,0)),0)
                                                             ,nvl(max(vers.vers_tot),0)),0)   dovuto_a_saldo
     , (round(sum(ogim.imposta),0)) - sum(ogim.imposta)    arrotondamento
     , (round(nvl(sum(ogim.imposta),0) - decode(p_saldo_dv,'D',round(sum(nvl(ogim.imposta_acconto,0)),0)
                                                              ,nvl(max(vers.vers_tot),0)),0))
      - (sum(ogim.imposta) - decode(p_saldo_dv,'D',sum(nvl(ogim.imposta_acconto,0))
                                                  ,nvl(max(vers.vers_tot),0)))          diff_arrotondamento
  from dati_generali                         dage
      ,ad4_comuni                            coen
      ,ad4_provincie                         prre
      ,ad4_comuni                            core
      ,archivio_vie                          arvi
      ,soggetti                              sogg
      ,ad4_provincie                         prr2
      ,ad4_comuni                            cor2
      ,archivio_vie                          arv2
      ,soggetti                              sog2
      ,contribuenti                          cont
      ,oggetti                               ogge
      ,pratiche_tributo                      prtr
      ,oggetti_pratica                       ogpr
      ,oggetti_contribuente                  ogco
      ,tipi_tributo                          titr
      ,scadenze                              scaa
      ,scadenze                              scas
      ,oggetti_imposta                       ogim
      ,ad4_provincie                         prna
      ,ad4_comuni                            cona
      ,(select vers.anno                       vers_anno,
               cod_fiscale                     vers_cod_fiscale,
               sum(ab_principale)              vers_tot_ab_principale,
               sum(num_fabbricati_ab)          vers_num_fabbricati_ab,
               sum(detrazione)                 vers_detrazione,
               sum(rurali)                     versato_tot_rurali,
               sum(num_fabbricati_rurali)      vers_num_fabbricati_rurali,
               sum(terreni_agricoli)           vers_tot_terreni_agricoli,
               sum(terreni_erariale)           vers_terreni_erariale,
               sum(terreni_comune)             vers_terreni_comune,
               sum(num_fabbricati_terreni)     vers_num_fabbricati_terreni,
               sum(aree_fabbricabili)          vers_tot_aree_fabbricabili,
               sum(aree_erariale)              vers_aree_erariale,
               sum(aree_comune)                vers_aree_comune,
               sum(num_fabbricati_aree)        vers_num_fabbricati_aree,
               sum(altri_fabbricati)           vers_tot_altri_fabbricati,
               sum(altri_erariale)             vers_altri_erariale,
               sum(altri_comune)               vers_altri_comune  ,
               sum(num_fabbricati_altri)       vers_num_fabbricati_altri,
               sum(vers.fabbricati_d)          vers_tot_fabbricati_d,
               sum(vers.fabbricati_d_comune)   vers_fabbricati_d_comune,
               sum(vers.fabbricati_d_erariale) vers_fabbricati_d_erariale,
               sum(vers.num_fabbricati_d)      vers_num_fabbricati_d,
               sum(vers.importo_versato)       vers_tot
          from VERSAMENTI vers
         where tipo_tributo||''='TASI'
           and pratica is null
         group by cod_fiscale, anno )          VERS
 where coen.provincia_stato              (+)    = dage.pro_cliente
   and coen.comune                       (+)    = dage.com_cliente
   and prre.provincia                    (+)    = sogg.cod_pro_res
   and core.provincia_stato              (+)    = sogg.cod_pro_res
   and core.comune                       (+)    = sogg.cod_com_res
   and arvi.cod_via                      (+)    = sogg.cod_via
   and prna.provincia                    (+)    = sogg.cod_pro_nas
   and cona.provincia_stato              (+)    = sogg.cod_pro_nas
   and cona.comune                       (+)    = sogg.cod_com_nas
   and prr2.provincia                    (+)    = sog2.cod_pro_res
   and cor2.provincia_stato              (+)    = sog2.cod_pro_res
   and cor2.comune                       (+)    = sog2.cod_com_res
   and arv2.cod_via                      (+)    = sog2.cod_via
   and sog2.ni                           (+)    = sogg.ni_presso
   and sogg.ni                                  = cont.ni
   and scaa.tipo_tributo                 (+)    = titr.tipo_tributo
   and scaa.anno                         (+)    = p_anno
   and scaa.tipo_scadenza                (+)    = 'V'
   and scaa.tipo_versamento              (+)    = 'A'
   and scas.tipo_tributo                 (+)    = titr.tipo_tributo
   and scas.anno                         (+)    = p_anno
   and scas.tipo_scadenza                (+)    = 'V'
   and scas.tipo_versamento              (+)    = 'S'
   and cont.cod_fiscale                         = ogim.cod_fiscale
   and ogge.oggetto                             = ogpr.oggetto
   and ogpr.oggetto_pratica                     = ogim.oggetto_pratica
   and prtr.pratica                             = ogpr.pratica
   and titr.tipo_tributo                        = prtr.tipo_tributo
   and ogco.cod_fiscale                         = ogim.cod_fiscale
   and ogco.oggetto_pratica                     = ogim.oggetto_pratica
   and prtr.tipo_tributo||''                    = 'TASI'
   and ogim.anno                                = p_anno
--   and ogim.num_bollettino                     is not null
   and ogim.flag_calcolo                        = 'S'
   and vers.vers_cod_Fiscale (+)                =  cont.cod_fiscale
   and vers.vers_anno (+)                       =  p_anno
   and exists
      (select 1
         from contatti_contribuente          coco
        where coco.cod_fiscale                  = ogim.cod_fiscale
--          and nvl(coco.anno,0)                 in (ogim.anno,0)
          and ((coco.tipo_contatto = 4
               and coco.tipo_tributo                 = 'TASI')
              or coco.tipo_contatto != 4)
          and coco.tipo_contatto                = p_tipo_contatto
      )
 group by
       cont.cod_fiscale
-- having sum(ogim.imposta)                        > 0
;
cursor sel_ogim_cf (p_anno number,p_tipo_contatto number,p_cod_fiscale varchar2) is
select cont.cod_fiscale                      cod_fiscale
      ,prtr.anno                             anno
      ,ogge.oggetto                          oggetto
      ,ogpr.tipo_oggetto                     tipo_oggetto
      ,ogge.zona                             zona
      ,ogge.sezione                          sezione
      ,ogge.foglio                           foglio
      ,ogge.numero                           numero
      ,ogge.subalterno                       subalterno
      ,ogge.partita                          partita
      ,ogge.progr_partita                    progr_partita
      ,ogge.anno_catasto                     anno_catasto
      ,ogge.protocollo_catasto               protocollo_catasto
      ,decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
             ,3,decode(nvl(ogpr.imm_storico,'N')||to_char(sign(2012 - p_anno))
                      ,'S1',100
                      ,nvl(molt.moltiplicatore,1)
                      )
             ,55,decode(nvl(ogpr.imm_storico,'N')||to_char(sign(2012 - p_anno))
                      ,'S1',100
                      ,nvl(molt.moltiplicatore,1)
                      )
             ,nvl(molt.moltiplicatore,1)
             )                               moltiplicatore
      ,nvl(rire.aliquota,0)                  rivalutazione
      ,f_dato_riog(p_cod_fiscale
                  ,ogpr.oggetto_pratica
                  ,p_anno
                  ,'CA'
                  )                          categoria_catasto
      ,caca.descrizione                      des_categoria_catasto
      ,f_dato_riog(p_cod_fiscale
                  ,ogpr.oggetto_pratica
                  ,p_anno
                  ,'CL'
                  )                          classe_catasto
      ,f_dato_riog(p_cod_fiscale
                  ,ogpr.oggetto_pratica
                  ,p_anno
                  ,'PT'
                  )                          periodo
      ,f_dato_riog(p_cod_fiscale
                  ,ogpr.oggetto_pratica
                  ,p_anno
                  ,'PA'
                  )                          periodo_1s
      ,decode(ogco.anno
             ,ogim.anno,nvl(ogco.mesi_possesso,0)
                       ,nvl(ogco.mesi_possesso,12)
             )                               mesi_possesso
      ,ogco.perc_possesso                    perc_possesso
      ,decode(ogpr.imm_storico,'S','SI','NO')
                                             imm_storico
      ,round(f_valore(ogpr.valore,nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                     ,ogco.anno
                     ,p_anno
                     ,nvl(ogpr.categoria_catasto,ogge.categoria_catasto)
                     ,prtr.tipo_pratica
                     ,ogpr.flag_valore_rivalutato
                     )
            ,2
            )                                valore
      ,decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
             ,4,to_number(null)
               ,round((f_valore(ogpr.valore,nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                               ,ogco.anno
                               ,p_anno
                               ,nvl(ogpr.categoria_catasto,ogge.categoria_catasto)
                               ,prtr.tipo_pratica
                               ,ogpr.flag_valore_rivalutato
                               )  * 100
                     ) / (decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                ,3,decode(nvl(ogpr.imm_storico,'N')||to_char(sign(2012 - p_anno))
                                         ,'S1',100
                                         ,nvl(molt.moltiplicatore,1)
                                         )
                                ,55,decode(nvl(ogpr.imm_storico,'N')||to_char(sign(2012 - p_anno))
                                         ,'S1',100
                                         ,nvl(molt.moltiplicatore,1)
                                         )
                                ,nvl(molt.moltiplicatore,1)
                                )
                            * (100 + nvl(rire.aliquota,0))
                          ),2
                     )
             )                               rendita
      ,ogim.imposta                          imposta_totale
      ,nvl(ogim.detrazione,0)                detrazione_totale
      ,nvl(ogim.imposta_acconto,0)           imposta_acconto
      ,nvl(ogim.detrazione_acconto,0)        detrazione_acconto
      ,ogim.imposta - nvl(ogim.imposta_acconto,0)
                                             imposta_saldo
      ,decode(sign(nvl(ogim.detrazione,0) - nvl(ogim.detrazione_acconto,0))
                  ,-1,0
                     ,nvl(ogim.detrazione,0) - nvl(ogim.detrazione_acconto,0)
             )                               detrazione_saldo
      ,ogim.tipo_aliquota                    tipo_aliquota
      ,ogim.aliquota                         aliquota
      ,ogim.num_bollettino                   num_bollettino
      ,decode(ogge.cod_via,null,ogge.indirizzo_localita,arvi.denom_uff)||
       decode(ogge.num_civ,null,null,', '||to_char(ogge.num_civ))||
       decode(ogge.suffisso,null,null,'/'||ogge.suffisso)
                                             indirizzo
      , nvl(ogim.detrazione_imponibile,0)                detrazione_imponibile
      , nvl(ogim.detrazione_imponibile_acconto,0)        detrazione_imponibile_acconto
      , decode(sign(nvl(ogim.detrazione_imponibile,0) - nvl(ogim.detrazione_imponibile_acconto,0))
                  , -1, 0
                  , nvl(ogim.detrazione_imponibile,0) - nvl(ogim.detrazione_imponibile_acconto,0)
              )                                          detrazione_imponibile_saldo
  from archivio_vie                          arvi
      ,contribuenti                          cont
      ,oggetti                               ogge
      ,pratiche_tributo                      prtr
      ,oggetti_pratica                       ogpr
      ,oggetti_contribuente                  ogco
      ,tipi_tributo                          titr
      ,categorie_catasto                     caca
      ,moltiplicatori                        molt
      ,rivalutazioni_rendita                 rire
      ,oggetti_imposta                       ogim
 where arvi.cod_via                      (+)    = ogge.cod_via
   and cont.cod_fiscale                         = ogim.cod_fiscale
   and ogge.oggetto                             = ogpr.oggetto
   and ogpr.oggetto_pratica                     = ogim.oggetto_pratica
   and prtr.pratica                             = ogpr.pratica
   and titr.tipo_tributo                        = prtr.tipo_tributo
   and caca.categoria_catasto            (+)    = f_dato_riog(p_cod_fiscale
                                                             ,ogpr.oggetto_pratica
                                                             ,p_anno
                                                             ,'CA'
                                                             )
   and molt.anno                         (+)    = p_anno
   and molt.categoria_catasto            (+)    = f_dato_riog(p_cod_fiscale
                                                             ,ogpr.oggetto_pratica
                                                             ,p_anno
                                                             ,'CA'
                                                             )
   and rire.anno                         (+)    = p_anno
   and rire.tipo_oggetto                 (+)    = ogpr.tipo_oggetto
   and ogco.cod_fiscale                         = ogim.cod_fiscale
   and ogco.oggetto_pratica                     = ogim.oggetto_pratica
   and prtr.tipo_tributo||''                    = 'TASI'
   and ogim.anno                                = p_anno
--   and ogim.num_bollettino                     is not null
   and exists
      (select 1
         from contatti_contribuente          coco
        where coco.cod_fiscale                  = ogim.cod_fiscale
--          and coco.anno                         = ogim.anno
          and ((coco.tipo_contatto = 4
               and coco.tipo_tributo                 = 'TASI')
              or coco.tipo_contatto != 4)
          and coco.tipo_contatto                = p_tipo_contatto
      )
   and ogim.cod_fiscale                         = p_cod_fiscale
   and ogim.flag_calcolo = 'S'
 order by
       2 desc,3,4
;
cursor sel_riog (p_anno number,p_oggetto number,p_dal date,p_al date) is
select greatest(nvl(riog.inizio_validita,p_dal),p_dal)
                                             dal
      ,least(nvl(riog.fine_validita,p_al),p_al)
                                             al
      ,riog.categoria_catasto                categoria_catasto
      ,caca.descrizione                      des_categoria_catasto
      ,riog.classe_catasto                   classe_catasto
      ,riog.rendita                          rendita
      ,nvl(molt.moltiplicatore,1)            moltiplicatore
  from moltiplicatori                        molt
      ,categorie_catasto                     caca
      ,riferimenti_oggetto                   riog
 where molt.anno                       (+)      = p_anno
   and molt.categoria_catasto          (+)      = riog.categoria_catasto
   and caca.categoria_catasto                   = riog.categoria_catasto
   and nvl(riog.inizio_validita,p_dal)         <= p_al
   and nvl(riog.fine_validita,p_al)            >= p_dal
   and riog.oggetto                             = p_oggetto
 order by
       nvl(riog.inizio_validita,p_dal) desc
;
BEGIN
   sErrore := null;
   BEGIN
      delete from wrk_tras_anci
       where anno = 8
      ;
   END;
   nProgressivo := 0;
   FOR rec_ogim IN sel_ogim(p_anno,p_tipo_contatto)
   LOOP
      nProgressivo := nProgressivo + 1;
      insert into wrk_tras_anci
            (anno,progressivo,dati)
      values(8
            ,nProgressivo
            ,rec_ogim.cod_fiscale||';'||
             '1'||';'||
             rec_ogim.cognome_nome||';'||
             rec_ogim.presso||';'||
             rec_ogim.indirizzo||';'||
             lpad(to_char(rec_ogim.cap),5,'0')||';'||
             rec_ogim.comune||';'||
             rec_ogim.provincia||';'||
             rec_ogim.tipo_tributo||';'||
             to_char(rec_ogim.anno)||';'||
             rec_ogim.ente||';'||
             to_char(rec_ogim.conto_corrente)||';'||
             rec_ogim.descrizione_cc||';'||
             to_char(rec_ogim.imposta_totale * 100)||';'||
             to_char(rec_ogim.imposta_totale_ap * 100)||';'||
             to_char(rec_ogim.imposta_totale_pert * 100)||';'||
             to_char((rec_ogim.imposta_totale_altri + rec_ogim.imposta_totale_pert) * 100)||';'||
             to_char(rec_ogim.imposta_totale_terreni * 100)||';'||
             to_char(rec_ogim.imposta_totale_aree * 100)||';'||
             to_char(rec_ogim.detrazione_totale * 100)||';'||
             to_char(rec_ogim.detrazione_totale_ap * 100)||';'||
             to_char(rec_ogim.detrazione_totale_pert * 100)||';'||
             to_char(rec_ogim.imposta_acconto * 100)||';'||
             to_char(rec_ogim.imposta_acconto_ap * 100)||';'||
             to_char(rec_ogim.imposta_acconto_pert * 100)||';'||
             to_char((rec_ogim.imposta_acconto_altri + rec_ogim.imposta_acconto_pert) * 100)||';'||
             to_char(rec_ogim.imposta_acconto_terreni * 100)||';'||
             to_char(rec_ogim.imposta_acconto_aree * 100)||';'||
             to_char(rec_ogim.detrazione_acconto * 100)||';'||
             to_char(rec_ogim.detrazione_acconto_ap * 100)||';'||
             to_char(rec_ogim.detrazione_acconto_pert * 100)||';'||
             to_char(rec_ogim.imposta_saldo * 100)||';'||
             to_char(rec_ogim.imposta_saldo_ap * 100)||';'||
             to_char(rec_ogim.imposta_saldo_pert * 100)||';'||
             to_char((rec_ogim.imposta_saldo_altri + rec_ogim.imposta_saldo_pert) * 100)||';'||
             to_char(rec_ogim.imposta_saldo_terreni * 100)||';'||
             to_char(rec_ogim.imposta_saldo_aree * 100)||';'||
             to_char(rec_ogim.detrazione_saldo * 100)||';'||
             to_char(rec_ogim.detrazione_saldo_ap * 100)||';'||
             to_char(rec_ogim.detrazione_saldo_pert * 100)||';'||
             to_char(rec_ogim.numero_fabbricati)||';'||
             rec_ogim.ravvedimento||';'||
             to_char(rec_ogim.scadenza_acconto,'ddmmyyyy')||';'||
             to_char(rec_ogim.scadenza_saldo,'ddmmyyyy')||';'||
             to_char(rec_ogim.num_bollettino)||';'||
             to_char(rec_ogim.detrazione_imponibile_tot * 100)||';'||
             to_char(rec_ogim.detrazione_imponibile_acc_tot * 100)||';'||
             to_char(rec_ogim.detrazione_imponibile_sal_tot * 100)||';'||
          -- SEZIONE IMU --
          -- (VD - 14/05/2015): sostituito valore fisso con sigla_cfis da AD4_COMUNI
             rec_ogim.sigla_cfis||';'||
             '3958'||';'||
             to_char(round(rec_ogim.tot_ab,0) * 100)||';'||
             to_char(round(rec_ogim.acconto_ab,0) * 100)||';'||
             to_char(round(rec_ogim.vers_tot_ab_principale,0) * 100)||';'||
             to_char(round(rec_ogim.tot_ab - decode(p_saldo_dv,'D',nvl(rec_ogim.acconto_ab,0)
                                                                  ,nvl(rec_ogim.vers_tot_ab_principale,0)),0) * 100)||';'||
             to_char(rec_ogim.num_fabb_ab)||';'||
             '3959'||';'||
             to_char(round(rec_ogim.tot_rurali,0) * 100)||';'||
             to_char(round(rec_ogim.acconto_rurali,0) * 100)||';'||
             to_char(round(rec_ogim.versato_tot_rurali,0) * 100)||';'||
             to_char(round(rec_ogim.tot_rurali - decode(p_saldo_dv,'D',nvl(rec_ogim.acconto_rurali,0)
                                                                      ,nvl(rec_ogim.versato_tot_rurali,0)),0) * 100)||';'||
             to_char(rec_ogim.num_fabb_rurali)||';'||
             ''||';'||
             to_char(round(rec_ogim.tot_terreni - rec_ogim.tot_terreni_erar,0) * 100)||';'||
             to_char(round(rec_ogim.acconto_terreni - rec_ogim.acconto_terreni_erar,0) * 100)||';'||
             to_char(round(rec_ogim.vers_terreni_comune,0) * 100)||';'||
             to_char(round((rec_ogim.tot_terreni - rec_ogim.tot_terreni_erar)
                            - decode(p_saldo_dv,'D',(nvl(rec_ogim.acconto_terreni,0) + nvl(rec_ogim.acconto_terreni_erar,0))
                                                   ,nvl(rec_ogim.vers_terreni_comune,0)),0) * 100)||';'||
             ''||';'||
             to_char(round(rec_ogim.tot_terreni_erar,0) * 100)||';'||
             to_char(round(rec_ogim.acconto_terreni_erar,0) * 100)||';'||
             to_char(round(rec_ogim.vers_terreni_erariale,0) * 100)||';'||
             to_char(round(rec_ogim.tot_terreni_erar - decode(p_saldo_dv,'D',nvl(rec_ogim.acconto_terreni_erar,0)
                                                                            ,nvl(rec_ogim.vers_terreni_erariale,0)),0) * 100)||';'||
             '3960'||';'||
             to_char(round(rec_ogim.tot_aree - rec_ogim.tot_aree_erar,0) * 100)||';'||
             to_char(round(rec_ogim.acconto_aree - rec_ogim.acconto_aree_erar,0) * 100)||';'||
             to_char(round(rec_ogim.vers_aree_comune,0) * 100)||';'||
             to_char(round((rec_ogim.tot_aree - rec_ogim.tot_aree_erar)
                            - decode(p_saldo_dv,'D',(nvl(rec_ogim.acconto_aree,0) + nvl(rec_ogim.acconto_aree_erar,0))
                                                   ,nvl(rec_ogim.vers_aree_comune,0)),0) * 100)||';'||
              ''||';'||
             to_char(round(rec_ogim.tot_aree_erar,0) * 100)||';'||
             to_char(round(rec_ogim.acconto_aree_erar,0) * 100)||';'||
             to_char(round(rec_ogim.vers_aree_erariale,0) * 100)||';'||
             to_char(round(rec_ogim.tot_aree_erar - decode(p_saldo_dv,'D',nvl(rec_ogim.acconto_aree_erar,0)
                                                                         ,nvl(rec_ogim.vers_aree_erariale,0)),0) * 100)||';'||
             '3961'||';'||
             to_char(round(rec_ogim.tot_altri - rec_ogim.tot_altri_erar,0) * 100)||';'||
             to_char(round(rec_ogim.acconto_altri - rec_ogim.acconto_altri_erar,0) * 100)||';'||
             to_char(round(rec_ogim.vers_altri_comune,0) * 100)||';'||
             to_char(round((rec_ogim.tot_altri - rec_ogim.tot_altri_erar)
                            - decode(p_saldo_dv,'D',(nvl(rec_ogim.acconto_altri,0) + nvl(rec_ogim.acconto_altri_erar,0))
                                                   ,nvl( rec_ogim.vers_altri_comune,0)),0) * 100)||';'||
             to_char(rec_ogim.num_fabb_altri)||';'||
              ''||';'||
             to_char(round(rec_ogim.tot_altri_erar,0) * 100)||';'||
             to_char(round(rec_ogim.acconto_altri_erar,0) * 100)||';'||
             to_char(round(rec_ogim.vers_altri_erariale,0) * 100)||';'||
             to_char(round(rec_ogim.tot_altri_erar - decode(p_saldo_dv,'D',nvl(rec_ogim.acconto_altri_erar,0)
                                                                          ,nvl(rec_ogim.vers_altri_erariale,0)),0) * 100)||';'||
             to_char(rec_ogim.num_fabb_altri)||';'||
             ''||';'||
             to_char(round(rec_ogim.tot_fabb_d - rec_ogim.tot_fabb_d_erar,0) * 100)||';'||
             to_char(round(rec_ogim.acconto_fabb_d - rec_ogim.acconto_fabb_d_erar,0) * 100)||';'||
             to_char(round(rec_ogim.vers_fabbricati_d_comune,0) * 100)||';'||
             to_char(round((rec_ogim.tot_fabb_d - rec_ogim.tot_fabb_d_erar)
                            - decode(p_saldo_dv,'D',(nvl(rec_ogim.acconto_fabb_d,0) + nvl(rec_ogim.acconto_fabb_d_erar,0))
                                                   ,nvl( rec_ogim.vers_fabbricati_d_comune,0)),0) * 100)||';'||
             to_char(rec_ogim.num_fabb_fabb_d)||';'||
              ''||';'||
             to_char(round(rec_ogim.tot_fabb_d_erar,0) * 100)||';'||
             to_char(round(rec_ogim.acconto_fabb_d_erar,0) * 100)||';'||
             to_char(round(rec_ogim.vers_fabbricati_d_erariale,0) * 100)||';'||
             to_char(round(rec_ogim.tot_fabb_d_erar - decode(p_saldo_dv,'D',nvl(rec_ogim.acconto_fabb_d_erar,0)
                                                                           ,nvl(rec_ogim.vers_fabbricati_d_erariale,0)),0) * 100)||';'||
             to_char(rec_ogim.num_fabb_fabb_d)||';'||
              ''||';'||
             decode(sign(nvl(rec_ogim.tot_ab,0))
                   ,1,to_char(rec_ogim.tot_detrazione * 100)
                   ,''
                   )||';'||
             decode(sign(nvl(rec_ogim.acconto_ab,0))
                   ,1,to_char(rec_ogim.acconto_detrazione * 100)
                   ,''
                   )||';'||
             decode(sign(nvl(rec_ogim.acconto_ab,0))
                   ,1,to_char(rec_ogim.vers_detrazione * 100)
                   ,''
                   )||';'||
--??             decode(sign(nvl(rec_ogim.tot_ab,0) - nvl(rec_ogim.vers_detrazione,0))
             decode(sign(nvl(rec_ogim.tot_detrazione,0) - decode(p_saldo_dv,'D',nvl(rec_ogim.acconto_detrazione,0)
                                                                               ,nvl(rec_ogim.vers_detrazione,0)))
                   ,1,to_char((rec_ogim.tot_detrazione - decode(p_saldo_dv,'D',nvl(rec_ogim.acconto_detrazione,0)
                                                                              ,nvl(rec_ogim.vers_detrazione,0))) * 100)
                   ,''
                   )||';'||
             -- SEZIONE IMU gia versato--
             to_char(round(rec_ogim.VERS_TOT_AB_PRINCIPALE,0) * 100)||';'||
             to_char(rec_ogim.VERS_NUM_FABBRICATI_AB)||';'||
             to_char(round(rec_ogim.VERS_DETRAZIONE,0) * 100)||';'||
             to_char(round(rec_ogim.VERSATO_TOT_RURALI,0) * 100)||';'||
             to_char(rec_ogim.VERS_NUM_FABBRICATI_RURALI)||';'||
             to_char(round(rec_ogim.VERS_TOT_TERRENI_AGRICOLI,0) * 100)||';'||
             to_char(round(rec_ogim.VERS_TERRENI_ERARIALE,0) * 100)||';'||
             to_char(round(rec_ogim.VERS_TERRENI_COMUNE,0) * 100)||';'||
             to_char(rec_ogim.VERS_NUM_FABBRICATI_TERRENI)||';'||
             to_char(round(rec_ogim.VERS_TOT_AREE_FABBRICABILI,0) * 100)||';'||
             to_char(round(rec_ogim.VERS_AREE_ERARIALE,0) * 100)||';'||
             to_char(round(rec_ogim.VERS_AREE_COMUNE,0) * 100)||';'||
             to_char(rec_ogim.VERS_NUM_FABBRICATI_AREE)||';'||
             to_char(round(rec_ogim.VERS_TOT_ALTRI_FABBRICATI,0) * 100)||';'||
             to_char(round(rec_ogim.VERS_ALTRI_ERARIALE,0) * 100)||';'||
             to_char(round(rec_ogim.VERS_ALTRI_COMUNE ,0) * 100)||';'||
             to_char(rec_ogim.VERS_NUM_FABBRICATI_ALTRI) ||';'||
             to_char(round(rec_ogim.VERS_TOT_fabbricati_d,0) * 100)||';'||
             to_char(round(rec_ogim.VERS_fabbricati_d_ERARIALE,0) * 100)||';'||
             to_char(round(rec_ogim.VERS_fabbricati_d_COMUNE ,0) * 100)||';'||
             to_char(rec_ogim.VERS_NUM_FABBRICATI_d) ||';'||
             rec_ogim.cognome||';'||
             rec_ogim.nome||';'||
             rec_ogim.data_nascita||';'||
             rec_ogim.sesso||';'||
             rec_ogim.comune_nas||';'||
             rec_ogim.sigla_provincia_nas||';'||
             rec_ogim.imp_tot_no_arr * 100||';'||
             rec_ogim.vers_tot * 100||';'||
             rec_ogim.differenza_dovuto_vers * 100||';'||
             rec_ogim.dovuto_a_saldo * 100||';'||
             rec_ogim.arrotondamento * 100||';'||
             rec_ogim.diff_arrotondamento * 100
            )
      ;
--      Elenco dei nuovi campi inseriti della sezione IMU  --
--
--      Codice Ente
--      Codice Tributo Abitazione Principale
--      Unico Abitazione Principale
--      Acconto Abitazione Principale
--      Saldo Abitazione Principale
--      Numero Immobili Abitazione Principale
--      Codice Tributo Fabbricati Rurali ad Uso Strumentale
--      Unico Fabbricati Rurali ad Uso Strumentale
--      Acconto Fabbricati Rurali ad Uso Strumentale
--      Saldo Fabbricati Rurali ad Uso Strumentale
--      Numero Immobili Fabbricati Rurali ad Uso Strumentale
--      Codice Tributo Terreni Comune
--      Unico Terreni Comune
--      Acconto Terreni Comune
--      Saldo Terreni Comune
--      Codice Tributo Terreni Stato
--      Unico Terreni Stato
--      Acconto Terreni Stato
--      Saldo Terreni Stato
--      Codice Tributo Aree Fabbricabili Comune
--      Unico Aree Fabbricabili Comune
--      Acconto Aree Fabbricabili Comune
--      Saldo Aree Fabbricabili Comune
--      Codice Tributo Aree Fabbricabili Stato
--      Unico Aree Fabbricabili Stato
--      Acconto Aree Fabbricabili Stato
--      Saldo Aree Fabbricabili Stato
--      Codice Tributo Altri Fabbricati Comune
--      Unico Altri Fabbricati Comune
--      Acconto Altri Fabbricati Comune
--      Saldo Altri Fabbricati Comune
--      Numero Immobili Altri Fabbricati
--      Codice Tributo Altri Fabbricati Stato
--      Unico Altri Fabbricati Stato
--      Acconto Altri Fabbricati Stato
--      Saldo Altri Fabbricati Stato
--      Numero Immobili Altri Fabbricati
--      Codice Tributo fabbricati D Comune
--      Unico fabbricati D Comune
--      Acconto fabbricati D Comune
--      Saldo fabbricati D Comune
--      Numero Immobili fabbricati D
--      Codice Tributo fabbricati D Stato
--      Unico fabbricati D Stato
--      Acconto fabbricati D Stato
--      Saldo fabbricati D Stato
--      Numero Immobili  Fabbricati D
--      Rateazione Abitazione Principale
--      Unico Detrazione
--      Acconto Detrazione
--      Saldo Detrazione
--      VERS_TOT_AB_PRINCIPALE
--      VERS_NUM_FABBRICATI_AB,0
--      VERS_DETRAZIONE
--      VERSATO_TOT_RURALI
--      VERS_NUM_FABBRICATI_RURALI
--      VERS_TOT_TERRENI_AGRICOLI
--      VERS_TERRENI_ERARIALE
--      VERS_TERRENI_COMUNE,
--      VERS_NUM_FABBRICATI_TERRENI,
--      VERS_TOT_AREE_FABBRICABILI
--      VERS_AREE_ERARIALE,
--      VERS_AREE_COMUNE
--      VERS_NUM_FABBRICATI_AREE
--      VERS_TOT_ALTRI_FABBRICATI
--      VERS_ALTRI_ERARIALE
--      VERS_ALTRI_COMUNE
--      VERS_NUM_FABBRICATI_ALTRI
--      VERS_TOT_FABBRICATI_D
--      VERS_fabbricati_d_ERARIALE
--      VERS_fabbricati_d_COMUNE
--      VERS_NUM_FABBRICATI_D
--      Cognome
--      Nome
--      Data Nascita
--      Sesso
--      Comune Nascita
--      Prov Nascita
-- CAMPI AGGIUNTI TASI
--      Imposta totale non arrotondata
--      Versato Totale
--      Dovuto a saldo non arrotondato (sul versato)
--      Dovuto a saldo arrotondato (sul versato)
--      Arrotondamento
      FOR rec_ogim_cf IN sel_ogim_cf(p_anno,p_tipo_contatto,rec_ogim.cod_fiscale)
      LOOP
         nMesi_aa := to_number(substr(rec_ogim_cf.periodo,1,2));
         if nMesi_aa = 0 then
            nMesi_aa := null;
            dDal_aa  := null;
            dAl_aa   := null;
         else
            dDal_aa  := to_date(substr(rec_ogim_cf.periodo,3,8),'ddmmyyyy');
            dAl_aa   := to_date(substr(rec_ogim_cf.periodo,11,8),'ddmmyyyy');
         end if;
         nMesi_1s := to_number(substr(rec_ogim_cf.periodo_1s,1,2));
         if nMesi_1s = 0 then
            nMesi_1s := null;
            dDal_1s  := null;
            dAl_1s   := null;
         else
            dDal_1s  := to_date(substr(rec_ogim_cf.periodo_1s,3,8),'ddmmyyyy');
            dAl_1s   := to_date(substr(rec_ogim_cf.periodo_1s,11,8),'ddmmyyyy');
         end if;
         dDal_Riog_1                   := null;
         dAl_Riog_1                    := null;
         sCategoria_Catasto_Riog_1     := null;
         sDes_Categoria_Catasto_Riog_1 := null;
         sClasse_Catasto_Riog_1        := null;
         nRendita_Riog_1               := null;
         nMoltiplicatore_Riog_1        := null;
         dDal_Riog_2                   := null;
         dAl_Riog_2                    := null;
         sCategoria_Catasto_Riog_2     := null;
         sDes_Categoria_Catasto_Riog_2 := null;
         sClasse_Catasto_Riog_2        := null;
         nRendita_Riog_2               := null;
         nMoltiplicatore_Riog_2        := null;
         open sel_riog (p_anno,rec_ogim_cf.oggetto,dDal_aa,dAl_aa);
         fetch sel_riog into dDal_Riog_1,dAl_Riog_1,sCategoria_Catasto_Riog_1,sDes_Categoria_Catasto_Riog_1,
                             sClasse_Catasto_Riog_1,nRendita_Riog_1,nMoltiplicatore_Riog_1;
         if sel_riog%FOUND then
            fetch sel_riog into dDal_Riog_2,dAl_Riog_2,sCategoria_Catasto_Riog_2,sDes_Categoria_Catasto_Riog_2,
                                sClasse_Catasto_Riog_2,nRendita_Riog_2,nMoltiplicatore_Riog_2;
         end if;
         close sel_riog;
         -- Se lmmobile storico anche il moltiplicatore dei riog va messo a 100
         if rec_ogim_cf.imm_storico = 'SI' and rec_ogim_cf.tipo_oggetto in (3,55) and p_anno < 2012 then
            if  nMoltiplicatore_Riog_1 is not null then
               nMoltiplicatore_Riog_1 := 100;
            end if;
            if nMoltiplicatore_Riog_2 is not null then
               nMoltiplicatore_Riog_2 := 100;
            end if;
         end if;
         nProgressivo := nProgressivo + 1;
         insert into wrk_tras_anci
               (anno,progressivo,dati)
         values(8
               ,nProgressivo
               ,rec_ogim.cod_fiscale||';'||
                '2'||';'||
                rec_ogim_cf.indirizzo||';'||
                rec_ogim_cf.zona||';'||
                rec_ogim_cf.sezione||';'||
                rec_ogim_cf.foglio||';'||
                rec_ogim_cf.numero||';'||
                rec_ogim_cf.subalterno||';'||
                rec_ogim_cf.partita||';'||
                to_char(rec_ogim_cf.progr_partita)||';'||
                to_char(rec_ogim_cf.anno_catasto)||';'||
                rec_ogim_cf.protocollo_catasto||';'||
                to_char(rec_ogim_cf.moltiplicatore * 100)||';'||
                to_char(rec_ogim_cf.rivalutazione * 100)||';'||
                rec_ogim_cf.categoria_catasto||';'||
                rec_ogim_cf.des_categoria_catasto||';'||
                rec_ogim_cf.classe_catasto||';'||
                to_char(dDal_aa,'ddmmyyyy')||';'||
                to_char(dAl_aa,'ddmmyyyy')||';'||
                to_char(nMesi_aa)||';'||
                to_char(dDal_1s,'ddmmyyyy')||';'||
                to_char(dAl_1s,'ddmmyyyy')||';'||
                to_char(nMesi_1s)||';'||
                to_char(rec_ogim_cf.perc_possesso * 100)||';'||
                rec_ogim_cf.imm_storico||';'||
                to_char(rec_ogim_cf.valore * 100)||';'||
                to_char(rec_ogim_cf.rendita * 100)||';'||
                to_char(rec_ogim_cf.imposta_totale * 100)||';'||
                to_char(rec_ogim_cf.detrazione_totale * 100)||';'||
                to_char(rec_ogim_cf.imposta_acconto * 100)||';'||
                to_char(rec_ogim_cf.detrazione_acconto * 100)||';'||
                to_char(rec_ogim_cf.imposta_saldo * 100)||';'||
                to_char(rec_ogim_cf.detrazione_saldo * 100)||';'||
                to_char(rec_ogim_cf.tipo_aliquota)||';'||
                to_char(rec_ogim_cf.aliquota * 100)||';'||
                to_char(rec_ogim_cf.num_bollettino)||';'||
                to_char(dDal_Riog_2,'ddmmyyyy')||';'||
                to_char(dAl_Riog_2,'ddmmyyyy')||';'||
                sCategoria_Catasto_Riog_2||';'||
                sDes_Categoria_Catasto_Riog_2||';'||
                sClasse_Catasto_Riog_2||';'||
                to_char(nRendita_Riog_2 * 100)||';'||
                to_char(nMoltiplicatore_Riog_2 * 100)||';'||
                to_char(dDal_Riog_1,'ddmmyyyy')||';'||
                to_char(dAl_Riog_1,'ddmmyyyy')||';'||
                sCategoria_Catasto_Riog_1||';'||
                sDes_Categoria_Catasto_Riog_1||';'||
                sClasse_Catasto_Riog_1||';'||
                to_char(nRendita_Riog_1 * 100)||';'||
                to_char(nMoltiplicatore_Riog_1 * 100)||';'||
                to_char(rec_ogim_cf.detrazione_imponibile * 100) ||';'||
                to_char(rec_ogim_cf.detrazione_imponibile_acconto * 100) ||';'||
                to_char(rec_ogim_cf.detrazione_imponibile_saldo * 100)
               )
         ;
      END LOOP;
   END LOOP;
EXCEPTION
   WHEN ERRORE THEN
      ROLLBACK;
      RAISE_APPLICATION_ERROR(-20999,sErrore);
--   WHEN OTHERS THEN
--      ROLLBACK;
--      RAISE_APPLICATION_ERROR(-20999,to_char(SQLCODE)||' '||SQLERRM);
END;
/* End Procedure: ESTRAI_F24_COMP_TASI */
/

