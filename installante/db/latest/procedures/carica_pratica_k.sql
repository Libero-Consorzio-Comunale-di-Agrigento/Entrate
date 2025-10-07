--liquibase formatted sql 
--changeset abrandolini:20250326_152423_carica_pratica_k stripComments:false runOnChange:true 
 
create or replace procedure CARICA_PRATICA_K

--    Data: 24/04/2001 - Utilizzato INDIRIZZO_OCC di OGPR
--    per memorizzare tipo aliquota, aliquota, detrazioni
--    dell'anno precedente per la determinazione dell'acconto
--    nel caso di anno di riferimento > 2000.      (DM)
--    Modifica del 25/06/2001: Nell'insert di ogco tolto mesi_esclusione,
--                             riduzione e aliq_rid
--                             per problemi di OGCO_DI se modifichiamo
--                             i mesi_possesso
--    Modificato EURO
/*************************************************************************
  Rev.  Date         Author   Note
  19    15/04/2025   RV       #79575
                              Modifica determinazione rendita da per data a per periodo
                              Sostituito f_get_rendita_riog con f_dato_riog_multiplo
  18    29/02/2024   ab       #69780
                              Utilizzo delle procedure _NR per poter utilizzare le nuove sequence
  17    18/01/2024   RV       #66356
                              Modificato gestione flag_possesso per ogog non di fine anno
  16    10/01/2024   RV       #66629
                              Integrata gestione mesi esclusione
  15    01/09/2021   VD       Corretto passaggio parametri alla funzione
                              F_RENDITA: anno della denuncia al posto di
                              anno del calcolo imposta
  14    14/06/2021   VD       Aggiunta gestione periodi RIOG e periodi
                              OGGETTI_OGIM.
  13    12/06/2019   VD       In caso di primo calcolo effettuato nell'anno
                              (con emissione di oggetti_imposta "temporanei")
                              alla fine dell'elaborazione si cancellano
                              anche gli oggetti_ogim relativi al calcolo
                              temporaneo effettuato.
  12    30/07/2018   VD       Corretta sel_ogco: per errore era rimasto
                              fisso l'anno 2015 nella composizione delle
                              date di validita. Sostituito con l'apposito
                              parametro.
  11    12/12/2017   DM       Reimpostato controllo su utente per corretto
                              funzionamento tra TR4, TR4WEB e TributiWeb
  10    11/10/2017   DM       Adeguamenti WEB: aggiunto il parametro
                              in input a_caller.
                              a_caller viene settato a WEB nella
                              chiamata da TributiWEB ed impedisce la
                              creazione del contatto effettuata lato WEB.
                              Modificata la logica di festione dei contatti
                              e valorizzazione del campo indirizzo_occ.
  9     29/12/2016   VD       Modificata gestione aliquota acconto
                              per categoria: per anno >= 2012, si
                              passa alla funzione F_ALIQUOTA_ALCA il
                              parametro 'S' per ottenere l'eventuale
                              aliquota base della categoria indicata
  8     19/12/2016   VD       Modifica temporanea: aggiunta select
                              in union nella query principale per
                              gestire correttamente i cambi di tipo
                              rapporto in corso d'anno.
                              Per il momento questa modifica viene
                              fatta solo per la TASI, in attesa di
                              ulteriori verifiche.
  7     12/05/2016   VD       Modifiche 2016: se il tipo_aliquota
                              dell'oggetto prevede il flag riduzione,
                              si attiva il flag riduzione su OGCO.
  6     08/01/2016   VD       Modificato cursore principale:
                              anziche usare RIFERIMENTI_OGGETTO in
                              join, si usa la funzione F_DATO_RIOG
                              opportunamente modificata per restituire
                              la rendita e le date di inizio e fine validita.
                              La funzione F_RIOG_VALIDO può essere eliminata.
  5     10/08/2015   SC       Se ogim.aliquota_acconto è pieno
                              lo salvo in ogpr.indirizzo_occ e
                              come tipo_aliquota prendo quella
                              di ogim. Il campo è pieno solo se c'è
                              stato utilizzo di aliquote mobili,
                              in futuro sarebbe da usare sempre.
  4     21/04/2015   PM       Modificato cursore principale, inserita
                              funzione f_riog_valido
  3     18/03/2015   VD       Eliminata condizione di where sul flag
                              possesso perchè non si capisce a cosa
                              serve (vv. modifiche a CALCOLA_IMPOSTA_TASI)
  2     05/12/2014   SC       Delete di pratiche precedenti
  1     05/12/2014   VD       Aggiunta gestione nuovi campi mesi
                              occupazione su OGGETTI_CONTRIBUENTE
                              Valorizzazione flag_al_ridotta
                              (se sono indicati dei mesi occupazione)
*************************************************************************/
(a_tipo_tributo     IN   varchar2,
 a_cod_fiscale      IN   varchar2,
 a_anno_rif         IN   number,
 a_utente           IN   varchar2,
 a_pratica       IN OUT  NUMBER,-- DM 11-10-2017 - Parametri WEB
 a_caller           IN   VARCHAR2 DEFAULT NULL)
IS
w_conta_calc_imp        number;
w_aliquota_base         number;
w_tipo_aliquota_ab      number;
w_aliquota_ab           number;
w_aliquota_prec         number;
w_tipo_aliquota_prec    number;
w_aliquota_ogim         number;
w_oggetto_pratica       number;
w_oggetto_imposta       number;
w_aliquota_rire         number;
w_valore                number;
w_valore_dic            number;
w_tipo_aliquota         number;
w_detrazioni_prec       number;
w_esiste_ogco           varchar2(1);
w_detrazioni_made       number;
w_mesi_possesso         number;
w_mesi_possesso_prec    number;
w_mesi_possesso_1s      number;
w_mesi_affitto          number;
w_mesi_affitto_1s       number;
w_mesi_esclusione       number;
w_data_inizio_possesso  date;
w_data_fine_possesso    date;
w_dal_possesso          date;
w_al_possesso           date;
w_dal_possesso_1s       date;
w_al_possesso_1s        date;
w_anno_s                number;
w_flag_possesso         varchar2(1);
w_flag_possesso_Prec    varchar2(1);
w_flag_esclusione       varchar2(1);
w_flag_riduzione        varchar2(1);
w_flag_al_ridotta       varchar2(1);
errore                  exception;
w_errore                varchar2(2000);

-- (RV) 07/12/2023 - Nuova gestione porzioni escluse
w_flag_possesso_iniz    varchar2(1);
w_mesi_possesso_iniz    number;
w_mesi_possesso_1s_iniz number;
w_mesi_esclusione_iniz  number;
--
w_mp1                   number;
w_mp1s1                 number;
w_me1                   number;
w_fe1                   varchar2(1);
w_mp2                   number;
w_mp1s2                 number;
w_me2                   number;
w_fe2                   varchar2(1);
--
w_valore_calc           number;
w_rendita               number := 0;
w_oggetto_prec          number;
w_contatore             number := 0;
w_contatore_dett        number;
w_num_ordine            varchar2(5);

