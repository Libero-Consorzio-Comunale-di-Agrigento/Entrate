--liquibase formatted sql 
--changeset abrandolini:20250326_152423_calcolo_imposta_ici stripComments:false runOnChange:true 
 
CREATE OR REPLACE procedure     CALCOLO_IMPOSTA_ICI
/*************************************************************************
  NOME:        CALCOLO_IMPOSTA_ICI
  DESCRIZIONE: Calcola imposta ICI per contribuente/anno
  ANNOTAZIONI:
  REVISIONI:
  Rev.  Data        Autore  Note
  ----  ----------  ------  ----------------------------------------------------
  012   04/12/2024  AB      #76723
                            Per i Ravvedimenti, nella eliminazione di OGIM e OGOG aggiunto
                            nvl(prtr.stato_accertamento,'D')  ='D' che non dovrebbe
                            mai succedere perchè dovrebbero gia essere eliminati
                            al momento della creazione della nuova pratica,
                            prima venivano eliminati tutti i ravv con stesso tipo_evento
  011   08/05/2023  AB      Nella delete periodi_imponibile aggiunto il CF in descr errore
  010   17/02/2022  VD      Ingrandita variabile messaggio di errore (per
                            visualizzare l'intero testo).
  009   07/10/2021  VD      Aggiunto controllo su tipo_evento: se la procedure
                            viene richiamata da CREA_RAVVEDIMENTO si passa il
                            tipo versamento come parametro (Acconto/Saldo).
                            Questo permette di caricare il ravvedimento in
                            acconto e il ravvedimento a saldo, evitando
                            l'eliminazione degli oggetti_imposta caricati per
                            primi quando si effettua il secondo ravvedimento.
  008   23/10/2020  VD      IMU 2020: nuova gestione per calcolo imposta a saldo
  007   10/09/2020  VD      Aggiunto parametro da_mese_possesso nel richiamo
                            della procedure DETERMINA_MESI_POSSESSO.
  006   29/12/2016  VD      Modificata gestione aliquota acconto per categoria:
                            per anno >= 2012, si passa alla funzione
                            F_ALIQUOTA_ALCA il parametro 'S' per ottenere
                            l'eventuale aliquota base della categoria indicata.
  005   20/09/2016  AB      Sistemato il loop di SEL_OGIM_MINI per azzerare le
                            variabili e aggiunta la categoria_catasto come
                            parametro per la F_ORDINAMENTO_OGGETTI.
  004   12/08/2016  VD      Correzione aggiornamento OGGETTI_IMPOSTA
                            (imposta invece di imposta_dovuta)
  003   11/05/2016  VD      Aggiunta funzione F_ORDINAMENTO_OGGETTI in query
                            SEL_OGCO e SEL_OGIM_MINI per selezionare gli oggetti
                            di ogni contribuente in ordine di periodo possesso
                            e raggruppando per pertinenza
  002   08/06/2015  AB      Aggiunto il controllo dei tipi_aliquota in
                            aliquote_ogco, sel_chk_alog
  001   21/04/2015  VD      Aggiunto test su tipo_tributo in controllo aliquote
                            utilizzi_oggetto anno precedente (SEL_CHK_UTOG)
*************************************************************************/
( a_anno_rif      IN number,
  a_cod_fiscale   IN varchar2,
  a_utente        IN varchar2,
  a_ravvedimento  IN VARCHAR2,
  a_tipo_evento   IN varchar2 default null
) IS
errore                  exception;
w_errore                varchar2(32767);
--sql_errm                varchar2(100);
w_anno_s                varchar2(4);
w_dal_possesso          date;
w_dal_possesso_1s       date;
w_flag_pertinenze       varchar2(1);
w_dep_aliquota          number;
w_dep_tipo_aliquota     number;
w_dep_aliquota2         number;
w_dep_tipo_aliquota2    number;
w_aliquota_base         number;
w_aliquota_base_prec    number;
w_aliquota_base_erar    number;
w_aliquota_base_ok      number;
w_tipo_al_base          number := 1;
w_tipo_al_base_prec     number := 1;
w_al_ab_principale      number;
w_al_ab_principale_prec number;
w_al_ab_principale_erar number;
w_al_ab_principale_ok   number;
w_tipo_al_ab_principale number := 2;
w_tipo_al_ab_principale_prec
                        number := 2;
w_al_affittato          number;
w_al_affittato_prec     number;
w_al_affittato_erar     number;
w_tipo_al_affittato     number := 3;
w_tipo_al_affittato_prec
                        number := 3;
w_al_affittato_utog     number;
w_tipo_al_affittato_utog
                        number;
w_al_affittato_Prec_utog
                        number;
w_tipo_al_affittato_prec_utog
                        number;
w_al_risultante         number;
w_tipo_al_risultante    number;
w_al_risultante_prec    number;
w_tipo_al_risultante_prec
                        number;
w_al_non_affittato      number;
w_al_non_affittato_prec number;
w_al_non_affittato_erar number;
w_tipo_al_non_affittato number := 4;
w_tipo_al_non_affittato_prec
                        number := 4;
w_al_seconda_casa       number;
w_al_seconda_casa_prec  number;
w_al_seconda_casa_erar  number;
w_tipo_al_seconda_casa  number := 10;
w_tipo_al_seconda_casa_prec
                        number := 10;
w_al_negozio            number;
w_al_negozio_prec       number;
w_al_negozio_erar       number;
w_tipo_al_negozio       number := 5;
w_tipo_al_negozio_prec  number := 5;
w_al_d                  number;
w_al_d_prec             number;
w_al_d_erar             number;
w_tipo_al_d             number := 9;
w_tipo_al_d_prec        number := 9;
w_al_d10                number;
w_al_d10_prec           number;
w_al_d10_erar           number;
w_tipo_al_d10           number := 11;
w_tipo_al_d10_prec      number := 11;
w_tipo_al               number;
w_tipo_al_prec          number;
w_tipo_al_terreni       number := 51;
w_tipo_al_terreni_prec  number := 51;
w_al_terreni            number;
w_al_terreni_prec       number;
w_al_terreni_erar       number;
w_tipo_al_terreni_rid   number := 52;
w_tipo_al_terreni_rid_prec
                        number := 52;
w_al_terreni_rid        number;
w_al_terreni_rid_prec   number;
w_al_terreni_rid_erar   number;
w_tipo_al_aree          number := 53;
w_tipo_al_aree_prec     number := 53;
w_al_aree               number;
w_al_aree_prec          number;
w_al_aree_erar          number;
w_al                    number;
w_al_prec               number;
w_al_erar               number;
w_aliquota1             number;
w_aliquota2             number;
w_perc_acconto          number;
w_abitazioni            number := 0;
w_detrazioni            number := 0;
w_altri_1               number := 0;
w_altri_2               number := 0;
w_altri_3               number := 0;
w_tot_altri_3           number := 0;
w_altri_4               number := 0;
w_data_inizio_possesso  date;
w_data_fine_possesso    date;
w_data_inizio_possesso_1s  date;
w_data_fine_possesso_1s    date;
w_flag_possesso         varchar2(1);
w_mesi_possesso         number;
w_mesi_possesso_1s      number;
w_mesi_possesso_2s      number;
w_da_mese_possesso      number;
w_flag_riduzione        varchar2(1);
w_mesi_riduzione        number;
w_mesi_riduzione_1s     number;
w_flag_esclusione       varchar2(1);
w_mesi_esclusione       number;
w_mesi_esclusione_1s    number;
w_mesi_esclusione_2s    number;
w_flag_al_ridotta       varchar2(1);
w_mesi_al_ridotta       number;
w_mesi_al_ridotta_1s    number;
w_mm_affitto            number;
w_mm_affitto_1s         number;
w_dep_mesi_affitto      number;
w_mesi_affitto          number;
w_dep_mesi_affitto_1s   number;
w_mesi_affitto_1s       number;
w_dep_mesi_non_affitto  number;
w_mesi_non_affitto      number;
w_mesi_non_affitto_1s   number;
w_data_inizio_affitto   date;
w_data_fine_affitto     date;
w_data_inizio_affitto_1s date;
w_data_fine_affitto_1s  date;
w_anno                  number;
w_dep_mm                number;
w_mm                    number;
w_aa                    number;
w_abitazioni_1s         number;
w_detrazioni_1s         number;
w_altri_1_1s            number := 0;
w_altri_2_1s            number := 0;
w_altri_3_1s            number := 0;
w_tot_altri_3_1s        number := 0;
w_altri_4_1s            number := 0;
w_flag_possesso_prec    varchar2(1);
w_flag_riduzione_prec   varchar2(1);
w_flag_esclusione_prec  varchar2(1);
w_flag_al_ridotta_prec  varchar2(1);
w_flag_ab_pric_Prec     varchar2(1);
w_moltiplicatore_altri  number;
w_categoria_catasto_altri varchar(3);
w_mesi_possesso_prec      number;
w_magg_detrazione_prec    number;
w_detrazione_prec         number;
w_esiste_ogco             varchar2(1);
w_esiste_det_ogco         varchar2(1);
w_rif_ap_ab_principale    varchar2(1);
wd_abitazioni           number   := 0;
wd_detrazioni           number   := 0;
wd_altri_1              number   := 0;
wd_altri_2              number   := 0;
wd_altri_3              number   := 0;
wd_tot_altri_3          number   := 0;
wd_altri_4              number   := 0;
wd_abitazioni_1s        number;
wd_detrazioni_1s        number;
wd_altri_1_1s           number   := 0;
wd_altri_2_1s           number   := 0;
wd_altri_3_1s           number   := 0;
wd_tot_altri_3_1s       number   := 0;
wd_altri_4_1s           number   := 0;
w_altri_3_erar          number   := 0;
w_altri_3_erar_1s       number   := 0;
wd_altri_3_erar         number   := 0;
wd_altri_3_erar_1s      number   := 0;
w_cod_fiscale           varchar2(16);
w_flag_calcolo          varchar2(1);
w_totale_mesi           number;
w_totale_importo        number;
w_totale_mesi_1s        number;
w_totale_importo_1s     number;
w_ind                   number;
w_imposta               number;
w_imposta_dovuta        number;
w_imposta_acconto       number;
w_imposta_dovuta_acconto
                        number;
w_note                  varchar2(2000);
w_aliquote_mancanti     varchar2(200);
w_anno_utog_prec        number;
w_anno_alog_prec        number;
w_conta_rif_ap_ab_principale
                        number;
