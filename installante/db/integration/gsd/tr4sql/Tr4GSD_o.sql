--liquibase formatted sql
--changeset abrandolini:20250331_110438_Tr4GSD_o stripComments:false context:"TRT2 or TRV4"
--validCheckSum: 1:any

-- ============================================================
--   Database name:  TR4
--   DBMS name:      ORACLE Version for SI4
--   Created on:     07/03/2025  09:11
-- ============================================================

-- ============================================================
--   Table: ANAANA
-- ============================================================
create table ANAANA
(
    MATRICOLA              NUMBER(7)              not null,
    COGNOME_NOME           VARCHAR2(60)           null    ,
    FASCIA                 NUMBER(1)              null    ,
    STATO                  NUMBER(2)              null    ,
    DATA_ULT_EVE           NUMBER(8)              null    ,
    SOSPENSIONE            NUMBER(1)              null    ,
    STATO_CIVILE           VARCHAR2(2)            null    ,
    SESSO                  VARCHAR2(1)            null    ,
    NAZIONALITA            VARCHAR2(3)            null    ,
    PATERNITA              VARCHAR2(60)           null    ,
    MATERNITA              VARCHAR2(60)           null    ,
    TITOLO_STUDIO          VARCHAR2(3)            null    ,
    COD_PROF               NUMBER(5)              null    ,
    ATTIVITA_PROF          NUMBER(1)              null    ,
    POSIZIONE_PROF         NUMBER(1)              null    ,
    PENSIONATO             NUMBER(1)              null    ,
    COD_FAM                NUMBER(7)              null    ,
    RAPPORTO_PAR           VARCHAR2(2)            null    ,
    SEQUENZA_PAR           NUMBER(2)              null    ,
    DATA_INIZIO_FAM        NUMBER(8)              null    ,
    DATA_INIZIO_RES        NUMBER(8)              null    ,
    COGNOME_NOME_CN        VARCHAR2(60)           null    ,
    MATRICOLA_CN           NUMBER(7)              null    ,
    ANNO_CENS              NUMBER(4)              null    ,
    SEZIONE_CENS           NUMBER(4)              null    ,
    FOGLIO_CENS            NUMBER(4)              null    ,
    COD_PRO_NAS            NUMBER(3)              null    ,
    COD_COM_NAS            NUMBER(3)              null    ,
    DATA_NAS               NUMBER(8)              null    ,
    COD_PRO_ATTO_NAS       NUMBER(3)              null    ,
    COD_COM_ATTO_NAS       NUMBER(3)              null    ,
    ANNO_ATTO_NAS          NUMBER(4)              null    ,
    ATTO_NAS               NUMBER(4)              null    ,
    PARTE_NAS              NUMBER(1)              null    ,
    SERIE_NAS              VARCHAR2(1)            null    ,
    UFFICIO_NAS            NUMBER(2)              null    ,
    ANNO_ATTO_NAS_TR       NUMBER(4)              null    ,
    ATTO_NAS_TR            NUMBER(4)              null    ,
    PARTE_NAS_TR           NUMBER(1)              null    ,
    SERIE_NAS_TR           VARCHAR2(1)            null    ,
    UFFICIO_NAS_TR         NUMBER(2)              null    ,
    COD_PRO_MAT            NUMBER(3)              null    ,
    COD_COM_MAT            NUMBER(3)              null    ,
    DATA_MAT               NUMBER(8)              null    ,
    ANNO_ATTO_MAT          NUMBER(4)              null    ,
    ATTO_MAT               NUMBER(4)              null    ,
    PARTE_MAT              NUMBER(1)              null    ,
    SERIE_MAT              VARCHAR2(1)            null    ,
    UFFICIO_MAT            NUMBER(2)              null    ,
    ANNO_ATTO_MAT_TR       NUMBER(4)              null    ,
    ATTO_MAT_TR            NUMBER(4)              null    ,
    PARTE_MAT_TR           NUMBER(1)              null    ,
    SERIE_MAT_TR           VARCHAR2(1)            null    ,
    UFFICIO_MAT_TR         NUMBER(2)              null    ,
    DATA_MOR               NUMBER(8)              null    ,
    COD_PRO_MOR            NUMBER(3)              null    ,
    COD_COM_MOR            NUMBER(3)              null    ,
    ANNO_ATTO_MOR          NUMBER(4)              null    ,
    ATTO_MOR               NUMBER(4)              null    ,
    PARTE_MOR              NUMBER(1)              null    ,
    SERIE_MOR              VARCHAR2(1)            null    ,
    UFFICIO_MOR            NUMBER(2)              null    ,
    ANNO_ATTO_MOR_TR       NUMBER(4)              null    ,
    ATTO_MOR_TR            NUMBER(4)              null    ,
    PARTE_MOR_TR           NUMBER(1)              null    ,
    SERIE_MOR_TR           VARCHAR2(5)            null    ,
    UFFICIO_MOR_TR         NUMBER(2)              null    ,
    COD_PRO_VED            NUMBER(3)              null    ,
    COD_COM_VED            NUMBER(3)              null    ,
    DATA_VED               NUMBER(8)              null    ,
    ANNO_ATTO_VED          NUMBER(4)              null    ,
    ATTO_VED               NUMBER(4)              null    ,
    PARTE_VED              NUMBER(1)              null    ,
    SERIE_VED              VARCHAR2(1)            null    ,
    UFFICIO_VED            NUMBER(2)              null    ,
    COD_FISCALE            VARCHAR2(16)           null    ,
    DATA_REG               NUMBER(8)              null    ,
    ANNO_NAS               VARCHAR2(1)            null    ,
    COD_PRO_DIV            NUMBER(3)              null    ,
    COD_COM_DIV            NUMBER(3)              null    ,
    DATA_DIV               NUMBER(8)              null    ,
    ANNO_ATTO_DIV          NUMBER(4)              null    ,
    ATTO_DIV               NUMBER(4)              null    ,
    PARTE_DIV              NUMBER(1)              null    ,
    SERIE_DIV              VARCHAR2(1)            null    ,
    UFFICIO_DIV            NUMBER(2)              null    ,
    MATRICOLA_AIRE         VARCHAR2(12)           null    ,
    CF_CALCOLATO           VARCHAR2(1)            null    ,
    VAL_ESPATRIO           VARCHAR2(1)            null    ,
    COD_PRO_ATTO_MAT       NUMBER(3)              null    ,
    COD_COM_ATTO_MAT       NUMBER(3)              null    ,
    COD_PRO_ATTO_VED       NUMBER(3)              null    ,
    COD_COM_ATTO_VED       NUMBER(3)              null    ,
    COD_PRO_ATTO_MOR       NUMBER(3)              null    ,
    COD_COM_ATTO_MOR       NUMBER(3)              null    ,
    NOTE                   VARCHAR2(2000)         null    ,
    ANNO_MAT               VARCHAR2(1)            null    ,
    MATRICOLA_PD           NUMBER(7)              null    ,
    MATRICOLA_MD           NUMBER(7)              null    ,
    constraint ANAANA_PK primary key (MATRICOLA)
)
/

