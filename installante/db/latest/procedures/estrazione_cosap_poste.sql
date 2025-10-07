--liquibase formatted sql 
--changeset abrandolini:20250326_152423_estrazione_cosap_poste stripComments:false runOnChange:true 
 
create or replace procedure ESTRAZIONE_COSAP_POSTE
/*************************************************************************
 NOME:        ESTRAZIONE_COSAP_POSTE
 DESCRIZIONE: Estrazione dati COSAP per invio a mezzo posta
 NOTE:        Personalizzazioni presenti:
              048010 - Comune di Castelfiorentino
              047014 - Provincia di Pistoia (eliminate)
 Rev.    Date         Author      Note
 007     30/08/2017   VD          Eliminate modifiche per provincia di
                                  Pistoia (per creazione procedure
                                  personalizzata)
 006     28/08/2017   VD          Corretta gestione righe piu' lunghe di
                                  4000 crt (per contribuenti con più di 20
                                  oggetti_imposta)
 005     24/08/2017   VD          Modifiche per provincia di Pistoia:
                                  si escludono dall'estrazione gli oggetti
                                  con anno di oggetti_imposta = anno decorrenza
                                  e decorrenza > 01/01/anno di oggetti_imposta.
 004     07/06/2017   VD          Aggiunto nvl su conto corrente in selezione
                                  rate imposta
 003     06/06/2017   VD          Corretta selezione prima riga destinatario
                                  in caso di ni_presso null e f_recapito null
 002     07/11/2014   Betta T.    Corretta insert in wrk_trasmissioni per
                                  aggiunta di campi
 001     09/10/2014   Betta T.    Aggiunta gestione recapiti
 000     XX/XX/XXXX   XX          Prima emissione.
*************************************************************************/
( a_anno in number
, a_sessione in number
) is
cursor sel_cont (c_anno number, c_istat varchar2, c_tributo number) is
select max(substr(
--             decode(nvl(sogg.ni_presso,f_recapito(sogg.ni, prtr.tipo_tributo, 1, trunc(sysdate),'PR'))
--                   ,null,'Spett.le'||decode(sogg.sesso,'F',' sig.ra','M',' sig.','')
--                   ,'Spett.le'||decode(sogg.sesso,'F',' sig.ra','M',' sig.','')
--                    ||' '||replace(replace(sogg.cognome_nome,'/',' '),';',',')
--                   )
             decode(sogg.ni_presso
                   ,null,
                   decode(f_recapito(sogg.ni, prtr.tipo_tributo, 1, trunc(sysdate),'PR')
                         ,null,'Spett.le'||decode(sogg.sesso,'F',' sig.ra','M',' sig.','')
                         ,'Spett.le'||decode(sogg.sesso,'F',' sig.ra','M',' sig.','')
                          ||' '||replace(replace(sogg.cognome_nome,'/',' '),';',',')
                          )
                   ,'Spett.le'||decode(sogg.sesso,'F',' sig.ra','M',' sig.','')
                    ||' '||replace(replace(sogg.cognome_nome,'/',' '),';',',')
                   )
                 ,1,44)||';'||                                                                        -- Rigadestinatario1
           substr(
             decode(sogg.ni_presso
                   ,null,nvl(f_recapito(sogg.ni, prtr.tipo_tributo, 1, trunc(sysdate),'PR')
                            ,replace(replace(sogg.cognome_nome,'/',' '),';',','))
                   ,'c/o '||replace(replace(sogP.cognome_nome,'/',' '),';',',')
                   )
                 ,1,44)||';'||                                                                        -- Rigadestinatario2
           decode(sogg.ni_presso
                 ,null,substr(nvl(f_recapito(sogg.ni, prtr.tipo_tributo, 1, trunc(sysdate))
                                 ,decode(sogg.cod_via
                                        ,to_number(null),sogg.denominazione_via
                                        ,arvi.denom_uff
                                        )
                                  ||' '||to_char(sogg.num_civ)
                                  ||decode(sogg.suffisso,'','','/'||sogg.suffisso)
                                  ||decode(sogg.scala,'','',' Sc.'||sogg.scala)
                                  ||decode(sogg.piano,'','',' P.'||sogg.piano)
                                  ||decode(sogg.interno,'','',' Int.'||sogg.interno)
                                 )
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
                   ,null,nvl(f_recapito(sogg.ni, prtr.tipo_tributo, 1, trunc(sysdate),'CC')
                            ,lpad(to_char(nvl(sogg.cap,comR.cap)),5,'0')||' '
                             ||substr(comR.denominazione,1,30)||' '
                             ||substr(proR.sigla,1,2)
                            )
                   ,lpad(to_char(nvl(sogP.cap,comP.cap)),5,'0')||' '
                    ||substr(comP.denominazione,1,30)||' '
                    ||substr(proP.sigla,1,2)
                   )
                  ,1,44)||';'||                                                                  -- Rigadestinatario4
         decode(sogg.ni_presso
               ,null,nvl(f_recapito(sogg.ni, prtr.tipo_tributo, 1, trunc(sysdate),'SE')
                        ,sttR.denominazione
                        )
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
         decode(c_istat
               ,'048033',decode(nvl(deba.cod_abi,0)    -- Pontassieve
                               ,07601, '*'
                               ,''
                               )
               ,''
               )  || ';'||                                                                        -- DOMiciliazione bancaria postale
          'C.U.: '||to_char(sogg.ni)||' C.F. P.IVA: '||cont.cod_fiscale||';'||                    -- VAR01D
          'CU:'||to_char(sogg.ni)||' CF-PI:'||cont.cod_fiscale||';'                               -- VAR02S
          )                                              prima_parte
     , max(sogg.ni)                              ni
     , max(replace(sogg.cognome_nome,'/',' '))   cognome_nome
     , cont.cod_fiscale                          cod_fiscale
     , sum(ogim.imposta)                         imposta_contribuente
  from ad4_provincie        proR
     , ad4_comuni           comR
     , ad4_stati_territori  sttR
     , ad4_provincie        proP
     , ad4_comuni           comP
     , ad4_stati_territori  sttP
     , archivio_vie         arvi
     , archivio_vie         arvP
     , soggetti             sogg
     , soggetti             sogP
     , contribuenti         cont
     , deleghe_bancarie     deba
     , oggetti_imposta      ogim
     , oggetti_pratica      ogpr
--     , oggetti_contribuente ogco
     , pratiche_tributo     prtr
 where proR.provincia            (+)   = sogg.cod_pro_res
   and comR.provincia_stato      (+)   = sogg.cod_pro_res
   and comR.comune               (+)   = sogg.cod_com_res
   and sttR.stato_territorio     (+)   = sogg.cod_pro_res
   and proP.provincia            (+)   = sogP.cod_pro_res
   and comP.provincia_stato      (+)   = sogP.cod_pro_res
   and comP.comune               (+)   = sogP.cod_com_res
   and sttP.stato_territorio     (+)   = sogP.cod_pro_res
   and arvi.cod_via              (+)   = sogg.cod_via
   and arvP.cod_via              (+)   = sogP.cod_via
   and sogP.ni                   (+)   = sogg.ni_presso
   and sogg.ni                         = cont.ni
   and deba.cod_fiscale          (+)   = cont.cod_fiscale
   and deba.tipo_tributo         (+)   = 'TOSAP'
   and ogpr.oggetto_pratica            = ogim.oggetto_pratica
   and ogim.flag_calcolo               = 'S'
   and prtr.tipo_tributo||''           = 'TOSAP'
   and ((prtr.tipo_pratica    in ('D','C')) or
        (prtr.tipo_pratica     = 'A' and ogim.anno > prtr.anno and prtr.flag_denuncia = 'S')
       )
--   and ogpr.oggetto_pratica            = ogim.oggetto_pratica
   and prtr.pratica                    = ogpr.pratica
   and ogim.anno                       = c_anno
   and ogim.cod_fiscale                = cont.cod_fiscale
   and ogpr.tributo                    = nvl(c_tributo,ogpr.tributo)
   and nvl(replace(replace(sogg.cognome_nome,'/',' '),';',','),' ') <> ' '
   and nvl(substr(decode(sogg.cod_via
                        , null, sogg.denominazione_via
                        , arvi.denom_uff)
                 || decode(sogg.num_civ
                          ,null, ''
                          ,', ' || to_char(sogg.num_civ))
               || decode(sogg.suffisso
                        ,null, ''
                        ,'/' || sogg.suffisso),1,44),' ') <> ' '
   and nvl(to_char(nvl(sogg.cap,nvl(comR.cap,0))),' ') <> ' '
   and  nvl(comR.denominazione,' ') <> ' '
   and (  (nvl(proR.sigla,' ') <> ' ')
       or (nvl(sttR.denominazione,' ') <> ' ')
       )
   -- (VD - 24/08/2017): aggiunto controllo per escludere oggetti con
   --                    con anno di oggetti_imposta = anno decorrenza
   --                    e decorrenza > 01/01/anno di oggetti_imposta
   -- (VD - 30/08/2017): eliminate modifiche
--      and ogco.cod_fiscale                = cont.cod_fiscale
--      and ogpr.oggetto_pratica            = ogco.oggetto_pratica
--      and (c_istat <> '047014' or
--          (c_istat = '047014' and
--          (ogim.anno <> to_number(to_char(nvl(ogco.data_decorrenza,to_date('01011900','ddmmyyyy')),'yyyy')) or
--          (ogim.anno = to_number(to_char(nvl(ogco.data_decorrenza,to_date('01011900','ddmmyyyy')),'yyyy')) and
--          nvl(ogco.data_decorrenza,to_date('01011900','ddmmyyyy')) <= to_date('0101'||ogim.anno,'ddmmyyyy')))))
group by cont.cod_fiscale
order by cont.cod_fiscale
;
cursor sel_ogim (c_anno number, c_cod_fiscale varchar2, c_istat varchar2, c_tributo number) is
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
              ,1,50
              )
     || ' - '
     ||decode(cate.descrizione
             ,null, ''
             , cate.descrizione
             )
     || ' - MQ.' || ogpr.consistenza
     || ' - EURO/MQ.' || tari.tariffa
     || decode(c_istat
              ,'048010',decode(ogpr.num_concessione    -- Castelfiorentino
                              ,null,''
                              ,' - Concessione n. ' ||to_char(ogpr.num_concessione)
                              )
              ,''
              )
     ||';'                            note
     , ogim.oggetto_imposta                                     oggetto_imposta
  from oggetti_imposta                 ogim
     , oggetti_pratica                 ogpr
