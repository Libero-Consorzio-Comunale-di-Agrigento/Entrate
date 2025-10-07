--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_cate_riog_null stripComments:false runOnChange:true 
 
create or replace function F_CATE_RIOG_NULL
(p_ogge    number,
 p_anno    number)
return varchar2
is
w_return varchar2(3);
begin
     select riog.categoria_catasto
       into w_return
       from riferimenti_oggetto  riog
      where riog.oggetto(+)  = p_ogge
   and riog.da_anno(+) <= p_anno
   and riog.a_anno(+)  >= p_anno
     ;
     return w_return;
exception
  when others then
     return null;
end;
/* End Function: F_CATE_RIOG_NULL */
/

