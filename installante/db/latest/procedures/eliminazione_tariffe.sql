--liquibase formatted sql 
--changeset abrandolini:20250326_152423_eliminazione_tariffe stripComments:false runOnChange:true 
 
create or replace procedure ELIMINAZIONE_TARIFFE
(a_anno      IN number,
 a_tributo   IN number)
IS
BEGIN
  delete tariffe
   where anno      = a_anno
     and tributo   = a_tributo
  ;
EXCEPTION
  WHEN others THEN
    RAISE_APPLICATION_ERROR
     (-20999,'Errore in Eliminazione Tariffe ('||SQLERRM||')');
END;
/* End Procedure: ELIMINAZIONE_TARIFFE */
/

