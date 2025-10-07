--liquibase formatted sql
--changeset dmarotta:20250617_121548_tido stripComments:false
--validCheckSum: 1:any
--preConditions onFail:MARK_RAN
--precondition-sql-check expectedResult:0 select count(1) from titoli_documento

ALTER TABLE titoli_documento DISABLE ALL TRIGGERS;

insert into titoli_documento (TITOLO_DOCUMENTO, DESCRIZIONE, TIPO_CARICAMENTO, ESTENSIONE_MULTI, ESTENSIONE_MULTI2, NOME_BEAN, NOME_METODO)
values (26, 'Dichiarazioni IMU/TASI Enti Non Commerciali', null, null, null, 'importaService', 'importaDichiarazioniENC_ECPF');

insert into titoli_documento (TITOLO_DOCUMENTO, DESCRIZIONE, TIPO_CARICAMENTO, ESTENSIONE_MULTI, ESTENSIONE_MULTI2, NOME_BEAN, NOME_METODO)
values (27, 'Utenze Elettriche/GAS', null, null, null, 'importUtenze', 'importaUtenze');

insert into titoli_documento (TITOLO_DOCUMENTO, DESCRIZIONE, TIPO_CARICAMENTO, ESTENSIONE_MULTI, ESTENSIONE_MULTI2, NOME_BEAN, NOME_METODO)
values (28, 'LOC - Contratti di Locazione', null, null, null, 'importLocazioni', 'importaLocazioni');

insert into titoli_documento (TITOLO_DOCUMENTO, DESCRIZIONE, TIPO_CARICAMENTO, ESTENSIONE_MULTI, ESTENSIONE_MULTI2, NOME_BEAN, NOME_METODO)
values (29, 'Dati metrici', null, null, null, 'importDatiMetrici', 'importaDatiMetrici');

insert into titoli_documento (TITOLO_DOCUMENTO, DESCRIZIONE, TIPO_CARICAMENTO, ESTENSIONE_MULTI, ESTENSIONE_MULTI2, NOME_BEAN, NOME_METODO)
values (30, 'LOC - Atti di Locazione Manuali', null, null, null, 'importLocazioni', 'importaLocazioni');

insert into titoli_documento (TITOLO_DOCUMENTO, DESCRIZIONE, TIPO_CARICAMENTO, ESTENSIONE_MULTI, ESTENSIONE_MULTI2, NOME_BEAN, NOME_METODO)
values (31, 'LOC - Contratti di Locazione Manuali', null, null, null, 'importLocazioni', 'importaLocazioni');

insert into titoli_documento (TITOLO_DOCUMENTO, DESCRIZIONE, TIPO_CARICAMENTO, ESTENSIONE_MULTI, ESTENSIONE_MULTI2, NOME_BEAN, NOME_METODO)
values (32, 'Date Notifica per Pratiche di Violazioni', null, null, null, 'importNotifiche', 'importaDateNotifiche');

insert into titoli_documento (TITOLO_DOCUMENTO, DESCRIZIONE, TIPO_CARICAMENTO, ESTENSIONE_MULTI, ESTENSIONE_MULTI2, NOME_BEAN, NOME_METODO)
values (33, 'Flusso di Ritorno Interrogazione Anagrafe Tributaria CO1.151', null, null, null, 'importAnagrafeTributaria', 'importaC01151');

insert into titoli_documento (TITOLO_DOCUMENTO, DESCRIZIONE, TIPO_CARICAMENTO, ESTENSIONE_MULTI, ESTENSIONE_MULTI2, NOME_BEAN, NOME_METODO)
values (1, 'Gestione Notai (MUI)', null, null, null, 'importaService', 'gestioneNotai');

insert into titoli_documento (TITOLO_DOCUMENTO, DESCRIZIONE, TIPO_CARICAMENTO, ESTENSIONE_MULTI, ESTENSIONE_MULTI2, NOME_BEAN, NOME_METODO)
values (2, 'Allineamento Deleghe', null, null, null, 'importaService', 'allineamentoDeleghe');

insert into titoli_documento (TITOLO_DOCUMENTO, DESCRIZIONE, TIPO_CARICAMENTO, ESTENSIONE_MULTI, ESTENSIONE_MULTI2, NOME_BEAN, NOME_METODO)
values (3, 'Flusso di Ritorno MAV', null, null, null, 'importaService', 'flussoRitornoMAV');

