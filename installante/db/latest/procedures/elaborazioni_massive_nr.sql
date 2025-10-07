--liquibase formatted sql 
--changeset abrandolini:20250326_152423_elaborazioni_massive_nr stripComments:false runOnChange:true 
 
create or replace procedure ELABORAZIONI_MASSIVE_NR
(a_id in out number) is
begin
  if a_id is null then
    begin
      -- Assegnazione Numero Progressivo
      select nvl(max(elaborazione_id), 0) + 1
        into a_id
        from elaborazioni_massive;
    end;
  end if;
end;
/* End Procedure: ELABORAZIONI_MASSIVE_NR */
/

