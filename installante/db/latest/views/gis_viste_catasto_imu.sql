--liquibase formatted sql 
--changeset abrandolini:20250326_152401_gis_viste_catasto_imu stripComments:false runOnChange:true 
 
create or replace force view gis_viste_catasto_imu as
select 3 tipo_oggetto, sezione, foglio, numero, subalterno
  from immobili_catasto_urbano icur
 where exists (select 1
                 from oggetti ogge
                    , oggetti_ici ogic
                where ogge.estremi_catasto  = icur.estremi_catasto
                  and ogge.oggetto = ogic.oggetto)
   and data_fine_efficacia is null
   and partita not in ('0000000','C')
union
select 1 tipo_oggetto, sezione, foglio, numero, subalterno
  from immobili_catasto_terreni icte
 where exists (select 1
                 from oggetti ogge
                    , oggetti_ici ogic
                where ogge.estremi_catasto = icte.estremi_catasto
                  and ogge.oggetto = ogic.oggetto)
   and data_fine_efficacia is null
   and partita not in ('0000000','C')
with check option;
comment on table GIS_VISTE_CATASTO_IMU is 'GIS Viste catasto IMU';

