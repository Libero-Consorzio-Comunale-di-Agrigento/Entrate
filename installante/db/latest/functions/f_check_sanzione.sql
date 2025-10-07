--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_check_sanzione stripComments:false runOnChange:true 
 
CREATE OR REPLACE function     F_CHECK_SANZIONE
(a_pratica        number,
 a_cod_sanzione   number,
 a_data_inizio    date default to_date('01/01/1900','dd/mm/yyyy')
 )
RETURN number
IS
   w_return number;
BEGIN
   BEGIN
   select count(1)
     into w_return
     from sanzioni_pratica sapr
    where pratica      = a_pratica
      and cod_sanzione   = a_cod_sanzione
      and a_data_inizio between sapr.data_inizio and sapr.data_fine
   ;
   EXCEPTION
   WHEN others THEN
          w_return := -1;
  END;
  RETURN w_return;
END;
/* End Function: F_CHECK_SANZIONE */
/
