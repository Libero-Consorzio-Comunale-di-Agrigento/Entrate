--liquibase formatted sql 
--changeset abrandolini:20250326_152423_calcolo_detrazioni_ici stripComments:false runOnChange:true 
 
create or replace procedure CALCOLO_DETRAZIONI_ICI
/*************************************************************************
  NOME:        CALCOLO_DETRAZIONI_ICI
  DESCRIZIONE: Calcola le detrazioni ICI/IMU per contribuente/anno
  ANNOTAZIONI:
  REVISIONI:
  Rev.  Data        Autore  Descrizione
  ----  ----------  ------  ----------------------------------------------------
  005   07/10/2021  VD      Aggiunto parametro tipo_evento per gestione nuovi
                            ravvedimenti in acconto o saldo
  004   18/01/2017  VD      Modificata determinazione detrazione nel caso di
                            imposta acconto > di imposta a saldo (per evitare
                            importi negativi).
  003   20/05/2015  VD      Modificato ordinamento query SEL_OGIM per evitare
                            che nel trattamento delle detrazioni a saldo tratti
                            le pertinenze prima delle abitazioni principali.
  002   21/11/2014  VD      Modificata distribuzione detrazioni
  001   05/11/2014  VD      Modificata determinazione detrazioni se la
                            detrazione è maggiore dell'imposta per il primo
                            oggetto.
**************************************************************************/
(a_cf           IN varchar2
,a_anno         IN number
,a_ravvedimento IN varchar2
,a_tipo_evento  IN varchar2 default null
) is
errore                              exception;
fine                                exception;
w_errore                            varchar2(2000);
w_flag_pertinenze                   varchar2(1);
w_detraz                            number;
w_detraz_base                       number;
w_detraz_prec                       number;
w_detraz_base_prec                  number;
w_detraz_den                        number;
w_detraz_base_den                   number;
w_detraz_den_prec                   number;
w_detraz_base_den_prec              number;
w_num_contitolari                   number;
w_mesi_possesso                     number;
w_mesi_possesso_1s                  number;
w_mm_inizio_periodo                 number;
w_mm_fine_periodo                   number;
w_mm_inizio_periodo_1s              number;
w_mm_fine_periodo_1s                number;
w_mesi_possesso_den                 number;
w_mesi_possesso_ogco                number;
w_mesi_possesso_1s_ogco             number;
w_mm_inizio_periodo_ogco            number;
w_mm_fine_periodo_ogco              number;
w_mm_inizio_periodo_1s_ogco         number;
w_mm_fine_periodo_1s_ogco           number;
w_stringa                           varchar2(18);
w_flag_possesso                     varchar2(1);
w_tot_detrazione                    number;
w_tot_detrazione_prec               number;
w_tot_detrazione_d                  number;
w_tot_detrazione_prec_d             number;
w_detr                              number;
w_detr_acc                          number;
w_detrazione                        number;
w_detrazione_acconto                number;
w_detrazione_d                      number;
w_detrazione_acconto_d              number;
w_maggiore_detrazione               number;
w_maggiore_detrazione_acconto       number;
w_maggiore_detrazione_prec          number;
w_detrazione_ogco                   number;
w_detrazione_acconto_ogco           number;
w_anno_prec                         number;
w_oggetto_pratica_prec              number;
w_mesi_possesso_prec                number;
w_den_detraz                        number;
w_loop                              number;
w_cod_fiscale                       varchar2(16);
w_impo_pert_acc                     number;
w_detr_pertinenze                   number;
w_imposta_da_trattare               number;
w_imposta_da_trattare_d             number;
--
-- Selezione dei contribuenti su cui e` stata calcolata l`imposta ICI.
-- (sono quelli che hanno la data di sistema nella data di variazione
-- sugli oggetti imposta.
-- Non vengono estratti i contribuenti con solo oggetti_pratica che hanno una detrazione oggetto (detrazioni_ogco)
-- e le pertinenze collegate a tali oggetti
--
cursor sel_cf (p_cf                varchar2
              ,p_anno              number
              ,p_flag_pertinenze   varchar2
              ,p_ravvedimento      varchar2
              ,p_tipo_evento       varchar2
              )
is
select ogco.cod_fiscale            cod_fiscale
  from oggetti_contribuente        ogco
      ,oggetti_pratica             ogpr
      ,pratiche_tributo            prtr
      ,oggetti                     ogge
      ,oggetti_imposta             ogim
 where ogco.cod_fiscale            =    ogim.cod_fiscale
   and ogco.oggetto_pratica        =    ogim.oggetto_pratica
   and ogpr.oggetto_pratica        =    ogim.oggetto_pratica
   and prtr.pratica                =    ogpr.pratica
   and prtr.tipo_tributo||''       =    'ICI'
   and nvl(prtr.stato_accertamento,'D') = 'D'
   and ogge.oggetto                =    ogpr.oggetto
   and ogim.cod_fiscale         like    p_cf
   and ogim.anno                   =    p_anno
   and ogim.ruolo                 is    null
   and trunc(ogim.data_variazione) =    trunc(sysdate)
   and (  (  p_ravvedimento        =    'S'
        and prtr.tipo_pratica      =    'V'
        and prtr.tipo_evento       =    nvl(p_tipo_evento,prtr.tipo_evento)
        and not exists (select 'x'
                          from sanzioni_pratica sapr
                         where sapr.pratica = prtr.pratica)
          )
        or
          ( p_ravvedimento         =    'N'
        and prtr.tipo_pratica     in    ('D','A')
        and nvl(ogim.flag_calcolo,'N')     = 'S'
          )
       )
   and (    p_flag_pertinenze      = 'S'
        and F_DATO_RIOG(ogim.cod_fiscale
                       ,ogim.oggetto_pratica
                       ,ogim.anno
                       ,'CA'
                       )        like 'C%'
        or  F_DATO_RIOG(ogim.cod_fiscale
                       ,ogim.oggetto_pratica
                       ,ogim.anno
                       ,'CA'
                       )        like 'A%'
       )
   and not exists (select 'x'
                     from detrazioni_ogco deog
               where deog.cod_fiscale     = ogco.cod_fiscale
                 and deog.oggetto_pratica = ogco.oggetto_pratica
                 and deog.anno            = p_anno
                 and deog.tipo_tributo    = 'ICI'
               union
                   select 'x'
                     from detrazioni_ogco deog2
                        , oggetti_pratica ogpr2
                    where deog2.cod_fiscale     = ogco.cod_fiscale
                      and deog2.oggetto_pratica = ogpr2.oggetto_pratica_rif_ap
                      and deog2.anno            = p_anno
                      and deog2.tipo_tributo    = 'ICI'
                      and ogpr2.oggetto_pratica = ogco.oggetto_pratica
                    )
 group by
       ogco.cod_fiscale
 order by 1
;
--
-- Dato un Contribuente, si determinano le Detrazioni Totali da applicare.
-- Questo cursore viene utilizzato  sia per determinare  le imposte totali
-- che per applicare le detrazioni sui singoli oggetti.
-- Si considerano tutti gli oggetti che hanno  in denuncia una detrazione.
-- Anche i comodati devono avere indicata in denuncia la detrazione.
-- Non vengono estratti gli oggetti_pratica che hanno una detrazione oggetto (detrazioni_ogco)
-- e le pertinenze collegate a tali oggetti
--
cursor sel_ogco (p_cf              varchar2
                ,p_anno            number
                ,p_flag_pertinenze varchar2
                ,p_ravvedimento    varchar2
                ,p_tipo_evento     varchar2
                )
is
select ogco.oggetto_pratica        oggetto_pratica
     , decode(ogco.anno
             ,p_anno,nvl(ogco.mesi_possesso,12)
                    ,12
             )                     mesi_possesso
      ,decode(ogco.anno
             ,p_anno,decode(ogco.flag_al_ridotta
                           ,'S',nvl(ogco.mesi_aliquota_ridotta,nvl(ogco.mesi_possesso,12))
                               ,nvl(ogco.mesi_aliquota_ridotta,0)
                           )
                    ,decode(ogco.flag_al_ridotta,'S',12,0)
             )                     mesi_al_ridotta
      ,decode(ogco.anno
             ,p_anno,decode(ogco.flag_esclusione
                           ,'S',nvl(ogco.mesi_esclusione,nvl(ogco.mesi_possesso,12))
                               ,nvl(ogco.mesi_esclusione,0)
                           )
                    ,decode(ogco.flag_esclusione,'S',12,0)
            )                      mesi_esclusione
      ,ogco.flag_possesso          flag_possesso
      ,ogco.flag_esclusione        flag_esclusione
      ,ogco.flag_al_ridotta        flag_al_ridotta
      ,ogco.detrazione             detr
      ,round(decode(nvl(ogco.mesi_possesso,12)
             ,0,0
               ,nvl(ogco.detrazione,0) / nvl(ogco.mesi_possesso,12) * 12
             ),2)                     detrazione
      ,ogpr.oggetto                oggetto
      ,ogco.anno                   anno
      ,ogim.oggetto_imposta        oggetto_imposta
      ,ogim.imposta                imposta
      ,ogim.imposta_dovuta         imposta_dovuta
      ,ogim.imposta_acconto        imposta_acconto
      ,ogim.imposta_dovuta_acconto imposta_dovuta_acconto
      ,F_DATO_RIOG(ogim.cod_fiscale
                       ,ogim.oggetto_pratica
                       ,ogim.anno
                       ,'CA'
                       )           categoria_catasto
  from oggetti_contribuente        ogco
      ,oggetti_pratica             ogpr
      ,pratiche_tributo            prtr
      ,oggetti                     ogge
      ,oggetti_imposta             ogim
 where ogco.cod_fiscale               =    ogim.cod_fiscale
   and ogco.oggetto_pratica           =    ogim.oggetto_pratica
   and ogpr.oggetto_pratica           =    ogim.oggetto_pratica
   and prtr.pratica                   =    ogpr.pratica
   and prtr.tipo_tributo||''          =    'ICI'
   and nvl(prtr.stato_accertamento,'D') = 'D'
   and ogge.oggetto                   =    ogpr.oggetto
   and ogim.cod_fiscale               =    p_cf
   and ogim.anno                      =    p_anno
   and ogim.ruolo                    is    null
   and (    nvl(ogco.detrazione,0)    > 0
        and ogco.flag_ab_principale   =    'S'
        or  nvl(ogco.detrazione,0)    > 0
        and ogco.anno                 =    p_anno
       )
   and trunc(ogim.data_variazione)    =    trunc(sysdate)
   and (  (  p_ravvedimento           =    'S'
        and prtr.tipo_pratica         =    'V'
        and prtr.tipo_evento          =    nvl(p_tipo_evento,prtr.tipo_evento)
        and not exists (select 'x'
                          from sanzioni_pratica sapr
                         where sapr.pratica = prtr.pratica)
          )
       or (  p_ravvedimento            =    'N'
        and prtr.tipo_pratica         in    ('D','A')
        and nvl(ogim.flag_calcolo,'N')     = 'S'
          )
       )
   and (    p_flag_pertinenze         = 'S'
        and F_DATO_RIOG(ogim.cod_fiscale
                       ,ogim.oggetto_pratica
                       ,ogim.anno
                       ,'CA'
                       )           like 'C%'
        or  F_DATO_RIOG(ogim.cod_fiscale
                       ,ogim.oggetto_pratica
                       ,ogim.anno
                       ,'CA'
                       )           like 'A%'
       )
   and not exists (select 'x'
                     from detrazioni_ogco deog
               where deog.cod_fiscale     = p_cf
                 and deog.oggetto_pratica = ogco.oggetto_pratica
                 and deog.anno            = p_anno
                 and deog.tipo_tributo    = 'ICI'
               union
                   select 'x'
                     from detrazioni_ogco deog2
                        , oggetti_pratica ogpr2
                    where deog2.cod_fiscale     = p_cf
                      and deog2.oggetto_pratica = ogpr2.oggetto_pratica_rif_ap
                      and deog2.anno            = p_anno
                      and deog2.tipo_tributo    = 'ICI'
                      and ogpr2.oggetto_pratica = ogco.oggetto_pratica
                   )
 order by 1
;
--
-- Determinazione degli oggetti soggetti a detrazione sui quali spalmare
-- il residuo di detrazione non ancora applicato agli oggetti nella  cui
-- denuncia e` specificata una detrazione.  Prima si opera sugli oggetti
-- che non sono stati ancora interessati dalle detrazioni (in ordine  di
-- categoria catastale per agevolare i comodati sulle pertinenze) e solo
-- successivamente si ritrattano eventualmente gli oggetti con applicata
-- una detrazione.
-- Non vengono estratti gli oggetti_pratica che hanno una detrazione oggetto (detrazioni_ogco)
-- e pertinenze collegate a tali oggetti
--
cursor sel_ogim (p_cf              varchar2
                ,p_anno            number
                ,p_flag_pertinenze varchar2
                ,p_ravvedimento    varchar2
                ,p_tipo_evento     varchar2
                )
is
select decode(ogim.detrazione,null,1,
              decode(ogim.wrk_calcolo,'ID',1,2)
             )                     detrazione_ogim
      ,F_DATO_RIOG(ogim.cod_fiscale
                       ,ogim.oggetto_pratica
                       ,ogim.anno
                       ,'CA'
                       )           categoria_catasto
      ,ogco.oggetto_pratica        oggetto_pratica
      ,ogpr.oggetto                oggetto
      ,ogco.anno                   anno
      ,ogim.oggetto_imposta        oggetto_imposta
      ,ogim.imposta                imposta
      ,ogim.imposta_dovuta         imposta_dovuta
      ,ogim.imposta_acconto        imposta_acconto
      ,ogim.imposta_dovuta_acconto imposta_dovuta_acconto
  from oggetti_contribuente        ogco
      ,oggetti_pratica             ogpr
      ,pratiche_tributo            prtr
      ,oggetti                     ogge
      ,oggetti_imposta             ogim
 where ogco.cod_fiscale               =    ogim.cod_fiscale
   and ogco.oggetto_pratica           =    ogim.oggetto_pratica
   and ogpr.oggetto_pratica           =    ogim.oggetto_pratica
   and prtr.pratica                   =    ogpr.pratica
   and prtr.tipo_tributo||''          =    'ICI'
   and nvl(prtr.stato_accertamento,'D') = 'D'
   and ogge.oggetto                   =    ogpr.oggetto
   and ogim.cod_fiscale               =    p_cf
   and ogim.anno                      =    p_anno
   and ogim.ruolo                    is    null
   and trunc(ogim.data_variazione)    =    trunc(sysdate)
   and (  (  p_ravvedimento           =    'S'
        and prtr.tipo_pratica         =    'V'
        and prtr.tipo_evento          =    nvl(p_tipo_evento,prtr.tipo_evento)
        and not exists (select 'x'
                          from sanzioni_pratica sapr
                         where sapr.pratica = prtr.pratica)
           )
        or ( p_ravvedimento            =    'N'
        and prtr.tipo_pratica       in    ('D','A')
        and nvl(ogim.flag_calcolo,'N') = 'S'
           )
       )
   and (    ogco.flag_ab_principale   =    'S'
        or  ogco.detrazione          is    not null
         and ogco.anno                 =    p_anno
        or exists (select 'x'
                    from oggetti_pratica ogpr1
                       , oggetti_contribuente ogco1
                   where ogpr1.oggetto_pratica = ogco1.oggetto_pratica
                     and ogpr1.oggetto_pratica = ogpr.oggetto_pratica_rif_ap
                     and (  ogco1.flag_ab_principale = 'S'
                         or ogco1.detrazione is not null
                           and ogco1.anno = p_anno
                         )
                )
       )
   and (    p_flag_pertinenze         = 'S'
        and F_DATO_RIOG(ogim.cod_fiscale
                       ,ogim.oggetto_pratica
                       ,ogim.anno
                       ,'CA'
                       )           like 'C%'
        or  F_DATO_RIOG(ogim.cod_fiscale
                       ,ogim.oggetto_pratica
                       ,ogim.anno
                       ,'CA'
                       )           like 'A%'
       )
   and not exists (select 'x'
                     from detrazioni_ogco deog
               where deog.cod_fiscale     = p_cf
                 and deog.oggetto_pratica = ogco.oggetto_pratica
                 and deog.anno            = p_anno
                 and deog.tipo_tributo    = 'ICI'
               union
                   select 'x'
                     from detrazioni_ogco deog2
                        , oggetti_pratica ogpr2
                    where deog2.cod_fiscale     = p_cf
                      and deog2.oggetto_pratica = ogpr2.oggetto_pratica_rif_ap
                      and deog2.anno            = p_anno
                      and deog2.tipo_tributo    = 'ICI'
                      and ogpr2.oggetto_pratica = ogco.oggetto_pratica
                   )
 order by 1, 2, 3
;
BEGIN
--
-- Determinazione della presenza di gestione delle pertinenze.
--
   BEGIN
      select flag_pertinenze
        into w_flag_pertinenze
        from aliquote
       where flag_ab_principale = 'S'
         and anno               = a_anno
         and tipo_tributo       = 'ICI'
      ;
   EXCEPTION
      WHEN NO_DATA_FOUND OR TOO_MANY_ROWS THEN
         w_flag_pertinenze := null;
   END;
--
-- Determinazione della Detrazione Base dell`anno di imposta.
--
   BEGIN
      select nvl(detrazione,0)
            ,nvl(detrazione_base,0)
        into w_detraz
            ,w_detraz_base
        from detrazioni
       where anno     = a_anno
         and tipo_tributo = 'ICI'
      ;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         w_detraz      := 0;
         w_detraz_base := 0;
   END;
   if a_anno > 2000 and a_anno < 2012 then
      BEGIN
         select nvl(detrazione,0)
               ,nvl(detrazione_base,0)
           into w_detraz_prec
               ,w_detraz_base_prec
           from detrazioni
          where anno     = a_anno - 1
            and tipo_tributo = 'ICI'
         ;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            w_detraz_prec      := 0;
            w_detraz_base_prec := 0;
      END;
      w_detraz_prec      := round(w_detraz_prec * 50 / 100,2);
   elsif a_anno >= 2012 then
      w_detraz_prec      := w_detraz;
      w_detraz_base_prec := w_detraz_base;
      w_detraz_prec      := round(w_detraz_prec * 50 / 100,2);
   else
      w_detraz_prec      := w_detraz;
      w_detraz_base_prec := w_detraz_base;
      w_detraz_prec      := round(w_detraz_prec * 45 / 100,2);
   end if;
--
-- Trattamento Contribuenti.
--
   FOR rec_cf IN sel_cf (a_cf,a_anno,w_flag_pertinenze,a_ravvedimento,a_tipo_evento)
   LOOP
      w_cod_fiscale := rec_cf.cod_fiscale;
      w_tot_detrazione           := 0;
      w_tot_detrazione_prec      := 0;
      BEGIN
         select detrazione
              , detrazione_acconto
           into w_maggiore_detrazione
              , w_maggiore_detrazione_acconto
           from maggiori_detrazioni
          where cod_fiscale       = rec_cf.cod_fiscale
            and anno              = a_anno
            and tipo_tributo = 'ICI'
         ;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            w_maggiore_detrazione := null;
            w_maggiore_detrazione_acconto := null;
      END;
      if a_anno > 2000 and a_anno < 2012 then
         BEGIN
            select made.detrazione
              into w_maggiore_detrazione_prec
              from maggiori_detrazioni made
             where made.cod_fiscale    = rec_cf.cod_fiscale
               and made.anno           = a_anno - 1
               and tipo_tributo = 'ICI'
            ;
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               w_maggiore_detrazione_prec := null;
         END;
      else
         w_maggiore_detrazione_prec := w_maggiore_detrazione;
      end if;
--
-- Il Cursore sottostante viene utilizzato due volte: la prima per totalizzare
-- le Detrazioni da applicare, la seconda invece per applicarle.
-- w_loop e` la variabile che governa questi utilizzi del cursore.
--
      w_loop := 0;
      LOOP
         w_loop := w_loop + 1;
         if w_loop > 2 then
            exit;
         end if;
         FOR rec_ogco IN sel_ogco (rec_cf.cod_fiscale
                                  ,a_anno
                                  ,w_flag_pertinenze
                                  ,a_ravvedimento
                                  ,a_tipo_evento
                                  )
         LOOP
            w_flag_possesso            := rec_ogco.flag_possesso;
--
-- Determinazione  Mesi di Possesso  per l`intero anno e per il primo semestre.
-- La F_DATO_RIOG  restituisce una stringa  del tipo  XXYYYYYYYYZZZZZZZZ in cui
-- XX e` il numero dei mesi di possesso, YYYYYYYY e` la data di inizio possesso
-- in forma GGMMAAAA e ZZZZZZZZ e` la data di fine possesso nella stessa forma.
-- Qualora i mesi di possesso siano = 0, le date contengono il valore 00000000.
-- Per ottenere il possesso dell`intero anno l`ultimo parametro deve essere PT,
-- mentre per il possesso del primo semestre deve essere PA.
--
            w_stringa                  := F_DATO_RIOG(rec_cf.cod_fiscale
                                                     ,rec_ogco.oggetto_pratica
                                                     ,a_anno
                                                     ,'PT'
                                                     );
            w_mesi_possesso            := to_number(substr(w_stringa,01,2));
            w_mm_inizio_periodo        := to_number(substr(w_stringa,05,2));
            w_mm_fine_periodo          := to_number(substr(w_stringa,13,2));
            w_stringa                  := F_DATO_RIOG(rec_cf.cod_fiscale
                                                     ,rec_ogco.oggetto_pratica
                                                     ,a_anno
                                                     ,'PA'
                                                     );
            w_mesi_possesso_1s         := to_number(substr(w_stringa,01,2));
            w_mm_inizio_periodo_1s     := to_number(substr(w_stringa,05,2));
            w_mm_fine_periodo_1s       := to_number(substr(w_stringa,13,2));
--
-- Se l`anno della pratica  in esame corrisponde all`anno  di imposta, non si
-- richiama la funzione  di determinazione  delle detrazioni, ma si considera
-- direttamente la detrazione  indicata. Per l`acconto, se anno > 2000  viene
-- controllato se l`anno della pratica e` uguale all`anno di imposta - 1, nel
-- qual caso si applica  la detrazione indicata. Solo nel caso  in cui l`anno
-- della pratica sia uguale all`anno di imposta si va a controllare se esiste
-- una pratica ICI con detrazione per stessi oggetto e contribuente dell`anno
-- precedente, nel qual caso si applica la detrazione indicata in pratica. Il
-- caso dell`anno di imposta fino al 2000 invece considera l`eventuale valore
-- indicato per l`anno. Per l`acconto la detrazione  va proporzionata ai mesi
-- di possesso del primo semestre.
--
-- Quando invece non si considera la detrazione, si esegue la funzione per la
-- Determinazione della Detrazione Totale e del primo Semestre sulla base dei
-- dizionari  delle  Detrazioni che indicano  la detrazione base  per singolo
-- immobile sui 12 mesi.
-- Inoltre in caso di superamento  del tetto previsto,  le detrazioni vengono
-- ricondotte al tetto.
--
            w_detr     := null;
            w_detr_acc := null;
            if rec_ogco.anno = a_anno then
               w_detr := rec_ogco.detr;
               if a_anno <= 2000 then
                  if w_mesi_possesso = 0 then
                     w_detr_acc := 0;
                  else
                     w_detr_acc := round(rec_ogco.detrazione * 0.9 / 12 * w_mesi_possesso_1s,2);
                  end if;
               elsif a_anno > 2000 and a_anno < 2012 then
                  BEGIN
                     select ogco.detrazione
                           ,ogco.oggetto_pratica
                       into w_detr_acc
                           ,w_oggetto_pratica_prec
                       from oggetti_contribuente ogco
                           ,oggetti_pratica      ogpr
                           ,pratiche_tributo     prtr
                      where ogpr.oggetto_pratica    = ogco.oggetto_pratica
                        and prtr.pratica            = ogpr.pratica
                        and prtr.tipo_tributo||''   = 'ICI'
                        and nvl(prtr.stato_accertamento,'D') = 'D'
                      --  and (    a_ravvedimento     = 'S'
                      --       and prtr.tipo_pratica  = 'V'
                      --       or  a_ravvedimento     = 'N'
                             and prtr.tipo_pratica in ('D','A')
                             and decode(prtr.tipo_pratica,'D','S',prtr.flag_denuncia)
                                                    = 'S'
                      --      )
                        and nvl(ogco.flag_possesso,'N') = 'S'
                        and ogco.cod_fiscale        = rec_cf.cod_fiscale
                        and ogco.anno               = a_anno - 1
                        and ogpr.oggetto            = rec_ogco.oggetto
                        and nvl(ogco.detrazione,0)  > 0
                     ;
                     w_mesi_possesso_prec := to_number(substr(F_DATO_RIOG(rec_cf.cod_fiscale
                                                                         ,w_oggetto_pratica_prec
                                                                         ,a_anno - 1
                                                                         ,'PT'
                                                                         ),1,2
                                                             )
                                                      );
                     if w_mesi_possesso_prec = 0 then
                        w_detr_acc := 0;
                     else
                        w_detr_acc := round(w_detr_acc / w_mesi_possesso_prec * w_mesi_possesso_1s,2);
                     end if;
                  EXCEPTION
                     WHEN NO_DATA_FOUND THEN
                        w_detr_acc := null;
                        w_oggetto_pratica_prec := null;
                  END;
               end if;
            end if;
            if a_anno > 2000 and a_anno < 2012 then
               if rec_ogco.anno = a_anno - 1 then
                  w_mesi_possesso_prec := to_number(substr(F_DATO_RIOG(rec_cf.cod_fiscale
                                                                      ,rec_ogco.oggetto_pratica
                                                                      ,a_anno - 1
                                                                      ,'PT'
                                                                      ),1,2
                                                          )
                                                   );
                  if w_mesi_possesso_prec = 0 then
                     w_detr_acc := 0;
                  else
                     w_detr_acc := round(rec_ogco.detr / w_mesi_possesso_prec * w_mesi_possesso_1s,2);
                  end if;
               end if;
            end if;
            if w_detr is null or w_detr_acc is null then
--
-- Proporziono la detrazione agli effettivi mesi di possesso
--
               w_detr     := round(rec_ogco.detrazione / 12 * w_mesi_possesso,2);
               w_detr_acc := round(rec_ogco.detrazione / 12 * w_mesi_possesso_1s,2);
--
-- Ora e` necessario riproporzionare la detrazione assegnata nell`anno di denuncia
-- all`anno di imposta secondo la logica:  la detrazione assegnata sta alla totale
-- dell`anno di denuncia  come la detrazione  dell`anno di calcolo sta alla totale
-- dell`anno di calcolo.
--
               BEGIN
                  select nvl(detrazione,0)
                        ,nvl(detrazione_base,0)
                    into w_detraz_den
                        ,w_detraz_base_den
                    from detrazioni
                   where anno     = rec_ogco.anno
                     and tipo_tributo = 'ICI'
                  ;
               EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                     w_detraz_den      := 0;
                     w_detraz_base_den := 0;
               END;
               if w_detraz_base_den <> 0 then
                  w_detr     := round(w_detr     / w_detraz_base_den * w_detraz_base,2);
                  w_detr_acc := round(w_detr_acc / w_detraz_base_den * w_detraz_base_prec,2);
               else
                  w_detr     := 0;
                  w_detr_acc := 0;
               end if;
            end if;
            if w_detr is not null then
               w_detrazione := w_detr;
            end if;
            if w_detr_acc is not null then
               w_detrazione_acconto := w_detr_acc;
            end if;
            if w_loop = 1 then
               w_tot_detrazione      := w_tot_detrazione      + w_detrazione;
               w_tot_detrazione_prec := w_tot_detrazione_prec + w_detrazione_acconto;
            end if;
            if w_loop = 2 then
               if a_anno >= 2012 and substr(rec_ogco.categoria_catasto,1,1) = 'A' then
                  if rec_ogco.imposta_acconto < w_detrazione_acconto  then
                     begin
                        select sum(nvl(ogim.imposta_acconto,0))
                          into w_impo_pert_acc
                          from oggetti_contribuente        ogco
                             , oggetti_pratica             ogpr
                             , pratiche_tributo            prtr
                          --   , oggetti                     ogge
                             , oggetti_imposta             ogim
                         where ogco.cod_fiscale               =    ogim.cod_fiscale
                           and ogco.oggetto_pratica           =    ogim.oggetto_pratica
                           and ogpr.oggetto_pratica           =    ogim.oggetto_pratica
                           and prtr.pratica                   =    ogpr.pratica
                           and prtr.tipo_tributo||''          =    'ICI'
                           and nvl(prtr.stato_accertamento,'D') = 'D'
                       --    and ogge.oggetto                   =    ogpr.oggetto
                           and ogim.cod_fiscale               =    rec_cf.cod_fiscale
                           and ogim.anno                      =    a_anno
                           and ogim.ruolo                    is    null
                           and trunc(ogim.data_variazione)    =    trunc(sysdate)
                           and (  (  a_ravvedimento           =    'S'
                                and prtr.tipo_pratica         =    'V'
                                and prtr.tipo_evento          =    nvl(a_tipo_evento,prtr.tipo_evento)
                                and not exists (select 'x'
                                                  from sanzioni_pratica sapr
                                                 where sapr.pratica = prtr.pratica)
                                   )
                                or ( a_ravvedimento            =    'N'
                                and prtr.tipo_pratica       in    ('D','A')
                                and nvl(ogim.flag_calcolo,'N') = 'S'
                                   )
                               )
                           and (    ogco.flag_ab_principale   =    'S'
                                or  ogco.detrazione          is    not null
                                 and ogco.anno                 =    a_anno
                                or exists (select 'x'
                                            from oggetti_pratica ogpr1
                                               , oggetti_contribuente ogco1
                                           where ogpr1.oggetto_pratica = ogco1.oggetto_pratica
                                             and ogpr1.oggetto_pratica = ogpr.oggetto_pratica_rif_ap
                                             and (  ogco1.flag_ab_principale = 'S'
                                                 or ogco1.detrazione is not null
                                                   and ogco1.anno = a_anno
                                                 )
                                        )
                               )
                           and (    w_flag_pertinenze         = 'S'
                                and F_DATO_RIOG(ogim.cod_fiscale
                                               ,ogim.oggetto_pratica
                                               ,ogim.anno
                                               ,'CA'
                                               )           like 'C%'
                               )
                           and not exists (select 'x'
                                             from detrazioni_ogco deog
                                       where deog.cod_fiscale     = rec_cf.cod_fiscale
                                         and deog.oggetto_pratica = ogco.oggetto_pratica
                                         and deog.anno            = a_anno
                                         and deog.tipo_tributo    = 'ICI'
                                       union
                                           select 'x'
                                             from detrazioni_ogco deog2
                                                , oggetti_pratica ogpr2
                                            where deog2.cod_fiscale     = rec_cf.cod_fiscale
                                              and deog2.oggetto_pratica = ogpr2.oggetto_pratica_rif_ap
                                              and deog2.anno            = a_anno
                                              and deog2.tipo_tributo    = 'ICI'
                                              and ogpr2.oggetto_pratica = ogco.oggetto_pratica
                                            );
                     EXCEPTION
                        WHEN OTHERS THEN
                           w_impo_pert_acc   := 0;
                     end;
                     w_detr_pertinenze := least(w_detrazione_acconto - rec_ogco.imposta_acconto
                                               ,w_impo_pert_acc);
                     if w_detr_pertinenze < 0 then
                        w_detr_pertinenze := 0;
                     end if;
                     w_detrazione := least(w_detrazione,nvl(w_tot_detrazione,0)) - w_detr_pertinenze;
                     if w_detrazione < 0 then
                        w_detrazione := 0;
                     end if;
                  end if;
               end if;
               w_detrazione             := least(nvl(rec_ogco.imposta,0)
                                                ,nvl(w_tot_detrazione,0)
                                                ,nvl(w_detrazione,0)
                                                );
               w_detrazione_d           := least(nvl(rec_ogco.imposta_dovuta,0)
                                                ,nvl(w_tot_detrazione_d,0)
                                                ,nvl(w_detrazione,0)
                                                );
               w_tot_detrazione         := w_tot_detrazione   - w_detrazione;
               w_tot_detrazione_d       := w_tot_detrazione_d - w_detrazione_d;
               w_detrazione_acconto     := least(nvl(rec_ogco.imposta_acconto,0)
                                                ,nvl(w_tot_detrazione_prec,0)
                                                ,nvl(w_detrazione_acconto,0)
                                                ,w_detrazione
                                                );
               w_detrazione_acconto_d   := least(nvl(rec_ogco.imposta_dovuta_acconto,0)
                                                ,nvl(w_tot_detrazione_prec_d,0)
                                                ,nvl(w_detrazione_acconto,0)
                                                ,w_detrazione_d
                                                );
               w_tot_detrazione_prec    := w_tot_detrazione_prec   - w_detrazione_acconto;
               w_tot_detrazione_prec_d  := w_tot_detrazione_prec_d - w_detrazione_acconto_d;
               --
               -- Aggiornamento Detrazioni e Imposte.
               --
               update oggetti_imposta
                  set detrazione             = decode(nvl(detrazione,0) + w_detrazione
                                                     ,0,to_number(null)
                                                      ,nvl(detrazione,0) + w_detrazione
                                                     )
                     ,detrazione_acconto     = decode(nvl(detrazione_acconto,0) + w_detrazione_acconto
                                                     ,0,to_number(null)
                                                       ,nvl(detrazione_acconto,0) + w_detrazione_acconto
                                                     )
                     ,imposta                = imposta - w_detrazione
                     ,imposta_dovuta         = nvl(imposta_dovuta,0) - nvl(w_detrazione_d,0)
                     ,imposta_acconto        = nvl(imposta_acconto,0) - nvl(w_detrazione_acconto,0)
                     ,imposta_dovuta_acconto = nvl(imposta_dovuta_acconto,0) - nvl(w_detrazione_acconto_d,0)
                where oggetto_imposta        = rec_ogco.oggetto_imposta
               ;
            end if;
         END LOOP;
        --
        -- Limitatamente all`imposta totale, se sono indicate maggiori detrazioni, vengono  prese
        -- quelle come detrazioni totali (esse sono gia` rapportate al numero di mesi di possesso
        -- e al numero di contitolari.
        --
        if w_loop = 1 then
          if w_maggiore_detrazione is not null then
             w_tot_detrazione         := w_maggiore_detrazione;
          end if;
          if w_maggiore_detrazione_acconto is not null then
             w_tot_detrazione_prec    := w_maggiore_detrazione_acconto;
          else
             -- Se esiste una maggiore detrazione per l'anno precedente a quello di imposta,
             -- viene preso questo valore diviso 2 come detrazione totale per l'acconto
             -- questo solo se non esiste per l'anno d'imposta una denuncia con indicata
             -- una detrazione che indica che la detrazione dell'anno precedente è stata modificata
             --
             if w_maggiore_detrazione_prec is not null then
                BEGIN
                   select count(1)
                    into w_den_detraz
                       from oggetti_contribuente ogco
                           ,oggetti_pratica      ogpr
                           ,pratiche_tributo     prtr
                      where ogpr.oggetto_pratica    = ogco.oggetto_pratica
                        and prtr.pratica            = ogpr.pratica
                        and prtr.tipo_tributo||''   = 'ICI'
                        and nvl(prtr.stato_accertamento,'D') = 'D'
                       -- and (    a_ravvedimento     = 'S'
                            -- and prtr.tipo_pratica  = 'V'
                            -- or  a_ravvedimento     = 'N'
                             and prtr.tipo_pratica in ('D','A')
                             and decode(prtr.tipo_pratica,'D','S',prtr.flag_denuncia)
                                                    = 'S'
                      --      )
                --        and nvl(ogco.flag_possesso,'N') = 'S'
                        and ogco.cod_fiscale        = rec_cf.cod_fiscale
                        and ogco.anno               = a_anno
                        and nvl(ogco.detrazione,0)  > 0
                            ;
                EXCEPTION
                  WHEN OTHERS THEN
                     w_den_detraz := 0;
                END;
                if w_den_detraz = 0 then
                   w_tot_detrazione_prec         := round(w_maggiore_detrazione_prec/2,2);
                end if;
             end if;
             -- Nel caso   in cui    non vi sia la maggiore detrazione per l'anno precedente, vi sia quella
             -- per questo anno e la detrazione totale calcolata rispetto ai dati di denuncia sia 0
             -- Si prende come detrazione totale per l'acconto la maggiore detrazione dell'anno diviso 2
             --
             if w_maggiore_detrazione_prec is null and w_maggiore_detrazione is not null and w_tot_detrazione_prec <= 0 then
                w_tot_detrazione_prec         := round(w_maggiore_detrazione / 2,2);
             end if;
              end if; -- w_maggiore_detrazione_acconto is not null
          -- nel caso che la detrazione totale per l'acconto (w_tot_detrazione_prec) sia maggiore della detrazione totale
          -- si setta la detrazione totale per l'acconto pari alla detrazione totale
            if w_tot_detrazione_prec  > w_tot_detrazione then
               w_tot_detrazione_prec :=  w_tot_detrazione;
            end if;
          --
          -- Si pongono sia le detrazioni totali che quelle in acconto per dichiarato uguali a quelle
          -- determinate, perche` la parte che si va a scalare puo` differire in quanto l`imposta non
          -- e` sempre uguale all`imposta dovuta (si pensi alla presenza di rendite definitive).
          --
          w_tot_detrazione_d      := w_tot_detrazione;
          w_tot_detrazione_prec_d := w_tot_detrazione_prec;
        end if; -- w_loop = 1
      --
      -- Fine Loop governato da w_loop.
      --
      END LOOP;
      --
      -- Trattamento di eventuali Residui di Detrazione.in ACCONTO
      --
      if w_tot_detrazione_prec   > 0
      or w_tot_detrazione_prec_d > 0 then
         FOR rec_ogim IN sel_ogim (rec_cf.cod_fiscale
                                  ,a_anno
                                  ,w_flag_pertinenze
                                  ,a_ravvedimento
                                  ,a_tipo_evento
                                  )
         LOOP
            w_detrazione_acconto     := least(nvl(rec_ogim.imposta,0)
                                             ,nvl(rec_ogim.imposta_acconto,0)
                                             ,nvl(w_tot_detrazione,0)
                                             ,nvl(w_tot_detrazione_prec,0)
                                             );
            w_detrazione_acconto_d   := least(nvl(rec_ogim.imposta_dovuta,0)
                                             ,nvl(rec_ogim.imposta_dovuta_acconto,0)
                                             ,nvl(w_tot_detrazione_d,0)
                                             ,nvl(w_tot_detrazione_prec_d,0)
                                             );
            w_tot_detrazione         := w_tot_detrazione        - w_detrazione_acconto;
            w_tot_detrazione_d       := w_tot_detrazione_d      - w_detrazione_acconto_d;
            w_tot_detrazione_prec    := w_tot_detrazione_prec   - w_detrazione_acconto;
            w_tot_detrazione_prec_d  := w_tot_detrazione_prec_d - w_detrazione_acconto_d;
            update oggetti_imposta
               set detrazione             = decode(nvl(detrazione,0) + w_detrazione_acconto
                                                  ,0,to_number(null)
                                                    ,nvl(detrazione,0) + w_detrazione_acconto
                                                  )
                  ,detrazione_acconto     = decode(nvl(detrazione_acconto,0) + w_detrazione_acconto
                                                  ,0,to_number(null)
                                                    ,nvl(detrazione_acconto,0) + w_detrazione_acconto
                                                  )
                  ,imposta                = imposta - w_detrazione_acconto
                  ,imposta_dovuta         = nvl(imposta_dovuta,0) - nvl(w_detrazione_acconto_d,0)
                  ,imposta_acconto        = nvl(imposta_acconto,0) - nvl(w_detrazione_acconto,0)
                  ,imposta_dovuta_acconto = nvl(imposta_dovuta_acconto,0) - nvl(w_detrazione_acconto_d,0)
                  ,wrk_calcolo            = 'ID'
             where oggetto_imposta        = rec_ogim.oggetto_imposta
            ;
         END LOOP;
      end if;
      --
      -- Trattamento di eventuali Residui di Detrazione.(SALDO)
      --
      if w_tot_detrazione        > 0
      or w_tot_detrazione_d      > 0
      or w_tot_detrazione_prec   > 0
      or w_tot_detrazione_prec_d > 0 then
         FOR rec_ogim IN sel_ogim (rec_cf.cod_fiscale
                                  ,a_anno
                                  ,w_flag_pertinenze
                                  ,a_ravvedimento
                                  ,a_tipo_evento
                                  )
         LOOP
            --
            -- (VD - 18/01/2017): aggiunta greatest tra 0 e imposta a saldo
            --                    per evitare problemi in caso di imposta
            --                    acconto > imposta dovuta (con conseguente
            --                    differenza negativa)
            --
            --w_detrazione             := least(nvl(rec_ogim.imposta,0) - nvl(rec_ogim.imposta_acconto,0)
            --                                 ,nvl(w_tot_detrazione,0)
            --                                 );
            --w_detrazione_d           := least(nvl(rec_ogim.imposta_dovuta,0) - nvl(rec_ogim.imposta_dovuta_acconto,0)
            --                                 ,nvl(w_tot_detrazione_d,0)
            --                                 );
            w_detrazione             := least(greatest(nvl(rec_ogim.imposta,0) - nvl(rec_ogim.imposta_acconto,0),0)
                                             ,nvl(w_tot_detrazione,0)
                                             );
            w_detrazione_d           := least(greatest(nvl(rec_ogim.imposta_dovuta,0) - nvl(rec_ogim.imposta_dovuta_acconto,0),0)
                                             ,nvl(w_tot_detrazione_d,0)
                                             );
            w_detrazione_acconto     := least(nvl(rec_ogim.imposta_acconto,0)
                                             ,nvl(w_tot_detrazione_prec,0)
                                             ,w_detrazione
                                             );
            w_detrazione_acconto_d   := least(nvl(rec_ogim.imposta_dovuta_acconto,0)
                                             ,nvl(w_tot_detrazione_prec_d,0)
                                             ,w_detrazione_d
                                             );
            w_tot_detrazione         := w_tot_detrazione        - w_detrazione;
            w_tot_detrazione_d       := w_tot_detrazione_d      - w_detrazione_d;
            w_tot_detrazione_prec    := w_tot_detrazione_prec   - w_detrazione_acconto;
            w_tot_detrazione_prec_d  := w_tot_detrazione_prec_d - w_detrazione_acconto_d;
            update oggetti_imposta
               set detrazione             = decode(nvl(detrazione,0) + w_detrazione
                                                  ,0,to_number(null)
                                                    ,nvl(detrazione,0) + w_detrazione
                                                  )
                  ,detrazione_acconto     = decode(nvl(detrazione_acconto,0) + w_detrazione_acconto
                                                  ,0,to_number(null)
                                                    ,nvl(detrazione_acconto,0) + w_detrazione_acconto
                                                  )
                  ,imposta                = imposta - w_detrazione
                  ,imposta_dovuta         = nvl(imposta_dovuta,0) - nvl(w_detrazione_d,0)
                  ,imposta_acconto        = nvl(imposta_acconto,0) - nvl(w_detrazione_acconto,0)
                  ,imposta_dovuta_acconto = nvl(imposta_dovuta_acconto,0) - nvl(w_detrazione_acconto_d,0)
                  ,wrk_calcolo            = 'ID'
             where oggetto_imposta        = rec_ogim.oggetto_imposta
            ;
         END LOOP;
      end if;
   END LOOP;
EXCEPTION
   WHEN FINE THEN null;
   WHEN ERRORE THEN
      ROLLBACK;
      RAISE_APPLICATION_ERROR(-20999,w_errore,true);
   WHEN OTHERS THEN
      ROLLBACK;
      RAISE_APPLICATION_ERROR(-20999,'Errore in Calcolo Detrazioni ICI di '||w_cod_fiscale||' ('||SQLERRM||')');
END;
/* End Procedure: CALCOLO_DETRAZIONI_ICI */
/

