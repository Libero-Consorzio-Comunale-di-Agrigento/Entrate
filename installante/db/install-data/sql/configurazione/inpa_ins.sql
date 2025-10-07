--liquibase formatted sql
--changeset dmarotta:20250326_152438_inpa_ins stripComments:false
--validCheckSum: 1:any

ALTER TABLE installazione_parametri DISABLE ALL TRIGGERS;

insert into installazione_parametri (PARAMETRO, VALORE, DESCRIZIONE)
values ('GIS_API', null, 'Indirizzo completo del servizio ADS della WebAPI');

insert into installazione_parametri (PARAMETRO, VALORE, DESCRIZIONE)
values ('GIS_CRON', null, 'Cronologia pianificazione Job sincronizzazione GIS');

insert into installazione_parametri (PARAMETRO, VALORE, DESCRIZIONE)
values ('COAT_SOLL', 'N', 'Proporre anche le pratiche sollecitate nel Ruolo Coattivo');

insert into installazione_parametri (PARAMETRO, VALORE, DESCRIZIONE)
values ('COMU_INS', '20/03/2017 06:00', 'Data Ultimo Allineamento Comuni');

insert into installazione_parametri (PARAMETRO, VALORE, DESCRIZIONE)
values ('CTR_NATU', 'E EU', 'Caricamento Notai indicare le nature da non trattare, tra apici e separati da virgola');

insert into installazione_parametri (PARAMETRO, VALORE, DESCRIZIONE)
values ('CTR_PART', 'S', 'Caricamento Notai disabilitare controllo partita per terreni (valori possibili S  N)');

insert into installazione_parametri (PARAMETRO, VALORE, DESCRIZIONE)
values ('DEPA_CE', null, 'Codice ente');

insert into installazione_parametri (PARAMETRO, VALORE, DESCRIZIONE)
values ('DEPA_CUNI', 'CUNI OCC=S', 'Descrizione Servizio CANONE UNICO in DEPAG');

insert into installazione_parametri (PARAMETRO, VALORE, DESCRIZIONE)
values ('DEPA_ICP', 'PUBB OCC=S', 'Descrizione Servizio ICP in DEPAG');

insert into installazione_parametri (PARAMETRO, VALORE, DESCRIZIONE)
values ('DEPA_PASS', null, 'Password utenza tecnica');

insert into installazione_parametri (PARAMETRO, VALORE, DESCRIZIONE)
values ('DEPA_RATE', 'T', 'Rate da passare a PAGOPA: T - Tutte, U - Rata unica, R - Rate calcolate');

insert into installazione_parametri (PARAMETRO, VALORE, DESCRIZIONE)
values ('DEPA_TARSU', 'TARI OCC=N', 'Descrizione Servizio TARSU in DEPAG');

insert into installazione_parametri (PARAMETRO, VALORE, DESCRIZIONE)
values ('DEPA_TOSAP', 'TOSAP OCC=S', 'Descrizione Servizio TOSAP in DEPAG');

insert into installazione_parametri (PARAMETRO, VALORE, DESCRIZIONE)
values ('DEPA_URL', null, 'URL WS DePag');

insert into installazione_parametri (PARAMETRO, VALORE, DESCRIZIONE)
values ('DEPA_USER', 'TR4WS', 'Utenza tecnica');

insert into installazione_parametri (PARAMETRO, VALORE, DESCRIZIONE)
values ('DES_ADPR', 'Add. Provinciale=1992-2007 Tributo TEFA=2008-2099', 'Descrizione Addizionale Provinciale');

insert into installazione_parametri (PARAMETRO, VALORE, DESCRIZIONE)
values ('DES_CUNI', 'Can. Unico=1900-9999', 'Descrizione CUNI');

insert into installazione_parametri (PARAMETRO, VALORE, DESCRIZIONE)
values ('DES_ICI', 'ICI=1900-2011 IMU=2012-2099', 'Descrizione ICI');

insert into installazione_parametri (PARAMETRO, VALORE, DESCRIZIONE)
values ('DES_ICP', 'PUBBL=1900-9999', 'Descrizione ICP');

insert into installazione_parametri (PARAMETRO, VALORE, DESCRIZIONE)
values ('DES_TARSU', 'TARSU=1900-2005 TIA=2006-2012 TARES=2013-2013 TARI=2014-2099', 'Descrizione TARSU');

insert into installazione_parametri (PARAMETRO, VALORE, DESCRIZIONE)
values ('DES_TOSAP', 'TOSAP=1900-2016 COSAP=2017-9999', 'Descrizione TOSAP');

insert into installazione_parametri (PARAMETRO, VALORE, DESCRIZIONE)
values ('DETA_OGGEA', 'S', 'Oggetti automatici in denunce TARSU');

insert into installazione_parametri (PARAMETRO, VALORE, DESCRIZIONE)
values ('DOC_FOLDER', null, 'Folder deposito pdf elaborazioni');

insert into installazione_parametri (PARAMETRO, VALORE, DESCRIZIONE)
values ('EMAIL', null, null);

insert into installazione_parametri (PARAMETRO, VALORE, DESCRIZIONE)
values ('GIS_NUM_OG', '50', 'Numero massimo di oggetti elaborabili in un blocco');

