--liquibase formatted sql 
--changeset abrandolini:20250326_152423_emissione_ruolo stripComments:false runOnChange:true 
 
create or replace procedure EMISSIONE_RUOLO
/******************************************************************************
  NOME:        EMISSIONE_RUOLO
  DESCRIZIONE: Emissione ruolo principale e suppletivo, acconto, saldo e totale
  ANNOTAZIONI: a_flag_normalizzato: 'S' per il calcolo normalizzato
                                    null per il calcolo tradizionale
               a_tipo_limite:       'C' per contribuente
                                    'O' per oggetto
               a_limite:            limite relativo al tipo di limite;
                                    un number di 13
  REVISIONI:
  Rev.  Data        Autore  Note
  ----  ----------  ------  ----------------------------------------------------
  036   14/03/2025  RV      #79428
                            Esteso dimensione campi w_dettaglio_ogim e w_dettaglio_faog
                            per coerenza con *_base e sotto procedure 
                            calcolo_importo_normalizzato e calcolo_importo_norm_tariffe
  035   07/03/2025  RV      #77568
                            Aggiunto gestione tariffa puntuale x svuotamenti
  034   10/02/2025  RV      #77805
                            Aggiunto gestione perequative spalmate sulle rate
  033   05/12/2024  AB      Messo nello standard il nuovo controllo attivato a
                            Bovezzo in 07/2024, cosi da comportarsi come gli altri
                            enti, altrimenti non tarttava la magg_tares
  032   20/08/2024  AB      #74442 Sostituito il controllo del tipo_occupazione
                            nel supplettivo con ogva al posto di ogpr
  031   28/05/2024  AB      #70397 Componenti perequative
                            Utilizzo di maggiorazione_tares determinata dalla
                            somma delle componenti per l'anno di elaborazione
  030   27/03/2024  AB      Risolto problema emerso ad Albano per campo too small
                            aumentati:
                            w_dettaglio_ogim_base       varchar2(32767);
                            w_dettaglio_faog_base       varchar2(32767);
  029   25/03/2024  AB      #69780
                            Evitata anche la perdita di un numero come avveniva prima ad ogni elaborazione
  028   21/03/2024  AB      #69780
                            Utilizzo delle procedure _NR per poter utilizzare le nuove sequence
  027   14/10/2021  VD      Corretto trattamento contribuenti a ruolo solo a
                            saldo oppure emissione ruolo a saldo senza acconto:
                            in questo caso gli importi quota fissa e variabile
                            venivano annullati. Ora riportano il valore corretto.
  026   15/06/2021  VD      Aggiunto calcolo acconto per ruoli con metodo di
                            calcolo tradizionale usando la percentuale presente
                            sulla tabella RUOLI.
  025   11/12/2020  VD      Modificata gestione flag integrazione DEPAG: ora il
                            flag è memorizzato sulla tabella ruoli e quindi
                            bisogna verificare se il ruolo è passato in DEPAG
                            per decidere se occorre emettere i DEPAG_DOVUTI.
  024   09/07/2020  VD      Castelnuovo Garfagnana: aggiunta emissione DEPAG
                            solo per ruolo totale
  023   07/01/2019  VD      Aggiunto calcolo ruoli con tariffe precalcolate.
  022   06/11/2018  VD      Gestione campi calcolati con tariffa base Bovezzo.
  021   24/10/2018  VD      Gestione campi calcolati con tariffa base.
  020   21/08/2018  VD      Aggiunta gestione sconto conferimenti per Fiorano
                            Modenese (cod.Istat 036013)
  019   21/02/2018  VD      Ruolo principale: sostituita TR4PACKAGE.sel_ogpr_validi
                            con select esplicita per modificare ordinamento
                            (per oggetto e dal anziche oggetto_pratica e dal).
                            Modificato cursore per emissione sgravi su
                            oggetti_pratica presenti nel ruolo di acconto ma non
                            in quello di saldo.
                            Aggiunto parametro oggetto alla procedure
                            IMPORTI_RUOLO_ACCONTO.
  018   30/01/2018  VD      Aggiunto parametro ogpr_rif in IMPORTI_RUOLO_ACC_SAL
  017   24/01/2018  VD      Aggiunto parametro ogpr_rif in IMPORTI_RUOLO_ACCONTO
  016   18/01/2018  VD      Ruolo suppletivo Bovezzo e suppletivo a saldo:
                            spostata memorizzazione importo da scalare dal
                            campo dettaglio_ogim al campo note di oggetti_imposta.
  015   03/01/2018  VD      Corretto controllo limite: prima il controllo sul
                            singolo oggetto veniva fatto sempre sull'importo
                            netto, indipendentemente dal flag importo_lordo
                            presente sul ruolo.
                            Al contrario, il controllo per contribuente era
                            corretto.
                            Modificata anche query finale per eliminare i
                            ruoli inferiori al limite per contribuente: prima
                            trattava sempre tutti i ruoli emessi, anche se
                            l'elaborazione era parziale. Aggiunto codice fiscale
                            nella condizione di where di sel_ruco_limite.
  014   08/11/2017  VD      Pontedera: modifiche per sconti su conferimenti
  013   19/06/2017  VD      Ruoli suppletivi: corretto calcolo da_mese
                            ruoli_contribuente: se il giorno è > 15, si somma 1
                            al mese solo se questo e' < 12
  012   16/11/2016  VD      S.Donato Milanese - Modifiche per sperimentazione
                            Poasco
  011   05/07/2016  SM      Aggiunta gestione contatto 87 per anno >=2015
  010   28/06/2016  AB      Aggiunti incentivi per anno >= 2015
  009   15/03/2016  AB      Aggiunti Incentivi per San Lazzaro nei Suppletivi
                            anno 2014 e 2015, modifica gia lanciata a San Lazzaro
                                        insieme alla Betta
  008   06/07/2015  VD      Aggiunta delete compensazioni nella procedure
                            ELIMINAZIONE_SGRAVI_RUOLO per ruoli suppletivi
                            ulteriori.
  007   30/04/2015  VD      In caso di emissione ruolo suppletivo, aggiunta
                            eliminazione compensazioni automatiche (oltre a
                            quella già prevista per gli sgravi)
  006   25/02/2015  VD      Modificato richiamo procedure ELIMINAZIONE_SGRAVI_RUOLO:
                            in caso di ruolo suppletivo la procedure viene
                            richiamata con tipo_emissione null per eliminare
                            solo gli sgravi del ruolo precedente.
  005   05/02/2015  ET      Corretta determinazione di a_mese in ruoli_contribuente
                        per evitare che venga minore di da_mese
  004   20/01/2015  ET     Modificata chiamata ad eliminazione_sgravi_ruolo
  003   19/01/2015  ET     Realizzata proc. per eliminazione sgravi
  002   01/12/2014  VD     Emissione finale sgravi: modificata query per trattare
                           solo oggetti validi nell'anno per cui si sta emettendo
                           il ruolo
  001   17/09/2014  PM     Inserite le modifiche fatte a San Lazzaro: Incentivi
                           e lancio della f_periodo
  Modifica il: 23/06/2000 - Gestione flag_normalizzato
  Modifica il: 02/08/2000 - Correzione della Variazione di Tariffa,
                            non veniva considerata la vecchia imposta
  Modifica il: 06/09/2000 - Correzione f_importo_da_scalare per suppletivo
  Modifica il: 20/09/2000 - Modificata la sel_ogpr_2
  Modifica il: 21/11/2000 - Gestito il limite e tar superiore, per vt
  Modifica il: 13/02/2001 - Gestita la round di f_importo_da_scalare e il controllo
                            che se imposta negativa non si inserisce in ogim e ruco
  Modifica il: 07/05/2001 - Gestito il Calcolo Normalizzato anche nei Suppletivi
                            e inserita f_importo_da_scalare_norm.
  Modifica il: 08/05/2001 - Trattati i periodi di familiari soggetto per normalizzato.
  Modificato EURO
  D.M. 18/06/2002 - inserite le addizionali, maggiorazioni, iva
  per ruolo principale. Si calcolano se presenti in carichi tarsu,
  se in ruoli esiste il flag importo lordo = S e se il parametro di input
  per il calcolo importo lordo ha valore S
******************************************************************************/
(a_ruolo                 number
,a_utente                varchar2
,a_cod_fiscale           varchar2
,a_flag_richiamo         varchar2
,a_flag_iscritti_p       varchar2
,a_flag_normalizzato     varchar2
,a_tipo_limite           varchar2
,a_limite                number
) IS
w_tipo_tributo             varchar2(5);
w_chk_iscritto             number;
w_tipo_ruolo               number;
w_anno_ruolo               number;
w_anno_emissione           number;
w_progr_emissione          number;
w_incentivi                number;
w_flag_incentivo           varchar2(1);
--w_cf_prec                  varchar2(16);
w_invio_consorzio          date;
w_data_emissione           date;
w_ruolo_rif                number;
w_rate                     number;
w_oggetto_imposta          number;
w_rata_imposta             number;
w_periodo                  number;
w_importo                  number;
w_importo_ruolo            number;
w_imp_scalare              number;
w_tariffe                  varchar2(2000)  := '';
w_note_ogim                varchar2(2000)  := '';
w_lordo_ecc                number;
w_imposta_ecc              number;
w_add_prov_ecc             number;
w_decorrenza_fino_al       date;
errore                     exception;
fine                       exception;
w_errore                   varchar2(2000);
w_limite_ruolo             number;
w_cod_istat                varchar2(6);
w_addizionale_pro          number;
w_addizionale_eca          number;
w_maggiorazione_eca        number;
w_mesi_calcolo             number;
w_aliquota                 number;
w_aliquota_iva             number;
w_tot_addizionali          number;
w_imp_addizionale_pro      number;
w_imp_addizionale_eca      number;
w_imp_maggiorazione_eca    number;
w_imp_aliquota             number;
w_cod_fiscale              varchar2(25) := ' ';
w_importo_lordo            varchar2(1);
w_dal                      date;
w_al                       date;
w_imposta                  number;
w_imposta_pf               number;
w_imposta_pv               number;
w_data_cessazione          date;
w_da_trattare              boolean;
w_importo_pf               number;
w_importo_pv               number;
w_stringa_familiari        varchar2(2000);
w_dettaglio_ogim           varchar2(32767);
w_dettaglio_faog           varchar2(32767);
w_imp_scalare_pf           number;
w_imp_scalare_pv           number;
w_ogpr_rif                 number := 0;
w_da_mese_ruolo            number;
w_a_mese_ruolo             number;
w_tratta_sgravio           number;
w_data_validita            date;
w_data_emissione_ruolo_prec   date;
w_mesi_faog                number;
w_mesi_faog_2sem           number;
w_maggiorazione_tares      number;
w_magg_tares_ogim          number; -- magg tares da mettere a sgravio
w_magg_tares_ogim_sgravi   number; -- magg tares a considerare per capire se c'è da fare uno sgravio
w_magg_tares_cope          number; -- magg tares da componenti perequative
w_coeff_gg                 number;
w_flag_magg_anno           varchar2(1);
w_rata_perequative         varchar2(1);
w_tariffa_puntuale         varchar2(1);
w_giorni_ruolo             number;
w_ins_magg_tares           varchar2(1) := 'N';
w_tipo_emissione           varchar2(1);
w_importo_tot              number;
w_importo_acconto          number;
w_importo_sgravio          number; --importo da mettere a sgravio
w_importo_sgravi           number; --importo da considerare per capire se c'è da fareuno sgravio
w_stato                    varchar2(100);
w_note_calcolo_importo     varchar2(200) := '';
w_cf_del_sgravi             varchar2(16) := '               ';
w_importo_acconto_pf        number;
w_importo_acconto_pv        number;
w_tipo_calcolo_acconto      varchar2(1);
w_ruolo_acconto             number;
w_imposta_dovuta            number;  -- indica il valore di imposta calcolato al quale verra tolot l'acconto è il dato che va anche nelle note
w_imposta_dovuta_acconto    number;  -- indica il valore di imposta calcolato in acconto nell OGIM di ruolo a saldo
w_cod_fiscale_magg          varchar2(16) := '               ';
w_magg_tares_scalare        number;
w_magg_tares_sgravio        number;
-- (VD - 23/10/2018): Variabili per calcolo importi con tariffa base
w_flag_tariffa_base         varchar2(1);
w_tariffa_domestica         number;
w_tariffa_non_domestica     number;
w_tariffa_base              number;
w_limite_base               number;
w_tariffa_superiore_base    number;
w_perc_riduzione_base       number;
w_importo_base              number;
w_importo_pf_base           number;
w_importo_pv_base           number;
w_perc_rid_pf               number;
w_perc_rid_pv               number;
w_importo_rid               number;
w_importo_pf_rid            number;
w_importo_pv_rid            number;
w_stringa_familiari_base    varchar2(2000);
w_dettaglio_ogim_base       varchar2(32767);
w_dettaglio_faog_base       varchar2(32767);
w_note_calcolo_imp_base     varchar2(200) := '';
w_importo_acc_base          number;
w_importo_acc_pf_base       number;
w_importo_acc_pv_base       number;
w_importo_tot_base          number;
w_importo_ruolo_base        number;
w_imp_add_pro_base          number;
w_imp_add_eca_base          number;
w_imp_magg_eca_base         number;
w_imp_aliquota_base         number;
w_tot_addizionali_base      number;
w_imp_scalare_base          number;
w_imp_scalare_pf_base       number;
w_imp_scalare_pv_base       number;
w_imposta_dovuta_base       number;
w_imposta_dovuta_acc_base   number;
w_importo_sgravio_base      number;
w_note_ogim_base            varchar2(2000)  := '';
w_flag_ruolo_tariffa        varchar2(1);
--------------------------------------------
w_rc                        tr4package.tariffe_errate_rc;
w_rec_taer                  tr4package.tariffe_errate_pkg;
--------------------------------------------
-- (VD - 15/11/2017): Variabili per conferimenti Pontedera
TYPE OggettiTyp IS TABLE OF varchar2(1)
   INDEX BY BINARY_INTEGER;
Oggetti_tab OggettiTyp;
-- (VD - 07/07/2020): Variabili per pagonline Castelnuovo
w_pagonline                 varchar2(1);
w_result                    varchar2(6);
w_cod_castel                varchar2(6) := '108009'; --'046009';
-- (VD - 15/06/2021) - modifiche per ruolo in acconto col metodo di calcolo
--                     tradizionale
w_perc_acconto              number;
--
--------------------------------------------
--
-- (VD - 21/02/2018): Cursore per selezione oggetti_pratica validi in
--                    sostituzione del cursore presente nel package TR4PACKAGE
--                    per modificare l'ordinamento dei dati (per oggetto e dal
--                    anziche oggetto_pratica e dal)
--
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
      ,cotr.flag_ruolo
      ,ogva.tipo_occupazione
      ,ogva.tipo_tributo
      ,decode(ogva.anno,a_anno,ogpr.data_concessione,null) data_concessione
      ,ogva.oggetto_pratica_rif
      ,f_get_tariffa_base(ogpr.tributo,ogpr.categoria,a_anno) tipo_tariffa_base
      ,ogco.flag_punto_raccolta
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
      ,ogpr.oggetto
      ,ogva.dal;
--
--------------------------------------------
--
-- Estrazione codici fiscali da ruco, dei contribuenti che hanno la sum
-- di imposta <= limite del ruolo.
-- Necessaria nel caso di a_tipo_limite = 'C'.
-- Devono restare in Ruco solo i contribuenti che hanno sum(importo)
-- > p_limite (limite a ruolo).
-- Quelli estratti da questo cursore sono invece cancellati da ruco ed il
-- loro ogim viene aggiornato mettendo a NULL sia il ruolo che l'importo
-- a ruolo.
--
-- (VD - 03/01/2018): aggiunto codice fiscale passato alla procedure principale,
--                    per trattare solo i contribuenti effettivamente presenti
--                    nell'elaborazione corrente e non cancellare quelli emessi
--                    in elaborazioni precedenti con limite importo piu' basso
--                    o nullo.
--
-- (RV - 21/02/2025): modificato per tener conto anche degli importi delle eccedenze
--
CURSOR sel_ruco_limite
  (p_ruolo                   number
  ,p_cod_fiscale             varchar2
  ,p_limite                  number
  )
IS
  select
    sum(tot_imp) as tot_imp,
    cod_fiscale
  from
    (
    select sum(importo) as tot_imp,
           cod_fiscale
      from ruoli_contribuente
     where ruolo               = p_ruolo
       and cod_fiscale      like p_cod_fiscale
     group by cod_fiscale
    union
    select sum(importo_ruolo) as tot_imp,
           cod_fiscale
      from ruoli_eccedenze
     where ruolo               = p_ruolo
       and cod_fiscale      like p_cod_fiscale
     group by cod_fiscale
    )
  group by cod_fiscale
  having sum(tot_imp)        < p_limite
  ;
--
--------------------------------------------
--
CURSOR sel_importo_zero
(p_ruolo                   number
) IS
select oggetto_imposta
      ,cod_fiscale
  from oggetti_imposta
 where ruolo               = p_ruolo
   and importo_ruolo      <= 0
   and imposta_dovuta     <= 0
;
--
--------------------------------------------
--
-- Emissione ruolo suppletivo (2)
--
CURSOR sel_ogpr_2
(p_ruolo                   number
,p_cod_fiscale             varchar2
,p_tipo_tributo            varchar2
,p_anno                    number
,p_data_emissione          date
,p_flag_normalizzato       varchar2
) IS
select ogpr.oggetto_pratica
      ,nvl(cotr.conto_corrente,titr.conto_corrente) conto_corrente
      ,prtr.tipo_tributo
      ,prtr.tipo_pratica
      ,prtr.flag_adesione
      ,prtr.data_notifica
      ,ogpr.tributo
      ,ogpr.categoria
      ,ogpr.consistenza
      ,ogpr.tipo_tariffa
      ,ogpr.tipo_occupazione
      ,ogpr.numero_familiari
      ,tari.tariffa
      ,tari.limite
      ,tari.tariffa_superiore
      ,tari.tariffa_quota_fissa
      ,nvl(tari.perc_riduzione,0)       perc_riduzione
      ,ogco.perc_possesso
      ,ogco.flag_ab_principale
      ,ogco.cod_fiscale
      ,ogva.oggetto_pratica_rif
      ,ogva.dal    inizio_decorrenza
      ,ogva.al     fine_decorrenza
      ,ogva.data   data_ogva
      ,prtr.tipo_evento
      ,f_get_tariffa_base(ogpr.tributo,ogpr.categoria,p_anno) tipo_tariffa_base
      ,ogco.flag_punto_raccolta
  from codici_tributo                   cotr
      ,tipi_tributo                     titr
      ,tariffe                          tari
      ,oggetti_contribuente             ogco
      ,oggetti_imposta                  ogim
      ,oggetti_pratica                  ogpr
      ,pratiche_tributo                 prtr
      ,oggetti_validita                 ogva
 where cotr.flag_ruolo                  is not null
   and cotr.tributo                      = ogpr.tributo
   and titr.tipo_tributo                 = cotr.tipo_tributo
   and tari.tipo_tariffa                 = ogpr.tipo_tariffa
   and tari.categoria                    = ogpr.categoria
   and tari.tributo                      = ogpr.tributo
   and tari.anno                         = p_anno
   and prtr.pratica                      = ogpr.pratica
   and nvl(prtr.stato_accertamento,'D')  = 'D'
   and ogva.tipo_occupazione             = 'P'
   and ogpr.flag_contenzioso            is null
   and ogpr.oggetto_pratica              = ogva.oggetto_pratica
   and ogco.oggetto_pratica              = ogva.oggetto_pratica
   and ogco.cod_fiscale                  = ogva.cod_fiscale
   and ogim.ruolo                   (+) is null
   and ogim.anno                    (+)  = p_anno
   and ogim.oggetto_pratica         (+)  = ogva.oggetto_pratica
   and ogim.cod_fiscale             (+)  = ogva.cod_fiscale
   and nvl(to_number(to_char(ogva.dal,'yyyy')),0)
                                        <= p_anno
   and nvl(to_number(to_char(ogva.al,'yyyy')),9999)
                                        >= p_anno
   and (    ogva.data                   <= p_data_emissione
        and decode(prtr.tipo_pratica||nvl(flag_adesione,'N')
                  ,'AN',prtr.data_notifica  + 60
                  ,'AS',prtr.data_notifica
                  ,ogva.data
                  )                    >
           (select nvl(max(data_emissione),ogva.data - 1)
              from ruoli
             where anno_ruolo            = p_anno
               and ruolo                <> p_ruolo
               and invio_consorzio      is not null
               and tipo_tributo          = p_tipo_tributo
               and specie_ruolo          = 0
           )
        or  p_flag_normalizzato          = 'S'
        and exists
           (select 1
              from familiari_soggetto    faso
                  ,contribuenti          cont
                  ,categorie             cate
             where cont.cod_fiscale      = ogva.cod_fiscale
               and cont.ni               = faso.ni
               and cate.tributo          = ogpr.tributo
               and cate.categoria        = ogpr.categoria
               and cate.flag_domestica   = 'S'
               and faso.anno             = p_anno
               and faso.data_variazione <= p_data_emissione
               and faso.data_variazione  >
                  (select nvl(max(data_emissione),faso.data_variazione - 1)
                     from ruoli
                    where anno_ruolo     = p_anno
                      and ruolo         <> p_ruolo
                      and invio_consorzio
                                        is not null
                      and tipo_tributo   = p_tipo_tributo
                      and specie_ruolo          = 0
                  )
           )
       )
    and ogva.tipo_tributo||''            = p_tipo_tributo
    and (    prtr.tipo_evento           in ('I','V')
-- Variazione fatta da D.M. il 09/12/2004
         or  prtr.tipo_evento            = 'U'
         and prtr.tipo_pratica           = 'A'
         and prtr.flag_denuncia          = 'S'
         and prtr.anno                   < p_anno
         and ( trunc(p_data_emissione) - nvl(prtr.data_notifica,trunc(p_data_emissione) + 1) >= decode(flag_adesione
                                                                                                  ,'S',0
                                                                                                  ,60
                                                                                                  )
               )
        )
    and ogva.cod_fiscale              like p_cod_fiscale
  order by
        ogva.oggetto_pratica_rif
       ,ogva.dal
;
--
--------------------------------------------
--
-- Emissione ruolo suppletivo (accertamenti)
CURSOR sel_ogpr_acce IS
select prtr.cod_fiscale
      ,prtr.pratica
      ,max(prtr.tipo_tributo) tipo_tributo
      ,decode(sanz.tributo,0,ogpr.tributo,sanz.tributo) tributo
      ,max(nvl(cotr.conto_corrente,titr.conto_corrente)) conto_corrente
--      ,f_round(sum(sapr.importo *
--                 decode(sanz.cod_sanzione
--                        ,'1',1,'101',1,'99',1,'199',1,'888',1,'889',1,
--                         decode(w_cod_istat,'036040',(100 + w_addizionale_pro) / 100,1)
--                        ) *
--               decode(prtr.flag_adesione,NULL,1,(100 - nvl(sanz.riduzione,0))/100))
--            , 1) importo
      ,sum(decode(decode(sapr.cod_sanzione,1,1,100,1,101,1,111,1,121,1,131,1,141,1,2)
                 ,1,decode(w_importo_lordo
                          ,'S',round(sapr.importo *
                                     decode(prtr.flag_adesione,null,1,(100 - nvl(sanz.riduzione,0)) / 100) *
                                     nvl(cata.addizionale_eca,0) / 100,2
                                    ) +
                               round(sapr.importo *
                                     decode(prtr.flag_adesione,null,1,(100 - nvl(sanz.riduzione,0)) / 100) *
                                     nvl(cata.maggiorazione_eca,0) / 100,2
                                    ) +
                               round(sapr.importo *
                                     decode(prtr.flag_adesione,null,1,(100 - nvl(sanz.riduzione,0)) / 100) *
                                     nvl(cata.addizionale_pro,0) / 100,2
                                    ) +
                               round(sapr.importo *
                                     decode(prtr.flag_adesione,null,1,(100 - nvl(sanz.riduzione,0)) / 100) *
                                     nvl(cata.aliquota,0) / 100,2
                                    ) +
                               round(sapr.importo *
                                     decode(prtr.flag_adesione,null,1,(100 - nvl(sanz.riduzione,0)) / 100),2
                                    )
                              ,round(sapr.importo *
                                     decode(prtr.flag_adesione,null,1,(100 - nvl(sanz.riduzione,0)) / 100),2
                                    )
                          )
                   ,round(sapr.importo *
                          decode(prtr.flag_adesione,null,1,(100 - nvl(sanz.riduzione,0)) / 100),2
                         )
                 )
          ) importo
  from codici_tributo                     cotr
      ,tipi_tributo                       titr
      ,carichi_tarsu                      cata
      ,sanzioni                           sanz
      ,sanzioni_pratica                   sapr
      ,oggetti_pratica                    ogpr
      ,pratiche_tributo                   prtr
 where cotr.tributo                       = ogpr.tributo
   and cotr.flag_ruolo                   is not null
   and titr.tipo_tributo                  = cotr.tipo_tributo
   and sanz.cod_sanzione                  = sapr.cod_sanzione
   and sanz.sequenza                      = sapr.sequenza_sanz
   and sanz.tipo_tributo                  = sapr.tipo_tributo
   and sapr.ruolo                        is null
   and sapr.pratica                       = prtr.pratica
   and ogpr.flag_contenzioso             is null
   and ogpr.pratica                       = prtr.pratica
   and (   prtr.flag_adesione            is not NULL
        or (w_data_emissione - nvl(prtr.data_notifica,w_data_emissione))
                                          > 60
       )
   and prtr.tipo_tributo||''              = w_tipo_tributo
   and prtr.tipo_pratica||''              = 'A'
   and nvl(prtr.stato_accertamento,'D')   = 'D'
   and ogpr.tipo_occupazione              = 'P'
   and prtr.anno                          = w_anno_ruolo
   and prtr.cod_fiscale                like a_cod_fiscale
   and sapr.cod_sanzione                 <>
       decode(prtr.flag_adesione,null,'889','888')
   and cata.anno                          = w_anno_ruolo
 group by
       prtr.cod_fiscale
      ,prtr.pratica
      ,decode(sanz.tributo,0,ogpr.tributo,sanz.tributo)
;
--
--------------------------------------------
-- Emissione ruolo suppletivo per variazione tariffa
--
CURSOR sel_ogpr_vt IS
-- In seguito alla richiesta di Corsico:
-- Non vengono presi in cosiderazione gli oggetti pratica
-- aventi una cessazione in corso d'anno.
select ruco.cod_fiscale
      ,ogpr.oggetto_pratica
      ,nvl(cotr.conto_corrente,titr.conto_corrente) conto_corrente
      ,prtr.tipo_tributo
      ,ogpr.tributo
      ,ogpr.categoria
      ,ogpr.tipo_tariffa
      ,ogpr.numero_familiari
      ,tari.tariffa
      ,tari.limite
      ,tari.tariffa_superiore
      ,tari.tariffa_quota_fissa
      ,ogco.perc_possesso
      ,ogco.flag_ab_principale
      ,ruco.consistenza
      ,ruco.mesi_ruolo
      ,ogim.imposta
      ,ogim.importo_pf
      ,ogim.importo_pv
      ,ogva.dal inizio_decorrenza
      ,ogva.al fine_decorrenza
      ,nvl(tari.perc_riduzione,0)       perc_riduzione
      ,ogco.flag_punto_raccolta
  from codici_tributo                      cotr
      ,tipi_tributo                        titr
      ,tariffe                             tari
      ,pratiche_tributo                    prtr
      ,oggetti_pratica                     ogpr
      ,oggetti_contribuente                ogco
      ,oggetti_imposta                     ogim
      ,ruoli_contribuente                  ruco
      ,ruoli                               ruol
      ,oggetti_validita                    ogva
 where cotr.flag_ruolo                    is not null
   and cotr.tributo                        = ogpr.tributo
   and titr.tipo_tributo                   = cotr.tipo_tributo
   and tari.tipo_tariffa                   = ogpr.tipo_tariffa
   and tari.categoria                      = ogpr.categoria
   and tari.tributo                        = ogpr.tributo
   and tari.anno                           = w_anno_ruolo
   and not exists
      (select 1
         from pratiche_tributo             prtr_cess
             ,oggetti_contribuente         ogco_cess
             ,oggetti_pratica              ogpr_cess
        where prtr_cess.tipo_evento        = 'C'
          and prtr_cess.tipo_pratica       = 'D'
          and prtr_cess.pratica            = ogpr_cess.pratica
          and nvl(to_number(to_char(ogco_cess.data_cessazione,'yyyy')),9999)
                                           = w_anno_ruolo
          and ogco_cess.oggetto_pratica    = ogpr_cess.oggetto_pratica
          and ogco_cess.cod_fiscale        = ogco.cod_fiscale
          and ogpr_cess.oggetto_pratica_rif
                                           =
              nvl(ogpr.oggetto_pratica_rif,ogpr.oggetto_pratica)
        and w_cod_istat not in ('058003' , '025006','082006') -- Belluno e Albano Laziale e Bagheria
      )
  and ogpr.oggetto_pratica                 = ogco.oggetto_pratica
  and ogco.oggetto_pratica                 = ogim.oggetto_pratica
  and ogco.cod_fiscale                     = ogim.cod_fiscale
  and prtr.pratica                         = ogpr.pratica
  and nvl(prtr.stato_accertamento,'D')     = 'D'
  and (    nvl(ruol.importo_lordo,'N')     = 'N'
       or  nvl(ruol.importo_lordo,'N')     = 'S'
       and prtr.tipo_pratica               = 'D'
      )
  and ogim.cod_fiscale                     = ruco.cod_fiscale
  and ogim.oggetto_imposta                 = ruco.oggetto_imposta
  and ruco.cod_fiscale                  like a_cod_fiscale
  and ruco.ruolo                           = w_ruolo_rif
  and ruol.ruolo                           = w_ruolo_rif
  and ogim.cod_fiscale                  = ogva.cod_fiscale
  and ogim.oggetto_pratica               = ogva.oggetto_pratica
