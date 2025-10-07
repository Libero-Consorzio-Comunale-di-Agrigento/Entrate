--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_get_progr_invio_ruoli stripComments:false runOnChange:true 
 
create or replace function F_GET_PROGR_INVIO_RUOLI
( p_anno                                number
) return number
is
  w_progr_invio                         number;
begin
  select nvl(max(progr_invio),0)
    into w_progr_invio
    from ruoli
   where specie_ruolo = 1
     and extract (year from invio_consorzio) = p_anno;
--
  return w_progr_invio;
end;
/* End Function: F_GET_PROGR_INVIO_RUOLI */
/

