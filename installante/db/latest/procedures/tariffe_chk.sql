--liquibase formatted sql 
--changeset abrandolini:20250326_152423_tariffe_chk stripComments:false runOnChange:true 
 
create or replace procedure TARIFFE_CHK
/*************************************************************************
 NOME:        TARIFFE_CHK
 DESCRIZIONE: Controllo tariffe per emissione ruolo.
              La procedure controlla che esistano tutte le tariffe
              necessarie all'emissione ruolo e, nel caso in cui sia
              richiesto, che per ogni combinazione anno/tributo/categoria
              esista la tariffa base.
 NOTE:
 Rev.    Date         Author      Note
 004     06/07/2020   VD          Corretta selezione tariffe non valorizzate:
                                  ora si estraggono solo quelle nulle
                                  (quelle = 0 identificano le esenzioni)
 003     14/01/2019   VD          Aggiunti controlli per emissione ruolo
                                  con tariffe.
 002     24/10/2018   VD          Aggiunto controllo presenza tariffe base.
                                  Le tariffe base mancanti vengono esposte
                                  con valore null.
 001     23/01/2015   Betta T.    Corretta select: non prendeva in considerazione
                      + AB        le cessazioni.
 000     01/12/2008   XX          Prima emissione.
*************************************************************************/
( a_tipo_tributo            in     varchar2
 ,a_anno_ruolo              in     number
 ,a_cod_fiscale             in     varchar2
 ,a_tipo_calcolo            in     varchar2
 ,a_flag_tariffa_base       in     varchar2
 ,a_flag_tariffe_ruolo      in     varchar2
 ,a_rc                      in out tr4package.tariffe_errate_rc
)
is
  --w_cod_fiscale              varchar2(16);
