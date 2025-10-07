--liquibase formatted sql 
--changeset abrandolini:20250326_152423_estrazione_tarsu_poste_2011 stripComments:false runOnChange:true 
 
create or replace procedure ESTRAZIONE_TARSU_POSTE_2011
      ( p_ruolo         IN number
      , p_spese_postali IN number
      , p_importo_tot_arr out number) IS
-- 07/11/2014 Betta T. Corretta insert in wrk_trasmissioni per aggiunta di campi
CURSOR sel_co (a_spese_postali number) IS
  select substr(
             decode(sogg.ni_presso
                   ,null,'Spett.le'||decode(sogg.sesso,'F',' sig.ra','M',' sig.','')
                   ,'Spett.le'||decode(sogg.sesso,'F',' sig.ra','M',' sig.','')
                    ||' '||replace(replace(sogg.cognome_nome,'/',' '),';',',')
                   )
                 ,1,44)||';'||                                                                        -- Rigadestinatario1
           substr(
             decode(sogg.ni_presso
                   ,null,replace(replace(sogg.cognome_nome,'/',' '),';',',')
                   ,'c/o '||replace(replace(sogP.cognome_nome,'/',' '),';',',')
                   )
                 ,1,44)||';'||                                                                        -- Rigadestinatario2
           decode(sogg.ni_presso
                 ,null,substr(decode(sogg.cod_via
                                    ,to_number(null),sogg.denominazione_via
                                    ,arvi.denom_uff
                                    )
                             ||' '||to_char(sogg.num_civ)
                             ||decode(sogg.suffisso,'','','/'||sogg.suffisso)
                             ||decode(sogg.scala,'','',' Sc.'||sogg.scala)
                             ||decode(sogg.piano,'','',' P.'||sogg.piano)
                             ||decode(sogg.interno,'','',' Int.'||sogg.interno)
                           ,1,44)||';'
                 ,substr(decode(sogP.cod_via
                               ,to_number(null),sogP.denominazione_via
                               ,arvP.denom_uff
                               )
                          ||' '||to_char(sogP.num_civ)
                          ||decode(sogP.suffisso,'','','/'||sogP.suffisso)
                          ||decode(sogP.scala,'','',' Sc.'||sogP.scala)
                          ||decode(sogP.piano,'','',' P.'||sogP.piano)
                          ||decode(sogP.interno,'','',' Int.'||sogP.interno)
                        ,1,44)||';'
                 )||                                                                              -- Rigadestinatario3
           substr(
             decode(sogg.ni_presso
                   ,null,lpad(to_char(nvl(sogg.cap,comR.cap)),5,'0')||' '
                         ||substr(comR.denominazione,1,30)||' '
                         ||substr(proR.sigla,1,2)
                   ,lpad(to_char(nvl(sogP.cap,comP.cap)),5,'0')||' '
                    ||substr(comP.denominazione,1,30)||' '
                    ||substr(proP.sigla,1,2)
                   )
                  ,1,44)||';'||                                                                  -- Rigadestinatario4
         decode(sogg.ni_presso
               ,null,sttR.denominazione
               ,sttP.denominazione
               )||';'||                                                                          -- Estero
         substr(replace(replace(sogg.cognome_nome,'/',' '),';',','),1,37)||
         ';'||                                                                                   -- NOME1
         substr(decode(sogg.cod_via,
                        to_number(null),sogg.denominazione_via,
                        arvi.denom_uff)
                ||' '||to_char(sogg.num_civ)
                     ||decode(sogg.suffisso,'','','/'||sogg.suffisso)
                     ||decode(sogg.scala,'','',' Sc.'||sogg.scala)
                     ||decode(sogg.piano,'','',' P.'||sogg.piano)
                     ||decode(sogg.interno,'','',' Int.'||sogg.interno),1,44)||';'||             -- INDIR
         lpad(nvl(to_char(nvl(sogg.cap,nvl(comR.cap,0))),''),5,'0')|| ';'||                      -- CAP
         nvl(substr(comR.denominazione,1,30),'') || ';'||                                        -- DEST (città del versante)
         nvl(substr(proR.sigla,1,2),'') || ';'||                                                 -- PROVincia
         'N;'||                                                                                  -- IBAN
         decode(nvl(deba.cod_abi,0)
               ,0, ''
               ,decode(deba.flag_delega_cessata
                      ,'S',decode(sign(nvl(data_ritiro_delega,to_date('01011900','ddmmyyyy'))
                                        - ruoli.data_emissione)
                                 , -1,''
                                 ,'*'
                                 )
                      ,'*'
                      )
              )  || ';'||                                                                  -- DOMiciliazione bancaria postale
          'COD.UT.: '||to_char(sogg.ni)||' C.F. P.IVA: '||cont.cod_fiscale||';'||              -- VAR01D
          'C.F. P.IVA: '||cont.cod_fiscale||';'                                               -- VAR01S
                                                                                     prima_parte
       ,  'Importo Netto: '
            ||replace(to_char(imco.importo_netto,'FM999990.00'),'.',',')||' euro;'||                            -- NOTE01
          'Addizionale ECA ('
            ||replace(to_char(cata.addizionale_eca),'.',',')||'%): '
            ||replace(to_char(imco.addizionale_eca,'FM999990.00'),'.',',')||' euro;'||                          -- NOTE02
          'Maggiorazione ECA ('
            ||replace(to_char(cata.maggiorazione_eca),'.',',')||'%): '
            ||replace(to_char(imco.maggiorazione_eca,'FM999990.00'),'.',',')||' euro;'||                        -- NOTE03
           decode(cata.addizionale_pro
                 ,null,''
                 ,'Addizionale Provinciale ('
                    ||replace(to_char(cata.addizionale_pro),'.',',')||'%): '
                    ||replace(to_char(imco.addizionale_pro,'FM999990.00'),'.',',')||' euro;'
                 )||                                                                              -- NOTE04
           decode(cata.aliquota
                 ,null,''
                 ,'IVA ('
                    ||replace(to_char(cata.aliquota),'.',',')||'%): '
                    ||replace(to_char(imco.iva,'FM999990.00'),'.',',')||' euro;'
                 )                                                                                -- NOTE05
                                                                                 seconda_parte
       , ruoli.ruolo
       , ruoli.rate
       , round(imco.importo_lordo,0) + a_spese_postali                           importo_tot_arrotondato
       , imco.importo_lordo                                                      da_pagare
       , cont.cod_fiscale                                                        cod_fiscale
       , sogg.ni                                                                 ni
       , imco.maggiorazione_tares                                                maggiorazione_tares
    from ruoli
       , (select r.ruolo, r.cod_fiscale,
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
            group by r.ruolo, r.cod_fiscale)            imco
      , carichi_tarsu      cata
      , contribuenti       cont
      , soggetti           sogg
      , archivio_vie       arvi
      , ad4_comuni         comR
      , ad4_provincie      proR
      , ad4_stati_territori  sttR
      , soggetti           sogP
      , archivio_vie       arvP
      , ad4_comuni         comP
      , ad4_provincie      proP
      , ad4_stati_territori sttP
      , deleghe_bancarie   deba
   where ruoli.ruolo              = p_ruolo
     and imco.ruolo               = ruoli.ruolo
     and cata.anno                = ruoli.anno_ruolo
     and cont.cod_fiscale         = imco.cod_fiscale
     and cont.ni                  = sogg.ni
     and arvi.cod_via         (+) = sogg.cod_via
     and comR.provincia_stato (+) = sogg.cod_pro_res
     and comR.comune          (+) = sogg.cod_com_res
     and proR.provincia       (+) = sogg.cod_pro_res
     and sttR.stato_territorio  (+) = sogg.cod_pro_res
     and sogP.ni              (+) = sogg.ni_presso
     and arvP.cod_via         (+) = sogP.cod_via
     and comP.provincia_stato (+) = sogP.cod_pro_res
     and comP.comune          (+) = sogP.cod_com_res
     and proP.provincia       (+) = sogP.cod_pro_res
     and sttP.stato_territorio (+)= sogP.cod_pro_res
     and deba.cod_fiscale     (+) = cont.cod_fiscale
     and deba.tipo_tributo    (+) = 'TARSU'
   order by sogg.cognome_nome;
