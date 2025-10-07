--liquibase formatted sql 
--changeset abrandolini:20250326_152423_annulla_elenco_sgravi stripComments:false runOnChange:true 
 
create or replace procedure ANNULLA_ELENCO_SGRAVI
(a_numero      IN   number,
 a_data         IN    date)
IS
BEGIN
   update sgravi
      set numero_elenco   = '',
          data_elenco   = ''
    where numero_elenco = a_numero
      and data_elenco   = a_data
   ;
   EXCEPTION
      WHEN others THEN
           RAISE_APPLICATION_ERROR
             (-20999,'Errore in aggiornamento Sgravi');
END;
/* End Procedure: ANNULLA_ELENCO_SGRAVI */
/