comment on table ANAANA is 'Anagrafe Individui'
/

-- ============================================================
--   Index: IDX2ANAANA
-- ============================================================
create index IDX2ANAANA on ANAANA (COGNOME_NOME asc)
/

-- ============================================================
--   Index: IDX3ANAANA
-- ============================================================
create index IDX3ANAANA on ANAANA (FASCIA asc, COD_FAM asc, SEQUENZA_PAR asc, DATA_NAS asc)
/

-- ============================================================
--   Index: IDX4ANAANA
-- ============================================================
create index IDX4ANAANA on ANAANA (ANNO_CENS asc, SEZIONE_CENS asc, FOGLIO_CENS asc)
/

-- ============================================================
--   Index: IDX5ANAANA
-- ============================================================
create index IDX5ANAANA on ANAANA (COD_FISCALE asc)
/

-- ============================================================
--   Index: IDX6ANAANA
-- ============================================================
create index IDX6ANAANA on ANAANA (MATRICOLA_AIRE asc)
/

-- ============================================================
--   Table: ANAFAM
-- ============================================================
create table ANAFAM
(
    FASCIA                 NUMBER(1)              not null,
    COD_FAM                NUMBER(7)              not null,
    TIPO_FAM               NUMBER(1)              null    ,
    COD_VIA                NUMBER(4)              null    ,
    NUM_CIV                NUMBER(6)              null    ,
    SUFFISSO               VARCHAR2(3)            null    ,
    INTERNO                NUMBER(2)              null    ,
    VIA_AIRE               VARCHAR2(55)           null    ,
    COD_PRO_AIRE           NUMBER(3)              null    ,
    COD_COM_AIRE           NUMBER(3)              null    ,
    CONVIVENZA             VARCHAR2(60)           null    ,
    INTESTATARIO           VARCHAR2(60)           null    ,
    VIA_RES                VARCHAR2(55)           null    ,
    COD_PRO_RES            NUMBER(3)              null    ,
    COD_COM_RES            NUMBER(3)              null    ,
    SCALA                  VARCHAR2(3)            null    ,
    PIANO                  VARCHAR2(3)            null    ,
    ZIPCODE                VARCHAR2(10)           null    ,
    constraint ANAFAM_PK primary key (FASCIA, COD_FAM)
)
/

