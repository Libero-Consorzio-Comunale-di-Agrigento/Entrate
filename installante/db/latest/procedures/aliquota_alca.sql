--liquibase formatted sql 
--changeset abrandolini:20250326_152423_aliquota_alca stripComments:false runOnChange:true 
 
create or replace procedure ALIQUOTA_ALCA
(a_anno                in number
,a_tipo_aliquota       in number
,a_categoria_catasto   in varchar2
,a_aliquota            in number
,a_oggetto_pratica     in number
,a_cod_fiscale         in varchar2
,a_tipo_tributo        in varchar2
,a_aliquota_alca       in out number
,a_esiste_alca         in out varchar2)
is
w_aliquota               number(6,2) := 0;
w_fascia                 number;
w_flag_integrazione_gsd  varchar2(1);
w_pertinenza_di          number(10)  := null;
w_caca_pertinenza_di     varchar2(3) := null;
w_esiste_alca            varchar2(1) := 'S';
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
      w_aliquota := a_aliquota;
      w_esiste_alca  := 'N';
   else
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
              w_esiste_alca := 'N';
         end;
      else
         begin
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
              w_esiste_alca := 'N';
         end;
      end if;
   end if;
   a_aliquota_alca := w_aliquota;
   a_esiste_alca   := w_esiste_alca;
end;
/* End Procedure: ALIQUOTA_ALCA */
/

