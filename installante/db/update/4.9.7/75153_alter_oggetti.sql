--liquibase formatted sql

--changeset rvattolo:20250521_092727_75153_alter_oggetti-a_latitudine stripComments:false
--preconditions onFail:MARK_RAN
--precondition-sql-check expectedResult:0 SELECT COUNT(*) FROM user_tab_cols WHERE table_name = 'OGGETTI' AND column_name = 'A_LATITUDINE'

alter table OGGETTI
    add A_LATITUDINE NUMBER(12,8)  NULL
/

--changeset rvattolo:20250521_092727_75153_alter_oggetti-a_longitudine stripComments:false
--preconditions onFail:MARK_RAN
--precondition-sql-check expectedResult:0 SELECT COUNT(*) FROM user_tab_cols WHERE table_name = 'OGGETTI' AND column_name = 'A_LONGITUDINE'

alter table OGGETTI
    add A_LONGITUDINE NUMBER(12,8) NULL
