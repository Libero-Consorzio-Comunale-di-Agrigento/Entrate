--liquibase formatted sql 
--changeset abrandolini:20250326_152423_eventi_nr stripComments:false runOnChange:true 
 
create or replace procedure EVENTI_NR
(a_tipo_evento      IN    varchar2,
 a_sequenza      IN OUT  number
)
is
begin
   if a_sequenza is null then
      begin -- Assegnazione Numero Progressivo
         select nvl(max(sequenza),0)+1
           into a_sequenza
           from EVENTI
          where tipo_evento = a_tipo_evento
         ;
      end;
   end if;
end;
/* End Procedure: EVENTI_NR */
/

