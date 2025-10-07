--liquibase formatted sql 
--changeset abrandolini:20250326_152423_estrazione_acc_tarsu_auto stripComments:false runOnChange:true 
 
create or replace procedure ESTRAZIONE_ACC_TARSU_AUTO
/*************************************************************************
 NOME:        ESTRAZIONE_ACC_TARSU_AUTO
 DESCRIZIONE: Estrazione per stampa accertamenti e F24 TARI
              Comune di Pontassieve
 NOTE:
 Rev.    Date         Author      Note
 007     06/02/2025   RV          #77116
                                  Flag sanz_min_rid da pratica non da inpa
 006     20/11/2023   RV          #65966
                                  Aggiunto gestione sanzione minima su riduzione
 005     22/10/2018   VD          Rimodificato test su tipologie sanzioni:
                                  ora si trattano solo quelle relative
                                  all'imposta evasa (per evitare di calcolare
                                  le addizionali anche su tutte le sanzioni).
 004     14/06/2018   VD          Corretta gestione deceduti: ora si
                                  controlla lo stato della tabella
                                  SOGGETTI (= 50).
 003     24/04/2018   VD          Aggiunto parametro per selezionare
                                  contribuenti:
                                  D - Deceduti
                                  N - Non deceduti
                                  T - Tutti.
                                  Modificato test su tipologie sanzioni:
                                  ora vengono considerate tutti i tipi
                                  sanzione presenti.
 002     21/09/2017   VD          Corretto lancio funzione F_RECAPITO
                                  per estrazione stringa comune indirizzo
                                  (cap + comune + siglia provincia)
                                  Parametro tipo campo = 'CC' (e non 'S')
 001     18/09/2017   VD          Aggiunto parametro per stampare
                                  riepilogo somme da versare (Pioltello)
 000     27/01/2016   VD          Prima emissione.
*************************************************************************/
( p_anno_iniz               number
, p_anno_fine               number
, p_data_iniz               date
, p_data_fine               date
, p_numero_iniz             varchar2
, p_numero_fine             varchar2
, p_tipo_stato              varchar2
, p_flag_importo_ridotto    varchar2
, p_flag_deceduti           varchar2
, p_num_modello             number
, p_riep_f24                varchar2
, p_num_protocollo          varchar2
, p_data_protocollo         date
, p_num_contribuenti        in out number
, p_num_atti                in out number
, p_num_colonne             in out number)
is
  w_tipo_tributo      varchar2(5) := 'TARSU';
  w_num_contribuenti  number := 0;
  w_num_colonne       number := 0;
  w_max_colonna       number := 0;
  w_conta_campi       number := 0;
  w_cf_prec           varchar2(16) := '*';
  w_cod_comune        varchar2(4);
  w_flag_tariffa      varchar2(1);
  w_conta_righe       number := 1;
  w_riga              varchar2(32000);
  w_errore            varchar2(4000);
  errore              exception;
  w_num_campo         number;
  w_num_campi         number;
  w_ind_totale        number;
  w_prima_riga        varchar2(1);
  w_flag_totali       varchar2(1);
  w_conta_righe_f24   number;
  w_tot_imposta       number;
  w_tot_magg_tares    number;
  w_tot_imposta_vers  number;
  w_tot_mtares_vers   number;
  w_diff_imposta      number;
  w_diff_mtares       number;
  w_tot_imposta_acc   number;
  w_tot_mtares_acc    number;
  w_tot_imposta_sanz  number;
  w_tot_mtares_sanz   number;
  w_tot_f24_importo   number;
  w_tot_f24_imp_rid   number;
  TYPE VettoreRighe   IS TABLE OF VARCHAR2(32767)
  INDEX BY BINARY_INTEGER;
  Riga_file           VettoreRighe;
  w_ind               number;
  w_i                 number;
  w_num_campi_dett    number;
  w_inizio_dett       number;
  w_fine_dett         number;
  w_riga1             varchar2(4000);
  w_riga2             varchar2(4000);
  w_riga3             varchar2(4000);
  w_riga4             varchar2(4000);
  w_riga5             varchar2(4000);
  w_riga6             varchar2(4000);
  w_riga7             varchar2(4000);
  w_riga8             varchar2(4000);
--
-- Variabili per parametri modello
--
  w_para_inte              varchar2(90);
  w_para_acc_elenco        varchar2(2);
  w_para_dic_acc_imp_dov   varchar2(16);
  w_para_dett_vers         varchar2(90);
  w_para_diff_imposta      varchar2(79);
  w_para_tot_dett_vers     varchar2(79);
  w_para_tot_imposta       varchar2(79);
  w_para_tot_vers          varchar2(79);
  w_para_riepilogo         varchar2(90);
  w_para_tot_magg_tares_v  varchar2(79);
  w_para_tot_dett_mtares   varchar2(90);
  w_para_tot_magg_tares    varchar2(79);
  w_para_tot_imp_comp      varchar2(79);
  w_para_diff_mtares       varchar2(79);
  w_para_acc_imp           varchar2(90);
  w_para_tot_acc_imp       varchar2(49);
  w_para_tot_acc_mag       varchar2(49);
  w_para_vis_cod_trib      varchar2(2);
  w_para_irr_sanz_int      varchar2(90);
  w_para_irr_tot_sanz      varchar2(49);
  w_para_irr_tot_magg      varchar2(49);
  w_para_rie_som_dov       varchar2(90);
  w_para_totaccimp         varchar2(79);
  w_para_totaccmag         varchar2(79);
  w_para_totsanz           varchar2(79);
  w_para_totsanzmag        varchar2(79);
  w_para_vis_tot_arr       varchar2(2);
  w_para_tot               varchar2(73);
  w_para_totale_arr        varchar2(73);
  w_para_totale_ad         varchar2(72);
  w_para_totale_ad_arr     varchar2(72);
  w_para_f24_int           varchar2(79);
  w_para_f24_tot           varchar2(79);
--
begin
--
-- Eliminazione dati tabella di servizio
--
  begin
    delete wrk_trasmissioni;
  exception
    when others then
      raise_application_error(-20999,'Errore in pulizia tabella di lavoro '||
                                     ' ('||sqlerrm||')');
  end;
  --
  -- Controllo parametri
  --
  if p_flag_deceduti not in ('D','N','T') then
     w_errore := 'Valore non previsto in trattamento deceduti: '||chr(10)||
                 'indicare D - Deceduti, N - Non deceduti, T - Tutti';
     raise errore;
  end if;
  --
  -- Selezione codice Belfiore del comune
  --
  begin
    select sigla_cfis
      into w_cod_comune
      from dati_generali dage
         , ad4_comuni    comu
     where dage.pro_cliente = comu.provincia_stato
       and dage.com_cliente = comu.comune;
  exception
    when others then
      raise_application_error(-20999,'Errore in selezione dati ente '||
                                     ' ('||sqlerrm||')');
  end;
  --
  -- Selezione flag tariffa per TARSU
  --
  begin
    select flag_tariffa
      into w_flag_tariffa
      from TIPI_TRIBUTO
     where tipo_tributo = w_tipo_tributo;
  exception
    when others then
      raise_application_error(-20999,'Errore in selezione dati tipo tributo TARSU '||
                                     ' ('||sqlerrm||')');
  end;
  --
  -- Selezione parametri modello
  --
  begin
    select rtrim(f_descrizione_timp(p_num_modello,'INTE'))
         , rtrim(f_descrizione_timp(p_num_modello,'ACC_ELENCO'))
         , rtrim(f_descrizione_timp(p_num_modello,'DIC ACC IMP DOV'))
         , rtrim(f_descrizione_timp(p_num_modello,'DETT_VERS'))
         , f_descrizione_timp(p_num_modello,'DIFF_PRT')
         , rtrim(f_descrizione_timp(p_num_modello,'TOT_DETT_VERS_PRT'))
         , f_descrizione_timp(p_num_modello,'TOT_IMP_PRT')
         , f_descrizione_timp(p_num_modello,'TOT_VERS_RIEP_PRT')
         , rtrim(f_descrizione_timp(p_num_modello,'RIEP_DETT_PRT'))
         , decode(sign(length('TOTALE MAGGIORAZIONE TARES') - nvl(length(f_descrizione_timp(p_num_modello,'TOT_IMP_PRT')),0))
                 ,1,'TOTALE MAGGIORAZIONE TARES'
                   ,rpad('TOTALE MAGGIORAZIONE TARES', length(nvl(f_descrizione_timp(p_num_modello,'TOT_IMP_PRT'),0))))
         , 'TOTALE MAGGIORAZIONE TARES'
         , 'TOTALE MAGG. TARES VERSATA'
         , f_descrizione_timp(p_num_modello,'TOT_IMP_COMP')
         , 'TOTALE DIFF. MAGG. TARES'
         , rtrim(f_descrizione_timp(p_num_modello,'ACC_IMP'))
         , rtrim(f_descrizione_timp(p_num_modello,'TOT_ACC_IMP'))
         , f_descrizione_timp(p_num_modello,'TOT_ACC_MAG')
         , f_descrizione_timp(p_num_modello,'VIS_COD_TRIB')
         , rtrim(f_descrizione_timp(p_num_modello,'IRR_SANZ_INT'))
         , f_descrizione_timp(p_num_modello,'IRR SAN INT TOT SANZ')
         , f_descrizione_timp(p_num_modello,'IRR SAN INT TOT MAGG')
         , rtrim(f_descrizione_timp(p_num_modello,'RIE_SOM_DOV'))
         , f_descrizione_timp(p_num_modello,'TOTACCIMP')
         , f_descrizione_timp(p_num_modello,'TOTACCMAG')
         , f_descrizione_timp(p_num_modello,'TOTSANZ')
         , f_descrizione_timp(p_num_modello,'TOTSANZMAG')
         , f_descrizione_timp(p_num_modello,'VIS_TOT_ARR')
         , f_descrizione_timp(p_num_modello,'TOT')
         , decode(w_flag_tariffa
                 ,null,decode(f_descrizione_timp(p_num_modello,'VIS_TOT_ARR')
                             ,'SI',f_descrizione_timp(p_num_modello,'TOT_ARR')
                                  ,null
                             )
                      ,null
                 )
         , f_descrizione_timp(p_num_modello, 'TOT_AD')
         , decode(w_flag_tariffa
                 ,null,decode(f_descrizione_timp(p_num_modello,'VIS_TOT_ARR')
                             ,'SI',f_descrizione_timp(p_num_modello,'TOT_AD_ARR')
                                  ,null
                             )
                      ,null
                 )
         , rtrim(f_descrizione_timp(p_num_modello,'F24_INT'))
         , rtrim(f_descrizione_timp(p_num_modello,'F24_TOT'))
      into w_para_inte
         , w_para_acc_elenco
         , w_para_dic_acc_imp_dov
         , w_para_dett_vers
         , w_para_diff_imposta
         , w_para_tot_dett_vers
         , w_para_tot_imposta
         , w_para_tot_vers
         , w_para_riepilogo
         , w_para_tot_dett_mtares
         , w_para_tot_magg_tares
         , w_para_tot_magg_tares_v
         , w_para_tot_imp_comp
         , w_para_diff_mtares
         , w_para_acc_imp
         , w_para_tot_acc_imp
         , w_para_tot_acc_mag
         , w_para_vis_cod_trib
         , w_para_irr_sanz_int
         , w_para_irr_tot_sanz
         , w_para_irr_tot_magg
         , w_para_rie_som_dov
         , w_para_totaccimp
         , w_para_totaccmag
         , w_para_totsanz
         , w_para_totsanzmag
         , w_para_vis_tot_arr
         , w_para_tot
         , w_para_totale_arr
         , w_para_totale_ad
         , w_para_totale_ad_arr
         , w_para_f24_int
         , w_para_f24_tot
      from dual;
  exception
    when others then
      raise_application_error(-20999,'Verificare parametri modello ('||sqlerrm||')');
  end;
