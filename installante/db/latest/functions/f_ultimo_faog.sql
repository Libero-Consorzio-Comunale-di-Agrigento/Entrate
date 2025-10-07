--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_ultimo_faog stripComments:false runOnChange:true 
 
create or replace function F_ULTIMO_FAOG
(p_oggetto_imposta number,
 p_data date)
return number
IS
w_return number;
BEGIN
   BEGIN
   select numero_familiari
     into w_return
     from familiari_ogim
    where oggetto_imposta = p_oggetto_imposta
     and dal = (select max(dal) from familiari_ogim
                 where oggetto_imposta = p_oggetto_imposta)
   ;
   EXCEPTION
   WHEN NO_DATA_FOUND THEN
      RETURN 0;
   WHEN OTHERS THEN
      RETURN -1;
   END;
   RETURN w_return;
END;
/* End Function: F_ULTIMO_FAOG */
/

