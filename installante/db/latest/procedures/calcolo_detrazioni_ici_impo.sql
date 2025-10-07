--liquibase formatted sql 
--changeset abrandolini:20250326_152423_calcolo_detrazioni_ici_impo stripComments:false runOnChange:true 
 
create or replace procedure CALCOLO_DETRAZIONI_ICI_IMPO
(a_cf           IN varchar2
,a_anno         IN number
,a_ravvedimento IN varchar2
,a_utente       IN varchar2
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
w_tot_detrazione_d_prec             number;
w_detr                              number;
w_detr_acc                          number;
w_detrazione                        number;
w_detrazione_acconto                number;
w_detrazione_d                      number;
w_detrazione_d_acconto              number;
w_maggiore_detrazione               number;
w_maggiore_detrazione_acconto       number;
w_maggiore_detrazione_prec          number;
w_detrazione_ogco                   number;
w_detrazione_acconto_ogco           number;
w_anno_prec                         number;
w_mesi_possesso_prec                number;
w_den_detraz                        number;
w_loop                              number;
w_cod_fiscale                       varchar2(16);
w_detr_aliquota                     number;
w_detr_imponibile_max               number;
w_detr_flag_pertinenze              varchar2(1);
w_ind                               number;
w_imponibile                        number;
w_imponibile_prec                   number;
w_imponibile_d                      number;
w_imponibile_d_prec                 number;
w_oggetto_pratica                   number;
w_oggetto_pratica_prec              number;
w_presenza_A                        varchar2(1);
w_presenza_A_prec                   varchar2(1);
w_flag_riog                         varchar2(1);
w_flag_riog_prec                    varchar2(1);
w_detrazione_denuncia               number;
w_detrazione_denuncia_prec          number;
w_detrazione_deim                   number;
w_detrazione_deim_acconto           number;
w_detrazione_deim_d                 number;
w_detrazione_deim_d_acconto         number;
w_da_mese                           number;
w_a_mese                            number;
w_perc_detrazione                   number;
w_mesi_pos                          number;
w_mesi_pos_1sem                     number;
w_detraz_base_denuncia              number;
w_sum_detrazione_deim               number;
w_sum_detrazione_deim_acconto       number;
w_test                              number  := 0;
w_test2                             number  := 0;
w_imposta_spet                      number;
w_imposta_dovuta_spet               number;
w_imposta_acconto_spet              number;
w_imposta_dovuta_acconto_spet       number;
w_mesi_possesso_ogim                number;
w_mesi_possesso_1sem_ogim           number;
w_flag_detrazione_possesso          varchar2(1);
w_perc_possesso_ogco                number;
w_perc_possesso_ogco_prec           number;
--
-- Selezione dei contribuenti su cui e` stata calcolata l`imposta ICI.
-- (sono quelli che hanno la data di sistema nella data di variazione
-- sugli oggetti imposta.
--
cursor sel_cf (p_cf                     varchar2
              ,p_anno                   number
              ,p_ravvedimento           varchar2
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
   and (    p_ravvedimento         =    'S'
        and prtr.tipo_pratica      =    'V'
        or  p_ravvedimento         =    'N'
        and prtr.tipo_pratica     in    ('D','A')
       )
        and   F_DATO_RIOG(ogim.cod_fiscale
                       ,ogim.oggetto_pratica
                       ,ogim.anno
                       ,'CA'
                       )        in ('A02','A03','A04','A05','A06','A07','A10','A11')
 group by
       ogco.cod_fiscale
 order by
       ogco.cod_fiscale
;
--
-- Dato un Contribuente, si inserisco le Detrazioni Imponibile .
--
cursor sel_ogco (p_cf                   varchar2
                ,p_anno                 number
                ,p_detr_flag_pertinenze varchar2
                ,p_ravvedimento         varchar2
                ,p_mese                 number
                )
is
         select ogim.oggetto_pratica                                            oggetto_pratica
               ,peim.imponibile                                                 imponibile
               ,peim.imponibile_d                                               imponibile_d
               ,peim.flag_riog                                                  flag_riog
               ,F_DATO_RIOG(ogim.cod_fiscale
                               ,ogim.oggetto_pratica
                               ,ogim.anno
                               ,'CA'
                               )                                                categoria_catasto
               ,round(decode(nvl(ogco.mesi_possesso,12)
                            ,0,0
                            ,nvl(ogco.detrazione,0)
                             / nvl(ogco.mesi_possesso,12) * 12
                            ),2)                                                detrazione
               ,ogco.anno                                                       anno
               ,ogco.perc_possesso                                              perc_possesso
           from oggetti_contribuente        ogco
               ,oggetti_pratica             ogpr
               ,pratiche_tributo            prtr
               ,oggetti                     ogge
               ,oggetti_imposta             ogim
               ,periodi_imponibile          peim
          where ogco.cod_fiscale               =    ogim.cod_fiscale
            and ogco.oggetto_pratica           =    ogim.oggetto_pratica
            and ogpr.oggetto_pratica           =    ogim.oggetto_pratica
            and prtr.pratica                   =    ogpr.pratica
            and prtr.tipo_tributo||''          =    'ICI'
            and nvl(prtr.stato_accertamento,'D') = 'D'
            and ogge.oggetto                   =    ogpr.oggetto
            and ogim.cod_fiscale               =    p_cf
            and ogim.anno                      =    p_anno
            and ogge.oggetto                   =    ogpr.oggetto
            and ogim.cod_fiscale               =    peim.cod_fiscale
            and ogim.anno                      =    peim.anno
            and ogim.oggetto_pratica           =    peim.oggetto_pratica
            and p_mese                   between    peim.da_mese and peim.a_mese
            and ogim.ruolo                    is    null
            and  (    ogco.flag_ab_principale   =    'S'
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
            and trunc(ogim.data_variazione)    =    trunc(sysdate)
            and (    p_ravvedimento            =    'S'
               and prtr.tipo_pratica         =    'V'
               or  p_ravvedimento            =    'N'
               and prtr.tipo_pratica         in    ('D','A')
                )
            and (    p_detr_flag_pertinenze    = 'S'
                and F_DATO_RIOG(ogim.cod_fiscale
                               ,ogim.oggetto_pratica
                               ,ogim.anno
                               ,'CA'
                               )           like 'C%'
                or  F_DATO_RIOG(ogim.cod_fiscale
                               ,ogim.oggetto_pratica
                               ,ogim.anno
                               ,'CA'
                               )           in ('A02','A03','A04','A05','A06','A07','A10','A11')
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
                               and ogpr2.oggetto_pratica = ogco.oggetto_pratica
                               and deog2.tipo_tributo    = 'ICI'
                            )
            order by
             ogco.oggetto_pratica
                ;
cursor sel_deim (p_cf                   varchar2
                ,p_anno                 number
                ,p_flag_pertinenze      varchar2
                ,p_ravvedimento         varchar2
                )
             is
         select ogim.oggetto_pratica                                            oggetto_pratica
               ,deim.detrazione                                                 detrazione
               ,deim.detrazione_acconto                                         detrazione_acconto
               ,deim.detrazione_d                                               detrazione_d
               ,deim.detrazione_d_acconto                                       detrazione_d_acconto
               ,ogim.oggetto_imposta                                            oggetto_imposta
               ,deim.a_mese - deim.da_mese + 1                                  mesi_possesso
               ,decode(sign(deim.da_mese - 6)
                      ,1,0
                      ,decode(sign(deim.a_mese - 6)
                             ,1,6
                             ,deim.a_mese
                             )
                       - deim.da_mese + 1
                      )                                                         mesi_possesso_1sem
               ,deim.da_mese                                                    da_mese
               ,deim.a_mese                                                     a_mese
               ,deim.perc_detrazione                                            perc_detrazione
               ,deim.detrazione_rimanente                                       detrazione_rimanente
               ,deim.detrazione_rimanente_acconto                               detrazione_rimanente_acconto
               ,deim.detrazione_rimanente_d                                     detrazione_rimanente_d
               ,deim.detrazione_rimanente_d_acconto                             detrazione_rimanente_d_acconto
               ,ogim.imposta                                                    imposta
               ,ogim.imposta_dovuta                                             imposta_dovuta
               ,ogim.imposta_acconto                                            imposta_acconto
               ,ogim.imposta_dovuta_acconto                                     imposta_dovuta_acconto
           from oggetti_imposta             ogim
               ,detrazioni_imponibile       deim
               ,oggetti_pratica             ogpr
               ,pratiche_tributo            prtr
          where deim.cod_fiscale               =    p_cf
            and deim.anno                      =    p_anno
            and ogim.cod_fiscale               =    deim.cod_fiscale
            and ogim.anno                      =    deim.anno
            and ogim.oggetto_pratica           =    deim.oggetto_pratica
            and ogim.ruolo                    is    null
            and ogim.flag_calcolo              =    'S'
            and ogpr.oggetto_pratica           =    ogim.oggetto_pratica
            and prtr.pratica                   =    ogpr.pratica
            and prtr.tipo_tributo||''          =    'ICI'
            and (    p_ravvedimento            =    'S'
                 and prtr.tipo_pratica         =    'V'
                  or  p_ravvedimento           =    'N'
                 and prtr.tipo_pratica        in    ('D','A')
                )
            and (    p_flag_pertinenze    = 'S'
                and F_DATO_RIOG(ogim.cod_fiscale
                               ,ogim.oggetto_pratica
                               ,ogim.anno
                               ,'CA'
                               )           like 'C%'
                or  F_DATO_RIOG(ogim.cod_fiscale
                               ,ogim.oggetto_pratica
                               ,ogim.anno
                               ,'CA'
                               )           in ('A02','A03','A04','A05','A06','A07','A10','A11')
                )
       order by ogim.oggetto_pratica
              , deim.da_mese
                ;
--
-- Determinazione degli oggetti soggetti a detrazione sui quali spalmare
-- la eventuale detrazione rimasta
--
cursor sel_ogim (p_cf              varchar2
                ,p_anno            number
                ,p_flag_pertinenze varchar2
                ,p_ravvedimento    varchar2
                )
is
select ogco.oggetto_pratica                 oggetto_pratica
      ,ogpr.oggetto                         oggetto
      ,ogco.anno                            anno
      ,ogim.oggetto_imposta                 oggetto_imposta
      ,ogim.imposta                         imposta
      ,ogim.imposta_dovuta                  imposta_dovuta
      ,ogim.imposta_acconto                 imposta_acconto
      ,ogim.imposta_dovuta_acconto          imposta_dovuta_acconto
      ,ogpr.oggetto_pratica_rif_ap          oggetto_pratica_rif_ap
      , F_DATO_RIOG(ogim.cod_fiscale
                   ,ogim.oggetto_pratica
                   ,ogim.anno
                   ,'CA'
                   )                        categoria_catasto
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
   and ogim.flag_calcolo              =    'S'
   and trunc(ogim.data_variazione)    =    trunc(sysdate)
   and (    p_ravvedimento            =    'S'
        and prtr.tipo_pratica         =    'V'
        or  p_ravvedimento            =    'N'
        and prtr.tipo_pratica       in    ('D','A')
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
                       )            in ('A02','A03','A04','A05','A06','A07','A10','A11')
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
 order by
       decode(ogpr.oggetto_pratica_rif_ap,null,2,1)
      ,F_DATO_RIOG(ogim.cod_fiscale
                       ,ogim.oggetto_pratica
                       ,ogim.anno
                       ,'CA'
                       )
      ,ogco.oggetto_pratica
;
cursor sel_peim (p_cf              varchar2
                ,p_anno            number
                ,p_oggetto_pratica number
                )
is
select peim.da_mese                                             da_mese_peim
     , peim.a_mese                                              a_mese_peim
     , peim.a_mese - peim.da_mese + 1                           mesi_possesso_peim
     , decode(sign(peim.da_mese - 6)
             ,1,0
             ,decode(sign(peim.a_mese - 6)
                    ,1,6
                    ,peim.a_mese
                    )
               - peim.da_mese + 1
              )                                                 mesi_possesso_1sem_peim
     , deim.oggetto_pratica                                     oggetto_pratica_deim
     , deim.da_mese                                             da_mese_deim
     , deim.a_mese                                              a_mese_deim
     , deim.a_mese - deim.da_mese + 1                           mesi_possesso_deim
     , decode(sign(deim.da_mese - 6)
             ,1,0
             ,decode(sign(deim.a_mese - 6)
                    ,1,6
                    ,deim.a_mese
                    )
               - deim.da_mese + 1
              )                                                 mesi_possesso_1sem_deim
  from detrazioni_imponibile  deim
     , periodi_imponibile     peim
 where peim.cod_fiscale     = p_cf
   and peim.anno            = p_anno
   and peim.oggetto_pratica = p_oggetto_pratica
   and deim.cod_fiscale     = peim.cod_fiscale
   and deim.anno            = peim.anno
   and (  peim.da_mese between deim.da_mese and deim.a_mese
       or peim.a_mese  between deim.da_mese and deim.a_mese
       )
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
-- Determinazione della Massima Detrazione Imponibile dell`anno di imposta.
--
   BEGIN
      select nvl(detrazione_base,0)
            ,aliquota
            ,nvl(detrazione_imponibile,0)
            ,flag_pertinenze
        into w_detraz_base
            ,w_detr_aliquota
            ,w_detr_imponibile_max
            ,w_detr_flag_pertinenze
        from detrazioni
       where anno     = a_anno
         and tipo_tributo = 'ICI'
      ;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         w_detr_aliquota        := 0;
         w_detr_imponibile_max  := 0;
         w_detr_flag_pertinenze := 'N';
         w_detraz_base          := 0;
   END;
--
-- Trattamento Contribuenti.
--
   FOR rec_cf IN sel_cf (a_cf,a_anno,a_ravvedimento)
   LOOP
      w_cod_fiscale := rec_cf.cod_fiscale;
      w_tot_detrazione           := 0;
      w_tot_detrazione_prec      := 0;
      --w_detrazione_impo          := 0;
      --w_detrazione_impo_acconto  := 0;
      w_detrazione_denuncia      := 0;
      w_detrazione_denuncia_prec := 0;
      w_ind                      := 0;
      w_imponibile           := 0;
      w_imponibile_prec      := -9999999999;
      w_oggetto_pratica      := 0;
      w_oggetto_pratica_prec := 0;
      w_presenza_A           := 'N';
      w_presenza_A_prec      := 'N';
      w_flag_riog            := null;
      w_flag_riog_prec       := null;
      BEGIN
         select nvl(detrazione_base,detrazione)
              , detrazione_acconto
              , flag_detrazione_possesso
           into w_maggiore_detrazione
              , w_maggiore_detrazione_acconto
              , w_flag_detrazione_possesso
           from maggiori_detrazioni
          where cod_fiscale       = rec_cf.cod_fiscale
            and anno              = a_anno
            and tipo_tributo      = 'ICI'
         ;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            w_maggiore_detrazione         := null;
            w_maggiore_detrazione_acconto := null;
            w_flag_detrazione_possesso    := null;
      END;
      LOOP
         w_ind := w_ind + 1;
         if w_ind > 12 then
            exit;
         end if;
         w_imponibile           := 0;
         w_imponibile_d         := 0;
         w_presenza_A           := 'N';
         w_flag_riog            := null;
         w_oggetto_pratica      := 0;
         FOR rec_ogco IN sel_ogco (rec_cf.cod_fiscale
                                  ,a_anno
                                  ,w_detr_flag_pertinenze
                                  ,a_ravvedimento
                                  ,w_ind
                                  )
         LOOP
            w_imponibile   := w_imponibile + rec_ogco.imponibile;
            w_imponibile_d := w_imponibile_d + rec_ogco.imponibile_d;
            if substr(rec_ogco.categoria_catasto,1,1) = 'A' then
               w_presenza_A          := 'S';
               w_oggetto_pratica     := rec_ogco.oggetto_pratica;
               w_flag_riog           := rec_ogco.flag_riog;
               w_perc_possesso_ogco  := rec_ogco.perc_possesso;
               if w_maggiore_detrazione is null then
               --
               -- Determinazione della Detrazione Base dell`anno di denuncia.
               --
                  BEGIN
                     select nvl(detrazione_base,0)
                       into w_detraz_base_denuncia
                       from detrazioni
                      where anno     = rec_ogco.anno
                        and tipo_tributo = 'ICI'
                          ;
                  EXCEPTION
                     WHEN NO_DATA_FOUND THEN
                        w_detraz_base_denuncia  := 0;
                  END;
                  w_detrazione_denuncia := round(rec_ogco.detrazione / w_detraz_base_denuncia * w_detraz_base,2);
               else
                  w_detrazione_denuncia := w_maggiore_detrazione;
               end if;
            end if;
         END LOOP;
         if w_ind = 1 or (w_presenza_A = 'S' and  w_presenza_A_prec <> 'S') then
            w_da_mese       := w_ind;
         end if;
         if w_presenza_A_prec = 'S' then
               if w_imponibile <> w_imponibile_prec or w_oggetto_pratica <> w_oggetto_pratica_prec then
                  w_a_mese := w_ind - 1;
                  if w_flag_detrazione_possesso is null then
                     if w_detraz_base = 0 then
                        w_perc_detrazione := 0;
                     else
                        w_perc_detrazione := least(round(w_detrazione_denuncia_prec / w_detraz_base * 100,2)
                                                  ,100);
                     end if;
                  else
                     w_perc_detrazione := w_perc_possesso_ogco_prec;
                  end if;
                  w_mesi_pos      := w_a_mese - w_da_mese + 1;
                  if w_da_mese > 6 then
                     w_mesi_pos_1sem := 0;
                  else
                     if w_a_mese > 6 then
                        w_mesi_pos_1sem := 6 - w_da_mese + 1;
                     else
                        w_mesi_pos_1sem := w_a_mese - w_da_mese + 1;
                     end if;
                  end if;
                  w_detrazione_deim := round(w_imponibile_prec
                                             * w_detr_aliquota
                                             / 1000
                                             * w_perc_detrazione
                                             /100
                                             / 12 * w_mesi_pos
                                            , 2);
                  w_detrazione_deim_acconto := round(w_imponibile_prec
                                                     * w_detr_aliquota
                                                     / 1000
                                                     * w_perc_detrazione
                                                     / 100
                                                     / 12 * w_mesi_pos_1sem
                                                    ,2);
                  w_detrazione_deim_d := round(w_imponibile_d_prec
                                               * w_detr_aliquota
                                               / 1000
                                               * w_perc_detrazione
                                               /100
                                               / 12 * w_mesi_pos
                                              , 2);
                  w_detrazione_deim_d_acconto := round(w_imponibile_d_prec
                                                       * w_detr_aliquota
                                                       / 1000
                                                       * w_perc_detrazione
                                                       / 100
                                                       / 12 * w_mesi_pos_1sem
                                                      ,2);
                  w_tot_detrazione         := least(round(w_detr_imponibile_max
                                                          / 12 * w_mesi_pos
                                                          * w_perc_detrazione / 100
                                                         ,2)
                                                   ,nvl(w_detrazione_deim,0)
                                                    );
                  w_tot_detrazione_prec    := least(round(w_detr_imponibile_max
                                                          / 12 * w_mesi_pos_1sem
                                                          * w_perc_detrazione / 100
                                                         ,2)
                                                   ,nvl(w_detrazione_deim_acconto,0)
                                                   );
                  w_tot_detrazione_d       := least(round(w_detr_imponibile_max
                                                          / 12 * w_mesi_pos
                                                          * w_perc_detrazione / 100
                                                         ,2)
                                                   ,nvl(w_detrazione_deim_d,0)
                                                   );
                  w_tot_detrazione_d_prec  := least(round(w_detr_imponibile_max
                                                          / 12 * w_mesi_pos_1sem
                                                          * w_perc_detrazione / 100
                                                         ,2)
                                                   ,nvl(w_detrazione_deim_d_acconto,0)
                                                   );
                  BEGIN
                     insert into detrazioni_imponibile
                             ( cod_fiscale, anno, oggetto_pratica
                             , da_mese, a_mese ,imponibile, flag_riog, utente
                             , perc_detrazione, detrazione, detrazione_acconto
                             , imponibile_d, detrazione_d, detrazione_d_acconto
                             , detrazione_rimanente, detrazione_rimanente_acconto
                             , detrazione_rimanente_d, detrazione_rimanente_d_acconto)
                      values ( w_cod_fiscale, a_anno, w_oggetto_pratica_prec
                             , w_da_mese, w_a_mese, w_imponibile_prec, w_flag_riog_prec, a_utente
                             , w_perc_detrazione, w_detrazione_deim, w_detrazione_deim_acconto
                             , w_imponibile_d_prec ,w_detrazione_deim_d, w_detrazione_deim_d_acconto
                             , w_tot_detrazione, w_tot_detrazione_prec
                             , w_tot_detrazione_d, w_tot_detrazione_d_prec)
                           ;
                  EXCEPTION
                     WHEN others THEN
                        w_errore := 'Errore in ins. Detrazione Imponibile di '||w_cod_fiscale||
                                    ' Anno '||to_char(a_anno)||
                                    ' Oggetto Pratica '||to_char(w_oggetto_pratica_prec)||
                                    ' da mese '||to_char(w_da_mese)||
                                    ' w_ind '||to_char(w_ind);
                     RAISE errore;
                  END;
                  w_da_mese       := w_ind;
               end if;
         end if;
         if w_presenza_A = 'S' then
            if w_ind = 12 then
               w_a_mese := w_ind;
               if w_flag_detrazione_possesso is null then
                  if w_detraz_base = 0 then
                     w_perc_detrazione := 0;
                  else
                     w_perc_detrazione := least(round(w_detrazione_denuncia / w_detraz_base * 100,2)
                                               ,100);
                  end if;
               else
                  w_perc_detrazione := w_perc_possesso_ogco;
               end if;
               w_mesi_pos      := w_a_mese - w_da_mese + 1;
               if w_da_mese > 6 then
                  w_mesi_pos_1sem := 0;
               else
                  if w_a_mese > 6 then
                     w_mesi_pos_1sem := 6 - w_da_mese + 1;
                  else
                     w_mesi_pos_1sem := w_a_mese - w_da_mese + 1;
                  end if;
               end if;
               w_detrazione_deim := round(w_imponibile
                                          * w_detr_aliquota
                                          / 1000
                                          * w_perc_detrazione
                                          / 100
                                          / 12 * w_mesi_pos
                                         , 2);
               w_detrazione_deim_acconto := round(w_imponibile
                                                  * w_detr_aliquota
                                                  / 1000
                                                  * w_perc_detrazione
                                                  / 100
                                                  / 12 * w_mesi_pos_1sem
                                                 ,2);
                  w_detrazione_deim_d := round(w_imponibile_d
                                               * w_detr_aliquota
                                               / 1000
                                               * w_perc_detrazione
                                               /100
                                               / 12 * w_mesi_pos
                                              , 2);
                  w_detrazione_deim_d_acconto := round(w_imponibile_d
                                                       * w_detr_aliquota
                                                       / 1000
                                                       * w_perc_detrazione
                                                       / 100
                                                       / 12 * w_mesi_pos_1sem
                                                      ,2);
                  w_tot_detrazione         := least(round(w_detr_imponibile_max
                                                          / 12 * w_mesi_pos
                                                          * w_perc_detrazione / 100
                                                         ,2)
                                                   ,nvl(w_detrazione_deim,0)
                                                    );
                  w_tot_detrazione_prec    := least(round(w_detr_imponibile_max
                                                          / 12 * w_mesi_pos_1sem
                                                          * w_perc_detrazione / 100
                                                         ,2)
                                                   ,nvl(w_detrazione_deim_acconto,0)
                                                   );
                  w_tot_detrazione_d       := least(round(w_detr_imponibile_max / 12 * w_mesi_pos
                                                          * w_perc_detrazione / 100
                                                         ,2)
                                                   ,nvl(w_detrazione_deim_d,0)
                                                   );
                  w_tot_detrazione_d_prec  := least(round(w_detr_imponibile_max
                                                          / 12 * w_mesi_pos_1sem
                                                          * w_perc_detrazione / 100
                                                         ,2)
                                                   ,nvl(w_detrazione_deim_d_acconto,0)
                                                   );
               BEGIN
                  insert into detrazioni_imponibile
                          ( cod_fiscale,anno,oggetto_pratica
                          , da_mese, a_mese ,imponibile, flag_riog, utente
                          , perc_detrazione, detrazione, detrazione_acconto
                          , imponibile_d, detrazione_d, detrazione_d_acconto
                          , detrazione_rimanente, detrazione_rimanente_acconto
                          , detrazione_rimanente_d, detrazione_rimanente_d_acconto)
                   values ( w_cod_fiscale,a_anno,w_oggetto_pratica
                          , w_da_mese, w_a_mese, w_imponibile, w_flag_riog, a_utente
                          , w_perc_detrazione, w_detrazione_deim, w_detrazione_deim_acconto
                          , w_imponibile_d_prec, w_detrazione_deim_d, w_detrazione_deim_d_acconto
                          , w_tot_detrazione, w_tot_detrazione_prec
                          , w_tot_detrazione_d, w_tot_detrazione_d_prec)
                         ;
               EXCEPTION
                   WHEN others THEN
                      w_errore := 'Errore in ins. Detrazioni Imponibile di '||w_cod_fiscale||
                                  ' Anno '||to_char(a_anno)||
                                  ' Oggetto Pratica '||to_char(w_oggetto_pratica)||
                                  ' da mese '||to_char(w_da_mese)||
                                  ' w_ind '||to_char(w_ind);
               END;
            end if;
         end if;
         w_oggetto_pratica_prec     := w_oggetto_pratica;
         w_presenza_A_prec          := w_presenza_A;
         w_imponibile_prec          := w_imponibile;
         w_imponibile_d_prec        := w_imponibile_d;
         w_detrazione_denuncia_prec := w_detrazione_denuncia;
         w_perc_possesso_ogco_prec  := w_perc_possesso_ogco;
      END LOOP;
     --
     -- Inizio assegnazione della detrazione  agli oggetti A% per quanto
     -- indicato nelle detrazioni_imponibile
     --
      w_imposta_spet                := 0;
      w_imposta_dovuta_spet         := 0;
      w_imposta_acconto_spet        := 0;
      w_imposta_dovuta_acconto_spet := 0;
      FOR rec_deim IN sel_deim (rec_cf.cod_fiscale
                               ,a_anno
                               ,w_flag_pertinenze
                               ,a_ravvedimento
                               )
      LOOP
            begin
               select max(peim.a_mese) - min(peim.da_mese) + 1                  mesi_possesso
                    , decode(sign(min(peim.da_mese) - 6)
                            ,1,0
                            ,decode(sign(max(peim.a_mese) - 6)
                                   ,1,6
                                   ,max(peim.a_mese)
                                   )
                             - min(peim.da_mese) + 1
                            )                                                   mesi_possesso_1sem
                 into w_mesi_possesso_ogim
                    , w_mesi_possesso_1sem_ogim
                 from periodi_imponibile peim
                where peim.cod_fiscale     = rec_cf.cod_fiscale
                  and peim.anno            = a_anno
                  and peim.oggetto_pratica = rec_deim.oggetto_pratica
             group by peim.cod_fiscale
                    , peim.anno
                    , peim.oggetto_pratica
                    ;
            EXCEPTION
                   WHEN others THEN
                      w_errore := 'Errore mesi possesso PEIM  (A%)'||
                                  ' cod_fiscale '||rec_cf.cod_fiscale||
                                  ' anno '||to_char(a_anno)||
                                  ' oggetto_pratica '||to_char(rec_deim.oggetto_pratica);
            end;
               w_imposta_spet                := round(nvl(rec_deim.imposta,0)
                                                      / w_mesi_possesso_ogim
                                                      * rec_deim.mesi_possesso
                                                     ,2);
               w_imposta_dovuta_spet         := round(nvl(rec_deim.imposta_dovuta,0)
                                                      / w_mesi_possesso_ogim
                                                      * rec_deim.mesi_possesso
                                                     ,2);
               if w_mesi_possesso_1sem_ogim = 0 then
                  w_imposta_acconto_spet        := 0;
                  w_imposta_dovuta_acconto_spet := 0;
               else
                  w_imposta_acconto_spet        := round(nvl(rec_deim.imposta_acconto,0)
                                                         / w_mesi_possesso_1sem_ogim
                                                         * rec_deim.mesi_possesso_1sem
                                                        ,2);
                  w_imposta_dovuta_acconto_spet := round(nvl(rec_deim.imposta_dovuta_acconto,0)
                                                         / w_mesi_possesso_1sem_ogim
                                                         * rec_deim.mesi_possesso_1sem
                                                        ,2);
               end if;
            w_detrazione             := least(w_imposta_spet
                                             ,rec_deim.detrazione_rimanente
                                             );
            w_detrazione_d           := least(w_imposta_dovuta_spet
                                             ,rec_deim.detrazione_rimanente_d
                                             );
            w_detrazione_acconto     := least(w_imposta_acconto_spet
                                             ,rec_deim.detrazione_rimanente_acconto
                                             );
            w_detrazione_d_acconto   := least(w_imposta_dovuta_acconto_spet
                                             ,rec_deim.detrazione_rimanente_d_acconto
                                             );
               w_test := w_test + 1;
            --   if w_test = 3 then
            --     w_errore := w_imposta_spet;
            --     raise errore;
            --   end if;
            begin
               update detrazioni_imponibile
                  set detrazione_rimanente            = detrazione_rimanente - w_detrazione
                    , detrazione_rimanente_acconto    = detrazione_rimanente_acconto - w_detrazione_acconto
                    , detrazione_rimanente_d          = detrazione_rimanente_d - w_detrazione_d
                    , detrazione_rimanente_d_acconto  = detrazione_rimanente_d_acconto - w_detrazione_d_acconto
                where oggetto_pratica        = rec_deim.oggetto_pratica
                  and anno                   = a_anno
                  and cod_fiscale            = rec_cf.cod_fiscale
                  and da_mese                = rec_deim.da_mese
                    ;
            EXCEPTION
                   WHEN others THEN
                      w_errore := 'Errore in agg. Detrazioni Imponibile '||w_cod_fiscale||
                                  ' oggetto pratica '||to_char(rec_deim.oggetto_imposta)||
                                  ' anno '||to_char(a_anno)||
                                  ' da_mese '||to_char(rec_deim.da_mese);
            end;
            begin
               update oggetti_imposta
                  set detrazione_imponibile  = decode(nvl(detrazione_imponibile,0) + w_detrazione
                                                     ,0,to_number(null)
                                                       ,nvl(detrazione_imponibile,0) + w_detrazione
                                                     )
                     ,detrazione_imponibile_acconto = decode(nvl(detrazione_imponibile_acconto,0) + w_detrazione_acconto
                                                             ,0,to_number(null)
                                                             ,nvl(detrazione_imponibile_acconto,0) + w_detrazione_acconto
                                                             )
                     ,detrazione_imponibile_d  = decode(nvl(detrazione_imponibile_d,0) + w_detrazione_d
                                                       ,0,to_number(null)
                                                       ,nvl(detrazione_imponibile_d,0) + w_detrazione_d
                                                       )
                     ,detrazione_imponibile_d_acc = decode(nvl(detrazione_imponibile_d_acc,0) + w_detrazione_d_acconto
                                                          ,0,to_number(null)
                                                          ,nvl(detrazione_imponibile_d_acc,0) + w_detrazione_d_acconto
                                                          )
                     ,imposta                = imposta - w_detrazione
                     ,imposta_dovuta         = imposta_dovuta - nvl(w_detrazione_d,0)
                     ,imposta_acconto        = imposta_acconto - nvl(w_detrazione_acconto,0)
                     ,imposta_dovuta_acconto = imposta_dovuta_acconto - nvl(w_detrazione_d_acconto,0)
                where oggetto_imposta        = rec_deim.oggetto_imposta
                    ;
            EXCEPTION
                   WHEN others THEN
                      w_errore := 'Errore in agg. Oggetti_imposta '||w_cod_fiscale||
                                  ' oggetto imposta '||to_char(rec_deim.oggetto_imposta)||
                                  ' imposta  '||to_char(nvl(rec_deim.imposta,0) - w_detrazione)||
                                  ' imposta dovuta  '||to_char(nvl(rec_deim.imposta_dovuta,0) - w_detrazione_d);
            end;
      END LOOP;
--
-- Trattamento di eventuali Residui di Detrazione.
--
      FOR rec_ogim IN sel_ogim (rec_cf.cod_fiscale
                               ,a_anno
                               ,w_flag_pertinenze
                               ,a_ravvedimento
                               )
      LOOP
         if substr(rec_ogim.categoria_catasto,1,1) <> 'A' then
            FOR rec_peim IN sel_peim (rec_cf.cod_fiscale
                                     ,a_anno
                                     ,rec_ogim.oggetto_pratica
                                     )
            LOOP
                  w_imposta_spet                := round(nvl(rec_ogim.imposta,0)
                                                         / rec_peim.mesi_possesso_peim
                                                         * rec_peim.mesi_possesso_deim
                                                        ,2);
                  w_imposta_dovuta_spet         := round(nvl(rec_ogim.imposta_dovuta,0)
                                                         / rec_peim.mesi_possesso_peim
                                                         * rec_peim.mesi_possesso_deim
                                                        ,2);
                  if rec_peim.mesi_possesso_1sem_peim = 0 then
                     w_imposta_acconto_spet        := 0;
                     w_imposta_dovuta_acconto_spet := 0;
                  else
                     w_imposta_acconto_spet        := round(nvl(rec_ogim.imposta_acconto,0)
                                                            / rec_peim.mesi_possesso_1sem_peim
                                                            * rec_peim.mesi_possesso_1sem_deim
                                                           ,2);
                     w_imposta_dovuta_acconto_spet := round(nvl(rec_ogim.imposta_dovuta_acconto,0)
                                                            / rec_peim.mesi_possesso_1sem_peim
                                                            * rec_peim.mesi_possesso_1sem_deim
                                                           ,2);
                  end if;
                  w_test2 := w_test2 + 1;
                --  if w_test2 = 2 then
                --    w_errore := nvl(rec_peim.detrazione_rimanente,0);
                --    raise errore;
                --  end if;
                  select least(w_imposta_spet
                              ,nvl(deim.detrazione_rimanente,0)
                              )
                       , least(w_imposta_dovuta_spet
                              ,nvl(deim.detrazione_rimanente_d,0)
                              )
                       , least(w_imposta_acconto_spet
                              ,nvl(deim.detrazione_rimanente_acconto,0)
                              )
                       , least(w_imposta_dovuta_acconto_spet
                              ,nvl(deim.detrazione_rimanente_d_acconto,0)
                              )
                    into w_detrazione
                       , w_detrazione_d
                       , w_detrazione_acconto
                       , w_detrazione_d_acconto
                    from detrazioni_imponibile deim
                   where deim.cod_fiscale     = rec_cf.cod_fiscale
                     and deim.anno            = a_anno
                     and deim.oggetto_pratica = rec_peim.oggetto_pratica_deim
                     and deim.da_mese         = rec_peim.da_mese_deim
                       ;
                  begin
                     update detrazioni_imponibile
                        set detrazione_rimanente            = detrazione_rimanente - w_detrazione
                          , detrazione_rimanente_acconto    = detrazione_rimanente_acconto - w_detrazione_acconto
                          , detrazione_rimanente_d          = detrazione_rimanente_d - w_detrazione_d
                          , detrazione_rimanente_d_acconto  = detrazione_rimanente_d_acconto - w_detrazione_d_acconto
                      where oggetto_pratica        = rec_peim.oggetto_pratica_deim
                        and anno                   = a_anno
                        and cod_fiscale            = rec_cf.cod_fiscale
                        and da_mese                = rec_peim.da_mese_deim
                          ;
                  EXCEPTION
                       WHEN others THEN
                      w_errore := 'Errore in agg. Detrazioni Imponibile '||w_cod_fiscale||
                                  ' oggetto pratica '||to_char(rec_peim.oggetto_pratica_deim)||
                                  ' anno '||to_char(a_anno)||
                                  ' da_mese '||to_char(rec_peim.da_mese_deim);
                  end;
                  update oggetti_imposta
                     set detrazione_imponibile  = decode(nvl(detrazione_imponibile,0) + w_detrazione
                                                        ,0,to_number(null)
                                                        ,nvl(detrazione_imponibile,0) + w_detrazione
                                                        )
                        ,detrazione_imponibile_acconto = decode(nvl(detrazione_imponibile_acconto,0) + w_detrazione_acconto
                                                               ,0,to_number(null)
                                                               ,nvl(detrazione_imponibile_acconto,0) + w_detrazione_acconto
                                                               )
                        ,detrazione_imponibile_d  = decode(nvl(detrazione_imponibile_d,0) + w_detrazione_d
                                                          ,0,to_number(null)
                                                          ,nvl(detrazione_imponibile_d,0) + w_detrazione_d
                                                          )
                        ,detrazione_imponibile_d_acc = decode(nvl(detrazione_imponibile_d_acc,0) + w_detrazione_d_acconto
                                                               ,0,to_number(null)
                                                               ,nvl(detrazione_imponibile_d_acc,0) + w_detrazione_d_acconto
                                                               )
                        ,imposta                = imposta - w_detrazione
                        ,imposta_dovuta         = nvl(imposta_dovuta,0) - nvl(w_detrazione_d,0)
                        ,imposta_acconto        = nvl(imposta_acconto,0) - nvl(w_detrazione_acconto,0)
                        ,imposta_dovuta_acconto = nvl(imposta_dovuta_acconto,0) - nvl(w_detrazione_d_acconto,0)
                   where oggetto_imposta        = rec_ogim.oggetto_imposta
                   ;
            END LOOP;
         end if;
      END LOOP;
   END LOOP;
EXCEPTION
   WHEN FINE THEN null;
   WHEN ERRORE THEN
      ROLLBACK;
      RAISE_APPLICATION_ERROR(-20999,w_errore,true);
   WHEN OTHERS THEN
      ROLLBACK;
      RAISE_APPLICATION_ERROR(-20999,'Errore in Calcolo Detrazioni ICI IMPO di '||w_cod_fiscale||' ('||SQLERRM||')');
END;
/* End Procedure: CALCOLO_DETRAZIONI_ICI_IMPO */
/

