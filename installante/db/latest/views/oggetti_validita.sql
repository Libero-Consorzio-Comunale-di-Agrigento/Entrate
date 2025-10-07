--liquibase formatted sql 
--changeset abrandolini:20250326_152401_oggetti_validita stripComments:false runOnChange:true 
 
create or replace force view oggetti_validita as
select ogco.cod_fiscale
   ,ogco.oggetto_pratica
   ,ogpr.oggetto
   ,ogco.flag_ab_principale
   ,nvl(ogpr.oggetto_pratica_rif,ogpr.oggetto_pratica) oggetto_pratica_rif
   ,ogco.data_decorrenza dal
   ,decode(nvl(ogpr.tipo_occupazione,'P')
 ,'T',ogco.data_cessazione
  ,nvl(ogco.data_cessazione
   ,decode(prtr.tipo_pratica
    ,'A',nvl(f_fine_validita(nvl(ogpr.oggetto_pratica_rif
     ,ogpr.oggetto_pratica
     )
    ,ogco.cod_fiscale
    ,ogco.data_decorrenza
    ,'%'
    )
   ,f_cessazione_accertamento(ogco.cod_fiscale
     ,ogpr.oggetto
     ,ogco.data_decorrenza
     ,prtr.tipo_tributo
     )
   )
  ,f_fine_validita(nvl(ogpr.oggetto_pratica_rif
    ,ogpr.oggetto_pratica
    )
   ,ogco.cod_fiscale
   ,ogco.data_decorrenza
   ,'%'
   )
    )
   )
 ) al
   ,prtr.pratica
   ,prtr.numero
   ,prtr.data
   ,prtr.anno
   ,prtr.tipo_tributo
   ,prtr.tipo_pratica
   ,prtr.tipo_evento
   ,nvl(ogpr.tipo_occupazione,'P') tipo_occupazione
   ,prtr.stato_accertamento
   ,prtr.flag_denuncia
  from oggetti_contribuente ogco
   ,oggetti_pratica   ogpr
   ,pratiche_tributo  prtr
 where ogpr.oggetto_pratica   = ogco.oggetto_pratica
   and prtr.pratica  = ogpr.pratica
   and decode(prtr.tipo_pratica,'A',prtr.flag_denuncia,'S')
   = 'S'
   and decode(prtr.tipo_pratica
 ,'A',decode(prtr.flag_adesione
   ,'S',to_date('01011900','ddmmyyyy')
   ,nvl(prtr.data_notifica,to_date('31122999','ddmmyyyy')) + 60
   )
 ,to_date('01011900','ddmmyyyy')
 )   < sysdate
   and prtr.tipo_pratica  in ('D','A')
   and nvl(prtr.stato_accertamento,'D')
   = 'D'
   and decode(prtr.tipo_pratica,'D',nvl(ogco.data_decorrenza,to_date('01011900','ddmmyyyy'))
     ,nvl(ogco.data_decorrenza,ogco.data_cessazione)
 )   is not null
   and prtr.tipo_evento   <> 'C'
   and prtr.flag_annullamento is null
   and not exists
   (select 1
   from oggetti_contribuente  ogc1
 ,oggetti_pratica ogp1
 ,pratiche_tributo   prt1
  where ogp1.oggetto_pratica  = ogc1.oggetto_pratica
 and prt1.pratica = ogp1.pratica
 and decode(prt1.tipo_pratica,'A',prt1.flag_denuncia,'S')
   = 'S'
 and decode(prt1.tipo_pratica,'D',nvl(ogc1.data_decorrenza,to_date('01011900','ddmmyyyy'))
   ,nvl(ogc1.data_decorrenza,ogc1.data_cessazione)
  )  is not null
 and prt1.tipo_pratica in ('D','A')
 and nvl(prt1.stato_accertamento,'D')
   = 'D'
 and decode(prt1.tipo_pratica
  ,'A',decode(prt1.flag_adesione
    ,'S',to_date('01011900','ddmmyyyy')
    ,nvl(prt1.data_notifica,to_date('31122999','ddmmyyyy')) + 60
    )
  ,to_date('01011900','ddmmyyyy')
  )   < sysdate
 and prt1.tipo_evento  <> 'C'
 and prt1.flag_annullamento is null
 and ogc1.cod_fiscale   = ogco.cod_fiscale
 and prt1.tipo_tributo||'' = prtr.tipo_tributo
 and nvl(ogp1.oggetto_pratica_rif,ogp1.oggetto_pratica)
   =
  nvl(ogpr.oggetto_pratica_rif,ogpr.oggetto_pratica)
 and nvl(ogc1.data_decorrenza,to_date('01011900','ddmmyyyy'))
   =
  nvl(ogco.data_decorrenza,to_date('01011900','ddmmyyyy'))
 and ( nvl(prt1.data,to_date('01011900','ddmmyyyy'))
   >
    nvl(prtr.data,to_date('01011900','ddmmyyyy'))
   or  nvl(prt1.data,to_date('01011900','ddmmyyyy'))
   =
    nvl(prtr.data,to_date('01011900','ddmmyyyy'))
   and prt1.pratica  > prtr.pratica
  )
   );
comment on table OGGETTI_VALIDITA is 'OGVA - Oggetti validità';

