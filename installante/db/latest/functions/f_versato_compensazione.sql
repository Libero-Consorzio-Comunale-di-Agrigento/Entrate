--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_versato_compensazione stripComments:false runOnChange:true 
 
create or replace function F_VERSATO_COMPENSAZIONE
( a_id_compensazione              in number
, a_cod_fiscale                   in varchar2
, a_anno                          in varchar2
, a_tipo_tributo                  in varchar2
) Return varchar2 is
nVersamento                number;
nVersamento_prec           number;
vReturn                    varchar2(1000);
BEGIN
   begin
      select importo_versato
        into nVersamento
        from versamenti
       where cod_fiscale  = a_cod_fiscale
         and id_compensazione = a_id_compensazione
         and anno = a_anno
         and tipo_tributo = a_tipo_tributo
        ;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         Return 'Non Presente';
      WHEN too_many_rows THEN
         Return 'Errati';
   END;
   begin
      select importo_versato
        into nVersamento_prec
        from versamenti
       where cod_fiscale  = a_cod_fiscale
         and id_compensazione = a_id_compensazione
         and anno = a_anno - 1
         and tipo_tributo = a_tipo_tributo
        ;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
        Return 'Non Presente (-)';
      WHEN too_many_rows THEN
         Return  'Errati (-)';
   END;
   if nVersamento = - nVersamento_prec then
      return translate(to_char(nVersamento,'9,999,990.00'),'.,',',.');
   else
      return 'Non Coerenti';
   end if;
END;
/* End Function: F_VERSATO_COMPENSAZIONE */
/

