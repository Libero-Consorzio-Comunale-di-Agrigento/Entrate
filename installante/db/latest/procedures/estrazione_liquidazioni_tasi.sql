--liquibase formatted sql 
--changeset abrandolini:20250326_152423_estrazione_liquidazioni_tasi stripComments:false runOnChange:true 
 
create or replace procedure ESTRAZIONE_LIQUIDAZIONI_TASI
/*************************************************************************
 NOME:        ESTRAZIONE_LIQUIDAZIONI_TASI
 DESCRIZIONE: Estrazione per stampa avvisi di liquidazione TASI e relativi
              F24
              Comune di Pioltello
 NOTE:
 Rev.    Date         Author      Note
 002     17/09/2019   VD          Corretta indicazione codici tributo per
                                  F24.
 001     03/01/2018   VD          Tolto simbolo "%" di fianco alle aliquote
                                  in quanto non si tratta di percentuali ma
                                  di "per mille".
 000     19/09/2017   VD          Prima emissione.
*************************************************************************/
( p_anno_iniz               number
, p_anno_fine               number
, p_data_iniz               date
, p_data_fine               date
, p_numero_iniz             varchar2
, p_numero_fine             varchar2
, p_tipo_stato              varchar2
, p_tipo_atto               number
, p_flag_importo_ridotto    varchar2
, p_num_modello             number
, p_num_protocollo          varchar2
, p_data_protocollo         date
, p_num_contribuenti        in out number
, p_num_atti                in out number
, p_num_colonne             in out number)
is
  w_tipo_tributo      varchar2(5) := 'TASI';
  w_num_contribuenti  number := 0;
  w_num_colonne       number := 0;
  w_max_colonna       number := 0;
  w_conta_campi       number := 0;
  w_cf_prec           varchar2(16) := '*';
  w_cod_comune        varchar2(4);
  w_conta_righe       number := 1;
  w_errore            varchar2(4000);
  errore              exception;
  w_num_campo         number;
  w_num_campi         number;
  w_ind_totale        number;
  w_prima_riga        varchar2(1);
  w_conta_righe_f24   number;
  w_tot_imposta       number;
  w_tot_f24_importo   number;
  w_tot_f24_imp_rid   number;
  w_tot_versato       number;
  w_tot_imposta_int   number;
  w_tot_sanzioni      number;
  w_flag_int          number;
  w_tasi_imp_dovuto   number;
  w_tasi_imp_versato  number;
  w_tasi_differenza   number;
  w_tot_imp_dovuto    number;
  w_tot_imp_versato   number;
  w_tot_differenza    number;
  TYPE VettoreRighe   IS TABLE OF VARCHAR2(32767)
  INDEX BY BINARY_INTEGER;
  Riga_file           VettoreRighe;
  w_ind               number;
  w_i                 number;
  w_num_campi_dett    number;
  w_inizio_dett       number;
  w_fine_dett         number;
  w_riga              varchar2(32000);
  w_file_clob_1       clob;
  w_file_clob         clob;
--
-- Variabili per parametri modello
--
  w_des_tributo                varchar2(20);
  w_para_intestazione          varchar2(12);
  w_para_int_imposta_int       varchar2(12);
  w_para_note_vers_ravv        varchar2(220);
  w_para_int_imposta_calc      varchar2(60);
  w_para_des_ris_cat           varchar2(35);
  w_para_dati_dich             varchar2(2);
--
  w_anno_da                    number := 2012;
