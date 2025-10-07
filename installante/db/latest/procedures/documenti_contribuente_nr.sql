--liquibase formatted sql 
--changeset abrandolini:20250326_152423_documenti_contribuente_nr stripComments:false runOnChange:true 
 
create or replace procedure DOCUMENTI_CONTRIBUENTE_NR
(a_cod_fiscale      IN varchar2,
 a_sequenza      IN OUT number
)
is
begin
   if a_sequenza is null then
      begin -- Assegnazione Numero Progressivo
         select nvl(max(sequenza),0)+1
           into a_sequenza
           from DOCUMENTI_CONTRIBUENTE
          where cod_fiscale       = a_cod_fiscale
         ;
      end;
   end if;
end;
/* End Procedure: DOCUMENTI_CONTRIBUENTE_NR */
/

