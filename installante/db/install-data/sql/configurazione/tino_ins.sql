--liquibase formatted sql
--changeset dmarotta:20250326_152438_tino_ins stripComments:false
--validCheckSum: 1:any

ALTER TABLE tipi_notifica DISABLE ALL TRIGGERS;

insert into tipi_notifica (TIPO_NOTIFICA, DESCRIZIONE, FLAG_MODIFICABILE)
values (1, 'PEC', 'S');

insert into tipi_notifica (TIPO_NOTIFICA, DESCRIZIONE, FLAG_MODIFICABILE)
values (2, 'RACCOMANDATA AR', null);

insert into tipi_notifica (TIPO_NOTIFICA, DESCRIZIONE, FLAG_MODIFICABILE)
values (3, 'MESSI', 'S');

insert into tipi_notifica (TIPO_NOTIFICA, DESCRIZIONE, FLAG_MODIFICABILE)
values (4, 'PND', 'S');

insert into tipi_notifica (TIPO_NOTIFICA, DESCRIZIONE, FLAG_MODIFICABILE)
values (81, 'PND - APPIO', null);

insert into tipi_notifica (TIPO_NOTIFICA, DESCRIZIONE, FLAG_MODIFICABILE)
values (82, 'PND - SMS', null);

insert into tipi_notifica (TIPO_NOTIFICA, DESCRIZIONE, FLAG_MODIFICABILE)
values (83, 'PND - EMAIL', null);

insert into tipi_notifica (TIPO_NOTIFICA, DESCRIZIONE, FLAG_MODIFICABILE)
values (84, 'PND - PEC', null);

insert into tipi_notifica (TIPO_NOTIFICA, DESCRIZIONE, FLAG_MODIFICABILE)
values (85, 'PND - RACCOMANDATA AR', null);

insert into tipi_notifica (TIPO_NOTIFICA, DESCRIZIONE, FLAG_MODIFICABILE)
values (86, 'PND - LETTERA 890', null);

insert into tipi_notifica (TIPO_NOTIFICA, DESCRIZIONE, FLAG_MODIFICABILE)
values (87, 'PND - RACCOMANDATA SEMPLICE', null);

ALTER TABLE tipi_notifica ENABLE ALL TRIGGERS;
