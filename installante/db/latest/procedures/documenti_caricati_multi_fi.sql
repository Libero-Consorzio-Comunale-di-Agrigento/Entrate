--liquibase formatted sql 
--changeset abrandolini:20250326_152423_documenti_caricati_multi_fi stripComments:false runOnChange:true 
 
create or replace procedure DOCUMENTI_CARICATI_MULTI_FI
(a_documento_id       IN NUMBER,
 a_documento_multi_id IN NUMBER
)
is
sql_errm      varchar2(200);
begin
   IF DELETING THEN
     BEGIN
      update pratiche_tributo
         set documento_id = null,
             documento_multi_id = null
       where documento_id = a_documento_id
         and documento_multi_id = a_documento_multi_id
      ;
     EXCEPTION
      WHEN others THEN
        sql_errm := substr(SQLERRM,12,200);
        RAISE_APPLICATION_ERROR
          (-20999,sql_errm);
     END;
   END IF;
end;
/* End Procedure: DOCUMENTI_CARICATI_MULTI_FI */
/

