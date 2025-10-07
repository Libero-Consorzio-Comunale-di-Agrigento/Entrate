--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_detrazione_raop_ici stripComments:false runOnChange:true 
 
create or replace function F_DETRAZIONE_RAOP_ICI
(a_detrazione      IN   number,
 a_mesi_pos_den      IN    number,
 a_anno_den           IN    number,
 a_anno              IN    number
)
RETURN number
IS
w_detrazione         number(15,2);
w_detraz_base_den     number(15,2);
w_detraz_base         number(15,2);
BEGIN
      if a_detrazione is null then
         return null;
      end if;
       if nvl(a_mesi_pos_den,12) = 0 then
         w_detrazione := 0;
      else
         if a_anno = a_anno_den then
            w_detrazione := a_detrazione;
         else
            w_detrazione := round(nvl(a_detrazione,0) / nvl(a_mesi_pos_den,12) * 12 ,2);
         end if;
      end if;
               BEGIN
                  select nvl(detrazione_base,0)
                    into w_detraz_base_den
                    from detrazioni
                   where anno     = a_anno_den
                     and tipo_tributo = 'ICI'
                  ;
               EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                     w_detraz_base_den := 0;
               END;
               BEGIN
                  select nvl(detrazione_base,0)
                    into w_detraz_base
                    from detrazioni
                   where anno     = a_anno
                     and tipo_tributo = 'ICI'
                  ;
               EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                     w_detraz_base := 0;
               END;
               if w_detraz_base_den <> 0 then
                  w_detrazione     := round(w_detrazione  / w_detraz_base_den * w_detraz_base,2);
            end if;
   RETURN w_detrazione;
EXCEPTION
   WHEN OTHERS THEN
        RETURN null;
END;
/* End Function: F_DETRAZIONE_RAOP_ICI */
/

