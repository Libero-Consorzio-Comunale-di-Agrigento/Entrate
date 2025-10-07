--liquibase formatted sql 
--changeset abrandolini:20250326_152423_get_mesi_affitto stripComments:false runOnChange:true 
 
create or replace procedure GET_MESI_AFFITTO
/*************************************************************************
 NOME:        GET_MESI_AFFITTO
 DESCRIZIONE: Calcola per quanti mesi l'immobile p_oggetto è stato
              affittato nell'anno p_anno_rif da contribuenti diversi
              da p_cf
 RITORNA:     Number               Mesi affitto
              Number               Mesi affitto primo semestre
 NOTE:
 Rev.  Date         Author   Note
 001   22/12/2016   VD       Modificato controllo ultimo oggetto
                             posseduto nell'anno: ora, al posto di
                             anno||tipo_rapporto||flag_possesso
                             si utilizza
                             anno||nvl(nvl(b.flag_possesso,c.flag_denuncia),'N')||tipo_rapporto.
 000                         Prima emissione.
*************************************************************************/
(p_oggetto        in number
,p_cf             in varchar2
,p_anno_rif       in number
,p_ravvedimento   in varchar2
,p_mesi_aff       in out number
,p_mesi_aff_1s    in out number
)
is
w_mesi_affitto    number;
w_mesi_affitto_2  number;
w_mesi_aff_1s     number;
w_mesi_aff_1s_2   number;
begin
         select nvl(sum(decode(ogco.anno,p_anno_rif,nvl(ogco.mesi_possesso,12),12)),0)
              , nvl(sum(decode(ogco.anno,p_anno_rif,nvl(ogco.mesi_possesso_1sem,6),6)),0)
           into w_mesi_affitto
              , w_mesi_aff_1s
           from oggetti_pratica       ogpr
              , oggetti_contribuente  ogco
              , pratiche_tributo      prtr
          where ogpr.oggetto          = p_oggetto
            and ogpr.oggetto_pratica  = ogco.oggetto_pratica
            and ogco.tipo_rapporto    = 'A'
            and ogco.cod_fiscale     != p_cf
            and ogpr.pratica          = prtr.pratica
            and prtr.tipo_tributo||'' = 'TASI'
            and ogco.anno||'S'||ogco.tipo_rapporto =
                  (select max(b.anno||nvl(nvl(b.flag_possesso,c.flag_denuncia),'N')||b.tipo_rapporto)
                     from pratiche_tributo c,
                          oggetti_contribuente b,
                          oggetti_pratica a
                    where (   c.data_notifica is not null and c.tipo_pratica||'' = 'A' and
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
              , nvl(sum(decode(ogco.anno,p_anno_rif,nvl(ogco.mesi_possesso_1sem,6),6)),0)
           into w_mesi_affitto_2
              , w_mesi_aff_1s_2
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
         p_mesi_aff    := nvl(w_mesi_affitto,0) + nvl(w_mesi_affitto_2,0);
         p_mesi_aff_1s := nvl(w_mesi_aff_1s,0)  + nvl(w_mesi_aff_1s_2,0);
end;
/* End Procedure: GET_MESI_AFFITTO */
/

