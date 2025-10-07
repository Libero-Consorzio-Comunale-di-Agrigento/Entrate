--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_coeff_gg stripComments:false runOnChange:true 
 
create or replace function F_COEFF_GG
(a_anno              IN number,
 a_data_decorrenza   IN date,
 a_data_cessazione   IN date)
 RETURN NUMBER
IS
w_dec_temp  date;
w_cess_temp date;
w_mese      number;
w_coeff     number;
BEGIN
   w_dec_temp     := nvl(a_data_decorrenza,to_date('0101'||lpad(to_char(a_anno),4,'0'),'ddmmyyyy'));
   w_dec_temp     := greatest(w_dec_temp,to_date('0101'||lpad(to_char(a_anno),4,'0'),'ddmmyyyy'));
   w_cess_temp    := nvl(a_data_cessazione,to_date('3112'||lpad(to_char(a_anno),4,'0'),'ddmmyyyy'));
   w_cess_temp    := least(w_cess_temp,to_date('3112'||lpad(to_char(a_anno),4,'0'),'ddmmyyyy'));
   IF w_dec_temp  > to_date('3112'||lpad(to_char(a_anno),4,'0'),'ddmmyyyy')
   OR w_cess_temp < to_date('0101'||lpad(to_char(a_anno),4,'0'),'ddmmyyyy') THEN
      Return 0;
   END IF;
   if w_cess_temp - w_dec_temp + 1 > 365 then
      w_coeff := 1;
   else
      w_coeff := ((w_cess_temp - w_dec_temp) + 1) / 365;
   end if;
   return w_coeff;
END;
/* End Function: F_COEFF_GG */
/