CURSOR sel_ubi (w_cod_fiscale varchar2) IS
   select substr(decode(ogge.cod_via
                    ,null, ogge.indirizzo_localita
                    ,arvi.denom_uff
                    )
               ||decode(ogge.num_civ
                       ,null, ''
                       ,', ' || to_char(ogge.num_civ)
                       )
               ||decode(ogge.suffisso
                       ,null, ''
                       ,'/' || ogge.suffisso)
               ||decode(cate.descrizione
                       ,null, ''
                       ,' - '||cate.descrizione
                       )
                 ,1,60)
           || ' - MQ. ' || translate(to_char(ogpr.consistenza,'FM9,999,999,990'),'.,',',.')
           || ' - EURO ' || translate(to_char(ogim.imposta,'FM9,999,999,990.99'),'.,',',.')
           ||';'                                                                 note
         , ogpr.oggetto_pratica
         , ogim.oggetto_imposta
     from ruoli,
          ruoli_contribuente ruco,
          oggetti_imposta ogim,
          oggetti_pratica ogpr,
          categorie cate,
          carichi_tarsu cata,
          tariffe tari,
          oggetti ogge,
          archivio_vie arvi
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
    order by 1;
CURSOR sel_fam (w_oggetto_imposta number, w_oggetto_pratica number) IS
   select decode(nvl(nvl(ogpr.numero_familiari,faog.numero_familiari),0),0,''
                , 'Dal: '||to_char(decode(faog.numero_familiari
                                         , null ,nvl(ogva.dal,to_date('01011900','ddmmyyyy'))
                                         , faog.dal),'dd/mm/yyyy')
                  ||' al: '||to_char(decode(faog.numero_familiari
                                           , null ,nvl(ogva.al,to_date('31122999','ddmmyyyy'))
                                           , faog.al),'dd/mm/yyyy')
                  ||' numero familiari: '||nvl(ogpr.numero_familiari,faog.numero_familiari)||'. ')
          ||'Quota fissa: '
          ||decode (ogim.dettaglio_ogim
                   , null, ltrim(rtrim(substr(faog.dettaglio_faog,49,17)))
                   ,ltrim(rtrim(substr(ogim.dettaglio_ogim,49,17))))
          ||' Quota variabile: '
          ||decode (ogim.dettaglio_ogim
                   , null, ltrim(rtrim(substr(faog.dettaglio_faog,114,17)))
                   ,ltrim(rtrim(substr(ogim.dettaglio_ogim,114,17))))
          ||';'                                       note2
     from oggetti_pratica ogpr,
          oggetti_imposta ogim,
          familiari_ogim              faog,
          oggetti_validita            ogva
    where ogim.oggetto_imposta = w_oggetto_imposta
      and ogpr.oggetto_pratica = w_oggetto_pratica
      and faog.oggetto_imposta (+) = ogim.oggetto_imposta
      and ogpr.oggetto_pratica = ogva.oggetto_pratica
    order by 1;
