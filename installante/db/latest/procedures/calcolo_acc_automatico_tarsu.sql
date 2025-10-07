--liquibase formatted sql 
--changeset abrandolini:20250326_152423_calcolo_acc_automatico_tarsu stripComments:false runOnChange:true 
 
create or replace procedure CALCOLO_ACC_AUTOMATICO_TARSU
/*******************************************************************************
 Rev.    Date         Author      Note
 20      29/07/2025   RV          #77694
                                  Integrato gestione importi rateizzati Maggiorazione
                                  Tares (Componentio Perequative) per Calcolo Sanzioni
 19      10/06/2025   DM          #79928
                                  Recuperata data cessazione da pratica collegata
 18      03/12/2024   DM          #73162 -
                                  quando la scadenza della rata unica è successiva
                                  alla scadenza della prima rata, la scadenza della
                                  rata unica diventa il termine unico a cui riferirsi
                                  per ravvedimento e interessi sul residuo da pagare.
 17      20/09/2022   VM          #66699 - sostituito filtro ricerca sogg.cognome_nome
                                  con sogg.cognome_nome_ric
 16      08/03/2023   VM          Issue #61132
                                  Aggiunto parametro a_se_spese_notifica
 15      02/02/2023   AB          Issue #48451
                                  Aggiunta la eliminazione sanzioni per deceduti
 14      23/01/2023   RV          Issue #61793
                                  Modificato nome parametro a_flag_solleciti,
                                  diventa a_tipo_solleciti
                                  Aggiunto parametri filtro data / data notifica,
                                  a_data_sollecito_da, a_data_sollecito_a,
                                  a_data_notifica_sol_da e a_data_notifica_sol_a
 13      10/01/2023   AB          Salvataggio anno in oggetti_pratica
 12      22/09/2022   VD          Issue #55324
                                  Aggiunto parametro a_flag_solleciti.
                                  Se parametro valorizzato a "S", si trattano
                                  solo i contribuenti per cui e' stato emesso
                                  un sollecito
                                  Se valorizzato a "N", si trattano solo i
                                  contribuenti per cui NON è stato emesso
                                  un sollecito
                                  Se valorizzato a "T" si trattano tutti i
                                  contribuenti
 11      06/04/2022   VD          Issue #55529
                                  Aggiunto parametro di output per
                                  restituire il numero pratica solo nel
                                  caso in cui l'accertamento venga eseguito
                                  per un solo contribuente.
 10      09/03/2020   VD          Corretta gestione importi di addizionali e/o
                                  maggiorazioni negativi nell'inserimento della
                                  stringa dettaglio_ogim.
 9       17/04/2019   VD          Aggiunta gestione campi per calcolo con
                                  tariffa
 8       16/11/2018   VD          Modificata query per rielaborare accertamenti
                                  precedenti non numerati
 7       12/11/2018   VD          Modificato controllo su esistenza accertamento
                                  precedente: ora si controlla solo che non
                                  esista già una pratica di tipo "A" con tipo
                                  evento "A", escludendo il controllo sui
                                  codici sanzione.
 6       15/06/2017   AB          Modificata la function f_exists_ruolo_successivo_tot
                                  mettendo il controllo >= 1 così da
                                  considerare per i ruoli acconto,
                                  sia i principali che i suppletivi totali.
                                  Aggiunto il >= 1 anche nella if
                                  per gestire bene anche i casi di
                                  più ruoli suppletivi totali,
                                  così da considerare solo l'ultimo.
 5       22/05/2017   VD          Modificata query sel_cont per evitare di
                                  inserire pratiche senza oggetti: ora le
                                  condizioni di where di sel_cont sono
                                  analoghe a quelle di sel_prat
 4       15/02/2017   VD          Modificata gestione stringhe con messaggi
                                  di errore: ora si espone il codice fiscale
                                  una sola volta, anche se l'errore e
                                  relativo a piu oggetti_imposta.
                                  Diminuita la lunghezza di riferimento da
                                  1950 a 1900.
 3       16/03/2015   VD          Corretta gestione stringa rate mancanti:
                                  si accodano i dati fino a che la
                                  lunghezza della stringa arriva a 1950
                                  caratteri
 2       10/12/2014   VD          Nel trattamento delle pratiche da eliminare
                                  perché non comprese nei limiti di importo,
                                  modificato calcolo importo totale per
                                  pratica ricavandolo dalla relativa window PB
 1       18/11/2014   VD          Aggiunta gestione limiti inferiore
                                  e superiore
 0       10/03/2014   SC          Att. TARES Accertamenti Automatici
*******************************************************************************/
( a_tipo_tributo               in        varchar2
 ,a_anno                       in        number
 ,a_cod_fiscale                in        varchar2
 ,a_cognome_nome               in        varchar2
 ,a_utente                     in        varchar2
 ,a_limite_inf                 in        number
 ,a_limite_sup                 in        number
 ,a_se_spese_notifica          in        varchar2
 ,a_interessi_dal              in        date
 ,a_interessi_al               in        date
 ,a_tipo_solleciti             in        varchar2   /* 'T' (Def) - Tutti, 'S' - Solo Sollecitati, 'M' - Solo NON Sollecitati */
 ,a_data_sollecito_da          in        date
 ,a_data_sollecito_a           in        date
 ,a_data_notifica_sol_da       in        date
 ,a_data_notifica_sol_a        in        date
 ,a_pratica                    out       number
) is
  w_errore                                varchar2 (2000);
  w_errore_2                              varchar2 (2000);
  errore                                  exception;
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
  -- Pratiche generate da precedenti calcoli di accertamenti.
  --
  -- Per Portoferraio, nel 2013, generiamo gli acc automatici solo
  -- per i contribuenti che hanno contatti di tipo 31 o 72
  -- Con Salva abbiamo deciso di cancellare comunque tutte le pratiche
  -- generate dai precedenti calcoli, senza preoccuparci dei contatti. Betta T.
  --
  -- (VD - 16/11/2018): Modificata query per rielaborare accertamenti
  --                    precedenti non numerati: si trattano gli accertamenti
  --                    con tipo_evento = 'A' oppure quelli con tipo_evento =
  --                    'U' e utente like '#%'
  --
  cursor sel_liq (
   p_tipo_trib                            varchar2
 , p_anno                                 number
 , p_cod_fiscale                          varchar2
 , p_cognome_nome                         varchar2
 , p_tipo_solleciti                       varchar2
 , p_data_sollecito_da                    date
 , p_data_sollecito_a                     date
 , p_data_notifica_sol_da                 date
 , p_data_notifica_sol_a                  date
 ) is
   select   pratica
       from pratiche_tributo prtr
          , contribuenti cont
          , soggetti sogg
      where prtr.tipo_tributo || '' = p_tipo_trib
        and prtr.anno = p_anno
        and prtr.tipo_pratica = 'A'
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
        -- (RV - 19/01/2023): rivisto select per range data e data notifica
        and (nvl(p_tipo_solleciti,'T') = 'T'
            or
            (nvl(p_tipo_solleciti,'T') = 'S'
             and exists
             (select 'x' from pratiche_tributo prtx
              where prtx.tipo_tributo = p_tipo_trib
                and prtx.anno = p_anno
                and prtx.cod_fiscale = prtr.cod_fiscale
                and prtx.tipo_pratica = 'S'
                and nvl(prtx.stato_accertamento,'D') = 'D'
                and prtx.data >= nvl(a_data_sollecito_da,to_date('01011900','ddmmyyyy'))
                and prtx.data <= nvl(a_data_sollecito_a,to_date('31122999','ddmmyyyy'))
                and nvl(prtx.data_notifica,to_date('01011990','ddmmyyyy')) >=
                    nvl(a_data_notifica_sol_da,to_date('01011900','ddmmyyyy'))
                and nvl(prtx.data_notifica,to_date('01011990','ddmmyyyy')) <=
                    nvl(a_data_notifica_sol_a,to_date('31122999','ddmmyyyy'))))
            or
            (nvl(p_tipo_solleciti,'T') = 'N'
             and not exists
             (select 'x' from pratiche_tributo prtz
              where prtz.tipo_tributo = p_tipo_trib
                and prtz.anno = p_anno
                and prtz.cod_fiscale = prtr.cod_fiscale
                and prtz.tipo_pratica = 'S'
                and nvl(prtz.stato_accertamento,'D') = 'D'
                and prtz.data >= nvl(a_data_sollecito_da,to_date('01011900','ddmmyyyy'))
                and prtz.data <= nvl(a_data_sollecito_a,to_date('31122999','ddmmyyyy'))
                and nvl(prtz.data_notifica,to_date('01011990','ddmmyyyy')) >=
                    nvl(a_data_notifica_sol_da,to_date('01011900','ddmmyyyy'))
                and nvl(prtz.data_notifica,to_date('01011990','ddmmyyyy')) <=
                    nvl(a_data_notifica_sol_a,to_date('31122999','ddmmyyyy'))))
            )
   order by 1;
   --
   -- Contribuenti.
   --
   cursor sel_cont ( p_cod_fiscale                          varchar2
                   , p_cognome_nome                         varchar2
                   , p_tipo_trib                            varchar2
                   , p_anno                                 number
                   , p_cod_istat                            varchar2
                   , p_tipo_solleciti                       varchar2
                   , p_data_sollecito_da                    date
                   , p_data_sollecito_a                     date
                   , p_data_notifica_sol_da                 date
                   , p_data_notifica_sol_a                  date
                   ) is
     --
     -- (VD - 22/05/2017): aggiunta la tabella pratiche_tributo in join
     --                    per trattare solo le pratiche con flag denuncia
     --                    e stato accertamento definitivo (le stesse
     --                    condizioni di sel_prat)
     --
     select distinct ogim.cod_fiscale
                   , replace (sogg.cognome_nome,'/',' ') cognome_nome
                   , sogg.stato  -- AB 02/02/2023 ci serve per elimianzione sanzioni per deceduti
       from oggetti_pratica ogpr
          , oggetti_contribuente ogco
          , oggetti_imposta ogim
          , ruoli ruol
          , contribuenti cont
          , soggetti sogg
          , pratiche_tributo prtr
       -- ,oggetti_validita     ogva
      where ogpr.oggetto_pratica = ogco.oggetto_pratica
        and ogco.cod_fiscale = ogim.cod_fiscale
        and ogco.oggetto_pratica = ogim.oggetto_pratica
        and cont.cod_fiscale = ogco.cod_fiscale
        and sogg.ni = cont.ni
        --  and ogim.oggetto_pratica               = NVL(ogva.oggetto_pratica_RIF, ogva.oggetto_pratica)
        and ogim.anno = p_anno
        and ogco.cod_fiscale like nvl (p_cod_fiscale, '%')
        and sogg.cognome_nome_ric like nvl (p_cognome_nome, '%')
        and ogim.tipo_tributo || '' = p_tipo_trib
        /*  and nvl(to_number(to_char(ogva.dal,'yyyy')),0)
                                                <= :p_anno
          and nvl(to_number(to_char(ogva.al,'yyyy')),9999)
                                                >= :p_anno
          and decode(ogva.tipo_pratica,'A',ogva.anno,:p_anno - 1)
                                                <> :p_anno
          and decode(ogva.tipo_pratica,'A',ogva.flag_denuncia,'S')
                                                 = 'S'
          and nvl(ogva.stato_accertamento,'D')   = 'D'    */
        and ogpr.pratica = prtr.pratica
        and decode(prtr.tipo_pratica,'A',prtr.anno,p_anno - 1)
                                              <> p_anno
        and decode(prtr.tipo_pratica,'A',prtr.flag_denuncia,'S')
                                               = 'S'
        and nvl(prtr.stato_accertamento,'D')   = 'D'
        and ruol.ruolo(+) = ogim.ruolo
        and ruol.tipo_tributo(+) = ogim.tipo_tributo
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
        /*and not exists (
            select 1
              from pratiche_tributo prt2
                 , sanzioni_pratica sap2
             where prt2.pratica = sap2.pratica
               and sap2.tipo_tributo = p_tipo_trib
               and prt2.tipo_tributo = p_tipo_trib
               and prt2.anno = p_anno
               and prt2.cod_fiscale = ogco.cod_fiscale
               and prt2.tipo_pratica = 'A'
               and nvl (prt2.stato_accertamento, 'D') = 'D'
               and (prt2.data_notifica is not null
                    or prt2.numero is not null)
               and sap2.cod_sanzione in (16,17,26,27,36,37,46,47,116,117,126,127,136,137,146,147
                                        ,18,19,28,29,38,39,48,49,118,119,128,129,138,139,148,149
                                        ,107
                                        )
                       ) */
        -- (RV - 19/01/2023): rivisto select per range data e data notifica
        and (nvl(p_tipo_solleciti,'T') = 'T'
             or
             (nvl(p_tipo_solleciti,'T') = 'S'
              and exists
              (select 'x' from pratiche_tributo prtx
               where prtx.tipo_tributo = p_tipo_trib
                 and prtx.anno = p_anno
                 and prtx.cod_fiscale = ogco.cod_fiscale
                 and prtx.tipo_pratica = 'S'
                 and nvl(prtx.stato_accertamento,'D') = 'D'
                 and prtx.data >= nvl(a_data_sollecito_da,to_date('01011900','ddmmyyyy'))
                 and prtx.data <= nvl(a_data_sollecito_a,to_date('31122999','ddmmyyyy'))
                 and nvl(prtx.data_notifica,to_date('01011990','ddmmyyyy')) >=
                     nvl(a_data_notifica_sol_da,to_date('01011900','ddmmyyyy'))
                 and nvl(prtx.data_notifica,to_date('01011990','ddmmyyyy')) <=
                     nvl(a_data_notifica_sol_a,to_date('31122999','ddmmyyyy'))))
             or
             (nvl(p_tipo_solleciti,'T') = 'N'
              and not exists
              (select 'x' from pratiche_tributo prtz
               where prtz.tipo_tributo = p_tipo_trib
                 and prtz.anno = p_anno
                 and prtz.cod_fiscale = ogco.cod_fiscale
                 and prtz.tipo_pratica = 'S'
                 and nvl(prtz.stato_accertamento,'D') = 'D'
                 and prtz.data >= nvl(a_data_sollecito_da,to_date('01011900','ddmmyyyy'))
                 and prtz.data <= nvl(a_data_sollecito_a,to_date('31122999','ddmmyyyy'))
                 and nvl(prtz.data_notifica,to_date('01011990','ddmmyyyy')) >=
                     nvl(a_data_notifica_sol_da,to_date('01011900','ddmmyyyy'))
                 and nvl(prtz.data_notifica,to_date('01011990','ddmmyyyy')) <=
                     nvl(a_data_notifica_sol_a,to_date('31122999','ddmmyyyy'))))
            )
        and ((p_anno != 2013
              or p_cod_istat != '049014')                -- Portoferraio
             or (p_anno = 2013
                 and p_cod_istat = '049014'              -- Portoferraio
                 and exists (
                     select 'x'
                       from contatti_contribuente
                      where cod_fiscale = ogim.cod_fiscale
                        and anno = p_anno
                        and tipo_contatto in (31, 72)
                        and nvl (tipo_tributo, 'TARSU') = 'TARSU')))
   order by ogim.cod_fiscale;
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
        --
        -- (VD - 12/11/2018): modificato test esistenza acc. precedente
        --
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
/**
  select   raim.rata
         , raim.imposta
         , raim.addizionale_eca
         , raim.maggiorazione_eca
         , raim.addizionale_pro
         , raim.iva
         , raim.imposta_round
         , raim.maggiorazione_tares
      from rate_imposta raim
     where raim.oggetto_imposta = p_oggetto_imposta
       and p_imposta_totale >= 0
  order by raim.rata;
**/
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
     /*
        #73162
        quando la scadenza della rata unica è successiva alla scadenza della prima rata,
        la scadenza della rata unica diventa il termine unico a cui riferirsi per ravvedimento
        e interessi sul residuo da pagare.
     */
     select case
       when ruol.scadenza_rata_unica is not null and ruol.scadenza_rata_unica > ruol.SCADENZA_PRIMA_RATA then
         ruol.scadenza_rata_unica
       else
         nvl (ruol.SCADENZA_RATA_4
            , nvl (ruol.SCADENZA_RATA_3
                 , nvl (ruol.SCADENZA_RATA_2
                      , ruol.SCADENZA_PRIMA_RATA)))
       end
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
/*         CHECK ACC AUTOMATICO TARSU               */
/*----------------------------------------------------*/
 procedure CHECK_ACC_AUTOMATICO_TARSU
