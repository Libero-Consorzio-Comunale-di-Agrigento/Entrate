--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_get_data_inizio_ogco stripComments:false runOnChange:true 
 
create or replace function F_GET_DATA_INIZIO_OGCO
( p_da_mese_possesso       number
, p_mesi_possesso          number
, p_flag_possesso          varchar2
, p_anno_ogco              number
, p_anno                   number
) return date
is
  w_data_inizio            date;
  w_giorno                 number;
  w_mese                   number;
begin
  if p_anno = p_anno_ogco then
     if nvl(p_mesi_possesso,12) = 0 then
        w_giorno := 16;
        if (nvl(p_da_mese_possesso,0) = 0 or nvl(p_da_mese_possesso,0) > 12) then
           if nvl(p_flag_possesso,'N') = 'S' then
              w_mese := 12;
           else
              w_mese := 1;
           end if;
        else
           w_mese := p_da_mese_possesso;
        end if;
     else
        w_giorno := 1;
        if (nvl(p_da_mese_possesso,0) = 0 or nvl(p_da_mese_possesso,0) > 12) then
           if nvl(p_flag_possesso,'N') = 'S' then
              w_mese := 12 - nvl(p_mesi_possesso,12) + 1;
           else
              w_mese := 1;
           end if;
        else
           w_mese := p_da_mese_possesso;
        end if;
     end if;
  else
     w_giorno := 1;
     w_mese := 1;
  end if;
--
  if nvl(w_mese,0) < 1 or nvl(w_mese,0) > 12 then
     w_data_inizio := to_date(null);
  else
     w_data_inizio := to_date(lpad(w_giorno,2,'0')||lpad(w_mese,2,'0')||p_anno,'ddmmyyyy');
  end if;
  return w_data_inizio;
--
end;
/* End Function: F_GET_DATA_INIZIO_OGCO */
/

