--liquibase formatted sql
--changeset dmarotta:20250326_152438_ogtr_ins stripComments:false
--validCheckSum: 1:any

ALTER TABLE oggetti_tributo DISABLE ALL TRIGGERS;

insert into oggetti_tributo (TIPO_TRIBUTO, TIPO_OGGETTO)
values ('ICI', 1);

insert into oggetti_tributo (TIPO_TRIBUTO, TIPO_OGGETTO)
values ('ICI', 2);

insert into oggetti_tributo (TIPO_TRIBUTO, TIPO_OGGETTO)
values ('ICI', 3);

insert into oggetti_tributo (TIPO_TRIBUTO, TIPO_OGGETTO)
values ('ICI', 4);

insert into oggetti_tributo (TIPO_TRIBUTO, TIPO_OGGETTO)
values ('TARSU', 3);

insert into oggetti_tributo (TIPO_TRIBUTO, TIPO_OGGETTO)
values ('TARSU', 5);

insert into oggetti_tributo (TIPO_TRIBUTO, TIPO_OGGETTO)
values ('CUNI', 6);

insert into oggetti_tributo (TIPO_TRIBUTO, TIPO_OGGETTO)
values ('CUNI', 10);

ALTER TABLE oggetti_tributo ENABLE ALL TRIGGERS;
