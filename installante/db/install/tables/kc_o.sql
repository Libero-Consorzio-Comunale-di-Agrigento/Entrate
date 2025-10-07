--liquibase formatted sql
--changeset dmarotta:20250326_152438_Catasto_kc_o stripComments:false
--validCheckSum: 1:any

CREATE TABLE KEY_CONSTRAINT
(
 OGGETTO                                  VARCHAR2(30)	NOT NULL,
 TIPO                                     VARCHAR2(2)	NOT NULL,
 SEQUENZA                                 NUMBER(3)	NOT NULL,
 NOME                                     VARCHAR2(30)	NOT NULL,
 NOTE                                     VARCHAR2(240),
 PROCEDURA                                LONG,
 LABEL_SUCCESS                            VARCHAR2(30),
 FLAG_ABORT                               VARCHAR2(1),
 LABEL_FAILURE                            VARCHAR2(30),
 RIF_OGGETTO                              VARCHAR2(30),
 RIF_DESCRIPTOR                           VARCHAR2(240),
 CASCADE_UPDATE                           VARCHAR2(1),
 CASCADE_DELETE                           VARCHAR2(1)
)
/
CREATE UNIQUE INDEX KECO_PK on KEY_CONSTRAINT (NOME)
/
CREATE UNIQUE INDEX KECO_UK on KEY_CONSTRAINT (OGGETTO,TIPO,SEQUENZA)
/
CREATE INDEX KECO_IK on KEY_CONSTRAINT (TIPO,RIF_OGGETTO)
/

CREATE TABLE KEY_CONSTRAINT_COLUMN
(
 NOME                                     VARCHAR2(30)	NOT NULL,
 SEQUENZA                                 NUMBER(3)	NOT NULL,
 COLONNA                                  VARCHAR2(30)	NOT NULL,
 RIF_COLONNA                              VARCHAR2(30)
)
/
CREATE UNIQUE INDEX KCCO_PK on KEY_CONSTRAINT_COLUMN (NOME,COLONNA)
/

CREATE TABLE KEY_CONSTRAINT_TYPE
(
 DB_ERROR                        VARCHAR2(10) NOT NULL,
 TIPO_ERRORE                     VARCHAR2(2) NOT NULL
)
/
CREATE UNIQUE INDEX KCTY_PK on KEY_CONSTRAINT_TYPE (DB_ERROR)
/

CREATE TABLE KEY_CONSTRAINT_ERROR
(
 NOME                            VARCHAR2(30)	NOT NULL,
 TIPO_ERRORE                     VARCHAR2(2)	NOT NULL,
 ERRORE                          VARCHAR2(6)	NOT NULL,
 PRECISAZIONE                    VARCHAR2(2000)
)
/
CREATE UNIQUE INDEX KCER_PK on KEY_CONSTRAINT_ERROR (NOME,TIPO_ERRORE)
/

CREATE TABLE KEY_ERROR
(
 ERRORE                                   VARCHAR2(6) 	NOT NULL,
 DESCRIZIONE                              VARCHAR2(240) NOT NULL,
 TIPO                                     VARCHAR2(1),
 KEY                                      VARCHAR2(30),
 PRECISAZIONE                             VARCHAR2(2000),
 constraint KERR_PK primary key (ERRORE)
)
/
COMMENT ON COLUMN KEY_ERROR.DESCRIZIONE IS 'Descrizione ERRORE <NLS>'
/

create table KEY_ERROR_LOG ( ERROR_ID number NOT NULL
                           , ERROR_SESSION number
                           , ERROR_DATE date
                           , ERROR_TEXT varchar2(2000)
                           , ERROR_USER varchar2(8)
                           , ERROR_USERTEXT varchar2(2000)
                           , ERROR_TYPE varchar2(1)
                           , constraint KEEL_PK primary key (ERROR_ID)
                           )
/
comment on table KEY_ERROR_LOG is 'KEEL - Tabella degli Errori di applicazione'
/
CREATE SEQUENCE keel_sq
  START WITH 1
  MINVALUE 1
  NOCYCLE
  NOCACHE
  NOORDER
/

CREATE TABLE KEY_DICTIONARY ( TABELLA         VARCHAR2(30) NOT NULL
                            , COLONNA         VARCHAR2(30) NOT NULL
                            , PK              VARCHAR2(240) NOT NULL
                            , LINGUA          VARCHAR2(1)	NOT NULL
                            , TESTO           VARCHAR2(2000)
                            , constraint KEDI_PK primary key (TABELLA,COLONNA,PK,LINGUA)
                            )
/

create table KEY_WORD ( TESTO VARCHAR2(240) not null
                      , LINGUA VARCHAR2(1) NOT NULL
                      , TRADUZIONE VARCHAR2(2000)
                      , constraint KEWO_PK primary key (TESTO,LINGUA)
                      )
/
comment on table KEY_WORD is 'KEWO - Tabella dei testi tradotti'
/
