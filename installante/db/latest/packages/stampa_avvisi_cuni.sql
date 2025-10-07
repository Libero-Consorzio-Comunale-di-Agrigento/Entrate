--liquibase formatted sql 
--changeset abrandolini:20250326_152429_stampa_avvisi_cuni stripComments:false runOnChange:true 
 
create or replace package STAMPA_AVVISI_CUNI is
/**
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 001   19/03/2021  RV      Prima emissione, basato su medesima package STAMPA_AVVISI_TARI  (VD)
 002   15/04/2021  RV      Rivisto le select per nuovi valori e con nuovo formato
 003   21/04/2021  RV      Prima release "Ufficiale" x Bellumo
 004   30/04/2021  RV      Modificato dati_rate e lista_canoni per dati Anno Precedente
 005   18/05/2021  RV      Modificata gesionte flag_ruolo per a_pratica_base <> -1
 006   20/05/2021  RV      Aggiunto vari formati in f_formatta_numero
 007   25/06/2021  RV      Rivisto query ELENCO_CANONI come da indicazionidi Valeria
 008   13/07/2021  RV      Rivisto ELENCO_CANONI ed DATI_CANINI per riferimenti multipli Pratica: Oggetto Pratica
 009   23/07/2021  RV      Rivisto Riduzione/Maggiorazione tariffa per Pioltello
 010   31/01/2022  RV      Recepimento variazione campi riga_destinatario_x come da modifica in STAMPA_COMMON (VD del 28/01/2022)
 011   25/02/2022  RV      Aggiunto campi di dettaglio canone come da issue 54189
 012   04/04/2022  RV      Normalizzato filtri obsoleti per includere dati residui ICP e TOSAP come da issue 56193
 013   02/05/2022  VD      Funzioni elenco_canoni e dati_canoni: modificata selezione tariffe per anno, ora si usa
                           l'anno passato come parametro e non l'anno di oggetti_pratica (che e' l'anno della denuncia)
 014   24/10/2022  DM      Recapito indirizzo stampato in maiuscolo issue #58092.
 015   07/02/2023  RV      #58042
                           Rivisto per totali mancanti su contribuenti_ente
                           CUNI usa un aversione specifica di contribuenti_ente con dati aggiuntivi,
                           non quella di STAMPA_COMMON
 016   27/04/2023  RV      #63851
                           Sistemato tag OCCUPAZIONE_TARIFFA in ELENCO_CANONI e DATI_CANONI
 017   11/01/2024  RV      #54732
                           Aggiunta gestione GruppoTributo
 018   29/02/2024  RV      #54733
                           Completata gestione flag_no_depag per Categoria e Tariffe
 019   29/03/2024  RV      #71295
                           Aggiunto dati occupazione ad estrazione canoni
**/

  -- Dati di base del contribuente (solo per C.F.)
  function contribuente(a_ni                number default -1,
                        a_tipo_tributo      varchar2 default '',
                        a_cod_fiscale       varchar2 default '',
                        a_ruolo             number default -1,
                        a_modello           number default -1,
                        a_anno              number default -1,
                        a_pratica_base      number default -1,
                        a_gruppo_tributo    varchar2 default null)
  return sys_refcursor;

  -- Dati di base del contribuente e dell'ente
  function contribuenti_ente(a_ni                  number    default -1,
                             a_tipo_tributo        varchar2  default '',
                             a_cod_fiscale         varchar2  default '',
                             a_ruolo               number    default -1,
                             a_modello             number    default -1,
                             a_anno                number    default -1,
                             a_pratica_base        number    default -1,
                             a_gruppo_tributo      varchar2  default null)
  return sys_refcursor;

  -- Lista dei canoni
  function lista_canoni(a_ruolo                    number     default -1,
                       a_cod_fiscale               varchar2   default '',
                       a_modello                   number     default -1,
                       a_tipo_tributo              varchar2   default '',
                       a_anno                      number     default -1,
                       a_pratica_base              number     default -1,
                       a_gruppo_tributo            varchar2   default null,
                       a_flag_no_depag             varchar2   default null)
  return sys_refcursor;

  -- Elenco dei canoni come da Pratiche
  function elenco_canoni(a_ruolo                   number     default -1,
                       a_cod_fiscale               varchar2   default '',
                       a_modello                   number     default -1,
                       a_tipo_tributo              varchar2   default '',
                       a_anno                      number     default -1,
                       a_pratica_base              number     default -1,
                       a_oggetto_base              number     default -1,
                       a_gruppo_tributo            varchar2   default null,
                       a_flag_no_depag             varchar2   default null)
  return sys_refcursor;

  -- Dati dei canoni come da Imposte
  function dati_canoni(a_ruolo                     number     default -1,
                       a_cod_fiscale               varchar2   default '',
                       a_modello                   number     default -1,
                       a_tipo_tributo              varchar2   default '',
                       a_anno                      number     default -1,
                       a_pratica_base              number     default -1,
                       a_oggetto_base              number     default -1,
                       a_gruppo_tributo            varchar2   default null,
                       a_flag_no_depag             varchar2   default null)
  return sys_refcursor;

  -- Dati delle rate
  function dati_rate(  a_ruolo                     number     default -1,
                       a_cod_fiscale               varchar2   default '',
                       a_modello                   number     default -1,
                       a_tipo_tributo              varchar2   default '',
                       a_anno                      number     default -1,
                       a_pratica_base              number     default -1,
                       a_gruppo_tributo            varchar2   default null,
                       a_flag_no_depag             varchar2   default null)
  return sys_refcursor;

  -- Dati del versato
  function dati_versato(a_cod_fiscale               varchar2   default '',
                        a_tipo_tributo              varchar2   default '',
                        a_anno                      number     default -1,
                        a_pratica_base              number     default -1,
                        a_gruppo_tributo            varchar2   default null)
  return sys_refcursor;

  -- Riporta elenco pratiche partendo da pratica base
  function pratiche_canoni(a_pratica_base number default -1)
  return sys_refcursor;

  -- Formattazione numeri (Presa e personalizzata da STAMPE_COMMON)
  function f_formatta_numero(a_numero    number,
                           a_formato   varchar2,
                           a_null_zero varchar2 default null)
  return varchar2;

