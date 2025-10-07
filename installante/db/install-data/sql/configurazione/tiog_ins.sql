--liquibase formatted sql
--changeset dmarotta:20250326_152438_tiog_ins stripComments:false
--validCheckSum: 1:any

ALTER TABLE tipi_oggetto DISABLE ALL TRIGGERS;

insert into tipi_oggetto (TIPO_OGGETTO, DESCRIZIONE)
values (1, 'TERRENO AGRICOLO');

insert into tipi_oggetto (TIPO_OGGETTO, DESCRIZIONE)
values (2, 'AREA FABBRICABILE');

insert into tipi_oggetto (TIPO_OGGETTO, DESCRIZIONE)
values (3, 'FABBRICATO CON RENDITA CATASTALE');

insert into tipi_oggetto (TIPO_OGGETTO, DESCRIZIONE)
values (4, 'FABBRICATO CON VALORE DETERMINATO');

insert into tipi_oggetto (TIPO_OGGETTO, DESCRIZIONE)
values (5, 'OGGETTO TARSU');

insert into tipi_oggetto (TIPO_OGGETTO, DESCRIZIONE)
values (6, 'OGGETTO TOSAP');

insert into tipi_oggetto (TIPO_OGGETTO, DESCRIZIONE)
values (10, 'OGGETTO CANONE UNICO');

ALTER TABLE tipi_oggetto ENABLE ALL TRIGGERS;
