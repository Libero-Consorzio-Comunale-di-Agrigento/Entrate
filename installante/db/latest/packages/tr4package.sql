--liquibase formatted sql 
--changeset abrandolini:20250326_152429_tr4package stripComments:false runOnChange:true 
 
create or replace package TR4PACKAGE
is
NO_RATE             CONSTANT number := 0;
RATE_CONTRIBUENTE   CONSTANT number := 1;
RATE_SINGOLO_OGIM   CONSTANT number := 2;
TYPE tariffe_pkg is RECORD
(anno               number(4)
,tributo            number(4)
,categoria          number(4)
,tipo_tariffa       number(2)
);
TYPE tariffe_rc is REF CURSOR RETURN tariffe_pkg;
-- (VD - 14/01/2019): nuovi tipi per controllo tariffe prima
--                    di emissione ruolo
TYPE tariffe_errate_pkg is RECORD
(anno               number(4)
,tributo            number(4)
,categoria          number(4)
,tipo_tariffa       number(2)
,descrizione        varchar2(200)
);
TYPE tariffe_errate_rc is REF CURSOR RETURN tariffe_errate_pkg;
TYPE calcolo_ici is RECORD
(dep_terreni        number
,acconto_terreni    number
,saldo_terreni      number
,dep_aree           number
,acconto_aree       number
,saldo_aree         number
,dep_ab             number
,acconto_ab         number
,saldo_ab           number
,dep_altri          number
,acconto_altri      number
,saldo_altri        number
,acconto_detrazione number
,saldo_detrazione   number
,totale_terreni     number
,numero_fabbricati  number
);
TYPE calcolo_ici_rc is REF CURSOR RETURN calcolo_ici;
TYPE dati is RECORD
(dati              varchar2(2000)
);
TYPE dati_rc is REF CURSOR RETURN dati;
-- (VD - 07/11/2018): aggiunta selezione tariffe base mancanti
--                    e adeguato controllo a quello eseguito in PB
CURSOR sel_tari
(w_tipo_tributo          varchar2
,w_anno_ruolo            number
,w_cod_fiscale           varchar2
,w_flag_tariffa_base     varchar2 default null
) IS
       select distinct w_anno_ruolo anno,
              ogpr.tributo,
              ogpr.categoria,
              ogpr.tipo_tariffa
         from oggetti_contribuente ogco,
              oggetti_pratica ogpr,
              codici_tributo cotr,
              pratiche_tributo prtr,
              oggetti_validita ogva
        where not exists (select 'x'
                            from tariffe tari
                           where tari.tipo_tariffa = nvl(ogpr.tipo_tariffa,0)
                             and tari.categoria    = nvl(ogpr.categoria,0)
                             and tari.tributo      = ogpr.tributo
                             and tari.anno         = w_anno_ruolo)
         and ogpr.oggetto_pratica = ogva.oggetto_pratica
         and ogco.cod_fiscale = ogva.cod_fiscale
         and ((to_char(ogva.al,'yyyy') = w_anno_ruolo)
             or
              (nvl(to_char(ogva.dal,'yyyy'),1800) <= w_anno_ruolo and
               nvl(to_char(ogva.al,'yyyy'),9999) > w_anno_ruolo  and
               nvl(to_char(prtr.data,'yyyy'),w_anno_ruolo)           <= w_anno_ruolo ))
         and ogco.cod_fiscale        like w_cod_fiscale
         and ogco.oggetto_pratica    = ogpr.oggetto_pratica
         and ogpr.flag_contenzioso    is null
         and ogpr.tributo        = cotr.tributo
         and ogpr.pratica        = prtr.pratica
         and cotr.tipo_tributo||''    = prtr.tipo_tributo
         and prtr.tipo_tributo||''    = w_tipo_tributo
       union
      select distinct w_anno_ruolo anno,
             ogpr.tributo,
             ogpr.categoria,
             to_number(null)
        from oggetti_contribuente ogco,
             oggetti_pratica ogpr,
             codici_tributo cotr,
             pratiche_tributo prtr,
             oggetti_validita ogva
       where not exists (select 'x'
                           from tariffe tari
                          where tari.categoria    = nvl(ogpr.categoria,0)
                            and tari.tributo      = ogpr.tributo
                            and tari.anno         = w_anno_ruolo
                            and nvl(tari.flag_tariffa_base,'N') = 'S')
        and ogpr.oggetto_pratica = ogva.oggetto_pratica
        and ogco.cod_fiscale = ogva.cod_fiscale
        and ((to_char(ogva.al,'yyyy') = w_anno_ruolo)
            or
             (nvl(to_char(ogva.dal,'yyyy'),1800) <= w_anno_ruolo and
              nvl(to_char(ogva.al,'yyyy'),9999) > w_anno_ruolo  and
              nvl(to_char(prtr.data,'yyyy'),w_anno_ruolo)           <= w_anno_ruolo ))
        and ogco.cod_fiscale        like w_cod_fiscale
        and ogco.oggetto_pratica    = ogpr.oggetto_pratica
        and ogpr.flag_contenzioso    is null
        and ogpr.tributo        = cotr.tributo
        and ogpr.pratica        = prtr.pratica
        and cotr.tipo_tributo||''    = prtr.tipo_tributo
        and prtr.tipo_tributo||''    = w_tipo_tributo
        and nvl(w_flag_tariffa_base,'N') = 'S'
