--liquibase formatted sql 
--changeset abrandolini:20250326_152423_calcolo_solleciti_tarsu stripComments:false runOnChange:true 
 
create or replace procedure CALCOLO_SOLLECITI_TARSU
/*******************************************************************************
  NOME:        CALCOLO_SOLLECITI_TARSU
  DESCRIZIONE: Creazione pratiche di sollecito (nuovo tipo_pratica = 'S')
  ANNOTAZIONI:
  REVISIONI:
  Rev.    Date         Author      Note
  007     29/07/2025   RV          #77694
                                   Integrato gestione importi rateizzati Maggiorazione
                                   Tares (Componentio Perequative) per Calcolo Sanzioni
  006     13/06/2025   DM          #81560 - gestite data fine occupazione e cessazione
  005     20/09/2023   VM          #66699 - sostituito filtro ricerca sogg.cognome_nome
                                   con sogg.cognome_nome_ric
  004     03/03/2023   DM          Non si genera il sollecito se per lo stesso anno
                                   ne esiste un altro già notificato o numerato
  003     10/02/2023   DM          Gestione dasta scadenza
  002     25/01/2023   AB          Controllo di presenza di altri solleciti da eliminare
                                   usando il cursore sel_liq
  001     10/01/2023   AB          Salvataggio anno in oggetti_pratica
  000     06/09/2022   VD          Prima emissione.
*******************************************************************************/
( a_tipo_tributo               in        varchar2
 ,a_anno                       in        number
 ,a_cod_fiscale                in        varchar2
 ,a_cognome_nome               in        varchar2
 ,a_ruolo                      in        number
 ,a_tributo                    in        number
 ,a_importo_min                in        number
 ,a_importo_max                in        number
 ,a_se_spese_notifica          in        varchar2
 ,a_data_scadenza              in        date
 ,a_utente                     in        varchar2
 ,a_pratica                    out       number
) is
  w_errore                                varchar2 (2000);
  w_errore_2                              varchar2 (2000);
  errore                                  exception;
  w_ruolo                                 number;
  w_tributo                               number;
  w_importo_min                           number;
  w_importo_max                           number;
  w_cod_istat                             varchar2 (6);
  w_num_prtr                              number;
  w_num_ogpr                              number;
  w_num_ogim                              number;
  w_stringa_rata                          varchar2 (75);
  w_stringa_rata_1                        varchar2 (75);
  w_stringa_rata_2                        varchar2 (75);
  w_stringa_rata_3                        varchar2 (75);
  w_stringa_rata_4                        varchar2 (75);
  w_stringa_magg_tares_rata               varchar2 (15);
  w_stringa_imp_round                     varchar2 (60);
  w_stringa_magg_tares                    varchar2 (60);
  w_scadenza_ricalcolata                  date;
  w_data_cessazione                       date;
  w_fine_occupazione                      date;
  w_tot_rate                              number;
  w_cod_fiscale                           contribuenti.COD_FISCALE%type;
  w_imposta_ricalcolata                   number;
  w_magg_tares_ricalcolata                number;
  w_step                                  number;
  --
  -- (VD - 15/02/2017): aggiunti flag per gestire meglio le segnalazioni di
  --                    errore
  w_flag_segn                             number;
  w_flag_segn_1                           number;
  --
  w_cod_sanzione                          number;
  w_imp_sanzioni                          number;
  cursor sel_liq (
   p_tipo_trib                            varchar2
 , p_anno                                 number
 , p_cod_fiscale                          varchar2
 , p_cognome_nome                         varchar2
 ) is
   select   pratica
       from pratiche_tributo prtr
          , contribuenti cont
          , soggetti sogg
      where prtr.tipo_tributo || '' = p_tipo_trib
        and prtr.anno = p_anno
        and prtr.tipo_pratica = 'S'
--        and prtr.tipo_evento in
--                          ('A', 'U') -- Betta T.: Adesso emettiamo gli acc auto
--                                     -- con tipo evento A
--                                     -- lasciamo U per gestire il pregresso
        and (prtr.tipo_evento = 'A' or
            (prtr.tipo_evento = 'U' and
             substr (prtr.utente, 1, 1) = '#'))
        and prtr.data_notifica is null
        and prtr.numero is null
