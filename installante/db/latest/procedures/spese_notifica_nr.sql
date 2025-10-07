--liquibase formatted sql 
--changeset abrandolini:20250326_152423_spese_notifica_nr stripComments:false runOnChange:true 
 
create or replace procedure SPESE_NOTIFICA_NR
(a_tipo_tributo      IN    varchar2,
 a_sequenza      IN OUT  number
)
is
begin
   if a_sequenza is null then
      begin -- Assegnazione Numero Progressivo
         select nvl(max(sequenza),0)+1
           into a_sequenza
           from SPESE_NOTIFICA
          where tipo_tributo   = a_tipo_tributo
         ;
      end;
   end if;
end;
/* End Procedure: SPESE_NOTIFICA_NR */
/
