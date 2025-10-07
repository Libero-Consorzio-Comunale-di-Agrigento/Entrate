--liquibase formatted sql
--changeset dmarotta:20250326_152438_init_dbchangelog_ad4 stripComments:false
--validCheckSum: 1:any
--preConditions onFail:MARK_RAN
--precondition-sql-check expectedResult:1 select count(1) from USER_OBJECTS where OBJECT_TYPE ='TABLE' and  OBJECT_NAME = 'PRATICHE_TRIBUTO'

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_Tr4ad4_s_all', 'dmarotta', 'integration/ad4/tr4sql/Tr4DIAC_ins.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 1, 'EXECUTED', '8:d82b4e756563d336027ea933f382ca70', 'sql', null, null, '3.10.2-fix1106', null, null, '4816617713');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_Tr4ad4_s_all', 'dmarotta', 'integration/ad4/tr4sql/Tr4ad4_s_all.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 2, 'EXECUTED', '8:d8d3435d03b6a1a02883fcdfd106533e', 'sql', null, null, '3.10.2-fix1106', null, null, '4816617713');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_Ad4BS_g', 'dmarotta', 'integration/ad4/ad4sql/Ad4_g.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 4, 'EXECUTED', '8:36ab21d7e1b41acb12cccc1f4f420956', 'sql', null, null, '3.10.2-fix1106', null, null, '4816619782');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_Ad4Tr4_gx', 'dmarotta', 'integration/ad4/ad4sql/Ad4Tr4_gx.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 5, 'EXECUTED', '8:6e241da0511041af4238ad34dc650400', 'sql', null, null, '3.10.2-fix1106', null, null, '4816619782');

insert into databasechangelog (ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250512_172006_Tr4DIAC_ins', 'dmarotta', 'integration/ad4/ad4sql/Tr4DIAC_ins.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 14, 'EXECUTED', '8:a1e65a0cf224519645cb15d0e1788dce', 'sql', null, null, '3.10.2-fix1106', null, null, '7063359734');
