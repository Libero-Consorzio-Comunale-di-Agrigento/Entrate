--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_get_data_fine_da_mese stripComments:false runOnChange:true 
 
create or replace function F_GET_DATA_FINE_DA_MESE
/*************************************************************************
 NOME:        F_GET_DATA_FINE_DA_MESE
 DESCRIZIONE: Dati anno, mesi possesso e mese inizio possesso, determina
              la data di fine validita del periodo.
 RITORNA:     date                Data fine validita
 NOTE:
 Rev.    Date         Author      Note
 000     10/06/2021   VD          Prima emissione.
*************************************************************************/
( a_anno                          number
, a_mesi_possesso                 number
, a_da_mese_possesso              number
) return date
is
  w_mesi                          number;
  w_data                          date;
begin
  if a_da_mese_possesso is null then
     w_data := to_date('3112'||a_anno,'ddmmyyyy');
  else
     w_mesi := least(12,a_da_mese_possesso + a_mesi_possesso -1);
     w_data := last_day(to_date('01'||lpad(w_mesi,2,'0')||a_anno,'ddmmyyyy'));
  end if;
  return w_data;
end;
/* End Function: F_GET_DATA_FINE_DA_MESE */
/

