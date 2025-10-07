--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_imposta_ruol_rate stripComments:false runOnChange:true 
 
create or replace function F_IMPOSTA_RUOL_RATE
(a_ruolo            in number
,a_anno             in number
,a_rata             in number
,a_importo          in number
) Return number
is
w_importo_lordo        varchar2(1);
w_num_rate             number;
w_imp_rata             number;
w_add_eca              number;
w_addizionale_eca      number;
w_magg_eca             number;
w_maggiorazione_eca    number;
w_add_pro              number;
w_addizionale_pro      number;
w_aliquota             number;
w_iva                  number;
w_importo              number;
w_cod_istat            varchar2(6);
BEGIN
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
   BEGIN
      select nvl(ruol.rate,0)
            ,nvl(ruol.importo_lordo,'N')
        into w_num_rate
            ,w_importo_lordo
        from ruoli ruol
       where ruol.ruolo = a_ruolo
      ;
   EXCEPTION
      WHEN OTHERS THEN
         Return 0;
   END;
   if a_rata > w_num_rate then
      Return 0;
   end if;
   if w_importo_lordo = 'S' then
      w_add_eca    := 0;
      w_magg_eca   := 0;
      w_add_pro    := 0;
      w_aliquota   := 0;
   else
      BEGIN
         select nvl(cata.addizionale_eca,0)
               ,nvl(cata.maggiorazione_eca,0)
               ,nvl(cata.addizionale_pro,0)
               ,nvl(aliquota,0)
           into w_add_eca
               ,w_magg_eca
               ,w_add_pro
               ,w_aliquota
           from carichi_tarsu cata
          where cata.anno = a_anno
         ;
      EXCEPTION
         WHEN OTHERS THEN
            w_add_eca    := 0;
            w_magg_eca   := 0;
            w_add_pro    := 0;
            w_aliquota   := 0;
      END;
   end if;
   w_addizionale_eca     := round(a_importo * w_add_eca  / 100,2);
   w_maggiorazione_eca   := round(a_importo * w_magg_eca / 100,2);
   w_addizionale_pro     := round(a_importo * w_add_pro  / 100,2);
   w_iva                 := round(a_importo * w_aliquota / 100,2);
   w_importo             := a_importo + w_addizionale_eca + w_maggiorazione_eca
                                      + w_addizionale_pro + w_iva;
   if w_cod_istat = '015036' then
      if a_rata < w_num_rate then
         w_imp_rata := round(round(a_importo / w_num_rate , 2) + round(w_addizionale_eca   / w_num_rate , 2)
                                                               + round(w_maggiorazione_eca / w_num_rate , 2)
                                                               + round(w_addizionale_pro   / w_num_rate , 2)
                                                               + round(w_iva               / w_num_rate , 2)
                            ,0);
      else
         w_imp_rata := round(w_importo,0) - round((round(a_importo / w_num_rate , 2) + round(w_addizionale_eca   / w_num_rate , 2)
                                                                      + round(w_maggiorazione_eca / w_num_rate , 2)
                                                                      + round(w_addizionale_pro   / w_num_rate , 2)
                                                                      + round(w_iva               / w_num_rate , 2)
                                                  ) * (w_num_rate - 1)
                                                 ,0);
      end if;
   else
      if a_rata < w_num_rate then
         w_imp_rata := round(a_importo / w_num_rate , 2) + round(w_addizionale_eca   / w_num_rate , 2)
                                                         + round(w_maggiorazione_eca / w_num_rate , 2)
                                                         + round(w_addizionale_pro   / w_num_rate , 2)
                                                         + round(w_iva               / w_num_rate , 2);
      else
         w_imp_rata := w_importo - (round(a_importo / w_num_rate , 2) + round(w_addizionale_eca   / w_num_rate , 2)
                                                                      + round(w_maggiorazione_eca / w_num_rate , 2)
                                                                      + round(w_addizionale_pro   / w_num_rate , 2)
                                                                      + round(w_iva               / w_num_rate , 2)
                                   ) * (w_num_rate - 1);
      end if;
   end if;
   Return w_imp_rata;
EXCEPTION
   WHEN OTHERS THEN
      Return 0;
END;
/* End Function: F_IMPOSTA_RUOL_RATE */
/

