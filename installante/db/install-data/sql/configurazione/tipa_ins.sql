--liquibase formatted sql
--changeset dmarotta:20250326_152438_tipa_ins stripComments:false
--validCheckSum: 1:any

ALTER TABLE tipi_parametro DISABLE ALL TRIGGERS;

INSERT INTO tipi_parametro ( TIPO_PARAMETRO, DESCRIZIONE, APPLICATIVO) VALUES ('CATASTO_DATE_EFF','Indicazione delle date efficacia di riferimento','TR4');
INSERT INTO tipi_parametro ( TIPO_PARAMETRO, DESCRIZIONE, APPLICATIVO) VALUES ('EMAIL','Email mittente','WEB');
INSERT INTO tipi_parametro ( TIPO_PARAMETRO, DESCRIZIONE, APPLICATIVO) VALUES ('SIT_CONTR','Situazione contribuente','WEB');

ALTER TABLE tipi_parametro ENABLE ALL TRIGGERS;
