--liquibase formatted sql 
--changeset abrandolini:20250326_152423_sam_interrogazioni_nr stripComments:false runOnChange:true 
 
create or replace procedure SAM_INTERROGAZIONI_NR
( a_id    IN OUT    number
)
is
begin
   if a_id is null then
       begin -- Assegnazione Numero Progressivo
          select nvl(max(interrogazione),0)+1
            into a_id
            from SAM_INTERROGAZIONI
          ;
       end;
    end if;
end;
/* End Procedure: SAM_INTERROGAZIONI_NR */
/

