--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_spese_mora stripComments:false runOnChange:true 
 
create or replace function F_SPESE_MORA
(a_tipo_tributo     in VARCHAR2
) Return NUMBER is
nTotale           number(16,2);
w_cod_istat       varchar2(6);
BEGIN
   BEGIN
     select lpad(to_char(pro_cliente), 3, '0') ||
            lpad(to_char(com_cliente), 3, '0')
       into w_cod_istat
       from dati_generali;
   EXCEPTION
     WHEN others THEN
       null;
   END;
   if w_cod_istat in ('097049','108027')  then   -- Missaglia, Limbiate
      BEGIN
         select sanz.sanzione
           into nTotale
           from sanzioni sanz
          where sanz.tipo_tributo = 'TARSU'
            and sanz.cod_sanzione = 182
         ;
      EXCEPTION
         WHEN OTHERS THEN
            nTotale := 0;
      END;
   else
      nTotale := 0;
   end if;
   Return nTotale;
END;
/* End Function: F_SPESE_MORA */
/

