--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_sgravio_ogpr stripComments:false runOnChange:true 
 
create or replace function F_SGRAVIO_OGPR
(a_cod_fiscale    varchar2,
 a_anno       number,
 a_titr       varchar2,
 a_ogpr       number
)
RETURN number
IS
   w_imposta    number;
BEGIN
   IF a_titr = 'TARSU' then
--
-- Ritorna sempre il valore netto
--
      BEGIN
         select sum(sgra.importo - nvl(sgra.addizionale_eca,0)
                                 - nvl(sgra.maggiorazione_eca,0)
                                 - nvl(sgra.addizionale_pro,0)
                                 - nvl(sgra.iva,0)
                                 - nvl(sgra.maggiorazione_tares,0)
                   )
           into w_imposta
           from sgravi sgra,
                ruoli_contribuente ruco,
                ruoli ruol,
                oggetti_imposta ogim
          where ruco.ruolo            = ruol.ruolo
            and NVL (F_RUOLO_TOTALE (a_COD_FISCALE,  -- AB aggiunto x ruolo totale  controllo il 22/06/2015
                                  a_anno,
                                  a_titr,
                                  -1),
                  ruol.ruolo) = ruol.ruolo
            and ruol.anno_ruolo       = a_anno
            and ruol.tipo_tributo||'' = a_titr
            and ruol.invio_consorzio is not null
            and sgra.cod_fiscale      = a_cod_fiscale
            and ruco.cod_fiscale      = a_cod_fiscale
            and ruco.sequenza         = sgra.sequenza
            and ruco.ruolo            = sgra.ruolo
            and ruco.ruolo            = ogim.ruolo
            and ruco.oggetto_imposta  = ogim.oggetto_imposta
            and ogim.oggetto_pratica  = a_ogpr
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
/* End Function: F_SGRAVIO_OGPR */
/

