--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_magg_tares_cont_anno_titr stripComments:false runOnChange:true 
 
create or replace function F_MAGG_TARES_CONT_ANNO_TITR
(a_cod_fiscale    varchar2,
 a_anno    number,
 a_titr    varchar2,
 a_ogpr      number,
 a_CC      number
) RETURN number
IS
   w_imposta number;
   w_oggetto number;
   w_flag_ruolo varchar2(1);
   w_flag_occupazione varchar2(1);
BEGIN
   IF a_titr = 'TARSU' then
      BEGIN
         select ogpr.oggetto,ogpr.tipo_occupazione,cotr.flag_ruolo
           into w_oggetto,w_flag_occupazione,w_flag_ruolo
           from codici_tributo cotr,oggetti_pratica ogpr
          where ogpr.oggetto_pratica = a_ogpr
            and cotr.tributo = ogpr.tributo
         ;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
      RETURN NULL;
      END;
     BEGIN
        select sum(MAGGIORAZIONE_TARES)
           into w_imposta
           from CODICI_TRIBUTO COTR, TIPI_TRIBUTO titr, PRATICHE_TRIBUTO prtr,
              OGGETTI_PRATICA ogpr, OGGETTI_IMPOSTA ogim, RUOLI ruol
         where nvl(cotr.conto_corrente,nvl(titr.conto_corrente,0)) = nvl(a_cc,0)
           and cotr.tributo         = ogpr.tributo
           and cotr.tipo_tributo      = prtr.tipo_tributo
           and ogim.cod_fiscale      = a_cod_fiscale
           and ogim.anno             = a_anno
           and ogim.flag_calcolo      = 'S'
           and titr.tipo_tributo     = prtr.tipo_tributo
           and prtr.tipo_tributo||''   = a_titr
           and ogpr.oggetto_pratica   = ogim.oggetto_pratica
           and prtr.pratica         = ogpr.pratica
           and nvl(a_ogpr,ogim.oggetto_pratica) = ogim.oggetto_pratica
           and ruol.ruolo (+) = ogim.ruolo
           and (    w_flag_occupazione||w_flag_ruolo = 'PS'
                and ogim.ruolo     is not null
                and ruol.anno_ruolo = a_anno
                or  w_flag_occupazione||w_flag_ruolo <> 'PS'
                and ogim.ruolo     is null
               )
          ;
          RETURN w_imposta;
       EXCEPTION
          WHEN NO_DATA_FOUND THEN
             RETURN NULL;
     END;
   END IF;
END;
/* End Function: F_MAGG_TARES_CONT_ANNO_TITR */
/