;
--
--------------------------------------------
--
cursor sel_del_ogpr_vt is
select ogim.oggetto_imposta
  from oggetti_imposta             ogim
 where nvl(ruolo,a_ruolo)          = a_ruolo
   and flag_calcolo                = 'S'
   and anno                        = w_anno_ruolo
   and cod_fiscale              like a_cod_fiscale
   and exists
      (select 'x'
         from codici_tributo       cotr
             ,oggetti_pratica      ogpr
        where ogim.oggetto_pratica = ogpr.oggetto_pratica
          and cotr.tributo         = ogpr.tributo
          and cotr.tipo_tributo    = 'TARSU'
          and cotr.flag_ruolo     is not null
      )
;
--
--------------------------------------------
--
cursor sel_del_ogpr1(a_cod_fiscale     varchar2
                    ,a_oggetto_pratica number
                    ,a_ruolo           number
                    )
is
select oggetto_imposta
  from oggetti_imposta
 where oggetto_pratica    = a_oggetto_pratica
   and nvl(ruolo,a_ruolo) = a_ruolo
   and flag_calcolo       = 'S'
   and cod_fiscale        = a_cod_fiscale
;
--
--------------------------------------------
--
cursor sel_del_ogpr(a_cod_fiscale     varchar2
                   ,a_ruolo           number
                   )
is
select oggetto_imposta
  from oggetti_imposta
 where ruolo              = a_ruolo
   and flag_calcolo       = 'S'
   and cod_fiscale     like a_cod_fiscale
;
--
--------------------------------------------
--
-- Cursore che viene utilizzato per memorizzare provvisoriamente nei versamenti
-- su oggetto e/O rata imposta, l`oggetto pratica a cui si riferisce per dar modo
-- di potere riemettere il Ruolo anche in presenza di versamenti.
--
cursor sel_vers_ogpr
(a_anno                    number
,a_cod_fiscale             varchar2
,a_tipo_tributo            varchar2
,a_ruolo                   number
) is
select vers.sequenza
      ,vers.cod_fiscale
      ,vers.tipo_tributo
      ,vers.oggetto_imposta
      ,vers.anno
      ,ogim.oggetto_pratica
  from oggetti_imposta ogim
      ,versamenti      vers
 where ogim.oggetto_imposta       = vers.oggetto_imposta
   and ogim.ruolo                 = a_ruolo
   and ogim.flag_calcolo          = 'S'
   and vers.cod_fiscale        like a_cod_fiscale
   and vers.anno+0                = a_anno
   and vers.tipo_tributo          = a_tipo_tributo
 union all
select vers.sequenza
      ,vers.cod_fiscale
      ,vers.tipo_tributo
      ,vers.oggetto_imposta
      ,vers.anno
      ,ogim.oggetto_pratica
  from rate_imposta    raim
      ,oggetti_imposta ogim
      ,versamenti      vers
 where ogim.oggetto_imposta       = raim.oggetto_imposta
   and raim.rata_imposta          = vers.rata_imposta
   and ogim.ruolo                 = a_ruolo
   and ogim.flag_calcolo          = 'S'
   and vers.cod_fiscale        like a_cod_fiscale
   and vers.anno+0                = a_anno
   and vers.tipo_tributo          = a_tipo_tributo
;
--
--------------------------------------------
--
-- Cursore che permette, terminata la emissione, di riallacciare i versamenti
-- ai nuovi oggetti imposta degli oggetti pratica memorizzati (se ancora presenti).
--
cursor sel_vers
(a_anno                    number
,a_cod_fiscale             varchar2
,a_tipo_tributo            varchar2
,a_ruolo                   number
) is
select vers.cod_fiscale
      ,vers.anno
      ,vers.tipo_tributo
      ,vers.sequenza
      ,ogim.oggetto_imposta
      ,vers.rata
  from oggetti_imposta ogim
      ,versamenti      vers
 where ogim.oggetto_pratica (+)  = vers.ogpr_ogim
   and ogim.anno            (+)  = a_anno
   and ogim.ruolo           (+)  = a_ruolo
   and vers.ogpr_ogim           is not null
   and vers.cod_fiscale       like a_cod_fiscale
   and vers.tipo_tributo         = a_tipo_tributo
   and vers.anno+0               = a_anno
;
--
--------------------------------------------
--
-- (VD - 01/12/2014): Modificata query per trattare solo oggetti validi
--                    nell'anno per cui si sta emettendo il ruolo
-- (VD - 24/01/2018): Modificata query per trattare oggetti_pratica
--                    non piu presenti in oggetti_validita e non
--                    andati a ruolo a saldo.
-- (VD - 21/02/2018): Modificata query per trattare oggetti_pratica
--                    non piu presenti in oggetti_validita neanche
--                    come oggetto_pratica_rif e non andati a ruolo a saldo.
cursor sel_ruco_acc
(a_ruolo_acconto                 number
,a_ruolo                         number
,p_anno                          number
) is
/*select ruog_acc.cod_fiscale
     , ruog_acc.oggetto
     , ruog_acc.oggetto_pratica
     , (ruog_acc.imposta-nvl(sgra.importo,0)) importo_residuo
  from sgravi sgra, ruoli_oggetto ruog_acc
 where ruog_acc.ruolo = a_ruolo_acconto
   and ruog_acc.cod_fiscale like a_cod_fiscale
   and not exists (select 1
                     from oggetti_validita  ogva
                    where ogva.cod_fiscale = ruog_acc.cod_fiscale
                      and ogva.oggetto = ruog_acc.oggetto
                      and ogva.oggetto_pratica = ruog_acc.oggetto_pratica
                      and ogva.dal < to_date('3112'||p_anno,'ddmmyyyy')
                      and nvl(ogva.al,to_date('31122999','ddmmyyyy')) > to_date('0101'||p_anno,'ddmmyyyy')
                  )
   and not exists (select 1
                     from ruoli_oggetto ruog
                    where ruog.cod_fiscale = ruog_acc.cod_fiscale
                      and ruog.ruolo = a_ruolo
                      and ruog.oggetto_pratica = ruog_acc.oggetto_pratica
                  )
   and exists (select 1
                 from ruoli_oggetto ruog
                where ruog.cod_fiscale = ruog_acc.cod_fiscale
                  and ruog.ruolo = a_ruolo)
   and sgra.cod_fiscale (+) = ruog_acc.cod_fiscale
   and sgra.sequenza (+)    = ruog_acc.sequenza
   and sgra.ruolo (+)       = ruog_acc.ruolo
   and (ruog_acc.importo-nvl(sgra.importo,0)) > 0
;*/
select ruog_acc.cod_fiscale
     , ruog_acc.oggetto
     , ruog_acc.oggetto_pratica
     , (ruog_acc.imposta-nvl(sgra.importo,0)) importo_residuo
     , ruog_acc.imposta_base - nvl(sgra.importo_base,0) importo_residuo_base
  from sgravi sgra,
       ruoli_oggetto ruog_acc,
       oggetti_pratica ogpr
 where ruog_acc.ruolo = a_ruolo_acconto
   and ruog_acc.cod_fiscale like a_cod_fiscale
   and ruog_acc.oggetto_pratica = ogpr.oggetto_pratica
   and not exists (select 1
                     from oggetti_validita  ogva
                    where ogva.cod_fiscale = ruog_acc.cod_fiscale
                      and ogva.oggetto = ruog_acc.oggetto
                      and ogva.oggetto_pratica = ruog_acc.oggetto_pratica
                      and ogva.dal < to_date('3112'||p_anno,'ddmmyyyy')
                      and nvl(ogva.al,to_date('31122999','ddmmyyyy')) > to_date('0101'||p_anno,'ddmmyyyy')
                  )
   and not exists (select 1
                     from oggetti_validita  ogva
                    where ogva.cod_fiscale = ruog_acc.cod_fiscale
                      and ogva.oggetto = ruog_acc.oggetto
                      and ogva.oggetto_pratica_rif = nvl(ogpr.oggetto_pratica_rif,ruog_acc.oggetto_pratica)
                      and ogva.dal < to_date('3112'||p_anno,'ddmmyyyy')
                      and nvl(ogva.al,to_date('31122999','ddmmyyyy')) > to_date('0101'||p_anno,'ddmmyyyy')
                  )
--   and exists (select 1
--                 from ruoli_oggetto ruog
--                where ruog.cod_fiscale = ruog_acc.cod_fiscale
--                  and ruog.ruolo = a_ruolo
--              )
   and sgra.cod_fiscale (+) = ruog_acc.cod_fiscale
   and sgra.sequenza (+)    = ruog_acc.sequenza
   and sgra.ruolo (+)       = ruog_acc.ruolo
   and (ruog_acc.importo-nvl(sgra.importo,0)) > 0
;
CURSOR sel_cf_supp_totali(p_ruolo number, p_cod_fiscale varchar2)
IS
select
  cod_fiscale,
  sum(importo) as importo
from
  (
  select
     ruco.cod_fiscale,
     sum(ruco.importo) importo
    from ruoli_contribuente ruco
   where ruco.ruolo = p_ruolo
     and ruco.cod_fiscale like p_cod_fiscale
   group by
         ruco.cod_fiscale
  union
  select
     ruec.cod_fiscale,
     sum(ruec.importo_ruolo) importo
    from ruoli_eccedenze ruec
   where ruec.ruolo = p_ruolo
     and ruec.cod_fiscale like p_cod_fiscale
   group by
         ruec.cod_fiscale
  )
group by
      cod_fiscale
;
--
--------------------------------------------
--
FUNCTION f_iscritto
(w_anno                        number
,w_cf                          varchar2
,w_ogpr                        number
,w_ruolo                       number
) RETURN number IS
w_return                       number;
BEGIN
   select distinct 1
     into w_return
     from oggetti_imposta ogim
         ,oggetti_pratica ogpr
         ,oggetti_pratica ogp2
    where ogim.cod_fiscale        = w_cf
      and ogim.anno               = w_anno
      and nvl(ogpr.oggetto_pratica_rif,ogpr.oggetto_pratica)
                                  =
          nvl(ogp2.oggetto_pratica_rif,ogp2.oggetto_pratica)
      and ruolo                  is not null
      and ruolo                <> w_ruolo
      and ogpr.oggetto_pratica    = ogim.oggetto_pratica
      and ogp2.oggetto_pratica    = w_ogpr
   ;
   RETURN w_return;
EXCEPTION
   WHEN no_data_found THEN
      RETURN 0;
   WHEN others THEN
      RETURN -1;
END f_iscritto;
--
--------------------------------------------
--
FUNCTION f_tratta_rate
(a_rate               number
,a_anno_ruolo         number
,a_tipo_tributo       varchar2
,a_imp_add_eca        number
,a_imp_magg_eca       number
,a_imp_add_pro        number
,a_imp_magg_tares     number
,a_imp_aliq           number
,a_importo            number
,a_oggetto_imposta    number
,a_conto_corrente     varchar2
,a_cod_fiscale        varchar2
,a_utente             varchar2
,a_cod_istat          varchar2
,a_rata_perequative   varchar2 default null
)
Return number
/******************************************************************************
  NOME:        f_tratta_rate
  DESCRIZIONE: Emette rate_imposta da dati oggetto_imposta
  REVISIONI:
  Rev.  Data        Autore  Note
  ----  ----------  ------  ----------------------------------------------------
  001   28/01/2025  RV      #77805
                            Aggiunto gestione perequative spalmate sulle rate
  000   xx/xx/xxxx  XX      Versione originale
******************************************************************************/
is
w_rate                         number;
w_conta_rate                   number;
w_imp_rata                     number;
w_imp_add_pro_rata             number;
w_imp_add_eca_rata             number;
w_imp_mag_eca_rata             number;
w_imp_mag_tares_rata           number;
w_imp_ali_rata                 number;
w_tot_imp                      number;
w_tot_add_pro                  number;
w_tot_add_eca                  number;
w_tot_mag_eca                  number;
w_tot_mag_tares                number;
w_tot_ali                      number;
w_tot_imp_round                number;
w_imp_rata_round               number;
w_round                        varchar2(1);
w_importo_lordo                number;
cursor sel_scad(a_tipo_tributo varchar2
               ,a_anno_ruolo   number
               ,a_rate         number
               )
is
select 1  rata
  from dual
 where a_rate >= 1
 union
select 2   rata
  from dual
 where a_rate >= 2
 union
select 3  rata
  from dual
 where a_rate >= 3
 union
select 4  rata
  from dual
 where a_rate >= 4
 order by 1
;
BEGIN
  --
--dbms_output.put_line('Tratta Rate: '||a_flag_cope_rate||', cope: '||a_imp_magg_tares);
  --
   w_conta_rate := a_rate;
   w_rate       := a_rate;
   if w_conta_rate > 0 then
      w_tot_imp        := 0;
      w_tot_add_eca    := 0;
      w_tot_mag_eca    := 0;
      w_tot_mag_tares  := 0;
      w_tot_add_pro    := 0;
      w_tot_ali        := 0;
      w_tot_imp_round  := 0;
      w_imp_rata_round := null;
      w_importo_lordo  := a_importo + a_imp_add_eca + a_imp_magg_eca + a_imp_add_pro + a_imp_aliq + a_imp_magg_tares;
      --
      begin
        select decode(a_tipo_tributo
                      ,'TARSU',decode(a_cod_istat
                                     ,'037058',null     --Savigno
                                     ,'015175',null     --Pioltello   (trasmissione MAV)
                                     ,'012083',null     --Induno Olona
                                     ,'090049',null     --Oschiri
                                     ,'097049',null     --Missaglia
                                     ,'091055',null     --Oliena
                                     ,'042030',null     --Monte San Vito
                                     ,'S'   --flag_tariffa
                                     )
                      ,'ICP',flag_canone
                      ,'TOSAP',flag_canone
                      ,null)
          into w_round
          from tipi_tributo
         where tipo_tributo = a_tipo_tributo
            ;
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
         w_round := null;
      WHEN OTHERS THEN
         w_round := null;
      end;
      FOR rec_scad in sel_scad(a_tipo_tributo
                              ,a_anno_ruolo
                              ,a_rate
                              )
      LOOP
         if rec_scad.rata = w_rate then
            --
            -- Ultima rata
            --
            w_imp_add_eca_rata := a_imp_add_eca  - w_tot_add_eca;
            w_imp_mag_eca_rata := a_imp_magg_eca - w_tot_mag_eca;
            --
            if a_rata_perequative = 'T' then
              w_imp_mag_tares_rata := a_imp_magg_tares - w_tot_mag_tares;   --- Residuo di Sparpaglia su tutte le rate
            else
              if a_rata_perequative = 'U' then
                w_imp_mag_tares_rata := a_imp_magg_tares;                   --- Tutto su ultima rata
              else
                w_imp_mag_tares_rata := 0.0;                                --- Tutto su prima rata
              end if;
            end if;
            --
            w_imp_add_pro_rata := a_imp_add_pro  - w_tot_add_pro;
            w_imp_ali_rata     := a_imp_aliq     - w_tot_ali;
            w_imp_rata         := a_importo      - w_tot_imp;
            if w_round is null then
               if a_tipo_tributo = 'TARSU' and a_cod_istat in ('037058','015175','012083','090049','097049','091055','042030') then
                  w_imp_rata_round := round(w_importo_lordo,0) - w_tot_imp_round;
               else
                  w_imp_rata_round := round(a_importo,0) - w_tot_imp_round;
               end if;
            end if;
         else
            --
            -- Tutte le rate tranne l'ultima
            --
            w_imp_add_eca_rata := round(a_imp_add_eca  / w_rate,2);
            w_imp_mag_eca_rata := round(a_imp_magg_eca / w_rate,2);
            --
            if a_rata_perequative = 'T' then
              w_imp_mag_tares_rata := round(a_imp_magg_tares / w_rate,2);   -- Sparpaglia su tutte le rate
            else
              if a_rata_perequative = 'P' and rec_scad.rata = 1 then
                w_imp_mag_tares_rata := a_imp_magg_tares;                   -- Tutto su prima rata
              else
                w_imp_mag_tares_rata := 0;                                  -- Tutto su ultima rata
              end if;
            end if;
            --
            w_imp_add_pro_rata := round(a_imp_add_pro  / w_rate,2);
            w_imp_ali_rata     := round(a_imp_aliq     / w_rate,2);
            w_imp_rata         := round(a_importo      / w_rate,2);
            w_tot_add_eca      := w_tot_add_eca + w_imp_add_eca_rata;
            w_tot_mag_eca      := w_tot_mag_eca + w_imp_mag_eca_rata;
            w_tot_mag_tares    := w_tot_mag_tares + w_imp_mag_tares_rata;
            w_tot_add_pro      := w_tot_add_pro + w_imp_add_pro_rata;
            w_tot_ali          := w_tot_ali     + w_imp_ali_rata;
            w_tot_imp          := w_tot_imp     + w_imp_rata;
            if w_round is null then
               if a_tipo_tributo = 'TARSU' and a_cod_istat in ('037058','015175','012083','090049','097049','091055','042030') then
                  w_imp_rata_round := round(w_importo_lordo / w_rate,0);
                  w_tot_imp_round  := w_tot_imp_round + w_imp_rata_round;
               else
                  w_imp_rata_round := round(a_importo / w_rate,0);
                  w_tot_imp_round  := w_tot_imp_round + w_imp_rata_round;
               end if;
            end if;
         end if;
         insert into rate_imposta
               (rata_imposta,anno,cod_fiscale,tipo_tributo,rata,
                oggetto_imposta,imposta,conto_corrente,utente,note,
                num_bollettino,addizionale_eca,maggiorazione_eca,
                addizionale_pro,iva,imposta_round,
                maggiorazione_tares
               )
         values(null,a_anno_ruolo,a_cod_fiscale,a_tipo_tributo,rec_scad.rata,
                a_oggetto_imposta,w_imp_rata,a_conto_corrente,a_utente,null,
                null,w_imp_add_eca_rata,w_imp_mag_eca_rata,
                w_imp_add_pro_rata,w_imp_ali_rata,w_imp_rata_round,
                w_imp_mag_tares_rata
               )
         ;
      END LOOP;
   end if;
   Return 0;
END f_tratta_rate;
--
----------------------------------
-- f_dovuto_eccedenze
--  Determina dovuto eccedenze
----------------------------------
FUNCTION f_dovuto_eccedenze
  ( p_cf                          varchar2
  , p_ruolo                       number
  , p_imposta                     IN OUT number
  , p_add_prov                    IN OUT number
  )
RETURN number
IS
  w_return                       number;
BEGIN
  select
    sum(ruec.importo_ruolo) as importo_ruolo,
    sum(nvl(ruec.imposta,0)) as imposta,
    sum(nvl(ruec.addizionale_pro,0)) as add_prov
    into
      w_return,
      p_imposta,
      p_add_prov
    from ruoli_eccedenze ruec
   where ruec.ruolo = p_ruolo
     and ruec.cod_fiscale = p_cf
  ;
  --
  RETURN w_return;
  --
EXCEPTION
   WHEN no_data_found THEN
      p_imposta := 0;
      p_add_prov := 0;
      RETURN 0;
   WHEN others THEN
      p_imposta := null;
      p_add_prov := null;
      RETURN 0;
END f_dovuto_eccedenze;
--
--------------------------------------------
--
procedure applica_sconto_conf
( p_anno             in      number
, p_ruolo            in      number
, p_tipo_limite      in      varchar2
, p_limite_ruolo     in      number
, p_rate             in      number
, p_cod_fiscale      in      varchar2
)
is
--
-- (VD - 23/10/2018): Modifiche per gestione importi calcolati con
--                    tariffa base
--
  w_imp_scalato                number;
  w_tot_scalato                number;
  w_imp_scalato_base           number;
  w_tot_scalato_base           number;
  w_sconto                     number;
  w_sconto_base                number;
  w_imp_maggiorazione_tares    number;       -- Per la gestione delle perquative
begin
  for cont in (select cod_fiscale
                    , tipo_utenza
                    , sum(importo_calcolato) importo_calcolato
                 from CONFERIMENTI_CER_RUOLO
                where cod_fiscale like p_cod_fiscale
                  and ruolo = p_ruolo
                group by cod_fiscale,tipo_utenza
                order by cod_fiscale,tipo_utenza)
  loop
    w_imp_scalato      := cont.importo_calcolato;
    w_imp_scalato_base := cont.importo_calcolato;
    w_tot_scalato      := 0;
    w_tot_scalato_base := 0;
    --
    for ruco in (select decode(cont.tipo_utenza,
                               'D',decode(nvl(ogco.flag_ab_principale,'N'),'S',0,1)
                                  ,0) flag_ab_princ
                      , ogim.importo_pv
                      , ogim.importo_pf
                      , ogim.importo_pv_base
                      , ogim.importo_pf_base
                      , ogim.oggetto_imposta
                      , ogim.maggiorazione_tares
                      , nvl(cotr.conto_corrente,titr.conto_corrente) conto_corrente
                   from oggetti_imposta      ogim
                      , oggetti_pratica      ogpr
                      , oggetti_contribuente ogco
                      , oggetti              ogge
                      , categorie            cate
                      , tipi_tributo         titr
                      , codici_tributo       cotr
                  where ogim.ruolo = p_ruolo
                    and ogim.cod_fiscale = cont.cod_fiscale
                    and ogim.flag_calcolo = 'S'
                    and ogim.oggetto_pratica = ogpr.oggetto_pratica
                    and ogpr.oggetto_pratica = ogco.oggetto_pratica
                    and ogpr.oggetto         = ogge.oggetto
                    and ogpr.tributo         = cate.tributo
                    and ogpr.categoria = cate.categoria
                    and ((cont.tipo_utenza = 'D' and nvl(cate.flag_domestica,'N') = 'S') or
                         (cont.tipo_utenza = 'N' and nvl(cate.flag_domestica,'N') <> 'S'))
                    and titr.tipo_tributo = w_tipo_tributo
                    and titr.tipo_tributo = cotr.tipo_tributo
                    and cotr.flag_ruolo is not null
                    and cotr.tributo = ogpr.tributo
                  order by 1,2 desc,3)
    loop
      w_sconto        := least(ruco.importo_pv,w_imp_scalato);
      w_imp_scalato := w_imp_scalato - w_sconto;
      w_tot_scalato := w_tot_scalato + w_sconto;
      w_sconto_base      := least(ruco.importo_pv_base,w_imp_scalato_base);
      w_imp_scalato_base := w_imp_scalato_base - w_sconto_base;
      w_tot_scalato_base := w_tot_scalato_base + w_sconto_base;
      --
      if w_sconto > 0 then
         w_importo_pv            := ruco.importo_pv - w_sconto;
         w_importo               := ruco.importo_pf + w_importo_pv;
         w_imp_addizionale_pro   := f_round(w_importo * w_addizionale_pro / 100,1);
         w_imp_addizionale_eca   := f_round(w_importo * w_addizionale_eca / 100,1);
         w_imp_maggiorazione_eca := f_round(w_importo * w_maggiorazione_eca / 100,1);
         w_imp_aliquota          := f_round(w_importo * w_aliquota / 100,1);
         w_importo_ruolo         := w_importo + w_imp_addizionale_pro + w_imp_addizionale_eca +
                                    w_imp_maggiorazione_eca + w_imp_aliquota;
         if w_sconto_base > 0 then
            w_importo_pv_base    := ruco.importo_pv_base - w_sconto_base;
            w_importo_base       := ruco.importo_pf_base + w_importo_pv_base;
            w_imp_add_pro_base   := f_round(w_importo_base * w_addizionale_pro / 100,1);
            w_imp_add_eca_base   := f_round(w_importo_base * w_addizionale_eca / 100,1);
            w_imp_magg_eca_base  := f_round(w_importo_base * w_maggiorazione_eca / 100,1);
            w_imp_aliquota_base  := f_round(w_importo_base * w_aliquota / 100,1);
            w_importo_ruolo_base := w_importo_base + w_imp_add_pro_base + w_imp_add_eca_base +
                                    w_imp_magg_eca_base + w_imp_aliquota_base;
         end if;
         --
         w_imp_maggiorazione_tares := ruco.maggiorazione_tares;         -- Recupera le perequative
         --
         -- Se l'importo ricalcolato è inferiore all'importo limite per oggetto,
         -- si annullano i riferimenti su oggetti_imposta e si eliminano i
         -- ruoli_contribuente (?)
         --
         if w_importo < nvl(p_limite_ruolo,0)
            and nvl(p_tipo_limite,' ') = 'O' then
            BEGIN
              update oggetti_imposta
                 set ruolo                = null
                    ,importo_ruolo        = null
                    ,addizionale_eca      = null
                    ,maggiorazione_eca    = null
                    ,addizionale_pro      = null
                    ,iva                  = null
               where ruolo = a_ruolo
                 and oggetto_imposta      = ruco.oggetto_imposta
              ;
            EXCEPTION
              WHEN others THEN
                 w_errore := 'Errore in aggiornamento Oggetti Imposta '||
                             'per '||w_cod_fiscale||' - ('||SQLERRM||')';
                 RAISE errore;
            END;
            begin
              delete from ruoli_contribuente
               where ruolo = p_ruolo
                 and cod_fiscale = cont.cod_fiscale
                 and oggetto_imposta = ruco.oggetto_imposta
              ;
            exception
              WHEN others THEN
                 w_errore := 'Errore in eliminazione Ruoli contribuente '||
                             'per '||w_cod_fiscale||' - ('||SQLERRM||')';
                 RAISE errore;
            END;
         ELSE
            --
            -- Oggetti_imposta: aggiornamento importi e riga di note per sconto conferimenti
            --
            begin
              update oggetti_imposta
                 set imposta           = w_importo
                   , importo_pv        = w_importo_pv
                   , addizionale_pro   = w_imp_addizionale_pro
                   , addizionale_eca   = w_imp_addizionale_eca
                   , maggiorazione_eca = w_imp_maggiorazione_eca
                   , iva               = w_imp_aliquota
                   , importo_ruolo     = w_importo_ruolo
                   , dettaglio_ogim    = dettaglio_ogim||rpad(' Sconti per conferimento su QV ',53)||
                                         lpad(nvl(translate(ltrim(to_char(w_sconto,'99,999,990.00')),'.,',',.'),' '),13,' ')
                   , imposta_base           = w_importo_base
                   , importo_pv_base        = w_importo_pv_base
                   , addizionale_pro_base   = w_imp_add_pro_base
                   , addizionale_eca_base   = w_imp_add_eca_base
                   , maggiorazione_eca_base = w_imp_magg_eca_base
                   , iva_base               = w_imp_aliquota_base
                   , importo_ruolo_base     = w_importo_ruolo_base
                   , dettaglio_ogim_base    = dettaglio_ogim_base||rpad(' Sconti per conferimento su QV ',53)||
                                              lpad(nvl(translate(ltrim(to_char(w_sconto,'99,999,990.00')),'.,',',.'),' '),13,' ')
               where oggetto_imposta = ruco.oggetto_imposta;
            exception
               when others then
                  w_errore := 'Errore in aggiornamento oggetti imposta (sconto conf.) '||
                              'per '||cont.cod_fiscale||' - ('||sqlerrm||')';
                  raise errore;
            end;
            --
            -- Ruoli_contribuente: aggiornamento importo ruolo per sconto conferimenti
            --
            begin
              update ruoli_contribuente
                 set importo = w_importo_ruolo
                   , importo_base = w_importo_ruolo_base
               where ruolo = p_ruolo
                 and cod_fiscale = cont.cod_fiscale
                 and oggetto_imposta = ruco.oggetto_imposta;
            exception
               when others then
                  w_errore := 'Errore in aggiornamento ruoli contribuente (sconto conf.) '||
                              'per '||cont.cod_fiscale||' - ('||sqlerrm||')';
                  raise errore;
            end;
            if p_rate > 0 then
               begin
                 delete rate_imposta
                  where cod_fiscale = cont.cod_fiscale
                    and anno = p_anno
                    and tipo_tributo = w_tipo_tributo
                    and oggetto_imposta = ruco.oggetto_imposta;
               exception
                  when others then
                     w_errore := 'Errore in eliminazione rate imposta (sconto conf.) '||
                                 'per '||cont.cod_fiscale||' - ('||sqlerrm||')';
                     raise errore;
               end;
               if f_tratta_rate(p_rate
                               ,p_anno
                               ,w_tipo_tributo
                               ,w_imp_addizionale_eca
                               ,w_imp_maggiorazione_eca
                               ,w_imp_addizionale_pro
                               ,w_imp_maggiorazione_tares
                               ,w_imp_aliquota
                               ,w_importo
                               ,ruco.oggetto_imposta
                               ,ruco.conto_corrente
                               ,cont.cod_fiscale
                               ,a_utente
                               ,w_cod_istat
                               ,w_rata_perequative
                               ) = -1 then
                  w_errore := 'Errore in determinazione numero rate (1) '||
                              'per '||w_cod_fiscale||' - ('||SQLERRM||')';
                  RAISE errore;
               end if;
            end if;
         end if;
      end if;
    end loop;
    --
    -- Dopo aver scalato i conferimenti, si aggiornano le relative righe
    -- con l'importo effettivamente scalato
    --
    for conf in (select coce.data_conferimento
                      , coce.importo_calcolato
                      , coce.rowid
                   from CONFERIMENTI_CER_RUOLO coce
                  where coce.cod_fiscale = cont.cod_fiscale
                    and coce.tipo_utenza = cont.tipo_utenza
                    and coce.ruolo = p_ruolo
               order by 1)
    loop
      w_sconto := least (conf.importo_calcolato, w_tot_scalato);
      w_tot_scalato := w_tot_scalato - w_sconto;
      --
      -- Si aggiorna l'importo effettivamente scalato per il ruolo
      --
      begin
        update conferimenti_cer_ruolo
           set importo_scalato = w_sconto
         where rowid = conf.rowid;
      exception
        when others then
          w_errore := 'Errore in aggiornamento Oggetti Imposta per '||
                      w_cod_fiscale|| ' - ('|| sqlerrm|| ')';
          raise errore;
      end;
    end loop;
  end loop;
end;
----------------------------------
-- E M I S S I O N E   R U O L O
----------------------------------
BEGIN
   -- (VD - 24/10/2018): aggiunta selezione parametro flag_calcolo_tariffa_base
   --                    da tabella ruoli (per ruoli calcolati anche con
   --                    tariffa base
   -- (VD - 04/01/2019): aggiunta selezione parametro flag_ruolo_tariffe per
   --                    ruoli calcolati con tariffe (e non con coefficienti)
   BEGIN
      w_limite_ruolo := nvl(a_limite,0);
      select r.tipo_tributo
            ,r.tipo_ruolo
            ,r.anno_ruolo
            ,r.anno_emissione
            ,r.progr_emissione
            ,r.invio_consorzio
            ,r.data_emissione
            ,r.ruolo_rif
            ,lpad(to_char(d.pro_cliente),3,'0')||
             lpad(to_char(d.com_cliente),3,'0')
            ,r.importo_lordo
            ,nvl(r.rate,0)
            ,r.tipo_emissione
            ,nvl(r.flag_calcolo_tariffa_base,'N')
            ,nvl(r.flag_tariffe_ruolo,'N')
            ,nvl(r.flag_depag,'N')
            ,perc_acconto
        into w_tipo_tributo
            ,w_tipo_ruolo
            ,w_anno_ruolo
            ,w_anno_emissione
            ,w_progr_emissione
            ,w_invio_consorzio
            ,w_data_emissione
            ,w_ruolo_rif
            ,w_cod_istat
            ,w_importo_lordo
            ,w_rate
            ,w_tipo_emissione
            ,w_flag_tariffa_base
            ,w_flag_ruolo_tariffa
            ,w_pagonline
            ,w_perc_acconto
        from ruoli                   r
            ,dati_generali           d
       where r.ruolo                 = a_ruolo
         and d.chiave                = 1
      ;
   EXCEPTION
      WHEN no_data_found THEN
         w_errore := 'Ruolo non presente in tabella o Dati Generali non inseriti';
         RAISE errore;
      WHEN others THEN
         w_errore := 'Errore in ricerca Ruoli o Dati Generali';
         RAISE errore;
   END;
   IF w_invio_consorzio is not null THEN
      w_errore := 'Emissione non consentita: Ruolo gia'' inviato al Consorzio';
      RAISE errore;
   END IF;
   BEGIN
      select nvl(addizionale_pro,0)
            ,nvl(addizionale_eca,0)
            ,nvl(maggiorazione_eca,0)
            ,nvl(aliquota,0)
            ,iva_fattura
            ,maggiorazione_tares
            ,nvl(mesi_calcolo,2)
            ,flag_magg_anno
            --,tariffa_domestica
            --,tariffa_non_domestica
            ,rata_perequative
            ,flag_tariffa_puntuale
        into w_addizionale_pro
            ,w_addizionale_eca
            ,w_maggiorazione_eca
            ,w_aliquota
            ,w_aliquota_iva
            ,w_maggiorazione_tares
            ,w_mesi_calcolo
            ,w_flag_magg_anno
            --,w_tariffa_domestica
            --,w_tariffa_non_domestica
            ,w_rata_perequative
            ,w_tariffa_puntuale
        from carichi_tarsu
       where anno              = w_anno_ruolo
      ;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         w_addizionale_pro    := 0;
         w_addizionale_eca    := 0;
         w_maggiorazione_eca  := 0;
         w_aliquota           := 0;
         w_aliquota_iva       := null;
         w_flag_magg_anno     := null;
         w_rata_perequative   := null;
         w_tariffa_puntuale   := null;
      WHEN others THEN
         w_errore := 'Errore in ricerca Carichi Tarsu';
         RAISE errore;
   END;
   if w_rata_perequative is null then
     w_rata_perequative := 'T';          -- Default su "Tutte"
   end if;
   BEGIN
      select sum(importo)
        into w_magg_tares_cope
        from componenti_perequative
       where anno              = w_anno_ruolo
      ;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         null;
      WHEN others THEN
         w_errore := 'Errore in ricerca Componenti Perequative';
         RAISE errore;
   END;
   if nvl(w_importo_lordo,'N') = 'N' then
      w_addizionale_pro       := 0;
      w_addizionale_eca       := 0;
      w_maggiorazione_eca     := 0;
      w_aliquota              := 0;
   end if;
-- Questo controllo serve per verificare se si viene da PB (Power Buider) oppure da SQL.
-- Se si viene da PB significa che e` gia` stata eseguita con successo la procedure
-- TARIFFE_CHK, mentre se si viene da SQL si esegue il loop per verificare se esistono
-- o meno tariffe non caricate per l`anno ruolo richiesto.
   BEGIN
      IF nvl(a_flag_richiamo,'XX') != 'PB' THEN
         /*FOR rec_tari IN TR4PACKAGE.sel_tari(w_tipo_tributo, w_anno_ruolo, a_cod_fiscale,w_flag_tariffa_base) LOOP
            w_tariffe := nvl(w_tariffe,' ')||' '||rec_tari.tributo||
                         ' '||rec_tari.categoria||' '||rec_tari.tipo_tariffa||' ';
         END LOOP; */
         -- (VD - 13/03/2019): modificato metodo di controllo: ora usa lo stesso
         --                    utilizzato in PB
         tariffe_chk(w_tipo_tributo, w_anno_ruolo, a_cod_fiscale, a_flag_normalizzato
                    ,w_flag_tariffa_base, w_flag_ruolo_tariffa, w_rc);
         loop
           fetch w_rc into w_rec_taer;
           if w_rc%NOTFOUND then
              exit;
           else
              w_tariffe := w_tariffe||' '||w_rec_taer.tributo||' '||
                           w_rec_taer.categoria||' '||w_rec_taer.tipo_tariffa||' ';
           end if;
         end loop;
         close w_rc;
         IF rtrim(w_tariffe,' ') is not null THEN
            w_errore := 'Errore in ricerca Tariffe per l''anno: '||w_anno_ruolo;
            RAISE errore;
         END IF;
         if w_flag_tariffa_base = 'S' then
            null;
         end if;
      END IF;
   END;
