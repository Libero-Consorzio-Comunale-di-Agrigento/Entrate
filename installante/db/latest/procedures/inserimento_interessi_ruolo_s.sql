--liquibase formatted sql 
--changeset abrandolini:20250326_152423_inserimento_interessi_ruolo_s stripComments:false runOnChange:true 
 
CREATE OR REPLACE procedure     INSERIMENTO_INTERESSI_RUOLO_S
(a_pratica         IN number,
 a_oggetto_pratica IN number,
 a_cod_sanzione    IN number,
 a_dal             IN date,
 a_al              IN date,
 a_importo         IN number,
 a_tipo_tributo    IN varchar2,
 a_tipo_vers       IN varchar2,
 a_utente          IN varchar2
)
IS
C_INTERESSI_ACC   CONSTANT number := 98;
C_INTERESSI_SAL   CONSTANT number := 99;
C_NUOVO           CONSTANT number := 100;
w_errore          varchar2(2000);
errore            exception;
w_semestri        number := NULL;
w_giorni          number := NULL;
w_interessi       number;
w_cod_sanzione    number(3);
w_sequenza_sanz   number(4);
w_check           number(1);
BEGIN   -- inserimento_interessi
  -- w_interessi := f_calcolo_interessi(a_tipo_tributo, a_importo, a_dal, a_al, w_semestri);
   w_interessi := F_CALCOLO_INTERESSI_GG_TITR(a_importo, a_dal, a_al, 365, a_tipo_tributo);
   w_giorni := a_al - a_dal +1;
   IF w_interessi IS NULL THEN
            w_errore := 'Manca il periodo in Interessi';
            RAISE errore;
   ELSIF w_interessi = -1 THEN
            w_errore := 'Errore in ricerca Interessi ('||SQLERRM||')';
            RAISE errore;
   ELSIF w_interessi <> 0 THEN
            IF a_tipo_vers = 'A' THEN
             w_cod_sanzione := C_INTERESSI_ACC;
            ELSE
             w_cod_sanzione := C_INTERESSI_SAL;
            END IF;
            w_check := f_check_sanzione(a_pratica,w_cod_sanzione);
            IF a_cod_sanzione < 100 THEN
             IF w_check = 0 THEN
              IF w_interessi != 0 THEN
               BEGIN
                insert into sanzioni_pratica
                      (cod_sanzione,tipo_tributo,pratica,oggetto_pratica,
                       percentuale,importo,giorni,riduzione,utente,data_variazione)
                values (w_cod_sanzione,a_tipo_tributo,a_pratica,a_oggetto_pratica,
                        null,w_interessi,w_giorni,null,a_utente,trunc(sysdate))
                ;
               EXCEPTION
                WHEN others THEN
                 w_errore := 'Errore in inserimento Sanzioni Pratica('
                            ||w_cod_sanzione||') '||'('||SQLERRM||')';
                 RAISE errore;
               END;
              END IF;
             ELSIF w_check = 1 THEN
              BEGIN
               update sanzioni_pratica
                  set importo      = w_interessi
                     ,semestri     = null
                     ,giorni       = w_giorni
                where pratica      = a_pratica
                  and cod_sanzione = w_cod_sanzione
               ;
              EXCEPTION
               WHEN others THEN
                w_errore := 'Errore aggiornamento Sanzioni Pratica';
               RAISE errore;
              END;
             ELSE
              w_errore := 'Errore f_check_sapr per sanzione: '||w_cod_sanzione||' ('||SQLERRM||')';
             END IF;
            END IF;
            w_cod_sanzione := w_cod_sanzione + C_NUOVO;
            w_check := f_check_sanzione(a_pratica,w_cod_sanzione);
            IF a_cod_sanzione > 99 THEN
             IF w_check = 0 THEN
              IF w_interessi != 0 THEN
               BEGIN
                insert into sanzioni_pratica
                      (cod_sanzione,tipo_tributo,pratica,oggetto_pratica,
                       percentuale,importo,giorni,riduzione,utente,data_variazione)
                values (w_cod_sanzione,a_tipo_tributo,a_pratica,a_oggetto_pratica,
                        null,w_interessi,w_giorni,null,a_utente,trunc(sysdate))
                ;
               EXCEPTION
                WHEN others THEN
                 w_errore := 'Errore in inserimento Sanzioni Pratica('
                            ||w_cod_sanzione||') '||'('||SQLERRM||')';
                 RAISE errore;
               END;
              END IF;
             ELSIF w_check = 1 THEN
-- AB (12/12/2024) per avere la sequenza_sanz giusta
              BEGIN
                 select sequenza_sanz
                   into w_sequenza_sanz
                   from sanzioni_pratica sapr
                  where sapr.pratica = a_pratica
                    and sapr.cod_sanzione = a_cod_sanzione
                 ;
              EXCEPTION
                  WHEN others THEN
                        w_errore := 'Errore in ricerca Sanzioni Pratica ('
                                ||a_cod_sanzione||') '||'('||SQLERRM||')';
                       RAISE errore;
              END;

              BEGIN
               update sanzioni_pratica
                  set importo       = w_interessi
                     ,semestri      = null
                     ,giorni        = w_giorni
                where pratica       = a_pratica
                  and cod_sanzione  = w_cod_sanzione
                  and sequenza_sanz = w_sequenza_sanz
               ;
              EXCEPTION
               WHEN others THEN
                w_errore := 'Errore aggiornamento Sanzioni Pratica';
               RAISE errore;
              END;
             ELSE
              w_errore := 'Errore f_check_sanzione per sanzione: '||w_cod_sanzione||' ('||SQLERRM||')';
             END IF;
            END IF;
   END IF;
EXCEPTION
  WHEN errore THEN
       ROLLBACK;
       RAISE_APPLICATION_ERROR(-20999,w_errore);
  WHEN others THEN
       ROLLBACK;
       RAISE_APPLICATION_ERROR(-20999,'Errore durante Inserimento Interessi ('||SQLERRM||')');
END;
/* End Procedure: INSERIMENTO_INTERESSI_RUOLO_S */
/
