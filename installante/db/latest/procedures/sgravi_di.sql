--liquibase formatted sql 
--changeset abrandolini:20250326_152423_sgravi_di stripComments:false runOnChange:true 
 
CREATE OR REPLACE PROCEDURE SGRAVI_DI
(a_data_elenco      IN   date)
IS
BEGIN
     IF nvl(a_data_elenco,to_date('01/01/1800','dd/mm/yyyy')) > sysdate THEN
        RAISE_APPLICATION_ERROR
          (-20999,'Data elenco maggiore della data odierna');
     END IF;
END;
/* End Procedure: SGRAVI_DI */
/

