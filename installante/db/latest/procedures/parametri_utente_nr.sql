--liquibase formatted sql 
--changeset abrandolini:20250326_152423_parametri_utente_nr stripComments:false runOnChange:true 
 
create or replace procedure PARAMETRI_UTENTE_NR
(a_id in out number) is
begin
  if a_id is null then
    begin
      -- Assegnazione Numero Progressivo
      select nvl(max(id), 0) + 1
        into a_id
        from parametri_utente;
    end;
  end if;
end;
/* End Procedure: PARAMETRI_UTENTE_NR */
/