--     , oggetti_contribuente            ogco
     , pratiche_tributo                prtr
     , archivio_vie                    arvi
     , oggetti                         ogge
     , tariffe                         tari
     , categorie                       cate
 where ogpr.oggetto_pratica            = ogim.oggetto_pratica
   and prtr.pratica                    = ogpr.pratica
   and ogge.oggetto                    = ogpr.oggetto
   and arvi.cod_via             (+)    = ogge.cod_via
   and tari.tributo                    = ogpr.tributo
   and tari.categoria                  = ogpr.categoria
   and tari.tipo_tariffa               = ogpr.tipo_tariffa
   and tari.anno                       = ogim.anno
   and cate.tributo                    = ogpr.tributo
   and cate.categoria                  = ogpr.categoria
   and ogpr.tributo                    = nvl(c_tributo,ogpr.tributo)
   and prtr.tipo_tributo||''           = 'TOSAP'
   and ogim.flag_calcolo               = 'S'
   and ogim.anno                       = c_anno
   and ogim.cod_fiscale                = c_cod_fiscale
   -- (VD - 24/08/2017): aggiunto controllo per escludere oggetti con
   --                    con anno di oggetti_imposta = anno decorrenza
   --                    e decorrenza > 01/01/anno di oggetti_imposta.
   -- (VD - 30/08/2017): eliminate modifiche
