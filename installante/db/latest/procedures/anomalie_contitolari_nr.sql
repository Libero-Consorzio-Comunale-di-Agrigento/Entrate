--liquibase formatted sql 
--changeset abrandolini:20250326_152423_anomalie_contitolari_nr stripComments:false runOnChange:true 
 
create or replace procedure ANOMALIE_CONTITOLARI_NR
( a_progressivo      IN OUT   number
)
is
begin
   if a_progressivo is null then
       begin -- Assegnazione Numero Progressivo
          select nvl(max(progressivo),0)+1
            into a_progressivo
            from ANOMALIE_CONTITOLARI
          ;
       end;
    end if;
end;
/* End Procedure: ANOMALIE_CONTITOLARI_NR */
/

