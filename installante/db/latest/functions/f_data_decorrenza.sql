--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_data_decorrenza stripComments:false runOnChange:true 
 
create or replace function F_DATA_DECORRENZA
( w_tipo_tributo  varchar2
, w_specie_ruolo  number
, w_data_pratica  date
, w_data_notifica date
, w_minuta        number
)
return varchar2 is
  w_data_dec_interessi date;
  w_cod_istat          varchar2(6);
begin
  BEGIN
    select lpad(to_char(pro_cliente), 3, '0') ||
           lpad(to_char(com_cliente), 3, '0')
      into w_cod_istat
      from dati_generali;
  EXCEPTION
    WHEN others THEN
       null;
  END;
  if (w_tipo_tributo = 'TARSU' and w_specie_ruolo = 0) then --Ruolo Normale
    if (w_minuta = 1) then
      return null; --Minuta di stampa
    else
      return '00000000'; --Trasmissione Ruolo
    end if;
  else if (w_tipo_tributo = 'ICI' and w_data_pratica <= to_date('31/12/2006','dd/mm/yyyy'))then
         w_data_dec_interessi := w_data_notifica + 91;
       else
         w_data_dec_interessi := w_data_notifica + 61;
       end if;
  end if;
  if (w_minuta = 1) then
    return to_char(w_data_dec_interessi, 'dd/mm/YYYY'); --Minuta di stampa
  else
    if w_cod_istat = '001219' and w_tipo_tributo = 'TARSU' then  -- Rivoli Trasmissione Ruolo
       return '00000000';
    else
       return to_char(w_data_dec_interessi, 'ddmmYYYY'); --Trasmissione Ruolo
    end if;
  end if;
end;
/* End Function: F_DATA_DECORRENZA */
/

