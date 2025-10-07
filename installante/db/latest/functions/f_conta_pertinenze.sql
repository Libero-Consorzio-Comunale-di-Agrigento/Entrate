--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_conta_pertinenze stripComments:false runOnChange:true 
 
create or replace function F_CONTA_PERTINENZE
(a_ogpr    number)
RETURN number
IS
   w_return number;
BEGIN
   BEGIN
   select count(1)
     into w_return
     from oggetti_pratica
    where oggetto_pratica_rif_ap  = a_ogpr
   ;
   EXCEPTION
   WHEN others THEN
          w_return := 0;
  END;
  RETURN w_return;
END;
/* End Function: F_CONTA_PERTINENZE */
/

