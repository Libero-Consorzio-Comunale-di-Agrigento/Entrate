--liquibase formatted sql 
--changeset abrandolini:20250326_152423_conferimenti_cer_ruolo_fi stripComments:false runOnChange:true 
 
create or replace procedure CONFERIMENTI_CER_RUOLO_FI
(a_ruolo              IN    number,
 a_importo_scalato    IN    number)
IS
w_invio_consorzio date;
BEGIN
  BEGIN
     select invio_consorzio
       into w_invio_consorzio
        from ruoli
       where ruolo = a_ruolo
     ;
  EXCEPTION
    WHEN no_data_found THEN
      w_invio_consorzio := to_date('');
    WHEN others THEN
      RAISE_APPLICATION_ERROR
        (-20999,'Errore in ricerca Ruoli');
  END;
  IF UPDATING THEN
     IF  w_invio_consorzio is not null and a_importo_scalato is not null THEN
        RAISE_APPLICATION_ERROR
          (-20999,'Conferimento non modificabile: Importo  scalato gia'' presente in un ruolo Inviato');
     END IF;
  ELSIF DELETING THEN
     IF w_invio_consorzio is not null and a_importo_scalato is not null THEN
       RAISE_APPLICATION_ERROR
          (-20999,'Eliminazione non consentita: Importo scalato gia'' presente in un ruolo Inviato');
     END IF;
  END IF;
END;
/* End Procedure: CONFERIMENTI_CER_RUOLO_FI */
/

