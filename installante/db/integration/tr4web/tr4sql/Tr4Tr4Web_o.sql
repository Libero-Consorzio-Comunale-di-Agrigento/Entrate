--liquibase formatted sql
--changeset dmarotta:20250326_152438_Tr4Tr4Web_o stripComments:false
--validCheckSum: 1:any

CREATE TABLE TR4WEB_ABILITAZIONI
(
  ID_ABILITAZIONE  NUMBER(10)              NOT NULL,
  USERNAME         VARCHAR2(30)            NOT NULL,
  COD_FISCALE      VARCHAR2(16)            NOT NULL
)
/
