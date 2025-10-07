--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_contitolari_oggetto stripComments:false runOnChange:true 
 
create or replace function F_CONTITOLARI_OGGETTO
(p_tipo_tributo    in varchar2
,p_anno            in number
,p_oggetto         in number
) Return string is
sContitolari          varchar2(1);
BEGIN
   BEGIN
      select decode(count(distinct cont.cod_fiscale),0,'N',1,'N','S') contitolari
        into sContitolari
        from (select ogco.cod_fiscale cod_fiscale
                from pratiche_tributo     prtr
                    ,oggetti_pratica      ogpr
                    ,oggetti_imposta      ogim
                    ,oggetti_contribuente ogco
               where ogco.anno||ogco.tipo_rapporto||'S' =
                    (select max(b.anno||b.tipo_rapporto||b.flag_possesso)
                       from pratiche_tributo     c
                           ,oggetti_contribuente b
                           ,oggetti_pratica      a
                      where (    c.data_notifica               is not null
                             and c.tipo_pratica||''             = 'A'
                             and nvl(c.stato_accertamento,'D')  = 'D'
                             and nvl(c.flag_denuncia,' ')       = 'S'
                             and c.anno                         < p_anno
                             or  c.data_notifica               is null
                             and c.tipo_pratica||''             = 'D'
                            )
                        and c.anno                             <= p_anno
                        and c.tipo_tributo||''                  = prtr.tipo_tributo
                        and c.pratica                           = a.pratica
                        and a.oggetto_pratica                   = b.oggetto_pratica
                        and a.oggetto                           = ogpr.oggetto
                        and b.tipo_rapporto                    in ('C','D','E')
                        and b.cod_fiscale                       = ogco.cod_fiscale
                    )
                 and prtr.tipo_tributo||''                      = p_tipo_tributo
                 and prtr.pratica                               = ogpr.pratica
                 and ogpr.oggetto_pratica                       = ogco.oggetto_pratica
                 and ogco.flag_possesso                         = 'S'
                 and ogim.cod_fiscale               (+)         = ogco.cod_fiscale
                 and ogim.anno                      (+)         = p_anno
                 and ogim.oggetto_pratica           (+)         = ogco.oggetto_pratica
                 and ogim.flag_calcolo              (+)         = 'S'
                 and ogpr.oggetto                               = p_oggetto
               union all
              select ogco.cod_fiscale cod_fiscale
                from pratiche_tributo     prtr
                    ,oggetti_pratica      ogpr
                    ,oggetti_imposta      ogim
                    ,oggetti_contribuente ogco
               where prtr.tipo_pratica||''                      = 'D'
                 and ogco.flag_possesso                        is null
                 and prtr.tipo_tributo||''                      = p_tipo_tributo
                 and prtr.pratica                               = ogpr.pratica
                 and ogpr.oggetto_pratica                       = ogco.oggetto_pratica
                 and ogco.anno                                  = p_anno
                 and ogim.anno                      (+)         = p_anno
                 and ogim.oggetto_pratica           (+)         = ogco.oggetto_pratica
                 and ogim.flag_calcolo              (+)         = 'S'
                 and ogpr.oggetto                               = p_oggetto
             ) cont
      ;
   END;
   Return sContitolari;
END;
/* End Function: F_CONTITOLARI_OGGETTO */
/

