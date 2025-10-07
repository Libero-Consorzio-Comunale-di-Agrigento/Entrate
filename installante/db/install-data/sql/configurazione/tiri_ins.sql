--liquibase formatted sql
--changeset dmarotta:20250326_152438_tiri_ins stripComments:false
--validCheckSum: 1:any

ALTER TABLE tipi_richiedente DISABLE ALL TRIGGERS;

INSERT INTO tipi_richiedente ( TIPO_RICHIEDENTE, DESCRIZIONE)
VALUES ( 1, 'UFFICIO TRIBUTI');
INSERT INTO tipi_richiedente ( TIPO_RICHIEDENTE, DESCRIZIONE)
VALUES ( 2, 'CONTRIBUENTE');

ALTER TABLE tipi_richiedente ENABLE ALL TRIGGERS;
