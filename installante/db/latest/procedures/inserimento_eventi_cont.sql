--liquibase formatted sql 
--changeset abrandolini:20250326_152423_inserimento_eventi_cont stripComments:false runOnChange:true 
 
create or replace procedure INSERIMENTO_EVENTI_CONT
(
   a_tipo_evento   VARCHAR2,
   a_sequenza      NUMBER,
   a_utente        VARCHAR2
)
IS
   dep_data_evento   DATE;
BEGIN
   BEGIN
      SELECT data_evento
        INTO dep_data_evento
        FROM eventi
       WHERE tipo_evento = a_tipo_evento
            AND sequenza = a_sequenza;
      IF dep_data_evento IS NULL
      THEN
         raise_application_error (-20999,
                                  'L''evento selezionato non ha data');
      END IF;
   EXCEPTION
      WHEN others THEN
         RAISE;
   END;
    BEGIN
      delete eventi_contribuente
      where tipo_evento = a_tipo_evento
          and sequenza = a_sequenza
          and flag_automatico = 'S'
      ;
    EXCEPTION
      WHEN others THEN
         RAISE_APPLICATION_ERROR(-20999,'Errore durante la cancellazione Eventi_contribuente ('||
                                        SQLERRM||')')
      ;
    END;
    FOR c IN (SELECT cont.cod_fiscale
               FROM contribuenti cont, soggetti sogg
              WHERE cont.ni = sogg.ni
                AND f_residente_al (sogg.ni, dep_data_evento) = 1)
   LOOP
      BEGIN
         INSERT INTO eventi_contribuente
                     (cod_fiscale, tipo_evento, sequenza, flag_automatico, utente
                     )
              VALUES (c.cod_fiscale, a_tipo_evento, a_sequenza, 'S', a_utente
                     );
      EXCEPTION
         WHEN DUP_VAL_ON_INDEX THEN
            NULL;
         WHEN OTHERS THEN
            IF SQLCODE = -20007
            THEN
               NULL;
            ELSE
               RAISE;
            END IF;
      END;
   END LOOP;
EXCEPTION
   WHEN OTHERS THEN
      RAISE;
END;
/* End Procedure: INSERIMENTO_EVENTI_CONT */
/

