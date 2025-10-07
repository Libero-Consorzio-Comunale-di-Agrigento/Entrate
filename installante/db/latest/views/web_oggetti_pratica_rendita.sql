--liquibase formatted sql 
--changeset abrandolini:20250326_152401_web_oggetti_pratica_rendita stripComments:false runOnChange:true 
 
create or replace force view web_oggetti_pratica_rendita as
select ogpr.OGGETTO_PRATICA,
nvl(f_rendita (ogpr.valore, NVL (ogpr.tipo_oggetto, ogge.tipo_oggetto), prtr.anno, NVL (ogpr.categoria_catasto, ogge.categoria_catasto)),0) rendita
from OGGETTI_PRATICA ogpr, OGGETTI ogge, PRATICHE_TRIBUTO prtr
where ogpr.oggetto = ogge.oggetto
and ogpr.pratica = prtr.pratica;
comment on table WEB_OGGETTI_PRATICA_RENDITA is 'WEB_OGGETTI_PRATICA_RENDITA';

