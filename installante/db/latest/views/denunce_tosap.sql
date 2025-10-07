--liquibase formatted sql 
--changeset abrandolini:20250326_152401_denunce_tosap stripComments:false runOnChange:true 
 
create or replace force view denunce_tosap as
select PRATICHE_TRIBUTO.PRATICA, PRATICHE_TRIBUTO.UTENTE,
PRATICHE_TRIBUTO.DATA_VARIAZIONE, PRATICHE_TRIBUTO.NOTE
from PRATICHE_TRIBUTO
where PRATICHE_TRIBUTO.TIPO_TRIBUTO = 'TOSAP'
and PRATICHE_TRIBUTO.TIPO_PRATICA = 'D'
with check option;
comment on table DENUNCE_TOSAP is 'DETO - Denunce TOSAP';

