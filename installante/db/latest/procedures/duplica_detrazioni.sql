--liquibase formatted sql 
--changeset abrandolini:20250326_152423_duplica_detrazioni stripComments:false runOnChange:true 
 
create or replace procedure DUPLICA_DETRAZIONI
(a_da_anno       in number
,a_a_anno        in number
,a_motivo        in number
,a_tipo_tributo  in varchar2
) is
cursor sel_ogco (aa_da_anno number
                ,aa_a_anno  number
                ,aa_motivo  number
                ) is
select distinct ogco.cod_fiscale cod_fiscale
               ,made.detrazione  detrazione
               ,made.note        note
  from maggiori_detrazioni       made
      ,pratiche_tributo          prtr
      ,oggetti_pratica           ogpr
      ,oggetti_contribuente      ogco
 where made.anno + 0                            = aa_da_anno
   and made.tipo_tributo                        = prtr.tipo_tributo
   and made.cod_fiscale                         = ogco.cod_fiscale
   and made.motivo_detrazione                   = aa_motivo
   and ogco.anno||ogco.tipo_rapporto||'S'       =
      (select max(b.anno||b.tipo_rapporto||b.flag_possesso)
         from pratiche_tributo     c
             ,oggetti_contribuente b
             ,oggetti_pratica      a
        where(    c.data_notifica              is not null
              and c.tipo_pratica||''            = 'A'
              and nvl(c.stato_accertamento,'D') = 'D'
              and nvl(c.flag_denuncia,' ')      = 'S'
              and c.anno                        < aa_a_anno
              or  c.data_notifica              is null
              and c.tipo_pratica||''            = 'D'
             )
          and c.anno                           <= aa_a_anno
          and c.tipo_tributo||''                = prtr.tipo_tributo
          and c.pratica                         = a.pratica
          and a.oggetto_pratica                 = b.oggetto_pratica
          and a.oggetto                         = ogpr.oggetto
          and b.tipo_rapporto                  in ('C','D','E')
          and b.cod_fiscale                     = ogco.cod_fiscale
      )
   and prtr.tipo_tributo||''                    = a_tipo_tributo
   and prtr.pratica                             = ogpr.pratica
   and ogpr.oggetto_pratica                     = ogco.oggetto_pratica
   and ogco.flag_possesso                       = 'S'
   and not exists
      (select 1
         from maggiori_detrazioni m
        where m.anno + 0                        = aa_a_anno
          and m.cod_fiscale                     = ogco.cod_fiscale
          and m.tipo_tributo                    = prtr.tipo_tributo
      )
   and exists
      (select 1
         from detrazioni          d
        where d.anno                            = aa_a_anno
          and d.tipo_tributo                    = prtr.tipo_tributo
      )
 union
select distinct ogco.cod_fiscale
               ,made.detrazione
               ,made.note
  from maggiori_detrazioni       made
      ,pratiche_tributo          prtr
      ,oggetti_pratica           ogpr
      ,oggetti_contribuente      ogco
 where made.anno + 0                            = aa_da_anno
   and made.cod_fiscale                         = ogco.cod_fiscale
   and made.tipo_tributo                        = prtr.tipo_tributo
   and made.motivo_detrazione                   = aa_motivo
   and prtr.tipo_pratica||''                    = 'D'
   and ogco.flag_possesso                      is null
   and prtr.tipo_tributo||''                    = a_tipo_tributo
   and prtr.pratica                             = ogpr.pratica
   and ogpr.oggetto_pratica                     = ogco.oggetto_pratica
   and ogco.anno                                = aa_a_anno
   and not exists
      (select 1
         from maggiori_detrazioni m
        where m.anno + 0                        = aa_a_anno
          and m.cod_fiscale                     = ogco.cod_fiscale
          and m.tipo_tributo                        = prtr.tipo_tributo
      )
   and exists
      (select 1
         from detrazioni          d
        where d.anno                            = aa_a_anno
          and d.tipo_tributo                        = prtr.tipo_tributo
      )
 order by 1
;
BEGIN
   FOR rec_ogco IN sel_ogco(a_da_anno,a_a_anno,a_motivo)
   LOOP
      BEGIN
         insert into maggiori_detrazioni
               (cod_fiscale,anno,motivo_detrazione,detrazione,note, tipo_tributo)
         values(rec_ogco.cod_fiscale,a_a_anno,a_motivo,rec_ogco.detrazione,rec_ogco.note, a_tipo_tributo)
         ;
      END;
   END LOOP;
END;
/* End Procedure: DUPLICA_DETRAZIONI */
/

