--liquibase formatted sql 
--changeset abrandolini:20250326_152423_sam_risposte_rap_nr stripComments:false runOnChange:true 
 
create or replace procedure SAM_RISPOSTE_RAP_NR
( a_id    IN OUT    number
)
is
begin
   if a_id is null then
       begin -- Assegnazione Numero Progressivo
          select nvl(max(risposta_rap),0)+1
            into a_id
            from SAM_RISPOSTE_RAP
P          ;
       end;
    end if;
end;
/* End Procedure: SAM_RISPOSTE_RAP_NR */
/

