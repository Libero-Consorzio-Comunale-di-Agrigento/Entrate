--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_cata stripComments:false runOnChange:true 
 
create or replace function F_CATA
(a_anno      IN number,
 a_tributo   IN number,
 a_importo   IN number,
 a_tipo_add   IN varchar2)
RETURN number
IS
w_add_eca   NUMBER;
w_mag_eca   NUMBER;
w_add_pro   NUMBER;
w_iva       NUMBER;
imp_return   NUMBER;
BEGIN
   IF a_tributo = 422 OR  a_tributo = 423 OR  a_tributo = 424 OR  a_tributo = 425 THEN
--     imp_return := a_importo;
--     MODIFICATA IL 05/09/2000 in seguito richiesta Sassuolo
     imp_return := 0;
   ELSE
     BEGIN
   select nvl(ADDIZIONALE_ECA,0),nvl(MAGGIORAZIONE_ECA,0),
          nvl(ADDIZIONALE_PRO,0),nvl(ALIQUOTA,0)
     into w_add_eca,w_mag_eca,w_add_pro,w_iva
     from carichi_tarsu
    where anno = a_anno
   ;
     EXCEPTION
   WHEN others THEN
        RETURN 0;
     END;
     IF UPPER(a_tipo_add) = 'T' THEN
   imp_return := f_round(w_add_eca * a_importo / 100,1)
         + f_round(w_mag_eca * a_importo / 100,1)
         + f_round(w_add_pro * a_importo / 100,1)
         + f_round(w_iva * a_importo / 100,1);
     ELSIF UPPER(a_tipo_add) = 'A' THEN
   imp_return := f_round(w_add_eca * a_importo / 100,1);
     ELSIF UPPER(a_tipo_add) = 'M' THEN
      imp_return := f_round(w_mag_eca * a_importo / 100,1);
     ELSIF UPPER(a_tipo_add) = 'P' THEN
   imp_return := f_round(w_add_pro * a_importo / 100,1);
     ELSIF UPPER(a_tipo_add) = 'I' THEN
   imp_return := f_round(w_iva * a_importo / 100,1);
     ELSE
   imp_return := 0;
     END IF;
   END IF;
   RETURN imp_return;
END;
/* End Function: F_CATA */
/

