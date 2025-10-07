--liquibase formatted sql 
--changeset abrandolini:20250326_152423_interessi_di stripComments:false runOnChange:true 
 
CREATE OR REPLACE PROCEDURE INTERESSI_DI
(a_inizio   IN   date,
 a_fine      IN   date
)
IS
BEGIN
   IF a_inizio > a_fine THEN
      RAISE_APPLICATION_ERROR
          (-20999,'Inizio validita maggiore di Fine Validita');
   END IF;
END;
/* End Procedure: INTERESSI_DI */
/

