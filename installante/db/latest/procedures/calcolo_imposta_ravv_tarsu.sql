--liquibase formatted sql 
--changeset abrandolini:20250326_152423_calcolo_imposta_ravv_tarsu stripComments:false runOnChange:true 
 
create or replace procedure CALCOLO_IMPOSTA_RAVV_TARSU
/*************************************************************************
  Rev.    Date         Author      Note
  1       10/08/2015   SC          Personalizzazione S.Lazzaro
                                   Attivita SAP
                                   CR518970 - Calcolo Accertamento a giorni
                                   (san Lazzaro)
  2       30/08/2021   VD          Modifiche per gestione ruoli a tariffe:
                                   invece di CALCOLO_IMPORTO_NORMALIZZATO
                                   occorre utilizzare la procedure
                                   CALCOLO_IMPORTO_NORM_TARIFFE.
*************************************************************************/
(a_pratica           IN number
,a_flag_normalizzato IN varchar2
,a_limite            IN number
,a_tipo_limite       IN varchar2
,a_utente            IN varchar2
) is
errore                  exception;
w_errore                varchar2(2000);
w_importo               number;
w_addizionale_eca       number;
w_maggiorazione_eca     number;
w_addizionale_pro       number;
w_iva                   number;
w_importo_1             number;
w_addizionale_eca_1     number;
w_maggiorazione_eca_1   number;
w_addizionale_pro_1     number;
w_iva_1                 number;
w_importo_2             number;
w_addizionale_eca_2     number;
w_maggiorazione_eca_2   number;
w_addizionale_pro_2     number;
w_iva_2                 number;
w_importo_3             number;
w_addizionale_eca_3     number;
w_maggiorazione_eca_3   number;
w_addizionale_pro_3     number;
w_iva_3                 number;
w_importo_4             number;
w_addizionale_eca_4     number;
w_maggiorazione_eca_4   number;
w_addizionale_pro_4     number;
w_iva_4                 number;
w_rata_imposta          number;
w_totale                number;
w_stringa_rate          varchar2(2000);
w_importo_pf               number;
w_importo_pv               number;
w_stringa_familiari        varchar2(2000);
w_dettaglio_ogim           varchar2(2000);
w_dettaglio_faog           varchar2(2000);
w_giorni_ruolo             number;
-- (VD - 30/08/2021): aggiunte variabili per gestione ruolo a tariffe
w_imposta                  number;
w_importo_base             number;
w_importo_pf_base          number;
w_importo_pv_base          number;
w_perc_rid_pf              number;
w_perc_rid_pv              number;
w_importo_pf_rid           number;
w_importo_pv_rid           number;
w_dettaglio_ogim_base      varchar2(2000);
cursor sel_prat (a_pratica           number
                ,a_flag_normalizzato varchar2
                ) is
