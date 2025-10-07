--liquibase formatted sql
--changeset dmarotta:20250527_100154_80357_insert_inpa stripComments:false

insert into installazione_parametri
  (parametro, valore, descrizione)
select
  'MAX_XLS_R',
   null,
   'Numero massimo di righe esportabili in XLS con export sincrono. Valore di default 15.000.'
from dual
where not exists (select 1 from installazione_parametri where parametro = 'MAX_XLS_R');
