--liquibase formatted sql
--changeset dmarotta:20250326_152438_init_dbchangelog_tr4Web stripComments:false
--validCheckSum: 1:any
--preConditions onFail:MARK_RAN
--precondition-sql-check expectedResult:1 select count(1) from USER_OBJECTS where OBJECT_TYPE ='TABLE' and  OBJECT_NAME = 'PRATICHE_TRIBUTO'

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_Tr4Tr4Web_o', 'dmarotta', 'integration/tr4web/tr4sql/Tr4Tr4Web_o.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 928, 'EXECUTED', '8:94cd96e5ba8a452cf37ea49f47073034', 'sql', null, null, '3.10.2-fix1106', null, null, '4816961681');
