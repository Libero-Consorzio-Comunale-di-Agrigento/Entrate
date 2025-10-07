--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_spese_spedizione stripComments:false runOnChange:true 
 
create or replace function F_SPESE_SPEDIZIONE
(a_tipo_tributo     in VARCHAR2
,a_numero_rate      in number
,a_rata             in number
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
   if w_cod_istat = '097049' then   -- Missaglia
      BEGIN
         select nvl(sanz.sanzione,0)
           into nTotale
           from sanzioni sanz
          where sanz.tipo_tributo = 'TARSU'
            and sanz.cod_sanzione = 181
         ;
      EXCEPTION
         WHEN OTHERS THEN
            nTotale := 0;
      END;
      if nTotale > 0 and a_numero_rate > 1 and a_rata <> 0 then
         if a_numero_rate = a_rata then
            nTotale := nTotale - round((nTotale / a_numero_rate),2) * (a_numero_rate - 1);
         else
            nTotale := round((nTotale / a_numero_rate),2);
         end if;
      end if;
   else
      nTotale := 0;
   end if;
   Return nTotale;
END;
/* End Function: F_SPESE_SPEDIZIONE */
/