--      and ogco.cod_fiscale                = c_cod_fiscale
--      and ogco.oggetto_pratica            = ogpr.oggetto_pratica
--      and (c_istat <> '047014' or
--          (c_istat = '047014' and
--          (ogim.anno <> to_number(to_char(nvl(ogco.data_decorrenza,to_date('01011900','ddmmyyyy')),'yyyy')) or
--          (ogim.anno = to_number(to_char(nvl(ogco.data_decorrenza,to_date('01011900','ddmmyyyy')),'yyyy')) and
--          nvl(ogco.data_decorrenza,to_date('01011900','ddmmyyyy')) <= to_date('0101'||ogim.anno,'ddmmyyyy')))))
   ;
cursor sel_raim (c_cod_fiscale varchar2, c_anno number, c_conto_corrente number) is
select raim.rata                                                                     numero_rata
     , sum(nvl(raim.imposta_round,raim.imposta))                                     importo_rata_num
  from rate_imposta      raim
 where raim.cod_fiscale                = c_cod_fiscale
   and raim.tipo_tributo               = 'TOSAP'
   and raim.anno                       = c_anno
   and nvl(raim.conto_corrente,0)      = nvl(c_conto_corrente,nvl(raim.conto_corrente,0))
group by raim.rata
order by raim.rata
;
w_intestazione               varchar2(4000);
w_intest_prima               varchar2(2000);
w_intest_utenza              varchar2(2000);
w_intest_seconda             varchar2(2000);
w_intest_terza               varchar2(2000);
i                            number;
r                            number;
w_max_progr_ubicazione       number;
w_max_rate                   number;
w_num_max_utenze             number := 20;
w_riga_rata                  varchar2(2000);
w_riga_causale               varchar2(2000);
w_utenze_contribuente        number;
w_importo_totale_complessivo number;
w_importo_totale_arrotondato number;
w_numero_rate                number;
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
w_progressivo                number;
w_conta_utenze               number;
w_progr_wrk                  number;
w_riga_wrk                   varchar2(32767);
w_cont_da_trattare           number;
w_flag_canone                varchar2(1);
w_istat                      varchar2(6);
w_tributo                    number;
w_conto_corrente             number;
--Gestione delle eccezioni
w_errore                     varchar2(2000);
w_err_par                    varchar2(50);
errore                       exception;
w_riga_suppl                 varchar2(32767);
w_dati                       varchar2(4000);
w_dati2                      varchar2(4000);
w_dati3                      varchar2(4000);
w_dati4                      varchar2(4000);
w_dati5                      varchar2(4000);
w_dati6                      varchar2(4000);
w_dati7                      varchar2(4000);
w_dati8                      varchar2(4000);
BEGIN
   w_importo_totale_complessivo := 0;
   w_importo_totale_arrotondato := 0;
   w_conta_utenze   := 0;
   w_progr_wrk := 0;
   w_cont_da_trattare := 0;
   --Recupero il Flag Canone e, se null, inerisco nel file gli importi arrotondati
   BEGIN
      select decode(titr.flag_canone
                   , null, 'N'
                   , titr.flag_canone)
        into w_flag_canone
        from tipi_tributo titr
       where titr.tipo_tributo = 'TOSAP'
           ;
   EXCEPTION
      WHEN others THEN
         w_errore := ('Errore nella ricerca del flag Canone' || ' (' || SQLERRM || ')' );
         raise errore;
   END;
   --Recupero codice Istat del Comune
   BEGIN
      select lpad(to_char(dage.pro_cliente),3,'0')||
             lpad(to_char(dage.com_cliente),3,'0')
        into w_istat
        from dati_generali dage
           ;
   EXCEPTION
      WHEN others THEN
         w_errore := ('Errore nel recupero codice istat' || ' (' || SQLERRM || ')' );
         raise errore;
   END;
   -- Codice Tributo da trattare, viene settata la variabile p_tributo,
   -- se null tratta tutti i codici tributo
   if w_istat = '048010' then  -- Castelfiorentino
      w_tributo := 453;
   else
      w_tributo := null;
   end if;
   -- Recupero del conto corrente, serve per estrarre le rate imposta corrette
   if w_tributo is not null then
   BEGIN
      select cotr.conto_corrente
        into w_conto_corrente
        from codici_tributo  cotr
       where cotr.tipo_tributo = 'TOSAP'
         and cotr.tributo      = w_tributo
           ;
   EXCEPTION
      WHEN others THEN
         w_errore := ('Errore nel recupero conto corrente' || ' (' || SQLERRM || ')' );
         raise errore;
   END;
   else
      w_conto_corrente := null;
   end if;
   BEGIN
      select to_char(scade.data_scadenza,'dd/mm/yyyy')
        into w_scadenza_rata_0
        from scadenze scade
       where scade.tipo_tributo = 'TOSAP'
         and scade.anno = a_anno
         and scade.rata = 0
           ;
   EXCEPTION
      WHEN others THEN
         w_errore := ('Errore nella ricerca della scadenza della rata zero' || ' (' || SQLERRM || ')' );
         raise errore;
   END;
   BEGIN
      select count(1)
        into w_cont_da_trattare
        from (select 1
                from ad4_provincie        prre
                   , ad4_comuni           core
                   , ad4_comuni           cona
                   , ad4_provincie        prr2
                   , ad4_comuni           cor2
                   , archivio_vie         arvi
                   , archivio_vie         arv2
                   , soggetti             sogg
                   , soggetti             sog2
                   , contribuenti         cont
            --       , deleghe_bancarie     deba
                   , oggetti_imposta      ogim
                   , oggetti_pratica      ogpr
            --       , oggetti_contribuente ogco
                   , pratiche_tributo     prtr
               where prre.provincia            (+)   = sogg.cod_pro_res
                 and core.provincia_stato      (+)   = sogg.cod_pro_res
                 and core.comune               (+)   = sogg.cod_com_res
                 and cona.provincia_stato      (+)   = sogg.cod_pro_res
                 and cona.comune               (+)   = 0
                 and prr2.provincia            (+)   = sog2.cod_pro_res
                 and cor2.provincia_stato      (+)   = sog2.cod_pro_res
                 and cor2.comune               (+)   = sog2.cod_com_res
                 and arvi.cod_via              (+)   = sogg.cod_via
                 and arv2.cod_via              (+)   = sog2.cod_via
                 and sog2.ni                   (+)   = sogg.ni_presso
                 and sogg.ni                         = cont.ni
             --    and deba.cod_fiscale          (+)   = cont.cod_fiscale
                 and ((prtr.tipo_pratica             in ('D','C')) or
                          (prtr.tipo_pratica     = 'A' and ogim.anno > prtr.anno and prtr.flag_denuncia = 'S'))
                 and ogpr.oggetto_pratica             = ogim.oggetto_pratica
                 and ogim.flag_calcolo                  = 'S'
                 and prtr.tipo_tributo||''            = 'TOSAP'
                 and ogpr.oggetto_pratica            = ogim.oggetto_pratica
                 and prtr.pratica                    = ogpr.pratica
                 and ogpr.tributo                    = nvl(w_tributo,ogpr.tributo)
                 and ogim.anno                       = a_anno
                 and ogim.cod_fiscale                = cont.cod_fiscale
                 -- (VD - 24/08/2017): aggiunto controllo per escludere oggetti con
                 --                    con anno di oggetti_imposta = anno decorrenza
                 --                    e decorrenza > 01/01/anno di oggetti_imposta
                 -- (VD - 30/08/2017): eliminate modifiche
             --       and ogco.cod_fiscale                = cont.cod_fiscale
             --       and ogco.oggetto_pratica            = ogpr.oggetto_pratica
             --       and (w_istat <> '047014' or
             --       (w_istat = '047014' and
             --       (ogim.anno <> to_number(to_char(nvl(ogco.data_decorrenza,to_date('01011900','ddmmyyyy')),'yyyy')) or
             --       (ogim.anno = to_number(to_char(nvl(ogco.data_decorrenza,to_date('01011900','ddmmyyyy')),'yyyy')) and
             --       nvl(ogco.data_decorrenza,to_date('01011900','ddmmyyyy')) <= to_date('0101'||ogim.anno,'ddmmyyyy')))))
            group by cont.cod_fiscale)
                   ;
   EXCEPTION
      WHEN others THEN
         w_errore := ('Errore nella ricerca del nr. di contribuenti da trattare' || ' (' || SQLERRM || ')' );
         raise errore;
   END;
   BEGIN
      delete wrk_trasmissioni
           ;
   EXCEPTION
      WHEN others THEN
         w_errore := ('Errore nella delete della tabella wrk_trasmissioni' || ' (' || SQLERRM || ')' );
            raise errore;
   END;
   BEGIN
    select max(numero_ubicazioni)
      into w_max_progr_ubicazione
      from (select ogim.cod_fiscale
                 , count(1) numero_ubicazioni
              from oggetti_imposta       ogim
                 , oggetti_pratica       ogpr
         --        , oggetti_contribuente  ogco
                 , pratiche_tributo      prtr
             where prtr.pratica = ogpr.pratica
               and ogpr.oggetto_pratica = ogim.oggetto_pratica
               and prtr.tipo_tributo||'' = 'TOSAP'
               and ogim.anno = a_anno
               and ogim.flag_calcolo = 'S'
               -- (VD - 24/08/2017): aggiunto controllo per escludere oggetti con
               --                    con anno di oggetti_imposta = anno decorrenza
               --                    e decorrenza > 01/01/anno di oggetti_imposta
               -- (VD - 30/08/2017): eliminate modifiche
         --      and ogco.cod_fiscale                = prtr.cod_fiscale
         --      and ogco.oggetto_pratica            = ogpr.oggetto_pratica
         --      and (w_istat <> '047014' or
         --          (w_istat = '047014' and
         --          (ogim.anno <> to_number(to_char(nvl(ogco.data_decorrenza,to_date('01011900','ddmmyyyy')),'yyyy')) or
         --          (ogim.anno = to_number(to_char(nvl(ogco.data_decorrenza,to_date('01011900','ddmmyyyy')),'yyyy')) and
         --           nvl(ogco.data_decorrenza,to_date('01011900','ddmmyyyy')) <= to_date('0101'||ogim.anno,'ddmmyyyy')))))
             group by ogim.cod_fiscale);
   EXCEPTION
     WHEN others THEN
       RAISE_APPLICATION_ERROR
           (-20919,'Errore in ricerca max ubicazioni'||
                ' ('||SQLERRM||')');
   END;
