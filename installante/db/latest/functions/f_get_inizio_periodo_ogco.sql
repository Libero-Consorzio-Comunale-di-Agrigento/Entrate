--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_get_inizio_periodo_ogco stripComments:false runOnChange:true 
 
create or replace function F_GET_INIZIO_PERIODO_OGCO
/*************************************************************************
 NOME:        F_GET_INIZIO_PERIODO_OGCO
 DESCRIZIONE: Determina la data di inizio validità del periodo di
              oggetti_contribuente.
              Utilizzata nella vista OGGETTI_CONTRIBUENTE_ANNO.
 RITORNA:     date                Data di inizio validita del periodo OGCO.
 NOTE:
 Rev.    Date         Author      Note
 002     14/12/2021   AB          Impostato giorno = 16 per mesi_possesso = 0
 001     15/03/2021   VD          Corretta gestione mesi possesso > 12 e
                                  da_mese_possesso < 0.
 000     11/07/2019   VD          Prima emissione.
*************************************************************************/
( p_da_mese_possesso       number
, p_mesi_possesso          number
, p_flag_possesso          varchar2
, p_anno_ogco              number
) return date
is
  w_data_inizio            date;
      w_giorno                 number;
  w_mese                   number;
begin
  if nvl(p_mesi_possesso,12) = 0 then
        w_giorno := 16;
     if nvl(p_da_mese_possesso,0) between 1 and 12 then
        w_mese := p_da_mese_possesso;
     else
        if nvl(p_flag_possesso,'N') = 'S' then
           w_mese := 12;
        else
           w_mese := 1;
        end if;
     end if;
  else
     w_giorno := 1;
     if nvl(p_da_mese_possesso,0) between 1 and 12 then
        w_mese := p_da_mese_possesso;
     else
        if nvl(p_mesi_possesso,12) between 1 and 12 and
           nvl(p_da_mese_possesso,0) between 1 and 12 then
           if nvl(p_flag_possesso,'N') = 'S' then
              w_mese := 12 - nvl(p_mesi_possesso,12) + 1;
           else
              w_mese := 1;
           end if;
        else
           w_mese := 1;
        end if;
     end if;
  end if;
--
  if nvl(w_mese,0) < 1 or nvl(w_mese,0) > 12 then
     w_data_inizio := to_date('0101'||p_anno_ogco,'ddmmyyyy');
  else
     w_data_inizio := to_date(lpad(w_giorno,2,'0')||lpad(w_mese,2,'0')||p_anno_ogco,'ddmmyyyy');
  end if;
--
  return w_data_inizio;
--
end;
/* End Function: F_GET_INIZIO_PERIODO_OGCO */
/

