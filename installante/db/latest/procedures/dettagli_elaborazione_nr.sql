--liquibase formatted sql 
--changeset abrandolini:20250326_152423_dettagli_elaborazione_nr stripComments:false runOnChange:true 
 
create or replace procedure DETTAGLI_ELABORAZIONE_NR
(a_id in out number) is
begin
  if a_id is null then
    begin
      -- Assegnazione Numero Progressivo
      select nvl(max(dettaglio_id), 0) + 1
        into a_id
        from dettagli_elaborazione;
    end;
  end if;
end;
/* End Procedure: DETTAGLI_ELABORAZIONE_NR */
/

