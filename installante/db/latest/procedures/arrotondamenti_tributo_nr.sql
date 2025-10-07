--liquibase formatted sql 
--changeset abrandolini:20250326_152423_arrotondamenti_tributo_nr stripComments:false runOnChange:true 
 
create or replace procedure ARROTONDAMENTI_TRIBUTO_NR
(a_tributo      IN number,
 a_sequenza      IN OUT number
)
is
begin
   if a_sequenza is null then
      begin -- Assegnazione Numero Progressivo
         select nvl(max(sequenza),0)+1
           into a_sequenza
           from ARROTONDAMENTI_TRIBUTO
          where tributo     = a_tributo
         ;
      end;
   end if;
end;
/* End Procedure: ARROTONDAMENTI_TRIBUTO_NR */
/

