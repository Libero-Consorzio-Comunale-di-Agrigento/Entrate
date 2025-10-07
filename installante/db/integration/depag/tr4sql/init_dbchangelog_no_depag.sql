--liquibase formatted sql
--changeset dmarotta:20250326_152438_init_dbchangelog_no_depag stripComments:false context:!DEPAG
--validCheckSum: 1:any
--preConditions onFail:MARK_RAN
--precondition-sql-check expectedResult:1 select count(1) from USER_OBJECTS where OBJECT_TYPE ='TABLE' and  OBJECT_NAME = 'PRATICHE_TRIBUTO'

insert into databasechangelog ( ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_PAGONLINE_TR4_NULL', 'dmarotta', 'integration/depag/tr4sql/PAGONLINE_TR4_NULL.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 923, 'EXECUTED', '8:cd73f4d5346b51bfe5301b8446ced093', 'sql', null, null, '3.10.2-fix1106', '!DEPAG', null, '4885657655');
