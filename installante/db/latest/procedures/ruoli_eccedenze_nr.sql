--liquibase formatted sql 
--changeset abrandolini:20250326_152423_ruoli_eccedenze_nr stripComments:false runOnChange:true 
 
create or replace procedure RUOLI_ECCEDENZE_NR
( a_id      IN OUT   number
)
is
begin
   if a_id is null then
       begin -- Assegnazione Numero Progressivo
          select nvl(max(id_eccedenza),0)+1
            into a_id
            from RUOLI_ECCEDENZE
          ;
       end;
    end if;
end;
/* End Procedure: RUOLI_ECCEDENZE_NR */
/
