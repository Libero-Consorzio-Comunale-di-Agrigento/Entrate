--liquibase formatted sql 
--changeset abrandolini:20250326_152423_trasmissione_ruolo stripComments:false runOnChange:true 
 
create or replace procedure TRASMISSIONE_RUOLO
(a_sessione  IN number,
 a_nome_p    IN varchar2,
 a_tipo_elab IN varchar2)
IS
  w_cat_indir_prec     varchar2(75);
  w_cod_istat          varchar2(6);
  w_cod_ente           varchar2(5);
  w_tipo_tributo       varchar2(5);
  w_tipo_ruolo         number;
  w_specie_ruolo       number;
  w_cod_sede           number;
  W_anno_ruolo         number;
  w_importo_lordo      varchar2(1);
  w_rate               number;
  w_flag_iciap         number := 0;
  w_flag_errore        number := 0;
  w_progressivo        number := 0;
  w_ruolo              number;
  w_ni_prec            number := 0;
  w_tipo_resid_prec    number := 0;
  w_tributo_prec       varchar2(4) := '';--number := 0;
  w_anno_ruolo_prec    number := 0;
  w_imponibile_prec    number := 0;
  w_imposta            number := 0;
  w_imposta_contrib    number := 0;
  w_numero_prec        varchar2(15);
  w_tipo_pratica_prec  varchar2(4);
  w_data_prec          varchar2(10);
  w_data_notifica_prec varchar2(10);
  w_note_prec          varchar2(14);
  w_Pontedera_1_prec   varchar2(27);
  w_comune_ruolo       varchar2(6);
  w_riga_100           varchar2(100);
  w_riga               varchar2(2000);
  w_riga_185           varchar2(185);
  w_riga_190           varchar2(190);
  w_riga_209           varchar2(209);
  w_riga_81            varchar2(81);
  w_riga_178           varchar2(178); --178
  w_riga_112           varchar2(112);
  tot_record_file      number := 0;
  tot_record_n1_file   number := 0;
  tot_record_n2_file   number := 0;
  tot_record_n3_file   number := 0;
  tot_record_n4_file   number := 0;
  tot_record_n5_file   number := 0;
  tot_record_ruolo     number := 0;
  tot_record_n2_ruolo  number := 0;
  tot_record_n3_ruolo  number := 0;
  tot_record_n4_ruolo  number := 0;
  tot_imposta_ruolo    number := 0;
  rec_trattati         number := 0;
  rec_da_trattare      number := 0;
  w_conta_n4           number;
  w_conta_ruolo        number := 0;
  w_num_ruoli          number := 0;
  w_compensazione      number := 0;
  w_cat_indir          varchar2(75);
  w_tari_descrizione   varchar2(60);
  w_tari_tariffa       number(11,5);
  errore               exception;
  w_errore             varchar2(2000);
  w_fase_euro          number;
  w_100                number;
  w_ni_display         number;
  w_cognome_resp       varchar2(30);
  w_nome_resp          varchar2(30);
  w_pertinenze_di      number;
  x_messaggio          varchar2(20);
  CURSOR sel_para IS
    select valore
      from parametri
     where parametri.sessione = a_sessione
       and parametri.nome_parametro = a_nome_p;
  -- Modificata l'estrazione del cursore
  -- con la decode sul campo cat_indir
  -- per il Comune di Sassuolo e Bagno di Romagna
  CURSOR sel_ruog IS
    select sogg.tipo_residente,
           sogg.ni,
           nvl(coti.cod_entrata, ruog.tributo) tributo,
           decode(ruol.specie_ruolo
                 , 1 , -- coattivo
                  rpad(decode(prtr.tipo_pratica,
                              'L',
                              'LIQUIDAZIONE',
                              'ACCERTAMENTO') ||
                       decode(prtr.numero,
                              null,
                              null,
                              ' Numero ' || prtr.numero) ||
                       decode(prtr.data,
                              null,
                              null,
                              ' del ' || to_char(prtr.data, 'dd/mm/yyyy')) ||
                       decode(prtr.data_notifica,
                              null,
                              null,
                              decode(prtr.tipo_pratica,
                                     'L',
                                     ' notificata il ',
                                     ' notificato il ') ||
                              to_char(prtr.data_notifica, 'dd/mm/yyyy')),
                       70,
                       ' ')
                 , -- normale
                  decode(w_cod_istat,
                         -- Sassuolo
--                         '036040',
--                         substr(tari.descrizione, 1, 24) || ' L' ||
--                         trunc(substr(tari.tariffa, 1, 6)) || ' MQ' ||
--                         trunc(substr(ogpr.consistenza, 1, 7)) ||
--                         decode(prtr.tipo_pratica,
--                                'D',
--                                decode(arvi.cod_via,
--                                       null,
--                                       to_char(null),
--                                       ' ' || substr(arvi.denom_uff, 1, 19) || ' ' ||
--                                       ogge.num_civ ||
--                                       decode(ogge.suffisso,
--                                              null,
--                                              to_char(null),
--                                              '/' || ogge.suffisso)),
--                                decode(prtr.note,
--                                       null,
--                                       to_char(null),
--                                       ' ' || substr(prtr.note, 1, 14)) ||
--                                decode(prtr.data_notifica,
--                                       null,
--                                       to_char(null),
--                                       ' Not. ' ||
--                                       to_char(prtr.data_notifica, 'dd/mm/yyyy'))),
                         -- Bagno di Romagna
                         '040001',
                         substr(cate.descrizione, 1, 21) || ' MQ' ||
                         trunc(substr(to_char(nvl(ogpr.consistenza,0) + f_consistenza_pert_ruolo(ogpr.oggetto_pratica,ruog.ruolo)), 1, 5)) ||
                         decode(arvi.cod_via,
                                null,
                                to_char(null),
                                '  ' || substr(arvi.denom_uff,
                                               instr(arvi.denom_uff, '-') + 1,
                                               34) || ' ' ||
                                substr(ogge.num_civ, 1, 4) ||
                                decode(ogge.suffisso,
                                       null,
                                       to_char(null),
                                       '/' || substr(ogge.suffisso, 1, 4))),
                         -- Roccastrada
                         '053021',
                         substr(cate.descrizione, 1, 21) || ' MQ' ||
                         trunc(substr(to_char(nvl(ogpr.consistenza,0) + f_consistenza_pert_ruolo(ogpr.oggetto_pratica,ruog.ruolo)), 1, 5)) ||
                         decode(arvi.cod_via,
                                null,
                                to_char(null),
                                --                      '  '||substr(arvi.denom_uff,instr(arvi.denom_uff,'-')+1,34)||' '||substr(ogge.num_civ,1,4)||
                                -- modificato il 21062006 a seguito di modifica frazioni del comune
                                '  ' ||
                                substr(arvi.denom_uff,
                                       1,
                                       instr(arvi.denom_uff, '-') - 1) || ' ' ||
                                substr(ogge.num_civ, 1, 4) ||
                                decode(ogge.suffisso,
                                       null,
                                       to_char(null),
                                       '/' || substr(ogge.suffisso, 1, 4))),
                         -- San Lazzaro Di Savena
                         '037054',
                         decode(ruog.note,
                                'ANNO 2004: INCENTIVO TARSU: EURO 8,7',
                                'DAL TOTALE DA PAGARE SONO STATI DETRATTI EURO 10,00 PER INCENTIVO 2003',
                                'ANNO 2004: INCENTIVO TARSU: EURO 17,39',
                                'DAL TOTALE DA PAGARE SONO STATI DETRATTI EURO 20,00 PER INCENTIVO 2003',
                                'ANNO 2005: INCENTIVO TARSU: EURO 8,7',
                                'DAL TOTALE DA PAGARE SONO STATI DETRATTI EURO 10,00 PER INCENTIVO 2004',
                                'ANNO 2005: INCENTIVO TARSU: EURO 17,39',
                                'DAL TOTALE DA PAGARE SONO STATI DETRATTI EURO 20,00 PER INCENTIVO 2004',
                                'ANNO 2006: INCENTIVO TARSU: EURO 8,7',
                                'DAL TOTALE DA PAGARE SONO STATI DETRATTI EURO 10,00 PER INCENTIVO 2005',
                                'ANNO 2006: INCENTIVO TARSU: EURO 17,39',
                                'DAL TOTALE DA PAGARE SONO STATI DETRATTI EURO 20,00 PER INCENTIVO 2005',
                                'ANNO 2007: INCENTIVO TARSU: EURO 8,7',
                                'DAL TOTALE DA PAGARE SONO STATI DETRATTI EURO 10,00 PER INCENTIVO 2006',
                                'ANNO 2007: INCENTIVO TARSU: EURO 17,39',
                                'DAL TOTALE DA PAGARE SONO STATI DETRATTI EURO 20,00 PER INCENTIVO 2006',
                                'ANNO 2008: INCENTIVO TARSU: EURO 8,7',
                                'DAL TOTALE DA PAGARE SONO STATI DETRATTI EURO 10,00 PER INCENTIVO 2007',
                                'ANNO 2008: INCENTIVO TARSU: EURO 17,39',
                                'DAL TOTALE DA PAGARE SONO STATI DETRATTI EURO 20,00 PER INCENTIVO 2007',
                                'ANNO 2010: INCENTIVO TARSU 2008: EURO 13,9',
                                'INCENTIVO RACCOLTA DIFFERENZIATA RIFIUTI ANNO 2008',
                                'ANNO 2010: INCENTIVO TARSU 2009: EURO 13,9',
                                'INCENTIVO RACCOLTA DIFFERENZIATA RIFIUTI ANNO 2009',
                                'ANNO 2010: INCENTIVO TARSU 2008-2009: EURO 27,8',
                                'INCENTIVO RACC. DIFF. RIFIUTI ANNO 2008 E 2009',
                                'ANNO 2010: INCENTIVO TARSU 2008: EURO 17,39',
                                'INCENTIVO RACCOLTA DIFFERENZIATA RIFIUTI ANNO 2008',
                                'ANNO 2010: INCENTIVO TARSU 2009: EURO 17,39',
                                'INCENTIVO RACCOLTA DIFFERENZIATA RIFIUTI ANNO 2009',
                                'ANNO 2010: INCENTIVO TARSU 2008-2009: EURO 34,78',
                                'INCENTIVO RACC. DIFF. RIFIUTI ANNO 2008 E 2009',
                                substr(cate.descrizione, 1, 34) || ' MQ' ||
                                trunc(substr(to_char(nvl(ogpr.consistenza,0) + f_consistenza_pert_ruolo(ogpr.oggetto_pratica,ruog.ruolo)), 1, 5)) ||
                                decode(arvi.cod_via,
                                       null,
                                       to_char(null),
                                       ' ' || substr(arvi.denom_uff, 1, 19) || ' ' ||
                                       ogge.num_civ ||
                                       decode(ogge.suffisso,
                                              null,
                                              to_char(null),
                                              '/' || ogge.suffisso))),
                         -- Malnate
--                         '012096',
--                         decode(cate.flag_domestica,
--                                'S',
--                                decode(sign(2004 - ruol.anno_ruolo),
--                                       -1,
--                                       rpad('CAT.' || cate.categoria || ' ' ||
--                                            substr(tari.descrizione, 1, 18) ||
--                                            ' OCC.' ||
--                                            f_ultimo_faso(sogg.ni,
--                                                          ruol.anno_ruolo),
--                                            34),
--                                       substr(cate.descrizione, 1, 34)),
--                                substr(cate.descrizione, 1, 34)) || ' MQ' ||
--                         trunc(substr(ogpr.consistenza, 1, 5)) ||
--                         decode(arvi.cod_via,
--                                null,
--                                to_char(null),
--                                ' ' || substr(arvi.denom_uff, 1, 19) || ' ' ||
--                                ogge.num_civ ||
--                                decode(ogge.suffisso,
--                                       null,
--                                       to_char(null),
--                                       '/' || ogge.suffisso)),
                         -- Sabbioneta
--                         '020054',
--                         substr(cate.descrizione, 1, 25) || ' ' ||
--                         substr(tari.descrizione, 1, 12) || ' MQ.' ||
--                         trunc(substr(ogpr.consistenza, 1, 5)) ||
--                         decode(arvi.cod_via,
--                                null,
--                                to_char(null),
--                                ' ' || substr(arvi.denom_uff, 1, 19) || ' ' ||
--                                ogge.num_civ ||
--                                decode(ogge.suffisso,
--                                       null,
--                                       to_char(null),
--                                       '/' || ogge.suffisso)),
                         -- Rivoli
                         '001219',
                         lpad(ogpr.categoria, 4, ' ') ||
                         lpad(ogpr.tipo_tariffa, 2, ' ') ||
                         decode(arvi.cod_via,
                                null,
                                to_char(null),
                                substr(arvi.denom_uff, 1, 55) || ' ' ||
                                ogge.num_civ ||
                                decode(ogge.suffisso,
                                       null,
                                       to_char(null),
                                       '/' || ogge.suffisso)),
                         -- Corsico
                         '015093',
                         lpad(ogpr.categoria, 4, ' ') || '|' || '|' ||
                         arvi.cod_via || '|' || ogge.num_civ || '|' ||
                         ogge.suffisso || '|' || ogge.interno || '|' ||
                         to_char(nvl(ogpr.consistenza,0) + f_consistenza_pert_ruolo(ogpr.oggetto_pratica,ruog.ruolo)) || '|' ||
                         f_ultimo_faso(sogg.ni, ruol.anno_ruolo) || '|' ||
                         decode(to_char(ogco.data_decorrenza, 'yyyy'),
                                to_char(W_anno_ruolo),
                                to_char(ogco.data_decorrenza, 'dd/mm/yyyy'),
                                '01/01/' || to_char(W_anno_ruolo)) || '|' ||
                         to_char(decode(nvl(ogpr.tipo_occupazione, 'P'),
                                        'T',
                                        ogco.data_cessazione,
                                        nvl(ogco.data_cessazione,
                                            decode(prtr.tipo_pratica,
                                                   'A',
                                                   nvl(f_fine_validita(nvl(ogpr.oggetto_pratica_rif,
                                                                           ogpr.oggetto_pratica),
                                                                       ogco.cod_fiscale,
                                                                       ogco.data_decorrenza,
                                                                       '%'),
                                                       f_cessazione_accertamento(ogco.cod_fiscale,
                                                                                 ogpr.oggetto,
                                                                                 ogco.data_decorrenza,
                                                                                 prtr.tipo_tributo)),
                                                   f_fine_validita(nvl(ogpr.oggetto_pratica_rif,
                                                                       ogpr.oggetto_pratica),
                                                                   ogco.cod_fiscale,
                                                                   ogco.data_decorrenza,
                                                                   '%')))),
                                 'dd/mm/yyyy'),
                         -- Portoferraio
                         '049014',
                         decode (tipo_ruolo,
                                 2,
                                 decode(prtr.tipo_pratica,
                            'A',
                            'ACC.' ||
                            prtr.numero ||'-' || to_char(prtr.data, 'dd/mm/yyyy') ||
                            decode(prtr.data_notifica,null,to_char(null),
                                '-NOT.' ||to_char(prtr.data_notifica, 'dd/mm/yyyy')),
                              substr(cate.descrizione, 1, 34) ),
                        substr(cate.descrizione, 1, 34) )||
                         ' MQ' ||
                 trunc(substr(to_char(nvl(ogpr.consistenza,0) + f_consistenza_pert_ruolo(ogpr.oggetto_pratica,ruog.ruolo)), 1, 5)) ||
                         decode(arvi.cod_via,
                                null,
                                to_char(null),
                                ' ' || substr(arvi.denom_uff, 1, 19) || ' ' ||
                                ogge.num_civ ||
                                decode(ogge.suffisso,
                                       null,
                                       to_char(null),
                                       '/' || ogge.suffisso)),
                         -- Fiorenzuola
                         '033021',
                         decode (tipo_ruolo,
                                 2,
                                 decode(prtr.tipo_pratica,
                            'A',
                            'Avviso di accertamento n.' ||
                            prtr.numero ||' del ' || to_char(prtr.data, 'dd/mm/yyyy') ||
                            decode(prtr.data_notifica,null,to_char(null),
                                ', data di notifica ' ||to_char(prtr.data_notifica, 'dd/mm/yyyy')),
                              substr(cate.descrizione, 1, 34)||' Sup. MQ ' ||
                 trunc(substr(to_char(nvl(ogpr.consistenza,0) + f_consistenza_pert_ruolo(ogpr.oggetto_pratica,ruog.ruolo)), 1, 5)) ||
                         decode(arvi.cod_via,
                                null,
                                to_char(null),
                                ' ' || substr(arvi.denom_uff, 1, 19) || ' ' ||
                                ogge.num_civ ||
                                decode(ogge.suffisso,
                                       null,
                                       to_char(null),
                                       '/' || ogge.suffisso)) ),
--Fiorenzuola nuovo
                         decode(arvi.cod_via,
                                null,
                                substr(indirizzo_localita, 1, 19),
--                                substr(replace(replace(arvi.denom_uff,'LOCALITA'' ',''),'VIA ',''), 1, 19) || ' ' ||
                                substr(arvi.denom_uff, 1, 19) || ' ' ||
                                  ogge.num_civ ||
                                decode(ogge.suffisso,
                                       null,
                                       to_char(null),
                                       '/' || ogge.suffisso))||
                       ' -' || substr(cate.descrizione, 1, 21) ||
                         decode(ogpr.categoria,15,'- GG.',16,'- GG.','- Sup.') ||
--                 trunc(substr(to_char(nvl(ogpr.consistenza,0) + f_consistenza_pert_ruolo(ogpr.oggetto_pratica,ruog.ruolo)), 1, 5))
--                 substr(to_char(nvl(ogpr.consistenza,0) + f_consistenza_pert_ruolo(ogpr.oggetto_pratica,ruog.ruolo)), 1, 5))
                   rtrim(to_char(nvl(ogpr.consistenza,0) + f_consistenza_pert_ruolo(ogpr.oggetto_pratica,ruog.ruolo),'FM999990D99'),'.'))
                                ||decode(ogpr.categoria,15,' x ',16,' x ',' Mq x ')||'€'||to_char(tari.tariffa,'FM999990.00999')
                                ||decode(ogpr.categoria,15,'/gg',16,'/gg','/mq'),
                         -- Pontedera
                         '050029',
                         decode (tipo_ruolo,
                                 2,
                                 decode(prtr.tipo_pratica,
                            'A',
                            'ACC.' ||
                            prtr.numero ||'-' || to_char(prtr.data, 'dd/mm/yy') ||
                            decode(prtr.data_notifica,null,to_char(null),
                                  '-NOT.' ||to_char(prtr.data_notifica, 'dd/mm/yy')) ||
                            ' CAT.'||lpad(ogpr.categoria,2,'0')||'/'||
                            lpad(ogpr.tipo_tariffa,2,'0'),
                            substr(cate.descrizione, 1, 34) ),
                 substr(cate.descrizione, 1, 34) )||
                         ' MQ' ||
                 trunc(substr(to_char(nvl(ogpr.consistenza,0) + f_consistenza_pert_ruolo(ogpr.oggetto_pratica,ruog.ruolo)), 1, 5)) ||
                         decode(arvi.cod_via,
                                null,
                                to_char(null),
                                ' ' || substr(arvi.denom_uff, 1, 19) || ' ' ||
                                ogge.num_civ ||
                                decode(ogge.suffisso,
                                       null,
                                       to_char(null),
                                       '/' || ogge.suffisso)),
                         '046015',
                         -- Gallicano
                         substr(cate.descrizione, 1, 25) || ' - '||substr (tari.descrizione, 1, 6) || ' MQ' ||
                         trunc(substr(to_char(nvl(ogpr.consistenza,0) + f_consistenza_pert_ruolo(ogpr.oggetto_pratica,ruog.ruolo)), 1, 5)) ||
                         decode(arvi.cod_via,
                                null,
                                to_char(null),
                                ' ' || substr(arvi.denom_uff, 1, 19) || ' ' ||
                                ogge.num_civ ||
                                decode(ogge.suffisso,
                                       null,
                                       to_char(null),
                                       '/' || ogge.suffisso)),
                         -- Standard
                         substr(cate.descrizione, 1, 34) || ' MQ' ||
                         trunc(substr(to_char(nvl(ogpr.consistenza,0) + f_consistenza_pert_ruolo(ogpr.oggetto_pratica,ruog.ruolo)), 1, 5)) ||
                         decode(arvi.cod_via,
                                null,
                                to_char(null),
                                ' ' || substr(arvi.denom_uff, 1, 19) || ' ' ||
                                ogge.num_civ ||
                                decode(ogge.suffisso,
                                       null,
                                       to_char(null),
                                       '/' || ogge.suffisso))
                                       )) cat_indir,
           decode(w_specie_ruolo
                 ,1,prtr.anno
                 ,ruol.anno_ruolo
                 )                                              anno_ruolo,
           nvl(ruog.consistenza,0)
             + f_consistenza_pert_ruolo(ogpr.oggetto_pratica,ruog.ruolo)      imponibile,
           decode(ruol.specie_ruolo
                 ,0,ruog.importo
                    + f_importo_pert_ruolo(ogpr.oggetto_pratica,ruog.ruolo,ruog.tributo)
                 ,f_imposta_ruolo_coattivo(prtr.pratica,ruog.ruolo,ruog.tributo)
                 )         imposta,
           decode(motivo_compensazione,99,null,coru.compensazione)                        compensazione,
           prtr.numero numero,
           decode(prtr.tipo_pratica, 'A', 'ACC.', 'L', 'LIQ.', 'DEN.') tipo_pratica,
           to_char(prtr.data, 'dd/mm/yyyy') data,
           to_char(prtr.data_notifica, 'dd/mm/yyyy') data_notifica,
           to_char(prtr.data_notifica, 'ddmmyy') data_notifica_2,
           /*nvl(decode(prtr.tipo_tributo||ruol.specie_ruolo
                                      , 'TARSU1', '00000000' --Ruolo Coattivo
                                      , to_char(prtr.data_notifica + decode(prtr.tipo_tributo
                                                                                            , 'TOSAP', 61
                                                                                            , 'TARSU', 61 --Ruolo Normale
                                                                                            , 91)
                                               , 'ddmmYYYY')),
               '00000000') decorrenza_interessi,*/
           f_data_decorrenza(prtr.tipo_tributo, ruol.specie_ruolo, prtr.data, prtr.data_notifica, 0) decorrenza_interessi,
           'E'||decode(prtr.tipo_pratica, 'A', 'ACC', 'L', 'LIQ', 'DEN')
              ||lpad(substr(prtr.numero,1,6),6)
              ||'/'||to_char(prtr.data, 'ddmmyy')
              ||' '||decode(prtr.data_notifica
                           ,null,lpad(' ',9)
                           ,'NOT'||to_char(prtr.data_notifica, 'ddmmyy')
                           )                                    Pontedera_1,
           substr(prtr.note, 1, 14)                             note,
           ogpr.tributo                                         ogpr_tributo,
           ogpr.categoria                                       ogpr_categoria,
           ogpr.tipo_tariffa                                    ogpr_tipo_tariffa,
           nvl(ogpr.consistenza,0)
            + f_consistenza_pert_ruolo(ogpr.oggetto_pratica,ruog.ruolo)
                                                                ogpr_consistenza,
           prtr.tipo_pratica                                    prtr_tipo_pratica,
           arvi.cod_via                                         arvi_cod_via,
           arvi.denom_uff                                       arvi_denom_uff,
           ogge.num_civ                                         ogge_num_civ,
           ogge.suffisso                                        ogge_suffisso,
           prtr.note                                            prtr_note,
           prtr.data_notifica                                   prtr_data_notifica,
           cate.flag_domestica                                  cate_flag_domestica,
           cate.categoria                                       cate_categoria,
           cate.descrizione                                     cate_descrizione,
           sogg.ni                                              sogg_ni,
           ruol.specie_ruolo                                    ruol_specie_ruolo
      from tariffe              tari,
           categorie            cate,
           archivio_vie         arvi,
           oggetti              ogge,
           soggetti             sogg,
           contribuenti         cont,
           ruoli                ruol,
           pratiche_tributo     prtr,
           oggetti_pratica      ogpr,
           ruoli_oggetto        ruog,
           oggetti_contribuente ogco,
           compensazioni_ruolo  coru
         , codici_tributo       coti
     where sogg.ni                 = cont.ni
       and coti.tributo            = ruog.tributo
       and cont.cod_fiscale        = ruog.cod_fiscale
       and ogpr.oggetto_pratica(+) = ruog.oggetto_pratica
       and prtr.pratica            = nvl(ruog.pratica, ogpr.pratica)
       and tari.tributo(+)         = ogpr.tributo
       and tari.categoria(+)       = ogpr.categoria
       and tari.tipo_tariffa(+)    = ogpr.tipo_tariffa
       and tari.anno(+)            = W_anno_ruolo
       and cate.tributo(+)          = ogpr.tributo
       and cate.categoria(+)        = ogpr.categoria
       and arvi.cod_via(+)          = ogge.cod_via
       and ogge.oggetto(+)          = ruog.oggetto
       and ogco.oggetto_pratica(+)  = ruog.oggetto_pratica
       and ogco.cod_fiscale(+)      = ruog.cod_fiscale
       and coru.oggetto_pratica (+) = ruog.oggetto_pratica
       and coru.cod_fiscale (+)     = ruog.cod_fiscale
       and coru.ruolo (+)           = ruog.ruolo
       and coru.anno (+)            = ruog.anno_ruolo
       and ruol.ruolo               = ruog.ruolo
