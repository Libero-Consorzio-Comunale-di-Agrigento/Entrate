--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_titolo_da_mese_possesso stripComments:false runOnChange:true 
 
create or replace function F_TITOLO_DA_MESE_POSSESSO
/*************************************************************************
 NOME:        F_TITOLO_DA_MESE_POSSESSO
 DESCRIZIONE: Determina il mese di inizio possesso sulla base del titolo
              e data_evento
 RITORNA:     number              Mese di inizio possesso
 NOTE:
 Rev.    Date         Author      Note
 000     18/08/2021   AB          Prima emissione.
 001     29/10/2021   DM          Corretto calcolo se data > 15/12/ANNO
 002     01/12/2021   AB          Modificato il w_mese inizio solo se < 12
*************************************************************************/
( a_titolo                 varchar2
, a_data_evento            date
) return number
as
  w_mese_inizio            number;
  w_giorni_possesso        number;
  w_giorni_mese            number;
begin
   if a_titolo in ('A','C') and a_data_evento is not null then
      w_giorni_mese := to_number(to_char(last_day(a_data_evento), 'dd'));
      if a_titolo = 'A' then
         w_mese_inizio := to_number(to_char(a_data_evento,'mm'));
         w_giorni_possesso := w_giorni_mese - to_number(to_char(a_data_evento, 'dd')) + 1;
         if w_giorni_possesso < (w_giorni_mese / 2) then
           if w_mese_inizio < 12 then
             w_mese_inizio := w_mese_inizio + 1;
           end if;
         end if;
         return w_mese_inizio;
      else
         return 1;
      end if;
   else
      return null;
   end if;
--
end;
/* End Function: F_TITOLO_DA_MESE_POSSESSO */
/

