--liquibase formatted sql 
--changeset abrandolini:20250326_152401_proprietari_catasto_urbano_cc stripComments:false runOnChange:true 
 
create or replace force view proprietari_catasto_urbano_cc as
select --distinct
  tito.id_immobile
   , sogg.id_soggetto_ric id_soggetto
   , sogg.sesso sesso
   , nvl (sogg.tipo_soggetto, sogg.tipo_soggetto_2) tipo_soggetto
   , cognome_nome_ric cognome_nome
   , decode (nvl (sogg.tipo_soggetto, sogg.tipo_soggetto_2)
  , 'P', f_adatta_data (sogg.data_nascita)
  , to_date (null))
   data_nas
   , decode (
   nvl (sogg.tipo_soggetto, sogg.tipo_soggetto_2)
 , 'P', f_get_dati_belfiore(sogg.luogo_nascita,f_adatta_data (sogg.data_nascita),'C')
 --decode (stat_nas.denominazione
  --, '', comu_nas.denominazione
  --, stat_nas.denominazione)
 , '')
   des_com_nas
   , decode (nvl (sogg.tipo_soggetto, sogg.tipo_soggetto_2)
  , 'P', f_get_dati_belfiore(sogg.luogo_nascita,f_adatta_data (sogg.data_nascita),'P')
 -- prov_nas.sigla
  , '')
   sigla_pro_nas
   , sogg.cod_fiscale_ric cod_fiscale
   , decode (nvl (sogg.tipo_soggetto, sogg.tipo_soggetto_2)
  , 'P', ''
  , comu_sed.denominazione)
   des_com_sede
   , decode (nvl (sogg.tipo_soggetto, sogg.tipo_soggetto_2)
  , 'P', ''
  , prov_sed.sigla)
   sigla_pro_sede
   , ltrim (tito.codice_diritto) cod_titolo
   , rtrim (ltrim (diri.descrizione)) des_diritto
   , rtrim (ltrim (ltrim (tito.quota_numeratore, '0'))) numeratore
   , rtrim (ltrim (ltrim (tito.quota_denominatore, '0'))) denominatore
   , rtrim (ltrim (tito.titolo_non_codificato)) des_titolo
   , f_adatta_data (data_validita) data_validita
   , f_adatta_data (data_validita_2) data_fine_validita
   , tito.tipo_immobile
   , tito.partita
   , tito.regime
   , tito.soggetto_riferimento
   , tito.tipo_nota
   , tito.numero_nota
   , tito.progressivo_nota
   , tito.anno_nota
   , f_adatta_data (tito.data_registrazione_atti) data_registrazione_atti
   , tito.tipo_nota_2
   , tito.numero_nota_2
   , tito.progressivo_nota_2
   , tito.anno_nota_2
   , f_adatta_data (tito.data_registrazione_atti_2)
   data_registrazione_atti_2
   , tito.id_mutazione_iniziale
   , tito.id_mutazione_finale
   , tito.id_titolarita
   , tito.cod_causale_atto_generante
   , tito.des_atto_generante
   , tito.cod_causale_atto_conclusivo
   , tito.des_atto_conclusivo
   , sogg.cognome_nome_ric cognome_nome_ric
   , sogg.cod_fiscale_ric cod_fiscale_ric
   , sogg.id_soggetto_ric id_soggetto_ric
   from --ad4_stati_territori stat_nas
 --  , ad4_comuni comu_nas
   --, ad4_provincie prov_nas
   --,
 ad4_comuni comu_sed
   , ad4_provincie prov_sed
   , cc_diritti diri
   , cc_titolarita tito
   , cc_soggetti sogg
  where --stat_nas.stato_territorio(+) = comu_nas.provincia_stato
 --and comu_nas.sigla_cfis(+) = sogg.luogo_nascita
 --and prov_nas.provincia(+) = comu_nas.provincia_stato
 --and
 comu_sed.sigla_cfis(+) = sogg.sede
 and prov_sed.provincia(+) = comu_sed.provincia_stato
 and diri.codice_diritto(+) = tito.codice_diritto
 and tito.id_soggetto = sogg.id_soggetto_ric
 and tito.tipo_soggetto = nvl(sogg.tipo_soggetto,sogg.tipo_soggetto_2)
 and ( (sogg.tipo_soggetto = 'P'
-- and nvl (comu_nas.data_soppressione, to_date ('31122999', 'ddmmyyyy')) =
--   (select min (
--   nvl (comx.data_soppressione
--   , to_date ('31122999', 'ddmmyyyy')))
--   from ad4_comuni comx
--  where comx.sigla_cfis = sogg.luogo_nascita
-- and nvl (comx.data_soppressione
--  , to_date ('31122999', 'ddmmyyyy')) >=
--   f_adatta_data (sogg.data_nascita))
)
   or  (sogg.tipo_soggetto_2 = 'G'
 and comu_sed.data_soppressione is null))
;
comment on table PROPRIETARI_CATASTO_URBANO_CC is 'Proprietari Catasto Urbano CC';

