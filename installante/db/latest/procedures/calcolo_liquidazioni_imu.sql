--liquibase formatted sql 
--changeset abrandolini:20250326_152423_calcolo_liquidazioni_imu stripComments:false runOnChange:true 
 
create or replace procedure CALCOLO_LIQUIDAZIONI_IMU
/*************************************************************************
 Rev. Data          Autore    Descrizione
 21   04/06/2025    RV        #78725
                              Modifica query determinazione importi
                              Ora prende i dati pure da oggetti_ogim, se presenti
 20   17/04/2025    RV        #77608
                              Adeguamento gestione sequenza sanzioni
 19   17/05/2024    AB        #50489 - nella select del cont si seleziona anche
                              chi ha solo versamenti per l'anno
 18   07/05/2024    VM        #54066 - generazione liquidazione con importo 0 solo se
                              non attivo il parametro LIQ_DIFF_0
 17   02/10/2023    AB        #67125 - gestione interessi anche se evasa
                              acconto e saldo = 0 (x flag_li_rioog null) (Malnate)
 16   20/09/2022    VM        #66699 - sostituito filtro ricerca sogg.cognome_nome
                              con sogg.cognome_nome_ric
 15   12/09/2022    VD        Belluno (cod. Istat 025006): le liquidazioni
                              calcolate non si eliminano mai
 14   25/08/2022    VD        Redmine 48451: aggiunta eliminazione
                              sanzioni per contribuenti deceduti
 13   27/12/2021    VD        Redmine 53295: corretto calcolo sanzioni
                              secondo lo schema documentato nel redmine
 12   23/09/2020    VD        Aggiunta gestione fabbricati merce
 11   23/03/2020    VD        Aggiunto controllo finale per non eliminare
                              liquidazioni con importo totale = 0 se sono
                              state elaborate dai verificatori.
 10   20/01/2020    VD        Aggiunto controllo per non ricalcolare
                              le pratiche inserite dai verificatori:
                              se la funzione F_CHECK_DELETE_PRATICA
                              restituisce 1, la pratica non è da
                              ricalcolare
 9    19/11/2019    VD        Modificato controllo liquidabilita del
                              contribuente: se l'imposta selezionata
                              risulta uguale a zero, si considera il
                              contribuente come liquidabile e si
                              procede con il calcolo
 8    22/10/2019    VD        Aggiunto motivo di non liquidabilita del
                              contribuente in inserimento wrk_generale
 7    06/03/2019    VD        Le spese di notifica vengono emesse
                              solo se il totale della liquidazione
                              e' maggiore di zero (cioe' non si
                              tratta di rimborso).
 7    03/05/2018    VD        Corretto calcolo imposta dovuta, aggiunta
                              anche mini IMU
 6    22/12/2016    VD        Modificato controllo contribuente da liquidare.
                              Ora il contribuente è da liquidare se esiste
                              anche solo un versamento effettuato in ritardo
                              rispetto alla relativa scadenza.
                              Nel caso in cui siano scambiati i tipi versamento
                              e i versamenti siano stati effettuati entro
                              la scadenza prevista, in sede di calcolo
                              sanzioni tali contribuenti non verranno
                              comunque trattati.
 5    06/12/2016    VD        Ripristinato calcolo totali come somma
                              degli importi arrotondati suddivisi per
                              codice tributo (= tipologia oggetto)
                              Aggiunto arrotondamento anche negli importi
                              delle imposte dichiarate
 4    29/11/2016    VD        Inibito calcolo totali come somma degli
                              importi per tipologia oggetto
                              La sanzione per tardivo versamento in
                              acconto in presenza di eccedenza di versamento
                              a saldo e' stata spostata nella procedure
                              LIQUIDAZIONI_ICI_SANZ_VERS_711
 3    26/10/2016    VD        Versamento a saldo a parziale copertura
                              di acconto totalmente evaso: emessa
                              sanzione per parziale versamento al
                              posto di sanzione per omesso versamento
 2    18/10/2016    VD        Corretta gestione in caso di versamento
                              a saldo a parziale copertura dell'acconto
                              e acconto totalmente evaso
 1    22/07/2016    VD        Aggiunta gestione liquidazione
                              mini IMU: per il 2013 i versamenti
                              di tipo "U" vengono considerati
                              relativi alla mini IMU
*************************************************************************/
(a_anno                 number,
 a_anno_rif             number, --MAI USATO
 a_data_liquidazione    date,
 a_data_rif_interessi   date,
 a_cod_fiscale          varchar2,
 a_nome                 varchar2,
 a_flag_riog            varchar2,
 a_da_data_riog         date,
 a_a_data_riog          date,
 a_da_perc_diff         number,
 a_a_perc_diff          number,
 a_importo_limite_inf   number,
 a_importo_limite_sup   number,
 a_ricalcolo            varchar2,
 a_utente               varchar2,
 a_flag_versamenti      varchar2,
 a_flag_rimborso        varchar2,
 a_flag_ravvedimenti    varchar2,
 a_cont_non_liq      IN OUT number)
IS
-- a_ricalcolo          varchar2(1) := NULL;
C_TIPO_TRIBUTO          CONSTANT varchar2(5) := 'ICI';
C_IMPO_EVASA_ACC        CONSTANT number := 1;
C_IMPO_EVASA_SAL        CONSTANT number := 21;
C_TARD_DEN_INF_30       CONSTANT number := 2;
C_TARD_DEN_SUP_30       CONSTANT number := 3;
C_OMESSO_VERS_ACC       CONSTANT number := 4;
C_OMESSO_VERS_SAL       CONSTANT number := 22;
C_PARZIALE_VERS_ACC     CONSTANT number := 5;
C_PARZIALE_VERS_SAL     CONSTANT number := 23;
C_ERRATO_CF             CONSTANT number := 11;
C_ERRATA_FIRMA          CONSTANT number := 12;
C_SPESE_NOT             CONSTANT number := 97;
C_NUOVO                 CONSTANT number := 100;
--C_TARD_VERS_ACC_INF_30   CONSTANT number := 6;  ***MAI USATO***
C_TARD_VERS_ACC_SUP_7   CONSTANT number := 7;
--C_TARD_VERS_ACC_SUP_15  CONSTANT number := 207;
--C_TARD_VERS_ACC_INF_15  CONSTANT number := 206;
--C_TARD_VERS_ACC_INF_90  CONSTANT number := 207;
--C_TARD_VERS_ACC_SUP_90  CONSTANT number := 210;
--
-- Sanzioni per mini IMU
--
C_IMPO_EVASA_MINI       CONSTANT number := 501;
C_OMESSO_VERS_MINI      CONSTANT number := 502;
C_PARZIALE_VERS_MINI    CONSTANT number := 503;
--
errore                         exception;
w_errore                       varchar2(2000);
w_diff_acconto                 number;
w_diff_saldo                   number;
w_diff_acc                     number;
w_diff_sal                     number;
w_cod_sanzione                 number;
w_chkLiquida                   number;
--w_controllo             varchar2(1); ***MAI USATO***
w_vers_cont                    number;
w_vers_cont_acconto            number;
w_num_versamenti               number;
w_num_versamenti_unici         number;
w_num_versamenti_saldo         number;
w_versamenti                   number;
w_versamenti_acconto           number;
w_versamenti_saldo             number;
w_vers_ecc_saldo               number;
w_imp_dovuta                   number;
w_imp_dovuta_acconto           number;
w_imp_dovuta_saldo             number;
w_imp_dovuta_dic               number;
w_imp_dovuta_acconto_dic       number;
w_imp_dovuta_saldo_dic         number;
w_imp_appoggio                 number;
w_imp_liq_new                  number;
w_imp_liq_old                  number;
w_pratica                      number;
w_data_scad_acconto            date; --Data scadenza acconto
w_data_scad_saldo              date; --Data scadenza saldo
w_data_scad_denuncia           date;
w_data_rif_interessi           date;
w_imp_evasa_acconto            number;
w_imp_evasa_acconto_dic        number;
w_imp_evasa_saldo              number;
w_imp_evasa_saldo_dic          number;
--w_cod_fiscale           varchar2(16); ***MAI USATO***
w_flag_firma                   varchar2(1);
w_flag_cf                      varchar2(1);
w_flag_data                    date;
w_gg_pres_denuncia             number;
w_conto_corrente               number;
w_cont_non_liq                 number;
w_fase_euro                    number;
w_1000                         number;
w_5000                         number;
w_comune                       number;  --Comune del cliente estrtatto da Dati Generali
w_provincia                    number;  --Comune del cliente estrtatto da Dati Generali
w_data_pagamento_max_acc        date;
w_data_pagamento_max_sal        date;
w_versamenti_ravv               number;
w_versamenti_ravv_acc           number;
w_impo_cont                     number;
w_impo_cont_acconto             number;
w_impo_cont_mini                number;
w_imp_dovuta_ab                 number;
w_imp_dovuta_acconto_ab         number;
w_imp_dovuta_saldo_ab           number;
w_imp_dovuta_dic_ab             number;
w_imp_dovuta_acconto_dic_ab     number;
w_imp_dovuta_saldo_dic_ab       number;
w_imp_dovuta_ter                number;
w_imp_dovuta_acconto_ter        number;
w_imp_dovuta_saldo_ter          number;
w_imp_dovuta_dic_ter            number;
w_imp_dovuta_acconto_dic_ter    number;
w_imp_dovuta_saldo_dic_ter      number;
w_imp_dovuta_aree               number;
w_imp_dovuta_acconto_aree       number;
w_imp_dovuta_saldo_aree         number;
w_imp_dovuta_dic_aree           number;
w_imp_dovuta_acconto_dic_aree   number;
w_imp_dovuta_saldo_dic_aree     number;
w_imp_dovuta_altri              number;
w_imp_dovuta_acconto_altri      number;
w_imp_dovuta_saldo_altri        number;
w_imp_dovuta_dic_altri          number;
w_imp_dovuta_acconto_dic_altri  number;
w_imp_dovuta_saldo_dic_altri    number;
w_imp_dov_rur                   number;
w_imp_dov_acc_rur               number;
w_imp_dov_saldo_rur             number;
w_imp_dov_dic_rur               number;
w_imp_dov_acc_dic_rur           number;
w_imp_dov_saldo_dic_rur         number;
w_imp_dov_ter_comu              number;
w_imp_dov_acc_ter_comu          number;
w_imp_dov_saldo_ter_comu        number;
w_imp_dov_dic_ter_comu          number;
w_imp_dov_acc_dic_ter_comu      number;
w_imp_dov_saldo_dic_ter_comu    number;
w_imp_dov_ter_erar              number;
w_imp_dov_acc_ter_erar          number;
w_imp_dov_saldo_ter_erar        number;
w_imp_dov_dic_ter_erar          number;
w_imp_dov_acc_dic_ter_erar      number;
w_imp_dov_saldo_dic_ter_erar    number;
w_imp_dov_aree_comu             number;
w_imp_dov_acc_aree_comu         number;
w_imp_dov_saldo_aree_comu       number;
w_imp_dov_dic_aree_comu         number;
w_imp_dov_acc_dic_aree_comu     number;
w_imp_dov_saldo_dic_aree_comu   number;
w_imp_dov_aree_erar             number;
w_imp_dov_acc_aree_erar         number;
w_imp_dov_saldo_aree_erar       number;
w_imp_dov_dic_aree_erar         number;
w_imp_dov_acc_dic_aree_erar     number;
w_imp_dov_saldo_dic_aree_erar   number;
w_imp_dov_altri_comu            number;
w_imp_dov_acc_altri_comu        number;
w_imp_dov_saldo_altri_comu      number;
w_imp_dov_dic_altri_comu        number;
w_imp_dov_acc_dic_altri_comu    number;
w_imp_dov_saldo_dic_altri_comu  number;
w_imp_dov_altri_erar            number;
w_imp_dov_acc_altri_erar        number;
w_imp_dov_saldo_altri_erar      number;
w_imp_dov_dic_altri_erar        number;
w_imp_dov_acc_dic_altri_erar    number;
w_imp_dov_saldo_dic_altri_erar  number;
w_imp_dov_fab_d_comu            number;
w_imp_dov_acc_fab_d_comu        number;
w_imp_dov_saldo_fab_d_comu      number;
w_imp_dov_dic_fab_d_comu        number;
w_imp_dov_acc_dic_fab_d_comu    number;
w_imp_dov_saldo_dic_fab_d_comu  number;
w_imp_dov_fab_d_erar            number;
w_imp_dov_acc_fab_d_erar        number;
w_imp_dov_saldo_fab_d_erar      number;
w_imp_dov_dic_fab_d_erar        number;
w_imp_dov_acc_dic_fab_d_erar    number;
w_imp_dov_saldo_dic_fab_d_erar  number;
w_imp_evasa_acconto_ab          number;
w_imp_evasa_acconto_ter         number;
w_imp_evasa_acconto_aree        number;
w_imp_evasa_acconto_altri       number;
w_imp_evasa_saldo_ab            number;
w_imp_evasa_saldo_ter           number;
w_imp_evasa_saldo_aree          number;
w_imp_evasa_saldo_altri         number;
w_imp_evasa_acconto_dic_ab      number;
w_imp_evasa_acconto_dic_ter     number;
w_imp_evasa_acconto_dic_aree    number;
w_imp_evasa_acconto_dic_altri   number;
w_imp_evasa_saldo_dic_ab        number;
w_imp_evasa_saldo_dic_ter       number;
w_imp_evasa_saldo_dic_aree      number;
w_imp_evasa_saldo_dic_altri     number;
w_imp_eva_acc_rur               number;
w_imp_eva_saldo_rur             number;
w_imp_eva_acc_dic_rur           number;
w_imp_eva_saldo_dic_rur         number;
w_imp_eva_acc_ter_comu          number;
w_imp_eva_saldo_ter_comu        number;
w_imp_eva_acc_dic_ter_comu      number;
w_imp_eva_saldo_dic_ter_comu    number;
w_imp_eva_acc_ter_erar          number;
w_imp_eva_saldo_ter_erar        number;
w_imp_eva_acc_dic_ter_erar      number;
w_imp_eva_saldo_dic_ter_erar    number;
w_imp_eva_acc_aree_comu         number;
w_imp_eva_saldo_aree_comu       number;
w_imp_eva_acc_dic_aree_comu     number;
w_imp_eva_saldo_dic_aree_comu   number;
w_imp_eva_acc_aree_erar         number;
w_imp_eva_saldo_aree_erar       number;
w_imp_eva_acc_dic_aree_erar     number;
w_imp_eva_saldo_dic_aree_erar   number;
w_imp_eva_acc_altri_comu        number;
w_imp_eva_saldo_altri_comu      number;
w_imp_eva_acc_dic_altri_comu    number;
w_imp_eva_saldo_dic_altri_comu  number;
w_imp_eva_acc_altri_erar        number;
w_imp_eva_saldo_altri_erar      number;
w_imp_eva_acc_dic_altri_erar    number;
w_imp_eva_saldo_dic_altri_erar  number;
w_imp_eva_acc_fab_d_comu        number;
w_imp_eva_saldo_fab_d_comu      number;
w_imp_eva_acc_dic_fab_d_comu    number;
w_imp_eva_saldo_dic_fab_d_comu  number;
w_imp_eva_acc_fab_d_erar        number;
w_imp_eva_saldo_fab_d_erar      number;
w_imp_eva_acc_dic_fab_d_erar    number;
w_imp_eva_saldo_dic_fab_d_erar  number;
w_versamenti_ab                 number;
w_versamenti_acconto_ab         number;
w_versamenti_saldo_ab           number;
w_versamenti_ter                number;
w_versamenti_acconto_ter        number;
w_versamenti_saldo_ter          number;
w_versamenti_aree               number;
w_versamenti_acconto_aree       number;
w_versamenti_saldo_aree         number;
w_versamenti_altri              number;
w_versamenti_acconto_altri      number;
w_versamenti_saldo_altri        number;
w_vers_rurali                   number;
w_vers_acconto_rurali           number;
w_vers_saldo_rurali             number;
w_vers_ter_comu                 number;
w_vers_acconto_ter_comu         number;
w_vers_saldo_ter_comu           number;
w_vers_ter_erar                 number;
w_vers_acconto_ter_erar         number;
w_vers_saldo_ter_erar           number;
w_vers_aree_comu                number;
w_vers_acconto_aree_comu        number;
w_vers_saldo_aree_comu          number;
w_vers_aree_erar                number;
w_vers_acconto_aree_erar        number;
w_vers_saldo_aree_erar          number;
w_vers_altri_comu               number;
w_vers_acconto_altri_comu       number;
w_vers_saldo_altri_comu         number;
w_vers_altri_erar               number;
w_vers_acconto_altri_erar       number;
w_vers_saldo_altri_erar         number;
w_vers_fab_d_comu               number;
w_vers_acconto_fab_d_comu       number;
w_vers_saldo_fab_d_comu         number;
w_vers_fab_d_erar               number;
w_vers_acconto_fab_d_erar       number;
w_vers_saldo_fab_d_erar         number;
-- Mini IMU
w_data_scad_mini                date;
w_imp_dovuta_mini               number;
w_imp_dovuta_mini_dic           number;
w_imp_dovuta_mini_ab            number;
w_imp_dovuta_mini_dic_ab        number;
w_imp_dovuta_mini_ter           number;
w_imp_dovuta_mini_dic_ter       number;
w_imp_evasa_mini                number;
w_imp_evasa_mini_dic            number;
w_imp_evasa_mini_ab             number;
w_imp_evasa_mini_ter            number;
w_versamenti_mini               number;
w_versamenti_mini_ab            number;
w_versamenti_mini_ter           number;
-- (VD - 23/09/2020): Variabili per fabbricati merce
w_imp_dov_fab_m                 number;
w_imp_dov_acc_fab_m             number;
w_imp_dov_saldo_fab_m           number;
w_imp_dov_dic_fab_m             number;
w_imp_dov_acc_dic_fab_m         number;
w_imp_dov_saldo_dic_fab_m       number;
w_imp_eva_acc_fab_m             number;
w_imp_eva_saldo_fab_m           number;
w_imp_eva_acc_dic_fab_m         number;
w_imp_eva_saldo_dic_fab_m       number;
w_vers_fab_merce                number;
w_vers_acconto_fab_merce        number;
w_vers_saldo_fab_merce          number;
w_importanza_ute                number;
w_flag_liq_diff_0               varchar(1);
w_commenti                      number := 0;

--Contiene le pratiche non notificate se Ricalcolo del Dovuto è checkato
CURSOR sel_liq(p_anno number, p_cf varchar2, p_nome varchar2, p_ricalcolo varchar2) IS
select pratica
  from pratiche_tributo prtr
      ,contribuenti cont
      ,soggetti sogg
 where tipo_tributo           = C_TIPO_TRIBUTO
   and anno                   = p_anno
   and tipo_pratica           = 'L'
   and tipo_evento            = 'U'
   and data_notifica       is null
   and decode(p_ricalcolo,'S',NULL,numero)
                           is null
   and prtr.cod_fiscale       = cont.cod_fiscale
   and cont.ni                = sogg.ni
   and cont.cod_fiscale    like p_cf
   and sogg.cognome_nome_ric like p_nome
   -- (VD - 20/01/2020): Aggiunto controllo utente verificatore
   and f_check_delete_pratica(prtr.pratica,a_utente) = 0
 order by 1
;
--Estrae: Codice Fiscale, Imposta Totale (Acconto + Saldo) ed Imposta Acconto
CURSOR sel_cont(p_anno number, p_cf varchar2, p_nome varchar2, p_conto_corrente number)
IS
select cont.cod_fiscale,
       max(sogg.stato) stato,
       sum(nvl(ogim.imposta,0)) impo_cont,
       sum(nvl(ogim.imposta_acconto,0)) impo_cont_acconto,
       sum(nvl(ogim.imposta_mini,0))    impo_cont_mini,
       null                             solo_vers
  from oggetti_imposta   ogim,
       pratiche_tributo  prtr,
       oggetti_pratica   ogpr,
       soggetti      sogg,
       contribuenti   cont
 where prtr.tipo_tributo||''   = C_TIPO_TRIBUTO
   and prtr.pratica            = ogpr.pratica
   and nvl(prtr.stato_accertamento,'D') = 'D'
   and ogpr.oggetto_pratica    = ogim.oggetto_pratica
   and cont.ni                 = sogg.ni
   and ogim.cod_fiscale        = cont.cod_fiscale
   and ogim.flag_calcolo       = 'S'
   and ogim.anno               = p_anno
   and sogg.cognome_nome_ric like p_nome
   and cont.cod_fiscale     like p_cf
   and not exists
   (select 1
      from oggetti_pratica ogpr_liq, oggetti_contribuente ogco_liq, pratiche_tributo prtr_liq
     where ogco_liq.cod_fiscale        = ogim.cod_fiscale
       and ogpr_liq.oggetto_pratica    = ogco_liq.oggetto_pratica
       and ogpr_liq.oggetto            = ogpr.oggetto
       and prtr_liq.pratica            = ogpr_liq.pratica
       and prtr_liq.tipo_pratica       = 'L'
       and nvl(prtr_liq.stato_accertamento,'D') = 'D'
       and prtr_liq.tipo_tributo||''   = C_TIPO_TRIBUTO
       and prtr_liq.anno + 0           = p_anno
       and instr(p_cf,'%')            != 0
      )
   and(    a_flag_ravvedimenti = 'N'
       or  a_flag_ravvedimenti = 'S'
       and not exists
          (select 1
             from oggetti_imposta ogim_rav,oggetti_pratica ogpr_rav,pratiche_tributo prtr_rav
            where prtr_rav.pratica = ogpr_rav.pratica
              and ogpr_rav.oggetto_pratica = ogim_rav.oggetto_pratica
              and prtr_rav.tipo_tributo||'' = C_TIPO_TRIBUTO
              and prtr_rav.anno + 0 = p_anno
              and prtr_rav.tipo_pratica = 'V'
              and nvl(prtr_rav.stato_accertamento,'D') = 'D'
              and prtr_rav.numero is not null
              and ogim_rav.cod_fiscale = cont.cod_fiscale
          )
      )
 group by cont.cod_fiscale
union
select cont.cod_fiscale,
       max(sogg.stato) stato,
       0 impo_cont,
       0 impo_cont_acconto,
       0 impo_cont_mini,
      'S' solo_vers
  from soggetti      sogg,
       contribuenti   cont,
       versamenti vers
 where vers.tipo_tributo||''   = C_TIPO_TRIBUTO
   and cont.ni                 = sogg.ni
   and vers.cod_fiscale        = cont.cod_fiscale
   and vers.anno               = p_anno
   and sogg.cognome_nome_ric like p_nome
   and cont.cod_fiscale      like p_cf
   and F_IMPOSTA_CONT_ANNO_TITR(cont.cod_fiscale,
                                p_anno,
                                'ICI',
                                NULL,
                                p_conto_corrente) IS NULL
 group by cont.cod_fiscale
 order by 1, 2
;
--------------------------------------------------------------------------------
-- DATA_SCADENZA_VERS
--------------------------------------------------------------------------------
PROCEDURE data_scadenza_vers
( p_anno              IN number
, p_tipo_trib         IN varchar2
, p_tipo_vers         IN varchar2
, p_cod_fiscale       IN varchar
, w_data_scad         IN OUT date
)
IS
BEGIN
   w_data_scad := f_scadenza(p_anno, p_tipo_trib, p_tipo_vers, p_cod_fiscale);
     if w_data_scad is null THEN
        IF p_tipo_vers = 'A' THEN
          w_errore := 'Manca la data scadenza dell''acconto per l''anno indicato: '||p_anno||' trib: '||p_tipo_trib||' vers: '||p_tipo_vers||' CF: '||p_cod_fiscale||' ('||SQLERRM||')';
        ELSE
          w_errore := 'Manca la data scadenza del saldo per l''anno indicato ('||SQLERRM||')';
        END IF;
        raise errore;
     end if;
EXCEPTION
     WHEN errore THEN RAISE;
 WHEN others THEN
      IF p_tipo_vers = 'A' THEN
        w_errore := 'Errore in ricerca Scadenze (Acconto) ('||SQLERRM||')';
      ELSE
        w_errore := 'Errore in ricerca Scadenze (Saldo) ('||SQLERRM||')';
      END IF;
      RAISE errore;
END data_scadenza_vers;
--------------------------------------------------------------------------------
-- CALCOLO LIQUIDAZIONI IMU
--------------------------------------------------------------------------------
BEGIN
  BEGIN
    select pro_cliente
         , com_cliente
      into w_provincia
         , w_comune
      from dati_generali
        ;
  EXCEPTION
    WHEN others THEN
        w_errore := 'Errore in estrazione comune e provincia in dati_generali ('||SQLERRM||')';
        RAISE errore;
  END;
  BEGIN
     select fase_euro
       into w_fase_euro
       from dati_generali
     ;
  EXCEPTION
     WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20999,'Mancano i Dati Generali');
  END;
  if w_fase_euro = 1 then
     --Lire
     w_1000  := 1000;
     w_5000  := 5000;
  else
     --Euro
     w_1000  := 1;
     w_5000  := 2.58;
  end if;
  a_cont_non_liq := 0;
