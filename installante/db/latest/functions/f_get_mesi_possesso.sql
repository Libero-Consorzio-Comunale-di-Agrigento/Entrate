--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_get_mesi_possesso stripComments:false runOnChange:true 
 
create or replace function F_GET_MESI_POSSESSO
/*************************************************************************
 NOME:        F_GET_MESI_POSSESSO
 DESCRIZIONE: Determina il numero di mesi in cui un certo oggetto e'
                in possesso di un contribuente nell'ambito del periodo
      indicato.
 RITORNA:     number                Numero di mesi di possesso
 NOTE:
 Rev.    Date         Author      Note
 000     04/07/2019   VD          Prima emissione.
*************************************************************************/
( a_tipo_tributo           varchar2
, a_cod_fiscale            varchar2
, a_anno                   number
, a_oggetto                number
, a_data_da                date
, a_data_a                 date
) return number
as
  w_mesi                   number;
  w_mese_inizio            number;
  w_mese_fine              number;
begin
  if a_data_da <= to_date('0101'||a_anno,'ddmmyyyy') then
     w_mese_inizio := 1;
  else
     w_mese_inizio := to_number(to_char(a_data_da,'mm'));
     if to_number(to_char(a_data_da,'dd')) > 15 then
        w_mese_inizio := w_mese_inizio + 1;
     end if;
  end if;
--
  if a_data_a >= to_date('3112'||a_anno,'ddmmyyyy') then
     w_mese_fine := 12;
  else
     w_mese_fine := to_number(to_char(a_data_a,'mm'));
     if to_number(to_char(a_data_a,'dd')) <= 15 then
        w_mese_fine := w_mese_fine - 1;
     end if;
  end if;
--
  w_mesi := w_mese_fine - w_mese_inizio + 1;
  return w_mesi;
--
end;
/* End Function: F_GET_MESI_POSSESSO */
/

