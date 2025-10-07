--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_se_esiste_riog stripComments:false runOnChange:true 
 
create or replace function F_SE_ESISTE_RIOG
(p_oggetto    number
,p_pratica    number
,p_anno       number) return varchar2
is
  w_esiste    varchar2(1);
begin
  begin
    select distinct 'S' se_esiste
      into w_esiste
      from riferimenti_oggetto   riog
         , rivalutazioni_rendita rire
         , (select nvl(riog2.categoria_catasto,nvl(ogpr2.categoria_catasto,ogge2.categoria_catasto)) categoria_catasto
                 , riog2.inizio_validita inizio_validita
                 , nvl(ogpr2.tipo_oggetto,ogge2.tipo_oggetto) tipo_oggetto
              from riferimenti_oggetto riog2
                 , oggetti_pratica     ogpr2
                 , oggetti             ogge2
             where riog2.oggetto = p_oggetto
               and ogpr2.oggetto = p_oggetto
               and ogpr2.pratica = p_pratica
               and ogge2.oggetto = p_oggetto
          order by riog2.inizio_validita)
                             cat
     where cat.inizio_validita   = riog.inizio_validita
       and riog.oggetto          = p_oggetto
       and rire.anno             = p_anno
       and rire.tipo_oggetto     = cat.tipo_oggetto
       and p_anno               between riog.da_anno and riog.a_anno
    ;
  exception
    when others then w_esiste := null;
  end;
  return w_esiste;
end;
/* End Function: F_SE_ESISTE_RIOG */
/

