--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_imposta_cont_anno_titr stripComments:false runOnChange:true 
 
create or replace function F_IMPOSTA_CONT_ANNO_TITR
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
   IF a_titr IN ('TASI', 'ICI') THEN
      BEGIN
         select sum(imposta)
      into w_imposta
      from TIPI_TRIBUTO TITR, PRATICHE_TRIBUTO prtr,
      OGGETTI_PRATICA ogpr, OGGETTI_IMPOSTA ogim
     where nvl(titr.conto_corrente,0)   = nvl(a_cc,0)
       and titr.tipo_tributo      = prtr.tipo_tributo
          and ogim.cod_fiscale      = a_cod_fiscale
          and ogim.anno             = a_anno
          and ogim.flag_calcolo      = 'S'
          and prtr.tipo_tributo||''      = a_titr
          and ogpr.oggetto_pratica      = ogim.oggetto_pratica
          and prtr.pratica         = ogpr.pratica
          and nvl(a_ogpr,ogim.oggetto_pratica)= ogim.oggetto_pratica
         ;
         RETURN w_imposta;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
      RETURN NULL;
      END;
   ELSIF a_titr = 'TARSU' then
      BEGIN
         select ogpr.oggetto,nvl(ogpr.tipo_occupazione,'P'),cotr.flag_ruolo
           into w_oggetto,w_flag_occupazione,w_flag_ruolo
           from codici_tributo cotr,oggetti_pratica ogpr
          where ogpr.oggetto_pratica = a_ogpr
            and cotr.tributo = ogpr.tributo
         ;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
      RETURN NULL;
      END;
--      IF w_flag_occupazione||w_flag_ruolo = 'PS' THEN
--         BEGIN
--            select sum(ruog.importo)
--              into w_imposta
--              from ruoli_oggetto ruog, ruoli ruol, tipi_tributo titr, codici_tributo cotr
--             where ruol.ruolo = ruog.ruolo
--               and ruol.anno_ruolo = a_anno
--               and ruog.cod_fiscale = a_cod_fiscale
--               and ruog.oggetto = w_oggetto
--               and titr.tipo_tributo = ruol.tipo_tributo
--               and titr.tipo_tributo||'' = a_titr
--               and nvl(cotr.conto_corrente,nvl(titr.conto_corrente,0)) = nvl(a_cc,0)
--               and cotr.tributo = ruog.tributo
--               and ruog.pratica is null
--            ;
--            RETURN w_imposta;
--         EXCEPTION
--            WHEN NO_DATA_FOUND THEN
--               RETURN NULL;
--         END;
--      ELSE
         BEGIN
            select sum(imposta)
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
                    and ruol.invio_consorzio is not null --SC 14/01/2015 senza questo sbaglia il calcolo delle sanzioni in fase di replica accertamento
                    or  w_flag_occupazione||w_flag_ruolo <> 'PS'
                    and ogim.ruolo     is null
                   )
              ;
              RETURN w_imposta;
           EXCEPTION
              WHEN NO_DATA_FOUND THEN
                 RETURN NULL;
         END;
--      END IF;
   ELSIF substr(a_titr,1,2) = 'E_' THEN
--   Utilizziamo E_ per gestire le conversioni in euro senza utilizzare il cc
      BEGIN
         select sum(imposta)
      into w_imposta
      from TIPI_TRIBUTO titr, PRATICHE_TRIBUTO prtr,
      OGGETTI_PRATICA ogpr, OGGETTI_IMPOSTA ogim
     where ogim.cod_fiscale      = a_cod_fiscale
          and ogim.anno             = a_anno
          and ogim.flag_calcolo      = 'S'
       and titr.tipo_tributo     = prtr.tipo_tributo
          and prtr.tipo_tributo||''   = substr(a_titr,3)
          and ogpr.oggetto_pratica   = ogim.oggetto_pratica
          and prtr.pratica         = ogpr.pratica
          and nvl(a_ogpr,ogim.oggetto_pratica) = ogim.oggetto_pratica
         ;
         RETURN w_imposta;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
      RETURN NULL;
      END;
    ELSE
--   Utilizziamo TARSU_2 per poter gestire velocemente la somma delle imposte
--   per contribuente tipo_tributo e tributo perche'' da Dettaglio_imposte non
--   viene passato il oggetto_pratica
      BEGIN
         select sum(imposta)
      into w_imposta
      from CODICI_TRIBUTO COTR, TIPI_TRIBUTO titr, PRATICHE_TRIBUTO prtr,
      OGGETTI_PRATICA ogpr, OGGETTI_IMPOSTA ogim
     where nvl(cotr.conto_corrente,nvl(titr.conto_corrente,0)) = nvl(a_cc,0)
       and cotr.tributo         = ogpr.tributo
          and cotr.tipo_tributo      = prtr.tipo_tributo
          and ogim.cod_fiscale      = a_cod_fiscale
          and ogim.anno             = a_anno
          and ogim.flag_calcolo      = 'S'
       and titr.tipo_tributo     = prtr.tipo_tributo
          and prtr.tipo_tributo||''   = decode(a_titr,'TARSU_2','TARSU',a_titr)
          and ogpr.oggetto_pratica   = ogim.oggetto_pratica
          and prtr.pratica         = ogpr.pratica
          and nvl(a_ogpr,ogim.oggetto_pratica) = ogim.oggetto_pratica
         ;
         RETURN w_imposta;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
      RETURN NULL;
      END;
   END IF;
END;
/* End Function: F_IMPOSTA_CONT_ANNO_TITR */
/

