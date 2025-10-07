--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_importo_ruolo_coat_trib stripComments:false runOnChange:true 
 
create or replace function F_IMPORTO_RUOLO_COAT_TRIB
( a_cod_fiscale  in varchar2
, a_ruolo        IN number
, a_progressivo  IN number
) return number
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
   w_cod_fiscale  varchar2(16);
   w_importo      number := null;
   w_tributo      number;
BEGIN
   open sel_ruco;
   loop
       fetch sel_ruco into w_tributo;
       if sel_ruco%NOTFOUND = TRUE then
          w_tributo := null;
          exit;
       end if;
       if sel_ruco%ROWCOUNT = a_progressivo then
          exit;
       end if;
    end loop;
    close sel_ruco;
   begin
        SELECT sum( nvl(RUOLI_CONTRIBUENTE.IMPORTO,0) ) importo
          into w_importo
          FROM RUOLI
             , RUOLI_CONTRIBUENTE
         WHERE ruoli.ruolo = ruoli_contribuente.ruolo (+)
           and RUOLI.SPECIE_RUOLO = 1
           and ruoli.ruolo        = a_ruolo
           and ruoli_contribuente.cod_fiscale = a_cod_fiscale
           and ruoli_contribuente.tributo     = w_tributo
             ;
   EXCEPTION
      WHEN no_data_found THEN
          w_importo := null;
   end;
    return w_importo;
END;
/* End Function: F_IMPORTO_RUOLO_COAT_TRIB */
/

