--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_aliquota_alca_rif_ap stripComments:false runOnChange:true 
 
create or replace function F_ALIQUOTA_ALCA_RIF_AP
/*************************************************************************
 Rev  Data        Autore  Descrizione
 002  14/12/2016  VD      Modificata per gestire l'aliquota base.
                          Aggiunto nuovo parametro a_aliquota_base
                          con default null.
                          Utilizzato per passarlo alla funzione
                          F_ALIQUOTA_ALCA.
                          Inoltre, visto che manca la parte di controllo
                          sull'AIRE, si richiama la F_ALIQUOTA_ALCA passando
                          oggetto_pratica_rif_ap e relativa categoria catasto:
                          in questo modo la funzione restituira' l'aliquota
                          dell'oggetto_pratica_rif_ap.
 001  06/10/2016  VD      Modificata per gestire il caso di
                          oggetto_pratica_rif_ap = 0.
                          La funzione viene utilizzata in Power Builder nella
                          funzione uf_aliquota_lk della libreria tr4com.pbl.
                          La uf_aliquota_lk ha tra i parametri solo
                          l'oggetto_pratica (non c'e' l'oggetto_pratica_rif_ap)
                          e richiama la funzione di DB passando tale paramentro
                          in oggetto_pratica_rif_ap.
                          La uf_aliquota_lk viene utilizzata nel calcolo
                          individuale e nell'inserimento dell'accertamento ICI.
                          Nel primo caso, nell'oggetto_pratica viene in realta'
                          passato l'oggetto_pratica_rif_ap, mentre nel secondo
                          caso l'oggetto_pratica viene sempre passato a zero.
                          Da qui la necessita di gestire il caso di
                          oggetto_pratica_rif_ap = 0.
*************************************************************************/
( a_anno                   in number
, a_tipo_aliquota          in number
, a_categoria_catasto      in varchar2
, a_aliquota               in number
, a_oggetto_pratica        in number
, a_cod_fiscale            in varchar2
, a_tipo_tributo           in varchar2
, a_oggetto_pratica_rif_ap in number
, a_flag_aliquota_base     in varchar2  default null
)
return number
IS
  w_aliquota              number;
w_caca_pertinenza_di     varchar2(3) := null;
BEGIN
  w_aliquota := a_aliquota;
  if a_oggetto_pratica_rif_ap is null then
     w_aliquota := F_ALIQUOTA_ALCA(a_anno, a_tipo_aliquota, a_categoria_catasto,
                                   a_aliquota, a_oggetto_pratica, a_cod_fiscale,
                                   a_tipo_tributo, a_flag_aliquota_base);
  else
     --
     -- (VD - 06/10/2016): si testa che l'oggetto_pratica_rif sia non nullo e
     --                    diverso da zero.
     --
     --if a_oggetto_pratica_rif_ap is not null and substr(a_categoria_catasto,1,1) = 'C' then
     if nvl(a_oggetto_pratica_rif_ap,0) <> 0 and substr(a_categoria_catasto,1,1) = 'C' then
        w_caca_pertinenza_di := f_dato_riog(a_cod_fiscale,a_oggetto_pratica_rif_ap,a_anno,'CA');
        -- questa parte deve rimanere allineata alla parte corrispondente di F_ALIQUOTA_ALCA
        --
        -- (VD - 15/12/2016): visto che manca la parte di controllo sull'AIRE,
        --                    si richiama la F_ALIQUOTA_ALCA passando
        --                    oggetto_pratica_rif_ap e relativa categoria catasto:
        --                    in questo modo la funzione restituira' l'aliquota
        --                    dell'oggetto_pratica_rif_ap.
        w_aliquota := F_ALIQUOTA_ALCA(a_anno, a_tipo_aliquota, w_caca_pertinenza_di,
                                      a_aliquota, a_oggetto_pratica_rif_ap, a_cod_fiscale,
                                      a_tipo_tributo, a_flag_aliquota_base);
       /*begin
           select aliquota
             into w_aliquota
             from aliquote_categoria
            where anno              = a_anno
              and tipo_aliquota     = a_tipo_aliquota
              and categoria_catasto = w_caca_pertinenza_di
              and tipo_tributo      = a_tipo_tributo
              ;
        exception
           when others then
             w_aliquota := a_aliquota;
        end; */
     else
        w_aliquota := F_ALIQUOTA_ALCA(a_anno, a_tipo_aliquota, a_categoria_catasto,
                                      a_aliquota, a_oggetto_pratica, a_cod_fiscale,
                                      a_tipo_tributo, a_flag_aliquota_base);
        /*begin
           select aliquota
             into w_aliquota
             from aliquote_categoria
            where anno              = a_anno
              and tipo_aliquota     = a_tipo_aliquota
              and categoria_catasto = a_categoria_catasto
              and tipo_tributo      = a_tipo_tributo
              ;
        exception
           when others then
             w_aliquota := a_aliquota;
        end; */
     end if;
  end if;
  return w_aliquota;
END;
/* End Function: F_ALIQUOTA_ALCA_RIF_AP */
/

