--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_web_popolamento_tasi_imu stripComments:false runOnChange:true 
 
create or replace function F_WEB_POPOLAMENTO_TASI_IMU
(A_COD_FISCALE VARCHAR2 DEFAULT '%',
 A_FONTE       NUMBER)
  RETURN CLOB IS
  W_DATE DATE;
  W_LOG  CLOB;
  W_PRATICHE_TASI NUMBER(10);
  CURSOR W_CUR_LOG(P_COD_FISCALE VARCHAR2, P_DATE DATE) IS
    SELECT '- Anno ' || T.ANNO || ' Pratica IMU n.' || T.PRATICA_IMU ||
           ' di ' || REPLACE(SOGG.COGNOME_NOME, '/', ' ') || ' - ' ||
           SOGG.COD_FISCALE || CHR(13) ||
           REPLACE(REPLACE(T.DESCRIZIONE, CHR(13), ''), '/', ' ') ||
           DECODE(T.OGGETTO,
                  NULL,
                  '',
                  CHR(13) || 'Oggetto ' || T.OGGETTO || ' Pratica TASI n.' ||
                  T.PRATICA_TASI) AS LINE
      FROM WRK_POPOLAMENTO_TASI_IMU T, SOGGETTI SOGG
     WHERE DATA_ELABORAZIONE = P_DATE
       AND SOGG.COD_FISCALE = P_COD_FISCALE
     ORDER BY 1;
BEGIN
  SELECT COUNT(*)
    INTO W_PRATICHE_TASI
    FROM PRATICHE_TRIBUTO PRTR
   WHERE PRTR.TIPO_TRIBUTO = 'TASI'
     AND PRTR.COD_FISCALE = A_COD_FISCALE
     AND PRTR.TIPO_PRATICA = 'D';
  IF (W_PRATICHE_TASI = 0) THEN
    POPOLAMENTO_TASI_IMU(A_COD_FISCALE, NULL, A_FONTE, 'S', 'S', W_DATE);
    DBMS_LOB.CREATETEMPORARY(W_LOG, TRUE);
    FOR REC IN W_CUR_LOG(A_COD_FISCALE, W_DATE) LOOP
      IF (DBMS_LOB.GETLENGTH(W_LOG) = 0) THEN
        W_LOG := 'Segnalazioni:' || CHR(13) || REC.LINE;
      ELSE
        W_LOG := W_LOG || CHR(13) || CHR(13) || REC.LINE;
      END IF;
    END LOOP;
    COMMIT;
  ELSE
    W_LOG := 'Operazione non consentita: il contribuente è già proprietario TASI.';
  END IF;
  RETURN W_LOG;
EXCEPTION
  WHEN OTHERS THEN
    RAISE_APPLICATION_ERROR(-20999,
                            'Errore in popolamento TASI da IMU ' || ' (' ||
                            SQLERRM || ')');
END;
/* End Function: F_WEB_POPOLAMENTO_TASI_IMU */
/

