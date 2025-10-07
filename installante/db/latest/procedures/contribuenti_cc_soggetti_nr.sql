--liquibase formatted sql 
--changeset abrandolini:20250326_152423_contribuenti_cc_soggetti_nr stripComments:false runOnChange:true 
 
create or replace procedure CONTRIBUENTI_CC_SOGGETTI_NR
( a_id    IN OUT  number
)
is
begin
   if a_id is null then
       begin -- Assegnazione Numero Progressivo
          select nvl(max(id),0)+1
            into a_id
            from CONTRIBUENTI_CC_SOGGETTI
          ;
       end;
    end if;
end;
/* End Procedure: CONTRIBUENTI_CC_SOGGETTI_NR */
/