w_imponibile            number;
w_detr_aliquota         number;
w_aliquota              number;
w_detrazione_acconto    number;
w_detrazione_figlio     number;
w_abitazioni_mini       number;
wd_abitazioni_mini      number;
w_abitazioni_std        number;
wd_abitazioni_std       number;
w_esiste_alca           varchar2(1);
w_al_std                number;
w_altri_3_std           number;
wd_altri_3_std          number;
w_aliquota_base_std     number;
w_al_ab_principale_std  number;
w_al_affittato_std      number;
w_al_non_affittato_std  number;
w_al_seconda_casa_std   number;
w_al_negozio_std        number;
w_al_d_std              number;
w_al_d10_std            number;
w_al_terreni_rid_std    number;
w_mini_imposta_std      number := 0;
w_mini_detrazione_std   number := 0;
w_mini_tot_detrazioni   number := 0;
w_cod_fiscale_mini      varchar2(16);
w_dettaglio_ogim        varchar2(2000);
w_perc_saldo            number;
w_imposta_saldo         number;
w_imposta_saldo_erar    number;
w_note_saldo            varchar2(200);
CURSOR sel_ogco IS
       select ogpr.tipo_oggetto,
         ogpr.pratica pratica_ogpr,
         ogpr.oggetto oggetto_ogpr,
         f_dato_riog(ogco.cod_fiscale,ogco.oggetto_pratica,a_anno_rif,'CA')
                                                    categoria_catasto_ogpr,
         ogpr.oggetto_pratica oggetto_pratica_ogpr,
         ogco.anno anno_ogco,
         ogco.cod_fiscale cod_fiscale_ogco,
         ogco.flag_possesso,
         ogco.perc_possesso,
         decode(ogco.anno,a_anno_rif,nvl(ogco.mesi_possesso,12),12) mesi_possesso,
         decode(ogco.anno,a_anno_rif,ogco.mesi_possesso_1sem,6)     mesi_possesso_1sem,
         decode(ogco.anno,a_anno_rif,ogco.da_mese_possesso,1)       da_mese_possesso,
         ogco.flag_al_ridotta,
         decode(ogco.anno
               ,a_anno_rif,decode(ogco.flag_al_ridotta
                                 ,'S',nvl(ogco.mesi_aliquota_ridotta,nvl(ogco.mesi_possesso,12))
                                     ,nvl(ogco.mesi_aliquota_ridotta,0)
                                 )
                          ,decode(ogco.flag_al_ridotta,'S',12,0)
               )  mesi_aliquota_ridotta,
         ogco.flag_esclusione,
         decode(ogco.anno
               ,a_anno_rif,decode(ogco.flag_esclusione
                                 ,'S',nvl(ogco.mesi_esclusione,nvl(ogco.mesi_possesso,12))
                                     ,nvl(ogco.mesi_esclusione,0)
                                 )
                          ,decode(ogco.flag_esclusione,'S',12,0)
              ) mesi_esclusione,
         ogco.flag_riduzione,
         decode(ogco.anno
               ,a_anno_rif,decode(ogco.flag_riduzione
                                 ,'S',nvl(ogco.mesi_riduzione,nvl(ogco.mesi_possesso,12))
                                     ,nvl(ogco.mesi_riduzione,0)
                                 )
                          ,decode(ogco.flag_riduzione,'S',12,0)
               ) mesi_riduzione,
         ogco.flag_ab_principale flag_ab_principale,
         f_valore(nvl(f_valore_d(ogpr.oggetto_pratica,a_anno_rif),ogpr.valore)
                 ,ogpr.tipo_oggetto
                 ,prtr.anno
                 ,a_anno_rif
                 ,nvl(ogpr.categoria_catasto,ogge.categoria_catasto)
                 ,prtr.tipo_pratica
                 ,ogpr.FLAG_VALORE_RIVALUTATO
                 )                             valore,
         f_valore(nvl(f_valore_d(ogpr.oggetto_pratica,a_anno_rif),ogpr.valore)
                 ,ogpr.tipo_oggetto
                 ,prtr.anno
                 ,a_anno_rif
                 ,nvl(ogpr.categoria_catasto,ogge.categoria_catasto)
                 ,prtr.tipo_pratica
                 ,ogpr.FLAG_VALORE_RIVALUTATO)  valore_d,
         decode(ogco.detrazione,'',decode(ogco.flag_ab_principale,'S',made.detrazione,''),
                         nvl(made.detrazione,ogco.detrazione)) detrazione,
         ogco.detrazione detrazione_ogco,
         nvl(ogpr.categoria_catasto,ogge.categoria_catasto) categoria_catasto_ogge,
         decode(ogpr.tipo_oggetto
               ,1,nvl(molt.moltiplicatore,1)
               ,3,decode(nvl(ogpr.imm_storico,'N')||to_char(sign(2012 - a_anno_rif))
                        ,'S1',100
                        ,nvl(molt.moltiplicatore,1)
                        )
               ,1)     moltiplicatore,
         ogpr.IMM_STORICO,
         ogpr.oggetto_pratica_rif_ap,
         rire.aliquota aliquota_rivalutazione,
         made.detrazione magg_detrazione,
         prtr.tipo_pratica,
         prtr.anno anno_titr,
         F_ORDINAMENTO_OGGETTI(ogpr.oggetto,
                               ogco.oggetto_pratica,
                               ogpr.oggetto_pratica_rif_ap,
                               ogco.flag_ab_principale,
                               ogco.flag_possesso,
                               decode(ogco.anno,a_anno_rif,ogco.mesi_possesso_1sem,6)
                              ) ordinamento
    from rivalutazioni_rendita rire,
         moltiplicatori molt,
         maggiori_detrazioni made,
         oggetti ogge,
         pratiche_tributo prtr,
         oggetti_pratica ogpr,
         oggetti_contribuente ogco
   where rire.anno     (+)           = a_anno_rif
         and rire.tipo_oggetto (+)   = ogpr.tipo_oggetto
         and molt.anno(+)            = a_anno_rif
     and molt.categoria_catasto(+)   =
         f_dato_riog(ogco.cod_fiscale,ogco.oggetto_pratica,a_anno_rif,'CA')
     and made.anno      (+) + 0      = a_anno_rif
     and made.cod_fiscale   (+)      = ogco.cod_fiscale
     and made.tipo_tributo (+)       = 'ICI'
     and ogco.anno||ogco.tipo_rapporto||'S' =
         (select max(b.anno||b.tipo_rapporto||b.flag_possesso)
          from pratiche_tributo c,
            oggetti_contribuente b,
            oggetti_pratica a
            where(   c.data_notifica is not null and c.tipo_pratica||'' = 'A' and
                     nvl(c.stato_accertamento,'D') = 'D' and
                     nvl(c.flag_denuncia,' ')      = 'S' and
                     c.anno                        < a_anno_rif
            or (c.data_notifica is null and c.tipo_pratica||'' = 'D')
                 )
        and c.anno                  <= a_anno_rif
        and c.tipo_tributo||''       = prtr.tipo_tributo
        and c.pratica                = a.pratica
        and a.oggetto_pratica        = b.oggetto_pratica
        and a.oggetto                = ogpr.oggetto
        and b.tipo_rapporto         in ('C','D','E')
        and b.cod_fiscale            = ogco.cod_fiscale)
        and ogge.oggetto             = ogpr.oggetto
        and prtr.tipo_tributo||''    = 'ICI'
  --      and prtr.tipo_pratica       != 'K' -- aggiunto per evitare più oggetti, da verificare 9/4/14 (AB)
        and nvl(prtr.stato_accertamento,'D') = 'D'
        and prtr.pratica             = ogpr.pratica
        and ogpr.oggetto_pratica     = ogco.oggetto_pratica
        and decode(ogco.anno,a_anno_rif,nvl(ogco.mesi_possesso,12),12) >= 0
        and decode(ogco.anno
                  ,a_anno_rif,decode(ogco.flag_esclusione
                                    ,'S',nvl(ogco.mesi_esclusione,nvl(ogco.mesi_possesso,12))
                                        ,nvl(ogco.mesi_esclusione,0)
                                    )
                             ,decode(ogco.flag_esclusione,'S',12,0)
                 )                     <=
            decode(ogco.anno,a_anno_rif,nvl(ogco.mesi_possesso,12),12)
        and ogco.flag_possesso       = 'S'
        and ogco.cod_fiscale      like a_cod_fiscale
        and a_ravvedimento           = 'N'
       union all
       select ogpr.tipo_oggetto,
         ogpr.pratica pratica_ogpr,
         ogpr.oggetto oggetto_ogpr,
         f_dato_riog(ogco.cod_fiscale,ogco.oggetto_pratica,a_anno_rif,'CA')
                                            categoria_catasto_ogpr,
         ogpr.oggetto_pratica oggetto_pratica_ogpr,
         ogco.anno anno_ogco,
         ogco.cod_fiscale cod_fiscale_ogco,
         ogco.flag_possesso,
         ogco.perc_possesso,
         decode(ogco.anno,a_anno_rif,nvl(ogco.mesi_possesso,12),12) mesi_possesso,
         decode(ogco.anno,a_anno_rif,ogco.mesi_possesso_1sem,6)     mesi_possesso_1sem,
         decode(ogco.anno,a_anno_rif,ogco.da_mese_possesso,1)       da_mese_possesso,
         ogco.flag_al_ridotta,
         decode(ogco.anno
               ,a_anno_rif,decode(ogco.flag_al_ridotta
                                 ,'S',nvl(ogco.mesi_aliquota_ridotta,nvl(ogco.mesi_possesso,12))
                                     ,nvl(ogco.mesi_aliquota_ridotta,0)
                                 )
                          ,decode(ogco.flag_al_ridotta,'S',12,0)
               )  mesi_aliquota_ridotta,
         ogco.flag_esclusione,
         decode(ogco.anno
               ,a_anno_rif,decode(ogco.flag_esclusione
                                 ,'S',nvl(ogco.mesi_esclusione,nvl(ogco.mesi_possesso,12))
                                     ,nvl(ogco.mesi_esclusione,0)
                                 )
                          ,decode(ogco.flag_esclusione,'S',12,0)
              ),
         ogco.flag_riduzione,
         decode(ogco.anno
               ,a_anno_rif,decode(ogco.flag_riduzione
                                 ,'S',nvl(ogco.mesi_riduzione,nvl(ogco.mesi_possesso,12))
                                     ,nvl(ogco.mesi_riduzione,0)
                                 )
                          ,decode(ogco.flag_riduzione,'S',12,0)
               ) mesi_riduzione,
         ogco.flag_ab_principale flag_ab_principale,
         f_valore(ogpr.valore
                 ,ogpr.tipo_oggetto
                 ,prtr.anno
                 ,a_anno_rif
                 ,nvl(ogpr.categoria_catasto,ogge.categoria_catasto)
                 ,prtr.tipo_pratica
                 ,ogpr.FLAG_VALORE_RIVALUTATO
                 )                                    valore,
         f_valore(ogpr.valore
                 ,ogpr.tipo_oggetto
                 ,prtr.anno
                 ,a_anno_rif
                 ,nvl(ogpr.categoria_catasto,ogge.categoria_catasto)
                 ,prtr.tipo_pratica
                 ,ogpr.FLAG_VALORE_RIVALUTATO)        valore_d,
         decode(ogco.detrazione,'',decode(ogco.flag_ab_principale,'S',made.detrazione,''),
                nvl(made.detrazione,ogco.detrazione)) detrazione,
         ogco.detrazione detrazione_ogco,
         ogge.categoria_catasto categoria_catasto_ogge,
         decode(ogpr.tipo_oggetto
               ,1,nvl(molt.moltiplicatore,1)
               ,3,decode(nvl(ogpr.imm_storico,'N')||to_char(sign(2012 - a_anno_rif))
                        ,'S1',100
                        ,nvl(molt.moltiplicatore,1)
                        )
               ,1)     moltiplicatore,
         ogpr.IMM_STORICO,
         ogpr.oggetto_pratica_rif_ap,
         rire.aliquota aliquota_rivalutazione,
         made.detrazione magg_detrazione,
         prtr.tipo_pratica,
         prtr.anno,
         F_ORDINAMENTO_OGGETTI(ogpr.oggetto,
                               ogco.oggetto_pratica,
                               ogpr.oggetto_pratica_rif_ap,
                               ogco.flag_ab_principale,
                               ogco.flag_possesso,
                               decode(ogco.anno,a_anno_rif,ogco.mesi_possesso_1sem,6)
                              ) ordinamento
    from rivalutazioni_rendita rire,
         moltiplicatori molt,
         maggiori_detrazioni made,
         oggetti ogge,
         pratiche_tributo prtr,
         oggetti_pratica ogpr,
         oggetti_contribuente ogco
   where rire.anno     (+)           = a_anno_rif
         and rire.tipo_oggetto (+)   = ogpr.tipo_oggetto
         and molt.anno(+)            = a_anno_rif
     and molt.categoria_catasto(+)   =
         f_dato_riog(ogco.cod_fiscale,ogco.oggetto_pratica,a_anno_rif,'CA')
     and made.anno      (+) + 0     = a_anno_rif
     and made.cod_fiscale   (+)      = ogco.cod_fiscale
     and made.tipo_tributo (+)       = 'ICI'
     and ogge.oggetto                = ogpr.oggetto
     and (  (  prtr.tipo_pratica||''  = 'D'
          and ogco.flag_possesso    is null
          and a_ravvedimento         = 'N'
            )
         or ( prtr.tipo_pratica||''  = 'V'
          and prtr.tipo_evento       = nvl(a_tipo_evento,prtr.tipo_evento)
          and a_ravvedimento         = 'S'
          and not exists (select 'x'
                            from sanzioni_pratica sapr
                           where sapr.pratica = prtr.pratica)
            )
         )
     and prtr.tipo_tributo||''       = 'ICI'
     and nvl(prtr.stato_accertamento,'D') = 'D'
     and prtr.pratica                = ogpr.pratica
     and ogpr.oggetto_pratica        = ogco.oggetto_pratica
     and ogco.anno                   = a_anno_rif
     and decode(ogco.anno
               ,a_anno_rif,decode(ogco.flag_esclusione
                                 ,'S',nvl(ogco.mesi_esclusione,nvl(ogco.mesi_possesso,12))
                                     ,nvl(ogco.mesi_esclusione,0)
                                 )
                          ,decode(ogco.flag_esclusione,'S',12,0)
              )                     <=
         decode(ogco.anno,a_anno_rif,nvl(ogco.mesi_possesso,12),12)
     and decode(ogco.anno,a_anno_rif,nvl(ogco.mesi_possesso,12),12) >= 0
     and ogco.cod_fiscale         like a_cod_fiscale
   order by 7,  -- codice fiscale
            31, -- ordinamento
            4   -- categoria catasto
  ;
--- Cursore non utilizzato
--CURSOR sel_utog (p_anno                 number
--                ,p_data_inizio_possesso date
--                ,p_data_fine_possesso   date
--                ,p_oggetto              number
--                ) is
--select utog.anno                   anno
--      ,greatest(
--       decode(utog.anno
--             ,p_anno,decode(to_number(to_char(utog.data_scadenza,'yyyy'))
--                           ,p_anno,add_months(last_day(utog.data_scadenza) + 1,utog.mesi_affitto * -1)
--                                  ,add_months(to_date('3112'||lpad(to_char(p_anno),4,'0')
--                                                     ,'ddmmyyyy'
--                                                     ) + 1,utog.mesi_affitto * -1
--                                                 )
--                           )
--                    ,to_date('0101'||lpad(to_char(p_anno),4,'0'),'ddmmyyyy')
--             ),p_data_inizio_possesso) data_inizio_affitto
--      ,least(
--       decode(to_number(to_char(utog.data_scadenza,'yyyy'))
--             ,p_anno,last_day(utog.data_scadenza)
--                    ,to_date('3112'||lpad(to_char(p_anno),4,'0'),'ddmmyyyy')
--             ),p_data_fine_possesso) data_fine_affitto
--      ,months_between(
--       least(
--       decode(to_number(to_char(utog.data_scadenza,'yyyy'))
--             ,p_anno,last_day(utog.data_scadenza)
--                    ,to_date('3112'||lpad(to_char(p_anno),4,'0'),'ddmmyyyy')
--             ),p_data_fine_possesso) + 1
--      ,greatest(
--       decode(utog.anno
--             ,p_anno,decode(to_number(to_char(utog.data_scadenza,'yyyy'))
--                           ,p_anno,add_months(last_day(utog.data_scadenza) + 1,utog.mesi_affitto * -1)
--                                  ,add_months(to_date('3112'||lpad(to_char(p_anno),4,'0')
--                                                     ,'ddmmyyyy'
--                                                     ) + 1,utog.mesi_affitto * -1
--                                                 )
--                           )
--                    ,to_date('0101'||lpad(to_char(p_anno),4,'0'),'ddmmyyyy')
--             ),p_data_inizio_possesso)) mesi_affitto
--      ,utog.tipo_utilizzo          tipo_utilizzo
--  from utilizzi_oggetto utog
-- where utog.oggetto          = p_oggetto
--   and utog.data_scadenza   >= p_data_inizio_possesso
--   and decode(utog.anno
--             ,to_number(to_char(utog.data_scadenza,'yyyy'))
--             ,add_months(last_day(utog.data_scadenza) + 1,utog.mesi_affitto * -1)
--             ,add_months(to_date('3112'||lpad(to_char(utog.anno),4,'0'),'ddmmyyyy') + 1
--                        ,utog.mesi_affitto * -1
--                        )
--             )              <= p_data_fine_possesso
--   and utog.anno            <= p_anno
--   and (   utog.tipo_utilizzo    = 1
--        or utog.tipo_utilizzo between 61 and 99
--       )
--   and nvl(utog.mesi_affitto,0)  > 0
--;
cursor sel_ogim(p_anno number,p_cod_fiscale varchar2
               ,p_ravvedimento varchar2,p_tipo_evento varchar2) is
