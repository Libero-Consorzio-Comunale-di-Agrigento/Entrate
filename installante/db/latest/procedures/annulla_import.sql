--liquibase formatted sql 
--changeset abrandolini:20250326_152423_annulla_import stripComments:false runOnChange:true 
 
create or replace procedure ANNULLA_IMPORT
( a_import      IN varchar2
)
is
    procedure tronca(p_tabella varchar2)
    is
       cursor_name    integer;
       ret      integer;
       string1      varchar2(2000);
    begin
       cursor_name    := dbms_sql.OPEN_CURSOR;
       string1       := 'truncate table '||p_tabella;
       dbms_sql.parse(cursor_name, string1, dbms_sql.v7);
       ret      := dbms_sql.execute(cursor_name);
       dbms_sql.close_cursor(cursor_name);
    end tronca;
begin
   IF a_import   = 'DIC_SIGAI' THEN
        tronca('SIGAI_ANA_FIS');
        tronca('SIGAI_ANA_GIUR');
        tronca('SIGAI_CONT_FABBRICATI');
        tronca('SIGAI_CONT_TERRENI');
        tronca('SIGAI_FABBRICATI');
        tronca('SIGAI_TERRENI');
   ELSIF a_import = 'VER_SIGAI' THEN
        tronca('SIGAI_VERSAMENTI');
   END IF;
end;
/* End Procedure: ANNULLA_IMPORT */
/

