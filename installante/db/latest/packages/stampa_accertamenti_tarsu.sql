--liquibase formatted sql 
--changeset abrandolini:20250326_152429_stampa_accertamenti_tarsu stripComments:false runOnChange:true 
 
create or replace package stampa_accertamenti_tarsu is
/******************************************************************************
 NOME:        STAMPA_ACCERTAMENTI_TARSU
 DESCRIZIONE: Funzione per stampa avvisi di accertamento TARI - TributiWeb
 ANNOTAZIONI: -
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 000   XX/XX/XXXX  DM      Prima emissione.
 001   25/01/2022  VD      Aggiunte funzioni per stmpa accertamento manuale
                           e totale
 002   21/02/2022  VD      Aggiunta formattazione importi in tutte le funzioni
 003   10/01/2023  DM      Modifiche alla generazione dell'id operazione per
                           la gestione dei solleciti
 004   02/02/2023  RV      #issue55318
                           Aggiunta campi integrativi per sollecito
 005   09/02/2023  RV      #issue41758
                           Modificato riep_vers, rimossa distinzione pre/post 2021
 006   14/02/2023  RV      #issue55318
                           Modificato formattazione totali numerici come testi
 007   17/02/2023  RV      #issue41758
                           Modificato acc per scorporo importo/tefa
                           Modificato riep_vers per cod. f24 non definiti (diventa XXXX)
 008   22/02/2023  RV      #issue55318
                           Aggiunto data_scadenza
 009   21/04/2023  DM      #63750
                           Gestita TEFA solo per anni successivi al 2020
 010   21/06/2023  AB      #63043
                           Tolto il chr(10) prima dei familiari cosi vengono subito
 011   11/09/2023  VM      #62342
                           Tariffe domestiche e non domestiche su oggetti e man_oggetti
 011   20/11/2023  RV      #issue65966
                           Aggiunto gestione sanzione minima su riduzione
 012   17/06/2024  RV      #55525
                           Aggiunto INTERESSI_DETTAGLIO
 013   06/02/2025  RV      #77116
                           Flag sanz_min_rid da pratica non da inpa
 014   17/04/2025  RV      #79055
                           Aggiunto tag giorni occupazione in oggetti e man_oggetti
 015   10/06/2025          #79928
                           Aggiunta data cessazione (ogco_data_cessazione)                               
 016   30/07/2025   RV     #77694
                           Integrato gestione nuove sanzioni Componenti Perequative
******************************************************************************/
  function contribuente
  ( a_pratica              number default -1
  , a_ni_erede number default -1
  ) return sys_refcursor;
  function principale
  ( a_cf                   varchar2 default ''
  , a_prat                 number default ''
  , a_modello              number default -1
  , a_ni_erede             number default -1
  ) return sys_refcursor;
  function oggetti
  ( a_cf                   varchar2 default ''
  , a_prat                 number default -1
  , a_anno                 number default -1
  , a_modello              number default -1
  ) return sys_refcursor;
  function versamenti
  ( a_cf                   varchar2 default ''
  , a_prat                 number default -1
  , a_modello              number default -1
  , a_tot_imposta          varchar2 default ''
  , a_tot_magg_tares       varchar2 default ''
  ) return sys_refcursor;
  function addiz_int
  ( a_prat                 number default -1
  , a_modello              number default -1
  ) return sys_refcursor;
  function acc_imposta
  ( a_prat                 number default -1
  , a_modello              number default -1
  ) return sys_refcursor;
  function acc_magg
  ( a_prat                 number default -1
  , a_modello              number default -1
  ) return sys_refcursor;
  function sanz_int
  ( a_prat                 number default -1
  , a_modello              number default -1
  ) return sys_refcursor;
  function sanz_magg
  ( a_prat                 number default -1
  , a_modello number default -1
  ) return sys_refcursor;
  function riep_vers
  ( a_prat                 number default -1
  , a_modello              number default -1
  ) return sys_refcursor;
  function man_contribuente
  ( a_pratica              number default -1
  , a_ni_erede number default -1
  ) return sys_refcursor;
  function man_principale
  ( a_cf                                varchar2 default ''
  , a_prat                              number default -1
  , a_modello                           number default -1
  , a_ni_erede                          number default -1
  ) return sys_refcursor;
  function man_oggetti
  ( a_cf                                varchar2 default ''
  , a_prat                              number default -1
  , a_anno                              number default -1
  , a_modello                           number default -1
  ) return sys_refcursor;
  function man_versamenti
  ( a_cf                                varchar2 default ''
  , a_pratica                           number default -1
  , a_modello                           number default -1
  , a_tot_imposta                       varchar2 default ''
  , a_tot_magg_tares                    varchar2 default ''
  ) return sys_refcursor;
  function man_acc_imposta
  ( a_prat                              number default -1
  , a_modello                           number default -1
  ) return sys_refcursor;
  function man_acc_magg
  ( a_prat                              number default -1
  , a_modello                           number default -1
  ) return sys_refcursor;
  function man_sanz_int
  ( a_prat                              number default -1
  , a_modello                           number default -1
  ) return sys_refcursor;
  function man_sanz_magg
  ( a_prat                              number default -1
  , a_modello                           number default -1
  ) return sys_refcursor;
  function man_riep_vers
  ( a_prat                 number default -1
  , a_modello              number default -1
  ) return sys_refcursor;
  function aggi_dilazioni
  ( a_pratica                                   number default -1
  , a_modello                                   number default -1
  ) return sys_refcursor;
  function interessi_dettaglio
  ( a_pratica               number default -1
  , a_modello               number default -1
  ) return sys_refcursor;
  function eredi
  ( a_ni_deceduto           number default -1
  , a_ni_erede_da_escludere number default -1
  ) return sys_refcursor;
end stampa_accertamenti_tarsu;
/
create or replace package body stampa_accertamenti_tarsu is
/******************************************************************************
 NOME:        STAMPA_ACCERTAMENTI_TARSU
 DESCRIZIONE: Funzione per stampa avvisi di accertamento TARI - TributiWeb
 ANNOTAZIONI: -
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 000   XX/XX/XXXX  DM      Prima emissione
 001   25/01/2022  VD      Aggiunte funzioni per stampa accertamento manuale
                           e totale
 002   21/02/2022  VD      Aggiunta formattazione importi in tutte le funzioni
 003   10/01/2023  DM      Modifiche alla generazione dell'id operazione per
                           la gestione dei solleciti
 004   02/02/2023  RV      #issue55318
                           Aggiunta campi integrativi per sollecito
 005   09/02/2023  RV      #issue41758
                           Modificato riep_vers, rimossa distinzione pre/post 2021
 006   14/02/2023  RV      #issue55318
                           Modificato formattazione totali numerici come testi
 007   17/02/2023  RV      #issue41758
                           Modificato acc per scorporo importo/tefa
                           Modificato riep_vers per cod. f24 non definiti (diventa XXXX)
 008   22/02/2023  RV      #issue55318
                           Aggiunto data_scadenza
 009   27/04/2023  DM      #63045
                           Modificata la lunghezza di t_sanz_cols a 5, la to_char
                           aggiunge uno spazio ad inizio stringa per gestira l'eventuale
                           presenza del segno. Se il numero è di 4 cifre la string
                           risulterà essere lunga 5.
 010   20/09/2023  RV      #65965
                           Aggiunto due tag in 'riep_vers' per i totali F24 normale e ridotto
                           Aggiunto i due tag di cui sopra in 'principale' e 'man_principale'
 011   20/11/2023  RV      #issue65966
                           Aggiunto gestione sanzione minima su riduzione
 012   17/06/2024  RV      #55525
                           Aggiunto INTERESSI_DETTAGLIO
 013   06/02/2025  RV      #77116
                           Flag sanz_min_rid da pratica non da inpa
 014   17/04/2025  RV      #79055
                           Aggiunto tag giorni occupazione in oggetti e man_oggetti
 015   10/06/2025          #79928
                           Aggiunta data cessazione (ogco_data_cessazione)
 016   30/07/2025   RV     #77694
                           Integrato gestione nuove sanzioni Componenti Perequative
******************************************************************************/
function contribuente
( a_pratica                           number
, a_ni_erede number default -1
) return sys_refcursor
is
    rc sys_refcursor;
begin
  rc := stampa_common.contribuente(a_pratica, a_ni_erede);
  return rc;
end;
--
------------------------------------------------------------------
-- Verifica se annualità con Componenti Perequative
------------------------------------------------------------------
function f_contolla_cope
( p_pratica               in      number default -1
-- , p_anno                  out     number
-- , p_tot_perequative       out     number
) return number
is
  --
  w_anno                  number;
  --
  w_num_perequative       number;
  w_tot_perequative       number;
  --
begin
  begin
    select max(prtr.anno) as anno,
           count(cope.importo) as conteggio,
           sum(cope.importo) as tot_importo
      into w_anno,
           w_num_perequative,
           w_tot_perequative
      from componenti_perequative cope,
           pratiche_tributo prtr
     where cope.anno = prtr.anno
       and prtr.pratica = p_pratica
    ;
  exception
    when others then
      w_anno := 0;
      w_num_perequative := 0;
      w_tot_perequative := 0;
  end;
  --
--p_anno := w_anno;
--p_tot_perequative := w_tot_perequative;
  --
  return w_num_perequative;
end;
------------------------------------------------------------------
function principale
( a_cf                                varchar2
, a_prat                              number
, a_modello                           number
, a_ni_erede                          number
) return sys_refcursor
is
  rc                                  sys_refcursor;
  v_rc                                sys_refcursor;
  --
  v_acc_imposta_importo_tot           number(10, 2);
  v_acc_magg_importo_tot              number(10, 2);
  v_sanz_int_importo_tot              number(10, 2);
  v_sanz_magg_importo_tot             number(10, 2);
  v_importo_vers_tot                  varchar2(20);
  v_importo_vers_rid                  varchar2(20);
  --
  type t_acc_cols is record
  ( cod_sanzione                      number(4),
    sanz_ord1                         varchar2(50),
    sanz_ord                          varchar2(50),
    ord                               number(5),
    importo                           varchar2(20),
    perc_ed_importo                   varchar2(50),
    descrizione                       varchar2(100),
    accertamento_imposta              varchar2(100),
    importo_tot                       number(10, 2),
    st_importo_tot                    varchar2(20),
    importo_netto                     varchar2(20),
    importo_netto_tot                 varchar2(20),
    descrizione_tefa                  varchar2(100),
    importo_tefa                      varchar2(20),
    importo_tefa_tot                  varchar2(20)
  );
  v_acc_cols t_acc_cols;
  --
  type t_sanz_cols is record
  ( cod_sanzione                      number(4),
    importo                           number(10, 2),
    perc_ed_importo                   varchar2(50),
    descrizione                       varchar2(100),
    irrogazioni_sanz_int              varchar2(100),
    st_giorni                         varchar2(5),
    st_riduzione                      varchar2(8),
    st_perc_sanzione                  varchar2(8),
    st_importo_sanzione               varchar2(20),
    note                              varchar2(2000),
    importo_tot                       number(10, 2)
    --st_importo_tot                    varchar2(20)
  );
  v_sanz_cols t_sanz_cols;
  --
  type t_riep_vers is record
  ( cod_tributo                      number(4),
    descr_tributo                    varchar2(1000),
    importo                          varchar2(100),
    imp_ridotto                      varchar2(100),
    importo_non_st                   number(10, 2),
    importo_ridotto_non_st           number(10, 2),
    f24_intestazione                 varchar2(100),
    f24_totale                       varchar2(100),
    st_importo_vers_tot              varchar2(100),
    st_importo_vers_rid              varchar2(100)
  );
  v_riep_vers t_riep_vers;
  --
