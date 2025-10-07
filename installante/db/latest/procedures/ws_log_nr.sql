--liquibase formatted sql 
--changeset abrandolini:20250326_152423_ws_log_nr stripComments:false runOnChange:true 
 
create or replace procedure WS_LOG_NR
( a_id      IN OUT   number
)
is
begin
   if a_id is null then
       begin -- Assegnazione Numero Progressivo
          select nvl(max(id),0)+1
            into a_id
            from WS_LOG
          ;
       end;
    end if;
end;
/* End Procedure: WS_LOG_NR */
/
