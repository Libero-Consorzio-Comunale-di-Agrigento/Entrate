--liquibase formatted sql
--changeset dmarotta:20250326_152438_stat_ins stripComments:false
--validCheckSum: 1:any

ALTER TABLE stati_attivita DISABLE ALL TRIGGERS;

INSERT INTO stati_attivita ( STATO_ATTIVITA, DESCRIZIONE) VALUES (0,'IN ATTESA');
INSERT INTO stati_attivita ( STATO_ATTIVITA, DESCRIZIONE) VALUES (1,'IN CORSO');
INSERT INTO stati_attivita ( STATO_ATTIVITA, DESCRIZIONE) VALUES (2,'TERMINATA');
INSERT INTO stati_attivita ( STATO_ATTIVITA, DESCRIZIONE) VALUES (3,'ERRORE');

ALTER TABLE stati_attivita ENABLE ALL TRIGGERS;
