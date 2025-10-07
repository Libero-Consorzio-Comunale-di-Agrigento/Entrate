--liquibase formatted sql 
--changeset abrandolini:20250326_152429_tr4_codice_fiscale stripComments:false runOnChange:true 
 
CREATE OR REPLACE PACKAGE TR4_CODICE_FISCALE IS
/******************************************************************************
 NOME:        CODICE_FISCALE.
 DESCRIZIONE: Package per gestione CODICE_FISCALE.
 ANNOTAZIONI: Salvato nella directory ins di AD4 nel file codfis.pks.
 ECCEZIONI:.
 REVISIONI:
 Rev. Data       Autore Descrizione
 ---- ---------- ------ ------------------------------------------------------
 0    17/01/2003 MM     Creazione.
 2    03/05/2007 MM     A20821.0.0: aggiunti i parametri p_cognome e p_nome
                        alle funzioni controllo e gestito nuovo errore in
                        get_error_msg.
 3    14/05/2007 MM     Duplicazione funzioni CONTROLLO con parametro
                        p_data_nascita date.
 4    25/02/2008 MM     Creazione procedure GET_DATI e funzioni
                        GET_PROVINCIA_NAS, GET_COMUNE_NAS, GET_DATA_NAS,
                        GET_SESSO.
******************************************************************************/
   FUNCTION  VERSIONE RETURN VARCHAR2;
/******************************************************************************
 NOME:        CREA.
 DESCRIZIONE: Determinazione Codice Fiscale.
 ARGOMENTI:   p_cognome:        cognome dell'individuo
              p_nome:           nome dell'individuo
              p_data:           data di nascita dell'individuo
              p_codice_catasto: codice catasto del comune di nascita dell'individuo
              p_sesso:          sesso dell'individuo
              p_codice_fiscale:   codice fiscale dell'individuo calcolato
 ECCEZIONI:   -20940: I parametri 'p_cognome', 'p_nome', 'p_data', '
                      'p_codice_catasto' e ''p_sesso'' NON possono essere NULLI.
 ANNOTAZIONI: presa da P00(PanamaASS).
******************************************************************************/
   PROCEDURE CREA ( p_cognome        IN     VARCHAR2
                  , p_nome           IN     VARCHAR2
                  , p_data           IN     DATE
                  , p_codice_catasto IN     VARCHAR2
                  , p_sesso          IN     VARCHAR2
                  , p_codice_fiscale IN OUT VARCHAR2);
/******************************************************************************
 NOME:        CREA.
 DESCRIZIONE: Determinazione Codice Fiscale
              Lancia la procedura omonima dopo aver calcolato, dal codice del
              comune e della provincia di nascita, il codice catasto corrispondente.
 ARGOMENTI:   p_cognome:        cognome dell'individuo
              p_nome:           nome dell'individuo
              p_data:           data di nascita dell'individuo
              p_comune_nas:     codice del comune di nascita dell'individuo
              p_provincia_nas:  codice della provincia di nascita dell'individuo
              p_sesso:          sesso dell'individuo
              p_codice_fiscale:   codice fiscale dell'individuo calcolato.
 ECCEZIONI:   -20920: Errore in selezione Codice Catasto.
******************************************************************************/
   PROCEDURE CREA ( p_cognome        IN     VARCHAR2
                  , p_nome           IN     VARCHAR2
                  , p_data           IN     DATE
                  , p_comune_nas     IN     NUMBER
                  , p_provincia_nas  IN     NUMBER
                  , p_sesso          IN     VARCHAR2
                  , p_codice_fiscale IN OUT VARCHAR2);
   FUNCTION CREA
/******************************************************************************
 NOME:        CREA.
 DESCRIZIONE: Determinazione Codice Fiscale
 ARGOMENTI:   .
 ECCEZIONI:   -20920: Errore in selezione Codice Catasto.
 ANNOTAZIONI: -
 REVISIONI:
 Rev. Data       Autore Descrizione
 ---- ---------- ------ ------------------------------------------------------
 0    17/01/2003 MM     Creazione.
******************************************************************************/
   ( p_cognome        IN     VARCHAR2
   , p_nome           IN     VARCHAR2
   , p_data           IN     DATE
   , p_comune_nas     IN     NUMBER
   , p_provincia_nas  IN     NUMBER
   , p_sesso          IN     VARCHAR2)
   RETURN VARCHAR2;
/******************************************************************************
 NOME:        CONTROLLO.
 DESCRIZIONE: Controllo CODICE FISCALE e PARTITA IVA.
              Lancia la funzione omonima dopo aver calcolato, dal codice del
              comune e della provincia di nascita, il codice catasto corrispondente.
  PARAMETRI:  p_codice_fiscale    codice fiscale o partita iva
              p_sesso             assume il valore relativo o il valore '*' se si
                                  desidera un controllo limitato del codice fiscale.
              p_comune_nas        codice del comune di nascita; e significativo
                                  solo per un controllo completo del codice fiscale.
              p_provincia_nas     codice della provincia di nascita; e significativo
                                  solo per un controllo completo del codice fiscale.
              p_data_nascita      data di nascita dell'individuo in formato
                                  dd/mm/yyyy; e' significativa solo per un controllo
                                  completo del codice fiscale.
              p_cognome           cognome dell'individuo; e' significativo solo
                                  per un controllo completo del codice fiscale.
              p_nome              nome dell'individuo; e' significativo solo per un
                                  controllo completo del codice fiscale.
    RITORNA:  NUMBER  Codice di errore
******************************************************************************/
   FUNCTION CONTROLLO ( p_codice_fiscale IN VARCHAR2
                      , p_sesso          IN VARCHAR2
                      , p_comune_nas     IN NUMBER
                      , p_provincia_nas  IN NUMBER
                      , p_data_nascita   IN VARCHAR2 DEFAULT NULL
                      , p_cognome        IN VARCHAR2 DEFAULT NULL
                      , p_nome           IN VARCHAR2 DEFAULT NULL)
   RETURN NUMBER;
/******************************************************************************
 NOME:        CONTROLLO.
 DESCRIZIONE: Controllo CODICE FISCALE e PARTITA IVA.
              I controlli operati sono:
              Cod.Fiscale :  a)- che il dato sia di 16 caratteri di cui:
                                 1^,2^,3^,4^,5^,6^,12^,16^ carattere alfa-
                                 betico maiuscolo, il 9^ alfabetico maiu-
                                 scolo e compreso tra i previsti per i mesi,
                                 7^,8^,10^,11^,13^,14^,15^ numerici.
                             b)- che 12^,13^,14^,15^ siano = al codice cata-
                                 sto.
                             c)- che il giorno di nascita sia corretto, ri-
                                 spetto al mese ed anno di nascita.
                             d)- che il check (16^ carattere) sia corretto.
              Il controllo parziale del codice fiscale che si ottiene passando
              il valore "*" nel sesso non esegue i punti b)- e c)- .
  PARAMETRI:  p_codice_fiscale    codice fiscale o partita iva
              p_sesso             assume il valore relativo o il valore '*' se si
                                  desidera un controllo limitato del codice fiscale.
              p_cod_catasto       codice catasto del comune di nascita; e'
                                  significativo solo per un controllo completo
                                  del codice fiscale.
              p_data_nascita      data di nascita dell'individuo in formato
                                  dd/mm/yyyy; e' significativa solo per un controllo
                                  completo del codice fiscale.
              p_cognome           cognome dell'individuo; e' significativo solo
                                  per un controllo completo del codice fiscale.
              p_nome              nome dell'individuo; e' significativo solo per un
                                  controllo completo del codice fiscale.
    RITORNA:  NUMBER  Codice di errore:
                0:  OK.
              - 1: Lunghezza errata.
              - 2: Codice errato. In corrispondenza degli identificativi del
                   nominativo, del 1. carattere del codice catasto o del
                   carattere di controllo devono comparire solo caratteri
                   alfabetici [A - Z].
              - 3: Codice errato. In corrispondenza degli identificativi di
                   anno e giorno di nascita e ultimi 3 caratteri del codice
                   catasto devono essere numerici [0 - 9].
              - 4: Codice errato. In corrispondenza del mese deve esserci un
                   carattere alfabetico significativo.
              - 5: Codice errato. Il Codice Catasto del Comune di Nascita deve
                   essere lo stesso del Codice Fiscale.
              - 6: Giorno di nascita errato.
              - 7: Peso relativo ai primi 15 caratteri del Codice Fiscale errato.
              - 8: Ultimo carattere errato.
              - 9: Check del codice fiscale errato.
              -10: Data di nascita e codice fiscale incompatibili.
              -11: Cognome / nome e codice fiscale incompatibili.
              -19: Errore non gestito.
              -21: Codice errato. Tutti i caratteri della Partita IVA devono essere
                   numerici.
              -22: Codice errato. Controllo check Partita IVA fallito.
******************************************************************************/
   FUNCTION CONTROLLO ( p_codice_fiscale IN VARCHAR2
                      , p_sesso          IN VARCHAR2 DEFAULT NULL
                      , p_cod_catasto    IN VARCHAR2 DEFAULT NULL
                      , p_data_nascita   IN VARCHAR2 DEFAULT NULL
                      , p_cognome        IN VARCHAR2 DEFAULT NULL
                      , p_nome           IN VARCHAR2 DEFAULT NULL)
   RETURN NUMBER;
