--liquibase formatted sql
--changeset abrandolini:20250331_110638_Tr4CFA_o stripComments:false context:!CFA
--validCheckSum: 1:any

-- ============================================================
--   Database name:  TR4
--   DBMS name:      ORACLE Version for SI4
--   Created on:     26/10/2021  15.57
-- ============================================================

-- ============================================================
--   Table: CFA_ACC_TRIBUTI
-- ============================================================
create table CFA_ACC_TRIBUTI
(
    ANNO_ACC               NUMBER(4)              null    ,
    NUMERO_ACC             NUMBER(5)              null    ,
    DESCRIZIONE_ACC        VARCHAR2(140)          null    ,
    ESERCIZIO              NUMBER(4)              null    ,
    ES                     VARCHAR2(1)            null    ,
    CAPITOLO               NUMBER(16)             null    ,
    ARTICOLO               NUMBER(2)              null    ,
    DESCRIZIONE_CAP        VARCHAR2(140)          null    ,
    DATA_ACC               DATE                   null    ,
    IMPORTO_ATTUALE        NUMBER                 null    ,
    ORDINATIVI             NUMBER                 null    ,
    DISPONIBILITA          NUMBER                 null    ,
    CODICE_LIVELLO_5       NUMBER(10)             null    ,
    DESCRIZIONE_LIVELLO_5  VARCHAR2(4000)         null
)
/

comment on table CFA_ACC_TRIBUTI is 'CFA_ACC_TRIBUTI'
/

-- ============================================================
--   Table: CFA_PROVVISORI_ENTRATA_TRIBUTI
-- ============================================================
create table CFA_PROVVISORI_ENTRATA_TRIBUTI
(
    ESERCIZIO              NUMBER(4)              null    ,
    NUMERO_PROVVISORIO     VARCHAR2(10)           null    ,
    DATA_PROVVISORIO       DATE                   null    ,
    DESCRIZIONE            VARCHAR2(140)          null    ,
    IMPORTO                NUMBER(14,2)           null    ,
    DES_BEN                VARCHAR2(50)           null    ,
    ID_FLUSSO_TESORERIA    VARCHAR2(500)          null    ,
    NOTE                   VARCHAR2(4000)         null
)
/

comment on table CFA_PROVVISORI_ENTRATA_TRIBUTI is 'CFA_PROVVISORI_ENTRATA_TRIBUTI'
/
