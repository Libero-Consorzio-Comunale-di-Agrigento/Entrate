--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_get_denominazione_via stripComments:false runOnChange:true 
 
create or replace function F_GET_DENOMINAZIONE_VIA
( p_cod_via                            number
) return varchar2
is
  w_denominazione_via                  archivio_vie.denom_uff%type;
begin
  begin
    select denom_uff
      into w_denominazione_via
      from archivio_vie
     where cod_via = p_cod_via;
  exception
    when others then
      w_denominazione_via := null;
  end;
  return w_denominazione_via;
end;
/* End Function: F_GET_DENOMINAZIONE_VIA */
/

