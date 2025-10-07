--liquibase formatted sql
--changeset dmarotta:20250612_121115_81533_alter_tipi_carica stripComments:false
--preconditions onFail:MARK_RAN
--precondition-sql-check expectedResult:0 SELECT COUNT(*) FROM user_tab_cols WHERE table_name = 'TIPI_CARICA' AND column_name = 'FLAG_ONLINE'

alter table TIPI_CARICA
    add     FLAG_ONLINE   VARCHAR2(1)            null
/

