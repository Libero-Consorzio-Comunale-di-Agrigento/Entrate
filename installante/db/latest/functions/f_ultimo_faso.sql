--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_ultimo_faso stripComments:false runOnChange:true 
 
create or replace function F_ULTIMO_FASO
(p_ni number,
 p_anno number)
return number
IS
w_return number;
BEGIN
   BEGIN
   select numero_familiari
     into w_return
     from familiari_soggetto
    where ni   = p_ni
     and anno = decode(p_anno,9999,anno,p_anno)
     and dal  = (select max(dal)
                   from familiari_soggetto
               where ni   = p_ni
                 and anno = decode(p_anno,9999,anno,p_anno) )
   ;
   EXCEPTION
   WHEN NO_DATA_FOUND THEN
      RETURN 0;
   WHEN OTHERS THEN
      RETURN -1;
   END;
   RETURN w_return;
END;
/* End Function: F_ULTIMO_FASO */
/

