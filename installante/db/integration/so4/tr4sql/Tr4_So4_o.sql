--liquibase formatted sql
--changeset dmarotta:20250326_152438_Tr4_So4_o stripComments:false
--validCheckSum: 1:any

-- ============================================================
--   Database name:  TR4                                       
--   DBMS name:      ORACLE Version for SI4                    
--   Created on:     08/11/2017  15.15                         
-- ============================================================

-- ============================================================
--   Table: AS4_V_TIPI_SOGGETTO                                
-- ============================================================
create table AS4_V_TIPI_SOGGETTO
(
    TIPO_SOGGETTO            VARCHAR2(1)            not null,
    DESCRIZIONE              VARCHAR2(40)           not null,
    constraint AS4_V_TIPI_SOGGETTO_PK primary key (TIPO_SOGGETTO)
)
/

comment on table AS4_V_TIPI_SOGGETTO is 'AS4_V_TIPI_SOGGETTO'
/

-- ============================================================
--   Table: AS4_V_SOGGETTI_CORRENTI                            
-- ============================================================
create table AS4_V_SOGGETTI_CORRENTI
(
    NI                       NUMBER(8)              not null,
    AL                       DATE                   null    ,
    CAP_DOM                  VARCHAR2(5)            null    ,
    CAP_RES                  VARCHAR2(5)            null    ,
    CITTADINANZA             VARCHAR2(3)            null    ,
    CODICE_FISCALE           VARCHAR2(16)           null    ,
    CODICE_FISCALE_ESTERO    VARCHAR2(40)           null    ,
    COGNOME                  VARCHAR2(240)          not null,
    COMPETENZA               VARCHAR2(8)            null    ,
    COMPETENZA_ESCLUSIVA     VARCHAR2(1)            null    ,
    COMUNE_DOM               NUMBER(3)              null    ,
    COMUNE_NAS               NUMBER(3)              null    ,
    COMUNE_RES               NUMBER(3)              null    ,
    DAL                      DATE                   null    ,
    DATA_AGG                 DATE                   null    ,
    DATA_NAS                 DATE                   null    ,
    DENOMINAZIONE            VARCHAR2(240)          null    ,
    FAX_DOM                  VARCHAR2(14)           null    ,
    FAX_RES                  VARCHAR2(14)           null    ,
    INDIRIZZO_DOM            VARCHAR2(40)           null    ,
    INDIRIZZO_RES            VARCHAR2(40)           null    ,
    INDIRIZZO_WEB            VARCHAR2(2000)         null    ,
    LUOGO_NAS                VARCHAR2(30)           null    ,
    NOME                     VARCHAR2(40)           null    ,
    NOTE                     VARCHAR2(4000)         null    ,
    PARTITA_IVA              VARCHAR2(11)           null    ,
    PRESSO                   VARCHAR2(40)           null    ,
    PROVINCIA_DOM            NUMBER(3)              null    ,
    PROVINCIA_NAS            NUMBER(3)              null    ,
    PROVINCIA_RES            NUMBER(3)              null    ,
    SESSO                    VARCHAR2(1)            null    ,
    STATO_DOM                NUMBER(3)              null    ,
    STATO_NAS                NUMBER(3)              null    ,
    STATO_RES                NUMBER(3)              null    ,
    TEL_DOM                  VARCHAR2(14)           null    ,
    TEL_RES                  VARCHAR2(14)           null    ,
    TIPO_SOGGETTO            VARCHAR2(1)            null    ,
    UTENTE                   VARCHAR2(8)            null    ,
    UTENTE_AGG               VARCHAR2(8)            null    ,
    constraint AS4_V_SOGGETTI_CORRENTI_PK primary key (NI)
)
/

comment on table AS4_V_SOGGETTI_CORRENTI is 'AS4_V_SOGGETTI_CORRENTI'
/

