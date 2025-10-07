--liquibase formatted sql
--changeset dmarotta:20250326_152438_init_dbchangelog_tr4 stripComments:false
--validCheckSum: 1:any
--preConditions onFail:MARK_RAN
--precondition-sql-check expectedResult:1 select count(1) from USER_OBJECTS where OBJECT_TYPE ='TABLE' and  OBJECT_NAME = 'PRATICHE_TRIBUTO'

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_abilitati_web_non_cont', 'abrandolini', 'latest/procedures/abilitati_web_non_cont.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 437, 'EXECUTED', '8:807572435faa260256edd1c394cc8b09', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_abilita_trg', 'abrandolini', 'latest/procedures/abilita_trg.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 436, 'EXECUTED', '8:2b4110ae0d81b152655cbf8c560955f1', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152401_ad4_v_comuni', 'abrandolini', 'latest/views/ad4_v_comuni.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 15, 'EXECUTED', '8:e152d3c8b93b06a5c833ce9e7c771e07', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152401_ad4_v_comuni_tr4', 'abrandolini', 'latest/views/ad4_v_comuni_tr4.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 16, 'EXECUTED', '8:0a2b6929f88bc4fc3004b0eed38dfe6e', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152401_ad4_v_moduli', 'abrandolini', 'latest/views/ad4_v_moduli.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 17, 'EXECUTED', '8:0648897769360f4935011d33dc0a776a', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152401_ad4_v_progetti', 'abrandolini', 'latest/views/ad4_v_progetti.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 18, 'EXECUTED', '8:dfea4ee0f9252165681c2dcfaf1102c1', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152401_ad4_v_province', 'abrandolini', 'latest/views/ad4_v_province.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 19, 'EXECUTED', '8:a347fcf90e1400b6ab54e2bc8c814e2c', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152401_ad4_v_regioni', 'abrandolini', 'latest/views/ad4_v_regioni.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 20, 'EXECUTED', '8:8af5b0c1b205f1800df5cea66fadd79a', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152401_ad4_v_ruoli', 'abrandolini', 'latest/views/ad4_v_ruoli.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 21, 'EXECUTED', '8:232e0977aca1d1eb51eef2b790968562', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152401_ad4_v_stati', 'abrandolini', 'latest/views/ad4_v_stati.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 22, 'EXECUTED', '8:363614a8ee84970e27211087b004d703', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152401_ad4_v_utenti', 'abrandolini', 'latest/views/ad4_v_utenti.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 23, 'EXECUTED', '8:36f290f90ac0084d35879566f09ff2da', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152401_ad4_v_utenti_ruoli', 'abrandolini', 'latest/views/ad4_v_utenti_ruoli.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 24, 'EXECUTED', '8:c938193986dc5310882b754f9c7f9f92', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152429_afc', 'abrandolini', 'latest/packages/afc.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 816, 'EXECUTED', '8:35a1ad2f2283864ed78bb76f7e9510ae', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152429_afc_ddl', 'abrandolini', 'latest/packages/afc_ddl.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 817, 'EXECUTED', '8:65f1cb138355ea6c59bf7f68f986531a', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152429_afc_dml', 'abrandolini', 'latest/packages/afc_dml.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 818, 'EXECUTED', '8:abe7f7df2dbde88980e8a0f5ea6c6a80', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152429_afc_error', 'abrandolini', 'latest/packages/afc_error.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 819, 'EXECUTED', '8:7cb742c6e9a0bff245c0ee9ff057eeea', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_afcKCDef', 'dmarotta', 'install-data/sql/configurazione/afcKCDef.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 864, 'EXECUTED', '8:6f4bde77744fce6c2413031092f8c65c', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152429_afc_lob', 'abrandolini', 'latest/packages/afc_lob.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 821, 'EXECUTED', '8:4b9f22a246008e23cdd3796142a6df66', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_aggana', 'dmarotta', 'latest/procedures/aggana.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 438, 'EXECUTED', '8:3339e0e96a3367ccd325dd4d9a423c34', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_aggi_nr', 'abrandolini', 'latest/procedures/aggi_nr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 439, 'EXECUTED', '8:8e261d936a951f243c2109ca3bbb1879', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_aggiorna_da_mese_possesso', 'abrandolini', 'latest/procedures/aggiorna_da_mese_possesso.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 440, 'EXECUTED', '8:1ce7051244970491b4a26828456e370d', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_aggiornamento_data_notifica', 'abrandolini', 'latest/procedures/aggiornamento_data_notifica.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 445, 'EXECUTED', '8:781b37af374990ce5e60f283ea34f9ba', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_aggiornamento_indirizzi', 'abrandolini', 'latest/procedures/aggiornamento_indirizzi.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 446, 'EXECUTED', '8:c24aa06893966a5c27c49fa7977f617d', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_aggiornamento_ogpr_rif_ap', 'abrandolini', 'latest/procedures/aggiornamento_ogpr_rif_ap.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 447, 'EXECUTED', '8:d79f51b289bcd4dc107f895673b49b40', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_aggiornamento_sanzione', 'abrandolini', 'latest/procedures/aggiornamento_sanzione.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 449, 'EXECUTED', '8:72a01f5277d0cfb7c082b4c12f016e16', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_aggiornamento_sanzione_liq', 'abrandolini', 'latest/procedures/aggiornamento_sanzione_liq.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 450, 'EXECUTED', '8:e77cdbc7a8202c8752217f4be9af5253', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_aggiornamento_sanzione_liq_imu', 'abrandolini', 'latest/procedures/aggiornamento_sanzione_liq_imu.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 451, 'EXECUTED', '8:a05fed80a1b3604ac5cca340abbd49cf', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_aggiornamento_sanz_liq_tasi', 'abrandolini', 'latest/procedures/aggiornamento_sanz_liq_tasi.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 448, 'EXECUTED', '8:ada400e0013c97f5e33d003c7fe52fae', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_aggiorna_parametri_utente', 'abrandolini', 'latest/procedures/aggiorna_parametri_utente.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 441, 'EXECUTED', '8:0ea5553e65edc6178f3ef014b464a371', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_aggiorna_perc_detrazione', 'abrandolini', 'latest/procedures/aggiorna_perc_detrazione.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 442, 'EXECUTED', '8:769a5cdc125978669296a342f9cea03d', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_aggiorna_sanzioni_at', 'abrandolini', 'latest/procedures/aggiorna_sanzioni_at.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 443, 'EXECUTED', '8:7f88a524c7cc5b432cd932da1bef8b97', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_aggiorna_tipo_violazione', 'abrandolini', 'latest/procedures/aggiorna_tipo_violazione.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 444, 'EXECUTED', '8:27e3919b4f9603a3f60bb58719f2fa19', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_alde_andata', 'abrandolini', 'latest/procedures/alde_andata.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 452, 'EXECUTED', '8:3df5b5f91593b203debcb5b70fa1ff40', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_alde_risposta', 'abrandolini', 'latest/procedures/alde_risposta.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 453, 'EXECUTED', '8:2bc252d8c623907e47ad98eeee25a2fa', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_aliquota_alca', 'abrandolini', 'latest/procedures/aliquota_alca.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 454, 'EXECUTED', '8:3fedd554ef764e6f540b57362ac92ca9', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_aliquota_mobile_k', 'abrandolini', 'latest/procedures/aliquota_mobile_k.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 455, 'EXECUTED', '8:cecec6fcd03b74f38513b2a51cbeb2d7', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_aliquote_ogco_di', 'abrandolini', 'latest/procedures/aliquote_ogco_di.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 456, 'EXECUTED', '8:ba96c62a408a323b73fa00413ef8a547', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_ALLEGATI_TESTO_NR', 'abrandolini', 'latest/procedures/ALLEGATI_TESTO_NR.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 429, 'EXECUTED', '8:1e125560e5e008b75fd87e1b46be1444', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_anci_var_nr', 'abrandolini', 'latest/procedures/anci_var_nr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 458, 'EXECUTED', '8:330db814b531bc344219a1ea6ac74de8', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_annulla_elenco_sgravi', 'abrandolini', 'latest/procedures/annulla_elenco_sgravi.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 459, 'EXECUTED', '8:850997e660c3ce6922003c70a7fea863', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_annulla_import', 'abrandolini', 'latest/procedures/annulla_import.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 460, 'EXECUTED', '8:0821ba845879c8764161c33be9263fcd', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_anomalie_caricamento_nr', 'abrandolini', 'latest/procedures/anomalie_caricamento_nr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 461, 'EXECUTED', '8:f66c6c485ad5e7e957a15a75a9cef857', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_anomalie_contitolari_nr', 'abrandolini', 'latest/procedures/anomalie_contitolari_nr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 462, 'EXECUTED', '8:551ee8f8441adc7fb7f1783ff2379a0d', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_anomalie_ici_di', 'abrandolini', 'latest/procedures/anomalie_ici_di.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 463, 'EXECUTED', '8:caaafb7c5acf58be7417a7d053134cde', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_anomalie_ici_nr', 'abrandolini', 'latest/procedures/anomalie_ici_nr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 464, 'EXECUTED', '8:c0bb18a04b5835fe8d339b27ab9ba17c', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_anomalie_nr', 'abrandolini', 'latest/procedures/anomalie_nr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 465, 'EXECUTED', '8:d6774201a9be88b71e17d6bae84de178', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_anomalie_parametri_nr', 'abrandolini', 'latest/procedures/anomalie_parametri_nr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 466, 'EXECUTED', '8:e09f8284c4f19ef46fe60e5f21e0da01', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_anomalie_pratiche_nr', 'abrandolini', 'latest/procedures/anomalie_pratiche_nr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 467, 'EXECUTED', '8:62bfb23fcfff526aae7c1b4fb3d758c4', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_archivia_denunce', 'abrandolini', 'latest/procedures/archivia_denunce.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 468, 'EXECUTED', '8:18a5db115c86200dae84dfbbaf79f2fa', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_archivia_denunce_job', 'abrandolini', 'latest/procedures/archivia_denunce_job.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 469, 'EXECUTED', '8:78f84a2bb1b920a968fdc391f57584ab', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_archivio_vie_fi', 'abrandolini', 'latest/procedures/archivio_vie_fi.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 470, 'EXECUTED', '8:3b6104b8804df173891d5f54fa67a275', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_archivio_vie_nr', 'abrandolini', 'latest/procedures/archivio_vie_nr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 471, 'EXECUTED', '8:753927992184c882c7ec4fb35a54e656', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_archivio_vie_zona_nr', 'abrandolini', 'latest/procedures/archivio_vie_zona_nr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 472, 'EXECUTED', '8:af2d3572da1150a6bd7cd163af991341', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_archivio_vie_zone_nr', 'abrandolini', 'latest/procedures/archivio_vie_zone_nr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 473, 'EXECUTED', '8:531b91a3847d064afec48667f1c5ab38', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_arrotondamenti_tributo_nr', 'abrandolini', 'latest/procedures/arrotondamenti_tributo_nr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 475, 'EXECUTED', '8:0b28e11810d0110c1a726d359141f5f2', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_arrotonda_raim_ruolo', 'abrandolini', 'latest/procedures/arrotonda_raim_ruolo.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 474, 'EXECUTED', '8:f1060a7564107d759b13fa605b943e4a', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_attivita_elaborazione_nr', 'abrandolini', 'latest/procedures/attivita_elaborazione_nr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 476, 'EXECUTED', '8:63e70ed9002c041566c9bbca1c35bea1', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('DEPAG_grant_databasechangelog', 'esasdelli', 'adsinstaller/grant.liquibase.xml', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 944, 'EXECUTED', '8:feecaeedf01b73c214c61b76685ead5a', 'sql', null, null, '3.10.2-fix1106', null, null, '4892510829');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_bonifica_ogco', 'abrandolini', 'latest/procedures/bonifica_ogco.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 477, 'EXECUTED', '8:e6616f34479797cd83d92ea8d25edc41', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_bonifica_ogpr', 'abrandolini', 'latest/procedures/bonifica_ogpr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 478, 'EXECUTED', '8:111a529c9fc3b4afdf9bc3785f5611a0', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_caca_ins', 'dmarotta', 'install-data/sql/configurazione/caca_ins.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 865, 'EXECUTED', '8:287b41e17eca93cfa2386e0492a39321', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_calcolo_acc_automatico', 'abrandolini', 'latest/procedures/calcolo_acc_automatico.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 479, 'EXECUTED', '8:d635ceaab081d50a8dad2fb5f7d28920', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_calcolo_acc_concessioni', 'abrandolini', 'latest/procedures/calcolo_acc_concessioni.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 481, 'EXECUTED', '8:33033a96954f28aaf7139068a595275c', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_calcolo_accertamento_ici', 'abrandolini', 'latest/procedures/calcolo_accertamento_ici.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 484, 'EXECUTED', '8:8872f37b9a2fe4c94e086fd70abfa518', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_calcolo_accertamento_iciap', 'abrandolini', 'latest/procedures/calcolo_accertamento_iciap.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 485, 'EXECUTED', '8:0cb93b4a16f4d56d0e3778d45db88f7a', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_calcolo_accertamento_icp', 'abrandolini', 'latest/procedures/calcolo_accertamento_icp.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 486, 'EXECUTED', '8:4a891810d06c9420643f07ecb2168d98', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_calcolo_accertamento_tarsu', 'abrandolini', 'latest/procedures/calcolo_accertamento_tarsu.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 487, 'EXECUTED', '8:3998c66ed96c47c1e74e1b3e6a81743e', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_calcolo_accertamento_tasi', 'abrandolini', 'latest/procedures/calcolo_accertamento_tasi.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 488, 'EXECUTED', '8:2de9047c38205fc7a34c1824cfabf80c', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_calcolo_accertamento_tosap', 'abrandolini', 'latest/procedures/calcolo_accertamento_tosap.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 489, 'EXECUTED', '8:68f7aac98bc62ec019f9dcb2f696fa40', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_calcolo_acc_sanzioni', 'abrandolini', 'latest/procedures/calcolo_acc_sanzioni.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 482, 'EXECUTED', '8:814942b36aef0dd8c135c42f512fa763', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_calcolo_acc_sanzioni_tarsu', 'abrandolini', 'latest/procedures/calcolo_acc_sanzioni_tarsu.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 483, 'EXECUTED', '8:9783be8e0dc012e633d7ca25c019c55f', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_calcolo_aree', 'abrandolini', 'latest/procedures/calcolo_aree.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 490, 'EXECUTED', '8:59c232e2a71b5d3e80877d71e3aac100', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_calcolo_detrazioni_ici', 'abrandolini', 'latest/procedures/calcolo_detrazioni_ici.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 491, 'EXECUTED', '8:7e0d8ad4f96cfe866c52d60ef7190884', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_calcolo_detrazioni_ici_figli', 'abrandolini', 'latest/procedures/calcolo_detrazioni_ici_figli.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 492, 'EXECUTED', '8:a8052b4a51974f6409c6a1f96578f801', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_calcolo_detrazioni_ici_impo', 'abrandolini', 'latest/procedures/calcolo_detrazioni_ici_impo.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 493, 'EXECUTED', '8:9585633fa083cac7199224fefc3d10e2', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_calcolo_detrazioni_ici_ogge', 'abrandolini', 'latest/procedures/calcolo_detrazioni_ici_ogge.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 494, 'EXECUTED', '8:31bd4cf4666a64cc54c541bbfb851368', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_calcolo_detrazioni_mobili_tasi', 'abrandolini', 'latest/procedures/calcolo_detrazioni_mobili_tasi.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 495, 'EXECUTED', '8:0650c874bf80b027233a09af64f899c0', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_calcolo_detrazioni_tasi', 'abrandolini', 'latest/procedures/calcolo_detrazioni_tasi.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 496, 'EXECUTED', '8:175059b93482e3cd3cb9eb340f786c05', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_calcolo_detrazioni_tasi_figli', 'abrandolini', 'latest/procedures/calcolo_detrazioni_tasi_figli.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 497, 'EXECUTED', '8:6c2fbf20077fd0ecfb3fa876bca72d28', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_calcolo_detrazioni_tasi_ogge', 'abrandolini', 'latest/procedures/calcolo_detrazioni_tasi_ogge.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 498, 'EXECUTED', '8:59af6659142ad3498d8cea2d147101a3', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_calcolo_importo_normalizzato', 'abrandolini', 'latest/procedures/calcolo_importo_normalizzato.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 500, 'EXECUTED', '8:bfdd9843bc8f26d7d73563b44efdf30a', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_calcolo_imposta', 'abrandolini', 'latest/procedures/calcolo_imposta.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 501, 'EXECUTED', '8:3c87417b2cf94cdf6db3487e7ff1f4cd', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_calcolo_imposta_ici_nome', 'abrandolini', 'latest/procedures/calcolo_imposta_ici_nome.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 504, 'EXECUTED', '8:4f16045e02ca7970dcc13f88c3eb9870', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_calcolo_imposta_pratica', 'abrandolini', 'latest/procedures/calcolo_imposta_pratica.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 505, 'EXECUTED', '8:9be7cb2321e7310b3292544a1b659500', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_calcolo_imposta_ravv_tarsu', 'abrandolini', 'latest/procedures/calcolo_imposta_ravv_tarsu.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 506, 'EXECUTED', '8:07c5e1da6922c8192ae5e03313962e06', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_calcolo_imposta_tasi', 'abrandolini', 'latest/procedures/calcolo_imposta_tasi.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 507, 'EXECUTED', '8:983f59aecc9887eca803cb81e16ca3fb', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_calcolo_imposta_tasi_nome', 'abrandolini', 'latest/procedures/calcolo_imposta_tasi_nome.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 508, 'EXECUTED', '8:dbdec4ac2c1d9f8d387860be5a4fef9a', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_calcolo_imu_saldo', 'abrandolini', 'latest/procedures/calcolo_imu_saldo.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 509, 'EXECUTED', '8:1f6cce57c960617ed4338385e32c666b', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_calcolo_individuale', 'abrandolini', 'latest/procedures/calcolo_individuale.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 510, 'EXECUTED', '8:d3f61cbf390699cf33b102f424bca50d', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_calcolo_individuale_imu_e_tasi', 'abrandolini', 'latest/procedures/calcolo_individuale_imu_e_tasi.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 511, 'EXECUTED', '8:5fb7a03f5ced7a8dcbc39c94f7c0b0ae', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_calcolo_interessi', 'abrandolini', 'latest/procedures/calcolo_interessi.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 512, 'EXECUTED', '8:9adf0e337d283f0a3c0b31c39a5f9ec8', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_calcolo_interessi_ruolo_s', 'abrandolini', 'latest/procedures/calcolo_interessi_ruolo_s.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 513, 'EXECUTED', '8:deff818093f002ea699f588f0c89532e', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_calcolo_liquidazioni_ici', 'abrandolini', 'latest/procedures/calcolo_liquidazioni_ici.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 514, 'EXECUTED', '8:5133cb7b17d6aa0789b086e74dc553de', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_calcolo_liquidazioni_ici_nome', 'abrandolini', 'latest/procedures/calcolo_liquidazioni_ici_nome.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 515, 'EXECUTED', '8:72b22c760debc8cef4a01f9cf2697d3e', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_calcolo_liquidazioni_tasi', 'abrandolini', 'latest/procedures/calcolo_liquidazioni_tasi.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 517, 'EXECUTED', '8:6e127f5a43a3350306a6c1c32c80d5ca', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_calcolo_mesi_affitto', 'abrandolini', 'latest/procedures/calcolo_mesi_affitto.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 518, 'EXECUTED', '8:b94e72d6caa33c8cb122498e023ef3eb', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_calcolo_mesi_esclusione', 'abrandolini', 'latest/procedures/calcolo_mesi_esclusione.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 519, 'EXECUTED', '8:c42a8dccc7b494a1f08f506ab35b8334', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_calcolo_mesi_possesso_ici', 'abrandolini', 'latest/procedures/calcolo_mesi_possesso_ici.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 520, 'EXECUTED', '8:e623b013fd302c054282b981efcf909e', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_calcolo_rateazione', 'abrandolini', 'latest/procedures/calcolo_rateazione.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 521, 'EXECUTED', '8:2c300eeb319441a6461198f2a26459da', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_calcolo_rateazione_aggi', 'abrandolini', 'latest/procedures/calcolo_rateazione_aggi.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 522, 'EXECUTED', '8:be2e10db440b827ceead348b5b197bcd', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_calcolo_riog_multiplo', 'abrandolini', 'latest/procedures/calcolo_riog_multiplo.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 523, 'EXECUTED', '8:d5efd0461b4365e295e663d04432b0db', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_calcolo_sanzioni_ici', 'abrandolini', 'latest/procedures/calcolo_sanzioni_ici.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 524, 'EXECUTED', '8:7b824bf13c095347d522c8afb37e4901', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_calcolo_sanzioni_iciap', 'abrandolini', 'latest/procedures/calcolo_sanzioni_iciap.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 525, 'EXECUTED', '8:0c68f5dbf2b8bc4b20b981e1addb8f16', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_calcolo_sanzioni_icp', 'abrandolini', 'latest/procedures/calcolo_sanzioni_icp.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 526, 'EXECUTED', '8:b877c3482ff32ae0e7297a304f67c5c0', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_calcolo_sanzioni_ingiunzione', 'abrandolini', 'latest/procedures/calcolo_sanzioni_ingiunzione.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 527, 'EXECUTED', '8:255360eae1e7a6d2f6b0f24d58f8ab94', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_calcolo_sanzioni_raop_cuni', 'abrandolini', 'latest/procedures/calcolo_sanzioni_raop_cuni.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 528, 'EXECUTED', '8:c7c8eb76cfbd4d44cb533fc364e87c1c', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_calcolo_sanzioni_raop_ici', 'abrandolini', 'latest/procedures/calcolo_sanzioni_raop_ici.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 529, 'EXECUTED', '8:bdc673cab48ef98c2a8880de9802bf68', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_calcolo_sanzioni_raop_tasi', 'abrandolini', 'latest/procedures/calcolo_sanzioni_raop_tasi.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 531, 'EXECUTED', '8:1c0ad61a32cc432283d5c3a10759361c', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_calcolo_sanzioni_tarsu', 'abrandolini', 'latest/procedures/calcolo_sanzioni_tarsu.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 532, 'EXECUTED', '8:3f2967c99da62f735015a609ec501f3e', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_calcolo_sanzioni_tasi', 'abrandolini', 'latest/procedures/calcolo_sanzioni_tasi.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 533, 'EXECUTED', '8:554d460829521fb82aaa133222e4b591', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_calcolo_sanzioni_tosap', 'abrandolini', 'latest/procedures/calcolo_sanzioni_tosap.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 534, 'EXECUTED', '8:db1514947127f5b8a55851e6092cca29', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_calcolo_solleciti', 'abrandolini', 'latest/procedures/calcolo_solleciti.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 537, 'EXECUTED', '8:5c448f05c05f89ed49f2e98964bfb08d', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_calcolo_solleciti_tarsu', 'abrandolini', 'latest/procedures/calcolo_solleciti_tarsu.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 538, 'EXECUTED', '8:7f42be1f799e7205cc30dca75dedd3b1', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_calcolo_sol_sanzioni', 'abrandolini', 'latest/procedures/calcolo_sol_sanzioni.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 536, 'EXECUTED', '8:1b93ddf572275e204c7635b2e63e45a0', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_calcolo_terreni', 'abrandolini', 'latest/procedures/calcolo_terreni.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 539, 'EXECUTED', '8:ce8afdd5891a9dd98d0501ba6fd617a5', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_calcolo_terreni_ridotti', 'abrandolini', 'latest/procedures/calcolo_terreni_ridotti.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 540, 'EXECUTED', '8:ff2b9f32a30e2bed3c81f8c5e9dbac53', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_carica_anagrafe_esterna', 'abrandolini', 'latest/procedures/carica_anagrafe_esterna.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 541, 'EXECUTED', '8:40c48f4b76af9c1f898837e61c6b88a2', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_carica_catasto_censuario', 'abrandolini', 'latest/procedures/carica_catasto_censuario.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 543, 'EXECUTED', '8:a149b42731be30884de06c0e291d182c', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152429_carica_catasto_censuario_pkg', 'abrandolini', 'latest/packages/carica_catasto_censuario_pkg.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 822, 'EXECUTED', '8:272d6472daa0ea55fdd0431c603a2c2e', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_carica_conferimenti', 'abrandolini', 'latest/procedures/carica_conferimenti.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 544, 'EXECUTED', '8:dd1fe01d0208bc0696863d8473650ed5', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_carica_dic_anci', 'abrandolini', 'latest/procedures/carica_dic_anci.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 545, 'EXECUTED', '8:ea54e7b9dddd219cd95f0ec7285decdf', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152429_carica_dic_anci_pk', 'abrandolini', 'latest/packages/carica_dic_anci_pk.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 823, 'EXECUTED', '8:0add6dc4094c48c56b1e0b95c7183c30', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152429_carica_dic_enc', 'abrandolini', 'latest/packages/carica_dic_enc.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 824, 'EXECUTED', '8:ffe2cc282e4e1f7e3e1af7386fa764a5', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152429_carica_dic_enc_ecpf', 'abrandolini', 'latest/packages/carica_dic_enc_ecpf.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 825, 'EXECUTED', '8:2099c1628b3a9ae6f9e07a0100fcaa22', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_carica_dic_notai', 'abrandolini', 'latest/procedures/carica_dic_notai.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 546, 'EXECUTED', '8:c0a2a9307aa276f7087e5aa66c045164', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_carica_dic_sigai', 'abrandolini', 'latest/procedures/carica_dic_sigai.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 548, 'EXECUTED', '8:8dd766df1c0cb129f8e7fd5f16ac8edd', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_carica_dic_successioni', 'abrandolini', 'latest/procedures/carica_dic_successioni.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 549, 'EXECUTED', '8:c768ea7f672e7f1b6128efc421159993', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_carica_docfa', 'abrandolini', 'latest/procedures/carica_docfa.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 550, 'EXECUTED', '8:6f690a1b83d236d5bb1445db76985243', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_carica_oggetti_cessati', 'abrandolini', 'latest/procedures/carica_oggetti_cessati.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 551, 'EXECUTED', '8:54184a319140ad23224bdf261ac2898e', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_carica_pratica_at', 'abrandolini', 'latest/procedures/carica_pratica_at.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 552, 'EXECUTED', '8:fb7699a3473251b34c611309540c66cd', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_carica_pratica_k', 'abrandolini', 'latest/procedures/carica_pratica_k.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 553, 'EXECUTED', '8:1d3166d2fc1df009d9248f9a1fd31099', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_carica_sogei', 'abrandolini', 'latest/procedures/carica_sogei.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 554, 'EXECUTED', '8:e2bca2166fe50398ef431f7f2d3c432e', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_carica_soggetti_docfa', 'abrandolini', 'latest/procedures/carica_soggetti_docfa.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 555, 'EXECUTED', '8:fb15bdb399b2da195a3215b66620dc3b', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_carica_versamenti_cosap_poste', 'abrandolini', 'latest/procedures/carica_versamenti_cosap_poste.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 565, 'EXECUTED', '8:ff7479efdeba347efab16c44aedb48b8', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_carica_versamenti_ici', 'abrandolini', 'latest/procedures/carica_versamenti_ici.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 566, 'EXECUTED', '8:a9d2b0deffca99ec8abf5331b6ae2610', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_carica_versamenti_tarsu_poste', 'abrandolini', 'latest/procedures/carica_versamenti_tarsu_poste.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 569, 'EXECUTED', '8:e7fe6e8779787908912201adfde4b711', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_carica_versamenti_tasi_f24', 'abrandolini', 'latest/procedures/carica_versamenti_tasi_f24.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 570, 'EXECUTED', '8:92334721440e77e6eea1a1496ab31b4d', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_carica_ver_sigai', 'abrandolini', 'latest/procedures/carica_ver_sigai.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 556, 'EXECUTED', '8:17432e83011d992d750a7cd78a9cbf83', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_carica_vers_ravv_ici_f24', 'abrandolini', 'latest/procedures/carica_vers_ravv_ici_f24.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 557, 'EXECUTED', '8:fac7d2a7f2f9d3569b3229bdc10c11d2', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_carica_vers_ravv_tasi_f24', 'abrandolini', 'latest/procedures/carica_vers_ravv_tasi_f24.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 559, 'EXECUTED', '8:cf5afef18d4695cb64f09f7142ae4045', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_carica_violazioni_ici', 'abrandolini', 'latest/procedures/carica_violazioni_ici.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 573, 'EXECUTED', '8:85e60268932f9b3429497bb10dcbc3e3', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_cata_ins', 'dmarotta', 'install-data/sql/configurazione/cata_ins.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 866, 'EXECUTED', '8:6226ffa6735d9d105e787325ce4aa04d', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_Catasto_kc_o', 'dmarotta', 'install/tables/kc_o.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 11, 'EXECUTED', '8:e41c7c4baf6a773ce0ac8369e7885a6c', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_Catasto_orig_o', 'dmarotta', 'install/tables/Catasto_orig_o.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 8, 'EXECUTED', '8:979476e80a8a18af517a9e48421959b1', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_cc_diritti_ins', 'dmarotta', 'install-data/sql/configurazione/cc_diritti_ins.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 867, 'EXECUTED', '8:f6be59f06c2d89395d8ba07f6afc288c', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_cc_qualita_ins', 'dmarotta', 'install-data/sql/configurazione/cc_qualita_ins.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 868, 'EXECUTED', '8:0ad1ad4c0a9e53f7e2c97ac5fab4dae7', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_cc_tipi_nota_ins', 'dmarotta', 'install-data/sql/configurazione/cc_tipi_nota_ins.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 869, 'EXECUTED', '8:1f3cdffcc2c1b5568923978aa9b58048', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152429_cer_conferimenti', 'abrandolini', 'latest/packages/cer_conferimenti.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 826, 'EXECUTED', '8:ed31fa2ca65502543f58bb8ec4f8c73e', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_cessazione_imu_terreni', 'abrandolini', 'latest/procedures/cessazione_imu_terreni.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 574, 'EXECUTED', '8:dd3b3e5e758e24c64e6f4c416ee29a16', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_civici_edificio_nr', 'abrandolini', 'latest/procedures/civici_edificio_nr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 575, 'EXECUTED', '8:4255e2269d3a3550e65dab7797a3121b', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_civici_oggetto_fi', 'abrandolini', 'latest/procedures/civici_oggetto_fi.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 576, 'EXECUTED', '8:f3efe9eaac3a9aea2fdfc03a5eca96cd', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_civici_oggetto_nr', 'abrandolini', 'latest/procedures/civici_oggetto_nr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 577, 'EXECUTED', '8:afa1da698f8f959e94ffbef2e4cc096f', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_coco_ins', 'dmarotta', 'install-data/sql/configurazione/coco_ins.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 870, 'EXECUTED', '8:c92b0068bee654e98a8442526be715cc', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_codi_ins', 'dmarotta', 'install-data/sql/configurazione/codi_ins.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 871, 'EXECUTED', '8:4fe1468cd98cc84a4473f2e9ae63031c', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_coefficienti_domestici_di', 'abrandolini', 'latest/procedures/coefficienti_domestici_di.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 578, 'EXECUTED', '8:aec5e1e3f4998e227799ff2836e2d8cd', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_cof2_ins', 'dmarotta', 'install-data/sql/configurazione/cof2_ins.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 872, 'EXECUTED', '8:75a2afbec6d4e2bd4ef0ec05df873031', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_coif_ins', 'dmarotta', 'install-data/sql/configurazione/coif_ins.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 873, 'EXECUTED', '8:0d736d491cca66381ac4af157b4d1fa1', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_compensazioni_nr', 'abrandolini', 'latest/procedures/compensazioni_nr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 579, 'EXECUTED', '8:f6cd40624243708597e46027649bd6a9', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_compile_gsd', 'abrandolini', 'latest/procedures/compile_gsd.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 580, 'EXECUTED', '8:11ca0df9bf275f36098f673964e07343', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_comunicazione_testi_nr', 'abrandolini', 'latest/procedures/comunicazione_testi_nr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 581, 'EXECUTED', '8:ebfdcd8aa65a012f79d6a46f7f824f04', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_conferimenti_cer_ruolo_fi', 'abrandolini', 'latest/procedures/conferimenti_cer_ruolo_fi.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 582, 'EXECUTED', '8:879802498d7e8f8efef3db017ac559b4', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_conferimenti_cer_ruolo_nr', 'abrandolini', 'latest/procedures/conferimenti_cer_ruolo_nr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 583, 'EXECUTED', '8:588ca7107b04e890f96a5b31c1cd96ae', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_conferimenti_fi', 'abrandolini', 'latest/procedures/conferimenti_fi.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 584, 'EXECUTED', '8:03f572967f35750a384d8af3c11dd4d8', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_contatti_contribuente_nr', 'abrandolini', 'latest/procedures/contatti_contribuente_nr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 585, 'EXECUTED', '8:d3bd33c7033a79678c69d9a0b65d95a2', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_contribuenti_cc_soggetti_nr', 'abrandolini', 'latest/procedures/contribuenti_cc_soggetti_nr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 586, 'EXECUTED', '8:79d89347a6dbf479bbb3559174c802f0', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_contribuenti_chk_del', 'abrandolini', 'latest/procedures/contribuenti_chk_del.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 587, 'EXECUTED', '8:52bc54b3c3048b29254cdf3c53f6e920', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_contribuenti_cu', 'abrandolini', 'latest/procedures/contribuenti_cu.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 588, 'EXECUTED', '8:16d3ee2a834a5dbf427f8a7556efb561', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_contribuenti_di', 'abrandolini', 'latest/procedures/contribuenti_di.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 589, 'EXECUTED', '8:1a85e0f70cd3b2981d9282292833b645', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152401_contribuenti_ente', 'abrandolini', 'latest/views/contribuenti_ente.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 25, 'EXECUTED', '8:d3c0e6084a1a8b402899f5cd2fb48f42', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152401_contribuenti_oggetto_anno', 'abrandolini', 'latest/views/contribuenti_oggetto_anno.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 26, 'EXECUTED', '8:faa1d39f6c28e99ed54675b62bf3ff0b', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152401_contribuenti_soggetti_cc', 'abrandolini', 'latest/views/contribuenti_soggetti_cc.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 27, 'EXECUTED', '8:5808c0798b8bbb5f7e215a58b7eb9f54', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_controllo_anomalie_ici', 'abrandolini', 'latest/procedures/controllo_anomalie_ici.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 590, 'EXECUTED', '8:3162044cff71799b43c7e74d5a0d1300', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_controllo_defi_cont', 'abrandolini', 'latest/procedures/controllo_defi_cont.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 592, 'EXECUTED', '8:436cef4ea4c84bf7e1fc1c3fa8121daa', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_convalida_docfa', 'abrandolini', 'latest/procedures/convalida_docfa.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 593, 'EXECUTED', '8:2ececef3dd016fbce51d0d3232f06911', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_copa_ins', 'dmarotta', 'install-data/sql/configurazione/copa_ins.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 874, 'EXECUTED', '8:e36eef180b87fdcfd9bea1ccafce1956', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_cotr_ins', 'dmarotta', 'install-data/sql/configurazione/cotr_ins.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 875, 'EXECUTED', '8:c50bc99427ccabc147b6a57d11431baa', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_crea_compensazioni', 'abrandolini', 'latest/procedures/crea_compensazioni.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 594, 'EXECUTED', '8:18157453f00838cf4ff5431dd65eaeec', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_crea_ravvedimento', 'abrandolini', 'latest/procedures/crea_ravvedimento.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 595, 'EXECUTED', '8:c63fbf52b819a7afdc11dc7a261c2a92', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_crea_ravvedimento_da_vers', 'abrandolini', 'latest/procedures/crea_ravvedimento_da_vers.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 596, 'EXECUTED', '8:982f32620fc5d79e58f3600c7a565f07', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_crea_sgravio_acconto', 'abrandolini', 'latest/procedures/crea_sgravio_acconto.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 600, 'EXECUTED', '8:1a62f8c32da9f06533215df9abcfb33c', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_crea_sgravio_saldo', 'abrandolini', 'latest/procedures/crea_sgravio_saldo.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 601, 'EXECUTED', '8:1c2cb853e01c58b641a8ba75fe2be3d1', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_crea_sgravi_per_cf_supp', 'abrandolini', 'latest/procedures/crea_sgravi_per_cf_supp.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 599, 'EXECUTED', '8:e77ad2efbd361a1a42571407b8743ffb', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_crea_versamenti_comp', 'abrandolini', 'latest/procedures/crea_versamenti_comp.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 602, 'EXECUTED', '8:6a77267dd1f7a74a0712e0e8b54bce98', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_crediti_ravvedimento_nr', 'abrandolini', 'latest/procedures/crediti_ravvedimento_nr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 603, 'EXECUTED', '8:59547bf8d17147d17ee923b91ed151fb', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_dati_contabili_di', 'abrandolini', 'latest/procedures/dati_contabili_di.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 604, 'EXECUTED', '8:5b35c86a568358ed766f9a7293eb0507', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_dati_contabili_nr', 'abrandolini', 'latest/procedures/dati_contabili_nr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 605, 'EXECUTED', '8:ae0253eb2cffe266525f535559246564', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152429_dbc', 'abrandolini', 'latest/packages/dbc.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 828, 'EXECUTED', '8:fc893e9cc0e77fe81a0afc4fe02ade10', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_DB_v4', 'dmarotta', 'install-data/sql/configurazione/datigenerali/DB_V4.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 876, 'EXECUTED', '8:7fcc214f745f1c51480b2cc9dda348bc', 'sql', null, null, '3.10.2-fix1106', 'TRV4', null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_denominazioni_via_fi', 'abrandolini', 'latest/procedures/denominazioni_via_fi.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 606, 'EXECUTED', '8:6c17e4f61545aa48ada3331d55b748c4', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_denunce_iciap_di', 'abrandolini', 'latest/procedures/denunce_iciap_di.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 607, 'EXECUTED', '8:75700fc90bd5c227d2957d0f1b385ccc', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152401_denunce_icp', 'abrandolini', 'latest/views/denunce_icp.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 28, 'EXECUTED', '8:556f972885ede5dc66d0e69c031931b5', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152401_denunce_tarsu', 'abrandolini', 'latest/views/denunce_tarsu.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 29, 'EXECUTED', '8:21fb1a594338b7d2a82fae08f6932826', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152401_denunce_tosap', 'abrandolini', 'latest/views/denunce_tosap.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 30, 'EXECUTED', '8:1cf9663a65fe5d602c43f789c28a4fdf', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_denunce_v_automatiche', 'abrandolini', 'latest/procedures/denunce_v_automatiche.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 608, 'EXECUTED', '8:2aca5dc1e1448a96775d59f0ecb6ea33', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_determina_importi_base', 'abrandolini', 'latest/procedures/determina_importi_base.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 609, 'EXECUTED', '8:d6adc7ceba0ef428a314a54fddd0d8d2', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_determina_importi_da_scalare', 'abrandolini', 'latest/procedures/determina_importi_da_scalare.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 610, 'EXECUTED', '8:9325f74fd202f3b750113465681ff1f2', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_determina_importi_ici', 'abrandolini', 'latest/procedures/determina_importi_ici.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 611, 'EXECUTED', '8:2776b5f420ee2d7bb4cdcafa26602c81', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_determina_mesi_possesso_ici', 'abrandolini', 'latest/procedures/determina_mesi_possesso_ici.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 613, 'EXECUTED', '8:cbc136697f7ded047d07435adc4044dd', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_determina_sconto_conf', 'abrandolini', 'latest/procedures/determina_sconto_conf.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 614, 'EXECUTED', '8:1ba7b42b9568adbc6efc81a8437ebd3f', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_detrazioni_automatiche', 'abrandolini', 'latest/procedures/detrazioni_automatiche.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 615, 'EXECUTED', '8:508c36addb22032108d7f11a98e21bb2', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_dettagli_comunicazione_nr', 'abrandolini', 'latest/procedures/dettagli_comunicazione_nr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 616, 'EXECUTED', '8:7f814b0761a7d6f7848ced74fa2f38e8', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_dettagli_elaborazione_nr', 'abrandolini', 'latest/procedures/dettagli_elaborazione_nr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 617, 'EXECUTED', '8:2a066c0a57f0aca7ffb174ac8fc92f88', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152401_dettagli_imu', 'abrandolini', 'latest/views/dettagli_imu.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 31, 'EXECUTED', '8:129c41e2011740a94b681797d0e471bf', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152401_dettagli_tasi', 'abrandolini', 'latest/views/dettagli_tasi.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 32, 'EXECUTED', '8:3adb2c38b6bde1a549abf0711c1141cb', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_disabilita_trg', 'abrandolini', 'latest/procedures/disabilita_trg.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 618, 'EXECUTED', '8:5bee7e89a4d92376b9763ac11ccda36b', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_documenti_caricati_multi_fi', 'abrandolini', 'latest/procedures/documenti_caricati_multi_fi.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 619, 'EXECUTED', '8:3bfd2f0e9c0f8df3c6d2bd32a306bbe3', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_documenti_caricati_multi_nr', 'abrandolini', 'latest/procedures/documenti_caricati_multi_nr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 620, 'EXECUTED', '8:e50d16dc77a7a4d8fd7f8bd0a7cf5a1a', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_documenti_caricati_nr', 'abrandolini', 'latest/procedures/documenti_caricati_nr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 621, 'EXECUTED', '8:5684851d4ccb4b9b4bd296a8721e6623', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_documenti_contribuente_nr', 'abrandolini', 'latest/procedures/documenti_contribuente_nr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 622, 'EXECUTED', '8:dc37f2e57f7fed8a3d682f80359651cc', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_duplica_deog_alog', 'abrandolini', 'latest/procedures/duplica_deog_alog.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 623, 'EXECUTED', '8:a4ee06f5de57d6531f20530b5ee4813b', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_duplica_detrazioni', 'abrandolini', 'latest/procedures/duplica_detrazioni.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 624, 'EXECUTED', '8:b870e1baf84ed0078539456f72795c6d', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_duplica_detrazioni_oggetto', 'abrandolini', 'latest/procedures/duplica_detrazioni_oggetto.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 625, 'EXECUTED', '8:f7789d1e838ca714fe4f2d837507bf7d', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_duplica_faso_cont', 'abrandolini', 'latest/procedures/duplica_faso_cont.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 626, 'EXECUTED', '8:ec30546bb20a2dd2102fc8090a330a9b', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_elaborazioni_massive_nr', 'abrandolini', 'latest/procedures/elaborazioni_massive_nr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 627, 'EXECUTED', '8:eaed165b8f39c26f69fff77ec23b6d76', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_elimina_sanz_liq_deceduti', 'abrandolini', 'latest/procedures/elimina_sanz_liq_deceduti.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 628, 'EXECUTED', '8:6ffc215e23a0067f3be1603dfafcfb6a', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_eliminazione_sgravi_ruolo', 'abrandolini', 'latest/procedures/eliminazione_sgravi_ruolo.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 630, 'EXECUTED', '8:d283c1c7015913a1bdf2bf14cc20ecd5', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_eliminazione_tariffe', 'abrandolini', 'latest/procedures/eliminazione_tariffe.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 631, 'EXECUTED', '8:ba8935f9f8903df7c48ec8424b150244', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_emissione_fattura', 'abrandolini', 'latest/procedures/emissione_fattura.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 632, 'EXECUTED', '8:9f4e62748616a2064cecf81e607c45e2', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152429_esporta_standard', 'abrandolini', 'latest/packages/esporta_standard.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 830, 'EXECUTED', '8:a7714cd8a6e95e602b4de15a8490527d', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_estrai_f24_comp_tasi', 'abrandolini', 'latest/procedures/estrai_f24_comp_tasi.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 635, 'EXECUTED', '8:af2542f6b56fcc5ccf79a969c8927879', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_estrai_numerico', 'abrandolini', 'latest/functions/estrai_numerico.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 103, 'EXECUTED', '8:d38a79521c01a0a0a0465302868e66a7', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_estrazione_acc_tarsu_auto', 'abrandolini', 'latest/procedures/estrazione_acc_tarsu_auto.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 636, 'EXECUTED', '8:09b67e853bdc4e9c7dd545fd4e9863bd', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_estrazione_cosap_f24', 'abrandolini', 'latest/procedures/estrazione_cosap_f24.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 637, 'EXECUTED', '8:9d7c8b0219aad53063864c6e8ddbb17e', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_estrazione_cosap_poste', 'abrandolini', 'latest/procedures/estrazione_cosap_poste.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 638, 'EXECUTED', '8:810eb96ca44ea23a2e1250647a2a05c9', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_estrazione_dati_vista', 'abrandolini', 'latest/procedures/estrazione_dati_vista.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 639, 'EXECUTED', '8:c55bf13807dab65ad9737b2e4768b837', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_estrazione_dv_tarsu_f24', 'abrandolini', 'latest/procedures/estrazione_dv_tarsu_f24.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 640, 'EXECUTED', '8:fe68c916b8a3748a1a90c35069d24b6b', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_estrazione_ici_vers', 'abrandolini', 'latest/procedures/estrazione_ici_vers.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 641, 'EXECUTED', '8:2018d4a4527d1adff7e98e6b28d007bb', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_estrazione_ici_vers_cassa', 'abrandolini', 'latest/procedures/estrazione_ici_vers_cassa.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 642, 'EXECUTED', '8:10ff2534a665751b0b7d881af75c419f', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_estrazione_icp_f24', 'abrandolini', 'latest/procedures/estrazione_icp_f24.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 643, 'EXECUTED', '8:c5a5c7b687df3e6041eb51f9c87f2f43', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_estrazione_liquidazioni_imu', 'abrandolini', 'latest/procedures/estrazione_liquidazioni_imu.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 644, 'EXECUTED', '8:d6e07ab856a680c1079d578584c77fb0', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_estrazione_ruolo_tarsu_hera', 'abrandolini', 'latest/procedures/estrazione_ruolo_tarsu_hera.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 646, 'EXECUTED', '8:8e83b3d8d535803e60db3a188bacb4ad', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_estrazione_tares_poste', 'abrandolini', 'latest/procedures/estrazione_tares_poste.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 647, 'EXECUTED', '8:fd43f3711be0a26f7707bcf6da9b0853', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_estrazione_tari_garbage', 'abrandolini', 'latest/procedures/estrazione_tari_garbage.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 648, 'EXECUTED', '8:25f462e4334555685a420db0ee3d0ba8', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_estrazione_tarsu_agenzia', 'abrandolini', 'latest/procedures/estrazione_tarsu_agenzia.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 649, 'EXECUTED', '8:68875325ada373ff834da0ab1dbd479c', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_estrazione_tarsu_agenzia_ogva', 'abrandolini', 'latest/procedures/estrazione_tarsu_agenzia_ogva.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 650, 'EXECUTED', '8:b71d3d98bc7f0166833154cc66825eb6', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_estrazione_tarsu_asa', 'abrandolini', 'latest/procedures/estrazione_tarsu_asa.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 651, 'EXECUTED', '8:ce61862c4cdac6ad7ce74cdeb3e2d9db', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_estrazione_tarsu_poste', 'abrandolini', 'latest/procedures/estrazione_tarsu_poste.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 652, 'EXECUTED', '8:4e98157251d2bda27bb97bc48c02a283', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_estrazione_tarsu_poste_2011', 'abrandolini', 'latest/procedures/estrazione_tarsu_poste_2011.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 653, 'EXECUTED', '8:9ef368352a9d2889dfb45bab57ea2b58', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_estrazione_variazioni_nf', 'abrandolini', 'latest/procedures/estrazione_variazioni_nf.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 654, 'EXECUTED', '8:56c6954a35e6fed9723ab82fbabd27f9', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_eventi_nr', 'abrandolini', 'latest/procedures/eventi_nr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 655, 'EXECUTED', '8:937a20ecf291adfee6ed7b69dd4daaa0', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_expe_ins', 'dmarotta', 'install-data/sql/configurazione/expe_ins.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 877, 'EXECUTED', '8:6e9300e8cad83994ff74915446bac9e1', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_export_dati', 'abrandolini', 'latest/procedures/export_dati.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 656, 'EXECUTED', '8:c3ba7869d3123bdee2eb6da2448eac20', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152429_expstd', 'abrandolini', 'latest/packages/expstd.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 831, 'EXECUTED', '8:dbc0d824e132306cabf66d589c5f97e2', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_abilita_funzione', 'abrandolini', 'latest/functions/f_abilita_funzione.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 104, 'EXECUTED', '8:5b13365acfdbe5f1274879b206e104a7', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_acc_liq_oggetto', 'abrandolini', 'latest/functions/f_acc_liq_oggetto.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 105, 'EXECUTED', '8:4e1560a8090ada369c7e4c184b9b1fbd', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_adatta_data', 'abrandolini', 'latest/functions/f_adatta_data.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 106, 'EXECUTED', '8:6598d306582bf91931baeeb5251f28b4', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_add_eca_pert_ruolo', 'abrandolini', 'latest/functions/f_add_eca_pert_ruolo.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 107, 'EXECUTED', '8:fdcc946d55a8fc6948c45b362513ef93', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_add_pro_pert_ruolo', 'abrandolini', 'latest/functions/f_add_pro_pert_ruolo.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 108, 'EXECUTED', '8:9f99e23b2d884c40e8741ac242839375', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_aliquota_alca', 'abrandolini', 'latest/functions/f_aliquota_alca.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 109, 'EXECUTED', '8:9ecb3dbb35b95ad844895f51a5fdc54c', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_aliquota_alca_rif_ap', 'abrandolini', 'latest/functions/f_aliquota_alca_rif_ap.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 110, 'EXECUTED', '8:6ab8241fe7c8f8bca31264971178529d', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_aliquota_mobile', 'abrandolini', 'latest/functions/f_aliquota_mobile.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 111, 'EXECUTED', '8:4a56d1b6b0d1113d2fc8941ceaa6e7d0', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_allinea_dettagli_acc_tarsu', 'abrandolini', 'latest/functions/f_allinea_dettagli_acc_tarsu.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 112, 'EXECUTED', '8:af3485f4fe6d22064dc25a449402dbc3', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_altri_importo', 'abrandolini', 'latest/functions/f_altri_importo.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 113, 'EXECUTED', '8:235837c2de4e48772e61d7341e5ab660', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_altri_importo_acconto', 'abrandolini', 'latest/functions/f_altri_importo_acconto.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 114, 'EXECUTED', '8:a564455e39ef0987bb598b8b9dbd842a', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_anni_anci_ver', 'abrandolini', 'latest/functions/f_anni_anci_ver.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 115, 'EXECUTED', '8:f951d32b1535eb1983f850d0c473b930', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_arrotonda', 'abrandolini', 'latest/functions/f_arrotonda.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 116, 'EXECUTED', '8:eab3ddb06b2d38784578c1971f0a2412', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_fatture_nr', 'abrandolini', 'latest/procedures/fatture_nr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 657, 'EXECUTED', '8:cc748461018d382ec15d12cb45761578', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_barcode', 'abrandolini', 'latest/functions/f_barcode.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 117, 'EXECUTED', '8:85d3802af9889ac0842f46d1b2d7599a', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_barcode_128c', 'abrandolini', 'latest/functions/f_barcode_128c.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 118, 'EXECUTED', '8:601909d5754486bf3f8c73a6c7d70888', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_bimestre_successivo', 'abrandolini', 'latest/functions/f_bimestre_successivo.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 119, 'EXECUTED', '8:f7480f8652138d11e3a488f179c35050', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_blob2clob', 'abrandolini', 'latest/functions/f_blob2clob.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 120, 'EXECUTED', '8:cb9c687a159f20e0749fd7b29b648209', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_calcola_rottura_demo', 'abrandolini', 'latest/functions/f_calcola_rottura_demo.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 121, 'EXECUTED', '8:7f706189215d0d271699b6c711db1541', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_calcolo_detrazione_immobile', 'abrandolini', 'latest/functions/f_calcolo_detrazione_immobile.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 122, 'EXECUTED', '8:2234e2895c6ad605c636dcde3c37f62b', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_calcolo_imu_saldo', 'abrandolini', 'latest/functions/f_calcolo_imu_saldo.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 123, 'EXECUTED', '8:6fcb49de9a6899456bf054cb7d3a35f1', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_calcolo_interessi', 'abrandolini', 'latest/functions/f_calcolo_interessi.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 124, 'EXECUTED', '8:9e9a9835e061e12358ae720e8c1dad11', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_calcolo_interessi_gg', 'abrandolini', 'latest/functions/f_calcolo_interessi_gg.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 125, 'EXECUTED', '8:c859b054882d5947160abe5727760759', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_calcolo_interessi_gg_titr', 'abrandolini', 'latest/functions/f_calcolo_interessi_gg_titr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 126, 'EXECUTED', '8:419cdf00c673cd7e58dd94294dda2a16', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_calcolo_rata_rc_tarsu', 'abrandolini', 'latest/functions/f_calcolo_rata_rc_tarsu.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 127, 'EXECUTED', '8:63a51f1010ccc9f0e24d7318b3cf8391', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_calcolo_rata_tarsu', 'abrandolini', 'latest/functions/f_calcolo_rata_tarsu.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 128, 'EXECUTED', '8:fffdf4e3c09929abffecf32882b8188d', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_carica_dic_notai_verifica', 'abrandolini', 'latest/functions/f_carica_dic_notai_verifica.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 129, 'EXECUTED', '8:2553090e491e286263eb22867d346efc', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_cata', 'abrandolini', 'latest/functions/f_cata.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 130, 'EXECUTED', '8:5d85a9f907a48d702d2fdeda26b3585d', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_cate_riog', 'abrandolini', 'latest/functions/f_cate_riog.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 131, 'EXECUTED', '8:7ed412e8a31ad3e296015f3e63c62685', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_cate_riog_null', 'abrandolini', 'latest/functions/f_cate_riog_null.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 132, 'EXECUTED', '8:db37e70b3bbfb33b6521b83868d458e4', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_cessazione_accertamento', 'abrandolini', 'latest/functions/f_cessazione_accertamento.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 133, 'EXECUTED', '8:b16f11a344a8ba2a4bec20339ab39682', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_cessazioni_ruolo', 'abrandolini', 'latest/functions/f_cessazioni_ruolo.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 134, 'EXECUTED', '8:d0863f72394b252b773f61344cf13444', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_check_agg_imm_ravv', 'abrandolini', 'latest/functions/f_check_agg_imm_ravv.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 135, 'EXECUTED', '8:db02391973541da3a59d508816c65036', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_check_delete_pratica', 'abrandolini', 'latest/functions/f_check_delete_pratica.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 136, 'EXECUTED', '8:2aa14d236e9f1ce597fe358e6620b678', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_check_digit', 'abrandolini', 'latest/functions/f_check_digit.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 137, 'EXECUTED', '8:cabd8bbfd51e053a910091c567afb468', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_check_oggetto_imu', 'abrandolini', 'latest/functions/f_check_oggetto_imu.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 138, 'EXECUTED', '8:a37d0f2abc18b280d0caa1e85dfae8c2', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_check_ogpr_a_ruolo', 'abrandolini', 'latest/functions/f_check_ogpr_a_ruolo.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 139, 'EXECUTED', '8:f57e180e82df1508b48e6424b309e4bb', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_check_ravvedimento', 'abrandolini', 'latest/functions/f_check_ravvedimento.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 141, 'EXECUTED', '8:9ea8dfa801f9d92400e28f80e941afd3', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_check_ripristino_ann', 'abrandolini', 'latest/functions/f_check_ripristino_ann.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 142, 'EXECUTED', '8:5d82276662ef2bce3d8dce378ee52fd4', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_check_sanzione', 'abrandolini', 'latest/functions/f_check_sanzione.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 143, 'EXECUTED', '8:aa382fd87bf0ad1f80942d2aa222679c', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_check_sostituzione_oggetto', 'abrandolini', 'latest/functions/f_check_sostituzione_oggetto.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 145, 'EXECUTED', '8:7161513be99952d243a91c15b6d98a7e', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_check_tipo_tributo', 'abrandolini', 'latest/functions/f_check_tipo_tributo.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 146, 'EXECUTED', '8:fe460cbab8adcb2799541e37330f8f54', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_cifre_lettere', 'abrandolini', 'latest/functions/f_cifre_lettere.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 147, 'EXECUTED', '8:d80d1f8d61b66c59e3dc319f49e01181', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_classe_riog_null', 'abrandolini', 'latest/functions/f_classe_riog_null.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 148, 'EXECUTED', '8:ebcde15f619f4093ea04488592a010cc', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_cod_fiscale', 'abrandolini', 'latest/functions/f_cod_fiscale.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 149, 'EXECUTED', '8:ba686bf133d0f39f83a2e10ec97dfe7e', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_coeff_gg', 'abrandolini', 'latest/functions/f_coeff_gg.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 150, 'EXECUTED', '8:f7dea07865341a53fded2d677321dd86', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_compensazione_ogim', 'abrandolini', 'latest/functions/f_compensazione_ogim.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 151, 'EXECUTED', '8:e644da4cbe955868e3a02109fd36029f', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_compensazione_ogpr', 'abrandolini', 'latest/functions/f_compensazione_ogpr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 152, 'EXECUTED', '8:4fb0b02028846bc2f76d1b244c75cd2b', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_compensazione_ruolo', 'abrandolini', 'latest/functions/f_compensazione_ruolo.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 153, 'EXECUTED', '8:1027f38240d9f7d5a4053fce927a2b90', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_concessione_attiva', 'abrandolini', 'latest/functions/f_concessione_attiva.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 154, 'EXECUTED', '8:2d7fef25cd7c9e4860014d6ae59552aa', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_consistenza_pert_ruolo', 'abrandolini', 'latest/functions/f_consistenza_pert_ruolo.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 155, 'EXECUTED', '8:6303d149a62b3403bc67539a08e6c38a', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_conta_aliquote_ogco', 'abrandolini', 'latest/functions/f_conta_aliquote_ogco.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 158, 'EXECUTED', '8:f9af2d2455de3e31b28160438bc27504', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_conta_altri_contribuenti', 'abrandolini', 'latest/functions/f_conta_altri_contribuenti.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 159, 'EXECUTED', '8:551c6db41953322d8cc50908a0620ef1', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_conta_costi_storici', 'abrandolini', 'latest/functions/f_conta_costi_storici.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 161, 'EXECUTED', '8:580e00d7f4ffd5c31bccdfbd83b030fa', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_conta_familiari_soggetto', 'abrandolini', 'latest/functions/f_conta_familiari_soggetto.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 162, 'EXECUTED', '8:5556056251a8bd48633ef2ca9008c9db', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_conta_pertinenze', 'abrandolini', 'latest/functions/f_conta_pertinenze.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 163, 'EXECUTED', '8:74973c54c02d1f3fb2a022658e512775', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_F_CONTA_RFID', 'abrandolini', 'latest/functions/F_CONTA_RFID.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 100, 'EXECUTED', '8:db9972f465e4a62a57af1fdd8abed76d', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_cont_attivo', 'abrandolini', 'latest/functions/f_cont_attivo.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 156, 'EXECUTED', '8:1e22de12e04950b76dc9a5bd43ef4954', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_cont_attivo_anno', 'abrandolini', 'latest/functions/f_cont_attivo_anno.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 157, 'EXECUTED', '8:ea181ecf8a3da2e2a73726b569c78055', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_conta_utilizzi_oggetto', 'abrandolini', 'latest/functions/f_conta_utilizzi_oggetto.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 164, 'EXECUTED', '8:f71d5e27f6fc7a206e9250520cd4fed6', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_contitolari_oggetto', 'abrandolini', 'latest/functions/f_contitolari_oggetto.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 165, 'EXECUTED', '8:dc07aa483f0e8af213700622c427cb40', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_controllo_calcolo_imposta', 'abrandolini', 'latest/functions/f_controllo_calcolo_imposta.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 166, 'EXECUTED', '8:55277cf4f4e9100685efc6e496c1fac5', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_count_alca', 'abrandolini', 'latest/functions/f_count_alca.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 167, 'EXECUTED', '8:cb13f28f6686305a7ab2c8c5d1e08da2', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_crea_contribuente', 'abrandolini', 'latest/functions/f_crea_contribuente.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 168, 'EXECUTED', '8:8fbe162dc72c5cedbf9a27a0e30697dd', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_ctr_oggetto_tarsu_obbl', 'abrandolini', 'latest/functions/f_ctr_oggetto_tarsu_obbl.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 169, 'EXECUTED', '8:84e8053c259c916df7159834189b1571', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_ctr_oggetto_tarsu_opz', 'abrandolini', 'latest/functions/f_ctr_oggetto_tarsu_opz.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 170, 'EXECUTED', '8:6fd5a99728cf3ad89066f1155f52dd5b', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_ctr_soggetto_tarsu', 'abrandolini', 'latest/functions/f_ctr_soggetto_tarsu.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 171, 'EXECUTED', '8:4f0e5c3034b1fb163a12886d79aaac8b', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_data_decorrenza', 'abrandolini', 'latest/functions/f_data_decorrenza.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 173, 'EXECUTED', '8:18446db3dfdc96aa552fdc307f53f885', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_data_max_vers_ravv', 'abrandolini', 'latest/functions/f_data_max_vers_ravv.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 174, 'EXECUTED', '8:bbccb7029818231ea1c39cd3bf09cb92', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_data_stampa', 'abrandolini', 'latest/functions/f_data_stampa.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 175, 'EXECUTED', '8:6e8f4d8638e453bf46d47c405b38de55', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_data_variazione', 'abrandolini', 'latest/functions/f_data_variazione.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 176, 'EXECUTED', '8:d9b93d86d80bff7ea1c9541f1957dfff', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_dato_dett_fattura', 'abrandolini', 'latest/functions/f_dato_dett_fattura.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 177, 'EXECUTED', '8:5616ce06cefb8315eb5972c0dd72d816', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_dato_riog', 'abrandolini', 'latest/functions/f_dato_riog.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 178, 'EXECUTED', '8:83f120a58e871703d3b64dbd0cbb4001', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_dato_riog_multiplo', 'abrandolini', 'latest/functions/f_dato_riog_multiplo.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 179, 'EXECUTED', '8:0140ceb0d415d7186f19832df77dc312', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_delta_rate', 'abrandolini', 'latest/functions/f_delta_rate.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 180, 'EXECUTED', '8:625baa8394a53eb6e8b3149e85ab892e', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_denunce_v_automatiche', 'abrandolini', 'latest/functions/f_denunce_v_automatiche.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 181, 'EXECUTED', '8:a396089330dea8c40b9c3598dceaf3e8', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_denuncia_doppia', 'abrandolini', 'latest/functions/f_denuncia_doppia.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 182, 'EXECUTED', '8:16b0443c69cbdbed4a85acc8f9d79508', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_depag_dovuto_mb', 'abrandolini', 'latest/functions/f_depag_dovuto_mb.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 183, 'EXECUTED', '8:43b895d8f973237719d51cb2ec8b50ee', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_depag_gg_solleciti', 'abrandolini', 'latest/functions/f_depag_gg_solleciti.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 184, 'EXECUTED', '8:d43120407d09e61dbd373b180e5da058', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_depag_gg_violazioni', 'abrandolini', 'latest/functions/f_depag_gg_violazioni.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 185, 'EXECUTED', '8:d182ac622737d1687b22c5310abeede7', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_depag_servizio', 'abrandolini', 'latest/functions/f_depag_servizio.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 186, 'EXECUTED', '8:5eae57fafafaa83b3e16f49fd9b7ee4c', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_F_DEPAG_TIPO_TRIBUTO', 'abrandolini', 'latest/functions/F_DEPAG_TIPO_TRIBUTO.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 101, 'EXECUTED', '8:5e117f9558d6c91428d953fb5eaa62b5', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_descrizione_adpr', 'abrandolini', 'latest/functions/f_descrizione_adpr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 187, 'EXECUTED', '8:adc1a4da43f4e59b0b9e345001c4603b', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_descrizione_caca', 'abrandolini', 'latest/functions/f_descrizione_caca.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 188, 'EXECUTED', '8:203da21a456c143258bee3c6d01cc977', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_descrizione_ente', 'abrandolini', 'latest/functions/f_descrizione_ente.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 189, 'EXECUTED', '8:8df226f6a52b1e6addd4a32c7c4060fb', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_descrizione_oggetto', 'abrandolini', 'latest/functions/f_descrizione_oggetto.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 190, 'EXECUTED', '8:a2802348c8374f876102c3c8262e9fb8', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_descrizione_tial', 'abrandolini', 'latest/functions/f_descrizione_tial.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 191, 'EXECUTED', '8:a9cf4924e3521c423da95f79e12e53cb', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_descrizione_timp', 'abrandolini', 'latest/functions/f_descrizione_timp.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 192, 'EXECUTED', '8:0478d560c8740c6adc653db99c55a7e2', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_descrizione_titr', 'abrandolini', 'latest/functions/f_descrizione_titr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 193, 'EXECUTED', '8:219c20ae9e74825afc1378ebc8d73bb5', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_determina_aliquote_ici', 'abrandolini', 'latest/functions/f_determina_aliquote_ici.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 194, 'EXECUTED', '8:edb867808d3a011e63bef18fc9b9fb4d', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_determina_aliquote_tasi', 'abrandolini', 'latest/functions/f_determina_aliquote_tasi.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 195, 'EXECUTED', '8:65ee91427eb48389c2471fcdec525976', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_determina_detr_acconto_ici', 'abrandolini', 'latest/functions/f_determina_detr_acconto_ici.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 196, 'EXECUTED', '8:f853f168b4ff4adb4b2903d09b39388e', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_determina_detr_acconto_tasi', 'abrandolini', 'latest/functions/f_determina_detr_acconto_tasi.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 197, 'EXECUTED', '8:ea87c018ba866941559d7b9f656d6f4e', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_determina_tipo_evento', 'abrandolini', 'latest/functions/f_determina_tipo_evento.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 199, 'EXECUTED', '8:a624b7fe95777b428ce114eb2a42a4e3', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_detrazione_raop_ici', 'abrandolini', 'latest/functions/f_detrazione_raop_ici.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 200, 'EXECUTED', '8:5b9f0e7b45dff4d20f4a22180ce93789', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_detrazione_raop_tasi', 'abrandolini', 'latest/functions/f_detrazione_raop_tasi.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 201, 'EXECUTED', '8:aab13fbea6b531e4d16282d6f037b876', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_dettaglio_imp_ici', 'abrandolini', 'latest/functions/f_dettaglio_imp_ici.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 202, 'EXECUTED', '8:fbfe01e22c0844f4688395bac449f39a', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_dettaglio_riog', 'abrandolini', 'latest/functions/f_dettaglio_riog.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 203, 'EXECUTED', '8:3fa907ae0c03f6ac96dbf68f67f33187', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_dovuto', 'abrandolini', 'latest/functions/f_dovuto.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 204, 'EXECUTED', '8:50498c72ff024d86bae428e0d30efe2a', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_dovuto_com', 'abrandolini', 'latest/functions/f_dovuto_com.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 205, 'EXECUTED', '8:4eb6246a75a29b4f90a7efba953c07a1', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_duplica_denuncia', 'abrandolini', 'latest/functions/f_duplica_denuncia.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 206, 'EXECUTED', '8:31cc88c22ded982a49342ecacdb686bc', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_esiste_aliquota_ogco', 'abrandolini', 'latest/functions/f_esiste_aliquota_ogco.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 207, 'EXECUTED', '8:581a1dd50d63b73a213392542c7ed302', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_esiste_dato_caricamento', 'abrandolini', 'latest/functions/f_esiste_dato_caricamento.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 208, 'EXECUTED', '8:3876e2a5c4a4ec32787266a9f53bac5b', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_esiste_detrazione_ogco', 'abrandolini', 'latest/functions/f_esiste_detrazione_ogco.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 209, 'EXECUTED', '8:001c78f5068f872f4a32f2edaf27282c', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_esiste_oggetto_in_prat', 'abrandolini', 'latest/functions/f_esiste_oggetto_in_prat.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 210, 'EXECUTED', '8:7632007b9ef969d8200e425f46a1bf60', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_esiste_pratica_notificata', 'abrandolini', 'latest/functions/f_esiste_pratica_notificata.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 211, 'EXECUTED', '8:7d6d1fd6611a94ee4a7a7478f5694e36', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_esiste_versamento_pratica', 'abrandolini', 'latest/functions/f_esiste_versamento_pratica.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 212, 'EXECUTED', '8:078872c8a180a56d67f19be20b8d708e', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_fine_validita', 'abrandolini', 'latest/functions/f_fine_validita.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 236, 'EXECUTED', '8:82a7055d2631e09438803816d684ca1f', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_f24_acc_tares', 'abrandolini', 'latest/functions/f_f24_acc_tares.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 213, 'EXECUTED', '8:568b7926f0a3fba4ca3617744d3b8a27', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_f24_causale_errore', 'abrandolini', 'latest/functions/f_f24_causale_errore.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 214, 'EXECUTED', '8:8a424fd88ac997bc7d66c47595f2c03a', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_f24_conta_righe', 'abrandolini', 'latest/functions/f_f24_conta_righe.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 215, 'EXECUTED', '8:1e4e48ab98350bbb77df09ab15c74ce3', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_f24_conta_righe_gdm', 'abrandolini', 'latest/functions/f_f24_conta_righe_gdm.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 216, 'EXECUTED', '8:a880fedfb795a9201117e75d9cdcd0d3', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_f24_get_imposta', 'abrandolini', 'latest/functions/f_f24_get_imposta.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 217, 'EXECUTED', '8:6c7cb70be35890e59a78a6744c814878', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_f24_ici', 'abrandolini', 'latest/functions/f_f24_ici.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 218, 'EXECUTED', '8:13439c968da928571a645baafc48c965', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_f24_imposta_anno_titr', 'abrandolini', 'latest/functions/f_f24_imposta_anno_titr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 219, 'EXECUTED', '8:f471b1f07dfd5a0392a016c2d664d86f', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_f24_imu', 'abrandolini', 'latest/functions/f_f24_imu.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 220, 'EXECUTED', '8:77ec319471e51864b15a711de22c15e5', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_f24_imu_conta_righe', 'abrandolini', 'latest/functions/f_f24_imu_conta_righe.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 221, 'EXECUTED', '8:1061a8905f336d65ffccce6795cb736c', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_f24_imu_tasi', 'abrandolini', 'latest/functions/f_f24_imu_tasi.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 222, 'EXECUTED', '8:98503b60e9372c797806e5b3562ba149', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_f24_note_versamento', 'abrandolini', 'latest/functions/f_f24_note_versamento.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 223, 'EXECUTED', '8:54405fb8559a82643fd589b2b70c3814', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_f24_numero_rate_titr', 'abrandolini', 'latest/functions/f_f24_numero_rate_titr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 224, 'EXECUTED', '8:c8fdf555bfe47e5b80a2d81ab999e09b', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_f24_rate_tributi_minori', 'abrandolini', 'latest/functions/f_f24_rate_tributi_minori.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 226, 'EXECUTED', '8:4f93a1e2c6266b7d8b903d033862cdc5', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_f24_ruolo', 'abrandolini', 'latest/functions/f_f24_ruolo.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 227, 'EXECUTED', '8:b752d5b20b249ce083f702d96930ba0a', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_f24_tares', 'abrandolini', 'latest/functions/f_f24_tares.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 228, 'EXECUTED', '8:9f50b84a0c979acdd07d8db39aea7e9e', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_f24_tari_tefa', 'abrandolini', 'latest/functions/f_f24_tari_tefa.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 229, 'EXECUTED', '8:c16fe7d84a8508ce76ee7d5b2a1ce0a5', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_f24_tasi', 'abrandolini', 'latest/functions/f_f24_tasi.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 230, 'EXECUTED', '8:bdaf7111c3ff9220c1aad275fa90f4cd', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_f24_tasi_conta_righe', 'abrandolini', 'latest/functions/f_f24_tasi_conta_righe.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 231, 'EXECUTED', '8:92b1b16ea88c19dbfb420866c97fdeb3', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_f24_titr', 'abrandolini', 'latest/functions/f_f24_titr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 232, 'EXECUTED', '8:7b738c227ad25c116b25c2553538b0fb', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_f24_tributi_minori', 'abrandolini', 'latest/functions/f_f24_tributi_minori.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 233, 'EXECUTED', '8:ad83484750852dc12a8cf496f9bc13dd', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_f24_tributiweb', 'abrandolini', 'latest/functions/f_f24_tributiweb.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 234, 'EXECUTED', '8:0de3fba142ae3953832ee03b4fbf9ae1', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_get_ab_principale', 'abrandolini', 'latest/functions/f_get_ab_principale.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 237, 'EXECUTED', '8:604b355178ddc615675da34bcd41609a', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_get_campo_ad4_com', 'abrandolini', 'latest/functions/f_get_campo_ad4_com.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 238, 'EXECUTED', '8:76b4b28a5d7b8203d9c777491f16c5bc', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_get_campo_csv', 'abrandolini', 'latest/functions/f_get_campo_csv.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 239, 'EXECUTED', '8:e0c25ba89e252c1076bdb6ff7d80d63e', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_get_cata_perc', 'abrandolini', 'latest/functions/f_get_cata_perc.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 240, 'EXECUTED', '8:a155cfa127f2b70a55d4f0f93ab5d24b', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_F_GET_CODICE_F24', 'abrandolini', 'latest/functions/F_GET_CODICE_F24.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 102, 'EXECUTED', '8:f0a57b6606e81587963853216d9e5877', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_get_competenza_utente', 'abrandolini', 'latest/functions/f_get_competenza_utente.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 241, 'EXECUTED', '8:18c4159bfd9c726f7ba6fdc653c6017d', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_get_comune_belfiore', 'abrandolini', 'latest/functions/f_get_comune_belfiore.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 242, 'EXECUTED', '8:00f6b5a2da00d9edc2df674fa0750dba', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_get_data_fine', 'abrandolini', 'latest/functions/f_get_data_fine.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 243, 'EXECUTED', '8:49260b2445246fd16369625fb11790d3', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_get_data_fine_da_mese', 'abrandolini', 'latest/functions/f_get_data_fine_da_mese.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 244, 'EXECUTED', '8:bf7d02ea9f67169c5c9387e4511c531d', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_get_data_fine_ogco', 'abrandolini', 'latest/functions/f_get_data_fine_ogco.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 245, 'EXECUTED', '8:d2d08eab5b67543e4b48c733c30a4301', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_get_data_inizio_da_mese', 'abrandolini', 'latest/functions/f_get_data_inizio_da_mese.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 246, 'EXECUTED', '8:84e02b68dffe6ce1782af8b92ecc426a', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_get_data_inizio_ogco', 'abrandolini', 'latest/functions/f_get_data_inizio_ogco.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 247, 'EXECUTED', '8:a1ae1123bbf4aede306732a47bd9daa9', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_get_data_scadenza', 'abrandolini', 'latest/functions/f_get_data_scadenza.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 248, 'EXECUTED', '8:7c8436771f350b26edc34ab1f1510afa', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_get_dati_belfiore', 'abrandolini', 'latest/functions/f_get_dati_belfiore.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 249, 'EXECUTED', '8:961160c61f79c8bf779372562c1b23da', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_get_dati_presso', 'abrandolini', 'latest/functions/f_get_dati_presso.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 250, 'EXECUTED', '8:f3010de2466f3bf8adcedc20c6d7b5d2', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_get_decorrenza_cessazione', 'abrandolini', 'latest/functions/f_get_decorrenza_cessazione.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 251, 'EXECUTED', '8:19f3c350c78a65b0cadca8f65be875e1', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_get_denominazione_via', 'abrandolini', 'latest/functions/f_get_denominazione_via.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 252, 'EXECUTED', '8:701a9a2f599010be6b1728678fff83ee', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_get_descr_errore', 'abrandolini', 'latest/functions/f_get_descr_errore.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 253, 'EXECUTED', '8:14102464f599159c11686b955a2174ff', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_get_descr_quota', 'abrandolini', 'latest/functions/f_get_descr_quota.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 254, 'EXECUTED', '8:fca37f29ba32b89f60250130554a713e', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_get_evento_c', 'abrandolini', 'latest/functions/f_get_evento_c.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 256, 'EXECUTED', '8:736fc4bbe2132fc944ce12513c2d34c4', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_get_familiari_ogim', 'abrandolini', 'latest/functions/f_get_familiari_ogim.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 257, 'EXECUTED', '8:f13811a646b9f0657d4b71af9630befd', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_get_familiari_ogpr', 'abrandolini', 'latest/functions/f_get_familiari_ogpr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 258, 'EXECUTED', '8:8eeaf57469a6400617034206edccda03', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_get_familiari_sgra', 'abrandolini', 'latest/functions/f_get_familiari_sgra.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 259, 'EXECUTED', '8:732457709157370869e2e54378947559', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_get_fine_periodo_ogco', 'abrandolini', 'latest/functions/f_get_fine_periodo_ogco.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 260, 'EXECUTED', '8:baf0514092aadb19f1495d73ba4c057a', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_get_flag_ruolo', 'abrandolini', 'latest/functions/f_get_flag_ruolo.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 261, 'EXECUTED', '8:21a31941d388b8e60031a0542ab1f985', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_get_imposta_lorda_per_ogpr', 'abrandolini', 'latest/functions/f_get_imposta_lorda_per_ogpr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 262, 'EXECUTED', '8:ea065ea180a2d94929debbab68673c96', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_get_imposta_netta_per_ogpr', 'abrandolini', 'latest/functions/f_get_imposta_netta_per_ogpr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 263, 'EXECUTED', '8:6e8df0220b3ecee4c7db3fd4753be56d', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_get_inizio_periodo_ogco', 'abrandolini', 'latest/functions/f_get_inizio_periodo_ogco.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 264, 'EXECUTED', '8:72e1a0b0f968218b16f46db2b85bed10', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_get_magg_tares_per_ogpr', 'abrandolini', 'latest/functions/f_get_magg_tares_per_ogpr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 265, 'EXECUTED', '8:15337480a62daf41207720e19f28a0d0', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_get_mesi_ab_princ', 'abrandolini', 'latest/functions/f_get_mesi_ab_princ.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 266, 'EXECUTED', '8:dea981e1da7d2b9bbadd0ef2b7f2278e', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_get_mesi_affitto', 'abrandolini', 'latest/functions/f_get_mesi_affitto.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 267, 'EXECUTED', '8:79abd4c4f01095684de9594ae39a73aa', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_get_mesi_possesso', 'abrandolini', 'latest/functions/f_get_mesi_possesso.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 268, 'EXECUTED', '8:1d5b6714f45f23b775218acce0bc22ce', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_get_mesi_possesso_1sem', 'abrandolini', 'latest/functions/f_get_mesi_possesso_1sem.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 269, 'EXECUTED', '8:2507e979ee67aa876048c625011f1935', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_get_mesi_sgravio', 'abrandolini', 'latest/functions/f_get_mesi_sgravio.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 270, 'EXECUTED', '8:b830175a5a407aa2853307a46ea23247', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_get_nome_file_tras_ruoli', 'abrandolini', 'latest/functions/f_get_nome_file_tras_ruoli.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 271, 'EXECUTED', '8:beb958830be971ec6c8819ecff2a002c', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_get_num_fam_ogim', 'abrandolini', 'latest/functions/f_get_num_fam_ogim.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 273, 'EXECUTED', '8:bd6cacf4d0b34727160297536dc66d83', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_get_perc_occupante', 'abrandolini', 'latest/functions/f_get_perc_occupante.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 274, 'EXECUTED', '8:6eaa96b87baf8512da5fa17315021264', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_get_progr_invio_ruoli', 'abrandolini', 'latest/functions/f_get_progr_invio_ruoli.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 275, 'EXECUTED', '8:4c72ebd0bb010d409b4948c9eb8cf3c9', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_get_rendita_riog', 'abrandolini', 'latest/functions/f_get_rendita_riog.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 276, 'EXECUTED', '8:672e999534c516ed41dcffb26b4b7373', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_get_riog_data', 'abrandolini', 'latest/functions/f_get_riog_data.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 277, 'EXECUTED', '8:469d9350cd26b6a1f7edada38ad4d965', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_get_sconto_conf', 'abrandolini', 'latest/functions/f_get_sconto_conf.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 278, 'EXECUTED', '8:62d28177c43583297b01bdd1c7e4eef6', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_get_stringa_note', 'abrandolini', 'latest/functions/f_get_stringa_note.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 279, 'EXECUTED', '8:311550d9827ed4a3b1841d7c438d0e10', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_get_tariffa_base', 'abrandolini', 'latest/functions/f_get_tariffa_base.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 280, 'EXECUTED', '8:ca7ae79803eb9bffcc7215e647d94df5', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_get_tipo_contatto_cf', 'abrandolini', 'latest/functions/f_get_tipo_contatto_cf.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 281, 'EXECUTED', '8:33feb6539d8ecfde10c33b3e681608cd', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_get_tipo_emissione_ruolo', 'abrandolini', 'latest/functions/f_get_tipo_emissione_ruolo.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 282, 'EXECUTED', '8:20bdeb85801d979690b2fc8525a992ba', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_get_tipo_imu', 'abrandolini', 'latest/functions/f_get_tipo_imu.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 283, 'EXECUTED', '8:de5b7b58822a668c1592ef498f69cba3', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_importi_acc', 'abrandolini', 'latest/functions/f_importi_acc.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 285, 'EXECUTED', '8:2280532a0d76716cd7bcfdbb41b46c2a', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_importi_acc_totale_tarsu', 'abrandolini', 'latest/functions/f_importi_acc_totale_tarsu.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 286, 'EXECUTED', '8:1bcdb6bdab70f3ec76c6c76109aa3f68', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_importi_anno_tarsu', 'abrandolini', 'latest/functions/f_importi_anno_tarsu.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 287, 'EXECUTED', '8:f1ac44d7e4845960afc854f212d7c419', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_importi_ruoli_tarsu', 'abrandolini', 'latest/functions/f_importi_ruoli_tarsu.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 288, 'EXECUTED', '8:bf07214d805b9576aadd915cb385faa5', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_importi_ruolo_acconto', 'abrandolini', 'latest/functions/f_importi_ruolo_acconto.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 289, 'EXECUTED', '8:a8948d6a703d4c811273dc284096fea6', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_importi_ruolo_saldo', 'abrandolini', 'latest/functions/f_importi_ruolo_saldo.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 290, 'EXECUTED', '8:492f8c56f7fefbd2723c02bc36510f00', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_importo_acc_lordo', 'abrandolini', 'latest/functions/f_importo_acc_lordo.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 291, 'EXECUTED', '8:69b8d256a3bbefd1231a956970963e16', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_importo_boll_violazione', 'abrandolini', 'latest/functions/f_importo_boll_violazione.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 292, 'EXECUTED', '8:0782df3736ca43ee307197d88cd01a04', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_importo_da_scalare', 'abrandolini', 'latest/functions/f_importo_da_scalare.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 293, 'EXECUTED', '8:2c09ba8f55f5066b825907f06e685818', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_importo_da_scalare_sem', 'abrandolini', 'latest/functions/f_importo_da_scalare_sem.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 294, 'EXECUTED', '8:2c0e48124106101d3d95e86943ebabb1', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_importo_da_scalare_sup2s', 'abrandolini', 'latest/functions/f_importo_da_scalare_sup2s.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 295, 'EXECUTED', '8:f7f759808275dff5b5dd18d2845a7d86', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_importo_f24_viol', 'abrandolini', 'latest/functions/f_importo_f24_viol.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 296, 'EXECUTED', '8:7f94225bc15e11c3299e1e90c54818db', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_importo_f24_viol_tefa', 'abrandolini', 'latest/functions/f_importo_f24_viol_tefa.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 297, 'EXECUTED', '8:a42e7e96885663e5ab8e6c9896e4561d', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_importo_ingiunzione', 'abrandolini', 'latest/functions/f_importo_ingiunzione.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 298, 'EXECUTED', '8:44e08675ebbc2209c5baf4b2fd8f7bd5', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_importo_ogim', 'abrandolini', 'latest/functions/f_importo_ogim.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 299, 'EXECUTED', '8:be565ee5c6bd32970d33ed88006ce453', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_importo_pert_ruolo', 'abrandolini', 'latest/functions/f_importo_pert_ruolo.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 300, 'EXECUTED', '8:04364d0b5ce21acd34761dfbbf218e81', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_importo_rata', 'abrandolini', 'latest/functions/f_importo_rata.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 301, 'EXECUTED', '8:18ec3b5db6024611cdb0b80ccc5a88c7', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_importo_rata_fatt', 'abrandolini', 'latest/functions/f_importo_rata_fatt.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 302, 'EXECUTED', '8:94de59c018f38225222fe3541b477ab3', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_importo_rid_2', 'abrandolini', 'latest/functions/f_importo_rid_2.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 303, 'EXECUTED', '8:14a5afbf4361f2f7ed756df9d378979b', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_importo_ruolo_coat_trib', 'abrandolini', 'latest/functions/f_importo_ruolo_coat_trib.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 304, 'EXECUTED', '8:fd16b8fba654d5be282867cf5010c79f', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_importo_sanzione', 'abrandolini', 'latest/functions/f_importo_sanzione.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 305, 'EXECUTED', '8:d983172a29073bdc285ab756e05fbfa2', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_importo_sanzione_gg', 'abrandolini', 'latest/functions/f_importo_sanzione_gg.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 306, 'EXECUTED', '8:166206a16b7aa132e1689d901c61b261', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_importo_vers', 'abrandolini', 'latest/functions/f_importo_vers.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 307, 'EXECUTED', '8:2d46493eadfdb9398065d9f9354c37b2', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_importo_vers_as', 'abrandolini', 'latest/functions/f_importo_vers_as.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 308, 'EXECUTED', '8:3c6ad26f143be8e4f0d9ee3a23610f3f', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_importo_vers_ravv', 'abrandolini', 'latest/functions/f_importo_vers_ravv.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 309, 'EXECUTED', '8:86e9aa83533d74d9ae44c2d5d869c980', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_importo_vers_ravv_dett', 'abrandolini', 'latest/functions/f_importo_vers_ravv_dett.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 310, 'EXECUTED', '8:5a21629ebabd2c4c3de8a645fea7cf6a', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_importo_violazione', 'abrandolini', 'latest/functions/f_importo_violazione.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 311, 'EXECUTED', '8:3c218af4cc6c39f3ae36b596a56d4ff3', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_imposta_boll_anno_titr', 'abrandolini', 'latest/functions/f_imposta_boll_anno_titr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 312, 'EXECUTED', '8:4023233dbed00787222b906e03791d90', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_imposta_cont_anno_titr', 'abrandolini', 'latest/functions/f_imposta_cont_anno_titr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 313, 'EXECUTED', '8:c80076d3461fddd96a05743df88ae067', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_imposta_cont_anno_titr_as', 'abrandolini', 'latest/functions/f_imposta_cont_anno_titr_as.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 314, 'EXECUTED', '8:f542c0c38657860d535aa324fab659c5', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_imposta_evasa_acc', 'abrandolini', 'latest/functions/f_imposta_evasa_acc.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 315, 'EXECUTED', '8:da12b3d84d8b99ab650f5dcb66bab05b', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_imposta_pert_ruolo', 'abrandolini', 'latest/functions/f_imposta_pert_ruolo.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 316, 'EXECUTED', '8:93844c7a9d507b719f6c390dd0a3352d', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_imposta_pratica', 'abrandolini', 'latest/functions/f_imposta_pratica.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 317, 'EXECUTED', '8:7b8e1b9115b22cb866b4c5e620b84a49', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_imposta_ruol_addiz_tarsu', 'abrandolini', 'latest/functions/f_imposta_ruol_addiz_tarsu.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 318, 'EXECUTED', '8:da08d5867d7a4047ad8831b33b6ab203', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_imposta_ruol_boll_anno_titr', 'abrandolini', 'latest/functions/f_imposta_ruol_boll_anno_titr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 319, 'EXECUTED', '8:da68c8b00ccfd51f67d57726c1116dae', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_imposta_ruol_boll_rate', 'abrandolini', 'latest/functions/f_imposta_ruol_boll_rate.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 320, 'EXECUTED', '8:919d4e812729dbdef5d80245ec8ff8dc', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_imposta_ruol_cont_anno_titr', 'abrandolini', 'latest/functions/f_imposta_ruol_cont_anno_titr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 321, 'EXECUTED', '8:c293a705001833453b2a425644a6847e', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_imposta_ruolo_coattivo', 'abrandolini', 'latest/functions/f_imposta_ruolo_coattivo.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 323, 'EXECUTED', '8:0ed7173c0ddc87ea6c705572346886e8', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_imposta_ruol_rate', 'abrandolini', 'latest/functions/f_imposta_ruol_rate.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 322, 'EXECUTED', '8:40b4ad67dec7a1a5be960e9d080db842', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_indirizzo_ni_al', 'abrandolini', 'latest/functions/f_indirizzo_ni_al.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 324, 'EXECUTED', '8:765a05b3d8ae6ebd0e1c7d374381f86a', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_inpa_valore', 'abrandolini', 'latest/functions/f_inpa_valore.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 325, 'EXECUTED', '8:1ed15aa9e4ac200dd62497a5f92f59b0', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_is_ruolo_master', 'abrandolini', 'latest/functions/f_is_ruolo_master.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 326, 'EXECUTED', '8:a5e4e9432fecebe73868b664b4468572', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_is_valid_xml', 'abrandolini', 'latest/functions/f_is_valid_xml.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 327, 'EXECUTED', '8:e491fca2b842168a7eab6d8feda87d6e', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_flusso_ritorno_mav', 'abrandolini', 'latest/procedures/flusso_ritorno_mav.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 658, 'EXECUTED', '8:d73388eca0ff8e9ccad837a777efcc0a', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_flusso_ritorno_mav_cosap', 'abrandolini', 'latest/procedures/flusso_ritorno_mav_cosap.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 659, 'EXECUTED', '8:b9087a379bc58cbb828736713eeea713', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_flusso_ritorno_mav_ici_viol', 'abrandolini', 'latest/procedures/flusso_ritorno_mav_ici_viol.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 660, 'EXECUTED', '8:a1ef30a4965e4506bb47bb61acf2817c', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_flusso_ritorno_mav_tarsu', 'abrandolini', 'latest/procedures/flusso_ritorno_mav_tarsu.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 661, 'EXECUTED', '8:18d21738480dd0f2f03f4e844295f958', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_flusso_ritorno_mav_tarsu_rm', 'abrandolini', 'latest/procedures/flusso_ritorno_mav_tarsu_rm.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 662, 'EXECUTED', '8:faa563a154e9f497f4064b5414d5012d', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_flusso_ritorno_rid', 'abrandolini', 'latest/procedures/flusso_ritorno_rid.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 663, 'EXECUTED', '8:22d114429801d04de669cf6159d94d19', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_flusso_ritorno_rid_fmo', 'abrandolini', 'latest/procedures/flusso_ritorno_rid_fmo.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 664, 'EXECUTED', '8:629c5fa84d88258d03fcd16087382396', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_flusso_ritorno_rid_std', 'abrandolini', 'latest/procedures/flusso_ritorno_rid_std.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 665, 'EXECUTED', '8:10e34be17d387ec0410d97f5f71065a9', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_magg_tares_cont_anno_titr', 'abrandolini', 'latest/functions/f_magg_tares_cont_anno_titr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 328, 'EXECUTED', '8:0b45def27b100457bc6a69e9d56e204f', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_max_ogpr_cont_ogge', 'abrandolini', 'latest/functions/f_max_ogpr_cont_ogge.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 329, 'EXECUTED', '8:e9d9e3de8d04eebfde16b979f0e1ceb4', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_max_ogpr_tipr_anno', 'abrandolini', 'latest/functions/f_max_ogpr_tipr_anno.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 330, 'EXECUTED', '8:1810dea5856fa5b0f26a986c52495be1', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_max_riog', 'abrandolini', 'latest/functions/f_max_riog.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 331, 'EXECUTED', '8:a06e77e24292ed11ad4e5daee6ec85e2', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_min_anno_prat', 'abrandolini', 'latest/functions/f_min_anno_prat.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 332, 'EXECUTED', '8:48442e4d898d165eaca659eb21ca04c7', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_numero_familiari', 'abrandolini', 'latest/functions/f_numero_familiari.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 335, 'EXECUTED', '8:4d8a632ade3f5c8e24c3ef2581730ed3', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_numero_familiari_al', 'abrandolini', 'latest/functions/f_numero_familiari_al.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 336, 'EXECUTED', '8:f1023c5e98fc0b63d4321f5b0dd35d7d', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_numero_familiari_al_faso', 'abrandolini', 'latest/functions/f_numero_familiari_al_faso.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 337, 'EXECUTED', '8:2c86fdb0e18ec690f40d915fc120d13d', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_num_pratiche_ruolo_cont', 'abrandolini', 'latest/functions/f_num_pratiche_ruolo_cont.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 334, 'EXECUTED', '8:e0ba1708bfd69f977c1cd475aaf200ce', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_oggetto_cessato', 'abrandolini', 'latest/functions/f_oggetto_cessato.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 338, 'EXECUTED', '8:23ed21717f9ad02c34a8b1817f498d5c', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_oggetto_valido', 'abrandolini', 'latest/functions/f_oggetto_valido.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 339, 'EXECUTED', '8:6839b594cf5154489879ad08e08666aa', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_ogpr_inviato', 'abrandolini', 'latest/functions/f_ogpr_inviato.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 340, 'EXECUTED', '8:40167e9eca630d4ccbda406575a3ddde', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_omesso_tardivo', 'abrandolini', 'latest/functions/f_omesso_tardivo.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 341, 'EXECUTED', '8:47f61cdfd20d0b18d821db80b60d7eed', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_font_ins', 'dmarotta', 'install-data/sql/configurazione/font_ins.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 878, 'EXECUTED', '8:e0aca4302e1fa0637b607084facb4ee6', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_ordinamento_oggetti', 'abrandolini', 'latest/functions/f_ordinamento_oggetti.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 342, 'EXECUTED', '8:f2ffc18cfaddb2d4be4a1c983c0d794c', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152401_forniture_ae_d', 'abrandolini', 'latest/views/forniture_ae_d.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 33, 'EXECUTED', '8:c70286e7796927c6b6bdce3d7495d62e', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152401_forniture_ae_g1', 'abrandolini', 'latest/views/forniture_ae_g1.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 34, 'EXECUTED', '8:388836257d9846979c481408836b2e28', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152401_forniture_ae_g2', 'abrandolini', 'latest/views/forniture_ae_g2.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 35, 'EXECUTED', '8:4745a37747658fe48ee67f77fa606e36', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152401_forniture_ae_g3', 'abrandolini', 'latest/views/forniture_ae_g3.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 36, 'EXECUTED', '8:e81cc7f369189d0cd323ad572d5e89c6', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152401_forniture_ae_g4', 'abrandolini', 'latest/views/forniture_ae_g4.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 37, 'EXECUTED', '8:a5cbf0e128c93b206dd8addad33525c4', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152401_forniture_ae_g5', 'abrandolini', 'latest/views/forniture_ae_g5.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 38, 'EXECUTED', '8:97e1edccfccd1724bf54b5ddffb53273', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152401_forniture_ae_g9', 'abrandolini', 'latest/views/forniture_ae_g9.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 39, 'EXECUTED', '8:174bcf9974c7b4fed677dcf513a5b754', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152401_forniture_ae_m', 'abrandolini', 'latest/views/forniture_ae_m.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 40, 'EXECUTED', '8:cb96c4ab18b00277375e743368672f06', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_forniture_ae_nr', 'abrandolini', 'latest/procedures/forniture_ae_nr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 666, 'EXECUTED', '8:97cff3922cae0a8dd7a976fabe86db07', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_paut_valore', 'abrandolini', 'latest/functions/f_paut_valore.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 343, 'EXECUTED', '8:51848bc96e2520003d25c1c225462977', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_periodo', 'abrandolini', 'latest/functions/f_periodo.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 344, 'EXECUTED', '8:4f78a42901144dd0df6cda19fa37a725', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_possesso', 'abrandolini', 'latest/functions/f_possesso.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 345, 'EXECUTED', '8:d2db1a4a095089a13c1899bfe56cdc73', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_pratica', 'abrandolini', 'latest/functions/f_pratica.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 346, 'EXECUTED', '8:d8ea7ff94100c1c95eb0cb0da858c82b', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_pratica_annullabile', 'abrandolini', 'latest/functions/f_pratica_annullabile.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 347, 'EXECUTED', '8:e9cc7b80da0a97402a48b7ea952fa9b8', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_pratica_tasi_da_imu', 'abrandolini', 'latest/functions/f_pratica_tasi_da_imu.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 348, 'EXECUTED', '8:d5782b931c1733de4d6f7eb88cf58fd0', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_pref_nome_file', 'abrandolini', 'latest/functions/f_pref_nome_file.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 349, 'EXECUTED', '8:b931cf8b154f26f3675ea35646c853ea', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_primo_erede', 'abrandolini', 'latest/functions/f_primo_erede.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 350, 'EXECUTED', '8:872c0e311ea40c26c5cd0d6cda34fc2b', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_primo_erede_cod_fiscale', 'abrandolini', 'latest/functions/f_primo_erede_cod_fiscale.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 351, 'EXECUTED', '8:a1e1c67d6ded738916c262e872384c6f', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_primo_erede_ni', 'abrandolini', 'latest/functions/f_primo_erede_ni.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 352, 'EXECUTED', '8:828ea730d8070b2a6730eb155c35b81d', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_prossima_pratica', 'abrandolini', 'latest/functions/f_prossima_pratica.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 353, 'EXECUTED', '8:ab7ba2fe2caababefd057eaf7c004fce', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_provincia_stato', 'abrandolini', 'latest/functions/f_provincia_stato.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 354, 'EXECUTED', '8:ce13d78a374a4569beb0e8cb90ac559b', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_recapito', 'abrandolini', 'latest/functions/f_recapito.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 355, 'EXECUTED', '8:013b9006f29de73825f4e4e0617eaa50', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_recapito_conv', 'abrandolini', 'latest/functions/f_recapito_conv.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 356, 'EXECUTED', '8:5009676d8b7a59bf9d7ca2f5f0b033b1', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_rendita', 'abrandolini', 'latest/functions/f_rendita.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 357, 'EXECUTED', '8:fd58028d385baf7d57ceb2e5de04cf48', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_rendita_anno_riog', 'abrandolini', 'latest/functions/f_rendita_anno_riog.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 358, 'EXECUTED', '8:5d93ec248f7b164d0604be6f28d79db8', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_rendita_data_riog', 'abrandolini', 'latest/functions/f_rendita_data_riog.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 359, 'EXECUTED', '8:1deef504701b257cc885ee7ac51cb125', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_rendita_riog_ogpr', 'abrandolini', 'latest/functions/f_rendita_riog_ogpr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 360, 'EXECUTED', '8:ea6786a3827fa6f8dbd4f0da983658e4', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_residente_al', 'abrandolini', 'latest/functions/f_residente_al.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 361, 'EXECUTED', '8:af8e3da1bd8496673bbc781b48f86a3d', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_ricalcolo_giorni', 'abrandolini', 'latest/functions/f_ricalcolo_giorni.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 362, 'EXECUTED', '8:04ba4de22c7cef8f0e6cfb0d5400a338', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_ricalcolo_tasi_per_affitto', 'abrandolini', 'latest/functions/f_ricalcolo_tasi_per_affitto.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 363, 'EXECUTED', '8:1b88c5364f7cf18f22c53a5a349302b5', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_riog_valido', 'abrandolini', 'latest/functions/f_riog_valido.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 364, 'EXECUTED', '8:a1228d4008d0fcd16417f917453ea98f', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_round', 'abrandolini', 'latest/functions/f_round.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 365, 'EXECUTED', '8:b7517185808bd7ee53650a1f17dc234b', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_ruolo_totale', 'abrandolini', 'latest/functions/f_ruolo_totale.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 366, 'EXECUTED', '8:c74ad0bba5493ba6d41f2a90b76a05e1', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_ruolo_totale_all', 'abrandolini', 'latest/functions/f_ruolo_totale_all.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 367, 'EXECUTED', '8:99963d28e1095e2b02120d381ae3e8d9', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_sanzioni_addizionali', 'abrandolini', 'latest/functions/f_sanzioni_addizionali.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 369, 'EXECUTED', '8:003519cad1a8ae109e1b7f5da0707582', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_sanz_ravv_per_liq', 'abrandolini', 'latest/functions/f_sanz_ravv_per_liq.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 368, 'EXECUTED', '8:66917c5af6523ca3ff4f00ad1853466d', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_scadenza', 'abrandolini', 'latest/functions/f_scadenza.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 371, 'EXECUTED', '8:9ba028cf42cb401d9bac511ad05409a5', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_scadenza_boll', 'abrandolini', 'latest/functions/f_scadenza_boll.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 372, 'EXECUTED', '8:d49cbbc80c8f19abd69a5f00bf872884', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_scadenza_denuncia', 'abrandolini', 'latest/functions/f_scadenza_denuncia.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 373, 'EXECUTED', '8:88b485d7fa365f2bba7e249486c6db8a', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_scadenza_mini_imu', 'abrandolini', 'latest/functions/f_scadenza_mini_imu.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 374, 'EXECUTED', '8:13867e3df0784992e3a4e8b61a4d1f53', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_scadenza_rata', 'abrandolini', 'latest/functions/f_scadenza_rata.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 375, 'EXECUTED', '8:0c57a9b759bbec4d14dad897a38235f0', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_se_esiste_riog', 'abrandolini', 'latest/functions/f_se_esiste_riog.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 376, 'EXECUTED', '8:759bb655bda9bcfa1b907da8125f3d2a', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_sgravio_anno', 'abrandolini', 'latest/functions/f_sgravio_anno.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 377, 'EXECUTED', '8:220f2fa9b75904c7179672656654fa10', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_sgravio_anno_escl', 'abrandolini', 'latest/functions/f_sgravio_anno_escl.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 378, 'EXECUTED', '8:65b3a4878556a1dcc4ee4a7ee3d53d08', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_sgravio_ogge_cont_anno', 'abrandolini', 'latest/functions/f_sgravio_ogge_cont_anno.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 379, 'EXECUTED', '8:aaf50a69fd7f3e0aa188b2a00dec895e', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_sgravio_ogim', 'abrandolini', 'latest/functions/f_sgravio_ogim.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 380, 'EXECUTED', '8:a6722548a761a9d0ef5bad91a9b8351d', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_sgravio_ogpr', 'abrandolini', 'latest/functions/f_sgravio_ogpr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 381, 'EXECUTED', '8:c72e4495ef5ecbdd7ce02b41aab1ec93', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_sgravio_prtr', 'abrandolini', 'latest/functions/f_sgravio_prtr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 382, 'EXECUTED', '8:be578117194ed1731d8b07fd2576fb74', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_sgravio_ruco_escl', 'abrandolini', 'latest/functions/f_sgravio_ruco_escl.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 383, 'EXECUTED', '8:7927d857bb49c5b4415cc44d5a3e693b', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_spazi_stringa', 'abrandolini', 'latest/functions/f_spazi_stringa.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 384, 'EXECUTED', '8:f1750519b855a70f3998bf97eb25f734', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_spese_mora', 'abrandolini', 'latest/functions/f_spese_mora.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 385, 'EXECUTED', '8:08e1e6fee306ff46fd0418b77abd46ed', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_spese_spedizione', 'abrandolini', 'latest/functions/f_spese_spedizione.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 386, 'EXECUTED', '8:775a573aca24f831f7ce22901912d2a9', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_split', 'abrandolini', 'latest/functions/f_split.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 387, 'EXECUTED', '8:99719bfd148b76197637cfdc380d4efc', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_stampa_com_ruolo', 'abrandolini', 'latest/functions/f_stampa_com_ruolo.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 388, 'EXECUTED', '8:8fbdbc33c9eebee58a7e5890f728bbea', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_stampa_rateazione_f24', 'abrandolini', 'latest/functions/f_stampa_rateazione_f24.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 389, 'EXECUTED', '8:bd2c9637ea8fa16a5b223f0bfdbc1bfb', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_tariffe_chk', 'abrandolini', 'latest/functions/f_tariffe_chk.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 390, 'EXECUTED', '8:f23ea526c94d668d6214076647634de5', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_tipo_accertamento', 'abrandolini', 'latest/functions/f_tipo_accertamento.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 392, 'EXECUTED', '8:70f9ab1f94f3633fefda4164bf0f5a92', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_titolo_da_mese_possesso', 'abrandolini', 'latest/functions/f_titolo_da_mese_possesso.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 393, 'EXECUTED', '8:8bc2c0551585de1e9024575fd9fae798', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_titolo_mesi_possesso', 'abrandolini', 'latest/functions/f_titolo_mesi_possesso.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 394, 'EXECUTED', '8:226e74913af8cbbabc4180cd0f928ba9', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_titolo_mesi_possesso_1sem', 'abrandolini', 'latest/functions/f_titolo_mesi_possesso_1sem.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 395, 'EXECUTED', '8:e3a55da4a0acf4330673397f6fc78d09', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_totale_addizionali', 'abrandolini', 'latest/functions/f_totale_addizionali.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 398, 'EXECUTED', '8:00ff4d1d35755e8a17221b146944fd88', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_totale_sgravi', 'abrandolini', 'latest/functions/f_totale_sgravi.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 399, 'EXECUTED', '8:6b434bdf99655a9d7ea14f6a0a8d3285', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_totali_cont_attivo', 'abrandolini', 'latest/functions/f_totali_cont_attivo.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 400, 'EXECUTED', '8:f54eeefe3f44ace80bd73ac1629db355', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_totali_pratica', 'abrandolini', 'latest/functions/f_totali_pratica.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 401, 'EXECUTED', '8:51cbef8c0334267aee7148265934acc2', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_tot_vers_cont', 'abrandolini', 'latest/functions/f_tot_vers_cont.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 396, 'EXECUTED', '8:df880d341f028fb5b01e42fa465b54cb', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_tot_vers_cont_ruol', 'abrandolini', 'latest/functions/f_tot_vers_cont_ruol.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 397, 'EXECUTED', '8:baca6cbc91d1db7a7e33c8dcfc320455', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_ftp_log_nr', 'abrandolini', 'latest/procedures/ftp_log_nr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 667, 'EXECUTED', '8:72fe8b023d78a61b4cc52c91e7fedba8', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_ftp_trasmissioni_nr', 'abrandolini', 'latest/procedures/ftp_trasmissioni_nr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 668, 'EXECUTED', '8:9f46dda5c24be8edb71d11f2e7c0ab0a', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_tributi_ruolo', 'abrandolini', 'latest/functions/f_tributi_ruolo.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 402, 'EXECUTED', '8:fac0fbf837d312ee4138de672a6bdaf5', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_trova_netto', 'abrandolini', 'latest/functions/f_trova_netto.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 403, 'EXECUTED', '8:a07732201a409bf364f97f1cd6104832', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_ultimo_faog', 'abrandolini', 'latest/functions/f_ultimo_faog.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 404, 'EXECUTED', '8:5be24243a15d2e918f5c5dbbaade00df', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_ultimo_faso', 'abrandolini', 'latest/functions/f_ultimo_faso.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 405, 'EXECUTED', '8:a57843dc7e57ff63737156051413dcd1', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_valore', 'abrandolini', 'latest/functions/f_valore.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 406, 'EXECUTED', '8:6cf06066a2b2fec0ab698b9d3c6abcb9', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_valore_acc', 'abrandolini', 'latest/functions/f_valore_acc.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 407, 'EXECUTED', '8:16ed2a6f8ca6aa028aa1a5d0fd8ec477', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_valore_d', 'abrandolini', 'latest/functions/f_valore_d.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 408, 'EXECUTED', '8:c52a32aa754b82b22ab4ac33598e7032', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_valore_da_rendita', 'abrandolini', 'latest/functions/f_valore_da_rendita.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 410, 'EXECUTED', '8:5ae30dbdabe0e5ded0f2de8f40d58267', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_valore_d_tab', 'abrandolini', 'latest/functions/f_valore_d_tab.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 409, 'EXECUTED', '8:a858d657f7aec38a0e101ba13178b0e7', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_valore_wpf', 'abrandolini', 'latest/functions/f_valore_wpf.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 411, 'EXECUTED', '8:071ef71fecb0041eb2eb0ebfa435911a', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_verifica_cap', 'abrandolini', 'latest/functions/f_verifica_cap.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 412, 'EXECUTED', '8:5be7689d9dfe454e5064cd567a6a6932', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_versato_compensazione', 'abrandolini', 'latest/functions/f_versato_compensazione.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 415, 'EXECUTED', '8:085c6ca2156ac913704d736e794c75d1', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_versato_ingiunzione', 'abrandolini', 'latest/functions/f_versato_ingiunzione.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 416, 'EXECUTED', '8:244fa8e041d9d489ae8d43eec20b7982', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_versato_pratica', 'abrandolini', 'latest/functions/f_versato_pratica.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 417, 'EXECUTED', '8:90494b87f35c05a2bc373b06352b8f77', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_versato_pratica_rid', 'abrandolini', 'latest/functions/f_versato_pratica_rid.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 418, 'EXECUTED', '8:1ec555440b1abaf694c4e10e3cd0dfc0', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_vers_cont', 'abrandolini', 'latest/functions/f_vers_cont.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 413, 'EXECUTED', '8:eaa349d4d3dcf76db79457f421d5b531', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_vers_cont_liq', 'abrandolini', 'latest/functions/f_vers_cont_liq.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 414, 'EXECUTED', '8:93e5459614aeb4bc39f3ade648ab03c4', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_web_calcolo_imposta', 'abrandolini', 'latest/functions/f_web_calcolo_imposta.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 419, 'EXECUTED', '8:f229a854c28b97294b1a1b9429a30934', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_web_calcolo_imposta_cu', 'abrandolini', 'latest/functions/f_web_calcolo_imposta_cu.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 420, 'EXECUTED', '8:234579c6c1444c8ebf39bedb55bba1b0', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_web_calcolo_individuale', 'abrandolini', 'latest/functions/f_web_calcolo_individuale.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 421, 'EXECUTED', '8:9b8a58a3d6d2465f86cb9e5292e6467d', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_web_carica_pratica_k', 'abrandolini', 'latest/functions/f_web_carica_pratica_k.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 422, 'EXECUTED', '8:2424d98d8f27d234912fb02aaa3af4ce', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_web_dovuto_versato', 'abrandolini', 'latest/functions/f_web_dovuto_versato.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 423, 'EXECUTED', '8:ab4939344a7a09df61be825541bd650c', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_web_inserimento_rendite', 'abrandolini', 'latest/functions/f_web_inserimento_rendite.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 424, 'EXECUTED', '8:bc1b0f33b91debeaff9f7f0d4e1e266b', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_web_popolamento_tasi_catasto', 'abrandolini', 'latest/functions/f_web_popolamento_tasi_catasto.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 425, 'EXECUTED', '8:81d205ecd11f5c508b3341ebe52860db', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_web_popolamento_tasi_imu', 'abrandolini', 'latest/functions/f_web_popolamento_tasi_imu.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 426, 'EXECUTED', '8:b4d1567c4bb89d4a30f8c6020bd62d2d', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_web_prossima_pratica', 'abrandolini', 'latest/functions/f_web_prossima_pratica.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 427, 'EXECUTED', '8:9a039e9450153711791c3c8dc3527869', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_f_web_sostituzione_oggetto', 'abrandolini', 'latest/functions/f_web_sostituzione_oggetto.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 428, 'EXECUTED', '8:29c84c494b0b284db3b26492c2461b88', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_gestione_noog_pratica', 'abrandolini', 'latest/procedures/gestione_noog_pratica.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 669, 'EXECUTED', '8:5ff1857fdbbb378a00c33924d9e95fc0', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_gestione_successioni', 'abrandolini', 'latest/procedures/gestione_successioni.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 670, 'EXECUTED', '8:eb001aaa526cfc967c36e3dbd089a00e', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_get_inpa_sosp_ferie', 'abrandolini', 'latest/procedures/get_inpa_sosp_ferie.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 672, 'EXECUTED', '8:9bde4f2fd55501aec09ca60e34c89e67', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_get_mesi_affitto', 'abrandolini', 'latest/procedures/get_mesi_affitto.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 673, 'EXECUTED', '8:2b8e5ef6bc9a22cc0bab27301d690526', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152401_gis_pulisci_viste_imu', 'abrandolini', 'latest/views/gis_pulisci_viste_imu.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 41, 'EXECUTED', '8:3bf3f873bf17e60a95f91268081810a5', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152401_gis_viste_catasto_imu', 'abrandolini', 'latest/views/gis_viste_catasto_imu.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 42, 'EXECUTED', '8:9628338a1dda140a90ac2748dbfc8d68', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152401_gis_viste_catasto_no_imu', 'abrandolini', 'latest/views/gis_viste_catasto_no_imu.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 43, 'EXECUTED', '8:2c25f1469d5af0c1b5daadca0c8e097a', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152401_immobili_catasto_terreni_cc', 'abrandolini', 'latest/views/immobili_catasto_terreni_cc.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 44, 'EXECUTED', '8:5b0bbf22f13a60d72b1e68459c7f553a', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152401_immobili_catasto_urbano_cc', 'abrandolini', 'latest/views/immobili_catasto_urbano_cc.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 45, 'EXECUTED', '8:45cb2cd04763fd4a83d2ae2ee99673ac', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152401_immobili_catasto_urbano_cu', 'abrandolini', 'latest/views/immobili_catasto_urbano_cu.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 46, 'EXECUTED', '8:65f684d10c10ae6159cdf7cda999ec9f', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152401_immobili_soggetto_cc', 'abrandolini', 'latest/views/immobili_soggetto_cc.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 47, 'EXECUTED', '8:046dfe9d3906b8c829146c9c62e82ee7', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152429_importa_standard', 'abrandolini', 'latest/packages/importa_standard.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 832, 'EXECUTED', '8:aa449c1ef20332e51cf0cd6fbce04c45', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_importa_vers_cosap_poste', 'abrandolini', 'latest/procedures/importa_vers_cosap_poste.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 674, 'EXECUTED', '8:fd64b998b56420efa258c0978d30ed77', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_importa_vers_mav_inc1', 'abrandolini', 'latest/procedures/importa_vers_mav_inc1.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 675, 'EXECUTED', '8:03a3d4b455241aaa1f7ca8f6265a6aac', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_importi_f24_imu', 'abrandolini', 'latest/procedures/importi_f24_imu.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 676, 'EXECUTED', '8:167c8797634937cfe2f103fe3c0771a4', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_importi_f24_tasi', 'abrandolini', 'latest/procedures/importi_f24_tasi.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 677, 'EXECUTED', '8:d5e7e465343c65968ec8d57a910f890d', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_importi_ruolo_acconto', 'abrandolini', 'latest/procedures/importi_ruolo_acconto.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 679, 'EXECUTED', '8:6de0f03dbd200ba209ac3a9f78b75c1f', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_importi_ruolo_acc_sal', 'abrandolini', 'latest/procedures/importi_ruolo_acc_sal.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 678, 'EXECUTED', '8:da32110ab71dcb7a8236238a51cd9f35', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_importi_ruolo_totale', 'abrandolini', 'latest/procedures/importi_ruolo_totale.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 680, 'EXECUTED', '8:aa7d766c5b4a2ea064eaa34da1d14fd4', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_imprese_arti_professioni_nr', 'abrandolini', 'latest/procedures/imprese_arti_professioni_nr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 681, 'EXECUTED', '8:62fdbd634925889e28dc5e7d0e5cf2bc', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_init_dbchangelog_ad4', 'dmarotta', 'init/../integration/ad4/tr4sql/init_dbchangelog_ad4.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 933, 'EXECUTED', '8:8bccb74e2d30b4ab009913ddbe40f1cc', 'sql', null, null, '3.10.2-fix1106', null, null, '4892471804');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_init_dbchangelog_depag', 'dmarotta', 'init/../integration/depag/tr4sql/init_dbchangelog_depag.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 937, 'EXECUTED', '8:e7df67253e07226e5b722e70d1ddf470', 'sql', null, null, '3.10.2-fix1106', 'DEPAG', null, '4892471804');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_init_dbchangelog_no_cfa', 'dmarotta', 'init/../integration/cfa/tr4sql/init_dbchangelog_no_cfa.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 936, 'EXECUTED', '8:981f9c1afb5c4fe247b3fcb58d19c48a', 'sql', null, null, '3.10.2-fix1106', '!CFA', null, '4892471804');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_init_dbchangelog_no_gsd', 'dmarotta', 'init/../integration/gsd/tr4sql/init_dbchangelog_no_gsd.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 938, 'EXECUTED', '8:1ad6af5632e74f33300d7806c23b0c2b', 'sql', null, null, '3.10.2-fix1106', '(TRT2 or TRV4)', null, '4892471804');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_init_dbchangelog_no_trb', 'dmarotta', 'init/../integration/trb/tr4sql/init_dbchangelog_no_trb.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 939, 'EXECUTED', '8:ac804db20abdc11153e964e2db9a1df7', 'sql', null, null, '3.10.2-fix1106', '(TRG2 or TRV4)', null, '4892471804');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_init_dbchangelog_so4', 'dmarotta', 'init/../integration/so4/tr4sql/init_dbchangelog_so4.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 934, 'EXECUTED', '8:a658c5e0023d86b15c539d49bc1a189c', 'sql', null, null, '3.10.2-fix1106', null, null, '4892471804');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_init_dbchangelog_tr4', 'dmarotta', 'init/init_dbchangelog_tr4.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 932, 'EXECUTED', '8:428f54d677b8a7c51bbac6ffb3632ce0', 'sql', null, null, '3.10.2-fix1106', null, null, '4892471804');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_init_dbchangelog_tr4Web', 'dmarotta', 'init/../integration/tr4web/tr4sql/init_dbchangelog_tr4Web.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 935, 'EXECUTED', '8:9fda5756e939c58fa902510dacf380f4', 'sql', null, null, '3.10.2-fix1106', null, null, '4892471804');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_inserimento_alog_ravv', 'abrandolini', 'latest/procedures/inserimento_alog_ravv.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 683, 'EXECUTED', '8:03af78931fdea4b182432c630bc26486', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_inserimento_coco_web', 'abrandolini', 'latest/procedures/inserimento_coco_web.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 684, 'EXECUTED', '8:dae08af131d0ce5c0f8927cabeeeb0bd', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_inserimento_defi_cont', 'abrandolini', 'latest/procedures/inserimento_defi_cont.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 685, 'EXECUTED', '8:49ab829c71436ea53e0cc10139bb5ea1', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_inserimento_eventi_cont', 'abrandolini', 'latest/procedures/inserimento_eventi_cont.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 686, 'EXECUTED', '8:89811e81f50b3a44edbb432b68ce678a', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_inserimento_faso_cont', 'abrandolini', 'latest/procedures/inserimento_faso_cont.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 687, 'EXECUTED', '8:d7dd0171e7424e09ff8437003e77a1cf', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_inserimento_interesse_gg', 'abrandolini', 'latest/procedures/inserimento_interesse_gg.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 689, 'EXECUTED', '8:0ac9d4e21486bfdef3b55155807e3af9', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_inserimento_interessi_ruolo_s', 'abrandolini', 'latest/procedures/inserimento_interessi_ruolo_s.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 691, 'EXECUTED', '8:cc9eed554f11b8e71471bb3a3293eda8', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_inserimento_int_magg_tares', 'abrandolini', 'latest/procedures/inserimento_int_magg_tares.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 688, 'EXECUTED', '8:f1c18bfae16c3d942d534e0c47791bef', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_inserimento_periodi_imponibile', 'abrandolini', 'latest/procedures/inserimento_periodi_imponibile.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 692, 'EXECUTED', '8:2a5e40602e6ee678073adf4eb0f96fea', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_inserimento_raim', 'abrandolini', 'latest/procedures/inserimento_raim.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 693, 'EXECUTED', '8:1ab2f0afd7aa10e723e9fdd91ebefa15', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_inserimento_raim_cu', 'abrandolini', 'latest/procedures/inserimento_raim_cu.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 694, 'EXECUTED', '8:9586542ef82619667c8c764470dbff70', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_inserimento_rendite_commit', 'abrandolini', 'latest/procedures/inserimento_rendite_commit.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 695, 'EXECUTED', '8:a0e0ef5d60581dd569681ef3d8986855', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152429_inserimento_rendite_pkg', 'abrandolini', 'latest/packages/inserimento_rendite_pkg.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 833, 'EXECUTED', '8:5d43ffe4934675be94c246af76db095f', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_inserimento_ruolo_coattivo', 'abrandolini', 'latest/procedures/inserimento_ruolo_coattivo.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 696, 'EXECUTED', '8:bd39b0db5c3c1ba9b309599a6fd7f27e', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_inserimento_sanzione_gg', 'abrandolini', 'latest/procedures/inserimento_sanzione_gg.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 698, 'EXECUTED', '8:2123c59a7db7c7283a9d8c5f8ba231c4', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_inserimento_sanzione_ici', 'abrandolini', 'latest/procedures/inserimento_sanzione_ici.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 699, 'EXECUTED', '8:992495177b90eca9164ecc9a758e585e', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_inserimento_sanzione_ici_gg', 'abrandolini', 'latest/procedures/inserimento_sanzione_ici_gg.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 700, 'EXECUTED', '8:9b2c1f624275b3f7366e95f0588d685a', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_inserimento_sanzione_liq', 'abrandolini', 'latest/procedures/inserimento_sanzione_liq.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 701, 'EXECUTED', '8:1ba7bfb665f5d2f88a2a67cf8c1a7904', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_inserimento_sanzione_liq_imu', 'abrandolini', 'latest/procedures/inserimento_sanzione_liq_imu.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 702, 'EXECUTED', '8:d14acbdbe90f71c4a9cb6117c2638c36', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_inserimento_sanzione_liq_tasi', 'abrandolini', 'latest/procedures/inserimento_sanzione_liq_tasi.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 703, 'EXECUTED', '8:2e64e73216a3d4ef746dc1c0e6c3e471', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_inserimento_sanzione_vers', 'abrandolini', 'latest/procedures/inserimento_sanzione_vers.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 704, 'EXECUTED', '8:6bac4b6b81f774de125209418c32cc1a', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_inserimento_versamenti_deleghe', 'abrandolini', 'latest/procedures/inserimento_versamenti_deleghe.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 705, 'EXECUTED', '8:886a9ac2ff13d8e4858f81a5ec5528e0', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_inserimento_versamenti_rid', 'abrandolini', 'latest/procedures/inserimento_versamenti_rid.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 706, 'EXECUTED', '8:cd4ff6da52cb1f57cc2903c7e44e23bb', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_ins_xsl_notai_to_html', 'abrandolini', 'latest/procedures/ins_xsl_notai_to_html.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 682, 'EXECUTED', '8:b9350ce89a67d00626dbcb42f5c82bbc', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152429_integritypackage', 'abrandolini', 'latest/packages/integritypackage.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 834, 'EXECUTED', '8:9f41a22cb90a4d5d0ec25f605a6fe9f6', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_inte_ins', 'dmarotta', 'install-data/sql/configurazione/inte_ins.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 879, 'EXECUTED', '8:04290673aa798e0c1802e0293840da00', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_interessi_di', 'abrandolini', 'latest/procedures/interessi_di.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 707, 'EXECUTED', '8:c4cd340264056c9cda297666ca39f17e', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_interessi_nr', 'abrandolini', 'latest/procedures/interessi_nr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 708, 'EXECUTED', '8:09284a14507e9719ec54771afb3732f8', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_interessi_ruolo_coattivo', 'abrandolini', 'latest/procedures/interessi_ruolo_coattivo.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 709, 'EXECUTED', '8:be8e2f4f528c78f3345e04bde60bd400', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_intestazione_minuta_ruolo', 'abrandolini', 'latest/procedures/intestazione_minuta_ruolo.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 710, 'EXECUTED', '8:7e1a4eab6d3b828fb932cb34b16fc78e', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_iter_pratica_nr', 'abrandolini', 'latest/procedures/iter_pratica_nr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 711, 'EXECUTED', '8:d82e273a9e87ad8832e7a21c386916b9', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152401_key_ntext', 'abrandolini', 'latest/views/key_ntext.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 48, 'EXECUTED', '8:df5f779a30dfc9db907769fa541d785a', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152401_key_nword', 'abrandolini', 'latest/views/key_nword.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 49, 'EXECUTED', '8:2fcf97cd2b9dba16d356cee5a227b248', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152429_keypackage', 'abrandolini', 'latest/packages/keypackage.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 835, 'EXECUTED', '8:11538ed49e4ebea09b5922279bd0e737', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_limiti_calcolo_nr', 'abrandolini', 'latest/procedures/limiti_calcolo_nr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 712, 'EXECUTED', '8:e3a612c9d96310dc27e8380d24ddb01b', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152401_liquidazione_ogpr_acc', 'abrandolini', 'latest/views/liquidazione_ogpr_acc.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 50, 'EXECUTED', '8:f368b0c0afbc107832d7f6baad3bbafb', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_liquidazioni_ici_sanz_vers', 'abrandolini', 'latest/procedures/liquidazioni_ici_sanz_vers.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 715, 'EXECUTED', '8:ca8174712cf54208ca1b1a06eb81cd7a', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_liquidazioni_ici_sanz_vers_711', 'abrandolini', 'latest/procedures/liquidazioni_ici_sanz_vers_711.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 716, 'EXECUTED', '8:7e27194e527f509209daf641661e6d29', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_liquidazioni_imu_imp_negativi', 'abrandolini', 'latest/procedures/liquidazioni_imu_imp_negativi.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 717, 'EXECUTED', '8:957cd2093be429726d743575e9ff7edb', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_liquidazioni_imu_rendita', 'abrandolini', 'latest/procedures/liquidazioni_imu_rendita.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 718, 'EXECUTED', '8:1c5d97466cbc4edc19f26b5dc2607143', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_liquidazioni_tasi_sanz_vers', 'abrandolini', 'latest/procedures/liquidazioni_tasi_sanz_vers.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 721, 'EXECUTED', '8:2f4702915cc6700d9530ebc98455a567', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_lire_euro', 'abrandolini', 'latest/procedures/lire_euro.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 722, 'EXECUTED', '8:9a60a6bc90db01e2f55dccffdb9b34dc', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_lott_ins', 'dmarotta', 'install-data/sql/configurazione/lott_ins.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 880, 'EXECUTED', '8:efe5c4dbf9a71fd7d9340014abbb2147', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_moco_ins', 'dmarotta', 'install-data/sql/configurazione/moco_ins.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 881, 'EXECUTED', '8:e55fd5f077a1ccee70a004bbdc4ec820', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_mode_ins', 'dmarotta', 'install-data/sql/configurazione/mosg_ins.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 886, 'EXECUTED', '8:f52cd543a5dfcaedb8b93fadb1e060c3', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_mode_ins', 'dmarotta', 'install-data/sql/configurazione/mode_ins.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 882, 'EXECUTED', '8:0a384c9d964b2f061dd6eec54a8efb2d', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_modelli_ins', 'dmarotta', 'install-data/sql/configurazione/modelli_ins.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 883, 'EXECUTED', '8:efed81abd97548b5d809e432a244caa5', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_modelli_nr', 'abrandolini', 'latest/procedures/modelli_nr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 725, 'EXECUTED', '8:00f310705fc5d747617d94a191e28a49', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_modelli_versione_nr', 'abrandolini', 'latest/procedures/modelli_versione_nr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 726, 'EXECUTED', '8:204605efd2bd64a58040e738d22d612b', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_mod_min_denuncia_ici', 'abrandolini', 'latest/procedures/mod_min_denuncia_ici.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 723, 'EXECUTED', '8:cc314c9643bf5ff3faffdd0ed717ed31', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_mod_min_denuncia_imu', 'abrandolini', 'latest/procedures/mod_min_denuncia_imu.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 724, 'EXECUTED', '8:878623c5a5c0bcf1e034125d852ba4e7', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_modt_ins', 'dmarotta', 'install-data/sql/configurazione/modt_ins.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 884, 'EXECUTED', '8:bbeac659170f85e39d3093e1a4d8e3e0', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_molt_ins', 'dmarotta', 'install-data/sql/configurazione/molt_ins.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 885, 'EXECUTED', '8:f0e80605c4ed9365cc00b8bcffd4334a', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_motivi_pratica_nr', 'abrandolini', 'latest/procedures/motivi_pratica_nr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 727, 'EXECUTED', '8:f365dbf15b4b575803824a6e303d5323', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_numera_bollettini', 'abrandolini', 'latest/procedures/numera_bollettini.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 729, 'EXECUTED', '8:419870e3b6170f8a38d8eccecca03b47', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_numera_bollettini_anno', 'abrandolini', 'latest/procedures/numera_bollettini_anno.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 730, 'EXECUTED', '8:95928fec736ec4f211dcd45674c60675', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_numera_bollettini_ruolo', 'abrandolini', 'latest/procedures/numera_bollettini_ruolo.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 731, 'EXECUTED', '8:d745564e7ac900f5868315c949d6d474', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_numera_elenco_sgravi', 'abrandolini', 'latest/procedures/numera_elenco_sgravi.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 732, 'EXECUTED', '8:f899c0431ada84d2b0b155995e413116', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_numera_pratiche', 'abrandolini', 'latest/procedures/numera_pratiche.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 733, 'EXECUTED', '8:d40062e25412f20ecd0487dff136db04', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_num_ruolo_per_contribuente', 'abrandolini', 'latest/procedures/num_ruolo_per_contribuente.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 728, 'EXECUTED', '8:9d28c0ab3d91291580ce52c6330045c4', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152401_oggetti_contribuente_anno', 'abrandolini', 'latest/views/oggetti_contribuente_anno.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 51, 'EXECUTED', '8:42e3a9e6cf64508537b3df8a6ffb7b4b', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_oggetti_contribuente_di', 'abrandolini', 'latest/procedures/oggetti_contribuente_di.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 734, 'EXECUTED', '8:44cdd09f3ea1afd6218cfe4627398b70', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_oggetti_di', 'abrandolini', 'latest/procedures/oggetti_di.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 735, 'EXECUTED', '8:ae266ac97e8603bb2e13988d79844d74', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_oggetti_fi', 'abrandolini', 'latest/procedures/oggetti_fi.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 736, 'EXECUTED', '8:ccb95c2244b1d9efa1f79e6361f1649b', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152401_oggetti_ici', 'abrandolini', 'latest/views/oggetti_ici.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 52, 'EXECUTED', '8:7cf2de684975a899c14c6008a3c7e533', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152401_oggetti_iciap', 'abrandolini', 'latest/views/oggetti_iciap.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 53, 'EXECUTED', '8:fd340547c3bc105bf1674cfc89c57878', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_oggetti_imposta_di', 'abrandolini', 'latest/procedures/oggetti_imposta_di.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 737, 'EXECUTED', '8:bc4db09d5943fb77f63d75774ee1a258', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_oggetti_imposta_fi', 'abrandolini', 'latest/procedures/oggetti_imposta_fi.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 738, 'EXECUTED', '8:7671602fc4499c6e65fafe9f2ff09e8b', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_OGGETTI_IMPOSTA_NR', 'abrandolini', 'latest/procedures/OGGETTI_IMPOSTA_NR.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 430, 'EXECUTED', '8:5d8e5bc905cafd43b42294066c10ad8d', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_OGGETTI_NR', 'abrandolini', 'latest/procedures/OGGETTI_NR.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 431, 'EXECUTED', '8:9f8d0502d3ad4b2f53efbb009f286fe4', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_oggetti_pratica_di', 'abrandolini', 'latest/procedures/oggetti_pratica_di.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 739, 'EXECUTED', '8:ce7d4b7fd1815715c726ba0134bb0512', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_OGGETTI_PRATICA_NR', 'abrandolini', 'latest/procedures/OGGETTI_PRATICA_NR.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 432, 'EXECUTED', '8:0e1c44c9675b6f6f6f4b65756d831ec2', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152401_oggetti_storici', 'abrandolini', 'latest/views/oggetti_storici.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 54, 'EXECUTED', '8:5903e92f1c97df7fe6fa722d337cd063', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152401_oggetti_tarsu', 'abrandolini', 'latest/views/oggetti_tarsu.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 55, 'EXECUTED', '8:bc416fbb795d2c3527406ea465b84e38', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152401_oggetti_tasi', 'abrandolini', 'latest/views/oggetti_tasi.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 56, 'EXECUTED', '8:87294969d11ee2ed2bbf7dfc4049243c', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152401_oggetti_tosap', 'abrandolini', 'latest/views/oggetti_tosap.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 57, 'EXECUTED', '8:d1ebe2c9ed8a8039efc1abdde1a5673c', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152401_oggetti_validita', 'abrandolini', 'latest/views/oggetti_validita.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 58, 'EXECUTED', '8:381b0ef8af87efa1d1bcf97194399d92', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_ogtr_ins', 'dmarotta', 'install-data/sql/configurazione/ogtr_ins.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 887, 'EXECUTED', '8:5dc5d1f0973ce0bec227e759af867c20', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_paex_ins', 'dmarotta', 'install-data/sql/configurazione/paex_ins.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 888, 'EXECUTED', '8:ba9f3d7942ac4be27b6ca3978651697a', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152429_pagonline_tr4', 'abrandolini', 'latest/packages/pagonline_tr4.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 942, 'EXECUTED', '8:67066f5405c625307a9ad9411c4497d6', 'sql', null, null, '3.10.2-fix1106', 'DEPAG', null, '4892504476');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152429_pagonline_tr4_cu', 'abrandolini', 'latest/packages/pagonline_tr4_cu.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 943, 'EXECUTED', '8:c72de6284db2c3f9d357093453e15c5e', 'sql', null, null, '3.10.2-fix1106', 'DEPAG', null, '4892504476');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_parametri_nr', 'abrandolini', 'latest/procedures/parametri_nr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 740, 'EXECUTED', '8:e8feb53a897b4aeee72380f0c8c3a94c', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_parametri_utente_nr', 'abrandolini', 'latest/procedures/parametri_utente_nr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 741, 'EXECUTED', '8:cd554f45c3eae210cdebee9ff16c08bd', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_partizioni_oggetto_nr', 'abrandolini', 'latest/procedures/partizioni_oggetto_nr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 742, 'EXECUTED', '8:d301e33601fc22ff36a6feff10f747d9', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_partizioni_oggetto_pratica_nr', 'abrandolini', 'latest/procedures/partizioni_oggetto_pratica_nr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 743, 'EXECUTED', '8:bb48d3700388ebdbb0693c6efe29a929', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152401_periodi_ogco', 'abrandolini', 'latest/views/periodi_ogco.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 59, 'EXECUTED', '8:a5f8e80cdefe2d73224167df0ae8c187', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152401_periodi_ogco_prtr', 'abrandolini', 'latest/views/periodi_ogco_prtr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 60, 'EXECUTED', '8:fe33943607e33c7b043c0a99c01cca5b', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152401_periodi_ogco_riog', 'abrandolini', 'latest/views/periodi_ogco_riog.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 61, 'EXECUTED', '8:0891811c8d760ea5de5a110fde9e2ed2', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152401_periodi_ogco_tarsu', 'abrandolini', 'latest/views/periodi_ogco_tarsu.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 62, 'EXECUTED', '8:643beb4492ccbb64ca11986cbaa3bac3', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152401_periodi_ogco_tarsu_trmi', 'abrandolini', 'latest/views/periodi_ogco_tarsu_trmi.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 63, 'EXECUTED', '8:a2dac2b76c67e52f9896f4388faa527a', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152401_periodi_riog', 'abrandolini', 'latest/views/periodi_riog.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 64, 'EXECUTED', '8:3fae5e3af6f4c24985a0f485776810c6', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_piano_finanziario', 'abrandolini', 'latest/procedures/piano_finanziario.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 744, 'EXECUTED', '8:14d34bd4b3bd3ae75fbd4933838e3434', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152429_popolamento_imu_catasto', 'abrandolini', 'latest/packages/popolamento_imu_catasto.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 836, 'EXECUTED', '8:72b5085345ca31534c00f5be7708e281', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_popolamento_imu_terreni', 'abrandolini', 'latest/procedures/popolamento_imu_terreni.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 745, 'EXECUTED', '8:1e1c9e8ad03bdafff44fbce9aa0a0974', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_popolamento_tasi_imu', 'abrandolini', 'latest/procedures/popolamento_tasi_imu.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 747, 'EXECUTED', '8:8ba5e1347b904e81428619ee8173b85a', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_popolamento_tasi_tares', 'abrandolini', 'latest/procedures/popolamento_tasi_tares.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 748, 'EXECUTED', '8:4df44175242237dc02ff91ee99b40c3f', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_pratiche_tributo_di', 'abrandolini', 'latest/procedures/pratiche_tributo_di.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 749, 'EXECUTED', '8:db72f2f4f5297824901f934039496b41', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_pratiche_tributo_fi', 'abrandolini', 'latest/procedures/pratiche_tributo_fi.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 750, 'EXECUTED', '8:8663172bb033c78eca1424b948454969', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_PRATICHE_TRIBUTO_NR', 'abrandolini', 'latest/procedures/PRATICHE_TRIBUTO_NR.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 433, 'EXECUTED', '8:1fc56c85dfca115828b7dd0e903a7416', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152401_proprietari_anagrafe_catasto', 'abrandolini', 'latest/views/proprietari_anagrafe_catasto.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 65, 'EXECUTED', '8:88aff3066fc5e4c5e2c131928ba727f9', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152401_proprietari_catasto_urbano_cc', 'abrandolini', 'latest/views/proprietari_catasto_urbano_cc.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 66, 'EXECUTED', '8:251ffe32ef1447e2dd07a5451d40dd21', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_rapporti_tributo_nr', 'abrandolini', 'latest/procedures/rapporti_tributo_nr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 751, 'EXECUTED', '8:09edbb09678b1ad0eb4601c82fe80c00', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_rate_imposta_nr', 'abrandolini', 'latest/procedures/rate_imposta_nr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 752, 'EXECUTED', '8:e5a3c9fadfaf17170a4c755ed8a4061e', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_rate_pratica_nr', 'abrandolini', 'latest/procedures/rate_pratica_nr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 753, 'EXECUTED', '8:49444cdd579fc45b01039af138810eda', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152401_rate_tributi_minori', 'abrandolini', 'latest/views/rate_tributi_minori.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 68, 'EXECUTED', '8:f01349d8cfc3730c5dba3cb192fcfb22', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_recapiti_soggetto_nr', 'abrandolini', 'latest/procedures/recapiti_soggetto_nr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 754, 'EXECUTED', '8:780a32060a26f876f59006dea44d970a', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_redditi_riferimento_nr', 'abrandolini', 'latest/procedures/redditi_riferimento_nr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 755, 'EXECUTED', '8:43f85d475dcf31ea439303701e53d2d7', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_relazioni_oggetti_calcolo_nr', 'abrandolini', 'latest/procedures/relazioni_oggetti_calcolo_nr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 756, 'EXECUTED', '8:139c8f07aef768b7a029f538307bc871', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_ricalcolo_interessi', 'abrandolini', 'latest/procedures/ricalcolo_interessi.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 758, 'EXECUTED', '8:9a637b40494b92c9abb127bc8541596a', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152401_riduzioni_tariffarie', 'abrandolini', 'latest/views/riduzioni_tariffarie.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 69, 'EXECUTED', '8:e1c7858cc36336f4c3ff5b4175ea5525', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_riferimenti_oggetto_bk_nr', 'abrandolini', 'latest/procedures/riferimenti_oggetto_bk_nr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 759, 'EXECUTED', '8:570d1b7ee2f938d72a0c38b9d999c334', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_riferimenti_oggetto_di', 'abrandolini', 'latest/procedures/riferimenti_oggetto_di.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 760, 'EXECUTED', '8:2abea1ab0ac1629e972cc3f1f8e4cdcd', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_riob_to_riog', 'abrandolini', 'latest/procedures/riob_to_riog.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 761, 'EXECUTED', '8:341877142119df8c82fda12d1761c16e', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_rire_ins', 'dmarotta', 'install-data/sql/configurazione/rire_ins.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 889, 'EXECUTED', '8:30904c07b6976bb6e810adc953774a75', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_ruoli_automatici_nr', 'abrandolini', 'latest/procedures/ruoli_automatici_nr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 762, 'EXECUTED', '8:2111cd3ca1d4c1547540c51af5fddb76', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_ruoli_contribuente_di', 'abrandolini', 'latest/procedures/ruoli_contribuente_di.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 763, 'EXECUTED', '8:871788675182aadfc7d34744cbb73faf', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_ruoli_contribuente_nr', 'abrandolini', 'latest/procedures/ruoli_contribuente_nr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 764, 'EXECUTED', '8:bba50bec5b741e302e86692f871a7304', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_ruoli_di', 'abrandolini', 'latest/procedures/ruoli_di.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 765, 'EXECUTED', '8:333a5c4a7d7441b70c56fde8ef286afd', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_ruoli_eccedenze_nr', 'abrandolini', 'latest/procedures/ruoli_eccedenze_nr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 766, 'EXECUTED', '8:b3526c17884e45d7c9bbe9391c9393d1', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_ruoli_eccedenze_seq_nr', 'abrandolini', 'latest/procedures/ruoli_eccedenze_seq_nr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 767, 'EXECUTED', '8:2ed5974c0cc10244ae85abcdac1c4abd', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152401_ruoli_elenco', 'abrandolini', 'latest/views/ruoli_elenco.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 70, 'EXECUTED', '8:3e652fefc25c23d2a4af5e6ee8a9905b', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_RUOLI_FI', 'abrandolini', 'latest/procedures/RUOLI_FI.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 434, 'EXECUTED', '8:ad75b81ee600f97d04844ad0ce950350', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_ruoli_nr', 'abrandolini', 'latest/procedures/ruoli_nr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 768, 'EXECUTED', '8:71352ed73e1dc51ed93456a7aca974cd', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152401_ruoli_oggetto', 'abrandolini', 'latest/views/ruoli_oggetto.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 71, 'EXECUTED', '8:129fd49ceef314afda23533d904e337d', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_sam_interrogazioni_nr', 'abrandolini', 'latest/procedures/sam_interrogazioni_nr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 769, 'EXECUTED', '8:5604555c2815e17e7d1d0eca4824b8a3', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_sam_risposte_ditta_nr', 'abrandolini', 'latest/procedures/sam_risposte_ditta_nr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 770, 'EXECUTED', '8:bb40d066046b8ce3ff7f7e47da9e9c8b', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_sam_risposte_nr', 'abrandolini', 'latest/procedures/sam_risposte_nr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 771, 'EXECUTED', '8:aa1700514271f9cdee88a63aa118888c', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_sam_risposte_partita_iva_nr', 'abrandolini', 'latest/procedures/sam_risposte_partita_iva_nr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 772, 'EXECUTED', '8:e1ba023f706ff750506529ab61a51f54', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_sam_risposte_rap_nr', 'abrandolini', 'latest/procedures/sam_risposte_rap_nr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 773, 'EXECUTED', '8:b334cf67b966ea22fc1efa25cb3afdd4', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_sanz_ins', 'dmarotta', 'install-data/sql/configurazione/sanz_ins.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 890, 'EXECUTED', '8:c5689c319acd4961bad4dcf923f16f67', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_SANZIONI_NR', 'abrandolini', 'latest/procedures/SANZIONI_NR.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 435, 'EXECUTED', '8:669f240182815e7d6a7f0cd887ba8c04', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_sanzioni_pratica_nr', 'abrandolini', 'latest/procedures/sanzioni_pratica_nr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 775, 'EXECUTED', '8:6fd532ee472a1b545af5e608b5cbaa01', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_scadenze_di', 'abrandolini', 'latest/procedures/scadenze_di.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 776, 'EXECUTED', '8:56126259e163e5db46ae50f9282978b5', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_scadenze_nr', 'abrandolini', 'latest/procedures/scadenze_nr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 777, 'EXECUTED', '8:f792a3c291d091b71b97dfb5a7ef73e7', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_scad_ins', 'dmarotta', 'install-data/sql/configurazione/scad_ins.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 891, 'EXECUTED', '8:98b305c3dfa586979e226655f63391b7', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152429_scambio_dati_ws', 'abrandolini', 'latest/packages/scambio_dati_ws.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 837, 'EXECUTED', '8:3f4146132779df7a14efe058d0453042', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_scelta_vista_catasto', 'abrandolini', 'latest/procedures/scelta_vista_catasto.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 778, 'EXECUTED', '8:f8155133d1f209689c84bb47633866a8', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('AD4_grant_databasechangelog', 'esasdelli', 'adsinstaller/grant.liquibase.xml', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 941, 'RERAN', '8:cc4fd4e19b33f21a2aa60a17a2515044', 'sql', null, null, '3.10.2-fix1106', null, null, '4892492390');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152401_servizi_cc', 'abrandolini', 'latest/views/servizi_cc.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 72, 'EXECUTED', '8:4f2224e1418272619e8923b67d6c35b1', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152401_servizi_ctr', 'abrandolini', 'latest/views/servizi_ctr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 73, 'EXECUTED', '8:db42365526a78f5251a07b204b87e9f2', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152401_servizi_dv', 'abrandolini', 'latest/views/servizi_dv.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 74, 'EXECUTED', '8:14e2bf2a62825002841f8b3f1ae495d8', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_set_valore_wpf', 'abrandolini', 'latest/procedures/set_valore_wpf.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 779, 'EXECUTED', '8:664cd3df9bfbf93b58d86fe13ad0b4e9', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_sgravi_di', 'abrandolini', 'latest/procedures/sgravi_di.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 780, 'EXECUTED', '8:77aad84e12f5fe93af5d8fefecf7e719', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_sgravi_nr', 'abrandolini', 'latest/procedures/sgravi_nr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 781, 'EXECUTED', '8:ac2fa4aa2d041494d10ada5c67efce5f', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152401_sgravi_oggetto', 'abrandolini', 'latest/views/sgravi_oggetto.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 75, 'EXECUTED', '8:908d6a76df948b18c81c91c1205f1494', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152429_si4', 'abrandolini', 'latest/packages/si4.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 838, 'EXECUTED', '8:1b09fc16c971bb818e6a9a4712f63a4d', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152429_si4_competenza', 'abrandolini', 'latest/packages/si4_competenza.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 839, 'EXECUTED', '8:ebbaea326071a97f874140a13f5a04ea', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152401_si4_competenza_oggetti', 'abrandolini', 'latest/views/si4_competenza_oggetti.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 76, 'EXECUTED', '8:342b4cd94d5457c960550b07399e30aa', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_si4_comp_ins', 'dmarotta', 'install-data/sql/configurazione/si4_comp_ins.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 892, 'EXECUTED', '8:86facbcc637628b97ca5909366a1dbf2', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_Si4Comp_o', 'dmarotta', 'install/tables/Si4Comp_o.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 9, 'EXECUTED', '8:572a8aa461f35f2d3bcf19a52ae6fc9c', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_Si4Comp_p', 'dmarotta', 'install/procedures/Si4Comp_p.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 12, 'EXECUTED', '8:fe3be81433dde11cf0e46040ea7aeadb', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_Si4Comp_t', 'dmarotta', 'install/triggers/Si4Comp_t.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 13, 'EXECUTED', '8:bcb53d68d8103340237cf5e5bfd246da', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152429_si4_soggetto', 'abrandolini', 'latest/packages/si4_soggetto.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 840, 'EXECUTED', '8:1a1f364fa0d82bb3d0b19fe62a1ff146', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_sogei_dic_nr', 'abrandolini', 'latest/procedures/sogei_dic_nr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 782, 'EXECUTED', '8:f45011976bd9f4971037f514c785ce9d', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_soggetti_di', 'abrandolini', 'latest/procedures/soggetti_di.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 783, 'EXECUTED', '8:0b4961e16322e80b482d5265e96b159d', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_soggetti_fi', 'abrandolini', 'latest/procedures/soggetti_fi.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 784, 'EXECUTED', '8:7bab5dbdec4cd93f200d2867daba0ae6', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_soggetti_nr', 'abrandolini', 'latest/procedures/soggetti_nr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 785, 'EXECUTED', '8:baa3bca4ad4619c898d3e46f8185f9a8', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152401_soggetti_pratica', 'abrandolini', 'latest/views/soggetti_pratica.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 77, 'EXECUTED', '8:c0c02c312c8fd3c0cc2a142de057e5ec', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_sostituzione_contribuente', 'abrandolini', 'latest/procedures/sostituzione_contribuente.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 786, 'EXECUTED', '8:9a5a54275b0d7cd1ec6ca653caa19bb3', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_sostituzione_contribuente_auto', 'abrandolini', 'latest/procedures/sostituzione_contribuente_auto.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 787, 'EXECUTED', '8:9616d1f07b0cd541e603f71ed80f1220', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_sostituzione_oggetto', 'abrandolini', 'latest/procedures/sostituzione_oggetto.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 788, 'EXECUTED', '8:c82fcec851d5ae083dc85df935da8f9b', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152401_sottocategorie', 'abrandolini', 'latest/views/sottocategorie.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 78, 'EXECUTED', '8:df4f7bcfd2dcd2b280b9a87680c1f067', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_spese_istruttoria_di', 'abrandolini', 'latest/procedures/spese_istruttoria_di.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 789, 'EXECUTED', '8:9d576da4be7492a3f456240559fce4ba', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_spese_notifica_nr', 'abrandolini', 'latest/procedures/spese_notifica_nr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 790, 'EXECUTED', '8:0df3ba58bff34ab357eea58e71ceb91f', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152429_stampa_accertamenti_ici', 'abrandolini', 'latest/packages/stampa_accertamenti_ici.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 841, 'EXECUTED', '8:114e1fc309909e26f5bfccf7b063e8c3', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152429_stampa_accertamenti_tarsu', 'abrandolini', 'latest/packages/stampa_accertamenti_tarsu.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 842, 'EXECUTED', '8:a4b3bc59da80c3f7b97d19d83709c83a', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152429_stampa_accoglimento_ist_rate', 'abrandolini', 'latest/packages/stampa_accoglimento_ist_rate.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 844, 'EXECUTED', '8:2d42bfd301cc9df8d2aaddfd5b6ebada', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152429_stampa_avvisi_cuni', 'abrandolini', 'latest/packages/stampa_avvisi_cuni.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 845, 'EXECUTED', '8:bd1d280bb0a9add95d88ea46fbfc9a6f', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152429_stampa_com_imposta', 'abrandolini', 'latest/packages/stampa_com_imposta.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 847, 'EXECUTED', '8:10ecec57b0d603d0587f430df64f2f69', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152429_stampa_common', 'abrandolini', 'latest/packages/stampa_common.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 848, 'EXECUTED', '8:5b093c78960429c0d310cefc9d660dfd', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152429_stampa_denunce_imu', 'abrandolini', 'latest/packages/stampa_denunce_imu.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 849, 'EXECUTED', '8:1a36849c4aea9ea426fae5caf34ab998', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152429_stampa_denunce_tari', 'abrandolini', 'latest/packages/stampa_denunce_tari.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 850, 'EXECUTED', '8:209ab0a785b73ba5c18ce83b58eeb7df', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152429_stampa_liquidazioni_tasi', 'abrandolini', 'latest/packages/stampa_liquidazioni_tasi.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 852, 'EXECUTED', '8:e83eb83fd03105845be2a5dbf3af4277', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_stampa_rimborsi', 'abrandolini', 'latest/procedures/stampa_rimborsi.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 791, 'EXECUTED', '8:8a59d267f4cfc036610b33b88b979a17', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_stampa_riscossioni', 'abrandolini', 'latest/procedures/stampa_riscossioni.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 792, 'EXECUTED', '8:c68a2af22cc8636d301228379d749eed', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_stati_contribuente_nr', 'abrandolini', 'latest/procedures/stati_contribuente_nr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 793, 'EXECUTED', '8:b8996fb14e49462e73aa90679341f467', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_stat_ins', 'dmarotta', 'install-data/sql/configurazione/stat_ins.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 893, 'EXECUTED', '8:bdcae8f6272b234252f9b3d8049def9b', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152401_sto_web_oggetti_pratica', 'abrandolini', 'latest/views/sto_web_oggetti_pratica.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 79, 'EXECUTED', '8:d34c217e4dcabfd980c2bd94b9aea01b', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_successioni_defunti_nr', 'abrandolini', 'latest/procedures/successioni_defunti_nr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 794, 'EXECUTED', '8:2bbac84369d3b855a7fcf6592907d5d9', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_supporto_servizi_nr', 'abrandolini', 'latest/procedures/supporto_servizi_nr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 795, 'EXECUTED', '8:476aa074c9bdfc8ff1b1ceedf351a200', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152429_supporto_servizi_pkg', 'abrandolini', 'latest/packages/supporto_servizi_pkg.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 855, 'EXECUTED', '8:0a067c9fe713779a56c43eb3423e6441', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_svuotamenti_nr', 'abrandolini', 'latest/procedures/svuotamenti_nr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 796, 'EXECUTED', '8:6c183c96c9dec354bd8fa46a31e7602c', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_tariffe_chk', 'abrandolini', 'latest/procedures/tariffe_chk.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 797, 'EXECUTED', '8:8fb9ed84438da8795855410be9643555', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_tatv_ins', 'dmarotta', 'install-data/sql/configurazione/tatv_ins.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 894, 'EXECUTED', '8:4b478d365f4e60f1b639a1f07205771a', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152401_terreni_soggetto_cc', 'abrandolini', 'latest/views/terreni_soggetto_cc.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 80, 'EXECUTED', '8:fab708b0fb596765bd5edab389adf9e2', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_tial_ins', 'dmarotta', 'install-data/sql/configurazione/tial_ins.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 895, 'EXECUTED', '8:e050c9b985071ecaa41a1c0c7c921c57', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_tiat_ins', 'dmarotta', 'install-data/sql/configurazione/tiat_ins.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 896, 'EXECUTED', '8:1cc570c5db56c592b45f49427e403ff9', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_tico_ins', 'dmarotta', 'install-data/sql/configurazione/tico_ins.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 897, 'EXECUTED', '8:4913f19df7e2103b32fb8c4d492c296c', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_tiex_ins', 'dmarotta', 'install-data/sql/configurazione/tiex_ins.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 898, 'EXECUTED', '8:2518e50d00a9dcabac32851d6c2cfa39', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_timo_ins', 'dmarotta', 'install-data/sql/configurazione/timo_ins.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 899, 'EXECUTED', '8:7ba2efd79faf9212736cc9285a1dac7f', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_timp_ins', 'dmarotta', 'install-data/sql/configurazione/timp_ins.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 900, 'EXECUTED', '8:3fd5ba92d1b4f90650fc36ed48ab747c', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_tino_ins', 'dmarotta', 'install-data/sql/configurazione/tino_ins.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 901, 'EXECUTED', '8:2c4abac8b9b54c8c3d817e28ed0dbf74', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_tiog_ins', 'dmarotta', 'install-data/sql/configurazione/tiog_ins.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 902, 'EXECUTED', '8:a8099fd79a4df8a0ee709a8ab12821fd', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_tipa_ins', 'dmarotta', 'install-data/sql/configurazione/tipa_ins.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 903, 'EXECUTED', '8:0f544e270013bec7faeb19fc2cdde755', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_tipi_modello_parametri_nr', 'abrandolini', 'latest/procedures/tipi_modello_parametri_nr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 798, 'EXECUTED', '8:6b4668973c752ba376d748125c9ce9f7', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_tiqu_ins', 'dmarotta', 'install-data/sql/configurazione/tiqu_ins.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 904, 'EXECUTED', '8:a9dbe83e17518ed5d7511acb9f24e1df', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_tire_ins', 'dmarotta', 'install-data/sql/configurazione/tire_ins.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 905, 'EXECUTED', '8:a8d4276cc84cb462a2fd1f2e16d91e8c', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_tiri_ins', 'dmarotta', 'install-data/sql/configurazione/tiri_ins.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 906, 'EXECUTED', '8:e83d3b210dcafe4136a7ed789493d5f2', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_tisp_ins', 'dmarotta', 'install-data/sql/configurazione/tisp_ins.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 907, 'EXECUTED', '8:27d01658fab0c3acaea5b36ab13e631b', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_tist_ins', 'dmarotta', 'install-data/sql/configurazione/tist_ins.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 908, 'EXECUTED', '8:10b319097cf165c6c182c7562c759319', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_titr_cuni_ins', 'dmarotta', 'install-data/sql/tipitributo/titr_cuni_ins.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 927, 'EXECUTED', '8:08b82b2fbdfa1a2aecebaac93385d2db', 'sql', null, null, '3.10.2-fix1106', null, null, '4816961457');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_titr_ici_ins', 'dmarotta', 'install-data/sql/tipitributo/titr_ici_ins.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 925, 'EXECUTED', '8:a2901b96cb0c5eaf753fb190b163ea66', 'sql', null, null, '3.10.2-fix1106', null, null, '4816960784');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_inpa_ins', 'dmarotta', 'install-data/sql/configurazione/inpa_ins.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 909, 'EXECUTED', '8:210355112d4663fcf5ea1421052616c6', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_titr_ins_tarsu', 'dmarotta', 'install-data/sql/tipitributo/titr_tarsu_ins.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 938, 'EXECUTED', '8:ff569eadbfa2444d06669d61e29e682a', 'sql', null, null, '3.10.2-fix1106', null, null, '6771459197');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_titr_trasv_ins', 'dmarotta', 'install-data/sql/tipitributo/titr_trasv_ins.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 924, 'EXECUTED', '8:431ed6f94f69ad552cb65f1aeda34cde', 'sql', null, null, '3.10.2-fix1106', null, null, '4816960453');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152401_totali_pratica_view', 'abrandolini', 'latest/views/totali_pratica_view.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 81, 'EXECUTED', '8:2a5203b2729b877ed200bdd4570b25e1', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_tras_dichiarazioni', 'abrandolini', 'latest/procedures/tras_dichiarazioni.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 799, 'EXECUTED', '8:2cb5a68a04ad122308904136603dda09', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_tras_dichiarazioni_cont_att', 'abrandolini', 'latest/procedures/tras_dichiarazioni_cont_att.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 800, 'EXECUTED', '8:f6089881c5f019f5a42587ae115f0e25', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_trasmissione_cosap_mav', 'abrandolini', 'latest/procedures/trasmissione_cosap_mav.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 804, 'EXECUTED', '8:9f6ace7a321ac1bebc9e25fceb12f19c', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_trasmissione_rid_std', 'abrandolini', 'latest/procedures/trasmissione_rid_std.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 805, 'EXECUTED', '8:a55d9be6c752a4a554f38d03bac29365', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_trasmissione_ruolo', 'abrandolini', 'latest/procedures/trasmissione_ruolo.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 806, 'EXECUTED', '8:f1df739a280e98e36aba4bde5517d4d8', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_trasmissione_ruolo_600', 'abrandolini', 'latest/procedures/trasmissione_ruolo_600.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 807, 'EXECUTED', '8:7389d853600adfe99eece888303b5de8', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_trasmissione_sgravio', 'abrandolini', 'latest/procedures/trasmissione_sgravio.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 808, 'EXECUTED', '8:fc66825ea12d073cc1ab566c771d5efd', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_tras_rimborsi', 'abrandolini', 'latest/procedures/tras_rimborsi.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 801, 'EXECUTED', '8:d5fa9470cbba98c81184015c04ddab94', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_tras_riscossioni', 'abrandolini', 'latest/procedures/tras_riscossioni.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 802, 'EXECUTED', '8:cea6d14218a27ee634f257de6c31e216', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_tras_tot_riscossioni', 'abrandolini', 'latest/procedures/tras_tot_riscossioni.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 803, 'EXECUTED', '8:333cbc51cc0dc86a33830791e8e6cc81', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152401_tr4_ad4_diritto_accesso', 'abrandolini', 'latest/views/tr4_ad4_diritto_accesso.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 82, 'EXECUTED', '8:b779938e888b3efe7a0816e1535f4db1', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152429_tr4_clob', 'abrandolini', 'latest/packages/tr4_clob.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 856, 'EXECUTED', '8:a222e2030f5d10897dfe6e1f5ff61ab7', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152429_tr4_codice_fiscale', 'abrandolini', 'latest/packages/tr4_codice_fiscale.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 857, 'EXECUTED', '8:28962b701710ab514caaffa3ec2c0f84', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_Tr4_o', 'dmarotta', 'install/tables/Tr4_o.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 18, 'EXECUTED', '8:733ff3da7dbf5925cf21edb5ddb3cf9c', 'sql', null, null, '3.10.2-fix1106', null, null, '6771147432');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152429_tr4package', 'abrandolini', 'latest/packages/tr4package.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 859, 'EXECUTED', '8:8c187d9c810dcf204f5f0197f91b9589', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_Tr4_scelta_cu', 'dmarotta', 'utils/Tr4_scelta_cu.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 929, 'EXECUTED', '8:31932ff1508bb2dbcd3a2eca4b9013f0', 'sql', null, null, '3.10.2-fix1106', null, null, '4816961900');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250407_181738_Tr4_tr', 'abrandolini', 'latest/triggers/Tr4_tr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 873, 'EXECUTED', '8:f512dda96add61642fd37bd40738a4e9', 'sql', null, null, '3.10.2-fix1106', null, null, '6771147432');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152429_utenze_tarsu_ftp', 'abrandolini', 'latest/packages/utenze_tarsu_ftp.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 860, 'EXECUTED', '8:9daa3cc52eeddcc4a3871cb985b05661', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152429_utilitypackage', 'abrandolini', 'latest/packages/utilitypackage.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 861, 'EXECUTED', '8:2511513739de674ba5d319b0f2d6616b', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_utilizzi_oggetto_nr', 'abrandolini', 'latest/procedures/utilizzi_oggetto_nr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 809, 'EXECUTED', '8:ad45df86a7ddb7747fe5f668565d412f', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_versamenti_di', 'abrandolini', 'latest/procedures/versamenti_di.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 810, 'EXECUTED', '8:e12117792e6af056491f60a8a0db0c8b', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152401_versamenti_ici', 'abrandolini', 'latest/views/versamenti_ici.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 83, 'EXECUTED', '8:12cd6973ebf9c7333a38d99403f61c2e', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_versamenti_nr', 'abrandolini', 'latest/procedures/versamenti_nr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 811, 'EXECUTED', '8:35fde9f6ca91e44b3dea8113ef6ba38f', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152401_violazioni_dettagli_ogim', 'abrandolini', 'latest/views/violazioni_dettagli_ogim.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 84, 'EXECUTED', '8:479bd00aad64bf3f8f4117ade29425d5', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_wdca_ins', 'dmarotta', 'install-data/sql/configurazione/wdca_ins.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 910, 'EXECUTED', '8:df4350c9e8dcf4d3bdd57cf0f6cf5124', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152401_web_anaana', 'abrandolini', 'latest/views/web_anaana.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 85, 'EXECUTED', '8:5548ea2b821c0e54a18f514ea0c95409', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152401_web_anadev', 'abrandolini', 'latest/views/web_anadev.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 86, 'EXECUTED', '8:970712b80003ad7aa974c0a70da3269b', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152401_web_anamov', 'abrandolini', 'latest/views/web_anamov.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 87, 'EXECUTED', '8:e0e86610f1a34208bb8e53e315c22fc9', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_web_carica_pratica_k', 'abrandolini', 'latest/procedures/web_carica_pratica_k.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 812, 'EXECUTED', '8:9fdb103fd07bcc6d0ef90243d8aa5fa4', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152401_web_categorie', 'abrandolini', 'latest/views/web_categorie.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 88, 'EXECUTED', '8:fd970fd165ede5064cbf5e61f6ca1f0e', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152401_web_detrazioni_ogco', 'abrandolini', 'latest/views/web_detrazioni_ogco.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 89, 'EXECUTED', '8:3e9b9ded19c0663f2c4aa19cfaa25d09', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152429_web_importa_dati', 'abrandolini', 'latest/packages/web_importa_dati.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 862, 'EXECUTED', '8:2eba7e17aef5b3096bbfdfacb4e633a0', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152401_web_motivi_detrazione', 'abrandolini', 'latest/views/web_motivi_detrazione.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 91, 'EXECUTED', '8:022eb74382db0d53f0b41930f5ba10aa', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152401_web_oggetti_imposta', 'abrandolini', 'latest/views/web_oggetti_imposta.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 92, 'EXECUTED', '8:541ab7bcb675bd248ce3f4118fbf3358', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152401_web_oggetti_pratica', 'abrandolini', 'latest/views/web_oggetti_pratica.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 93, 'EXECUTED', '8:5eff151dc23c49618a0b49d9084524da', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152401_web_oggetti_pratica_rendita', 'abrandolini', 'latest/views/web_oggetti_pratica_rendita.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 94, 'EXECUTED', '8:69211a8e7e312e32ccf66a1d0dfdbd28', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152401_web_oggetti_validita', 'abrandolini', 'latest/views/web_oggetti_validita.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 95, 'EXECUTED', '8:911651a264b5a02bead40ae4d5dd0153', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152401_web_proprietari_catasto_urbano', 'abrandolini', 'latest/views/web_proprietari_catasto_urbano.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 96, 'EXECUTED', '8:72ab6682c0293a6016edc56cce0ec72d', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152401_web_ruoli_oggetto', 'abrandolini', 'latest/views/web_ruoli_oggetto.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 97, 'EXECUTED', '8:6e69ae7640c2d947534e9a31d95345f4', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152401_web_sanzioni_pratica', 'abrandolini', 'latest/views/web_sanzioni_pratica.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 98, 'EXECUTED', '8:c055bce3e492757891a166ca17a08554', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152401_WEB_SUPPORTO_SERVIZI', 'abrandolini', 'latest/views/WEB_SUPPORTO_SERVIZI.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 14, 'EXECUTED', '8:a3762ca476c579a0b6db160ae7974098', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152401_web_tariffe', 'abrandolini', 'latest/views/web_tariffe.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 99, 'EXECUTED', '8:85f68d20e01d23507ee5d1af5f0ab243', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_wpim_ins', 'dmarotta', 'install-data/sql/configurazione/wpim_ins.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 911, 'EXECUTED', '8:3c8d984800b17362cdf3900c50bf01b4', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_wrk_popolamento_tasi_imu_nr', 'abrandolini', 'latest/procedures/wrk_popolamento_tasi_imu_nr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 813, 'EXECUTED', '8:3a4455630d5ed961c0e170b02d9e5d33', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_wrk_versamenti_di', 'abrandolini', 'latest/procedures/wrk_versamenti_di.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 814, 'EXECUTED', '8:1b6809c8161b1cea3c7727ce1a80ce6d', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152423_ws_log_nr', 'abrandolini', 'latest/procedures/ws_log_nr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 815, 'EXECUTED', '8:b55eba829c18e5f9d7aee5ac3b49bd75', 'sql', null, null, '3.10.2-fix1106', null, null, '4816634137');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('dmarotta:20250326_152438_checkInvalidObjects', 'mturra', 'utils/checkInvalidObjects.xml', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 946, 'RERAN', '8:d41d8cd98f00b204e9800998ecf8427e', 'empty', null, null, '3.10.2-fix1106', null, null, '4892540920');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('dmarotta:20250326_152438_compileInvalidObjects', 'mturra', 'utils/compileInvalids.xml', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 945, 'RERAN', '8:97a8e7d93ff091ebd177c93599153eb1', 'sql', null, null, '3.10.2-fix1106', null, null, '4892513055');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250508_152756_ServerError_Trigger', 'dmarotta', 'latest/triggers/ServerError_Trigger.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 873, 'EXECUTED', '8:b3e9a271cbff3827086483aeb2381c89', 'sql', null, null, '3.10.2-fix1106', null, null, '6775137919');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250509_095306_ServerError_Handler', 'dmarotta', 'latest/packages/ServerError_Handler.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 952, 'EXECUTED', '8:68ecf263b0fac934dc400359e9a17cc3', 'sql', null, null, '3.10.2-fix1106', null, null, '6777255342');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250508_152812_keel_tiu', 'dmarotta', 'latest/triggers/keel_tiu.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 881, 'EXECUTED', '8:75a0ba24f7f98b23fc1d426f7343d19e', 'sql', null, null, '3.10.2-fix1106', null, null, '6776696150');
