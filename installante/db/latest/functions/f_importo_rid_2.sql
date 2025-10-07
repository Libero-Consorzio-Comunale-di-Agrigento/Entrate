--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_importo_rid_2 stripComments:false runOnChange:true 
 
create or replace function F_IMPORTO_RID_2
(a_pratica              in number
) return number
is
nImporto             number;
BEGIN
   BEGIN
      select sum(round(sapr.importo
                       * (100 - nvl(sapr.riduzione_2,0))
                       / 100
                      ,2))
        into nImporto
        from sanzioni_pratica sapr
       where sapr.pratica  = a_pratica
         and nvl(sapr.riduzione_2,0) > 0
      ;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         nImporto := 0;
   END;
   Return nImporto;
END;
/* End Function: F_IMPORTO_RID_2 */
/

