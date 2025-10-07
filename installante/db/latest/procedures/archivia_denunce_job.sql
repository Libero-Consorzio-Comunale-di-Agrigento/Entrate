--liquibase formatted sql 
--changeset abrandolini:20250326_152423_archivia_denunce_job stripComments:false runOnChange:true 
 
create or replace procedure ARCHIVIA_DENUNCE_JOB
is
begin
  archivia_denunce('ICI','','');
  archivia_denunce('TASI','','');
  commit;
end;
/* End Procedure: ARCHIVIA_DENUNCE_JOB */
/

