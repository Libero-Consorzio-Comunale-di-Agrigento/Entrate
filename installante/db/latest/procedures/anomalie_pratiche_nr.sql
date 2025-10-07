--liquibase formatted sql 
--changeset abrandolini:20250326_152423_anomalie_pratiche_nr stripComments:false runOnChange:true 
 
create or replace procedure ANOMALIE_PRATICHE_NR
( a_id_anomalia_pratica   IN OUT   number
)
is
begin
   if a_id_anomalia_pratica is null then
       begin -- Assegnazione Numero Progressivo
          select nvl(max(id_anomalia_pratica),0)+1
            into a_id_anomalia_pratica
            from ANOMALIE_PRATICHE
          ;
       end;
    end if;
end;
/* End Procedure: ANOMALIE_PRATICHE_NR */
/