/******************************************************************************
 NOME:        GET_ERROR_MSG
 DESCRIZIONE: Restituisce messaggio di errore associato a p_error.
 PARAMETRI:   p_error: codice di errore.
 RITORNA:     stringa varchar2 contenente messaggio di errore.
******************************************************************************/
   FUNCTION GET_ERROR_MSG ( p_error IN NUMBER ) RETURN VARCHAR2;
/******************************************************************************
 NOME:        GET_DATI.
 DESCRIZIONE: Ottiene tutte le informazioni che compongono il codice fiscale:
              sesso, data, provincia e comune di nascita.
              ATTENZIONE: la data di NASCITA potrebbe NON essere CORRETTA
              perche' dal c.f. e' possibile determinare solo le ultime 2 cifre
              dell'anno di nascita. Il secolo viene cosi determinato:
              - se 2 cifre sono < 50 e l'anno risultante e' < dell'anno in corso,
                  ritorna il secolo corrente;
              - altrimenti,
                  ritorna 19||2 cifre del c.f.
              Ad esempio:
              01 01 49  diventa 01/01/1949
              01 01 51  diventa 01/01/1951
              01 01 06  diventa 01/01/2006 (ma potrebbe essere anche 1906).
  ARGOMENTI:  p_codice_fiscale   IN  VARCHAR2      codice fiscale
              p_sesso            IN OUT VARCHAR2   sesso (F/M)
              p_data_nas         IN OUT VARCHAR2   data di nascita in formato
                                                   dd/mm/yyyyy.
              p_provincia_nas    IN OUT NUMBER     codice provincia di nascita
              p_comune_nas       IN OUT NUMBER     codice comune di nascita
******************************************************************************/
   PROCEDURE GET_DATI
   ( p_codice_fiscale IN VARCHAR2
   , p_sesso IN OUT VARCHAR2
   , p_data_nas IN OUT VARCHAR2
   , p_provincia_nas IN OUT NUMBER
   , p_comune_nas IN OUT NUMBER);
/******************************************************************************
 NOME:        GET_PROVINCIA_NAS.
 DESCRIZIONE: Ottiene il codice della provincia di nascita.
  PARAMETRI:  p_codice_fiscale    codice fiscale
    RITORNA:  NUMBER  Codice della provincia di nascita.
******************************************************************************/
   FUNCTION GET_PROVINCIA_NAS
   ( p_codice_fiscale IN VARCHAR2) RETURN NUMBER;
/******************************************************************************
 NOME:        GET_COMUNE_NAS.
 DESCRIZIONE: Ottiene il codice del comune di nascita.
  PARAMETRI:  p_codice_fiscale    codice fiscale
    RITORNA:  NUMBER  Codice del comune di nascita.
******************************************************************************/
   FUNCTION GET_COMUNE_NAS
   ( p_codice_fiscale IN VARCHAR2) RETURN NUMBER;
/******************************************************************************
 NOME:        GET_DATA_NAS.
 DESCRIZIONE: Ottiene la data di nascita.
              ATTENZIONE: la data di NASCITA potrebbe NON essere CORRETTA
              perche' dal c.f. e' possibile determinare solo le ultime 2 cifre
              dell'anno di nascita. Il secolo viene cosi determinato:
              - se 2 cifre sono < 50 e l'anno risultante e' < dell'anno in corso,
                  ritorna il secolo corrente;
              - altrimenti,
                  ritorna 19||2 cifre del c.f.
              Ad esempio:
              01 01 49  diventa 01/01/1949
              01 01 51  diventa 01/01/1951
              01 01 06  diventa 01/01/2006 (ma potrebbe essere anche 1906).
  PARAMETRI:  p_codice_fiscale    codice fiscale
    RITORNA:  varchar2  Data di nascita come stringa in formato dd/mm/yyyy.
******************************************************************************/
   FUNCTION GET_DATA_NAS
   ( p_codice_fiscale varchar2) return date;
/******************************************************************************
 NOME:        GET_SESSO
 DESCRIZIONE: Ottiene il sesso.
  PARAMETRI:  p_codice_fiscale    codice fiscale
    RITORNA:  varchar2  Sesso (F/M)
******************************************************************************/
   FUNCTION GET_SESSO
   ( p_codice_fiscale varchar2) return varchar2;
END TR4_CODICE_FISCALE;
/

CREATE OR REPLACE PACKAGE BODY TR4_CODICE_FISCALE IS
/******************************************************************************
 NOME:        CODICE_FISCALE.
 DESCRIZIONE: Package body per gestione CODICE_FISCALE.
 ANNOTAZIONI: Salvato nella directory ins di AD4 nel file codfis.pkb.
 ECCEZIONI:.
 REVISIONI:
 Rev. Data       Autore Descrizione
 ---- ---------- ------ ------------------------------------------------------
 0    17/01/2003 MM     Creazione.
 1    12/10/2004 SM     Revisione calcolo cf per errore nel calcolo con cognomi
                        e nomi con solo vocali
 2    03/05/2007 MM     A20821.0.0:
                        1. Richiamando la funzione CODICE_FISCALE.CONTROLLO con
                        parametri codice comune e codice provincia/stato il
                        controllo fallisce nel caso in cui si considera un
                        comune di uno stato estero.
                        2. Il controllo non verifica che nome e cognome
                        utilizzati corrispondano ai primi 6 caratteri del
                        codice fiscale.
 3    14/05/2007 MM     Duplicazione funzioni CONTROLLO con parametro
                        p_data_nascita date.
 4    25/02/2008 MM     Creazione procedure GET_DATI e funzioni pubbliche
                        GET_PROVINCIA_NAS, GET_COMUNE_NAS, GET_DATA_NAS,
                        GET_SESSO.
                        Creazione funzioni di servizio GET_CF_CHARTONUMBER,
                        GET_GIORNO_NAS, GET_MESE_NAS e GET_ANNO_NAS.
 5    22/12/2010 SNeg   Modificata get_dati per considerare data soppressione
 6    12/02/2018 SNeg   In caso di stato estero considerare la validita e solo
                        la provincia e non il comune.
 7    07/11/2018 MTurra Gestione Omocodie
 8    09/04/2019 SNegr  Errore in controllo codice fiscale x correzione rev.6 Bug #34283
 9    02/05/2019 SNegr  Errore in controllo codice fiscale x correzione rev.6 Bug #34643
******************************************************************************/
   FUNCTION VERSIONE
/******************************************************************************
 NOME:        VERSIONE
 DESCRIZIONE: Restituisce la versione e la data di distribuzione del package.
 PARAMETRI:   --
 RITORNA:     stringa varchar2 contenente versione.
 ECCEZIONI:   --
 ANNOTAZIONI: --
 REVISIONI:
 Rev. Data       Autore Descrizione
 ---- ---------- ------ ------------------------------------------------------
 0    17/01/2003 MM     Creazione.
******************************************************************************/
   RETURN VARCHAR2
   IS
   BEGIN
      RETURN 'V1.6';
   END VERSIONE;
   FUNCTION GET_ERROR_MSG