--   if w_max_progr_ubicazione > w_num_max_utenze then
--      w_max_progr_ubicazione := w_num_max_utenze;
--   end if;
   BEGIN
    select max(rata)
      into w_max_rate
      from scadenze scad
     where scad.anno = a_anno
       and scad.tipo_tributo = 'TOSAP'
       and scad.tipo_scadenza = 'V'
         ;
   EXCEPTION
     WHEN others THEN
       RAISE_APPLICATION_ERROR
           (-20919,'Errore in ricerca max rata'||
                ' ('||SQLERRM||')');
   END;
   w_intest_prima   := 'Rigadestinatario1;Rigadestinatario2;Rigadestinatario3;Rigadestinatario4;Estero;NOME1;INDIRIZZO;CAP;DEST;PROV;IBAN;DOM;VAR01D;VAR01S;';
   w_intest_terza   := 'VCAMPOT;XRATAT;SCADET';
   w_intestazione   := w_intest_prima;
   r := 0;
   WHILE r < w_max_rate
   LOOP
     w_intestazione := w_intestazione||'CS'||to_char(r+1)||';';
     r:= r +1;
   END LOOP;
   i := 0;
   if (w_max_rate = 0) or (w_max_rate = 2) or (w_max_rate = 4) then
      WHILE i < w_num_max_utenze --w_max_progr_ubicazione
      LOOP
        w_intestazione := w_intestazione||'NOTE'||lpad( to_char(i+1),2,'0')||';';
        i:= i +1;
      END LOOP;
   end if;
   w_intestazione := w_intestazione||w_intest_terza;
   r := 0;
   WHILE r < w_max_rate
   LOOP
     w_intestazione := w_intestazione||';VCAMPO'||to_char(r+1)||';XRATA'||to_char(r+1)||';SCADE'||to_char(r+1);
     r:= r +1;
   END LOOP;
   IF w_max_progr_ubicazione > w_num_max_utenze then
      i := 20;
      WHILE i < w_max_progr_ubicazione
      LOOP
        w_intestazione := w_intestazione||';'||'NOTE'||lpad( to_char(i+1),2,'0');
        i:= i +1;
      END LOOP;
   end if;
   --
   w_progr_wrk := w_progr_wrk + 1;
   w_dati := substr(w_intestazione,1,4000);
   w_dati2 := substr(w_intestazione,4001,4000);
   w_dati3 := substr(w_intestazione,8001,4000);
   w_dati4 := substr(w_intestazione,12001,4000);
   w_dati5 := substr(w_intestazione,16001,4000);
   w_dati6 := substr(w_intestazione,20001,4000);
   w_dati7 := substr(w_intestazione,24001,4000);
   w_dati8 := substr(w_intestazione,28001,4000);
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
   w_errore := ' Inizio ';
   FOR rec_cont IN sel_cont(a_anno, w_istat, w_tributo) --Contribuenti
   LOOP
      --dbms_output.put_line(rec_cont.cod_fiscale || ' ' || rec_cont.cognome_nome || ' ' || rec_cont.ni);
      w_progressivo    := 0;
      w_importo_rata_0 := 0;
      w_importo_rata_1 := 0;
      w_importo_rata_2 := 0;
      w_importo_rata_3 := 0;
      w_importo_rata_4 := 0;
      w_riga_wrk := rec_cont.prima_parte;
      w_errore := to_char(length(w_riga_wrk))||'  1 '||rec_cont.cod_fiscale;
      w_riga_rata := '';
      w_riga_causale := '';
      w_riga_suppl := '';
      --Determinazione degli Importi Rateizzati a livello di Contribuente
      FOR rec_raim in sel_raim(rec_cont.cod_fiscale, a_anno, w_conto_corrente) --Rate
      LOOP
         w_riga_causale := w_riga_causale || 'COSAP - ANNO '||to_char(a_anno)||' - RATA '||to_char(rec_raim.numero_rata)||';';
         if rec_raim.numero_rata = 1 then
            w_importo_rata_1 := rec_raim.importo_rata_num;
            BEGIN
               select to_char(scade.data_scadenza,'dd/mm/yyyy')
                 into w_scadenza_rata_1
                 from scadenze scade
                where scade.tipo_tributo = 'TOSAP'
                  and scade.anno = a_anno
                  and scade.rata = 1
                    ;
            EXCEPTION
            WHEN others THEN
               w_errore := ('Errore nella ricerca della scadenza della prima rata' || ' (' || SQLERRM || ')' );
               raise errore;
            END;
            --Inserimento dei dati sulla rata 1
            w_vcampo1 := to_char(a_anno) || '1' || lpad(rec_cont.ni,8,'0') || '001;';
            w_riga_rata := w_riga_rata || ';' || w_vcampo1 || w_importo_rata_1 || ';' || w_scadenza_rata_1;
         end if;
         if rec_raim.numero_rata = 2 then
            w_importo_rata_2 := rec_raim.importo_rata_num;
            BEGIN
              select to_char(scade.data_scadenza,'dd/mm/yyyy')
                into w_scadenza_rata_2
                from scadenze scade
               where scade.tipo_tributo = 'TOSAP'
                 and scade.anno = a_anno
                 and scade.rata = 2
                   ;
            EXCEPTION
            WHEN others THEN
               w_errore := ('Errore nella ricerca della scadenza della seconda rata' || ' (' || SQLERRM || ')' );
               raise errore;
            END;
            --Inserimento dei dati sulla rata 2
            w_vcampo2 := to_char(a_anno) || '2' || lpad(rec_cont.ni,8,'0') || '001;';
            w_riga_rata := w_riga_rata || ';' || w_vcampo2 || w_importo_rata_2 || ';' || w_scadenza_rata_2;
         end if;
         if rec_raim.numero_rata = 3 then
            w_importo_rata_3 := rec_raim.importo_rata_num;
            BEGIN
               select to_char(scade.data_scadenza,'dd/mm/yyyy')
                 into w_scadenza_rata_3
                 from scadenze scade
                where scade.tipo_tributo = 'TOSAP'
                  and scade.anno = a_anno
                  and scade.rata = 3
                    ;
            EXCEPTION
            WHEN others THEN
               w_errore := ('Errore nella ricerca della scadenza della terza rata' || ' (' || SQLERRM || ')' );
               raise errore;
            END;
            --Inserimento dei dati sulla rata 3
            w_vcampo3 := to_char(a_anno) || '3' || lpad(rec_cont.ni,8,'0') || '001;';
            w_riga_rata := w_riga_rata || ';' || w_vcampo3 || w_importo_rata_3 || ';' || w_scadenza_rata_3;
         end if;
         if rec_raim.numero_rata = 4 then
            w_importo_rata_4 := rec_raim.importo_rata_num;
            BEGIN
               select to_char(scade.data_scadenza,'dd/mm/yyyy')
                 into w_scadenza_rata_4
                 from scadenze scade
                where scade.tipo_tributo = 'TOSAP'
                  and scade.anno = a_anno
                  and scade.rata = 4
                    ;
            EXCEPTION
            WHEN others THEN
               w_errore := ('Errore nella ricerca della scadenza della quarta rata' || ' (' || SQLERRM || ')' );
               raise errore;
            END;
            --Inserimento dei dati sulla rata 4
            w_vcampo4 := to_char(a_anno) || '4' || lpad(rec_cont.ni,8,'0') || '001;';
            w_riga_rata := w_riga_rata || ';' || w_vcampo4 || w_importo_rata_4 || ';' || w_scadenza_rata_4;
         end if;
      END LOOP; --rec_raim
      -- Inserimento Causale rate
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
      FOR rec_ogim in sel_ogim(a_anno, rec_cont.cod_fiscale, w_istat, w_tributo) --OGIM
      LOOP
         w_conta_utenze := w_conta_utenze + 1;
         w_utenze_contribuente := w_utenze_contribuente + 1;
         if (w_max_rate = 0) or (w_max_rate = 2) or (w_max_rate = 4) then
            if w_utenze_contribuente <= w_num_max_utenze then
               w_riga_wrk := w_riga_wrk || rec_ogim.note;
            else
               w_riga_suppl := w_riga_suppl||rec_ogim.note;
            end if;
         end if;
      END LOOP; --sel_ogim
      -- Inserimento dei (;) per avere lo stesso numero di note per tutti i contribuenti
      if (w_max_rate = 0) or (w_max_rate = 2) or (w_max_rate = 4) then
         WHILE w_utenze_contribuente < w_num_max_utenze --w_max_progr_ubicazione
         LOOP
           w_riga_wrk := w_riga_wrk||';';
           w_utenze_contribuente:= w_utenze_contribuente +1;
         END LOOP;
      end if;
      --Importo e scadenza rata 0
      w_importo_rata_0 := rec_cont.imposta_contribuente;
      --Inserimento dei dati sull'imposta totale (o rata 0)
      w_vcampot := to_char(a_anno) || '0' || lpad(rec_cont.ni,8,'0') || '001;';
      IF w_flag_canone = 'N' THEN
         w_riga_wrk := w_riga_wrk || w_vcampot || round(w_importo_rata_0,0) || ';' || w_scadenza_rata_0;
      ELSE
          w_riga_wrk := w_riga_wrk || w_vcampot || w_importo_rata_0 || ';' || w_scadenza_rata_0;
      END IF;
      r := 0;
      if w_riga_rata is null then
         WHILE r < w_max_rate
         loop
            w_riga_rata := w_riga_rata||';';
            r := r + 1;
         end loop;
      end if;
      w_riga_wrk := w_riga_wrk || w_riga_rata;
      if w_riga_suppl is not null then
         w_riga_wrk := w_riga_wrk || ';' || w_riga_suppl;
      end if;
      w_progr_wrk := w_progr_wrk + 1; --Conta anche il numero dei contribuenti trattati +1
      --
      -- (VD  - 28/08/2017): si suddivide la riga in parti di 4000 crt,
      --                     per consentire la gestione delle righe più'
      --                     lunghe di 4000
      --
      w_dati := substr(w_riga_wrk,1,4000);
      w_dati2 := substr(w_riga_wrk,4001,4000);
      w_dati3 := substr(w_riga_wrk,8001,4000);
      w_dati4 := substr(w_riga_wrk,12001,4000);
      w_dati5 := substr(w_riga_wrk,16001,4000);
      w_dati6 := substr(w_riga_wrk,20001,4000);
      w_dati7 := substr(w_riga_wrk,24001,4000);
      w_dati8 := substr(w_riga_wrk,28001,4000);
      BEGIN
         insert into wrk_trasmissioni(numero
                                    , dati
                                    , dati2
                                    , dati3
                                    , dati4
                                    , dati5
                                    , dati6
                                    , dati7
                                    , dati8)
         values (lpad(w_progr_wrk,15,'0')
               , w_dati
               , w_dati2
               , w_dati3
               , w_dati4
               , w_dati5
               , w_dati6
               , w_dati7
               , w_dati8);
      EXCEPTION
         WHEN others THEN
            w_errore := ('Errore in inserimento wrk_trasmissione' || ' (' || SQLERRM || ')' );
            raise errore;
      END;
      w_importo_totale_complessivo := w_importo_totale_complessivo + w_importo_rata_0;
      w_importo_totale_arrotondato := w_importo_totale_arrotondato + round(w_importo_rata_0,0);
   END LOOP; --sel_cont
   w_errore := ' Fine ';
   BEGIN
      w_err_par := 'cont_da_trattare';
      insert into parametri(sessione
                          , nome_parametro
                          , progressivo
                          , valore)
           values (a_sessione
                 , 'cont_da_trattare'
                 , 666
                 , w_cont_da_trattare)
                 ;
      w_err_par := 'numero_contribuenti';
      insert into parametri(sessione
                          , nome_parametro
                          , progressivo
                          , valore)
           values (a_sessione
                 , 'numero_contribuenti'
                 , 666
                 , to_number(w_progr_wrk)-1)
                 ;
      w_err_par := 'numero_utenze';
      insert into parametri(sessione
                          , nome_parametro
                          , progressivo
                          , valore)
           values (a_sessione
                 , 'numero_utenze'
                 , 666
                 , w_conta_utenze)
                 ;
      w_err_par := 'totale_versato';
      insert into parametri(sessione
                          , nome_parametro
                          , progressivo
                          , valore)
           values (a_sessione
                 , 'totale_versato'
                 , 666
                 , w_importo_totale_complessivo)
                 ;
      w_err_par := 'totale_versato_arrotondato';
      insert into parametri(sessione
                          , nome_parametro
                          , progressivo
                          , valore)
           values (a_sessione
                 , 'totale_versato_arrotondato'
                 , 666
                 , w_importo_totale_arrotondato)
                 ;
   EXCEPTION
   WHEN others THEN
         w_errore := ('Errore in inserimento Parametri - ' || w_err_par || ' (' || SQLERRM || ')' );
         raise errore;
   END;
   --dbms_output.put_line('Totale contribuenti trattati: ' || w_progr_wrk);
   --dbms_output.put_line('Importo totale: ' || w_importo_totale_complessivo);
   --dbms_output.put_line('Importo totale arrotondato: ' || w_importo_totale_arrotondato);
EXCEPTION
  WHEN errore THEN
       ROLLBACK;
       RAISE_APPLICATION_ERROR(-20999, w_errore);
  WHEN others THEN
       ROLLBACK;
       RAISE_APPLICATION_ERROR (-20999, 'Errore in estrazione_cosap_poste ' || '('||SQLERRM||')');
END;
/* End Procedure: ESTRAZIONE_COSAP_POSTE */
/