insert into titoli_documento (TITOLO_DOCUMENTO, DESCRIZIONE, TIPO_CARICAMENTO, ESTENSIONE_MULTI, ESTENSIONE_MULTI2, NOME_BEAN, NOME_METODO)
values (4, 'Flusso di Ritorno RID', null, null, null, 'importaService', 'flussoRitornoRID');

insert into titoli_documento (TITOLO_DOCUMENTO, DESCRIZIONE, TIPO_CARICAMENTO, ESTENSIONE_MULTI, ESTENSIONE_MULTI2, NOME_BEAN, NOME_METODO)
values (5, 'Gestione Successioni', null, null, null, 'importaService', 'caricaDicSuccessioni');

insert into titoli_documento (TITOLO_DOCUMENTO, DESCRIZIONE, TIPO_CARICAMENTO, ESTENSIONE_MULTI, ESTENSIONE_MULTI2, NOME_BEAN, NOME_METODO)
values (6, 'Caricamento Versamenti TARSU (Pioltello)', null, null, null, null, null);

insert into titoli_documento (TITOLO_DOCUMENTO, DESCRIZIONE, TIPO_CARICAMENTO, ESTENSIONE_MULTI, ESTENSIONE_MULTI2, NOME_BEAN, NOME_METODO)
values (7, 'Gestione contratti di locazione telematici - SIATEL', null, null, null, null, null);

insert into titoli_documento (TITOLO_DOCUMENTO, DESCRIZIONE, TIPO_CARICAMENTO, ESTENSIONE_MULTI, ESTENSIONE_MULTI2, NOME_BEAN, NOME_METODO)
values (8, 'Gestione utenze elettriche - SIATEL', null, null, null, null, null);

insert into titoli_documento (TITOLO_DOCUMENTO, DESCRIZIONE, TIPO_CARICAMENTO, ESTENSIONE_MULTI, ESTENSIONE_MULTI2, NOME_BEAN, NOME_METODO)
values (9, 'Gestione Utenze - SIATEL', null, null, null, null, null);

insert into titoli_documento (TITOLO_DOCUMENTO, DESCRIZIONE, TIPO_CARICAMENTO, ESTENSIONE_MULTI, ESTENSIONE_MULTI2, NOME_BEAN, NOME_METODO)
values (10, 'Docfa - Dati Metrici', null, null, null, null, null);

insert into titoli_documento (TITOLO_DOCUMENTO, DESCRIZIONE, TIPO_CARICAMENTO, ESTENSIONE_MULTI, ESTENSIONE_MULTI2, NOME_BEAN, NOME_METODO)
values (11, 'Docfa - Dati Censuari', null, null, null, null, null);

insert into titoli_documento (TITOLO_DOCUMENTO, DESCRIZIONE, TIPO_CARICAMENTO, ESTENSIONE_MULTI, ESTENSIONE_MULTI2, NOME_BEAN, NOME_METODO)
values (12, 'Dati Metrici TARSU txt - SISTER', null, null, null, null, null);

insert into titoli_documento (TITOLO_DOCUMENTO, DESCRIZIONE, TIPO_CARICAMENTO, ESTENSIONE_MULTI, ESTENSIONE_MULTI2, NOME_BEAN, NOME_METODO)
values (13, 'Flusso di Ritorno MAV COSAP', null, null, null, null, null);

insert into titoli_documento (TITOLO_DOCUMENTO, DESCRIZIONE, TIPO_CARICAMENTO, ESTENSIONE_MULTI, ESTENSIONE_MULTI2, NOME_BEAN, NOME_METODO)
values (14, 'Flusso di Ritorno MAV TARSU', null, null, null, 'importaService', 'flussoRitornoMAV_TARSU');

insert into titoli_documento (TITOLO_DOCUMENTO, DESCRIZIONE, TIPO_CARICAMENTO, ESTENSIONE_MULTI, ESTENSIONE_MULTI2, NOME_BEAN, NOME_METODO)
values (15, 'Importa Versamenti COSAP Poste', null, null, null, 'importaService', 'importaVersCosapPoste');

insert into titoli_documento (TITOLO_DOCUMENTO, DESCRIZIONE, TIPO_CARICAMENTO, ESTENSIONE_MULTI, ESTENSIONE_MULTI2, NOME_BEAN, NOME_METODO)
values (16, 'Flusso di Ritorno MAV TARSU (Ruoli Multipli)', null, null, null, 'importaService', 'flussoRitornoMAV_TARSU_rm');