/******************************************************************************
 NOME:        GET_ERROR_MSG
 DESCRIZIONE: Restituisce messaggio di errore associato a p_error.
 PARAMETRI:   p_error: codice di errore.
 RITORNA:     stringa varchar2 contenente messaggio di errore.
 ECCEZIONI:   --
 ANNOTAZIONI: --
 REVISIONI:
 Rev. Data       Autore Descrizione
 ---- ---------- ------ ------------------------------------------------------
 0    17/01/2003 MM     Creazione.
 2    03/05/2007 MM     A20821.0.0: il controllo non verifica che nome e cognome
                        utilizzati corrispondano ai primi 6 caratteri del
                        codice fiscale.
******************************************************************************/
   (p_error NUMBER)
   RETURN VARCHAR2
   IS
   p_msg VARCHAR2(2000);
   BEGIN
      IF p_error = 0 THEN
         p_msg := '';
      ELSIF p_error <> -31 then -- parita iva
         p_msg := 'Errore '||p_error||'.'||CHR(13)||CHR(10)||'Controllo Codice Fiscale Fallito: ';
      else
         p_msg := 'Errore '||p_error||'. ';
      END IF;
      IF p_error = -1 THEN
         p_msg := p_msg||'lunghezza errata.';
      END IF;
      IF p_error = -2 THEN
         p_msg := p_msg||'in corrispondenza degli identificativi del nominativo, del primo carattere del codice catasto o del carattere di controllo devono comparire solo caratteri alfabetici [A - Z].';
      END IF;
      IF p_error = -3 THEN
         p_msg := p_msg||'in corrispondenza degli identificativi di anno e giorno di nascita e ultimi 3 caratteri del codice catasto devono essere numerici [0 - 9].';
      END IF;
      IF p_error = -4 THEN
         p_msg := p_msg||'in corrispondenza del mese deve esserci un carattere alfabetico significativo.';
      END IF;
      IF p_error = -5 THEN
         p_msg := p_msg||'il Codice Catasto del Comune di Nascita deve essere lo stesso del Codice Fiscale.';
      END IF;
      IF p_error = -6 THEN
         p_msg := p_msg||'giorno di nascita errato.';
      END IF;
      IF p_error = -7 THEN
         p_msg := p_msg||'peso relativo ai primi 15 caratteri del Codice Fiscale errato.';
      END IF;
      IF p_error = -8 THEN
         p_msg := p_msg||'ultimo carattere errato.';
      END IF;
      IF p_error = -9 THEN
         p_msg := p_msg||'check del codice fiscale errato.';
      END IF;
      IF p_error = -10 THEN
         p_msg := p_msg||'data di nascita e codice fiscale incompatibili.';
      END IF;
      -- Rev. 2    03/05/2007 MM     A20821.0.0.
      IF p_error = -11 THEN
         p_msg := p_msg||'cognome / nome e codice fiscale incompatibili.';
      END IF;
      -- Rev. 2    03/05/2007 MM     A20821.0.0: fine mod..
      IF p_error = -19 THEN
         p_msg := p_msg||'errore non gestito.';
      END IF;
      IF p_error = -20 THEN
         p_msg := p_msg||'impossibile selezionare Codice Catasto.';
      END IF;
      IF p_error = -30 THEN
         p_msg := p_msg||'tutti i caratteri della Partita IVA devono essere numerici.';
      END IF;
      IF p_error = -31 THEN
         p_msg := p_msg||'Controllo check Partita IVA fallito.';
      END IF;
      IF p_error = -40 THEN
         p_msg := p_msg||'i parametri ''p_cognome'', ''p_nome'', ''p_data'', ''p_codice_catasto'' e ''p_sesso'' NON possono essere NULLI.';
      END IF;
      RETURN p_msg;
   END GET_ERROR_MSG;
   FUNCTION GET_CF_CHARTONUMBER
/******************************************************************************
 NOME:        GET_CF_CHARTONUMBER
 DESCRIZIONE: Se il Codice Fiscale e' riferito ad un Omonimo, puo' avere uno o
              piu' caratteri alfabetici dove normalmente si trovano dei numeri,
              per cui, per eseguire correttamente il controllo, questi caratteri
              devono essere riportati al corrispondente valore numerico che
              avrebbero avuto se il soggetto non fosse stato un omonimo.
  PARAMETRI:  p_stringa    stringa da sostituire
    RITORNA:  NUMBER         numero corrispondente
 REVISIONI:
 Rev. Data       Autore Descrizione
 ---- ---------- ------ ------------------------------------------------------
 4    25/02/2008 MM     Creazione.
******************************************************************************/
   (  p_stringa in varchar2
   ) return VARCHAR2
   is
   begin
      return TRANSLATE(p_stringa,'LMNPQRSTUV', '0123456789');
   end;
   FUNCTION GET_GIORNO_NAS
/******************************************************************************
 NOME:        GET_GIORNO_NAS.
 DESCRIZIONE: Ottiene il giorno di nascita dal codice fiscale.
              Non effettua controlli (se il soggetto e' femmina sara' giorno + 40).
  PARAMETRI:  p_codice_fiscale    codice fiscale
    RITORNA:  NUMBER  Giorno di nascita.
 REVISIONI:
 Rev. Data       Autore Descrizione
 ---- ---------- ------ ------------------------------------------------------
 4    25/02/2008 MM     Creazione.
 7   07/11/2018 MTurra Gestione Omocodie
******************************************************************************/
   ( p_codice_fiscale varchar2
   ) return integer
   is
     w_giorno number;
   begin
     begin
      w_giorno := TO_NUMBER(GET_CF_CHARTONUMBER(SUBSTR(p_codice_fiscale,10,2)));
     exception
       when others then
         w_giorno := to_number(null);
     end;
     return w_giorno;
   end;
   FUNCTION GET_MESE_NAS
/******************************************************************************
 NOME:        GET_MESE_NAS.
 DESCRIZIONE: Ottiene il mese di nascita dal codice fiscale.
  PARAMETRI:  p_codice_fiscale    codice fiscale
    RITORNA:  NUMBER  Mese di nascita.
 REVISIONI:
 Rev. Data       Autore Descrizione
 ---- ---------- ------ ------------------------------------------------------
 4    25/02/2008 MM     Creazione.
******************************************************************************/
   ( p_codice_fiscale varchar2) return integer is
   w_mese               number;
   begin
      begin
      w_mese := instr('ABCDEHLMPRST', SUBSTR(p_codice_fiscale,9,1));
      exception
        when others then
          w_mese := to_number(null);
      end;
      if w_mese not between 1 and 12 then
         w_mese := to_number(null);
      end if;
      return w_mese;
   end;
   FUNCTION GET_ANNO_NAS
/******************************************************************************
 NOME:        GET_ANNO_NAS.
 DESCRIZIONE: Ottiene l'anno di nascita dal codice fiscale.
  PARAMETRI:  p_codice_fiscale    codice fiscale
    RITORNA:  NUMBER  Anno di nascita (ultime 2 cifre).
 REVISIONI:
 Rev. Data       Autore Descrizione
 ---- ---------- ------ ------------------------------------------------------
 4    25/02/2008 MM     Creazione.
 7    07/11/2018 MTurra Gestione Omocodie
******************************************************************************/
   ( p_codice_fiscale varchar2
   ) return integer
   is
   w_anno integer;
   begin
     begin
      w_anno := TO_NUMBER(GET_CF_CHARTONUMBER(SUBSTR(p_codice_fiscale,7,2)));
     exception
       when others then
         w_anno := to_number(null);
     end;
     return w_anno;
   end;
   FUNCTION CONTROLLO