--  data_scadenza_vers(a_anno,C_TIPO_TRIBUTO, 'A',a_cod_fiscale,w_data_scad_acconto);
--  data_scadenza_vers(a_anno,C_TIPO_TRIBUTO, 'S',a_cod_fiscale,w_data_scad_saldo);
-- Cancellazione tabella WRK_GENERALE
  begin
    delete wrk_generale
     where upper(tipo_trattamento) = 'LIQUIDAZIONE ICI'
         ;
  EXCEPTION
     WHEN others THEN
        w_errore := 'Errore in Eliminazione WRK_GENERALE ';
  end;
  -- (VD - 24/03/2020): si seleziona l'importanza dell'utente per
  --                    controllare se si tratta di verificatore oppure
  --                    di utente standard
  w_importanza_ute := ad4_utente.get_importanza(a_utente,'N',0);
  if w_importanza_ute is null and a_utente like 'ADS%' then
     w_importanza_ute := 10;
  else
     w_importanza_ute := nvl(w_importanza_ute,0);
  end if;
  w_flag_liq_diff_0 := F_INPA_VALORE('LIQ_DIFF_0');
 -- INIZIO TRATTAMENTO STANDARD
  IF a_flag_riog is null THEN
    FOR rec_liq IN sel_liq(a_anno,a_cod_fiscale,a_nome,a_ricalcolo)
    LOOP
       --Cancella le pratiche non notificate da ricalcolare
       BEGIN
           delete pratiche_tributo
            where pratica = rec_liq.pratica
           ;
       EXCEPTION
           WHEN others THEN
           w_errore := 'Errore in Eliminazione Liquidazione (Pratica: '||rec_liq.pratica||')';
       END;
       COMMIT;
    END LOOP;
    --Estrazione del conto corrente su cui versare il dovuto
    BEGIN
       select conto_corrente
         into w_conto_corrente
         from tipi_tributo
        where tipo_tributo = C_TIPO_TRIBUTO;
       EXCEPTION
          WHEN no_data_found THEN NULL;
          WHEN others THEN
            w_errore := 'Errore in ricerca Tipi Tributo ('||SQLERRM||')';
    END;
    FOR rec_cont IN sel_cont(a_anno,a_cod_fiscale,a_nome,w_conto_corrente) LOOP
      if w_commenti = 1 then
         dbms_output.put_line('Contribuente: '||rec_cont.cod_fiscale||', Imposta: '||rec_cont.impo_cont);
      end if;
      data_scadenza_vers(a_anno,C_TIPO_TRIBUTO, 'A',rec_cont.cod_fiscale,w_data_scad_acconto);
      data_scadenza_vers(a_anno,C_TIPO_TRIBUTO, 'S',rec_cont.cod_fiscale,w_data_scad_saldo);
      --
      -- Determinazione scadenza mini IMU
      --
      if a_anno = 2013 then
         select max(scadenza_mini_imu)
           into w_data_scad_mini
           from ALIQUOTE
          where tipo_tributo = C_TIPO_TRIBUTO
            and anno = a_anno;
      else
         w_data_scad_mini := to_date(null);
      end if;
      IF F_IMPOSTA_CONT_ANNO_TITR(rec_cont.cod_fiscale,a_anno
                                  , C_TIPO_TRIBUTO
                                  , NULL
                                  , w_conto_corrente) IS NULL
      AND rec_cont.solo_vers is null THEN
         a_cont_non_liq := a_cont_non_liq + 1;
         -- Gestione dei contribuenti non Liquidabili
         BEGIN
             insert into wrk_generale
                   (tipo_trattamento,anno,progressivo,dati,note)
             values ('LIQUIDAZIONE ICI',a_anno,to_number(to_char(sysdate,'yyyymmddhhMM'))*1000 + a_cont_non_liq
                    ,rec_cont.cod_fiscale,'Imposta non calcolata per il contribuente')
             ;
         EXCEPTION
             WHEN others THEN
                w_errore := 'Errore in inserimento wrk_generale ('||SQLERRM||')';
                RAISE errore;
         END;
      ELSE
         BEGIN
           --Estrae l'importo versato totale e l'importo versato in acconto
           select nvl(sum(vers.importo_versato),0) importo_versato
                , nvl(sum(decode(vers.tipo_versamento
                                ,'A',vers.importo_versato
                                ,'U',vers.importo_versato
                                    ,decode(sign(vers.data_pagamento - w_data_scad_acconto)
                                           ,1,0
                                             ,vers.importo_versato
                                           )
                                )
                         ),0
                     ) importo_versato_acconto
                , count(decode(vers.tipo_versamento,'U',null,1)) num_versamenti
                , count(decode(vers.tipo_versamento,'U',1,null)) num_versamenti_unici
                -- (VD - 27/12/2021): corretto conteggio versamenti a saldo.
                --                    Se il tipo versamento e' S e la data di
                --                    versamento e' superiore alla scadenza
                --                    acconto, allora si considera come versamento
                --                    a saldo.
                --, count(decode(vers.tipo_versamento,'S',1,null)) num_versamenti_saldo
                , count(decode(sign(vers.data_pagamento - w_data_scad_acconto)
                              ,1,decode(vers.tipo_versamento,'S',1,null)
                              ,null)
                       ) num_versamenti_saldo
             into w_vers_cont
                 ,w_vers_cont_acconto
                 ,w_num_versamenti
                 ,w_num_versamenti_unici
                 ,w_num_versamenti_saldo
             from versamenti vers
            where vers.pratica          is null
              and vers.tipo_tributo||''  = C_TIPO_TRIBUTO
              and vers.cod_fiscale       = rec_cont.cod_fiscale
              and vers.anno              = a_anno
                ;
         EXCEPTION
            WHEN no_data_found THEN
                  w_vers_cont :=0;
                  w_vers_cont_acconto :=0;
                WHEN others THEN
                  w_errore := 'Errore in Calcolo Versamenti ('||SQLERRM||')';
               RAISE errore;
         END;
         if w_commenti = 1 then
            dbms_output.put_line('CALCOLO_LIQUIDAZIONI_IMU w_imp_versato e vers acconto '||w_vers_cont||' '||w_vers_cont_acconto);
         end if;
        -- Versamenti su ravvedimento
        begin
           w_versamenti_ravv       := F_IMPORTO_VERS_RAVV(rec_cont.cod_fiscale,C_TIPO_TRIBUTO,a_anno,'U');
           w_versamenti_ravv_acc   := F_IMPORTO_VERS_RAVV(rec_cont.cod_fiscale,C_TIPO_TRIBUTO,a_anno,'A');
        end;
        if a_anno >= 2007 then
           w_impo_cont := round(rec_cont.impo_cont,0);
           w_impo_cont_acconto := round(rec_cont.impo_cont_acconto,0);
           w_impo_cont_mini := round(rec_cont.impo_cont_mini,0);
        else
           w_impo_cont := rec_cont.impo_cont;
           w_impo_cont_acconto := rec_cont.impo_cont_acconto;
           w_impo_cont_mini := rec_cont.impo_cont_mini;
        end if;
        if w_commenti = 1 then
           dbms_output.put_line('w_impo_cont: '||w_impo_cont||', w_vers_cont: '||w_vers_cont||', w_versamenti_ravv: '||w_versamenti_ravv);
        end if;
        w_chkLiquida := 0;
        IF w_1000 < abs(w_impo_cont - w_vers_cont - w_versamenti_ravv)
         OR w_1000 < abs(w_impo_cont_acconto - w_vers_cont_acconto - w_versamenti_ravv_acc)  -- Non dovrebbe essere w_versamenti_ravv_acc?
         -- (VD - 24/04/2020): se utente verificatore la liquidazione viene sempre
         --                    calcolata
         OR w_importanza_ute = 10
         -- (VM - 07/05/2024): #54066 - se parametro LIQ_DIFF_0 attivo, la liquidazione
         --                    viene sempre calcolata
         OR w_flag_liq_diff_0 = 'S'
         THEN
           --dbms_output.put_line('Caso 1 - non versato tutto');
           w_chkLiquida := 1;--Non è stato versato tutto
        ELSE
           BEGIN
             --
             -- (VD - 22/12/2016): modificato controllo.
             --                    Ora il contribuente è da liquidare se esiste
             --                    anche solo un versamento effettuato in ritardo
             --                    rispetto alla relativa scadenza.
             --                    Nel caso in cui siano scambiati i tipi versamento
             --                    e i versamenti siano stati effettuati entro
             --                    la scadenza prevista, in sede di calcolo
             --                    sanzioni tali contribuenti non verranno
             --                    comunque trattati
             --
                select 1 into w_chkLiquida
                  from versamenti      vers
                 where vers.anno = a_anno
                   and vers.tipo_tributo   = C_TIPO_TRIBUTO
                   and vers.pratica is null
                   and vers.tipo_versamento in ('A','U','S')
                   and vers.cod_fiscale = rec_cont.cod_fiscale
                   and vers.data_pagamento > decode(vers.tipo_versamento
                                                   ,'S', w_data_scad_saldo, w_data_scad_acconto)
                   ;
             -- (VD - 16/12/2016): aggiunto controllo su versamenti a saldo
             --                    Vengono considerati validi per il saldo
             --                    solo se la data e' maggiore della scadenza
             --                    dell'acconto
                /*select 1 into w_chkLiquida--E' stato effettuato qualche versamento solo dopo la data di scadenza
                  from versamenti      vers
                 where vers.anno = a_anno
                   and vers.tipo_tributo   = 'ICI'
                   and vers.pratica is null
                   and vers.tipo_versamento in ('A','U','S')
                   and vers.cod_fiscale = rec_cont.cod_fiscale
                   and not exists
                   (select 1
                      from versamenti vers_sub
                     where vers_sub.anno           = vers.anno
                       and vers_sub.tipo_tributo   = vers.tipo_tributo
                       and vers_sub.cod_fiscale    = vers.cod_fiscale
                       and vers_sub.pratica        is null
                       and vers_sub.tipo_versamento   = vers.tipo_versamento
                       and vers_sub.data_pagamento   <= decode(vers.tipo_versamento
                                                              ,'S', w_data_scad_saldo, w_data_scad_acconto)
                       and (vers.tipo_versamento = 'A' or
                           (vers.tipo_versamento = 'S' and
                            vers_sub.data_pagamento   >  w_data_scad_acconto
                           )
                           )
                   )
                ;*/
                RAISE too_many_rows;
           EXCEPTION
             WHEN no_data_found THEN
               w_chkLiquida := 0;
             WHEN too_many_rows THEN
               w_chkLiquida := 1;
             WHEN others THEN
               w_errore := 'Errore in ricerca Versamenti in Ritardo('||SQLERRM||')';
               RAISE errore;
           END;
           IF w_chkLiquida = 0 THEN
              /*BEGIN
                --Quando esiste una denuncia per l'anno in questione
                --
                 select 1 into w_chkLiquida
                   from dual
                       where exists
                                   (select 1
                                     from scadenze      scad,
                                          pratiche_tributo    prtr
                                    where scad.tipo_tributo   = prtr.tipo_tributo
                                      and scad.anno           = prtr.anno
                                      and scad.tipo_scadenza  = prtr.tipo_pratica
                                      and scad.data_scadenza  > prtr.data
                                      and prtr.tipo_tributo   = 'ICI'
                                      and prtr.tipo_pratica   = 'D'
                                      and prtr.anno           = a_anno
                                      and prtr.cod_fiscale    = rec_cont.cod_fiscale)
              ;
              EXCEPTION
                 WHEN NO_DATA_FOUND THEN
                 w_chkLiquida := 0;
                 WHEN OTHERS THEN
                 w_errore := 'Errore in ricerca Denuncie in ritardo ('||SQLERRM||')';
                 RAISE errore;
              END;*/
             --
             -- (VD - 19/11/2019): se l'imposta dovuta dal contribuente e' zero,
             -- potrebbe essere dovuto a qualche dato mancante. In questo caso
             -- si lancia comunque la liquidazione per rilevare gli errori.
             --
              if (w_impo_cont - w_vers_cont - w_versamenti_ravv) = 0 then
                 w_chkliquida := 1;
              end if;
           END IF; -- w_chkLiquida = 0
        END IF; -- w_1000 < abs( w_impo_cont - w_vers_cont - w_versamenti_ravv)
        if w_commenti = 1 then
           DBMS_OUTPUT.PUT_LINE('w_chkLiquida '||w_chkLiquida);
        end if;
        IF w_chkLiquida = 1 THEN --Si esegue la liquidazione
            w_versamenti         := 0;
            w_versamenti_acconto := 0;
            w_versamenti_saldo   := 0;
            w_versamenti_ab            := 0;
            w_versamenti_acconto_ab    := 0;
            w_versamenti_saldo_ab      := 0;
            w_vers_rurali           := 0;
            w_vers_acconto_rurali   := 0;
            w_vers_saldo_rurali     := 0;
            w_versamenti_ter           := 0;
            w_versamenti_acconto_ter   := 0;
            w_versamenti_saldo_ter     := 0;
            w_vers_ter_comu            := 0;
            w_vers_acconto_ter_comu    := 0;
            w_vers_saldo_ter_comu      := 0;
            w_vers_ter_erar            := 0;
            w_vers_acconto_ter_erar    := 0;
            w_vers_saldo_ter_erar      := 0;
            w_versamenti_aree          := 0;
            w_versamenti_acconto_aree  := 0;
            w_versamenti_saldo_aree    := 0;
            w_vers_aree_comu           := 0;
            w_vers_acconto_aree_comu   := 0;
            w_vers_saldo_aree_comu     := 0;
            w_vers_aree_erar           := 0;
            w_vers_acconto_aree_erar   := 0;
            w_vers_saldo_aree_erar     := 0;
            w_versamenti_altri         := 0;
            w_versamenti_acconto_altri := 0;
            w_versamenti_saldo_altri   := 0;
            w_vers_altri_comu          := 0;
            w_vers_acconto_altri_comu  := 0;
            w_vers_saldo_altri_comu    := 0;
            w_vers_altri_erar          := 0;
            w_vers_acconto_altri_erar  := 0;
            w_vers_saldo_altri_erar    := 0;
            w_vers_fab_d_comu          := 0;
            w_vers_acconto_fab_d_comu  := 0;
            w_vers_saldo_fab_d_comu    := 0;
            w_vers_fab_d_erar          := 0;
            w_vers_acconto_fab_d_erar  := 0;
            w_vers_saldo_fab_d_erar    := 0;
            w_vers_fab_merce           := 0;
            w_vers_acconto_fab_merce   := 0;
            w_vers_saldo_fab_merce     := 0;
            w_imp_dovuta         := 0;
            w_imp_dovuta_acconto := 0;
            w_imp_dovuta_saldo   := 0;
            w_imp_dovuta_dic     := 0;
            w_imp_dovuta_acconto_dic := 0;
            w_imp_dovuta_saldo_dic   := 0;
            w_imp_evasa_acconto      := 0; --Non pagato
            w_imp_evasa_saldo        := 0; --Non pagato
            w_imp_evasa_acconto_dic  := 0;
            w_imp_evasa_saldo_dic    := 0;
            w_imp_dovuta_ab                   := 0;
            w_imp_dovuta_acconto_ab           := 0;
            w_imp_dovuta_saldo_ab             := 0;
            w_imp_dovuta_dic_ab               := 0;
            w_imp_dovuta_acconto_dic_ab       := 0;
            w_imp_dovuta_saldo_dic_ab         := 0;
            w_imp_dovuta_ter                  := 0;
            w_imp_dovuta_acconto_ter          := 0;
            w_imp_dovuta_saldo_ter            := 0;
            w_imp_dovuta_dic_ter              := 0;
            w_imp_dovuta_acconto_dic_ter      := 0;
            w_imp_dovuta_saldo_dic_ter        := 0;
            w_imp_dovuta_aree                 := 0;
            w_imp_dovuta_acconto_aree         := 0;
            w_imp_dovuta_saldo_aree           := 0;
            w_imp_dovuta_dic_aree             := 0;
            w_imp_dovuta_acconto_dic_aree     := 0;
            w_imp_dovuta_saldo_dic_aree       := 0;
            w_imp_dovuta_altri                := 0;
            w_imp_dovuta_acconto_altri        := 0;
            w_imp_dovuta_saldo_altri          := 0;
            w_imp_dovuta_dic_altri            := 0;
            w_imp_dovuta_acconto_dic_altri    := 0;
            w_imp_dovuta_saldo_dic_altri      := 0;
            w_imp_evasa_acconto_ab            := 0;
            w_imp_evasa_acconto_ter           := 0;
            w_imp_evasa_acconto_aree          := 0;
            w_imp_evasa_acconto_altri         := 0;
            w_imp_evasa_saldo_ab              := 0;
            w_imp_evasa_saldo_ter             := 0;
            w_imp_evasa_saldo_aree            := 0;
            w_imp_evasa_saldo_altri           := 0;
            w_imp_evasa_acconto_dic_ab        := 0;
            w_imp_evasa_acconto_dic_ter       := 0;
            w_imp_evasa_acconto_dic_aree      := 0;
            w_imp_evasa_acconto_dic_altri     := 0;
            w_imp_evasa_saldo_dic_ab          := 0;
            w_imp_evasa_saldo_dic_ter         := 0;
            w_imp_evasa_saldo_dic_aree        := 0;
            w_imp_evasa_saldo_dic_altri       := 0;
            w_imp_dovuta_mini                 := 0;
            w_imp_dovuta_mini_dic             := 0;
            w_imp_dovuta_mini_ab              := 0;
            w_imp_dovuta_mini_dic_ab          := 0;
            w_imp_dovuta_mini_ter             := 0;
            w_imp_dovuta_mini_dic_ter         := 0;
            w_imp_evasa_mini                  := 0;
            w_imp_evasa_mini_dic              := 0;
            w_imp_evasa_mini_ab               := 0;
            w_imp_evasa_mini_ter              := 0;
            w_gg_pres_denuncia   := 0; --prtr.data - w_data_scad_denuncia
            w_flag_cf            := '';
            w_flag_firma         := '';
            w_pratica            := NULL;  --Nr della pratica
            pratiche_tributo_nr(w_pratica); --Assegnazione Numero Progressivo
            --Totalizzazione dei versamenti e degli acconti
            BEGIN
               select nvl(sum(decode(versamenti.pratica
                                    ,null,versamenti.importo_versato
                                         ,0
                                    )
                              ),0
                          )
                      ,nvl(sum(decode(versamenti.pratica
                                     ,null,decode(versamenti.tipo_versamento
                                                 ,'A',versamenti.importo_versato
                                                 ,'U',versamenti.importo_versato
                                                     ,decode(sign(versamenti.data_pagamento -
                                                                  w_data_scad_acconto
                                                                 )
                                                                 ,1,0
                                                                   ,versamenti.importo_versato
                                                            )
                                                 ),0
                                     )
                              ),0
                          )
                    , max(decode(versamenti.pratica
                                ,null,decode(versamenti.tipo_versamento
                                            ,'A',versamenti.DATA_PAGAMENTO
                                            ,'U',versamenti.DATA_PAGAMENTO
                                            ,decode(sign(versamenti.data_pagamento - w_data_scad_acconto)
                                                   ,1,to_date('01011900','ddmmyyyy')
                                                   ,versamenti.DATA_PAGAMENTO
                                                   )
                                            )
                                ,decode(pratiche_tributo.tipo_pratica
                                       ,'V',decode(versamenti.tipo_versamento
                                            ,'S',versamenti.DATA_PAGAMENTO
                                            ,decode(sign(w_data_scad_acconto - versamenti.data_pagamento)
                                                   ,1,to_date('01011900','ddmmyyyy')
                                                   ,versamenti.DATA_PAGAMENTO
                                                   )
                                            )
                                        ,to_date('01011900','ddmmyyyy')
                                        )
                                )
                          )                                                     data_pagamento_max_acc
                    , max(decode(versamenti.pratica
                                ,null,decode(versamenti.tipo_versamento
                                            ,'S',versamenti.DATA_PAGAMENTO
                                            ,decode(sign(w_data_scad_acconto - versamenti.data_pagamento)
                                                   ,1,to_date('01011900','ddmmyyyy')
                                                   ,versamenti.DATA_PAGAMENTO
                                                   )
                                            )
                                ,decode(pratiche_tributo.tipo_pratica
                                       ,'V',decode(versamenti.tipo_versamento
                                            ,'S',versamenti.DATA_PAGAMENTO
                                            ,decode(sign(w_data_scad_acconto - versamenti.data_pagamento)
                                                   ,1,to_date('01011900','ddmmyyyy')
                                                   ,versamenti.DATA_PAGAMENTO
                                                   )
                                            )
                                        ,to_date('01011900','ddmmyyyy')
                                        )
                                )
                          )                                                     data_pagamento_max
                      ,nvl(sum(decode(versamenti.pratica
                                    ,null,versamenti.ab_principale
                                         ,0
                                    )
                              ),0
                          )                                                     ab_principale
                      ,nvl(sum(decode(versamenti.pratica
                                     ,null,decode(versamenti.tipo_versamento
                                                 ,'A',versamenti.ab_principale
                                                 ,'U',versamenti.ab_principale
                                                     ,decode(sign(versamenti.data_pagamento -
                                                                  w_data_scad_acconto
                                                                 )
                                                                 ,1,0
                                                                   ,versamenti.ab_principale
                                                            )
                                                 ),0
                                     )
                              ),0
                          )                                                     ab_principale_acc
                      ,nvl(sum(decode(versamenti.pratica
                                    ,null,versamenti.terreni_agricoli
                                         ,0
                                    )
                              ),0
                          )                                                     terreni_agricoli
                      ,nvl(sum(decode(versamenti.pratica
                                     ,null,decode(versamenti.tipo_versamento
                                                 ,'A',versamenti.terreni_agricoli
                                                 ,'U',versamenti.terreni_agricoli
                                                     ,decode(sign(versamenti.data_pagamento -
                                                                  w_data_scad_acconto
                                                                 )
                                                                 ,1,0
                                                                   ,versamenti.terreni_agricoli
                                                            )
                                                 ),0
                                     )
                              ),0
                          )                                                     terreni_acc
                      ,nvl(sum(decode(versamenti.pratica
                                    ,null,versamenti.aree_fabbricabili
                                         ,0
                                    )
                              ),0
                          )                                                     aree_fabbricabili
                      ,nvl(sum(decode(versamenti.pratica
                                     ,null,decode(versamenti.tipo_versamento
                                                 ,'A',versamenti.aree_fabbricabili
                                                 ,'U',versamenti.aree_fabbricabili
                                                     ,decode(sign(versamenti.data_pagamento -
                                                                  w_data_scad_acconto
                                                                 )
                                                                 ,1,0
                                                                   ,versamenti.aree_fabbricabili
                                                            )
                                                 ),0
                                     )
                              ),0
                          )                                                     aree_fabbricabili_acc
                      ,nvl(sum(decode(versamenti.pratica
                                    ,null,versamenti.altri_fabbricati
                                         ,0
                                    )
                              ),0
                          )                                                     altri_fabbricati
                      ,nvl(sum(decode(versamenti.pratica
                                     ,null,decode(versamenti.tipo_versamento
                                                 ,'A',versamenti.altri_fabbricati
                                                 ,'U',versamenti.altri_fabbricati
                                                     ,decode(sign(versamenti.data_pagamento -
                                                                  w_data_scad_acconto
                                                                 )
                                                                 ,1,0
                                                                   ,versamenti.altri_fabbricati
                                                            )
                                                 ),0
                                     )
                              ),0
                          )                                                     altri_fabbricati_acc
                      ,nvl(sum(decode(versamenti.pratica
                                    ,null,versamenti.rurali
                                         ,0
                                    )
                              ),0
                          )                                                     rurali
                      ,nvl(sum(decode(versamenti.pratica
                                     ,null,decode(versamenti.tipo_versamento
                                                 ,'A',versamenti.rurali
                                                 ,'U',versamenti.rurali
                                                     ,decode(sign(versamenti.data_pagamento -
                                                                  w_data_scad_acconto
                                                                 )
                                                                 ,1,0
                                                                   ,versamenti.rurali
                                                            )
                                                 ),0
                                     )
                              ),0
                          )                                                     rurali_acc
                      ,nvl(sum(decode(versamenti.pratica
                                    ,null,versamenti.terreni_comune
                                         ,0
                                    )
                              ),0
                          )                                                     terreni_comu
                      ,nvl(sum(decode(versamenti.pratica
                                     ,null,decode(versamenti.tipo_versamento
                                                 ,'A',versamenti.terreni_comune
                                                 ,'U',versamenti.terreni_comune
                                                     ,decode(sign(versamenti.data_pagamento -
                                                                  w_data_scad_acconto
                                                                 )
                                                                 ,1,0
                                                                   ,versamenti.terreni_comune
                                                            )
                                                 ),0
                                     )
                              ),0
                          )                                                     terreni_comu_acc
                      ,nvl(sum(decode(versamenti.pratica
                                    ,null,versamenti.terreni_erariale
                                         ,0
                                    )
                              ),0
                          )                                                     terreni_erar
                      ,nvl(sum(decode(versamenti.pratica
                                     ,null,decode(versamenti.tipo_versamento
                                                 ,'A',versamenti.terreni_erariale
                                                 ,'U',versamenti.terreni_erariale
                                                     ,decode(sign(versamenti.data_pagamento -
                                                                  w_data_scad_acconto
                                                                 )
                                                                 ,1,0
                                                                   ,versamenti.terreni_erariale
                                                            )
                                                 ),0
                                     )
                              ),0
                          )                                                     terreni_erar_acc
                      ,nvl(sum(decode(versamenti.pratica
                                    ,null,versamenti.aree_comune
                                         ,0
                                    )
                              ),0
                          )                                                     aree_comu
                      ,nvl(sum(decode(versamenti.pratica
                                     ,null,decode(versamenti.tipo_versamento
                                                 ,'A',versamenti.aree_comune
                                                 ,'U',versamenti.aree_comune
                                                     ,decode(sign(versamenti.data_pagamento -
                                                                  w_data_scad_acconto
                                                                 )
                                                                 ,1,0
                                                                   ,versamenti.aree_comune
                                                            )
                                                 ),0
                                     )
                              ),0
                          )                                                     aree_comu_acc
                      ,nvl(sum(decode(versamenti.pratica
                                    ,null,versamenti.aree_erariale
                                         ,0
                                    )
                              ),0
                          )                                                     aree_erar
                      ,nvl(sum(decode(versamenti.pratica
                                     ,null,decode(versamenti.tipo_versamento
                                                 ,'A',versamenti.aree_erariale
                                                 ,'U',versamenti.aree_erariale
                                                     ,decode(sign(versamenti.data_pagamento -
                                                                  w_data_scad_acconto
                                                                 )
                                                                 ,1,0
                                                                   ,versamenti.aree_erariale
                                                            )
                                                 ),0
                                     )
                              ),0
                          )                                                     aree_erar_acc
                      ,nvl(sum(decode(versamenti.pratica
                                    ,null,versamenti.altri_comune
                                         ,0
                                    )
                              ),0
                          )                                                     altri_comu
                      ,nvl(sum(decode(versamenti.pratica
                                     ,null,decode(versamenti.tipo_versamento
                                                 ,'A',versamenti.altri_comune
                                                 ,'U',versamenti.altri_comune
                                                     ,decode(sign(versamenti.data_pagamento -
                                                                  w_data_scad_acconto
                                                                 )
                                                                 ,1,0
                                                                   ,versamenti.altri_comune
                                                            )
                                                 ),0
                                     )
                              ),0
                          )                                                     altri_comu_acc
                      ,nvl(sum(decode(versamenti.pratica
                                    ,null,versamenti.altri_erariale
                                         ,0
                                    )
                              ),0
                          )                                                     altri_erar
                      ,nvl(sum(decode(versamenti.pratica
                                     ,null,decode(versamenti.tipo_versamento
                                                 ,'A',versamenti.altri_erariale
                                                 ,'U',versamenti.altri_erariale
                                                     ,decode(sign(versamenti.data_pagamento -
                                                                  w_data_scad_acconto
                                                                 )
                                                                 ,1,0
                                                                   ,versamenti.altri_erariale
                                                            )
                                                 ),0
                                     )
                              ),0
                          )                                                     altri_erar_acc
                      ,nvl(sum(decode(versamenti.pratica
                                    ,null,versamenti.fabbricati_d_comune
                                         ,0
                                    )
                              ),0
                          )                                                     fab_d_comu
                      ,nvl(sum(decode(versamenti.pratica
                                     ,null,decode(versamenti.tipo_versamento
                                                 ,'A',versamenti.fabbricati_d_comune
                                                 ,'U',versamenti.fabbricati_d_comune
                                                     ,decode(sign(versamenti.data_pagamento -
                                                                  w_data_scad_acconto
                                                                 )
                                                                 ,1,0
                                                                   ,versamenti.fabbricati_d_comune
                                                            )
                                                 ),0
                                     )
                              ),0
                          )                                                     fab_d_comu_acc
                      ,nvl(sum(decode(versamenti.pratica
                                    ,null,versamenti.fabbricati_d_erariale
                                         ,0
                                    )
                              ),0
                          )                                                     fab_d_erar
                      ,nvl(sum(decode(versamenti.pratica
                                     ,null,decode(versamenti.tipo_versamento
                                                 ,'A',versamenti.fabbricati_d_erariale
                                                 ,'U',versamenti.fabbricati_d_erariale
                                                     ,decode(sign(versamenti.data_pagamento -
                                                                  w_data_scad_acconto
                                                                 )
                                                                 ,1,0
                                                                   ,versamenti.fabbricati_d_erariale
                                                            )
                                                 ),0
                                     )
                              ),0
                          )                                                     fab_d_erar_acc
                      ,nvl(sum(decode(versamenti.pratica
                                    ,null,versamenti.fabbricati_merce
                                         ,0
                                    )
                              ),0
                          )                                                     fabbricati_merce
                      ,nvl(sum(decode(versamenti.pratica
                                     ,null,decode(versamenti.tipo_versamento
                                                 ,'A',versamenti.fabbricati_merce
                                                 ,'U',versamenti.fabbricati_merce
                                                     ,decode(sign(versamenti.data_pagamento -
                                                                  w_data_scad_acconto
                                                                 )
                                                                 ,1,0
                                                                   ,versamenti.fabbricati_merce
                                                            )
                                                 ),0
                                     )
                              ),0
                          )                                                     fabbricati_merce_acc
                      ,nvl(sum(decode(versamenti.pratica
                                     ,null,decode(versamenti.anno,2013
                                                 ,decode(versamenti.tipo_versamento
                                                        ,'U',versamenti.importo_versato
                                                            ,0
                                                         )
                                                  ,0
                                                  ),0
                                      )
                               )
                          ,0)                                                   mini_imu
                      ,nvl(sum(decode(versamenti.pratica
                                     ,null,decode(versamenti.anno,2013
                                                 ,decode(versamenti.tipo_versamento
                                                        ,'U',versamenti.ab_principale
                                                            ,0
                                                         )
                                                  ,0
                                                  ),0
                                      )
                               )
                          ,0)                                                   mini_imu_ab
                      ,nvl(sum(decode(versamenti.pratica
                                     ,null,decode(versamenti.anno,2013
                                                 ,decode(versamenti.tipo_versamento
                                                        ,'U',versamenti.terreni_agricoli
                                                            ,0
                                                         )
                                                  ,0
                                                  ),0
                                      )
                               )
                          ,0)                                                   mini_imu_ter
                 into w_versamenti
                     ,w_versamenti_acconto
                     ,w_data_pagamento_max_acc
                     ,w_data_pagamento_max_sal
                     ,w_versamenti_ab
                     ,w_versamenti_acconto_ab
                     ,w_versamenti_ter
                     ,w_versamenti_acconto_ter
                     ,w_versamenti_aree
                     ,w_versamenti_acconto_aree
                     ,w_versamenti_altri
                     ,w_versamenti_acconto_altri
                     ,w_vers_rurali
                     ,w_vers_acconto_rurali
                     ,w_vers_ter_comu
                     ,w_vers_acconto_ter_comu
                     ,w_vers_ter_erar
                     ,w_vers_acconto_ter_erar
                     ,w_vers_aree_comu
                     ,w_vers_acconto_aree_comu
                     ,w_vers_aree_erar
                     ,w_vers_acconto_aree_erar
                     ,w_vers_altri_comu
                     ,w_vers_acconto_altri_comu
                     ,w_vers_altri_erar
                     ,w_vers_acconto_altri_erar
                     ,w_vers_fab_d_comu
                     ,w_vers_acconto_fab_d_comu
                     ,w_vers_fab_d_erar
                     ,w_vers_acconto_fab_d_erar
                     ,w_vers_fab_merce
                     ,w_vers_acconto_fab_merce
                     ,w_versamenti_mini
                     ,w_versamenti_mini_ab
                     ,w_versamenti_mini_ter
                 from versamenti
                    , pratiche_tributo
                where versamenti.anno              = a_anno
                  and versamenti.tipo_tributo      = C_TIPO_TRIBUTO
                  and versamenti.cod_fiscale       = rec_cont.cod_fiscale
                  and pratiche_tributo.pratica (+) = versamenti.pratica
               ;
            EXCEPTION
              WHEN others THEN
                 w_errore := 'Errore in totalizzazione versamenti ('||SQLERRM||')';
                 RAISE errore;
            END;
          -- sommo ai totali dei versamenti i versamenti su ravvedimento
          w_versamenti          := w_versamenti + w_versamenti_ravv;
          w_versamenti_acconto  := w_versamenti_acconto + w_versamenti_ravv_acc;
          if w_commenti = 1 then
             dbms_output.put_line('w_versamenti: '||w_versamenti);
             dbms_output.put_line('w_versamenti_acconto: '||w_versamenti_acconto);
             dbms_output.put_line('w_versamenti_mini: '||w_versamenti_mini);
          end if;
          if w_comune = 40 and w_provincia = 36 then
              --Sassuolo: calcolo dell'imposta e dell'acconto dovuti e dichiarati diverso
             BEGIN
                 select f_round(sum(nvl(ogim.imposta, 0)),1)                            w_imp_dovuta2,
                        f_round(sum(nvl(ogim.imposta_acconto, 0)),1)                    w_imp_dovuta_acconto2,
                        f_round(sum(nvl(decode(ogpr.flag_provvisorio
                                              ,'S',ogim.imposta_dovuta,null)
                                              ,nvl(ogim.imposta,0))),1)                 w_imp_dovuta_dic2,
                        f_round(sum(nvl(decode(ogpr.flag_provvisorio
                                              ,'S',ogim.imposta_dovuta_acconto,null)
                                              ,nvl(ogim.imposta_acconto,0))),1)         w_imp_dovuta_acconto_dic2
                    into w_imp_dovuta,
                         w_imp_dovuta_acconto,
                         w_imp_dovuta_dic,
                         w_imp_dovuta_acconto_dic
                    from pratiche_tributo prtr,
                         oggetti_pratica ogpr,
                         oggetti_imposta ogim
                   where ogim.cod_fiscale         = rec_cont.cod_fiscale
                     and ogim.anno                = a_anno
                     and prtr.pratica             = ogpr.pratica
                     and ogim.oggetto_pratica     = ogpr.oggetto_pratica
                     and prtr.tipo_tributo||''    = C_TIPO_TRIBUTO
                     and ogim.flag_calcolo        = 'S'
                   ;
             EXCEPTION
                 WHEN others THEN
                   w_errore := 'Errore in totalizzazione imposta dovuta 1 ('||SQLERRM||')';
                   RAISE errore;
             END;
          else
             BEGIN
                 select sum(nvl(ogim.imposta, 0))
                      , sum(nvl(ogim.imposta_acconto, 0))
                      , sum(nvl(decode(titr.flag_liq_riog
                                      ,'S',ogim.imposta
                                      ,decode(noog.anno_notifica
                                             ,null,ogim.imposta_dovuta
                                             ,ogim.imposta
                                             )
                                      )
                               ,0))
                      , sum(nvl(decode(titr.flag_liq_riog
                                      ,'S',ogim.imposta_acconto
                                      ,decode(noog.anno_notifica
                                             ,null,ogim.imposta_dovuta_acconto
                                             ,ogim.imposta_acconto
                                             )
                                      )
                               ,0))
               -- Abitazione Principale --
                      , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                  ,1,0
                                  ,2,0
                                  ,decode(ogim.tipo_aliquota
                                         ,2,nvl(ogim.imposta, 0)
                                         ,0
                                         )
                                  )
                           )                                                    imp_dovuta_ab
                      , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                  ,1,0
                                  ,2,0
                                  ,decode(ogim.tipo_aliquota
                                         ,2,nvl(ogim.imposta_acconto, 0)
                                         ,0
                                         )
                                  )
                           )                                                    imp_dovuta_acconto_ab
                      , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                  ,1,0
                                  ,2,0
                                  ,decode(ogim.tipo_aliquota
                                         ,2,nvl(decode(titr.flag_liq_riog
                                                         ,'S',ogim.imposta
                                                         ,decode(noog.anno_notifica
                                                                ,null,ogim.imposta_dovuta
                                                                ,ogim.imposta
                                                                )
                                                         )
                                                  , 0)
                                         ,0
                                         )
                                  )
                           )                                                    imp_dovuta_dic_ab
                      , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                  ,1,0
                                  ,2,0
                                  ,decode(ogim.tipo_aliquota
                                         ,2,nvl(decode(titr.flag_liq_riog
                                                         ,'S',ogim.imposta_acconto
                                                         ,decode(noog.anno_notifica
                                                                ,null,ogim.imposta_dovuta_acconto
                                                                ,ogim.imposta_acconto
                                                                )
                                                         )
                                              , 0)
                                         ,0
                                         )
                                  )
                           )                                                    imp_dovuta_acconto_dic_ab
               -- Terreni --
                      , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                  ,1,nvl(ogim.imposta, 0)
                                  ,0
                                  )
                           )                                                    imp_dovuta_ter
                      , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                  ,1,nvl(ogim.imposta_acconto, 0)
                                  ,0
                                  )
                           )                                                    imp_dovuta_acconto_ter
                      , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                  ,1,nvl(decode(titr.flag_liq_riog
                                               ,'S',ogim.imposta
                                               ,decode(noog.anno_notifica
                                                      ,null,ogim.imposta_dovuta
                                                      ,ogim.imposta
                                                      )
                                               )
                                        , 0)
                                  ,0
                                  )
                           )                                                    imp_dovuta_dic_ter
                      , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                  ,1,nvl(decode(titr.flag_liq_riog
                                               ,'S',ogim.imposta_acconto
                                               ,decode(noog.anno_notifica
                                                      ,null,ogim.imposta_dovuta_acconto
                                                      ,ogim.imposta_acconto
                                                      )
                                               )
                                        , 0)
                                  ,0
                                  )
                           )                                                    imp_dovuta_acconto_dic_ter
                      , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                  ,1,nvl(ogim.imposta, 0) - nvl(ogim.imposta_erariale, 0)
                                  ,0
                                  )
                           )                                                    imp_dovuta_ter_comu
                      , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                  ,1,nvl(ogim.imposta_acconto, 0) - nvl(ogim.imposta_erariale_acconto, 0)
                                  ,0
                                  )
                           )                                                    imp_dovuta_acc_ter_comu
                      , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                  ,1,nvl(decode(titr.flag_liq_riog
                                               ,'S',ogim.imposta - nvl(ogim.imposta_erariale, 0)
                                               ,decode(noog.anno_notifica
                                                      ,null,ogim.imposta_dovuta - nvl(ogim.imposta_erariale_dovuta, 0)
                                                      ,ogim.imposta - nvl(ogim.imposta_erariale, 0)
                                                      )
                                               )
                                        , 0)
                                  ,0
                                  )
                           )                                                    imp_dovuta_dic_ter_comu
                      , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                  ,1,nvl(decode(titr.flag_liq_riog
                                               ,'S',ogim.imposta_acconto - nvl(ogim.imposta_erariale_acconto, 0)
                                               ,decode(noog.anno_notifica
                                                      ,null,ogim.imposta_dovuta_acconto - nvl(ogim.imposta_erariale_dovuta_acc, 0)
                                                      ,ogim.imposta_acconto - nvl(ogim.imposta_erariale_acconto, 0)
                                                      )
                                               )
                                        , 0)
                                  ,0
                                  )
                           )                                                    imp_dovuta_acc_dic_ter_comu
                      , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                  ,1,nvl(ogim.imposta_erariale, 0)
                                  ,0
                                  )
                           )                                                    imp_dovuta_ter_erar
                      , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                  ,1,nvl(ogim.imposta_erariale_acconto, 0)
                                  ,0
                                  )
                           )                                                    imp_dovuta_acc_ter_erar
                      , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                  ,1,nvl(decode(titr.flag_liq_riog
                                               ,'S',nvl(ogim.imposta_erariale, 0)
                                               ,decode(noog.anno_notifica
                                                      ,null,nvl(ogim.imposta_erariale_dovuta, 0)
                                                      ,nvl(ogim.imposta_erariale, 0)
                                                      )
                                               )
                                        , 0)
                                  ,0
                                  )
                           )                                                    imp_dovuta_dic_ter_erar
                      , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                  ,1,nvl(decode(titr.flag_liq_riog
                                               ,'S',nvl(ogim.imposta_erariale_acconto, 0)
                                               ,decode(noog.anno_notifica
                                                      ,null,nvl(ogim.imposta_erariale_dovuta_acc, 0)
                                                      ,nvl(ogim.imposta_erariale_acconto, 0)
                                                      )
                                               )
                                        , 0)
                                  ,0
                                  )
                           )                                                    imp_dovuta_acc_dic_ter_erar
               -- Aree --
                      , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                  ,2,nvl(ogim.imposta, 0)
                                  ,0
                                  )
                           )                                                    imp_dovuta_aree
                      , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                  ,2,nvl(ogim.imposta_acconto, 0)
                                  ,0
                                  )
                           )                                                    imp_dovuta_acconto_aree
                      , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                  ,2,nvl(decode(titr.flag_liq_riog
                                               ,'S',ogim.imposta
                                               ,decode(noog.anno_notifica
                                                      ,null,ogim.imposta_dovuta
                                                      ,ogim.imposta
                                                      )
                                               )
                                        , 0)
                                  ,0
                                  )
                           )                                                    imp_dovuta_dic_aree
                      , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                  ,2,nvl(decode(titr.flag_liq_riog
                                               ,'S',ogim.imposta_acconto
                                               ,decode(noog.anno_notifica
                                                      ,null,ogim.imposta_dovuta_acconto
                                                      ,ogim.imposta_acconto
                                                      )
                                               )
                                        , 0)
                                  ,0
                                  )
                           )                                                    imp_dovuta_acconto_dic_aree
                      , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                  ,2,nvl(ogim.imposta, 0) - nvl(ogim.imposta_erariale, 0)
                                  ,0
                                  )
                           )                                                    imp_dovuta_aree_comu
                      , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                  ,2,nvl(ogim.imposta_acconto, 0) - nvl(ogim.imposta_erariale_acconto, 0)
                                  ,0
                                  )
                           )                                                    imp_dovuta_acc_aree_comu
                      , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                  ,2,nvl(decode(titr.flag_liq_riog
                                               ,'S',ogim.imposta  - nvl(ogim.imposta_erariale, 0)
                                               ,decode(noog.anno_notifica
                                                      ,null,ogim.imposta_dovuta  - nvl(ogim.imposta_erariale_dovuta, 0)
                                                      ,ogim.imposta  - nvl(ogim.imposta_erariale, 0)
                                                      )
                                               )
                                        , 0)
                                  ,0
                                  )
                           )                                                    imp_dovuta_dic_aree_comu
                      , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                  ,2,nvl(decode(titr.flag_liq_riog
                                               ,'S',ogim.imposta_acconto - nvl(ogim.imposta_erariale_acconto, 0)
                                               ,decode(noog.anno_notifica
                                                      ,null,ogim.imposta_dovuta_acconto - nvl(ogim.imposta_erariale_dovuta_acc, 0)
                                                      ,ogim.imposta_acconto - nvl(ogim.imposta_erariale_acconto, 0)
                                                      )
                                               )
                                        , 0)
                                  ,0
                                  )
                           )                                                    imp_dovuta_acc_dic_aree_comu
                      , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                  ,2,nvl(ogim.imposta_erariale, 0)
                                  ,0
                                  )
                           )                                                    imp_dovuta_aree_erar
                      , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                  ,2,nvl(ogim.imposta_erariale_acconto, 0)
                                  ,0
                                  )
                           )                                                    imp_dovuta_acc_aree_erar
                      , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                  ,2,nvl(decode(titr.flag_liq_riog
                                               ,'S',nvl(ogim.imposta_erariale, 0)
                                               ,decode(noog.anno_notifica
                                                      ,null,nvl(ogim.imposta_erariale_dovuta, 0)
                                                      ,nvl(ogim.imposta_erariale, 0)
                                                      )
                                               )
                                        , 0)
                                  ,0
                                  )
                           )                                                    imp_dovuta_dic_aree_erar
                      , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                  ,2,nvl(decode(titr.flag_liq_riog
                                               ,'S',nvl(ogim.imposta_erariale_acconto, 0)
                                               ,decode(noog.anno_notifica
                                                      ,null,nvl(ogim.imposta_erariale_dovuta_acc, 0)
                                                      ,nvl(ogim.imposta_erariale_acconto, 0)
                                                      )
                                               )
                                        , 0)
                                  ,0
                                  )
                           )                                                    imp_dovuta_acc_dic_aree_erar
               -- Fabbricati Rurali --
                      , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                  ,1,0
                                  ,2,0
                                  ,decode(ogim.tipo_aliquota
                                         ,2,0
                                         ,decode(nvl(aliq.flag_fabbricati_merce, 'N')
                                                ,'S',0
                                                ,decode(ogim.aliquota_erariale
                                                       ,null,ogim.imposta
                                                       ,0
                                                       )
                                                )
                                         )
                                  )
                           )                                                    imp_dovuta_rurali
                      , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                  ,1,0
                                  ,2,0
                                  ,decode(ogim.tipo_aliquota
                                         ,2,0
                                         ,decode(nvl(aliq.flag_fabbricati_merce, 'N')
                                                ,'S',0
                                                ,decode(ogim.aliquota_erariale
                                                       ,null,nvl(ogim.imposta_acconto,0)
                                                       ,0
                                                       )
                                                )
                                         )
                                  )
                           )                                                    imp_dovuta_acc_rurali
                      , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                  ,1,0
                                  ,2,0
                                  ,decode(ogim.tipo_aliquota
                                         ,2,0
                                         ,decode(nvl(aliq.flag_fabbricati_merce, 'N')
                                                ,'S',0
                                                ,decode(ogim.aliquota_erariale
                                                       ,null,nvl(decode(titr.flag_liq_riog
                                                                       ,'S',ogim.imposta
                                                                       ,decode(noog.anno_notifica
                                                                              ,null,ogim.imposta_dovuta
                                                                              ,ogim.imposta
                                                                              )
                                                                       )
                                                                ,0)
                                                       ,0
                                                       )
                                                )
                                         )
                                  )
                           )                                                    imp_dovuta_dic_rurali
                      , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                  ,1,0
                                  ,2,0
                                  ,decode(ogim.tipo_aliquota
                                         ,2,0
                                         ,decode(nvl(aliq.flag_fabbricati_merce, 'N')
                                                ,'S',0
                                                ,decode(ogim.aliquota_erariale
                                                       ,null,nvl(decode(titr.flag_liq_riog
                                                                       ,'S',ogim.imposta_acconto
                                                                       ,decode(noog.anno_notifica
                                                                              ,null,ogim.imposta_dovuta_acconto
                                                                              ,ogim.imposta_acconto
                                                                              )
                                                                       )
                                                                ,0)
                                                       ,0
                                                       )
                                                )
                                         )
                                  )
                           )                                                    imp_dovuta_acc_dic_rurali
               -- Fabbricati D --
                      , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                  ,1,0
                                  ,2,0
                                  ,decode(ogim.tipo_aliquota
                                         ,2,0
                                         ,decode(ogim.aliquota_erariale
                                                ,null,0
                                                ,decode(sign(ogim.anno - 2012)
                                                       ,1,decode(substr(ogpr.categoria_catasto,1,1)||to_char(ogim.tipo_aliquota)
                                                                ,'D9',ogim.imposta - nvl(ogim.imposta_erariale,0)
                                                                ,0
                                                                )
                                                       ,0
                                                       )
                                                )
                                         )
                                  )
                           )                                                    imp_dovuta_fab_d_comu
                      , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                  ,1,0
                                  ,2,0
                                  ,decode(ogim.tipo_aliquota
                                         ,2,0
                                         ,decode(ogim.aliquota_erariale
                                                ,null,0
                                                ,decode(sign(ogim.anno - 2012)
                                                       ,1,decode(substr(ogpr.categoria_catasto,1,1)||to_char(ogim.tipo_aliquota)
                                                                ,'D9',nvl(ogim.imposta_acconto,0) - nvl(ogim.imposta_erariale_acconto,0)
                                                                ,0
                                                                )
                                                       ,0
                                                       )
                                                )
                                         )
                                  )
                           )                                                    imp_dovuta_acc_fab_d_comu
                      , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                  ,1,0
                                  ,2,0
                                  ,decode(ogim.tipo_aliquota
                                         ,2,0
                                         ,decode(ogim.aliquota_erariale
                                                ,null,0
                                                ,decode(sign(ogim.anno - 2012)
                                                       ,1,decode(substr(ogpr.categoria_catasto,1,1)||to_char(ogim.tipo_aliquota)
                                                                ,'D9',nvl(decode(titr.flag_liq_riog
                                                                                ,'S',nvl(ogim.imposta,0) - nvl(ogim.imposta_erariale,0)
                                                                                ,decode(noog.anno_notifica
                                                                                       ,null,nvl(ogim.imposta_dovuta,0) - nvl(ogim.imposta_erariale_dovuta,0)
                                                                                       ,nvl(ogim.imposta,0) - nvl(ogim.imposta_erariale,0)
                                                                                       )
                                                                                )
                                                                         ,0)
                                                                ,0
                                                                )
                                                       ,0
                                                       )
                                                )
                                         )
                                  )
                           )                                                    imp_dovuta_dic_fab_d_comu
                      , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                  ,1,0
                                  ,2,0
                                  ,decode(ogim.tipo_aliquota
                                         ,2,0
                                         ,decode(ogim.aliquota_erariale
                                                ,null,0
                                                ,decode(sign(ogim.anno - 2012)
                                                       ,1,decode(substr(ogpr.categoria_catasto,1,1)||to_char(ogim.tipo_aliquota)
                                                                ,'D9',nvl(decode(titr.flag_liq_riog
                                                                                ,'S',nvl(ogim.imposta_acconto,0) - nvl(ogim.imposta_erariale_acconto,0)
                                                                                ,decode(noog.anno_notifica
                                                                                       ,null,nvl(ogim.imposta_dovuta_acconto,0) - nvl(ogim.imposta_erariale_dovuta_acc,0)
                                                                                       ,nvl(ogim.imposta_acconto,0) - nvl(ogim.imposta_erariale_acconto,0)
                                                                                       )
                                                                                )
                                                                         ,0)
                                                                ,0
                                                                )
                                                       ,0
                                                       )
                                                )
                                         )
                                  )
                           )                                                    imp_dovuta_acc_dic_fab_d_comu
                      , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                  ,1,0
                                  ,2,0
                                  ,decode(ogim.tipo_aliquota
                                         ,2,0
                                         ,decode(ogim.aliquota_erariale
                                                ,null,0
                                                ,decode(sign(ogim.anno - 2012)
                                                       ,1,decode(substr(ogpr.categoria_catasto,1,1)||to_char(ogim.tipo_aliquota)
                                                                ,'D9',nvl(ogim.imposta_erariale,0)
                                                                ,0
                                                                )
                                                       ,0
                                                       )
                                                )
                                         )
                                  )
                           )                                                    imp_dovuta_fab_d_erar
                      , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                  ,1,0
                                  ,2,0
                                  ,decode(ogim.tipo_aliquota
                                         ,2,0
                                         ,decode(ogim.aliquota_erariale
                                                ,null,0
                                                ,decode(sign(ogim.anno - 2012)
                                                       ,1,decode(substr(ogpr.categoria_catasto,1,1)||to_char(ogim.tipo_aliquota)
                                                                ,'D9',nvl(ogim.imposta_erariale_acconto,0)
                                                                ,0
                                                                )
                                                       ,0
                                                       )
                                                )
                                         )
                                  )
                           )                                                    imp_dovuta_acc_fab_d_erar
                      , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                  ,1,0
                                  ,2,0
                                  ,decode(ogim.tipo_aliquota
                                         ,2,0
                                         ,decode(ogim.aliquota_erariale
                                                ,null,0
                                                ,decode(sign(ogim.anno - 2012)
                                                       ,1,decode(substr(ogpr.categoria_catasto,1,1)||to_char(ogim.tipo_aliquota)
                                                                ,'D9',nvl(decode(titr.flag_liq_riog
                                                                                ,'S',nvl(ogim.imposta_erariale,0)
                                                                                ,decode(noog.anno_notifica
                                                                                       ,null,nvl(ogim.imposta_erariale_dovuta,0)
                                                                                       ,nvl(ogim.imposta_erariale,0)
                                                                                       )
                                                                                )
                                                                         ,0)
                                                                ,0
                                                                )
                                                       ,0
                                                       )
                                                )
                                         )
                                  )
                           )                                                    imp_dovuta_dic_fab_d_erar
                      , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                  ,1,0
                                  ,2,0
                                  ,decode(ogim.tipo_aliquota
                                         ,2,0
                                         ,decode(ogim.aliquota_erariale
                                                ,null,0
                                                ,decode(sign(ogim.anno - 2012)
                                                       ,1,decode(substr(ogpr.categoria_catasto,1,1)||to_char(ogim.tipo_aliquota)
                                                                ,'D9',nvl(decode(titr.flag_liq_riog
                                                                                ,'S',nvl(ogim.imposta_erariale_acconto,0)
                                                                                ,decode(noog.anno_notifica
                                                                                       ,null,nvl(ogim.imposta_erariale_dovuta_acc,0)
                                                                                       ,nvl(ogim.imposta_erariale_acconto,0)
                                                                                       )
                                                                                )
                                                                         ,0)
                                                                ,0
                                                                )
                                                       ,0
                                                       )
                                                )
                                         )
                                  )
                           )                                                    imp_dovuta_acc_dic_fab_d_erar
               -- Altri Fabbricati --
                      , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                  ,1,0
                                  ,2,0
                                  ,decode(ogim.tipo_aliquota
                                         ,2,0
                                         ,decode(ogim.aliquota_erariale
                                                ,null,0
                                                ,decode(sign(ogim.anno - 2012)
                                                       ,1,decode(substr(ogpr.categoria_catasto,1,1)||to_char(ogim.tipo_aliquota)
                                                                ,'D9',0
                                                                ,decode(nvl(aliq.flag_fabbricati_merce,'N')
                                                                       ,'S',0
                                                                       ,ogim.imposta
                                                                       )
                                                                )
                                                       ,ogim.imposta
                                                       )
                                                )
                                         )
                                  )
                           )                                                    imp_dovuta_altri
                      , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                  ,1,0
                                  ,2,0
                                  ,decode(ogim.tipo_aliquota
                                         ,2,0
                                         ,decode(ogim.aliquota_erariale
                                                ,null,0
                                                ,decode(sign(ogim.anno - 2012)
                                                       ,1,decode(substr(ogpr.categoria_catasto,1,1)||to_char(ogim.tipo_aliquota)
                                                                ,'D9',0
                                                                ,decode(nvl(aliq.flag_fabbricati_merce,'N')
                                                                       ,'S',0
                                                                       ,nvl(ogim.imposta_acconto,0)
                                                                       )
                                                                )
                                                       ,nvl(ogim.imposta_acconto,0)
                                                       )
                                                )
                                         )
                                  )
                           )                                                    imp_dovuta_acc_altri
                      , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                  ,1,0
                                  ,2,0
                                  ,decode(ogim.tipo_aliquota
                                         ,2,0
                                         ,decode(ogim.aliquota_erariale
                                                ,null,0
                                                ,decode(sign(ogim.anno - 2012)
                                                       ,1,decode(substr(ogpr.categoria_catasto,1,1)||to_char(ogim.tipo_aliquota)
                                                                ,'D9',0
                                                                ,decode(nvl(aliq.flag_fabbricati_merce,'N')
                                                                       ,'S',0
                                                                       ,nvl(decode(titr.flag_liq_riog
                                                                                  ,'S',nvl(ogim.imposta,0)
                                                                                  ,decode(noog.anno_notifica
                                                                                         ,null,nvl(ogim.imposta_dovuta,0)
                                                                                         ,nvl(ogim.imposta,0)
                                                                                         )
                                                                                  )
                                                                           ,0)
                                                                       )
                                                                )
                                                       ,nvl(decode(titr.flag_liq_riog
                                                                  ,'S',nvl(ogim.imposta,0)
                                                                  ,decode(noog.anno_notifica
                                                                         ,null,nvl(ogim.imposta_dovuta,0)
                                                                         ,nvl(ogim.imposta,0)
                                                                          )
                                                                  )
                                                           ,0)
                                                       )
                                                )
                                         )
                                  )
                           )                                                    imp_dovuta_dic_altri
                      , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                  ,1,0
                                  ,2,0
                                  ,decode(ogim.tipo_aliquota
                                         ,2,0
                                         ,decode(ogim.aliquota_erariale
                                                ,null,0
                                                ,decode(sign(ogim.anno - 2012)
                                                       ,1,decode(substr(ogpr.categoria_catasto,1,1)||to_char(ogim.tipo_aliquota)
                                                                ,'D9',0
                                                                ,decode(nvl(aliq.flag_fabbricati_merce,'N')
                                                                       ,'S',0
                                                                       ,nvl(decode(titr.flag_liq_riog
                                                                                  ,'S',nvl(ogim.imposta_acconto,0)
                                                                                  ,decode(noog.anno_notifica
                                                                                         ,null,nvl(ogim.imposta_dovuta_acconto,0)
                                                                                         ,nvl(ogim.imposta_acconto,0)
                                                                                         )
                                                                                  )
                                                                           ,0)
                                                                       )
                                                                )
                                                       ,nvl(decode(titr.flag_liq_riog
                                                                  ,'S',nvl(ogim.imposta_acconto,0)
                                                                  ,decode(noog.anno_notifica
                                                                         ,null,nvl(ogim.imposta_dovuta_acconto,0)
                                                                         ,nvl(ogim.imposta_acconto,0)
                                                                         )
                                                                  )
                                                           ,0)
                                                       )
                                                )
                                         )
                                  )
                           )                                                    imp_dovuta_acc_dic_altri
                      , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                  ,1,0
                                  ,2,0
                                  ,decode(ogim.tipo_aliquota
                                         ,2,0
                                         ,decode(ogim.aliquota_erariale
                                                ,null,0
                                                ,decode(sign(ogim.anno - 2012)
                                                       ,1,decode(substr(ogpr.categoria_catasto,1,1)||to_char(ogim.tipo_aliquota)
                                                                ,'D9',0
                                                                ,decode(nvl(aliq.flag_fabbricati_merce,'N')
                                                                       ,'S',0
                                                                       ,ogim.imposta - nvl(ogim.imposta_erariale,0)
                                                                       )
                                                                )
                                                       ,ogim.imposta - nvl(ogim.imposta_erariale,0)
                                                       )
                                                )
                                         )
                                  )
                           )                                                    imp_dovuta_altri_comu
                      , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                  ,1,0
                                  ,2,0
                                  ,decode(ogim.tipo_aliquota
                                         ,2,0
                                         ,decode(ogim.aliquota_erariale
                                                ,null,0
                                                ,decode(sign(ogim.anno - 2012)
                                                       ,1,decode(substr(ogpr.categoria_catasto,1,1)||to_char(ogim.tipo_aliquota)
                                                                ,'D9',0
                                                                ,decode(nvl(aliq.flag_fabbricati_merce,'N')
                                                                       ,'S',0
                                                                       ,nvl(ogim.imposta_acconto,0) - nvl(ogim.imposta_erariale_acconto,0)
                                                                       )
                                                                )
                                                       ,nvl(ogim.imposta_acconto,0) - nvl(ogim.imposta_erariale_acconto,0)
                                                       )
                                                )
                                         )
                                  )
                           )                                                    imp_dovuta_acc_altri_comu
                      , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                  ,1,0
                                  ,2,0
                                  ,decode(ogim.tipo_aliquota
                                         ,2,0
                                         ,decode(ogim.aliquota_erariale
                                                ,null,0
                                                ,decode(sign(ogim.anno - 2012)
                                                       ,1,decode(substr(ogpr.categoria_catasto,1,1)||to_char(ogim.tipo_aliquota)
                                                                ,'D9',0
                                                                ,decode(nvl(aliq.flag_fabbricati_merce,'N')
                                                                       ,'S',0
                                                                       ,nvl(decode(titr.flag_liq_riog
                                                                                  ,'S',nvl(ogim.imposta,0) - nvl(ogim.imposta_erariale,0)
                                                                                  ,decode(noog.anno_notifica
                                                                                         ,null,nvl(ogim.imposta_dovuta,0) - nvl(ogim.imposta_erariale_dovuta,0)
                                                                                         ,nvl(ogim.imposta,0) - nvl(ogim.imposta_erariale,0)
                                                                                         )
                                                                                  )
                                                                           ,0)
                                                                       )
                                                                )
                                                       ,nvl(decode(titr.flag_liq_riog
                                                                  ,'S',nvl(ogim.imposta,0) - nvl(ogim.imposta_erariale,0)
                                                                  ,decode(noog.anno_notifica
                                                                         ,null,nvl(ogim.imposta_dovuta,0) - nvl(ogim.imposta_erariale_dovuta,0)
                                                                         ,nvl(ogim.imposta,0) - nvl(ogim.imposta_erariale,0)
                                                                          )
                                                                  )
                                                           ,0)
                                                       )
                                                )
                                         )
                                  )
                           )                                                    imp_dovuta_dic_altri_comu
                      , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                  ,1,0
                                  ,2,0
                                  ,decode(ogim.tipo_aliquota
                                         ,2,0
                                         ,decode(ogim.aliquota_erariale
                                                ,null,0
                                                ,decode(sign(ogim.anno - 2012)
                                                       ,1,decode(substr(ogpr.categoria_catasto,1,1)||to_char(ogim.tipo_aliquota)
                                                                ,'D9',0
                                                                ,decode(nvl(aliq.flag_fabbricati_merce,'N')
                                                                       ,'S',0
                                                                       ,nvl(decode(titr.flag_liq_riog
                                                                                  ,'S',nvl(ogim.imposta_acconto,0) - nvl(ogim.imposta_erariale_acconto,0)
                                                                                  ,decode(noog.anno_notifica
                                                                                         ,null,nvl(ogim.imposta_dovuta_acconto,0) - nvl(ogim.imposta_erariale_dovuta_acc,0)
                                                                                         ,nvl(ogim.imposta_acconto,0) - nvl(ogim.imposta_erariale_acconto,0)
                                                                                         )
                                                                                  )
                                                                           ,0)
                                                                       )
                                                                )
                                                       ,nvl(decode(titr.flag_liq_riog
                                                                  ,'S',nvl(ogim.imposta_acconto,0) - nvl(ogim.imposta_erariale_acconto,0)
                                                                  ,decode(noog.anno_notifica
                                                                         ,null,nvl(ogim.imposta_dovuta_acconto,0) - nvl(ogim.imposta_erariale_dovuta_acc,0)
                                                                         ,nvl(ogim.imposta_acconto,0) - nvl(ogim.imposta_erariale_acconto,0)
                                                                         )
                                                                  )
                                                           ,0)
                                                       )
                                                )
                                         )
                                  )
                           )                                                    imp_dovuta_acc_dic_altri_comu
                      , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                  ,1,0
                                  ,2,0
                                  ,decode(ogim.tipo_aliquota
                                         ,2,0
                                         ,decode(ogim.aliquota_erariale
                                                ,null,0
                                                ,decode(sign(ogim.anno - 2012)
                                                       ,1,decode(substr(ogpr.categoria_catasto,1,1)||to_char(ogim.tipo_aliquota)
                                                                ,'D9',0
                                                                ,decode(nvl(aliq.flag_fabbricati_merce,'N')
                                                                       ,'S',0
                                                                       ,nvl(ogim.imposta_erariale,0)
                                                                       )
                                                                )
                                                       ,nvl(ogim.imposta_erariale,0)
                                                       )
                                                )
                                         )
                                  )
                           )                                                    imp_dovuta_altri_erar
                      , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                  ,1,0
                                  ,2,0
                                  ,decode(ogim.tipo_aliquota
                                         ,2,0
                                         ,decode(ogim.aliquota_erariale
                                                ,null,0
                                                ,decode(sign(ogim.anno - 2012)
                                                       ,1,decode(substr(ogpr.categoria_catasto,1,1)||to_char(ogim.tipo_aliquota)
                                                                ,'D9',0
                                                                ,decode(nvl(aliq.flag_fabbricati_merce,'N')
                                                                       ,'S',0
                                                                       ,nvl(ogim.imposta_erariale_acconto,0)
                                                                       )
                                                                )
                                                       ,nvl(ogim.imposta_erariale_acconto,0)
                                                       )
                                                )
                                         )
                                  )
                           )                                                    imp_dovuta_acc_altri_erar
                      , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                  ,1,0
                                  ,2,0
                                  ,decode(ogim.tipo_aliquota
                                         ,2,0
                                         ,decode(ogim.aliquota_erariale
                                                ,null,0
                                                ,decode(sign(ogim.anno - 2012)
                                                       ,1,decode(substr(ogpr.categoria_catasto,1,1)||to_char(ogim.tipo_aliquota)
                                                                ,'D9',0
                                                                ,decode(nvl(aliq.flag_fabbricati_merce,'N')
                                                                       ,'S',0
                                                                       ,nvl(decode(titr.flag_liq_riog
                                                                                  ,'S',nvl(ogim.imposta_erariale,0)
                                                                                  ,decode(noog.anno_notifica
                                                                                         ,null,nvl(ogim.imposta_erariale_dovuta,0)
                                                                                         ,nvl(ogim.imposta_erariale,0)
                                                                                         )
                                                                                  )
                                                                           ,0)
                                                                       )
                                                                )
                                                       ,nvl(decode(titr.flag_liq_riog
                                                                  ,'S',nvl(ogim.imposta_erariale,0)
                                                                  ,decode(noog.anno_notifica
                                                                         ,null,nvl(ogim.imposta_erariale_dovuta,0)
                                                                         ,nvl(ogim.imposta_erariale,0)
                                                                          )
                                                                  )
                                                           ,0)
                                                       )
                                                )
                                         )
                                  )
                           )                                                    imp_dovuta_dic_altri_erar
                      , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                  ,1,0
                                  ,2,0
                                  ,decode(ogim.tipo_aliquota
                                         ,2,0
                                         ,decode(ogim.aliquota_erariale
                                                ,null,0
                                                ,decode(sign(ogim.anno - 2012)
                                                       ,1,decode(substr(ogpr.categoria_catasto,1,1)||to_char(ogim.tipo_aliquota)
                                                                ,'D9',0
                                                                ,decode(nvl(aliq.flag_fabbricati_merce,'N')
                                                                       ,'S',0
                                                                       ,nvl(decode(titr.flag_liq_riog
                                                                                  ,'S',nvl(ogim.imposta_erariale_acconto,0)
                                                                                  ,decode(noog.anno_notifica
                                                                                         ,null,nvl(ogim.imposta_erariale_dovuta_acc,0)
                                                                                         ,nvl(ogim.imposta_erariale_acconto,0)
                                                                                         )
                                                                                  )
                                                                           ,0)
                                                                       )
                                                                )
                                                       ,nvl(decode(titr.flag_liq_riog
                                                                  ,'S',nvl(ogim.imposta_erariale_acconto,0)
                                                                  ,decode(noog.anno_notifica
                                                                         ,null,nvl(ogim.imposta_erariale_dovuta_acc,0)
                                                                         ,nvl(ogim.imposta_erariale_acconto,0)
                                                                         )
                                                                  )
                                                           ,0)
                                                       )
                                                )
                                         )
                                  )
                           )                                                    imp_dovuta_acc_dic_altri_erar
               -- Fabbricati Merce --
                      , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                  ,1,0
                                  ,2,0
                                  ,decode(nvl(aliq.flag_fabbricati_merce, 'N')
                                         ,'S',ogim.imposta
                                         ,0
                                         )
                                  )
                           )                                                    imp_dovuta_fabb_merce
                      , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                  ,1,0
                                  ,2,0
                                  ,decode(nvl(aliq.flag_fabbricati_merce, 'N')
                                         ,'S',nvl(ogim.imposta_acconto,0)
                                         ,0
                                         )
                                  )
                           )                                                    imp_dovuta_acc_fabb_merce
                      , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                  ,1,0
                                  ,2,0
                                  ,decode(nvl(aliq.flag_fabbricati_merce, 'N')
                                         ,'S',nvl(decode(titr.flag_liq_riog
                                                        ,'S',ogim.imposta
                                                        ,decode(noog.anno_notifica
                                                               ,null,ogim.imposta_dovuta
                                                               ,ogim.imposta
                                                               )
                                                        )
                                                 ,0)
                                         ,0
                                         )
                                  )
                           )                                                    imp_dovuta_dic_fabb_merce
                      , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                  ,1,0
                                  ,2,0
                                  ,decode(nvl(aliq.flag_fabbricati_merce, 'N')
                                         ,'S',nvl(decode(titr.flag_liq_riog
                                                        ,'S',ogim.imposta_acconto
                                                        ,decode(noog.anno_notifica
                                                               ,null,ogim.imposta_dovuta_acconto
                                                               ,ogim.imposta_acconto
                                                               )
                                                        )
                                                 ,0)
                                         ,0
                                         )
                                  )
                           )                                                    imp_dovuta_acc_dic_fabb_merce
               -- Mini IMU
                      , sum(nvl(ogim.imposta_mini, 0))                          imp_dovuta_mini
                      , sum(nvl(decode(titr.flag_liq_riog
                                      ,'S',ogim.imposta_mini
                                      ,decode(noog.anno_notifica
                                             ,null,ogim.imposta_dovuta_mini
                                             ,ogim.imposta_mini
                                             )
                                      )
                               ,0))                                             imp_dovuta_mini_dic
                      , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                  ,1,0
                                  ,2,0
                                  ,decode(ogim.tipo_aliquota
                                         ,2,nvl(ogim.imposta_mini, 0)
                                         ,0
                                         )
                                  )
                           )                                                    imp_dovuta_mini_ab
                      , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                  ,1,0
                                  ,2,0
                                  ,decode(ogim.tipo_aliquota
                                         ,2,nvl(decode(titr.flag_liq_riog
                                                         ,'S',ogim.imposta_mini
                                                         ,decode(noog.anno_notifica
                                                                ,null,ogim.imposta_dovuta_mini
                                                                ,ogim.imposta_mini
                                                                )
                                                         )
                                                  , 0)
                                         ,0
                                         )
                                  )
                           )                                                    imp_dovuta_mini_dic_ab
                      , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                  ,1,nvl(ogim.imposta_mini, 0)
                                  ,0
                                  )
                           )                                                    imp_dovuta_mini_ter
                      , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                  ,1,nvl(decode(titr.flag_liq_riog
                                               ,'S',ogim.imposta_mini
                                               ,decode(noog.anno_notifica
                                                      ,null,ogim.imposta_dovuta_mini
                                                      ,ogim.imposta_mini
                                                      )
                                               )
                                        , 0)
                                  ,0
                                  )
                           )                                                          imp_dovuta_mini_dic_ter
                into w_imp_dovuta
                   , w_imp_dovuta_acconto
                   , w_imp_dovuta_dic
                   , w_imp_dovuta_acconto_dic
                   , w_imp_dovuta_ab
                   , w_imp_dovuta_acconto_ab
                   , w_imp_dovuta_dic_ab
                   , w_imp_dovuta_acconto_dic_ab
                   , w_imp_dovuta_ter
                   , w_imp_dovuta_acconto_ter
                   , w_imp_dovuta_dic_ter
                   , w_imp_dovuta_acconto_dic_ter
                   , w_imp_dov_ter_comu
                   , w_imp_dov_acc_ter_comu
                   , w_imp_dov_dic_ter_comu
                   , w_imp_dov_acc_dic_ter_comu
                   , w_imp_dov_ter_erar
                   , w_imp_dov_acc_ter_erar
                   , w_imp_dov_dic_ter_erar
                   , w_imp_dov_acc_dic_ter_erar
                   , w_imp_dovuta_aree
                   , w_imp_dovuta_acconto_aree
                   , w_imp_dovuta_dic_aree
                   , w_imp_dovuta_acconto_dic_aree
                   , w_imp_dov_aree_comu
                   , w_imp_dov_acc_aree_comu
                   , w_imp_dov_dic_aree_comu
                   , w_imp_dov_acc_dic_aree_comu
                   , w_imp_dov_aree_erar
                   , w_imp_dov_acc_aree_erar
                   , w_imp_dov_dic_aree_erar
                   , w_imp_dov_acc_dic_aree_erar
                   , w_imp_dov_rur
                   , w_imp_dov_acc_rur
                   , w_imp_dov_dic_rur
                   , w_imp_dov_acc_dic_rur
                   , w_imp_dov_fab_d_comu
                   , w_imp_dov_acc_fab_d_comu
                   , w_imp_dov_dic_fab_d_comu
                   , w_imp_dov_acc_dic_fab_d_comu
                   , w_imp_dov_fab_d_erar
                   , w_imp_dov_acc_fab_d_erar
                   , w_imp_dov_dic_fab_d_erar
                   , w_imp_dov_acc_dic_fab_d_erar
                   , w_imp_dovuta_altri
                   , w_imp_dovuta_acconto_altri
                   , w_imp_dovuta_dic_altri
                   , w_imp_dovuta_acconto_dic_altri
                   , w_imp_dov_altri_comu
                   , w_imp_dov_acc_altri_comu
                   , w_imp_dov_dic_altri_comu
                   , w_imp_dov_acc_dic_altri_comu
                   , w_imp_dov_altri_erar
                   , w_imp_dov_acc_altri_erar
                   , w_imp_dov_dic_altri_erar
                   , w_imp_dov_acc_dic_altri_erar
                   , w_imp_dov_fab_m
                   , w_imp_dov_acc_fab_m
                   , w_imp_dov_dic_fab_m
                   , w_imp_dov_acc_dic_fab_m
                   , w_imp_dovuta_mini
                   , w_imp_dovuta_mini_dic
                   , w_imp_dovuta_mini_ab
                   , w_imp_dovuta_mini_dic_ab
                   , w_imp_dovuta_mini_ter
                   , w_imp_dovuta_mini_dic_ter
                from pratiche_tributo      prtr
                   , oggetti_pratica       ogpr
                   , oggetti_contribuente  ogco
                   , oggetti               ogge
                -- , oggetti_imposta       ogim
                   , oggetti_imposta_ogim  ogim
                   , dati_generali         dage
                   , notifiche_oggetto     noog
                   , tipi_tributo          titr
                   , aliquote              aliq
               where ogim.cod_fiscale       = rec_cont.cod_fiscale
                 and ogim.anno              = a_anno
                 and prtr.pratica           = ogpr.pratica
                 and ogim.oggetto_pratica   = ogpr.oggetto_pratica
                 and ogim.oggetto_pratica   = ogco.oggetto_pratica
                 and ogim.cod_fiscale       = ogco.cod_fiscale
                 and ogpr.oggetto           = ogge.oggetto
                 and titr.tipo_tributo      = prtr.tipo_tributo
                 and prtr.tipo_tributo||''  = C_TIPO_TRIBUTO
                 and ogim.flag_calcolo      = 'S'
                 and ogim.tipo_tributo      = aliq.tipo_tributo(+)
                 and ogim.anno              = aliq.anno(+)
                 and ogim.tipo_aliquota     = aliq.tipo_aliquota(+)
                 and noog.cod_fiscale (+)   = rec_cont.cod_fiscale
                 and noog.anno_notifica (+) < a_anno
                 and noog.oggetto (+)       = ogpr.oggetto
              group by dage.fase_euro
               ;
             EXCEPTION
               WHEN no_data_found THEN
                 w_imp_dovuta := 0;
                 w_imp_dovuta_mini := 0;
               WHEN others THEN
                 w_errore := 'Errore in totalizzazione imposta dovuta 2 ('||SQLERRM||')';
                 RAISE errore;
             END;
          end if; --Sassuolo: calcolo dell'imposta e dell'acconto dovuti e dichiarati diverso
          --
          -- Mini IMU: per il 2013, in presenza di mini IMU, si considerano
          --           i versamenti di tipo 'U' come relativi alla mini IMU
          --
          if w_imp_dovuta_mini > 0 then
             if w_versamenti_acconto >= w_versamenti_mini then
                if w_versamenti_mini > round(w_imp_dovuta_mini) then
                   w_versamenti_mini := round(w_imp_dovuta_mini);
                end if;
                w_versamenti_acconto := w_versamenti_acconto - w_versamenti_mini;
             end if;
             if w_versamenti_acconto_ab >= w_versamenti_mini_ab then
                if w_versamenti_mini_ab > round(w_imp_dovuta_mini_ab) then
                   w_versamenti_mini_ab := round(w_imp_dovuta_mini_ab);
                end if;
                w_versamenti_acconto_ab := w_versamenti_acconto_ab - w_versamenti_mini_ab;
             end if;
             if w_versamenti_acconto_ter >= w_versamenti_mini_ter then
                if w_versamenti_mini_ter > round(w_imp_dovuta_mini_ter) then
                   w_versamenti_mini_ter := round(w_imp_dovuta_mini_ter);
                end if;
                w_versamenti_acconto_ter := w_versamenti_acconto_ter - w_versamenti_mini_ter;
             end if;
          else
             w_versamenti_mini := 0;
             w_versamenti_mini_ab := 0;
             w_versamenti_mini_ter := 0;
          end if;
          if w_commenti = 1 then
             dbms_output.put_line('CALCOLO_LIQUIDAZIONI_IMU w_imp_dovuta w_versamenti '|| w_imp_dovuta ||' '||w_versamenti);
             dbms_output.put_line('CALCOLO_LIQUIDAZIONI_IMU w_imp_dovuta_acconto w_versamenti_acconto '|| w_imp_dovuta_acconto ||' '||w_versamenti_acconto);
             dbms_output.put_line('CALCOLO_LIQUIDAZIONI_IMU w_imp_dovuta_mini w_versamenti_mini '|| w_imp_dovuta_mini ||' '||w_versamenti_mini);
             dbms_output.put_line('CALCOLO_LIQUIDAZIONI_IMU (1) w_imp_dovuta_dic '||w_imp_dovuta_dic);
             dbms_output.put_line('CALCOLO_LIQUIDAZIONI_IMU (1) w_imp_dovuta_ab '||w_imp_dovuta_ab);
             dbms_output.put_line('CALCOLO_LIQUIDAZIONI_IMU (1) w_imp_dovuta_acconto_ab '||w_imp_dovuta_acconto_ab);
             dbms_output.put_line('CALCOLO_LIQUIDAZIONI_IMU (1) w_imp_dovuta_dic_ab '||w_imp_dovuta_dic_ab);
             dbms_output.put_line('CALCOLO_LIQUIDAZIONI_IMU (1) w_imp_dovuta_acconto_dic_ab '||w_imp_dovuta_acconto_dic_ab);
          end if;
          --Inserimento dati in Pratiche Tributo e Rapporti Tributo
          BEGIN
               insert into pratiche_tributo
                     (pratica,cod_fiscale,tipo_tributo,anno,
                      tipo_pratica,tipo_evento,data,utente,data_variazione)
               values (w_pratica,rec_cont.cod_fiscale,C_TIPO_TRIBUTO,a_anno,
                      'L','U',trunc(a_data_liquidazione),a_utente,trunc(sysdate))
               ;
          EXCEPTION
               WHEN others THEN
                  w_errore := 'Errore in inserimento pratica ('||SQLERRM||')';
                  RAISE errore;
          END;
          BEGIN
               insert into rapporti_tributo(pratica,cod_fiscale)
               values (w_pratica,rec_cont.cod_fiscale);
          EXCEPTION
               WHEN others THEN
                    w_errore := 'Errore in inserimento rapporto ('||SQLERRM||')';
                 RAISE errore;
          END;
          w_cont_non_liq := a_cont_non_liq;
          LIQUIDAZIONI_IMU_RENDITA(a_anno, w_pratica, rec_cont.cod_fiscale
                     , w_imp_dovuta, w_imp_dovuta_acconto, w_imp_dovuta_dic, w_imp_dovuta_acconto_dic
                     , w_imp_dovuta_ab, w_imp_dovuta_acconto_ab, w_imp_dovuta_dic_ab, w_imp_dovuta_acconto_dic_ab
                     , w_imp_dovuta_ter, w_imp_dovuta_acconto_ter, w_imp_dovuta_dic_ter, w_imp_dovuta_acconto_dic_ter
                     , w_imp_dov_ter_comu, w_imp_dov_acc_ter_comu, w_imp_dov_dic_ter_comu, w_imp_dov_acc_dic_ter_comu
                     , w_imp_dov_ter_erar, w_imp_dov_acc_ter_erar, w_imp_dov_dic_ter_erar, w_imp_dov_acc_dic_ter_erar
                     , w_imp_dovuta_aree, w_imp_dovuta_acconto_aree, w_imp_dovuta_dic_aree, w_imp_dovuta_acconto_dic_aree
                     , w_imp_dov_aree_comu, w_imp_dov_acc_aree_comu, w_imp_dov_dic_aree_comu, w_imp_dov_acc_dic_aree_comu
                     , w_imp_dov_aree_erar, w_imp_dov_acc_aree_erar, w_imp_dov_dic_aree_erar, w_imp_dov_acc_dic_aree_erar
                     , w_imp_dov_rur, w_imp_dov_acc_rur, w_imp_dov_dic_rur, w_imp_dov_acc_dic_rur
                     , w_imp_dov_fab_d_comu, w_imp_dov_acc_fab_d_comu, w_imp_dov_dic_fab_d_comu, w_imp_dov_acc_dic_fab_d_comu
                     , w_imp_dov_fab_d_erar, w_imp_dov_acc_fab_d_erar, w_imp_dov_dic_fab_d_erar, w_imp_dov_acc_dic_fab_d_erar
                     , w_imp_dovuta_altri, w_imp_dovuta_acconto_altri, w_imp_dovuta_dic_altri, w_imp_dovuta_acconto_dic_altri
                     , w_imp_dov_altri_comu, w_imp_dov_acc_altri_comu, w_imp_dov_dic_altri_comu, w_imp_dov_acc_dic_altri_comu
                     , w_imp_dov_altri_erar, w_imp_dov_acc_altri_erar, w_imp_dov_dic_altri_erar, w_imp_dov_acc_dic_altri_erar
                     , w_imp_dov_fab_m, w_imp_dov_acc_fab_m, w_imp_dov_dic_fab_m, w_imp_dov_acc_dic_fab_m
                     , w_imp_dovuta_mini, w_imp_dovuta_mini_dic
                     , w_imp_dovuta_mini_ab, w_imp_dovuta_mini_dic_ab
                     , w_imp_dovuta_mini_ter, w_imp_dovuta_mini_dic_ter
                     , w_versamenti, w_versamenti_acconto
                     , w_versamenti_ab, w_versamenti_acconto_ab
                     , w_versamenti_ter, w_versamenti_acconto_ter
                     , w_versamenti_aree, w_versamenti_acconto_aree
                     , w_versamenti_altri, w_versamenti_acconto_altri
                     , w_vers_rurali, w_vers_acconto_rurali
                     , w_vers_ter_comu, w_vers_acconto_ter_comu
                     , w_vers_ter_erar, w_vers_acconto_ter_erar
                     , w_vers_aree_comu, w_vers_acconto_aree_comu
                     , w_vers_aree_erar, w_vers_acconto_aree_erar
                     , w_vers_altri_comu, w_vers_acconto_altri_comu
                     , w_vers_altri_erar, w_vers_acconto_altri_erar
                     , w_vers_fab_d_comu, w_vers_acconto_fab_d_comu
                     , w_vers_fab_d_erar, w_vers_acconto_fab_d_erar
                     , w_vers_fab_merce, w_vers_acconto_fab_merce
                     , w_versamenti_mini, w_versamenti_mini_ab, w_versamenti_mini_ter
                     , a_cont_non_liq, a_utente);
          if w_commenti = 1 then
             dbms_output.put_line('CALCOLO_LIQUIDAZIONI_IMU (2) w_imp_dovuta_dic '||w_imp_dovuta_dic);
             dbms_output.put_line('CALCOLO_LIQUIDAZIONI_IMU w_cont_non_liq = a_cont_non_liq '|| w_cont_non_liq ||' '|| a_cont_non_liq );
          end if;
          --Se nella LIQUIDAZIONI_IMU_RENDITA il numero di contribuenti la cui liquidazione
          --non è andata a buon fine non è cambiato
          IF w_cont_non_liq = a_cont_non_liq THEN
             w_imp_dovuta_saldo            := nvl(w_imp_dovuta,0) - nvl(w_imp_dovuta_acconto,0) - nvl(w_imp_dovuta_mini,0);
             w_imp_dovuta_saldo_dic        := nvl(w_imp_dovuta_dic,0) - nvl(w_imp_dovuta_acconto_dic,0) - nvl(w_imp_dovuta_mini_dic,0);
             w_imp_dovuta_saldo_ab         := nvl(w_imp_dovuta_ab,0) - nvl(w_imp_dovuta_acconto_ab,0) - nvl(w_imp_dovuta_mini_ab,0);
             w_imp_dovuta_saldo_dic_ab     := nvl(w_imp_dovuta_dic_ab,0) - nvl(w_imp_dovuta_acconto_dic_ab,0) - nvl(w_imp_dovuta_mini_dic_ab,0);
             w_versamenti_saldo            := nvl(w_versamenti,0) - nvl(w_versamenti_acconto,0) - nvl(w_versamenti_mini,0);
             w_versamenti_saldo_ab         := nvl(w_versamenti_ab,0) - nvl(w_versamenti_acconto_ab,0) - nvl(w_versamenti_mini_ab,0);
             w_imp_dovuta_saldo_ter        := nvl(w_imp_dovuta_ter,0) - nvl(w_imp_dovuta_acconto_ter,0) - nvl(w_imp_dovuta_mini_ter,0);
             w_imp_dovuta_saldo_dic_ter    := nvl(w_imp_dovuta_dic_ter,0) - nvl(w_imp_dovuta_acconto_dic_ter,0) - nvl(w_imp_dovuta_mini_dic_ter,0);
             w_imp_dov_saldo_ter_comu      := nvl(w_imp_dov_ter_comu,0) - nvl(w_imp_dov_acc_ter_comu,0) - nvl(w_imp_dovuta_mini_ter,0);
             w_imp_dov_saldo_dic_ter_comu  := nvl(w_imp_dov_dic_ter_comu,0) - nvl(w_imp_dov_acc_dic_ter_comu,0) - nvl(w_imp_dovuta_mini_dic_ter,0);
             w_imp_dov_saldo_ter_erar      := nvl(w_imp_dov_ter_erar,0) - nvl(w_imp_dov_acc_ter_erar,0);
             w_imp_dov_saldo_dic_ter_erar  := nvl(w_imp_dov_dic_ter_erar,0) - nvl(w_imp_dov_acc_dic_ter_erar,0);
             w_versamenti_saldo_ter        := nvl(w_versamenti_ter,0) - nvl(w_versamenti_acconto_ter,0) - nvl(w_versamenti_mini_ter,0);
             w_vers_saldo_ter_comu         := nvl(w_vers_ter_comu,0) - nvl(w_vers_acconto_ter_comu,0) - nvl(w_versamenti_mini_ter,0);
             w_vers_saldo_ter_erar         := nvl(w_vers_ter_erar,0) - nvl(w_vers_acconto_ter_erar,0);
             w_imp_dovuta_saldo_aree       := nvl(w_imp_dovuta_aree,0) - nvl(w_imp_dovuta_acconto_aree,0);
             w_imp_dovuta_saldo_dic_aree   := nvl(w_imp_dovuta_dic_aree,0) - nvl(w_imp_dovuta_acconto_dic_aree,0);
             w_imp_dov_saldo_aree_comu     := nvl(w_imp_dov_aree_comu,0) - nvl(w_imp_dov_acc_aree_comu,0);
             w_imp_dov_saldo_dic_aree_comu := nvl(w_imp_dov_dic_aree_comu,0) - nvl(w_imp_dov_acc_dic_aree_comu,0);
             w_imp_dov_saldo_aree_erar     := nvl(w_imp_dov_aree_erar,0) - nvl(w_imp_dov_acc_aree_erar,0);
             w_imp_dov_saldo_dic_aree_erar := nvl(w_imp_dov_dic_aree_erar,0) - nvl(w_imp_dov_acc_dic_aree_erar,0);
             w_versamenti_saldo_aree       := nvl(w_versamenti_aree,0) - nvl(w_versamenti_acconto_aree,0);
             w_vers_saldo_aree_comu        := nvl(w_vers_aree_comu,0) - nvl(w_vers_acconto_aree_comu,0);
             w_vers_saldo_aree_erar        := nvl(w_vers_aree_erar,0) - nvl(w_vers_acconto_aree_erar,0);
             w_imp_dov_saldo_rur           := nvl(w_imp_dov_rur,0) - nvl(w_imp_dov_acc_rur,0);
             w_imp_dov_saldo_dic_rur       := nvl(w_imp_dov_dic_rur,0) - nvl(w_imp_dov_acc_dic_rur,0);
             w_vers_saldo_rurali           := nvl(w_vers_rurali,0) - nvl(w_vers_acconto_rurali,0);
             w_imp_dov_saldo_fab_d_comu     := nvl(w_imp_dov_fab_d_comu,0) - nvl(w_imp_dov_acc_fab_d_comu,0);
             w_imp_dov_saldo_dic_fab_d_comu := nvl(w_imp_dov_dic_fab_d_comu,0) - nvl(w_imp_dov_acc_dic_fab_d_comu,0);
             w_imp_dov_saldo_fab_d_erar     := nvl(w_imp_dov_fab_d_erar,0) - nvl(w_imp_dov_acc_fab_d_erar,0);
             w_imp_dov_saldo_dic_fab_d_erar := nvl(w_imp_dov_dic_fab_d_erar,0) - nvl(w_imp_dov_acc_dic_fab_d_erar,0);
             w_vers_saldo_fab_d_comu        := nvl(w_vers_fab_d_comu,0) - nvl(w_vers_acconto_fab_d_comu,0);
             w_vers_saldo_fab_d_erar        := nvl(w_vers_fab_d_erar,0) - nvl(w_vers_acconto_fab_d_erar,0);
             w_imp_dovuta_saldo_altri       := nvl(w_imp_dovuta_altri,0) - nvl(w_imp_dovuta_acconto_altri,0);
             w_imp_dovuta_saldo_dic_altri   := nvl(w_imp_dovuta_dic_altri,0) - nvl(w_imp_dovuta_acconto_dic_altri,0);
             w_imp_dov_saldo_altri_comu     := nvl(w_imp_dov_altri_comu,0) - nvl(w_imp_dov_acc_altri_comu,0);
             w_imp_dov_saldo_dic_altri_comu := nvl(w_imp_dov_dic_altri_comu,0) - nvl(w_imp_dov_acc_dic_altri_comu,0);
             w_imp_dov_saldo_altri_erar     := nvl(w_imp_dov_altri_erar,0) - nvl(w_imp_dov_acc_altri_erar,0);
             w_imp_dov_saldo_dic_altri_erar := nvl(w_imp_dov_dic_altri_erar,0) - nvl(w_imp_dov_acc_dic_altri_erar,0);
             w_versamenti_saldo_altri       := nvl(w_versamenti_altri,0) - nvl(w_versamenti_acconto_altri,0);
             w_vers_saldo_altri_comu        := nvl(w_vers_altri_comu,0) - nvl(w_vers_acconto_altri_comu,0);
             w_vers_saldo_altri_erar        := nvl(w_vers_altri_erar,0) - nvl(w_vers_acconto_altri_erar,0);
             -- Fabbricati merce
             w_imp_dov_saldo_fab_m          := nvl(w_imp_dov_fab_m,0) - nvl(w_imp_dov_acc_fab_m,0);
             w_imp_dov_saldo_dic_fab_m      := nvl(w_imp_dov_dic_fab_m,0) - nvl(w_imp_dov_acc_dic_fab_m,0);
             w_vers_saldo_fab_merce         := nvl(w_vers_fab_merce,0) - nvl(w_vers_acconto_fab_merce,0);
             -- Gestione Arrotondamenti
             -- (VD - 10/11/2016): per evitare problemi di differenza tra arrotondamenti
             --                    degli importi totali e degli importi acconto/saldo,
             --                    prima si arrotondano i totali e gli acconti,
             --                    i saldi vengono determinati per differenza
             -- (VD - 06/12/2016): annullata modifica precedente.
             -- (VD - 27/12/2021): riattivata modifica del 10/11/2016
             --
             if a_anno >= 2007 then
                w_imp_dovuta                     := round(w_imp_dovuta,0);
                --w_imp_dovuta_acconto             := round(w_imp_dovuta_acconto,0);
                w_imp_dovuta_dic                 := round(w_imp_dovuta_dic,0);
                --w_imp_dovuta_acconto_dic         := round(w_imp_dovuta_acconto_dic,0);
                w_imp_dovuta_ab                  := round(w_imp_dovuta_ab,0);
                w_imp_dovuta_acconto_ab          := round(w_imp_dovuta_acconto_ab,0);
                w_imp_dovuta_dic_ab              := round(w_imp_dovuta_dic_ab,0);
                w_imp_dovuta_acconto_dic_ab      := round(w_imp_dovuta_acconto_dic_ab,0);
                w_imp_dov_ter_comu               := round(w_imp_dov_ter_comu,0);
                w_imp_dov_acc_ter_comu           := round(w_imp_dov_acc_ter_comu,0);
                w_imp_dov_dic_ter_comu           := round(w_imp_dov_dic_ter_comu,0);
                w_imp_dov_acc_dic_ter_comu       := round(w_imp_dov_acc_dic_ter_comu,0);
                w_imp_dov_ter_erar               := round(w_imp_dov_ter_erar,0);
                w_imp_dov_acc_ter_erar           := round(w_imp_dov_acc_ter_erar,0);
                w_imp_dov_dic_ter_erar           := round(w_imp_dov_dic_ter_erar,0);
                w_imp_dov_acc_dic_ter_erar       := round(w_imp_dov_acc_dic_ter_erar,0);
                w_imp_dov_aree_comu              := round(w_imp_dov_aree_comu,0);
                w_imp_dov_acc_aree_comu          := round(w_imp_dov_acc_aree_comu,0);
                w_imp_dov_dic_aree_comu          := round(w_imp_dov_dic_aree_comu,0);
                w_imp_dov_acc_dic_aree_comu      := round(w_imp_dov_acc_dic_aree_comu,0);
                w_imp_dov_aree_erar              := round(w_imp_dov_aree_erar,0);
                w_imp_dov_acc_aree_erar          := round(w_imp_dov_acc_aree_erar,0);
                w_imp_dov_dic_aree_erar          := round(w_imp_dov_dic_aree_erar,0);
                w_imp_dov_acc_dic_aree_erar      := round(w_imp_dov_acc_dic_aree_erar,0);
                w_imp_dov_rur                    := round(w_imp_dov_rur,0);
                w_imp_dov_acc_rur                := round(w_imp_dov_acc_rur,0);
                w_imp_dov_dic_rur                := round(w_imp_dov_dic_rur,0);
                w_imp_dov_acc_dic_rur            := round(w_imp_dov_acc_dic_rur,0);
                w_imp_dov_fab_d_comu             := round(w_imp_dov_fab_d_comu,0);
                w_imp_dov_acc_fab_d_comu         := round(w_imp_dov_acc_fab_d_comu,0);
                w_imp_dov_dic_fab_d_comu         := round(w_imp_dov_dic_fab_d_comu,0);
                w_imp_dov_acc_dic_fab_d_comu     := round(w_imp_dov_acc_dic_fab_d_comu,0);
                w_imp_dov_fab_d_erar             := round(w_imp_dov_fab_d_erar,0);
                w_imp_dov_acc_fab_d_erar         := round(w_imp_dov_acc_fab_d_erar,0);
                w_imp_dov_dic_fab_d_erar         := round(w_imp_dov_dic_fab_d_erar,0);
                w_imp_dov_acc_dic_fab_d_erar     := round(w_imp_dov_acc_dic_fab_d_erar,0);
                w_imp_dov_altri_comu             := round(w_imp_dov_altri_comu,0);
                w_imp_dov_acc_altri_comu         := round(w_imp_dov_acc_altri_comu,0);
                w_imp_dov_dic_altri_comu         := round(w_imp_dov_dic_altri_comu,0);
                w_imp_dov_acc_dic_altri_comu     := round(w_imp_dov_acc_dic_altri_comu,0);
                w_imp_dov_altri_erar             := round(w_imp_dov_altri_erar,0);
                w_imp_dov_acc_altri_erar         := round(w_imp_dov_acc_altri_erar,0);
                w_imp_dov_dic_altri_erar         := round(w_imp_dov_dic_altri_erar,0);
                w_imp_dov_acc_dic_altri_erar     := round(w_imp_dov_acc_dic_altri_erar,0);
                -- Fabbricati merce
                w_imp_dov_fab_m                  := round(w_imp_dov_fab_m,0);
                w_imp_dov_acc_fab_m              := round(w_imp_dov_acc_fab_m,0);
                w_imp_dov_dic_fab_m              := round(w_imp_dov_dic_fab_m,0);
                w_imp_dov_acc_dic_fab_m          := round(w_imp_dov_acc_dic_fab_m,0);
                -- saldo  --
                --w_imp_dovuta_saldo               := round(w_imp_dovuta_saldo,0);
                --w_imp_dovuta_saldo_dic           := round(w_imp_dovuta_saldo_dic,0);
                -- (VD - 27/12/2021): saldi calcolati per differenza tra totale e acconto
                w_imp_dovuta_saldo_ab            := w_imp_dovuta_ab - w_imp_dovuta_acconto_ab;
                w_imp_dovuta_saldo_dic_ab        := w_imp_dovuta_dic_ab - w_imp_dovuta_acconto_dic_ab;
                w_imp_dov_saldo_ter_comu         := w_imp_dov_ter_comu - w_imp_dov_acc_ter_comu;
                w_imp_dov_saldo_dic_ter_comu     := w_imp_dov_dic_ter_comu - w_imp_dov_acc_dic_ter_comu;
                w_imp_dov_saldo_ter_erar         := w_imp_dov_ter_erar - w_imp_dov_acc_ter_erar;
                w_imp_dov_saldo_dic_ter_erar     := w_imp_dov_dic_ter_erar - w_imp_dov_acc_dic_ter_erar;
                w_imp_dov_saldo_aree_comu        := w_imp_dov_aree_comu - w_imp_dov_acc_aree_comu;
                w_imp_dov_saldo_dic_aree_comu    := w_imp_dov_dic_aree_comu - w_imp_dov_acc_dic_aree_comu;
                w_imp_dov_saldo_aree_erar        := w_imp_dov_aree_erar - w_imp_dov_acc_aree_erar;
                w_imp_dov_saldo_dic_aree_erar    := w_imp_dov_dic_aree_erar - w_imp_dov_acc_dic_aree_erar;
                w_imp_dov_saldo_rur              := w_imp_dov_rur - w_imp_dov_acc_rur;
                w_imp_dov_saldo_dic_rur          := w_imp_dov_dic_rur - w_imp_dov_acc_dic_rur;
                w_imp_dov_saldo_fab_d_comu       := w_imp_dov_fab_d_comu - w_imp_dov_acc_fab_d_comu;
                w_imp_dov_saldo_dic_fab_d_comu   := w_imp_dov_dic_fab_d_comu - w_imp_dov_acc_dic_fab_d_comu;
                w_imp_dov_saldo_fab_d_erar       := w_imp_dov_fab_d_erar - w_imp_dov_acc_fab_d_erar;
                w_imp_dov_saldo_dic_fab_d_erar   := w_imp_dov_dic_fab_d_erar - w_imp_dov_acc_dic_fab_d_erar;
                w_imp_dov_saldo_altri_comu       := w_imp_dov_altri_comu - w_imp_dov_acc_altri_comu;
                w_imp_dov_saldo_dic_altri_comu   := w_imp_dov_dic_altri_comu - w_imp_dov_acc_dic_altri_comu;
                w_imp_dov_saldo_altri_erar       := w_imp_dov_altri_erar - w_imp_dov_acc_altri_erar;
                w_imp_dov_saldo_dic_altri_erar   := w_imp_dov_dic_altri_erar - w_imp_dov_acc_dic_altri_erar;
                -- Fabbricati merce
                w_imp_dov_saldo_fab_m            := w_imp_dov_fab_m - w_imp_dov_acc_fab_m;
                w_imp_dov_saldo_dic_fab_m        := w_imp_dov_dic_fab_m - w_imp_dov_acc_dic_fab_m;
                -- Mini IMU
                w_imp_dovuta_mini                := round(w_imp_dovuta_mini,0);
                w_imp_dovuta_mini_dic            := round(w_imp_dovuta_mini_dic,0);
                w_imp_dovuta_mini_ab             := round(w_imp_dovuta_mini_ab,0);
                w_imp_dovuta_mini_dic_ab         := round(w_imp_dovuta_mini_dic_ab,0);
                w_imp_dovuta_mini_ter            := round(w_imp_dovuta_mini_ter,0);
                w_imp_dovuta_mini_dic_ter        := round(w_imp_dovuta_mini_dic_ter,0);
             end if;
             -- Gestione degli importi come somma dei parziali --
             -- (VD - 29/11/2016): per calcolare le sanzioni corrette,
             --                    gli importi totali si lasciano invariati
             -- (VD - 06/12/2016): si ricalcolano gli importi totali come
             --                    somma dei parziali arrotondati
             -- (VD - 23/09/2020): Aggiunti fabbricati merce
             if a_anno >= 2012 then
                w_imp_dovuta_acconto  := nvl(w_imp_dovuta_acconto_ab,0)
                                       + nvl(w_imp_dov_acc_ter_comu,0)
                                       + nvl(w_imp_dov_acc_ter_erar,0)
                                       + nvl(w_imp_dov_acc_aree_comu,0)
                                       + nvl(w_imp_dov_acc_aree_erar,0)
                                       + nvl(w_imp_dov_acc_rur,0)
                                       + nvl(w_imp_dov_acc_fab_d_comu,0)
                                       + nvl(w_imp_dov_acc_fab_d_erar,0)
                                       + nvl(w_imp_dov_acc_altri_comu,0)
                                       + nvl(w_imp_dov_acc_altri_erar,0)
                                       + nvl(w_imp_dov_acc_fab_m,0)
                                       ;
                -- w_imp_dovuta_saldo          := w_imp_dovuta - w_imp_dovuta_acconto;
                w_imp_dovuta_saldo    := nvl(w_imp_dovuta_saldo_ab,0)
                                       + nvl(w_imp_dov_saldo_ter_comu,0)
                                       + nvl(w_imp_dov_saldo_ter_erar,0)
                                       + nvl(w_imp_dov_saldo_aree_comu,0)
                                       + nvl(w_imp_dov_saldo_aree_erar,0)
                                       + nvl(w_imp_dov_saldo_rur,0)
                                       + nvl(w_imp_dov_saldo_fab_d_comu,0)
                                       + nvl(w_imp_dov_saldo_fab_d_erar,0)
                                       + nvl(w_imp_dov_saldo_altri_comu,0)
                                       + nvl(w_imp_dov_saldo_altri_erar,0)
                                       + nvl(w_imp_dov_saldo_fab_m,0)
                                       ;
                --
                -- (VD - 06/12/2016); aggiunto ricalcolo totali imposta
                --                    dichiarata
                -- (VD - 23/09/2020): Aggiunti fabbricati merce
                --
                w_imp_dovuta_acconto_dic := nvl(w_imp_dovuta_acconto_dic_ab,0)
                                          + nvl(w_imp_dov_acc_dic_ter_comu,0)
                                          + nvl(w_imp_dov_acc_dic_ter_erar,0)
                                          + nvl(w_imp_dov_acc_dic_aree_comu,0)
                                          + nvl(w_imp_dov_acc_dic_aree_erar,0)
                                          + nvl(w_imp_dov_acc_dic_rur,0)
                                          + nvl(w_imp_dov_acc_dic_fab_d_comu,0)
                                          + nvl(w_imp_dov_acc_dic_fab_d_erar,0)
                                          + nvl(w_imp_dov_acc_dic_altri_comu,0)
                                          + nvl(w_imp_dov_acc_dic_altri_erar,0)
                                          + nvl(w_imp_dov_acc_dic_fab_m,0)
                                       ;
                w_imp_dovuta_saldo_dic := nvl(w_imp_dovuta_saldo_dic_ab,0)
                                        + nvl(w_imp_dov_saldo_dic_ter_comu,0)
                                        + nvl(w_imp_dov_saldo_dic_ter_erar,0)
                                        + nvl(w_imp_dov_saldo_dic_aree_comu,0)
                                        + nvl(w_imp_dov_saldo_dic_aree_erar,0)
                                        + nvl(w_imp_dov_saldo_dic_rur,0)
                                        + nvl(w_imp_dov_saldo_dic_fab_d_comu,0)
                                        + nvl(w_imp_dov_saldo_dic_fab_d_erar,0)
                                        + nvl(w_imp_dov_saldo_dic_altri_comu,0)
                                        + nvl(w_imp_dov_saldo_dic_altri_erar,0)
                                        + nvl(w_imp_dov_saldo_dic_fab_m,0)
                                        ;
                if w_commenti = 1 then
                   dbms_output.put_line('CALCOLO_LIQUIDAZIONI_IMU w_imp_dovuta_saldo '|| w_imp_dovuta_saldo);
                   dbms_output.put_line('CALCOLO_LIQUIDAZIONI_IMU w_imp_dovuta_acconto '|| w_imp_dovuta_acconto);
                   dbms_output.put_line('CALCOLO_LIQUIDAZIONI_IMU w_imp_dovuta_mini '|| w_imp_dovuta_mini);
                end if;
                if w_num_versamenti > 0 or
                   w_num_versamenti_unici >= 1 then
                   --
                   -- (VD - 03/05/2018): Aggiunta mini IMU
                   --
                   w_imp_dovuta                     := w_imp_dovuta_acconto + w_imp_dovuta_saldo + w_imp_dovuta_mini;
                   w_imp_dovuta_dic                 := w_imp_dovuta_acconto_dic + w_imp_dovuta_saldo_dic + w_imp_dovuta_mini_dic;
                   --w_imp_dovuta_ab                  := w_imp_dovuta_acconto_ab + w_imp_dovuta_saldo_ab + w_imp_dovuta_mini_ab;
                   --w_imp_dovuta_dic_ab              := w_imp_dovuta_acconto_dic_ab + w_imp_dovuta_saldo_dic_ab + w_imp_dovuta_mini_dic_ab;
                   --w_imp_dov_ter_comu               := w_imp_dov_acc_ter_comu + w_imp_dov_saldo_ter_comu + w_imp_dovuta_mini_ter;
                   --w_imp_dov_dic_ter_comu           := w_imp_dov_acc_dic_ter_comu + w_imp_dov_saldo_dic_ter_comu + w_imp_dovuta_mini_dic_ter;
                   --w_imp_dov_ter_erar               := w_imp_dov_acc_ter_erar + w_imp_dov_saldo_ter_erar;
                   --w_imp_dov_dic_ter_erar           := w_imp_dov_acc_dic_ter_erar + w_imp_dov_saldo_dic_ter_erar;
                   --w_imp_dov_aree_comu              := w_imp_dov_acc_aree_comu + w_imp_dov_saldo_aree_comu;
                   --w_imp_dov_dic_aree_comu          := w_imp_dov_acc_dic_aree_comu + w_imp_dov_saldo_dic_aree_comu;
                   --w_imp_dov_aree_erar              := w_imp_dov_acc_aree_erar + w_imp_dov_saldo_aree_erar;
                   --w_imp_dov_dic_aree_erar          := w_imp_dov_acc_dic_aree_erar + w_imp_dov_saldo_dic_aree_erar;
                   --w_imp_dov_rur                    := w_imp_dov_acc_rur + w_imp_dov_saldo_rur;
                   --w_imp_dov_dic_rur                := w_imp_dov_acc_dic_rur + w_imp_dov_saldo_dic_rur;
                   --w_imp_dov_fab_d_comu             := w_imp_dov_acc_fab_d_comu + w_imp_dov_saldo_fab_d_comu;
                   --w_imp_dov_dic_fab_d_comu         := w_imp_dov_acc_dic_fab_d_comu + w_imp_dov_saldo_dic_fab_d_comu;
                   --w_imp_dov_fab_d_erar             := w_imp_dov_acc_fab_d_erar + w_imp_dov_saldo_fab_d_erar;
                   --w_imp_dov_dic_fab_d_erar         := w_imp_dov_acc_dic_fab_d_erar + w_imp_dov_saldo_dic_fab_d_erar;
                   --w_imp_dov_altri_comu             := w_imp_dov_acc_altri_comu + w_imp_dov_saldo_altri_comu;
                   --w_imp_dov_dic_altri_comu         := w_imp_dov_acc_dic_altri_comu + w_imp_dov_saldo_dic_altri_comu;
                   --w_imp_dov_altri_erar             := w_imp_dov_acc_altri_erar + w_imp_dov_saldo_altri_erar;
                   --w_imp_dov_dic_altri_erar         := w_imp_dov_acc_dic_altri_erar + w_imp_dov_saldo_dic_altri_erar;
                   -- Fabbricati merce
                   --w_imp_dov_fab_m                  := w_imp_dov_acc_fab_m + w_imp_dov_saldo_fab_m;
                   --w_imp_dov_dic_fab_m              := w_imp_dov_acc_dic_fab_m + w_imp_dov_saldo_dic_fab_m;
                else
                   --
                   -- (VD - 03/05/2018): Aggiunta mini IMU
                   -- (VD - 23/09/2020): Aggiunti fabbricati merce
                   --
                   w_imp_dovuta          := nvl(w_imp_dovuta_ab,0)
                                          + nvl(w_imp_dov_ter_comu,0)
                                          + nvl(w_imp_dov_ter_erar,0)
                                          + nvl(w_imp_dov_aree_comu,0)
                                          + nvl(w_imp_dov_aree_erar,0)
                                          + nvl(w_imp_dov_rur,0)
                                          + nvl(w_imp_dov_fab_d_comu,0)
                                          + nvl(w_imp_dov_fab_d_erar,0)
                                          + nvl(w_imp_dov_altri_comu,0)
                                          + nvl(w_imp_dov_altri_erar,0)
                                          + nvl(w_imp_dov_fab_m,0)
                                          + nvl(w_imp_dovuta_mini,0)
                                          ;
                   w_imp_dovuta_dic      := nvl(w_imp_dovuta_dic_ab,0)
                                          + nvl(w_imp_dov_dic_ter_comu,0)
                                          + nvl(w_imp_dov_dic_ter_erar,0)
                                          + nvl(w_imp_dov_dic_aree_comu,0)
                                          + nvl(w_imp_dov_dic_aree_erar,0)
                                          + nvl(w_imp_dov_dic_rur,0)
                                          + nvl(w_imp_dov_dic_fab_d_comu,0)
                                          + nvl(w_imp_dov_dic_fab_d_erar,0)
                                          + nvl(w_imp_dov_dic_altri_comu,0)
                                          + nvl(w_imp_dov_dic_altri_erar,0)
                                          + nvl(w_imp_dov_dic_fab_m,0)
                                          + nvl(w_imp_dovuta_mini_dic,0)
                                          ;
                   --DBMS_OUTPUT.PUT_LINE('1 - w_imp_dovuta '||w_imp_dovuta);
                   --DBMS_OUTPUT.PUT_LINE('1 - w_imp_dovuta_acconto '||w_imp_dovuta_acconto);
                   --DBMS_OUTPUT.PUT_LINE('1 - w_imp_dovuta_saldo '||w_imp_dovuta_saldo);
                   --DBMS_OUTPUT.PUT_LINE('1 - w_imp_dovuta_mini '||w_imp_dovuta_mini);
                   --DBMS_OUTPUT.PUT_LINE('1 - w_imp_dovuta_dic '||w_imp_dovuta_dic);
                end if;
             else
                w_imp_dovuta          := w_imp_dovuta_acconto + w_imp_dovuta_saldo;
                w_imp_dovuta_dic      := w_imp_dovuta_acconto_dic + w_imp_dovuta_saldo_dic;
             end if;
             --DBMS_OUTPUT.PUT_LINE('w_imp_dovuta '||w_imp_dovuta);
             --DBMS_OUTPUT.PUT_LINE('w_versamenti '||w_versamenti);
             --DBMS_OUTPUT.PUT_LINE('w_imp_dovuta_acconto '||w_imp_dovuta_acconto);
             --DBMS_OUTPUT.PUT_LINE('w_versamenti_acconto '||w_versamenti_acconto);
             --DBMS_OUTPUT.PUT_LINE('w_imp_dovuta_saldo '||w_imp_dovuta_saldo);
             --DBMS_OUTPUT.PUT_LINE('w_versamenti_saldo '||w_versamenti_saldo);
             --DBMS_OUTPUT.PUT_LINE('w_imp_dovuta_mini '||w_imp_dovuta_mini);
             --DBMS_OUTPUT.PUT_LINE('w_versamenti_mini '||w_versamenti_mini);
             --DBMS_OUTPUT.PUT_LINE('w_imp_dovuta_dic '||w_imp_dovuta_dic);
          IF w_versamenti_acconto >= w_imp_dovuta_acconto THEN
             IF w_versamenti_saldo >= w_imp_dovuta_saldo THEN
                w_imp_evasa_acconto        := w_imp_dovuta_acconto - w_versamenti_acconto;
                w_imp_evasa_saldo          := w_imp_dovuta_saldo - w_versamenti_saldo;
                w_imp_evasa_acconto_ab     := w_imp_dovuta_acconto_ab - w_versamenti_acconto_ab;
                w_imp_evasa_saldo_ab       := w_imp_dovuta_saldo_ab - w_versamenti_saldo_ab;
                w_imp_evasa_acconto_ter    := w_imp_dovuta_acconto_ter - w_versamenti_acconto_ter;
                w_imp_evasa_saldo_ter      := w_imp_dovuta_saldo_ter - w_versamenti_saldo_ter;
                w_imp_eva_acc_ter_comu     := nvl(w_imp_dov_acc_ter_comu,0) - w_vers_acconto_ter_comu;
                w_imp_eva_saldo_ter_comu   := w_imp_dov_saldo_ter_comu- w_vers_saldo_ter_comu;
                w_imp_eva_acc_ter_erar     := nvl(w_imp_dov_acc_ter_erar,0) - w_vers_acconto_ter_erar;
                w_imp_eva_saldo_ter_erar   := w_imp_dov_saldo_ter_erar- w_vers_saldo_ter_erar;
                w_imp_evasa_acconto_aree   := w_imp_dovuta_acconto_aree - w_versamenti_acconto_aree;
                w_imp_evasa_saldo_aree     := w_imp_dovuta_saldo_aree - w_versamenti_saldo_aree;
                w_imp_eva_acc_aree_comu    := nvl(w_imp_dov_acc_aree_comu,0) - w_vers_acconto_aree_comu;
                w_imp_eva_saldo_aree_comu  := w_imp_dov_saldo_aree_comu - w_vers_saldo_aree_comu;
                w_imp_eva_acc_aree_erar    := nvl(w_imp_dov_acc_aree_erar,0) - w_vers_acconto_aree_erar;
                w_imp_eva_saldo_aree_erar  := w_imp_dov_saldo_aree_erar- w_vers_saldo_aree_erar;
                w_imp_eva_acc_rur          := nvl(w_imp_dov_acc_rur,0) - w_vers_acconto_rurali;
                w_imp_eva_saldo_rur        := w_imp_dov_saldo_rur - w_vers_saldo_rurali;
                w_imp_eva_acc_fab_d_comu   := nvl(w_imp_dov_acc_fab_d_comu,0) - w_vers_acconto_fab_d_comu;
                w_imp_eva_saldo_fab_d_comu := w_imp_dov_saldo_fab_d_comu- w_vers_saldo_fab_d_comu;
                w_imp_eva_acc_fab_d_erar   := nvl(w_imp_dov_acc_fab_d_erar,0) - w_vers_acconto_fab_d_erar;
                w_imp_eva_saldo_fab_d_erar := w_imp_dov_saldo_fab_d_erar- w_vers_saldo_fab_d_erar;
                w_imp_evasa_acconto_altri  := w_imp_dovuta_acconto_altri - w_versamenti_acconto_altri;
                w_imp_evasa_saldo_altri    := w_imp_dovuta_saldo_altri - w_versamenti_saldo_altri;
                w_imp_eva_acc_altri_comu   := nvl(w_imp_dov_acc_altri_comu,0) - w_vers_acconto_altri_comu;
                w_imp_eva_saldo_altri_comu := w_imp_dov_saldo_altri_comu- w_vers_saldo_altri_comu;
                w_imp_eva_acc_altri_erar   := nvl(w_imp_dov_acc_altri_erar,0) - w_vers_acconto_altri_erar;
                w_imp_eva_saldo_altri_erar := w_imp_dov_saldo_altri_erar- w_vers_saldo_altri_erar;
                -- Fabbricati merce
                w_imp_eva_acc_fab_m        := nvl(w_imp_dov_acc_fab_m,0) - w_vers_acconto_fab_merce;
                w_imp_eva_saldo_fab_m      := w_imp_dov_saldo_fab_m - w_vers_saldo_fab_merce;
             ELSIF w_versamenti >= w_imp_dovuta THEN
                w_imp_evasa_acconto        := (w_imp_dovuta - w_imp_dovuta_mini) - (w_versamenti - w_versamenti_mini);
                w_imp_evasa_saldo          := 0;
                w_imp_evasa_acconto_ab     := (w_imp_dovuta_ab - w_imp_dovuta_mini_ab) - (w_versamenti_ab - w_versamenti_mini_ab);
                w_imp_evasa_saldo_ab       := 0;
                w_imp_evasa_acconto_ter    := (w_imp_dovuta_ter - w_imp_dovuta_mini_ter) - (w_versamenti_ter - w_versamenti_mini_ter);
                w_imp_evasa_saldo_ter      := 0;
                w_imp_eva_acc_ter_comu     := (w_imp_dov_ter_comu - w_imp_dovuta_mini_ter) - (w_vers_ter_comu - w_versamenti_mini_ter);
                w_imp_eva_saldo_ter_comu   := 0;
                w_imp_eva_acc_ter_erar     := w_imp_dov_ter_erar - w_vers_ter_erar;
                w_imp_eva_saldo_ter_erar   := 0;
                w_imp_evasa_acconto_aree   := w_imp_dovuta_aree - w_versamenti_aree;
                w_imp_evasa_saldo_aree     := 0;
                w_imp_eva_acc_aree_comu    := w_imp_dov_aree_comu - w_vers_aree_comu;
                w_imp_eva_saldo_aree_comu  := 0;
                w_imp_eva_acc_aree_erar    := w_imp_dov_aree_erar - w_vers_aree_erar;
                w_imp_eva_saldo_aree_erar  := 0;
                w_imp_eva_acc_rur          := w_imp_dov_rur - w_vers_rurali;
                w_imp_eva_saldo_rur        := 0;
                w_imp_eva_acc_fab_d_comu   := w_imp_dov_fab_d_comu - w_vers_fab_d_comu;
                w_imp_eva_saldo_fab_d_comu := 0;
                w_imp_eva_acc_fab_d_erar   := w_imp_dov_fab_d_erar - w_vers_fab_d_erar;
                w_imp_eva_saldo_fab_d_erar := 0;
                w_imp_evasa_acconto_altri  := w_imp_dovuta_altri - w_versamenti_altri;
                w_imp_evasa_saldo_altri    := 0;
                w_imp_eva_acc_altri_comu   := w_imp_dov_altri_comu - w_vers_altri_comu;
                w_imp_eva_saldo_altri_comu := 0;
                w_imp_eva_acc_altri_erar   := w_imp_dov_altri_erar - w_vers_altri_erar;
                w_imp_eva_saldo_altri_erar := 0;
                -- Fabbricati merce
                w_imp_eva_acc_fab_m        := w_imp_dov_fab_m - w_vers_fab_merce;
                w_imp_eva_saldo_fab_m      := 0;
             ELSE
                w_imp_evasa_acconto       := 0;
                w_imp_evasa_saldo         := (w_imp_dovuta - w_imp_dovuta_mini) - (w_versamenti - w_versamenti_mini);
                w_imp_evasa_acconto_ab    := 0;
                w_imp_evasa_saldo_ab      := (w_imp_dovuta_ab - w_imp_dovuta_mini_ab) - (w_versamenti_ab - w_versamenti_mini_ab);
                w_imp_evasa_acconto_ter   := 0;
                w_imp_evasa_saldo_ter     := (w_imp_dovuta_ter - w_imp_dovuta_mini_ter) - (w_versamenti_ter - w_versamenti_mini_ter);
                w_imp_eva_acc_ter_comu    := 0;
                w_imp_eva_saldo_ter_comu  := (w_imp_dov_ter_comu - w_imp_dovuta_mini_ter) - (w_vers_ter_comu - w_versamenti_mini_ter);
                w_imp_eva_acc_ter_erar    := 0;
                w_imp_eva_saldo_ter_erar  := w_imp_dov_ter_erar - w_vers_ter_erar;
                w_imp_evasa_acconto_aree   := 0;
                w_imp_evasa_saldo_aree     := w_imp_dovuta_aree - w_versamenti_aree;
                w_imp_eva_acc_aree_comu    := 0;
                w_imp_eva_saldo_aree_comu  := w_imp_dov_aree_comu - w_vers_aree_comu;
                w_imp_eva_acc_aree_erar    := 0;
                w_imp_eva_saldo_aree_erar  := w_imp_dov_aree_erar - w_vers_aree_erar;
                w_imp_eva_acc_rur          := 0;
                w_imp_eva_saldo_rur        := w_imp_dov_rur - w_vers_rurali;
                w_imp_eva_acc_fab_d_comu   := 0;
                w_imp_eva_saldo_fab_d_comu := w_imp_dov_fab_d_comu - w_vers_fab_d_comu;
                w_imp_eva_acc_fab_d_erar   := 0;
                w_imp_eva_saldo_fab_d_erar := w_imp_dov_fab_d_erar - w_vers_fab_d_erar;
                w_imp_evasa_acconto_altri  := 0;
                w_imp_evasa_saldo_altri    := w_imp_dovuta_altri - w_versamenti_altri;
                w_imp_eva_acc_altri_comu   := 0;
                w_imp_eva_saldo_altri_comu := w_imp_dov_altri_comu - w_vers_altri_comu;
                w_imp_eva_acc_altri_erar   := 0;
                w_imp_eva_saldo_altri_erar := w_imp_dov_altri_erar - w_vers_altri_erar;
                -- Fabbricati merce
                w_imp_eva_acc_fab_m        := 0;
                w_imp_eva_saldo_fab_m      := w_imp_dov_fab_m - w_vers_fab_merce;
             END IF;
          ELSE
             IF w_versamenti_saldo < w_imp_dovuta_saldo THEN
                w_imp_evasa_acconto        := w_imp_dovuta_acconto - w_versamenti_acconto;
                w_imp_evasa_saldo          := w_imp_dovuta_saldo - w_versamenti_saldo;
                w_imp_evasa_acconto_ab     := w_imp_dovuta_acconto_ab - w_versamenti_acconto_ab;
                w_imp_evasa_saldo_ab       := w_imp_dovuta_saldo_ab - w_versamenti_saldo_ab;
                w_imp_evasa_acconto_ter    := w_imp_dovuta_acconto_ter - w_versamenti_acconto_ter;
                w_imp_evasa_saldo_ter      := w_imp_dovuta_saldo_ter - w_versamenti_saldo_ter;
                w_imp_eva_acc_ter_comu     := w_imp_dov_acc_ter_comu - w_vers_acconto_ter_comu;
                w_imp_eva_saldo_ter_comu   := w_imp_dov_saldo_ter_comu- w_vers_saldo_ter_comu;
                w_imp_eva_acc_ter_erar     := w_imp_dov_acc_ter_erar - w_vers_acconto_ter_erar;
                w_imp_eva_saldo_ter_erar   := w_imp_dov_saldo_ter_erar- w_vers_saldo_ter_erar;
                w_imp_evasa_acconto_aree   := w_imp_dovuta_acconto_aree - w_versamenti_acconto_aree;
                w_imp_evasa_saldo_aree     := w_imp_dovuta_saldo_aree - w_versamenti_saldo_aree;
                w_imp_eva_acc_aree_comu    := w_imp_dov_acc_aree_comu - w_vers_acconto_aree_comu;
                w_imp_eva_saldo_aree_comu  := w_imp_dov_saldo_aree_comu - w_vers_saldo_aree_comu;
                w_imp_eva_acc_aree_erar    := w_imp_dov_acc_aree_erar - w_vers_acconto_aree_erar;
                w_imp_eva_saldo_aree_erar  := w_imp_dov_saldo_aree_erar- w_vers_saldo_aree_erar;
                w_imp_eva_acc_rur          := w_imp_dov_acc_rur - w_vers_acconto_rurali;
                w_imp_eva_saldo_rur        := w_imp_dov_saldo_rur - w_vers_saldo_rurali;
                w_imp_eva_acc_fab_d_comu   := w_imp_dov_acc_fab_d_comu - w_vers_acconto_fab_d_comu;
                w_imp_eva_saldo_fab_d_comu := w_imp_dov_saldo_fab_d_comu- w_vers_saldo_fab_d_comu;
                w_imp_eva_acc_fab_d_erar   := w_imp_dov_acc_fab_d_erar - w_vers_acconto_fab_d_erar;
                w_imp_eva_saldo_fab_d_erar := w_imp_dov_saldo_fab_d_erar- w_vers_saldo_fab_d_erar;
                w_imp_evasa_acconto_altri  := w_imp_dovuta_acconto_altri - w_versamenti_acconto_altri;
                w_imp_evasa_saldo_altri    := w_imp_dovuta_saldo_altri - w_versamenti_saldo_altri;
                w_imp_eva_acc_altri_comu   := w_imp_dov_acc_altri_comu - w_vers_acconto_altri_comu;
                w_imp_eva_saldo_altri_comu := w_imp_dov_saldo_altri_comu- w_vers_saldo_altri_comu;
                w_imp_eva_acc_altri_erar   := w_imp_dov_acc_altri_erar - w_vers_acconto_altri_erar;
                w_imp_eva_saldo_altri_erar := w_imp_dov_saldo_altri_erar- w_vers_saldo_altri_erar;
                -- Fabbricati merce
                w_imp_eva_acc_fab_m        := w_imp_dov_acc_fab_m - w_vers_acconto_fab_merce;
                w_imp_eva_saldo_fab_m      := w_imp_dov_saldo_fab_m - w_vers_saldo_fab_merce;
             ELSIF w_versamenti >= w_imp_dovuta THEN
                w_imp_evasa_acconto       := 0;
                w_imp_evasa_saldo         := (w_imp_dovuta - w_imp_dovuta_mini) - (w_versamenti - w_versamenti_mini); --w_imp_dovuta - w_versamenti;
                w_imp_evasa_acconto_ab    := 0;
                w_imp_evasa_saldo_ab      := (w_imp_dovuta_ab - w_imp_dovuta_mini_ab) - (w_versamenti_ab - w_versamenti_mini_ab); --w_imp_dovuta_ab - w_versamenti_ab;
                w_imp_evasa_acconto_ter   := 0;
                w_imp_evasa_saldo_ter     := (w_imp_dovuta_ter - w_imp_dovuta_mini_ter) - (w_versamenti_ter - w_versamenti_mini_ter); --w_imp_dovuta_ter - w_versamenti_ter;
                w_imp_eva_acc_ter_comu    := 0;
                w_imp_eva_saldo_ter_comu  := (w_imp_dov_ter_comu - w_imp_dovuta_mini_ter) - (w_vers_ter_comu - w_versamenti_mini_ter); --w_imp_dov_ter_comu - w_vers_ter_comu;
                w_imp_eva_acc_ter_erar    := 0;
                w_imp_eva_saldo_ter_erar  := w_imp_dov_ter_erar - w_vers_ter_erar;
                w_imp_evasa_acconto_aree   := 0;
                w_imp_evasa_saldo_aree     := w_imp_dovuta_aree - w_versamenti_aree;
                w_imp_eva_acc_aree_comu    := 0;
                w_imp_eva_saldo_aree_comu  := w_imp_dov_aree_comu - w_vers_aree_comu;
                w_imp_eva_acc_aree_erar    := 0;
                w_imp_eva_saldo_aree_erar  := w_imp_dov_aree_erar - w_vers_aree_erar;
                w_imp_eva_acc_rur          := 0;
                w_imp_eva_saldo_rur        := w_imp_dov_rur - w_vers_rurali;
                w_imp_eva_acc_fab_d_comu   := 0;
                w_imp_eva_saldo_fab_d_comu := w_imp_dov_fab_d_comu - w_vers_fab_d_comu;
                w_imp_eva_acc_fab_d_erar   := 0;
                w_imp_eva_saldo_fab_d_erar := w_imp_dov_fab_d_erar - w_vers_fab_d_erar;
                w_imp_evasa_acconto_altri  := 0;
                w_imp_evasa_saldo_altri    := w_imp_dovuta_altri - w_versamenti_altri;
                w_imp_eva_acc_altri_comu   := 0;
                w_imp_eva_saldo_altri_comu := w_imp_dov_altri_comu - w_vers_altri_comu;
                w_imp_eva_acc_altri_erar   := 0;
                w_imp_eva_saldo_altri_erar := w_imp_dov_altri_erar - w_vers_altri_erar;
                -- Fabbricati merce
                w_imp_eva_acc_fab_m        := 0;
                w_imp_eva_saldo_fab_m      := w_imp_dov_fab_m - w_vers_fab_merce;
             ELSE
                w_imp_evasa_acconto        := (w_imp_dovuta - w_imp_dovuta_mini) - (w_versamenti - w_versamenti_mini);
                w_imp_evasa_saldo          := 0;
                w_imp_evasa_acconto_ab     := (w_imp_dovuta_ab - w_imp_dovuta_mini_ab) - (w_versamenti_ab - w_versamenti_mini_ab);
                w_imp_evasa_saldo_ab       := 0;
                w_imp_evasa_acconto_ter    := (w_imp_dovuta_ter - w_imp_dovuta_mini_ter) - (w_versamenti_ter - w_versamenti_mini_ter);
                w_imp_evasa_saldo_ter      := 0;
                w_imp_eva_acc_ter_comu     := (w_imp_dov_ter_comu - w_imp_dovuta_mini_ter) - (w_vers_ter_comu - w_versamenti_mini_ter);
                w_imp_eva_saldo_ter_comu   := 0;
                w_imp_eva_acc_ter_erar     := w_imp_dov_ter_erar - w_vers_ter_erar;
                w_imp_eva_saldo_ter_erar   := 0;
                w_imp_evasa_acconto_aree   := w_imp_dovuta_aree - w_versamenti_aree;
                w_imp_evasa_saldo_aree     := 0;
                w_imp_eva_acc_aree_comu    := w_imp_dov_aree_comu - w_vers_aree_comu;
                w_imp_eva_saldo_aree_comu  := 0;
                w_imp_eva_acc_aree_erar    := w_imp_dov_aree_erar - w_vers_aree_erar;
                w_imp_eva_saldo_aree_erar  := 0;
                w_imp_eva_acc_rur          := w_imp_dov_rur - w_vers_rurali;
                w_imp_eva_saldo_rur        := 0;
                w_imp_eva_acc_fab_d_comu   := w_imp_dov_fab_d_comu - w_vers_fab_d_comu;
                w_imp_eva_saldo_fab_d_comu := 0;
                w_imp_eva_acc_fab_d_erar   := w_imp_dov_fab_d_erar - w_vers_fab_d_erar;
                w_imp_eva_saldo_fab_d_erar := 0;
                w_imp_evasa_acconto_altri  := w_imp_dovuta_altri - w_versamenti_altri;
                w_imp_evasa_saldo_altri    := 0;
                w_imp_eva_acc_altri_comu   := w_imp_dov_altri_comu - w_vers_altri_comu;
                w_imp_eva_saldo_altri_comu := 0;
                w_imp_eva_acc_altri_erar   := w_imp_dov_altri_erar - w_vers_altri_erar;
                w_imp_eva_saldo_altri_erar := 0;
                -- Fabbricati merce
                w_imp_eva_acc_fab_m        := w_imp_dov_fab_m - w_vers_fab_merce;
                w_imp_eva_saldo_fab_m      := 0;
             END IF;
          END IF;
          -- Mini IMU
          if w_versamenti_mini >= w_imp_dovuta_mini then
             w_imp_evasa_mini := 0;
          else
             w_imp_evasa_mini := w_imp_dovuta_mini - w_versamenti_mini;
          end if;
          if w_versamenti_mini_ab >= w_imp_dovuta_mini_ab then
             w_imp_evasa_mini_ab := 0;
          else
             w_imp_evasa_mini_ab := w_imp_dovuta_mini_ab - w_versamenti_mini_ab;
          end if;
          if w_versamenti_mini_ter >= w_imp_dovuta_mini_ter then
             w_imp_evasa_mini_ter := 0;
          else
             w_imp_evasa_mini_ter := w_imp_dovuta_mini_ter - w_versamenti_mini_ter;
          end if;
          --
          if w_imp_evasa_acconto < 0 then
             if abs(w_imp_evasa_acconto) <= w_imp_evasa_mini then
                w_imp_evasa_mini    := w_imp_evasa_mini + w_imp_evasa_acconto;
                w_imp_evasa_acconto := 0;
             else
                w_imp_evasa_acconto := w_imp_evasa_acconto + w_imp_evasa_mini;
                w_imp_evasa_mini    := 0;
             end if;
          end if;
          --
          if w_imp_evasa_acconto_ab < 0 then
             if abs(w_imp_evasa_acconto_ab) <= w_imp_evasa_mini_ab then
                w_imp_evasa_mini_ab    := w_imp_evasa_mini_ab + w_imp_evasa_acconto_ab;
                w_imp_evasa_acconto_ab := 0;
             else
                w_imp_evasa_acconto_ab := w_imp_evasa_acconto_ab + w_imp_evasa_mini_ab;
                w_imp_evasa_mini_ab    := 0;
             end if;
          end if;
          --
          if w_imp_evasa_acconto_ter < 0 then
             if abs(w_imp_evasa_acconto_ter) <= w_imp_evasa_mini_ter then
                w_imp_evasa_mini_ter    := w_imp_evasa_mini_ter + w_imp_evasa_acconto_ter;
                w_imp_evasa_acconto_ter := 0;
             else
                w_imp_evasa_acconto_ter := w_imp_evasa_acconto_ter + w_imp_evasa_mini_ter;
                w_imp_evasa_mini_ter    := 0;
             end if;
          end if;
          --
          if w_imp_evasa_saldo < 0 then
             if abs(w_imp_evasa_saldo) <= w_imp_evasa_mini then
                w_imp_evasa_mini  := w_imp_evasa_mini + w_imp_evasa_saldo;
                w_imp_evasa_saldo := 0;
             else
                w_imp_evasa_saldo := w_imp_evasa_saldo + w_imp_evasa_mini;
                w_imp_evasa_mini  := 0;
             end if;
          end if;
          --
          if w_imp_evasa_saldo_ab < 0 then
             if abs(w_imp_evasa_saldo_ab) <= w_imp_evasa_mini_ab then
                w_imp_evasa_mini_ab  := w_imp_evasa_mini_ab + w_imp_evasa_saldo_ab;
                w_imp_evasa_saldo_ab := 0;
             else
                w_imp_evasa_saldo_ab := w_imp_evasa_saldo_ab + w_imp_evasa_mini_ab;
                w_imp_evasa_mini_ab  := 0;
             end if;
          end if;
          --
          if w_imp_evasa_saldo_ter < 0 then
             if abs(w_imp_evasa_saldo_ter) <= w_imp_evasa_mini_ter then
                w_imp_evasa_mini_ter  := w_imp_evasa_mini_ter + w_imp_evasa_saldo_ter;
                w_imp_evasa_saldo_ter := 0;
             else
                w_imp_evasa_saldo_ter := w_imp_evasa_saldo_ter + w_imp_evasa_mini_ter;
                w_imp_evasa_mini_ter  := 0;
             end if;
          end if;
          --
          --DBMS_OUTPUT.PUT_LINE('w_imp_evasa_acconto '||w_imp_evasa_acconto);
          --DBMS_OUTPUT.PUT_LINE('w_imp_evasa_saldo '||w_imp_evasa_saldo);
          --DBMS_OUTPUT.PUT_LINE('w_imp_evasa_mini '||w_imp_evasa_mini);
          --DBMS_OUTPUT.PUT_LINE('w_imp_evasa_acconto_AB '||w_imp_evasa_acconto_ab);
          --DBMS_OUTPUT.PUT_LINE('w_imp_evasa_saldo_AB '||w_imp_evasa_saldo_ab);
          --DBMS_OUTPUT.PUT_LINE('w_imp_evasa_mini_ab '||w_imp_evasa_mini_ab);
          --DBMS_OUTPUT.PUT_LINE('w_imp_evasa_acconto_ter '||w_imp_evasa_acconto_ter);
          --DBMS_OUTPUT.PUT_LINE('w_imp_evasa_saldo_ter '||w_imp_evasa_saldo_ter);
          --DBMS_OUTPUT.PUT_LINE('w_imp_evasa_mini_ter '||w_imp_evasa_mini_ter);
          --DBMS_OUTPUT.PUT_LINE('---------------------------------------------------');
          --DBMS_OUTPUT.PUT_LINE('w_imp_dovuta_dic '||w_imp_dovuta_dic);
          IF w_versamenti_acconto >= w_imp_dovuta_acconto_dic THEN
             IF w_versamenti_saldo >= w_imp_dovuta_saldo_dic THEN
                w_imp_evasa_acconto_dic       := w_imp_dovuta_acconto_dic - w_versamenti_acconto;
                w_imp_evasa_saldo_dic         := w_imp_dovuta_saldo_dic - w_versamenti_saldo;
                -- w_imp_evasa_acconto_dic_ab    := w_imp_dovuta_acconto_dic_ab - w_versamenti_acconto_ab;
                -- w_imp_evasa_saldo_dic_ab      := w_imp_dovuta_saldo_dic_ab - w_versamenti_saldo_ab;
                -- w_imp_evasa_acconto_dic_ter   := w_imp_dovuta_acconto_dic_ter - w_versamenti_acconto_ter;
                -- w_imp_evasa_saldo_dic_ter     := w_imp_dovuta_saldo_dic_ter - w_versamenti_saldo_ter;
                -- w_imp_evasa_acconto_dic_aree  := w_imp_dovuta_acconto_dic_aree - w_versamenti_acconto_aree;
                -- w_imp_evasa_saldo_dic_aree    := w_imp_dovuta_saldo_dic_aree - w_versamenti_saldo_aree;
                -- w_imp_evasa_acconto_dic_altri := w_imp_dovuta_acconto_dic_altri - w_versamenti_acconto_altri;
                -- w_imp_evasa_saldo_dic_altri   := w_imp_dovuta_saldo_dic_altri - w_versamenti_saldo_altri;
             ELSIF w_versamenti >= w_imp_dovuta_dic THEN
                w_imp_evasa_acconto_dic := (w_imp_dovuta_dic - w_imp_dovuta_mini_dic) - (w_versamenti - w_versamenti_mini);
                w_imp_evasa_saldo_dic   := 0;
                -- w_imp_evasa_acconto_dic_ab := w_imp_dovuta_dic_ab - w_versamenti_ab;
                -- w_imp_evasa_saldo_dic_ab   := 0;
                -- w_imp_evasa_acconto_dic_ter := w_imp_dovuta_dic_ter - w_versamenti_ter;
                -- w_imp_evasa_saldo_dic_ter   := 0;
                -- w_imp_evasa_acconto_dic_aree := w_imp_dovuta_dic_aree - w_versamenti_aree;
                -- w_imp_evasa_saldo_dic_aree   := 0;
                -- w_imp_evasa_acconto_dic_altri := w_imp_dovuta_dic_altri - w_versamenti_altri;
                -- w_imp_evasa_saldo_dic_altri   := 0;
             ELSE
                w_imp_evasa_acconto_dic       := 0;
                w_imp_evasa_saldo_dic         := (w_imp_dovuta_dic - w_imp_dovuta_mini_dic) - (w_versamenti - w_versamenti_mini); --w_imp_dovuta_dic - w_versamenti;
                -- w_imp_evasa_acconto_dic_ab    := 0;
                -- w_imp_evasa_saldo_dic_ab      := w_imp_dovuta_dic_ab - w_versamenti_ab;
                -- w_imp_evasa_acconto_dic_ter   := 0;
                -- w_imp_evasa_saldo_dic_ter     := w_imp_dovuta_dic_ter - w_versamenti_ter;
                -- w_imp_evasa_acconto_dic_aree  := 0;
                -- w_imp_evasa_saldo_dic_aree    := w_imp_dovuta_dic_aree - w_versamenti_aree;
                -- w_imp_evasa_acconto_dic_altri := 0;
                -- w_imp_evasa_saldo_dic_altri   := w_imp_dovuta_dic_altri - w_versamenti_altri;
             END IF;
          ELSE
             IF w_versamenti_saldo < w_imp_dovuta_saldo_dic THEN
                w_imp_evasa_acconto_dic       := w_imp_dovuta_acconto_dic - w_versamenti_acconto;
                w_imp_evasa_saldo_dic         := w_imp_dovuta_saldo_dic - w_versamenti_saldo;
                -- w_imp_evasa_acconto_dic_ab    := w_imp_dovuta_acconto_dic_ab - w_versamenti_acconto_ab;
                -- w_imp_evasa_saldo_dic_ab      := w_imp_dovuta_saldo_dic_ab - w_versamenti_saldo_ab;
                -- w_imp_evasa_acconto_dic_ter   := w_imp_dovuta_acconto_dic_ter - w_versamenti_acconto_ter;
                -- w_imp_evasa_saldo_dic_ter     := w_imp_dovuta_saldo_dic_ter - w_versamenti_saldo_ter;
                -- w_imp_evasa_acconto_dic_aree  := w_imp_dovuta_acconto_dic_aree - w_versamenti_acconto_aree;
                -- w_imp_evasa_saldo_dic_aree    := w_imp_dovuta_saldo_dic_aree - w_versamenti_saldo_aree;
                -- w_imp_evasa_acconto_dic_altri := w_imp_dovuta_acconto_dic_altri - w_versamenti_acconto_altri;
                -- w_imp_evasa_saldo_dic_altri   := w_imp_dovuta_saldo_dic_altri - w_versamenti_saldo_altri;
             ELSIF w_versamenti >= w_imp_dovuta_dic THEN
                w_imp_evasa_acconto_dic       := 0;
                w_imp_evasa_saldo_dic         := (w_imp_dovuta_dic - w_imp_dovuta_mini_dic) - (w_versamenti - w_versamenti_mini); --w_imp_dovuta_dic - w_versamenti;
                -- w_imp_evasa_acconto_dic_ab    := 0;
                -- w_imp_evasa_saldo_dic_ab      := w_imp_dovuta_dic_ab - w_versamenti_ab;
                -- w_imp_evasa_acconto_dic_ter   := 0;
                -- w_imp_evasa_saldo_dic_ter     := w_imp_dovuta_dic_ter - w_versamenti_ter;
                -- w_imp_evasa_acconto_dic_aree  := 0;
                -- w_imp_evasa_saldo_dic_aree    := w_imp_dovuta_dic_aree - w_versamenti_aree;
                -- w_imp_evasa_acconto_dic_altri := 0;
                -- w_imp_evasa_saldo_dic_altri   := w_imp_dovuta_dic_altri - w_versamenti_altri;
             ELSE
                w_imp_evasa_acconto_dic := (w_imp_dovuta_dic - w_imp_dovuta_mini_dic) - (w_versamenti - w_versamenti_mini);
                w_imp_evasa_saldo_dic   := 0;
                -- w_imp_evasa_acconto_dic_ab := w_imp_dovuta_dic_ab - w_versamenti_ab;
                -- w_imp_evasa_saldo_dic_ab   := 0;
                -- w_imp_evasa_acconto_dic_ter := w_imp_dovuta_dic_ter - w_versamenti_ter;
                -- w_imp_evasa_saldo_dic_ter   := 0;
                -- w_imp_evasa_acconto_dic_aree := w_imp_dovuta_dic_aree - w_versamenti_aree;
                -- w_imp_evasa_saldo_dic_aree   := 0;
                -- w_imp_evasa_acconto_dic_altri := w_imp_dovuta_dic_altri - w_versamenti_altri;
                -- w_imp_evasa_saldo_dic_altri   := 0;
             END IF;
          END IF;
          -- Mini IMU
          if w_versamenti_mini >= w_imp_dovuta_mini_dic then
             w_imp_evasa_mini_dic := 0;
          else
             w_imp_evasa_mini_dic := w_imp_dovuta_mini_dic - w_versamenti_mini;
          end if;
          --DBMS_OUTPUT.PUT_LINE('w_imp_evasa_acconto_dic '||w_imp_evasa_acconto_dic);
          --DBMS_OUTPUT.PUT_LINE('w_imp_evasa_saldo_dic '||w_imp_evasa_saldo_dic);
          --DBMS_OUTPUT.PUT_LINE('w_imp_evasa_mini_dic '||w_imp_evasa_mini_dic);
          -- Gestione delle imposte negative --
          if a_anno >= 2012 then
             -- Acconto --
             liquidazioni_imu_imp_negativi(w_imp_evasa_acconto,w_imp_evasa_acconto_ab
                                          ,w_imp_eva_acc_ter_comu,w_imp_eva_acc_ter_erar
                                          ,w_imp_eva_acc_aree_comu,w_imp_eva_acc_aree_erar
                                          ,w_imp_eva_acc_rur
                                          ,w_imp_eva_acc_fab_d_comu,w_imp_eva_acc_fab_d_erar
                                          ,w_imp_eva_acc_altri_comu,w_imp_eva_acc_altri_erar
                                          ,w_imp_eva_acc_fab_m
                                          );
             -- Saldo --
             liquidazioni_imu_imp_negativi(w_imp_evasa_saldo,w_imp_evasa_saldo_ab
                                          ,w_imp_eva_saldo_ter_comu,w_imp_eva_saldo_ter_erar
                                          ,w_imp_eva_saldo_aree_comu,w_imp_eva_saldo_aree_erar
                                          ,w_imp_eva_saldo_rur
                                          ,w_imp_eva_saldo_fab_d_comu,w_imp_eva_saldo_fab_d_erar
                                          ,w_imp_eva_saldo_altri_comu,w_imp_eva_saldo_altri_erar
                                          ,w_imp_eva_saldo_fab_m
                                          );
          end if;
          /*
             Gli interessi vengono calcolati sul dichiarato.
          Esempio di uso, ho una dichiarazione con in acconto da pagare 15 euro e a saldo 15 euro.
          Se faccio un versamento unico di 10 euro gli interessi vengono applicati su 5 euro per l'acconto e 15 euro per il saldo
          Se faccio un versamento unico di 20 euro gli interessi vengono applicati su 10 euro per il saldo
          Se faccio un versamento unico di 40 euro gli interessi a rimborso vengono applicati su 10 euro per l'acconto
          */
          --DBMS_OUTPUT.PUT_LINE('w_1000 '||w_1000);
          --DBMS_OUTPUT.PUT_LINE(' -- w_imp_evasa_acconto '||w_imp_evasa_acconto);
          --DBMS_OUTPUT.PUT_LINE(' -- w_imp_evasa_saldo '||w_imp_evasa_saldo);
          --DBMS_OUTPUT.PUT_LINE(' -- w_imp_evasa_mini '||w_imp_evasa_mini);
