--liquibase formatted sql 
--changeset abrandolini:20250326_152423_redditi_riferimento_nr stripComments:false runOnChange:true 
 
create or replace procedure REDDITI_RIFERIMENTO_NR
(a_pratica      IN    number,
 a_sequenza      IN OUT  number
)
is
begin
   if a_sequenza is null then
      begin -- Assegnazione Numero Progressivo
         select nvl(max(sequenza),0)+1
           into a_sequenza
           from REDDITI_RIFERIMENTO
          where pratica      = a_pratica
         ;
      end;
   end if;
end;
/* End Procedure: REDDITI_RIFERIMENTO_NR */
/