/******************************************************************************
 NOME:        CONTROLLO.
 DESCRIZIONE: Controllo CODICE FISCALE e PARTITA IVA.
              I controlli operati sono:
              Cod.Fiscale :  a)- che il dato sia di 16 caratteri di cui:
                                 1^,2^,3^,4^,5^,6^,12^,16^ carattere alfa-
                                 betico maiuscolo, il 9^ alfabetico maiu-
                                 scolo e compreso tra i previsti per i mesi,
                                 7^,8^,10^,11^,13^,14^,15^ numerici.
                             b)- che 12^,13^,14^,15^ siano = al codice cata-
                                 sto.
                             c)- che il giorno di nascita sia corretto, ri-
                                 spetto al mese ed anno di nascita.
                             d)- che il check (16^ carattere) sia corretto.
              Il controllo parziale del codice fiscale che si ottiene passando
              il valore "*" nel sesso non esegue i punti b)- e c)- .
  PARAMETRI:  p_codice_fiscale    codice fiscale
              p_sesso             assume il valore relativo o il valore '*' se si
                                  desidera un controllo limitato del codice fiscale.
              p_cod_catasto       e' significativo solo per un controllo completo
                                  di un codice fiscale.
              p_data_nascita      data di nascita dell'individuo in formato
                                  dd/mm/yyyy; e' significativa solo per un controllo
                                  completo del codice fiscale.
              p_cognome           cognome dell'individuo; e' significativo solo
                                  per un controllo completo del codice fiscale.
              p_nome              nome dell'individuo; e' significativo solo per un
                                  controllo completo del codice fiscale.
    RITORNA:  NUMBER  Codice di errore:
                0:  OK.
              - 1: Lunghezza errata.
              - 2: Codice errato. In corrispondenza degli identificativi del
                   nominativo, del 1? carattere del codice catasto o del
                   carattere di controllo devono comparire solo caratteri
                   alfabetici [A - Z].
              - 3: Codice errato. In corrispondenza degli identificativi di
                   anno e giorno di nascita e ultimi 3 caratteri del codice
                  catasto devono essere numerici [0 - 9].
              - 4: Codice errato. In corrispondenza del mese deve esserci un
                   carattere alfabetico significativo.
              - 5: Codice errato. Il Codice Catasto del Comune di Nascita deve
                   essere lo stesso del Codice Fiscale.
              - 6: Giorno di nascita errato.
              - 7: Peso relativo ai primi 15 caratteri del Codice Fiscale errato.
              - 8: Ultimo carattere errato.
              - 9: Check del codice fiscale errato.
              -10: Data di nascita e codice fiscale incompatibili.
              -11: Cognome / nome e codice fiscale incompatibili.
              -19: Errore non gestito.
              -21: Codice errato. Tutti i caratteri della Partita IVA devono essere
                   numerici.
              -22: Codice errato. Controllo check Partita IVA fallito.
 ECCEZIONI:   -
 ANNOTAZIONI: -
 REVISIONI:
 Rev. Data       Autore Descrizione
 ---- ---------- ------ ------------------------------------------------------
 0    17/01/2003 MM     Creazione.
 2    03/05/2007 MM     A20821.0.0: il controllo non verifica che nome e cognome
                        utilizzati corrispondano ai primi 6 caratteri del
                        codice fiscale.
 3    29/11/2007 MM     A24319.0.0: La funzione controllo del package codice
                        fiscale non gestisce correttamente le omocodie.
******************************************************************************/
   ( p_codice_fiscale IN VARCHAR2
   , p_sesso IN VARCHAR2
   , p_cod_catasto IN VARCHAR2
   , p_data_nascita IN VARCHAR2
   , p_cognome IN VARCHAR2
   , p_nome IN VARCHAR2)
   RETURN NUMBER
   IS
      TYPE validChar IS
        VARRAY(36) OF VARCHAR2(1);
      sChar            validChar := validChar ('A','B','C','D','E','F','G','H','I','J',
                                               'K','L', 'M','N','O','P','Q','R','S','T',
                                               'U','V','W','X','Y','Z','0','1','2','3',
                                               '4','5','6','7','8','9');
      TYPE Pari IS
        VARRAY(36) OF INT;
      iPari            Pari := Pari ( 00,01,02,03,04,05,06,07,08,09,10,11,
                                      12,13,14,15,16,17,18,19,20,21,22,23,
                                      24,25,00,01,02,03,04,05,06,07,08,09);
      TYPE Disp IS
        VARRAY(36) OF INT;
      iDisp            Disp := Disp ( 01,00,05,07,09,13,15,17,19,21,02,04,
                                      18,20,11,03,06,08,12,14,16,10,22,25,
                                      24,23,01,00,05,07,09,13,15,17,19,21);
      TYPE CodiceFiscale IS
        VARRAY(16) OF VARCHAR2(1);
      sCodice          CodiceFiscale := CodiceFiscale ( NULL,NULL,NULL,NULL,
                                                        NULL,NULL,NULL,NULL,
                                                        NULL,NULL,NULL,NULL,
                                                        NULL,NULL,NULL,NULL);
      sCodiceFiscale   VARCHAR2(16);
      dError           NUMBER;
      iIndice          NUMBER(2);
      iIndice2         NUMBER(2);
      iGiorno          NUMBER(2);
      iMese            NUMBER(2);
      iAnno            NUMBER(4);
      iFineMese        NUMBER(2);
      iSomma           NUMBER;
      sSesso           VARCHAR2(1);
      CODICE_ERRATO    EXCEPTION;
   BEGIN
      dError := 0;
      IF p_codice_fiscale IS NOT NULL THEN
         -- Controllo lunghezza
         IF LENGTH(p_codice_fiscale) NOT IN (16, 11) THEN
          dError := -1;
            RAISE CODICE_ERRATO;
         END IF;
         sCodiceFiscale := p_codice_fiscale;
         -- Si trasferisce il codice in un array per poterlo analizzare
         iIndice := 0;
         WHILE iIndice < LENGTH(sCodiceFiscale) LOOP
           iIndice := iIndice + 1;
            sCodice(iIndice) := SUBSTR(sCodiceFiscale,iIndice,1);
         END LOOP;
         IF LENGTH(sCodiceFiscale) = 16 THEN
         -- |////////////////////////////////////////////////////////|
         -- |   Controlli eseguiti solo in caso di CODICE FISCALE    |
         -- |////////////////////////////////////////////////////////|
            -- Se il Codice Fiscale e' riferito ad un Omonimo, puo' avere uno o
            -- piu' caratteri alfabetici dove normalmente si trovano dei numeri,
            -- per cui, per eseguire correttamente il controllo, questi caratteri
            -- vengono riportati al corrispondente valore numerico che avrebbero
            -- avuto se il soggetto non fosse stato un omonimo.
            iIndice := 0;
            WHILE iIndice < 16 LOOP
               iIndice := iIndice + 1;
               IF iIndice > 6 AND iIndice < 16 AND iIndice <> 9 AND iIndice <> 12 THEN
                  IF sCodice(iIndice) in ('L', 'M', 'N', 'P', 'Q', 'R', 'S', 'T', 'U', 'V') THEN
                     sCodice(iIndice) := GET_CF_CHARTONUMBER(sCodice(iIndice));
                  END IF;
               END IF;
               -- Si controlla che esistano caratteri alfabetici in corrispondenza
               -- degli identificativi del nominativo, del 1^ carattere del codice
               -- catasto e del carattere di controllo, che esistano caratteri nu-
               -- merici in corrispondenza degli identificativi di anno e giorno di
               -- nascita e ultimi 3 caratteri del codice catasto e che il mese sia
               -- alfabetico e compreso nella gamma significativa associata ai mesi.
               IF iIndice < 7 OR iIndice IN (12, 16) THEN
                  IF sCodice(iIndice) < 'A' OR sCodice(iIndice) > 'Z' THEN
                     dError := -2;
                     RAISE CODICE_ERRATO;
                  END IF;
               ELSE
                  IF iIndice IN (7, 8, 10, 11, 13, 14, 15) THEN
                     IF sCodice(iIndice) < '0' OR   sCodice(iIndice) > '9' THEN
                        dError := -3;
                        RAISE CODICE_ERRATO;
                     END IF;
                  ELSE
                     IF  sCodice(iIndice) NOT IN ('A', 'B', 'C', 'D', 'E', 'H', 'L', 'M',
                                              'P', 'R', 'S', 'T') THEN
                        dError := -4;
                       RAISE CODICE_ERRATO;
                     END IF;
                  END IF;
               END IF;
            END LOOP;
      -- +--------------------------------------------------------+
      -- | INIZIO controlli NON ESEGUITI per elaborazione RIDOTTA |
      -- |                                                        |
      -- +--------------------------------------------------------+
            sSesso := NVL(p_sesso, '*');
            IF sSesso <> '*' THEN
               -- Controllo che il Codice Catasto del Comune di Nascita sia
               -- lo stesso del Codice Fiscale
               -- Rev, 3    29/11/2007 MM     A24319.0.0.
               -- IF SUBSTR(sCodiceFiscale,12,4) <> p_cod_catasto THEN
               IF sCodice(12)||sCodice(13)||sCodice(14)||sCodice(15) <> p_cod_catasto THEN
                  dError := -5;
                  RAISE CODICE_ERRATO;
               END IF;
            -- Controllo della correttezza del giorno della data di nascita
               iGiorno := GET_GIORNO_NAS(sCodiceFiscale);
               iMese := GET_MESE_NAS(sCodiceFiscale);
               iAnno := GET_ANNO_NAS(sCodiceFiscale);
               SELECT TO_CHAR(LAST_DAY(TO_DATE(LPAD(TO_CHAR(iMese),2,'0')
                    ||LPAD(TO_CHAR(iAnno),2,'0'),'mmyy')),'dd')
                 INTO iFineMese
                 FROM DUAL
               ;
               -- Se il sesso e' femmina, si toglie 40 dal giorno di nascita
               IF sSesso = 'F' THEN
                 iGiorno := iGiorno - 40;
               END IF;
               IF iGiorno > iFineMese OR iGiorno < 1 THEN
                  dError := -6;
                  RAISE CODICE_ERRATO;
               END IF;
               -- Controlla compatibilita' tra eventuale Data di nascita passata (p_data_nascita)
               -- e codice fiscale.
               IF p_data_nascita IS NOT NULL THEN
                  IF LPAD(iGiorno,2,'0') <> SUBSTR(p_data_nascita,1,2)
                  OR LPAD(iMese,2,'0')     <> SUBSTR(p_data_nascita,4,2)
                  OR iAnno               <> SUBSTR(p_data_nascita,9,2) THEN
                     dError := -10;
                     RAISE CODICE_ERRATO;
                  END IF;
               END IF;
               -- Rev. 2    03/05/2007 MM     A20821.0.0
               -- Controlla compatibilita' tra eventuali cognome e nome passati
               -- e codice fiscale.
               IF p_cognome IS NOT NULL and p_nome IS NOT NULL THEN
                  declare
                     d_data_nas        date;
                     d_codice_fiscale  varchar2(16);
                  begin
                     d_data_nas := nvl(to_date(p_data_nascita,'dd/mm/yyyy'),to_date('01/01/1951','dd/mm/yyyy'));
                     CREA( p_cognome, p_nome, d_data_nas, p_cod_catasto, p_sesso, d_codice_fiscale);
                     if upper(substr(d_codice_fiscale,1,6)) != upper(substr(p_codice_fiscale,1,6)) then
                        dError := -11;
                        RAISE CODICE_ERRATO;
                     END IF;
                  end;
               END IF;
               -- Rev. 2    03/05/2007 MM     A20821.0.0: fine mod.
            END IF;
      -- +--------------------------------------------------------+
      -- |   FINE controlli NON ESEGUITI per elaborazione RIDOTTA |
      -- |                                                        |
      -- +--------------------------------------------------------+
            -- Rev, 3    29/11/2007 MM     A24319.0.0.
            -- Si ritrasferisce il codice iniziale nell'array per il calcolo
            -- del carattere di check finale, perche deve essere effettuato sul
            -- codice fiscale originale (alcune lettere potrebbero essere state
            -- sostituite da numeri per i casi di omocodia ed avere quindi 'pesi'
            -- diversi).
            iIndice := 0;
            WHILE iIndice < LENGTH(sCodiceFiscale) LOOP
              iIndice := iIndice + 1;
               sCodice(iIndice) := SUBSTR(sCodiceFiscale,iIndice,1);
            END LOOP;
            -- Rev, 3    29/11/2007 MM     A24319.0.0. fine mod.
            -- Routine per la determinazione del "Peso" relativo ai primi
            -- 15 caratteri del Codice Fiscale
            iSomma   := 0;
            iIndice  := 0;
            WHILE iIndice < 15 LOOP
               iIndice := iIndice + 1;
               iIndice2 := 0;
               WHILE TRUE LOOP
                  iIndice2 := iIndice2 + 1;
                  IF iIndice2 > 36 THEN
                      dError := -7;
                    RAISE CODICE_ERRATO;
                  END IF;
                  IF sChar(iIndice2) = sCodice(iIndice) THEN
                     EXIT;
                  END IF;
               END LOOP;
               IF MOD(iIndice,2) = 0 THEN
                  iSomma := iSomma + iPari(iIndice2);
               ELSE
                  iSomma := iSomma + iDisp(iIndice2);
               END IF;
            END LOOP;
            -- Il resto della somma dei pesi divisa per 26 deve corrispondere
            -- ad un carattere della tabella Ipari il cui valore deve essere
            -- il check del Codice Fiscale (16^ carattere).
            iIndice := 0;
            WHILE TRUE LOOP
               iIndice := iIndice + 1;
               IF iIndice > 36 THEN
                   dError := -8;
                 RAISE CODICE_ERRATO;
               END IF;
               IF iPari(iIndice) = MOD(iSomma,26) THEN
                  EXIT;
               END IF;
            END LOOP;
            -- Controllo check del Codice Fiscale
            IF sChar(iIndice) <> sCodice(16) THEN
               dError := -9;
               RAISE CODICE_ERRATO;
            END IF;
         ELSE
      -- |////////////////////////////////////////////////////////|
      -- |   Controlli eseguiti solo in caso di Partita IVA       |
      -- |////////////////////////////////////////////////////////|
            -- Tutti i caratteri della Partita IVA devono essere numerici
            iIndice := 0;
            WHILE iIndice < 11 LOOP
               iIndice := iIndice + 1;
               IF sCodice(iIndice) < '0' OR sCodice(iIndice) > '9'  THEN
                  dError := -30;
                  RAISE CODICE_ERRATO;
               END IF;
            END LOOP;
            -- Controlla che i primi sette carattere non siano tutti = 0 e che l'ottavo,
             -- il nono ed il decimo carattere siano compresi tra 0 e 100.
            IF SUBSTR(p_codice_fiscale,1,7) = '0000000' OR SUBSTR(p_codice_fiscale,8,3) = '000' THEN
               dError := -31;
               RAISE CODICE_ERRATO;
            END IF;
            -- Routine per la determinazione del "Peso" relativo ai primi 10 caratteri
             -- della Partita IVA.
            iSomma := 0;
            iIndice := 0;
            WHILE iIndice < 10 LOOP
                iIndice := iIndice + 1;
               IF MOD(iIndice,2) = 0 THEN
                  IF sCodice(iIndice) < '5' THEN
                     iSomma := iSomma + TO_NUMBER(sCodice(iIndice)) * 2;
                  ELSE
                     iSomma := iSomma + TO_NUMBER(sCodice(iIndice)) * 2 + 1;
                  END IF;
               ELSE
                  iSomma := iSomma + TO_NUMBER(sCodice(iIndice));
               END IF;
            END LOOP;
            -- Controllo check Partita IVA
            IF MOD(10 - MOD(iSomma,10),10) <> TO_NUMBER(sCodice(11)) THEN
               dError := -31;
               RAISE CODICE_ERRATO;
            END IF;
         END IF;
      END IF;
      RETURN dError;
   EXCEPTION
      WHEN CODICE_ERRATO THEN
         RETURN dError;
      WHEN OTHERS THEN
         dError := -19;
         RETURN dError;
   END CONTROLLO;
   FUNCTION CONTROLLO
