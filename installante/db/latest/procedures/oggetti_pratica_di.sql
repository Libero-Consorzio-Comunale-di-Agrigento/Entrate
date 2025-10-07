--liquibase formatted sql 
--changeset abrandolini:20250326_152423_oggetti_pratica_di stripComments:false runOnChange:true 
 
CREATE OR REPLACE PROCEDURE OGGETTI_PRATICA_DI
(a_inizio_concessione   IN   date,
 a_fine_concessione   IN   date)
IS
BEGIN
  IF nvl(a_fine_concessione,to_date('31/12/9999','dd/mm/yyyy')) <
     nvl(a_inizio_concessione,to_date('01/01/1800','dd/mm/yyyy')) THEN
        RAISE_APPLICATION_ERROR
          (-20999,'Data di fine concessione minore o uguale (pino) a quella di inizio');
  END IF;
END;
/* End Procedure: OGGETTI_PRATICA_DI */
/

