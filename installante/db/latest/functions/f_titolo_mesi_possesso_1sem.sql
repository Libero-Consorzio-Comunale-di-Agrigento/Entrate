--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_titolo_mesi_possesso_1sem stripComments:false runOnChange:true 
 
create or replace function F_TITOLO_MESI_POSSESSO_1SEM
/*************************************************************************
 NOME:        F_TITOLO_MESI_POSSESSO_1SEM
 DESCRIZIONE: Determina il numero di mesi del primo semestre sulla base
              del titolo e data_evento
 RITORNA:     number                Numero di mesi di possesso
 NOTE:
 Rev.    Date         Author      Note
 000     18/08/2021   AB          Prima emissione.
*************************************************************************/
( a_titolo                 varchar2
, a_data_evento            date
) return number
as
  w_mesi                   number;
  w_mese_inizio            number;
  w_mese_fine              number;
  w_giorni_possesso        number;
  w_giorni_mese            number;
begin
   if a_titolo in ('A','C') and a_data_evento is not null then
      w_giorni_mese := to_number(to_char(last_day(a_data_evento), 'dd'));
      if a_titolo = 'A' then
         w_mese_inizio := to_number(to_char(a_data_evento,'mm'));
         w_giorni_possesso := w_giorni_mese - to_number(to_char(a_data_evento, 'dd')) + 1;
         if w_giorni_possesso < (w_giorni_mese / 2) then
            w_mese_inizio := w_mese_inizio + 1;
         end if;
         if w_mese_inizio > 6 then
            return 0;
         end if;
         w_mese_fine := 6;
      else
         w_mese_inizio := 1;
         w_mese_fine := to_number(to_char(a_data_evento,'mm'));
         w_giorni_possesso := to_number(to_char(a_data_evento, 'dd')) - 1;
         if w_giorni_possesso <= (w_giorni_mese / 2) then
            w_mese_fine := w_mese_fine - 1;
         end if;
         if w_mese_fine > 6 then
            w_mese_fine := 6;
         end if;
      end if;
      w_mesi := w_mese_fine - w_mese_inizio + 1;
      return w_mesi;
   else
      return null;
   end if;
--
end;
/* End Function: F_TITOLO_MESI_POSSESSO_1SEM */
/