insert into installazione_parametri (PARAMETRO, VALORE, DESCRIZIONE)
values ('FONT_COMP', '20', 'Fonte per versamenti da compensazione');

insert into installazione_parametri (PARAMETRO, VALORE, DESCRIZIONE)
values ('FONT_DEPAG', '21', 'Fonte per Versamenti PagoPA');

insert into installazione_parametri (PARAMETRO, VALORE, DESCRIZIONE)
values ('FONT_DIENC', '22', 'Fonte per denunce enti non commerciali');

insert into installazione_parametri (PARAMETRO, VALORE, DESCRIZIONE)
values ('GIS_SERV', null, 'Indirizzo completo del servizio ADS del WebGIS - Non parametrizzare qui !');

insert into installazione_parametri (PARAMETRO, VALORE, DESCRIZIONE)
values ('FONT_DUPD', '23', 'Fonte per duplica denunce');

insert into installazione_parametri (PARAMETRO, VALORE, DESCRIZIONE)
values ('FONT_REND', '24', 'Fonte per recupero rendite');

insert into installazione_parametri (PARAMETRO, VALORE, DESCRIZIONE)
values ('GIS_WEB', null, 'Indirizzo completo pagina predefinita del WebGIS');

insert into installazione_parametri (PARAMETRO, VALORE, DESCRIZIONE)
values ('GSD_UTST', '', 'GSD: Unita territoriale e Suddivisione Territoriale da trattare');

insert into installazione_parametri (PARAMETRO, VALORE, DESCRIZIONE)
values ('LISTA_ANNI', '5', 'Anni da visualizzare in Situazione Contribuente WEB');

insert into installazione_parametri (PARAMETRO, VALORE, DESCRIZIONE)
values ('MAX_P_ELAB', '1', 'Massimo numero di processi paralleli.');

insert into installazione_parametri (PARAMETRO, VALORE, DESCRIZIONE)
values ('N_AUTO_RAV', 'S', 'NUMERAZIONE AUTOMATICA DEL RAVVEDIMENTO');

insert into installazione_parametri (PARAMETRO, VALORE, DESCRIZIONE)
values ('PAGONLINE', 'N', 'Passaggio dati a Pagonline DEPAG');

insert into installazione_parametri (PARAMETRO, VALORE, DESCRIZIONE)
values ('PAGONL_ORD', 'A', 'Ordinamento record a Pagonline DEPAG  (A,C,I)');

insert into installazione_parametri (PARAMETRO, VALORE, DESCRIZIONE)
values ('GG_ANNO_BI', '366', 'Giorni Anno Bisestile (come Divisore)');

insert into installazione_parametri (PARAMETRO, VALORE, DESCRIZIONE)
values ('PERC_RAVV', '10', 'Percentuale di scostamento accettata per controllo ravvedimento');

insert into installazione_parametri (PARAMETRO, VALORE, DESCRIZIONE)
values ('PERC_RISUP', '80', 'Percentuale riduzione superficie dati metrici');

insert into installazione_parametri (PARAMETRO, VALORE, DESCRIZIONE)
values ('RATE_FIME', 'S', 'Scadenza Rate a FIne MEse');

insert into installazione_parametri (PARAMETRO, VALORE, DESCRIZIONE)
values ('RUOLO_ZERO', 'S', 'Visualizzazione ruoli con importo totale = 0');

insert into installazione_parametri (PARAMETRO, VALORE, DESCRIZIONE)
values ('SI4CS_IO', 'appio', 'Alias AppIO per si4cs');

insert into installazione_parametri (PARAMETRO, VALORE, DESCRIZIONE)
values ('SI4CS_MAIL', 'mail', 'Alias e-mail per si4cs');

insert into installazione_parametri (PARAMETRO, VALORE, DESCRIZIONE)
values ('SI4CS_URL', null, 'WS Si4csWeb');

insert into installazione_parametri (PARAMETRO, VALORE, DESCRIZIONE)
values ('SOSP_FERIE', '01/08-31/08', 'Periodo di sospensione, nel formato gg/mm-gg/mm');

insert into installazione_parametri (PARAMETRO, VALORE, DESCRIZIONE)
values ('TITR_DIENC', 'ICI TASI', 'Tipi tributo da gestire in caricamento dichiarazione ENC, separati da spazio (valori possibili ICI TASI)');

insert into installazione_parametri (PARAMETRO, VALORE, DESCRIZIONE)
values ('TITR_DOCFA', 'ICI TASI', 'Tipi tributo da gestire in caricamento Docfa, separati da spazio (valori possibili ICI TASI)');

insert into installazione_parametri (PARAMETRO, VALORE, DESCRIZIONE)
values ('TITR_NOTAI', 'ICI TASI', 'Tipi tributo da gestire in caricamento Notai, separati da spazio (valori possibili ICI TASI)');

insert into installazione_parametri (PARAMETRO, VALORE, DESCRIZIONE)
values ('TITR_SUCC', 'ICI', 'Tipi tributo da gestire in caricamento Successioni, separati da spazio (valori possibili ICI TASI)');

insert into installazione_parametri (PARAMETRO, VALORE, DESCRIZIONE)
values ('TRW_MAPPE', 'N', 'Visualizzazione Bottoni e Mappe nella TributiWeb');

ALTER TABLE installazione_parametri ENABLE ALL TRIGGERS;