begin
  -- (VD - 14/02/2020): modifica temporanea per aggirare il problema
  --                    dovuto all'errore presente in PB nel passaggio
  --                    dei parametri
  -- (VD - 02/04/2020): annullata modifica precedente
  --  w_cod_fiscale := a_cod_fiscale;
  --  if a_tipo_calcolo = '%' or length(a_tipo_calcolo) >  then
  --     w_cod_fiscale := a_tipo_calcolo;
  --  end if;
  open a_rc for
       select distinct a_anno_ruolo anno,
              ogpr.tributo,
              ogpr.categoria,
              ogpr.tipo_tariffa,
              'Tariffa non esistente'
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
                             and tari.anno         = a_anno_ruolo)
          and ogpr.oggetto_pratica = ogva.oggetto_pratica
          and ogco.cod_fiscale = ogva.cod_fiscale
          and ((to_char(ogva.al,'yyyy') = a_anno_ruolo)
              or
               (nvl(to_char(ogva.dal,'yyyy'),1800) <= a_anno_ruolo and
                nvl(to_char(ogva.al,'yyyy'),9999) > a_anno_ruolo  and
                nvl(to_char(prtr.data,'yyyy'),a_anno_ruolo)           <= a_anno_ruolo ))
          and ogco.cod_fiscale        like a_cod_fiscale
          and ogco.oggetto_pratica    = ogpr.oggetto_pratica
          and ogpr.flag_contenzioso    is null
          and ogpr.tributo        = cotr.tributo
          and ogpr.pratica        = prtr.pratica
          and cotr.tipo_tributo||''    = prtr.tipo_tributo
          and prtr.tipo_tributo||''    = a_tipo_tributo
        union
       -- (VD - 24/10/2018): selezione tariffe base mancanti
       select distinct a_anno_ruolo anno,
              ogpr.tributo,
              ogpr.categoria,
              to_number(null),
              'Tariffa base non presente per anno/tributo/categoria'
         from oggetti_contribuente ogco,
              oggetti_pratica ogpr,
              codici_tributo cotr,
              pratiche_tributo prtr,
              oggetti_validita ogva
        where not exists (select 'x'
                            from tariffe tari
                           where tari.categoria    = nvl(ogpr.categoria,0)
                             and tari.tributo      = ogpr.tributo
                             and tari.anno         = a_anno_ruolo
                             and nvl(tari.flag_tariffa_base,'N') = 'S')
          and ogpr.oggetto_pratica = ogva.oggetto_pratica
          and ogco.cod_fiscale = ogva.cod_fiscale
          and ((to_char(ogva.al,'yyyy') = a_anno_ruolo)
              or
               (nvl(to_char(ogva.dal,'yyyy'),1800) <= a_anno_ruolo and
                nvl(to_char(ogva.al,'yyyy'),9999) > a_anno_ruolo  and
                nvl(to_char(prtr.data,'yyyy'),a_anno_ruolo)           <= a_anno_ruolo ))
          and ogco.cod_fiscale        like a_cod_fiscale
          and ogco.oggetto_pratica    = ogpr.oggetto_pratica
          and ogpr.flag_contenzioso    is null
          and ogpr.tributo        = cotr.tributo
          and ogpr.pratica        = prtr.pratica
          and cotr.tipo_tributo||''    = prtr.tipo_tributo
          and prtr.tipo_tributo||''    = a_tipo_tributo
          and nvl(a_flag_tariffa_base,'N') = 'S'
        union
       -- (VD - 14/01/2019): selezione tariffe non valorizzate per
       --                    calcolo tradizionale
       select distinct a_anno_ruolo anno,
              ogpr.tributo,
              ogpr.categoria,
              ogpr.tipo_tariffa,
              'Importo tariffa non valorizzato'
         from oggetti_contribuente ogco,
              oggetti_pratica ogpr,
              codici_tributo cotr,
              pratiche_tributo prtr,
              oggetti_validita ogva
        where exists (select 'x'
                        from tariffe tari
                       where tari.tipo_tariffa   = nvl(ogpr.tipo_tariffa,0)
                         and tari.categoria      = nvl(ogpr.categoria,0)
                         and tari.tributo        = ogpr.tributo
                         and tari.anno           = a_anno_ruolo
                         and tari.tariffa        is null)
          and ogpr.oggetto_pratica = ogva.oggetto_pratica
          and ogco.cod_fiscale = ogva.cod_fiscale
          and ((to_char(ogva.al,'yyyy') = a_anno_ruolo)
              or
               (nvl(to_char(ogva.dal,'yyyy'),1800) <= a_anno_ruolo and
                nvl(to_char(ogva.al,'yyyy'),9999) > a_anno_ruolo  and
                nvl(to_char(prtr.data,'yyyy'),a_anno_ruolo)           <= a_anno_ruolo ))
          and ogco.cod_fiscale        like a_cod_fiscale
          and ogco.oggetto_pratica    = ogpr.oggetto_pratica
          and ogpr.flag_contenzioso    is null
          and ogpr.tributo        = cotr.tributo
          and ogpr.pratica        = prtr.pratica
          and cotr.tipo_tributo||''    = prtr.tipo_tributo
          and prtr.tipo_tributo||''    = a_tipo_tributo
          and a_tipo_calcolo is null
        union
       -- (VD - 14/01/2019): selezione coefficienti domestici non presenti
       select distinct a_anno_ruolo anno,
              ogpr.tributo,
              ogpr.categoria,
              to_number(null),
              'Coefficienti domestici non presenti per anno/tributo/categoria'
         from oggetti_contribuente ogco,
              oggetti_pratica ogpr,
              codici_tributo cotr,
              pratiche_tributo prtr,
              oggetti_validita ogva,
              categorie        cate
        where not exists (select 'x'
                            from coefficienti_domestici codo
                           where codo.anno         = a_anno_ruolo)
          and ogpr.oggetto_pratica = ogva.oggetto_pratica
          and ogpr.categoria = cate.categoria
          and ogpr.tributo = cate.tributo
          and nvl(cate.flag_domestica,'N') = 'S'
          and ogco.cod_fiscale = ogva.cod_fiscale
          and ((to_char(ogva.al,'yyyy') = a_anno_ruolo)
              or
               (nvl(to_char(ogva.dal,'yyyy'),1800) <= a_anno_ruolo and
                nvl(to_char(ogva.al,'yyyy'),9999) > a_anno_ruolo  and
                nvl(to_char(prtr.data,'yyyy'),a_anno_ruolo)           <= a_anno_ruolo ))
          and ogco.cod_fiscale        like a_cod_fiscale
          and ogco.oggetto_pratica    = ogpr.oggetto_pratica
          and ogpr.flag_contenzioso    is null
          and ogpr.tributo        = cotr.tributo
          and ogpr.pratica        = prtr.pratica
          and cotr.tipo_tributo||''    = prtr.tipo_tributo
          and prtr.tipo_tributo||''    = a_tipo_tributo
          and a_flag_tariffe_ruolo = 'N'
        union
       -- (VD - 14/01/2019): selezione coefficienti non domestici non presenti
       select distinct a_anno_ruolo anno,
              ogpr.tributo,
              ogpr.categoria,
              to_number(null),
              'Coefficienti non domestici non presenti per anno/tributo/categoria'
         from oggetti_contribuente ogco,
              oggetti_pratica ogpr,
              codici_tributo cotr,
              pratiche_tributo prtr,
              oggetti_validita ogva,
              categorie        cate
        where not exists (select 'x'
                            from coefficienti_non_domestici cond
                           where cond.categoria    = nvl(ogpr.categoria,0)
                             and cond.tributo      = ogpr.tributo
                             and cond.anno         = a_anno_ruolo)
          and ogpr.oggetto_pratica = ogva.oggetto_pratica
          and ogpr.categoria = cate.categoria
          and ogpr.tributo = cate.tributo
          and nvl(cate.flag_domestica,'N') = 'N'
          and ogco.cod_fiscale = ogva.cod_fiscale
          and ((to_char(ogva.al,'yyyy') = a_anno_ruolo)
              or
               (nvl(to_char(ogva.dal,'yyyy'),1800) <= a_anno_ruolo and
                nvl(to_char(ogva.al,'yyyy'),9999) > a_anno_ruolo  and
                nvl(to_char(prtr.data,'yyyy'),a_anno_ruolo)           <= a_anno_ruolo ))
          and ogco.cod_fiscale        like a_cod_fiscale
          and ogco.oggetto_pratica    = ogpr.oggetto_pratica
          and ogpr.flag_contenzioso    is null
          and ogpr.tributo        = cotr.tributo
          and ogpr.pratica        = prtr.pratica
          and cotr.tipo_tributo||''    = prtr.tipo_tributo
          and prtr.tipo_tributo||''    = a_tipo_tributo
          and a_flag_tariffe_ruolo = 'N'
        union
       -- (VD - 14/01/2019): selezione tariffe domestiche non presenti
       select distinct a_anno_ruolo anno,
              ogpr.tributo,
              ogpr.categoria,
              to_number(null),
              'Tariffe domestiche non presenti per anno/tributo/categoria'
         from oggetti_contribuente ogco,
              oggetti_pratica ogpr,
              codici_tributo cotr,
              pratiche_tributo prtr,
              oggetti_validita ogva,
              categorie        cate
        where not exists (select 'x'
                            from tariffe_domestiche tado
                           where tado.anno         = a_anno_ruolo)
          and ogpr.oggetto_pratica = ogva.oggetto_pratica
          and ogpr.categoria = cate.categoria
          and ogpr.tributo = cate.tributo
          and nvl(cate.flag_domestica,'N') = 'S'
          and ogco.cod_fiscale = ogva.cod_fiscale
          and ((to_char(ogva.al,'yyyy') = a_anno_ruolo)
              or
               (nvl(to_char(ogva.dal,'yyyy'),1800) <= a_anno_ruolo and
                nvl(to_char(ogva.al,'yyyy'),9999) > a_anno_ruolo  and
                nvl(to_char(prtr.data,'yyyy'),a_anno_ruolo)           <= a_anno_ruolo ))
          and ogco.cod_fiscale        like a_cod_fiscale
          and ogco.oggetto_pratica    = ogpr.oggetto_pratica
          and ogpr.flag_contenzioso    is null
          and ogpr.tributo        = cotr.tributo
          and ogpr.pratica        = prtr.pratica
          and cotr.tipo_tributo||''    = prtr.tipo_tributo
          and prtr.tipo_tributo||''    = a_tipo_tributo
          and a_flag_tariffe_ruolo = 'S'
        union
       -- (VD - 14/01/2019): selezione tariffe non domestiche non presenti
       select distinct a_anno_ruolo anno,
              ogpr.tributo,
              ogpr.categoria,
              to_number(null),
              'Tariffe non domestiche non presenti per anno/tributo/categoria'
         from oggetti_contribuente ogco,
              oggetti_pratica ogpr,
              codici_tributo cotr,
              pratiche_tributo prtr,
              oggetti_validita ogva,
              categorie        cate
        where not exists (select 'x'
                            from tariffe_non_domestiche tand
                           where tand.categoria    = nvl(ogpr.categoria,0)
                             and tand.tributo      = ogpr.tributo
                             and tand.anno         = a_anno_ruolo)
          and ogpr.oggetto_pratica = ogva.oggetto_pratica
          and ogpr.tributo = cate.tributo
          and ogpr.categoria = cate.categoria
          and nvl(cate.flag_domestica,'N') = 'N'
          and ogco.cod_fiscale = ogva.cod_fiscale
          and ((to_char(ogva.al,'yyyy') = a_anno_ruolo)
              or
               (nvl(to_char(ogva.dal,'yyyy'),1800) <= a_anno_ruolo and
                nvl(to_char(ogva.al,'yyyy'),9999) > a_anno_ruolo  and
                nvl(to_char(prtr.data,'yyyy'),a_anno_ruolo)           <= a_anno_ruolo ))
          and ogco.cod_fiscale        like a_cod_fiscale
          and ogco.oggetto_pratica    = ogpr.oggetto_pratica
          and ogpr.flag_contenzioso    is null
          and ogpr.tributo        = cotr.tributo
          and ogpr.pratica        = prtr.pratica
          and cotr.tipo_tributo||''    = prtr.tipo_tributo
          and prtr.tipo_tributo||''    = a_tipo_tributo
          and a_flag_tariffe_ruolo = 'S'
              ;
