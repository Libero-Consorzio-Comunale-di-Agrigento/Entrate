--liquibase formatted sql 
--changeset abrandolini:20250326_152401_proprietari_anagrafe_catasto stripComments:false runOnChange:true 
 
create or replace force view proprietari_anagrafe_catasto as
select decode(nvl(ccso.tipo_soggetto, ccso.tipo_soggetto_2)
  ,'P',ccso.codice_amm
  ,ccso.codice_amm_2) codice_amm
 ,decode(nvl(ccso.tipo_soggetto, ccso.tipo_soggetto_2)
  ,'P',ccso.sezione_amm
  ,ccso.sezione_amm) sezione_amm
 ,ccso.id_soggetto_ric id_soggetto
 ,nvl(ccso.tipo_soggetto, ccso.tipo_soggetto_2) tipo_soggetto
 ,ccso.cognome
 ,ccso.nome
 ,ccso.sesso
 ,f_adatta_data(ccso.data_nascita) data_nascita
 ,ccso.luogo_nascita
 ,ccso.cod_fiscale_ric codice_fiscale
 ,ccso.indicazioni_supplementari
 ,ccso.denominazione
 ,ccso.sede
 ,ccso.id_soggetto_ric
 ,ccso.cognome_nome_ric
 ,ccso.cod_fiscale_ric
 ,ccso.documento_id
 ,ccso.utente
 ,ccso.data_variazione
 ,decode(stat_nas.denominazione, '', comu_nas.denominazione, stat_nas.denominazione) des_comune_nas
 ,prov_nas.sigla sigla_provincia_nas
 ,comu_sd.denominazione des_comune_sede
 ,prov_sd.sigla sigla_provincia_sede
   from cc_soggetti ccso
 ,ad4_stati_territori stat_nas
 ,ad4_provincie prov_nas
 ,ad4_comuni comu_nas
 ,ad4_provincie prov_sd
 ,ad4_comuni comu_sd
  where ccso.luogo_nascita = comu_nas.sigla_cfis(+)
 and comu_nas.provincia_stato = stat_nas.stato_territorio(+)
 and comu_nas.provincia_stato = prov_nas.provincia(+)
 and ccso.sede = comu_sd.sigla_cfis(+)
 and prov_sd.provincia(+) = comu_sd.provincia_stato
 and ((ccso.tipo_soggetto = 'P' and
   nvl(comu_nas.data_soppressione,to_date('31122999','DDMMYYYY')) =
   (select min(nvl(comx_nas.data_soppressione,to_date('31122999','DDMMYYYY')))
   from ad4_comuni comx_nas
  where comx_nas.sigla_cfis = ccso.luogo_nascita
 and nvl(comx_nas.data_soppressione,to_date('31122999','ddmmyyyy')) >=
  f_adatta_data(ccso.data_nascita))
   ) or
   (ccso.tipo_soggetto_2 = 'G' and
 comu_sd.data_soppressione is null
   )
  );
comment on table PROPRIETARI_ANAGRAFE_CATASTO is 'proprietari_anagrafe_catasto';