select prtr.tipo_tributo             tipo_tributo
      ,prtr.tipo_pratica             tipo_pratica
      ,prtr.tipo_evento              tipo_evento
      ,prtr.anno                     anno
      ,prtr.numero                   numero_pratica
      ,prtr.data                     data_pratica
      ,prtr.data_notifica            data_notifica
      ,ogpr.oggetto                  oggetto
      ,ogpr.oggetto_pratica          oggetto_pratica
      ,ogpr.tipo_oggetto             tipo_oggetto
      ,ogpr.tipo_occupazione         tipo_occupazione
      ,ogpr.tributo                  tributo
      ,ogpr.categoria                categoria
      ,nvl(cate.flag_giorni,'N')     flag_giorni
      ,ogpr.tipo_tariffa             tipo_tariffa
      ,ogpr.numero_familiari         numero_familiari
      ,tari.tariffa                  tariffa
      ,tari.limite                   limite_tariffa
      ,tari.tariffa_superiore        tariffa_superiore
      ,tari.tariffa_quota_fissa      tariffa_quota_fissa
      ,ogpr.consistenza              consistenza
      ,ogco.perc_possesso            perc_possesso
      ,ogco.flag_ab_principale       flag_ab_principale
      ,ogco.data_decorrenza          data_decorrenza
      ,ogco.data_cessazione          data_cessazione
      ,nvl(f_periodo(prtr.anno,ogco.data_decorrenza,ogco.data_cessazione,
                     ogpr.tipo_occupazione,prtr.tipo_tributo,
                     decode(
                     lpad(to_char(pro_cliente),3,'0')||lpad(to_char(com_cliente),3,'0'),
                     '037054',
                     'S',
                     a_flag_normalizzato)
                    ),0
          )                          periodo
      ,ogco.cod_fiscale              cod_fiscale
      ,ogim.oggetto_imposta          oggetto_imposta
      ,to_number(substr(ogim.note,1,10))
                                     ruolo
      ,decode(nvl(to_number(substr(ogim.note,1,10)),0)
             ,0,0
               ,0  --f_delta_rate(to_number(substr(ogim.note,1,10)))
             )                       delta_rate
      ,ruol.rate                     num_rate
      ,nvl(cata.addizionale_eca,0)   add_eca
      ,nvl(cata.maggiorazione_eca,0) magg_eca
      ,nvl(cata.addizionale_pro,0)   add_pro
      ,nvl(cata.aliquota,0)          aliquota
      --(VD - 30/08/2021): selezione per ruolo gestito a tariffe
      ,f_get_tariffa_base(ogpr.tributo,ogpr.categoria,prtr.anno) tipo_tariffa_base
  from oggetti_imposta        ogim
      ,carichi_tarsu          cata
      ,ruoli                  ruol
      ,oggetti_contribuente   ogco
      ,tariffe                tari
      ,categorie              cate
      ,oggetti_pratica        ogpr
      ,pratiche_tributo       prtr
      ,dati_generali          dage
 where dage.chiave               = 1
   and ogim.anno                 = prtr.anno
   and ogim.oggetto_pratica      = ogpr.oggetto_pratica
   and cata.anno                 = ogim.anno
--
-- nelle note degli oggetti imposta viene memorizzato il ruolo di provenienza
--
   and ruol.ruolo                = to_number(substr(ogim.note,1,10))
   and ogim.cod_fiscale          = prtr.cod_fiscale
   and ogco.cod_fiscale          = prtr.cod_fiscale
   and ogco.oggetto_pratica      = ogpr.oggetto_pratica
   and tari.anno                 = ogim.anno
   and tari.tributo              = ogpr.tributo
   and tari.categoria            = ogpr.categoria
   and tari.tipo_tariffa         = ogpr.tipo_tariffa
   and cate.tributo              = ogpr.tributo
   and cate.categoria            = ogpr.categoria
   and ogpr.pratica              = prtr.pratica
   and prtr.pratica              = a_pratica
;
BEGIN
   BEGIN
      delete from rate_imposta            raim
       where raim.oggetto_imposta in
            (select ogim.oggetto_imposta
               from oggetti_imposta       ogim
                   ,oggetti_pratica       ogpr
              where ogpr.oggetto_pratica  = ogim.oggetto_pratica
                and ogpr.pratica          = a_pratica
            )
      ;
   END;
   BEGIN
      delete from familiari_ogim            faog
       where faog.oggetto_imposta in
            (select ogim.oggetto_imposta
               from oggetti_imposta       ogim
                   ,oggetti_pratica       ogpr
              where ogpr.oggetto_pratica  = ogim.oggetto_pratica
                and ogpr.pratica          = a_pratica
            )
      ;
   END;
   BEGIN
      update oggetti_imposta         ogim
         set ogim.imposta            = 0
            ,ogim.addizionale_eca    = null
            ,ogim.maggiorazione_eca  = null
            ,ogim.addizionale_pro    = null
            ,ogim.iva                = null
            ,ogim.utente             = a_utente
       where ogim.oggetto_pratica   in
            (select ogpr.oggetto_pratica
               from oggetti_pratica  ogpr
              where ogpr.pratica     = a_pratica
            )
       ;
   END;
   w_totale := 0;
   FOR rec_prat in sel_prat(a_pratica,a_flag_normalizzato)
   LOOP
      w_importo_pf         := null;
      w_importo_pv         := null;
      w_stringa_familiari  := '';
      w_dettaglio_ogim     := '';
      w_dettaglio_faog     := '';
      if a_flag_normalizzato = 'S' then
