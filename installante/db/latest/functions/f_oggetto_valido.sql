--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_oggetto_valido stripComments:false runOnChange:true 
 
create or replace function F_OGGETTO_VALIDO
( A_COD_FISCALE      IN VARCHAR2,
  A_OGGETTO_PRATICA    IN NUMBER,
  A_DATA      IN DATE
)
RETURN number
is
ritorno number;
BEGIN
   select 1
     into ritorno
     from oggetti_validita ogva
    where ogva.cod_fiscale      = a_cod_fiscale
      and ogva.oggetto_pratica      = a_oggetto_pratica
      and a_data between nvl(ogva.dal,to_date('01/01/1900','dd/mm/yyyy'))
           and nvl(ogva.al,to_date('31/12/9999','dd/mm/yyyy'))
   ;
   RETURN ritorno;
EXCEPTION
   WHEN NO_DATA_FOUND THEN
        RETURN 0;
   WHEN OTHERS THEN
        RETURN -1;
END;
/* End Function: F_OGGETTO_VALIDO */
/

