--liquibase formatted sql 
--changeset abrandolini:20250326_152423_comunicazione_testi_nr stripComments:false runOnChange:true 
 
create or replace procedure COMUNICAZIONE_TESTI_NR
(a_id in out number) is
begin
  if a_id is null then
    begin
      -- Assegnazione Numero Progressivo
      select nvl(max(comunicazione_testo), 0) + 1
        into a_id
        from comunicazione_testi;
    end;
  end if;
end;
/* End Procedure: COMUNICAZIONE_TESTI_NR */
/