/******************************************************************************
 NOME:        CONTROLLO.
 DESCRIZIONE: Controllo CODICE FISCALE e PARTITA IVA.
              Lancia la funzione omonima dopo aver calcolato, dal codice del
              comune e della provincia di nascita, il codice catasto corrispondente.
  PARAMETRI:  p_codice_fiscale    codice fiscale o partita iva
              p_sesso             assume il valore relativo o il valore '*' se si
                                  desidera un controllo limitato del codice fiscale.
              p_cod_catasto       e' significativo solo per un controllo completo
                                  di un codice fiscale.
              p_data_nascita      data di nascita dell'individuo in formato
                                  dd/mm/yyyy; e' significativa solo per un controllo
                                  completo del codice fiscale.
              p_cognome           cognome dell'individuo; e' significativo solo
                                  per un controllo completo del codice fiscale.
              p_nome              nome dell'individuo; e' significativo solo per un
                                  controllo completo del codice fiscale.
    RITORNA:  NUMBER  Codice di errore
 REVISIONI:
 Rev. Data       Autore Descrizione
 ---- ---------- ------ ------------------------------------------------------
 0    14/05/2007 MM     Creazione.
 6    12/02/2018 SNeg   In caso di stato estero considerare la validita e solo
                        la provincia e non il comune.
 8    09/04/2019 SNegr  Errore in controllo codice fiscale x correzione rev.6 Bug #34283
 9    02/05/2019 SNegr  Errore in controllo codice fiscale x correzione rev.6 Bug #34643
******************************************************************************/
   ( p_codice_fiscale IN VARCHAR2
   , p_sesso IN VARCHAR2
   , p_comune_nas IN NUMBER
   , p_provincia_nas IN NUMBER
   , p_data_nascita IN VARCHAR2
   , p_cognome IN VARCHAR2
   , p_nome IN VARCHAR2)
   RETURN NUMBER
   IS
      dCodiceCatasto   VARCHAR2(4);
      dReturn          NUMBER;
      d_comune_nas     NUMBER;
   BEGIN
      if p_sesso <> '*' then
         -- Rev. 2    03/05/2007 MM     A20821.0.0
         -- Verifico se e' stato estero
         if  p_provincia_nas >= 200 and p_comune_nas > 0
         and (p_comune_nas <= 700 OR p_provincia_nas NOT IN (701,702,703)) then
           d_comune_nas := 0;
           -- Rev. 6    12/02/2018 SN
         BEGIN
            SELECT sigla_cfis
              INTO dCodiceCatasto
              FROM AD4_COMUNI
             WHERE Comune          = d_comune_nas AND -- rev.8
                   provincia_stato = p_provincia_nas
                    and to_date(p_data_nascita,'dd/mm/yyyy') <= nvl(data_soppressione, to_date('3333333','j'))
                    and not exists (select 'x'
                                      from ad4_comuni c
                                     where provincia_stato = p_provincia_nas
                                       -- rev. 9 inizio
                                       and comune = d_comune_nas
                                       -- rev. 9 fine
                                       and to_date(p_data_nascita,'dd/mm/yyyy') <= nvl(data_soppressione, to_date('3333333','j'))
                                       and nvl(c.data_soppressione, to_date('3333333','j'))<
                                         nvl(ad4_comuni.data_soppressione, to_date('3333333','j')))
            ;
         -- Rev. 6    12/02/2018 SN     fine mod.
         EXCEPTION
            WHEN OTHERS THEN
               RETURN -20;
         END;
         else
           d_comune_nas := p_comune_nas;
           BEGIN
            SELECT sigla_cfis
              INTO dCodiceCatasto
              FROM AD4_COMUNI
             WHERE Comune          = d_comune_nas
               AND provincia_stato = p_provincia_nas
            ;
         EXCEPTION
            WHEN OTHERS THEN
               RETURN -20;
         END;
         end if;
         -- Rev. 2    03/05/2007 MM     A20821.0.0: fine mod.
      end if;
      -- Rev. 2    03/05/2007 MM     A20821.0.0
      -- Passo alla funzione omonima anche cognome e nome.
      dReturn := CONTROLLO(p_codice_fiscale, p_sesso, dCodiceCatasto, p_data_nascita, p_cognome, p_nome);
      -- Rev. 2    03/05/2007 MM     A20821.0.0: fine mod.
      RETURN dReturn;
   END CONTROLLO;
   PROCEDURE CREA
