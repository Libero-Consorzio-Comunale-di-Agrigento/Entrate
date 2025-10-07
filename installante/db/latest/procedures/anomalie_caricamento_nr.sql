--liquibase formatted sql 
--changeset abrandolini:20250326_152423_anomalie_caricamento_nr stripComments:false runOnChange:true 
 
create or replace procedure ANOMALIE_CARICAMENTO_NR
(a_documento_id      IN    number,
 a_sequenza      IN OUT  number
)
is
begin
   if a_sequenza is null then
      begin -- Assegnazione Numero Progressivo
         select nvl(max(sequenza),0)+1
           into a_sequenza
           from ANOMALIE_CARICAMENTO
          where documento_id   = a_documento_id
         ;
      end;
   end if;
end;
/* End Procedure: ANOMALIE_CARICAMENTO_NR */
/

