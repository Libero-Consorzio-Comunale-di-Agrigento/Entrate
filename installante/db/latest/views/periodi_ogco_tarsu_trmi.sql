--liquibase formatted sql 
--changeset abrandolini:20250326_152401_periodi_ogco_tarsu_trmi stripComments:false runOnChange:true 
 
create or replace force view periodi_ogco_tarsu_trmi as
select ogco.cod_fiscale
   , cont.ni
   , prtr.anno
   , prtr.tipo_tributo
   , prtr.tipo_pratica
   , prtr.tipo_evento||
  decode(f_get_evento_c(nvl(ogpr.oggetto_pratica_rif,ogpr.oggetto_pratica)
  ,ogco.cod_fiscale
  ,ogco.data_decorrenza
  ,'%'
  ,ogpr.oggetto
  ,prtr.tipo_tributo
  )
  ,'',''
  ,'/'||
   f_get_evento_c(nvl(ogpr.oggetto_pratica_rif,ogpr.oggetto_pratica)
  ,ogco.cod_fiscale
  ,ogco.data_decorrenza
  ,'%'
  ,ogpr.oggetto
  ,prtr.tipo_tributo
  )
  ) tipo_evento
   , nvl(ogco.tipo_rapporto,'D') tipo_rapporto
   , ogco.data_decorrenza
   , decode(nvl(ogpr.tipo_occupazione, 'P')
  ,'T',ogco.data_cessazione
  ,nvl(ogco.data_cessazione
   ,decode(prtr.tipo_pratica
    ,'A',nvl(f_fine_validita(nvl(ogpr.oggetto_pratica_rif,ogpr.oggetto_pratica)
    , ogco.cod_fiscale
    , ogco.data_decorrenza
    , '%'
    )
   ,f_cessazione_accertamento(ogco.cod_fiscale
     ,ogpr.oggetto
     ,ogco.data_decorrenza
     ,prtr.tipo_tributo
     )
   )
    ,f_fine_validita(nvl(ogpr.oggetto_pratica_rif,ogpr.oggetto_pratica)
     ,ogco.cod_fiscale
     ,ogco.data_decorrenza
     ,'%'
     )
    )
   )
  ) data_cessazione
   , ogpr.tributo
   , ogpr.categoria categoria_ogpr
   , ogpr.tipo_tariffa
   , ogpr.consistenza
   , ogco.flag_possesso
   , ogco.perc_possesso
   , f_get_ab_principale (ogco.cod_fiscale, ogco.anno, ogco.oggetto_pratica)
   flag_ab_principale
   , ogco.flag_esclusione
   , ogco.flag_riduzione
   , ogpr.flag_contenzioso
   , ogpr.imm_storico
   , ogpr.valore
   , ogpr.categoria_catasto
   , ogpr.classe_catasto
   , ogpr.tipo_oggetto
   , decode (ogpr.oggetto_pratica_rif_ap, null, null, 'S')
   flag_pertinenza_di
   , ogpr.oggetto_pratica_rif_ap
   , prtr.pratica
   , ogpr.oggetto
   , ogpr.oggetto_pratica
   , ogco.data_decorrenza inizio_validita
   , decode(nvl(ogpr.tipo_occupazione, 'P')
  ,'T',ogco.data_cessazione
  ,nvl(ogco.data_cessazione
   ,decode(prtr.tipo_pratica
    ,'A',nvl(f_fine_validita(nvl(ogpr.oggetto_pratica_rif,ogpr.oggetto_pratica)
    , ogco.cod_fiscale
    , ogco.data_decorrenza
    , '%'
    )
   ,f_cessazione_accertamento(ogco.cod_fiscale
     ,ogpr.oggetto
     ,ogco.data_decorrenza
     ,prtr.tipo_tributo
     )
   )
    ,f_fine_validita(nvl(ogpr.oggetto_pratica_rif,ogpr.oggetto_pratica)
     ,ogco.cod_fiscale
     ,ogco.data_decorrenza
     ,'%'
     )
    )
   )
  ) fine_validita
   , prtr.tipo_violazione
   , ogco.flag_punto_raccolta
   from oggetti_contribuente ogco
   , oggetti_pratica ogpr
   , pratiche_tributo prtr
   , contribuenti cont
  where ogpr.oggetto_pratica = ogco.oggetto_pratica
 and ogco.cod_fiscale = cont.cod_fiscale
 and prtr.pratica = ogpr.pratica
 and prtr.tipo_tributo in ('TARSU','TOSAP','ICP','CUNI')--in ('TARSU')
 and decode(prtr.tipo_pratica,'A',prtr.flag_denuncia,'S') = 'S'
 and decode(prtr.tipo_pratica
  ,'A',decode(prtr.flag_adesione
    ,'S',to_date('01011900', 'ddmmyyyy')
    ,nvl(prtr.data_notifica,to_date('31122999','ddmmyyyy')) + 60
    )
  ,to_date('01011900','ddmmyyyy')) < sysdate
 and prtr.tipo_pratica in ('D', 'A')
 and nvl (prtr.stato_accertamento, 'D') = 'D'
 and decode(prtr.tipo_pratica
  ,'D',nvl(ogco.data_decorrenza,to_date('01011900','ddmmyyyy'))
  ,nvl(ogco.data_decorrenza,ogco.data_cessazione)) is not null
 and prtr.tipo_evento <> 'C'
 and prtr.flag_annullamento is null
 and prtr.pratica > 0
 and not exists
 (select 1
 from oggetti_contribuente ogc1, oggetti_pratica ogp1, pratiche_tributo prt1
   where ogp1.oggetto_pratica = ogc1.oggetto_pratica
  and prt1.pratica = ogp1.pratica
  and decode (prt1.tipo_pratica, 'A', prt1.flag_denuncia, 'S') =
    'S'
  and decode (
    prt1.tipo_pratica
  , 'D', nvl (ogc1.data_decorrenza
   , to_date ('01011900', 'ddmmyyyy'))
  , nvl (ogc1.data_decorrenza, ogc1.data_cessazione))
    is not null
  and prt1.tipo_pratica in ('D', 'A')
  and nvl (prt1.stato_accertamento, 'D') = 'D'
  and decode (
    prt1.tipo_pratica
  , 'A', decode (
    prt1.flag_adesione
  , 'S', to_date ('01011900', 'ddmmyyyy')
  , nvl (prt1.data_notifica
    , to_date ('31122999', 'ddmmyyyy')) +
    60)
  , to_date ('01011900', 'ddmmyyyy')) < sysdate
  and prt1.tipo_evento <> 'C'
  and prt1.flag_annullamento is null
  and ogc1.cod_fiscale = ogco.cod_fiscale
  and prt1.tipo_tributo || '' = prtr.tipo_tributo
  and nvl (ogp1.oggetto_pratica_rif, ogp1.oggetto_pratica) =
    nvl (ogpr.oggetto_pratica_rif, ogpr.oggetto_pratica)
  and nvl (ogc1.data_decorrenza
   , to_date ('01011900', 'ddmmyyyy')) =
    nvl (ogco.data_decorrenza
    , to_date ('01011900', 'ddmmyyyy'))
  and (nvl (prt1.data, to_date ('01011900', 'ddmmyyyy')) >
  nvl (prtr.data, to_date ('01011900', 'ddmmyyyy'))
    or  nvl (prt1.data, to_date ('01011900', 'ddmmyyyy')) =
   nvl (prtr.data, to_date ('01011900', 'ddmmyyyy'))
    and prt1.pratica > prtr.pratica))
;
comment on table PERIODI_OGCO_TARSU_TRMI is 'Periodi Ogco Tarsu Trmi';

