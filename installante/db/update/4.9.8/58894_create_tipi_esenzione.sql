--liquibase formatted sql
--changeset dmarotta:20251002_110931_58894_create_tipi_esenzione stripComments:false
--precondition-sql-check expectedResult:0 SELECT COUNT(*) FROM user_tables WHERE table_name = 'TIPI_ESENZIONE'

create table TIPI_ESENZIONE
(
    TIPO_ESENZIONE               NUMBER(4)              not null,
    TIPO_TRIBUTO                 VARCHAR2(5)            not null,
    DESCRIZIONE                  VARCHAR2(200)          not null,
    DESCRIZIONE_BREVE            VARCHAR2(40)           not null,
    constraint TIPI_ESENZIONE_PK primary key (TIPO_ESENZIONE)
)
/
