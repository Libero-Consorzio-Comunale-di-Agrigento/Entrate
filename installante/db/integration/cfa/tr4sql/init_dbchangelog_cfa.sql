--liquibase formatted sql
--changeset dmarotta:20250326_152438_init_dbchangelog_cfa stripComments:false context:CFA
--validCheckSum: 1:any
--preConditions onFail:MARK_RAN
--precondition-sql-check expectedResult:1 select count(1) from USER_OBJECTS where OBJECT_TYPE ='TABLE' and  OBJECT_NAME = 'PRATICHE_TRIBUTO'

insert into databasechangelog ( ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_TR4TRB_dr', 'dmarotta', 'integration/cfa/tr4sql/TR4CFA_dr.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 925, 'EXECUTED', '8:881a8c6383a7d037cdf5f3eb14f33d26', 'sql', null, null, '3.10.2-fix1106', 'CFA', null, '4882029832');

insert into databasechangelog ( ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250331_122738_CFATr4_g', 'abrandolini', 'integration/cfa/tr4sql/CFATr4pg.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 926, 'EXECUTED', '8:c038577c009a7a0ecd0b0e577de702c3', 'sql', null, null, '3.10.2-fix1106', 'CFA', null, '4882029832');

insert into databasechangelog ( ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250326_152438_Tr4CFA_s', 'dmarotta', 'integration/cfa/tr4sql/Tr4CFA_s.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 927, 'EXECUTED', '8:1b3859a4cf2b707274118b2b4b48c2ec', 'sql', null, null, '3.10.2-fix1106', 'CFA', null, '4882029832');

insert into databasechangelog ( ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250331_123138_Tr4_CFA', 'abrandolini', 'integration/cfa/tr4sql/Tr4_CFA.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 928, 'EXECUTED', '8:b8a1823f51ef09451dfb3015a61e342d', 'sql', null, null, '3.10.2-fix1106', 'CFA', null, '4882029832');

insert into databasechangelog ( ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, MD5SUM, DESCRIPTION, COMMENTS, TAG, LIQUIBASE, CONTEXTS, LABELS, DEPLOYMENT_ID)
values ('20250331_120938_Tr4CFA_g', 'abrandolini', 'integration/cfa/cfasql/Tr4CFA_g.sql', TO_TIMESTAMP('2025-05-14 00:00:00.000000', 'YYYY-MM-DD HH24:MI:SS.FF6'), 930, 'EXECUTED', '8:27235984da916eac8af81ff757b98e5c', 'sql', null, null, '3.10.2-fix1106', 'CFA', null, '4882031614');

