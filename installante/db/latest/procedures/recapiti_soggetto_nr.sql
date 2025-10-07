--liquibase formatted sql 
--changeset abrandolini:20250326_152423_recapiti_soggetto_nr stripComments:false runOnChange:true 
 
create or replace procedure RECAPITI_SOGGETTO_NR
( a_id_recapito   IN OUT   number
)
is
begin
   if a_id_recapito is null then
       begin -- Assegnazione Numero Progressivo
          select nvl(max(id_recapito),0)+1
            into a_id_recapito
            from RECAPITI_SOGGETTO
          ;
       end;
    end if;
end;
/* End Procedure: RECAPITI_SOGGETTO_NR */
/