begin
  v_rc := acc_imposta(a_prat, a_modello);
  loop
    fetch v_rc
      into v_acc_cols;
    exit when v_rc%notfound;
    v_acc_imposta_importo_tot := v_acc_cols.importo_tot;
    --v_acc_imposta_importo_tot := v_acc_cols.st_importo_tot;
    exit;
    end loop;
  --
  v_rc := acc_magg(a_prat, a_modello);
  loop
    fetch v_rc
        into v_acc_cols;
    exit when v_rc%notfound;
    v_acc_magg_importo_tot := v_acc_cols.importo_tot;
    --v_acc_magg_importo_tot := v_acc_cols.st_importo_tot;
    exit;
  end loop;
  --
  v_rc := sanz_int(a_prat, a_modello);
  loop
    fetch v_rc
      into v_sanz_cols;
    exit when v_rc%notfound;
    v_sanz_int_importo_tot := v_sanz_cols.importo_tot;
    --v_sanz_int_importo_tot := v_sanz_cols.st_importo_tot;
    exit;
  end loop;
  --
  v_rc := sanz_magg(a_prat, a_modello);
  loop
    fetch v_rc
      into v_sanz_cols;
    exit when v_rc%notfound;
    v_sanz_magg_importo_tot := v_sanz_cols.importo_tot;
    --v_sanz_magg_importo_tot := v_sanz_cols.st_importo_tot;
    exit;
  end loop;
  --
  v_importo_vers_tot := 0;
  v_importo_vers_rid := 0;
  v_rc := man_riep_vers(a_prat, a_modello);
  loop
    fetch v_rc
      into v_riep_vers;
    exit when v_rc%notfound;
    v_importo_vers_tot := v_riep_vers.st_importo_vers_tot;
    v_importo_vers_rid := v_riep_vers.st_importo_vers_rid;
    exit;
  end loop;
  --
  open rc for
    select distinct --
                  '(Identificativo Operazione ' || decode(prtr_acc.tipo_pratica, 'A', 'ACCA', 'SOLL') || prtr_acc.anno ||
                  lpad(prtr_acc.pratica, 10, '0') || ')' as id_operazione_char,
                  decode(prtr_acc.tipo_pratica, 'A', 'ACCA', 'SOLL') || prtr_acc.anno ||
                  lpad(prtr_acc.pratica, 10, '0') as id_operazione,
                  a_modello modello,
                  a_cf cod_fiscale,
                  --
                  prtr_acc.pratica pratica,
                  translate(prtr_acc.motivo, chr(013) || chr(010), '  ') motivo,
                  lpad(prtr_acc.anno, 4) anno,
                  lpad(nvl(prtr_acc.numero, ' '), 15, '0') prtr_numero,
                  nvl(prtr_acc.numero, ' ') prtr_numero_vis,
                  prtr_acc.anno prtr_anno,
                  nvl(to_char(prtr_acc.data, 'dd/mm/yyyy'), ' ') data,
                  nvl(to_char(prtr_acc.data_scadenza, 'dd/mm/yyyy'), ' ') data_scadenza,
                  nvl(spese_notifica_rivoli.importo, 0) snr,
                  decode(rtrim(f_descrizione_timp(a_modello, 'INTE')),
                         'DEFAULT',
                         f_tipo_accertamento(ogpr_acc.oggetto_pratica),
                         rtrim(f_descrizione_timp(a_modello, 'INTE'))) tipo_acc,
                  stampa_common.f_formatta_numero(prtr_acc.importo_totale +
                                                  nvl(addiz.tot_add, 0) -
                                                  nvl(spese_notifica_rivoli.importo,0),
                                                  'I','S') importo_totale,
                  prtr_acc.importo_totale + nvl(addiz.tot_add, 0) -
                  nvl(spese_notifica_rivoli.importo, 0) importo_totale_num_riv,
                  decode(f_descrizione_timp(a_modello,'VIS_TOT_ARR'),
                         'SI',
                         decode(titr.flag_tariffa,
                                null,
                                stampa_common.f_formatta_numero(round(prtr_acc.importo_totale +
                                                                      nvl(addiz.tot_add,0) -
                                                                      nvl(spese_notifica_rivoli.importo,0),
                                                                      0),'I','S'),
                                null),
                         null) importo_totale_arrotondato,
                  decode(nvl(spese_notifica_rivoli.importo, 0),
                         0,
                         decode(prtr_acc.importo_ridotto,
                                prtr_acc.importo_totale,
                                null,
                                stampa_common.f_formatta_numero(f_round(prtr_acc.importo_ridotto +
                                                                        nvl(addiz.tot_add,0),
                                                                        1),
                                                                'I','S')
                             ),
                         decode(prtr_acc.importo_ridotto,
                                prtr_acc.importo_totale,
                                null,
                                stampa_common.f_formatta_numero(f_round(prtr_acc.importo_ridotto +
                                                                        nvl(addiz.tot_add,0) -
                                                                        nvl(spese_notifica_rivoli.importo,0),
                                                                        1),
                                                                'I','S')
                             )
                      ) importo_ridotto,
                  decode(f_descrizione_timp(a_modello, 'VIS_TOT_ARR'),
                         'SI',
                         decode(nvl(spese_notifica_rivoli.importo, 0),
                                0,
                                decode(prtr_acc.importo_ridotto,
                                       prtr_acc.importo_totale,
                                       null,
                                       stampa_common.f_formatta_numero(decode(titr.flag_tariffa,
                                                                              null,
                                                                              round(prtr_acc.importo_ridotto +
                                                                                    nvl(addiz.tot_add,
                                                                                        0),
                                                                                    0),
                                                                              null),
                                                                       'I','S')
                                    ),
                                decode(prtr_acc.importo_ridotto,
                                       prtr_acc.importo_totale,
                                       null,
                                       stampa_common.f_formatta_numero(decode(titr.flag_tariffa,
                                                                              null,
                                                                              round(prtr_acc.importo_ridotto +
                                                                                    nvl(addiz.tot_add,
                                                                                        0) -
                                                                                    nvl(spese_notifica_rivoli.importo,
                                                                                        0),
                                                                                    0),
                                                                              null),
                                                                       'I','S')
                                    )),
                         '') importo_ridotto_arrotondato,
                  decode(nvl(spese_notifica_rivoli.importo,0),
                         0,
                         null,
                         'SPESE DI NOTIFICA' || lpad(' ', 59, ' ') ||
                         stampa_common.f_formatta_numero(nvl(spese_notifica_rivoli.importo,0),
                                                         'I','S')
                      ) label_spese_notifica,
                  decode(nvl(spese_notifica_rivoli.importo, 0),
                         0,
                         null,
                         f_descrizione_timp(a_modello, 'TOT_RIV')) l_totale_rivoli,
                  decode(nvl(spese_notifica_rivoli.importo, 0),
                         0,
                         null,
                         stampa_common.f_formatta_numero(decode(titr.flag_tariffa,
                                                                null,
                                                                round(prtr_acc.importo_totale +
                                                                      nvl(addiz.tot_add,
                                                                          0) -
                                                                      nvl(spese_notifica_rivoli.importo,
                                                                          0),
                                                                      0) +
                                                                nvl(spese_notifica_rivoli.importo,
                                                                    0),
                                                                null),
                                                         'I','S')
                      ) importo_totale_rivoli,
                  decode(nvl(spese_notifica_rivoli.importo, 0),
                         0,
                         null,
                         decode(prtr_acc.importo_ridotto,
                                prtr_acc.importo_totale,
                                null,
                                f_descrizione_timp(a_modello,'TOT_RID_RIV')
                               )
                  ) l_totale_ridotto_rivoli,
                  decode(nvl(spese_notifica_rivoli.importo, 0),
                         0,
                         null,
                         decode(prtr_acc.importo_ridotto,
                                prtr_acc.importo_totale,
                                null,
                                stampa_common.f_formatta_numero(decode(titr.flag_tariffa,
                                                                       null,
                                                                       round(prtr_acc.importo_ridotto +
                                                                             nvl(addiz.tot_add,
                                                                                 0) -
                                                                             nvl(spese_notifica_rivoli.importo,
                                                                                 0),
                                                                             0) +
                                                                       nvl(spese_notifica_rivoli.importo,
                                                                           0),
                                                                       null),
                                                                'I','S'))
                      ) importo_totale_ridotto_rivoli,
                  decode(fase_euro, 1, 'PARI AD EURO', '') pari_euro,
                  decode(fase_euro,
                         1,
                         stampa_common.f_formatta_numero(round((round((((prtr_acc.importo_totale +
                                                                         nvl(addiz.tot_add,
                                                                             0)) - 1) / 1000),
                                                                      0) * 1000) /
                                                               DATI_GENERALI.cambio_euro,
                                                               2),
                                                         'I','S'),
                         '') importo_totale_euro,
                  decode(fase_euro,
                         1,
                         stampa_common.f_formatta_numero(round((round((((prtr_acc.importo_ridotto +
                                                                         nvl(addiz.tot_add,
                                                                             0)) - 1) / 1000),
                                                                      0) * 1000) /
                                                               "DATI_GENERALI".cambio_euro,
                                                               2),
                                                         'I','S'),
                         '') importo_ridotto_euro,
                  ' ' x,
                  f_descrizione_timp(a_modello, 'TOT') totale,
                  decode(titr.flag_tariffa,
                         null,
                         decode(f_descrizione_timp(a_modello,'VIS_TOT_ARR'),
                                'SI',
                                f_descrizione_timp(a_modello, 'TOT_ARR'),
                                ''),
                         null) totale_arr,
                  decode(prtr_acc.importo_ridotto,
                         prtr_acc.importo_totale,
                         null,
                         f_descrizione_timp(a_modello, 'TOT_AD')) totale_ad,
                  decode(prtr_acc.importo_ridotto,
                         prtr_acc.importo_totale,
                         null,
                         decode(titr.flag_tariffa,
                                null,
                                decode(f_descrizione_timp(a_modello,'VIS_TOT_ARR'),
                                       'SI',
                                       f_descrizione_timp(a_modello,'TOT_AD_ARR'),
                                       ''),
                                null)) totale_ad_arr,
                  f_descrizione_timp(a_modello, 'TOT_IMP_COMP') totale_imposta_complessiva,
                  trim(f_descrizione_timp(a_modello, 'RIE_SOM_DOV')) riepilogo_somme_dovute,
                  decode(cata.maggiorazione_tares,
                         null,
                         '',
                         decode(sign(length('TOTALE MAGGIORAZIONE TARES') -
                                     nvl(length(f_descrizione_timp(a_modello,'TOT_IMP_COMP')),
                                         0)),
                                1,
                                'TOTALE MAGGIORAZIONE TARES',
                                rpad('TOTALE MAGGIORAZIONE TARES',
                                     length(nvl(f_descrizione_timp(a_modello,'TOT_IMP_COMP'),
                                                0))))) totale_magg_tares,
                  prtr_acc.tipo_evento,
                  --
                  f_descrizione_titr(prtr_acc.tipo_tributo,
                                     prtr_acc.anno) descr_titr,
                  sopr.*,
                  --
                  (select stampa_common.f_formatta_numero(
                                  sum(f_round(nvl(decode(decode(cotr01.flag_ruolo,
                                                                null,'N',
                                                                nvl(cata01.flag_lordo,'N')),
                                                         'S',
                                                         sum(nvl(ogim01.addizionale_eca,0) +
                                                             nvl(ogim01.maggiorazione_eca,0) +
                                                             nvl(ogim01.addizionale_pro,0) +
                                                             nvl(ogim01.iva, 0)),
                                                         0) +
                                                  sum(nvl(ogim01.imposta, 0) +
                                                      (nvl(ogim01.maggiorazione_tares, 0) * cope01.presenti)),
                                                  0),
                                              1)),
                                  'I','S')
                   from OGGETTI_IMPOSTA       ogim01,
                        OGGETTI_CONTRIBUENTE  ogco01,
                        OGGETTI_PRATICA       ogpr01,
                        PRATICHE_TRIBUTO      prtr01,
                        carichi_tarsu         cata01,
                        soggetti_pratica      sopr01,
                        codici_tributo        cotr01,
                        (
                        select decode(count(cope.componente),0,0,1) as presenti
                          from componenti_perequative cope,
                               pratiche_tributo prtr
                         where cope.anno = prtr.anno
                           and prtr.pratica = a_prat
                        )                     cope01
                   where (ogim01.ANNO(+) = ogco01.anno)
                     and (ogim01.COD_FISCALE(+) =
                          ogco01.COD_FISCALE)
                     and (ogim01.OGGETTO_PRATICA(+) =
                          ogco01.OGGETTO_PRATICA)
                     and (ogco01.COD_FISCALE = a_cf)
                     and (ogco01.OGGETTO_PRATICA =
                          ogpr01.OGGETTO_PRATICA)
                     and (ogpr01.PRATICA = prtr01.PRATICA)
                     and (prtr01.PRATICA = a_prat)
                     and cata01.anno = prtr01.anno
                     and sopr01.pratica = a_prat
                     and cotr01.tributo = ogpr01.tributo
                   group by
                         cotr01.flag_ruolo,
                         cata01.flag_lordo,
                         ogim01.addizionale_eca,
                         ogim01.maggiorazione_eca,
                         ogim01.addizionale_pro,
                         ogim01.iva,
                         ogim01.imposta) tot_imposta,
                  (select stampa_common.f_formatta_numero(
                                  round(sum(f_round(nvl(decode(decode(cotr01.flag_ruolo,
                                                                      null,'N',
                                                                      nvl(cata01.flag_lordo,'N')
                                                                     ),
                                                               'S',
                                                               sum(nvl(ogim01.addizionale_eca,0) +
                                                                   nvl(ogim01.maggiorazione_eca,0) +
                                                                   nvl(ogim01.addizionale_pro,0) +
                                                                   nvl(ogim01.iva, 0)),
                                                               0) +
                                                        sum(nvl(ogim01.imposta, 0) +
                                                            (nvl(ogim01.maggiorazione_tares, 0) * cope01.presenti)),
                                                        0),
                                                    1))),
                                  'I','S')
                   from OGGETTI_IMPOSTA       ogim01,
                        OGGETTI_CONTRIBUENTE  ogco01,
                        OGGETTI_PRATICA       ogpr01,
                        PRATICHE_TRIBUTO      prtr01,
                        carichi_tarsu         cata01,
                        soggetti_pratica      sopr01,
                        codici_tributo        cotr01,
                        (
                        select decode(count(cope.componente),0,0,1) as presenti
                          from componenti_perequative cope,
                               pratiche_tributo prtr
                         where cope.anno = prtr.anno
                           and prtr.pratica = a_prat
                        )                     cope01
                   where (ogim01.ANNO(+) = ogco01.anno)
                     and (ogim01.COD_FISCALE(+) =
                          ogco01.COD_FISCALE)
                     and (ogim01.OGGETTO_PRATICA(+) =
                          ogco01.OGGETTO_PRATICA)
                     and (ogco01.COD_FISCALE = a_cf)
                     and (ogco01.OGGETTO_PRATICA =
                          ogpr01.OGGETTO_PRATICA)
                     and (ogpr01.PRATICA = prtr01.PRATICA)
                     and (prtr01.PRATICA = a_prat)
                     and cata01.anno = prtr01.anno
                     and sopr01.pratica = a_prat
                     and cotr01.tributo = ogpr01.tributo
                   group by
                         cotr01.flag_ruolo,
                         cata01.flag_lordo,
                         ogim01.addizionale_eca,
                         ogim01.maggiorazione_eca,
                         ogim01.addizionale_pro,
                         ogim01.iva,
                         ogim01.imposta) tot_imposta_arr,
                  (select sum(f_round(sum(nvl(ogim02.maggiorazione_tares,0)),1)) magg_tares_acc_no_visibile
                     from "OGGETTI_IMPOSTA"      ogim02,
                          "OGGETTI_CONTRIBUENTE" ogco02,
                          "OGGETTI_PRATICA"      ogpr02,
                          "PRATICHE_TRIBUTO"     prtr02,
                          carichi_tarsu          cata02,
                          soggetti_pratica       sopr02
                   where (ogim02."ANNO"(+) = ogco02.anno)
                     and (ogim02."COD_FISCALE"(+) =
                          ogco02."COD_FISCALE")
                     and (ogim02."OGGETTO_PRATICA"(+) =
                          ogco02."OGGETTO_PRATICA")
                     and (ogco02."COD_FISCALE" = a_cf)
                     and (ogco02."OGGETTO_PRATICA" =
                          ogpr02."OGGETTO_PRATICA")
                     and (ogpr02."PRATICA" = prtr02."PRATICA")
                     and (prtr02."PRATICA" = a_prat)
                     and cata02.anno = prtr02.anno
                     and sopr02.pratica = a_prat
                   group by
                         ogim02.maggiorazione_eca) tot_magg_tares,
                  --
                  decode(v_acc_imposta_importo_tot,
                         NULL,
                         NULL,
                         f_descrizione_timp(a_modello, 'TOTACCIMP')) label_acc_imposta_importo_tot,
                  stampa_common.f_formatta_numero(v_acc_imposta_importo_tot,'I','S') acc_imposta_importo_tot,
                  decode(v_sanz_int_importo_tot,
                         null,
                         null,
                         f_descrizione_timp(a_modello, 'TOTSANZ')) label_sanz_int_importo_tot,
                  stampa_common.f_formatta_numero(v_sanz_int_importo_tot,'I','S') sanz_int_importo_tot,
                  decode(v_acc_magg_importo_tot,
                         NULL,NULL,
                         decode(cope.presenti
                               ,1,'TOTALE COMPONENTI PEREQUATIVE EVASE'
                               ,'TOTALE MAGG. TARES EVASA'
                               )
                         ) label_acc_magg_importo_tot,
                  stampa_common.f_formatta_numero(v_acc_magg_importo_tot,'I','S') acc_magg_importo_tot,
                  decode(v_sanz_magg_importo_tot,
                         null,
                         null,
                         f_descrizione_timp(a_modello, 'TOTSANZ')) label_sanz_magg_importo_tot,
                  stampa_common.f_formatta_numero(v_sanz_magg_importo_tot,'I','S') sanz_magg_importo_tot,
                  -- Duplicati per i solleciti, cambia solo acc_ e diventa sol_
                  decode(v_acc_imposta_importo_tot,
                         NULL,
                         NULL,
                         f_descrizione_timp(a_modello, 'TOTACCIMP')) label_sol_imposta_importo_tot,
                  stampa_common.f_formatta_numero(v_acc_imposta_importo_tot,'I','S') sol_imposta_importo_tot,
                  decode(v_acc_magg_importo_tot,
                         NULL,NULL,
                         decode(cope.presenti
                               ,1,'TOTALE COMPONENTI PEREQUATIVE EVASE'
                               ,'TOTALE MAGG. TARES EVASA'
                               )
                        ) label_sol_magg_importo_tot,
                  stampa_common.f_formatta_numero(v_acc_magg_importo_tot,'I','S') sol_magg_importo_tot
                  --
                 , decode(f_descrizione_timp(a_modello, 'VIS_TOT_ARR')
                         ,'SI',v_importo_vers_tot
                         ,null
                         ) importo_totale_arrotondato_F24
                 , decode(f_descrizione_timp(a_modello,'VIS_TOT_ARR')
                         ,'SI',v_importo_vers_rid
                         ,null
                         ) importo_rid_arrotondato_F24
                  --
                 , a_ni_erede                           ni_erede
                from "ARCHIVIO_VIE",
                     "DATI_GENERALI",
                     "OGGETTI",
                     "CATEGORIE" cate,
                     "TARIFFE" tari,
                     "OGGETTI_IMPOSTA" ogim_acc,
                     "OGGETTI_CONTRIBUENTE" ogco_acc,
                     "OGGETTI_PRATICA" ogpr_acc,
                     "PRATICHE_TRIBUTO" prtr_acc,
                     tipi_tributo titr,
                     carichi_tarsu cata,
                     soggetti_pratica sopr,
                     (select decode(ruol."INVIO_CONSORZIO",
                                    null,
                                    0,
                                    ogpr_dic."CONSISTENZA") cons,
                             ogpr_dic."OGGETTO_PRATICA" ogpr,
                             ogim_dic."ANNO" a_anno,
                             ogpr_dic."CONSISTENZA" consistenza,
                             ogco_dic."PERC_POSSESSO" perc_possesso,
                             nvl(TO_CHAR(ogco_dic."DATA_DECORRENZA", 'dd/mm/yyyy'),
                                 NULL) data_decorrenza,
                             nvl(TO_CHAR(ogco_dic."DATA_CESSAZIONE", 'dd/mm/yyyy'),
                                 NULL) data_cessazione,
                             tari_dic."TARIFFA" tariffa,
                             tari_dic."DESCRIZIONE" descrizione
                      from "RUOLI"                ruol,
                           "TARIFFE"              tari_dic,
                           "OGGETTI_CONTRIBUENTE" ogco_dic,
                           "OGGETTI_PRATICA"      ogpr_dic,
                           "OGGETTI_IMPOSTA"      ogim_dic,
                           "PRATICHE_TRIBUTO"     prtr_dic
                      where (prtr_dic."PRATICA" = ogpr_dic."PRATICA")
                        and (prtr_dic."TIPO_PRATICA" = 'D')
                        and (prtr_dic."TIPO_TRIBUTO" || '' = 'TARSU')
                        and (tari_dic."ANNO" = ogco_dic.anno)
                        and (tari_dic."TRIBUTO" = ogpr_dic."TRIBUTO")
                        and (tari_dic."CATEGORIA" = ogpr_dic."CATEGORIA")
                        and (tari_dic."TIPO_TARIFFA" = ogpr_dic."TIPO_TARIFFA")
                        and (ogim_dic."RUOLO" = ruol.ruolo(+))
                        and (ogim_dic."COD_FISCALE"(+) = ogco_dic."COD_FISCALE")
                        and (ogim_dic."OGGETTO_PRATICA"(+) =
                             ogco_dic."OGGETTO_PRATICA")
                        and (ogco_dic."OGGETTO_PRATICA" =
                             ogpr_dic."OGGETTO_PRATICA")
                        and (ogco_dic."COD_FISCALE" = a_cf)
                      group by decode(ruol."INVIO_CONSORZIO",
                                      null,
                                      0,
                                      ogpr_dic."CONSISTENZA"),
                               ogpr_dic."OGGETTO_PRATICA",
                               ogim_dic."ANNO",
                               ogpr_dic."CONSISTENZA",
                               ogco_dic."PERC_POSSESSO",
                               ogco_dic."DATA_DECORRENZA",
                               ogco_dic."DATA_CESSAZIONE",
                               tari_dic."TARIFFA",
                               tari_dic."DESCRIZIONE") ogdic,
                     (select prtr_acc_cate.pratica pratica,
                             nvl(sum(f_cata(cata.anno,
                                            1,
                                            nvl(sapr.importo, sanzioni.sanzione),
                                            'T')),
                                 0) tot_add
                      from dati_generali,
                           carichi_tarsu    cata,
                           sanzioni_pratica sapr,
                           sanzioni,
                           pratiche_tributo prtr_acc_cate
                      where cata.anno = prtr_acc_cate.anno
                        and sanzioni.tipo_tributo = 'TARSU'
                        and (sanzioni.cod_sanzione in (1, 100, 101) or
                             sanzioni.tipo_causale ||
                             nvl(sanzioni.flag_magg_tares, 'N') = 'EN')
                        and sanzioni.cod_sanzione not in (888, 889)
                        and sapr.pratica in (a_prat)
                        and sanzioni.cod_sanzione = sapr.cod_sanzione
                        and sanzioni.sequenza = sapr.sequenza_sanz
                        and sapr.pratica = prtr_acc_cate.pratica
                      group by prtr_acc_cate.pratica
                     ) addiz,
                     (select sapr.pratica pratica, nvl(sum(sapr.importo), 0) importo
                      from dati_generali dage, sanzioni_pratica sapr
                      where lpad(to_char(dage.pro_cliente), 3, '0') ||
                            lpad(to_char(dage.com_cliente), 3, '0') = '001219'
                        and sapr.pratica in (a_prat)
                        and sapr.cod_sanzione in (15, 115, 198)
                      group by sapr.pratica
                     ) spese_notifica_rivoli,
                     (
                      select decode(count(cope.componente),0,0,1) as presenti
                        from componenti_perequative cope,
                             pratiche_tributo prtr
                       where cope.anno = prtr.anno
                         and prtr.pratica = a_prat
                     ) cope
                where ("OGGETTI"."COD_VIA" = "ARCHIVIO_VIE"."COD_VIA"(+))
                  and ("OGGETTI"."OGGETTO" = ogpr_acc."OGGETTO")
                  and (cate."TRIBUTO" = tari."TRIBUTO")
                  and (cate."CATEGORIA" = tari."CATEGORIA")
                  and (tari."ANNO" = ogco_acc.anno)
                  and (tari."TRIBUTO" = ogpr_acc."TRIBUTO")
                  and (tari."CATEGORIA" = ogpr_acc."CATEGORIA")
                  and (tari."TIPO_TARIFFA" = ogpr_acc."TIPO_TARIFFA")
                  and (ogim_acc."ANNO"(+) = ogco_acc.anno)
                  and (ogim_acc."COD_FISCALE"(+) = ogco_acc."COD_FISCALE")
                  and (ogim_acc."OGGETTO_PRATICA"(+) = ogco_acc."OGGETTO_PRATICA")
                  and (ogco_acc."COD_FISCALE" = a_cf)
                  and (ogco_acc."OGGETTO_PRATICA" = ogpr_acc."OGGETTO_PRATICA")
                  and (nvl(ogpr_acc."OGGETTO_PRATICA_RIF_V",
                           ogpr_acc."OGGETTO_PRATICA_RIF") = ogdic.ogpr(+))
                  and (ogpr_acc.anno = ogdic.a_anno(+))
                  and (addiz.pratica(+) = prtr_acc."PRATICA")
                  and (spese_notifica_rivoli.pratica(+) = prtr_acc."PRATICA")
                  and (ogpr_acc."PRATICA" = prtr_acc."PRATICA")
                  and (prtr_acc."TIPO_TRIBUTO" = titr.tipo_tributo)
                  and (prtr_acc."PRATICA" = a_prat)
                  and cata.anno = prtr_acc.anno
                  and sopr.pratica = a_prat
                order by prtr_acc.pratica;
  --
  return rc;
end;
--------------------------------------------------------------
function oggetti
( a_cf                                varchar2
, a_prat                              number
, a_anno                              number
, a_modello                           number
) return sys_refcursor
is
  --
  rc sys_refcursor;
  --
