--liquibase formatted sql 
--changeset abrandolini:20250326_152423_scelta_vista_catasto stripComments:false runOnChange:true 
 
create or replace procedure SCELTA_VISTA_CATASTO
is
cursor_name    integer;
ret       integer;
string1    varchar2(2000);
errore      exception;
pragma exception_init (errore, -4043);
w_catasto_cu   varchar2(1);
BEGIN
 begin
   cursor_name    := dbms_sql.OPEN_CURSOR;
   BEGIN
     dbms_sql.parse(cursor_name, 'drop synonym IMMOBILI_CATASTO_URBANO', dbms_sql.native);
   EXCEPTION
      when others then null;
   END;
   BEGIN
     dbms_sql.parse(cursor_name, 'drop synonym IMMOBILI_CATASTO_TERRENI', dbms_sql.native);
   EXCEPTION
      when others then null;
   END;
   BEGIN
     dbms_sql.parse(cursor_name, 'drop synonym PROPRIETARI_CATASTO_URBANO', dbms_sql.native);
   EXCEPTION
      when others then null;
   END;
 end;
 BEGIN
    select flag_catasto_cu
      into w_catasto_cu
      from dati_generali
    ;
 EXCEPTION
     WHEN others THEN
        RAISE_APPLICATION_ERROR
           (-20999,'Errore in ricerca Dati Generali'||' ('||SQLERRM||')');
 END;
 IF w_catasto_cu = 'S' THEN
   BEGIN
     dbms_sql.parse(cursor_name, 'create synonym IMMOBILI_CATASTO_URBANO for IMMOBILI_CATASTO_URBANO_CU', dbms_sql.native);
   END;
   BEGIN
     dbms_sql.parse(cursor_name, 'create synonym PROPRIETARI_CATASTO_URBANO for PROPRIETARI_CATASTO_URBANO_CU', dbms_sql.native);
   END;
 ELSE
   BEGIN
     dbms_sql.parse(cursor_name, 'create synonym IMMOBILI_CATASTO_URBANO for IMMOBILI_CATASTO_URBANO_CC', dbms_sql.native);
   END;
   BEGIN
     dbms_sql.parse(cursor_name, 'create synonym IMMOBILI_CATASTO_TERRENI for IMMOBILI_CATASTO_TERRENI_CC', dbms_sql.native);
   END;
   BEGIN
     dbms_sql.parse(cursor_name, 'create synonym PROPRIETARI_CATASTO_URBANO for PROPRIETARI_CATASTO_URBANO_CC', dbms_sql.native);
   END;
 END IF;
 dbms_sql.close_cursor(cursor_name);
EXCEPTION
     when others then
        raise_application_error(-20999,'Errore in scelta vista Catasto'||' ('||SQLERRM||')');
END;
/* End Procedure: SCELTA_VISTA_CATASTO */
/

