--liquibase formatted sql
--changeset dmarotta:20250925_163659_82733_modifiche_db stripComments:false  endDelimiter:/

create table BONUS_SOCIALI_CONTRIBUENTE
(
    BONUS_SOCIALE_CONTRIBUENTE     NUMBER(10)             not null,
    COD_FISCALE                    VARCHAR2(16)           null    ,
    TIPO_TRIBUTO                   VARCHAR2(5)            null    ,
    ANNO                           NUMBER(4)              null    ,
    constraint BONUS_SOCIALI_CONTRIBUENTE_PK primary key (BONUS_SOCIALE_CONTRIBUENTE)
)
/

alter table OGGETTI_IMPOSTA
    add     BONUS_SOCIALE                  NUMBER(15,2)           null
/

alter table RUOLI_CONTRIBUENTE
    add     BONUS_SOCIALE                  NUMBER(15,2)           null
/

alter table RATE_IMPOSTA
    add     BONUS_SOCIALE                  NUMBER(15,2)           null
/

create unique index BONUS_SOCIALI_CONTRIBUENTE_AK on BONUS_SOCIALI_CONTRIBUENTE (COD_FISCALE asc, TIPO_TRIBUTO asc, ANNO asc)
/
