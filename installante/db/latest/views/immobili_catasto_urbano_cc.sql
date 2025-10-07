--liquibase formatted sql 
--changeset abrandolini:20250326_152401_immobili_catasto_urbano_cc stripComments:false runOnChange:true 
 
create or replace force view immobili_catasto_urbano_cc as
select fabb.id_immobile contatore
  , ltrim (rtrim (indi.indirizzo)) indirizzo
  , rtrim (ltrim (ltrim (indi.civico1, '0'))) ||
 decode (rtrim (ltrim (ltrim (indi.civico2, '0')))
 , '', ''
 , '-' || rtrim (ltrim (ltrim (indi.civico2, '0')))) ||
 decode (rtrim (ltrim (ltrim (indi.civico3, '0')))
 , '', ''
 , '-' || rtrim (ltrim (ltrim (indi.civico3, '0'))))
  num_civ
  , rtrim (ltrim (ltrim (fabb.lotto, '0'))) lotto
  , rtrim (ltrim (ltrim (fabb.edificio, '0'))) edificio
  , rtrim (ltrim (ltrim (fabb.scala, '0'))) scala
  , rtrim (ltrim (ltrim (fabb.interno_1, '0'))) ||
 decode (rtrim (ltrim (ltrim (fabb.interno_2, '0')))
 , '', ''
 , '-' || rtrim (ltrim (ltrim (fabb.interno_2, '0'))))
  interno
  , rtrim (ltrim (ltrim (fabb.piano_1, '0'))) ||
 decode (rtrim (ltrim (ltrim (fabb.piano_2, '0')))
 , '', ''
 , '-' || rtrim (ltrim (ltrim (fabb.piano_2, '0')))) ||
 decode (rtrim (ltrim (ltrim (fabb.piano_3, '0')))
 , '', ''
 , '-' || rtrim (ltrim (ltrim (fabb.piano_3, '0')))) ||
 decode (rtrim (ltrim (ltrim (fabb.piano_4, '0')))
 , '', ''
 , '-' || rtrim (ltrim (ltrim (fabb.piano_4, '0'))))
  piano
  , fabb.tipo_immobile
  , fabb.partita partita
  , iden.progr_identificativo
  , rtrim (ltrim (ltrim (iden.sezione, '0'))) sezione
  , substr (rtrim (ltrim (ltrim (iden.foglio, '0'))), 1, 5) foglio
  , substr (rtrim (ltrim (ltrim (iden.numero, '0'))), 1, 5) numero
  , rtrim (ltrim (ltrim (iden.subalterno, '0'))) subalterno
  , rtrim (ltrim (ltrim (fabb.zona, '0'))) zona
  , rtrim (ltrim (ltrim (fabb.categoria, '0'))) categoria
  , rtrim (ltrim (ltrim (fabb.classe, '0'))) classe
  , rtrim (ltrim (ltrim (fabb.consistenza, '0'))) consistenza
  , rtrim (ltrim (ltrim (fabb.superficie, '0'))) superficie
  , rtrim (
  ltrim (
   ltrim (decode (dage.cambio_euro, 1, fabb.rendita_lire, fabb.rendita_euro), '0')))
  rendita
  , rtrim (ltrim (ltrim (fabb.rendita_euro, '0'))) rendita_euro
  , null descrizione
  , f_adatta_data (fabb.data_efficacia) data_efficacia
  , f_adatta_data (fabb.data_efficacia_2) data_fine_efficacia
  , f_adatta_data (fabb.data_registrazione_atti) data_iscrizione
  , f_adatta_data (fabb.data_registrazione_atti_2) data_fine_iscrizione
  , fabb.protocollo_notifica
  , f_adatta_data (fabb.data_notifica) data_notifica
  , fabb.cod_causale_atto_generante
  , fabb.des_atto_generante
  , fabb.cod_causale_atto_conclusivo
  , fabb.des_atto_conclusivo
  , fabb.flag_classamento
  , iden.estremi_catasto estremi_catasto
  , fabb.annotazione note
  , iden.sezione_ric sezione_ric
  , iden.foglio_ric foglio_ric
  , iden.numero_ric numero_ric
  , iden.subalterno_ric subalterno_ric
  , indi.indirizzo_ric indirizzo_ric
  , fabb.zona_ric zona_ric
  , fabb.categoria_ric categoria_ric
  , fabb.partita_ric partita_ric
  from dati_generali dage
  , (select *
 from cc_indirizzi
   where tipo_immobile = 'F'
  and progr_indirizzo = 1) indi
  , cc_identificativi iden
  , cc_fabbricati fabb
 where indi.id_immobile(+) = fabb.id_immobile
   and indi.codice_amm (+) = fabb.codice_amm
   and nvl (indi.sezione_amm(+), ' ') = nvl (fabb.sezione_amm, ' ')
   and indi.tipo_immobile(+) = fabb.tipo_immobile
   and indi.progressivo(+) = fabb.progressivo
   and iden.id_immobile = fabb.id_immobile
   and iden.codice_amm = fabb.codice_amm
   and nvl (iden.sezione_amm, ' ') = nvl (fabb.sezione_amm, ' ')
   and iden.tipo_immobile = fabb.tipo_immobile
   and iden.progressivo = fabb.progressivo;
comment on table IMMOBILI_CATASTO_URBANO_CC is 'Immobili Catasto Urbano CC';

