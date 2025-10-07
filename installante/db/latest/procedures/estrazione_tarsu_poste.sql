--liquibase formatted sql 
--changeset abrandolini:20250326_152423_estrazione_tarsu_poste stripComments:false runOnChange:true 
 
create or replace procedure ESTRAZIONE_TARSU_POSTE
      (p_ruolo IN number, p_spese_postali IN number) IS
-- 07/11/2014 Betta T. Corretta insert in wrk_trasmissioni per aggiunta di campi
CURSOR sel_co (p_spese_postali number) IS
  select so.ni
       , co.cod_fiscale
       , so.ni||';'||
          substr(replace(replace(so.cognome_nome,'/',' '),';',','),1,44)||';'||
          substr(decode(so.cod_via,
                        to_number(null),so.denominazione_via,
                        arviS.denom_uff)
                 ||' '||to_char(so.num_civ)
                 ||decode(so.suffisso,'','','/'||so.suffisso)
                 ||decode(so.scala,'','',' Sc.'||so.scala)
                ,1,44)||';'||
          lpad(to_char(comR.cap),5,'0')||';'||
          substr(comR.denominazione,1,30)||';'||
          substr(proR.sigla,1,2)||';'||
          co.cod_fiscale||';'||
          substr(decode(sign(200-nazR.provincia_stato),1,'',nazR.denominazione),1,30)||';'||
--      replace(substr(
--        to_char(round((ruco.importo +
--                 f_round(ruco.importo*nvl(cata.addizionale_eca,0)/100,1) +
--                 f_round(ruco.importo*nvl(cata.maggiorazione_eca,0)/100,1) +
--                 f_round(ruco.importo*nvl(cata.addizionale_pro,0)/100,1) +
--                     f_round(ruco.importo*nvl(cata.aliquota,0)/100,1)),2))
--        ,1,10),'.',',')||';'||
          replace(substr(to_char(round(imco.importo_lordo + p_spese_postali - nvl(comp.compensazione,0),0)),1,10),'.',',')||';'||
          substr(replace(replace(soP.cognome_nome,'/',' '),';',','),1,44)||';'||
          substr(decode(soP.cod_via,
                        to_number(null),soP.denominazione_via,
                        arviP.denom_uff)
                 ||' '||to_char(soP.num_civ)||decode(soP.suffisso,'','','/'||soP.suffisso),1,44)||';'||
          lpad(to_char(comP.cap),5,'0')||';'||
          substr(comP.denominazione,1,30)||';'||
          substr(proP.sigla,1,2)||';'                                            prima_parte
       , replace(to_char(cata.addizionale_eca),'.',',')||';'||
--          replace(substr(
--              to_char(f_round(nvl(ruco.importo*cata.addizionale_eca,0)/100,1))
--            ,1,10),'.',',')||';'||
          replace(substr(to_char(imco.addizionale_eca),1,10),'.',',')||';'||
          replace(to_char(cata.maggiorazione_eca),'.',',')||';'||
--          replace(substr(
--              to_char(f_round(ruco.importo*nvl(cata.maggiorazione_eca,0)/100,1))
--            ,1,10),'.',',')||';'||
          replace(substr(to_char(imco.maggiorazione_eca),1,10),'.',',')||';'||
          replace(decode(to_char(cata.addizionale_pro)||to_char(cata.aliquota)
                        ,null,null
                        ,to_char(nvl(cata.addizionale_pro,0) + nvl(cata.aliquota,0))
                        ),'.',',')||';'||
--          replace(substr(
--              to_char(f_round(ruco.importo*nvl(cata.addizionale_pro,0)/100,1) +
--                            f_round(ruco.importo*nvl(cata.aliquota,0)/100,1))
--            ,1,10),'.',',')||';'||
          replace(substr(to_char(nvl(imco.addizionale_pro,0)
                             +nvl(imco.iva,0)),1,10),'.',',')||';'||
          replace(substr(to_char(imco.importo_netto),1,10),'.',',')||';'         seconda_parte
