--liquibase formatted sql 
--changeset abrandolini:20250326_152401_contribuenti_oggetto_anno stripComments:false runOnChange:true 
 
create or replace force view contribuenti_oggetto_anno as
select peox.cod_fiscale
      , peox.anno
      , peox.tipo_tributo
      , peox.tipo_pratica
      , peox.tipo_evento
      , peox.tipo_rapporto
      , peox.data_decorrenza
      , peox.data_cessazione
      , peox.tributo
      , peox.categoria_ogpr
      , peox.tipo_tariffa
      , peox.consistenza
      , peox.flag_possesso
      , peox.perc_possesso
      , peox.flag_ab_principale
      , peox.flag_esclusione
      , peox.flag_riduzione
      , peox.flag_contenzioso
      , peox.imm_storico
      , peox.valore
      , peox.categoria_catasto
      , peox.classe_catasto
      , peox.tipo_oggetto
      , peox.pratica
      , peox.oggetto
      , peox.oggetto_pratica
      , peox.inizio_validita
      , peox.fine_validita
   from periodi_ogco_prtr peox
 union
 select ogva.cod_fiscale
      , ogva.anno
      , ogva.tipo_tributo
      , ogva.tipo_pratica
      , ogva.tipo_evento
      , ogco.tipo_rapporto
      , ogco.data_decorrenza
      , ogco.data_cessazione
      , ogpr.tributo
      , ogpr.categoria categoria_ogpr
      , ogpr.tipo_tariffa
      , ogpr.consistenza
      , ogco.flag_possesso
      , ogco.perc_possesso
      , ogco.flag_ab_principale
      , ogco.flag_esclusione
      , ogco.flag_riduzione
      , ogpr.flag_contenzioso
      , ogpr.imm_storico
      , ogpr.valore
      , ogpr.categoria_catasto
      , ogpr.classe_catasto
      , ogpr.tipo_oggetto
      , ogva.pratica
      , ogpr.oggetto
      , ogpr.oggetto_pratica
      , nvl (ogva.dal, to_date ('01011900', 'ddmmyyyy')) inizio_validita
      , nvl (ogva.al, to_date ('31129999', 'ddmmyyyy')) fine_validita
   from oggetti_validita ogva
      , oggetti_contribuente ogco
      , oggetti_pratica ogpr
  where ogva.tipo_tributo in ('TARSU', 'ICP', 'TOSAP', 'CUNI')
    and ogva.oggetto_pratica = ogco.oggetto_pratica
    and ogva.cod_fiscale = ogco.cod_fiscale
    and ogva.oggetto_pratica = ogpr.oggetto_pratica;
comment on table CONTRIBUENTI_OGGETTO_ANNO is 'COOA - Contribuente Oggetti Anno';