--
-- Codici tributo per F24
--
  w_cf24_ab_princ              varchar2(4);
  w_cf24_fabb_rurali           varchar2(4);
  w_cf24_aree_fabb             varchar2(4);
  w_cf24_altri_fabb            varchar2(4);
  w_cf24_interessi             varchar2(4);
  w_cf24_sanzioni              varchar2(4);
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
  -- Selezione parametri modello
  --
  begin
    select f_descrizione_titr(w_tipo_tributo,to_number(to_char(sysdate,'yyyy')))
         , decode(rtrim(f_descrizione_timp(p_num_modello,'INTESTAZIONE')),'DEFAULT','LIQUIDAZIONE',
                  rtrim(f_descrizione_timp(p_num_modello,'INTESTAZIONE')))
         , rtrim(f_descrizione_timp(p_num_modello,'INT_IMPOSTA_INTERESSI'))
         , rtrim(f_descrizione_timp(p_num_modello,'NOTE_VERS_RAVV'))
         , rtrim(f_descrizione_timp(p_num_modello,'INT_IMPOSTA_CALC'))
         , rtrim(f_descrizione_timp(p_num_modello,'DES_RIS_CAT'))
         , nvl(f_descrizione_timp(p_num_modello,'DATI_DIC'),'NO')
      into w_des_tributo
         , w_para_intestazione
         , w_para_int_imposta_int
         , w_para_note_vers_ravv
         , w_para_int_imposta_calc
         , w_para_des_ris_cat
         , w_para_dati_dich
      from dual;
  exception
    when others then
      raise_application_error(-20999,'Verificare parametri modello ('||sqlerrm||')');
  end;
  --
  -- Selezione codici tributo per F24
  --
  begin
    select max(decode(tributo_f24,'3958',tributo_f24,null))
         , max(decode(tributo_f24,'3959',tributo_f24,null))
         , max(decode(tributo_f24,'3960',tributo_f24,null))
         , max(decode(tributo_f24,'3961',tributo_f24,null))
         , max(decode(tipo_codice,'I',tributo_f24,null))
         , max(decode(tipo_codice,'S',tributo_f24,null))
      into w_cf24_ab_princ
         , w_cf24_fabb_rurali
         , w_cf24_aree_fabb
         , w_cf24_altri_fabb
         , w_cf24_interessi
         , w_cf24_sanzioni
      from codici_f24
     where tipo_tributo = w_tipo_tributo
       and descrizione_titr = w_des_tributo;
  exception
    when others then
      w_cf24_ab_princ    := '3958';
      w_cf24_fabb_rurali := '3959';
      w_cf24_aree_fabb   := '3960';
      w_cf24_altri_fabb  := '3961';
      w_cf24_interessi   := '3962';
      w_cf24_sanzioni    := '3963';
  end;
  --
  -- Trattamento pratiche di liquidazione
  --
  for liq in ( select translate(sogg.cognome_nome, '/',' ') cognome_nome
                    , cont.cod_fiscale cod_fiscale
                    , sogg.ni
                    , upper(replace(sogg.cognome,' ','')) cognome
                    , upper(replace(sogg.nome,' ','')) nome
                    , sogg.data_nas
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
                                             ||decode(sogg.suffisso,null,'', '/'||sogg.suffisso)
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
                    , prtr.data_notifica data_notifica
                    , tist.descrizione stato_accertamento
                    , prtr.anno anno
                    , lpad(prtr.numero, 15) clnumero
                    , prtr.pratica
                    , prtr.data data_liq
                    , vers.data_pagam data_pag
                    , vers.imp_versato imp_ver
                    , to_number(decode(f_vers_cont_liq(prtr.anno,cont.cod_fiscale,prtr.data,w_tipo_tributo),0,null
                                      ,f_vers_cont_liq(prtr.anno,cont.cod_fiscale,prtr.data,w_tipo_tributo))) versamenti2
                    , decode(prtr.tipo_atto,null,'',tiat.descrizione) tipo_atto
                    , decode(prtr.motivo,null,''
                            ,'MOTIVAZIONE: ' || translate(prtr.motivo,chr(013)||chr(010),'  ')) motivo
                    , prtr.importo_totale             imp_cal
                    , rpad('TOTALE DOVUTO (ARROTONDATO)',67)  tot_desc
                    , decode(w_para_dati_dich
                            , 'NO', ''
                                  , rpad('Dovuto CALCOLATO PER L''ANNO DI RIFERIMENTO',43))
                                                        testo1
                    , decode(nvl(prtr.imposta_totale,0)
                            , 0, rpad(' ', 43)
                            , decode(w_para_dati_dich
                                    , 'NO', rpad('Dovuto '||w_para_des_ris_cat,43)
                                          , decode(nvl(prtr.imposta_totale,0),nvl(prtr.imposta_dovuta_totale,0),''
                                                  ,rpad('Dovuto '||w_para_des_ris_cat,43))))
                                                        testo2
                    , decode(w_para_dati_dich
                            , 'NO', ''
                            , lpad(decode(NVL(prtr.imposta_dovuta_totale,0)
                                 , 0, translate(to_char(f_round(prtr.imposta_totale,0),'99,999,999,990.00'), ',.', '.,')
                                 , nvl(prtr.imposta_totale,0) , translate(to_char(f_round(prtr.imposta_totale,0),'99,999,999,990.00'), ',.', '.,')
                                    , translate(to_char(f_round(prtr.imposta_dovuta_totale,0),'99,999,999,990.00'), ',.', '.,')),18))
                                                        imposta_totale1
                    , decode(w_para_dati_dich
                            , 'NO', ''
                            , lpad(translate(to_char(f_round(f_imposta_pratica(prtr.pratica,'D','A'),0),'99,999,999,990.00'), ',.', '.,'),18))
                                                        imposta_acconto1
                    , decode(w_para_dati_dich
                            , 'NO', ''
                            , lpad(translate(to_char(f_round(f_imposta_pratica(prtr.pratica,'D','S'),0),'99,999,999,990.00'), ',.', '.,'),18))
                                                        imposta_saldo1
                    , lpad(decode(nvl(prtr.imposta_totale,0)
                                 , 0, null
                                    , decode(w_para_dati_dich
                                            , 'NO', translate(to_char(f_round(prtr.imposta_totale,0),'99,999,999,990.00'), ',.', '.,')
                                                  , decode(nvl(prtr.imposta_totale,0),nvl(prtr.imposta_dovuta_totale,0),''
                                                          ,translate(to_char(f_round(prtr.imposta_totale,0),'99,999,999,990.00'), ',.', '.,'))))
                       ,18)
                                                        imposta_totale2
                    , lpad(decode(NVL(prtr.imposta_totale,0)
                                 , 0, null
                                    , decode(w_para_dati_dich
                                            , 'NO', translate(to_char(f_round(f_imposta_pratica(prtr.pratica,'C','A'),0),'99,999,999,990.00'), ',.', '.,')
                                                  , decode(nvl(prtr.imposta_totale,0),nvl(prtr.imposta_dovuta_totale,0),''
                                                          ,translate(to_char(f_round(f_imposta_pratica(prtr.pratica,'C','A'),0),'99,999,999,990.00'), ',.', '.,'))))
                       ,18)
                                                        imposta_acconto2
                    , lpad(decode(nvl(prtr.imposta_totale,0)
                                 , 0, NULL
                                    , decode(w_para_dati_dich
                                            , 'NO', translate(to_char(f_round(f_imposta_pratica(prtr.pratica,'C','S'),0),'99,999,999,990.00'), ',.', '.,')
                                                  , decode(nvl(prtr.imposta_totale,0),nvl(prtr.imposta_dovuta_totale,0),''
                                                          ,translate(to_char(f_round(f_imposta_pratica(prtr.pratica,'C','S'),0),'99,999,999,990.00'), ',.', '.,'))))
                       ,18)
                                                        imposta_saldo2
                    , rpad('TOTALE DOVUTO',45) l_importo_totale
                    , lpad(translate(to_char(f_round(prtr.importo_totale,1),'99,999,999,990.00'), ',.', '.,'),48) importo_totale
                    , rpad('TOTALE DOVUTO ARROTONDATO',45) l_importo_totale_arrotondato
                    , lpad(translate(to_char(round(prtr.importo_totale,0) ,'99,999,999,990.00'), ',.', '.,'),48) importo_totale_arrotondato
                    , decode(round(prtr.importo_ridotto,0)
                            ,round(prtr.importo_totale,0),null
                            , 'TOTALE CON ADESIONE FORMALE ARROTONDATO') l_importo_ridotto_arrotondato
                    , decode(round(prtr.importo_ridotto,0)
                            ,round(prtr.importo_totale,0), null
                            ,translate(to_char(f_round(prtr.importo_ridotto,1),'99,999,999,990.00'), ',.', '.,')) importo_ridotto
                    , decode(round(prtr.importo_ridotto,0)
                            ,round(prtr.importo_totale,0), null
                            ,translate(to_char(round(prtr.importo_ridotto,0) ,'99,999,999,990.00'), ',.', '.,')) importo_ridotto_arrotondato
                    , decode(f_round(prtr.importo_totale,1)
                            ,f_round(prtr.importo_ridotto,1),rpad('TOTALE (ARROTONDATO)',45)
                            ,rpad('TOTALE CON ADESIONE FORMALE ARROTONDATO',45)) tot_ad_form_arr
                 from ( select sum(nvl(decode(versamenti.pratica, null, 0, versamenti.importo_versato), 0)) imp_versato,
                               min(versamenti.data_pagamento) data_pagam,
                               versamenti.pratica pratica
                          from versamenti
                         where versamenti.tipo_tributo = w_tipo_tributo
                           and versamenti.anno between p_anno_iniz and p_anno_fine
                         group by versamenti.pratica ) vers,
                      pratiche_tributo prtr,
                      soggetti         sogg,
                      soggetti         sogg_p,
                      archivio_vie     arvi,
                      archivio_vie     arvi_p,
                      ad4_comuni       comu,
                      ad4_comuni       comu_p,
                      ad4_comuni       com_nas,
                      ad4_provincie    prov,
                      ad4_provincie    prov_p,
                      ad4_provincie    pro_nas,
                      ad4_stati_territori stte,
                      ad4_stati_territori stte_p,
                      contribuenti     cont,
                      tipi_stato       tist,
                      tipi_atto        tiat
                where vers.pratica(+)            = prtr.pratica
                  and sogg.ni                    = cont.ni
                  and sogg.cod_via               = arvi.cod_via (+)
                  and sogg_p.cod_via             = arvi_p.cod_via (+)
                  and sogg_p.ni (+)              = sogg.ni_presso
                  and sogg.cod_pro_res           = stte.stato_territorio (+)
                  and sogg.cod_pro_res           = comu.provincia_stato (+)
                  and sogg.cod_com_res           = comu.comune (+)
                  and sogg_p.cod_pro_res         = stte_p.stato_territorio (+)
                  and sogg_p.cod_pro_res         = comu_p.provincia_stato (+)
                  and sogg_p.cod_com_res         = comu_p.comune (+)
                  and sogg.cod_pro_nas           = com_nas.provincia_stato (+)
                  and sogg.cod_com_nas           = com_nas.comune (+)
                  and comu.provincia_stato       = prov.provincia (+)
                  and comu_p.provincia_stato     = prov_p.provincia (+)
                  and com_nas.provincia_stato    = pro_nas.provincia (+)
                  and cont.cod_fiscale           = prtr.cod_fiscale
                  and prtr.stato_accertamento    = tist.tipo_stato (+)
                  and prtr.tipo_atto             = tiat.tipo_atto (+)
                  and prtr.tipo_tributo          = w_tipo_tributo
                  -- aggiunte da Elisabetta per uniformare alla TARI la gestione del numero e data notifica
                  and prtr.numero                is not null
                  and prtr.data_notifica         is null
                  and prtr.tipo_pratica          = 'L'
                  and prtr.importo_totale        > 0
                  and nvl(prtr.stato_accertamento,'D') = nvl(p_tipo_stato,nvl(prtr.stato_accertamento,'D'))
                  and nvl(prtr.tipo_atto,-1)     = nvl(p_tipo_atto,nvl(prtr.tipo_atto,-1))
                  and prtr.anno between nvl(p_anno_iniz,0) and nvl(p_anno_fine,9999)
                  and prtr.data between nvl(p_data_iniz,to_date('01011980','ddmmyyyy'))
                                    and nvl(p_data_fine,to_date('31122200','ddmmyyyy'))
                  and lpad(nvl(prtr.numero,' '),15) between lpad(nvl(p_numero_iniz,' '),15)
                                                        and lpad(nvl(p_numero_fine,'ZZZZZZZZZZZZZZZ'),15)
                order by 1, 6, 5, 7 )         -- cognome e nome
  loop
    --
    -- Conteggio contribuenti
    --
    if liq.cod_fiscale <> w_cf_prec then
       w_cf_prec := liq.cod_fiscale;
       w_num_contribuenti := w_num_contribuenti + 1;
    end if;
    --
    w_conta_righe := w_conta_righe + 1;
    w_ind         := 0;
    riga_file.delete;
    --
    -- Stampa F24 - Intestazione
    --
    w_num_campi := 8;
    for w_num_campo in 1 .. w_num_campi
    loop
      w_ind := w_ind + 1;
      if w_num_campo = 1 then
         riga_file (w_ind) := liq.cod_fiscale;
      elsif w_num_campo = 2 then
         riga_file (w_ind) := liq.cognome;
      elsif w_num_campo = 3 then
         riga_file (w_ind) := liq.nome;
      elsif w_num_campo = 4 then
         riga_file (w_ind) := to_char(liq.data_nas,'ddmmyyyy');
      elsif w_num_campo = 5 then
         riga_file (w_ind) := liq.sesso;
      elsif w_num_campo = 6 then
         riga_file (w_ind) := liq.comune_nas;
      elsif w_num_campo = 7 then
         riga_file (w_ind) := liq.provincia_nas;
      elsif w_num_campo = 8 then
         riga_file (w_ind) := 'LIQP'||liq.anno||lpad(to_char(liq.pratica),10,'0');
      end if;
    end loop;
    --
    -- Stampa F24 - Righe dettaglio
    --
    w_tot_f24_importo := 0;
    w_ind_totale      := 0;
    w_conta_righe_f24 := 0;
    w_num_campi       := 7;
    for dett in (select nvl(sanz.cod_tributo_f24,decode(sanz.cod_sanzione, 98,w_cf24_interessi
                                                                         , 99,w_cf24_interessi
                                                                         ,198,w_cf24_interessi
                                                                         ,199,w_cf24_interessi
                                                                             ,w_cf24_sanzioni)) cod_tributo
                      , round(sum(decode(nvl(sanz.cod_tributo_f24,decode(sanz.cod_sanzione, 98,w_cf24_interessi
                                                                                          , 99,w_cf24_interessi
                                                                                          ,198,w_cf24_interessi
                                                                                          ,199,w_cf24_interessi
                                                                                              ,w_cf24_sanzioni))
                              ,w_cf24_interessi,sapr.importo
                                     ,sapr.importo * (100 - nvl(sapr.riduzione,0)) / 100)),0) importo
                   from sanzioni_pratica   sapr
                      , sanzioni           sanz
                  where sapr.pratica      = liq.pratica
                    and sapr.cod_sanzione = sanz.cod_sanzione
                    and sapr.tipo_tributo = sanz.tipo_tributo
               group by nvl(sanz.cod_tributo_f24,decode(sanz.cod_sanzione, 98,w_cf24_interessi
                                                                         , 99,w_cf24_interessi
                                                                         ,198,w_cf24_interessi
                                                                         ,199,w_cf24_interessi
                                                                             ,w_cf24_sanzioni))
                 having round(sum(decode(nvl(sanz.cod_tributo_f24,decode(sanz.cod_sanzione, 98,w_cf24_interessi
                                                                         , 99,w_cf24_interessi
                                                                         ,198,w_cf24_interessi
                                                                         ,199,w_cf24_interessi
                                                                             ,w_cf24_sanzioni))
                              ,w_cf24_interessi,sapr.importo
                                     ,sapr.importo * (100 - nvl(sapr.riduzione,0)) / 100)),0) > 0)
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
           riga_file (w_ind) := liq.anno;
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
    --
    -- Composizione righe di intestazione avviso
    --
    w_num_campi   := 9;
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
         riga_file (w_ind) := liq.cognome_nome;
      elsif w_num_campo = 3 then
         if liq.presso is null then
            w_ind := w_ind - 1;
         else
            riga_file (w_ind) := liq.presso;
         end if;
      elsif w_num_campo = 4 then
         riga_file (w_ind) := liq.indirizzo;
      elsif w_num_campo = 5 then
         riga_file (w_ind) := liq.comune;
      elsif w_num_campo = 6 then
         if liq.presso is null then
            riga_file (w_ind) := ' ';
            w_ind := w_ind + 1;
         end if;
         riga_file (w_ind) := liq.cod_fiscale;
      elsif w_num_campo = 7 then
         w_riga := w_para_intestazione||' '||w_des_tributo;
         if liq.clnumero is not null then
            w_riga := w_riga||' NUMERO '||liq.clnumero||' DEL '||
                      to_char(liq.data_liq,'dd/mm/yyyy')||' RELATIVO ALL''ANNO '||liq.anno;
         else
            w_riga := w_riga||' DEL '||
                      to_char(liq.data_liq,'dd/mm/yyyy')||' RELATIVO ALL''ANNO '||liq.anno;
         end if;
         riga_file (w_ind) := lpad(' ',trunc((99 - length(w_riga)) / 2))||w_riga;
      elsif w_num_campo = 8 then
         w_riga := '(Identificativo Operazione LIQP'||liq.anno||lpad(to_char(liq.pratica),10,'0')||')';
         riga_file (w_ind) := lpad(' ',trunc((99 - length(w_riga)) / 2))||w_riga;
      elsif w_num_campo = 9 then
         w_riga := 'DETTAGLIO IMMOBILI';
         riga_file (w_ind) := lpad(' ',trunc((99 - length(w_riga)) / 2))||w_riga;
      end if;
    end loop;
    --
    -- Trattamento oggetti accertamento
    --
    w_tot_imposta    := 0;
    --
    for ogg in ( select distinct
                        ogpr.oggetto_pratica
                       ,decode(f_conta_costi_storici(ogpr.oggetto_pratica)
                              ,0, ''
                              ,'[COSTI_STORICI')
                         costi_storici
                       ,decode(ogim.tipo_aliquota
                              ,null, ''
                              ,   ' ('
                               || trim(translate(to_char(nvl(ogim.aliquota, 0)
                                                        ,'99,999,999,990.00')
                                                ,',.'
                                                ,'.,'))
                               --|| '%'
                               ||')'
                               )
                         aliquota
                       ,trim(decode(ogim.tipo_aliquota
                                   ,null, null
                                   ,'ALIQUOTA APPLICATA: ' || tial.descrizione || ' - '))
                         st_tial
                       ,decode(ogim.aliquota_std,null,''
                                                ,' - (ALIQUOTA STANDARD '||trim(translate(to_char(ogim.aliquota_std
                                                        ,'99,999,999,990.00')
                                                ,',.'
                                                ,'.,'))
                               --|| '%'
                               ||')'
                               ) st_aliquota_std
                       ,ogge.oggetto oggetto
                       ,tiog.descrizione descr_tiog
                       ,lpad(nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto), 2) tipo_oggetto
                       ,decode(ogge.cod_via
                              ,null, indirizzo_localita
                              ,   denom_uff
                               || decode(ogge.num_civ, null, '', ', ' || ogge.num_civ)
                               || decode(ogge.suffisso, null, '', '/' || ogge.suffisso)
                               || decode(ogge.interno, null, '', ' int. ' || ogge.interno))
                         indirizzo_ogg
                       ,lpad(nvl(ogge.categoria_catasto, ' '), 4) cat
                       ,lpad(nvl(ogge.classe_catasto, ' '), 6) classe
                       ,lpad(nvl(ogge.partita, ' '), 8) partita
                       ,lpad(nvl(ogge.sezione, ' '), 4) sezione
                       ,lpad(nvl(ogge.foglio, ' '), 6) foglio
                       ,lpad(nvl(ogge.numero, ' '), 6) numero
                       ,lpad(nvl(ogge.subalterno, ' '), 4) subalterno
                       ,lpad(nvl(ogge.zona, ' '), 4) zona
                       ,lpad(nvl(ogge.protocollo_catasto, ' '), 6) prot_cat
                       ,lpad(nvl(to_char(ogge.anno_catasto), ' '), 4) anno_cat
                       ,translate(to_char(nvl(ogpr_dic.valore, 0), '99,999,999,990.00')
                                 ,',.'
                                 ,'.,')
                         valore_dic
                       ,'CALCOLATO PER L''ANNO DI RIFERIMENTO' st_valore_riv
                       ,translate(to_char(f_valore(ogpr_dic.valore
                                                  ,nvl(ogpr_dic.tipo_oggetto
                                                      ,ogge.tipo_oggetto)
                                                  ,prtr_dic.anno
                                                  ,ogim.anno
                                                  ,nvl(ogpr_dic.categoria_catasto
                                                      ,ogge.categoria_catasto)
                                                  ,prtr_dic.tipo_pratica
                                                  ,ogpr_dic.flag_valore_rivalutato)
                                         ,'99,999,999,990.00')
                                 ,',.'
                                 ,'.,')
                         valore_riv
                       ,translate(to_char(f_rendita(f_valore(ogpr_dic.valore
                                                            ,nvl(ogpr_dic.tipo_oggetto
                                                                ,ogge.tipo_oggetto)
                                                            ,prtr_dic.anno
                                                            ,ogim.anno
                                                            ,nvl(ogpr_dic.categoria_catasto
                                                                ,ogge.categoria_catasto)
                                                            ,prtr_dic.tipo_pratica
                                                            ,ogpr_dic.flag_valore_rivalutato)
                                                   ,nvl(ogpr_dic.tipo_oggetto
                                                       ,ogge.tipo_oggetto)
                                                   ,prtr.anno
                                                   ,nvl(ogpr_dic.categoria_catasto
                                                       ,ogge.categoria_catasto))
                                         ,'9,999,999,990.000')
                                 ,',.'
                                 ,'.,')
                         rendita_valore_riv
                       ,decode(ogpr.valore
                              ,null, w_para_des_ris_cat ,null) st_pre_riog
                       ,decode(ogpr.valore
                              ,null, '[RIOG'
                              ,decode(w_para_dati_dich,'NO',w_para_des_ris_cat
                                     ,decode(ogpr.valore
                                     ,ogpr_dic.valore, null
                                     ,f_valore(ogpr_dic.valore
                                              ,nvl(ogpr_dic.tipo_oggetto, ogge.tipo_oggetto)
                                              ,prtr_dic.anno
                                              ,ogim.anno
                                              ,nvl(ogpr_dic.categoria_catasto
                                                  ,ogge.categoria_catasto)
                                              ,prtr_dic.tipo_pratica
                                              ,ogpr_dic.flag_valore_rivalutato), null
                                     ,w_para_des_ris_cat)
                                     ))
                         st_valore_subase
                       ,decode(ogpr.valore
                              ,null, ''
                              ,decode(w_para_dati_dich,'NO',translate(to_char(ogpr.valore, '99,999,999,990.00')
                                               ,',.'
                                               ,'.,')
                                     ,decode(ogpr.valore
                                     ,ogpr_dic.valore, null
                                     ,f_valore(ogpr_dic.valore
                                              ,nvl(ogpr_dic.tipo_oggetto, ogge.tipo_oggetto)
                                              ,prtr_dic.anno
                                              ,ogim.anno
                                              ,nvl(ogpr_dic.categoria_catasto
                                                  ,ogge.categoria_catasto)
                                              ,prtr_dic.tipo_pratica
                                              ,ogpr_dic.flag_valore_rivalutato), null
                                     ,translate(to_char(ogpr.valore, '99,999,999,990.00')
                                               ,',.'
                                               ,'.,'))))
                         valore_subase
                       ,decode(ogpr.valore
                              ,null, ''
                              ,decode(w_para_dati_dich,'NO'
                                     ,decode(f_rendita_anno_riog(ogpr.oggetto, prtr.anno)
                                            ,null, translate(to_char(f_rendita(ogpr.valore
                                                                              ,nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                                                              ,prtr.anno
                                                                              ,nvl(ogpr.categoria_catasto
                                                                                   ,ogge.categoria_catasto)
                                                                              )
                                                              ,'9,999,999,990.000')
                                                      ,',.'
                                                      ,'.,')
                                            ,translate(to_char(f_rendita_anno_riog(ogpr.oggetto
                                                                                  ,prtr.anno)
                                                              ,'9,999,999,990.000')
                                                      ,',.'
                                                      ,'.,'))
                                     ,decode(ogpr.valore
                                     ,ogpr_dic.valore, null
                                     ,f_valore(ogpr_dic.valore
                                              ,nvl(ogpr_dic.tipo_oggetto, ogge.tipo_oggetto)
                                              ,prtr_dic.anno
                                              ,ogim.anno
                                              ,nvl(ogpr_dic.categoria_catasto
                                                  ,ogge.categoria_catasto)
                                              ,prtr_dic.tipo_pratica
                                              ,ogpr_dic.flag_valore_rivalutato), null
                                     ,decode(f_rendita_anno_riog(ogpr.oggetto, prtr.anno)
                                            ,null, ''
                                            ,translate(to_char(f_rendita_anno_riog(ogpr.oggetto
                                                                                  ,prtr.anno)
                                                              ,'9,999,999,990.000')
                                                      ,',.'
                                                      ,'.,')))))
                         rendita_valore_subase
                       ,decode(ogco.perc_possesso
                              ,null, ''
                              ,   ': '
                               || trim(translate(to_char(nvl(ogco.perc_possesso, 0)
                                                        ,'99,999,999,990.00')
                                                ,',.'
                                                ,'.,')))
                         perc_poss
                       ,': ' || to_char(nvl(ogco.mesi_possesso, 12), '99') mp
                       ,decode(nvl(ogco.mesi_riduzione, 0)
                              ,0, ''
                              ,': ' || to_char(ogco.mesi_riduzione, '99'))
                         mr
                       ,decode(nvl(ogco.mesi_esclusione, 0)
                              ,0, ''
                              ,': ' || to_char(ogco.mesi_esclusione, '99'))
                         me
                       ,decode(ogim.detrazione, null, '', 'DETRAZIONE APPLICATA: ') detr
                       ,decode(ogim.detrazione
                              ,null, ''
                              ,trim(translate(to_char(nvl(ogim.detrazione, 0)
                                                     ,'99,999,999,990.00')
                                             ,',.'
                                             ,'.,')))
                         detrazione
                       ,rpad(decode(ogco_dic.detrazione, null, '', 'DETRAZIONE DICHIARATA')
                            ,54)
                         detr_dic
                       ,decode(ogco_dic.detrazione
                              ,null, ''
                              ,translate(to_char(nvl(ogco_dic.detrazione, 0)
                                                ,'99,999,999,990.00')
                                        ,',.'
                                        ,'.,'))
                         detrazione_dic
                       ,prtr.anno anno
                       ,rpad('VALORE DICHIARATO', 54) st_valdic
                       ,'PERCENTUALE POSSESSO' st_percposs
                       ,'MESI POSSESSO' st_mesposs
                       ,decode(nvl(ogco.mesi_riduzione, 0), 0, '', 'MESI RIDUZIONE') st_mesrid
                       ,decode(nvl(ogco.mesi_esclusione, 0), 0, '', 'MESI ESCLUSIONE')
                         st_mesescl
                       ,decode(ogpr.valore
                              ,null, ''
                              ,decode(w_para_dati_dich,'NO',lpad(nvl(f_cate_riog_null(ogpr.oggetto, prtr.anno),
                                                                     nvl(ogpr.categoria_catasto
                                                                        ,ogge.categoria_catasto)), 18)
                              ,decode(ogpr.valore
                                     ,ogpr_dic.valore, null
                                     ,f_valore(ogpr_dic.valore
                                              ,nvl(ogpr_dic.tipo_oggetto, ogge.tipo_oggetto)
                                              ,prtr_dic.anno
                                              ,ogim.anno
                                              ,nvl(ogpr_dic.categoria_catasto
                                                  ,ogge.categoria_catasto)
                                              ,prtr_dic.tipo_pratica
                                              ,ogpr_dic.flag_valore_rivalutato), null
                                     ,lpad(nvl(f_cate_riog_null(ogpr.oggetto, prtr.anno), ' '), 18)))) cat_ren
                       ,decode(ogpr_dic.categoria_catasto
                              ,null, null
                              ,decode(w_para_dati_dich,'NO',''
                              ,rpad('CAT. CATASTALE DICHIARATA', 54)))
                         st_catdic
                       ,decode(w_para_dati_dich,'NO','',
                               lpad(nvl(ogpr_dic.categoria_catasto, ' '), 18)) cat_dic
                       ,decode(w_para_dati_dich,'NO','',
                               decode(nvl(ogim.imposta_dovuta, 0)
                                     ,nvl(ogim.imposta, 0), w_para_int_imposta_calc||decode(nvl(ogim.imposta_dovuta, 0),0,' : 0','')
                                     ,w_para_int_imposta_calc))
                        imposta_testo1
                       ,decode(w_para_dati_dich,'NO','',
                               decode(nvl(ogim.imposta_dovuta, 0),0,'','   Dettaglio codici tributo per versamento:')) imposta_subtesto1
                       ,decode(w_para_dati_dich,'NO','',
                               decode(nvl(ogim.imposta_dovuta, 0),0,'',lpad(translate(to_char(nvl(ogim.imposta_dovuta, 0)
                                                                                             ,'99,999,999,990.00')
                                                                                      ,',.','.,')
                                                                           ,72)))          importo1
                       ,decode(w_para_dati_dich,'NO','',
                               decode(nvl(ogim.imposta_dovuta, 0),0,'',lpad('_________________', 72))) linea_importo1
                       ,decode(w_para_dati_dich,'NO'
                              ,'IMPOSTA CALCOLATA '||w_para_des_ris_cat||decode(nvl(ogim.imposta_dovuta, 0),0,' : 0','')
                              ,decode(nvl(ogim.imposta, 0), nvl(ogim.imposta_dovuta, 0), null
                              ,'IMPOSTA CALCOLATA '||w_para_des_ris_cat||decode(nvl(ogim.imposta_dovuta, 0),0,' : 0','')))
                        imposta_testo2
                       ,decode(w_para_dati_dich,'NO'
                              ,'   Dettaglio codici tributo per versamento:'
                              ,decode(nvl(ogim.imposta, 0), nvl(ogim.imposta_dovuta, 0), null
                                     ,'   Dettaglio codici tributo per versamento:')) imposta_subtesto2
                       ,decode(w_para_dati_dich,'NO'
                              ,lpad('_________________', 72)
                              ,decode(nvl(ogim.imposta, 0), nvl(ogim.imposta_dovuta, 0), null
                                     ,lpad('_________________', 72))) linea_importo2
                       ,decode(w_para_dati_dich,'NO'
                              ,decode(nvl(ogim.imposta, 0),0,'',lpad(translate(to_char(nvl(ogim.imposta, 0)
                                                                                             ,'99,999,999,990.00')
                                                                                      ,',.','.,')
                                                                           ,72))
                              ,decode(nvl(ogim.imposta, 0)
                              ,nvl(ogim.imposta_dovuta, 0), null
                              ,lpad(translate(to_char(nvl(ogim.imposta, 0)
                                                     ,'99,999,999,990.00')
                                             ,',.'
                                             ,'.,')
                                   ,72)))                             importo2
                       ,ogpr.note note
                       ,decode(ogim.tipo_rapporto,'D','PROPRIETARIO   QUOTA: '||
                               decode(nvl(ogim.mesi_affitto,0),0,'100,00%',
                                      translate(to_char(100 - nvl(f_get_perc_occupante(prtr.tipo_tributo,prtr.anno,1),0),'990.00'),',.','.,')||'%'||
                                      decode(nvl(ogim.mesi_possesso,12),nvl(ogim.mesi_affitto,0),'',
                                             ' PER '||nvl(ogim.mesi_affitto,0)||' MESI - 100,00% PER '||
                                  to_char(nvl(ogim.mesi_possesso,12) - nvl(ogim.mesi_affitto,0))||' MESI')),
                               'A','OCCUPANTE   QUOTA: '||translate(to_char(nvl(ogim.percentuale,100),'990.00'),',.','.,')||'%','')
                          tipo_rapporto
                       ,' ' x
                   from tipi_aliquota        tial
                       ,archivio_vie         arvi
                       ,tipi_oggetto         tiog
                       ,oggetti              ogge
                       ,oggetti_contribuente ogco
                       ,oggetti_pratica      ogpr
                       ,oggetti_pratica      ogpr_dic
                       ,pratiche_tributo     prtr_dic
                       ,oggetti_contribuente ogco_dic
                       ,oggetti_imposta      ogim
                       ,pratiche_tributo     prtr
                  where tial.tipo_aliquota       = nvl(ogim.tipo_aliquota, tial.tipo_aliquota)
                    and tiog.tipo_oggetto        = nvl(ogpr.tipo_oggetto
                                                      ,nvl(ogpr_dic.tipo_oggetto, ogge.tipo_oggetto))
                    and ogim.cod_fiscale         = ogco.cod_fiscale
                    and ogim.oggetto_pratica     = ogco.oggetto_pratica
                    and ogge.oggetto             = ogpr.oggetto
                    and ogpr_dic.oggetto_pratica = ogpr.oggetto_pratica_rif
                    and prtr_dic.pratica         = ogpr_dic.pratica
                    and ogpr_dic.oggetto_pratica = ogco_dic.oggetto_pratica
                    and ogco_dic.cod_fiscale     = liq.cod_fiscale
                    and ogim.anno                = prtr.anno
                    and arvi.cod_via(+)          = ogge.cod_via
                    and ogpr.pratica             = prtr.pratica
                    and ogpr.oggetto_pratica     = ogco.oggetto_pratica
                    and ogco.cod_fiscale         = liq.cod_fiscale
                    and prtr.pratica             = liq.pratica
                    and tial.tipo_tributo        = prtr.tipo_tributo
               order by ogge.oggetto
                       ,lpad(nvl(ogge.classe_catasto, ' '), 6)
                       ,lpad(nvl(ogge.sezione, ' '), 4)
                       ,lpad(nvl(ogge.foglio, ' '), 6)
                       ,lpad(nvl(ogge.numero, ' '), 6)
                       ,lpad(nvl(ogge.subalterno, ' '), 4)
               )
    loop
      w_num_campi      := 6;
      for w_num_campo in 1..w_num_campi
      loop
        w_ind := w_ind + 1;
        if w_num_campo = 1 then
           riga_file (w_ind) := ogg.descr_tiog||'       Indirizzo: '||ogg.indirizzo_ogg;
        elsif w_num_campo = 2 then
           riga_file (w_ind) := 'Cat. Classe  Partita Sez. Foglio Numero Sub.  Prot. Anno';
        elsif w_num_campo = 3 then
           riga_file (w_ind) := ogg.cat||' '||ogg.classe||' '||ogg.partita||' '||ogg.sezione||' '||ogg.foglio||' '||
                                ogg.numero||' '||ogg.subalterno||' '||ogg.prot_cat||' '||ogg.anno_cat;
        elsif w_num_campo = 4 then
           riga_file (w_ind) := ' ';
        elsif w_num_campo = 5 then
           riga_file (w_ind) := lpad(' ',50)||'VALORE              RENDITA         CATEGORIA';
        elsif w_num_campo = 6 then
           riga_file (w_ind) := ogg.st_valore_riv||'   '||ogg.valore_riv||'   '||ogg.rendita_valore_riv||ogg.cat_dic;
        end if;
      end loop;
      --
      -- Trattamento RIOG
      --
      if ogg.st_valore_subase = '[RIOG' then
         w_ind := w_ind + 1;
         riga_file (w_ind) := ogg.st_pre_riog;
         for riog in (select distinct
                             translate(to_char(f_round(nvl(riog.rendita,0) * decode(cat.tipo_oggetto,1,nvl(molt.moltiplicatore,1),3,nvl(molt.moltiplicatore,1),1) * (100 + rire.aliquota) / 100, 2),'99,999,999,990.00'), ',.', '.,')
                                                   valore
                           , lpad(ltrim(translate(to_char(riog.rendita,'99,999,999,990.00'), ',.', '.,')),21,' ')  rendita
                           , to_char(riog.inizio_validita,'dd/mm/yyyy')  inizio_validita
                           , to_char(riog.fine_validita,'dd/mm/yyyy')    fine_validita
                           , lpad(cat.categoria_catasto,18,' ') categoria_catasto
                        from riferimenti_oggetto   riog
                           , moltiplicatori        molt
                           , rivalutazioni_rendita rire
                           , (select nvl(riog2.categoria_catasto,nvl(ogpr2.categoria_catasto,ogge2.categoria_catasto)) categoria_catasto
                                   , riog2.inizio_validita inizio_validita
                                   , nvl(ogpr2.tipo_oggetto,ogge2.tipo_oggetto) tipo_oggetto
                                from riferimenti_oggetto riog2
                                   , oggetti_pratica     ogpr2
                                   , oggetti             ogge2
                               where riog2.oggetto = ogg.oggetto
                                 and ogpr2.oggetto = ogg.oggetto
                                 and ogpr2.pratica = liq.pratica
                                 and ogge2.oggetto = ogg.oggetto
                            order by riog2.inizio_validita)
                                             cat
                       where cat.categoria_catasto = molt.categoria_catasto (+)
                         and cat.inizio_validita   = riog.inizio_validita
                         and molt.anno (+)         = liq.anno
                         and riog.oggetto          = ogg.oggetto
                         and rire.anno             = liq.anno
                         and rire.tipo_oggetto     = cat.tipo_oggetto
                         and liq.anno              between riog.da_anno and riog.a_anno
                      order by 3
                     )
         loop
           w_ind := w_ind + 1;
           riga_file (w_ind) := '   Dal '||riog.inizio_validita||'  al '||riog.fine_validita||'      '||riog.valore||riog.rendita||riog.categoria_catasto;
         end loop;
      else
         w_ind := w_ind + 1;
         riga_file (w_ind) := ogg.st_valore_subase||'   '||ogg.valore_subase||'   '||ogg.rendita_valore_subase||ogg.cat_ren;
      end if;
      --
      w_num_campi := 7;
      for w_num_campo in 1..w_num_campi
      loop
        w_ind := w_ind + 1;
        if w_num_campo = 1 then
           riga_file (w_ind) := ogg.st_percposs||ogg.perc_poss||'%';
        elsif w_num_campo = 2 then
           riga_file (w_ind) := ogg.st_mesposs||ogg.mp||'   '||ogg.st_mesescl||ogg.me||'   '||ogg.st_mesrid||ogg.mr;
        elsif w_num_campo = 3 then
           riga_file (w_ind) := ogg.tipo_rapporto;
        elsif w_num_campo = 4 then
           riga_file (w_ind) := ogg.detr||ogg.detrazione;
        elsif w_num_campo = 5 then
           riga_file (w_ind) := ogg.st_tial||ogg.aliquota||ogg.st_aliquota_std;
        elsif w_num_campo = 6 then
           riga_file (w_ind) := ogg.imposta_testo1; --||'         '||ogg.importo1;
        elsif w_num_campo = 7 then
           riga_file (w_ind) := ogg.imposta_subtesto1;
        end if;
      end loop;
      --
      -- Trattamento codici tributo dettaglio
      --
      for cotr in (select translate (to_char (sum (decode (ogim.tipo_aliquota,
                                                           2, nvl (ogim.imposta_dovuta, 0),
                                                           0
                                                          )
                                                  ),
                                              '99,999,999,990.00'
                                             ),
                                     ',.',
                                     '.,'
                                    ) imposta,
                          w_cf24_ab_princ codice_tributo,
                          rpad ('TASI - Abitazioni Principali', 44) des_tributo
                     from oggetti_imposta ogim, oggetti_pratica ogpr, oggetti ogge
                    where ogpr.oggetto_pratica = ogim.oggetto_pratica
                      and ogpr.oggetto = ogge.oggetto
                      and ogpr.pratica = liq.pratica
                      and ogpr.oggetto_pratica = ogg.oggetto_pratica
                      and ogim.tipo_aliquota = 2
                      and w_para_dati_dich = 'SI'
                   having sum (nvl (ogim.imposta_dovuta, 0)) != 0
                   union
                   select translate
                             (to_char (sum (decode (ogim.tipo_aliquota,
                                                    2, 0,
                                                    decode (nvl (ogpr.tipo_oggetto,
                                                                 ogge.tipo_oggetto
                                                                ),
                                                            1, 0,
                                                            2, 0,
                                                            decode (aliquota_erariale,
                                                                    null, nvl
                                                                            (ogim.imposta_dovuta,
                                                                             0
                                                                            ),
                                                                    0
                                                                   )
                                                           )
                                                   )
                                           ),
                                       '99,999,999,990.00'
                                      ),
                              ',.',
                              '.,'
                             ) imposta_rur_3913,
                          w_cf24_fabb_rurali codice_tributo,
                          rpad ('TASI - Fabbricati Rurali', 44) des_tributo
                     from OGGETTI_IMPOSTA ogim, OGGETTI_PRATICA ogpr, OGGETTI ogge
                    where ogpr.oggetto_pratica = ogim.oggetto_pratica
                      and ogpr.oggetto = ogge.oggetto
                      and ogpr.pratica = liq.pratica
                      and ogpr.oggetto_pratica = ogg.oggetto_pratica
                      and ogim.tipo_aliquota != 2
                      and nvl (ogpr.tipo_oggetto, ogge.tipo_oggetto) not in (1, 2)
                      and w_para_dati_dich = 'SI'
                   having sum (nvl (ogim.imposta_dovuta, 0)) != 0
                      and sum (decode (aliquota_erariale, null, nvl (ogim.imposta_dovuta, 0), 0)) !=
                                                                                                0
                   union
                   select translate
                             (to_char (sum (decode (nvl (ogpr.tipo_oggetto, ogge.tipo_oggetto),
                                                    2, nvl (ogim.imposta_dovuta, 0)
                                                     - nvl (ogim.imposta_erariale_dovuta, 0),
                                                    0
                                                   )
                                           ),
                                       '99,999,999,990.00'
                                      ),
                              ',.',
                              '.,'
                             ) imposta_aree_com_3916,
                          w_cf24_aree_fabb codice_tributo,
                          rpad ('TASI - Aree Fabbricabili', 44) des_tributo
                     from oggetti_imposta ogim, oggetti_pratica ogpr, oggetti ogge
                    where ogpr.oggetto_pratica = ogim.oggetto_pratica
                      and ogpr.oggetto = ogge.oggetto
                      and ogpr.pratica = liq.pratica
                      and ogpr.oggetto_pratica = ogg.oggetto_pratica
                      and nvl (ogpr.tipo_oggetto, ogge.tipo_oggetto) = 2
                      and w_para_dati_dich = 'SI'
                   having sum (nvl (ogim.imposta_dovuta, 0) - NVL (ogim.imposta_erariale_dovuta, 0)) !=
                                                                                                0
                   union
                   select translate
                                  (to_char (f_altri_importo (liq.pratica,
                                                             ogg.oggetto_pratica,
                                                             'COMUNE',
                                                             ogpr.anno,
                                                             'DOVUTA'
                                                            ),
                                            '99,999,999,990.00'
                                           ),
                                   ',.',
                                   '.,'
                                  ) imposta_altri_com_3918,
                          w_cf24_altri_fabb codice_tributo,
                          rpad ('TASI - Altri Fabbricati', 44) des_tributo
                     from oggetti_imposta ogim, oggetti_pratica ogpr, oggetti ogge
                    where ogpr.oggetto_pratica = ogim.oggetto_pratica
                      and ogpr.oggetto = ogge.oggetto
                      and ogpr.pratica = liq.pratica
                      and ogpr.oggetto_pratica = ogg.oggetto_pratica
                      and ogim.tipo_aliquota != 2
                      and nvl (ogpr.tipo_oggetto, ogge.tipo_oggetto) not in (1, 2)
                      and aliquota_erariale is not null
                      and f_altri_importo (liq.pratica, ogg.oggetto_pratica, 'COMUNE', ogpr.anno, 'DOVUTA') > 0
                      and w_para_dati_dich = 'SI'
                   order by 2)
      loop
        w_ind := w_ind + 1;
        riga_file (w_ind) := '   '||cotr.codice_tributo||'  '||cotr.des_tributo||' '||cotr.imposta;
      end loop;
      --
      w_num_campi := 4;
      for w_num_campo in 1..w_num_campi
      loop
        w_ind := w_ind + 1;
        if w_num_campo = 1 then
           riga_file (w_ind) := ogg.linea_importo1;
        elsif w_num_campo = 2 then
           riga_file (w_ind) := lpad(ogg.importo1,72);
        elsif w_num_campo = 3 then
           riga_file (w_ind) := ogg.imposta_testo2;
        elsif w_num_campo = 4 then
           riga_file (w_ind) := ogg.imposta_subtesto2;
        end if;
      end loop;
      --
      -- Trattamento codici tributo in caso di rendita
      --
      for cotr in (select translate(to_char(sum(decode(ogim.tipo_aliquota,
                                                       2, nvl(ogim.imposta, 0),
                                                       0
                                                      )
                                               ),
                                           '99,999,999,990.00'
                                           ),
                                     ',.',
                                     '.,'
                                    ) imposta,
                          w_cf24_ab_princ codice_tributo,
                          rpad('TASI - Abitazioni Principali', 44) des_tributo
                     from OGGETTI_IMPOSTA ogim, OGGETTI_PRATICA ogpr, oggetti ogge
                    where ogpr.oggetto_pratica = ogim.oggetto_pratica
                      and ogpr.oggetto         = ogge.oggetto
                      and ogpr.pratica         = liq.pratica
                      and ogpr.oggetto_pratica = ogg.oggetto_pratica
                      and ogim.tipo_aliquota   = 2
                      and (nvl(w_para_dati_dich,'NO') = 'NO' or
                           nvl(ogim.imposta_dovuta, 0) != nvl(ogim.imposta, 0))
                   having sum(nvl(ogim.imposta, 0)) != 0
                   union
                   select translate(to_char(sum(decode(ogim.tipo_aliquota,
                                                       2, 0,
                                                       decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto),
                                                              1, 0,
                                                              2, 0,
                                                              decode(aliquota_erariale,
                                                                     null,nvl(ogim.imposta,0),
                                                                     0
                                                                    )
                                                             )
                                                      )
                                               ),
                                            '99,999,999,990.00'
                                           ),
                                    ',.',
                                    '.,'
                                   ) imposta_rurali,
                          w_cf24_fabb_rurali codice_tributo,
                          rpad('TASI - Fabbricati Rurali', 44) des_tributo
                     from OGGETTI_IMPOSTA ogim, OGGETTI_PRATICA ogpr, oggetti ogge
                    where ogpr.oggetto_pratica = ogim.oggetto_pratica
                      and ogpr.oggetto         = ogge.oggetto
                      and ogpr.pratica         = liq.pratica
                      and ogpr.oggetto_pratica = ogg.oggetto_pratica
                      and ogim.tipo_aliquota  != 2
                      and nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto) not in (1, 2)
                      and (w_para_dati_dich = 'NO' or
                           nvl(ogim.imposta_dovuta, 0) != nvl(ogim.imposta, 0))
                   having sum(nvl(ogim.imposta, 0)) != 0
                      and sum(decode(aliquota_erariale, NULL, nvl(ogim.imposta, 0), 0)) != 0
                   union
                   select translate(to_char(sum(decode(nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto),
                                                       2, nvl(ogim.imposta, 0)
                                                          - nvl(ogim.imposta_erariale, 0),
                                                       0
                                                      )
                                               ),
                                            '99,999,999,990.00'
                                           ),
                                    ',.',
                                    '.,'
                                   ) imposta_aree_fabbr,
                          w_cf24_aree_fabb codice_tributo,
                          rpad('TASI - Aree Fabbricabili', 44) des_tributo
                     from OGGETTI_IMPOSTA ogim, OGGETTI_PRATICA ogpr, oggetti ogge
                    where ogpr.oggetto_pratica = ogim.oggetto_pratica
                      and ogpr.oggetto         = ogge.oggetto
                      and ogpr.pratica         = liq.pratica
                      and ogpr.oggetto_pratica = ogg.oggetto_pratica
                      and nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto) = 2
                      and (w_para_dati_dich = 'NO' or
                           nvl(ogim.imposta_dovuta, 0) != nvl(ogim.imposta, 0))
                   having sum(nvl(ogim.imposta, 0) - nvl(ogim.imposta_erariale, 0)) != 0
                   union
                   select translate(to_char(f_altri_importo (liq.pratica,
                                                             ogg.oggetto_pratica,
                                                             'COMUNE',
                                                             ogpr.anno,
                                                             'RENDITA'
                                                            ),
                                            '99,999,999,990.00'
                                           ),
                                    ',.',
                                    '.,'
                                   ) imposta_altri_fabbr,
                          w_cf24_altri_fabb codice_tributo,
                          rpad('TASI - Altri Fabbricati', 44) des_tributo
                     from OGGETTI_IMPOSTA ogim, OGGETTI_PRATICA ogpr, oggetti ogge
                    where ogpr.oggetto_pratica = ogim.oggetto_pratica
                      and ogpr.oggetto         = ogge.oggetto
                      and ogpr.pratica         = liq.pratica
                      and ogpr.oggetto_pratica = ogg.oggetto_pratica
                      and ogim.tipo_aliquota  != 2
                      and nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto) not in (1, 2)
                      and aliquota_erariale IS NOT NULL
                      and (w_para_dati_dich = 'NO' or
                           nvl(ogim.imposta_dovuta, 0) != nvl(ogim.imposta, 0))
                      and f_altri_importo (liq.pratica,ogg.oggetto_pratica,'COMUNE',ogpr.anno,'RENDITA') > 0
                   order by 2)
      loop
        w_ind := w_ind + 1;
        riga_file (w_ind) := '   '||cotr.codice_tributo||'  '||cotr.des_tributo||' '||cotr.imposta;
      end loop;
      --
      w_num_campi := 3;
      if ogg.importo2 is not null then
         for w_num_campo in 1..w_num_campi
         loop
           w_ind := w_ind + 1;
           if w_num_campo = 1 then
              riga_file (w_ind) := ogg.linea_importo2;
           elsif w_num_campo = 2 then
              riga_file (w_ind) := ogg.importo2;
           else
              riga_file (w_ind) := ogg.note;
           end if;
         end loop;
      end if;
      --
      w_prima_riga := 'S';
      if ogg.costi_storici is not null then
         for cost in (select 1 ordinamento
                            ,rpad(to_char(cost.anno),23,' ') anno_costo
                            ,aliq.anno anno_imposta
                            ,translate(to_char(cost.costo,'99,999,999,990.00'), ',.', '.,') costo_storico
                            ,translate(to_char(f_valore_d_tab(cost.oggetto_pratica,aliq.anno,cost.anno,'S','S')
                                              ,'99,999,999,990.00'), ',.', '.,') valore
                        from costi_storici        cost
                            ,aliquote             aliq
                       where cost.oggetto_pratica     = ogg.oggetto_pratica
                         and cost.anno                < aliq.anno
                         and aliq.anno          between liq.anno and liq.anno
                         and aliq.tipo_aliquota       = 1
                         and aliq.tipo_tributo        = w_tipo_tributo
                         and cost.anno                < liq.anno
                       union all
                      select distinct
                             2
                            ,'Totale Costo Storico   '   anno_costo
                            ,aliq.anno anno_imposta
                            ,translate(to_char(f_valore_d_tab(cost.oggetto_pratica,aliq.anno,0,'N','N')
                                              ,'99,999,999,990.00'), ',.', '.,')    costo_storico
                            ,lpad(' ',18,' ') valore
                        from costi_storici        cost
                            ,aliquote             aliq
                       where cost.oggetto_pratica     = ogg.oggetto_pratica
                         and cost.anno                < aliq.anno
                         and aliq.anno          between w_anno_da and liq.anno
                         and aliq.tipo_aliquota       = 1
                         and aliq.tipo_tributo        = w_tipo_tributo
                         and cost.anno                < liq.anno
                       union all
                      select distinct
                             3
                            ,'Totale Costo Rivalutato'   anno_costo
                            ,aliq.anno anno_imposta
                            ,lpad(' ',18,' ')   costo_storico
                            ,translate(to_char(f_valore_d_tab(cost.oggetto_pratica,aliq.anno,0,'S','N')
                                              ,'99,999,999,990.00'), ',.', '.,') valore
                        from costi_storici        cost
                            ,aliquote             aliq
                       where cost.oggetto_pratica     = ogg.oggetto_pratica
                         and cost.anno                < aliq.anno
                         and aliq.anno          between w_anno_da and liq.anno
                         and aliq.tipo_aliquota       = 1
                         and aliq.tipo_tributo        = w_tipo_tributo
                         and cost.anno                < liq.anno
                       union all
                      select 4
                            ,'Aliquota TASI          '   anno_costo
                            ,aliq.anno anno_imposta
                            ,lpad(' ',18,' ')   costo_storico
                            ,lpad(to_char(aliq.aliquota),18,' ')  valore
                        from aliquote             aliq
                       where aliq.anno          between w_anno_da and liq.anno
                         and aliq.tipo_aliquota       = 1
                         and aliq.tipo_tributo        = w_tipo_tributo
                       union all
                      select distinct
                             5
                            ,'Imposta Dovuta         '   anno_costo
                            ,aliq.anno anno_imposta
                            ,lpad(' ',18,' ') costo_storico
                            ,translate(to_char(round(f_valore_d_tab(cost.oggetto_pratica,aliq.anno,0,'S','N') *
                                                     nvl(aliq.aliquota,0) / 1000,2)
                                               ,'99,999,999,990.00'), ',.', '.,') valore
                        from costi_storici        cost
                            ,aliquote             aliq
                       where cost.oggetto_pratica     = ogg.oggetto_pratica
                         and cost.anno                < aliq.anno
                         and aliq.anno          between w_anno_da and liq.anno
                         and aliq.tipo_aliquota       = 1
                         and aliq.tipo_tributo        = w_tipo_tributo
                         and cost.anno                < liq.anno
                       order by 1,2,3)
         loop
           if w_prima_riga = 'S' then
              w_prima_riga := 'N';
              w_ind := w_ind + 1;
              w_riga := 'VALORI CONTABILI';
              riga_file (w_ind) := lpad(' ',trunc((99 - length(w_riga)) / 2))||w_riga;
              w_ind := w_ind + 1;
              riga_file (w_ind) := 'ANNO                         COSTO STORICO             VALORE';
           end if;
           --
           w_ind := w_ind + 1;
           riga_file (w_ind) := cost.anno_costo||' '||cost.costo_storico||' '||cost.valore;
         end loop;
      end if;
      --
      w_ind := w_ind + 1;
      riga_file (w_ind) := '-------------------------------------------------------------------------------------------------';
    end loop;
    --
    -- Stampa totali oggetti
    --
    w_ind := w_ind + 1;
    riga_file (w_ind) := 'IMPOSTA COMPLESSIVA                                   ACCONTO             SALDO            TOTALE';
    w_ind := w_ind + 1;
    riga_file (w_ind) := liq.testo1||liq.imposta_acconto1||liq.imposta_saldo1||liq.imposta_totale1;
    w_ind := w_ind + 1;
    riga_file (w_ind) := liq.testo2||liq.imposta_acconto2||liq.imposta_saldo2||liq.imposta_totale2;
    --
    -- Trattamento versamenti
    --
    w_prima_riga       := 'S';
    w_tot_versato      := 0;
    w_ind := w_ind + 1;
    riga_file (w_ind) := ' ';
    w_ind := w_ind + 1;
    w_riga := 'DETTAGLIO VERSAMENTI';
    riga_file (w_ind) := lpad(' ',trunc((99 - length(w_riga)) / 2))||w_riga;
    --
    for vers in (select vers.importo_versato
                      , nvl(to_char(vers.data_pagamento, 'dd/mm/yyyy'), '          ') data_versamento
                      , decode(vers.tipo_versamento,'A','ACCONTO '
                                                   ,'S','SALDO   '
                                                   ,'U','UNICO   '
                                                       ,'      ') tipo_versamento
                       ,nvl(to_char(f_scadenza(vers.anno
                                              ,w_tipo_tributo
                                              ,vers.tipo_versamento
                                              ,vers.cod_fiscale)
                                   ,'dd/mm/yyyy')
                           ,'          '
                           ) data_scadenza
                       ,decode(sign(trunc(f_scadenza(vers.anno
                                                    ,w_tipo_tributo
                                                    ,vers.tipo_versamento
                                                    ,vers.cod_fiscale)
                                    - vers.data_pagamento))
                              ,-1,lpad(trunc(f_scadenza(vers.anno
                                                       ,w_tipo_tributo
                                                       ,vers.tipo_versamento
                                                       ,vers.cod_fiscale)
                                            - vers.data_pagamento),6)
                             ,'') gio_dif
                       ,1 ord
                   from versamenti vers
                  where vers.pratica is null
                    and vers.anno = liq.anno
                    and vers.cod_fiscale = liq.cod_fiscale
                    and vers.tipo_tributo = w_tipo_tributo
                    and vers.data_pagamento <= (select min(prtr.data)
                                                  from pratiche_tributo prtr
                                                 where prtr.pratica = liq.pratica)
                 union
                 select f_importo_vers_ravv_dett(prtr.cod_fiscale
                                                ,w_tipo_tributo
                                                ,prtr.anno
                                                ,'U'
                                                ,'TOT'
                                                ,data_elab.data)
                       ,nvl(to_char(f_data_max_vers_ravv(prtr.cod_fiscale
                                                        ,w_tipo_tributo
                                                        ,prtr.anno
                                                        ,'U')
                                   ,'dd/mm/yyyy')
                           ,'          ')
                       ,'RAVVED.*'
                       ,'          '
                       ,''
                       ,2
                   from pratiche_tributo prtr
                       ,(select min(prtr.data) data
                           from pratiche_tributo prtr
                          where prtr.pratica = liq.pratica) data_elab
                  where prtr.tipo_pratica = 'V'
                    and prtr.anno = liq.anno
                    and prtr.cod_fiscale = liq.cod_fiscale
                    and prtr.numero is not null
                    and prtr.tipo_tributo || '' = w_tipo_tributo
                    and nvl(prtr.stato_accertamento, 'D') = 'D'
                    and prtr.data <= data_elab.data
                    and f_importo_vers_ravv_dett(prtr.cod_fiscale
                                                ,w_tipo_tributo
                                                ,prtr.anno
                                                ,'U'
                                                ,'TOT'
                                                ,data_elab.data) > 0
                 order by ord, data_versamento)
    loop
      --
      -- Composizione intestazione versamenti
      --
      if w_prima_riga = 'S' then
         w_prima_riga := 'N';
         w_ind := w_ind + 1;
         riga_file (w_ind) := 'TIPO             IMPORTO VERSATO    DATA VERSAM    DATA SCADENZA    GIORNI DIFF.';
      end if;
      --
      w_ind := w_ind + 1;
      riga_file (w_ind) :=  vers.tipo_versamento||lpad(' ',3)||
                            translate(to_char(vers.importo_versato,'9,999,999,999,990.00'),',.', '.,')||'     '||
                            vers.data_versamento||'       '||vers.data_scadenza||'          '||
                            vers.gio_dif;
      --
      w_tot_versato := w_tot_versato + vers.importo_versato;
    end loop;
    --
    -- Stampa totale versamenti
    --
    if w_tot_versato = 0 then
       w_ind := w_ind + 1;
       riga_file (w_ind) := ' ';
       w_ind := w_ind + 1;
       riga_file(w_ind) := 'NON RISULTANO VERSAMENTI PER L''ANNO DI IMPOSTA '||liq.anno;
    else
       w_ind := w_ind + 1;
       riga_file (w_ind) := ' ';
       w_ind := w_ind + 1;
       riga_file (w_ind) := rpad('TOTALE VERSAMENTI',76)||translate(to_char(w_tot_versato,'9,999,999,999,990.00'),',.', '.,');
    end if;
    --
    -- Riepilogo importi
    --
    w_flag_int         := 0;
    w_tasi_imp_dovuto  := 0;
    w_tasi_imp_versato := 0;
    w_tasi_differenza  := 0;
    --
    w_ind := w_ind + 1;
    riga_file (w_ind) := ' ';
    w_ind := w_ind + 1;
    w_riga := 'RIEPILOGO IMPORTI';
    riga_file (w_ind) := lpad(' ',trunc((99 - length(w_riga)) / 2))||w_riga;
    w_ind := w_ind + 1;
    riga_file (w_ind) := '       Descrizione                   Codice    Importo Dovuto   Importo Versato        Differenza';
    --
    -- Importi divisi per codice tributo (nota: nella TASI non c'e' distinzione tra comune e erario)
    --
    for cotr in (select rpad('TASI - Abitazioni Principali', 39) descrizione
                       ,3958 codice
                       ,sum(decode(ogim.tipo_aliquota,2,ogim.imposta,0)) dovuto
                       ,max(vers.ab_principale) + max(f_importo_vers_ravv_dett(liq.cod_fiscale
                                                                              ,w_tipo_tributo
                                                                              ,liq.anno
                                                                              ,'U'
                                                                              ,'ABP'
                                                                              ,liq.data_liq))
                         versato
                       ,sum(decode(ogim.tipo_aliquota,2,ogim.imposta,0))
                         - (max(vers.ab_principale) + max(f_importo_vers_ravv_dett(liq.cod_fiscale
                                                                                  ,w_tipo_tributo
                                                                                  ,liq.anno
                                                                                  ,'U'
                                                                                  ,'ABP'
                                                                                  ,liq.data_liq)))
                         differenza
                   from oggetti_imposta ogim
                       ,oggetti_pratica ogpr
                       ,(select nvl(sum(ab_principale), 0) ab_principale
                           from versamenti vers
                          where vers.tipo_tributo || '' = w_tipo_tributo
                            and vers.pratica is null
                            and vers.anno = liq.anno
                            and vers.cod_fiscale = liq.cod_fiscale
                            and vers.data_pagamento <= liq.data_liq) vers
                  where ogim.oggetto_pratica = ogpr.oggetto_pratica
                    and ogpr.pratica = liq.pratica
                 having sum(decode(ogim.tipo_aliquota, 2, ogim.imposta, 0)) > 0
                     or   max(vers.ab_principale)
                        + max(f_importo_vers_ravv_dett(liq.cod_fiscale
                                                      ,w_tipo_tributo
                                                      ,liq.anno
                                                      ,'U'
                                                      ,'ABP'
                                                      ,liq.data_liq)) > 0
                 union
                 select rpad('TASI - Fabbricati Rurali', 39)
                       ,3959
                       ,sum(decode(ogim.tipo_aliquota,2,0
                                                     ,decode(nvl(ogpr.tipo_oggetto
                                                                ,ogge.tipo_oggetto)
                                                            ,1, 0
                                                            ,2, 0
                                                            ,decode(aliquota_erariale
                                                                   ,null, ogim.imposta
                                                                   ,0))))
                       ,max(vers.rurali) + max(f_importo_vers_ravv_dett(liq.cod_fiscale
                                                                       ,w_tipo_tributo
                                                                       ,liq.anno
                                                                       ,'U'
                                                                       ,'RUR'
                                                                       ,liq.data_liq))
                       ,sum(decode(ogim.tipo_aliquota,2,0
                                                     ,decode(nvl(ogpr.tipo_oggetto
                                                                ,ogge.tipo_oggetto)
                                                            ,1, 0
                                                            ,2, 0
                                                            ,decode(aliquota_erariale
                                                                   ,null, ogim.imposta
                                                                   ,0))))
                         - (max(vers.rurali) + max(f_importo_vers_ravv_dett(liq.cod_fiscale
                                                  ,w_tipo_tributo
                                                  ,liq.anno
                                                  ,'U'
                                                  ,'RUR'
                                                  ,liq.data_liq)))
                   from oggetti_imposta ogim
                       ,oggetti_pratica ogpr
                       ,oggetti ogge
                       ,(select nvl(sum(rurali), 0) rurali
                           from versamenti vers
                          where vers.tipo_tributo || '' = w_tipo_tributo
                            and vers.anno >= 2012
                            and vers.pratica is null
                            and vers.anno = liq.anno
                            and vers.cod_fiscale = liq.cod_fiscale
                            and vers.data_pagamento <= liq.data_liq) vers
                  where ogim.oggetto_pratica = ogpr.oggetto_pratica
                    and ogpr.pratica = liq.pratica
                    and ogpr.oggetto = ogge.oggetto
                 having sum(decode(ogim.tipo_aliquota
                                  ,2, 0
                                  ,decode(nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto)
                                         ,1, 0
                                         ,2, 0
                                         ,decode(aliquota_erariale, null, ogim.imposta, 0)))) >
                         0
                     or   max(vers.rurali)
                        + max(f_importo_vers_ravv_dett(liq.cod_fiscale
                                                      ,w_tipo_tributo
                                                      ,liq.anno
                                                      ,'U'
                                                      ,'RUR'
                                                      ,liq.data_liq)) > 0
                 union
                 select rpad('TASI - Aree Fabbricabili', 39)
                       ,3960
                       ,sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                  ,2,ogim.imposta - nvl(ogim.imposta_erariale, 0)
                                    ,0))
                       ,max(vers.aree_comune) + max(f_importo_vers_ravv_dett(liq.cod_fiscale
                                                                            ,w_tipo_tributo
                                                                            ,liq.anno
                                                                            ,'U'
                                                                            ,'ARC'
                                                                            ,liq.data_liq))
                       ,sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                  ,2,ogim.imposta - nvl(ogim.imposta_erariale, 0)
                                    ,0))
                        - (max(vers.aree_comune) + max(f_importo_vers_ravv_dett(liq.cod_fiscale
                                                                               ,w_tipo_tributo
                                                                               ,liq.anno
                                                                               ,'U'
                                                                               ,'ARC'
                                                                               ,liq.data_liq)))
                   from oggetti_imposta ogim
                       ,oggetti_pratica ogpr
                       ,oggetti ogge
                       ,(select nvl(sum(aree_fabbricabili), 0) aree_comune
                           from versamenti vers
                          where vers.tipo_tributo || '' = w_tipo_tributo
                            and vers.anno >= 2012
                            and vers.pratica is null
                            and vers.anno = liq.anno
                            and vers.cod_fiscale = liq.cod_fiscale
                            and vers.data_pagamento <= liq.data_liq) vers
                  where ogim.oggetto_pratica = ogpr.oggetto_pratica
                    and ogpr.pratica = liq.pratica
                    and ogpr.oggetto = ogge.oggetto
                 having sum(decode(nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto)
                                  ,2, ogim.imposta - nvl(ogim.imposta_erariale, 0)
                                  ,0)) > 0
                     or   max(vers.aree_comune)
                        + max(f_importo_vers_ravv_dett(liq.cod_fiscale
                                                      ,w_tipo_tributo
                                                      ,liq.anno
                                                      ,'U'
                                                      ,'ARC'
                                                      ,liq.data_liq)) > 0
                 union
                 select rpad('TASI - Altri Fabbricati', 39)
                       ,3961
                       ,sum(decode(ogim.tipo_aliquota,2,0
                                                     ,decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                                            ,1, 0
                                                            ,2, 0
                                                            ,decode(aliquota_erariale
                                                                   ,null, 0
                                                                        ,  ogim.imposta
                                                                           - nvl(ogim.imposta_erariale
                                                                                 ,0)))))
                       ,max(vers.altri_comune) + max(f_importo_vers_ravv_dett(liq.cod_fiscale
                                                                             ,w_tipo_tributo
                                                                             ,liq.anno
                                                                             ,'U'
                                                                             ,'ALC'
                                                                             ,liq.data_liq))
                       ,sum(decode(ogim.tipo_aliquota,2,0
                                                     ,decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                                            ,1, 0
                                                            ,2, 0
                                                            ,decode(aliquota_erariale
                                                                   ,null, 0
                                                                   ,  ogim.imposta
                                                                           - nvl(ogim.imposta_erariale
                                                                                ,0)))))
                        - (max(vers.altri_comune) + max(f_importo_vers_ravv_dett(liq.cod_fiscale
                                                                                ,w_tipo_tributo
                                                                                ,liq.anno
                                                                                ,'U'
                                                                                ,'ALC'
                                                                                ,liq.data_liq)))
                   from oggetti_imposta ogim
                       ,oggetti_pratica ogpr
                       ,oggetti ogge
                       ,(select nvl(sum(altri_fabbricati), 0) altri_comune
                           from versamenti vers
                          where vers.tipo_tributo || '' = w_tipo_tributo
                            and vers.anno >= 2012
                            and vers.pratica is null
                            and vers.anno = liq.anno
                            and vers.cod_fiscale = liq.cod_fiscale
                            and vers.data_pagamento <= liq.data_liq) vers
                  where ogim.oggetto_pratica = ogpr.oggetto_pratica
                    and ogpr.pratica = liq.pratica
                    and ogpr.oggetto = ogge.oggetto
                 having sum(decode(ogim.tipo_aliquota
                                  ,2, 0
                                  ,decode(nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto)
                                         ,1, 0
                                         ,2, 0
                                         ,decode(aliquota_erariale
                                                ,null, 0
                                                ,decode(sign(ogim.anno - 2012)
                                                       ,1, decode(   substr(ogpr.categoria_catasto
                                                                           ,1
                                                                           ,1)
                                                                  || to_char(ogim.tipo_aliquota)
                                                                 ,'D9', 0
                                                                 ,  ogim.imposta
                                                                  - nvl(ogim.imposta_erariale
                                                                       ,0))
                                                       ,  ogim.imposta
                                                        - nvl(ogim.imposta_erariale, 0)))))) >
                         0
                     or   max(vers.altri_comune)
                        + max(f_importo_vers_ravv_dett(liq.cod_fiscale
                                                      ,w_tipo_tributo
                                                      ,liq.anno
                                                      ,'U'
                                                      ,'ALC'
                                                      ,liq.data_liq)) > 0
                 order by 2)
    loop
      w_tasi_imp_dovuto  := w_tasi_imp_dovuto + cotr.dovuto;
      w_tasi_imp_versato := w_tasi_imp_versato + cotr.versato;
      w_tasi_differenza  := w_tasi_differenza + cotr.differenza;
      --
      w_ind := w_ind + 1;
      riga_file(w_ind) := cotr.descrizione||cotr.codice||
                          lpad(translate(to_char(cotr.dovuto, '99,999,999,990.00'),',.','.,'),18)||
                          lpad(translate(to_char(cotr.versato,'99,999,999,990.00'),',.','.,'),18)||
                          lpad(translate(to_char(cotr.differenza,'99,999,999,990.00'),',.','.,'),18);
    end loop;
    --
    -- Totale importi
    --
    w_ind := w_ind + 1;
    riga_file (w_ind) := lpad(' ', 43)||rpad(' _', 18, '_')||rpad(' _', 18, '_')||rpad(' _', 18, '_');
    w_ind := w_ind + 1;
    riga_file (w_ind) := rpad('Totale Complessivo',43)||
                         lpad(translate(to_char(w_tasi_imp_dovuto, '99,999,999,990.00'),',.','.,'),18)||
                         lpad(translate(to_char(w_tasi_imp_versato,'99,999,999,990.00'),',.','.,'),18)||
                         lpad(translate(to_char(w_tasi_differenza,'99,999,999,990.00'),',.','.,'),18);
    w_ind := w_ind + 1;
    riga_file (w_ind) := ' ';
    --
    -- Liquidazione imposta e interessi
    --
    w_prima_riga      := 'S';
    w_tot_imposta_int := 0;
    for imp in (select sapr.cod_sanzione
                     , sapr.importo
                     , decode(sapr.percentuale, null , '        '
                                              , replace(to_char(sapr.percentuale,'9990.00'),'.',','))
                              || '  '
                              || decode(sapr.riduzione, null, '        '
                                                      , replace(to_char(sapr.riduzione,'9990.00'),'.',','))
                              || '  '
                              || decode(nvl(sapr.giorni,sapr.semestri)
                                            , null, '     '
                                            , to_char(nvl(sapr.giorni,sapr.semestri),'9999'))
                              || '  '
                              || translate(to_char(sapr.importo,'99,999,999,990.00'), ',.', '.,')
                       perc_ed_importo
                     , rpad(substr(sanz.descrizione,1,52),52) descrizione
                  from SANZIONI_PRATICA sapr
                     , SANZIONI         sanz
                 where sapr.cod_sanzione = sanz.cod_sanzione (+)
                   and sapr.tipo_tributo = sanz.tipo_tributo (+)
                   and sapr.pratica = liq.pratica
                   and sapr.cod_sanzione not in (888,889)
                   and (sanz.cod_sanzione in (1, 100, 101)
                     or ( (sanz.tipo_tributo = 'TARSU'
                      and (sanz.tipo_causale || nvl (sanz.flag_magg_tares, 'N') = 'EN'
                        or sanz.tipo_causale || nvl (sanz.flag_magg_tares, 'N') = 'IN'))
                     or (sanz.tipo_tributo != 'TARSU'
                        and flag_imposta = 'S')))
                order by sapr.cod_sanzione asc)
    loop
      if w_prima_riga = 'S' then
         w_prima_riga  := 'N';
         --w_flag_totali := substr(imp.sanz_ord,2,1);
         w_ind := w_ind + 1;
         riga_file(w_ind) := ' ';
         w_ind := w_ind + 1;
         w_riga := w_para_int_imposta_int||' IMPOSTA ED INTERESSI';
         riga_file (w_ind) := lpad(' ',trunc((99 - length(w_riga)) / 2))||w_riga;
         w_ind := w_ind + 1;
         riga_file(w_ind) := ' ';
         w_ind := w_ind + 1;
         riga_file (w_ind) := '                                                         PERC.      RID. SEM/GG';
      end if;
      --
      w_ind := w_ind + 1;
      riga_file(w_ind) := imp.descrizione||imp.perc_ed_importo;
      w_tot_imposta_int := w_tot_imposta_int + imp.importo;
    end loop;
    --
    -- Totale imposta ed interessi
    --
    if w_tot_imposta_int <> 0 then
       w_ind := w_ind + 1;
       riga_file(w_ind) := rpad('TOTALE PER IMPOSTA ED INTERESSI',76)||
                           translate(to_char(w_tot_imposta_int,'9,999,999,999,990.00'), ',.', '.,');
    end if;
    --
    -- Trattamento sanzioni e spese di notifica
    --
    w_prima_riga   := 'S';
    w_tot_sanzioni := 0;
    for sanz in ( select sapr.cod_sanzione
                       , rpad(substr(sanz.descrizione,1,51),51) descrizione
                       , sapr.importo
                       , decode(sapr.percentuale
                               , null, '        '
                               , replace(to_char(sapr.percentuale,'9990.00'),'.',','))
                         || '  '
                         || decode(sapr.riduzione
                                  , null, '        '
                                  , replace(to_char(sapr.riduzione,'9990.00'),'.',','))
                         || '  '
                         || decode(sapr.riduzione_2
                                  , null, '        '
                                  , replace(to_char(sapr.riduzione_2,'9990.00'),'.',','))
                         || ' '
                         || translate(to_char(sapr.importo,'99,999,990.00'), ',.', '.,')      perc_ed_importo
                     from SANZIONI_PRATICA sapr
                        , SANZIONI sanz
                    where sapr.cod_sanzione = sanz.cod_sanzione (+) and
                          sapr.tipo_tributo = sanz.tipo_tributo (+) and
                          sapr.cod_sanzione not in (888,889) and
                          sapr.PRATICA = liq.pratica  and
                          sanz.cod_sanzione not in (1, 100, 101)
                          and flag_imposta is null
                 order by sapr.cod_sanzione asc )
    loop
      if w_prima_riga = 'S' then
         w_prima_riga  := 'N';
         w_ind := w_ind + 1;
         riga_file(w_ind) := ' ';
         w_ind := w_ind + 1;
         w_riga := 'IRROGAZIONE SANZIONI E SPESE DI NOTIFICA';
         riga_file (w_ind) := lpad(' ',trunc((99 - length(w_riga)) / 2))||w_riga;
         w_ind := w_ind + 1;
         riga_file(w_ind) := ' ';
         w_ind := w_ind + 1;
         riga_file(w_ind) := '                                                         PERC.      RID.     RID.2';
      end if;
      --
      w_ind := w_ind + 1;
      riga_file(w_ind) := sanz.descrizione||'   '||sanz.perc_ed_importo;
      w_tot_sanzioni   := w_tot_sanzioni + sanz.importo;
    end loop;
    --
    -- Se il flag w_prima_riga e' uguale a 'N', significa che sono state
    -- stampate delle sanzioni, quindi si stampa anche il totale. In caso
    -- contrario, i totali non vengono stampati
    --
    if w_prima_riga = 'N' then
       w_ind := w_ind + 1;
       riga_file(w_ind) := rpad('TOTALE SANZIONI',76)||
                           translate(to_char(w_tot_sanzioni,'9,999,999,999,990.00'), ',.', '.,');
    end if;
    --
    -- Riepilogo somme dovute
    --
    w_ind := w_ind + 1;
    riga_file(w_ind) := ' ';
    w_ind := w_ind + 1;
    riga_file(w_ind) := liq.l_importo_totale||'    '||liq.importo_totale;
    w_ind := w_ind + 1;
    riga_file(w_ind) := liq.l_importo_totale_arrotondato||'    '||liq.importo_totale_arrotondato;
    w_ind := w_ind + 1;
    riga_file(w_ind) := liq.l_importo_ridotto_arrotondato||'                                        '||liq.importo_ridotto_arrotondato;
    if liq.motivo is not null then
       w_ind := w_ind + 1;
       riga_file(w_ind) := ' ';
       w_ind := w_ind + 1;
       riga_file (w_ind) := liq.motivo;
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
     --DBMS_OUTPUT.PUT_LINE('Prima riga: '||riga_file.first);
     --DBMS_OUTPUT.PUT_LINE('Ultima riga: '||riga_file.last);
      for w_ind in riga_file.first .. riga_file.last
      loop
        w_file_clob_1 := w_file_clob_1||riga_file(w_ind)||';';
      end loop;
    exception
      when others then
        w_errore := 'Composizione riga (Cod. fiscale ' || liq.cod_fiscale || ', Pratica n. '|| liq.pratica ||') - ' ||
                    sqlerrm;
        raise errore;
    end;
    --
    -- Aggiunta caratteri per "a capo"
    --
    w_file_clob_1 := w_file_clob_1||chr(13)||chr(10);
  end loop;