/******************************************************************************
 NOME:        CREA.
 DESCRIZIONE: Determinazione Codice Fiscale
 ECCEZIONI:   -20940: I parametri 'p_cognome', 'p_nome', 'p_data', '
                      'p_codice_catasto' e ''p_sesso'' NON possono essere NULLI.
 ANNOTAZIONI: presa da P00(PanamaASS).
 REVISIONI:
 Rev. Data       Autore Descrizione
 ---- ---------- ------ ------------------------------------------------------
 0    17/01/2003 MM     Creazione.
 1    12/10/2004 SM     Revisione calcolo cf per errore nel calcolo con cognomi
                        e nomi con solo vocali
******************************************************************************/
   ( p_cognome        IN     VARCHAR2
   , p_nome           IN     VARCHAR2
   , p_data           IN     DATE
   , p_codice_catasto IN     VARCHAR2
   , p_sesso          IN     VARCHAR2
   , p_codice_fiscale IN OUT VARCHAR2)
   IS
           stringa_car       VARCHAR(36) :=
           'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
           pesi_pari         VARCHAR(72) :=
   '000102030405060708091011121314151617181920212223242500010203040506070809';
           pesi_dispari      VARCHAR(72) :=
   '010005070913151719210204182011030608121416102225242301000507091315171921';
           stringa_mesi      VARCHAR(12) := 'ABCDEHLMPRST';
           Codice_Fiscale    VARCHAR(16) := NULL;
           ind1              NUMBER;
           ind2              NUMBER;
           ind3              NUMBER;
           somma             NUMBER(3);
           quoziente         NUMBER(3);
           differenza        NUMBER(3);
           cod_catasto       VARCHAR(4)  := P_CODICE_CATASTO;
           DATA              DATE        := P_DATA;
           sesso             VARCHAR(1)  := P_SESSO;
           giorno            VARCHAR(2);
           mese              VARCHAR(2);
           anno              VARCHAR(2);
           cognome           VARCHAR(40) := P_COGNOME;
           nome              VARCHAR(36) := P_NOME;
           cognome_cons      VARCHAR(40) := NULL;
           cognome_voc       VARCHAR(40) := NULL;
           nome_cons         VARCHAR(36) := NULL;
           nome_voc          VARCHAR(36) := NULL;
           char_123          VARCHAR(3);
           char_456          VARCHAR(3);
           char_9            VARCHAR(1);
           char_check        VARCHAR(1);
   BEGIN
      IF p_nome           IS NULL OR
         p_data           IS NULL OR
         p_codice_catasto IS NULL OR
         p_sesso          IS NULL
      THEN
        RAISE_APPLICATION_ERROR(-20940, GET_ERROR_MSG(-40));
     ELSE
         BEGIN
         /*                                                                */
         /*              Ricerca consonanti e vocali nel cognome           */
         /*              gli altri caratteri sono ignorati                 */
         /*                                                                */
            ind2 := 0;
            ind3 := 0;
            FOR ind1 IN 1..40 LOOP
               IF UPPER(SUBSTR(cognome,ind1,1)) IN
                  ('B','C','D','F','G','H','J','K','L','M','N','P','Q','R','S',
                   'T','V','W','X','Y','Z') THEN
                  ind2 := ind2 + 1;
                  cognome_cons := SUBSTR(cognome_cons,1,LENGTH(cognome_cons))||
                                  UPPER(SUBSTR(cognome,ind1,1));
               ELSIF
                  UPPER(SUBSTR(cognome,ind1,1)) IN
                  ('A','E','I','O','U') THEN
                  ind3 := ind3 + 1;
                  cognome_voc := SUBSTR(cognome_voc,1,LENGTH(cognome_voc))||
                                 UPPER(SUBSTR(cognome,ind1,1));
               END IF;
            END LOOP;
         /*                                                                */
         /*              Ricerca consonanti e vocali nel nome              */
         /*              gli altri caratteri sono ignorati                 */
         /*                                                                */
            ind2 := 0;
            ind3 := 0;
            FOR ind1 IN 1..36 LOOP
               IF UPPER(SUBSTR(nome,ind1,1)) IN
                  ('B','C','D','F','G','H','J','K','L','M','N','P','Q','R','S',
                   'T','V','W','X','Y','Z') THEN
                  ind2 := ind2 + 1;
                  nome_cons := SUBSTR(nome_cons,1,LENGTH(nome_cons))||
                               UPPER(SUBSTR(nome,ind1,1));
               ELSIF
                  UPPER(SUBSTR(nome,ind1,1)) IN
                  ('A','E','I','O','U') THEN
                  ind3 := ind3 + 1;
                  nome_voc := SUBSTR(nome_voc,1,LENGTH(nome_voc))||
                              UPPER(SUBSTR(nome,ind1,1));
               END IF;
            END LOOP;
         /*                                                           */
         /*               Determinazione Caratteri del Cognome        */
         /*                                                           */
            IF LENGTH(cognome_cons) > 2 THEN
               char_123 := SUBSTR(cognome_cons,1,3);
            ELSIF
               LENGTH(cognome_cons) = 2 THEN
                  IF LENGTH(cognome_voc) > 0 THEN
                    char_123 := SUBSTR(cognome_cons,1,2)||SUBSTR(cognome_voc,1,1);
                  ELSE
                    char_123 := SUBSTR(cognome_cons,1,2)||'X';
                  END IF;
            ELSIF
               LENGTH(cognome_cons) = 1 THEN
                  IF LENGTH(cognome_voc) > 1 THEN
                        char_123 := SUBSTR(cognome_cons,1,1)||SUBSTR(cognome_voc,1,2);
                  ELSIF LENGTH(cognome_voc)  = 1 THEN
                        char_123 := SUBSTR(cognome_cons,1,1)||SUBSTR(cognome_voc,1,1)||'X';
                  ELSE
                        char_123 := SUBSTR(cognome_cons,1,1)||'XX';
                  END IF;
            ELSIF
               LENGTH(cognome_cons) = 0 OR LENGTH(cognome_cons) IS NULL THEN
                  IF LENGTH(cognome_voc) > 2 THEN
                      char_123 := SUBSTR(cognome_voc,1,3);
                  ELSIF LENGTH(cognome_voc) = 2 THEN
                      char_123 := SUBSTR(cognome_voc,1,2)||'X';
                  ELSIF LENGTH(cognome_voc) = 1 THEN
                      char_123 := SUBSTR(cognome_voc,1,1)||'XX';
                  ELSE
                      char_123 := 'XXX';
                  END IF;
            END IF;
         /*                                                           */
         /*               Determinazione Caratteri del Nome           */
         /*                                                           */
            IF LENGTH(nome_cons) > 3 THEN
               char_456 := SUBSTR(nome_cons,1,1)||SUBSTR(nome_cons,3,2);
            ELSIF
               LENGTH(nome_cons) = 3 THEN
               char_456 := SUBSTR(nome_cons,1,3);
            ELSIF
               LENGTH(nome_cons) = 2 THEN
                 IF LENGTH(nome_voc) > 0 THEN
                    char_456 := SUBSTR(nome_cons,1,2)||SUBSTR(nome_voc,1,1);
                 ELSE
                     char_456 := SUBSTR(nome_cons,1,2)||'X';
                 END IF;
            ELSIF
               LENGTH(nome_cons) = 1 THEN
               IF LENGTH(nome_voc) > 1 THEN
                    char_456 := SUBSTR(nome_cons,1,1)||SUBSTR(nome_voc,1,2);
               ELSIF LENGTH(nome_voc) = 1 THEN
                    char_456 := SUBSTR(nome_cons,1,1)||SUBSTR(nome_voc,1,1)||'X';
               ELSE
                    char_456 := SUBSTR(nome_cons,1,1)||'XX';
               END IF;
            ELSIF
               LENGTH(nome_cons) = 0 OR LENGTH(nome_cons) IS NULL THEN
               IF LENGTH(nome_voc)  > 2 THEN
                    char_456 := SUBSTR(nome_voc,1,3);
               ELSIF LENGTH(nome_voc)  = 2 THEN
                    char_456 := SUBSTR(nome_voc,1,2)||'X';
               ELSIF LENGTH(nome_voc) = 1 THEN
                    char_456 := SUBSTR(nome_voc,1,1)||'XX';
               ELSE
                    char_456 := 'XXX';
               END IF;
            END IF;
         /*                                                           */
         /*      Determinazione Anno, Carattere del Mese, Giorno      */
         /*                                                           */
            giorno := SUBSTR(TO_CHAR(DATA,'dd/mm/yyyy'),1,2);
            mese   := SUBSTR(TO_CHAR(DATA,'dd/mm/yyyy'),4,2);
            anno   := SUBSTR(TO_CHAR(DATA,'dd/mm/yyyy'),9,2);
            char_9 := SUBSTR(stringa_mesi,TO_NUMBER(mese),1);
            IF sesso = 'F' THEN
               giorno := TO_CHAR(TO_NUMBER(giorno) + 40);
            END IF;
         /*                                                           */
         /*      Costruzione del Codice Fiscale                       */
         /*                                                           */
            Codice_Fiscale := char_123||char_456||anno||char_9||
                              giorno||cod_catasto;
         /*                                                           */
         /*      Calcolo del Check (ultimo carattere del codice)      */
         /*                                                           */
            somma := 0;
            FOR ind1 IN 1..15 LOOP
               ind2 := 1;
               WHILE SUBSTR(Codice_Fiscale,ind1,1) !=
                     SUBSTR(stringa_car,ind2,1) LOOP
                  ind2 := ind2+1;
               END LOOP;
               IF TRUNC(ind1 / 2) * 2 = ind1 THEN
                somma := somma+TO_NUMBER(SUBSTR(pesi_pari,(ind2-1)
                         *2+1,2));
               ELSE
                somma := somma+TO_NUMBER(SUBSTR(pesi_dispari,(ind2-1)
                         *2+1,2));
               END IF;
            END LOOP;
            quoziente  := TRUNC(somma / 26);
            differenza := somma-quoziente*26;
            ind2 := 1;
            WHILE TO_NUMBER(SUBSTR(pesi_pari,(ind2-1)*2+1,2)) != differenza
            LOOP
               ind2 := ind2+1;
            END LOOP;
         /*                                              */
         /*    Assegnazione del Check al Codice Fiscale  */
         /*                                              */
            Codice_Fiscale := SUBSTR(Codice_Fiscale,1,LENGTH(Codice_Fiscale))||
                              SUBSTR(stringa_car,ind2,1);
            P_CODICE_FISCALE := Codice_Fiscale;
         END;
      END IF;
   END CREA;
   PROCEDURE CREA
