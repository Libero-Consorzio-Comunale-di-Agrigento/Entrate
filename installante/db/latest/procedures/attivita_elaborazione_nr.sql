--liquibase formatted sql 
--changeset abrandolini:20250326_152423_attivita_elaborazione_nr stripComments:false runOnChange:true 
 
create or replace procedure ATTIVITA_ELABORAZIONE_NR
(a_id in out number) is
begin
  if a_id is null then
    begin
      -- Assegnazione Numero Progressivo
      select nvl(max(attivita_id), 0) + 1
        into a_id
        from attivita_elaborazione;
    end;
  end if;
end;
/* End Procedure: ATTIVITA_ELABORAZIONE_NR */
/

