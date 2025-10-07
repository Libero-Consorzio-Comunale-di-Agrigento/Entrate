--liquibase formatted sql 
--changeset abrandolini:20250326_152423_numera_elenco_sgravi stripComments:false runOnChange:true 
 
create or replace procedure NUMERA_ELENCO_SGRAVI
(a_numero      IN   number,
 a_data         IN    date)
IS
BEGIN
   update sgravi
      set numero_elenco   = a_numero,
          data_elenco   = a_data
    where numero_elenco is null
   ;
   EXCEPTION
      WHEN others THEN
           RAISE_APPLICATION_ERROR
             (-20999,'Errore in aggiornamento Sgravi');
END;
/* End Procedure: NUMERA_ELENCO_SGRAVI */
/

