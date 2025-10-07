--liquibase formatted sql
--changeset dmarotta:20250326_152438_cc_tipi_nota_ins stripComments:false
--validCheckSum: 1:any

INSERT INTO CC_TIPI_NOTA VALUES('F','A','accatastamento');
INSERT INTO CC_TIPI_NOTA VALUES('F','D','voltura');
INSERT INTO CC_TIPI_NOTA VALUES('F','I','impianto');
INSERT INTO CC_TIPI_NOTA VALUES('F','N','voltura');
INSERT INTO CC_TIPI_NOTA VALUES('F','R','voltura automatica da conservatorie');
INSERT INTO CC_TIPI_NOTA VALUES('F','V','variazione');
INSERT INTO CC_TIPI_NOTA VALUES('T','A','voltura provenienti da tabelle di variazione o nota di variazione');
INSERT INTO CC_TIPI_NOTA VALUES('T','B','nota di voltura o frazionamento proveniente da note di voltura');
INSERT INTO CC_TIPI_NOTA VALUES('T','C','voltura');
INSERT INTO CC_TIPI_NOTA VALUES('T','D','voltura');
INSERT INTO CC_TIPI_NOTA VALUES('T','F','frazionamento');
INSERT INTO CC_TIPI_NOTA VALUES('T','I','impianto');
INSERT INTO CC_TIPI_NOTA VALUES('T','M','tipo mappale');
INSERT INTO CC_TIPI_NOTA VALUES('T','N','nota di voltura o variazione');
INSERT INTO CC_TIPI_NOTA VALUES('T','P','tipo particellare');
INSERT INTO CC_TIPI_NOTA VALUES('T','R','voltura automatica da conservatorie');
INSERT INTO CC_TIPI_NOTA VALUES('T','T','tabella di variazione');
INSERT INTO CC_TIPI_NOTA VALUES('T','V','voltura');
INSERT INTO CC_TIPI_NOTA VALUES('T','X','variazione territoriale');
INSERT INTO CC_TIPI_NOTA VALUES('T','W','voltura o variazione');
