--liquibase formatted sql
--changeset dmarotta:20250326_152438_tist_ins stripComments:false
--validCheckSum: 1:any

ALTER TABLE tipi_stato DISABLE ALL TRIGGERS;

insert into tipi_stato (TIPO_STATO, DESCRIZIONE, NUM_ORDINE)
values ('A', 'Annullato', null);

insert into tipi_stato (TIPO_STATO, DESCRIZIONE, NUM_ORDINE)
values ('D', 'Definitivo', null);

insert into tipi_stato (TIPO_STATO, DESCRIZIONE, NUM_ORDINE)
values ('I', 'Inesigibile', null);

insert into tipi_stato (TIPO_STATO, DESCRIZIONE, NUM_ORDINE)
values ('P', 'Provvisorio', null);

insert into tipi_stato (TIPO_STATO, DESCRIZIONE, NUM_ORDINE)
values ('R', 'Revocato', null);

ALTER TABLE tipi_stato ENABLE ALL TRIGGERS;