--          raise_application_error (-20999,' -- w_imp_dovuta_acconto_dic '||w_imp_dovuta_acconto_dic||
----                                   ' -- w_versamenti_acconto '||w_versamenti_acconto||
--                                   ' -- w_diff_acc '||w_diff_acc||
--                                   ' -- w_imp_evasa_acconto '||w_imp_evasa_acconto||
--                                   ' -- w_imp_evasa_acconto_dic '||w_imp_evasa_acconto_dic||
----                                   ' -- w_imp_evasa_saldo '||w_imp_evasa_saldo||
--                                   ' -- w_imp_evasa_saldo_dic '||w_imp_evasa_saldo_dic||
--                                   ' w_1000 '||w_1000);
          IF w_imp_evasa_acconto != 0 and abs(w_imp_evasa_acconto + w_imp_evasa_saldo + w_imp_evasa_mini) > w_1000 THEN
            --  ANOMALIA 1 e 101
             w_cod_sanzione := C_IMPO_EVASA_ACC;
             inserimento_sanzione_liq_imu(w_cod_sanzione,C_TIPO_TRIBUTO
                                         ,w_pratica,NULL
                                         ,NULL,w_imp_evasa_acconto
                                         ,w_imp_evasa_acconto_ab
                                         ,w_imp_eva_acc_ter_comu,w_imp_eva_acc_ter_erar
                                         ,w_imp_eva_acc_aree_comu,w_imp_eva_acc_aree_erar
                                         ,w_imp_eva_acc_rur
                                         ,w_imp_eva_acc_fab_d_comu,w_imp_eva_acc_fab_d_erar
                                         ,w_imp_eva_acc_altri_comu,w_imp_eva_acc_altri_erar
                                         ,w_imp_eva_acc_fab_m
                                         ,a_utente
                                         ,w_data_scad_acconto);
             w_cod_sanzione := w_cod_sanzione + C_NUOVO;
             inserimento_sanzione_liq_imu(w_cod_sanzione,C_TIPO_TRIBUTO
                                         ,w_pratica,NULL
                                         ,NULL,w_imp_evasa_acconto
                                         ,w_imp_evasa_acconto_ab
                                         ,w_imp_eva_acc_ter_comu,w_imp_eva_acc_ter_erar
                                         ,w_imp_eva_acc_aree_comu,w_imp_eva_acc_aree_erar
                                         ,w_imp_eva_acc_rur
                                         ,w_imp_eva_acc_fab_d_comu,w_imp_eva_acc_fab_d_erar
                                         ,w_imp_eva_acc_altri_comu,w_imp_eva_acc_altri_erar
                                         ,w_imp_eva_acc_fab_m
                                         ,a_utente
                                         ,w_data_scad_acconto);
          END IF;

             w_diff_acc := w_imp_dovuta_acconto_dic - w_versamenti_acconto;
             IF w_imp_evasa_saldo_dic = 0 THEN
                w_diff_acc := w_imp_dovuta_acconto_dic + w_imp_dovuta_saldo_dic - (w_versamenti - w_versamenti_mini);
             END IF;
             --DBMS_OUTPUT.PUT_LINE('w_diff_acc (1)'||w_diff_acc);

