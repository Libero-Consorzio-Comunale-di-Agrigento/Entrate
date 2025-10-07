--liquibase formatted sql
--changeset rvattolo:20250521_105333_75455_alter_daticontabili stripComments:false
--preconditions onFail:MARK_RAN
--precondition-sql-check expectedResult:0 SELECT COUNT(*) FROM user_tab_cols WHERE table_name = 'DATI_CONTABILI' AND column_name = 'COD_ENTE_COMUNALE'

alter table "DATI_CONTABILI" 
		add "COD_ENTE_COMUNALE" VARCHAR2(4) NULL
/
