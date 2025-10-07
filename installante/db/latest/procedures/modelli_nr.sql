--liquibase formatted sql 
--changeset abrandolini:20250326_152423_modelli_nr stripComments:false runOnChange:true 
 
create or replace procedure MODELLI_NR
(a_modello      IN OUT  number
)
is
begin
   if a_modello is null then
      begin -- Assegnazione Numero Progressivo
         select nvl(max(modello),0)+1
           into a_modello
           from MODELLI
         ;
      end;
   end if;
end;
/* End Procedure: MODELLI_NR */
/