--          raise_application_error (-20999,' -- w_imp_dovuta_acconto_dic '||w_imp_dovuta_acconto_dic||
----                                   ' -- w_versamenti_acconto '||w_versamenti_acconto||
--                                   ' -- w_diff_acc '||w_diff_acc||
--                                   ' -- w_imp_evasa_acconto '||w_imp_evasa_acconto||
--                                   ' -- w_imp_evasa_acconto_dic '||w_imp_evasa_acconto_dic||
------                                   ' -- w_imp_evasa_saldo '||w_imp_evasa_saldo||
--                                   ' -- w_imp_evasa_saldo_dic '||w_imp_evasa_saldo_dic||
--                                   ' w_1000 '||w_1000);

             IF w_diff_acc <> 0 and w_imp_evasa_acconto_dic <> 0 THEN
                IF  abs(w_imp_dovuta_dic - w_versamenti) > w_5000
                  AND w_imp_dovuta_dic <> w_imp_dovuta
                   OR  w_imp_dovuta_dic = w_imp_dovuta   THEN
                     IF w_diff_acc > 0 THEN
                        IF w_versamenti_acconto >= 0 THEN
                           inserimento_interessi(w_pratica,NULL,w_data_scad_acconto,a_data_rif_interessi,w_diff_acc,
                                                                                  C_TIPO_TRIBUTO,'A',a_utente,w_data_scad_acconto);
                        ELSE
                           inserimento_interessi(w_pratica,NULL,w_data_scad_saldo,a_data_rif_interessi,w_diff_acc,
                                                                                  C_TIPO_TRIBUTO,'A',a_utente,w_data_scad_saldo);
                        END IF;
                     ELSE
                     --DBMS_OUTPUT.PUT_LINE('w_diff_acc (2)'||w_diff_acc);
                     --inserimento_interessi(w_pratica,NULL,w_data_pagamento_max_acc,a_data_rif_interessi,w_diff_acc,
                     --                                                           C_TIPO_TRIBUTO,'A',a_utente,w_data_pagamento_max_acc);
                       inserimento_interessi(w_pratica,NULL,w_data_scad_acconto,a_data_rif_interessi,w_diff_acc,
                                                                                  C_TIPO_TRIBUTO,'A',a_utente,w_data_scad_acconto);
                     END IF;
                END IF;
             END IF;
             IF w_imp_dovuta  < w_imp_dovuta_dic THEN
                -- IF a_data_rif_interessi >= to_date('01012000','ddmmyyyy') THEN
                --     w_data_rif_interessi := to_date('31121999','ddmmyyyy') ;
                --  ELSE
                w_data_rif_interessi := a_data_rif_interessi;
                --   END IF;
                IF a_flag_rimborso = 'S' then -- 10/05/2001
                    if w_imp_evasa_saldo = 0 and w_versamenti_saldo = 0 then
                      -- inserisco l'interesse a rimborso per accorto + saldo (versamento unico)
                      inserimento_interessi(w_pratica,NULL,w_data_scad_acconto,w_data_rif_interessi,w_imp_dovuta - w_imp_dovuta_dic,
                                                                                                      C_TIPO_TRIBUTO,'A',a_utente,w_data_scad_acconto);
                    else
                      -- inserisco l'interesse a rimborso per l'acconto
                      inserimento_interessi(w_pratica,NULL,w_data_scad_acconto,w_data_rif_interessi,w_imp_dovuta_acconto - w_imp_dovuta_acconto_dic,
                                                                                                      C_TIPO_TRIBUTO,'A',a_utente,w_data_scad_acconto);
                    end if;
                END IF;
             END IF;
