--liquibase formatted sql 
--changeset abrandolini:20250326_152423_oggetti_fi stripComments:false runOnChange:true 
 
CREATE OR REPLACE PROCEDURE OGGETTI_FI
(a_oggetto      IN    number,
 a_indirizzo_localita_old IN    varchar2,
 a_cod_via_old      IN    number,
 a_num_civ_old      IN    number,
 a_suffisso_old      IN   varchar2,
 a_indirizzo_localita_new IN    varchar2,
 a_cod_via_new      IN    number,
 a_num_civ_new      IN    number,
 a_suffisso_new      IN   varchar2)
IS
BEGIN
  IF INSERTING THEN
     BEGIN
       insert into civici_oggetto
         (oggetto,indirizzo_localita,cod_via,num_civ,suffisso)
       values (a_oggetto,a_indirizzo_localita_new,
               a_cod_via_new,a_num_civ_new,a_suffisso_new)
       ;
     EXCEPTION
       WHEN others THEN
    RAISE_APPLICATION_ERROR
      (-20999,'Errore in inserimento Civici Oggetti');
     END;
  ELSIF UPDATING THEN
     BEGIN
       update civici_oggetto
          set indirizzo_localita    = a_indirizzo_localita_new,
         cod_via          = a_cod_via_new,
         num_civ          = a_num_civ_new,
         suffisso           = a_suffisso_new
   where oggetto               = a_oggetto
          and sequenza          = 1
       ;
     EXCEPTION
       WHEN others THEN
    RAISE_APPLICATION_ERROR
      (-20999,'Errore in aggiornamento Civici Oggetti');
     END;
     IF SQL%NOTFOUND THEN
        RAISE_APPLICATION_ERROR
          (-20999,'Identificazione '||a_oggetto||
              ' non presente in archivio Civici Oggetti');
     END IF;
  END IF;
END;
/* End Procedure: OGGETTI_FI */
/

