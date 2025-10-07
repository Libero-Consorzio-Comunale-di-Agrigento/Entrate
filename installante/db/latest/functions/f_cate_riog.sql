--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_cate_riog stripComments:false runOnChange:true 
 
create or replace function F_CATE_RIOG
(p_ogge    number,
 p_anno    number)
return varchar2
is
w_cate_riog varchar2(3);
w_cate_ogge varchar2(3);
w_tipo_ogge number;
w_return    varchar2(3);
cursor sel_ogge is
select riog.categoria_catasto
  from riferimenti_oggetto  riog
 where riog.oggetto            = p_ogge
   and riog.da_anno           <= p_anno
   and riog.a_anno            >= p_anno
 order by
       riog.da_anno desc
      ,riog.a_anno  desc
;
begin
   begin
      select decode(ogge.tipo_oggetto
                   ,1,'T'
                     ,ogge.categoria_catasto
                )
            ,ogge.tipo_oggetto
        into w_cate_ogge
            ,w_tipo_ogge
        from oggetti              ogge
       where ogge.oggetto     = p_ogge
      ;
   exception
      when others then
         return null;
   end;
   if w_tipo_ogge = 1 then
      Return 'T';
   end if;
   open sel_ogge;
   fetch sel_ogge into w_cate_riog;
   if sel_ogge%NOTFOUND then
      close sel_ogge;
      Return w_cate_ogge;
   else
      close sel_ogge;
      if w_cate_riog is null then
         w_cate_riog := w_cate_ogge;
      end if;
      Return w_cate_riog;
   end if;
exception
   when others then
      Return null;
end;
/* End Function: F_CATE_RIOG */
/

