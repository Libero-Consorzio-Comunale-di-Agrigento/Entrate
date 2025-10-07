--liquibase formatted sql 
--changeset abrandolini:20250326_152423_compensazioni_nr stripComments:false runOnChange:true 
 
create or replace procedure COMPENSAZIONI_NR
( a_id_compensazione   IN OUT   number
)
is
begin
   if a_id_compensazione is null then
       begin -- Assegnazione Numero Progressivo
          select nvl(max(id_compensazione),0)+1
            into a_id_compensazione
            from COMPENSAZIONI
          ;
       end;
    end if;
end;
/* End Procedure: COMPENSAZIONI_NR */
/