CURSOR sel_rate (w_cod_fiscale varchar2, w_ruolo number, w_ni number) IS
  select raim.rata,
         to_char(ruol.anno_ruolo)||
         to_char(nvl(raim.rata,0))||
         lpad(to_char(ruol.ruolo),4,'0')||
         lpad(to_char(w_ni),7,'0')||';' v_campo,
         sum(nvl(raim.imposta,0))
          + sum(nvl(raim.addizionale_eca,0))
          + sum(nvl(raim.maggiorazione_eca,0))
          + sum(nvl(raim.addizionale_pro,0))
          + sum(nvl(raim.iva,0)) importo_rata
    from ruoli ruol,
         ruoli_contribuente ruco,
         oggetti_imposta ogim,
         rate_imposta raim
   where ruol.ruolo               = w_ruolo
     and ruco.ruolo               = ruol.ruolo
     and ruco.cod_fiscale         = w_cod_fiscale
     and ogim.oggetto_imposta     = ruco.oggetto_imposta
     and raim.oggetto_imposta     = ogim.oggetto_imposta
   group by ruol.anno_ruolo
          , raim.rata
          , ruol.ruolo
   order by raim.rata;
w_progr_ubicazione      number;
w_max_progr_ubicazione  number;
w_spese_postali         number(6,2);
w_spese_postali_rata    number(6,2);
w_tot_spese_rata        number(6,2);
w_progr_wrk             number :=1;
w_riga_wrk              varchar2(4000);
w_sum_rate              number(15,2);
w_raim_imposta_round    number(15,2);
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
r                       number;
w_cod_istat             varchar2(6);
w_max_rate              number;
w_anno_ruolo            number;
w_responsabile_ruolo    varchar2(61);
w_tot_maggiorazione_tares    number;
w_importo_totale_arrotondato number  := 0;
w_importo_rata_0             number;
w_importo_rata_1             number;
w_importo_rata_2             number;
w_importo_rata_3             number;
w_importo_rata_4             number;
w_scadenza_rata_0            varchar2(10);
w_scadenza_rata_1            varchar2(10);
w_scadenza_rata_2            varchar2(10);
w_scadenza_rata_3            varchar2(10);
w_scadenza_rata_4            varchar2(10);
w_vcampot                    varchar2(17);
w_vcampo1                    varchar2(17);
w_vcampo2                    varchar2(17);
w_vcampo3                    varchar2(17);
w_vcampo4                    varchar2(17);
w_addizionale_pro            number;
w_aliquota                   number;
w_importo_prima_rata         number;
w_conta_utenze               number;
w_riga_rata                  varchar2(2000);
w_riga_causale               varchar2(2000);
w_utenze_contribuente        number;
w_compensazione              number;
w_compensazione_rata         number;
w_compensazione_tot          number;
max_w_intestazione           number := 0;
max_w_riga_wrk               number := 0;
w_progressivo                number;
w_num_note                   number;
w_comune                     varchar2(100);
w_max_rata                   date;
-- 40 è il numero massimo di VARXXA previsti dal tracciato per le Ubicazioni
-- per ogni ubicazione dobbiamo riempire 2 campi, quindi al massimo possiamo
-- gestire 20 ubicazioni
w_num_max_utenze        number := 40;
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
      select lpad(to_char(dage.pro_cliente), 3, '0') ||
             lpad(to_char(dage.com_cliente), 3, '0')
           , comu.denominazione
        into w_cod_istat
           , w_comune
        from dati_generali dage
           , ad4_comuni    comu
       where dage.pro_cliente = comu.provincia_stato
         and dage.com_cliente = comu.comune
           ;
   EXCEPTION
      WHEN no_data_found THEN
         null;
      WHEN others THEN
         w_errore := 'Errore in ricerca Codice Istat del Comune ' || ' (' ||
                     SQLERRM || ')';
         RAISE errore;
   END;
   BEGIN
    select rate
         , anno_ruolo
         , cognome_resp
           ||decode(nome_resp
                   ,null,''
                   ,' '||nome_resp
                   )
      into w_max_rate
         , w_anno_ruolo
         , w_responsabile_ruolo
      from ruoli
     where ruolo = p_ruolo
       and tipo_tributo = 'TARSU'
         ;
   EXCEPTION
     WHEN others THEN
       RAISE_APPLICATION_ERROR
           (-20919,'Errore in ricerca max rata'||
                ' ('||SQLERRM||')');
   END;
   BEGIN
    select cata.addizionale_pro
         , cata.aliquota
      into w_addizionale_pro
         , w_aliquota
      from carichi_tarsu  cata
     where cata.anno = w_anno_ruolo
         ;
   EXCEPTION
     WHEN others THEN
       RAISE_APPLICATION_ERROR
           (-20919,'Errore in ricerca carichi TARSU'||
                ' ('||SQLERRM||')');
   END;
   BEGIN
    select sum(o.maggiorazione_tares) maggiorazione_tares
      into w_tot_maggiorazione_tares
      from ruoli_contribuente r,oggetti_imposta o
     where r.ruolo = p_ruolo
       and o.ruolo = r.ruolo
       and r.oggetto_imposta = o.oggetto_imposta
         ;
   EXCEPTION
     WHEN others THEN
       RAISE_APPLICATION_ERROR
           (-20919,'Errore in ricerca maggiorazione TARES'||
                ' ('||SQLERRM||')');
   END;
   BEGIN
      select to_char(ruol.scadenza_prima_rata,'dd/mm/yyyy')
           , to_char(ruol.scadenza_prima_rata,'dd/mm/yyyy')
           , to_char(ruol.scadenza_rata_2,'dd/mm/yyyy')
           , to_char(ruol.scadenza_rata_3,'dd/mm/yyyy')
           , to_char(ruol.scadenza_rata_4,'dd/mm/yyyy')
           , decode(ruol.rate
                   ,0,scadenza_prima_rata
                   ,1,scadenza_prima_rata
                   ,2,scadenza_rata_2
                   ,3,scadenza_rata_3
                   ,4,scadenza_rata_4
                   )
        into w_scadenza_rata_0
           , w_scadenza_rata_1
           , w_scadenza_rata_2
           , w_scadenza_rata_3
           , w_scadenza_rata_4
           , w_max_rata
        from ruoli ruol
       where ruol.ruolo = p_ruolo
           ;
   EXCEPTION
      WHEN others THEN
         w_errore := ('Errore nella ricerca delle scadenze ' || ' (' || SQLERRM || ')' );
         raise errore;
   END;
   if w_max_rata is null then
      w_errore := 'Errore: verificare le scadenze del Ruolo!';
      raise errore;
   end if;
   BEGIN
      select max(nvl(fam.numero_ubicazioni,0)+nvl(fam.numero_familiari,0))
        into w_max_progr_ubicazione
        from (select ruco.cod_fiscale,
                     count(1) numero_familiari,
                     max(ubic.numero_ubicazioni) numero_ubicazioni
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
                     oggetti_validita            ogva,
                    (select cod_fiscale,count(1) numero_ubicazioni
                       from ruoli_contribuente ruco
                      where ruolo = p_ruolo
                   group by cod_fiscale) ubic
               where ruoli.ruolo          = p_ruolo
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
                 and ubic.cod_fiscale = ruco.cod_fiscale
            group by ruco.cod_fiscale) fam
          ;
   EXCEPTION
      WHEN others THEN
         RAISE_APPLICATION_ERROR
           (-20919,'Errore in ricerca max ubicazioni'||
                ' ('||SQLERRM||')');
   END;
   -- l'ultimo VARXXA (VAR40A) lo utilizziamo per la maggiorazione_tares se c'è
   if nvl(w_tot_maggiorazione_tares,0) != 0 then
      w_num_max_utenze := w_num_max_utenze - 1;
   end if;
   if w_max_progr_ubicazione > w_num_max_utenze then
      w_max_progr_ubicazione := w_num_max_utenze;
   end if;
   i:= 0;
  -----------------------------------
  --- Intestazione ------------------
  -----------------------------------
  w_intest_prima   := 'Rigadestinatario1;Rigadestinatario2;Rigadestinatario3;Rigadestinatario4;Estero;NOME1;INDIRIZZO;CAP;DEST;PROV;IBAN;DOM;VAR01D;VAR01S;';
  w_intestazione   := w_intest_prima;
   r := 0;
   WHILE r < w_max_rate
   LOOP
     w_intestazione := w_intestazione||'CS'||to_char(r+1)||';';
     r:= r +1;
   END LOOP;
   i := 0;
   WHILE i < w_max_progr_ubicazione
   LOOP
     w_intestazione := w_intestazione||'VAR'||lpad( to_char(i+1),2,'0')||'A;';
     i:= i +1;
   END LOOP;
   if nvl(w_tot_maggiorazione_tares,0) != 0 then
      w_intestazione := w_intestazione||'VAR40A;';
   end if;
