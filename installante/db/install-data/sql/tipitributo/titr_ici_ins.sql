--liquibase formatted sql
--changeset dmarotta:20250326_152438_titr_ici_ins stripComments:false runOnChange:true
--validCheckSum: 1:any

ALTER TABLE tipi_tributo DISABLE ALL TRIGGERS;

INSERT INTO tipi_tributo ( TIPO_TRIBUTO, DESCRIZIONE)
VALUES ( 'ICI', 'Imposta Comunale sugli Immobili');

ALTER TABLE tipi_tributo ENABLE ALL TRIGGERS;