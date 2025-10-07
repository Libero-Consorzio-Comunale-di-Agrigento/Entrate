--liquibase formatted sql
--changeset dmarotta:20250701_121627_80258_insert_inpa stripComments:false

insert into installazione_parametri
  (parametro, valore, descrizione)
select
  'PORT_INT',
   null,
   'Integrazione con PortaleWEB'
from dual
where not exists (select 1 from installazione_parametri where parametro = 'PORT_INT');
