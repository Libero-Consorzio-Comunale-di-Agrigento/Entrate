--liquibase formatted sql

--changeset dmarotta:20250326_152438_init_dbchangelog_so4 stripComments:false
--validCheckSum: 1:any
--preConditions onFail:MARK_RAN
--precondition-sql-check expectedResult:1 select count(1) from USER_OBJECTS where OBJECT_TYPE ='TABLE' and  OBJECT_NAME = 'PRATICHE_TRIBUTO'

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_Tr4_So4_o', 'dmarotta', 'integration/so4/tr4sql/Tr4_So4_o.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 6, 'EXECUTED', '8:4b840400e9274502bde425faf4c612d3', 'sql', null, null, '3.10.2-fix1106', null, null, '4816620871');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_So4_v_ott_ins', 'dmarotta', 'integration/so4/tr4sql/So4_v_ott_ins.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 7, 'EXECUTED', '8:05824e1301833e562e8ec8d7d366bebf', 'sql', null, null, '3.10.2-fix1106', null, null, '4816620871');

--changeset dmarotta:20250326_152438_init_dbchangelog_so4_fix_001 stripComments:false
--validCheckSum: 1:any
--preConditions onFail:MARK_RAN
--precondition-sql-check expectedResult:1 select count(1) from USER_OBJECTS where OBJECT_TYPE ='TABLE' and  OBJECT_NAME = 'PRATICHE_TRIBUTO'

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_So4_v_amm_ins', 'dmarotta', 'integration/so4/tr4sql/So4_v_amm_ins.sql', TO_TIMESTAMP('2025-07-01 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 17, 'EXECUTED', '8:48f3fb8ecda0dc823d09e03731df7303', 'sql', null, null, '3.10.2-fix1106', null, null, '1355670050');