CURSOR sel_ogco IS
  select pogr.tipo_rapporto,
         pogr.anno anno_ogco,
         pogr.cod_fiscale cod_fiscale_ogco,
         nvl(f_get_riog_data(pogr.oggetto
                            ,greatest(pogr.inizio_validita
                                     ,f_get_data_inizio_da_mese(a_anno_rif,ogog.da_mese_possesso))
                            ,'CA')
            ,nvl(pogr.categoria_catasto,ogge.categoria_catasto)) categoria_catasto_ogge,
         pogr.oggetto_pratica,
         ogog.sequenza   sequenza_ogog,
         pogr.oggetto    oggetto_ogpr,
         nvl(pogr.categoria_catasto,ogge.categoria_catasto) categoria_catasto_ogpr,
         case when pogr.flag_possesso = 'S' then
           case when (nvl(ogog.mesi_possesso,12) + nvl(ogog.da_mese_possesso,1) - 1) != 12 then
             null
           else
             pogr.flag_possesso
           end
         else
           pogr.flag_possesso
         end flag_possesso,
         pogr.perc_possesso,
         f_get_mesi_possesso(a_tipo_tributo,pogr.cod_fiscale,a_anno_rif
                            ,pogr.oggetto
                            ,greatest(pogr.inizio_validita
                                     ,f_get_data_inizio_da_mese(a_anno_rif,ogog.da_mese_possesso))
                            ,least(pogr.fine_validita
                                  ,f_get_data_fine_da_mese(a_anno_rif,ogog.mesi_possesso,ogog.da_mese_possesso))
                            )                                     mesi_possesso,
        f_get_mesi_possesso_1sem(greatest(pogr.inizio_validita
                                         ,f_get_data_inizio_da_mese(a_anno_rif,ogog.da_mese_possesso))
                                ,least(pogr.fine_validita
                                      ,f_get_data_fine_da_mese(a_anno_rif,ogog.mesi_possesso,ogog.da_mese_possesso))
                                     )                            mesi_possesso_1sem,
         pogr.flag_esclusione,
         pogr.flag_riduzione,
         pogr.flag_ab_principale flag_ab_principale,
         pogr.flag_al_ridotta,
         pogr.valore,
         greatest(pogr.inizio_validita
                 ,f_get_data_inizio_da_mese(a_anno_rif,ogog.da_mese_possesso)) inizio_validita,
         least(pogr.fine_validita
              ,f_get_data_fine_da_mese(a_anno_rif,ogog.mesi_possesso,ogog.da_mese_possesso)) fine_validita,
         ogim.detrazione          detrazione,
         nvl(f_get_riog_data(pogr.oggetto
                            ,greatest(pogr.inizio_validita
                                     ,f_get_data_inizio_da_mese(a_anno_rif,ogog.da_mese_possesso))
                            ,'CL')
            ,nvl(pogr.classe_catasto,ogge.classe_catasto)) classe_catasto_ogge,
         nvl(pogr.tipo_oggetto,ogge.tipo_oggetto)         tipo_oggetto,
         nvl(ogog.tipo_aliquota,ogim.tipo_aliquota)       tipo_aliquota_ogim,
         nvl(ogog.aliquota,ogim.aliquota)                 aliquota_ogim,
         ogim.aliquota_acconto                            aliquota_acconto,
         nvl(ogog.aliquota_erariale,ogim.aliquota_erariale)   aliquota_erariale_ogim,
         nvl(ogog.aliquota_std,ogim.aliquota_std)             aliquota_std_ogim,
         ogim.oggetto_imposta,
         ogim.detrazione_acconto  detrazione_acconto,
         ogim.detrazione_figli,
         ogim.detrazione_figli_acconto,
         pogr.imm_storico,
         pogr.flag_valore_rivalutato,
         pogr.tipo_pratica,
         decode(ogim.tipo_aliquota
               ,2,pogr.oggetto_pratica_rif_ap
               ,to_number(null)
               )                                        oggetto_pratica_rif_ap,
         pogr.mesi_occupato,
         pogr.mesi_occupato_1sem,
         ogim.dettaglio_ogim,
         nvl(ogim.anno,9999) anno_ogim,
         case when pogr.anno < a_anno_rif then null else pogr.mesi_esclusione end mesi_esclusione
    from periodi_ogco_riog pogr,
         oggetti ogge,
         oggetti_imposta ogim,
         oggetti_ogim  ogog
   where pogr.oggetto                                      = ogge.oggetto
     and pogr.inizio_validita <= to_date('3112'||a_anno_rif,'ddmmyyyy')
     and pogr.fine_validita >= to_date('0101'||a_anno_rif,'ddmmyyyy')
     and f_get_data_inizio_da_mese(a_anno_rif,ogog.da_mese_possesso) <=
         to_date('3112'||a_anno_rif,'ddmmyyyy')
     and f_get_data_fine_da_mese(a_anno_rif,ogog.mesi_possesso,ogog.da_mese_possesso) >=
         to_date('0101'||a_anno_rif,'ddmmyyyy')
     and pogr.inizio_validita <= f_get_data_fine_da_mese(a_anno_rif,ogog.mesi_possesso,ogog.da_mese_possesso)
     and pogr.fine_validita >= f_get_data_inizio_da_mese(a_anno_rif,ogog.da_mese_possesso)
     and ogim.oggetto_pratica                          (+) = pogr.oggetto_pratica
     and ogim.anno                                     (+) = a_anno_rif
     and ogim.cod_fiscale                              (+) = pogr.cod_fiscale
     and ogog.oggetto_pratica                          (+) = ogim.oggetto_pratica
     and ogog.anno                                     (+) = ogim.anno
     and ogog.cod_fiscale                              (+) = ogim.cod_fiscale
     and pogr.tipo_tributo                                 = a_tipo_tributo
  --   and ogco.flag_esclusione                             is null
     and pogr.cod_fiscale                               like a_cod_fiscale
  -- (VD - 19/12/2016): per i tipi tributo diversi da TASI la select
  --                    rimane invariata (per ora)
