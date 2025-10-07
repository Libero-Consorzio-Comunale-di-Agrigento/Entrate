--liquibase formatted sql 
--changeset abrandolini:20250326_152423_scadenze_nr stripComments:false runOnChange:true 
 
create or replace procedure SCADENZE_NR
(a_tipo_tributo      IN    varchar2,
 a_anno         IN   number,
 a_sequenza      IN OUT  number
)
is
begin
   if a_sequenza is null then
      begin -- Assegnazione Numero Progressivo
         select nvl(max(sequenza),0)+1
           into a_sequenza
           from SCADENZE
          where tipo_tributo   = a_tipo_tributo
         and anno      = a_anno
         ;
      end;
   end if;
end;
/* End Procedure: SCADENZE_NR */
/

