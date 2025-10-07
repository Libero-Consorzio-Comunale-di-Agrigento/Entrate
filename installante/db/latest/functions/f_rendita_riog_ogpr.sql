--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_rendita_riog_ogpr stripComments:false runOnChange:true 
 
create or replace function F_RENDITA_RIOG_OGPR
/*************************************************************************
 NOME:        F_RENDITA_RIOG_OGPR
 DESCRIZIONE: Dato un oggetto_pratica, se esiste restituisce la rendita di
              RIOG per l'anno indicato.
              Se questa non esiste, restituisce la rendita ricavata dal
              valore indicato in denuncia.
 Rev.    Date         Author      Note
 000     04/01/2021   VD          Prima emissione.
*************************************************************************/
( p_oggetto_pratica        number
, p_anno                   number
) return number is
  w_rendita                number;
begin
  -- Si seleziona la rendita da RIOG
  begin
    select f_get_rendita_riog(ogpr.oggetto,p_anno,to_date(null))
      into w_rendita
      from oggetti_pratica ogpr
     where ogpr.oggetto_pratica = p_oggetto_pratica;
  exception
    when others then
      w_rendita := to_number(null);
  end;
  if w_rendita is null then
     begin
       select f_rendita(f_valore(ogpr.valore
                                ,ogpr.tipo_oggetto
                                ,prtr.anno
                                ,p_anno
                                ,nvl(ogpr.categoria_catasto,ogge.categoria_catasto)
                                ,prtr.tipo_pratica
                                ,ogpr.flag_valore_rivalutato
                                )
                        ,ogge.tipo_oggetto
                        ,p_anno
                        ,nvl(ogpr.categoria_catasto,ogge.categoria_catasto)
                        )
         into w_rendita
         from oggetti_pratica  ogpr
            , pratiche_tributo prtr
            , oggetti          ogge
        where ogpr.oggetto_pratica = p_oggetto_pratica
          and ogpr.pratica = prtr.pratica
          and ogpr.oggetto = ogge.oggetto;
     exception
       when others then
         w_rendita := to_number(null);
     end;
  end if;
  return w_rendita;
end;
/* End Function: F_RENDITA_RIOG_OGPR */
/

