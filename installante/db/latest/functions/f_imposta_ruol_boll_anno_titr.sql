--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_imposta_ruol_boll_anno_titr stripComments:false runOnChange:true 
 
create or replace function F_IMPOSTA_RUOL_BOLL_ANNO_TITR
(a_cod_fiscale    varchar2,
 a_anno    number,
 a_titr    varchar2,
 a_ogpr    number,
 a_cc      number,
 a_ruolo   number
) RETURN   number
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
   w_round               varchar2(1);
   w_cod_istat           varchar2(6);
BEGIN
--Solo TARSU
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
         begin
           select lpad(to_char(d.pro_cliente),3,'0')
                   ||lpad(to_char(d.com_cliente),3,'0')
             into w_cod_istat
             from dati_generali  d
            where d.chiave                = 1
                ;
            EXCEPTION
                WHEN others THEN
                    w_cod_istat := '';
         end;
         begin
            select decode(a_titr
                         ,'TARSU',decode(w_cod_istat
                                        ,'037058',null     --Savigno
                                        ,'015036',null     --Buccinasco
                                        ,'012083',null     --Induno Olona
                                        ,'015175',null     --Pioltello
                                        ,'090049',null     --Oschiri
                                        ,'097049',null     --Missaglia
                                        ,'091055',null     --Oliena
                                        ,'042030',null     --Monte San Vito
                                        ,'S'   --flag_tariffa
                                        )
                         ,'S')
                    into w_round
               from tipi_tributo
              where tipo_tributo = a_titr
                  ;
          EXCEPTION
             WHEN OTHERS THEN
                w_round := 'S';
         end;
         if w_round is null
            and (w_importo_lordo = 'S' or w_cod_istat = '015036') then
            w_imposta := round(w_imposta,0);
         end if;
         RETURN w_imposta;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            RETURN NULL;
      END;
END;
/* End Function: F_IMPOSTA_RUOL_BOLL_ANNO_TITR */
/

