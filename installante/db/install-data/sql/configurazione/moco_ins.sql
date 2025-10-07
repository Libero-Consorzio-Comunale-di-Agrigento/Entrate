--liquibase formatted sql
--changeset dmarotta:20250326_152438_moco_ins stripComments:false
--validCheckSum: 1:any

ALTER TABLE motivi_compensazione DISABLE ALL TRIGGERS;

insert into motivi_compensazione (MOTIVO_COMPENSAZIONE, DESCRIZIONE)
values (99, 'ECCEDENZA DI GETTITO');

ALTER TABLE motivi_compensazione ENABLE ALL TRIGGERS;
