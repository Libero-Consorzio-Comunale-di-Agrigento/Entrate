--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_tributi_ruolo stripComments:false runOnChange:true 
 
create or replace function F_TRIBUTI_RUOLO
( a_ruolo        in number
) return varchar2
IS
  cursor sel_ruco is
     SELECT RUOLI_CONTRIBUENTE.TRIBUTO
       FROM RUOLI
          , RUOLI_CONTRIBUENTE
      WHERE ruoli.ruolo = ruoli_contribuente.ruolo (+)
        and RUOLI.SPECIE_RUOLO = 1
        and ruoli.ruolo        = a_ruolo
   GROUP BY RUOLI_CONTRIBUENTE.TRIBUTO
   ORDER BY RUOLI_CONTRIBUENTE.TRIBUTO
          ;
   w_tributo      number;
   w_tributi      varchar2(100);
BEGIN
   open sel_ruco;
   loop
       fetch sel_ruco into w_tributo;
       if sel_ruco%NOTFOUND = TRUE then
          w_tributo := null;
          exit;
       end if;
       w_tributi := w_tributi||lpad(to_char(w_tributo),4,' ');
    end loop;
    close sel_ruco;
   return w_tributi;
END;
/* End Function: F_TRIBUTI_RUOLO */
/

