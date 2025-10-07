--liquibase formatted sql 
--changeset abrandolini:20250326_152429_stampa_sgravi stripComments:false runOnChange:true 
 
create or replace package stampa_sgravi is
/**
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 001   20/12/2024  RV      #71531
                           Modificato per Componenti Perequative
 000   xx/xx/xxxx  XX      Versionme iniziale
**/
  function contribuente(a_ni           number default -1,
                        a_tipo_tributo varchar2 default '',
                        a_cod_fiscale  varchar2 default '',
                        a_ruolo        number default -2,
                        a_modello      number default -1)
    return sys_refcursor;
  function sgravio(a_tipo_tributo  varchar2 default '',
                   a_trib          number default -1,
                   a_ogge          number default -1,
                   a_cod_fiscale   varchar2 default '',
                   a_seq           number default -1,
                   a_seq_sgravio   number default -1,
                   a_ruolo         number default -2,
                   a_pratica       number default -1,
                   a_progr_sgravio number default -1,
                   a_modello       number default -1,
                   a_anno          number default -1) return sys_refcursor;
  function oggetti(a_trib        number default -1,
                   a_ogge        number default -1,
                   a_cod_fiscale varchar2 default '',
                   a_seq         number default -1,
                   a_seq_sgravio number default -1,
                   a_ruolo       number default -2,
                   a_anno        number default -1) return sys_refcursor;
  function importi(a_trib        number default -1,
                   a_ogge        number default -1,
                   a_cod_fiscale varchar2 default '',
                   a_seq         number default -1,
                   a_seq_sgravio number default -1,
                   a_ruolo       number default -2,
                   a_modello     number default -1) return sys_refcursor;
  function pratica(a_ruolo         number default -2,
                   a_cod_fiscale   varchar2 default '',
                   a_pratica       number default -1,
                   a_progr_sgravio number default -1) return sys_refcursor;
end stampa_sgravi;
/
create or replace package body stampa_sgravi is
/**
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 001   20/12/2024  RV      #71531
                           Modificato per Componenti Perequative
 000   xx/xx/xxxx  XX      Versionme iniziale
**/
---------------------------------------------------------------------
  function contribuente(a_ni           number default -1,
                        a_tipo_tributo varchar2 default '',
                        a_cod_fiscale  varchar2 default '',
                        a_ruolo        number default -2,
                        a_modello      number default -1)
    return sys_refcursor is
    rc sys_refcursor;
  begin
    rc := stampa_common.contribuenti_ente(a_ni,
                                          a_tipo_tributo,
                                          a_cod_fiscale,
                                          a_ruolo,
                                          a_modello);
    return rc;
  end;
