--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_importo_rata_fatt stripComments:false runOnChange:true 
 
create or replace function F_IMPORTO_RATA_FATT
(a_importo  IN number
,a_rata     IN number
,a_max_rata IN number
)
RETURN number
IS
w_importo number;
w_resto   number;
begin
   if a_max_rata <= 1 or a_rata = 0 then
      w_importo := a_importo;
   else
      if a_max_rata = a_rata then
        w_importo := a_importo - (trunc(a_importo / a_max_rata, 2) * (a_max_rata -1));
     else
        w_importo := trunc(a_importo / a_max_rata, 2);
     end if;
   end if ;
 RETURN w_importo;
EXCEPTION
    WHEN OTHERS THEN
         RETURN null;
end;
/* End Function: F_IMPORTO_RATA_FATT */
/

