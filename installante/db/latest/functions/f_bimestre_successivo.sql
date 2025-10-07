--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_bimestre_successivo stripComments:false runOnChange:true 
 
create or replace function F_BIMESTRE_SUCCESSIVO
(a_data_in   in date)
RETURN date
IS
w_data_out     date;
w_mesi_calcolo number;
BEGIN
  if a_data_in is null then
     return  null;
  end if;
  begin
     select nvl(cata.mesi_calcolo,2)
       into w_mesi_calcolo
       from carichi_tarsu cata
      where cata.anno = to_number(to_char(a_data_in,'yyyy'))
         ;
  exception
     when no_data_found then
       w_mesi_calcolo := 2;
     when others then
       w_mesi_calcolo := 2;
  end;
  if w_mesi_calcolo = 1 then
    w_data_out := add_months(to_date('01'||to_char(a_data_in,'mmyyyy'),'ddmmyyyy'),1);
  elsif w_mesi_calcolo = 2 then
    w_data_out := to_date('01'||to_char(a_data_in,'mmyyyy'),'ddmmyyyy');
    if to_char(a_data_in,'mm') in ('02','04','06','08','10','12') then
      w_data_out := add_months(to_date('01'||to_char(a_data_in,'mmyyyy'),'ddmmyyyy'),1);
    else
      w_data_out := add_months(to_date('01'||to_char(a_data_in,'mmyyyy'),'ddmmyyyy'),2);
    end if;
  else
    return  null;
  end if;
  return w_data_out;
END;
/* End Function: F_BIMESTRE_SUCCESSIVO */
/