/******************************************************************************
 NOME:        CREA.
 DESCRIZIONE: Determinazione Codice Fiscale
 ARGOMENTI:   .
 ECCEZIONI:   -20920: Errore in selezione Codice Catasto.
 ANNOTAZIONI: -
 REVISIONI:
 Rev. Data       Autore Descrizione
 ---- ---------- ------ ------------------------------------------------------
 0    17/01/2003 MM     Creazione.
******************************************************************************/
   ( p_cognome        IN     VARCHAR2
   , p_nome           IN     VARCHAR2
   , p_data           IN     DATE
   , p_comune_nas     IN     NUMBER
   , p_provincia_nas  IN     NUMBER
   , p_sesso          IN     VARCHAR2
   , p_codice_fiscale IN OUT VARCHAR2)
   IS
      dCodiceCatasto   VARCHAR2(4);
     dReturn          NUMBER;
   BEGIN
      BEGIN
           SELECT sigla_cfis
            INTO dCodiceCatasto
            FROM AD4_COMUNI
           WHERE Comune          = p_comune_nas
             AND provincia_stato = p_provincia_nas
          ;
      EXCEPTION WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20920, GET_ERROR_MSG(-20));
      END;
     CREA(p_cognome, p_nome, p_data, dCodiceCatasto, p_sesso, p_codice_fiscale);
   END CREA;
   FUNCTION CREA
/******************************************************************************
 NOME:        CREA.
 DESCRIZIONE: Determinazione Codice Fiscale
 ARGOMENTI:   .
 ECCEZIONI:   -20920: Errore in selezione Codice Catasto.
 ANNOTAZIONI: -
 REVISIONI:
 Rev. Data       Autore Descrizione
 ---- ---------- ------ ------------------------------------------------------
 0    17/01/2003 MM     Creazione.
******************************************************************************/
   ( p_cognome        IN     VARCHAR2
   , p_nome           IN     VARCHAR2
   , p_data           IN     DATE
   , p_comune_nas     IN     NUMBER
   , p_provincia_nas  IN     NUMBER
   , p_sesso          IN     VARCHAR2)
   RETURN VARCHAR2
   IS
     dReturn          VARCHAR2(16);
   BEGIN
     CREA(p_cognome, p_nome, p_data, p_comune_nas, p_provincia_nas, p_sesso, dReturn);
     RETURN dReturn;
   EXCEPTION
      WHEN OTHERS THEN
         RETURN TO_CHAR(NULL);
   END CREA;
   PROCEDURE GET_DATI