select ogim.oggetto_imposta
      ,ogim.imposta
      ,ogim.imposta_acconto
      ,ogim.imposta_dovuta
      ,ogim.imposta_dovuta_acconto
      ,ogim.aliquota
      ,ogim.detrazione_acconto
  from oggetti_imposta  ogim
      ,oggetti_pratica  ogpr
      ,pratiche_tributo prtr
 where ogpr.oggetto_pratica      = ogim.oggetto_pratica
   and prtr.pratica              = ogpr.pratica
   and prtr.tipo_tributo||''     = 'ICI'
   and nvl(prtr.stato_accertamento,'D') = 'D'
   and (  (  p_ravvedimento       = 'S'
         and prtr.tipo_pratica    = 'V'
         and prtr.tipo_evento     = nvl(p_tipo_evento,prtr.tipo_evento)
         and not exists (select 'x'
                           from sanzioni_pratica sapr
                          where sapr.pratica = prtr.pratica)
          )
        or
          (  p_ravvedimento       = 'N'
         and nvl(ogim.flag_calcolo,'N')      = 'S'    -- Segnalato da Betta
         and prtr.tipo_pratica   in  ('D','A')
          )
       )
   and ogim.cod_fiscale       like p_cod_fiscale
   and ogim.anno                 = p_anno
   and ogim.data_variazione      = trunc(sysdate)
   and (    nvl(ogim.imposta_dovuta_acconto,0)
                                 >
            nvl(ogim.imposta_dovuta,0)
        or  nvl(ogim.imposta_acconto,0)
                                 >
            nvl(ogim.imposta,0)
       )
;
cursor sel_ogim_mini(p_anno number,p_cod_fiscale varchar2
                    ,p_ravvedimento varchar2,p_tipo_evento varchar2) is
select ogim.oggetto_imposta
     , ogim.imposta
     , ogim.imposta_dovuta
     , ogim.imposta_acconto
     , ogim.imposta_dovuta_acconto
     , ogim.imposta_std
     , ogim.imposta_dovuta_std
     , ogim.detrazione
     , ogpr.categoria_catasto
     , F_ORDINAMENTO_OGGETTI (ogpr.oggetto,
                              ogco.oggetto_pratica,
                              ogpr.oggetto_pratica_rif_ap,
                              ogco.flag_ab_principale,
                              ogco.flag_possesso,
                              decode(ogco.anno,a_anno_rif,ogco.mesi_possesso_1sem,6),
                              ogpr.categoria_catasto
                             ) ordinamento
     , ogim.cod_fiscale
  from oggetti_imposta      ogim
      ,oggetti_pratica      ogpr
      ,oggetti_contribuente ogco
      ,pratiche_tributo     prtr
 where ogco.cod_fiscale          = ogim.cod_fiscale
   and ogco.oggetto_pratica      = ogim.oggetto_pratica
   and ogpr.oggetto_pratica      = ogim.oggetto_pratica
   and prtr.pratica              = ogpr.pratica
   and prtr.tipo_tributo||''     = 'ICI'
   and nvl(prtr.stato_accertamento,'D') = 'D'
   and (  (  p_ravvedimento       = 'S'
         and prtr.tipo_pratica    = 'V'
         and prtr.tipo_evento     = nvl(p_tipo_evento,prtr.tipo_evento)
         and not exists (select 'x'
                           from sanzioni_pratica sapr
                          where sapr.pratica = prtr.pratica)
          )
        or
          (  p_ravvedimento       = 'N'
         and nvl(ogim.flag_calcolo,'N')      = 'S'    -- Segnalato da Betta
         and prtr.tipo_pratica   in  ('D','A')
          )
       )
   and ogim.cod_fiscale       like p_cod_fiscale
   and ogim.anno                 = p_anno
   and ogim.data_variazione      = trunc(sysdate)
   and ogim.imposta_std is not null
   and ogim.anno = 2013
 order by 11    -- cod_fiscale
         ,10     -- ordinamento
         , ogpr.categoria_catasto
;
-- cursore per controllo che esistano le aliquote
-- per gli utilizzi oggetto dell`anno di imposta e
-- dell`anno precedente di imposta se anno > 2000.
--
cursor sel_chk_utog (p_anno         number
                    ,p_cod_fiscale  varchar2
                    ,p_ravvedimento varchar2
                    ,p_tipo_evento  varchar2
                    ) is
select to_number(p_anno)     anno
      ,decode(utog.tipo_utilizzo
             ,1,3
               ,utog.tipo_utilizzo
             )       tipo_aliquota
  from utilizzi_oggetto utog
 where p_anno                  <= to_number(to_char(utog.data_scadenza,'yyyy'))
   and p_anno                  >= utog.anno
   and utog.tipo_tributo        = 'ICI'
   and (    utog.tipo_utilizzo  = 1
        or  utog.tipo_utilizzo between 61 and 99
       )
   and not exists
      (select 1
         from aliquote aliq
        where aliq.tipo_aliquota = decode(utog.tipo_utilizzo
                                         ,1,3
                                           ,utog.tipo_utilizzo
                                         )
          and aliq.anno          = p_anno
          and aliq.tipo_tributo  = 'ICI'
      )
   and (     nvl(instr(p_cod_fiscale,'%'),0)
                                 > 0
        or   nvl(instr(p_cod_fiscale,'_'),0)
                                 > 0
       )
 group by
       decode(utog.tipo_utilizzo
             ,1,3
               ,utog.tipo_utilizzo
             )
 union
select to_number(p_anno) - 1    anno
      ,decode(utog.tipo_utilizzo
             ,1,3
               ,utog.tipo_utilizzo
             )       tipo_aliquota
  from utilizzi_oggetto utog
 where p_anno - 1              <= to_number(to_char(utog.data_scadenza,'yyyy'))
   and p_anno - 1              >= utog.anno
   and utog.tipo_tributo        = 'ICI'
   and (    utog.tipo_utilizzo  = 1
        or  utog.tipo_utilizzo between 61 and 99
       )
   and not exists
      (select 1
         from aliquote aliq
        where aliq.tipo_aliquota = decode(utog.tipo_utilizzo
                                         ,1,3
                                           ,utog.tipo_utilizzo
                                         )
          and aliq.anno          = p_anno - 1
          and aliq.tipo_tributo  = 'ICI'
      )
   and (     nvl(instr(p_cod_fiscale,'%'),0)
                                 > 0
        or   nvl(instr(p_cod_fiscale,'_'),0)
                                 > 0
       )
   and p_anno     > 2000
 group by
       decode(utog.tipo_utilizzo
             ,1,3
               ,utog.tipo_utilizzo
             )
 union