( a_tipo_tributo               in        varchar2
, a_anno                       in        number
, a_cod_fiscale                in        varchar2
, a_cognome_nome               in        varchar2
, a_cod_istat                  in        varchar2
, a_tipo_solleciti             in        varchar2
 ,a_data_sollecito_da          in        date
 ,a_data_sollecito_a           in        date
 ,a_data_notifica_sol_da       in        date
 ,a_data_notifica_sol_a        in        date
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
                          , a_cod_istat
                          , a_tipo_solleciti
                          , a_data_sollecito_da
                          , a_data_sollecito_a
                          , a_data_notifica_sol_da
                          , a_data_notifica_sol_a)
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
--         CALCOLO ACC AUTOMATICO TARSU               --
--------------------------------------------------------
--
begin
  w_errore := null;
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
                            , w_cod_istat
                            , a_tipo_solleciti
                            , a_data_sollecito_da
                            , a_data_sollecito_a
                            , a_data_notifica_sol_da
                            , a_data_notifica_sol_a);
  for rec_liq in sel_liq (a_tipo_tributo
                        , a_anno
                        , a_cod_fiscale
                        , a_cognome_nome
                        , a_tipo_solleciti
                        , a_data_sollecito_da
                        , a_data_sollecito_a
                        , a_data_notifica_sol_da
                        , a_data_notifica_sol_a)
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
                          , w_cod_istat
                          , a_tipo_solleciti
                          , a_data_sollecito_da
                          , a_data_sollecito_a
                          , a_data_notifica_sol_da
                          , a_data_notifica_sol_a)
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
                                   )
      values ( w_num_prtr
             , rec_cont.cod_fiscale
             , a_tipo_tributo
             , a_anno
             , 'A'
             , 'A'
             , trunc (sysdate)
             , null
             , null
             , '#'||substr(a_utente,1,7)
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
         if rec_prat.num_rate = 0 then
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
                 /*dbms_output.put_line(' w_step '||w_step||' rec_prat.ruolo '||rec_prat.ruolo||' rec_prat.num_rate '||rec_prat.num_rate);
                 RICALCOLO_IMPOSTA ( rec_prat.cod_fiscale, rec_prat.ruolo
                                   , a_anno
                                   , rec_prat.oggetto_pratica_rif
                                   , rec_prat.dal
                                   , rec_prat.al
                                   , rec_prat.flag_normalizzato
                                   , rec_prat.tipo_ruolo
                                   , rec_prat.tipo_emissione
                                   , w_imposta_ricalcolata
                                   , w_magg_eca
                                   , w_add_eca
                                   , w_add_pro
                                   , w_iva
                                   , w_magg_tares_ricalcolata);
                 dbms_output.put_line('rec_prat.maggiorazione_tares '||rec_prat.maggiorazione_tares||' w_magg_tares_ricalcolata '||w_magg_tares_ricalcolata);
                 dbms_output.put_line(' rec_prat.imposta '||rec_prat.imposta||' w_imposta_ricalcolata '||w_imposta_ricalcolata);
                 dbms_output.put_line(' nvl(rec_prat.maggiorazione_eca,0) '||nvl(rec_prat.maggiorazione_eca,0)||' w_magg_eca '||w_magg_eca);
                 dbms_output.put_line(' nvl(rec_prat.addizionale_eca,0) '||nvl(rec_prat.addizionale_eca,0)||' w_add_eca '||w_add_eca);
                 dbms_output.put_line(' nvl(rec_prat.addizionale_pro,0) '||nvl(rec_prat.addizionale_pro,0)||' w_add_pro '||w_add_pro);
                 dbms_output.put_line(' nvl(rec_prat.iva,0) '||nvl(rec_prat.iva,0)||' w_iva '||w_iva);*/
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
                 w_errore := 'Accertamento non applicabile: il ruolo '
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
                              , a_interessi_dal
                              , a_interessi_al
                              , a_se_spese_notifica);
    w_step := 11.2;
    -- (AB - 02/02/2023): se il contribuente è deceduto, si eliminano
    --                    le sanzioni lasciando solo imposta evasa,
    --                    interessi e spese di notifica
    if rec_cont.stato = 50 then
       ELIMINA_SANZ_LIQ_DECEDUTI(w_num_prtr);
    end if;
    COMMIT;
    --dbms_output.put_line(' w_step '||w_step);
  end loop;
  w_step := 12;
  --dbms_output.put_line(' w_step '||w_step);
 --
 -- Eliminazione degli Accertamenti emessi nel caso di non raggiungimento del Limite.
 --
  for rec_prat_elim in sel_prat_elim (a_limite_inf
                                    , a_limite_sup
                                    , a_tipo_tributo
                                    , a_anno
                                    , a_cod_fiscale
                                    , a_cognome_nome)
  loop
    --dbms_output.put_line(' rec_prat_elim.pratica '||rec_prat_elim.pratica);
    if rec_prat_elim.pratica = w_num_prtr and
       instr(a_cod_fiscale,'%') = 0 then
       w_num_prtr := to_number(null);
    end if;
    delete from pratiche_tributo prtr
     where prtr.pratica = rec_prat_elim.pratica;
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
/* End Procedure: CALCOLO_ACC_AUTOMATICO_TARSU */
/