--          END IF;
          --
          --DBMS_OUTPUT.PUT_LINE('w_imp_evasa_saldo '||w_imp_evasa_saldo);
          --DBMS_OUTPUT.PUT_LINE('w_imp_evasa_mini '||w_imp_evasa_mini);
--          raise_application_error (-20999,'  w_imp_dovuta_acconto_dic '||w_imp_dovuta_acconto_dic||
--                                   '  w_versamenti_acconto '||w_versamenti_acconto||
--                                   '  w_diff_acc '||w_diff_acc||
--                                   '  w_diff_sal '||w_diff_sal||
--                                   '  w_imp_evasa_acconto '||w_imp_evasa_acconto||
--                                   '  w_imp_evasa_saldo '||w_imp_evasa_saldo||
--                                   '  w_imp_evasa_saldo_dic '||w_imp_evasa_saldo_dic||
--                                   ' w_1000 '||w_1000);

          IF w_imp_evasa_saldo != 0 and
             abs(w_imp_evasa_acconto + w_imp_evasa_saldo + w_imp_evasa_mini) > w_1000 THEN   -- ANOMALIA 21 e 121
             w_cod_sanzione := C_IMPO_EVASA_SAL;
             inserimento_sanzione_liq_imu(w_cod_sanzione,C_TIPO_TRIBUTO
                                         ,w_pratica,NULL
                                         ,NULL,(w_imp_evasa_saldo)
                                         ,(w_imp_evasa_saldo_ab)
                                         ,(w_imp_eva_saldo_ter_comu)
                                         ,w_imp_eva_saldo_ter_erar
                                         ,w_imp_eva_saldo_aree_comu,w_imp_eva_saldo_aree_erar
                                         ,w_imp_eva_saldo_rur
                                         ,w_imp_eva_saldo_fab_d_comu,w_imp_eva_saldo_fab_d_erar
                                         ,w_imp_eva_saldo_altri_comu,w_imp_eva_saldo_altri_erar
                                         ,w_imp_eva_saldo_fab_m
                                         ,a_utente
                                         ,w_data_scad_saldo);
             w_cod_sanzione := w_cod_sanzione + C_NUOVO;
             inserimento_sanzione_liq_imu(w_cod_sanzione,C_TIPO_TRIBUTO
                                         ,w_pratica,NULL
                                         ,NULL,(w_imp_evasa_saldo)
                                         ,(w_imp_evasa_saldo_ab)
                                         ,(w_imp_eva_saldo_ter_comu)
                                         ,w_imp_eva_saldo_ter_erar
                                         ,w_imp_eva_saldo_aree_comu,w_imp_eva_saldo_aree_erar
                                         ,w_imp_eva_saldo_rur
                                         ,w_imp_eva_saldo_fab_d_comu,w_imp_eva_saldo_fab_d_erar
                                         ,w_imp_eva_saldo_altri_comu,w_imp_eva_saldo_altri_erar
                                         ,w_imp_eva_saldo_fab_m
                                         ,a_utente
                                         ,w_data_scad_saldo);
          END IF;

             w_diff_sal := (w_imp_dovuta_dic - w_imp_dovuta_acconto_dic - w_imp_dovuta_mini_dic) - (w_versamenti - w_versamenti_acconto - w_versamenti_mini);
             --dbms_output.put_line('w_imp_evasa_acconto_dic '||w_imp_evasa_acconto_dic);
             IF w_imp_evasa_acconto_dic = 0 THEN
                w_diff_sal := w_imp_dovuta_acconto_dic + w_imp_dovuta_saldo_dic - (w_versamenti - w_versamenti_mini);
             END IF;
