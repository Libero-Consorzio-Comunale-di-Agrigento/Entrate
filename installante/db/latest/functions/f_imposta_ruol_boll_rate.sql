--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_imposta_ruol_boll_rate stripComments:false runOnChange:true 
 
create or replace function F_IMPOSTA_RUOL_BOLL_RATE
(a_rata           number
,a_cod_fiscale    varchar2
,a_ruolo          number
) RETURN   number
IS
   w_rate                number;
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
   w_imposta_rata        number;
BEGIN
--Solo TARSU
      BEGIN
         select ruol.rate
           into w_rate
           from ruoli ruol
          where ruol.ruolo = a_ruolo
         ;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            RETURN null;
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
        --    and ruol.anno_ruolo       = a_anno
            and ruog.cod_fiscale      = a_cod_fiscale
            and titr.tipo_tributo     = ruol.tipo_tributo
            and titr.tipo_tributo||'' = 'TARSU'
       --     and nvl(cotr.conto_corrente,nvl(titr.conto_corrente,0))
       --                               = nvl(a_cc,0)
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
         if a_rata = w_rate then
            w_imposta_rata := round(w_imposta,0) - (round((w_imposta / w_rate),0) * (w_rate -1) );
         else
            w_imposta_rata := round(w_imposta/ w_rate,0);
         end if;
         RETURN w_imposta_rata;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            RETURN NULL;
      END;
END;
/* End Function: F_IMPOSTA_RUOL_BOLL_RATE */
/

