--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_vers_cont_liq stripComments:false runOnChange:true 
 
create or replace function F_VERS_CONT_LIQ
(p_anno       number,
 p_cf         varchar2,
 p_data_liq   date,
 p_titr       varchar2)
return number
IS
   w_vers_cont        number;
BEGIN
   select nvl(sum(vers.importo_versato),0) + F_IMPORTO_VERS_RAVV(p_cf,p_titr,p_anno,'U') importo_versato
     into w_vers_cont
     from versamenti vers
    where vers.pratica is NULL
      and vers.oggetto_imposta is NULL
      and vers.rata_imposta is NULL
      and vers.tipo_tributo||''   = p_titr
      and vers.cod_fiscale        = p_cf
      and vers.anno               = p_anno
      and vers.data_pagamento     <= p_data_liq
   ;
      RETURN w_vers_cont;
EXCEPTION
  WHEN no_data_found THEN
    RETURN 0;
  WHEN others THEN
    RETURN NULL;
END;
/* End Function: F_VERS_CONT_LIQ */
/

