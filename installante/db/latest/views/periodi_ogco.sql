--liquibase formatted sql 
--changeset abrandolini:20250326_152401_periodi_ogco stripComments:false runOnChange:true 
 
CREATE OR REPLACE FORCE VIEW PERIODI_OGCO
(COD_FISCALE, ANNO, TIPO_TRIBUTO, TIPO_PRATICA, TIPO_EVENTO,
 TIPO_RAPPORTO, DATA_DECORRENZA, DATA_CESSAZIONE, TRIBUTO, CATEGORIA_OGPR,
 TIPO_TARIFFA, CONSISTENZA, MESI_POSSESSO_OGCO, MESI_POSSESSO_1SEM, MESI_OCCUPATO,
 MESI_OCCUPATO_1SEM, FLAG_POSSESSO, PERC_POSSESSO, FLAG_AL_RIDOTTA, FLAG_AB_PRINCIPALE,
 FLAG_ESCLUSIONE, FLAG_RIDUZIONE, FLAG_CONTENZIOSO, FLAG_VALORE_RIVALUTATO, IMM_STORICO,
 VALORE, CATEGORIA_CATASTO, CLASSE_CATASTO, TIPO_OGGETTO, FLAG_PERTINENZA_DI,
 OGGETTO_PRATICA_RIF_AP, PRATICA, OGGETTO, OGGETTO_PRATICA, INIZIO_VALIDITA,
 FINE_VALIDITA, TIPO_VIOLAZIONE, MESI_ESCLUSIONE, MESI_RIDUZIONE)
AS
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
       ,prtr.tipo_violazione
       ,ogco.mesi_esclusione
       ,ogco.mesi_riduzione
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
;
comment on table PERIODI_OGCO is 'PEOG - Periodi OGCO';

