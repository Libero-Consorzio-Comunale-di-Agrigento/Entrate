--liquibase formatted sql 
--changeset abrandolini:20250326_152423_anomalie_parametri_nr stripComments:false runOnChange:true 
 
create or replace procedure ANOMALIE_PARAMETRI_NR
( a_id_anomalia_parametro   IN OUT   number
)
is
begin
   if a_id_anomalia_parametro is null then
       begin -- Assegnazione Numero Progressivo
          select nvl(max(id_anomalia_parametro),0)+1
            into a_id_anomalia_parametro
            from ANOMALIE_PARAMETRI
          ;
       end;
    end if;
end;
/* End Procedure: ANOMALIE_PARAMETRI_NR */
/