/*select distinct
       w_anno_ruolo anno
      ,ogpr.tributo
      ,ogpr.categoria
      ,ogpr.tipo_tariffa
  from oggetti_contribuente ogco
      ,oggetti_pratica      ogpr
      ,codici_tributo       cotr
      ,pratiche_tributo     prtr
 where not exists
      (select 'x'
         from tariffe tari
        where tari.tipo_tariffa = nvl(ogpr.tipo_tariffa,0)
          and tari.categoria    = nvl(ogpr.categoria,0)
          and tari.tributo      = ogpr.tributo
          and tari.anno         = w_anno_ruolo
      )
  and (    to_number(to_char(ogco.data_cessazione,'yyyy'))
                                = w_anno_ruolo
       or  nvl(to_number(to_char(ogco.data_decorrenza,'yyyy')),1800)
                               <= w_anno_ruolo
       and nvl(to_number(to_char(ogco.data_cessazione,'yyyy')),9999)
                                > w_anno_ruolo
       and nvl(to_number(to_char(data,'yyyy')),w_anno_ruolo)
                               <= w_anno_ruolo
       and not exists
          (select 'x'
             from oggetti_contribuente ogco1
                 ,oggetti_pratica      ogpr1
            where to_number(to_char(ogco1.data_cessazione,'yyyy'))
                                           <= w_anno_ruolo
              and ogco1.cod_fiscale         = ogco.cod_fiscale
              and ogco1.oggetto_pratica     = ogpr1.oggetto_pratica
              and ogpr1.oggetto_pratica_rif =
                  nvl(ogpr.oggetto_pratica_rif,ogpr.oggetto_pratica)
              and nvl(ogco.tipo_rapporto,' ')||
                  nvl(ogco.data_decorrenza,to_date('01/01/1800','dd/mm/yyyy'))
                                            =
                 (select max(nvl(ogco1.tipo_rapporto,' ')||
                             nvl(ogco1.data_decorrenza
                                ,to_date('01/01/1800','dd/mm/yyyy')
                                )
                            )
                    from pratiche_tributo     prtr1
                        ,oggetti_contribuente ogco1
                        ,oggetti_pratica      ogpr1
                   where (    prtr1.tipo_pratica  = 'A'
                          and prtr1.anno          < w_anno_ruolo
                          and (trunc(sysdate) - nvl(prtr1.data_notifica,trunc(sysdate)))
                                                  > 60
                          or prtr1.tipo_pratica  != 'A'
                         )
                      and prtr1.pratica           = ogpr1.pratica
                      and ogco1.cod_fiscale       = ogco.cod_fiscale
                      and ogco1.oggetto_pratica   = ogpr1.oggetto_pratica
                      and nvl(ogpr1.oggetto_pratica_rif,ogpr1.oggetto_pratica)
                                                  =
                          nvl(ogpr.oggetto_pratica_rif,ogpr.oggetto_pratica)
                 )
          )
      )
   and ogco.cod_fiscale    like w_cod_fiscale
   and ogco.oggetto_pratica   = ogpr.oggetto_pratica
   and ogpr.flag_contenzioso is null
   and ogpr.tributo           = cotr.tributo
   and ogpr.pratica           = prtr.pratica
   and cotr.tipo_tributo||''  = prtr.tipo_tributo
   and prtr.tipo_tributo||''  = w_tipo_tributo*/
;
CURSOR sel_ogpr_validi
(a_anno              number
,a_cod_fiscale       varchar2
,a_tipo_tributo      varchar2
,a_tipo_occupazione  varchar2
,a_data_emissione    date
) IS
select ogpr.oggetto
      ,ogpr.oggetto_pratica
      ,ogpr.tributo
      ,ogpr.categoria
      ,ogpr.consistenza
      ,ogpr.tipo_tariffa
      ,ogpr.numero_familiari
      ,tari.tariffa
      ,tari.limite
      ,tari.tariffa_superiore
      ,tari.tariffa_quota_fissa
      ,nvl(tari.perc_riduzione,0)                   perc_riduzione
      ,nvl(cotr.conto_corrente,titr.conto_corrente) conto_corrente
      ,ogco.perc_possesso
      ,ogco.flag_ab_principale
      ,ogva.cod_fiscale
      ,ogva.dal data_decorrenza
      ,ogva.al data_cessazione