comment on table ANAFAM is 'Archivio Famiglie'
/

-- ============================================================
--   Index: IDX2ANAFAM
-- ============================================================
create index IDX2ANAFAM on ANAFAM (INTESTATARIO asc)
/

-- ============================================================
--   Index: IDX3ANAFAM
-- ============================================================
create index IDX3ANAFAM on ANAFAM (CONVIVENZA asc)
/

-- ============================================================
--   Table: ARCVIE
-- ============================================================
create table ARCVIE
(
    COD_VIA                NUMBER(4)              not null,
    DENOM_UFF              VARCHAR2(40)           null    ,
    DENOM_RIC              VARCHAR2(40)           null    ,
    DENOM_ORD              VARCHAR2(40)           null    ,
    INIZIA                 VARCHAR2(40)           null    ,
    TERMINA                VARCHAR2(40)           null    ,
    DATA_ISTITUZIONE       NUMBER(8)              null    ,
    DATA_CESSAZIONE        NUMBER(8)              null    ,
    FLAG_CESSATA           VARCHAR2(1)            null
        constraint ARCVIE_FLAG_CESSATA_CC check (
            FLAG_CESSATA is null or (FLAG_CESSATA in ('S'))),
    NOTE                   VARCHAR2(2000)         null    ,
    constraint ARCVIE_PK primary key (COD_VIA)
)
/

comment on table ARCVIE is 'Archivio Vie'
/

-- ============================================================
--   Index: IDX2ARCVIE
-- ============================================================
create index IDX2ARCVIE on ARCVIE (DENOM_RIC asc)
/

