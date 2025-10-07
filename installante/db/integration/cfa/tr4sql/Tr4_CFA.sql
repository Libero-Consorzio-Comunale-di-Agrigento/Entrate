--liquibase formatted sql
--changeset abrandolini:20250331_123138_Tr4_CFA stripComments:false context:CFA
--validCheckSum: 1:any

DECLARE
nConta   NUMBER := 1;
BEGIN
	SELECT COUNT (*)
	  INTO nConta
	  FROM installazione_parametri
	 WHERE parametro = 'CFA_INT'
	;
	IF nConta = 0 THEN
		INSERT INTO installazione_parametri ( PARAMETRO, VALORE, DESCRIZIONE)
		VALUES ( 'CFA_INT', 'S', 'Integrazione con il nostro CFA');
	END IF;
END;
/