-- ============================================================
--   Table: SO4_V_AMMINISTRAZIONI                              
-- ============================================================
create table SO4_V_AMMINISTRAZIONI
(
    CODICE                   VARCHAR2(50)           not null,
    DATA_ISTITUZIONE         DATE                   null    ,
    DATA_SOPPRESSIONE        DATE                   null    ,
    ENTE                     NUMBER(1)              not null,
    ID_SOGGETTO              NUMBER(8)              not null,
    constraint SO4_V_AMMINISTRAZIONI_PK primary key (CODICE)
)
/

comment on table SO4_V_AMMINISTRAZIONI is 'SO4_V_AMMINISTRAZIONI'
/

-- ============================================================
--   Table: SO4_V_OTTICHE                                      
-- ============================================================
create table SO4_V_OTTICHE
(
    CODICE                   VARCHAR2(18)           not null,
    AMMINISTRAZIONE          VARCHAR2(50)           not null,
    DESCRIZIONE              VARCHAR2(120)          null    ,
    GESTIONE_REVISIONI       NUMBER(1)              not null,
    ISTITUZIONALE            NUMBER(1)              not null,
    NOTE                     VARCHAR2(2000)         null    ,
    constraint SO4_V_OTTICHE_PK primary key (CODICE)
)
/

comment on table SO4_V_OTTICHE is 'SO4_V_OTTICHE'
/

-- ============================================================
--   Table: SO4_V_COMPONENTI                                   
-- ============================================================
create table SO4_V_COMPONENTI
(
    ID_COMPONENTE            NUMBER(8)              not null,
    AL                       DATE                   null    ,
    CI_SOGGETTO_GP4          NUMBER(8)              null    ,
    DAL                      DATE                   not null,
    NOMINATIVO_SOGGETTO      VARCHAR2(4000)         null    ,
    OTTICA                   VARCHAR2(18)           not null,
    PROGR_UNITA              NUMBER(8)              not null,
    ID_SOGGETTO              NUMBER(8)              not null,
    STATO                    VARCHAR2(1)            null    ,
    constraint SO4_V_COMPONENTI_PK primary key (ID_COMPONENTE)
)
/

comment on table SO4_V_COMPONENTI is 'SO4_V_COMPONENTI'
/

-- ============================================================
--   Table: SO4_V_COMPONENTI_PUBB                              
-- ============================================================
create table SO4_V_COMPONENTI_PUBB
(
    ID_COMPONENTE            NUMBER(8)              not null,
    AL                       DATE                   null    ,
    CI_SOGGETTO_GP4          NUMBER(8)              null    ,
    DAL                      DATE                   not null,
    NOMINATIVO_SOGGETTO      VARCHAR2(4000)         null    ,
    OTTICA                   VARCHAR2(18)           not null,
    PROGR_UNITA              NUMBER(8)              not null,
    ID_SOGGETTO              NUMBER(8)              not null,
    STATO                    VARCHAR2(1)            null    ,
    constraint SO4_V_COMPONENTI_PUBB_PK primary key (ID_COMPONENTE)
)
/

comment on table SO4_V_COMPONENTI_PUBB is 'SO4_V_COMPONENTI_PUBB'
/

-- ============================================================
--   Table: SO4_V_SUDDIVISIONI_STRUTTURA                       
-- ============================================================
create table SO4_V_SUDDIVISIONI_STRUTTURA
(
    ID_SUDDIVISIONE          NUMBER(8)              not null,
    ABBREVIAZIONE            VARCHAR2(20)           null    ,
    CODICE                   VARCHAR2(8)            not null,
    DESCRIZIONE              VARCHAR2(60)           not null,
    ORDINAMENTO              NUMBER(2)              null    ,
    OTTICA                   VARCHAR2(18)           not null,
    constraint SO4_V_SUDDIVISIONI_STRUTTUR_PK primary key (ID_SUDDIVISIONE)
)
/

comment on table SO4_V_SUDDIVISIONI_STRUTTURA is 'SO4_V_SUDDIVISIONI_STRUTTURA'
/

