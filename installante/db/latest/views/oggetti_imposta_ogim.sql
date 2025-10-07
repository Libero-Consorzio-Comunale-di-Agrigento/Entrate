--liquibase formatted sql 
--changeset rvattolo:20250604_180808_oggetti_imposta_ogim stripComments:false runOnChange:true 
 
create or replace view oggetti_imposta_ogim as
select ogim.anno,
       ogim.tipo_tributo,
       ogim.oggetto_pratica,
       ogim.cod_fiscale,
       ogim.flag_calcolo,
       --
       nvl(ogog.mesi_possesso,ogim.mesi_possesso) as mesi_possesso,
       nvl(ogog.da_mese_possesso,ogim.da_mese_possesso) as da_mese_possesso,
       ogog.mesi_possesso_1sem as mesi_possesso_1sem,
       --
       ogog.mesi_riduzione as mesi_riduzione,
       ogog.mesi_esclusione as mesi_esclusione,
       ogog.mesi_aliquota_ridotta as mesi_aliquota_ridotta,
       --
       nvl(ogog.tipo_aliquota,ogim.tipo_aliquota) as tipo_aliquota,
       nvl(ogog.aliquota,ogim.aliquota) as aliquota,
       nvl(ogog.aliquota_erariale,ogim.aliquota_erariale) as aliquota_erariale,
       nvl(ogog.aliquota_std,ogim.aliquota_std) as aliquota_std,
       --
       nvl(ogog.imposta,ogim.imposta) as imposta,
       nvl(ogog.imposta_acconto,ogim.imposta_acconto) as imposta_acconto,
       nvl(ogog.imposta_erariale,ogim.imposta_erariale) as imposta_erariale,
       nvl(ogog.imposta_erariale_acconto,ogim.imposta_erariale_acconto) as imposta_erariale_acconto,
       nvl(ogog.imposta_dovuta,ogim.imposta_dovuta) as imposta_dovuta,
       nvl(ogog.imposta_dovuta_acconto,ogim.imposta_dovuta_acconto) as imposta_dovuta_acconto,
       nvl(ogog.imposta_erariale_dovuta,ogim.imposta_erariale_dovuta) as imposta_erariale_dovuta,
       nvl(ogog.imposta_erariale_dovuta_acc,ogim.imposta_erariale_dovuta_acc) as imposta_erariale_dovuta_acc,
       --
       decode(ogog.sequenza,null,ogim.imposta_mini,0) as imposta_mini,
       decode(ogog.sequenza,null,ogim.imposta_dovuta_mini,0) as imposta_dovuta_mini,
       decode(ogog.sequenza,null,ogim.imposta_std,0) as imposta_std,
       decode(ogog.sequenza,null,ogim.imposta_dovuta_std,0) as imposta_dovuta_std,
       decode(ogog.sequenza,null,ogim.detrazione_std,0) as detrazione_std,
       decode(ogog.sequenza,null,ogim.imposta_aliquota,0) as imposta_aliquota,
       decode(ogog.sequenza,null,ogim.detrazione,0) as detrazione,
       decode(ogog.sequenza,null,ogim.detrazione_acconto,0) as detrazione_acconto
       --
     , ogog.sequenza as sequenza_ogog
  from oggetti_imposta        ogim
  left join oggetti_ogim      ogog
    on ogim.oggetto_pratica   = ogog.oggetto_pratica
   and ogim.cod_fiscale       = ogog.cod_fiscale
   and ogim.anno              = ogog.anno
 where ogim.flag_calcolo      = 'S'
;
