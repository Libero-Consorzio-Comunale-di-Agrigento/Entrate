--liquibase formatted sql 
--changeset abrandolini:20250326_152423_set_valore_wpf stripComments:false runOnChange:true 
 
create or replace procedure SET_VALORE_WPF
  (p_anno          NUMBER,
   p_progressivo   NUMBER,
   p_codice        VARCHAR2,
   p_valore        VARCHAR2
)
IS
   is_numero     NUMBER;
   a_codice      VARCHAR2 (100);
   a_messaggio   VARCHAR2 (32000);
BEGIN
   a_codice := p_codice;
   IF p_codice = 'KG_D'
   THEN
      a_codice := 'Kg domestici';
   END IF;
   IF p_codice = 'KG_ND'
   THEN
      a_codice := 'Kg Non domestici';
   END IF;
   IF p_codice = 'TIPO_COM'
   THEN
      a_codice := 'Tipo comune';
   END IF;
   IF p_codice = 'TRIBUTO'
   THEN
      a_codice := 'Tributo';
   END IF;
   IF p_codice = 'AREA'
   THEN
      a_codice := 'Area';
   END IF;
   a_messaggio :=
         'set_valore_wpf - Anno '
      || p_anno
      || ' progressivo '
      || p_progressivo
      || ' codice '''
      || a_codice
      || ''' - ';
   IF     p_codice IN ('KG_D', 'KG_ND', 'TIPO_COM', 'TRIBUTO', 'AREA')
      AND (p_valore IS NULL OR p_valore = '')
   THEN
      raise_application_error (-20999,
                               a_messaggio || 'Inserire un valore valido'
                              );
   END IF;
   IF p_codice IN ('KG_D', 'KG_ND')
   THEN
      BEGIN
         SELECT TO_NUMBER (p_valore)
           INTO is_numero
           FROM DUAL;
      EXCEPTION
         WHEN OTHERS
         THEN
            raise_application_error (-20999,
                                        a_messaggio
                                     || 'Inserire un valore numerico'
                                    );
      END;
   END IF;
   BEGIN
      INSERT INTO wrk_piano_finanziario
                  (codice, progressivo, anno, valore
                  )
           VALUES (p_codice, p_progressivo, p_anno, p_valore
                  );
   EXCEPTION
      WHEN DUP_VAL_ON_INDEX
      THEN
         UPDATE wrk_piano_finanziario
            SET valore = p_valore
          WHERE anno = p_anno
            AND progressivo = p_progressivo
            AND codice = p_codice;
   END;
EXCEPTION
   WHEN OTHERS
   THEN
      RAISE;
END;
/* End Procedure: SET_VALORE_WPF */
/