-- ============================================================
--   Table: AS4_V_SOGGETTI                                     
-- ============================================================
create table AS4_V_SOGGETTI
(
    NI                       NUMBER(8)              not null,
    DAL                      DATE                   not null,
    AL                       DATE                   null    ,
    CAP_DOM                  VARCHAR2(5)            null    ,
    CAP_RES                  VARCHAR2(5)            null    ,
    CITTADINANZA             VARCHAR2(3)            null    ,
    CODICE_FISCALE           VARCHAR2(16)           null    ,
    CODICE_FISCALE_ESTERO    VARCHAR2(40)           null    ,
    COGNOME                  VARCHAR2(240)          not null,
    COMPETENZA               VARCHAR2(8)            null    ,
    COMPETENZA_ESCLUSIVA     VARCHAR2(1)            null    ,
    COMUNE_DOM               NUMBER(3)              null    ,
    COMUNE_NAS               NUMBER(3)              null    ,
    COMUNE_RES               NUMBER(3)              null    ,
    DATA_AGG                 DATE                   null    ,
    DATA_NAS                 DATE                   null    ,
    DENOMINAZIONE            VARCHAR2(240)          null    ,
    FAX_DOM                  VARCHAR2(14)           null    ,
    FAX_RES                  VARCHAR2(14)           null    ,
    INDIRIZZO_DOM            VARCHAR2(40)           null    ,
    INDIRIZZO_RES            VARCHAR2(40)           null    ,
    INDIRIZZO_WEB            VARCHAR2(2000)         null    ,
    LUOGO_NAS                VARCHAR2(30)           null    ,
    NOME                     VARCHAR2(40)           null    ,
    NOTE                     VARCHAR2(4000)         null    ,
    PARTITA_IVA              VARCHAR2(11)           null    ,
    PRESSO                   VARCHAR2(40)           null    ,
    PROVINCIA_DOM            NUMBER(3)              null    ,
    PROVINCIA_NAS            NUMBER(3)              null    ,
    PROVINCIA_RES            NUMBER(3)              null    ,
    SESSO                    VARCHAR2(1)            null    ,
    STATO_DOM                NUMBER(3)              null    ,
    STATO_NAS                NUMBER(3)              null    ,
    STATO_RES                NUMBER(3)              null    ,
    TEL_DOM                  VARCHAR2(14)           null    ,
    TEL_RES                  VARCHAR2(14)           null    ,
    TIPO_SOGGETTO            VARCHAR2(1)            null    ,
    UTENTE                   VARCHAR2(8)            null    ,
    UTENTE_AGG               VARCHAR2(8)            null    ,
    constraint AS4_V_SOGGETTI_PK primary key (NI, DAL)
)
/

comment on table AS4_V_SOGGETTI is 'AS4_V_SOGGETTI'
/

-- ============================================================
--   Table: SO4_V_AOO                                          
-- ============================================================
create table SO4_V_AOO
(
    PROGR_AOO                NUMBER(8)              not null,
    DAL                      DATE                   not null,
    ABBREVIAZIONE            VARCHAR2(20)           null    ,
    AL                       DATE                   null    ,
    AMMINISTRAZIONE          VARCHAR2(50)           not null,
    CAP                      VARCHAR2(5)            null    ,
    CODICE                   VARCHAR2(50)           not null,
    COMUNE                   NUMBER(3)              null    ,
    DESCRIZIONE              VARCHAR2(240)          not null,
    FAX                      VARCHAR2(14)           null    ,
    INDIRIZZO                VARCHAR2(120)          null    ,
    PROVINCIA                NUMBER(3)              null    ,
    TELEFONO                 VARCHAR2(14)           null    ,
    constraint SO4_V_AOO_PK primary key (PROGR_AOO, DAL)
)
/

comment on table SO4_V_AOO is 'SO4_V_AOO'
/

