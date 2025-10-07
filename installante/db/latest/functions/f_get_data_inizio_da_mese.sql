--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_get_data_inizio_da_mese stripComments:false runOnChange:true 
 
create or replace function F_GET_DATA_INIZIO_DA_MESE
/*************************************************************************
 NOME:        F_GET_DATA_INIZIO_DA_MESE
 DESCRIZIONE: Dati anno e mese inizio possesso, determina la data di
              inizio validita del periodo.
 RITORNA:     date                Data inizio validita
 NOTE:
 Rev.    Date         Author      Note
 000     10/06/2021   VD          Prima emissione.
*************************************************************************/
( a_anno                          number
, a_da_mese_possesso              number
) return date
is
  w_data                          date;
begin
  if a_da_mese_possesso is null then
     w_data := to_date('0101'||a_anno,'ddmmyyyy');
  else
     w_data := to_date('01'||lpad(a_da_mese_possesso,2,'0')||a_anno,'ddmmyyyy');
  end if;
  return w_data;
end;
/* End Function: F_GET_DATA_INIZIO_DA_MESE */
/

