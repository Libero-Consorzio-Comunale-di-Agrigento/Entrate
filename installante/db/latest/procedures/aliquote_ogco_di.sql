--liquibase formatted sql 
--changeset abrandolini:20250326_152423_aliquote_ogco_di stripComments:false runOnChange:true 
 
create or replace procedure ALIQUOTE_OGCO_DI
(a_dal         IN   date,
 a_al         IN   date
)
IS
BEGIN
   IF a_dal > a_al THEN
      RAISE_APPLICATION_ERROR
          (-20999,'Inizio Validita maggiore di Fine Validita');
   END IF;
END;
/* End Procedure: ALIQUOTE_OGCO_DI */
/

