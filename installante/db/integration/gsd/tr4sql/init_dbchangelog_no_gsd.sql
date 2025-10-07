--liquibase formatted sql
--changeset dmarotta:TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6') stripComments:false context:"TRT2 or TRV4"
--validCheckSum: 1:any
--preConditions onFail:MARK_RAN
--precondition-sql-check expectedResult:1 select count(1) from USER_OBJECTS where OBJECT_TYPE ='TABLE' and  OBJECT_NAME = 'PRATICHE_TRIBUTO'

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250331_110438_Tr4GSD_o', 'abrandolini', 'integration/gsd/tr4sql/Tr4GSD_o.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 912, 'EXECUTED', '8:4cbf87de8e897b5f58f5486148a9e41c', 'sql', null, null, '3.10.2-fix1106', '(TRT2 or TRV4)', null, '4885653702');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250331_123138_f_MOV_fascia_al_TR4', 'abrandolini', 'integration/gsd/tr4sql/f_MOV_fascia_al_TR4.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 913, 'EXECUTED', '8:1af008ba8ff6925a19029146c05aaeca', 'sql', null, null, '3.10.2-fix1106', '(TRT2 or TRV4)', null, '4885653702');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250331_123138_f_unita_territoriale_TR4', 'abrandolini', 'integration/gsd/tr4sql/f_unita_territoriale_TR4.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 914, 'EXECUTED', '8:d72be01e93be23e79621c00b09d33c95', 'sql', null, null, '3.10.2-fix1106', '(TRT2 or TRV4)', null, '4885653702');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250331_123138_ff_matricola_md_TR4', 'abrandolini', 'integration/gsd/tr4sql/f_matricola_md_TR4.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 915, 'EXECUTED', '8:36c533ca1939bbc0adb0ccba4e016142', 'sql', null, null, '3.10.2-fix1106', '(TRT2 or TRV4)', null, '4885653702');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250331_123138_f_matricola_pd_TR4', 'abrandolini', 'integration/gsd/tr4sql/f_matricola_pd_TR4.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 916, 'EXECUTED', '8:a1e65a0cf224519645cb15d0e1788dce', 'sql', null, null, '3.10.2-fix1106', '(TRT2 or TRV4)', null, '4885653702');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_Tr4Tr4ps', 'dmarotta', 'integration/gsd/tr4sql/Tr4Tr4ps.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 917, 'EXECUTED', '8:7e9d29bd9256ab14c09e80ba98fc943a', 'sql', null, null, '3.10.2-fix1106', '(TRT2 or TRV4)', null, '4885653702');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_anadev_ins', 'dmarotta', 'integration/gsd/tr4sql/anadev_ins.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 918, 'EXECUTED', '8:36588a46670f194c08e7022c8aa688d5', 'sql', null, null, '3.10.2-fix1106', '(TRT2 or TRV4)', null, '4885653702');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_anadrp_ins', 'dmarotta', 'integration/gsd/tr4sql/anadrp_ins.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 919, 'EXECUTED', '8:a1baa4d3ff287f9088e174f5693d9cd9', 'sql', null, null, '3.10.2-fix1106', '(TRT2 or TRV4)', null, '4885653702');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250408_094738_anadce_ins', 'abrandolini', 'integration/gsd/tr4sql/anadce_ins.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 920, 'EXECUTED', '8:47e26295add3fd67cde691ead0ea5875', 'sql', null, null, '3.10.2-fix1106', '(TRT2 or TRV4)', null, '4885653702');
