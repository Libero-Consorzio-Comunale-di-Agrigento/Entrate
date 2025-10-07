--liquibase formatted sql 
--changeset abrandolini:20250326_152423_partizioni_oggetto_pratica_nr stripComments:false runOnChange:true 
 
create or replace procedure PARTIZIONI_OGGETTO_PRATICA_NR
(a_oggetto_pratica   IN    number,
 a_sequenza      IN OUT  number
)
is
begin
   if a_sequenza is null then
      begin -- Assegnazione Numero Progressivo
         select nvl(max(sequenza),0)+1
           into a_sequenza
           from PARTIZIONI_OGGETTO_PRATICA
          where oggetto_pratica   = a_oggetto_pratica
            and a_sequenza    is null
         ;
      end;
   end if;
end;
/* End Procedure: PARTIZIONI_OGGETTO_PRATICA_NR */
/