-- Campi PS1 e NOTE01
       , decode(imco.maggiorazione_tares,null,null,
                'Maggiorazione Tares per lo Stato: '||imco.maggiorazione_tares)||';;'||
          ruoli.anno_ruolo||
          '0'||
          lpad(ruoli.ruolo,4,'0')||
          lpad(so.ni,7,'0')||';'                                                 terza_parte
       , ruoli.ruolo
       , ruoli.rate
       , round(imco.importo_lordo + p_spese_postali - nvl(comp.compensazione,0),0)                           importo_tot_arrotondato
       , imco.importo_lordo - nvl(comp.compensazione,0)                                                      da_pagare
       , imco.maggiorazione_tares                                                maggiorazione_tares
       -- IL V CAMPO sarà estratto dal cursore sel_rate e composto composto dall'anno_ruolo
-- per i primi 4 caratteri, la rata per il quinto carattere, il ruolo (pk di ruoli)
-- per i successivi 4 caratteri e l'ni in 7 caratteri
--       ';;;;;;;;' seconda_parte
    from ruoli,
          (select r.ruolo, r.cod_fiscale,
                  sum(r.importo) importo_lordo,
                  sum(o.addizionale_eca) addizionale_eca,
                  sum(o.maggiorazione_eca) maggiorazione_eca,
                  sum(o.addizionale_pro) addizionale_pro,
                  sum(o.iva) iva,
                  sum(o.imposta) importo_netto,
                  sum(o.maggiorazione_tares) maggiorazione_tares
             from ruoli_contribuente r,oggetti_imposta o
            where r.ruolo = p_ruolo
              and o.ruolo = r.ruolo
              and r.oggetto_imposta = o.oggetto_imposta
            group by r.ruolo, r.cod_fiscale) imco,
          (select nvl(sum(decode(motivo_compensazione,99,null,coru.compensazione)),0) compensazione -- 24/10/13 eccedenza come gli sgravi in acconto
                , coru.ruolo
                , coru.cod_fiscale
             from compensazioni_ruolo coru
            group by coru.ruolo, coru.cod_fiscale) comp,
          carichi_tarsu      cata,
          contribuenti       co,
          soggetti           so,
          archivio_vie       arviS,
          ad4_comuni         comR,
          ad4_provincie      proR,
          ad4_comuni         nazR,
          soggetti           soP,
          archivio_vie       arviP,
          ad4_comuni         comP,
          ad4_provincie      proP
   where ruoli.ruolo    = p_ruolo
     and imco.ruolo     = ruoli.ruolo
     and cata.anno      = ruoli.anno_ruolo
     and co.cod_fiscale = imco.cod_fiscale
     and co.ni          = so.ni
     and arviS.cod_via        (+) = so.cod_via
     and comR.provincia_stato (+) = so.cod_pro_res
     and comR.comune          (+) = so.cod_com_res
     and proR.provincia       (+) = so.cod_pro_res
     and nazR.provincia_stato (+) = so.cod_pro_res
     and nazR.comune          (+) = 0
     and soP.ni               (+) = so.ni_presso
     and arviP.cod_via        (+) = soP.cod_via
     and comP.provincia_stato (+) = soP.cod_pro_res
     and comP.comune          (+) = soP.cod_com_res
     and proP.provincia       (+) = soP.cod_pro_res
     and comp.cod_fiscale     (+) = imco.cod_fiscale
     and comp.ruolo           (+) = imco.ruolo
   order by 1;
