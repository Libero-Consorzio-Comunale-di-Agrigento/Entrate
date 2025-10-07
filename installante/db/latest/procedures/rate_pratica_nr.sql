--liquibase formatted sql 
--changeset abrandolini:20250326_152423_rate_pratica_nr stripComments:false runOnChange:true 
 
create or replace procedure RATE_PRATICA_NR
( a_rata_pratica   IN OUT   number
)
is
begin
   if a_rata_pratica is null then
       begin -- Assegnazione Numero Progressivo
          select nvl(max(rata_pratica),0)+1
            into a_rata_pratica
            from RATE_PRATICA
          ;
       end;
    end if;
end;
/* End Procedure: RATE_PRATICA_NR */
/

