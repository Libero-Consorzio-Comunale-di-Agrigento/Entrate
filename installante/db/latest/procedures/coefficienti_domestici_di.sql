--liquibase formatted sql 
--changeset abrandolini:20250326_152423_coefficienti_domestici_di stripComments:false runOnChange:true 
 
CREATE OR REPLACE PROCEDURE COEFFICIENTI_DOMESTICI_DI
(a_COEFF_ADATTAMENTO      IN number,
 a_COEFF_PRODUTTIVITA      IN number,
 a_COEFF_ADATTAMENTO_NO_AP   IN number,
 a_COEFF_PRODUTTIVITA_NO_AP   IN number,
 a_TARIFFA_QUOTA_FISSA      IN number,
 a_TARIFFA_QUOTA_VARIABILE   IN number,
 a_TARIFFA_QUOTA_F_NO_AP   IN number,
 a_TARIFFA_QUOTA_V_NO_AP   IN number)
IS
BEGIN
  IF INSERTING OR UPDATING THEN
     IF a_COEFF_ADATTAMENTO||a_COEFF_PRODUTTIVITA||a_COEFF_ADATTAMENTO_NO_AP||a_COEFF_PRODUTTIVITA_NO_AP is not null and
     (a_COEFF_ADATTAMENTO     is null or
    a_COEFF_PRODUTTIVITA    is null)
     THEN
        RAISE_APPLICATION_ERROR
             (-20999,'Coefficienti Domestici non inseriti completamente');
     END IF;
     IF a_TARIFFA_QUOTA_FISSA||a_TARIFFA_QUOTA_VARIABILE||a_TARIFFA_QUOTA_F_NO_AP||a_TARIFFA_QUOTA_V_NO_AP is not null and
      (a_TARIFFA_QUOTA_FISSA       is null or
         a_TARIFFA_QUOTA_VARIABILE is null)
     THEN
        RAISE_APPLICATION_ERROR
             (-20999,'Tariffe Domestiche non inserite completamente');
     END IF;
   END IF;
END;
/* End Procedure: COEFFICIENTI_DOMESTICI_DI */
/

