--liquibase formatted sql 
--changeset abrandolini:20250326_152423_disabilita_trg stripComments:false runOnChange:true 
 
create or replace procedure DISABILITA_TRG
( a_tabella   IN varchar2
)
is
cursor_name    integer;
ret       integer;
string1    varchar2(2000);
begin
   cursor_name    := dbms_sql.OPEN_CURSOR;
   string1    := 'alter table '||a_tabella||' disable all Triggers';
   dbms_sql.parse(cursor_name, string1, dbms_sql.v7);
   ret      := dbms_sql.execute(cursor_name);
   dbms_sql.close_cursor(cursor_name);
end;
/* End Procedure: DISABILITA_TRG */
/

