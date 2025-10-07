--liquibase formatted sql 
--changeset abrandolini:20250326_152423_rate_imposta_nr stripComments:false runOnChange:true 
 
create or replace procedure RATE_IMPOSTA_NR
( a_rata_imposta   IN OUT   number
)
is
begin
   if a_rata_imposta is null then
       begin -- Assegnazione Numero Progressivo
          select nvl(max(rata_imposta),0)+1
            into a_rata_imposta
            from RATE_IMPOSTA
          ;
       end;
    end if;
end;
/* End Procedure: RATE_IMPOSTA_NR */
/

