--liquibase formatted sql
--changeset dmarotta:20250326_152438_tico_ins stripComments:false
--validCheckSum: 1:any

ALTER TABLE tipi_contatto DISABLE ALL TRIGGERS;

insert into tipi_contatto (TIPO_CONTATTO, DESCRIZIONE)
values (34, 'CALCOLO INDIVIDUALE WEB');

insert into tipi_contatto (TIPO_CONTATTO, DESCRIZIONE)
values (1, 'LETTERA ANOMALIE SOGEI');

insert into tipi_contatto (TIPO_CONTATTO, DESCRIZIONE)
values (2, 'LETTERA IMMOBILI NON LIQUIDABILI');

insert into tipi_contatto (TIPO_CONTATTO, DESCRIZIONE)
values (3, 'LETTERA CONTROLLO DOVUTO VERSATO');

insert into tipi_contatto (TIPO_CONTATTO, DESCRIZIONE)
values (4, 'CALCOLO INDIVIDUALE');

insert into tipi_contatto (TIPO_CONTATTO, DESCRIZIONE)
values (10, 'RAVVEDIMENTO OPEROSO');

insert into tipi_contatto (TIPO_CONTATTO, DESCRIZIONE)
values (20, 'LETTERA SOLLECITO PAGAMENTO TARSU');

ALTER TABLE tipi_contatto ENABLE ALL TRIGGERS;