--
-- La seguente fase memorizza gli oggetti pratica sui versamenti con oggetto imposta.
--
   FOR rec_vers_ogpr in sel_vers_ogpr (w_anno_ruolo
                                      ,a_cod_fiscale
                                      ,w_tipo_tributo
                                      ,a_ruolo
                                      )
   LOOP
      BEGIN
         update versamenti vers
            set vers.ogpr_ogim       = rec_vers_ogpr.oggetto_pratica
               ,vers.oggetto_imposta = null
               ,vers.rata_imposta    = null
          where vers.cod_fiscale     = rec_vers_ogpr.cod_fiscale
            and vers.anno            = rec_vers_ogpr.anno
            and vers.tipo_tributo    = rec_vers_ogpr.tipo_tributo
            and vers.sequenza        = rec_vers_ogpr.sequenza
         ;
      EXCEPTION
        WHEN others THEN
           w_errore := 'Errore in Aggiornamento Versamenti (Memorizzazione Oggetto Pratica)'
                       ||' di '||rec_vers_ogpr.cod_fiscale||' '||'('||SQLERRM||')';
           RAISE ERRORE;
      END;
   END LOOP;
   --
   -- Pulizia preparatoria al calcolo
   --
   BEGIN
      delete ruoli_contribuente
       where ruolo            = a_ruolo
         and cod_fiscale   like a_cod_fiscale
      ;
   EXCEPTION
      WHEN others THEN
         w_errore := 'Errore in eliminazione Ruoli Contribuente '||
                     '('||SQLERRM||')';
         RAISE errore;
   END;
   BEGIN
      delete ruoli_eccedenze
       where ruolo            = a_ruolo
         and cod_fiscale   like a_cod_fiscale
      ;
   EXCEPTION
      WHEN others THEN
         w_errore := 'Errore in eliminazione Ruoli Eccedenze '||
                     '('||SQLERRM||')';
         RAISE errore;
   END;
   BEGIN
      update sanzioni_pratica
         set ruolo            = null
            ,importo_ruolo    = null
       where ruolo            = a_ruolo
         and pratica         in
            (select pratica
               from pratiche_tributo prtr
              where prtr.cod_fiscale
                              like a_cod_fiscale
            )
      ;
   EXCEPTION
      WHEN others THEN
         w_errore := 'Errore in Aggiornamento Oggetti Imposta '||
                     '('||SQLERRM||')';
         RAISE errore;
   END;
   --
   ------------------------------------
   ---- Emissione ruolo principale ----
   ------------------------------------
   IF w_tipo_ruolo = 1 THEN
    --dbms_output.put_line('Ruolo Principale');
      FOR rec_del_ogpr in sel_del_ogpr(a_cod_fiscale
                                      ,a_ruolo
                                      )
      LOOP
         -- delete solo degli oggetti imposta e familiari_ogim relativi al
         -- Ruolo selezionato
         -- cotr.flag_ruolo is not null.
         BEGIN
            delete familiari_ogim faog
             where oggetto_imposta = rec_del_ogpr.oggetto_imposta
            ;
         EXCEPTION
            WHEN others THEN
               w_errore := 'Errore in eliminazione familiari_ogim '||
                           'per Ogim'||to_char(rec_del_ogpr.oggetto_imposta)||' - ('||SQLERRM||')';
               RAISE errore;
         END;
         BEGIN
            delete oggetti_imposta ogim
             where oggetto_imposta = rec_del_ogpr.oggetto_imposta
            ;
         EXCEPTION
            WHEN others THEN
               w_errore := 'Errore in eliminazione Oggetti Imposta '||
                           'per Ogim '||to_char(rec_del_ogpr.oggetto_imposta)||' - ('||SQLERRM||')';
               RAISE errore;
         END;
      END LOOP;
      -- Il flag_incentivo mi indica che non ho ancora applicato l'incentivo TARSU
      w_flag_incentivo:= 'N';
      --
      -- (VD - 21/02/2018): sostituito cursore sel_ogpr_validi del package
      --                    TR4PACKAGE con nuovo cursore esplicito presente
      --                    nella procedure per modifica ordinamento dati.
      --
      FOR rec_ogpr IN sel_ogpr_validi    --TR4PACKAGE.sel_ogpr_validi
                      (w_anno_ruolo
                      ,a_cod_fiscale
                      ,w_tipo_tributo
                      ,'P'
                      ,w_data_emissione
                      )
      LOOP
--dbms_output.put_line('Oggetto: '||rec_ogpr.oggetto||', Oggetto pratica: '||rec_ogpr.oggetto_pratica||', Oggetto pratica rif.: '||rec_ogpr.oggetto_pratica_rif);
         --if w_cod_fiscale_magg <> rec_ogpr.cod_fiscale then
         --   Oggetti_tab.DELETE;
         --   w_cod_fiscale_magg := rec_ogpr.cod_fiscale;
         --end if;
         w_data_cessazione := rec_ogpr.data_cessazione;
         w_da_trattare := TRUE;
         -- Personalizzazione Malnate
         if w_cod_istat = '012096' and w_tipo_tributo = 'TARSU' and w_anno_ruolo = 2006 and w_progr_emissione = 1 then
            if nvl(rec_ogpr.data_cessazione,to_date('31122006','ddmmyyyy')) > to_date('30062006','ddmmyyyy') then
               w_data_cessazione := to_date('30062006','ddmmyyyy');
            else
               w_data_cessazione := rec_ogpr.data_cessazione;
            end if;
            if nvl(rec_ogpr.data_decorrenza,to_date('01012006','ddmmyyyy')) > to_date('30062006','ddmmyyyy') then
               w_da_trattare := FALSE;
            else
               w_da_trattare := TRUE;
            end if;
         end if;
        -- Bovezzo calcolo semestrale primo semestre
         if w_cod_istat = '017025' and w_tipo_tributo = 'TARSU' and w_anno_ruolo > 2007 and w_progr_emissione = 1 then
            if nvl(rec_ogpr.data_cessazione,to_date('3112'||to_char(w_anno_ruolo),'ddmmyyyy')) > to_date('3006'||to_char(w_anno_ruolo),'ddmmyyyy') then
               w_data_cessazione := to_date('3006'||to_char(w_anno_ruolo),'ddmmyyyy');
            else
               w_data_cessazione := rec_ogpr.data_cessazione;
            end if;
            if nvl(rec_ogpr.data_decorrenza,to_date('0101'||to_char(w_anno_ruolo),'ddmmyyyy')) > to_date('3006'||to_char(w_anno_ruolo),'ddmmyyyy') then
               w_da_trattare := FALSE;
            else
               w_da_trattare := TRUE;
            end if;
         end if;
         if w_da_trattare then  -- se non è da trattare passo al prossimo oggetto
          -- Il flag_incentivo mi indica che non ho ancora applicato l'incentivo TARSU
          --  if w_cod_fiscale <> '(1) - '||rec_ogpr.cod_fiscale then
          --     w_flag_incentivo:= 'N';
          --  end if;
          --  w_cod_fiscale := '(1) - '||rec_ogpr.cod_fiscale;
            IF rec_ogpr.flag_ruolo is not null THEN
              IF a_flag_iscritti_p = 'S' THEN
              -- Si considerano tutti i contribuenti
                 w_chk_iscritto := 0;
              ELSE
              -- Si considerano solo quelli non iscritti in altro ruolo
                 w_chk_iscritto :=
                 f_iscritto(w_anno_ruolo,rec_ogpr.cod_fiscale,rec_ogpr.oggetto_pratica,a_ruolo);
              END IF;
              IF w_chk_iscritto = 0  THEN
                 if w_cod_fiscale_magg <> rec_ogpr.cod_fiscale then
                    Oggetti_tab.DELETE;
                    w_cod_fiscale_magg := rec_ogpr.cod_fiscale;
                    -- Il flag_incentivo mi indica che non ho ancora applicato l'incentivo TARSU
                    w_flag_incentivo:= 'N';
                    w_cod_fiscale := '(1) - '||rec_ogpr.cod_fiscale;
                 end if;
                 FOR rec_del_ogpr1 in sel_del_ogpr1(rec_ogpr.cod_fiscale
                                                   ,rec_ogpr.oggetto_pratica
                                                   ,a_ruolo
                                                   )
                 LOOP
                    BEGIN
                       delete familiari_ogim             faog
                        where oggetto_imposta             = rec_del_ogpr1.oggetto_imposta
                       ;
                    EXCEPTION
                       WHEN others THEN
                          w_errore := 'Errore in eliminazione familiari_ogim '||
                                      'per '||w_cod_fiscale||' - ('||SQLERRM||')';
                          RAISE errore;
                    END;
                    BEGIN
                       delete oggetti_imposta             ogim
                        where oggetto_imposta             = rec_del_ogpr1.oggetto_imposta
                       ;
                    EXCEPTION
                       WHEN others THEN
                          w_errore := 'Errore in eliminazione Oggetti Imposta '||
                                      'per '||w_cod_fiscale||' - ('||SQLERRM||')';
                          RAISE errore;
                    END;
                 END LOOP;
                 w_importo := 0;
                 w_importo_pf := null;
                 w_importo_pv := null;
                 w_stringa_familiari   := '';
                 w_dettaglio_ogim      := '';
                 w_dettaglio_faog      := '';
                 w_dettaglio_ogim_base := '';
                 w_dettaglio_faog_base := '';
                 if  w_cod_istat ='037054' then -- San lazzaro
                    -- Il periodo viene calcolato sempre come normalizzato,
                    -- in questo modo può essere anche a giorni
                     w_periodo := f_periodo(w_anno_ruolo
                                           ,rec_ogpr.data_decorrenza
                                           ,w_data_cessazione    --rec_ogpr.data_cessazione
                                           ,'P'
                                           ,w_tipo_tributo
                                           ,'S'  -- flag_normalizzato
                                           );
                     w_giorni_ruolo := least(nvl(rec_ogpr.data_cessazione,to_date('3333333','j')),to_date('3112'||lpad(to_char(w_anno_ruolo),4,'0'),'ddmmyyyy'))
                                     - greatest(nvl(rec_ogpr.data_decorrenza,to_date('2222222','j')),to_date('0101'||lpad(to_char(w_anno_ruolo),4,'0'),'ddmmyyyy'))
                                     + 1;
                 else
                     w_periodo := f_periodo(w_anno_ruolo
                                           ,rec_ogpr.data_decorrenza
                                           ,w_data_cessazione    --rec_ogpr.data_cessazione
                                           ,'P'
                                           ,w_tipo_tributo
                                           ,a_flag_normalizzato
                                           );
                 end if;
                 w_da_mese_ruolo := to_number(to_char(
                                          greatest(
                                            nvl(rec_ogpr.data_decorrenza
                                               ,to_date('0101'||to_char(w_anno_ruolo),'ddmmyyyy'))
                                                  ,to_date('0101'||to_char(w_anno_ruolo),'ddmmyyyy'))
                                                       ,'mm'));
                 if a_flag_normalizzato is not null
                 and rec_ogpr.data_decorrenza is not null
                 and to_number(to_char(rec_ogpr.data_decorrenza,'yyyy')) = w_anno_ruolo then
                     if to_number(to_char(rec_ogpr.data_decorrenza,'dd')) > 15 and
                        -- (VD - 19/06/2017): Corretto calcolo da_mese ruolo per mese = 12
                        w_da_mese_ruolo < 12 then
                        w_da_mese_ruolo  := w_da_mese_ruolo + 1;
                     end if;
                 end if;
                 w_a_mese_ruolo   := greatest(least((w_da_mese_ruolo + (w_periodo*12) - 1),12)  -- 12/11/2013 AB e PM
                                             ,w_da_mese_ruolo);-- 05/02/2015 Betta T.
                 --  w_da_mese_ruolo  := to_number(to_char(
                 --                          greatest(
                 --                            nvl(rec_ogpr.data_decorrenza
                 --                               ,to_date('0101'||to_char(w_anno_ruolo),'ddmmyyyy'))
                 --                                  ,to_date('0101'||to_char(w_anno_ruolo),'ddmmyyyy'))
                 --                                       ,'mm'));
                 --
                 --  w_a_mese_ruolo   := to_number(to_char(
                 --                         least(
                 --                            nvl(w_data_cessazione
                 --                               ,to_date('3112'||to_char(w_anno_ruolo),'ddmmyyyy'))
                 --                              ,to_date('3112'||to_char(w_anno_ruolo),'ddmmyyyy'))
                 --                                       ,'mm'));
                 --
                 IF a_flag_normalizzato is null THEN
                    IF rec_ogpr.consistenza < rec_ogpr.limite
                    or rec_ogpr.limite is NULL THEN
                       w_importo := rec_ogpr.consistenza * rec_ogpr.tariffa;
                    ELSE
                       w_importo := rec_ogpr.limite * rec_ogpr.tariffa +
                                    (rec_ogpr.consistenza - rec_ogpr.limite)
                                    * rec_ogpr.tariffa_superiore;
                    END IF;
                    w_importo := f_round(w_importo * (nvl(rec_ogpr.perc_possesso,100) / 100)
                                                   * w_periodo,1
                                        );
                    -- (VD - 15/06/2021): aggiunto calcolo importo in acconto
                    --                    se tipo emissione ruolo = 'A'
                    if w_tipo_emissione = 'A' and
                       w_perc_acconto is not null then
                       w_importo := f_round(w_importo * w_perc_acconto / 100,1);
                    end if;
                 ELSE
                 -- Il normalizzato tiene conto del periodo e percentuale di possesso.
                 --dbms_output.put_line('Tariffa: '||rec_ogpr.tariffa||' Tariffa qf: '||rec_ogpr.tariffa_quota_fissa);
                 --dbms_output.put_line('Anno ruolo: '||w_anno_ruolo);
                 --dbms_output.put_line('tributo: '||rec_ogpr.tributo);
                 --dbms_output.put_line('categoria: '||rec_ogpr.categoria);
                 --dbms_output.put_line('tipo_tariffa: '||rec_ogpr.tipo_tariffa);
                 --dbms_output.put_line('tariffa: '||rec_ogpr.tariffa);
                 --dbms_output.put_line('tariffa_quota_fissa: '||rec_ogpr.tariffa_quota_fissa);
                 --dbms_output.put_line('consistenza: '||rec_ogpr.consistenza);
                 --dbms_output.put_line('perc_poss: '||rec_ogpr.perc_possesso);
                 --dbms_output.put_line('data_decorrenza: '||to_char(rec_ogpr.data_decorrenza,'dd/mm/yyyy'));
                 --dbms_output.put_line('data_cessazione: '||to_char(w_data_cessazione,'dd/mm/yyyy'));
                 --dbms_output.put_line('flag_ab_principale: '||rec_ogpr.flag_ab_principale);
                 --dbms_output.put_line('numero_familiari: '||rec_ogpr.numero_familiari);
                 -- (VD - 04/01/2019): sostituita procedure CALCOLO_IMPORTO_NORMALIZZATO
                 --                    con CALCOLO_IMPORTO_NORM_TARIFFE per
                 --                    calcolo ruoli con tariffe
                    calcolo_importo_norm_tariffe(rec_ogpr.cod_fiscale
                                                ,null   --  ni
                                                ,w_anno_ruolo
                                                ,rec_ogpr.tributo
                                                ,rec_ogpr.categoria
                                                ,rec_ogpr.tipo_tariffa
                                                ,rec_ogpr.tariffa
                                                ,rec_ogpr.tariffa_quota_fissa
                                                ,rec_ogpr.consistenza
                                                ,rec_ogpr.perc_possesso
                                                ,rec_ogpr.data_decorrenza
                                                ,w_data_cessazione    --rec_ogpr.data_cessazione
                                                ,rec_ogpr.flag_ab_principale
                                                ,rec_ogpr.numero_familiari
                                                ,a_ruolo
                                                ,to_number(null)      -- oggetto
                                                ,rec_ogpr.tipo_tariffa_base
                                                ,w_importo
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
                                                ,w_giorni_ruolo
                                                );
                    if length(w_dettaglio_ogim) > 151 then
                       w_dettaglio_faog := w_dettaglio_ogim;
                       w_dettaglio_ogim := '';
                    end if;
                    if length(w_dettaglio_ogim_base) > 171 then
                       w_dettaglio_faog_base := w_dettaglio_ogim_base;
                       w_dettaglio_ogim_base := '';
                    end if;
                 END IF;
                 --
                 -- (VD - 23/10/2018): Determinazione importi con tariffa base
                 --
                 /*if w_flag_tariffa_base = 'S' and rec_ogpr.tipo_tariffa_base is not null then
                    determina_importi_base(rec_ogpr.cod_fiscale
                                          ,w_anno_ruolo
                                          ,a_ruolo
                                          ,rec_ogpr.tributo
                                          ,rec_ogpr.categoria
                                          ,rec_ogpr.tipo_tariffa_base
                                          ,a_flag_normalizzato
                                          ,rec_ogpr.consistenza
                                          ,rec_ogpr.perc_possesso
                                          ,w_periodo
                                          ,rec_ogpr.data_decorrenza
                                          ,w_data_cessazione    --rec_ogpr.data_cessazione
                                          ,rec_ogpr.flag_ab_principale
                                          ,rec_ogpr.numero_familiari
                                          ,w_importo_base
                                          ,w_importo_pf_base
                                          ,w_importo_pv_base
                                          ,w_stringa_familiari_base
                                          ,w_dettaglio_ogim_base
                                          ,w_giorni_ruolo
                                          );
                    if length(w_dettaglio_ogim_base) > 171 then
                       w_dettaglio_faog_base := w_dettaglio_ogim_base;
                       w_dettaglio_ogim_base := '';
                    end if;
                 end if; */
                 --dbms_output.put_line('Imposta dovuta: '||w_importo);
                 --dbms_output.put_line('Dettaglio ogim: '||w_dettaglio_ogim);
                 --dbms_output.put_line('Giorni ruolo: '||w_giorni_ruolo);
                 --dbms_output.put_line(' Importo Tot: '||to_char(w_importo)||' Importo pf: '||to_char(w_importo_pf)||' Importo pv: '||to_char(w_importo_pv));
                 -- Bovezzo gestione secondo semestre
                 if w_cod_istat = '017025' and w_tipo_tributo = 'TARSU' and w_anno_ruolo > 2007
                     and w_progr_emissione = 7 then
                    w_tratta_sgravio := 0; --sgravio NON trattato
                    w_imp_scalare := round(f_importo_da_scalare_sem(a_ruolo
                                                               ,rec_ogpr.cod_fiscale
                                                               ,w_anno_ruolo
                                                               ,rec_ogpr.data_decorrenza
                                                               ,w_data_cessazione    ---rec_ogpr.data_cessazione
                                                               ,w_tipo_tributo
                                                               ,rec_ogpr.oggetto_pratica_rif
                                                               ,a_flag_normalizzato
                                                               ,'TOT'
                                                               ,w_tratta_sgravio
                                                               )
                                          ,2
                                          );
                    w_importo := w_importo - nvl(w_imp_scalare,0);
                    w_imp_scalare_pf := round(f_importo_da_scalare_sem(a_ruolo
                                                           ,rec_ogpr.cod_fiscale
                                                           ,w_anno_ruolo
                                                           ,rec_ogpr.data_decorrenza
                                                           ,w_data_cessazione   --rec_ogpr.fine_decorrenza
                                                           ,w_tipo_tributo
                                                           ,rec_ogpr.oggetto_pratica_rif
                                                           ,a_flag_normalizzato
                                                           ,'PF'
                                                           ,w_tratta_sgravio
                                                           )
                                             ,2
                                             );
                    w_importo_pf := w_importo_pf - nvl(w_imp_scalare_pf,0);
                    w_imp_scalare_pv := round(f_importo_da_scalare_sem(a_ruolo
                                                           ,rec_ogpr.cod_fiscale
                                                           ,w_anno_ruolo
                                                           ,rec_ogpr.data_decorrenza
                                                           ,w_data_cessazione    --rec_ogpr.fine_decorrenza
                                                           ,w_tipo_tributo
                                                           ,rec_ogpr.oggetto_pratica_rif
                                                           ,a_flag_normalizzato
                                                           ,'PV'
                                                           ,w_tratta_sgravio
                                                           )
                                             ,2
                                             );
                    w_importo_pv := w_importo_pv - nvl(w_imp_scalare_pv,0);
                    if w_importo_pf < 0 or w_importo_pv < 0 then
                       w_importo_pv := 0;
                       w_importo_pf := 0;
                    end if;
                    if w_da_mese_ruolo < 7 then
                       w_da_mese_ruolo := 7;
                    end if;
                    w_periodo := (w_a_mese_ruolo + 1 - w_da_mese_ruolo) /12;  -- Solo per Bovezzo
                    -- (VD - 06/11/2018): Gestione importi calcolati con tariffa base
                    if w_flag_tariffa_base = 'S' or w_flag_ruolo_tariffa = 'S' then
                       w_imp_scalare_base := round(f_importo_da_scalare_sem
                                                                  (a_ruolo
                                                                  ,rec_ogpr.cod_fiscale
                                                                  ,w_anno_ruolo
                                                                  ,rec_ogpr.data_decorrenza
                                                                  ,w_data_cessazione    ---rec_ogpr.data_cessazione
                                                                  ,w_tipo_tributo
                                                                  ,rec_ogpr.oggetto_pratica_rif
                                                                  ,a_flag_normalizzato
                                                                  ,'TOTB'
                                                                  ,w_tratta_sgravio
                                                                  )
                                             ,2
                                             );
                       w_importo_base := w_importo_base - nvl(w_imp_scalare_base,0);
                       w_imp_scalare_pf_base := round(f_importo_da_scalare_sem
                                                              (a_ruolo
                                                              ,rec_ogpr.cod_fiscale
                                                              ,w_anno_ruolo
                                                              ,rec_ogpr.data_decorrenza
                                                              ,w_data_cessazione   --rec_ogpr.fine_decorrenza
                                                              ,w_tipo_tributo
                                                              ,rec_ogpr.oggetto_pratica_rif
                                                              ,a_flag_normalizzato
                                                              ,'PFB'
                                                              ,w_tratta_sgravio
                                                              )
                                                ,2
                                                );
                       w_importo_pf_base := w_importo_pf_base - nvl(w_imp_scalare_pf_base,0);
                       w_imp_scalare_pv_base := round(f_importo_da_scalare_sem
                                                              (a_ruolo
                                                              ,rec_ogpr.cod_fiscale
                                                              ,w_anno_ruolo
                                                              ,rec_ogpr.data_decorrenza
                                                              ,w_data_cessazione    --rec_ogpr.fine_decorrenza
                                                              ,w_tipo_tributo
                                                              ,rec_ogpr.oggetto_pratica_rif
                                                              ,a_flag_normalizzato
                                                              ,'PVB'
                                                              ,w_tratta_sgravio
                                                              )
                                                ,2
                                                );
                       w_importo_pv_base := w_importo_pv_base - nvl(w_imp_scalare_pv_base,0);
                       if w_importo_pf_base < 0 or w_importo_pv_base < 0 then
                          w_importo_pv_base := 0;
                          w_importo_pf_base := 0;
                       end if;
                    else
                       w_importo_base := to_number(null);
                       w_importo_pf_base := to_number(null);
                       w_importo_pv_base := to_number(null);
                    end if;
                 end if;
                 w_stato := '01';
                 -- la variabile w_importo_tot contiene il valore totale calcolato prima della gestione
                 -- del tipo_emissione, mi serve perchè un oggetto potrebbe andare a ruolo per la sola maggiorazione_tares
                 w_importo_tot := w_importo;
                 w_importo_tot_base := w_importo_base;
  -- dbms_output.put_line('Stato: '|| w_stato||' Importo Tot: '||to_char(w_importo));
               -- Gestione TIPO EMISSIONE  --
                 if w_anno_ruolo >= 2013 then