/*     and a_tipo_tributo <> 'TASI'
   union
  -- (VD - 19/12/2016): per la TASI, viene modificata la determinazione
  --                    dell'ultimo periodo dell'oggetto
  select ogco.tipo_rapporto,
         ogco.anno anno_ogco,
         ogco.cod_fiscale cod_fiscale_ogco,
         nvl(f_get_riog_data(ogpr.oggetto
                            ,greatest(nvl(peri.inizio_validita,to_date('0101'||a_anno_rif,'ddmmyyyy'))
                                     ,to_date('0101'||a_anno_rif,'ddmmyyyy'))
                            ,'CA')
            ,nvl(ogpr.categoria_catasto,ogge.categoria_catasto)) categoria_catasto_ogge,
         ogpr.oggetto_pratica,
         ogog.sequenza   sequenza_ogog,
         ogpr.oggetto    oggetto_ogpr,
         nvl(ogpr.categoria_catasto,ogge.categoria_catasto) categoria_catasto_ogpr,
         ogco.flag_possesso,
         ogco.perc_possesso,
         nvl(ogog.mesi_possesso
            ,f_get_mesi_possesso(a_tipo_tributo,ogco.cod_fiscale,a_anno_rif
                                ,ogpr.oggetto
                                ,greatest(nvl(peri.inizio_validita,to_date('0101'||a_anno_rif,'ddmmyyyy'))
                                         ,to_date('0101'||a_anno_rif,'ddmmyyyy'))
                                ,least(nvl(peri.fine_validita,to_date('3112'||a_anno_rif,'ddmmyyyy'))
                                      ,to_date('3112'||a_anno_rif,'ddmmyyyy'))
                                )
            )                                                      mesi_possesso,
         nvl(ogog.mesi_possesso_1sem
            ,f_get_mesi_possesso_1sem(greatest(nvl(peri.inizio_validita,to_date('0101'||a_anno_rif,'ddmmyyyy'))
                                              ,to_date('0101'||a_anno_rif,'ddmmyyyy'))
                                     ,least(nvl(peri.fine_validita,to_date('3112'||a_anno_rif,'ddmmyyyy'))
                                           ,to_date('3112'||a_anno_rif,'ddmmyyyy'))
                                     )
            )      mesi_possesso_1sem,
         ogco.flag_esclusione,
         ogco.flag_riduzione,
         ogco.flag_ab_principale flag_ab_principale,
         ogco.flag_al_ridotta,
         ogpr.valore,
         greatest(nvl(peri.inizio_validita,to_date('0101'||a_anno_rif,'ddmmyyyy'))
                 ,to_date('0101'||a_anno_rif,'ddmmyyyy')) inizio_validita,
         least(nvl(peri.fine_validita,to_date('3112'||a_anno_rif,'ddmmyyyy'))
              ,to_date('3112'||a_anno_rif,'ddmmyyyy')) fine_validita,
         ogim.detrazione          detrazione,
         nvl(f_get_riog_data(ogpr.oggetto
                            ,greatest(nvl(peri.inizio_validita,to_date('0101'||a_anno_rif,'ddmmyyyy'))
                                     ,to_date('0101'||a_anno_rif,'ddmmyyyy'))
                            ,'CL')
            ,nvl(ogpr.classe_catasto,ogge.classe_catasto)) classe_catasto_ogge,
         nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)         tipo_oggetto,
         nvl(ogog.tipo_aliquota,ogim.tipo_aliquota)       tipo_aliquota_ogim,
         nvl(ogog.aliquota,ogim.aliquota)                 aliquota_ogim,
         ogim.aliquota_acconto                            aliquota_acconto,
         nvl(ogog.aliquota_erariale,ogim.aliquota_erariale)   aliquota_erariale_ogim,
         nvl(ogog.aliquota_std,ogim.aliquota_std)             aliquota_std_ogim,
         ogim.oggetto_imposta,
         ogim.detrazione_acconto  detrazione_acconto,
         ogim.detrazione_figli,
         ogim.detrazione_figli_acconto,
         ogpr.imm_storico,
         ogpr.flag_valore_rivalutato,
         prtr.tipo_pratica,
         decode(ogim.tipo_aliquota
               ,2,ogpr.oggetto_pratica_rif_ap
               ,to_number(null)
               )                                        oggetto_pratica_rif_ap,
         ogco.mesi_occupato,
         ogco.mesi_occupato_1sem,
         ogim.dettaglio_ogim,
         nvl(ogim.anno,9999),
         pogr.mesi_esclusione
    from periodi_riog peri,
         maggiori_detrazioni made,
         oggetti ogge,
         oggetti_imposta ogim,
         pratiche_tributo prtr,
         oggetti_pratica ogpr,
         oggetti_contribuente ogco,
         oggetti_ogim  ogog
   where made.anno                                    (+)  = a_anno_rif
     and made.cod_fiscale                             (+)  = ogco.cod_fiscale
     and made.tipo_tributo                            (+)  = a_tipo_tributo
     and peri.oggetto                                 (+)  = ogge.oggetto
     and nvl(peri.inizio_validita (+),to_date('0101'||a_anno_rif,'ddmmyyyy')) <=
         to_date('3112'||a_anno_rif,'ddmmyyyy')
     and nvl(peri.fine_validita (+), to_date('3112'||a_anno_rif,'ddmmyyyy')) >=
         to_date('0101'||a_anno_rif,'ddmmyyyy')
     and ogco.anno||'S'||ogco.tipo_rapporto                =
         (select max(ogco_sub.anno||nvl(ogco_sub.flag_possesso,nvl(prtr_sub.flag_denuncia,'N'))||ogco_sub.tipo_rapporto)
            from pratiche_tributo prtr_sub,
                 oggetti_pratica ogpr_sub,
                 oggetti_contribuente ogco_sub
           where(    prtr_sub.data_notifica               is not null
                 and prtr_sub.tipo_pratica||''             = 'A'
                 and nvl(prtr_sub.stato_accertamento,'D')  = 'D'
                 and nvl(prtr_sub.flag_denuncia,' ')       = 'S'
                 and prtr_sub.anno                         < a_anno_rif
                 or  prtr_sub.data_notifica               is null
                 and prtr_sub.tipo_pratica||''             = 'D'
                )
                 and prtr_sub.anno                                    <= a_anno_rif
                 and prtr_sub.tipo_tributo                             = prtr.tipo_tributo
                 and prtr_sub.pratica                                  = ogpr_sub.pratica
                 and ogpr_sub.oggetto                                  = ogpr.oggetto
                 and ogpr_sub.oggetto_pratica                          = ogco_sub.oggetto_pratica
                 and ogco_sub.tipo_rapporto                           in ('A','C','D','E')
                 and ogco_sub.cod_fiscale                              = ogco.cod_fiscale
         )
     and ogge.oggetto                                      = ogpr.oggetto
     and ogim.oggetto_pratica                          (+) = ogco.oggetto_pratica
     and ogim.anno                                     (+) = a_anno_rif
     and ogim.cod_fiscale                              (+) = ogco.cod_fiscale
     and ogog.oggetto_pratica                          (+) = ogim.oggetto_pratica
     and ogog.anno                                     (+) = ogim.anno
     and ogog.cod_fiscale                              (+) = ogim.cod_fiscale
     and prtr.tipo_tributo||''                             = a_tipo_tributo
     and prtr.pratica                                      = ogpr.pratica
     and ogpr.oggetto_pratica                              = ogco.oggetto_pratica
     and decode(ogco.anno,a_anno_rif,nvl(ogco.mesi_possesso,12),12)
                                                           > 0
     and ogco.flag_possesso                                = 'S'
     and ogco.cod_fiscale                               like a_cod_fiscale
     and a_tipo_tributo = 'TASI'
   union
  select ogco.tipo_rapporto,
         ogco.anno anno_ogco,
         ogco.cod_fiscale cod_fiscale_ogco,
         nvl(f_get_riog_data(ogpr.oggetto
                            ,greatest(nvl(peri.inizio_validita,to_date('0101'||a_anno_rif,'ddmmyyyy'))
                                     ,to_date('0101'||a_anno_rif,'ddmmyyyy'))
                            ,'CA')
            ,nvl(ogpr.categoria_catasto,ogge.categoria_catasto)) categoria_catasto_ogge,
         ogpr.oggetto_pratica,
         ogog.sequenza   sequenza_ogog,
         ogpr.oggetto oggetto_ogpr,
         nvl(ogpr.categoria_catasto,ogge.categoria_catasto) categoria_catasto_ogpr,
         ogco.flag_possesso,
         ogco.perc_possesso,
         nvl(ogog.mesi_possesso
            ,f_get_mesi_possesso(a_tipo_tributo,ogco.cod_fiscale,a_anno_rif
                                ,ogpr.oggetto
                                ,greatest(nvl(peri.inizio_validita,to_date('0101'||a_anno_rif,'ddmmyyyy'))
                                         ,to_date('0101'||a_anno_rif,'ddmmyyyy'))
                                ,least(nvl(peri.fine_validita,to_date('3112'||a_anno_rif,'ddmmyyyy'))
                                      ,to_date('3112'||a_anno_rif,'ddmmyyyy'))
                                )
            )                                                      mesi_possesso,
         nvl(ogog.mesi_possesso_1sem
            ,f_get_mesi_possesso_1sem(greatest(nvl(peri.inizio_validita,to_date('0101'||a_anno_rif,'ddmmyyyy'))
                                              ,to_date('0101'||a_anno_rif,'ddmmyyyy'))
                                     ,least(nvl(peri.fine_validita,to_date('3112'||a_anno_rif,'ddmmyyyy'))
                                           ,to_date('3112'||a_anno_rif,'ddmmyyyy'))
                                     )
            )      mesi_possesso_1sem,
         ogco.flag_esclusione,
         ogco.flag_riduzione,
         ogco.flag_ab_principale flag_ab_principale,
         ogco.flag_al_ridotta,
         ogpr.valore,
         greatest(nvl(peri.inizio_validita,to_date('0101'||a_anno_rif,'ddmmyyyy'))
                 ,to_date('0101'||a_anno_rif,'ddmmyyyy')) inizio_validita,
         least(nvl(peri.fine_validita,to_date('3112'||a_anno_rif,'ddmmyyyy'))
              ,to_date('3112'||a_anno_rif,'ddmmyyyy')) fine_validita,
         ogim.detrazione          detrazione,
         nvl(f_get_riog_data(ogpr.oggetto
                            ,greatest(nvl(peri.inizio_validita,to_date('0101'||a_anno_rif,'ddmmyyyy'))
                                     ,to_date('0101'||a_anno_rif,'ddmmyyyy'))
                            ,'CL')
            ,nvl(ogpr.classe_catasto,ogge.classe_catasto)) classe_catasto_ogge,
         ogpr.tipo_oggetto        tipo_oggetto,
         nvl(ogog.tipo_aliquota,ogim.tipo_aliquota)       tipo_aliquota_ogim,
         nvl(ogog.aliquota,ogim.aliquota)                 aliquota_ogim,
         ogim.aliquota_acconto                            aliquota_acconto,
         nvl(ogog.aliquota_erariale,ogim.aliquota_erariale)   aliquota_erariale_ogim,
         nvl(ogog.aliquota_std,ogim.aliquota_std)   aliquota_std_ogim,
         ogim.oggetto_imposta,
         ogim.detrazione_acconto  detrazione_acconto,
         ogim.detrazione_figli,
         ogim.detrazione_figli_acconto,
         ogpr.imm_storico,
         ogpr.flag_valore_rivalutato,
         prtr.tipo_pratica,
         decode(ogim.tipo_aliquota
               ,2,ogpr.oggetto_pratica_rif_ap
               ,to_number(null)
               )                                        oggetto_pratica_rif_ap,
         ogco.mesi_occupato,
         ogco.mesi_occupato_1sem,
         ogim.dettaglio_ogim,
         nvl(ogim.anno,9999),
         pogr.mesi_esclusione
    from periodi_riog peri,
         maggiori_detrazioni made,
         oggetti ogge,
         oggetti_imposta ogim,
         pratiche_tributo prtr,
         oggetti_pratica ogpr,
         oggetti_contribuente ogco,
         oggetti_ogim  ogog
   where made.anno                                         (+)  = a_anno_rif
     and made.cod_fiscale                                  (+)  = ogco.cod_fiscale
     and made.tipo_tributo                                 (+)  = a_tipo_tributo
     and peri.oggetto                                 (+)  = ogge.oggetto
     and nvl(peri.inizio_validita (+),to_date('0101'||a_anno_rif,'ddmmyyyy')) <=
         to_date('3112'||a_anno_rif,'ddmmyyyy')
     and nvl(peri.fine_validita (+), to_date('3112'||a_anno_rif,'ddmmyyyy')) >=
         to_date('0101'||a_anno_rif,'ddmmyyyy')
     and ogge.oggetto                                           = ogpr.oggetto
     and prtr.tipo_pratica                                      = 'D'
     and ogim.oggetto_pratica                              (+)  = ogco.oggetto_pratica
     and ogim.anno                                         (+)  = ogco.anno
     and ogim.cod_fiscale                                  (+)  = ogco.cod_fiscale
     and ogog.oggetto_pratica                              (+)  = ogim.oggetto_pratica
     and ogog.anno                                         (+)  = ogim.anno
     and ogog.cod_fiscale                                  (+)  = ogim.cod_fiscale
     and prtr.tipo_tributo||''                                  = a_tipo_tributo
     and prtr.pratica                                           = ogpr.pratica
     and ogpr.oggetto_pratica                                   = ogco.oggetto_pratica
     and ogco.flag_possesso                                    is null
     and ogco.anno                                              = a_anno_rif
 --    and ogco.flag_esclusione                                  is null
     and decode(ogco.anno,a_anno_rif,nvl(ogco.mesi_possesso,12),12)
                                                                > 0
     and ogco.cod_fiscale                                    like a_cod_fiscale
     and nvl(ogco.mesi_possesso,12)                             > 0  */
 order by 3,4,7,18
  ;
