--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_sanz_ravv_per_liq stripComments:false runOnChange:true 
 
create or replace function F_SANZ_RAVV_PER_LIQ
(p_pratica IN number)
Return number IS
nImporto number;
BEGIN
   select nvl(sum(nvl(sapr.importo,0)),0)
     into nImporto
     from sanzioni_pratica sapr
    where sapr.cod_sanzione not in (1,21,101,121)
      and sapr.pratica        = p_pratica
   ;
   Return nImporto;
END;
/* End Function: F_SANZ_RAVV_PER_LIQ */
/

