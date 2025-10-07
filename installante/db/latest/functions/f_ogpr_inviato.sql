--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_ogpr_inviato stripComments:false runOnChange:true 
 
create or replace function F_OGPR_INVIATO
(a_oggetto_pratica      IN   number)
RETURN varchar2
IS
max_invio_consorzio   VARCHAR2(1);
BEGIN
   select decode(max(invio_consorzio),null,'NULL','S')
     into max_invio_consorzio
     from ruoli_oggetto ruog, ruoli
    where ruoli.RUOLO       = ruog.RUOLO
      and ruog.OGGETTO_PRATICA    = a_oggetto_pratica
   ;
   RETURN max_invio_consorzio;
EXCEPTION
   WHEN NO_DATA_FOUND THEN
        RETURN '';
   WHEN OTHERS THEN
        RETURN '';
END;
/* End Function: F_OGPR_INVIATO */
/