-- Modifica per evitare inserimento di record N4 con imposta a zero  (Salvatore 28-05-09)
       and nvl(ruog.importo,0)      > 0
       and
          ( ruog.tipo_tributo||'' <> 'TARSU'
             or
             ( ruog.tipo_tributo||'' = 'TARSU'
              and (ogpr.OGGETTO_PRATICA_RIF_AP is null
                 or  not exists ( select ogim2.oggetto_pratica
                                    from ruoli_contribuente ruco2
                                       , oggetti_imposta    ogim2
                                   where ruco2.oggetto_imposta = ogim2.oggetto_imposta
                                     and ogim2.oggetto_pratica = ogpr.oggetto_pratica_rif_ap
                                     and ruco2.ruolo           = w_ruolo
                                     and ruco2.tributo         = ruog.tributo
                                 )
                   )
              )
           )
       and ruog.ruolo               = w_ruolo
     order by sogg.tipo_residente,
              sogg.ni,
              decode(w_specie_ruolo
                 ,1,prtr.anno
                 ,ruol.anno_ruolo
                 ),
              ruog.tributo,
              nvl(decode(motivo_compensazione,99,null,coru.compensazione),0) desc,
              ruog.categoria
              ;
--Fine cursore sel_ruog
  CURSOR sel_ered (p_ni number) IS
      select 'N3'
             ||lpad(w_comune_ruolo, 6, '0')
             ||lpad(to_char(w_conta_ruolo),2,'0')
             ||lpad(erso.ni, 14)
             ||rpad(nvl(sogg.cod_fiscale,sogg.partita_iva), 16, ' ')
             ||'000000'
             ||decode(w_cod_istat
                     ,'001219'   -- Rivoli
                     ,rpad(substr(
                          decode(sogg.cod_via
                                  ,to_number(null),sogg.denominazione_via
                                  ,arvi.denom_uff
                                  )
                             ||' '||to_char(sogg.num_civ)
                             ||decode(sogg.suffisso,'','','/'||sogg.suffisso)
                             ||decode(sogg.scala,'','',' Sc.'||sogg.scala)
                             ||decode(sogg.piano,'','',' P.'||sogg.piano)
                             ||decode(sogg.interno,'','',' Int.'||sogg.interno)
                                 ,1,43)
                          ,43,' '
                          )
                     ,rpad(decode(sogg.cod_via,
                                   null,
                                   nvl(substr(sogg.denominazione_via, 1, 30),
                                       ' '),
                                   substr(arvi.denom_uff, 1, 30)),
                            30,
                            ' ') ||
                      lpad(nvl(sogg.num_civ, 0), 5, '0') ||
                      rpad(nvl(substr(sogg.suffisso, 1, 2), ' '), 2, ' ') ||
                      decode(w_cod_istat
                            ,'015206',rpad(nvl(sogg.scala,' '),6)
                            ,'001219',rpad(nvl(sogg.scala,' '),6)
                            ,'000000'
                            )
                      )
             ||lpad(nvl(nvl(sogg.cap, adco1.cap), 0), 5, '0')
             ||rpad(nvl(adco1.sigla_cfis, ' '), 4, ' ')
             ||decode(sign(nvl(adco1.provincia_stato,0) - 199)
                    ,-1,rpad(' ', 21, ' ')
                    ,0,rpad(' ', 21, ' ')
                    ,1,rpad(substr(adco1.denominazione,1,21), 21, ' ')
                    )
             -- INIZIO GESTIONE DATI DEL NI PRESSO
             ||'000000'
             ||decode(w_cod_istat
                     ,'001219'   -- Rivoli
                     ,rpad(substr(
                          decode(sogg2.cod_via
                                  ,to_number(null),sogg2.denominazione_via
                                  ,arvi2.denom_uff
                                  )
                             ||' '||to_char(sogg2.num_civ)
                             ||decode(sogg2.suffisso,'','','/'||sogg2.suffisso)
                             ||decode(sogg2.scala,'','',' Sc.'||sogg2.scala)
                             ||decode(sogg2.piano,'','',' P.'||sogg2.piano)
                             ||decode(sogg2.interno,'','',' Int.'||sogg2.interno)
                                 ,1,43)
                          ,43,' '
                          )
                     ,rpad(decode(sogg2.cod_via,
                                   null,
                                   nvl(substr(sogg2.denominazione_via, 1, 30),
                                       ' '),
                                   substr(arvi2.denom_uff, 1, 30)),
                            30,
                            ' ') ||
                      lpad(nvl(sogg2.num_civ, 0), 5, '0') ||
                      rpad(nvl(substr(sogg2.suffisso, 1, 2), ' '), 2, ' ') ||
                      decode(w_cod_istat
                            ,'015206',rpad(nvl(sogg2.scala,' '),6)
                            ,'001219',rpad(nvl(sogg2.scala,' '),6)
                            ,'000000'
                            )
                     )
             ||lpad(nvl(nvl(sogg2.cap, adco3.cap), 0), 5, '0')
             ||rpad(nvl(adco3.sigla_cfis, ' '), 4, ' ')
             ||decode(sign(nvl(adco3.provincia_stato,0) - 199)
                    ,-1,rpad(' ', 21, ' ')
                    ,0,rpad(' ', 21, ' ')
                    ,1,rpad(substr(adco3.denominazione,1,21), 21, ' ')
                    )
             -- FINE GESTIONE DATI DEL NI PRESSO
             ||decode(nvl(sogg.tipo, 0),
                     0,
                     1,
                     1,
                     2,
                     decode(length(nvl(sogg.cod_fiscale,sogg.partita_iva)), 16, 1, 2))                riga_200
           , decode(nvl(sogg.tipo, 0)
                   ,0,rpad(nvl(substr(upper(sogg.cognome_nome)
                                     ,1,instr(upper(sogg.cognome_nome), '/') - 1
                                     ),' ')
                          ,24,' ')
                    ||rpad(nvl(substr(upper(sogg.cognome_nome)
                                     ,instr(upper(sogg.cognome_nome), '/') + 1
                                     ),' ')
                          ,20,' ')
                    || nvl(sogg.sesso, ' ')
                    ||decode(sogg.data_nas,
                           null,
                           '00000000',
                           to_char(sogg.data_nas, 'ddmmyyyy'))
                    ||rpad(nvl(adco2.sigla_cfis, ' '), 4, ' ')
                    ||rpad(' ', 19, ' ')
                   ,1,rpad(nvl(upper(sogg.cognome_nome), ' '), 76, ' ')
                   ,decode(length(nvl(sogg.cod_fiscale,sogg.partita_iva))
                          ,16,rpad(nvl(substr(upper(sogg.cognome_nome)
                                             ,1,instr(upper(sogg.cognome_nome),'/') - 1
                                             ),' ')
                                  ,24,' ')
                              ||rpad(nvl(substr(upper(sogg.cognome_nome)
                                                     ,instr(upper(sogg.cognome_nome),'/') + 1
                                                     ),' ')
                                    ,20,' ')
                              ||nvl(sogg.sesso, ' ')
                              ||decode(sogg.data_nas
                                      ,null,'00000000'
                                      ,to_char(sogg.data_nas, 'ddmmyyyy')
                                      )
                              ||rpad(nvl(adco2.sigla_cfis, ' '), 4, ' ')
                              ||rpad(' ', 19, ' ')
                          ,rpad(nvl(upper(sogg.cognome_nome), ' '),76,' ')
                          )
                    )
              || rpad(' ', 15, ' ')                                             riga_100
        from ad4_comuni     adco1,
             ad4_comuni     adco2,
             archivio_vie   arvi,
             ad4_comuni     adco3,
             archivio_vie   arvi2,
             soggetti       sogg,
             soggetti       sogg2,
             eredi_soggetto erso
       where sogg.cod_pro_res = adco1.provincia_stato(+)
         and sogg.cod_com_res = adco1.comune(+)
         and sogg.cod_pro_nas = adco2.provincia_stato(+)
         and sogg.cod_com_nas = adco2.comune(+)
         and arvi.cod_via(+) = sogg.cod_via
         and sogg.ni = erso.ni_erede
         and erso.ni = p_ni
         and sogg.ni_presso = sogg2.ni(+)
         and arvi2.cod_via(+) = sogg2.cod_via
         and sogg2.cod_pro_res = adco3.provincia_stato(+)
         and sogg2.cod_com_res = adco3.comune(+)
         ;
