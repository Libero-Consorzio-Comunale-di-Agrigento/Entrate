--liquibase formatted sql 
--changeset abrandolini:20250326_152401_denunce_tarsu stripComments:false runOnChange:true 
 
create or replace force view denunce_tarsu as
select PRATICHE_TRIBUTO.PRATICA, PRATICHE_TRIBUTO.UTENTE,
PRATICHE_TRIBUTO.DATA_VARIAZIONE, PRATICHE_TRIBUTO.NOTE
from PRATICHE_TRIBUTO
where PRATICHE_TRIBUTO.TIPO_TRIBUTO = 'TARSU'
and PRATICHE_TRIBUTO.TIPO_PRATICA = 'D'
with check option;
comment on table DENUNCE_TARSU is 'DETA - Denunce TARSU';

