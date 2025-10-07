--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_imposta_ruol_addiz_tarsu stripComments:false runOnChange:true 
 
create or replace function F_IMPOSTA_RUOL_ADDIZ_TARSU
(a_cod_fiscale    varchar2,
 a_anno    number,
 a_ogpr    number,
 a_cc      number,
 a_ruolo   number
) RETURN number
IS
   w_imposta           number;
BEGIN
      BEGIN
         select sum(ogim.imposta + nvl(ogim.ADDIZIONALE_ECA,0)
                               + nvl(ogim.ADDIZIONALE_PRO,0)
                         + nvl(ogim.IVA,0)
                         + nvl(ogim.MAGGIORAZIONE_ECA,0)
                )
           into w_imposta
           from CODICI_TRIBUTO COTR,
              TIPI_TRIBUTO titr,
            PRATICHE_TRIBUTO prtr,
                OGGETTI_PRATICA ogpr,
            OGGETTI_IMPOSTA ogim
          where nvl(cotr.conto_corrente,nvl(titr.conto_corrente,0)) = nvl(a_cc,0)
            and cotr.tributo         = ogpr.tributo
            and cotr.tipo_tributo      = prtr.tipo_tributo
            and ogim.cod_fiscale      = a_cod_fiscale
            and ogim.anno             = a_anno
            and ogim.flag_calcolo      = 'S'
            and titr.tipo_tributo     = prtr.tipo_tributo
            and prtr.tipo_tributo||''   = 'TARSU'
            and ogpr.oggetto_pratica   = ogim.oggetto_pratica
            and prtr.pratica         = ogpr.pratica
            and nvl(a_ogpr,ogim.oggetto_pratica) = ogim.oggetto_pratica
            and ogim.ruolo between nvl(a_ruolo,0) and
                  decode(nvl(a_ruolo,0),0,9999999999,nvl(a_ruolo,0))
         ;
         RETURN w_imposta;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
      RETURN NULL;
      END;
END;
/* End Function: F_IMPOSTA_RUOL_ADDIZ_TARSU */
/