---------------------------------------------------------------------
  function sgravio(a_tipo_tributo  varchar2 default '',
                   a_trib          number default -1,
                   a_ogge          number default -1,
                   a_cod_fiscale   varchar2 default '',
                   a_seq           number default -1,
                   a_seq_sgravio   number default -1,
                   a_ruolo         number default -2,
                   a_pratica       number default -1,
                   a_progr_sgravio number default -1,
                   a_modello       number default -1,
                   a_anno          number default -1) return sys_refcursor is
    rc   sys_refcursor;
    w_ni number;
  begin
    begin
      select ni
        into w_ni
        from contribuenti
       where cod_fiscale = a_cod_fiscale;
    exception
      when others then
        w_ni := -1;
    end;
    /*
       Sono richieste le informazioni sul contribuente più altre relative allo sgravio, ma non è possibile
       utilizzare la stampa_common.stampa_common per restituisce un refcursor.
       Per ora si ricopia l'intera query, ma deve essere studiato un modo più efficiente di procedere.
    */
    open rc for
      select a_tipo_tributo tipo_tributo,
             nvl(a_trib, -1) tributo,
             nvl(a_ogge, -1) oggetto,
             a_cod_fiscale codice_fiscale,
             a_seq sequenza,
             nvl(a_seq_sgravio, -1) sequenza_sgravio,
             prtr_sgra.*,
             a_ruolo ruolo,
             a_progr_sgravio progr_sgravio,
             a_modello modello,
             a_anno anno,
             (select decode(nvl(sgog.tipo_sgravio, 'S'),
                            'D',
                            'Discarico',
                            'R',
                            'Rimborso',
                            'Sgravio')
                from sgravi_oggetto sgog
               where sgog.cod_fiscale = a_cod_fiscale
                 and sgog.ruolo = a_ruolo
                 and sgog.sequenza = a_seq
                 and sgog.sequenza_sgravio = a_seq_sgravio
              union
              select distinct decode(nvl(sgra.tipo_sgravio, 'S'),
                                     'D',
                                     'Discarico',
                                     'R',
                                     'Rimborso',
                                     'Sgravio')
                from ruoli_contribuente ruco, sgravi sgra
               where sgra.ruolo = ruco.ruolo
                 and sgra.cod_fiscale = ruco.cod_fiscale
                 and sgra.sequenza = ruco.sequenza
                 and sgra.ruolo = a_ruolo
                 and sgra.cod_fiscale = a_cod_fiscale
                 and ruco.pratica = a_pratica
                 and sgra.progr_sgravio = a_progr_sgravio) int_sgravio,
             ------ CONTRIBUENTI_ENTE
             coen.comune_ente,
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
             coen.indirizzo,
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
             decode(coen.suffisso_dest, '', '', '/' || suffisso_dest) suffisso_dest,
             coen.scala_dest,
             coen.piano_dest,
             coen.interno_dest,
             coen.cap_dest,
             upper(coen.comune_dest) comune_dest,
             coen.provincia_dest,
             decode(f_recapito(coen.ni,
                               coen.tipo_tributo,
                               3,
                               trunc(sysdate)),
                    null,
                    null,
                    'PEC ') label_indirizzo_pec,
             f_recapito(coen.ni, coen.tipo_tributo, 3, trunc(sysdate)) indirizzo_pec,
             decode(f_recapito(coen.ni,
                               coen.tipo_tributo,
                               2,
                               trunc(sysdate)),
                    null,
                    null,
                    'E-mail ') label_indirizzo_email,
             f_recapito(coen.ni, coen.tipo_tributo, 2, trunc(sysdate)) indirizzo_email,
             decode(f_recapito(coen.ni,
                               coen.tipo_tributo,
                               4,
                               trunc(sysdate)),
                    null,
                    null,
                    'Nr. Tel. ') label_telefono_fisso,
             f_recapito(coen.ni, coen.tipo_tributo, 4, trunc(sysdate)) telefono,
             decode(f_recapito(coen.ni,
                               coen.tipo_tributo,
                               6,
                               trunc(sysdate)),
                    null,
                    null,
                    'Cell. ') label_cell_personale,
             f_recapito(coen.ni, coen.tipo_tributo, 6, trunc(sysdate)) cell_personale,
             decode(f_recapito(coen.ni,
                               coen.tipo_tributo,
                               7,
                               trunc(sysdate)),
                    null,
                    null,
                    'Cell. Ufficio ') label_cell_lavoro,
             f_recapito(coen.ni, coen.tipo_tributo, 7, trunc(sysdate)) cell_lavoro,
             decode(coen.tipo_residente || coen.tipo,
                    -- (VD - 28/01/2022): Non si indica più il legale rappresentante
                    11,
                    coen.cognome_nome, --decode(coen.label_rap,'',coen.cognome_nome,coen.rappresentante),
                    decode(coen.erede_di,
                           '',
                           decode(coen.stato, 50, 'Eredi di ', '') ||
                           coen.cognome_nome,
                           coen.cognome_nome_erede)) riga_destinatario_1,
             decode(coen.tipo_residente || coen.tipo,
                    -- (VD - 28/01/2022): Non si indica più il legale rappresentante
                    11,
                    coen.presso, --decode(coen.label_rap,'',coen.presso,coen.descr_carica||' '||coen.cognome_nome),
                    decode(coen.erede_di,
                           '',
                           coen.presso,
                           coen.erede_di || ' ' || coen.cognome_nome ||
                           decode(coen.presso_erede,
                                  '',
                                  '',
                                  ' ' || coen.presso_erede))) riga_destinatario_2,
             ltrim(decode(coen.scala_dest,
                          '',
                          '',
                          'Scala ' || coen.scala_dest) ||
                   decode(coen.piano_dest,
                          '',
                          '',
                          ' Piano ' || coen.piano_dest) ||
                   decode(coen.interno_dest,
                          '',
                          '',
                          ' Int. ' || coen.interno_dest)) riga_destinatario_3,
             coen.via_dest || ' ' || coen.num_civ_dest ||
             decode(coen.suffisso_dest, '', '', '/' || coen.suffisso_dest) riga_destinatario_4,
             coen.cap_dest || ' ' || coen.comune_dest || ' ' ||
             coen.provincia_dest riga_destinatario_5,
             f_descrizione_titr(coen.tipo_tributo,
                                to_number(to_char(sysdate, 'yyyy'))) descr_titr,
             a_ruolo ruolo,
             a_modello modello
        from contribuenti_ente coen,
             (select nvl(prtr.pratica, -1) pratica,
                     decode(prtr.tipo_pratica,
                            'L',
                            'Liquidazione',
                            'A',
                            'Accertamento',
                            null) tipo_pratica_desc,
                     prtr.numero pratica_numero,
                     prtr.anno pratica_anno,
                     prtr.data pratica_data,
                     prtr.data_notifica pratica_data_notifica
                from pratiche_tributo prtr
               where prtr.pratica = a_pratica
              union all
              select -1, null, null, null, null, null
                from dual
               where not exists (select 1
                        from pratiche_tributo prtr1
                       where prtr1.pratica = a_pratica)) prtr_sgra
       where coen.ni = w_ni
         and coen.tipo_tributo = a_tipo_tributo;

    return rc;
  end;
