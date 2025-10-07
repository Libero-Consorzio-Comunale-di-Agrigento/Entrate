--liquibase formatted sql 
--changeset abrandolini:20250326_152423_crediti_ravvedimento_nr stripComments:false runOnChange:true 
 
create or replace procedure CREDITI_RAVVEDIMENTO_NR
(a_pratica      IN number,
 a_sequenza      IN OUT number
)
is
begin
   if a_sequenza is null then
      begin -- Assegnazione Numero Progressivo
         select nvl(max(sequenza),0)+1
           into a_sequenza
           from CREDITI_RAVVEDIMENTO
          where pratica    = a_pratica
         ;
      end;
   end if;
end;
/* End Procedure: CREDITI_RAVVEDIMENTO_NR */
/
