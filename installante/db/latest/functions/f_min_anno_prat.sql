--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_min_anno_prat stripComments:false runOnChange:true 
 
create or replace function F_MIN_ANNO_PRAT
(a_pratica        in number
,a_cod_fiscale    in varchar2
) Return number
is
nAnno             number(4);
BEGIN
   BEGIN
      select decode(max(prtr.tipo_tributo)
                   ,'ICI'  ,max(nvl(prtr.anno,1900))
                   ,'ICIAP',max(nvl(prtr.anno,1900))
                           ,to_number(to_char(min(nvl(ogco.data_decorrenza
                                                     ,to_date('01011900','ddmmyyyy')
                                                     )
                                                 ),'yyyy'
                                             )
                                     )
                   )
        into nAnno
        from oggetti_contribuente ogco
            ,oggetti_pratica      ogpr
            ,pratiche_tributo     prtr
       where ogco.oggetto_pratica (+) = ogpr.oggetto_pratica
         and ogco.cod_fiscale     (+) = a_cod_fiscale
         and ogpr.pratica         (+) = prtr.pratica
         and prtr.pratica             = a_pratica
      ;
   EXCEPTION
      WHEN OTHERS THEN
         nAnno := null;
   END;
   Return nAnno;
END;
/* End Function: F_MIN_ANNO_PRAT */
/

