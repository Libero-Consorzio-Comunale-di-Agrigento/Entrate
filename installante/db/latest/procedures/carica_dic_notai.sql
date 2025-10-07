--liquibase formatted sql 
--changeset abrandolini:20250326_152423_carica_dic_notai stripComments:false runOnChange:true 
 
create or replace procedure CARICA_DIC_NOTAI
(  a_documento_id    IN       NUMBER,
   a_utente          IN       VARCHAR2,
   a_ctr_denuncia    IN       VARCHAR2,
   a_sezione_unica   IN       VARCHAR2,
   a_fonte           IN       NUMBER,
   a_messaggio       IN OUT   VARCHAR2
)
IS
   w_messaggio       VARCHAR2 (500);
   w_messaggio_tot   VARCHAR2 (1000);
   w_parametro       installazione_parametri.valore%TYPE;
   w_titr            installazione_parametri.valore%TYPE;
   w_ctr_part        installazione_parametri.valore%TYPE;
   w_pos             NUMBER;
BEGIN
   -- Cambio stato in caricamento in corso per gestione Web
   update documenti_caricati
           set stato = 15
             , data_variazione = sysdate
             , utente = a_utente
         where documento_id = a_documento_id
             ;
   commit;
   BEGIN
      SELECT nvl(TRIM (UPPER (valore)),'ICI')
        INTO w_parametro
        FROM installazione_parametri
       WHERE parametro = 'TITR_NOTAI';
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         w_parametro := 'ICI';
      WHEN OTHERS
      THEN
         raise_application_error
                               (-20999,
                                   'Errore in lettura parametro TITR_NOTAI ('
                                || SQLERRM
                                || ')'
                               );
   END;
   WHILE w_parametro IS NOT NULL
   LOOP
      w_messaggio := NULL;
      w_pos := NVL (INSTR (w_parametro, ' '), 0);
      IF w_pos = 0
      THEN
         w_titr := w_parametro;
         w_parametro := NULL;
      ELSE
         w_titr := SUBSTR (w_parametro, 1, w_pos - 1);
      END IF;
      IF w_pos < LENGTH (w_parametro) AND w_pos > 0
      THEN
         w_parametro := SUBSTR (w_parametro, w_pos + 1);
      ELSE
         w_parametro := NULL;
      END IF;
      /*
          DM 08/03/2016 - Recupero parametro controllo su partita
      */
      BEGIN
          SELECT nvl(TRIM (UPPER (valore)),'N')
                 INTO w_ctr_part
          FROM installazione_parametri
          WHERE parametro = 'CTR_PART';
      EXCEPTION
          WHEN NO_DATA_FOUND
               THEN
                w_ctr_part := 'N';
          WHEN OTHERS
               THEN
               raise_application_error
                                     (-20999,
                                         'Errore in lettura parametro CTR_PART ('
                                      || SQLERRM
                                      || ')'
                                     );
       END;
      carica_dic_notai_titr (a_documento_id,
                             a_utente,
                             a_ctr_denuncia,
                             w_ctr_part,
                             a_sezione_unica,
                             a_fonte,
                             w_titr,
                             w_messaggio
                            );
     IF nvl(w_messaggio_tot, ' ') = ' ' THEN
         w_messaggio_tot := w_messaggio;
      ELSE
         w_messaggio_tot :=
                         w_messaggio_tot || CHR (10) || CHR (13)
                         || w_messaggio;
      END IF;
   END LOOP;
   a_messaggio := w_messaggio_tot;
END;
/* End Procedure: CARICA_DIC_NOTAI */
/