CURSOR sel_ubi (w_cod_fiscale varchar2) IS
   select ruco.oggetto_imposta,
          to_char(ruoli.anno_ruolo)||';'||
           substr(decode(ogge.cod_via,
                         to_number(null),indirizzo_localita,
                         arvi.denom_uff)
           ||' '||to_char(ogge.num_civ)||decode(ogge.suffisso,'','','/'||ogge.suffisso),1,44)||';'||
           cate.descrizione||' - '||tari.descrizione||';'||
           to_char(ogpr.consistenza)||';'||
           replace(substr(to_char(tari.tariffa),1,5),'.',',')||';'||
           decode(nvl(nvl(ogpr.numero_familiari,faog.numero_familiari),0),0,''
                , 'Dal: '||to_char(decode(faog.numero_familiari
                                         , null ,nvl(ogva.dal,to_date('01011900','ddmmyyyy'))
                                         , faog.dal),'dd/mm/yyyy')
                  ||' al: '||to_char(decode(faog.numero_familiari
                                           , null ,nvl(ogva.al,to_date('31122999','ddmmyyyy'))
                                           , faog.al),'dd/mm/yyyy')
                  ||' numero familiari: '||nvl(ogpr.numero_familiari,faog.numero_familiari))||';'||
           replace(to_char(decode (ogim.dettaglio_ogim
                                   , null , to_number(replace(ltrim(rtrim(substr(faog.dettaglio_faog,8,9))),',','.'))
                                            * to_number(replace(ltrim(rtrim(substr(faog.dettaglio_faog,24,15))),',','.'))
                                   , to_number(replace(ltrim(rtrim(substr(ogim.dettaglio_ogim,8,9))),',','.'))
                                     * to_number(replace(ltrim(rtrim(substr(ogim.dettaglio_ogim,24,15))),',','.'))
                                   )),'.',',')||';'||
           replace(to_char(decode (ogim.dettaglio_ogim
                           , null , to_number(replace(ltrim(rtrim(substr(faog.dettaglio_faog,73,9))),',','.'))
                                    * to_number(replace(ltrim(rtrim(substr(faog.dettaglio_faog,89,15))),',','.'))
                           , to_number(replace(ltrim(rtrim(substr(ogim.dettaglio_ogim,73,9))),',','.'))
                             * to_number(replace(ltrim(rtrim(substr(ogim.dettaglio_ogim,89,15))),',','.'))
                           )),'.',',')||';'||
--         replace(substr(to_char(round((ogim.imposta +
--                 f_round(ogim.imposta*nvl(cata.addizionale_eca,0)/100,1) +
--                    f_round(ogim.imposta*nvl(cata.maggiorazione_eca,0)/100,1) +
--                    f_round(ogim.imposta*nvl(cata.addizionale_pro,0)/100,1) +
--                  f_round(ogim.imposta*nvl(cata.aliquota,0)/100,1)),2)),1,7),'.',',')||
            replace(substr(to_char(ruco.importo),1,10),'.',',')||
            ';' riga_ubi
     from ruoli,
          ruoli_contribuente ruco,
          oggetti_imposta ogim,
          oggetti_pratica ogpr,
          categorie cate,
          carichi_tarsu cata,
          tariffe tari,
          oggetti ogge,
          archivio_vie arvi,
          familiari_ogim              faog,
          oggetti_validita            ogva
    where ruoli.ruolo          = p_ruolo
      and ruco.cod_fiscale     = w_cod_fiscale
      and ruco.ruolo           = ruoli.ruolo
      and ogim.oggetto_imposta = ruco.oggetto_imposta
      and ogpr.oggetto_pratica = ogim.oggetto_pratica
      and cate.tributo         = ogpr.tributo
      and cate.categoria       = ogpr.categoria
      and tari.anno            = ruoli.anno_ruolo
      and tari.tributo         = ogpr.tributo
      and tari.categoria       = ogpr.categoria
      and tari.tipo_tariffa    = ogpr.tipo_tariffa
      and ogge.oggetto         = ogpr.oggetto
      and arvi.cod_via (+)     = ogge.cod_via
      and cata.anno            = ruoli.anno_ruolo
      and faog.oggetto_imposta (+) = ogim.oggetto_imposta
      and ogpr.oggetto_pratica = ogva.oggetto_pratica
    order by 1;
