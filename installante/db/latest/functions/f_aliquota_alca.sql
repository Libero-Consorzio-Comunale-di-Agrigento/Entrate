--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_aliquota_alca stripComments:false runOnChange:true 
 
create or replace function F_ALIQUOTA_ALCA
/*************************************************************************
 NOME:        F_ALIQUOTA_ALCA
 DESCRIZIONE: Date le informazioni relative ad un oggetto pratica,
              verifica se esiste un'aliquota per categoria.
              Se l'oggetto e' di categoria 'C%' ed e' pertinenza
              di un altro oggetto, si ricerca l'eventuale aliquota
              per la categoria di quest'ultimo.
 RITORNA:     Number               Aliquota
 NOTE:
 Rev.    Date         Author      Note
 001     14/12/2016   VD          Modificata per gestire l'aliquota base.
                                  Aggiunto nuovo parametro a_aliquota_base
                                  con default null:
                                  se null, si restituisce l'aliquota
                                  se = 'S', si restituisce l'aliquota_base
 000                              Prima emissione.
*************************************************************************/
( a_anno                in number
, a_tipo_aliquota       in number
, a_categoria_catasto   in varchar2
, a_aliquota            in number
, a_oggetto_pratica     in number
, a_cod_fiscale         in varchar2
, a_tipo_tributo        in varchar2
, a_flag_aliquota_base  in varchar2  default null
)
  return number
is
  w_aliquota               number(6,2) := 0;
  w_fascia                 number;
  w_flag_integrazione_gsd  varchar2(1);
  w_pertinenza_di          number(10)  := null;
  w_caca_pertinenza_di     varchar2(3) := null;
begin
   -- AIRE
   begin
      select nvl(flag_integrazione_gsd,'N')
        into w_flag_integrazione_gsd
        from dati_generali
        ;
   exception
      when others then
         w_flag_integrazione_gsd := 'N';
   end;
   begin
      select decode(w_flag_integrazione_gsd
                   ,'S',F_MOV_FASCIA_AL(matricola
                                       ,to_number(to_char(to_date('0101'||to_char(a_anno),'ddmmyyyy'),'J'))
                                       )
                   ,nvl(sogg.fascia,-1)
                   )
        into w_fascia
        from soggetti     sogg
           , contribuenti cont
       where cont.ni          = sogg.ni
         and cont.cod_fiscale = a_cod_fiscale
       ;
   exception
      when others then
         w_fascia := -1;
   end;
   if w_fascia in (3,4)  then
      return a_aliquota;
   end if;
   if substr(a_categoria_catasto,1,1) = 'C' then
      begin
         select oggetto_pratica_rif_ap
           into w_pertinenza_di
           from oggetti_pratica
          where oggetto_pratica = a_oggetto_pratica
          ;
      exception
         when others then
           w_pertinenza_di := null;
      end;
   end if;
   if w_pertinenza_di is not null then
      w_caca_pertinenza_di := f_dato_riog(a_cod_fiscale,w_pertinenza_di,a_anno,'CA');
      begin
         select decode(a_flag_aliquota_base,null,aliquota,nvl(aliquota_base,a_aliquota))
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
      end;
   else
      begin
         select decode(a_flag_aliquota_base,null,aliquota,nvl(aliquota_base,a_aliquota))
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
      end;
   end if;
   return w_aliquota;
end;
/* End Function: F_ALIQUOTA_ALCA */
/