-- ============================================================
--   Table: SO4_V_ATTR_COMPONENTE                              
-- ============================================================
create table SO4_V_ATTR_COMPONENTE
(
    ID_ATTR_COMPONENTE       NUMBER(8)              not null,
    AL                       DATE                   null    ,
    ASSEGNAZIONE_PREVALENTE  VARCHAR2(40)           null    ,
    CODICE_INCARICO          VARCHAR2(8)            null    ,
    ID_COMPONENTE            NUMBER(8)              not null,
    DAL                      DATE                   not null,
    DESCRIZIONE_INCARICO     VARCHAR2(4000)         null    ,
    E_MAIL                   VARCHAR2(40)           null    ,
    FAX                      VARCHAR2(20)           null    ,
    GRADAZIONE               VARCHAR2(2)            null    ,
    ORDINAMENTO              NUMBER(10)             null    ,
    PERCENTUALE_IMPIEGO      NUMBER(19,2)           null    ,
    SE_RESPONSABILE          NUMBER(1)              null    ,
    TELEFONO                 VARCHAR2(20)           null    ,
    TIPO_ASSEGNAZIONE        VARCHAR2(1)            null    ,
    constraint SO4_V_ATTR_COMPONENTE_PK primary key (ID_ATTR_COMPONENTE)
)
/

comment on table SO4_V_ATTR_COMPONENTE is 'SO4_V_ATTR_COMPONENTE'
/

-- ============================================================
--   Table: SO4_V_ATTR_COMPONENTE_PUBB                         
-- ============================================================
create table SO4_V_ATTR_COMPONENTE_PUBB
(
    ID_ATTR_COMPONENTE       NUMBER(8)              not null,
    AL                       DATE                   null    ,
    ASSEGNAZIONE_PREVALENTE  VARCHAR2(40)           null    ,
    CODICE_INCARICO          VARCHAR2(8)            null    ,
    ID_COMPONENTE            NUMBER(8)              not null,
    DAL                      DATE                   not null,
    DESCRIZIONE_INCARICO     VARCHAR2(4000)         null    ,
    E_MAIL                   VARCHAR2(40)           null    ,
    FAX                      VARCHAR2(20)           null    ,
    GRADAZIONE               VARCHAR2(2)            null    ,
    ORDINAMENTO              NUMBER(10)             null    ,
    PERCENTUALE_IMPIEGO      NUMBER(19,2)           null    ,
    SE_RESPONSABILE          NUMBER(1)              null    ,
    TELEFONO                 VARCHAR2(20)           null    ,
    TIPO_ASSEGNAZIONE        VARCHAR2(1)            null    ,
    constraint SO4_V_ATTR_COMPONENTE_PUBB_PK primary key (ID_ATTR_COMPONENTE)
)
/

comment on table SO4_V_ATTR_COMPONENTE_PUBB is 'SO4_V_ATTR_COMPONENTE_PUBB'
/

-- ============================================================
--   Table: SO4_V_RUOLI_COMPONENTE                             
-- ============================================================
create table SO4_V_RUOLI_COMPONENTE
(
    ID_RUOLO_COMPONENTE      NUMBER(8)              not null,
    AL                       DATE                   null    ,
    ID_COMPONENTE            NUMBER(8)              not null,
    DAL                      DATE                   not null,
    RUOLO                    VARCHAR2(8)            not null,
    constraint SO4_V_RUOLI_COMPONENTE_PK primary key (ID_RUOLO_COMPONENTE)
)
/

comment on table SO4_V_RUOLI_COMPONENTE is 'SO4_V_RUOLI_COMPONENTE'
/

-- ============================================================
--   Table: SO4_V_RUOLI_COMPONENTE_PUBB                        
-- ============================================================
create table SO4_V_RUOLI_COMPONENTE_PUBB
(
    ID_RUOLO_COMPONENTE      NUMBER(8)              not null,
    AL                       DATE                   null    ,
    ID_COMPONENTE            NUMBER(8)              not null,
    DAL                      DATE                   not null,
    RUOLO                    VARCHAR2(8)            not null,
    constraint SO4_V_RUOLI_COMPONENTE_PUBB_PK primary key (ID_RUOLO_COMPONENTE)
)
/

