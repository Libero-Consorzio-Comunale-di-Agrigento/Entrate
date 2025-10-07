--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_is_ruolo_master stripComments:false runOnChange:true 
 
create or replace function F_IS_RUOLO_MASTER
(a_ruolo            in     number
) Return varchar2 is
nContaRuoli number;
BEGIN
   BEGIN
      select nvl(count(1),0)
        into nContaRuoli
        from ruoli
       where ruolo_master     = a_ruolo
      ;
   EXCEPTION
      WHEN OTHERS THEN
         nContaRuoli := 0;
   END;
   if nContaRuoli > 0 then
      return 'S';
   else
      return null;
   end if;
END;
/* End Function: F_IS_RUOLO_MASTER */
/

