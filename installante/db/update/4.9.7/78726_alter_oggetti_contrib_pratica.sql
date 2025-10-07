--liquibase formatted sql

--changeset dmarotta_20240717_154200_000_1 stripComments:false runOnChange:true
--preconditions onFail:MARK_RAN
--precondition-sql-check expectedResult:0 SELECT COUNT(*) FROM user_tab_cols WHERE table_name = 'OGGETTI_CONTRIBUENTE' AND column_name = 'COD_EQUIP_AB_PRINCIPALE'
alter table OGGETTI_CONTRIBUENTE
    add     COD_EQUIP_AB_PRINCIPALE      NUMBER(2)              null
/

--changeset dmarotta_20240717_154200_000_2 stripComments:false runOnChange:true
--preconditions onFail:MARK_RAN
--precondition-sql-check expectedResult:0 SELECT COUNT(*) FROM user_tab_cols WHERE table_name = 'OGGETTI_PRATICA' AND column_name = 'TIPO_RIDUZIONE'
alter table OGGETTI_PRATICA
    add     TIPO_RIDUZIONE               NUMBER(4)              null
/

--changeset dmarotta_20240717_154200_000_3 stripComments:false runOnChange:true
--preconditions onFail:MARK_RAN
--precondition-sql-check expectedResult:0 SELECT COUNT(*) FROM user_tab_cols WHERE table_name = 'OGGETTI_PRATICA' AND column_name = 'TIP_TIPO_RIDUZIONE'
alter table OGGETTI_PRATICA
    add     TIP_TIPO_RIDUZIONE           NUMBER(4)              null
/

--changeset dmarotta_20240717_154200_000_4 stripComments:false runOnChange:true
--preconditions onFail:MARK_RAN
--precondition-sql-check expectedResult:0 SELECT COUNT(*) FROM user_tab_cols WHERE table_name = 'OGGETTI_PRATICA' AND column_name = 'FLAG_ALTRO'
alter table OGGETTI_PRATICA
    add     FLAG_ALTRO                   VARCHAR2(1)            null
/

--changeset dmarotta_20240717_154200_000_5 stripComments:false runOnChange:true
--preconditions onFail:MARK_RAN
--precondition-sql-check expectedResult:0 SELECT COUNT(*) FROM user_tab_cols WHERE table_name = 'OGGETTI_PRATICA' AND column_name = 'DESCRIZIONE_ALTRO'
alter table OGGETTI_PRATICA
    add     DESCRIZIONE_ALTRO            VARCHAR2(100)          null
/

--changeset dmarotta_20240717_154200_000_6 stripComments:false runOnChange:true
--preconditions onFail:MARK_RAN
--precondition-sql-check expectedResult:0 SELECT COUNT(*) FROM user_tab_cols WHERE table_name = 'OGGETTI_PRATICA' AND column_name = 'INIZIO_TERMINE_AGEVOLAZIONE'
alter table OGGETTI_PRATICA
    add     INIZIO_TERMINE_AGEVOLAZIONE  VARCHAR2(1)            null
/

--changeset dmarotta_20240717_154200_000_7 stripComments:false runOnChange:true
--preconditions onFail:MARK_RAN
--precondition-sql-check expectedResult:0 SELECT COUNT(*) FROM user_tab_cols WHERE table_name = 'OGGETTI_PRATICA' AND column_name = 'TIPO_ES_IMM_NO_UTI_DISP'
alter table OGGETTI_PRATICA
    add     TIPO_ES_IMM_NO_UTI_DISP      VARCHAR2(1)            null
/

--changeset dmarotta_20240717_154200_000_8 stripComments:false runOnChange:true
--preconditions onFail:MARK_RAN
--precondition-sql-check expectedResult:0 SELECT COUNT(*) FROM user_tab_cols WHERE table_name = 'OGGETTI_PRATICA' AND column_name = 'AUT_ES_IMM_NO_UTI_DISP'
alter table OGGETTI_PRATICA
    add     AUT_ES_IMM_NO_UTI_DISP       VARCHAR2(100)          null
/

--changeset dmarotta_20240717_154200_000_9 stripComments:false runOnChange:true
--preconditions onFail:MARK_RAN
--precondition-sql-check expectedResult:0 SELECT COUNT(*) FROM user_tab_cols WHERE table_name = 'OGGETTI_PRATICA' AND column_name = 'DATA_ES_IMM_NO_UTI_DISP'
alter table OGGETTI_PRATICA
    add     DATA_ES_IMM_NO_UTI_DISP      DATE                   null
/
