--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_web_carica_pratica_k stripComments:false runOnChange:true 
 
create or replace function F_WEB_CARICA_PRATICA_K
(a_tipo_tributo   IN VARCHAR2,
 a_cod_fiscale    IN VARCHAR2,
 a_anno_rif       IN NUMBER,
 a_utente         IN VARCHAR2,
 a_caller         IN VARCHAR2)
   RETURN NUMBER
IS
   n_pratica   NUMBER := 0;
BEGIN
--raise_application_error(-20999, 'cod fiscale '||nvl(a_cod_fiscale,'nullo'));
   carica_pratica_k (a_tipo_tributo,
                     a_cod_fiscale,
                     a_anno_rif,
                     a_utente,
                     n_pratica,
                     a_caller
                     );
   RETURN n_pratica;
END;
/* End Function: F_WEB_CARICA_PRATICA_K */
/