--        and substr (prtr.utente
--                  , 1
--                  , 1) = '#'
        and prtr.cod_fiscale like p_cod_fiscale
        and cont.cod_fiscale = prtr.cod_fiscale
        and sogg.ni = cont.ni
        and sogg.cognome_nome_ric like p_cognome_nome
   order by 1;
  --
  -- Selezione contribuenti da trattare
  cursor sel_cont ( p_cod_fiscale                          varchar2
                  , p_cognome_nome                         varchar2
                  , p_tipo_tributo                         varchar2
                  , p_anno                                 number
                  , p_ruolo                                number
                  , p_tributo                              number
                  , p_importo_min                          number
                  , p_importo_max                          number
                  ) is
  select imru.cod_fiscale cod_fiscale
       , replace (sogg.cognome_nome,'/',' ') cognome_nome
       , sum(imru.imposta_ruolo) imposta_ruolo
       , sum(sgravio_tot) sgravio_tot
       , nvl(f_tot_vers_cont_ruol(imru.anno
                                 ,imru.cod_fiscale
                                 ,p_tipo_tributo
                                 ,decode(nvl(p_ruolo, 0), 0, null, p_ruolo)
                                 )
            ,0
            )
    from ( select ogim.cod_fiscale
                 ,round(sum(  ogim.imposta
                           + nvl(ogim.addizionale_eca, 0)
                           + nvl(ogim.maggiorazione_eca, 0)
                           + nvl(ogim.addizionale_pro, 0)
                           + nvl(ogim.iva, 0)),0)
                  + round(sum(nvl(ogim.maggiorazione_tares,0)),0)
                    imposta_ruolo
                 ,ogim.ruolo
                 ,ogim.anno
             from pratiche_tributo prtr
                 ,tipi_tributo titr
                 ,codici_tributo cotr
                 ,oggetti_pratica ogpr
                 ,oggetti_imposta ogim
                 ,ruoli ruol
            where titr.tipo_tributo = cotr.tipo_tributo
              and cotr.tributo = ogpr.tributo + 0
              and cotr.tipo_tributo = prtr.tipo_tributo || ''
              and prtr.tipo_tributo || '' = p_tipo_tributo
              and prtr.cod_fiscale || '' = ogim.cod_fiscale
              and prtr.pratica = ogpr.pratica
              and ogpr.oggetto_pratica = ogim.oggetto_pratica
              and ogpr.tributo =
                    decode(p_tributo, -1, ogpr.tributo, p_tributo)
              and ogim.ruolo is not null
              and ogim.flag_calcolo = 'S'
              and ogim.anno = p_anno
              and ogim.ruolo =
                    nvl(nvl(decode(nvl(p_ruolo,0), 0, to_number(''), p_ruolo)
                            ,f_ruolo_totale(ogim.cod_fiscale
                                           ,p_anno
                                           ,p_tipo_tributo
                                           ,p_tributo
                                           ))
                            ,ogim.ruolo
                            )
              and ogim.cod_fiscale like p_cod_fiscale
              and ruol.ruolo = ogim.ruolo
              and ruol.invio_consorzio is not null
         group by ogim.cod_fiscale, ogim.ruolo, ogim.anno) imru
        ,( select sum(nvl(importo, 0)) sgravio_tot
                 ,ruolo
                 ,cod_fiscale
             from sgravi
            where ruolo =
                     nvl(nvl(decode(p_ruolo, 0, to_number(''), p_ruolo)
                            ,f_ruolo_totale(cod_fiscale
                                        ,p_anno
                                        ,p_tipo_tributo
                                        ,p_tributo
                                        ))
                            ,ruolo
                            )
              and cod_fiscale like p_cod_fiscale
         group by cod_fiscale, ruolo) sgra
        , contribuenti cont
        , soggetti     sogg
   where imru.cod_fiscale = cont.cod_fiscale
     and imru.cod_fiscale = sgra.cod_fiscale(+)
     and cont.ni          = sogg.ni
     and cont.cod_fiscale  like nvl(p_cod_fiscale, '%')
     and sogg.cognome_nome_ric like nvl(p_cognome_nome, '%')
     and imru.ruolo = sgra.ruolo(+)
     and not exists (
          select 1
            from pratiche_tributo prt2
           where prt2.tipo_tributo = p_tipo_tributo
             and prt2.anno = p_anno
             and prt2.cod_fiscale = imru.cod_fiscale
             and prt2.tipo_pratica in ('S', 'A')
             and prt2.tipo_evento = 'A'
             and nvl (prt2.stato_accertamento, 'D') = 'D'
             and (prt2.data_notifica is not null
                  or prt2.numero is not null)
                    )
   group by imru.cod_fiscale
          , replace (sogg.cognome_nome,'/',' ')
          , nvl(f_tot_vers_cont_ruol(imru.anno
                                    ,imru.cod_fiscale
                                    ,p_tipo_tributo
                                    ,decode(nvl(p_ruolo, 0), 0, null, p_ruolo)
                                    )
               ,0
               )
  having sum(imru.imposta_ruolo) -
         nvl(f_tot_vers_cont_ruol(imru.anno
                                 ,imru.cod_fiscale
                                 ,p_tipo_tributo
                                 ,decode(nvl(p_ruolo, 0), 0, null, p_ruolo)
                                 )
            ,0
            ) -
         nvl(sum(sgravio_tot), 0) between nvl(p_importo_min, 0)
                                      and nvl(p_importo_max, 9999999999999999);
--
-- Pratiche.
--
 cursor sel_prat ( p_cod_fiscale                          varchar2
                 , p_tipo_trib                            varchar2
                 , p_anno                                 number) is
  select   ogco.cod_fiscale cod_fiscale
         , ogpr.oggetto_pratica oggetto_pratica
         , nvl (ogpr.oggetto_pratica_rif, ogpr.oggetto_pratica) oggetto_pratica_rif
         , decode (prtr.tipo_evento,'V',ogpr.oggetto_pratica,null) oggetto_pratica_rif_v
         , ogpr.oggetto oggetto
         , prtr.pratica pratica
         , prtr.data data
         , prtr.numero numero
         , prtr.anno anno
         , prtr.tipo_pratica tipo_pratica
         , prtr.tipo_evento tipo_evento
         , ogpr.tipo_occupazione tipo_occupazione
         , ogim.imposta
           - nvl (round (F_SGRAVIO_OGIM (p_cod_fiscale,p_anno,p_tipo_trib,ogpr.oggetto_pratica,ogim.oggetto_imposta,'S'),2),0)
                                                  imposta
         , nvl(round (F_SGRAVIO_OGIM (p_cod_fiscale,p_anno,p_tipo_trib,ogpr.oggetto_pratica,ogim.oggetto_imposta,'SMG'),2),0)
                                                  sgravio_compensazione
         , nvl(round (F_SGRAVIO_OGIM (p_cod_fiscale,p_anno,p_tipo_trib,ogpr.oggetto_pratica,ogim.oggetto_imposta,'S','maggiorazione_tares'),2),0)
                                                  sgravio_tares
         , ogim.addizionale_eca - nvl(round(F_SGRAVIO_OGIM(p_cod_fiscale,p_anno,p_tipo_trib,ogpr.oggetto_pratica,ogim.oggetto_imposta,'S','addizionale_eca'),2),0) addizionale_eca
         , ogim.maggiorazione_eca - nvl(round(F_SGRAVIO_OGIM(p_cod_fiscale,p_anno,p_tipo_trib,ogpr.oggetto_pratica,ogim.oggetto_imposta,'S','maggiorazione_eca'),2),0) maggiorazione_eca
         , ogim.addizionale_pro - nvl(round(F_SGRAVIO_OGIM(p_cod_fiscale,p_anno,p_tipo_trib,ogpr.oggetto_pratica,ogim.oggetto_imposta,'S','addizionale_pro'),2),0) addizionale_pro
         , ogim.iva - nvl(round(F_SGRAVIO_OGIM(p_cod_fiscale,p_anno,p_tipo_trib,ogpr.oggetto_pratica,ogim.oggetto_imposta,'S','iva'),2),0) iva
         , ogim.maggiorazione_tares - nvl(round(F_SGRAVIO_OGIM(p_cod_fiscale,p_anno,p_tipo_trib,ogpr.oggetto_pratica,ogim.oggetto_imposta,'S','maggiorazione_tares'),2),0) maggiorazione_tares
         , ogim.ruolo
         , round(  nvl(ogim.imposta,0)
                 + nvl(ogim.addizionale_eca,0)
                 + nvl(ogim.maggiorazione_eca,0)
                 + nvl(ogim.addizionale_pro,0)
                 + nvl(ogim.iva,0)
                 + nvl(ogim.maggiorazione_tares,0)
           , 0) ogim_imposta_round
         , ogim.oggetto_imposta oggetto_imposta
         , nvl(ruol.rate,0) num_rate
         , 0 delta_rate                  --f_delta_rate(ogim.ruolo) delta_rate
         , ruol.tipo_ruolo
         , ruol.tipo_emissione
         , ruol.invio_consorzio
         , decode (ruol.tipo_calcolo, 'N', 'S', null) flag_normalizzato
         , ogco.flag_ab_principale
         , ogim.dettaglio_ogim
         -- (VD - 17/04/2019): aggiunti campi relativi al calcolo con tariffa
         , ogim.tipo_tariffa_base
         , ogim.imposta_base
         , ogim.addizionale_eca_base
         , ogim.maggiorazione_eca_base
         , ogim.addizionale_pro_base
         , ogim.iva_base
         , ogim.dettaglio_ogim_base
         , ogim.perc_riduzione_pf
         , ogim.perc_riduzione_pv
         , ogim.importo_riduzione_pf
         , ogim.importo_riduzione_pv
      from oggetti_pratica ogpr
         , oggetti_contribuente ogco
         , oggetti_imposta ogim
         , ruoli ruol
         , pratiche_tributo prtr
     where ogco.cod_fiscale = ogim.cod_fiscale
       and prtr.pratica = ogpr.pratica
       and ogco.oggetto_pratica = ogpr.oggetto_pratica
       and ogim.oggetto_pratica = ogco.oggetto_pratica
       and ogim.anno = p_anno
       and ogim.cod_fiscale = p_cod_fiscale
       and ogim.tipo_tributo || '' = p_tipo_trib
       and decode (prtr.tipo_pratica
                 , 'A', prtr.anno
                 , p_anno - 1) <> p_anno
       and decode (prtr.tipo_pratica
                 , 'A', prtr.flag_denuncia
                 , 'S') = 'S'
       and nvl (prtr.stato_accertamento, 'D') = 'D'
       and ruol.ruolo(+) = ogim.ruolo
       and nvl (ruol.importo_lordo, 'N') = 'S'
       and ruol.invio_consorzio is not null
       and not exists (
            select 1
              from pratiche_tributo prt2
             where prt2.tipo_tributo = p_tipo_trib
               and prt2.anno = p_anno
               and prt2.cod_fiscale = ogco.cod_fiscale
               and prt2.tipo_pratica = 'A'
               and prt2.tipo_evento = 'A'
               and nvl (prt2.stato_accertamento, 'D') = 'D'
               and (prt2.data_notifica is not null
                    or prt2.numero is not null)
                      )
  order by 1
         , 2;
