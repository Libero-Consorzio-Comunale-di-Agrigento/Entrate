--liquibase formatted sql 
--changeset abrandolini:20250326_152423_anomalie_ici_nr stripComments:false runOnChange:true 
 
create or replace procedure ANOMALIE_ICI_NR
( a_anomalia   IN OUT   number
)
is
begin
   if a_anomalia is null then
       begin -- Assegnazione Numero Progressivo
          select nvl(max(anomalia),0)+1
            into a_anomalia
            from ANOMALIE_ICI
          ;
       end;
    end if;
end;
/* End Procedure: ANOMALIE_ICI_NR */
/

