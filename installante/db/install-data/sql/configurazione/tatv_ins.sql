--liquibase formatted sql
--changeset dmarotta:20250326_152438_tatv_ins stripComments:false
--validCheckSum: 1:any

ALTER TABLE tipi_attivita DISABLE ALL TRIGGERS;

insert into tipi_attivita (TIPO_ATTIVITA, DESCRIZIONE)
values (5, 'INVIO AppIO');

insert into tipi_attivita (TIPO_ATTIVITA, DESCRIZIONE)
values (7, 'CONTROLLO ANAGRAFE TRIB');

insert into tipi_attivita (TIPO_ATTIVITA, DESCRIZIONE)
values (8, 'ALLINEAMENTO ANAGRAFE TRIB');

insert into tipi_attivita (TIPO_ATTIVITA, DESCRIZIONE)
values (1, 'GENERA DOCUMENTI');

insert into tipi_attivita (TIPO_ATTIVITA, DESCRIZIONE)
values (2, 'ELABORA PER TIPOGRAFIA');

insert into tipi_attivita (TIPO_ATTIVITA, DESCRIZIONE)
values (4, 'ACQUISISCI AVVISO AgID');

insert into tipi_attivita (TIPO_ATTIVITA, DESCRIZIONE)
values (6, 'ESPORTA ANAGRAFE TRIB');

insert into tipi_attivita (TIPO_ATTIVITA, DESCRIZIONE)
values (3, 'INVIO A DOCUMENTALE');

ALTER TABLE tipi_attivita ENABLE ALL TRIGGERS;