BEGIN
  begin
    delete pratiche_tributo
     where anno = a_anno_rif
       and tipo_tributo||'' = a_tipo_tributo
       and cod_fiscale =  a_cod_fiscale
       and tipo_pratica = 'K'
       and utente != 'WEB'
    ;
  exception
  when others then
    w_errore := 'Cancellazione precedenti pratiche di calcolo '||to_char(a_anno_rif)||
           ' ('||SQLERRM||')';
    RAISE errore;
  end;
  w_anno_s := lpad(to_char(a_anno_rif),4,'0');
  BEGIN
    select aliquota
      into w_aliquota_base
      from aliquote
     where anno          = a_anno_rif
       and tipo_tributo  = a_tipo_tributo
       and tipo_aliquota   = 1
    ;
  EXCEPTION
    WHEN no_data_found THEN
    w_errore := 'Manca record in Aliquote - base -'||to_char(a_anno_rif)||
           ' ('||SQLERRM||')';
    RAISE errore;
    WHEN others THEN
    w_errore := 'Errore in ricerca Aliquote (1) - ogim1 -'||to_char(a_anno_rif)||
           ' ('||SQLERRM||')';
         RAISE errore;
  END;
  BEGIN
    select tipo_aliquota,aliquota
      into w_tipo_aliquota_ab,w_aliquota_ab
      from aliquote
     where anno          = a_anno_rif
       and flag_ab_principale   is not null
       and tipo_tributo  = a_tipo_tributo
    ;
  EXCEPTION
    WHEN no_data_found THEN
    w_errore := 'Manca record in Aliquote - ab.principale -'||to_char(a_anno_rif)||
           ' ('||SQLERRM||')';
    RAISE errore;
    WHEN others THEN
    w_errore := 'Errore in ricerca Aliquote (2) - ogim -'||to_char(a_anno_rif)||
           ' ('||SQLERRM||')';
         RAISE errore;
  END;
  BEGIN
    select detrazione
      into w_detrazioni_made
      from maggiori_detrazioni
     where cod_fiscale = a_cod_fiscale
       and anno = a_anno_rif - 1
       and tipo_tributo  = a_tipo_tributo
    ;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      w_detrazioni_made := null;
    WHEN OTHERS THEN
      w_errore := 'Errore in Ricerca Maggiori Detrazioni '||to_char(a_anno_rif - 1)||
                 ' per '||a_cod_fiscale||' ('||SQLERRM||')';
      RAISE errore;
  END;
--  BEGIN
--    select nvl(max(pratica),0) + 1
--      into a_pratica
--      from pratiche_tributo
--    ;
--  EXCEPTION
--    WHEN others THEN
--    w_errore := 'Errore in ricerca Pratiche Tributo'||
--           ' ('||SQLERRM||')';
--    RAISE errore;
--  END;

  a_pratica            := NULL;  --Nr della pratica
  pratiche_tributo_nr(a_pratica); --Assegnazione Numero Progressivo

  BEGIN
    insert into pratiche_tributo
           (pratica,cod_fiscale,tipo_tributo,anno,
           tipo_pratica,tipo_evento,data,utente)
    values (a_pratica,a_cod_fiscale,a_tipo_tributo,a_anno_rif,
        'K','U',trunc(sysdate),a_utente)
    ;
  EXCEPTION
    WHEN others THEN
         w_errore := 'Errore in inserimento Pratiche Tributo'||
           ' ('||SQLERRM||')';
         RAISE errore;
  END;
  BEGIN
    insert into rapporti_tributo
           (pratica,cod_fiscale)
    values (a_pratica,a_cod_fiscale)
    ;
  EXCEPTION
    WHEN others THEN
         w_errore := 'Errore in inserimento Pratiche Tributo'||
           ' ('||SQLERRM||')';
         RAISE errore;
  END;

--         w_errore := 'Controllo a_utente '||NVL(a_utente,'nullo')||
--           ' ('||SQLERRM||')';
--         RAISE errore;

