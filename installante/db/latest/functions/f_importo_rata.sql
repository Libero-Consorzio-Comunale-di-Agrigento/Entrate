--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_importo_rata stripComments:false runOnChange:true 
 
create or replace function F_IMPORTO_RATA
(a_rata              in number
,a_cod_fiscale       in varchar2
,a_tipo_tributo      in varchar2
,a_anno              in number
,a_oggetto_imposta   in number
,a_lordo             in varchar2
) return number
is
nImporto             number;
BEGIN
   BEGIN
      select nvl(sum(raim.imposta +
                     decode(a_lordo,'S',nvl(raim.addizionale_eca,0) + nvl(raim.maggiorazione_eca,0) +
                                        nvl(raim.addizionale_pro,0) + nvl(raim.iva,0)
                                       ,0
                           )
                    ),0
                )
        into nImporto
        from rate_imposta raim
       where raim.rata           = a_rata
         and raim.cod_fiscale    = a_cod_fiscale
         and raim.tipo_tributo   = a_tipo_tributo
         and raim.anno           = a_anno
         and raim.oggetto_imposta
                           between nvl(a_oggetto_imposta,0)
                               and decode(a_oggetto_imposta,0,9999999999,a_Oggetto_imposta)
      ;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         nImporto := 0;
   END;
   Return nImporto;
END;
/* End Function: F_IMPORTO_RATA */
/

