--liquibase formatted sql 
--changeset abrandolini:20250326_152401_periodi_ogco_prtr stripComments:false runOnChange:true 
 
create or replace force view periodi_ogco_prtr as
select ogco.cod_fiscale
 ,prtr.anno
 ,prtr.tipo_tributo
 ,prtr.tipo_pratica
 ,prtr.tipo_evento
 ,ogco.tipo_rapporto
 ,ogco.data_decorrenza
 ,ogco.data_cessazione
 ,ogpr.tributo
 ,ogpr.categoria categoria_ogpr
 ,ogpr.tipo_tariffa
 ,ogpr.consistenza
 ,case
   when nvl(ogco.mesi_possesso, 12) between 0 and 12 then
 to_number(null)
   else
 ogco.mesi_possesso
  end
   mesi_possesso_ogco
 ,ogco.mesi_possesso_1sem
 ,ogco.mesi_occupato
 ,ogco.mesi_occupato_1sem
 ,ogco.flag_possesso
 ,ogco.perc_possesso
 ,ogco.flag_al_ridotta
 ,f_get_ab_principale(ogco.cod_fiscale
   ,ogco.anno
   ,ogco.oggetto_pratica
   )
   flag_ab_principale
 ,ogco.flag_esclusione
 ,ogco.flag_riduzione
 ,ogpr.flag_contenzioso
 ,ogpr.flag_valore_rivalutato
 ,ogpr.imm_storico
 ,ogpr.valore
 ,ogpr.categoria_catasto
 ,ogpr.classe_catasto
 ,ogpr.tipo_oggetto
 ,decode(ogpr.oggetto_pratica_rif_ap, null, null, 'S')
   flag_pertinenza_di
 ,ogpr.oggetto_pratica_rif_ap
 ,prtr.pratica
 ,ogpr.oggetto
 ,ogpr.oggetto_pratica
 ,f_get_inizio_periodo_ogco(ogco.da_mese_possesso
   ,ogco.mesi_possesso
   ,ogco.flag_possesso
   ,prtr.anno
   )
   inizio_validita
 ,f_get_fine_periodo_ogco(prtr.tipo_tributo
    ,ogco.cod_fiscale
    ,ogpr.oggetto
    ,ogco.da_mese_possesso
    ,ogco.mesi_possesso
    ,ogco.flag_possesso
    ,prtr.anno
    )
   fine_validita
   from oggetti_contribuente ogco
 ,oggetti_pratica ogpr
 ,pratiche_tributo prtr
  where ogco.oggetto_pratica = ogpr.oggetto_pratica
 and prtr.pratica = ogpr.pratica
 and prtr.pratica > 0
 and prtr.tipo_tributo in ('ICI', 'TASI')
 and prtr.flag_annullamento is null
 and ((prtr.data_notifica is not null
   and prtr.tipo_pratica || '' = 'A'
   and nvl(prtr.stato_accertamento, 'D') = 'D'
   and nvl(prtr.flag_denuncia, ' ') = 'S')
   or  (prtr.data_notifica is null
 and prtr.tipo_pratica || '' = 'D'))
 -- 02/08/2019 AB aggiunto questo controllo per evitare di trattare le denunce TASI con mesi = 0 del 2014 create dall'IMU e poi aggiornate nel caso di altre denunce nell'anno
 and decode(prtr.tipo_tributo
  ,'TASI', decode(ogco.anno || mesi_possesso || flag_possesso
  ,'20140', 'N'
  ,'S'
  )
  ,'S'
  ) = 'S'
union
select ogco.cod_fiscale
 ,prtr.anno
 ,prtr.tipo_tributo
 ,prtr.tipo_pratica
 ,prtr.tipo_evento
 ,ogco.tipo_rapporto
 ,ogco.data_decorrenza
 ,ogco.data_cessazione
 ,ogpr.tributo
 ,ogpr.categoria categoria_ogpr
 ,ogpr.tipo_tariffa
 ,ogpr.consistenza
 ,case
   when nvl(ogco.mesi_possesso, 12) between 0 and 12 then
 to_number(null)
   else
 ogco.mesi_possesso
  end
   mesi_possesso_ogco
 ,ogco.mesi_possesso_1sem
 ,ogco.mesi_occupato
 ,ogco.mesi_occupato_1sem
 ,ogco.flag_possesso
 ,ogco.perc_possesso
 ,ogco.flag_al_ridotta
 ,f_get_ab_principale(ogco.cod_fiscale
   ,ogco.anno
   ,ogco.oggetto_pratica
   )
   flag_ab_principale
 ,ogco.flag_esclusione
 ,ogco.flag_riduzione
 ,ogpr.flag_contenzioso
 ,ogpr.flag_valore_rivalutato
 ,ogpr.imm_storico
 ,ogpr.valore
 ,ogpr.categoria_catasto
 ,ogpr.classe_catasto
 ,ogpr.tipo_oggetto
 ,decode(ogpr.oggetto_pratica_rif_ap, null, null, 'S')
   flag_pertinenza_di
 ,ogpr.oggetto_pratica_rif_ap
 ,prtr.pratica
 ,ogpr.oggetto
 ,ogpr.oggetto_pratica
 ,f_get_inizio_periodo_ogco(ogco.da_mese_possesso
   ,ogco.mesi_possesso
   ,'N' --ogco.flag_possesso
   ,prtr.anno
   )
   inizio_validita
 ,f_get_fine_periodo_ogco(prtr.tipo_tributo
    ,ogco.cod_fiscale
    ,ogpr.oggetto
    ,ogco.da_mese_possesso
    ,ogco.mesi_possesso
    ,'N' --ogco.flag_possesso
    ,prtr.anno
    )
   fine_validita
   from oggetti_contribuente ogco
 ,oggetti_pratica ogpr
 ,pratiche_tributo prtr
  where ogco.oggetto_pratica = ogpr.oggetto_pratica
 and prtr.pratica = ogpr.pratica
 and prtr.pratica > 0
 and prtr.tipo_tributo in ('ICI', 'TASI')
 and prtr.tipo_pratica || '' in ('A','I','L')
 -- and prtr.flag_annullamento is null
-- and ((prtr.data_notifica is not null
--   and nvl(prtr.stato_accertamento, 'D') = 'D'
   and prtr.flag_denuncia is null
--   or  (prtr.data_notifica is null
-- and prtr.tipo_pratica || '' in ('D','V'))) --= 'D'))
-- -- 02/08/2019 AB aggiunto questo controllo per evitare di trattare le denunce TASI con mesi = 0 del 2014 create dall'IMU e poi aggiornate nel caso di altre denunce nell'anno
-- and decode(prtr.tipo_tributo
--  ,'TASI', decode(ogco.anno || mesi_possesso || flag_possesso
--  ,'20140', 'N'
--  ,'S'
--  )
--  ,'S'
--  ) = 'S'
;
comment on table PERIODI_OGCO_PRTR is 'PEOP - Periodi OGCO PRTR';

