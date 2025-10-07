--liquibase formatted sql
--changeset dmarotta:20250326_152438_font_ins stripComments:false
--validCheckSum: 1:any

ALTER TABLE coefficienti_contabili DISABLE ALL TRIGGERS;

insert into fonti (FONTE, DESCRIZIONE)
values (20, 'VERSAMENTI DA COMPENSAZIONE');

insert into fonti (FONTE, DESCRIZIONE)
values (21, 'VERSAMENTI PAGOPA');

insert into fonti (FONTE, DESCRIZIONE)
values (22, 'DENUNCE ENTI NON COMMERCIALI');

insert into fonti (FONTE, DESCRIZIONE)
values (23, 'DUPLICA DENUNCE');

insert into fonti (FONTE, DESCRIZIONE)
values (24, 'RECUPERO RENDITE');

insert into fonti (FONTE, DESCRIZIONE)
values (25, 'DENUNCE MUI');

insert into fonti (FONTE, DESCRIZIONE)
values (26, 'DENUNCE SUCCESSIONE');

insert into fonti (FONTE, DESCRIZIONE)
values (27, 'DENUNCE DOCFA');

insert into fonti (FONTE, DESCRIZIONE)
values (0, 'DA TRASCODIFICA OGGETTI');

insert into fonti (FONTE, DESCRIZIONE)
values (1, 'SOGEI');

insert into fonti (FONTE, DESCRIZIONE)
values (2, 'ANCI-CNC');

insert into fonti (FONTE, DESCRIZIONE)
values (3, 'INSERIMENTO IMMOBILI');

insert into fonti (FONTE, DESCRIZIONE)
values (4, 'INSERIMENTO DICHIARAZIONI');

insert into fonti (FONTE, DESCRIZIONE)
values (5, 'INSERIMENTO ACCERTAMENTI');

insert into fonti (FONTE, DESCRIZIONE)
values (6, 'INSERIMENTO VERSAMENTI');

insert into fonti (FONTE, DESCRIZIONE)
values (7, 'INSERIMENTO LIQUIDAZIONI');

insert into fonti (FONTE, DESCRIZIONE)
values (8, 'INSERIMENTO CONCESSIONI');

insert into fonti (FONTE, DESCRIZIONE)
values (9, 'VERSAMENTI CON MODELLO F24');

insert into fonti (FONTE, DESCRIZIONE)
values (10, 'VERSAMENTI WEB');

ALTER TABLE coefficienti_contabili ENABLE ALL TRIGGERS;