--      ,decode(sign(ogva.al - a_data_emissione),-1,ogva.al,null) data_cessazione
      ,cotr.flag_ruolo
      ,ogva.tipo_occupazione
      ,ogva.tipo_tributo
      ,decode(ogva.anno,a_anno,ogpr.data_concessione,null) data_concessione
      ,ogva.oggetto_pratica_rif
  from tariffe              tari
      ,tipi_tributo         titr
      ,codici_tributo       cotr
      ,pratiche_tributo     prtr
      ,oggetti_pratica      ogpr
      ,oggetti_contribuente ogco
      ,oggetti_validita     ogva
 where nvl(to_number(to_char(ogva.dal,'yyyy')),a_anno)
                              <= a_anno
   and nvl(to_number(to_char(ogva.al,'yyyy')),a_anno)
                               >= a_anno
   and nvl(ogva.data,nvl(a_data_emissione
                        ,to_date('0101'||lpad(to_char(a_anno),4,'0'),'ddmmyyyy')
                        )
          )                    <=
       nvl(a_data_emissione,nvl(ogva.data
                               ,to_date('0101'||lpad(to_char(a_anno),4,'0'),'ddmmyyyy')
                               )
          )
/*
   Modifica del 28-11-2003 in seguito a richiesta di Boe
   -----------------------------------------------------
   and decode(cotr.flag_ruolo
             ,'S',nvl(to_number(to_char(ogva.data,'yyyy')),a_anno)
                 ,a_anno
             )                <= a_anno
*/
   and not exists
      (select 'x'
         from pratiche_tributo prtr
        where prtr.tipo_pratica||''    = 'A'
          and prtr.anno               <= a_anno
          and prtr.pratica             = ogpr.pratica
          and (    trunc(sysdate) - nvl(prtr.data_notifica,trunc(sysdate))
                                       < 60
               and flag_adesione      is NULL
               or  prtr.anno           = a_anno
              )
          and prtr.flag_denuncia       = 'S'
      )
   and tari.tipo_tariffa         = ogpr.tipo_tariffa
   and tari.categoria+0          = ogpr.categoria
   and tari.tributo              = ogpr.tributo
   and nvl(tari.anno,0)          = a_anno
   and titr.tipo_tributo         = cotr.tipo_tributo
   and cotr.tipo_tributo         = ogva.tipo_tributo
   and cotr.tributo              = ogpr.tributo
   and ogpr.flag_contenzioso    is null
   and ogpr.oggetto_pratica      = ogva.oggetto_pratica
   and ogva.tipo_occupazione  like a_tipo_occupazione
   and ogva.cod_fiscale       like a_cod_fiscale
   and ogva.tipo_tributo||''     = a_tipo_tributo
   and ogco.oggetto_pratica      = ogva.oggetto_pratica
   and ogco.cod_fiscale          = ogva.cod_fiscale
   and prtr.pratica              = ogpr.pratica
   and nvl(prtr.stato_accertamento,'D')
                                 = 'D'
   and (    ogva.tipo_occupazione
                                 = 'T'
        or  a_tipo_tributo      in ('TARSU','ICIAP','ICI')
        or  ogva.tipo_occupazione
                            = 'P'
   and a_tipo_tributo      in ('TOSAP','ICP')
        and not exists
           (select 1
              from oggetti_validita   ogv2
             where ogv2.cod_fiscale   = ogva.cod_fiscale
               and ogv2.oggetto_pratica_rif
                                      = ogva.oggetto_pratica_rif
               and ogv2.tipo_tributo||''
                                   = ogva.tipo_tributo
               and ogv2.tipo_occupazione
                                      = 'P'
               and nvl(to_number(to_char(ogv2.data,'yyyy'))
                      ,decode(ogv2.tipo_pratica,'A',a_anno - 1,a_anno)
                      )              <= decode(ogv2.tipo_pratica,'A',a_anno - 1,a_anno)
               and nvl(to_number(to_char(ogv2.dal,'yyyy'))
                      ,decode(ogv2.tipo_pratica,'A',a_anno - 1,a_anno)
                      )              <= decode(ogv2.tipo_pratica,'A',a_anno - 1,a_anno)
               and nvl(to_number(to_char(ogv2.al,'yyyy'))
                      ,decode(ogv2.tipo_pratica,'A',a_anno - 1,a_anno)
                      )              >= decode(ogv2.tipo_pratica,'A',a_anno - 1,a_anno)
               and nvl(ogv2.data,nvl(a_data_emissione
                                    ,to_date('0101'||lpad(to_char(a_anno),4,'0'),'ddmmyyyy')
                                    )
                      )              <=
                   nvl(a_data_emissione,nvl(ogv2.data
                                           ,to_date('0101'||lpad(to_char(a_anno),4,'0'),'ddmmyyyy')
                                           )
                      )
               and ogv2.dal           > ogva.dal
           )
       )
 order by
       ogva.cod_fiscale
      ,ogpr.oggetto_pratica
      ,ogva.dal
;
end TR4PACKAGE;
/* End Package: TR4PACKAGE */
/

