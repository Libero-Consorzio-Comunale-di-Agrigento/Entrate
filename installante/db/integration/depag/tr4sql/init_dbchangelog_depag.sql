--liquibase formatted sql
--changeset dmarotta:20250326_152438_init_dbchangelog_depag stripComments:false context:DEPAG
--validCheckSum: 1:any
--preConditions onFail:MARK_RAN
--precondition-sql-check expectedResult:1 select count(1) from USER_OBJECTS where OBJECT_TYPE ='TABLE' and  OBJECT_NAME = 'PRATICHE_TRIBUTO'

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_Tr4Depag_s', 'dmarotta', 'integration/depag/tr4sql/Tr4Depag_s.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 938, 'EXECUTED', '8:7cf74f615070d16cc05f9d2329689bc7', 'sql', null, null, '3.10.2-fix1106', 'DEPAG', null, '4882033687');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_Tr4Depag_g', 'dmarotta', 'integration/depag/depagsql/Tr4Depag_g.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 940, 'EXECUTED', '8:6dbe886841444fd5baeb482b3b774fe8', 'sql', null, null, '3.10.2-fix1106', 'DEPAG', null, '4882035255');