--                 if w_anno_ruolo >= 2013 and
--                    w_cod_istat <> '017025' then  -- Bovezzo
                    w_stato := '02';
  -- dbms_output.put_line('Stato: '|| w_stato||' Tipo emissione: '||w_tipo_emissione);
                    if w_tipo_emissione = 'T' then
                       w_ins_magg_tares := 'S';
                    elsif w_tipo_emissione = 'A'  then
                       w_ins_magg_tares := 'N';
                    elsif w_tipo_emissione = 'S'  then
                       w_ins_magg_tares := 'S';
                       w_stato := '03';
                     -- Cancellazione sgravi automatici 99 inseriti sull'acconto
                     -- da una precedente emissione del ruolo a saldo
                       if w_cf_del_sgravi <> rec_ogpr.cod_fiscale then
                          begin
                             /*delete sgravi
                              where cod_fiscale = rec_ogpr.cod_fiscale
                                and ruolo in (select ruolo
                                                from ruoli
                                               where anno_ruolo = w_anno_ruolo
                                                 and tipo_tributo = w_tipo_tributo
                                                 and invio_consorzio is not null
                                                 and tipo_emissione = 'A'
                                             )
                                and motivo_sgravio = 99
                                and flag_automatico = 'S'
                                ;*/
                             eliminazione_sgravi_ruolo(rec_ogpr.cod_fiscale, a_ruolo, w_anno_ruolo, 'TARSU', w_tipo_emissione, w_tipo_ruolo,'S');
                          EXCEPTION
                             WHEN others THEN
                                w_errore := 'Errore in eliminazione Sgravi Acconto '||
                                            'per '||w_cod_fiscale||' - ('||SQLERRM||')';
                                RAISE errore;
                          end;
                          w_cf_del_sgravi := rec_ogpr.cod_fiscale;
                          --
                          -- (VD - 06/07/2015) Nota: in teoria non dovrebbero esistere compensazioni
                          --                         su un ruolo in acconto; comunque si cancellano
                          --
                          begin
                             delete compensazioni_ruolo
                              where cod_fiscale = rec_ogpr.cod_fiscale
                                 and ruolo = a_ruolo
                                 and motivo_compensazione = 99
                                 and flag_automatico = 'S'
                                ;
                          EXCEPTION
                             WHEN others THEN
                                w_errore := 'Errore in eliminazione Compensazioni Ruolo '||
                                            'per '||w_cod_fiscale||' - ('||SQLERRM||')';
                                RAISE errore;
                          end;
                       end if;--w_cf_del_sgravi <> rec_ogpr.cod_fiscale
                       --
                       -- (VD - 21/02/2018): aggiunti parametri oggetto e
                       --                    oggetto_pratica
                       -- (VD - 23/10/2018): aggiunti parametri per gestione
                       --                    importi calcolati con tariffa base
                       --
                       importi_ruolo_acconto(rec_ogpr.cod_fiscale
                                            ,w_anno_ruolo
                                            ,rec_ogpr.data_decorrenza
                                            ,w_data_cessazione    --rec_ogpr.fine_decorrenza
                                            ,w_tipo_tributo
                                            ,rec_ogpr.oggetto
                                            ,rec_ogpr.oggetto_pratica --rec_ogpr.oggetto_pratica_rif
                                            ,rec_ogpr.oggetto_pratica_rif
                                            ,a_flag_normalizzato
                                            ,w_flag_tariffa_base
                                            ,w_importo_acconto
                                            ,w_importo_acconto_pv
                                            ,w_importo_acconto_pf
                                            ,w_importo_acc_base
                                            ,w_importo_acc_pv_base
                                            ,w_importo_acc_pf_base
                                            ,w_tipo_calcolo_acconto
                                            ,w_ruolo_acconto
                                            );
                       --dbms_output.put_line('Importi_ruolo_acconto: Importo acconto '||w_importo_acconto||' acconto pv: '||w_importo_acconto_pv||' acconto pf '||w_importo_acconto_pf);
                       if w_tipo_calcolo_acconto = 'N' then
                       --dbms_output.put_line('1 importo pv '||w_importo_pv||' importo acconto pv '||w_importo_acconto_pv||' ');
                          w_importo_pv := w_importo_pv - w_importo_acconto_pv;
                       --dbms_output.put_line('2 importo pv '||w_importo_pv||' importo acconto pv '||w_importo_acconto_pv||' ');
                          if w_importo_pv < 0 then
                             w_importo_pv := null;
                          end if;
                          w_importo_pf := w_importo_pf - w_importo_acconto_pf;
                          if w_importo_pf < 0 then
                             w_importo_pf := null;
                          end if;
                       -- (VD - 14/10/2021): se il tipo calcolo acconto è nullo,
                       --                    significa che non esiste il ruolo
                       --                    in acconto, quindi gli importi
                       --                    quota fissa e quota variabile
                       --                    devono rimanere valorizzati
                       elsif w_tipo_calcolo_acconto is not null then
                          w_importo_pv := null;
                          w_importo_pf := null;
                       end if;
                       --
                       -- (VD - 23/10/2018): Calcolo importi tariffa base
                       --
                       if w_flag_tariffa_base = 'S' then
                          if w_tipo_calcolo_acconto = 'N' or
                             -- (VD - 14/10/2021): se il tipo calcolo acconto è nullo,
                             --                    significa che non esiste il ruolo
                             --                    in acconto, quindi gli importi
                             --                    quota fissa e quota variabile
                             --                    devono rimanere valorizzati
                            (w_tipo_calcolo_acconto is null and a_flag_normalizzato is not null) then
                             w_importo_pv_base := w_importo_pv_base - w_importo_acc_pv_base;
                          --dbms_output.put_line('2 importo pv '||w_importo_pv||' importo acconto pv '||w_importo_acconto_pv||' ');
                             if w_importo_pv_base < 0 then
                                w_importo_pv_base := null;
                             end if;
                             w_importo_pf_base := w_importo_pf_base - w_importo_acc_pf_base;
                             if w_importo_pf_base < 0 then
                                w_importo_pf_base := null;
                             end if;
                          else
                             w_importo_pv_base := null;
                             w_importo_pf_base := null;
                          end if;
                       else
                          w_importo_pv_base := null;
                          w_importo_pf_base := null;
                       end if;
                       w_stato := '04';
                       w_note_calcolo_importo := ' Importo Tot: '||to_char(w_importo)||' - Importo Acc: '||to_char(w_importo_acconto);
                       w_imposta_dovuta := w_importo;  -- per inserirlo nei modelli (14/11/13) AB
                       w_imposta_dovuta_acconto := w_importo_acconto;
                       w_importo := w_importo - w_importo_acconto;
                       --
                       -- (VD - 23/10/2018): Calcolo importi tariffa base
                       --
                       if w_flag_tariffa_base = 'S' or
                          w_flag_ruolo_tariffa = 'S' then
                          w_note_calcolo_imp_base := ' Importo Tot.Base: '||to_char(w_importo_base)||' - Importo Acc.Base: '||to_char(w_importo_acc_base);
                          w_imposta_dovuta_base := w_importo_base;
                          w_imposta_dovuta_acc_base := w_importo_acc_base;
                          w_importo_base := w_importo_base - w_importo_acc_base;
                       else
                          w_note_calcolo_imp_base := null;
                          w_imposta_dovuta_base := to_number(null);
                          w_imposta_dovuta_acc_base := to_number(null);
                          w_importo_base := to_number(null);
                       end if;
                       --dbms_output.put_line('Importo'|| w_importo);
                       -- se l'importo è negativo perchè il ruolo in Acconto supera il totale
                       -- metto l'importo a zero e inserisco uno sgravio sul ruolo di acconto
                       w_stato := '05';
                       if w_importo < 0 then
                          w_importo_sgravio := 0 - w_importo;
                          w_importo := 0;
                          w_stato := '06';
                          --
                          -- (VD - 23/10/2018): Calcolo importi tariffa base
                          --
                          if w_flag_tariffa_base = 'S' then
                             if w_importo_base < 0 then
                                w_importo_sgravio_base := 0 - w_importo_base;
                                w_importo_base := 0;
                             end if;
                          end if;
                          --dbms_output.put_line('Importo Sgravio'|| w_importo_sgravio);
                          crea_sgravio_acconto(w_importo_sgravio
                                              ,w_importo_sgravio_base
                                              ,rec_ogpr.cod_fiscale
                                              ,w_anno_ruolo
                                              ,w_tipo_tributo
                                              ,rec_ogpr.oggetto_pratica_rif
                                              ,a_ruolo
                                              ,w_flag_tariffa_base);
                       end if;
                    else
                       w_errore := 'Indicare il Tipo Emissione';
                       raise errore;
                    end if; --test tipo emissione
                 elsif w_cod_istat = '017025'
                       and w_tipo_tributo = 'TARSU'
                       and w_anno_ruolo >= 2013
                       and w_progr_emissione = 7 then
                    w_ins_magg_tares := 'S'; --calcolo magg. tares x Bovezzo secondo semestre
                 else
                    w_importo_tot := w_importo;
                    w_importo_tot_base := w_importo_base;
                 end if;
                 w_stato := '06';
-- dbms_output.put_line('Stato: '|| w_stato||' Importo Tot: '||to_char(w_importo_tot)||' Importo: '||to_char(w_importo));
                 if (w_importo_tot > 0) then
                    w_imp_addizionale_pro   := f_round(w_importo * w_addizionale_pro / 100,1);
                    w_imp_addizionale_eca   := f_round(w_importo * w_addizionale_eca / 100,1);
                    w_imp_maggiorazione_eca := f_round(w_importo * w_maggiorazione_eca / 100,1);
                    w_imp_aliquota          := f_round(w_importo * w_aliquota / 100,1);
                    if w_cod_istat = '037048' then  -- Pieve di Cento
                       w_importo               := round(w_importo,0);
                       w_imp_addizionale_pro   := round(w_imp_addizionale_pro,0);
                       w_imp_addizionale_eca   := round(w_imp_addizionale_eca,0);
                       w_imp_maggiorazione_eca := round(w_imp_maggiorazione_eca,0);
                       w_imp_aliquota          := round(w_imp_aliquota,0);
                    end if;
                    w_tot_addizionali       := w_imp_addizionale_pro
                                             + w_imp_addizionale_eca
                                             + w_imp_maggiorazione_eca
                                             + w_imp_aliquota;
                    w_importo_ruolo         := w_importo + w_tot_addizionali;
                    w_oggetto_imposta := null;
                    oggetti_imposta_nr(w_oggetto_imposta);
--dbms_output.put_line('Importo Ruolo: '||to_char(w_importo_ruolo));
                    --  incentivi TARSU per San Lazzaro per il 2004 da applicare alla prima utenza
                    --  se si h in presenza di una particolare delega bancaria
                    if (w_cod_istat ='037054') and (w_anno_ruolo = 2004) and
                       (w_flag_incentivo = 'N') and (w_anno_emissione = 2004) and (w_progr_emissione = 1) then
                       begin
                       --  metto il flag a 'S' per indicare che ho applicato l'incentivo TARSU
                       --  per la prima utenza
                         select decode(deba.cod_cab,37070,8.7,2400,17.39,0)
                              , decode(deba.cod_cab,37070,'ANNO 2004: INCENTIVO TARSU: EURO 8,7'
                                                 ,2400,'ANNO 2004: INCENTIVO TARSU: EURO 17,39'
                                            ,'')
                            , decode(deba.cod_cab,37070,'S',2400,'S','N')
                          into w_incentivi
                             , w_note_ogim
                             , w_flag_incentivo
                          from deleghe_bancarie deba
                         where deba.cod_abi = 6120
                           and deba.cod_cab in (37070,2400)
                           and deba.tipo_tributo = 'TARSU'
                           and deba.cod_fiscale = rec_ogpr.cod_fiscale
                             ;
                       exception
                          when others then
                              w_note_ogim := '';
                              w_incentivi := 0;
                              w_flag_incentivo := 'N';
                       end;
                       w_importo_ruolo:= w_importo_ruolo - w_incentivi;
                    elsif (w_cod_istat ='037054') and (w_anno_ruolo = 2005) and
                          (w_flag_incentivo = 'N') and (w_anno_emissione = 2005) and (w_progr_emissione = 1) then
                       begin
                       --  metto il flag a 'S' per indicare che ho applicato l'incentivo TARSU
                       --  per la prima utenza
                         select decode(deba.cod_cab,37070,8.7,2400,17.39,0)
                              , decode(deba.cod_cab,37070,'ANNO 2005: INCENTIVO TARSU: EURO 8,7'
                                                 ,2400,'ANNO 2005: INCENTIVO TARSU: EURO 17,39'
                                            ,'')
                              , decode(deba.cod_cab,37070,'S',2400,'S','N')
                           into w_incentivi
                              , w_note_ogim
                             , w_flag_incentivo
                           from deleghe_bancarie deba
                          where deba.cod_abi = 6120
                            and deba.cod_cab in (37070,2400)
                            and deba.tipo_tributo = 'TARSU'
                            and deba.cod_fiscale = rec_ogpr.cod_fiscale
                             ;
                       exception
                          when others then
                              w_note_ogim := '';
                              w_incentivi := 0;
                              w_flag_incentivo := 'N';
                       end;
                       w_importo_ruolo:= w_importo_ruolo - w_incentivi;
                    elsif (w_cod_istat ='037054') and (w_anno_ruolo = 2006) and
                          (w_flag_incentivo = 'N') and (w_anno_emissione = 2006) and (w_progr_emissione = 1) and
                          (rec_ogpr.oggetto_pratica not in (278884, 312734) ) then
                       begin
                       --     metto il flag a 'S' per indicare che ho applicato l'incentivo TARSU
                       --    per la prima utenza
                         select decode(deba.cod_cab,37070,8.7,2400,17.39,0)
                              , decode(deba.cod_cab,37070,'ANNO 2006: INCENTIVO TARSU: EURO 8,7'
                                               ,2400,'ANNO 2006: INCENTIVO TARSU: EURO 17,39'
                                          ,'')
                              , decode(deba.cod_cab,37070,'S',2400,'S','N')
                           into w_incentivi
                              , w_note_ogim
                              , w_flag_incentivo
                           from deleghe_bancarie deba
                          where deba.cod_abi = 6120
                            and deba.cod_cab in (37070,2400)
                            and deba.tipo_tributo = 'TARSU'
                            and deba.cod_fiscale = rec_ogpr.cod_fiscale
                              ;
                       exception
                          when others then
                           w_note_ogim := '';
                           w_incentivi := 0;
                           w_flag_incentivo := 'N';
                       end;
                       w_importo_ruolo:= w_importo_ruolo - w_incentivi;
                    elsif (w_cod_istat ='037054') and (w_anno_ruolo = 2007) and
                          (w_flag_incentivo = 'N') and (w_anno_emissione = 2007) and (w_progr_emissione = 1) then
                       begin
                       -- metto il flag a 'S' per indicare che ho applicato l'incentivo TARSU
                       -- per la prima utenza
                         select decode(deba.cod_cab,37070,8.7,2400,17.39,0)
                              , decode(deba.cod_cab,37070,'ANNO 2007: INCENTIVO TARSU: EURO 8,7'
                                                 ,2400,'ANNO 2007: INCENTIVO TARSU: EURO 17,39'
                                            ,'')
                              , decode(deba.cod_cab,37070,'S',2400,'S','N')
                           into w_incentivi
                              , w_note_ogim
                              , w_flag_incentivo
                           from deleghe_bancarie deba
                          where deba.cod_abi = 6120
                            and deba.cod_cab in (37070,2400)
                            and deba.tipo_tributo = 'TARSU'
                            and deba.cod_fiscale = rec_ogpr.cod_fiscale
                             ;
                       exception
                          when others then
                              w_note_ogim := '';
                              w_incentivi := 0;
                              w_flag_incentivo := 'N';
                       end;
                       w_importo_ruolo:= w_importo_ruolo - w_incentivi;
                    elsif (w_cod_istat ='037054') and (w_anno_ruolo = 2008) and
                          (w_flag_incentivo = 'N') and (w_anno_emissione = 2008) and (w_progr_emissione = 1) then
                       begin
                       --  metto il flag a 'S' per indicare che ho applicato l'incentivo TARSU
                       --  per la prima utenza
                         select decode(deba.cod_cab,37070,8.7,2400,17.39,0)
                              , decode(deba.cod_cab,37070,'ANNO 2008: INCENTIVO TARSU: EURO 8,7'
                                                 ,2400,'ANNO 2008: INCENTIVO TARSU: EURO 17,39'
                                            ,'')
                              , decode(deba.cod_cab,37070,'S',2400,'S','N')
                           into w_incentivi
                              , w_note_ogim
                              , w_flag_incentivo
                           from deleghe_bancarie deba
                          where deba.cod_abi = 6120
                            and deba.cod_cab in (37070,2400)
                            and deba.tipo_tributo = 'TARSU'
                            and deba.cod_fiscale = rec_ogpr.cod_fiscale
                             ;
                       exception
                          when others then
                              w_note_ogim := '';
                              w_incentivi := 0;
                              w_flag_incentivo := 'N';
                       end;
                       w_importo_ruolo:= w_importo_ruolo - w_incentivi;
                    elsif (w_cod_istat ='037054') and (w_anno_ruolo = 2010) and
                          (w_flag_incentivo = 'N') and (w_anno_emissione = 2010) and (w_progr_emissione = 1) then
                       begin
                       --  metto il flag a 'S' per indicare che ho applicato l'incentivo TARSU
                       --  per la prima utenza
                         select decode(deba.cod_cab
                                      ,37070,13.9
                                      ,36640,13.9
                                      ,36750,27.8
                                      ,2400,17.39
                                      ,2413,17.39
                                      ,2600,34.78
                                      ,0)
                              , decode(deba.cod_cab
                                      ,37070,'ANNO 2010: INCENTIVO TARSU 2008: EURO 13,9'
                                      ,36640,'ANNO 2010: INCENTIVO TARSU 2009: EURO 13,9'
                                      ,36750,'ANNO 2010: INCENTIVO TARSU 2008-2009: EURO 27,8'
                                      ,2400,'ANNO 2010: INCENTIVO TARSU 2008: EURO 17,39'
                                      ,2413,'ANNO 2010: INCENTIVO TARSU 2009: EURO 17,39'
                                      ,2600,'ANNO 2010: INCENTIVO TARSU 2008-2009: EURO 34,78'
                                      ,'')
                              , decode(deba.cod_cab
                                      ,37070,'S'
                                      ,36640,'S'
                                      ,36750,'S'
                                      ,2400,'S'
                                      ,2413,'S'
                                      ,2600,'S'
                                      ,'N')
                           into w_incentivi
                              , w_note_ogim
                              , w_flag_incentivo
                           from deleghe_bancarie deba
                          where deba.cod_abi = 6120
                            and deba.cod_cab in (37070,36640,36750,2400,2413,2600)
                            and deba.tipo_tributo = 'TARSU'
                            and deba.cod_fiscale = rec_ogpr.cod_fiscale
                             ;
                       exception
                          when others then
                              w_note_ogim := '';
                              w_incentivi := 0;
                              w_flag_incentivo := 'N';
                       end;
                       w_importo_ruolo:= w_importo_ruolo - w_incentivi;
                    elsif (w_cod_istat ='037054') and (w_anno_ruolo = 2012) and
                          (w_flag_incentivo = 'N') and (w_anno_emissione = 2012) and (w_progr_emissione = 1) then
                       begin
                       --  metto il flag a 'S' per indicare che ho applicato l'incentivo TARSU
                       --  per la prima utenza
                         select decode(coco.tipo_contatto
                                      ,79,39.13
                                      ,80,52.17
                                      ,81,78.26
                                      ,77,13.04
                                      ,78,26.09
                                      ,0)
                              , decode(coco.tipo_contatto
                                      ,79,'ANNO 2012: INCENTIVO TARSU EURO 45'
                                      ,80,'ANNO 2012: INCENTIVO TARSU EURO 60'
                                      ,81,'ANNO 2012: INCENTIVO TARSU EURO 90'
                                      ,77,'ANNO 2012: INCENTIVO TARSU EURO 15'
                                      ,78,'ANNO 2012: INCENTIVO TARSU EURO 30'
                                      ,'')
                              , decode(coco.tipo_contatto
                                      ,79,'S'
                                      ,80,'S'
                                      ,81,'S'
                                      ,77,'S'
                                      ,78,'S'
                                      ,'N')
                           into w_incentivi
                              , w_note_ogim
                              , w_flag_incentivo
                           from contatti_contribuente coco
                          where coco.anno=2012
                            and coco.tipo_contatto in (78,80,81,77,79)
                            and coco.cod_fiscale = rec_ogpr.cod_fiscale
                             ;
                       exception
                          when others then
                              w_note_ogim := '';
                              w_incentivi := 0;
                              w_flag_incentivo := 'N';
                       end;
                       w_importo_ruolo:= w_importo_ruolo - w_incentivi;
                    elsif (w_cod_istat ='037054') and (w_anno_ruolo = 2014) and
                          (w_flag_incentivo = 'N') and (w_anno_emissione = 2014) and (w_progr_emissione = 1) then
                       begin
                       --  metto il flag a 'S' per indicare che ho applicato l'incentivo TARSU
                       --  per la prima utenza
                         select decode(coco.tipo_contatto
                                      ,79,45.00
                                      ,80,60.00
                                      ,81,90.00
                                      ,85,105.00
                                      ,77,15.00
                                      ,78,30.00
                                      ,0)
                              , decode(coco.tipo_contatto
                                      ,79,'ANNO 2014: INCENTIVO TARI EURO 45'
                                      ,80,'ANNO 2014: INCENTIVO TARI EURO 60'
                                      ,81,'ANNO 2014: INCENTIVO TARI EURO 90'
                                      ,85,'ANNO 2014: INCENTIVO TARI EURO 105'
                                      ,77,'ANNO 2014: INCENTIVO TARI EURO 15'
                                      ,78,'ANNO 2014: INCENTIVO TARI EURO 30'
                                      ,'')
                              , decode(coco.tipo_contatto
                                      ,79,'S'
                                      ,80,'S'
                                      ,81,'S'
                                      ,85,'S'
                                      ,77,'S'
                                      ,78,'S'
                                      ,'N')
                           into w_incentivi
                              , w_note_ogim
                              , w_flag_incentivo
                           from contatti_contribuente coco
                          where coco.anno = 2014
                            and coco.tipo_contatto in (78,80,81,85,77,79)
                            and coco.cod_fiscale = rec_ogpr.cod_fiscale
                             ;
                       exception
                          when others then
                              w_note_ogim := '';
                              w_incentivi := 0;
                              w_flag_incentivo := 'N';
                       end;
                       w_importo_ruolo:= w_importo_ruolo - w_incentivi;
                    elsif (w_cod_istat ='037054') and (w_anno_ruolo >= 2015) and
                          (w_flag_incentivo = 'N') and (w_anno_emissione = w_anno_ruolo) and (w_progr_emissione = 1) then
                       begin
                       --  metto il flag a 'S' per indicare che ho applicato l'incentivo TARSU
                       --  per la prima utenza
                         select decode(coco.tipo_contatto
                                      ,79,45.00
                                      ,80,60.00
                                      ,81,90.00
                                      ,85,105.00
                                      ,77,15.00
                                      ,78,30.00
                                      ,87,75.00
                                      ,0)
                              , decode(coco.tipo_contatto
                                      ,79,'ANNO '||coco.anno||': INCENTIVO '||f_descrizione_titr('TARSU',coco.anno)||' EURO 45'
                                      ,80,'ANNO '||coco.anno||': INCENTIVO '||f_descrizione_titr('TARSU',coco.anno)||' EURO 60'
                                      ,81,'ANNO '||coco.anno||': INCENTIVO '||f_descrizione_titr('TARSU',coco.anno)||' EURO 90'
                                      ,85,'ANNO '||coco.anno||': INCENTIVO '||f_descrizione_titr('TARSU',coco.anno)||' EURO 105'
                                      ,77,'ANNO '||coco.anno||': INCENTIVO '||f_descrizione_titr('TARSU',coco.anno)||' EURO 15'
                                      ,78,'ANNO '||coco.anno||': INCENTIVO '||f_descrizione_titr('TARSU',coco.anno)||' EURO 30'
                                      ,87,'ANNO '||coco.anno||': INCENTIVO '||f_descrizione_titr('TARSU',coco.anno)||' EURO 75'
                                      ,'')
                              , decode(coco.tipo_contatto
                                      ,79,'S'
                                      ,80,'S'
                                      ,81,'S'
                                      ,85,'S'
                                      ,77,'S'
                                      ,78,'S'
                                      ,87,'S'
                                      ,'N')
                           into w_incentivi
                              , w_note_ogim
                              , w_flag_incentivo
                           from contatti_contribuente coco
                          where coco.anno = w_anno_ruolo
                            and coco.tipo_contatto in (79,80,81,85,77,78,87)
                            and coco.cod_fiscale = rec_ogpr.cod_fiscale
                             ;
                       exception
                          when others then
                              w_note_ogim := '';
                              w_incentivi := 0;
                              w_flag_incentivo := 'N';
                       end;
                       w_importo_ruolo:= w_importo_ruolo - w_incentivi;
                    else
                       w_note_ogim := '';
                    end if;
                   -- sistemazione dettaglio ogim per Bovezzo secondo semestre
                    if w_cod_istat = '017025' and w_tipo_tributo = 'TARSU' and w_anno_ruolo > 2007
                    and w_progr_emissione = 7  and w_dettaglio_ogim is not null then
                        w_dettaglio_ogim := substr(w_dettaglio_ogim,1,48)
                                         ||lpad(translate(to_char(w_importo_pf,'FM99,999,999,990.00'),'.,',',.'),17)
                                         ||substr(w_dettaglio_ogim,66,48)
                                         ||lpad(translate(to_char(w_importo_pv,'FM99,999,999,990.00'),'.,',',.'),17)
                                         ||lpad(translate(to_char(w_importo,'FM9,999,999,999,990.00'),'.,',',.'),20);
                        if w_flag_tariffa_base = 'S' then
                           w_dettaglio_ogim_base := substr(w_dettaglio_ogim_base,1,58)
                                            ||lpad(translate(to_char(w_importo_pf_base,'FM99,999,999,990.00'),'.,',',.'),17)
                                            ||substr(w_dettaglio_ogim_base,76,58)
                                            ||lpad(translate(to_char(w_importo_pv_base,'FM99,999,999,990.00'),'.,',',.'),17)
                                            ||lpad(translate(to_char(w_importo_base,'FM9,999,999,999,990.00'),'.,',',.'),20);
                        else
                           w_dettaglio_ogim_base := null;
                        end if;
                    end if;
                    -- maggiorazione tares
-- dbms_output.put_line('Magg. tares: '||w_ins_magg_tares);
                    if nvl(w_ins_magg_tares,'N') = 'S' then
                       if w_flag_magg_anno is null then
                          w_coeff_gg := F_COEFF_GG(w_anno_ruolo,rec_ogpr.data_decorrenza,w_data_cessazione);
                          w_magg_tares_ogim := round(rec_ogpr.consistenza * w_maggiorazione_tares * (100 - rec_ogpr.perc_riduzione) / 100 * w_coeff_gg,2);
                       else
                          if Oggetti_tab.exists(rec_ogpr.oggetto) then
                             w_magg_tares_ogim := null;
                          else
                             Oggetti_tab(rec_ogpr.oggetto) := 'S';
                             w_magg_tares_ogim := round(rec_ogpr.consistenza * w_maggiorazione_tares,2);
                          end if;
                       end if;
                    -- maggiorazione componenti perequative
                       if rec_ogpr.flag_punto_raccolta = 'S' then
                          if w_flag_magg_anno is null then
                             w_coeff_gg := F_COEFF_GG(w_anno_ruolo,rec_ogpr.data_decorrenza,w_data_cessazione);
                             w_magg_tares_ogim := trunc(w_magg_tares_cope * w_coeff_gg,2);
                          else
                             w_magg_tares_ogim := w_magg_tares_cope;
                          end if;
                       end if;
                       w_importo_ruolo := w_importo_ruolo + nvl(w_magg_tares_ogim,0);
                    end if;