begin
  open rc for
    select
       ogg.*,
       f_cope_dettagli(ogg.prtr_anno, ogg.imposta_dovuta_cope_num, null) as dett_imposta_cope,
       sum(imposta_dovuta_acc_no_visibile) over() as tot_imp_comp,
       decode(totale_magg_tares,null,null,
                   sum(magg_tares_acc_no_visibile) over()) as tot_magg_tares
    from (
         select distinct
                decode(sum(nvl(ogim_acc.addizionale_eca, 0)),
                       0,
                       ' ',
                       'ADDIZIONALE ECA :') s_addizionale_eca,
                rpad(ltrim(decode(sum(nvl(ogim_acc.addizionale_eca,
                                          0)),
                                  0,
                                  '                    ',
                                  stampa_common.f_formatta_numero(sum(nvl(ogim_acc.addizionale_eca,
                                                                          0)),
                                                                  'I','S'))),
                     30) imposta_dovuta_add_eca,
                decode(sum(nvl(ogim_acc.maggiorazione_eca, 0)),
                       0,
                       ' ',
                       'MAG. ECA        :') s_maggiorazione_eca,
                rpad(decode(sum(nvl(ogim_acc.maggiorazione_eca,
                                    0)),
                            0,
                            '                    ',
                            ltrim(stampa_common.f_formatta_numero(sum(nvl(ogim_acc.maggiorazione_eca,
                                                                          0)),
                                                                  'I','S'))),
                     30) imposta_dovuta_mag_eca,
                decode(sum(nvl(ogim_acc.addizionale_pro, 0)),
                       0,
                       ' ',
                       rpad(f_descrizione_adpr(prtr_acc.anno),
                            16) || ':') s_addizionale_provinciale,
                rpad(decode(sum(nvl(ogim_acc.addizionale_pro,
                                    0)),
                            0,
                            '                    ',
                            ltrim(stampa_common.f_formatta_numero(sum(nvl(ogim_acc.addizionale_pro,
                                                                          0)),
                                                                  'I','S'))),
                     30) imposta_dovuta_add_pro,
                decode(sum(nvl(ogim_acc.iva, 0)),
                       0,
                       ' ',
                       'IVA             :') s_iva,
                rpad(decode(sum(nvl(ogim_acc.iva, 0)),
                            0,
                            '                    ',
                            ltrim(stampa_common.f_formatta_numero(sum(nvl(ogim_acc.iva,
                                                                          0)),
                                                                  'I','S'))),
                     30) imposta_dovuta_iva,
                prtr_acc.pratica pratica,
                rpad(nvl(cate."DESCRIZIONE", ' '), 30) categorie_desc,
                lpad(nvl(to_char(ogim_acc."ANNO"), ' '), 10) anno,
                lpad(nvl(prtr_acc.numero, ' '), 15, '0') prtr_numero,
                nvl(prtr_acc.numero, ' ') prtr_numero_vis,
                prtr_acc.anno prtr_anno,
                nvl(to_char(ogco_acc.inizio_occupazione,
                            'dd/mm/yyyy'),
                    ' ') ogco_inizio_occup,
                nvl(to_char(ogco_acc.data_decorrenza,
                            'dd/mm/yyyy'),
                    ' ') ogco_data_decorrenza,
                nvl(to_char(ogco_acc.data_cessazione,
                            'dd/mm/yyyy'),
                    ' ') ogco_data_cessazione,
                nvl(to_char(ogco_acc.fine_occupazione,
                            'dd/mm/yyyy'),
                    ' ') ogco_fine_occup,
                'mq.' mqacc,
                decode(ogco_acc.inizio_occupazione,
                       null,
                       ' ',
                       'INIZIO OCCUPAZ. :') sinizio_occup,
                decode(ogco_acc.data_decorrenza,
                       null,
                       ' ',
                       'DATA DECORRENZA :') sdata_decor,
                decode(ogco_acc.fine_occupazione,
                       null,
                       ' ',
                       'FINE OCCUPAZIONE:') sfine_occup,
                nvl(to_char(prtr_acc.data, 'dd/mm/yyyy'), ' ') data,
                decode(ogpr_acc.oggetto_pratica_rif,
                       null,
                       'omessa presentazione della denuncia',
                       'rettifica della denuncia presentata') tipo_acc,
                decode(ogpr_acc.oggetto_pratica_rif,
                       null,
                       '          ',
                       'DICHIARATI') sdichiarati,
                rpad(decode(sum(nvl(ogim_acc.imposta, 0))
                            ,0
                            ,'                    '
                            ,ltrim(stampa_common.f_formatta_numero(f_round(sum(nvl(ogim_acc.imposta,0))
                                                                          ,1),'I','S'))
                           ),
                     30) imposta_acc,
                rpad(decode(sum(nvl(ogim_acc.imposta, 0) +
                                (nvl(ogim_acc.maggiorazione_tares, 0) * cope.presenti)),
                            0,
                            '                    ',
                            ltrim(stampa_common.f_formatta_numero(f_round(nvl(decode(decode(cotr.flag_ruolo,
                                                                                            null,
                                                                                            'N',
                                                                                            nvl(cata.flag_lordo,
                                                                                                'N')),
                                                                                     'S',
                                                                                     sum(nvl(ogim_acc.addizionale_eca,0) +
                                                                                         nvl(ogim_acc.maggiorazione_eca,0) +
                                                                                         nvl(ogim_acc.addizionale_pro,0) +
                                                                                         nvl(ogim_acc.iva,0)
                                                                                         ),
                                                                                     0) +
                                                                              sum(nvl(ogim_acc.imposta,0) +
                                                                                  (nvl(ogim_acc.maggiorazione_tares, 0) * cope.presenti)
                                                                                 ),
                                                                              0),
                                                                          1),
                                                                  'I','S'))),
                     30) imposta_dovuta,
                f_round(nvl(decode(decode(cotr.flag_ruolo,
                                          null,
                                          'N',
                                          nvl(cata.flag_lordo,'N')
                                         ),
                                   'S',sum(nvl(ogim_acc.addizionale_eca,0) +
                                           nvl(ogim_acc.maggiorazione_eca,0) +
                                           nvl(ogim_acc.addizionale_pro,0) +
                                           nvl(ogim_acc.iva, 0)
                                           )
                                    ,0
                                   ) +
                            sum(nvl(ogim_acc.imposta, 0) +
                                (nvl(ogim_acc.maggiorazione_tares, 0) * cope.presenti)
                               )
                            ,0)
                         ,1
                ) imposta_dovuta_acc_no_visibile,
                decode(sum(nvl(ogim_acc.imposta, 0) +
                           (nvl(ogim_acc.maggiorazione_tares, 0) * cope.presenti)
                          )
                       ,0 , ' '
                       ,f_descrizione_timp(a_modello,'DIC ACC IMP DOV') || ':'
                ) st_imposta_dovuta,
                rpad(substr(nvl(tari."DESCRIZIONE", ' '), 1, 36)
                    ,36
                ) tariffa_desc,
                nvl(stampa_common.f_formatta_numero(tari.riduzione_quota_fissa,'P','S'),' ')             riduzione_quota_fissa,
                nvl(stampa_common.f_formatta_numero(tari.riduzione_quota_variabile,'P','S') ,' ')        riduzione_quota_variabile,
                nvl(stampa_common.f_formatta_numero(tado.tariffa_quota_fissa,'T','S'),' ')               tariffa_dom_quota_fissa,
                nvl(stampa_common.f_formatta_numero(tado.tariffa_quota_variabile,'T','S'),' ')           tariffa_dom_quota_variabile,
                nvl(stampa_common.f_formatta_numero(tado.tariffa_quota_fissa_no_ap,'T','S'),' ')         tariffa_dom_quota_fissa_no_ap,
                nvl(stampa_common.f_formatta_numero(tado.tariffa_quota_variabile_no_ap,'T','S'),' ')     tariffa_dom_quota_var_no_ap,
                nvl(stampa_common.f_formatta_numero(tand.tariffa_quota_fissa,'T','S'),' ')               tariffa_nondom_quota_fissa,
                nvl(stampa_common.f_formatta_numero(tand.tariffa_quota_variabile,'T','S'),' ')           tariffa_nondom_quota_variabile,
                'Estremi Oggetto : ' st_estremi_oggetto,
                rpad("OGGETTI"."PARTITA", 9) partita,
                rpad("OGGETTI"."SEZIONE", 5) sezione,
                rpad("OGGETTI"."FOGLIO", 7) foglio,
                rpad("OGGETTI"."NUMERO", 7) numero,
                rpad("OGGETTI"."SUBALTERNO", 5) subalterno,
                rpad("OGGETTI"."ZONA", 5) zona,
                'Estremi Catasto: ' st_estremi_catasto,
                rpad("OGGETTI"."PROTOCOLLO_CATASTO", 7) protocollo_catasto,
                rpad(to_char("OGGETTI"."ANNO_CATASTO"), 5) anno_catasto,
                rpad("OGGETTI"."CATEGORIA_CATASTO", 5) categoria_catasto,
                rpad("OGGETTI"."CLASSE_CATASTO", 4) classe_catasto,
                decode("OGGETTI"."PARTITA",
                       null,
                       '',
                       'Partita  ') st_partita,
                decode("OGGETTI"."SEZIONE", null, '', 'Sez. ') st_sezione,
                decode("OGGETTI"."FOGLIO", null, '', 'Foglio ') st_foglio,
                decode("OGGETTI"."NUMERO", null, '', 'Numero ') st_numero,
                decode("OGGETTI"."SUBALTERNO",
                       null,
                       '',
                       'Sub. ') st_subalterno,
                decode("OGGETTI"."ZONA", null, '', 'Zona ') st_zona,
                decode("OGGETTI"."PROTOCOLLO_CATASTO",
                       null,
                       '',
                       'Prot.  ') st_protocollo,
                decode("OGGETTI"."ANNO_CATASTO",
                       null,
                       '',
                       'Anno ') st_anno,
                decode("OGGETTI"."CATEGORIA_CATASTO",
                       null,
                       '',
                       'Cat. ') st_categoria,
                decode("OGGETTI"."CLASSE_CATASTO",
                       null,
                       '',
                       'Cl. ') st_classe,
                decode("OGGETTI"."COD_VIA",
                       null,
                       "OGGETTI"."INDIRIZZO_LOCALITA",
                       "ARCHIVIO_VIE"."DENOM_UFF") ||
                decode("OGGETTI"."NUM_CIV",
                       null,
                       '',
                       ', ' || "OGGETTI"."NUM_CIV") ||
                decode("OGGETTI"."SUFFISSO",
                       null,
                       '',
                       '/' || "OGGETTI"."SUFFISSO") indirizzo_ogg,
                rpad(nvl(ltrim(translate(to_char(ogpr_acc.consistenza,
                                                 '999,990.00'),
                                         '.,',
                                         ',.')),
                         ' '),
                     10) superficie,
                rpad(ltrim(stampa_common.f_formatta_numero(nvl(ogco_acc.perc_possesso,
                                                               100),
                                                           'P','S')),
                     10) perc_possesso,
                oggetti.oggetto,
                ogpr_acc.oggetto_pratica,
                decode(cate.flag_domestica,
                       null,
                       '',
                       chr(10) ||
                       rpad(rpad('ABITAZ. PRINC.', 16) || ':',
                            24) || decode(ogco_acc.flag_ab_principale,
                                          'S',
                                          'SI',
                                          'NO')) ab_principale,
                max(decode(f_get_dettagli_acc_tarsu_ogim(prtr_acc.pratica,
                                                         ogim_acc.oggetto_imposta),
                           null,
                           '',
--                                 chr(10) ||
                           replace(replace(replace(f_get_dettagli_acc_tarsu_ogim(prtr_acc.pratica,
                                                                                 ogim_acc.oggetto_imposta),
                                                   '                        ',
                                                   ''),
                                           'DETTAGLI        :       ',
                                           ''),
                                   '[a_capo',
                                   CHR(10)))) n_familiari,
                decode(ogpr_acc.tipo_occupazione,
                       'P',
                       'Permanente',
                       'Temporanea') tipo_occupazione,
                decode(cata.maggiorazione_tares,
                       null,
                       '',
                       rpad(ltrim(stampa_common.f_formatta_numero(sum(nvl(ogim_acc.maggiorazione_tares,
                                                                          0)),
                                                                  'I','S')),
                            30)) magg_tares,
                decode(cata.maggiorazione_tares,
                       null,
                       '',
                       'MAGG. TARES     :       ') prompt_magg_tares,
                f_round(sum(nvl(ogim_acc.maggiorazione_tares,
                                0)),
                        1) magg_tares_acc_no_visibile,
                decode(cate.flag_domestica, null, 'NON ', '') ||
                'DOMESTICA' tipo_utenza,
                ogco_acc.data_decorrenza,
                rpad(decode(sum(nvl(ogim_acc.imposta, 0) +
                                (nvl(ogim_acc.maggiorazione_tares, 0) * cope.presenti))
                            ,0
                            ,'                    '
                            ,ltrim(stampa_common.f_formatta_numero(round(nvl(decode(decode(cotr.flag_ruolo,
                                                                                          null,
                                                                                          'N',
                                                                                          nvl(cata.flag_lordo,
                                                                                              'N')),
                                                                                   'S',
                                                                                   sum(nvl(ogim_acc.addizionale_eca,0) +
                                                                                       nvl(ogim_acc.maggiorazione_eca,0) +
                                                                                       nvl(ogim_acc.addizionale_pro,0) +
                                                                                       nvl(ogim_acc.iva,0)
                                                                                       ),
                                                                                   0) +
                                                                            sum(nvl(ogim_acc.imposta,0) +
                                                                                (nvl(ogim_acc.maggiorazione_tares, 0) * cope.presenti)
                                                                               ),
                                                                            0),
                                                                        0),
                                                                  'I','S'))),
                     20) imposta_dovuta_arr,
                decode(f_descrizione_timp(a_modello,'VIS_TOT_ARR'),
                       'SI',
                       'ARR.',
                       '') st_imp_dovuta_arr,
                decode(f_get_tipo_emissione_ruolo(substr(ogim_acc.note,
                                                         1,
                                                         10)),
                       'A',
                       '(Acconto)',
                       'S',
                       '(Saldo)',
                       '') descr_tipo_emissione,
                decode(f_get_tipo_emissione_ruolo(substr(ogim_acc.note,
                                                         1,
                                                         10)),
                       'A',
                       'Acconto',
                       'S',
                       'Saldo',
                       'T',
                       'Totale',
                       '') descr_tipo_emissione_sol,
                f_get_tipo_emissione_ruolo(substr(ogim_acc.note,
                                                  1,
                                                  10)) tipo_emissione,
                f_descrizione_timp(a_modello, 'TOT_IMP_COMP') totale_imposta_complessiva,
                decode(cata.maggiorazione_tares,
                       null,
                       '',
                       decode(sign(length('TOTALE MAGGIORAZIONE TARES') -
                                   nvl(length(f_descrizione_timp(a_modello,'TOT_IMP_COMP')),
                                       0)),
                              1,
                              'TOTALE MAGGIORAZIONE TARES',
                              rpad('TOTALE MAGGIORAZIONE TARES',
                                   length(nvl(f_descrizione_timp(a_modello,'TOT_IMP_COMP'),
                                              0))))) totale_magg_tares
              , to_char(least(least(nvl(ogco_acc.data_cessazione,to_date('3112'||a_anno,'ddMMYYYY')),
                                                   nvl(ogco_acc.fine_occupazione,to_date('3112'||a_anno,'ddMMYYYY'))),
                                                                                        to_date('3112'||a_anno,'ddMMYYYY')) -
                                       greatest(greatest(nvl(ogco_acc.data_decorrenza,to_date('0101'||a_anno,'ddMMYYYY')),
                                                         nvl(ogco_acc.inizio_occupazione,to_date('0101'||a_anno,'ddMMYYYY'))),
                                                                                                to_date('0101'||a_anno,'ddMMYYYY')) + 1
                ) ogco_gg_occup
              , to_char(least(nvl(ogco_acc.data_cessazione,to_date('3112'||a_anno,'ddMMYYYY')),to_date('3112'||a_anno,'ddMMYYYY')) -
                                       greatest(nvl(ogco_acc.data_decorrenza,to_date('0101'||a_anno,'ddMMYYYY')),to_date('0101'||a_anno,'ddMMYYYY')) + 1
                ) ogco_gg_possesso
              , to_char(dtrl.giorni_ruolo) as gg_ruolo
              --
              , sum(nvl(ogim_acc.maggiorazione_tares, 0) * cope.presenti) as imposta_dovuta_cope_num
              , rpad(decode(sum(nvl(ogim_acc.maggiorazione_tares, 0) * cope.presenti)
                            ,0
                            ,'                    '
                            ,ltrim(stampa_common.f_formatta_numero(sum(nvl(ogim_acc.maggiorazione_tares, 0) * cope.presenti),
                                                                  'I','S'))),
                     30) as imposta_dovuta_cope
          from "ARCHIVIO_VIE",
               "DATI_GENERALI",
               "OGGETTI",
               "CATEGORIE"            cate,
               "TARIFFE"              tari,
               "OGGETTI_IMPOSTA"      ogim_acc,
               "OGGETTI_CONTRIBUENTE" ogco_acc,
               "OGGETTI_PRATICA"      ogpr_acc,
               "PRATICHE_TRIBUTO"     prtr_acc,
               "CODICI_TRIBUTO"       cotr,
               "CARICHI_TARSU"        cata,
               "CONTRIBUENTI"         cont,
               "TARIFFE_DOMESTICHE"   tado,
               "TARIFFE_NON_DOMESTICHE" tand,
               (select distinct
                       ruco.giorni_ruolo,
                       ogim.oggetto_pratica
                  from pratiche_tributo prtr,
                       oggetti_pratica ogpr,
                       oggetti_imposta ogim,
                       ruoli_contribuente ruco
                 where prtr.pratica = a_prat
                   and ogpr.pratica = prtr.pratica
                   and ogim.oggetto_pratica = ogpr.oggetto_pratica_rif
                   and ogim.oggetto_imposta = ruco.oggetto_imposta
                   and ogim.anno = prtr.anno
                   and ogim.ruolo = f_get_ultimo_ruolo(ogim.COD_FISCALE,ogim.ANNO,ogim.tipo_tributo,'T','','',0)
               ) dtrl,
               (
                select decode(count(cope.componente),0,0,1) as presenti
                  from componenti_perequative cope,
                       pratiche_tributo prtr
                 where cope.anno = prtr.anno
                   and prtr.pratica = a_prat
               ) cope
          where ("OGGETTI"."COD_VIA" = "ARCHIVIO_VIE"."COD_VIA"(+))
            and ("OGGETTI"."OGGETTO" = ogpr_acc."OGGETTO")
            and (cate."TRIBUTO" = tari."TRIBUTO")
            and (cate."CATEGORIA" = tari."CATEGORIA")
            and (tari."ANNO" = ogco_acc.anno)
            and (tari."TRIBUTO" = ogpr_acc."TRIBUTO")
            and (tari."CATEGORIA" = ogpr_acc."CATEGORIA")
            and (tari."TIPO_TARIFFA" = ogpr_acc."TIPO_TARIFFA")
            and (ogim_acc."ANNO"(+) = ogco_acc.anno)
            and (ogim_acc."COD_FISCALE"(+) = ogco_acc."COD_FISCALE")
            and (ogim_acc."OGGETTO_PRATICA"(+) =
                 ogco_acc."OGGETTO_PRATICA")
            and (cotr.tributo = ogpr_acc.tributo)
            and (cata.anno = a_anno)
            and (ogco_acc."COD_FISCALE" = a_cf)
            and (ogco_acc."OGGETTO_PRATICA" =
                 ogpr_acc."OGGETTO_PRATICA")
            and (ogpr_acc."PRATICA" = prtr_acc."PRATICA")
            and (prtr_acc."PRATICA" = a_prat)
            and cont.cod_fiscale = a_cf
            and tado.anno (+) = a_anno
            and tado.numero_familiari (+) = f_ultimo_faso(cont.ni, a_anno)
            and tand.categoria (+) = ogpr_acc.categoria
            and tand.tributo (+) = ogpr_acc.tributo
            and tand.anno (+) = a_anno
            and ogpr_acc.oggetto_pratica_rif = dtrl.oggetto_pratica (+)
          group by prtr_acc.pratica,
                   oggetti.oggetto,
                   ogpr_acc.oggetto_pratica,
                   ogco_acc.data_decorrenza,
                   ogco_acc.data_cessazione,
                   rpad(nvl(cate."DESCRIZIONE", ' '), 30),
                   ogim_acc."ANNO",
                   prtr_acc.numero,
                   prtr_acc.anno,
                   nvl(to_char(ogco_acc.inizio_occupazione,
                               'dd/mm/yyyy'),
                       ' '),
                   nvl(to_char(ogco_acc.data_decorrenza, 'dd/mm/yyyy'),
                       ' '),
                   nvl(to_char(ogco_acc.fine_occupazione, 'dd/mm/yyyy'),
                       ' '),
                   'mq.',
                   decode(ogco_acc.inizio_occupazione,
                          null,
                          ' ',
                          'INIZIO OCCUPAZ. :'),
                   decode(ogco_acc.data_decorrenza,
                          null,
                          ' ',
                          'DATA DECORRENZA :'),
                   decode(ogco_acc.fine_occupazione,
                          null,
                          ' ',
                          'FINE OCCUPAZIONE:'),
                   prtr_acc.data,
                   decode(ogpr_acc.oggetto_pratica_rif,
                          null,
                          'omessa presentazione della denuncia',
                          'rettifica della denuncia presentata'),
                   decode(ogpr_acc.oggetto_pratica_rif,
                          null,
                          '          ',
                          'DICHIARATI'),
                   cotr.flag_ruolo,
                   cata.flag_lordo,
                   rpad(nvl(ltrim(stampa_common.f_formatta_numero(tari."TARIFFA",
                                                                  'T','S')),
                            ' '),
                        36),
                   rpad(substr(nvl(tari."DESCRIZIONE", ' '), 1, 36), 36),
                   "OGGETTI"."PARTITA",
                   "OGGETTI"."SEZIONE",
                   "OGGETTI"."FOGLIO",
                   "OGGETTI"."NUMERO",
                   "OGGETTI"."SUBALTERNO",
                   "OGGETTI"."ZONA",
                   "OGGETTI"."PROTOCOLLO_CATASTO",
                   "OGGETTI"."ANNO_CATASTO",
                   "OGGETTI"."CATEGORIA_CATASTO",
                   "OGGETTI"."CLASSE_CATASTO",
                   decode("OGGETTI"."COD_VIA",
                          null,
                          "OGGETTI"."INDIRIZZO_LOCALITA",
                          "ARCHIVIO_VIE"."DENOM_UFF") ||
                   decode("OGGETTI"."NUM_CIV",
                          null,
                          '',
                          ', ' || "OGGETTI"."NUM_CIV") ||
                   decode("OGGETTI"."SUFFISSO",
                          null,
                          '',
                          '/' || "OGGETTI"."SUFFISSO"),
                   rpad(nvl(ltrim(translate(to_char(ogpr_acc.consistenza,
                                                    '999,990.00'),
                                            '.,',
                                            ',.')),
                            ' '),
                        10),
                   rpad(ltrim(stampa_common.f_formatta_numero(nvl(ogco_acc.perc_possesso,
                                                                  100),
                                                              'P','S')),
                        10),
                   ogco_acc.flag_ab_principale,
                   ogpr_acc.tipo_occupazione,
                   cate.flag_domestica,
                   cata.maggiorazione_tares,
                   f_get_tipo_emissione_ruolo(substr(ogim_acc.note,1,10)),
                   tari.riduzione_quota_fissa,
                   tari.riduzione_quota_variabile,
                   tado.tariffa_quota_fissa,
                   tado.tariffa_quota_variabile,
                   tado.tariffa_quota_fissa_no_ap,
                   tado.tariffa_quota_variabile_no_ap,
                   tand.tariffa_quota_fissa,
                   tand.tariffa_quota_variabile,
                   to_char(least(least(nvl(ogco_acc.data_cessazione,to_date('3112'||a_anno,'ddMMYYYY')),
                                                   nvl(ogco_acc.fine_occupazione,to_date('3112'||a_anno,'ddMMYYYY'))),
                                                                                       to_date('3112'||a_anno,'ddMMYYYY')) -
                                       greatest(greatest(nvl(ogco_acc.data_decorrenza,to_date('0101'||a_anno,'ddMMYYYY')),
                                                         nvl(ogco_acc.inizio_occupazione,to_date('0101'||a_anno,'ddMMYYYY'))),
                                                                                       to_date('0101'||a_anno,'ddMMYYYY'))
                                        + 1),
                   to_char(least(nvl(ogco_acc.data_cessazione,to_date('3112'||a_anno,'ddMMYYYY')),to_date('3112'||a_anno,'ddMMYYYY')) -
                                       greatest(nvl(ogco_acc.data_decorrenza,to_date('0101'||a_anno,'ddMMYYYY')),to_date('0101'||a_anno,'ddMMYYYY')) + 1),
                   dtrl.giorni_ruolo,
                   ogpr_acc.oggetto_pratica_rif,
                   cope.presenti
          order by prtr_acc.pratica,
                   oggetti.oggetto,
                   f_get_tipo_emissione_ruolo(substr(ogim_acc.note,1,10)),
                   ogpr_acc.oggetto_pratica,
                   ogco_acc.data_decorrenza
         ) ogg;
  --
  return rc;
  --
