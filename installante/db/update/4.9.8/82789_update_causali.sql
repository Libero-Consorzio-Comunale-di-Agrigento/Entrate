--liquibase formatted sql
--changeset dmarotta:20250910_145235_82789_update_causali stripComments:false

update causali caus
   set caus.descrizione = 'Versamento con codici violazione Pratica non presente o incongruente'
 where caus.tipo_tributo = 'TARSU'
   and caus.causale = '50350';
