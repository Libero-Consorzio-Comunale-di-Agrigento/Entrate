--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_imposta_ruol_cont_anno_titr stripComments:false runOnChange:true 
 
create or replace function F_IMPOSTA_RUOL_CONT_ANNO_TITR
(a_cod_fiscale    varchar2,
 a_anno    number,
 a_titr    varchar2,
 a_ogpr    number,
 a_cc      number,
 a_ruolo   number
) RETURN number
IS
   w_importo_lordo       varchar2(1);
   w_imposta             number;
   w_addizionale_eca     number;
   w_maggiorazione_eca   number;
   w_addizionale_pro     number;
   w_iva                 number;
   w_sgravi              number;
   w_addizionale_eca_s   number;
   w_maggiorazione_eca_s number;
   w_addizionale_pro_s   number;
   w_iva_s               number;
   w_oggetto             number;
BEGIN
   IF a_titr = 'TARSU' then
      BEGIN
         select ogpr.oggetto
           into w_oggetto
           from codici_tributo cotr,oggetti_pratica ogpr
          where ogpr.oggetto_pratica = a_ogpr
            and cotr.tributo = ogpr.tributo
         ;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
              w_oggetto := NULL;
      END;
      BEGIN
         select ruol.importo_lordo
           into w_importo_lordo
           from ruoli ruol
          where ruol.ruolo = a_ruolo
         ;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            RETURN null;
      END;
      BEGIN
         select sum(ruog.importo)
               ,sum(decode(cotr.flag_ruolo
                          ,'S',round(ruog.imposta * nvl(cata.addizionale_eca    ,0) / 100,2)
                              ,0
                          )
                   )
               ,sum(decode(cotr.flag_ruolo
                          ,'S',round(ruog.imposta * nvl(cata.maggiorazione_eca  ,0) / 100,2)
                              ,0
                          )
                   )
               ,sum(decode(cotr.flag_ruolo
                          ,'S',round(ruog.imposta * nvl(cata.addizionale_pro    ,0) / 100,2)
                              ,0
                          )
                   )
               ,sum(decode(cotr.flag_ruolo
                          ,'S',round(ruog.imposta * nvl(cata.aliquota           ,0) / 100,2)
                              ,0
                          )
                   )
               ,nvl(sum(nvl(sgra.importo,0)
                       ),0
                   )
               ,sum(decode(cotr.flag_ruolo
                          ,'S',round(nvl(sgra.importo,0) * nvl(cata.addizionale_eca    ,0) / 100,2)
                              ,0
                          )
                   )
               ,sum(decode(cotr.flag_ruolo
                          ,'S',round(nvl(sgra.importo,0) * nvl(cata.maggiorazione_eca  ,0) / 100,2)
                              ,0
                          )
                   )
               ,sum(decode(cotr.flag_ruolo
                          ,'S',round(nvl(sgra.importo,0) * nvl(cata.addizionale_pro    ,0) / 100,2)
                              ,0
                          )
                   )
               ,sum(decode(cotr.flag_ruolo
                          ,'S',round(nvl(sgra.importo,0) * nvl(cata.aliquota           ,0) / 100,2)
                              ,0
                          )
                   )
           into w_imposta
               ,w_addizionale_eca
               ,w_maggiorazione_eca
               ,w_addizionale_pro
               ,w_iva
               ,w_sgravi
               ,w_addizionale_eca_s
               ,w_maggiorazione_eca_s
               ,w_addizionale_pro_s
               ,w_iva_s
           from ruoli_oggetto    ruog,
      (select sum(nvl(importo,0)) importo
            , ruolo
            , cod_fiscale
            , sequenza
         from sgravi
        group by cod_fiscale
               , ruolo
          , sequenza)  sgra,
                ruoli            ruol,
                tipi_tributo     titr,
                codici_tributo   cotr,
                carichi_tarsu    cata
          where ruol.ruolo            = ruog.ruolo
            and ruol.anno_ruolo       = a_anno
            and ruog.cod_fiscale      = a_cod_fiscale
            and ruog.oggetto    between nvl(w_oggetto,0)
                                    and
                decode(nvl(w_oggetto,0),0,9999999999,w_oggetto)
            and ruog.oggetto_pratica
                                between nvl(a_ogpr,0)
                                    and
                decode(nvl(a_ogpr,0),0,9999999999,a_ogpr)
            and titr.tipo_tributo     = ruol.tipo_tributo
            and titr.tipo_tributo||'' = a_titr
            and nvl(cotr.conto_corrente,nvl(titr.conto_corrente,0))
                                      = nvl(a_cc,0)
            and cotr.tributo          = ruog.tributo
            and sgra.ruolo (+)        = ruog.ruolo
            and sgra.cod_fiscale (+)  = ruog.cod_fiscale
            and sgra.sequenza (+)     = ruog.sequenza
            and ruog.ruolo            = a_ruolo
            and cata.anno (+)         = ruol.anno_ruolo
         ;
         if w_importo_lordo is null then
            w_imposta := w_imposta + w_addizionale_eca   + w_maggiorazione_eca
                                   + w_addizionale_pro   + w_iva;
            w_sgravi  := w_sgravi  + w_addizionale_eca_s + w_maggiorazione_eca_s
                                   + w_addizionale_pro_s + w_iva_s;
         end if;
         w_imposta := w_imposta - w_sgravi;
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
          and ogim.ruolo between nvl(a_ruolo,0) and
              decode(nvl(a_ruolo,0),0,9999999999,nvl(a_ruolo,0))
         ;
         RETURN w_imposta;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
      RETURN NULL;
      END;
   END IF;
END;
/* End Function: F_IMPOSTA_RUOL_CONT_ANNO_TITR */
/

