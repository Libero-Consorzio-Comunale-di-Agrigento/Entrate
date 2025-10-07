--liquibase formatted sql
--changeset dmarotta:20250326_152438_titr_ins_tarsu stripComments:false runOnChange:true
--validCheckSum: 1:any

ALTER TABLE tipi_tributo DISABLE ALL TRIGGERS;

INSERT INTO tipi_tributo ( TIPO_TRIBUTO, DESCRIZIONE)
VALUES ( 'TARSU', 'Tassa per lo smaltimento dei Rifiuti Solidi Urbani');

ALTER TABLE tipi_tributo ENABLE ALL TRIGGERS;