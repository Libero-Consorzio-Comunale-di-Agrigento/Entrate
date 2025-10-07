--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_get_perc_occupante stripComments:false runOnChange:true 
 
create or replace function F_GET_PERC_OCCUPANTE
( p_tipo_tributo            varchar2
, p_anno                    number
, p_tipo_aliquota           number
)
  return varchar
is
  w_perc_occupante          number;
/******************************************************************************
  Restituisce la percentuale occupante per tipo tributo e tipo aliquota
  indicati (solo per TASI)
******************************************************************************/
begin
  begin
    select nvl(perc_occupante,0)
      into w_perc_occupante
      from aliquote
     where tipo_tributo  = p_tipo_tributo
       and anno          = p_anno
       and tipo_aliquota = p_tipo_aliquota;
  exception
    when others
    then
      w_perc_occupante := 0;
  end;
  return w_perc_occupante;
end;
/* End Function: F_GET_PERC_OCCUPANTE */
/

