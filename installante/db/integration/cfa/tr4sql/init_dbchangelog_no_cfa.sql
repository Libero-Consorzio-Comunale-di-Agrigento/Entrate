--liquibase formatted sql
--changeset dmarotta:20250326_152438_init_dbchangelog_no_cfa stripComments:false context:!CFA
--validCheckSum: 1:any
--preConditions onFail:MARK_RAN
--precondition-sql-check expectedResult:1 select count(1) from USER_OBJECTS where OBJECT_TYPE ='TABLE' and  OBJECT_NAME = 'PRATICHE_TRIBUTO'

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250331_110638_Tr4CFA_o', 'abrandolini', 'integration/cfa/tr4sql/Tr4CFA_o.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 921, 'EXECUTED', '8:ae0a9f61010a9aa0631edd5a089054e5', 'sql', null, null, '3.10.2-fix1106', '!CFA', null, '4885656808');
