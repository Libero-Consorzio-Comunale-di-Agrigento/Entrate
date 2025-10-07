--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_get_mesi_possesso_1sem stripComments:false runOnChange:true 
 
create or replace function F_GET_MESI_POSSESSO_1SEM
/*************************************************************************
 NOME:        F_GET_MESI_POSSESSO_1SEM
 DESCRIZIONE: Determina il numero di mesi del primo semestre dell'anno
              in cui un certo oggetto e' in possesso di un contribuente
              nell'ambito del periodo indicato.
 RITORNA:     number                Numero di mesi di possesso
 NOTE:
 Rev.    Date         Author      Note
 000     09/06/2021   VD          Prima emissione.
*************************************************************************/
( a_data_da                date
, a_data_a                 date
) return number
as
  w_mesi                   number;
  w_mese_inizio            number;
  w_mese_fine              number;
begin
  -- Determinazione mese inizio periodo
  w_mese_inizio := to_number(to_char(a_data_da,'mm'));
  if to_number(to_char(a_data_da,'dd')) > 15 then
     w_mese_inizio := w_mese_inizio + 1;
  end if;
  if w_mese_inizio > 6 then
     return 0;
  end if;
  -- Determinazione mese fine periodo
  w_mese_fine := to_number(to_char(a_data_a,'mm'));
  if to_number(to_char(a_data_a,'dd')) <= 15 then
     w_mese_fine := w_mese_fine - 1;
  end if;
  if w_mese_fine > 6 then
     w_mese_fine := 6;
  end if;
--
  w_mesi := w_mese_fine - w_mese_inizio + 1;
  return w_mesi;
--
end;
/* End Function: F_GET_MESI_POSSESSO_1SEM */
/