/******************************************************************************
 NOME:        GET_DATI.
 DESCRIZIONE: Ottiene tutte le informazioni che compongono il codice fiscale:
              sesso, data, provincia e comune di nascita.
              ATTENZIONE: la data di NASCITA potrebbe NON essere CORRETTA
              perche' dal c.f. e' possibile determinare solo le ultime 2 cifre
              dell'anno di nascita. Il secolo viene cosi determinato:
              - se 2 cifre sono < 50 e l'anno risultante e' < dell'anno in corso,
                  ritorna il secolo corrente;
              - altrimenti,
                  ritorna 19||2 cifre del c.f.
              Ad esempio:
              01 01 49  diventa 01/01/1949
              01 01 51  diventa 01/01/1951
              01 01 06  diventa 01/01/2006 (ma potrebbe essere anche 1906).
  ARGOMENTI:  p_codice_fiscale   IN  VARCHAR2      codice fiscale
              p_sesso            IN OUT VARCHAR2   sesso (F/M)
              p_data_nas         IN OUT VARCHAR2   data di nascita in formato
                                                   dd/mm/yyyyy.
              p_provincia_nas    IN OUT NUMBER     codice provincia di nascita
              p_comune_nas       IN OUT NUMBER     codice comune di nascita
       NOTE:
 REVISIONI:
 Rev. Data       Autore Descrizione
 ---- ---------- ------ ------------------------------------------------------
 4    25/02/2008 MM     Creazione.
 5   22/12/2010 SNeg   Modificata get_dati per considerare data soppressione
******************************************************************************/
   ( p_codice_fiscale IN VARCHAR2
   , p_sesso IN OUT VARCHAR2
   , p_data_nas IN OUT VARCHAR2
   , p_provincia_nas IN OUT NUMBER
   , p_comune_nas IN OUT NUMBER)
   IS
      dCodFis varchar2(16) := upper(p_codice_fiscale);
      dCodCatasto varchar2(4) := substr(p_codice_fiscale, 12, 4);
      iGiorno integer;
      iMese integer;
      iAnno integer;
      dDataNas date;
      dReturn number;
      v_data_nas varchar2(10);
   BEGIN
      if dCodFis is not null and length(dCodFis) = 16
      then
         iGiorno := get_giorno_nas(dCodFis);
         if nvl(p_sesso, ' ') <> 'N'
         then
            if iGiorno > 40
            then
               p_sesso := 'F';
            else
               p_sesso := 'M';
            end if;
         else
            p_sesso := null;
         end if;
         if iGiorno > 40
          then
             iGiorno := iGiorno - 40;
          end if;
          iMese := get_mese_nas(dCodFis);
          iAnno := get_anno_nas(dCodFis);
          if iMese not between 1 and 12 then
             dDataNas := to_date(null);
          else
            begin
              dDataNas := to_date(LPAD(iGiorno,2,'0')||LPAD(iMese,2,'0')||LPAD(iAnno,2,'0'),'ddmmrr');
            exception
              when others then
                dDataNas := to_date(null);
            end;
          end if;
          if dDataNas is not null then
            if dDataNas > trunc(sysdate)
              then
                 v_data_nas := to_char(dDataNas,'dd/mm')||'/'||'19'||to_char(dDataNas,'yy');
              else
                 v_data_nas := to_char(dDataNas,'dd/mm/yyyy');
              end if;
          else
            v_data_nas := null;
          end if;
          if nvl(p_comune_nas, -1000) <> -1
           or nvl(p_provincia_nas, -1000) <> -1
           then
              begin
                 dCodCatasto := upper(substr(dCodCatasto, 1, 1) || get_cf_charToNumber(substr(dCodCatasto, 2, 1)) || get_cf_charToNumber(substr(dCodCatasto, 3, 1)) || get_cf_charToNumber(substr(dCodCatasto, 4, 1)));
                 -- ricava provincia e comune di nascita
                 select comune, provincia_stato
                   into p_comune_nas, p_provincia_nas
                   from ad4_comuni
                  where sigla_cfis = dCodCatasto
                    and to_date(v_data_nas,'dd/mm/yyyy') <= nvl(data_soppressione, to_date('3333333','j'))
                    and not exists (select 'x'
                                      from ad4_comuni c
                                     where sigla_cfis = dCodCatasto
                                       and to_date(v_data_nas,'dd/mm/yyyy') <= nvl(data_soppressione, to_date('3333333','j'))
                                       and nvl(c.data_soppressione, to_date('3333333','j'))<
                                         nvl(ad4_comuni.data_soppressione, to_date('3333333','j')))
                 ;
              exception
                 when others
                 then
                    p_comune_nas := null;
                    p_provincia_nas := null;
              end;
           else
              p_provincia_nas := null;
              p_comune_nas := null;
           end if;
         if nvl(p_data_nas, ' ') <> 'N'
         then
            p_data_nas := v_data_nas;
         else
            p_data_nas := null;
         end if;
      else
         p_sesso := null;
         p_data_nas := null;
         p_provincia_nas := null;
         p_comune_nas := null;
      end if;
   END GET_DATI;
   FUNCTION GET_PROVINCIA_NAS
/******************************************************************************
 NOME:        GET_PROVINCIA_NAS.
 DESCRIZIONE: Ottiene il codice della provincia di nascita.
  PARAMETRI:  p_codice_fiscale    codice fiscale
    RITORNA:  NUMBER  Codice della provincia di nascita.
 REVISIONI:
 Rev. Data       Autore Descrizione
 ---- ---------- ------ ------------------------------------------------------
 4    25/02/2008 MM     Creazione.
******************************************************************************/
   ( p_codice_fiscale IN VARCHAR2)
   RETURN NUMBER
   IS
      d_sesso VARCHAR2(1) := 'N';
      d_data_nas VARCHAR2(10) := 'N';
      d_provincia_nas NUMBER;
      d_comune_nas NUMBER;
   BEGIN
      get_dati(p_codice_fiscale, d_sesso, d_data_nas, d_provincia_nas, d_comune_nas);
      return d_provincia_nas;
   END GET_PROVINCIA_NAS;
   FUNCTION GET_COMUNE_NAS
/******************************************************************************
 NOME:        GET_COMUNE_NAS.
 DESCRIZIONE: Ottiene il codice del comune di nascita.
  PARAMETRI:  p_codice_fiscale    codice fiscale
    RITORNA:  NUMBER  Codice del comune di nascita.
 REVISIONI:
 Rev. Data       Autore Descrizione
 ---- ---------- ------ ------------------------------------------------------
 4    25/02/2008 MM     Creazione.
******************************************************************************/
   ( p_codice_fiscale IN VARCHAR2)
   RETURN NUMBER
   IS
      d_sesso VARCHAR2(1) := 'N';
      d_data_nas VARCHAR2(10) := 'N';
      d_provincia_nas NUMBER;
      d_comune_nas NUMBER;
   BEGIN
      get_dati(p_codice_fiscale, d_sesso, d_data_nas, d_provincia_nas, d_comune_nas);
      return d_comune_nas;
   END GET_COMUNE_NAS;
   FUNCTION GET_DATA_NAS
/******************************************************************************
 NOME:        GET_DATA_NAS.
 DESCRIZIONE: Ottiene la data di nascita.
              ATTENZIONE: la data di NASCITA potrebbe NON essere CORRETTA
              perche' dal c.f. e' possibile determinare solo le ultime 2 cifre
              dell'anno di nascita. Il secolo viene cosi determinato:
              - se 2 cifre sono < 50 e l'anno risultante e' < dell'anno in corso,
                  ritorna il secolo corrente;
              - altrimenti,
                  ritorna 19||2 cifre del c.f.
              Ad esempio:
              01 01 49  diventa 01/01/1949
              01 01 51  diventa 01/01/1951
              01 01 06  diventa 01/01/2006 (ma potrebbe essere anche 1906).
  PARAMETRI:  p_codice_fiscale    codice fiscale
    RITORNA:  varchar2  Data di nascita come stringa in formato dd/mm/yyyy.
 REVISIONI:
 Rev. Data       Autore Descrizione
 ---- ---------- ------ ------------------------------------------------------
 4    25/02/2008 MM     Creazione.
******************************************************************************/
   ( p_codice_fiscale varchar2) return date
   is
      d_sesso VARCHAR2(1) := 'N';
      d_data_nas VARCHAR2(10);
      d_provincia_nas NUMBER := -1;
      d_comune_nas NUMBER := -1;
   BEGIN
      get_dati(p_codice_fiscale, d_sesso, d_data_nas, d_provincia_nas, d_comune_nas);
      return to_date(d_data_nas,'dd/mm/yyyy');
   end GET_DATA_NAS;
   FUNCTION GET_SESSO
/******************************************************************************
 NOME:        GET_SESSO
 DESCRIZIONE: Ottiene il sesso.
  PARAMETRI:  p_codice_fiscale    codice fiscale
    RITORNA:  varchar2  Sesso (F/M)
 REVISIONI:
 Rev. Data       Autore Descrizione
 ---- ---------- ------ ------------------------------------------------------
 4    25/02/2008 MM     Creazione.
******************************************************************************/
   ( p_codice_fiscale varchar2) return varchar2
   is
      d_sesso VARCHAR2(1);
      d_data_nas VARCHAR2(10) := 'N';
      d_provincia_nas NUMBER := -1;
      d_comune_nas NUMBER := -1;
   BEGIN
      get_dati(p_codice_fiscale, d_sesso, d_data_nas, d_provincia_nas, d_comune_nas);
      return d_sesso;
   end GET_SESSO;
END TR4_CODICE_FISCALE;
/

