--liquibase formatted sql 
--changeset abrandolini:20250326_152423_PRATICHE_TRIBUTO_NR stripComments:false runOnChange:true 
 
CREATE OR REPLACE procedure PRATICHE_TRIBUTO_NR
( a_pratica	IN OUT	number
)
is
cursor_name 	integer;
ret		integer;
begin -- Assegnazione Numero Progressivo
   if a_pratica is null then

--      cursor_name 	:= dbms_sql.OPEN_CURSOR;
--      dbms_sql.parse(cursor_name, 'lock table PRATICHE_TRIBUTO in exclusive mode', dbms_sql.native);
--      ret 		:= dbms_sql.execute(cursor_name);
--      dbms_sql.close_cursor(cursor_name);

       begin -- Assegnazione Numero Progressivo
--          select nvl(max(pratica),0)+1
          select nr_prtr_seq.nextval
            into a_pratica
            from dual
--            from PRATICHE_TRIBUTO
          ; 
       end;
    end if;

end;
/* End Procedure: PRATICHE_TRIBUTO_NR */
/
