--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_add_pro_pert_ruolo stripComments:false runOnChange:true 
 
create or replace function F_ADD_PRO_PERT_RUOLO
(a_ogpr    number
,a_ruolo   number
,a_tributo number)
RETURN number
IS
   w_return number;
BEGIN
   BEGIN
   select nvl(sum(nvl(ogim.addizionale_pro,0)),0)
     into w_return
     from ruoli_contribuente ruco
        , oggetti_imposta    ogim
        , oggetti_pratica    ogpr
        , pratiche_tributo   prtr
    where ruco.oggetto_imposta  = ogim.oggetto_imposta
      and ogim.oggetto_pratica  = ogpr.oggetto_pratica
      and ogpr.pratica          = prtr.pratica
      and ogpr.oggetto_pratica_rif_ap = a_ogpr
      and ruco.ruolo  = a_ruolo
      and ruco.tributo + 0 = a_tributo
      and prtr.tipo_tributo||'' = 'TARSU'
   ;
   EXCEPTION
   WHEN others THEN
          w_return := 0;
  END;
  RETURN w_return;
END;
/* End Function: F_ADD_PRO_PERT_RUOLO */
/

