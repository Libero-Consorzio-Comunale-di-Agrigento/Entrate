--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_carica_dic_notai_verifica stripComments:false runOnChange:true 
 
create or replace function F_CARICA_DIC_NOTAI_VERIFICA
(P_DOCUMENTO_ID IN NUMBER)
/********************************************************
  FUNCTION VERIFICA_PRE_ELABORAZIONE
     STATUS:
     - 0: OK
     - 1: GAP nella sequenza di caricamento.
     - 2: Impossibile caricare un file cronologicamente precedente all'ultimo caricato
********************************************************/
  RETURN NUMBER IS
  W_STATUS              NUMBER(1) := 0;
  W_NEW_DOCUMENTO_BLOB  BLOB;
  W_NEW_DOCUMENTO_CLOB  CLOB;
  W_LAST_DOCUMENTO_BLOB BLOB;
  W_LAST_DOCUMENTO_CLOB CLOB;
  W_LAST_DOC_DATA_INIZIALE VARCHAR2(10);
  W_LAST_DOC_N_FILE        VARCHAR2(2);
  W_LAST_DOC_N_FILE_TOT    VARCHAR2(2);
  W_NEW_DOC_DATA_INIZIALE VARCHAR2(10);
  W_NEW_DOC_N_FILE        VARCHAR2(2);
  W_NEW_DOC_N_FILE_TOT    VARCHAR2(2);
  W_MONTHS NUMBER := 0;
BEGIN
  -- Ultimo documento caricato
  SELECT CONTENUTO
    INTO W_LAST_DOCUMENTO_BLOB
    FROM (SELECT DOC.CONTENUTO,
                 ROW_NUMBER() OVER(ORDER BY DOC.DATA_VARIAZIONE DESC) RN
            FROM DOCUMENTI_CARICATI DOC
           WHERE DOC.TITOLO_DOCUMENTO = 1
             AND DOC.STATO = 2)
   WHERE RN = 1;
  -- File del documento da caricare
  SELECT DOC.CONTENUTO
    INTO W_NEW_DOCUMENTO_BLOB
    FROM DOCUMENTI_CARICATI DOC
   WHERE DOC.DOCUMENTO_ID = P_DOCUMENTO_ID;
  -- Se esiste alemno un documento caricato
  IF (W_LAST_DOCUMENTO_BLOB IS NOT NULL) THEN
    W_LAST_DOCUMENTO_CLOB := F_BLOB2CLOB(W_LAST_DOCUMENTO_BLOB);
    W_NEW_DOCUMENTO_CLOB  := F_BLOB2CLOB(W_NEW_DOCUMENTO_BLOB);
    -- Eliminazione del prefisso XML <?xml version="1.0" encoding="ISO-8859-1"?>
    W_LAST_DOCUMENTO_CLOB := SUBSTR(W_LAST_DOCUMENTO_CLOB, 44);
    W_NEW_DOCUMENTO_CLOB  := SUBSTR(W_NEW_DOCUMENTO_CLOB, 44);
    -- Informazioni sull'ultimo caricamento
    SELECT EXTRACTVALUE(VALUE(RICHIESTA),
                        '/DatiRichiesta/DataIniziale',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') DATAINZIALE,
           EXTRACTVALUE(VALUE(RICHIESTA),
                        '/DatiRichiesta/N_File',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') NFILE,
           EXTRACTVALUE(VALUE(RICHIESTA),
                        '/DatiRichiesta/N_File_Tot',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') NFILETOT
      INTO W_LAST_DOC_DATA_INIZIALE,
           W_LAST_DOC_N_FILE,
           W_LAST_DOC_N_FILE_TOT
      FROM TABLE(XMLSEQUENCE(EXTRACT(XMLTYPE(W_LAST_DOCUMENTO_CLOB),
                                     '/DatiOut/DatiRichiesta',
                                     'xmlns="http://www.agenziaterritorio.it/ICI.xsd"'))) RICHIESTA;
    -- Informazioni sul file da caricare
    SELECT EXTRACTVALUE(VALUE(RICHIESTA),
                        '/DatiRichiesta/DataIniziale',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') DATAINZIALE,
           EXTRACTVALUE(VALUE(RICHIESTA),
                        '/DatiRichiesta/N_File',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') NFILE,
           EXTRACTVALUE(VALUE(RICHIESTA),
                        '/DatiRichiesta/N_File_Tot',
                        'xmlns="http://www.agenziaterritorio.it/ICI.xsd"') NFILETOT
      INTO W_NEW_DOC_DATA_INIZIALE, W_NEW_DOC_N_FILE, W_NEW_DOC_N_FILE_TOT
      FROM TABLE(XMLSEQUENCE(EXTRACT(XMLTYPE(W_NEW_DOCUMENTO_CLOB),
                                     '/DatiOut/DatiRichiesta',
                                     'xmlns="http://www.agenziaterritorio.it/ICI.xsd"'))) RICHIESTA;
    -- Inizio controlli
    W_MONTHS := FLOOR(MONTHS_BETWEEN(TO_DATE(W_NEW_DOC_DATA_INIZIALE,
                                             'YYYY-MM-DD'),
                                     TO_DATE(W_LAST_DOC_DATA_INIZIALE,
                                             'YYYY-MM-DD')));
    -- Se la differenza tra le date è 1: OK
    IF (W_MONTHS = 1) THEN
      W_STATUS := 0;
    ELSIF (W_MONTHS = 0) THEN
      -- Stessad data => fornitura multipla nell'anno. Si valuta w_new_doc_n_file
      IF (W_NEW_DOC_N_FILE - W_LAST_DOC_N_FILE = 1) THEN
        -- Fornitura successiva: OK
        W_STATUS := 0;
      ELSIF (W_NEW_DOC_N_FILE - W_LAST_DOC_N_FILE > 1) THEN
        -- Mancano forniture intermedie
        W_STATUS := 1;
      ELSIF (W_NEW_DOC_N_FILE - W_LAST_DOC_N_FILE < 0) THEN
        -- Fornitura precedente: ERRORE!!!
        W_STATUS := 2;
      END IF;
    ELSIF (W_MONTHS > 1) THEN
      -- Mancano forniture intermedie
      W_STATUS := 1;
    ELSIF (W_MONTHS < 0) THEN
      -- Fornitura precedente: ERRORE!!!
      W_STATUS := 2;
    END IF;
  END IF;
  RETURN W_STATUS;
EXCEPTION
  WHEN OTHERS THEN
    RETURN 0;
END;
/* End Function: F_CARICA_DIC_NOTAI_VERIFICA */
/

