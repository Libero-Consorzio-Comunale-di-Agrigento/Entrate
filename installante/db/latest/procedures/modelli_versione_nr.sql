--liquibase formatted sql 
--changeset abrandolini:20250326_152423_modelli_versione_nr stripComments:false runOnChange:true 
 
create or replace procedure MODELLI_VERSIONE_NR
(a_versione_id      IN OUT  number
)
is
begin
   if a_versione_id is null then
      begin -- Assegnazione Numero Progressivo
         select nvl(max(versione_id),0)+1
           into a_versione_id
           from MODELLI_VERSIONE
         ;
      end;
   end if;
end;
/* End Procedure: MODELLI_VERSIONE_NR */
/