CURSOR sel_coru (w_cod_fiscale varchar2) IS
   select ruco.oggetto_imposta,
          to_char(ruoli.anno_ruolo)||';'||
           substr(decode(ogge.cod_via,
                         to_number(null),indirizzo_localita,
                         arvi.denom_uff)
           ||' '||to_char(ogge.num_civ)||decode(ogge.suffisso,'','','/'||ogge.suffisso),1,44)||';'||
           cate.descrizione||' - '||tari.descrizione||';'||
           to_char(ogpr.consistenza)||';'||
           replace(substr(to_char(tari.tariffa),1,5),'.',',')||';'||
           ';'||
           ';'||
           ';'||
            replace(substr(to_char(0 - coru.compensazione),1,10),'.',',')||
            ';' riga_ubi
     from ruoli
        , ruoli_contribuente ruco
        , oggetti_imposta ogim
        , oggetti_pratica ogpr
        , categorie cate
        , carichi_tarsu cata
        , tariffe tari
        , oggetti ogge
        , archivio_vie arvi
        , compensazioni_ruolo coru
    where ruoli.ruolo          = p_ruolo
      and ruco.cod_fiscale     = w_cod_fiscale
      and ruco.ruolo           = ruoli.ruolo
      and ogim.oggetto_imposta = ruco.oggetto_imposta
      and ogpr.oggetto_pratica = ogim.oggetto_pratica
      and cate.tributo         = ogpr.tributo
      and cate.categoria       = ogpr.categoria
      and tari.anno            = ruoli.anno_ruolo
      and tari.tributo         = ogpr.tributo
      and tari.categoria       = ogpr.categoria
      and tari.tipo_tariffa    = ogpr.tipo_tariffa
      and ogge.oggetto         = ogpr.oggetto
      and arvi.cod_via (+)     = ogge.cod_via
      and cata.anno            = ruoli.anno_ruolo
      and coru.cod_fiscale     = ruco.cod_fiscale
      and coru.anno            = ruoli.anno_ruolo
      and coru.ruolo           = ruco.ruolo
      and coru.oggetto_pratica = ogim.oggetto_pratica
      and coru.motivo_compensazione != 99 -- Eccedenza inserita per uguaglianza con sgravio in acconto (24/10/13 AB)
    order by 1;
CURSOR sel_rate (w_cod_fiscale varchar2, w_ruolo number, w_ni number) IS
  select raim.rata,
         ruol.anno_ruolo||
         nvl(raim.rata,0)||
         lpad(ruol.ruolo,4,'0')||
         lpad(w_ni,7,'0')||';' v_campo,
         sum(nvl(raim.imposta,nvl(ogim.imposta,0)))
          + sum(nvl(raim.addizionale_eca,nvl(ogim.addizionale_eca,0)))
          + sum(nvl(raim.maggiorazione_eca,nvl(ogim.maggiorazione_eca,0)))
          + sum(nvl(raim.addizionale_pro,nvl(ogim.addizionale_pro,0)))
          + sum(nvl(raim.iva,nvl(ogim.iva,0))) importo_rata
    from ruoli ruol,
         ruoli_contribuente ruco,
         oggetti_imposta ogim,
         rate_imposta raim
   where ruol.ruolo               = w_ruolo
     and ruco.ruolo               = ruol.ruolo
     and ruco.cod_fiscale         = w_cod_fiscale
     and ogim.oggetto_imposta     = ruco.oggetto_imposta
     and raim.oggetto_imposta (+) = ogim.oggetto_imposta
   group by ruol.anno_ruolo
          , raim.rata
          , ruol.ruolo
   order by raim.rata;