--         w_errore := 'Controllo a_tipo_tributo '||NVL(a_tipo_tributo,'nullo')||
--           ' ('||SQLERRM||')';
--         RAISE errore;

  if NVL(a_utente, 'TR4') != 'WEB' and NVL(a_caller, 'TR4') != 'WEB' then
     BEGIN
       insert into contatti_contribuente
              (cod_fiscale,data,anno,tipo_contatto,tipo_richiedente, tipo_tributo, pratica_k)
       values (a_cod_fiscale,trunc(sysdate),a_anno_rif,4,2, a_tipo_tributo, a_pratica)
       ;
     EXCEPTION
       WHEN others THEN
            w_errore := 'Errore in inserimento Contatti Contribuente'||
              ' ('||SQLERRM||')';
            RAISE errore;
     END;
  end if;

  select count(*)
    into w_conta_calc_imp
    from oggetti_imposta
   where cod_fiscale  = a_cod_fiscale
     and anno         = a_anno_rif
     and flag_calcolo = 'S'
     and tipo_tributo = a_tipo_tributo
      ;

   if w_conta_calc_imp = 0 then
      if a_tipo_tributo = 'ICI' then
         calcolo_imposta_ici(a_anno_rif,a_cod_fiscale,a_utente,'N');
      else
         calcolo_imposta_tasi(a_anno_rif,a_cod_fiscale,a_utente,'N');
      end if;
   end if;

  FOR rec_ogco IN sel_ogco LOOP
      --
    --dbms_output.put_line('Oggetto: '||rec_ogco.oggetto_ogpr||', Oggetto pratica: '||rec_ogco.oggetto_pratica||', Anno rif. OGIM: '||rec_ogco.anno_ogim||', Anno OGCO: '||rec_ogco.anno_ogco);
      --
      w_flag_possesso_iniz    := rec_ogco.flag_possesso;
      w_mesi_possesso_iniz    := rec_ogco.mesi_possesso;
      w_mesi_possesso_1s_iniz := rec_ogco.mesi_possesso_1sem;
      w_mesi_esclusione_iniz  := rec_ogco.mesi_esclusione;
      w_flag_esclusione       := rec_ogco.flag_esclusione;
      --
      w_flag_riduzione     := rec_ogco.flag_riduzione;
      w_flag_al_ridotta    := rec_ogco.flag_al_ridotta;
      --
    --dbms_output.put_line('MPI: '||w_mesi_possesso_iniz||', MP1SI: '||w_mesi_possesso_1s_iniz||
    --                         ', MEI: '||w_mesi_esclusione_iniz||', FPI: '||w_flag_possesso_iniz);
    --dbms_output.put_line('FEI: '||w_flag_esclusione||', FRI: '||w_flag_riduzione||', FARI: '||w_flag_al_ridotta);
      --
      -- 18/01/2024 (RV) : Al fine di mantenere in + casi possibili w_mesi_possesso_1s evito i casi senza esclusione
      --
      w_mp1 := 0;
      w_mp1s1 := null;
      w_me1 := null;
      w_fe1 := null;
      --
      if nvl(w_mesi_esclusione_iniz,0) > 0 then
        --
        w_mp2 := 0;
        w_mp1s2 := null;
        w_me2 := null;
        w_fe2 := null;
        --
        calcolo_mesi_esclusione(w_mesi_possesso_iniz,w_flag_possesso_iniz,
                                   nvl(w_mesi_possesso_1s_iniz,0),nvl(w_mesi_esclusione_iniz,0),
                                                          w_mp1,w_mp1s1,w_me1,w_fe1,w_mp2,w_mp1s2,w_me2,w_fe2);
      else
        w_mp2 := w_mesi_possesso_iniz;
        w_mp1s2 := w_mesi_possesso_1s_iniz;
        w_me2 := w_mesi_esclusione_iniz;
        w_fe2 := w_flag_esclusione;
      end if;
      --
    --dbms_output.put_line('MP1: '||w_mp1||', MP1S1: '||w_mp1s1||', ME1: '||w_me1||', FE1: '||w_fe1);
    --dbms_output.put_line('MP2: '||w_mp2||', MP1S2: '||w_mp1s2||', ME2: '||w_me2||', FE2: '||w_fe2);
      --
      FOR quadro IN 0..1      -- Quadro x Esclusione
      LOOP
        --
        if quadro = 0 then
          w_mesi_possesso := w_mp1;
          w_mesi_possesso_1s := w_mp1s1;
          w_mesi_esclusione := w_me1;
          w_flag_esclusione := w_fe1;
          if w_mesi_possesso = w_mesi_possesso_iniz then
             w_flag_possesso := w_flag_possesso_iniz;
          else
             w_flag_possesso := null;
          end if;
        else
          w_mesi_possesso := w_mp2;
          w_mesi_possesso_1s := w_mp1s2;
          w_mesi_esclusione := w_me2;
          w_flag_esclusione := w_fe2;
          w_flag_possesso := w_flag_possesso_iniz;
        end if;
        --
        if(w_mesi_possesso_1s = 0) then
          w_mesi_possesso_1s := null;
        end if ;
        if w_mesi_esclusione = 0 then
          w_mesi_esclusione := null;
        end if;
        --
        IF w_mesi_possesso > 0 THEN     -- Mesi possesso quadro > 0
          --
        --dbms_output.put_line('MPQ: '||w_mesi_possesso||', MP1SQ: '||w_mesi_possesso_1s||', FPQ: '||
        --                                 w_flag_possesso||', MEQ: '||w_mesi_esclusione||', FEQ: '||w_flag_esclusione);
          --

      -- (VD - 10/06/2021): gestione num. ordine oggetti_pratica
      if rec_ogco.oggetto_ogpr <> nvl(w_oggetto_prec,-1) then
         w_oggetto_prec   := rec_ogco.oggetto_ogpr;
         w_contatore      := w_contatore + 1;
         w_contatore_dett := 1;
      else
         w_contatore_dett := w_contatore_dett + 1;
      end if;

    if rec_ogco.anno_ogco = a_anno_rif and w_flag_possesso is null then

      BEGIN
         select ltrim(max(nvl(ogco.flag_possesso,' ')))
           into w_flag_possesso_prec
           from oggetti_contribuente      ogco
               ,oggetti_pratica           ogpr
               ,pratiche_tributo          prtr
          where ogco.cod_fiscale                        = rec_ogco.cod_fiscale_ogco
            and ogpr.oggetto                            = rec_ogco.oggetto_ogpr
            and ogpr.oggetto_pratica                    = ogco.oggetto_pratica
            and prtr.pratica                            = ogpr.pratica
            and prtr.tipo_tributo||''                   = a_tipo_tributo
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
                   and c.tipo_tributo||''                = a_tipo_tributo
                   and c.anno                            < rec_ogco.anno_ogco
                   and b.cod_fiscale                     = ogco.cod_fiscale
                   and a.oggetto                         = rec_ogco.oggetto_ogpr
               )
           group by rec_ogco.oggetto_ogpr
         ;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            w_flag_possesso_prec   := null;
      END;

    else
       w_flag_possesso_prec := null;
    end if;
--
-- (VD - 05/12/2014): Valorizzazione flag_al_ridotta (se sono indicati
--                    dei mesi occupazione)
--
    if a_tipo_tributo = 'TASI' then
       begin
         GET_MESI_AFFITTO (rec_ogco.oggetto_ogpr, rec_ogco.cod_fiscale_ogco, a_anno_rif, 'N',
                           w_mesi_affitto, w_mesi_affitto_1s);
       END;
       if rec_ogco.anno_ogco < a_anno_rif then
          if nvl(w_mesi_possesso,0) = nvl(w_mesi_affitto,-1) then
             w_flag_al_ridotta := 'S';
          end if;
       elsif rec_ogco.anno_ogco = a_anno_rif and
          nvl(w_mesi_possesso,0) = nvl(nvl(rec_ogco.mesi_occupato,w_mesi_affitto),-1) then
          w_flag_al_ridotta := 'S';
       end if;
    end if;
    --dbms_output.put_line('Oggetto: '||rec_ogco.oggetto_ogpr||', mesi possesso: '||w_mesi_possesso);
    --dbms_output.put_line('Oggetto: '||rec_ogco.oggetto_ogpr||', mesi possesso 1 sem: '||w_mesi_possesso_1s);
    --dbms_output.put_line('Oggetto: '||rec_ogco.oggetto_ogpr||', flag possesso: '||w_flag_possesso);
    --dbms_output.put_line('Oggetto: '||rec_ogco.oggetto_ogpr||', flag possesso prec: '||w_flag_possesso_prec);
    -- Nel caso di presenza di OGGETTI_OGIM vengono sempre utilizzati
    -- i mesi di possesso 1 semestre di oggetti_ogim
--    if nvl(rec_ogco.sequenza_ogog,0) = 0 then
--       determina_mesi_possesso_ici( w_flag_possesso, w_flag_possesso_prec
--                                  , a_anno_rif, w_mesi_possesso
--                                  , w_mesi_possesso_1s
--                                  , w_dal_possesso , w_al_possesso
--                                  , w_dal_possesso_1s, w_al_possesso_1s);

      /*
       Se esiste un riog che non ricopre interamente il periodo di possesso,
       si azzerano i mesi di possesso e si obbliga ad introdurli.
         if rec_ogco.inizio_validita is not null then
            if  rec_ogco.inizio_validita > w_dal_possesso
            and rec_ogco.inizio_validita < w_al_possesso
            or  rec_ogco.fine_validita   > w_dal_possesso
            and rec_ogco.fine_validita   < w_al_possesso then
               w_mesi_possesso         := null;
               w_mesi_possesso_1s      := null;
            end if;
         end if;
      */
