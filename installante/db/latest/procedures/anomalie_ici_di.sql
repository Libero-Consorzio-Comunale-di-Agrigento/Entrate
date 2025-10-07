--liquibase formatted sql 
--changeset abrandolini:20250326_152423_anomalie_ici_di stripComments:false runOnChange:true 
 
CREATE OR REPLACE PROCEDURE ANOMALIE_ICI_DI
(a_cod_fiscale   IN   varchar2,
 a_oggetto   IN   number)
IS
BEGIN
  IF a_cod_fiscale is null and a_oggetto is null THEN
     RAISE_APPLICATION_ERROR
       (-20999,'Indicare cod_fiscale oppure oggetto');
  END IF;
end;
/* End Procedure: ANOMALIE_ICI_DI */
/