--          raise_application_error (-20999,' -- w_imp_dovuta_acconto_dic '||w_imp_dovuta_acconto_dic||
----                                   ' -- w_versamenti_acconto '||w_versamenti_acconto||
--                                   ' -- w_diff_sal '||w_diff_sal||
----                                   ' -- w_imp_evasa_acconto '||w_imp_evasa_acconto||
----                                   ' -- w_imp_evasa_acconto_dic '||w_imp_evasa_acconto_dic||
--                                   ' -- w_imp_evasa_saldo '||w_imp_evasa_saldo||
--                                   ' -- w_imp_evasa_saldo_dic '||w_imp_evasa_saldo_dic||
--                                   ' w_1000 '||w_1000);

             IF w_diff_sal <> 0 and w_imp_evasa_saldo_dic <> 0 THEN
                 IF  abs(w_imp_dovuta_dic - w_versamenti) > w_5000
                   AND w_imp_dovuta_dic <> w_imp_dovuta
                   OR  w_imp_dovuta_dic = w_imp_dovuta   THEN
                   --DBMS_OUTPUT.PUT_LINE('w_diff_sal '|| w_diff_sal);
                   --dbms_output.put_line('w_imp_evasa_saldo_dic '||w_imp_evasa_saldo_dic);
                   --dbms_output.put_line('w_imp_evasa_mini_dic '||w_imp_evasa_mini_dic);

                     IF w_diff_sal > 0 THEN
                        IF w_imp_evasa_saldo_dic <> 0 THEN
                          inserimento_interessi(w_pratica,NULL,w_data_scad_saldo,a_data_rif_interessi,w_imp_evasa_saldo_dic,
                                                                                                C_TIPO_TRIBUTO,'S',a_utente,w_data_scad_saldo);
                        END IF;
                        --IF w_imp_evasa_mini_dic > 0 THEN
                        --   inserimento_interessi(w_pratica,NULL,w_data_scad_mini,a_data_rif_interessi,w_imp_evasa_mini_dic,
                        --                                                                      C_TIPO_TRIBUTO,'M',a_utente,w_data_scad_mini);
                        --END IF;
                     ELSE
                        --IF w_imp_evasa_mini_dic > 0 THEN  -- AB Aggiunto questo controllo il 9/8/16 da verificare, alcuni casi vanno bene
                        --  w_imp_appoggio := w_imp_evasa_saldo_dic - w_imp_evasa_mini_dic;
                        --  inserimento_interessi(w_pratica,NULL,w_data_scad_saldo,a_data_rif_interessi,w_imp_appoggio,
                        --                                                                       C_TIPO_TRIBUTO,'S',a_utente,w_data_scad_saldo);
                        --ELSE
                          inserimento_interessi(w_pratica,NULL,w_data_pagamento_max_sal,a_data_rif_interessi,w_diff_sal,
                                                                                                 C_TIPO_TRIBUTO,'S',a_utente,w_data_pagamento_max_sal);
                        --END IF;
                     END IF;
