--liquibase formatted sql 
--changeset abrandolini:20250326_152423_civici_oggetto_nr stripComments:false runOnChange:true 
 
create or replace procedure CIVICI_OGGETTO_NR
(a_oggetto      IN    number,
 a_sequenza      IN OUT  number
)
is
begin
   if a_sequenza is null then
      begin -- Assegnazione Numero Progressivo
         select nvl(max(sequenza),0)+1
           into a_sequenza
           from CIVICI_OGGETTO
          where oggetto      = a_oggetto
         ;
      end;
   end if;
end;
/* End Procedure: CIVICI_OGGETTO_NR */
/

