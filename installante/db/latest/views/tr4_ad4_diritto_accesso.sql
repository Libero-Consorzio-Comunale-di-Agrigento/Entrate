--liquibase formatted sql 
--changeset abrandolini:20250326_152401_tr4_ad4_diritto_accesso stripComments:false runOnChange:true 
 
create or replace force view tr4_ad4_diritto_accesso as
select rownum diritto_accesso, diac."UTENTE",diac."MODULO",diac."ISTANZA",diac."RUOLO",diac."SEQUENZA",diac."ULTIMO_ACCESSO",diac."NUMERO_ACCESSI",diac."GRUPPO",diac."NOTE"
  from ad4_diritti_accesso diac
 where istanza like 'TR4%';
comment on table TR4_AD4_DIRITTO_ACCESSO is 'TADA - TR4_AD4_DIRITTO_ACCESSO';

