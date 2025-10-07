--liquibase formatted sql
--changeset dmarotta:20250422_152800_78458_80008_perequativa_ur3 endDelimiter:/

DECLARE
    nConta NUMBER := 1;
BEGIN
    SELECT COUNT(*)
    INTO nConta
    FROM componenti_perequative
    WHERE ANNO = 2025 AND COMPONENTE = 'UR3';

    IF nConta = 0 THEN
        INSERT INTO componenti_perequative (ANNO, COMPONENTE, DESCRIZIONE, IMPORTO)
        VALUES (2025, 'UR3', 'Copertura delle agevolazioni riconosciute ai beneficiari di bonus sociale', 6.00);
    END IF;

END;
/