--
-- Rate Imposta degli Oggetti.
--
 cursor sel_raim ( p_oggetto_imposta                      number
                 , p_imposta_totale                       number) is
  select  raim.rata
        , raim.imposta
        , raim.addizionale_eca
        , raim.maggiorazione_eca
        , raim.addizionale_pro
        , raim.iva
        , raim.imposta_round
        , case when raim.magg_tares_rate = 0 then
              -- Rate senza Maggiorazione TARES (Vecchio Calcolo)
            case when raim.rata = raim.max_rata then
                -- Ultima rata, tutta la TARES dell'ogim
                raim.magg_tares_ogim
            else
              -- Non ultima, zero TARES
              0
            end
          else
            -- Rate con Maggiorazione TARES, prende quella
            raim.maggiorazione_tares
          end maggiorazione_tares
  from (
       select raim.rata
            , raim.imposta
            , raim.addizionale_eca
            , raim.maggiorazione_eca
            , raim.addizionale_pro
            , raim.iva
            , raim.imposta_round
            , raim.maggiorazione_tares
            --
            , max(raim.rata) over() as max_rata
            , ogim.maggiorazione_tares as magg_tares_ogim
            , sum(decode(raim.maggiorazione_tares,null,0,1)) over() as magg_tares_rate
         from rate_imposta raim,
              oggetti_imposta ogim
        where ogim.oggetto_imposta = raim.oggetto_imposta
          and raim.oggetto_imposta = p_oggetto_imposta
          and p_imposta_totale >= 0
       ) raim
  order by raim.rata
  ;
--
-- Determinazione degli Accertamenti che devono essere eliminati
-- per non avere raggiunto il limite.
--
-- (VD - 10/12/2014): modificato calcolo importo totale per pratica
--                    ricavandolo dalla relativa window PB
--
 cursor sel_prat_elim (
  p_limite_inf                           number
, p_limite_sup                           number
, p_tipo_trib                            varchar2
, p_anno                                 number
, p_cod_fiscale                          varchar2
, p_cognome_nome                         varchar2) is
  select   prtr.pratica
         , sapr.importo_totale
      from pratiche_tributo prtr
         , contribuenti cont
         , soggetti sogg
         , (select sapr.pratica
                 , nvl(sum(sapr.importo + decode(f_get_flag_ruolo (sapr.pratica)
                      ,'S',decode(decode (sanz.cod_sanzione,  1, 1,  100, 1,  101, 1,
                                   decode (sanz.tipo_causale||nvl(sanz.flag_magg_tares,'N'), 'EN', 1, 0))
                          ,1,decode(nvl(cata.flag_lordo,'N')
                            ,'S',  round(sapr.importo * nvl(cata.addizionale_eca,0)   / 100,2)
                                   + round(sapr.importo * nvl(cata.maggiorazione_eca,0) / 100,2)
                                   + round(sapr.importo * nvl(cata.addizionale_pro,0)   / 100,2)
                                   + round(sapr.importo * nvl(cata.aliquota,0)          / 100,2)
                                   ,0
                                   )
                              ,0)
                            ,0
                          )),0
                          ) importo_totale
                from sanzioni_pratica sapr
                   , pratiche_tributo prtr
                   , carichi_tarsu cata
                   , sanzioni sanz
               where prtr.pratica = sapr.pratica
                 and cata.anno = prtr.anno
                 and prtr.tipo_tributo || '' = p_tipo_trib
                 and prtr.anno = p_anno
                 and prtr.tipo_pratica = 'A'
                 and prtr.tipo_evento = 'A'
                 and prtr.data_notifica is null
                 and prtr.numero is null
                 and sapr.cod_sanzione = sanz.cod_sanzione
                 and sapr.sequenza_sanz = sanz.sequenza
                 and sanz.tipo_tributo = p_tipo_trib
                 and substr (prtr.utente,1,1) = '#'
            group by sapr.pratica) sapr
     where nvl(sapr.importo_totale,0) not between nvl(p_limite_inf,-999999999.99) and nvl(p_limite_sup,999999999.99)
       and prtr.tipo_tributo || '' = p_tipo_trib
       and prtr.anno = p_anno
       and prtr.tipo_pratica = 'A'
       and prtr.tipo_evento = 'A'
       and prtr.data_notifica is null
       and prtr.numero is null
       and substr (prtr.utente,1,1) = '#'
       and prtr.cod_fiscale like nvl (p_cod_fiscale, '%')
       and cont.cod_fiscale = prtr.cod_fiscale
       and sogg.ni = cont.ni
       and sogg.cognome_nome_ric like nvl (p_cognome_nome, '%')
       and sapr.pratica(+) = prtr.pratica
  order by 1;
