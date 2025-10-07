--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_vers_cont stripComments:false runOnChange:true 
 
create or replace function F_VERS_CONT
(p_anno    number,
 p_cf       varchar2,
 p_pratica    number,
 p_ogim      number,
 P_raim      number,
 p_titr    varchar2)
return number
IS
   w_vers_cont      number;
BEGIN
   select nvl(sum(vers.importo_versato),0) importo_versato
     into w_vers_cont
     from versamenti vers
    where ((p_pratica is NULL and vers.pratica is NULL )or vers.pratica = p_pratica)
      and ((p_ogim is NULL and vers.oggetto_imposta is NULL )or vers.oggetto_imposta = p_ogim)
      and ((p_raim is NULL and vers.rata_imposta is NULL )or vers.rata_imposta = p_raim)
      and vers.tipo_tributo||''   = p_titr
      and vers.cod_fiscale        = p_cf
      and vers.anno               = p_anno
    group by vers.cod_fiscale
  ;
      RETURN w_vers_cont;
EXCEPTION
  WHEN no_data_found THEN
   RETURN 0;
  WHEN others THEN
   RETURN NULL;
END;
/* End Function: F_VERS_CONT */
/

