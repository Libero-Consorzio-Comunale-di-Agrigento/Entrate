--liquibase formatted sql
--changeset abrandolini:20250331_123138_f_unita_territoriale_TR4 stripComments:false context:"TRT2 or TRV4"
--validCheckSum: 1:any

create or replace function F_UNITA_TERRITORIALE
	(a_unita_territoriale number,
     a_cod_via            number,
     a_num_civ            number,
     a_suffisso           varchar2
	 )

return varchar2

IS
begin
  return '-1';
end;
/