--dbms_output.put_line('Importo Ruolo: '||to_char(w_importo_ruolo));
--w_errore := to_char(rec_ogpr.data_decorrenza,'dd/mm/yyyy')||' - '||to_char(w_data_cessazione,'dd/mm/yyyy');
--w_errore := nvl(to_char(w_coeff_gg),'null');
--w_errore := to_char(rec_ogpr.consistenza)||' - '||to_char(w_maggiorazione_tares);
--w_errore := to_char(w_magg_tares_ogim);
--w_errore := to_char(w_importo_ruolo);
--if rec_ogpr.tributo = 465 then
--   raise errore;
--end if;
                    --
                    -- (VD - 23/10/2018): Gestione campi calcolati con tariffa base
                    --
                    if w_flag_tariffa_base = 'S' or
                       w_flag_ruolo_tariffa = 'S' then
                       if w_importo_tot_base > 0 then
                          w_imp_add_pro_base   := f_round(w_importo_base * w_addizionale_pro / 100,1);
                          w_imp_add_eca_base   := f_round(w_importo_base * w_addizionale_eca / 100,1);
                          w_imp_magg_eca_base  := f_round(w_importo_base * w_maggiorazione_eca / 100,1);
                          w_imp_aliquota_base  := f_round(w_importo_base * w_aliquota / 100,1);
                          w_tot_addizionali_base  := w_imp_add_pro_base
                                                   + w_imp_add_eca_base
                                                   + w_imp_magg_eca_base
                                                   + w_imp_aliquota_base;
                          w_importo_ruolo_base    := w_importo_base + w_tot_addizionali_base;
                       else
                          w_imp_add_pro_base     := 0;
                          w_imp_add_eca_base     := 0;
                          w_imp_magg_eca_base    := 0;
                          w_imp_aliquota_base    := 0;
                          w_tot_addizionali_base := 0;
                          w_importo_ruolo_base   := 0;
                       end if;
                    else
                       w_imp_add_pro_base     := to_number(null);
                       w_imp_add_eca_base     := to_number(null);
                       w_imp_magg_eca_base    := to_number(null);
                       w_imp_aliquota_base    := to_number(null);
                       w_tot_addizionali_base := to_number(null);
                       w_importo_ruolo_base   := to_number(null);
                    end if;
                    --
                    -- (VD - 23/10/2018): Aggiunti campi calcolati con tariffa base
                    --
                    if w_dettaglio_ogim is not null then
                       w_dettaglio_ogim := '*'||substr(w_dettaglio_ogim,2,1999);
                    end if;
                    if w_dettaglio_ogim_base is not null then
                       w_dettaglio_ogim_base := '*'||substr(w_dettaglio_ogim_base,2,1999);
                    end if;
                    if w_dettaglio_faog is not null then
                       w_dettaglio_faog := '*'||substr(w_dettaglio_faog,2,1999);
                    end if;
                    if w_dettaglio_faog_base is not null then
                       w_dettaglio_faog_base := '*'||substr(w_dettaglio_faog_base,2,1999);
                    end if;
                    BEGIN
                      insert into oggetti_imposta
                            (oggetto_imposta,cod_fiscale,anno,oggetto_pratica,imposta,
                             imposta_dovuta,imposta_dovuta_acconto,
                             addizionale_eca,maggiorazione_eca,addizionale_pro,iva,
                             ruolo,importo_ruolo,flag_calcolo,utente,note,
                             importo_pf,importo_pv,aliquota_iva,dettaglio_ogim,
                             maggiorazione_tares, tipo_tributo,
                             tipo_tariffa_base, imposta_base,
                             addizionale_eca_base, maggiorazione_eca_base,
                             addizionale_pro_base, iva_base, importo_pf_base,
                             importo_pv_base, importo_ruolo_base, dettaglio_ogim_base,
                             perc_riduzione_pf,perc_riduzione_pv,
                             importo_riduzione_pf,importo_riduzione_pv
                            )
                      values(w_oggetto_imposta,rec_ogpr.cod_fiscale,w_anno_ruolo,
                             rec_ogpr.oggetto_pratica,w_importo,
                             w_imposta_dovuta,w_imposta_dovuta_acconto,
                             w_imp_addizionale_eca,w_imp_maggiorazione_eca,
                             w_imp_addizionale_pro,w_imp_aliquota,
                             a_ruolo,w_importo_ruolo,'S',a_utente,w_note_ogim||w_note_calcolo_importo,
                             w_importo_pf,w_importo_pv,w_aliquota_iva,w_dettaglio_ogim,
                             w_magg_tares_ogim, w_tipo_tributo,
                             rec_ogpr.tipo_tariffa_base, w_importo_base,
                             w_imp_add_eca_base, w_imp_magg_eca_base,
                             w_imp_add_pro_base, w_imp_aliquota_base, w_importo_pf_base,
                             w_importo_pv_base, w_importo_ruolo_base,w_dettaglio_ogim_base,
                             w_perc_rid_pf, w_perc_rid_pv,
                             w_importo_pf_rid, w_importo_pv_rid
                            )
                      ;
                    EXCEPTION
                      WHEN others THEN
                         w_errore := 'Errore in inserimento Oggetti Imposta (1)- '||
                                     'per '||w_cod_fiscale||' - ('||SQLERRM||')';
                         RAISE errore;
                    END;
                    WHILE length(w_stringa_familiari) > 19  LOOP
                       if w_cod_istat = '017025' and w_tipo_tributo = 'TARSU' and w_anno_ruolo > 2007 -- Bovezzo
                          and w_progr_emissione = 7 then
                          if to_date(substr(w_stringa_familiari,13,8),'ddmmyyyy') > to_date('3006'||substr(w_stringa_familiari,17,4),'ddmmyyyy') then
                             if to_date(substr(w_stringa_familiari,5,8),'ddmmyyyy') > to_date('3006'||substr(w_stringa_familiari,9,4),'ddmmyyyy') then
                                --inserimento normale
                                BEGIN
                                   insert into familiari_ogim
                                              (oggetto_imposta,numero_familiari
                                              ,dal,al
                                              ,data_variazione
                                              ,dettaglio_faog
                                              ,dettaglio_faog_base
                                              )
                                        values(w_oggetto_imposta,to_number(substr(w_stringa_familiari,1,4))
                                              ,to_date(substr(w_stringa_familiari,5,8),'ddmmyyyy'),to_date(substr(w_stringa_familiari,13,8),'ddmmyyyy')
                                              ,trunc(sysdate)
                                              ,substr(w_dettaglio_faog,1,150)
                                              ,substr(w_dettaglio_faog_base,1,170)
                                              )
                                              ;
                                EXCEPTION
                                   WHEN others THEN
                                       w_errore := 'Errore in inserimento Familiari_ogim di '
                                                   ||w_cod_fiscale||' ('||SQLERRM||')';
                                           RAISE ERRORE;
                                END;
                             else
                                -- inserimento con riproporzionamento
                                w_mesi_faog      := to_number(substr(w_stringa_familiari,15,2)) + 1 - to_number(substr(w_stringa_familiari,7,2));
                                w_mesi_faog_2sem := to_number(substr(w_stringa_familiari,15,2)) + 1 - 7;
                                --w_errore := lpad(translate(to_char(round(to_number(ltrim(translate(substr(w_dettaglio_faog,49,17),',.','.'))) / w_mesi_faog * w_mesi_faog_2sem,2),'FM99,999,999,990.00'),'.,',',.'),17);
                                --RAISE ERRORE;
                                w_dettaglio_faog := substr(w_dettaglio_faog,1,48)
                                                  ||lpad(translate(to_char(round(to_number(ltrim(translate(translate(substr(w_dettaglio_faog,49,17),'a.','a'),',','.'))) / w_mesi_faog * w_mesi_faog_2sem,2),'FM99,999,999,990.00'),'.,',',.'),17)
                                                  ||substr(w_dettaglio_faog,66,48)
                                                  ||lpad(translate(to_char(round(to_number(ltrim(translate(translate(substr(w_dettaglio_faog,114,17),'a.','a'),',','.'))) / w_mesi_faog * w_mesi_faog_2sem,2),'FM99,999,999,990.00'),'.,',',.'),17)
                                                  ||lpad(translate(to_char(round(to_number(ltrim(translate(translate(substr(w_dettaglio_faog,131,20),'a.','a'),',','.'))) / w_mesi_faog * w_mesi_faog_2sem,2),'FM9,999,999,999,990.00'),'.,',',.'),20)
                                                  ||substr(w_dettaglio_faog,151);
                                if w_flag_tariffa_base = 'S' or
                                   w_flag_ruolo_tariffa = 'S' then
                                   w_dettaglio_faog_base := substr(w_dettaglio_faog_base,1,58)
                                                    ||lpad(translate(to_char(round(to_number(ltrim(translate(translate(substr(w_dettaglio_faog_base,59,17),'a.','a'),',','.'))) / w_mesi_faog * w_mesi_faog_2sem,2),'FM99,999,999,990.00'),'.,',',.'),17)
                                                    ||substr(w_dettaglio_faog_base,76,58)
                                                    ||lpad(translate(to_char(round(to_number(ltrim(translate(translate(substr(w_dettaglio_faog_base,134,17),'a.','a'),',','.'))) / w_mesi_faog * w_mesi_faog_2sem,2),'FM99,999,999,990.00'),'.,',',.'),17)
                                                    ||lpad(translate(to_char(round(to_number(ltrim(translate(translate(substr(w_dettaglio_faog_base,151,20),'a.','a'),',','.'))) / w_mesi_faog * w_mesi_faog_2sem,2),'FM9,999,999,999,990.00'),'.,',',.'),20)
                                                    ||substr(w_dettaglio_faog_base,171);
                                end if;
                                BEGIN
                                   insert into familiari_ogim
                                              (oggetto_imposta,numero_familiari
                                              ,dal,al
                                              ,data_variazione
                                              ,dettaglio_faog
                                              ,dettaglio_faog_base
                                              )
                                        values(w_oggetto_imposta,to_number(substr(w_stringa_familiari,1,4))
                                              ,to_date('0107'||substr(w_stringa_familiari,9,4),'ddmmyyyy'),to_date(substr(w_stringa_familiari,13,8),'ddmmyyyy')
                                              ,trunc(sysdate)
                                              ,substr(w_dettaglio_faog,1,150)
                                              ,substr(w_dettaglio_faog_base,1,170)
                                              )
                                              ;
                                EXCEPTION
                                   WHEN others THEN
                                       w_errore := 'Errore in inserimento Familiari_ogim di '
                                                   ||w_cod_fiscale||' ('||SQLERRM||')';
                                           RAISE ERRORE;
                                END;
                             end if;
                          else
                             -- nessun inserimento
                             null;
                          end if;
                       else
                          BEGIN
                             insert into familiari_ogim
                                        (oggetto_imposta,numero_familiari
                                        ,dal,al
                                        ,data_variazione
                                        ,dettaglio_faog
                                        ,dettaglio_faog_base
                                        )
                                  values(w_oggetto_imposta,to_number(substr(w_stringa_familiari,1,4))
                                        ,to_date(substr(w_stringa_familiari,5,8),'ddmmyyyy'),to_date(substr(w_stringa_familiari,13,8),'ddmmyyyy')
                                        ,trunc(sysdate)
                                        ,substr(w_dettaglio_faog,1,150)
                                        ,substr(w_dettaglio_faog_base,1,170)
                                        )
                                        ;
                          EXCEPTION
                             WHEN others THEN
                                 w_errore := 'Errore in inserimento Familiari_ogim di '
                                             ||w_cod_fiscale||' ('||SQLERRM||')';
                                     RAISE ERRORE;
                          END;
                       end if;
                       w_stringa_familiari := substr(w_stringa_familiari,21);
                       if w_dettaglio_faog is not null then
                          w_dettaglio_faog := '*'||rtrim(substr(w_dettaglio_faog,152));
                       end if;
                       if w_dettaglio_faog_base is not null then
                          w_dettaglio_faog_base := '*'||rtrim(substr(w_dettaglio_faog_base,172));
                       end if;
                    END LOOP;
                    --
                    -- (VD - 03/01/2018): in caso di limite sull'oggetto, il
                    --                    controllo veniva effettuato sempre
                    --                    sull'importo al netto delle addizionali,
                    --                    indipendentemente dal flag importo_lordo
                    --                    presente sul ruolo
                    --IF  w_importo < nvl(w_limite_ruolo,0)
                    IF  w_importo_ruolo < nvl(w_limite_ruolo,0)
                       and nvl(a_tipo_limite,' ') = 'O'       THEN
                       BEGIN
                         update oggetti_imposta
                            set ruolo                = null
                               ,importo_ruolo        = null
                               ,addizionale_eca      = null
                               ,maggiorazione_eca    = null
                               ,addizionale_pro      = null
                               ,iva                  = null
                          where ruolo = a_ruolo
                            and oggetto_imposta      = w_oggetto_imposta
                         ;
                       EXCEPTION
                         WHEN others THEN
                            w_errore := 'Errore in aggiornamento Oggetti Imposta '||
                                        'per '||w_cod_fiscale||' - ('||SQLERRM||')';
                            RAISE errore;
                       END;
                    ELSE
                       if w_rate > 0 then
                          if f_tratta_rate(w_rate
                                          ,w_anno_ruolo
                                          ,rec_ogpr.tipo_tributo
                                          ,w_imp_addizionale_eca
                                          ,w_imp_maggiorazione_eca
                                          ,w_imp_addizionale_pro
                                          ,w_magg_tares_ogim
                                          ,w_imp_aliquota
                                          ,w_importo
                                          ,w_oggetto_imposta
                                          ,rec_ogpr.conto_corrente
                                          ,rec_ogpr.cod_fiscale
                                          ,a_utente
                                          ,w_cod_istat
                                          ,w_rata_perequative
                                          ) = -1 then
                             w_errore := 'Errore in determinazione numero rate (1) '||
                                         'per '||w_cod_fiscale||' - ('||SQLERRM||')';
                             RAISE errore;
                          end if;
-- dbms_output.put_line('tratta rate: -1');
                       end if;
                       BEGIN
                          insert into ruoli_contribuente
                                (ruolo,cod_fiscale,oggetto_imposta
                                ,tributo,consistenza,importo
                                ,mesi_ruolo
                                ,utente,note
                                ,da_mese,a_mese
                                ,giorni_ruolo
                                ,importo_base
                                )
                          values(a_ruolo,rec_ogpr.cod_fiscale,w_oggetto_imposta
                                ,rec_ogpr.tributo,rec_ogpr.consistenza,w_importo_ruolo
                                ,decode(w_mesi_calcolo,0,null,round(w_periodo * 12))
                                ,a_utente,w_note_ogim
                                ,w_da_mese_ruolo,w_a_mese_ruolo
                                ,decode(w_mesi_calcolo,0,w_giorni_ruolo,null)
                                ,w_importo_ruolo_base
                                )
                          ;
                       EXCEPTION
                          WHEN others THEN
                             w_errore := 'Errore in inserimento Ruoli Contribuente (1) '||
                                         'per '||w_cod_fiscale||' - ('||SQLERRM||')';
                             RAISE errore;
                       END;
                    END IF;
                 end if;
              ELSIF w_chk_iscritto = -1 THEN
                 w_errore := 'Errore in lettura su Oggetti Imposta per '||w_cod_fiscale;
                 RAISE errore;
              END IF;
            END IF; -- rec_ogpr.flag_ruolo is not NULL
         end if;  -- w_da_trattare (personalizzazione di Malnate)
      END LOOP;
      --
      -- (VD - 22/11/2017): Pontedera - calcolo e applicazione sconti per conferimento
      -- (VD - 21/08/2018): Fiorano Modenese - calcolo e applicazione sconti per conferimento
      --
      if w_cod_istat in  ('050029','036013') then
         cer_conferimenti.determina_sconto_conf(w_anno_ruolo
                                               ,a_ruolo
                                               ,w_tipo_ruolo
                                               ,w_tipo_emissione
                                               ,a_cod_fiscale
                                               ,a_utente
                                               );
         applica_sconto_conf(w_anno_ruolo
                            ,a_ruolo
                            ,a_tipo_limite
                            ,w_limite_ruolo
                            ,w_rate
                            ,a_cod_fiscale
                            );
      end if;
   --------------------------------------------
   ---- Emissione ruolo suppletivo per VT  ----
   --------------------------------------------
   ELSIF w_tipo_ruolo = 2 THEN
    --dbms_output.put_line('Ruolo supplettivo');
      FOR rec_del_vt in sel_del_ogpr_vt
      LOOP
         BEGIN
            delete familiari_ogim             faog
             where oggetto_imposta             = rec_del_vt.oggetto_imposta
            ;
         EXCEPTION
            WHEN others THEN
               w_errore := 'Errore in eliminazione familiari_ogim per Ruolo Suppletivo'||
                           'per '||w_cod_fiscale||' - ('||SQLERRM||')';
               RAISE errore;
         END;
         BEGIN
            delete oggetti_imposta             ogim
             where oggetto_imposta             = rec_del_vt.oggetto_imposta
            ;
         EXCEPTION
            WHEN others THEN
               w_errore := 'Errore in eliminazione Oggetti Imposta per Ruolo Suppletivo'||
                           'per '||w_cod_fiscale||' - ('||SQLERRM||')';
               RAISE errore;
         END;
      END LOOP;
      IF w_ruolo_rif is not null THEN
         FOR rec_vt IN sel_ogpr_vt
         LOOP
           w_cod_fiscale := '(2) - '||rec_vt.cod_fiscale;
           w_periodo := rec_vt.mesi_ruolo;
           w_importo_pf := null;
           w_importo_pv := null;
           w_stringa_familiari := '';
           w_dettaglio_faog    := '';
           w_dettaglio_ogim    := '';
           IF a_flag_normalizzato is null THEN
              IF (nvl(rec_vt.consistenza,1) < rec_vt.limite)
               OR (rec_vt.limite is null)                         THEN
                 w_importo := f_round(nvl(rec_vt.consistenza,1)    *
                              nvl(rec_vt.tariffa,1) *
                              (nvl(rec_vt.perc_possesso,100) / 100) *
                              w_periodo / 12 , 1) - rec_vt.imposta;
              ELSE
                 w_importo := f_round((((nvl(rec_vt.consistenza,1) - rec_vt.limite) *
                                       nvl(rec_vt.tariffa_superiore,1) + rec_vt.limite *
                                       nvl(rec_vt.tariffa,1)) *
                                       (nvl(rec_vt.perc_possesso,100) / 100) *
                                       w_periodo / 12) , 1) - rec_vt.imposta;
              END IF;
           ELSE
            -- Il normalizzato tiene conto del periodo e percentuale di possesso.
              CALCOLO_IMPORTO_NORMALIZZATO(rec_vt.cod_fiscale
                                          ,null    -- ni
                                          ,w_anno_ruolo
                                          ,rec_vt.tributo
                                          ,rec_vt.categoria
                                          ,rec_vt.tipo_tariffa
                                          ,rec_vt.tariffa
                                          ,rec_vt.tariffa_quota_fissa
                                          ,rec_vt.consistenza
                                          ,rec_vt.perc_possesso
                                          ,rec_vt.inizio_decorrenza
                                          ,rec_vt.fine_decorrenza
                                          ,rec_vt.flag_ab_principale
                                          ,rec_vt.numero_familiari
                                          ,a_ruolo
                                          ,w_importo
                                          ,w_importo_pf
                                          ,w_importo_pv
                                          ,w_stringa_familiari
                                          ,w_dettaglio_ogim
                                          ,w_giorni_ruolo
                                          );
              if length(w_dettaglio_ogim) > 151 then
                 w_dettaglio_faog := w_dettaglio_ogim;
                 w_dettaglio_ogim := '';
              end if;
          -- Ricalcolo l'importo del principale per i mesi di validita' dell'oggetto  (Belluno) (Piero 12/08/2005)
              if w_cod_istat in ('058003' , '025006','082006' )  then
                 w_dal     := greatest(nvl(rec_vt.inizio_decorrenza,to_date('2222222','j'))
                                      ,to_date('0101'||lpad(to_char(w_anno_ruolo),4,'0'),'ddmmyyyy'));
                 w_al      := least(nvl(rec_vt.fine_decorrenza,to_date('3333333','j'))
                                       ,to_date('3112'||lpad(to_char(w_anno_ruolo),4,'0'),'ddmmyyyy'));
                 w_imposta    := nvl(rec_vt.imposta,0) * round(months_between(w_al + 1,w_dal)) / w_periodo;
                 w_imposta_pf := rec_vt.importo_pf * round(months_between(w_al + 1,w_dal)) / w_periodo;
                 w_imposta_pv := rec_vt.importo_pv * round(months_between(w_al + 1,w_dal)) / w_periodo;
                 w_periodo    := round(months_between(w_al + 1,w_dal));
                 w_imposta    := f_round(w_imposta,1);
                 w_imposta_pf := f_round(w_imposta_pf,1);
                 w_imposta_pv := f_round(w_imposta_pv,1);
              else
                 w_imposta    := nvl(rec_vt.imposta,0);
                 w_imposta_pf := rec_vt.importo_pf;
                 w_imposta_pv := rec_vt.importo_pv;
              end if;
              w_importo := w_importo - nvl(w_imposta,0);
              if rec_vt.importo_pf is not null and rec_vt.importo_pf is not null then
                 w_importo_pf := w_importo_pf - w_imposta_pf;
                 w_importo_pv := w_importo_pv - w_imposta_pv;
              else  --non inserisco importo_pf e importo_pv se non ci sono nel principale
                 w_importo_pf := null;
                 w_importo_pv := null;
              end if;
           END IF;   --    normalizzato
           IF w_importo > 0 THEN
              w_imp_addizionale_pro   := f_round(w_importo * w_addizionale_pro / 100,1);
              w_imp_addizionale_eca   := f_round(w_importo * w_addizionale_eca / 100,1);
              w_imp_maggiorazione_eca := f_round(w_importo * w_Maggiorazione_eca / 100,1);
              w_imp_aliquota          := f_round(w_importo * w_aliquota / 100,1);
              w_tot_addizionali       := w_imp_addizionale_pro
                                       + w_imp_addizionale_eca
                                       + w_imp_maggiorazione_eca
                                       + w_imp_aliquota;
              w_importo_ruolo         := w_importo + w_tot_addizionali;
              w_oggetto_imposta := null;
              oggetti_imposta_nr(w_oggetto_imposta);
--             -- maggiorazione tares
--             if w_flag_magg_anno is null then
--                w_coeff_gg := F_COEFF_GG(w_anno_ruolo,rec_vt.inizio_decorrenza,rec_vt.fine_decorrenza);
--                w_magg_tares_ogim := round(rec_vt.consistenza * w_maggiorazione_tares * (100 - rec_vt.perc_riduzione) / 100 * w_coeff_gg,2);
--             else
--                w_magg_tares_ogim := round(rec_vt.consistenza * w_maggiorazione_tares,2);
--             end if;
              BEGIN
                insert into oggetti_imposta
                      (oggetto_imposta,cod_fiscale,anno,oggetto_pratica,
                       imposta,ruolo,importo_ruolo,
                       addizionale_eca,maggiorazione_eca,
                       addizionale_pro,iva,flag_calcolo,utente,
                       importo_pf,importo_pv,aliquota_iva,dettaglio_ogim, tipo_tributo
                      )
                values(w_oggetto_imposta,rec_vt.cod_fiscale,w_anno_ruolo,
                       rec_vt.oggetto_pratica,w_importo,a_ruolo,w_importo_ruolo,
                       w_imp_addizionale_eca,w_imp_maggiorazione_eca,
                       w_imp_addizionale_pro,w_imp_aliquota,'S',a_utente,
                       w_importo_pf,w_importo_pv,w_aliquota_iva,w_dettaglio_ogim, w_tipo_tributo
                      )
                ;
              EXCEPTION
                WHEN others THEN
                   w_errore := 'Errore in inserimento Oggetti Imposta (vt) '||
                               'per '||w_cod_fiscale||' - ('||SQLERRM||')';
                   RAISE errore;
              END;
              WHILE length(w_stringa_familiari) > 19  LOOP
                 BEGIN
                    insert into familiari_ogim
                               (oggetto_imposta,numero_familiari
                               ,dal,al
                               ,data_variazione
                               ,dettaglio_faog
                               )
                         values(w_oggetto_imposta,to_number(substr(w_stringa_familiari,1,4))
                               ,to_date(substr(w_stringa_familiari,5,8),'ddmmyyyy'),to_date(substr(w_stringa_familiari,13,8),'ddmmyyyy')
                               ,trunc(sysdate)
                               ,substr(w_dettaglio_faog,1,150)
                               )
                               ;
                 EXCEPTION
                    WHEN others THEN
                        w_errore := 'Errore in inserimento Familiari_ogim di '
                                    ||w_cod_fiscale||' ('||SQLERRM||')';
                            RAISE ERRORE;
                 END;
                 w_stringa_familiari := substr(w_stringa_familiari,21);
                 w_dettaglio_faog    := substr(w_dettaglio_faog,151);
              END LOOP;
              IF  w_importo < nvl(w_limite_ruolo,0)
              and nvl(a_tipo_limite,' ') = 'O'        THEN
                 BEGIN
                    update oggetti_imposta
                       set ruolo             = null
                          ,importo_ruolo     = null
                          ,addizionale_eca   = null
                          ,maggiorazione_eca = null
                          ,addizionale_pro   = null
                          ,iva               = null
                     where ruolo             = a_ruolo
                       and   oggetto_imposta = w_oggetto_imposta
                    ;
                 EXCEPTION
                    WHEN others THEN
                       w_errore := 'Errore in aggiornamento Oggetti Imposta '||
                                   'per '||w_cod_fiscale||' - ('||SQLERRM||')';
                       RAISE errore;
                 END;
              ELSE
                 if w_rate > 0 then
                    if f_tratta_rate(w_rate
                                    ,w_anno_ruolo
                                    ,rec_vt.tipo_tributo
                                    ,w_imp_addizionale_eca
                                    ,w_imp_maggiorazione_eca
                                    ,w_imp_addizionale_pro
                                    ,0  -- w_magg_tares_ogim
                                    ,w_imp_aliquota
                                    ,w_importo
                                    ,w_oggetto_imposta
                                    ,rec_vt.conto_corrente
                                    ,rec_vt.cod_fiscale
                                    ,a_utente
                                    ,w_cod_istat
                                    ,w_rata_perequative
                                    ) = -1 then
                       w_errore := 'Errore in determinazione numero rate (vt) '||
                                   'per '||w_cod_fiscale||' - ('||SQLERRM||')';
                       RAISE errore;
                    end if;
                 end if;
                 BEGIN
                    insert into ruoli_contribuente
                          (ruolo,cod_fiscale,oggetto_imposta,tributo,consistenza,
                           importo,mesi_ruolo,utente,giorni_ruolo
                          )
                    values(a_ruolo,rec_vt.cod_fiscale,w_oggetto_imposta,
                           rec_vt.tributo,rec_vt.consistenza,w_importo_ruolo,
                           decode(w_mesi_calcolo,0,null,w_periodo),a_utente,
                           decode(w_mesi_calcolo,0,w_giorni_ruolo,null)
                          )
                    ;
                 EXCEPTION
                    WHEN others THEN
                       w_errore := 'Errore in inserimento Ruoli Contribuente (vt) '||
                                   'per '||w_cod_fiscale||' - ('||SQLERRM||')';
                       RAISE errore;
                 END;
              END IF;
           END IF;  -- w_importo > 0
         END LOOP;
      ------------------------------------
      ---- Emissione ruolo suppletivo ----
      ------------------------------------
      else
        --
        -- Tariffa puntuale - #77568
        --
        if w_tariffa_puntuale = 'S' then
          if w_tipo_emissione = 'T' then
            EMISSIONE_RUOLO_PUNTUALE(a_ruolo,a_utente,a_cod_fiscale,a_flag_richiamo,a_flag_iscritti_p,a_flag_normalizzato,a_tipo_limite,a_limite);
          end if;  -- Supplettivo Totale
        end if; -- Tariffa puntuale
        --
         -- dbms_output.put_line('Ruolo suppletivo: '||a_cod_fiscale);
         -- Ruolo suppletivo fino al 2012 oppure Bovezzo
         if w_anno_ruolo <= 2012 or w_cod_istat = '017025' then   -- Bovezzo
            FOR rec_ogpr IN sel_ogpr_2(a_ruolo
                                      ,a_cod_fiscale
                                      ,w_tipo_tributo
                                      ,w_anno_ruolo
                                      ,w_data_emissione
                                      ,a_flag_normalizzato
                                      )
            LOOP
              w_cod_fiscale := '(3) - '||rec_ogpr.cod_fiscale;
              w_importo := 0;
              w_importo_pf := null;
              w_importo_pv := null;
              w_stringa_familiari := '';
              w_dettaglio_faog    := '';
              w_dettaglio_ogim    := '';
              w_note_ogim         := '';
              w_importo_base := 0;
              w_importo_pf_base := null;
              w_importo_pv_base := null;
              w_stringa_familiari_base := '';
              w_dettaglio_faog_base    := '';
              w_dettaglio_ogim_base    := '';
              w_note_ogim_base         := '';
              w_data_cessazione := rec_ogpr.fine_decorrenza;
              w_da_trattare := TRUE;
              if w_cod_istat = '012096' and w_tipo_tributo = 'TARSU' and w_anno_ruolo = 2006 then
                  if nvl(rec_ogpr.fine_decorrenza,to_date('31122006','ddmmyyyy')) > to_date('30062006','ddmmyyyy') then
                     w_data_cessazione := to_date('30062006','ddmmyyyy');
                  else
                     w_data_cessazione := rec_ogpr.fine_decorrenza;
                  end if;
                  if nvl(rec_ogpr.inizio_decorrenza,to_date('01012006','ddmmyyyy')) > to_date('30062006','ddmmyyyy') then
                     w_da_trattare := FALSE;
                  else
                     w_da_trattare := TRUE;
                  end if;
              end if;
              if w_da_trattare then  -- se non è da trattare passo al prossimo oggetto
                 if  (w_cod_istat ='037054') then -- San lazzaro
                  -- Il periodo viene calcolato sempre come normalizzato,
                  -- in questo modo può essere anche a giorni
                    w_periodo := f_periodo(w_anno_ruolo
                                          ,rec_ogpr.inizio_decorrenza
                                          ,w_data_cessazione
                                          ,rec_ogpr.tipo_occupazione
                                          ,w_tipo_tributo
                                          ,'S'    --flag_normalizzato
                                          );
                 else
                    w_periodo := f_periodo(w_anno_ruolo
                                          ,rec_ogpr.inizio_decorrenza
                                          ,w_data_cessazione
                                          ,rec_ogpr.tipo_occupazione
                                          ,w_tipo_tributo
                                          ,a_flag_normalizzato
                                          );
                 end if;
                 IF a_flag_normalizzato is null THEN
                    w_tratta_sgravio := 1; -- Sgravio sempre trattato per il NON Normalizzato
                    IF (nvl(rec_ogpr.consistenza,1) < rec_ogpr.limite)
                    or (rec_ogpr.limite is null)                         THEN
                       w_importo := rec_ogpr.consistenza * rec_ogpr.tariffa;
                    ELSE
                       w_importo := rec_ogpr.limite * rec_ogpr.tariffa +
                                    (rec_ogpr.consistenza - rec_ogpr.limite) * rec_ogpr.tariffa_superiore;
                    END IF;
                    w_importo := f_round(w_importo * (nvl(rec_ogpr.perc_possesso,100) / 100)
                                         * w_periodo , 1);
                 ELSE
                 -- Il normalizzato tiene conto del periodo e percentuale di possesso.
                 -- (VD - 04/01/2019): sostituita procedure CALCOLO_IMPORTO_NORMALIZZATO
                 --                    con CALCOLO_IMPORTO_NORM_TARIFFE per
                 --                    calcolo ruoli con tariffe
                    CALCOLO_IMPORTO_NORM_TARIFFE(rec_ogpr.cod_fiscale
                                                ,null  -- ni
                                                ,w_anno_ruolo
                                                ,rec_ogpr.tributo
                                                ,rec_ogpr.categoria
                                                ,rec_ogpr.tipo_tariffa
                                                ,rec_ogpr.tariffa
                                                ,rec_ogpr.tariffa_quota_fissa
                                                ,rec_ogpr.consistenza
                                                ,rec_ogpr.perc_possesso
                                                ,rec_ogpr.inizio_decorrenza
                                                ,w_data_cessazione    --rec_ogpr.fine_decorrenza
                                                ,rec_ogpr.flag_ab_principale
                                                ,rec_ogpr.numero_familiari
                                                ,a_ruolo
                                                ,to_number(null)      -- oggetto
                                                ,rec_ogpr.tipo_tariffa_base
                                                ,w_importo
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
                                                ,w_giorni_ruolo
                                                );
                    if length(w_dettaglio_ogim) > 151 then
                       w_dettaglio_faog := w_dettaglio_ogim;
                       w_dettaglio_ogim := '';
                    end if;
                    if length(w_dettaglio_ogim_base) > 171 then
                       w_dettaglio_faog_base := w_dettaglio_ogim_base;
                       w_dettaglio_ogim_base := '';
                    end if;
                    -- Verifico se applicare lo sgravio
                    -- w_tratta_sgravio = 1   Sgravio trattato
                    -- w_tratta_sgravio = 0   Sgravio NON trattato
                    w_tratta_sgravio := 0;
                    if rec_ogpr.data_ogva                   <= w_data_emissione then
                       begin
                         select nvl(max(data_emissione),rec_ogpr.data_ogva - 1)
                           into w_data_emissione_ruolo_prec
                           from ruoli
                          where anno_ruolo            = w_anno_ruolo
                            and ruolo                <> a_ruolo
                            and invio_consorzio      is not null
                            and tipo_tributo          = w_tipo_tributo
                         ;
                       exception
                         when others then
                           w_data_emissione_ruolo_prec := rec_ogpr.data_ogva - 1;
                       end;
                       if rec_ogpr.tipo_pratica||nvl(rec_ogpr.flag_adesione,'N') = 'AN' then
                          w_data_validita := rec_ogpr.data_notifica  + 60;
                       elsif rec_ogpr.tipo_pratica||nvl(rec_ogpr.flag_adesione,'N') = 'AS' then
                          w_data_validita := rec_ogpr.data_notifica;
                       else
                          w_data_validita := rec_ogpr.data_ogva;
                       end if;
                       if w_data_validita > w_data_emissione_ruolo_prec then
                          w_tratta_sgravio := 1;
                       end if;
                    end if;
                 END IF;
                 --
                 -- (VD - 23/10/2018): Determinazione importi con tariffa base
                 --
                 /*if w_flag_tariffa_base = 'S' and rec_ogpr.tipo_tariffa_base is not null then
                    determina_importi_base(rec_ogpr.cod_fiscale
                                          ,w_anno_ruolo
                                          ,a_ruolo
                                          ,rec_ogpr.tributo
                                          ,rec_ogpr.categoria
                                          ,rec_ogpr.tipo_tariffa_base
                                          ,a_flag_normalizzato
                                          ,rec_ogpr.consistenza
                                          ,rec_ogpr.perc_possesso
                                          ,w_periodo
                                          ,rec_ogpr.inizio_decorrenza
                                          ,w_data_cessazione    --rec_ogpr.data_cessazione
                                          ,rec_ogpr.flag_ab_principale
                                          ,rec_ogpr.numero_familiari
                                          ,w_importo_base
                                          ,w_importo_pf_base
                                          ,w_importo_pv_base
                                          ,w_stringa_familiari_base
                                          ,w_dettaglio_ogim_base
                                          ,w_giorni_ruolo
                                          );
                    if length(w_dettaglio_ogim_base) > 171 then
                       w_dettaglio_faog_base := w_dettaglio_ogim_base;
                       w_dettaglio_ogim_base := '';
                    end if;
                 end if;  */
