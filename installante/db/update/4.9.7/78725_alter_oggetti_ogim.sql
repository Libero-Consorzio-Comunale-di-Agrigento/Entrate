--liquibase formatted sql

--changeset rvattolo:20250603_112233_78725_alter_oggetti_ogim_imposta stripComments:false
--preconditions onFail:MARK_RAN
--precondition-sql-check expectedResult:0 SELECT COUNT(*) FROM user_tab_cols WHERE table_name = 'OGGETTI_OGIM' AND column_name = 'IMPOSTA'
alter table OGGETTI_OGIM 
      add imposta NUMBER(15,2) NULL
/

--changeset rvattolo:20250603_112233_78725_alter_oggetti_ogim_imposta_acc stripComments:false
--preconditions onFail:MARK_RAN
--precondition-sql-check expectedResult:0 SELECT COUNT(*) FROM user_tab_cols WHERE table_name = 'OGGETTI_OGIM' AND column_name = 'IMPOSTA_ACCONTO'
alter table OGGETTI_OGIM 
      add imposta_acconto NUMBER(15,2) NULL
/

--changeset rvattolo:20250603_112233_78725_alter_oggetti_ogim_imposta_erar stripComments:false
--preconditions onFail:MARK_RAN
--precondition-sql-check expectedResult:0 SELECT COUNT(*) FROM user_tab_cols WHERE table_name = 'OGGETTI_OGIM' AND column_name = 'IMPOSTA_ERARIALE'
alter table OGGETTI_OGIM 
      add imposta_erariale NUMBER(15,2) NULL
/

--changeset rvattolo:20250603_112233_78725_alter_oggetti_ogim_imposta_erar_acc stripComments:false
--preconditions onFail:MARK_RAN
--precondition-sql-check expectedResult:0 SELECT COUNT(*) FROM user_tab_cols WHERE table_name = 'OGGETTI_OGIM' AND column_name = 'IMPOSTA_ERARIALE_ACCONTO'
alter table OGGETTI_OGIM 
      add imposta_erariale_acconto NUMBER(15,2) NULL
/

--changeset rvattolo:20250603_112233_78725_alter_oggetti_ogim_dovuta stripComments:false
--preconditions onFail:MARK_RAN
--precondition-sql-check expectedResult:0 SELECT COUNT(*) FROM user_tab_cols WHERE table_name = 'OGGETTI_OGIM' AND column_name = 'IMPOSTA_DOVUTA'
alter table OGGETTI_OGIM
      add imposta_dovuta NUMBER(15,2) NULL
/

--changeset rvattolo:20250603_112233_78725_alter_oggetti_ogim_dovuta_acc stripComments:false
--preconditions onFail:MARK_RAN
--precondition-sql-check expectedResult:0 SELECT COUNT(*) FROM user_tab_cols WHERE table_name = 'OGGETTI_OGIM' AND column_name = 'IMPOSTA_DOVUTA_ACCONTO'
alter table OGGETTI_OGIM 
      add imposta_dovuta_acconto NUMBER(15,2) NULL
/

--changeset rvattolo:20250603_112233_78725_alter_oggetti_ogim_dovuta_erar stripComments:false
--preconditions onFail:MARK_RAN
--precondition-sql-check expectedResult:0 SELECT COUNT(*) FROM user_tab_cols WHERE table_name = 'OGGETTI_OGIM' AND column_name = 'IMPOSTA_ERARIALE_DOVUTA'
alter table OGGETTI_OGIM 
      add imposta_erariale_dovuta NUMBER(15,2) NULL
/

--changeset rvattolo:20250603_112233_78725_alter_oggetti_ogim_dovuta_erar_acc stripComments:false
--preconditions onFail:MARK_RAN
--precondition-sql-check expectedResult:0 SELECT COUNT(*) FROM user_tab_cols WHERE table_name = 'OGGETTI_OGIM' AND column_name = 'IMPOSTA_ERARIALE_DOVUTA_ACC'
alter table OGGETTI_OGIM 
      add imposta_erariale_dovuta_acc NUMBER(15,2) NULL
/

--changeset rvattolo:20250603_112233_78725_alter_oggetti_ogim_mesi_riduzione stripComments:false
--preconditions onFail:MARK_RAN
--precondition-sql-check expectedResult:0 SELECT COUNT(*) FROM user_tab_cols WHERE table_name = 'OGGETTI_OGIM' AND column_name = 'MESI_RIDUZIONE'
alter table OGGETTI_OGIM 
      add mesi_riduzione NUMBER(2,0) NULL
/

--changeset rvattolo:20250603_112233_78725_alter_oggetti_ogim_mesi_esclusione stripComments:false
--preconditions onFail:MARK_RAN
--precondition-sql-check expectedResult:0 SELECT COUNT(*) FROM user_tab_cols WHERE table_name = 'OGGETTI_OGIM' AND column_name = 'MESI_ESCLUSIONE'
alter table OGGETTI_OGIM 
      add mesi_esclusione NUMBER(2,0) NULL
/

--changeset rvattolo:20250603_112233_78725_alter_oggetti_ogim_mesi_aliquota_ridotta stripComments:false
--preconditions onFail:MARK_RAN
--precondition-sql-check expectedResult:0 SELECT COUNT(*) FROM user_tab_cols WHERE table_name = 'OGGETTI_OGIM' AND column_name = 'MESI_ALIQUOTA_RIDOTTA'
alter table OGGETTI_OGIM 
      add mesi_aliquota_ridotta NUMBER(2,0) NULL
/
