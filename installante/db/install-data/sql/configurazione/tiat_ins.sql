--liquibase formatted sql
--changeset dmarotta:20250326_152438_tiat_ins stripComments:false
--validCheckSum: 1:any

ALTER TABLE tipi_atto DISABLE ALL TRIGGERS;

insert into tipi_atto (TIPO_ATTO, DESCRIZIONE)
values (90, 'RATEAZIONE');

ALTER TABLE tipi_atto ENABLE ALL TRIGGERS;