-- dbms_output.put_line('Parametri di f_importo_da_scalare');
-- dbms_output.put_line('Ruolo '||to_char(a_ruolo)||' Cf '||rec_ogpr.cod_fiscale||' Anno '||to_char(w_anno_ruolo));
-- dbms_output.put_line('TRATTA SGRAVIO '||w_tratta_sgravio||' '||
-- ' Dal '||to_char(rec_ogpr.inizio_decorrenza,'dd/mm/yyyy')||' Al '||to_char(w_data_cessazione,'dd/mm/yyyy')||
-- ' titr '||w_tipo_tributo||' Ogpr Rif '||to_char(rec_ogpr.oggetto_pratica_rif)||' Norm '||a_flag_normalizzato);
               --  Occorre scalare l`eventuale importo gia` pagato con il ruolo principale,
               --  quando l`inizio_decorrenza dell OGPR in esame si sovrappone con la
               --  validita` dell OGPR (riferito allo stesso oggetto) inserito in un RUOLO
               --  precedente.
               -- Bovezzo suppletivo (solo dopo il secondo principale e solo un suppletivo per ogpr)
                 if w_cod_istat = '017025' and w_tipo_tributo = 'TARSU' and w_anno_ruolo > 2007 then
                    w_imp_scalare := f_round(f_importo_da_scalare_sup2s(a_ruolo
                                                                       ,rec_ogpr.cod_fiscale
                                                                       ,w_anno_ruolo
                                                                       ,rec_ogpr.inizio_decorrenza
                                                                       ,w_data_cessazione    --rec_ogpr.fine_decorrenza
                                                                       ,w_tipo_tributo
                                                                       ,rec_ogpr.oggetto_pratica_rif
                                                                       ,a_flag_normalizzato
                                                                       ,'TOT'
                                                                       ,w_tratta_sgravio
                                                                       ),1
                                            );
                    w_imp_scalare_pf := f_round(f_importo_da_scalare_sup2s(a_ruolo
                                                                       ,rec_ogpr.cod_fiscale
                                                                       ,w_anno_ruolo
                                                                       ,rec_ogpr.inizio_decorrenza
                                                                       ,w_data_cessazione    --rec_ogpr.fine_decorrenza
                                                                       ,w_tipo_tributo
                                                                       ,rec_ogpr.oggetto_pratica_rif
                                                                       ,a_flag_normalizzato
                                                                       ,'PF'
                                                                       ,w_tratta_sgravio
                                                                       ),1
                                            );
                    w_imp_scalare_pv := f_round(f_importo_da_scalare_sup2s(a_ruolo
                                                                       ,rec_ogpr.cod_fiscale
                                                                       ,w_anno_ruolo
                                                                       ,rec_ogpr.inizio_decorrenza
                                                                       ,w_data_cessazione    --rec_ogpr.fine_decorrenza
                                                                       ,w_tipo_tributo
                                                                       ,rec_ogpr.oggetto_pratica_rif
                                                                       ,a_flag_normalizzato
                                                                       ,'PV'
                                                                       ,w_tratta_sgravio
                                                                       ),1
                                            );
                    if w_flag_tariffa_base = 'S' or
                       w_flag_ruolo_tariffa = 'S' then
                       w_imp_scalare_base := f_round(f_importo_da_scalare_sup2s(a_ruolo
                                                                          ,rec_ogpr.cod_fiscale
                                                                          ,w_anno_ruolo
                                                                          ,rec_ogpr.inizio_decorrenza
                                                                          ,w_data_cessazione    --rec_ogpr.fine_decorrenza
                                                                          ,w_tipo_tributo
                                                                          ,rec_ogpr.oggetto_pratica_rif
                                                                          ,a_flag_normalizzato
                                                                          ,'TOTB'
                                                                          ,w_tratta_sgravio
                                                                          ),1
                                               );
                       w_imp_scalare_pf_base := f_round(f_importo_da_scalare_sup2s(a_ruolo
                                                                          ,rec_ogpr.cod_fiscale
                                                                          ,w_anno_ruolo
                                                                          ,rec_ogpr.inizio_decorrenza
                                                                          ,w_data_cessazione    --rec_ogpr.fine_decorrenza
                                                                          ,w_tipo_tributo
                                                                          ,rec_ogpr.oggetto_pratica_rif
                                                                          ,a_flag_normalizzato
                                                                          ,'PFB'
                                                                          ,w_tratta_sgravio
                                                                          ),1
                                               );
                       w_imp_scalare_pv_base := f_round(f_importo_da_scalare_sup2s(a_ruolo
                                                                          ,rec_ogpr.cod_fiscale
                                                                          ,w_anno_ruolo
                                                                          ,rec_ogpr.inizio_decorrenza
                                                                          ,w_data_cessazione    --rec_ogpr.fine_decorrenza
                                                                          ,w_tipo_tributo
                                                                          ,rec_ogpr.oggetto_pratica_rif
                                                                          ,a_flag_normalizzato
                                                                          ,'PVB'
                                                                          ,w_tratta_sgravio
                                                                          ),1
                                               );
                    else
                       w_imp_scalare_base    := to_number(null);
                       w_imp_scalare_pf_base := to_number(null);
                       w_imp_scalare_pv_base := to_number(null);
                    end if;
                 else
                    /*w_imp_scalare := f_round(f_importo_da_scalare(a_ruolo
                                                                 ,rec_ogpr.cod_fiscale
                                                                 ,w_anno_ruolo
                                                                 ,rec_ogpr.inizio_decorrenza
                                                                 ,w_data_cessazione    --rec_ogpr.fine_decorrenza
                                                                 ,w_tipo_tributo
                                                                 ,rec_ogpr.oggetto_pratica_rif
                                                                 ,a_flag_normalizzato
                                                                 ,'TOT'
                                                                 ,w_tratta_sgravio
                                                                 ),1
                                            );
                    w_imp_scalare_pf := f_round(f_importo_da_scalare(a_ruolo
                                                              ,rec_ogpr.cod_fiscale
                                                              ,w_anno_ruolo
                                                              ,rec_ogpr.inizio_decorrenza
                                                              ,w_data_cessazione   --rec_ogpr.fine_decorrenza
                                                              ,w_tipo_tributo
                                                              ,rec_ogpr.oggetto_pratica_rif
                                                              ,a_flag_normalizzato
                                                              ,'PF'
                                                              ,w_tratta_sgravio
                                                              ),1
                                               );
                    w_imp_scalare_pv := f_round(f_importo_da_scalare(a_ruolo
                                                              ,rec_ogpr.cod_fiscale
                                                              ,w_anno_ruolo
                                                              ,rec_ogpr.inizio_decorrenza
                                                              ,w_data_cessazione    --rec_ogpr.fine_decorrenza
                                                              ,w_tipo_tributo
                                                              ,rec_ogpr.oggetto_pratica_rif
                                                              ,a_flag_normalizzato
                                                              ,'PV'
                                                              ,w_tratta_sgravio
                                                              ),1
                                              ); */
                    determina_importi_da_scalare(a_ruolo
                                                ,rec_ogpr.cod_fiscale
                                                ,w_anno_ruolo
                                                ,rec_ogpr.inizio_decorrenza
                                                ,w_data_cessazione    --rec_ogpr.fine_decorrenza
                                                ,w_tipo_tributo
                                                ,rec_ogpr.oggetto_pratica_rif
                                                ,a_flag_normalizzato
                                                ,w_tratta_sgravio
                                                ,w_flag_tariffa_base
                                                ,w_flag_ruolo_tariffa
                                                ,w_imp_scalare
                                                ,w_imp_scalare_pf
                                                ,w_imp_scalare_pv
                                                ,w_imp_scalare_base
                                                ,w_imp_scalare_pf_base
                                                ,w_imp_scalare_pv_base
                                                );
                 end if;
--                dbms_output.put_line('Importo = '||to_char(w_importo)||' Importo da Scalare = '||to_char(w_imp_scalare));
                 w_importo      := w_importo - nvl(w_imp_scalare,0);
                 w_importo_base := w_importo_base - nvl(w_imp_scalare_base,0);
--                dbms_output.put_line('Importo = '||to_char(w_importo)||' Importo da Scalare = '||to_char(w_imp_scalare));
                 IF w_importo > 0 THEN
                    w_imp_addizionale_pro   := f_round(w_importo * w_addizionale_pro / 100,1);
                    w_imp_addizionale_eca   := f_round(w_importo * w_addizionale_eca / 100,1);
                    w_imp_maggiorazione_eca := f_round(w_importo * w_Maggiorazione_eca / 100,1);
                    w_imp_aliquota          := f_round(w_importo * w_aliquota / 100,1);
                    if w_cod_istat = '037048' then  -- Pieve di Cento
                       w_importo               := round(w_importo,0);
                       w_imp_addizionale_pro   := round(w_imp_addizionale_pro,0);
                       w_imp_addizionale_eca   := round(w_imp_addizionale_eca,0);
                       w_imp_maggiorazione_eca := round(w_imp_maggiorazione_eca,0);
                       w_imp_aliquota          := round(w_imp_aliquota,0);
                    end if;
                    w_tot_addizionali       := w_imp_addizionale_pro
                                             + w_imp_addizionale_eca
                                             + w_imp_maggiorazione_eca
                                             + w_imp_aliquota;
                    w_importo_ruolo         := w_importo + w_tot_addizionali;
                    if w_imp_scalare_pf = -1 then
                       w_importo_pf := null;
                    else
                       w_importo_pf := w_importo_pf - nvl(w_imp_scalare_pf,0);
                    end if;
                    if w_imp_scalare_pv = -1 then
                       w_importo_pv := null;
                    else
                       w_importo_pv := w_importo_pv - nvl(w_imp_scalare_pv,0);
                    end if;
                    if w_importo_pf < 0 or w_importo_pv < 0 then
                       w_importo_pv := 0;
                       w_importo_pf := 0;
                    end if;
                    if nvl(w_imp_scalare,0) > 0 then
                       --
                       -- (VD - 18/01/2018): Memorizzazione importo da scalare in campo note anziche in dettaglio_ogim
                       --
                       --w_dettaglio_faog := '';
                       --w_dettaglio_ogim := lpad(nvl(translate(ltrim(to_char(nvl(w_imp_scalare,0),'99,999,999,990.00')),'.,',',.'),' '),17,' ');
                       w_note_ogim    := 'Importo calcolato: '||to_char(w_importo)||' - Importo da scalare: '||to_char(nvl(w_imp_scalare,0));
                    end if;
                   -- maggiorazione tares
                   -- if w_flag_magg_anno is null then
                   --    w_coeff_gg := F_COEFF_GG(w_anno_ruolo,rec_ogpr.inizio_decorrenza,w_data_cessazione);
                   --    w_magg_tares_ogim := round(rec_ogpr.consistenza * w_maggiorazione_tares * (100 - rec_ogpr.perc_riduzione) / 100 * w_coeff_gg,2);
                   -- else
                   --    w_magg_tares_ogim := round(rec_ogpr.consistenza * w_maggiorazione_tares,2);
                   -- end if;
                    if (w_flag_tariffa_base = 'S' or w_flag_ruolo_tariffa = 'S') and
                       nvl(w_importo_base,0) > 0 then
                       w_imp_add_pro_base   := f_round(w_importo_base * w_addizionale_pro / 100,1);
                       w_imp_add_eca_base   := f_round(w_importo_base * w_addizionale_eca / 100,1);
                       w_imp_magg_eca_base  := f_round(w_importo_base * w_Maggiorazione_eca / 100,1);
                       w_imp_aliquota_base  := f_round(w_importo_base * w_aliquota / 100,1);
                       w_tot_addizionali_base := w_imp_add_pro_base
                                               + w_imp_add_eca_base
                                               + w_imp_magg_eca_base
                                               + w_imp_aliquota_base;
                       w_importo_ruolo_base  := w_importo_base + w_tot_addizionali_base;
                       if w_imp_scalare_pf_base = -1 then
                          w_importo_pf_base := to_number(null);
                       else
                          w_importo_pf_base := w_importo_pf_base - nvl(w_imp_scalare_pf_base,0);
                       end if;
                       if w_imp_scalare_pv_base = -1 then
                          w_importo_pv_base := to_number(null);
                       else
                          w_importo_pv_base := w_importo_pv_base - nvl(w_imp_scalare_pv_base,0);
                       end if;
                       if w_importo_pf_base < 0 or w_importo_pv_base < 0 then
                          w_importo_pv_base := 0;
                          w_importo_pf_base := 0;
                       end if;
                       if nvl(w_imp_scalare_base,0) > 0 then
                          w_note_ogim := w_note_ogim||' - Importo calcolato base: '||to_char(w_importo_base)||' - Importo da scalare base: '||to_char(nvl(w_imp_scalare_base,0));
                       end if;
                    end if;
                    --
                    -- (VD - 20/03/2019): Modifica calcolo dettaglio_ogim per
                    --                    gestione tariffe
                    --
                    if w_dettaglio_ogim is not null then
                       w_dettaglio_ogim := '*'||substr(w_dettaglio_ogim,2,1999);
                    end if;
                    if w_dettaglio_ogim_base is not null then
                       w_dettaglio_ogim_base := '*'||substr(w_dettaglio_ogim_base,2,1999);
                    end if;
                    if w_dettaglio_faog is not null then
                       w_dettaglio_faog := '*'||substr(w_dettaglio_faog,2,1999);
                    end if;
                    if w_dettaglio_faog_base is not null then
                       w_dettaglio_faog_base := '*'||substr(w_dettaglio_faog_base,2,1999);
                    end if;
                    w_oggetto_imposta := null;
                    oggetti_imposta_nr(w_oggetto_imposta);
                    BEGIN
                      insert into oggetti_imposta
                            (oggetto_imposta,cod_fiscale,anno,oggetto_pratica,
                             imposta,ruolo,importo_ruolo,addizionale_eca,
                             maggiorazione_eca,addizionale_pro,iva,flag_calcolo,utente,
                             aliquota_iva,importo_pf,importo_pv,dettaglio_ogim,tipo_tributo,
                             note,
                             tipo_tariffa_base, imposta_base,
                             addizionale_eca_base, maggiorazione_eca_base,
                             addizionale_pro_base, iva_base, importo_pf_base,
                             importo_pv_base, importo_ruolo_base, dettaglio_ogim_base,
                             perc_riduzione_pf, perc_riduzione_pv,
                             importo_riduzione_pf, importo_riduzione_pv
                            )
                      values(w_oggetto_imposta,rec_ogpr.cod_fiscale,w_anno_ruolo,
                             rec_ogpr.oggetto_pratica,w_importo,a_ruolo,w_importo_ruolo,
                             w_imp_addizionale_eca,w_imp_maggiorazione_eca,
                             w_imp_addizionale_pro,w_imp_aliquota,'S',a_utente,
                             w_aliquota_iva,w_importo_pf,w_importo_pv,w_dettaglio_ogim,w_tipo_tributo,
                             w_note_ogim,
                             rec_ogpr.tipo_tariffa_base, w_importo_base,
                             w_imp_add_eca_base, w_imp_magg_eca_base,
                             w_imp_add_pro_base, w_imp_aliquota_base, w_importo_pf_base,
                             w_importo_pv_base, w_importo_ruolo_base, w_dettaglio_ogim_base,
                             w_perc_rid_pf, w_perc_rid_pv,
                             w_importo_pf_rid, w_importo_pv_rid
                            )
                      ;
                    EXCEPTION
                      WHEN others THEN
                         w_errore := 'Errore in inserimento Oggetti Imposta (2) '||
                                     'per '||w_cod_fiscale||' - ('||SQLERRM||')';
                         RAISE errore;
                    END;
                    WHILE length(w_stringa_familiari) > 19  LOOP
                       BEGIN
                         insert into familiari_ogim
                                    (oggetto_imposta,numero_familiari
                                    ,dal,al
                                    ,data_variazione
                                    ,dettaglio_faog
                                    ,dettaglio_faog_base
                                    )
                              values(w_oggetto_imposta,to_number(substr(w_stringa_familiari,1,4))
                                    ,to_date(substr(w_stringa_familiari,5,8),'ddmmyyyy'),to_date(substr(w_stringa_familiari,13,8),'ddmmyyyy')
                                    ,trunc(sysdate)
                                    --,substr(w_dettaglio_faog,1,192)
                                    ,substr(w_dettaglio_faog,1,150)         -- (VD - 19/01/2016)
                                    ,substr(w_dettaglio_faog_base,1,170)
                                    )
                                    ;
                       EXCEPTION
                         WHEN others THEN
                             w_errore := 'Errore in inserimento Familiari_ogim (2) di '
                                         ||w_cod_fiscale||' ('||SQLERRM||')';
                                 RAISE ERRORE;
                       END;
                       w_stringa_familiari   := substr(w_stringa_familiari,21);
                       if w_dettaglio_faog is not null then
                          w_dettaglio_faog := '*'||rtrim(substr(w_dettaglio_faog,152));
                       end if;
                       if w_dettaglio_faog_base is not null then
                          w_dettaglio_faog_base := '*'||rtrim(substr(w_dettaglio_faog_base,172));
                       end if;
                    END LOOP;
                    IF  w_importo < nvl(w_limite_ruolo,0)
                    and nvl(a_tipo_limite,' ') = 'O'             THEN
                       BEGIN
                          update oggetti_imposta
                             set ruolo             = null
                                ,importo_ruolo     = null
                                ,addizionale_eca   = null
                                ,maggiorazione_eca = null
                                ,addizionale_pro   = null
                                ,iva               = null
                           where ruolo             = a_ruolo
                             and oggetto_imposta   = w_oggetto_imposta
                          ;
                       EXCEPTION
                          WHEN others THEN
                             w_errore := 'Errore in aggiornamento Oggetti Imposta '||
                                         'per '||w_cod_fiscale||' - ('||SQLERRM||')';
                             RAISE errore;
                       END;
                    ELSE
                       if w_rate > 0 then
                          if f_tratta_rate(w_rate
                                          ,w_anno_ruolo
                                          ,rec_ogpr.tipo_tributo
                                          ,w_imp_addizionale_eca
                                          ,w_imp_maggiorazione_eca
                                          ,w_imp_addizionale_pro
                                          ,0  -- w_magg_tares_ogim
                                          ,w_imp_aliquota
                                          ,w_importo
                                          ,w_oggetto_imposta
                                          ,rec_ogpr.conto_corrente
                                          ,rec_ogpr.cod_fiscale
                                          ,a_utente
                                          ,w_cod_istat
                                          ,w_rata_perequative
                                          ) = -1 then
                             w_errore := 'Errore in determinazione numero rate (2) '||
                                         'per '||w_cod_fiscale||' - ('||SQLERRM||')';
                             RAISE errore;
                          end if;
                       end if;
                       BEGIN
                          insert into ruoli_contribuente
                                (ruolo,cod_fiscale,oggetto_imposta,tributo,consistenza,
                                 importo,mesi_ruolo,utente,giorni_ruolo,
                                 importo_base
                                )
                          values(a_ruolo,rec_ogpr.cod_fiscale,w_oggetto_imposta,
                                 rec_ogpr.tributo,rec_ogpr.consistenza,w_importo_ruolo,
                                 decode(w_mesi_calcolo,0,null,f_round(w_periodo * 12,0)),a_utente,
                                 decode(w_mesi_calcolo,0,w_giorni_ruolo,null),
                                 w_importo_ruolo_base
                                )
                          ;
                       EXCEPTION
                          WHEN others THEN
                             w_errore := 'Errore in inserimento Ruoli Contribuente (2) '||
                                         'per '||w_cod_fiscale||' - ('||SQLERRM||')';
                             RAISE errore;
                       END;
                    END IF;
                 END IF;  -- w_importo > 0
              end if;  -- personalizzazione di Malnate
            END LOOP;
         /*
              Per ora se il ruolo e` importo e` lordo non si trattano gli accertamenti
         */
            IF w_importo_lordo is null THEN
               FOR rec_ogpr IN sel_ogpr_acce LOOP
                  w_cod_fiscale := '(4) - '||rec_ogpr.cod_fiscale;
                  if rec_ogpr.importo >= 0 then
                     BEGIN
                        insert into ruoli_contribuente
                              (ruolo,cod_fiscale,pratica,tributo,importo,utente)
                        values(a_ruolo,rec_ogpr.cod_fiscale,rec_ogpr.pratica,
                               rec_ogpr.tributo,rec_ogpr.importo,a_utente
                              )
                        ;
                     EXCEPTION
                        WHEN others THEN
                           w_errore := 'Errore in inserimento Ruoli Contribuente '||
                                       '(Ruolo per Accertamento) '||
                                       ' per '||w_cod_fiscale||' - ('||SQLERRM||')';
                           RAISE errore;
                     END;
                  /*
                       Se il Codice ISTAT del comune corrisponde a 036040 (SASSUOLO),
                       si applica la personalizzazione con addizionale provinciale.
                  */
                  -- BEGIN
                  --    update sanzioni_pratica
                  --       set ruolo         = a_ruolo
                  --          ,importo_ruolo = decode(cod_sanzione
                  --                                 ,'1'  ,importo
                  --                                 ,'101',importo
                  --                                 ,'99' ,importo
                  --                                 ,'199',importo
                  --                                 ,decode(w_cod_istat
                  --                                        ,'036040',f_round(importo *
                  --                                                  (100 + w_addizionale_pro) /
                  --                                                   100,0)
                  --                                                 ,importo
                  --                                        )
                  --                                 )
                  --     where pratica       = rec_ogpr.pratica
                  --    ;
                  -- EXCEPTION
                  --    WHEN others THEN
                  --       w_errore := 'Errore in aggiornamento Sanzioni Pratica '||
                  --                   '(Ruolo per Accertamento)'||
                  --                   'per '||w_cod_fiscale||' - ('||SQLERRM||')';
                  --       RAISE errore;
                  -- END;
                     BEGIN
                        update sanzioni_pratica
                           set ruolo         = a_ruolo
                              ,importo_ruolo = importo
                         where pratica       = rec_ogpr.pratica
                        ;
                     EXCEPTION
                        WHEN others THEN
                           w_errore := 'Errore in aggiornamento Sanzioni Pratica '||
                                       '(Ruolo per Accertamento)'||
                                       'per '||w_cod_fiscale||' - ('||SQLERRM||')';
                           RAISE errore;
                     END;
                  end if; -- rec_ogpr.importo > 0
               END LOOP; -- rec_ogpr IN sel_ogpr_acce
            END IF; -- Importo Lordo del Ruolo
         else
            -- Gestione del suppletivo per 2013 o successivo
            if w_tipo_emissione = 'T' then
            -- Il flag_incentivo mi indica che non ho ancora applicato l'incentivo TARSU
               w_flag_incentivo:= 'N';
               FOR rec_ogpr IN sel_ogpr_validi (w_anno_ruolo
                                               ,a_cod_fiscale
                                               ,w_tipo_tributo
                                               ,'P'
                                               ,w_data_emissione
                                               )
               LOOP