--
-- Composizione riga di intestazione
--
  w_riga := 'CODICE_FISCALE;COGNOME;NOME;DATA_NASCITA;SESSO;COMUNE_NASCITA;PROVINCIA_NASCITA;IDENTIFICATIVO_OPERAZIONE;';
  w_conta_campi := 8;
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
  w_riga := w_riga||'TOTALE_02;PROTOCOLLO;NOMINATIVO;INDIRIZZO1;INDIRIZZO2;INDIRIZZO3;CODICE_FISCALE;ATTO1;ATTO2;ATTO3;';
  w_conta_campi := w_conta_campi + 11;
  --
  for w_ind in w_conta_campi .. w_max_colonna
  loop
    w_riga := w_riga||'RIGA_'||lpad(to_char(w_ind - w_conta_campi + 1),3,'0')||';';
  end loop;
  --
  w_num_colonne := length(w_riga) - length(replace(w_riga,';',''));
  w_file_clob := w_riga||chr(13)||chr(10)||w_file_clob_1;
  --
  -- Inserimento riga wrk_trasmissioni con file clob
  --
  begin
    insert into wrk_trasmissioni ( numero
                                 , dati_clob
                                 )
    values ( lpad('1',15,'0')
           , w_file_clob
           );
  exception
    when others then
      w_errore := 'Ins. WRK_TRASMISSIONI (clob) ' ||
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
/* End Procedure: ESTRAZIONE_LIQUIDAZIONI_TASI */
/