end STAMPA_AVVISI_CUNI;
/
create or replace package body STAMPA_AVVISI_CUNI is
/**
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 001   19/03/2021  RV      Prima emissione, basato su medesima package STAMPA_AVVISI_TARI  (VD)
 002   15/04/2021  RV      Rivisto le select per nuovi valori e con nuovo formato
 003   21/04/2021  RV      Prima release "Ufficiale" x Bellumo
 004   30/04/2021  RV      Modificato dati_rate e lista_canoni per dati Anno Precedente
 005   18/05/2021  RV      Modificata gesionte flag_ruolo per a_pratica_base <> -1
 006   20/05/2021  RV      Aggiunto vari formati in f_formatta_numero
 007   25/06/2021  RV      Rivisto query ELENCO_CANONI come da indicazionidi Valeria
 008   13/07/2021  RV      Rivisto ELENCO_CANONI ed DATI_CANINI per riferimenti multipli Pratica: Oggetto Pratica
 009   23/07/2021  RV      Rivisto Riduzione/Maggiorazione tariffa per Pioltello
 010   31/01/2022  RV      Recepimento variazione campi riga_destinatario_x come da modifica in STAMPA_COMMON (VD del 28/01/2022)
 011   25/02/2022  RV      Aggiunto campi di dettaglio canone come da issue 54189
 012   04/04/2022  RV      Normalizzato filtri obsoleti per includere dati residui ICP e TOSAP come da issue 56193
 013   02/05/2022  VD      Funzioni elenco_canoni e dati_canoni: modificata selezione tariffe per anno, ora si usa
                           l'anno passato come parametro e non l'anno di oggetti_pratica (che e' l'anno della denuncia)
 014   24/10/2022  DM      Recapito indirizzo stampato in maiuscolo issue #58092.
 015   07/02/2023  RV      #58042
                           Rivisto per totali mancanti su contribuenti_ente
                           CUNI usa un aversione specifica di contribuenti_ente con dati aggiuntivi,
                           non quella di STAMPA_COMMON
 016   27/04/2023  RV      #63851
                           Sistemato tag OCCUPAZIONE_TARIFFA in ELENCO_CANONI e DATI_CANONI
 017   11/01/2024  RV      #54732
                           Aggiunta gestione GruppoTributo
 018   29/02/2024  RV      #54733
                           Completata gestione flag_no_depag per Categoria e Tariffe
 019   29/03/2024  RV      #71295
                           Aggiunto dati occupazione ad estrazione canoni
**/

  -- Function and procedure implementations

  function contribuente(a_ni                number default -1,
                        a_tipo_tributo      varchar2 default '',
                        a_cod_fiscale       varchar2 default '',
                        a_ruolo             number default -1,
                        a_modello           number default -1,
                        a_anno              number default -1,
                        a_pratica_base      number default -1,
                        a_gruppo_tributo    varchar2 default null)
    return sys_refcursor is
    rc                          sys_refcursor;
  begin
    rc := contribuenti_ente(a_ni,a_tipo_tributo,a_cod_fiscale,a_ruolo,a_modello,a_anno,a_pratica_base,a_gruppo_tributo);
    return rc;
  end contribuente;

  ---
  --- Versione personaliozzata di stampa_common.contribuenti_ente
  ---
  function contribuenti_ente(a_ni                  number default -1,
                             a_tipo_tributo        varchar2 default '',
                             a_cod_fiscale         varchar2 default '',
                             a_ruolo               number default -1,
                             a_modello             number default -1,
                             a_anno                number default -1,
                             a_pratica_base        number default -1,
                             a_gruppo_tributo      varchar2 default null)
    return sys_refcursor is
    w_ni                     number;
    rc                       sys_refcursor;
    w_descr_ord              modelli.descrizione_ord%TYPE;
    --
    v_rc                     sys_refcursor;
    --
    type t_dati_canoni is record
    ( descr_utenza            varchar2(100),
      descr_codice            varchar2(20),
      descr_tariffa           varchar2(200),
      descr_tariffa_magg      varchar2(200),
      importo_tariffa         varchar2(100),
      periodo_tariffa         varchar2(20),
      occupazione_tariffa     varchar2(100),
      dati_categoria          varchar2(100),
      indirizzo_utenza        varchar2(1000),
      localita_utenza         varchar2(60),
      comune_utenza           varchar2(60),
      provincia_utenza        varchar2(60),
      sigla_pro_utenza        varchar2(10),
      dati_tariffa            varchar2(100),
      periodo_imposta         varchar2(100),
      estremi_catastali       varchar2(60),
      categoria_catasto       varchar2(10),
      superficie              varchar2(20),
      descr_perc_poss         varchar2(200),
      base_tariffa            varchar2(20),
      coeff_tariffa           varchar2(20),
      riduz_tariffa           varchar2(20),
      magg_tariffa            varchar2(20),
      descr_perc_detr         varchar2(200),
      descr_perc_magg         varchar2(200),
      note_tariffa            varchar2(2000),
      periodo_ruolo           varchar2(100),
      imposta                 varchar2(20),
      residuo_lordo           varchar2(20),
      imposta_netta           varchar2(20),
      imposta_lorda           varchar2(20),
      imposta_netta_annua     varchar2(20),
      imposta_netta_acconto   varchar2(20),
      oggetto_pratica         number(10),
      oggetto_imposta         number(10),
      oggetto                 number(10),
      flag_domestica          varchar2(10),
      flag_depag              varchar2(10),
      flag_altro              varchar2(10),
      inizio_occ              varchar2(12),
      fine_occ                varchar2(12),
      inizio_conc             varchar2(12),
      fine_conc               varchar2(12),
      conc_numero             varchar2(20),
      conc_data               varchar2(12),
      dett_conc               varchar2(200),
      larghezza               number(7,2),
      profondita              number(7,2),
      mq_reali                number(8,2),
      quantita                number(6,0),
      mq                      number(8,2),
      dett_cons               varchar2(200),
      stringa_familiari       varchar2(200),
      gruppo_tributo          varchar2(10),
      gruppo_tributo_descr    varchar2(100),
      modello                 number,
      tot_imposta_netta_num   number(10,2),
      tot_imposta_lorda_num   number(10,2),
      tot_imposta_arr_num     number(10,2),
      tot_imposta_netta       varchar2(20),
      tot_imposta_lorda       varchar2(20),
      tot_imposta_arr         varchar2(20)
    );
    v_dati_canoni t_dati_canoni;
    --
    type t_dati_versato is record
    ( anno_versamento         number(4),
      rata                    varchar2(10),
      importo_versato_num     number(10,2),
      tot_importo_versato_num number(10,2),
      importo_versato         varchar2(20),
      tot_importo_versato     varchar2(20),
      gruppo_tributo          varchar2(10),
      gruppo_tributo_descr    varchar2(100)
    );
    v_dati_versato t_dati_versato;
    --
    v_tot_importo_versato_num  number(10,2);
    v_tot_imposta_lorda_num    number(10,2);
    v_tot_imposta_arr_num      number(10,2);
    v_tot_importo_versato      varchar2(20);
    v_tot_imposta_netta        varchar2(20);
    v_tot_imposta_lorda        varchar2(20);
    v_tot_imposta_arr          varchar2(20);
    --
  begin
    -- se si passa come parametro il codice fiscale invece dell'ni
    -- si determina l'ni dalla tabella contribuenti
    if nvl(a_ni,-1) = -1 and a_cod_fiscale is not null then
       begin
         select ni
           into w_ni
           from contribuenti
          where cod_fiscale = a_cod_fiscale;
       exception
         when others then
           w_ni := -1;
       end;
    else
       w_ni := a_ni;
    end if;
    begin
      select modelli.descrizione_ord
        into w_descr_ord
        from modelli
       where modello = a_modello;
    exception
      when NO_DATA_FOUND then
        w_descr_ord := '';
    end;
    --
    v_tot_importo_versato_num := 0;
    v_tot_importo_versato := '0.00';
    v_rc := dati_versato(a_cod_fiscale, a_tipo_tributo, a_anno, a_pratica_base, a_gruppo_tributo);
    loop
      fetch v_rc
        into v_dati_versato;
      exit when v_rc%notfound;
      v_tot_importo_versato_num := v_dati_versato.tot_importo_versato_num;
      v_tot_importo_versato := v_dati_versato.tot_importo_versato;
      exit;
    end loop;
    --
    v_tot_imposta_lorda_num := 0;
    v_tot_imposta_arr_num := 0;
    v_tot_imposta_netta := '0.00';
    v_tot_imposta_lorda := '0.00';
    v_tot_imposta_arr := '0.00';
    v_rc := dati_canoni(a_ruolo, a_cod_fiscale, a_modello, a_tipo_tributo, a_anno, a_pratica_base, -1, a_gruppo_tributo);
    loop
      fetch v_rc
        into v_dati_canoni;
      exit when v_rc%notfound;
      v_tot_imposta_lorda_num := v_dati_canoni.tot_imposta_lorda_num;
      v_tot_imposta_arr_num := v_dati_canoni.tot_imposta_arr_num;
      v_tot_imposta_netta := v_dati_canoni.tot_imposta_netta;
      v_tot_imposta_lorda := v_dati_canoni.tot_imposta_lorda;
      v_tot_imposta_arr := v_dati_canoni.tot_imposta_arr;
      exit;
    end loop;
    --
    if a_ruolo = -1 then -- Utilizzato per lettera generica
       open rc for
         select coen.comune_ente,
                coen.sigla_ente,
                coen.provincia_ente,
                coen.cognome_nome,
                coen.ni,
                coen.cod_sesso,
                coen.sesso,
                coen.cod_contribuente,
                coen.cod_controllo,
                coen.cod_fiscale,
                coen.presso,
                upper(coen.indirizzo) indirizzo,
                coen.comune,
                coen.comune_provincia,
                coen.cap,
                coen.telefono,
                to_char(coen.data_nascita, 'DD/MM/YYYY') data_nascita,
                coen.comune_nascita,
                coen.label_rap,
                coen.rappresentante,
                coen.cod_fiscale_rap,
                coen.indirizzo_rap,
                coen.comune_rap,
                coen.data_odierna,
                coen.tipo_tributo,
                coen.erede_di,
                coen.cognome_nome_erede,
                coen.cod_fiscale_erede,
                coen.indirizzo_erede,
                coen.comune_erede,
                coen.partita_iva,
                upper(coen.via_dest) via_dest,
                coen.num_civ_dest,
                decode(coen.suffisso_dest,'','','/'||suffisso_dest) suffisso_dest,
                coen.scala_dest,
                coen.piano_dest,
                coen.interno_dest,
                coen.cap_dest,
                upper(coen.comune_dest) comune_dest,
                coen.provincia_dest,
                decode(f_recapito(coen.ni,
                                  coen.tipo_tributo,
                                  3,
                                  trunc(sysdate)
                                  ),
                       null,null,'PEC ') label_indirizzo_pec,
                f_recapito(coen.ni,
                           coen.tipo_tributo,
                           3,
                           trunc(sysdate)
                          ) indirizzo_pec,
                decode(f_recapito(coen.ni,
                                  coen.tipo_tributo,
                                 2,
                                 trunc(sysdate)
                                 ),
                      null,null,'E-mail ') label_indirizzo_email,
               f_recapito(coen.ni,
                          coen.tipo_tributo,
                          2,
                          trunc(sysdate)
                         ) indirizzo_email,
               decode(f_recapito(coen.ni,
                                 coen.tipo_tributo,
                                 4,
                                 trunc(sysdate)
                                 ),
                      null,null,'Nr. Tel. ') label_telefono_fisso,
               f_recapito(coen.ni,
                          coen.tipo_tributo,
                          4,
                          trunc(sysdate)
                         ) telefono,
               decode(f_recapito(coen.ni,
                                 coen.tipo_tributo,
                                 6,
                                 trunc(sysdate)
                                 ),
                      null,null,'Cell. ') label_cell_personale,
               f_recapito(coen.ni,
                          coen.tipo_tributo,
                          6,
                          trunc(sysdate)
                         ) cell_personale,
               decode(f_recapito(coen.ni,
                                 coen.tipo_tributo,
                                 7,
                                 trunc(sysdate)
                                 ),
                      null,null,'Cell. Ufficio ') label_cell_lavoro,
               f_recapito(coen.ni,
                          coen.tipo_tributo,
                          7,
                          trunc(sysdate)
                         ) cell_lavoro,
                decode(coen.tipo_residente||coen.tipo,
                    -- (VD - 28/01/2022): Non si indica più il legale rappresentante
                       11,coen.cognome_nome, --decode(coen.label_rap,'',coen.cognome_nome,coen.rappresentante),
                          decode(coen.erede_di,
                                '',decode(coen.stato,50,'Eredi di ','')||coen.cognome_nome,
                                coen.cognome_nome_erede)
                      ) riga_destinatario_1,
                decode(coen.tipo_residente||coen.tipo,
                    -- (VD - 28/01/2022): Non si indica più il legale rappresentante
                       11,coen.presso, --decode(coen.label_rap,'',coen.presso,coen.descr_carica||' '||coen.cognome_nome),
                          decode(coen.erede_di,
                                 '',coen.presso,
                                    coen.erede_di||' '||coen.cognome_nome||
                                    decode(coen.presso_erede,'','',' '||coen.presso_erede)
                                )
                      ) riga_destinatario_2,
                ltrim(decode(coen.scala_dest,'','','Scala '||coen.scala_dest)||
                      decode(coen.piano_dest,'','',' Piano '||coen.piano_dest)||
                      decode(coen.interno_dest,'','',' Int. '||coen.interno_dest)
                     ) riga_destinatario_3,
                coen.via_dest||' '||coen.num_civ_dest||
                decode(coen.suffisso_dest,'','','/'||coen.suffisso_dest) riga_destinatario_4,
                coen.cap_dest||' '||coen.comune_dest||' '||coen.provincia_dest riga_destinatario_5,
                f_descrizione_titr(coen.tipo_tributo,to_number(to_char(sysdate,'yyyy'))) descr_titr,
                a_ruolo ruolo,
                a_modello modello,
                a_anno anno_imposta,
                a_pratica_base pratica_base,
                a_gruppo_tributo gruppo_tributo,
                to_char(CURRENT_DATE, 'dd/mm/yyyy') data_odierna,
                to_char(scad.r0, 'dd/mm/yyyy') scadenza_rata_unica,
                to_char(decode(rsca.r1,null,scad.r1,rsca.r1), 'dd/mm/yyyy') scadenza_prima_rata,
                to_char(decode(rsca.r1,null,scad.r2,rsca.r2), 'dd/mm/yyyy') scadenza_rata_2,
                to_char(decode(rsca.r1,null,scad.r3,rsca.r3), 'dd/mm/yyyy') scadenza_rata_3,
                to_char(decode(rsca.r1,null,scad.r4,rsca.r4), 'dd/mm/yyyy') scadenza_rata_4,
                to_char(decode(rsca.r1,null,scad.r5,rsca.r5), 'dd/mm/yyyy') scadenza_rata_5,
                v_tot_importo_versato as importo_versato_tot,
                v_tot_imposta_netta as imposta_netta_tot,
                v_tot_imposta_lorda as imposta_lorda_tot,
                v_tot_imposta_arr as imposta_arrorondata_tot,
                f_formatta_numero(v_tot_imposta_lorda_num - v_tot_importo_versato_num,'I','S') differenza_lorda_tot,
                f_formatta_numero(v_tot_imposta_arr_num - v_tot_importo_versato_num,'I','S') differenza_imposta_tot
          from contribuenti_ente coen,
                (select
                  w_ni as ni,
                  max((case when scad.rata = 0 then scad.data_scadenza else null end)) as R0,
                  max((case when scad.rata = 1 then scad.data_scadenza else null end)) as R1,
                  max((case when scad.rata = 2 then scad.data_scadenza else null end)) as R2,
                  max((case when scad.rata = 3 then scad.data_scadenza else null end)) as R3,
                  max((case when scad.rata = 4 then scad.data_scadenza else null end)) as R4,
                  max((case when scad.rata = 5 then scad.data_scadenza else null end)) as R5
                from
                  scadenze scad
                where scad.anno = a_anno
                  and scad.tipo_scadenza = 'V'
                  and scad.tipo_tributo = a_tipo_tributo
                  and (((a_gruppo_tributo is null) and (scad.gruppo_tributo is null)) or
                       ((a_gruppo_tributo is not null) and (scad.gruppo_tributo = a_gruppo_tributo)))
                group by
                  tipo_scadenza, tipo_tributo, gruppo_tributo, anno
                ) scad,
              (select
                w_ni as ni,
                max((case when risc.rata = 1 then risc.data_scadenza else null end)) as R1,
                max((case when risc.rata = 2 then risc.data_scadenza else null end)) as R2,
                max((case when risc.rata = 3 then risc.data_scadenza else null end)) as R3,
                max((case when risc.rata = 4 then risc.data_scadenza else null end)) as R4,
                max((case when risc.rata = 5 then risc.data_scadenza else null end)) as R5
              from
                (select
                  raim.rata,
                  raim.data_scadenza
                from
                  rate_imposta raim
                where raim.anno = a_anno
                  and raim.tipo_tributo = a_tipo_tributo
                  and raim.cod_fiscale = a_cod_fiscale
                  and nvl(raim.conto_corrente,99990000) in (
                         select distinct nvl(cotr.conto_corrente,99990000) conto_corrente
                         from codici_tributo cotr
                         where cotr.flag_ruolo is null
                           and ((a_gruppo_tributo is null) or
                               ((a_gruppo_tributo is not null) and (cotr.gruppo_tributo = a_gruppo_tributo))
                           )
                      )
                group by
                  raim.rata,raim.data_scadenza
                  ) risc
                ) rsca
         where coen.ni = w_ni
           and coen.tipo_tributo = a_tipo_tributo
           and coen.ni = scad.ni (+)
           and coen.ni = rsca.ni (+);
    else
       open rc for
         select coen.comune_ente,
                coen.sigla_ente,
                coen.provincia_ente,
                coen.cognome_nome,
                coen.ni,
                coen.cod_sesso,
                coen.sesso,
                coen.cod_contribuente,
                coen.cod_controllo,
                coen.cod_fiscale,
                coen.presso,
                upper(coen.indirizzo),
                coen.comune,
                coen.comune_provincia,
                coen.cap,
                coen.telefono,
                to_char(coen.data_nascita, 'DD/MM/YYYY') data_nascita,
                coen.comune_nascita,
                coen.label_rap,
                coen.rappresentante,
                coen.cod_fiscale_rap,
                coen.indirizzo_rap,
                coen.comune_rap,
                coen.descr_carica carica_rap,
                coen.data_odierna,
                coen.tipo_tributo,
                coen.erede_di,
                coen.cognome_nome_erede,
                coen.cod_fiscale_erede,
                coen.indirizzo_erede,
                coen.comune_erede,
                coen.partita_iva,
                upper(coen.via_dest) via_dest,
                coen.num_civ_dest,
                decode(coen.suffisso_dest,'','','/'||suffisso_dest) suffisso_dest,
                coen.scala_dest,
                coen.piano_dest,
                coen.interno_dest,
                coen.cap_dest,
                upper(coen.comune_dest) comune_dest,
                coen.provincia_dest,
                decode(f_recapito(coen.ni,
                                  coen.tipo_tributo,
                                  3,
                                  trunc(sysdate)
                                  ),
                       null,null,'PEC ') label_indirizzo_pec,
                f_recapito(coen.ni,
                           coen.tipo_tributo,
                           3,
                           trunc(sysdate)
                          ) indirizzo_pec,
                decode(f_recapito(coen.ni,
                                  coen.tipo_tributo,
                                  2,
                                  trunc(sysdate)
                                  ),
                       null,null,'E-mail ') label_indirizzo_email,
                f_recapito(coen.ni,
                           coen.tipo_tributo,
                           2,
                           trunc(sysdate)
                          ) indirizzo_email,
                decode(f_recapito(coen.ni,
                                  coen.tipo_tributo,
                                  4,
                                  trunc(sysdate)
                                  ),
                       null,null,'Nr. Tel. ') label_telefono_fisso,
                f_recapito(coen.ni,
                           coen.tipo_tributo,
                           4,
                           trunc(sysdate)
                          ) telefono,
                decode(f_recapito(coen.ni,
                                  coen.tipo_tributo,
                                  6,
                                  trunc(sysdate)
                                  ),
                       null,null,'Cell. ') label_cell_personale,
                f_recapito(coen.ni,
                           coen.tipo_tributo,
                           6,
                           trunc(sysdate)
                          ) cell_personale,
                decode(f_recapito(coen.ni,
                                  coen.tipo_tributo,
                                  7,
                                  trunc(sysdate)
                                  ),
                       null,null,'Cell. Ufficio ') label_cell_lavoro,
                f_recapito(coen.ni,
                           coen.tipo_tributo,
                           7,
                           trunc(sysdate)
                          ) cell_lavoro,
                decode(coen.tipo_residente||coen.tipo,
                       11,decode(coen.label_rap,'',coen.cognome_nome,coen.rappresentante),
                          decode(coen.erede_di,
                                 '',decode(coen.stato,50,'Eredi di ','')||coen.cognome_nome,
                                 coen.cognome_nome_erede)
                      ) riga_destinatario_1,
                      decode(coen.tipo_residente||coen.tipo,
                             11,decode(coen.label_rap,'',coen.presso,coen.descr_carica||' '||coen.cognome_nome),
                          decode(coen.erede_di,
                                 '',coen.presso,
                                    coen.erede_di||' '||coen.cognome_nome||
                                    decode(coen.presso_erede,'','',' '||coen.presso_erede)
                                )
                      ) riga_destinatario_2,
                ltrim(decode(coen.scala_dest,'','','Scala '||coen.scala_dest)||
                      decode(coen.piano_dest,'','',' Piano '||coen.piano_dest)||
                      decode(coen.interno_dest,'','',' Int. '||coen.interno_dest)
                     ) riga_destinatario_3,
                coen.via_dest||' '||coen.num_civ_dest||
                decode(coen.suffisso_dest,'','','/'||coen.suffisso_dest) riga_destinatario_4,
                coen.cap_dest||' '||coen.comune_dest||' '||coen.provincia_dest riga_destinatario_5,
                f_descrizione_titr(coen.tipo_tributo,anno_ruolo) descr_titr,
                a_ruolo ruolo,
                a_modello modello,
                a_anno anno_imposta,
                a_pratica_base pratica_base,
                v_tot_importo_versato as importo_versato_tot,
                v_tot_imposta_netta as imposta_netta_tot,
                v_tot_imposta_lorda as imposta_lorda_tot,
                v_tot_imposta_arr as imposta_arrorondata_tot,
                f_formatta_numero(v_tot_imposta_lorda_num - v_tot_importo_versato_num,'I','S') differenza_lorda_tot,
                f_formatta_numero(v_tot_imposta_arr_num - v_tot_importo_versato_num,'I','S') differenza_imposta_tot,
    -- Ruolo
                ruoli.tipo_ruolo,
                ruoli.anno_ruolo,
                ruoli.anno_emissione,
                ruoli.progr_emissione,
                to_char(ruoli.data_emissione, 'dd/mm/yyyy') data_emissione,
                ruoli.descrizione,
                ruoli.rate,
                ruoli.specie_ruolo,
                ruoli.cod_sede,
                ruoli.data_denuncia,
                to_char(ruoli.scadenza_prima_rata, 'dd/mm/yyyy') scadenza_prima_rata,
                to_char(ruoli.scadenza_rata_2, 'dd/mm/yyyy') scadenza_rata_2,
                to_char(ruoli.scadenza_rata_3, 'dd/mm/yyyy') scadenza_rata_3,
                to_char(ruoli.scadenza_rata_4, 'dd/mm/yyyy') scadenza_rata_4,
                to_char(ruoli.scadenza_rata_unica, 'dd/mm/yyyy') scadenza_rata_unica,
                to_char(ruoli.invio_consorzio, 'dd/mm/yyyy') invio_consorzio,
                ruoli.ruolo_rif,
                ruoli.importo_lordo,
                ruoli.a_anno_ruolo,
                ruoli.cognome_resp,
                ruoli.nome_resp,
                to_char(ruoli.data_fine_interessi, 'dd/mm/yyyy') data_fine_interessi,
                ruoli.stato_ruolo,
                ruoli.ruolo_master,
                ruoli.tipo_calcolo,
                ruoli.tipo_emissione,
                ruoli.perc_acconto,
                ruoli.ente,
                ruoli.flag_calcolo_tariffa_base,
                ruoli.flag_tariffe_ruolo,
                ruoli.note,
                ruoli.utente,
                to_char(ruoli.data_variazione, 'dd/mm/yyyy') data_variazione,
                decode(w_descr_ord, 'SGR%', '',
                   stampa_common.f_get_stringa_versamenti( ruoli.tipo_tributo
                                           , a_cod_fiscale
                                           , a_ruolo
                                           , ruoli.anno_ruolo
                                           , ruoli.tipo_ruolo
                                           , ruoli.tipo_emissione
                                           , a_modello)) stringa_versamenti
           from contribuenti_ente coen,
                ruoli
          where coen.ni = w_ni
            and ruoli.ruolo = a_ruolo
            and coen.tipo_tributo = a_tipo_tributo;
    end if;
    return rc;
  end contribuenti_ente;

  function lista_canoni(a_ruolo                    number     default -1,
                       a_cod_fiscale               varchar2   default '',
                       a_modello                   number     default -1,
                       a_tipo_tributo              varchar2   default '',
                       a_anno                      number     default -1,
                       a_pratica_base              number     default -1,
                       a_gruppo_tributo            varchar2   default null,
                       a_flag_no_depag             varchar2   default null)  -- S Si, N No, X solo
  return sys_refcursor is
    rc                          sys_refcursor;
  begin
    open rc for
    select  esenzione,
            descrizione_utenza,
            indirizzo_utenza,
            localita_utenza,
            comune_utenza,
            provincia_utenza,
            sigla_pro_utenza,
            estremi_catastali,
            periodo_tariffa,
            periodo_imposta,
            descrizione_perc_detr,
            descrizione_perc_magg,
            min(pratica) as pratica_canone,
            min(data_pratica) as data_pratica,
            min(oggetto_pratica) as oggetto_pratica,
            oggetto,
            flag_depag,
            flag_altro,
            a_ruolo ruolo,
            a_cod_fiscale cod_fiscale,
            a_modello modello,
            a_tipo_tributo tipo_tributo,
            gruppo_tributo,
            gruppo_tributo_descr,
            a_anno anno_imposta,
            a_pratica_base pratica_base
    from (
          select decode(ogpr.flag_contenzioso,'S','Sì','No') as esenzione,
                 decode(ogge.descrizione,null,'--',ogge.descrizione) as descrizione_utenza,
                 decode(ogge.cod_via
                       ,null,ogge.indirizzo_localita
                            ,arvi.denom_uff
                       ) ||
                 decode(ogge.num_civ
                       ,null, ''
                            , ', ' || to_char(ogge.num_civ)
                       ) ||
                 decode(ogge.suffisso
                       ,null, ''
                            , '/' || ogge.suffisso
                       ) ||
                 decode(ogpr.indirizzo_occ
                    ,null, ''
                    ,' Località '|| ogpr.indirizzo_occ
                    ) ||
                 decode(cmoc.denominazione
                    ,null, ''
                    ,', '|| cmoc.denominazione
                    ) ||
                 decode(pvoc.sigla
                    ,null, ''
                    ,' ('||pvoc.sigla||')'
                    ) ||
                 decode(ogpr.da_chilometro
                       ,null, ''
                            , ' KM ' || f_formatta_numero(ogpr.da_chilometro,'N3','S')
                       ) ||
                 decode(ogpr.lato
                       ,null, ''
                            , ' Lato ' || decode(ogpr.lato,'S','SX','D','DX',ogpr.lato)
                       ) as indirizzo_utenza,
                 ogpr.indirizzo_occ localita_utenza,
                 cmoc.denominazione comune_utenza,
                 pvoc.denominazione provincia_utenza,
                 decode(pvoc.sigla,null,'','('||pvoc.sigla||')') sigla_pro_utenza,
                 nvl(ltrim(decode(ogge.partita,null,'',' Part.'||trim(ogge.partita))
                           ||decode(ogge.sezione,null,'',' Sez.'||trim(ogge.sezione))
                           ||decode(ogge.foglio,null,'',' Fg.'||trim(ogge.foglio))
                           ||decode(ogge.numero,null,'',' Num.'||trim(ogge.numero))
                           ||decode(ogge.subalterno,null,'',' Sub.'||trim(ogge.subalterno))
                           ||decode(ogge.zona,null,'',' Zona '||trim(ogge.zona)))
                     , '-') as estremi_catastali,
                 decode(ogpr.tipo_occupazione,'T','Giornaliera','Annuale') as periodo_tariffa,
                 decode(ogpr.tipo_occupazione,'T',
                            'Dal ' || to_char(ogco.inizio_occupazione, 'dd/mm/yyyy') ||
                            ' al ' || to_char(ogco.fine_occupazione, 'dd/mm/yyyy'),
                            'Annualità'
                       ) as periodo_imposta
               , (case when nvl(ogco.perc_detrazione,0) > 0 then
                          f_formatta_numero(ogco.perc_detrazione,'P','S') || '%'
                          else '-' end) descrizione_perc_detr
               , (case when nvl(ogco.perc_detrazione,0) < 0 then
                          f_formatta_numero(-ogco.perc_detrazione,'P','S') || '%'
                          else '-' end) descrizione_perc_magg
               , cotr.gruppo_tributo
               , grtr.descrizione gruppo_tributo_descr
               , decode(nvl(nvl(tari.flag_no_depag,cate.flag_no_depag),'N'),'S','No','Sì') flag_depag
               , decode(nvl(nvl(tari.flag_no_depag,cate.flag_no_depag),'N'),'S','Sì','No') flag_altro
               , prtr.pratica as pratica
               , prtr.data as data_pratica
               , ogpr.oggetto_pratica as oggetto_pratica
               , ogpr.oggetto as oggetto
           from oggetti_pratica ogpr,
                oggetti_contribuente ogco,
                oggetti_validita ogva,
                pratiche_tributo prtr,
                codici_tributo cotr,
                gruppi_tributo grtr,
                categorie cate,
                tariffe tari,
                oggetti ogge,
                archivio_vie arvi,
                ad4_comuni cmoc,
                ad4_provincie pvoc
           where
           --   ogva.dal <= to_date('3112' || a_anno,'ddmmyyyy') and
                nvl(ogva.al,to_date('31129999','ddmmyyyy')) >= to_date('0101' || a_anno,'ddmmyyyy')
            and prtr.tipo_tributo||''= a_tipo_tributo
            and prtr.cod_fiscale     = a_cod_fiscale
            and prtr.pratica         = ogpr.pratica
            and ogco.cod_fiscale     = prtr.cod_fiscale
            and ogco.oggetto_pratica = ogpr.oggetto_pratica
            and ogva.oggetto_pratica = ogpr.oggetto_pratica
            and ogva.cod_fiscale     = prtr.cod_fiscale
            and ogva.tipo_tributo    = prtr.tipo_tributo
            and ogge.oggetto         = ogpr.oggetto
            and ogpr.tributo         = cotr.tributo
            and cotr.gruppo_tributo  = grtr.gruppo_tributo (+)
            and cate.tributo         = ogpr.tributo
            and cate.categoria       = ogpr.categoria
            and tari.tributo         = ogpr.tributo
            and tari.categoria       = ogpr.categoria
            and tari.tipo_tariffa    = ogpr.tipo_tariffa
            and tari.anno            = a_anno
            and ((nvl(a_flag_no_depag,'S') = 'S') or
                 ((nvl(a_flag_no_depag,'S') = 'X') and (nvl(nvl(tari.flag_no_depag,cate.flag_no_depag),'N') = 'S')) or
                 ((nvl(a_flag_no_depag,'S') = 'N') and (nvl(nvl(tari.flag_no_depag,cate.flag_no_depag),'N') <> 'S'))
            )
            and arvi.cod_via (+)     = ogge.cod_via
            and cmoc.provincia_stato = pvoc.provincia (+)
            and ogpr.cod_pro_occ = cmoc.provincia_stato (+)
            and ogpr.cod_com_occ = cmoc.comune (+)
            and (
                 ((a_pratica_base = -1) and
                   (cotr.flag_ruolo is null) and
                   ((a_gruppo_tributo is null) or
                    ((a_gruppo_tributo is not null) and (cotr.gruppo_tributo = a_gruppo_tributo))) and
                   (ogpr.tipo_occupazione = 'P') and
                   (ogva.dal < to_date('0101' || a_anno,'ddmmyyyy')) and
                   (
                    prtr.tipo_pratica in ('D', 'C') or
                    (prtr.tipo_pratica = 'A' and ogpr.anno > prtr.anno and prtr.flag_denuncia = 'S')
                   )
                  )
                or
                 ((a_pratica_base <> -1) and
                  (prtr.pratica = a_pratica_base)
                 )
            )
    )
    group by
          esenzione,
          descrizione_utenza,
          indirizzo_utenza,
          localita_utenza,
          comune_utenza,
          provincia_utenza,
          sigla_pro_utenza,
          estremi_catastali,
          periodo_tariffa,
          periodo_imposta,
          descrizione_perc_detr,
          descrizione_perc_magg,
          oggetto,
          flag_depag,
          flag_altro,
          gruppo_tributo,
          gruppo_tributo_descr
    order by
          gruppo_tributo,
          flag_depag desc,
          provincia_utenza,
          comune_utenza,
          indirizzo_utenza,
          estremi_catastali,
          data_pratica;
  return rc;

  end lista_canoni;

  function elenco_canoni(a_ruolo                     number     default -1,
                         a_cod_fiscale               varchar2   default '',
                         a_modello                   number     default -1,
                         a_tipo_tributo              varchar2   default '',
                         a_anno                      number     default -1,
                         a_pratica_base              number     default -1,
                         a_oggetto_base              number     default -1,
                         a_gruppo_tributo            varchar2   default null,
                         a_flag_no_depag             varchar2   default null)  -- S Si, N No, X solo
  return sys_refcursor is
    rc                          sys_refcursor;
  begin
    open rc for
    select decode(ogpr.flag_contenzioso,'S','Sì','No') as esenzione,
           decode(ogge.descrizione,null,'--',ogge.descrizione) as descrizione_utenza,
           decode(cotr.descrizione_ruolo,null,'--',cotr.descrizione_ruolo) as descrizione_codice,
           decode(a_tipo_tributo,
                     'CUNI',
                     case nvl(tari.tariffa_quota_fissa,0) when 0 then '' else
                       'Base ' || f_formatta_numero(tari.tariffa_quota_fissa,'V','S') ||
                       ' - Coefficiente ' || (f_formatta_numero(tari.tariffa,'N3','S') ||
                       decode(tari.limite,null,'',
                        ' fino a '||f_formatta_numero(nvl(tari.limite,0),'N0','S') ||
                        decode(tari.riduzione_quota_variabile,201,' gg','') ||
                        ' poi '||f_formatta_numero(tari.tariffa_superiore,'N3','S'))) ||
                       ' - Riduzione ' || f_formatta_numero(tari.perc_riduzione,'P','S') || '%'
                     end
                     , '') descrizione_tariffa,
           decode(a_tipo_tributo,
                     'CUNI',
                     case nvl(tari.tariffa_quota_fissa,0) when 0 then '' else
                       'Base ' || f_formatta_numero(tari.tariffa_quota_fissa,'V','S') ||
                       ' - Coefficiente ' || (f_formatta_numero(tari.tariffa,'N3','S') ||
                       decode(tari.limite,null,'',
                        ' fino a '||f_formatta_numero(nvl(tari.limite,0),'N0','S') ||
                        decode(tari.riduzione_quota_variabile,201,' gg','') ||
                        ' poi '||f_formatta_numero(tari.tariffa_superiore,'N3','S'))) ||
                       ' - Maggiorazione ' || f_formatta_numero(-tari.perc_riduzione,'P','S') || '%'
                     end
                     , '') descrizione_tariffa_magg,
           (decode(a_tipo_tributo,
                     'CUNI',
                     f_formatta_numero(nvl(tari.tariffa_quota_fissa,0) * nvl(tari.tariffa,0) *
                                                                       (100 - nvl(tari.perc_riduzione,0)) * 0.01,'V','S') ||
                     decode(tari.limite,null,'',' poi ' ||
                     f_formatta_numero(nvl(tari.tariffa_quota_fissa,0) * nvl(tari.tariffa_superiore,0) *
                                                                       (100 - nvl(tari.perc_riduzione,0)) * 0.01,'V','S'))
                     , f_formatta_numero(tari.tariffa,'V','S')
                     ) ||
                     ' / '||decode(ogpr.tipo_occupazione,'T','Giorno','Anno')) importo_tariffa,
           decode(ogpr.tipo_occupazione,'T','Giornaliera','Annuale') periodo_tariffa,
           decode(ogpr.tipo_occupazione,'T','Temporanea (' ||
                  f_formatta_numero(nvl(ogco.data_cessazione,TO_DATE('20991231','YYYYMMDD')) -
                                                 nvl(ogco.data_decorrenza,TO_DATE('19010101','YYYYMMDD')) + 1,'N0','S') || 'gg)'
                  ,'Permanente') occupazione_tariffa,
           decode(a_tipo_tributo,
                     'CUNI',
                        case nvl(tari.tariffa_quota_fissa,0) when 0 then '' else
                          decode(cate.descrizione,null, '', cate.descrizione) end,
                     ' Cat. '||cate.categoria || decode(cate.descrizione,null, '', ' - '||cate.descrizione)) dati_categoria,
           decode(ogge.cod_via
                 ,null,ogge.indirizzo_localita
                      ,arvi.denom_uff
                 ) ||
           decode(ogge.num_civ
                 ,null, ''
                      , ', ' || to_char(ogge.num_civ)
                 ) ||
           decode(ogge.suffisso
                 ,null, ''
                      , '/' || ogge.suffisso
                 ) ||
           decode(ogpr.indirizzo_occ
              ,null, ''
              ,' Località '|| ogpr.indirizzo_occ
              ) ||
           decode(cmoc.denominazione
              ,null, ''
              ,', '|| cmoc.denominazione
              ) ||
           decode(pvoc.sigla
              ,null, ''
              ,' ('||pvoc.sigla||')'
              ) ||
           decode(ogpr.da_chilometro
                 ,null, ''
                      , ' KM ' || f_formatta_numero(ogpr.da_chilometro,'I','S')
                 ) ||
           decode(ogpr.lato
                 ,null, ''
                      , ' Lato ' || decode(ogpr.lato,'S','SX','D','DX',ogpr.lato)
                 ) indirizzo_utenza,
           ogpr.indirizzo_occ localita_utenza,
           cmoc.denominazione comune_utenza,
           pvoc.denominazione provincia_utenza,
           decode(pvoc.sigla,null,'','('||pvoc.sigla||')') sigla_prov_utenza,
           decode(tari.descrizione
                 ,null, ''
                      , tari.descrizione) dati_tariffa,
           decode(ogpr.tipo_occupazione,'T',
                      'Dal ' || to_char(ogco.data_decorrenza, 'dd/mm/yyyy') ||
                      ' al ' || to_char(ogco.data_cessazione, 'dd/mm/yyyy'),
                      'Annualità'
                 ) periodo_imposta,
           nvl(ltrim(decode(ogge.partita,null,'',' Part.'||trim(ogge.partita))
                     ||decode(ogge.sezione,null,'',' Sez.'||trim(ogge.sezione))
                     ||decode(ogge.foglio,null,'',' Fg.'||trim(ogge.foglio))
                     ||decode(ogge.numero,null,'',' Num.'||trim(ogge.numero))
                     ||decode(ogge.subalterno,null,'',' Sub.'||trim(ogge.subalterno))
                     ||decode(ogge.zona,null,'',' Zona '||trim(ogge.zona)))
               , '-') estremi_catastali
         , decode(ogge.categoria_catasto,null,'','Cat.'||OGGE.categoria_catasto) categoria_catasto
         , decode(ogpr.consistenza,null,'','mq ' || f_formatta_numero(ogpr.consistenza,'I','S')) superficie
         , (f_formatta_numero(nvl(ogco.perc_possesso,100),'P','S') || '%') descrizione_perc_poss
         , f_formatta_numero(tari.tariffa_quota_fissa,'I','S') base_tariffa
         , (f_formatta_numero(tari.tariffa,'N3','S') ||
                decode(tari.tariffa_superiore,null,'','/'||f_formatta_numero(tari.tariffa_superiore,'N3','S'))) coeff_tariffa
         , case when NVL(tari.perc_riduzione,0) > 0 then f_formatta_numero(tari.perc_riduzione,'P','S') || '%' else '-' end riduz_tariffa
         , case when NVL(tari.perc_riduzione,0) < 0 then f_formatta_numero(-tari.perc_riduzione,'P','S') || '%' else '-' end magg_tariffa
         , (case when nvl(ogco.perc_detrazione,0) > 0 then
                    f_formatta_numero(ogco.perc_detrazione,'P','S') || '%'
                    else '-' end) descrizione_perc_detr
         , (case when nvl(ogco.perc_detrazione,0) < 0 then
                    f_formatta_numero(-ogco.perc_detrazione,'P','S') || '%'
                    else '-' end) descrizione_perc_magg
         , nvl(ogpr.note,'-') note_tariffa
         , '' periodo_ruolo
           -- campi riepilogo per ruoli a saldo
         , ogpr.oggetto_pratica
         , ogpr.oggetto
         , cate.flag_domestica
         , decode(nvl(nvl(tari.flag_no_depag,cate.flag_no_depag),'N'),'S','No','Sì') flag_depag
         , decode(nvl(nvl(tari.flag_no_depag,cate.flag_no_depag),'N'),'S','Sì','No') flag_altro
         , to_char(ogco.inizio_occupazione, 'dd/mm/yyyy') as inizio_occ
         , to_char(ogco.fine_occupazione, 'dd/mm/yyyy') as fine_occ
         , to_char(ogpr.inizio_concessione, 'dd/mm/yyyy') as inizio_conc
         , to_char(ogpr.fine_concessione, 'dd/mm/yyyy') as fine_conc
         , ogpr.num_concessione as conc_numero
         , to_char(ogpr.data_concessione, 'dd/mm/yyyy') as conc_data
         , case when (ogpr.inizio_concessione is not null) or (ogpr.fine_concessione is not null) or
                     (ogpr.num_concessione is not null) or (ogpr.data_concessione is not null)
           then 'Concessione'
                ||decode(ogpr.inizio_concessione,null,'',' dal '||to_char(ogpr.inizio_concessione,'dd/mm/yyyy'))
                ||decode(ogpr.fine_concessione,null,'',' al '||to_char(ogpr.fine_concessione,'dd/mm/yyyy'))
                ||decode(ogpr.num_concessione,null,'',' numero '||to_char(ogpr.num_concessione))
                ||decode(ogpr.fine_concessione,null,'',' del '||to_char(ogpr.fine_concessione,'dd/mm/yyyy'))
           else '' end dett_conc
         , ogpr.larghezza as larghezza
         , ogpr.profondita as profondita
         , ogpr.consistenza_reale as mq_reali
         , ogpr.quantita as quantita
         , ogpr.consistenza mq
         , case when (ogpr.larghezza is not null) or (ogpr.profondita is not null) or
                     (ogpr.consistenza_reale is not null) or (ogpr.quantita is not null)
           then decode(ogpr.larghezza,null,'',decode(cotr.tipo_tributo_prec,'ICP',' L ',' larghezza ')||to_char(ogpr.larghezza)||'m')
                ||decode(ogpr.profondita,null,'',decode(cotr.tipo_tributo_prec,'ICP',' H ',' profondità ')||to_char(ogpr.profondita)||'m')
                ||decode(ogpr.consistenza_reale,null,'',' superficie '||to_char(ogpr.consistenza_reale)||'mq')
                ||decode(ogpr.quantita,null,'',' quantità '||to_char(ogpr.quantita))
           else '' end dett_cons
         , cotr.gruppo_tributo
         , grtr.descrizione gruppo_tributo_descr
         , a_modello modello
     from
         oggetti_validita ogva,
         oggetti_pratica ogpr,
         oggetti_contribuente ogco,
         pratiche_tributo prtr,
         oggetti ogge,
         codici_tributo cotr,
         gruppi_tributo grtr,
         categorie cate,
         tariffe tari,
         archivio_vie arvi,
         ad4_comuni cmoc,
         ad4_provincie pvoc
     where
     --   ogva.dal <= to_date('3112' || a_anno,'ddmmyyyy') and
          nvl(ogva.al,to_date('31129999','ddmmyyyy')) >= to_date('0101' || a_anno,'ddmmyyyy')
      and ogva.tipo_tributo||''= a_tipo_tributo
      and ogva.cod_fiscale     = a_cod_fiscale
      and ogva.oggetto_pratica = ogpr.oggetto_pratica
      and ogpr.oggetto_pratica = ogco.oggetto_pratica
      and ogco.cod_fiscale     = ogva.cod_fiscale
      and ogpr.pratica         = prtr.pratica
      and cotr.tributo         = ogpr.tributo
      and cotr.gruppo_tributo  = grtr.gruppo_tributo (+)
      and cate.tributo         = ogpr.tributo
      and cate.categoria       = ogpr.categoria
      and ((nvl(a_flag_no_depag,'S') = 'S') or
           ((nvl(a_flag_no_depag,'S') = 'X') and (nvl(nvl(tari.flag_no_depag,cate.flag_no_depag),'N') = 'S')) or
           ((nvl(a_flag_no_depag,'S') = 'N') and (nvl(nvl(tari.flag_no_depag,cate.flag_no_depag),'N') <> 'S'))
      )
      and tari.anno            = a_anno --ogpr.anno
      and tari.tributo         = ogpr.tributo
      and tari.categoria       = ogpr.categoria
      and tari.tipo_tariffa    = ogpr.tipo_tariffa
      and ogge.oggetto         = ogpr.oggetto
      and arvi.cod_via (+)     = ogge.cod_via
      and cmoc.provincia_stato = pvoc.provincia (+)
      and ogpr.cod_pro_occ = cmoc.provincia_stato (+)
      and ogpr.cod_com_occ = cmoc.comune (+)
      and (
          (a_oggetto_base = -1)
          or
            (
            (a_oggetto_base <> -1) and
            (ogge.oggetto in (
                select ogpr.oggetto
                from oggetti_pratica ogpr
                where ogpr.oggetto_pratica = a_oggetto_base)
            )
            )
          )
      and (
            ((a_pratica_base = -1) and
             (ogpr.tipo_occupazione = 'P') and
             (ogva.dal < to_date('0101' || a_anno,'ddmmyyyy')) and
             ((a_gruppo_tributo is null) or
              ((a_gruppo_tributo is not null) and (cotr.gruppo_tributo = a_gruppo_tributo))) and
             (
              prtr.tipo_pratica in ('D', 'C') or
              (prtr.tipo_pratica = 'A' and ogpr.anno > prtr.anno and prtr.flag_denuncia = 'S')
             )
            )
          or
            ((a_pratica_base <> -1) and
             (prtr.pratica = a_pratica_base)
            )
          )
  order by
      gruppo_tributo,
      flag_depag desc,
      pvoc.denominazione,
      cmoc.denominazione,
      decode(ogge.cod_via,null,ogge.indirizzo_localita
                     ,arvi.denom_uff
                     || decode(ogge.num_civ, null, '', ', ' || ogge.num_civ)
                     || decode(ogge.suffisso, null, '', '/' || ogge.suffisso)),
      ogpr.categoria,
      ogpr.tipo_tariffa
    ;
  --
  return rc;
  end elenco_canoni;

  function dati_canoni(a_ruolo                     number     default -1,
                       a_cod_fiscale               varchar2   default '',
                       a_modello                   number     default -1,
                       a_tipo_tributo              varchar2   default '',
                       a_anno                      number     default -1,
                       a_pratica_base              number     default -1,
                       a_oggetto_base              number     default -1,
                       a_gruppo_tributo            varchar2   default null,
                       a_flag_no_depag             varchar2   default null)  -- S Si, N No, X solo
  return sys_refcursor is
    rc                          sys_refcursor;
  begin
    open rc for
    select decode(ogge.descrizione,null,'--',ogge.descrizione) as descrizione_utenza,
           decode(cotr.descrizione_ruolo,null,'--',cotr.descrizione_ruolo) as descrizione_codice,
           decode(a_tipo_tributo,
                     'CUNI',
                     case nvl(tari.tariffa_quota_fissa,0) when 0 then '' else
                       'Base ' || f_formatta_numero(tari.tariffa_quota_fissa,'V','S') ||
                       ' - Coefficiente ' || (f_formatta_numero(tari.tariffa,'N3','S') ||
                       decode(tari.limite,null,'',
                        ' fino a '||f_formatta_numero(nvl(tari.limite,0),'N0','S') ||
                        decode(tari.riduzione_quota_variabile,201,' gg','') ||
                        ' poi '||f_formatta_numero(tari.tariffa_superiore,'N3','S'))) ||
                       ' - Riduzione ' || f_formatta_numero(tari.perc_riduzione,'P','S') || '%'
                     end
                     , '') descrizione_tariffa,
           decode(a_tipo_tributo,
                     'CUNI',
                     case nvl(tari.tariffa_quota_fissa,0) when 0 then '' else
                       'Base ' || f_formatta_numero(tari.tariffa_quota_fissa,'V','S') ||
                       ' - Coefficiente ' || (f_formatta_numero(tari.tariffa,'N3','S') ||
                       decode(tari.limite,null,'',
                        ' fino a '||f_formatta_numero(nvl(tari.limite,0),'N0','S') ||
                        decode(tari.riduzione_quota_variabile,201,' gg','') ||
                        ' poi '||f_formatta_numero(tari.tariffa_superiore,'N3','S'))) ||
                       ' - Maggiorazione ' || f_formatta_numero(tari.perc_riduzione,'P','S') || '%'
                     end
                     , '') descrizione_tariffa_magg,
           (decode(a_tipo_tributo,
                     'CUNI',
                     f_formatta_numero(nvl(tari.tariffa_quota_fissa,0) * nvl(tari.tariffa,0) *
                                                                       (100 - nvl(tari.perc_riduzione,0)) * 0.01,'V','S') ||
                     decode(tari.limite,null,'',' poi ' ||
                     f_formatta_numero(nvl(tari.tariffa_quota_fissa,0) * nvl(tari.tariffa_superiore,0) *
                                                                       (100 - nvl(tari.perc_riduzione,0)) * 0.01,'V','S'))
                     , f_formatta_numero(tari.tariffa,'V','S')
                     ) ||
                     ' / '||decode(ogpr.tipo_occupazione,'T','Giorno','Anno')) importo_tariffa,
           decode(ogpr.tipo_occupazione,'T','Giornaliera','Annuale') periodo_tariffa,
           decode(ogpr.tipo_occupazione,'T','Temporanea (' ||
                  f_formatta_numero(nvl(ogco.data_cessazione,TO_DATE('20991231','YYYYMMDD')) -
                                                 nvl(ogco.data_decorrenza,TO_DATE('19010101','YYYYMMDD')) + 1,'N0','S') || 'gg)'
                  ,'Permanente') occupazione_tariffa,
           decode(a_tipo_tributo,
                     'CUNI',
                        case nvl(tari.tariffa_quota_fissa,0) when 0 then '' else
                          decode(cate.descrizione,null, '', cate.descrizione) end,
                     ' Cat. '||cate.categoria || decode(cate.descrizione,null, '', ' - '||cate.descrizione)) dati_categoria,
           decode(ogge.cod_via
                 ,null,ogge.indirizzo_localita
                      ,arvi.denom_uff
                 ) ||
           decode(ogge.num_civ
                 ,null, ''
                      , ', ' || to_char(ogge.num_civ)
                 ) ||
           decode(ogge.suffisso
                 ,null, ''
                      , '/' || ogge.suffisso
                 ) ||
           decode(ogpr.indirizzo_occ
              ,null, ''
              ,' Località '|| ogpr.indirizzo_occ
              ) ||
           decode(cmoc.denominazione
              ,null, ''
              ,', '|| cmoc.denominazione
              ) ||
           decode(pvoc.sigla
              ,null, ''
              ,' ('||pvoc.sigla||')'
             ) ||
           decode(ogpr.da_chilometro
                 ,null, ''
                      , ' KM ' || f_formatta_numero(ogpr.da_chilometro,'I','S')
                 ) ||
           decode(ogpr.lato
                 ,null, ''
                      , ' Lato ' || decode(ogpr.lato,'S','SX','D','DX',ogpr.lato)
                 ) indirizzo_utenza,
           ogpr.indirizzo_occ localita_utenza,
           cmoc.denominazione comune_utenza,
           pvoc.denominazione provincia_utenza,
           decode(pvoc.sigla,null,'','('||pvoc.sigla||')') sigla_prov_utenza,
           decode(tari.descrizione
                 ,null, ''
                      , tari.descrizione) dati_tariffa,
           decode(ogpr.tipo_occupazione,'T',
                      'Dal ' || to_char(ogco.data_decorrenza, 'dd/mm/yyyy') ||
                      ' al ' || to_char(ogco.data_cessazione, 'dd/mm/yyyy'),
                      'Annualità'
                 ) periodo_imposta,
           nvl(ltrim(decode(ogge.partita,null,'',' Part.'||trim(ogge.partita))
                     ||decode(ogge.sezione,null,'',' Sez.'||trim(ogge.sezione))
                     ||decode(ogge.foglio,null,'',' Fg.'||trim(ogge.foglio))
                     ||decode(ogge.numero,null,'',' Num.'||trim(ogge.numero))
                     ||decode(ogge.subalterno,null,'',' Sub.'||trim(ogge.subalterno))
                     ||decode(ogge.zona,null,'',' Zona '||trim(ogge.zona)))
               , '-') estremi_catastali
         , decode(ogge.categoria_catasto,null,'','Cat.'||OGGE.categoria_catasto) categoria_catasto
         , decode(ogpr.consistenza,null,'','mq ' || f_formatta_numero(ogpr.consistenza,'I','S')) superficie
         , (f_formatta_numero(nvl(ogco.perc_possesso,100),'P','S') || '%') descrizione_perc_poss
         , f_formatta_numero(tari.tariffa_quota_fissa,'I','S') base_tariffa
         , (f_formatta_numero(tari.tariffa,'N3','S') ||
              decode(tari.tariffa_superiore,null,'','/'||f_formatta_numero(tari.tariffa_superiore,'N3','S'))) coeff_tariffa
         , case when NVL(tari.perc_riduzione,0) > 0 then f_formatta_numero(tari.perc_riduzione,'P','S') || '%' else '-' end riduz_tariffa
         , case when NVL(tari.perc_riduzione,0) < 0 then f_formatta_numero(-tari.perc_riduzione,'P','S') || '%' else '-' end magg_tariffa
         , (case when nvl(ogco.perc_detrazione,0) > 0 then
                    f_formatta_numero(ogco.perc_detrazione,'P','S') || '%'
                    else '-' end) descrizione_perc_detr
         , (case when nvl(ogco.perc_detrazione,0) < 0 then
                    f_formatta_numero(-ogco.perc_detrazione,'P','S') || '%'
                    else '-' end) descrizione_perc_magg
         , nvl(ogpr.note,'-') note_tariffa
         , '' periodo_ruolo
         , f_formatta_numero(nvl(ogim.imposta_dovuta,ogim.imposta),'I','S') imposta
      -- , decode(nvl(ogim.maggiorazione_tares,0),0,''
      --           ,f_formatta_numero(ogim.maggiorazione_tares,'I','S')) magg_tares
           -- riepilogo importi per oggetto
         , 0 as residuo_lordo
         , f_formatta_numero(ogim.imposta,'I','S') imposta_netta
      -- , ogim.addizionale_pro as add_pro
         , f_formatta_numero(ogim.imposta + nvl(ogim.addizionale_pro,0),'I','S') imposta_lorda
           -- campi riepilogo per ruoli a saldo
         , 0 as imposta_netta_annua
         , 0 as imposta_netta_acconto
         , ogpr.oggetto_pratica
         , ogim.oggetto_imposta
         , ogpr.oggetto
         , cate.flag_domestica
         , decode(nvl(nvl(tari.flag_no_depag,cate.flag_no_depag),'N'),'S','No','Sì') flag_depag
         , decode(nvl(nvl(tari.flag_no_depag,cate.flag_no_depag),'N'),'S','Sì','No') flag_altro
         , to_char(ogco.inizio_occupazione, 'dd/mm/yyyy') as inizio_occ
         , to_char(ogco.fine_occupazione, 'dd/mm/yyyy') as fine_occ
         , to_char(ogpr.inizio_concessione, 'dd/mm/yyyy') as inizio_conc
         , to_char(ogpr.fine_concessione, 'dd/mm/yyyy') as fine_conc
         , ogpr.num_concessione as conc_numero
         , to_char(ogpr.data_concessione, 'dd/mm/yyyy') as conc_data
         , case when (ogpr.inizio_concessione is not null) or (ogpr.fine_concessione is not null) or
                     (ogpr.num_concessione is not null) or (ogpr.data_concessione is not null)
           then 'Concessione'
                ||decode(ogpr.inizio_concessione,null,'',' dal '||to_char(ogpr.inizio_concessione,'dd/mm/yyyy'))
                ||decode(ogpr.fine_concessione,null,'',' al '||to_char(ogpr.fine_concessione,'dd/mm/yyyy'))
                ||decode(ogpr.num_concessione,null,'',' numero '||to_char(ogpr.num_concessione))
                ||decode(ogpr.fine_concessione,null,'',' del '||to_char(ogpr.fine_concessione,'dd/mm/yyyy'))
           else '' end dett_conc
         , ogpr.larghezza as larghezza
         , ogpr.profondita as profondita
         , ogpr.consistenza_reale as mq_reali
         , ogpr.quantita as quantita
         , ogpr.consistenza mq
         , case when (ogpr.larghezza is not null) or (ogpr.profondita is not null) or
                     (ogpr.consistenza_reale is not null) or (ogpr.quantita is not null)
           then decode(ogpr.larghezza,null,'',decode(cotr.tipo_tributo_prec,'ICP',' L ',' larghezza ')||to_char(ogpr.larghezza)||'m')
                ||decode(ogpr.profondita,null,'',decode(cotr.tipo_tributo_prec,'ICP',' H ',' profondità ')||to_char(ogpr.profondita)||'m')
                ||decode(ogpr.consistenza_reale,null,'',' superficie '||to_char(ogpr.consistenza_reale)||'mq')
                ||decode(ogpr.quantita,null,'',' quantità '||to_char(ogpr.quantita))
           else '' end dett_cons
         , '' as  stringa_familiari
         , cotr.gruppo_tributo
         , grtr.descrizione gruppo_tributo_descr
         , a_modello modello
         , sum(ogim.imposta) over() imposta_netta_tot_num
         , sum(ogim.imposta + nvl(ogim.addizionale_pro,0)) over() imposta_lorda_tot_num
         , round((sum(ogim.imposta + nvl(ogim.addizionale_pro,0)) over()),0) imposta_arr_tot_num
         , f_formatta_numero(sum(ogim.imposta) over(),'I','S') imposta_netta_tot
         , f_formatta_numero(sum(ogim.imposta + nvl(ogim.addizionale_pro,0)) over(),'I','S') imposta_lorda_tot
         , f_formatta_numero(round((sum(ogim.imposta + nvl(ogim.addizionale_pro,0)) over()),0),'I','S') imposta_arr_tot
     from oggetti_imposta ogim,
          oggetti_pratica ogpr,
          oggetti_contribuente ogco,
          oggetti_validita ogva,
          pratiche_tributo prtr,
          oggetti ogge,
          codici_tributo cotr,
          gruppi_tributo grtr,
          categorie cate,
          tariffe tari,
          archivio_vie arvi,
          ad4_comuni cmoc,
          ad4_provincie pvoc
    where
          ogim.anno            = a_anno
      and ogim.tipo_tributo    = a_tipo_tributo
      and ogim.cod_fiscale     = a_cod_fiscale
      and ogpr.oggetto_pratica = ogim.oggetto_pratica
      and ogco.oggetto_pratica = ogim.oggetto_pratica
      and ogco.cod_fiscale     = ogim.cod_fiscale
      and prtr.cod_fiscale     = ogim.cod_fiscale
      and prtr.pratica         = ogpr.pratica
      and ogva.oggetto_pratica = ogpr.oggetto_pratica
      and ogva.cod_fiscale     = ogco.cod_fiscale
      and ogva.tipo_tributo    = prtr.tipo_tributo
      and cate.tributo         = ogpr.tributo
      and cate.categoria       = ogpr.categoria
      and ((nvl(a_flag_no_depag,'S') = 'S') or
           ((nvl(a_flag_no_depag,'S') = 'X') and (nvl(nvl(tari.flag_no_depag,cate.flag_no_depag),'N') = 'S')) or
           ((nvl(a_flag_no_depag,'S') = 'N') and (nvl(nvl(tari.flag_no_depag,cate.flag_no_depag),'N') <> 'S'))
      )
      and cotr.tributo         = ogpr.tributo
      and cotr.gruppo_tributo  = grtr.gruppo_tributo (+)
      and ((a_pratica_base <> -1) or
           (a_gruppo_tributo is null) or
           ((a_gruppo_tributo is not null) and (cotr.gruppo_tributo = a_gruppo_tributo))
      )
      and tari.anno            = a_anno --ogpr.anno
      and tari.tributo         = ogpr.tributo
      and tari.categoria       = ogpr.categoria
      and tari.tipo_tariffa    = ogpr.tipo_tariffa
      and ogge.oggetto         = ogpr.oggetto
      and arvi.cod_via (+)     = ogge.cod_via
      and cmoc.provincia_stato = pvoc.provincia (+)
      and ogpr.cod_pro_occ = cmoc.provincia_stato (+)
      and ogpr.cod_com_occ = cmoc.comune (+)
      and ogim.flag_calcolo = 'S'
      and ogim.imposta > 0
      and (
          (a_oggetto_base = -1)
          or
            (
            (a_oggetto_base <> -1) and
            (ogge.oggetto in (
                select ogpr.oggetto
                from oggetti_pratica ogpr
                where ogpr.oggetto_pratica = a_oggetto_base)
            )
            )
          )
      and (
            ((a_pratica_base = -1) and
             (ogpr.tipo_occupazione = 'P') and
             (
              prtr.tipo_pratica in ('D', 'C') or
              (prtr.tipo_pratica = 'A' and ogim.anno > prtr.anno  and prtr.flag_denuncia = 'S')
             )
            )
          or
            ((a_pratica_base <> -1) and
             (prtr.pratica = a_pratica_base)
            )
          )
  order by
      gruppo_tributo,
      flag_depag desc,
      pvoc.denominazione,
      cmoc.denominazione,
      decode(ogge.cod_via,null,ogge.indirizzo_localita
                     ,arvi.denom_uff
                     || decode(ogge.num_civ, null, '', ', ' || ogge.num_civ)
                     || decode(ogge.suffisso, null, '', '/' || ogge.suffisso))
    , ogim.imposta desc
    ;
  --
  return rc;
  end dati_canoni;

  function dati_rate(  a_ruolo                     number     default -1,
                       a_cod_fiscale               varchar2   default '',
                       a_modello                   number     default -1,
                       a_tipo_tributo              varchar2   default '',
                       a_anno                      number     default -1,
                       a_pratica_base              number     default -1,
                       a_gruppo_tributo            varchar2   default null,
                       a_flag_no_depag             varchar2   default null)  -- S Si, N No, X solo
  return sys_refcursor is
    rc                          sys_refcursor;
  begin
    open rc for
      select * from (
        select to_char(rtim.rata) rata
             , to_char(nvl(rtim.data_scadenza,scad.data_scadenza), 'dd/mm/yyyy') scadenza_rata
             , f_formatta_numero(rtim.imposta,'I','S') importo_rata
             , f_formatta_numero(decode(titr.flag_canone,'S',rtim.imposta,rtim.imposta_round),'I','S') arrotondato_rata
       --    , f_descrizione_timp(a_modello,'RATA_UNICA') stampa_rata_unica
       --    , f_descrizione_timp(a_modello,'RATE_SCADUTE') stampa_rate_scadute
             , decode(nvl(instr(nvl(note,'-'),'[NoDePag]'),0),0,'Sì','No') flag_depag
             , decode(nvl(instr(nvl(note,'-'),'[NoDePag]'),0),0,'No','Sì') flag_altro
             , to_char(rtim.conto_corrente) gruppo_tributo
             , grtr.descrizione gruppo_tributo_descr
             , rtim.rata as ordine
             , a_modello modello
          from
             rate_imposta rtim,
             (select
                  tipo_tributo,
                  anno,
                  tipo_scadenza,
                  rata,
                  to_date(substr(date_code,11,8),'YYYYMMDD') data_scadenza
              from
                (select
                    scad.tipo_tributo,
                    scad.anno,
                    scad.tipo_scadenza,
                    scad.rata,
                    min(case when
                         a_gruppo_tributo is not null and scad.gruppo_tributo = a_gruppo_tributo
                        then
                          lpad('-0',10,'0')
                        else
                          lpad(nvl(scad.gruppo_tributo,'0'),10,'0')
                        end ||
                        to_char(scad.data_scadenza,'YYYYMMDD')) date_code
                  from
                    scadenze scad
                  where scad.anno = a_anno
                    and scad.tipo_tributo = a_tipo_tributo
                    and scad.tipo_scadenza = 'V'
                    and scad.rata > 0
                  group by
                    scad.tipo_tributo,
                    scad.anno,
                    scad.tipo_scadenza,
                    scad.rata
                    )
             ) scad,
             gruppi_tributo grtr,
             tipi_tributo titr
          where
              scad.anno = a_anno and
              scad.tipo_tributo = a_tipo_tributo and
              scad.rata = rtim.rata
          and scad.tipo_scadenza  = 'V'
          and titr.tipo_tributo = scad.tipo_tributo
          and rtim.anno = a_anno
          and rtim.cod_fiscale = a_cod_fiscale
          and rtim.tipo_tributo = a_tipo_tributo
          and rtim.conto_corrente = grtr.gruppo_tributo (+)
          and ((nvl(a_flag_no_depag,'S') = 'S') or
               ((nvl(a_flag_no_depag,'S') = 'X') and (nvl(instr(nvl(note,'-'),'[NoDePag]'),0) != 0)) or
               ((nvl(a_flag_no_depag,'S') = 'N') and (nvl(instr(nvl(note,'-'),'[NoDePag]'),0) = 0))
              )
          and (
              ((a_pratica_base = -1) and (rtim.oggetto_imposta is null) and
               (nvl(rtim.conto_corrente,99990000) in (
                  select distinct nvl(cotr.conto_corrente,99990000) conto_corrente
                  from codici_tributo cotr
                  where cotr.flag_ruolo is null
                    and ((a_gruppo_tributo is null) or
                         ((a_gruppo_tributo is not null) and (cotr.gruppo_tributo = a_gruppo_tributo))
                    )
                  )
               )
              )
              or
              ((a_pratica_base <> -1) and
                (rtim.oggetto_imposta in (
                  select
                      ogim.oggetto_imposta
                  from
                      oggetti_imposta ogim,
                      oggetti_pratica ogpr,
                      oggetti_validita ogva,
                      pratiche_tributo prtr,
                      oggetti ogge
                  where ogim.anno            = a_anno
                    and ogim.tipo_tributo    = a_tipo_tributo
                    and ogim.cod_fiscale     = a_cod_fiscale
                    and ogpr.oggetto_pratica = ogim.oggetto_pratica
                    and prtr.cod_fiscale     = ogim.cod_fiscale
                    and prtr.pratica         = ogpr.pratica
                    and ogva.oggetto_pratica = ogpr.oggetto_pratica
                    and ogva.cod_fiscale     = ogim.cod_fiscale
                    and ogva.tipo_tributo    = prtr.tipo_tributo
                    and ogge.oggetto         = ogpr.oggetto
                    and ogim.flag_calcolo = 'S'
                    and ogim.imposta > 0
                    and prtr.pratica = a_pratica_base
                  )
              )
            )
          )
        union all
        select
            unica.rata
          , -- Se c'è la scadenza ogim prendo quella, senno scadenza_pratica, senno scadenza_rata
            case when unica.scadenza_ogim < to_date('31129999','ddmmyyyy') then
              to_char(unica.scadenza_ogim, 'dd/mm/yyyy')
            else
              to_char(nvl(unica.scadenza_pratica,unica.scadenza_rata), 'dd/mm/yyyy')
            end as scadenza_rata
          , unica.importo_rata
          , unica.arrotondato_rata
  --     , f_descrizione_timp(a_modello,'RATA_UNICA') stampa_rata_unica
  --     , f_descrizione_timp(a_modello,'RATE_SCADUTE') stampa_rate_scadute
          , unica.flag_depag
          , unica.flag_altro
          , unica.gruppo_tributo
          , unica.gruppo_tributo_descr
          , 9999 as ordine
          , a_modello modello
        from
          (select 'UNICA' rata
               , prsc.scadenza_pratica
               , prsc.scadenza_rata
               , f_formatta_numero(sum(ogim.imposta),'I','S') importo_rata
               , f_formatta_numero(decode(titr.flag_canone,'S',sum(ogim.imposta),round(sum(ogim.imposta))),'I','S') arrotondato_rata
               , decode(nvl(nvl(tari.flag_no_depag,cate.flag_no_depag),'N'),'S','No','Sì') flag_depag
               , decode(nvl(nvl(tari.flag_no_depag,cate.flag_no_depag),'N'),'S','Sì','No') flag_altro
               , cotr.gruppo_tributo
               , grtr.descrizione gruppo_tributo_descr
               , min(nvl(ogim.data_scadenza,to_date('31129999','ddmmyyyy'))) as scadenza_ogim
            from
                oggetti_imposta ogim,
                oggetti_pratica ogpr,
                categorie cate,
                tariffe tari,
                codici_tributo cotr,
                gruppi_tributo grtr,
                tipi_tributo titr,
                (select
                   f_scadenza_rata(a_tipo_tributo,a_anno,0,a_gruppo_tributo,prsc1.tipo_occupazione) as scadenza_rata,
                   prsc1.scadenza_pratica
                 from
                  (select
                     null as scadenza_pratica,
                     'P' as tipo_occupazione
                    from dual
                   where a_pratica_base = -1
                   union
                   select
                     prtr.data_scadenza as scadenza_pratica,
                     decode(prtr.tipo_evento,'U','T','P')
                    from pratiche_tributo prtr
                   where prtr.pratica = a_pratica_base
                  ) prsc1
                ) prsc
            where titr.tipo_tributo = a_tipo_tributo
              and ogim.oggetto_pratica = ogpr.oggetto_pratica
              and cotr.tributo = ogpr.tributo
              and cotr.gruppo_tributo = grtr.gruppo_tributo (+)
              and cate.tributo = ogpr.tributo
              and cate.categoria = ogpr.categoria
              and tari.tributo = ogpr.tributo
              and tari.categoria = ogpr.categoria
              and tari.tipo_tariffa = ogpr.tipo_tariffa
              and tari.anno  = a_anno
              and ((nvl(a_flag_no_depag,'S') = 'S') or
                   ((nvl(a_flag_no_depag,'S') = 'X') and (nvl(nvl(tari.flag_no_depag,cate.flag_no_depag),'N') = 'S')) or
                   ((nvl(a_flag_no_depag,'S') = 'N') and (nvl(nvl(tari.flag_no_depag,cate.flag_no_depag),'N') <> 'S'))
                  )
              and ogim.oggetto_imposta in (
                  select
                        ogim.oggetto_imposta
                  from
                        oggetti_imposta ogim,
                        oggetti_pratica ogpr,
                        oggetti_validita ogva,
                        pratiche_tributo prtr,
                        codici_tributo cotr,
                        oggetti ogge
                  where ogim.anno            = a_anno
                    and ogim.tipo_tributo    = a_tipo_tributo
                    and ogim.cod_fiscale     = a_cod_fiscale
                    and ogpr.oggetto_pratica = ogim.oggetto_pratica
                    and prtr.cod_fiscale     = ogim.cod_fiscale
                    and prtr.pratica         = ogpr.pratica
                    and ogva.oggetto_pratica = ogpr.oggetto_pratica
                    and ogva.cod_fiscale     = ogim.cod_fiscale
                    and ogva.tipo_tributo    = prtr.tipo_tributo
                    and ogge.oggetto         = ogpr.oggetto
                    and ogpr.tributo         = cotr.tributo
                    and ogim.flag_calcolo = 'S'
                    and ogim.imposta > 0
                    and (
                        ((a_pratica_base = -1) and
                         (ogpr.tipo_occupazione = 'P') and
                         (cotr.flag_ruolo is null) and
                         ((a_gruppo_tributo is null) or
                          ((a_gruppo_tributo is not null) and (cotr.gruppo_tributo = a_gruppo_tributo))) and
                         (ogva.dal < to_date('0101' || a_anno,'ddmmyyyy')) and
                         (
                          prtr.tipo_pratica in ('D', 'C') or
                          (prtr.tipo_pratica = 'A' and ogim.anno > prtr.anno  and prtr.flag_denuncia = 'S')
                         )
                        )
                      or
                        ((a_pratica_base <> -1) and
                         (prtr.pratica = a_pratica_base)
                        )
                    )
               )
           group by
                 1,
                 prsc.scadenza_pratica,
                 prsc.scadenza_rata,
                 titr.flag_canone,
                 nvl(tari.flag_no_depag,cate.flag_no_depag),
                 cotr.gruppo_tributo,
                 grtr.descrizione
           ) unica
         )
       order by
             flag_depag,
             ordine
       ;

  return rc;
  end dati_rate;

  function dati_versato(a_cod_fiscale               varchar2   default '',
                        a_tipo_tributo              varchar2   default '',
                        a_anno                      number     default -1,
                        a_pratica_base              number     default -1,
                        a_gruppo_tributo            varchar2   default null)
  return sys_refcursor is
    rc                          sys_refcursor;
  begin
    open rc for
      select
            vers.anno as anno_versamento,
            decode(vers.rata,null,'',to_char(vers.rata)) as rata,
            vers.importo_versato as importo_versato_num,
            sum(nvl(importo_versato,0)) over() as tot_importo_versato_num,
            f_formatta_numero(vers.importo_versato,'I','S') importo_versato,
            f_formatta_numero(sum(nvl(importo_versato,0)) over(),'I','S') tot_importo_versato,
            servizi.gruppo_tributo gruppo_tributo_codice,
            servizi.gruppo_tributo_descr gruppo_tributo_descr
        from
           versamenti vers,
           (select
              grtr.tipo_tributo,
              grtr.gruppo_tributo,
              grtr.descrizione gruppo_tributo_descr,
              f_depag_servizio(grtr.descrizione,'P',null) servizio
            from
              gruppi_tributo grtr) servizi
        where vers.tipo_tributo = a_tipo_tributo
          and vers.cod_fiscale = a_cod_fiscale
          and vers.tipo_tributo = servizi.tipo_tributo (+)
          and vers.servizio = servizi.servizio (+)
          and (
              ((a_pratica_base = -1) and
               (vers.anno = a_anno) and
               (vers.pratica is null) and
               ((a_gruppo_tributo is null)
                or
                ((a_gruppo_tributo is not null) and (servizi.gruppo_tributo = a_gruppo_tributo)))
              )
              or
              ((a_pratica_base <> -1) and
               (vers.pratica = a_pratica_base)
              )
          )
       ;

  return rc;
  end dati_versato;

  -- Riporta elenco pratiche partendo da pratica base
  function pratiche_canoni(a_pratica_base number default -1)
  return sys_refcursor is
    rc                          sys_refcursor;
  begin
    open rc for
      select
        prtr.pratica
      from
        pratiche_tributo prtr,
        oggetti_pratica ogpr,
        (select
            prtrb.data,
            ogprb.oggetto
        from
               pratiche_tributo prtrb,
               oggetti_pratica ogprb
        where
               prtrb.pratica = ogprb.pratica and
               prtrb.pratica = a_pratica_base) ogprb
      where
         prtr.pratica = ogpr.pratica and
         prtr.data = ogprb.data and
         ogpr.oggetto = ogprb.oggetto;

  return rc;
  end pratiche_canoni;

  -- (VD - 26/02/2020): nuova funzione di formattazione campi numerici
  -- (RV - 15/04/2021): Copiato da package STAMPA_COMMON
  -- (RV - 15/04/2021): Aggiunto formati numerici a precisione variabile N0, N1, N2, N3, N4
  -- (RV - 17/05/2021): Aggiunto formato valuta 'V'
  -- (RV - 20/05/2021): Aggiunto formato decimali per D0, D1, D2, D3, D4
  function f_formatta_numero(a_numero    number,
                             a_formato   varchar2,
                             a_null_zero varchar2 default null)
    return varchar2 is
    w_numero_formattato varchar2(20);
    c_formato_importo   varchar2(20) := '99G999G999G990D00';
    c_formato_valuta    varchar2(20) := '99G999G999G990D00L';
    c_formato_n0        varchar2(20) := '99G999G999G990';
    c_formato_n1        varchar2(20) := '99G999G999G990D0';
    c_formato_n2        varchar2(20) := '99G999G999G990D00';
    c_formato_n3        varchar2(20) := '99G999G999G990D000';
    c_formato_n4        varchar2(20) := '99G999G999G990D0000';
    c_formato_d0        varchar2(20) := '99999999990';
    c_formato_d1        varchar2(20) := '99999999990.0';
    c_formato_d2        varchar2(20) := '99999999990.00';
    c_formato_d3        varchar2(20) := '99999999990.000';
    c_formato_d4        varchar2(20) := '99999999990.0000';
    c_formato_perc      varchar2(20) := '990D00';
  begin
    if nvl(a_null_zero, 'N') = 'N' and nvl(a_numero, 0) = 0 then
      w_numero_formattato := '';
    else
      select trim(to_char(nvl(a_numero, 0),
                          decode(a_formato,
                                 'V',
                                 c_formato_valuta,
                                 'I',
                                 c_formato_importo,
                                 'P',
                                 c_formato_perc,
                                 'N0',
                                 c_formato_n0,
                                 'N1',
                                 c_formato_n1,
                                 'N2',
                                 c_formato_n2,
                                 'N3',
                                 c_formato_n3,
                                 'N4',
                                 c_formato_n4,
                                 'D0',
                                 c_formato_d0,
                                 'D1',
                                 c_formato_d1,
                                 'D2',
                                 c_formato_d2,
                                 'D3',
                                 c_formato_d3,
                                 'D4',
                                 c_formato_d4,
                                 ''),
                          'NLS_NUMERIC_CHARACTERS = '',.'''))
        into w_numero_formattato
        from dual;
    end if;
    --
    if a_formato = 'V' then
      w_numero_formattato := substr(w_numero_formattato, 1, length(w_numero_formattato) - 1) || ' ' || substr(w_numero_formattato, -1, 1);
    end if;
    --
    return w_numero_formattato;
    --
  end f_formatta_numero;

end STAMPA_AVVISI_CUNI;
/