/*    select distinct
           a_anno_ruolo anno, ogpr.tributo, ogpr.categoria, ogpr.tipo_tariffa
      from oggetti_contribuente ogco
          ,oggetti_pratica ogpr
          ,codici_tributo cotr
          ,pratiche_tributo prtr
     where not exists
             (select 'x'
                from tariffe tari
               where tari.tipo_tariffa = nvl (ogpr.tipo_tariffa, 0)
                 and tari.categoria = nvl (ogpr.categoria, 0)
                 and tari.tributo = ogpr.tributo
                 and tari.anno = a_anno_ruolo)
       and ( (to_char (ogco.data_cessazione, 'yyyy') = a_anno_ruolo)
         or (nvl (to_char (ogco.data_decorrenza, 'yyyy'), 1800) <=
               a_anno_ruolo
         and nvl (to_char (ogco.data_cessazione, 'yyyy'), 9999) >
               a_anno_ruolo
         and nvl (to_char (data, 'yyyy'), a_anno_ruolo) <= a_anno_ruolo
         and not exists
                   (select 'x'
                      from oggetti_contribuente ogco1, oggetti_pratica ogpr1
                     where to_char (ogco1.data_cessazione, 'yyyy') <=
                             a_anno_ruolo
                       and ogco1.cod_fiscale = ogco.cod_fiscale
                       and ogco1.oggetto_pratica = ogpr1.oggetto_pratica
                       and ogpr1.oggetto_pratica_rif =
                             nvl (ogpr.oggetto_pratica_rif
                                 ,ogpr.oggetto_pratica
                                 ))
         and    nvl (ogco.tipo_rapporto, ' ')
             || nvl (ogco.data_decorrenza
                    ,to_date ('01/01/1800', 'dd/mm/yyyy')
                    ) =
               (select max (   nvl (ogco1.tipo_rapporto, ' ')
                            || nvl (ogco1.data_decorrenza
                                   ,to_date ('01/01/1800', 'dd/mm/yyyy')
                                   )
                           )
                  from pratiche_tributo prtr1
                      ,oggetti_contribuente ogco1
                      ,oggetti_pratica ogpr1
                 where ( (prtr1.tipo_pratica = 'A'
                      and prtr1.anno < a_anno_ruolo
                      and (sysdate - nvl (prtr1.data_notifica, sysdate)) > 60)
                     or prtr1.tipo_pratica != 'A')
                   and prtr1.pratica = ogpr1.pratica
                   and ogco1.cod_fiscale = ogco.cod_fiscale
                   and ogco1.oggetto_pratica = ogpr1.oggetto_pratica
                   and nvl (ogpr1.oggetto_pratica_rif, ogpr1.oggetto_pratica) =
                         nvl (ogpr.oggetto_pratica_rif, ogpr.oggetto_pratica))))
       and ogco.cod_fiscale like a_cod_fiscale
       and ogco.oggetto_pratica = ogpr.oggetto_pratica
       and ogpr.flag_contenzioso is null
       and ogpr.tributo = cotr.tributo
       and ogpr.pratica = prtr.pratica
       and cotr.tipo_tributo || '' = prtr.tipo_tributo
       and prtr.tipo_tributo || '' = a_tipo_tributo*/
end;
/* End Procedure: TARIFFE_CHK */
/

