--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_determina_detr_acconto_ici stripComments:false runOnChange:true 
 
create or replace function F_DETERMINA_DETR_ACCONTO_ICI
(a_anno            IN NUMBER
,a_detrazione      IN NUMBER
,a_mesi            IN NUMBER
,a_mesi_1s         IN NUMBER
) Return NUMBER
is
nDetrazione                number;
nDetrazione_Anno           number;
nDetrazione_Anno_Prec      number;
nCoeff                     number;
BEGIN
   BEGIN
      select nvl(detr.detrazione_base,0) * nvl(a_mesi,0) / 12
            ,nvl(detr.detrazione_base,0) * nvl(a_mesi_1s,0) / 12
        into nDetrazione_Anno
            ,nDetrazione_Anno_Prec
        from detrazioni detr
       where detr.anno  = a_anno
         and tipo_tributo = 'ICI'
      ;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         nDetrazione_Anno := 0;
         nDetrazione_Anno_Prec := 0;
   END;
   if a_anno > 2000 and a_anno < 2012 then
      BEGIN
         select nvl(detr.detrazione_base,0) * nvl(a_mesi_1s,0) / 12
           into nDetrazione_Anno_Prec
           from detrazioni detr
          where detr.anno  = a_anno - 1
            and tipo_tributo = 'ICI'
         ;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            nDetrazione_Anno_Prec := 0;
      END;
   end if;
   if nDetrazione_Anno <> 0 then
      nCoeff := nvl(a_detrazione,0) / nDetrazione_Anno;
   else
      nCoeff := 0;
   end if;
   nDetrazione := round(nDetrazione_Anno_Prec * nCoeff,2);
   Return nDetrazione;
END;
/* End Function: F_DETERMINA_DETR_ACCONTO_ICI */
/