--                 END IF;
             END IF;
             IF w_imp_dovuta < w_imp_dovuta_dic THEN
                --  IF a_data_rif_interessi >= to_date('01012000','ddmmyyyy') THEN
                --  w_data_rif_interessi := to_date('31121999','ddmmyyyy') ;
                -- ELSE
                w_data_rif_interessi := a_data_rif_interessi;
                --  END IF;
                IF a_flag_rimborso = 'S' then -- 10/05/2001
                   inserimento_interessi(w_pratica,NULL,w_data_scad_saldo,w_data_rif_interessi,
                                              (w_imp_dovuta - w_imp_dovuta_acconto) - (w_imp_dovuta_dic - w_imp_dovuta_acconto_dic),
                                                                                                   C_TIPO_TRIBUTO,'S',a_utente,w_data_scad_saldo);
                END IF;
             END IF;
          END IF;
            --DBMS_OUTPUT.PUT_LINE('w_imp_evasa_mini '||w_imp_evasa_mini);
            if w_imp_evasa_mini != 0 and
               abs(w_imp_evasa_acconto + w_imp_evasa_saldo + w_imp_evasa_mini) > w_1000 THEN
               w_cod_sanzione := C_IMPO_EVASA_MINI;
               inserimento_sanzione_liq_imu(w_cod_sanzione,C_TIPO_TRIBUTO
                                           ,w_pratica,NULL
                                           ,NULL,w_imp_evasa_mini
                                           ,w_imp_evasa_mini_ab
                                           ,w_imp_evasa_mini_ter,to_number(null)
                                           ,to_number(null),to_number(null)
                                           ,to_number(null)
                                           ,to_number(null),to_number(null)
                                           ,to_number(null),to_number(null)
                                           ,to_number(null)
                                           ,a_utente,w_data_scad_mini);
             --inserimento_interessi(w_pratica,NULL,w_data_scad_mini,a_data_rif_interessi,w_imp_evasa_mini_dic,
             --                                                                C_TIPO_TRIBUTO,'M',a_utente,w_data_scad_mini);
               inserimento_interessi(w_pratica,NULL,w_data_scad_mini,a_data_rif_interessi,w_imp_evasa_mini,
                                                                               C_TIPO_TRIBUTO,'M',a_utente,w_data_scad_mini);
            end if;
            w_data_scad_denuncia := F_SCADENZA_DENUNCIA(C_TIPO_TRIBUTO,a_anno);
            IF w_data_scad_denuncia is NULL THEN
               w_errore := 'Errore in ricerca Scadenze (Denuncia) ('||SQLERRM||')';
               RAISE errore;
            ELSE
               BEGIN
                 select prtr.data - w_data_scad_denuncia,
                        deic.flag_cf,
                        deic.flag_firma,
                        prtr.data
                   into w_gg_pres_denuncia,
                        w_flag_cf,
                        w_flag_firma,
                        w_flag_data
                   from denunce_ici deic,pratiche_tributo prtr
                  where prtr.pratica      = deic.pratica (+)
                    and prtr.tipo_tributo = C_TIPO_TRIBUTO
                    and prtr.cod_fiscale  = rec_cont.cod_fiscale
                    and prtr.anno         = a_anno
                    and prtr.tipo_pratica = 'D'
                ;
                RAISE too_many_rows;
               EXCEPTION
                WHEN no_data_found THEN null;
                   WHEN too_many_rows THEN
                  IF w_flag_cf = 'S' THEN      -- ANOMALIA 11 e 111
                     w_cod_sanzione := C_ERRATO_CF;
                     inserimento_sanzione(w_cod_sanzione,C_TIPO_TRIBUTO,w_pratica,NULL,NULL,NULL,a_utente,0,w_flag_data);
                     w_cod_sanzione := w_cod_sanzione + C_NUOVO;
                     inserimento_sanzione(w_cod_sanzione,C_TIPO_TRIBUTO,w_pratica,NULL,NULL,NULL,a_utente,0,w_flag_data);
                  END IF;
                  IF w_flag_firma = 'S' THEN   -- ANOMALIA 12 E 112
                     w_cod_sanzione := C_ERRATA_FIRMA;
                     inserimento_sanzione(w_cod_sanzione,C_TIPO_TRIBUTO,w_pratica,NULL,NULL,NULL,a_utente,0,w_flag_data);
                     w_cod_sanzione := w_cod_sanzione + C_NUOVO;
                     inserimento_sanzione(w_cod_sanzione,C_TIPO_TRIBUTO,w_pratica,NULL,NULL,NULL,a_utente,0,w_flag_data);
                  END IF;
                  IF w_gg_pres_denuncia between 1 and 30 THEN   -- ANOMALIA 2 e 102
                     w_cod_sanzione := C_TARD_DEN_INF_30;
                     inserimento_sanzione(w_cod_sanzione,C_TIPO_TRIBUTO,w_pratica,NULL,w_imp_dovuta,NULL,a_utente,0,w_data_scad_denuncia);
                     w_cod_sanzione := w_cod_sanzione + C_NUOVO;
                     inserimento_sanzione(w_cod_sanzione,C_TIPO_TRIBUTO,w_pratica,NULL,w_imp_dovuta,NULL,a_utente,0,w_data_scad_denuncia);
                  ELSIF w_gg_pres_denuncia > 30 THEN       -- ANOMALIA 3 e 103
                     w_cod_sanzione := C_TARD_DEN_SUP_30;
                     inserimento_sanzione(w_cod_sanzione,C_TIPO_TRIBUTO,w_pratica,NULL,w_imp_dovuta,NULL,a_utente,0,w_data_scad_denuncia);
                     w_cod_sanzione := w_cod_sanzione + C_NUOVO;
                     inserimento_sanzione(w_cod_sanzione,C_TIPO_TRIBUTO,w_pratica,NULL,w_imp_dovuta,NULL,a_utente,0,w_data_scad_denuncia);
                  END IF;
                WHEN others THEN
                  w_errore := 'Errore in controllo presentazione denuncia ('||SQLERRM||')';
                  RAISE errore;
               END;
            END IF; -- w_data_scad_denuncia is NULL
            --dbms_output.put_line('a_data_liquidazione '||a_data_liquidazione);
            IF w_imp_dovuta_dic > 0 THEN  -- Se dichiarato = 0 non esistono sanzioni su i Versamenti
               if a_data_liquidazione < to_date('06072011','ddmmyyyy') then
                  LIQUIDAZIONI_ICI_SANZ_VERS
                    (a_anno, w_pratica, rec_cont.cod_fiscale, w_data_scad_acconto, w_data_scad_saldo,
                     w_imp_dovuta_acconto, w_imp_dovuta_saldo, a_utente);
               else
                  --dbms_output.put_line( 'LIQUIDAZIONI_ICI_SANZ_VERS_711('||a_anno||', '||w_pratica||', '||rec_cont.cod_fiscale||', '||
                  --   w_data_scad_acconto||', '||w_data_scad_saldo||', '||
                  --   w_imp_dovuta_acconto||', '||w_imp_dovuta_saldo||', '||a_utente||', '||
                  --   w_data_scad_mini||', '||w_imp_dovuta_mini||')');
                  LIQUIDAZIONI_ICI_SANZ_VERS_711
                    (a_anno, w_pratica, rec_cont.cod_fiscale, w_data_scad_acconto, w_data_scad_saldo,
                     w_imp_dovuta_acconto, w_imp_dovuta_saldo, a_utente,
                     w_data_scad_mini, w_imp_dovuta_mini);
               end if;
               -- Si usa w_imp_dovuta invece della w_imp_dovuta_dic se la prima e' minore
               -- della seconda, cio' accade in seguito ad una svalutazione dell'immobile
               --dbms_output.put_line('w_imp_dovuta_acconto: '||w_imp_dovuta_acconto);
               --dbms_output.put_line('w_imp_dovuta_acconto_dic: '||w_imp_dovuta_acconto_dic);
               IF w_imp_dovuta_acconto < w_imp_dovuta_acconto_dic THEN
                  w_imp_appoggio := w_imp_dovuta_acconto;
               ELSE
                  w_imp_appoggio := w_imp_dovuta_acconto_dic;
               END IF;
               w_diff_acconto   := w_imp_appoggio - w_versamenti_acconto;
               --dbms_output.put_line('w_diff_acconto: '||w_diff_acconto);
               w_vers_ecc_saldo := w_versamenti_saldo - least(w_imp_dovuta_saldo_dic,w_imp_dovuta_saldo);
               w_vers_ecc_saldo := least(w_vers_ecc_saldo,w_diff_acconto);
              IF nvl(w_imp_appoggio,0) != 0 AND w_diff_acconto > 0 THEN
                if w_vers_ecc_saldo > 0 THEN
                   -- La sanzione seguente viene inserita nel caso si abbia un versamento a saldo in eccedenza,
                   -- che va a coprire un eventuale imposta di acconto non pagata
                      if a_data_liquidazione < to_date('06072011','ddmmyyyy') then
                      -- ANOMALIA 7 e 107
                         w_cod_sanzione := C_TARD_VERS_ACC_SUP_7;
                         inserimento_sanzione_ici(w_cod_sanzione,C_TIPO_TRIBUTO,w_pratica,w_vers_ecc_saldo,a_utente,w_data_scad_acconto);
                         w_cod_sanzione := w_cod_sanzione + C_NUOVO;
                         inserimento_sanzione_ici(w_cod_sanzione,C_TIPO_TRIBUTO,w_pratica,w_vers_ecc_saldo,a_utente,w_data_scad_acconto);
                      /* else
                         --
                         -- (VD - 12/10/2016): occorre definire i giorni di ritardo rispetto all'acconto,
                         --                    perche dal 2016 cambia la percentuale e quindi il codice sanzione
                         --                    Corretta anche gestione tardivi versamenti per anni < 2016:
                         --                    in questo caso non gestiva gli scaglioni di giorni di ritardo
                         --
                         -- (VD - 29/11/2016): la gestione del versamento a saldo in
                         --                    eccedenza viene effettuata nella
                         --                    LIQUIDAZIONI_ICI_SANZ_VERS_711;
                         --                    rimane per le date anteriori al 6/7/2011
                         --
                         if a_data_liquidazione >= to_date('01012016','ddmmyyyy') then
                            if (w_data_pagamento_max_sal - w_data_scad_acconto) > 90 then
                               w_cod_sanzione := C_TARD_VERS_ACC_SUP_90; -- Anomalia 210
                            elsif (w_data_pagamento_max_sal - w_data_scad_acconto) > 15 then
                               w_cod_sanzione := C_TARD_VERS_ACC_INF_90; -- Anomalia 207
                            else
                               w_cod_sanzione := C_TARD_VERS_ACC_INF_15; -- Anomalia 206
                            end if;
                         else
                            if (w_data_pagamento_max_sal - w_data_scad_acconto) > 15 then
                               w_cod_sanzione := C_TARD_VERS_ACC_INF_90; -- Anomalia 207
                            else
                               w_cod_sanzione := C_TARD_VERS_ACC_INF_15; -- Anomalia 206
                            end if;
                         end if;
                         --w_cod_sanzione := C_TARD_VERS_ACC_SUP_15;
                         inserimento_sanzione_ici(w_cod_sanzione,C_TIPO_TRIBUTO,w_pratica,w_vers_ecc_saldo,a_utente,w_data_scad_acconto);*/
                      end if;
                else
                   w_vers_ecc_saldo := 0;
                end if;
                --
                -- (VD - 12/10/2016): si detrae il versamento in eccedenza a saldo dall'acconto residuo da pagare,
                --                    altrimenti il residuo acconto risulta sempre uguale all'acconto totale
                --                    (w_imp_appoggio)
                --
                w_diff_acconto := w_diff_acconto - w_vers_ecc_saldo;
                --DBMS_OUTPUT.PUT_LINE('w_diff_acconto '||w_diff_acconto);
                --DBMS_OUTPUT.PUT_LINE('w_imp_appoggio '||w_imp_appoggio);
                IF  abs(least(w_imp_dovuta_dic,w_imp_dovuta) - w_versamenti) > w_5000 THEN
                   IF w_diff_acconto = w_imp_appoggio THEN   -- ANOMALIA 4 e 104
                      w_cod_sanzione := C_OMESSO_VERS_ACC;
                      --inserimento_sanzione(w_cod_sanzione,C_TIPO_TRIBUTO,w_pratica,NULL,w_diff_acconto - w_vers_ecc_saldo,NULL,a_utente);
                      inserimento_sanzione(w_cod_sanzione,C_TIPO_TRIBUTO,w_pratica,NULL,w_diff_acconto,NULL,a_utente,0,w_data_scad_acconto);
                      w_cod_sanzione := w_cod_sanzione + C_NUOVO;
                      --inserimento_sanzione(w_cod_sanzione,C_TIPO_TRIBUTO,w_pratica,NULL,w_diff_acconto - w_vers_ecc_saldo,NULL,a_utente);
                      inserimento_sanzione(w_cod_sanzione,C_TIPO_TRIBUTO,w_pratica,NULL,w_diff_acconto,NULL,a_utente,0,w_data_scad_acconto);
                   ELSIF (w_imp_evasa_acconto + w_imp_evasa_saldo) > w_1000 THEN   -- ANOMALIA 5 e 105
                      w_cod_sanzione := C_PARZIALE_VERS_ACC;
                      --inserimento_sanzione(w_cod_sanzione,C_TIPO_TRIBUTO,w_pratica, NULL, w_diff_acconto - w_vers_ecc_saldo, NULL, a_utente );
                      inserimento_sanzione(w_cod_sanzione,C_TIPO_TRIBUTO,w_pratica,NULL,w_diff_acconto,NULL,a_utente,0,w_data_scad_acconto);
                      w_cod_sanzione := w_cod_sanzione + C_NUOVO;
                      --inserimento_sanzione(w_cod_sanzione,C_TIPO_TRIBUTO,w_pratica, NULL, w_diff_acconto - w_vers_ecc_saldo, NULL, a_utente );
                      inserimento_sanzione(w_cod_sanzione,C_TIPO_TRIBUTO,w_pratica,NULL,w_diff_acconto,NULL,a_utente,0,w_data_scad_acconto);
                   END IF;
                END IF;
              END IF;
              --
              IF w_imp_dovuta_saldo < w_imp_dovuta_saldo_dic THEN
                w_imp_appoggio := w_imp_dovuta_saldo;
              ELSE
                w_imp_appoggio := w_imp_dovuta_saldo_dic;
              END IF;
              w_diff_saldo := w_imp_appoggio - w_versamenti_saldo;
              if w_diff_acconto < 0 then
                 w_diff_saldo := w_diff_saldo + w_diff_acconto;
              end if;
              IF w_diff_saldo != 0 and
                 w_diff_saldo = w_imp_evasa_mini then
                 w_versamenti_saldo := w_versamenti;
                 w_versamenti_acconto := 0;
              END IF;
              --
              --DBMS_OUTPUT.PUT_LINE('w_imp_dovuta_saldo '||w_imp_dovuta_saldo);
              --DBMS_OUTPUT.PUT_LINE('w_imp_dovuta_saldo_dic '||w_imp_dovuta_saldo_dic);
              --DBMS_OUTPUT.PUT_LINE('w_diff_saldo '||w_diff_saldo);
              --DBMS_OUTPUT.PUT_LINE('w_imp_appoggio '||w_imp_appoggio);
              --DBMS_OUTPUT.PUT_LINE('w_versamenti_saldo '||w_versamenti_saldo);
              --DBMS_OUTPUT.PUT_LINE('w_num_versamenti_saldo '||w_num_versamenti_saldo);
              IF w_diff_saldo != 0 THEN
                 IF  abs(least(w_imp_dovuta_dic,w_imp_dovuta) - w_versamenti) > w_5000
                 AND w_imp_dovuta_dic <> w_imp_dovuta
                 OR  w_imp_dovuta_dic = w_imp_dovuta   THEN
                    IF w_diff_saldo > 0 AND
                       ((w_versamenti_saldo = 0 AND w_num_versamenti_saldo = 0) AND
                         w_diff_saldo = w_imp_appoggio) AND
                       (w_imp_evasa_acconto + w_imp_evasa_saldo + w_imp_evasa_mini) > w_1000 THEN  -- ANOMALIA 22 e 122
                       w_cod_sanzione := C_OMESSO_VERS_SAL;
                       inserimento_sanzione(w_cod_sanzione,C_TIPO_TRIBUTO,w_pratica,NULL,(w_diff_saldo),NULL,a_utente,0,w_data_scad_saldo);
                       w_cod_sanzione := w_cod_sanzione + C_NUOVO;
                       inserimento_sanzione(w_cod_sanzione,C_TIPO_TRIBUTO,w_pratica,NULL,(w_diff_saldo),NULL,a_utente,0,w_data_scad_saldo);
                    -- (VD - 27/12/2021): modificato controllo per parziale versamento a saldo.
                    --ELSIF w_imp_appoggio != 0 AND w_diff_saldo > 0 AND (w_versamenti_saldo != 0 OR w_num_versamenti_saldo > 0) AND
                    ELSIF w_imp_appoggio != 0 AND (w_diff_saldo > 0 OR (w_versamenti_saldo != 0 OR w_num_versamenti_saldo > 0)) AND
                       (w_imp_evasa_acconto + w_imp_evasa_saldo + w_imp_evasa_mini) > w_1000  THEN   -- ANOMALIA 23 e 123
                       w_cod_sanzione := C_PARZIALE_VERS_SAL;
                       inserimento_sanzione_ici(w_cod_sanzione,C_TIPO_TRIBUTO,w_pratica,(w_diff_saldo),a_utente,w_data_scad_saldo);
                       w_cod_sanzione := w_cod_sanzione + C_NUOVO;
                       inserimento_sanzione_ici(w_cod_sanzione,C_TIPO_TRIBUTO,w_pratica,(w_diff_saldo),a_utente,w_data_scad_saldo);
                    END IF;
                 END IF;
              END IF;  -- w_diff_saldo != 0
              --
              IF w_imp_evasa_mini > 0 and (w_imp_evasa_acconto + w_imp_evasa_saldo + w_imp_evasa_mini) > w_1000 THEN
                 if w_versamenti_mini = 0 then
                    w_cod_sanzione := C_OMESSO_VERS_MINI;
                    inserimento_sanzione(w_cod_sanzione,C_TIPO_TRIBUTO,w_pratica,NULL,w_imp_evasa_mini,NULL,a_utente,0,w_data_scad_mini);
                 else
                    w_cod_sanzione := C_PARZIALE_VERS_MINI;
                    inserimento_sanzione_ici(w_cod_sanzione,C_TIPO_TRIBUTO,w_pratica,w_imp_evasa_mini,a_utente,w_data_scad_mini);
                 END IF;
              END IF;
            END IF;
            BEGIN
                select nvl(sum(nvl(importo,0)),0)
                  into w_imp_liq_old
                  from sanzioni_pratica
                 where pratica      = w_pratica
                   and cod_sanzione < 100
                ;
            EXCEPTION
              WHEN others THEN
                 w_errore := 'Errore in totalizz. importo (old) ('||SQLERRM||')';
                 RAISE errore;
            END;
            BEGIN
                select nvl(sum(nvl(importo,0)),0)
                  into w_imp_liq_new
                  from sanzioni_pratica
                 where pratica      = w_pratica
                   and cod_sanzione > 100
                ;
            EXCEPTION
               WHEN others THEN
                  w_errore := 'Errore in totalizz. importo (new) ('||SQLERRM||')';
                  RAISE errore;
            END;
            --
            -- Modifica fatta il 04/05/2005 da Davide per ovviare al disguido secondo cui
            -- non veniva tenuto conto dei limiti eventuali digitati.
            -- (VD - 24/03/2020): le liquidazioni vengono eliminate solo se
            --                    non eseguite da verificatori
            -- (VD - 12/09/2022): Belluno. Le liquidazioni calcolate non si eliminano mai
            -- (VM - 07/05/2024): #54066 - le liquidazioni con importo 0 vengono eliminate solo se
            --                    il parametro LIQ_DIFF_0 non è attivo
            --
            IF lpad(w_provincia,3,'0')||lpad(w_comune,3,'0') <> '025006' and -- Belluno
               w_importanza_ute <> 10 and
             ((w_imp_liq_new = 0 and w_imp_liq_old = 0 and nvl(w_flag_liq_diff_0, 'N') = 'N')
              OR (a_anno >= 1998 AND w_imp_liq_new not between nvl(a_importo_limite_inf,-999999999.99)
                                                           AND nvl(a_importo_limite_sup,999999999.99))
              OR (a_anno < 1998 AND w_imp_liq_old not between nvl(a_importo_limite_inf,-999999999.99)
                                                         AND nvl(a_importo_limite_sup,999999999.99))) THEN
              BEGIN
                 delete pratiche_tributo
                  where pratica = w_pratica;
              EXCEPTION
                 WHEN others THEN
                    w_errore := 'Errore in cancellaz. pratica ('||SQLERRM||')';
                    RAISE errore;
              END;
            ELSIF w_imp_liq_new > w_imp_liq_old and a_anno < 1998 THEN
              BEGIN
                 delete sanzioni_pratica
                  where pratica      = w_pratica
                    and cod_sanzione > 100;
                 if w_imp_liq_old > 0 then
                    w_cod_sanzione := C_SPESE_NOT;
                    inserimento_sanzione(w_cod_sanzione,C_TIPO_TRIBUTO,w_pratica,NULL,NULL,NULL,a_utente,0,a_data_liquidazione);
                 end if;
              EXCEPTION
                WHEN others THEN
                  w_errore := 'Errore in cancellaz. sanz. pratica new ('||SQLERRM||')';
                  RAISE errore;
              END;
            ELSIF w_imp_liq_new <= w_imp_liq_old or a_anno >= 1998 THEN
              BEGIN
                delete sanzioni_pratica
                 where pratica      = w_pratica
                   and cod_sanzione < 100
                     ;
                if w_imp_liq_new > 0 then
                   w_cod_sanzione := C_SPESE_NOT + C_NUOVO;
                   inserimento_sanzione(w_cod_sanzione,C_TIPO_TRIBUTO,w_pratica,NULL,NULL,NULL,a_utente,0,a_data_liquidazione);
                end if;
              EXCEPTION
                WHEN others THEN
                  w_errore := 'Errore in cancellaz. sanz. pratica old ('||SQLERRM||')';
                  RAISE errore;
              END;
            END IF;
            -- (VD - 25/08/2022): se il contribuente è deceduto, si eliminano
            --                    le sanzioni lasciando solo imposta evasa,
            --                    interessi e spese di notifica
            if rec_cont.stato = 50 then
               ELIMINA_SANZ_LIQ_DECEDUTI(w_pratica);
            end if;
            COMMIT;
          END IF; -- w_cont_non_liq = a_cont_non_liq THEN
        END IF; -- w_chkLiquida = 1
      END IF; -- F_IMPOSTA_CONT_ANNO_TITR
    END LOOP;
  ELSE --Flag Riferimenti Oggetto checkato
    LIQUIDAZIONI_ICI_RIOG(a_anno, a_cod_fiscale, a_nome, a_data_liquidazione, a_data_rif_interessi, a_da_data_riog, a_a_data_riog,
      a_importo_limite_inf, a_importo_limite_sup,
      a_da_perc_diff, a_a_perc_diff,
--      w_data_scad_acconto, w_data_scad_saldo,
      a_ricalcolo, a_utente,
      a_flag_versamenti,a_flag_rimborso,a_cont_non_liq);
  END IF;
EXCEPTION
  WHEN errore THEN
       ROLLBACK;
       RAISE_APPLICATION_ERROR (-20999,w_errore,TRUE);
  WHEN others THEN
       ROLLBACK;
       RAISE_APPLICATION_ERROR (-20999,'Errore in Calcolo Liquidazioni IMU'||'('||SQLERRM||')');
END;
/* End Procedure: CALCOLO_LIQUIDAZIONI_IMU */
/
