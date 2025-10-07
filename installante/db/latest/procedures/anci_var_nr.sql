--liquibase formatted sql 
--changeset abrandolini:20250326_152423_anci_var_nr stripComments:false runOnChange:true 
 
create or replace procedure ANCI_VAR_NR
( a_progressivo      IN OUT   number
)
is
begin
   if a_progressivo is null then
       begin -- Assegnazione Numero Progressivo
          select nvl(max(progressivo),0)+1
            into a_progressivo
            from ANCI_VAR
          ;
       end;
    end if;
end;
/* End Procedure: ANCI_VAR_NR */
/

