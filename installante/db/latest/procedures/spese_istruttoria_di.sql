--liquibase formatted sql 
--changeset abrandolini:20250326_152423_spese_istruttoria_di stripComments:false runOnChange:true 
 
CREATE OR REPLACE PROCEDURE SPESE_ISTRUTTORIA_DI
(a_spese      IN   number,
 a_perc_insolvenza   IN   number)
IS
BEGIN
  IF (a_spese is not null and a_perc_insolvenza is not null)
     or
     (a_spese is null and a_perc_insolvenza is null)
  THEN
    RAISE_APPLICATION_ERROR
      (-20999,'Spese e Percentuale Insolvenza non coerenti');
  END IF;
END;
/* End Procedure: SPESE_ISTRUTTORIA_DI */
/

