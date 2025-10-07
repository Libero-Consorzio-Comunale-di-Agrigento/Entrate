--liquibase formatted sql 
--changeset abrandolini:20250326_152423_denominazioni_via_fi stripComments:false runOnChange:true 
 
create or replace procedure DENOMINAZIONI_VIA_FI
(a_cod_via      IN   number,
 a_progr_via      IN   number,
 a_descrizione      IN   varchar2)
IS
BEGIN
  IF UPDATING and a_progr_via in (1,99) THEN
     BEGIN
       update archivio_vie
          set denom_uff      =
                decode(a_progr_via,1,a_descrizione,denom_uff),
              denom_ord      =
           decode(a_progr_via,99,a_descrizione,denom_ord)
        where cod_via      = a_cod_via
          and a_progr_via    in (1,99)
       ;
     EXCEPTION
       WHEN others THEN
         RAISE_APPLICATION_ERROR
           (-20999,'Errore in aggiornamento Archivio Vie');
     END;
     IF SQL%NOTFOUND THEN
        RAISE_APPLICATION_ERROR
          (-20999,'Indentificazione '||a_cod_via||
             ' non presente in Archivio Vie');
     END IF;
  END IF;
END;
/* End Procedure: DENOMINAZIONI_VIA_FI */
/