insert into titoli_documento (TITOLO_DOCUMENTO, DESCRIZIONE, TIPO_CARICAMENTO, ESTENSIONE_MULTI, ESTENSIONE_MULTI2, NOME_BEAN, NOME_METODO)
values (17, 'Acquisizione Versamenti MAV INC1 (SLS)', null, null, null, null, null);

insert into titoli_documento (TITOLO_DOCUMENTO, DESCRIZIONE, TIPO_CARICAMENTO, ESTENSIONE_MULTI, ESTENSIONE_MULTI2, NOME_BEAN, NOME_METODO)
values (18, 'Redditi', null, null, null, null, null);

insert into titoli_documento (TITOLO_DOCUMENTO, DESCRIZIONE, TIPO_CARICAMENTO, ESTENSIONE_MULTI, ESTENSIONE_MULTI2, NOME_BEAN, NOME_METODO)
values (19, 'Flusso di Ritorno MAV ICI Violazioni', null, null, null, 'importaService', 'flussoRitornoMAV_ICIviol');

insert into titoli_documento (TITOLO_DOCUMENTO, DESCRIZIONE, TIPO_CARICAMENTO, ESTENSIONE_MULTI, ESTENSIONE_MULTI2, NOME_BEAN, NOME_METODO)
values (20, 'Trasco ICI/IMU', null, null, null, null, null);

insert into titoli_documento (TITOLO_DOCUMENTO, DESCRIZIONE, TIPO_CARICAMENTO, ESTENSIONE_MULTI, ESTENSIONE_MULTI2, NOME_BEAN, NOME_METODO)
values (21, 'Caricamento Versamenti F24 Tributi Locali', null, null, null, 'importaService', 'caricaVersamentiTitrF24');

insert into titoli_documento (TITOLO_DOCUMENTO, DESCRIZIONE, TIPO_CARICAMENTO, ESTENSIONE_MULTI, ESTENSIONE_MULTI2, NOME_BEAN, NOME_METODO)
values (22, 'Acquisizione DOCFA', 'MULTI', 'DAT', 'PDF', 'importaService', 'caricaDocfa');

insert into titoli_documento (TITOLO_DOCUMENTO, DESCRIZIONE, TIPO_CARICAMENTO, ESTENSIONE_MULTI, ESTENSIONE_MULTI2, NOME_BEAN, NOME_METODO)
values (23, 'Caricamento Catasto Censuario', 'MULTI', 'TIT,SOG,FAB,TER,', null, 'importaService', 'importaCatastoCensuario');

insert into titoli_documento (TITOLO_DOCUMENTO, DESCRIZIONE, TIPO_CARICAMENTO, ESTENSIONE_MULTI, ESTENSIONE_MULTI2, NOME_BEAN, NOME_METODO)
values (24, 'Conferimenti (S. Donato Milanese)', null, null, null, null, null);

insert into titoli_documento (TITOLO_DOCUMENTO, DESCRIZIONE, TIPO_CARICAMENTO, ESTENSIONE_MULTI, ESTENSIONE_MULTI2, NOME_BEAN, NOME_METODO)
values (25, 'Conferimenti CER', null, null, null, null, null);

insert into titoli_documento (TITOLO_DOCUMENTO, DESCRIZIONE, TIPO_CARICAMENTO, ESTENSIONE_MULTI, ESTENSIONE_MULTI2, NOME_BEAN, NOME_METODO)
values (39, 'Svuotamenti', null, null, null, 'importSvuotamentiService', 'importa');

insert into titoli_documento (TITOLO_DOCUMENTO, DESCRIZIONE, TIPO_CARICAMENTO, ESTENSIONE_MULTI, ESTENSIONE_MULTI2, NOME_BEAN, NOME_METODO)
values (35, 'LAC per Popolamento Anagrafe', null, null, null, 'importaService', 'importaAnagrafeLAC');

insert into titoli_documento (TITOLO_DOCUMENTO, DESCRIZIONE, TIPO_CARICAMENTO, ESTENSIONE_MULTI, ESTENSIONE_MULTI2, NOME_BEAN, NOME_METODO)
values (36, 'Dichiarazioni IMU/TASI Enti Commerciali e Persone Fisiche', null, null, null, 'importaService', 'importaDichiarazioniENC_ECPF');

ALTER TABLE titoli_documento ENABLE ALL TRIGGERS;