select to_number(p_anno)     anno
      ,decode(utog.tipo_utilizzo
             ,1,3
               ,utog.tipo_utilizzo
             )       tipo_aliquota
  from utilizzi_oggetto utog
 where p_anno                  <= to_number(to_char(utog.data_scadenza,'yyyy'))
   and p_anno                  >= utog.anno
   and utog.tipo_tributo        = 'ICI'
   and (    utog.tipo_utilizzo  = 1
        or  utog.tipo_utilizzo between 61 and 99
       )
   and not exists
      (select 1
         from aliquote aliq
        where aliq.tipo_aliquota = decode(utog.tipo_utilizzo
                                         ,1,3
                                           ,utog.tipo_utilizzo
                                         )
          and aliq.anno          = p_anno
          and aliq.tipo_tributo  = 'ICI'
      )
   and (     nvl(instr(p_cod_fiscale,'%'),0)
                                 = 0
        and  nvl(instr(p_cod_fiscale,'_'),0)
                                 = 0
       )
   and utog.oggetto in
      (select ogpr.oggetto
         from oggetti              ogge,
              pratiche_tributo     prtr,
              oggetti_pratica      ogpr,
              oggetti_contribuente ogco
         where ogco.anno||ogco.tipo_rapporto||'S' =
             (select max(b.anno||b.tipo_rapporto||b.flag_possesso)
                from pratiche_tributo c,
                     oggetti_contribuente b,
                     oggetti_pratica a
               where(   c.data_notifica              is not null and
                        c.tipo_pratica||''            = 'A'      and
                        nvl(c.stato_accertamento,'D') = 'D'      and
                        nvl(c.flag_denuncia,' ')      = 'S'      and
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
          and ogge.oggetto              = ogpr.oggetto
          and prtr.tipo_tributo||''     = 'ICI'
          and nvl(prtr.stato_accertamento,'D') = 'D'
          and prtr.pratica              = ogpr.pratica
          and ogpr.oggetto_pratica      = ogco.oggetto_pratica
          and decode(ogco.anno,p_anno,nvl(ogco.mesi_possesso,12),12) >= 0
          and decode(ogco.anno
                    ,p_anno,decode(ogco.flag_esclusione
                                  ,'S',nvl(ogco.mesi_esclusione,nvl(ogco.mesi_possesso,12))
                                      ,nvl(ogco.mesi_esclusione,0)
                                  )
                           ,decode(ogco.flag_esclusione,'S',12,0)
                    )                   <=
              decode(ogco.anno,p_anno,nvl(ogco.mesi_possesso,12),12)
          and ogco.flag_possesso         = 'S'
          and ogco.cod_fiscale           = p_cod_fiscale
          and p_ravvedimento             = 'N'
        union
       select ogpr.oggetto
         from oggetti              ogge,
              pratiche_tributo     prtr,
              oggetti_pratica      ogpr,
              oggetti_contribuente ogco
        where ogge.oggetto               = ogpr.oggetto
         and (   ( prtr.tipo_pratica||''  = 'D'
               and ogco.flag_possesso    is null
               and p_ravvedimento         = 'N' )
              or ( prtr.tipo_pratica||''  = 'V'
               and prtr.tipo_evento       = nvl(p_tipo_evento,prtr.tipo_evento)
               and p_ravvedimento         = 'S' )
             )
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
                   )                    <=
             decode(ogco.anno,p_anno,nvl(ogco.mesi_possesso,12),12)
         and decode(ogco.anno,p_anno,nvl(ogco.mesi_possesso,12),12) >= 0
         and ogco.cod_fiscale            = p_cod_fiscale
      )
 group by
       decode(utog.tipo_utilizzo
             ,1,3
               ,utog.tipo_utilizzo
             )
 union
select to_number(p_anno) - 1     anno
      ,decode(utog.tipo_utilizzo
             ,1,3
               ,utog.tipo_utilizzo
             )       tipo_aliquota
  from utilizzi_oggetto utog
 where p_anno - 1              <= to_number(to_char(utog.data_scadenza,'yyyy'))
   and p_anno - 1              >= utog.anno
   and utog.tipo_tributo        = 'ICI'
   and (    utog.tipo_utilizzo  = 1
        or  utog.tipo_utilizzo between 61 and 99
       )
   and not exists
      (select 1
         from aliquote aliq
        where aliq.tipo_aliquota = decode(utog.tipo_utilizzo
                                         ,1,3
                                           ,utog.tipo_utilizzo
                                         )
          and aliq.anno          = p_anno - 1
          and aliq.tipo_tributo  = 'ICI'
      )
   and (     nvl(instr(p_cod_fiscale,'%'),0)
                                 = 0
        and  nvl(instr(p_cod_fiscale,'_'),0)
                                 = 0
       )
   and utog.oggetto in
      (select ogpr.oggetto
         from oggetti              ogge,
              pratiche_tributo     prtr,
              oggetti_pratica      ogpr,
              oggetti_contribuente ogco
         where ogco.anno||ogco.tipo_rapporto||'S' =
             (select max(b.anno||b.tipo_rapporto||b.flag_possesso)
                from pratiche_tributo c,
                     oggetti_contribuente b,
                     oggetti_pratica a
               where(   c.data_notifica              is not null and
                        c.tipo_pratica||''            = 'A'      and
                        nvl(c.stato_accertamento,'D') = 'D'      and
                        nvl(c.flag_denuncia,' ')      = 'S'      and
                        c.anno                        < p_anno
                     or (c.data_notifica is null and c.tipo_pratica||'' = 'D')
                    )
                and c.anno           <= p_anno
                and c.tipo_tributo||''
                                      = prtr.tipo_tributo
                and c.pratica         = a.pratica
                and a.oggetto_pratica = b.oggetto_pratica
                and a.oggetto         = ogpr.oggetto
                and b.tipo_rapporto  in ('C','D','E')
                and b.cod_fiscale     = ogco.cod_fiscale
             )
          and ogge.oggetto            = ogpr.oggetto
          and prtr.tipo_tributo||''   = 'ICI'
          and nvl(prtr.stato_accertamento,'D') = 'D'
          and prtr.pratica            = ogpr.pratica
          and ogpr.oggetto_pratica    = ogco.oggetto_pratica
          and decode(ogco.anno,p_anno,nvl(ogco.mesi_possesso,12),12) >= 0
          and decode(ogco.anno
                    ,p_anno,decode(ogco.flag_esclusione
                                  ,'S',nvl(ogco.mesi_esclusione,nvl(ogco.mesi_possesso,12))
                                      ,nvl(ogco.mesi_esclusione,0)
                                  )
                           ,decode(ogco.flag_esclusione,'S',12,0)
                    )                 <=
              decode(ogco.anno,p_anno,nvl(ogco.mesi_possesso,12),12)
          and ogco.flag_possesso       = 'S'
          and ogco.cod_fiscale         = p_cod_fiscale
          and p_ravvedimento           = 'N'
        union
       select ogpr.oggetto
         from oggetti ogge,
              pratiche_tributo prtr,
              oggetti_pratica ogpr,
              oggetti_contribuente ogco
        where ogge.oggetto             = ogpr.oggetto
         and (    ( prtr.tipo_pratica||''
                                       = 'D'
               and ogco.flag_possesso is null
               and p_ravvedimento      = 'N' )
              or ( prtr.tipo_pratica||'' = 'V'
               and prtr.tipo_evento    = nvl(p_tipo_evento,prtr.tipo_evento)
               and p_ravvedimento      = 'S' )
             )
         and prtr.tipo_tributo||''     = 'ICI'
         and nvl(prtr.stato_accertamento,'D') = 'D'
         and prtr.pratica              = ogpr.pratica
         and ogpr.oggetto_pratica      = ogco.oggetto_pratica
         and ogco.anno                 = p_anno
         and decode(ogco.anno
                   ,p_anno,decode(ogco.flag_esclusione
                                 ,'S',nvl(ogco.mesi_esclusione,nvl(ogco.mesi_possesso,12))
                                     ,nvl(ogco.mesi_esclusione,0)
                                 )
                          ,decode(ogco.flag_esclusione,'S',12,0)
                   )                  <=
             decode(ogco.anno,p_anno,nvl(ogco.mesi_possesso,12),12)
         and decode(ogco.anno,p_anno,nvl(ogco.mesi_possesso,12),12) >= 0
         and ogco.cod_fiscale          = p_cod_fiscale
      )
   and p_anno                          > 2000
 group by
       decode(utog.tipo_utilizzo
             ,1,3
               ,utog.tipo_utilizzo
             )
 order by
       1
      ,2
;
-- AB 8/6/2015 cursore per controllo che esistano le aliquote
-- per le aliquote_ogco dell`anno di imposta
--
cursor sel_chk_alog (p_anno         number
                    ,p_cod_fiscale  varchar2
                    ,p_ravvedimento varchar2
                    ,p_tipo_evento  varchar2
                    ) is
select to_number(p_anno)     anno
      ,tipo_aliquota
  from aliquote_ogco alog
 where p_anno                  <= to_number(to_char(alog.al,'yyyy'))
   and p_anno                  >= to_number(to_char(alog.dal,'yyyy'))
   and alog.tipo_tributo        = 'ICI'
   and not exists
      (select 1
         from aliquote aliq
        where aliq.tipo_aliquota = alog.tipo_aliquota
          and aliq.anno          = p_anno
          and aliq.tipo_tributo  = 'ICI'
      )
   and (     nvl(instr(p_cod_fiscale,'%'),0)
                                 > 0
        or   nvl(instr(p_cod_fiscale,'_'),0)
                                 > 0
       )
 group by alog.tipo_aliquota
 union
select to_number(p_anno)     anno
      ,tipo_aliquota
  from aliquote_ogco alog
 where p_anno                  <= to_number(to_char(alog.al,'yyyy'))
   and p_anno                  >= to_number(to_char(alog.dal,'yyyy'))
   and alog.tipo_tributo        = 'ICI'
   and not exists
      (select 1
         from aliquote aliq
        where aliq.tipo_aliquota = alog.tipo_aliquota
          and aliq.anno          = p_anno
          and aliq.tipo_tributo  = 'ICI'
      )
   and (     nvl(instr(p_cod_fiscale,'%'),0)
                                 = 0
        and  nvl(instr(p_cod_fiscale,'_'),0)
                                 = 0
       )
   and (alog.cod_fiscale,alog.oggetto_pratica) in
      (select ogco.cod_fiscale,ogco.oggetto_pratica
         from oggetti              ogge,
              pratiche_tributo     prtr,
              oggetti_pratica      ogpr,
              oggetti_contribuente ogco
         where ogco.anno||ogco.tipo_rapporto||'S' =
             (select max(b.anno||b.tipo_rapporto||b.flag_possesso)
                from pratiche_tributo c,
                     oggetti_contribuente b,
                     oggetti_pratica a
               where(   c.data_notifica              is not null and
                        c.tipo_pratica||''            = 'A'      and
                        nvl(c.stato_accertamento,'D') = 'D'      and
                        nvl(c.flag_denuncia,' ')      = 'S'      and
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
          and ogge.oggetto              = ogpr.oggetto
          and prtr.tipo_tributo||''     = 'ICI'
          and nvl(prtr.stato_accertamento,'D') = 'D'
          and prtr.pratica              = ogpr.pratica
          and ogpr.oggetto_pratica      = ogco.oggetto_pratica
          and decode(ogco.anno,p_anno,nvl(ogco.mesi_possesso,12),12) >= 0
          and decode(ogco.anno
                    ,p_anno,decode(ogco.flag_esclusione
                                  ,'S',nvl(ogco.mesi_esclusione,nvl(ogco.mesi_possesso,12))
                                      ,nvl(ogco.mesi_esclusione,0)
                                  )
                           ,decode(ogco.flag_esclusione,'S',12,0)
                    )                   <=
              decode(ogco.anno,p_anno,nvl(ogco.mesi_possesso,12),12)
          and ogco.flag_possesso         = 'S'
          and ogco.cod_fiscale           = p_cod_fiscale
          and p_ravvedimento             = 'N'
        union
       select ogco.cod_fiscale,ogco.oggetto_pratica
         from oggetti              ogge,
              pratiche_tributo     prtr,
              oggetti_pratica      ogpr,
              oggetti_contribuente ogco
        where  ogge.oggetto               = ogpr.oggetto
         and (   ( prtr.tipo_pratica||''  = 'D'
               and ogco.flag_possesso    is null
               and p_ravvedimento         = 'N')
              or ( prtr.tipo_pratica||''  = 'V'
               and prtr.tipo_evento     = nvl(a_tipo_evento,prtr.tipo_evento)
               and p_ravvedimento         = 'S')
             )
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
                   )                    <=
             decode(ogco.anno,p_anno,nvl(ogco.mesi_possesso,12),12)
         and decode(ogco.anno,p_anno,nvl(ogco.mesi_possesso,12),12) >= 0
         and ogco.cod_fiscale            = p_cod_fiscale
      )
 group by alog.tipo_aliquota
;
BEGIN
-- Controllo iniziale di eventuali aliquote mancanti in utilizzi oggetto.
--
     w_aliquote_mancanti := '';
     w_anno_utog_prec    := 0;
     FOR rec_chk_utog in sel_chk_utog(a_anno_rif,a_cod_fiscale
                                     ,a_ravvedimento,a_tipo_evento)
    LOOP
        if w_anno_utog_prec = 0 then
           w_aliquote_mancanti := 'Tipi Aliquote in Utilizzi Oggetto Mancanti per l`anno '||
                                  to_char(rec_chk_utog.anno)||': ';
           w_anno_utog_prec    := rec_chk_utog.anno;
        elsif rec_chk_utog.anno <> w_anno_utog_prec then
           w_aliquote_mancanti := w_aliquote_mancanti||'; per l`anno '||
                                  to_char(rec_chk_utog.anno)||': ';
           w_anno_utog_prec    := rec_chk_utog.anno;
        else
           w_aliquote_mancanti := w_aliquote_mancanti||', ';
        end if;
        w_aliquote_mancanti    := w_aliquote_mancanti||to_char(rec_chk_utog.tipo_aliquota);
     END LOOP;
     if length(w_aliquote_mancanti) > 0 then
        RAISE_APPLICATION_ERROR(-20999,w_aliquote_mancanti);
     end if;
--
-- Controllo iniziale di eventuali aliquote mancanti in aliquote_ogco
--
      w_aliquote_mancanti := '';
      w_anno_alog_prec    := 0;
      FOR rec_chk_alog in sel_chk_alog(a_anno_rif,a_cod_fiscale
                                      ,a_ravvedimento,a_tipo_evento)
      LOOP
         if w_anno_alog_prec = 0 then
            w_aliquote_mancanti := 'Tipi Aliquote in Aliquote particolari (ALOG) Mancanti per l`anno '||
                                   to_char(rec_chk_alog.anno)||': ';
            w_anno_alog_prec    := rec_chk_alog.anno;
         elsif rec_chk_alog.anno <> w_anno_alog_prec then
            w_aliquote_mancanti := w_aliquote_mancanti||'; per l`anno '||
                                   to_char(rec_chk_alog.anno)||': ';
            w_anno_alog_prec    := rec_chk_alog.anno;
         else
            w_aliquote_mancanti := w_aliquote_mancanti||', ';
         end if;
         w_aliquote_mancanti    := w_aliquote_mancanti||to_char(rec_chk_alog.tipo_aliquota);
      END LOOP;
      if length(w_aliquote_mancanti) > 0 then
         RAISE_APPLICATION_ERROR(-20999,w_aliquote_mancanti);
      end if;
  w_anno_s := lpad(to_char(a_anno_rif),4,'0');
  w_cod_fiscale := ' ';
  BEGIN
    delete periodi_imponibile peim
     where anno      = a_anno_rif
       and cod_fiscale   like a_cod_fiscale
       and exists (select 'x'
                     from oggetti_pratica  ogpr
                        , rapporti_tributo ratr
                        , pratiche_tributo prtr
                        , oggetti_contribuente  ogco
                    where ogco.cod_fiscale      = peim.cod_fiscale
                      and ogco.oggetto_pratica  = peim.oggetto_pratica
                      and ogpr.oggetto_pratica  = ogco.oggetto_pratica
                      and ogpr.pratica          = prtr.pratica
                      and ratr.cod_fiscale      = ogco.cod_fiscale
                      and ratr.pratica          = prtr.pratica
                      and prtr.tipo_tributo||'' = 'ICI'
                      and (  ( prtr.tipo_pratica ||''  = 'V'
                           and prtr.tipo_evento        = nvl(a_tipo_evento,prtr.tipo_evento)
                           and a_ravvedimento          = 'S' )
                          or ( prtr.tipo_pratica in ('D','A')
                            and a_ravvedimento = 'N' )
                          )
                  )
    ;
  EXCEPTION
    WHEN others THEN
         w_errore := 'Errore in cancellazione Periodi Imponibile '||' CF: '||a_cod_fiscale;
         RAISE errore;
  END;
  BEGIN
    delete detrazioni_imponibile deim
     where anno      = a_anno_rif
       and cod_fiscale   like a_cod_fiscale
       and exists (select 'x'
                     from oggetti_pratica  ogpr
                        , rapporti_tributo ratr
                        , pratiche_tributo prtr
                        , oggetti_imposta  ogim
                    where ogim.cod_fiscale      = deim.cod_fiscale
                      and ogim.oggetto_pratica  = deim.oggetto_pratica
                      and ogpr.oggetto_pratica  = ogim.oggetto_pratica
                      and ogpr.pratica          = prtr.pratica
                      and ratr.cod_fiscale      = ogim.cod_fiscale
                      and ratr.pratica          = prtr.pratica
                      and prtr.tipo_tributo||'' = 'ICI'
                      and (  ( prtr.tipo_pratica ||''  = 'V'
                           and prtr.tipo_evento        = nvl(a_tipo_evento,prtr.tipo_evento)
                           and a_ravvedimento = 'S' )
                          or ( ogim.flag_calcolo = 'S'
                           and a_ravvedimento = 'N'))
                  )
    ;
  EXCEPTION
    WHEN others THEN
         w_errore := 'Errore in cancellazione Detrazioni Imponibile ';
         RAISE errore;
  END;
  BEGIN
    delete oggetti_ogim ogog
     where anno      = a_anno_rif
       and cod_fiscale   like a_cod_fiscale
       and exists (select 'x'
                     from oggetti_pratica  ogpr
                        , rapporti_tributo ratr
                        , pratiche_tributo prtr
                        , oggetti_imposta  ogim
                    where ogim.cod_fiscale      = ogog.cod_fiscale
                      and ogim.oggetto_pratica  = ogog.oggetto_pratica
                      and ogim.anno             = ogog.anno
                      and ogpr.oggetto_pratica  = ogim.oggetto_pratica
                      and ogpr.pratica          = prtr.pratica
                      and ratr.cod_fiscale      = ogim.cod_fiscale
                      and ratr.pratica          = prtr.pratica
                      and prtr.tipo_tributo||'' = 'ICI'
                      and (  ( prtr.tipo_pratica ||''  = 'V'
                           and prtr.tipo_evento        = nvl(a_tipo_evento,prtr.tipo_evento)
                           and nvl(prtr.stato_accertamento,'D')  ='D'
                           and a_ravvedimento = 'S' )
                          or ( ogim.flag_calcolo = 'S'
                            and a_ravvedimento = 'N'))
                  )
    ;
  EXCEPTION
    WHEN others THEN
         w_errore := 'Errore in cancellazione Oggetti OGIM ';
         RAISE errore;
  END;
  BEGIN
    delete oggetti_imposta ogim
     where anno      = a_anno_rif
       and cod_fiscale   like a_cod_fiscale
       and exists (select 'x'
                     from oggetti_pratica ogpr,
                          rapporti_tributo ratr,
                          pratiche_tributo prtr
                    where ogpr.oggetto_pratica  = ogim.oggetto_pratica
                      and ogpr.pratica         = prtr.pratica
                      and ratr.cod_fiscale     = ogim.cod_fiscale
                      and ratr.pratica          = prtr.pratica
                      and prtr.tipo_tributo||''   = 'ICI'
                      and (  ( prtr.tipo_pratica ||''  = 'V'
                           and prtr.tipo_evento        = nvl(a_tipo_evento,prtr.tipo_evento)
                           and nvl(prtr.stato_accertamento,'D')  ='D'
                           and a_ravvedimento = 'S' )
                          or ( ogim.flag_calcolo = 'S'
                           and a_ravvedimento = 'N'))
                  )
    ;
  EXCEPTION
    WHEN others THEN
         w_errore := 'Errore in cancellazione Oggetti Imposta ';
         RAISE errore;
  END;
  BEGIN
     if F_DETERMINA_ALIQUOTE_ICI(a_anno_rif,
        w_aliquota_base,w_aliquota_base_prec,w_aliquota_base_erar,w_tipo_al_base,w_tipo_al_base_prec,
        w_al_ab_principale,w_al_ab_principale_prec,w_al_ab_principale_erar,w_tipo_al_ab_principale,w_tipo_al_ab_principale_prec,
        w_al_affittato,w_al_affittato_prec,w_al_affittato_erar,w_tipo_al_affittato,w_tipo_al_affittato_prec,
        w_al_non_affittato,w_al_non_affittato_prec,w_al_non_affittato_erar,w_tipo_al_non_affittato,w_tipo_al_non_affittato_prec,
        w_al_seconda_casa,w_al_seconda_casa_prec,w_al_seconda_casa_erar,w_tipo_al_seconda_casa,w_tipo_al_seconda_casa_prec,
        w_al_negozio,w_al_negozio_prec,w_al_negozio_erar,w_tipo_al_negozio,w_tipo_al_negozio_prec,
        w_al_d,w_al_d_prec,w_al_d_erar,w_tipo_al_d,w_tipo_al_d_prec,
        w_al_d10,w_al_d10_prec,w_al_d10_erar,w_tipo_al_d10,w_tipo_al_d10_prec,
        w_al_terreni,w_al_terreni_prec,w_al_terreni_erar,w_tipo_al_terreni,w_tipo_al_terreni_Prec,
        w_al_terreni_rid,w_al_terreni_rid_prec,w_al_terreni_rid_erar,
        w_tipo_al_terreni_rid,w_tipo_al_terreni_rid_prec,
        w_al_aree,w_al_aree_prec,w_al_aree_erar,w_tipo_al_aree,w_tipo_al_aree_prec,
        w_aliquota_base_std,w_al_ab_principale_std,w_al_affittato_std,w_al_non_affittato_std,w_al_seconda_casa_std,
        w_al_negozio_std,w_al_d_std,w_al_d10_std,w_al_terreni_rid_std,
        w_perc_acconto,w_errore) < 0 then
              w_errore := nvl(w_errore,'Problemi sulle aliquote');
              RAISE ERRORE;
     end if;
  END;
   BEGIN
     select flag_pertinenze
       into w_flag_pertinenze
       from aliquote
      where flag_ab_principale = 'S'
        and anno = a_anno_rif
        and tipo_tributo = 'ICI'
     ;
   EXCEPTION
     WHEN NO_DATA_FOUND OR TOO_MANY_ROWS THEN
        w_errore := 'Errore in Ricerca Flag Pertinenze';
        RAISE ERRORE;
   END;
   FOR rec_ogco IN sel_ogco LOOP
      --DBMS_OUTPUT.PUT_LINE('Calcolo imposta ICI - Oggetto pratica: '||rec_ogco.oggetto_pratica_ogpr);
      w_cod_fiscale     := rec_ogco.cod_fiscale_ogco;
      w_abitazioni      := 0;
      w_detrazioni      := 0;
      w_altri_1         := 0;
      w_altri_2         := 0;
      w_altri_3         := 0;
      w_altri_4         := 0;
      w_abitazioni_1s   := 0;
      w_detrazioni_1s   := 0;
      w_altri_1_1s      := 0;
      w_altri_2_1s      := 0;
      w_altri_3_1s      := 0;
      w_altri_4_1s      := 0;
      wd_abitazioni     := 0;
      wd_detrazioni     := 0;
      wd_altri_1        := 0;
      wd_altri_2        := 0;
      wd_altri_3        := 0;
      wd_altri_4        := 0;
      wd_abitazioni_1s  := 0;
      wd_detrazioni_1s  := 0;
      wd_altri_1_1s     := 0;
      wd_altri_2_1s     := 0;
      wd_altri_3_1s     := 0;
      wd_altri_4_1s     := 0;
      w_mesi_possesso_1s   := rec_ogco.mesi_possesso_1sem;
      w_mesi_riduzione_1s  := 0;
      w_mesi_al_ridotta_1s := 0;
      w_dettaglio_ogim     := '';
      w_flag_possesso      := rec_ogco.flag_possesso;
      if w_flag_possesso is null then
         w_flag_riduzione  := null;
         w_flag_esclusione := null;
         w_flag_al_ridotta := null;
      else
         w_flag_riduzione  := rec_ogco.flag_riduzione;
         w_flag_esclusione := rec_ogco.flag_esclusione;
         w_flag_al_ridotta := rec_ogco.flag_al_ridotta;
      end if;
      w_mesi_possesso      := rec_ogco.mesi_possesso;
      w_da_mese_possesso   := rec_ogco.da_mese_possesso;
      if nvl(rec_ogco.mesi_esclusione,0) > rec_ogco.mesi_possesso then
         w_mesi_esclusione := w_mesi_possesso;
      else
         w_mesi_esclusione := rec_ogco.mesi_esclusione;
      end if;
      IF nvl(w_mesi_possesso,0) - nvl(w_mesi_esclusione,0) <= 0 THEN
         BEGIN
            if rec_ogco.tipo_oggetto in (1,2) then
               w_al         := w_aliquota_base;
               w_tipo_al    := w_tipo_al_base;
            elsif rec_ogco.tipo_oggetto = 3 and
                 (rec_ogco.flag_ab_principale = 'S' or nvl(rec_ogco.detrazione,0)!= 0) and
                 (w_flag_pertinenze = 'S' or w_flag_pertinenze is null and
                                             rec_ogco.categoria_catasto_ogpr like 'A%') THEN
               w_al         := w_al_ab_principale;
               w_tipo_al    := w_tipo_al_ab_principale;
            elsif rec_ogco.categoria_catasto_ogpr in ('A09','A08','A07','A06','A05',
                                                      'A04','A03','A02','A01') then
               w_al         := w_al_seconda_casa;
               w_tipo_al    := w_tipo_al_seconda_casa;
            elsif rec_ogco.categoria_catasto_ogpr = 'C01' then
               w_al         := w_al_negozio;
               w_tipo_al    := w_tipo_al_negozio;
            elsif rec_ogco.categoria_catasto_ogpr in ('D12','D11','D09','D08','D07','D06','D05',
                                                      'D04','D03','D02','D01') then
               w_al         := w_al_d;
               w_tipo_al    := w_tipo_al_d;
            elsif rec_ogco.categoria_catasto_ogpr ='D10' then
               w_al         := w_al_d10;
               w_tipo_al    := w_tipo_al_d10;
            else
               w_al         := w_aliquota_base;
               w_tipo_al    := w_tipo_al_base;
            end if;
            if rec_ogco.tipo_pratica = 'V' then
               w_flag_calcolo := null;
            else
               w_flag_calcolo := 'S';
            end if;
            --
            -- Nota: non modificato perche' non si tratta di aliquota acconto
            w_al := F_ALIQUOTA_ALCA(a_anno_rif,w_tipo_al,rec_ogco.categoria_catasto_ogpr,w_al
                                   ,rec_ogco.oggetto_pratica_ogpr,rec_ogco.cod_fiscale_ogco,'ICI');
            insert into oggetti_imposta
                  (cod_fiscale,anno,oggetto_pratica
                  ,imposta,imposta_acconto
                  ,imposta_dovuta,imposta_dovuta_acconto
                  ,imposta_erariale,imposta_erariale_acconto
                  ,imposta_erariale_dovuta,imposta_erariale_dovuta_acc
                  ,tipo_aliquota,aliquota
                  ,flag_calcolo,utente
                  ,tipo_tributo
                  )
            values (rec_ogco.cod_fiscale_ogco,a_anno_rif,rec_ogco.oggetto_pratica_ogpr
                   ,0,0
                   ,0,0
                   ,0,0
                   ,0,0
                   ,w_tipo_al,w_al
                   ,w_flag_calcolo,a_utente
                   ,'ICI'
                   )
            ;
         EXCEPTION
            WHEN others THEN
               w_errore := 'Errore in inserimento Oggetti Imposta (A3) di '||
                           rec_ogco.cod_fiscale_ogco;
              RAISE errore;
         END;
      ELSE
         if nvl(rec_ogco.mesi_aliquota_ridotta,0) > w_mesi_possesso - nvl(w_mesi_esclusione,0) then
            w_mesi_al_ridotta := w_mesi_possesso - nvl(w_mesi_esclusione,0);
         else
            w_mesi_al_ridotta := rec_ogco.mesi_aliquota_ridotta;
         end if;
         if nvl(rec_ogco.mesi_riduzione,0) > w_mesi_possesso - nvl(w_mesi_esclusione,0) then
            w_mesi_riduzione  := w_mesi_possesso - nvl(w_mesi_esclusione,0);
         else
            w_mesi_riduzione  := rec_ogco.mesi_riduzione;
         end if;
         -- I dati per anno precedente l'anno di denuncia sono significativi solo se l'anno d'imposta e' uguale a quello di denuncia
         -- e solo se  il flag possesso e' nullo  (Piero 18/05/2006)
         if rec_ogco.anno_ogco = a_anno_rif and w_flag_possesso is null then
            BEGIN
               select ltrim(max(nvl(ogco.flag_possesso,' ')))
                     ,substr(max(nvl(ogco.flag_possesso,' ')||ogco.flag_riduzione),2,1)
                     ,substr(max(nvl(ogco.flag_possesso,' ')||ogco.flag_esclusione),2,1)
                     ,substr(max(nvl(ogco.flag_possesso,' ')||ogco.flag_al_ridotta),2,1)
                     ,substr(max(nvl(ogco.flag_possesso,' ')||ogco.flag_ab_principale),2,1)
                 into w_flag_possesso_prec
                     ,w_flag_riduzione_prec
                     ,w_flag_esclusione_prec
                     ,w_flag_al_ridotta_Prec
                     ,w_flag_ab_pric_Prec
                 from oggetti_contribuente      ogco
                     ,oggetti_pratica           ogpr
                     ,pratiche_tributo          prtr
                where ogco.cod_fiscale                        = rec_ogco.cod_fiscale_ogco
                  and ogpr.oggetto                            = rec_ogco.oggetto_ogpr
                  and ogpr.oggetto_pratica                    = ogco.oggetto_pratica
                  and prtr.pratica                            = ogpr.pratica
                  and prtr.tipo_tributo||''                   = 'ICI'
                  and prtr.anno                               < rec_ogco.anno_ogco
                  and ogco.anno||ogco.tipo_rapporto||nvl(ogco.flag_possesso,'N')
                                                              =
                     (select max(b.anno||b.tipo_rapporto||nvl(b.flag_possesso,'N'))
                        from pratiche_tributo     c,
                             oggetti_contribuente b,
                             oggetti_pratica      a
                       where(    c.data_notifica             is not null
                             and c.tipo_pratica||''            = 'A'
                             and nvl(c.stato_accertamento,'D') = 'D'
                             and nvl(c.flag_denuncia,' ')      = 'S'
                             or  c.data_notifica              is null
                             and c.tipo_pratica||''            = 'D'
                            )
                         and c.pratica                         = a.pratica
                         and a.oggetto_pratica                 = b.oggetto_pratica
                         and c.tipo_tributo||''                = 'ICI'
                         and nvl(c.stato_accertamento,'D')     = 'D'
                         and c.anno                            < rec_ogco.anno_ogco
                         and b.cod_fiscale                     = ogco.cod_fiscale
                         and a.oggetto                         = rec_ogco.oggetto_ogpr
                     )
                 group by rec_ogco.oggetto_ogpr
               ;
            EXCEPTION
               WHEN NO_DATA_FOUND THEN
                  w_flag_possesso_prec   := null;
                  w_flag_riduzione_prec  := null;
                  w_flag_esclusione_prec := null;
                  w_flag_al_ridotta_prec := null;
                  w_flag_ab_pric_Prec    := null;
            END;
         else
             w_flag_possesso_prec := null;
         end if;
         if w_flag_possesso_prec is null then
            w_flag_riduzione_prec  := null;
            w_flag_esclusione_prec := null;
            w_flag_al_ridotta_prec := null;
            w_flag_ab_pric_Prec    := null;
         end if;
         dbms_output.put_line ('prima di det '||w_flag_possesso||'$'|| w_flag_possesso_prec||'$'|| a_anno_rif||'$'|| w_mesi_possesso||'$'||w_mesi_esclusione||'$'|| w_mesi_possesso_1s||'$'||
                                     w_data_inizio_possesso||'$'|| w_data_fine_possesso||'$'|| w_data_inizio_possesso_1s||'$'|| w_data_fine_possesso_1s||'$'|| w_da_mese_possesso);

         determina_mesi_possesso_ici(w_flag_possesso, w_flag_possesso_prec, a_anno_rif, w_mesi_possesso - nvl(w_mesi_esclusione,0) , w_mesi_possesso_1s,
                                     w_data_inizio_possesso, w_data_fine_possesso, w_data_inizio_possesso_1s, w_data_fine_possesso_1s, w_da_mese_possesso);
         dbms_output.put_line ('dopo di det '||w_flag_possesso||'$'|| w_flag_possesso_prec||'$'|| a_anno_rif||'$'|| w_mesi_possesso||'$'||w_mesi_esclusione||'$'|| w_mesi_possesso_1s||'$'||
                                     w_data_inizio_possesso||'$'|| w_data_fine_possesso||'$'|| w_data_inizio_possesso_1s||'$'|| w_data_fine_possesso_1s||'$'|| w_da_mese_possesso);
         w_mesi_possesso_2s := w_mesi_possesso - w_mesi_possesso_1s;
         if w_flag_esclusione = 'S' then
            if w_mesi_esclusione > w_mesi_possesso_2s then
               w_mesi_esclusione_1s  := w_mesi_esclusione - w_mesi_possesso_2s;
            else
               w_mesi_esclusione_1s  := 0;
            end if;
         else
            if w_flag_esclusione_prec = 'S' then
                if w_mesi_esclusione > w_mesi_possesso_1s then
                  w_mesi_esclusione_1s  := w_mesi_possesso_1s;
                else
                  w_mesi_esclusione_1s := w_mesi_esclusione;
                end if;
            else
                if w_mesi_esclusione > w_mesi_possesso_2s then
                      w_mesi_esclusione_1s  := w_mesi_esclusione - w_mesi_possesso_2s;
                   else
                   w_mesi_esclusione_1s  := 0;
                end if;
            end if;
         end if;
         w_mesi_esclusione_2s := w_mesi_esclusione - w_mesi_esclusione_1s;
         if w_flag_riduzione = 'S' then
            if w_mesi_riduzione > (w_mesi_possesso_2s - w_mesi_esclusione_2s) then
               w_mesi_riduzione_1s  := w_mesi_riduzione - (w_mesi_possesso_2s - w_mesi_esclusione_2s);
            else
               w_mesi_riduzione_1s  := 0;
            end if;
         else
            if w_flag_riduzione_prec = 'S' then
               if w_mesi_riduzione > (w_mesi_possesso_1s - w_mesi_esclusione_1s) then
                  w_mesi_riduzione_1s  := (w_mesi_possesso_1s - w_mesi_esclusione_1s);
               else
                  w_mesi_riduzione_1s := w_mesi_riduzione;
               end if;
            else
               if w_mesi_riduzione > (w_mesi_possesso_2s - w_mesi_esclusione_2s) then
                  w_mesi_riduzione_1s  := w_mesi_riduzione - (w_mesi_possesso_2s - w_mesi_esclusione_2s);
               else
                  w_mesi_riduzione_1s  := 0;
               end if;
            end if;
         end if;
         if w_flag_al_ridotta = 'S' then
            if w_mesi_al_ridotta > (w_mesi_possesso_2s - w_mesi_esclusione_2s) then
               w_mesi_al_ridotta_1s  := w_mesi_al_ridotta - (w_mesi_possesso_2s - w_mesi_esclusione_2s);
            else
              w_mesi_riduzione_1s  := 0;
            end if;
         else
            if w_flag_al_ridotta_prec = 'S' then
               if w_mesi_al_ridotta > (w_mesi_possesso_1s - w_mesi_esclusione_1s) then
                  w_mesi_al_ridotta_1s  := (w_mesi_possesso_1s - w_mesi_esclusione_1s);
               else
                  w_mesi_al_ridotta_1s := w_mesi_al_ridotta;
               end if;
            else
               if w_mesi_al_ridotta > (w_mesi_possesso_2s - w_mesi_esclusione_2s) then
                  w_mesi_al_ridotta_1s  := w_mesi_al_ridotta - (w_mesi_possesso_2s - w_mesi_esclusione_2s);
               else
                  w_mesi_al_ridotta_1s  := 0;
               end if;
            end if;
         end if;
         if nvl(w_mesi_esclusione_1s,0) > nvl(w_mesi_possesso_1s,0) then
            w_mesi_esclusione_1s := w_mesi_possesso_1s;
         end if;
         if nvl(w_mesi_riduzione_1s,0) > nvl(w_mesi_possesso_1s,0) - nvl(w_mesi_esclusione_1s,0) then
            w_mesi_riduzione_1s := w_mesi_possesso_1s - nvl(w_mesi_esclusione_1s,0);
         end if;
         if nvl(w_mesi_al_ridotta_1s,0) > nvl(w_mesi_possesso_1s,0) - nvl(w_mesi_esclusione_1s,0) then
            w_mesi_al_ridotta_1s := w_mesi_possesso_1s - nvl(w_mesi_esclusione_1s,0);
         end if;
         if rec_ogco.anno_ogco     < a_anno_rif then
            w_flag_possesso_prec   := w_flag_possesso;
            w_flag_riduzione_prec  := w_flag_riduzione;
            w_flag_esclusione_prec := w_flag_esclusione;
            w_flag_al_ridotta_prec := w_flag_al_ridotta;
         end if;
         if a_anno_rif > 2000 then
            w_perc_acconto := 100;
            BEGIN
               select decode(ogco.anno,a_anno_rif - 1,nvl(ogco.mesi_possesso,12),12),
                      ogco.detrazione
                 into w_mesi_possesso_prec,
                      w_detrazione_prec
                 from oggetti_contribuente      ogco
                where ogco.oggetto_pratica      = rec_ogco.oggetto_ogpr
                  and ogco.cod_fiscale          = rec_ogco.cod_fiscale_ogco
                  and ogco.anno                <= a_anno_rif - 1
               ;
               w_esiste_ogco := 'S';
            EXCEPTION
               WHEN NO_DATA_FOUND THEN
                  w_esiste_ogco := 'N';
            END;
            BEGIN
               select detrazione
                 into w_magg_detrazione_prec
                 from maggiori_detrazioni
                where cod_fiscale = rec_ogco.cod_fiscale_ogco
                  and anno        = a_anno_rif - 1
                  and tipo_tributo = 'ICI'
               ;
            EXCEPTION
               WHEN NO_DATA_FOUND THEN
                  w_magg_detrazione_prec := null;
            END;
            if w_esiste_ogco = 'N' then
               w_detrazione_prec := w_magg_detrazione_prec;
            else
               if w_detrazione_prec is not null or rec_ogco.flag_ab_principale = 'S' then
                  w_detrazione_prec := f_round(nvl(w_magg_detrazione_prec,w_detrazione_prec)
                                              / w_mesi_possesso_prec * w_mesi_possesso_1s,0);
               end if;
            end if;
         else
            w_perc_acconto             := 90;
            w_mesi_possesso_prec       := rec_ogco.mesi_possesso;
            w_detrazione_prec          := rec_ogco.detrazione;
            w_magg_detrazione_prec     := rec_ogco.magg_detrazione;
         end if;
         w_totale_mesi        := 0;
         w_totale_importo     := 0;
         w_totale_mesi_1s     := 0;
         w_totale_importo_1s  := 0;
         if rec_ogco.tipo_oggetto = 3 then
             BEGIN
               select detraz.det
                 into w_esiste_det_ogco
                from (
                    select 'S' det
                        from detrazioni_ogco deog
                  where deog.cod_fiscale     = w_cod_fiscale
                    and deog.oggetto_pratica = rec_ogco.oggetto_pratica_ogpr
                    and deog.anno            = a_anno_rif
                    and deog.tipo_tributo    = 'ICI'
                    and not exists (select 'S'
                                      from aliquote_ogco alog
                                     where alog.cod_fiscale = w_cod_fiscale
                                       and tipo_tributo = 'ICI'
                                       and alog.oggetto_pratica = rec_ogco.oggetto_pratica_ogpr
                                       and a_anno_rif between to_number(to_char(alog.dal,'yyyy'))
                                                          and to_number(to_char(alog.al,'yyyy'))
                                    )
                  union
                      select 'S'
                        from detrazioni_ogco deog2
                           , oggetti_pratica ogpr2
                       where deog2.cod_fiscale     = w_cod_fiscale
                         and deog2.oggetto_pratica = ogpr2.oggetto_pratica_rif_ap
                         and deog2.anno            = a_anno_rif
                         and deog2.tipo_tributo    = 'ICI'
                         and ogpr2.oggetto_pratica = rec_ogco.oggetto_pratica_ogpr
                         and not exists (select 'S'
                                           from aliquote_ogco alog
                                          where alog.cod_fiscale = w_cod_fiscale
                                            and tipo_tributo = 'ICI'
                                            and alog.oggetto_pratica = deog2.oggetto_pratica
                                            and a_anno_rif between to_number(to_char(alog.dal,'yyyy'))
                                                               and to_number(to_char(alog.al,'yyyy'))
                                    )
                    ) detraz
                    ;
            EXCEPTION
               WHEN NO_DATA_FOUND THEN
                  w_esiste_det_ogco := 'N';
            END;
         end if;
         -- Verifico se l'ogpr a cui la pertinenza è collegata è abitazione principale
         if rec_ogco.tipo_oggetto = 3
           and rec_ogco.categoria_catasto_ogpr like 'C%'
           and rec_ogco.oggetto_pratica_rif_ap is not null then
             begin
                select count(1)
                  into w_conta_rif_ap_ab_principale
                  from oggetti_pratica      ogpr
                     , oggetti_contribuente ogco
                 where ogpr.oggetto_pratica = ogco.oggetto_pratica
                   and ogpr.oggetto_pratica = rec_ogco.oggetto_pratica_rif_ap
                   and (  ogco.flag_ab_principale = 'S'
                       or ogco.detrazione is not null
                         and ogco.anno = a_anno_rif
                       )
                     ;
             EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                      w_conta_rif_ap_ab_principale := 0;
             END;
             if w_conta_rif_ap_ab_principale > 0 then
                 w_rif_ap_ab_principale := 'S';
             else
                 w_rif_ap_ab_principale := 'N';
             end if;
         else
            w_rif_ap_ab_principale := 'N';
         end if;
         IF rec_ogco.tipo_oggetto in (3,55) and
               (rec_ogco.flag_ab_principale = 'S' or
                rec_ogco.detrazione_ogco is not null or
                w_esiste_det_ogco = 'S'
                  or
                w_rif_ap_ab_principale = 'S'  -- Serve per gestire le pertinenze con pertinenza_di
               ) and
               (w_flag_pertinenze = 'S' or
                (w_flag_pertinenze is null and rec_ogco.categoria_catasto_ogpr like 'A%')
               )   THEN
         --
         -- Utilizzo la procedura INSERIMENTO_PERIODI_IMPOSTA al posto della CALCOLO_RIOG_MULTIPLO
         -- la nuova procedura in più di quella precedente salva nella tabella PERIODI_IMPOSTA
         -- i valore dell'oggetto_pratica per i vari periodi dell'anno utilizzato per calcolare il
         -- w_totale_importo e w_totale_importo_1s
         --
         INSERIMENTO_PERIODI_IMPONIBILE(rec_ogco.oggetto_ogpr
                                       ,rec_ogco.valore
                                       ,w_data_inizio_possesso
                                       ,w_data_fine_possesso
                                       ,w_data_inizio_possesso_1s
                                       ,w_data_fine_possesso_1s
                                       ,rec_ogco.moltiplicatore
                                       ,rec_ogco.aliquota_rivalutazione
                                       ,rec_ogco.tipo_oggetto
                                       ,rec_ogco.anno_titr
                                       ,a_anno_rif
                                       ,rec_ogco.imm_storico
                                       ,rec_ogco.oggetto_pratica_ogpr
                                       ,w_cod_fiscale
                                       ,a_utente
                                       ,w_totale_importo
                                       ,w_totale_importo_1s
                                       )
                                       ;
         else
         --
         -- Routine per gestire i Riferimenti Oggetto Multipli. In questa sede viene calcolato
         -- un importo medio tra i vari riferimenti, se esistono. Questo valore va poi utilizzato
         -- per il calcolo imposta. Questa procedura si deve considerare corretta solo se in un anno
         -- viene utilizzata una sola aliquota e questo avviene per terreni, aree e abitazioni principali.
         -- Per i restanti casi non viene utilizzato questo valore, ma viene eseguita una routine apposita
         -- che si incarica di gestire tutte le eventuali eccezioni mese per mese.
         --
         CALCOLO_RIOG_MULTIPLO(rec_ogco.oggetto_ogpr
                              ,rec_ogco.valore
                              ,w_data_inizio_possesso
                              ,w_data_fine_possesso
                              ,w_data_inizio_possesso_1s
                              ,w_data_fine_possesso_1s
                              ,rec_ogco.moltiplicatore
                              ,rec_ogco.aliquota_rivalutazione
                              ,rec_ogco.tipo_oggetto
                              ,rec_ogco.anno_titr
                              ,a_anno_rif
                              ,rec_ogco.imm_storico
                              ,w_totale_importo
                              ,w_totale_importo_1s
                              )
                              ;
         end if;
         IF rec_ogco.tipo_oggetto = 1 THEN
            if a_anno_rif > 2000 then
               w_dep_aliquota       := w_al_terreni_prec;
               w_dep_tipo_aliquota  := w_tipo_al_terreni_prec;
               w_dep_aliquota2      := w_al_terreni_rid_prec;
               w_dep_tipo_aliquota2 := w_tipo_al_terreni_rid_prec;
            else
               w_dep_aliquota       := w_al_terreni;
               w_dep_tipo_aliquota  := w_tipo_al_terreni;
               w_dep_aliquota2      := w_al_terreni_rid;
               w_dep_tipo_aliquota2 := w_tipo_al_terreni_rid;
            end if;
            calcolo_terreni(a_anno_rif,rec_ogco.cod_fiscale_ogco
                           ,rec_ogco.oggetto_pratica_ogpr
                           ,w_totale_importo,w_totale_importo_1s,rec_ogco.valore_d
                           ,w_data_inizio_possesso,w_data_fine_possesso
                           ,w_data_inizio_possesso_1s,w_data_fine_possesso_1s
                           ,w_mesi_possesso - nvl(w_mesi_esclusione,0)
                           ,w_mesi_possesso_1s - nvl(w_mesi_esclusione_1s,0)
                           ,nvl(w_mesi_riduzione,w_mesi_possesso - nvl(w_mesi_esclusione,0))
                           ,nvl(w_mesi_riduzione_1s,w_mesi_possesso_1s -
                            nvl(w_mesi_esclusione_1s,0))
                           ,rec_ogco.perc_possesso
                           ,w_tipo_al_terreni,w_al_terreni
                           ,w_dep_aliquota
                           ,w_tipo_al_terreni_rid,w_al_terreni_rid
                           ,w_dep_aliquota2
                           ,w_al_terreni_erar,w_al_terreni_rid_erar,w_al_terreni_rid_std
                           ,a_utente
                           ,'ICI'
                           );
         ELSIF rec_ogco.tipo_oggetto = 2 THEN
            if a_anno_rif > 2000 then
               w_dep_aliquota      := w_al_aree_prec;
               w_dep_tipo_aliquota := w_tipo_al_aree_prec;
            else
               w_dep_aliquota      := w_al_aree;
               w_dep_tipo_aliquota := w_tipo_al_aree;
            end if;
            calcolo_aree(a_anno_rif,rec_ogco.cod_fiscale_ogco
                        ,rec_ogco.oggetto_pratica_ogpr
                        ,w_totale_importo,w_totale_importo_1s,rec_ogco.valore_d
                        ,w_mesi_possesso - nvl(w_mesi_esclusione,0)
                        ,w_mesi_possesso_1s - nvl(w_mesi_esclusione_1s,0)
                        ,rec_ogco.perc_possesso,w_tipo_al_aree,w_al_aree
                        ,w_dep_aliquota,w_al_aree_erar,a_utente,'ICI'
                        );
         ELSIF rec_ogco.tipo_oggetto = 3 and
               (rec_ogco.flag_ab_principale = 'S' or
                rec_ogco.detrazione_ogco is not null or
            --    (w_flag_ab_pric_Prec = 'S' and
            --     nvl(rec_ogco.flag_ab_principale,'N') = 'N' and
            --    rec_ogco.categoria_catasto_ogpr like 'C%'
            --    ) or   -- Questo serve per gestire le pertinenze che cessano
                w_esiste_det_ogco = 'S'
                  or
                w_rif_ap_ab_principale = 'S'  -- Serve per gestire le pertinenze con pertinenza_di
               ) and
               (w_flag_pertinenze = 'S' or
                (w_flag_pertinenze is null and rec_ogco.categoria_catasto_ogpr like 'A%')
             )   THEN
            if a_anno_rif > 2000 and a_anno_rif < 2012 then
               --
               -- Nota: questa selezione rimane invariata perche' relativa ad
               --       anni < 2012
               --
               w_aliquota1 := F_ALIQUOTA_ALCA(a_anno_rif - 1,w_tipo_al_ab_principale_prec
                                             ,rec_ogco.categoria_catasto_ogpr,w_al_ab_principale_prec
                                             ,rec_ogco.oggetto_pratica_ogpr,rec_ogco.cod_fiscale_ogco,'ICI');
               w_aliquota2 := F_ALIQUOTA_ALCA(a_anno_rif - 1,w_tipo_al_base_prec
                                             ,rec_ogco.categoria_catasto_ogpr,w_aliquota_base_prec
                                             ,rec_ogco.oggetto_pratica_ogpr,rec_ogco.cod_fiscale_ogco,'ICI');
            elsif a_anno_rif >= 2012 then
               --
               -- (VD - 29/12/2016): aggiunto parametro finale 'S' per selezionare l'eventuale aliquota
               --                    base (acconto) per categoria
               w_aliquota1 := F_ALIQUOTA_ALCA(a_anno_rif,w_tipo_al_ab_principale_prec
                                             ,rec_ogco.categoria_catasto_ogpr,w_al_ab_principale_prec
                                             ,rec_ogco.oggetto_pratica_ogpr,rec_ogco.cod_fiscale_ogco,'ICI','S');
               w_aliquota2 := F_ALIQUOTA_ALCA(a_anno_rif ,w_tipo_al_base_prec
                                             ,rec_ogco.categoria_catasto_ogpr,w_aliquota_base_prec
                                             ,rec_ogco.oggetto_pratica_ogpr,rec_ogco.cod_fiscale_ogco,'ICI','S');
            else
               --
               -- Nota: questa selezione rimane invariata perche' relativa ad
               --       anni < 2000
               --
               w_aliquota1 := F_ALIQUOTA_ALCA(a_anno_rif,w_tipo_al_ab_principale
                                             ,rec_ogco.categoria_catasto_ogpr,w_al_ab_principale
                                             ,rec_ogco.oggetto_pratica_ogpr,rec_ogco.cod_fiscale_ogco,'ICI');
               w_aliquota2 := F_ALIQUOTA_ALCA(a_anno_rif,w_tipo_al_base
                                             ,rec_ogco.categoria_catasto_ogpr,w_aliquota_base
                                             ,rec_ogco.oggetto_pratica_ogpr,rec_ogco.cod_fiscale_ogco,'ICI');
            end if;
            ALIQUOTA_ALCA(a_anno_rif,w_tipo_al_ab_principale
                         ,rec_ogco.categoria_catasto_ogpr,w_al_ab_principale
                         ,rec_ogco.oggetto_pratica_ogpr,rec_ogco.cod_fiscale_ogco, 'ICI'
                         ,w_al_ab_principale_ok,w_esiste_alca);
            --
            -- Nota: non modificato perche' non si tratta di aliquota acconto
            w_aliquota_base_ok := F_ALIQUOTA_ALCA(a_anno_rif,w_tipo_al_base
                                                 ,rec_ogco.categoria_catasto_ogpr,w_aliquota_base
                                                 ,rec_ogco.oggetto_pratica_ogpr,rec_ogco.cod_fiscale_ogco,'ICI');
            w_imponibile := f_round(w_totale_importo
                             --       * (w_mesi_possesso) / 12
                                   ,2);
            BEGIN
              if a_anno_rif = 2013 and w_esiste_alca = 'N' then  -- Inserito per la Mini IMU (9/1/14) AB
                 determina_importi_ici(w_totale_importo,rec_ogco.valore_d,
                                       w_al_ab_principale_std,w_aliquota_base_ok,
                                       w_flag_riduzione,rec_ogco.perc_possesso,
                                       w_mesi_possesso - nvl(w_mesi_esclusione,0),
                                       nvl(w_mesi_riduzione,
                                       w_mesi_possesso - nvl(w_mesi_esclusione,0)),
                                       nvl(w_mesi_al_ridotta,
                                       w_mesi_possesso - nvl(w_mesi_esclusione,0)),
                                       100,
                                       nvl(rec_ogco.imm_storico,'N'),a_anno_rif,
                                       w_abitazioni_std, wd_abitazioni_std
                                      );
              else
                 w_abitazioni_std   := null;
                 wd_abitazioni_std  := null;
              end if;
              determina_importi_ici(w_totale_importo,rec_ogco.valore_d,
                                    w_al_ab_principale_ok,w_aliquota_base_ok,
                                    w_flag_riduzione,rec_ogco.perc_possesso,
                                    w_mesi_possesso - nvl(w_mesi_esclusione,0),
                                    nvl(w_mesi_riduzione,
                                    w_mesi_possesso - nvl(w_mesi_esclusione,0)),
                                    nvl(w_mesi_al_ridotta,
                                    w_mesi_possesso - nvl(w_mesi_esclusione,0)),
                                    100,
                                    nvl(rec_ogco.imm_storico,'N'),a_anno_rif,
                                    w_abitazioni,wd_abitazioni
                                   );
              determina_importi_ici(w_totale_importo_1s,rec_ogco.valore_d,
                                    w_aliquota1,w_aliquota2,
                                    w_flag_riduzione,rec_ogco.perc_possesso,
                                    w_mesi_possesso_1s - nvl(w_mesi_esclusione_1s,0),
                                    nvl(w_mesi_riduzione_1s,
                                    w_mesi_possesso_1s - nvl(w_mesi_esclusione_1s,0)),
                                    nvl(w_mesi_al_ridotta_1s,
                                    w_mesi_possesso_1s - nvl(w_mesi_esclusione_1s,0)),
                                    w_perc_acconto,
                                    nvl(rec_ogco.imm_storico,'N'),a_anno_rif,
                                    w_abitazioni_1s,wd_abitazioni_1s
                                   );
            EXCEPTION
               WHEN others THEN null;
            END;
            w_detrazioni := rec_ogco.detrazione;
            BEGIN
               if a_anno_rif <= 2000 then
                  if rec_ogco.mesi_possesso = 0 then
                     w_detrazioni_1s := 0;
                  else
                     select w_detrazione_prec * nvl(w_mesi_al_ridotta_1s,0)
                            / nvl(rec_ogco.mesi_possesso,12) * 0.9
                       into w_detrazioni_1s
                       from dual
                     ;
                  end if;
               else
                  if rec_ogco.mesi_possesso = 0 then
                     w_detrazioni_1s := 0;
                  else
                     select w_detrazione_prec * nvl(w_mesi_al_ridotta_1s,0)
                            / nvl(rec_ogco.mesi_possesso,12)
                       into w_detrazioni_1s
                       from dual
                     ;
                  end if;
               end if;
            EXCEPTION
               WHEN others THEN null;
            END;
            BEGIN
               -- (VD - 23/10/2020): calcolo imposta a saldo (D.L. 14 agosto 2020)
               --                    per le abitazioni principali in realta
               --                    non dovrebbe servire
               calcolo_imu_saldo ( 'ICI'
                                 , a_anno_rif
                                 , w_tipo_al_ab_principale
                                 , f_round(nvl(w_abitazioni,0),0)
                                 , f_round(nvl(w_abitazioni_1s,0),0)
                                 , to_number(null)
                                 , to_number(null)
                                 , w_perc_saldo
                                 , w_imposta_saldo
                                 , w_imposta_saldo_erar
                                 , w_note_saldo
                                 );
               if w_perc_saldo is not null then
                  w_abitazioni := w_imposta_saldo;
               end if;
               if rec_ogco.tipo_pratica = 'V' then
                  w_flag_calcolo := null;
               else
                  w_flag_calcolo := 'S';
               end if;
               insert into oggetti_imposta
                     (cod_fiscale,anno,oggetto_pratica
                     ,imposta,imposta_acconto
                     ,imposta_dovuta,imposta_dovuta_acconto
                     ,tipo_aliquota,aliquota,flag_calcolo,utente
                     ,imponibile,imponibile_d
                     ,aliquota_std
                     ,imposta_std, imposta_dovuta_std
                     ,tipo_tributo, note)
               values (rec_ogco.cod_fiscale_ogco,a_anno_rif,rec_ogco.oggetto_pratica_ogpr
                      ,f_round(nvl(w_abitazioni,0),0),f_round(nvl(w_abitazioni_1s,0),0)
                      ,f_round(nvl(wd_abitazioni,0),0),f_round(nvl(wd_abitazioni_1s,0),0)
                      ,w_tipo_al_ab_principale,w_al_ab_principale_ok,w_flag_calcolo,a_utente
                      ,w_imponibile,rec_ogco.valore_d
                      ,decode(w_abitazioni_std,null,null,w_al_ab_principale_std)
                      ,w_abitazioni_std, wd_abitazioni_std
                      ,'ICI', w_note_saldo)
                       ;
            EXCEPTION
               WHEN others THEN
                  w_errore := 'Errore in ins. Oggetti Imposta (AP) di '||
                              rec_ogco.cod_fiscale_ogco||' Oggetto '||to_char(rec_ogco.oggetto_ogpr);
                  RAISE errore;
            END;
         ELSE -- << altri >>
            if a_anno_rif > 2000 then
               w_perc_acconto := 100;
            else
               w_perc_acconto := 90;
            end if;
            if rec_ogco.tipo_pratica = 'V' then
               w_flag_calcolo := null;
            else
               w_flag_calcolo := 'S';
            end if;
--            if rec_ogco.tipo_oggetto = 1 then
--               w_categoria_catasto_altri := 'T';
--            else
               BEGIN
                  select f_dato_riog(rec_ogco.cod_fiscale_ogco,rec_ogco.oggetto_pratica_ogpr,a_anno_rif,'CA')
                    into w_categoria_catasto_altri
                    from dual
                  ;
               END;
--            end if;
            if rec_ogco.tipo_oggetto = 1 or rec_ogco.tipo_oggetto = 3 then
               BEGIN
                  select nvl(molt.moltiplicatore,1)
                    into w_moltiplicatore_altri
                    from moltiplicatori molt
                   where molt.anno              = a_anno_rif
                     and molt.categoria_catasto = w_categoria_catasto_altri
                       ;
               EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                     w_moltiplicatore_altri := 1;
               END;
               if nvl(rec_ogco.imm_storico,'N') = 'S' and rec_ogco.tipo_oggetto = 3 and a_anno_rif < 2012 then
                  w_moltiplicatore_altri := 100;
               end if;
            else
               w_moltiplicatore_altri := 1;
            end if;
--
-- Routine che determina le imposte tenendo conto di eventuali riferimenti oggetto e di utilizzi oggettp
-- con tutta la problematica quindi delle variazioni di rendita, categoria, moltiplicatore e aliquota.
--
         dbms_output.put_line ('prima di det_imp '||rec_ogco.oggetto_ogpr||'$'||w_tipo_al_affittato
                                     ||'$'||w_tipo_al_non_affittato
                                     ||'$'||w_tipo_al_negozio
                                     ||'$'||w_tipo_al_d
                                     ||'$'||w_tipo_al_d10
                                     ||'$'||w_tipo_al_seconda_casa);
           DETERMINA_IMPOSTA_OGGETTO(rec_ogco.oggetto_ogpr
                                     ,a_anno_rif
                                     ,rec_ogco.cod_fiscale_ogco
                                     ,rec_ogco.oggetto_pratica_ogpr
                                     ,w_data_inizio_possesso
                                     ,w_data_fine_possesso
                                     ,w_data_inizio_possesso_1s
                                     ,w_data_fine_possesso_1s
                                     ,w_mesi_riduzione
                                     ,w_mesi_riduzione_1s
                                     ,rec_ogco.tipo_oggetto
                                     ,w_categoria_catasto_altri
                                     ,w_moltiplicatore_altri
                                     ,rec_ogco.aliquota_rivalutazione
                                     ,w_aliquota_base
                                     ,w_al_affittato
                                     ,w_al_non_affittato
                                     ,w_al_negozio
                                     ,w_al_d
                                     ,w_al_d10
                                     ,w_al_seconda_casa
                                     ,w_aliquota_base_prec
                                     ,w_al_affittato_prec
                                     ,w_al_non_affittato_prec
                                     ,w_al_negozio_prec
                                     ,w_al_d_prec
                                     ,w_al_d10_prec
                                     ,w_al_seconda_casa_prec
                                     ,w_aliquota_base_erar
                                     ,w_al_affittato_erar
                                     ,w_al_non_affittato_erar
                                     ,w_al_negozio_erar
                                     ,w_al_d_erar
                                     ,w_al_d10_erar
                                     ,w_al_seconda_casa_erar
                                     ,w_tipo_al_affittato
                                     ,w_tipo_al_non_affittato
                                     ,w_tipo_al_negozio
                                     ,w_tipo_al_d
                                     ,w_tipo_al_d10
                                     ,w_tipo_al_seconda_casa
                                     ,w_perc_acconto
                                     ,rec_ogco.valore
                                     ,rec_ogco.valore_d
                                     ,nvl(rec_ogco.perc_possesso,0)
                                     ,w_aliquota_base_std
                                     ,w_al_ab_principale_std
                                     ,w_al_affittato_std
                                     ,w_al_non_affittato_std
                                     ,w_al_seconda_casa_std
                                     ,w_al_negozio_std
                                     ,w_al_d_std
                                     ,w_al_d10_std
                                     ,w_al_terreni_rid_std
                                     ,'ICI'
                                     ,w_altri_3
                                     ,wd_altri_3
                                     ,w_altri_3_1s
                                     ,wd_altri_3_1s
                                     ,w_altri_3_erar
                                     ,w_altri_3_erar_1s
                                     ,wd_altri_3_erar
                                     ,wd_altri_3_erar_1s
                                     ,w_tipo_al
                                     ,w_al
                                     ,w_al_erar
                                     ,w_altri_3_std
                                     ,wd_altri_3_std
                                     ,w_al_std
                                     ,w_dettaglio_ogim
                                     );
         dbms_output.put_line ('dopo di det_imp '||w_tipo_al
                                     ||'$'|| w_al);--||'$'|| a_anno_rif||'$'|| w_mesi_possesso||'$'||w_mesi_esclusione||'$'|| w_mesi_possesso_1s||'$'||
                                     --w_data_inizio_possesso||'$'|| w_data_fine_possesso||'$'|| w_data_inizio_possesso_1s||'$'|| w_data_fine_possesso_1s||'$'|| w_da_mese_possesso);
            BEGIN
               insert into oggetti_imposta
                     (cod_fiscale,anno,oggetto_pratica
                     ,imposta,imposta_acconto
                     ,imposta_dovuta,imposta_dovuta_acconto
                     ,imposta_erariale,imposta_erariale_acconto
                     ,imposta_erariale_dovuta,imposta_erariale_dovuta_acc
                     ,tipo_aliquota,aliquota,aliquota_erariale
                     ,flag_calcolo,utente
                     ,aliquota_std
                     ,imposta_std,imposta_dovuta_std
                     ,tipo_tributo,dettaglio_ogim
                     )
               values (rec_ogco.cod_fiscale_ogco,a_anno_rif,rec_ogco.oggetto_pratica_ogpr
                      ,f_round(nvl(w_altri_3,0),0),f_round(nvl(w_altri_3_1s,0),0)
                      ,f_round(nvl(wd_altri_3,0),0),f_round(nvl(wd_altri_3_1s,0),0)
                      ,f_round(nvl(w_altri_3_erar,0),0),f_round(nvl(w_altri_3_erar_1s,0),0)
                      ,f_round(nvl(wd_altri_3_erar,0),0),f_round(nvl(wd_altri_3_erar_1s,0),0)
                      ,w_tipo_al,w_al,w_al_erar
                      ,w_flag_calcolo,a_utente
                      ,w_al_std
                      ,w_altri_3_std, wd_altri_3_std
                      ,'ICI',w_dettaglio_ogim
                      )
               ;
            EXCEPTION
               WHEN others THEN
                  w_errore := 'Errore in inserimento Oggetti Imposta (A3) di '||
                              rec_ogco.cod_fiscale_ogco||' Oggetto '||to_char(rec_ogco.oggetto_ogpr)||
                              ' ('||SQLERRM||')';
                 RAISE errore;
            END;
         END IF;
      END IF;
   END LOOP;
   CALCOLO_DETRAZIONI_ICI(a_cod_fiscale,a_anno_rif,a_ravvedimento,a_tipo_evento);
