--liquibase formatted sql 
--changeset abrandolini:20250326_152423_contribuenti_di stripComments:false runOnChange:true 
 
create or replace procedure CONTRIBUENTI_DI
(a_cod_fiscale      IN    varchar2,
 a_ni         IN   number)
IS
w_ni      number;
BEGIN
  BEGIN
    select ni
      into w_ni
      from contribuenti
     where cod_fiscale           = a_cod_fiscale
    ;  EXCEPTION
    WHEN no_data_found THEN
      null;
    WHEN others THEN
         RAISE_APPLICATION_ERROR (-20999,SQLERRM);
  END;
  IF nvl(a_ni,w_ni) != w_ni THEN
     RAISE_APPLICATION_ERROR
       (-20999,'Contribuente con lo stesso Codice Fiscale, gia'' presente in archivio');
  END IF;
END;
/* End Procedure: CONTRIBUENTI_DI */
/