end;
--------------------------------------------------------------
function versamenti
( a_cf                                varchar2
, a_prat                              number
, a_modello                           number
, a_tot_imposta                       varchar2
, a_tot_magg_tares                    varchar2
) return sys_refcursor
is
  rc sys_refcursor;
begin
  open rc for
    select nvl(to_char(versamenti.rata, 99), '  ') rata,
           stampa_common.f_formatta_numero(versamenti.importo_versato -
                                           nvl(versamenti.maggiorazione_tares, 0),
                                           'I','S') s_importo_versato,
           nvl(to_char(versamenti.data_pagamento, 'dd/mm/yyyy'),
               '          ') data_versamento,
           nvl(versamenti.tipo_versamento, ' ') tipo_vers,
           nvl(to_char(decode(versamenti.rata,
                              0,
                              nvl(ruol.scadenza_rata_unica, ruol.scadenza_prima_rata),
                              1,
                              ruol.scadenza_prima_rata,
                              2,
                              ruol.scadenza_rata_2,
                              3,
                              ruol.scadenza_rata_3,
                              4,
                              ruol.scadenza_rata_4),
                       'dd/mm/yyyy'),
               '          ') data_scadenza,
           rtrim(f_descrizione_timp(a_modello, 'DETT_VERS')) dettaglio_versamenti,
           f_descrizione_timp(a_modello, 'DIFF_PRT') differenzadimposta,
           f_descrizione_timp(a_modello, 'TOT_IMP_PRT') totale_imposta,
           f_descrizione_timp(a_modello, 'TOT_VERS_RIEP_PRT') totale_versamento,
           rtrim(f_descrizione_timp(a_modello, 'RIEP_DETT_PRT')) riepilogo,
           decode(cata.maggiorazione_tares,
                  null,
                  null,
                  decode(sign(length('TOTALE MAGGIORAZIONE TARES') -
                              nvl(length(f_descrizione_timp(a_modello,'TOT_IMP_PRT')),
                                  0)),
                         1,
                         'TOTALE MAGGIORAZIONE TARES',
                         rpad('TOTALE MAGGIORAZIONE TARES',
                              length(nvl(f_descrizione_timp(a_modello,'TOT_IMP_PRT'),
                                         0))))) totale_magg_tares,
           decode(cata.maggiorazione_tares,
                  null,
                  lpad(' ', 26),
                  lpad(nvl(stampa_common.f_formatta_numero(versamenti.maggiorazione_tares,
                                                           'I','S'),
                           ' '),
                       26)) s_maggiorazione_tares,
           stampa_common.f_formatta_numero(
                       versamenti.importo_versato -
                       nvl(versamenti.maggiorazione_tares, 0),
                       'I','S') importo_versato,
           stampa_common.f_formatta_numero(
                   versamenti.maggiorazione_tares,
                   'I','S') maggiorazione_tares,
           decode(count(versamenti.maggiorazione_tares) over(),
                  0,
                  null,
                  f_descrizione_timp(a_modello, 'TOT_DETT_VERS_PRT')) totale_dettaglio_versamenti,
           decode(cata.maggiorazione_tares,
                  null,
                  null,
                  rpad('TOTALE MAGG. TARES VERSATA',
                       length(f_descrizione_timp(a_modello,'TOT_DETT_VERS_PRT')))) totale_dettaglio_mtares,
           decode(cata.maggiorazione_tares,
                  null,
                  null,
                  rpad('TOTALE MAGG. TARES VERSATA',
                       length(f_descrizione_timp(a_modello,'TOT_VERS_RIEP_PRT')))) totale_vers_mtares,
           decode(cata.maggiorazione_tares,
                  null,
                  null,
                  rpad('TOTALE DIFF. MAGG. TARES ',
                       length(f_descrizione_timp(a_modello,'TOT_VERS_RIEP_PRT')))) totale_diff_mtares,
           decode(cata.maggiorazione_tares,
                  null,
                  '           ',
                  'MAGG. TARES') int_magg_tares,
           stampa_common.f_formatta_numero(
                   sum(versamenti.importo_versato) over(),
                   'I','S') tot_dett_vers,
           stampa_common.f_formatta_numero(
                   sum(versamenti.maggiorazione_tares) over(),
                   'I','S') tot_dett_mtares,
           nvl(a_tot_imposta, '0') tot_imposta,
           decode(cata.maggiorazione_tares,
                  NULL,
                  NULL,
                  nvl(a_tot_magg_tares, '0')) tot_magg_tares,
           stampa_common.f_formatta_numero(
                   SUM(versamenti.importo_versato) over(),
                   'I','S') tot_versato,
           stampa_common.f_formatta_numero(
                   decode(cata.maggiorazione_tares,
                          NULL,
                          NULL,
                          SUM(versamenti.maggiorazione_tares) over()),
                   'I','S') tot_vers_magg_tares
    from versamenti,
         pratiche_tributo prtr,
         ruoli            ruol,
         carichi_tarsu    cata
    where versamenti.pratica is null
      and versamenti.oggetto_imposta is null
      and versamenti.cod_fiscale = a_cf
      and versamenti.anno = prtr.anno
      and cata.anno = prtr.anno
      and prtr.pratica = a_prat
      and versamenti.tipo_tributo = 'TARSU'
      and versamenti.ruolo = ruol.ruolo(+)
      -- (VD - 28/01/2022): eliminato test su sanzioni per omessa/infedele denuncia
      --                    Questa funzione è relativa alla stampa degli avvisi di
      --                    accertamento automatico TARSU, dove non è previsto che
      --                    ci siano accertamenti per omessa/infedele denuncia.
      --                    Occorre comunque trovare il modo di identificare le
      --                    sanzioni relative alle infrazioni su denuncia.
        /*and not exists
            (select sapr.cod_sanzione
               from sanzioni_pratica sapr
              where sapr.cod_sanzione in
                    (2, 3, 4, 5, 6, 102, 103, 104, 105, 106)
                and sapr.pratica = a_prat) */
    order by 1, 3;
  return rc;
end;
------------------------------------------------------------------
function addiz_int
( a_prat number
, a_modello number)
return sys_refcursor
is
  rc sys_refcursor;
begin
  open rc for
    select a_prat pratica,
           a_modello modello,
           decode(sum(f_cata(cata.anno,
                             1,
                             decode(sapr.importo,
                                    null,
                                    sanzioni.sanzione,
                                    sapr.importo),
                             'A')),
                  0,
                  '',
                  lpad(stampa_common.f_formatta_numero(nvl(sum(f_cata(cata.anno,
                                                                      1,
                                                                      decode(sapr.importo,
                                                                             null,
                                                                             sanzioni.sanzione,
                                                                             sapr.importo),
                                                                      'A')),
                                                           0),
                                                       'I','S'),
                       15)
               ) addizionale_eca,
           decode(sum(f_cata(cata.anno,
                             1,
                             decode(sapr.importo,
                                    null,
                                    sanzioni.sanzione,
                                    sapr.importo),
                             'A')),
                  0,
                  ' ',
                  'ADDIZIONALE ECA          ') s_addizionale_eca,
           decode(sum(f_cata(cata.anno,
                             1,
                             decode(sapr.importo,
                                    null,
                                    sanzioni.sanzione,
                                    sapr.importo),
                             'M')),
                  0,
                  '',
                  lpad(stampa_common.f_formatta_numero(nvl(sum(f_cata(cata.anno,
                                                                      1,
                                                                      decode(sapr.importo,
                                                                             null,
                                                                             sanzioni.sanzione,
                                                                             sapr.importo),
                                                                      'M')),
                                                           0),
                                                       'I','S'),
                       15)
               ) maggiorazione_eca,
           decode(sum(f_cata(cata.anno,
                             1,
                             decode(sapr.importo,
                                    null,
                                    sanzioni.sanzione,
                                    sapr.importo),
                             'M')),
                  0,
                  ' ',
                  'MAGGIORAZIONE ECA        ') s_maggiorazione_eca,
           decode(sum(f_cata(cata.anno,
                             1,
                             decode(sapr.importo,
                                    null,
                                    sanzioni.sanzione,
                                    sapr.importo),
                             'P') - f_cata(cata.anno,
                                           1,
                                           ((decode(sapr.importo,
                                                    null,
                                                    sanzioni.sanzione,
                                                    sapr.importo) *
                                             cata.commissione_com) / 100),
                                           'P')),
                  0,
                  '',
                  lpad(stampa_common.f_formatta_numero(nvl(sum(f_cata(cata.anno,
                                                                      1,
                                                                      decode(sapr.importo,
                                                                             null,
                                                                             sanzioni.sanzione,
                                                                             sapr.importo),
                                                                      'P') -
                                                               f_cata(cata.anno,
                                                                      1,
                                                                      ((decode(sapr.importo,
                                                                               null,
                                                                               sanzioni.sanzione,
                                                                               sapr.importo) *
                                                                        cata.commissione_com) / 100),
                                                                      'P')),
                                                           0),
                                                       'I','S'),
                       15)) addizionale_provinciale,
           decode(sum(f_cata(cata.anno,
                             1,
                             decode(sapr.importo,
                                    null,
                                    sanzioni.sanzione,
                                    sapr.importo),
                             'P') - f_cata(cata.anno,
                                           1,
                                           ((decode(sapr.importo,
                                                    null,
                                                    sanzioni.sanzione,
                                                    sapr.importo) *
                                             cata.commissione_com) / 100),
                                           'P')),
                  0,
                  ' ',
                  'ADDIZIONALE PROVINCIALE  ') s_addizionale_provinciale,
           decode(sum(f_cata(cata.anno,
                             1,
                             ((decode(sapr.importo,
                                      null,
                                      sanzioni.sanzione,
                                      sapr.importo) *
                               cata.commissione_com) / 100),
                             'P')),
                  0,
                  '',
                  lpad(stampa_common.f_formatta_numero(nvl(sum(f_cata(cata.anno,
                                                                      1,
                                                                      ((decode(sapr.importo,
                                                                               null,
                                                                               sanzioni.sanzione,
                                                                               sapr.importo) *
                                                                        cata.commissione_com) / 100),
                                                                      'P')),
                                                           0),
                                                       'I','S'),
                       15)
               ) comm_comunale,
           decode(sum(f_cata(cata.anno,
                             1,
                             ((decode(sapr.importo,
                                      null,
                                      sanzioni.sanzione,
                                      sapr.importo) *
                               cata.commissione_com) / 100),
                             'P')),
                  0,
                  ' ',
                  'COMMISSIONE COMUNALE     ') s_comm_comunale,
           decode(sum(f_cata(cata.anno,
                             1,
                             decode(sapr.importo,
                                    null,
                                    sanzioni.sanzione,
                                    sapr.importo),
                             'I')),
                  0,
                  '',
                  lpad(stampa_common.f_formatta_numero(nvl(sum(f_cata(cata.anno,
                                                                      1,
                                                                      decode(sapr.importo,
                                                                             null,
                                                                             sanzioni.sanzione,
                                                                             sapr.importo),
                                                                      'I')),
                                                           0),
                                                       'I','S'),
                       15)
               ) iva,
           decode(sum(f_cata(cata.anno,
                             1,
                             decode(sapr.importo,
                                    null,
                                    sanzioni.sanzione,
                                    sapr.importo),
                             'I')),
                  0,
                  ' ',
                  'IVA                      ') s_iva,
           lpad(stampa_common.f_formatta_numero(nvl(sum(f_cata(cata.anno,
                                                               1,
                                                               decode(sapr.importo,
                                                                      null,
                                                                      sanzioni.sanzione,
                                                                      sapr.importo),
                                                               'T')),
                                                    0),
                                                'I','S'),
                15) tot_add,
           f_descrizione_timp(a_modello, 'ADD MAGG TOT') totale,
           rtrim(f_descrizione_timp(a_modello, 'ADD_MAGG')) addizionali_maggiorazioni
    from carichi_tarsu    cata,
         sanzioni_pratica sapr,
         sanzioni,
         pratiche_tributo prtr_acc
    where cata.anno = prtr_acc.anno
      and sanzioni.tipo_tributo = 'TARSU'
      and (sanzioni.cod_sanzione in (1, 100, 101) or
           sanzioni.tipo_causale || nvl(sanzioni.flag_magg_tares, 'N') = 'EN')
      and sanzioni.cod_sanzione not in (888, 889)
      and sanzioni.cod_sanzione = sapr.cod_sanzione
      and sanzioni.sequenza = sapr.sequenza_sanz
      and sapr.pratica = prtr_acc.pratica
      and prtr_acc.pratica = a_prat;
  return rc;
end;
------------------------------------------------------------------
function acc
( a_prat        number default -1
, a_tipo_record varchar2 default ''
, a_modello     number default -1
)
return sys_refcursor
is
  rc sys_refcursor;
begin
  open rc FOR
    SELECT sapr.cod_sanzione,
           trunc(sapr.cod_sanzione / 100) sanz_ord1,
           sanz.tipo_causale || nvl(sanz.flag_magg_tares, 'N') sanz_ord,
           1 ord,
           stampa_common.f_formatta_numero(sapr.importo + importi_tefa.importo, 'I', 'S') importo,
           decode(sapr.percentuale,
                  null,
                  '        ',
                  replace(to_char(sapr.percentuale, '9990.00'), '.', ',')) || '  ' ||
           decode(sapr.riduzione,
                  null,
                  '        ',
                  replace(to_char(sapr.riduzione, '9990.00'), '.', ',')) || '  ' ||
           decode(sapr.semestri, null, '   ', to_char(sapr.semestri, '99')) || '  ' ||
           stampa_common.f_formatta_numero(decode(a_tipo_record,
                                                  'X',
                                                  nvl(sapr.importo, 0),
                                                  sapr.importo),
                                           'I',
                                           'S') perc_ed_importo,
           rpad(decode(f_descrizione_timp(a_modello, 'VIS_COD_TRIB'),
                       'SI',
                       nvl(sanz.cod_tributo_f24,
                           decode(sanz.flag_magg_tares, 'S', '3955', '3944')) ||
                       ' - ',
                       '') || substr(sanz.descrizione, 1, 49),
                49) descrizione,
           rtrim(decode(a_tipo_record,
                        'I',
                        f_descrizione_timp(a_modello, 'ACC_IMP'),
                        f_descrizione_timp(a_modello, 'ACC_MAGG'))) accertamento_imposta,
           SUM(sapr.importo + importi_tefa.importo) over() importo_tot,
           stampa_common.f_formatta_numero(SUM(sapr.importo + importi_tefa.importo) over(), 'I', 'S') st_importo_tot,
           stampa_common.f_formatta_numero(sapr.importo, 'I', 'S') importo_netto,
           stampa_common.f_formatta_numero(SUM(sapr.importo) over(), 'I', 'S') importo_netto_tot,
           rpad(decode(f_descrizione_timp(a_modello, 'VIS_COD_TRIB'),
                       'SI',
                       'TEFA - ',
                       '') || substr(sanz.descrizione, 1, 49),
                49) descrizione_tefa,
           stampa_common.f_formatta_numero(importi_tefa.importo, 'I', 'S') importo_tefa,
           stampa_common.f_formatta_numero(SUM(importi_tefa.importo) over(), 'I', 'S') importo_tefa_tot
      from sanzioni_pratica sapr,
           sanzioni sanz,
           carichi_tarsu cata,
           pratiche_tributo prtr,
           (select nvl(max(nvl(cotr.flag_ruolo, 'N')), 'N') flag_ruolo
              from codici_tributo cotr, oggetti_pratica ogpr
             where cotr.tributo = ogpr.tributo
               and ogpr.pratica = a_prat) ogpr,
           (-- Quota TEFA
           select sapr.cod_sanzione,
                  sapr.sequenza,
                  sapr.sequenza_sanz,
                   trunc(sapr.cod_sanzione / 100) sanz_ord1,
                   sanz.tipo_causale || nvl(sanz.flag_magg_tares, 'N') sanz_ord,
                   2 ord,
                   decode(sapr.cod_sanzione,
                          197,
                          0,
                          decode(ogpr.flag_ruolo,
                                 'S',
                                 decode(decode(sanz.tipo_causale ||
                                               nvl(sanz.flag_magg_tares, 'N'),
                                               'EN',
                                               1,
                                               0),
                                        1,
                                        round(sapr.importo *
                                              nvl(cata.addizionale_eca, 0) / 100,
                                              2) +
                                        round(sapr.importo *
                                              nvl(cata.maggiorazione_eca, 0) / 100,
                                              2) +
                                        round(sapr.importo *
                                              nvl(cata.addizionale_pro, 0) / 100,
                                              2) +
                                        round(sapr.importo * nvl(cata.aliquota, 0) / 100,
                                              2),
                                        0),
                                 0)) importo,
                   sapr.percentuale percentuale,
                   sapr.riduzione riduzione,
                   sapr.semestri semestri,
                   'TEFA' cod_tributo_f24,
                   sanz.descrizione descr_tributo_f24
              from sanzioni_pratica sapr,
                   sanzioni sanz,
                   carichi_tarsu cata,
                   pratiche_tributo prtr,
                   (select nvl(max(nvl(cotr.flag_ruolo, 'N')), 'N') flag_ruolo
                      from codici_tributo cotr, oggetti_pratica ogpr
                     where cotr.tributo = ogpr.tributo
                       and ogpr.pratica = a_prat) ogpr
             where (sapr.cod_sanzione = sanz.cod_sanzione)
               and (sapr.sequenza_sanz = sanz.sequenza)
               and (sapr.tipo_tributo = sanz.tipo_tributo)
               and ((prtr.tipo_tributo = 'TARSU' and (sanz.tipo_causale = 'E')) or
                   (prtr.tipo_tributo != 'TARSU' and (sanz.flag_imposta = 'S')))
               and (sanz.cod_sanzione not in (888, 889))
               and (sapr.pratica = a_prat)
               and (a_tipo_record = 'X' or
                   (a_tipo_record = 'I' and
                   nvl(sanz.flag_magg_tares, 'N') = 'N') or
                   (a_tipo_record = 'M' and
                   nvl(sanz.flag_magg_tares, 'N') != 'N'))
               and (prtr.pratica = a_prat)
               and (cata.anno(+) = prtr.anno)) importi_tefa
     where (sapr.cod_sanzione = sanz.cod_sanzione)
       and (sapr.sequenza_sanz = sanz.sequenza)
       and (sapr.tipo_tributo = sanz.tipo_tributo)
       and ((prtr.tipo_tributo = 'TARSU' and (sanz.tipo_causale = 'E')) or
           (prtr.tipo_tributo != 'TARSU' and (sanz.flag_imposta = 'S')))
       and (sanz.cod_sanzione not in (888, 889))
       and (sapr.pratica = a_prat)
       and (a_tipo_record = 'X' or
           (a_tipo_record = 'I' and nvl(sanz.flag_magg_tares, 'N') = 'N') or
           (a_tipo_record = 'M' and nvl(sanz.flag_magg_tares, 'N') != 'N'))
       and (prtr.pratica = a_prat)
       and (cata.anno(+) = prtr.anno)
       and importi_tefa.cod_sanzione = sapr.cod_sanzione
       and importi_tefa.sequenza = sapr.sequenza
       and importi_tefa.sequenza_sanz = sapr.sequenza_sanz
     order by 3, 1, 4;
  return rc;
end;
------------------------------------------------------------------
function acc_imposta
( a_prat    number default -1
, a_modello number default -1
)
return sys_refcursor
is
  w_tipo_record    varchar2(1);
begin
  if f_contolla_cope(a_prat) > 0 then
    w_tipo_record := 'X';   -- Nel caso di annualità con Componenti Perequative prende Imposta normale + TARES
  else
    w_tipo_record := 'I';
  end if;
  return acc(a_prat, w_tipo_record, a_modello);
end;
------------------------------------------------------------------
function acc_magg
( a_prat number default -1
, a_modello number default -1
)
return sys_refcursor
is
begin
  return acc(a_prat, 'M', a_modello);
end;
------------------------------------------------------------------
function sanz
( a_prat        number default -1
, a_tipo_record varchar2 default ''
, a_modello     number default -1)
return sys_refcursor
is
  rc sys_refcursor;
