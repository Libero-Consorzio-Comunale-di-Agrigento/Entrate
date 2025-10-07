--liquibase formatted sql 
--changeset abrandolini:20250326_152423_get_inpa_sosp_ferie stripComments:false runOnChange:true 
 
create or replace procedure GET_INPA_SOSP_FERIE
( p_anno                      number
, p_data_inizio               IN OUT date
, p_data_fine                 IN OUT date
, p_gg_sosp                   IN OUT number
) is
  w_data_in                   date;
  w_data_fi                   date;
  w_gg_sosp                   number;
begin
  --
  -- Si seleziona da INSTALLAZIONE_PARAMETRI il periodo di sospensione ferie
  --
  begin
    select to_date(substr(valore,1,5)||'/'||p_anno,'dd/mm/yyyy')
         , to_date(substr(valore,7,5)||'/'||p_anno,'dd/mm/yyyy')
      into w_data_in
         , w_data_fi
      from INSTALLAZIONE_PARAMETRI
     where parametro = 'SOSP_FERIE';
  exception
    when others then
      w_data_in := to_date(null);
      w_data_fi := to_date(null);
  end;
  --
  if w_data_in is not null and
     w_data_fi is not null then
     w_gg_sosp := w_data_fi - w_data_in + 1;
  else
     w_gg_sosp := 0;
  end if;
  p_data_inizio := w_data_in;
  p_data_fine   := w_data_fi;
  p_gg_sosp     := w_gg_sosp;
end;
/* End Procedure: GET_INPA_SOSP_FERIE */
/