---------------------------------------------------------------------
  function oggetti(a_trib        number default -1,
                   a_ogge        number default -1,
                   a_cod_fiscale varchar2 default '',
                   a_seq         number default -1,
                   a_seq_sgravio number default -1,
                   a_ruolo       number default -2,
                   a_anno        number default -1) return sys_refcursor is
    rc sys_refcursor;
  begin
    open rc for
      select ruog.anno_ruolo anno,
             cate.categoria || ' - ' || cate.descrizione categoria,
             tari.descrizione tariffa,
             decode(ogge.cod_via,
                    null,
                    ogge.indirizzo_localita,
                    arvi_ogge.denom_uff ||
                    decode(ogge.num_civ, null, '', ', ' || ogge.num_civ) ||
                    decode(ogge.suffisso, null, '', '/' || ogge.suffisso)) ubicazione,
             rpad('Mq. ' || ogpr.consistenza,
                  decode(giorni_sgravio, null, 15, 12)) superficie,
             '% possesso ' ||
             translate(to_char(ogco.perc_possesso, '990.00'), ',.', '.,') perc_possesso,
             'Attiva dal ' ||
             decode(greatest(to_number(nvl(to_char(ogva.al, 'yyyy'),
                                           ruog.anno_ruolo)),
                             ruog.anno_ruolo),
                    ruog.anno_ruolo,
                    to_char(nvl(ogva.dal,
                                to_date('0101' || ruog.anno_ruolo, 'ddmmyyyy')),
                            'dd/mm/yyyy'),
                    to_char(greatest(nvl(ogva.dal,
                                         to_date('0101' || ruog.anno_ruolo,
                                                 'ddmmyyyy')),
                                     to_date('0101' || ruog.anno_ruolo,
                                             'ddmmyyyy')),
                            'dd/mm/yyyy')) || ' al ' ||
             decode(greatest(to_number(nvl(to_char(ogva.al, 'yyyy'),
                                           ruog.anno_ruolo)),
                             ruog.anno_ruolo),
                    ruog.anno_ruolo,
                    to_char(nvl(ogva.al,
                                to_date('3112' || ruog.anno_ruolo, 'ddmmyyyy')),
                            'dd/mm/yyyy'),
                    to_char(least(nvl(ogva.al,
                                      to_date('3112' || ruog.anno_ruolo,
                                              'ddmmyyyy')),
                                  to_date('3112' || ruog.anno_ruolo,
                                          'ddmmyyyy')),
                            'dd/mm/yyyy')) validita,
             DECODE(giorni_sgravio,
                    NULL,
                    DECODE(mesi_sgravio, NULL, '', 'Mesi a Ruolo'),
                    'Giorni a Ruolo') l_familiari,
             nvl(giorni_sgravio, mesi_sgravio) familiari,
             DECODE(giorni_sgravio,
                    NULL,
                    DECODE(mesi_sgravio, NULL, '', 'Mesi a Ruolo'),
                    'Giorni a Ruolo') l_ggsgravio,
             nvl(giorni_sgravio, mesi_sgravio) ggsgravio,
             null l_giorni_ruolo,
             null giorni_ruolo,
             substr(decode(ogge.partita,
                           null,
                           '',
                           ' Partita ' || ogge.partita) ||
                    decode(ogge.sezione,
                           null,
                           '',
                           ' Sezione ' || ogge.sezione) ||
                    decode(ogge.foglio, null, '', ' Foglio ' || ogge.foglio) ||
                    decode(ogge.numero, null, '', ' Numero ' || ogge.numero) ||
                    decode(ogge.subalterno,
                           null,
                           '',
                           ' Sub. ' || ogge.subalterno) ||
                    decode(ogge.zona, null, '', ' Zona ' || ogge.zona) ||
                    decode(ogge.categoria_catasto,
                           null,
                           '',
                           ' Cat. ' || ogge.categoria_catasto),
                    2) estremi_catasto
        from archivio_vie         arvi_ogge,
             oggetti              ogge,
             categorie            cate,
             tariffe              tari,
             pratiche_tributo     prtr,
             oggetti_pratica      ogpr,
             oggetti_contribuente ogco,
             oggetti_validita     ogva,
             ruoli_oggetto        ruog,
             sgravi               sgra
       where arvi_ogge.cod_via(+) = ogge.cod_via
         and ogge.oggetto = ogpr.oggetto
         and cate.tributo = tari.tributo
         and cate.categoria = tari.categoria
         and tari.tributo = ogpr.tributo
         and tari.categoria = ogpr.categoria
         and tari.tipo_tariffa = ogpr.tipo_tariffa
         and tari.anno = ruog.anno_ruolo
         and prtr.tipo_tributo || '' = 'TARSU'
         and prtr.pratica = ogpr.pratica
         and ogpr.oggetto_pratica = sgra.ogpr_sgravio
         and ogco.cod_fiscale = a_cod_fiscale
         and ogco.oggetto_pratica = ogpr.oggetto_pratica
         and ogva.cod_fiscale(+) = a_cod_fiscale
         and ogva.oggetto_pratica(+) = ogpr.oggetto_pratica
         and RUOG.COD_FISCALE = SGRA.COD_FISCALE
         and RUOG.RUOLO = SGRA.RUOLO
         and RUOG.SEQUENZA = SGRA.SEQUENZA
         and RUOG.TRIBUTO = a_trib
         and RUOG.OGGETTO = a_ogge
         and RUOG.COD_FISCALE = a_cod_fiscale
         and SGRA.SEQUENZA_SGRAVIO = a_seq_sgravio
         and RUOG.sequenza = a_seq
         and RUOG.RUOLO = a_ruolo
         and ruog.anno_ruolo = a_anno
       order by 1, 2, 3, 4, 5;
    return rc;
  end;