begin
  open rc FOR
    SELECT sanz_int.*,
           SUM(importo) over() importo_tot
                 --stampa_common.f_formatta_numero(sanz_int.totale,'I','S') importo_tot
    FROM (select sanzioni_pratica.cod_sanzione,
                 nvl(sanzioni_pratica.importo, 0) importo,
                 decode(sanzioni_pratica.percentuale,
                        null,
                        rpad(' ', 8),
                        stampa_common.f_formatta_numero(sanzioni_pratica.percentuale,
                                                        'P','S')) || '   ' ||
                 decode(sanzioni_pratica.riduzione,
                        null,
                        rpad(' ', 8),
                        translate(to_char(sanzioni_pratica.riduzione,
                                          '9990.00'),
                                  ',.',
                                  '.,')) || '   ' ||
                 decode(nvl(sanzioni_pratica.giorni,
                            sanzioni_pratica.semestri),
                        null,
                        rpad(' ', 5),
                        to_char(nvl(sanzioni_pratica.giorni,
                                    sanzioni_pratica.semestri),
                                '9999')) || '   ' ||
                 stampa_common.f_formatta_numero(sanzioni_pratica.importo,
                                                 'I','S') perc_ed_importo,
                 rpad(substr(decode(f_descrizione_timp(a_modello,'VIS_COD_TRIB'),
                                    'SI',
                                    nvl(sanzioni.cod_tributo_f24,
                                        decode(sanzioni.flag_magg_tares,
                                               'S',
                                               '3955',
                                               '3944')) || ' - ',
                                    '') || sanzioni.descrizione,
                             1,
                             49),
                      49) descrizione,
                 rtrim(f_descrizione_timp(a_modello, 'IRR_SANZ_INT')) irrogazioni_sanz_int,
                 to_char(nvl(sanzioni_pratica.giorni,sanzioni_pratica.semestri),'9999') st_giorni,
                 trim(to_char(sanzioni_pratica.riduzione,'990D00','NLS_NUMERIC_CHARACTERS = '',.''')) st_riduzione,
                 trim(to_char(sanzioni_pratica.percentuale,'990D00','NLS_NUMERIC_CHARACTERS = '',.''')) st_percentuale,
                 stampa_common.f_formatta_numero(sanzioni_pratica.importo,'I','S') st_importo_sanzione,
                 sanzioni_pratica.note
                 --SUM(importo) over() totale
          from sanzioni_pratica, sanzioni, dati_generali dage
          where sanzioni_pratica.cod_sanzione = sanzioni.cod_sanzione
            and sanzioni_pratica.sequenza_sanz = sanzioni.sequenza
            and sanzioni_pratica.tipo_tributo = sanzioni.tipo_tributo
            and sanzioni.cod_sanzione not in (1, 100, 101)
            and nvl(sanzioni.tipo_causale, '*') != 'E'
            and sanzioni_pratica.cod_sanzione not in (888, 889)
            and sanzioni_pratica.pratica = a_prat
            and (dage.pro_cliente = 1 and dage.com_cliente = 219 and
                sanzioni_pratica.cod_sanzione not in (15, 115, 198) or
                (dage.pro_cliente <> 1 or dage.com_cliente <> 219))
            and (
                 (a_tipo_record = 'X') or
                ((a_tipo_record = 'I' and nvl(sanzioni.flag_magg_tares, 'N') = 'N')) or
                ((a_tipo_record = 'M' and nvl(sanzioni.flag_magg_tares, 'N') != 'N'))
                )
          order by 1) sanz_int;
  return rc;
end;
------------------------------------------------------------------
function sanz_int
( a_prat number default -1
, a_modello number default -1
)
return sys_refcursor
is
  w_tipo_record    varchar2(1);
begin
  if f_contolla_cope(a_prat) > 0 then
    w_tipo_record := 'X';   -- Nel caso di annualità con Componenti Perequative prende Imposta normale + TARES
  else
    w_tipo_record := 'I';
  end if;
  return sanz(a_prat, w_tipo_record, a_modello);
end;
------------------------------------------------------------------
function sanz_magg
( a_prat number default -1
, a_modello number default -1
)
return sys_refcursor
is
begin
  return sanz(a_prat, 'M', a_modello);
end;
------------------------------------------------------------------
function riep_vers
( a_prat number
, a_modello number
)
return sys_refcursor
is
  rc sys_refcursor;
begin
  open rc for
         select
             vers.*,
             stampa_common.f_formatta_numero(sum(vers.importo_non_st) over(),'I') st_importo_vers_tot,
             stampa_common.f_formatta_numero(sum(vers.importo_ridotto_non_st) over(),'I') st_importo_vers_rid
         from
             (
  select cod_tributo,
         descr_tributo,
         lpad(stampa_common.f_formatta_numero(sum(importo), 'I', 'S'),
              14,
              ' ') importo,
         lpad(stampa_common.f_formatta_numero(sum(importo_ridotto),
                                              'I',
                                              'S'),
              14,
              ' ') imp_ridotto,
         sum(importo) importo_non_st,
         sum(importo_ridotto) importo_ridotto_non_st,
         rtrim(f_descrizione_timp(a_modello, 'F24_INT')) f24_intestazione,
         rpad(rtrim(f_descrizione_timp(a_modello, 'F24_TOT')), 24) f24_totale
  from (select nvl(sanz.cod_tributo_f24,
                   decode(sanz.flag_magg_tares, 'S', '3955', '3944')) cod_tributo,
               cf24.descrizione descr_tributo,
               round(sum(f_importo_f24_viol(sapr.importo,
                                            sapr.riduzione,
                                            'N',
                                            prtr.tipo_tributo,
                                            prtr.anno,
                                            sanz.tipo_causale,
                                            sanz.flag_magg_tares)),
                     0) importo,
               round(sum(f_importo_f24_viol(sapr.importo,
                                            sapr.riduzione,
                                            'S',
                                            prtr.tipo_tributo,
                                            prtr.anno,
                                            sanz.tipo_causale,
                                            sanz.flag_magg_tares,
                                            (case when prtr.flag_sanz_min_rid = 'S'
                                               then sanz.sanzione_minima
                                               else null end))),
                     0) importo_ridotto,
               cf24.tipo_codice tipo_cod_tributo
        from pratiche_tributo prtr,
             sanzioni_pratica sapr,
             sanzioni         sanz,
             codici_f24       cf24
        where sapr.pratica = prtr.pratica
          and sapr.cod_sanzione = sanz.cod_sanzione
          and sapr.sequenza_sanz = sanz.sequenza
          and sapr.tipo_tributo = sanz.tipo_tributo
          and nvl(sanz.cod_tributo_f24,
                  decode(sanz.flag_magg_tares, 'S', '3955', '3944')) =
              cf24.tributo_f24(+)
          and cf24.tipo_tributo(+) = sanz.tipo_tributo
          and prtr.pratica in (a_prat)
          and prtr.anno < 2021
        group by prtr.pratica,
                 nvl(sanz.cod_tributo_f24,
                     decode(sanz.flag_magg_tares, 'S', '3955', '3944')),
                 cf24.descrizione,
                 cf24.tipo_codice
        union
        -- (VD - 27/09/2022): se accertamento relativo ad anno >= 2021, occorre suddividere
        --                    l'imposta in TARI e TEFA
        select nvl(sanz.cod_tributo_f24,
                   decode(sanz.flag_magg_tares, 'S', '3955', '3944')) cod_tributo,
               cf24.descrizione descr_tributo,
               round(sum(f_importo_f24_viol_tefa(sapr.importo,
                                                 sapr.riduzione,
                                                 'N',
                                                 prtr.tipo_tributo,
                                                 prtr.anno,
                                                 sanz.tipo_causale,
                                                 sanz.flag_magg_tares)),
                     0) importo,
               round(sum(f_importo_f24_viol_tefa(sapr.importo,
                                                 sapr.riduzione,
                                                 'S',
                                                 prtr.tipo_tributo,
                                                 prtr.anno,
                                                 sanz.tipo_causale,
                                                 sanz.flag_magg_tares,
                                                 (case when prtr.flag_sanz_min_rid = 'S'
                                                   then sanz.sanzione_minima
                                                   else null end))),
                     0) importo_ridotto,
               cf24.tipo_codice tipo_cod_tributo
        from pratiche_tributo prtr,
             sanzioni_pratica sapr,
             sanzioni         sanz,
             codici_f24       cf24
        where sapr.pratica = prtr.pratica
          and sapr.cod_sanzione = sanz.cod_sanzione
          and sapr.sequenza_sanz = sanz.sequenza
          and sapr.tipo_tributo = sanz.tipo_tributo
          and nvl(sanz.cod_tributo_f24,
                  decode(sanz.flag_magg_tares, 'S', '3955', '3944')) =
              cf24.tributo_f24(+)
          and cf24.tipo_tributo(+) = sanz.tipo_tributo
          and prtr.pratica in (a_prat)
          and prtr.anno >= 2021
        group by prtr.pratica,
                 nvl(sanz.cod_tributo_f24,
                     decode(sanz.flag_magg_tares, 'S', '3955', '3944')),
                 cf24.descrizione,
                 cf24.tipo_codice
        union
        select nvl(cf24.tributo_f24, 'TEFA') cod_tributo,
               cf24.descrizione descr_tributo,
               round(sum(case
                           when sanz.cod_tributo_f24 != '3944' or
                                nvl(sanz.tipo_causale, '*') != 'E' or
                                nvl(sanz.flag_magg_tares, '*') = 'S' then
                                  0
                                 else
                                  f_importo_f24_viol_tefa(sapr.importo,
                                                          sapr.riduzione,
                                                          'N',
                                                          'TEFA',
                                                          prtr.anno,
                                                          sanz.tipo_causale,
                                                          sanz.flag_magg_tares)
                               end),
                     0) importo,
               round(sum(case
                           when sanz.cod_tributo_f24 != '3944' or
                                nvl(sanz.tipo_causale, '*') != 'E' or
                                nvl(sanz.flag_magg_tares, '*') = 'S' then
                                  0
                                 else
                                  f_importo_f24_viol_tefa(sapr.importo,
                                                          sapr.riduzione,
                                                          'S',
                                                          'TEFA',
                                                          prtr.anno,
                                                          sanz.tipo_causale,
                                                          sanz.flag_magg_tares,
                                                          (case when prtr.flag_sanz_min_rid = 'S'
                                                           then sanz.sanzione_minima
                                                           else null end))
                               end),
                     0) importo_ridotto,
               cf24.tipo_codice tipo_cod_tributo
        from pratiche_tributo prtr,
             sanzioni_pratica sapr,
             sanzioni         sanz,
             codici_f24       cf24
        where sapr.pratica = prtr.pratica
          and sapr.cod_sanzione = sanz.cod_sanzione
          and sapr.sequenza_sanz = sanz.sequenza
          and sapr.tipo_tributo = sanz.tipo_tributo
          and 'TEFA' = cf24.tributo_f24(+)
          and cf24.tipo_tributo(+) = sanz.tipo_tributo
          and prtr.pratica in (a_prat)
          and prtr.anno >= 2021
        group by prtr.pratica,
                 cf24.tributo_f24,
                 cf24.descrizione,
                 cf24.tipo_codice)
  group by cod_tributo, descr_tributo, tipo_cod_tributo
  having nvl(sum(importo), 0) <> 0 or nvl(sum(importo_ridotto), 0) <> 0
      order by tipo_cod_tributo, importo desc, cod_tributo) vers;
  --
  return rc;
end;
-----------------------------------------------------------------------------------------
-- FUNZIONI PER STAMPA AVVISO DI ACCERTAMENTO MANUALE (TIPO_EVENTO = 'U')
-----------------------------------------------------------------------------------------
function man_contribuente
( a_pratica                           number
, a_ni_erede number default -1
)
return sys_refcursor
is
  rc sys_refcursor;
begin
  rc := stampa_common.contribuente(a_pratica, a_ni_erede);
  return rc;
end;
------------------------------------------------------------------
function man_principale
( a_cf                                varchar2
, a_prat                              number
, a_modello                           number
, a_ni_erede                          number     default -1
)
return sys_refcursor
is
  v_rc                                sys_refcursor;
  --v_acc_imposta_importo_tot           number(10, 2);
  --v_acc_magg_importo_tot              number(10, 2);
  --v_sanz_int_importo_tot              number(10, 2);
  --v_sanz_magg_importo_tot             number(10, 2);
  v_acc_imposta_importo_tot           varchar2(20);
  v_acc_magg_importo_tot              varchar2(20);
  v_sanz_int_importo_tot              varchar2(20);
  v_sanz_magg_importo_tot             varchar2(20);
  --
  v_importo_vers_tot                  varchar2(20);
  v_importo_vers_rid                  varchar2(20);
  --
  type t_acc_cols is record
  ( cod_sanzione                      number(4),
    sanz_ord1                         varchar2(50),
    sanz_ord                          varchar2(50),
    ord                               number(5),
    --importo                           number(10, 2),
    perc_sanzione                     varchar2(10),
    perc_riduzione                    varchar2(10),
    giorni_semestri                   varchar2(5),
    importo_sanzione                  varchar2(20),
    cod_tributo_f24                   varchar2(4),
    descrizione                       varchar2(100),
    accertamento_imposta              varchar2(100),
    --importo_tot                       number(10, 2),
    st_importo_tot                    varchar2(20)
  );
  v_acc_cols t_acc_cols;
  type t_sanz_cols is record
  ( cod_sanzione                      number(4),
    --importo                           number(10, 2),
    perc_sanzione                     varchar2(10),
    perc_riduzione                    varchar2(10),
    giorni_semestri                   varchar2(5),
    importo_sanzione                  varchar2(20),
    cod_tributo_f24                   varchar2(4),
    descrizione                       varchar2(100),
    irrogazioni_sanz                  varchar2(100),
    irrogazioni_sanz_int              varchar2(100),
    --importo_tot                       number(10, 2),
    st_importo_tot                    varchar2(20)
  );
  v_sanz_cols t_sanz_cols;
  --
  type t_riep_vers is record
  ( cod_tributo                      number(4),
    descr_tributo                    varchar2(1000),
    importo                          varchar2(100),
    imp_ridotto                      varchar2(100),
    importo_non_st                   number(10, 2),
    importo_ridotto_non_st           number(10, 2),
    f24_intestazione                 varchar2(100),
    f24_totale                       varchar2(100),
    st_importo_vers_tot              varchar2(100),
    st_importo_vers_rid              varchar2(100)
  );
  v_riep_vers t_riep_vers;
  --
  rc                                  sys_refcursor;
begin
  v_rc := man_acc_imposta(a_prat, a_modello);
  loop
    fetch v_rc
        into v_acc_cols;
      exit when v_rc%notfound;
      v_acc_imposta_importo_tot := v_acc_cols.st_importo_tot;
      exit;
  end loop;
  v_rc := man_acc_magg(a_prat, a_modello);
  loop
    fetch v_rc
        into v_acc_cols;
      exit when v_rc%notfound;
      v_acc_magg_importo_tot := v_acc_cols.st_importo_tot;
      exit;
  end loop;
  v_rc := man_sanz_int(a_prat, a_modello);
  loop
    fetch v_rc
        into v_sanz_cols;
      exit when v_rc%notfound;
      v_sanz_int_importo_tot := v_sanz_cols.st_importo_tot;
      exit;
  end loop;
  v_rc := man_sanz_magg(a_prat, a_modello);
  loop
    fetch v_rc
        into v_sanz_cols;
      exit when v_rc%notfound;
      v_sanz_int_importo_tot := v_sanz_cols.st_importo_tot;
      exit;
  end loop;
  --
  v_importo_vers_tot := 0;
  v_importo_vers_rid := 0;
  v_rc := man_riep_vers(a_prat, a_modello);
  loop
    fetch v_rc
      into v_riep_vers;
    exit when v_rc%notfound;
    v_importo_vers_tot := v_riep_vers.st_importo_vers_tot;
    v_importo_vers_rid := v_riep_vers.st_importo_vers_rid;
    exit;
  end loop;
  --
  open rc for
    select '(Identificativo Operazione ACCU' || prtr_acc.anno ||
           lpad(prtr_acc.pratica, 10, '0') || ')' as id_operazione_char
         , 'ACCU' || prtr_acc.anno ||
           lpad(prtr_acc.pratica, 10, '0') as id_operazione
         , a_modello modello
         , a_cf cod_fiscale
         , prtr_acc.pratica pratica
         , translate (prtr_acc.motivo, chr (013) || chr (010), '  ') motivo
         , lpad(prtr_acc.anno, 4) anno
         , lpad(nvl (prtr_acc.numero, ' '), 15, '0') prtr_numero
         , nvl(prtr_acc.numero, ' ') prtr_numero_vis
         , prtr_acc.anno prtr_anno
         , nvl(to_char (prtr_acc.data, 'dd/mm/yyyy'), ' ') data
         , decode(rtrim (f_descrizione_timp (a_modello, 'INTE'))
        -- (VD - 21/02/2022): in caso di stampa da TributiWeb si
        --                    stampa sempre "Atto"
        --,'DEFAULT',f_tipo_accertamento(ogpr_acc.oggetto_pratica)
        ,'DEFAULT','ATTO'
        ,rtrim(f_descrizione_timp(a_modello, 'INTE'))
        ) tipo_acc
         , stampa_common.f_formatta_numero(f_round(prtr_acc.importo_totale
                                                       + nvl(addiz.tot_add,0)
                                               ,1
                                               )
        ,'I','S'
        ) importo_totale
         , decode(f_descrizione_timp(a_modello, 'VIS_TOT_ARR')
        ,'SI',decode(titr.flag_tariffa
                      ,null,stampa_common.f_formatta_numero(round(prtr_acc.importo_totale
                                                                      + nvl(addiz.tot_add,0)
                                                                ,0
                                                                )
                         ,'I','S')
                      ,null
                      )
        ,null
        ) importo_totale_arrotondato
         , decode(prtr_acc.importo_ridotto
        ,prtr_acc.importo_totale, null
        ,stampa_common.f_formatta_numero(f_round(prtr_acc.importo_ridotto
                                                     + nvl (addiz.tot_add,0)
                                             ,1
                                             )
                      ,'I','S'
                      )
        ) importo_ridotto
         , decode(f_descrizione_timp(a_modello,'VIS_TOT_ARR')
                  ,'SI',decode(prtr_acc.importo_ridotto
                                ,prtr_acc.importo_totale, null
                                ,decode(titr.flag_tariffa
                                   ,null,stampa_common.f_formatta_numero(round(prtr_acc.importo_ridotto
                                                                                   + nvl (addiz.tot_add,0)
                                                                             ,0
                                                                             )
                                            ,'I','S'
                                            )
                                   ,null
                                   )
                                )
                  ,null
         ) importo_ridotto_arrotondato
         , f_descrizione_timp(a_modello,'TOT') totale
         , decode(titr.flag_tariffa
                  ,null,decode(f_descrizione_timp(a_modello,'VIS_TOT_ARR')
                               ,'SI',f_descrizione_timp(a_modello,'TOT_ARR')
                               ,null
                               )
                  ,null
           ) totale_arr
         , decode(prtr_acc.importo_ridotto
                  ,prtr_acc.importo_totale, null
                  ,f_descrizione_timp(a_modello,'TOT_AD')
           ) totale_ad
         , decode(prtr_acc.importo_ridotto
        ,prtr_acc.importo_totale,null
        ,decode(titr.flag_tariffa
                      ,null,decode(f_descrizione_timp(a_modello,'VIS_TOT_ARR')
                    ,'SI',f_descrizione_timp(a_modello,'TOT_AD_ARR')
                    ,null
                    )
                      ,null
                      )
        ) totale_ad_arr
         , f_descrizione_timp(a_modello,'TOT_IMP_COMP') totale_imposta_complessiva
         , trim(f_descrizione_timp(a_modello,'RIE_SOM_DOV')) riepilogo_somme_dovute
         , prtr_acc.tipo_evento
         , f_descrizione_titr(prtr_acc.tipo_tributo,prtr_acc.anno) descr_titr
         , sopr.*
         , (f_importi_acc(prtr_acc.pratica,'N','TASSA_EVASA') +
            decode(cope.presenti,0,0,f_importi_acc(prtr_acc.pratica,'N','MAGGIORAZIONE'))
           ) tot_imposta
         , f_importi_acc(prtr_acc.pratica,'N','ADD_PRO') tot_add_pro
         , (f_importi_acc(prtr_acc.pratica,'N','TASSA_EVASA') +
            f_importi_acc(prtr_acc.pratica,'N','ADD_PRO') +
            decode(cope.presenti,0,0,f_importi_acc(prtr_acc.pratica,'N','MAGGIORAZIONE'))
           ) tot_imposta_lorda
         , (select sum(f_round(sum(nvl(ogim02.maggiorazione_tares, 0)),1)) magg_tares_acc_no_visibile
              from "OGGETTI_IMPOSTA"      ogim02,
                   "OGGETTI_CONTRIBUENTE" ogco02,
                   "OGGETTI_PRATICA"      ogpr02,
                   "PRATICHE_TRIBUTO"     prtr02,
                   carichi_tarsu          cata02,
                   soggetti_pratica       sopr02
            where (ogim02."ANNO"(+) = ogco02.anno)
              and (ogim02."COD_FISCALE"(+) =
                   ogco02."COD_FISCALE")
              and (ogim02."OGGETTO_PRATICA"(+) =
                   ogco02."OGGETTO_PRATICA")
              and (ogco02."COD_FISCALE" = a_cf)
              and (ogco02."OGGETTO_PRATICA" =
                   ogpr02."OGGETTO_PRATICA")
              and (ogpr02."PRATICA" = prtr02."PRATICA")
              and (prtr02."PRATICA" = a_prat)
              and cata02.anno = prtr02.anno
              and sopr02.pratica = prtr02.pratica
              and sopr02.cod_fiscale = prtr02.cod_fiscale
            group by ogim02.maggiorazione_eca) tot_magg_tares
         , decode(v_acc_imposta_importo_tot,
                  NULL,
                  NULL,
                  f_descrizione_timp(a_modello, 'TOTACCIMP')) label_acc_imposta_importo_tot,
        v_acc_imposta_importo_tot acc_imposta_importo_tot,
        decode(v_sanz_int_importo_tot,
               null,
               null,
               f_descrizione_timp(a_modello, 'TOTSANZ')) label_sanz_int_importo_tot,
        v_sanz_int_importo_tot sanz_int_importo_tot,
        decode(v_acc_magg_importo_tot,
               NULL,NULL,
               decode(cope.presenti
                     ,1,'TOTALE COMPONENTI PEREQUATIVE EVASE'
                     ,'TOTALE MAGG. TARES EVASA'
                     )
        ) label_acc_magg_importo_tot,
        v_acc_magg_importo_tot acc_magg_importo_tot,
        decode(v_sanz_magg_importo_tot,
               null,
               null,
               f_descrizione_timp(a_modello, 'TOTSANZ')) label_sanz_magg_importo_tot,
        v_sanz_magg_importo_tot sanz_magg_importo_tot,
        stampa_common.f_formatta_numero(f_importi_acc(prtr_acc.pratica,'N','ADD_PRO')
            ,'I','S') acc_add_pro_importo_tot,
        stampa_common.f_formatta_numero(f_importi_acc(prtr_acc.pratica,'N','TASSA_EVASA') +
                                        f_importi_acc(prtr_acc.pratica,'N','ADD_PRO') +
                                        decode(cope.presenti,0,0,f_importi_acc(prtr_acc.pratica,'N','MAGGIORAZIONE'))
            ,'I','S') acc_imp_lorda_importo_tot
          --
         , decode(f_descrizione_timp(a_modello, 'VIS_TOT_ARR')
                 ,'SI',v_importo_vers_tot
                 ,null
                 ) importo_totale_arrotondato_F24
         , decode(f_descrizione_timp(a_modello,'VIS_TOT_ARR')
                 ,'SI',v_importo_vers_rid
                 ,null
                 ) importo_rid_arrotondato_F24
         , a_ni_erede                  ni_erede
    from PRATICHE_TRIBUTO prtr_acc
       , TIPI_TRIBUTO titr
       , CARICHI_TARSU cata
       , soggetti_pratica sopr
       ,(select prtr_acc_cate.pratica pratica
              , nvl(sum(f_cata(cata.anno
            ,1,decode(sapr.importo
                                   ,null,sanzioni.sanzione
                                   ,sapr.importo
                                   )
            ,'T'
            )
                        )
            ,0
            ) tot_add
         from carichi_tarsu cata
            , sanzioni_pratica sapr
            , sanzioni
            , pratiche_tributo prtr_acc_cate
         where cata.anno = prtr_acc_cate.anno
           and sanzioni.tipo_tributo = 'TARSU'
           and sanzioni.tipo_causale||nvl(sanzioni.flag_magg_tares,'N') = 'EN'
           and sanzioni.cod_sanzione not in (888, 889)
           and sapr.pratica in (a_prat)
           and sanzioni.cod_sanzione = sapr.cod_sanzione
           and sanzioni.sequenza = sapr.sequenza_sanz
           and sapr.pratica = prtr_acc_cate.pratica
         group by prtr_acc_cate.pratica) addiz,
         (
          select decode(count(cope.componente),0,0,1) as presenti
            from componenti_perequative cope,
                 pratiche_tributo prtr
           where cope.anno = prtr.anno
             and prtr.pratica = a_prat
         ) cope
    where addiz.pratica(+) = prtr_acc.pratica
      and prtr_acc.tipo_tributo = titr.tipo_tributo
      and prtr_acc.pratica in (a_prat)
      and cata.anno = prtr_acc.anno
      and sopr.pratica = prtr_acc.pratica
      and sopr.cod_fiscale = prtr_acc.cod_fiscale
    order by prtr_acc.pratica;
  return rc;