--    end if;
-- 04/03/2014 SC sposto il calcolo piu' vicino alla insert che lo usa.
--      BEGIN
--        select nvl(max(oggetto_pratica),0) + 1
--          into w_oggetto_pratica
--          from oggetti_pratica
--        ;
--      EXCEPTION
--        WHEN others THEN
--        w_errore := 'Errore in ricerca Oggetti Pratica'||
--               ' ('||SQLERRM||')';
--        RAISE errore;
--      END;
     -- (VD - 08/06/2021): determinazione rendita
   --dbms_output.put_line('Oggetto: '||rec_ogco.oggetto_ogpr||', inizio validità: '||rec_ogco.inizio_validita);
   --dbms_output.put_line('Sequenza ogog: '||rec_ogco.sequenza_ogog);
   --dbms_output.put_line('Tipo oggetto: '||rec_ogco.tipo_oggetto);
   --dbms_output.put_line('Categoria catasto: '||rec_ogco.categoria_catasto_ogge);
   --dbms_output.put_line('Valore: '||rec_ogco.valore);
   --dbms_output.put_line('Rendita riog per data: '||
   --                      f_get_rendita_riog(rec_ogco.oggetto_ogpr,to_number(null),rec_ogco.inizio_validita));
   --dbms_output.put_line('Rendita riog date IMU: '||
   --                      f_dato_riog_multiplo(rec_ogco.oggetto_ogpr,null,null,rec_ogco.inizio_validita,rec_ogco.fine_validita,null,null,a_anno_rif,'RE'));
     --
     select nvl(f_dato_riog_multiplo(rec_ogco.oggetto_ogpr,null,null,rec_ogco.inizio_validita,rec_ogco.fine_validita,null,null,a_anno_rif,'RE')
              --f_get_rendita_riog(rec_ogco.oggetto_ogpr,to_number(null),rec_ogco.inizio_validita)
               ,round(f_rendita(rec_ogco.valore
                               ,rec_ogco.tipo_oggetto
                               -- (VD - 01/09/2021): sostituito anno calcolo imposta con anno denuncia
                               ,rec_ogco.anno_ogco --a_anno_rif
                               ,rec_ogco.categoria_catasto_ogge
                               )
                     ,2
                     )
               )
        into w_rendita
        from dual;
    --dbms_output.put_line('Oggetto: '||rec_ogco.oggetto_ogpr||', rendita: '||w_rendita||', dal: '||rec_ogco.inizio_validita);
      BEGIN
         select nvl(rire.aliquota,0)
           into w_aliquota_rire
           from rivalutazioni_rendita rire
          where tipo_oggetto   = rec_ogco.tipo_oggetto
            and anno           = rec_ogco.anno_ogco
         ;
      EXCEPTION
         WHEN no_data_found THEN
            w_aliquota_rire := 0;
         WHEN others THEN
            w_errore := 'Errore in calcolo rivalutazione rendita'||
                        ' ('||SQLERRM||')';
            RAISE errore;
      END;
      -- (VD - 08/06/2021): nuova query per estrarre il moltiplicatore
      --                    relativo alla categoria catasto corretta
      --                    recuperata nella query precedente
      begin
        select decode(rec_ogco.tipo_oggetto
                     ,1,f_round(rec_ogco.valore / nvl(molt.moltiplicatore,1),0)
                     ,3,f_round(rec_ogco.valore / decode(nvl(rec_ogco.imm_storico,'N')||to_char(sign(2012 - a_anno_rif))
                                                        ,'S1',100
                                                        ,nvl(molt.moltiplicatore,1)
                                                        )
                               ,0)
                    ,55,f_round(rec_ogco.valore / decode(nvl(rec_ogco.imm_storico,'N')||to_char(sign(2012 - a_anno_rif))
                                                        ,'S1',100
                                                        ,nvl(molt.moltiplicatore,1)
                                                        )
                               ,0)
                    ,rec_ogco.valore
                    )
          into w_valore_calc
          from moltiplicatori molt
         where molt.anno               = rec_ogco.anno_ogco --a_anno_rif?
           and molt.categoria_catasto  = rec_ogco.categoria_catasto_ogge;
      exception
        when others then
          w_valore_calc := rec_ogco.valore;
      end;
      select decode(rec_ogco.tipo_oggetto
                   ,4,w_valore_calc
                   ,nvl(w_rendita
                       ,decode(rec_ogco.tipo_pratica||nvl(rec_ogco.flag_valore_rivalutato,'N')
                              ,'AN',w_valore_calc
                              ,(w_valore_calc / (100 + nvl(w_aliquota_rire,0)) * 100)
                              )
                      )
                   )
           , decode(rec_ogco.tipo_oggetto
                   ,4,w_valore_calc
                   ,(w_valore_calc / (100 + nvl(w_aliquota_rire,0)) * 100)
                   )
        into w_valore
           , w_valore_dic
        from dual;
     --dbms_output.put_line('Oggetto: '||rec_ogco.oggetto_ogpr||', rendita: '||w_rendita||', dal: '||rec_ogco.inizio_validita);
     --dbms_output.put_line('Valore: '||w_valore||', Valore Calc: '||w_valore_calc);

       w_valore     := round(w_valore,2);
       w_valore_dic := round(w_valore_dic,2);

       -- gestione degli immobili di catecoria catasto B
       -- se l'anno della pratica è minore del 2007 e
       -- l'anno d'imposta è maggiore del 2006 va aggiunta la rivalutazione del 40%
--       if substr(rec_ogco.categoria_catasto_ogpr,1,1) = 'B'
--          and rec_ogco.anno_ogco < 2007 and a_anno_rif > 2006 then
--             w_valore     := round(w_valore * 1.4 , 2);
--             w_valore_dic := round(w_valore_dic * 1.4 , 2);
--       end if;

--
--    Determinazione detrazione di acconto ICI per anni > 2000
--
      IF a_anno_rif > 2000 then
         IF rec_ogco.anno_ogco < a_anno_rif then
            w_esiste_ogco := 'S';
         ELSE
            w_esiste_ogco := 'N';
         END IF;
         IF w_esiste_ogco = 'S' then
            IF rec_ogco.detrazione is null THEN
               w_detrazioni_prec := null;
            ELSE
               w_detrazioni_prec := f_round(nvl(w_detrazioni_made,rec_ogco.detrazione)
                                         / w_mesi_possesso_prec * w_mesi_possesso_1s,0);
            END IF;
         ELSE
            w_detrazioni_prec := w_detrazioni_made;
         END IF;
      END IF;
