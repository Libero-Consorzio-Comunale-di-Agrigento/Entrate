--liquibase formatted sql 
--changeset abrandolini:20250326_152423_duplica_detrazioni_oggetto stripComments:false runOnChange:true 
 
create or replace procedure DUPLICA_DETRAZIONI_OGGETTO
(a_da_anno       in number
,a_a_anno        in number
,a_motivo        in number
,a_tipo_tributo  in varchar2
) is
--
-- Estrae le Detrazioni Oggetto da Duplicare solo se
-- nell`anno da duplicare l`oggetto pratica e` posseduto
-- a fine anno in pratica di denuncia ICI o di accertamento
-- ICI sostitutivo di denuncia per quel contribuente
-- e che l`oggetto dell`oggetto pratica in questione non
-- sia gia` presente in altra pratica di denuncia ICI o
-- accertamento sostitutivo di denuncia ICI per lo stesso
-- contribuente.
--
-- Praticamente questo cursore e` quello del calcolo imposta
-- limitatamente agli oggetti con flag possesso = S e con
-- l`aggiunta in not exists dell cursore completo del calcolo
-- imposta limitatamente allo stesso oggetto ma con oggetto
-- pratica diverso.
--
cursor sel_ogco (aa_da_anno number
                ,aa_a_anno  number
                ,aa_motivo  number
                ) is
select distinct ogco.cod_fiscale cod_fiscale
               ,ogco.oggetto_pratica
                                 oggetto_pratica
               ,deog.detrazione  detrazione
               ,deog.note        note
               ,deog.tipo_tributo
  from detrazioni_ogco           deog
      ,pratiche_tributo          prtr
      ,oggetti_pratica           ogpr
      ,oggetti_contribuente      ogco
 where deog.anno                                = aa_da_anno
   and deog.cod_fiscale                         = ogco.cod_fiscale
   and deog.oggetto_pratica                     = ogco.oggetto_pratica
   and deog.motivo_detrazione                   = aa_motivo
   and prtr.tipo_tributo||''                    = a_tipo_tributo
   and prtr.tipo_pratica                       in ('D','A')
   and decode(prtr.tipo_pratica,'A',prtr.flag_denuncia,'S')
                                                = 'S'
   and nvl(prtr.stato_accertamento,'D')         = 'D'
   and prtr.anno                               <= aa_a_anno
   and prtr.pratica                             = ogpr.pratica
   and ogpr.oggetto_pratica                     = ogco.oggetto_pratica
   and ogco.flag_possesso                       = 'S'
   and (    prtr.anno                           < aa_a_anno
        or  prtr.anno                           = aa_a_anno
        and prtr.tipo_pratica                   = 'D'
       )
   and not exists
      (select 1
         from detrazioni_ogco m
        where m.anno + 0                        = aa_a_anno
          and m.cod_fiscale                     = ogco.cod_fiscale
          and m.oggetto_pratica                 = ogco.oggetto_pratica
          and prtr.tipo_tributo                 = m.tipo_tributo
      )
   and exists
      (select 1
         from detrazioni          d
        where d.anno                            = aa_a_anno
          and prtr.tipo_tributo                 = d.tipo_tributo
      )
   and not exists
      (select 1
         from pratiche_tributo          prt1
             ,oggetti_pratica           ogp1
             ,oggetti_contribuente      ogc1
        where ogp1.oggetto                       = ogpr.oggetto
          and ogc1.cod_fiscale                   = ogco.cod_fiscale
          and ogp1.oggetto_pratica              <> ogco.oggetto_pratica
          and ogc1.anno||ogc1.tipo_rapporto||'S' =
             (select max(e.anno||e.tipo_rapporto||e.flag_possesso)
                from pratiche_tributo     f
                    ,oggetti_contribuente e
                    ,oggetti_pratica      d
               where(    f.data_notifica        is not null
                     and f.tipo_pratica||''      = 'A'
                     and nvl(f.stato_accertamento,'D')
                                                 = 'D'
                     and nvl(f.flag_denuncia,' ')
                                                 = 'S'
                     and f.anno                  < aa_a_anno
                     or  f.data_notifica        is null
                     and f.tipo_pratica||''      = 'D'
                    )
                 and f.anno                     <= aa_a_anno
                 and f.tipo_tributo||''          = prt1.tipo_tributo
                 and f.pratica                   = d.pratica
                 and d.oggetto_pratica           = e.oggetto_pratica
                 and d.oggetto                   = ogp1.oggetto
                 and e.tipo_rapporto            in ('C','D','E')
                 and e.cod_fiscale               = ogc1.cod_fiscale
             )
          and prt1.tipo_tributo||''              = a_tipo_tributo
          and prt1.pratica                       = ogp1.pratica
          and ogp1.oggetto_pratica               = ogc1.oggetto_pratica
          and ogc1.flag_possesso                 = 'S'
        union
       select 1
         from pratiche_tributo          prt1
             ,oggetti_pratica           ogp1
             ,oggetti_contribuente      ogc1
        where ogp1.oggetto                       = ogpr.oggetto
          and ogc1.cod_fiscale                   = ogco.cod_fiscale
          and ogp1.oggetto_pratica              <> ogco.oggetto_pratica
          and prt1.tipo_pratica||''              = 'D'
          and ogc1.flag_possesso                is null
          and prt1.tipo_tributo||''              = a_tipo_tributo
          and prt1.pratica                       = ogp1.pratica
          and ogp1.oggetto_pratica               = ogc1.oggetto_pratica
          and ogc1.anno                          = aa_a_anno
      )
 order by 1
;
BEGIN
   FOR rec_ogco IN sel_ogco(a_da_anno,a_a_anno,a_motivo)
   LOOP
      BEGIN
         insert into detrazioni_ogco
               (cod_fiscale,oggetto_pratica,anno,motivo_detrazione,detrazione,note,tipo_tributo)
         values(rec_ogco.cod_fiscale,rec_ogco.oggetto_pratica,a_a_anno,
                a_motivo,rec_ogco.detrazione,rec_ogco.note,rec_ogco.tipo_tributo
               )
         ;
      END;
   END LOOP;
END;
/* End Procedure: DUPLICA_DETRAZIONI_OGGETTO */
/