---------------------------------------------------------------------
  function importi(a_trib        number default -1,
                   a_ogge        number default -1,
                   a_cod_fiscale varchar2 default '',
                   a_seq         number default -1,
                   a_seq_sgravio number default -1,
                   a_ruolo       number default -2,
                   a_modello     number default -1) return sys_refcursor is
    rc sys_refcursor;
  begin
    open rc for
      SELECT distinct ruog.tributo TRIB,
                      ruoli.anno_ruolo ANNO,
                      rtrim(F_DESCRIZIONE_TIMP(a_modello, 'IMPORTO_RUOLO')) TESTOTASSA,
                      rtrim(F_DESCRIZIONE_TIMP(a_modello, 'IMPORTO_CRED')) ||
                      '(1)' TESTOSGRAVIO,
                      rtrim(F_DESCRIZIONE_TIMP(a_modello, 'GIA_SGRAVATO')) TESTOGIASGRAV,
                      rtrim(F_DESCRIZIONE_TIMP(a_modello, 'RESIDUO_RUOLO')) TESTORESIDUO,
                      decode(nvl(cata.compenso_massimo, 0),
                             0,
                             '',
                             'Compenso esattoria         ' ||
                             translate(to_char(decode(sign(somma_add.lordo_a_ruolo -
                                                           cata.limite),
                                                      1,
                                                      decode(sign((cata.compenso_minimo +
                                                                  (somma_add.lordo_a_ruolo -
                                                                  cata.limite) *
                                                                  cata.perc_compenso / 100) -
                                                                  cata.compenso_massimo),
                                                             1,
                                                             cata.compenso_massimo,
                                                             cata.compenso_minimo +
                                                             ((somma_add.lordo_a_ruolo -
                                                             CATA.LIMITE) *
                                                             CATA.PERC_COMPENSO / 100)),
                                                      cata.compenso_minimo) -
                                               decode(somma_add.lordo_a_ruolo -
                                                      somma_add.imposta_lorda,
                                                      0,
                                                      0,
                                                      decode(sign(somma_add.lordo_a_ruolo -
                                                                  somma_add.imposta_lorda -
                                                                  cata.limite),
                                                             1,
                                                             decode(sign((cata.compenso_minimo +
                                                                         (somma_add.lordo_a_ruolo -
                                                                         somma_add.imposta_lorda -
                                                                         cata.limite) *
                                                                         cata.perc_compenso / 100) -
                                                                         cata.compenso_massimo),
                                                                    1,
                                                                    cata.compenso_massimo,
                                                                    cata.compenso_minimo +
                                                                    ((somma_add.lordo_a_ruolo -
                                                                    somma_add.imposta_lorda -
                                                                    cata.limite) *
                                                                    cata.perc_compenso / 100)),
                                                             cata.compenso_minimo)),
                                               '9,999,999,999,990.00'),
                                       ',.',
                                       '.,')) compenso_esattoria,
                      decode(ruog.numero_cartella,
                             null,
                             decode(ruog.data_cartella,
                                    null,
                                    '',
                                    'Cartella del ' ||
                                    to_char(ruog.data_cartella, 'dd/mm/yyyy')),
                             'Cartella n° ' || ruog.numero_cartella ||
                             decode(ruog.data_cartella,
                                    null,
                                    '',
                                    ' del ' ||
                                    to_char(ruog.data_cartella, 'dd/mm/yyyy'))) dati_cartella,
                      decode(sgravi.numero_elenco,
                             null,
                             decode(sgravi.data_elenco,
                                    null,
                                    '',
                                    'Elenco del ' ||
                                    to_char(sgravi.data_elenco, 'dd/mm/yyyy')),
                             'Elenco n° ' || sgravi.numero_elenco ||
                             decode(sgravi.data_elenco,
                                    null,
                                    '',
                                    ' del ' ||
                                    to_char(sgravi.data_elenco, 'dd/mm/yyyy'))) dati_elenco,
                      trim(translate(to_char(ruog.importo +
                                             decode(ruoli.importo_lordo,
                                                    'S',
                                                    0,
                                                    F_CATA(cata.anno,
                                                           ruog.tributo,
                                                           ruog.importo,
                                                           'T')),
                                             '9,999,999,999,990.00'),
                                     ',.',
                                     '.,')) sTASSA_RUOLO,
                      trim(decode(decode(ruoli.importo_lordo,
                                    'S',
                                    nvl(sgravi.addizionale_pro, 0),
                                    F_CATA(cata.anno,
                                           ruog.tributo,
                                           sgravi.importo,
                                           'P')),
                             0,
                             '',
                             rpad(' Tributo Provinciale', 24) ||
                             translate(to_char(decode(ruoli.importo_lordo,
                                                      'S',
                                                      nvl(sgravi.addizionale_pro,
                                                          0),
                                                      F_CATA(cata.anno,
                                                             ruog.tributo,
                                                             sgravi.importo,
                                                             'P')),
                                               '9,999,999,999,990.00'),
                                       ',.',
                                       '.,')) ||
                      decode(decode(ruoli.importo_lordo,
                                    'S',
                                    nvl(sgravi.addizionale_eca, 0) +
                                    nvl(sgravi.maggiorazione_eca, 0),
                                    F_CATA(cata.anno,
                                           ruog.tributo,
                                           sgravi.importo,
                                           'A') + F_CATA(cata.anno,
                                                         ruog.tributo,
                                                         sgravi.importo,
                                                         'M')),
                             0,
                             '',
                             rpad(' Add./Magg. ECA', 24) ||
                             translate(to_char(decode(ruoli.importo_lordo,
                                                      'S',
                                                      nvl(sgravi.addizionale_eca,
                                                          0) +
                                                      nvl(sgravi.maggiorazione_eca,
                                                          0),
                                                      F_CATA(cata.anno,
                                                             ruog.tributo,
                                                             sgravi.importo,
                                                             'A') +
                                                      F_CATA(cata.anno,
                                                             ruog.tributo,
                                                             sgravi.importo,
                                                             'M')),
                                               '9,999,999,999,990.00'),
                                       ',.',
                                       '.,')) ||
                      decode(decode(ruoli.importo_lordo,
                                    'S',
                                    nvl(sgravi.iva, 0),
                                    F_CATA(cata.anno,
                                           ruog.tributo,
                                           sgravi.importo,
                                           'I')),
                             0,
                             '',
                             rpad(' I.V.A. ' || translate(to_char(cata.aliquota),
                                                         ',.',
                                                         '.,') || '%',
                                  20) ||
                             translate(to_char(decode(ruoli.importo_lordo,
                                                      'S',
                                                      nvl(sgravi.iva, 0),
                                                      f_cata(cata.anno,
                                                             ruog.tributo,
                                                             sgravi.importo,
                                                             'I')),
                                               '9,999,999,999,990.00'),
                                       ',.',
                                       '.,')) ||
                      decode(decode(ruoli.importo_lordo,
                                    'S',
                                    nvl(sgravi.maggiorazione_tares, 0),
                                    nvl(F_CATA(cata.anno,
                                               ruog.tributo,
                                               sgravi.importo,
                                               'M'),
                                        0)),
                             0,
                             '',
                             rpad(' Componenti Perequative', 24) ||
                             translate(to_char(decode(ruoli.importo_lordo,
                                                      'S',
                                                      nvl(sgravi.maggiorazione_tares,
                                                          0),
                                                      F_CATA(cata.anno,
                                                             ruog.tributo,
                                                             sgravi.importo,
                                                             'M')),
                                               '9,999,999,999,990.00'),
                                       ',.',
                                       '.,'))) sAddizionali,
                      trim(translate(to_char(sgravi.importo -
                                             decode(ruoli.importo_lordo,
                                                    'S',
                                                    nvl(sgravi.addizionale_pro,
                                                        0) + nvl(sgravi.maggiorazione_eca,
                                                                 0) +
                                                    nvl(sgravi.addizionale_eca,
                                                        0) +
                                                    nvl(sgravi.iva, 0) +
                                                    nvl(sgravi.maggiorazione_tares,
                                                        0),
                                                    0),
                                             '9,999,999,999,990.00'),
                                     ',.',
                                     '.,')) STRIB_COM,
                      trim(translate(to_char(sgravi.importo +
                                             decode(ruoli.importo_lordo,
                                                    'S',
                                                    0,
                                                    F_CATA(cata.anno,
                                                           ruog.tributo,
                                                           sgravi.importo,
                                                           'P') +
                                                    F_CATA(cata.anno,
                                                           ruog.tributo,
                                                           sgravi.importo,
                                                           'A') +
                                                    F_CATA(cata.anno,
                                                           ruog.tributo,
                                                           sgravi.importo,
                                                           'M') +
                                                    F_CATA(cata.anno,
                                                           ruog.tributo,
                                                           sgravi.importo,
                                                           'I')),
                                             '9,999,999,999,990.00'),
                                     ',.',
                                     '.,')) ssgravio,
                      trim(translate(to_char(ruog.importo +
                                             decode(ruoli.importo_lordo,
                                                    'S',
                                                    0,
                                                    F_CATA(cata.anno,
                                                           ruog.tributo,
                                                           ruog.importo,
                                                           'T')) -
                                             tot_sgravi.somma,
                                             '9,999,999,999,990.00'),
                                     ',.',
                                     '.,')) sresiduo,
                      trim(translate(to_char(tot_sgravi.somma -
                                             (sgravi.importo +
                                             decode(ruoli.importo_lordo,
                                                     'S',
                                                     0,
                                                     F_CATA(cata.anno,
                                                            ruog.tributo,
                                                            sgravi.importo,
                                                            'P') +
                                                     F_CATA(cata.anno,
                                                            ruog.tributo,
                                                            sgravi.importo,
                                                            'A') +
                                                     F_CATA(cata.anno,
                                                            ruog.tributo,
                                                            sgravi.importo,
                                                            'M') +
                                                     F_CATA(cata.anno,
                                                            ruog.tributo,
                                                            sgravi.importo,
                                                            'I'))),
                                             '9,999,999,999,990.00'),
                                     ',.',
                                     '.,')) imp_gia_sgrav,
                      decode(nvl(sgravi.tipo_sgravio, 'S'),
                             'D',
                             'Discarico',
                             'Sgravio') int_sgravio,
                      motivi_sgravio.descrizione desc_motivo_sgravio
        FROM RUOLI,
             RUOLI_OGGETTO RUOG,
             CARICHI_TARSU CATA,
             MOTIVI_SGRAVIO,
             SGRAVI,
             (select sum(F_ROUND(sgra.importo, 1) +
                         decode(ruoli.importo_lordo,
                                'S',
                                0,
                                F_CATA(cata.anno,
                                       ruog.tributo,
                                       sgra.importo,
                                       'P') + F_CATA(cata.anno,
                                                     ruog.tributo,
                                                     sgra.importo,
                                                     'A') +
                                F_CATA(cata.anno,
                                       ruog.tributo,
                                       sgra.importo,
                                       'M') + F_CATA(cata.anno,
                                                     ruog.tributo,
                                                     sgra.importo,
                                                     'I'))) somma
                from sgravi        sgra,
                     ruoli_oggetto ruog,
                     carichi_tarsu cata,
                     ruoli
               where sgra.sequenza_sgravio <= a_seq_sgravio
                 and ruog.sequenza = a_seq
                 and sgra.cod_fiscale = ruog.cod_fiscale
                 and sgra.sequenza = ruog.sequenza
                 and sgra.ruolo = ruog.ruolo
                 and cata.anno = ruoli.anno_ruolo
                 and ruoli.ruolo = a_ruolo
                 and ruog.ruolo = ruoli.ruolo
                 and ruog.tributo = a_trib
                 and ruog.oggetto = a_ogge
                 and ruog.cod_fiscale = a_cod_fiscale
                 and ruog.ruolo = a_ruolo) tot_sgravi,
             (select distinct ruog.importo + F_CATA(cata.anno,
                                                    ruog.tributo,
                                                    ruog.importo,
                                                    'T') lordo_a_ruolo,
                              sgravi.importo + F_CATA(cata.anno,
                                                      ruog.tributo,
                                                      sgravi.importo,
                                                      'T') imposta_lorda
                from RUOLI,
                     RUOLI_OGGETTO  RUOG,
                     CARICHI_TARSU  CATA,
                     MOTIVI_SGRAVIO,
                     SGRAVI
               where motivi_sgravio.motivo_sgravio = sgravi.motivo_sgravio
                 and cata.anno = ruoli.anno_ruolo
                 and ruog.cod_fiscale = sgravi.cod_fiscale
                 and ruog.ruolo = sgravi.ruolo
                 and ruog.sequenza = sgravi.sequenza
                 and sgravi.sequenza_sgravio = a_seq_sgravio
                 and ruog.sequenza = a_seq
                 and ruog.ruolo = ruoli.ruolo
                 and ruog.oggetto = a_ogge
                 and ruog.cod_fiscale = a_cod_fiscale
                 and ruoli.ruolo = a_ruolo) somma_add
       where motivi_sgravio.motivo_sgravio = sgravi.motivo_sgravio
         and cata.anno = ruoli.anno_ruolo
         and ruog.cod_fiscale = sgravi.cod_fiscale
         and ruog.ruolo = sgravi.ruolo
         and ruog.sequenza = sgravi.sequenza
         and ruog.ruolo = ruoli.ruolo
         and ruog.tributo = a_trib
         and ruog.oggetto = a_ogge
         and ruog.cod_fiscale = a_cod_fiscale
         and sgravi.sequenza_sgravio = a_seq_sgravio
         and ruog.sequenza = a_seq
         and ruoli.ruolo = a_ruolo;
    return rc;
  end;