--
-- Il normalizzato tiene gia` conto del periodo e percentuale di possesso.
--
         /*calcolo_importo_normalizzato(rec_prat.cod_fiscale
                                     ,null  --ni
                                     ,rec_prat.anno
                                     ,rec_prat.tributo
                                     ,rec_prat.categoria
                                     ,rec_prat.tipo_tariffa
                                     ,rec_prat.tariffa
                                     ,rec_prat.tariffa_quota_fissa
                                     ,rec_prat.consistenza
                                     ,rec_prat.perc_possesso
                                     ,rec_prat.data_decorrenza
                                     ,rec_prat.data_cessazione
                                     ,rec_prat.flag_ab_principale
                                     ,rec_prat.numero_familiari
                                     ,null  -- ruolo
                                     ,w_importo
                                     ,w_importo_pf,w_importo_pv
                                     ,w_stringa_familiari
                                     ,w_dettaglio_ogim
                                     ,w_giorni_ruolo);
         if length(w_dettaglio_ogim) > 151 then
            w_dettaglio_faog := w_dettaglio_ogim;
            w_dettaglio_ogim := '';
         end if;*/
         -- (VD - 30/08/2021): gestione ruolo a tariffe.
         --                    Sostituita procedure CALCOLO_IMPORTO_NORMALIZZATO
         --                    con CALCOLO_IMPORTO_NORM_TARIFFE
         calcolo_importo_norm_tariffe(rec_prat.cod_fiscale
                                     ,null  --ni
                                     ,rec_prat.anno
                                     ,rec_prat.tributo
                                     ,rec_prat.categoria
                                     ,rec_prat.tipo_tariffa
                                     ,rec_prat.tariffa
                                     ,rec_prat.tariffa_quota_fissa
                                     ,rec_prat.consistenza
                                     ,rec_prat.perc_possesso
                                     ,rec_prat.data_decorrenza
                                     ,rec_prat.data_cessazione
                                     ,rec_prat.flag_ab_principale
                                     ,rec_prat.numero_familiari
                                     ,null  -- ruolo
                                     ,to_number(null)      -- oggetto
                                     ,rec_prat.tipo_tariffa_base
                                     ,w_imposta
                                     ,w_importo_pf
                                     ,w_importo_pv
                                     ,w_importo_base
                                     ,w_importo_pf_base
                                     ,w_importo_pv_base
                                     ,w_perc_rid_pf
                                     ,w_perc_rid_pv
                                     ,w_importo_pf_rid
                                     ,w_importo_pv_rid
                                     ,w_stringa_familiari
                                     ,w_dettaglio_ogim
                                     ,w_dettaglio_ogim_base
                                     ,w_giorni_ruolo);
         if length(w_dettaglio_ogim) > 151 then
            w_dettaglio_faog := w_dettaglio_ogim;
            w_dettaglio_ogim := '';
         end if;
         w_importo := w_imposta;
      else
         if rec_prat.consistenza     < rec_prat.limite_tariffa
         or rec_prat.limite_tariffa is null         then
            w_importo := rec_prat.consistenza * rec_prat.tariffa;
         else
            w_importo := rec_prat.limite_tariffa * rec_prat.tariffa +
                         (rec_prat.consistenza - rec_prat.limite_tariffa) * nvl(rec_prat.tariffa_superiore,0);
         end if;
         w_importo := round(w_importo * (nvl(rec_prat.perc_possesso,100) / 100) * rec_prat.periodo,2);
      end if;
--
-- Totalizzazione imposta per eventuale controllo sul limite del contribuente.
--
      w_totale := w_totale + w_importo;
--
-- Controllo che sia stato raggiunto il limite per utenza.
--
      if a_limite < w_importo and a_tipo_limite = 'O'
      or a_tipo_limite = 'C' then
         w_addizionale_eca    := round(w_importo * rec_prat.add_eca    / 100,2);
         w_maggiorazione_eca  := round(w_importo * rec_prat.magg_eca   / 100,2);
         w_addizionale_pro    := round(w_importo * rec_prat.add_pro    / 100,2);
         w_iva                := round(w_importo * rec_prat.aliquota   / 100,2);
--
-- Si compone la w_stringa_rate che viene memorizzata nelle note di ogim.
-- Essa serve per il calcolo delle sanzioni e contiene:
-- Il ruolo (caratteri da 1 a 10), il numero di rate con data scadenza inferiore
-- alla data di emissione del ruolo (infatti le rate per i ruoli sono sempre
-- numerate a partire da 1, ma rispetto alla data di emissione del ruolo il che
-- significa che se, per esempio, ci sono due scadenze prima della data di emissione
-- del ruolo bisogna considerare come prima scadenza la terza, come seconda la quarta, ecc...),
-- il numero della rata e poi la imposta netta, la addizionale ECA, la maggiorazione ECA,
-- la addizionale PRO, la IVA; questi importi tutti moltiplicati per 100 e riempiti di zeri a
-- sinistra per la lunghezza di 15 caratteri ognuno. Le rate inferiori al numero massimo consentito
-- (quattro) hanno gli elementi non significativi con tutti zeri.
--
         if rec_prat.num_rate = 4 then
            w_importo_4           := w_importo           - round(w_importo           / 4,2) * 3;
            w_addizionale_eca_4   := w_addizionale_eca   - round(w_addizionale_eca   / 4,2) * 3;
            w_maggiorazione_eca_4 := w_maggiorazione_eca - round(w_maggiorazione_eca / 4,2) * 3;
            w_addizionale_pro_4   := w_addizionale_pro   - round(w_addizionale_pro   / 4,2) * 3;
            w_iva_4               := w_iva               - round(w_iva               / 4,2) * 3;
            w_importo_3           := round(w_importo           / 4,2);
            w_addizionale_eca_3   := round(w_addizionale_eca   / 4,2);
            w_maggiorazione_eca_3 := round(w_maggiorazione_eca / 4,2);
            w_addizionale_pro_3   := round(w_addizionale_pro   / 4,2);
            w_iva_3               := round(w_iva               / 4,2);
            w_importo_2           := round(w_importo           / 4,2);
            w_addizionale_eca_2   := round(w_addizionale_eca   / 4,2);
            w_maggiorazione_eca_2 := round(w_maggiorazione_eca / 4,2);
            w_addizionale_pro_2   := round(w_addizionale_pro   / 4,2);
            w_iva_2               := round(w_iva               / 4,2);
            w_importo_1           := round(w_importo           / 4,2);
            w_addizionale_eca_1   := round(w_addizionale_eca   / 4,2);
            w_maggiorazione_eca_1 := round(w_maggiorazione_eca / 4,2);
            w_addizionale_pro_1   := round(w_addizionale_pro   / 4,2);
            w_iva_1               := round(w_iva               / 4,2);
            w_stringa_rate        := lpad(to_char(rec_prat.ruolo),10,'0')||
                                     to_char(rec_prat.delta_rate)||
                                     '4'||
                                     lpad(to_char(nvl(w_importo_1,0) * 100),15,'0')||
                                     lpad(to_char(nvl(w_addizionale_eca_1,0) * 100),15,'0')||
                                     lpad(to_char(nvl(w_maggiorazione_eca_1,0) * 100),15,'0')||
                                     lpad(to_char(nvl(w_addizionale_pro_1,0) * 100),15,'0')||
                                     lpad(to_char(nvl(w_iva_1,0) * 100),15,'0')||
                                     lpad(to_char(nvl(w_importo_2,0) * 100),15,'0')||
                                     lpad(to_char(nvl(w_addizionale_eca_2,0) * 100),15,'0')||
                                     lpad(to_char(nvl(w_maggiorazione_eca_2,0) * 100),15,'0')||
                                     lpad(to_char(nvl(w_addizionale_pro_2,0) * 100),15,'0')||
                                     lpad(to_char(nvl(w_iva_2,0) * 100),15,'0')||
                                     lpad(to_char(nvl(w_importo_3,0) * 100),15,'0')||
                                     lpad(to_char(nvl(w_addizionale_eca_3,0) * 100),15,'0')||
                                     lpad(to_char(nvl(w_maggiorazione_eca_3,0) * 100),15,'0')||
                                     lpad(to_char(nvl(w_addizionale_pro_3,0) * 100),15,'0')||
                                     lpad(to_char(nvl(w_iva_3,0) * 100),15,'0')||
                                     lpad(to_char(nvl(w_importo_4,0) * 100),15,'0')||
                                     lpad(to_char(nvl(w_addizionale_eca_4,0) * 100),15,'0')||
                                     lpad(to_char(nvl(w_maggiorazione_eca_4,0) * 100),15,'0')||
                                     lpad(to_char(nvl(w_addizionale_pro_4,0) * 100),15,'0')||
                                     lpad(to_char(nvl(w_iva_4,0) * 100),15,'0');
         end if;
         if rec_prat.num_rate = 3 then
            w_importo_3           := w_importo           - round(w_importo           / 3,2) * 2;
            w_addizionale_eca_3   := w_addizionale_eca   - round(w_addizionale_eca   / 3,2) * 2;
            w_maggiorazione_eca_3 := w_maggiorazione_eca - round(w_maggiorazione_eca / 3,2) * 2;
            w_addizionale_pro_3   := w_addizionale_pro   - round(w_addizionale_pro   / 3,2) * 2;
            w_iva_3               := w_iva               - round(w_iva               / 3,2) * 2;
            w_importo_2           := round(w_importo           / 3,2);
            w_addizionale_eca_2   := round(w_addizionale_eca   / 3,2);
            w_maggiorazione_eca_2 := round(w_maggiorazione_eca / 3,2);
            w_addizionale_pro_2   := round(w_addizionale_pro   / 3,2);
            w_iva_2               := round(w_iva               / 3,2);
            w_importo_1           := round(w_importo           / 3,2);
            w_addizionale_eca_1   := round(w_addizionale_eca   / 3,2);
            w_maggiorazione_eca_1 := round(w_maggiorazione_eca / 3,2);
            w_addizionale_pro_1   := round(w_addizionale_pro   / 3,2);
            w_iva_1               := round(w_iva               / 3,2);
            w_stringa_rate        := lpad(to_char(rec_prat.ruolo),10,'0')||
                                     to_char(rec_prat.delta_rate)||
                                     '3'||
                                     lpad(to_char(nvl(w_importo_1,0) * 100),15,'0')||
                                     lpad(to_char(nvl(w_addizionale_eca_1,0) * 100),15,'0')||
                                     lpad(to_char(nvl(w_maggiorazione_eca_1,0) * 100),15,'0')||
                                     lpad(to_char(nvl(w_addizionale_pro_1,0) * 100),15,'0')||
                                     lpad(to_char(nvl(w_iva_1,0) * 100),15,'0')||
                                     lpad(to_char(nvl(w_importo_2,0) * 100),15,'0')||
                                     lpad(to_char(nvl(w_addizionale_eca_2,0) * 100),15,'0')||
                                     lpad(to_char(nvl(w_maggiorazione_eca_2,0) * 100),15,'0')||
                                     lpad(to_char(nvl(w_addizionale_pro_2,0) * 100),15,'0')||
                                     lpad(to_char(nvl(w_iva_2,0) * 100),15,'0')||
                                     lpad(to_char(nvl(w_importo_3,0) * 100),15,'0')||
                                     lpad(to_char(nvl(w_addizionale_eca_3,0) * 100),15,'0')||
                                     lpad(to_char(nvl(w_maggiorazione_eca_3,0) * 100),15,'0')||
                                     lpad(to_char(nvl(w_addizionale_pro_3,0) * 100),15,'0')||
                                     lpad(to_char(nvl(w_iva_3,0) * 100),15,'0')||
                                     lpad('0',75,'0');
         end if;
         if rec_prat.num_rate = 2 then
            w_importo_2           := w_importo           - round(w_importo           / 2,2);
            w_addizionale_eca_2   := w_addizionale_eca   - round(w_addizionale_eca   / 2,2);
            w_maggiorazione_eca_2 := w_maggiorazione_eca - round(w_maggiorazione_eca / 2,2);
            w_addizionale_pro_2   := w_addizionale_pro   - round(w_addizionale_pro   / 2,2);
            w_iva_2               := w_iva               - round(w_iva               / 2,2);
            w_importo_1           := round(w_importo           / 2,2);
            w_addizionale_eca_1   := round(w_addizionale_eca   / 2,2);
            w_maggiorazione_eca_1 := round(w_maggiorazione_eca / 2,2);
            w_addizionale_pro_1   := round(w_addizionale_pro   / 2,2);
            w_iva_1               := round(w_iva               / 2,2);
            w_stringa_rate        := lpad(to_char(rec_prat.ruolo),10,'0')||
                                     to_char(rec_prat.delta_rate)||
                                     '2'||
                                     lpad(to_char(nvl(w_importo_1,0) * 100),15,'0')||
                                     lpad(to_char(nvl(w_addizionale_eca_1,0) * 100),15,'0')||
                                     lpad(to_char(nvl(w_maggiorazione_eca_1,0) * 100),15,'0')||
                                     lpad(to_char(nvl(w_addizionale_pro_1,0) * 100),15,'0')||
                                     lpad(to_char(nvl(w_iva_1,0) * 100),15,'0')||
                                     lpad(to_char(nvl(w_importo_2,0) * 100),15,'0')||
                                     lpad(to_char(nvl(w_addizionale_eca_2,0) * 100),15,'0')||
                                     lpad(to_char(nvl(w_maggiorazione_eca_2,0) * 100),15,'0')||
                                     lpad(to_char(nvl(w_addizionale_pro_2,0) * 100),15,'0')||
                                     lpad(to_char(nvl(w_iva_2,0) * 100),15,'0')||
                                     lpad('0',150,'0');
         end if;
         if rec_prat.num_rate < 2 then
            w_importo_1           := w_importo;
            w_addizionale_eca_1   := w_addizionale_eca;
            w_maggiorazione_eca_1 := w_maggiorazione_eca;
            w_addizionale_pro_1   := w_addizionale_pro;
            w_iva_1               := w_iva;
            w_stringa_rate        := lpad(to_char(rec_prat.ruolo),10,'0')||
                                     to_char(rec_prat.delta_rate)||
                                     '1'||
                                     lpad(to_char(nvl(w_importo_1,0) * 100),15,'0')||
                                     lpad(to_char(nvl(w_addizionale_eca_1,0) * 100),15,'0')||
                                     lpad(to_char(nvl(w_maggiorazione_eca_1,0) * 100),15,'0')||
                                     lpad(to_char(nvl(w_addizionale_pro_1,0) * 100),15,'0')||
                                     lpad(to_char(nvl(w_iva_1,0) * 100),15,'0')||
                                     lpad('0',150,'0')||lpad('0',75,'0');
         end if;
         BEGIN
            update oggetti_imposta      ogim
               set ogim.imposta            = w_importo
                  ,ogim.addizionale_eca    = w_addizionale_eca
                  ,ogim.maggiorazione_eca  = w_maggiorazione_eca
                  ,ogim.addizionale_pro    = w_addizionale_pro
                  ,ogim.iva                = w_iva
                  ,ogim.utente             = a_utente
                  ,ogim.note               = w_stringa_rate
                  ,ogim.importo_pf         = w_importo_pf
                  ,ogim.importo_pv         = w_importo_pv
                  ,ogim.dettaglio_ogim     = w_dettaglio_ogim
             where ogim.oggetto_imposta    = rec_prat.oggetto_imposta
            ;
         END;
         WHILE length(w_stringa_familiari) > 19  LOOP
                 BEGIN
                       insert into familiari_ogim
                                  (oggetto_imposta,numero_familiari
                                  ,dal,al
                                  ,data_variazione
                                  ,dettaglio_faog)
                            values(rec_prat.oggetto_imposta,to_number(substr(w_stringa_familiari,1,4))
                                  ,to_date(substr(w_stringa_familiari,5,8),'ddmmyyyy'),to_date(substr(w_stringa_familiari,13,8),'ddmmyyyy')
                                  ,trunc(sysdate)
                                  ,substr(w_dettaglio_faog,1,150)
                                  )
                                  ;
                    EXCEPTION
                       WHEN others THEN
                           w_errore := 'Errore in inserimento Familiari_ogim di '
                                       ||to_char(rec_prat.oggetto_imposta)||' ('||SQLERRM||')';
                               RAISE ERRORE;
                    END;
                 w_stringa_familiari := substr(w_stringa_familiari,21);
                 w_dettaglio_faog    := substr(w_dettaglio_faog,151);
         END LOOP;
      end if;
   END LOOP;
--
-- Controllo di raggiunto limite per contribuente.
--
   if a_tipo_limite = 'C' and a_limite is not null and a_limite > w_totale then
      BEGIN
         delete from rate_imposta            raim
          where raim.oggetto_imposta in
               (select ogim.oggetto_imposta
                  from oggetti_imposta       ogim
                      ,oggetti_pratica       ogpr
                 where ogpr.oggetto_pratica  = ogim.oggetto_pratica
                   and ogpr.pratica          = a_pratica
               )
         ;
      END;
      BEGIN
         delete from familiari_ogim          faog
          where faog.oggetto_imposta in
               (select ogim.oggetto_imposta
                  from oggetti_imposta       ogim
                      ,oggetti_pratica       ogpr
                 where ogpr.oggetto_pratica  = ogim.oggetto_pratica
                   and ogpr.pratica          = a_pratica
               )
         ;
      END;
      BEGIN
         update oggetti_imposta         ogim
            set ogim.imposta            = 0
               ,ogim.addizionale_eca    = null
               ,ogim.maggiorazione_eca  = null
               ,ogim.addizionale_pro    = null
               ,ogim.iva                = null
               ,ogim.utente             = a_utente
               ,ogim.importo_pf         = null
               ,ogim.importo_pv         = null
               ,ogim.dettaglio_ogim     = null
          where ogim.oggetto_pratica   in
               (select ogpr.oggetto_pratica
                  from oggetti_pratica  ogpr
                 where ogpr.pratica     = a_pratica
               )
          ;
      END;
   end if;
EXCEPTION
   WHEN errore THEN
      ROLLBACK;
      RAISE_APPLICATION_ERROR(-20999,w_errore);
   WHEN OTHERS THEN
      ROLLBACK;
      RAISE_APPLICATION_ERROR(-20999,SQLERRM);
END;
/* End Procedure: CALCOLO_IMPOSTA_RAVV_TARSU */
/

