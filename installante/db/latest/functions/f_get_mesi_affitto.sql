--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_get_mesi_affitto stripComments:false runOnChange:true 
 
create or replace function F_GET_MESI_AFFITTO
(p_oggetto number
,p_cf varchar2
,p_anno_rif number
,p_ravvedimento varchar2
)
return number
is
w_mesi_affitto number;
w_mesi_affitto_1 number;
w_mesi_affitto_2 number;
begin
/*calcola per quanti mesi l'immobile p_oggetto
è stato affittato nell'anno p_anno_rif da contribuenti diversi da p_cf*/
         select nvl(sum(decode(ogco.anno,p_anno_rif,nvl(ogco.mesi_possesso,12),12)),0)
           into w_mesi_affitto_1
           from oggetti_pratica       ogpr
              , oggetti_contribuente  ogco
              , pratiche_tributo      prtr
          where ogpr.oggetto          = p_oggetto
            and ogpr.oggetto_pratica  = ogco.oggetto_pratica
            and ogco.tipo_rapporto    = 'A'
            and ogco.cod_fiscale     != p_cf
            and ogpr.pratica          = prtr.pratica
            and prtr.tipo_tributo||'' = 'TASI'
            and ogco.anno||ogco.tipo_rapporto||'S' =
                  (select max(b.anno||b.tipo_rapporto||b.flag_possesso)
                   from pratiche_tributo c,
                     oggetti_contribuente b,
                     oggetti_pratica a
                     where(   c.data_notifica is not null and c.tipo_pratica||'' = 'A' and
                              nvl(c.stato_accertamento,'D') = 'D' and
                              nvl(c.flag_denuncia,' ')      = 'S' and
                              c.anno                        < p_anno_rif
                     or (c.data_notifica is null and c.tipo_pratica||'' = 'D')
                          )
                       and c.anno                  <= p_anno_rif
                       and c.tipo_tributo||''       = prtr.tipo_tributo
                       and c.pratica                = a.pratica
                       and a.oggetto_pratica        = b.oggetto_pratica
                       and a.oggetto                = ogpr.oggetto
                       and b.tipo_rapporto          = 'A' --in ('A','C','D','E')
                       and b.cod_fiscale            = ogco.cod_fiscale
                  )
            and nvl(prtr.stato_accertamento,'D') = 'D'
            and decode(ogco.anno,p_anno_rif,nvl(ogco.mesi_possesso,12),12) >= 0
            ;
         select nvl(sum(decode(ogco.anno,p_anno_rif,nvl(ogco.mesi_possesso,12),12)),0)
           into w_mesi_affitto_2
           from oggetti_pratica       ogpr
              , oggetti_contribuente  ogco
              , pratiche_tributo      prtr
          where ogpr.oggetto          = p_oggetto
            and ogpr.oggetto_pratica  = ogco.oggetto_pratica
            and ogco.tipo_rapporto    = 'A'
            and ogco.cod_fiscale     != p_cf
            and ogpr.pratica          = prtr.pratica
            and prtr.tipo_tributo||'' = 'TASI'
            and (  (  prtr.tipo_pratica||'' = 'D'
                 and ogco.flag_possesso    is null
                 and p_ravvedimento         = 'N'
                   )
                or ( prtr.tipo_pratica||''  = 'V'
                 and p_ravvedimento         = 'S'
                 and not exists (select 'x'
                                   from sanzioni_pratica sapr
                                  where sapr.pratica = prtr.pratica)
                   )
                )
            and ogco.anno                   = p_anno_rif
            and nvl(prtr.stato_accertamento,'D') = 'D'
            and decode(ogco.anno,p_anno_rif,nvl(ogco.mesi_possesso,12),12) >= 0
            ;
         w_mesi_affitto := nvl(w_mesi_affitto_1,0) + nvl(w_mesi_affitto_2,0);
return w_mesi_affitto;
end;
/* End Function: F_GET_MESI_AFFITTO */
/

