--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_trova_netto stripComments:false runOnChange:true 
 
create or replace function F_TROVA_NETTO
(a_lordo         in number
,a_perc_1        in number
,a_perc_2        in number
,a_perc_3        in number
,a_perc_4        in number
) return number is
w_netto             number;
w_incr              number;
w_lordo             number;
BEGIN
   w_netto := trunc(a_lordo * 100 / (100 + nvl(a_perc_1,0)
                                         + nvl(a_perc_2,0)
                                         + nvl(a_perc_3,0)
                                         + nvl(a_perc_4,0)
                                    ),2
                   );
   w_lordo := w_netto + round(w_netto * nvl(a_perc_1,0) / 100,2)
                      + round(w_netto * nvl(a_perc_2,0) / 100,2)
                      + round(w_netto * nvl(a_perc_3,0) / 100,2)
                      + round(w_netto * nvl(a_perc_4,0) / 100,2);
   if w_lordo = a_lordo then
      Return w_netto;
   end if;
   if w_lordo > a_lordo then
      w_incr := -0.01;
   else
      w_incr :=  0.01;
   end if;
   LOOP
      w_netto := w_netto + w_incr;
      w_lordo := w_netto + round(w_netto * nvl(a_perc_1,0) / 100,2)
                         + round(w_netto * nvl(a_perc_2,0) / 100,2)
                         + round(w_netto * nvl(a_perc_3,0) / 100,2)
                         + round(w_netto * nvl(a_perc_4,0) / 100,2);
      if w_lordo = a_lordo then
         exit;
      end if;
      if w_incr =  0.01 and w_lordo > a_lordo
      or w_incr = -0.01 and w_lordo < a_lordo then
         exit;
      end if;
   END LOOP;
   Return w_netto;
END;
/* End Function: F_TROVA_NETTO */
/