--   if (w_max_rate = 0) or (w_max_rate = 2) or (w_max_rate = 4) then
      w_intest_seconda := 'NOTE01;NOTE02;NOTE03;';
      w_num_note := 3;
      if w_addizionale_pro is not null then
         w_num_note := w_num_note + 1;
         w_intest_seconda := w_intest_seconda || 'NOTE'||lpad(to_char(w_num_note),2,'0')||';';
      end if;
      if w_aliquota is not null then
         w_num_note := w_num_note + 1;
         w_intest_seconda := w_intest_seconda || 'NOTE'||lpad(to_char(w_num_note),2,'0')||';';
      end if;
      w_num_note := w_num_note + 1;
      w_intest_seconda := w_intest_seconda || 'NOTE'||lpad(to_char(w_num_note),2,'0')||';';
      w_num_note := w_num_note + 1;
      w_intest_seconda := w_intest_seconda || 'NOTE'||lpad(to_char(w_num_note),2,'0')||';';
      if w_responsabile_ruolo is not null then
         w_num_note := w_num_note + 1;
         w_intest_seconda := w_intest_seconda || 'NOTE'||lpad(to_char(w_num_note),2,'0')||';';
      end if;
/*   else
      w_intest_seconda := '';
   end if;*/
   w_intestazione := w_intestazione||w_intest_seconda;
   w_intest_terza   := 'VCAMPOT;XRATAT;SCADET';
   w_intestazione := w_intestazione||w_intest_terza;
   r := 0;
   WHILE r < w_max_rate
   LOOP
     w_intestazione := w_intestazione||';VCAMPO'||to_char(r+1)||';XRATA'||to_char(r+1)||';SCADE'||to_char(r+1);
     r:= r +1;
   END LOOP;
   w_progr_wrk := w_progr_wrk + 1;
   BEGIN
      insert into wrk_trasmissioni (numero, dati)
      values (lpad(w_progr_wrk,15,'0')
             ,w_intestazione
             )
             ;
   EXCEPTION
      WHEN others THEN
           RAISE_APPLICATION_ERROR
               (-20929,'Errore in inserimento wrk_trasmissione '||
                    ' ('||SQLERRM||')');
   END;
   max_w_intestazione := length(w_intestazione);
   DBMS_OUTPUT.Put_Line('max_w_intestazione: '||to_char(max_w_intestazione));
   ------------------------------------
   --- Inizio -------------------------
   ------------------------------------
   w_errore := ' Inizio ';
   w_spese_postali := nvl(p_spese_postali,0);
   FOR rec_co  IN sel_co (w_spese_postali) LOOP --Contribuenti
      --dbms_output.put_line(rec_cont.cod_fiscale || ' ' || rec_cont.cognome_nome || ' ' || rec_cont.ni);
      w_progressivo    := 0;
      w_importo_rata_0 := 0;
      w_importo_rata_1 := 0;
      w_importo_rata_2 := 0;
      w_importo_rata_3 := 0;
      w_importo_rata_4 := 0;
      -- Prima Parte
      w_riga_wrk := rec_co.prima_parte;
      w_errore := to_char(length(w_riga_wrk))||'  1 '||rec_co.cod_fiscale;
      w_riga_rata := '';
      w_riga_causale := '';
      if rec_co.rate > 0 then
         w_spese_postali_rata := round(w_spese_postali/rec_co.rate,2);
      else
         w_spese_postali_rata := w_spese_postali;
      end if;
      --Determinazione degli Importi Rateizzati a livello di Contribuente
      FOR rec_rate IN sel_rate (rec_co.cod_fiscale, rec_co.ruolo, rec_co.ni) LOOP --Rate
         w_riga_causale := w_riga_causale || 'RUOLO '||f_descrizione_titr('TARSU',w_anno_ruolo)
                           ||' - ANNO '||to_char(w_anno_ruolo)||' - RATA '||to_char(rec_rate.rata)||';';
         if rec_rate.rata = 1 then
            -- w_importo_prima_rata lo utilizzo come valore per tutte le rate tranne l'ultima
            w_importo_prima_rata := rec_rate.importo_rata;
            IF rec_co.rate = rec_rate.rata THEN
               w_importo_rata_1 := rec_co.importo_tot_arrotondato - ( ( round(w_importo_prima_rata,0) + w_spese_postali_rata)  * (rec_co.rate - 1) ) ;
            else
               w_importo_rata_1 := round(w_importo_prima_rata,0) + w_spese_postali_rata;
            end if;
            --Inserimento dei dati sulla rata 1
            w_vcampo1 := to_char(w_anno_ruolo) || '1' || lpad(p_ruolo,4,'0') || lpad(rec_co.ni,7,'0')||';';
            w_riga_rata := w_riga_rata || ';' || w_vcampo1  || ltrim(translate(to_char(w_importo_rata_1,'999999990.00'),'.',',')) || ';' || w_scadenza_rata_1;
         end if;
         if rec_rate.rata = 2 then
            IF rec_co.rate = rec_rate.rata THEN
               w_importo_rata_2 := rec_co.importo_tot_arrotondato - ( ( round(w_importo_prima_rata,0) + w_spese_postali_rata)  * (rec_co.rate - 1) ) ;
            else
               w_importo_rata_2 := round(w_importo_prima_rata,0) + w_spese_postali_rata;
            end if;
            --Inserimento dei dati sulla rata 2
            w_vcampo2 := to_char(w_anno_ruolo) || '2' || lpad(p_ruolo,4,'0') || lpad(rec_co.ni,7,'0')||';';
            w_riga_rata := w_riga_rata || ';' || w_vcampo2 || ltrim(translate(to_char(w_importo_rata_2,'999999990.00'),'.',',')) || ';' || w_scadenza_rata_2;
         end if;
         if rec_rate.rata = 3 then
            IF rec_co.rate = rec_rate.rata THEN
               w_importo_rata_3 := rec_co.importo_tot_arrotondato - ( ( round(w_importo_prima_rata,0) + w_spese_postali_rata)  * (rec_co.rate - 1) ) ;
            else
               w_importo_rata_3 := round(w_importo_prima_rata,0) + w_spese_postali_rata;
            end if;
            --Inserimento dei dati sulla rata 3
            w_vcampo3 := to_char(w_anno_ruolo) || '3' || lpad(p_ruolo,4,'0') || lpad(rec_co.ni,7,'0')||';';
            w_riga_rata := w_riga_rata || ';' || w_vcampo3 || ltrim(translate(to_char(w_importo_rata_3,'999999990.00'),'.',',')) || ';' || w_scadenza_rata_3;
         end if;
         if rec_rate.rata = 4 then
            IF rec_co.rate = rec_rate.rata THEN
               w_importo_rata_4 := rec_co.importo_tot_arrotondato - ( ( round(w_importo_prima_rata,0) + w_spese_postali_rata)  * (rec_co.rate - 1) ) ;
            else
               w_importo_rata_4 := round(w_importo_prima_rata,0) + w_spese_postali_rata;
            end if;
            --Inserimento dei dati sulla rata 4
            w_vcampo4 := to_char(w_anno_ruolo) || '4' || lpad(p_ruolo,4,'0') || lpad(rec_co.ni,7,'0')||';';
            w_riga_rata := w_riga_rata || ';' || w_vcampo4 || ltrim(translate(to_char(w_importo_rata_4,'999999990.00'),'.',',')) || ';' || w_scadenza_rata_4;
         end if;
      END LOOP; --rec_raim
      -- Inserimento Causale rate (CS1-12 Moscato Salvatore)
      r := 0;
      if w_riga_causale is null then
         WHILE r < w_max_rate
         loop
            w_riga_causale := w_riga_causale||';';
            r := r + 1;
         end loop;
      end if;
      w_riga_wrk := w_riga_wrk||w_riga_causale;
      w_utenze_contribuente := 0;
      FOR rec_ubi IN sel_ubi (rec_co.cod_fiscale) LOOP --OGIM
         w_conta_utenze := w_conta_utenze + 1;
         w_utenze_contribuente := w_utenze_contribuente + 1;
         if w_utenze_contribuente <= w_num_max_utenze  then
            w_riga_wrk := w_riga_wrk || rec_ubi.note;
            FOR rec_fam IN sel_fam (rec_ubi.oggetto_imposta,rec_ubi.oggetto_pratica) LOOP
               w_conta_utenze := w_conta_utenze + 1;
               w_utenze_contribuente := w_utenze_contribuente + 1;
               if w_utenze_contribuente <= w_num_max_utenze  then
                  w_riga_wrk := w_riga_wrk || rec_fam.note2;
               end if;
            END LOOP;
         end if;
      END LOOP; --sel_ogim
      -- Inserimento dei (;) per avere lo stesso numero di VARXXA per tutti i contribuenti
      WHILE w_utenze_contribuente < w_max_progr_ubicazione
      LOOP
        w_riga_wrk := w_riga_wrk||';';
        w_utenze_contribuente:= w_utenze_contribuente +1;
      END LOOP;
      -- Inserimento di maggiorazione_tares
      if nvl(w_tot_maggiorazione_tares,0) != 0 then  -- AB 25/07/2016 inserito questo controllo perche altrimenti viene il campo, ma non intestazione
         if nvl(rec_co.maggiorazione_tares,0) != 0 then
            w_riga_wrk := w_riga_wrk||'Maggiorazione Tares per lo Stato: '
                          ||replace(to_char(rec_co.maggiorazione_tares,'FM999990.00'),'.',',')||';';
         else
            w_riga_wrk := w_riga_wrk||';';
         end if;
      end if;
      -- Si inserisce solo se il numero di pagamenti è dispari (rate pari)
      -- NOTE01-NOTE08
      -- Tolto per estrarre sempre i dati, indipendentemente dal numero delle rate