/*
  La funzione vuole riportare i valori dei principali o suppletivi TOTALI
  come fassero dei principali o suppletivi a saldo. Quindi
  se p_ruolo PRINCIPALE ACCONTO, non fa nulla
  se p_ruolo PRINCIPALE SALDO, non fa nulla
  se p_ruolo SUPPLETIVO SALDO, non fa nulla
  se p_ruolo PRINCIPALE TOTALE, imposta del ruolo + versamenti precedenti - imposta acconto
  se p_ruolo SUPPLETIVO TOTALE, imposta del ruolo + versamenti precedenti - imposta ruoli precedenti
*/
 procedure RICALCOLO_IMPOSTA ( p_cf                                   varchar2
                             , p_ruolo                                number
                             , p_anno                                 number
                             , p_ogpr                                 number
                             , p_dal                                  date
                             , p_al                                   date
                             , p_norm                                 varchar2
                             , p_tipo_ruolo                           number
                             , p_tipo_emissione                       varchar2
                             , p_imposta                    in out    number
                             , p_magg_eca                   in out    number
                             , p_add_eca                    in out    number
                             , p_add_pro                    in out    number
                             , p_iva                        in out    number
                             , p_magg_tares                 in out    number)
is
  dep_imposta                             number;
  dep_importo_pv                          number;           --parte fissa
  dep_importo_pf                          number;           --parte variabile
  dep_magg_tares_scalare                  number;
  dep_addizionale_pro                     number;
  dep_addizionale_eca                     number;
  dep_maggiorazione_eca                   number;
  dep_aliquota                            number;
  dep_flag_magg_anno                      number;
 begin
   begin
    select nvl (addizionale_pro, 0)
         , nvl (addizionale_eca, 0)
         , nvl (maggiorazione_eca, 0)
         , nvl (aliquota, 0)
         , flag_magg_anno
      into dep_addizionale_pro
         , dep_addizionale_eca
         , dep_maggiorazione_eca
         , dep_aliquota
         , dep_flag_magg_anno
      from carichi_tarsu
     where anno = p_anno;
   exception
    when no_data_found then
     dep_addizionale_pro := 0;
     dep_addizionale_eca := 0;
     dep_maggiorazione_eca := 0;
     dep_aliquota := 0;
     dep_flag_magg_anno := null;
    when others then
     w_errore := 'Errore in ricerca Carichi Tarsu';
     raise errore;
   end;
 -- DBMS_OUTPUT.PUT_LINE('p_ogpr '||p_ogpr||' p_imposta '||p_imposta);
 -- DBMS_OUTPUT.PUT_LINE('p_ogpr '||p_ogpr||' p_dal '||p_dal);
 -- DBMS_OUTPUT.PUT_LINE('p_ogpr '||p_ogpr||' p_al '||p_al);
 -- DBMS_OUTPUT.PUT_LINE('p_ogpr '||p_ogpr||' dep_flag_magg_anno '||dep_flag_magg_anno);
 -- DBMS_OUTPUT.PUT_LINE('p_ogpr '||p_ogpr||' p_norm '||p_norm);
 -- DBMS_OUTPUT.PUT_LINE('p_ogpr '||p_ogpr||' p_anno '||p_anno);
 -- per ruoli in acconto o principale a saldo
 -- o suppletivo a saldo non si modifica nulla.
   if p_tipo_emissione = 'T' and p_tipo_ruolo = 2 then
      IMPORTI_RUOLO_TOTALE (p_ruolo
                          , p_cf
                          , p_anno
                          , p_dal
                          , p_al
                          , 'TARSU'
                          , dep_flag_magg_anno
                          , p_ogpr
                          , p_norm
                          , dep_imposta
                          , dep_importo_pv
                          , dep_importo_pf
                          , dep_magg_tares_scalare);
      -- DBMS_OUTPUT.PUT_LINE('DOPO p_ogpr '||p_ogpr||' dep_imposta '||dep_imposta);
      p_imposta := p_imposta - dep_imposta;
      -- DBMS_OUTPUT.PUT_LINE('DOPO p_ogpr '||p_ogpr||' p_imposta '||p_imposta);
      p_magg_tares := p_magg_tares - dep_magg_tares_scalare;
      p_magg_eca := round ((p_imposta * dep_maggiorazione_eca) / 100, 2);
      p_add_eca := round ((p_imposta * dep_addizionale_eca) / 100, 2);
      p_add_pro := round ((p_imposta * dep_addizionale_pro) / 100, 2);
      p_iva := round ((p_imposta * dep_aliquota) / 100, 2);
   end if;
 end RICALCOLO_IMPOSTA;
/*----------------------------------------------------*/
 function F_RICALCOLO_SCADENZA (p_ruolo number)
 return date
 is
 w_scadenza                    date := to_date('31122999','ddmmyyyy');
 begin
   begin
     select nvl (ruol.SCADENZA_RATA_4
               , nvl (ruol.SCADENZA_RATA_3
                    , nvl (ruol.SCADENZA_RATA_2
                         , nvl (ruol.SCADENZA_PRIMA_RATA
                              , to_date ('31122999', 'ddmmyyyy')))))
       into w_scadenza
       from ruoli ruol
      where ruol.ruolo = p_ruolo;
   exception
     when no_data_found then
       w_scadenza := to_date ('31122999', 'ddmmyyyy');
   end;
   return w_scadenza;
 end;
/*----------------------------------------------------*/
 function F_EXISTS_RUOLO_SUCCESSIVO_TOT
( p_cod_fiscale                          varchar2
, p_invio_consorzio                      date
, p_ruolo                                number
, p_tipo_ruolo                           number
, p_tipo_emissione                       varchar2)
  return number
is
  dep_ret                                 number := 0;
 begin
  select count (distinct ruol.ruolo)
    into dep_ret
    from oggetti_contribuente ogco
       , oggetti_imposta ogim
       , ruoli ruol
   where ogim.oggetto_pratica = ogco.oggetto_pratica
     and ogco.cod_fiscale = p_cod_fiscale
     and ogim.anno = a_anno
     and ogim.tipo_tributo = a_tipo_tributo
     and ruol.tipo_ruolo >=   -- Aggiunto il > per poter trattare anche i suppletivi Totali nel caso un cf non sia presente nel princ totale  AB (15/06/2017)
         decode (p_tipo_ruolo || ' ' || p_tipo_emissione
               , '1 A', 1
               , '1 T', 2
               , '2 T', 2)
     and nvl (ruol.tipo_emissione, 'T') = 'T'
     and ruol.ruolo != p_ruolo
     and ruol.anno_ruolo = a_anno
     and ruol.ruolo(+) = ogim.ruolo
     and ruol.tipo_tributo(+) = ogim.tipo_tributo
     and nvl (ruol.importo_lordo, 'N') = 'S'
     and ruol.invio_consorzio is not null
     and ruol.invio_consorzio > p_invio_consorzio
     and not exists (
         select 1
           from pratiche_tributo prt2
          where prt2.tipo_tributo = a_tipo_tributo
            and prt2.anno = a_anno
            and prt2.cod_fiscale = ogco.cod_fiscale
            and prt2.tipo_pratica = 'A'
            and prt2.tipo_evento = 'A'
            and nvl (prt2.stato_accertamento, 'D') = 'D'
            and (prt2.data_notifica is not null
                 or prt2.numero is not null));
  return dep_ret;
 exception
   when no_data_found then
     dep_ret := 0;
     return dep_ret;
   when others then
     raise;
 end F_EXISTS_RUOLO_SUCCESSIVO_TOT;
