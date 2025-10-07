--liquibase formatted sql 
--changeset abrandolini:20250326_152423_denunce_iciap_di stripComments:false runOnChange:true 
 
create or replace procedure DENUNCE_ICIAP_DI
(a_data_compilazione   IN   date)
IS
BEGIN
     IF nvl(a_data_compilazione,to_date('01/01/1800','dd/mm/yyyy')) > sysdate THEN
        RAISE_APPLICATION_ERROR
          (-20999,'Data compilazione maggiore della data odierna');
     END IF;
END;
/* End Procedure: DENUNCE_ICIAP_DI */
/

