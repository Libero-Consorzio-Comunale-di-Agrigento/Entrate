--liquibase formatted sql
--changeset abrandolini:20250331_110538_Tr4TRB_o stripComments:false context:"TRG2 or TRV4"
--validCheckSum: 1:any

-- ============================================================
--   Database name:  TR4_TRB
--   DBMS name:      ORACLE Version for SI4
--   Created on:     03/12/2008  15.36
-- ============================================================

-- ============================================================
--   Table: N01
-- ============================================================
create table N01
(
    NUMERO             NUMBER(7)              not null,
    constraint N01_PK primary key (NUMERO)
)
/

comment on table N01 is 'Progressivo annuale'
/

-- ============================================================
--   Table: ANANRE
-- ============================================================
create table ANANRE
(
    MATRICOLA          NUMBER(7)              not null,
    COGNOME_NOME       VARCHAR2(60)           not null,
    DENOMINAZIONE_VIA  VARCHAR2(60)           null    ,
    NUM_CIV            NUMBER(6)              null    ,
    SUFFISSO           VARCHAR2(3)            null    ,
    INTERNO            NUMBER(2)              null    ,
    PROVINCIA          NUMBER(3)              null    ,
    COMUNE             NUMBER(3)              null    ,
    CAP                NUMBER(5)              null    ,
    COD_PROF           NUMBER(5)              null    ,
    SESSO              VARCHAR2(1)            null    ,
    DATA_NASCITA       NUMBER(8)              null    ,
    PROVINCIA_NASCITA  NUMBER(3)              null    ,
    COMUNE_NASCITA     NUMBER(3)              null    ,
    TIPO               NUMBER(1)              null    ,
    DATA_ULT_AGG       NUMBER(8)              null    ,
    COD_FISCALE        VARCHAR2(16)           null    ,
    PARTITA_IVA        VARCHAR2(11)           null    ,
    COD_FAM            NUMBER(7)              null    ,
    RAPPRESENTANTE     VARCHAR2(40)           null    ,
    INDIR_RAPPR        VARCHAR2(40)           null    ,
    COD_PRO_RAPPR      NUMBER(3)              null    ,
    COD_COM_RAPPR      NUMBER(3)              null    ,
    CARICA             VARCHAR2(40)           null    ,
    COD_FISCALE_RAPPR  VARCHAR2(16)           null    ,
    NOTE_1             VARCHAR2(60)           null    ,
    NOTE_2             VARCHAR2(60)           null    ,
    NOTE_3             VARCHAR2(60)           null    ,
    ESENZIONE          VARCHAR2(1)            null    ,
    GRUPPO_UTENTE      VARCHAR2(1)            null    ,
    CF_CALCOLATO       VARCHAR2(1)            null    ,
    constraint ANANRE_PK primary key (MATRICOLA)
)
/

comment on table ANANRE is 'Anagrafe non residenti'
/

-- ============================================================
--   Index: IDX2ANANRE
-- ============================================================
create index IDX2ANANRE on ANANRE (COD_FISCALE asc)
/

-- ============================================================
--   Index: IDX3ANANRE
-- ============================================================
create index IDX3ANANRE on ANANRE (PARTITA_IVA asc)
/

-- ============================================================
--   Index: IDX4ANANRE
-- ============================================================
create index IDX4ANANRE on ANANRE (COGNOME_NOME asc)
/