-- ============================================================
--   Table: ANAEVE
-- ============================================================
create table ANAEVE
(
    MATRICOLA              NUMBER(7)              null    ,
    COD_MOV                NUMBER(2)              null    ,
    COD_EVE                NUMBER(2)              null    ,
    DATA_INIZIO            NUMBER(8)              null    ,
    DATA_EVE               NUMBER(8)              null    ,
    COD_PRO_EVE            NUMBER(3)              null    ,
    COD_COM_EVE            NUMBER(3)              null    ,
    ANNO_PRATICA           NUMBER(4)              null    ,
    PRATICA                NUMBER(4)              null    ,
    COD_EVE_PR             NUMBER(2)              null    ,
    COD_FAM                NUMBER(7)              null    ,
    RAPPORTO_PAR           VARCHAR2(2)            null    ,
    COD_VIA                NUMBER(4)              null    ,
    NUM_CIV                NUMBER(6)              null    ,
    SUFFISSO               VARCHAR2(3)            null    ,
    INTERNO                NUMBER(2)              null    ,
    VIA_AIRE               VARCHAR2(55)           null    ,
    COD_PRO_AIRE           NUMBER(3)              null    ,
    COD_COM_AIRE           NUMBER(3)              null    ,
    TITOLO_STUDIO          VARCHAR2(3)            null    ,
    COD_PROF               NUMBER(5)              null    ,
    ATTIVITA_PROF          NUMBER(1)              null    ,
    POSIZIONE_PROF         NUMBER(1)              null    ,
    DATA_REG               NUMBER(8)              null    ,
    DATA_RIC               NUMBER(8)              null    ,
    COD_PRO_RIC            NUMBER(3)              null    ,
    COD_COM_RIC            NUMBER(3)              null    ,
    ANNO_PRATICA_RIC       NUMBER(4)              null    ,
    PRATICA_RIC            NUMBER(6)              null    ,
    COD_VARIAZIONE         VARCHAR2(1)            null    ,
    SCALA                  VARCHAR2(3)            null    ,
    PIANO                  VARCHAR2(3)            null    ,
    ZIPCODE                VARCHAR2(10)           null
)
/

comment on table ANAEVE is 'Archivio Eventi'
/

-- ============================================================
--   Index: IDX1ANAEVE
-- ============================================================
create index IDX1ANAEVE on ANAEVE (MATRICOLA asc, DATA_EVE asc)
/

-- ============================================================
--   Index: IDX2ANAEVE
-- ============================================================
create index IDX2ANAEVE on ANAEVE (ANNO_PRATICA asc, PRATICA asc, MATRICOLA asc, COD_EVE_PR asc, COD_MOV asc)
/

-- ============================================================
--   Index: IDX3ANAEVE
-- ============================================================
create index IDX3ANAEVE on ANAEVE (COD_MOV asc, COD_FAM asc, DATA_EVE asc)
/

-- ============================================================
--   Table: ANADRP
-- ============================================================
create table ANADRP
(
    COD_RP                 VARCHAR2(2)            not null,
    SESSO                  VARCHAR2(1)            not null,
    SEQUENZA               NUMBER(2)              null    ,
    DESCRIZIONE            VARCHAR2(30)           null    ,
    constraint ANADRP_PK primary key (COD_RP, SESSO)
)
/

comment on table ANADRP is 'Dizionario Rapporti di Parentela'
/

-- ============================================================
--   Table: ANADPR
-- ============================================================
create table ANADPR
(
    COD_PR                 NUMBER(5)              not null,
    SESSO                  VARCHAR2(1)            not null,
    DESCRIZIONE            VARCHAR2(30)           null    ,
    constraint ANADPR_PK primary key (COD_PR, SESSO)
)
/

comment on table ANADPR is 'Dizionario Professioni'
/

-- ============================================================
--   Table: ANADST
-- ============================================================
create table ANADST
(
    COD_UT                 NUMBER(2)              not null,
    COD_ST                 NUMBER(4)              not null,
    DESCRIZIONE            VARCHAR2(30)           null    ,
    constraint ANADST_PK primary key (COD_UT, COD_ST)
)
/

comment on table ANADST is 'Dizionario Suddivisioni Territoriali'
/

-- ============================================================
--   Table: ANASTE
-- ============================================================
create table ANASTE
(
    COD_UT                 NUMBER(2)              null    ,
    COD_ST                 NUMBER(4)              null    ,
    COD_VIA                NUMBER(4)              null    ,
    PARI_DISPARI           VARCHAR2(1)            null    ,
    CIVICO_INF             NUMBER(6)              null    ,
    CIVICO_SUP             NUMBER(6)              null    ,
    SUFFISSO_INF           VARCHAR2(3)            null    ,
    SUFFISSO_SUP           VARCHAR2(3)            null
)
/