/*----------------------------------------------------*/
/*         CHECK ACC AUTOMATICO TARSU                 */
/*----------------------------------------------------*/
 procedure CHECK_ACC_AUTOMATICO_TARSU
( a_tipo_tributo               in        varchar2
, a_anno                       in        number
, a_cod_fiscale                in        varchar2
, a_cognome_nome               in        varchar2
, a_cod_istat                  in        varchar2
) is
 begin
  w_errore := null;
  w_errore_2 := null;
--
-- Trattamento Contribuenti.
--
  for rec_cont in sel_cont (a_cod_fiscale
                          , a_cognome_nome
                          , a_tipo_tributo
                          , a_anno
                          , w_ruolo
                          , w_tributo
                          , w_importo_min
                          , w_importo_max
                          )
  loop
    w_cod_fiscale := rec_cont.cod_fiscale;
    w_flag_segn := 0;
    w_flag_segn_1 := 0;
    --Trattamento Pratiche di un Contribuente.
    for rec_prat in sel_prat (w_cod_fiscale
                            , a_tipo_tributo
                            , a_anno)
    loop
      --
      -- 24/04/2015 (VD/PM): per evitare l'errore di check constraint in inserimento
      --                     OGGETTI_IMPOSTA si escludono gli importi < zero
      --
      -- (VD - 15/02/2017): w_flag_segn serve per evitare di inserire piu' volte
      --                    lo stesso codice fiscale qualora ci siano piu'
      --                    imposte negative
      --
      if rec_prat.imposta < 0
         or rec_prat.maggiorazione_tares < 0 then
         if nvl (length (w_errore_2), 0) < 1900 then
            if w_flag_segn = 0 then
               w_errore_2 :=
                   nvl (w_errore_2, ' ')
                || chr (10)
                || chr (13)
                || rec_cont.cognome_nome
                || ' '
                || w_cod_fiscale;
               w_flag_segn := 1;
            end if;
         end if;
      -- SE è UN ACCONTO SEGUITO DA RUOLO TOTALE, CONTROLLO SOLO IL TOTALE.
      elsif (rec_prat.tipo_ruolo = 1
             and rec_prat.tipo_emissione = 'A'
             and f_exists_ruolo_successivo_tot (rec_prat.cod_fiscale
                                              , rec_prat.invio_consorzio
                                              , rec_prat.ruolo
                                              , rec_prat.tipo_ruolo
                                              , rec_prat.tipo_emissione) >= 1)
            or (rec_prat.tipo_emissione = 'T'
                and f_exists_ruolo_successivo_tot (rec_prat.cod_fiscale
                                                 , rec_prat.invio_consorzio
                                                 , rec_prat.ruolo
                                                 , rec_prat.tipo_ruolo
                                                 , rec_prat.tipo_emissione) >= 1) then
         null;
      else
         -- se il ruolo è suppletivo mi comporto sempre come se
         -- avessi solo la rata 0.
         if rec_prat.num_rate = 0
            or (rec_prat.imposta = 0
                and nvl (rec_prat.maggiorazione_tares, 0) > 0)
                                                              /*or (rec_prat.tipo_ruolo = 2  and rec_prat.tipo_emissione = 'T')*/
         then
            null;
         else
            select count (*)
              into w_tot_rate
              from rate_imposta raim
             where raim.oggetto_imposta = rec_prat.oggetto_imposta
               and rec_prat.imposta >= 0;
            if w_tot_rate = 0 then
                if nvl(length(w_errore),0) < 1900 then
                   --
                   -- (VD - 15/02/2017): w_flag_segn serve per evitare di inserire piu volte
                   --                    lo stesso codice fiscale qualora manchino le rate
                   --                    per piu oggetti imposta
                   --
                   if w_flag_segn_1 = 0 then
                      w_errore :=
                          nvl (w_errore, ' ')
                       || chr (10)
                       || chr (13)
                       || rec_cont.cognome_nome
                       || ' '
                       || w_cod_fiscale;
                      w_flag_segn_1 := 1;
                   end if;
                end if;
            end if;
         end if;
      end if;
    end loop;
  end loop;
--
  if nvl (w_errore, ' ') <> ' ' then
     w_errore := 'Rate non presenti per i contribuenti: ' || w_errore;
  end if;
--
  if nvl (w_errore_2, ' ') <> ' ' then
     w_errore_2 := 'Sgravi errati per i contribuenti: ' || w_errore_2;
  end if;
--
  if nvl (w_errore, ' ') <> ' '
     or nvl (w_errore_2, ' ') <> ' ' then
     w_cod_fiscale := null;
     w_tot_rate := null;
     raise errore;
  end if;
  w_errore := null;
  w_errore_2 := null;
  w_tot_rate := null;
  w_cod_fiscale := null;
 exception
   when ERRORE then
     RAISE_APPLICATION_ERROR (-20999
                            , w_errore || chr (10) || chr (13) || w_errore_2);
   when others then
     rollback;
     RAISE_APPLICATION_ERROR (-20999
                            , w_step || ' ' || w_cod_fiscale || ' ' || sqlerrm);
 end CHECK_ACC_AUTOMATICO_TARSU;
--
--------------------------------------------------------
--         CALCOLO SOLLECITO TARSU                    --
--------------------------------------------------------
--
begin
  w_errore := null;
  w_ruolo := nvl(a_ruolo,0);
  w_tributo := nvl(a_tributo,-1);
  w_importo_min := a_importo_min;
  w_importo_max := a_importo_max;
  begin
    select lpad(to_char(d.pro_cliente),3,'0')||
           lpad(to_char(d.com_cliente),3,'0')
      into w_cod_istat
      from dati_generali d;
  exception
    when no_data_found then
      w_errore := 'Dati Generali non inseriti';
      raise errore;
    when others then
      w_errore := 'Errore in ricerca Dati Generali';
      raise errore;
  end;
  check_acc_automatico_tarsu (a_tipo_tributo
                            , a_anno
                            , a_cod_fiscale
                            , a_cognome_nome
                            , w_cod_istat);
  for rec_liq in sel_liq (a_tipo_tributo
                        , a_anno
                        , a_cod_fiscale
                        , a_cognome_nome)
  loop
    begin
      --Eliminando la Pratica vengono eliminate anche tutte
      --le dipendenze in cascata via Trigger.
      delete from pratiche_tributo prtr
            where prtr.pratica = rec_liq.pratica;
    end;
  end loop;
