--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_notai_to_html stripComments:false runOnChange:true 
 
CREATE OR REPLACE FUNCTION F_NOTAI_TO_HTML
( P_DOCUMENTO_ID IN NUMBER,
  P_NUMERO_NOTA  NUMBER DEFAULT NULL
)
  RETURN CLOB IS
  W_XML_NON_VALIDO         NUMBER(1);
  C_XSLDATA                CLOB;
  XMLDATA                  XMLTYPE;
  XMLDATA_NOTA             XMLTYPE;
  XMLDATA_NOTA_RETTIFICATA XMLTYPE;
  XSLDATA                  XMLTYPE;
  HTML                     XMLTYPE;
  ERRORE EXCEPTION;
  W_ERRORE                   VARCHAR2(2000);
  W_DOCUMENTO_ID_RETTIFICATA NUMBER;
  W_NUMERO_NOTA_RETTIFICATA  NUMBER;
  -- Recupera tutte le rettifiche di una data nota
  CURSOR SEL_RETT(P_NUMERO_NOTA NUMBER) IS
    SELECT DOC.DOCUMENTO_ID, TO_NUMBER(RETT.NUMERO_NOTA) NUMERO_NOTA
      FROM DOCUMENTI_CARICATI DOC,
           XMLTABLE(XMLNAMESPACES(DEFAULT 'http://www.agenziaterritorio.it/ICI.xsd',
                                  'http://www.agenziaterritorio.it/ICI.xsd' AS
                                  "nms"),
                    '/DatiOut/DatiPresenti/Variazioni/Variazione/Trascrizione'
                    PASSING XMLTYPE(F_BLOB2CLOB(DOC.CONTENUTO)) COLUMNS
                    NUMERO_NOTA VARCHAR2(10) PATH 'Nota/NumeroNota',
                    NUMERO_NOTA_RETT VARCHAR2(10) PATH
                    'NotaRettificata/NumeroNota') RETT
     WHERE DOC.TITOLO_DOCUMENTO = 1
       AND DOC.STATO != 3
       AND TO_NUMBER(RETT.NUMERO_NOTA_RETT) = P_NUMERO_NOTA
     ORDER BY 1;
  -- Recupero della nota rettificata
  PROCEDURE NOTA_RETTIFIFCATA(P_NUMERO_NOTA_RETTIFICA    IN VARCHAR2,
                              P_NUMERO_NOTA_RETTIFICATA  OUT NUMBER,
                              P_DOCUMENTO_ID_RETTIFICATO OUT NUMBER) IS
  BEGIN

    -- XML non corretto, si esce.
    select f_is_valid_xml(doca.contenuto)
        into W_XML_NON_VALIDO
    from documenti_caricati doca
        where doca.documento_id = P_DOCUMENTO_ID;

    if (W_XML_NON_VALIDO = 0) then
      W_ERRORE := 'Formato xml non valido';
      RAISE ERRORE;
    end if;

    -- recupero del numero nota rettificata
    SELECT TO_NUMBER(RETT.NUMERO_NOTA_RETT)
      INTO P_NUMERO_NOTA_RETTIFICATA
      FROM DOCUMENTI_CARICATI DOC,
           XMLTABLE(XMLNAMESPACES(DEFAULT 'http://www.agenziaterritorio.it/ICI.xsd',
                                  'http://www.agenziaterritorio.it/ICI.xsd' AS
                                  "nms"),
                    '/DatiOut/DatiPresenti/Variazioni/Variazione/Trascrizione'
                    PASSING XMLTYPE(F_BLOB2CLOB(DOC.CONTENUTO)) COLUMNS
                    NUMERO_NOTA VARCHAR2(10) PATH 'Nota/NumeroNota',
                    NUMERO_NOTA_RETT VARCHAR2(10) PATH
                    'NotaRettificata/NumeroNota') RETT
     WHERE f_IS_VALID_XML(DOC.CONTENUTO) = 1
       AND DOC.TITOLO_DOCUMENTO = 1
       AND DOC.STATO != 3
       AND RETT.NUMERO_NOTA = P_NUMERO_NOTA_RETTIFICA
       AND RETT.NUMERO_NOTA_RETT IS NOT NULL;
    -- Se si tratta di rettifica
    IF (P_NUMERO_NOTA_RETTIFICATA IS NOT NULL) THEN
      -- recupero del documento della nota rettificata se esiste
      SELECT DOC.DOCUMENTO_ID
        INTO P_DOCUMENTO_ID_RETTIFICATO
        FROM DOCUMENTI_CARICATI DOC,
             XMLTABLE(XMLNAMESPACES(DEFAULT 'http://www.agenziaterritorio.it/ICI.xsd',
                                    'http://www.agenziaterritorio.it/ICI.xsd' AS
                                    "nms"),
                      '/DatiOut/DatiPresenti/Variazioni/Variazione/Trascrizione'
                      PASSING XMLTYPE(F_BLOB2CLOB(DOC.CONTENUTO)) COLUMNS
                      NUMERO_NOTA VARCHAR2(10) PATH 'Nota/NumeroNota') NOTA
       WHERE DOC.TITOLO_DOCUMENTO = 1
         AND DOC.STATO != 3
         AND NOTA.NUMERO_NOTA = P_NUMERO_NOTA_RETTIFICATA;
    END IF;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      NULL;
  END;
  -- Carica il documento in un clob
  PROCEDURE CARICA_DOCUMENTO(P_DOCUMENTO_ID IN NUMBER,
                             P_DOCUMENTO    OUT XMLTYPE) IS
    C_XML              CLOB;
    W_TROVA            NUMBER;
    W_CARATTERI_ERRATI VARCHAR2(100);
    W_NUMBER_TEMP      NUMBER;
  BEGIN
    SELECT F_BLOB2CLOB(CONTENUTO)
      INTO C_XML
      FROM DOCUMENTI_CARICATI
     WHERE DOCUMENTO_ID = P_DOCUMENTO_ID;
    -- Verifica dimensione file caricato
    W_NUMBER_TEMP := DBMS_LOB.GETLENGTH(C_XML);
    IF NVL(W_NUMBER_TEMP, 0) = 0 THEN
      W_ERRORE := 'Attenzione File caricato Vuoto - Verificare Client Oracle';
      RAISE ERRORE;
    END IF;
    -- Verifica caratteri errati
    W_TROVA := NVL(DBMS_LOB.INSTR(C_XML, 'Ã'), -9999);
    IF W_TROVA > 0 THEN
      IF W_TROVA > 20 THEN
        W_CARATTERI_ERRATI := DBMS_LOB.SUBSTR(C_XML, 60, W_TROVA - 20);
      ELSE
        W_CARATTERI_ERRATI := DBMS_LOB.SUBSTR(C_XML, 60, 1);
      END IF;
      W_ERRORE := 'Attenzione caratteri errati nel file:' || CHR(013) ||
                  W_CARATTERI_ERRATI;
      RAISE ERRORE;
    END IF;
    C_XML       := '<DatiOut>' ||
                   SUBSTR(C_XML, INSTR(C_XML, '<DatiRichiesta>'));
    P_DOCUMENTO := XMLTYPE.CREATEXML(C_XML);
  END;
