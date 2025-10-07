--liquibase formatted sql
--changeset dmarotta:20250326_152438_mode_ins stripComments:false
--validCheckSum: 1:any

ALTER TABLE motivi_sgravio DISABLE ALL TRIGGERS;


insert into motivi_sgravio (MOTIVO_SGRAVIO, DESCRIZIONE)
values (99, 'ECCEDENZA DI GETTITO');

ALTER TABLE motivi_sgravio ENABLE ALL TRIGGERS;
