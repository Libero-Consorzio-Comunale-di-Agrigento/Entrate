--liquibase formatted sql 
--changeset abrandolini:20250326_152423_sam_risposte_nr stripComments:false runOnChange:true 
 
create or replace procedure SAM_RISPOSTE_NR
( a_id    IN OUT    number
)
is
begin
   if a_id is null then
       begin -- Assegnazione Numero Progressivo
          select nvl(max(risposta_interrogazione),0)+1
            into a_id
            from SAM_RISPOSTE
          ;
       end;
    end if;
end;
/* End Procedure: SAM_RISPOSTE_NR */
/

