--liquibase formatted sql 
--changeset abrandolini:20250326_152401_gis_pulisci_viste_imu stripComments:false runOnChange:true 
 
create or replace force view gis_pulisci_viste_imu as
select 1 tipo_oggetto, '*' sezione, '*' foglio, '*' numero, '*' subalterno
  from dual
union
select 3 tipo_oggetto, '*' sezione, '*' foglio, '*' numero, '*' subalterno
  from dual
with check option;
comment on table GIS_PULISCI_VISTE_IMU is 'GIS_PULISCI_VISTE_IMU';