end;
--------------------------------------------------------------
function man_oggetti
  ( a_cf                                varchar2
  , a_prat                              number
  , a_anno                              number
  , a_modello                           number
  ) return sys_refcursor
is
  --
  rc sys_refcursor;
  --
begin
  open rc for
    select ogg.*,
           f_cope_dettagli(ogg.prtr_anno, ogg.imposta_dovuta_cope_num, null) as dett_imposta_cope,
           f_cope_dettagli(ogg.prtr_anno, ogg.imposta_dovuta_cope_dic_num, null) as dett_imposta_cope_dic
      from (
            select distinct
              decode(nvl(cata.addizionale_eca,0),0,'','ADDIZIONALE ECA :') st_addizionale_eca
             ,decode(nvl(cata.addizionale_eca,0)
              ,0,''
              ,decode(decode(cotr.flag_ruolo
                          ,null,'N'
                          ,ogdic.lordo
                          )
                                    ,'N',''
                                    ,stampa_common.f_formatta_numero
                          (f_round(nvl(round(ogdic.imposta
                                                 * nvl(cata.addizionale_eca,0)
                                                 / 100
                                           ,2
                                           )
                                       ,0
                                       )
                               ,1
                               )
                          ,'I','S'
                          )
                                    )
              ) imposta_dovuta_dic_add_eca
              ,decode(f_descrizione_timp (a_modello,'ACC_ELENCO')
                      ,'SI',decode(nvl(cata.addizionale_eca,0)
                                    ,0,''
                                    ,decode(decode(cotr.flag_ruolo
                                                ,null,'N'
                                                ,ogdic.lordo
                                                )
                               ,'S',stampa_common.f_formatta_numero
                                                (nvl(round(ogim_acc.imposta
                                                               * nvl(cata.addizionale_eca,0)
                                                               / 100
                                                         ,2
                                                         )
                                                     ,0
                                                     )
                                                ,'I','S'
                                                )
                               ,''
                               )
                                    )
              ) imposta_dovuta_add_eca
              ,decode(nvl(cata.maggiorazione_eca,0),0,'','MAGG. ECA :') st_maggiorazione_eca
              ,decode(nvl(cata.maggiorazione_eca,0)
              ,0,''
              ,decode(decode(cotr.flag_ruolo
                          ,null,'N'
                          ,ogdic.lordo
                          )
                                    ,'N',''
                                    ,stampa_common.f_formatta_numero
                          (nvl(round(ogdic.imposta
                                         * nvl(cata.maggiorazione_eca,0)
                                         / 100
                                   ,2
                                   )
                               ,0
                               )
                          ,'I','S'
                          )
                                    )
              ) imposta_dovuta_dic_mag_eca
              ,decode(f_descrizione_timp(a_modello,'ACC_ELENCO')
                ,'SI',decode(nvl(cata.maggiorazione_eca,0)
                                    ,0,''
                                    ,decode(decode(cotr.flag_ruolo
                                                ,null,'N'
                                                ,ogdic.lordo
                                                )
                               ,'N',''
                               ,stampa_common.f_formatta_numero
                                                (nvl(round(ogim_acc.imposta
                                                               * nvl(cata.maggiorazione_eca,0)
                                                               / 100
                                                         ,2
                                                         )
                                                     ,0
                                                     )
                                                ,'I','S'
                                                )
                               )
                                    )
              ,''
              ) imposta_dovuta_mag_eca
              ,decode(nvl(cata.addizionale_pro,0)
              ,0,'',
                                f_descrizione_ADPR(prtr_acc.anno)||' :'
              ) st_addizionale_provinciale
              ,decode(nvl(cata.addizionale_pro,0)
                      ,0,''
                      ,decode(decode(cotr.flag_ruolo
                                    ,null,'N'
                                    ,ogdic.lordo
                                    )
                              ,'N',''
                              ,stampa_common.f_formatta_numero
                                  (nvl(round(ogdic.imposta * nvl(cata.addizionale_pro,0) / 100, 2)
                                       ,0
                                       )
                                  ,'I','S')
                              )
              ) imposta_dovuta_dic_add_pro
              ,decode(f_descrizione_timp (a_modello,'ACC_ELENCO')
                      ,'SI',decode(nvl(cata.addizionale_pro,0)
                                    ,0,''
                                    ,decode(decode(cotr.flag_ruolo
                                                  ,null,'N'
                                                  ,ogdic.lordo
                                                  )
                                     ,'N',''
                                     ,stampa_common.f_formatta_numero
                                                (nvl(round(ogim_acc.imposta * nvl(cata.addizionale_pro,0) / 100,2)
                                                     ,0)
                                                ,'I','S')
                                           )
                                    )
              ) imposta_dovuta_add_pro
              ,decode(nvl(cata.aliquota,0),0,'','IVA :') s_iva
              ,decode(nvl(cata.aliquota,0)
                      ,0,''
                      ,decode(decode(cotr.flag_ruolo
                                    ,null,'N'
                                    ,ogdic.lordo
                                    )
                              ,'N',''
                              ,stampa_common.f_formatta_numero
                                  (nvl(round(ogdic.imposta * nvl(cata.aliquota,0) / 100, 2)
                                       ,0)
                                  ,'I','S')
                              )
              ) imposta_dovuta_dic_iva
              ,decode(f_descrizione_timp (a_modello,'ACC_ELENCO')
                      ,'SI',decode(nvl(cata.aliquota,0)
                                    ,0,''
                                    ,decode(decode(cotr.flag_ruolo
                                                ,null,'N'
                                                ,ogdic.lordo
                                                )
                               ,'N',''
                               ,stampa_common.f_formatta_numero
                                                (nvl(round(ogim_acc.imposta
                                                               * nvl(cata.aliquota,0)
                                                               / 100
                                                         ,2
                                                         )
                                                     ,0
                                                     )
                                                ,'I','S'
                                                )
                               )
                                    )
              ) imposta_dovuta_iva
              ,prtr_acc.pratica pratica
              ,decode(f_descrizione_timp (a_modello,'ACC_ELENCO')
                      ,'SI',nvl(cate.descrizione,' ')
              ) categorie_desc
              ,nvl(ogdic.categorie_d,' ') categorie_desc_dic
              ,nvl(to_char(ogim_acc.anno),' ') anno
              ,nvl(to_char(ogdic.anno),' ') anno_dic
              ,nvl(prtr_acc.numero,' ') prtr_numero
              ,nvl(prtr_acc.numero,' ') prtr_numero_vis
              ,prtr_acc.anno prtr_anno
              ,decode(f_descrizione_timp (a_modello,'ACC_ELENCO')
                      ,'SI',nvl(to_char (ogco_acc.inizio_occupazione,'dd/mm/yyyy')
                                    ,' '
                                    )
              ) ogco_inizio_occup
              ,decode(f_descrizione_timp (a_modello,'ACC_ELENCO')
                      ,'SI',nvl(to_char(ogco_acc.data_decorrenza,'dd/mm/yyyy')
                                    ,' '
                                    )
              ) ogco_data_decorrenza
              ,decode(f_descrizione_timp(a_modello,'ACC_ELENCO')
                      ,'SI',nvl(to_char(ogco_acc.fine_occupazione,'dd/mm/yyyy')
                                    ,' '
                                    )
              ) ogco_fine_occup
              ,decode(f_descrizione_timp(a_modello,'ACC_ELENCO'),'SI','mq.') as mqacc
              ,nvl(to_char(ogdic.inizio_occupazione_d,'dd/mm/yyyy'),'          ') as ogco_inizio_occup_dic
              ,nvl(to_char(ogdic.data_decorrenza_d,'dd/mm/yyyy'),'          ') as ogco_data_decorrenza_dic
              ,nvl(to_char(ogdic.fine_occupazione_d,'dd/mm/yyyy'),'          ') as ogco_fine_occup_dic
              ,decode(ogco_acc.inizio_occupazione
              ,null,decode(ogdic.inizio_occupazione_d
                                    ,null,' '
                                    ,'INIZIO OCCUPAZ. : '
                                    )
              ,'INIZIO OCCUPAZ. : '
              ) as sinizio_occup
              ,decode(ogco_acc.data_decorrenza
              ,null,decode(ogdic.data_decorrenza_d
                                    ,null,' '
                                    ,'DATA DECORRENZA : '
                                    )
              ,'DATA DECORRENZA : '
              ) as sdata_decor
              ,decode(ogco_acc.fine_occupazione
              ,null,decode(ogdic.fine_occupazione_d
                                    ,null,' '
                                    ,'FINE OCCUPAZIONE: '
                                    )
              ,'FINE OCCUPAZIONE: '
              ) as sfine_occup
              ,nvl(to_char(prtr_acc.data,'dd/mm/yyyy'),' ') data_acc
              ,decode(ogpr_acc.oggetto_pratica_rif
              ,null,'omessa presentazione della denuncia'
              ,'rettifica della denuncia presentata'
              ) as tipo_acc
              ,decode(ogpr_acc.oggetto_pratica_rif
              ,null,'          '
              ,'DICHIARATI'
              ) as sdichiarati
              ,decode(f_descrizione_timp (a_modello,'ACC_ELENCO')
                      ,'SI',decode(nvl(ogim_acc.imposta,0) +
                                       (nvl(ogim_acc.maggiorazione_tares, 0) * cope.presenti)
                                            ,0,''
                                            ,stampa_common.f_formatta_numero(f_round(nvl(ogim_acc.imposta,0) +
                                                                                     (nvl(ogim_acc.maggiorazione_tares, 0) * cope.presenti),1)
                                       ,'I','S'
                                       )
                                )
              ) imposta_acc
              ,decode(f_descrizione_timp(a_modello,'ACC_ELENCO')
                    ,'SI',decode(cata.maggiorazione_tares
                                ,null,''
                                ,decode(nvl(ogim_acc.maggiorazione_tares,0)
                                       ,0,''
                                       ,stampa_common.f_formatta_numero(f_round(nvl(ogim_acc.maggiorazione_tares,0),1)
                                                        ,'I','S')
                                       )
                                )
              ) magg_tares_acc
              ,decode(f_descrizione_timp(a_modello,'ACC_ELENCO')
                    ,'SI',decode(nvl(ogim_acc.imposta,0) +
                                 (nvl(ogim_acc.maggiorazione_tares, 0) * cope.presenti)
                                  ,0,''
                                  ,stampa_common.f_formatta_numero
                                                 (nvl(ogim_acc.imposta, 0) +
                                                  (nvl(ogim_acc.maggiorazione_tares, 0) * cope.presenti) +
                                                  decode(decode(cotr.flag_ruolo
                                                                 ,null,'N'
                                                                 ,nvl(ogdic.lordo,nvl(cata.flag_lordo,'N'))
                                                                 )
                                                        ,'S',nvl(round(ogim_acc.imposta * nvl(cata.addizionale_eca,0) / 100, 2)
                                                               + round(ogim_acc.imposta * nvl(cata.maggiorazione_eca,0) / 100, 2)
                                                               + round(ogim_acc.imposta * nvl(cata.addizionale_pro,0) / 100, 2)
                                                               + round(ogim_acc.imposta * nvl(cata.aliquota,0) / 100, 2)
                                                               ,0)
                                                        ,0
                                                        )
                                                 ,'I','S')
                                 )
              ) imposta_dovuta
              ,decode(f_descrizione_timp(a_modello,'ACC_ELENCO')
                    ,'SI',decode(cata.maggiorazione_tares
                                 ,null,''
                                 ,decode(nvl(ogim_acc.maggiorazione_tares,0)
                                         ,0,''
                                         ,stampa_common.f_formatta_numero
                                                            (f_round(nvl(ogim_acc.maggiorazione_tares,0),1)
                                                 ,'I','S')
                                         )
                                 )
              ) magg_tares_dovuta
              ,decode(nvl(ogdic.imposta,0) +
                      (nvl(ogdic.maggiorazione_tares, 0) * cope.presenti)
                      ,0,''
                      ,stampa_common.f_formatta_numero(f_round(nvl(ogdic.imposta,0) +
                                                               (nvl(ogdic.maggiorazione_tares, 0) * cope.presenti),1)
                                                       ,'I','S')
              ) imposta_dic
              ,decode(cata.maggiorazione_tares
                      ,null,''
                      ,decode(nvl(ogdic.maggiorazione_tares,0)
                              ,0,''
                              ,stampa_common.f_formatta_numero(f_round(nvl(ogdic.maggiorazione_tares,0),1)
                                                        ,'I','S')
                             )
              ) magg_tares_dic
              ,decode(nvl(ogdic.imposta,0) +
                      (nvl(ogdic.maggiorazione_tares, 0) * cope.presenti)
                      ,0,''
                      ,stampa_common.f_formatta_numero
                                    (nvl(ogdic.imposta,0) +
                                     (nvl(ogdic.maggiorazione_tares, 0) * cope.presenti) +
                                     decode(decode(cotr.flag_ruolo
                                                ,null,'N'
                                                ,ogdic.lordo
                                                )
                                           ,'S',nvl(round(ogdic.imposta * nvl(cata.addizionale_eca,0)/ 100,2)
                                                  + round(ogdic.imposta * nvl(cata.maggiorazione_eca,0) / 100,2)
                                                  + round(ogdic.imposta * nvl(cata.addizionale_pro,0) / 100,2)
                                                  + round(ogdic.imposta * nvl(cata.aliquota,0) / 100,2)
                                                  ,0
                                                  )
                                           ,0
                                           )
                                    ,'I','S'
                                    )
              ) imposta_dovuta_dic
              ,decode(nvl(ogim_acc.imposta,0) +
                      (nvl(ogim_acc.maggiorazione_tares, 0) * cope.presenti)
                      ,0,decode(nvl(ogdic.imposta,0)
                                ,0,''
                                ,f_descrizione_timp(a_modello,'DIC ACC IMP DOV')||' :'
                                )
                      ,f_descrizione_timp(a_modello,'DIC ACC IMP DOV')||' :'
              ) st_imposta_dovuta
              ,decode(cata.maggiorazione_tares
                      ,null,''
                      ,decode(nvl(ogim_acc.maggiorazione_tares,0) + nvl(ogdic.maggiorazione_tares,0)
                              ,0,''
                              ,'MAGG. TARES :'
                              )
              ) st_magg_tares_dovuta
              ,decode(f_tipo_accertamento(ogpr_acc.oggetto_pratica)
                      ,'Atto',''
                      ,decode(sign(least(nvl(ogpr_acc.consistenza,0),nvl(ogdic.cons,0)))
                              ,1,'UTENZA GIA'' A RUOLO PER '
                                ||ltrim(translate(to_char(least(nvl(ogpr_acc.consistenza,0)
                                                        ,nvl(ogdic.cons,0)
                                                        )
                                                ,'999,990.00'
                                                )
                                  ,'.,'
                                  ,',.'
                                  )
                                           )
                          ||' MQ.'
                                    ,null
                                    )
              ) cons_dic
              ,ceil(months_between(decode(ogco_acc.data_cessazione
                                       ,null,to_date(decode(ogco_acc.data_decorrenza
                                                         ,null,'31/12/1900'
                                                         ,'31/12/'||to_char(ogco_acc.data_decorrenza,'yyyy')
                                                         )
                                              ,'dd/mm/yyyy'
                                              )
                                       ,ogco_acc.data_cessazione
                                       )
                                      ,decode(ogco_acc.data_decorrenza
                                                 ,null,to_date(decode(ogco_acc.data_cessazione
                                                                   ,null,'01/01/1901'
                                                                   ,'01/01/'||to_char(ogco_acc.data_cessazione,'yyyy')
                                                                   )
                          ,'dd/mm/yyyy'
                          )
                                                 ,ogco_acc.data_decorrenza
                                                 )
                                  )
              ) mesi
              ,decode(ogpr_acc.oggetto_pratica_rif
                      ,null,''
                      ,ceil(months_between(decode(ogdic.data_cessazione_d
                                                 ,null,to_date(decode(ogdic.data_decorrenza_d
                                                                     ,null,'31/12/1900'
                                                                     ,'31/12/'||to_char(ogdic.data_decorrenza_d,'yyyy')
                                                                     )
                                                        ,'dd/mm/yyyy')
                                                 ,ogdic.data_cessazione_d
                                                 )
                                          ,decode(ogdic.data_decorrenza_d
                                                 ,null,to_date(decode(ogdic.data_cessazione_d
                                                                     ,null,'01/01/1901'
                                                                     ,'01/01/'||to_char(ogdic.data_cessazione_d,'yyyy')
                                                                     )
                                                                ,'dd/mm/yyyy')
                                                 ,ogdic.data_decorrenza_d
                                                 )
                                           )
                           )
              ) mesi_dic
              ,decode(f_descrizione_timp (a_modello,'ACC_ELENCO')
                      ,'SI',decode(cate.flag_domestica,'S','UD - ','UND - ')||nvl(tari.descrizione,' ')
                      ,''
              ) tariffa_desc
              ,nvl(stampa_common.f_formatta_numero(ogdic.tariffa_d,'T','S')
                   ,' '
              ) tariffa_dic
              ,nvl(stampa_common.f_formatta_numero(tari.riduzione_quota_fissa,'P','S'),' ') as riduzione_quota_fissa
              ,nvl(stampa_common.f_formatta_numero(tari.riduzione_quota_variabile,'P','S'),' ') as riduzione_quota_variabile
              ,nvl(stampa_common.f_formatta_numero(tado.tariffa_quota_fissa,'T','S'),' ') as tariffa_dom_quota_fissa
              ,nvl(stampa_common.f_formatta_numero(tado.tariffa_quota_variabile,'T','S'),' ') as tariffa_dom_quota_variabile
              ,nvl(stampa_common.f_formatta_numero(tado.tariffa_quota_fissa_no_ap,'T','S'),' ') as tariffa_dom_quota_fissa_no_ap
              ,nvl(stampa_common.f_formatta_numero(tado.tariffa_quota_variabile_no_ap,'T','S'),' ') as tariffa_dom_quota_var_no_ap
              ,nvl(stampa_common.f_formatta_numero(tand.tariffa_quota_fissa,'T','S'),' ') as tariffa_nondom_quota_fissa
              ,nvl(stampa_common.f_formatta_numero(tand.tariffa_quota_variabile,'T','S'),' ')  as tariffa_nondom_quota_variabile
              ,nvl(decode(ogdic.tipo_utenza,null,'',ogdic.tipo_utenza||' - ')||ogdic.descrizione_d,' ') as tariffa_desc_dic
              ,decode(oggetti.partita
                          || oggetti.sezione
                          || oggetti.foglio
                          || oggetti.numero
                          || oggetti.subalterno
                          || oggetti.zona
                          || oggetti.protocollo_catasto
                          || to_char(oggetti.anno_catasto)
                          || oggetti.categoria_catasto
                          || oggetti.classe_catasto
              ,null,''
              ,'Estremi Oggetto: '
              ) st_estremi_oggetto
              ,rpad(oggetti.partita,9) partita
              ,rpad(oggetti.sezione,5) sezione
              ,rpad(oggetti.foglio,7) foglio
              ,rpad(oggetti.numero,7) numero
              ,rpad(oggetti.subalterno,5) subalterno
              ,rpad(oggetti.zona,5) zona
              ,decode(oggetti.protocollo_catasto
                          || to_char(oggetti.anno_catasto)
                          || oggetti.categoria_catasto
                          || oggetti.classe_catasto
              ,null,''
              ,'Estremi Catasto: '
              ) st_estremi_catasto
              ,rpad(oggetti.protocollo_catasto,7) protocollo_catasto
              ,rpad(to_char (oggetti.anno_catasto),5) anno_catasto
              ,rpad(oggetti.categoria_catasto,5) categoria_catasto
              ,rpad(oggetti.classe_catasto,4) classe_catasto
              ,decode(oggetti.partita,null,'','Partita  ') st_partita
              ,decode(oggetti.sezione,null,'','Sez. ') st_sezione
              ,decode(oggetti.foglio,null,'','Foglio ') st_foglio
              ,decode(oggetti.numero,null,'','Numero ') st_numero
              ,decode(oggetti.subalterno,null,'','Sub. ') st_subalterno
              ,decode(oggetti.zona,null,'','Zona ') st_zona
              ,decode(oggetti.protocollo_catasto,null,'','Prot.  ') st_protocollo
              ,decode(oggetti.anno_catasto,null,'','Anno ') st_anno
              ,decode(oggetti.categoria_catasto,null,'','Cat. ') st_categoria
              ,decode(oggetti.classe_catasto,null,'','Cl. ') st_classe
              ,(decode(oggetti.cod_via
                   ,null,oggetti.indirizzo_localita
                   ,archivio_vie.denom_uff
                   )
                || decode(oggetti.num_civ,null,'',',' || oggetti.num_civ)
                || decode(oggetti.suffisso
                             ,null,''
                             ,'/' || oggetti.suffisso
                             )
               ) indirizzo_ogg
              ,decode(f_descrizione_timp (a_modello,'ACC_ELENCO')
                      ,'SI',nvl(ltrim(translate(to_char(ogpr_acc.consistenza,'999,990.00')
                                                ,'.,'
                                                ,',.'
                                               )
                                     )
                                ,' '
                                )
              ) superficie
              ,nvl(ltrim(translate(to_char(ogdic.consistenza_d,'999,990.00')
                                  ,'.,'
                                  ,',.'
                                  )
                        )
                  ,' '
              ) superficie_dic
              ,decode(ogdic.consistenza_d,null,'','mq. ') mqdic
              ,decode(f_descrizione_timp(a_modello,'ACC_ELENCO')
                      ,'SI',stampa_common.f_formatta_numero(nvl(ogco_acc.perc_possesso,100)
                                    ,'I','S')
              ) perc_possesso
              ,decode(ogpr_acc.oggetto_pratica_rif
                      ,null,' '
                      ,stampa_common.f_formatta_numero(nvl(ogdic.perc_possesso_d,100)
                                    ,'I','S')
              ) perc_possesso_dic
              ,decode(f_descrizione_timp (a_modello,'ACC_ELENCO')
                      ,'SI',decode(f_tipo_accertamento(ogpr_acc.oggetto_pratica)
                                  ,'Denuncia presentata oltre i termini di legge',null
                                  ,f_descrizione_timp (a_modello,'ACC')
                                  )
              ) accertati
              , oggetti.oggetto
              , decode(cate.flag_domestica||ogdic.categorie_d
                        ,null,''
                        ,'ABITAZ. PRINC. :'
              ) st_ab_principale
              , decode(cate.flag_domestica
                      ,null,''
                      ,decode(ogco_acc.flag_ab_principale,'S','SI','NO')
              ) ab_principale_Acc
              , decode(ogdic.ogpr,null,''
                      ,decode(ogdic.categorie_d
                             ,null,''
                             ,decode(ogdic.flag_ab_principale,'S','SI','NO')
                             )
              ) ab_principale_dic
              , decode(f_get_dettagli_acc_tarsu_ogim(prtr_acc.pratica,
                                                     ogim_acc.oggetto_imposta),
                       null,
                       '',
                       replace(replace(replace(f_get_dettagli_acc_tarsu_ogim(prtr_acc.pratica,
                                                                             ogim_acc.oggetto_imposta),
                                               '                        ',
                                               ''),
                                       'DETTAGLI        :       ',
                                       ''),
                               '[a_capo',
                               CHR(10))
                ) n_familiari
              , ogdic.tipo_utenza tipo_utenza_dic
              , to_char(ogco_acc.data_decorrenza,'dd/mm/yyyy') data_decorrenza
              , cate.flag_domestica
              , decode(cate.flag_domestica, null, 'NON ', '') || 'DOMESTICA' tipo_utenza_acc
              , decode(f_descrizione_timp(a_modello,'ACC_ELENCO')
                       ,'SI',to_char(least(least(nvl(ogco_acc.data_cessazione,to_date('3112'||a_anno,'ddMMYYYY')),
                                                 nvl(ogco_acc.fine_occupazione,to_date('3112'||a_anno,'ddMMYYYY'))),
                                                                                     to_date('3112'||a_anno,'ddMMYYYY')) -
                                     greatest(greatest(nvl(ogco_acc.data_decorrenza,to_date('0101'||a_anno,'ddMMYYYY')),
                                                       nvl(ogco_acc.inizio_occupazione,to_date('0101'||a_anno,'ddMMYYYY'))),
                                                                                     to_date('0101'||a_anno,'ddMMYYYY'))
                                      + 1)
                       ,' '
              ) ogco_gg_occup
              , decode(f_descrizione_timp(a_modello,'ACC_ELENCO')
                       ,'SI',to_char(least(nvl(ogco_acc.data_cessazione,to_date('3112'||a_anno,'ddMMYYYY')),to_date('3112'||a_anno,'ddMMYYYY')) -
                                     greatest(nvl(ogco_acc.data_decorrenza,to_date('0101'||a_anno,'ddMMYYYY')),to_date('0101'||a_anno,'ddMMYYYY')) + 1)
                       ,' '
              ) ogco_gg_possesso
              , decode(ogdic.anno,null,'',
                       decode(f_descrizione_timp(a_modello,'ACC_ELENCO')
                             ,'SI',to_char(least(least(nvl(ogdic.data_cessazione_d,to_date('3112'||a_anno,'ddMMYYYY')),
                                                       nvl(ogdic.fine_occupazione_d,to_date('3112'||a_anno,'ddMMYYYY'))),
                                                                                           to_date('3112'||a_anno,'ddMMYYYY')) -
                                           greatest(greatest(nvl(ogdic.data_decorrenza_d,to_date('0101'||a_anno,'ddMMYYYY')),
                                                             nvl(ogdic.inizio_occupazione_d,to_date('0101'||a_anno,'ddMMYYYY'))),
                                                                                           to_date('0101'||a_anno,'ddMMYYYY'))
                                            + 1)
                             ,' '
                       )
              ) ogco_gg_occup_dic
              , decode(ogdic.anno,null,'',
                       decode(f_descrizione_timp(a_modello,'ACC_ELENCO')
                             ,'SI',to_char(least(nvl(ogdic.data_cessazione_d,to_date('3112'||a_anno,'ddMMYYYY')),to_date('3112'||a_anno,'ddMMYYYY')) -
                                           greatest(nvl(ogdic.data_decorrenza_d,to_date('0101'||a_anno,'ddMMYYYY')),to_date('0101'||a_anno,'ddMMYYYY')) + 1)
                             ,' '
                       )
              ) ogco_gg_possesso_dic,
              to_char(dtrl.giorni_ruolo) as gg_ruolo
              --
            , (nvl(ogim_acc.maggiorazione_tares, 0) * cope.presenti) as imposta_dovuta_cope_num
            , rpad(decode((nvl(ogim_acc.maggiorazione_tares, 0) * cope.presenti)
                          ,0
                          ,'                    '
                          ,ltrim(stampa_common.f_formatta_numero((nvl(ogim_acc.maggiorazione_tares, 0) * cope.presenti),
                                                                'I','S'))),
                   30) as imposta_dovuta_cope
              --
            , (nvl(ogdic.maggiorazione_tares, 0) * cope.presenti) as imposta_dovuta_cope_dic_num
            , rpad(decode((nvl(ogdic.maggiorazione_tares, 0) * cope.presenti)
                          ,0
                          ,'                    '
                          ,ltrim(stampa_common.f_formatta_numero((nvl(ogdic.maggiorazione_tares, 0) * cope.presenti),
                                                                'I','S'))),
                   30) as imposta_dovuta_cope_dic
          from ARCHIVIO_VIE
             , DATI_GENERALI
             , OGGETTI
             , CATEGORIE cate
             , TARIFFE tari
             , OGGETTI_IMPOSTA ogim_acc
             , OGGETTI_CONTRIBUENTE ogco_acc
             , OGGETTI_PRATICA ogpr_acc
             , PRATICHE_TRIBUTO prtr_acc
             , CODICI_TRIBUTO cotr
             , CARICHI_TARSU cata
             ,(select decode(max(ruol.invio_consorzio)
                        ,null,0
                        ,ogpr_dic.consistenza
                      ) cons
                    , ogpr_dic.oggetto_pratica ogpr
                    , ogim_dic.anno
                    , sum(ogim_dic.imposta)
                      - nvl(round(f_sgravio_ogpr(a_cf
                                      ,a_anno
                                      ,prtr_dic.TIPO_TRIBUTO
                                      ,ogpr_dic.OGGETTO_PRATICA
                                      )
                                ,2
                                )
                              ,0
                              ) imposta
                    , sum(ogim_dic.maggiorazione_tares) maggiorazione_tares
                    , decode(max(ruol.ruolo)
                        ,null,nvl(cata.flag_lordo,'N')
                        ,nvl(max(ruol.importo_lordo),'N')
                      ) lordo
                    , ogpr_dic.data_concessione data_concessione_d
                    , ogco_dic.inizio_occupazione inizio_occupazione_d
                    , ogco_dic.fine_occupazione fine_occupazione_d
                    , ogpr_dic.consistenza consistenza_d
                    , ogco_dic.perc_possesso perc_possesso_d
                    , ogco_dic.data_decorrenza data_decorrenza_d
                    , ogco_dic.data_cessazione data_cessazione_d
                    , cate_dic.descrizione categorie_d
                    , tari_dic.tariffa tariffa_d
                    , tari_dic.descrizione descrizione_d
                    , prtr_dic.flag_denuncia flag_denuncia
                    , max(ogco_dic.flag_ab_principale) flag_ab_principale
                    , prtr_dic.pratica
                    , max(f_get_dettagli_acc_tarsu_ogim(prtr_dic.pratica
                        ,ogim_dic.oggetto_imposta)
                      ) dettagli_acc_tarsu_ogim_dic
                    , decode(cate_dic.flag_domestica, null, 'NON ', '') || 'DOMESTICA' tipo_utenza
               from RUOLI ruol
                  , TARIFFE tari_dic
                  , CATEGORIE cate_dic
                  , OGGETTI_CONTRIBUENTE ogco_dic
                  , OGGETTI_PRATICA ogpr_dic
                  , OGGETTI_IMPOSTA ogim_dic
                  , PRATICHE_TRIBUTO prtr_dic
                  , CARICHI_TARSU cata
               where prtr_dic.pratica = ogpr_dic.pratica
                 and (prtr_dic.tipo_pratica = 'D'
                   or (prtr_dic.tipo_pratica = 'A'
                       and prtr_dic.flag_denuncia = 'S'))
                 and prtr_dic.tipo_tributo || '' = 'TARSU'
                 and tari_dic.tributo = ogpr_dic.tributo
                 and tari_dic.categoria = ogpr_dic.categoria
                 and tari_dic.tipo_tariffa = ogpr_dic.tipo_tariffa
                 and cate_dic.tributo = tari_dic.tributo
                 and cate_dic.categoria = tari_dic.categoria
                 and ogim_dic.ruolo = ruol.ruolo(+)
                 and ogim_dic.ruolo is not null
                 and ruol.invio_consorzio is not null
                 and ogim_dic.cod_fiscale(+) = ogco_dic.cod_fiscale
                 and ogim_dic.oggetto_pratica(+) = ogco_dic.oggetto_pratica
                 and ogim_dic.flag_calcolO(+) = 'S'
                 and tari_dic.anno = a_anno
                 and (nvl(ogim_dic.anno,a_anno) = a_anno
                   or (prtr_dic.tipo_pratica = 'A'
                       and prtr_dic.flag_denuncia = 'S'
                       and prtr_dic.anno = a_anno))
                 and cata.anno = a_anno
                 and ogco_dic.oggetto_pratica = ogpr_dic.oggetto_pratica
                 and ogco_dic.cod_fiscale = a_cf
                 and nvl(F_RUOLO_TOTALE(a_cf,
                                        a_anno,
                                        'TARSU',
                                        -1),
                         ruol.ruolo) = ruol.ruolo
               group by ogpr_dic.oggetto_pratica
                      ,ogim_dic.anno
                      ,ogpr_dic.consistenza
                      ,ogpr_dic.data_concessione
                      ,ogco_dic.inizio_occupazione
                      ,ogco_dic.fine_occupazione
                      ,ogco_dic.perc_possesso
                      ,ogco_dic.data_decorrenza
                      ,ogco_dic.data_cessazione
                      ,cate_dic.descrizione
                      ,tari_dic.tariffa
                      ,tari_dic.descrizione
                      ,prtr_dic.tipo_tributo
                      ,cata.flag_lordo
                      ,prtr_dic.flag_denuncia
                      ,prtr_dic.pratica
                      ,cate_dic.flag_domestica) ogdic
             , CONTRIBUENTI cont
             , TARIFFE_DOMESTICHE tado
             , TARIFFE_NON_DOMESTICHE tand
             , (select distinct
                       ruco.giorni_ruolo,
                       ogim.oggetto_pratica
                  from pratiche_tributo prtr,
                       oggetti_pratica ogpr,
                       oggetti_imposta ogim,
                       ruoli_contribuente ruco
                 where prtr.pratica = a_prat
                   and ogpr.pratica = prtr.pratica
                   and ogim.oggetto_pratica = ogpr.oggetto_pratica_rif
                   and ogim.oggetto_imposta = ruco.oggetto_imposta
                   and ogim.anno = prtr.anno
                   and ogim.ruolo = f_get_ultimo_ruolo(ogim.COD_FISCALE,ogim.ANNO,ogim.tipo_tributo,'T','','',0)
               ) dtrl,
               (
                select decode(count(cope.componente),0,0,1) as presenti
                  from componenti_perequative cope,
                       pratiche_tributo prtr
                 where cope.anno = prtr.anno
                   and prtr.pratica = a_prat
               ) cope
          where oggetti.cod_via = archivio_vie.cod_via(+)
            and oggetti.oggetto = ogpr_acc.oggetto
            and cate.tributo = tari.tributo
            and cate.categoria = tari.categoria
            and tari.anno = ogco_acc.anno
            and tari.tributo = ogpr_acc.tributo
            and tari.categoria = ogpr_acc.categoria
            and tari.tipo_tariffa = ogpr_acc.tipo_tariffa
            and cont.cod_fiscale = a_cf
            and tado.anno (+) = a_anno
            and tado.numero_familiari (+) = f_ultimo_faso(cont.ni, a_anno)
            and tand.categoria (+) = nvl(ogpr_acc.categoria,0)
            and tand.tributo (+) = ogpr_acc.tributo
            and tand.anno (+) = a_anno
            and ogim_acc.anno(+) = ogco_acc.anno
            and ogim_acc.cod_fiscale(+) = ogco_acc.cod_fiscale
            and ogim_acc.oggetto_pratica(+) = ogco_acc.oggetto_pratica
            and cotr.tributo = ogpr_acc.tributo
            and cata.anno = a_anno
            and ogco_acc.cod_fiscale = a_cf
            and ogco_acc.oggetto_pratica = ogpr_acc.oggetto_pratica
            and nvl(ogpr_acc.oggetto_pratica_rif_v,ogpr_acc.oggetto_pratica_rif) = ogdic.ogpr(+)
            and ogpr_acc.pratica = prtr_acc.pratica
            and prtr_acc.pratica = a_prat
            and ogpr_acc.oggetto_pratica_rif = dtrl.oggetto_pratica (+)
        ) ogg
  ;
  --
  return rc;
