--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_get_cata_perc stripComments:false runOnChange:true 
 
create or replace function F_GET_CATA_PERC
( p_anno                   number
, p_tipo_add               varchar2
) return number is
  w_perc_add               number;
begin
  begin
    select decode(p_tipo_add
                 ,'AE',addizionale_eca
                 ,'ME',maggiorazione_eca
                 ,'AP',addizionale_pro
                 )
      into w_perc_add
      from CARICHI_TARSU
     where anno = p_anno;
  exception
    when others then
      w_perc_add := 0;
  end;
  return w_perc_add;
end;
/* End Function: F_GET_CATA_PERC */
/

