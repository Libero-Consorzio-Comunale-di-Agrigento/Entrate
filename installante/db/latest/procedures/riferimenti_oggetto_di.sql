--liquibase formatted sql 
--changeset abrandolini:20250326_152423_riferimenti_oggetto_di stripComments:false runOnChange:true 
 
CREATE OR REPLACE PROCEDURE RIFERIMENTI_OGGETTO_DI
(a_inizio_validita   IN   date,
 a_fine_validita   IN   date,
 da_anno      IN   number,
 a_anno         IN   number
)
IS
BEGIN
   IF a_inizio_validita > a_fine_validita THEN
      RAISE_APPLICATION_ERROR
          (-20999,'Inizio validita maggiore di Fine Validita');
   END IF;
   IF da_anno > a_anno THEN
      RAISE_APPLICATION_ERROR
          (-20999,'Da Anno indicato maggiore di A Anno');
   END IF;
END;
/* End Procedure: RIFERIMENTI_OGGETTO_DI */
/

