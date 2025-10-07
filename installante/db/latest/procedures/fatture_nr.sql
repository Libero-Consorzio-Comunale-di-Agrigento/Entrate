--liquibase formatted sql 
--changeset abrandolini:20250326_152423_fatture_nr stripComments:false runOnChange:true 
 
create or replace procedure FATTURE_NR
( a_fattura   IN OUT   number
)
is
begin
   if a_fattura is null then
       begin -- Assegnazione Numero Progressivo
          select nvl(max(fattura),0)+1
            into a_fattura
            from FATTURE
          ;
       end;
    end if;
end;
/* End Procedure: FATTURE_NR */
/

