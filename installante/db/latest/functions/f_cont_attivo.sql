--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_cont_attivo stripComments:false runOnChange:true 
 
create or replace function F_CONT_ATTIVO
(p_titr    in varchar2,
 p_cf       in varchar2)
RETURN   string IS
w_attivo varchar2(2);
BEGIN
   if p_titr = 'ICP' or p_titr = 'TARSU' or p_titr = 'TOSAP' then
      BEGIN
         select 'SI'
           into w_attivo
           from dual
          where exists
               (select 1
                  from oggetti_contribuente ogco
                      ,oggetti_pratica      ogpr
                      ,rapporti_tributo     ratr
                      ,pratiche_tributo     prtr
                 where ogpr.oggetto_pratica    = ogco.oggetto_pratica
                   and prtr.pratica            = ratr.pratica
                   and ratr.cod_fiscale        = p_cf
                   and ogpr.pratica            = prtr.pratica
                   and ogco.cod_fiscale        = p_cf
                   and prtr.tipo_tributo||''   = p_titr
                   and prtr.tipo_pratica||''   = 'D'
                   and prtr.tipo_evento||''    = 'I'
                   and prtr.anno              <= to_number(to_char(sysdate,'yyyy'))
                   and not exists
                      (select 1
                         from oggetti_pratica      a
                             ,oggetti_contribuente b
                             ,pratiche_tributo     c
                        where a.oggetto_pratica    = b.oggetto_pratica
                          and c.pratica            = a.pratica
                          and b.cod_fiscale        = p_cf
                          and c.tipo_tributo||''   = p_titr
                          and c.tipo_evento||''    = 'C'
                          and c.tipo_pratica||''   = 'D'
                          and c.anno              >= prtr.anno
                          and a.oggetto_pratica_rif
                                                   = ogpr.oggetto_pratica
                      )
               )
         ;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            w_attivo := 'NO';
      END;
   elsif p_titr = 'ICIAP' then
      w_attivo := 'NO';
   else  -- caso ICI e TASI
      BEGIN
         select 'SI'
           into w_attivo
           from dual
          where exists
               (select 1
                  from oggetti_contribuente ogco
                      ,oggetti_pratica      ogpr
                      ,rapporti_tributo     ratr
                      ,pratiche_tributo     prtr
                 where ogco.anno||ogco.tipo_rapporto||'S' =
                      (select max(b.anno||b.tipo_rapporto||b.flag_possesso)
                         from pratiche_tributo     c
                             ,oggetti_contribuente b
                             ,oggetti_pratica      a
                        where c.data_notifica         is null
                          and c.tipo_pratica||''       = 'D'
                          and c.anno                  <= to_number(to_char(sysdate,'yyyy'))
                          and c.tipo_tributo||''       = prtr.tipo_tributo
                          and c.pratica                = a.pratica
                          and a.oggetto_pratica        = b.oggetto_pratica
                          and a.oggetto                = ogpr.oggetto
                          and b.tipo_rapporto         in ('C','D','E')
                          and b.cod_fiscale            = ogco.cod_fiscale
                          and c.tipo_tributo||''       = p_titr
                      )
                   and ogco.oggetto_pratica            = ogpr.oggetto_pratica
                   and ogpr.pratica                    = prtr.pratica
                   and prtr.pratica                    = ratr.pratica
                   and ratr.cod_fiscale                = p_cf
                   and prtr.anno                      <= to_number(to_char(sysdate,'yyyy'))
                   and ogco.tipo_rapporto             in ('C','D','E')
                   and prtr.tipo_pratica||''           = 'D'
                   and ogco.flag_possesso              = 'S'
                   and ogco.flag_esclusione           is null
                   and ogco.cod_fiscale                = p_cf
                   and prtr.tipo_tributo||''           = p_titr
               )
         ;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            w_attivo := 'NO';
      END;
      if w_attivo = 'NO' then
         BEGIN
            select 'SI'
              into w_attivo
              from dual
             where exists
                  (select 1
                     from oggetti_contribuente ogco
                         ,oggetti_pratica      ogpr
                         ,rapporti_tributo     ratr
                         ,pratiche_tributo     prtr
                    where ogco.anno||ogco.tipo_rapporto||'S' =
                         (select max(b.anno||b.tipo_rapporto||b.flag_possesso)
                            from pratiche_tributo     c
                                ,oggetti_contribuente b
                                ,oggetti_pratica      a
                           where c.data_notifica         is not null
                             and c.tipo_pratica||''       = 'A'
                             and nvl(c.stato_accertamento,'D')
                                                          = 'D'
                             and nvl(c.flag_denuncia,' ') = 'S'
                             and c.anno                   < to_number(to_char(sysdate,'yyyy'))
                             and c.tipo_tributo||''       = prtr.tipo_tributo
                             and c.pratica                = a.pratica
                             and a.oggetto_pratica        = b.oggetto_pratica
                             and a.oggetto                = ogpr.oggetto
                             and b.tipo_rapporto         in ('C','D','E')
                             and b.cod_fiscale            = ogco.cod_fiscale
                             and c.tipo_tributo||''       = p_titr
                         )
                      and ogco.oggetto_pratica            = ogpr.oggetto_pratica
                      and ogpr.pratica                    = prtr.pratica
                      and prtr.pratica                    = ratr.pratica
                      and ratr.cod_fiscale                = p_cf
                      and ogco.flag_possesso              = 'S'
                      and ogco.flag_esclusione           is null
                      and prtr.anno                       < to_number(to_char(sysdate,'yyyy'))
                      and ogco.tipo_rapporto             in ('C','D','E')
                      and prtr.tipo_pratica||''           = 'A'
                      and nvl(prtr.stato_accertamento,'D')
                                                          = 'D'
                      and ogco.cod_fiscale                = p_cf
                      and prtr.tipo_tributo||''           = p_titr
                  )
            ;
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               w_attivo := 'NO';
         END;
      end if;
      if w_attivo = 'NO' then
         BEGIN
            select 'SI'
              into w_attivo
              from dual
             where exists
                  (select 1
                     from pratiche_tributo prtr
                         ,rapporti_tributo ratr
                         ,oggetti_pratica ogpr
                         ,oggetti_contribuente ogco
                    where prtr.tipo_pratica||''       = 'D'
                      and prtr.tipo_tributo||''       = p_titr
                      and ogpr.pratica                = prtr.pratica
                      and prtr.pratica                = ratr.pratica
                      and ratr.cod_fiscale            = p_cf
                      and ogco.oggetto_pratica        = ogpr.oggetto_pratica
                      and ogco.flag_possesso         is null
                      and ogco.flag_esclusione       is null
                      and ogco.anno                   = to_number(to_char(sysdate,'yyyy'))
                      and ogco.cod_fiscale            = p_cf
                  )
           ;
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               w_attivo := 'NO';
         END;
      end if;
      if w_attivo = 'NO' then
         BEGIN
            select 'SI'
              into w_attivo
              from dual
             where exists
                  (select 1
                     from versamenti vers
                    where vers.cod_fiscale                = p_cf
                      and vers.tipo_tributo||''           = p_titr
                      and vers.anno                       = to_number(to_char(sysdate,'yyyy'))
                  )
            ;
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               w_attivo := 'NO';
         END;
      end if;
   end if; -- else per ICI e TASI
   RETURN w_attivo;
END;
/* End Function: F_CONT_ATTIVO */
/

