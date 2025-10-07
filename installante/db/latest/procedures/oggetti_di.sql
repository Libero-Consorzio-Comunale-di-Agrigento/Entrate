--liquibase formatted sql 
--changeset abrandolini:20250326_152423_oggetti_di stripComments:false runOnChange:true 
 
CREATE OR REPLACE PROCEDURE OGGETTI_DI
(a_estremi_catasto   IN    varchar2
)
IS
w_presente   varchar2(1);
BEGIN
  IF INSERTING or UPDATING or DELETING or rtrim(a_estremi_catasto) is null THEN
    null;
  ELSE
    BEGIN
      select 'x'
        into w_presente
        from oggetti
       where estremi_catasto = a_estremi_catasto
      ;
    RAISE too_many_rows;
    EXCEPTION
      WHEN no_data_found THEN
        null;
      WHEN too_many_rows THEN
        RAISE_APPLICATION_ERROR
          (-20998,'Esistono Oggetti con gli stessi estremi catastali');
      WHEN others THEN
        RAISE_APPLICATION_ERROR
          (-20999,'Errore in ricerca Oggetti (OGGETTI_DI)');
    END;
  END IF;
END;
/* End Procedure: OGGETTI_DI */
/

