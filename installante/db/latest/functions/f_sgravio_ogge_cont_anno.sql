--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_sgravio_ogge_cont_anno stripComments:false runOnChange:true 
 
create or replace function F_SGRAVIO_OGGE_CONT_ANNO
(a_cod_fiscale    varchar2,
 a_anno       number,
 a_titr       varchar2,
 a_ogpr         number
)
RETURN number
IS
   w_imposta    number;
   w_oggetto    number;
BEGIN
   IF a_titr = 'TARSU' then
      BEGIN
         select ogpr.oggetto
           into w_oggetto
           from oggetti_pratica ogpr
          where ogpr.oggetto_pratica = a_ogpr
         ;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
      RETURN NULL;
      END;
      BEGIN
         select sum(sgra.importo)
           into w_imposta
           from sgravi sgra,ruoli ruol
          where ruol.ruolo = sgra.ruolo
            and ruol.anno_ruolo = a_anno
            and ruol.tipo_tributo||'' = a_titr
            and sgra.cod_fiscale = a_cod_fiscale
            and w_oggetto in (select ruog.oggetto
                                from ruoli_oggetto ruog
                               where ruog.cod_fiscale = a_cod_fiscale
                             )
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
/* End Function: F_SGRAVIO_OGGE_CONT_ANNO */
/

