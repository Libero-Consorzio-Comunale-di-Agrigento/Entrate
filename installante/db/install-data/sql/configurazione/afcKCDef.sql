--liquibase formatted sql
--changeset dmarotta:20250326_152438_afcKCDef stripComments:false
--validCheckSum: 1:any

--******************************************************************************
-- NOME:        afcKC.def
-- DESCRIZIONE: Predisposizione minimale "Base Dati Appoggio" per gestione Constraint Error e Multilinguismo.
--
-- ANNOTAZIONI: Attivata per Default nella installazione del file afcKC.def
-- REVISIONI:
-- Rev.  Data        Autore  Descrizione
-- ----  ----------  ------  ----------------------------------------------------
-- 1     23/02/2006  MF      Inclusione della gestione delle Revisioni.
-- 2     04/04/2006  MF      Tolta variabile $$ in testo proposto per A02291 e A02292.
-- 3     08/09/2006  MF      Modifica nome da Si4KCDef.sql in afcKCDef.sql.
-- 4     02/10/2006  MM      Commento con --.
--******************************************************************************

-- Inserimento KEY_CONSTRAINT_TYPE di Default

insert into key_constraint_type (db_error, tipo_errore) values('1','UK');
insert into key_constraint_type (db_error, tipo_errore) values('2290','CC');
insert into key_constraint_type (db_error, tipo_errore) values('2291','FK');
insert into key_constraint_type (db_error, tipo_errore) values('2292','FR');

-- Inserimento KEY_CONSTRAINT_ERROR di Default

insert into key_constraint_error (nome, tipo_errore, errore) values('UK','UK','A00001');
insert into key_constraint_error (nome, tipo_errore, errore) values('CC','CC','A02290');
insert into key_constraint_error (nome, tipo_errore, errore) values('FK','FK','A02291');
insert into key_constraint_error (nome, tipo_errore, errore) values('FR','FR','A02292');

-- Inserimento KEY_ERROR di Default

insert into key_error (errore, descrizione, tipo) values('A00001','Registrazione gia'' presente $table:in','E');
insert into key_error (errore, descrizione, tipo) values('A02290','Registrazione $table:in con informazioni incongruenti','E');
insert into key_error (errore, descrizione, tipo) values('A02291','Riferimento $table:di non presente $ref_table:in','E');
insert into key_error (errore, descrizione, tipo) values('A02292','Esistono riferimenti $table:in alla registrazione $ref_table:di', 'E');
