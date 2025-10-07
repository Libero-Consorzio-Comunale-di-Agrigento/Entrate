--liquibase formatted sql
--changeset dmarotta:20250326_152438_Tr4_o stripComments:false
--validCheckSum: 1:any

-- ============================================================
--   Database name:  TR4                                       
--   DBMS name:      ORACLE Version for SI4                    
--   Created on:     07/03/2025  09:12                         
-- ============================================================

-- ============================================================
--   Table: CARICHI_TARSU                                      
-- ============================================================
create table CARICHI_TARSU
(
    ANNO                            NUMBER(4)              not null,
    ADDIZIONALE_ECA                 NUMBER(4,2)            null    ,
    MAGGIORAZIONE_ECA               NUMBER(4,2)            null    ,
    ADDIZIONALE_PRO                 NUMBER(4,2)            null    ,
    COMMISSIONE_COM                 NUMBER(4,2)            null    ,
    NON_DOVUTO_PRO                  NUMBER(4,2)            null    ,
    COMPENSO_MINIMO                 NUMBER(8,2)            null    
        constraint CARICHI_TARSU_COMPENSO_MINI_CC check (
            COMPENSO_MINIMO is null or (COMPENSO_MINIMO >= 0
            )),
    COMPENSO_MASSIMO                NUMBER(8,2)            null    ,
    PERC_COMPENSO                   NUMBER(4,2)            null    ,
    LIMITE                          NUMBER(8,2)            null    ,
    TARIFFA_DOMESTICA               NUMBER(10,4)           null    ,
    TARIFFA_NON_DOMESTICA           NUMBER(10,4)           null    ,
    ALIQUOTA                        NUMBER(4,2)            null    ,
    FLAG_LORDO                      VARCHAR2(1)            null    
        constraint CARICHI_TARSU_FLAG_LORDO_CC check (
            FLAG_LORDO is null or (FLAG_LORDO in ('S'))),
    FLAG_SANZIONE_ADD_P             VARCHAR2(1)            null    
        constraint CATA_FLAG_SANZIONE_ADD_P_CC check (
            FLAG_SANZIONE_ADD_P is null or (FLAG_SANZIONE_ADD_P in ('S'))),
    FLAG_SANZIONE_ADD_T             VARCHAR2(1)            null    
        constraint CATA_FLAG_SANZIONE_ADD_T_CC check (
            FLAG_SANZIONE_ADD_T is null or (FLAG_SANZIONE_ADD_T in ('S'))),
    FLAG_INTERESSI_ADD              VARCHAR2(1)            null    
        constraint CATA_FLAG_INTERESSI_ADD_CC check (
            FLAG_INTERESSI_ADD is null or (FLAG_INTERESSI_ADD in ('S'))),
    MESI_CALCOLO                    NUMBER(1)              null    
        constraint CARICHI_TARSU_MESI_CALCOLO_CC check (
            MESI_CALCOLO is null or (MESI_CALCOLO in (0,1,2))),
    IVA_FATTURA                     NUMBER(4,2)            null    ,
    MAGGIORAZIONE_TARES             NUMBER(4,2)            null    
        constraint CARICHI_TARSU_MAGGIORAZIONE_CC check (
            MAGGIORAZIONE_TARES is null or (MAGGIORAZIONE_TARES >= 0.01
            )),
    FLAG_MAGG_ANNO                  VARCHAR2(1)            null    
        constraint CARICHI_TARSU_FLAG_MAGG_ANN_CC check (
            FLAG_MAGG_ANNO is null or (FLAG_MAGG_ANNO in ('S'))),
    MODALITA_FAMILIARI              NUMBER(1)              null    
        constraint CARICHI_TARSU_MODALITA_FAMI_CC check (
            MODALITA_FAMILIARI is null or (MODALITA_FAMILIARI in (1,2,3,4,5))),
    FLAG_NO_TARDIVO                 VARCHAR2(1)            null    
        constraint CARICHI_TARSU_FLAG_NO_TARDI_CC check (
            FLAG_NO_TARDIVO is null or (FLAG_NO_TARDIVO in ('S'))),
    ENTE                            VARCHAR2(4)            null    ,
    FLAG_TARIFFE_RUOLO              VARCHAR2(1)            null    
        constraint CARICHI_TARSU_FLAG_TARIFFE__CC check (
            FLAG_TARIFFE_RUOLO is null or (FLAG_TARIFFE_RUOLO in ('S'))),
    RATA_PEREQUATIVE                VARCHAR2(1)            null    
        constraint CARICHI_TARSU_RATA_PEREQUAT_CC check (
            RATA_PEREQUATIVE is null or (RATA_PEREQUATIVE in ('P','U','T'))),
    FLAG_TARIFFA_PUNTUALE           VARCHAR2(1)            null    
        constraint CARICHI_TARSU_FLAG_TARIFFA__CC check (
            FLAG_TARIFFA_PUNTUALE is null or (FLAG_TARIFFA_PUNTUALE in ('S'))),
    COSTO_UNITARIO                  NUMBER(10,8)           null    ,
    constraint CARICHI_TARSU_PK primary key (ANNO)
)
/

comment on table CARICHI_TARSU is 'CATA - Carichi TARSU'
/

-- ============================================================
--   Table: DATI_GENERALI                                      
-- ============================================================
create table DATI_GENERALI
(
    CHIAVE                          NUMBER(1)              not null
        constraint DATI_GENERALI_CHIAVE_CC check (
            CHIAVE in (1)),
    PRO_CLIENTE                     NUMBER(3)              not null,
    COM_CLIENTE                     NUMBER(3)              not null,
    FLAG_INTEGRAZIONE_GSD           VARCHAR2(1)            null    
        constraint DATI_GENERALI_FLAG_INT_GSD_CC check (
            FLAG_INTEGRAZIONE_GSD is null or (FLAG_INTEGRAZIONE_GSD in ('S'))),
    FLAG_INTEGRAZIONE_TRB           VARCHAR2(1)            null    
        constraint DATI_GENERALI_FLAG_INT_TRB_CC check (
            FLAG_INTEGRAZIONE_TRB is null or (FLAG_INTEGRAZIONE_TRB in ('S'))),
    FASE_EURO                       NUMBER(1)              null    
        constraint DATI_GENERALI_FASE_EURO_CC check (
            FASE_EURO is null or (FASE_EURO in (1,2))),
    CAMBIO_EURO                     NUMBER(6,2)            null    ,
    COD_COMUNE_RUOLO                VARCHAR2(6)            null    ,
    FLAG_CATASTO_CU                 VARCHAR2(1)            null    
        constraint DATI_GENERALI_FLAG_CATASTO__CC check (
            FLAG_CATASTO_CU is null or (FLAG_CATASTO_CU in ('S'))),
    FLAG_PROVINCIA                  VARCHAR2(1)            null    
        constraint DATI_GENERALI_FLAG_PROVINCI_CC check (
            FLAG_PROVINCIA is null or (FLAG_PROVINCIA in ('S'))),
    COD_ABI                         NUMBER(5)              null    ,
    COD_CAB                         NUMBER(5)              null    ,
    COD_AZIENDA                     VARCHAR2(5)            null    ,
    FLAG_ACC_TOTALE                 VARCHAR2(1)            null    
        constraint DATI_GENERALI_FLAG_ACC_TOTA_CC check (
            FLAG_ACC_TOTALE is null or (FLAG_ACC_TOTALE in ('S'))),
    FLAG_COMPETENZE                 VARCHAR2(1)            null    
        constraint DATI_GENERALI_FLAG_COMPETEN_CC check (
            FLAG_COMPETENZE is null or (FLAG_COMPETENZE in ('S'))),
    TIPO_COMUNE                     VARCHAR2(3)            null    
        constraint DATI_GENERALI_TIPO_COMUNE_CC check (
            TIPO_COMUNE is null or (TIPO_COMUNE in ('INF','SUP'))),
    AREA                            VARCHAR2(20)           null    
        constraint DATI_GENERALI_AREA_CC check (
            AREA is null or (AREA in ('NORD','CENTRO','SUD'))),
    constraint DATI_GENERALI_PK primary key (CHIAVE)
)
/

comment on table DATI_GENERALI is 'Dati generali del Comune'
/

-- ============================================================
--   Table: CATELE                                             
-- ============================================================
create table CATELE
(
    PROGRESSIVO                     NUMBER(10)             null    ,
    COD_COMUNE                      VARCHAR2(5)            null    ,
    COD_AZIENDA                     VARCHAR2(5)            null    ,
    COD_UTENTE                      VARCHAR2(14)           null    ,
    COD_FISCALE                     VARCHAR2(16)           null    ,
    DENOMINAZIONE                   VARCHAR2(63)           null    ,
    SESSO                           VARCHAR2(1)            null    ,
    DATA_NAS                        VARCHAR2(7)            null    ,
    COMUNE_NAS                      VARCHAR2(25)           null    ,
    PROVINCIA_UTE                   VARCHAR2(2)            null    ,
    SEZIONE                         VARCHAR2(3)            null    ,
    FOGLIO                          VARCHAR2(5)            null    ,
    NUMERO                          VARCHAR2(5)            null    ,
    SUBALTERNO                      VARCHAR2(4)            null    ,
    PROTOCOLLO                      VARCHAR2(6)            null    ,
    ANNO                            NUMBER(2)              null    ,
    INDIRIZZO                       VARCHAR2(24)           null    ,
    SCALA                           VARCHAR2(2)            null    ,
    PIANO                           VARCHAR2(2)            null    ,
    INTERNO                         VARCHAR2(2)            null    ,
    CAP_FORNITURA                   NUMBER(5)              null    ,
    UTILIZZATO                      VARCHAR2(1)            null    ,
    LOCALITA_FORNITURA              VARCHAR2(18)           null    ,
    SUP_IMMOBILE                    NUMBER(5)              null    ,
    RURALE                          NUMBER(1)              null    ,
    COD_COM_AMM                     VARCHAR2(4)            null    ,
    COD_FISCALE_PRO                 VARCHAR2(16)           null    ,
    DENOMINAZIONE_PRO               VARCHAR2(63)           null    ,
    SESSO_PRO                       VARCHAR2(1)            null    ,
    DATA_NAS_PRO                    VARCHAR2(7)            null    ,
    COM_NAS_PRO                     VARCHAR2(27)           null    ,
    PROVINCIA_PRO                   VARCHAR2(2)            null    ,
    UTENZA                          NUMBER(1)              null    ,
    NOM_REC                         VARCHAR2(20)           null    ,
    IND_REC                         VARCHAR2(24)           null    ,
    CAP_REC                         NUMBER(5)              null    ,
    FIL_REC                         VARCHAR2(1)            null    ,
    LOC_REC                         VARCHAR2(17)           null    ,
    FLAG_COD_FIS_UTE                NUMBER(1)              null    ,
    FLAG_COD_FIS_PRO                NUMBER(1)              null    ,
    DUP                             NUMBER(1)              null    ,
    COD_FIS_UT                      NUMBER(1)              null    ,
    DATI_IMM                        NUMBER(1)              null    ,
    SUPERFICIE_IMM                  NUMBER(1)              null    ,
    COD_FIS_PRO                     NUMBER(1)              null    ,
    INF_QUEST                       NUMBER(1)              null    ,
    COD_ATT                         VARCHAR2(4)            null    ,
    COD_ATT_NEW                     VARCHAR2(5)            null    ,
    PARTITA_IVA                     VARCHAR2(11)           null    
)
/

comment on table CATELE is 'CATELE'
/

-- ============================================================
--   Table: CATELN                                             
-- ============================================================
create table CATELN
(
    COD_AZIENDA                     VARCHAR2(5)            null    ,
    COD_UTENTE                      NUMBER(14)             null    ,
    TIPO_UTENZA                     NUMBER(1)              null    ,
    COD_INTESTATARIO                NUMBER(1)              null    ,
    COGNOME_NOME                    VARCHAR2(35)           null    ,
    COD_FISCALE                     VARCHAR2(16)           null    ,
    INDIRIZZO_FOR                   VARCHAR2(24)           null    ,
    SCALA_FOR                       VARCHAR2(2)            null    ,
    PIANO_FOR                       VARCHAR2(2)            null    ,
    INTERNO_FOR                     VARCHAR2(2)            null    ,
    CAP_FOR                         NUMBER(5)              null    ,
    LOCALITA_FOR                    VARCHAR2(18)           null    ,
    COD_PRO_FOR                     NUMBER(2)              null    ,
    COD_COM_FOR                     NUMBER(3)              null    ,
    COD_CATASTALE                   VARCHAR2(5)            null    ,
    COD_AMM                         VARCHAR2(4)            null    ,
    NOMINATIVO_REC                  VARCHAR2(20)           null    ,
    INDIRIZZO_REC                   VARCHAR2(24)           null    ,
    CAP_REC                         NUMBER(5)              null    ,
    LOCALITA_REC                    VARCHAR2(17)           null    ,
    COD_ATTIVITA                    VARCHAR2(5)            null    
)
/

comment on table CATELN is 'CATELN'
/

-- ============================================================
--   Table: CUARCUIU                                           
-- ============================================================
create table CUARCUIU
(
    CODICE                          VARCHAR2(5)            null    ,
    PARTITA                         VARCHAR2(7)            null    ,
    SEZIONE                         VARCHAR2(3)            null    ,
    FOGLIO                          VARCHAR2(4)            null    ,
    NUMERO                          VARCHAR2(11)           null    ,
    SUBALTERNO                      VARCHAR2(4)            null    ,
    ZONA                            VARCHAR2(3)            null    ,
    CATEGORIA1                      VARCHAR2(1)            null    ,
    CATEGORIA2                      NUMBER(2)              null    ,
    CLASSE                          VARCHAR2(2)            null    ,
    CONSISTENZA                     NUMBER(7,1)            null    ,
    RENDITA                         NUMBER(10)             null    ,
    DESCRIZIONE                     VARCHAR2(100)          null    ,
    CONTATORE                       NUMBER(6)              null    ,
    FLAG                            VARCHAR2(1)            null    ,
    DATA_EFFICACIA                  VARCHAR2(10)           null    ,
    DATA_ISCRIZIONE                 VARCHAR2(10)           null    ,
    CATEGORIA_RIC                   VARCHAR2(3)            null    ,
    SEZIONE_RIC                     VARCHAR2(3)            null    ,
    FOGLIO_RIC                      VARCHAR2(4)            null    ,
    NUMERO_RIC                      VARCHAR2(11)           null    ,
    SUBALTERNO_RIC                  VARCHAR2(4)            null    ,
    ZONA_RIC                        VARCHAR2(3)            null    
)
initrans 1
/

comment on table CUARCUIU is 'CUARCUIU'
/

-- ============================================================
--   Index: IDX1CUARCUIU                                       
-- ============================================================
create index IDX1CUARCUIU on CUARCUIU (PARTITA asc)
/

-- ============================================================
--   Index: IDX2CUARCUIU                                       
-- ============================================================
create index IDX2CUARCUIU on CUARCUIU (SEZIONE asc, FOGLIO asc, NUMERO asc, SUBALTERNO asc, ZONA asc)
/

-- ============================================================
--   Index: IDX3CUARCUIU                                       
-- ============================================================
create index IDX3CUARCUIU on CUARCUIU (CONTATORE asc)
/

-- ============================================================
--   Index: IDX5CUARCUIU_RIC                                   
-- ============================================================
create index IDX5CUARCUIU_RIC on CUARCUIU (CATEGORIA_RIC asc)
/

-- ============================================================
--   Index: IDX4CUARCUIU_FNS                                   
-- ============================================================
create index IDX4CUARCUIU_FNS on CUARCUIU (FOGLIO_RIC asc, NUMERO_RIC asc, SUBALTERNO_RIC asc)
/

-- ============================================================
--   Index: IDX6CUARCUIU_ZONA                                  
-- ============================================================
create index IDX6CUARCUIU_ZONA on CUARCUIU (ZONA_RIC asc)
/

-- ============================================================
--   Table: CUCODTOP                                           
-- ============================================================
create table CUCODTOP
(
    CODICE                          NUMBER(3)              null    ,
    TOPONIMO                        VARCHAR2(16)           null    
)
/

comment on table CUCODTOP is 'CUCODTOP'
/

-- ============================================================
--   Index: IDX1CUCODTOP                                       
-- ============================================================
create index IDX1CUCODTOP on CUCODTOP (CODICE asc)
/

-- ============================================================
--   Table: CUINDIRI                                           
-- ============================================================
create table CUINDIRI
(
    CODICE                          VARCHAR2(5)            null    ,
    CHIAVE                          NUMBER(7)              null    ,
    TOPONIMO                        NUMBER(3)              null    ,
    INDIRIZZO                       VARCHAR2(50)           null    ,
    LOTTO                           VARCHAR2(2)            null    ,
    EDIFICIO                        VARCHAR2(2)            null    ,
    SCALA                           VARCHAR2(2)            null    ,
    INTERNO                         VARCHAR2(3)            null    ,
    CIVICO1                         VARCHAR2(6)            null    ,
    CIVICO2                         VARCHAR2(6)            null    ,
    CIVICO3                         VARCHAR2(6)            null    ,
    PIANO1                          VARCHAR2(4)            null    ,
    PIANO2                          VARCHAR2(4)            null    ,
    PIANO3                          VARCHAR2(4)            null    
)
/

comment on table CUINDIRI is 'CUINDIRI'
/

-- ============================================================
--   Index: IDX1CUINDIRI                                       
-- ============================================================
create index IDX1CUINDIRI on CUINDIRI (CHIAVE asc)
/

-- ============================================================
--   Table: CUNONFIS                                           
-- ============================================================
create table CUNONFIS
(
    CODICE                          VARCHAR2(5)            null    ,
    PARTITA                         NUMBER(7)              null    ,
    DENOMINAZIONE                   VARCHAR2(100)          null    ,
    SEDE                            VARCHAR2(4)            null    ,
    COD_FISCALE                     VARCHAR2(16)           null    ,
    COD_TITOLO                      VARCHAR2(7)            null    ,
    NUMERATORE                      VARCHAR2(9)            null    ,
    DENOMINATORE                    VARCHAR2(9)            null    ,
    DES_TITOLO                      VARCHAR2(25)           null    ,
    DENOMINAZIONE_RIC               VARCHAR2(100)          null    
)
/

comment on table CUNONFIS is 'CUNONFIS'
/

-- ============================================================
--   Index: IDX1CUNONFIS                                       
-- ============================================================
create index IDX1CUNONFIS on CUNONFIS (PARTITA asc)
/

-- ============================================================
--   Index: IDX2CUNONFIS_RIC                                   
-- ============================================================
create index IDX2CUNONFIS_RIC on CUNONFIS (DENOMINAZIONE_RIC asc)
/

-- ============================================================
--   Table: CUFISICA                                           
-- ============================================================
create table CUFISICA
(
    CODICE                          VARCHAR2(5)            null    ,
    PARTITA                         NUMBER(7)              null    ,
    COGNOME                         VARCHAR2(24)           null    ,
    NOME                            VARCHAR2(20)           null    ,
    IND_SUPPLEMENTARI               VARCHAR2(75)           null    ,
    COD_TITOLO                      VARCHAR2(7)            null    ,
    NUMERATORE                      VARCHAR2(9)            null    ,
    DENOMINATORE                    VARCHAR2(9)            null    ,
    DES_TITOLO                      VARCHAR2(25)           null    ,
    SESSO                           NUMBER(1)              null    ,
    DATA_NASCITA                    VARCHAR2(10)           null    ,
    LUOGO_NASCITA                   VARCHAR2(25)           null    ,
    COD_FISCALE                     VARCHAR2(16)           null    ,
    COGNOME_NOME_RIC                VARCHAR2(45)           null    
)
/

comment on table CUFISICA is 'CUFISICA'
/

-- ============================================================
--   Index: IDX1CUFISICA                                       
-- ============================================================
create index IDX1CUFISICA on CUFISICA (PARTITA asc)
/

-- ============================================================
--   Index: IDX2CUFISICA_RIC                                   
-- ============================================================
create index IDX2CUFISICA_RIC on CUFISICA (COGNOME_NOME_RIC asc)
/

-- ============================================================
--   Table: UTEELE                                             
-- ============================================================
create table UTEELE
(
    UTENZA                          VARCHAR2(16)           null    ,
    ENTE                            NUMBER(5)              null    ,
    TIPO_UTENTE                     VARCHAR2(1)            null    ,
    NOMINATIVO                      VARCHAR2(35)           null    ,
    COD_FISCALE                     VARCHAR2(16)           null    ,
    TIPO_VIA                        VARCHAR2(3)            null    ,
    NOME_VIA                        VARCHAR2(27)           null    ,
    LOCALITA                        VARCHAR2(18)           null    ,
    CAP                             VARCHAR2(5)            null    ,
    TIPO_UTENZA                     VARCHAR2(1)            null    ,
    STATO_UTENZA                    VARCHAR2(1)            null    ,
    COD_ATTIVITA                    VARCHAR2(3)            null    ,
    POTENZA                         NUMBER(7,1)            null    ,
    CONSUMO                         VARCHAR2(9)            null    ,
    DATA_ALLACCIAMENTO              VARCHAR2(8)            null    ,
    DATA_CONTRATTO                  VARCHAR2(8)            null    ,
    COD_CONTRATTO                   VARCHAR2(1)            null    ,
    NOMINATIVO_RECAPITO             VARCHAR2(20)           null    ,
    INDIRIZZO_RECAPITO              VARCHAR2(24)           null    ,
    LOCALITA_RECAPITO               VARCHAR2(18)           null    ,
    CAP_RECAPITO                    VARCHAR2(5)            null    ,
    SEMESTRE                        VARCHAR2(8)            null    
)
/

comment on table UTEELE is 'UTEELE'
/

-- ============================================================
--   Table: ETICHETTE                                          
-- ============================================================
create table ETICHETTE
(
    ETICHETTA                       NUMBER(2)              not null,
    DESCRIZIONE                     VARCHAR2(60)           not null,
    ALTEZZA                         NUMBER(4,2)            not null,
    LARGHEZZA                       NUMBER(4,2)            not null,
    RIGHE                           NUMBER(3)              null    ,
    COLONNE                         NUMBER(1)              not null,
    SPAZIO_TRA_RIGHE                NUMBER(3,2)            not null,
    SPAZIO_TRA_COLONNE              NUMBER(3,2)            not null,
    MODULO                          VARCHAR2(1)            not null
        constraint ETICHETTE_MODULO_CC check (
            MODULO in ('C','S')),
    ORIENTAMENTO                    VARCHAR2(1)            null    
        constraint ETICHETTE_ORIENTAMENTO_CC check (
            ORIENTAMENTO is null or (ORIENTAMENTO in ('V','O'))),
    SOPRA                           NUMBER(3,2)            null    ,
    SINISTRA                        NUMBER(3,2)            null    ,
    NOTE                            VARCHAR2(2000)         null    ,
    constraint ETICHETTE_PK primary key (ETICHETTA)
)
/

comment on table ETICHETTE is 'ETIC- Etichette'
/

-- ============================================================
--   Table: PARAMETRI                                          
-- ============================================================
create table PARAMETRI
(
    SESSIONE                        NUMBER                 not null,
    NOME_PARAMETRO                  VARCHAR2(30)           not null,
    PROGRESSIVO                     NUMBER                 not null,
    VALORE                          VARCHAR2(2000)         null    ,
    DATA                            DATE                   null    ,
    constraint PARAMETRI_PK primary key (SESSIONE, NOME_PARAMETRO, PROGRESSIVO)
)
/

comment on table PARAMETRI is 'PARA - Temp Parametri'
/

create sequence PARAM_SEQ
minvalue -999999999999999999999999999
maxvalue -1
start with -1
increment by -1
cache 20
/

-- ============================================================
--   Table: WRK_CALCOLO_INDIVIDUALE
-- ============================================================
create table WRK_CALCOLO_INDIVIDUALE
(
    PRATICA                         NUMBER(10)             not null,
    ACCONTO_TERRENI                 NUMBER(12,2)           null    ,
    SALDO_TERRENI                   NUMBER(12,2)           null    ,
    TOT_TERRENI                     NUMBER(12,2)           null    ,
    ACCONTO_AREE                    NUMBER(12,2)           null    ,
    SALDO_AREE                      NUMBER(12,2)           null    ,
    TOT_AREE                        NUMBER(12,2)           null    ,
    ACCONTO_AB                      NUMBER(12,2)           null    ,
    ACCONTO_ALTRI                   NUMBER(12,2)           null    ,
    SALDO_AB                        NUMBER(12,2)           null    ,
    TOT_AB                          NUMBER(12,2)           null    ,
    SALDO_ALTRI                     NUMBER(12,2)           null    ,
    TOT_ALTRI                       NUMBER(12,2)           null    ,
    ACCONTO_DETRAZIONE              NUMBER(12,2)           null    ,
    SALDO_DETRAZIONE                NUMBER(12,2)           null    ,
    TOT_DETRAZIONE                  NUMBER(12,2)           null    ,
    TOTALE_TERRENI                  NUMBER(12,2)           null    ,
    NUMERO_FABBRICATI               NUMBER(12,2)           null    ,
    ACCONTO_DETRAZIONE_IMPONIBILE   NUMBER(12,2)           null    ,
    SALDO_DETRAZIONE_IMPONIBILE     NUMBER(12,2)           null    ,
    TOT_DETRAZIONE_IMPONIBILE       NUMBER(12,2)           null    ,
    ACCONTO_RURALI                  NUMBER(12,2)           null    ,
    SALDO_RURALI                    NUMBER(12,2)           null    ,
    TOT_RURALI                      NUMBER(12,2)           null    ,
    ACCONTO_TERRENI_ERAR            NUMBER(12,2)           null    ,
    SALDO_TERRENI_ERAR              NUMBER(12,2)           null    ,
    TOT_TERRENI_ERAR                NUMBER(12,2)           null    ,
    ACCONTO_AREE_ERAR               NUMBER(12,2)           null    ,
    SALDO_AREE_ERAR                 NUMBER(12,2)           null    ,
    TOT_AREE_ERAR                   NUMBER(12,2)           null    ,
    ACCONTO_ALTRI_ERAR              NUMBER(12,2)           null    ,
    SALDO_ALTRI_ERAR                NUMBER(12,2)           null    ,
    TOT_ALTRI_ERAR                  NUMBER(12,2)           null    ,
    NUM_FABBRICATI_AB               NUMBER(12,2)           null    ,
    NUM_FABBRICATI_RURALI           NUMBER(12,2)           null    ,
    NUM_FABBRICATI_ALTRI            NUMBER(12,2)           null    ,
    ACCONTO_FABBRICATI_D            NUMBER(12,2)           null    ,
    SALDO_FABBRICATI_D              NUMBER(12,2)           null    ,
    TOT_FABBRICATI_D                NUMBER(12,2)           null    ,
    ACCONTO_FABBRICATI_D_ERAR       NUMBER(12,2)           null    ,
    SALDO_FABBRICATI_D_ERAR         NUMBER(12,2)           null    ,
    TOT_FABBRICATI_D_ERAR           NUMBER(12,2)           null    ,
    NUM_FABBRICATI_D                NUMBER(12,2)           null    ,
    GUEST_COD_FISCALE               VARCHAR2(16)           null    ,
    GUEST_COGNOME                   VARCHAR2(60)           null    ,
    GUEST_NOME                      VARCHAR2(36)           null    ,
    GUEST_SESSO                     VARCHAR2(1)            null    ,
    GUEST_DATA_NAS                  DATE                   null    ,
    GUEST_COMUNE_NAS                VARCHAR2(60)           null    ,
    GUEST_SIGLA_PRO_NAS             VARCHAR2(2)            null    ,
    VERS_ACCONTO_TERRENI_COMU       NUMBER(12,2)           null    ,
    VERS_ACCONTO_TERRENI_ERAR       NUMBER(12,2)           null    ,
    VERS_ACCONTO_AREE_COMU          NUMBER(12,2)           null    ,
    VERS_ACCONTO_AREE_ERAR          NUMBER(12,2)           null    ,
    VERS_ACCONTO_AB                 NUMBER(12,2)           null    ,
    VERS_ACCONTO_ALTRI_COMU         NUMBER(12,2)           null    ,
    VERS_ACCONTO_ALTRI_ERAR         NUMBER(12,2)           null    ,
    VERS_ACCONTO_RURALI             NUMBER(12,2)           null    ,
    VERS_ACCONTO_FABBRICATI_D_COMU  NUMBER(12,2)           null    ,
    VERS_ACCONTO_FABBRICATI_D_ERAR  NUMBER(12,2)           null    ,
    ACCONTO_FABBRICATI_MERCE        NUMBER(12,2)           null    ,
    SALDO_FABBRICATI_MERCE          NUMBER(12,2)           null    ,
    TOT_FABBRICATI_MERCE            NUMBER(12,2)           null    ,
    NUM_FABBRICATI_MERCE            NUMBER(12,2)           null    ,
    VERS_ACCONTO_FABBRICATI_MERCE   NUMBER(12,2)           null    ,
    constraint WRK_CALCOLO_INDIVIDUALE_PK primary key (PRATICA)
)
/

comment on table WRK_CALCOLO_INDIVIDUALE is 'Tabella di lavoro per il calcolo individuale ICI'
/

-- ============================================================
--   Table: COEFFICIENTI_DOMESTICI
-- ============================================================
create table COEFFICIENTI_DOMESTICI
(
    ANNO                            NUMBER(4)              not null,
    NUMERO_FAMILIARI                NUMBER(2)              not null,
    COEFF_ADATTAMENTO               NUMBER(6,4)            not null,
    COEFF_PRODUTTIVITA              NUMBER(6,4)            not null,
    COEFF_ADATTAMENTO_NO_AP         NUMBER(6,4)            null    ,
    COEFF_PRODUTTIVITA_NO_AP        NUMBER(6,4)            null    ,
    constraint COEFFICIENTI_DOMESTICI_PK primary key (ANNO, NUMERO_FAMILIARI)
)
/

comment on table COEFFICIENTI_DOMESTICI is 'CODO - Coefficienti Domestici'
/

-- ============================================================
--   Table: WRK_TRAS_ANCI
-- ============================================================
create table WRK_TRAS_ANCI
(
    ANNO                            NUMBER                 not null,
    PROGRESSIVO                     NUMBER                 not null,
    DATI                            VARCHAR2(3000)         null    ,
    constraint WRK_TRAS_ANCI_PK primary key (ANNO, PROGRESSIVO)
)
/

comment on table WRK_TRAS_ANCI is 'Wrk_Tras_anci'
/

-- ============================================================
--   Table: SIGAI_ANA_FIS
-- ============================================================
create table SIGAI_ANA_FIS
(
    TDICH                           VARCHAR2(1)            null    ,
    FISCALE                         VARCHAR2(16)           null    ,
    PRESENTA                        VARCHAR2(10)           null    ,
    MODELLO                         VARCHAR2(1)            null    ,
    PROG_MOD                        VARCHAR2(5)            null    ,
    COGNOME                         VARCHAR2(24)           null    ,
    NOME                            VARCHAR2(20)           null    ,
    SESSO                           VARCHAR2(1)            null    ,
    DATA_NASCITA                    VARCHAR2(10)           null    ,
    PRV_NASCITA                     VARCHAR2(2)            null    ,
    COMUNE_NASCITA                  VARCHAR2(21)           null    ,
    COMUNE_RES                      VARCHAR2(21)           null    ,
    ISTAT_COM_RES                   VARCHAR2(6)            null    ,
    PRV_RES                         VARCHAR2(2)            null    ,
    CAP_RES                         VARCHAR2(5)            null    ,
    INDIRIZZO_RES                   VARCHAR2(35)           null    ,
    COD_STA_CIV                     VARCHAR2(1)            null    ,
    TIT_STUDIO                      VARCHAR2(1)            null    ,
    FALLIMENTO                      VARCHAR2(1)            null    ,
    EVENTI_ECC                      VARCHAR2(1)            null    ,
    CA_PAR_DOM_FI                   VARCHAR2(1)            null    ,
    COM_DO_FI                       VARCHAR2(21)           null    ,
    ISTAT_COM_FI                    VARCHAR2(6)            null    ,
    PRO_DOM_FI                      VARCHAR2(2)            null    ,
    INDIR_DOM_FI                    VARCHAR2(35)           null    ,
    CAP_DOM_FI                      VARCHAR2(5)            null    ,
    PRES_DICH_CONG                  VARCHAR2(1)            null    ,
    FISC_CONIUGE                    VARCHAR2(16)           null    ,
    RECO_MODIFICATO                 VARCHAR2(1)            null    ,
    FISC_DENUNC                     VARCHAR2(16)           null    ,
    FREE                            VARCHAR2(1)            null    ,
    DENOM_DENUNC                    VARCHAR2(60)           null    ,
    DOM_FISC_DENUNC                 VARCHAR2(35)           null    ,
    CAP_FISC_DENUNC                 VARCHAR2(5)            null    ,
    COM_FISC_DENUNC                 VARCHAR2(25)           null    ,
    PRV_FISC_DENUNC                 VARCHAR2(2)            null    ,
    CARICA_DENUNC                   VARCHAR2(25)           null    ,
    TEL_PREF_DICHIAR                VARCHAR2(4)            null    ,
    TEL_DICHIARANTE                 VARCHAR2(8)            null    ,
    PROGRESSIVO                     VARCHAR2(9)            null
)
/

comment on table SIGAI_ANA_FIS is 'SIAF - SIGAI Anagrafiche Fiscale'
/

-- ============================================================
--   Index: SIAF_CF_IK
-- ============================================================
create index SIAF_CF_IK on SIGAI_ANA_FIS (FISCALE asc)
/

-- ============================================================
--   Table: SIGAI_ANA_GIUR
-- ============================================================
create table SIGAI_ANA_GIUR
(
    U_IIDD                          VARCHAR2(3)            null    ,
    CENTRO_SERVIZIO                 VARCHAR2(3)            null    ,
    PRESENTA                        VARCHAR2(10)           null    ,
    FISCALE                         VARCHAR2(16)           null    ,
    MODELLO                         VARCHAR2(1)            null    ,
    PROG_MOD                        VARCHAR2(5)            null    ,
    FLAG_CF                         VARCHAR2(1)            null    ,
    SIGLA                           VARCHAR2(20)           null    ,
    RAGIONE_SOC                     VARCHAR2(180)          null    ,
    FLAG                            VARCHAR2(1)            null    ,
    APPR_BIL                        VARCHAR2(10)           null    ,
    TER_BIL                         VARCHAR2(10)           null    ,
    DATA_VARIAZ                     VARCHAR2(10)           null    ,
    COMUNE_SEDE_LEG                 VARCHAR2(25)           null    ,
    ISTAT_COM_SL                    VARCHAR2(6)            null    ,
    PROV_SEDE_LEG                   VARCHAR2(2)            null    ,
    CAP_SEDE_LEG                    VARCHAR2(5)            null    ,
    IND_SEDE_LEG                    VARCHAR2(35)           null    ,
    DATA_VARIAZ_DF                  VARCHAR2(10)           null    ,
    COMUNE_DOM_FI                   VARCHAR2(25)           null    ,
    ISTAT_COM                       VARCHAR2(6)            null    ,
    PROV_DOM_FI                     VARCHAR2(2)            null    ,
    CAP_DOM_FI                      VARCHAR2(5)            null    ,
    IND_DOM_FI                      VARCHAR2(35)           null    ,
    STATO                           VARCHAR2(1)            null    ,
    NATURA_GIU                      VARCHAR2(2)            null    ,
    SITUAZ                          VARCHAR2(1)            null    ,
    FI_SOC_IN                       VARCHAR2(16)           null    ,
    FLAG_CF_S_IN                    VARCHAR2(1)            null    ,
    EVENTI_ECC                      VARCHAR2(1)            null    ,
    FISC_RAP_LEG                    VARCHAR2(16)           null    ,
    FLAG_RAP_LEG                    VARCHAR2(1)            null    ,
    COGNOME_RAP_LEG                 VARCHAR2(24)           null    ,
    NOME_RAP_LEG                    VARCHAR2(20)           null    ,
    SESSO_RAP_LEG                   VARCHAR2(1)            null    ,
    DATA_NAS_RAP_LE                 VARCHAR2(10)           null    ,
    COM_NAS_RAP_LE                  VARCHAR2(25)           null    ,
    ISTAT_NAS_RAP_LE                VARCHAR2(6)            null    ,
    PRV_NAS_RAP_LE                  VARCHAR2(2)            null    ,
    DENOMINAZ                       VARCHAR2(79)           null    ,
    CODICE_CARI                     VARCHAR2(1)            null    ,
    DATA_CARICA                     VARCHAR2(10)           null    ,
    COMU_RE_RA_LE                   VARCHAR2(25)           null    ,
    ISTAT_RE_RA_LE                  VARCHAR2(6)            null    ,
    PROV_RE_RA_LE                   VARCHAR2(2)            null    ,
    IND_RAP_LEG                     VARCHAR2(35)           null    ,
    CAP_RAP_LEG                     VARCHAR2(5)            null    ,
    CAAF                            VARCHAR2(1)            null    ,
    RECO_MODIFICATO                 VARCHAR2(1)            null    ,
    FISC_DENUNC                     VARCHAR2(16)           null    ,
    FREE                            VARCHAR2(1)            null    ,
    DENOM_DENUNC                    VARCHAR2(60)           null    ,
    DOM_FISC_DENUNC                 VARCHAR2(35)           null    ,
    CAP_FISC_DENUNC                 VARCHAR2(5)            null    ,
    COM_FISC_DENUNC                 VARCHAR2(25)           null    ,
    PRV_FISC_DENUNC                 VARCHAR2(2)            null    ,
    CARICA_DENUNC                   VARCHAR2(25)           null    ,
    TEL_PREF_DICHIAR                VARCHAR2(4)            null    ,
    TEL_DICHIARANTE                 VARCHAR2(8)            null    ,
    PROGRESSIVO                     VARCHAR2(9)            null
)
/

comment on table SIGAI_ANA_GIUR is 'SIAG - SIGAI Anagrafiche Giuridiche'
/

-- ============================================================
--   Index: SIAG_CF_IK
-- ============================================================
create index SIAG_CF_IK on SIGAI_ANA_GIUR (FISCALE asc)
/

-- ============================================================
--   Table: SIGAI_CONT_FABBRICATI
-- ============================================================
create table SIGAI_CONT_FABBRICATI
(
    FISCALE                         VARCHAR2(16)           null    ,
    DATA_SIT                        VARCHAR2(10)           null    ,
    PROG_MOD                        VARCHAR2(5)            null    ,
    NUM_ORD                         VARCHAR2(4)            null    ,
    ISTAT_COM                       VARCHAR2(6)            null    ,
    SEZIONE                         VARCHAR2(3)            null    ,
    FOGLIO                          VARCHAR2(5)            null    ,
    NUMERO                          VARCHAR2(5)            null    ,
    SUBALTERNO                      VARCHAR2(4)            null    ,
    PROTOCOLLO                      VARCHAR2(6)            null    ,
    ANNO_DE_ACC                     VARCHAR2(4)            null    ,
    FISC_CONT                       VARCHAR2(16)           null    ,
    FLAGCF                          VARCHAR2(1)            null    ,
    PERC_POSS                       VARCHAR2(5)            null    ,
    ABIT_PRIN                       VARCHAR2(1)            null    ,
    PROGRESSIVO                     VARCHAR2(7)            null    ,
    INVIO                           VARCHAR2(5)            null    ,
    IMPO_DETRAZ_AB_PR               VARCHAR2(8)            null    ,
    FLAG_POSSESSO                   VARCHAR2(1)            null    ,
    RECO_MODIFICATO                 VARCHAR2(1)            null
)
/

comment on table SIGAI_CONT_FABBRICATI is 'SICF - SIGAI Contitolari Fabbricati'
/

-- ============================================================
--   Index: SICF_CF_IK
-- ============================================================
create index SICF_CF_IK on SIGAI_CONT_FABBRICATI (FISCALE asc)
/

-- ============================================================
--   Table: SIGAI_CONT_TERRENI
-- ============================================================
create table SIGAI_CONT_TERRENI
(
    ISTAT_COM                       VARCHAR2(6)            null    ,
    FISCALE                         VARCHAR2(16)           null    ,
    DATA_SIT                        VARCHAR2(10)           null    ,
    FLAG_CF                         VARCHAR2(1)            null    ,
    PROG_MOD                        VARCHAR2(5)            null    ,
    NUM_ORDINE                      VARCHAR2(4)            null    ,
    PART_CATAST                     VARCHAR2(8)            null    ,
    CF_CONTITOLARE                  VARCHAR2(16)           null    ,
    PER_Q_POSS                      VARCHAR2(5)            null    ,
    PROGRESSIVO                     VARCHAR2(7)            null    ,
    INVIO                           VARCHAR2(3)            null    ,
    RECO_MODIFICATO                 VARCHAR2(1)            null
)
/

comment on table SIGAI_CONT_TERRENI is 'SICT - SIGAI Contitolari Terreni'
/

-- ============================================================
--   Index: SICT_CF_IK
-- ============================================================
create index SICT_CF_IK on SIGAI_CONT_TERRENI (FISCALE asc)
/

-- ============================================================
--   Table: SIGAI_FABBRICATI
-- ============================================================
create table SIGAI_FABBRICATI
(
    FISCALE                         VARCHAR2(16)           null    ,
    PERSONA                         VARCHAR2(1)            null    ,
    DATA_SIT                        VARCHAR2(10)           null    ,
    TDICH                           VARCHAR2(1)            null    ,
    PROG_MOD                        VARCHAR2(5)            null    ,
    NUM_ORD                         VARCHAR2(4)            null    ,
    CARATTERISTICA                  VARCHAR2(1)            null    ,
    COMUNE                          VARCHAR2(21)           null    ,
    ISTAT_COM                       VARCHAR2(6)            null    ,
    PROV                            VARCHAR2(2)            null    ,
    CAP                             VARCHAR2(5)            null    ,
    INDIRIZZO                       VARCHAR2(36)           null    ,
    SEZIONE                         VARCHAR2(3)            null    ,
    FOGLIO                          VARCHAR2(5)            null    ,
    NUMERO                          VARCHAR2(5)            null    ,
    SUBALTERNO                      VARCHAR2(4)            null    ,
    PROTOCOLLO                      VARCHAR2(6)            null    ,
    ANNO_DE_ACC                     VARCHAR2(4)            null    ,
    CAT_CATASTALE                   VARCHAR2(3)            null    ,
    CLASSE                          VARCHAR2(2)            null    ,
    IMM_STORICO                     VARCHAR2(1)            null    ,
    IDEN_REND_VALORE                VARCHAR2(1)            null    ,
    FLAG_VAL_PROV                   VARCHAR2(1)            null    ,
    TIPO_IMM                        VARCHAR2(1)            null    ,
    SOGG_ICI                        VARCHAR2(1)            null    ,
    DETRAZ_PRINC                    VARCHAR2(7)            null    ,
    RIDUZIONE                       VARCHAR2(1)            null    ,
    RENDITA                         VARCHAR2(13)           null    ,
    PERC_POSS                       VARCHAR2(5)            null    ,
    MESI_POSS                       VARCHAR2(2)            null    ,
    MESI_ESC_ESENZI                 VARCHAR2(2)            null    ,
    MESI_APPL_RIDU                  VARCHAR2(2)            null    ,
    POSSESSO                        VARCHAR2(1)            null    ,
    ESCLUSO_ESENTE                  VARCHAR2(1)            null    ,
    RIDUZIONE_2                     VARCHAR2(1)            null    ,
    ABIT_PRINC                      VARCHAR2(1)            null    ,
    FISC_DICH_CONG                  VARCHAR2(16)           null    ,
    FLAGC_F                         VARCHAR2(1)            null    ,
    RENDITA_REDD                    VARCHAR2(10)           null    ,
    GIORNI_POSS_REDD                VARCHAR2(3)            null    ,
    PERC_POSS_REDD                  VARCHAR2(5)            null    ,
    REDDITO_EFF_REDD                VARCHAR2(9)            null    ,
    UTILIZZO_REDD                   VARCHAR2(1)            null    ,
    DE_PIANO_EN_REDD                VARCHAR2(9)            null    ,
    DAT_SC_ILOR_REDD                VARCHAR2(4)            null    ,
    IMPON_IRPEF_REDD                VARCHAR2(9)            null    ,
    TITOLO_REDD                     VARCHAR2(1)            null    ,
    SOGG_ISI_REDD                   VARCHAR2(1)            null    ,
    IMPON_ILOR                      VARCHAR2(9)            null    ,
    PROGRESSIVO                     VARCHAR2(7)            null    ,
    RECO_MODIFICATO                 VARCHAR2(1)            null    ,
    INVIO                           VARCHAR2(3)            null    ,
    RELAZIONE                       VARCHAR2(8)            null    ,
    ANNO_FISCALE                    VARCHAR2(4)            null
)
/

comment on table SIGAI_FABBRICATI is 'SIFA - SIGAI Fabbricati'
/

-- ============================================================
--   Index: SIFA_CF_IK
-- ============================================================
create index SIFA_CF_IK on SIGAI_FABBRICATI (FISCALE asc)
/

-- ============================================================
--   Table: SIGAI_TERRENI
-- ============================================================
create table SIGAI_TERRENI
(
    FISCALE                         VARCHAR2(16)           null    ,
    PERSONA                         VARCHAR2(1)            null    ,
    DATA_SIT                        VARCHAR2(10)           null    ,
    CENTRO_CONS                     VARCHAR2(3)            null    ,
    PROVIIDD                        VARCHAR2(3)            null    ,
    UFF_IIDD                        VARCHAR2(3)            null    ,
    CENT_SERV                       VARCHAR2(3)            null    ,
    TDICH                           VARCHAR2(1)            null    ,
    PROG_MOD                        VARCHAR2(5)            null    ,
    COMUNE                          VARCHAR2(32)           null    ,
    ISTAT_COM                       VARCHAR2(6)            null    ,
    PROV                            VARCHAR2(2)            null    ,
    NUM_ORD_TERR                    VARCHAR2(4)            null    ,
    PARTITA_CAT                     VARCHAR2(8)            null    ,
    SOGG_ICI                        VARCHAR2(1)            null    ,
    COND_DIR                        VARCHAR2(1)            null    ,
    AREA_FAB                        VARCHAR2(1)            null    ,
    REDD_NOM                        VARCHAR2(10)           null    ,
    PER_POSS                        VARCHAR2(5)            null    ,
    F_DICH_CONG                     VARCHAR2(16)           null    ,
    TOT_REDD_DOM                    VARCHAR2(9)            null    ,
    QT_RED_DOM_IRPEF                VARCHAR2(9)            null    ,
    QT_RED_DOM_ILOR                 VARCHAR2(9)            null    ,
    VALORE_ISI                      VARCHAR2(9)            null    ,
    TITOLO                          VARCHAR2(1)            null    ,
    TOT_REDD_AGR                    VARCHAR2(9)            null    ,
    QT_RED_AGR_IRPEF                VARCHAR2(9)            null    ,
    QT_RED_AGR_ILOR                 VARCHAR2(9)            null    ,
    DED_ILOR                        VARCHAR2(9)            null    ,
    PROGRESSIVO                     VARCHAR2(7)            null    ,
    RECO_MODIFICATO                 VARCHAR2(1)            null    ,
    INVIO                           VARCHAR2(3)            null    ,
    RELAZIONE                       VARCHAR2(8)            null    ,
    ANNO_FISCALE                    VARCHAR2(4)            null    ,
    MESI_POSS                       VARCHAR2(2)            null    ,
    MESI_ESC_ESENZI                 VARCHAR2(2)            null    ,
    MESI_APPL_RIDU                  VARCHAR2(2)            null    ,
    POSSESSO                        VARCHAR2(1)            null    ,
    ESENZIONE                       VARCHAR2(1)            null    ,
    RIDUZIONE                       VARCHAR2(1)            null    ,
    INDIRIZZO                       VARCHAR2(36)           null
)
/

comment on table SIGAI_TERRENI is 'SITE - SIGAI Terreni'
/

-- ============================================================
--   Index: SITE_CF_IK
-- ============================================================
create index SITE_CF_IK on SIGAI_TERRENI (FISCALE asc)
/

-- ============================================================
--   Table: SIGAI_VERSAMENTI
-- ============================================================
create table SIGAI_VERSAMENTI
(
    CONCESSIONE                     VARCHAR2(4)            null    ,
    FISCALE                         VARCHAR2(16)           null    ,
    DATA_VERSAME                    VARCHAR2(10)           null    ,
    COMUNE_IMMOB                    VARCHAR2(25)           null    ,
    ISTAT_COM                       VARCHAR2(6)            null    ,
    CAP_IMMOBILE                    VARCHAR2(5)            null    ,
    NUM_FABBRICATI                  VARCHAR2(4)            null    ,
    ANNO_FISCALE_IMM                VARCHAR2(4)            null    ,
    FLAG_ACCONTO                    VARCHAR2(1)            null    ,
    FLAG_SALDO                      VARCHAR2(1)            null    ,
    IMP_TERR_AGR                    VARCHAR2(10)           null    ,
    AREE_FABBRICA                   VARCHAR2(10)           null    ,
    ABIT_PRINCIP                    VARCHAR2(10)           null    ,
    ALTRI_FABBRIC                   VARCHAR2(10)           null    ,
    IMP_DET_AB_PR                   VARCHAR2(8)            null    ,
    TOTALE_IMP                      VARCHAR2(11)           null    ,
    PROGRESSIVO                     VARCHAR2(7)            null    ,
    INVIO                           VARCHAR2(3)            null    ,
    EX_RURALE                       VARCHAR2(1)            null    ,
    RECO_MODIFICATO                 VARCHAR2(1)            null
)
/

comment on table SIGAI_VERSAMENTI is 'SIVE - SIGAI Versamenti'
/

-- ============================================================
--   Index: SIVE_CF_IK
-- ============================================================
create index SIVE_CF_IK on SIGAI_VERSAMENTI (FISCALE asc)
/

-- ============================================================
--   Table: WRK_RISCOSSIONI
-- ============================================================
create table WRK_RISCOSSIONI
(
    RUOLO                           NUMBER(10)             not null,
    COD_FISCALE                     VARCHAR2(16)           not null,
    TIPO_TRIBUTO                    VARCHAR2(5)            not null,
    COGNOME_NOME                    VARCHAR2(60)           null    ,
    COD_ABI                         NUMBER(5)              null    ,
    COD_CAB                         NUMBER(5)              null    ,
    CONTO_CORRENTE                  VARCHAR2(12)           null    ,
    COD_CONTROLLO_CC                VARCHAR2(1)            null    ,
    ANNO                            NUMBER(4)              not null,
    RATA                            NUMBER(1)              not null,
    IMPORTO_TOTALE                  NUMBER(15,2)           null    ,
    DATA_SCADENZA                   DATE                   null    ,
    DATA_PAGAMENTO                  DATE                   null    ,
    IMPORTO_VERSATO                 NUMBER(15,2)           null    ,
    constraint WRK_RISCOSSIONI_PK primary key (RUOLO, COD_FISCALE, TIPO_TRIBUTO, ANNO, RATA)
)
/

comment on table WRK_RISCOSSIONI is 'WRIS - WRK_RISCOSSIONI'
/

-- ============================================================
--   Table: CC_FABBRICATI
-- ============================================================
create table CC_FABBRICATI
(
    CODICE_AMM                      VARCHAR2(4)            null    ,
    SEZIONE_AMM                     VARCHAR2(1)            null    ,
    ID_IMMOBILE                     NUMBER(15)             null    ,
    TIPO_IMMOBILE                   VARCHAR2(1)            null    ,
    PROGRESSIVO                     NUMBER(3)              null    ,
    TIPO_RECORD                     NUMBER(1)              null    ,
    ZONA                            VARCHAR2(3)            null    ,
    CATEGORIA                       VARCHAR2(3)            null    ,
    CLASSE                          VARCHAR2(3)            null    ,
    CONSISTENZA                     NUMBER(7,1)            null    ,
    SUPERFICIE                      NUMBER(5)              null    ,
    RENDITA_LIRE                    NUMBER(15)             null    ,
    RENDITA_EURO                    NUMBER(18,3)           null    ,
    LOTTO                           VARCHAR2(2)            null    ,
    EDIFICIO                        VARCHAR2(2)            null    ,
    SCALA                           VARCHAR2(2)            null    ,
    INTERNO_1                       VARCHAR2(3)            null    ,
    INTERNO_2                       VARCHAR2(3)            null    ,
    PIANO_1                         VARCHAR2(4)            null    ,
    PIANO_2                         VARCHAR2(4)            null    ,
    PIANO_3                         VARCHAR2(4)            null    ,
    PIANO_4                         VARCHAR2(4)            null    ,
    DATA_EFFICACIA                  VARCHAR2(8)            null    ,
    DATA_REGISTRAZIONE_ATTI         VARCHAR2(8)            null    ,
    TIPO_NOTA                       VARCHAR2(1)            null    ,
    NUMERO_NOTA                     VARCHAR2(6)            null    ,
    PROGRESSIVO_NOTA                VARCHAR2(3)            null    ,
    ANNO_NOTA                       NUMBER(4)              null    ,
    DATA_EFFICACIA_2                VARCHAR2(8)            null    ,
    DATA_REGISTRAZIONE_ATTI_2       VARCHAR2(8)            null    ,
    TIPO_NOTA_2                     VARCHAR2(1)            null    ,
    NUMERO_NOTA_2                   VARCHAR2(6)            null    ,
    PROGRESSIVO_NOTA_2              VARCHAR2(3)            null    ,
    ANNO_NOTA_2                     NUMBER(4)              null    ,
    PARTITA                         VARCHAR2(7)            null    ,
    ANNOTAZIONE                     VARCHAR2(200)          null    ,
    ID_MUTAZIONE_INIZIALE           NUMBER(9)              null    ,
    ID_MUTAZIONE_FINALE             NUMBER(9)              null    ,
    ZONA_RIC                        VARCHAR2(3)            null    ,
    CATEGORIA_RIC                   VARCHAR2(3)            null    ,
    PARTITA_RIC                     VARCHAR2(7)            null    ,
    PROTOCOLLO_NOTIFICA             VARCHAR2(18)           null    ,
    DATA_NOTIFICA                   VARCHAR2(8)            null    ,
    COD_CAUSALE_ATTO_GENERANTE      VARCHAR2(3)            null    ,
    DES_ATTO_GENERANTE              VARCHAR2(100)          null    ,
    COD_CAUSALE_ATTO_CONCLUSIVO     VARCHAR2(3)            null    ,
    DES_ATTO_CONCLUSIVO             VARCHAR2(100)          null    ,
    FLAG_CLASSAMENTO                VARCHAR2(1)            null    ,
    DOCUMENTO_ID                    NUMBER(10)             null    ,
    UTENTE                          VARCHAR2(8)            null    ,
    DATA_VARIAZIONE                 DATE                   null
)
/

comment on table CC_FABBRICATI is 'CC_FABBRICATI'
/

-- ============================================================
--   Index: CC_FABB_IMMO_IK
-- ============================================================
create index CC_FABB_IMMO_IK on CC_FABBRICATI (ID_IMMOBILE asc, PROGRESSIVO asc, TIPO_IMMOBILE asc, CODICE_AMM asc, SEZIONE_AMM asc)
/

-- ============================================================
--   Index: CC_FABB_ZONA_IK
-- ============================================================
create index CC_FABB_ZONA_IK on CC_FABBRICATI (ZONA_RIC asc)
/

-- ============================================================
--   Index: CC_FABB_CATEGORIA_IK
-- ============================================================
create index CC_FABB_CATEGORIA_IK on CC_FABBRICATI (CATEGORIA_RIC asc)
/

-- ============================================================
--   Index: CC_FABB_PARTITA_IK
-- ============================================================
create index CC_FABB_PARTITA_IK on CC_FABBRICATI (PARTITA_RIC asc)
/

-- ============================================================
--   Table: CC_INDIRIZZI
-- ============================================================
create table CC_INDIRIZZI
(
    CODICE_AMM                      VARCHAR2(4)            null    ,
    SEZIONE_AMM                     VARCHAR2(1)            null    ,
    ID_IMMOBILE                     NUMBER(15)             null    ,
    TIPO_IMMOBILE                   VARCHAR2(1)            null    ,
    PROGRESSIVO                     NUMBER(3)              null    ,
    TIPO_RECORD                     NUMBER(1)              null    ,
    PROGR_INDIRIZZO                 NUMBER(1)              null    ,
    TOPONIMO                        NUMBER(3)              null    ,
    INDIRIZZO                       VARCHAR2(50)           null    ,
    CIVICO1                         VARCHAR2(6)            null    ,
    CIVICO2                         VARCHAR2(6)            null    ,
    CIVICO3                         VARCHAR2(6)            null    ,
    COD_STRADA                      NUMBER(5)              null    ,
    INDIRIZZO_RIC                   VARCHAR2(50)           null    ,
    DOCUMENTO_ID                    NUMBER(10)             null    ,
    UTENTE                          VARCHAR2(8)            null    ,
    DATA_VARIAZIONE                 DATE                   null
)
/

comment on table CC_INDIRIZZI is 'CC_INDIRIZZI'
/

-- ============================================================
--   Index: CC_INDI_IMMO_IK
-- ============================================================
create index CC_INDI_IMMO_IK on CC_INDIRIZZI (ID_IMMOBILE asc, PROGRESSIVO asc, PROGR_INDIRIZZO asc, TIPO_IMMOBILE asc, CODICE_AMM asc, SEZIONE_AMM asc)
/

-- ============================================================
--   Index: CC_INDI_INDIRIZZO_IK
-- ============================================================
create index CC_INDI_INDIRIZZO_IK on CC_INDIRIZZI (INDIRIZZO_RIC asc)
/

-- ============================================================
--   Table: CC_PARTICELLE
-- ============================================================
create table CC_PARTICELLE
(
    CODICE_AMM                      VARCHAR2(4)            null    ,
    SEZIONE_AMM                     VARCHAR2(1)            null    ,
    ID_IMMOBILE                     NUMBER(15)             null    ,
    TIPO_IMMOBILE                   VARCHAR2(1)            null    ,
    PROGRESSIVO                     NUMBER(3)              null    ,
    TIPO_RECORD                     NUMBER(1)              null    ,
    FOGLIO                          NUMBER(5)              null    ,
    NUMERO                          VARCHAR2(5)            null    ,
    DENOMINATORE                    NUMBER(4)              null    ,
    SUBALTERNO                      VARCHAR2(4)            null    ,
    EDIFICIALITA                    VARCHAR2(1)            null    ,
    QUALITA                         NUMBER(3)              null    ,
    CLASSE                          VARCHAR2(2)            null    ,
    ETTARI                          NUMBER(5)              null    ,
    ARE                             NUMBER(2)              null    ,
    CENTIARE                        NUMBER(2)              null    ,
    FLAG_REDDITO                    VARCHAR2(1)            null    ,
    FLAG_PORZIONE                   VARCHAR2(1)            null    ,
    FLAG_DEDUZIONI                  VARCHAR2(1)            null    ,
    REDDITO_DOMINICALE_LIRE         NUMBER(9)              null    ,
    REDDITO_AGRARIO_LIRE            NUMBER(8)              null    ,
    REDDITO_DOMINICALE_EURO         NUMBER(12,3)           null    ,
    REDDITO_AGRARIO_EURO            NUMBER(11,3)           null    ,
    DATA_EFFICACIA                  VARCHAR2(8)            null    ,
    DATA_REGISTRAZIONE_ATTI         VARCHAR2(8)            null    ,
    TIPO_NOTA                       VARCHAR2(1)            null    ,
    NUMERO_NOTA                     VARCHAR2(6)            null    ,
    PROGRESSIVO_NOTA                VARCHAR2(3)            null    ,
    ANNO_NOTA                       NUMBER(4)              null    ,
    DATA_EFFICACIA_1                VARCHAR2(8)            null    ,
    DATA_REGISTRAZIONE_ATTI_1       VARCHAR2(8)            null    ,
    TIPO_NOTA_1                     VARCHAR2(1)            null    ,
    NUMERO_NOTA_1                   VARCHAR2(6)            null    ,
    PROGRESSIVO_NOTA_1              VARCHAR2(3)            null    ,
    ANNO_NOTA_1                     NUMBER(4)              null    ,
    PARTITA                         VARCHAR2(7)            null    ,
    ANNOTAZIONE                     VARCHAR2(200)          null    ,
    ID_MUTAZIONE_INIZIALE           NUMBER(9)              null    ,
    ID_MUTAZIONE_FINALE             NUMBER(9)              null    ,
    FOGLIO_RIC                      VARCHAR2(4)            null    ,
    NUMERO_RIC                      VARCHAR2(5)            null    ,
    SUBALTERNO_RIC                  VARCHAR2(4)            null    ,
    SEZIONE_RIC                     VARCHAR2(1)            null    ,
    ESTREMI_CATASTO                 VARCHAR2(20)           null    ,
    COD_CAUSALE_ATTO_GENERANTE      VARCHAR2(3)            null    ,
    DES_ATTO_GENERANTE              VARCHAR2(100)          null    ,
    COD_CAUSALE_ATTO_CONCLUSIVO     VARCHAR2(3)            null    ,
    DES_ATTO_CONCLUSIVO             VARCHAR2(100)          null    ,
    DOCUMENTO_ID                    NUMBER(10)             null    ,
    UTENTE                          VARCHAR2(8)            null    ,
    DATA_VARIAZIONE                 DATE                   null
)
/

comment on table CC_PARTICELLE is 'CC_PARTICELLE'
/

-- ============================================================
--   Index: CC_PART_IMMO_IK
-- ============================================================
create index CC_PART_IMMO_IK on CC_PARTICELLE (ID_IMMOBILE asc, PROGRESSIVO asc, TIPO_IMMOBILE asc, CODICE_AMM asc, SEZIONE_AMM asc)
/

-- ============================================================
--   Index: CC_PART_FNS_IK
-- ============================================================
create index CC_PART_FNS_IK on CC_PARTICELLE (FOGLIO_RIC asc, NUMERO_RIC asc, SUBALTERNO_RIC asc)
/

-- ============================================================
--   Index: CC_PART_ESTREMI_IK
-- ============================================================
create index CC_PART_ESTREMI_IK on CC_PARTICELLE (ESTREMI_CATASTO asc)
/

-- ============================================================
--   Table: CC_SOGGETTI
-- ============================================================
create table CC_SOGGETTI
(
    CODICE_AMM                      VARCHAR2(4)            null    ,
    SEZIONE_AMM                     VARCHAR2(1)            null    ,
    ID_SOGGETTO                     NUMBER(15)             null    ,
    TIPO_SOGGETTO                   VARCHAR2(1)            null    ,
    COGNOME                         VARCHAR2(50)           null    ,
    NOME                            VARCHAR2(50)           null    ,
    SESSO                           VARCHAR2(1)            null    ,
    DATA_NASCITA                    VARCHAR2(8)            null    ,
    LUOGO_NASCITA                   VARCHAR2(4)            null    ,
    CODICE_FISCALE                  VARCHAR2(16)           null    ,
    INDICAZIONI_SUPPLEMENTARI       VARCHAR2(100)          null    ,
    CODICE_AMM_2                    VARCHAR2(4)            null    ,
    SEZIONE_AMM_2                   VARCHAR2(1)            null    ,
    ID_SOGGETTO_2                   NUMBER(15)             null    ,
    TIPO_SOGGETTO_2                 VARCHAR2(1)            null    ,
    DENOMINAZIONE                   VARCHAR2(150)          null    ,
    SEDE                            VARCHAR2(4)            null    ,
    CODICE_FISCALE_2                NUMBER(11)             null    ,
    ID_SOGGETTO_RIC                 NUMBER(15)             null    ,
    COGNOME_NOME_RIC                VARCHAR2(150)          null    ,
    COD_FISCALE_RIC                 VARCHAR2(16)           null    ,
    DOCUMENTO_ID                    NUMBER(10)             null    ,
    UTENTE                          VARCHAR2(8)            null    ,
    DATA_VARIAZIONE                 DATE                   null
)
/

comment on table CC_SOGGETTI is 'CC_SOGGETTI'
/

-- ============================================================
--   Index: CC_SOGG_TISO_2_IK
-- ============================================================
create index CC_SOGG_TISO_2_IK on CC_SOGGETTI (TIPO_SOGGETTO_2 asc)
/

-- ============================================================
--   Index: CC_SOGG_IDSO_IK
-- ============================================================
create index CC_SOGG_IDSO_IK on CC_SOGGETTI (ID_SOGGETTO asc)
/

-- ============================================================
--   Index: CC_SOGG_IDSO_2_IK
-- ============================================================
create index CC_SOGG_IDSO_2_IK on CC_SOGGETTI (ID_SOGGETTO_2 asc)
/

-- ============================================================
--   Index: CC_SOGG_IDSO_RIC_IK
-- ============================================================
create index CC_SOGG_IDSO_RIC_IK on CC_SOGGETTI (ID_SOGGETTO_RIC asc)
/

-- ============================================================
--   Index: CC_SOGG_CONO_RIC_IK
-- ============================================================
create index CC_SOGG_CONO_RIC_IK on CC_SOGGETTI (COGNOME_NOME_RIC asc)
/

-- ============================================================
--   Index: CC_SOGG_COFI_RIC_IK
-- ============================================================
create index CC_SOGG_COFI_RIC_IK on CC_SOGGETTI (COD_FISCALE_RIC asc)
/

-- ============================================================
--   Table: CC_TITOLARITA
-- ============================================================
create table CC_TITOLARITA
(
    CODICE_AMM                      VARCHAR2(4)            null    ,
    SEZIONE_AMM                     VARCHAR2(1)            null    ,
    ID_SOGGETTO                     NUMBER(15)             null    ,
    TIPO_SOGGETTO                   VARCHAR2(1)            null    ,
    ID_IMMOBILE                     NUMBER(15)             null    ,
    TIPO_IMMOBILE                   VARCHAR2(1)            null    ,
    CODICE_DIRITTO                  VARCHAR2(3)            null    ,
    TITOLO_NON_CODIFICATO           VARCHAR2(200)          null    ,
    QUOTA_NUMERATORE                NUMBER(9)              null    ,
    QUOTA_DENOMINATORE              NUMBER(9)              null    ,
    REGIME                          VARCHAR2(1)            null    ,
    SOGGETTO_RIFERIMENTO            NUMBER(15)             null    ,
    DATA_VALIDITA                   VARCHAR2(8)            null    ,
    TIPO_NOTA                       VARCHAR2(1)            null    ,
    NUMERO_NOTA                     VARCHAR2(6)            null    ,
    PROGRESSIVO_NOTA                VARCHAR2(3)            null    ,
    ANNO_NOTA                       NUMBER(4)              null    ,
    DATA_REGISTRAZIONE_ATTI         VARCHAR2(8)            null    ,
    PARTITA                         VARCHAR2(7)            null    ,
    DATA_VALIDITA_2                 VARCHAR2(8)            null    ,
    TIPO_NOTA_2                     VARCHAR2(1)            null    ,
    NUMERO_NOTA_2                   VARCHAR2(6)            null    ,
    PROGRESSIVO_NOTA_2              VARCHAR2(3)            null    ,
    ANNO_NOTA_2                     NUMBER(4)              null    ,
    DATA_REGISTRAZIONE_ATTI_2       VARCHAR2(8)            null    ,
    ID_MUTAZIONE_INIZIALE           NUMBER(9)              null    ,
    ID_MUTAZIONE_FINALE             NUMBER(9)              null    ,
    ID_TITOLARITA                   NUMBER(15)             null    ,
    COD_CAUSALE_ATTO_GENERANTE      VARCHAR2(3)            null    ,
    DES_ATTO_GENERANTE              VARCHAR2(100)          null    ,
    COD_CAUSALE_ATTO_CONCLUSIVO     VARCHAR2(3)            null    ,
    DES_ATTO_CONCLUSIVO             VARCHAR2(100)          null    ,
    DOCUMENTO_ID                    NUMBER(10)             null    ,
    UTENTE                          VARCHAR2(8)            null    ,
    DATA_VARIAZIONE                 DATE                   null
)
/

comment on table CC_TITOLARITA is 'CC_TITOLARITA'
/

-- ============================================================
--   Index: CC_TITO_SOGG_IK
-- ============================================================
create index CC_TITO_SOGG_IK on CC_TITOLARITA (ID_SOGGETTO asc)
/

-- ============================================================
--   Index: CC_TITO_IMMO_IK
-- ============================================================
create index CC_TITO_IMMO_IK on CC_TITOLARITA (ID_IMMOBILE asc, TIPO_IMMOBILE asc, CODICE_AMM asc, SEZIONE_AMM asc)
/

-- ============================================================
--   Table: WRK_TRASMISSIONI
-- ============================================================
create table WRK_TRASMISSIONI
(
    NUMERO                          VARCHAR2(15)           not null,
    DATI                            VARCHAR2(4000)         null    ,
    DATI2                           VARCHAR2(4000)         null    ,
    DATI3                           VARCHAR2(4000)         null    ,
    DATI4                           VARCHAR2(4000)         null    ,
    DATI5                           VARCHAR2(4000)         null    ,
    DATI6                           VARCHAR2(4000)         null    ,
    DATI7                           VARCHAR2(4000)         null    ,
    DATI8                           VARCHAR2(4000)         null    ,
    DATI_CLOB                       CLOB                   null
)
/

comment on table WRK_TRASMISSIONI is 'Tabella di working generica.'
/

-- ============================================================
--   Index: WRK_TRASMISSIONI_IK
-- ============================================================
create index WRK_TRASMISSIONI_IK on WRK_TRASMISSIONI (NUMERO asc)
/

-- ============================================================
--   Table: WRK_BONIFICA_OGCO
-- ============================================================
create table WRK_BONIFICA_OGCO
(
    TIPO_TRIBUTO                    VARCHAR2(6)            null    ,
    COD_FISCALE                     VARCHAR2(16)           null    ,
    OGGETTO_PRATICA_RIF             NUMBER(10)             null
)
/

comment on table WRK_BONIFICA_OGCO is 'WRK_BONIFICA_OGCO'
/

-- ============================================================
--   Index: WBOG_OGPR_RIF_IK
-- ============================================================
create index WBOG_OGPR_RIF_IK on WRK_BONIFICA_OGCO (OGGETTO_PRATICA_RIF asc)
/

-- ============================================================
--   Table: WRK_BONIFICA_OGPR
-- ============================================================
create table WRK_BONIFICA_OGPR
(
    OGGETTO_PRATICA                 NUMBER(10)             not null,
    OGGETTO_PRATICA_RIF             NUMBER(10)             null    ,
    constraint WRK_BONIFICA_OGPR_PK primary key (OGGETTO_PRATICA)
)
/

comment on table WRK_BONIFICA_OGPR is 'WRK_BONIFICA_OGPR'
/

-- ============================================================
--   Table: TIPI_QUALITA
-- ============================================================
create table TIPI_QUALITA
(
    TIPO_QUALITA                    NUMBER(4)              not null,
    DESCRIZIONE                     VARCHAR2(60)           null    ,
    constraint TIPI_QUALITA_PK primary key (TIPO_QUALITA)
)
/

comment on table TIPI_QUALITA is 'TIQU - Tipi Qualita'
/

-- ============================================================
--   Table: COEFFICIENTI_CONTABILI
-- ============================================================
create table COEFFICIENTI_CONTABILI
(
    ANNO                            NUMBER(4)              not null,
    ANNO_COEFF                      NUMBER(4)              not null,
    COEFF                           NUMBER(6,2)            null    ,
    constraint COEFFICIENTI_CONTABILI_PK primary key (ANNO, ANNO_COEFF)
)
/

comment on table COEFFICIENTI_CONTABILI is 'COCO - Coefficienti Contabili'
/

-- ============================================================
--   Table: WRK_VERSAMENTI
-- ============================================================
create table WRK_VERSAMENTI
(
    PROGRESSIVO                     NUMBER                 not null,
    TIPO_TRIBUTO                    VARCHAR2(5)            not null,
    TIPO_INCASSO                    VARCHAR2(10)           not null,
    ANNO                            NUMBER(4)              null    ,
    RUOLO                           NUMBER(10)             null    ,
    COD_FISCALE                     VARCHAR2(16)           null    ,
    COGNOME_NOME                    VARCHAR2(60)           null    ,
    RATA                            NUMBER(2)              null    ,
    IMPORTO_VERSATO                 NUMBER(15,2)           null    ,
    DATA_SCADENZA                   DATE                   null    ,
    CAUSALE                         VARCHAR2(200)          null    ,
    DISPOSIZIONE                    NUMBER                 null    ,
    DATA_VARIAZIONE                 DATE                   null    ,
    NOTE                            VARCHAR2(2000)         null    ,
    TIPO_VERSAMENTO                 VARCHAR2(1)            null    ,
    UFFICIO_PT                      VARCHAR2(30)           null    ,
    DATA_PAGAMENTO                  DATE                   null    ,
    AB_PRINCIPALE                   NUMBER(15,2)           null    ,
    TERRENI_AGRICOLI                NUMBER(15,2)           null    ,
    AREE_FABBRICABILI               NUMBER(15,2)           null    ,
    ALTRI_FABBRICATI                NUMBER(15,2)           null    ,
    DATA_REG                        DATE                   null    ,
    DETRAZIONE                      NUMBER(15,2)           null    ,
    FABBRICATI                      NUMBER(4)              null    ,
    FLAG_CONTRIBUENTE               VARCHAR2(1)            null
        constraint WRK_VERSAMENT_FLAG_CONTRIBU_CC check (
            FLAG_CONTRIBUENTE is null or (FLAG_CONTRIBUENTE in ('S'))),
    SANZIONE_RAVVEDIMENTO           VARCHAR2(1)            null
        constraint WRK_VERSAMENT_SANZIONE_RAVV_CC check (
            SANZIONE_RAVVEDIMENTO is null or (SANZIONE_RAVVEDIMENTO in ('O','I','N'))),
    RURALI                          NUMBER(15,2)           null    ,
    TERRENI_ERARIALE                NUMBER(15,2)           null    ,
    AREE_ERARIALE                   NUMBER(15,2)           null    ,
    ALTRI_ERARIALE                  NUMBER(15,2)           null    ,
    NUM_FABBRICATI_AB               NUMBER(4)              null    ,
    NUM_FABBRICATI_RURALI           NUMBER(4)              null    ,
    NUM_FABBRICATI_ALTRI            NUMBER(4)              null    ,
    TERRENI_COMUNE                  NUMBER(15,2)           null    ,
    AREE_COMUNE                     NUMBER(15,2)           null    ,
    ALTRI_COMUNE                    NUMBER(15,2)           null    ,
    NUM_FABBRICATI_TERRENI          NUMBER(4)              null    ,
    NUM_FABBRICATI_AREE             NUMBER(4)              null    ,
    FABBRICATI_D                    NUMBER(15,2)           null    ,
    FABBRICATI_D_ERARIALE           NUMBER(15,2)           null    ,
    FABBRICATI_D_COMUNE             NUMBER(15,2)           null    ,
    NUM_FABBRICATI_D                NUMBER(4)              null    ,
    RURALI_ERARIALE                 NUMBER(15,2)           null    ,
    RURALI_COMUNE                   NUMBER(15,2)           null    ,
    MAGGIORAZIONE_TARES             NUMBER(15,2)           null    ,
    IDENTIFICATIVO_OPERAZIONE       VARCHAR2(18)           null    ,
    DOCUMENTO_ID                    NUMBER(10)             null    ,
    FLAG_OK                         VARCHAR2(1)            null
        constraint WRK_VERSAMENT_FLAG_OK_CC check (
            FLAG_OK is null or (FLAG_OK in ('S'))),
    RATEAZIONE                      VARCHAR2(4)            null    ,
    IMPOSTA                         NUMBER(15,2)           null    ,
    SANZIONI_1                      NUMBER(15,2)           null    ,
    SANZIONI_2                      NUMBER(15,2)           null    ,
    INTERESSI                       NUMBER(15,2)           null    ,
    FABBRICATI_MERCE                NUMBER(15,2)           null    ,
    NUM_FABBRICATI_MERCE            NUMBER(4)              null    ,
    NOTE_VERSAMENTO                 VARCHAR2(2000)         null    ,
    ADDIZIONALE_PRO                 NUMBER(15,2)           null    ,
    SANZIONI_ADD_PRO                NUMBER(15,2)           null    ,
    INTERESSI_ADD_PRO               NUMBER(15,2)           null    ,
    constraint WRK_VERSAMENTI_PK primary key (PROGRESSIVO)
)
/

comment on table WRK_VERSAMENTI is 'WRK Versamenti'
/

-- ============================================================
--   Table: CODICI_ATTIVITA
-- ============================================================
create table CODICI_ATTIVITA
(
    COD_ATTIVITA                    VARCHAR2(5)            not null,
    DESCRIZIONE                     VARCHAR2(250)          null    ,
    FLAG_REALE                      VARCHAR2(1)            null
        constraint CODICI_ATTIVI_FLAG_REALE_CC check (
            FLAG_REALE is null or (FLAG_REALE in ('S'))),
    constraint CODICI_ATTIVITA_PK primary key (COD_ATTIVITA)
)
/

comment on table CODICI_ATTIVITA is 'COAT - Codici Attivita'
/

-- ============================================================
--   Table: COMPONENTI_SUPERFICIE
-- ============================================================
create table COMPONENTI_SUPERFICIE
(
    ANNO                            NUMBER(4)              not null,
    NUMERO_FAMILIARI                NUMBER(4)              not null,
    DA_CONSISTENZA                  NUMBER(8,2)            null    ,
    A_CONSISTENZA                   NUMBER(8,2)            null    ,
    constraint COMPONENTI_SUPERFICIE_PK primary key (ANNO, NUMERO_FAMILIARI)
)
/

comment on table COMPONENTI_SUPERFICIE is 'COSU - Componenti Superficie'
/

-- ============================================================
--   Table: NUMERAZIONE_FATTURE
-- ============================================================
create table NUMERAZIONE_FATTURE
(
    ANNO                            NUMBER(4)              not null,
    NUMERO                          NUMBER(8)              not null,
    DATA_EMISSIONE                  DATE                   null    ,
    constraint NUMERAZIONE_FATTURE_PK primary key (ANNO, NUMERO)
)
/

comment on table NUMERAZIONE_FATTURE is 'NUFA - Numerazione Fatture'
/

-- ============================================================
--   Table: WRK_GENERALE
-- ============================================================
create table WRK_GENERALE
(
    TIPO_TRATTAMENTO                VARCHAR2(20)           not null,
    ANNO                            NUMBER(4)              not null,
    PROGRESSIVO                     NUMBER                 not null,
    DATI                            VARCHAR2(2000)         null    ,
    NOTE                            VARCHAR2(2000)         null    ,
    constraint WRK_GENERALE_PK primary key (TIPO_TRATTAMENTO, ANNO, PROGRESSIVO)
)
/

comment on table WRK_GENERALE is 'WRK Generale'
/

-- ============================================================
--   Table: CC_IDENTIFICATIVI
-- ============================================================
create table CC_IDENTIFICATIVI
(
    CODICE_AMM                      VARCHAR2(4)            null    ,
    SEZIONE_AMM                     VARCHAR2(1)            null    ,
    ID_IMMOBILE                     NUMBER(15)             null    ,
    TIPO_IMMOBILE                   VARCHAR2(1)            null    ,
    PROGRESSIVO                     NUMBER(3)              null    ,
    TIPO_RECORD                     NUMBER(1)              null    ,
    PROGR_IDENTIFICATIVO            NUMBER(3)              null    ,
    SEZIONE                         VARCHAR2(3)            null    ,
    FOGLIO                          VARCHAR2(4)            null    ,
    NUMERO                          VARCHAR2(5)            null    ,
    DENOMINATORE                    NUMBER(4)              null    ,
    SUBALTERNO                      VARCHAR2(4)            null    ,
    EDIFICIALITA                    VARCHAR2(1)            null    ,
    SEZIONE_RIC                     VARCHAR2(3)            null    ,
    FOGLIO_RIC                      VARCHAR2(4)            null    ,
    NUMERO_RIC                      VARCHAR2(5)            null    ,
    SUBALTERNO_RIC                  VARCHAR2(4)            null    ,
    ESTREMI_CATASTO                 VARCHAR2(20)           null    ,
    DOCUMENTO_ID                    NUMBER(10)             null    ,
    UTENTE                          VARCHAR2(8)            null    ,
    DATA_VARIAZIONE                 DATE                   null
)
/

comment on table CC_IDENTIFICATIVI is 'CC_IDENTIFICATIVI'
/

-- ============================================================
--   Index: CC_IDEN_IMMO_IK
-- ============================================================
create index CC_IDEN_IMMO_IK on CC_IDENTIFICATIVI (ID_IMMOBILE asc, PROGRESSIVO asc, TIPO_IMMOBILE asc, CODICE_AMM asc)
/

-- ============================================================
--   Index: CC_IDEN_FNS_IK
-- ============================================================
create index CC_IDEN_FNS_IK on CC_IDENTIFICATIVI (FOGLIO_RIC asc, NUMERO_RIC asc, SUBALTERNO_RIC asc)
/

-- ============================================================
--   Index: CC_IDEN_ESTREMI_IK
-- ============================================================
create index CC_IDEN_ESTREMI_IK on CC_IDENTIFICATIVI (ESTREMI_CATASTO asc)
/

-- ============================================================
--   Index: CC_IDEN_SEZIONE_IK
-- ============================================================
create index CC_IDEN_SEZIONE_IK on CC_IDENTIFICATIVI (SEZIONE_RIC asc)
/

-- ============================================================
--   Table: V_CONCESSIONI
-- ============================================================
create table V_CONCESSIONI
(
    CPRAT                           VARCHAR2(16)           null    ,
    NPRAT                           VARCHAR2(16)           null    ,
    DATCRE                          DATE                   null    ,
    DPROTD                          DATE                   null    ,
    NPROT                           VARCHAR2(10)           null    ,
    OGGETC                          VARCHAR2(2000)         null    ,
    TIPRAT                          NUMBER(12)             null    ,
    DRICON                          DATE                   null    ,
    NCONC                           VARCHAR2(20)           null    ,
    DINLAV                          DATE                   null    ,
    DULLAV                          DATE                   null    ,
    CVIADI                          VARCHAR2(10)           null    ,
    VIAPIA                          VARCHAR2(60)           null    ,
    NUMERO                          VARCHAR2(10)           null    ,
    ESPON                           VARCHAR2(10)           null    ,
    CORTIL                          VARCHAR2(10)           null    ,
    SCALA                           VARCHAR2(10)           null    ,
    PIANO                           VARCHAR2(10)           null    ,
    INTERN                          VARCHAR2(10)           null    ,
    TIPCIV                          NUMBER(7)              null    ,
    TIP_INT                         NUMBER(2)              null    ,
    CODINT                          VARCHAR2(16)           null    ,
    NOMINT                          VARCHAR2(61)           null    ,
    CFUTE                           VARCHAR2(16)           null    ,
    PIVAUTE                         VARCHAR2(16)           null
)
/

comment on table V_CONCESSIONI is 'V_CONCESSIONI'
/

-- ============================================================
--   Table: FUNZIONI
-- ============================================================
create table FUNZIONI
(
    FUNZIONE                        VARCHAR2(40)           not null,
    DESCRIZIONE                     VARCHAR2(200)          not null,
    FLAG_VISIBILE                   VARCHAR2(1)            null
        constraint FUNZIONI_FLAG_VISIBILE_CC check (
            FLAG_VISIBILE is null or (FLAG_VISIBILE in ('S'))),
    constraint FUNZIONI_PK primary key (FUNZIONE)
)
/

comment on table FUNZIONI is 'FUNZIONI'
/

-- ============================================================
--   Table: INSTALLAZIONE_PARAMETRI
-- ============================================================
create table INSTALLAZIONE_PARAMETRI
(
    PARAMETRO                       VARCHAR2(10)           not null,
    VALORE                          VARCHAR2(2000)         null    ,
    DESCRIZIONE                     VARCHAR2(200)          null    ,
    constraint INSTALLAZIONE_PARAMETRI_PK primary key (PARAMETRO)
)
/

comment on table INSTALLAZIONE_PARAMETRI is 'INPA - Installazione Parametri'
/

-- ============================================================
--   Table: DETRAZIONI_FIGLI_CTR
-- ============================================================
create table DETRAZIONI_FIGLI_CTR
(
    COD_FISCALE                     VARCHAR2(16)           not null,
    ANNO                            NUMBER(4)              not null,
    DATA_RIFERIMENTO                DATE                   not null,
    NUMERO_FIGLI                    NUMBER(2)              null    ,
    DETRAZIONE                      NUMBER(15,2)           null    ,
    DETRAZIONE_ACCONTO              NUMBER(15,2)           null    ,
    UTENTE                          VARCHAR2(8)            null    ,
    DATA_VARIAZIONE                 DATE                   null    ,
    NOTE                            VARCHAR2(2000)         null    ,
    constraint DETRAZIONI_FIGLI_CTR_PK primary key (COD_FISCALE, ANNO, DATA_RIFERIMENTO)
)
/

comment on table DETRAZIONI_FIGLI_CTR is 'DEFC - Detrazione Figli Controllo'
/

-- ============================================================
--   Table: CAP_VIARIO
-- ============================================================
create table CAP_VIARIO
(
    COD_PROVINCIA                   NUMBER(3)              not null,
    COD_COMUNE                      NUMBER(3)              not null,
    DESCRIZIONE                     VARCHAR2(30)           null    ,
    SIGLA_PROVINCIA                 VARCHAR2(10)           null    ,
    CAP                             NUMBER(5)              null    ,
    DA_CAP                          NUMBER(5)              null    ,
    A_CAP                           NUMBER(5)              null    ,
    CAP_MUNICIPIO                   VARCHAR2(5)            null    ,
    NOTE                            VARCHAR2(2000)         null    ,
    constraint CAP_VIARIO_PK primary key (COD_PROVINCIA, COD_COMUNE)
)
/

comment on table CAP_VIARIO is 'CAVI - Cap Viario'
/

-- ============================================================
--   Table: COEFF_DOMESTICI_AREA
-- ============================================================
create table COEFF_DOMESTICI_AREA
(
    AREA                            VARCHAR2(20)           not null
        constraint COEFF_DOMESTI_AREA_CC check (
            AREA in ('NORD','CENTRO','SUD')),
    NUMERO_FAMILIARI                NUMBER(2)              not null,
    COEFF_ADATTAMENTO               NUMBER(6,4)            not null,
    COEFF_ADATTAMENTO_SUP           NUMBER(6,4)            null    ,
    COEFF_PRODUTTIVITA_MIN          NUMBER(6,4)            not null,
    COEFF_PRODUTTIVITA_MAX          NUMBER(6,4)            null    ,
    COEFF_PRODUTTIVITA_MED          NUMBER(6,4)            not null,
    constraint COEFF_DOMESTICI_AREA_PK primary key (AREA, NUMERO_FAMILIARI)
)
/

comment on table COEFF_DOMESTICI_AREA is 'CODA - Coefficienti Domestici Aree'
/

-- ============================================================
--   Table: COEFF_NON_DOMESTICI_AREA
-- ============================================================
create table COEFF_NON_DOMESTICI_AREA
(
    TRIBUTO                         NUMBER(4)              not null,
    TIPO_COMUNE                     VARCHAR2(3)            not null
        constraint COEFF_NON_DOM_TIPO_COMUNE_CC check (
            TIPO_COMUNE in ('INF','SUP')),
    AREA                            VARCHAR2(20)           not null
        constraint COEFF_NON_DOM_AREA_CC check (
            AREA in ('NORD','CENTRO','SUD')),
    CATEGORIA                       NUMBER(4)              not null,
    COEFF_POTENZIALE_MIN            NUMBER(6,4)            not null,
    COEFF_POTENZIALE_MAX            NUMBER(6,4)            not null,
    COEFF_PRODUZIONE_MIN            NUMBER(6,4)            not null,
    COEFF_PRODUZIONE_MAX            NUMBER(6,4)            not null,
    constraint COEFF_NON_DOMESTICI_AREA_PK primary key (TRIBUTO, TIPO_COMUNE, AREA, CATEGORIA)
)
/

comment on table COEFF_NON_DOMESTICI_AREA is 'CNDA - Coefficienti Non Domestici Area'
/

-- ============================================================
--   Table: WRK_PIANO_FINANZIARIO
-- ============================================================
create table WRK_PIANO_FINANZIARIO
(
    CODICE                          VARCHAR2(10)           not null,
    PROGRESSIVO                     NUMBER                 not null,
    ANNO                            NUMBER(4)              not null,
    VALORE                          VARCHAR2(100)          null    ,
    constraint WRK_PIANO_FINANZIARIO_PK primary key (CODICE, PROGRESSIVO, ANNO)
)
/

comment on table WRK_PIANO_FINANZIARIO is 'Tabella di lavoro per il Piano Finanziario'
/

-- ============================================================
--   Table: CC_DIRITTI
-- ============================================================
create table CC_DIRITTI
(
    CODICE_DIRITTO                  VARCHAR2(3)            not null,
    DESCRIZIONE                     VARCHAR2(100)          null    ,
    constraint CC_DIRITTI_PK primary key (CODICE_DIRITTO)
)
/

comment on table CC_DIRITTI is 'CC_DIRITTI'
/

-- ============================================================
--   Table: RIFERIMENTI_OGGETTO_BK
-- ============================================================
create table RIFERIMENTI_OGGETTO_BK
(
    OGGETTO                         NUMBER(10)             not null,
    INIZIO_VALIDITA                 DATE                   not null,
    SEQUENZA                        NUMBER(4)              not null,
    FINE_VALIDITA                   DATE                   not null,
    DA_ANNO                         NUMBER(4)              not null,
    A_ANNO                          NUMBER(4)              not null,
    RENDITA                         NUMBER(15,2)           not null,
    ANNO_RENDITA                    NUMBER(4)              null    ,
    CATEGORIA_CATASTO               VARCHAR2(3)            null    ,
    CLASSE_CATASTO                  VARCHAR2(2)            null    ,
    DATA_REG                        DATE                   null    ,
    DATA_REG_ATTI                   DATE                   null    ,
    UTENTE_RIOG                     VARCHAR2(8)            null    ,
    DATA_VARIAZIONE_RIOG            DATE                   null    ,
    NOTE_RIOG                       VARCHAR2(2000)         null    ,
    UTENTE                          VARCHAR2(8)            null    ,
    DATA_ORA_VARIAZIONE             DATE                   null    ,
    constraint RIFERIMENTI_OGGETTO_BK_PK primary key (OGGETTO, INIZIO_VALIDITA, SEQUENZA)
)
/

comment on table RIFERIMENTI_OGGETTO_BK is 'RIOB - RIFERIMENTI_OGGETTO_BK'
/

-- ============================================================
--   Table: WRK_POPOLAMENTO_TASI_IMU
-- ============================================================
create table WRK_POPOLAMENTO_TASI_IMU
(
    ID                              NUMBER                 not null,
    COD_FISCALE                     VARCHAR2(16)           not null,
    ANNO                            NUMBER                 null    ,
    PRATICA_IMU                     NUMBER                 null    ,
    PRATICA_TASI                    NUMBER                 null    ,
    OGGETTO                         NUMBER                 null    ,
    TIPO                            NUMBER                 null    ,
    DESCRIZIONE                     VARCHAR2(2000)         null    ,
    COD_FISCALE_CONTITOLARE         VARCHAR2(16)           null    ,
    UTENTE                          VARCHAR2(8)            null    ,
    DATA_ELABORAZIONE               DATE                   default SYSDATE null    ,
    constraint WRK_POPOLAMENTO_TASI_IMU_PK primary key (ID)
)
/

comment on table WRK_POPOLAMENTO_TASI_IMU is 'WPTI - WRK_POPOLAMENTO_TASI_IMU'
/

-- ============================================================
--   Index: WPTI_CF_DATA_IK
-- ============================================================
create index WPTI_CF_DATA_IK on WRK_POPOLAMENTO_TASI_IMU (COD_FISCALE asc, DATA_ELABORAZIONE asc)
/

-- ============================================================
--   Index: WPTI_DATA_IK
-- ============================================================
create index WPTI_DATA_IK on WRK_POPOLAMENTO_TASI_IMU (DATA_ELABORAZIONE asc)
/

-- ============================================================
--   Table: WRK_NOTAI_CF
-- ============================================================
create table WRK_NOTAI_CF
(
    DOCUMENTO_ID                    NUMBER(10)             not null,
    COD_FISCALE                     VARCHAR2(16)           not null,
    ANNO                            NUMBER(4)              null    ,
    FLAG_TRATTATO                   VARCHAR2(1)            null
        constraint WRK_NOTAI_CF_FLAG_TRATTATO_CC check (
            FLAG_TRATTATO is null or (FLAG_TRATTATO in ('S'))),
    constraint WRK_NOTAI_CF_PK primary key (DOCUMENTO_ID, COD_FISCALE)
)
/

comment on table WRK_NOTAI_CF is 'Wrk Notai CF'
/

-- ============================================================
--   Table: COMPONENTI_SACCHI
-- ============================================================
create table COMPONENTI_SACCHI
(
    ANNO                            NUMBER(4)              not null,
    NUMERO_FAMILIARI                NUMBER(4)              not null,
    DA_SACCHI                       NUMBER(4)              not null,
    A_SACCHI                        NUMBER(4)              null    ,
    PERC_SCONTO                     NUMBER(6,2)            null    ,
    NOTE                            VARCHAR2(2000)         null    ,
    constraint COMPONENTI_SACCHI_PK primary key (ANNO, NUMERO_FAMILIARI, DA_SACCHI)
)
/

comment on table COMPONENTI_SACCHI is 'COSA - Componenti Sacchi'
/

-- ============================================================
--   Table: WEB_CC_CODICI_DIRITTO
-- ============================================================
create table WEB_CC_CODICI_DIRITTO
(
    CODICE                          VARCHAR2(3)            not null,
    DESCRIZIONE                     VARCHAR2(100)          not null,
    VERSION                         NUMBER(10)             not null,
    constraint WEB_CC_CODICI_DIRITTO_PK primary key (CODICE)
)
/

comment on table WEB_CC_CODICI_DIRITTO is 'WEB_CC_CODICI_DIRITTO'
/

-- ============================================================
--   Table: WEB_CC_CODICI_QUALITA
-- ============================================================
create table WEB_CC_CODICI_QUALITA
(
    ID_CODICE_QUALITA               NUMBER(3)              not null,
    DESCRIZIONE                     VARCHAR2(100)          not null,
    VERSION                         NUMBER(10)             not null,
    constraint WEB_CC_CODICI_QUALITA_PK primary key (ID_CODICE_QUALITA)
)
/

comment on table WEB_CC_CODICI_QUALITA is 'WEB_CC_CODICI_QUALITA'
/

-- ============================================================
--   Table: AFC_SCHEDULAZIONI
-- ============================================================
create table AFC_SCHEDULAZIONI
(
    ID_SCHEDULAZIONE                NUMBER(10)             not null,
    VERSION                         NUMBER(10)             not null,
    CODICE                          VARCHAR2(200)          not null,
    CRON_EXPRESSION                 VARCHAR2(200)          null    ,
    DESCRIZIONE                     VARCHAR2(200)          null    ,
    DATA_MODIFICA                   DATE                   not null,
    REPEAT_COUNT                    NUMBER(10)             null    ,
    REPEAT_INTERVAL                 NUMBER(10)             null    ,
    constraint AFC_SCHEDULAZIONI_PK primary key (ID_SCHEDULAZIONE)
)
/

comment on table AFC_SCHEDULAZIONI is 'AFC_SCHEDULAZIONI'
/

-- ============================================================
--   Index: AFSC_CODICE_UK
-- ============================================================
create unique index AFSC_CODICE_UK on AFC_SCHEDULAZIONI (CODICE asc)
/

-- ============================================================
--   Table: TARIFFE_DOMESTICHE
-- ============================================================
create table TARIFFE_DOMESTICHE
(
    ANNO                            NUMBER(4)              not null,
    NUMERO_FAMILIARI                NUMBER(2)              not null,
    TARIFFA_QUOTA_FISSA             NUMBER(11,5)           not null,
    TARIFFA_QUOTA_VARIABILE         NUMBER(11,5)           not null,
    TARIFFA_QUOTA_FISSA_NO_AP       NUMBER(11,5)           null    ,
    TARIFFA_QUOTA_VARIABILE_NO_AP   NUMBER(11,5)           null    ,
    SVUOTAMENTI_MINIMI              NUMBER(4)              null    ,
    constraint TARIFFE_DOMESTICHE_PK primary key (ANNO, NUMERO_FAMILIARI)
)
/

comment on table TARIFFE_DOMESTICHE is 'TADO - Tariffe Domestiche'
/

-- ============================================================
--   Table: WRK_SEGNALAZIONI
-- ============================================================
create table WRK_SEGNALAZIONI
(
    PROGR_ELAB                      NUMBER(10)             null    ,
    PROGR_RIGA                      NUMBER(10)             null    ,
    COD_FISCALE                     VARCHAR2(16)           null    ,
    OGGETTO_PRATICA                 NUMBER(10)             null    ,
    MESSAGGIO                       VARCHAR2(2000)         null
)
/

comment on table WRK_SEGNALAZIONI is 'WRSE - WRK Segnalazioni'
/

-- ============================================================
--   Index: WRK_SEGN_IK
-- ============================================================
create index WRK_SEGN_IK on WRK_SEGNALAZIONI (PROGR_ELAB asc, PROGR_RIGA asc)
/

-- ============================================================
--   Index: WRK_SEGN_IK2
-- ============================================================
create index WRK_SEGN_IK2 on WRK_SEGNALAZIONI (COD_FISCALE asc, OGGETTO_PRATICA asc)
/

-- ============================================================
--   Table: PAGONLINE_LOG
-- ============================================================
create table PAGONLINE_LOG
(
    ID                              NUMBER                 not null,
    DATA_ORA                        DATE                   null    ,
    OPERAZIONE                      VARCHAR2(100)          null    ,
    NOTE                            VARCHAR2(4000)         null    ,
    constraint PAGONLINE_LOG_PK primary key (ID)
)
/

comment on table PAGONLINE_LOG is 'PALO - Pagonline Log'
/

-- ============================================================
--   Table: CC_TIPI_NOTA
-- ============================================================
create table CC_TIPI_NOTA
(
    TIPO_CATASTO                    VARCHAR2(1)            not null,
    TIPO_NOTA                       VARCHAR2(1)            not null,
    DESCRIZIONE                     VARCHAR2(200)          null    ,
    constraint CC_TIPI_NOTA_PK primary key (TIPO_CATASTO, TIPO_NOTA)
)
/

comment on table CC_TIPI_NOTA is 'CC_TIPI_NOTA'
/

-- ============================================================
--   Table: CC_QUALITA
-- ============================================================
create table CC_QUALITA
(
    QUALITA                         NUMBER(3)              not null,
    DESCRIZIONE                     VARCHAR2(200)          null    ,
    constraint CC_QUALITA_PK primary key (QUALITA)
)
/

comment on table CC_QUALITA is 'CC_QUALITA'
/

-- ============================================================
--   Table: GIS_VISTE
-- ============================================================
create table GIS_VISTE
(
    ID                              NUMBER(10)             not null,
    VISTA                           VARCHAR2(30)           not null,
    FUNZIONE                        VARCHAR2(255)          not null,
    FILTRO                          VARCHAR2(255)          null    ,
    DISABILITATO                    VARCHAR2(1)            null    ,
    constraint GIS_VISTE_PK primary key (ID)
)
/

comment on table GIS_VISTE is 'GIVI GIS Viste'
/

-- ============================================================
--   Table: CONTRIBUTI_IFEL
-- ============================================================
create table CONTRIBUTI_IFEL
(
    ANNO                            NUMBER(4)              not null,
    ALIQUOTA                        NUMBER(5,4)            null    ,
    constraint CONTRIBUTI_IFEL_PK primary key (ANNO)
)
/

comment on table CONTRIBUTI_IFEL is 'COIF - Contributi IFEL'
/

-- ============================================================
--   Table: FORNITURE_AE
-- ============================================================
create table FORNITURE_AE
(
    DOCUMENTO_ID                    NUMBER(10)             not null,
    PROGRESSIVO                     NUMBER(8)              not null,
    TIPO_RECORD                     VARCHAR2(2)            null    ,
    DATA_FORNITURA                  DATE                   null    ,
    PROGR_FORNITURA                 NUMBER(2)              null    ,
    DATA_RIPARTIZIONE               DATE                   null    ,
    PROGR_RIPARTIZIONE              NUMBER(2)              null    ,
    DATA_BONIFICO                   DATE                   null    ,
    PROGR_DELEGA                    NUMBER(6)              null    ,
    PROGR_RIGA                      NUMBER(2)              null    ,
    COD_ENTE                        NUMBER(5)              null    ,
    TIPO_ENTE                       VARCHAR2(1)            null    ,
    CAB                             NUMBER(5)              null    ,
    COD_FISCALE                     VARCHAR2(16)           null    ,
    FLAG_ERR_COD_FISCALE            NUMBER(1)              null    ,
    DATA_RISCOSSIONE                DATE                   null    ,
    COD_ENTE_COMUNALE               VARCHAR2(4)            null    ,
    COD_TRIBUTO                     VARCHAR2(4)            null    ,
    FLAG_ERR_COD_TRIBUTO            NUMBER(1)              null    ,
    RATEAZIONE                      NUMBER(4)              null    ,
    ANNO_RIF                        NUMBER(4)              null    ,
    FLAG_ERR_ANNO                   NUMBER(1)              null    ,
    COD_VALUTA                      VARCHAR2(3)            null    ,
    IMPORTO_DEBITO                  NUMBER(15,2)           null    ,
    IMPORTO_CREDITO                 NUMBER(15,2)           null    ,
    RAVVEDIMENTO                    NUMBER(1)              null    ,
    IMMOBILI_VARIATI                NUMBER(1)              null    ,
    ACCONTO                         NUMBER(1)              null    ,
    SALDO                           NUMBER(1)              null    ,
    NUM_FABBRICATI                  NUMBER(3)              null    ,
    FLAG_ERR_DATI                   NUMBER(1)              null    ,
    DETRAZIONE                      NUMBER(15,2)           null    ,
    COGNOME_DENOMINAZIONE           VARCHAR2(60)           null    ,
    COD_FISCALE_ORIG                VARCHAR2(16)           null    ,
    NOME                            VARCHAR2(20)           null    ,
    SESSO                           VARCHAR2(1)            null    ,
    DATA_NAS                        DATE                   null    ,
    COMUNE_STATO                    VARCHAR2(25)           null    ,
    PROVINCIA                       VARCHAR2(2)            null    ,
    TIPO_IMPOSTA                    VARCHAR2(3)            null    ,
    COD_FISCALE_2                   VARCHAR2(16)           null    ,
    COD_IDENTIFICATIVO_2            VARCHAR2(2)            null    ,
    ID_OPERAZIONE                   VARCHAR2(18)           null    ,
    STATO                           VARCHAR2(1)            null    ,
    COD_ENTE_BENEFICIARIO           VARCHAR2(4)            null    ,
    IMPORTO_ACCREDITO               NUMBER(15,2)           null    ,
    DATA_MANDATO                    DATE                   null    ,
    PROGR_MANDATO                   NUMBER(2)              null    ,
    IMPORTO_RECUPERO                NUMBER(15,2)           null    ,
    PERIODO_RIPARTIZIONE_ORIG       NUMBER(6)              null    ,
    PROGR_RIPARTIZIONE_ORIG         NUMBER(2)              null    ,
    DATA_BONIFICO_ORIG              DATE                   null    ,
    TIPO_RECUPERO                   VARCHAR2(3)            null    ,
    DES_RECUPERO                    VARCHAR2(200)          null    ,
    IMPORTO_ANTICIPAZIONE           NUMBER(15,2)           null    ,
    CRO                             NUMBER(11)             null    ,
    DATA_ACCREDITAMENTO             DATE                   null    ,
    DATA_RIPARTIZIONE_ORIG          DATE                   null    ,
    IBAN                            VARCHAR2(34)           null    ,
    SEZIONE_CONTO_TU                VARCHAR2(3)            null    ,
    NUMERO_CONTO_TU                 NUMBER(6)              null    ,
    COD_MOVIMENTO                   NUMBER(14)             null    ,
    DES_MOVIMENTO                   VARCHAR2(45)           null    ,
    DATA_STORNO_SCARTO              DATE                   null    ,
    DATA_ELABORAZIONE_NUOVA         DATE                   null    ,
    PROGR_ELABORAZIONE_NUOVA        NUMBER(2)              null    ,
    TIPO_OPERAZIONE                 VARCHAR2(1)            null    ,
    DATA_OPERAZIONE                 DATE                   null    ,
    TIPO_TRIBUTO                    VARCHAR2(5)            null    ,
    DESCRIZIONE_TITR                VARCHAR2(5)            null    ,
    ANNO_ACC                        NUMBER(4)              null    ,
    NUMERO_ACC                      NUMBER(5)              null    ,
    NUMERO_PROVVISORIO              VARCHAR2(10)           null    ,
    DATA_PROVVISORIO                DATE                   null    ,
    IMPORTO_NETTO                   NUMBER(15,2)           null    ,
    IMPORTO_IFEL                    NUMBER(15,2)           null    ,
    IMPORTO_LORDO                   NUMBER(15,2)           null    ,
    COD_PROVINCIA                   NUMBER(3)              null    ,
    constraint FORNITURE_AE_PK primary key (DOCUMENTO_ID, PROGRESSIVO)
)
/

comment on table FORNITURE_AE is 'FOAE - Forniture AE'
/

-- ============================================================
--   Table: BENEFICIARI_TRIBUTO
-- ============================================================
create table BENEFICIARI_TRIBUTO
(
    TRIBUTO_F24                     VARCHAR2(4)            not null,
    COD_FISCALE                     VARCHAR2(16)           not null,
    INTESTATARIO                    VARCHAR2(100)          not null,
    IBAN                            VARCHAR2(34)           not null,
    TASSONOMIA                      VARCHAR2(20)           not null,
    TASSONOMIA_ANNI_PREC            VARCHAR2(20)           null    ,
    CAUSALE_QUOTA                   VARCHAR2(100)          null    ,
    DES_METADATA                    VARCHAR2(100)          null    ,
    constraint BENEFICIARI_TRIBUTO_PK primary key (TRIBUTO_F24, COD_FISCALE)
)
/

comment on table BENEFICIARI_TRIBUTO is 'BETR - Beneficiari Tributo'
/

-- ============================================================
--   Table: RAVVEDIMENTO_PARAMETRI
-- ============================================================
create table RAVVEDIMENTO_PARAMETRI
(
    RAVVEDIMENTO_PARAMETRO          NUMBER(10)             not null,
    DATA_RAVVEDIMENTO               DATE                   not null,
    TIPO_TRIBUTO                    VARCHAR2(5)            not null,
    ANNO                            NUMBER(4)              not null,
    constraint PK1 primary key (RAVVEDIMENTO_PARAMETRO)
)
/

comment on table RAVVEDIMENTO_PARAMETRI is 'RAVVEDIMENTO_PARAMETRI'
/

-- ============================================================
--   Table: WS_LOG
-- ============================================================
create table WS_LOG
(
    ID                              NUMBER(10)             not null,
    TIPO                            VARCHAR2(20)           not null,
    DATA                            DATE                   not null,
    LOG_RICHIESTA                   CLOB                   null    ,
    LOG_RISPOSTA                    CLOB                   null    ,
    TIPO_CALLBACK                   VARCHAR2(30)           null    ,
    ID_COMUNICAZIONE                NUMBER(10)             null    ,
    IDBACK                          VARCHAR2(4000)         null    ,
    COD_IUV                         VARCHAR2(35)           null    ,
    COD_FISCALE                     VARCHAR2(16)           null    ,
    LOG_ERRORE                      CLOB                   null    ,
    ENDPOINT                        VARCHAR2(2000)         null    ,
    constraint WS_LOG_PK primary key (ID)
)
/

comment on table WS_LOG is 'WSLO - Log dei Web Services'
/

-- ============================================================
--   Table: COMPONENTI_PEREQUATIVE
-- ============================================================
create table COMPONENTI_PEREQUATIVE
(
    ANNO                            NUMBER(4)              not null,
    COMPONENTE                      VARCHAR2(10)           not null,
    DESCRIZIONE                     VARCHAR2(100)          null    ,
    IMPORTO                         NUMBER(15,2)           null
        constraint COMPONENTI_PE_IMPORTO_CC check (
            IMPORTO is null or (IMPORTO >= 0
            )),
    constraint COMPONENTI_PEREQUATIVE_PK primary key (ANNO, COMPONENTE)
)
/

comment on table COMPONENTI_PEREQUATIVE is 'COPE - Componenti Perequative'
/

-- ============================================================
--   Table: SOGEI_DIC
-- ============================================================
create table SOGEI_DIC
(
    PROGRESSIVO                     NUMBER(10)             not null,
    TIPO_RECORD                     VARCHAR2(1)            not null,
    DATI                            VARCHAR2(124)          not null,
    NUM_CONTRIB                     NUMBER(10)             not null,
    PROGR_CONTRIB                   NUMBER(5)              not null,
    constraint SOGEI_DIC_PK primary key (PROGRESSIVO)
        using index
)
/

comment on table SOGEI_DIC is 'SODI - Sogei Dichiazioni'
/

-- ============================================================
--   Table: ANCI_VAR
-- ============================================================
create table ANCI_VAR
(
    PROGRESSIVO                     NUMBER(10)             not null,
    TIPO_RECORD                     VARCHAR2(1)            not null,
    DATI                            VARCHAR2(17)           not null,
    NUMERO_PACCO                    NUMBER(6)              not null,
    PROGRESSIVO_RECORD              NUMBER(7)              not null,
    DATI_1                          VARCHAR2(215)          not null,
    DATI_2                          VARCHAR2(242)          null    ,
    DATI_3                          VARCHAR2(10)           null    ,
    constraint ANCI_VAR_PK primary key (PROGRESSIVO)
        using index
)
/

comment on table ANCI_VAR is 'ANVA - Denunce di Variazione ANCI/CNC'
/

-- ============================================================
--   Table: FONTI
-- ============================================================
create table FONTI
(
    FONTE                           NUMBER(2)              not null,
    DESCRIZIONE                     VARCHAR2(60)           not null,
    constraint FONTI_PK primary key (FONTE)
)
/

comment on table FONTI is 'FONT - Fonti'
/

-- ============================================================
--   Table: CATEGORIE_CATASTO
-- ============================================================
create table CATEGORIE_CATASTO
(
    CATEGORIA_CATASTO               VARCHAR2(3)            not null,
    DESCRIZIONE                     VARCHAR2(200)          not null,
    FLAG_REALE                      VARCHAR2(1)            null
        constraint CATEGORIE_CAT_FLAG_REALE_CC check (
            FLAG_REALE is null or (FLAG_REALE in ('S'))),
    ECCEZIONE                       VARCHAR2(1)            null    ,
    constraint CATEGORIE_CATASTO_PK primary key (CATEGORIA_CATASTO)
)
/

comment on table CATEGORIE_CATASTO is 'CACA - Categorie Catastali'
/

-- ============================================================
--   Table: TIPI_OGGETTO
-- ============================================================
create table TIPI_OGGETTO
(
    TIPO_OGGETTO                    NUMBER(2)              not null,
    DESCRIZIONE                     VARCHAR2(60)           not null,
    constraint TIPI_OGGETTO_PK primary key (TIPO_OGGETTO)
)
/

comment on table TIPI_OGGETTO is 'TIOG - Tipi Oggetto'
/

-- ============================================================
--   Table: TIPI_UTILIZZO
-- ============================================================
create table TIPI_UTILIZZO
(
    TIPO_UTILIZZO                   NUMBER(2)              not null,
    DESCRIZIONE                     VARCHAR2(60)           not null,
    constraint TIPI_UTILIZZO_PK primary key (TIPO_UTILIZZO)
)
/

comment on table TIPI_UTILIZZO is 'TIUT - Tipi Utilizzo'
/

-- ============================================================
--   Table: TIPI_TRIBUTO
-- ============================================================
create table TIPI_TRIBUTO
(
    TIPO_TRIBUTO                    VARCHAR2(5)            not null,
    DESCRIZIONE                     VARCHAR2(100)          null    ,
    COD_ENTE                        VARCHAR2(5)            null    ,
    CONTO_CORRENTE                  NUMBER(8)              null    ,
    DESCRIZIONE_CC                  VARCHAR2(100)          null    ,
    TESTO_BOLLETTINO                VARCHAR2(2000)         null    ,
    FLAG_CANONE                     VARCHAR2(1)            null
        constraint TIPI_TRIBUTO_FLAG_CANONE_CC check (
            FLAG_CANONE is null or (FLAG_CANONE in ('S'))),
    FLAG_TARIFFA                    VARCHAR2(1)            null
        constraint TIPI_TRIBUTO_FLAG_TARIFFA_CC check (
            FLAG_TARIFFA is null or (FLAG_TARIFFA in ('S'))),
    FLAG_LIQ_RIOG                   VARCHAR2(1)            null
        constraint TIPI_TRIBUTO_FLAG_LIQ_RIOG_CC check (
            FLAG_LIQ_RIOG is null or (FLAG_LIQ_RIOG in ('S'))),
    UFFICIO                         VARCHAR2(100)          null    ,
    INDIRIZZO_UFFICIO               VARCHAR2(200)          null    ,
    TIPO_UFFICIO                    VARCHAR2(1)            null    ,
    COD_UFFICIO                     VARCHAR2(6)            null    ,
    DA_ANNO_VALIDITA                NUMBER(4)              null    ,
    A_ANNO_VALIDITA                 NUMBER(4)              null    ,
    constraint TIPI_TRIBUTO_PK primary key (TIPO_TRIBUTO)
)
/

comment on table TIPI_TRIBUTO is 'TITR - Tipi Tributo'
/

-- ============================================================
--   Table: TIPI_AREA
-- ============================================================
create table TIPI_AREA
(
    TIPO_AREA                       NUMBER(2)              not null,
    DESCRIZIONE                     VARCHAR2(60)           not null,
    constraint TIPI_AREA_PK primary key (TIPO_AREA)
)
/

comment on table TIPI_AREA is 'TIAP - Tipi Area'
/

-- ============================================================
--   Table: TIPI_USO
-- ============================================================
create table TIPI_USO
(
    TIPO_USO                        NUMBER(2)              not null,
    DESCRIZIONE                     VARCHAR2(60)           not null,
    constraint TIPI_USO_PK primary key (TIPO_USO)
)
/

comment on table TIPI_USO is 'TIUS - Tipi Uso'
/

-- ============================================================
--   Table: TIPI_CARICA
-- ============================================================
create table TIPI_CARICA
(
    TIPO_CARICA                     NUMBER(4)              not null,
    DESCRIZIONE                     VARCHAR2(60)           null    ,
    COD_SOGGETTO                    VARCHAR2(1)            null
        constraint TIPI_CARICA_COD_SOGGETTO_CC check (
            COD_SOGGETTO is null or (COD_SOGGETTO in ('C','D','E','L','R','T','G'))),
    constraint TIPI_CARICA_PK primary key (TIPO_CARICA)
)
/

comment on table TIPI_CARICA is 'TICA - Tipi Carica'
/

-- ============================================================
--   Table: MOTIVI_SGRAVIO
-- ============================================================
create table MOTIVI_SGRAVIO
(
    MOTIVO_SGRAVIO                  NUMBER(2)              not null,
    DESCRIZIONE                     VARCHAR2(60)           not null,
    constraint MOTIVI_SGRAVIO_PK primary key (MOTIVO_SGRAVIO)
)
/

comment on table MOTIVI_SGRAVIO is 'MOSG - Motivi Sgravio'
/

-- ============================================================
--   Table: ARCHIVIO_VIE
-- ============================================================
create table ARCHIVIO_VIE
(
    COD_VIA                         NUMBER(6)              not null,
    DENOM_UFF                       VARCHAR2(60)           null    ,
    DENOM_ORD                       VARCHAR2(60)           null    ,
    UTENTE                          VARCHAR2(8)            null    ,
    DATA_VARIAZIONE                 DATE                   not null,
    NOTE                            VARCHAR2(2000)         null    ,
    ENTE                            VARCHAR2(4)            null    ,
    constraint ARCHIVIO_VIE_PK primary key (COD_VIA)
)
/

comment on table ARCHIVIO_VIE is 'ARVI - Archivio Vie'
/

-- ============================================================
--   Table: TIPI_ANOMALIA
-- ============================================================
create table TIPI_ANOMALIA
(
    TIPO_ANOMALIA                   NUMBER(2)              not null,
    DESCRIZIONE                     VARCHAR2(60)           not null,
    TIPO_BONIFICA                   VARCHAR2(1)            null
        constraint TIPI_ANOMALIA_TIPO_BONIFICA_CC check (
            TIPO_BONIFICA is null or (TIPO_BONIFICA in ('D','V'))),
    TIPO_INTERVENTO                 VARCHAR2(100)          null    ,
    NOME_METODO                     VARCHAR2(100)          null    ,
    ZUL                             VARCHAR2(1000)         null    ,
    DETTAGLI_INDIPENDENTI           VARCHAR2(1)            default 'S' null    ,
    constraint TIPI_ANOMALIA_PK primary key (TIPO_ANOMALIA)
)
/

comment on table TIPI_ANOMALIA is 'TIAN - Tipi Anomalia'
/

-- ============================================================
--   Table: GRUPPI_SANZIONE
-- ============================================================
create table GRUPPI_SANZIONE
(
    GRUPPO_SANZIONE                 NUMBER(4)              not null,
    DESCRIZIONE                     VARCHAR2(60)           not null,
    STAMPA_TOTALE                   VARCHAR2(1)            null
        constraint GRUPPI_SANZIO_STAMPA_TOTALE_CC check (
            STAMPA_TOTALE is null or (STAMPA_TOTALE in ('S'))),
    constraint GRUPPI_SANZIONE_PK primary key (GRUPPO_SANZIONE)
)
/

comment on table GRUPPI_SANZIONE is 'GRSA - Gruppi Sanzione'
/

-- ============================================================
--   Table: TIPI_CONTATTO
-- ============================================================
create table TIPI_CONTATTO
(
    TIPO_CONTATTO                   NUMBER(2)              not null,
    DESCRIZIONE                     VARCHAR2(60)           not null,
    constraint TIPI_CONTATTO_PK primary key (TIPO_CONTATTO)
)
/

comment on table TIPI_CONTATTO is 'TICO - Tipi Contatto'
/

-- ============================================================
--   Table: TIPI_RICHIEDENTE
-- ============================================================
create table TIPI_RICHIEDENTE
(
    TIPO_RICHIEDENTE                NUMBER(2)              not null,
    DESCRIZIONE                     VARCHAR2(60)           not null,
    constraint TIPI_RICHIEDENTE_PK primary key (TIPO_RICHIEDENTE)
)
/

comment on table TIPI_RICHIEDENTE is 'TIRI - Tipi Richiedente'
/

-- ============================================================
--   Table: SETTORI_ATTIVITA
-- ============================================================
create table SETTORI_ATTIVITA
(
    SETTORE                         NUMBER(2)              not null,
    DESCRIZIONE                     VARCHAR2(60)           not null,
    constraint SETTORI_ATTIVITA_PK primary key (SETTORE)
)
/

comment on table SETTORI_ATTIVITA is 'Settori di attivita'
/

-- ============================================================
--   Table: SCAGLIONI_REDDITO
-- ============================================================
create table SCAGLIONI_REDDITO
(
    ANNO                            NUMBER(4)              not null,
    REDDITO_INF                     NUMBER(15,2)           not null,
    REDDITO_SUP                     NUMBER(15,2)           not null,
    constraint SCAGLIONI_REDDITO_PK primary key (ANNO)
)
/

comment on table SCAGLIONI_REDDITO is 'Scaglioni di reddito'
/

-- ============================================================
--   Table: TIPI_MODELLO
-- ============================================================
create table TIPI_MODELLO
(
    TIPO_MODELLO                    VARCHAR2(10)           not null,
    DESCRIZIONE                     VARCHAR2(60)           null    ,
    TIPO_PRATICA                    VARCHAR2(1)            null
        constraint TIPI_MODELLO_TIPO_PRATICA_CC check (
            TIPO_PRATICA is null or (TIPO_PRATICA in ('A','D','L','I','C','K','T','V','G','S'))),
    TIPO_EVENTO                     VARCHAR2(1)            null    ,
    FLAG_RIMBORSO                   VARCHAR2(1)            null
        constraint TIPI_MODELLO_FLAG_RIMBORSO_CC check (
            FLAG_RIMBORSO is null or (FLAG_RIMBORSO in ('S'))),
    constraint TIPI_MODELLO_PK primary key (TIPO_MODELLO)
)
/

comment on table TIPI_MODELLO is 'TIMO - Tipi Modello'
/

-- ============================================================
--   Table: MOTIVI_COMPENSAZIONE
-- ============================================================
create table MOTIVI_COMPENSAZIONE
(
    MOTIVO_COMPENSAZIONE            NUMBER(2)              not null,
    DESCRIZIONE                     VARCHAR2(60)           not null,
    constraint MOTIVI_COMPENSAZIONE_PK primary key (MOTIVO_COMPENSAZIONE)
)
/

comment on table MOTIVI_COMPENSAZIONE is 'MOCO - Motivi Compensazione'
/

-- ============================================================
--   Table: TITOLI_DOCUMENTO
-- ============================================================
create table TITOLI_DOCUMENTO
(
    TITOLO_DOCUMENTO                NUMBER(4)              not null,
    DESCRIZIONE                     VARCHAR2(100)          null    ,
    TIPO_CARICAMENTO                VARCHAR2(10)           null    ,
    ESTENSIONE_MULTI                VARCHAR2(100)          null    ,
    ESTENSIONE_MULTI2               VARCHAR2(10)           null    ,
    NOME_BEAN                       VARCHAR2(50)           null    ,
    NOME_METODO                     VARCHAR2(50)           null    ,
    constraint TITOLI_DOCUMENTO_PK primary key (TITOLO_DOCUMENTO)
)
/

comment on table TITOLI_DOCUMENTO is 'TIDO - Titoli Documento'
/

-- ============================================================
--   Table: CODICI_DIRITTO
-- ============================================================
create table CODICI_DIRITTO
(
    COD_DIRITTO                     VARCHAR2(4)            not null,
    ORDINAMENTO                     NUMBER(4)              not null,
    DESCRIZIONE                     VARCHAR2(60)           not null,
    FLAG_TRATTA_ISCRIZIONE          VARCHAR2(1)            null
        constraint CODICI_DIRITT_FLAG_TRATTA_I_CC check (
            FLAG_TRATTA_ISCRIZIONE is null or (FLAG_TRATTA_ISCRIZIONE in ('S'))),
    FLAG_TRATTA_CESSAZIONE          VARCHAR2(1)            null
        constraint CODICI_DIRITT_FLAG_TRATTA_C_CC check (
            FLAG_TRATTA_CESSAZIONE is null or (FLAG_TRATTA_CESSAZIONE in ('S'))),
    NOTE                            VARCHAR2(2000)         null    ,
    ECCEZIONE                       VARCHAR2(1)            null    ,
    constraint CODICI_DIRITTO_PK primary key (COD_DIRITTO)
)
/

comment on table CODICI_DIRITTO is 'CODI - Codici Diritto'
/

-- ============================================================
--   Table: TIPI_EXPORT
-- ============================================================
create table TIPI_EXPORT
(
    TIPO_EXPORT                     NUMBER(5)              not null,
    DESCRIZIONE                     VARCHAR2(100)          not null,
    NOME_PROCEDURA                  VARCHAR2(100)          not null,
    FLAG_STANDARD                   VARCHAR2(1)            null    ,
    TABELLA_TEMPORANEA              VARCHAR2(100)          null    ,
    NOME_FILE                       VARCHAR2(100)          null    ,
    ANNO_TRAS_ANCI                  NUMBER                 null    ,
    ORDINAMENTO                     NUMBER(5)              null    ,
    WINDOW_STAMPA                   VARCHAR2(100)          null    ,
    TIPO_TRIBUTO                    VARCHAR2(5)            null    ,
    WINDOW_CONTROLLO                VARCHAR2(100)          null    ,
    PREFISSO_NOME_FILE              VARCHAR2(20)           null    ,
    SUFFISSO_NOME_FILE              VARCHAR2(20)           null    ,
    ESTENSIONE_NOME_FILE            VARCHAR2(100)          null    ,
    FLAG_CLOB                       VARCHAR2(1)            null
        constraint TIPI_EXPORT_FLAG_CLOB_CC check (
            FLAG_CLOB is null or (FLAG_CLOB in ('S'))),
    constraint TIPI_EXPORT_PK primary key (TIPO_EXPORT)
)
/

comment on table TIPI_EXPORT is 'TIEX - Tipi Expot'
/

-- ============================================================
--   Table: TIPI_STATO
-- ============================================================
create table TIPI_STATO
(
    TIPO_STATO                      VARCHAR2(2)            not null,
    DESCRIZIONE                     VARCHAR2(60)           null    ,
    NUM_ORDINE                      NUMBER(5)              null    ,
    constraint TIPI_STATO_PK primary key (TIPO_STATO)
)
/

comment on table TIPI_STATO is 'TIST - Tipi Stato'
/

-- ============================================================
--   Table: TIPI_COSTO
-- ============================================================
create table TIPI_COSTO
(
    TIPO_COSTO                      VARCHAR2(8)            not null,
    DESCRIZIONE                     VARCHAR2(100)          null    ,
    constraint TIPI_COSTO_PK primary key (TIPO_COSTO)
)
/

comment on table TIPI_COSTO is 'TICS - Tipi Costo'
/

-- ============================================================
--   Table: TIPI_EVENTO
-- ============================================================
create table TIPI_EVENTO
(
    TIPO_EVENTO                     VARCHAR2(1)            not null,
    DESCRIZIONE                     VARCHAR2(60)           null    ,
    constraint TIPI_EVENTO_PK primary key (TIPO_EVENTO)
)
/

comment on table TIPI_EVENTO is 'TIEV - Tipi Evento'
/

-- ============================================================
--   Table: TIPI_ATTO
-- ============================================================
create table TIPI_ATTO
(
    TIPO_ATTO                       NUMBER(2)              not null,
    DESCRIZIONE                     VARCHAR2(60)           null    ,
    constraint TIPI_ATTO_PK primary key (TIPO_ATTO)
)
/

comment on table TIPI_ATTO is 'TIAT - Tipi Atto'
/

-- ============================================================
--   Table: TIPI_RECAPITO
-- ============================================================
create table TIPI_RECAPITO
(
    TIPO_RECAPITO                   NUMBER(2)              not null,
    DESCRIZIONE                     VARCHAR2(60)           not null,
    constraint TIPI_RECAPITO_PK primary key (TIPO_RECAPITO)
)
/

comment on table TIPI_RECAPITO is 'TIRE - Tipi Recapito'
/

-- ============================================================
--   Table: WRK_GRAFFATI
-- ============================================================
create table WRK_GRAFFATI
(
    DOCUMENTO_ID                    NUMBER(10)             not null,
    RIFERIMENTO                     VARCHAR2(10)           not null,
    ID_IMMOBILE                     NUMBER(9)              null    ,
    PROGR_GRAFFATO                  NUMBER(2)              null    ,
    OGGETTO                         NUMBER(10)             null    ,
    constraint WRK_GRAFFATI_PK primary key (DOCUMENTO_ID, RIFERIMENTO)
)
/

comment on table WRK_GRAFFATI is 'WRGR - WRK Graffati'
/

-- ============================================================
--   Table: WEB_CC_FABBRICATI
-- ============================================================
create table WEB_CC_FABBRICATI
(
    ID_FABBRICATO                   NUMBER(10)             not null,
    VERSION                         NUMBER(10)             not null,
    ANNO_NOTA_FINE                  NUMBER(4)              null    ,
    ANNO_NOTA_INIZIO                NUMBER(4)              null    ,
    ANNOTAZIONE                     VARCHAR2(200)          null    ,
    CATEGORIA                       VARCHAR2(3)            null    ,
    CLASSE                          VARCHAR2(2)            null    ,
    CODICE_AMMINISTRATIVO           VARCHAR2(4)            not null,
    CONSISTENZA                     NUMBER(7)              null    ,
    DATA_EFFICIACIA_FINE            DATE                   null    ,
    DATA_EFFICIACIA_INIZIO          DATE                   null    ,
    DATA_REG_ATTI_FINE              DATE                   null    ,
    DATA_REG_ATTI_INIZIO            DATE                   null    ,
    EDIFICIO                        VARCHAR2(2)            null    ,
    ID_IMMOBILE                     NUMBER(10)             not null,
    ID_MUTAZIONE_FINALE             NUMBER(10)             null    ,
    ID_MUTAZIONE_INIZIALE           NUMBER(10)             null    ,
    INTERNO1                        VARCHAR2(3)            null    ,
    INTERNO2                        VARCHAR2(3)            null    ,
    LOTTO                           VARCHAR2(2)            null    ,
    NUMERO_NOTA_FINE                VARCHAR2(6)            null    ,
    NUMERO_NOTA_INIZIO              VARCHAR2(6)            null    ,
    PARTITA                         VARCHAR2(7)            null    ,
    PIANO1                          VARCHAR2(4)            null    ,
    PIANO2                          VARCHAR2(4)            null    ,
    PIANO3                          VARCHAR2(4)            null    ,
    PIANO4                          VARCHAR2(4)            null    ,
    PROGR_NOTA_FINE                 VARCHAR2(3)            null    ,
    PROGR_NOTA_INIZIO               VARCHAR2(3)            null    ,
    PROGRESSIVO                     NUMBER(10)             null    ,
    RENDITA_EURO                    NUMBER(18,3)           null    ,
    RENDITA_LIRE                    NUMBER(15)             null    ,
    SCALA                           VARCHAR2(2)            null    ,
    SEZIONE                         VARCHAR2(1)            null    ,
    SUPERFICIE                      NUMBER(19,2)           null    ,
    TIPO_IMMOBILE                   VARCHAR2(1)            not null,
    TIPO_NOTA_FINE                  VARCHAR2(1)            null    ,
    TIPO_NOTA_INIZIO                VARCHAR2(1)            null    ,
    ZONA                            VARCHAR2(3)            null    ,
    ENTE                            VARCHAR2(4)            null    ,
    UTENTE                          VARCHAR2(8)            not null,
    PROTOCOLLO_NOTIFICA             VARCHAR2(20)           null    ,
    DATA_NOTIFICA                   DATE                   null    ,
    constraint WEB_CC_FABBRICATI_PK primary key (ID_FABBRICATO)
)
/

comment on table WEB_CC_FABBRICATI is 'WEB_CC_FABBRICATI'
/

-- ============================================================
--   Index: WCFA_UK
-- ============================================================
create unique index WCFA_UK on WEB_CC_FABBRICATI (ID_IMMOBILE asc, PROGRESSIVO asc, SEZIONE asc, CODICE_AMMINISTRATIVO asc, TIPO_IMMOBILE asc)
/

-- ============================================================
--   Table: WEB_CC_SOGGETTI
-- ============================================================
create table WEB_CC_SOGGETTI
(
    ID_SOGGETTO                     NUMBER(10)             not null,
    VERSION                         NUMBER(10)             not null,
    CODICE_AMMINISTRATIVO           VARCHAR2(4)            not null,
    SEZIONE                         VARCHAR2(1)            not null,
    IDENTIFICATIVO_SOGGETTO         NUMBER(10)             not null,
    TIPO_SOGGETTO                   VARCHAR2(1)            not null,
    CODICE_FISCALE                  VARCHAR2(16)           null    ,
    COGNOME                         VARCHAR2(50)           null    ,
    NOME                            VARCHAR2(50)           null    ,
    SESSO                           VARCHAR2(1)            null    ,
    DATA_NASCITA                    DATE                   null    ,
    LUOGO_NASCITA                   VARCHAR2(4)            null    ,
    INDICAZIONI_SUPPLEMENTARI       VARCHAR2(100)          null    ,
    DENOMINAZIONE                   VARCHAR2(150)          null    ,
    SEDE                            VARCHAR2(4)            null    ,
    ENTE                            VARCHAR2(4)            null    ,
    UTENTE                          VARCHAR2(8)            null    ,
    constraint WEB_CC_SOGGETTI_PK primary key (ID_SOGGETTO)
)
/

comment on table WEB_CC_SOGGETTI is 'WEB_CC_SOGGETTI'
/

-- ============================================================
--   Index: SOGGETTI_UNIQUE_IDX
-- ============================================================
create unique index SOGGETTI_UNIQUE_IDX on WEB_CC_SOGGETTI (CODICE_AMMINISTRATIVO asc, SEZIONE asc, IDENTIFICATIVO_SOGGETTO asc, TIPO_SOGGETTO asc)
/

-- ============================================================
--   Table: WEB_CC_TOPONIMI
-- ============================================================
create table WEB_CC_TOPONIMI
(
    ID_TOPONIMO                     NUMBER(3)              not null,
    DESCRIZIONE                     VARCHAR2(50)           null    ,
    constraint WEB_CC_TOPONIMI_PK primary key (ID_TOPONIMO)
)
/

comment on table WEB_CC_TOPONIMI is 'WEB_CC_TOPONIMI'
/

-- ============================================================
--   Table: WEB_CC_PARTICELLE
-- ============================================================
create table WEB_CC_PARTICELLE
(
    ID_PARTICELLA                   NUMBER(10)             not null,
    VERSION                         NUMBER(10)             not null,
    ID_IMMOBILE                     NUMBER(10)             not null,
    CODICE_AMMINISTRATIVO           VARCHAR2(4)            not null,
    SEZIONE                         VARCHAR2(1)            not null,
    PROGRESSIVO                     NUMBER(10)             null    ,
    TIPO_IMMOBILE                   VARCHAR2(1)            not null,
    FOGLIO                          NUMBER(5)              null    ,
    NUMERO                          VARCHAR2(5)            null    ,
    DENOMINATORE                    NUMBER(4)              null    ,
    SUBALTERNO                      VARCHAR2(4)            null    ,
    EDIFICIALITA                    VARCHAR2(1)            null    ,
    CODICE_QUALITA_ID               NUMBER(3)              null    ,
    CLASSE                          VARCHAR2(2)            null    ,
    ETTARI                          NUMBER(5)              null    ,
    ARE                             NUMBER(5)              null    ,
    CENTIARE                        NUMBER(2)              null    ,
    FLAG_REDDITO                    NUMBER(1)              null    ,
    FLAG_PORZIONE                   NUMBER(1)              null    ,
    FLAG_DEDUZIONI                  NUMBER(1)              null    ,
    REDDITO_DOMINICALE_LIRE         NUMBER(9)              null    ,
    REDDITO_AGRARIO_LIRE            NUMBER(8)              null    ,
    REDDITO_DOMINICALE_EURO         NUMBER(12,3)           null    ,
    REDDITO_AGRARIO_EURO            NUMBER(11,3)           null    ,
    DATA_EFFICIACIA_INIZIO          DATE                   null    ,
    DATA_REG_ATTI_INIZIO            DATE                   null    ,
    TIPO_NOTA_INIZIO                VARCHAR2(1)            null    ,
    NUMERO_NOTA_INIZIO              VARCHAR2(6)            null    ,
    PROGR_NOTA_INIZIO               VARCHAR2(3)            null    ,
    ANNO_NOTA_INIZIO                NUMBER(4)              null    ,
    DATA_EFFICIACIA_FINE            DATE                   null    ,
    DATA_REG_ATTI_FINE              DATE                   null    ,
    TIPO_NOTA_FINE                  VARCHAR2(1)            null    ,
    NUMERO_NOTA_FINE                VARCHAR2(6)            null    ,
    PROGR_NOTA_FINE                 VARCHAR2(3)            null    ,
    ANNO_NOTA_FINE                  NUMBER(4)              null    ,
    PARTITA                         VARCHAR2(7)            null    ,
    ANNOTAZIONE                     VARCHAR2(200)          null    ,
    ID_MUTAZIONE_INIZIALE           NUMBER(10)             null    ,
    ID_MUTAZIONE_FINALE             NUMBER(10)             null    ,
    ENTE                            VARCHAR2(4)            null    ,
    UTENTE                          VARCHAR2(8)            null    ,
    constraint WEB_CC_PARTICELLE_PK primary key (ID_PARTICELLA)
)
/

comment on table WEB_CC_PARTICELLE is 'WEB_CC_PARTICELLE'
/

-- ============================================================
--   Table: AFC_ELABORAZIONI
-- ============================================================
create table AFC_ELABORAZIONI
(
    ID_ELABORAZIONE                 NUMBER(10)             not null,
    VERSION                         NUMBER(10)             not null,
    CODICE                          VARCHAR2(100)          not null,
    DATA_INIZIO                     DATE                   null    ,
    DATA_REGISTRAZIONE              DATE                   not null,
    DESCRIZIONE                     VARCHAR2(200)          null    ,
    ENTI                            VARCHAR2(100)          null    ,
    DATA_MODIFICA                   DATE                   not null,
    ID_SCHEDULAZIONE                NUMBER(10)             not null,
    STATO                           VARCHAR2(1)            not null,
    UTENTE                          VARCHAR2(8)            not null,
    VISIONATO                       CHAR(1)                not null,
    constraint AFC_ELABORAZIONI_PK primary key (ID_ELABORAZIONE)
)
/

comment on table AFC_ELABORAZIONI is 'AFC_ELABORAZIONI'
/

-- ============================================================
--   Index: AFEL_CODICE_UK
-- ============================================================
create unique index AFEL_CODICE_UK on AFC_ELABORAZIONI (CODICE asc)
/

-- ============================================================
--   Table: WS_INTEGRAZIONI
-- ============================================================
create table WS_INTEGRAZIONI
(
    CODICE_INTEGRAZIONE             NUMBER(3)              not null,
    DESCRIZIONE                     VARCHAR2(60)           null    ,
    constraint WS_INTEGRAZIONI_PK primary key (CODICE_INTEGRAZIONE)
)
/

comment on table WS_INTEGRAZIONI is 'WINT : Tipologie di integrazioni tramite WS'
/

-- ============================================================
--   Table: CLASSI_CER
-- ============================================================
create table CLASSI_CER
(
    CLASSE_CER                      VARCHAR2(2)            not null,
    DESCRIZIONE                     VARCHAR2(200)          null    ,
    constraint CLASSI_CER_PK primary key (CLASSE_CER)
)
/

comment on table CLASSI_CER is 'CLCE - Classi CER'
/

-- ============================================================
--   Table: WRK_DOCFA_CAUSALI
-- ============================================================
create table WRK_DOCFA_CAUSALI
(
    CAUSALE                         VARCHAR2(3)            not null,
    DESCRIZIONE                     VARCHAR2(100)          null    ,
    constraint WRK_DOCFA_CAUSALI_PK primary key (CAUSALE)
)
/

comment on table WRK_DOCFA_CAUSALI is 'WRK_DOCFA_CAUSALI'
/

-- ============================================================
--   Table: WRK_ENC_TESTATA
-- ============================================================
create table WRK_ENC_TESTATA
(
    DOCUMENTO_ID                    NUMBER(10)             not null,
    PROGR_DICHIARAZIONE             NUMBER(4)              not null,
    ANNO_DICHIARAZIONE              NUMBER(4)              null    ,
    ANNO_IMPOSTA                    NUMBER(4)              null    ,
    COD_COMUNE                      VARCHAR2(4)            null    ,
    COD_FISCALE                     VARCHAR2(16)           null    ,
    DENOMINAZIONE                   VARCHAR2(60)           null    ,
    TELEFONO                        VARCHAR2(12)           null    ,
    EMAIL                           VARCHAR2(50)           null    ,
    INDIRIZZO                       VARCHAR2(35)           null    ,
    NUM_CIV                         VARCHAR2(5)            null    ,
    SCALA                           VARCHAR2(5)            null    ,
    PIANO                           VARCHAR2(5)            null    ,
    INTERNO                         VARCHAR2(5)            null    ,
    CAP                             VARCHAR2(5)            null    ,
    COMUNE                          VARCHAR2(100)          null    ,
    PROVINCIA                       VARCHAR2(2)            null    ,
    NUM_IMMOBILI_A                  NUMBER(9)              null    ,
    NUM_IMMOBILI_B                  NUMBER(9)              null    ,
    IMU_DOVUTA                      NUMBER(12)             null    ,
    ECCEDENZA_IMU_DIC_PREC          NUMBER(12)             null    ,
    ECCEDENZA_IMU_DIC_PREC_F24      NUMBER(12)             null    ,
    RATE_IMU_VERSATE                NUMBER(12)             null    ,
    IMU_DEBITO                      NUMBER(12)             null    ,
    IMU_CREDITO                     NUMBER(12)             null    ,
    TASI_DOVUTA                     NUMBER(12)             null    ,
    ECCEDENZA_TASI_DIC_PREC         NUMBER(12)             null    ,
    ECCEDENZA_TASI_DIC_PREC_F24     NUMBER(12)             null    ,
    TASI_RATE_VERSATE               NUMBER(12)             null    ,
    TASI_DEBITO                     NUMBER(12)             null    ,
    TASI_CREDITO                    NUMBER(12)             null    ,
    IMU_CREDITO_DIC_PRESENTE        NUMBER(12)             null    ,
    CREDITO_IMU_RIMBORSO            NUMBER(12)             null    ,
    CREDITO_IMU_COMPENSAZIONE       NUMBER(12)             null    ,
    TASI_CREDITO_DIC_PRESENTE       NUMBER(12)             null    ,
    CREDITO_TASI_RIMBORSO           NUMBER(12)             null    ,
    CREDITO_TASI_COMPENSAZIONE      NUMBER(12)             null    ,
    DATA_VARIAZIONE                 DATE                   null    ,
    UTENTE                          VARCHAR2(8)            null    ,
    TR4_NI                          NUMBER(10)             null    ,
    TR4_PRATICA_ICI                 NUMBER(10)             null    ,
    TR4_PRATICA_TASI                NUMBER(10)             null    ,
    FIRMA_DICHIARAZIONE             VARCHAR2(1)            null    ,
    SESSO                           VARCHAR2(1)            null
        constraint WRK_ENC_TESTA_SESSO_CC check (
            SESSO is null or (SESSO in ('M','F'))),
    DATA_NASCITA                    DATE                   null    ,
    COMUNE_NASCITA                  VARCHAR2(40)           null    ,
    PROVINCIA_NASCITA               VARCHAR2(2)            null    ,
    CODICE_TRACCIATO                VARCHAR2(50)           null    ,
    NOME                            VARCHAR2(100)          null    ,
    constraint WRK_ENC_TESTATA_PK primary key (DOCUMENTO_ID, PROGR_DICHIARAZIONE)
)
/

comment on table WRK_ENC_TESTATA is 'WETE - Wrk_enc_testata'
/

-- ============================================================
--   Table: UTENZE_TIPI_UTENZA
-- ============================================================
create table UTENZE_TIPI_UTENZA
(
    TIPO_FORNITURA                  VARCHAR2(1)            not null,
    TIPO_UTENZA                     VARCHAR2(1)            not null,
    DESCRIZIONE                     VARCHAR2(200)          null    ,
    DESCR_BREVE                     VARCHAR2(20)           null    ,
    constraint UTENZE_TIPI_UTENZA_PK primary key (TIPO_FORNITURA, TIPO_UTENZA)
)
/

comment on table UTENZE_TIPI_UTENZA is 'UTTU - Utenze Tipi Utenza'
/

-- ============================================================
--   Table: TIPI_PARAMETRO
-- ============================================================
create table TIPI_PARAMETRO
(
    TIPO_PARAMETRO                  VARCHAR2(16)           not null,
    DESCRIZIONE                     VARCHAR2(100)          not null,
    APPLICATIVO                     VARCHAR2(20)           not null
        constraint TIPI_PARAMETR_APPLICATIVO_CC check (
            APPLICATIVO in ('WEB','TR4')),
    constraint TIPI_PARAMETRO_PK primary key (TIPO_PARAMETRO)
)
/

comment on table TIPI_PARAMETRO is 'TIPA - Tipi Parametro'
/

-- ============================================================
--   Table: FTP_TRASMISSIONI
-- ============================================================
create table FTP_TRASMISSIONI
(
    ID_DOCUMENTO                    NUMBER(10)             not null,
    NOME_FILE                       VARCHAR2(100)          null    ,
    CLOB_FILE                       CLOB                   null    ,
    UTENTE                          VARCHAR2(8)            null    ,
    DATA_VARIAZIONE                 DATE                   null    ,
    DIREZIONE                       VARCHAR2(1)            null
        constraint FTP_TRASMISSI_DIREZIONE_CC check (
            DIREZIONE is null or (DIREZIONE in ('E','U'))),
    HASH                            VARCHAR2(256)          null    ,
    constraint FTP_TRASMISSIONI_PK primary key (ID_DOCUMENTO)
)
/

comment on table FTP_TRASMISSIONI is 'FTTR - Ftp Trasmissioni'
/

-- ============================================================
--   Table: TIPI_ATTIVITA
-- ============================================================
create table TIPI_ATTIVITA
(
    TIPO_ATTIVITA                   NUMBER(2)              not null,
    DESCRIZIONE                     VARCHAR2(60)           not null,
    constraint TIPI_ATTIVITA_PK primary key (TIPO_ATTIVITA)
)
/

comment on table TIPI_ATTIVITA is 'TIAT - Tipi Attivita'
/

-- ============================================================
--   Table: STATI_ATTIVITA
-- ============================================================
create table STATI_ATTIVITA
(
    STATO_ATTIVITA                  NUMBER(2)              not null,
    DESCRIZIONE                     VARCHAR2(60)           not null,
    constraint STATI_ATTIVITA_PK primary key (STATO_ATTIVITA)
)
/

comment on table STATI_ATTIVITA is 'STAT - Stati Attivita'
/

-- ============================================================
--   Table: TIPI_SPEDIZIONE
-- ============================================================
create table TIPI_SPEDIZIONE
(
    TIPO_SPEDIZIONE                 VARCHAR2(2)            not null,
    DESCRIZIONE                     VARCHAR2(60)           not null,
    constraint TIPI_SPEDIZIONE_PK primary key (TIPO_SPEDIZIONE)
)
/

comment on table TIPI_SPEDIZIONE is 'TISP - Tipi Spedizione'
/

-- ============================================================
--   Table: ARCHIVIO_VIE_ZONE
-- ============================================================
create table ARCHIVIO_VIE_ZONE
(
    COD_ZONA                        NUMBER(2)              not null,
    SEQUENZA                        NUMBER(4)              not null,
    DENOMINAZIONE                   VARCHAR2(60)           null    ,
    DA_ANNO                         NUMBER(4)              null    ,
    A_ANNO                          NUMBER(4)              null    ,
    constraint ARCHIVIO_VIE_ZONE_PK primary key (COD_ZONA, SEQUENZA)
)
/

comment on table ARCHIVIO_VIE_ZONE is 'AVZE - Archivio Vie Zone'
/

-- ============================================================
--   Table: SAM_CODICI_RITORNO
-- ============================================================
create table SAM_CODICI_RITORNO
(
    COD_RITORNO                     VARCHAR2(10)           not null,
    DESCRIZIONE                     VARCHAR2(100)          null    ,
    RISCONTRO                       VARCHAR2(200)          null    ,
    ESITO                           VARCHAR2(2)            null    ,
    constraint SAM_CODICI_RITORNO_PK primary key (COD_RITORNO)
)
/

comment on table SAM_CODICI_RITORNO is 'SAM_CODICI_RITORNO'
/

-- ============================================================
--   Table: SAM_CODICI_CARICA
-- ============================================================
create table SAM_CODICI_CARICA
(
    COD_CARICA                      VARCHAR2(2)            not null,
    DESCRIZIONE                     VARCHAR2(100)          null    ,
    constraint SAM_CODICI_CARICA_PK primary key (COD_CARICA)
)
/

comment on table SAM_CODICI_CARICA is 'SAM_CODICI_CARICA'
/

-- ============================================================
--   Table: SAM_FONTI_DECESSO
-- ============================================================
create table SAM_FONTI_DECESSO
(
    FONTE_DECESSO                   VARCHAR2(2)            not null,
    DESCRIZIONE                     VARCHAR2(100)          null    ,
    constraint SAM_FONTI_DECESSO_PK primary key (FONTE_DECESSO)
)
/

comment on table SAM_FONTI_DECESSO is 'SAM_FONTI_DECESSO'
/

-- ============================================================
--   Table: SAM_FONTI_DOM_SEDE
-- ============================================================
create table SAM_FONTI_DOM_SEDE
(
    FONTE                           VARCHAR2(2)            not null,
    DESCRIZIONE                     VARCHAR2(100)          null    ,
    constraint SAM_FONTI_DOM_SEDE_PK primary key (FONTE)
)
/

comment on table SAM_FONTI_DOM_SEDE is 'SAM_FONTI_DOM_SEDE'
/

-- ============================================================
--   Table: SAM_TIPI
-- ============================================================
create table SAM_TIPI
(
    TIPO                            VARCHAR2(15)           not null,
    DESCRIZIONE                     VARCHAR2(100)          null    ,
    constraint SAM_TIPI_PK primary key (TIPO)
)
/

comment on table SAM_TIPI is 'STIP - SAM Tipi'
/

-- ============================================================
--   Table: SAM_TIPI_CESSAZIONE
-- ============================================================
create table SAM_TIPI_CESSAZIONE
(
    TIPO_CESSAZIONE                 VARCHAR2(1)            not null,
    DESCRIZIONE                     VARCHAR2(100)          null    ,
    constraint SAM_TIPI_CESSAZIONE_PK primary key (TIPO_CESSAZIONE)
)
/

comment on table SAM_TIPI_CESSAZIONE is 'SAM_TIPI_CESSAZIONE'
/

-- ============================================================
--   Table: TIPI_NOTIFICA
-- ============================================================
create table TIPI_NOTIFICA
(
    TIPO_NOTIFICA                   NUMBER(2)              not null,
    DESCRIZIONE                     VARCHAR2(100)          null    ,
    FLAG_MODIFICABILE               VARCHAR2(1)            null
        constraint TIPI_NOTIFICA_FLAG_MODIFICA_CC check (
            FLAG_MODIFICABILE is null or (FLAG_MODIFICABILE in ('S'))),
    constraint TIPI_NOTIFICA_PK primary key (TIPO_NOTIFICA)
)
/

comment on table TIPI_NOTIFICA is 'TINO - Tipi Notifica'
/

-- ============================================================
--   Table: TIPI_ELABORAZIONE
-- ============================================================
create table TIPI_ELABORAZIONE
(
    TIPO_ELABORAZIONE               VARCHAR2(4)            not null,
    DESCRIZIONE                     VARCHAR2(60)           not null,
    constraint TIPI_ELABORAZIONE_PK primary key (TIPO_ELABORAZIONE)
)
/

comment on table TIPI_ELABORAZIONE is 'TIEL - Tipi_Elaborazione'
/

-- ============================================================
--   Table: TIPI_CANALE
-- ============================================================
create table TIPI_CANALE
(
    TIPO_CANALE                     NUMBER(2)              not null,
    DESCRIZIONE                     VARCHAR2(100)          not null,
    constraint TIPI_CANALE_PK primary key (TIPO_CANALE)
)
/

comment on table TIPI_CANALE is 'TICA - Tipi Canale'
/

-- ============================================================
--   Table: TIPI_STATO_CONTRIBUENTE
-- ============================================================
create table TIPI_STATO_CONTRIBUENTE
(
    TIPO_STATO_CONTRIBUENTE         NUMBER(2)              not null,
    DESCRIZIONE                     VARCHAR2(100)          not null,
    DESCRIZIONE_BREVE               VARCHAR2(4)            not null,
    constraint TIPI_STATO_CONTRIBUENTE_PK primary key (TIPO_STATO_CONTRIBUENTE)
)
/

comment on table TIPI_STATO_CONTRIBUENTE is 'TSCO - Tipi Stato Contribuente'
/

-- ============================================================
--   Table: CONTENITORI
-- ============================================================
create table CONTENITORI
(
    COD_CONTENITORE                 NUMBER(4)              not null,
    DESCRIZIONE                     VARCHAR2(60)           null    ,
    UNITA_DI_MISURA                 VARCHAR2(20)           null    ,
    CAPIENZA                        NUMBER(6,2)            null    ,
    constraint CONTENITORI_PK primary key (COD_CONTENITORE)
)
/

comment on table CONTENITORI is 'CORI - Contenitori Rifiuti'
/

-- ============================================================
--   Table: MOLTIPLICATORI
-- ============================================================
create table MOLTIPLICATORI
(
    ANNO                            NUMBER(4)              not null,
    CATEGORIA_CATASTO               VARCHAR2(3)            not null,
    MOLTIPLICATORE                  NUMBER(5,2)            not null,
    constraint MOLTIPLICATORI_PK primary key (ANNO, CATEGORIA_CATASTO)
)
/

comment on table MOLTIPLICATORI is 'MOLT - Moltiplicatori'
/

-- ============================================================
--   Index: MOLT_CACA_FK
-- ============================================================
create index MOLT_CACA_FK on MOLTIPLICATORI (CATEGORIA_CATASTO asc)
/

-- ============================================================
--   Table: OGGETTI_TRIBUTO
-- ============================================================
create table OGGETTI_TRIBUTO
(
    TIPO_TRIBUTO                    VARCHAR2(5)            not null,
    TIPO_OGGETTO                    NUMBER(2)              not null,
    constraint OGGETTI_TRIBUTO_PK primary key (TIPO_TRIBUTO, TIPO_OGGETTO)
)
/

comment on table OGGETTI_TRIBUTO is 'OGTR - Oggetti Tributo'
/

-- ============================================================
--   Index: OGTR_TIOG_FK
-- ============================================================
create index OGTR_TIOG_FK on OGGETTI_TRIBUTO (TIPO_OGGETTO asc)
/

-- ============================================================
--   Index: OGTR_TITR_FK
-- ============================================================
create index OGTR_TITR_FK on OGGETTI_TRIBUTO (TIPO_TRIBUTO asc)
/

-- ============================================================
--   Table: RUOLI
-- ============================================================
create table RUOLI
(
    RUOLO                           NUMBER(10)             not null,
    TIPO_TRIBUTO                    VARCHAR2(5)            not null,
    TIPO_RUOLO                      NUMBER(1)              not null
        constraint RUOLI_TIPO_RUOLO_CC check (
            TIPO_RUOLO in (1,2,3,4,5)),
    ANNO_RUOLO                      NUMBER(4)              not null,
    ANNO_EMISSIONE                  NUMBER(4)              not null,
    PROGR_EMISSIONE                 NUMBER(2)              not null,
    DATA_EMISSIONE                  DATE                   null    ,
    DESCRIZIONE                     VARCHAR2(100)          not null,
    RATE                            NUMBER(2)              null    ,
    SPECIE_RUOLO                    NUMBER(1)              not null
        constraint RUOLI_SPECIE_RUOLO_CC check (
            SPECIE_RUOLO in (0,1)),
    COD_SEDE                        NUMBER(4)              null    ,
    DATA_DENUNCIA                   DATE                   null    ,
    SCADENZA_PRIMA_RATA             DATE                   null    ,
    INVIO_CONSORZIO                 DATE                   null    ,
    RUOLO_RIF                       NUMBER(10)             null    ,
    UTENTE                          VARCHAR2(8)            not null,
    DATA_VARIAZIONE                 DATE                   not null,
    NOTE                            VARCHAR2(2000)         null    ,
    IMPORTO_LORDO                   VARCHAR2(1)            null
        constraint RUOLI_IMPORTO_LORDO_CC check (
            IMPORTO_LORDO is null or (IMPORTO_LORDO in ('S'))),
    A_ANNO_RUOLO                    NUMBER(4)              null    ,
    COGNOME_RESP                    VARCHAR2(30)           null    ,
    NOME_RESP                       VARCHAR2(30)           null    ,
    DATA_FINE_INTERESSI             DATE                   null    ,
    STATO_RUOLO                     VARCHAR2(100)          null
        constraint RUOLI_STATO_RUOLO_CC check (
            STATO_RUOLO is null or (STATO_RUOLO in ('RID_EMESSI','RID_CARICATI'))),
    RUOLO_MASTER                    NUMBER(10)             null    ,
    SCADENZA_RATA_2                 DATE                   null    ,
    SCADENZA_RATA_3                 DATE                   null    ,
    SCADENZA_RATA_4                 DATE                   null    ,
    TIPO_CALCOLO                    VARCHAR2(1)            null
        constraint RUOLI_TIPO_CALCOLO_CC check (
            TIPO_CALCOLO is null or (TIPO_CALCOLO in ('T','N'))),
    TIPO_EMISSIONE                  VARCHAR2(1)            null
        constraint RUOLI_TIPO_EMISSION_CC check (
            TIPO_EMISSIONE is null or (TIPO_EMISSIONE in ('A','S','T','X'))),
    PERC_ACCONTO                    NUMBER(5,2)            null    ,
    ENTE                            VARCHAR2(4)            null    ,
    FLAG_CALCOLO_TARIFFA_BASE       VARCHAR2(1)            null
        constraint RUOLI_FLAG_CALCOLO__CC check (
            FLAG_CALCOLO_TARIFFA_BASE is null or (FLAG_CALCOLO_TARIFFA_BASE in ('S'))),
    FLAG_TARIFFE_RUOLO              VARCHAR2(1)            null
        constraint RUOLI_FLAG_TARIFFE__CC check (
            FLAG_TARIFFE_RUOLO is null or (FLAG_TARIFFE_RUOLO in ('S'))),
    SCADENZA_AVVISO_1               DATE                   null    ,
    SCADENZA_AVVISO_2               DATE                   null    ,
    SCADENZA_AVVISO_3               DATE                   null    ,
    SCADENZA_AVVISO_4               DATE                   null    ,
    FLAG_DEPAG                      VARCHAR2(1)            null
        constraint RUOLI_FLAG_DEPAG_CC check (
            FLAG_DEPAG is null or (FLAG_DEPAG in ('S'))),
    TERMINE_PAGAMENTO               DATE                   null    ,
    PROGR_INVIO                     NUMBER(5)              null    ,
    FLAG_ISCRITTI_ALTRO_RUOLO       VARCHAR2(1)            null
        constraint RUOLI_FLAG_ISCRITTI_CC check (
            FLAG_ISCRITTI_ALTRO_RUOLO is null or (FLAG_ISCRITTI_ALTRO_RUOLO in ('S'))),
    SCADENZA_RATA_UNICA             DATE                   null    ,
    SCADENZA_AVVISO_UNICO           DATE                   null    ,
    FLAG_ELIMINA_DEPAG              VARCHAR2(1)            null
        constraint RUOLI_FLAG_ELIMINA__CC check (
            FLAG_ELIMINA_DEPAG is null or (FLAG_ELIMINA_DEPAG in ('S'))),
    constraint RUOLI_PK primary key (RUOLO)
)
/

comment on table RUOLI is 'RUOL - Ruoli'
/

-- ============================================================
--   Index: RUOL_UK
-- ============================================================
create unique index RUOL_UK on RUOLI (TIPO_TRIBUTO asc, TIPO_RUOLO asc, ANNO_RUOLO asc, ANNO_EMISSIONE asc, PROGR_EMISSIONE asc)
/

-- ============================================================
--   Index: RUOL_TITR_FK
-- ============================================================
create index RUOL_TITR_FK on RUOLI (TIPO_TRIBUTO asc)
/

-- ============================================================
--   Index: RUOL_RUOL_FK
-- ============================================================
create index RUOL_RUOL_FK on RUOLI (RUOLO_RIF asc)
/

-- ============================================================
--   Index: RUOL_RUOL2_FK
-- ============================================================
create index RUOL_RUOL2_FK on RUOLI (RUOLO_MASTER asc)
/

-- ============================================================
--   Table: TIPI_ALIQUOTA
-- ============================================================
create table TIPI_ALIQUOTA
(
    TIPO_TRIBUTO                    VARCHAR2(5)            not null,
    TIPO_ALIQUOTA                   NUMBER(2)              not null,
    DESCRIZIONE                     VARCHAR2(60)           not null,
    constraint TIPI_ALIQUOTA_PK primary key (TIPO_TRIBUTO, TIPO_ALIQUOTA)
)
/

comment on table TIPI_ALIQUOTA is 'TIAL - Tipi Aliquota'
/

-- ============================================================
--   Table: DETRAZIONI
-- ============================================================
create table DETRAZIONI
(
    TIPO_TRIBUTO                    VARCHAR2(5)            not null,
    ANNO                            NUMBER(4)              not null,
    DETRAZIONE_BASE                 NUMBER(15,2)           null
        constraint DETRAZIONI_DETRAZIONE_BA_CC check (
            DETRAZIONE_BASE is null or (DETRAZIONE_BASE >= 0
            )),
    DETRAZIONE                      NUMBER(15,2)           null
        constraint DETRAZIONI_DETRAZIONE_CC check (
            DETRAZIONE is null or (DETRAZIONE >= 0
            )),
    ALIQUOTA                        NUMBER(6,4)            null    ,
    DETRAZIONE_IMPONIBILE           NUMBER(15,2)           null
        constraint DETRAZIONI_DETRAZIONE_IM_CC check (
            DETRAZIONE_IMPONIBILE is null or (DETRAZIONE_IMPONIBILE >= 0
            )),
    FLAG_PERTINENZE                 VARCHAR2(1)            null
        constraint DETRAZIONI_FLAG_PERTINEN_CC check (
            FLAG_PERTINENZE is null or (FLAG_PERTINENZE in ('S'))),
    DETRAZIONE_FIGLIO               NUMBER(15,2)           null    ,
    DETRAZIONE_MAX_FIGLI            NUMBER(15,2)           null    ,
    constraint DETRAZIONI_PK primary key (TIPO_TRIBUTO, ANNO)
)
/

comment on table DETRAZIONI is 'DETR - Detrazioni'
/

-- ============================================================
--   Table: MOTIVI_DETRAZIONE
-- ============================================================
create table MOTIVI_DETRAZIONE
(
    TIPO_TRIBUTO                    VARCHAR2(5)            not null,
    MOTIVO_DETRAZIONE               NUMBER(2)              not null,
    DESCRIZIONE                     VARCHAR2(60)           not null,
    constraint MOTIVI_DETRAZIONE_PK primary key (TIPO_TRIBUTO, MOTIVO_DETRAZIONE)
)
/

comment on table MOTIVI_DETRAZIONE is 'MDET - Motivi Detrazione'
/

-- ============================================================
--   Index: MDET_TITR_FK
-- ============================================================
create index MDET_TITR_FK on MOTIVI_DETRAZIONE (TIPO_TRIBUTO asc)
/

-- ============================================================
--   Table: COMUNICAZIONE_PARAMETRI
-- ============================================================
create table COMUNICAZIONE_PARAMETRI
(
    TIPO_TRIBUTO                    VARCHAR2(5)            not null,
    TIPO_COMUNICAZIONE              VARCHAR2(3)            not null,
    DESCRIZIONE                     VARCHAR2(100)          null    ,
    FLAG_FIRMA                      VARCHAR2(1)            null
        constraint COMUNICAZIONE_FLAG_FIRMA_CC check (
            FLAG_FIRMA is null or (FLAG_FIRMA in ('S'))),
    FLAG_PROTOCOLLO                 VARCHAR2(1)            null
        constraint COMUNICAZIONE_FLAG_PROTOCOL_CC check (
            FLAG_PROTOCOLLO is null or (FLAG_PROTOCOLLO in ('S'))),
    FLAG_PEC                        VARCHAR2(1)            null
        constraint COMUNICAZIONE_FLAG_PEC_CC check (
            FLAG_PEC is null or (FLAG_PEC in ('S'))),
    TIPO_DOCUMENTO                  VARCHAR2(3)            null    ,
    TITOLO_DOCUMENTO                VARCHAR2(200)          null    ,
    PKG_VARIABILI                   VARCHAR2(100)          null    ,
    VARIABILI_CLOB                  CLOB                   null    ,
    constraint COMUNICAZIONE_PARAMETRI_PK primary key (TIPO_TRIBUTO, TIPO_COMUNICAZIONE)
)
/

comment on table COMUNICAZIONE_PARAMETRI is 'COPA - Comunicazione Parametri'
/

-- ============================================================
--   Index: COPA_TITR_FK
-- ============================================================
create index COPA_TITR_FK on COMUNICAZIONE_PARAMETRI (TIPO_TRIBUTO asc)
/

-- ============================================================
--   Table: CODICI_F24
-- ============================================================
create table CODICI_F24
(
    TRIBUTO_F24                     VARCHAR2(4)            not null,
    DESCRIZIONE                     VARCHAR2(1000)         not null,
    RATEAZIONE                      VARCHAR2(4)            null    ,
    TIPO_TRIBUTO                    VARCHAR2(5)            not null,
    DESCRIZIONE_TITR                VARCHAR2(5)            not null,
    TIPO_CODICE                     VARCHAR2(1)            not null,
    FLAG_IFEL                       VARCHAR2(1)            null
        constraint CODICI_F24_FLAG_IFEL_CC check (
            FLAG_IFEL is null or (FLAG_IFEL in ('S'))),
    FLAG_STAMPA_RATEAZIONE          VARCHAR2(1)            null
        constraint CODICI_F24_FLAG_STAMPA_R_CC check (
            FLAG_STAMPA_RATEAZIONE is null or (FLAG_STAMPA_RATEAZIONE in ('S'))),
    FLAG_TRIBUTO_RIF                VARCHAR2(1)            null
        constraint CODICI_F24_FLAG_TRIBUTO__CC check (
            FLAG_TRIBUTO_RIF is null or (FLAG_TRIBUTO_RIF in ('S'))),
    constraint CODICI_F24_PK primary key (TRIBUTO_F24, TIPO_TRIBUTO, DESCRIZIONE_TITR)
)
/

comment on table CODICI_F24 is 'COF2 - Codici F24'
/

-- ============================================================
--   Index: COF2_DES_TITR_IK
-- ============================================================
create index COF2_DES_TITR_IK on CODICI_F24 (DESCRIZIONE_TITR asc)
/

-- ============================================================
--   Index: COF2_TITR_FK
-- ============================================================
create index COF2_TITR_FK on CODICI_F24 (TIPO_TRIBUTO asc)
/

-- ============================================================
--   Table: GRUPPI_TRIBUTO
-- ============================================================
create table GRUPPI_TRIBUTO
(
    TIPO_TRIBUTO                    VARCHAR2(5)            not null,
    GRUPPO_TRIBUTO                  VARCHAR2(10)           not null,
    DESCRIZIONE                     VARCHAR2(100)          null    ,
    constraint GRUPPI_TRIBUTO_PK primary key (TIPO_TRIBUTO, GRUPPO_TRIBUTO)
)
/

comment on table GRUPPI_TRIBUTO is 'GRTR - Gruppi_tributo'
/

-- ============================================================
--   Index: GRTR_TITR_FK
-- ============================================================
create index GRTR_TITR_FK on GRUPPI_TRIBUTO (TIPO_TRIBUTO asc)
/

-- ============================================================
--   Table: OGGETTI_IMPOSTA
-- ============================================================
create table OGGETTI_IMPOSTA
(
    OGGETTO_IMPOSTA                 NUMBER(10)             not null,
    COD_FISCALE                     VARCHAR2(16)           not null,
    ANNO                            NUMBER(4)              not null,
    OGGETTO_PRATICA                 NUMBER(10)             not null,
    IMPOSTA                         NUMBER(15,2)           not null
        constraint OGGETTI_IMPOS_IMPOSTA_CC check (
            IMPOSTA >= 0),
    IMPOSTA_ACCONTO                 NUMBER(15,2)           null
        constraint OGGETTI_IMPOS_IMPOSTA_ACCON_CC check (
            IMPOSTA_ACCONTO is null or (IMPOSTA_ACCONTO >= 0
            )),
    IMPOSTA_DOVUTA                  NUMBER(15,2)           null
        constraint OGGETTI_IMPOS_IMPOSTA_DOVUT_CC check (
            IMPOSTA_DOVUTA is null or (IMPOSTA_DOVUTA >= 0
            )),
    IMPOSTA_DOVUTA_ACCONTO          NUMBER(15,2)           null    ,
    IMPORTO_VERSATO                 NUMBER(15,2)           null
        constraint OGGETTI_IMPOS_IMPORTO_VERSA_CC check (
            IMPORTO_VERSATO is null or (IMPORTO_VERSATO >= 0
            )),
    TIPO_ALIQUOTA                   NUMBER(2)              null    ,
    ALIQUOTA                        NUMBER(6,2)            null    ,
    RUOLO                           NUMBER(10)             null    ,
    IMPORTO_RUOLO                   NUMBER(15,2)           null
        constraint OGGETTI_IMPOS_IMPORTO_RUOLO_CC check (
            IMPORTO_RUOLO is null or (IMPORTO_RUOLO >= 0
            )),
    FLAG_CALCOLO                    VARCHAR2(1)            null
        constraint OGGETTI_IMPOS_FLAG_CALCOLO_CC check (
            FLAG_CALCOLO is null or (FLAG_CALCOLO in ('S'))),
    UTENTE                          VARCHAR2(8)            not null,
    DATA_VARIAZIONE                 DATE                   not null,
    NOTE                            VARCHAR2(2000)         null    ,
    DETRAZIONE                      NUMBER(15,2)           null    ,
    DETRAZIONE_ACCONTO              NUMBER(15,2)           null    ,
    ADDIZIONALE_ECA                 NUMBER(15,2)           null    ,
    MAGGIORAZIONE_ECA               NUMBER(15,2)           null    ,
    ADDIZIONALE_PRO                 NUMBER(15,2)           null    ,
    IVA                             NUMBER(15,2)           null    ,
    NUM_BOLLETTINO                  NUMBER(12)             null    ,
    FATTURA                         NUMBER                 null    ,
    DETTAGLIO_OGIM                  VARCHAR2(2000)         null    ,
    ALIQUOTA_IVA                    NUMBER(6,2)            null    ,
    IMPORTO_PF                      NUMBER(15,2)           null
        constraint OGGETTI_IMPOS_IMPORTO_PF_CC check (
            IMPORTO_PF is null or (IMPORTO_PF >= 0
            )),
    IMPORTO_PV                      NUMBER(15,2)           null
        constraint OGGETTI_IMPOS_IMPORTO_PV_CC check (
            IMPORTO_PV is null or (IMPORTO_PV >= 0
            )),
    IMPONIBILE                      NUMBER(15,2)           null    ,
    IMPONIBILE_D                    NUMBER(15,2)           null    ,
    DETRAZIONE_IMPONIBILE           NUMBER(15,2)           null    ,
    DETRAZIONE_IMPONIBILE_ACCONTO   NUMBER(15,2)           null    ,
    DETRAZIONE_IMPONIBILE_D         NUMBER(15,2)           null    ,
    DETRAZIONE_IMPONIBILE_D_ACC     NUMBER(15,2)           null    ,
    DETRAZIONE_RIMANENTE_CAIN       NUMBER(15,2)           null    ,
    DETRAZIONE_RIMANENTE_CAIN_ACC   NUMBER(15,2)           null    ,
    IMPOSTA_ERARIALE                NUMBER(15,2)           null    ,
    IMPOSTA_ERARIALE_ACCONTO        NUMBER(15,2)           null    ,
    DETRAZIONE_FIGLI                NUMBER(15,2)           null    ,
    DETRAZIONE_FIGLI_ACCONTO        NUMBER(15,2)           null    ,
    ALIQUOTA_ERARIALE               NUMBER(6,2)            null    ,
    MAGGIORAZIONE_TARES             NUMBER(15,2)           null    ,
    IMPOSTA_ERARIALE_DOVUTA         NUMBER(15,2)           null    ,
    IMPOSTA_ERARIALE_DOVUTA_ACC     NUMBER(15,2)           null    ,
    ALIQUOTA_STD                    NUMBER(6,2)            null    ,
    IMPOSTA_ALIQUOTA                NUMBER(15,2)           null    ,
    IMPOSTA_STD                     NUMBER(15,2)           null    ,
    IMPOSTA_DOVUTA_STD              NUMBER(15,2)           null    ,
    IMPOSTA_MINI                    NUMBER(15,2)           null    ,
    IMPOSTA_DOVUTA_MINI             NUMBER(15,2)           null    ,
    DETRAZIONE_STD                  NUMBER(15,2)           null    ,
    TIPO_TRIBUTO                    VARCHAR2(5)            null    ,
    IMPOSTA_PRE_PERC                NUMBER(15,2)           null    ,
    IMPOSTA_ACCONTO_PRE_PERC        NUMBER(15,2)           null    ,
    TIPO_RAPPORTO                   VARCHAR2(1)            null
        constraint OGGETTI_IMPOS_TIPO_RAPPORTO_CC check (
            TIPO_RAPPORTO is null or (TIPO_RAPPORTO in ('D','C','E','A'))),
    PERCENTUALE                     NUMBER(5,2)            null    ,
    MESI_POSSESSO                   NUMBER(2)              null    ,
    MESI_AFFITTO                    NUMBER(2)              null    ,
    WRK_CALCOLO                     VARCHAR2(2000)         null    ,
    ALIQUOTA_ACCONTO                NUMBER(6,2)            null    ,
    TIPO_ALIQUOTA_PREC              NUMBER(2)              null    ,
    ALIQUOTA_PREC                   NUMBER(6,2)            null    ,
    DETRAZIONE_PREC                 NUMBER(15,2)           null    ,
    ALIQUOTA_ERAR_PREC              NUMBER(6,2)            null    ,
    TIPO_TARIFFA_BASE               VARCHAR2(2)            null    ,
    IMPOSTA_BASE                    NUMBER(15,2)           null    ,
    ADDIZIONALE_ECA_BASE            NUMBER(15,2)           null    ,
    MAGGIORAZIONE_ECA_BASE          NUMBER(15,2)           null    ,
    ADDIZIONALE_PRO_BASE            NUMBER(15,2)           null    ,
    IVA_BASE                        NUMBER(15,2)           null    ,
    IMPORTO_PF_BASE                 NUMBER(15,2)           null    ,
    IMPORTO_PV_BASE                 NUMBER(15,2)           null    ,
    IMPORTO_RUOLO_BASE              NUMBER(15,2)           null    ,
    DETTAGLIO_OGIM_BASE             VARCHAR2(2000)         null    ,
    PERC_RIDUZIONE_PF               NUMBER(5,2)            null    ,
    PERC_RIDUZIONE_PV               NUMBER(5,2)            null    ,
    IMPORTO_RIDUZIONE_PF            NUMBER(15,2)           null    ,
    IMPORTO_RIDUZIONE_PV            NUMBER(15,2)           null    ,
    DA_MESE_POSSESSO                NUMBER(2)              null    ,
    IMPOSTA_PERIODO                 NUMBER(15,2)           null    ,
    DATA_SCADENZA                   DATE                   null    ,
    constraint OGGETTI_IMPOSTA_PK primary key (OGGETTO_IMPOSTA)
        using index
)
/

comment on table OGGETTI_IMPOSTA is 'OGIM - Imposta relativa agli oggetti'
/

create sequence NR_OGIM_SEQ
MINVALUE 0
START WITH 1
INCREMENT BY 1
NOCACHE
/

-- ============================================================
--   Index: OGIM_OGPR_IK
-- ============================================================
create index OGIM_OGPR_IK on OGGETTI_IMPOSTA (OGGETTO_PRATICA asc)
/

-- ============================================================
--   Index: OGIM_CONT_IK
-- ============================================================
create index OGIM_CONT_IK on OGGETTI_IMPOSTA (COD_FISCALE asc)
/

-- ============================================================
--   Index: OGIM_ANNO_CONT_IK
-- ============================================================
create index OGIM_ANNO_CONT_IK on OGGETTI_IMPOSTA (ANNO asc, COD_FISCALE asc)
/

-- ============================================================
--   Index: OGIM_BOLL_IK
-- ============================================================
create index OGIM_BOLL_IK on OGGETTI_IMPOSTA (NUM_BOLLETTINO asc)
/

-- ============================================================
--   Index: OGIM_OGCO_FK
-- ============================================================
create index OGIM_OGCO_FK on OGGETTI_IMPOSTA (COD_FISCALE asc, OGGETTO_PRATICA asc)
/

-- ============================================================
--   Index: OGIM_RUOL_FK
-- ============================================================
create index OGIM_RUOL_FK on OGGETTI_IMPOSTA (RUOLO asc)
/

-- ============================================================
--   Index: OGIM_TIAL_FK
-- ============================================================
create index OGIM_TIAL_FK on OGGETTI_IMPOSTA (TIPO_TRIBUTO asc, TIPO_ALIQUOTA asc)
/

-- ============================================================
--   Index: OGIM_FATT_FK
-- ============================================================
create index OGIM_FATT_FK on OGGETTI_IMPOSTA (FATTURA asc)
/

-- ============================================================
--   Table: ELABORAZIONI_MASSIVE
-- ============================================================
create table ELABORAZIONI_MASSIVE
(
    ELABORAZIONE_ID                 NUMBER(10)             not null,
    NOME_ELABORAZIONE               VARCHAR2(200)          null    ,
    DATA_ELABORAZIONE               DATE                   null    ,
    TIPO_TRIBUTO                    VARCHAR2(5)            null    ,
    TIPO_PRATICA                    VARCHAR2(1)            null
        constraint ELABORAZIONI__TIPO_PRATICA_CC check (
            TIPO_PRATICA is null or (TIPO_PRATICA in ('A','D','L','I','C','K','T','V','G','S'))),
    RUOLO                           NUMBER(10)             null    ,
    UTENTE                          VARCHAR2(8)            null    ,
    DATA_VARIAZIONE                 DATE                   null    ,
    NOTE                            VARCHAR2(2000)         null    ,
    ANNO                            NUMBER(4)              null    ,
    GRUPPO_TRIBUTO                  VARCHAR2(10)           null    ,
    TIPO_ELABORAZIONE               VARCHAR2(4)            null    ,
    constraint ELABORAZIONI_MASSIVE_PK primary key (ELABORAZIONE_ID)
)
/

comment on table ELABORAZIONI_MASSIVE is 'ELMA - Elaborazioni'
/

-- ============================================================
--   Index: ELMA_RUOL_FK
-- ============================================================
create index ELMA_RUOL_FK on ELABORAZIONI_MASSIVE (RUOLO asc)
/

-- ============================================================
--   Index: ELMA_TITR_FK
-- ============================================================
create index ELMA_TITR_FK on ELABORAZIONI_MASSIVE (TIPO_TRIBUTO asc)
/

-- ============================================================
--   Index: ELMA_GRTR_FK
-- ============================================================
create index ELMA_GRTR_FK on ELABORAZIONI_MASSIVE (GRUPPO_TRIBUTO asc, TIPO_TRIBUTO asc)
/

-- ============================================================
--   Index: ELMA_TIEL_FK
-- ============================================================
create index ELMA_TIEL_FK on ELABORAZIONI_MASSIVE (TIPO_ELABORAZIONE asc)
/

-- ============================================================
--   Table: ATTIVITA_ELABORAZIONE
-- ============================================================
create table ATTIVITA_ELABORAZIONE
(
    ATTIVITA_ID                     NUMBER(10)             not null,
    ELABORAZIONE_ID                 NUMBER(10)             not null,
    DATA_ATTIVITA                   DATE                   null    ,
    TIPO_ATTIVITA                   NUMBER(2)              null    ,
    STATO_ATTIVITA                  NUMBER(2)              not null,
    TIPO_SPEDIZIONE                 VARCHAR2(2)            null    ,
    MODELLO                         NUMBER(4)              null    ,
    FLAG_F24                        VARCHAR2(1)            null
        constraint ATTIVITA_ELAB_FLAG_F24_CC check (
            FLAG_F24 is null or (FLAG_F24 in ('S'))),
    DOCUMENTO                       BLOB                   null    ,
    UTENTE                          VARCHAR2(8)            null    ,
    DATA_VARIAZIONE                 DATE                   null    ,
    NOTE                            VARCHAR2(2000)         null    ,
    TESTO_APPIO                     CLOB                   null    ,
    TIPO_TRIBUTO                    VARCHAR2(5)            null    ,
    TIPO_COMUNICAZIONE              VARCHAR2(3)            null    ,
    SEQUENZA_COMUNICAZIONE          NUMBER(4)              null    ,
    FLAG_NOTIFICA                   VARCHAR2(1)            null
        constraint ATTIVITA_ELAB_FLAG_NOTIFICA_CC check (
            FLAG_NOTIFICA is null or (FLAG_NOTIFICA in ('S'))),
    constraint ATTIVITA_ELABORAZIONE_PK primary key (ATTIVITA_ID)
)
/

comment on table ATTIVITA_ELABORAZIONE is 'ATEL - Attività Elaborazione'
/

-- ============================================================
--   Index: ATEL_ELMA_FK
-- ============================================================
create index ATEL_ELMA_FK on ATTIVITA_ELABORAZIONE (ELABORAZIONE_ID asc)
/

-- ============================================================
--   Index: ATEL_STAT_FK
-- ============================================================
create index ATEL_STAT_FK on ATTIVITA_ELABORAZIONE (STATO_ATTIVITA asc)
/

-- ============================================================
--   Index: ATEL_TISP_FK
-- ============================================================
create index ATEL_TISP_FK on ATTIVITA_ELABORAZIONE (TIPO_SPEDIZIONE asc)
/

-- ============================================================
--   Index: ATEL_TIAT_FK
-- ============================================================
create index ATEL_TIAT_FK on ATTIVITA_ELABORAZIONE (TIPO_ATTIVITA asc)
/

-- ============================================================
--   Index: ATEL_MODE_FK
-- ============================================================
create index ATEL_MODE_FK on ATTIVITA_ELABORAZIONE (MODELLO asc)
/

-- ============================================================
--   Index: ATEL_DECO_FK
-- ============================================================
create index ATEL_DECO_FK on ATTIVITA_ELABORAZIONE (TIPO_TRIBUTO asc, TIPO_COMUNICAZIONE asc, SEQUENZA_COMUNICAZIONE asc)
/

-- ============================================================
--   Table: ALIQUOTE
-- ============================================================
create table ALIQUOTE
(
    TIPO_TRIBUTO                    VARCHAR2(5)            not null,
    ANNO                            NUMBER(4)              not null,
    TIPO_ALIQUOTA                   NUMBER(2)              not null,
    ALIQUOTA                        NUMBER(6,2)            not null,
    FLAG_AB_PRINCIPALE              VARCHAR2(1)            null
        constraint ALIQUOTE_FLAG_AB_PRINC_CC check (
            FLAG_AB_PRINCIPALE is null or (FLAG_AB_PRINCIPALE in ('S'))),
    FLAG_PERTINENZE                 VARCHAR2(1)            null
        constraint ALIQUOTE_FLAG_PERTINEN_CC check (
            FLAG_PERTINENZE is null or (FLAG_PERTINENZE in ('S'))),
    ALIQUOTA_BASE                   NUMBER(6,2)            null    ,
    ALIQUOTA_ERARIALE               NUMBER(6,2)            null    ,
    ALIQUOTA_STD                    NUMBER(6,2)            null    ,
    PERC_SALDO                      NUMBER(6,2)            null    ,
    PERC_OCCUPANTE                  NUMBER(6,2)            null    ,
    FLAG_RIDUZIONE                  VARCHAR2(1)            null
        constraint ALIQUOTE_FLAG_RIDUZION_CC check (
            FLAG_RIDUZIONE is null or (FLAG_RIDUZIONE in ('S'))),
    RIDUZIONE_IMPOSTA               NUMBER(6,2)            null    ,
    NOTE                            VARCHAR2(2000)         null    ,
    SCADENZA_MINI_IMU               DATE                   null    ,
    FLAG_FABBRICATI_MERCE           VARCHAR2(1)            null
        constraint ALIQUOTE_FLAG_FABBRICA_CC check (
            FLAG_FABBRICATI_MERCE is null or (FLAG_FABBRICATI_MERCE in ('S'))),
    constraint ALIQUOTE_PK primary key (TIPO_TRIBUTO, ANNO, TIPO_ALIQUOTA)
)
/

comment on table ALIQUOTE is 'ALIQ - Aliquote'
/

-- ============================================================
--   Index: ALIQ_TIAL_FK
-- ============================================================
create index ALIQ_TIAL_FK on ALIQUOTE (TIPO_TRIBUTO asc, TIPO_ALIQUOTA asc)
/

-- ============================================================
--   Table: COMUNICAZIONE_TESTI
-- ============================================================
create table COMUNICAZIONE_TESTI
(
    COMUNICAZIONE_TESTO             NUMBER                 not null,
    TIPO_TRIBUTO                    VARCHAR2(5)            not null,
    TIPO_COMUNICAZIONE              VARCHAR2(3)            not null,
    TIPO_CANALE                     NUMBER                 not null,
    DESCRIZIONE                     VARCHAR2(200)          not null,
    OGGETTO                         VARCHAR2(200)          null    ,
    TESTO                           CLOB                   null    ,
    UTENTE                          VARCHAR2(8)            null    ,
    DATA_VARIAZIONE                 DATE                   null    ,
    NOTE                            VARCHAR2(2000)         null    ,
    constraint COMUNICAZIONE_TESTI_PK primary key (COMUNICAZIONE_TESTO)
)
/

comment on table COMUNICAZIONE_TESTI is 'COTE - Comunicaziopne Testi'
/

-- ============================================================
--   Index: COTE_COPA_FK
-- ============================================================
create index COTE_COPA_FK on COMUNICAZIONE_TESTI (TIPO_TRIBUTO asc, TIPO_COMUNICAZIONE asc)
/

-- ============================================================
--   Index: COTE_TICA_FK
-- ============================================================
create index COTE_TICA_FK on COMUNICAZIONE_TESTI (TIPO_CANALE asc)
/

-- ============================================================
--   Table: DETTAGLI_COMUNICAZIONE
-- ============================================================
create table DETTAGLI_COMUNICAZIONE
(
    TIPO_TRIBUTO                    VARCHAR2(5)            not null,
    TIPO_COMUNICAZIONE              VARCHAR2(3)            not null,
    SEQUENZA                        NUMBER(4)              not null,
    DESCRIZIONE                     VARCHAR2(100)          not null,
    TIPO_COMUNICAZIONE_PND          VARCHAR2(30)           null    ,
    TAG                             VARCHAR2(100)          null    ,
    TIPO_CANALE                     NUMBER(2)              null    ,
    constraint DETTAGLI_COMUNICAZIONE_PK primary key (TIPO_TRIBUTO, TIPO_COMUNICAZIONE, SEQUENZA)
)
/

comment on table DETTAGLI_COMUNICAZIONE is 'DECO - Dettagli Comunicazione'
/

-- ============================================================
--   Index: DECO_COPA_FK
-- ============================================================
create index DECO_COPA_FK on DETTAGLI_COMUNICAZIONE (TIPO_TRIBUTO asc, TIPO_COMUNICAZIONE asc)
/

-- ============================================================
--   Index: DECO_TICA_FK
-- ============================================================
create index DECO_TICA_FK on DETTAGLI_COMUNICAZIONE (TIPO_CANALE asc)
/

-- ============================================================
--   Table: CODICI_TRIBUTO
-- ============================================================
create table CODICI_TRIBUTO
(
    TRIBUTO                         NUMBER(4)              not null,
    DESCRIZIONE                     VARCHAR2(60)           not null,
    DESCRIZIONE_RUOLO               VARCHAR2(100)          null    ,
    TIPO_TRIBUTO                    VARCHAR2(5)            null    ,
    CONTO_CORRENTE                  NUMBER(8)              null    ,
    DESCRIZIONE_CC                  VARCHAR2(100)          null    ,
    FLAG_STAMPA_CC                  VARCHAR2(1)            null
        constraint CODICI_TRIBUT_FLAG_STAMPA_C_CC check (
            FLAG_STAMPA_CC is null or (FLAG_STAMPA_CC in ('S'))),
    FLAG_RUOLO                      VARCHAR2(1)            null
        constraint CODICI_TRIBUT_FLAG_RUOLO_CC check (
            FLAG_RUOLO is null or (FLAG_RUOLO in ('S'))),
    FLAG_CALCOLO_INTERESSI          VARCHAR2(1)            null
        constraint CODICI_TRIBUT_FLAG_CALCOLO__CC check (
            FLAG_CALCOLO_INTERESSI is null or (FLAG_CALCOLO_INTERESSI in ('S'))),
    COD_ENTRATA                     VARCHAR2(4)            null    ,
    GRUPPO_TRIBUTO                  VARCHAR2(10)           null    ,
    TIPO_TRIBUTO_PREC               VARCHAR2(5)            null    ,
    constraint CODICI_TRIBUTO_PK primary key (TRIBUTO)
)
/

comment on table CODICI_TRIBUTO is 'Codici tributo'
/

-- ============================================================
--   Index: COTR_TITR_FK
-- ============================================================
create index COTR_TITR_FK on CODICI_TRIBUTO (TIPO_TRIBUTO asc)
/

-- ============================================================
--   Index: COTR_GRTR_FK
-- ============================================================
create index COTR_GRTR_FK on CODICI_TRIBUTO (TIPO_TRIBUTO asc, GRUPPO_TRIBUTO asc)
/

-- ============================================================
--   Table: SANZIONI
-- ============================================================
create table SANZIONI
(
    TIPO_TRIBUTO                    VARCHAR2(5)            not null,
    COD_SANZIONE                    NUMBER(4)              not null,
    SEQUENZA                        NUMBER(4)              not null,
    DESCRIZIONE                     VARCHAR2(60)           not null,
    PERCENTUALE                     NUMBER(5,2)            null    ,
    SANZIONE                        NUMBER(15,2)           null
        constraint SANZIONI_SANZIONE_CC check (
            SANZIONE is null or (SANZIONE >= 0
            )),
    SANZIONE_MINIMA                 NUMBER(15,2)           null
        constraint SANZIONI_SANZIONE_MINI_CC check (
            SANZIONE_MINIMA is null or (SANZIONE_MINIMA >= 0
            )),
    RIDUZIONE                       NUMBER(5,2)            null    ,
    FLAG_IMPOSTA                    VARCHAR2(1)            null
        constraint SANZIONI_FLAG_IMPOSTA_CC check (
            FLAG_IMPOSTA is null or (FLAG_IMPOSTA in ('S'))),
    FLAG_INTERESSI                  VARCHAR2(1)            null
        constraint SANZIONI_FLAG_INTERESS_CC check (
            FLAG_INTERESSI is null or (FLAG_INTERESSI in ('S'))),
    FLAG_PENA_PECUNIARIA            VARCHAR2(1)            null
        constraint SANZIONI_FLAG_PENA_PEC_CC check (
            FLAG_PENA_PECUNIARIA is null or (FLAG_PENA_PECUNIARIA in ('S'))),
    GRUPPO_SANZIONE                 NUMBER(4)              null    ,
    TRIBUTO                         NUMBER(4)              null    ,
    FLAG_CALCOLO_INTERESSI          VARCHAR2(1)            null
        constraint SANZIONI_FLAG_CALCOLO__CC check (
            FLAG_CALCOLO_INTERESSI is null or (FLAG_CALCOLO_INTERESSI in ('S'))),
    RIDUZIONE_2                     NUMBER(5,2)            null    ,
    TIPOLOGIA_RUOLO                 NUMBER(1)              null
        constraint SANZIONI_TIPOLOGIA_RUO_CC check (
            TIPOLOGIA_RUOLO is null or (TIPOLOGIA_RUOLO in (1,2,3))),
    TIPO_CAUSALE                    VARCHAR2(10)           null
        constraint SANZIONI_TIPO_CAUSALE_CC check (
            TIPO_CAUSALE is null or (TIPO_CAUSALE in ('E','O','P','S','T','TP30','I'))),
    RATA                            NUMBER(2)              null    ,
    FLAG_MAGG_TARES                 VARCHAR2(1)            null
        constraint SANZIONI_FLAG_MAGG_TAR_CC check (
            FLAG_MAGG_TARES is null or (FLAG_MAGG_TARES in ('S'))),
    COD_TRIBUTO_F24                 VARCHAR2(4)            null    ,
    TIPO_VERSAMENTO                 VARCHAR2(1)            null    ,
    DATA_INIZIO                     DATE                   not null,
    DATA_FINE                       DATE                   not null,
    UTENTE                          VARCHAR2(8)            null    ,
    DATA_VARIAZIONE                 DATE                   null    ,
    NOTE                            VARCHAR2(2000)         null    ,
    constraint SANZIONI_PK primary key (TIPO_TRIBUTO, COD_SANZIONE, SEQUENZA)
)
/

comment on table SANZIONI is 'SANZ - Sanzioni'
/

-- ============================================================
--   Index: SANZ_COTR_FK
-- ============================================================
create index SANZ_COTR_FK on SANZIONI (TRIBUTO asc)
/

-- ============================================================
--   Index: SANZ_TITR_FK
-- ============================================================
create index SANZ_TITR_FK on SANZIONI (TIPO_TRIBUTO asc)
/

-- ============================================================
--   Index: SANZ_GRSA_FK
-- ============================================================
create index SANZ_GRSA_FK on SANZIONI (GRUPPO_SANZIONE asc)
/

-- ============================================================
--   Table: CATEGORIE
-- ============================================================
create table CATEGORIE
(
    TRIBUTO                         NUMBER(4)              not null,
    CATEGORIA                       NUMBER(4)              not null,
    DESCRIZIONE                     VARCHAR2(100)          not null,
    CATEGORIA_RIF                   NUMBER(4)              null    ,
    DESCRIZIONE_PREC                VARCHAR2(100)          null    ,
    FLAG_DOMESTICA                  VARCHAR2(1)            null
        constraint CATEGORIE_FLAG_DOMESTIC_CC check (
            FLAG_DOMESTICA is null or (FLAG_DOMESTICA in ('S'))),
    FLAG_GIORNI                     VARCHAR2(1)            null
        constraint CATEGORIE_FLAG_GIORNI_CC check (
            FLAG_GIORNI is null or (FLAG_GIORNI in ('S'))),
    ENTE                            VARCHAR2(4)            null    ,
    ID_CATEGORIA                    VARCHAR2(8)            null    ,
    FLAG_NO_DEPAG                   VARCHAR2(1)            null
        constraint CATEGORIE_FLAG_NO_DEPAG_CC check (
            FLAG_NO_DEPAG is null or (FLAG_NO_DEPAG in ('S'))),
    constraint CATEGORIE_PK primary key (TRIBUTO, CATEGORIA)
)
/

comment on table CATEGORIE is 'Categorie di tributo'
/

-- ============================================================
--   Index: CATE_ID_CATEGORIA_UK
-- ============================================================
create unique index CATE_ID_CATEGORIA_UK on CATEGORIE (ID_CATEGORIA asc)
/

-- ============================================================
--   Index: CATE_COTR_FK
-- ============================================================
create index CATE_COTR_FK on CATEGORIE (TRIBUTO asc)
/

-- ============================================================
--   Index: CATE_CATE_FK
-- ============================================================
create index CATE_CATE_FK on CATEGORIE (TRIBUTO asc, CATEGORIA_RIF asc)
/

-- ============================================================
--   Table: TARIFFE
-- ============================================================
create table TARIFFE
(
    TRIBUTO                         NUMBER(4)              not null,
    CATEGORIA                       NUMBER(4)              not null,
    ANNO                            NUMBER(4)              not null,
    TIPO_TARIFFA                    NUMBER(2)              not null,
    DESCRIZIONE                     VARCHAR2(100)          null    ,
    TARIFFA                         NUMBER(11,5)           not null,
    PERC_RIDUZIONE                  NUMBER(5,2)            null    ,
    LIMITE                          NUMBER(11,5)           null    ,
    TARIFFA_SUPERIORE               NUMBER(11,5)           null    ,
    LIMITE_PREC                     NUMBER(11,5)           null    ,
    TARIFFA_PREC                    NUMBER(11,5)           null    ,
    TARIFFA_SUPERIORE_PREC          NUMBER(11,5)           null    ,
    TARIFFA_QUOTA_FISSA             NUMBER(11,5)           null    ,
    ENTE                            VARCHAR2(4)            null    ,
    FLAG_TARIFFA_BASE               VARCHAR2(1)            null
        constraint TARIFFE_FLAG_TARIFFA__CC check (
            FLAG_TARIFFA_BASE is null or (FLAG_TARIFFA_BASE in ('S'))),
    RIDUZIONE_QUOTA_FISSA           NUMBER(5,2)            null    ,
    RIDUZIONE_QUOTA_VARIABILE       NUMBER(5,2)            null    ,
    ID_TARIFFA                      NUMBER(14)             null    ,
    ID_CATEGORIA                    VARCHAR2(8)            null    ,
    TIPOLOGIA_TARIFFA               NUMBER(4)              null    ,
    TIPOLOGIA_SECONDARIA            NUMBER(4)              null    ,
    FLAG_NO_DEPAG                   VARCHAR2(1)            null
        constraint TARIFFE_FLAG_NO_DEPAG_CC check (
            FLAG_NO_DEPAG is null or (FLAG_NO_DEPAG in ('S'))),
    constraint TARIFFE_PK primary key (TRIBUTO, CATEGORIA, ANNO, TIPO_TARIFFA)
)
/

comment on table TARIFFE is 'TARI - Tariffe di categoria tributaria'
/

-- ============================================================
--   Index: TARI_ANNO_IK
-- ============================================================
create index TARI_ANNO_IK on TARIFFE (ANNO asc)
/

-- ============================================================
--   Index: TARI_CATE_FK
-- ============================================================
create index TARI_CATE_FK on TARIFFE (TRIBUTO asc, CATEGORIA asc)
/

-- ============================================================
--   Index: TARI_ID_TARIFFA_UK
-- ============================================================
create unique index TARI_ID_TARIFFA_UK on TARIFFE (ID_TARIFFA asc)
/

-- ============================================================
--   Index: TARI_ID_CATEGORIA_UK
-- ============================================================
create index TARI_ID_CATEGORIA_UK on TARIFFE (ID_CATEGORIA asc)
/

-- ============================================================
--   Table: SOGGETTI
-- ============================================================
create table SOGGETTI
(
    NI                              NUMBER(10)             not null,
    TIPO_RESIDENTE                  NUMBER(1)              not null
        constraint SOGGETTI_TIPO_RESIDENT_CC check (
            TIPO_RESIDENTE in (0,1)),
    MATRICOLA                       NUMBER(10)             null    ,
    COD_FISCALE                     VARCHAR2(16)           null    ,
    COGNOME_NOME                    VARCHAR2(100)          not null,
    FASCIA                          NUMBER(2)              null
        constraint SOGGETTI_FASCIA_CC check (
            FASCIA is null or (FASCIA in (1,2,3,4,5,6))),
    STATO                           NUMBER(2)              null    ,
    DATA_ULT_EVE                    DATE                   null    ,
    COD_PRO_EVE                     NUMBER(3)              null    ,
    COD_COM_EVE                     NUMBER(3)              null    ,
    SESSO                           VARCHAR2(1)            null
        constraint SOGGETTI_SESSO_CC check (
            SESSO is null or (SESSO in ('M','F'))),
    COD_FAM                         NUMBER(10)             null    ,
    RAPPORTO_PAR                    VARCHAR2(2)            null    ,
    SEQUENZA_PAR                    NUMBER(2)              null    ,
    DATA_NAS                        DATE                   null    ,
    COD_PRO_NAS                     NUMBER(3)              null    ,
    COD_COM_NAS                     NUMBER(3)              null    ,
    COD_PRO_RES                     NUMBER(3)              null    ,
    COD_COM_RES                     NUMBER(3)              null    ,
    CAP                             NUMBER(5)              null    ,
    COD_PROF                        NUMBER(5)              null    ,
    PENSIONATO                      NUMBER(1)              null
        constraint SOGGETTI_PENSIONATO_CC check (
            PENSIONATO is null or (PENSIONATO in (1))),
    DENOMINAZIONE_VIA               VARCHAR2(60)           null    ,
    COD_VIA                         NUMBER(6)              null    ,
    NUM_CIV                         NUMBER(6)              null    ,
    SUFFISSO                        VARCHAR2(10)           null    ,
    SCALA                           VARCHAR2(5)            null    ,
    PIANO                           VARCHAR2(5)            null    ,
    INTERNO                         NUMBER(4)              null    ,
    PARTITA_IVA                     VARCHAR2(11)           null    ,
    RAPPRESENTANTE                  VARCHAR2(40)           null    ,
    INDIRIZZO_RAP                   VARCHAR2(50)           null    ,
    COD_PRO_RAP                     NUMBER(3)              null    ,
    COD_COM_RAP                     NUMBER(3)              null    ,
    COD_FISCALE_RAP                 VARCHAR2(16)           null    ,
    TIPO_CARICA                     NUMBER(4)              null    ,
    FLAG_ESENZIONE                  VARCHAR2(1)            null
        constraint SOGGETTI_FLAG_ESENZION_CC check (
            FLAG_ESENZIONE is null or (FLAG_ESENZIONE in ('S'))),
    TIPO                            VARCHAR2(1)            not null
        constraint SOGGETTI_TIPO_CC check (
            TIPO in ('0','1','2')),
    GRUPPO_UTENTE                   VARCHAR2(1)            null    ,
    FLAG_CF_CALCOLATO               VARCHAR2(1)            null
        constraint SOGGETTI_FLAG_CF_CALCO_CC check (
            FLAG_CF_CALCOLATO is null or (FLAG_CF_CALCOLATO in ('S'))),
    COGNOME                         VARCHAR2(100)          null    ,
    NOME                            VARCHAR2(100)          null    ,
    UTENTE                          VARCHAR2(8)            not null,
    DATA_VARIAZIONE                 DATE                   not null,
    NOTE                            VARCHAR2(2000)         null    ,
    NI_PRESSO                       NUMBER(10)             null    ,
    INTESTATARIO_FAM                VARCHAR2(100)          null    ,
    FONTE                           NUMBER(2)              null    ,
    ZIPCODE                         VARCHAR2(10)           null    ,
    ENTE                            VARCHAR2(4)            null    ,
    COGNOME_NOME_RIC                VARCHAR2(100)          null    ,
    COGNOME_RIC                     VARCHAR2(100)          null    ,
    NOME_RIC                        VARCHAR2(100)          null    ,
    constraint SOGGETTI_PK primary key (NI)
        using index
)
/

comment on table SOGGETTI is 'SOGG - Soggetti'
/

-- ============================================================
--   Index: SOGG_COD_FISCALE_IK
-- ============================================================
create index SOGG_COD_FISCALE_IK on SOGGETTI (COD_FISCALE asc)
/

-- ============================================================
--   Index: SOGG_COGNOME_NOME_IK
-- ============================================================
create index SOGG_COGNOME_NOME_IK on SOGGETTI (COGNOME_NOME asc)
/

-- ============================================================
--   Index: SOGG_TIPO_RESIDENTE_IK
-- ============================================================
create index SOGG_TIPO_RESIDENTE_IK on SOGGETTI (TIPO_RESIDENTE asc, MATRICOLA asc)
/

-- ============================================================
--   Index: SOGG_COGNOME_IK
-- ============================================================
create index SOGG_COGNOME_IK on SOGGETTI (COGNOME asc, NOME asc)
/

-- ============================================================
--   Index: SOGG_FASCIA_IK
-- ============================================================
create index SOGG_FASCIA_IK on SOGGETTI (FASCIA asc, COD_FAM asc)
/

-- ============================================================
--   Index: SOGG_PARTITA_IVA_IK
-- ============================================================
create index SOGG_PARTITA_IVA_IK on SOGGETTI (PARTITA_IVA asc)
/

-- ============================================================
--   Index: SOGG_TICA_FK
-- ============================================================
create index SOGG_TICA_FK on SOGGETTI (TIPO_CARICA asc)
/

-- ============================================================
--   Index: SOGG_ARVI_FK
-- ============================================================
create index SOGG_ARVI_FK on SOGGETTI (COD_VIA asc)
/

-- ============================================================
--   Index: SOGG_SOGG1_FK
-- ============================================================
create index SOGG_SOGG1_FK on SOGGETTI (NI_PRESSO asc)
/

-- ============================================================
--   Index: SOGG_FONT_FK
-- ============================================================
create index SOGG_FONT_FK on SOGGETTI (FONTE asc)
/

-- ============================================================
--   Index: SOGG_COGNOME_RIC_IK
-- ============================================================
create index SOGG_COGNOME_RIC_IK on SOGGETTI (COGNOME_RIC asc)
/

-- ============================================================
--   Index: SOGG_NOME_RIC_IK
-- ============================================================
create index SOGG_NOME_RIC_IK on SOGGETTI (NOME_RIC asc)
/

-- ============================================================
--   Index: SOGG_COGNOME_NOME_RIC_IK
-- ============================================================
create index SOGG_COGNOME_NOME_RIC_IK on SOGGETTI (COGNOME_NOME_RIC asc)
/

-- ============================================================
--   Table: STO_OGGETTI
-- ============================================================
create table STO_OGGETTI
(
    OGGETTO                         NUMBER(10)             not null
        constraint STO_OGGETTI_OGGETTO_CC check (
            OGGETTO >= 0),
    DESCRIZIONE                     VARCHAR2(60)           null    ,
    EDIFICIO                        NUMBER(10)             null    ,
    TIPO_OGGETTO                    NUMBER(2)              not null,
    INDIRIZZO_LOCALITA              VARCHAR2(36)           null    ,
    COD_VIA                         NUMBER(6)              null    ,
    NUM_CIV                         NUMBER(6)              null    ,
    SUFFISSO                        VARCHAR2(10)           null    ,
    SCALA                           VARCHAR2(5)            null    ,
    PIANO                           VARCHAR2(5)            null    ,
    INTERNO                         NUMBER(4)              null    ,
    SEZIONE                         VARCHAR2(3)            null    ,
    FOGLIO                          VARCHAR2(5)            null    ,
    NUMERO                          VARCHAR2(5)            null    ,
    SUBALTERNO                      VARCHAR2(4)            null    ,
    ZONA                            VARCHAR2(3)            null    ,
    ESTREMI_CATASTO                 VARCHAR2(20)           null    ,
    PARTITA                         VARCHAR2(8)            null    ,
    PROGR_PARTITA                   NUMBER(9)              null    ,
    PROTOCOLLO_CATASTO              VARCHAR2(6)            null    ,
    ANNO_CATASTO                    NUMBER(4)              null    ,
    CATEGORIA_CATASTO               VARCHAR2(3)            null    ,
    CLASSE_CATASTO                  VARCHAR2(2)            null    ,
    TIPO_USO                        NUMBER(2)              null    ,
    CONSISTENZA                     NUMBER(8,2)            null    ,
    VANI                            NUMBER(8,2)            null    ,
    QUALITA                         VARCHAR2(60)           null    ,
    ETTARI                          NUMBER(5)              null    ,
    ARE                             NUMBER(2)              null    ,
    CENTIARE                        NUMBER(2)              null    ,
    FLAG_SOSTITUITO                 VARCHAR2(1)            null
        constraint STO_OGGETTI_FLAG_SOSTITUI_CC check (
            FLAG_SOSTITUITO is null or (FLAG_SOSTITUITO in ('S'))),
    FLAG_COSTRUITO_ENTE             VARCHAR2(1)            null
        constraint STO_OGGETTI_FLAG_COSTRUIT_CC check (
            FLAG_COSTRUITO_ENTE is null or (FLAG_COSTRUITO_ENTE in ('S'))),
    FONTE                           NUMBER(2)              not null,
    UTENTE                          VARCHAR2(8)            not null,
    DATA_VARIAZIONE                 DATE                   not null,
    NOTE                            VARCHAR2(2000)         null    ,
    COD_ECOGRAFICO                  VARCHAR2(15)           null    ,
    TIPO_QUALITA                    NUMBER(4)              null    ,
    DATA_CESSAZIONE                 DATE                   null    ,
    SUPERFICIE                      NUMBER(8,2)            null    ,
    ID_IMMOBILE                     NUMBER(9)              null    ,
    ENTE                            VARCHAR2(4)            null    ,
    constraint STO_OGGETTI_PK primary key (OGGETTO)
)
/

comment on table STO_OGGETTI is 'SOGGE - Sto Oggetti'
/

-- ============================================================
--   Index: SOGGE_CATASTO_IK
-- ============================================================
create index SOGGE_CATASTO_IK on STO_OGGETTI (ANNO_CATASTO asc, PROTOCOLLO_CATASTO asc)
/

-- ============================================================
--   Index: SOGGE_ESTREMI1_IK
-- ============================================================
create index SOGGE_ESTREMI1_IK on STO_OGGETTI (ESTREMI_CATASTO asc)
/

-- ============================================================
--   Index: SOGGE_ESTREMI_IK
-- ============================================================
create index SOGGE_ESTREMI_IK on STO_OGGETTI (FOGLIO asc, NUMERO asc, SUBALTERNO asc, SEZIONE asc)
/

-- ============================================================
--   Index: SOGGE_IDIM_IK
-- ============================================================
create index SOGGE_IDIM_IK on STO_OGGETTI (ID_IMMOBILE asc)
/

-- ============================================================
--   Index: SOGGE_EDIF_FK
-- ============================================================
create index SOGGE_EDIF_FK on STO_OGGETTI (EDIFICIO asc)
/

-- ============================================================
--   Index: SOGGE_FONT_FK
-- ============================================================
create index SOGGE_FONT_FK on STO_OGGETTI (FONTE asc)
/

-- ============================================================
--   Index: SOGGE_TIOG_FK
-- ============================================================
create index SOGGE_TIOG_FK on STO_OGGETTI (TIPO_OGGETTO asc)
/

-- ============================================================
--   Index: SOGGE_TIUS_FK
-- ============================================================
create index SOGGE_TIUS_FK on STO_OGGETTI (TIPO_USO asc)
/

-- ============================================================
--   Index: SOGGE_ARVI_FK
-- ============================================================
create index SOGGE_ARVI_FK on STO_OGGETTI (COD_VIA asc)
/

-- ============================================================
--   Index: SOGGE_CACA_FK
-- ============================================================
create index SOGGE_CACA_FK on STO_OGGETTI (CATEGORIA_CATASTO asc)
/

-- ============================================================
--   Table: CONTRIBUENTI
-- ============================================================
create table CONTRIBUENTI
(
    COD_FISCALE                     VARCHAR2(16)           not null,
    NI                              NUMBER(10)             not null,
    COD_CONTRIBUENTE                NUMBER(8)              null    ,
    COD_CONTROLLO                   NUMBER(2)              null    ,
    NOTE                            VARCHAR2(2000)         null    ,
    COD_ATTIVITA                    VARCHAR2(5)            null    ,
    ENTE                            VARCHAR2(4)            null    ,
    constraint CONTRIBUENTI_PK primary key (COD_FISCALE)
        using index
)
/

comment on table CONTRIBUENTI is 'CONT - Contribuenti'
/

-- ============================================================
--   Index: CONT_COD_IK
-- ============================================================
create unique index CONT_COD_IK on CONTRIBUENTI (COD_CONTRIBUENTE asc)
/

-- ============================================================
--   Index: CONT_SOGG_FK
-- ============================================================
-- create index CONT_SOGG_FK on CONTRIBUENTI (NI asc)
-- /

-- ============================================================
--   Index: CONT_SOGG_UK
-- ============================================================
create unique index CONT_SOGG_UK on CONTRIBUENTI (NI asc)
/

-- ============================================================
--   Table: EDIFICI
-- ============================================================
create table EDIFICI
(
    EDIFICIO                        NUMBER(10)             not null,
    NUM_UI                          NUMBER(4)              null    ,
    DESCRIZIONE                     VARCHAR2(60)           null    ,
    AMMINISTRATORE                  NUMBER(10)             null    ,
    NOTE                            VARCHAR2(2000)         null    ,
    constraint EDIFICI_PK primary key (EDIFICIO)
)
/

comment on table EDIFICI is 'EDIF - Edifici'
/

-- ============================================================
--   Index: EDIF_SOGG_FK
-- ============================================================
create index EDIF_SOGG_FK on EDIFICI (AMMINISTRATORE asc)
/

-- ============================================================
--   Table: EREDI_SOGGETTO
-- ============================================================
create table EREDI_SOGGETTO
(
    NI                              NUMBER(10)             not null,
    NI_EREDE                        NUMBER(10)             not null,
    NUMERO_ORDINE                   NUMBER(2)              not null,
    UTENTE                          VARCHAR2(8)            null    ,
    DATA_VARIAZIONE                 DATE                   null    ,
    NOTE                            VARCHAR2(2000)         null    ,
    constraint EREDI_SOGGETTO_PK primary key (NI, NI_EREDE)
)
/

comment on table EREDI_SOGGETTO is 'ERSO - Eredi Soggetto'
/

-- ============================================================
--   Index: ERSO_SOGG_FK
-- ============================================================
create index ERSO_SOGG_FK on EREDI_SOGGETTO (NI asc)
/

-- ============================================================
--   Index: ERSO_SOGG1_FK
-- ============================================================
create index ERSO_SOGG1_FK on EREDI_SOGGETTO (NI_EREDE asc)
/

-- ============================================================
--   Table: OGGETTI_CONTRIBUENTE
-- ============================================================
create table OGGETTI_CONTRIBUENTE
(
    COD_FISCALE                     VARCHAR2(16)           not null,
    OGGETTO_PRATICA                 NUMBER(10)             not null,
    ANNO                            NUMBER(4)              not null,
    TIPO_RAPPORTO                   VARCHAR2(1)            null
        constraint OGGETTI_CONTR_TIPO_RAPPORTO_CC check (
            TIPO_RAPPORTO is null or (TIPO_RAPPORTO in ('D','C','E','A'))),
    INIZIO_OCCUPAZIONE              DATE                   null    ,
    FINE_OCCUPAZIONE                DATE                   null    ,
    DATA_DECORRENZA                 DATE                   null    ,
    DATA_CESSAZIONE                 DATE                   null    ,
    PERC_POSSESSO                   NUMBER(5,2)            null    ,
    MESI_POSSESSO                   NUMBER(2)              null    ,
    MESI_POSSESSO_1SEM              NUMBER(1)              null    ,
    MESI_ESCLUSIONE                 NUMBER(2)              null    ,
    MESI_RIDUZIONE                  NUMBER(2)              null    ,
    MESI_ALIQUOTA_RIDOTTA           NUMBER(2)              null    ,
    DETRAZIONE                      NUMBER(15,2)           null
        constraint OGGETTI_CONTR_DETRAZIONE_CC check (
            DETRAZIONE is null or (DETRAZIONE >= 0
            )),
    FLAG_POSSESSO                   VARCHAR2(1)            null
        constraint OGGETTI_CONTR_FLAG_POSSESSO_CC check (
            FLAG_POSSESSO is null or (FLAG_POSSESSO in ('S'))),
    FLAG_ESCLUSIONE                 VARCHAR2(1)            null
        constraint OGGETTI_CONTR_FLAG_ESCLUSIO_CC check (
            FLAG_ESCLUSIONE is null or (FLAG_ESCLUSIONE in ('S'))),
    FLAG_RIDUZIONE                  VARCHAR2(1)            null
        constraint OGGETTI_CONTR_FLAG_RIDUZION_CC check (
            FLAG_RIDUZIONE is null or (FLAG_RIDUZIONE in ('S'))),
    FLAG_AB_PRINCIPALE              VARCHAR2(1)            null
        constraint OGGETTI_CONTR_FLAG_AB_PRINC_CC check (
            FLAG_AB_PRINCIPALE is null or (FLAG_AB_PRINCIPALE in ('S'))),
    FLAG_AL_RIDOTTA                 VARCHAR2(1)            null
        constraint OGGETTI_CONTR_FLAG_AL_RIDOT_CC check (
            FLAG_AL_RIDOTTA is null or (FLAG_AL_RIDOTTA in ('S'))),
    UTENTE                          VARCHAR2(8)            not null,
    DATA_VARIAZIONE                 DATE                   not null,
    NOTE                            VARCHAR2(2000)         null    ,
    SUCCESSIONE                     NUMBER(10)             null    ,
    PROGRESSIVO_SUDV                NUMBER(5)              null    ,
    TIPO_RAPPORTO_K                 VARCHAR2(1)            null
        constraint OGGETTI_CONTR_TIPO_RAPPOR_K_CC check (
            TIPO_RAPPORTO_K is null or (TIPO_RAPPORTO_K in ('D','C','E','A'))),
    PERC_DETRAZIONE                 NUMBER(6,2)            null    ,
    MESI_OCCUPATO                   NUMBER(2)              null    ,
    MESI_OCCUPATO_1SEM              NUMBER(1)              null    ,
    DA_MESE_POSSESSO                NUMBER(2)              null    ,
    DA_MESE_ESCLUSIONE              NUMBER(2)              null    ,
    DA_MESE_RIDUZIONE               NUMBER(2)              null    ,
    DA_MESE_AL_RIDOTTA              NUMBER(2)              null    ,
    DATA_EVENTO                     DATE                   null    ,
    FLAG_PUNTO_RACCOLTA             VARCHAR2(1)            null
        constraint OGGETTI_CONTR_FLAG_PUNTO_RA_CC check (
            FLAG_PUNTO_RACCOLTA is null or (FLAG_PUNTO_RACCOLTA in ('S'))),
    constraint OGGETTI_CONTRIBUENTE_PK primary key (COD_FISCALE, OGGETTO_PRATICA)
        using index
)
/

comment on table OGGETTI_CONTRIBUENTE is 'OGCO - Oggetti per Contribuente'
/

-- ============================================================
--   Index: OGCO_CONT_FK
-- ============================================================
create index OGCO_CONT_FK on OGGETTI_CONTRIBUENTE (COD_FISCALE asc)
/

-- ============================================================
--   Index: OGCO_OGPR_FK
-- ============================================================
create index OGCO_OGPR_FK on OGGETTI_CONTRIBUENTE (OGGETTO_PRATICA asc)
/

-- ============================================================
--   Table: PRATICHE_TRIBUTO
-- ============================================================
create table PRATICHE_TRIBUTO
(
    PRATICA                         NUMBER(10)             not null,
    COD_FISCALE                     VARCHAR2(16)           not null,
    TIPO_TRIBUTO                    VARCHAR2(5)            not null,
    ANNO                            NUMBER(4)              not null,
    TIPO_PRATICA                    VARCHAR2(1)            not null
        constraint PRATICHE_TRIB_TIPO_PRATICA_CC check (
            TIPO_PRATICA in ('A','D','L','I','C','K','T','V','G','S')),
    TIPO_EVENTO                     VARCHAR2(1)            not null
        constraint PRATICHE_TRIB_TIPO_EVENTO_CC check (
            TIPO_EVENTO in ('I','V','C','U','R','T','A','S')),
    DATA                            DATE                   null    ,
    NUMERO                          VARCHAR2(15)           null    ,
    TIPO_CARICA                     NUMBER(4)              null    ,
    DENUNCIANTE                     VARCHAR2(60)           null    ,
    INDIRIZZO_DEN                   VARCHAR2(50)           null    ,
    COD_PRO_DEN                     NUMBER(3)              null    ,
    COD_COM_DEN                     NUMBER(3)              null    ,
    COD_FISCALE_DEN                 VARCHAR2(16)           null    ,
    PARTITA_IVA_DEN                 VARCHAR2(11)           null    ,
    DATA_NOTIFICA                   DATE                   null    ,
    IMPOSTA_TOTALE                  NUMBER(15,2)           null    ,
    IMPORTO_TOTALE                  NUMBER(15,2)           null    ,
    IMPORTO_RIDOTTO                 NUMBER(15,2)           null    ,
    STATO_ACCERTAMENTO              VARCHAR2(2)            null    ,
    MOTIVO                          VARCHAR2(2000)         null    ,
    PRATICA_RIF                     NUMBER(10)             null    ,
    UTENTE                          VARCHAR2(8)            not null,
    DATA_VARIAZIONE                 DATE                   not null,
    NOTE                            VARCHAR2(2000)         null    ,
    FLAG_ADESIONE                   VARCHAR2(1)            null
        constraint PRATICHE_TRIB_FLAG_ADESIONE_CC check (
            FLAG_ADESIONE is null or (FLAG_ADESIONE in ('S'))),
    IMPOSTA_DOVUTA_TOTALE           NUMBER(15,2)           null    ,
    FLAG_DENUNCIA                   VARCHAR2(1)            null
        constraint PRATICHE_TRIB_FLAG_DENUNCIA_CC check (
            FLAG_DENUNCIA is null or (FLAG_DENUNCIA in ('S'))),
    FLAG_ANNULLAMENTO               VARCHAR2(1)            null
        constraint PRATICHE_TRIB_FLAG_ANNULLAM_CC check (
            FLAG_ANNULLAMENTO is null or (FLAG_ANNULLAMENTO in ('S'))),
    IMPORTO_RIDOTTO_2               NUMBER(15,2)           null    ,
    TIPO_ATTO                       NUMBER(2)              null    ,
    DOCUMENTO_ID                    NUMBER(10)             null    ,
    DOCUMENTO_MULTI_ID              NUMBER(10)             null    ,
    TIPO_CALCOLO                    VARCHAR2(1)            null    ,
    ENTE                            VARCHAR2(4)            null    ,
    DATA_RATEAZIONE                 DATE                   null    ,
    MORA                            NUMBER(15,2)           null    ,
    RATE                            NUMBER(2)              null    ,
    TIPOLOGIA_RATE                  VARCHAR2(1)            null
        constraint PRATICHE_TRIB_TIPOLOGIA_RAT_CC check (
            TIPOLOGIA_RATE is null or (TIPOLOGIA_RATE in ('M','B','T','Q','S','A'))),
    IMPORTO_RATE                    NUMBER(15,2)           null    ,
    ALIQUOTA_RATE                   NUMBER(6,4)            null    ,
    VERSATO_PRE_RATE                NUMBER(15,2)           null    ,
    TIPO_RAVVEDIMENTO               VARCHAR2(1)            null
        constraint PRATICHE_TRIB_TIPO_RAVVEDIM_CC check (
            TIPO_RAVVEDIMENTO is null or (TIPO_RAVVEDIMENTO in ('D','V'))),
    FLAG_DEPAG                      VARCHAR2(1)            null
        constraint PRATICHE_TRIB_FLAG_DEPAG_CC check (
            FLAG_DEPAG is null or (FLAG_DEPAG in ('S'))),
    DATA_SCADENZA                   DATE                   null    ,
    TIPO_VIOLAZIONE                 VARCHAR2(2)            null
        constraint PRATICHE_TRIB_TIPO_VIOLAZIO_CC check (
            TIPO_VIOLAZIONE is null or (TIPO_VIOLAZIONE in ('OD','ID'))),
    CALCOLO_RATE                    VARCHAR2(1)            null
        constraint PRATICHE_TRIB_CALCOLO_RATE_CC check (
            CALCOLO_RATE is null or (CALCOLO_RATE in ('C','R','V'))),
    FLAG_INT_RATE_SOLO_EVASA        VARCHAR2(1)            null
        constraint PRATICHE_TRIB_FLAG_INT_RATE_CC check (
            FLAG_INT_RATE_SOLO_EVASA is null or (FLAG_INT_RATE_SOLO_EVASA in ('S'))),
    TIPO_NOTIFICA                   NUMBER(2)              null    ,
    FLAG_RATE_ONERI                 VARCHAR2(1)            null
        constraint PRATICHE_TRIB_FLAG_RATE_ONE_CC check (
            FLAG_RATE_ONERI is null or (FLAG_RATE_ONERI in ('S'))),
    SCADENZA_PRIMA_RATA             DATE                   null    ,
    DATA_RIF_RAVVEDIMENTO           DATE                   null    ,
    FLAG_SANZ_MIN_RID               VARCHAR2(1)            null
        constraint PRATICHE_TRIB_FLAG_SANZ_MIN_CC check (
            FLAG_SANZ_MIN_RID is null or (FLAG_SANZ_MIN_RID in ('S'))),
    constraint PRATICHE_TRIBUTO_PK primary key (PRATICA)
        using index
)
/

comment on table PRATICHE_TRIBUTO is 'PRTR - Pratiche Tributo'
/

create sequence NR_PRTR_SEQ
MINVALUE 0
START WITH 1
INCREMENT BY 1
NOCACHE
/

-- ============================================================
--   Index: PRTR_ANNO_IK
-- ============================================================
create index PRTR_ANNO_IK on PRATICHE_TRIBUTO (ANNO asc, TIPO_TRIBUTO asc, TIPO_PRATICA asc)
/

-- ============================================================
--   Index: PRTR_CONT_FK
-- ============================================================
create index PRTR_CONT_FK on PRATICHE_TRIBUTO (COD_FISCALE asc)
/

-- ============================================================
--   Index: PRTR_TICA_FK
-- ============================================================
create index PRTR_TICA_FK on PRATICHE_TRIBUTO (TIPO_CARICA asc)
/

-- ============================================================
--   Index: PRTR_PRTR1_FK
-- ============================================================
create index PRTR_PRTR1_FK on PRATICHE_TRIBUTO (PRATICA_RIF asc)
/

-- ============================================================
--   Index: PRTR_TIST_FK
-- ============================================================
create index PRTR_TIST_FK on PRATICHE_TRIBUTO (STATO_ACCERTAMENTO asc)
/

-- ============================================================
--   Index: PRTR_TIAT_FK
-- ============================================================
create index PRTR_TIAT_FK on PRATICHE_TRIBUTO (TIPO_ATTO asc)
/

-- ============================================================
--   Index: PRTR_DCMU_FK
-- ============================================================
create index PRTR_DCMU_FK on PRATICHE_TRIBUTO (DOCUMENTO_ID asc, DOCUMENTO_MULTI_ID asc)
/

-- ============================================================
--   Index: PRTR_TINO_FK
-- ============================================================
create index PRTR_TINO_FK on PRATICHE_TRIBUTO (TIPO_NOTIFICA asc)
/

-- ============================================================
--   Table: RUOLI_CONTRIBUENTE
-- ============================================================
create table RUOLI_CONTRIBUENTE
(
    RUOLO                           NUMBER(10)             not null,
    COD_FISCALE                     VARCHAR2(16)           not null,
    SEQUENZA                        NUMBER(4)              not null,
    OGGETTO_IMPOSTA                 NUMBER(10)             null    ,
    PRATICA                         NUMBER(10)             null    ,
    TRIBUTO                         NUMBER(4)              not null,
    CONSISTENZA                     NUMBER(8,2)            null    ,
    IMPORTO                         NUMBER(15,2)           not null
        constraint RUOLI_CONTRIB_IMPORTO_CC check (
            IMPORTO >= 0),
    SEMESTRI                        NUMBER(2)              null    ,
    DECORRENZA_INTERESSI            DATE                   null    ,
    MESI_RUOLO                      NUMBER(2)              null    ,
    DATA_CARTELLA                   DATE                   null    ,
    NUMERO_CARTELLA                 VARCHAR2(20)           null    ,
    UTENTE                          VARCHAR2(8)            not null,
    DATA_VARIAZIONE                 DATE                   not null,
    NOTE                            VARCHAR2(2000)         null    ,
    DA_MESE                         NUMBER(2)              null    ,
    A_MESE                          NUMBER(2)              null    ,
    GIORNI_RUOLO                    NUMBER(4)              null    ,
    IMPORTO_BASE                    NUMBER(15,2)           null    ,
    constraint RUOLI_CONTRIBUENTE_PK primary key (RUOLO, COD_FISCALE, SEQUENZA)
        using index
)
/

comment on table RUOLI_CONTRIBUENTE is 'RUCO - Ruoli Contribuente'
/

-- ============================================================
--   Index: RUCO_PRTR_FK
-- ============================================================
create index RUCO_PRTR_FK on RUOLI_CONTRIBUENTE (PRATICA asc)
/

-- ============================================================
--   Index: RUCO_COTR_FK
-- ============================================================
create index RUCO_COTR_FK on RUOLI_CONTRIBUENTE (TRIBUTO asc)
/

-- ============================================================
--   Index: RUCO_CONT_FK
-- ============================================================
create index RUCO_CONT_FK on RUOLI_CONTRIBUENTE (COD_FISCALE asc)
/

-- ============================================================
--   Index: RUCO_RUOL_FK
-- ============================================================
create index RUCO_RUOL_FK on RUOLI_CONTRIBUENTE (RUOLO asc)
/

-- ============================================================
--   Index: RUCO_OGIM_FK
-- ============================================================
create index RUCO_OGIM_FK on RUOLI_CONTRIBUENTE (OGGETTO_IMPOSTA asc)
/

-- ============================================================
--   Table: FATTURE
-- ============================================================
create table FATTURE
(
    FATTURA                         NUMBER                 not null,
    ANNO                            NUMBER(4)              not null,
    NUMERO                          NUMBER(8)              not null,
    COD_FISCALE                     VARCHAR2(16)           null    ,
    DATA_EMISSIONE                  DATE                   null    ,
    DATA_SCADENZA                   DATE                   null    ,
    FLAG_STAMPA                     VARCHAR2(1)            null
        constraint FATTURE_FLAG_STAMPA_CC check (
            FLAG_STAMPA is null or (FLAG_STAMPA in ('S'))),
    IMPORTO_TOTALE                  NUMBER(15,2)           null    ,
    FATTURA_RIF                     NUMBER                 null    ,
    ANNO_RIF                        NUMBER(4)              null    ,
    NUMERO_RIF                      NUMBER(8)              null    ,
    UTENTE                          VARCHAR2(8)            null    ,
    DATA_VARIAZIONE                 DATE                   null    ,
    NOTE                            VARCHAR2(2000)         null    ,
    FLAG_DELEGA                     VARCHAR2(1)            null
        constraint FATTURE_FLAG_DELEGA_CC check (
            FLAG_DELEGA is null or (FLAG_DELEGA in ('S'))),
    constraint FATTURE_PK primary key (FATTURA)
)
/

comment on table FATTURE is 'FATT - Fatture'
/

-- ============================================================
--   Index: FATT_FATT1_FK
-- ============================================================
create index FATT_FATT1_FK on FATTURE (FATTURA_RIF asc)
/

-- ============================================================
--   Index: FATT_CONT_FK
-- ============================================================
create index FATT_CONT_FK on FATTURE (COD_FISCALE asc)
/

-- ============================================================
--   Table: COMPENSAZIONI
-- ============================================================
create table COMPENSAZIONI
(
    ID_COMPENSAZIONE                NUMBER(10)             not null,
    COD_FISCALE                     VARCHAR2(16)           null    ,
    TIPO_TRIBUTO                    VARCHAR2(5)            null    ,
    ANNO                            NUMBER(4)              null    ,
    MOTIVO_COMPENSAZIONE            NUMBER(2)              null    ,
    COMPENSAZIONE                   NUMBER(15,2)           null    ,
    FLAG_AUTOMATICO                 VARCHAR2(1)            null    ,
    UTENTE                          VARCHAR2(8)            null    ,
    DATA_VARIAZIONE                 DATE                   null    ,
    NOTE                            VARCHAR2(2000)         null    ,
    constraint COMPENSAZIONI_PK primary key (ID_COMPENSAZIONE)
)
/

comment on table COMPENSAZIONI is 'COMP - Compensazioni'
/

-- ============================================================
--   Index: COMP_CONT_FK
-- ============================================================
create index COMP_CONT_FK on COMPENSAZIONI (COD_FISCALE asc)
/

-- ============================================================
--   Index: COMP_MOCO_FK
-- ============================================================
create index COMP_MOCO_FK on COMPENSAZIONI (MOTIVO_COMPENSAZIONE asc)
/

-- ============================================================
--   Index: COMP_TITR_FK
-- ============================================================
create index COMP_TITR_FK on COMPENSAZIONI (TIPO_TRIBUTO asc)
/

-- ============================================================
--   Table: CONFERIMENTI_CER
-- ============================================================
create table CONFERIMENTI_CER
(
    COD_FISCALE                     VARCHAR2(16)           not null,
    ANNO                            NUMBER(4)              not null,
    TIPO_UTENZA                     VARCHAR2(1)            not null
        constraint CONFERIMENTI__TIPO_UTENZA_CC check (
            TIPO_UTENZA in ('D','N')),
    DATA_CONFERIMENTO               DATE                   not null,
    CODICE_CER                      VARCHAR2(6)            not null,
    COD_FISCALE_CONFERENTE          VARCHAR2(16)           not null,
    SCONTRINO                       VARCHAR2(10)           not null,
    QUANTITA                        NUMBER(6,2)            not null,
    DOCUMENTO_ID                    NUMBER(10)             null    ,
    UTENTE                          VARCHAR2(8)            not null,
    DATA_VARIAZIONE                 DATE                   not null,
    NOTE                            VARCHAR2(2000)         null    ,
    constraint CONFERIMENTI_CER_PK primary key (COD_FISCALE, ANNO, TIPO_UTENZA, DATA_CONFERIMENTO, CODICE_CER)
)
/

comment on table CONFERIMENTI_CER is 'COCE - Conferimenti CER'
/

-- ============================================================
--   Index: COCE_CACE_FK
-- ============================================================
create index COCE_CACE_FK on CONFERIMENTI_CER (CODICE_CER asc)
/

-- ============================================================
--   Index: COCE_DOCA_FK
-- ============================================================
create index COCE_DOCA_FK on CONFERIMENTI_CER (DOCUMENTO_ID asc)
/

-- ============================================================
--   Index: COCE_CONT_FK
-- ============================================================
create index COCE_CONT_FK on CONFERIMENTI_CER (COD_FISCALE asc)
/

-- ============================================================
--   Table: RATE_IMPOSTA
-- ============================================================
create table RATE_IMPOSTA
(
    RATA_IMPOSTA                    NUMBER(10)             not null,
    ANNO                            NUMBER(4)              not null,
    RATA                            NUMBER(2)              not null
        constraint RATE_IMPOSTA_RATA_CC check (
            RATA in (0,1,2,3,4,11,12,22)),
    OGGETTO_IMPOSTA                 NUMBER(10)             null    ,
    COD_FISCALE                     VARCHAR2(16)           null    ,
    TIPO_TRIBUTO                    VARCHAR2(5)            null    ,
    IMPOSTA                         NUMBER(15,2)           null
        constraint RATE_IMPOSTA_IMPOSTA_CC check (
            IMPOSTA is null or (IMPOSTA >= 0
            )),
    CONTO_CORRENTE                  NUMBER(8)              null    ,
    UTENTE                          VARCHAR2(8)            not null,
    NOTE                            VARCHAR2(2000)         null    ,
    NUM_BOLLETTINO                  NUMBER(12)             null    ,
    ADDIZIONALE_ECA                 NUMBER(15,2)           null    ,
    MAGGIORAZIONE_ECA               NUMBER(15,2)           null    ,
    ADDIZIONALE_PRO                 NUMBER(15,2)           null    ,
    IVA                             NUMBER(15,2)           null    ,
    IMPOSTA_ROUND                   NUMBER(15,2)           null
        constraint RATE_IMPOSTA_IMPOSTA_ROUND_CC check (
            IMPOSTA_ROUND is null or (IMPOSTA_ROUND >= 0
            )),
    IDBACK                          VARCHAR2(4000)         null    ,
    DATA_SCADENZA                   DATE                   null    ,
    MAGGIORAZIONE_TARES             NUMBER(15,2)           null    ,
    constraint RATE_IMPOSTA_PK primary key (RATA_IMPOSTA)
        using index
)
/

comment on table RATE_IMPOSTA is 'RAIM - Rate Imposta'
/

-- ============================================================
--   Index: RAIM_ANNO_CONT_IK
-- ============================================================
create index RAIM_ANNO_CONT_IK on RATE_IMPOSTA (ANNO asc)
/

-- ============================================================
--   Index: RAIM_BOLL_IK
-- ============================================================
create index RAIM_BOLL_IK on RATE_IMPOSTA (NUM_BOLLETTINO asc)
/

-- ============================================================
--   Index: RAIM_OGIM_FK
-- ============================================================
create index RAIM_OGIM_FK on RATE_IMPOSTA (OGGETTO_IMPOSTA asc)
/

-- ============================================================
--   Index: RAIM_CONT_FK
-- ============================================================
create index RAIM_CONT_FK on RATE_IMPOSTA (COD_FISCALE asc)
/

-- ============================================================
--   Index: RAIM_TITR_FK
-- ============================================================
create index RAIM_TITR_FK on RATE_IMPOSTA (TIPO_TRIBUTO asc)
/

-- ============================================================
--   Table: STO_PRATICHE_TRIBUTO
-- ============================================================
create table STO_PRATICHE_TRIBUTO
(
    PRATICA                         NUMBER(10)             not null,
    COD_FISCALE                     VARCHAR2(16)           not null,
    TIPO_TRIBUTO                    VARCHAR2(5)            not null,
    ANNO                            NUMBER(4)              not null,
    TIPO_PRATICA                    VARCHAR2(1)            not null
        constraint STO_PRATICHE__TIPO_PRATICA_CC check (
            TIPO_PRATICA in ('A','D','L','I','C','K','T','V','G')),
    TIPO_EVENTO                     VARCHAR2(1)            not null
        constraint STO_PRATICHE__TIPO_EVENTO_CC check (
            TIPO_EVENTO in ('I','V','C','U','R','T','A')),
    DATA                            DATE                   null    ,
    NUMERO                          VARCHAR2(15)           null    ,
    TIPO_CARICA                     NUMBER(4)              null    ,
    DENUNCIANTE                     VARCHAR2(60)           null    ,
    INDIRIZZO_DEN                   VARCHAR2(50)           null    ,
    COD_PRO_DEN                     NUMBER(3)              null    ,
    COD_COM_DEN                     NUMBER(3)              null    ,
    COD_FISCALE_DEN                 VARCHAR2(16)           null    ,
    PARTITA_IVA_DEN                 VARCHAR2(11)           null    ,
    DATA_NOTIFICA                   DATE                   null    ,
    IMPOSTA_TOTALE                  NUMBER(15,2)           null    ,
    IMPORTO_TOTALE                  NUMBER(15,2)           null    ,
    IMPORTO_RIDOTTO                 NUMBER(15,2)           null    ,
    STATO_ACCERTAMENTO              VARCHAR2(2)            null    ,
    MOTIVO                          VARCHAR2(2000)         null    ,
    PRATICA_RIF                     NUMBER(10)             null    ,
    UTENTE                          VARCHAR2(8)            not null,
    DATA_VARIAZIONE                 DATE                   not null,
    NOTE                            VARCHAR2(2000)         null    ,
    FLAG_ADESIONE                   VARCHAR2(1)            null
        constraint STO_PRATICHE__FLAG_ADESIONE_CC check (
            FLAG_ADESIONE is null or (FLAG_ADESIONE in ('S'))),
    IMPOSTA_DOVUTA_TOTALE           NUMBER(15,2)           null    ,
    FLAG_DENUNCIA                   VARCHAR2(1)            null
        constraint STO_PRATICHE__FLAG_DENUNCIA_CC check (
            FLAG_DENUNCIA is null or (FLAG_DENUNCIA in ('S'))),
    FLAG_ANNULLAMENTO               VARCHAR2(1)            null
        constraint STO_PRATICHE__FLAG_ANNULLAM_CC check (
            FLAG_ANNULLAMENTO is null or (FLAG_ANNULLAMENTO in ('S'))),
    IMPORTO_RIDOTTO_2               NUMBER(15,2)           null    ,
    TIPO_ATTO                       NUMBER(2)              null    ,
    DOCUMENTO_ID                    NUMBER(10)             null    ,
    DOCUMENTO_MULTI_ID              NUMBER(10)             null    ,
    TIPO_CALCOLO                    VARCHAR2(1)            null    ,
    ENTE                            VARCHAR2(4)            null    ,
    DATA_RATEAZIONE                 DATE                   null    ,
    MORA                            NUMBER(15,2)           null    ,
    RATE                            NUMBER(2)              null    ,
    TIPOLOGIA_RATE                  VARCHAR2(1)            null
        constraint STO_PRATICHE__TIPOLOGIA_RAT_CC check (
            TIPOLOGIA_RATE is null or (TIPOLOGIA_RATE in ('M','B','T','Q','S','A'))),
    IMPORTO_RATE                    NUMBER(15,2)           null    ,
    ALIQUOTA_RATE                   NUMBER(6,4)            null    ,
    VERSATO_PRE_RATE                NUMBER(15,2)           null    ,
    DATA_STO                        DATE                   null    ,
    constraint STO_PRATICHE_TRIBUTO_PK primary key (PRATICA)
)
/

comment on table STO_PRATICHE_TRIBUTO is 'SPRTR - Sto Pratiche Tributo'
/

-- ============================================================
--   Index: SPRTR_ANNO_IK
-- ============================================================
create index SPRTR_ANNO_IK on STO_PRATICHE_TRIBUTO (ANNO asc, TIPO_TRIBUTO asc, TIPO_PRATICA asc)
/

-- ============================================================
--   Index: SPRTR_CONT_FK
-- ============================================================
create index SPRTR_CONT_FK on STO_PRATICHE_TRIBUTO (COD_FISCALE asc)
/

-- ============================================================
--   Index: SPRTR_TICA_FK
-- ============================================================
create index SPRTR_TICA_FK on STO_PRATICHE_TRIBUTO (TIPO_CARICA asc)
/

-- ============================================================
--   Index: SPRTR_SPRTR1_FK
-- ============================================================
create index SPRTR_SPRTR1_FK on STO_PRATICHE_TRIBUTO (PRATICA_RIF asc)
/

-- ============================================================
--   Index: SPRTR_TIST_FK
-- ============================================================
create index SPRTR_TIST_FK on STO_PRATICHE_TRIBUTO (STATO_ACCERTAMENTO asc)
/

-- ============================================================
--   Index: SPRTR_TIAT_FK
-- ============================================================
create index SPRTR_TIAT_FK on STO_PRATICHE_TRIBUTO (TIPO_ATTO asc)
/

-- ============================================================
--   Index: SPRTR_DCMU_FK
-- ============================================================
create index SPRTR_DCMU_FK on STO_PRATICHE_TRIBUTO (DOCUMENTO_ID asc, DOCUMENTO_MULTI_ID asc)
/

-- ============================================================
--   Table: SAM_INTERROGAZIONI
-- ============================================================
create table SAM_INTERROGAZIONI
(
    INTERROGAZIONE                  NUMBER(10)             not null,
    COD_FISCALE                     VARCHAR2(16)           not null,
    COD_FISCALE_INIZIALE            VARCHAR2(16)           not null,
    TIPO                            VARCHAR2(15)           not null,
    IDENTIFICATIVO_ENTE             VARCHAR2(15)           not null,
    ELABORAZIONE_ID                 NUMBER(10)             null    ,
    ATTIVITA_ID                     NUMBER(10)             null    ,
    constraint SAM_INTERROGAZIONI_PK primary key (INTERROGAZIONE)
)
/

comment on table SAM_INTERROGAZIONI is 'SINT - SAM Interrogazioni'
/

create sequence ALLANAGR_SEQ
minvalue 1
maxvalue 999999999999999999999999999
start with 1
increment by 1
nocache
/

-- ============================================================
--   Index: SINT_CONT_FK
-- ============================================================
create index SINT_CONT_FK on SAM_INTERROGAZIONI (COD_FISCALE asc)
/

-- ============================================================
--   Index: SINT_STIP_FK
-- ============================================================
create index SINT_STIP_FK on SAM_INTERROGAZIONI (TIPO asc)
/

-- ============================================================
--   Index: SINT_ELMA_FK
-- ============================================================
create index SINT_ELMA_FK on SAM_INTERROGAZIONI (ELABORAZIONE_ID asc)
/

-- ============================================================
--   Index: SINT_ATEL_FK
-- ============================================================
create index SINT_ATEL_FK on SAM_INTERROGAZIONI (ATTIVITA_ID asc)
/

-- ============================================================
--   Table: CODICI_RFID
-- ============================================================
create table CODICI_RFID
(
    COD_FISCALE                     VARCHAR2(16)           not null,
    OGGETTO                         NUMBER(10)             not null
        constraint CODICI_RFID_OGGETTO_CC check (
            OGGETTO >= 0),
    COD_RFID                        VARCHAR2(100)          not null,
    COD_CONTENITORE                 NUMBER(4)              not null,
    DATA_CONSEGNA                   DATE                   null    ,
    DATA_RESTITUZIONE               DATE                   null    ,
    UTENTE                          VARCHAR2(8)            null    ,
    DATA_VARIAZIONE                 DATE                   null    ,
    NOTE                            VARCHAR2(2000)         null    ,
    constraint CODICI_RFID_PK primary key (COD_FISCALE, OGGETTO, COD_RFID)
)
/

comment on table CODICI_RFID is 'CORF - Codici RFID'
/

-- ============================================================
--   Index: CORF_CONT_FK
-- ============================================================
create index CORF_CONT_FK on CODICI_RFID (COD_FISCALE asc)
/

-- ============================================================
--   Index: CORF_OGGE_FK
-- ============================================================
create index CORF_OGGE_FK on CODICI_RFID (OGGETTO asc)
/

-- ============================================================
--   Index: CORF_CORI_FK
-- ============================================================
create index CORF_CORI_FK on CODICI_RFID (COD_CONTENITORE asc)
/

-- ============================================================
--   Table: OGGETTI_PRATICA
-- ============================================================
create table OGGETTI_PRATICA
(
    OGGETTO_PRATICA                 NUMBER(10)             not null,
    OGGETTO                         NUMBER(10)             not null
        constraint OGGETTI_PRATI_OGGETTO_CC check (
            OGGETTO >= 0),
    PRATICA                         NUMBER(10)             not null,
    TRIBUTO                         NUMBER(4)              null    ,
    CATEGORIA                       NUMBER(4)              null    ,
    ANNO                            NUMBER(4)              null    ,
    TIPO_TARIFFA                    NUMBER(2)              null    ,
    NUM_ORDINE                      VARCHAR2(5)            null    ,
    IMM_STORICO                     VARCHAR2(1)            null
        constraint OGGETTI_PRATI_IMM_STORICO_CC check (
            IMM_STORICO is null or (IMM_STORICO in ('S'))),
    CATEGORIA_CATASTO               VARCHAR2(3)            null    ,
    CLASSE_CATASTO                  VARCHAR2(2)            null    ,
    VALORE                          NUMBER(15,2)           null
        constraint OGGETTI_PRATI_VALORE_CC check (
            VALORE is null or (VALORE >= 0
            )),
    FLAG_PROVVISORIO                VARCHAR2(1)            null
        constraint OGGETTI_PRATI_FLAG_PROVVISO_CC check (
            FLAG_PROVVISORIO is null or (FLAG_PROVVISORIO in ('S'))),
    FLAG_VALORE_RIVALUTATO          VARCHAR2(1)            null
        constraint OGGETTI_PRATI_FLAG_VALORE_R_CC check (
            FLAG_VALORE_RIVALUTATO is null or (FLAG_VALORE_RIVALUTATO in ('S'))),
    TITOLO                          VARCHAR2(1)            null
        constraint OGGETTI_PRATI_TITOLO_CC check (
            TITOLO is null or (TITOLO in ('A','C'))),
    ESTREMI_TITOLO                  VARCHAR2(60)           null    ,
    MODELLO                         NUMBER(3)              null    ,
    FLAG_FIRMA                      VARCHAR2(1)            null
        constraint OGGETTI_PRATI_FLAG_FIRMA_CC check (
            FLAG_FIRMA is null or (FLAG_FIRMA in ('S'))),
    FONTE                           NUMBER(2)              null    ,
    CONSISTENZA_REALE               NUMBER(8,2)            null    ,
    CONSISTENZA                     NUMBER(8,2)            null    ,
    LOCALE                          NUMBER(8,2)            null    ,
    COPERTA                         NUMBER(8,2)            null    ,
    SCOPERTA                        NUMBER(8,2)            null    ,
    SETTORE                         NUMBER(2)              null    ,
    FLAG_UIP_PRINCIPALE             VARCHAR2(1)            null
        constraint OGGETTI_PRATI_FLAG_UIP_PRIN_CC check (
            FLAG_UIP_PRINCIPALE is null or (FLAG_UIP_PRINCIPALE in ('S'))),
    REDDITO                         NUMBER(15,2)           null    ,
    CLASSE_SUP                      NUMBER(6)              null    ,
    IMPOSTA_BASE                    NUMBER(15,2)           null
        constraint OGGETTI_PRATI_IMPOSTA_BASE_CC check (
            IMPOSTA_BASE is null or (IMPOSTA_BASE >= 0
            )),
    IMPOSTA_DOVUTA                  NUMBER(15,2)           null
        constraint OGGETTI_PRATI_IMPOSTA_DOVUT_CC check (
            IMPOSTA_DOVUTA is null or (IMPOSTA_DOVUTA >= 0
            )),
    FLAG_DOMICILIO_FISCALE          VARCHAR2(1)            null
        constraint OGGETTI_PRATI_FLAG_DOMICILI_CC check (
            FLAG_DOMICILIO_FISCALE is null or (FLAG_DOMICILIO_FISCALE in ('S'))),
    NUM_CONCESSIONE                 NUMBER(7)              null    ,
    DATA_CONCESSIONE                DATE                   null    ,
    INIZIO_CONCESSIONE              DATE                   null    ,
    FINE_CONCESSIONE                DATE                   null    ,
    LARGHEZZA                       NUMBER(7,2)            null    ,
    PROFONDITA                      NUMBER(7,2)            null    ,
    COD_PRO_OCC                     NUMBER(3)              null    ,
    COD_COM_OCC                     NUMBER(3)              null    ,
    INDIRIZZO_OCC                   VARCHAR2(50)           null    ,
    DA_CHILOMETRO                   NUMBER(8,4)            null    ,
    A_CHILOMETRO                    NUMBER(8,4)            null    ,
    LATO                            VARCHAR2(1)            null    ,
    TIPO_OCCUPAZIONE                VARCHAR2(1)            null
        constraint OGGETTI_PRATI_TIPO_OCCUPAZI_CC check (
            TIPO_OCCUPAZIONE is null or (TIPO_OCCUPAZIONE in ('P','T'))),
    FLAG_CONTENZIOSO                VARCHAR2(1)            null
        constraint OGGETTI_PRATI_FLAG_CONTENZI_CC check (
            FLAG_CONTENZIOSO is null or (FLAG_CONTENZIOSO in ('S'))),
    OGGETTO_PRATICA_RIF             NUMBER(10)             null    ,
    UTENTE                          VARCHAR2(8)            not null,
    DATA_VARIAZIONE                 DATE                   not null,
    NOTE                            VARCHAR2(2000)         null    ,
    OGGETTO_PRATICA_RIF_V           NUMBER(10)             null    ,
    TIPO_QUALITA                    NUMBER(4)              null    ,
    QUALITA                         VARCHAR2(60)           null    ,
    TIPO_OGGETTO                    NUMBER(2)              null    ,
    OGGETTO_PRATICA_RIF_AP          NUMBER(10)             null    ,
    QUANTITA                        NUMBER(6)              null    ,
    TITOLO_OCCUPAZIONE              NUMBER(2)              null
        constraint OGGETTI_PRATI_TITOLO_OCCUPA_CC check (
            TITOLO_OCCUPAZIONE is null or (TITOLO_OCCUPAZIONE in (1,2,3,4))),
    NATURA_OCCUPAZIONE              NUMBER(2)              null
        constraint OGGETTI_PRATI_NATURA_OCCUPA_CC check (
            NATURA_OCCUPAZIONE is null or (NATURA_OCCUPAZIONE in (1,2,3,4))),
    DESTINAZIONE_USO                NUMBER(2)              null
        constraint OGGETTI_PRATI_DESTINAZIONE__CC check (
            DESTINAZIONE_USO is null or (DESTINAZIONE_USO in (1,2,3,4,5))),
    ASSENZA_ESTREMI_CATASTO         NUMBER(2)              null
        constraint OGGETTI_PRATI_ASSENZA_ESTRE_CC check (
            ASSENZA_ESTREMI_CATASTO is null or (ASSENZA_ESTREMI_CATASTO in (1,2,3))),
    DATA_ANAGRAFE_TRIBUTARIA        DATE                   null    ,
    NUMERO_FAMILIARI                NUMBER(4)              null    ,
    FLAG_DATI_METRICI               VARCHAR2(1)            null
        constraint OGGETTI_PRATI_FLAG_DATI_MET_CC check (
            FLAG_DATI_METRICI is null or (FLAG_DATI_METRICI in ('S'))),
    PERC_RIDUZIONE_SUP              NUMBER(5,2)            null    ,
    FLAG_NULLA_OSTA                 VARCHAR2(1)            null
        constraint OGGETTI_PRATI_FLAG_NULLA_OS_CC check (
            FLAG_NULLA_OSTA is null or (FLAG_NULLA_OSTA in ('S'))),
    constraint OGGETTI_PRATICA_PK primary key (OGGETTO_PRATICA)
        using index
)
/

comment on table OGGETTI_PRATICA is 'OGPR - Valori generali degli oggetti di una pratica'
/

create sequence NR_OGPR_SEQ
MINVALUE 0
START WITH 1
INCREMENT BY 1
NOCACHE
/

-- ============================================================
--   Index: OGPR_OGGE_FK
-- ============================================================
create index OGPR_OGGE_FK on OGGETTI_PRATICA (OGGETTO asc)
/

-- ============================================================
--   Index: OGPR_FONT_FK
-- ============================================================
create index OGPR_FONT_FK on OGGETTI_PRATICA (FONTE asc)
/

-- ============================================================
--   Index: OGPR_CACA_FK
-- ============================================================
create index OGPR_CACA_FK on OGGETTI_PRATICA (CATEGORIA_CATASTO asc)
/

-- ============================================================
--   Index: OGPR_PRTR_FK
-- ============================================================
create index OGPR_PRTR_FK on OGGETTI_PRATICA (PRATICA asc)
/

-- ============================================================
--   Index: OGPR_COTR_FK
-- ============================================================
create index OGPR_COTR_FK on OGGETTI_PRATICA (TRIBUTO asc)
/

-- ============================================================
--   Index: OGPR_OGPR1_FK
-- ============================================================
create index OGPR_OGPR1_FK on OGGETTI_PRATICA (OGGETTO_PRATICA_RIF asc)
/

-- ============================================================
--   Index: OGPR_TARI_FK
-- ============================================================
create index OGPR_TARI_FK on OGGETTI_PRATICA (TRIBUTO asc, CATEGORIA asc, ANNO asc, TIPO_TARIFFA asc)
/

-- ============================================================
--   Index: OGPR_CLSU_FK
-- ============================================================
create index OGPR_CLSU_FK on OGGETTI_PRATICA (ANNO asc, SETTORE asc, CLASSE_SUP asc)
/

-- ============================================================
--   Index: OGPR_SEAT_FK
-- ============================================================
create index OGPR_SEAT_FK on OGGETTI_PRATICA (SETTORE asc)
/

-- ============================================================
--   Index: OGPR_OGPR2_FK
-- ============================================================
create index OGPR_OGPR2_FK on OGGETTI_PRATICA (OGGETTO_PRATICA_RIF_V asc)
/

-- ============================================================
--   Index: OGPR_TIOG_FK
-- ============================================================
create index OGPR_TIOG_FK on OGGETTI_PRATICA (TIPO_OGGETTO asc)
/

-- ============================================================
--   Index: OGPR_OGPR3_FK
-- ============================================================
create index OGPR_OGPR3_FK on OGGETTI_PRATICA (OGGETTO_PRATICA_RIF_AP asc)
/

-- ============================================================
--   Table: SUCCESSIONI_DEFUNTI
-- ============================================================
create table SUCCESSIONI_DEFUNTI
(
    SUCCESSIONE                     NUMBER(10)             not null,
    UFFICIO                         VARCHAR2(3)            not null,
    ANNO                            NUMBER(4)              not null,
    VOLUME                          NUMBER(5)              not null,
    NUMERO                          NUMBER(6)              not null,
    SOTTONUMERO                     NUMBER(3)              not null,
    COMUNE                          VARCHAR2(4)            not null,
    TIPO_DICHIARAZIONE              VARCHAR2(1)            not null,
    DATA_APERTURA                   DATE                   null    ,
    COD_FISCALE                     VARCHAR2(16)           null    ,
    COGNOME                         VARCHAR2(25)           null    ,
    NOME                            VARCHAR2(25)           null    ,
    SESSO                           VARCHAR2(1)            null    ,
    CITTA_NAS                       VARCHAR2(30)           null    ,
    PROV_NAS                        VARCHAR2(2)            null    ,
    DATA_NAS                        DATE                   null    ,
    CITTA_RES                       VARCHAR2(30)           null    ,
    PROV_RES                        VARCHAR2(2)            null    ,
    INDIRIZZO                       VARCHAR2(30)           null    ,
    STATO_SUCCESSIONE               VARCHAR2(30)           null    ,
    UTENTE                          VARCHAR2(8)            not null,
    DATA_VARIAZIONE                 DATE                   not null,
    NOTE                            VARCHAR2(2000)         null    ,
    PRATICA                         NUMBER(10)             null    ,
    constraint SUCCESSIONI_DEFUNTI_PK primary key (SUCCESSIONE)
)
/

comment on table SUCCESSIONI_DEFUNTI is 'SUDE - Successioni Defunti'
/

-- ============================================================
--   Index: SUDE_CHIAVE_UK
-- ============================================================
create unique index SUDE_CHIAVE_UK on SUCCESSIONI_DEFUNTI (UFFICIO asc, ANNO asc, VOLUME asc, NUMERO asc, SOTTONUMERO asc, COMUNE asc)
/

-- ============================================================
--   Index: SUDE_PRTR_FK
-- ============================================================
create index SUDE_PRTR_FK on SUCCESSIONI_DEFUNTI (PRATICA asc)
/

-- ============================================================
--   Table: SUCCESSIONI_EREDI
-- ============================================================
create table SUCCESSIONI_EREDI
(
    SUCCESSIONE                     NUMBER(10)             not null,
    PROGRESSIVO                     NUMBER(5)              not null,
    PROGR_EREDE                     NUMBER(3)              not null,
    CATEGORIA                       VARCHAR2(1)            null    ,
    COD_FISCALE                     VARCHAR2(16)           null    ,
    COGNOME                         VARCHAR2(25)           null    ,
    NOME                            VARCHAR2(25)           null    ,
    DENOMINAZIONE                   VARCHAR2(50)           null    ,
    SESSO                           VARCHAR2(1)            null    ,
    CITTA_NAS                       VARCHAR2(30)           null    ,
    PROV_NAS                        VARCHAR2(2)            null    ,
    DATA_NAS                        DATE                   null    ,
    CITTA_RES                       VARCHAR2(30)           null    ,
    PROV_RES                        VARCHAR2(2)            null    ,
    INDIRIZZO                       VARCHAR2(30)           null    ,
    PRATICA                         NUMBER(10)             null    ,
    constraint SUCCESSIONI_EREDI_PK primary key (SUCCESSIONE, PROGRESSIVO)
)
/

comment on table SUCCESSIONI_EREDI is 'SUER - Successioni Eredi'
/

-- ============================================================
--   Index: SUER_SUDE_FK
-- ============================================================
create index SUER_SUDE_FK on SUCCESSIONI_EREDI (SUCCESSIONE asc)
/

-- ============================================================
--   Index: SUER_PRTR_FK
-- ============================================================
create index SUER_PRTR_FK on SUCCESSIONI_EREDI (PRATICA asc)
/

-- ============================================================
--   Table: WEB_CALCOLO_INDIVIDUALE
-- ============================================================
create table WEB_CALCOLO_INDIVIDUALE
(
    ID_CALCOLO_INDIVIDUALE          NUMBER                 not null,
    COD_FISCALE                     VARCHAR2(16)           not null,
    LAST_UPDATED                    DATE                   not null,
    DATE_CREATED                    DATE                   not null,
    UTENTE                          VARCHAR2(8)            not null,
    ENTE                            VARCHAR2(4)            null    ,
    ANNO                            NUMBER(4)              not null,
    TIPO_TRIBUTO                    VARCHAR2(5)            not null,
    PRATICA                         NUMBER(10)             not null,
    TIPO_CALCOLO                    VARCHAR2(50)           not null,
    TOTALE_TERRENI_RIDOTTI          NUMBER                 null    ,
    NUMERO_FABBRICATI               NUMBER                 null    ,
    SALDO_DETRAZIONE_STD            NUMBER                 null    ,
    VERSION                         NUMBER(10)             null    ,
    constraint WEB_CALCOLO_INDIVIDUALE_PK primary key (ID_CALCOLO_INDIVIDUALE)
)
/

comment on table WEB_CALCOLO_INDIVIDUALE is 'WCIN - Deposito valori calcolati da CALCOLO_INDIVIDUALE'
/

CREATE SEQUENCE WCIN_SQ
  START WITH 1
  MAXVALUE 999999999999999999999999999
  MINVALUE 1
  NOCYCLE
  NOCACHE
  NOORDER
/

-- ============================================================
--   Index: WCIN_UK
-- ============================================================
create unique index WCIN_UK on WEB_CALCOLO_INDIVIDUALE (PRATICA asc)
/

-- ============================================================
--   Table: SGRAVI
-- ============================================================
create table SGRAVI
(
    RUOLO                           NUMBER(10)             not null,
    COD_FISCALE                     VARCHAR2(16)           not null,
    SEQUENZA                        NUMBER(4)              not null,
    SEQUENZA_SGRAVIO                NUMBER(4)              not null,
    MOTIVO_SGRAVIO                  NUMBER(2)              null    ,
    NUMERO_ELENCO                   NUMBER(4)              null    ,
    DATA_ELENCO                     DATE                   null    ,
    IMPORTO                         NUMBER(15,2)           null
        constraint SGRAVI_IMPORTO_CC check (
            IMPORTO is null or (IMPORTO >= 0
            )),
    SEMESTRI                        NUMBER(2)              null    ,
    ADDIZIONALE_ECA                 NUMBER(15,2)           null    ,
    MAGGIORAZIONE_ECA               NUMBER(15,2)           null    ,
    ADDIZIONALE_PRO                 NUMBER(15,2)           null    ,
    IVA                             NUMBER(15,2)           null    ,
    COD_CONCESSIONE                 NUMBER(3)              null    ,
    NUM_RUOLO                       NUMBER(6)              null    ,
    FATTURA                         NUMBER                 null    ,
    MESI_SGRAVIO                    NUMBER(2)              null    ,
    FLAG_AUTOMATICO                 VARCHAR2(1)            null
        constraint SGRAVI_FLAG_AUTOMATI_CC check (
            FLAG_AUTOMATICO is null or (FLAG_AUTOMATICO in ('S'))),
    DA_MESE                         NUMBER(2)              null    ,
    A_MESE                          NUMBER(2)              null    ,
    TIPO_SGRAVIO                    VARCHAR2(1)            null
        constraint SGRAVI_TIPO_SGRAVIO_CC check (
            TIPO_SGRAVIO is null or (TIPO_SGRAVIO in ('S','D','R'))),
    GIORNI_SGRAVIO                  NUMBER(4)              null    ,
    MAGGIORAZIONE_TARES             NUMBER(15,2)           null    ,
    UTENTE                          VARCHAR2(8)            null    ,
    DATA_VARIAZIONE                 DATE                   null    ,
    NOTE                            VARCHAR2(2000)         null    ,
    DETTAGLIO_SGRA                  VARCHAR2(2000)         null    ,
    OGPR_SGRAVIO                    NUMBER(10)             null    ,
    IMPOSTA_DOVUTA                  NUMBER(15,2)           null    ,
    RUOLO_INSERIMENTO               NUMBER(10)             null    ,
    IMPORTO_BASE                    NUMBER(15,2)           null    ,
    ADDIZIONALE_ECA_BASE            NUMBER(15,2)           null    ,
    MAGGIORAZIONE_ECA_BASE          NUMBER(15,2)           null    ,
    ADDIZIONALE_PRO_BASE            NUMBER(15,2)           null    ,
    IVA_BASE                        NUMBER(15,2)           null    ,
    DETTAGLIO_SGRA_BASE             VARCHAR2(2000)         null    ,
    PROGR_SGRAVIO                   NUMBER(4)              null    ,
    constraint SGRAVI_PK primary key (RUOLO, COD_FISCALE, SEQUENZA, SEQUENZA_SGRAVIO)
        using index
)
/

comment on table SGRAVI is 'SGRA - Sgravi'
/

-- ============================================================
--   Index: SGRA_NUMERO_IK
-- ============================================================
create index SGRA_NUMERO_IK on SGRAVI (NUMERO_ELENCO asc, DATA_ELENCO asc)
/

-- ============================================================
--   Index: SGRA_RUOL_FK
-- ============================================================
create index SGRA_RUOL_FK on SGRAVI (RUOLO asc, COD_FISCALE asc, SEQUENZA asc)
/

-- ============================================================
--   Index: SGRA_MOSG_FK
-- ============================================================
create index SGRA_MOSG_FK on SGRAVI (MOTIVO_SGRAVIO asc)
/

-- ============================================================
--   Index: SGRA_FATT_FK
-- ============================================================
create index SGRA_FATT_FK on SGRAVI (FATTURA asc)
/

-- ============================================================
--   Table: STO_OGGETTI_PRATICA
-- ============================================================
create table STO_OGGETTI_PRATICA
(
    OGGETTO_PRATICA                 NUMBER(10)             not null,
    OGGETTO                         NUMBER(10)             not null
        constraint STO_OGGETTI_P_OGGETTO_CC check (
            OGGETTO >= 0),
    PRATICA                         NUMBER(10)             not null,
    TRIBUTO                         NUMBER(4)              null    ,
    CATEGORIA                       NUMBER(4)              null    ,
    ANNO                            NUMBER(4)              null    ,
    TIPO_TARIFFA                    NUMBER(2)              null    ,
    NUM_ORDINE                      VARCHAR2(5)            null    ,
    IMM_STORICO                     VARCHAR2(1)            null
        constraint STO_OGGETTI_P_IMM_STORICO_CC check (
            IMM_STORICO is null or (IMM_STORICO in ('S'))),
    CATEGORIA_CATASTO               VARCHAR2(3)            null    ,
    CLASSE_CATASTO                  VARCHAR2(2)            null    ,
    VALORE                          NUMBER(15,2)           null
        constraint STO_OGGETTI_P_VALORE_CC check (
            VALORE is null or (VALORE >= 0
            )),
    FLAG_PROVVISORIO                VARCHAR2(1)            null
        constraint STO_OGGETTI_P_FLAG_PROVVISO_CC check (
            FLAG_PROVVISORIO is null or (FLAG_PROVVISORIO in ('S'))),
    FLAG_VALORE_RIVALUTATO          VARCHAR2(1)            null
        constraint STO_OGGETTI_P_FLAG_VALORE_R_CC check (
            FLAG_VALORE_RIVALUTATO is null or (FLAG_VALORE_RIVALUTATO in ('S'))),
    TITOLO                          VARCHAR2(1)            null
        constraint STO_OGGETTI_P_TITOLO_CC check (
            TITOLO is null or (TITOLO in ('A','C'))),
    ESTREMI_TITOLO                  VARCHAR2(60)           null    ,
    MODELLO                         NUMBER(3)              null    ,
    FLAG_FIRMA                      VARCHAR2(1)            null
        constraint STO_OGGETTI_P_FLAG_FIRMA_CC check (
            FLAG_FIRMA is null or (FLAG_FIRMA in ('S'))),
    FONTE                           NUMBER(2)              null    ,
    CONSISTENZA_REALE               NUMBER(8,2)            null    ,
    CONSISTENZA                     NUMBER(8,2)            null    ,
    LOCALE                          NUMBER(8,2)            null    ,
    COPERTA                         NUMBER(8,2)            null    ,
    SCOPERTA                        NUMBER(8,2)            null    ,
    SETTORE                         NUMBER(2)              null    ,
    FLAG_UIP_PRINCIPALE             VARCHAR2(1)            null
        constraint STO_OGGETTI_P_FLAG_UIP_PRIN_CC check (
            FLAG_UIP_PRINCIPALE is null or (FLAG_UIP_PRINCIPALE in ('S'))),
    REDDITO                         NUMBER(15,2)           null    ,
    CLASSE_SUP                      NUMBER(6)              null    ,
    IMPOSTA_BASE                    NUMBER(15,2)           null
        constraint STO_OGGETTI_P_IMPOSTA_BASE_CC check (
            IMPOSTA_BASE is null or (IMPOSTA_BASE >= 0
            )),
    IMPOSTA_DOVUTA                  NUMBER(15,2)           null
        constraint STO_OGGETTI_P_IMPOSTA_DOVUT_CC check (
            IMPOSTA_DOVUTA is null or (IMPOSTA_DOVUTA >= 0
            )),
    FLAG_DOMICILIO_FISCALE          VARCHAR2(1)            null
        constraint STO_OGGETTI_P_FLAG_DOMICILI_CC check (
            FLAG_DOMICILIO_FISCALE is null or (FLAG_DOMICILIO_FISCALE in ('S'))),
    NUM_CONCESSIONE                 NUMBER(7)              null    ,
    DATA_CONCESSIONE                DATE                   null    ,
    INIZIO_CONCESSIONE              DATE                   null    ,
    FINE_CONCESSIONE                DATE                   null    ,
    LARGHEZZA                       NUMBER(7,2)            null    ,
    PROFONDITA                      NUMBER(7,2)            null    ,
    COD_PRO_OCC                     NUMBER(3)              null    ,
    COD_COM_OCC                     NUMBER(3)              null    ,
    INDIRIZZO_OCC                   VARCHAR2(50)           null    ,
    DA_CHILOMETRO                   NUMBER(8,4)            null    ,
    A_CHILOMETRO                    NUMBER(8,4)            null    ,
    LATO                            VARCHAR2(1)            null    ,
    TIPO_OCCUPAZIONE                VARCHAR2(1)            null
        constraint STO_OGGETTI_P_TIPO_OCCUPAZI_CC check (
            TIPO_OCCUPAZIONE is null or (TIPO_OCCUPAZIONE in ('P','T'))),
    FLAG_CONTENZIOSO                VARCHAR2(1)            null
        constraint STO_OGGETTI_P_FLAG_CONTENZI_CC check (
            FLAG_CONTENZIOSO is null or (FLAG_CONTENZIOSO in ('S'))),
    OGGETTO_PRATICA_RIF             NUMBER(10)             null    ,
    UTENTE                          VARCHAR2(8)            not null,
    DATA_VARIAZIONE                 DATE                   not null,
    NOTE                            VARCHAR2(2000)         null    ,
    OGGETTO_PRATICA_RIF_V           NUMBER(10)             null    ,
    TIPO_QUALITA                    NUMBER(4)              null    ,
    QUALITA                         VARCHAR2(60)           null    ,
    TIPO_OGGETTO                    NUMBER(2)              null    ,
    OGGETTO_PRATICA_RIF_AP          NUMBER(10)             null    ,
    QUANTITA                        NUMBER(6)              null    ,
    TITOLO_OCCUPAZIONE              NUMBER(2)              null
        constraint STO_OGGETTI_P_TITOLO_OCCUPA_CC check (
            TITOLO_OCCUPAZIONE is null or (TITOLO_OCCUPAZIONE in (1,2,3,4))),
    NATURA_OCCUPAZIONE              NUMBER(2)              null
        constraint STO_OGGETTI_P_NATURA_OCCUPA_CC check (
            NATURA_OCCUPAZIONE is null or (NATURA_OCCUPAZIONE in (1,2,3,4))),
    DESTINAZIONE_USO                NUMBER(2)              null
        constraint STO_OGGETTI_P_DESTINAZIONE__CC check (
            DESTINAZIONE_USO is null or (DESTINAZIONE_USO in (1,2,3,4,5))),
    ASSENZA_ESTREMI_CATASTO         NUMBER(2)              null
        constraint STO_OGGETTI_P_ASSENZA_ESTRE_CC check (
            ASSENZA_ESTREMI_CATASTO is null or (ASSENZA_ESTREMI_CATASTO in (1,2,3))),
    DATA_ANAGRAFE_TRIBUTARIA        DATE                   null    ,
    NUMERO_FAMILIARI                NUMBER(4)              null    ,
    constraint STO_OGGETTI_PRATICA_PK primary key (OGGETTO_PRATICA)
)
/

comment on table STO_OGGETTI_PRATICA is 'SOGPR - Valori generali degli oggetti di una pratica sto'
/

-- ============================================================
--   Index: SOGPR_SOGGE_FK
-- ============================================================
create index SOGPR_SOGGE_FK on STO_OGGETTI_PRATICA (OGGETTO asc)
/

-- ============================================================
--   Index: SOGPR_FONT_FK
-- ============================================================
create index SOGPR_FONT_FK on STO_OGGETTI_PRATICA (FONTE asc)
/

-- ============================================================
--   Index: SOGPR_CACA_FK
-- ============================================================
create index SOGPR_CACA_FK on STO_OGGETTI_PRATICA (CATEGORIA_CATASTO asc)
/

-- ============================================================
--   Index: SOGPR_SPRTR_FK
-- ============================================================
create index SOGPR_SPRTR_FK on STO_OGGETTI_PRATICA (PRATICA asc)
/

-- ============================================================
--   Index: SOGPR_COTR_FK
-- ============================================================
create index SOGPR_COTR_FK on STO_OGGETTI_PRATICA (TRIBUTO asc)
/

-- ============================================================
--   Index: SOGPR_SOGPR1_FK
-- ============================================================
create index SOGPR_SOGPR1_FK on STO_OGGETTI_PRATICA (OGGETTO_PRATICA_RIF asc)
/

-- ============================================================
--   Index: SOGPR_TARI_FK
-- ============================================================
create index SOGPR_TARI_FK on STO_OGGETTI_PRATICA (TRIBUTO asc, CATEGORIA asc, ANNO asc, TIPO_TARIFFA asc)
/

-- ============================================================
--   Index: SOGPR_CLSU_FK
-- ============================================================
create index SOGPR_CLSU_FK on STO_OGGETTI_PRATICA (ANNO asc, SETTORE asc, CLASSE_SUP asc)
/

-- ============================================================
--   Index: SOGPR_SEAT_FK
-- ============================================================
create index SOGPR_SEAT_FK on STO_OGGETTI_PRATICA (SETTORE asc)
/

-- ============================================================
--   Index: SOGPR_SOGPR2_FK
-- ============================================================
create index SOGPR_SOGPR2_FK on STO_OGGETTI_PRATICA (OGGETTO_PRATICA_RIF_V asc)
/

-- ============================================================
--   Index: SOGPR_TIOG_FK
-- ============================================================
create index SOGPR_TIOG_FK on STO_OGGETTI_PRATICA (TIPO_OGGETTO asc)
/

-- ============================================================
--   Index: SOGPR_SOGPR3_FK
-- ============================================================
create index SOGPR_SOGPR3_FK on STO_OGGETTI_PRATICA (OGGETTO_PRATICA_RIF_AP asc)
/

-- ============================================================
--   Table: OGGETTI
-- ============================================================
create table OGGETTI
(
    OGGETTO                         NUMBER(10)             not null
        constraint OGGETTI_OGGETTO_CC check (
            OGGETTO >= 0),
    DESCRIZIONE                     VARCHAR2(60)           null    ,
    EDIFICIO                        NUMBER(10)             null    ,
    TIPO_OGGETTO                    NUMBER(2)              not null,
    INDIRIZZO_LOCALITA              VARCHAR2(36)           null    ,
    COD_VIA                         NUMBER(6)              null    ,
    NUM_CIV                         NUMBER(6)              null    ,
    SUFFISSO                        VARCHAR2(10)           null    ,
    SCALA                           VARCHAR2(5)            null    ,
    PIANO                           VARCHAR2(5)            null    ,
    INTERNO                         NUMBER(4)              null    ,
    SEZIONE                         VARCHAR2(3)            null    ,
    FOGLIO                          VARCHAR2(5)            null    ,
    NUMERO                          VARCHAR2(5)            null    ,
    SUBALTERNO                      VARCHAR2(4)            null    ,
    ZONA                            VARCHAR2(3)            null    ,
    ESTREMI_CATASTO                 VARCHAR2(20)           null    ,
    PARTITA                         VARCHAR2(8)            null    ,
    PROGR_PARTITA                   NUMBER(9)              null    ,
    PROTOCOLLO_CATASTO              VARCHAR2(6)            null    ,
    ANNO_CATASTO                    NUMBER(4)              null    ,
    CATEGORIA_CATASTO               VARCHAR2(3)            null    ,
    CLASSE_CATASTO                  VARCHAR2(2)            null    ,
    TIPO_USO                        NUMBER(2)              null    ,
    CONSISTENZA                     NUMBER(8,2)            null    ,
    VANI                            NUMBER(8,2)            null    ,
    QUALITA                         VARCHAR2(60)           null    ,
    ETTARI                          NUMBER(5)              null    ,
    ARE                             NUMBER(2)              null    ,
    CENTIARE                        NUMBER(2)              null    ,
    FLAG_SOSTITUITO                 VARCHAR2(1)            null
        constraint OGGETTI_FLAG_SOSTITUI_CC check (
            FLAG_SOSTITUITO is null or (FLAG_SOSTITUITO in ('S'))),
    FLAG_COSTRUITO_ENTE             VARCHAR2(1)            null
        constraint OGGETTI_FLAG_COSTRUIT_CC check (
            FLAG_COSTRUITO_ENTE is null or (FLAG_COSTRUITO_ENTE in ('S'))),
    FONTE                           NUMBER(2)              not null,
    UTENTE                          VARCHAR2(8)            not null,
    DATA_VARIAZIONE                 DATE                   not null,
    NOTE                            VARCHAR2(2000)         null    ,
    COD_ECOGRAFICO                  VARCHAR2(15)           null    ,
    TIPO_QUALITA                    NUMBER(4)              null    ,
    DATA_CESSAZIONE                 DATE                   null    ,
    SUPERFICIE                      NUMBER(8,2)            null    ,
    ID_IMMOBILE                     NUMBER(15)             null    ,
    ENTE                            VARCHAR2(4)            null    ,
    LATITUDINE                      NUMBER(12,8)           null    ,
    LONGITUDINE                     NUMBER(12,8)           null    ,
    constraint OGGETTI_PK primary key (OGGETTO)
        using index
)
/

comment on table OGGETTI is 'OGGE - Oggetti'
/

create sequence NR_OGGE_SEQ
MINVALUE 0
START WITH 1
INCREMENT BY 1
NOCACHE
/

-- ============================================================
--   Index: OGGE_CATASTO_IK
-- ============================================================
create index OGGE_CATASTO_IK on OGGETTI (ANNO_CATASTO asc, PROTOCOLLO_CATASTO asc)
/

-- ============================================================
--   Index: OGGE_ESTREMI1_IK
-- ============================================================
create index OGGE_ESTREMI1_IK on OGGETTI (ESTREMI_CATASTO asc)
/

-- ============================================================
--   Index: OGGE_ESTREMI_IK
-- ============================================================
create index OGGE_ESTREMI_IK on OGGETTI (FOGLIO asc, NUMERO asc, SUBALTERNO asc, SEZIONE asc)
/

-- ============================================================
--   Index: OGGE_IDIM_IK
-- ============================================================
create index OGGE_IDIM_IK on OGGETTI (ID_IMMOBILE asc)
/

-- ============================================================
--   Index: OGGE_EDIF_FK
-- ============================================================
create index OGGE_EDIF_FK on OGGETTI (EDIFICIO asc)
/

-- ============================================================
--   Index: OGGE_FONT_FK
-- ============================================================
create index OGGE_FONT_FK on OGGETTI (FONTE asc)
/

-- ============================================================
--   Index: OGGE_TIOG_FK
-- ============================================================
create index OGGE_TIOG_FK on OGGETTI (TIPO_OGGETTO asc)
/

-- ============================================================
--   Index: OGGE_TIUS_FK
-- ============================================================
create index OGGE_TIUS_FK on OGGETTI (TIPO_USO asc)
/

-- ============================================================
--   Index: OGGE_ARVI_FK
-- ============================================================
create index OGGE_ARVI_FK on OGGETTI (COD_VIA asc)
/

-- ============================================================
--   Index: OGGE_CACA_FK
-- ============================================================
create index OGGE_CACA_FK on OGGETTI (CATEGORIA_CATASTO asc)
/

-- ============================================================
--   Table: PARTIZIONI_OGGETTO
-- ============================================================
create table PARTIZIONI_OGGETTO
(
    OGGETTO                         NUMBER(10)             not null
        constraint PARTIZIONI_OG_OGGETTO_CC check (
            OGGETTO >= 0),
    SEQUENZA                        NUMBER(4)              not null,
    TIPO_AREA                       NUMBER(2)              not null,
    NUMERO                          NUMBER(2)              null    ,
    CONSISTENZA                     NUMBER(8,2)            not null,
    NOTE                            VARCHAR2(2000)         null    ,
    constraint PARTIZIONI_OGGETTO_PK primary key (OGGETTO, SEQUENZA)
)
/

comment on table PARTIZIONI_OGGETTO is 'PAOG - PArtizioni Oggetto'
/

-- ============================================================
--   Index: PAOG_OGGE_FK
-- ============================================================
create index PAOG_OGGE_FK on PARTIZIONI_OGGETTO (OGGETTO asc)
/

-- ============================================================
--   Index: PAOG_TIAR_FK
-- ============================================================
create index PAOG_TIAR_FK on PARTIZIONI_OGGETTO (TIPO_AREA asc)
/

-- ============================================================
--   Table: ANOMALIE
-- ============================================================
create table ANOMALIE
(
    ID_ANOMALIA                     NUMBER(19)             not null,
    ID_ANOMALIA_PARAMETRO           NUMBER(19)             null    ,
    ID_OGGETTO                      NUMBER(19)             null    ,
    FLAG_OK                         VARCHAR2(1)            null    ,
    UTENTE                          VARCHAR2(8)            null    ,
    DATA_CREAZIONE                  DATE                   null    ,
    DATA_VARIAZIONE                 DATE                   null    ,
    ENTE                            VARCHAR2(4)            null    ,
    RENDITA_MEDIA                   NUMBER(15,2)           null    ,
    RENDITA_MASSIMA                 NUMBER(15,2)           null    ,
    VERSION                         NUMBER(10)             not null,
    VALORE_MEDIO                    NUMBER(15,2)           null    ,
    VALORE_MASSIMO                  NUMBER(15,2)           null    ,
    constraint ANOMALIE_PK primary key (ID_ANOMALIA)
)
/

comment on table ANOMALIE is 'ANOMALIE'
/

-- ============================================================
--   Index: ANOM_ANPA_FK
-- ============================================================
create index ANOM_ANPA_FK on ANOMALIE (ID_ANOMALIA_PARAMETRO asc)
/

-- ============================================================
--   Index: ANOM_OGGE_FK
-- ============================================================
create index ANOM_OGGE_FK on ANOMALIE (ID_OGGETTO asc)
/

-- ============================================================
--   Table: ANCI_VER
-- ============================================================
create table ANCI_VER
(
    CONCESSIONE                     NUMBER(3)              null    ,
    ENTE                            VARCHAR2(4)            null    ,
    PROGR_QUIETANZA                 NUMBER(10)             null    ,
    PROGR_RECORD                    NUMBER(8)              not null,
    TIPO_RECORD                     VARCHAR2(1)            not null,
    DATA_VERSAMENTO                 DATE                   null    ,
    COD_FISCALE                     VARCHAR2(16)           null    ,
    ANNO_FISCALE                    NUMBER(4)              not null,
    QUIETANZA                       VARCHAR2(11)           null    ,
    IMPORTO_VERSATO                 NUMBER(11)             null
        constraint ANCI_VER_IMPORTO_VERSA_CC check (
            IMPORTO_VERSATO is null or (IMPORTO_VERSATO >= 0
            )),
    TERRENI_AGRICOLI                NUMBER(10)             null    ,
    AREE_FABBRICABILI               NUMBER(10)             null    ,
    AB_PRINCIPALE                   NUMBER(10)             null    ,
    ALTRI_FABBRICATI                NUMBER(10)             null    ,
    DETRAZIONE                      NUMBER(8)              null    ,
    FLAG_QUADRATURA                 VARCHAR2(1)            null    ,
    FLAG_SQUADRATURA                VARCHAR2(1)            null    ,
    DETRAZIONE_EFFETTIVA            NUMBER(8)              null
        constraint ANCI_VER_DETRAZIONE_EF_CC check (
            DETRAZIONE_EFFETTIVA is null or (DETRAZIONE_EFFETTIVA >= 0
            )),
    IMPOSTA_CALCOLATA               NUMBER(10)             null
        constraint ANCI_VER_IMPOSTA_CALCO_CC check (
            IMPOSTA_CALCOLATA is null or (IMPOSTA_CALCOLATA >= 0
            )),
    TIPO_VERSAMENTO                 NUMBER(1)              null    ,
    DATA_REG                        NUMBER(8)              null    ,
    FLAG_COMPETENZA_VER             VARCHAR2(1)            null    ,
    COMUNE                          VARCHAR2(25)           null    ,
    COD_CATASTO                     VARCHAR2(4)            null    ,
    CAP                             NUMBER(5)              null    ,
    FABBRICATI                      NUMBER(4)              null    ,
    ACCONTO_SALDO                   VARCHAR2(1)            null    ,
    FLAG_EX_RURALI                  VARCHAR2(1)            null    ,
    FLAG_ZERO                       VARCHAR2(35)           null    ,
    FLAG_IDENTIFICAZIONE            NUMBER(1)              null    ,
    TIPO_ANOMALIA                   NUMBER(2)              null    ,
    IMPOSTA                         NUMBER(10)             null    ,
    SANZIONI_1                      NUMBER(10)             null    ,
    SANZIONI_2                      NUMBER(10)             null    ,
    INTERESSI                       NUMBER(10)             null    ,
    NUM_PROVVEDIMENTO               NUMBER(9)              null    ,
    DATA_PROVVEDIMENTO              DATE                   null    ,
    ANNO_IMPOSTA                    NUMBER(4)              null    ,
    FLAG_RAVVEDIMENTO               NUMBER(1)              null    ,
    FLAG_CONTRIBUENTE               VARCHAR2(1)            null
        constraint ANCI_VER_FLAG_CONTRIBU_CC check (
            FLAG_CONTRIBUENTE is null or (FLAG_CONTRIBUENTE in ('S'))),
    SANZIONE_RAVVEDIMENTO           VARCHAR2(1)            null
        constraint ANCI_VER_SANZIONE_RAVV_CC check (
            SANZIONE_RAVVEDIMENTO is null or (SANZIONE_RAVVEDIMENTO in ('O','I','N'))),
    FONTE                           NUMBER(2)              null    ,
    FLAG_OK                         VARCHAR2(1)            null
        constraint ANCI_VER_FLAG_OK_CC check (
            FLAG_OK is null or (FLAG_OK in ('S'))),
    constraint ANCI_VER_PK primary key (PROGR_RECORD, ANNO_FISCALE)
        using index
)
/

comment on table ANCI_VER is 'ANVE - Versamenti da ANCI/CNC'
/

-- ============================================================
--   Index: ANVE_TIAN_FK
-- ============================================================
create index ANVE_TIAN_FK on ANCI_VER (TIPO_ANOMALIA asc)
/

-- ============================================================
--   Table: ANOMALIE_PARAMETRI
-- ============================================================
create table ANOMALIE_PARAMETRI
(
    ID_ANOMALIA_PARAMETRO           NUMBER(19)             not null,
    ID_TIPO_ANOMALIA                NUMBER(5)              not null,
    ANNO                            NUMBER(4)              not null,
    SCARTO                          NUMBER(9,3)            null    ,
    RENDITA_DA                      NUMBER(9,2)            null    ,
    RENDITA_A                       NUMBER(9,2)            null    ,
    TIPO_TRIBUTO                    VARCHAR2(5)            not null,
    CATEGORIE                       VARCHAR2(2000)         null    ,
    FLAG_IMPOSTA                    VARCHAR2(1)            null    ,
    UTENTE                          VARCHAR2(8)            not null,
    DATA_CREAZIONE                  DATE                   null    ,
    DATA_VARIAZIONE                 DATE                   null    ,
    ENTE                            VARCHAR2(4)            null    ,
    LOCKED                          NUMBER(1)              null    ,
    RENDITA_MEDIA                   NUMBER(15,2)           null    ,
    RENDITA_MASSIMA                 NUMBER(15,2)           null    ,
    VERSION                         NUMBER(10)             not null,
    VALORE_MEDIO                    NUMBER(15,2)           null    ,
    VALORE_MASSIMO                  NUMBER(15,2)           null    ,
    constraint ANOMALIE_PARAMETRI_PK primary key (ID_ANOMALIA_PARAMETRO)
)
/

comment on table ANOMALIE_PARAMETRI is 'ANOMALIE_PARAMETRI'
/

CREATE SEQUENCE HIBERNATE_SEQUENCE
  START WITH 1
  MAXVALUE 999999999999999999999999999
  MINVALUE 1
  NOCYCLE
  CACHE 20
  NOORDER
/

-- ============================================================
--   Index: ANPA_UK
-- ============================================================
create unique index ANPA_UK on ANOMALIE_PARAMETRI (ID_TIPO_ANOMALIA asc, ANNO asc, TIPO_TRIBUTO asc, FLAG_IMPOSTA asc, ENTE asc)
/

-- ============================================================
--   Index: ANPA_TIAN_FK
-- ============================================================
create index ANPA_TIAN_FK on ANOMALIE_PARAMETRI (ID_TIPO_ANOMALIA asc)
/

-- ============================================================
--   Index: ANPA_TITR_FK
-- ============================================================
create index ANPA_TITR_FK on ANOMALIE_PARAMETRI (TIPO_TRIBUTO asc)
/

-- ============================================================
--   Table: CLASSI_SUPERFICIE
-- ============================================================
create table CLASSI_SUPERFICIE
(
    ANNO                            NUMBER(4)              not null,
    SETTORE                         NUMBER(2)              not null,
    CLASSE                          NUMBER(6)              not null,
    IMPOSTA                         NUMBER(15,2)           null    ,
    constraint CLASSI_SUPERFICIE_PK primary key (ANNO, SETTORE, CLASSE)
)
/

comment on table CLASSI_SUPERFICIE is 'Classi di Superficie'
/

-- ============================================================
--   Index: CLSU_SEAT_FK
-- ============================================================
create index CLSU_SEAT_FK on CLASSI_SUPERFICIE (SETTORE asc)
/

-- ============================================================
--   Index: CLSU_SCRE_FK
-- ============================================================
create index CLSU_SCRE_FK on CLASSI_SUPERFICIE (ANNO asc)
/

-- ============================================================
--   Table: MODELLI
-- ============================================================
create table MODELLI
(
    MODELLO                         NUMBER(4)              not null,
    TIPO_TRIBUTO                    VARCHAR2(5)            not null,
    DESCRIZIONE                     VARCHAR2(60)           not null,
    DESCRIZIONE_ORD                 VARCHAR2(10)           not null,
    PATH                            VARCHAR2(200)          null    ,
    NOME_DW                         VARCHAR2(60)           null    ,
    FLAG_SOTTOMODELLO               VARCHAR2(1)            null
        constraint MODELLI_FLAG_SOTTOMOD_CC check (
            FLAG_SOTTOMODELLO is null or (FLAG_SOTTOMODELLO in ('S'))),
    CODICE_SOTTOMODELLO             VARCHAR2(60)           null    ,
    FLAG_EDITABILE                  VARCHAR2(1)            null
        constraint MODELLI_FLAG_EDITABIL_CC check (
            FLAG_EDITABILE is null or (FLAG_EDITABILE in ('S'))),
    DB_FUNCTION                     VARCHAR2(100)          null    ,
    FLAG_STANDARD                   VARCHAR2(1)            null
        constraint MODELLI_FLAG_STANDARD_CC check (
            FLAG_STANDARD is null or (FLAG_STANDARD in ('S'))),
    FLAG_F24                        VARCHAR2(1)            null
        constraint MODELLI_FLAG_F24_CC check (
            FLAG_F24 is null or (FLAG_F24 in ('S'))),
    FLAG_AVVISO_AGID                VARCHAR2(1)            null
        constraint MODELLI_FLAG_AVVISO_A_CC check (
            FLAG_AVVISO_AGID is null or (FLAG_AVVISO_AGID in ('S'))),
    FLAG_WEB                        VARCHAR2(1)            null
        constraint MODELLI_FLAG_WEB_CC check (
            FLAG_WEB is null or (FLAG_WEB in ('S'))),
    FLAG_EREDI                      VARCHAR2(1)            null
        constraint MODELLI_FLAG_EREDI_CC check (
            FLAG_EREDI is null or (FLAG_EREDI in ('S'))),
    constraint MODELLI_PK primary key (MODELLO)
)
/

comment on table MODELLI is 'MODE - Modelli'
/

-- ============================================================
--   Index: MODE_TITR_FK
-- ============================================================
create index MODE_TITR_FK on MODELLI (TIPO_TRIBUTO asc)
/

-- ============================================================
--   Index: MODE_TIMO_FK
-- ============================================================
create index MODE_TIMO_FK on MODELLI (DESCRIZIONE_ORD asc)
/

-- ============================================================
--   Index: MODE_COSO_UK
-- ============================================================
create unique index MODE_COSO_UK on MODELLI (CODICE_SOTTOMODELLO asc)
/

-- ============================================================
--   Table: TIPI_MODELLO_PARAMETRI
-- ============================================================
create table TIPI_MODELLO_PARAMETRI
(
    PARAMETRO_ID                    NUMBER                 not null,
    TIPO_MODELLO                    VARCHAR2(10)           not null,
    PARAMETRO                       VARCHAR2(30)           not null,
    DESCRIZIONE                     VARCHAR2(100)          null    ,
    LUNGHEZZA_MAX                   NUMBER(4)              not null,
    TESTO_PREDEFINITO               VARCHAR2(2000)         not null,
    constraint TIPI_MODELLO_PARAMETRI_PK primary key (PARAMETRO_ID)
)
/

comment on table TIPI_MODELLO_PARAMETRI is 'TIMP - Tipi Modello Parametri'
/

-- ============================================================
--   Index: TIMP_PARAMETRO_UK
-- ============================================================
create unique index TIMP_PARAMETRO_UK on TIPI_MODELLO_PARAMETRI (TIPO_MODELLO asc, PARAMETRO asc)
/

-- ============================================================
--   Index: TIMP_TIMO_FK
-- ============================================================
create index TIMP_TIMO_FK on TIPI_MODELLO_PARAMETRI (TIPO_MODELLO asc)
/

-- ============================================================
--   Table: DATI_METRICI_TESTATE
-- ============================================================
create table DATI_METRICI_TESTATE
(
    TESTATE_ID                      NUMBER(10)             not null,
    DOCUMENTO_ID                    NUMBER(10)             not null,
    ISCRIZIONE                      VARCHAR2(255)          null    ,
    DATA_INIZIALE                   DATE                   null    ,
    N_FILE                          NUMBER(3)              null    ,
    N_FILE_TOT                      NUMBER(3)              null    ,
    COMUNE                          VARCHAR2(4)            null    ,
    DATA_ESTRAZIONE                 DATE                   null    ,
    TOT_UIU                         NUMBER(4)              null    ,
    TIPOLOGIA                       VARCHAR2(5)            not null,
    constraint DATI_METRICI_TESTATE_PK primary key (TESTATE_ID)
)
/

comment on table DATI_METRICI_TESTATE is 'DMTE - Dati Metrici Testate'
/

-- ============================================================
--   Index: DMTE_DOCA_FK
-- ============================================================
create index DMTE_DOCA_FK on DATI_METRICI_TESTATE (DOCUMENTO_ID asc)
/

-- ============================================================
--   Table: LOCAZIONI_TESTATE
-- ============================================================
create table LOCAZIONI_TESTATE
(
    TESTATE_ID                      NUMBER(10)             not null,
    DOCUMENTO_ID                    NUMBER(10)             not null,
    INTESTAZIONE                    VARCHAR2(140)          null    ,
    DATA_FILE                       DATE                   null    ,
    ANNO                            NUMBER(4)              null    ,
    constraint LOCAZIONI_TESTATE_PK primary key (TESTATE_ID)
)
/

comment on table LOCAZIONI_TESTATE is 'LOTE - Locazioni Testate'
/

-- ============================================================
--   Index: LOTE_DOCA_FK
-- ============================================================
create index LOTE_DOCA_FK on LOCAZIONI_TESTATE (DOCUMENTO_ID asc)
/

-- ============================================================
--   Table: UTENZE_FORNITURE
-- ============================================================
create table UTENZE_FORNITURE
(
    FORNITURE_ID                    NUMBER(10)             not null,
    DOCUMENTO_ID                    NUMBER(10)             not null,
    IDENTIFICATIVO                  VARCHAR2(20)           null    ,
    PROGRESSIVO                     NUMBER(4)              null    ,
    DATA                            DATE                   not null,
    constraint UTENZE_FORNITURE_PK primary key (FORNITURE_ID)
)
/

comment on table UTENZE_FORNITURE is 'UTFO - Utenze Forniture'
/

-- ============================================================
--   Index: UTFO_DOCA_FK
-- ============================================================
create index UTFO_DOCA_FK on UTENZE_FORNITURE (DOCUMENTO_ID asc)
/

-- ============================================================
--   Table: SAM_RISPOSTE
-- ============================================================
create table SAM_RISPOSTE
(
    RISPOSTA_INTERROGAZIONE         NUMBER(10)             not null,
    TIPO_RECORD                     VARCHAR2(1)            not null,
    INTERROGAZIONE                  NUMBER(10)             not null,
    COD_FISCALE                     VARCHAR2(16)           null    ,
    COD_RITORNO                     VARCHAR2(10)           not null,
    COGNOME                         VARCHAR2(40)           null    ,
    NOME                            VARCHAR2(40)           null    ,
    DENOMINAZIONE                   VARCHAR2(150)          null    ,
    SESSO                           VARCHAR2(1)            null    ,
    DATA_NASCITA                    DATE                   null    ,
    COMUNE_NASCITA                  VARCHAR2(45)           null    ,
    PROVINCIA_NASCITA               VARCHAR2(2)            null    ,
    COMUNE_DOMICILIO                VARCHAR2(45)           null    ,
    PROVINCIA_DOMICILIO             VARCHAR2(2)            null    ,
    CAP_DOMICILIO                   VARCHAR2(5)            null    ,
    INDIRIZZO_DOMICILIO             VARCHAR2(35)           null    ,
    FONTE_DOMICILIO                 VARCHAR2(1)            null    ,
    DATA_DOMICILIO                  DATE                   null    ,
    FONTE_DECESSO                   VARCHAR2(1)            null    ,
    DATA_DECESSO                    DATE                   null    ,
    PRESENZA_ESTINZIONE             VARCHAR2(1)            null    ,
    DATA_ESTINZIONE                 DATE                   null    ,
    PARTITA_IVA                     VARCHAR2(11)           null    ,
    STATO_PARTITA_IVA               VARCHAR2(1)            null    ,
    COD_ATTIVITA                    VARCHAR2(6)            null    ,
    TIPOLOGIA_CODIFICA              VARCHAR2(1)            null    ,
    DATA_INIZIO_ATTIVITA            DATE                   null    ,
    DATA_FINE_ATTIVITA              DATE                   null    ,
    COMUNE_SEDE_LEGALE              VARCHAR2(45)           null    ,
    PROVINCIA_SEDE_LEGALE           VARCHAR2(2)            null    ,
    CAP_SEDE_LEGALE                 VARCHAR2(5)            null    ,
    INDIRIZZO_SEDE_LEGALE           VARCHAR2(35)           null    ,
    FONTE_SEDE_LEGALE               VARCHAR2(1)            null    ,
    DATA_SEDE_LEGALE                DATE                   null    ,
    COD_FISCALE_RAP                 VARCHAR2(16)           null    ,
    COD_CARICA                      VARCHAR2(1)            null    ,
    DATA_DECORRENZA_RAP             DATE                   null    ,
    DOCUMENTO_ID                    NUMBER(10)             not null,
    UTENTE                          VARCHAR2(8)            null    ,
    DATA_VARIAZIONE                 DATE                   null    ,
    constraint SAM_RISPOSTE_PK primary key (RISPOSTA_INTERROGAZIONE)
)
/

comment on table SAM_RISPOSTE is 'SRIS - SAM Risposte'
/

-- ============================================================
--   Index: SRIS_SINT_FK
-- ============================================================
create index SRIS_SINT_FK on SAM_RISPOSTE (INTERROGAZIONE asc)
/

-- ============================================================
--   Index: SRIS_SCRI_FK
-- ============================================================
create index SRIS_SCRI_FK on SAM_RISPOSTE (COD_RITORNO asc)
/

-- ============================================================
--   Index: SRIS_FDSE1_FK
-- ============================================================
create index SRIS_FDSE1_FK on SAM_RISPOSTE (FONTE_DOMICILIO asc)
/

-- ============================================================
--   Index: SRIS_SFDE_FK
-- ============================================================
create index SRIS_SFDE_FK on SAM_RISPOSTE (FONTE_DECESSO asc)
/

-- ============================================================
--   Index: SRIS_FDSE2_FK
-- ============================================================
create index SRIS_FDSE2_FK on SAM_RISPOSTE (FONTE_SEDE_LEGALE asc)
/

-- ============================================================
--   Index: SRIS_SCCA_FK
-- ============================================================
create index SRIS_SCCA_FK on SAM_RISPOSTE (COD_CARICA asc)
/

-- ============================================================
--   Index: SRIS_DOCA_FK
-- ============================================================
create index SRIS_DOCA_FK on SAM_RISPOSTE (DOCUMENTO_ID asc)
/

-- ============================================================
--   Table: DATI_METRICI_UIU
-- ============================================================
create table DATI_METRICI_UIU
(
    UIU_ID                          NUMBER(15)             not null,
    TESTATE_ID                      NUMBER(10)             not null,
    SEZ_CENS                        VARCHAR2(1)            null    ,
    ID_UIU                          NUMBER(15)             null    ,
    PROGRESSIVO                     NUMBER(10)             null    ,
    CATEGORIA                       VARCHAR2(3)            null    ,
    BENE_COMUNE                     NUMBER(1)              null    ,
    SUPERFICIE                      NUMBER(9,2)            null    ,
    constraint DATI_METRICI_UIU_PK primary key (UIU_ID)
)
/

comment on table DATI_METRICI_UIU is 'DMUI - Dati Metrici UIU'
/

-- ============================================================
--   Index: DMUI_DMTE_FK
-- ============================================================
create index DMUI_DMTE_FK on DATI_METRICI_UIU (TESTATE_ID asc)
/

-- ============================================================
--   Table: DATI_METRICI_SOGGETTI
-- ============================================================
create table DATI_METRICI_SOGGETTI
(
    SOGGETTI_ID                     NUMBER(15)             not null,
    ID_SOGGETTO                     NUMBER(15)             null    ,
    TIPO                            VARCHAR2(1)            null    ,
    COGNOME                         VARCHAR2(50)           null    ,
    NOME                            VARCHAR2(50)           null    ,
    SESSO                           VARCHAR2(1)            null    ,
    DATA_NASCITA                    DATE                   null    ,
    COMUNE                          VARCHAR2(30)           null    ,
    COD_FISCALE                     VARCHAR2(16)           null    ,
    DENOMINAZIONE                   VARCHAR2(150)          null    ,
    SEDE                            VARCHAR2(30)           null    ,
    UIU_ID                          NUMBER(15)             null    ,
    constraint DATI_METRICI_SOGGETTI_PK primary key (SOGGETTI_ID)
)
/

comment on table DATI_METRICI_SOGGETTI is 'DMSO - DAti Metrici Soggetti'
/

-- ============================================================
--   Index: DMSO_DMUI_FK
-- ============================================================
create index DMSO_DMUI_FK on DATI_METRICI_SOGGETTI (UIU_ID asc)
/

-- ============================================================
--   Table: LOCAZIONI_CONTRATTI
-- ============================================================
create table LOCAZIONI_CONTRATTI
(
    CONTRATTI_ID                    NUMBER(10)             not null,
    UFFICIO                         VARCHAR2(3)            null    ,
    ANNO                            NUMBER(4)              null    ,
    SERIE                           VARCHAR2(2)            null    ,
    NUMERO                          NUMBER(6)              null    ,
    SOTTO_NUMERO                    NUMBER(3)              null    ,
    PROGRESSIVO_NEGOZIO             NUMBER(3)              null    ,
    DATA_REGISTRAZIONE              DATE                   null    ,
    DATA_STIPULA                    DATE                   null    ,
    CODICE_OGGETTO                  VARCHAR2(2)            null    ,
    CODICE_NEGOZIO                  VARCHAR2(4)            null    ,
    IMPORTO_CANONE                  NUMBER(15,2)           null    ,
    VALUTA_CANONE                   VARCHAR2(1)            null    ,
    TIPO_CANONE                     VARCHAR2(1)            null    ,
    DATA_INIZIO                     DATE                   null    ,
    DATA_FINE                       DATE                   null    ,
    TESTATE_ID                      NUMBER(10)             not null,
    constraint LOCAZIONI_CONTRATTI_PK primary key (CONTRATTI_ID)
)
/

comment on table LOCAZIONI_CONTRATTI is 'LOCO - Locazioni Contratti'
/

-- ============================================================
--   Index: LOCO_LOTE_FK
-- ============================================================
create index LOCO_LOTE_FK on LOCAZIONI_CONTRATTI (TESTATE_ID asc)
/

-- ============================================================
--   Table: EVENTI
-- ============================================================
create table EVENTI
(
    TIPO_EVENTO                     VARCHAR2(1)            not null,
    SEQUENZA                        NUMBER(4)              not null,
    DATA_EVENTO                     DATE                   null    ,
    DESCRIZIONE                     VARCHAR2(60)           null    ,
    NOTE                            VARCHAR2(2000)         null    ,
    constraint EVENTI_PK primary key (TIPO_EVENTO, SEQUENZA)
)
/

comment on table EVENTI is 'EVEN - Eventi'
/

-- ============================================================
--   Index: EVEN_TIEV_FK
-- ============================================================
create index EVEN_TIEV_FK on EVENTI (TIPO_EVENTO asc)
/

-- ============================================================
--   Table: SOTTOCLASSI_CER
-- ============================================================
create table SOTTOCLASSI_CER
(
    CLASSE_CER                      VARCHAR2(2)            not null,
    SOTTOCLASSE_CER                 VARCHAR2(2)            not null,
    DESCRIZIONE                     VARCHAR2(200)          null    ,
    constraint SOTTOCLASSI_CER_PK primary key (CLASSE_CER, SOTTOCLASSE_CER)
)
/

comment on table SOTTOCLASSI_CER is 'SOCE - Sottoclassi CER'
/

-- ============================================================
--   Index: SOCE_CLCE_FK
-- ============================================================
create index SOCE_CLCE_FK on SOTTOCLASSI_CER (CLASSE_CER asc)
/

-- ============================================================
--   Table: CATEGORIE_CER
-- ============================================================
create table CATEGORIE_CER
(
    CODICE_CER                      VARCHAR2(6)            not null,
    DESCRIZIONE                     VARCHAR2(200)          not null,
    DESCRIZIONE_BREVE               VARCHAR2(60)           not null,
    CLASSE_CER                      VARCHAR2(2)            not null,
    SOTTOCLASSE_CER                 VARCHAR2(2)            not null,
    CATEGORIA_CER                   VARCHAR2(2)            not null,
    S_CODICE_CER                    VARCHAR2(8)            not null,
    PERICOLOSO                      VARCHAR2(1)            null
        constraint CATEGORIE_CER_PERICOLOSO_CC check (
            PERICOLOSO is null or (PERICOLOSO in ('S'))),
    NOTE                            VARCHAR2(2000)         null    ,
    constraint CATEGORIE_CER_PK primary key (CODICE_CER)
)
/

comment on table CATEGORIE_CER is 'CACE - CAtegorie CER'
/

-- ============================================================
--   Index: CACE_S_CODICE_IK
-- ============================================================
create unique index CACE_S_CODICE_IK on CATEGORIE_CER (S_CODICE_CER asc)
/

-- ============================================================
--   Index: CACE_SOCE_FK
-- ============================================================
create index CACE_SOCE_FK on CATEGORIE_CER (CLASSE_CER asc, SOTTOCLASSE_CER asc)
/

-- ============================================================
--   Table: WRK_DOCFA_TESTATA
-- ============================================================
create table WRK_DOCFA_TESTATA
(
    DOCUMENTO_ID                    NUMBER(10)             not null,
    DOCUMENTO_MULTI_ID              NUMBER(10)             not null,
    UNITA_DEST_ORD                  NUMBER(3)              null    ,
    UNITA_DEST_SPEC                 NUMBER(3)              null    ,
    UNITA_NON_CENSITE               NUMBER(3)              null    ,
    UNITA_SOPPRESSE                 NUMBER(3)              null    ,
    UNITA_VARIATE                   NUMBER(3)              null    ,
    UNITA_COSTITUITE                NUMBER(3)              null    ,
    CAUSALE                         VARCHAR2(3)            null    ,
    NOTE1                           VARCHAR2(35)           null    ,
    NOTE2                           VARCHAR2(35)           null    ,
    NOTE3                           VARCHAR2(35)           null    ,
    NOTE4                           VARCHAR2(42)           null    ,
    NOTE5                           VARCHAR2(380)          null    ,
    COGNOME_DIC                     VARCHAR2(24)           null    ,
    NOME_DIC                        VARCHAR2(20)           null    ,
    COMUNE_DIC                      VARCHAR2(25)           null    ,
    PROVINCIA_DIC                   VARCHAR2(2)            null    ,
    INDIRIZZO_DIC                   VARCHAR2(35)           null    ,
    CIVICO_DIC                      VARCHAR2(5)            null    ,
    CAP_DIC                         VARCHAR2(5)            null    ,
    COGNOME_TEC                     VARCHAR2(24)           null    ,
    NOME_TEC                        VARCHAR2(20)           null    ,
    COD_FISCALE_TEC                 VARCHAR2(16)           null    ,
    ALBO_TEC                        VARCHAR2(2)            null    ,
    NUM_ISCRIZIONE_TEC              VARCHAR2(5)            null    ,
    PROV_ISCRIZIONE_TEC             VARCHAR2(2)            null    ,
    DATA_REALIZZAZIONE              DATE                   null    ,
    FONTE                           NUMBER(2)              null    ,
    constraint WRK_DOCFA_TESTATA_PK primary key (DOCUMENTO_ID, DOCUMENTO_MULTI_ID)
)
/

comment on table WRK_DOCFA_TESTATA is 'WRK_DOCFA_TESTATA'
/

-- ============================================================
--   Index: WDTE_FONT_FK
-- ============================================================
create index WDTE_FONT_FK on WRK_DOCFA_TESTATA (FONTE asc)
/

-- ============================================================
--   Index: WDTE_WDCA_FK
-- ============================================================
create index WDTE_WDCA_FK on WRK_DOCFA_TESTATA (CAUSALE asc)
/

-- ============================================================
--   Table: WRK_DOCFA_OGGETTI
-- ============================================================
create table WRK_DOCFA_OGGETTI
(
    DOCUMENTO_ID                    NUMBER(10)             not null,
    DOCUMENTO_MULTI_ID              NUMBER(10)             not null,
    PROGR_OGGETTO                   NUMBER(3)              not null,
    TIPO_OPERAZIONE                 VARCHAR2(1)            null    ,
    SEZIONE                         VARCHAR2(3)            null    ,
    FOGLIO                          VARCHAR2(4)            null    ,
    NUMERO                          VARCHAR2(5)            null    ,
    SUBALTERNO                      VARCHAR2(4)            null    ,
    COD_VIA                         NUMBER(6)              null    ,
    INDIRIZZO                       VARCHAR2(44)           null    ,
    NUM_CIVICO                      VARCHAR2(5)            null    ,
    PIANO                           VARCHAR2(4)            null    ,
    SCALA                           VARCHAR2(2)            null    ,
    INTERNO                         VARCHAR2(3)            null    ,
    ZONA                            VARCHAR2(3)            null    ,
    CATEGORIA                       VARCHAR2(3)            null    ,
    CLASSE                          VARCHAR2(2)            null    ,
    CONSISTENZA                     VARCHAR2(6)            null    ,
    SUPERFICIE_CATASTALE            NUMBER(5)              null    ,
    RENDITA                         NUMBER(10,2)           null    ,
    TR4_OGGETTO                     NUMBER(10)             null    ,
    constraint WRK_DOCFA_OGGETTI_PK primary key (DOCUMENTO_ID, DOCUMENTO_MULTI_ID, PROGR_OGGETTO)
)
/

comment on table WRK_DOCFA_OGGETTI is 'WRK_DOCFA_OGGETTI'
/

-- ============================================================
--   Index: WDOG_WDTE_FK
-- ============================================================
create index WDOG_WDTE_FK on WRK_DOCFA_OGGETTI (DOCUMENTO_ID asc, DOCUMENTO_MULTI_ID asc)
/

-- ============================================================
--   Table: WRK_ENC_IMMOBILI
-- ============================================================
create table WRK_ENC_IMMOBILI
(
    DOCUMENTO_ID                    NUMBER(10)             not null,
    PROGR_DICHIARAZIONE             NUMBER(4)              not null,
    TIPO_IMMOBILE                   VARCHAR2(1)            not null,
    PROGR_IMMOBILE                  NUMBER(6)              not null,
    NUM_ORDINE                      NUMBER(4)              not null,
    TIPO_ATTIVITA                   NUMBER(2)              null    ,
    CARATTERISTICA                  VARCHAR2(3)            null    ,
    INDIRIZZO                       VARCHAR2(100)          null    ,
    TIPO                            VARCHAR2(1)            null    ,
    COD_CATASTALE                   VARCHAR2(5)            null    ,
    SEZIONE                         VARCHAR2(3)            null    ,
    FOGLIO                          VARCHAR2(4)            null    ,
    NUMERO                          VARCHAR2(10)           null    ,
    SUBALTERNO                      VARCHAR2(4)            null    ,
    CATEGORIA_CATASTO               VARCHAR2(25)           null    ,
    CLASSE_CATASTO                  VARCHAR2(10)           null    ,
    PROTOCOLLO_CATASTO              VARCHAR2(20)           null    ,
    ANNO_CATASTO                    VARCHAR2(4)            null    ,
    IMMOBILE_STORICO                NUMBER(1)              null    ,
    VALORE                          NUMBER(15)             null    ,
    IMMOBILE_ESENTE                 NUMBER(1)              null    ,
    PERC_POSSESSO                   NUMBER(5,2)            null    ,
    DATA_VAR_IMPOSTA                VARCHAR2(8)            null    ,
    FLAG_ACQUISTO                   NUMBER(1)              null    ,
    FLAG_CESSIONE                   NUMBER(1)              null    ,
    AGENZIA_ENTRATE                 VARCHAR2(24)           null    ,
    ESTREMI_TITOLO                  VARCHAR2(24)           null    ,
    D_CORRISPETTIVO_MEDIO           NUMBER(9,2)            null    ,
    D_COSTO_MEDIO                   NUMBER(9,2)            null    ,
    D_RAPPORTO_SUPERFICIE           NUMBER(5,2)            null    ,
    D_RAPPORTO_SUP_GG               NUMBER(5,2)            null    ,
    D_RAPPORTO_SOGGETTI             NUMBER(5,2)            null    ,
    D_RAPPORTO_SOGG_GG              NUMBER(5,2)            null    ,
    D_RAPPORTO_GIORNI               NUMBER(5,2)            null    ,
    D_PERC_IMPONIBILITA             NUMBER(5,2)            null    ,
    D_VALORE_ASS_ART_5              NUMBER(12)             null    ,
    D_VALORE_ASS_ART_4              NUMBER(12)             null    ,
    D_CASELLA_RIGO_G                NUMBER(1)              null    ,
    D_CASELLA_RIGO_H                NUMBER(1)              null    ,
    D_RAPPORTO_CMS_CM               NUMBER(5,2)            null    ,
    D_VALORE_ASS_PARZIALE           NUMBER(12)             null    ,
    D_VALORE_ASS_COMPL              NUMBER(12)             null    ,
    A_CORRISPETTIVO_MEDIO_PERC      NUMBER(9,2)            null    ,
    A_CORRISPETTIVO_MEDIO_PREV      NUMBER(9,2)            null    ,
    A_RAPPORTO_SUPERFICIE           NUMBER(5,2)            null    ,
    A_RAPPORTO_SUP_GG               NUMBER(5,2)            null    ,
    A_RAPPORTO_SOGGETTI             NUMBER(5,2)            null    ,
    A_RAPPORTO_SOGG_GG              NUMBER(5,2)            null    ,
    A_RAPPORTO_GIORNI               NUMBER(5,2)            null    ,
    A_PERC_IMPONIBILITA             NUMBER(5,2)            null    ,
    A_VALORE_ASSOGGETTATO           NUMBER(12)             null    ,
    ANNOTAZIONI                     VARCHAR2(500)          null    ,
    DATA_VARIAZIONE                 DATE                   null    ,
    UTENTE                          VARCHAR2(8)            null    ,
    TR4_OGGETTO                     NUMBER(10)             null    ,
    TR4_OGGETTO_NEW                 NUMBER(10)             null    ,
    TR4_OGGETTO_PRATICA_ICI         NUMBER(10)             null    ,
    TR4_OGGETTO_PRATICA_TASI        NUMBER(10)             null    ,
    PROGR_IMMOBILE_DICH             NUMBER(4)              null    ,
    IND_CONTINUITA                  NUMBER(1)              null    ,
    FLAG_ALTRO                      NUMBER(1)              null    ,
    DESCRIZIONE_ALTRO               VARCHAR2(100)          null    ,
    DETRAZIONE                      NUMBER(15,2)           null
        constraint WRK_ENC_IMMOB_DETRAZIONE_CC check (
            DETRAZIONE is null or (DETRAZIONE >= 0
            )),
    constraint WRK_ENC_IMMOBILI_PK primary key (DOCUMENTO_ID, PROGR_DICHIARAZIONE, TIPO_IMMOBILE, PROGR_IMMOBILE, NUM_ORDINE)
)
/

comment on table WRK_ENC_IMMOBILI is 'WEIM - Wrk_enc_immobili'
/

-- ============================================================
--   Index: WEIM_WETE_FK
-- ============================================================
create index WEIM_WETE_FK on WRK_ENC_IMMOBILI (DOCUMENTO_ID asc, PROGR_DICHIARAZIONE asc)
/

-- ============================================================
--   Table: DENUNCE_ICI
-- ============================================================
create table DENUNCE_ICI
(
    PRATICA                         NUMBER(10)             not null,
    DENUNCIA                        NUMBER(7)              not null,
    PREFISSO_TELEFONICO             VARCHAR2(4)            null    ,
    NUM_TELEFONICO                  NUMBER(8)              null    ,
    FLAG_CF                         VARCHAR2(1)            null
        constraint DENUNCE_ICI_FLAG_CF_CC check (
            FLAG_CF is null or (FLAG_CF in ('S'))),
    FLAG_FIRMA                      VARCHAR2(1)            null
        constraint DENUNCE_ICI_FLAG_FIRMA_CC check (
            FLAG_FIRMA is null or (FLAG_FIRMA in ('S'))),
    FLAG_DENUNCIANTE                VARCHAR2(1)            null
        constraint DENUNCE_ICI_FLAG_DENUNCIA_CC check (
            FLAG_DENUNCIANTE is null or (FLAG_DENUNCIANTE in ('S'))),
    PROGR_ANCI                      NUMBER(8)              null    ,
    FONTE                           NUMBER(2)              not null,
    UTENTE                          VARCHAR2(8)            not null,
    DATA_VARIAZIONE                 DATE                   not null,
    NOTE                            VARCHAR2(2000)         null    ,
    constraint DENUNCE_ICI_PK primary key (PRATICA)
        using index
)
/

comment on table DENUNCE_ICI is 'DEIC - Denunce ICI'
/

-- ============================================================
--   Index: DEIC_FONT_FK
-- ============================================================
create index DEIC_FONT_FK on DENUNCE_ICI (FONTE asc)
/

-- ============================================================
--   Table: DENUNCE_ICIAP
-- ============================================================
create table DENUNCE_ICIAP
(
    PRATICA                         NUMBER(10)             not null,
    NUM_UIP                         NUMBER(2)              null    ,
    DES_PROF                        VARCHAR2(60)           null    ,
    COD_ATTIVITA                    VARCHAR2(5)            null    ,
    FLAG_ALBO                       VARCHAR2(1)            null
        constraint DENUNCE_ICIAP_FLAG_ALBO_CC check (
            FLAG_ALBO is null or (FLAG_ALBO in ('S'))),
    LOCALE                          NUMBER(8,2)            null    ,
    COPERTA                         NUMBER(8,2)            null    ,
    SCOPERTA                        NUMBER(8,2)            null    ,
    SUPERFICIE                      NUMBER(8,2)            null    ,
    RIDUZIONE                       NUMBER(8,2)            null    ,
    CONSISTENZA                     NUMBER(8,2)            null    ,
    SETTORE                         NUMBER(2)              null    ,
    REDDITO                         NUMBER(15,2)           null    ,
    REDDITO_ZERO                    VARCHAR2(1)            null    ,
    COEFF_REDDITO                   NUMBER(1)              null    ,
    DATA_COMPILAZIONE               DATE                   null    ,
    FLAG_CF                         VARCHAR2(1)            null
        constraint DENUNCE_ICIAP_FLAG_CF_CC check (
            FLAG_CF is null or (FLAG_CF in ('S'))),
    FLAG_FIRMA                      VARCHAR2(1)            null
        constraint DENUNCE_ICIAP_FLAG_FIRMA_CC check (
            FLAG_FIRMA is null or (FLAG_FIRMA in ('S'))),
    FLAG_DENUNCIANTE                VARCHAR2(1)            null
        constraint DENUNCE_ICIAP_FLAG_DENUNCIA_CC check (
            FLAG_DENUNCIANTE is null or (FLAG_DENUNCIANTE in ('S'))),
    FLAG_SETTORE                    VARCHAR2(1)            null
        constraint DENUNCE_ICIAP_FLAG_SETTORE_CC check (
            FLAG_SETTORE is null or (FLAG_SETTORE in ('S'))),
    FLAG_STAGIONALE                 VARCHAR2(1)            null    ,
    FLAG_VERSAMENTO                 VARCHAR2(1)            null
        constraint DENUNCE_ICIAP_FLAG_VERSAMEN_CC check (
            FLAG_VERSAMENTO is null or (FLAG_VERSAMENTO in ('S'))),
    UTENTE                          VARCHAR2(8)            not null,
    DATA_VARIAZIONE                 DATE                   not null,
    NOTE                            VARCHAR2(2000)         null    ,
    constraint DENUNCE_ICIAP_PK primary key (PRATICA)
)
/

comment on table DENUNCE_ICIAP is 'DEIP - Denunce ICIAP'
/

-- ============================================================
--   Index: DEIP_SEAT_FK
-- ============================================================
create index DEIP_SEAT_FK on DENUNCE_ICIAP (SETTORE asc)
/

-- ============================================================
--   Table: RIFERIMENTI_OGGETTO
-- ============================================================
create table RIFERIMENTI_OGGETTO
(
    OGGETTO                         NUMBER(10)             not null
        constraint RIFERIMENTI_O_OGGETTO_CC check (
            OGGETTO >= 0),
    INIZIO_VALIDITA                 DATE                   not null,
    FINE_VALIDITA                   DATE                   not null,
    DA_ANNO                         NUMBER(4)              not null,
    A_ANNO                          NUMBER(4)              not null,
    RENDITA                         NUMBER(15,2)           not null
        constraint RIFERIMENTI_O_RENDITA_CC check (
            RENDITA >= 0),
    ANNO_RENDITA                    NUMBER(4)              null    ,
    CATEGORIA_CATASTO               VARCHAR2(3)            null    ,
    CLASSE_CATASTO                  VARCHAR2(2)            null    ,
    DATA_REG                        DATE                   null    ,
    DATA_REG_ATTI                   DATE                   null    ,
    UTENTE                          VARCHAR2(8)            null    ,
    DATA_VARIAZIONE                 DATE                   null    ,
    NOTE                            VARCHAR2(2000)         null    ,
    constraint RIFERIMENTI_OGGETTO_PK primary key (OGGETTO, INIZIO_VALIDITA)
)
/

comment on table RIFERIMENTI_OGGETTO is 'RIOG - Riferimenti Oggetto'
/

-- ============================================================
--   Index: RIOG_DATA_IK
-- ============================================================
create index RIOG_DATA_IK on RIFERIMENTI_OGGETTO (DATA_REG asc)
/

-- ============================================================
--   Index: RIOG_OGGE_FK
-- ============================================================
create index RIOG_OGGE_FK on RIFERIMENTI_OGGETTO (OGGETTO asc)
/

-- ============================================================
--   Table: SANZIONI_PRATICA
-- ============================================================
create table SANZIONI_PRATICA
(
    PRATICA                         NUMBER(10)             not null,
    COD_SANZIONE                    NUMBER(4)              not null,
    SEQUENZA_SANZ                   NUMBER(4)              not null,
    SEQUENZA                        NUMBER(4)              not null,
    TIPO_TRIBUTO                    VARCHAR2(5)            not null,
    OGGETTO_PRATICA                 NUMBER(10)             null    ,
    SEMESTRI                        NUMBER(2)              null    ,
    PERCENTUALE                     NUMBER(5,2)            null    ,
    IMPORTO                         NUMBER(15,2)           null    ,
    RIDUZIONE                       NUMBER(5,2)            null    ,
    RUOLO                           NUMBER(10)             null    ,
    IMPORTO_RUOLO                   NUMBER(15,2)           null    ,
    UTENTE                          VARCHAR2(8)            not null,
    DATA_VARIAZIONE                 DATE                   not null,
    NOTE                            VARCHAR2(2000)         null    ,
    GIORNI                          NUMBER(4)              null    ,
    RIDUZIONE_2                     NUMBER(5,2)            null    ,
    AB_PRINCIPALE                   NUMBER(15,2)           null    ,
    RURALI                          NUMBER(15,2)           null    ,
    TERRENI_COMUNE                  NUMBER(15,2)           null    ,
    TERRENI_ERARIALE                NUMBER(15,2)           null    ,
    AREE_COMUNE                     NUMBER(15,2)           null    ,
    AREE_ERARIALE                   NUMBER(15,2)           null    ,
    ALTRI_COMUNE                    NUMBER(15,2)           null    ,
    ALTRI_ERARIALE                  NUMBER(15,2)           null    ,
    FABBRICATI_D_COMUNE             NUMBER(15,2)           null    ,
    FABBRICATI_D_ERARIALE           NUMBER(15,2)           null    ,
    FABBRICATI_MERCE                NUMBER(15,2)           null    ,
    DATA_INIZIO                     DATE                   null    ,
    DATA_FINE                       DATE                   null    ,
    constraint SANZIONI_PRATICA_PK primary key (PRATICA, COD_SANZIONE, SEQUENZA_SANZ, SEQUENZA)
        using index
)
/

comment on table SANZIONI_PRATICA is 'SAPR - Sanzioni Pratica'
/

-- ============================================================
--   Index: SAPR_PRTR_FK
-- ============================================================
create index SAPR_PRTR_FK on SANZIONI_PRATICA (PRATICA asc)
/

-- ============================================================
--   Index: SAPR_RUOL_FK
-- ============================================================
create index SAPR_RUOL_FK on SANZIONI_PRATICA (RUOLO asc)
/

-- ============================================================
--   Index: SAPR_SANZ_FK
-- ============================================================
create index SAPR_SANZ_FK on SANZIONI_PRATICA (TIPO_TRIBUTO asc, COD_SANZIONE asc, SEQUENZA_SANZ asc)
/

-- ============================================================
--   Index: SAPR_OGPR_FK
-- ============================================================
create index SAPR_OGPR_FK on SANZIONI_PRATICA (OGGETTO_PRATICA asc)
/

-- ============================================================
--   Table: ANCI_ANA
-- ============================================================
create table ANCI_ANA
(
    CONCESSIONE                     NUMBER(3)              null    ,
    ENTE                            VARCHAR2(4)            null    ,
    PROGR_QUIETANZA                 NUMBER(10)             null    ,
    PROGR_RECORD                    NUMBER(8)              not null,
    TIPO_RECORD                     VARCHAR2(1)            not null,
    COGNOME                         VARCHAR2(24)           null    ,
    NOME                            VARCHAR2(20)           null    ,
    COMUNE                          VARCHAR2(25)           null    ,
    FILLER                          VARCHAR2(105)          null    ,
    ANNO_FISCALE                    NUMBER(4)              not null,
    constraint ANCI_ANA_PK primary key (PROGR_RECORD, ANNO_FISCALE)
)
/

comment on table ANCI_ANA is 'ANAN - Anagrafiche non codificate relative ai versamenti ANCI/CNC'
/

-- ============================================================
--   Table: ANCI_SOC
-- ============================================================
create table ANCI_SOC
(
    CONCESSIONE                     NUMBER(3)              null    ,
    ENTE                            VARCHAR2(4)            null    ,
    PROGR_QUIETANZA                 NUMBER(10)             null    ,
    PROGR_RECORD                    NUMBER(8)              not null,
    TIPO_RECORD                     VARCHAR2(1)            not null,
    RAGIONE_SOCIALE                 VARCHAR2(60)           null    ,
    COMUNE                          VARCHAR2(25)           null    ,
    FILLER                          VARCHAR2(89)           null    ,
    ANNO_FISCALE                    NUMBER(4)              not null,
    constraint ANCI_SOC_PK primary key (PROGR_RECORD, ANNO_FISCALE)
)
/

comment on table ANCI_SOC is 'ANSO - Anagrafiche di societa non codificate relative ai versamenti ANCI/CNC'
/

-- ============================================================
--   Table: STORICO_SOGGETTI
-- ============================================================
create table STORICO_SOGGETTI
(
    NI                              NUMBER(10)             not null,
    DAL                             DATE                   not null,
    AL                              DATE                   not null,
    COD_FISCALE                     VARCHAR2(16)           null    ,
    COGNOME_NOME                    VARCHAR2(60)           not null,
    FASCIA                          NUMBER(2)              null
        constraint STORICO_SOGGE_FASCIA_CC check (
            FASCIA is null or (FASCIA in (1,2,3,4,5,6))),
    STATO                           NUMBER(2)              null    ,
    SESSO                           VARCHAR2(1)            null
        constraint STORICO_SOGGE_SESSO_CC check (
            SESSO is null or (SESSO in ('M','F'))),
    COD_FAM                         NUMBER(10)             null    ,
    RAPPORTO_PAR                    VARCHAR2(2)            null    ,
    SEQUENZA_PAR                    NUMBER(2)              null    ,
    DATA_NAS                        DATE                   null    ,
    COD_PRO_NAS                     NUMBER(3)              null    ,
    COD_COM_NAS                     NUMBER(3)              null    ,
    COD_PRO_RES                     NUMBER(3)              null    ,
    COD_COM_RES                     NUMBER(3)              null    ,
    CAP                             NUMBER(5)              null    ,
    DENOMINAZIONE_VIA               VARCHAR2(60)           null    ,
    COD_VIA                         NUMBER(6)              null    ,
    NUM_CIV                         NUMBER(6)              null    ,
    SUFFISSO                        VARCHAR2(10)           null    ,
    SCALA                           VARCHAR2(5)            null    ,
    PIANO                           VARCHAR2(5)            null    ,
    INTERNO                         NUMBER(4)              null    ,
    PARTITA_IVA                     VARCHAR2(11)           null    ,
    RAPPRESENTANTE                  VARCHAR2(40)           null    ,
    INDIRIZZO_RAP                   VARCHAR2(50)           null    ,
    COD_PRO_RAP                     NUMBER(3)              null    ,
    COD_COM_RAP                     NUMBER(3)              null    ,
    COD_FISCALE_RAP                 VARCHAR2(16)           null    ,
    TIPO_CARICA                     NUMBER(4)              null    ,
    TIPO                            VARCHAR2(1)            not null
        constraint STORICO_SOGGE_TIPO_CC check (
            TIPO in ('0','1','2')),
    COGNOME                         VARCHAR2(60)           null    ,
    NOME                            VARCHAR2(36)           null    ,
    UTENTE                          VARCHAR2(8)            not null,
    DATA_VARIAZIONE                 DATE                   not null,
    NOTE                            VARCHAR2(2000)         null    ,
    NI_PRESSO                       NUMBER(10)             null    ,
    INTESTATARIO_FAM                VARCHAR2(60)           null    ,
    FONTE                           NUMBER(2)              null    ,
    constraint STORICO_SOGGETTI_PK primary key (NI, DAL)
)
/

comment on table STORICO_SOGGETTI is 'STSO - Storico Soggetti'
/

-- ============================================================
--   Index: STSO_SOGG_FK
-- ============================================================
create index STSO_SOGG_FK on STORICO_SOGGETTI (NI asc)
/

-- ============================================================
--   Index: STSO_FONT_FK
-- ============================================================
create index STSO_FONT_FK on STORICO_SOGGETTI (FONTE asc)
/

-- ============================================================
--   Table: UTILIZZI_OGGETTO
-- ============================================================
create table UTILIZZI_OGGETTO
(
    OGGETTO                         NUMBER(10)             not null
        constraint UTILIZZI_OGGE_OGGETTO_CC check (
            OGGETTO >= 0),
    TIPO_TRIBUTO                    VARCHAR2(5)            not null,
    ANNO                            NUMBER(4)              not null,
    TIPO_UTILIZZO                   NUMBER(2)              not null,
    SEQUENZA                        NUMBER(4)              not null,
    NI                              NUMBER(10)             null    ,
    MESI_AFFITTO                    NUMBER(2)              null    ,
    DATA_SCADENZA                   DATE                   null    ,
    INTESTATARIO                    VARCHAR2(60)           null    ,
    TIPO_USO                        NUMBER(4)              null    ,
    UTENTE                          VARCHAR2(8)            not null,
    DATA_VARIAZIONE                 DATE                   not null,
    NOTE                            VARCHAR2(2000)         null    ,
    DAL                             DATE                   null    ,
    AL                              DATE                   null    ,
    constraint UTILIZZI_OGGETTO_PK primary key (OGGETTO, TIPO_TRIBUTO, ANNO, TIPO_UTILIZZO, SEQUENZA)
)
/

comment on table UTILIZZI_OGGETTO is 'UTOG - Utilizzi Oggetto'
/

-- ============================================================
--   Index: UTOG_OGGE_FK
-- ============================================================
create index UTOG_OGGE_FK on UTILIZZI_OGGETTO (OGGETTO asc)
/

-- ============================================================
--   Index: UTOG_TIUT_FK
-- ============================================================
create index UTOG_TIUT_FK on UTILIZZI_OGGETTO (TIPO_UTILIZZO asc)
/

-- ============================================================
--   Index: UTOG_TIUS_FK
-- ============================================================
create index UTOG_TIUS_FK on UTILIZZI_OGGETTO (TIPO_USO asc)
/

-- ============================================================
--   Index: UTOG_SOGG_FK
-- ============================================================
create index UTOG_SOGG_FK on UTILIZZI_OGGETTO (NI asc)
/

-- ============================================================
--   Table: MAGGIORI_DETRAZIONI
-- ============================================================
create table MAGGIORI_DETRAZIONI
(
    COD_FISCALE                     VARCHAR2(16)           not null,
    TIPO_TRIBUTO                    VARCHAR2(5)            not null,
    ANNO                            NUMBER(4)              not null,
    MOTIVO_DETRAZIONE               NUMBER(2)              not null,
    DETRAZIONE                      NUMBER(15,2)           null
        constraint MAGGIORI_DETR_DETRAZIONE_CC check (
            DETRAZIONE is null or (DETRAZIONE >= 0
            )),
    NOTE                            VARCHAR2(2000)         null    ,
    DETRAZIONE_ACCONTO              NUMBER(15,2)           null    ,
    DETRAZIONE_BASE                 NUMBER(15,2)           null    ,
    FLAG_DETRAZIONE_POSSESSO        VARCHAR2(1)            null
        constraint MAGGIORI_DETR_FLAG_DETRAZIO_CC check (
            FLAG_DETRAZIONE_POSSESSO is null or (FLAG_DETRAZIONE_POSSESSO in ('S'))),
    constraint MAGGIORI_DETRAZIONI_PK primary key (COD_FISCALE, TIPO_TRIBUTO, ANNO)
)
/

comment on table MAGGIORI_DETRAZIONI is 'MADE - Maggiori Detrazioni per contribuente'
/

-- ============================================================
--   Index: MADE_CONT_FK
-- ============================================================
create index MADE_CONT_FK on MAGGIORI_DETRAZIONI (COD_FISCALE asc)
/

-- ============================================================
--   Index: MADE_DETR_FK
-- ============================================================
create index MADE_DETR_FK on MAGGIORI_DETRAZIONI (TIPO_TRIBUTO asc, ANNO asc)
/

-- ============================================================
--   Index: MADE_MODE_FK
-- ============================================================
create index MADE_MODE_FK on MAGGIORI_DETRAZIONI (TIPO_TRIBUTO asc, MOTIVO_DETRAZIONE asc)
/

-- ============================================================
--   Table: SCADENZE
-- ============================================================
create table SCADENZE
(
    TIPO_TRIBUTO                    VARCHAR2(5)            not null,
    ANNO                            NUMBER(4)              not null,
    SEQUENZA                        NUMBER(4)              not null,
    TIPO_SCADENZA                   VARCHAR2(1)            not null
        constraint SCADENZE_TIPO_SCADENZA_CC check (
            TIPO_SCADENZA in ('D','V','T','R')),
    RATA                            NUMBER(2)              null
        constraint SCADENZE_RATA_CC check (
            RATA is null or (RATA in (0,1,2,3,4,5,6))),
    TIPO_VERSAMENTO                 VARCHAR2(1)            null
        constraint SCADENZE_TIPO_VERSAMEN_CC check (
            TIPO_VERSAMENTO is null or (TIPO_VERSAMENTO in ('A','S','U'))),
    DATA_SCADENZA                   DATE                   not null,
    GRUPPO_TRIBUTO                  VARCHAR2(10)           null    ,
    TIPO_OCCUPAZIONE                VARCHAR2(1)            null
        constraint SCADENZE_TIPO_OCCUPAZI_CC check (
            TIPO_OCCUPAZIONE is null or (TIPO_OCCUPAZIONE in ('P','T'))),
    constraint SCADENZE_PK primary key (TIPO_TRIBUTO, ANNO, SEQUENZA)
)
/

comment on table SCADENZE is 'SCAD - Scadenze'
/

-- ============================================================
--   Index: SCAD_ANNO_TITR_IK
-- ============================================================
create index SCAD_ANNO_TITR_IK on SCADENZE (ANNO asc, TIPO_TRIBUTO asc, TIPO_SCADENZA asc)
/

-- ============================================================
--   Index: SCAD_TITR_FK
-- ============================================================
create index SCAD_TITR_FK on SCADENZE (TIPO_TRIBUTO asc)
/

-- ============================================================
--   Index: SCAD_GRTR_FK
-- ============================================================
create index SCAD_GRTR_FK on SCADENZE (TIPO_TRIBUTO asc, GRUPPO_TRIBUTO asc)
/

-- ============================================================
--   Table: RIVALUTAZIONI_RENDITA
-- ============================================================
create table RIVALUTAZIONI_RENDITA
(
    ANNO                            NUMBER(4)              not null,
    TIPO_OGGETTO                    NUMBER(2)              not null,
    ALIQUOTA                        NUMBER(6,2)            not null,
    constraint RIVALUTAZIONI_RENDITA_PK primary key (ANNO, TIPO_OGGETTO)
)
/

comment on table RIVALUTAZIONI_RENDITA is 'RIRE - Rivalutazioni Rendita'
/

-- ============================================================
--   Index: RIRE_TIOG_FK
-- ============================================================
create index RIRE_TIOG_FK on RIVALUTAZIONI_RENDITA (TIPO_OGGETTO asc)
/

-- ============================================================
--   Table: RAPPORTI_TRIBUTO
-- ============================================================
create table RAPPORTI_TRIBUTO
(
    PRATICA                         NUMBER(10)             not null,
    SEQUENZA                        NUMBER(4)              not null,
    COD_FISCALE                     VARCHAR2(16)           not null,
    TIPO_RAPPORTO                   VARCHAR2(1)            null
        constraint RAPPORTI_TRIB_TIPO_RAPPORTO_CC check (
            TIPO_RAPPORTO is null or (TIPO_RAPPORTO in ('D','C','E','A'))),
    constraint RAPPORTI_TRIBUTO_PK primary key (PRATICA, SEQUENZA)
        using index
)
/

comment on table RAPPORTI_TRIBUTO is 'RATR - Rapporti legati a tributi'
/

-- ============================================================
--   Index: RATR_CONT_FK
-- ============================================================
create index RATR_CONT_FK on RAPPORTI_TRIBUTO (COD_FISCALE asc)
/

-- ============================================================
--   Index: RATR_PRTR_FK
-- ============================================================
create index RATR_PRTR_FK on RAPPORTI_TRIBUTO (PRATICA asc)
/

-- ============================================================
--   Index: RATR_UK
-- ============================================================
create unique index RATR_UK on RAPPORTI_TRIBUTO (PRATICA asc, COD_FISCALE asc, TIPO_RAPPORTO asc)
/

-- ============================================================
--   Table: UTILIZZI_TRIBUTO
-- ============================================================
create table UTILIZZI_TRIBUTO
(
    TIPO_TRIBUTO                    VARCHAR2(5)            not null,
    TIPO_UTILIZZO                   NUMBER(2)              not null,
    constraint UTILIZZI_TRIBUTO_PK primary key (TIPO_TRIBUTO, TIPO_UTILIZZO)
)
/

comment on table UTILIZZI_TRIBUTO is 'UTTR - Utilizzi Tributo'
/

-- ============================================================
--   Index: UTTR_TIUT_FK
-- ============================================================
create index UTTR_TIUT_FK on UTILIZZI_TRIBUTO (TIPO_UTILIZZO asc)
/

-- ============================================================
--   Index: UTTR_TITR_FK
-- ============================================================
create index UTTR_TITR_FK on UTILIZZI_TRIBUTO (TIPO_TRIBUTO asc)
/

-- ============================================================
--   Table: OGGETTI_ICI_93
-- ============================================================
create table OGGETTI_ICI_93
(
    OGGETTO_PRATICA                 NUMBER(10)             not null,
    TIPO_RENDITA_93                 NUMBER(1)              null    ,
    TIPO_BENE_93                    NUMBER(1)              null    ,
    ESENZIONE_93                    NUMBER(1)              null    ,
    RIDUZIONE_93                    NUMBER(1)              null    ,
    PERCENTUALE_93                  NUMBER(1)              null    ,
    CONDUZIONE_93                   NUMBER(1)              null    ,
    AREA_FABBR_93                   NUMBER(1)              null    ,
    constraint OGGETTI_ICI_93_PK primary key (OGGETTO_PRATICA)
        using index
)
/

comment on table OGGETTI_ICI_93 is 'Oggetti ICI 93'
/

-- ============================================================
--   Table: CIVICI_EDIFICIO
-- ============================================================
create table CIVICI_EDIFICIO
(
    EDIFICIO                        NUMBER(10)             not null,
    SEQUENZA                        NUMBER(4)              not null,
    COD_VIA                         NUMBER(6)              not null,
    NUM_CIV                         NUMBER(6)              not null,
    SUFFISSO                        VARCHAR2(10)           null    ,
    constraint CIVICI_EDIFICIO_PK primary key (EDIFICIO, SEQUENZA)
)
/

comment on table CIVICI_EDIFICIO is 'CIED - Civici Edificio'
/

-- ============================================================
--   Index: CIED_EDIF_FK
-- ============================================================
create index CIED_EDIF_FK on CIVICI_EDIFICIO (EDIFICIO asc)
/

-- ============================================================
--   Index: CIED_ARVI_FK
-- ============================================================
create index CIED_ARVI_FK on CIVICI_EDIFICIO (COD_VIA asc)
/

-- ============================================================
--   Table: CIVICI_OGGETTO
-- ============================================================
create table CIVICI_OGGETTO
(
    OGGETTO                         NUMBER(10)             not null
        constraint CIVICI_OGGETT_OGGETTO_CC check (
            OGGETTO >= 0),
    SEQUENZA                        NUMBER(4)              not null,
    INDIRIZZO_LOCALITA              VARCHAR2(36)           null    ,
    COD_VIA                         NUMBER(6)              null    ,
    NUM_CIV                         NUMBER(6)              null    ,
    SUFFISSO                        VARCHAR2(10)           null    ,
    constraint CIVICI_OGGETTO_PK primary key (OGGETTO, SEQUENZA)
        using index
)
/

comment on table CIVICI_OGGETTO is 'CIOG - Civici Oggetto'
/

-- ============================================================
--   Index: CIOG_OGGE_FK
-- ============================================================
create index CIOG_OGGE_FK on CIVICI_OGGETTO (OGGETTO asc)
/

-- ============================================================
--   Index: CIOG_ARVI_FK
-- ============================================================
create index CIOG_ARVI_FK on CIVICI_OGGETTO (COD_VIA asc)
/

-- ============================================================
--   Table: VERSAMENTI
-- ============================================================
create table VERSAMENTI
(
    COD_FISCALE                     VARCHAR2(16)           not null,
    ANNO                            NUMBER(4)              not null,
    TIPO_TRIBUTO                    VARCHAR2(5)            not null,
    SEQUENZA                        NUMBER(4)              not null,
    OGGETTO_IMPOSTA                 NUMBER(10)             null    ,
    RATA_IMPOSTA                    NUMBER(10)             null    ,
    PRATICA                         NUMBER(10)             null    ,
    RATA                            NUMBER(2)              null    ,
    TIPO_VERSAMENTO                 VARCHAR2(1)            null
        constraint VERSAMENTI_TIPO_VERSAMEN_CC check (
            TIPO_VERSAMENTO is null or (TIPO_VERSAMENTO in ('A','S','U'))),
    DESCRIZIONE                     VARCHAR2(60)           null    ,
    PROVVEDIMENTO                   NUMBER(7)              null    ,
    UFFICIO_PT                      VARCHAR2(30)           null    ,
    NUM_BOLLETTINO                  NUMBER(12)             null    ,
    DATA_PAGAMENTO                  DATE                   null    ,
    IMPORTO_VERSATO                 NUMBER(15,2)           null    ,
    FABBRICATI                      NUMBER(4)              null    ,
    TERRENI_AGRICOLI                NUMBER(15,2)           null    ,
    AREE_FABBRICABILI               NUMBER(15,2)           null    ,
    AB_PRINCIPALE                   NUMBER(15,2)           null    ,
    ALTRI_FABBRICATI                NUMBER(15,2)           null    ,
    DETRAZIONE                      NUMBER(15,2)           null
        constraint VERSAMENTI_DETRAZIONE_CC check (
            DETRAZIONE is null or (DETRAZIONE >= 0
            )),
    PROGR_ANCI                      NUMBER(16)             null    ,
    CAUSALE                         VARCHAR2(200)          null    ,
    FONTE                           NUMBER(2)              null    ,
    UTENTE                          VARCHAR2(8)            not null,
    DATA_VARIAZIONE                 DATE                   not null,
    NOTE                            VARCHAR2(2000)         null    ,
    ESTREMI_PROVVEDIMENTO           VARCHAR2(16)           null    ,
    DATA_PROVVEDIMENTO              DATE                   null    ,
    ESTREMI_SENTENZA                VARCHAR2(16)           null    ,
    DATA_SENTENZA                   DATE                   null    ,
    DATA_REG                        DATE                   null    ,
    OGPR_OGIM                       NUMBER(10)             null    ,
    IMPOSTA                         NUMBER(15,2)           null    ,
    SANZIONI_1                      NUMBER(15,2)           null    ,
    SANZIONI_2                      NUMBER(15,2)           null    ,
    INTERESSI                       NUMBER(15,2)           null    ,
    RUOLO                           NUMBER(10)             null    ,
    FATTURA                         NUMBER                 null    ,
    SPESE_SPEDIZIONE                NUMBER(15,2)           null    ,
    SPESE_MORA                      NUMBER(15,2)           null    ,
    RURALI                          NUMBER(15,2)           null    ,
    TERRENI_ERARIALE                NUMBER(15,2)           null    ,
    AREE_ERARIALE                   NUMBER(15,2)           null    ,
    ALTRI_ERARIALE                  NUMBER(15,2)           null    ,
    NUM_FABBRICATI_AB               NUMBER(4)              null    ,
    NUM_FABBRICATI_RURALI           NUMBER(4)              null    ,
    NUM_FABBRICATI_ALTRI            NUMBER(4)              null    ,
    TERRENI_COMUNE                  NUMBER(15,2)           null    ,
    AREE_COMUNE                     NUMBER(15,2)           null    ,
    ALTRI_COMUNE                    NUMBER(15,2)           null    ,
    NUM_FABBRICATI_TERRENI          NUMBER(4)              null    ,
    NUM_FABBRICATI_AREE             NUMBER(4)              null    ,
    FABBRICATI_D                    NUMBER(15,2)           null    ,
    FABBRICATI_D_ERARIALE           NUMBER(15,2)           null    ,
    FABBRICATI_D_COMUNE             NUMBER(15,2)           null    ,
    NUM_FABBRICATI_D                NUMBER(4)              null    ,
    RURALI_ERARIALE                 NUMBER(15,2)           null    ,
    RURALI_COMUNE                   NUMBER(15,2)           null    ,
    MAGGIORAZIONE_TARES             NUMBER(15,2)           null    ,
    ID_COMPENSAZIONE                NUMBER(10)             null    ,
    DOCUMENTO_ID                    NUMBER(10)             null    ,
    FABBRICATI_MERCE                NUMBER(15,2)           null    ,
    NUM_FABBRICATI_MERCE            NUMBER(4)              null    ,
    SERVIZIO                        VARCHAR2(64)           null    ,
    IDBACK                          VARCHAR2(4000)         null    ,
    ADDIZIONALE_PRO                 NUMBER(15,2)           null    ,
    SANZIONI_ADD_PRO                NUMBER(15,2)           null    ,
    INTERESSI_ADD_PRO               NUMBER(15,2)           null    ,
    constraint VERSAMENTI_PK primary key (COD_FISCALE, ANNO, TIPO_TRIBUTO, SEQUENZA)
        using index
)
/

comment on table VERSAMENTI is 'VERS - Versamenti'
/

-- ============================================================
--   Index: VERS_TITR_ANNO_IK
-- ============================================================
create index VERS_TITR_ANNO_IK on VERSAMENTI (TIPO_TRIBUTO asc, ANNO asc)
/

-- ============================================================
--   Index: VERS_BOLL_IK
-- ============================================================
create index VERS_BOLL_IK on VERSAMENTI (NUM_BOLLETTINO asc)
/

-- ============================================================
--   Index: VERS_CONT_FK
-- ============================================================
create index VERS_CONT_FK on VERSAMENTI (COD_FISCALE asc)
/

-- ============================================================
--   Index: VERS_FONT_FK
-- ============================================================
create index VERS_FONT_FK on VERSAMENTI (FONTE asc)
/

-- ============================================================
--   Index: VERS_PRTR_FK
-- ============================================================
create index VERS_PRTR_FK on VERSAMENTI (PRATICA asc)
/

-- ============================================================
--   Index: VERS_OGIM_FK
-- ============================================================
create index VERS_OGIM_FK on VERSAMENTI (OGGETTO_IMPOSTA asc)
/

-- ============================================================
--   Index: VERS_RAIM_FK
-- ============================================================
create index VERS_RAIM_FK on VERSAMENTI (RATA_IMPOSTA asc)
/

-- ============================================================
--   Index: VERS_TITR_FK
-- ============================================================
create index VERS_TITR_FK on VERSAMENTI (TIPO_TRIBUTO asc)
/

-- ============================================================
--   Index: VERS_RUOL_FK
-- ============================================================
create index VERS_RUOL_FK on VERSAMENTI (RUOLO asc)
/

-- ============================================================
--   Index: VERS_FATT_FK
-- ============================================================
create index VERS_FATT_FK on VERSAMENTI (FATTURA asc)
/

-- ============================================================
--   Index: VERS_COMP_FK
-- ============================================================
create index VERS_COMP_FK on VERSAMENTI (ID_COMPENSAZIONE asc)
/

-- ============================================================
--   Index: VERS_DOCA_FK
-- ============================================================
create index VERS_DOCA_FK on VERSAMENTI (DOCUMENTO_ID asc)
/

-- ============================================================
--   Index: VERS_SERVIZIO_IDBACK_IK
-- ============================================================
create index VERS_SERVIZIO_IDBACK_IK on VERSAMENTI (SERVIZIO asc, IDBACK asc)
/

-- ============================================================
--   Table: DENOMINAZIONI_VIA
-- ============================================================
create table DENOMINAZIONI_VIA
(
    COD_VIA                         NUMBER(6)              not null,
    PROGR_VIA                       NUMBER(2)              not null,
    DESCRIZIONE                     VARCHAR2(60)           null    ,
    constraint DENOMINAZIONI_VIA_PK primary key (COD_VIA, PROGR_VIA)
)
/

comment on table DENOMINAZIONI_VIA is 'DEVI - Denominazioni Vie'
/

-- ============================================================
--   Index: DEVI_DESC_IK
-- ============================================================
create index DEVI_DESC_IK on DENOMINAZIONI_VIA (DESCRIZIONE asc)
/

-- ============================================================
--   Index: DEVI_ARVI_FK
-- ============================================================
create index DEVI_ARVI_FK on DENOMINAZIONI_VIA (COD_VIA asc)
/

-- ============================================================
--   Table: INTERESSI
-- ============================================================
create table INTERESSI
(
    TIPO_TRIBUTO                    VARCHAR2(5)            not null,
    SEQUENZA                        NUMBER(4)              not null,
    DATA_INIZIO                     DATE                   not null,
    DATA_FINE                       DATE                   not null,
    ALIQUOTA                        NUMBER(6,4)            not null,
    TIPO_INTERESSE                  VARCHAR2(1)            default 'S' not null
        constraint INTERESSI_TIPO_INTERESS_CC check (
            TIPO_INTERESSE in ('G','L','S','R','D')),
    constraint INTERESSI_PK primary key (TIPO_TRIBUTO, SEQUENZA)
)
/

comment on table INTERESSI is 'Interessi'
/

-- ============================================================
--   Index: INTE_TITR_FK
-- ============================================================
create index INTE_TITR_FK on INTERESSI (TIPO_TRIBUTO asc)
/

-- ============================================================
--   Table: ANOMALIE_ICI
-- ============================================================
create table ANOMALIE_ICI
(
    ANOMALIA                        NUMBER(10)             not null,
    ANNO                            NUMBER(4)              not null,
    TIPO_ANOMALIA                   NUMBER(2)              not null,
    COD_FISCALE                     VARCHAR2(16)           null    ,
    OGGETTO                         NUMBER(10)             null
        constraint ANOMALIE_ICI_OGGETTO_CC check (
            OGGETTO is null or (OGGETTO >= 0
            )),
    FLAG_OK                         VARCHAR2(1)            null
        constraint ANOMALIE_ICI_FLAG_OK_CC check (
            FLAG_OK is null or (FLAG_OK in ('S'))),
    DATA_VARIAZIONE                 DATE                   null    ,
    NOTE                            VARCHAR2(2000)         null    ,
    constraint ANOMALIE_ICI_PK primary key (ANOMALIA)
)
/

comment on table ANOMALIE_ICI is 'ANIC - Anomalie ICI'
/

-- ============================================================
--   Index: ANIC_TIAN_FK
-- ============================================================
create index ANIC_TIAN_FK on ANOMALIE_ICI (TIPO_ANOMALIA asc)
/

-- ============================================================
--   Index: ANIC_OGGE_FK
-- ============================================================
create index ANIC_OGGE_FK on ANOMALIE_ICI (OGGETTO asc)
/

-- ============================================================
--   Index: ANIC_CONT_FK
-- ============================================================
create index ANIC_CONT_FK on ANOMALIE_ICI (COD_FISCALE asc)
/

-- ============================================================
--   Table: ANOMALIE_ANNO
-- ============================================================
create table ANOMALIE_ANNO
(
    TIPO_ANOMALIA                   NUMBER(2)              not null,
    ANNO                            NUMBER(4)              not null,
    DATA_ELABORAZIONE               DATE                   not null,
    SCARTO                          NUMBER(9,3)            null    ,
    constraint ANOMALIE_ANNO_PK primary key (TIPO_ANOMALIA, ANNO)
)
/

comment on table ANOMALIE_ANNO is 'ANAN - Anomalie per anno'
/

-- ============================================================
--   Index: ANAN_TIAN_FK
-- ============================================================
create index ANAN_TIAN_FK on ANOMALIE_ANNO (TIPO_ANOMALIA asc)
/

-- ============================================================
--   Table: CONTATTI_CONTRIBUENTE
-- ============================================================
create table CONTATTI_CONTRIBUENTE
(
    COD_FISCALE                     VARCHAR2(16)           not null,
    SEQUENZA                        NUMBER(4)              not null,
    DATA                            DATE                   not null,
    NUMERO                          NUMBER(8)              null    ,
    ANNO                            NUMBER(4)              null    ,
    TIPO_CONTATTO                   NUMBER(2)              null    ,
    TIPO_RICHIEDENTE                NUMBER(2)              null    ,
    TESTO                           VARCHAR2(2000)         null    ,
    TIPO_TRIBUTO                    VARCHAR2(5)            null    ,
    PRATICA_K                       NUMBER(10)             null    ,
    constraint CONTATTI_CONTRIBUENTE_PK primary key (COD_FISCALE, SEQUENZA)
)
/

comment on table CONTATTI_CONTRIBUENTE is 'COCO - Contatti Contribuente'
/

-- ============================================================
--   Index: COCO_TICO_FK
-- ============================================================
create index COCO_TICO_FK on CONTATTI_CONTRIBUENTE (TIPO_CONTATTO asc)
/

-- ============================================================
--   Index: COCO_TIRI_FK
-- ============================================================
create index COCO_TIRI_FK on CONTATTI_CONTRIBUENTE (TIPO_RICHIEDENTE asc)
/

-- ============================================================
--   Index: COCO_TITR_FK
-- ============================================================
create index COCO_TITR_FK on CONTATTI_CONTRIBUENTE (TIPO_TRIBUTO asc)
/

-- ============================================================
--   Index: COCO_PRATICA_K_IK
-- ============================================================
create index COCO_PRATICA_K_IK on CONTATTI_CONTRIBUENTE (PRATICA_K asc)
/

-- ============================================================
--   Table: PARTIZIONI_OGGETTO_PRATICA
-- ============================================================
create table PARTIZIONI_OGGETTO_PRATICA
(
    OGGETTO_PRATICA                 NUMBER(10)             not null,
    SEQUENZA                        NUMBER(4)              not null,
    TIPO_AREA                       NUMBER(2)              not null,
    NUMERO                          NUMBER(2)              null    ,
    CONSISTENZA_REALE               NUMBER(8,2)            not null,
    CONSISTENZA                     NUMBER(8,2)            not null,
    FLAG_ESENZIONE                  VARCHAR2(1)            null
        constraint PARTIZIONI_OP_FLAG_ESENZION_CC check (
            FLAG_ESENZIONE is null or (FLAG_ESENZIONE in ('S'))),
    NOTE                            VARCHAR2(2000)         null    ,
    constraint PARTIZIONI_OGGETTO_PRATICA_PK primary key (OGGETTO_PRATICA, SEQUENZA)
)
/

comment on table PARTIZIONI_OGGETTO_PRATICA is 'POPR - Partizioni Oggetto Pratica'
/

-- ============================================================
--   Index: POPR_OGPR_FK
-- ============================================================
create index POPR_OGPR_FK on PARTIZIONI_OGGETTO_PRATICA (OGGETTO_PRATICA asc)
/

-- ============================================================
--   Index: POPR_TIAR_FK
-- ============================================================
create index POPR_TIAR_FK on PARTIZIONI_OGGETTO_PRATICA (TIPO_AREA asc)
/

-- ============================================================
--   Table: CONSISTENZE_TRIBUTO
-- ============================================================
create table CONSISTENZE_TRIBUTO
(
    TIPO_TRIBUTO                    VARCHAR2(5)            not null,
    OGGETTO                         NUMBER(10)             not null
        constraint CONSISTENZE_T_OGGETTO_CC check (
            OGGETTO >= 0),
    SEQUENZA                        NUMBER(4)              not null,
    CONSISTENZA                     NUMBER(8,2)            not null,
    FLAG_ESENZIONE                  VARCHAR2(1)            null
        constraint CONSISTENZE_T_FLAG_ESENZION_CC check (
            FLAG_ESENZIONE is null or (FLAG_ESENZIONE in ('S'))),
    constraint CONSISTENZE_TRIBUTO_PK primary key (TIPO_TRIBUTO, OGGETTO, SEQUENZA)
)
/

comment on table CONSISTENZE_TRIBUTO is 'COTR - Consistenze Tributo'
/

-- ============================================================
--   Table: MOTIVI_PRATICA
-- ============================================================
create table MOTIVI_PRATICA
(
    TIPO_TRIBUTO                    VARCHAR2(5)            not null,
    SEQUENZA                        NUMBER(4)              not null,
    ANNO                            NUMBER(4)              null    ,
    TIPO_PRATICA                    VARCHAR2(1)            null
        constraint MOTIVI_PRATIC_TIPO_PRATICA_CC check (
            TIPO_PRATICA is null or (TIPO_PRATICA in ('A','D','L','I','C','K','T','V','G','S'))),
    MOTIVO                          VARCHAR2(2000)         not null,
    constraint MOTIVI_PRATICA_PK primary key (TIPO_TRIBUTO, SEQUENZA)
)
/

comment on table MOTIVI_PRATICA is 'MOPR - Motivi Pratica'
/

-- ============================================================
--   Index: MOPR_TITR_FK
-- ============================================================
create index MOPR_TITR_FK on MOTIVI_PRATICA (TIPO_TRIBUTO asc)
/

-- ============================================================
--   Table: FAMILIARI_PRATICA
-- ============================================================
create table FAMILIARI_PRATICA
(
    PRATICA                         NUMBER(10)             not null,
    NI                              NUMBER(10)             not null,
    RAPPORTO_PAR                    VARCHAR2(2)            null    ,
    constraint FAMILIARI_PRATICA_PK primary key (PRATICA, NI)
)
/

comment on table FAMILIARI_PRATICA is 'FAPR - Familiari in Pratica'
/

-- ============================================================
--   Table: IMPRESE_ARTI_PROFESSIONI
-- ============================================================
create table IMPRESE_ARTI_PROFESSIONI
(
    PRATICA                         NUMBER(10)             not null,
    SEQUENZA                        NUMBER(4)              not null,
    DESCRIZIONE                     VARCHAR2(60)           null    ,
    SETTORE                         NUMBER(2)              null    ,
    constraint IMPRESE_ARTI_PROFESSIONI_PK primary key (PRATICA, SEQUENZA)
)
/

comment on table IMPRESE_ARTI_PROFESSIONI is 'Impresa,Arte,Professione esercitata'
/

-- ============================================================
--   Index: IAPR_PRTR_FK
-- ============================================================
create index IAPR_PRTR_FK on IMPRESE_ARTI_PROFESSIONI (PRATICA asc)
/

-- ============================================================
--   Table: REDDITI_RIFERIMENTO
-- ============================================================
create table REDDITI_RIFERIMENTO
(
    PRATICA                         NUMBER(10)             not null,
    SEQUENZA                        NUMBER(4)              not null,
    REDDITO                         NUMBER(15,2)           null    ,
    TIPO                            VARCHAR2(1)            null
        constraint REDDITI_RIFER_TIPO_CC check (
            TIPO is null or (TIPO in ('I','P','NULL!'))),
    constraint REDDITI_RIFERIMENTO_PK primary key (PRATICA, SEQUENZA)
)
/

comment on table REDDITI_RIFERIMENTO is 'Reddito di Riferimento'
/

-- ============================================================
--   Index: RERI_PRTR_FK
-- ============================================================
create index RERI_PRTR_FK on REDDITI_RIFERIMENTO (PRATICA asc)
/

-- ============================================================
--   Table: ANOMALIE_CONTITOLARI
-- ============================================================
create table ANOMALIE_CONTITOLARI
(
    PROGRESSIVO                     NUMBER(10)             not null,
    ANNO                            NUMBER(4)              not null,
    COD_FISCALE                     VARCHAR2(16)           not null,
    PRATICA                         NUMBER(10)             not null,
    NUM_ORDINE                      VARCHAR2(5)            null    ,
    INDIRIZZO                       VARCHAR2(40)           null    ,
    COMUNE                          VARCHAR2(60)           null    ,
    SIGLA_PROVINCIA                 VARCHAR2(2)            null    ,
    PERC_POSSESSO                   NUMBER(5,2)            null    ,
    MESI_POSSESSO                   NUMBER(2)              null    ,
    DETRAZIONE                      NUMBER(15,2)           null    ,
    MESI_ALIQUOTA_RIDOTTA           NUMBER(2)              null    ,
    FLAG_POSSESSO                   VARCHAR2(1)            null    ,
    FLAG_ESCLUSIONE                 VARCHAR2(1)            null    ,
    FLAG_RIDUZIONE                  VARCHAR2(1)            null    ,
    FLAG_AB_PRINCIPALE              VARCHAR2(1)            null    ,
    FLAG_AL_RIDOTTA                 VARCHAR2(1)            null    ,
    constraint ANOMALIE_CONTITOLARI_PK primary key (PROGRESSIVO)
)
/

comment on table ANOMALIE_CONTITOLARI is 'ANCO - Anomalie Contitolari'
/

-- ============================================================
--   Index: ANCO_PRTR_FK
-- ============================================================
create index ANCO_PRTR_FK on ANOMALIE_CONTITOLARI (PRATICA asc)
/

-- ============================================================
--   Table: WRK_TRASMISSIONE_RUOLO
-- ============================================================
create table WRK_TRASMISSIONE_RUOLO
(
    RUOLO                           NUMBER                 not null,
    PROGRESSIVO                     NUMBER                 not null,
    DATI                            VARCHAR2(2000)         null    ,
    constraint WRK_TRASMISSIONE_RUOLO_PK primary key (RUOLO, PROGRESSIVO)
)
/

comment on table WRK_TRASMISSIONE_RUOLO is 'Tabella di lavoro per la trasmissione del ruolo'
/

-- ============================================================
--   Table: COEFFICIENTI_NON_DOMESTICI
-- ============================================================
create table COEFFICIENTI_NON_DOMESTICI
(
    TRIBUTO                         NUMBER(4)              not null,
    CATEGORIA                       NUMBER(4)              not null,
    ANNO                            NUMBER(4)              not null,
    COEFF_POTENZIALE                NUMBER(6,4)            not null,
    COEFF_PRODUZIONE                NUMBER(6,4)            not null,
    constraint COEFFICIENTI_NON_DOMESTICI_PK primary key (TRIBUTO, CATEGORIA, ANNO)
)
/

comment on table COEFFICIENTI_NON_DOMESTICI is 'COND - Coefficienti Non Domestici'
/

-- ============================================================
--   Index: COND_ANNO_IK
-- ============================================================
create index COND_ANNO_IK on COEFFICIENTI_NON_DOMESTICI (ANNO asc)
/

-- ============================================================
--   Table: FAMILIARI_SOGGETTO
-- ============================================================
create table FAMILIARI_SOGGETTO
(
    NI                              NUMBER(10)             not null,
    ANNO                            NUMBER(4)              not null,
    DAL                             DATE                   not null,
    AL                              DATE                   null    ,
    NUMERO_FAMILIARI                NUMBER(4)              not null,
    DATA_VARIAZIONE                 DATE                   not null,
    NOTE                            VARCHAR2(2000)         null    ,
    constraint FAMILIARI_SOGGETTO_PK primary key (NI, ANNO, DAL)
        using index
)
/

comment on table FAMILIARI_SOGGETTO is 'FASO - Familiari Soggetto'
/

-- ============================================================
--   Table: TERRENI_RIDOTTI
-- ============================================================
create table TERRENI_RIDOTTI
(
    COD_FISCALE                     VARCHAR2(16)           not null,
    ANNO                            NUMBER(4)              not null,
    VALORE                          NUMBER(15,2)           not null
        constraint TERRENI_RIDOT_VALORE_CC check (
            VALORE >= 0),
    NOTE                            VARCHAR2(2000)         null    ,
    constraint TERRENI_RIDOTTI_PK primary key (COD_FISCALE, ANNO)
)
/

comment on table TERRENI_RIDOTTI is 'TERI - Terreni Ridotti'
/

-- ============================================================
--   Index: TERI_CONT_FK
-- ============================================================
create index TERI_CONT_FK on TERRENI_RIDOTTI (COD_FISCALE asc)
/

-- ============================================================
--   Table: DELEGHE_BANCARIE
-- ============================================================
create table DELEGHE_BANCARIE
(
    COD_FISCALE                     VARCHAR2(16)           not null,
    TIPO_TRIBUTO                    VARCHAR2(5)            not null,
    COD_ABI                         NUMBER(5)              null    ,
    COD_CAB                         NUMBER(5)              null    ,
    CONTO_CORRENTE                  VARCHAR2(12)           null    ,
    COD_CONTROLLO_CC                VARCHAR2(1)            null    ,
    UTENTE                          VARCHAR2(8)            null    ,
    DATA_VARIAZIONE                 DATE                   not null,
    NOTE                            VARCHAR2(2000)         null    ,
    CODICE_FISCALE_INT              VARCHAR2(16)           null    ,
    COGNOME_NOME_INT                VARCHAR2(60)           null    ,
    FLAG_DELEGA_CESSATA             VARCHAR2(1)            null
        constraint DELEGHE_BANCA_FLAG_DELEGA_C_CC check (
            FLAG_DELEGA_CESSATA is null or (FLAG_DELEGA_CESSATA in ('S'))),
    DATA_RITIRO_DELEGA              DATE                   null    ,
    FLAG_RATA_UNICA                 VARCHAR2(1)            null
        constraint DELEGHE_BANCA_FLAG_RATA_UNI_CC check (
            FLAG_RATA_UNICA is null or (FLAG_RATA_UNICA in ('S'))),
    CIN_BANCARIO                    VARCHAR2(1)            null    ,
    IBAN_PAESE                      VARCHAR2(2)            null    ,
    IBAN_CIN_EUROPA                 NUMBER(2)              null    ,
    constraint DELEGHE_BANCARIE_PK primary key (COD_FISCALE, TIPO_TRIBUTO)
)
/

comment on table DELEGHE_BANCARIE is 'DEBA - Deleghe Bancarie'
/

-- ============================================================
--   Index: DEBA_CONT_FK
-- ============================================================
create index DEBA_CONT_FK on DELEGHE_BANCARIE (COD_FISCALE asc)
/

-- ============================================================
--   Index: DEBA_TITR_FK
-- ============================================================
create index DEBA_TITR_FK on DELEGHE_BANCARIE (TIPO_TRIBUTO asc)
/

-- ============================================================
--   Table: COSTI_STORICI
-- ============================================================
create table COSTI_STORICI
(
    OGGETTO_PRATICA                 NUMBER(10)             not null,
    ANNO                            NUMBER(4)              not null,
    COSTO                           NUMBER(15,2)           null    ,
    UTENTE                          VARCHAR2(8)            null    ,
    DATA_VARIAZIONE                 DATE                   null    ,
    NOTE                            VARCHAR2(2000)         null    ,
    constraint COSTI_STORICI_PK primary key (OGGETTO_PRATICA, ANNO)
)
/

comment on table COSTI_STORICI is 'COST - Costi Storici'
/

-- ============================================================
--   Table: DETRAZIONI_OGCO
-- ============================================================
create table DETRAZIONI_OGCO
(
    COD_FISCALE                     VARCHAR2(16)           not null,
    OGGETTO_PRATICA                 NUMBER(10)             not null,
    ANNO                            NUMBER(4)              not null,
    TIPO_TRIBUTO                    VARCHAR2(5)            null    ,
    MOTIVO_DETRAZIONE               NUMBER(2)              null    ,
    DETRAZIONE                      NUMBER(15,2)           null
        constraint DETRAZIONI_OG_DETRAZIONE_CC check (
            DETRAZIONE is null or (DETRAZIONE >= 0
            )),
    NOTE                            VARCHAR2(2000)         null    ,
    DETRAZIONE_ACCONTO              NUMBER(15,2)           null    ,
    constraint DETRAZIONI_OGCO_PK primary key (COD_FISCALE, OGGETTO_PRATICA, ANNO)
)
/

comment on table DETRAZIONI_OGCO is 'DEOG - Detrazioni relative agli anni per gli oggetti di una pratica e contribuente'
/

-- ============================================================
--   Index: DEOG_MODE_FK
-- ============================================================
create index DEOG_MODE_FK on DETRAZIONI_OGCO (TIPO_TRIBUTO asc, MOTIVO_DETRAZIONE asc)
/

-- ============================================================
--   Index: DEOG_OGCO_FK
-- ============================================================
create index DEOG_OGCO_FK on DETRAZIONI_OGCO (COD_FISCALE asc, OGGETTO_PRATICA asc)
/

-- ============================================================
--   Table: ALIQUOTE_OGCO
-- ============================================================
create table ALIQUOTE_OGCO
(
    COD_FISCALE                     VARCHAR2(16)           not null,
    OGGETTO_PRATICA                 NUMBER(10)             not null,
    DAL                             DATE                   not null,
    AL                              DATE                   not null,
    TIPO_TRIBUTO                    VARCHAR2(5)            not null,
    TIPO_ALIQUOTA                   NUMBER(2)              not null,
    NOTE                            VARCHAR2(2000)         null    ,
    constraint ALIQUOTE_OGCO_PK primary key (COD_FISCALE, OGGETTO_PRATICA, DAL)
)
/

comment on table ALIQUOTE_OGCO is 'ALOG - Aliquote relative agli anni per gli oggetti di una pratica e contribuente'
/

-- ============================================================
--   Index: ALOG_TIAL_FK
-- ============================================================
create index ALOG_TIAL_FK on ALIQUOTE_OGCO (TIPO_TRIBUTO asc, TIPO_ALIQUOTA asc)
/

-- ============================================================
--   Index: ALOG_OGCO_FK
-- ============================================================
create index ALOG_OGCO_FK on ALIQUOTE_OGCO (COD_FISCALE asc, OGGETTO_PRATICA asc)
/

-- ============================================================
--   Table: NOTIFICHE_OGGETTO
-- ============================================================
create table NOTIFICHE_OGGETTO
(
    OGGETTO                         NUMBER(10)             not null,
    COD_FISCALE                     VARCHAR2(16)           not null,
    ANNO_NOTIFICA                   NUMBER(4)              not null,
    PRATICA                         NUMBER(10)             null    ,
    DATA_VARIAZIONE                 DATE                   not null,
    NOTE                            VARCHAR2(2000)         null    ,
    constraint NOTIFICHE_OGGETTO_PK primary key (OGGETTO, COD_FISCALE)
)
/

comment on table NOTIFICHE_OGGETTO is 'NOOG - Notifiche Oggetto'
/

-- ============================================================
--   Index: NOOG_CONT_FK
-- ============================================================
create index NOOG_CONT_FK on NOTIFICHE_OGGETTO (COD_FISCALE asc)
/

-- ============================================================
--   Index: NOOG_PRTR_FK
-- ============================================================
create index NOOG_PRTR_FK on NOTIFICHE_OGGETTO (PRATICA asc)
/

-- ============================================================
--   Table: FAMILIARI_OGIM
-- ============================================================
create table FAMILIARI_OGIM
(
    OGGETTO_IMPOSTA                 NUMBER(10)             not null,
    DAL                             DATE                   not null,
    AL                              DATE                   null    ,
    NUMERO_FAMILIARI                NUMBER(4)              not null,
    DETTAGLIO_FAOG                  VARCHAR2(2000)         null    ,
    DATA_VARIAZIONE                 DATE                   not null,
    NOTE                            VARCHAR2(2000)         null    ,
    DETTAGLIO_FAOG_BASE             VARCHAR2(2000)         null    ,
    constraint FAMILIARI_OGIM_PK primary key (OGGETTO_IMPOSTA, DAL)
        using index
)
/

comment on table FAMILIARI_OGIM is 'FAOG - Familiari OGIM'
/

-- ============================================================
--   Index: FAOG_OGIM_FK
-- ============================================================
create index FAOG_OGIM_FK on FAMILIARI_OGIM (OGGETTO_IMPOSTA asc)
/

-- ============================================================
--   Table: MODELLI_DETTAGLIO
-- ============================================================
create table MODELLI_DETTAGLIO
(
    MODELLO                         NUMBER(4)              not null,
    PARAMETRO_ID                    NUMBER                 not null,
    TESTO                           VARCHAR2(2000)         null    ,
    constraint MODELLI_DETTAGLIO_PK primary key (MODELLO, PARAMETRO_ID)
)
/

comment on table MODELLI_DETTAGLIO is 'MODT - Modelli Dettaglio'
/

-- ============================================================
--   Index: MODT_TIMP_FK
-- ============================================================
create index MODT_TIMP_FK on MODELLI_DETTAGLIO (PARAMETRO_ID asc)
/

-- ============================================================
--   Table: PERIODI_IMPONIBILE
-- ============================================================
create table PERIODI_IMPONIBILE
(
    COD_FISCALE                     VARCHAR2(16)           not null,
    OGGETTO_PRATICA                 NUMBER(10)             not null,
    ANNO                            NUMBER(4)              not null,
    DA_MESE                         NUMBER(2)              not null,
    A_MESE                          NUMBER(2)              not null,
    IMPONIBILE                      NUMBER(15,2)           null    ,
    IMPONIBILE_D                    NUMBER(15,2)           null    ,
    FLAG_RIOG                       VARCHAR2(1)            null
        constraint PERIODI_IMPON_FLAG_RIOG_CC check (
            FLAG_RIOG is null or (FLAG_RIOG in ('S'))),
    UTENTE                          VARCHAR2(8)            null    ,
    DATA_VARIAZIONE                 DATE                   null    ,
    NOTE                            VARCHAR2(2000)         null    ,
    constraint PERIODI_IMPONIBILE_PK primary key (COD_FISCALE, OGGETTO_PRATICA, ANNO, DA_MESE)
)
/

comment on table PERIODI_IMPONIBILE is 'PEIM - Periodi Imponibile'
/

-- ============================================================
--   Index: PEIM_OGCO_FK
-- ============================================================
create index PEIM_OGCO_FK on PERIODI_IMPONIBILE (COD_FISCALE asc, OGGETTO_PRATICA asc)
/

-- ============================================================
--   Table: DETRAZIONI_IMPONIBILE
-- ============================================================
create table DETRAZIONI_IMPONIBILE
(
    COD_FISCALE                     VARCHAR2(16)           not null,
    OGGETTO_PRATICA                 NUMBER(10)             not null,
    ANNO                            NUMBER(4)              not null,
    DA_MESE                         NUMBER(2)              not null,
    A_MESE                          NUMBER(2)              not null,
    IMPONIBILE                      NUMBER(15,2)           null    ,
    IMPONIBILE_D                    NUMBER(15,2)           null    ,
    FLAG_RIOG                       VARCHAR2(1)            null
        constraint DETRAZIONI_IM_FLAG_RIOG_CC check (
            FLAG_RIOG is null or (FLAG_RIOG in ('S'))),
    PERC_DETRAZIONE                 NUMBER(6,2)            null    ,
    DETRAZIONE                      NUMBER(15,2)           null    ,
    DETRAZIONE_ACCONTO              NUMBER(15,2)           null    ,
    DETRAZIONE_D                    NUMBER(15,2)           null    ,
    DETRAZIONE_D_ACCONTO            NUMBER(15,2)           null    ,
    DETRAZIONE_RIMANENTE            NUMBER(15,2)           null    ,
    DETRAZIONE_RIMANENTE_ACCONTO    NUMBER(15,2)           null    ,
    DETRAZIONE_RIMANENTE_D          NUMBER(15,2)           null    ,
    DETRAZIONE_RIMANENTE_D_ACCONTO  NUMBER(15,2)           null    ,
    UTENTE                          VARCHAR2(8)            null    ,
    DATA_VARIAZIONE                 DATE                   null    ,
    NOTE                            VARCHAR2(2000)         null    ,
    constraint DETRAZIONI_IMPONIBILE_PK primary key (COD_FISCALE, OGGETTO_PRATICA, ANNO, DA_MESE)
)
/

comment on table DETRAZIONI_IMPONIBILE is 'DEIM - Detrazioni Imponibile'
/

-- ============================================================
--   Index: DEIM_OGCO_FK
-- ============================================================
create index DEIM_OGCO_FK on DETRAZIONI_IMPONIBILE (COD_FISCALE asc, OGGETTO_PRATICA asc)
/

-- ============================================================
--   Table: COMPENSAZIONI_RUOLO
-- ============================================================
create table COMPENSAZIONI_RUOLO
(
    COD_FISCALE                     VARCHAR2(16)           not null,
    ANNO                            NUMBER(4)              not null,
    RUOLO                           NUMBER(10)             not null,
    OGGETTO_PRATICA                 NUMBER(10)             not null,
    MOTIVO_COMPENSAZIONE            NUMBER(2)              null    ,
    COMPENSAZIONE                   NUMBER(15,2)           null
        constraint COMPENSAZIONI_COMPENSAZIONE_CC check (
            COMPENSAZIONE is null or (COMPENSAZIONE >= 0
            )),
    UTENTE                          VARCHAR2(8)            null    ,
    DATA_VARIAZIONE                 DATE                   null    ,
    NOTE                            VARCHAR2(2000)         null    ,
    FLAG_AUTOMATICO                 VARCHAR2(1)            null
        constraint COMPENSAZIONI_FLAG_AUTOMATI_CC check (
            FLAG_AUTOMATICO is null or (FLAG_AUTOMATICO in ('S'))),
    COMPENSAZIONE_BASE              NUMBER(15,2)           null    ,
    constraint COMPENSAZIONI_RUOLO_PK primary key (COD_FISCALE, ANNO, RUOLO, OGGETTO_PRATICA)
)
/

comment on table COMPENSAZIONI_RUOLO is 'CORU - Compensazioni Ruolo'
/

-- ============================================================
--   Index: CORU_RUOL_FK
-- ============================================================
create index CORU_RUOL_FK on COMPENSAZIONI_RUOLO (RUOLO asc)
/

-- ============================================================
--   Index: CORU_CONT_FK
-- ============================================================
create index CORU_CONT_FK on COMPENSAZIONI_RUOLO (COD_FISCALE asc)
/

-- ============================================================
--   Index: CORU_OGPR_FK
-- ============================================================
create index CORU_OGPR_FK on COMPENSAZIONI_RUOLO (OGGETTO_PRATICA asc)
/

-- ============================================================
--   Index: CORU_MOCO_FK
-- ============================================================
create index CORU_MOCO_FK on COMPENSAZIONI_RUOLO (MOTIVO_COMPENSAZIONE asc)
/

-- ============================================================
--   Table: SPESE_ISTRUTTORIA
-- ============================================================
create table SPESE_ISTRUTTORIA
(
    TIPO_TRIBUTO                    VARCHAR2(5)            not null,
    ANNO                            NUMBER(4)              not null,
    DA_IMPORTO                      NUMBER(10,2)           not null,
    A_IMPORTO                       NUMBER(10,2)           not null,
    SPESE                           NUMBER(6,2)            null    ,
    PERC_INSOLVENZA                 NUMBER(4,2)            null    ,
    constraint SPESE_ISTRUTTORIA_PK primary key (TIPO_TRIBUTO, ANNO, DA_IMPORTO)
)
/

comment on table SPESE_ISTRUTTORIA is 'SPIS - Spese Istruttoria'
/

-- ============================================================
--   Index: SPIS_TITR_FK
-- ============================================================
create index SPIS_TITR_FK on SPESE_ISTRUTTORIA (TIPO_TRIBUTO asc)
/

-- ============================================================
--   Table: ANOMALIE_CARICAMENTO
-- ============================================================
create table ANOMALIE_CARICAMENTO
(
    DOCUMENTO_ID                    NUMBER(10)             not null,
    SEQUENZA                        NUMBER(4)              not null,
    OGGETTO                         NUMBER(10)             null
        constraint ANOMALIE_CARI_OGGETTO_CC check (
            OGGETTO is null or (OGGETTO >= 0
            )),
    DATI_OGGETTO                    VARCHAR2(1000)         null    ,
    COGNOME                         VARCHAR2(60)           null    ,
    NOME                            VARCHAR2(36)           null    ,
    COD_FISCALE                     VARCHAR2(16)           null    ,
    DESCRIZIONE                     VARCHAR2(100)          null    ,
    NOTE                            VARCHAR2(2000)         null    ,
    constraint ANOMALIE_CARICAMENTO_PK primary key (DOCUMENTO_ID, SEQUENZA)
)
/

comment on table ANOMALIE_CARICAMENTO is 'ANOMALIE_CARICAMENTO'
/

-- ============================================================
--   Index: ANCA_DOCA_FK
-- ============================================================
create index ANCA_DOCA_FK on ANOMALIE_CARICAMENTO (DOCUMENTO_ID asc)
/

-- ============================================================
--   Index: ANCA_OGGE_FK
-- ============================================================
create index ANCA_OGGE_FK on ANOMALIE_CARICAMENTO (OGGETTO asc)
/

-- ============================================================
--   Table: ATTRIBUTI_OGCO
-- ============================================================
create table ATTRIBUTI_OGCO
(
    COD_FISCALE                     VARCHAR2(16)           not null,
    OGGETTO_PRATICA                 NUMBER(10)             not null,
    DOCUMENTO_ID                    NUMBER(10)             null    ,
    NUMERO_NOTA                     VARCHAR2(15)           null    ,
    ESITO_NOTA                      NUMBER(1)              null    ,
    DATA_REG_ATTI                   DATE                   null    ,
    NUMERO_REPERTORIO               VARCHAR2(15)           null    ,
    COD_ATTO                        NUMBER(4)              null    ,
    ROGANTE                         VARCHAR2(60)           null    ,
    COD_FISCALE_ROGANTE             VARCHAR2(16)           null    ,
    SEDE_ROGANTE                    VARCHAR2(4)            null    ,
    COD_DIRITTO                     VARCHAR2(4)            null    ,
    REGIME                          VARCHAR2(2)            null    ,
    COD_ESITO                       VARCHAR2(4)            null    ,
    UTENTE                          VARCHAR2(8)            not null,
    DATA_VARIAZIONE                 DATE                   not null,
    NOTE                            VARCHAR2(2000)         null    ,
    DATA_VALIDITA_ATTO              DATE                   null    ,
    ID_COMUNE                       NUMBER(10)             null    ,
    constraint ATTRIBUTI_OGCO_PK primary key (COD_FISCALE, OGGETTO_PRATICA)
)
/

comment on table ATTRIBUTI_OGCO is 'ATOG - Attributi OGCO'
/

-- ============================================================
--   Index: ATOG_CODI_FK
-- ============================================================
create index ATOG_CODI_FK on ATTRIBUTI_OGCO (COD_DIRITTO asc)
/

-- ============================================================
--   Index: ATOG_DOCA_FK
-- ============================================================
create index ATOG_DOCA_FK on ATTRIBUTI_OGCO (DOCUMENTO_ID asc)
/

-- ============================================================
--   Table: ALIQUOTE_CATEGORIA
-- ============================================================
create table ALIQUOTE_CATEGORIA
(
    TIPO_TRIBUTO                    VARCHAR2(5)            not null,
    ANNO                            NUMBER(4)              not null,
    TIPO_ALIQUOTA                   NUMBER(2)              not null,
    CATEGORIA_CATASTO               VARCHAR2(3)            not null,
    ALIQUOTA                        NUMBER(6,2)            not null,
    NOTE                            VARCHAR2(2000)         null    ,
    ALIQUOTA_BASE                   NUMBER(6,2)            null    ,
    constraint ALIQUOTE_CATEGORIA_PK primary key (TIPO_TRIBUTO, ANNO, TIPO_ALIQUOTA, CATEGORIA_CATASTO)
)
/

comment on table ALIQUOTE_CATEGORIA is 'Aliquote Categoria'
/

-- ============================================================
--   Index: ALCA_ALIQ_FK
-- ============================================================
create index ALCA_ALIQ_FK on ALIQUOTE_CATEGORIA (TIPO_TRIBUTO asc, ANNO asc, TIPO_ALIQUOTA asc)
/

-- ============================================================
--   Index: ALCA_CACA_FK
-- ============================================================
create index ALCA_CACA_FK on ALIQUOTE_CATEGORIA (CATEGORIA_CATASTO asc)
/

-- ============================================================
--   Table: ALLINEAMENTO_DELEGHE
-- ============================================================
create table ALLINEAMENTO_DELEGHE
(
    COD_FISCALE                     VARCHAR2(16)           not null,
    TIPO_TRIBUTO                    VARCHAR2(5)            not null,
    COD_ABI                         NUMBER(5)              null    ,
    COD_CAB                         NUMBER(5)              null    ,
    CONTO_CORRENTE                  VARCHAR2(12)           null    ,
    COD_CONTROLLO_CC                VARCHAR2(1)            null    ,
    CIN_BANCARIO                    VARCHAR2(1)            null    ,
    IBAN_PAESE                      VARCHAR2(2)            null    ,
    IBAN_CIN_EUROPA                 NUMBER(2)              null    ,
    STATO                           VARCHAR2(10)           null    ,
    DATA_INVIO                      DATE                   null    ,
    UTENTE                          VARCHAR2(8)            null    ,
    DATA_VARIAZIONE                 DATE                   null    ,
    NOTE                            VARCHAR2(2000)         null    ,
    CODICE_FISCALE_INT              VARCHAR2(16)           null    ,
    COGNOME_NOME_INT                VARCHAR2(60)           null    ,
    constraint ALLINEAMENTO_DELEGHE_PK primary key (COD_FISCALE, TIPO_TRIBUTO)
)
/

comment on table ALLINEAMENTO_DELEGHE is 'ALDE - Allineamento Deleghe'
/

-- ============================================================
--   Index: ALDE_CONT_FK
-- ============================================================
create index ALDE_CONT_FK on ALLINEAMENTO_DELEGHE (COD_FISCALE asc)
/

-- ============================================================
--   Index: ALDE_TITR_FK
-- ============================================================
create index ALDE_TITR_FK on ALLINEAMENTO_DELEGHE (TIPO_TRIBUTO asc)
/

-- ============================================================
--   Table: SUCCESSIONI_DEVOLUZIONI
-- ============================================================
create table SUCCESSIONI_DEVOLUZIONI
(
    SUCCESSIONE                     NUMBER(10)             not null,
    PROGRESSIVO                     NUMBER(5)              not null,
    PROGR_IMMOBILE                  NUMBER(3)              not null,
    PROGR_EREDE                     NUMBER(3)              not null,
    NUMERATORE_QUOTA                NUMBER(7)              null    ,
    DENOMINATORE_QUOTA              NUMBER(7)              null    ,
    AGEVOLAZIONE_PRIMA_CASA         NUMBER(1)              null    ,
    constraint SUCCESSIONI_DEVOLUZIONI_PK primary key (SUCCESSIONE, PROGRESSIVO)
)
/

comment on table SUCCESSIONI_DEVOLUZIONI is 'SUDV - Successioni Devoluzioni'
/

-- ============================================================
--   Index: SUDV_SUDE_FK
-- ============================================================
create index SUDV_SUDE_FK on SUCCESSIONI_DEVOLUZIONI (SUCCESSIONE asc)
/

-- ============================================================
--   Table: SUCCESSIONI_IMMOBILI
-- ============================================================
create table SUCCESSIONI_IMMOBILI
(
    SUCCESSIONE                     NUMBER(10)             not null,
    PROGRESSIVO                     NUMBER(5)              not null,
    PROGR_IMMOBILE                  NUMBER(3)              not null,
    NUMERATORE_QUOTA_DEF            NUMBER(10,3)           null    ,
    DENOMINATORE_QUOTA_DEF          NUMBER(6)              null    ,
    DIRITTO                         VARCHAR2(2)            null    ,
    PROGR_PARTICELLA                NUMBER(3)              null    ,
    CATASTO                         VARCHAR2(2)            null    ,
    SEZIONE                         VARCHAR2(2)            null    ,
    FOGLIO                          VARCHAR2(4)            null    ,
    PARTICELLA_1                    VARCHAR2(5)            null    ,
    PARTICELLA_2                    VARCHAR2(2)            null    ,
    SUBALTERNO_1                    NUMBER(3)              null    ,
    SUBALTERNO_2                    VARCHAR2(1)            null    ,
    DENUNCIA_1                      VARCHAR2(7)            null    ,
    DENUNCIA_2                      VARCHAR2(3)            null    ,
    ANNO_DENUNCIA                   NUMBER(4)              null    ,
    NATURA                          VARCHAR2(3)            null    ,
    SUPERFICIE_ETTARI               NUMBER(5)              null    ,
    SUPERFICIE_MQ                   NUMBER(7,3)            null    ,
    VANI                            NUMBER(4,1)            null    ,
    INDIRIZZO                       VARCHAR2(40)           null    ,
    OGGETTO                         NUMBER(10)             null    ,
    VALORE                          NUMBER(15,2)           null    ,
    constraint SUCCESSIONI_IMMOBILI_PK primary key (SUCCESSIONE, PROGRESSIVO)
)
/

comment on table SUCCESSIONI_IMMOBILI is 'SUIM - Successioni Immobili'
/

-- ============================================================
--   Index: SUIM_SUDE_FK
-- ============================================================
create index SUIM_SUDE_FK on SUCCESSIONI_IMMOBILI (SUCCESSIONE asc)
/

-- ============================================================
--   Index: SUIM_OGGE_FK
-- ============================================================
create index SUIM_OGGE_FK on SUCCESSIONI_IMMOBILI (OGGETTO asc)
/

-- ============================================================
--   Table: RID_IMPAGATI
-- ============================================================
create table RID_IMPAGATI
(
    DOCUMENTO_ID                    NUMBER(10)             not null,
    FATTURA                         NUMBER                 not null,
    RUOLO                           NUMBER(10)             not null,
    COD_FISCALE                     VARCHAR2(16)           not null,
    ANNO                            NUMBER(4)              null    ,
    TIPO_TRIBUTO                    VARCHAR2(5)            null    ,
    IMPORTO_IMPAGATO                NUMBER(15,2)           null    ,
    CAUSALE                         VARCHAR2(100)          null    ,
    CAUSALE_STORNO                  VARCHAR2(100)          null    ,
    UTENTE                          VARCHAR2(8)            not null,
    DATA_VARIAZIONE                 DATE                   not null,
    NOTE                            VARCHAR2(2000)         null    ,
    constraint RID_IMPAGATI_PK primary key (DOCUMENTO_ID, FATTURA)
)
/

comment on table RID_IMPAGATI is 'RIIM - RID Impagati'
/

-- ============================================================
--   Index: RIIM_TITR_FK
-- ============================================================
create index RIIM_TITR_FK on RID_IMPAGATI (TIPO_TRIBUTO asc)
/

-- ============================================================
--   Index: RIIM_FATT_FK
-- ============================================================
create index RIIM_FATT_FK on RID_IMPAGATI (FATTURA asc)
/

-- ============================================================
--   Index: RIIM_DOCA_FK
-- ============================================================
create index RIIM_DOCA_FK on RID_IMPAGATI (DOCUMENTO_ID asc)
/

-- ============================================================
--   Index: RIIM_RUCO_IK
-- ============================================================
create index RIIM_RUCO_IK on RID_IMPAGATI (RUOLO asc, COD_FISCALE asc)
/

-- ============================================================
--   Table: EXPORT_PERSONALIZZATI
-- ============================================================
create table EXPORT_PERSONALIZZATI
(
    TIPO_EXPORT                     NUMBER(5)              not null,
    CODICE_ISTAT                    VARCHAR2(6)            not null,
    DESCRIZIONE                     VARCHAR2(200)          null    ,
    constraint EXPORT_PERSONALIZZATI_PK primary key (TIPO_EXPORT, CODICE_ISTAT)
)
/

comment on table EXPORT_PERSONALIZZATI is 'EXPE - Export personalizzati'
/

-- ============================================================
--   Index: EXPE_TIEX_FK
-- ============================================================
create index EXPE_TIEX_FK on EXPORT_PERSONALIZZATI (TIPO_EXPORT asc)
/

-- ============================================================
--   Table: PARAMETRI_EXPORT
-- ============================================================
create table PARAMETRI_EXPORT
(
    TIPO_EXPORT                     NUMBER(5)              not null,
    PARAMETRO_EXPORT                NUMBER(2)              not null,
    NOME_PARAMETRO                  VARCHAR2(100)          not null,
    TIPO_PARAMETRO                  VARCHAR2(1)            not null,
    FORMATO_PARAMETRO               VARCHAR2(100)          not null,
    ULTIMO_VALORE                   VARCHAR2(2000)         null    ,
    FLAG_OBBLIGATORIO               VARCHAR2(1)            null    ,
    VALORE_PREDEFINITO              VARCHAR2(2000)         null    ,
    ORDINAMENTO                     NUMBER(2)              null    ,
    FLAG_NON_VISIBILE               VARCHAR2(1)            null    ,
    QUERY_SELEZIONE                 CLOB                   null    ,
    constraint PARAMETRI_EXPORT_PK primary key (TIPO_EXPORT, PARAMETRO_EXPORT)
)
/

comment on table PARAMETRI_EXPORT is 'PAEX - Parametri Export'
/

-- ============================================================
--   Index: PAEX_TIEX_FK
-- ============================================================
create index PAEX_TIEX_FK on PARAMETRI_EXPORT (TIPO_EXPORT asc)
/

-- ============================================================
--   Table: DOCUMENTI_CONTRIBUENTE
-- ============================================================
create table DOCUMENTI_CONTRIBUENTE
(
    COD_FISCALE                     VARCHAR2(16)           not null,
    SEQUENZA                        NUMBER(4)              not null,
    TITOLO                          VARCHAR2(130)          null    ,
    NOME_FILE                       VARCHAR2(255)          null    ,
    DOCUMENTO                       BLOB                   null    ,
    DATA_INSERIMENTO                DATE                   null    ,
    VALIDITA_DAL                    DATE                   null    ,
    VALIDITA_AL                     DATE                   null    ,
    INFORMAZIONI                    VARCHAR2(2000)         null    ,
    UTENTE                          VARCHAR2(8)            null    ,
    DATA_VARIAZIONE                 DATE                   null    ,
    NOTE                            VARCHAR2(2000)         null    ,
    XMLSEND                         CLOB                   null    ,
    XMLRECEIVE                      CLOB                   null    ,
    ID_DOCUMENTO_GDM                NUMBER(10)             null    ,
    ID_RIFERIMENTO                  NUMBER(10)             null    ,
    PRATICA                         NUMBER(10)             null    ,
    RUOLO                           NUMBER(10)             null    ,
    ANNO_PROTOCOLLO                 NUMBER(4)              null    ,
    NUMERO_PROTOCOLLO               NUMBER(10)             null    ,
    DATA_INVIO_PEC                  VARCHAR2(30)           null    ,
    DATA_RICEZIONE_PEC              VARCHAR2(30)           null    ,
    ID_MESSAGGIO                    NUMBER(10)             null    ,
    ID_COMUNICAZIONE_PND            NUMBER(10)             null    ,
    TIPO_CANALE                     NUMBER(2)              null    ,
    DATA_SPEDIZIONE_PND             VARCHAR2(30)           null    ,
    STATO_PND                       VARCHAR2(20)           null    ,
    SEQUENZA_PRINCIPALE             NUMBER(4)              null    ,
    constraint DOCUMENTI_CONTRIBUENTE_PK primary key (COD_FISCALE, SEQUENZA)
)
/

comment on table DOCUMENTI_CONTRIBUENTE is 'DOCO - Documenti Contribuente'
/

CREATE SEQUENCE IDRIF_SQ
  START WITH 1
  MAXVALUE 999999999999999999999999999
  MINVALUE 1
  NOCYCLE
  NOCACHE
  NOORDER
/

-- ============================================================
--   Index: DOCO_CONT_FK
-- ============================================================
create index DOCO_CONT_FK on DOCUMENTI_CONTRIBUENTE (COD_FISCALE asc)
/

-- ============================================================
--   Index: DOCO_PRTR_FK
-- ============================================================
create index DOCO_PRTR_FK on DOCUMENTI_CONTRIBUENTE (PRATICA asc)
/

-- ============================================================
--   Index: DOCO_RUOL_FK
-- ============================================================
create index DOCO_RUOL_FK on DOCUMENTI_CONTRIBUENTE (RUOLO asc)
/

-- ============================================================
--   Index: DOCO_TICA_FK
-- ============================================================
create index DOCO_TICA_FK on DOCUMENTI_CONTRIBUENTE (TIPO_CANALE asc)
/

-- ============================================================
--   Index: DOCO_DOCO2_FK
-- ============================================================
create index DOCO_DOCO2_FK on DOCUMENTI_CONTRIBUENTE (COD_FISCALE asc, SEQUENZA_PRINCIPALE asc)
/

-- ============================================================
--   Table: DETRAZIONI_FIGLI
-- ============================================================
create table DETRAZIONI_FIGLI
(
    COD_FISCALE                     VARCHAR2(16)           not null,
    ANNO                            NUMBER(4)              not null,
    DA_MESE                         NUMBER(2)              not null,
    A_MESE                          NUMBER(2)              null    ,
    NUMERO_FIGLI                    NUMBER(2)              null    ,
    DETRAZIONE                      NUMBER(15,2)           null    ,
    DETRAZIONE_ACCONTO              NUMBER(15,2)           null    ,
    UTENTE                          VARCHAR2(8)            null    ,
    DATA_VARIAZIONE                 DATE                   null    ,
    NOTE                            VARCHAR2(2000)         null    ,
    constraint DETRAZIONI_FIGLI_PK primary key (COD_FISCALE, ANNO, DA_MESE)
)
/

comment on table DETRAZIONI_FIGLI is 'DEFI - Detrazione Figli'
/

-- ============================================================
--   Index: DEFI_CONT_FK
-- ============================================================
create index DEFI_CONT_FK on DETRAZIONI_FIGLI (COD_FISCALE asc)
/

-- ============================================================
--   Table: DETRAZIONI_FIGLI_OGIM
-- ============================================================
create table DETRAZIONI_FIGLI_OGIM
(
    OGGETTO_IMPOSTA                 NUMBER(10)             not null,
    DA_MESE                         NUMBER(2)              not null,
    A_MESE                          NUMBER(2)              null    ,
    NUMERO_FIGLI                    NUMBER(2)              null    ,
    DETRAZIONE                      NUMBER(15,2)           null    ,
    DETRAZIONE_ACCONTO              NUMBER(15,2)           null    ,
    UTENTE                          VARCHAR2(8)            null    ,
    DATA_VARIAZIONE                 DATE                   null    ,
    NOTE                            VARCHAR2(2000)         null    ,
    constraint DETRAZIONI_FIGLI_OGIM_PK primary key (OGGETTO_IMPOSTA, DA_MESE)
)
/

comment on table DETRAZIONI_FIGLI_OGIM is 'DEFO - Detrazioni Figli OGIM'
/

-- ============================================================
--   Index: DEFO_OGIM_FK
-- ============================================================
create index DEFO_OGIM_FK on DETRAZIONI_FIGLI_OGIM (OGGETTO_IMPOSTA asc)
/

-- ============================================================
--   Table: OGGETTI_OGIM
-- ============================================================
create table OGGETTI_OGIM
(
    COD_FISCALE                     VARCHAR2(16)           not null,
    ANNO                            NUMBER(4)              not null,
    OGGETTO_PRATICA                 NUMBER(10)             not null,
    SEQUENZA                        NUMBER(3)              not null,
    TIPO_TRIBUTO                    VARCHAR2(5)            null    ,
    TIPO_ALIQUOTA                   NUMBER(2)              null    ,
    ALIQUOTA                        NUMBER(6,2)            null    ,
    ALIQUOTA_ERARIALE               NUMBER(6,2)            null    ,
    MESI_POSSESSO                   NUMBER(2)              null    ,
    MESI_POSSESSO_1SEM              NUMBER(1)              null    ,
    ALIQUOTA_STD                    NUMBER(6,2)            null    ,
    DA_MESE_POSSESSO                NUMBER(2)              null    ,
    constraint OGGETTI_OGIM_PK primary key (COD_FISCALE, ANNO, OGGETTO_PRATICA, SEQUENZA)
)
/

comment on table OGGETTI_OGIM is 'OGOG - Oggetti OGIM'
/

-- ============================================================
--   Index: OGOG_OGCO_FK
-- ============================================================
create index OGOG_OGCO_FK on OGGETTI_OGIM (COD_FISCALE asc, OGGETTO_PRATICA asc)
/

-- ============================================================
--   Table: COSTI_TARSU
-- ============================================================
create table COSTI_TARSU
(
    ANNO                            NUMBER(4)              not null,
    SEQUENZA                        NUMBER(4)              not null,
    TIPO_COSTO                      VARCHAR2(8)            not null,
    COSTO_FISSO                     NUMBER(15,2)           null    ,
    COSTO_VARIABILE                 NUMBER(15,2)           null    ,
    RAGGRUPPAMENTO                  VARCHAR2(4)            null
        constraint COSTI_TARSU_RAGGRUPPAMENT_CC check (
            RAGGRUPPAMENTO is null or (RAGGRUPPAMENTO in ('CG','CC','CK'))),
    constraint COSTI_TARSU_PK primary key (ANNO, SEQUENZA, TIPO_COSTO)
)
/

comment on table COSTI_TARSU is 'COTA - Costi Tarsu'
/

-- ============================================================
--   Index: COTA_TICS_FK
-- ============================================================
create index COTA_TICS_FK on COSTI_TARSU (TIPO_COSTO asc)
/

-- ============================================================
--   Table: EVENTI_CONTRIBUENTE
-- ============================================================
create table EVENTI_CONTRIBUENTE
(
    COD_FISCALE                     VARCHAR2(16)           not null,
    TIPO_EVENTO                     VARCHAR2(1)            not null,
    SEQUENZA                        NUMBER(4)              not null,
    FLAG_AUTOMATICO                 VARCHAR2(1)            null
        constraint EVENTI_CONTRI_FLAG_AUTOMATI_CC check (
            FLAG_AUTOMATICO is null or (FLAG_AUTOMATICO in ('S'))),
    UTENTE                          VARCHAR2(8)            null    ,
    DATA_VARIAZIONE                 DATE                   null    ,
    NOTE                            VARCHAR2(2000)         null    ,
    constraint EVENTI_CONTRIBUENTE_PK primary key (COD_FISCALE, TIPO_EVENTO, SEQUENZA)
)
/

comment on table EVENTI_CONTRIBUENTE is 'EVCO - Eventi Contribuente'
/

-- ============================================================
--   Index: EVCO_CONT_FK
-- ============================================================
create index EVCO_CONT_FK on EVENTI_CONTRIBUENTE (COD_FISCALE asc)
/

-- ============================================================
--   Index: EVCO_EVEN_FK
-- ============================================================
create index EVCO_EVEN_FK on EVENTI_CONTRIBUENTE (TIPO_EVENTO asc, SEQUENZA asc)
/

-- ============================================================
--   Table: DENUNCE_TASI
-- ============================================================
create table DENUNCE_TASI
(
    PRATICA                         NUMBER(10)             not null,
    DENUNCIA                        NUMBER(7)              not null,
    PREFISSO_TELEFONICO             VARCHAR2(4)            null    ,
    NUM_TELEFONICO                  NUMBER(8)              null    ,
    FLAG_CF                         VARCHAR2(1)            null
        constraint DENUNCE_TASI_FLAG_CF_CC check (
            FLAG_CF is null or (FLAG_CF in ('S'))),
    FLAG_FIRMA                      VARCHAR2(1)            null
        constraint DENUNCE_TASI_FLAG_FIRMA_CC check (
            FLAG_FIRMA is null or (FLAG_FIRMA in ('S'))),
    FLAG_DENUNCIANTE                VARCHAR2(1)            null
        constraint DENUNCE_TASI_FLAG_DENUNCIA_CC check (
            FLAG_DENUNCIANTE is null or (FLAG_DENUNCIANTE in ('S'))),
    PROGR_ANCI                      NUMBER(8)              null    ,
    FONTE                           NUMBER(2)              not null,
    UTENTE                          VARCHAR2(8)            not null,
    DATA_VARIAZIONE                 DATE                   not null,
    NOTE                            VARCHAR2(2000)         null    ,
    constraint DENUNCE_TASI_PK primary key (PRATICA)
        using index
)
/

comment on table DENUNCE_TASI is 'DESI - Denunce TASI'
/

-- ============================================================
--   Index: DESI_FONT_FK
-- ============================================================
create index DESI_FONT_FK on DENUNCE_TASI (FONTE asc)
/

-- ============================================================
--   Table: SUCCESSIONI_TRIBUTO_DEFUNTI
-- ============================================================
create table SUCCESSIONI_TRIBUTO_DEFUNTI
(
    TIPO_TRIBUTO                    VARCHAR2(5)            not null,
    SUCCESSIONE                     NUMBER(10)             not null,
    PRATICA                         NUMBER(10)             null    ,
    STATO_SUCCESSIONE               VARCHAR2(30)           null    ,
    constraint SUCCESSIONI_TRIBUTO_DEFUNTI_PK primary key (TIPO_TRIBUTO, SUCCESSIONE)
)
/

comment on table SUCCESSIONI_TRIBUTO_DEFUNTI is 'SUTD - Successioni Tributo Defunti'
/

-- ============================================================
--   Index: SUTD_TITR_FK
-- ============================================================
create index SUTD_TITR_FK on SUCCESSIONI_TRIBUTO_DEFUNTI (TIPO_TRIBUTO asc)
/

-- ============================================================
--   Index: SUTD_PRTR_FK
-- ============================================================
create index SUTD_PRTR_FK on SUCCESSIONI_TRIBUTO_DEFUNTI (PRATICA asc)
/

-- ============================================================
--   Index: SUTD_SUDE_FK
-- ============================================================
create index SUTD_SUDE_FK on SUCCESSIONI_TRIBUTO_DEFUNTI (SUCCESSIONE asc)
/

-- ============================================================
--   Table: SUCCESSIONI_TRIBUTO_EREDI
-- ============================================================
create table SUCCESSIONI_TRIBUTO_EREDI
(
    TIPO_TRIBUTO                    VARCHAR2(5)            not null,
    SUCCESSIONE                     NUMBER(10)             not null,
    PROGRESSIVO                     NUMBER(5)              not null,
    PRATICA                         NUMBER(10)             null    ,
    constraint SUCCESSIONI_TRIBUTO_EREDI_PK primary key (TIPO_TRIBUTO, SUCCESSIONE, PROGRESSIVO)
)
/

comment on table SUCCESSIONI_TRIBUTO_EREDI is 'SUTE - Successioni Tributo Eredi'
/

-- ============================================================
--   Index: SUTE_SUER_FK
-- ============================================================
create index SUTE_SUER_FK on SUCCESSIONI_TRIBUTO_EREDI (SUCCESSIONE asc, PROGRESSIVO asc)
/

-- ============================================================
--   Index: SUTE_PRTR_FK
-- ============================================================
create index SUTE_PRTR_FK on SUCCESSIONI_TRIBUTO_EREDI (PRATICA asc)
/

-- ============================================================
--   Index: SUTE_TITR_FK
-- ============================================================
create index SUTE_TITR_FK on SUCCESSIONI_TRIBUTO_EREDI (TIPO_TRIBUTO asc)
/

-- ============================================================
--   Table: WRK_DOCFA_SOGGETTI
-- ============================================================
create table WRK_DOCFA_SOGGETTI
(
    DOCUMENTO_ID                    NUMBER(10)             not null,
    DOCUMENTO_MULTI_ID              NUMBER(10)             not null,
    PROGR_OGGETTO                   NUMBER(3)              not null,
    PROGR_SOGGETTO                  NUMBER(3)              not null,
    DENOMINAZIONE                   VARCHAR2(100)          null    ,
    COMUNE_NASCITA                  VARCHAR2(40)           null    ,
    PROVINCIA_NASCITA               VARCHAR2(2)            null    ,
    DATA_NASCITA                    DATE                   null    ,
    SESSO                           VARCHAR2(1)            null    ,
    CODICE_FISCALE                  VARCHAR2(16)           null    ,
    COGNOME                         VARCHAR2(60)           null    ,
    NOME                            VARCHAR2(36)           null    ,
    TIPO                            VARCHAR2(1)            null    ,
    FLAG_CARICAMENTO                VARCHAR2(1)            null    ,
    REGIME                          VARCHAR2(1)            null    ,
    PROGRESSIVO_INT_RIF             NUMBER(3)              null    ,
    SPEC_DIRITTO                    VARCHAR2(50)           null    ,
    PERC_POSSESSO                   NUMBER(5,2)            null    ,
    TITOLO                          VARCHAR2(3)            null    ,
    TR4_NI                          NUMBER(10)             null    ,
    constraint WRK_DOCFA_SOGGETTI_PK primary key (DOCUMENTO_ID, DOCUMENTO_MULTI_ID, PROGR_OGGETTO, PROGR_SOGGETTO)
)
/

comment on table WRK_DOCFA_SOGGETTI is 'WRK_DOCFA_SOGGETTI'
/

-- ============================================================
--   Index: WDSO_WDOG_FK
-- ============================================================
create index WDSO_WDOG_FK on WRK_DOCFA_SOGGETTI (DOCUMENTO_ID asc, DOCUMENTO_MULTI_ID asc, PROGR_OGGETTO asc)
/

-- ============================================================
--   Table: DETRAZIONI_MOBILI
-- ============================================================
create table DETRAZIONI_MOBILI
(
    TIPO_TRIBUTO                    VARCHAR2(5)            not null,
    ANNO                            NUMBER(4)              not null,
    MOTIVO_DETRAZIONE               NUMBER(2)              not null,
    DA_RENDITA                      NUMBER(8,2)            not null,
    A_RENDITA                       NUMBER(8,2)            not null,
    DETRAZIONE                      NUMBER(15,2)           not null,
    constraint DETRAZIONI_MOBILI_PK primary key (TIPO_TRIBUTO, ANNO, MOTIVO_DETRAZIONE, DA_RENDITA)
)
/

comment on table DETRAZIONI_MOBILI is 'DEMO- Detrazioni Mobili'
/

-- ============================================================
--   Index: DEMO_TITR_FK
-- ============================================================
create index DEMO_TITR_FK on DETRAZIONI_MOBILI (TIPO_TRIBUTO asc)
/

-- ============================================================
--   Index: DEMO_MDET_FK
-- ============================================================
create index DEMO_MDET_FK on DETRAZIONI_MOBILI (TIPO_TRIBUTO asc, MOTIVO_DETRAZIONE asc)
/

-- ============================================================
--   Table: RELAZIONI_OGGETTI_CALCOLO
-- ============================================================
create table RELAZIONI_OGGETTI_CALCOLO
(
    ID_RELAZIONE                    NUMBER                 not null,
    TIPO_TRIBUTO                    VARCHAR2(5)            not null,
    ANNO                            NUMBER(4)              not null,
    TIPO_OGGETTO                    NUMBER(2)              not null,
    CATEGORIA_CATASTO               VARCHAR2(3)            null    ,
    TIPO_ALIQUOTA                   NUMBER(2)              null    ,
    constraint RELAZIONI_OGGETTI_CALCOLO_PK primary key (ID_RELAZIONE)
)
/

comment on table RELAZIONI_OGGETTI_CALCOLO is 'RELAZIONI_OGGETTI_CALCOLO'
/

-- ============================================================
--   Index: ROCA_ALIQ_FK
-- ============================================================
create index ROCA_ALIQ_FK on RELAZIONI_OGGETTI_CALCOLO (TIPO_TRIBUTO asc, ANNO asc, TIPO_ALIQUOTA asc)
/

-- ============================================================
--   Index: ROCA_MOLT_FK
-- ============================================================
create index ROCA_MOLT_FK on RELAZIONI_OGGETTI_CALCOLO (ANNO asc, CATEGORIA_CATASTO asc)
/

-- ============================================================
--   Index: ROCA_OGTR_FK
-- ============================================================
create index ROCA_OGTR_FK on RELAZIONI_OGGETTI_CALCOLO (TIPO_TRIBUTO asc, TIPO_OGGETTO asc)
/

-- ============================================================
--   Table: RECAPITI_SOGGETTO
-- ============================================================
create table RECAPITI_SOGGETTO
(
    ID_RECAPITO                     NUMBER(10)             not null,
    NI                              NUMBER(10)             not null,
    TIPO_TRIBUTO                    VARCHAR2(5)            null    ,
    TIPO_RECAPITO                   NUMBER(2)              not null,
    DESCRIZIONE                     VARCHAR2(100)          null    ,
    COD_VIA                         NUMBER(6)              null    ,
    NUM_CIV                         NUMBER(6)              null    ,
    SUFFISSO                        VARCHAR2(10)           null    ,
    SCALA                           VARCHAR2(5)            null    ,
    PIANO                           VARCHAR2(5)            null    ,
    INTERNO                         NUMBER(4)              null    ,
    DAL                             DATE                   null    ,
    AL                              DATE                   null    ,
    COD_PRO                         NUMBER(3)              null    ,
    COD_COM                         NUMBER(3)              null    ,
    CAP                             NUMBER(5)              null    ,
    ZIPCODE                         VARCHAR2(10)           null    ,
    UTENTE                          VARCHAR2(8)            not null,
    DATA_VARIAZIONE                 DATE                   not null,
    NOTE                            VARCHAR2(2000)         null    ,
    PRESSO                          VARCHAR2(100)          null    ,
    constraint RECAPITI_SOGGETTO_PK primary key (ID_RECAPITO)
)
/

comment on table RECAPITI_SOGGETTO is 'RESO - Recapiti Soggetto'
/

-- ============================================================
--   Index: RESO_TIRE_FK
-- ============================================================
create index RESO_TIRE_FK on RECAPITI_SOGGETTO (TIPO_RECAPITO asc)
/

-- ============================================================
--   Index: RESO_SOGG_FK
-- ============================================================
create index RESO_SOGG_FK on RECAPITI_SOGGETTO (NI asc)
/

-- ============================================================
--   Table: RATE_PRATICA
-- ============================================================
create table RATE_PRATICA
(
    RATA_PRATICA                    NUMBER(10)             not null,
    PRATICA                         NUMBER(10)             not null,
    RATA                            NUMBER(2)              not null,
    DATA_SCADENZA                   DATE                   not null,
    ANNO                            NUMBER(4)              not null,
    TRIBUTO_CAPITALE_F24            VARCHAR2(4)            null    ,
    IMPORTO_CAPITALE                NUMBER(15,2)           not null,
    TRIBUTO_INTERESSI_F24           VARCHAR2(4)            null    ,
    IMPORTO_INTERESSI               NUMBER(15,2)           not null,
    RESIDUO_CAPITALE                NUMBER(15,2)           null    ,
    RESIDUO_INTERESSI               NUMBER(15,2)           null    ,
    UTENTE                          VARCHAR2(8)            not null,
    DATA_VARIAZIONE                 DATE                   not null,
    NOTE                            VARCHAR2(2000)         null    ,
    GIORNI_AGGIO                    NUMBER(4)              null    ,
    ALIQUOTA_AGGIO                  NUMBER(6,4)            null    ,
    AGGIO                           NUMBER(15,2)           null    ,
    AGGIO_RIMODULATO                NUMBER(15,2)           null    ,
    GIORNI_DILAZIONE                NUMBER(4)              null    ,
    ALIQUOTA_DILAZIONE              NUMBER(6,4)            null    ,
    DILAZIONE                       NUMBER(15,2)           null    ,
    DILAZIONE_RIMODULATA            NUMBER(15,2)           null    ,
    ONERI                           NUMBER(15,2)           null    ,
    IMPORTO                         NUMBER(15,2)           null
        constraint RATE_PRATICA_IMPORTO_CC check (
            IMPORTO is null or (IMPORTO >= 0
            )),
    IMPORTO_ARR                     NUMBER(15,2)           null    ,
    FLAG_SOSP_FERIE                 VARCHAR2(1)            null
        constraint RATE_PRATICA_FLAG_SOSP_FER_CC check (
            FLAG_SOSP_FERIE is null or (FLAG_SOSP_FERIE in ('S'))),
    QUOTA_TASSA                     NUMBER(15,2)           null    ,
    QUOTA_TEFA                      NUMBER(15,2)           null    ,
    TRIBUTO_IMPOSTA_F24             VARCHAR2(4)            null    ,
    TRIBUTO_TEFA_F24                VARCHAR2(4)            null    ,
    constraint RATE_PRATICA_PK primary key (RATA_PRATICA)
)
/

comment on table RATE_PRATICA is 'RAPR - Rate Pratica'
/

-- ============================================================
--   Index: RAPR_UK
-- ============================================================
create unique index RAPR_UK on RATE_PRATICA (PRATICA asc, RATA asc)
/

-- ============================================================
--   Index: RAPR_PRTR_FK
-- ============================================================
create index RAPR_PRTR_FK on RATE_PRATICA (PRATICA asc)
/

-- ============================================================
--   Table: FAMILIARI_SGRA
-- ============================================================
create table FAMILIARI_SGRA
(
    RUOLO                           NUMBER(10)             not null,
    COD_FISCALE                     VARCHAR2(16)           not null,
    SEQUENZA                        NUMBER(4)              not null,
    SEQUENZA_SGRAVIO                NUMBER(4)              not null,
    DAL                             DATE                   not null,
    AL                              DATE                   null    ,
    NUMERO_FAMILIARI                NUMBER(4)              null    ,
    DETTAGLIO_FASG                  VARCHAR2(2000)         null    ,
    UTENTE                          VARCHAR2(8)            null    ,
    DATA_VARIAZIONE                 DATE                   null    ,
    NOTE                            VARCHAR2(2000)         null    ,
    DETTAGLIO_FASG_BASE             VARCHAR2(2000)         null    ,
    constraint FAMILIARI_SGRA_PK primary key (RUOLO, COD_FISCALE, SEQUENZA, SEQUENZA_SGRAVIO, DAL)
)
/

comment on table FAMILIARI_SGRA is 'FASG - Familiari_Sgra'
/

-- ============================================================
--   Table: ANOMALIE_PRATICHE
-- ============================================================
create table ANOMALIE_PRATICHE
(
    ID_ANOMALIA_PRATICA             NUMBER(19)             not null,
    ID_ANOMALIA                     NUMBER(19)             not null,
    OGGETTO_PRATICA                 NUMBER(10)             not null,
    COD_FISCALE                     VARCHAR2(16)           null    ,
    FLAG_OK                         VARCHAR2(1)            null    ,
    UTENTE                          VARCHAR2(8)            null    ,
    DATA_REG                        DATE                   null    ,
    DATA_VARIAZIONE                 DATE                   null    ,
    ANOMALIA_PRATICA_RIF            NUMBER(19)             null    ,
    RENDITA                         NUMBER(15,2)           null    ,
    VERSION                         NUMBER(10)             not null,
    VALORE                          NUMBER(15,2)           null    ,
    constraint ANOMALIE_PRATICHE_PK primary key (ID_ANOMALIA_PRATICA)
)
/

comment on table ANOMALIE_PRATICHE is 'ANPR - Anomalie_Pratiche'
/

-- ============================================================
--   Index: ANPR_OGCO_FK
-- ============================================================
create index ANPR_OGCO_FK on ANOMALIE_PRATICHE (COD_FISCALE asc, OGGETTO_PRATICA asc)
/

-- ============================================================
--   Index: ANPR_ANOM_FK
-- ============================================================
create index ANPR_ANOM_FK on ANOMALIE_PRATICHE (ID_ANOMALIA asc)
/

-- ============================================================
--   Index: ANPR_ANPR2_FK
-- ============================================================
create index ANPR_ANPR2_FK on ANOMALIE_PRATICHE (ANOMALIA_PRATICA_RIF asc)
/

-- ============================================================
--   Table: WRK_GRAFFATI_CONT
-- ============================================================
create table WRK_GRAFFATI_CONT
(
    DOCUMENTO_ID                    NUMBER(10)             not null,
    ID_IMMOBILE                     NUMBER(9)              not null,
    COD_FISCALE                     VARCHAR2(16)           not null,
    RIFERIMENTO                     VARCHAR2(10)           null    ,
    constraint WRK_GRAFFATI_CONT_PK primary key (DOCUMENTO_ID, ID_IMMOBILE, COD_FISCALE)
)
/

comment on table WRK_GRAFFATI_CONT is 'WGCO - WRK Graffati Cont'
/

-- ============================================================
--   Index: WGCO_WRGR_FK
-- ============================================================
create index WGCO_WRGR_FK on WRK_GRAFFATI_CONT (DOCUMENTO_ID asc, RIFERIMENTO asc)
/

-- ============================================================
--   Table: ALIQUOTE_MOBILI
-- ============================================================
create table ALIQUOTE_MOBILI
(
    TIPO_TRIBUTO                    VARCHAR2(5)            not null,
    ANNO                            NUMBER(4)              not null,
    DA_RENDITA                      NUMBER(15,2)           not null,
    A_RENDITA                       NUMBER(15,2)           null    ,
    ALIQUOTA                        NUMBER(6,2)            null    ,
    constraint ALIQUOTE_MOBILI_PK primary key (TIPO_TRIBUTO, ANNO, DA_RENDITA)
)
/

comment on table ALIQUOTE_MOBILI is 'ALMO - Aliquote Mobili'
/

-- ============================================================
--   Table: CONFERIMENTI
-- ============================================================
create table CONFERIMENTI
(
    COD_FISCALE                     VARCHAR2(16)           not null,
    ANNO                            NUMBER(4)              not null,
    SACCHI                          NUMBER(4)              null    ,
    RUOLO                           NUMBER(10)             null    ,
    IMPORTO_SCALATO                 NUMBER(15,2)           null    ,
    UTENTE                          VARCHAR2(8)            null    ,
    DATA_VARIAZIONE                 DATE                   null    ,
    NOTE                            VARCHAR2(2000)         null    ,
    constraint CONFERIMENTI_PK primary key (COD_FISCALE, ANNO)
)
/

comment on table CONFERIMENTI is 'CONF - Conferimenti'
/

-- ============================================================
--   Index: CONF_CONT_FK
-- ============================================================
create index CONF_CONT_FK on CONFERIMENTI (COD_FISCALE asc)
/

-- ============================================================
--   Table: WEB_PARAMETRI_IMPORT
-- ============================================================
create table WEB_PARAMETRI_IMPORT
(
    ID_PARAMETRO_IMPORT             NUMBER(19)             not null,
    VERSION                         NUMBER(10)             not null,
    NOME_PARAMETRO                  VARCHAR2(50)           null    ,
    LABEL_PARAMETRO                 VARCHAR2(50)           null    ,
    COMPONENTE                      VARCHAR2(50)           null    ,
    NOME_BEAN                       VARCHAR2(50)           null    ,
    NOME_METODO                     VARCHAR2(50)           null    ,
    UTENTE                          VARCHAR2(8)            null    ,
    DATA_VARIAZIONE                 DATE                   null    ,
    ENTE                            VARCHAR2(4)            null    ,
    ID_TITOLO_DOCUMENTO             NUMBER(19)             not null,
    SEQUENZA                        NUMBER(2)              null    ,
    constraint WEB_PARAMETRI_IMPORT_PK primary key (ID_PARAMETRO_IMPORT)
)
/

comment on table WEB_PARAMETRI_IMPORT is 'WEB_PARAMETRI_IMPORT'
/

-- ============================================================
--   Index: WEPI_TIDO_FK
-- ============================================================
create index WEPI_TIDO_FK on WEB_PARAMETRI_IMPORT (ID_TITOLO_DOCUMENTO asc)
/

-- ============================================================
--   Table: WEB_CC_IDENTIFICATIVI
-- ============================================================
create table WEB_CC_IDENTIFICATIVI
(
    ID_IDENTIFICATIVO               NUMBER(10)             not null,
    VERSION                         NUMBER(10)             not null,
    ID_FABBRICATO                   NUMBER(10)             not null,
    SEZIONE_URBANA                  VARCHAR2(3)            null    ,
    FOGLIO                          VARCHAR2(4)            null    ,
    NUMERO                          VARCHAR2(5)            null    ,
    DENOMINATORE                    NUMBER(4)              null    ,
    SUBALTERNO                      VARCHAR2(4)            null    ,
    EDIFICIALITA                    VARCHAR2(1)            null    ,
    ENTE                            VARCHAR2(4)            null    ,
    UTENTE                          VARCHAR2(8)            null    ,
    constraint WEB_CC_IDENTIFICATIVI_PK primary key (ID_IDENTIFICATIVO)
)
/

comment on table WEB_CC_IDENTIFICATIVI is 'WEB_CC_IDENTIFICATIVI'
/

-- ============================================================
--   Index: IDX_FOGLIO
-- ============================================================
create index IDX_FOGLIO on WEB_CC_IDENTIFICATIVI (FOGLIO asc)
/

-- ============================================================
--   Index: IDX_SUBALTERNO
-- ============================================================
create index IDX_SUBALTERNO on WEB_CC_IDENTIFICATIVI (SUBALTERNO asc)
/

-- ============================================================
--   Index: IDX_NUMERO
-- ============================================================
create index IDX_NUMERO on WEB_CC_IDENTIFICATIVI (NUMERO asc)
/

-- ============================================================
--   Index: WCID_WCFA_FK
-- ============================================================
create index WCID_WCFA_FK on WEB_CC_IDENTIFICATIVI (ID_FABBRICATO asc)
/

-- ============================================================
--   Table: WEB_CC_INDIRIZZI
-- ============================================================
create table WEB_CC_INDIRIZZI
(
    ID_INDIRIZZO                    NUMBER(10)             not null,
    VERSION                         NUMBER(10)             not null,
    ID_FABBRICATO                   NUMBER(10)             not null,
    ID_TOPONIMO                     NUMBER(3)              null    ,
    INDIRIZZO                       VARCHAR2(50)           null    ,
    CIVICO1                         VARCHAR2(6)            null    ,
    CIVICO2                         VARCHAR2(6)            null    ,
    CIVICO3                         VARCHAR2(6)            null    ,
    CODICE_STRADA                   NUMBER(5)              null    ,
    ENTE                            VARCHAR2(4)            null    ,
    UTENTE                          VARCHAR2(8)            null    ,
    constraint WEB_CC_INDIRIZZI_PK primary key (ID_INDIRIZZO)
)
/

comment on table WEB_CC_INDIRIZZI is 'WEB_CC_INDIRIZZI'
/

-- ============================================================
--   Index: WCIN_WCFA_FK
-- ============================================================
create index WCIN_WCFA_FK on WEB_CC_INDIRIZZI (ID_FABBRICATO asc)
/

-- ============================================================
--   Index: WCIN_WCTO_FK
-- ============================================================
create index WCIN_WCTO_FK on WEB_CC_INDIRIZZI (ID_TOPONIMO asc)
/

-- ============================================================
--   Table: WEB_CC_TITOLARITA
-- ============================================================
create table WEB_CC_TITOLARITA
(
    ID_TITOLARITA                   NUMBER(10)             not null,
    VERSION                         NUMBER(10)             not null,
    ID_SOGGETTO                     NUMBER(10)             not null,
    ID_FABBRICATO                   NUMBER(10)             null    ,
    ID_PARTICELLA                   NUMBER(10)             null    ,
    CODICE_AMMINISTRATIVO           VARCHAR2(4)            not null,
    SEZIONE                         VARCHAR2(1)            not null,
    ID_CODICE_DIRITTO               VARCHAR2(3)            null    ,
    TITOLO_NON_CODIFICATO           VARCHAR2(200)          null    ,
    QUOTA_NUMERATORE                NUMBER(9)              null    ,
    QUOTA_DENOMINATORE              NUMBER(9)              null    ,
    REGIME                          VARCHAR2(1)            null    ,
    ID_SOGGETTO_RIFERIMENTO         NUMBER(10)             null    ,
    DATA_VALIDITA_DAL               DATE                   null    ,
    TIPO_NOTA_DAL                   VARCHAR2(1)            null    ,
    NUMERO_NOTA_DAL                 VARCHAR2(6)            null    ,
    PROGR_NOTA_DAL                  VARCHAR2(3)            null    ,
    ANNO_NOTA_DAL                   NUMBER(4)              null    ,
    DATA_REG_ATTI_DAL               DATE                   null    ,
    PARTITA                         VARCHAR2(7)            null    ,
    DATA_VALIDITA_AL                DATE                   null    ,
    TIPO_NOTA_AL                    VARCHAR2(1)            null    ,
    NUMERO_NOTA_AL                  VARCHAR2(6)            null    ,
    PROGR_NOTA_AL                   VARCHAR2(3)            null    ,
    ANNO_NOTA_AL                    NUMBER(4)              null    ,
    DATA_REG_ATTI_AL                DATE                   null    ,
    ID_MUTAZIONE_INIZIALE           NUMBER(10)             null    ,
    ID_MUTAZIONE_FINALE             NUMBER(10)             null    ,
    IDENTIFICATIVO_TITOLARITA       NUMBER(10)             null    ,
    CODICE_CAUSALE_ATTO_GEN         VARCHAR2(3)            null    ,
    DESCRIZIONE_ATTO_GEN            VARCHAR2(100)          null    ,
    CODICE_CAUSALE_ATTO_CON         VARCHAR2(3)            null    ,
    DESCRIZIONE_ATTO_CON            VARCHAR2(100)          null    ,
    ENTE                            VARCHAR2(4)            null    ,
    UTENTE                          VARCHAR2(8)            null    ,
    constraint WEB_CC_TITOLARITA_PK primary key (ID_TITOLARITA)
)
/

comment on table WEB_CC_TITOLARITA is 'WEB_CC_TITOLARITA'
/

-- ============================================================
--   Index: WCTI_WCSO_FK
-- ============================================================
create index WCTI_WCSO_FK on WEB_CC_TITOLARITA (ID_SOGGETTO asc)
/

-- ============================================================
--   Index: WCTI_WCFA_FK
-- ============================================================
create index WCTI_WCFA_FK on WEB_CC_TITOLARITA (ID_FABBRICATO asc)
/

-- ============================================================
--   Index: WCTI_WCPA_FK
-- ============================================================
create index WCTI_WCPA_FK on WEB_CC_TITOLARITA (ID_PARTICELLA asc)
/

-- ============================================================
--   Table: WEB_CALCOLO_DETTAGLI
-- ============================================================
create table WEB_CALCOLO_DETTAGLI
(
    ID_CALCOLO_DETTAGLI             NUMBER                 not null,
    ID_CALCOLO_INDIVIDUALE          NUMBER                 not null,
    LAST_UPDATED                    DATE                   not null,
    DATE_CREATED                    DATE                   not null,
    UTENTE                          VARCHAR2(8)            not null,
    TIPO_OGGETTO                    VARCHAR2(25)           not null,
    VERS_ACCONTO                    NUMBER                 null    ,
    VERS_ACCONTO_ERAR               NUMBER                 null    ,
    ACCONTO                         NUMBER                 null    ,
    SALDO                           NUMBER                 null    ,
    ACCONTO_ERAR                    NUMBER                 null    ,
    SALDO_ERAR                      NUMBER                 null    ,
    NUM_FABBRICATI                  NUMBER                 null    ,
    ORDINAMENTO                     NUMBER                 not null,
    VERSION                         NUMBER(10)             null    ,
    constraint WEB_CALCOLO_DETTAGLI_PK primary key (ID_CALCOLO_DETTAGLI)
)
/

comment on table WEB_CALCOLO_DETTAGLI is 'WCDE - Deposito valori calcolati da CALCOLO_INDIVIDUALE suddivisi per tipo di immobile'
/

CREATE SEQUENCE WCDE_SQ
  START WITH 1
  MAXVALUE 999999999999999999999999999
  MINVALUE 1
  NOCYCLE
  NOCACHE
  NOORDER
/

-- ============================================================
--   Index: WCDE_WCIN_FK
-- ============================================================
create index WCDE_WCIN_FK on WEB_CALCOLO_DETTAGLI (ID_CALCOLO_INDIVIDUALE asc)
/

-- ============================================================
--   Table: AFC_ALLEGATI_ELABORAZIONE
-- ============================================================
create table AFC_ALLEGATI_ELABORAZIONE
(
    ID_ALLEGATO                     NUMBER(10)             not null,
    VERSION                         NUMBER(10)             not null,
    ID_ELABORAZIONE                 NUMBER(10)             not null,
    NOME                            VARCHAR2(100)          not null,
    TESTO                           BLOB                   null    ,
    TIPO                            VARCHAR2(50)           not null,
    constraint AFC_ALLEGATI_ELABORAZIONE_PK primary key (ID_ALLEGATO)
)
/

comment on table AFC_ALLEGATI_ELABORAZIONE is 'AFC_ALLEGATI_ELABORAZIONE'
/

-- ============================================================
--   Index: AFAL_AFEL_FK
-- ============================================================
create index AFAL_AFEL_FK on AFC_ALLEGATI_ELABORAZIONE (ID_ELABORAZIONE asc)
/

-- ============================================================
--   Table: AFC_LOG_ELABORAZIONI
-- ============================================================
create table AFC_LOG_ELABORAZIONI
(
    ID_LOG                          NUMBER(10)             not null,
    VERSION                         NUMBER(10)             not null,
    ID_ELABORAZIONE                 NUMBER(10)             not null,
    TESTO_LOG                       VARCHAR2(4000)         not null,
    constraint AFC_LOG_ELABORAZIONI_PK primary key (ID_LOG)
)
/

comment on table AFC_LOG_ELABORAZIONI is 'AFC_LOG_ELABORAZIONI'
/

-- ============================================================
--   Index: AFLE_AFEL_FK
-- ============================================================
create index AFLE_AFEL_FK on AFC_LOG_ELABORAZIONI (ID_ELABORAZIONE asc)
/

-- ============================================================
--   Table: WS_INDIRIZZI_INTEGRAZIONE
-- ============================================================
create table WS_INDIRIZZI_INTEGRAZIONE
(
    CODICE_ISTAT                    VARCHAR2(6)            not null,
    CODICE_INTEGRAZIONE             NUMBER(3)              not null,
    IDENTIFICATIVO_SERVIZIO         NUMBER(2)              not null,
    INDIRIZZO_URL                   VARCHAR2(100)          not null,
    WEB_SERVICE                     VARCHAR2(100)          not null,
    TESTO_INIZIALE_ENVELOPE         VARCHAR2(2000)         null    ,
    TESTO_FINALE_ENVELOPE           VARCHAR2(2000)         null    ,
    HEADER_TYPE                     VARCHAR2(100)          null    ,
    HEADER_ACTION                   VARCHAR2(100)          null    ,
    constraint WS_INDIRIZZI_INTEGRAZIONE_PK primary key (CODICE_ISTAT, CODICE_INTEGRAZIONE, IDENTIFICATIVO_SERVIZIO)
)
/

comment on table WS_INDIRIZZI_INTEGRAZIONE is 'WINI : Tabella per la gestione degli indirizzi e dei nomi dei web services da richiamare per gli invii dei carichi e la richiesta giacenza armadio di reparto'
/

-- ============================================================
--   Index: WINI_WINT_FK
-- ============================================================
create index WINI_WINT_FK on WS_INDIRIZZI_INTEGRAZIONE (CODICE_INTEGRAZIONE asc)
/

-- ============================================================
--   Table: RIDUZIONI_CER
-- ============================================================
create table RIDUZIONI_CER
(
    ANNO                            NUMBER(4)              not null,
    TIPO_UTENZA                     VARCHAR2(1)            not null
        constraint RIDUZIONI_CER_TIPO_UTENZA_CC check (
            TIPO_UTENZA in ('D','N')),
    CODICE_CER                      VARCHAR2(6)            not null,
    PESO_MAX                        NUMBER(6,2)            not null,
    SCONTO_KG                       NUMBER(4,2)            not null,
    NOTE                            VARCHAR2(2000)         null    ,
    constraint RIDUZIONI_CER_PK primary key (ANNO, TIPO_UTENZA, CODICE_CER)
)
/

comment on table RIDUZIONI_CER is 'RICE - Riduzioni CER'
/

-- ============================================================
--   Index: RICE_CACE_FK
-- ============================================================
create index RICE_CACE_FK on RIDUZIONI_CER (CODICE_CER asc)
/

-- ============================================================
--   Table: CONFERIMENTI_CER_RUOLO
-- ============================================================
create table CONFERIMENTI_CER_RUOLO
(
    COD_FISCALE                     VARCHAR2(16)           not null,
    ANNO                            NUMBER(4)              not null,
    TIPO_UTENZA                     VARCHAR2(1)            not null
        constraint CONF_CER_RUO_TIPO_UTENZA_CC check (
            TIPO_UTENZA in ('D','N')),
    DATA_CONFERIMENTO               DATE                   not null,
    CODICE_CER                      VARCHAR2(6)            not null,
    SEQUENZA                        NUMBER(4)              not null,
    QUANTITA                        NUMBER(6,2)            null    ,
    IMPORTO_CALCOLATO               NUMBER(15,2)           null    ,
    RUOLO                           NUMBER(10)             null    ,
    IMPORTO_SCALATO                 NUMBER(15,2)           null    ,
    UTENTE                          VARCHAR2(8)            null    ,
    DATA_VARIAZIONE                 DATE                   null    ,
    NOTE                            VARCHAR2(2000)         null    ,
    constraint CONFERIMENTI_CER_RUOLO_PK primary key (COD_FISCALE, ANNO, TIPO_UTENZA, DATA_CONFERIMENTO, CODICE_CER, SEQUENZA)
)
/

comment on table CONFERIMENTI_CER_RUOLO is 'CCRU - Conferimenti CER Ruolo'
/

-- ============================================================
--   Index: CCRU_COCE_FK
-- ============================================================
create index CCRU_COCE_FK on CONFERIMENTI_CER_RUOLO (COD_FISCALE asc, ANNO asc, TIPO_UTENZA asc, DATA_CONFERIMENTO asc, CODICE_CER asc)
/

-- ============================================================
--   Table: CAUSALI
-- ============================================================
create table CAUSALI
(
    TIPO_TRIBUTO                    VARCHAR2(5)            not null,
    CAUSALE                         VARCHAR2(200)          not null,
    DESCRIZIONE                     VARCHAR2(200)          not null,
    constraint CAUSALI_PK primary key (TIPO_TRIBUTO, CAUSALE)
)
/

comment on table CAUSALI is 'CAUS - Causali'
/

-- ============================================================
--   Index: CAUS_TITR_FK
-- ============================================================
create index CAUS_TITR_FK on CAUSALI (TIPO_TRIBUTO asc)
/

-- ============================================================
--   Table: DATI_METRICI
-- ============================================================
create table DATI_METRICI
(
    ID                              NUMBER(10)             not null,
    AMBIENTE                        VARCHAR2(1)            null    ,
    SUPERFICIE_AMBIENTE             NUMBER(9,2)            null    ,
    ALTEZZA                         NUMBER(4)              null    ,
    ALTEZZA_MAX                     NUMBER(4)              null    ,
    UIU_ID                          NUMBER(15)             not null,
    constraint DATI_METRICI_PK primary key (ID)
)
/

comment on table DATI_METRICI is 'SAME - Dati Metrici'
/

-- ============================================================
--   Index: DAME_DMUI_FK
-- ============================================================
create index DAME_DMUI_FK on DATI_METRICI (UIU_ID asc)
/

-- ============================================================
--   Table: DATI_METRICI_DATI_ATTO
-- ============================================================
create table DATI_METRICI_DATI_ATTO
(
    DATI_ATTO_ID                    NUMBER(10)             not null,
    SEDE_ROGANTE                    VARCHAR2(150)          null    ,
    DATA                            DATE                   null    ,
    NUMERO_REPERTORIO               NUMBER(10)             null    ,
    RACCOLTA_REPERTORIO             NUMBER(10)             null    ,
    SOGGETTI_ID                     NUMBER(15)             not null,
    constraint DATI_METRICI_DATI_ATTO_PK primary key (DATI_ATTO_ID)
)
/

comment on table DATI_METRICI_DATI_ATTO is 'DMDA - Dati Metrici Dati Atto'
/

-- ============================================================
--   Index: DMDA_DMSO_FK
-- ============================================================
create index DMDA_DMSO_FK on DATI_METRICI_DATI_ATTO (SOGGETTI_ID asc)
/

-- ============================================================
--   Table: DATI_METRICI_DATI_NUOVI
-- ============================================================
create table DATI_METRICI_DATI_NUOVI
(
    DATI_NUOVI_ID                   NUMBER(10)             not null,
    SUPERFICIE_TOT                  NUMBER(9,2)            null    ,
    SUPERFICIE_CONV                 NUMBER(9,2)            null    ,
    INIZIO_VALIDITA                 DATE                   null    ,
    FINE_VALIDITA                   DATE                   null    ,
    COMUNE                          VARCHAR2(50)           null    ,
    PROG_STRADA                     VARCHAR2(20)           null    ,
    DATA_CERTIFICAZIONE             DATE                   null    ,
    DATA_PROVV                      DATE                   null    ,
    PROTOCOLLO_PROVV                VARCHAR2(50)           null    ,
    COD_STRADA_COM                  VARCHAR2(20)           null    ,
    UIU_ID                          NUMBER(15)             not null,
    constraint DATI_METRICI_DATI_NUOVI_PK primary key (DATI_NUOVI_ID)
)
/

comment on table DATI_METRICI_DATI_NUOVI is 'DMDN - Dati Metrici Dati Nuovi'
/

-- ============================================================
--   Index: DMDN_DMUI_FK
-- ============================================================
create index DMDN_DMUI_FK on DATI_METRICI_DATI_NUOVI (UIU_ID asc)
/

-- ============================================================
--   Table: DATI_METRICI_ESITI_AGENZIA
-- ============================================================
create table DATI_METRICI_ESITI_AGENZIA
(
    ESITI_AGENZIA_ID                NUMBER(10)             not null,
    ESITO_SUP                       NUMBER(1)              null    ,
    ESITO_AGG                       VARCHAR2(2)            null    ,
    UIU_ID                          NUMBER(15)             not null,
    constraint DATI_METRICI_ESITI_AGENZIA_PK primary key (ESITI_AGENZIA_ID)
)
/

comment on table DATI_METRICI_ESITI_AGENZIA is 'DMEA - Dati Metrici Esiti Agenzia'
/

-- ============================================================
--   Index: DMEA_DMUI_FK
-- ============================================================
create index DMEA_DMUI_FK on DATI_METRICI_ESITI_AGENZIA (UIU_ID asc)
/

-- ============================================================
--   Table: DATI_METRICI_ESITI_COMUNE
-- ============================================================
create table DATI_METRICI_ESITI_COMUNE
(
    ESITI_COMUNE_ID                 NUMBER(10)             not null,
    RISCONTRO                       NUMBER(1)              null    ,
    ISTANZA                         NUMBER(1)              null    ,
    RICHIESTA_PLAN                  NUMBER(1)              null    ,
    UIU_ID                          NUMBER(15)             not null,
    constraint DATI_METRICI_ESITI_COMUNE_PK primary key (ESITI_COMUNE_ID)
)
/

comment on table DATI_METRICI_ESITI_COMUNE is 'DMEC - Dati Metrici Esiti Comune'
/

-- ============================================================
--   Index: DMEC_DMUI_FK
-- ============================================================
create index DMEC_DMUI_FK on DATI_METRICI_ESITI_COMUNE (UIU_ID asc)
/

-- ============================================================
--   Table: DATI_METRICI_IDENTIFICATIVI
-- ============================================================
create table DATI_METRICI_IDENTIFICATIVI
(
    IDENTIFICATIVI_ID               NUMBER(10)             not null,
    SEZIONE                         VARCHAR2(3)            null    ,
    FOGLIO                          VARCHAR2(4)            null    ,
    NUMERO                          VARCHAR2(5)            null    ,
    DENOMINATORE                    VARCHAR2(4)            null    ,
    SUBALTERNO                      VARCHAR2(4)            null    ,
    EDIFICIALITA                    VARCHAR2(1)            null    ,
    UIU_ID                          NUMBER(15)             not null,
    constraint DATI_METRICI_IDENTIFICATIVI_PK primary key (IDENTIFICATIVI_ID)
)
/

comment on table DATI_METRICI_IDENTIFICATIVI is 'DMID - Dati Metrici Identificativi'
/

-- ============================================================
--   Index: DMID_DMUI_FK
-- ============================================================
create index DMID_DMUI_FK on DATI_METRICI_IDENTIFICATIVI (UIU_ID asc)
/

-- ============================================================
--   Table: DATI_METRICI_INDIRIZZI
-- ============================================================
create table DATI_METRICI_INDIRIZZI
(
    INDIRIZZI_ID                    NUMBER(10)             not null,
    COD_TOPONIMO                    NUMBER(3)              null    ,
    TOPONIMO                        VARCHAR2(16)           null    ,
    DENOM                           VARCHAR2(50)           null    ,
    CODICE                          NUMBER(5)              null    ,
    CIVICO1                         VARCHAR2(6)            null    ,
    CIVICO2                         VARCHAR2(6)            null    ,
    CIVICO3                         VARCHAR2(6)            null    ,
    FONTE                           VARCHAR2(1)            null    ,
    DELIBERA                        VARCHAR2(70)           null    ,
    LOCALITA                        VARCHAR2(30)           null    ,
    KM                              NUMBER(5)              null    ,
    CAP                             VARCHAR2(5)            null    ,
    UIU_ID                          NUMBER(15)             not null,
    constraint DATI_METRICI_INDIRIZZI_PK primary key (INDIRIZZI_ID)
)
/

comment on table DATI_METRICI_INDIRIZZI is 'DMIN - Dati Metrici Indirizzi'
/

-- ============================================================
--   Index: DMIN_DMUI_FK
-- ============================================================
create index DMIN_DMUI_FK on DATI_METRICI_INDIRIZZI (UIU_ID asc)
/

-- ============================================================
--   Table: DATI_METRICI_UBICAZIONI
-- ============================================================
create table DATI_METRICI_UBICAZIONI
(
    UBICAZIONI_ID                   NUMBER(10)             not null,
    LOTTO                           VARCHAR2(2)            null    ,
    EDIFICIO                        VARCHAR2(2)            null    ,
    SCALA                           VARCHAR2(2)            null    ,
    INTERNO1                        VARCHAR2(3)            null    ,
    INTERNO2                        VARCHAR2(3)            null    ,
    PIANO1                          VARCHAR2(4)            null    ,
    PIANO2                          VARCHAR2(4)            null    ,
    PIANO3                          VARCHAR2(4)            null    ,
    PIANO4                          VARCHAR2(4)            null    ,
    UIU_ID                          NUMBER(15)             not null,
    constraint DATI_METRICI_UBICAZIONI_PK primary key (UBICAZIONI_ID)
)
/

comment on table DATI_METRICI_UBICAZIONI is 'DMUB - Dati Metrici Ubicazioni'
/

-- ============================================================
--   Index: DMUB_DMUI_FK
-- ============================================================
create index DMUB_DMUI_FK on DATI_METRICI_UBICAZIONI (UIU_ID asc)
/

-- ============================================================
--   Table: LOCAZIONI_IMMOBILI
-- ============================================================
create table LOCAZIONI_IMMOBILI
(
    IMMOBILI_ID                     NUMBER(10)             not null,
    UFFICIO                         VARCHAR2(3)            null    ,
    ANNO                            NUMBER(4)              null    ,
    SERIE                           VARCHAR2(2)            null    ,
    NUMERO                          NUMBER(6)              null    ,
    SOTTO_NUMERO                    NUMBER(3)              null    ,
    PROGRESSIVO_NEGOZIO             NUMBER(3)              null    ,
    PROGRESSIVO_IMMOBILE            NUMBER(3)              null    ,
    IMM_ACCATASTAMENTO              VARCHAR2(1)            null    ,
    TIPO_CATASTO                    VARCHAR2(1)            null    ,
    FLAG_IP                         VARCHAR2(1)            null    ,
    CODICE_CATASTO                  VARCHAR2(4)            null    ,
    SEZ_URB_COM_CAT                 VARCHAR2(3)            null    ,
    FOGLIO                          VARCHAR2(4)            null    ,
    PARTICELLA_NUM                  VARCHAR2(5)            null    ,
    PARTICELLA_DEN                  VARCHAR2(4)            null    ,
    SUBALTERNO                      VARCHAR2(4)            null    ,
    INDIRIZZO                       VARCHAR2(40)           null    ,
    CONTRATTI_ID                    NUMBER(10)             not null,
    constraint LOCAZIONI_IMMOBILI_PK primary key (IMMOBILI_ID)
)
/

comment on table LOCAZIONI_IMMOBILI is 'LOIM - Locazioni Immobili'
/

-- ============================================================
--   Index: LOIM_LOCO_FK
-- ============================================================
create index LOIM_LOCO_FK on LOCAZIONI_IMMOBILI (CONTRATTI_ID asc)
/

-- ============================================================
--   Table: LOCAZIONI_SOGGETTI
-- ============================================================
create table LOCAZIONI_SOGGETTI
(
    SOGGETTI_ID                     NUMBER                 not null,
    UFFICIO                         VARCHAR2(3)            null    ,
    ANNO                            NUMBER(4)              null    ,
    SERIE                           VARCHAR2(2)            null    ,
    NUMERO                          NUMBER(6)              null    ,
    SOTTO_NUMERO                    NUMBER(3)              null    ,
    PROGRESSIVO_SOGGETTO            NUMBER(3)              null    ,
    PROGRESSIVO_NEGOZIO             NUMBER(3)              null    ,
    TIPO_SOGGETTO                   VARCHAR2(1)            null    ,
    COD_FISCALE                     VARCHAR2(16)           null    ,
    SESSO                           VARCHAR2(1)            null    ,
    CITTA_NASCITA                   VARCHAR2(30)           null    ,
    PROV_NASCITA                    VARCHAR2(2)            null    ,
    DATA_NASCITA                    DATE                   null    ,
    CITTA_RES                       VARCHAR2(30)           null    ,
    PROV_RES                        VARCHAR2(2)            null    ,
    INDIRIZZO_RES                   VARCHAR2(35)           null    ,
    NUM_CIV_RES                     VARCHAR2(6)            null    ,
    DATA_SUBENTRO                   DATE                   null    ,
    DATA_CESSAZIONE                 DATE                   null    ,
    CONTRATTI_ID                    NUMBER(10)             not null,
    constraint LOCAZIONI_SOGGETTI_PK primary key (SOGGETTI_ID)
)
/

comment on table LOCAZIONI_SOGGETTI is 'LOSO - Locazioni Soggetti'
/

-- ============================================================
--   Index: LOSO_LOCO_FK
-- ============================================================
create index LOSO_LOCO_FK on LOCAZIONI_SOGGETTI (CONTRATTI_ID asc)
/

-- ============================================================
--   Table: LOCAZIONI_TIPI_TRACCIATO
-- ============================================================
create table LOCAZIONI_TIPI_TRACCIATO
(
    TIPO_TRACCIATO                  NUMBER(10)             not null,
    DATA_INIZIO                     DATE                   not null,
    DATA_FINE                       DATE                   not null,
    TRACCIATO                       CLOB                   not null,
    TITOLO_DOCUMENTO                NUMBER                 null    ,
    constraint LOCAZIONI_TIPI_TRACCIATO_PK primary key (TIPO_TRACCIATO)
)
/

comment on table LOCAZIONI_TIPI_TRACCIATO is 'LOTT - Locazioni Tipi Tracciato'
/

-- ============================================================
--   Index: LOTT_TIDO_FK
-- ============================================================
create index LOTT_TIDO_FK on LOCAZIONI_TIPI_TRACCIATO (TITOLO_DOCUMENTO asc)
/

-- ============================================================
--   Table: UTENZE_DATI_FORNITURA
-- ============================================================
create table UTENZE_DATI_FORNITURA
(
    DATI_FORNITURA_ID               NUMBER(10)             not null,
    IDENTIFICATIVO_UTENZA           VARCHAR2(30)           null    ,
    TIPO_FORNITURA                  VARCHAR2(1)            null    ,
    ANNO_RIFERIMENTO                NUMBER(4)              null    ,
    COD_CATASTALE_UTENZA            VARCHAR2(4)            null    ,
    COD_FISCALE_EROGANTE            VARCHAR2(16)           null    ,
    COD_FISCALE_TITOLARE            VARCHAR2(16)           null    ,
    TIPO_SOGGETTO                   VARCHAR2(1)            null    ,
    DATI_ANAGRAFICI_TITOLARE        VARCHAR2(80)           null    ,
    TIPO_UTENZA                     VARCHAR2(1)            null    ,
    INDIRIZZO_UTENZA                VARCHAR2(35)           null    ,
    CAP_UTENZA                      VARCHAR2(5)            null    ,
    AMMONTARE_FATTURATO             NUMBER(15,2)           null    ,
    CONSUMO_FATTURATO               NUMBER(12,2)           null    ,
    MESI_FATTURAZIONE               NUMBER(2)              null    ,
    FORNITURE_ID                    NUMBER(10)             not null,
    constraint UTENZE_DATI_FORNITURA_PK primary key (DATI_FORNITURA_ID)
)
/

comment on table UTENZE_DATI_FORNITURA is 'UTDF - Utenze Dati Fornitura'
/

-- ============================================================
--   Index: UTDF_UTFO_FK
-- ============================================================
create index UTDF_UTFO_FK on UTENZE_DATI_FORNITURA (FORNITURE_ID asc)
/

-- ============================================================
--   Index: UTDF_UTTU_FK
-- ============================================================
create index UTDF_UTTU_FK on UTENZE_DATI_FORNITURA (TIPO_FORNITURA asc, TIPO_UTENZA asc)
/

-- ============================================================
--   Table: MODELLI_VERSIONE
-- ============================================================
create table MODELLI_VERSIONE
(
    VERSIONE_ID                     NUMBER(10)             not null,
    MODELLO                         NUMBER(4)              not null,
    VERSIONE                        NUMBER                 not null,
    DOCUMENTO                       BLOB                   not null,
    UTENTE                          VARCHAR2(8)            null    ,
    DATA_VARIAZIONE                 DATE                   null    ,
    NOTE                            VARCHAR2(2000)         null    ,
    constraint MODELLI_VERSIONE_PK primary key (VERSIONE_ID)
)
/

comment on table MODELLI_VERSIONE is 'MODELLI_VERSIONE'
/

-- ============================================================
--   Index: MOVE_MODE_FK
-- ============================================================
create index MOVE_MODE_FK on MODELLI_VERSIONE (MODELLO asc)
/

-- ============================================================
--   Index: MOVE_VERSIONE_UK
-- ============================================================
create unique index MOVE_VERSIONE_UK on MODELLI_VERSIONE (MODELLO asc, VERSIONE asc)
/

-- ============================================================
--   Table: TARIFFE_NON_DOMESTICHE
-- ============================================================
create table TARIFFE_NON_DOMESTICHE
(
    TRIBUTO                         NUMBER(4)              not null,
    CATEGORIA                       NUMBER(4)              not null,
    ANNO                            NUMBER(4)              not null,
    TARIFFA_QUOTA_FISSA             NUMBER(11,5)           not null,
    TARIFFA_QUOTA_VARIABILE         NUMBER(11,5)           not null,
    IMPORTO_MINIMI                  NUMBER(11,5)           null    ,
    constraint TARIFFE_NON_DOMESTICHE_PK primary key (TRIBUTO, CATEGORIA, ANNO)
)
/

comment on table TARIFFE_NON_DOMESTICHE is 'tand - Tariffe non Domestiche'
/

-- ============================================================
--   Index: TAND_IK
-- ============================================================
create index TAND_IK on TARIFFE_NON_DOMESTICHE (ANNO asc)
/

-- ============================================================
--   Table: ITER_PRATICA
-- ============================================================
create table ITER_PRATICA
(
    ITER_PRATICA                    NUMBER                 not null,
    PRATICA                         NUMBER(10)             not null,
    DATA                            DATE                   not null,
    STATO                           VARCHAR2(2)            null    ,
    MOTIVO                          VARCHAR2(2000)         null    ,
    UTENTE                          VARCHAR2(8)            null    ,
    DATA_VARIAZIONE                 DATE                   null    ,
    NOTE                            VARCHAR2(2000)         null    ,
    TIPO_ATTO                       NUMBER(2)              null    ,
    FLAG_ANNULLAMENTO               VARCHAR2(1)            null
        constraint ITER_PRATICA_FLAG_ANNULLAM_CC check (
            FLAG_ANNULLAMENTO is null or (FLAG_ANNULLAMENTO in ('S'))),
    constraint ITER_PRATICA_PK primary key (ITER_PRATICA)
)
/

comment on table ITER_PRATICA is 'ITPR - Iter Pratica'
/

create sequence NR_ITPR_SEQ
MINVALUE 0
START WITH 1
INCREMENT BY 1
NOCACHE
/

-- ============================================================
--   Index: ITPR_PRTR_FK
-- ============================================================
create index ITPR_PRTR_FK on ITER_PRATICA (PRATICA asc)
/

-- ============================================================
--   Index: ITPR_TIST_FK
-- ============================================================
create index ITPR_TIST_FK on ITER_PRATICA (STATO asc)
/

-- ============================================================
--   Index: ITPR_TIAT_FK
-- ============================================================
create index ITPR_TIAT_FK on ITER_PRATICA (TIPO_ATTO asc)
/

-- ============================================================
--   Table: PARAMETRI_UTENTE
-- ============================================================
create table PARAMETRI_UTENTE
(
    ID                              NUMBER                 not null,
    UTENTE                          VARCHAR2(8)            null    ,
    TIPO_PARAMETRO                  VARCHAR2(16)           null    ,
    VALORE                          VARCHAR2(2000)         null    ,
    DATA_VARIAZIONE                 DATE                   null    ,
    constraint PARAMETRI_UTENTE_PK primary key (ID)
)
/

comment on table PARAMETRI_UTENTE is 'PAUT - Parametri Utente'
/

-- ============================================================
--   Index: PAUT_UK
-- ============================================================
create unique index PAUT_UK on PARAMETRI_UTENTE (UTENTE asc, TIPO_PARAMETRO asc)
/

-- ============================================================
--   Table: FTP_LOG
-- ============================================================
create table FTP_LOG
(
    ID_DOCUMENTO                    NUMBER(10)             not null,
    SEQUENZA                        NUMBER(8)              not null,
    MESSAGGIO                       VARCHAR2(2000)         null    ,
    UTENTE                          VARCHAR2(8)            null    ,
    DATA_VARIAZIONE                 DATE                   null    ,
    constraint FTP_LOG_PK primary key (ID_DOCUMENTO, SEQUENZA)
)
/

comment on table FTP_LOG is 'FTLO - FTO Log'
/

-- ============================================================
--   Index: FTLO_FTTR_FK
-- ============================================================
create index FTLO_FTTR_FK on FTP_LOG (ID_DOCUMENTO asc)
/

-- ============================================================
--   Table: STO_OGGETTI_CONTRIBUENTE
-- ============================================================
create table STO_OGGETTI_CONTRIBUENTE
(
    COD_FISCALE                     VARCHAR2(16)           not null,
    OGGETTO_PRATICA                 NUMBER(10)             not null,
    ANNO                            NUMBER(4)              not null,
    TIPO_RAPPORTO                   VARCHAR2(1)            null
        constraint STO_OGGETTI_C_TIPO_RAPPORTO_CC check (
            TIPO_RAPPORTO is null or (TIPO_RAPPORTO in ('D','C','E','A'))),
    INIZIO_OCCUPAZIONE              DATE                   null    ,
    FINE_OCCUPAZIONE                DATE                   null    ,
    DATA_DECORRENZA                 DATE                   null    ,
    DATA_CESSAZIONE                 DATE                   null    ,
    PERC_POSSESSO                   NUMBER(5,2)            null    ,
    MESI_POSSESSO                   NUMBER(2)              null    ,
    MESI_POSSESSO_1SEM              NUMBER(1)              null    ,
    MESI_ESCLUSIONE                 NUMBER(2)              null    ,
    MESI_RIDUZIONE                  NUMBER(2)              null    ,
    MESI_ALIQUOTA_RIDOTTA           NUMBER(2)              null    ,
    DETRAZIONE                      NUMBER(15,2)           null
        constraint STO_OGGETTI_C_DETRAZIONE_CC check (
            DETRAZIONE is null or (DETRAZIONE >= 0
            )),
    FLAG_POSSESSO                   VARCHAR2(1)            null
        constraint STO_OGGETTI_C_FLAG_POSSESSO_CC check (
            FLAG_POSSESSO is null or (FLAG_POSSESSO in ('S'))),
    FLAG_ESCLUSIONE                 VARCHAR2(1)            null
        constraint STO_OGGETTI_C_FLAG_ESCLUSIO_CC check (
            FLAG_ESCLUSIONE is null or (FLAG_ESCLUSIONE in ('S'))),
    FLAG_RIDUZIONE                  VARCHAR2(1)            null
        constraint STO_OGGETTI_C_FLAG_RIDUZION_CC check (
            FLAG_RIDUZIONE is null or (FLAG_RIDUZIONE in ('S'))),
    FLAG_AB_PRINCIPALE              VARCHAR2(1)            null
        constraint STO_OGGETTI_C_FLAG_AB_PRINC_CC check (
            FLAG_AB_PRINCIPALE is null or (FLAG_AB_PRINCIPALE in ('S'))),
    FLAG_AL_RIDOTTA                 VARCHAR2(1)            null
        constraint STO_OGGETTI_C_FLAG_AL_RIDOT_CC check (
            FLAG_AL_RIDOTTA is null or (FLAG_AL_RIDOTTA in ('S'))),
    UTENTE                          VARCHAR2(8)            not null,
    DATA_VARIAZIONE                 DATE                   not null,
    NOTE                            VARCHAR2(2000)         null    ,
    SUCCESSIONE                     NUMBER(10)             null    ,
    PROGRESSIVO_SUDV                NUMBER(5)              null    ,
    TIPO_RAPPORTO_K                 VARCHAR2(1)            null
        constraint STO_OGGETTI_C_TIPO_RAPP_K_CC check (
            TIPO_RAPPORTO_K is null or (TIPO_RAPPORTO_K in ('D','C','E','A'))),
    PERC_DETRAZIONE                 NUMBER(6,2)            null    ,
    MESI_OCCUPATO                   NUMBER(2)              null    ,
    MESI_OCCUPATO_1SEM              NUMBER(1)              null    ,
    DA_MESE_POSSESSO                NUMBER(2)              null    ,
    DA_MESE_ESCLUSIONE              NUMBER(2)              null    ,
    DA_MESE_RIDUZIONE               NUMBER(2)              null    ,
    DA_MESE_AL_RIDOTTA              NUMBER(2)              null    ,
    constraint STO_OGGETTI_CONTRIBUENTE_PK primary key (COD_FISCALE, OGGETTO_PRATICA)
)
/

comment on table STO_OGGETTI_CONTRIBUENTE is 'SOGCO - Sto Oggetti per Contribuente'
/

-- ============================================================
--   Index: SOGCO_CONT_FK
-- ============================================================
create index SOGCO_CONT_FK on STO_OGGETTI_CONTRIBUENTE (COD_FISCALE asc)
/

-- ============================================================
--   Index: SOGCO_SOGPR_FK
-- ============================================================
create index SOGCO_SOGPR_FK on STO_OGGETTI_CONTRIBUENTE (OGGETTO_PRATICA asc)
/

-- ============================================================
--   Table: STO_RAPPORTI_TRIBUTO
-- ============================================================
create table STO_RAPPORTI_TRIBUTO
(
    PRATICA                         NUMBER(10)             not null,
    SEQUENZA                        NUMBER(4)              not null,
    COD_FISCALE                     VARCHAR2(16)           not null,
    TIPO_RAPPORTO                   VARCHAR2(1)            null
        constraint STO_RAPPORTI__TIPO_RAPPORTO_CC check (
            TIPO_RAPPORTO is null or (TIPO_RAPPORTO in ('D','C','E','A'))),
    constraint STO_RAPPORTI_TRIBUTO_PK primary key (PRATICA, SEQUENZA)
)
/

comment on table STO_RAPPORTI_TRIBUTO is 'SRATR - Sto Rapporti legati a tributi'
/

-- ============================================================
--   Index: SRATR_CONT_FK
-- ============================================================
create index SRATR_CONT_FK on STO_RAPPORTI_TRIBUTO (COD_FISCALE asc)
/

-- ============================================================
--   Index: SRATR_SPRTR_FK
-- ============================================================
create index SRATR_SPRTR_FK on STO_RAPPORTI_TRIBUTO (PRATICA asc)
/

-- ============================================================
--   Index: SRATR_UK
-- ============================================================
create unique index SRATR_UK on STO_RAPPORTI_TRIBUTO (PRATICA asc, COD_FISCALE asc, TIPO_RAPPORTO asc)
/

-- ============================================================
--   Table: STO_CIVICI_OGGETTO
-- ============================================================
create table STO_CIVICI_OGGETTO
(
    OGGETTO                         NUMBER(10)             not null
        constraint STO_CIVICI_OG_OGGETTO_CC check (
            OGGETTO >= 0),
    SEQUENZA                        NUMBER(4)              not null,
    INDIRIZZO_LOCALITA              VARCHAR2(36)           null    ,
    COD_VIA                         NUMBER(6)              null    ,
    NUM_CIV                         NUMBER(6)              null    ,
    SUFFISSO                        VARCHAR2(10)           null    ,
    constraint STO_CIVICI_OGGETTO_PK primary key (OGGETTO, SEQUENZA)
)
/

comment on table STO_CIVICI_OGGETTO is 'SCIOG - Sto Civici Oggetto'
/

-- ============================================================
--   Index: SCIOG_SOGGE_FK
-- ============================================================
create index SCIOG_SOGGE_FK on STO_CIVICI_OGGETTO (OGGETTO asc)
/

-- ============================================================
--   Index: SCIOG_ARVI_FK
-- ============================================================
create index SCIOG_ARVI_FK on STO_CIVICI_OGGETTO (COD_VIA asc)
/

-- ============================================================
--   Table: STO_DENUNCE_ICI
-- ============================================================
create table STO_DENUNCE_ICI
(
    PRATICA                         NUMBER(10)             not null,
    DENUNCIA                        NUMBER(7)              not null,
    PREFISSO_TELEFONICO             VARCHAR2(4)            null    ,
    NUM_TELEFONICO                  NUMBER(8)              null    ,
    FLAG_CF                         VARCHAR2(1)            null
        constraint STO_DENUNCE_I_FLAG_CF_CC check (
            FLAG_CF is null or (FLAG_CF in ('S'))),
    FLAG_FIRMA                      VARCHAR2(1)            null
        constraint STO_DENUNCE_I_FLAG_FIRMA_CC check (
            FLAG_FIRMA is null or (FLAG_FIRMA in ('S'))),
    FLAG_DENUNCIANTE                VARCHAR2(1)            null
        constraint STO_DENUNCE_I_FLAG_DENUNCIA_CC check (
            FLAG_DENUNCIANTE is null or (FLAG_DENUNCIANTE in ('S'))),
    PROGR_ANCI                      NUMBER(8)              null    ,
    FONTE                           NUMBER(2)              not null,
    UTENTE                          VARCHAR2(8)            not null,
    DATA_VARIAZIONE                 DATE                   not null,
    NOTE                            VARCHAR2(2000)         null    ,
    constraint STO_DENUNCE_ICI_PK primary key (PRATICA)
)
/

comment on table STO_DENUNCE_ICI is 'SDEIC - Sto Denunce ICI'
/

-- ============================================================
--   Index: SDEIC_FONT_FK
-- ============================================================
create index SDEIC_FONT_FK on STO_DENUNCE_ICI (FONTE asc)
/

-- ============================================================
--   Table: STO_DENUNCE_TASI
-- ============================================================
create table STO_DENUNCE_TASI
(
    PRATICA                         NUMBER(10)             not null,
    DENUNCIA                        NUMBER(7)              not null,
    PREFISSO_TELEFONICO             VARCHAR2(4)            null    ,
    NUM_TELEFONICO                  NUMBER(8)              null    ,
    FLAG_CF                         VARCHAR2(1)            null
        constraint STO_DENUNCE_T_FLAG_CF_CC check (
            FLAG_CF is null or (FLAG_CF in ('S'))),
    FLAG_FIRMA                      VARCHAR2(1)            null
        constraint STO_DENUNCE_T_FLAG_FIRMA_CC check (
            FLAG_FIRMA is null or (FLAG_FIRMA in ('S'))),
    FLAG_DENUNCIANTE                VARCHAR2(1)            null
        constraint STO_DENUNCE_T_FLAG_DENUNCIA_CC check (
            FLAG_DENUNCIANTE is null or (FLAG_DENUNCIANTE in ('S'))),
    PROGR_ANCI                      NUMBER(8)              null    ,
    FONTE                           NUMBER(2)              not null,
    UTENTE                          VARCHAR2(8)            not null,
    DATA_VARIAZIONE                 DATE                   not null,
    NOTE                            VARCHAR2(2000)         null    ,
    constraint STO_DENUNCE_TASI_PK primary key (PRATICA)
)
/

comment on table STO_DENUNCE_TASI is 'SDESI - Sto Denunce TASI'
/

-- ============================================================
--   Index: SDESI_FONT_FK
-- ============================================================
create index SDESI_FONT_FK on STO_DENUNCE_TASI (FONTE asc)
/

-- ============================================================
--   Table: DETTAGLI_ELABORAZIONE
-- ============================================================
create table DETTAGLI_ELABORAZIONE
(
    DETTAGLIO_ID                    NUMBER(10)             not null,
    ELABORAZIONE_ID                 NUMBER(10)             not null,
    PRATICA                         NUMBER(10)             null    ,
    COD_FISCALE                     VARCHAR2(16)           null    ,
    FLAG_SELEZIONATO                VARCHAR2(1)            null
        constraint DETTAGLI_ELAB_FLAG_SELEZION_CC check (
            FLAG_SELEZIONATO is null or (FLAG_SELEZIONATO in ('S'))),
    STAMPA_ID                       NUMBER(10)             null    ,
    DOCUMENTALE_ID                  NUMBER(10)             null    ,
    TIPOGRAFIA_ID                   NUMBER(10)             null    ,
    NOME_FILE                       VARCHAR2(255)          null    ,
    NUM_PAGINE                      NUMBER(4)              null    ,
    DOCUMENTO                       BLOB                   null    ,
    UTENTE                          VARCHAR2(8)            null    ,
    DATA_VARIAZIONE                 DATE                   null    ,
    NOTE                            VARCHAR2(2000)         null    ,
    AVVISO_AGID_ID                  NUMBER(10)             null    ,
    APPIO_ID                        NUMBER(10)             null    ,
    ANAGR_ID                        NUMBER(10)             null    ,
    CONTROLLO_AT_ID                 NUMBER(10)             null    ,
    ALLINEAMENTO_AT_ID              NUMBER(10)             null    ,
    NI                              NUMBER(10)             null    ,
    NI_EREDE                        NUMBER(10)             null    ,
    constraint DETTAGLI_ELABORAZIONE_PK primary key (DETTAGLIO_ID)
)
/

comment on table DETTAGLI_ELABORAZIONE is 'DEEL - Dettaglio Elaborazione'
/

-- ============================================================
--   Index: DEEL_ELMA_FK
-- ============================================================
create index DEEL_ELMA_FK on DETTAGLI_ELABORAZIONE (ELABORAZIONE_ID asc)
/

-- ============================================================
--   Index: DEEL_PRTR_FK
-- ============================================================
create index DEEL_PRTR_FK on DETTAGLI_ELABORAZIONE (PRATICA asc)
/

-- ============================================================
--   Index: DEEL_ATEL_FK
-- ============================================================
create index DEEL_ATEL_FK on DETTAGLI_ELABORAZIONE (STAMPA_ID asc)
/

-- ============================================================
--   Index: DEEL_ATEL2_FK
-- ============================================================
create index DEEL_ATEL2_FK on DETTAGLI_ELABORAZIONE (DOCUMENTALE_ID asc)
/

-- ============================================================
--   Index: DEEL_ATEL3_FK
-- ============================================================
create index DEEL_ATEL3_FK on DETTAGLI_ELABORAZIONE (TIPOGRAFIA_ID asc)
/

-- ============================================================
--   Index: DEEL_CONT_FK
-- ============================================================
create index DEEL_CONT_FK on DETTAGLI_ELABORAZIONE (COD_FISCALE asc)
/

-- ============================================================
--   Index: DEEL_ATEL4_FK
-- ============================================================
create index DEEL_ATEL4_FK on DETTAGLI_ELABORAZIONE (AVVISO_AGID_ID asc)
/

-- ============================================================
--   Index: DEEL_ATEL5_FK
-- ============================================================
create index DEEL_ATEL5_FK on DETTAGLI_ELABORAZIONE (APPIO_ID asc)
/

-- ============================================================
--   Index: DEEL_ATEL6_FK
-- ============================================================
create index DEEL_ATEL6_FK on DETTAGLI_ELABORAZIONE (ANAGR_ID asc)
/

-- ============================================================
--   Index: DEEL_ATEL7_FK
-- ============================================================
create index DEEL_ATEL7_FK on DETTAGLI_ELABORAZIONE (CONTROLLO_AT_ID asc)
/

-- ============================================================
--   Index: DEEL_ATEL8_FK
-- ============================================================
create index DEEL_ATEL8_FK on DETTAGLI_ELABORAZIONE (ALLINEAMENTO_AT_ID asc)
/

-- ============================================================
--   Index: DEEL_ERSO_FK
-- ============================================================
create index DEEL_ERSO_FK on DETTAGLI_ELABORAZIONE (NI asc, NI_EREDE asc)
/

-- ============================================================
--   Table: CONTRIBUENTI_CC_SOGGETTI
-- ============================================================
create table CONTRIBUENTI_CC_SOGGETTI
(
    ID                              NUMBER                 not null,
    COD_FISCALE                     VARCHAR2(16)           null    ,
    ID_SOGGETTO                     NUMBER(9)              null    ,
    UTENTE                          VARCHAR2(8)            null    ,
    DATA_VARIAZIONE                 DATE                   null    ,
    NOTE                            VARCHAR2(2000)         null    ,
    constraint CONTRIBUENTI_CC_SOGGETTI_PK primary key (ID)
)
/

comment on table CONTRIBUENTI_CC_SOGGETTI is 'COCS - Contribuenti CC Soggetti'
/

-- ============================================================
--   Index: COCS_CONT_FK
-- ============================================================
create index COCS_CONT_FK on CONTRIBUENTI_CC_SOGGETTI (COD_FISCALE asc)
/

-- ============================================================
--   Table: DATI_CONTABILI
-- ============================================================
create table DATI_CONTABILI
(
    ID_DATO_CONTABILE               NUMBER(10)             not null,
    TIPO_TRIBUTO                    VARCHAR2(5)            null    ,
    ANNO                            NUMBER(4)              null    ,
    TIPO_IMPOSTA                    VARCHAR2(1)            null
        constraint DATI_CONTABIL_TIPO_IMPOSTA_CC check (
            TIPO_IMPOSTA is null or (TIPO_IMPOSTA in ('O','V'))),
    TIPO_PRATICA                    VARCHAR2(1)            null
        constraint DATI_CONTABIL_TIPO_PRATICA_CC check (
            TIPO_PRATICA is null or (TIPO_PRATICA in ('A','D','L','I','C','K','T','V','G','S'))),
    EMISSIONE_DAL                   DATE                   null    ,
    EMISSIONE_AL                    DATE                   null    ,
    RIPARTIZIONE_DAL                DATE                   null    ,
    RIPARTIZIONE_AL                 DATE                   null    ,
    TRIBUTO                         NUMBER(4)              null    ,
    COD_TRIBUTO_F24                 VARCHAR2(4)            null    ,
    DESCRIZIONE_TITR                VARCHAR2(5)            null    ,
    STATO_PRATICA                   VARCHAR2(2)            null    ,
    ANNO_ACC                        NUMBER(4)              null    ,
    NUMERO_ACC                      NUMBER(5)              null    ,
    TIPO_OCCUPAZIONE                VARCHAR2(1)            null
        constraint DATI_CONTABIL_TIPO_OCCUPAZI_CC check (
            TIPO_OCCUPAZIONE is null or (TIPO_OCCUPAZIONE in ('P','T'))),
    constraint DATI_CONTABILI_PK primary key (ID_DATO_CONTABILE)
)
/

comment on table DATI_CONTABILI is 'DACO - Dati Contabili'
/

-- ============================================================
--   Index: DACO_TITR_FK
-- ============================================================
create index DACO_TITR_FK on DATI_CONTABILI (TIPO_TRIBUTO asc)
/

-- ============================================================
--   Index: DACO_TIST_FK
-- ============================================================
create index DACO_TIST_FK on DATI_CONTABILI (STATO_PRATICA asc)
/

-- ============================================================
--   Index: DACO_COF2_FK
-- ============================================================
create index DACO_COF2_FK on DATI_CONTABILI (COD_TRIBUTO_F24 asc, TIPO_TRIBUTO asc, DESCRIZIONE_TITR asc)
/

-- ============================================================
--   Index: DACO_COTR_FK
-- ============================================================
create index DACO_COTR_FK on DATI_CONTABILI (TRIBUTO asc)
/

-- ============================================================
--   Table: ARROTONDAMENTI_TRIBUTO
-- ============================================================
create table ARROTONDAMENTI_TRIBUTO
(
    TRIBUTO                         NUMBER(4)              not null,
    SEQUENZA                        NUMBER(4)              not null,
    ARR_CONSISTENZA                 NUMBER(4)              null    ,
    CONSISTENZA_MINIMA              NUMBER(8,2)            null    ,
    ARR_CONSISTENZA_REALE           NUMBER(4)              null    ,
    CONSISTENZA_MINIMA_REALE        NUMBER(8,2)            null    ,
    constraint ARROTONDAMENTI_TRIBUTO_PK primary key (TRIBUTO, SEQUENZA)
)
/

comment on table ARROTONDAMENTI_TRIBUTO is 'ARTR - Arrotondamenti Tributo'
/

-- ============================================================
--   Index: ARTR_COTR_FK
-- ============================================================
create index ARTR_COTR_FK on ARROTONDAMENTI_TRIBUTO (TRIBUTO asc)
/

-- ============================================================
--   Table: ARCHIVIO_VIE_ZONA
-- ============================================================
create table ARCHIVIO_VIE_ZONA
(
    COD_VIA                         NUMBER(6)              not null,
    SEQUENZA                        NUMBER(4)              not null,
    DA_NUM_CIV                      NUMBER(6)              not null,
    A_NUM_CIV                       NUMBER(6)              null    ,
    FLAG_PARI                       VARCHAR2(1)            null    ,
    FLAG_DISPARI                    VARCHAR2(1)            null    ,
    DA_CHILOMETRO                   NUMBER(8,4)            null    ,
    A_CHILOMETRO                    NUMBER(8,4)            null    ,
    LATO                            VARCHAR2(1)            null    ,
    DA_ANNO                         NUMBER(4)              null    ,
    A_ANNO                          NUMBER(4)              null    ,
    COD_ZONA                        NUMBER(2)              null    ,
    SEQUENZA_ZONA                   NUMBER(4)              null    ,
    constraint ARCHIVIO_VIE_ZONA_PK primary key (COD_VIA, SEQUENZA)
)
/

comment on table ARCHIVIO_VIE_ZONA is 'AVZA - Archivio Vie Zona'
/

-- ============================================================
--   Index: AVZA_ARVI_FK
-- ============================================================
create index AVZA_ARVI_FK on ARCHIVIO_VIE_ZONA (COD_VIA asc)
/

-- ============================================================
--   Index: AVZA_AVZE_FK
-- ============================================================
create index AVZA_AVZE_FK on ARCHIVIO_VIE_ZONA (COD_ZONA asc, SEQUENZA_ZONA asc)
/

-- ============================================================
--   Table: TARIFFE_CONVERSIONE
-- ============================================================
create table TARIFFE_CONVERSIONE
(
    TRIBUTO                         NUMBER(4)              not null,
    CATEGORIA                       NUMBER(4)              not null,
    TIPO_TARIFFA                    NUMBER(4)              not null,
    SEQUENZA                        NUMBER(4)              not null,
    COD_TRIBUTO                     NUMBER(4)              null    ,
    DA_ANNO                         NUMBER(4)              null    ,
    A_ANNO                          NUMBER(4)              null    ,
    TIPO_TRIBUTO                    VARCHAR2(5)            not null,
    ANNO                            NUMBER(4)              not null,
    CONVERTI_TRIBUTO                NUMBER(4)              null    ,
    CONVERTI_CATEGORIA              NUMBER(4)              null    ,
    CONVERTI_TIPO_TARIFFA           NUMBER(4)              not null,
    CONVERTI_PERC_DETRAZIONE        NUMBER(6,2)            null    ,
    CONVERTI_NOTE                   VARCHAR2(2000)         null    ,
    CONVERTI_MOTIVO                 VARCHAR2(2000)         null    ,
    CONVERTI_NOTE_TARIFFA           VARCHAR2(2000)         null    ,
    constraint TARIFFE_CONVERSIONE_PK primary key (TRIBUTO, CATEGORIA, TIPO_TARIFFA, SEQUENZA)
)
/

comment on table TARIFFE_CONVERSIONE is 'TARIFFE_CONVERSIONE'
/

-- ============================================================
--   Index: TACO_CATE_FK
-- ============================================================
create index TACO_CATE_FK on TARIFFE_CONVERSIONE (TRIBUTO asc, CATEGORIA asc)
/

-- ============================================================
--   Index: TACO_COTR_FK
-- ============================================================
create index TACO_COTR_FK on TARIFFE_CONVERSIONE (CONVERTI_TRIBUTO asc)
/

-- ============================================================
--   Table: SAM_RISPOSTE_PARTITA_IVA
-- ============================================================
create table SAM_RISPOSTE_PARTITA_IVA
(
    RISPOSTA_PARTITA_IVA            NUMBER(10)             not null,
    RISPOSTA_INTERROGAZIONE         NUMBER(10)             null    ,
    COD_RITORNO                     VARCHAR2(10)           not null,
    PARTITA_IVA                     VARCHAR2(11)           null    ,
    COD_ATTIVITA                    VARCHAR2(6)            null    ,
    TIPOLOGIA_CODIFICA              VARCHAR2(1)            null    ,
    STATO                           VARCHAR2(1)            null    ,
    DATA_CESSAZIONE                 DATE                   null    ,
    TIPO_CESSAZIONE                 VARCHAR2(1)            null    ,
    PARTITA_IVA_CONFLUENZA          VARCHAR2(11)           null    ,
    constraint SAM_RISPOSTE_PARTITA_IVA_PK primary key (RISPOSTA_PARTITA_IVA)
)
/

comment on table SAM_RISPOSTE_PARTITA_IVA is 'SAM_RISPOSTE_PARTITA_IVA'
/

-- ============================================================
--   Index: SRPI_SCRI_FK
-- ============================================================
create index SRPI_SCRI_FK on SAM_RISPOSTE_PARTITA_IVA (COD_RITORNO asc)
/

-- ============================================================
--   Index: SRPI_STCE_FK
-- ============================================================
create index SRPI_STCE_FK on SAM_RISPOSTE_PARTITA_IVA (TIPO_CESSAZIONE asc)
/

-- ============================================================
--   Index: SRPI_SRIS_FK
-- ============================================================
create index SRPI_SRIS_FK on SAM_RISPOSTE_PARTITA_IVA (RISPOSTA_INTERROGAZIONE asc)
/

-- ============================================================
--   Table: SAM_RISPOSTE_DITTA
-- ============================================================
create table SAM_RISPOSTE_DITTA
(
    RISPOSTA_DITTA                  NUMBER(10)             not null,
    RISPOSTA_INTERROGAZIONE         NUMBER(10)             null    ,
    COD_RITORNO                     VARCHAR2(10)           not null,
    COD_FISCALE_DITTA               VARCHAR2(16)           null    ,
    COD_CARICA                      VARCHAR2(1)            null    ,
    DATA_DECORRENZA                 DATE                   null    ,
    DATA_FINE_CARICA                DATE                   null    ,
    constraint SAM_RISPOSTE_DITTA_PK primary key (RISPOSTA_DITTA)
)
/

comment on table SAM_RISPOSTE_DITTA is 'SAM_RISPOSTE_DITTA'
/

-- ============================================================
--   Index: SRDI_SCRI_FK
-- ============================================================
create index SRDI_SCRI_FK on SAM_RISPOSTE_DITTA (COD_RITORNO asc)
/

-- ============================================================
--   Index: SRDI_SCCA_FK
-- ============================================================
create index SRDI_SCCA_FK on SAM_RISPOSTE_DITTA (COD_CARICA asc)
/

-- ============================================================
--   Index: SRDI_SRIS_FK
-- ============================================================
create index SRDI_SRIS_FK on SAM_RISPOSTE_DITTA (RISPOSTA_INTERROGAZIONE asc)
/

-- ============================================================
--   Table: SAM_RISPOSTE_RAP
-- ============================================================
create table SAM_RISPOSTE_RAP
(
    RISPOSTA_RAP                    NUMBER(10)             not null,
    RISPOSTA_INTERROGAZIONE         NUMBER(10)             null    ,
    COD_RITORNO                     VARCHAR2(10)           not null,
    COD_FISCALE_RAP                 VARCHAR2(16)           null    ,
    COD_CARICA                      VARCHAR2(1)            null    ,
    DATA_DECORRENZA                 DATE                   null    ,
    DATA_FINE_CARICA                DATE                   null    ,
    constraint SAM_RISPOSTE_RAP_PK primary key (RISPOSTA_RAP)
)
/

comment on table SAM_RISPOSTE_RAP is 'SAM_RISPOSTE_RAP'
/

-- ============================================================
--   Index: SRRA_SCCA_FK
-- ============================================================
create index SRRA_SCCA_FK on SAM_RISPOSTE_RAP (COD_CARICA asc)
/

-- ============================================================
--   Index: SRRA_SCRI_FK
-- ============================================================
create index SRRA_SCRI_FK on SAM_RISPOSTE_RAP (COD_RITORNO asc)
/

-- ============================================================
--   Index: SRRA_SRIS_FK
-- ============================================================
create index SRRA_SRIS_FK on SAM_RISPOSTE_RAP (RISPOSTA_INTERROGAZIONE asc)
/

-- ============================================================
--   Table: RUOLI_AUTOMATICI
-- ============================================================
create table RUOLI_AUTOMATICI
(
    ID                              NUMBER                 not null,
    TIPO_TRIBUTO                    VARCHAR2(5)            not null,
    DA_DATA                         DATE                   not null,
    A_DATA                          DATE                   not null,
    RUOLO                           NUMBER(10)             not null,
    UTENTE                          VARCHAR2(8)            null    ,
    DATA_VARIAZIONE                 DATE                   null    ,
    NOTE                            VARCHAR2(2000)         null    ,
    constraint RUOLI_AUTOMATICI_PK primary key (ID)
)
/

comment on table RUOLI_AUTOMATICI is 'RUAU - Ruoli Automatici'
/

-- ============================================================
--   Index: RUAU_RUOL_FK
-- ============================================================
create index RUAU_RUOL_FK on RUOLI_AUTOMATICI (RUOLO asc)
/

-- ============================================================
--   Index: RUAU_TITR_FK
-- ============================================================
create index RUAU_TITR_FK on RUOLI_AUTOMATICI (TIPO_TRIBUTO asc)
/

-- ============================================================
--   Index: RUAU_IK
-- ============================================================
create index RUAU_IK on RUOLI_AUTOMATICI (TIPO_TRIBUTO asc, DA_DATA asc, A_DATA asc)
/

-- ============================================================
--   Index: RUAU_UK
-- ============================================================
create unique index RUAU_UK on RUOLI_AUTOMATICI (TIPO_TRIBUTO asc, DA_DATA asc, RUOLO asc)
/

-- ============================================================
--   Table: LIMITI_CALCOLO
-- ============================================================
create table LIMITI_CALCOLO
(
    TIPO_TRIBUTO                    VARCHAR2(5)            not null,
    ANNO                            NUMBER(4)              not null,
    SEQUENZA                        NUMBER(4)              not null,
    LIMITE_IMPOSTA                  NUMBER(8,2)            null    ,
    LIMITE_VIOLAZIONE               NUMBER(8,2)            null    ,
    GRUPPO_TRIBUTO                  VARCHAR2(10)           null    ,
    TIPO_OCCUPAZIONE                VARCHAR2(1)            null
        constraint LIMITI_CALCOL_TIPO_OCCUPAZI_CC check (
            TIPO_OCCUPAZIONE is null or (TIPO_OCCUPAZIONE in ('P','T'))),
    LIMITE_RATA                     NUMBER(8,2)            null    ,
    constraint LIMITI_CALCOLO_PK primary key (TIPO_TRIBUTO, ANNO, SEQUENZA)
)
/

comment on table LIMITI_CALCOLO is 'Limiti calcolo'
/

-- ============================================================
--   Index: LICA_TITR_FK
-- ============================================================
create index LICA_TITR_FK on LIMITI_CALCOLO (TIPO_TRIBUTO asc)
/

-- ============================================================
--   Index: LICA_GRTR_FK
-- ============================================================
create index LICA_GRTR_FK on LIMITI_CALCOLO (TIPO_TRIBUTO asc, GRUPPO_TRIBUTO asc)
/

-- ============================================================
--   Table: AGGI
-- ============================================================
create table AGGI
(
    TIPO_TRIBUTO                    VARCHAR2(5)            not null,
    SEQUENZA                        NUMBER(4)              not null,
    DATA_INIZIO                     DATE                   not null,
    DATA_FINE                       DATE                   not null,
    ALIQUOTA                        NUMBER(6,4)            not null,
    GIORNO_INIZIO                   NUMBER(4)              not null,
    GIORNO_FINE                     NUMBER(4)              not null,
    IMPORTO_MASSIMO                 NUMBER(15,2)           null    ,
    constraint AGGI_PK primary key (TIPO_TRIBUTO, SEQUENZA)
)
/

comment on table AGGI is 'AGGI - Aggi per Accertamento Esecutivo'
/

-- ============================================================
--   Index: AGGI_TITR_FK
-- ============================================================
create index AGGI_TITR_FK on AGGI (TIPO_TRIBUTO asc)
/

-- ============================================================
--   Table: SUPPORTO_SERVIZI
-- ============================================================
create table SUPPORTO_SERVIZI
(
    ID                              NUMBER(10)             not null,
    TIPOLOGIA                       VARCHAR2(50)           not null,
    SEGNALAZIONE_INIZIALE           VARCHAR2(2000)         null    ,
    SEGNALAZIONE_ULTIMA             VARCHAR2(2000)         null    ,
    COGNOME_NOME                    VARCHAR2(150)          not null,
    COD_FISCALE                     VARCHAR2(16)           not null,
    ANNO                            NUMBER(4)              not null,
    NUM_OGGETTI                     NUMBER(6)              null    ,
    NUM_FABBRICATI                  NUMBER(6)              null    ,
    NUM_TERRENI                     NUMBER(6)              null    ,
    NUM_AREE                        NUMBER(6)              null    ,
    DIFFERENZA_IMPOSTA              NUMBER(15,2)           null    ,
    RES_STORICO_GSD_INIZIO_ANNO     VARCHAR2(9)            null    ,
    RES_STORICO_GSD_FINE_ANNO       VARCHAR2(9)            null    ,
    RESIDENTE_DA_ANNO               NUMBER(4)              null    ,
    TIPO_PERSONA                    VARCHAR2(50)           null    ,
    DATA_NAS                        DATE                   null    ,
    AIRE_STORICO_GSD_INIZIO_ANNO    VARCHAR2(4)            null    ,
    AIRE_STORICO_GSD_FINE_ANNO      VARCHAR2(4)            null    ,
    FLAG_DECEDUTO                   VARCHAR2(1)            null    ,
    DATA_DECESSO                    DATE                   null    ,
    CONTRIBUENTE_DA_FARE            VARCHAR2(1)            null    ,
    MIN_PERC_POSSESSO               NUMBER(5,2)            null    ,
    MAX_PERC_POSSESSO               NUMBER(5,2)            null    ,
    FLAG_DIFF_FABBRICATI_CATASTO    VARCHAR2(1)            null
        constraint SUPPORTO_SERV_FLAG_DIFF_FAB_CC check (
            FLAG_DIFF_FABBRICATI_CATASTO is null or (FLAG_DIFF_FABBRICATI_CATASTO in ('S'))),
    FLAG_DIFF_TERRENI_CATASTO       VARCHAR2(1)            null
        constraint SUPPORTO_SERV_FLAG_DIFF_TER_CC check (
            FLAG_DIFF_TERRENI_CATASTO is null or (FLAG_DIFF_TERRENI_CATASTO in ('S'))),
    FABBRICATI_NON_CATASTO          NUMBER(6)              null    ,
    TERRENI_NON_CATASTO             NUMBER(6)              null    ,
    CATASTO_NON_TR4_FABBRICATI      NUMBER(6)              null    ,
    CATASTO_NON_TR4_TERRENI         NUMBER(6)              null    ,
    FLAG_LIQ_ACC                    VARCHAR2(1)            null
        constraint SUPPORTO_SERV_FLAG_LIQ_ACC_CC check (
            FLAG_LIQ_ACC is null or (FLAG_LIQ_ACC in ('S'))),
    LIQUIDAZIONE_ADS                VARCHAR2(2000)         null    ,
    ITER_ADS                        VARCHAR2(2000)         null    ,
    FLAG_RAVVEDIMENTO               VARCHAR2(1)            null
        constraint SUPPORTO_SERV_FLAG_RAVVEDIM_CC check (
            FLAG_RAVVEDIMENTO is null or (FLAG_RAVVEDIMENTO in ('S'))),
    TIPO_TRIBUTO                    VARCHAR2(5)            not null,
    VERSATO                         NUMBER(15,2)           null    ,
    DOVUTO                          NUMBER(15,2)           null    ,
    DOVUTO_COMUNALE                 NUMBER(15,2)           null    ,
    DOVUTO_ERARIALE                 NUMBER(15,2)           null    ,
    DOVUTO_ACCONTO                  NUMBER(15,2)           null    ,
    DOVUTO_COMUNALE_ACCONTO         NUMBER(15,2)           null    ,
    DOVUTO_ERARIALE_ACCONTO         NUMBER(15,2)           null    ,
    DIFF_TOT_CONTR                  NUMBER(15,2)           null    ,
    DENUNCE_IMU                     NUMBER(6)              null    ,
    CODICE_ATTIVITA_CONT            VARCHAR2(5)            null    ,
    RESIDENTE_OGGI                  VARCHAR2(50)           null    ,
    AB_PRINCIPALI                   NUMBER(6)              null    ,
    PERTINENZE                      NUMBER(6)              null    ,
    ALTRI_FABBRICATI                NUMBER(6)              null    ,
    FABBRICATI_D                    NUMBER(6)              null    ,
    TERRENI                         NUMBER(6)              null    ,
    TERRENI_RIDOTTI                 NUMBER(6)              null    ,
    AREE                            NUMBER(6)              null    ,
    ABITATIVO                       NUMBER(6)              null    ,
    COMMERCIALI_ARTIGIANALI         NUMBER(6)              null    ,
    RURALI                          NUMBER(6)              null    ,
    COGNOME                         VARCHAR2(150)          null    ,
    NOME                            VARCHAR2(100)          null    ,
    COGNOME_NOME_RIC                VARCHAR2(150)          not null,
    COGNOME_RIC                     VARCHAR2(150)          null    ,
    NOME_RIC                        VARCHAR2(100)          null    ,
    UTENTE_ASSEGNATO                VARCHAR2(8)            null    ,
    UTENTE_OPERATIVO                VARCHAR2(8)            null    ,
    NUMERO                          VARCHAR2(15)           null    ,
    DATA                            DATE                   null    ,
    STATO                           VARCHAR2(2)            null    ,
    TIPO_ATTO                       NUMBER(2)              null    ,
    UTENTE                          VARCHAR2(8)            null    ,
    DATA_VARIAZIONE                 DATE                   not null,
    NOTE                            VARCHAR2(2000)         null    ,
    LIQ2_UTENTE                     VARCHAR2(8)            null    ,
    LIQ2_NUMERO                     VARCHAR2(15)           null    ,
    LIQ2_DATA                       DATE                   null    ,
    LIQ2_STATO                      VARCHAR2(2)            null    ,
    LIQ2_TIPO_ATTO                  NUMBER(2)              null    ,
    DATA_NOTIFICA                   DATE                   null    ,
    LIQ2_DATA_NOTIFICA              DATE                   null    ,
    constraint SUPPORTO_SERVIZI_PK primary key (ID)
)
/

comment on table SUPPORTO_SERVIZI is 'SUSE - Supporto Servizi'
/

-- ============================================================
--   Index: SUSE_ANNO_TITR_IK
-- ============================================================
create index SUSE_ANNO_TITR_IK on SUPPORTO_SERVIZI (ANNO asc, TIPO_TRIBUTO asc)
/

-- ============================================================
--   Index: SUSE_COGNOME_NOME_RIC_IK
-- ============================================================
create index SUSE_COGNOME_NOME_RIC_IK on SUPPORTO_SERVIZI (COGNOME_NOME_RIC asc)
/

-- ============================================================
--   Index: SUSE_COGNOME_RIC_IK
-- ============================================================
create index SUSE_COGNOME_RIC_IK on SUPPORTO_SERVIZI (COGNOME_RIC asc)
/

-- ============================================================
--   Index: SUSE_NOME_RIC_IK
-- ============================================================
create index SUSE_NOME_RIC_IK on SUPPORTO_SERVIZI (NOME_RIC asc)
/

-- ============================================================
--   Index: SUSE_COD_FISCALE_IK
-- ============================================================
create index SUSE_COD_FISCALE_IK on SUPPORTO_SERVIZI (COD_FISCALE asc)
/

-- ============================================================
--   Index: SUSE_TIAT_FK
-- ============================================================
create index SUSE_TIAT_FK on SUPPORTO_SERVIZI (TIPO_ATTO asc)
/

-- ============================================================
--   Index: SUSE_TIAT2_FK
-- ============================================================
create index SUSE_TIAT2_FK on SUPPORTO_SERVIZI (LIQ2_TIPO_ATTO asc)
/

-- ============================================================
--   Index: SUSE_TIST_FK
-- ============================================================
create index SUSE_TIST_FK on SUPPORTO_SERVIZI (STATO asc)
/

-- ============================================================
--   Index: SUSE_TIST2_FK
-- ============================================================
create index SUSE_TIST2_FK on SUPPORTO_SERVIZI (LIQ2_STATO asc)
/

-- ============================================================
--   Index: SUSE_UK
-- ============================================================
create unique index SUSE_UK on SUPPORTO_SERVIZI (TIPO_TRIBUTO asc, ANNO asc, COGNOME_NOME asc, COD_FISCALE asc)
/

-- ============================================================
--   Table: TIPI_ATTIVITA_ELABORAZIONE
-- ============================================================
create table TIPI_ATTIVITA_ELABORAZIONE
(
    TIPO_ELABORAZIONE               VARCHAR2(4)            not null,
    TIPO_ATTIVITA                   NUMBER(2)              not null,
    NUM_ORDINE                      NUMBER(5)              not null,
    constraint TIPI_ATTIVITA_ELABORAZIONE_PK primary key (TIPO_ELABORAZIONE, TIPO_ATTIVITA)
)
/

comment on table TIPI_ATTIVITA_ELABORAZIONE is 'TAEL - Tipi_Attivita_Elaborazione'
/

-- ============================================================
--   Index: TAEL_TIAL_FK
-- ============================================================
create index TAEL_TIAL_FK on TIPI_ATTIVITA_ELABORAZIONE (TIPO_ATTIVITA asc)
/

-- ============================================================
--   Index: TAEL_TIEL_FK
-- ============================================================
create index TAEL_TIEL_FK on TIPI_ATTIVITA_ELABORAZIONE (TIPO_ELABORAZIONE asc)
/

-- ============================================================
--   Table: WRK_ENC_CONTITOLARI
-- ============================================================
create table WRK_ENC_CONTITOLARI
(
    DOCUMENTO_ID                    NUMBER(10)             not null,
    PROGR_DICHIARAZIONE             NUMBER(4)              not null,
    PROGR_CONTITOLARE               NUMBER(6)              not null,
    TIPO_IMMOBILE                   VARCHAR2(1)            not null,
    PROGR_IMMOBILE                  NUMBER(6)              not null,
    NUM_ORDINE                      NUMBER(4)              not null,
    DENOMINAZIONE                   VARCHAR2(50)           null    ,
    COD_FISCALE                     VARCHAR2(16)           null    ,
    INDIRIZZO                       VARCHAR2(35)           null    ,
    NUM_CIV                         VARCHAR2(5)            null    ,
    SCALA                           VARCHAR2(5)            null    ,
    PIANO                           VARCHAR2(5)            null    ,
    INTERNO                         VARCHAR2(5)            null    ,
    CAP                             VARCHAR2(5)            null    ,
    COMUNE                          VARCHAR2(100)          null    ,
    PROVINCIA                       VARCHAR2(2)            null    ,
    PERC_POSSESSO                   NUMBER(5,2)            null    ,
    DETRAZIONE                      NUMBER(15,2)           null    ,
    FIRMA_CONTITOLARE               VARCHAR2(1)            null    ,
    TR4_NI                          NUMBER(10)             null    ,
    DATA_VARIAZIONE                 DATE                   null    ,
    UTENTE                          VARCHAR2(8)            null    ,
    SESSO                           VARCHAR2(1)            null
        constraint WRK_ENC_CONTI_SESSO_CC check (
            SESSO is null or (SESSO in ('M','F'))),
    DATA_NASCITA                    DATE                   null    ,
    COMUNE_NASCITA                  VARCHAR2(40)           null    ,
    PROVINCIA_NASCITA               VARCHAR2(2)            null    ,
    constraint WRK_ENC_CONTITOLARI_PK primary key (DOCUMENTO_ID, PROGR_DICHIARAZIONE, PROGR_CONTITOLARE, TIPO_IMMOBILE, PROGR_IMMOBILE)
)
/

comment on table WRK_ENC_CONTITOLARI is 'WECO - WRK_ENC_CONTITOLARI'
/

-- ============================================================
--   Index: WECO_WETE_FK
-- ============================================================
create index WECO_WETE_FK on WRK_ENC_CONTITOLARI (DOCUMENTO_ID asc, PROGR_DICHIARAZIONE asc)
/

-- ============================================================
--   Table: STATI_CONTRIBUENTE
-- ============================================================
create table STATI_CONTRIBUENTE
(
    ID                              NUMBER(10)             not null,
    COD_FISCALE                     VARCHAR2(16)           not null,
    TIPO_TRIBUTO                    VARCHAR2(5)            not null,
    TIPO_STATO_CONTRIBUENTE         NUMBER(2)              not null,
    DATA_STATO                      DATE                   not null,
    ANNO                            NUMBER(4)              not null,
    UTENTE                          VARCHAR2(8)            not null,
    DATA_VARIAZIONE                 DATE                   not null,
    NOTE                            VARCHAR2(2000)         null    ,
    constraint STATI_CONTRIBUENTE_PK primary key (ID)
)
/

comment on table STATI_CONTRIBUENTE is 'STCO - Stati Contribuente'
/

-- ============================================================
--   Index: STCO_CONT_FK
-- ============================================================
create index STCO_CONT_FK on STATI_CONTRIBUENTE (COD_FISCALE asc)
/

-- ============================================================
--   Index: STCO_TITR_FK
-- ============================================================
create index STCO_TITR_FK on STATI_CONTRIBUENTE (TIPO_TRIBUTO asc)
/

-- ============================================================
--   Index: STCO_TSCO_FK
-- ============================================================
create index STCO_TSCO_FK on STATI_CONTRIBUENTE (TIPO_STATO_CONTRIBUENTE asc)
/

-- ============================================================
--   Index: STATI_CONTRIBUENTE_UK
-- ============================================================
create unique index STATI_CONTRIBUENTE_UK on STATI_CONTRIBUENTE (COD_FISCALE asc, TIPO_TRIBUTO asc, TIPO_STATO_CONTRIBUENTE asc, DATA_STATO asc, ANNO asc)
/

-- ============================================================
--   Table: CREDITI_RAVVEDIMENTO
-- ============================================================
create table CREDITI_RAVVEDIMENTO
(
    PRATICA                         NUMBER(10)             not null,
    SEQUENZA                        NUMBER(4)              not null,
    DESCRIZIONE                     VARCHAR2(200)          not null,
    ANNO                            NUMBER(4)              not null,
    RATA                            NUMBER(2)              null    ,
    IMPORTO_VERSATO                 NUMBER(15,2)           not null,
    DATA_PAGAMENTO                  DATE                   not null,
    RUOLO                           NUMBER(10)             null    ,
    SANZIONI                        NUMBER(15,2)           null    ,
    INTERESSI                       NUMBER(15,2)           null    ,
    ALTRO                           NUMBER(15,2)           null    ,
    COD_IUV                         VARCHAR2(35)           null    ,
    UTENTE                          VARCHAR2(8)            null    ,
    DATA_VARIAZIONE                 DATE                   null    ,
    NOTE                            VARCHAR2(2000)         null    ,
    constraint CREDITI_RAVVEDIMENTO_PK primary key (PRATICA, SEQUENZA)
)
/

comment on table CREDITI_RAVVEDIMENTO is 'CRRA - Crediti Ravvedimento'
/

-- ============================================================
--   Index: CRRA_PRTR_FK
-- ============================================================
create index CRRA_PRTR_FK on CREDITI_RAVVEDIMENTO (PRATICA asc)
/

-- ============================================================
--   Table: DEBITI_RAVVEDIMENTO
-- ============================================================
create table DEBITI_RAVVEDIMENTO
(
    PRATICA                         NUMBER(10)             not null,
    RUOLO                           NUMBER(10)             not null,
    SCADENZA_PRIMA_RATA             DATE                   null    ,
    SCADENZA_RATA_2                 DATE                   null    ,
    SCADENZA_RATA_3                 DATE                   null    ,
    SCADENZA_RATA_4                 DATE                   null    ,
    IMPORTO_PRIMA_RATA              NUMBER(15,2)           null    ,
    IMPORTO_RATA_2                  NUMBER(15,2)           null    ,
    IMPORTO_RATA_3                  NUMBER(15,2)           null    ,
    IMPORTO_RATA_4                  NUMBER(15,2)           null    ,
    VERSATO_PRIMA_RATA              NUMBER(15,2)           null    ,
    VERSATO_RATA_2                  NUMBER(15,2)           null    ,
    VERSATO_RATA_3                  NUMBER(15,2)           null    ,
    VERSATO_RATA_4                  NUMBER(15,2)           null    ,
    UTENTE                          VARCHAR2(8)            null    ,
    DATA_VARIAZIONE                 DATE                   null    ,
    NOTE                            VARCHAR2(2000)         null    ,
    MAGGIORAZIONE_TARES_PRIMA_RATA  NUMBER(15,2)           null    ,
    MAGGIORAZIONE_TARES_RATA_2      NUMBER(15,2)           null    ,
    MAGGIORAZIONE_TARES_RATA_3      NUMBER(15,2)           null    ,
    MAGGIORAZIONE_TARES_RATA_4      NUMBER(15,2)           null    ,
    constraint DEBITI_RAVVEDIMENTO_PK primary key (PRATICA, RUOLO)
)
/

comment on table DEBITI_RAVVEDIMENTO is 'DERA - Debiti Ravvedimento'
/

-- ============================================================
--   Index: DERA_PRTR_FK
-- ============================================================
create index DERA_PRTR_FK on DEBITI_RAVVEDIMENTO (PRATICA asc)
/

-- ============================================================
--   Table: SPESE_NOTIFICA
-- ============================================================
create table SPESE_NOTIFICA
(
    TIPO_TRIBUTO                    VARCHAR2(5)            not null,
    SEQUENZA                        NUMBER(4)              not null,
    DESCRIZIONE                     VARCHAR2(200)          not null,
    DESCRIZIONE_BREVE               VARCHAR2(40)           not null,
    IMPORTO                         NUMBER(15,2)           not null,
    TIPO_NOTIFICA                   NUMBER(2)              null    ,
    constraint SPESE_NOTIFICA_PK primary key (TIPO_TRIBUTO, SEQUENZA)
)
/

comment on table SPESE_NOTIFICA is 'SPNO - Spese Notifica'
/

-- ============================================================
--   Index: SPNO_TITR_FK
-- ============================================================
create index SPNO_TITR_FK on SPESE_NOTIFICA (TIPO_TRIBUTO asc)
/

-- ============================================================
--   Index: SPNO_TINO_FK
-- ============================================================
create index SPNO_TINO_FK on SPESE_NOTIFICA (TIPO_NOTIFICA asc)
/

-- ============================================================
--   Table: ALLEGATI_TESTO
-- ============================================================
create table ALLEGATI_TESTO
(
    COMUNICAZIONE_TESTO             NUMBER                 not null,
    SEQUENZA                        NUMBER(4)              not null,
    DESCRIZIONE                     VARCHAR2(100)          null    ,
    NOME_FILE                       VARCHAR2(255)          not null,
    DOCUMENTO                       BLOB                   not null,
    UTENTE                          VARCHAR2(8)            null    ,
    DATA_VARIAZIONE                 DATE                   null    ,
    NOTE                            VARCHAR2(2000)         null    ,
    constraint ALLEGATI_TESTO_PK primary key (COMUNICAZIONE_TESTO, SEQUENZA)
)
/

comment on table ALLEGATI_TESTO is 'ALTE - Allegati Testo'
/

-- ============================================================
--   Index: ALTE_COTE_FK
-- ============================================================
create index ALTE_COTE_FK on ALLEGATI_TESTO (COMUNICAZIONE_TESTO asc)
/

-- ============================================================
--   Table: DATE_INTERESSI_VIOLAZIONI
-- ============================================================
create table DATE_INTERESSI_VIOLAZIONI
(
    TIPO_TRIBUTO                    VARCHAR2(5)            not null,
    ANNO                            NUMBER(4)              not null,
    DATA_ATTO_DA                    DATE                   not null,
    DATA_ATTO_A                     DATE                   null    ,
    DATA_INIZIO                     DATE                   null    ,
    DATA_FINE                       DATE                   null    ,
    constraint DATE_INTERESSI_VIOLAZIONI_PK primary key (TIPO_TRIBUTO, ANNO, DATA_ATTO_DA)
)
/

comment on table DATE_INTERESSI_VIOLAZIONI is 'DIVI - Date Interessi Violazioni'
/

-- ============================================================
--   Index: DIVI_TITR_FK
-- ============================================================
create index DIVI_TITR_FK on DATE_INTERESSI_VIOLAZIONI (TIPO_TRIBUTO asc)
/

-- ============================================================
--   Table: SVUOTAMENTI
-- ============================================================
create table SVUOTAMENTI
(
    COD_FISCALE                     VARCHAR2(16)           not null,
    OGGETTO                         NUMBER(10)             not null
        constraint SVUOTAMENTI_OGGETTO_CC check (
            OGGETTO >= 0),
    COD_RFID                        VARCHAR2(100)          not null,
    SEQUENZA                        NUMBER(4)              not null,
    DATA_SVUOTAMENTO                DATE                   not null,
    GPS                             VARCHAR2(100)          null    ,
    STATO                           VARCHAR2(100)          null    ,
    LATITUDINE                      NUMBER(12,8)           null    ,
    LONGITUDINE                     NUMBER(12,8)           null    ,
    QUANTITA                        NUMBER(6)              null    ,
    FLAG_EXTRA                      VARCHAR2(1)            null
        constraint SVUOTAMENTI_FLAG_EXTRA_CC check (
            FLAG_EXTRA is null or (FLAG_EXTRA in ('S'))),
    DOCUMENTO_ID                    NUMBER(10)             null    ,
    UTENTE                          VARCHAR2(8)            null    ,
    DATA_VARIAZIONE                 DATE                   null    ,
    NOTE                            VARCHAR2(2000)         null    ,
    constraint SVUOTAMENTI_PK primary key (COD_FISCALE, OGGETTO, COD_RFID, SEQUENZA)
)
/

comment on table SVUOTAMENTI is 'SVUO - Svuotamenti'
/

-- ============================================================
--   Index: SVUO_CORF_FK
-- ============================================================
create index SVUO_CORF_FK on SVUOTAMENTI (COD_FISCALE asc, OGGETTO asc, COD_RFID asc)
/

-- ============================================================
--   Index: SVUO_DOCA_FK
-- ============================================================
create index SVUO_DOCA_FK on SVUOTAMENTI (DOCUMENTO_ID asc)
/

-- ============================================================
--   Index: SVUO_DATA_IK
-- ============================================================
create index SVUO_DATA_IK on SVUOTAMENTI (DATA_SVUOTAMENTO asc)
/

-- ============================================================
--   Table: RUOLI_ECCEDENZE
-- ============================================================
create table RUOLI_ECCEDENZE
(
    ID_ECCEDENZA                    NUMBER                 not null,
    RUOLO                           NUMBER(10)             not null,
    COD_FISCALE                     VARCHAR2(16)           not null,
    TRIBUTO                         NUMBER(4)              not null,
    CATEGORIA                       NUMBER(4)              not null,
    SEQUENZA                        NUMBER(4)              not null,
    DAL                             DATE                   null    ,
    AL                              DATE                   null    ,
    FLAG_DOMESTICA                  VARCHAR2(1)            null
        constraint RUOLI_ECCEDEN_FLAG_DOMESTIC_CC check (
            FLAG_DOMESTICA is null or (FLAG_DOMESTICA in ('S'))),
    NUMERO_FAMILIARI                NUMBER(2)              null    ,
    IMPOSTA                         NUMBER(15,2)           null
        constraint RUOLI_ECCEDEN_IMPOSTA_CC check (
            IMPOSTA is null or (IMPOSTA >= 0
            )),
    ADDIZIONALE_PRO                 NUMBER(15,2)           null    ,
    IMPORTO_RUOLO                   NUMBER(15,2)           null
        constraint RUOLI_ECCEDEN_IMPORTO_RUOLO_CC check (
            IMPORTO_RUOLO is null or (IMPORTO_RUOLO >= 0
            )),
    IMPORTO_MINIMI                  NUMBER(11,5)           null    ,
    TOTALE_SVUOTAMENTI              NUMBER(15,2)           null    ,
    SUPERFICIE                      NUMBER(15,2)           null    ,
    COSTO_UNITARIO                  NUMBER(10,8)           null    ,
    COSTO_SVUOTAMENTO               NUMBER(15,2)           null    ,
    UTENTE                          VARCHAR2(8)            null    ,
    DATA_VARIAZIONE                 DATE                   null    ,
    NOTE                            VARCHAR2(2000)         null    ,
    constraint RUOLI_ECCEDENZE_PK primary key (ID_ECCEDENZA)
)
/

comment on table RUOLI_ECCEDENZE is 'RUEC - Ruoli Eccedenze'
/

-- ============================================================
--   Index: RUEC_CATE_UK
-- ============================================================
create unique index RUEC_CATE_UK on RUOLI_ECCEDENZE (RUOLO asc, COD_FISCALE asc, TRIBUTO asc, CATEGORIA asc, SEQUENZA asc)
/

-- ============================================================
--   Index: RUEC_RUOL_FK
-- ============================================================
create index RUEC_RUOL_FK on RUOLI_ECCEDENZE (RUOLO asc)
/

-- ============================================================
--   Index: RUEC_CONT_FK
-- ============================================================
create index RUEC_CONT_FK on RUOLI_ECCEDENZE (COD_FISCALE asc)
/

-- ============================================================
--   Index: RUEC_CATE_FK
-- ============================================================
create index RUEC_CATE_FK on RUOLI_ECCEDENZE (TRIBUTO asc, CATEGORIA asc)
/

-- ============================================================
--   Database name:  TR4
--   DBMS name:      ORACLE Version for SI4
--   Created on:     29/03/2019  11.25
-- ============================================================

-- ============================================================
--   Table: PARAMETRI_IMPORT
-- ============================================================
create table PARAMETRI_IMPORT
(
    NOME                VARCHAR2(60)           not null,
    PARAMETRO           CLOB                   null    ,
    constraint PARAMETRI_IMPORT_PK primary key (NOME)
)
/

comment on table PARAMETRI_IMPORT is 'PARAMETRI_IMPORT'
/

-- ============================================================
--   Table: DOCUMENTI_CARICATI
-- ============================================================
create table DOCUMENTI_CARICATI
(
    DOCUMENTO_ID        NUMBER(10)             not null,
    TITOLO_DOCUMENTO    NUMBER(4)              not null,
    NOME_DOCUMENTO      VARCHAR2(255)          not null,
    CONTENUTO           BLOB                   null    ,
    STATO               NUMBER(4)              not null,
    UTENTE              VARCHAR2(8)            not null,
    DATA_VARIAZIONE     DATE                   not null,
    NOTE                VARCHAR2(2000)         null    ,
    ENTE                VARCHAR2(4)            null    ,
    constraint DOCUMENTI_CARICATI_PK primary key (DOCUMENTO_ID)
)
/

comment on table DOCUMENTI_CARICATI is 'DOCA - Documenti Caricati'
/

-- ============================================================
--   Index: DOCA_TIDO_FK
-- ============================================================
create index DOCA_TIDO_FK on DOCUMENTI_CARICATI (TITOLO_DOCUMENTO asc)
/

-- ============================================================
--   Table: DOCUMENTI_CARICATI_MULTI
-- ============================================================
create table DOCUMENTI_CARICATI_MULTI
(
    DOCUMENTO_ID        NUMBER(10)             not null,
    DOCUMENTO_MULTI_ID  NUMBER(10)             not null,
    NOME_DOCUMENTO      VARCHAR2(255)          null    ,
    CONTENUTO           BLOB                   null    ,
    NOME_DOCUMENTO_2    VARCHAR2(255)          null    ,
    CONTENUTO_2         BLOB                   null    ,
    UTENTE              VARCHAR2(8)            null    ,
    DATA_VARIAZIONE     DATE                   null    ,
    NOTE                VARCHAR2(2000)         null    ,
    constraint DOCUMENTI_CARICATI_MULTI_PK primary key (DOCUMENTO_ID, DOCUMENTO_MULTI_ID)
)
/

comment on table DOCUMENTI_CARICATI_MULTI is 'DCMU - Documenti Caricati Multi'
/

-- ============================================================
--   Index: DCMU_DOCA_FK
-- ============================================================
create index DCMU_DOCA_FK on DOCUMENTI_CARICATI_MULTI (DOCUMENTO_ID asc)
/

CREATE TABLE ANAMIN_LAC
(
  CODPRO         NUMBER,
  CODCOM         NUMBER,
  TIPORES        NUMBER,
  CODICEFAM      NUMBER,
  CODICECONV     NUMBER,
  IDINDIVIDUO    NUMBER,
  COGNOME        VARCHAR2(200),
  NOME           VARCHAR2(200),
  CODFISCALE     VARCHAR2(16),
  SESSO          NUMBER,
  DATANAS        VARCHAR2(10),
  PRONAS         VARCHAR2(3), -- a CAstelfiorentino abbiano degli A00
  COMNAS         NUMBER,
  ESTNAS         NUMBER,
  CITTAD         NUMBER,
  NCOMP          NUMBER,
  RELPAR         NUMBER,
  STACIV         NUMBER,
  DATAISCR       VARCHAR2(10),
  IDTOPONIMO     NUMBER,
  SPECIE         VARCHAR2(200),
  DENOMINAZIONE  VARCHAR2(200),
  CIVICO         NUMBER,
  ESPONENTE      VARCHAR2(10),
  INTERNO        VARCHAR2(10),
  CAP            VARCHAR2(10),
  NSEZ           VARCHAR2(200),
  FILLER         VARCHAR2(200)
)
/