---------------------------------------------------------------------
  function pratica(a_ruolo         number default -2,
                   a_cod_fiscale   varchar2 default '',
                   a_pratica       number default -1,
                   a_progr_sgravio number default -1) return sys_refcursor is
    rc sys_refcursor;
  begin
    open rc for
      SELECT ruco.ruolo,
             ruco.cod_fiscale,
             ruco.sequenza,
             ruco.tributo,
             stampa_common.f_formatta_numero(ruco.importo, 'I', 'N') importo,
             sgra.sequenza_sgravio,
             stampa_common.f_formatta_numero(sgra.importo, 'I', 'N') importo_sgravio,
             stampa_common.f_formatta_numero(ruco.importo -
                                             NVL(sgra.importo, 0),
                                             'I',
                                             'N') residuo_ruolo,
             stampa_common.f_formatta_numero(SUM(ruco.importo)
                                             OVER(PARTITION BY ruco.ruolo),
                                             'I',
                                             'N') importo_tot,
             stampa_common.f_formatta_numero(SUM(sgra.importo)
                                             OVER(PARTITION BY ruco.ruolo),
                                             'I',
                                             'N') importo_sgravio_tot,
             stampa_common.f_formatta_numero(SUM(ruco.importo -
                                                 NVL(sgra.importo, 0))
                                             OVER(PARTITION BY ruco.ruolo),
                                             'I',
                                             'N') residuo_ruolo_tot
        from ruoli_contribuente ruco, sgravi sgra
       where ruco.ruolo = sgra.ruolo(+)
         and ruco.sequenza = sgra.sequenza(+)
         and ruco.cod_fiscale = sgra.cod_fiscale(+)
         and ruco.ruolo = a_ruolo
         and ruco.cod_fiscale = a_cod_fiscale
         and ruco.pratica = a_pratica
         and sgra.progr_sgravio(+) = a_progr_sgravio;
    return rc;
  end;
---------------------------------------------------------------------
end stampa_sgravi;
/
