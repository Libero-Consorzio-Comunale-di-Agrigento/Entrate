--liquibase formatted sql 
--changeset abrandolini:20250326_152423_soggetti_nr stripComments:false runOnChange:true 
 
create or replace procedure SOGGETTI_NR
( a_ni      IN OUT   number
)
is
begin
   if a_ni is null then
       begin -- Assegnazione Numero Progressivo
          select nvl(max(ni),0)+1
            into a_ni
            from SOGGETTI
          ;
       end;
    end if;
end;
/* End Procedure: SOGGETTI_NR */
/

