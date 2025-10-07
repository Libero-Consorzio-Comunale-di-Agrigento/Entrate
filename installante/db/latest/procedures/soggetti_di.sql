--liquibase formatted sql 
--changeset abrandolini:20250326_152423_soggetti_di stripComments:false runOnChange:true 
 
CREATE OR REPLACE PROCEDURE SOGGETTI_DI
(a_cod_fiscale      IN    varchar2,
 a_data_nascita      IN   date
)
IS
w_presente   varchar2(1);
BEGIN
  IF nvl(a_data_nascita,to_date('01/01/1800','dd/mm/yyyy')) > sysdate THEN
     RAISE_APPLICATION_ERROR
       (-20999,'Data di nascita maggiore della data odierna');
  END IF;
  IF INSERTING or UPDATING or DELETING THEN
    null;
  ELSE
    BEGIN
      select 'x'
        into w_presente
        from soggetti
       where cod_fiscale = a_cod_fiscale
      ;
    RAISE too_many_rows;
    EXCEPTION
      WHEN no_data_found THEN
        null;
      WHEN too_many_rows THEN
        RAISE_APPLICATION_ERROR
          (-20998,'Esistono Soggetti con il Codice Fiscale indicato');
      WHEN others THEN
        RAISE_APPLICATION_ERROR
          (-20999,'Errore in ricerca Soggetti (SOGGETTI_DI)');
    END;
  END IF;
END;
/* End Procedure: SOGGETTI_DI */
/

