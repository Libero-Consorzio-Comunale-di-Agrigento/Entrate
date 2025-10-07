--liquibase formatted sql 
--changeset abrandolini:20250326_152423_successioni_defunti_nr stripComments:false runOnChange:true 
 
create or replace procedure SUCCESSIONI_DEFUNTI_NR
( a_successione   IN OUT   number
)
is
cursor_name    integer;
ret      integer;
begin -- Assegnazione Numero Progressivo
   if a_successione is null then
--      cursor_name    := dbms_sql.OPEN_CURSOR;
--      dbms_sql.parse(cursor_name, 'lock table SUCCESSIONI_DEFUNTI in exclusive mode', dbms_sql.native);
--      ret       := dbms_sql.execute(cursor_name);
--      dbms_sql.close_cursor(cursor_name);
       begin -- Assegnazione Numero Progressivo
          select nvl(max(successione),0)+1
            into a_successione
            from SUCCESSIONI_DEFUNTI
          ;
       end;
    end if;
end;
/* End Procedure: SUCCESSIONI_DEFUNTI_NR */
/