--commit; tolta il 12-08-2008
   CALCOLO_DETRAZIONI_ICI_OGGE(a_cod_fiscale,a_anno_rif,a_ravvedimento,a_tipo_evento);
--
-- Controllo finale sulle imposte  per far si` che non si verifichi  che l`imposta
-- in acconto superi quella totale. In caso affermativo, si pone l`imposta acconto
-- uguale alla totale e si inserisce un messaggio in oggetti imposta nelle note.
--
   FOR rec_ogim in sel_ogim(a_anno_rif,a_cod_fiscale,a_ravvedimento,a_tipo_evento)
   LOOP
      w_note := null;
      w_imposta_acconto := rec_ogim.imposta_acconto;
      w_imposta_dovuta_acconto := rec_ogim.imposta_dovuta_acconto;
      if nvl(rec_ogim.imposta_acconto,0) > nvl(rec_ogim.imposta,0) then
         w_imposta_acconto := nvl(rec_ogim.imposta,0);
         w_note := ', Imposta Acconto Ricondotta all`Imposta Totale per '||
                   to_char(nvl(rec_ogim.imposta_acconto,0) - nvl(rec_ogim.imposta,0));
      end if;
    --  if w_imposta_acconto = 0 then
    --     w_imposta_acconto := null;
    --  end if;
      if nvl(rec_ogim.imposta_dovuta_acconto,0) > nvl(rec_ogim.imposta_dovuta,0) then
         w_imposta_dovuta_acconto := nvl(rec_ogim.imposta_dovuta,0);
         w_note := w_note||', Imposta Dovuta Acconto Ricondotta all`Imposta Totale per '||
                   to_char(nvl(rec_ogim.imposta_dovuta_acconto,0) - nvl(rec_ogim.imposta_dovuta,0));
      end if;
    --  if w_imposta_dovuta_acconto = 0 then
    --     w_imposta_dovuta_acconto := null;
    --  end if;
      if w_note is not null then
         w_note := substr(w_note,3);
      end if;
    -- Verifica che la detrazione acconto non sia > 0 nel caso che l'aliquota sia 0   (Piero 16-06-08)
    -- se no si mette nulla la detrazione acconto.
      w_aliquota := nvl(rec_ogim.aliquota,0);
      if w_aliquota = 0 then
         w_detrazione_acconto := null;
      else
         w_detrazione_acconto := rec_ogim.detrazione_acconto;
      end if;
      update oggetti_imposta
         set imposta_acconto        = w_imposta_acconto
            ,imposta_dovuta_acconto = w_imposta_dovuta_acconto
            ,note                   = w_note
            ,detrazione_acconto     = w_detrazione_acconto
       where oggetto_imposta        = rec_ogim.oggetto_imposta
      ;
   END LOOP;
   BEGIN
      select detrazione_figlio
        into w_detrazione_figlio
        from detrazioni
       where anno     = a_anno_rif
         and tipo_tributo = 'ICI'
      ;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         w_detrazione_figlio        := 0;
   END;
   if nvl(w_detrazione_figlio,0) <> 0 then
     CALCOLO_DETRAZIONI_ICI_FIGLI(a_cod_fiscale,a_anno_rif,a_ravvedimento
                                 ,a_utente,a_tipo_evento);
   end if;
