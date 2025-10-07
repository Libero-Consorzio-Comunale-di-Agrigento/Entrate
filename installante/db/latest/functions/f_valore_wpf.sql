--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_valore_wpf stripComments:false runOnChange:true 
 
create or replace function F_VALORE_WPF
(  p_anno          NUMBER,
   p_progressivo   NUMBER,
   p_codice        VARCHAR2
)
   RETURN VARCHAR2
IS
   ret   wrk_piano_finanziario.codice%TYPE;
BEGIN
   SELECT valore
     INTO ret
     FROM wrk_piano_finanziario
    WHERE anno = p_anno
      AND progressivo = p_progressivo
      AND codice = UPPER (p_codice);
   RETURN ret;
EXCEPTION
   WHEN NO_DATA_FOUND
   THEN
      RETURN NULL;
END;
/* End Function: F_VALORE_WPF */
/

