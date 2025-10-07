--liquibase formatted sql 
--changeset abrandolini:20250326_152401_contribuenti_soggetti_cc stripComments:false runOnChange:true 
 
create or replace force view contribuenti_soggetti_cc as
select coso.cod_fiscale cod_fiscale
       ,nvl(sogg.cod_fiscale_ric,sogg.id_soggetto_ric) cod_fiscale_abb
   from contribuenti_cc_soggetti coso
       ,cc_soggetti sogg
  where coso.id_soggetto = sogg.id_soggetto_ric
 union
 select nvl(sogg.cod_fiscale_ric,sogg.id_soggetto_ric)
       ,nvl(sogg.cod_fiscale_ric,sogg.id_soggetto_ric)
   from cc_soggetti sogg
 union
 select cont.cod_fiscale
       ,cont.cod_fiscale
   from contribuenti cont;
comment on table CONTRIBUENTI_SOGGETTI_CC is 'CSCC - Contribuenti Soggetti CC';

