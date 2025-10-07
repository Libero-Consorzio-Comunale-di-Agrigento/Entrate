--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_descrizione_caca stripComments:false runOnChange:true 
 
create or replace function F_DESCRIZIONE_CACA
(p_categoria_catasto varchar2)
  return varchar2
is
  w_descr_caca   categorie_catasto.descrizione%type;
BEGIN
  select descrizione
  into   w_descr_caca
  from   categorie_catasto caca
  where  caca.categoria_catasto = p_categoria_catasto
  ;
  return w_descr_caca;
EXCEPTION
  when others then return null;
END;
/* End Function: F_DESCRIZIONE_CACA */
/