--
-- Trattamento Contribuenti.
--
  for rec_cont in sel_cont (a_cod_fiscale
                          , a_cognome_nome
                          , a_tipo_tributo
                          , a_anno
                          , w_ruolo
                          , w_tributo
                          , w_importo_min
                          , w_importo_max
                          )
  loop
    w_cod_fiscale := rec_cont.cod_fiscale;
    w_step := 1;
    begin
      w_num_prtr := null;
      pratiche_tributo_nr (w_num_prtr);
      insert into pratiche_tributo ( pratica
                                   , cod_fiscale
                                   , tipo_tributo
                                   , anno
                                   , tipo_pratica
                                   , tipo_evento
                                   , data
                                   , pratica_rif
                                   , flag_adesione
                                   , utente
                                   , data_scadenza
                                   )
      values ( w_num_prtr
             , rec_cont.cod_fiscale
             , a_tipo_tributo
             , a_anno
             , 'S'
             , 'A'
             , trunc (sysdate)
             , null
             , null
             , '#'||substr(a_utente,1,7)
             , a_data_scadenza
             );
    end;
    w_step := 2;
    begin
      insert into rapporti_tributo ( pratica
                                   , sequenza
                                   , cod_fiscale
                                   , tipo_rapporto
                                   )
      values ( w_num_prtr
             , 1
             , rec_cont.cod_fiscale
             , 'E'
             );
    end;
    w_step := 3;
    --Trattamento Pratiche di un Contribuente.
    for rec_prat in sel_prat (rec_cont.cod_fiscale,a_tipo_tributo,a_anno)
    loop
      -- SE è UN ACCONTO SEGUITO DA RUOLO TOTALE, CONTROLLO SOLO IL TOTALE.
      if (rec_prat.tipo_ruolo = 1
          and rec_prat.tipo_emissione = 'A'
          and f_exists_ruolo_successivo_tot (rec_prat.cod_fiscale
                                           , rec_prat.invio_consorzio
                                           , rec_prat.ruolo
                                           , rec_prat.tipo_ruolo
                                           , rec_prat.tipo_emissione) >= 1)
         or (rec_prat.tipo_emissione = 'T'
             and f_exists_ruolo_successivo_tot (rec_prat.cod_fiscale
                                              , rec_prat.invio_consorzio
                                              , rec_prat.ruolo
                                              , rec_prat.tipo_ruolo
                                              , rec_prat.tipo_emissione) >= 1) then
         --dbms_output.put_line(' passo a ruolo successivo di '||rec_prat.ruolo);
         null;
      else
         --dbms_output.put_line('Trattamento pratica');
         w_step := 99;
         begin
           w_num_ogpr := null;
           oggetti_pratica_nr (w_num_ogpr);
           insert into oggetti_pratica
                       (oggetto_pratica
                      , oggetto
                      , pratica
                      , consistenza
                      , tributo
                      , categoria
                      , anno
                      , tipo_tariffa
                      , tipo_occupazione
                      , data_concessione
                      , oggetto_pratica_rif
                      , oggetto_pratica_rif_v
                      , utente)
            select w_num_ogpr
                 , ogpr.oggetto
                 , w_num_prtr
                 , ogpr.consistenza
                 , ogpr.tributo
                 , ogpr.categoria
                 , a_anno
                 , ogpr.tipo_tariffa
                 , ogpr.tipo_occupazione
                 , null
                 , rec_prat.oggetto_pratica_rif
                 , rec_prat.oggetto_pratica_rif_v
                 , a_utente
              from oggetti_pratica ogpr
             where ogpr.oggetto_pratica = rec_prat.oggetto_pratica;
         end;
         w_step := 4;
         begin
           begin
            select ogco_cess.data_cessazione, ogco_cess.fine_occupazione
              into w_data_cessazione, w_fine_occupazione
              from pratiche_tributo     prtr_cess,
                   oggetti_pratica      ogpr_cess,
                   oggetti_contribuente ogco_cess
             where prtr_cess.pratica = ogpr_cess.pratica
               and ogpr_cess.oggetto_pratica = ogco_cess.oggetto_pratica
               and ogco_cess.cod_fiscale = rec_cont.cod_fiscale
               and ogpr_cess.oggetto_pratica_rif =
                   rec_prat.oggetto_pratica_rif
               and prtr_cess.tipo_pratica = 'D'
               and prtr_cess.tipo_evento = 'C';
            exception
              when no_data_found then
                w_data_cessazione := null;
                w_fine_occupazione := null;
            end;

          insert into oggetti_contribuente
                      (cod_fiscale
                     , oggetto_pratica
                     , anno
                     , tipo_rapporto
                     , inizio_occupazione
                     , fine_occupazione
                     , data_decorrenza
                     , data_cessazione
                     , perc_possesso
                     , flag_ab_principale
                     , utente)
           select rec_prat.cod_fiscale
                , w_num_ogpr
                , a_anno
                , ogco.tipo_rapporto
                , ogco.inizio_occupazione
                , nvl(ogco.fine_occupazione, w_fine_occupazione)
                , ogco.data_decorrenza
                , nvl(ogco.data_cessazione, w_data_cessazione)
                , ogco.perc_possesso
                , ogco.flag_ab_principale
                , a_utente
             from oggetti_contribuente ogco
            where ogco.oggetto_pratica = rec_prat.oggetto_pratica
              and ogco.cod_fiscale = rec_cont.cod_fiscale;
         end;
         w_step := 5;
         w_stringa_rata_1 := rpad('0',75,'0');
         w_stringa_rata_2 := rpad('0',75,'0');
         w_stringa_rata_3 := rpad('0',75,'0');
         w_stringa_rata_4 := rpad('0',75,'0');
         w_stringa_magg_tares := rpad('0',60,'0');
       --dbms_output.put_line('Num Rate: '||rec_prat.num_rate);
         -- se il ruolo è suppletivo mi comporto sempre come se
         -- avessi solo la rata 0.
         w_tot_rate := null;
         w_scadenza_ricalcolata := null;
         --
         w_imposta_ricalcolata := rec_prat.imposta;
         w_magg_tares_ricalcolata := nvl (rec_prat.maggiorazione_tares, 0);
       --dbms_output.put_line('Imposta: '||w_imposta_ricalcolata||', TARES: '||w_magg_tares_ricalcolata);
         --
       --dbms_output.put_line('Rate: '||rec_prat.num_rate);
         if rec_prat.num_rate = 0
            /*or (rec_prat.tipo_ruolo = 2  and rec_prat.tipo_emissione = 'T')*/ then
            declare
              w_magg_eca                              number;
              w_add_eca                               number;
              w_add_pro                               number;
              w_iva                                   number;
              w_magg_tares                            number;
            begin
              w_scadenza_ricalcolata := f_ricalcolo_scadenza (rec_prat.ruolo);
              if w_scadenza_ricalcolata < trunc (sysdate) then
                 w_tot_rate := 0;
                 w_magg_eca := nvl (rec_prat.maggiorazione_eca, 0);
                 w_add_eca := nvl (rec_prat.addizionale_eca, 0);
                 w_add_pro := nvl (rec_prat.addizionale_pro, 0);
                 w_iva := nvl (rec_prat.iva, 0);
                 w_magg_tares := rec_prat.maggiorazione_tares;
                 --
                 -- (RV - 21/05/2025): Dettaglio formato w_stringa_rata e w_stringa_rata_x
                 --
                 -- w_stringa_rata :=  lpad(to_char((nvl(w_imposta_ricalcolata,0)) * 100),15,'0')
                 --                 || lpad(to_char(nvl(w_add_eca,0) * 100),15,'0')
                 --                 || lpad(to_char(nvl(w_magg_eca,0) * 100),15,'0')
                 --                 || lpad(to_char(nvl(w_add_pro,0) * 100),15,'0')
                 --                 || lpad(to_char(nvl(w_iva,0) * 100),15,'0');
                 --
                 -- (VD - 09/03/2020): per gestire correttamente gli importi negativi
                 --                    si compone prima una stringa generica per rata:
                 --                    se l'importo è negativo si allinea a destra
                 --                    il valore assoluto e gli si antepone il
                 --                    segno "-".
                 --
                 if nvl(w_imposta_ricalcolata,0) < 0 then
                    w_stringa_rata_1 := '-' || lpad(to_char(abs(nvl(w_imposta_ricalcolata,0)) * 100),14,'0');
                 else
                    w_stringa_rata_1 := lpad(to_char(nvl(w_imposta_ricalcolata,0) * 100),15,'0');
                 end if;
                 if nvl(w_add_eca,0) < 0 then
                    w_stringa_rata_1 := w_stringa_rata_1 || '-' || lpad(to_char(abs(nvl(w_add_eca,0)) * 100),14,'0');
                 else
                    w_stringa_rata_1 := w_stringa_rata_1 || lpad(to_char(nvl(w_add_eca,0) * 100),15,'0');
                 end if;
                 if nvl(w_magg_eca,0) < 0 then
                    w_stringa_rata_1 := w_stringa_rata_1 || '-' || lpad(to_char(abs(nvl(w_magg_eca,0)) * 100),14,'0');
                 else
                    w_stringa_rata_1 := w_stringa_rata_1 || lpad(to_char(nvl(w_magg_eca,0) * 100),15,'0');
                 end if;
                 if nvl(w_add_pro,0) < 0 then
                    w_stringa_rata_1 := w_stringa_rata_1 || '-' || lpad(to_char(abs(nvl(w_add_pro,0)) * 100),14,'0');
                 else
                    w_stringa_rata_1 := w_stringa_rata_1 || lpad(to_char(nvl(w_add_pro,0) * 100),15,'0');
                 end if;
                 if nvl(w_iva,0) < 0 then
                    w_stringa_rata_1 := w_stringa_rata_1 || '-' || lpad(to_char(abs(nvl(w_iva,0)) * 100),14,'0');
                 else
                    w_stringa_rata_1 := w_stringa_rata_1 || lpad(to_char(nvl(w_iva,0) * 100),15,'0');
                 end if;
                 if w_cod_istat in ('037058','015175','012083','090049','097049','091055','042030') then
                    w_stringa_imp_round := lpad(to_char(nvl(rec_prat.ogim_imposta_round,0) * 100),15,'0');
                 else
                    w_stringa_imp_round := rpad(' ',15);
                 end if;
                 -- (RV - 21/05/2025): Nuova stringa importi Maggiorazione Tares (Componenti Perequative)
                 if nvl(w_magg_tares,0) < 0 then
                    w_stringa_magg_tares := '-' || lpad(to_char(abs(nvl(w_magg_tares,0)) * 100),14,'0');
                 else
                    w_stringa_magg_tares := lpad(to_char(nvl(w_magg_tares,0) * 100),15,'0');
                 end if;
              else
                 w_errore := 'Sollecito non effettuabile: il ruolo '
                          || rec_prat.ruolo
                          || ' scade in data '
                          || to_char (w_scadenza_ricalcolata, 'dd/mm/yyyy')
                          || ', successiva alla data odierna.';
                 raise errore;
              end if;
            end;
            w_step := 6;
         else
            for rec_raim in sel_raim (rec_prat.oggetto_imposta, rec_prat.imposta)
            loop
            --dbms_output.put_line('  Rata: '||rec_raim.rata||', Imposta: '||rec_raim.imposta||', Magg.TARES: '||rec_raim.maggiorazione_tares);
              w_stringa_rata   := rpad('0',75,'0');
              if rec_raim.imposta < 0 then
                 w_stringa_rata := '-' || lpad(to_char(abs(rec_raim.imposta) * 100),14,'0');
              else
                 w_stringa_rata := lpad(to_char(rec_raim.imposta * 100),15,'0');
              end if;
              if nvl (rec_raim.addizionale_eca, 0) < 0 then
                 w_stringa_rata := w_stringa_rata || '-' || lpad (to_char (abs (nvl (rec_raim.addizionale_eca, 0)) * 100),14,'0');
              else
                 w_stringa_rata := w_stringa_rata ||lpad (to_char (nvl (rec_raim.addizionale_eca, 0) * 100),15,'0');
              end if;
              if nvl (rec_raim.maggiorazione_eca, 0) < 0 then
                 w_stringa_rata := w_stringa_rata || '-' || lpad (to_char (abs (nvl (rec_raim.maggiorazione_eca, 0)) * 100),14,'0');
              else
                 w_stringa_rata := w_stringa_rata || lpad (to_char (nvl (rec_raim.maggiorazione_eca, 0) * 100),15,'0');
              end if;
              if nvl (rec_raim.addizionale_pro, 0) < 0 then
                 w_stringa_rata := w_stringa_rata || '-' || lpad (to_char (abs (nvl (rec_raim.addizionale_pro, 0)) * 100),14,'0');
              else
                 w_stringa_rata := w_stringa_rata || lpad (to_char (nvl (rec_raim.addizionale_pro, 0) * 100),15,'0');
              end if;
              if nvl (rec_raim.iva, 0) < 0 then
                 w_stringa_rata := w_stringa_rata || '-' || lpad (to_char (abs (nvl (rec_raim.iva, 0)) * 100),14 ,'0');
              else
                 w_stringa_rata := w_stringa_rata || lpad (to_char (nvl (rec_raim.iva, 0) * 100),15,'0');
              end if;
              -- (RV - 21/05/2025): Nuova stringa importi Maggiorazione Tares (Componenti Perequative)
              if nvl (rec_raim.maggiorazione_tares, 0) < 0 then
                 w_stringa_magg_tares_rata := '-' || lpad (to_char (abs (nvl (rec_raim.maggiorazione_tares, 0)) * 100),14 ,'0');
              else
                 w_stringa_magg_tares_rata := lpad (to_char (nvl (rec_raim.maggiorazione_tares, 0) * 100),15,'0');
              end if;
              if rec_raim.rata < 2 then
                 w_stringa_rata_1 := w_stringa_rata;
                 w_stringa_magg_tares := w_stringa_magg_tares_rata;
                 if rec_raim.imposta_round is null then
                    w_stringa_imp_round := rpad(' ',15);
                 else
                    w_stringa_imp_round := lpad(to_char(nvl(rec_raim.imposta_round,0) * 100),15,'0');
                 end if;
                 w_step := 7;
              elsif rec_raim.rata = 2 then
                 w_stringa_rata_2 := w_stringa_rata;
                 w_stringa_magg_tares := w_stringa_magg_tares || w_stringa_magg_tares_rata;
                 if rec_raim.imposta_round is null then
                    w_stringa_imp_round := w_stringa_imp_round||rpad(' ', 15);
                 else
                    w_stringa_imp_round := w_stringa_imp_round||lpad(to_char(nvl(rec_raim.imposta_round,0) * 100),15,'0');
                 end if;
                 w_step := 8;
              elsif rec_raim.rata = 3 then
                 w_stringa_rata_3 := w_stringa_rata;
                 w_stringa_magg_tares := w_stringa_magg_tares || w_stringa_magg_tares_rata;
                 if rec_raim.imposta_round is null then
                    w_stringa_imp_round := w_stringa_imp_round||rpad(' ', 15);
                 else
                    w_stringa_imp_round := w_stringa_imp_round||lpad(to_char(nvl(rec_raim.imposta_round,0) * 100),15,'0');
                 end if;
                 w_step := 9;
              elsif rec_raim.rata = 4 then
                 w_stringa_rata_4 := w_stringa_rata;
                 w_stringa_magg_tares := w_stringa_magg_tares || w_stringa_magg_tares_rata;
                 if rec_raim.imposta_round is null then
                    w_stringa_imp_round := w_stringa_imp_round || rpad (' ', 15);
                 else
                    w_stringa_imp_round := w_stringa_imp_round||lpad(to_char(nvl(rec_raim.imposta_round,0) * 100),15,'0');
                 end if;
              end if;
              w_step := 10;
            end loop;
         end if;
         --dbms_output.put_line(' w_step '||w_step||' nvl(rec_prat.sgravio_compensazione,0)  '||nvl(rec_prat.sgravio_compensazione,0) );
         begin
         --dbms_output.put_line('  Str 1: '||w_stringa_rata_1);
         --dbms_output.put_line('  Str 2: '||w_stringa_rata_2);
         --dbms_output.put_line('  Str 3: '||w_stringa_rata_3);
         --dbms_output.put_line('  Str 4: '||w_stringa_rata_4);
         --dbms_output.put_line('  TARES: '||w_stringa_magg_tares);
           w_num_ogim := null;
           oggetti_imposta_nr (w_num_ogim);
           insert into oggetti_imposta ( oggetto_imposta
                                       , cod_fiscale
                                       , anno
                                       , oggetto_pratica
                                       , imposta
                                       , utente
                                       , addizionale_eca
                                       , maggiorazione_eca
                                       , addizionale_pro
                                       , iva
                                       , maggiorazione_tares
                                       , note
                                       , tipo_tributo
                                       , dettaglio_ogim
                                       , tipo_tariffa_base
                                       , imposta_base
                                       , addizionale_eca_base
                                       , maggiorazione_eca_base
                                       , addizionale_pro_base
                                       , iva_base
                                       , dettaglio_ogim_base
                                       , perc_riduzione_pf
                                       , perc_riduzione_pv
                                       , importo_riduzione_pf
                                       , importo_riduzione_pv
                                       )
           values ( w_num_ogim
                  , rec_cont.cod_fiscale
                  , a_anno
                  , w_num_ogpr
                  , rec_prat.imposta
                  , a_utente
                  , rec_prat.addizionale_eca
                  , rec_prat.maggiorazione_eca
                  , rec_prat.addizionale_pro
                  , rec_prat.iva
                  , w_magg_tares_ricalcolata
                  , lpad(to_char(rec_prat.ruolo),10,'0')
                    || to_char(nvl(rec_prat.delta_rate,0))
                    || to_char(nvl(w_tot_rate,nvl(rec_prat.num_rate,0)))
                    || w_stringa_rata_1
                    || w_stringa_rata_2
                    || w_stringa_rata_3
                    || w_stringa_rata_4
                    || lpad(to_char(nvl(rec_prat.sgravio_compensazione,0) * 100),15,'0')
                    || rpad(w_stringa_imp_round,60,'0')
                    || decode(w_scadenza_ricalcolata,null,rpad('0',10),to_char(w_scadenza_ricalcolata,'dd/mm/yyyy'))
                    --
                    || rpad(w_stringa_magg_tares,60,'0')
                    || lpad(to_char(nvl(rec_prat.sgravio_tares,0) * 100),15,'0')
                  , a_tipo_tributo
                  , rec_prat.dettaglio_ogim
                  , rec_prat.tipo_tariffa_base
                  , rec_prat.imposta_base
                  , rec_prat.addizionale_eca_base
                  , rec_prat.maggiorazione_eca_base
                  , rec_prat.addizionale_pro_base
                  , rec_prat.iva_base
                  , rec_prat.dettaglio_ogim_base
                  , rec_prat.perc_riduzione_pf
                  , rec_prat.perc_riduzione_pv
                  , rec_prat.importo_riduzione_pf
                  , rec_prat.importo_riduzione_pv
                  );
           insert into familiari_ogim ( oggetto_imposta
                                      , dal
                                      , al
                                      , numero_familiari
                                      , dettaglio_faog
                                      , data_variazione
                                      , note
                                      , dettaglio_faog_base
                                      )
           select w_num_ogim
                , dal
                , al
                , numero_familiari
                , dettaglio_faog
                , data_variazione
                , note
                , dettaglio_faog_base
             from familiari_ogim
            where oggetto_imposta = rec_prat.oggetto_imposta;
         end;
         w_step := 11;
         -- dbms_output.put_line(' w_step '||w_step);
         -- w_errore := w_stringa_imp_round;
         -- raise errore;
      end if;
    end loop;
    w_step := 11.1;
    --dbms_output.put_line(' w_step '||w_step);
    --
    -- Calcolo delle sanzioni.
    --
    CALCOLO_ACC_SANZIONI_TARSU (w_num_prtr
                              , a_utente
                              , to_date(null)
                              , to_date(null)
                              , a_se_spese_notifica);
  end loop;
  w_step := 13;
  if instr(a_cod_fiscale,'%') = 0 then
     a_pratica := w_num_prtr;
  else
     a_pratica := to_number(null);
  end if;
exception
  when ERRORE then
    rollback;
    RAISE_APPLICATION_ERROR (-20999
                           , w_step || ' ' || w_cod_fiscale || ' ' || w_errore);
  when others then
    rollback;
    RAISE_APPLICATION_ERROR (-20999
                           , w_step || ' ' || w_cod_fiscale || ' ' || sqlerrm);
end;
/* End Procedure: CALCOLO_SOLLECITI_TARSU */
/
