--liquibase formatted sql 
--changeset abrandolini:20250326_152423_estrazione_tares_poste stripComments:false runOnChange:true 
 
create or replace procedure ESTRAZIONE_TARES_POSTE
( p_ruolo             IN number
, p_spese_postali     IN number
, p_importo_limite    IN number
, p_se_vers_positivi  IN varchar2
, p_addebito_cc       IN varchar2
, p_flag_tariffa_base IN varchar2 default null
, p_numero_anni       IN number
, p_insolvenza_min    IN number
, p_stringa_vers_reg  IN varchar2
, p_stringa_vers_irr  IN varchar2
, p_importo_tot_arr  out number)
IS
/*************************************************************************
 NOME:        ESTRAZIONE_TARES_POSTE
 DESCRIZIONE: Estrazione dati TARSU comprensivi di F24 per invio massivo
              comunicazioni a ruolo
 NOTE:        Personalizzazioni:
              048035 - Reggello: nei dati delle utenze non si espone la
                       tipologia Domestica/Non domestica
              049014 - Portoferraio: colonne aggiuntive
              015192 - S.Donato Milanese: i dati del contribuente UnipolSAI
                       vengono ridotti per problemi di dimensione della riga
                       (superiore a 32000 caratteri)
              036013 - Fiorano Modenese: esposizione dati IBAN e domiciliazione
                       bancaria.
                       Eliminata esposizione conferimenti.
              017025 - Bovezzo: nuovi campi per dovuto anni precedenti.
                       10/06/2019: eliminati i campi:
                       IMPOSTA NETTA ACCONTO
                       ADD. PROVINCIALE ACCONTO
                       IMPOSTA LORDA ACCONTO
                       RESIDUO LORDO ACCONTO
 Data        Autore      Descrizione
 20/12/2021  VD          Richiesta di Bovezzo: modificate intestazioni nei campi
                         VARXX (da MM a MESI, da E. a EURO).
 26/04/2021  VD          Occhiobello: corretto passaggio parametri a funzione
                         F_GET_STRINGA_VERSAMENTI.
 30/03/2021  VD          Aggiunti campi per gestione TEFA 2021
 20/11/2020  VD          Aggiunti campi relativi ai versamenti degli anni
                         precedenti.
 10/06/2019  VD          Bovezzo: eliminati i campi relativi all'acconto
 20/03/2019  VD          Aggiunta gestione nuovi campi di dettaglio per
                         ruoli calcolati con tariffe
 19/12/2018  VD          Aggiunta gestione file blob (per righe con più di 32000
                         caratteri)
 13/12/2018  VD          Aggiunta gestione importi calcolati con tariffa base
 05/12/2018  VD          Personalizzazione Bovezzo
 27/09/2018  VD          Aggiunta estrazione sgravi sul ruolo
 26/09/2018  VD          Fiorano Modenese: eliminata esposizione conferimenti
 09/05/2018  VD          S.Donato Milanese: per il contribuente UNIPOLSAI
                         non si stampano i dati di dettaglio importi dei
                         singoli oggetti
 10/04/2018  VD          Fiorano Modenese: aggiunti dati IBAN e
                         domiciliazione bancaria
 03/04/2018  VD          Modificata struttura riga: ora le colonne "VAR"
                         sono tutte in fondo alla riga
                         Il conteggio delle colonne utilizzate viene fatto
                         dopo aver trattato tutti i contribuenti
 14/03/2018  VD          Pontedera: aggiunti dati dei conferimenti andati
                         a ruolo
 29/09/2017  VD          Pontedera - Aggiunta estrazione sgravi per sconto
                         conferimenti temporanei
 13/07/2017  AB          Gestito il campo Estero correttamente, con decode
                         per vedere se esiste un comune di recapito, poi
                         si guarda se straniero, perche nel caso di comune
                         non estero usciva null e allora prendeva il
                         comune di residenza
 12/04/2017  VD          San Donato Milanese - Gestione caso UnipolSAI:
                         (numero oggetti > 100)
 23/11/2016  VD          San Donato Milanese - Sperimentazione Poasco
 22/08/2016  VD          Aggiunte nuove colonne per adeguamento a stampa
                         comunicazione ruolo; corrette intestazioni
                         errate
 05/07/2016  VD          Aggiunto controllo su parametro p_importo_limite:
                         puo' essere presente solo se si tratta un ruolo
                         a saldo
 28/06/2016  VD          Aggiunto parametro 'SE_VERS_POSITIVI' e eliminata
                         selezione parametro da modelli COM_TARSU
 18/01/2016  VD          Aggiunta gestione limite importo lordo ruolo.
                         Corretta select parametro per versamenti positivi
 16/07/2015  AB          Cambiata la select per il conteggio degli immobili
 14/05/2015  VD          Aggiunta riga di separazione tra un'utenza e l'altra
 23/03/2015  Betta T.    Aggiunti mesi ruolo
 19/01/2015  Betta T.    indicati imposta_evasa_accertata e magg_tares_evasa_accertata
                         come negativi
 19/01/2015  Betta T.    Corretti controlli sulla gestione di imposta_evasa_accertata
                         e magg_tares_evasa_accertata
 16/12/2014  Piero M.    Aggiunti i campi estratti 'IMPOSTA_EVASA_ACCERTATA' e  '
                         MAGG_TARES_EVASA_ACCERTATA'l'imposta evasa accertata
                         la maggiorazione evasa accertata vengono trattate
                         come versamenti e sottratte alle relative imposte
 11/12/2014  Betta T.    Aggiunti altri campi all'ordinamento per allinearli
                         completamente alla comunicazione
 10/12/2014  Betta T.    Modificati ordinamenti per allinearli alla comunicazione
 10/12/2014  Betta T.    Corretto errore nella divisione dei campi per la insert
 12/11/2014  Betta T.    Suddivisi su due campi VARxx indirizzo e dati catastali
 07/11/2014  Betta T.    Modificato per gestione nuovi campi in wrk_trasmissioni
                         Aggiunta magg tares (se significativa) per i dettagli
                         delle utenze
                         Sistemata anche select per determinare il numero massimo
                         di campi VARXX da stampare: intestavamo alcuni campi
                         che restavano vuoti.
 06/11/2014  A. Monopoli Corretta gestione del presso
 06/11/2014  Betta T.    Aggiunto test su parametro VERS_POSITIVI che usiamo per
                         la stampa della comunicazione per estrarre i versamenti
                         solo positivi oppure tutti.
 04/11/2014  Betta T.    Sistemata estrazione del numero di familiari:
             (più Piero) gli nvl erano invertiti: dobbiamo legger prima faog e
                         poi eventualmente ogpr
 03/11/2014  Betta T.    Prima dell'inserimento nella tabella di wrk faceva una
                         substr del campo. In questo modo non dava errore la
                         insert, ma il file esce con delle righe troncate
                         Ho tolto la substr.
 31/10/2014  Betta T.    I versamenti parziali vengono stampati con il segno -
                         I giorni li stampiamo sulla singola utenza
 30/10/2014  Betta T.    Aggiunti campi versato magg e versato al netto della
                         maggiorazione e maggiorazione dovutae dovuto annuo non arr.
 24/10/2014  Betta T.    Modifiche per gestire crediti di imposta x S. Donato
                         Corretta anche det. imposta netta in caso di sgravi su
                         maggiorazione (non erano gestiti correttamente)
 08/10/2014  Betta T.    ATTENZIONE MODIFICATO PERCHè è CAMBIATA F_RECAPITO
                         Se si ricrea bisogna ricreare F_RECAPITO e le viste
                         CONTRIBUENTI_ENTE e SOGGETTI_PRATICA
 07/10/2014  Betta T.    Modificato per estrarre gli estremi catastali al posto della
                         descrizione della categoria solo x S. Donato.
                         Se S. Donato prompt categoria TARES aggiunto come UD Cat
                         o UND Cat x utenze domestiche o non domestiche
                         Messi due decimali fissi nel campo imposta degli oggetti
 03/10/2014  Betta T.    Modificata intestazione dei campi VARnnX per gestire
                         anche numeri di più di 2 cifre (VAR99X, VAR100X)
                         prima usciva VAR10X
 30/09/2014  Betta T.    Modificato per gestione del presso nei recapiti
**************************************************************************/
w_max_progr_ubicazione       number;
w_data_indirizzi             date := trunc(sysdate); -- per ora usiamo la data_emissione
w_spese_postali              number(6,2);
w_importo_limite             number;
w_spese_postali_rata         number(6,2);
w_tot_spese_rata             number(6,2);
w_progr_wrk                  number :=1;
w_riga_wrk                   varchar2(32767);
w_sum_rate                   number(15,2);
w_raim_imposta_round         number(15,2);
w_errore                     varchar2(4000);
errore                       exception;
w_se_vers_positivi           varchar2(1);
w_intestazione               varchar2(32767);
w_intest_seconda             varchar2(32767);
w_intest_rate                varchar2(32767);
w_int_rateazione             varchar2(32767);
w_int_rata_a                 varchar2(32767);
w_int_varXX                  varchar2(32767);
i                            number;
n                            number;
r                            number;
w_cod_istat                  varchar2(6);
w_tipo_emissione             varchar2(1);
w_max_rate                   number;
w_anno_ruolo                 number;
w_responsabile_ruolo         varchar2(61);
w_progr_ruolo                number;
w_flag_tariffe_ruolo         varchar2(1);
w_tot_maggiorazione_tares    number;
w_numero_ubicazioni          number;
w_importo_totale_arrotondato number  := 0;
w_importo_rata_0             number;
w_importo_rata_1             number;
w_importo_rata_2             number;
w_importo_rata_3             number;
w_importo_rata_4             number;
w_versato                    number;
w_tot_rate                   number;
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
w_importo_tot_x_rate         number;
w_importo_add_prov_x_rate    number;
w_addizionale_pro            number;
w_aliquota                   number;
w_importo_rata               number;
w_sgravio_imposta            number;
w_sgravio_add_pro            number;
w_riga_rata                  varchar2(32767);
w_riga_rata_a                varchar2(32767);
w_riga_rata_rateaz           varchar2(32767);
w_riga_causale               varchar2(32767);
w_stringa_dettaglio          varchar2(32767);
w_utenze_contribuente        number;
w_num_note                   number;
w_comune                     varchar2(100);
w_cod_catast_comune          varchar2(6);
w_max_rata                   date;
w_tot_complessivo            number;
w_tot_complessivo_a          number;
w_tares_add_prov_a           number;
w_tares_add_prov_not         number;
w_tares_add_prov_not_a       number;
w_coeff_fissa                varchar2(3);
w_coeff_var                  varchar2(3);
w_str_mq_fissa               varchar2(10);
w_str_mq_var                 varchar2(10);
w_riga_varXX                 varchar2(32767);
w_str_dett_fam               varchar2(32767);
w_str_conferimenti           varchar2(32767);
w_lunghezza_prec             number;
w_lunghezza_new              number;
w_dati                       varchar2(4000);
w_dati2                      varchar2(4000);
w_dati3                      varchar2(4000);
w_dati4                      varchar2(4000);
w_dati5                      varchar2(4000);
w_dati6                      varchar2(4000);
w_dati7                      varchar2(4000);
w_dati8                      varchar2(4000);
-- 40 è il numero massimo di VARXXA previsti dal tracciato per le Ubicazioni
-- per ogni ubicazione dobbiamo riempire 2 campi, quindi al massimo possiamo
-- gestire 20 ubicazioni
--w_num_max_utenze             number := 40;
--w_ruolo_prec             number;
--
-- (VD - 12/04/2017): variabile contenente il codice fiscale di UnipolSAI
--
w_cod_unipol                 varchar2(16) := '00818570012';
--
-- (VD - 14/03/2018): Pontedera, variabili per conferimenti
--
w_dal_conf                   date;
w_al_conf                    date;
w_conta_conf                 number;
-- (VD - 05/12/2018): Bovezzo, variabili per personalizzazione
w_numero_anni                number;
w_insolvenza_min             number;
w_note_utenza                varchar2(2000);
w_stringa_anni               varchar2(100);
w_ruolo_acconto              number;
w_importo_anno               number;
w_imp_dovuto                 number;
w_imp_versato                number;
w_imp_sgravi                 number;
w_ind                        number;
type t_importo_anno_t        is table of number index by binary_integer;
t_importo_anno               t_importo_anno_t;
-- (VD - 18/12/2018): gestione file clob
TYPE VettoreRighe            IS TABLE OF VARCHAR2(32767)
INDEX BY BINARY_INTEGER;
Riga_file                    VettoreRighe;
w_riga                       varchar2(32000);
w_file_clob_1                clob;
w_file_clob                  clob;
-- (VD - 30/03/2021): variabili per ruoli emessi dal 2021 in avanti
w_rata_tari                  number;
w_rata_tefa                  number;
w_descr_titr                 varchar2(60);
CURSOR sel_co ( a_spese_postali    number
              , a_se_vers_positivi varchar2
              , a_importo_limite   number
              , a_addebito_cc      varchar2) IS
  select substr(
             decode(sogg.ni_presso
                   ,null,
                   decode(f_recapito(sogg.ni, 'TARSU', 1, ruoli.data_emissione,'PR')
                         ,null,'Spett.le'||decode(sogg.sesso,'F',' sig.ra','M',' sig.','')
                         ,'Spett.le'||decode(sogg.sesso,'F',' sig.ra','M',' sig.','')
                          ||' '||replace(replace(sogg.cognome_nome,'/',' '),';',',')
                          )
                   ,'Spett.le'||decode(sogg.sesso,'F',' sig.ra','M',' sig.','')
                    ||' '||replace(replace(sogg.cognome_nome,'/',' '),';',',')
                   )
                 ,1,44)||';'||                                                                   -- Rigadestinatario1
           substr(
             decode(sogg.ni_presso
                   ,null,nvl(f_recapito(sogg.ni, 'TARSU', 1, ruoli.data_emissione,'PR')
                            ,replace(replace(sogg.cognome_nome,'/',' '),';',','))
                   ,'c/o '||replace(replace(sogP.cognome_nome,'/',' '),';',',')
                   )
                 ,1,44)||';'||                                                                   -- Rigadestinatario2
           decode(sogg.ni_presso
                 ,null,nvl(f_recapito(sogg.ni, 'TARSU', 1, ruoli.data_emissione) ,
                           substr(decode(sogg.cod_via
                                    ,to_number(null),sogg.denominazione_via
                                    ,arvi.denom_uff
                                    )
                             ||' '||to_char(sogg.num_civ)
                             ||decode(sogg.suffisso,'','','/'||sogg.suffisso)
                             ||decode(sogg.scala,'','',' Sc.'||sogg.scala)
                             ||decode(sogg.piano,'','',' P.'||sogg.piano)
                             ||decode(sogg.interno,'','',' Int.'||sogg.interno)
                           ,1,44))||';'
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
                 )||                                                                             -- Rigadestinatario3
           substr(
             decode(sogg.ni_presso
                   ,null,nvl(f_recapito(sogg.ni, 'TARSU', 1, ruoli.data_emissione,'CC') ,
                              lpad(to_char(nvl(sogg.cap,comR.cap)),5,'0')||' '
                                   ||substr(comR.denominazione,1,30)||' '
                                   ||substr(proR.sigla,1,2) )
                   ,lpad(to_char(nvl(sogP.cap,comP.cap)),5,'0')||' '
                    ||substr(comP.denominazione,1,30)||' '
                    ||substr(proP.sigla,1,2)
                   )
                  ,1,44)||';'||                                                                  -- Rigadestinatario4
         decode(sogg.ni_presso
               ,null,decode(f_recapito(sogg.ni, 'TARSU', 1, ruoli.data_emissione,'CO')
                            ,'',sttR.denominazione
                               ,f_recapito(sogg.ni, 'TARSU', 1, ruoli.data_emissione,'SE'))
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
         decode(deba.cod_abi,to_char(null)
               ,'N;'||
                decode(deba.flag_delega_cessata
                      ,'S',decode(sign(nvl(data_ritiro_delega,to_date('01011900','ddmmyyyy'))
                                       - ruoli.data_emissione)
                                 , -1,''
                                 ,'*'
                                 )
                           ,'*'
                      )
               ,rpad(nvl(deba.iban_paese,' '),2,' ')||
                lpad(to_char(nvl(deba.iban_cin_europa,0)),2,'0')||
                nvl(deba.cin_bancario,' ')||
                lpad(to_char(nvl(deba.cod_abi,0)),5,'0')||
                lpad(to_char(nvl(deba.cod_cab,0)),5,'0')||
                rpad(nvl(deba.conto_corrente,'0'),12,'0')||
                ';'||
                ad4_banche_tpk.get_denominazione(lpad(deba.cod_abi,5,'0'))||
                ' - '||
                ad4_sportelli_tpk.get_descrizione(lpad(deba.cod_abi,5,'0'),lpad(deba.cod_cab,5,'0'))
               )  || ';'||                                                           -- IBAN + domiciliazione bancaria
          'COD.UT.: '||to_char(sogg.ni)||' C.F. P.IVA: '||cont.cod_fiscale||';'||    -- VAR01D
          'C.F. P.IVA: '||cont.cod_fiscale||';'                                      -- VAR01S
                                                                                     prima_parte
       ,  'Importo Netto: euro '
            ||replace(to_char(imco.importo_netto,'FM999990.00'),'.',',')||';'||                  -- NOTE01
          decode(nvl(cata.addizionale_eca,0)
                , 0, ''
                , 'Addizionale ECA ('
                  ||replace(to_char(cata.addizionale_eca),'.',',')||'%): euro '
                  ||replace(to_char(imco.addizionale_eca,'FM999990.00'),'.',','))||';'||         -- NOTE02
          decode(nvl(cata.maggiorazione_eca,0)
                , 0, ''
                , 'Maggiorazione ECA ('
                  ||replace(to_char(cata.maggiorazione_eca),'.',',')||'%): euro '
                  ||replace(to_char(imco.maggiorazione_eca,'FM999990.00'),'.',','))||';'||       -- NOTE03
           decode(cata.addizionale_pro
                 ,null,''
                 ,decode(w_cod_istat,'049014','','Addizionale Provinciale ('
                    ||replace(to_char(cata.addizionale_pro),'.',',')||'%): euro ')
                    ||replace(to_char(imco.addizionale_pro,'FM999990.00'),'.',',')||';'
                 )||                                                                             -- NOTE04
           decode(cata.aliquota
                 ,null,''
                 ,'IVA ('
                    ||replace(to_char(cata.aliquota),'.',',')||'%): euro '
                    ||replace(to_char(imco.iva,'FM999990.00'),'.',',')||';'
                 )                                                                               -- NOTE05
                                                                                 seconda_parte
       , ruoli.ruolo
       , decode(ruoli.rate,0,1,null,1,ruoli.rate)                                rate
       , round(nvl(imco.importo_lordo,0) - nvl(imco.maggiorazione_tares,0)
              + a_spese_postali,0)
         - round(imco.versato_netto_tot,0)
         - round(nvl(imco.imposta_evasa_accertata,0),0)                          importo_tot_arrotondato
--       , greatest(0,round(nvl(imco.importo_lordo,0) - nvl(imco.maggiorazione_tares,0)
--                    + a_spese_postali,0))                                        importo_tot_arrotondato
       , nvl(imco.importo_lordo,0) - nvl(imco.maggiorazione_tares,0)
         + nvl(imco.compensazione,0) + NVL(a_spese_postali,0)                    importo_tot_s_no_comp
       , imco.importo_lordo                                                      da_pagare
       , cont.cod_fiscale                                                        cod_fiscale
       , sogg.ni                                                                 ni
       , round(imco.maggiorazione_tares,0) - imco.versato_magg_tares
         - round(nvl(imco.magg_tares_evasa_accertata,0),0)                       maggiorazione_tares
       , sogg.cognome                                                            cognome
       , sogg.nome                                                               nome
       , to_char(sogg.data_nas,'dd/mm/yyyy')                                     data_nascita
       , sogg.sesso                                                              sesso
       , comN.denominazione                                                      comune_nascita
       , proN.sigla                                                              provincia_nascita
       , f_primo_erede_cod_fiscale (sogg.ni)                                     cod_fiscale_erede
       , imco.addizionale_pro                                                    addizionale_pro
       , nvl(imco.importo_netto,0) - imco.versato_netto_tot
         - nvl(imco.imposta_evasa_accertata,0)                                   importo_netto
       , decode(nvl(ruoli.tipo_emissione, 'T')
                   ,'A', 0
                   ,'T', 0
                   ,imco_prec.rate_ruolo_prec) rate_iniz_prec
       , decode(nvl(ruoli.tipo_emissione, 'T')
                   ,'A', 1
                   ,'T', 0
                   ,imco_prec.rate_ruolo_prec) rate_prec
       , imco.giorni_ruolo
       , imco.mesi_ruolo
       , nvl(imco.versato_tot,0)    versato_tot
       , nvl(imco.maggiorazione_tares ,0) - imco.versato_magg_tares
         - nvl(imco.magg_tares_evasa_accertata,0)                                            magg_tares_no_arr
       , nvl(imco.compensazione    ,0)                                                       compensazione
       , nvl(imco_prec.addizionale_pro_prec ,0)                                              addizionale_pro_prec
       , nvl(imco_prec.importo_netto_prec ,0)                                                importo_netto_prec
       , (nvl(imco_prec.importo_netto_prec,0) +nvl(imco_prec.addizionale_pro_prec ,0)    )   importo_lordo_prec
       , nvl(sgravi_cont.sgravio_lordo  ,0)                                                  sgravio_lordo
       , nvl(sgravi_cont.sgravio_prov ,0)                                                    sgravio_prov
       , nvl(sgravi_cont.sgravio_netto,0)                                                    sgravio_netto
       , nvl(imco_prec.addizionale_pro_prec ,0)     -   nvl(sgravi_cont.sgravio_prov,0)      residuo_acconto_prov
       , nvl(imco_prec.importo_netto_prec,0)
         - (nvl(sgravi_cont.sgravio_lordo,0)
         - nvl(sgravi_cont.sgravio_prov,0))
                                                                                             residuo_acconto_netto
       , (nvl(imco_prec.importo_netto_prec,0) +nvl(imco_prec.addizionale_pro_prec,0) )
        - nvl( sgravi_cont.sgravio_lordo,0)
                                                                                             residuo_acconto_lordo
       , imco.dovuto_netto_annuo
       , imco.addizionale_pro_annua
       , nvl(imco.dovuto_netto_annuo,0) + nvl(imco.addizionale_pro_annua,0)                  dovuto_lordo_annuo
       , imco.importo_lordo_x_rate
       , imco.versato_netto_tot
       , imco.magg_tares_dovuta
       , imco.versato_magg_tares
       , imco.imposta_evasa_accertata
       , imco.magg_tares_evasa_accertata
       -- (VD - 23/08/2016): aggiunte colonne per adeguamento a stampa comunicazione
       , nvl(imco.dovuto_netto_annuo,0) + nvl(sgravi_cont.sgravio_netto,0) tares_netta_annua
       , nvl(imco.addizionale_pro_annua,0) + nvl(sgravi_cont.sgravio_prov,0) add_prov_annua
       , nvl(imco.dovuto_netto_annuo,0) + nvl(imco.addizionale_pro_annua,0) + nvl(sgravi_cont.sgravio_lordo,0) importo_lordo_annuo
         -- (VD - 13/12/2018): aggiunti dati relativi al calcolo con tariffa base
       , imco.imposta_base
       , imco.addizionale_eca_base
       , imco.maggiorazione_eca_base
       , imco.addizionale_pro_base
       , imco.iva_base
       , imco.importo_pf_base
       , imco.importo_pv_base
       , imco.importo_ruolo_base
       , imco.importo_pf
       , imco.importo_pv
       , imco.importo_riduzione_pf
       , imco.importo_riduzione_pv
       , sgravi_cont.sgravio_lordo_base
       , sgravi_cont.sgravio_prov_base
       , sgravi_cont.sgravio_netto_base
       -- (VD - 30/03/2021): Aggiunti campi per gestione TEFA 2021
       , imco.imposta_2021
       , imco.imposta_netta_2021
       , imco.add_pro_2021
       , imco.add_pro_netta_2021
       , imco.sgravio_imposta_2021
       , imco.sgravio_add_pro_2021
       , imco.comp_imposta_2021
       , imco.comp_add_pro_2021
       , round(imco.imposta_netta_2021) - imco.imposta_netta_2021 arr_imposta_2021
       , round(imco.add_pro_netta_2021) - imco.add_pro_netta_2021 arr_add_pro_2021
       , round(imco.imposta_netta_2021) - imco.imposta_netta_2021 +
         round(imco.add_pro_netta_2021) - imco.add_pro_netta_2021 arr_totale_2021
       , imco.versato_imposta
       , imco.versato_add_pro
    from ruoli
       ,  (select r.ruolo, r.cod_fiscale,
                  sum(r.importo)
                    - f_tot_vers_cont_ruol(ruol.anno_ruolo
                                          ,r.cod_fiscale
                                          ,ruol.tipo_tributo
                                          ,r.ruolo
                                          ,'S')
                    - f_tot_vers_cont_ruol(ruol.anno_ruolo
                                        ,r.cod_fiscale
                                        ,ruol.tipo_tributo
                                        ,r.ruolo
                                        ,'C')
--                    - decode(nvl(ruol.tipo_emissione, 'T')
--                            ,'T', f_tot_vers_cont_ruol(ruol.anno_ruolo
--                                                      ,r.cod_fiscale
--                                                      ,ruol.tipo_tributo
--                                                      ,null
--                                                      ,'VN')
--                            ,0)
--                    - decode(nvl(ruol.tipo_emissione, 'T')
--                            ,'T', f_tot_vers_cont_ruol(ruol.anno_ruolo
--                                                      ,r.cod_fiscale
--                                                      ,ruol.tipo_tributo
--                                                      ,null
--                                                     ,'M')
--                            ,0
--                            )
/*                    - decode(nvl(ruol.tipo_emissione, 'T')
                            ,'T', least(nvl(sum(o.maggiorazione_tares),0)
                                       ,f_tot_vers_cont_ruol(ruol.anno_ruolo
                                                            ,r.cod_fiscale
                                                            ,ruol.tipo_tributo
                                                            ,null
                                                            ,'M')
                                       )
-- se la magg tares ha un versato superiore alla magg calcolata lo consideriamo
-- solo per la parte di maggiorazione non per l'eccedenza
                            ,0
                            )*/
                                        importo_lordo,
                  round(sum(r.importo)
                    - f_tot_vers_cont_ruol(ruol.anno_ruolo
                                          ,r.cod_fiscale
                                          ,ruol.tipo_tributo
                                          ,r.ruolo
                                          ,'S')
                    + f_tot_vers_cont_ruol(ruol.anno_ruolo
                                          ,r.cod_fiscale
                                          ,ruol.tipo_tributo
                                          ,r.ruolo
                                          ,'SM')
                    - f_tot_vers_cont_ruol(ruol.anno_ruolo
                                        ,r.cod_fiscale
                                        ,ruol.tipo_tributo
                                        ,r.ruolo
                                        ,'C')
                  - nvl(sum(o.maggiorazione_tares),0),0)
                                        importo_lordo_x_rate,
-- gli importi sono calcolati come importo - gli sgravi sul ruolo
-- - le compensazioni sul ruolo - se il ruolo è totale i versamenti su tutto l'anno
-- per determinare l'importo lordo, non consideriamo i versamenti
                  sum(o.addizionale_eca) addizionale_eca,
                  sum(o.maggiorazione_eca) maggiorazione_eca,
                  sum(o.addizionale_pro) addizionale_pro,
                  sum(o.iva) iva,
                  sum(o.imposta)
                    - f_tot_vers_cont_ruol(ruol.anno_ruolo
                                          ,r.cod_fiscale
                                          ,ruol.tipo_tributo
                                          ,r.ruolo
                                          ,'S')
                    + f_tot_vers_cont_ruol(ruol.anno_ruolo
                                          ,r.cod_fiscale
                                          ,ruol.tipo_tributo
                                          ,r.ruolo
                                          ,'SM')
                    - f_tot_vers_cont_ruol(ruol.anno_ruolo
                                          ,r.cod_fiscale
                                          ,ruol.tipo_tributo
                                          ,r.ruolo
                                          ,'C')
--                    - decode(nvl(ruol.tipo_emissione, 'T')
--                            ,'T', f_tot_vers_cont_ruol(ruol.anno_ruolo
--                                                      ,r.cod_fiscale
--                                                      ,ruol.tipo_tributo
--                                                      ,null
--                                                      ,'VN')
--                            ,0)
                                        importo_netto,
                  sum(o.maggiorazione_tares)
--                  - decode(nvl(ruol.tipo_emissione, 'T')
--                          ,'T', f_tot_vers_cont_ruol(ruol.anno_ruolo
--                                                    ,r.cod_fiscale
--                                                    ,ruol.tipo_tributo
--                                                    ,null
--                                                    ,'M')
--                         ,0)
                          maggiorazione_tares
/*                  greatest(0,sum(o.maggiorazione_tares)
                             - decode(nvl(ruol.tipo_emissione, 'T')
                                     ,'T', f_tot_vers_cont_ruol(ruol.anno_ruolo
                                                               ,r.cod_fiscale
                                                               ,ruol.tipo_tributo
                                                               ,null
                                                               ,'M')
                                     ,0)) maggiorazione_tares*/
                , max(r.giorni_ruolo) giorni_ruolo
                , max(r.mesi_ruolo) mesi_ruolo
                ,decode(nvl(ruol.tipo_emissione, 'T')
                            ,'T', f_tot_vers_cont_ruol(ruol.anno_ruolo
                                        ,r.cod_fiscale
                                        ,ruol.tipo_tributo
                                        ,null
                                        ,'V'||a_se_vers_positivi)
                            ,0) versato_tot
                ,decode(nvl(ruol.tipo_emissione, 'T')
                            ,'T', f_tot_vers_cont_ruol(ruol.anno_ruolo
                                        ,r.cod_fiscale
                                        ,ruol.tipo_tributo
                                        ,null
                                        ,'VN'||a_se_vers_positivi)
                            ,0) versato_netto_tot
                ,decode(nvl(ruol.tipo_emissione, 'T')
                            ,'T', f_tot_vers_cont_ruol(ruol.anno_ruolo
                                        ,r.cod_fiscale
                                        ,ruol.tipo_tributo
                                        ,null
                                        ,'VI'||a_se_vers_positivi)
                            ,0) versato_imposta
                ,decode(nvl(ruol.tipo_emissione, 'T')
                            ,'T', f_tot_vers_cont_ruol(ruol.anno_ruolo
                                        ,r.cod_fiscale
                                        ,ruol.tipo_tributo
                                        ,null
                                        ,'VP'||a_se_vers_positivi)
                            ,0) versato_add_pro
                ,f_tot_vers_cont_ruol(ruol.anno_ruolo
                                        ,r.cod_fiscale
                                        ,ruol.tipo_tributo
                                        ,r.ruolo
                                        ,'C') compensazione
                ,sum(nvl(o.imposta_dovuta,o.imposta)) dovuto_netto_annuo
                ,sum(round(nvl(o.imposta_dovuta,o.imposta) * catu.addizionale_pro / 100
                           ,2)) addizionale_pro_annua
                ,sum(o.maggiorazione_tares) magg_tares_dovuta
                ,decode(nvl(ruol.tipo_emissione, 'T')
                            ,'T', f_tot_vers_cont_ruol(ruol.anno_ruolo
                                                      ,r.cod_fiscale
                                                      ,ruol.tipo_tributo
                                                      ,null
                                                     ,'M')
                            ,0
                            ) versato_magg_tares
                ,decode(nvl(ruol.tipo_emissione, 'T')
                            ,'T', decode (ruol.tipo_ruolo
                                         ,2, F_IMPOSTA_EVASA_ACC(r.cod_fiscale,'TARSU',ruol.anno_ruolo,'N')
                                         ,0
                                         )
                            ,0
                            ) imposta_evasa_accertata
                ,decode(nvl(ruol.tipo_emissione, 'T')
                            ,'T', decode (ruol.tipo_ruolo
                                         ,2, F_IMPOSTA_EVASA_ACC(r.cod_fiscale,'TARSU',ruol.anno_ruolo,'S')
                                         ,0
                                         )
                            ,0
                            ) magg_tares_evasa_accertata
                -- (VD - 13/12/2018): aggiunti dati relativi al calcolo con tariffa base
                ,sum(o.imposta_base)           imposta_base
                ,sum(o.addizionale_eca_base)   addizionale_eca_base
                ,sum(o.maggiorazione_eca_base) maggiorazione_eca_base
                ,sum(o.addizionale_pro_base)   addizionale_pro_base
                ,sum(o.iva_base)               iva_base
                ,sum(o.importo_pf_base)        importo_pf_base
                ,sum(o.importo_pv_base)        importo_pv_base
                ,sum(o.importo_ruolo_base)     importo_ruolo_base
                -- (VD - 27/03/2019): aggiunti importi pf, pv e relative riduzioni
                ,sum(o.importo_pf)             importo_pf
                ,sum(o.importo_pv)             importo_pv
                ,sum(o.importo_riduzione_pf)   importo_riduzione_pf
                ,sum(o.importo_riduzione_pv)   importo_riduzione_pv
                -- (VD - 30/03/2021): aggiunti campi per gestione TEFA 2021
                ,sum(o.imposta)                imposta_2021
                ,sum(o.imposta)
                    - f_tot_vers_cont_ruol(ruol.anno_ruolo
                                          ,r.cod_fiscale
                                          ,ruol.tipo_tributo
                                          ,r.ruolo
                                          ,'SN')
                    - f_tot_vers_cont_ruol(ruol.anno_ruolo
                                          ,r.cod_fiscale
                                          ,ruol.tipo_tributo
                                          ,r.ruolo
                                          ,'CN') imposta_netta_2021
                ,sum(o.addizionale_pro)        add_pro_2021
                ,sum(o.addizionale_pro)
                    - f_tot_vers_cont_ruol(ruol.anno_ruolo
                                          ,r.cod_fiscale
                                          ,ruol.tipo_tributo
                                          ,r.ruolo
                                          ,'SP')
                    - f_tot_vers_cont_ruol(ruol.anno_ruolo
                                          ,r.cod_fiscale
                                          ,ruol.tipo_tributo
                                          ,r.ruolo
                                          ,'CP') add_pro_netta_2021
                ,-1 * f_tot_vers_cont_ruol(ruol.anno_ruolo
                                          ,r.cod_fiscale
                                          ,ruol.tipo_tributo
                                          ,r.ruolo
                                          ,'SN') sgravio_imposta_2021
                ,-1 * f_tot_vers_cont_ruol(ruol.anno_ruolo
                                          ,r.cod_fiscale
                                          ,ruol.tipo_tributo
                                          ,r.ruolo
                                          ,'SP') sgravio_add_pro_2021
                ,-1 * f_tot_vers_cont_ruol(ruol.anno_ruolo
                                          ,r.cod_fiscale
                                          ,ruol.tipo_tributo
                                          ,r.ruolo
                                          ,'CN') comp_imposta_2021
                ,-1 * f_tot_vers_cont_ruol(ruol.anno_ruolo
                                          ,r.cod_fiscale
                                          ,ruol.tipo_tributo
                                          ,r.ruolo
                                          ,'CP') comp_add_pro_2021
             from ruoli_contribuente r
                , oggetti_imposta o
                , ruoli ruol
                , carichi_tarsu catu
            where r.ruolo = p_ruolo
              and o.ruolo = r.ruolo
              and r.oggetto_imposta = o.oggetto_imposta
              and catu.anno = ruol.anno_ruolo
              and ruol.ruolo = r.ruolo
            group by r.ruolo
                   , r.cod_fiscale
                   , ruol.anno_ruolo
                   , ruol.tipo_tributo
                   , ruol.tipo_emissione
                   , ruol.rate
                   , ruol.tipo_ruolo)            imco
      , carichi_tarsu      cata
      , contribuenti       cont
      , soggetti           sogg
      , archivio_vie       arvi
      , ad4_comuni         comR
      , ad4_provincie      proR
      , ad4_comuni         comN
      , ad4_provincie      proN
      , ad4_stati_territori  sttR
      , soggetti           sogP
      , archivio_vie       arvP
      , ad4_comuni         comP
      , ad4_provincie      proP
      , ad4_stati_territori sttP
      , deleghe_bancarie   deba
      ,  (select r.cod_fiscale,ruol.tipo_tributo,
                  sum(r.importo)
--                    - f_tot_vers_cont_ruol(ruol.anno_ruolo
--                                          ,r.cod_fiscale
--                                          ,ruol.tipo_tributo
--                                          ,r.ruolo
--                                          ,'S')
                    - sum(f_tot_vers_cont_ruol(ruol.anno_ruolo
                                        ,r.cod_fiscale
                                        ,ruol.tipo_tributo
                                        ,r.ruolo
                                        ,'C'))
                    - decode(nvl(ruol.tipo_emissione, 'T')
                            ,'T', f_tot_vers_cont_ruol(ruol.anno_ruolo
                                                      ,r.cod_fiscale
                                                      ,ruol.tipo_tributo
                                                      ,null
                                                      ,'V'||a_se_vers_positivi)
                                  + decode (ruol.tipo_ruolo
                                           ,2, round(F_IMPOSTA_EVASA_ACC(r.cod_fiscale,'TARSU',ruol.anno_ruolo,'N'),0)
                                           ,0
                                           )
                            ,0)
                                       importo_lordo_PREC,
                  sum(o.addizionale_eca) addizionale_eca_PREC,
                  sum(o.maggiorazione_eca) maggiorazione_eca_PREC,
                  sum(o.addizionale_pro) addizionale_pro_PREC,
                  sum(o.iva) iva_PREC,
                  sum(o.imposta)
--                    - f_tot_vers_cont_ruol(ruol.anno_ruolo
--                                          ,r.cod_fiscale
--                                          ,ruol.tipo_tributo
--                                          ,r.ruolo
--                                          ,'S')
 /*                 - sum(f_tot_vers_cont_ruol(ruol.anno_ruolo
                                        ,r.cod_fiscale
                                        ,ruol.tipo_tributo
                                        ,r.ruolo
                                        ,'C'))
                    - decode(nvl(ruol.tipo_emissione, 'T')
                            ,'T', f_tot_vers_cont_ruol(ruol.anno_ruolo
                                                      ,r.cod_fiscale
                                                      ,ruol.tipo_tributo
                                                      ,null
                                                      ,'VN')
                            ,0)*/
                                        importo_netto_PREC,
                  sum(o.maggiorazione_tares)
                  - decode(nvl(ruol.tipo_emissione, 'T')
                          ,'T', f_tot_vers_cont_ruol(ruol.anno_ruolo
                                                    ,r.cod_fiscale
                                                    ,ruol.tipo_tributo
                                                    ,null
                                                    ,'M')
                                + decode (ruol.tipo_ruolo
                                         ,2, round(F_IMPOSTA_EVASA_ACC(r.cod_fiscale,'TARSU',ruol.anno_ruolo,'S'),0)
                                         ,0
                                         )
                          , 0
                          ) maggiorazione_tares_PREC
/*                  greatest(0,sum(o.maggiorazione_tares)
                             - decode(nvl(ruol.tipo_emissione, 'T')
                                     ,'T', f_tot_vers_cont_ruol(ruol.anno_ruolo
                                                               ,r.cod_fiscale
                                                               ,ruol.tipo_tributo
                                                               ,null
                                                               ,'M')
                                     ,0)) maggiorazione_tares_PREC*/
                , max(r.giorni_ruolo) giorni_ruolo_PREC
                , max(decode(ruol.rate
                          ,0, 1
                          ,null, 1
                          ,ruol.rate)) rate_ruolo_prec
                -- (VD - 13/12/2018): aggiunti dati relativi al calcolo con tariffa base
                , sum(o.imposta_base)           imposta_base_prec
                , sum(o.addizionale_eca_base)   add_eca_base_prec
                , sum(o.maggiorazione_eca_base) magg_eca_base_prec
                , sum(o.addizionale_pro_base)   add_pro_base_prec
                , sum(o.iva_base)               iva_base_prec
                , sum(o.importo_pf_base)        importo_pf_base_prec
                , sum(o.importo_pv_base)        importo_pv_base_prec
                , sum(o.importo_ruolo_base)     importo_ruolo_base_prec
             from ruoli_contribuente r,oggetti_imposta o,ruoli ruol
            where ruol.ruolo in (SELECT ruol_prec.ruolo
                                   FROM RUOLI , ruoli ruol_prec
                                  where nvl(ruol_prec.tipo_emissione(+), 'T') = 'A'
                                    and ruol_prec.invio_consorzio(+) is not null
                                    and ruol_prec.anno_ruolo(+) = ruoli.anno_ruolo
                                    and ruol_prec.tipo_tributo(+) || '' = ruoli.tipo_tributo
                                    and ruoli.ruolo = p_ruolo)
              and o.ruolo = r.ruolo
              and r.oggetto_imposta = o.oggetto_imposta
              and ruol.ruolo = r.ruolo
            group by r.cod_fiscale
                   , ruol.anno_ruolo
                   , ruol.tipo_tributo
                   , ruol.tipo_emissione
                   , ruol.rate
                   , ruol.tipo_ruolo)            imco_prec
      , (SELECT sum( importo) sgravio_lordo
               ,sum(addizionale_pro) sgravio_prov
               ,sum(nvl(importo,0) - nvl(addizionale_pro,0)) sgravio_netto
                -- (VD - 13/12/2018): aggiunti dati relativi al calcolo con tariffa base
               ,sum(importo_base) sgravio_lordo_base
               ,sum(addizionale_pro_base) sgravio_prov_base
               ,sum(nvl(importo_base,0) - nvl(addizionale_pro_base,0)) sgravio_netto_base
               ,cod_fiscale
           FROM sgravi
          where sgravi.ruolo in (SELECT ruol_prec.ruolo
                                   FROM RUOLI , ruoli ruol_prec
                                  where nvl(ruol_prec.tipo_emissione(+), 'T') = 'A'
                                    and ruol_prec.invio_consorzio(+) is not null
                                    and ruol_prec.anno_ruolo(+) = ruoli.anno_ruolo
                                    and ruol_prec.tipo_tributo(+) || '' = ruoli.tipo_tributo
                                    and ruoli.ruolo = p_ruolo)
            and motivo_sgravio!=99
          group by COD_FISCALE ) sgravi_cont
--        , ruoli ruol_prec
   where ruoli.ruolo              = p_ruolo
     and imco.ruolo               = ruoli.ruolo
     and cata.anno                = ruoli.anno_ruolo
     and cont.cod_fiscale         = imco.cod_fiscale
     and cont.ni                  = sogg.ni
     and arvi.cod_via         (+) = sogg.cod_via
     and comR.provincia_stato (+) = sogg.cod_pro_res
     and comR.comune          (+) = sogg.cod_com_res
     and proR.provincia       (+) = sogg.cod_pro_res
     and comN.provincia_stato (+) = sogg.cod_pro_nas
     and comN.comune          (+) = sogg.cod_com_nas
     and proN.provincia       (+) = sogg.cod_pro_nas
     and sttR.stato_territorio  (+) = sogg.cod_pro_res
     and sogP.ni              (+) = sogg.ni_presso
     and arvP.cod_via         (+) = sogP.cod_via
     and comP.provincia_stato (+) = sogP.cod_pro_res
     and comP.comune          (+) = sogP.cod_com_res
     and proP.provincia       (+) = sogP.cod_pro_res
     and sttP.stato_territorio (+)= sogP.cod_pro_res
     and deba.cod_fiscale     (+) = cont.cod_fiscale
     and deba.tipo_tributo    (+) = 'TARSU'
     and imco_prec.cod_fiscale (+) = imco.cod_fiscale
     and sgravi_cont.cod_fiscale (+) = imco.cod_fiscale
     and (nvl(ruoli.tipo_emissione,'T') <> 'S' or
         (nvl(ruoli.tipo_emissione,'T') = 'S' and nvl(imco.importo_lordo,0) >= a_importo_limite))
--     and cont.cod_fiscale not in ('12148530152')
--     and nvl(ruol_prec.tipo_emissione(+), 'T') = 'A'
--     and ruol_prec.invio_consorzio(+) is not null
--     and ruol_prec.anno_ruolo(+) = ruoli.anno_ruolo
--     and ruol_prec.tipo_tributo(+) || '' = ruoli.tipo_tributo
    and (a_addebito_cc = 'T' or
        (a_addebito_cc = 'S' and deba.cod_abi is not null) or
        (a_addebito_cc = 'N' and deba.cod_abi is null))
   order by sogg.cognome_nome;
CURSOR sel_ubi (w_cod_fiscale varchar2) IS
   select decode(w_cod_istat, '048035', -- Reggello
                             decode(ogge.cod_via
                                ,null, substr(ogge.indirizzo_localita,1,25)
                                ,substr(arvi.denom_uff,1,25)
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
                           ||decode(tari.descrizione
                                   ,null, ''
                                   ,' - '||tari.descrizione
                                   ),
                             decode(ogge.cod_via
                                ,null, substr(ogge.indirizzo_localita,1,25)
                                ,substr(arvi.denom_uff,1,25)
                                )
                           ||decode(ogge.num_civ
                                   ,null, ''
                                   ,', ' || to_char(ogge.num_civ)
                                   )
                           ||decode(ogge.suffisso
                                   ,null, ''
                                   ,'/' || ogge.suffisso)
                           ||' - '
                           ||decode(cate.flag_domestica,'S','UD Cat. ','UND Cat. ')
                           ||cate.categoria
                           --
                           -- (VD - 12/04/2017): se si tratta di S.Donato Milanese
                           --                    e UnipolSAI si considerano solo i
                           --                    primi 22 caratteri della
                           --                    descrizione della categoria
                           --
                           ||decode(cate.descrizione
                                   ,null, ''
                                   ,' - '||decode(w_cod_istat||w_cod_fiscale,
                                                  '015192'||w_cod_unipol,
                                                  substr(cate.descrizione,1,22),
                                                  cate.descrizione)
                                   )
                           --
                           -- (VD - 12/04/2017): se si tratta di S.Donato Milanese
                           --                    e UnipolSAI si sostituisce la
                           --                    parola TARIFFA con l'abbreviazione
                           --                    TAR. nella descrizione della tariffa
                           --
                           ||decode(tari.descrizione
                                   ,null, ''
                                   ,' - '||decode(w_cod_istat||w_cod_fiscale,
                                                  '015192'||w_cod_unipol,
                                                  replace(tari.descrizione,'TARIFFA','TAR.'),
                                                  tari.descrizione)
                                   ))
           ||';'                                                                 note1
                             ,
--                             substr(decode(ogge.cod_via
--                                ,null, substr(ogge.indirizzo_localita,1,25)
--                                ,substr(arvi.denom_uff,1,25)
--                                )
--                           ||decode(ogge.num_civ
--                                   ,null, ''
--                                   ,', ' || to_char(ogge.num_civ)
--                                   )
--                           ||decode(ogge.suffisso
--                                   ,null, ''
--                                   ,'/' || ogge.suffisso)
--                           ||decode(cate.descrizione
--                                   ,null, ''
--                                   ,' - '||cate.descrizione
--                                   )
--                             ,1,50)),
           ltrim(ltrim(decode(ogge.partita,null,'',' Part.'||OGGE.PARTITA)
           ||decode(ogge.sezione,null,'',' Sez.'||OGGE.SEZIONE)
           ||decode(ogge.foglio,null,'',' Fg.'||OGGE.FOGLIO)
           ||decode(ogge.numero,null,'',' Num.'||OGGE.NUMERO)
           ||decode(ogge.subalterno,null,'',' Sub.'||OGGE.SUBALTERNO)
           ||decode(ogge.zona,null,'',' Zona '||OGGE.ZONA)
           ||decode(ogge.categoria_catasto ,null,'',' Cat.'||OGGE.categoria_catasto)
           || ' - MQ ' || translate(to_char(ogpr.consistenza,'FM9,999,999,990'),'.,',',.')
           -- (VD - 20/12/2021): Bovezzo. Modificate intestazioni mesi e "euro"
           --|| decode(ruco.giorni_ruolo, null,' - MM' || to_char(ruco.mesi_ruolo,'990')
           || decode(ruco.giorni_ruolo, null,decode(w_cod_istat,'017025',' - Mesi',' - MM') || to_char(ruco.mesi_ruolo,'990')
                     ,' - GG' || to_char(ruco.giorni_ruolo,'990'))
           --|| decode(f_stampa_com_ruolo(p_ruolo),1,'',' - E. ' || translate(to_char(nvl(ogim.imposta_dovuta,ogim.imposta),'FM9,999,999,990.00'),'.,',',.')
           || decode(f_stampa_com_ruolo(p_ruolo),1,''
                    ,decode(w_cod_istat,'017025',' - Euro ',' - E. ') || translate(to_char(nvl(ogim.imposta_dovuta,ogim.imposta),'FM9,999,999,990.00'),'.,',',.')
                    )
           || decode(nvl(ogim.maggiorazione_tares,0),0,''
                    , '+Magg. ' || translate(to_char(ogim.maggiorazione_tares,'FM9,999,999,990.00'),'.,',',.')),' -'),' ')
           ||';'                                                                 note2
           --
           -- (VD - 28/03/2018): aggiunta selezione riepilogo importi per oggetto
           --
           , rpad('RESIDUO LORDO '||decode(ruoli.tipo_emissione,'A','ACCONTO','S','SALDO','T','TOTALE'),30)
           || lpad(translate(to_char(ogim.imposta + nvl(ogim.addizionale_pro,0)
                                                  + nvl(sgra.sgravio,0)
                                                  + nvl(sgra.sgravio_escl,0)
                                    ,'9,999,990.00'
                                    )
                            ,',.'
                            ,'.,'
                            )
                  ,15)||';' st_residuo_lordo
           ,rpad('IMPOSTA NETTA '||decode(ruoli.tipo_emissione,'A','ACCONTO','S','SALDO','T','TOTALE'),30)
           ||lpad(translate(to_char(ogim.imposta,'99,999,990.00'),',.','.,'),15)||';' st_imposta_netta
           ,rpad(upper(f_descrizione_adpr(ruoli.anno_ruolo))||decode(ruoli.tipo_emissione,'A',' ACCONTO','S',' SALDO','T',' TOTALE'),30)
           ||decode(nvl(cata.addizionale_pro, 0),0,''
                  ,lpad(ltrim(translate(to_char(decode(ruoli.importo_lordo
                                                      ,'S',ogim.addizionale_pro
                                                          ,round(ogim.imposta * nvl(cata.addizionale_pro,0) / 100,2)
                                                      )
                                               ,'9,999,990.00'
                                               )
                                       ,',.'
                                       ,'.,'
                                       )
                             ),15)
                   )||';' st_add_pro
           ,rpad('IMPOSTA LORDA '||decode(ruoli.tipo_emissione,'A','ACCONTO','S','SALDO','T','TOTALE'),30)
           ||lpad(translate(to_char(ogim.imposta + nvl(ogim.addizionale_pro,0) +
                                f_sgravio_ruco_escl(p_ruolo,w_cod_fiscale,ruco.sequenza,'L'),'99,999,990.00'),'.,',',.')
             ,15)||';' st_imposta_lorda
           --
           -- (VD - 25/03/2019): aggiunti nuovi campi riepilogo per ruoli a saldo
           --
           ,decode(ruoli.tipo_emissione,'S',
                rpad('IMPOSTA ANNUA',30)||
                lpad(translate(to_char(decode(ruoli.tipo_ruolo,1,
                                         nvl (ogim.imposta_dovuta, ogim.imposta) -
                                              decode(instr(ogim.dettaglio_ogim,'conferimento'),0,0
                                                    ,to_number(translate(substr(dettaglio_ogim,instr(dettaglio_ogim,' ',-1) + 1),',','.'))),
                                         trim(substr(ogim.note,instr(ogim.note,':',1,1)+1,instr(ogim.note,'-',1,1)-2 -instr(ogim.note,':',1,1)))
                                        )
                                 ,'9,999,990.00'
                                 )
                         ,',.'
                         ,'.,'
                         )
                    ,15)||';'
               ,''
               )
           st_imposta_netta_annua
        ,decode(ruoli.tipo_emissione,'S',
                rpad('IMPOSTA ACCONTO',30)||
                lpad(translate(to_char(
                                 decode(ruoli.tipo_ruolo,1,
                                        nvl (f_importi_ruolo_acconto( w_cod_fiscale
                                                                    , ruoli.anno_ruolo
                                                                    , ruoli.progr_emissione
                                                                    , ogco.data_decorrenza
                                                                    , ogco.data_cessazione
                                                                    , ruoli.tipo_tributo
                                                                    , ogpr.oggetto
                                                                    , ogpr.oggetto_pratica
                                                                    , ogpr.oggetto_pratica_rif
                                                                    , ruoli.tipo_calcolo
                                                                    , 'N'
                                                                    , 'I'
                                                                    ),0) * -1,
                                        to_number(trim(substr(ogim.note,instr(ogim.note,':',1,2)+1,instr(ogim.note,' ',1,8)-1 -instr(ogim.note,':',1,2)))) * -1
                                       )
                                ,'9,999,990.00'
                                )
                         ,',.'
                         ,'.,'
                         ),
                         15)||';'
               ,'') st_imposta_netta_acconto
         , ogpr.oggetto_pratica
         , ogim.oggetto_imposta
         , cate.flag_domestica
         , ogpr.consistenza     mq
         , f_get_familiari_ogim (ogim.oggetto_imposta) stringa_dettaglio
     from ruoli,
          ruoli_contribuente ruco,
          oggetti_imposta ogim,
          oggetti_pratica ogpr,
          oggetti_contribuente ogco,
          categorie cate,
          carichi_tarsu cata,
          tariffe tari,
          oggetti ogge,
          archivio_vie arvi,
          (select sequenza
                , sum(decode(f_stampa_com_ruolo(p_ruolo),1,
                           decode( substr(nvl(note,' '),1,1),'*', 0,
                           nvl (importo, 0)
                         )))
                   * -1
                     sgravio
                , sum(maggiorazione_tares) * -1 sgravio_magg
                , sum(decode(f_stampa_com_ruolo(p_ruolo),0,0,
                             decode(substr(nvl(note,' '),1,1),'*',
                                    nvl(importo,0),0)) * -1) sgravio_escl
             from sgravi
            where ruolo = p_ruolo
              and cod_fiscale = w_cod_fiscale
              and motivo_sgravio != 99
            group by sequenza) sgra
    where ruoli.ruolo          = p_ruolo
      and ruco.cod_fiscale     = w_cod_fiscale
      and ruco.ruolo           = ruoli.ruolo
      and ogim.oggetto_imposta = ruco.oggetto_imposta
      and ogpr.oggetto_pratica = ogim.oggetto_pratica
      and ogco.cod_fiscale     = w_cod_fiscale
      and ogco.oggetto_pratica = ogpr.oggetto_pratica
      and cate.tributo         = ogpr.tributo
      and cate.categoria       = ogpr.categoria
      and tari.anno            = ruoli.anno_ruolo
      and tari.tributo         = ogpr.tributo
      and tari.categoria       = ogpr.categoria
      and tari.tipo_tariffa    = ogpr.tipo_tariffa
      and ogge.oggetto         = ogpr.oggetto
      and arvi.cod_via (+)     = ogge.cod_via
      and cata.anno            = ruoli.anno_ruolo
      and sgra.sequenza(+)     = ruco.sequenza
      order by cate.categoria || ' - ' || cate.descrizione
             , tari.descrizione
             , decode(ogge.cod_via,null,ogge.indirizzo_localita
                     ,arvi.denom_uff
                     || decode(ogge.num_civ, null, '', ', ' || ogge.num_civ)
                     || decode(ogge.suffisso, null, '', '/' || ogge.suffisso))
             , ogim.oggetto_imposta
    ;
 --   order by 1;
-- (VD - 25/03/2019): questa select non serve più perchè si utilizza
--                    la funzione F_GET_FAMILIARI_OGIM nell query
--                    sel_ubi
CURSOR sel_fam (w_oggetto_imposta number, w_oggetto_pratica number) IS
   select decode(nvl(nvl(faog.numero_familiari,ogpr.numero_familiari),0),0,''
                , 'Dal: '||to_char(decode(faog.numero_familiari
                                         , null ,nvl(ogva.dal,to_date('01011900','ddmmyyyy'))
                                         , faog.dal),'dd/mm/yy')
                  ||' al: '||to_char(decode(faog.numero_familiari
                                           , null ,nvl(ogva.al,to_date('31122999','ddmmyyyy'))
                                           , faog.al),'dd/mm/yy')
                  ||' n.fam: '||nvl(faog.numero_familiari,ogpr.numero_familiari)||'. ')
--          ||'QF: '
--          ||decode (ogim.dettaglio_ogim
--                   , null, ltrim(rtrim(substr(faog.dettaglio_faog,49,17)))
--                   ,ltrim(rtrim(substr(ogim.dettaglio_ogim,49,17))))
--          ||' QV: '
--          ||decode (ogim.dettaglio_ogim
--                   , null, ltrim(rtrim(substr(faog.dettaglio_faog,114,17)))
--                   ,ltrim(rtrim(substr(ogim.dettaglio_ogim,114,17))))
          ||';'                                       note2
        , substr(nvl(faog.dettaglio_faog, ogim.dettaglio_ogim),1,131) dettaglio
        --
        -- (VD - 23/11/2016): Aggiunte note x sconto conferimento sacchi
        --
        , rtrim(ltrim(substr(nvl(faog.dettaglio_faog, ogim.dettaglio_ogim),152)))  sconto_conf
     from oggetti_pratica ogpr,
          oggetti_imposta ogim,
          familiari_ogim              faog,
          oggetti_validita            ogva
    where ogim.oggetto_imposta = w_oggetto_imposta
      and ogpr.oggetto_pratica = w_oggetto_pratica
      and faog.oggetto_imposta (+) = ogim.oggetto_imposta
      and ogpr.oggetto_pratica = ogva.oggetto_pratica
    order by decode(faog.numero_familiari
                   , null ,nvl(ogva.dal,to_date('01011900','ddmmyyyy'))
                   , faog.dal)
           , decode(faog.numero_familiari
                   , null ,nvl(ogva.al,to_date('31122999','ddmmyyyy'))
                   , faog.al);
--    order by 1;
CURSOR sel_rate ( w_cod_fiscale varchar2
                , w_ruolo number
                , w_ni number
                , w_importo_tot_arrotondato number
                , w_importo_versato number
                , w_rate number) IS
  select raim.rata,
         to_char(ruol.anno_ruolo)||
         to_char(nvl(raim.rata,0))||
         lpad(to_char(ruol.ruolo),4,'0')||
         lpad(to_char(w_ni),7,'0')||';' v_campo,
--         sum(nvl(raim.imposta,0))
--          + sum(nvl(raim.addizionale_eca,0))
--          + sum(nvl(raim.maggiorazione_eca,0))
--          + sum(nvl(raim.addizionale_pro,0))
--          + sum(nvl(raim.iva,0))
--         decode(w_importo_versato
--               ,0,
               round(w_importo_tot_arrotondato / w_rate,0)
--               ,0)
         importo_rata
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
--
-- (VD - 14/03/2018): Pontedera, cursore per selezionare i conferimenti
--                    da inserire nel file
--
CURSOR sel_conf ( a_cod_fiscale       varchar2
                , a_anno              number
                , a_ruolo             number
                , a_dal               date
                , a_al                date
                ) IS
select 'A',
       coce.data_conferimento data_conf,
       cace.codice_cer,
       to_char(coce.data_conferimento,'dd/mm/yyyy hh24.mi.ss') || '  ' ||
       cace.codice_cer || ': ' || rpad(cace.descrizione_breve,33) || ' ' ||
       lpad(translate(to_char(coce.quantita,'9990.99')
                     ,'.',',')
           ,10) ||
       lpad(translate(to_char(cocr.importo_scalato,'99,990.99')
                     ,',.','.,')
           ,10) ||';' riga_conf
  from CONFERIMENTI_CER       coce,
       CONFERIMENTI_CER_RUOLO cocr,
       CATEGORIE_CER          cace
 where coce.cod_fiscale = a_cod_fiscale
   and coce.cod_fiscale = cocr.cod_fiscale
   and coce.anno = cocr.anno
   and coce.tipo_utenza = cocr.tipo_utenza
   and coce.data_conferimento = cocr.data_conferimento
   and coce.codice_cer = cocr.codice_cer
   and cocr.ruolo = a_ruolo
   and coce.codice_cer = cace.codice_cer
 union
select 'B',
       to_date(null),
       null,
       lpad(' ',19) || '  ' ||
       lpad('-',41,'-') ||
       ' ' ||
       lpad('-',10,'-') ||
       lpad('-',10,'-') ||';' riga_conf
  from dual
 where exists (select 'x' from conferimenti_cer_ruolo cocer
                where cocer.cod_fiscale = a_cod_fiscale
                  and cocer.anno = a_anno
                  and cocer.ruolo = a_ruolo
                  and trunc(cocer.data_conferimento) between a_dal and a_al)
 union
select 'C',
       to_date(null),
       null,
       lpad(' ',19) || '  ' ||
       lpad('TOTALE CONFERITO',41) || ' ' ||
       lpad(translate(to_char(sum(coce.quantita),'9999.99')
                     ,'.',',')
           ,10) ||
       lpad(translate(to_char(sum(cocr.importo_scalato),'99,999.99')
                     ,',.','.,')
           ,10) ||';' riga_conf
  from CONFERIMENTI_CER       coce,
       CONFERIMENTI_CER_RUOLO cocr,
       CATEGORIE_CER          cace
 where coce.cod_fiscale = a_cod_fiscale
   and trunc(coce.data_conferimento) between a_dal and a_al
   and coce.cod_fiscale = cocr.cod_fiscale
   and coce.anno = cocr.anno
   and coce.tipo_utenza = cocr.tipo_utenza
   and coce.data_conferimento = cocr.data_conferimento
   and coce.codice_cer = cocr.codice_cer
   and nvl(cocr.ruolo,a_ruolo) = a_ruolo
   and coce.codice_cer = cace.codice_cer
having sum(coce.quantita) <> 0
 order by 1, 2 nulls last,3 nulls last;
--------------------------------------------------------------------------------
function f_get_stringa_versamenti
  ( a_tipo_tributo              varchar2
  , a_cod_fiscale               varchar2
  , a_ruolo                     number
  , a_anno_ruolo                number
  , a_tipo_emissione            varchar2
  , a_numero_anni               number
  , a_insolvenza_min            number
  , a_stringa_vers_reg          varchar2
  , a_stringa_vers_irr          varchar2
  ) return varchar2
  is
  w_note_utenza               varchar2(4000);
  w_stringa_anni              varchar2(100);
  w_ruolo_acconto             number;
  w_ultimo_ruolo              number;
  w_anno_rif                  number;
  w_importo_anno              number;
  w_imp_dovuto                number;
  w_imp_versato               number;
  w_imp_sgravi                number;
  w_ind                       number;
  type t_importo_anno_t       is table of number index by binary_integer;
  t_importo_anno              t_importo_anno_t;
  begin
    w_note_utenza      := null;
    -- Se il numero di anni per cui controllare i versamenti è 0, la funzione
    -- restituisce una stringa nulla
    if a_numero_anni = 0 then
       return w_note_utenza;
    end if;
    -- Se il ruolo che si sta trattando è a saldo, si verificano anche i
    -- versamenti relativi al ruolo in acconto. Se il ruolo è in acconto o
    -- totale, si verificano solo i versamenti per gli anni precedenti
    w_importo_anno := to_number(null);
    if a_tipo_emissione = 'S' then
       begin
         select ruolo
           into w_ruolo_acconto
           from ruoli
          where anno_ruolo = a_anno_ruolo
            --and progr_emissione = 1
            and tipo_emissione = 'A'
            and invio_consorzio is not null;
       exception
         when others then
           w_ruolo_acconto := to_number(null);
       end;
       if w_ruolo_acconto is not null then
          w_importo_anno := nvl(f_importi_ruoli_tarsu(a_cod_fiscale,a_anno_ruolo,w_ruolo_acconto,to_number(null),'IMPOSTA'),0) -
                            nvl(f_importo_vers(a_cod_fiscale,'TARSU',a_anno_ruolo,to_number(null)),0) -
                            nvl(f_importo_vers_ravv(a_cod_fiscale,'TARSU',a_anno_ruolo,to_number(null)),0) -
                            nvl(f_dovuto(0,a_anno_ruolo,'TARSU',0,-1,'S',null,a_cod_fiscale),0);
          if w_importo_anno <= a_insolvenza_min then
             w_importo_anno := to_number(null);
          end if;
       end if;
    end if;
    -- Si esegue un loop sugli anni precedenti per determinare
    -- l'eventuale dovuto residuo
    t_importo_anno.delete;
    w_ind := 0;
    for w_ind in 1 .. a_numero_anni
    loop
      -- Si determina l'anno di riferimento e l'ultimo ruolo totale emesso per quell'anno
      w_anno_rif := a_anno_ruolo - w_ind;
      begin
        w_ultimo_ruolo := f_ruolo_totale(a_cod_fiscale
                                        ,w_anno_rif
                                        ,a_tipo_tributo
                                        ,-1
                                        );
      exception
        when others then
          w_ultimo_ruolo := to_number(null);
      end;
      begin
        select nvl(sum(nvl(ogim.imposta,0) + nvl(ogim.maggiorazione_eca,0) +
               nvl(ogim.addizionale_eca,0) + nvl(ogim.addizionale_pro,0) +
               nvl(ogim.iva,0) + nvl(ogim.maggiorazione_tares,0)),0) imp_dovuto
          into w_imp_dovuto
          from oggetti_imposta ogim
              ,oggetti_pratica ogpr
              ,pratiche_tributo prtr
              ,ruoli ruol
         where ogim.cod_fiscale = a_cod_fiscale
           and ogim.oggetto_pratica = ogpr.oggetto_pratica
           and ogpr.pratica = prtr.pratica
           and (prtr.tipo_pratica = 'D'
             or (prtr.tipo_pratica = 'A'
             and ogim.anno > prtr.anno))
           and prtr.tipo_tributo||'' = 'TARSU'
           and nvl (ogim.ruolo, -1) =
                 nvl (nvl (w_ultimo_ruolo
                          ,ogim.ruolo
                          )
                     ,-1
                     )
            and ruol.ruolo = ogim.ruolo
            and ruol.invio_consorzio is not null
            and ogim.anno = w_anno_rif
          group by ogim.anno
                 , prtr.tipo_tributo
                 ;
      exception
        when others then
          w_imp_dovuto := 0;
      end;
      begin
        select f_importo_vers (a_cod_fiscale, a_tipo_tributo, a_anno_ruolo - w_ind, null)
             + f_importo_vers_ravv (a_cod_fiscale, a_tipo_tributo, a_anno_ruolo - w_ind, 'U') imp_versato
             , nvl(f_dovuto(0,a_anno_ruolo - w_ind,a_tipo_tributo,0,-1,'S',null,a_cod_fiscale),0) imp_sgravi
          into w_imp_versato
             , w_imp_sgravi
          from dual;
      exception
        when others then
          w_imp_versato := 0;
          w_imp_sgravi := 0;
      end;
      t_importo_anno(w_ind) := w_imp_dovuto - w_imp_versato - w_imp_sgravi;
      if t_importo_anno(w_ind) <= a_insolvenza_min then
         t_importo_anno(w_ind) := to_number(null);
      end if;
    end loop;
    -- Alla fine del trattamento si verifica se occorre compilare anche la
    -- nota utenza
    w_stringa_anni := '';
    if w_importo_anno is not null then
       w_stringa_anni := 'l''anno '||a_anno_ruolo;
    end if;
    for w_ind in reverse 1 .. a_numero_anni
    loop
       if t_importo_anno (w_ind) is not null then
          if w_stringa_anni is null then
             w_stringa_anni := 'l''anno '||to_char(a_anno_ruolo - w_ind);
          else
             w_stringa_anni := replace(w_stringa_anni,'l''anno','gli anni');
             w_stringa_anni := w_stringa_anni||', '||to_char(a_anno_ruolo - w_ind);
          end if;
       end if;
    end loop;
    if w_stringa_anni is not null then
       w_note_utenza := replace(a_stringa_vers_irr,'XXXX',w_stringa_anni);
    else
       w_note_utenza := a_stringa_vers_reg;
    end if;
    return w_note_utenza;
  end f_get_stringa_versamenti;
--------------------------------------------------------------------------------
-- INIZIO ELABORAZIONE
--------------------------------------------------------------------------------
BEGIN
   --
   -- (VD - 18/01/2016): Il limite importo ruolo deve essere >= 0
   --
   if nvl(p_importo_limite,0) < 0 then
      w_errore := 'L''importo limite indicato non puo'' essere negativo';
      raise ERRORE;
   end if;
   --
   -- (VD - 11/04/2018): il parametro addebito_cc puo' valere solo
   --                    S - Solo i contribuenti con addebito c/c
   --                    N - Solo i contribuenti senza addebito c/c
   --                    T - Tutti i contribuenti
   --
   if p_addebito_cc not in ('S','N','T') then
      w_errore := 'Indicare il tipo addebito c/c: '||chr(10)||
                  'S - Solo contribuenti con addebito in c/c'||chr(10)||
                  'N - Solo contribuenti senza addebito in c/c'||chr(10)||
                  'T - Tutti i contribuenti';
      raise errore;
   end if;
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
           , comu.sigla_cfis
        into w_cod_istat
           , w_comune
           , w_cod_catast_comune
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
   --
   --   (VD - 29/06/2016): il parametro della selezione degli importi
   --                      positivi e' diventato un parametro della
   --                      procedure e non viene piu' selezionato dai
   --                      parametri del modello 'COM_TARSU%'
   --
   if p_se_vers_positivi = 'S' then
      w_se_vers_positivi := '+';
   else
      w_se_vers_positivi := '';
   end if;
   --
   BEGIN
     select tipo_emissione
          , rate
          , anno_ruolo
          , cognome_resp
            ||decode(nome_resp
                    ,null,''
                    ,' '||nome_resp
                    )
          , progr_emissione
          , flag_tariffe_ruolo
       into w_tipo_emissione
          , w_max_rate
          , w_anno_ruolo
          , w_responsabile_ruolo
          , w_progr_ruolo
          , w_flag_tariffe_ruolo
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
   --
   -- (VD - 05/07/2016): Il limite importo puo' essere indicato solo per
   --                    ruoli a saldo
   --
   if p_importo_limite is not null and
      nvl(w_tipo_emissione,'T') <> 'S' then
      w_errore := 'Indicazione Limite Importo da inserire solo per ruoli a Saldo';
      raise ERRORE;
   end if;
   --
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
   --
   -- (VD - 14/03/2018): Pontedera, si determina il periodo per cui
   --                    conteggiare i conferimenti relativamente al
   --                    ruolo che si sta trattando
   --                    Successivamenti, si determina il numero massimo
   --                    di righe da inserire per i conferimenti stessi
   --
   cer_conferimenti.calcolo_periodo_conf(p_ruolo,w_dal_conf,w_al_conf);
   ------------------------------------
   --- Inizio -------------------------
   ------------------------------------
   w_errore := ' Inizio ';
   w_descr_titr := f_descrizione_titr('TARSU',w_anno_ruolo);
   w_spese_postali := nvl(p_spese_postali,0);
   w_importo_limite := nvl(p_importo_limite,0);
   w_max_progr_ubicazione := 0;
   w_progr_wrk := 1;
   FOR rec_co  IN sel_co (w_spese_postali,w_se_vers_positivi,w_importo_limite,p_addebito_cc) --Contribuenti
   LOOP
     -- dbms_output.put_line(rec_co.cod_fiscale || ' ' || rec_co.cognome_nome || ' ' || rec_co.ni);
     -- dbms_output.put_line(rec_co.cod_fiscale );
      w_importo_rata_0 := 0;
      w_importo_rata_1 := 0;
      w_importo_rata_2 := 0;
      w_importo_rata_3 := 0;
      w_importo_rata_4 := 0;
      -- Prima Parte
      w_riga_wrk := rec_co.prima_parte;
      w_errore := to_char(length(w_riga_wrk))||'  1 '||rec_co.cod_fiscale;
      w_riga_rata := '';
      w_riga_rata_a := '';
      w_riga_causale := '';
      w_riga_rata_rateaz := null;
      -- calcolo valori colonne per Portoferraio
      w_tot_complessivo   := w_spese_postali + rec_co.importo_netto
                           + rec_co.addizionale_pro + rec_co.maggiorazione_tares;
      w_tot_complessivo_a := round(w_spese_postali,0) + round(rec_co.importo_netto,0)
                           + round(rec_co.addizionale_pro,0) + round(rec_co.maggiorazione_tares,0);
      w_tares_add_prov_a  := round(rec_co.importo_netto,0) + round(rec_co.addizionale_pro,0);
      w_tares_add_prov_not := rec_co.da_pagare + w_spese_postali;
      w_tares_add_prov_not_a := round(rec_co.importo_netto,0) + round(rec_co.addizionale_pro,0)
                                + round(w_spese_postali,0);
      if rec_co.rate > 0 then
         w_spese_postali_rata := round(w_spese_postali/rec_co.rate,2);
      else
         w_spese_postali_rata := w_spese_postali;
      end if;
      --
      BEGIN
        select nvl(count(distinct(oggetto)),0)   -- AB 16/07/2015
          into w_numero_ubicazioni
          from oggetti_pratica ogpr
             , oggetti_imposta ogim
             , ruoli_contribuente ruco
         where ruco.ruolo = p_ruolo
           and ruco.cod_fiscale = rec_co.cod_fiscale
           and ogpr.oggetto_pratica = ogim.oggetto_pratica
           and ogim.oggetto_imposta = ruco.oggetto_imposta
/*
        select nvl(count(1),0) numero_ubicazioni
          into w_numero_ubicazioni
          from ruoli_contribuente ruco
         where ruolo = p_ruolo
           and cod_fiscale = rec_co.cod_fiscale
*/        ;
      END;
      --Determinazione degli Importi Rateizzati a livello di Contribuente
      -- (VD - 30/03/2021): Si differenzia il trattamento a seconda che il
      --                    ruolo sia stato emesso prima del 2021 o dal 2021
      --                    in poi
      if w_anno_ruolo < 2021 then
         w_versato := nvl(rec_co.versato_netto_tot,0);
         w_tot_rate := 0;
         w_importo_tot_x_rate := greatest(0,rec_co.importo_tot_arrotondato);
   --      w_importo_tot_x_rate := rec_co.importo_tot_arrotondato;
         w_importo_add_prov_x_rate := w_tares_add_prov_not;
         FOR rec_rate IN sel_rate (rec_co.cod_fiscale, rec_co.ruolo, rec_co.ni, rec_co.importo_lordo_x_rate, rec_co.versato_tot, rec_co.rate) LOOP --Rate
            w_riga_causale := w_riga_causale || 'RUOLO '||w_descr_titr
                              ||' - ANNO '||to_char(w_anno_ruolo)||' - RATA '||to_char(rec_rate.rata)||';';
            -- determino l'importo della rata al netto del versato
   --         if rec_rate.importo_rata > w_versato
   --         then w_importo_rata := round(w_versato,0);
   --         else
            w_importo_rata := greatest(0,round(rec_rate.importo_rata - w_versato,0));
   --         end if;
            w_versato := greatest(0,w_versato - rec_rate.importo_rata);
            if rec_rate.rata = 1 then
               -- w_importo_prima_rata lo utilizzo come valore per tutte le rate tranne l'ultima
   --            w_importo_prima_rata := rec_rate.importo_rata;
               IF rec_co.rate = rec_rate.rata THEN
               -- se ultima rata l'importo della rata è determinato per differenza
               -- come importo del ruolo - il già versato - le rate precedenti
                  w_importo_rata_1 := greatest(0,round(w_importo_tot_x_rate
                                                       - w_tot_rate,0));
               else
                  w_importo_rata_1 := w_importo_rata;
               end if;
               --Inserimento dei dati sulla rata 1
               w_vcampo1 := to_char(w_anno_ruolo) || '1' || lpad(p_ruolo,4,'0') || lpad(rec_co.ni,7,'0')||';';
               w_riga_rata := w_riga_rata || ';' || w_vcampo1  || ltrim(translate(to_char(w_importo_rata_1,'999999990.00'),'.',','))
                              || ';' || w_scadenza_rata_1 ;
               w_riga_rata_a :=  w_riga_rata_a || ';' ||ltrim(translate(to_char(w_importo_rata_1,'999999990.00'),'.',','));
               if w_cod_istat = '049014' then  -- Portoferraio
                   w_riga_rata_rateaz := w_riga_rata_rateaz||';01'||lpad(nvl(rec_co.rate,0),2,'0') ;
               else
                   w_riga_rata_rateaz := w_riga_rata_rateaz
                                         ||';'||lpad(1+nvl(rec_co.rate_iniz_prec,0),2,'0')
                                         ||lpad(nvl(rec_co.rate,0)+nvl(rec_co.rate_prec,0),2,'0') ;
               end if;
            end if;
            if rec_rate.rata = 2 then
               IF rec_co.rate = rec_rate.rata THEN
               -- se ultima rata l'importo della rata è determinato per differenza
               -- come importo del ruolo - il già versato - le rate precedenti
                  w_importo_rata_2 := greatest(0,round(w_importo_tot_x_rate
                                                       - w_tot_rate,0));
               else
                  w_importo_rata_2 := w_importo_rata;
               end if;
               --Inserimento dei dati sulla rata 2
               w_vcampo2 := to_char(w_anno_ruolo) || '2' || lpad(p_ruolo,4,'0') || lpad(rec_co.ni,7,'0')||';';
               w_riga_rata := w_riga_rata || ';' || w_vcampo2 || ltrim(translate(to_char(w_importo_rata_2,'999999990.00'),'.',','))
                              || ';' || w_scadenza_rata_2 ;
               w_riga_rata_a :=  w_riga_rata_a || ';' ||ltrim(translate(to_char(w_importo_rata_2,'999999990.00'),'.',','));
               if w_cod_istat = '049014' then  -- Portoferraio
                   w_riga_rata_rateaz := w_riga_rata_rateaz||';02'||lpad(nvl(rec_co.rate,0),2,'0') ;
               else
                   w_riga_rata_rateaz := w_riga_rata_rateaz
                                         ||';'||lpad(2+nvl(rec_co.rate_iniz_prec,0),2,'0')
                                         ||lpad(nvl(rec_co.rate,0)+nvl(rec_co.rate_prec,0),2,'0') ;
               end if;
            end if;
            if rec_rate.rata = 3 then
               IF rec_co.rate = rec_rate.rata THEN
               -- se ultima rata l'importo della rata è determinato per differenza
               -- come importo del ruolo - il già versato - le rate precedenti
                  w_importo_rata_3 := greatest(0,round(w_importo_tot_x_rate
                                                       - w_tot_rate,0));
               else
                  w_importo_rata_3 := w_importo_rata;
               end if;
               --Inserimento dei dati sulla rata 3
               w_vcampo3 := to_char(w_anno_ruolo) || '3' || lpad(p_ruolo,4,'0') || lpad(rec_co.ni,7,'0')||';';
               w_riga_rata := w_riga_rata || ';' || w_vcampo3 || ltrim(translate(to_char(w_importo_rata_3,'999999990.00'),'.',','))
                              || ';' || w_scadenza_rata_3 ;
               w_riga_rata_a :=  w_riga_rata_a || ';' ||ltrim(translate(to_char(w_importo_rata_3,'999999990.00'),'.',','));
               if w_cod_istat = '049014' then  -- Portoferraio
                   w_riga_rata_rateaz := w_riga_rata_rateaz||';03'||lpad(nvl(rec_co.rate,0),2,'0') ;
               else
                   w_riga_rata_rateaz := w_riga_rata_rateaz
                                         ||';'||lpad(3+nvl(rec_co.rate_iniz_prec,0),2,'0')
                                         ||lpad(nvl(rec_co.rate,0)+nvl(rec_co.rate_prec,0),2,'0') ;
               end if;
            end if;
            if rec_rate.rata = 4 then
               IF rec_co.rate = rec_rate.rata THEN
               -- se ultima rata l'importo della rata è determinato per differenza
               -- come importo del ruolo - il già versato - le rate precedenti
                  w_importo_rata_4 := greatest(0,round(w_importo_tot_x_rate
                                                       - w_tot_rate,0));
               else
                  w_importo_rata_4 := w_importo_rata;
               end if;
               --Inserimento dei dati sulla rata 4
               w_vcampo4 := to_char(w_anno_ruolo) || '4' || lpad(p_ruolo,4,'0') || lpad(rec_co.ni,7,'0')||';';
               w_riga_rata := w_riga_rata || ';' || w_vcampo4 || ltrim(translate(to_char(w_importo_rata_4,'999999990.00'),'.',','))
                              || ';' || w_scadenza_rata_4 ;
               w_riga_rata_a :=  w_riga_rata_a || ';' ||ltrim(translate(to_char(w_importo_rata_4,'999999990.00'),'.',','));
               if w_cod_istat = '049014' then  -- Portoferraio
                   w_riga_rata_rateaz := w_riga_rata_rateaz||';04'||lpad(nvl(rec_co.rate,0),2,'0') ;
               else
                   w_riga_rata_rateaz := w_riga_rata_rateaz
                                         ||';'||lpad(4+nvl(rec_co.rate_iniz_prec,0),2,'0')
                                         ||lpad(nvl(rec_co.rate,0)+nvl(rec_co.rate_prec,0),2,'0') ;
                 end if;
            end if;
            w_tot_rate := w_tot_rate + w_importo_rata;
         END LOOP; --rec_raim
      else
         -- Trattamento rate per ruoli emessi dal 2021 in avanti
         for w_rata in 1..rec_co.rate
         loop
           w_riga_causale := w_riga_causale || 'RUOLO '||w_descr_titr
                          ||' - ANNO '||to_char(w_anno_ruolo)||' - RATA '||to_char(w_rata)||';';
           w_rata_tari := f_calcolo_rata_tarsu(rec_co.cod_fiscale
                                              ,p_ruolo,rec_co.rate
                                              ,w_rata,'I','');
           w_rata_tefa := f_calcolo_rata_tarsu(rec_co.cod_fiscale
                                              ,p_ruolo,rec_co.rate
                                              ,w_rata,'P','');
           w_importo_rata := w_rata_tari + w_rata_tefa;
           w_vcampo1 := to_char(w_anno_ruolo) || w_rata || lpad(p_ruolo,4,'0') || lpad(rec_co.ni,7,'0')||';';
           w_riga_rata := w_riga_rata || ';' || w_vcampo1  ||
                          ltrim(translate(to_char(w_rata_tari,'999999990.00'),'.',',')) || ';' ||
                          ltrim(translate(to_char(w_rata_tefa,'999999990.00'),'.',',')) || ';' ||
                          ltrim(translate(to_char(w_importo_rata,'999999990.00'),'.',',')) || ';';
           case w_rata
                when 1 then w_riga_rata := w_riga_rata || w_scadenza_rata_1;
                when 2 then w_riga_rata := w_riga_rata || w_scadenza_rata_2;
                when 3 then w_riga_rata := w_riga_rata || w_scadenza_rata_3;
                when 4 then w_riga_rata := w_riga_rata || w_scadenza_rata_4;
           end case;
           w_riga_rata_a :=  w_riga_rata_a || ';' ||ltrim(translate(to_char(w_importo_rata,'999999990.00'),'.',','));
           w_riga_rata_rateaz := w_riga_rata_rateaz
                                 ||';'||lpad(w_rata + nvl(rec_co.rate_iniz_prec,0),2,'0')
                                 ||lpad(nvl(rec_co.rate,0)+nvl(rec_co.rate_prec,0),2,'0') ;
         end loop;
      end if;
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
      --w_riga_varXX := null;
      riga_file.delete;
      w_ind := 0;
      FOR rec_ubi IN sel_ubi (rec_co.cod_fiscale)
      LOOP --OGIM
         if rec_ubi.flag_domestica is null then
            w_coeff_fissa := 'Kc.';
            w_coeff_var := 'Kd.';
            w_str_mq_fissa := 'Mq'||to_char(round(rec_ubi.mq),'B99999');
            w_str_mq_var := 'Mq'||to_char(round(rec_ubi.mq),'B99999');
         else
            w_coeff_fissa := 'Ka.';
            w_coeff_var := 'Kb.';
            w_str_mq_fissa := 'Mq'||to_char(round(rec_ubi.mq),'B99999');
            w_str_mq_var := '        ';
         end if;
         --
         w_utenze_contribuente := w_utenze_contribuente + 1;
         --w_riga_varXX := w_riga_varXX|| rec_ubi.note1;
         w_ind := w_ind + 1;
         riga_file(w_ind) := rec_ubi.note1;
         --
         w_utenze_contribuente := w_utenze_contribuente + 1;
         --w_riga_varXX := w_riga_varXX|| rec_ubi.note2;
         w_ind := w_ind + 1;
         riga_file(w_ind) := rec_ubi.note2;
         --
         -- (VD - 25/03/2019): questo loop e' sostituito dalla suddivisione
         --                    della stringa risultante dalla F_GET_FAMILIARI_OGIM
         --
/*       FOR rec_fam IN sel_fam (rec_ubi.oggetto_imposta,rec_ubi.oggetto_pratica)
         LOOP
            w_str_dett_fam := replace(replace(replace('('||w_coeff_fissa || substr(rec_fam.dettaglio
                                                                                   , 9
                                                                                   )
                                                      ,'Imposta QF'
                                                      ,w_str_mq_fissa || ') QF:'
                                                      )
                                              ,'Coeff.'
                                              ,' - ('||w_coeff_var
                                              )
                                      ,'Imposta QV'
                                      ,w_str_mq_var || ') QV:'
                                      )||';'
                               ;
            w_lunghezza_prec := length(w_str_dett_fam);
            w_lunghezza_new := 0;
            while w_lunghezza_prec != w_lunghezza_new loop
                  w_lunghezza_prec := w_lunghezza_new;
                  w_str_dett_fam := replace(w_str_dett_fam,'  ',' ');
                  w_lunghezza_new := length(w_str_dett_fam);
            end loop;
            if rec_fam.note2 != ';' then
               w_utenze_contribuente := w_utenze_contribuente + 1;
               --w_riga_varXX := w_riga_varXX|| rec_fam.note2;
               w_ind := w_ind + 1;
               riga_file(w_ind) := rec_fam.note2;
            end if;
            if rec_fam.dettaglio is not null then
               w_utenze_contribuente := w_utenze_contribuente + 1;
               --w_riga_varXX := w_riga_varXX|| w_str_dett_fam;
               w_ind := w_ind + 1;
               riga_file(w_ind) := rec_fam.dettaglio||';';
            end if;
           --
           -- (VD - 23/11/2016): Aggiunte note x sconto conferimento sacchi
           --
            if rec_fam.sconto_conf is not null then
               --
               -- (VD - 14/03/2018): distinzione conferimenti.
               --                    Se la stringa contiene "QV", si tratta
               --                    di conferimento CER (Pontedera), quindi
               --                    si stampa la stringa così com'è.
               --                    In caso contrario, si tratta di conferimenti
               --                    con sconto percentuale (S.Donato Milanese)
               --                    quindi la stringa viene "assestata" in maniera
               --                    differente.
               --
               if rec_fam.sconto_conf like '' then
                  w_str_conferimenti := substr(rec_fam.sconto_conf,1,30)||
                                        lpad('-'||substr(rec_fam.sconto_conf,instr(rec_fam.sconto_conf,' ',-1) + 1),15)||';';
               else
                  w_str_conferimenti := replace(replace('('||rec_fam.sconto_conf,' Perc.','  Perc.'),' Sconto:',') Sconto:');
                  w_str_conferimenti := substr(w_str_conferimenti,1,instr(w_str_conferimenti,' ',-1)-1)||'-'||
                                        substr(w_str_conferimenti,instr(w_str_conferimenti,' ',-1) + 1)||';';
               end if;
               if w_str_conferimenti is not null then
                  w_utenze_contribuente := w_utenze_contribuente + 1;
                  --w_riga_varXX := w_riga_varXX|| w_str_conferimenti;
                  w_ind := w_ind + 1;
                  riga_file(w_ind) := w_str_conferimenti;
               end if;
            end if;
         END LOOP; */
         w_stringa_dettaglio := replace(rec_ubi.stringa_dettaglio,'[a_capo',';');
         w_stringa_dettaglio := ltrim(w_stringa_dettaglio,';')||';';
         w_utenze_contribuente := w_utenze_contribuente +
                                  length(w_stringa_dettaglio) -
                                  length(replace(w_stringa_dettaglio,';',''));
         w_ind := w_ind + 1;
         riga_file(w_ind) := w_stringa_dettaglio;
         --
         -- (VD - 09/05/2018): S.Donato Milanese/UnipolSai
         --                    in questo caso non si stampano i dettagli
         --                    degli importi
         if w_cod_istat||rec_co.cod_fiscale <> '015192'||w_cod_unipol then
            if rec_ubi.st_imposta_netta_annua is not null then
               w_utenze_contribuente := w_utenze_contribuente + 1;
               w_ind := w_ind + 1;
               riga_file(w_ind) := rec_ubi.st_imposta_netta_annua;
            end if;
            if rec_ubi.st_imposta_netta_acconto is not null then
               w_utenze_contribuente := w_utenze_contribuente + 1;
               w_ind := w_ind + 1;
               riga_file(w_ind) := rec_ubi.st_imposta_netta_acconto;
            end if;
            --
            -- Stampa imposta netta
            -- (VD - 10/06/2019): per Bovezzo non si stampano gli importi
            --                    del dettaglio utenza
            --
            if w_cod_istat <> '017025' then
               w_utenze_contribuente := w_utenze_contribuente + 1;
               --w_riga_varXX := w_riga_varXX|| rec_ubi.st_imposta_netta;
               w_ind := w_ind + 1;
               riga_file(w_ind) := rec_ubi.st_imposta_netta;
               --
               -- Stampa addizionale provinciale
               --
               w_utenze_contribuente := w_utenze_contribuente + 1;
               --w_riga_varXX := w_riga_varXX|| rec_ubi.st_add_pro;
               w_ind := w_ind + 1;
               riga_file(w_ind) := rec_ubi.st_add_pro;
               --
               -- Stampa imposta lorda
               --
               w_utenze_contribuente := w_utenze_contribuente + 1;
               --w_riga_varXX := w_riga_varXX|| rec_ubi.st_imposta_lorda;
               w_ind := w_ind + 1;
               riga_file(w_ind) := rec_ubi.st_imposta_lorda;
               --
               -- Stampa residuo lordo
               --
               w_utenze_contribuente := w_utenze_contribuente + 1;
               --w_riga_varXX := w_riga_varXX|| rec_ubi.st_residuo_lordo;
               w_ind := w_ind + 1;
               riga_file(w_ind) := rec_ubi.st_residuo_lordo;
            end if;
         end if;
         --
         -- (VD - 13/05/2015): aggiunta riga di separazione tra un'utenza e l'altra
         --
         w_utenze_contribuente := w_utenze_contribuente + 1;
         --
         -- (VD - 12/04/2017): se si tratta di S.Donato Milanese
         --                    e UnipolSAI la riga di separazione
         --                    e' di 5 caratteri anziche 50
         --
         --if w_cod_istat||rec_co.cod_fiscale = '015192'||w_cod_unipol then
         --   w_riga_varXX := w_riga_varXX || rpad('_',5,'_') || ';';
         --else
         --   w_riga_varXX := w_riga_varXX || rpad('_',50,'_') || ';';
         --end if;
          w_ind := w_ind + 1;
          riga_file(w_ind) := rpad('_',50,'_') || ';';
      END LOOP; --sel_ubi
      --
      -- (VD - 14/03/2018): Pontedera, stampa riepilogo conferimenti
      -- (VD - 26/09/2018): Fiorano Modenese, eliminata esposizione conferimenti
      --
      if w_cod_istat <> '036013' then
         w_conta_conf := 0;
         for rec_conf in sel_conf (rec_co.cod_fiscale,w_anno_ruolo,p_ruolo,
                                   w_dal_conf,w_al_conf)
         loop
           -- Intestazione conferimenti
           if w_conta_conf = 0 then
              w_utenze_contribuente := w_utenze_contribuente + 1;
              w_riga_varXX := w_riga_varXX || 'RIEPILOGO CONFERIMENTI - PERIODO DAL '||
                              to_char(w_dal_conf,'dd/mm/yyyy')||' AL '||to_char(w_al_conf,'dd/mm/yyyy')|| ';';
              w_utenze_contribuente := w_utenze_contribuente + 1;
              w_riga_varXX := w_riga_varXX || 'DATA CONFERIMENTO    CATEGORIA CER                                     KG IMP.SCAL.;';
           end if;
           --
           w_conta_conf := w_conta_conf + 1;
           w_utenze_contribuente := w_utenze_contribuente + 1;
           w_riga_varXX := w_riga_varXX || rec_conf.riga_conf;
         end loop;
      end if;
      --
      -- Si memorizza il numero di VAR inserite
      --
      if w_utenze_contribuente > w_max_progr_ubicazione then
         w_max_progr_ubicazione := w_utenze_contribuente;
      end if;
      w_riga_wrk := w_riga_wrk||rec_co.seconda_parte;
      -- Inserimento di maggiorazione_tares
      if nvl(w_tot_maggiorazione_tares,0) != 0 then  -- AB 09/08/2013 inserito questo controllo perche altrimenti viene il campo, ma non intestazione
         if nvl(rec_co.maggiorazione_tares,0) = 0 then
            w_riga_wrk := w_riga_wrk||';';
         else
            w_riga_wrk := w_riga_wrk||replace(to_char(rec_co.maggiorazione_tares,'FM999990.00'),'.',',')||';';
         end if;
      end if;
      w_riga_wrk := w_riga_wrk||'AVVISO DI PAGAMENTO '
                    ||f_descrizione_titr('TARSU',w_anno_ruolo)||';';
      w_riga_wrk := w_riga_wrk||'COMUNE DI '||w_comune||' - UFFICIO TRIBUTI;';
      if w_responsabile_ruolo is not null then
         w_riga_wrk := w_riga_wrk||'RESPONSABILE DEL PROCEDIMENTO: '||w_responsabile_ruolo||';';
      end if;
      --Importo e scadenza rata 0
      w_importo_rata_0 := rec_co.importo_tot_arrotondato;
      --Inserimento dei dati sull'imposta totale (o rata 0)
      w_vcampot := to_char(w_anno_ruolo) || '0' || lpad(p_ruolo,4,'0') || lpad(rec_co.ni,7,'0')||';';
      -- (VD - 30/03/2021): differenziato trattamento ruoli emessi dal 2021
      --                    in avanti
      if w_anno_ruolo < 2021 then
         w_riga_wrk := w_riga_wrk || w_vcampot || ltrim(translate(to_char(w_importo_rata_0,'999999990.00'),'.',','))
                       || ';' || w_scadenza_rata_0;
      else
         w_rata_tari := f_calcolo_rata_tarsu(rec_co.cod_fiscale
                                            ,p_ruolo,rec_co.rate
                                            ,0,'I','');
         w_rata_tefa := f_calcolo_rata_tarsu(rec_co.cod_fiscale
                                            ,p_ruolo,rec_co.rate
                                            ,0,'P','');
         w_importo_rata := w_rata_tari + w_rata_tefa;
         w_riga_wrk := w_riga_wrk || w_vcampot
                    || ltrim(translate(to_char(w_rata_tari,'999999990.00'),'.',','))||';'
                    || ltrim(translate(to_char(w_rata_tefa,'999999990.00'),'.',','))||';'
                    || ltrim(translate(to_char(w_importo_rata,'999999990.00'),'.',','))||';'
                    || w_scadenza_rata_0;
      end if;
      r := 0;
      if w_riga_rata is null then
         WHILE r < w_max_rate
         loop
            w_riga_rata := w_riga_rata||';;;';
            r := r + 1;
         end loop;
      end if;
      w_riga_wrk := w_riga_wrk || w_riga_rata;
      --
      -- (VD -  27/09/2018): aggiunta selezione sgravi sul ruolo
      --
      begin
        select decode(nvl(sum(sgra.importo),0)
                     ,f_sgravio_anno_escl(p_ruolo,rec_co.cod_fiscale,'L'),to_number(null)
                     ,-1 * sum( nvl(sgra.importo, 0)
                              - nvl(sgra.addizionale_pro,0)
                              - nvl(sgra.maggiorazione_tares, 0))
                     ) sgravio_imposta
              ,decode(nvl(sum(sgra.addizionale_pro),0)
                     ,f_sgravio_anno_escl(p_ruolo,rec_co.cod_fiscale,'P'),to_number(null)
                     ,-1 * sum(nvl(sgra.addizionale_pro,0))
                     ) sgravio_add_pro
          into w_sgravio_imposta
             , w_sgravio_add_pro
          from sgravi sgra
              ,ruoli ruol
         where sgra.motivo_sgravio != 99
           and sgra.cod_fiscale = rec_co.cod_fiscale
           and sgra.ruolo = p_ruolo
           and sgra.ruolo = ruol.ruolo
           and nvl(substr(sgra.note,1,1),' ') <> '*'
         group by sgra.cod_fiscale,ruol.anno_ruolo
        having nvl(sum(sgra.importo), 0) != 0;
      exception
        when others then
          w_sgravio_imposta := to_number(null);
          w_sgravio_add_pro := to_number(null);
      end;
      -- Personalizzazione Bovezzo: si estraggono i dati relativi agli ultimi
      -- 5 anni precedenti l'anno del ruolo
      if(w_cod_istat = '017025' or
        (w_cod_istat = '029033' and nvl(p_numero_anni,0) > 0) or
        (w_tipo_emissione <> 'A' and nvl(p_numero_anni,0) > 0)) then
         -- Se si tratta del primo ruolo dell'anno (progr. 1) l'anno del ruolo
         -- non viene considerato
         if w_cod_istat = '017025' then
            w_numero_anni := 5;
            if w_progr_ruolo = 1 then
               w_importo_anno := to_number(null);
            else
               w_errore := 'Bovezzo 1 '||rec_co.cod_fiscale;
               -- Si determina il ruolo in acconto dell'anno che si sta trattando
               begin
                 select ruolo
                   into w_ruolo_acconto
                   from ruoli
                  where anno_ruolo = w_anno_ruolo
                    and progr_emissione = 1
                    and tipo_emissione = 'A'
                    and invio_consorzio is not null;
               exception
                 when others then
                   w_ruolo_acconto := to_number(null);
               end;
            end if;
         else
            w_numero_anni := nvl(p_numero_anni,0);
            w_ruolo_acconto := to_number(null);
            if w_tipo_emissione = 'S' then
               begin
                 select ruolo
                   into w_ruolo_acconto
                   from ruoli
                  where anno_ruolo = w_anno_ruolo
                    --and progr_emissione = 1
                    and tipo_emissione = 'A'
                    and invio_consorzio is not null;
               exception
                 when others then
                   w_ruolo_acconto := to_number(null);
               end;
            end if;
         end if;
         --
         if w_ruolo_acconto is not null then
            w_errore := 'Bovezzo/Vers.anni prec. 7'||rec_co.cod_fiscale;
            w_importo_anno := nvl(f_importi_ruoli_tarsu(rec_co.cod_fiscale,w_anno_ruolo,w_ruolo_acconto,to_number(null),'IMPOSTA'),0) -
                              nvl(f_importo_vers(rec_co.cod_fiscale,'TARSU',w_anno_ruolo,to_number(null)),0) -
                              nvl(f_importo_vers_ravv(rec_co.cod_fiscale,'TARSU',w_anno_ruolo,to_number(null)),0) -
                              nvl(f_dovuto(0,w_anno_ruolo,'TARSU',0,-1,'S',null,rec_co.cod_fiscale),0);
            w_errore := 'Bovezzo/Vers.anni prec. importo '||rec_co.cod_fiscale;
            if w_importo_anno <= p_insolvenza_min then
               w_importo_anno := to_number(null);
            end if;
         else
            w_importo_anno := to_number(null);
         end if;
         -- Si esegue un loop sui 5 anni precedenti per determinare
         -- l'eventuale dovuto residuo
         t_importo_anno.delete;
         w_ind := 0;
         for w_ind in 1 .. w_numero_anni
         loop
           begin
             select nvl(sum(nvl(ogim.imposta,0) + nvl(ogim.maggiorazione_eca,0) +
                    nvl(ogim.addizionale_eca,0) + nvl(ogim.addizionale_pro,0) +
                    nvl(ogim.iva,0) + nvl(ogim.maggiorazione_tares,0)),0) imp_dovuto
                  , f_importo_vers (rec_co.cod_fiscale, prtr.tipo_tributo, ogim.anno, null)
                  + f_importo_vers_ravv (rec_co.cod_fiscale, prtr.tipo_tributo, ogim.anno, 'U') imp_versato
                  , nvl(f_dovuto(0,ogim.anno,prtr.tipo_tributo,0,-1,'S',null,rec_co.cod_fiscale),0) imp_sgravi
               into w_imp_dovuto
                  , w_imp_versato
                  , w_imp_sgravi
               from codici_tributo cotr
                   ,oggetti_imposta ogim
                   ,oggetti_pratica ogpr
                   ,pratiche_tributo prtr
                   ,ruoli ruol
              where cotr.tributo = ogpr.tributo
                and ogim.cod_fiscale = rec_co.cod_fiscale
                and ogim.oggetto_pratica = ogpr.oggetto_pratica
                and ogpr.pratica = prtr.pratica
                and (prtr.tipo_pratica = 'D'
                  or (prtr.tipo_pratica = 'A'
                  and ogim.anno > prtr.anno))
                and prtr.tipo_tributo||'' = 'TARSU'
                and nvl (ogim.ruolo, -1) =
                      nvl (nvl (f_ruolo_totale (ogim.cod_fiscale
                                               ,ogim.anno
                                               ,prtr.tipo_tributo
                                               ,-1
                                               )
                               ,ogim.ruolo
                               )
                          ,-1
                          )
                and ruol.ruolo = ogim.ruolo
                and ruol.invio_consorzio is not null
                and ogim.anno = w_anno_ruolo - w_ind
              group by ogim.anno
                     , prtr.tipo_tributo
                     , cotr.flag_ruolo;
           exception
             when others then
               w_imp_dovuto := 0;
               w_imp_versato := 0;
               w_imp_sgravi := 0;
           end;
           w_errore := 'Bovezzo/Vers.anni prec. ('||w_ind||') '||rec_co.cod_fiscale;
           t_importo_anno(w_ind) := w_imp_dovuto - w_imp_versato - w_imp_sgravi;
           if t_importo_anno(w_ind) <= p_insolvenza_min then
              t_importo_anno(w_ind) := to_number(null);
           end if;
         end loop;
         -- Alla fine del trattamento si verifica se occorre compilare anche la
         -- nota utenza
         w_errore := 'Bovezzo note/Vers.anni prec. '||rec_co.cod_fiscale;
         w_note_utenza := '';
         w_stringa_anni := '';
         for w_ind in reverse 1 .. w_numero_anni
         loop
           w_errore := 'Bovezzo/Vers.anni prec. note ('||w_ind||') '||rec_co.cod_fiscale;
           if t_importo_anno (w_ind) is not null then
              if w_cod_istat = '017025' then
                 if w_note_utenza is null then
                    w_note_utenza := 'ATTENZIONE! Per l''anno '||to_char(w_anno_ruolo - w_ind);
                 else
                    w_note_utenza := replace(w_note_utenza,'l''anno','gli anni');
                    w_note_utenza := w_note_utenza||', '||to_char(w_anno_ruolo - w_ind);
                 end if;
              else
                 if w_stringa_anni is null then
                    w_stringa_anni := 'l''anno '||to_char(w_anno_ruolo - w_ind);
                 else
                    w_stringa_anni := replace(w_stringa_anni,'l''anno','gli anni');
                    w_stringa_anni := w_stringa_anni||', '||to_char(w_anno_ruolo - w_ind);
                 end if;
              end if;
           end if;
         end loop;
         if w_importo_anno is not null then
            if w_cod_istat = '017025' then
               w_note_utenza := w_note_utenza||', '||w_anno_ruolo;
            else
               w_stringa_anni := w_stringa_anni||', '||w_anno_ruolo;
            end if;
         end if;
         if w_cod_istat = '017025' then
            if w_note_utenza is not null then
               w_errore := 'Bovezzo note finali ('||w_note_utenza||') '||rec_co.cod_fiscale;
               w_note_utenza := w_note_utenza||' i versamenti non risultano regolari.'||
                                ' Contattare l''ufficio Tributi';
            else
               w_note_utenza := 'I versamenti precedenti risultano regolarmente eseguiti.';
            end if;
         else
            if w_stringa_anni is not null then
               w_note_utenza := replace(p_stringa_vers_irr,'XXXX',w_stringa_anni);
            else
               w_note_utenza := p_stringa_vers_reg;
            end if;
         end if;
      end if;
      -- Modifica provvisoria per Occhiobello: per estrarre gli stessi valori
      -- presenti nella comunicazione, si utilizza una nuova funzione ricavata
      -- da quella del package di stampa avvisi per Tributiwen.
      -- Da verificare cosa fare per altri clienti.
      if w_cod_istat = '029033' then
         w_note_utenza := f_get_stringa_versamenti ( 'TARSU'
                                                   , rec_co.cod_fiscale
                                                   , p_ruolo
                                                   , w_anno_ruolo
                                                   , w_tipo_emissione
                                                   , p_numero_anni
                                                   , p_insolvenza_min
                                                   , p_stringa_vers_reg
                                                   , p_stringa_vers_irr
                                                   );
         --dbms_output.put_line('Stringa: '||w_note_utenza);
      end if;
      --dati anagrafici
      w_errore := 'Dati anagrafici '||rec_co.cod_fiscale;
      w_riga_wrk := w_riga_wrk||';'||rec_co.cognome||';'||rec_co.nome||';'||rec_co.cod_fiscale||';'
                    ||rec_co.data_nascita||';'||rec_co.sesso||';'
                    ||rec_co.comune_nascita||';'||rec_co.provincia_nascita||';'
                    ||rec_co.cod_fiscale_erede
                    ||';EL;3944;3955;';
      if w_anno_ruolo >= 2021 then
         w_riga_wrk := w_riga_wrk||'TEFA;';
      end if;
      w_riga_wrk := w_riga_wrk||w_cod_catast_comune||';'||w_anno_ruolo||';'||w_numero_ubicazioni||';'
                    ||rec_co.giorni_ruolo||';'||rec_co.mesi_ruolo||';'
                    ||replace(to_char(rec_co.versato_tot,'FM999990.00'),'.',',')||';'                         -- VERSATO;
                    ||replace(to_char(-1*rec_co.versato_netto_tot,'FM999990.00'),'.',',')||';'                -- VERSATO_NO_MAGG;
                    ||replace(to_char(-1*rec_co.versato_magg_tares,'FM999990.00'),'.',',')||';'               -- VERSATO_MAGG_TARES;
                    ||replace(to_char(rec_co.magg_tares_dovuta,'FM999990.00'),'.',',')||';'                   -- MAGG_TARES_DOVUTA_NO_ARR;
                    ||replace(to_char(round(rec_co.magg_tares_dovuta,0),'FM999990.00'),'.',',')||';'          -- MAGG_TARES_DOVUTA;
                    ||replace(to_char(rec_co.magg_tares_no_arr,'FM999990.00'),'.',',')||';'                   -- MAGG_TARES_NO_ARR;
                    ||replace(to_char(rec_co.compensazione,'FM999990.00'),'.',',')||';'                       -- COMPENSAZIONE;
                    ||replace(to_char(rec_co.tares_netta_annua,'FM999990.00'),'.',',')||';'                   -- TARES_NETTA_ANNUA;
                    ||replace(to_char(rec_co.importo_lordo_annuo,'FM999990.00'),'.',',')||';'                 -- IMPORTO_LORDO_ANNUO;
                    ||replace(to_char(rec_co.add_prov_annua,'FM999990.00'),'.',',')||';'                      -- ADD_PROV_ANNUA;
                    ||replace(to_char(rec_co.importo_netto_prec,'FM999990.00'),'.',',')||';'                  -- IMPORTO_NETTO_ACCONTO;
                    ||replace(to_char(rec_co.importo_lordo_prec,'FM999990.00'),'.',',')||';'                  -- IMPORTO_LORDO_ACCONTO;
                    ||replace(to_char(rec_co.addizionale_pro_prec,'FM999990.00'),'.',',')||';'                -- ADD_PROV_ACCONTO;
                    ||replace(to_char(rec_co.sgravio_netto,'FM999990.00'),'.',',')||';'                       -- NON_DOVUTO_NETTO_ACCONTO;
                    ||replace(to_char(rec_co.sgravio_lordo,'FM999990.00'),'.',',')||';'                       -- NONDOVUTO_LORDO_ACCONTO;
                    ||replace(to_char(rec_co.sgravio_prov,'FM999990.00'),'.',',')||';'                        -- NON_DOVUTO_ADD_PROV_ACCONTO;
                    ||replace(to_char(rec_co.residuo_acconto_netto,'FM999990.00'),'.',',')||';'               -- RESIDUO_NETTO_ACCONTO;
                    ||replace(to_char(rec_co.residuo_acconto_lordo,'FM999990.00'),'.',',')||';'               -- RESIDUO_LORDO_ACCONTO;
                    ||replace(to_char(rec_co.residuo_acconto_prov,'FM999990.00'),'.',',')||';'                -- RESIDUO_ADD_PROV_ACCONTO;
                    ||replace(to_char(rec_co.importo_netto,'FM999990.00'),'.',',')||';'                       -- DOVUTO_NETTO_SALDO_NO_COMP;
                    ||replace(to_char(rec_co.importo_tot_s_no_comp,'FM999990.00'),'.',',')||';'               -- DOVUTO_LORDO_SALDO_NO_COMP;
                    ||replace(to_char(rec_co.addizionale_pro,'FM999990.00'),'.',',')||';'                     -- DOVUTO_ADD_PROV_SALDO_NO_COMP;
                    ||replace(to_char(rec_co.dovuto_netto_annuo,'FM999990.00'),'.',',')||';'                  -- DOVUTO_NETTO_ANNUO;
                    ||replace(to_char(rec_co.addizionale_pro_annua,'FM999990.00'),'.',',')||';'               -- ADDIZIONALE_PRO_ANNUA;
                    ||replace(to_char(nvl(rec_co.dovuto_lordo_annuo,0),'FM999990.00'),'.',',')||';'           -- DOVUTO_LORDO_ANNUO_NO_MAGG;
                    ||replace(to_char(round(nvl(rec_co.dovuto_lordo_annuo,0),0),'FM999990.00'),'.',',')||';'  -- DOVUTO_LORDO_ANNUO_NO_MAGG_ARR;
                    ||replace(to_char(w_sgravio_imposta,'FM999990.00'),'.',',')||';'                          -- NON_DOVUTO_NETTO;
                    ||replace(to_char(w_sgravio_add_pro,'FM999990.00'),'.',',')||';'                          -- NON_DOVUTO_ADD_PRO;
                    ||replace(to_char(nvl(rec_co.dovuto_lordo_annuo,0)
                                      +nvl(rec_co.magg_tares_no_arr,0),'FM999990.00'),'.',',')||';'           -- TOTALE_COMPL_ANNUO;
                    ||replace(to_char(nvl(round(rec_co.importo_lordo_prec,0),0),'FM999990.00'),'.',',')||';'  -- RICHIESTO_ACCONTO;
                    ||replace(to_char(nvl(rec_co.importo_lordo_prec,0)
                                      - nvl(round(rec_co.importo_lordo_prec,0),0),'FM999990.00'),'.',',')||';' -- arrotondamento
                    ||replace(to_char(nvl(rec_co.importo_lordo_prec,0)
                                      - nvl(rec_co.sgravio_lordo,0),'FM999990.00'),'.',',')||';'              -- RESIDUO_ACCONTO;
                    --  ||replace(to_char(nvl(rec_co.importo_netto,0)
                    --    + nvl(rec_co.compensazione,0),'FM999990.00'),'.',',')||';'
                    ||replace(to_char(greatest(0,nvl(rec_co.importo_netto,0)
                                                + nvl(rec_co.addizionale_pro,0)
                                                + nvl(p_spese_postali,0))
                      ,'FM999990.00'),'.',',')||';'                                                           -- TOT_SALDO;
                    ||replace(to_char(greatest(0,nvl(round(rec_co.importo_tot_arrotondato,0),0))
                                      +greatest(0,nvl(round(rec_co.magg_tares_no_arr,0),0)),'FM999990.00'),'.',',')||';'  -- TOT_DA_PAGARE_ARR;
                    --  ||replace(to_char(nvl(rec_co.dovuto_lordo_annuo,0)
                    --    -nvl(rec_co.residuo_acconto_lordo,0),'FM999990.00'),'.',',')||';'
                    ||replace(to_char(p_spese_postali,'FM999990.00'),'.',',')||';'                            -- SPESE_NOTIFICA
                    ||replace(to_char(-1*rec_co.imposta_evasa_accertata,'FM999990.00'),'.',',')||';'          -- IMPOSTA_EVASA_ACCERTATA
                    ||replace(to_char(-1*rec_co.magg_tares_evasa_accertata,'FM999990.00'),'.',',')||';'       -- MAGG_TARES_EVASA_ACCERTATA
                    ||replace(to_char(round(-1*rec_co.imposta_evasa_accertata,0),'FM999990.00'),'.',',')||';' -- IMPOSTA_EVASA_ACCERTATA_ARR
                    ||replace(to_char(round(-1*rec_co.magg_tares_evasa_accertata,0),'FM999990.00'),'.',',')   -- MAGG_TARES_EVASA_ACCERTATA_ARR
                    --  ||rec_co.versato_tot||';'||rec_co.magg_tares_no_arr||';'||rec_co.compensazione||';'
                    --  ||rec_co.importo_netto_prec||';'||rec_co.importo_lordo_prec||';'||rec_co.addizionale_pro_prec||';'
                    --  ||rec_co.sgravio_netto||';'||rec_co.sgravio_lordo||';'||rec_co.sgravio_prov||';'
                    --  ||rec_co.residuo_acconto_netto||';'||rec_co.residuo_acconto_lordo||';'||rec_co.residuo_acconto_prov;
                    ;
      -- (VD - 06/04/2021): Aggiunti dati per gestione TEFA 2021
      if w_anno_ruolo >= 2021 then
         w_riga_wrk := w_riga_wrk||';'
                       ||replace(to_char(rec_co.imposta_2021,'FM999990.00'),'.',',')||';'             -- 2021: TARI
                       ||replace(to_char(rec_co.imposta_netta_2021,'FM999990.00'),'.',',')||';'                 -- 2021: TARI AL NETTO DI SGRAVI E COMPENSAZIONI
                       ||replace(to_char(rec_co.add_pro_2021,'FM999990.00'),'.',',')||';'                       -- 2021: TEFA
                       ||replace(to_char(rec_co.add_pro_netta_2021,'FM999990.00'),'.',',')||';'                 -- 2021: TEFA AL NETTO DI SGRAVI E COMPENSAZIONI
                       ||replace(to_char(-1*rec_co.sgravio_imposta_2021,'FM999990.00'),'.',',')||';'            -- 2021: SGRAVIO TARI
                       ||replace(to_char(-1*rec_co.sgravio_add_pro_2021,'FM999990.00'),'.',',')||';'            -- 2021: SGRAVIO TEFA
                       ||replace(to_char(-1*rec_co.comp_imposta_2021,'FM999990.00'),'.',',')||';'               -- 2021: COMPENSAZIONE TARI
                       ||replace(to_char(-1*rec_co.comp_add_pro_2021,'FM999990.00'),'.',',')||';'               -- 2021: COMPENSAZIONE TEFA
                       ||replace(to_char(rec_co.arr_imposta_2021,'FM999990.00MI'),'.',',')||';'                   -- 2021: ARR. TARI
                       ||replace(to_char(rec_co.arr_add_pro_2021,'FM999990.00MI'),'.',',')||';'                   -- 2021: ARR. TEFA
                       ||replace(to_char(rec_co.arr_totale_2021,'FM999990.00MI'),'.',',')||';'                    -- 2021: ARR. TOTALE
                       ||replace(to_char(rec_co.versato_imposta,'FM999990.00'),'.',',')||';'                    -- 2021: VERSATO TARI
                       ||replace(to_char(rec_co.versato_add_pro,'FM999990.00'),'.',',')                         -- 2021: VERSATO TEFA
                       ;
      end if;
      w_riga_wrk := w_riga_wrk||';0101'||w_riga_rata_rateaz;
      -- dati Portoferraio
      if w_cod_istat = '049014' then  -- Portoferraio AB 09/08/2013 per evitare che anche tutti gli altri ora abbiano questi campi, poi decideremo il da farsi
         w_riga_wrk := w_riga_wrk||';'||translate(to_char(w_spese_postali,'FM999999990.00'),'.',',')
                                 ||';'||translate(to_char(round(w_spese_postali,0),'FM999999990.00'),'.',',')
                                 ||';'||translate(to_char(rec_co.importo_netto,'FM999999990.00'),'.',',')
                                 ||';'||translate(to_char(round(rec_co.importo_netto,0),'FM999999990.00'),'.',',')
                                 ||';'||translate(to_char(rec_co.addizionale_pro,'FM999999990.00'),'.',',')
                                 ||';'||translate(to_char(round(rec_co.addizionale_pro,0),'FM999999990.00'),'.',',')
                                 ||';'||translate(to_char(rec_co.maggiorazione_tares,'FM999999990.00'),'.',',')
                                 ||';'||translate(to_char(round(rec_co.maggiorazione_tares,0),'FM999999990.00'),'.',',')
                                 ||';'||translate(to_char(w_tot_complessivo,'FM999999990.00'),'.',',')
                                 ||';'||translate(to_char(w_tot_complessivo_a,'FM999999990.00'),'.',',')
                                 ||';'||translate(to_char(round(w_tot_complessivo,0),'FM999999990.00'),'.',',')
                                 ||';'||translate(to_char(rec_co.da_pagare,'FM999999990.00'),'.',',')
                                 ||';'||translate(to_char(w_tares_add_prov_a,'FM999999990.00'),'.',',')
                                 ||';'||translate(to_char(round(rec_co.da_pagare,0),'FM999999990.00'),'.',',')
                                 ||';'||translate(to_char(w_tares_add_prov_not,'FM999999990.00'),'.',',')
                                 ||';'||translate(to_char(w_tares_add_prov_not_a,'FM999999990.00'),'.',',')
                                 ||';'||translate(to_char(round(w_tares_add_prov_not,0),'FM999999990.00'),'.',',')
                                 ||';'||translate(to_char(round(w_tares_add_prov_not,0)
                                                                + round(rec_co.maggiorazione_tares,0),'FM999999990.00'),'.',',')
                                 ||';'||translate(to_char(round(w_tares_add_prov_not,0)
                                                                + round(rec_co.maggiorazione_tares,0),'FM999999990.00'),'.',',')
                                 ||w_riga_rata_a
                        ;
      end if;
      --
      -- (VD - 27/01/2019): importi qf/qv e nuovi dati relativi ai ruoli calcolati con tariffe
      --
      w_riga_wrk := w_riga_wrk||';'||translate(to_char(rec_co.importo_pf,'FM999999990.00'),'.',',')
                              ||';'||translate(to_char(rec_co.importo_pv,'FM999999990.00'),'.',',');
      --
      if nvl(w_flag_tariffe_ruolo,'N') = 'S' then
         w_riga_wrk := w_riga_wrk||';'||translate(to_char(rec_co.importo_riduzione_pf,'FM999999990.00'),'.',',')
                                 ||';'||translate(to_char(rec_co.importo_riduzione_pv,'FM999999990.00'),'.',',');
      end if;
      --
      -- (VD - 13/12/2018): nuovi dati relativi al calcolo con tariffa base
      --                    solo se il flag e' attivo
      if nvl(p_flag_tariffa_base,'N') = 'S' or
         nvl(w_flag_tariffe_ruolo,'N') = 'S' then
         w_riga_wrk := w_riga_wrk||';'||translate(to_char(rec_co.importo_ruolo_base,'FM999999990.00'),'.',',')
                                 ||';'||translate(to_char(rec_co.addizionale_eca_base,'FM999999990.00'),'.',',')
                                 ||';'||translate(to_char(rec_co.maggiorazione_eca_base,'FM999999990.00'),'.',',')
                                 ||';'||translate(to_char(rec_co.addizionale_pro_base,'FM999999990.00'),'.',',')
                                 ||';'||translate(to_char(rec_co.iva_base,'FM999999990.00'),'.',',')
                                 --||';'||translate(to_char(rec_co.sgravio_netto_base,'FM999999990.00'),'.',',')
                                 --||';'||translate(to_char(rec_co.sgravio_prov_base,'FM999999990.00'),'.',',')
                                 ||';'||translate(to_char(rec_co.sgravio_lordo_base,'FM999999990.00'),'.',',')
                                 ||';'||translate(to_char(rec_co.imposta_base,'FM999999990.00'),'.',',')
                                 ||';'||translate(to_char(rec_co.importo_pf_base,'FM999999990.00'),'.',',')
                                 ||';'||translate(to_char(rec_co.importo_pv_base,'FM999999990.00'),'.',',')
                       ;
      end if;
      -- (VD - 05/12/2018): Bovezzo, si aggiungono i campi con gli eventuali
      --                    importi dovuti relativi ai 5 anni precedenti
      if w_cod_istat = '017025' or w_numero_anni > 0 then
         w_riga_wrk := w_riga_wrk||';'||w_note_utenza;
         w_errore := 'Bovezzo riga 1'||rec_co.cod_fiscale;
         for w_ind in reverse 1 .. w_numero_anni
         loop
           w_riga_wrk := w_riga_wrk||';'||translate(to_char(t_importo_anno(w_ind),'FM999999990.00'),'.',',');
           w_errore := 'Bovezzo riga ('||w_ind||') '||rec_co.cod_fiscale;
         end loop;
         if w_progr_ruolo <> 1 and w_tipo_emissione <> 'A' then
            w_riga_wrk := w_riga_wrk||';'||translate(to_char(w_importo_anno,'FM999999990.00'),'.',',');
         end if;
      end if;
      --w_riga_wrk := w_riga_wrk||';'||w_riga_varXX;
      w_file_clob_1 := w_file_clob_1||w_riga_wrk||';';
      for w_ind in riga_file.first..riga_file.last
      loop
        w_file_clob_1 := w_file_clob_1||riga_file(w_ind);
      end loop;
      w_file_clob_1 := w_file_clob_1||chr(13)||chr(10);
      --w_progr_wrk := w_progr_wrk + 1; --Conta anche il numero dei contribuenti trattati +1
      --BEGIN
--         dbms_output.put_line('C. F.: '||rec_co.cod_fiscale||' riga '||length(w_riga_wrk));
        -- w_riga_wrk := substr(w_riga_wrk,1,4000);
      --  w_dati := substr(w_riga_wrk,1,4000);
      --  w_dati2 := substr(w_riga_wrk,4001,4000);
      --  w_dati3 := substr(w_riga_wrk,8001,4000);
      --  w_dati4 := substr(w_riga_wrk,12001,4000);
      --  w_dati5 := substr(w_riga_wrk,16001,4000);
      --  w_dati6 := substr(w_riga_wrk,20001,4000);
      --  w_dati7 := substr(w_riga_wrk,24001,4000);
      --  w_dati8 := substr(w_riga_wrk,28001,4000);
      --  insert into wrk_trasmissioni (numero
      --                               , dati, dati2, dati3, dati4
      --                               , dati5, dati6, dati7, dati8)
      --  values (lpad(w_progr_wrk,15,'0')
      --         , w_dati, w_dati2, w_dati3, w_dati4
      --         , w_dati5, w_dati6, w_dati7, w_dati8
      --         )
      --         ;
      --EXCEPTION
      --   WHEN others THEN
      --      w_errore := ('Errore in inserimento wrk_trasmissione '||length (w_riga_wrk) || ' crt '
      --                  ||' cod fisc. '||rec_co.cod_fiscale||'(' || SQLERRM || ')' );
      --      raise errore;
      --END;
      w_importo_totale_arrotondato := w_importo_totale_arrotondato + w_importo_rata_0;
   END LOOP; --sel_cont
  -----------------------------------
  --- Intestazione ------------------
  -----------------------------------
   w_intestazione   := 'Rigadestinatario1;Rigadestinatario2;Rigadestinatario3;Rigadestinatario4;Estero;NOME1;INDIRIZZO;CAP;DEST;PROV;IBAN;DOM;VAR01D;VAR01S;';
   r := 0;
   WHILE r < w_max_rate
   LOOP
     w_intestazione := w_intestazione||'CS'||to_char(r+1)||';';
     r:= r +1;
   END LOOP;
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
   if nvl(w_tot_maggiorazione_tares,0) != 0 then
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
   w_intestazione := w_intestazione||w_intest_seconda;
   -- (VD - 30/03/2021): Modifiche per ruoli emessi dal 2021 in avanti
   if w_anno_ruolo < 2021 then
      w_intestazione := w_intestazione||'VCAMPOT;XRATAT;SCADET';
   else
      w_intestazione := w_intestazione||'VCAMPOT;'
                     || 'XRATA' || f_descrizione_titr('TARSU',w_anno_ruolo)||'T;'
                     || 'XRATA' || upper(replace(f_descrizione_adpr(w_anno_ruolo),' ','_'))||'T;'
                     || 'XRATAT'
                     || ';SCADET';
   end if;
   w_int_rateazione := ';RATEAZIONET';
   w_int_rata_a := ';XRATAT_A';
   r := 0;
   WHILE r < w_max_rate
   LOOP
     w_intestazione := w_intestazione||';VCAMPO'||to_char(r+1);
     if w_anno_ruolo < 2021 then
        w_intestazione := w_intestazione||';XRATA'||to_char(r+1);
     else
        w_intestazione := w_intestazione
                       || ';XRATA'||f_descrizione_titr('TARSU',w_anno_ruolo)||to_char(r+1)
                       || ';XRATA'||upper(replace(f_descrizione_adpr(w_anno_ruolo),' ','_'))||to_char(r+1)
                       || ';XRATA'||to_char(r+1)
                       ||';SCADE'||to_char(r+1);
     end if;
     w_int_rateazione := w_int_rateazione||';RATEAZIONE'||to_char(r+1);
     w_int_rata_a     := w_int_rata_a||';XRATA'||to_char(r+1)||'_A';
     r:= r +1;
   END LOOP;
   w_intestazione := w_intestazione
                     ||';COGNOME;NOME;COD_FISCALE;DATA_NASCITA;SESSO;COMUNE_NASCITA;'
                     ||'PROVINCIA_NASCITA;COD_FISCALE_EREDE_COOBBLIGATO;SEZIONE;CODICE_TRIB_TARES;CODICE_TRIB_MAGG;';
   if w_anno_ruolo >= 2021 then
      w_intestazione := w_intestazione||'CODICE_TRIB_TEFA;';
   end if;
   w_intestazione := w_intestazione||'CODICE_ENTE;ANNO;NUMERO_IMMOBILI;GG;MM;'
                     ||'VERSATO;VERSATO_NO_MAGG;VERSATO_MAGG_TARES;MAGG_TARES_DOVUTA_NO_ARR;MAGG_TARES_DOVUTA;MAGG_TARES_NO_ARR;COMPENSAZIONE;'
                     ||'TARES_NETTA_ANNUA;IMPORTO_LORDO_ANNUO;ADD_PROV_ANNUA;'
                     ||'IMPORTO_NETTO_ACCONTO;IMPORTO_LORDO_ACCONTO;ADD_PROV_ACCONTO;'
                     ||'NON_DOVUTO_NETTO_ACCONTO;NONDOVUTO_LORDO_ACCONTO;NON_DOVUTO_ADD_PROV_ACCONTO;'
                     ||'RESIDUO_NETTO_ACCONTO;RESIDUO_LORDO_ACCONTO;RESIDUO_ADD_PROV_ACCONTO;'
                     ||'DOVUTO_NETTO_SALDO_NO_COMP;DOVUTO_LORDO_SALDO_NO_COMP;DOVUTO_ADD_PROV_SALDO_NO_COMP;'
                     ||'DOVUTO_NETTO_ANNUO;ADDIZIONALE_PRO_ANNUA;DOVUTO_LORDO_ANNUO_NO_MAGG;DOVUTO_LORDO_ANNUO_NO_MAGG_ARR;'
                     ||'NON_DOVUTO_NETTO;NON_DOVUTO ADD_PROV;TOTALE_COMPL_ANNUO;'
                     ||'RICHIESTO_ACCONTO;ARROTONDAMENTI;RESIDUO_ACCONTO;TOT_SALDO;TOT_DA_PAGARE_ARR;'
--                     ||'DIFF_DOVUTO_NO_MAGG;'
                     ||'SPESE_NOTIFICA;'
                     ||'IMPOSTA_EVASA_ACCERTATA;'
                     ||'MAGG_TARES_EVASA_ACCERTATA;'
                     ||'IMPOSTA_EVASA_ACCERTATA_ARR;'
                     ||'MAGG_TARES_EVASA_ACCERTATA_ARR';
   -- /VD - 006/04/2021): gestione campo per TEFA 2021
   if w_anno_ruolo >= 2021 then
      w_intestazione := w_intestazione||';'||w_descr_titr||';'||w_descr_titr||'_NETTA'||';'||
                        upper(replace(f_descrizione_adpr(w_anno_ruolo),' ','_'))||';'||
                        upper(replace(f_descrizione_adpr(w_anno_ruolo),' ','_'))||'_NETTA'||';'||
                        'SGRAVIO_'||w_descr_titr||';'||
                        'SGRAVIO_'||upper(replace(f_descrizione_adpr(w_anno_ruolo),' ','_'))||';'||
                        'COMPENSAZIONE_'||w_descr_titr||';'||
                        'COMPENSAZIONE_'||upper(replace(f_descrizione_adpr(w_anno_ruolo),' ','_'))||';'||
                        'ARROTONDAMENTO_'||w_descr_titr||';'||
                        'ARROTONDAMENTO_'||upper(replace(f_descrizione_adpr(w_anno_ruolo),' ','_'))||';'||
                        'ARROTONDAMENTO_TOTALE'||';'||
                        'VERSATO_'||w_descr_titr||';'||
                        'VERSATO_'||upper(replace(f_descrizione_adpr(w_anno_ruolo),' ','_'));
   end if;
   w_intestazione := w_intestazione||w_int_rateazione||';';
   w_intestazione := w_intestazione||'IMPORTO_QUOTA_FISSA;IMPORTO_QUOTA_VAR;';
   if w_cod_istat = '049014' then  -- Portoferraio AB 09/08/13 inserita per evitare tutti i nuovi campi voluti da Portoferraio da valutare
      w_intestazione := w_intestazione||'SPESE_NOTIFICA;SPESE_NOTIFICA_ARR;TARES;TARES_ARR;ADD_PROV;'
                                      ||'ADD_PROV_ARR;MAGG_TARES;MAGG_TARES_ARR;TOT_COMPLESSIVO;COMPLESSIVO_TOT_A;'
                                      ||'COMPLESSIVO_A_TOT;TARES_ADD_PROV;TARES_ADD_PROV_TOT_A;TARES_ADD_PROV_A_TOT;'
                                      ||'TARES_ADD_PROV_NOTIFICA;TARES_ADD_PROV_NOTIFICA_TOT_A;'
                                      ||'TARES_ADD_PROV_NOTIFICA_A_TOT;TARES_ADD_PROV_NOTIFICA_A_TOT_MAGG_TARES_ARR;'
                                      ||w_int_rata_a;
   end if;
   --
   -- (VD - 27/03/2019): nuovi dati relativi al ruoli calcolati con tariffa
   --                    solo se il flag e' attivo
   if nvl(w_flag_tariffe_ruolo,'N') = 'S' then
      w_intestazione := w_intestazione||'IMPORTO_RIDUZIONE_PF;IMPORTO_RIDUZIONE_PV;';
   end if;
   -- (VD - 13/12/2018): nuovi dati relativi al calcolo con tariffa base
   --                    solo se il flag e' attivo
   if nvl(p_flag_tariffa_base,'N') = 'S' or
      nvl(w_flag_tariffe_ruolo,'N') = 'S' then
      w_intestazione := w_intestazione||'IMPORTO_RUOLO_BASE;ADD_ECA_BASE;MAGG_ECA_BASE;ADD_PRO_BASE;'
                                      ||'IVA_BASE;SGRAVIO_LORDO_BASE;'
                                      ||'IMPOSTA_BASE;IMPORTO_PF_BASE;IMPORTO_PV_BASE;';
   end if;
   -- Personalizzazione Bovezzo
   if w_cod_istat = '017025' or w_numero_anni > 0 then
      w_intestazione := w_intestazione||'NOTE_UTENZA;';
      for w_ind in reverse 1..w_numero_anni
      loop
        w_intestazione := w_intestazione||to_char(w_anno_ruolo - w_ind)||';';
      end loop;
      if w_progr_ruolo = 1 or w_tipo_emissione = 'A' then
         w_intestazione := w_intestazione||';';
      else
         w_intestazione := w_intestazione||to_char(w_anno_ruolo)||';';
      end if;
      w_errore := 'Bovezzo Intestazione';
   end if;
   --- Composizione int_varXX
   i := 0;
   WHILE i < w_max_progr_ubicazione
   LOOP
     if w_max_progr_ubicazione < 100 then
        w_intestazione := w_intestazione||'VAR'||lpad( to_char(i+1),2,'0')||'A;';
     else
        w_intestazione := w_intestazione||'VAR'||lpad( to_char(i+1),3,'0')||'A;';
     end if;
     i:= i +1;
   END LOOP;
   w_file_clob := w_intestazione||chr(13)||chr(10)||w_file_clob_1;
   w_progr_wrk := 1;
   BEGIN
      --w_dati := substr(w_intestazione,1,4000);
      --w_dati2 := substr(w_intestazione,4001,4000);
      --w_dati3 := substr(w_intestazione,8001,4000);
      --w_dati4 := substr(w_intestazione,16001,4000);
      --w_dati5 := substr(w_intestazione,20001,4000);
      --w_dati6 := substr(w_intestazione,24001,4000);
      --w_dati7 := substr(w_intestazione,28001,4000);
      --w_dati8 := substr(w_intestazione,32001,4000);
      insert into wrk_trasmissioni ( numero
                                   , dati_clob )
      --                             , dati, dati2, dati3, dati4
      --                             , dati5, dati6, dati7, dati8)
      values ( lpad(w_progr_wrk,15,'0')
             , w_file_clob
      --       ,w_dati, w_dati2, w_dati3, w_dati4
      --       ,w_dati5, w_dati6, w_dati7, w_dati8
             )
             ;
   EXCEPTION
      WHEN others THEN
           RAISE_APPLICATION_ERROR
               (-20929,'Errore in inserimento wrk_trasmissione (File CLOB) '||
                    ' ('||SQLERRM||')');
   END;
   p_importo_tot_arr := w_importo_totale_arrotondato ;
   w_errore := ' Fine ';
EXCEPTION
  WHEN others THEN
    RAISE_APPLICATION_ERROR
       (-20939,w_errore||' ('||SQLERRM||')');
END;
/* End Procedure: ESTRAZIONE_TARES_POSTE */
/