comment on table ANASTE is 'Archivio Suddivisioni Territoriali'
/

-- ============================================================
--   Index: IDX1ANASTE
-- ============================================================
create index IDX1ANASTE on ANASTE (COD_UT asc, COD_ST asc)
/

-- ============================================================
--   Index: IDX2ANASTE
-- ============================================================
create index IDX2ANASTE on ANASTE (COD_VIA asc, CIVICO_INF asc, CIVICO_SUP asc, PARI_DISPARI asc)
/

-- ============================================================
--   Table: ANACP4
-- ============================================================
create table ANACP4
(
    ANNO_DIC               NUMBER(4)              not null,
    NUMERO_DIC             NUMBER(4)              not null,
    ANNO_PRATICA           NUMBER(4)              null    ,
    PRATICA                NUMBER(4)              null    ,
    DATA_PRATICA           NUMBER(8)              null    ,
    CONTEGGIO              VARCHAR2(1)            null    ,
    DATA_DECORRENZA        NUMBER(8)              null    ,
    TIPO_RICHIESTA         VARCHAR2(1)            null    ,
    COD_PRO_EVE            NUMBER(3)              null    ,
    COD_COM_EVE            NUMBER(3)              null    ,
    RICHIESTA              NUMBER(1)              null    ,
    PROVVEDIMENTO          NUMBER(1)              null    ,
    COD_STATO              NUMBER(3)              null    ,
    DATA_IRREPERIBILITA    NUMBER(8)              null    ,
    DATA_DEFINIZIONE       NUMBER(8)              null    ,
    SOTTOSCRITTO           NUMBER(2)              null    ,
    FAMIGLIA_CONVIVENZA    VARCHAR2(1)            null    ,
    COD_VIA                NUMBER(4)              null    ,
    NUM_CIV                NUMBER(6)              null    ,
    SUFFISSO               VARCHAR2(3)            null    ,
    INTERNO                NUMBER(2)              null    ,
    SCALA                  VARCHAR2(3)            null    ,
    PIANO                  VARCHAR2(3)            null    ,
    DATA_REG               NUMBER(8)              null    ,
    STATO_PRATICA          VARCHAR2(1)            null    ,
    PRESSO                 VARCHAR2(60)           null    ,
    MOTIVO                 VARCHAR2(30)           null    ,
    COD_FAM_PROV           NUMBER(7)              null    ,
    FLAG_INTERO_NUCLEO     VARCHAR2(1)            null    ,
    INDIRIZZO_EMI          VARCHAR2(60)           null    ,
    MATRICOLA_DIC          NUMBER(8)              null    ,
    constraint ANACP4_PK primary key (ANNO_DIC, NUMERO_DIC)
)
/

comment on table ANACP4 is 'Testata Modello APR4 di Cancellazione'
/

-- ============================================================
--   Index: IDX2ANACP4
-- ============================================================
create index IDX2ANACP4 on ANACP4 (ANNO_PRATICA asc, PRATICA asc)
/

-- ============================================================
--   Table: ANACPM
-- ============================================================
create table ANACPM
(
    ANNO_DIC               NUMBER(4)              null    ,
    NUMERO_DIC             NUMBER(4)              null    ,
    NUMERO_ORDINE          NUMBER(2)              null    ,
    MATRICOLA              NUMBER(7)              null    ,
    IST_RP                 VARCHAR2(2)            null    ,
    SESSO                  VARCHAR2(1)            null    ,
    IST_TS                 NUMBER(2)              null    ,
    IST_NP                 NUMBER(2)              null    ,
    ANNULLAMENTO           VARCHAR2(1)            null    ,
    FLAG_SOGGETTO          VARCHAR2(1)            null    ,
    NUOVO_RAPPORTO_PAR     VARCHAR2(2)            null    ,
    NUOVA_SEQUENZA_PAR     NUMBER(2)              null
)
/

