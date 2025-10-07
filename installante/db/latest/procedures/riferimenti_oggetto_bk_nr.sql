--liquibase formatted sql 
--changeset abrandolini:20250326_152423_riferimenti_oggetto_bk_nr stripComments:false runOnChange:true 
 
create or replace procedure RIFERIMENTI_OGGETTO_BK_NR
(a_oggetto      IN    number,
 a_inizio_validita      IN      date,
 a_sequenza      IN OUT  number
)
is
begin
   if a_sequenza is null then
      begin -- Assegnazione Numero Progressivo
         select nvl(max(sequenza),0)+1
           into a_sequenza
           from RIFERIMENTI_OGGETTO_BK
          where oggetto      = a_oggetto
            and inizio_validita = a_inizio_validita
         ;
      end;
   end if;
end;
/* End Procedure: RIFERIMENTI_OGGETTO_BK_NR */
/

