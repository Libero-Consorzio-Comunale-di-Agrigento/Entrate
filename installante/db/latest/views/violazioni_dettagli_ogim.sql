--liquibase formatted sql 
--changeset abrandolini:20250326_152401_violazioni_dettagli_ogim stripComments:false runOnChange:true 
 
create or replace force view violazioni_dettagli_ogim as
select prtr.pratica
   ,sum(ogim.detrazione) detrazione
   ,sum(ogim.detrazione_acconto) detrazione_acconto
   ,sum(ogim.detrazione - ogim.detrazione_acconto) detrazione_saldo
   ,sum(decode(ogim.tipo_aliquota, 2, 1, 0)) num_fabbricati_ab_imu
   ,sum(decode(ogim.tipo_aliquota, 2, 0, decode(nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto),  1, 0,  2, 0,  decode(ogim.aliquota_erariale, null, 1, 0)))
 )
  num_fabbricati_rurali_imu
   ,sum(decode(ogim.tipo_aliquota, 2, 0, decode(nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto),  1, 0,  2, 0,  decode(aliquota_erariale, null, 0, 1)))
 )
  num_fabbricati_altri_imu
   ,0 num_fabbricati_fabb_d_imu
   ,0 num_fabbricati_fabb_merce_imu
   ,sum(decode(nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto)
  ,1, 0
  ,2, 0
  ,decode(ogco.flag_ab_principale ||
    substr(ogpr.categoria_catasto
    ,1
    ,1
    )
   ,'SA', 1
   ,0
   )
  ))
  num_fabbricati_ab_ici
   ,sum(decode(nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto)
  ,1, 0
  ,2, 0
  ,decode(ogco.flag_ab_principale ||
    substr(ogpr.categoria_catasto
    ,1
    ,1
    )
   ,'SA', 0
   ,1
   )
  ))
  num_fabbricati_altri_ici
   ,0 num_fabbricati_ab_tasi
   ,0 num_fabbricati_rurali_tasi
   ,0 num_fabbricati_altri_tasi
  from oggetti_imposta ogim
   ,oggetti_pratica ogpr
   ,oggetti ogge
   ,pratiche_tributo prtr
   ,oggetti_contribuente ogco
 where ogim.oggetto_pratica = ogpr.oggetto_pratica
   and ogpr.oggetto = ogge.oggetto
   and ogpr.pratica = prtr.pratica
   and ogpr.oggetto_pratica = ogco.oggetto_pratica
   and prtr.tipo_pratica in ('V', 'A', 'L')
   and prtr.tipo_tributo = 'ICI'
   and ogim.flag_calcolo is null
   and prtr.anno < 2013
 group by prtr.pratica
 union all
   select prtr.pratica
   ,sum(ogim.detrazione) detrazione
   ,sum(ogim.detrazione_acconto) detrazione_acconto
   ,sum(ogim.detrazione - ogim.detrazione_acconto) detrazione_saldo
   ,sum(decode(ogim.tipo_aliquota, 2, 1, 0)) num_fabbricati_ab_imu
   ,sum(decode(ogim.tipo_aliquota, 2, 0, decode(nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto),  1, 0,  2, 0,  decode(nvl(aliq.flag_fabbricati_merce, 'N'), 'S', 0, decode(ogim.aliquota_erariale, null, 1, 0))))
 )
  num_fabbricati_rurali_imu
   ,sum(decode(ogim.tipo_aliquota, 2, 0, decode(nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto),  1, 0,  2, 0,  decode(ogim.aliquota_erariale, null, 0, decode(nvl(aliq.flag_fabbricati_merce, 'N'), 'S', 0, 1))))
 )
  num_fabbricati_altri_imu
   ,sum(decode(ogim.tipo_aliquota
  ,9, decode(nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto)
   ,1, 0
   ,2, 0
   ,decode(substr(ogpr.categoria_catasto
     ,1
     ,1
     )
    ,'D', 1
    ,0
    )
   )
  ))
  num_fabbricati_fabb_d_imu
   ,sum(decode(nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto),  1, 0,  2, 0,  decode(nvl(aliq.flag_fabbricati_merce, 'N'), 'S', 1, 0))
 )
  num_fabbricati_fabb_merce_imu
   ,sum(decode(nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto)
  ,1, 0
  ,2, 0
  ,decode(ogco.flag_ab_principale ||
    substr(ogpr.categoria_catasto
    ,1
    ,1
    )
   ,'SA', 1
   ,0
   )
  ))
  num_fabbricati_ab_ici
   ,sum(decode(nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto)
  ,1, 0
  ,2, 0
  ,decode(ogco.flag_ab_principale ||
    substr(ogpr.categoria_catasto
    ,1
    ,1
    )
   ,'SA', 0
   ,1
   )
  ))
  num_fabbricati_altri_ici
   ,0 num_fabbricati_ab_tasi
   ,0 num_fabbricati_rurali_tasi
   ,0 num_fabbricati_altri_tasi
  from oggetti_imposta ogim
   ,oggetti_pratica ogpr
   ,oggetti ogge
   ,pratiche_tributo prtr
   ,oggetti_contribuente ogco
   ,aliquote aliq
 where ogim.oggetto_pratica = ogpr.oggetto_pratica
   and ogpr.oggetto = ogge.oggetto
   and ogpr.pratica = prtr.pratica
   and ogpr.oggetto_pratica = ogco.oggetto_pratica
   and prtr.tipo_pratica in ('V', 'A', 'L')
   and prtr.tipo_tributo = 'ICI'
   and ogim.flag_calcolo is null
   and ogim.tipo_tributo = aliq.tipo_tributo (+)
   and ogim.anno = aliq.anno (+)
   and ogim.tipo_aliquota = aliq.tipo_aliquota (+)
   and prtr.anno >= 2013
 group by prtr.pratica
 union all
   select prtr.pratica
   ,sum(ogim.detrazione) detrazione
   ,sum(ogim.detrazione_acconto) detrazione_acconto
   ,sum(ogim.detrazione - ogim.detrazione_acconto) detrazione_saldo
   ,0 num_fabbricati_ab_imu
   ,0 num_fabbricati_rurali_imu
   ,0 num_fabbricati_altri_imu
   ,0 num_fabbricati_ab_ici
   ,0 num_fabbricati_altri_ici
   ,0 num_fabbricati_fabb_d_imu
   ,0 num_fabbricati_fabb_merce_imu
   ,sum(decode(ogim.tipo_aliquota, 2, 1, 0)) num_fabbricati_ab_tasi
   ,sum(decode(ogim.tipo_aliquota, 2, 0, decode(nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto),  1, 0,  2, 0,  decode(aliquota_erariale, null, 1, 0)))) num_fabbricati_rurali_tasi
   ,sum(decode(ogim.tipo_aliquota, 2, 0, decode(nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto),  1, 0,  2, 0,  decode(aliquota_erariale, null, 0, 1)))) num_fabbricati_altri_tasi
  from oggetti_imposta ogim
   ,oggetti_pratica ogpr
   ,oggetti ogge
   ,pratiche_tributo prtr
   ,oggetti_contribuente ogco
 where ogim.oggetto_pratica = ogpr.oggetto_pratica
   and ogpr.oggetto = ogge.oggetto
   and ogpr.pratica = prtr.pratica
   and ogpr.oggetto_pratica = ogco.oggetto_pratica
   and prtr.tipo_pratica in ('V', 'A', 'L')
   and prtr.tipo_tributo = 'TASI'
   and ogim.flag_calcolo is null
 group by prtr.pratica;
comment on table VIOLAZIONI_DETTAGLI_OGIM is 'VDOG - Violazioni Dettagli OGIM';

