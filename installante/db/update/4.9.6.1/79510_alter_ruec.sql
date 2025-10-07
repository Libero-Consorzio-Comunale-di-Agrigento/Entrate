--liquibase formatted sql
--changeset dmarotta:20250424_095109_79510_alter_ruec stripComments:false
--preconditions onFail:MARK_RAN
--precondition-sql-check expectedResult:0 SELECT COUNT(*) FROM user_tab_cols WHERE table_name = 'RUOLI_ECCEDENZE' AND column_name = 'SVUOTAMENTI_SUPERFICIE'
--validCheckSum: 1:any

alter table RUOLI_ECCEDENZE
    add     SVUOTAMENTI_SUPERFICIE  NUMBER(15,2)           null
/

alter table RUOLI_ECCEDENZE
    add     COSTO_SUPERFICIE        NUMBER(15,2)           null
/

alter table RUOLI_ECCEDENZE
    add     ECCEDENZA_SVUOTAMENTI   NUMBER(15,2)           null
/

