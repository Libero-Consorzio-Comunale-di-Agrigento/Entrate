--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_web_prossima_pratica stripComments:false runOnChange:true 
 
create or replace function F_WEB_PROSSIMA_PRATICA
(A_PRATICA      in number
,A_COD_FISCALE  in varchar2
,A_TIPO_TRIBUTO in varchar2
                                                  )
RETURN VARCHAR2
IS
       ret   VARCHAR2 (2000);
BEGIN
   ret := F_PROSSIMA_PRATICA( A_PRATICA, A_COD_FISCALE,A_TIPO_TRIBUTO );
   COMMIT;
   RETURN ret;
  EXCEPTION
     WHEN OTHERS THEN
     RAISE_APPLICATION_ERROR(-20999,'Errore in rcupero prossima pratica '|| ' ('||SQLERRM||')');
END;
/* End Function: F_WEB_PROSSIMA_PRATICA */
/