comment on table ANACPM is 'ANACPM'
/

-- ============================================================
--   Index: IDX1ANACPM
-- ============================================================
create index IDX1ANACPM on ANACPM (ANNO_DIC asc, NUMERO_DIC asc, MATRICOLA asc)
/

-- ============================================================
--   Table: ANADEV
-- ============================================================
create table ANADEV
(
    COD_EV                 NUMBER(2)              not null,
    DESCRIZIONE            VARCHAR2(30)           null    ,
    SEGNALAZIONE           NUMBER(1)              null    ,
    constraint ANADEV_PK primary key (COD_EV)
)
/

comment on table ANADEV is 'Dizionario Eventi'
/

-- ============================================================
--   Table: ARCPRO
-- ============================================================
create table ARCPRO
(
    COD_PROVINCIA          NUMBER(3)              not null,
    DESCRIZIONE            VARCHAR2(30)           null    ,
    constraint ARCPRO_PK primary key (COD_PROVINCIA)
)
/

comment on table ARCPRO is 'Archivio Provincie'
/

-- ============================================================
--   Table: ANADCE
-- ============================================================
create table ANADCE
(
    ANAGRAFE               VARCHAR2(3)            null    ,
    CODICE                 NUMBER(4)              not null,
    DESCRIZIONE            VARCHAR2(40)           null    ,
    COD_MOV                NUMBER(2)              null    ,
    COD_EVE                NUMBER(2)              null    ,
    TIPO_EVENTO            VARCHAR2(1)            null    ,
    COD_VARIAZIONE         VARCHAR2(1)            null    ,
    FLAG_TPR               VARCHAR2(1)            null    ,
    TIPO_EVENTO_TPR        VARCHAR2(1)            null    ,
    DES_EVENTO_TPR         VARCHAR2(30)           null    ,
    SEQ_EVENTO_TPR         NUMBER(2)              null    ,
    FLAG_ISTAT             VARCHAR2(1)            null    ,
    TIPO_EVENTO_ISTAT      VARCHAR2(1)            null    ,
    FLAG_APR4              VARCHAR2(1)            null    ,
    TIPO_RICHIESTA_APR4    VARCHAR2(1)            null    ,
    RICHIESTA_APR4         NUMBER(1)              null    ,
    PROVVEDIMENTO_APR4     NUMBER(1)              null    ,
    MOTIVO_APR4            VARCHAR2(30)           null    ,
    FLAG_R01               VARCHAR2(1)            null    ,
    FLAG_AIRE01            VARCHAR2(1)            null    ,
    INIZIATIVA_AIRE01      NUMBER(1)              null    ,
    ISCRIZIONE_AIRE01      VARCHAR2(1)            null    ,
    MOTIVO_AIRE01          VARCHAR2(3)            null    ,
    INDIVIDUAZIONE_AIRE01  NUMBER(1)              null    ,
    FLAG_ELE               VARCHAR2(1)            null    ,
    MOTIVO_ELE             NUMBER(2)              null    ,
    MOTIVO_GPO             NUMBER(2)              null    ,
    MOTIVO_PSE             NUMBER(2)              null    ,
    MOTIVO_SCR             NUMBER(2)              null    ,
    SIGLA_VANA             VARCHAR2(20)           null    ,
    DESCRIZIONE_CER        VARCHAR2(255)          null    ,
    DESCRIZIONE_M          VARCHAR2(60)           null    ,
    DESCRIZIONE_F          VARCHAR2(60)           null    ,
    constraint ANADCE_PK primary key (CODICE)
)
/

comment on table ANADCE is 'Dizionario Codici Evento e Relazioni'
/

-- ============================================================
--   Index: IDX2ANADCE
-- ============================================================
create unique index IDX2ANADCE on ANADCE (ANAGRAFE asc, COD_MOV asc, COD_EVE asc, TIPO_EVENTO asc, COD_VARIAZIONE asc)
/
