--liquibase formatted sql 
--changeset abrandolini:20250326_152423_OGGETTI_IMPOSTA_NR stripComments:false runOnChange:true 
 
CREATE OR REPLACE procedure OGGETTI_IMPOSTA_NR
( a_oggetto_imposta	IN OUT	number
)
is
cursor_name 	integer;
ret		integer;
begin -- Assegnazione Numero Progressivo
   if a_oggetto_imposta is null then

--      cursor_name 	:= dbms_sql.OPEN_CURSOR;
--      dbms_sql.parse(cursor_name, 'lock table OGGETTI_IMPOSTA in exclusive mode', dbms_sql.native);
--      ret 		:= dbms_sql.execute(cursor_name);
--      dbms_sql.close_cursor(cursor_name);

      begin -- Assegnazione Numero Progressivo
--          select nvl(max(oggetto_imposta),0)+1 
          select nr_ogim_seq.nextval
            into a_oggetto_imposta
            from dual 
--            from OGGETTI_IMPOSTA 
          ;  
      end;
   end if;
end;
/* End Procedure: OGGETTI_IMPOSTA_NR */
/