--                eliminazione_sgravi_ruolo(rec_ogpr.cod_fiscale, a_ruolo, w_anno_ruolo, 'TARSU', w_tipo_emissione, w_tipo_ruolo,'S');
                  eliminazione_sgravi_ruolo(rec_ogpr.cod_fiscale, a_ruolo, w_anno_ruolo, 'TARSU', w_tipo_emissione, w_tipo_ruolo);
                  --
                  -- (VD - 30/04/2015): Oltre agli sgravi automatici, si eliminano anche le compensazioni
                  --                    automatiche (come viene fatto per i ruoli principali)
                  --
                  begin
                     delete compensazioni_ruolo
                      where cod_fiscale = rec_ogpr.cod_fiscale
                         and ruolo = a_ruolo
                         and motivo_compensazione = 99
                         and flag_automatico = 'S'
                        ;
                  EXCEPTION
                     WHEN others THEN
                        w_errore := 'Errore in eliminazione Compensazioni Ruolo '||
                                    'per '||w_cod_fiscale||' - ('||SQLERRM||')';
                        RAISE errore;
                  end;
                  if w_cod_fiscale_magg <> rec_ogpr.cod_fiscale then
                     Oggetti_tab.DELETE;
                     --
                     -- (VD - 16/11/2016): - Sperimentazione Poasco
                     --                      Si annullano i dati del ruolo
                     --                      registrati nella tabella CONFERIMENTI
                     -- Nota: l'annullamento viene fatto in questo punto per evitare
                     --       che, in presenza di piu oggetti per lo stesso
                     --       codice fiscale, se l'ultimo non da diritto a
                     --       sconti, si annullino gli eventuali sconti gia'
                     --       calcolati
                     --
                     begin
                        update conferimenti
                           set ruolo = null
                             , importo_scalato = null
                         where cod_fiscale = rec_ogpr.cod_fiscale
                           and anno = w_anno_ruolo
                           and ruolo = a_ruolo
                           ;
                     EXCEPTION
                        WHEN others THEN
                           w_errore := 'Errore in annullamento sconti conferimento '||
                                       'per '||w_cod_fiscale||' - ('||SQLERRM||')';
                           RAISE errore;
                     end;
                     w_cod_fiscale_magg := rec_ogpr.cod_fiscale;
                  end if;
                  w_data_cessazione := rec_ogpr.data_cessazione;
                  -- Il flag_incentivo mi indica che non ho ancora applicato l'incentivo TARSU
                  if w_cod_fiscale <> '(1) - '||rec_ogpr.cod_fiscale then
                     w_flag_incentivo:= 'N';
                  end if;
                  w_cod_fiscale := '(1) - '||rec_ogpr.cod_fiscale;
                  IF rec_ogpr.flag_ruolo is not null THEN
                     w_importo := 0;
                     w_importo_pf := null;
                     w_importo_pv := null;
                     w_stringa_familiari    := '';
                     w_dettaglio_ogim     := '';
                     w_dettaglio_faog     := '';
                     w_importo_base := 0;
                     w_importo_pf_base := null;
                     w_importo_pv_base := null;
                     w_stringa_familiari_base := '';
                     w_dettaglio_ogim_base    := '';
                     w_dettaglio_faog_base    := '';
                     if (w_cod_istat ='037054') then -- San lazzaro
                        -- Il periodo viene calcolato sempre come normalizzato,
                        -- in questo modo può essere anche a giorni
                        w_periodo := f_periodo(w_anno_ruolo
                                              ,rec_ogpr.data_decorrenza
                                              ,w_data_cessazione    --rec_ogpr.data_cessazione
                                              ,'P'
                                              ,w_tipo_tributo
                                              ,'S'  -- flag_normalizzato
                                              );
                        w_giorni_ruolo := least(nvl(rec_ogpr.data_cessazione,to_date('3333333','j')),
                                                to_date('3112'||lpad(to_char(w_anno_ruolo),4,'0'),'ddmmyyyy'))
                                                - greatest(nvl(rec_ogpr.data_decorrenza,to_date('2222222','j')),
                                                           to_date('0101'||lpad(to_char(w_anno_ruolo),4,'0'),'ddmmyyyy'))
                                          + 1;
                     else
                        w_periodo := f_periodo(w_anno_ruolo
                                              ,rec_ogpr.data_decorrenza
                                              ,w_data_cessazione    --rec_ogpr.data_cessazione
                                              ,'P'
                                              ,w_tipo_tributo
                                              ,a_flag_normalizzato
                                              );
                     end if;
                     w_da_mese_ruolo  := to_number(to_char(
                                                 greatest(
                                                   nvl(rec_ogpr.data_decorrenza
                                                      ,to_date('0101'||to_char(w_anno_ruolo),'ddmmyyyy'))
                                                         ,to_date('0101'||to_char(w_anno_ruolo),'ddmmyyyy'))
                                                              ,'mm'));
                     if     a_flag_normalizzato is not null
                     and rec_ogpr.data_decorrenza is not null
                     and to_number(to_char(rec_ogpr.data_decorrenza,'yyyy')) = w_anno_ruolo then
                         if to_number(to_char(rec_ogpr.data_decorrenza,'dd')) > 15 and
                            -- (VD - 19/06/2017): Corretto calcolo da_mese ruolo per mese = 12
                            w_da_mese_ruolo < 12 then
                            w_da_mese_ruolo  := w_da_mese_ruolo + 1;
                         end if;
                     end if;
                     w_a_mese_ruolo   := greatest(least((w_da_mese_ruolo + (w_periodo*12) - 1),12)  -- 12/11/2013 AB e PM
                                                        ,w_da_mese_ruolo); -- 05/02/2015 Betta T.
                     IF a_flag_normalizzato is null THEN
                        IF (rec_ogpr.consistenza < rec_ogpr.limite)
                        or (rec_ogpr.limite is NULL)                THEN
                           w_importo := rec_ogpr.consistenza * rec_ogpr.tariffa;
                        ELSE
                           w_importo := rec_ogpr.limite * rec_ogpr.tariffa +
                                        (rec_ogpr.consistenza - rec_ogpr.limite)
                                        * rec_ogpr.tariffa_superiore;
                        END IF;
                        w_importo := f_round(w_importo * (nvl(rec_ogpr.perc_possesso,100) / 100)
                                                       * w_periodo,1
                                            );
                     ELSE
                        -- Il normalizzato tiene conto del periodo e percentuale di possesso.
                        -- (VD - 04/01/2019): sostituita procedure CALCOLO_IMPORTO_NORMALIZZATO
                        --                    con CALCOLO_IMPORTO_NORM_TARIFFE per
                        --                    calcolo ruoli con tariffe
                        calcolo_importo_norm_tariffe(rec_ogpr.cod_fiscale
                                                    ,null   --  ni
                                                    ,w_anno_ruolo
                                                    ,rec_ogpr.tributo
                                                    ,rec_ogpr.categoria
                                                    ,rec_ogpr.tipo_tariffa
                                                    ,rec_ogpr.tariffa
                                                    ,rec_ogpr.tariffa_quota_fissa
                                                    ,rec_ogpr.consistenza
                                                    ,rec_ogpr.perc_possesso
                                                    ,rec_ogpr.data_decorrenza
                                                    ,w_data_cessazione    --rec_ogpr.data_cessazione
                                                    ,rec_ogpr.flag_ab_principale
                                                    ,rec_ogpr.numero_familiari
                                                    ,a_ruolo
                                                    ,rec_ogpr.oggetto
                                                    ,rec_ogpr.tipo_tariffa_base
                                                    ,w_importo
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
                                                    ,w_giorni_ruolo
                                                    );
                        if length(w_dettaglio_ogim) > 215 then
                           w_dettaglio_faog := w_dettaglio_ogim;
                           w_dettaglio_ogim := '';
                        end if;
                        if length(w_dettaglio_ogim_base) > 171 then
                           w_dettaglio_faog_base := w_dettaglio_ogim_base;
                           w_dettaglio_ogim_base := '';
                        end if;
                     END IF;
                     /*--
                     -- (VD - 23/10/2018): Determinazione importi con tariffa base
                     --
                     if w_flag_tariffa_base = 'S' and rec_ogpr.tipo_tariffa_base is not null then
                        determina_importi_base(rec_ogpr.cod_fiscale
                                              ,w_anno_ruolo
                                              ,a_ruolo
                                              ,rec_ogpr.tributo
                                              ,rec_ogpr.categoria
                                              ,rec_ogpr.tipo_tariffa_base
                                              ,a_flag_normalizzato
                                              ,rec_ogpr.consistenza
                                              ,rec_ogpr.perc_possesso
                                              ,w_periodo
                                              ,rec_ogpr.data_decorrenza
                                              ,w_data_cessazione    --rec_ogpr.data_cessazione
                                              ,rec_ogpr.flag_ab_principale
                                              ,rec_ogpr.numero_familiari
                                              ,w_importo_base
                                              ,w_importo_pf_base
                                              ,w_importo_pv_base
                                              ,w_stringa_familiari_base
                                              ,w_dettaglio_ogim_base
                                              ,w_giorni_ruolo
                                              );
                        if length(w_dettaglio_ogim_base) > 171 then
                           w_dettaglio_faog_base := w_dettaglio_ogim_base;
                           w_dettaglio_ogim_base := '';
                        end if;
                     end if; */
                     w_stato := '01';
                     -- la variabile w_importo_tot contiene il valore totale calcolato prima della gestione
                     -- del tipo_emissione, mi serve perchè un oggetto potrebbe andare a ruolo per la sola
                     -- maggiorazione_tares
                     w_importo_tot      := w_importo;
                     w_importo_tot_base := w_importo_base;
                     w_stato := '06';
                   --dbms_output.put_line('Totale: '||to_char(w_importo_tot)||', Totale Base: '||to_char(w_importo_tot_base));
                     if (w_importo_tot > 0) then
                        w_imp_addizionale_pro   := f_round(w_importo * w_addizionale_pro / 100,1);
                        w_imp_addizionale_eca   := f_round(w_importo * w_addizionale_eca / 100,1);
                        w_imp_maggiorazione_eca := f_round(w_importo * w_Maggiorazione_eca / 100,1);
                        w_imp_aliquota          := f_round(w_importo * w_aliquota / 100,1);
                        if w_cod_istat = '037048' then  -- Pieve di Cento
                           w_importo               := round(w_importo,0);
                           w_imp_addizionale_pro   := round(w_imp_addizionale_pro,0);
                           w_imp_addizionale_eca   := round(w_imp_addizionale_eca,0);
                           w_imp_maggiorazione_eca := round(w_imp_maggiorazione_eca,0);
                           w_imp_aliquota          := round(w_imp_aliquota,0);
                        end if;
                        w_tot_addizionali       := w_imp_addizionale_pro
                                                 + w_imp_addizionale_eca
                                                 + w_imp_maggiorazione_eca
                                                 + w_imp_aliquota;
                        w_importo_ruolo         := w_importo + w_tot_addizionali;
--dbms_output.put_line('Importo: '||w_importo||', Importo pf: '||w_importo_pf||', Importo pv: '||w_importo_pv||', Importo ruolo: '||w_importo_ruolo);
                       -- maggiorazione tares
                        if w_flag_magg_anno is null then
                           w_coeff_gg := F_COEFF_GG(w_anno_ruolo,rec_ogpr.data_decorrenza,w_data_cessazione);
                           w_magg_tares_ogim := round(rec_ogpr.consistenza * w_maggiorazione_tares * (100 - rec_ogpr.perc_riduzione) / 100 * w_coeff_gg,2);
                        else
                           if Oggetti_tab.exists(rec_ogpr.oggetto) then
                              w_magg_tares_ogim := null;
                           else
                              Oggetti_tab(rec_ogpr.oggetto) := 'S';
                              w_magg_tares_ogim := round(rec_ogpr.consistenza * w_maggiorazione_tares,2);
                           end if;
                        end if;
                     -- maggiorazione componenti perequative
                        if rec_ogpr.flag_punto_raccolta = 'S' then
                          if w_flag_magg_anno is null then
                             w_coeff_gg := F_COEFF_GG(w_anno_ruolo,rec_ogpr.data_decorrenza,w_data_cessazione);
                             w_magg_tares_ogim := trunc(w_magg_tares_cope * w_coeff_gg,2);
                          else
                             w_magg_tares_ogim := w_magg_tares_cope;
                          end if;
                        end if;
                        w_importo_ruolo := w_importo_ruolo + nvl(w_magg_tares_ogim,0);
                        w_note_ogim := '';
                        -- (VD - 23/10/2018): Calcolo importi con tariffa base
                        if (w_flag_tariffa_base = 'S' or w_flag_ruolo_tariffa = 'S') and
                           w_importo_base > 0 then
                           w_imp_add_pro_base   := f_round(w_importo_base * w_addizionale_pro / 100,1);
                           w_imp_add_eca_base   := f_round(w_importo_base * w_addizionale_eca / 100,1);
                           w_imp_magg_eca_base  := f_round(w_importo_base * w_Maggiorazione_eca / 100,1);
                           w_imp_aliquota_base  := f_round(w_importo_base * w_aliquota / 100,1);
                           w_tot_addizionali_base  := w_imp_add_pro_base
                                                    + w_imp_add_eca_base
                                                    + w_imp_magg_eca_base
                                                    + w_imp_aliquota_base;
                           w_importo_ruolo_base    := w_importo_base + w_tot_addizionali_base;
                        end if;
                        --  incentivi TARSU per San Lazzaro per il 2013  da applicare alla prima utenza
                        --  se si h in presenza di una particolare delega bancaria  (EMETTONO SOLO SUPP TOTALE)
                        if (w_cod_istat ='037054') and (w_anno_ruolo = 2013) and
                           (w_flag_incentivo = 'N') and (w_progr_emissione = 1) then
                           begin
                           --  metto il flag a 'S' per indicare che ho applicato l'incentivo TARSU
                           --  per la prima utenza
                              select decode(coco.tipo_contatto
                                           ,79,45.00
                                           ,80,60.00
                                           ,81,90.00
                                           ,85,105.00
                                           ,77,15.00
                                           ,78,30.00
                                           ,0)
                                   , decode(coco.tipo_contatto
                                           ,79,'ANNO 2013: INCENTIVO TARES EURO 45'
                                           ,80,'ANNO 2013: INCENTIVO TARES EURO 60'
                                           ,81,'ANNO 2013: INCENTIVO TARES EURO 90'
                                           ,85,'ANNO 2013: INCENTIVO TARES EURO 105'
                                           ,77,'ANNO 2013: INCENTIVO TARES EURO 15'
                                           ,78,'ANNO 2013: INCENTIVO TARES EURO 30'
                                           ,'')
                                   , decode(coco.tipo_contatto
                                           ,79,'S'
                                           ,80,'S'
                                           ,81,'S'
                                           ,85,'S'
                                           ,2400,'S'
                                           ,77,'S'
                                           ,78,'S'
                                           ,'N')
                                 into w_incentivi
                                    , w_note_ogim
                                    , w_flag_incentivo
                                 from contatti_contribuente coco
                                 where coco.anno = 2013
                                   and coco.tipo_contatto in (78,80,81,77,79,85)
                                   and coco.cod_fiscale = rec_ogpr.cod_fiscale
                              ;
                           exception
                              when others then
                                  w_note_ogim := '';
                                  w_incentivi := 0;
                                  w_flag_incentivo := 'N';
                           end;
                           w_importo_ruolo:= w_importo_ruolo - w_incentivi;
                        elsif (w_cod_istat ='037054') and (w_anno_ruolo = 2014) and
                          (w_flag_incentivo = 'N') and (w_progr_emissione = 1) then
                           begin
                           --  metto il flag a 'S' per indicare che ho applicato l'incentivo TARSU
                           --  per la prima utenza
                             select decode(coco.tipo_contatto
                                          ,79,45.00
                                          ,80,60.00
                                          ,81,90.00
                                          ,85,105.00
                                          ,77,15.00
                                          ,78,30.00
                                          ,0)
                                  , decode(coco.tipo_contatto
                                          ,79,'ANNO 2014: INCENTIVO TARI EURO 45'
                                          ,80,'ANNO 2014: INCENTIVO TARI EURO 60'
                                          ,81,'ANNO 2014: INCENTIVO TARI EURO 90'
                                          ,85,'ANNO 2014: INCENTIVO TARI EURO 105'
                                          ,77,'ANNO 2014: INCENTIVO TARI EURO 15'
                                          ,78,'ANNO 2014: INCENTIVO TARI EURO 30'
                                          ,'')
                                  , decode(coco.tipo_contatto
                                          ,79,'S'
                                          ,80,'S'
                                          ,81,'S'
                                          ,85,'S'
                                          ,77,'S'
                                          ,78,'S'
                                          ,'N')
                               into w_incentivi
                                  , w_note_ogim
                                  , w_flag_incentivo
                               from contatti_contribuente coco
                              where coco.anno = 2014
                                and coco.tipo_contatto in (78,80,81,85,77,79)
                                and coco.cod_fiscale = rec_ogpr.cod_fiscale
                                 ;
                           exception
                              when others then
                                  w_note_ogim := '';
                                  w_incentivi := 0;
                                  w_flag_incentivo := 'N';
                           end;
                           w_importo_ruolo:= w_importo_ruolo - w_incentivi;
                        elsif (w_cod_istat ='037054') and (w_anno_ruolo >= 2015) and
                          (w_flag_incentivo = 'N') and (w_progr_emissione = 1) then
                           begin
                           --  metto il flag a 'S' per indicare che ho applicato l'incentivo TARSU
                           --  per la prima utenza
                             select decode(coco.tipo_contatto
                                          ,79,45.00
                                          ,80,60.00
                                          ,81,90.00
                                          ,85,105.00
                                          ,77,15.00
                                          ,78,30.00
                                          ,87,75.00
                                          ,0)
                                  , decode(coco.tipo_contatto
                                          ,79,'ANNO '||coco.anno||': INCENTIVO '||f_descrizione_titr('TARSU',coco.anno)||' EURO 45'
                                          ,80,'ANNO '||coco.anno||': INCENTIVO '||f_descrizione_titr('TARSU',coco.anno)||' EURO 60'
                                          ,81,'ANNO '||coco.anno||': INCENTIVO '||f_descrizione_titr('TARSU',coco.anno)||' EURO 90'
                                          ,85,'ANNO '||coco.anno||': INCENTIVO '||f_descrizione_titr('TARSU',coco.anno)||' EURO 105'
                                          ,77,'ANNO '||coco.anno||': INCENTIVO '||f_descrizione_titr('TARSU',coco.anno)||' EURO 15'
                                          ,78,'ANNO '||coco.anno||': INCENTIVO '||f_descrizione_titr('TARSU',coco.anno)||' EURO 30'
                                          ,87,'ANNO '||coco.anno||': INCENTIVO '||f_descrizione_titr('TARSU',coco.anno)||' EURO 75'
                                          ,'')
                                  , decode(coco.tipo_contatto
                                          ,79,'S'
                                          ,80,'S'
                                          ,81,'S'
                                          ,85,'S'
                                          ,77,'S'
                                          ,78,'S'
                                          ,87,'S'
                                          ,'N')
                               into w_incentivi
                                  , w_note_ogim
                                  , w_flag_incentivo
                               from contatti_contribuente coco
                              where coco.anno = w_anno_ruolo
                                and coco.tipo_contatto in (79,80,81,85,77,78,87)
                                and coco.cod_fiscale = rec_ogpr.cod_fiscale
                                 ;
                           exception
                              when others then
                                  w_note_ogim := '';
                                  w_incentivi := 0;
                                  w_flag_incentivo := 'N';
                           end;
                           w_importo_ruolo:= w_importo_ruolo - w_incentivi;
                        else
                           w_note_ogim := '';
                        end if;
                        --
                        -- (VD - 23/10/2018): Modificata gestione dettaglio_ogim
                        --                    per ruolo gestito a tariffe
                        --
                        if w_dettaglio_ogim is not null then
                           w_dettaglio_ogim := '*'||substr(w_dettaglio_ogim,2,1999);
                        end if;
                        if w_dettaglio_ogim_base is not null then
                           w_dettaglio_ogim_base := '*'||substr(w_dettaglio_ogim_base,2,1999);
                        end if;
                        if w_dettaglio_faog is not null then
                           w_dettaglio_faog := '*'||substr(w_dettaglio_faog,2,1999);
                        end if;
                        if w_dettaglio_faog_base is not null then
                           w_dettaglio_faog_base := '*'||substr(w_dettaglio_faog_base,2,1999);
                        end if;
                        --
                        w_oggetto_imposta := null;
                        oggetti_imposta_nr(w_oggetto_imposta);
                        BEGIN
                          insert into oggetti_imposta
                                (oggetto_imposta,cod_fiscale,anno,oggetto_pratica,imposta,
                                 imposta_dovuta,imposta_dovuta_acconto,
                                 addizionale_eca,maggiorazione_eca,addizionale_pro,iva,
                                 ruolo,importo_ruolo,flag_calcolo,utente,note,
                                 importo_pf,importo_pv,aliquota_iva,dettaglio_ogim,
                                 maggiorazione_tares, tipo_tributo,
                                 tipo_tariffa_base, imposta_base,
                                 addizionale_eca_base, maggiorazione_eca_base,
                                 addizionale_pro_base, iva_base, importo_pf_base,
                                 importo_pv_base, importo_ruolo_base, dettaglio_ogim_base,
                                 perc_riduzione_pf, perc_riduzione_pv,
                                 importo_riduzione_pf, importo_riduzione_pv
                                )
                          values(w_oggetto_imposta,rec_ogpr.cod_fiscale,w_anno_ruolo,
                                 rec_ogpr.oggetto_pratica,w_importo,
                                 w_imposta_dovuta,w_imposta_dovuta_acconto,
                                 w_imp_addizionale_eca,w_imp_maggiorazione_eca,
                                 w_imp_addizionale_pro,w_imp_aliquota,
                                 a_ruolo,w_importo_ruolo,'S',a_utente,w_note_ogim,
                                 w_importo_pf,w_importo_pv,w_aliquota_iva,w_dettaglio_ogim,
                                 w_magg_tares_ogim, w_tipo_tributo,
                                 rec_ogpr.tipo_tariffa_base, w_importo_base,
                                 w_imp_add_eca_base, w_imp_magg_eca_base,
                                 w_imp_add_pro_base, w_imp_aliquota_base, w_importo_pf_base,
                                 w_importo_pv_base, w_importo_ruolo_base, w_dettaglio_ogim_base,
                                 w_perc_rid_pf, w_perc_rid_pv,
                                 w_importo_pf_rid, w_importo_pv_rid
                                )
                          ;
                        EXCEPTION
                          WHEN others THEN
                             w_errore := 'Errore in inserimento Oggetti Imposta (1)- '||
                                         'per '||w_cod_fiscale||' - ('||SQLERRM||')';
                             RAISE errore;
                        END;
                        WHILE length(w_stringa_familiari) > 19  LOOP
                           BEGIN
                              insert into familiari_ogim
                                         (oggetto_imposta,numero_familiari
                                         ,dal,al
                                         ,data_variazione
                                         ,dettaglio_faog
                                         ,dettaglio_faog_base
                                         )
                                   values(w_oggetto_imposta,to_number(substr(w_stringa_familiari,1,4))
                                         ,to_date(substr(w_stringa_familiari,5,8),'ddmmyyyy'),to_date(substr(w_stringa_familiari,13,8),'ddmmyyyy')
                                         ,trunc(sysdate)
                                         ,substr(w_dettaglio_faog,1,214)
                                         ,substr(w_dettaglio_faog_base,1,171)
                                         )
                                         ;
                           EXCEPTION
                              WHEN others THEN
                                  w_errore := 'Errore in inserimento Familiari_ogim di '
                                              ||w_cod_fiscale||' ('||SQLERRM||')';
                                      RAISE ERRORE;
                           END;
                           w_stringa_familiari := substr(w_stringa_familiari,21);
                           if w_dettaglio_faog is not null then
                              w_dettaglio_faog := '*'||rtrim(substr(w_dettaglio_faog,215));
                           end if;
                           if w_dettaglio_faog_base is not null then
                              w_dettaglio_faog_base := '*'||rtrim(substr(w_dettaglio_faog_base,172));
                           end if;
                        END LOOP;
                        IF  w_importo < nvl(w_limite_ruolo,0)
                        and nvl(a_tipo_limite,' ') = 'O'       THEN
                           BEGIN
                             update oggetti_imposta
                                set ruolo                = null
                                   ,importo_ruolo        = null
                                   ,addizionale_eca      = null
                                   ,maggiorazione_eca    = null
                                   ,addizionale_pro      = null
                                   ,iva                  = null
                              where ruolo = a_ruolo
                                and oggetto_imposta      = w_oggetto_imposta
                             ;
                           EXCEPTION
                             WHEN others THEN
                                w_errore := 'Errore in aggiornamento Oggetti Imposta '||
                                            'per '||w_cod_fiscale||' - ('||SQLERRM||')';
                                RAISE errore;
                           END;
                        ELSE
                           if w_rate > 0 then
                              if f_tratta_rate(w_rate
                                              ,w_anno_ruolo
                                              ,rec_ogpr.tipo_tributo
                                              ,w_imp_addizionale_eca
                                              ,w_imp_maggiorazione_eca
                                              ,w_imp_addizionale_pro
                                              ,w_magg_tares_ogim
                                              ,w_imp_aliquota
                                              ,w_importo
                                              ,w_oggetto_imposta
                                              ,rec_ogpr.conto_corrente
                                              ,rec_ogpr.cod_fiscale
                                              ,a_utente
                                              ,w_cod_istat
                                              ,w_rata_perequative
                                              ) = -1 then
                                 w_errore := 'Errore in determinazione numero rate (1) '||
                                             'per '||w_cod_fiscale||' - ('||SQLERRM||')';
                                 RAISE errore;
                              end if;
                           end if;
                           BEGIN
                              insert into ruoli_contribuente
                                    (ruolo,cod_fiscale,oggetto_imposta
                                    ,tributo,consistenza,importo
                                    ,mesi_ruolo
                                    ,utente,note
                                    ,da_mese,a_mese
                                    ,giorni_ruolo
                                    ,importo_base
                                    )
                              values(a_ruolo,rec_ogpr.cod_fiscale,w_oggetto_imposta
                                    ,rec_ogpr.tributo,rec_ogpr.consistenza,w_importo_ruolo
                                    ,decode(w_mesi_calcolo,0,null,round(w_periodo * 12))
                                    ,a_utente,w_note_ogim
                                    ,w_da_mese_ruolo,w_a_mese_ruolo
                                    ,decode(w_mesi_calcolo,0,w_giorni_ruolo,null)
                                    ,w_importo_base
                                    )
                              ;
                           EXCEPTION
                              WHEN others THEN
                                 w_errore := 'Errore in inserimento Ruoli Contribuente (1) '||
                                             'per '||w_cod_fiscale||' - ('||SQLERRM||')';
                                 RAISE errore;
                           END;
                        END IF;
                     end if;
                  END IF; -- rec_ogpr.flag_ruolo is not NULL
               END LOOP;
               --
               -- (VD - 22/11/2017): Pontedera - calcolo e applicazione sconti per conferimento
               --
               if w_cod_istat = '050029' then
                  cer_conferimenti.determina_sconto_conf(w_anno_ruolo
                                                        ,a_ruolo
                                                        ,w_tipo_ruolo
                                                        ,w_tipo_emissione
                                                        ,a_cod_fiscale
                                                        ,a_utente
                                                        );
                  applica_sconto_conf(w_anno_ruolo
                                     ,a_ruolo
                                     ,a_tipo_limite
                                     ,w_limite_ruolo
                                     ,w_rate
                                     ,a_cod_fiscale
                                     );
               end if;
               --
               -- Calcolato il suppletivo, esso va confrontato con la somma dei ruoli
               -- precedenti (principale e suppletivi TOTALE).
               -- Si confrontano le somme per contribuente anzichè oggetto per oggetto.
               --
               for rec_cf_supp_totali in sel_cf_supp_totali(a_ruolo,a_cod_fiscale)
               loop
                   declare w_importo_cf_tot number;
                   --
                   begin
                     begin
                       select nvl(sum(ruco.IMPORTO - nvl(sgra_tot.importo, 0)),0)
                         into w_importo_cf_tot
                         from ruoli_contribuente ruco
                            , ruoli ruol
                            , (select ruolo, cod_fiscale, sequenza, sum(importo) importo
                                 from sgravi sgra
                                where ruolo != a_ruolo
                                  and cod_fiscale = rec_cf_supp_totali.cod_fiscale
                                group by ruolo, cod_fiscale, sequenza) sgra_tot
                       where ruol.ruolo          = ruco.ruolo
                         and ruco.cod_fiscale    =  rec_cf_supp_totali.cod_fiscale
                         and ruol.tipo_tributo   = 'TARSU'
                         and ruol.tipo_emissione = 'T'
                         and ruol.anno_ruolo     = w_anno_ruolo
                         and ruol.ruolo          != a_ruolo
                         and ruol.invio_consorzio is not null
                         and ruco.ruolo = sgra_tot.ruolo (+)
                         and ruco.cod_fiscale = sgra_tot.cod_fiscale (+)
                         and ruco.sequenza = sgra_tot.sequenza (+);
                     exception
                     when others then
                       w_importo_cf_tot := 0;
                     end;
                     --
                     -- Se la somma degli importi precedenti è uguale all'importo appena calcolato
                     -- cancello tutti i record del suppletivo appena creato.
                     --
                   --dbms_output.put_line('Importo ruoli contr.: '||w_importo_cf_tot||', Importo ruoli tot: '||  rec_cf_supp_totali.importo);
                     if w_importo_cf_tot = rec_cf_supp_totali.importo then
                          delete ruoli_contribuente
                           where cod_fiscale = rec_cf_supp_totali.cod_fiscale
                             and ruolo = a_ruolo
                          ;
                          delete ruoli_eccedenze
                           where cod_fiscale = rec_cf_supp_totali.cod_fiscale
                             and ruolo = a_ruolo
                          ;
                      --  Versione ottimizzata per Oracle 11 (usa appieno gli indici)
                          delete familiari_ogim faog
                           where faog.oggetto_imposta in (select ogim.oggetto_imposta
                                                            from oggetti_imposta ogim
                                                           where ogim.cod_fiscale = rec_cf_supp_totali.cod_fiscale
                                                             and ogim.ruolo = a_ruolo)
                          ;
                      --  Versione originale, buona per Oracle 19 ma non per la 11 (va in FULL TABLE)
                      --  delete familiari_ogim
                      --   where exists (select 1
                      --                   from oggetti_imposta
                      --                  where cod_fiscale = rec_cf_supp_totali.cod_fiscale
                      --                    and ruolo = a_ruolo
                      --                    and familiari_ogim.oggetto_imposta = oggetti_imposta.oggetto_imposta
                      --                )
                      --  ;
                          delete oggetti_imposta
                           where cod_fiscale = rec_cf_supp_totali.cod_fiscale
                             and ruolo = a_ruolo
                          ;
                         --
                         -- (VD - 16/11/2016) - Sperimentazione Poasco
                         --                     Si annullano sulla tabella CONFERIMENTI
                         --                     il ruolo e l'importo scalato
                         --
                         BEGIN
                           update CONFERIMENTI
                              set ruolo = null
                                , importo_scalato = null
                            where cod_fiscale = rec_cf_supp_totali.cod_fiscale
                              and anno = w_anno_ruolo;
                         EXCEPTION
                           WHEN OTHERS THEN
                             w_errore := 'Errore in Aggiornamento CONFERIMENTI '||
                                         'per '||w_cod_fiscale||' - ('||SQLERRM||')';
                             RAISE errore;
                         END;
                      else
                         -- inserisce uno sgravio su ogni utenza pari all'importo richiesto in precedenza.
                         CREA_SGRAVI_PER_CF_SUPP(rec_cf_supp_totali.cod_fiscale, a_ruolo, w_anno_ruolo, 'TARSU');
                      end if;
                   exception
                     when others then
                       w_errore := 'Errore in gestione suppletivo totale '||
                                   'per '||rec_cf_supp_totali.cod_fiscale||' - ('||SQLERRM||')';
                       RAISE errore;
                   end;
               end loop;
            else --suppletivo SALDO