--
-- Controllo finale sulle imposte  per far si` che non si verifichi  che l`imposta
-- in acconto superi quella totale. In caso affermativo, si pone l`imposta acconto
-- uguale alla totale e si inserisce un messaggio in oggetti imposta nelle note.
--
   FOR rec_ogim in sel_ogim(a_anno_rif,a_cod_fiscale,a_ravvedimento,a_tipo_evento)
   LOOP
      w_note := null;
      w_imposta_acconto := rec_ogim.imposta_acconto;
      w_imposta_dovuta_acconto := rec_ogim.imposta_dovuta_acconto;
      if nvl(rec_ogim.imposta_acconto,0) > nvl(rec_ogim.imposta,0) then
         w_imposta_acconto := nvl(rec_ogim.imposta,0);
         w_note := w_note||', (DEIM) Imposta Acconto Ricondotta all`Imposta Totale per '||
                   to_char(nvl(rec_ogim.imposta_acconto,0) - nvl(rec_ogim.imposta,0));
      end if;
    --  if w_imposta_acconto = 0 then
    --     w_imposta_acconto := null;
    --  end if;
      if nvl(rec_ogim.imposta_dovuta_acconto,0) > nvl(rec_ogim.imposta_dovuta,0) then
         w_imposta_dovuta_acconto := nvl(rec_ogim.imposta_dovuta,0);
         w_note := w_note||', (DEIM) Imposta Dovuta Acconto Ricondotta all`Imposta Totale per '||
                   to_char(nvl(rec_ogim.imposta_dovuta_acconto,0) - nvl(rec_ogim.imposta_dovuta,0));
      end if;
    --  if w_imposta_dovuta_acconto = 0 then
    --     w_imposta_dovuta_acconto := null;
    --  end if;
      if w_note is not null then
         w_note := substr(w_note,3);
      end if;
      update oggetti_imposta
         set imposta_acconto        = w_imposta_acconto
            ,imposta_dovuta_acconto = w_imposta_dovuta_acconto
            ,note                   = note||w_note
       where oggetto_imposta        = rec_ogim.oggetto_imposta
      ;
   END LOOP;
   -- Gestione MINI IMU: ripartizione eventuali detrazioni eccedenti --
