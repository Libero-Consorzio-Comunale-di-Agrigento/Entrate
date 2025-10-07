--liquibase formatted sql
--changeset dmarotta:20250326_152438_init_dbchangelog_no_trb stripComments:false context:"TRG2 or TRV4"
--validCheckSum: 1:any
--preConditions onFail:MARK_RAN
--precondition-sql-check expectedResult:1 select count(1) from USER_OBJECTS where OBJECT_TYPE ='TABLE' and  OBJECT_NAME = 'PRATICHE_TRIBUTO'

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250331_110538_Tr4TRB_o', 'abrandolini', 'integration/trb/tr4sql/Tr4TRB_o.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 922, 'EXECUTED', '8:98e4b7da905d263026e1888e7f2f1ecb', 'sql', null, null, '3.10.2-fix1106', '(TRG2 or TRV4)', null, '4885657243');