end;
--------------------------------------------------------------
function man_versamenti
( a_cf                                varchar2
, a_pratica                           number
, a_modello                           number
, a_tot_imposta                       varchar2
, a_tot_magg_tares                    varchar2
)
return sys_refcursor
is
  rc sys_refcursor;
begin
  open rc for
    select nvl(to_char(versamenti.rata,99),'  ') rata
         , versamenti.importo_versato
         , stampa_common.f_formatta_numero(versamenti.importo_versato,'I','S') s_importo_versato
         , nvl(to_char(versamenti.data_pagamento,'dd/mm/yyyy'),'          ') data_versamento
         , nvl(versamenti.tipo_versamento,' ') tipo_vers
         , nvl(to_char(decode(versamenti.rata
                           ,0,ruol.scadenza_prima_rata
                           ,1,ruol.scadenza_prima_rata
                           ,2,ruol.scadenza_rata_2
                           ,3,ruol.scadenza_rata_3
                           ,4,ruol.scadenza_rata_4
                           )
                   ,'dd/mm/yyyy'
                   )
        ,'          '
        ) data_scadenza
         , rtrim(f_descrizione_timp(a_modello,'DETT_VERS')) st_dettaglio_versamenti
         , f_descrizione_timp(a_modello,'DIFF_PRT') st_differenza_imposta
         , f_descrizione_timp(a_modello,'TOT_DETT_VERS_PRT') st_totale_dettaglio_versamenti
         , f_descrizione_timp(a_modello,'TOT_IMP_PRT') st_totale_imposta
         , 'TOTALE MAGGIORAZIONE TARES' st_totale_magg_tares
         , f_descrizione_timp(a_modello,'TOT_VERS_RIEP_PRT') st_totale_versamento
         , rtrim(f_descrizione_timp(a_modello,'RIEP_DETT_PRT')) st_riepilogo
         , sum(versamenti.importo_versato) over() tot_versato
               , decode(cata.maggiorazione_tares,
                        null,
                        null,
                        sum(versamenti.maggiorazione_tares) over()) tot_vers_magg_tares
         , to_number(nvl(a_tot_imposta, '0')) tot_imposta
         , decode(cata.maggiorazione_tares,
                  null,
                  null,
                  to_number(nvl(a_tot_magg_tares, '0'))) tot_magg_tares
    from versamenti
       , pratiche_tributo prtr
       , ruoli            ruol
       , carichi_tarsu    cata
    where versamenti.pratica               is null
      and versamenti.oggetto_imposta       is null
      and versamenti.cod_fiscale           = a_cf
      and versamenti.anno                  = prtr.anno
      and cata.anno                        = prtr.anno
      and prtr.pratica                     = a_pratica
      and versamenti.tipo_tributo          = 'TARSU'
      and versamenti.ruolo                 = ruol.ruolo (+)
      -- (VD - 28/01/2022): eliminato test su sanzioni per omessa/infedele denuncia
      --                    Normalmente negli avvisi per omessa/infedele denuncia
      --                    i versamenti non vengono stampati.
      --                    Si è deciso (EA - 27/01/2022) di prevedere comunque un
      --                    riepilogo degli eventuali versamenti spontanei effettuati
      --                    e lasciare al cliente la scelta se stamparli o meno nell'avviso
        /*and not exists (select sapr.cod_sanzione
                          from sanzioni_pratica sapr
                         where sapr.cod_sanzione in (2,3,4,5,6,102,103,104,105,106)
                               -- omesse, infedeli e tardive denunce
                           and sapr.pratica = a_pratica
                       ) */
    order by 1,3;
  return rc;