--   w_mini_tot_detrazioni := 0;
   w_cod_fiscale_mini    := ' ';
   FOR rec_ogim_mini in sel_ogim_mini(a_anno_rif,a_cod_fiscale
                                     ,a_ravvedimento,a_tipo_evento)
   LOOP
      IF w_cod_fiscale_mini != rec_ogim_mini.cod_fiscale then
         w_cod_fiscale_mini := rec_ogim_mini.cod_fiscale;
         w_mini_imposta_std    := 0;
         w_mini_detrazione_std := 0;
         w_mini_tot_detrazioni := 0;
      END IF;
      w_mini_tot_detrazioni := w_mini_tot_detrazioni + nvl(rec_ogim_mini.detrazione,0);
      if nvl(rec_ogim_mini.imposta_std,0) >= w_mini_tot_detrazioni then
         w_mini_imposta_std    := nvl(rec_ogim_mini.imposta_std,0) - w_mini_tot_detrazioni;
         w_mini_detrazione_std := w_mini_tot_detrazioni;
         w_mini_tot_detrazioni := 0;
      else
         w_mini_imposta_std    := 0;
         w_mini_detrazione_std := nvl(rec_ogim_mini.imposta_std,0);
         w_mini_tot_detrazioni := w_mini_tot_detrazioni - nvl(rec_ogim_mini.imposta_std,0);
      end if;
      BEGIN
          update oggetti_imposta
             set imposta_aliquota       = nvl(rec_ogim_mini.imposta,0)
               , imposta_mini           = ((nvl(rec_ogim_mini.imposta,0)               - nvl(rec_ogim_mini.imposta_acconto,0))
                                          - (w_mini_imposta_std
                                            / decode(nvl(rec_ogim_mini.imposta_acconto,0),0,1,2)) )  * 0.4
               , imposta_dovuta_mini    = ((nvl(rec_ogim_mini.imposta_dovuta,0)        - nvl(rec_ogim_mini.imposta_acconto,0))
                                          - (w_mini_imposta_std
                                            / decode(nvl(rec_ogim_mini.imposta_acconto,0),0,1,2)) )  * 0.4
               , imposta                = greatest(
                                          nvl(rec_ogim_mini.imposta_acconto,0)        +
                                            (((nvl(rec_ogim_mini.imposta,0)        - nvl(rec_ogim_mini.imposta_acconto,0))
                                          - (w_mini_imposta_std
                                            / decode(nvl(rec_ogim_mini.imposta_acconto,0),0,1,2)) )  * 0.4)
                                                   ,0)     -- imposta_mini
               , imposta_dovuta         = greatest(
                                          nvl(rec_ogim_mini.imposta_dovuta_acconto,0) +
                                            (((nvl(rec_ogim_mini.imposta_dovuta,0)        - nvl(rec_ogim_mini.imposta_acconto,0))
                                          - (w_mini_imposta_std
                                            / decode(nvl(rec_ogim_mini.imposta_acconto,0),0,1,2)) )  * 0.4)
                                                   ,0)     -- imposta_dovuta_mini
       --        , imposta_acconto        = 0
       --        , imposta_dovuta_acconto = 0
               , imposta_std            = w_mini_imposta_std
               , imposta_dovuta_std     = w_mini_imposta_std
               , detrazione_std         = w_mini_detrazione_std
               , note = note||' - Imp.='||rec_ogim_mini.imposta||' ImpAacc='|| rec_ogim_mini.imposta_acconto||
                        ' Imp.Std='||rec_ogim_mini.imposta_std
    --         set imposta_aliquota       = nvl(rec_ogim_mini.imposta,0)
    --           , imposta_mini           = (nvl(rec_ogim_mini.imposta,0)        - (nvl(rec_ogim_mini.imposta_std,0) - nvl(rec_ogim_mini.detrazione,0)))  * 0.4
    --           , imposta_dovuta_mini    = (nvl(rec_ogim_mini.imposta_dovuta,0) - (nvl(rec_ogim_mini.imposta_dovuta_std,0) - nvl(rec_ogim_mini.detrazione,0))) * 0.4
    --           , imposta                = (nvl(rec_ogim_mini.imposta,0)        - (nvl(rec_ogim_mini.imposta_std,0) - nvl(rec_ogim_mini.detrazione,0))) * 0.4
    --           , imposta_dovuta         = (nvl(rec_ogim_mini.imposta_dovuta,0) - (nvl(rec_ogim_mini.imposta_dovuta_std,0) - nvl(rec_ogim_mini.detrazione,0))) * 0.4
    --           , imposta_acconto        = 0
    --           , imposta_dovuta_acconto = 0
    --           , imposta_std            = nvl(rec_ogim_mini.imposta_std,0) - nvl(rec_ogim_mini.detrazione,0)
    --           , imposta_dovuta_std     = nvl(rec_ogim_mini.imposta_dovuta_std,0) - nvl(rec_ogim_mini.detrazione,0)
           where oggetto_imposta        = nvl(rec_ogim_mini.oggetto_imposta,0)
               ;
      EXCEPTION
        WHEN others THEN
             w_errore := 'Errore in aggiornamento OGIM (Mini-IMU) per CF: '||w_cod_fiscale_mini;
             RAISE errore;
      END;
   END LOOP;
EXCEPTION
   WHEN errore THEN
      ROLLBACK;
      RAISE_APPLICATION_ERROR(-20999,w_errore||' ('||SQLERRM||')',true);
  WHEN others THEN
      ROLLBACK;
      RAISE_APPLICATION_ERROR
      (-20999,'Errore in Calcolo Imposta ICI di '||w_cod_fiscale||' '||'('||SQLERRM||')');
END;
/* End Procedure: CALCOLO_IMPOSTA_ICI */
/
