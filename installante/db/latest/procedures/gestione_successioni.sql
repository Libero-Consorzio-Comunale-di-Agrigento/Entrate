--liquibase formatted sql 
--changeset abrandolini:20250326_152423_gestione_successioni stripComments:false runOnChange:true 
 
create or replace procedure GESTIONE_SUCCESSIONI
/*************************************************************************
 NOME:        GESTIONE_SUCCESSIONI
 DESCRIZIONE: Per ogni tipo tributo presente nella tabella
              INSTALLAZIONE_PARAMETRI esegue la procedure di
              caricamento pratiche per il defunto e gli eredi
 NOTE:        A_CTR_DENUNCIA assume i seguenti valori:
              'S' - controlla se esiste gia' una denuncia per il
                    contribuente da trattare
              'N' - Inserisce sempre una nuova denuncia
              A_SEZIONE_UNICA assume i seguenti valori:
              'S' - per il trattamento dei dati catastali si considera la
                    sezione = null
              'N' - per il trattamento dei dati catastali si considera la
                    sezione presente sul file
  Rev.    Date         Author      Note
  1       12/05/2017   VD          Aggiunti commenti
  0       25/01/2010               Prima emissione
*************************************************************************/
(  a_documento_id            IN       NUMBER,
   a_utente                  IN       VARCHAR2,
   a_ctr_denuncia            IN       VARCHAR2,
   a_sezione_unica           IN       VARCHAR2,
   a_fonte                   IN       NUMBER,
   a_succ_gia_inserite       IN       NUMBER,
   a_successioni             IN       NUMBER,
   a_nuove_pratiche          IN OUT   NUMBER,
   a_nuovi_oggetti           IN OUT   NUMBER,
   a_nuovi_contribuenti      IN OUT   NUMBER,
   a_nuovi_soggetti          IN OUT   NUMBER,
   a_pratiche_gia_inserite   IN OUT   NUMBER,
   a_messaggio               IN OUT   VARCHAR2
)
IS
w_messaggio         varchar2(500);
w_messaggio_tot     varchar2(1000);
w_parametro         installazione_parametri.valore%TYPE;
w_titr              installazione_parametri.valore%TYPE;
w_pos               NUMBER;
w_errore            varchar2(2000);
sql_errm            varchar2(2000);
TYPE type_stato_successione IS TABLE OF successioni_defunti.stato_successione%TYPE
INDEX BY varchar2(10);
t_stsu           type_stato_successione;
BEGIN
    BEGIN
      SELECT nvl(TRIM (UPPER (valore)),'ICI')
        INTO w_parametro
        FROM installazione_parametri
       WHERE parametro = 'TITR_SUCC';
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         w_parametro := 'ICI';
      WHEN OTHERS
      THEN
         raise_application_error
                               (-20999,
                                   'Errore in lettura parametro TITR_SUCC ('
                                || SQLERRM
                                || ')'
                               );
   END;
WHILE w_parametro IS NOT NULL
   LOOP
      w_messaggio := NULL;
      w_pos := NVL (INSTR (w_parametro, ' '), 0);
      IF w_pos = 0
      THEN
         w_titr := w_parametro;
         w_parametro := NULL;
      ELSE
         w_titr := SUBSTR (w_parametro, 1, w_pos - 1);
      END IF;
      IF w_pos < LENGTH (w_parametro) AND w_pos > 0
      THEN
         w_parametro := SUBSTR (w_parametro, w_pos + 1);
      ELSE
         w_parametro := NULL;
      END IF;
      gestione_successioni_titr (a_documento_id,
                                  a_utente,
                                  a_ctr_denuncia,
                                  a_sezione_unica,
                                  a_fonte,
                                  w_titr,
                                  a_nuove_pratiche,
                                  a_nuovi_oggetti,
                                  a_nuovi_contribuenti,
                                  a_nuovi_soggetti,
                                  a_pratiche_gia_inserite
                                 );
      begin
          update documenti_caricati
             set stato = 2
               , data_variazione = sysdate
               , utente = a_utente
               , note = decode(note,null,'',note||'     ')||w_titr||': ctr denuncia: '||a_ctr_denuncia
                      ||' - sezione unica: '||a_sezione_unica
                      ||' - fonte: '||to_char(a_fonte)
                      ||' - successioni trattate: '||to_char(a_successioni)
                      ||' - successioni già inserite: '||to_char(a_succ_gia_inserite)
                      ||' - pratiche: '||to_char(a_nuove_pratiche)
                      ||' - nuovi oggetti: '||to_char(a_nuovi_oggetti)
                      ||' - nuovi contribuenti: '||to_char(a_nuovi_contribuenti)
                      ||' - nuovi soggetti: '||to_char(a_nuovi_soggetti)
                      ||' - pratiche già inserite: '||a_pratiche_gia_inserite
           where documento_id = a_documento_id
               ;
      EXCEPTION
          WHEN others THEN
             sql_errm  := substr(SQLERRM,1,100);
             w_errore := 'Errore in Aggiornamento Dati del documento per '||w_titr||' '||
                                        ' ('||sql_errm||')';
             raise_application_error(-20999, w_errore);
      end;
      w_messaggio := w_titr||':'||chr(10)||chr(13)
                ||'Trattate '||to_char(a_successioni)||' successioni'||chr(13)
                ||to_char(a_succ_gia_inserite)||' successioni già inserite'||chr(13)
                ||'Inserite '||to_char(a_nuove_pratiche)||' pratiche'||chr(13)
                ||'Inseriti '||to_char(a_nuovi_oggetti)||' nuovi oggetti'||chr(13)
                ||'Inseriti '||to_char(a_nuovi_contribuenti)||' nuovi contribuenti'||chr(13)
                ||'Inseriti '||to_char(a_nuovi_soggetti)||' nuovi soggetti'||chr(13)
                ||to_char(a_pratiche_gia_inserite)||' pratiche già inserite';
      IF nvl(w_messaggio_tot, ' ') = ' ' THEN
         w_messaggio_tot := w_messaggio;
      ELSE
         w_messaggio_tot :=
                         w_messaggio_tot || CHR (10) || CHR (13)
                         || w_messaggio;
      END IF;
   END LOOP;
   a_messaggio := w_messaggio_tot;
END;
/* End Procedure: GESTIONE_SUCCESSIONI */
/

