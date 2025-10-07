--liquibase formatted sql 
--changeset abrandolini:20250326_152423_sogei_dic_nr stripComments:false runOnChange:true 
 
create or replace procedure SOGEI_DIC_NR
( a_progressivo      IN OUT   number
)
is
begin
   if a_progressivo is null then
       begin -- Assegnazione Numero Progressivo
          select nvl(max(progressivo),0)+1
            into a_progressivo
            from SOGEI_DIC
          ;
       end;
    end if;
end;
/* End Procedure: SOGEI_DIC_NR */
/

