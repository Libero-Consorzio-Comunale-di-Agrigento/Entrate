--liquibase formatted sql 
--changeset abrandolini:20250326_152423_SANZIONI_NR stripComments:false runOnChange:true 
 
CREATE OR REPLACE procedure SANZIONI_NR
(a_tipo_tributo		IN varchar2,
 a_cod_sanzione		IN number,
 a_sequenza		IN OUT number
)
is
begin
   if a_sequenza is null then
      begin -- Assegnazione Numero Progressivo
         select nvl(max(sequenza),0)+1
           into a_sequenza
           from SANZIONI
          where tipo_tributo 	= a_tipo_tributo
            and cod_sanzione	= a_cod_sanzione
         ; 
      end;
   end if;
end;
/* End Procedure: SANZIONI_NR */
/
