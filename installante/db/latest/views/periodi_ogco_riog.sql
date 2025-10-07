--liquibase formatted sql 
--changeset abrandolini:20250326_152401_periodi_ogco_riog stripComments:false runOnChange:true 
 
CREATE OR REPLACE FORCE VIEW PERIODI_OGCO_RIOG
(COD_FISCALE, ANNO, TIPO_TRIBUTO, TIPO_PRATICA, TIPO_EVENTO,
 TIPO_RAPPORTO, DATA_DECORRENZA, DATA_CESSAZIONE, TRIBUTO, CATEGORIA_OGPR,
 TIPO_TARIFFA, CONSISTENZA, MESI_POSSESSO_OGCO, MESI_POSSESSO_1SEM, MESI_OCCUPATO,
 MESI_OCCUPATO_1SEM, FLAG_POSSESSO, PERC_POSSESSO, FLAG_AL_RIDOTTA, FLAG_AB_PRINCIPALE,
 FLAG_ESCLUSIONE, FLAG_RIDUZIONE, FLAG_CONTENZIOSO, FLAG_VALORE_RIVALUTATO, IMM_STORICO,
 VALORE, CATEGORIA_CATASTO, CLASSE_CATASTO, TIPO_OGGETTO, FLAG_PERTINENZA_DI,
 OGGETTO_PRATICA_RIF_AP, PRATICA, OGGETTO, OGGETTO_PRATICA, INIZIO_VALIDITA,
 FINE_VALIDITA, INIZIO_VALIDITA_RIOG, TIPO_VIOLAZIONE, MESI_ESCLUSIONE, MESI_RIDUZIONE)
AS
select peog.cod_fiscale
       ,peog.anno
       ,peog.tipo_tributo
       ,peog.tipo_pratica
       ,peog.tipo_evento
       ,peog.tipo_rapporto
       ,peog.data_decorrenza
       ,peog.data_cessazione
       ,peog.tributo
       ,peog.categoria_ogpr
       ,peog.tipo_tariffa
       ,peog.consistenza
       ,peog.mesi_possesso_ogco
       ,peog.mesi_possesso_1sem
       ,peog.mesi_occupato
       ,peog.mesi_occupato_1sem
       ,peog.flag_possesso
       ,peog.perc_possesso
       ,peog.flag_al_ridotta
       ,peog.flag_ab_principale
       ,peog.flag_esclusione
       ,peog.flag_riduzione
       ,peog.flag_contenzioso
       ,peog.flag_valore_rivalutato
       ,peog.imm_storico
       ,peog.valore
       ,peog.categoria_catasto
       ,peog.classe_catasto
       ,peog.tipo_oggetto
       ,peog.flag_pertinenza_di
       ,peog.oggetto_pratica_rif_ap
       ,peog.pratica
       ,peog.oggetto
       ,peog.oggetto_pratica
       ,greatest(peog.inizio_validita
                ,nvl(peri.inizio_validita,peog.inizio_validita)
                )
         inizio_validita
       ,least(peog.fine_validita
             ,nvl(peri.fine_validita,peog.fine_validita)
             )
         fine_validita
       ,peri.inizio_validita_eff inizio_validita_riog
       ,peog.tipo_violazione
       ,peog.mesi_esclusione
       ,peog.mesi_riduzione
   from periodi_ogco peog
       ,periodi_riog peri
  where peog.oggetto = peri.oggetto (+)
    and peog.inizio_validita <= peri.fine_validita (+)
    and peog.fine_validita >= peri.inizio_validita (+);
comment on table PERIODI_OGCO_RIOG is 'PEOR - Periodi OGCO RIOG';

