--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_sgravio_prtr stripComments:false runOnChange:true 
 
create or replace function F_SGRAVIO_PRTR
(a_cod_fiscale    varchar2,
 a_anno       number,
 a_titr       varchar2,
 a_pratica         number
)
RETURN number
IS
   w_imposta    number;
BEGIN
   IF a_titr = 'TARSU' then
      BEGIN
         select sum(sgra.importo)
           into w_imposta
           from sgravi sgra,
                ruoli_contribuente ruco,
                ruoli ruol,
                oggetti_imposta  ogim,
            oggetti_pratica  ogpr
          where ruco.ruolo            = ruol.ruolo
            and ruol.anno_ruolo       = a_anno
            and ruol.tipo_tributo||'' = a_titr
            and sgra.cod_fiscale      = a_cod_fiscale
            and ruco.cod_fiscale      = a_cod_fiscale
            and ruco.sequenza         = sgra.sequenza
            and ruco.ruolo            = sgra.ruolo
            and ruco.ruolo            = ogim.ruolo
            and ruco.oggetto_imposta  = ogim.oggetto_imposta
            and ogim.oggetto_pratica  = ogpr.oggetto_pratica
         and ogpr.pratica          = a_pratica
            and ogim.cod_fiscale      = a_cod_fiscale
            and ogim.anno             = a_anno
         ;
         RETURN w_imposta;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            RETURN NULL;
      END;
   ELSE
      RETURN NULL;
   END IF;
END;
/* End Function: F_SGRAVIO_PRTR */
/