-- dbms_output.put_line('Suppletivo a saldo: '||a_cod_fiscale);
               w_cf_del_sgravi := '                ';
               FOR rec_ogpr IN sel_ogpr_2(a_ruolo
                                         ,a_cod_fiscale
                                         ,w_tipo_tributo
                                         ,w_anno_ruolo
                                         ,w_data_emissione
                                         ,a_flag_normalizzato
                                         )
               LOOP
                  if w_cf_del_sgravi <> rec_ogpr.cod_fiscale then
                     /*delete sgravi
                      where cod_fiscale = rec_ogpr.cod_fiscale
                        and ruolo in (select ruolo
                                        from ruoli
                                       where anno_ruolo = w_anno_ruolo
                                         and tipo_tributo = 'TARSU'
                                         and invio_consorzio is not null
                                         and tipo_emissione = 'S'
                                     )
                        and motivo_sgravio = 99
                        and flag_automatico = 'S'
                     ;*/
                     eliminazione_sgravi_ruolo(rec_ogpr.cod_fiscale, a_ruolo, w_anno_ruolo, 'TARSU', w_tipo_emissione, w_tipo_ruolo,'S');
                     begin
                         delete compensazioni_ruolo
                          where cod_fiscale = rec_ogpr.cod_fiscale
                             and ruolo = a_ruolo
                             and motivo_compensazione = 99
                             and flag_automatico = 'S'
                            ;
                     EXCEPTION
                       WHEN others THEN
                         w_errore := 'Errore in eliminazione Compensazioni Ruolo '||
                                     'per '||w_cod_fiscale||' - ('||SQLERRM||')';
                         RAISE errore;
                     end;
                  end if;
                  w_cf_del_sgravi := rec_ogpr.cod_fiscale;
                  w_cod_fiscale   := '(3) - '||rec_ogpr.cod_fiscale;
                  w_importo := 0;
                  w_importo_pf := null;
                  w_importo_pv := null;
                  w_stringa_familiari := '';
                  w_dettaglio_faog    := '';
                  w_dettaglio_ogim    := '';
                  w_note_ogim         := '';
                  w_data_cessazione := rec_ogpr.fine_decorrenza;
                   if  (w_cod_istat ='037054') then -- San lazzaro
                      -- Il periodo viene calcolato sempre come normalizzato,
                      -- in questo modo può essere anche a giorni
                      w_periodo := f_periodo(w_anno_ruolo
                                            ,rec_ogpr.inizio_decorrenza
                                            ,w_data_cessazione
                                            ,rec_ogpr.tipo_occupazione
                                            ,w_tipo_tributo
                                            ,'S'     -- flag_normalizzato
                                            );
                   else
                      w_periodo := f_periodo(w_anno_ruolo
                                            ,rec_ogpr.inizio_decorrenza
                                            ,w_data_cessazione
                                            ,rec_ogpr.tipo_occupazione
                                            ,w_tipo_tributo
                                            ,a_flag_normalizzato
                                            );
                   end if;
                   IF a_flag_normalizzato is null THEN
                      w_tratta_sgravio := 1; -- Sgravio sempre trattato per il NON Normalizzato
                      IF (nvl(rec_ogpr.consistenza,1) < rec_ogpr.limite)
                      or (rec_ogpr.limite is null)                         THEN
                         w_importo := rec_ogpr.consistenza * rec_ogpr.tariffa;
                      ELSE
                         w_importo := rec_ogpr.limite * rec_ogpr.tariffa +
                                      (rec_ogpr.consistenza - rec_ogpr.limite) *      rec_ogpr.tariffa_superiore;
                      END IF;
                      w_importo := f_round(w_importo * (nvl(rec_ogpr.perc_possesso,100) / 100)
                                           * w_periodo , 1);
                   ELSE
                      -- Il normalizzato tiene conto del periodo e percentuale di possesso.
                      -- (VD - 04/01/2019): sostituita procedure CALCOLO_IMPORTO_NORMALIZZATO
                      --                    con CALCOLO_IMPORTO_NORM_TARIFFE per
                      --                    calcolo ruoli con tariffe
                      CALCOLO_IMPORTO_NORM_TARIFFE(rec_ogpr.cod_fiscale
                                                  ,null  -- ni
                                                  ,w_anno_ruolo
                                                  ,rec_ogpr.tributo
                                                  ,rec_ogpr.categoria
                                                  ,rec_ogpr.tipo_tariffa
                                                  ,rec_ogpr.tariffa
                                                  ,rec_ogpr.tariffa_quota_fissa
                                                  ,rec_ogpr.consistenza
                                                  ,rec_ogpr.perc_possesso
                                                  ,rec_ogpr.inizio_decorrenza
                                                  ,w_data_cessazione    --rec_ogpr.fine_decorrenza
                                                  ,rec_ogpr.flag_ab_principale
                                                  ,rec_ogpr.numero_familiari
                                                  ,a_ruolo
                                                  ,to_number(null)      -- oggetto
                                                  ,rec_ogpr.tipo_tariffa_base
                                                  ,w_importo
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
                                                  ,w_giorni_ruolo
                                                  );
 -- dbms_output.put_line('Calcolo importo normalizzato - Importo: '||w_importo||' Importo pf: '||w_importo_pf||' Importo pv: '||w_importo_pv);
                      if length(w_dettaglio_ogim) > 151 then
                         w_dettaglio_faog := w_dettaglio_ogim;
                         w_dettaglio_ogim := '';
                      end if;
                      if length(w_dettaglio_ogim_base) > 171 then
                         w_dettaglio_faog_base := w_dettaglio_ogim_base;
                         w_dettaglio_ogim_base := '';
                      end if;
                   END IF;
                   /*--
                   -- (VD - 23/10/2018): Determinazione importi con tariffa base
                   --
                   if w_flag_tariffa_base = 'S' and rec_ogpr.tipo_tariffa_base is not null then
                      DETERMINA_IMPORTI_BASE(rec_ogpr.cod_fiscale
                                            ,w_anno_ruolo
                                            ,a_ruolo
                                            ,rec_ogpr.tributo
                                            ,rec_ogpr.categoria
                                            ,rec_ogpr.tipo_tariffa_base
                                            ,a_flag_normalizzato
                                            ,rec_ogpr.consistenza
                                            ,rec_ogpr.perc_possesso
                                            ,w_periodo
                                            ,rec_ogpr.inizio_decorrenza
                                            ,w_data_cessazione    --rec_ogpr.data_cessazione
                                            ,rec_ogpr.flag_ab_principale
                                            ,rec_ogpr.numero_familiari
                                            ,w_importo_base
                                            ,w_importo_pf_base
                                            ,w_importo_pv_base
                                            ,w_stringa_familiari_base
                                            ,w_dettaglio_ogim_base
                                            ,w_giorni_ruolo
                                            );
                      if length(w_dettaglio_ogim_base) > 171 then
                         w_dettaglio_faog_base := w_dettaglio_ogim_base;
                         w_dettaglio_ogim_base := '';
                      end if;
                   end if; */
                   importi_ruolo_acc_sal(rec_ogpr.cod_fiscale
                                        ,w_anno_ruolo
                                        ,rec_ogpr.inizio_decorrenza
                                        ,w_data_cessazione    --rec_ogpr.fine_decorrenza
                                        ,w_tipo_tributo
                                        ,rec_ogpr.oggetto_pratica
                                        ,rec_ogpr.oggetto_pratica_rif
                                        ,a_flag_normalizzato
                                        ,w_flag_magg_anno
                                        ,w_imp_scalare
                                        ,w_imp_scalare_pv
                                        ,w_imp_scalare_pf
                                        ,w_magg_tares_scalare
                                        ,w_imp_scalare_base
                                        ,w_imp_scalare_pv_base
                                        ,w_imp_scalare_pf_base
                                        );
-- dbms_output.put_line('Importo calcolato: '||to_char(w_importo)||' - Importo da scalare: '||to_char(nvl(w_imp_scalare,0)));
                   w_note_ogim    := 'Importo calcolato: '||to_char(w_importo)||' - Importo da scalare: '||to_char(nvl(w_imp_scalare,0))||' '||
                                     'Importo base calcolato: '||to_char(w_importo_base)||' - Importo base da scalare: '||to_char(nvl(w_imp_scalare_base,0));
                   w_importo := w_importo - nvl(w_imp_scalare,0);
                   w_importo_sgravi := w_importo;
                   w_importo_base := w_importo_base - nvl(w_imp_scalare_base,0);
                   w_importo_sgravio_base := w_importo_base;
                   -- maggiorazione TARES
                   if w_flag_magg_anno is null then
                      w_coeff_gg := F_COEFF_GG(w_anno_ruolo,rec_ogpr.inizio_decorrenza,w_data_cessazione);
                      w_magg_tares_ogim := rec_ogpr.consistenza * w_maggiorazione_tares * (100 - rec_ogpr.perc_riduzione) / 100 * w_coeff_gg;
                   else
                      w_magg_tares_ogim := rec_ogpr.consistenza * w_maggiorazione_tares;
                   end if;
                -- maggiorazione componenti perequative
                   if rec_ogpr.flag_punto_raccolta = 'S' then
                      if w_flag_magg_anno is null then
                         w_coeff_gg := F_COEFF_GG(w_anno_ruolo,rec_ogpr.inizio_decorrenza,w_data_cessazione);
                         w_magg_tares_ogim := trunc(w_magg_tares_cope * w_coeff_gg,2);
                      else
                         w_magg_tares_ogim := w_magg_tares_cope;
                      end if;
                   end if;
                   w_magg_tares_ogim := round(w_magg_tares_ogim - nvl(w_magg_tares_scalare,0),2);
                   w_magg_tares_ogim_sgravi := w_magg_tares_ogim;
-- dbms_output.put_line('Maggiorazione TARES: '||to_char(w_magg_tares_ogim));
                   IF w_importo > 0 or  nvl(w_magg_tares_ogim,0) > 0 THEN
                      -- se l'importo-ruolo è minore di zero metto a ruolo la sola maggiorazione tares
                      if w_importo < 0 then
                         w_importo := 0;
                         w_importo_pf := 0;
                         w_importo_pv := 0;
                      end if;
                      -- se la maggiorazione tares è minore di zero non la metto a ruolo
                      if w_magg_tares_ogim < 0 then
                         w_magg_tares_ogim := 0;
                      end if;
                      w_imp_addizionale_pro   := f_round(w_importo * w_addizionale_pro / 100,1);
                      w_imp_addizionale_eca   := f_round(w_importo * w_addizionale_eca / 100,1);
                      w_imp_maggiorazione_eca := f_round(w_importo * w_Maggiorazione_eca / 100,1);
                      w_imp_aliquota          := f_round(w_importo * w_aliquota / 100,1);
                      if w_cod_istat = '037048' then  -- Pieve di Cento
                         w_importo               := round(w_importo,0);
                         w_imp_addizionale_pro   := round(w_imp_addizionale_pro,0);
                         w_imp_addizionale_eca   := round(w_imp_addizionale_eca,0);
                         w_imp_maggiorazione_eca := round(w_imp_maggiorazione_eca,0);
                         w_imp_aliquota          := round(w_imp_aliquota,0);
                      end if;
                      w_tot_addizionali       := w_imp_addizionale_pro
                                               + w_imp_addizionale_eca
                                               + w_imp_maggiorazione_eca
                                               + w_imp_aliquota;
                      w_importo_ruolo         := w_importo + w_tot_addizionali + nvl(w_magg_tares_ogim,0);
                      if w_imp_scalare_pf = -1 then
                         w_importo_pf := null;
                      else
                         w_importo_pf := w_importo_pf - nvl(w_imp_scalare_pf,0);
                      end if;
                      if w_imp_scalare_pv = -1 then
                         w_importo_pv := null;
                      else
                        w_importo_pv := w_importo_pv - nvl(w_imp_scalare_pv,0);
                      end if;
                      if w_importo_pf < 0 or w_importo_pv < 0 then
                         w_importo_pv := 0;
                         w_importo_pf := 0;
                      end if;
                      --
                      -- (VD - 25/10/2018): Trattamento importi calcolati con
                      --                    tariffa base
                      if w_flag_tariffa_base = 'S' or w_flag_ruolo_tariffa = 'S' then
                         if w_importo_base < 0 then
                            w_importo_base := 0;
                            w_importo_pf_base := 0;
                            w_importo_pv_base := 0;
                         end if;
                         w_imp_add_pro_base  := f_round(w_importo_base * w_addizionale_pro / 100,1);
                         w_imp_add_eca_base  := f_round(w_importo_base * w_addizionale_eca / 100,1);
                         w_imp_magg_eca_base := f_round(w_importo_base * w_Maggiorazione_eca / 100,1);
                         w_imp_aliquota_base := f_round(w_importo_base * w_aliquota / 100,1);
                         w_tot_addizionali_base := w_imp_add_pro_base
                                                 + w_imp_add_eca_base
                                                 + w_imp_magg_eca_base
                                                 + w_imp_aliquota_base;
                         w_importo_ruolo_base    := w_importo_base + w_tot_addizionali_base;
                         if w_imp_scalare_pf_base = -1 then
                            w_importo_pf_base := null;
                         else
                            w_importo_pf_base := w_importo_pf_base - nvl(w_imp_scalare_pf_base,0);
                         end if;
                         if w_imp_scalare_pv_base = -1 then
                            w_importo_pv_base := null;
                         else
                            w_importo_pv_base := w_importo_pv_base - nvl(w_imp_scalare_pv_base,0);
                         end if;
                         if w_importo_pf_base < 0 or w_importo_pv_base < 0 then
                            w_importo_pv_base := 0;
                            w_importo_pf_base := 0;
                         end if;
                      end if;
                      --
                      -- (VD - 18/01/2018): Memorizzazione importo da scalare in campo note anziche in dettaglio_ogim
                      --
                      --if nvl(w_imp_scalare,0) > 0 then
                      --   w_dettaglio_faog := '';
                      --   w_dettaglio_ogim := lpad(nvl(translate(ltrim(to_char(nvl(w_imp_scalare,0),'99,999,999,990.00')),'.,',',.'),' '),17,' ');
                      --end if;
                      --
                      -- (VD - 20/03/2019): Modifica calcolo dettaglio_ogim per
                      --                    gestione tariffe
                      --
                      if w_dettaglio_ogim is not null then
                         w_dettaglio_ogim := '*'||substr(w_dettaglio_ogim,2,1999);
                      end if;
                      if w_dettaglio_ogim_base is not null then
                         w_dettaglio_ogim_base := '*'||substr(w_dettaglio_ogim_base,2,1999);
                      end if;
                      if w_dettaglio_faog is not null then
                         w_dettaglio_faog := '*'||substr(w_dettaglio_faog,2,1999);
                      end if;
                      if w_dettaglio_faog_base is not null then
                         w_dettaglio_faog_base := '*'||substr(w_dettaglio_faog_base,2,1999);
                      end if;
                      --
                      w_oggetto_imposta := null;
                      oggetti_imposta_nr(w_oggetto_imposta);
                      BEGIN
                         insert into oggetti_imposta
                               (oggetto_imposta,cod_fiscale,anno,oggetto_pratica,
                                imposta,ruolo,importo_ruolo,addizionale_eca,
                                maggiorazione_eca,addizionale_pro,iva,flag_calcolo,utente,
                                aliquota_iva,importo_pf,importo_pv,dettaglio_ogim, tipo_tributo,
                                note, maggiorazione_tares,
                                tipo_tariffa_base,imposta_base,
                                addizionale_eca_base,maggiorazione_eca_base,
                                addizionale_pro_base,iva_base,
                                importo_pf_base,importo_pv_base,
                                importo_ruolo_base, dettaglio_ogim_base,
                                perc_riduzione_pf,perc_riduzione_pv,
                                importo_riduzione_pf,importo_riduzione_pv
                               )
                         values(w_oggetto_imposta,rec_ogpr.cod_fiscale,w_anno_ruolo,
                                rec_ogpr.oggetto_pratica,w_importo,a_ruolo,w_importo_ruolo,
                                w_imp_addizionale_eca,w_imp_maggiorazione_eca,
                                w_imp_addizionale_pro,w_imp_aliquota,'S',a_utente,
                                w_aliquota_iva,w_importo_pf,w_importo_pv,w_dettaglio_ogim, w_tipo_tributo,
                                w_note_ogim, w_magg_tares_ogim,
                                rec_ogpr.tipo_tariffa_base,w_importo_base,
                                w_imp_add_eca_base,w_imp_magg_eca_base,
                                w_imp_add_pro_base,w_imp_aliquota_base,
                                w_importo_pf_base,w_importo_pv_base,
                                w_importo_ruolo_base, w_dettaglio_ogim_base,
                                w_perc_rid_pf, w_perc_rid_pv,
                                w_importo_pf_rid, w_importo_pv_rid
                               )
                         ;
                      EXCEPTION
                        WHEN others THEN
                           w_errore := 'Errore in inserimento Oggetti Imposta (2) '||
                                       'per '||w_cod_fiscale||' - ('||SQLERRM||')';
                           RAISE errore;
                      END;
                      WHILE length(w_stringa_familiari) > 19  LOOP
                         BEGIN
                           insert into familiari_ogim
                                      (oggetto_imposta,numero_familiari
                                      ,dal,al
                                      ,data_variazione
                                      ,dettaglio_faog
                                      ,dettaglio_faog_base
                                      )
                                values(w_oggetto_imposta,to_number(substr(w_stringa_familiari,1,4))
                                      ,to_date(substr(w_stringa_familiari,5,8),'ddmmyyyy'),to_date(substr(w_stringa_familiari,13,8),'ddmmyyyy')
                                      ,trunc(sysdate)
                                      ,substr(w_dettaglio_faog,1,150)
                                      ,substr(w_dettaglio_faog_base,1,170)
                                      )
                                      ;
                         EXCEPTION
                           WHEN others THEN
                               w_errore := 'Errore in inserimento Familiari_ogim (2) di '
                                           ||w_cod_fiscale||' ('||SQLERRM||')';
                                   RAISE ERRORE;
                         END;
                         w_stringa_familiari := substr(w_stringa_familiari,21);
                         if w_dettaglio_faog is not null then
                            w_dettaglio_faog := '*'||rtrim(substr(w_dettaglio_faog,152));
                         end if;
                         if w_dettaglio_faog_base is not null then
                            w_dettaglio_faog_base := '*'||rtrim(substr(w_dettaglio_faog_base,172));
                         end if;
                      END LOOP;
                      IF  w_importo < nvl(w_limite_ruolo,0)
                      and nvl(a_tipo_limite,' ') = 'O'             THEN
                         BEGIN
                            update oggetti_imposta
                               set ruolo             = null
                                  ,importo_ruolo     = null
                                  ,addizionale_eca   = null
                                  ,maggiorazione_eca = null
                                  ,addizionale_pro   = null
                                  ,iva               = null
                             where ruolo             = a_ruolo
                               and oggetto_imposta   = w_oggetto_imposta
                            ;
                         EXCEPTION
                            WHEN others THEN
                               w_errore := 'Errore in aggiornamento Oggetti Imposta '||
                                           'per '||w_cod_fiscale||' - ('||SQLERRM||')';
                               RAISE errore;
                         END;
                      ELSE
                         if w_rate > 0 then
                            if f_tratta_rate(w_rate
                                            ,w_anno_ruolo
                                            ,rec_ogpr.tipo_tributo
                                            ,w_imp_addizionale_eca
                                            ,w_imp_maggiorazione_eca
                                            ,w_imp_addizionale_pro
                                            ,w_magg_tares_ogim
                                            ,w_imp_aliquota
                                            ,w_importo
                                            ,w_oggetto_imposta
                                            ,rec_ogpr.conto_corrente
                                            ,rec_ogpr.cod_fiscale
                                            ,a_utente
                                            ,w_cod_istat
                                            ,w_rata_perequative
                                            ) = -1 then
                               w_errore := 'Errore in determinazione numero rate (2) '||
                                           'per '||w_cod_fiscale||' - ('||SQLERRM||')';
                               RAISE errore;
                            end if;
                         end if;
                         BEGIN
                            insert into ruoli_contribuente
                                  (ruolo,cod_fiscale,oggetto_imposta,tributo,consistenza,
                                   importo,mesi_ruolo,utente,giorni_ruolo,
                                   importo_base
                                  )
                            values(a_ruolo,rec_ogpr.cod_fiscale,w_oggetto_imposta,
                                   rec_ogpr.tributo,rec_ogpr.consistenza,w_importo_ruolo,
                                   decode(w_mesi_calcolo,0,null,f_round(w_periodo * 12,0)),a_utente,
                                   decode(w_mesi_calcolo,0,w_giorni_ruolo,null),
                                   w_importo_ruolo_base
                                  )
                            ;
                         EXCEPTION
                            WHEN others THEN
                               w_errore := 'Errore in inserimento Ruoli Contribuente (2) '||
                                           'per '||w_cod_fiscale||' - ('||SQLERRM||')';
                               RAISE errore;
                         END;
                      END IF;
                   end if;
-- dbms_output.put_line('Sgravi: '||w_importo_sgravi);
                   if w_importo_sgravi < 0 or nvl(w_magg_tares_ogim_sgravi,0) < 0 then
                      -- se l'importo è maggiore di zero metto a sgravio la sola maggiorazione tares
                      if w_importo_sgravi > 0 then
                         w_importo_sgravi := 0;
                      end if;
                      -- se la maggiorazione tares è maggiore di zero non la metto a sgravio
                      if w_magg_tares_ogim_sgravi > 0 then
                         w_magg_tares_ogim_sgravi := 0;
                      end if;
                      w_importo_sgravio := 0 - w_importo_sgravi;
                      w_importo := 0;
                      w_magg_tares_sgravio := 0 - w_magg_tares_ogim_sgravi;
-- dbms_output.put_line('Importo sgravio: '||w_importo_sgravio||' Magg. Tares sgravio: '||w_magg_tares_sgravio);
-- dbms_output.put_line('Trattamento ogpr: '||rec_ogpr.oggetto_pratica_rif);
                      --
                      -- (VD - 23/10/2018): Calcolo importi tariffa base
                      --
                      if w_flag_tariffa_base = 'S' or w_flag_ruolo_tariffa = 'S' then
                         if w_importo_base < 0 then
                            w_importo_sgravio_base := 0 - w_importo_base;
                            w_importo_base := 0;
                         end if;
                      end if;
                      --
                      crea_sgravio_saldo(w_importo_sgravio
                                        ,w_importo_sgravio_base
                                        ,rec_ogpr.cod_fiscale
                                        ,w_anno_ruolo
                                        ,w_tipo_tributo
                                        ,rec_ogpr.oggetto_pratica_rif
                                        ,a_ruolo
                                        ,w_magg_tares_sgravio
                                        ,greatest(w_flag_tariffa_base,w_flag_ruolo_tariffa)
                                        );
                   END IF;  -- w_importo > 0
               end loop;
            end if;
        end if; -- Gestione del suppletivo pre e post 2013
      END IF;  -- Ruolo Suppletivo
      --
      -- (VD - 22/11/2017): Pontedera - calcolo e applicazione sconti per conferimento
      --
      if w_cod_istat = '050029' then
         cer_conferimenti.determina_sconto_conf(w_anno_ruolo
                                               ,a_ruolo
                                               ,w_tipo_ruolo
                                               ,w_tipo_emissione
                                               ,a_cod_fiscale
                                               ,a_utente
                                               );
         applica_sconto_conf(w_anno_ruolo
                            ,a_ruolo
                            ,a_tipo_limite
                            ,w_limite_ruolo
                            ,w_rate
                            ,a_cod_fiscale
                            );
      end if;
   END IF;
   --
   -- Applica il limite per contribuente
   --
   IF a_tipo_limite = 'C' THEN
      commit;
      FOR rec_ruco_limite IN sel_ruco_limite(a_ruolo,a_cod_fiscale,a_limite)
      LOOP
         BEGIN
            delete ruoli_contribuente
             where ruolo         = a_ruolo
               and cod_fiscale   = rec_ruco_limite.cod_fiscale
            ;
         EXCEPTION
            WHEN others THEN
               w_errore := 'Errore in eliminazione Ruoli Contribuente '||
                           'per '||w_cod_fiscale||' - ('||SQLERRM||')';
               RAISE errore;
         END;
         BEGIN
            delete ruoli_eccedenze
             where ruolo         = a_ruolo
               and cod_fiscale   = rec_ruco_limite.cod_fiscale
            ;
         EXCEPTION
            WHEN others THEN
               w_errore := 'Errore in eliminazione Ruoli Eccedenze '||
                           'per '||w_cod_fiscale||' - ('||SQLERRM||')';
               RAISE errore;
         END;
         BEGIN
            update oggetti_imposta
               set ruolo             = null
                  ,importo_ruolo     = null
                  ,addizionale_eca   = null
                  ,maggiorazione_eca = null
                  ,addizionale_pro   = null
                  ,iva               = null
             where ruolo             = a_ruolo
               and cod_fiscale       = rec_ruco_limite.cod_fiscale
            ;
         EXCEPTION
            WHEN others THEN
               w_errore := 'Errore in aggiornamento Oggetti Imposta '||
                           'per '||w_cod_fiscale||' - ('||SQLERRM||')';
               RAISE errore;
         END;
         BEGIN
            update sanzioni_pratica
               set ruolo         = null
                  ,importo_ruolo = null
             where ruolo         = a_ruolo
               and pratica      in (select pratica
                                      from pratiche_tributo prtr
                                     where prtr.cod_fiscale like rec_ruco_limite.cod_fiscale
                                   )
             ;
         EXCEPTION
            WHEN others THEN
               w_errore := 'Errore in aggiornamento Sanzioni Pratica'||
                           'per '||w_cod_fiscale||' - ('||SQLERRM||')';
               RAISE errore;
         END;
      END LOOP;
   END IF;
--
-- La seguente fase elimina i ruoli_contribuente per gli oggetti con imposta minore o uguale a zero e elimina
-- il numero del ruolo da oggetti_imposta per gli oggetti relativi
--
   IF a_tipo_limite = 'C' THEN
      FOR rec_importo_zero in sel_importo_zero(a_ruolo)
      LOOP
         BEGIN
            delete ruoli_contribuente
             where ruolo           = a_ruolo
               and cod_fiscale     = rec_importo_zero.cod_fiscale
               and oggetto_imposta = rec_importo_zero.oggetto_imposta
            ;
         EXCEPTION
            WHEN others THEN
               w_errore := 'Errore in eliminazione Ruoli Contribuente '||
                           'per '||rec_importo_zero.cod_fiscale||' - '||rec_importo_zero.oggetto_imposta||' ('||SQLERRM||')';
               RAISE errore;
         END;
         BEGIN
            update oggetti_imposta
               set ruolo             = null
                  ,importo_ruolo     = null
                  ,addizionale_eca   = null
                  ,maggiorazione_eca = null
                  ,addizionale_pro   = null
                  ,iva               = null
             where ruolo             = a_ruolo
               and cod_fiscale     = rec_importo_zero.cod_fiscale
               and oggetto_imposta = rec_importo_zero.oggetto_imposta
            ;
         EXCEPTION
            WHEN others THEN
               w_errore := 'Errore in aggiornamento Oggetti Imposta '||
                           'per '||rec_importo_zero.cod_fiscale||' - '||rec_importo_zero.oggetto_imposta||' ('||SQLERRM||')';
               RAISE errore;
         END;
      END LOOP;
   END IF;
--
-- Elimina tutte le eccedenze che non hanno un ruoli_contribuente (tariffe a zero o altri problemi di dizionario
--
  BEGIN
    delete ruoli_eccedenze ruec
     where ruec.ruolo = a_ruolo
       and not exists
           (select 1
              from ruoli_contribuente ruco
             where ruco.ruolo = a_ruolo
               and ruco.cod_fiscale = ruec.cod_fiscale
               and ruco.tributo = ruec.tributo)
    ;
  EXCEPTION
    WHEN others THEN
      w_errore := 'Errore in bonifica Eccedenze per '||w_cod_fiscale||' - ('||SQLERRM||')';
      RAISE errore;
  END;
--
-- La seguente fase assegna ai versamenti su oggetto imposta il nuovo oggetto imposta.
--
   FOR rec_vers in sel_vers (w_anno_ruolo
                            ,a_cod_fiscale
                            ,w_tipo_tributo
                            ,a_ruolo
                            )
   LOOP
      if nvl(rec_vers.rata,0) = 0 then
         BEGIN
            update versamenti vers
               set vers.ogpr_ogim       = null
                  ,vers.oggetto_imposta = rec_vers.oggetto_imposta
             where vers.cod_fiscale     = rec_vers.cod_fiscale
               and vers.anno            = rec_vers.anno
               and vers.tipo_tributo    = rec_vers.tipo_tributo
               and vers.sequenza        = rec_vers.sequenza
            ;
         EXCEPTION
           WHEN others THEN
              w_errore := 'Errore in Aggiornamento Versamenti (Riassegnazione Oggetto Imposta)'
                          ||' di '||rec_vers.cod_fiscale||' '||'('||SQLERRM||')';
              RAISE ERRORE;
         END;
      else
         BEGIN
            select raim.rata_imposta
              into w_rata_imposta
              from rate_imposta   raim
             where raim.oggetto_imposta = rec_vers.oggetto_imposta
               and raim.rata            = rec_vers.rata
               and raim.cod_fiscale     = rec_vers.cod_fiscale
               and raim.anno            = rec_vers.anno
               and raim.tipo_tributo    = w_tipo_tributo
            ;
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               w_rata_imposta := null;
         END;
         BEGIN
            update versamenti vers
               set vers.ogpr_ogim       = null
                  ,vers.rata_imposta    = w_rata_imposta
             where vers.cod_fiscale     = rec_vers.cod_fiscale
               and vers.anno            = rec_vers.anno
               and vers.tipo_tributo    = rec_vers.tipo_tributo
               and vers.sequenza        = rec_vers.sequenza
            ;
         EXCEPTION
           WHEN others THEN
              w_errore := 'Errore in Aggiornamento Versamenti (Riassegnazione Rata Imposta)'
                          ||' di '||rec_vers.cod_fiscale||' '||'('||SQLERRM||')';
              RAISE ERRORE;
         END;
      end if;
   END LOOP;
--
-- La seguente fase inserisce uno sgravio nel ruolo di acconto nel caso non sia andato a saldo
-- (VD - 01/12/2014): Modificata query per trattare solo oggetti validi
-- nell'anno per cui si sta emettendo il ruolo
--
   if w_tipo_emissione = 'S'  and w_tipo_ruolo = 1 then
      --dbms_output.put_line('Sgravio finale - ruolo acconto '||w_ruolo_acconto);
      FOR rec_ruco_acc in sel_ruco_acc (w_ruolo_acconto
                                       ,a_ruolo
                                       ,w_anno_ruolo
                                       )
      LOOP
        crea_sgravio_acconto(rec_ruco_acc.importo_residuo
                            ,rec_ruco_acc.importo_residuo_base
                            ,rec_ruco_acc.cod_fiscale
                            ,w_anno_ruolo
                            ,w_tipo_tributo
                            ,rec_ruco_acc.oggetto_pratica
                            ,a_ruolo
                            ,greatest(w_flag_tariffa_base,w_flag_ruolo_tariffa)
                            );
      end loop;
   end if;
   --
   -- (VD - 07/07/2020): Castelnuovo Garfagnana - Passaggio dati a DEPAG
   -- (VD - 28/09/2020): Modificati controlli su ruoli da trattare e
   --                    eliminata personalizzazione per Castelnuovo
   --                    Garfagnana
   -- (VD - 27/11/2020): Modificati controlli su ruoli da trattare: ora si
   --                    trattano anche i suppletivi
   -- (VD - 11/12/2020): Eliminati controlli per Castelnuovo Garfagnana
   --                    Ora l'integrazioe e' possibile per tutti i clienti
   --
   --w_pagonline := F_INPA_VALORE('PAGONLINE');
   if w_pagonline = 'S'
   and w_tipo_tributo = 'TARSU'
   --and w_tipo_ruolo = 1
   --and w_cod_istat = w_cod_castel
   --and w_tipo_emissione = 'T'
   then
      w_result := pagonline_tr4.inserimento_dovuti_ruolo ( w_tipo_tributo
                                                         , a_cod_fiscale
                                                         , w_anno_ruolo
                                                         , a_ruolo
      --                                                   , w_rate
                                                         );
      if w_result = -1 then
         w_errore:= 'Si e'' verificato un errore in fase di preparazione dati per PAGONLINE - verificare log';
         raise errore;
      end if;
   end if;
EXCEPTION
   WHEN FINE THEN
        null;
   WHEN errore THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20999,w_errore||'  '||w_tariffe,TRUE);
   WHEN others THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR
        (-20999,'Errore in Emissione Ruolo per '||w_cod_fiscale||' - '||w_stato||'('||SQLERRM||')');
END;
/* End Procedure: EMISSIONE_RUOLO */
/