w_progr_ubicazione      number;
w_max_progr_ubicazione  number;
w_spese_postali_rata    number(6,2);
w_tot_spese_rata        number(6,2);
w_progr_wrk             number :=1;
w_riga_wrk              varchar2(4000);
w_sum_rate              number(15,2);
w_raim_imposta_round    number(15,2);
w_tot_maggiorazione_tares    number;
w_errore                varchar2(2000);
errore                  exception;
w_intestazione          varchar2(4000);
w_intest_prima          varchar2(2000);
w_intest_utenza         varchar2(2000);
w_intest_seconda        varchar2(2000);
w_intest_terza          varchar2(2000);
w_intest_rate           varchar2(2000);
i                       number;
n                       number;
w_cod_istat             varchar2(6);
w_limite_da_pagare      number(15,2);
w_compensazione         number;
w_compensazione_rata    number;
w_compensazione_tot     number;
w_importo_arrotondato_totale  number;
max_w_intestazione      number := 0;
max_w_riga_wrk          number := 0;
w_num_max_utenze        number := 1000;
BEGIN
  BEGIN
    delete wrk_trasmissioni
    ;
  EXCEPTION
    WHEN others THEN
      RAISE_APPLICATION_ERROR
          (-20999,'Errore in pulizia tabella di lavoro '||
                     ' ('||SQLERRM||')');
  END;
  BEGIN
    select lpad(to_char(pro_cliente), 3, '0') ||
           lpad(to_char(com_cliente), 3, '0')
      into w_cod_istat
      from dati_generali;
  EXCEPTION
    WHEN no_data_found THEN
      null;
    WHEN others THEN
      w_errore := 'Errore in ricerca Codice Istat del Comune ' || ' (' ||
                  SQLERRM || ')';
      RAISE errore;
  END;
  -- Limite da Pagare per il comune di Rivoli (001219)
  w_limite_da_pagare  := 12.50;
  BEGIN
    select max(ubic.numero_ubicazioni + nvl(comp.numero_compensazioni,0))
      into w_max_progr_ubicazione
      from (select cod_fiscale,count(1) numero_ubicazioni
             from ruoli_contribuente ruco
             where ruolo = p_ruolo
             group by cod_fiscale) ubic
         , (select cod_fiscale, count(1) numero_compensazioni
              from compensazioni_ruolo coru
             where ruolo = p_ruolo
                 and motivo_compensazione != 99
             group by cod_fiscale) comp
      where ubic.cod_fiscale = comp.cod_fiscale (+)
          ;
  EXCEPTION
    WHEN others THEN
      RAISE_APPLICATION_ERROR
           (-20919,'Errore in ricerca max ubicazioni'||
                ' ('||SQLERRM||')');
  END;
  if w_max_progr_ubicazione > w_num_max_utenze then
     w_max_progr_ubicazione := w_num_max_utenze;
  end if;
  i:= 0;
  w_intest_prima   := 'CU;NOME1;INDIRIZZO;CAP;DEST;PROV;CODFISC;ESTERO;XRATAT;NOME2;INDIRIZZO2;CAP2;DEST2;PROV2;';
  w_intest_utenza  := 'ANNORUOLO;INDOGG;CAT-TAR;MQ;TARI;FAMILIARI;Q-FISSA-ANNUA;Q-VAR-ANNUA;IMP_UTE;';
  w_intest_seconda := 'PERCADDECA;ADDECA;PERCMAGGECA;MAGGECA;PERCADDPRO;ADDPRO;IMPNETTO;';
  w_intest_terza   := 'VAR40A;V;VCAMPOT;';
  w_intest_rate    := 'VCAMPO1;XRATA1;VCAMPO2;XRATA2;VCAMPO3;XRATA3;VCAMPO4;XRATA4;';
  w_intestazione   := w_intest_prima;
  WHILE i < w_max_progr_ubicazione
  LOOP
     w_intestazione := w_intestazione||w_intest_utenza;
     i:= i +1;
  END LOOP;
  w_intestazione := w_intestazione||w_intest_seconda;
  w_intestazione := w_intestazione||'SPESE POSTALI;'||w_intest_terza;
  w_intestazione := w_intestazione||w_intest_rate;
   max_w_intestazione := length(w_intestazione);
   DBMS_OUTPUT.Put_Line('max_w_intestazione: '||to_char(max_w_intestazione));
    BEGIN
      insert into wrk_trasmissioni (numero, dati)
      values (w_progr_wrk,w_intestazione
             )
             ;
    EXCEPTION
      WHEN others THEN
           RAISE_APPLICATION_ERROR
               (-20929,'Errore in inserimento wrk_trasmissione '||
                    ' ('||SQLERRM||')');
    END;
  w_errore := ' Inizio ';
  FOR rec_co  IN sel_co (p_spese_postali) LOOP
    if (rec_co.da_pagare >= w_limite_da_pagare and w_cod_istat = '001219') or ( w_cod_istat <> '001219' ) then
      w_progr_wrk := w_progr_wrk + 1;
      w_progr_ubicazione := 0;
      w_riga_wrk := rec_co.prima_parte;
      w_errore := to_char(length(w_riga_wrk))||'  1 '||rec_co.cod_fiscale;
      FOR rec_coru IN sel_coru (rec_co.cod_fiscale) LOOP
        w_riga_wrk := w_riga_wrk||rec_coru.riga_ubi;
        w_progr_ubicazione := w_progr_ubicazione + 1;
        w_errore := to_char(length(w_riga_wrk))||'  2c '||rec_co.cod_fiscale;
        if w_progr_ubicazione = w_num_max_utenze then
           exit;
        end if;
      END LOOP;
      FOR rec_ubi IN sel_ubi (rec_co.cod_fiscale) LOOP
        w_riga_wrk := w_riga_wrk||rec_ubi.riga_ubi;
        w_progr_ubicazione := w_progr_ubicazione + 1;
        w_errore := to_char(length(w_riga_wrk))||'  2 '||rec_co.cod_fiscale;
        if w_progr_ubicazione = w_num_max_utenze then
           exit;
        end if;
      END LOOP;
      w_errore := to_char(length(w_riga_wrk))||'  3 '||rec_co.cod_fiscale;
      WHILE w_progr_ubicazione < w_max_progr_ubicazione LOOP
        w_progr_ubicazione := w_progr_ubicazione + 1;
           w_riga_wrk := w_riga_wrk||';;;;;;;;;';
      END LOOP;
      w_errore := to_char(length(w_riga_wrk))||'  4 '||rec_co.cod_fiscale;
      w_riga_wrk := w_riga_wrk||rec_co.seconda_parte
                  ||replace(to_char(p_spese_postali),'.',',')||';'
                  ||rec_co.terza_parte;
      w_spese_postali_rata := 0;
      w_tot_spese_rata     := 0;
      w_raim_imposta_round := 0;
      w_sum_rate           := 0;
      w_compensazione_tot  := 0;
      w_compensazione_rata := 0;
      w_compensazione      := 0;
      -- estrazione totale compensazione_ruolo
      begin
         select nvl(sum(decode(motivo_compensazione,99,null,coru.compensazione)),0) compensazione
           into w_compensazione
           from compensazioni_ruolo coru
          where coru.ruolo       = rec_co.ruolo
            and coru.cod_fiscale = rec_co.cod_fiscale
            ;
      EXCEPTION
         WHEN others THEN
              w_compensazione := 0;
      end;
      FOR rec_rate IN sel_rate (rec_co.cod_fiscale, rec_co.ruolo, rec_co.ni) LOOP
        w_errore := to_char(length(w_riga_wrk))||'  5 '||rec_co.cod_fiscale;
        IF rec_co.rate = 0 THEN
           w_spese_postali_rata := p_spese_postali;
           w_compensazione_rata := w_compensazione;
           w_raim_imposta_round := round(rec_rate.importo_rata + w_spese_postali_rata - nvl(w_compensazione_rata,0),0);
        ELSIF rec_co.rate = rec_rate.rata THEN
           w_spese_postali_rata := p_spese_postali - w_tot_spese_rata;
           w_compensazione_rata := w_compensazione - w_compensazione_tot;
           w_raim_imposta_round := rec_co.importo_tot_arrotondato - w_sum_rate;
        ELSE
           w_spese_postali_rata := round(p_spese_postali/rec_co.rate,2);
           w_tot_spese_rata     := w_tot_spese_rata + w_spese_postali_rata;
           w_compensazione_rata := round(w_compensazione/rec_co.rate,2);
           w_compensazione_tot  := w_compensazione_tot + w_compensazione_rata;
           w_raim_imposta_round := round(rec_rate.importo_rata + w_spese_postali_rata - nvl(w_compensazione_rata,0),0);
           w_sum_rate           := w_sum_rate + w_raim_imposta_round;
        END IF;
        w_riga_wrk := w_riga_wrk
                    ||rec_rate.v_campo
                    ||replace(to_char(w_raim_imposta_round),'.',',')
                    ||';';
      END LOOP;
      if max_w_riga_wrk < length(w_riga_wrk) then
         max_w_riga_wrk := length(w_riga_wrk);
         DBMS_OUTPUT.Put_Line('max_w_riga_wrk: '||to_char(max_w_riga_wrk));
      end if;
      BEGIN
        insert into wrk_trasmissioni (numero, dati)
        values (w_progr_wrk, w_riga_wrk);
      EXCEPTION
        WHEN others THEN
             RAISE_APPLICATION_ERROR
                 (-20929,'Errore in inserimento wrk_trasmissione '||
                      ' ('||SQLERRM||')');
      END;
      COMMIT;
    end if;
  END LOOP;
  w_errore := ' Fine ';
EXCEPTION
  WHEN others THEN
    RAISE_APPLICATION_ERROR
       (-20939,w_errore||' ('||SQLERRM||')');
END;
/* End Procedure: ESTRAZIONE_TARSU_POSTE */
/

