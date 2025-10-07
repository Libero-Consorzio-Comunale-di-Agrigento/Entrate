--liquibase formatted sql 
--changeset abrandolini:20250326_152423_inserimento_rendite_commit stripComments:false runOnChange:true 
 
create or replace procedure INSERIMENTO_RENDITE_COMMIT
(  a_id_immobile           IN   NUMBER,
   a_utente                IN   VARCHAR2,
   a_ver_data_cessazione   IN   DATE,
   a_flag_cessati          IN   VARCHAR2
)
IS
   a_messaggio             varchar2(2000);
BEGIN
   /*inserimento_rendite (a_id_immobile,
                        a_utente,
                        a_ver_data_cessazione,
                        a_flag_cessati
                       );*/
   inserimento_rendite_pkg.inserimento_rendite (a_id_immobile,
                                                'F',
                                                a_ver_data_cessazione,
                                                a_flag_cessati,
                                                a_utente,
                                                to_number(null),
                                                a_messaggio
                                               );
   COMMIT;
EXCEPTION
   WHEN OTHERS
   THEN
      ROLLBACK;
      RAISE;
END;
/* End Procedure: INSERIMENTO_RENDITE_COMMIT */
/

