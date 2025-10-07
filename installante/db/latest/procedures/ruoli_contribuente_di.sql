--liquibase formatted sql 
--changeset abrandolini:20250326_152423_ruoli_contribuente_di stripComments:false runOnChange:true 
 
CREATE OR REPLACE PROCEDURE RUOLI_CONTRIBUENTE_DI
(a_data_cartella   IN   date,
 a_decorrenza_interessi   IN   date)
IS
BEGIN
     IF nvl(a_data_cartella,to_date('01/01/1800','dd/mm/yyyy')) > sysdate THEN
        RAISE_APPLICATION_ERROR
          (-20999,'Data della cartella maggiore della data odierna');
     END IF;
     IF nvl(a_decorrenza_interessi,to_date('01/01/1800','dd/mm/yyyy')) > sysdate THEN
        RAISE_APPLICATION_ERROR
          (-20999,'Data di decorrenza interessi maggiore della data odierna');
     END IF;
END;
/* End Procedure: RUOLI_CONTRIBUENTE_DI */
/