--      BEGIN
--        select nvl(max(oggetto_pratica),0) + 1
--          into w_oggetto_pratica
--          from oggetti_pratica
--        ;
--      EXCEPTION
--        WHEN others THEN
--        w_errore := 'Errore in ricerca Oggetti Pratica'||
--               ' ('||SQLERRM||')';
--        RAISE errore;
--      END;
      --dbms_output.put_line('rec_ogco.detrazione '||rec_ogco.detrazione);
      --dbms_output.put_line('w_detrazioni_made '||w_detrazioni_made);
      --dbms_output.put_line('w_detrazioni_prec '||w_detrazioni_prec);

     w_oggetto_pratica := null;
     oggetti_pratica_nr(w_oggetto_pratica); --Assegnazione Numero Progressivo

     BEGIN
       insert into oggetti_pratica
             (oggetto_pratica,oggetto,pratica,categoria_catasto,
              classe_catasto,valore,utente,tipo_oggetto,anno,
              note,imm_storico,oggetto_pratica_rif_ap,
              num_ordine
             )
       values(w_oggetto_pratica,rec_ogco.oggetto_ogpr,a_pratica,
              rec_ogco.categoria_catasto_ogge,rec_ogco.classe_catasto_ogge,
              w_valore,a_utente,rec_ogco.tipo_oggetto,a_anno_rif,
              rpad(nvl(rec_ogco.categoria_catasto_ogpr,' '),3,' ')||to_char(w_valore_dic*100),
              rec_ogco.imm_storico,rec_ogco.oggetto_pratica_rif_ap,
              to_char(w_contatore)||decode(w_contatore_dett,1,'','/'||to_char(w_contatore_dett))
             )
      ;
     EXCEPTION
        WHEN others THEN
           w_errore := 'Errore in inserimento Oggetti Pratica'||
                       ' ('||SQLERRM||')';
           RAISE errore;
     END;

     if rec_ogco.oggetto_pratica_rif_ap is not null then
        AGGIORNAMENTO_OGPR_RIF_AP(w_oggetto_pratica, rec_ogco.oggetto_pratica_rif_ap);
     end if;

     BEGIN
         insert into costi_storici
                (oggetto_pratica,anno,costo)
         select w_oggetto_pratica,anno,costo
           from costi_storici
          where oggetto_pratica = rec_ogco.oggetto_pratica
         ;
     EXCEPTION
         WHEN others THEN
              w_errore := 'Errore in inserimento Costi Storici'||
                     ' ('||SQLERRM||')';
              RAISE errore;
     END;
     --
     -- (VD - 12/05/2016): Modifiche IMU/TASI 2016. Se il tipo_aliquota
     --                    selezionato da OGCO/OGIM prevede la riduzione,
     --                    si attiva il flag_riduzione su OGCO.
     --
     if w_flag_riduzione is null then
        begin
          select flag_riduzione
            into w_flag_riduzione
            from ALIQUOTE
           where anno          = a_anno_rif
             and tipo_tributo  = a_tipo_tributo
             and tipo_aliquota = rec_ogco.tipo_aliquota_ogim;
        exception
          when others then
            w_errore := 'Errore in ricerca Tipo Aliquota '||rec_ogco.tipo_aliquota_ogim||
                        ' per l''anno '||a_anno_rif||' ('||sqlerrm||')';
        end;
     end if;

     BEGIN
     --DBMS_OUTPUT.PUT_LINE('INSERISCO IN OGCO rec_ogco.detrazione '||rec_ogco.detrazione);
         insert into oggetti_contribuente
           (cod_fiscale,oggetto_pratica,anno,perc_possesso,
            mesi_possesso,mesi_possesso_1sem,mesi_esclusione,
            detrazione,
            flag_possesso,flag_esclusione,flag_riduzione,
            flag_ab_principale,flag_al_ridotta,utente,tipo_rapporto_k,
            mesi_occupato,mesi_occupato_1sem)
         values (a_cod_fiscale,w_oggetto_pratica,a_anno_rif,
            rec_ogco.perc_possesso,w_mesi_possesso,
            w_mesi_possesso_1s,w_mesi_esclusione,
            rec_ogco.detrazione,
            w_flag_possesso,w_flag_esclusione,
            w_flag_riduzione,decode(rec_ogco.tipo_aliquota_ogim,2,'S',rec_ogco.flag_ab_principale),
            w_flag_al_ridotta,a_utente,rec_ogco.tipo_rapporto,
            rec_ogco.mesi_occupato,rec_ogco.mesi_occupato_1sem)
         ;

     EXCEPTION
         WHEN others THEN
              w_errore := 'Errore in inserimento Oggetti Contribuente'||
                     ' ('||SQLERRM||')';
              RAISE errore;
     END;

-- 04/03/2014 SC sposto piu' vicino alla insert che lo usa.
--     BEGIN
--        select nvl(max(oggetto_imposta),0) + 1
--          into w_oggetto_imposta
--          from oggetti_imposta
--        ;
--     EXCEPTION
--        WHEN others THEN
--        w_errore := 'Errore in ricerca Oggetti Imposta'||
--               ' ('||SQLERRM||')';
--        RAISE errore;
--     END;
     w_tipo_aliquota := to_number('');
     BEGIN
        select 3
          into w_tipo_aliquota
          from aliquote aliq
             , utilizzi_oggetto utog
         where aliq.anno       = a_anno_rif
           and aliq.tipo_aliquota = 3
           and utog.tipo_utilizzo = 1
           and utog.oggetto       = rec_ogco.oggetto_ogpr
           and aliq.tipo_tributo  = a_tipo_tributo
           and utog.tipo_tributo  = a_tipo_tributo
           and a_anno_rif
            between utog.anno
                and nvl(to_char(utog.data_scadenza,'yyyy'),a_anno_rif)
           and rownum          = 1
        ;
     EXCEPTION
        WHEN no_data_found THEN
           null;
           WHEN others THEN
           w_errore := 'Errore in ricerca Utilizzi Oggetto'||
                      ' ('||SQLERRM||')';
           RAISE errore;
     END;
     w_aliquota_ogim := to_number('');
     IF rec_ogco.tipo_aliquota_ogim is not null or
        w_tipo_aliquota is not null  THEN
        BEGIN
           select aliquota
             into w_aliquota_ogim
             from aliquote
            where anno          = a_anno_rif
              and tipo_aliquota = nvl(rec_ogco.tipo_aliquota_ogim,w_tipo_aliquota)
              and tipo_tributo  = a_tipo_tributo
                ;
        EXCEPTION
           WHEN no_data_found THEN
           null;
           WHEN others THEN
           w_errore := 'Errore in ricerca Aliquote (3) - ogim -'||
                ' ('||SQLERRM||')';
              RAISE errore;
        END;
     END IF;
