--liquibase formatted sql 
--changeset abrandolini:20250326_152423_imprese_arti_professioni_nr stripComments:false runOnChange:true 
 
create or replace procedure IMPRESE_ARTI_PROFESSIONI_NR
(a_pratica      IN    number,
 a_sequenza      IN OUT  number
)
is
begin
   if a_sequenza is null then
      begin -- Assegnazione Numero Progressivo
         select nvl(max(sequenza),0)+1
           into a_sequenza
           from IMPRESE_ARTI_PROFESSIONI
          where pratica      = a_pratica
         ;
      end;
   end if;
end;
/* End Procedure: IMPRESE_ARTI_PROFESSIONI_NR */
/

