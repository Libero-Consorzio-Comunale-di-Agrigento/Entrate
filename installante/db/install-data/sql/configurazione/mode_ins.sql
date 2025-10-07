--liquibase formatted sql
--changeset dmarotta:20250326_152438_mode_ins stripComments:false
--validCheckSum: 1:any

ALTER TABLE motivi_detrazione DISABLE ALL TRIGGERS;

insert into motivi_detrazione (TIPO_TRIBUTO, MOTIVO_DETRAZIONE, DESCRIZIONE)
values ('ICI', 97, 'DETRAZIONE DA ACCERTAMENTO SU ABITAZIONE PRINCIPALE');

insert into motivi_detrazione (TIPO_TRIBUTO, MOTIVO_DETRAZIONE, DESCRIZIONE)
values ('ICI', 98, 'AGGIORNAMENTO DETRAZIONE BASE (MESI POSSESSO = 12)');

insert into motivi_detrazione (TIPO_TRIBUTO, MOTIVO_DETRAZIONE, DESCRIZIONE)
values ('ICI', 99, 'DETRAZIONI PER ANNI SUCCESSIVI A DICH. CON MESI POS. < 12');

ALTER TABLE motivi_detrazione ENABLE ALL TRIGGERS;