BEGIN
  -- E' stato richiesto il dettaglio di una singola nota
  IF (P_NUMERO_NOTA IS NOT NULL) THEN
    -- Recupero del numero nota rettificata e id documento.
    -- Se non si tratta di rettifica i parametri in output varranno NULL
    NOTA_RETTIFIFCATA(P_NUMERO_NOTA,
                      W_NUMERO_NOTA_RETTIFICATA,
                      W_DOCUMENTO_ID_RETTIFICATA);
    -- Se si tratta di rettifica
    IF (W_DOCUMENTO_ID_RETTIFICATA IS NOT NULL) THEN
      -- Si carica il documento contenente la nota rettificata
      CARICA_DOCUMENTO(W_DOCUMENTO_ID_RETTIFICATA, XMLDATA);
      -- Recupero della variazione rettificata
      XMLDATA_NOTA_RETTIFICATA := XMLDATA.EXTRACT('/DatiOut/DatiPresenti/Variazioni/Variazione[Trascrizione/Nota/NumeroNota="' ||
                                                  W_NUMERO_NOTA_RETTIFICATA || '"]');
      -- Si eliminato tutte le variazione per poi aggiungere solo quelle interessate
      XMLDATA := XMLDATA.DELETEXML('/DatiOut/DatiPresenti/Variazioni/*');
      -- Si inserisce prima la nota indicata
      FOR REC_RETT IN SEL_RETT(W_NUMERO_NOTA_RETTIFICATA) LOOP
        -- lettura del documento
        CARICA_DOCUMENTO(REC_RETT.DOCUMENTO_ID, XMLDATA_NOTA);
        XMLDATA_NOTA := XMLDATA_NOTA.EXTRACT('/DatiOut/DatiPresenti/Variazioni/Variazione[Trascrizione/Nota/NumeroNota="' ||
                                             REC_RETT.NUMERO_NOTA || '"]');
        IF (P_NUMERO_NOTA = REC_RETT.NUMERO_NOTA) THEN
          XMLDATA := XMLDATA.APPENDCHILDXML('/DatiOut/DatiPresenti/Variazioni',
                                            XMLDATA_NOTA);
        END IF;
      END LOOP;
      -- Si aggiunge la nota rettificata
      XMLDATA := XMLDATA.APPENDCHILDXML('/DatiOut/DatiPresenti/Variazioni',
                                        XMLDATA_NOTA_RETTIFICATA);
      -- Si inseriscono, se esistono, le altre note che rettificano
      FOR REC_RETT IN SEL_RETT(W_NUMERO_NOTA_RETTIFICATA) LOOP
        -- lettura del documento
        CARICA_DOCUMENTO(REC_RETT.DOCUMENTO_ID, XMLDATA_NOTA);
        XMLDATA_NOTA := XMLDATA_NOTA.EXTRACT('/DatiOut/DatiPresenti/Variazioni/Variazione[Trascrizione/Nota/NumeroNota="' ||
                                             REC_RETT.NUMERO_NOTA || '"]');
        IF (P_NUMERO_NOTA != REC_RETT.NUMERO_NOTA) THEN
          XMLDATA := XMLDATA.APPENDCHILDXML('/DatiOut/DatiPresenti/Variazioni',
                                            XMLDATA_NOTA);
        END IF;
      END LOOP;
    ELSE
      -- Stampa di singola nota (non è rettifica)
      -- si carica il documento indicato
      CARICA_DOCUMENTO(P_DOCUMENTO_ID, XMLDATA);
      -- Recupero della della nota richiesta
      XMLDATA_NOTA := XMLDATA.EXTRACT('/DatiOut/DatiPresenti/Variazioni/Variazione[Trascrizione/Nota/NumeroNota="' ||
                                      P_NUMERO_NOTA || '"]');
      -- Si eliminato tutte le variazione per poi aggiungere solo quelle interessate
      XMLDATA := XMLDATA.DELETEXML('/DatiOut/DatiPresenti/Variazioni/*');
      -- Si aggiunge la singola nota selezionara
      XMLDATA := XMLDATA.APPENDCHILDXML('/DatiOut/DatiPresenti/Variazioni',
                                        XMLDATA_NOTA);
    END IF;
  ELSE
    -- Stampa dell'intero mui
    CARICA_DOCUMENTO(P_DOCUMENTO_ID, XMLDATA);
  END IF;
  BEGIN
    SELECT PARAMETRO
      INTO C_XSLDATA
      FROM PARAMETRI_IMPORT
     WHERE NOME = 'XSLDATA';
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      W_ERRORE := 'xsl stylesheet non trovato';
      RAISE ERRORE;
    WHEN OTHERS THEN
      W_ERRORE := 'Errore in estrazione xsl stylesheet';
      RAISE ERRORE;
  END;
  XSLDATA := XMLTYPE.CREATEXML(C_XSLDATA);
  HTML    := XMLDATA.TRANSFORM(XSLDATA);
  RETURN HTML.GETCLOBVAL();
EXCEPTION
  WHEN ERRORE THEN
    RAISE_APPLICATION_ERROR(-20999, NVL(W_ERRORE, 'vuoto'));
  WHEN OTHERS THEN
    RAISE_APPLICATION_ERROR(-20999,
                            'Fallita generazione Html. Errore non gestito',
                            TRUE);
END;
/* End Function: F_NOTAI_TO_HTML */
/
