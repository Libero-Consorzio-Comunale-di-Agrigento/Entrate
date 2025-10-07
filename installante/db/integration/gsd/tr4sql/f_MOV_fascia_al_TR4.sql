--liquibase formatted sql
--changeset abrandolini:20250331_123138_f_MOV_fascia_al_TR4 stripComments:false context:"TRT2 or TRV4"
--validCheckSum: 1:any

create or replace function F_MOV_FASCIA_AL
	(a_matricola		number,
	 a_data_rif		number)

return varchar2

IS
begin
  return '-1';
end;
/
