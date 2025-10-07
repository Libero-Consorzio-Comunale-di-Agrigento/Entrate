--liquibase formatted sql 
--changeset abrandolini:20250326_152423_ruoli_nr stripComments:false runOnChange:true 
 
create or replace procedure RUOLI_NR
( a_ruolo   IN OUT   number
)
is
begin
   if a_ruolo is null then
       begin -- Assegnazione Numero Progressivo
          select nvl(max(ruolo),0)+1
            into a_ruolo
            from RUOLI
          ;
       end;
    end if;
end;
/* End Procedure: RUOLI_NR */
/