--     BEGIN
--        select nvl(max(oggetto_imposta),0) + 1
--          into w_oggetto_imposta
--          from oggetti_imposta
--        ;
--     EXCEPTION
--        WHEN others THEN
--        w_errore := 'Errore in ricerca Oggetti Imposta'||
--               ' ('||SQLERRM||')';
--        RAISE errore;
--     END;

     w_oggetto_imposta := null;
     oggetti_imposta_nr(w_oggetto_imposta); --Assegnazione Numero Progressivo

     BEGIN
       --DBMS_OUTPUT.PUT_LINE('A w_oggetto_imposta '||w_oggetto_imposta);
       --DBMS_OUTPUT.PUT_LINE('A rec_ogco.detrazione '||rec_ogco.detrazione);
       --DBMS_OUTPUT.PUT_LINE('A w_flag_possesso '||w_flag_possesso);
       --DBMS_OUTPUT.PUT_LINE('A rec_ogco.tipo_aliquota_ogim '||rec_ogco.tipo_aliquota_ogim
       --               ||' rec_ogco.aliquota_ogim '||rec_ogco.aliquota_ogim);
         insert into oggetti_imposta
                (oggetto_imposta
                ,cod_fiscale
                ,anno
                ,oggetto_pratica
                ,imposta
                ,tipo_aliquota
                ,aliquota
                ,aliquota_erariale
                ,aliquota_std
                ,utente
                ,detrazione
                ,detrazione_acconto
                ,detrazione_figli
                ,detrazione_figli_acconto
                ,detrazione_std
                ,tipo_tributo
                ,dettaglio_ogim
                )
         select w_oggetto_imposta
               ,a_cod_fiscale
               ,a_anno_rif
               ,w_oggetto_pratica
               ,0
               ,rec_ogco.tipo_aliquota_ogim
               ,rec_ogco.aliquota_ogim
               ,rec_ogco.aliquota_erariale_ogim
               ,rec_ogco.aliquota_std_ogim
               ,a_utente
               ,rec_ogco.detrazione
               ,rec_ogco.detrazione_acconto
               ,rec_ogco.detrazione_figli
               ,rec_ogco.detrazione_figli_acconto
               ,decode(rec_ogco.aliquota_std_ogim,null,null,rec_ogco.detrazione)
               ,a_tipo_tributo
               ,rec_ogco.dettaglio_ogim
          from dual
                ;
     EXCEPTION
        WHEN others THEN
        w_errore := 'Errore in inserimento Oggetti Imposta'||
               ' ('||SQLERRM||')';
        RAISE errore;
     END;
     if a_anno_rif > 2000 then
        BEGIN
           if w_aliquota_ogim is null then
              if rec_ogco.flag_ab_principale is null then
                 w_tipo_aliquota_prec := 1; -- Base
              else
                 w_tipo_aliquota_prec := w_tipo_aliquota_ab;
              end if;
           else
              if nvl(rec_ogco.tipo_aliquota_ogim,w_tipo_aliquota) is null then
                 if rec_ogco.flag_ab_principale is null then
                    w_tipo_aliquota_prec := 1; -- Base
                 else
                    w_tipo_aliquota_prec := w_tipo_aliquota_ab;
                 end if;
              else
                 w_tipo_aliquota_prec := nvl(rec_ogco.tipo_aliquota_ogim,w_tipo_aliquota);
              end if;
           end if;

           if a_anno_rif < 2012 then
              if w_tipo_aliquota_prec is null then
                 w_aliquota_prec := 0;
              else
                 BEGIN
                     select aliquota
                       into w_aliquota_prec
                       from aliquote
                      where anno = a_anno_rif - 1
                        and tipo_aliquota   = w_tipo_aliquota_prec
                        and tipo_tributo    = a_tipo_tributo
                    ;
                 EXCEPTION
                    WHEN no_data_found THEN
                       w_errore := 'Manca record in Aliquote per Tipo '||
                                   to_char(w_tipo_aliquota_prec)||
                                   ' e anno '||to_char(a_anno_rif - 1)||
                             ' ('||SQLERRM||')';
                    RAISE errore;
                   WHEN others THEN
                   w_errore := 'Errore in ricerca Aliquote (4) - ogim -'||to_char(a_anno_rif - 1)||
                  ' ('||SQLERRM||')';
                      RAISE errore;
                 END;
              end if;
              --
              -- Nota: questa selezione rimane invariata perche' relativa ad
              --       anni < 2012
              --
              begin
                  select F_ALIQUOTA_ALCA(a_anno_rif - 1, w_tipo_aliquota_prec, rec_ogco.categoria_catasto_ogge, w_aliquota_prec, 0, a_cod_fiscale, a_tipo_tributo)
                    into w_aliquota_prec
                    from dual
                     ;
              exception
                  when others then
                    null;
              end;
           else
              w_tipo_aliquota_prec  := rec_ogco.tipo_aliquota_ogim;

              if w_tipo_aliquota_prec is null then
                 w_aliquota_prec := 0;
              else
                 BEGIN
                     select nvl(aliquota_base,aliquota)
                       into w_aliquota_prec
                       from aliquote
                      where anno = a_anno_rif
                        and tipo_aliquota   = w_tipo_aliquota_prec
                        and tipo_tributo    = a_tipo_tributo
                    ;
                 EXCEPTION
                    WHEN no_data_found THEN
                       w_errore := 'Manca record in Aliquote per Tipo '||
                                   to_char(w_tipo_aliquota_prec)||
                                   ' e anno '||to_char(a_anno_rif)||
                             ' ('||SQLERRM||')';
                    RAISE errore;
                   WHEN others THEN
                   w_errore := 'Errore in ricerca Aliquote (5) - ogim -'||to_char(a_anno_rif)||
                  ' ('||SQLERRM||')';
                      RAISE errore;
                 END;
              end if;

              --dbms_output.put_line(a_anno_rif||'-'|| w_tipo_aliquota_prec||'-'|| rec_ogco.categoria_catasto_ogge||'-'|| w_aliquota_prec||'-'|| w_oggetto_pratica||'-'|| a_cod_fiscale||'-'||a_tipo_tributo);
              -- (AB - 13/08/2014): messo w_oggetto_pratica al posto di 0 per recuperare l'aliquota della pertinenza di
              -- (VD - 29/12/2016): aggiunto parametro finale 'S' per selezionare l'eventuale aliquota base (acconto) per categoria
              begin
                  select F_ALIQUOTA_ALCA(a_anno_rif, w_tipo_aliquota_prec, rec_ogco.categoria_catasto_ogge, w_aliquota_prec, w_oggetto_pratica, a_cod_fiscale, a_tipo_tributo, 'S')
                  --select F_ALIQUOTA_ALCA(a_anno_rif, w_tipo_aliquota_prec, rec_ogco.categoria_catasto_ogge, w_aliquota_prec, 0, a_cod_fiscale,a_tipo_tributo)
                    into w_aliquota_prec
                    from dual
                     ;
              exception
                  when others then
                    null;
              end;

           end if;
         --dbms_output.put_line('w_tipo_aliquota_prec: '||w_tipo_aliquota_prec||' ');
         --dbms_output.put_line('w_aliquota_prec: '||w_aliquota_prec||' ');
         --dbms_output.put_line('aliquota_acconto: '||rec_ogco.aliquota_acconto||' ');
         --dbms_output.put_line('aliquota_erariale_ogim: '||rec_ogco.aliquota_erariale_ogim||' ');
         --dbms_output.put_line('tipo_aliquota_ogim: '||rec_ogco.tipo_aliquota_ogim||' ');
           BEGIN
              update oggetti_pratica
                 set indirizzo_occ = lpad(to_char(decode(rec_ogco.aliquota_acconto,null, w_tipo_aliquota_prec, rec_ogco.tipo_aliquota_ogim)),2,'0')||
                                     lpad(to_char(decode(rec_ogco.aliquota_acconto,null,w_aliquota_prec,rec_ogco.aliquota_acconto) * 100),6,'0')||
                                     lpad(to_char(nvl(rec_ogco.detrazione_acconto,0) * 100),15,'0')||
                                     lpad(to_char(rec_ogco.aliquota_erariale_ogim * 100),6,'0')
               where oggetto_pratica = w_oggetto_pratica
              ;

                -- 20/03/2015 SC
                BEGIN
                  UPDATE OGGETTI_IMPOSTA
                     SET TIPO_ALIQUOTA_PREC = W_TIPO_ALIQUOTA_PREC,
                         ALIQUOTA_PREC      = W_ALIQUOTA_PREC * 100,
                         DETRAZIONE_PREC    = REC_OGCO.DETRAZIONE_ACCONTO,
                         ALIQUOTA_ERAR_PREC = REC_OGCO.ALIQUOTA_ERARIALE_OGIM
                   WHERE OGGETTO_PRATICA = W_OGGETTO_PRATICA;
        EXCEPTION
          WHEN OTHERS THEN
            W_ERRORE := 'Errore in Aggiornamento Dati Anno Precedente - ogim -' || ' (' ||
                        SQLERRM || ')';
            RAISE ERRORE;
        END;
           EXCEPTION
             WHEN others THEN
             w_errore := 'Errore in Aggiornamento Dati Anno Precedente - ogpr -'||
                      ' ('||SQLERRM||')';
                RAISE errore;
           END;
        END;
     END IF;

         END IF;      -- Mesi possesso quadro > 0
     END LOOP;  -- Quadro x Esclusione
  END LOOP;

  if w_conta_calc_imp = 0 then
     -- (VD - 12/06/2019): in caso di calcolo "temporaneo" si cancellano
     --                    anche gli eventuali oggetti_ogim collegati al
     --                    calcolo.
     BEGIN
       delete oggetti_ogim
       where cod_fiscale  = a_cod_fiscale
         and anno         = a_anno_rif
         and tipo_tributo = a_tipo_tributo
          ;
     EXCEPTION
        WHEN others THEN
          w_errore := 'Errore in Cancellazione oggetti_ogim temporanei'||
                        ' ('||SQLERRM||')';
              RAISE errore;
     END;
     BEGIN
       delete oggetti_imposta
       where cod_fiscale  = a_cod_fiscale
         and anno         = a_anno_rif
         and flag_calcolo = 'S'
         and tipo_tributo = a_tipo_tributo
          ;
     EXCEPTION
        WHEN others THEN
          w_errore := 'Errore in Cancellazione oggetti_imposta temporanei'||
                        ' ('||SQLERRM||')';
              RAISE errore;
     END;
  end if;

EXCEPTION
  WHEN errore THEN
       ROLLBACK;
       RAISE_APPLICATION_ERROR
    (-20999,w_errore);
  WHEN others THEN
       ROLLBACK;
       RAISE_APPLICATION_ERROR
    (-20999,'Errore in inserimento pratica di calcolo '||
       ' ('||SQLERRM||')');
END;
/* End Procedure: CARICA_PRATICA_K */
/
