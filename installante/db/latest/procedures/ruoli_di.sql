--liquibase formatted sql 
--changeset abrandolini:20250326_152423_ruoli_di stripComments:false runOnChange:true 
 
CREATE OR REPLACE PROCEDURE RUOLI_DI
(a_data_emissione   IN   date,
 a_data_denuncia   IN   date,
 a_scadenza_prima_rata   IN   date,
 a_invio_consorzio   IN   date)
IS
BEGIN
   IF INSERTING THEN
     IF nvl(a_data_emissione,to_date('01/01/1800','dd/mm/yyyy')) > sysdate THEN
        RAISE_APPLICATION_ERROR
          (-20999,'Data emissione maggiore della data odierna');
     END IF;
     IF nvl(a_data_denuncia,to_date('01/01/1800','dd/mm/yyyy')) > sysdate THEN
        RAISE_APPLICATION_ERROR
          (-20999,'Data denuncia maggiore della data odierna');
     END IF;
     IF nvl(a_scadenza_prima_rata,to_date('31/12/9999','dd/mm/yyyy')) <= sysdate THEN
        RAISE_APPLICATION_ERROR
          (-20999,'Data di scadenza prima rata minore o uguale alla data odierna');
     END IF;
     IF nvl(a_invio_consorzio,to_date('01/01/1800','dd/mm/yyyy')) > sysdate THEN
        RAISE_APPLICATION_ERROR
          (-20999,'Data di invio al consorzio maggiore della data odierna');
     END IF;
   END IF;
   IF nvl(a_data_emissione,to_date('01/01/1800','dd/mm/yyyy')) >
      nvl(a_scadenza_prima_rata,to_date('31/12/9999','dd/mm/yyyy')) THEN
        RAISE_APPLICATION_ERROR
          (-20999,'Data emissione maggiore della data scadenza prima rata');
   END IF;
   IF nvl(a_data_emissione,to_date('01/01/1800','dd/mm/yyyy')) >
      nvl(a_invio_consorzio,to_date('31/12/9999','dd/mm/yyyy')) THEN
        RAISE_APPLICATION_ERROR
          (-20999,'Data emissione maggiore della data invio al consorzio');
   END IF;
   IF nvl(a_invio_consorzio,to_date('01/01/1800','dd/mm/yyyy')) >
      nvl(a_scadenza_prima_rata,to_date('31/12/9999','dd/mm/yyyy')) THEN
        RAISE_APPLICATION_ERROR
          (-20999,'Data invio al consorzio maggiore della data scadenza prima rata');
   END IF;
END;
/* End Procedure: RUOLI_DI */
/

