--liquibase formatted sql

--changeset dmarotta:20250610_151639_72454_alter_wrk_enc_immobili_1 stripComments:false
--preconditions onFail:MARK_RAN
--precondition-sql-check expectedResult:0 SELECT COUNT(*) FROM user_tab_cols WHERE table_name = 'WRK_ENC_IMMOBILI' AND column_name = 'COD_RIDUZIONE'
alter table WRK_ENC_IMMOBILI
    add     COD_RIDUZIONE                   VARCHAR2(1)            null
/
--changeset dmarotta:20250610_151639_72454_alter_wrk_enc_immobili_2 stripComments:false
--preconditions onFail:MARK_RAN
--precondition-sql-check expectedResult:0 SELECT COUNT(*) FROM user_tab_cols WHERE table_name = 'WRK_ENC_IMMOBILI' AND column_name = 'COD_ESENZIONE'
alter table WRK_ENC_IMMOBILI
    add     COD_ESENZIONE                   VARCHAR2(1)            null
/

--changeset dmarotta:20250610_151639_72454_alter_wrk_enc_immobili_3 stripComments:false
--preconditions onFail:MARK_RAN
--precondition-sql-check expectedResult:0 SELECT COUNT(*) FROM user_tab_cols WHERE table_name = 'WRK_ENC_IMMOBILI' AND column_name = 'INIZIO_TERMINE_AGEVOLAZIONE'
alter table WRK_ENC_IMMOBILI
    add     INIZIO_TERMINE_AGEVOLAZIONE     VARCHAR2(1)            null
/

--changeset dmarotta:20250610_151639_72454_alter_wrk_enc_immobili_4 stripComments:false
--preconditions onFail:MARK_RAN
--precondition-sql-check expectedResult:0 SELECT COUNT(*) FROM user_tab_cols WHERE table_name = 'WRK_ENC_IMMOBILI' AND column_name = 'NON_UTILIZZ_DISP_TIPO'
alter table WRK_ENC_IMMOBILI
    add     NON_UTILIZZ_DISP_TIPO           VARCHAR2(1)            null
/

--changeset dmarotta:20250610_151639_72454_alter_wrk_enc_immobili_5 stripComments:false
--preconditions onFail:MARK_RAN
--precondition-sql-check expectedResult:0 SELECT COUNT(*) FROM user_tab_cols WHERE table_name = 'WRK_ENC_IMMOBILI' AND column_name = 'NON_UTILIZZ_DISP_AUTORITA'
alter table WRK_ENC_IMMOBILI
    add     NON_UTILIZZ_DISP_AUTORITA       VARCHAR2(100)          null
/

--changeset dmarotta:20250610_151639_72454_alter_wrk_enc_immobili_6 stripComments:false
--preconditions onFail:MARK_RAN
--precondition-sql-check expectedResult:0 SELECT COUNT(*) FROM user_tab_cols WHERE table_name = 'WRK_ENC_IMMOBILI' AND column_name = 'NON_UTILIZZ_DISP_DATA'
alter table WRK_ENC_IMMOBILI
    add     NON_UTILIZZ_DISP_DATA           DATE                   null
/

--changeset dmarotta:20250610_151639_72454_alter_wrk_enc_immobili_7 stripComments:false
--preconditions onFail:MARK_RAN
--precondition-sql-check expectedResult:0 SELECT COUNT(*) FROM user_tab_cols WHERE table_name = 'WRK_ENC_IMMOBILI' AND column_name = 'COMODATO_IMM_STRUTT_TIPO'
alter table WRK_ENC_IMMOBILI
    add     COMODATO_IMM_STRUTT_TIPO        VARCHAR2(1)            null
/

--changeset dmarotta:20250610_151639_72454_alter_wrk_enc_immobili_8 stripComments:false
--preconditions onFail:MARK_RAN
--precondition-sql-check expectedResult:0 SELECT COUNT(*) FROM user_tab_cols WHERE table_name = 'WRK_ENC_IMMOBILI' AND column_name = 'COMODATO_IMM_STRUTT_COM'
alter table WRK_ENC_IMMOBILI
    add     COMODATO_IMM_STRUTT_COM         VARCHAR2(100)          null
/

--changeset dmarotta:20250610_151639_72454_alter_wrk_enc_immobili_9 stripComments:false
--preconditions onFail:MARK_RAN
--precondition-sql-check expectedResult:0 SELECT COUNT(*) FROM user_tab_cols WHERE table_name = 'WRK_ENC_IMMOBILI' AND column_name = 'EQUIPARAZIONE_AP'
alter table WRK_ENC_IMMOBILI
    add     EQUIPARAZIONE_AP  VARCHAR2(1)            null
/