comment on table SO4_V_RUOLI_COMPONENTE_PUBB is 'SO4_V_RUOLI_COMPONENTE_PUBB'
/

-- ============================================================
--   Table: SO4_V_UNITA_ORGANIZZATIVE                          
-- ============================================================
create table SO4_V_UNITA_ORGANIZZATIVE
(
    PROGR                    NUMBER(8)              not null,
    DAL                      DATE                   not null,
    OTTICA                   VARCHAR2(18)           not null,
    AL                       DATE                   null    ,
    AMMINISTRAZIONE          VARCHAR2(50)           not null,
    ASSEGNAZIONE_COMPONENTI  NUMBER(1)              null    ,
    CENTRO_COSTO             VARCHAR2(16)           null    ,
    CENTRO_RESPONSABILITA    NUMBER(1)              null    ,
    CODICE                   VARCHAR2(50)           not null,
    CODICE_AOO               VARCHAR2(4000)         null    ,
    DESCRIZIONE              VARCHAR2(140)          not null,
    ETICHETTA                VARCHAR2(30)           null    ,
    PROGR_PADRE              NUMBER(19)             null    ,
    REVISIONE                NUMBER(8)              null    ,
    REVISIONE_CESSAZIONE     NUMBER(8)              null    ,
    SE_GIURIDICO             NUMBER(1)              null    ,
    SEQUENZA                 NUMBER(6)              null    ,
    ID_SUDDIVISIONE          NUMBER(8)              null    ,
    TAG_MAIL                 VARCHAR2(4000)         null    ,
    TIPO_UNITA               VARCHAR2(1)            null    ,
    TIPOLOGIA                VARCHAR2(2)            null    ,
    UTENTE_AD4               VARCHAR2(8)            not null,
    constraint SO4_V_UNITA_ORGANIZZATIVE_PK primary key (PROGR, DAL, OTTICA)
)
/

comment on table SO4_V_UNITA_ORGANIZZATIVE is 'SO4_V_UNITA_ORGANIZZATIVE'
/

-- ============================================================
--   Table: SO4_V_UNITA_ORGANIZZATIVE_PUBB                     
-- ============================================================
create table SO4_V_UNITA_ORGANIZZATIVE_PUBB
(
    PROGR                    NUMBER(8)              not null,
    DAL                      DATE                   not null,
    OTTICA                   VARCHAR2(18)           not null,
    AL                       DATE                   null    ,
    AMMINISTRAZIONE          VARCHAR2(50)           not null,
    ASSEGNAZIONE_COMPONENTI  NUMBER(1)              null    ,
    CENTRO_COSTO             VARCHAR2(16)           null    ,
    CENTRO_RESPONSABILITA    NUMBER(1)              null    ,
    CODICE                   VARCHAR2(50)           not null,
    CODICE_AOO               VARCHAR2(4000)         null    ,
    DESCRIZIONE              VARCHAR2(240)          not null,
    ETICHETTA                VARCHAR2(30)           null    ,
    PROGR_PADRE              NUMBER(8)              null    ,
    REVISIONE                NUMBER(8)              null    ,
    REVISIONE_CESSAZIONE     NUMBER(8)              null    ,
    SE_GIURIDICO             NUMBER(1)              null    ,
    SEQUENZA                 NUMBER(6)              null    ,
    ID_SUDDIVISIONE          NUMBER(8)              null    ,
    TAG_MAIL                 VARCHAR2(4000)         null    ,
    TIPO_UNITA               VARCHAR2(1)            null    ,
    TIPOLOGIA                VARCHAR2(2)            null    ,
    UTENTE_AD4               VARCHAR2(8)            not null,
    constraint SO4_V_UNITA_ORGANIZZATIVE_P_PK primary key (PROGR, DAL, OTTICA)
)
/

comment on table SO4_V_UNITA_ORGANIZZATIVE_PUBB is 'SO4_V_UNITA_ORGANIZZATIVE_PUBB'
/
