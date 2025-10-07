--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_conta_costi_storici stripComments:false runOnChange:true 
 
create or replace function F_CONTA_COSTI_STORICI
(
 a_oggetto_pratica      decimal
) return number
IS
w_numero   number;
BEGIN
   select count(*)
     into w_numero
     from costi_storici
       , oggetti_pratica
    where costi_storici.oggetto_pratica = a_oggetto_pratica
     and costi_storici.OGGETTO_PRATICA = oggetti_pratica.OGGETTO_PRATICA
     and oggetti_pratica.TIPO_OGGETTO  = 4
     and substr(oggetti_pratica.CATEGORIA_CATASTO,1,1) = 'D'
   ;
   RETURN w_numero;
EXCEPTION
   WHEN others THEN
   RETURN 0;
END;
/* End Function: F_CONTA_COSTI_STORICI */
/

