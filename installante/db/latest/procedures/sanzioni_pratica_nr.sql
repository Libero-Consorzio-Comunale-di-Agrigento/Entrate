--liquibase formatted sql 
--changeset abrandolini:20250326_152423_sanzioni_pratica_nr stripComments:false runOnChange:true 
 
CREATE OR REPLACE procedure SANZIONI_PRATICA_NR
(a_pratica        IN number,
 a_cod_sanzione        IN number,
 a_sequenza_SANZ             IN number,
 a_sequenza        IN OUT number
)
is
begin
   if a_sequenza is null then
      begin -- Assegnazione Numero Progressivo
         select nvl(max(sequenza),0)+1
           into a_sequenza
           from SANZIONI_PRATICA
          where pratica     = a_pratica
            and cod_sanzione       = a_cod_sanzione
            and sequenza_sanz   = nvl(a_sequenza_sanz,1)
         ;
      end;
   end if;
end;
/* End Procedure: SANZIONI_PRATICA_NR */
/
