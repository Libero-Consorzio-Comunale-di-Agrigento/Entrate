--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_get_decorrenza_cessazione stripComments:false runOnChange:true 
 
create or replace function F_GET_DECORRENZA_CESSAZIONE
/*************************************************************************
 NOME:        F_GET_DECORRENZA_CESSAZIONE
 DESCRIZIONE: Solo per la denuncia TARSU.
              Data una data di inizio (p_flag_giorno = 0) o fine occupazione
              (p_flag_giorno = 1), determina la data di decorrenza o di
              cessazione in base alla periodicita dei carichi TARSU.
              In assenza di carichi tarsu per l'anno di riferimento o la
              mancanza del valore nella registrazione in tabella, fa assumere
              come valore di difetto 2 che corrisponde ai bimestri.
 RITORNA:     date
 NOTE:
 Rev.    Date         Author      Note
 00      16/02/2021   VD          Prima emissione.
*************************************************************************/
( p_data_in                        in date
, p_flag_giorno                    in number
) return date
is
  w_data_out                       date;
  w_mesi_calcolo                   number;
begin
  if p_data_in is null then
     return to_date(null);
  end if;
  begin
     select nvl(cata.mesi_calcolo,2)
       into w_mesi_calcolo
       from carichi_tarsu cata
      where cata.anno = to_number(to_char(p_data_in,'yyyy'))
         ;
  exception
     when no_data_found then
       w_mesi_calcolo := 2;
     when others then
       w_mesi_calcolo := 2;
  end;
  if w_mesi_calcolo = 0 then
     w_data_out := p_data_in;
  else
     w_data_out := to_date('01'||to_char(p_data_in,'mmyyyy'),'ddmmyyyy');
     if w_mesi_calcolo = 2 then
        if to_char(p_data_in,'mm') in ('02','04','06','08','10','12') then
           w_data_out := add_months(to_date('01'||to_char(p_data_in,'mmyyyy'),'ddmmyyyy'),-1);
        end if;
     end if;
     w_data_out := add_months(w_data_out,w_mesi_calcolo) - p_flag_giorno;
  end if;
  return w_data_out;
end;
/* End Function: F_GET_DECORRENZA_CESSAZIONE */
/