--      if (w_max_rate = 0) or (w_max_rate = 2) or (w_max_rate = 4) then
         w_riga_wrk := w_riga_wrk||rec_co.seconda_parte;
         w_riga_wrk := w_riga_wrk||'AVVISO DI PAGAMENTO '
                       ||f_descrizione_titr('TARSU',w_anno_ruolo)||';';
         w_riga_wrk := w_riga_wrk||'COMUNE DI '||w_comune||' - UFFICIO TRIBUTI;';
         if w_responsabile_ruolo is not null then
            w_riga_wrk := w_riga_wrk||'RESPONSABILE DEL PROCEDIMENTO: '||w_responsabile_ruolo||';';
         end if;
--      end if;
      --Importo e scadenza rata 0
      w_importo_rata_0 := rec_co.importo_tot_arrotondato;
      --Inserimento dei dati sull'imposta totale (o rata 0)
      w_vcampot := to_char(w_anno_ruolo) || '0' || lpad(p_ruolo,4,'0') || lpad(rec_co.ni,7,'0')||';';
      w_riga_wrk := w_riga_wrk || w_vcampot || ltrim(translate(to_char(w_importo_rata_0,'999999990.00'),'.',',')) || ';' || w_scadenza_rata_0;
      r := 0;
      if w_riga_rata is null then
         WHILE r < w_max_rate
         loop
            w_riga_rata := w_riga_rata||';';
            r := r + 1;
         end loop;
      end if;
      w_riga_wrk := w_riga_wrk || w_riga_rata;
      w_progr_wrk := w_progr_wrk + 1; --Conta anche il numero dei contribuenti trattati +1
      BEGIN
         insert into wrk_trasmissioni(numero
                                    , dati)
         values (lpad(w_progr_wrk,15,'0')
               , w_riga_wrk);
      EXCEPTION
         WHEN others THEN
            w_errore := ('Errore in inserimento wrk_trasmissione' || ' (' || SQLERRM || ')' );
            raise errore;
      END;
      w_importo_totale_arrotondato := w_importo_totale_arrotondato + w_importo_rata_0;
   END LOOP; --sel_cont
   p_importo_tot_arr := w_importo_totale_arrotondato ;
   w_errore := ' Fine ';
EXCEPTION
  WHEN others THEN
    RAISE_APPLICATION_ERROR
       (-20939,w_errore||' ('||SQLERRM||')');
END;
/* End Procedure: ESTRAZIONE_TARSU_POSTE_2011 */
/