BEGIN
  w_ni_display := null;
  BEGIN
    select fase_euro into w_fase_euro from dati_generali;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      w_errore := 'Dati Generali Assenti.';
      RAISE ERRORE;
    WHEN others THEN
      w_errore := 'Errore in ricerca Dati Generali.' || ' (' || SQLERRM || ')';
      RAISE errore;
  END;
  if w_fase_euro = 1 then
    w_100 := 1;
  else
    w_100 := 100;
  end if;
  BEGIN
    select count(*)
      into w_num_ruoli
      from parametri
     where parametri.sessione = a_sessione
       and parametri.nome_parametro = a_nome_p;
  EXCEPTION
    WHEN no_data_found THEN
      null;
    WHEN others THEN
      w_errore := 'Errore in conteggio totale ruoli.' || ' (' || SQLERRM || ')';
      RAISE errore;
  END;
  -- Estrazione dei dati del Comune
  -- per verificare se si tratta di:
  -- Sassuolo
  -- Bagno di Romagna
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
  FOR rec_para IN sel_para LOOP
    w_ruolo       := to_number(rec_para.valore);
    w_conta_ruolo := w_conta_ruolo + 1;
    BEGIN
      select tipo_tributo,
         --    decode(tipo_ruolo
         --          ,2,3
         --          ,tipo_ruolo) ,
             1,
             specie_ruolo,
             cod_sede,
             rate,
             anno_ruolo,
             importo_lordo
        into w_tipo_tributo,
             w_tipo_ruolo,
             w_specie_ruolo,
             w_cod_sede,
             w_rate,
             w_anno_ruolo,
             w_importo_lordo
        from ruoli
       where ruolo = w_ruolo;
    EXCEPTION
      WHEN no_data_found THEN
        w_errore := 'Errore in ricerca Ruoli. (1)' || ' (' || SQLERRM || ')';
        RAISE errore;
      WHEN others THEN
        null;
    END;
    --   CONTROLLO ICIAP
    BEGIN
      select 1 into w_flag_iciap from dual where w_tipo_tributo = 'ICIAP';
    EXCEPTION
      WHEN no_data_found THEN
        null;
      WHEN others THEN
        w_errore := 'Errore in controllo ICIAP.' || ' (' || SQLERRM || ')';
        RAISE errore;
    END;
    --   CONTROLLO IRL 1
    BEGIN
      select 1
        into w_flag_errore
        from dati_generali
       where pro_cliente is null
         and com_cliente is null;
      RAISE too_many_rows;
    EXCEPTION
      WHEN no_data_found THEN
        null;
      WHEN too_many_rows THEN
        w_errore := 'Elaborazione terminata con anomalie:
                          mancano i codici identificativi del Comune.
                          Caricare la tabella relativa. ' || ' (' ||
                    SQLERRM || ')';
        RAISE errore;
      WHEN others THEN
        w_errore := 'Errore in ricerca Dati Generali. (1)' || ' (' ||
                    SQLERRM || ')';
        RAISE errore;
    END;
    --   SEL CODICI
    BEGIN
      select lpad(cod_comune_ruolo, 6, '0')
        into w_comune_ruolo
        from dati_generali;
    EXCEPTION
      WHEN no_data_found THEN
        w_errore := 'Codice Ente Impositore errato o mancante.' || ' (' ||
                    SQLERRM || ')';
        RAISE errore;
      WHEN others THEN
        w_errore := 'Errore in ricerca Dati Generali. (2)' || ' (' ||
                    SQLERRM || ')';
        RAISE errore;
    END;
    --   CONTROLLO IRL 2
    BEGIN
      select 1
        into w_flag_errore
        from tipi_tributo
       where (nvl(w_comune_ruolo, 0) = 0 or nvl(cod_ente, 0) = 0)
         and tipo_tributo = w_tipo_tributo;
      RAISE too_many_rows;
    EXCEPTION
      WHEN no_data_found THEN
        null;
      WHEN too_many_rows THEN
        w_errore := 'Elaborazione terminata con anomalie: ' ||
                    'mancano uno o piu'' codici identificativi ' ||
                    'del Comune. Caricarli nella tabella relativa. ' || ' (' ||
                    SQLERRM || ')';
        RAISE errore;
      WHEN others THEN
        w_errore := 'Errore in ricerca Tipi Tributo. (1)' || ' (' ||
                    SQLERRM || ')';
        RAISE errore;
    END;
    --   CONTA REC DA TRATTARE
    BEGIN
      select count(*)
        into rec_da_trattare
        from ruoli_contribuente
       where ruolo = w_ruolo
-- Modifica per evitare inserimento di record N4 con imposta a zero  (Salvatore 28-05-09)
         and nvl(importo,0)      > 0
         ;
    EXCEPTION
      WHEN no_data_found THEN
        w_errore := 'Nessun record presente nel ruolo indicato.' || ' (' ||
                    SQLERRM || ')';
        RAISE errore;
      WHEN others THEN
        w_errore := 'Errore in ricerca Ruoli. (2)' || ' (' || SQLERRM || ')';
        RAISE errore;
    END;
    --   IN TRATTAMENTO
    --   SEL N0
    IF w_conta_ruolo = 1 THEN
      BEGIN
        select 'N0' || lpad(cod_ente, 5, '0') ||
               to_char(sysdate, 'yyyymmdd') || rpad(' ', 85),
               rpad(' ', 190),
               cod_ente
          into w_riga_100, w_riga_190, w_cod_ente
          from tipi_tributo
         where tipo_tributo = w_tipo_tributo;
      EXCEPTION
        WHEN no_data_found THEN
          w_errore := 'Errore in selezione record N0.' || ' (' || SQLERRM || ')';
          RAISE errore;
        WHEN others THEN
          w_errore := 'Errore in ricerca Tipi Tributo. (2)' || ' (' ||
                      SQLERRM || ')';
          RAISE errore;
      END;
      tot_record_file := tot_record_file + 1;
      w_progressivo   := w_progressivo + 1;
      BEGIN
        insert into wrk_trasmissione_ruolo
          (ruolo, progressivo, dati)
        values
          (w_ruolo, w_progressivo, w_riga_100 || w_riga_190);
      EXCEPTION
        WHEN others THEN
          w_errore := 'Errore in inserimento record N0' || '(' || SQLERRM || ')';
          RAISE errore;
      END;
    END IF;
    --   SEL N1
    if (w_specie_ruolo = 0) then --Ruolo NON Coattivo
       w_cognome_resp := ' ';
       w_nome_resp := ' ';
    else --Ruolo Coattivo
       begin
          select nvl(ruol.cognome_resp, ' ')
               , nvl(ruol.nome_resp, ' ')
            into w_cognome_resp
               , w_nome_resp
            from ruoli ruol
           where ruol.ruolo = w_ruolo
               ;
       exception
          when others then
             w_errore := 'Errore in ricerca Cognome/Nome Resp. (' || SQLERRM || ')';
             raise errore;
       end;
    end if;
    BEGIN
      select 'N1'                                     --TRK
          || lpad(w_comune_ruolo, 6, '0')             --PROCOM
          || lpad(to_char(w_conta_ruolo),2,'0')       --MINUTA
          || decode(w_flag_iciap, 1, 1, w_tipo_ruolo) --TRUOLO
          || decode(w_tipo_ruolo, 1, '0042', '0045')  --NRUOLO
          || lpad(w_rate, 2, '0')                     --NRATE
          || nvl(w_specie_ruolo, 0)                   --FLAG-RUO
          || lpad(nvl(w_cod_sede, 0), 4, '0')         --COD_SEDE
          || '0'                                      --TIPO-COMP
          || rpad(' ', 18)                            --filler
          || decode(w_flag_iciap, 1, '1', ' ')        --FLAG_ICIAP
          || '00'                                     --NCONV
          || ' '                                      --ART89
          || rpad(w_cognome_resp, 30, ' ')            --XCOGRES
          || rpad(w_nome_resp, 30, ' ')               --XNOMRES
           , rpad(' ', 185)                           --filler
        into w_riga, w_riga_185
        from dual;
    EXCEPTION
      WHEN no_data_found THEN
        w_errore := 'Errore in selezione record N1.' || ' (' || SQLERRM || ')';
        RAISE errore;
      WHEN others THEN
        w_errore := 'Errore in ricerca Ruoli. (3)' || ' (' || SQLERRM || ')';
        RAISE errore;
    END;
    tot_record_file := tot_record_file + 1;
    w_progressivo   := w_progressivo + 1;
    BEGIN
      insert into wrk_trasmissione_ruolo
        (ruolo, progressivo, dati)
      values
        (w_ruolo, w_progressivo, w_riga || w_riga_185);
    EXCEPTION
      WHEN others THEN
        w_errore := 'Errore in inserimento record N1' || '(' || SQLERRM || ')';
        RAISE errore;
    END;
    tot_record_n1_file  := tot_record_n1_file + 1;
    tot_record_ruolo    := 1;
    tot_record_n2_ruolo := 0;
    tot_record_n3_ruolo := 0;
    tot_record_n4_ruolo := 0;
    tot_imposta_ruolo   := 0;
    rec_trattati        := 0;
    rec_trattati        := 0;
    w_ni_prec           := 0;
    w_tipo_resid_prec   := 0;
    w_tributo_prec      := 0;
    w_anno_ruolo_prec   := 0;
    w_imponibile_prec   := 0;
    w_imposta           := 0;
    w_imposta_contrib   := 0;
    w_compensazione     := 0;
    --w_compensazione_sum := 0;
    --   TRATTAMENTO
    FOR rec_ruog IN sel_ruog LOOP
      w_ni_display := rec_ruog.ni;
      rec_trattati := rec_trattati + 1;
      --Modifica fatta per eliminare dal cursore principale la tabella tariffe
      -- Piero 29/09/2008
      if rec_ruog.ruol_specie_ruolo <> 1 then  -- ruolo NON Coattivo
        if w_cod_istat in ('036040','012096','020054') then
         -- estrazioni dati tariffe
           begin
             select tari.descrizione
                  , tari.tariffa
               into w_tari_descrizione
                  , w_tari_tariffa
               from tariffe tari
              where tari.tributo      = rec_ruog.ogpr_tributo
                and tari.categoria    = rec_ruog.ogpr_categoria
                and tari.tipo_tariffa = rec_ruog.ogpr_tipo_tariffa
                and tari.anno         = rec_ruog.anno_ruolo
                ;
           exception
              when others then
                 w_tari_descrizione  := '';
                 w_tari_tariffa      := '';
           end;
        end if;
        if w_cod_istat = '036040' then
        -- Sassuolo
          select substr(w_tari_descrizione, 1, 24) || ' L' ||
                 trunc(substr(w_tari_tariffa, 1, 6)) || ' MQ' ||
                 trunc(substr(rec_ruog.ogpr_consistenza, 1, 7)) ||
                 decode(rec_ruog.prtr_tipo_pratica,
                        'D',
                        decode(rec_ruog.arvi_cod_via,
                               null,
                               to_char(null),
                               ' ' || substr(rec_ruog.arvi_denom_uff, 1, 19) || ' ' ||
                               rec_ruog.ogge_num_civ ||
                               decode(rec_ruog.ogge_suffisso,
                                      null,
                                      to_char(null),
                                      '/' || rec_ruog.ogge_suffisso)
                              ),
                         decode(rec_ruog.prtr_note,
                                null,
                                to_char(null),
                                ' ' || substr(rec_ruog.prtr_note, 1, 14)
                               ) ||
                         decode(rec_ruog.prtr_data_notifica,
                                null,
                                to_char(null),
                                ' Not. ' ||
                                to_char(rec_ruog.prtr_data_notifica, 'dd/mm/yyyy')
                               )
                       )
            into w_cat_indir
            from dual
                                       ;
        elsif w_cod_istat = '012096' then
      -- Malnate
          select decode(rec_ruog.cate_flag_domestica,
                       'S',
                       decode(sign(2004 - rec_ruog.anno_ruolo),
                               -1,
                               rpad('CAT.' || rec_ruog.cate_categoria || ' ' ||
                               substr(w_tari_descrizione, 1, 18) ||
                               ' OCC.' ||
                               f_ultimo_faso(rec_ruog.sogg_ni,
                                             rec_ruog.anno_ruolo),
                               34),
                               substr(rec_ruog.cate_descrizione, 1, 34)
                             ),
                       substr(rec_ruog.cate_descrizione, 1, 34)
                       ) || ' MQ' ||
                 trunc(substr(rec_ruog.ogpr_consistenza, 1, 5)) ||
                 decode(rec_ruog.arvi_cod_via,
                        null,
                        to_char(null),
                        ' ' || substr(rec_ruog.arvi_denom_uff, 1, 19) || ' ' ||
                        rec_ruog.ogge_num_civ ||
                        decode(rec_ruog.ogge_suffisso,
                               null,
                               to_char(null),
                               '/' || rec_ruog.ogge_suffisso
                                    )
                        )
             into w_cat_indir
             from dual
             ;
        elsif w_cod_istat = '020054' then
      -- Sabbioneta
           select substr(rec_ruog.cate_descrizione, 1, 25) || ' ' ||
                  substr(w_tari_descrizione, 1, 12) || ' MQ.' ||
                  trunc(substr(rec_ruog.ogpr_consistenza, 1, 5)) ||
                  decode(rec_ruog.arvi_cod_via,
                         null,
                         to_char(null),
                         ' ' || substr(rec_ruog.arvi_denom_uff, 1, 19) || ' ' ||
                         rec_ruog.ogge_num_civ ||
                         decode(rec_ruog.ogge_suffisso,
                                null,
                                to_char(null),
                                '/' || rec_ruog.ogge_suffisso)
                        )
             into w_cat_indir
             from dual
                ;
        else  -- Utilizzo quello del cursore    Ruolo Coattivo
        --
        -- (VD - 13/10/2015: Aggiunta substr per gestire stringhe più lunghe
        --                   di 75 caratteri
        --
           w_cat_indir := substr(rec_ruog.cat_indir,1,75);
        end if;
      else -- Utilizzo quello del cursore
        --
        -- (VD - 13/10/2015: Aggiunta substr per gestire stringhe più lunghe
        --                   di 75 caratteri
        --
         w_cat_indir := substr(rec_ruog.cat_indir,1,75);
      end if;
      IF rec_ruog.ni != w_ni_prec THEN
        -- NUOVO INTESTATARIO
        IF w_ni_prec = 0 OR nvl(a_tipo_elab, ' ') != 'R' THEN
          --   TRATTA RECORD N2
          --   SEL RESIDENTE-NON RESIDENTE
          w_conta_n4 := 0;
          BEGIN
            select 'N2' || lpad(w_comune_ruolo, 6, '0') || lpad(to_char(w_conta_ruolo),2,'0') ||
                    lpad(cont.ni, 14) || rpad(cont.cod_fiscale, 16, ' ') ||
                    lpad(nvl(cont.cod_contribuente, 0), 8, '0') ||
                    lpad(nvl(cont.cod_controllo, 0), 2, '0') || '000000' ||
                    decode(w_cod_istat
                          ,'001219'   -- Rivoli
                          ,rpad(substr(
                                decode(sogg.cod_via
                                        ,to_number(null),sogg.denominazione_via
                                        ,arvi.denom_uff
                                        )
                                   ||' '||to_char(sogg.num_civ)
                                   ||decode(sogg.suffisso,'','','/'||sogg.suffisso)
                                   ||decode(sogg.scala,'','',' Sc.'||sogg.scala)
                                   ||decode(sogg.piano,'','',' P.'||sogg.piano)
                                   ||decode(sogg.interno,'','',' Int.'||sogg.interno)
                                       ,1,43)
                                ,43,' '
                                )
                          ,rpad(decode(sogg.cod_via,
                                         null,
                                         nvl(substr(sogg.denominazione_via, 1, 30),
                                             ' '),
                                         substr(arvi.denom_uff, 1, 30)),
                                  30,
                                  ' ') ||
                           lpad(nvl(sogg.num_civ, 0), 5, '0') ||
                           rpad(nvl(substr(sogg.suffisso, 1, 2), ' '), 2, ' ') ||
                           decode(w_cod_istat
                                 ,'015206',rpad(nvl(sogg.scala,' '),6)
                                 ,'001219',rpad(nvl(sogg.scala,' '),6)
                                 ,'000000'
                                 )
                           )||
                    lpad(nvl(nvl(sogg.cap, adco1.cap), 0), 5, '0') ||
                    rpad(nvl(adco1.sigla_cfis, ' '), 4, ' ') ||
                    decode(sign(nvl(adco1.provincia_stato,0) - 199)
                          ,-1,rpad(' ', 21, ' ')
                          ,0,rpad(' ', 21, ' ')
                          ,1,rpad(substr(adco1.denominazione,1,21), 21, ' ')
                          ) ||
                   -- INIZIO GESTIONE DATI DEL NI PRESSO
                    '000000' ||
                    decode(w_cod_istat
                          ,'001219'   -- Rivoli
                          ,rpad(substr(
                                decode(sogg2.cod_via
                                        ,to_number(null),sogg2.denominazione_via
                                        ,arvi2.denom_uff
                                        )
                                   ||' '||to_char(sogg2.num_civ)
                                   ||decode(sogg2.suffisso,'','','/'||sogg2.suffisso)
                                   ||decode(sogg2.scala,'','',' Sc.'||sogg2.scala)
                                   ||decode(sogg2.piano,'','',' P.'||sogg2.piano)
                                   ||decode(sogg2.interno,'','',' Int.'||sogg2.interno)
                                       ,1,43)
                                ,43,' '
                                )
                          ,rpad(decode(sogg2.cod_via,
                                         null,
                                         nvl(substr(sogg2.denominazione_via, 1, 30),
                                             ' '),
                                         substr(arvi2.denom_uff, 1, 30)),
                                  30,
                                  ' ') ||
                           lpad(nvl(sogg2.num_civ, 0), 5, '0') ||
                           rpad(nvl(substr(sogg2.suffisso, 1, 2), ' '), 2, ' ') ||
                           decode(w_cod_istat
                                 ,'015206',rpad(nvl(sogg2.scala,' '),6)
                                 ,'001219',rpad(nvl(sogg2.scala,' '),6)
                                 ,'000000'
                                 )
                          )||
                    lpad(nvl(nvl(sogg2.cap, adco3.cap), 0), 5, '0') ||
                    rpad(nvl(adco3.sigla_cfis, ' '), 4, ' ') ||
                    decode(sign(nvl(adco3.provincia_stato,0) - 199)
                          ,-1,rpad(' ', 21, ' ')
                          ,0,rpad(' ', 21, ' ')
                          ,1,rpad(substr(adco3.denominazione,1,21), 21, ' ')
                          ) ||
                   -- FINE GESTIONE DATI DEL NI PRESSO
                    decode(nvl(sogg.tipo, 0),
                           0,
                           1,
                           1,
                           2,
                           decode(length(cont.cod_fiscale), 16, 1, 2)),
                   decode(nvl(sogg.tipo, 0),
                          0,
                          rpad(nvl(substr(upper(sogg.cognome_nome),
                                          1,
                                          instr(upper(sogg.cognome_nome), '/') - 1),
                                   ' '),
                               24,
                               ' ') ||
                          rpad(nvl(substr(upper(sogg.cognome_nome),
                                          instr(upper(sogg.cognome_nome), '/') + 1),
                                   ' '),
                               20,
                               ' ') || nvl(sogg.sesso, ' ') ||
                          decode(sogg.data_nas,
                                 null,
                                 '00000000',
                                 to_char(sogg.data_nas, 'ddmmyyyy')) ||
                          rpad(nvl(adco2.sigla_cfis, ' '), 4, ' ') ||
                          rpad(' ', 19, ' '),
                          1,
                          rpad(nvl(upper(sogg.cognome_nome), ' '), 76, ' '),
                          decode(length(cont.cod_fiscale),
                                 16,
                                 rpad(nvl(substr(upper(sogg.cognome_nome),
                                                 1,
                                                 instr(upper(sogg.cognome_nome),
                                                       '/') - 1),
                                          ' '),
                                      24,
                                      ' ') || rpad(nvl(substr(upper(sogg.cognome_nome),
                                                              instr(upper(sogg.cognome_nome),
                                                                    '/') + 1),
                                                       ' '),
                                                   20,
                                                   ' ') ||
                                 nvl(sogg.sesso, ' ') ||
                                 decode(sogg.data_nas,
                                        null,
                                        '00000000',
                                        to_char(sogg.data_nas, 'ddmmyyyy')) ||
                                 rpad(nvl(adco2.sigla_cfis, ' '), 4, ' ') ||
                                 rpad(' ', 19, ' '),
                                 rpad(nvl(upper(sogg.cognome_nome), ' '),
                                      76,
                                      ' '))) || rpad(' ', 5, ' ')
              into w_riga_209, w_riga_81
              from ad4_comuni   adco1,
                   ad4_comuni   adco2,
                   archivio_vie arvi,
                   ad4_comuni   adco3,
                   archivio_vie arvi2,
                   contribuenti cont,
                   soggetti     sogg,
                   soggetti     sogg2
             where sogg.cod_pro_res = adco1.provincia_stato(+)
               and sogg.cod_com_res = adco1.comune(+)
               and sogg.cod_pro_nas = adco2.provincia_stato(+)
               and sogg.cod_com_nas = adco2.comune(+)
               and arvi.cod_via(+) = sogg.cod_via
               and sogg.ni = cont.ni
               and cont.ni = rec_ruog.ni
               and sogg.ni_presso = sogg2.ni(+)
               and arvi2.cod_via(+) = sogg2.cod_via
               and sogg2.cod_pro_res = adco3.provincia_stato(+)
               and sogg2.cod_com_res = adco3.comune(+);
          EXCEPTION
            WHEN no_data_found THEN
              w_errore := 'Errore in selezione record N2. (1)' || ' ' ||
                          to_char(w_ni_display) || ' ' || ' (' || SQLERRM || ')';
              RAISE errore;
            WHEN others THEN
              w_errore := 'Errore in ricerca Soggetti e Contribuenti. (1)' || ' ' ||
                          to_char(w_ni_display) || ' ' || ' (' || SQLERRM || ')';
              RAISE errore;
          END; --TRATTA RECORD N2
          w_progressivo := w_progressivo + 1;
          BEGIN
            insert into wrk_trasmissione_ruolo
              (ruolo, progressivo, dati)
            values
              (w_ruolo, w_progressivo, w_riga_209 || w_riga_81);
          EXCEPTION
            WHEN others THEN
              w_errore := 'Errore in inserimento record N2 (1)' || ' ' ||
                          to_char(w_ni_display) || ' ' || '(' || SQLERRM || ')';
              RAISE errore;
          END;
          tot_record_file     := tot_record_file + 1;
          tot_record_ruolo    := tot_record_ruolo + 1;
          tot_record_n2_file  := tot_record_n2_file + 1;
          tot_record_n2_ruolo := tot_record_n2_ruolo + 1;
          -- Record N3 Cointestatari (Eredi_soggetto)
          FOR rec_ered IN sel_ered(rec_ruog.ni) LOOP
             w_progressivo := w_progressivo + 1;
             BEGIN
               insert into wrk_trasmissione_ruolo
                 (ruolo, progressivo, dati)
               values
                 (w_ruolo, w_progressivo, rec_ered.riga_200 || rec_ered.riga_100);
             EXCEPTION
               WHEN others THEN
                 w_errore := 'Errore in inserimento record N3 (1)' || ' ' ||
                             to_char(rec_ruog.ni) || ' ' || '(' || SQLERRM || ')';
                 RAISE errore;
             END;
             tot_record_file     := tot_record_file + 1;
             tot_record_ruolo    := tot_record_ruolo + 1;
             tot_record_n3_file  := tot_record_n3_file + 1;
             tot_record_n3_ruolo := tot_record_n3_ruolo + 1;
          end loop;
          GOTO stesso_intestatario;
        ELSE
          --NUOVO INTESTATARIO
          -- TRATTA E COMPONI RECORD N4 PREC
          BEGIN
            select 'N4'
                || lpad(w_comune_ruolo, 6, '0')
                || lpad(to_char(w_conta_ruolo),2,'0')
                || lpad(w_ni_prec, 14)
                || w_anno_ruolo_prec
                || lpad(w_tributo_prec, 4, '0')
                || decode(w_conta_n4
                                   , 1, lpad(to_char(nvl(w_imponibile_prec, 0) * w_100), 13, '0')
                                   , '0000000000000')
                || lpad(to_char((nvl(w_imposta_contrib, 0) - nvl(w_compensazione, 0) ) * w_100), 13, '0')
                || '0000000000'
                || '  '
                || decode(w_conta_n4
                                   , 1, rpad(nvl(w_cat_indir_prec, ' '), 75, ' ')
                                   , rpad(' ', 75, ' '))
                || decode(nvl(w_specie_ruolo, 0)
                         , 1, rpad('E' || w_tipo_pratica_prec || w_numero_prec, 12)
                           || rpad(decode (w_cod_istat
                                          ,'020018', nvl(w_data_notifica_prec,' ')
                                          ,' ')
                                  , 21, ' ')
                         , decode(w_tipo_ruolo
                                 ,1, rpad('EISCRIZIONE SU AUTODENUNCIA', 33)
                                 ,decode(w_cod_istat
                                        ,'050029',rpad(w_Pontedera_1_prec, 33)
                                        ,rpad('E' || w_tipo_pratica_prec || w_numero_prec || ' DEL ' || w_data_prec, 33)
                                        )
                                 )
                         )
                 , rpad(' ', 112)
                 , tot_imposta_ruolo + (nvl(w_imposta_contrib, 0) - nvl(w_compensazione, 0) ) * w_100
            into w_riga_178
               , w_riga_112
               , tot_imposta_ruolo
            from dual;
          EXCEPTION
            WHEN no_data_found THEN
              w_errore := 'Errore in selezione record N4 precedente. (1)' || ' ' ||
                          to_char(w_ni_display) || ' ' || ' (' || SQLERRM || ')';
              RAISE errore;
            WHEN others THEN
              w_errore := 'Errore in ricerca record N4 precedente. (1)' || ' ' ||
                          to_char(w_ni_display) || ' ' || ' (' || SQLERRM || ')';
              RAISE errore;
          END; --TRATTA RECORD N4 PREC
          w_progressivo := w_progressivo + 1;
          BEGIN
            insert into wrk_trasmissione_ruolo
              (ruolo, progressivo, dati)
            values
              (w_ruolo, w_progressivo, w_riga_178 || w_riga_112);
          EXCEPTION
            WHEN others THEN
              w_errore := 'Errore in inserimento record N4 precedente (1)' || ' ' ||
                          to_char(w_ni_display) || ' ' || '(' || SQLERRM || ')';
              RAISE errore;
          END;
          tot_record_file     := tot_record_file + 1;
          tot_record_ruolo    := tot_record_ruolo + 1;
          tot_record_n4_file  := tot_record_n4_file + 1;
          tot_record_n4_ruolo := tot_record_n4_ruolo + 1;
          w_imposta_contrib   := 0;
          w_compensazione     := 0;
          --   TRATTA RECORD N2
          --   SEL RESIDENTE-NON RESIDENTE
          w_conta_n4 := 0;
          BEGIN
            select 'N2' || lpad(w_comune_ruolo, 6, '0') || lpad(to_char(w_conta_ruolo),2,'0') ||
                    lpad(cont.ni, 14) || rpad(cont.cod_fiscale, 16, ' ') ||
                    lpad(nvl(cont.cod_contribuente, 0), 8, '0') ||
                    lpad(nvl(cont.cod_controllo, 0), 2, '0') || '000000' ||
                    decode(w_cod_istat
                          ,'001219'   -- Rivoli
                          ,rpad(substr(
                                decode(sogg.cod_via
                                        ,to_number(null),sogg.denominazione_via
                                        ,arvi.denom_uff
                                        )
                                   ||' '||to_char(sogg.num_civ)
                                   ||decode(sogg.suffisso,'','','/'||sogg.suffisso)
                                   ||decode(sogg.scala,'','',' Sc.'||sogg.scala)
                                   ||decode(sogg.piano,'','',' P.'||sogg.piano)
                                   ||decode(sogg.interno,'','',' Int.'||sogg.interno)
                                       ,1,43)
                                ,43,' '
                                )
                          ,rpad(decode(sogg.cod_via,
                                         null,
                                         nvl(substr(sogg.denominazione_via, 1, 30),
                                             ' '),
                                         substr(arvi.denom_uff, 1, 30)),
                                  30,
                                  ' ') ||
                           lpad(nvl(sogg.num_civ, 0), 5, '0') ||
                           rpad(nvl(substr(sogg.suffisso, 1, 2), ' '), 2, ' ') ||
                           decode(w_cod_istat
                                 ,'015206',rpad(nvl(sogg.scala,' '),6)
                                 ,'001219',rpad(nvl(sogg.scala,' '),6)
                                 ,'000000'
                                 )
                           )||
                    lpad(nvl(nvl(sogg.cap, adco1.cap), 0), 5, '0') ||
                    rpad(nvl(adco1.sigla_cfis, ' '), 4, ' ') ||
                    decode(sign(nvl(adco1.provincia_stato,0) - 199)
                          ,-1,rpad(' ', 21, ' ')
                          ,0,rpad(' ', 21, ' ')
                          ,1,rpad(substr(adco1.denominazione,1,21), 21, ' ')
                          )  ||
                   -- INIZIO GESTIONE DATI DEL NI PRESSO
                    '000000' ||
                    decode(w_cod_istat
                          ,'001219'   -- Rivoli
                          ,rpad(substr(
                                decode(sogg2.cod_via
                                        ,to_number(null),sogg2.denominazione_via
                                        ,arvi2.denom_uff
                                        )
                                   ||' '||to_char(sogg2.num_civ)
                                   ||decode(sogg2.suffisso,'','','/'||sogg2.suffisso)
                                   ||decode(sogg2.scala,'','',' Sc.'||sogg2.scala)
                                   ||decode(sogg2.piano,'','',' P.'||sogg2.piano)
                                   ||decode(sogg2.interno,'','',' Int.'||sogg2.interno)
                                       ,1,43)
                                ,43,' '
                                )
                          ,rpad(decode(sogg2.cod_via,
                                         null,
                                         nvl(substr(sogg2.denominazione_via, 1, 30),
                                             ' '),
                                         substr(arvi2.denom_uff, 1, 30)),
                                  30,
                                  ' ') ||
                           lpad(nvl(sogg2.num_civ, 0), 5, '0') ||
                           rpad(nvl(substr(sogg2.suffisso, 1, 2), ' '), 2, ' ') ||
                           decode(w_cod_istat
                                 ,'015206',rpad(nvl(sogg2.scala,' '),6)
                                 ,'001219',rpad(nvl(sogg2.scala,' '),6)
                                 ,'000000'
                                 )
                          )||
                    lpad(nvl(nvl(sogg2.cap, adco3.cap), 0), 5, '0') ||
                    rpad(nvl(adco3.sigla_cfis, ' '), 4, ' ') ||
                    decode(sign(nvl(adco3.provincia_stato,0) - 199)
                          ,-1,rpad(' ', 21, ' ')
                          ,0,rpad(' ', 21, ' ')
                          ,1,rpad(substr(adco3.denominazione,1,21), 21, ' ')
                          )  ||
                   -- FINE GESTIONE DATI DEL NI PRESSO
                    decode(nvl(sogg.tipo, 0),
                           0,
                           1,
                           1,
                           2,
                           decode(length(cont.cod_fiscale), 16, 1, 2)),
                   decode(nvl(sogg.tipo, 0),
                          0,
                          rpad(nvl(substr(upper(sogg.cognome_nome),
                                          1,
                                          instr(upper(sogg.cognome_nome), '/') - 1),
                                   ' '),
                               24,
                               ' ') ||
                          rpad(nvl(substr(upper(sogg.cognome_nome),
                                          instr(upper(sogg.cognome_nome), '/') + 1),
                                   ' '),
                               20,
                               ' ') || nvl(sogg.sesso, ' ') ||
                          decode(sogg.data_nas,
                                 null,
                                 '00000000',
                                 to_char(sogg.data_nas, 'ddmmyyyy')) ||
                          rpad(nvl(adco2.sigla_cfis, ' '), 4, ' ') ||
                          rpad(' ', 19, ' '),
                          1,
                          rpad(nvl(upper(sogg.cognome_nome), ' '), 76, ' '),
                          decode(length(cont.cod_fiscale),
                                 16,
                                 rpad(nvl(substr(upper(sogg.cognome_nome),
                                                 1,
                                                 instr(upper(sogg.cognome_nome),
                                                       '/') - 1),
                                          ' '),
                                      24,
                                      ' ') || rpad(nvl(substr(upper(sogg.cognome_nome),
                                                              instr(upper(sogg.cognome_nome),
                                                                    '/') + 1),
                                                       ' '),
                                                   20,
                                                   ' ') ||
                                 nvl(sogg.sesso, ' ') ||
                                 decode(sogg.data_nas,
                                        null,
                                        '00000000',
                                        to_char(sogg.data_nas, 'ddmmyyyy')) ||
                                 rpad(nvl(adco2.sigla_cfis, ' '), 4, ' ') ||
                                 rpad(' ', 19, ' '),
                                 rpad(nvl(upper(sogg.cognome_nome), ' '),
                                      76,
                                      ' '))) || rpad(' ', 5, ' ')
              into w_riga_209, w_riga_81
              from ad4_comuni   adco1,
                   ad4_comuni   adco2,
                   archivio_vie arvi,
                   ad4_comuni   adco3,
                   archivio_vie arvi2,
                   contribuenti cont,
                   soggetti     sogg,
                   soggetti     sogg2
             where sogg.cod_pro_res = adco1.provincia_stato(+)
               and sogg.cod_com_res = adco1.comune(+)
               and sogg.cod_pro_nas = adco2.provincia_stato(+)
               and sogg.cod_com_nas = adco2.comune(+)
               and arvi.cod_via(+) = sogg.cod_via
               and sogg.ni = cont.ni
               and cont.ni = rec_ruog.ni
               and sogg.ni_presso = sogg2.ni(+)
               and arvi2.cod_via(+) = sogg2.cod_via
               and sogg2.cod_pro_res = adco3.provincia_stato(+)
               and sogg2.cod_com_res = adco3.comune(+);
          EXCEPTION
            WHEN no_data_found THEN
              w_errore := 'Errore in selezione record N2. (2) ' || ' ' ||
                          to_char(w_ni_display) || ' ' || ' (' || SQLERRM || ')';
              RAISE errore;
            WHEN others THEN
              w_errore := 'Errore in ricerca Soggetti e Contribuenti. (2)' || ' ' ||
                          to_char(w_ni_display) || ' ' || ' (' || SQLERRM || ')';
              RAISE errore;
          END; --TRATTA RECORD N2
          w_progressivo := w_progressivo + 1;
          BEGIN
            insert into wrk_trasmissione_ruolo
              (ruolo, progressivo, dati)
            values
              (w_ruolo, w_progressivo, w_riga_209 || w_riga_81);
          EXCEPTION
            WHEN others THEN
              w_errore := 'Errore in inserimento record N2 (2)' || ' ' ||
                          to_char(w_ni_display) || ' ' || '(' || SQLERRM || ')';
              RAISE errore;
          END;
          tot_record_file     := tot_record_file + 1;
          tot_record_ruolo    := tot_record_ruolo + 1;
          tot_record_n2_file  := tot_record_n2_file + 1;
          tot_record_n2_ruolo := tot_record_n2_ruolo + 1;
          -- Record N3 Cointestatari (Eredi_soggetto)
          FOR rec_ered IN sel_ered(rec_ruog.ni) LOOP
             w_progressivo := w_progressivo + 1;
             BEGIN
               insert into wrk_trasmissione_ruolo
                 (ruolo, progressivo, dati)
               values
                 (w_ruolo, w_progressivo, rec_ered.riga_200 || rec_ered.riga_100);
             EXCEPTION
               WHEN others THEN
                 w_errore := 'Errore in inserimento record N3 (1)' || ' ' ||
                             to_char(rec_ruog.ni) || ' ' || '(' || SQLERRM || ')';
                 RAISE errore;
             END;
             tot_record_file     := tot_record_file + 1;
             tot_record_ruolo    := tot_record_ruolo + 1;
             tot_record_n3_file  := tot_record_n3_file + 1;
             tot_record_n3_ruolo := tot_record_n3_ruolo + 1;
          end loop;
          GOTO somma;
        END IF;
      END IF; --NUOVO INTESTATARIO
      <<stesso_intestatario>>
      null;
      -- STESSO INTESTATARIO
      IF nvl(a_tipo_elab, ' ') != 'R' OR
         (rec_ruog.tributo != w_tributo_prec AND w_tributo_prec != 0) OR
         (rec_ruog.anno_ruolo != w_anno_ruolo_prec AND
          w_anno_ruolo_prec != 0) THEN
        -- TRATTA E COMPONI RECORD N4
        w_conta_n4 := 0;
        if  (w_compensazione > 0 and nvl(a_tipo_elab, ' ') = 'R')
         or (rec_ruog.compensazione > 0 and nvl(a_tipo_elab, ' ') != 'R')then  -- GESTIONE COMPENSAZIONE
           BEGIN
             select 'N4'
                 || lpad(w_comune_ruolo, 6, '0')
                 || lpad(to_char(w_conta_ruolo),2,'0')
                 || lpad(rec_ruog.ni, 14)
                 || decode(a_tipo_elab
                                     , 'R', w_anno_ruolo_prec
                                     , rec_ruog.anno_ruolo)
                 || decode(a_tipo_elab
                                     , 'R', lpad(w_tributo_prec, 4, '0')
                                     , lpad(rec_ruog.tributo, 4, '0'))
                 || decode(a_tipo_elab
                                     , 'R', lpad(to_char(nvl(w_imponibile_prec, 0) * w_100), 13, '0')
                                     , lpad(to_char(nvl(rec_ruog.imponibile, 0) * w_100),  13, '0'))
                 || decode(a_tipo_elab
                                     , 'R', lpad(to_char(nvl(0 - w_compensazione, 0) * w_100), 13, '0')
                                     , lpad(to_char(nvl(0 - rec_ruog.compensazione, 0) * w_100), 13, '0'))
                 || '00'
                 || rec_ruog.decorrenza_interessi
                 || '  '
                 || decode(a_tipo_elab
                                     , 'R', rpad(nvl(w_cat_indir_prec, ' '), 75, ' ')
                                     ,  rpad(nvl(w_cat_indir, ' '), 75, ' '))
                 || decode(a_tipo_elab
                                     , 'R', decode(nvl(w_specie_ruolo, 0)
                                                                        ,  1, rpad('E' || w_tipo_pratica_prec || w_numero_prec, 12)
                                                                        || rpad(decode (w_cod_istat
                                                                                       , '020018', nvl(w_data_notifica_prec,' ')
                                                                                       ,' ')
                                                                               ,21,' ')
                                                                        , decode(w_tipo_ruolo
                                                                                            , 1, rpad('EISCRIZIONE SU AUTODENUNCIA', 33)
                                                                                            , decode(w_cod_istat
                                                                                                    ,'050029',rpad(w_Pontedera_1_prec, 33)
                                                                                                    ,rpad('E' || w_tipo_pratica_prec || w_numero_prec || ' DEL ' || w_data_prec, 33)
                                                                                                    )
                                                                                )
                                                                         )
                                      , decode(nvl(w_specie_ruolo, 0)
                                                                    ,  1, rpad('E' || rec_ruog.tipo_pratica || rec_ruog.numero, 12)
                                                                       || rpad(decode (w_cod_istat
                                                                                      , '020018', nvl(rec_ruog.data_notifica,' ')
                                                                                      ,' ')
                                                                              ,21,' ')
                                                                    , decode(w_tipo_ruolo
                                                                            , 1, rpad('EISCRIZIONE SU AUTODENUNCIA', 33)
                                                                            , decode(w_cod_istat
                                                                                    ,'050029',rpad(rec_ruog.Pontedera_1, 33)
                                                                                    ,rpad('E' || rec_ruog.tipo_pratica || rec_ruog.numero || ' DEL ' || rec_ruog.data, 33)
                                                                                   )
                                                                           )
                                             )
                          )
                 , rpad(' ', 112)
                 , tot_imposta_ruolo
                                   - decode(a_tipo_elab
                                                       , 'R', nvl(w_compensazione, 0) * w_100
                                                       , nvl(rec_ruog.compensazione, 0) * w_100)
             into w_riga_178
                , w_riga_112
                , tot_imposta_ruolo
             from dual;
           EXCEPTION
             WHEN no_data_found THEN
               w_errore := 'Errore in selezione record N4. Comp ' || ' ' ||
                           to_char(w_ni_display) || ' ' || ' (' || SQLERRM || ')';
               RAISE errore;
             WHEN others THEN
               w_errore := 'Errore in ricerca record N4. Comp ' || ' ' ||
                           to_char(w_ni_display) || ' ' || ' (' || SQLERRM || ')';
               RAISE errore;
           END; --TRATTA RECORD N4
           w_progressivo := w_progressivo + 1;
           BEGIN
             insert into wrk_trasmissione_ruolo
               (ruolo, progressivo, dati)
             values
               (w_ruolo, w_progressivo, w_riga_178 || w_riga_112);
           EXCEPTION
             WHEN others THEN
               w_errore := 'Errore in inserimento record N4 Comp ' || ' ' ||
                           to_char(w_ni_display) || ' ' || '(' || SQLERRM || ')';
               RAISE errore;
           END;
           tot_record_file     := tot_record_file + 1;
           tot_record_ruolo    := tot_record_ruolo + 1;
           tot_record_n4_file  := tot_record_n4_file + 1;
           tot_record_n4_ruolo := tot_record_n4_ruolo + 1;
        end if;
        BEGIN
          select 'N4'
              || lpad(w_comune_ruolo, 6, '0')
              || lpad(to_char(w_conta_ruolo),2,'0')
              || lpad(rec_ruog.ni, 14)
              || decode(a_tipo_elab
                                  , 'R', w_anno_ruolo_prec
                                  , rec_ruog.anno_ruolo)
              || decode(a_tipo_elab
                                  , 'R', lpad(w_tributo_prec, 4, '0')
                                  , lpad(rec_ruog.tributo, 4, '0'))
              || decode(a_tipo_elab
                                  , 'R', lpad(to_char(nvl(w_imponibile_prec, 0) * w_100), 13, '0')
                                  , lpad(to_char(nvl(rec_ruog.imponibile, 0) * w_100),  13, '0'))
              || decode(a_tipo_elab
                                  , 'R', lpad(to_char(nvl(w_imposta_contrib, 0) * w_100), 13, '0')
                                  , lpad(to_char(nvl(rec_ruog.imposta, 0) * w_100), 13, '0'))
              || '00'
              || rec_ruog.decorrenza_interessi
              || '  '
              || decode(a_tipo_elab
                                  , 'R', rpad(nvl(w_cat_indir_prec, ' '), 75, ' ')
                                  ,  rpad(nvl(w_cat_indir, ' '), 75, ' '))
              || decode(a_tipo_elab
                                  , 'R', decode(nvl(w_specie_ruolo, 0)
                                                                     ,  1, rpad('E' || w_tipo_pratica_prec || w_numero_prec, 12)
                                                                        || rpad(decode (w_cod_istat
                                                                                       , '020018', nvl(w_data_notifica_prec,' ')
                                                                                       ,' ')
                                                                               ,21,' ')
                                                                     , decode(w_tipo_ruolo
                                                                                         , 1, rpad('EISCRIZIONE SU AUTODENUNCIA', 33)
                                                                                         , decode(w_cod_istat
                                                                                                 ,'050029',rpad(w_Pontedera_1_prec, 33)
                                                                                                 ,rpad('E' || w_tipo_pratica_prec || w_numero_prec || ' DEL ' || w_data_prec, 33)
                                                                                                 )
                                                                             )
                                                                     )
                                  , decode(nvl(w_specie_ruolo, 0)
                                                                ,  1, rpad('E' || rec_ruog.tipo_pratica || rec_ruog.numero, 12)
                                                                   || rpad(decode (w_cod_istat
                                                                                  , '020018', nvl(rec_ruog.data_notifica,' ')
                                                                                  ,' ')
                                                                         ,21,' ')
                                                                , decode(w_tipo_ruolo
                                                                        , 1, rpad('EISCRIZIONE SU AUTODENUNCIA', 33)
                                                                        , decode(w_cod_istat
                                                                                ,'050029',rpad(rec_ruog.Pontedera_1, 33)
                                                                                ,rpad('E' || rec_ruog.tipo_pratica || rec_ruog.numero || ' DEL ' || rec_ruog.data, 33)
                                                                                )
                                                                        )
                                          )
                       )
              , rpad(' ', 112)
              , tot_imposta_ruolo
                                + decode(a_tipo_elab
                                                   , 'R', nvl(w_imposta_contrib, 0) * w_100
                                                   , nvl(rec_ruog.imposta, 0) * w_100)
          into w_riga_178
             , w_riga_112
             , tot_imposta_ruolo
          from dual;
        EXCEPTION
          WHEN no_data_found THEN
            w_errore := 'Errore in selezione record N4.' || ' ' ||
                        to_char(w_ni_display) || ' ' || ' (' || SQLERRM || ')';
            RAISE errore;
          WHEN others THEN
            w_errore := 'Errore in ricerca record N4.' || ' ' ||
                        to_char(w_ni_display) || ' ' || ' (' || SQLERRM || ')';
            RAISE errore;
        END; --TRATTA RECORD N4
        w_progressivo := w_progressivo + 1;
        BEGIN
          insert into wrk_trasmissione_ruolo
            (ruolo, progressivo, dati)
          values
            (w_ruolo, w_progressivo, w_riga_178 || w_riga_112);
        EXCEPTION
          WHEN others THEN
            w_errore := substr('Errore in inserimento record N4' || ' ' ||
                        to_char(w_ni_display) || ' ' || '(' || SQLERRM || ')',1,2000);
            RAISE errore;
        END;
        tot_record_file     := tot_record_file + 1;
        tot_record_ruolo    := tot_record_ruolo + 1;
        tot_record_n4_file  := tot_record_n4_file + 1;
        tot_record_n4_ruolo := tot_record_n4_ruolo + 1;
        IF nvl(a_tipo_elab, ' ') != 'R' THEN
          GOTO fine;
        ELSE
          w_imposta_contrib := 0;
          w_compensazione   := 0;
        END IF;
      END IF;
      <<somma>>
      null;
      w_imposta_contrib := w_imposta_contrib + rec_ruog.imposta;
      w_compensazione   := w_compensazione + nvl(rec_ruog.compensazione,0);
      w_conta_n4        := w_conta_n4 + 1;
      <<fine>>
      null;
      w_tipo_resid_prec    := rec_ruog.tipo_residente;
      w_ni_prec            := rec_ruog.ni;
      w_tributo_prec       := rec_ruog.tributo;
      w_anno_ruolo_prec    := rec_ruog.anno_ruolo;
      w_cat_indir_prec     := w_cat_indir;
      w_imponibile_prec    := rec_ruog.imponibile;
      w_imposta            := rec_ruog.imposta;
      w_numero_prec        := rec_ruog.numero;
      w_tipo_pratica_prec  := rec_ruog.tipo_pratica;
      w_data_prec          := rec_ruog.data;
      w_data_notifica_prec := rec_ruog.data_notifica;
      w_note_prec          := rec_ruog.note;
      w_Pontedera_1_prec   := rec_ruog.Pontedera_1;
    END LOOP;
    --   FI TRATTAMENTO
    IF nvl(a_tipo_elab, ' ') = 'R' THEN
      --   TRATTA E COMPONI RECORD N4 PREC
      BEGIN
        select 'N4'
            || lpad(w_comune_ruolo, 6, '0')
            || lpad(to_char(w_conta_ruolo),2,'0')
            || lpad(w_ni_prec, 14)
            || w_anno_ruolo_prec
            || lpad(w_tributo_prec, 4, '0')
            || decode(w_conta_n4
                               , 1, lpad(to_char(nvl(w_imponibile_prec, 0) * w_100), 13, '0')
                               , '0000000000000')
            || lpad(to_char((nvl(w_imposta_contrib, 0) - nvl(w_compensazione, 0)) * w_100), 13, '0')
            || '0000000000'
            || '  '
            || decode(w_conta_n4
                               , 1, rpad(nvl(w_cat_indir_prec, ' '), 75, ' ')
                               , rpad(' ', 75, ' '))
            || decode(nvl(w_specie_ruolo, 0)
                                           , 1, rpad('E' || w_tipo_pratica_prec || w_numero_prec, 12)
                                           || rpad(decode (w_cod_istat
                                                          , '020018', nvl(w_data_notifica_prec,' ')
                                                          ,' ')
                                                  ,21,' ')
                                           , decode(w_tipo_ruolo
                                                   ,1, rpad('EISCRIZIONE SU AUTODENUNCIA', 33)
                                                   ,decode(w_cod_istat
                                                          ,'050029',rpad(w_Pontedera_1_prec, 33)
                                                          ,rpad(' ' || w_tipo_pratica_prec || w_numero_prec || ' DEL ' || w_data_prec, 33)
                                                          )
                                                   )
                     )
           , rpad(' ', 112)
           , tot_imposta_ruolo + (nvl(w_imposta_contrib, 0) - nvl(w_compensazione, 0)) * w_100
        into w_riga_178
           , w_riga_112
           , tot_imposta_ruolo
        from dual;
      EXCEPTION
        WHEN no_data_found THEN
          w_errore := substr('Errore in selezione record N4 precedente. (2)' || ' ' ||
                      to_char(w_ni_display) || ' ' || ' (' || SQLERRM || ')',1,2000);
          RAISE errore;
        WHEN others THEN
          w_errore := substr('Errore in selezione record N4 precedente. (2)' || ' ' ||
                      to_char(w_ni_display) || ' ' || ' (' || SQLERRM || ')',1,2000);
          RAISE errore;
      END; --TRATTA RECORD N4 PREC
      w_progressivo := w_progressivo + 1;
      BEGIN
        insert into wrk_trasmissione_ruolo
          (ruolo, progressivo, dati)
        values
          (w_ruolo, w_progressivo, w_riga_178 || w_riga_112);
      EXCEPTION
        WHEN others THEN
          w_errore := substr('Errore in inserimento record N4 precedente (2)' || ' ' ||
                      to_char(w_ni_display) || ' ' || '(' || SQLERRM || ')',1,2000);
          RAISE errore;
      END;
      tot_record_file     := tot_record_file + 1;
      tot_record_ruolo    := tot_record_ruolo + 1;
      tot_record_n4_file  := tot_record_n4_file + 1;
      tot_record_n4_ruolo := tot_record_n4_ruolo + 1;
    END IF;
    tot_record_ruolo   := tot_record_ruolo + 1;
    tot_record_n5_file := tot_record_n5_file + 1;
    --   SEL N5
    BEGIN
      select 'N5' || lpad(w_comune_ruolo, 6, '0') || lpad(to_char(w_conta_ruolo),2,'0') ||
             lpad(nvl(tot_record_ruolo, 0), 7, '0') ||
             lpad(nvl(tot_record_n2_ruolo, 0), 7, '0') ||
             lpad(nvl(tot_record_n3_ruolo, 0), 7, '0') ||
             lpad(nvl(tot_record_n4_ruolo, 0), 7, '0') ||
             lpad(to_char(nvl(tot_imposta_ruolo, 0)), 15, '0') ||
             rpad(' ', 47),
             rpad(' ', 190)
        into w_riga_100, w_riga_190
        from dual;
    EXCEPTION
      WHEN no_data_found THEN
        w_errore := 'Errore in selezione record N5.' || ' ' ||
                    to_char(w_ni_display) || ' ' || ' (' || SQLERRM || ')';
        RAISE errore;
      WHEN others THEN
        w_errore := 'Errore in ricerca record N5.' || ' ' ||
                    to_char(w_ni_display) || ' ' || ' (' || SQLERRM || ')';
        RAISE errore;
    END;
    tot_record_file := tot_record_file + 1;
    w_progressivo   := w_progressivo + 1;
    BEGIN
      insert into wrk_trasmissione_ruolo
        (ruolo, progressivo, dati)
      values
        (w_ruolo, w_progressivo, w_riga_100 || w_riga_190);
    EXCEPTION
      WHEN others THEN
        w_errore := 'Errore in inserimento record N5' || ' ' ||
                    to_char(w_ni_display) || ' ' || '(' || SQLERRM || ')';
        RAISE errore;
    END;
    IF w_num_ruoli = w_conta_ruolo THEN
      tot_record_file := tot_record_file + 1;
      --   SEL N9
      BEGIN
        select 'N9' || lpad(w_cod_ente, 5, '0') ||
               lpad(nvl(tot_record_file, 0), 7, '0') ||
               lpad(nvl(tot_record_n1_file, 0), 7, '0') ||
               lpad(nvl(tot_record_n2_file, 0), 7, '0') ||
               lpad(nvl(tot_record_n3_file, 0), 7, '0') ||
               lpad(nvl(tot_record_n4_file, 0), 7, '0') ||
               lpad(nvl(tot_record_n5_file, 0), 7, '0') || rpad(' ', 51),
               rpad(' ', 190)
          into w_riga_100, w_riga_190
          from dual;
      EXCEPTION
        WHEN no_data_found THEN
          w_errore := 'Errore in selezione record N9.' || ' ' ||
                      to_char(w_ni_display) || ' ' || ' (' || SQLERRM || ')';
          RAISE errore;
        WHEN others THEN
          w_errore := 'Errore in ricerca record N9.' || ' ' ||
                      to_char(w_ni_display) || ' ' || ' (' || SQLERRM || ')';
          RAISE errore;
      END;
      w_progressivo := w_progressivo + 1;
      BEGIN
        insert into wrk_trasmissione_ruolo
          (ruolo, progressivo, dati)
        values
          (w_ruolo, w_progressivo, w_riga_100 || w_riga_190);
      EXCEPTION
        WHEN others THEN
          w_errore := 'Errore in inserimento record N9' || ' ' ||
                      to_char(w_ni_display) || ' ' || '(' || SQLERRM || ')';
          RAISE errore;
      END;
      --Verifica uilizzo pertinenze di
      begin
         select count(1)
           into w_pertinenze_di
           from oggetti_pratica  ogpr
              , pratiche_tributo prtr
          where prtr.pratica = ogpr.pratica
            and prtr.tipo_tributo = 'TARSU'
            and ogpr.oggetto_pratica_rif_ap is not null
             ;
      EXCEPTION
        WHEN others THEN
          w_pertinenze_di := 0;
      end;
      -- Con la gestione delle "Pertinenza di" non è possibile eseguire il
      -- controllo, perchè negli accertamenti non c'è ruog.oggetti_imposta
      -- Piero 28-01-2010
      IF w_pertinenze_di =  0 and rec_da_trattare != rec_trattati THEN
        w_errore := 'ELABORAZIONE TERMINATA CON ANOMALIE. ' ||
                    'TRATTAMENTO DATI INCOMPLETO.' || ' - Da trattare ' ||
                    to_char(rec_da_trattare) || ' Trattati ' ||
                    to_char(rec_trattati);
        RAISE errore;
      END IF;
    END IF;
  END LOOP;
  BEGIN
    update ruoli
       set invio_consorzio = trunc(sysdate)
     where ruolo in (select valore
                       from parametri
                      where parametri.sessione = a_sessione
                        and parametri.nome_parametro = a_nome_p);
  EXCEPTION
    WHEN others THEN
      w_errore := 'Errore in aggiornamento data invio in Ruoli' || ' (' ||
                  SQLERRM || ')';
      RAISE errore;
  END;
EXCEPTION
  WHEN errore THEN
    ROLLBACK;
    RAISE_APPLICATION_ERROR(-20999, w_errore);
  WHEN others THEN
    ROLLBACK;
    RAISE_APPLICATION_ERROR(-20999,w_ni_display||' '||
                            'Errore in Trasmissione Ruolo su supporto magnetico' || ' (' ||
                            SQLERRM || ')');
END;
/* End Procedure: TRASMISSIONE_RUOLO */
/

