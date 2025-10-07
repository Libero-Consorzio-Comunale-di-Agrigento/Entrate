--liquibase formatted sql 
--changeset abrandolini:20250326_152423_ALLEGATI_TESTO_NR stripComments:false runOnChange:true 
 
CREATE OR REPLACE procedure ALLEGATI_TESTO_NR
(a_comunicazione_testo in number,
 a_sequenza            in out number) is
begin
  if a_sequenza is null then
    begin
      -- Assegnazione Numero Progressivo
      select nvl(max(sequenza), 0) + 1
        into a_sequenza
        from allegati_testo
       where comunicazione_testo = a_comunicazione_testo;
    end;
  end if;
end;
/* End Procedure: ALLEGATI_TESTO_NR */
/
