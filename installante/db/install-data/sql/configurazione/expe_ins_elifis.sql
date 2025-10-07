--liquibase formatted sql
--changeset dmarotta:20250326_152438_expe_ins_elifis stripComments:false  context:ER
--validCheckSum: 1:any

DECLARE
    v_codice_istat VARCHAR2(100);
    v_descrizione VARCHAR2(200);

    -- Variabile per controllare se abbiamo trovato dati
    v_trovato BOOLEAN := FALSE;
BEGIN
    -- Disabilita i trigger sulla tabella
    EXECUTE IMMEDIATE 'ALTER TABLE export_personalizzati DISABLE ALL TRIGGERS';

    -- Estrai i valori dalla query
    BEGIN
        SELECT lpad(to_char(dage.pro_cliente),3,'0') || lpad(to_char(dage.com_cliente),3,'0'),
               initcap(comu.denominazione)
        INTO v_codice_istat, v_descrizione
        FROM dati_generali dage
        JOIN ad4_comuni comu ON dage.pro_cliente = comu.provincia_stato
                            AND dage.com_cliente = comu.comune
        WHERE ROWNUM = 1; -- Prendi solo il primo record se ce ne sono più di uno

        v_trovato := TRUE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_trovato := FALSE;
            DBMS_OUTPUT.PUT_LINE('Nessun dato trovato nella query iniziale.');
    END;

    -- Procedi solo se abbiamo trovato i dati
    IF v_trovato THEN
        -- Inserimenti nella tabella EXPORT_PERSONALIZZATI
        -- Nota: Utilizziamo la clausola WHERE NOT EXISTS per ogni inserimento

        -- ELIFIS Anagrafica dei Soggetti (151)
        INSERT INTO EXPORT_PERSONALIZZATI (TIPO_EXPORT, CODICE_ISTAT, DESCRIZIONE)
        SELECT 151, v_codice_istat, v_descrizione || ' - ELIFIS Anagrafica dei Soggetti'
        FROM dual
        WHERE NOT EXISTS (SELECT 'x' FROM EXPORT_PERSONALIZZATI
                          WHERE TIPO_EXPORT = 151 AND CODICE_ISTAT = v_codice_istat);

        -- ELIFIS Anagrafica degli Oggetti (152)
        INSERT INTO EXPORT_PERSONALIZZATI (TIPO_EXPORT, CODICE_ISTAT, DESCRIZIONE)
        SELECT 152, v_codice_istat, v_descrizione || ' - ELIFIS Anagrafica degli Oggetti'
        FROM dual
        WHERE NOT EXISTS (SELECT 'x' FROM EXPORT_PERSONALIZZATI
                          WHERE TIPO_EXPORT = 152 AND CODICE_ISTAT = v_codice_istat);

        -- ELIFIS Comuni (153)
        INSERT INTO EXPORT_PERSONALIZZATI (TIPO_EXPORT, CODICE_ISTAT, DESCRIZIONE)
        SELECT 153, v_codice_istat, v_descrizione || ' - ELIFIS Comuni'
        FROM dual
        WHERE NOT EXISTS (SELECT 'x' FROM EXPORT_PERSONALIZZATI
                          WHERE TIPO_EXPORT = 153 AND CODICE_ISTAT = v_codice_istat);

        -- ELIFIS Nazioni (154)
        INSERT INTO EXPORT_PERSONALIZZATI (TIPO_EXPORT, CODICE_ISTAT, DESCRIZIONE)
        SELECT 154, v_codice_istat, v_descrizione || ' - ELIFIS Nazioni'
        FROM dual
        WHERE NOT EXISTS (SELECT 'x' FROM EXPORT_PERSONALIZZATI
                          WHERE TIPO_EXPORT = 154 AND CODICE_ISTAT = v_codice_istat);

        -- ELIFIS Strade (155)
        INSERT INTO EXPORT_PERSONALIZZATI (TIPO_EXPORT, CODICE_ISTAT, DESCRIZIONE)
        SELECT 155, v_codice_istat, v_descrizione || ' - ELIFIS Strade'
        FROM dual
        WHERE NOT EXISTS (SELECT 'x' FROM EXPORT_PERSONALIZZATI
                          WHERE TIPO_EXPORT = 155 AND CODICE_ISTAT = v_codice_istat);

        -- ELIFIS Civici (156)
        INSERT INTO EXPORT_PERSONALIZZATI (TIPO_EXPORT, CODICE_ISTAT, DESCRIZIONE)
        SELECT 156, v_codice_istat, v_descrizione || ' - ELIFIS Civici'
        FROM dual
        WHERE NOT EXISTS (SELECT 'x' FROM EXPORT_PERSONALIZZATI
                          WHERE TIPO_EXPORT = 156 AND CODICE_ISTAT = v_codice_istat);

        -- ELIFIS Denunce ICI (157)
        INSERT INTO EXPORT_PERSONALIZZATI (TIPO_EXPORT, CODICE_ISTAT, DESCRIZIONE)
        SELECT 157, v_codice_istat, v_descrizione || ' - ELIFIS Denunce ICI'
        FROM dual
        WHERE NOT EXISTS (SELECT 'x' FROM EXPORT_PERSONALIZZATI
                          WHERE TIPO_EXPORT = 157 AND CODICE_ISTAT = v_codice_istat);

        -- ELIFIS Aliquote Speciali ICI (158)
        INSERT INTO EXPORT_PERSONALIZZATI (TIPO_EXPORT, CODICE_ISTAT, DESCRIZIONE)
        SELECT 158, v_codice_istat, v_descrizione || ' - ELIFIS Aliquote Speciali ICI'
        FROM dual
        WHERE NOT EXISTS (SELECT 'x' FROM EXPORT_PERSONALIZZATI
                          WHERE TIPO_EXPORT = 158 AND CODICE_ISTAT = v_codice_istat);

        -- ELIFIS Detrazioni ICI (159)
        INSERT INTO EXPORT_PERSONALIZZATI (TIPO_EXPORT, CODICE_ISTAT, DESCRIZIONE)
        SELECT 159, v_codice_istat, v_descrizione || ' - ELIFIS Detrazioni ICI'
        FROM dual
        WHERE NOT EXISTS (SELECT 'x' FROM EXPORT_PERSONALIZZATI
                          WHERE TIPO_EXPORT = 159 AND CODICE_ISTAT = v_codice_istat);

        -- ELIFIS Versamenti ICI (160)
        INSERT INTO EXPORT_PERSONALIZZATI (TIPO_EXPORT, CODICE_ISTAT, DESCRIZIONE)
        SELECT 160, v_codice_istat, v_descrizione || ' - ELIFIS Versamenti ICI'
        FROM dual
        WHERE NOT EXISTS (SELECT 'x' FROM EXPORT_PERSONALIZZATI
                          WHERE TIPO_EXPORT = 160 AND CODICE_ISTAT = v_codice_istat);

        -- ELIFIS Provvedimenti ICI (161)
        INSERT INTO EXPORT_PERSONALIZZATI (TIPO_EXPORT, CODICE_ISTAT, DESCRIZIONE)
        SELECT 161, v_codice_istat, v_descrizione || ' - ELIFIS Provvedimenti ICI'
        FROM dual
        WHERE NOT EXISTS (SELECT 'x' FROM EXPORT_PERSONALIZZATI
                          WHERE TIPO_EXPORT = 161 AND CODICE_ISTAT = v_codice_istat);

        -- ELIFIS Dovuti ICI (162)
        INSERT INTO EXPORT_PERSONALIZZATI (TIPO_EXPORT, CODICE_ISTAT, DESCRIZIONE)
        SELECT 162, v_codice_istat, v_descrizione || ' - ELIFIS Dovuti ICI'
        FROM dual
        WHERE NOT EXISTS (SELECT 'x' FROM EXPORT_PERSONALIZZATI
                          WHERE TIPO_EXPORT = 162 AND CODICE_ISTAT = v_codice_istat);

        -- ELIFIS Aliquote ICI (163)
        INSERT INTO EXPORT_PERSONALIZZATI (TIPO_EXPORT, CODICE_ISTAT, DESCRIZIONE)
        SELECT 163, v_codice_istat, v_descrizione || ' - ELIFIS Aliquote ICI'
        FROM dual
        WHERE NOT EXISTS (SELECT 'x' FROM EXPORT_PERSONALIZZATI
                          WHERE TIPO_EXPORT = 163 AND CODICE_ISTAT = v_codice_istat);

        -- ELIFIS Agevolazioni ICI (164)
        INSERT INTO EXPORT_PERSONALIZZATI (TIPO_EXPORT, CODICE_ISTAT, DESCRIZIONE)
        SELECT 164, v_codice_istat, v_descrizione || ' - ELIFIS Agevolazioni ICI'
        FROM dual
        WHERE NOT EXISTS (SELECT 'x' FROM EXPORT_PERSONALIZZATI
                          WHERE TIPO_EXPORT = 164 AND CODICE_ISTAT = v_codice_istat);

        -- ELIFIS Denunce RSU (165)
        INSERT INTO EXPORT_PERSONALIZZATI (TIPO_EXPORT, CODICE_ISTAT, DESCRIZIONE)
        SELECT 165, v_codice_istat, v_descrizione || ' - ELIFIS Denunce RSU'
        FROM dual
        WHERE NOT EXISTS (SELECT 'x' FROM EXPORT_PERSONALIZZATI
                          WHERE TIPO_EXPORT = 165 AND CODICE_ISTAT = v_codice_istat);

        -- ELIFIS Provvedimenti RSU (166)
        INSERT INTO EXPORT_PERSONALIZZATI (TIPO_EXPORT, CODICE_ISTAT, DESCRIZIONE)
        SELECT 166, v_codice_istat, v_descrizione || ' - ELIFIS Provvedimenti RSU'
        FROM dual
        WHERE NOT EXISTS (SELECT 'x' FROM EXPORT_PERSONALIZZATI
                          WHERE TIPO_EXPORT = 166 AND CODICE_ISTAT = v_codice_istat);

        -- ELIFIS Classe Tariffa RSU (167)
        INSERT INTO EXPORT_PERSONALIZZATI (TIPO_EXPORT, CODICE_ISTAT, DESCRIZIONE)
        SELECT 167, v_codice_istat, v_descrizione || ' - ELIFIS Classe Tariffa RSU'
        FROM dual
        WHERE NOT EXISTS (SELECT 'x' FROM EXPORT_PERSONALIZZATI
                          WHERE TIPO_EXPORT = 167 AND CODICE_ISTAT = v_codice_istat);

        -- ELIFIS Tipi Oggetto RSU (168)
        INSERT INTO EXPORT_PERSONALIZZATI (TIPO_EXPORT, CODICE_ISTAT, DESCRIZIONE)
        SELECT 168, v_codice_istat, v_descrizione || ' - ELIFIS Tipi Oggetto RSU'
        FROM dual
        WHERE NOT EXISTS (SELECT 'x' FROM EXPORT_PERSONALIZZATI
                          WHERE TIPO_EXPORT = 168 AND CODICE_ISTAT = v_codice_istat);

        DBMS_OUTPUT.PUT_LINE('Inserimenti completati per codice ISTAT: ' || v_codice_istat ||
                             ', descrizione: ' || v_descrizione);
    END IF;

    -- Riabilita i trigger sulla tabella
    EXECUTE IMMEDIATE 'ALTER TABLE export_personalizzati ENABLE ALL TRIGGERS';

EXCEPTION
    WHEN OTHERS THEN
        -- In caso di errore, riabilita comunque i trigger
        BEGIN
            EXECUTE IMMEDIATE 'ALTER TABLE export_personalizzati ENABLE ALL TRIGGERS';
        EXCEPTION
            WHEN OTHERS THEN
                NULL; -- Ignora eventuali errori nel riabilitare i trigger
        END;

        -- Propaga l'errore
        RAISE;
END;
/
