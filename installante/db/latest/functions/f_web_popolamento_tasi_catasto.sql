--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_web_popolamento_tasi_catasto stripComments:false runOnChange:true 
 
create or replace function F_WEB_POPOLAMENTO_TASI_CATASTO
(A_COD_FISCALE VARCHAR2 DEFAULT '%',
 A_FONTE       NUMBER,
 A_TITOLO      VARCHAR2 DEFAULT '%')
  RETURN VARCHAR2 IS
  w_log VARCHAR2(2000);
BEGIN
  -- Inizializzazione LOG 
  dbms_lob.createtemporary(w_log, true);
  
  POPOLAMENTO_TASI_CATASTO(A_COD_FISCALE, A_FONTE, A_TITOLO, w_log);
  
  COMMIT;
  RETURN w_log;
EXCEPTION
  WHEN OTHERS THEN
    RAISE_APPLICATION_ERROR(-20999,
                            'Errore in popolamento TASI da catasto ' || ' (' || SQLERRM || ')');
END;
/* End Function: F_WEB_POPOLAMENTO_TASI_CATASTO */
/

