--liquibase formatted sql
--changeset dmarotta:20250521_125950_init_dbchangelog_dage_v4 stripComments:false context:"TRV4"
--validCheckSum: 1:any
--preConditions onFail:MARK_RAN
--precondition-sql-check expectedResult:1 select count(1) from USER_OBJECTS where OBJECT_TYPE ='TABLE' and  OBJECT_NAME = 'PRATICHE_TRIBUTO'

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_DB_V4', 'dmarotta', 'install-data/sql/configurazione/datigenerali/DB_V4.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 895, 'EXECUTED', '8:4eb8496024f35dbf7777444843a8cecc', 'sql', null, null, '3.10.2-fix1106', 'TRV2', null, '7726276690');


