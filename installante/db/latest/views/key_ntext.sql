--liquibase formatted sql 
--changeset abrandolini:20250326_152401_key_ntext stripComments:false runOnChange:true 
 
CREATE OR REPLACE FORCE VIEW KEY_NTEXT AS
SELECT TABELLA, COLONNA, PK, TESTO
  FROM KEY_DICTIONARY
 where LINGUA = 'I';

