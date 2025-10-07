--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_cont_attivo_anno stripComments:false runOnChange:true 
 
create or replace function F_CONT_ATTIVO_ANNO
(p_titr   in  varchar2
,p_cf     in  varchar2
,p_anno   in  number)
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
                  from oggetti_validita ogva
                 where ogva.tipo_tributo||'' = p_titr
                   and ogva.cod_fiscale      = p_cf
                   and nvl(ogva.dal,to_date('01011900','ddmmyyyy'))
                                             < to_date('3112'||to_char(p_anno),'ddmmyyyy')
                   and nvl(ogva.al,to_date('31122999','ddmmyyyy'))
                                             > to_date('0101'||to_char(p_anno),'ddmmyyyy')
                )
         ;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            w_attivo := 'NO';
      END;
   elsif p_titr = 'ICIAP' then
      w_attivo := 'NO';
   else  -- caso ICI
      BEGIN
         select 'SI'
           into w_attivo
           from dual
          where exists
               (select 1
                  from oggetti_contribuente ogco
                     , oggetti_pratica      ogpr
                     , pratiche_tributo     prtr
                     , oggetti              ogge
                 where ogco.anno||ogco.tipo_rapporto||'S' =
                        (select max(b.anno||b.tipo_rapporto||b.flag_possesso)
                           from pratiche_tributo     c,
                                oggetti_contribuente b,
                                oggetti_pratica      a
                          where(   c.data_notifica is not null and c.tipo_pratica||'' = 'A' and
                                   nvl(c.stato_accertamento,'D') = 'D' and
                                   nvl(c.flag_denuncia,' ')      = 'S' and
                                   c.anno                        < p_anno
                                  or (c.data_notifica is null and c.tipo_pratica||'' = 'D')
                               )
                            and c.anno                  <= p_anno
                            and c.tipo_tributo||''       = prtr.tipo_tributo
                            and c.pratica                = a.pratica
                            and a.oggetto_pratica        = b.oggetto_pratica
                            and a.oggetto                = ogpr.oggetto
                            and b.tipo_rapporto         in ('C','D','E')
                            and b.cod_fiscale            = ogco.cod_fiscale
                         )
                   and ogge.oggetto             = ogpr.oggetto
                   and prtr.tipo_tributo||''    = 'ICI'
                   and nvl(prtr.stato_accertamento,'D') = 'D'
                   and prtr.pratica             = ogpr.pratica
                   and ogpr.oggetto_pratica     = ogco.oggetto_pratica
                   and decode(ogco.anno,p_anno,nvl(ogco.mesi_possesso,12),12) >= 0
                   and decode(ogco.anno
                             ,p_anno,decode(ogco.flag_esclusione
                                               ,'S',nvl(ogco.mesi_esclusione,nvl(ogco.mesi_possesso,12))
                                               ,nvl(ogco.mesi_esclusione,0)
                                               )
                                        ,decode(ogco.flag_esclusione,'S',12,0)
                             )                     <=
                           decode(ogco.anno,p_anno,nvl(ogco.mesi_possesso,12),12)
                   and ogco.flag_possesso       = 'S'
                   and ogco.cod_fiscale         = p_cf
             union
                 select 1
                   from oggetti ogge,
                        pratiche_tributo prtr,
                        oggetti_pratica ogpr,
                        oggetti_contribuente ogco
                  where ogge.oggetto                = ogpr.oggetto
                    and prtr.tipo_pratica||''  = 'D'
                    and ogco.flag_possesso    is null
                    and prtr.tipo_tributo||''       = 'ICI'
                    and nvl(prtr.stato_accertamento,'D') = 'D'
                    and prtr.pratica                = ogpr.pratica
                    and ogpr.oggetto_pratica        = ogco.oggetto_pratica
                    and ogco.anno                   = p_anno
                    and decode(ogco.anno
                              ,p_anno,decode(ogco.flag_esclusione
                                            ,'S',nvl(ogco.mesi_esclusione,nvl(ogco.mesi_possesso,12))
                                            ,nvl(ogco.mesi_esclusione,0)
                                            )
                              ,decode(ogco.flag_esclusione,'S',12,0)
                             )                     <=
                                           decode(ogco.anno,p_anno,nvl(ogco.mesi_possesso,12),12)
                    and decode(ogco.anno,p_anno,nvl(ogco.mesi_possesso,12),12) >= 0
                    and ogco.cod_fiscale         = p_cf
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
   end if; -- else per ICI
   RETURN w_attivo;
END;
/* End Function: F_CONT_ATTIVO_ANNO */
/