--
-- Trattamento pratiche di accertamento
--
  for acc in (select cont.cod_fiscale
                   , sogg.cognome
                   , sogg.nome
                   , sogg.data_nas
                   , translate(sogg.cognome_nome,'/', ' ') cognome_nome
                   , sogg.sesso                            sesso
                   , com_nas.denominazione                 comune_nas
                   , pro_nas.sigla                         provincia_nas
                   , decode(sogg.ni_presso
                           ,null,f_recapito(sogg.ni,prtr.tipo_tributo,1,prtr.data,'PR')
                                ,'Presso: '||translate(sogg_p.cognome_nome,'/',' ')) presso
                   , decode(sogg.ni_presso
                           ,null,nvl(f_recapito(sogg.ni, prtr.tipo_tributo, 1, prtr.data)
                                    ,decode(sogg.cod_via,null,sogg.denominazione_via,arvi.denom_uff)
                                            ||decode(sogg.num_civ,null,'',', '||to_char(sogg.num_civ))
                                            ||decode(SOGG.suffisso,null,'', '/'||sogg.suffisso)
                                            ||decode(sogg.scala, NULL, '', ' Sc.'||sogg.scala)
                                            ||decode(sogg.piano, NULL, '', ' P.'||sogg.piano)
                                            ||decode(sogg.interno, NULL, '',  ' Int.'||sogg.interno))
                                    ,decode(sogg_p.cod_via,null,sogg_p.denominazione_via,arvi_p.denom_uff)
                                            ||decode(sogg_p.num_civ,null,'',', '||to_char(sogg_p.num_civ))
                                            ||decode(sogg_p.suffisso,null,'', '/'||sogg_p.suffisso)
                                            ||decode(sogg_p.scala, NULL, '', ' Sc.'||sogg_p.scala)
                                            ||decode(sogg_p.piano, NULL, '', ' P.'||sogg_p.piano)
                                            ||decode(sogg_p.interno, NULL, '',  ' Int.'||sogg_p.interno)
                           ) indirizzo
                   , decode(sogg.ni_presso
                           ,null,nvl(f_recapito(sogg.ni, prtr.tipo_tributo, 1, prtr.data,'CC')
                                    ,decode(nvl(sogg.cap,comu.cap)
                                           ,'99999',''
                                           ,nvl(sogg.zipcode,lpad(nvl(sogg.cap,comu.cap),5,'0'))||' '
                                           )
                                     ||comu.denominazione
                                     ||decode(sign(200-sogg.cod_pro_res)
                                             ,1,decode(prov.sigla,null,'',' (' ||prov.sigla|| ')')
                                             ,decode(stte.denominazione
                                                    ,null,''
                                                    ,comu.denominazione,''
                                                    ,' (' ||stte.denominazione || ')'
                                                    )
                                             ))
                           ,decode(nvl(sogg_p.zipcode,nvl(sogg_p.cap,comu_p.cap))
                                  ,'9999',''
                                  ,nvl(sogg_p.zipcode,lpad(nvl(sogg_p.cap,comu_p.cap),5,'0'))||' '
                                  )
                            ||comu_p.denominazione
                            ||decode(sign(200-sogg_p.cod_pro_res)
                                    ,1,decode(prov_p.sigla
                                             ,null,''
                                             ,' (' ||prov_p.sigla|| ')'
                                             )
                                    ,decode(stte_p.denominazione
                                           ,null,''
                                           ,comu_p.denominazione,''
                                           ,' (' ||stte_p.denominazione|| ')'
                                           )
                                    )
                           ) comune
                   , TRANSLATE (sogg_erso.cognome_nome, '/', ' ') cognome_nome_erede
                   , sogg_erso.cod_fiscale cod_fiscale_erede
                   , DECODE (sogg_erso.cod_via
                           , NULL, sogg_erso.denominazione_via
                           , arvi_erso.denom_uff)
                     || DECODE (sogg_erso.num_civ, NULL, '', ', ' || sogg_erso.num_civ)
                     || DECODE (sogg_erso.suffisso, NULL, '', '/' || sogg_erso.suffisso)
                        indirizzo_erede
                   ,    LPAD (com_erso.CAP, 5, '0')
                     || ' '
                     || com_erso.denominazione
                     || DECODE (pro_erso.SIGLA, NULL, '', ' (' || pro_erso.sigla || ')')
                        comune_erede
                   , prtr.pratica
                   , prtr.tipo_tributo
                   , prtr.tipo_pratica
                   , prtr.tipo_evento
                   , prtr.anno
                   , prtr.numero
                   , to_char(prtr.data,'dd/mm/yyyy') data_pratica
                   , prtr.note note_pratica
                   , prtr.motivo motivo_pratica
                   , decode(nvl(cata.maggiorazione_tares,0),0,'N','S') flag_magg_tares
                   , prtr.importo_totale + nvl(addiz.tot_add,0) importo_totale
                   , decode(w_para_vis_tot_arr
                           ,'SI',decode(w_flag_tariffa
                                       ,null,round(prtr.importo_totale + nvl(addiz.tot_add,0)
                                                  ,0
                                                  )
                                       ,to_number(null)
                                       )
                           ,to_number(null)) importo_totale_arrotondato
                   , decode(prtr.importo_ridotto
                           ,prtr.importo_totale,to_number(null)
                                               ,f_round(prtr.importo_ridotto + nvl(addiz.tot_add,0)
                                                       ,1
                                                       )
                           ) importo_ridotto
                   , decode(w_para_vis_tot_arr
                           ,'SI',decode(prtr.importo_ridotto
                                       ,prtr.importo_totale,to_number(null)
                                                           ,decode(w_flag_tariffa
                                                                  ,null,round(prtr.importo_ridotto
                                                                              + nvl(addiz.tot_add,0)
                                                                             ,0
                                                                             )
                                                                       ,null
                                                                  )
                                       )
                           ,null
                           ) importo_ridotto_arrotondato
                   , prtr.flag_sanz_min_rid
                from soggetti            sogg
                   , soggetti            sogg_p
                   , archivio_vie        arvi
                   , archivio_vie        arvi_p
                   , ad4_provincie       prov
                   , ad4_provincie       prov_p
                   , ad4_comuni          comu
                   , ad4_comuni          comu_p
                   , ad4_comuni          com_nas
                   , ad4_provincie       pro_nas
                   , ad4_stati_territori stte
                   , ad4_stati_territori stte_p
                   , soggetti            sogg_erso
                   , ad4_comuni          com_erso
                   , ad4_provincie       pro_erso
                   , archivio_vie        arvi_erso
                   , contribuenti        cont
                   , pratiche_tributo    prtr
                   , carichi_tarsu       cata
                   , (select prtr_add.pratica pratica
                           , nvl(sum(f_cata(cata.anno,1,nvl(sapr.importo,sanzioni.sanzione),'T')
                                    )
                                ,0
                                ) tot_add
                          from carichi_tarsu cata
                              ,sanzioni_pratica sapr
                              ,sanzioni
                              ,pratiche_tributo prtr_add
                         where cata.anno = prtr_add.anno
                           and sanzioni.tipo_tributo = w_tipo_tributo
                           --
                           -- (VD - 24/04/2018): eliminato test su tipi sanzione
                           --
                           -- (VD - 22/10/2018): riattivato test su tipi sanzione
                           -- per evitare di calcolare le addizionali anche su
                           -- tutte le sanzioni inserite
                           and (sanzioni.cod_sanzione in (1, 100, 101)
                                or sanzioni.tipo_causale||nvl(sanzioni.flag_magg_tares,'N') = 'EN')
                           and sanzioni.cod_sanzione not in (888,889)
                           and sanzioni.cod_sanzione = sapr.cod_sanzione
                           and sanzioni.sequenza = sapr.sequenza_sanz
                           and sapr.pratica = prtr_add.pratica
                           and nvl(prtr_add.stato_accertamento,'D') = nvl(p_tipo_stato,nvl(prtr_add.stato_accertamento,'D'))
                           and prtr_add.anno between nvl(p_anno_iniz,0) and nvl(p_anno_fine,9999)
                           and prtr_add.data between nvl(p_data_iniz,to_date('01011980','ddmmyyyy'))
                                                 and nvl(p_data_fine,to_date('31122200','ddmmyyyy'))
                           and lpad(nvl(prtr_add.numero,' '),15) between lpad(nvl(p_numero_iniz,' '),15)
                                                                     and lpad(nvl(p_numero_fine,'ZZZZZZZZZZZZZZZ'),15)
                       group by prtr_add.pratica) addiz
               where sogg.ni                          = cont.ni
                 and sogg.cod_via                     = arvi.cod_via (+)
                 and sogg_p.cod_via                   = arvi_p.cod_via (+)
                 and sogg_p.ni (+)                    = sogg.ni_presso
                 and sogg.cod_pro_res                 = stte.stato_territorio (+)
                 and sogg.cod_pro_res                 = comu.provincia_stato (+)
                 and sogg.cod_com_res                 = comu.comune (+)
                 and sogg_p.cod_pro_res               = stte_p.stato_territorio (+)
                 and sogg_p.cod_pro_res               = comu_p.provincia_stato (+)
                 and sogg_p.cod_com_res               = comu_p.comune (+)
                 and sogg.cod_pro_nas                 = com_nas.provincia_stato (+)
                 and sogg.cod_com_nas                 = com_nas.comune (+)
                 and comu.provincia_stato             = prov.provincia (+)
                 and comu_p.provincia_stato           = prov_p.provincia (+)
                 and com_nas.provincia_stato          = pro_nas.provincia (+)
                 and f_primo_erede_ni (sogg.ni)       = sogg_erso.ni(+)
                 and com_erso.provincia_stato         = pro_erso.provincia(+)
                 and sogg_erso.cod_pro_res            = com_erso.provincia_stato(+)
                 and sogg_erso.cod_com_res            = com_erso.comune(+)
                 and sogg_erso.cod_via                = arvi_erso.cod_via(+)
                 --
                 -- (VD - 20/04/2018): aggiunta selezione per tipo contribuente
                 --                    (deceduti, non deceduti, tutti)
                 --
                 and (p_flag_deceduti = 'T' or
--                     (p_flag_deceduti = 'D' and f_primo_erede_ni (sogg.ni) is not null) or
                 -- (VD - 14/06/2018): corretto test per selezionare contribuenti deceduti
                     (p_flag_deceduti = 'D' and nvl(sogg.stato,-1) = 50) or -- L'ha detto Monopoli di testare lo stato 50
--                     (p_flag_deceduti = 'N' and f_primo_erede_ni (sogg.ni) is null))
                 -- (VD - 14/06/2018): corretto test per selezionare contribuenti non deceduti
                     (p_flag_deceduti = 'N' and nvl(sogg.stato,-1) <> 50))
                 and cont.cod_fiscale                 = prtr.cod_fiscale
                 and prtr.pratica                     = addiz.pratica
                 and prtr.tipo_tributo                = w_tipo_tributo
                 and prtr.anno                        = cata.anno
                 and prtr.tipo_pratica                = 'A'
                 and prtr.tipo_evento                 = 'A'
                 and (prtr.importo_totale + nvl(addiz.tot_add,0)) > 0
                 and prtr.numero                      is not null
                 and prtr.data_notifica               is null
                 and nvl(prtr.stato_accertamento,'D') = nvl(p_tipo_stato,nvl(prtr.stato_accertamento,'D'))
                 and prtr.anno between nvl(p_anno_iniz,0) and nvl(p_anno_fine,9999)
                 and prtr.data between nvl(p_data_iniz,to_date('01011980','ddmmyyyy'))
                                   and nvl(p_data_fine,to_date('31122200','ddmmyyyy'))
                 and lpad(nvl(prtr.numero,' '),15) between lpad(nvl(p_numero_iniz,' '),15)
                                                       and lpad(nvl(p_numero_fine,'ZZZZZZZZZZZZZZZ'),15)
            order by 2,3)         -- cognome e nome
  loop
    --
    -- Conteggio contribuenti
    --
    if acc.cod_fiscale <> w_cf_prec then
       w_cf_prec := acc.cod_fiscale;
       w_num_contribuenti := w_num_contribuenti + 1;
    end if;
    --
    w_conta_righe := w_conta_righe + 1;
    w_ind         := 0;
    riga_file.delete;
    --
    -- Stampa F24 - Intestazione
    --
    w_num_campi := 9;
    for w_num_campo in 1 .. w_num_campi
    loop
      w_ind := w_ind + 1;
      if w_num_campo = 1 then
         riga_file (w_ind) := acc.cod_fiscale;
      elsif w_num_campo = 2 then
         riga_file (w_ind) := acc.cognome;
      elsif w_num_campo = 3 then
         riga_file (w_ind) := acc.nome;
      elsif w_num_campo = 4 then
         riga_file (w_ind) := to_char(acc.data_nas,'ddmmyyyy');
      elsif w_num_campo = 5 then
         riga_file (w_ind) := acc.sesso;
      elsif w_num_campo = 6 then
         riga_file (w_ind) := acc.comune_nas;
      elsif w_num_campo = 7 then
         riga_file (w_ind) := acc.provincia_nas;
      elsif w_num_campo = 8 then
         riga_file (w_ind) := acc.cod_fiscale_erede;
      elsif w_num_campo = 9 then
         riga_file (w_ind) := 'ACC'||acc.tipo_evento||acc.anno||lpad(to_char(acc.pratica),10,'0');
      end if;
    end loop;
        if acc.pratica = 326451 then
      dbms_output.put_line('Fine intesta f24: '||w_ind);
        end if;
    --
    -- Stampa F24 - Righe dettaglio
    --
    w_tot_f24_importo := 0;
    w_ind_totale      := 0;
    w_conta_righe_f24 := 0;
    w_num_campi       := 7;
    for dett in (select nvl(sanz.cod_tributo_f24,decode(sanz.flag_magg_tares,'S','3955','3944')) cod_tributo
                      , round(sum(decode(sanz.cod_tributo_f24
                                  ,null,decode(sanz.flag_magg_tares
                                              ,'S',0
                                                  ,F_IMPORTO_F24_VIOL(sapr.importo,sapr.riduzione
                                                                     ,p_flag_importo_ridotto,acc.tipo_tributo
                                                                     ,acc.anno,sanz.tipo_causale,sanz.flag_magg_tares
                                                                     ,(case when acc.flag_sanz_min_rid = 'S'
                                                                            then sanz.sanzione_minima else null end)
                                                                     )
                                              )
                                       ,F_IMPORTO_F24_VIOL(sapr.importo,sapr.riduzione
                                                          ,p_flag_importo_ridotto,acc.tipo_tributo
                                                          ,acc.anno,sanz.tipo_causale,sanz.flag_magg_tares
                                                          ,(case when acc.flag_sanz_min_rid = 'S'
                                                                then sanz.sanzione_minima else null end)
                                                          )
                                  ))
                             ,0) importo
                   from sanzioni_pratica   sapr
                      , sanzioni           sanz
                  where sapr.pratica = acc.pratica
                    and sapr.cod_sanzione = sanz.cod_sanzione
                    and sapr.sequenza_sanz = sanz.sequenza
                    and sapr.tipo_tributo = sanz.tipo_tributo
               group by nvl(sanz.cod_tributo_f24,decode(sanz.flag_magg_tares,'S','3955','3944'))
                 having round(sum(decode(sanz.cod_tributo_f24
                                        ,null,decode(sanz.flag_magg_tares
                                                    ,'S',0
                                                        ,F_IMPORTO_F24_VIOL(sapr.importo,sapr.riduzione
                                                                           ,p_flag_importo_ridotto,acc.tipo_tributo
                                                                           ,acc.anno,sanz.tipo_causale,sanz.flag_magg_tares
                                                                           ,(case when acc.flag_sanz_min_rid = 'S'
                                                                                  then sanz.sanzione_minima else null end)
                                                                           )
                                                    )
                                             ,F_IMPORTO_F24_VIOL(sapr.importo,sapr.riduzione
                                                                ,p_flag_importo_ridotto,acc.tipo_tributo
                                                                ,acc.anno,sanz.tipo_causale,sanz.flag_magg_tares
                                                                ,(case when acc.flag_sanz_min_rid = 'S'
                                                                      then sanz.sanzione_minima else null end)
                                                                )
                                        ))
                                 ,0) > 0)
    loop
      w_tot_f24_importo := w_tot_f24_importo + dett.importo;
      w_conta_righe_f24 := w_conta_righe_f24 + 1;
      --
      if w_conta_righe_f24 = 11 then
         w_ind := w_ind + 1;
         w_ind_totale := w_ind;
         riga_file (w_ind) := lpad(to_char(w_tot_f24_importo * 100),22);
      end if;
      --
      if w_conta_righe_f24 = 21 then
         w_ind := w_ind + 1;
         riga_file (w_ind) := lpad(to_char(dett.importo * 100),22);
         w_ind := w_ind + 1;
         riga_file (w_ind) := 'Pagine Modulo F24 insufficienti - Elenco incompleto';
         exit;
      end if;
      --
      for w_num_campo in 1..w_num_campi
      loop
        w_ind := w_ind + 1;
        if w_num_campo = 1 then
           riga_file (w_ind) := 'E';
        elsif w_num_campo = 2 then
           riga_file (w_ind) := 'L';
        elsif w_num_campo = 3 then
           riga_file (w_ind) := dett.cod_tributo;
        elsif w_num_campo = 4 then
           riga_file (w_ind) := w_cod_comune;
        elsif w_num_campo = 5 then
           riga_file (w_ind) := '0101';
        elsif w_num_campo = 6 then
           riga_file (w_ind) := acc.anno;
        elsif w_num_campo = 7 then
          riga_file (w_ind) := lpad(to_char(dett.importo * 100),22);
        end if;
      end loop;
    end loop;
    --
    -- Si prevedono 20 righe di dettaglio per un massimo di 2 pagine per modello
    --
    if w_conta_righe_f24 < 20 then
       w_conta_righe_f24 := w_conta_righe_f24 + 1;
       for indice in w_conta_righe_f24..20
       loop
         if indice = 11 then
            w_ind := w_ind + 1;
            w_ind_totale := w_ind;
            riga_file (w_ind) := lpad(to_char(w_tot_f24_importo * 100),22);
         end if;
         --
         for w_num_campo in 1..w_num_campi
         loop
           w_ind := w_ind + 1;
           riga_file (w_ind) := ' ';
         end loop;
       end loop;
    end if;
    --
    -- Se l'elenco dei codici tributo supera le 10 righe, si stampa il totale
    -- nella 21esima riga e si annulla quello stampato nell'11esima
    --
    if w_conta_righe_f24 > 11 then
       w_ind := w_ind + 1;
       riga_file (w_ind) := lpad(w_tot_f24_importo * 100,22);
       riga_file (w_ind_totale) := ' ';
    else
       w_ind := w_ind + 1;
       riga_file (w_ind) := ' ';
    end if;
            if acc.pratica = 326451 then
      dbms_output.put_line('Fine F24: '||w_ind);
        end if;
    --
    -- Composizione righe di intestazione avviso
    --
    w_num_campi   := 14;
    for w_num_campo in 1..w_num_campi
    loop
      w_ind := w_ind + 1;
      if w_num_campo = 1 then
         if p_num_protocollo is not null then
            riga_file (w_ind) := 'Prot. n. '||p_num_protocollo||rpad(' ',40 - length(p_num_protocollo))||'lì '||to_char(nvl(p_data_protocollo,sysdate),'dd/mm/yyyy');
         else
            riga_file (w_ind) := 'Prot. n. ______________                          lì '||to_char(nvl(p_data_protocollo,sysdate),'dd/mm/yyyy');
         end if;
      elsif w_num_campo = 2 then
         riga_file (w_ind) := acc.cognome_nome;
      elsif w_num_campo = 3 then
         if acc.presso is null then
            w_ind := w_ind - 1;
         else
            riga_file (w_ind) := acc.presso;
         end if;
      elsif w_num_campo = 4 then
         riga_file (w_ind) := acc.indirizzo;
      elsif w_num_campo = 5 then
         riga_file (w_ind) := acc.comune;
      elsif w_num_campo = 6 then
         if acc.presso is null then
            riga_file (w_ind) := ' ';
            w_ind := w_ind + 1;
         end if;
         riga_file (w_ind) := acc.cod_fiscale;
      elsif w_num_campo = 7 then
         riga_file (w_ind) := acc.cognome_nome_erede;
      elsif w_num_campo = 8 then
         riga_file (w_ind) := acc.indirizzo_erede;
      elsif w_num_campo = 9 then
         riga_file (w_ind) := acc.comune_erede;
      elsif w_num_campo = 10 then
         riga_file (w_ind) := acc.cod_fiscale_erede;
      elsif w_num_campo = 11 then
         if p_num_modello = 0 or
            w_para_inte = 'DEFAULT' then
            riga_file (w_ind) := lpad(' ',trunc((99 - length('Atto')) /2))||'Atto' ;
         else
            riga_file (w_ind) := w_para_inte;
         end if;
      elsif w_num_campo = 12 then
         if acc.numero is not null then
            w_riga := 'numero '||acc.numero||' del '||acc.data_pratica||' relativo all''anno '||acc.anno;
         else
            w_riga := 'del '||acc.data_pratica||' relativo all''anno '||acc.anno;
         end if;
         riga_file (w_ind) := lpad(' ',trunc((99 - length(w_riga)) / 2))||w_riga;
      elsif w_num_campo = 13 then
         w_riga := '(Identificativo Operazione ACC'||acc.tipo_evento||acc.anno||lpad(to_char(acc.pratica),10,'0')||')';
         riga_file (w_ind) := lpad(' ',trunc((99 - length(w_riga)) / 2))||w_riga;
      elsif w_num_campo = 14 then
         if acc.motivo_pratica is null then
            w_ind := w_ind - 1;
         else
            riga_file (w_ind) := acc.motivo_pratica;
         end if;
      end if;
    end loop;
        if acc.pratica = 326451 then
      dbms_output.put_line('Fine intesta avviso: '||w_ind);
        end if;
    --
    -- Trattamento oggetti accertamento
    --
    w_num_campi      := 17;
    w_tot_imposta    := 0;
    w_tot_magg_tares := 0;
    --
    for ogg in (select decode(sum(nvl(ogim_acc.addizionale_eca,0))
                             ,0,''
                               ,ltrim(translate(to_char(sum(nvl(ogim_acc.addizionale_eca,0))
                                                       ,'99,999,999,990.00'
                                                       )
                                               ,',.','.,'
                                               )
                                     )
                             ) imposta_dovuta_add_eca
                      ,decode(sum(nvl(ogim_acc.maggiorazione_eca,0))
                             ,0,''
                               ,ltrim(translate(to_char(sum(nvl(ogim_acc.maggiorazione_eca,0))
                                                       ,'99,999,999,990.00'
                                                       )
                                               ,',.','.,'
                                               )
                                     )
                             ) imposta_dovuta_mag_eca
                      ,decode(sum(nvl(ogim_acc.addizionale_pro,0))
                             ,0,''
                               ,ltrim(translate(to_char(sum(nvl(ogim_acc.addizionale_pro,0)
                                                           )
                                                       ,'99,999,999,990.00'
                                                       )
                                               ,',.','.,'
                                               )
                                     )
                             ) imposta_dovuta_add_pro
                      ,decode(sum(nvl(ogim_acc.iva,0))
                             ,0,''
                               ,ltrim(translate(to_char(sum(nvl(ogim_acc.iva,0))
                                                       ,'99,999,999,990.00'
                                                       )
                                               ,',.','.,'
                                               )
                                     )
                             ) imposta_dovuta_iva
                      ,prtr_acc.pratica pratica
                      ,nvl(cate.descrizione,' ') categoria_desc
                      ,lpad(nvl(to_char(ogim_acc.anno),' '),10) anno
                      ,lpad(nvl(prtr_acc.numero,' '),15,'0') prtr_numero
                      ,nvl(prtr_acc.numero,' ') prtr_numero_vis
                      ,prtr_acc.anno prtr_anno
                      ,decode(ogco_acc.inizio_occupazione
                             ,null,null
                                  ,'INIZIO OCCUPAZ. :'||to_char(ogco_acc.inizio_occupazione,'dd/mm/yyyy')) sinizio_occup
                      ,decode(ogco_acc.data_decorrenza
                             ,null,null
                                  ,to_char(ogco_acc.data_decorrenza,'dd/mm/yyyy')) data_decor
                      ,decode(ogco_acc.fine_occupazione
                             ,null,null
                                  ,to_char(ogco_acc.fine_occupazione,'dd/mm/yyyy')) fine_occup
                      ,nvl(to_char(prtr_acc.data,'dd/mm/yyyy'),' ') data_acc
                      ,decode(sum(nvl(ogim_acc.imposta,0))
                             ,0,''
                               ,ltrim(translate(to_char(f_round(sum(nvl(ogim_acc.imposta,0)
                                                                   )
                                                               ,1
                                                               )
                                                       ,'99,999,999,990.00'
                                                       )
                                               ,',.','.,'
                                               )
                                     )
                             ) imposta_acc
                      ,decode(sum(nvl(ogim_acc.imposta,0))
                             ,0,''
                               ,ltrim(translate(to_char(f_round(nvl(decode(decode(cotr.flag_ruolo
                                                                                 ,null,'N'
                                                                                      ,nvl(cata.flag_lordo,'N')
                                                                                 )
                                                                          ,'S',sum(nvl(ogim_acc.addizionale_eca,0)
                                                                                   + nvl(ogim_acc.maggiorazione_eca,0)
                                                                                   + nvl(ogim_acc.addizionale_pro,0)
                                                                                   + nvl(ogim_acc.iva,0)
                                                                                  )
                                                                              ,0
                                                                          )
                                                                    + sum(nvl(ogim_acc.imposta,0))
                                                                   ,0
                                                                   )
                                                               ,1
                                                               )
                                                       ,'99,999,999,990.00'
                                                       )
                                               ,',.','.,'
                                               )
                                     )
                             ) imposta_dovuta
                      ,f_round(nvl(decode(decode(cotr.flag_ruolo
                                                ,null,'N'
                                                     ,nvl(cata.flag_lordo,'N')
                                                )
                                         ,'S',sum(nvl(ogim_acc.addizionale_eca,0)
                                                  + nvl(ogim_acc.maggiorazione_eca,0)
                                                  + nvl(ogim_acc.addizionale_pro,0)
                                                  + nvl(ogim_acc.iva,0)
                                                 )
                                             ,0
                                         )
                                   + sum(nvl(ogim_acc.imposta,0))
                                  ,0
                                  )
                              ,1
                              ) imposta_dovuta_acc_no_visibile
                      ,rpad(nvl(ltrim(translate(to_char(tari.tariffa,'99,999,999,990.00000')
                                               ,',.','.,'
                                               )
                                     )
                               ,' '
                               )
                           ,36
                           ) tariffa
                      ,substr(nvl(tari.descrizione,' '),1,36) tariffa_desc
                      ,rpad(oggetti.partita,9) partita
                      ,rpad(oggetti.sezione,5) sezione
                      ,rpad(oggetti.foglio,7) foglio
                      ,rpad(oggetti.numero,7) numero
                      ,rpad(oggetti.subalterno,5) subalterno
                      ,rpad(oggetti.zona,5) zona
                      ,'Estremi Catasto: ' st_estremi_catasto
                      ,rpad(oggetti.protocollo_catasto,7) protocollo_catasto
                      ,rpad(to_char(oggetti.anno_catasto),5) anno_catasto
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
                      ,decode(oggetti.cod_via
                             ,null,oggetti.indirizzo_localita
                                  ,archivio_vie.denom_uff
                             )
                       ||decode(oggetti.num_civ,null,'',',' ||oggetti.num_civ)
                       ||decode(oggetti.suffisso,null,'','/' ||oggetti.suffisso) indirizzo_ogg
                      ,nvl(ltrim(translate(to_char(ogpr_acc.consistenza,'999,990.00')
                                          ,'.,',',.'
                                          )
                                )
                          ,' '
                          ) superficie
                      ,rpad(ltrim(translate(to_char(nvl(ogco_acc.perc_possesso,100)
                                                   ,'999,990.00'
                                                   )
                                           ,'.,',',.'
                                           )
                                 )
                           ,10
                           ) perc_possesso
                      ,oggetti.oggetto
                      ,decode(cate.flag_domestica
                             ,null,''
                                  ,decode(ogco_acc.flag_ab_principale,'S','SI','NO')
                             ) ab_principale
                      ,decode(ogpr_acc.tipo_occupazione,'P','Permanente','Temporanea') tipo_occupazione
                      ,decode(cata.maggiorazione_tares
                             ,null,''
                                  ,ltrim(translate(to_char(sum(nvl(ogim_acc.maggiorazione_tares,0)
                                                              )
                                                          ,'99,999,999,990.00'
                                                          )
                                                  ,'.,',',.'
                                                  )
                                        )
                             ) magg_tares
                      ,f_round(sum(nvl(ogim_acc.maggiorazione_tares,0)),1) magg_tares_acc_no_visibile
                      ,decode(cate.flag_domestica,null,'NON ','') ||'DOMESTICA' tipo_utenza
                      ,replace(f_get_dettagli_acc_tarsu_ogim(prtr_acc.pratica
                                                            ,ogim_acc.oggetto_imposta
                                                            )
                              ,'[a_capo','#') n_familiari
                      ,ogco_acc.data_decorrenza
                      ,ogim_acc.oggetto_imposta
                      -- (VD - 03/05/2019): nuovi campi per calcolo con tariffe
                      ,decode(sum(nvl(ogim_acc.addizionale_eca_base,0))
                             ,0,''
                               ,ltrim(translate(to_char(sum(nvl(ogim_acc.addizionale_eca_base,0))
                                                       ,'99,999,999,990.00'
                                                       )
                                               ,',.','.,'
                                               )
                                     )
                             ) imposta_add_eca_base
                      ,decode(sum(nvl(ogim_acc.maggiorazione_eca_base,0))
                             ,0,''
                               ,ltrim(translate(to_char(sum(nvl(ogim_acc.maggiorazione_eca_base,0))
                                                       ,'99,999,999,990.00'
                                                       )
                                               ,',.','.,'
                                               )
                                     )
                             ) imposta_mag_eca_base
                      ,decode(sum(nvl(ogim_acc.addizionale_pro_base,0))
                             ,0,''
                               ,ltrim(translate(to_char(sum(nvl(ogim_acc.addizionale_pro_base,0)
                                                           )
                                                       ,'99,999,999,990.00'
                                                       )
                                               ,',.','.,'
                                               )
                                     )
                             ) imposta_add_pro_base
                      ,decode(sum(nvl(ogim_acc.iva_base,0))
                             ,0,''
                               ,ltrim(translate(to_char(sum(nvl(ogim_acc.iva_base,0))
                                                       ,'99,999,999,990.00'
                                                       )
                                               ,',.','.,'
                                               )
                                     )
                             ) imposta_iva_base
                      ,decode(sum(nvl(ogim_acc.imposta_base,0))
                             ,0,''
                               ,ltrim(translate(to_char(f_round(sum(nvl(ogim_acc.imposta_base,0)
                                                                   )
                                                               ,1
                                                               )
                                                       ,'99,999,999,990.00'
                                                       )
                                               ,',.','.,'
                                               )
                                     )
                             ) imposta_base
                      ,decode(sum(nvl(ogim_acc.imposta_base,0))
                             ,0,''
                               ,ltrim(translate(to_char(f_round(nvl(decode(decode(cotr.flag_ruolo
                                                                                 ,null,'N'
                                                                                      ,nvl(cata.flag_lordo,'N')
                                                                                 )
                                                                          ,'S',sum(nvl(ogim_acc.addizionale_eca_base,0)
                                                                                   + nvl(ogim_acc.maggiorazione_eca_base,0)
                                                                                   + nvl(ogim_acc.addizionale_pro_base,0)
                                                                                   + nvl(ogim_acc.iva_base,0)
                                                                                  )
                                                                              ,0
                                                                          )
                                                                    + sum(nvl(ogim_acc.imposta_base,0))
                                                                   ,0
                                                                   )
                                                               ,1
                                                               )
                                                       ,'99,999,999,990.00'
                                                       )
                                               ,',.','.,'
                                               )
                                     )
                             ) imposta_lorda_base
                  from ARCHIVIO_VIE
                      ,DATI_GENERALI
                      ,OGGETTI
                      ,CATEGORIE cate
                      ,TARIFFE tari
                      ,OGGETTI_IMPOSTA ogim_acc
                      ,OGGETTI_CONTRIBUENTE ogco_acc
                      ,OGGETTI_PRATICA ogpr_acc
                      ,PRATICHE_TRIBUTO prtr_acc
                      ,CODICI_TRIBUTO cotr
                      ,CARICHI_TARSU cata
                 where oggetti.cod_via = archivio_vie.cod_via(+)
                   and oggetti.oggetto = ogpr_acc.oggetto
                   and cate.tributo = tari.tributo
                   and cate.categoria = tari.categoria
                   and tari.anno = ogco_acc.anno
                   and tari.tributo = ogpr_acc.tributo
                   and tari.categoria = ogpr_acc.categoria
                   and tari.tipo_tariffa = ogpr_acc.tipo_tariffa
                   and ogim_acc.anno(+) = ogco_acc.anno
                   and ogim_acc.cod_fiscale(+) = ogco_acc.cod_fiscale
                   and ogim_acc.oggetto_pratica(+) = ogco_acc.oggetto_pratica
                   and cotr.tributo = ogpr_acc.tributo
                   and cata.anno = acc.anno
                   and ogco_acc.cod_fiscale = acc.cod_fiscale
                   and ogco_acc.oggetto_pratica = ogpr_acc.oggetto_pratica
                   and ogpr_acc.pratica = prtr_acc.pratica
                   and prtr_acc.pratica = acc.pratica
              group by prtr_acc.pratica
                      ,oggetti.oggetto
                      ,ogpr_acc.oggetto_pratica
                      ,ogim_acc.oggetto_imposta
                      ,ogco_acc.data_decorrenza
                      ,cate.descrizione
                      ,ogim_acc.anno
                      ,prtr_acc.numero
                      ,prtr_acc.anno
                      ,ogco_acc.inizio_occupazione
                      ,ogco_acc.data_decorrenza
                      ,ogco_acc.fine_occupazione
                      ,prtr_acc.data
                      ,cotr.flag_ruolo
                      ,cata.flag_lordo
                      ,tari.tariffa
                      ,substr(nvl(tari.descrizione,' '),1,36)
                      ,oggetti.partita
                      ,oggetti.sezione
                      ,oggetti.foglio
                      ,oggetti.numero
                      ,oggetti.subalterno
                      ,oggetti.zona
                      ,oggetti.protocollo_catasto
                      ,oggetti.anno_catasto
                      ,oggetti.categoria_catasto
                      ,oggetti.classe_catasto
                      ,decode(oggetti.cod_via,null,oggetti.indirizzo_localita
                                                  ,archivio_vie.denom_uff
                             )
                       ||decode(oggetti.num_civ,null,'',',' ||oggetti.num_civ)
                       ||decode(oggetti.suffisso,null,'','/' ||oggetti.suffisso)
                      ,ogpr_acc.consistenza
                      ,rpad(ltrim(translate(to_char(nvl(ogco_acc.perc_possesso,100)
                                                   ,'999,990.00'
                                                   )
                                           ,'.,',',.'
                                           )
                                 )
                           ,10
                           )
                      ,ogco_acc.flag_ab_principale
                      ,ogpr_acc.tipo_occupazione
                      ,cate.flag_domestica
                      ,cata.maggiorazione_tares
              order by prtr_acc.pratica
                      ,oggetti.oggetto
                      ,ogco_acc.data_decorrenza
               )
    loop
      w_tot_imposta    := w_tot_imposta    + nvl(ogg.imposta_dovuta_acc_no_visibile,0);
      w_tot_magg_tares := w_tot_magg_tares + nvl(ogg.magg_tares_acc_no_visibile,0);
      --
      for w_num_campo in 1..w_num_campi
      loop
        w_ind := w_ind + 1;
        if w_num_campo = 1 then
           riga_file (w_ind) := 'INDIRIZZO UTENZA: '||ogg.indirizzo_ogg;
        elsif w_num_campo = 2 then
           riga_file (w_ind) := ' ';
           w_ind := w_ind + 1;
           riga_file (w_ind) := 'Estremi Oggetto : '||ogg.st_partita||ogg.st_sezione||ogg.st_foglio||
                                ogg.st_numero||ogg.st_subalterno||ogg.st_zona||ogg.st_protocollo||
                                ogg.st_anno||ogg.st_categoria||ogg.st_classe;
        elsif w_num_campo = 3 then
           riga_file (w_ind) := '                  '||ogg.partita||ogg.sezione||ogg.foglio||
                                ogg.numero||ogg.subalterno||ogg.zona||ogg.protocollo_catasto||
                                ogg.anno_catasto||ogg.categoria_catasto||ogg.classe_catasto;
        elsif w_num_campo = 4 then
           riga_file (w_ind) := ' ';
           w_ind := w_ind + 1;
           riga_file (w_ind) := 'TIPO UTENZA     :       '||ogg.tipo_utenza||' - '||ogg.categoria_desc;
        elsif w_num_campo = 5 then
           riga_file (w_ind) := 'DESC. TARIFFA   :       '||ogg.tariffa_desc;
        elsif w_num_campo = 6 then
           riga_file (w_ind) := 'SUPERFICIE      :       '||'mq. '||ogg.superficie;
        elsif w_num_campo = 7 then
           if ogg.ab_principale is null then
              w_ind := w_ind - 1;
           else
              riga_file (w_ind) := 'ABITAZ. PRINC.  :       '||ogg.ab_principale;
           end if;
        elsif w_num_campo = 8 then
           w_ind := w_ind - 1;
           if nvl(rtrim(ogg.n_familiari),'DETTAGLI        :') <> 'DETTAGLI        :' then
              w_num_campi_dett := length(ogg.n_familiari) - length(replace(ogg.n_familiari,'#','')) + 1;
              w_inizio_dett := 1;
              for w_i in 1..w_num_campi_dett
              loop
                w_ind := w_ind + 1;
                if w_i = w_num_campi_dett then
                   riga_file (w_ind) := substr(ogg.n_familiari,w_inizio_dett);
                else
                   w_fine_dett := instr(ogg.n_familiari,'#',1,w_i) - w_inizio_dett;
                   riga_file (w_ind) := substr(ogg.n_familiari,w_inizio_dett,w_fine_dett);
                end if;
                w_inizio_dett := instr(ogg.n_familiari,'#',1,w_i) + 1;
              end loop;
           end if;
        elsif w_num_campo = 9 then
           if ogg.data_decor is null then
              w_ind := w_ind - 1;
           else
              riga_file (w_ind) := 'DATA DECORRENZA :       '||ogg.data_decor;
           end if;
        elsif w_num_campo = 10 then
           if ogg.fine_occup is null then
              w_ind := w_ind - 1;
           else
              riga_file (w_ind) := 'FINE OCCUPAZIONE:       '||ogg.fine_occup;
           end if;
        elsif w_num_campo = 11 then
           riga_file (w_ind) := ' ';
           w_ind := w_ind + 1;
           riga_file (w_ind) := 'IMPOSTA         :       '||ogg.imposta_acc;
        elsif w_num_campo = 12 then
           if ogg.imposta_dovuta_add_eca is null then
              w_ind := w_ind - 1;
           else
              riga_file (w_ind) := 'ADDIZIONALE ECA :       '||ogg.imposta_dovuta_add_eca;
           end if;
        elsif w_num_campo = 13 then
           if ogg.imposta_dovuta_mag_eca is null then
              w_ind := w_ind - 1;
           else
              riga_file (w_ind) := 'MAGG. ECA       :       '||ogg.imposta_dovuta_mag_eca;
           end if;
        elsif w_num_campo = 14 then
           if ogg.imposta_dovuta_add_pro is null then
              w_ind := w_ind - 1;
           else
              riga_file (w_ind) := 'ADD. PROVINCIALE:       '||ogg.imposta_dovuta_add_pro;
           end if;
        elsif w_num_campo = 15 then
           if ogg.imposta_dovuta_iva is null then
              w_ind := w_ind - 1;
           else
              riga_file (w_ind) := 'IVA             :       '||ogg.imposta_dovuta_iva;
           end if;
        elsif w_num_campo = 16 then
           if ogg.imposta_dovuta is null then
              w_ind := w_ind - 1;
           else
              riga_file (w_ind) := rpad(w_para_dic_acc_imp_dov,16)||':       '||ogg.imposta_dovuta;
           end if;
        elsif w_num_campo = 17 then
           if ogg.magg_tares is null then
              w_ind := w_ind - 1;
           else
              riga_file (w_ind) := 'MAGG. TARES     :       '||ogg.magg_tares;
           end if;
        end if;
      end loop;
      --
      w_ind := w_ind + 1;
      riga_file (w_ind) := '-------------------------------------------------------------------------------------------------';
    end loop;
    --
    -- Stampa totali oggetti
    --
    if w_tot_imposta <> 0 then
       w_ind := w_ind + 1;
       riga_file (w_ind) := ' ';
       w_ind := w_ind + 1;
       riga_file (w_ind) := rpad(w_para_tot_imp_comp,79)||translate(to_char(w_tot_imposta,'99,999,999,990.00')
                                                                   ,',.','.,'
                                                                   );
    end if;
    --
    -- (VD - 19/09/2017): Il totale della maggiorazione TARES si stampa solo se
    --                    prevista per l'anno che si sta trattando
    --
    --if w_tot_magg_tares <> 0 then
    if acc.flag_magg_tares = 'S' then
       w_ind := w_ind + 1;
       riga_file (w_ind) := rpad(w_para_tot_magg_tares,79)||translate(to_char(w_tot_magg_tares,'99,999,999,990.00')
                                                                     ,',.','.,'
                                                                     );
    end if;
        if acc.pratica = 326451 then
      dbms_output.put_line('Fine oggetti: '||w_ind);
        end if;
    --
    -- Trattamento versamenti
    --
    w_prima_riga       := 'S';
    w_tot_imposta_vers := 0;
    w_tot_mtares_vers  := 0;
    --
    for vers in (select rpad(' ',6)||
                        nvl(to_char(vers.rata,99),'  ')||
                        rpad(' ',2)||
                        translate(to_char(vers.importo_versato - nvl(vers.maggiorazione_tares,0),'9,999,999,999,990.00')
                                 ,',.', '.,')||
                        lpad(translate(nvl(to_char(vers.maggiorazione_tares,'9,999,999,999,990.00'),' ')
                                       ,',.', '.,'),26)||
                        lpad(' ',5)||
                        nvl(to_char(vers.data_pagamento,'dd/mm/yyyy'),'          ')||
                        lpad(' ',7)||
                        nvl(to_char(decode(vers.rata
                                          ,0,ruol.scadenza_prima_rata
                                          ,1,ruol.scadenza_prima_rata
                                          ,2,ruol.scadenza_rata_2
                                          ,3,ruol.scadenza_rata_3
                                          ,4,ruol.scadenza_rata_4
                                          )
                                   ,'dd/mm/yyyy')
                           ,'          ') riga_vers
                      , vers.importo_versato - nvl(vers.maggiorazione_tares,0) importo_versato
                      ,   vers.maggiorazione_tares
                   from versamenti       vers,
                        pratiche_tributo prtr,
                        ruoli            ruol
                  where vers.pratica               is null
                    and vers.oggetto_imposta       is null
                    and vers.cod_fiscale           = acc.cod_fiscale
                    and vers.anno                  = prtr.anno
                    and prtr.pratica               = acc.pratica
                    and vers.tipo_tributo          = w_tipo_tributo
                    and vers.ruolo                 = ruol.ruolo (+)
                    and not exists (select sapr.cod_sanzione
                                      from sanzioni_pratica sapr
                                     where sapr.cod_sanzione in (2,3,4,5,6,102,103,104,105,106)
                                           /* omesse, infedeli e tardive denunce*/
                                       and sapr.pratica = acc.pratica
                                   )
                  order by vers.rata,vers.data_pagamento)
    loop
      --
      -- Composizione intestazione versamenti
      --
      if w_prima_riga = 'S' then
         w_prima_riga := 'N';
         w_ind := w_ind + 1;
         riga_file (w_ind) := ' ';
         w_ind := w_ind + 1;
         w_riga := w_para_dett_vers;
         riga_file (w_ind) := lpad(' ',trunc((99 - length(w_riga)) / 2))||w_riga;
         w_ind := w_ind + 1;
         riga_file (w_ind) := '      RATA       IMPORTO VERSATO               MAGG. TARES    DATA VERSAM    DATA SCADENZA';
      end if;
      --
      w_ind := w_ind + 1;
      riga_file (w_ind) := vers.riga_vers;
      --
      w_tot_imposta_vers := w_tot_imposta_vers + vers.importo_versato;
      w_tot_mtares_vers  := w_tot_mtares_vers  + nvl(vers.maggiorazione_tares,0);
    end loop;
    --
    -- Il totale dei versamenti viene stampato sempre anche se = 0
    --
    w_ind := w_ind + 1;
    riga_file (w_ind) := ' ';
    w_ind := w_ind + 1;
    riga_file (w_ind) := rpad(w_para_tot_dett_vers,76)||translate(to_char(w_tot_imposta_vers,'9,999,999,999,990.00')
                                                                 ,',.', '.,');
    --
    -- La maggiorazione Tares versata viene stampata se tale maggiorazione
    -- e dovuta oppure se ci sono stati versamenti (anche errati)
    --
    -- (VD - 19/09/2017): il totale della maggiorazione Tares viene stampata
    --                    se prevista per l'anno oppure se ci sono versamenti
    --                    anche errati
    --
    --if w_tot_magg_tares <> 0 or
    if acc.flag_magg_tares = 'S' or
       w_tot_mtares_vers <> 0 then
       w_ind := w_ind + 1;
       riga_file (w_ind) := rpad(w_para_tot_magg_tares_v,76)||translate(to_char(w_tot_mtares_vers,'9,999,999,999,990.00')
                                                                       ,',.', '.,');
    end if;
    --
    -- Stampa riepilogo (solo se esistono versamenti)
    --
    if w_tot_imposta_vers <> 0 or
       w_tot_mtares_vers  <> 0 then
       w_ind := w_ind + 1;
       riga_file (w_ind) := ' ';
       w_ind := w_ind + 1;
       w_riga := w_para_riepilogo;
       riga_file (w_ind) := lpad(' ',trunc((99 - length(w_riga)) / 2))||w_riga;
       w_ind := w_ind + 1;
       riga_file (w_ind) := rpad(w_para_tot_imp_comp,76)||translate(to_char(w_tot_imposta,'9,999,999,999,990.00')
                                                                   ,',.', '.,');
       w_ind := w_ind + 1;
       riga_file (w_ind) := rpad(w_para_tot_vers,76)||translate(to_char(w_tot_imposta_vers,'9,999,999,999,990.00')
                                                               ,',.', '.,');
       --
       w_diff_imposta := w_tot_imposta - w_tot_imposta_vers;
       w_ind := w_ind + 1;
       riga_file (w_ind) := rpad(w_para_diff_imposta,76)||translate(to_char(w_diff_imposta,'9,999,999,999,990.00')
                                                                   ,',.', '.,');
       --
       -- (VD - 19/09/2017): il riepilogo della maggiorazione TARES viene
       --                    stampato solo se prevista per l'anno che si
       --                    sta trattando o se esistono dei versamenti
       --if w_tot_magg_tares <> 0 or
       if acc.flag_magg_tares = 'S' or
          w_tot_mtares_vers <> 0 then
          w_ind := w_ind + 1;
          riga_file (w_ind) := rpad(w_para_tot_magg_tares,76)||translate(to_char(w_tot_magg_tares,'9,999,999,999,990.00')
                                                                               ,',.', '.,');
          w_ind := w_ind + 1;
          riga_file (w_ind) := rpad(w_para_tot_magg_tares_v,76)||translate(to_char(w_tot_mtares_vers,'9,999,999,999,990.00')
                                                                          ,',.', '.,');
          w_diff_mtares  := w_tot_magg_tares - w_tot_mtares_vers;
          w_ind := w_ind + 1;
          riga_file (w_ind) := rpad(w_para_diff_mtares,76)||translate(to_char(w_diff_mtares,'9,999,999,999,990.00')
                                                                            ,',.', '.,');
       end if;
    end if;
        if acc.pratica = 326451 then
      dbms_output.put_line('Versamenti: '||w_ind);
        end if;
    --
    -- Trattamento accertamento imposte
    --
    w_prima_riga     := 'S';
    w_tot_imposta_acc:= 0;
    w_tot_mtares_acc := 0;
    for imp in (select sanzioni_pratica.cod_sanzione
                      ,trunc(sanzioni_pratica.cod_sanzione / 100) sanz_ord1
                      ,sanzioni.tipo_causale||nvl(sanzioni.flag_magg_tares,'N') sanz_ord
                      ,1 ord
                      ,nvl(sanzioni_pratica.importo,0)
                       + decode(ogpr.flag_ruolo
                               ,'S',decode(decode(sanzioni.tipo_causale
                                                  ||nvl(sanzioni.flag_magg_tares,'N')
                                                 ,'EN',1
                                                      ,0
                                                 )
                                          ,1,round(sanzioni_pratica.importo
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
                                       ) importo
                      ,decode(sanzioni_pratica.percentuale
                             ,null,'        '
                                  ,replace(to_char(sanzioni_pratica.percentuale,'9990.00')
                                          ,'.',','
                                          )
                             )
                       ||'  '
                       ||decode(sanzioni_pratica.riduzione
                               ,null,'        '
                                    ,replace(to_char(sanzioni_pratica.riduzione
                                                    ,'9990.00'
                                                    )
                                            ,'.',','
                                            )
                               )
                       ||'  '
                       ||decode(sanzioni_pratica.semestri
                               ,null,'   '
                                    ,to_char(sanzioni_pratica.semestri,'99')
                               )
                       ||'  '
                       ||translate(to_char(nvl(sanzioni_pratica.importo,0)
                                           + decode(ogpr.flag_ruolo
                                                   ,'S',decode(decode(sanzioni.tipo_causale
                                                                      ||nvl(sanzioni.flag_magg_tares,'N')
                                                                     ,'EN',1
                                                                          ,0
                                                                     )
                                                              ,1,round(sanzioni_pratica.importo
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
                                                                         * nvl(carichi_tarsu.aliquota
                                                                                ,0
                                                                                )
                                                                          / 100
                                                                         ,2
                                                                         )
                                                                ,0
                                                              )
                                                   ,0
                                                   )
                                          ,'99,999,999,990.00'
                                          )
                                  ,',.','.,'
                                  ) perc_ed_importo
                      ,rpad(decode(w_para_vis_cod_trib
                                  ,'SI',nvl(sanzioni.cod_tributo_f24
                                           ,decode(sanzioni.flag_magg_tares
                                                  ,'S','3955'
                                                      ,'3944'
                                                  )
                                           )|| ' - '
                                       ,''
                                  )
                            ||substr(sanzioni.descrizione,1,50)
                           ,54
                           ) descrizione
                  from SANZIONI_PRATICA
                      ,SANZIONI
                      ,CARICHI_TARSU
                      ,PRATICHE_TRIBUTO
                      ,(select nvl(max(nvl(cotr.flag_ruolo,'N')),'N') flag_ruolo
                          from codici_tributo cotr
                             , oggetti_pratica ogpr
                         where cotr.tributo = ogpr.tributo
                           and ogpr.pratica = acc.pratica) ogpr
                 where sanzioni_pratica.cod_sanzione = sanzioni.cod_sanzione
                   and sanzioni_pratica.sequenza_sanz = sanzioni.sequenza
                   and sanzioni_pratica.tipo_tributo = sanzioni.tipo_tributo
                   and ((pratiche_tributo.tipo_tributo = w_tipo_tributo
                         and sanzioni.tipo_causale = 'E')
                        or (pratiche_tributo.tipo_tributo != w_tipo_tributo
                            and sanzioni.flag_imposta = 'S'))
                   and sanzioni.cod_sanzione not in (888, 889)
                   and sanzioni_pratica.pratica = acc.pratica
                   and pratiche_tributo.pratica = acc.pratica
                   and carichi_tarsu.anno(+) = pratiche_tributo.anno
                order by 3, 1, 4)
    loop
      if w_prima_riga = 'S' then
         w_prima_riga  := 'N';
         w_flag_totali := substr(imp.sanz_ord,2,1);
         w_ind := w_ind + 1;
         riga_file(w_ind) := ' ';
         w_ind := w_ind + 1;
         w_riga := w_para_acc_imp;
         riga_file (w_ind) := lpad(' ',trunc((99 - length(w_riga)) / 2))||w_riga;
      end if;
      --
      if substr(imp.sanz_ord,2,1) <> w_flag_totali then
         w_ind := w_ind + 1;
         if w_flag_totali = 'N' then
            if w_tot_imposta_acc <> 0 then
               riga_file(w_ind) := rpad(w_para_tot_acc_imp,76)||translate(to_char(w_tot_imposta_acc,'9,999,999,999,990.00')
                                                                         ,',.', '.,');
            end if;
         else
            if w_tot_mtares_acc <> 0 then
               riga_file(w_ind) := rpad(w_para_tot_acc_mag,76)||translate(to_char(w_tot_mtares_acc,'9,999,999,999,990.00')
                                                                         ,',.', '.,');
            end if;
         end if;
         w_flag_totali := substr(imp.sanz_ord,2,1);
      end if;
      --
      w_ind := w_ind + 1;
      riga_file(w_ind) := imp.descrizione||imp.perc_ed_importo;
      if w_flag_totali = 'N' then
         w_tot_imposta_acc := w_tot_imposta_acc + imp.importo;
      else
         w_tot_mtares_acc  := w_tot_mtares_acc + imp.importo;
      end if;
    end loop;
    --
    if w_flag_totali = 'N' then
       if w_tot_imposta_acc <> 0 then
          w_ind := w_ind + 1;
          riga_file(w_ind) := rpad(w_para_tot_acc_imp,76)||translate(to_char(w_tot_imposta_acc,'9,999,999,999,990.00')
                                                                    ,',.', '.,');
       end if;
    else
--       riga_file(w_ind) := rpad(w_para_tot_acc_mag,76)||translate(to_char(w_tot_mtares_acc,'9,999,999,999,990.00')
       if w_tot_mtares_acc <> 0 then
          w_ind := w_ind + 1;
          riga_file(w_ind) := rpad(w_para_tot_acc_imp,76)||translate(to_char(w_tot_mtares_acc,'9,999,999,999,990.00')
                                                                    ,',.', '.,');
       end if;
    end if;
        if acc.pratica = 326451 then
      dbms_output.put_line('Accertamento: '||w_ind);
        end if;
    --
    -- Trattamento sanzioni e interessi
    --
    w_prima_riga       := 'S';
    w_tot_imposta_sanz := 0;
    w_tot_mtares_sanz  := 0;
    for sanz in (select sanzioni_pratica.cod_sanzione
                      , nvl(sanzioni.flag_magg_tares,'N') flag_magg_tares
                      , nvl(sanzioni_pratica.importo,0) importo
                      , decode(sanzioni_pratica.percentuale
                              ,null,rpad(' ' ,8)
                                   ,translate(to_char(sanzioni_pratica.percentuale,'9990.00'),',.','.,'))
                        ||'   '
                        ||decode(sanzioni_pratica.riduzione
                                ,null,rpad(' ' ,8)
                                     ,translate(to_char(sanzioni_pratica.riduzione,'9990.00'),',.','.,'))
                        ||'   '
                        ||decode(nvl(sanzioni_pratica.giorni,sanzioni_pratica.semestri)
                                ,null,rpad(' ' ,5)
                                ,to_char(nvl(sanzioni_pratica.giorni,sanzioni_pratica.semestri),'9999'))
                        ||'   '
                        ||translate(to_char(sanzioni_pratica.importo,'99,999,999,990.00'),',.','.,') perc_ed_importo
                      , rpad(substr(decode(w_para_vis_cod_trib
                                          ,'SI',nvl(sanzioni.cod_tributo_f24
                                                   ,decode(sanzioni.flag_magg_tares
                                                          ,'S','3955'
                                                              ,'3944'
                                                          )
                                                   )
                                                ||' - '
                                               ,''
                                          )
                                    ||sanzioni.descrizione,1,49),49) descrizione
                   from SANZIONI_PRATICA
                      , SANZIONI
                  where sanzioni_pratica.cod_sanzione = sanzioni.cod_sanzione
                    and sanzioni_pratica.sequenza_sanz = sanzioni.sequenza
                    and sanzioni_pratica.tipo_tributo = sanzioni.tipo_tributo
                    and sanzioni.cod_sanzione not in (1,100,101)
                    and nvl(sanzioni.tipo_causale,'*') != 'E'
                    and sanzioni_pratica.cod_sanzione not in (888,889)
                    and sanzioni_pratica.pratica = acc.pratica
                  order by 1)
    loop
      if w_prima_riga = 'S' then
         w_prima_riga  := 'N';
         w_flag_totali := sanz.flag_magg_tares;
         w_ind := w_ind + 1;
         riga_file(w_ind) := ' ';
         w_ind := w_ind + 1;
         w_riga := w_para_irr_sanz_int;
         riga_file (w_ind) := lpad(' ',trunc((99 - length(w_riga)) / 2))||w_riga;
         w_ind := w_ind + 1;
         riga_file(w_ind) := '                                                    PERC.    RID.   SEM./GG.';
      end if;
      --
      if sanz.flag_magg_tares <> w_flag_totali then
         w_ind := w_ind + 1;
         if w_flag_totali = 'N' then
            riga_file(w_ind) := rpad(w_para_irr_tot_sanz,76)||translate(to_char(w_tot_imposta_sanz,'9,999,999,999,990.00')
                                                                       ,',.', '.,');
         else
--            riga_file(w_ind) := rpad(w_para_irr_tot_magg,76)||translate(to_char(w_tot_mtares_sanz,'9,999,999,999,990.00')
            riga_file(w_ind) := rpad(w_para_irr_tot_sanz,76)||translate(to_char(w_tot_mtares_sanz,'9,999,999,999,990.00')
                                                                       ,',.', '.,');
         end if;
         w_flag_totali := sanz.flag_magg_tares;
      end if;
      --
      w_ind := w_ind + 1;
      riga_file(w_ind) := sanz.descrizione||sanz.perc_ed_importo;
      if w_flag_totali = 'N' then
         w_tot_imposta_sanz := w_tot_imposta_sanz + sanz.importo;
      else
         w_tot_mtares_sanz := w_tot_mtares_sanz + sanz.importo;
      end if;
    end loop;
    --
    -- Se il flag w_prima_riga e' uguale a 'N', significa che sono stati
    -- stampati dei versamenti, quindi si stampa anche il totale. In caso
    -- contrario, i totali non vengono stampati
    --
    if w_prima_riga = 'N' then
       w_ind := w_ind + 1;
       if w_flag_totali = 'N' then
          riga_file(w_ind) := rpad(w_para_irr_tot_sanz,76)||translate(to_char(w_tot_imposta_sanz,'9,999,999,999,990.00')
                                                                     ,',.', '.,');
       else
          --riga_file(w_ind) := rpad(w_para_irr_tot_magg,76)||translate(to_char(w_tot_mtares_sanz,'9,999,999,999,990.00')
          riga_file(w_ind) := rpad(w_para_irr_tot_sanz,76)||translate(to_char(w_tot_mtares_sanz,'9,999,999,999,990.00')
                                                                     ,',.', '.,');
       end if;
    end if;
        if acc.pratica = 326451 then
      dbms_output.put_line('Sanzioni: '||w_ind);
        end if;
    --
    -- Riepilogo somme dovute
    --
    w_ind := w_ind + 1;
    riga_file (w_ind) := ' ';
    w_ind := w_ind + 1;
    w_riga := w_para_rie_som_dov;
    riga_file (w_ind) := lpad(' ',trunc((99 - length(w_riga)) / 2))||w_riga;
    --
    if w_tot_imposta_acc <> 0 then
       w_ind := w_ind + 1;
       riga_file (w_ind) := rpad(w_para_totaccimp,76)||translate(to_char(w_tot_imposta_acc,'9,999,999,999,990.00')
                                                                ,',.', '.,');
    end if;
    --
    if w_tot_imposta_sanz <> 0 then
       w_ind := w_ind + 1;
       riga_file (w_ind) := rpad(w_para_totsanz,76)||translate(to_char(w_tot_imposta_sanz,'9,999,999,999,990.00')
                                                              ,',.', '.,');
    end if;
    --
    if w_tot_mtares_acc <> 0 then
       w_ind := w_ind + 1;
--       riga_file (w_ind) := rpad(w_para_totaccmag,76)||translate(to_char(w_tot_mtares_acc,'9,999,999,999,990.00')
       riga_file (w_ind) := rpad('TOTALE MAGG. TARES EVASA',76)||translate(to_char(w_tot_mtares_acc,'9,999,999,999,990.00')
                                                                ,',.', '.,');
    end if;    --
    if w_tot_mtares_sanz <> 0 then
       w_ind := w_ind + 1;
--       riga_file (w_ind) := rpad(w_para_totsanzmag,76)||translate(to_char(w_tot_mtares_sanz,'9,999,999,999,990.00')
       riga_file (w_ind) := rpad(w_para_totsanz,76)||translate(to_char(w_tot_mtares_sanz,'9,999,999,999,990.00')
                                                              ,',.', '.,');
    end if;
    --
    w_ind := w_ind + 1;
    riga_file (w_ind) := rpad(w_para_tot,76)||translate(to_char(acc.importo_totale,'9,999,999,999,990.00')
                                                       ,',.', '.,');
    --
    if acc.importo_ridotto is not null then
       w_ind := w_ind + 1;
       riga_file (w_ind) := rpad(w_para_totale_ad,76)||translate(to_char(acc.importo_ridotto,'9,999,999,999,990.00')
                                                                ,',.', '.,');
    end if;
    --
    if w_para_vis_tot_arr = 'SI' then
       w_ind := w_ind + 1;
       riga_file (w_ind) := rpad(w_para_totale_arr,76)||translate(to_char(acc.importo_totale_arrotondato,'9,999,999,999,990.00')
                                                                 ,',.', '.,');
    --
       if acc.importo_ridotto_arrotondato is not null then
          w_ind := w_ind + 1;
          riga_file (w_ind) := rpad(w_para_totale_ad_arr,76)||translate(to_char(acc.importo_ridotto_arrotondato,'9,999,999,999,990.00')
                                                                       ,',.', '.,');
       end if;
    end if;
        if acc.pratica = 326451 then
      dbms_output.put_line('Riep.Avviso: '||w_ind);
        end if;
    --
    -- Riepilogo codici per F24
    -- (VD - 18/09/2017): il riepilogo si stampa solo se l'apposito parametro
    --                    e' uguale a S
    --
    if p_riep_f24 = 'S' then
       w_prima_riga       := 'S';
       w_tot_f24_importo  := 0;
       w_tot_f24_imp_rid  := 0;
       for riep in (select nvl(sanz.cod_tributo_f24,decode(sanz.flag_magg_tares,'S','3955','3944')) cod_tributo
                         , round(sum(f_importo_f24_viol(sapr.importo
                                                       ,sapr.riduzione
                                                       ,'N'
                                                       ,acc.tipo_tributo
                                                       ,acc.anno
                                                       ,sanz.tipo_causale
                                                       ,sanz.flag_magg_tares
                                                       )
                                    )
                                ,0
                                )                     importo
                         , round(sum(f_importo_f24_viol(sapr.importo
                                                       ,sapr.riduzione
                                                       ,'S'
                                                       ,acc.tipo_tributo
                                                       ,acc.anno
                                                       ,sanz.tipo_causale
                                                       ,sanz.flag_magg_tares
                                                       )
                                    )
                                ,0
                                )                     importo_ridotto
                      from sanzioni_pratica   sapr
                         , sanzioni           sanz
                     where sapr.pratica = acc.pratica
                       and sapr.cod_sanzione = sanz.cod_sanzione
                       and sapr.sequenza_sanz = sanz.sequenza
                       and sapr.tipo_tributo = sanz.tipo_tributo
                  group by nvl(sanz.cod_tributo_f24,decode(sanz.flag_magg_tares,'S','3955','3944'))
                    having round(sum(f_importo_f24_viol(sapr.importo
                                                       ,sapr.riduzione
                                                       ,'N'
                                                       ,acc.tipo_tributo
                                                       ,acc.anno
                                                       ,sanz.tipo_causale
                                                       ,sanz.flag_magg_tares
                                                       )
                                    )
                                ,0
                                ) > 0 or
                           round(sum(f_importo_f24_viol(sapr.importo
                                                       ,sapr.riduzione
                                                       ,'S'
                                                       ,acc.tipo_tributo
                                                       ,acc.anno
                                                       ,sanz.tipo_causale
                                                       ,sanz.flag_magg_tares
                                                       )
                                    )
                                ,0
                                ) > 0)
       loop
         --
         -- Composizione intestazione riepilogo codici per F24
         --
         if w_prima_riga = 'S' then
            w_prima_riga := 'N';
            w_ind := w_ind + 1;
            riga_file (w_ind) := ' ';
            w_ind := w_ind + 1;
   --         w_riga := w_para_f24_int;
            w_riga := 'RIEPILOGO SOMME DA VERSARE';
            riga_file (w_ind) := lpad(' ',trunc((99 - length(w_riga)) / 2))||w_riga;
            w_ind := w_ind + 1;
            riga_file (w_ind) := 'COD. TRIBUTO           IMPORTO DA VERSARE      IMPORTO DA VERSARE CON ADESIONE';
         end if;
         --
         w_tot_f24_importo := w_tot_f24_importo + riep.importo;
         w_tot_f24_imp_rid := w_tot_f24_imp_rid + riep.importo_ridotto;
         w_ind := w_ind + 1;
         riga_file(w_ind) := rpad(riep.cod_tributo,20)||translate(to_char(riep.importo,'9,999,999,999,990.00')
                                                                 ,',.', '.,')
                                                      ||lpad(' ',16)
                                                      ||translate(to_char(riep.importo_ridotto,'9,999,999,999,990.00')
                                                                 ,',.', '.,');
       end loop;
       --
       w_ind := w_ind + 1;
       riga_file(w_ind) := rpad('TOTALE DA VERSARE',20)||translate(to_char(w_tot_f24_importo,'9,999,999,999,990.00')
                                                                     ,',.', '.,')
                                                       ||lpad(' ',16)
                                                       ||translate(to_char(w_tot_f24_imp_rid,'9,999,999,999,990.00')
                                                                     ,',.', '.,');
    end if;
        if acc.pratica = 326451 then
      dbms_output.put_line('Riep. F24: '||w_ind);
        end if;
    --
    -- Memorizzazione del numero di colonne utilizzate
    --
    if w_ind > w_max_colonna then
       w_max_colonna := w_ind;
    end if;
    --
    --  Composizione riga file
    --
    begin
      w_riga := '';
      for w_ind in riga_file.first .. riga_file.last
      loop
        w_riga := w_riga||riga_file(w_ind)||';';
        if acc.pratica = 326451 then
      dbms_output.put_line('Indice: '||w_ind);
        end if;
        if length(w_riga) > 32000 then
           w_riga := substr(w_riga,1,32000);
           --raise errore;
        end if;
      end loop;
    exception
      when others then
        w_errore := 'Composizione riga (Cod. fiscale ' || acc.cod_fiscale || ', Pratica n. '|| acc.pratica ||') - ' ||
                    sqlerrm;
        raise errore;
    end;
    --
    w_riga1 := substr(w_riga,1,4000);
    w_riga2 := substr(w_riga,4001,4000);
    w_riga3 := substr(w_riga,8001,4000);
    w_riga4 := substr(w_riga,12001,4000);
    w_riga5 := substr(w_riga,16001,4000);
    w_riga6 := substr(w_riga,20001,4000);
    w_riga7 := substr(w_riga,24001,4000);
    w_riga8 := substr(w_riga,28001,4000);
    begin
      insert into wrk_trasmissioni ( numero
                                   , dati
                                   , dati2
                                   , dati3
                                   , dati4
                                   , dati5
                                   , dati6
                                   , dati7
                                   , dati8
                                   )
      values ( lpad(to_char(w_conta_righe),15,'0')
             , w_riga1
             , w_riga2
             , w_riga3
             , w_riga4
             , w_riga5
             , w_riga6
             , w_riga7
             , w_riga8
             );
    exception
      when others then
        w_errore := 'Ins. WRK_TRASMISSIONI (Cod. fiscale ' || acc.cod_fiscale || ', Pratica n. '|| acc.pratica || ') - ' ||
                     sqlerrm;
        raise errore;
    end;
  end loop;
--
-- Composizione riga di intestazione
--
  w_riga := 'CODICE_FISCALE;COGNOME;NOME;DATA_NASCITA;SESSO;COMUNE_NASCITA;PROVINCIA_NASCITA;COD_FISCALE_EREDE;IDENTIFICATIVO_OPERAZIONE;';
  w_conta_campi := 9;
  for w_ind in 1..20
  loop
    if w_ind = 11 then
       w_riga := w_riga||'TOTALE_01;';
       w_conta_campi := w_conta_campi + 1;
    end if;
    --
    w_riga := w_riga||'SEZIONE1_'||lpad(to_char(w_ind),2,'0')||';SEZIONE2_'||lpad(to_char(w_ind),2,'0')||
                      ';COD_TRIBUTO_'||lpad(to_char(w_ind),2,'0')||';COD_ENTE_'||lpad(to_char(w_ind),2,'0')||
                      ';RATEAZIONE_'||lpad(to_char(w_ind),2,'0')||';ANNO_RIF_'||lpad(to_char(w_ind),2,'0')||
                      ';IMPORTO_X_100_'||lpad(to_char(w_ind),2,'0')||';';
    w_conta_campi := w_conta_campi + 7;
  end loop;
  --
  w_riga := w_riga||'TOTALE_02;PROTOCOLLO;NOMINATIVO;INDIRIZZO1;INDIRIZZO2;INDIRIZZO3;CODICE_FISCALE;'||
                    'NOMINATIVO_EREDE;INDIRIZZO1_EREDE;INDIRIZZO2_EREDE;COD_FISCALE_EREDE;'||
                    'ATTO1;ATTO2;ATTO3;';
  w_conta_campi := w_conta_campi + 14;
  --
  for w_ind in w_conta_campi .. w_max_colonna
  loop
    w_riga := w_riga||'RIGA_'||lpad(to_char(w_ind - w_conta_campi + 1),3,'0')||';';
  end loop;
  --
  w_num_colonne := length(w_riga) - length(replace(w_riga,';',''));
  w_riga1 := substr(w_riga,1,4000);
  w_riga2 := substr(w_riga,4001,4000);
  w_riga3 := substr(w_riga,8001,4000);
  w_riga4 := substr(w_riga,12001,4000);
  w_riga5 := substr(w_riga,16001,4000);
  w_riga6 := substr(w_riga,20001,4000);
  w_riga7 := substr(w_riga,24001,4000);
  w_riga8 := substr(w_riga,28001,4000);
  begin
    insert into wrk_trasmissioni ( numero
                                 , dati
                                 , dati2
                                 , dati3
                                 , dati4
                                 , dati5
                                 , dati6
                                 , dati7
                                 , dati8
                                 )
    values ( lpad('1',15,'0')
           , w_riga1
           , w_riga2
           , w_riga3
           , w_riga4
           , w_riga5
           , w_riga6
           , w_riga7
           , w_riga8
           );
  exception
    when others then
      w_errore := 'Ins. WRK_TRASMISSIONI intestazione ' ||
                   sqlerrm;
      raise errore;
  end;
  --
  p_num_contribuenti := w_num_contribuenti;
  p_num_atti         := w_conta_righe - 1;
  p_num_colonne      := w_num_colonne;
  --
exception
  when errore then
    raise_application_error(-20999,w_errore);
  when others then
    raise;
end;
/* End Procedure: ESTRAZIONE_ACC_TARSU_AUTO */
/
