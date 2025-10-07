--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_verifica_cap stripComments:false runOnChange:true 
 
create or replace function F_VERIFICA_CAP
(p_cod_provincia     IN number
,p_cod_comune        IN number
,p_cap          IN number)
RETURN varchar2
IS
w_cap_errato      number;
w_comune_cappato  number;
w_cap_corretto    number;
BEGIN
   if p_cap is null then
      RETURN '';
   end if;
   if p_cod_comune is null or p_cod_provincia is null then
      BEGIN
         select count(1)
           into w_cap_errato
           from cap_viario  cavi
          where cavi.cap = p_cap
         ;
      EXCEPTION
         WHEN no_data_found THEN
         w_cap_errato := 0;
      END;
      if w_cap_errato > 0 then
         return 'ERR';
      end if;
   else
      BEGIN
         select count(1)
           into w_comune_cappato
           from cap_viario  cavi
          where cavi.cod_provincia = p_cod_provincia
            and cavi.cod_comune    = p_cod_comune
         ;
      EXCEPTION
         WHEN no_data_found THEN
         w_comune_cappato := 0;
      END;
      if w_comune_cappato > 0 then
         BEGIN
            select count(1)
              into w_cap_corretto
              from cap_viario  cavi
             where cavi.cod_provincia = p_cod_provincia
               and cavi.cod_comune    = p_cod_comune
               and p_cap  between cavi.da_cap
                              and cavi.a_cap
            ;
         EXCEPTION
            WHEN no_data_found THEN
            w_cap_corretto := 0;
         END;
         if w_cap_corretto = 0 then
            return 'ERR';
         end if;
      end if;
   end if;
   return '';
EXCEPTION
   WHEN OTHERS THEN
        RETURN 'cc';
END;
/* End Function: F_VERIFICA_CAP */
/

