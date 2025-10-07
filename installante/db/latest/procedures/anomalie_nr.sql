--liquibase formatted sql 
--changeset abrandolini:20250326_152423_anomalie_nr stripComments:false runOnChange:true 
 
create or replace procedure ANOMALIE_NR
( a_id_anomalia   IN OUT   number
)
is
begin
   if a_id_anomalia is null then
       begin -- Assegnazione Numero Progressivo
          select nvl(max(id_anomalia),0)+1
            into a_id_anomalia
            from ANOMALIE
          ;
       end;
    end if;
end;
/* End Procedure: ANOMALIE_NR */
/

