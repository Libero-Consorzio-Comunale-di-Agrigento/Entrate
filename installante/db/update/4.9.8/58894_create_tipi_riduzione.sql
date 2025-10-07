--liquibase formatted sql
--changeset dmarotta:20251002_110718_58894_create_tipi_riduzione stripComments:false
--precondition-sql-check expectedResult:0 SELECT COUNT(*) FROM user_tables WHERE table_name = 'TIPI_RIDUZIONE'

create table TIPI_RIDUZIONE
(
    TIPO_RIDUZIONE               NUMBER(4)              not null,
    TIPO_TRIBUTO                 VARCHAR2(5)            not null,
    DESCRIZIONE                  VARCHAR2(200)          not null,
    DESCRIZIONE_BREVE            VARCHAR2(40)           not null,
    constraint TIPI_RIDUZIONE_PK primary key (TIPO_RIDUZIONE)
)
/
