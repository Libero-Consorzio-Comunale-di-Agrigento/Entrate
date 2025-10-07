--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_compensazione_ogpr stripComments:false runOnChange:true 
 
create or replace function F_COMPENSAZIONE_OGPR
( a_cod_fiscale  varchar2
, a_anno         number
, a_titr         varchar2
, a_ogpr         number
, a_netto        varchar2
)
RETURN number
IS
   w_imposta    number;
BEGIN
   IF a_titr = 'TARSU' then
      BEGIN
         select sum(coru.compensazione +
                    decode(a_netto
                          ,'S',0 - round(coru.compensazione * nvl(cata.addizionale_eca,0)
                                         / (100 + nvl(cata.addizionale_eca,0) + nvl(cata.maggiorazione_eca,0) + nvl(cata.addizionale_pro,0) + nvl(cata.aliquota,0))
                                        ,2)
                                 - round(coru.compensazione * nvl(cata.maggiorazione_eca,0)
                                         / (100 + nvl(cata.addizionale_eca,0) + nvl(cata.maggiorazione_eca,0) + nvl(cata.addizionale_pro,0) + nvl(cata.aliquota,0))
                                        ,2)
                                 - round(coru.compensazione * nvl(cata.addizionale_pro,0)
                                         / (100 + nvl(cata.addizionale_eca,0) + nvl(cata.maggiorazione_eca,0) + nvl(cata.addizionale_pro,0) + nvl(cata.aliquota,0))
                                        ,2)
                                 - round(coru.compensazione * nvl(cata.aliquota,0)
                                         / (100 + nvl(cata.addizionale_eca,0) + nvl(cata.maggiorazione_eca,0) + nvl(cata.addizionale_pro,0) + nvl(cata.aliquota,0))
                                        ,2)
                          ,0
                          )
         )
           into w_imposta
           from compensazioni_ruolo coru
              , ruoli               ruol
              , oggetti_imposta     ogim
              , carichi_tarsu       cata
          where cata.anno             = a_anno
            and coru.ruolo            = ruol.ruolo
            and coru.anno             = a_anno
            and ruol.anno_ruolo       = a_anno
            and ruol.tipo_tributo||'' = a_titr
            and coru.cod_fiscale      = a_cod_fiscale
            and coru.oggetto_pratica  = ogim.oggetto_pratica
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
/* End Function: F_COMPENSAZIONE_OGPR */
/

