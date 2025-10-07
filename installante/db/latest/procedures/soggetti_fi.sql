--liquibase formatted sql 
--changeset abrandolini:20250326_152423_soggetti_fi stripComments:false runOnChange:true 
 
create or replace procedure SOGGETTI_FI
(a_tipo_residente      IN   number
)
IS
w_flag_gsd   varchar2(1);
w_errore   varchar2(2000);
errore      exception;
BEGIN
  BEGIN
    select flag_integrazione_gsd
      into w_flag_gsd
      from dati_generali
    ;
  EXCEPTION
    WHEN no_data_found THEN
    w_errore := 'Manca record in Dati Generali';
      RAISE errore;
    WHEN others THEN
    w_errore := 'Errore in ricerca Dati Generali '||
           '('||SQLERRM||')';
      RAISE errore;
  END;
  IF nvl(w_flag_gsd,'N') = 'S' and a_tipo_residente = 0 THEN
     IF Gsd_IntegrityPackage.GetNestLevel = 0 THEN
        IF DELETING THEN
           w_errore := 'Eliminazione non consentita: '||
             'Soggetto di proprieta'' dei Servizi Demografici';
      RAISE errore;
        END IF;
     END IF;
   END IF;
EXCEPTION
  WHEN errore THEN
       RAISE_APPLICATION_ERROR
    (-20999,w_errore);
  WHEN others THEN
       RAISE_APPLICATION_ERROR
    (-20999,SQLERRM);
END;
/* End Procedure: SOGGETTI_FI */
/