end;
------------------------------------------------------------------
function man_acc
( a_prat        number default -1
, a_tipo_record varchar2 default ''
, a_modello     number default -1
)
return sys_refcursor
is
  rc sys_refcursor;
begin
  -- (VD - 30/06/2022): su richiesta di Elisabetta, eliminati gli importi
  --                    non formattati
  --                    Per questo motivo sono stati esplicitati i singoli campi
  --                    al posto di "select *"
  open rc for
    select imp_acc.cod_sanzione
         , imp_acc.sanz_ord1
         , imp_acc.sanz_ord
         , imp_acc.ord
         , imp_acc.perc_sanzione
         , imp_acc.perc_riduzione
         , imp_acc.semestri
         , imp_acc.importo_sanzione
         , imp_acc.cod_tributo_f24
         , imp_acc.descr_sanzione
         , imp_acc.st_accertamento_imposta
         --, sum(imp_acc.importo) over() totale
         , stampa_common.f_formatta_numero(sum(imp_acc.importo) over(),'I','S') importo_tot
    from
        (select sanzioni_pratica.cod_sanzione
              ,trunc(sanzioni_pratica.cod_sanzione / 100) sanz_ord1
              ,sanzioni.tipo_causale || nvl (sanzioni.flag_magg_tares, 'N') sanz_ord
              ,1 ord
              ,decode(a_tipo_record
                ,'X', nvl(sanzioni_pratica.importo,0)
                ,sanzioni_pratica.importo
                ) importo
              ,decode(sanzioni_pratica.percentuale
                ,null, ''
                ,stampa_common.f_formatta_numero(sanzioni_pratica.percentuale
                          ,'P','S'
                          )
                ) perc_sanzione
              ,decode(sanzioni_pratica.riduzione
                ,null, ''
                ,stampa_common.f_formatta_numero(sanzioni_pratica.riduzione
                          ,'P','S'
                          )
                ) perc_riduzione
              ,decode(sanzioni_pratica.semestri
                ,null, ''
                ,to_char(sanzioni_pratica.semestri,'99')
                ) semestri
              ,stampa_common.f_formatta_numero
                (decode(a_tipo_record
                     ,'X',nvl(sanzioni_pratica.importo,0)
                     ,sanzioni_pratica.importo
                     )
                ,'I','S'
                ) importo_sanzione
              ,decode(f_descrizione_timp(a_modello,'VIS_COD_TRIB')
                ,'SI',nvl(sanzioni.cod_tributo_f24
                          ,decode(sanzioni.flag_magg_tares
                              ,'S','3955'
                              ,'3944'
                              )
                          )
                ,''
                ) cod_tributo_f24
              ,sanzioni.descrizione descr_sanzione
              ,rtrim(decode(a_tipo_record
                ,'I',f_descrizione_timp(a_modello,'ACC_IMP')
                ,f_descrizione_timp (a_modello, 'ACC_MAGG')
                )
                ) st_accertamento_imposta
         from SANZIONI_PRATICA
            ,SANZIONI
            ,CARICHI_TARSU
            ,PRATICHE_TRIBUTO
            ,(select nvl(max(nvl(cotr.flag_ruolo,'N')),'N') flag_ruolo
              from CODICI_TRIBUTO cotr
                 , OGGETTI_PRATICA ogpr
                 , PRATICHE_TRIBUTO PRTR
              where cotr.tributo = ogpr.tributo
                and ogpr.pratica = prtr.pratica
                AND prtr.pratica_rif = a_prat) ogpr
         where sanzioni_pratica.cod_sanzione = sanzioni.cod_sanzione
           and sanzioni_pratica.sequenza_sanz = sanzioni.sequenza
           and sanzioni_pratica.tipo_tributo = sanzioni.tipo_tributo
           and ( (pratiche_tributo.tipo_tributo = 'TARSU' and
                  sanzioni.tipo_causale = 'E')
             or  (pratiche_tributo.tipo_tributo != 'TARSU' and
                   sanzioni.flag_imposta = 'S'))
           and sanzioni.cod_sanzione not in (888, 889)
           and sanzioni_pratica.pratica = a_prat
           and (a_tipo_record = 'X'
             or (a_tipo_record = 'I' and
                 nvl(sanzioni.flag_magg_tares,'N') = 'N')
             or (a_tipo_record = 'M' and
                 nvl(sanzioni.flag_magg_tares,'N') != 'N'))
           and pratiche_tributo.pratica = a_prat
           and carichi_tarsu.anno(+) = pratiche_tributo.anno
         union
         select sanzioni_pratica.cod_sanzione
              ,trunc(sanzioni_pratica.cod_sanzione / 100) sanz_ord1
              ,sanzioni.tipo_causale || nvl (sanzioni.flag_magg_tares, 'N') sanz_ord
              ,2 ord
              ,decode (a_tipo_record
             ,'X', nvl(sanzioni_pratica.importo,0)
             ,decode(ogpr.flag_ruolo
                           ,'S', decode(sanzioni.tipo_causale||nvl(sanzioni.flag_magg_tares,'N')
                         ,'EN',round(sanzioni_pratica.importo
                                         * nvl(carichi_tarsu.addizionale_eca,0)
                                         / 100
                                   ,2)
                                            + round(sanzioni_pratica.importo
                                                        * nvl(carichi_tarsu.maggiorazione_eca,0)
                                                        / 100
                                   ,2
                                   )
                                            + round(sanzioni_pratica.importo
                                                        * nvl(carichi_tarsu.addizionale_pro,0)
                                                        / 100
                                   ,2
                                   )
                                            + round(sanzioni_pratica.importo
                                                        * nvl(carichi_tarsu.aliquota,0)
                                                        / 100
                                   ,2
                                   )
                         ,0
                         )
                           ,0
                           )
             ) importo
              ,decode(sanzioni_pratica.percentuale
             ,null, ''
             ,stampa_common.f_formatta_numero(sanzioni_pratica.percentuale
                          ,'P','S'
                          )
             ) perc_sanzione
              ,decode(sanzioni_pratica.riduzione
             ,null,''
             ,stampa_common.f_formatta_numero(sanzioni_pratica.riduzione
                          ,'P','S'
                          )
             ) perc_riduzione
              ,decode(sanzioni_pratica.semestri
             ,null,''
             ,to_char(sanzioni_pratica.semestri,'99')
             ) semestri
              ,stampa_common.f_formatta_numero
             (decode(a_tipo_record
                  ,'X',nvl(sanzioni_pratica.importo,0)
                  ,decode(ogpr.flag_ruolo
                         ,'S',decode(sanzioni.tipo_causale || nvl(sanzioni.flag_magg_tares,'N')
                              ,'EN',round(sanzioni_pratica.importo
                                              * nvl (carichi_tarsu.addizionale_eca,0)
                                              / 100
                                        ,2
                                        )
                                         + round(sanzioni_pratica.importo
                                                     * nvl(carichi_tarsu.maggiorazione_eca,0)
                                                     / 100
                                        ,2
                                        )
                                         + round(sanzioni_pratica.importo
                                                     * nvl(carichi_tarsu.addizionale_pro,0)
                                                     / 100
                                        ,2
                                        )
                                         + round(sanzioni_pratica.importo
                                                     * nvl(carichi_tarsu.aliquota,0)
                                                     / 100
                                        ,2
                                        )
                              ,0
                              )
                         )
                  )
             ,'I','S'
             ) importo_sanzione
              ,decode(f_descrizione_timp(a_modello, 'VIS_COD_TRIB')
             ,'SI',nvl(sanzioni.cod_tributo_f24
                          ,decode(sanzioni.flag_magg_tares
                           ,'S','3955'
                           ,'3944'
                           )
                          )
             ,''
             ) cod_tributo_f24
              ,rtrim(f_descrizione_timp(a_modello,'DESCR_ADD')) descr_sanzione
              ,rtrim(decode(a_tipo_record
             ,'I',f_descrizione_timp(a_modello,'ACC_IMP')
             ,f_descrizione_timp(a_modello,'ACC_MAGG')
             )
             ) st_accertamento_imposta
         from SANZIONI_PRATICA
            ,SANZIONI
            ,CARICHI_TARSU
            ,PRATICHE_TRIBUTO
            ,(select nvl (max (nvl (cotr.flag_ruolo, 'N')), 'N') flag_ruolo
              from codici_tributo cotr, oggetti_pratica ogpr, PRATICHE_TRIBUTO PRTR
              where cotr.tributo = ogpr.tributo
                and ogpr.pratica = prtr.pratica
                and prtr.pratica_rif = a_prat) ogpr
         where sanzioni_pratica.cod_sanzione = sanzioni.cod_sanzione
           and sanzioni_pratica.sequenza_sanz = sanzioni.sequenza
           and sanzioni_pratica.tipo_tributo = sanzioni.tipo_tributo
           and ( (pratiche_tributo.tipo_tributo = 'TARSU' and
                  sanzioni.tipo_causale = 'E')
             or (pratiche_tributo.tipo_tributo != 'TARSU' and
                   sanzioni.flag_imposta = 'S'))
           and (sanzioni.cod_sanzione not in (888, 889))
           and (sanzioni_pratica.pratica = a_prat)
           and ((a_tipo_record = 'X') or
                (a_tipo_record = 'I' and nvl(sanzioni.flag_magg_tares,'N') = 'N') or
                (a_tipo_record = 'M' and nvl(sanzioni.flag_magg_tares,'N') != 'N')
               )
           and pratiche_tributo.pratica = a_prat
           and carichi_tarsu.anno(+) = pratiche_tributo.anno
           and decode(ogpr.flag_ruolo
             ,'S',decode(sanzioni.tipo_causale || nvl(sanzioni.flag_magg_tares,'N')
                          ,'EN',round(sanzioni_pratica.importo
                                          * nvl(carichi_tarsu.addizionale_eca,0)
                                          / 100
                                    ,2
                                    )
                             + round(sanzioni_pratica.importo
                                         * nvl(carichi_tarsu.maggiorazione_eca,0)
                                         / 100
                                    ,2
                                    )
                             + round(sanzioni_pratica.importo
                                         * nvl(carichi_tarsu.addizionale_pro,0)
                                         / 100
                                    ,2
                                    )
                             + round(sanzioni_pratica.importo
                                         * nvl(carichi_tarsu.aliquota,0)
                                         / 100
                                    ,2
                                    )
                          ,0
                          )
             ,0
             ) != 0
         order by 3, 1, 4) imp_acc;
         return rc;
end;
------------------------------------------------------------------
function man_acc_imposta
( a_prat number default -1
, a_modello number default -1
)
return sys_refcursor
is
  w_tipo_record    varchar2(1);
begin
  if f_contolla_cope(a_prat) > 0 then
    w_tipo_record := 'X';   -- Nel caso di annualità con Componenti Perequative prende Imposta normale + TARES
  else
    w_tipo_record := 'I';
  end if;
  return man_acc(a_prat, w_tipo_record, a_modello);
end;
------------------------------------------------------------------
function man_acc_magg
( a_prat number default -1
, a_modello number default -1
)
return sys_refcursor
is
begin
  return man_acc(a_prat, 'M', a_modello);
end;
------------------------------------------------------------------
function man_sanz
( a_prat        number default -1
, a_tipo_record varchar2 default ''
, a_modello     number default -1
)
return sys_refcursor
is
  rc sys_refcursor;
begin
  -- (VD - 30/06/2022): su richiesta di Elisabetta, eliminati gli importi
  --                    non formattati
  --                    Per questo motivo sono stati esplicitati i singoli campi
  --                    al posto di "select *"
  open rc for
    select imp_sanz.cod_sanzione
         , imp_sanz.perc_sanzione
         , imp_sanz.perc_riduzione
         , imp_sanz.giorni_semestri
         , imp_sanz.importo_sanzione
         , imp_sanz.cod_tributo_f24
         , imp_sanz.descrizione
         , imp_sanz.st_irrogazioni_sanz
         , imp_sanz.st_irrogazioni_sanz_int_magg
         , stampa_common.f_formatta_numero(imp_sanz.totale
        ,'I','S'
        ) importo_tot
    from
        (select sanzioni_pratica.cod_sanzione
              , nvl(sanzioni_pratica.importo,0) importo
              , decode(sanzioni_pratica.percentuale
                ,null,''
                ,stampa_common.f_formatta_numero(sanzioni_pratica.percentuale
                           ,'P','S'
                           )
                ) perc_sanzione
              , decode(sanzioni_pratica.riduzione
                ,null,''
                ,stampa_common.f_formatta_numero(sanzioni_pratica.riduzione
                           ,'P','S'
                           )
                ) perc_riduzione
              , decode(nvl(sanzioni_pratica.giorni,sanzioni_pratica.semestri)
                ,null,''
                ,to_char(nvl(sanzioni_pratica.giorni,sanzioni_pratica.semestri)
                           ,'9999'
                           )
                ) giorni_semestri
              , stampa_common.f_formatta_numero(sanzioni_pratica.importo
                ,'I','S'
                ) importo_sanzione
              , decode(sanzioni.tipo_tributo
                ,'TARSU',decode(f_descrizione_timp(a_modello,'VIS_COD_TRIB')
                           ,'SI',nvl(sanzioni.cod_tributo_f24
                                    ,decode(sanzioni.flag_magg_tares
                                         ,'S','3955'
                                         ,'3944'
                                         )
                                    )
                           ,''
                           )
                ,''
                ) cod_tributo_f24
              , sanzioni.descrizione descrizione
              , rtrim(f_descrizione_timp(a_modello,'IRR_SANZ_INT')) st_irrogazioni_sanz
              , decode(sanzioni.tipo_tributo
                ,'TARSU',rtrim(f_descrizione_timp(a_modello,'IRR_SANZ_INT_MAGG'))
                ,''
                ) st_irrogazioni_sanz_int_magg
              , SUM(importo) over() totale
         from sanzioni_pratica
            , sanzioni
         where sanzioni_pratica.cod_sanzione = sanzioni.cod_sanzione
           and sanzioni_pratica.sequenza_sanz = sanzioni.sequenza
           and sanzioni_pratica.tipo_tributo = sanzioni.tipo_tributo
           and sanzioni_pratica.cod_sanzione not in (888, 889, 891, 892, 893, 894)
           and ( (sanzioni.tipo_tributo = 'TARSU' and sanzioni.tipo_causale != 'E')
             or (sanzioni.tipo_tributo != 'TARSU' and nvl(sanzioni.flag_imposta,'N') != 'S'))
           and sanzioni_pratica.pratica = a_prat
           and ((a_tipo_record = 'X') or
                (a_tipo_record = 'I' and nvl (sanzioni.flag_magg_tares, 'N') = 'N') or
                (a_tipo_record = 'M' and nvl (sanzioni.flag_magg_tares, 'N') != 'N')
               )
         order by 1) imp_sanz;
  return rc;
end;
------------------------------------------------------------------
function man_sanz_int
( a_prat number default -1
, a_modello number default -1
)
return sys_refcursor
is
  w_tipo_record    varchar2(1);
begin
  if f_contolla_cope(a_prat) > 0 then
    w_tipo_record := 'X';   -- Nel caso di annualità con Componenti Perequative prende Imposta normale + TARES
  else
    w_tipo_record := 'I';
  end if;
  return man_sanz(a_prat, w_tipo_record, a_modello);
end;
------------------------------------------------------------------
function man_sanz_magg
( a_prat number default -1
, a_modello number default -1
)
return sys_refcursor
is
begin
  return man_sanz(a_prat, 'M', a_modello);
end;
------------------------------------------------------------------
function man_riep_vers
( a_prat number
, a_modello number
)
return sys_refcursor
is
begin
  return riep_vers(a_prat, a_modello);
end;
------------------------------------------------------------------
function aggi_dilazioni
( a_pratica                                   number default -1
, a_modello                                   number default -1
)
return sys_refcursor
is
  rc         sys_refcursor;
begin
  open rc for
    select stampa_common.f_formatta_numero(prtr.importo_totale,'I','S') st_importo_totale
         , stampa_common.f_formatta_numero(prtr.importo_ridotto,'I','S') st_importo_ridotto
         , stampa_common.f_formatta_numero(aggi_60.aliquota,'P','S') st_aliquota_60
         , stampa_common.f_formatta_numero(least(round(prtr.importo_totale * aggi_60.aliquota / 100,2)
                                                ,aggi_60.importo_massimo),'I','S') st_aggio_60
         , stampa_common.f_formatta_numero(prtr.importo_totale +
                                          (least(round(prtr.importo_totale * aggi_60.aliquota / 100,2)
                                                ,aggi_60.importo_massimo))
                                          ,'I','S'
                                          ) st_importo_da_versare_60
         , stampa_common.f_formatta_numero(aggi_120.aliquota,'P','S') st_aliquota_120
         , stampa_common.f_formatta_numero(least(round(prtr.importo_totale * aggi_120.aliquota / 100,2)
                                                ,aggi_120.importo_massimo),'I','S') st_aggio_120
         , stampa_common.f_formatta_numero(prtr.importo_totale +
                                          (least(round(prtr.importo_totale * aggi_120.aliquota / 100,2)
                                                ,aggi_120.importo_massimo))
                                          ,'I','S'
                                          ) st_importo_da_versare_120
         , stampa_common.f_formatta_numero(inte.aliquota,'P','S') st_aliquota_interessi
         , round(prtr.imposta_totale * inte.aliquota / 36500,6) st_interesse_giornaliero
         , (select stampa_common.f_formatta_numero(sum(sapr.importo),'I') importo
              from sanzioni_pratica sapr, sanzioni sanz
             where sapr.pratica = a_pratica
               and sapr.tipo_tributo = sanz.tipo_tributo
               and sapr.cod_sanzione = sanz.cod_sanzione
               and sapr.sequenza_sanz = sanz.sequenza
               and sanz.flag_imposta = 'S'
               and nvl(sanz.tipo_causale, 'X') = 'E') st_differenza_imposta
      from pratiche_tributo prtr
         , aggi aggi_60
         , aggi aggi_120
         , interessi inte
     where prtr.pratica = a_pratica
       and prtr.tipo_tributo = aggi_60.tipo_tributo
       and aggi_60.aliquota > 0
       and aggi_60.giorno_inizio < 90
       and prtr.tipo_tributo = aggi_120.tipo_tributo
       and aggi_120.aliquota > 0
       and aggi_120.giorno_inizio > 90
       and inte.tipo_tributo = prtr.tipo_tributo
       and inte.tipo_interesse = 'D'
       and prtr.data between inte.data_inizio
                         and inte.data_fine
    ;
  return rc;
end;
------------------------------------------------------------------
function interessi_dettaglio
( a_pratica               number default -1
, a_modello               number default -1
)
return sys_refcursor
/******************************************************************************
  NOME:        INTERESSI_DETTAGLIO
  DESCRIZIONE: Restituisce un ref_cursor contenente il dettaglio degli interessi
  RITORNA:     ref_cursor.
  Rev.  Data        Autore  Descrizione
  ----  ----------  ------  ----------------------------------------------------
  000   14/06/2024  RV      #55525
                            Versione iniziale
******************************************************************************/
is
  rc sys_refcursor;
begin
  rc := stampa_common.interessi(a_pratica);
  return rc;
end;
------------------------------------------------------------------
function eredi
( a_ni_deceduto           number default -1
, a_ni_erede_da_escludere number default -1
)
return sys_refcursor
is
  rc         sys_refcursor;
begin
  rc := stampa_common.eredi(a_ni_deceduto,a_ni_erede_da_escludere);
  return rc;
end;

end stampa_accertamenti_tarsu;
/
