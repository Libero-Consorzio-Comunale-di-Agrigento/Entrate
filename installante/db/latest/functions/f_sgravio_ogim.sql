--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_sgravio_ogim stripComments:false runOnChange:true 
 
create or replace function F_SGRAVIO_OGIM
( a_cod_fiscale  varchar2
, a_anno         number
, a_titr         varchar2
, a_ogpr         number
, a_ogim         number
, a_netto        varchar2
, a_campo        varchar2 default null
)
RETURN number
IS
   w_imposta    number;
BEGIN
   IF a_titr = 'TARSU' then
      if a_campo is null or lower(a_campo) = 'importo' then
--
-- Se a_netto = 'S' ritorna il valore netto
--    a_netto = 'SMG' ritorna il valore al netto della sola maggiorazione tares
--
          BEGIN
             select sum(sgra.importo +
                        decode(a_netto, 'SMG', 0 - nvl(sgra.maggiorazione_tares,0)
                              ,'S',0 - nvl(sgra.addizionale_eca,0)
                                     - nvl(sgra.maggiorazione_eca,0)
                                     - nvl(sgra.addizionale_pro,0)
                                     - nvl(sgra.iva,0)
                                     - nvl(sgra.maggiorazione_tares,0)
                              ,0
                              )
                       )
               into w_imposta
               from sgravi sgra,
                    ruoli_contribuente ruco,
                    ruoli ruol,
                    oggetti_imposta ogim
              where ruco.ruolo            = ruol.ruolo
                and ruol.anno_ruolo       = a_anno
                and ruol.tipo_tributo||'' = a_titr
                and sgra.cod_fiscale      = a_cod_fiscale
                and ruco.cod_fiscale      = a_cod_fiscale
                and ruco.sequenza         = sgra.sequenza
                and ruco.ruolo            = sgra.ruolo
                and ruco.ruolo            = ogim.ruolo
                and ruco.oggetto_imposta  = ogim.oggetto_imposta
                and ogim.oggetto_pratica  = a_ogpr
                and ogim.cod_fiscale      = a_cod_fiscale
                and ogim.anno             = a_anno
                and ogim.oggetto_imposta  = a_ogim
    --            and sgra.motivo_sgravio   <> 99   tolto il 7/4/2014 perche gli sgravi dovrebbero essere sempre tolti
    --                                              ragionare sulla gestione della compensazione
             ;
             RETURN w_imposta;
          EXCEPTION
             WHEN NO_DATA_FOUND THEN
                RETURN NULL;
          END;
      end if;
      if a_campo is not null and lower(a_campo) = 'addizionale_eca' then
             select sum(nvl(sgra.addizionale_eca,0)
                       )
               into w_imposta
               from sgravi sgra,
                    ruoli_contribuente ruco,
                    ruoli ruol,
                    oggetti_imposta ogim
              where ruco.ruolo            = ruol.ruolo
                and ruol.anno_ruolo       = a_anno
                and ruol.tipo_tributo||'' = a_titr
                and sgra.cod_fiscale      = a_cod_fiscale
                and ruco.cod_fiscale      = a_cod_fiscale
                and ruco.sequenza         = sgra.sequenza
                and ruco.ruolo            = sgra.ruolo
                and ruco.ruolo            = ogim.ruolo
                and ruco.oggetto_imposta  = ogim.oggetto_imposta
                and ogim.oggetto_pratica  = a_ogpr
                and ogim.cod_fiscale      = a_cod_fiscale
                and ogim.anno             = a_anno
                and ogim.oggetto_imposta  = a_ogim
    --            and sgra.motivo_sgravio   <> 99   tolto il 7/4/2014 perche gli sgravi dovrebbero essere sempre tolti
    --                                              ragionare sulla gestione della compensazione
             ;
             RETURN w_imposta;
      end if;
      if a_campo is not null and lower(a_campo) = 'maggiorazione_eca' then
             select sum(nvl(sgra.maggiorazione_eca,0)
                       )
               into w_imposta
               from sgravi sgra,
                    ruoli_contribuente ruco,
                    ruoli ruol,
                    oggetti_imposta ogim
              where ruco.ruolo            = ruol.ruolo
                and ruol.anno_ruolo       = a_anno
                and ruol.tipo_tributo||'' = a_titr
                and sgra.cod_fiscale      = a_cod_fiscale
                and ruco.cod_fiscale      = a_cod_fiscale
                and ruco.sequenza         = sgra.sequenza
                and ruco.ruolo            = sgra.ruolo
                and ruco.ruolo            = ogim.ruolo
                and ruco.oggetto_imposta  = ogim.oggetto_imposta
                and ogim.oggetto_pratica  = a_ogpr
                and ogim.cod_fiscale      = a_cod_fiscale
                and ogim.anno             = a_anno
                and ogim.oggetto_imposta  = a_ogim
    --            and sgra.motivo_sgravio   <> 99   tolto il 7/4/2014 perche gli sgravi dovrebbero essere sempre tolti
    --                                              ragionare sulla gestione della compensazione
             ;
             RETURN w_imposta;
      end if;
      if a_campo is not null and lower(a_campo) = 'addizionale_pro' then
             select sum(nvl(sgra.addizionale_pro,0)
                       )
               into w_imposta
               from sgravi sgra,
                    ruoli_contribuente ruco,
                    ruoli ruol,
                    oggetti_imposta ogim
              where ruco.ruolo            = ruol.ruolo
                and ruol.anno_ruolo       = a_anno
                and ruol.tipo_tributo||'' = a_titr
                and sgra.cod_fiscale      = a_cod_fiscale
                and ruco.cod_fiscale      = a_cod_fiscale
                and ruco.sequenza         = sgra.sequenza
                and ruco.ruolo            = sgra.ruolo
                and ruco.ruolo            = ogim.ruolo
                and ruco.oggetto_imposta  = ogim.oggetto_imposta
                and ogim.oggetto_pratica  = a_ogpr
                and ogim.cod_fiscale      = a_cod_fiscale
                and ogim.anno             = a_anno
                and ogim.oggetto_imposta  = a_ogim
    --            and sgra.motivo_sgravio   <> 99   tolto il 7/4/2014 perche gli sgravi dovrebbero essere sempre tolti
    --                                              ragionare sulla gestione della compensazione
             ;
             RETURN w_imposta;
      end if;
      if a_campo is not null and lower(a_campo) = 'iva' then
             select sum(nvl(sgra.iva,0)
                       )
               into w_imposta
               from sgravi sgra,
                    ruoli_contribuente ruco,
                    ruoli ruol,
                    oggetti_imposta ogim
              where ruco.ruolo            = ruol.ruolo
                and ruol.anno_ruolo       = a_anno
                and ruol.tipo_tributo||'' = a_titr
                and sgra.cod_fiscale      = a_cod_fiscale
                and ruco.cod_fiscale      = a_cod_fiscale
                and ruco.sequenza         = sgra.sequenza
                and ruco.ruolo            = sgra.ruolo
                and ruco.ruolo            = ogim.ruolo
                and ruco.oggetto_imposta  = ogim.oggetto_imposta
                and ogim.oggetto_pratica  = a_ogpr
                and ogim.cod_fiscale      = a_cod_fiscale
                and ogim.anno             = a_anno
                and ogim.oggetto_imposta  = a_ogim
    --            and sgra.motivo_sgravio   <> 99   tolto il 7/4/2014 perche gli sgravi dovrebbero essere sempre tolti
    --                                              ragionare sulla gestione della compensazione
             ;
             RETURN w_imposta;
      end if;
      if a_campo is not null and lower(a_campo) = 'maggiorazione_tares' then
             select sum(nvl(sgra.maggiorazione_tares,0)
                       )
               into w_imposta
               from sgravi sgra,
                    ruoli_contribuente ruco,
                    ruoli ruol,
                    oggetti_imposta ogim
              where ruco.ruolo            = ruol.ruolo
                and ruol.anno_ruolo       = a_anno
                and ruol.tipo_tributo||'' = a_titr
                and sgra.cod_fiscale      = a_cod_fiscale
                and ruco.cod_fiscale      = a_cod_fiscale
                and ruco.sequenza         = sgra.sequenza
                and ruco.ruolo            = sgra.ruolo
                and ruco.ruolo            = ogim.ruolo
                and ruco.oggetto_imposta  = ogim.oggetto_imposta
                and ogim.oggetto_pratica  = a_ogpr
                and ogim.cod_fiscale      = a_cod_fiscale
                and ogim.anno             = a_anno
                and ogim.oggetto_imposta  = a_ogim
    --            and sgra.motivo_sgravio   <> 99   tolto il 7/4/2014 perche gli sgravi dovrebbero essere sempre tolti
    --                                              ragionare sulla gestione della compensazione
             ;
             RETURN w_imposta;
      end if;
   ELSE
      RETURN NULL;
   END IF;
END;
/* End Function: F_SGRAVIO_OGIM */
/

