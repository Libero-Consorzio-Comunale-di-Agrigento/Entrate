--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_get_ab_principale stripComments:false runOnChange:true 
 
create or replace function F_GET_AB_PRINCIPALE
( p_cod_fiscale            varchar2
, p_anno                   number
, p_oggetto_pratica        number
) return varchar2
is
  w_flag_ab_principale     varchar2(1);
begin
  begin
    select decode(nvl(ogco.flag_ab_principale,'N')
                 ,'S','S'
                 ,decode(ogco.anno
                        ,p_anno,decode(ogco.flag_possesso
                                      ,'S',ogco.flag_ab_principale
                                      ,decode(ogco.detrazione
                                             ,null,null
                                             ,'S'
                                             )
                                      )
                        ,null
                        )
                 )
      into w_flag_ab_principale
      from oggetti_contribuente ogco
     where ogco.cod_fiscale = p_cod_fiscale
       and ogco.oggetto_pratica = p_oggetto_pratica;
  exception
    when others then
      w_flag_ab_principale := null;
  end;
  --
  return w_flag_ab_principale;
  --
end;
/* End Function: F_GET_AB_PRINCIPALE */
/

