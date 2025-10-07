--liquibase formatted sql 
--changeset abrandolini:20250326_152429_afc_lob stripComments:false runOnChange:true 
 
CREATE OR REPLACE PACKAGE afc_lob
IS
/******************************************************************************
 Funzioni per la gestione degli oggetti di tipo LOB.
 REVISIONI.
 Rev. Data       Autore Descrizione
 ---- ---------- ------ ------------------------------------------------------
 00   30/08/2006 FT     Prima emissione.
 01   28/08/2007 FT     Aggiunte 2 versioni di to_blob (per varchar2 e clob), decode_value, versione di to_clob per blob e sql_execute.
 02   11/09/2007 MM     Aggiunta replace_clob.
 03   31/10/2007 FT     Aggiunto nvl_clob.
 04   19/06/2009 MM     Resa pubblica riempi_text_table ed inserimento di set_row_len, c_add, c_replace, c_substr, c_instr, encode_utf8.
 05   14/07/2011 FT     Allineati i commenti col nuovo standard di plsqldoc.
******************************************************************************/
   -- Package revision value
   s_revisione   CONSTANT afc.t_revision := 'V1.05';
   /******************************************************************************
    Restituisce versione e revisione di distribuzione del package.
    %return varchar2: contiene versione e revisione.
    %note <UL>
          <LI> Primo numero: versione compatibilita del Package.</LI>
          <LI> Secondo numero: revisione del Package specification.</LI>
          <LI> Terzo numero: revisione del Package body.</LI>
          </UL>
   ******************************************************************************/
   FUNCTION versione
      RETURN VARCHAR2;
   /******************************************************************************
    Trasforma stringa in CLOB.
    %param p_testo varchar2
    %param p_empty_clob boolean: Se FALSE ritorna NULL, se TRUE ritorna CALL empty_clob
    %return clob
   ******************************************************************************/
   FUNCTION TO_CLOB (
      p_testo        IN   VARCHAR2,
      p_empty_clob   IN   BOOLEAN DEFAULT FALSE
   )
      RETURN CLOB;
   /******************************************************************************
    Trasforma blob in CLOB - overloading per valori blob.
    %param p_testo blob
    %param p_empty_clob boolean: Se FALSE ritorna NULL, se TRUE ritorna CALL empty_clob
    %return clob
   ******************************************************************************/
   FUNCTION TO_CLOB (p_testo IN BLOB, p_empty_clob IN BOOLEAN DEFAULT FALSE)
      RETURN CLOB;
   /******************************************************************************
    Trasforma stringa in BLOB.
    %param p_testo varchar2
    %param p_empty_blob boolean: Se FALSE ritorna NULL, se TRUE ritorna CALL empty_blob
    %return varchar2
   ******************************************************************************/
   FUNCTION to_blob (
      p_testo        IN   VARCHAR2,
      p_empty_blob   IN   BOOLEAN DEFAULT FALSE
   )
      RETURN BLOB;
   /******************************************************************************
    Trasforma clob in BLOB - overloading per type clob
    %param p_testo clob
    %param p_empty_blob boolean: Se FALSE ritorna NULL, se TRUE ritorna CALL empty_blob
    %return blob
   ******************************************************************************/
   FUNCTION to_blob (p_testo IN CLOB, p_empty_blob IN BOOLEAN DEFAULT FALSE)
      RETURN BLOB;
   /******************************************************************************
    Istruzione "decode" per PL/SQL.
    %param p_check_value    valore da controllare
    %param p_against_value  valore di confronto
    %param p_then_result    risultato per uguale
    %param p_else_result    risultato per diverso
    %return varchar2
   ******************************************************************************/
   FUNCTION decode_value (
      p_check_value     IN   CLOB,
      p_against_value   IN   CLOB,
      p_then_result     IN   CLOB,
      p_else_result     IN   CLOB
   )
      RETURN CLOB;
   /******************************************************************************
    Esegue il clob dato.
    %param p_testo IN clob sorgente da eseguire.
   ******************************************************************************/
   PROCEDURE sql_execute (p_testo IN CLOB);
   /******************************************************************************
    Esegue la sostituzione di tutte le occorrenze di p_replaceStr con p_replaceWith nel clob dato.
    %param p_srcClob      IN CLOB      clob da esaminare
    %param p_replaceStr   IN VARCHAR2  stringa da sostituire
    %param p_replaceWith  IN VARCHAR2  stringa con cui sostituire
   ******************************************************************************/
   FUNCTION replace_clob (
      p_srcclob       IN   CLOB,
      p_replacestr    IN   VARCHAR2,
      p_replacewith   IN   VARCHAR2
   )
      RETURN CLOB;
   /******************************************************************************
    Esegue la funzione nvl di oracle su valore di tipo CLOB
    %param p_check_value  IN CLOB      clob da esaminare
    %param p_then_result  IN CLOB      clob da restituire nel caso in cui p_check_value sia EMPTY
   ******************************************************************************/
   FUNCTION nvl_clob (p_check_value IN CLOB, p_then_result IN CLOB)
      RETURN CLOB;
   /******************************************************************************
    Riempie la table p_text_table con il sorgente passato.
    %param p_text_table IN OUT  dbms_sql.varchar2s tabella da riempire.
    %param p_text       IN      clob               testo con cui riempirla.
    %note Eventuale ';' o '/' finale viene eliminato. Per riempire p_text_table vengono isolate le singole righe di sorgente (fino al carattere chr(10)); se la riga cosi' ottenuta ha lunghezza maggiore di 255 caratteri, viene spezzata in piu' righe di lunghezza massima 255.
   ******************************************************************************/
   PROCEDURE riempi_text_table (
      p_text_table   IN OUT   DBMS_SQL.varchar2s,
      p_testo        IN       CLOB
   );
   FUNCTION C_ADD (in_clob IN CLOB, in_text IN VARCHAR2)
      RETURN CLOB;
   FUNCTION C_REPLACE (
      in_clob      IN   CLOB,
      in_search    IN   VARCHAR2,
      in_replace   IN   VARCHAR2
   )
      RETURN CLOB;
   PROCEDURE set_row_len (p_len INTEGER);
   FUNCTION C_SUBSTR (
      in_clob     IN   CLOB,
      in_start    IN   NUMBER,
      in_amount   IN   NUMBER DEFAULT NULL
   )
      RETURN CLOB;
   FUNCTION C_INSTR (
      in_clob      IN   CLOB,
      in_pattern   IN   VARCHAR2,
      in_start     IN   NUMBER DEFAULT 1,
      in_nth       IN   NUMBER DEFAULT 1,
      in_reverse   IN   NUMBER DEFAULT 0
   )
      RETURN NUMBER;
   FUNCTION encode_utf8 (in_text IN CLOB)
      RETURN CLOB;
END afc_lob;
/

CREATE OR REPLACE PACKAGE BODY afc_lob
IS
/******************************************************************************
 Funzioni per la gestione degli oggetti di tipo LOB.
 REVISIONI:.
 Rev. Data       Autore Descrizione
 ---- ---------- ------ ------------------------------------------------------
 000 30/08/2006  FT     Prima emissione.
 001 29/08/2007  FT     Aggiunte 2 versioni di to_blob (per varchar2 e clob), decode_value, versione di to_clob per blob e sql_execute (con metodi ausiliari).
 002 11/09/2007  MM     Aggiunta replace_clob.
 003 31/10/2007  FT     Aggiunto nvl_clob.
 004 23/03/2009  MM     Modificata sql_execute.
 005 19/06/2009  MM     Modifica a riempi_text_table ed inserimento di set_row_len, add, replace, substr, instr, encode_utf8.
 006 19/10/2009  MM     Modificata riempi_text_table. Sostituite le funzioni add, substr, instr e replace con c_add, c_substr, c_instr e c_replace; sostituzione concatenzazione tra clob (||) con c_add.
 007 30/10/2009  SNeg   Tolti REM in cima al file; Aggiunti chr(10) quando da pl/sql table genera clob.
 008 14/07/2011  FT     Allineati i commenti col nuovo standard di plsqldoc.
******************************************************************************/
   -- Package body revision value
   s_revisione_body   CONSTANT afc.t_revision := '008';
   s_row_len                   INTEGER        := 255;
   /******************************************************************************
    Restituisce versione e revisione di distribuzione del package.
   ******************************************************************************/
   FUNCTION versione
      RETURN VARCHAR2
   IS
   BEGIN
      RETURN afc.VERSION (s_revisione, NVL (s_revisione_body, '000'));
   END versione;
--------------------------------------------------------------------------------
   /******************************************************************************
    Trasforma stringa in CLOB.
    REVISIONI:.
    Rev.  Data        Autore  Descrizione
    ----  ----------  ------  ------------------------------------------------------
    013   19/05/2006  --      Aggiunta metodo to_clob.
    014   25/06/2006  MF      Parametro in to_clob per ottenere empty in caso di null.
   ******************************************************************************/
   FUNCTION TO_CLOB (p_testo IN VARCHAR2, p_empty_clob IN BOOLEAN
            DEFAULT FALSE)
      RETURN CLOB
   IS
      d_result   CLOB;
      d_amount   BINARY_INTEGER;
   BEGIN
      d_amount := LENGTH (p_testo);
      IF d_amount != 0
      THEN
         DBMS_LOB.createtemporary (d_result, TRUE);
         DBMS_LOB.WRITE (d_result, d_amount, 1, p_testo);
      ELSE
         IF p_empty_clob
         THEN
            d_result := EMPTY_CLOB;
            DBMS_LOB.createtemporary (d_result, TRUE, DBMS_LOB.CALL);
         ELSE
            NULL;                       -- ritorna d_result che contiene NULL
         END IF;
      END IF;
      RETURN d_result;
   END TO_CLOB;
--------------------------------------------------------------------------------
   /******************************************************************************
    Trasforma blob in CLOB - overloading per valori blob.
    REVISIONI:.
    Rev.  Data        Autore  Descrizione
    ----  ----------  ------  ------------------------------------------------------
    001   29/08/2007  --      Prima versione
   ******************************************************************************/
   FUNCTION TO_CLOB (p_testo IN BLOB, p_empty_clob IN BOOLEAN DEFAULT FALSE)
      RETURN CLOB
   IS
      d_result        CLOB             := EMPTY_CLOB ();
      d_length        NUMBER;
      BLOCK           NUMBER           := 10000;
      blockcount      NUMBER;
      rawbuff         RAW (32000);
      pos             NUMBER;
      charbuff        VARCHAR2 (32000);
      charbuff_size   NUMBER;
   BEGIN
      DBMS_LOB.createtemporary (d_result, TRUE, DBMS_LOB.CALL);
      -- recast the BLOB to a CLOB
      d_length := DBMS_LOB.getlength (p_testo);
      IF d_length != 0
      THEN
         IF BLOCK < d_length
         THEN
            blockcount := ROUND ((d_length / BLOCK) + 0.5);
         ELSE
            blockcount := 1;
         END IF;
         pos := 1;
         FOR i IN 1 .. blockcount
         LOOP
            DBMS_LOB.READ (p_testo, BLOCK, pos, rawbuff);
            charbuff := UTL_RAW.cast_to_varchar2 (rawbuff);
            charbuff_size := LENGTH (charbuff);
            DBMS_LOB.writeappend (d_result, charbuff_size, charbuff);
            pos := pos + BLOCK;
         END LOOP;
      ELSE
         d_result := TO_CLOB ('', p_empty_clob);
      END IF;
      RETURN d_result;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RETURN d_result;
   END TO_CLOB;
--------------------------------------------------------------------------------
   /******************************************************************************
    Trasforma stringa in BLOB.
    REVISIONI:.
    Rev.  Data        Autore  Descrizione
    ----  ----------  ------  ------------------------------------------------------
    001   29/08/2007  --      Prima versione.
   ******************************************************************************/
   FUNCTION to_blob (p_testo IN VARCHAR2, p_empty_blob IN BOOLEAN
            DEFAULT FALSE)
      RETURN BLOB
   IS
      d_result   BLOB;
      d_amount   BINARY_INTEGER;
   BEGIN
      d_amount := LENGTH (p_testo);
      IF d_amount != 0
      THEN
         DBMS_LOB.createtemporary (d_result, TRUE);
         DBMS_LOB.WRITE (d_result, d_amount, 1,
                         UTL_RAW.cast_to_raw (p_testo));
      ELSE
         IF p_empty_blob
         THEN
            d_result := EMPTY_BLOB;
            DBMS_LOB.createtemporary (d_result, TRUE, DBMS_LOB.CALL);
         ELSE
            NULL;                       -- ritorna d_result che contiene NULL
         END IF;
      END IF;
      RETURN d_result;
   END to_blob;
--------------------------------------------------------------------------------
   /******************************************************************************
    Trasforma clob in BLOB - overloading per type clob.
    REVISIONI:.
    Rev.  Data        Autore  Descrizione
    ----  ----------  ------  ------------------------------------------------------
    001   29/08/2007  --      Prima versione.
   ******************************************************************************/
   FUNCTION to_blob (p_testo IN CLOB, p_empty_blob IN BOOLEAN DEFAULT FALSE)
      RETURN BLOB
   IS
      d_result   BLOB             := NULL;
      d_char     VARCHAR2 (32767);
      d_length   BINARY_INTEGER;
      d_dep      INTEGER          := 0;
      d_amount   BINARY_INTEGER   := 32767;
   BEGIN
      DBMS_LOB.createtemporary (d_result, TRUE, DBMS_LOB.SESSION);
      d_length := DBMS_LOB.getlength (p_testo);
      IF d_length != 0
      THEN
         LOOP
            DBMS_LOB.READ (p_testo, d_amount, 1 + (d_amount * d_dep), d_char);
            d_dep := d_dep + 1;
            d_length := d_length - d_amount;
            DBMS_LOB.writeappend (d_result,
                                  d_amount,
                                  UTL_RAW.cast_to_raw (d_char)
                                 );
            EXIT WHEN d_length < 0;
         END LOOP;
      ELSE
         d_result := to_blob ('', p_empty_blob);
      END IF;
      RETURN d_result;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RETURN d_result;
   END to_blob;
--------------------------------------------------------------------------------
   /******************************************************************************
    Istruzione "decode" per PL/SQL.
    REVISIONI:.
    Rev.  Data        Autore  Descrizione
    ----  ----------  ------  ------------------------------------------------------
    001   29/08/2007  FT      Prima versione.
   ******************************************************************************/
   FUNCTION decode_value (
      p_check_value     IN   CLOB,
      p_against_value   IN   CLOB,
      p_then_result     IN   CLOB,
      p_else_result     IN   CLOB
   )
      RETURN CLOB
   IS
      d_result   CLOB;
   BEGIN
      IF    DBMS_LOB.compare (p_check_value, p_against_value) = 0
         OR (p_check_value IS NULL AND p_against_value IS NULL)
      THEN
         d_result := p_then_result;
      ELSE
         d_result := p_else_result;
      END IF;
      RETURN d_result;
   END decode_value;
--------------------------------------------------------------------------------
   /******************************************************************************
    Spezza il testo in input in stringhe di lunghezza massima 255 e riempie la tabella p_text_table partendo dall'ultima riga presente + 1.
    %note Se la sottostringa di 255 caratteri non termina con uno spazio, cerca lo spazio precedente e spezza in corrispondenza di esso.
    REVISIONI:.
    Rev. Data       Autore Descrizione
    ---- ---------- ------ ------------------------------------------------------
    001  28/08/2007 MM     Prima emissione.
   ******************************************************************************/
   PROCEDURE spezza_riga (
      p_text_table   IN OUT   DBMS_SQL.varchar2s,
      p_text         IN       CLOB
   )
   IS
      d_stringa      VARCHAR2 (256);
      d_amount       INTEGER        := s_row_len;
      d_string_len   NUMBER         := 0;
      d_text_len     NUMBER         := 0;
      d_index        NUMBER         := NVL (p_text_table.LAST, 0);
   BEGIN
      d_text_len := DBMS_LOB.getlength (p_text);
      WHILE d_text_len > d_string_len
      LOOP
         d_stringa := DBMS_LOB.SUBSTR (p_text, d_amount, 1 + d_string_len);
         IF SUBSTR (TRIM (d_stringa), 1, 2) = '--'
         THEN
            EXIT;
         END IF;
         IF     SUBSTR (d_stringa, 1, LENGTH (d_stringa) - 1) <> ' '
            AND d_text_len > d_string_len + LENGTH (d_stringa)
         THEN
            IF INSTR (d_stringa, ' ', -1) > 0
            THEN
               d_stringa := SUBSTR (d_stringa, 1, INSTR (d_stringa, ' ', -1));
            END IF;
         END IF;
         d_string_len := d_string_len + LENGTH (d_stringa);
         d_index := d_index + 1;
         d_stringa := REPLACE (d_stringa, CHR (13), ' ');
         p_text_table (d_index) := d_stringa;
      END LOOP;
   END spezza_riga;
--------------------------------------------------------------------------------
   /******************************************************************************
    Riempie la table p_text_table con il sorgente passato.
    %note Eventuale ';' o '/' finale viene eliminato. Per riempire p_text_table vengono isolate le singole righe di sorgente (fino al carattere chr(10)); se la riga cosi' ottenuta ha lunghezza maggiore di 255 caratteri, viene spezzata in piu' righe di lunghezza massima 255.
    REVISIONI:.
    Rev. Data       Autore Descrizione
    ---- ---------- ------ ------------------------------------------------------
    001  28/08/2007 MM     Prima emissione.
   ******************************************************************************/
   PROCEDURE riempi_text_table (
      p_text_table   IN OUT   DBMS_SQL.varchar2s,
      p_testo        IN       CLOB
   )
   IS
      d_text         CLOB;
      d_stringa      VARCHAR2 (32000);
      d_max_len      INTEGER          := 32000;
      d_row_len      INTEGER          := s_row_len;
      d_index        NUMBER           := 0;
      d_clob_len     NUMBER           := 0;
      d_len          NUMBER           := 0;
      d_posnl        NUMBER           := 0;
      d_posnl_prec   NUMBER           := 0;
      d_clob_dep     CLOB;
   BEGIN
      d_text := p_testo;
      d_clob_len := NVL (DBMS_LOB.getlength (d_text), 0);
      IF d_clob_len > 0
      THEN
         d_posnl := DBMS_LOB.INSTR (d_text, CHR (10), d_posnl_prec + 1);
         IF d_posnl > 0
         THEN
            WHILE d_posnl - d_posnl_prec <> 0
            LOOP
               IF d_posnl = 0
               THEN
                  d_len := d_max_len;
               ELSE
                  d_len := d_posnl - d_posnl_prec - 1;
               END IF;
               IF d_len > d_max_len
               THEN
                  d_clob_dep :=
                          afc_lob.c_SUBSTR (d_text, d_posnl_prec + 1, d_len);
                  spezza_riga (p_text_table, d_clob_dep);
                  d_index := p_text_table.LAST;
               else
                  d_stringa := DBMS_LOB.SUBSTR (d_text, d_len, d_posnl_prec + 1);
                  IF LENGTH (d_stringa) > d_row_len
                  THEN
                     DBMS_LOB.createtemporary (d_clob_dep, TRUE);
                     DBMS_LOB.WRITE (d_clob_dep,
                                     LENGTH (d_stringa),
                                     1,
                                     d_stringa
                                    );
                     spezza_riga (p_text_table, d_clob_dep);
                     d_index := p_text_table.LAST;
                  ELSE
                     IF d_stringa IS NOT NULL
                     THEN
                        d_stringa := REPLACE (d_stringa, CHR (13), ' ');
                        d_index := d_index + 1;
                        -- per evitare rem che altrimenti rendono invalido il comando sql
                        if d_stringa not like 'REM %'  and d_stringa != 'REM' then
                        p_text_table (d_index) := d_stringa;
                        end if;
                     END IF;
                  END IF;
               end if;
               d_posnl_prec := d_posnl;
               IF d_posnl > 0
               THEN
                  d_posnl :=
                          DBMS_LOB.INSTR (d_text, CHR (10), d_posnl_prec + 1);
               END IF;
            END LOOP;
         ELSE
            spezza_riga (p_text_table, d_text);
         END IF;
      END IF;
   END riempi_text_table;
--------------------------------------------------------------------------------
   /******************************************************************************
    Esegue il sorgente PL/Sql memorizzato in p_text_table.
    REVISIONI:.
    Rev. Data       Autore Descrizione
    ---- ---------- ------ ------------------------------------------------------
    001  28/08/2007 MM     Prima emissione.
    004  23/03/2009 MM     Modificato il controllo per determinare quando togliere ; o / finale.
   ******************************************************************************/
   PROCEDURE sql_execute (p_text_table IN DBMS_SQL.varchar2s)
   IS
      d_cursor              INTEGER;
      d_ret_val             INTEGER;
      d_last                VARCHAR2 (255);
      d_text_table          DBMS_SQL.varchar2s := p_text_table;
      d_pac_or_prc_or_fun   BOOLEAN            := FALSE;
      d_pos_end             INTEGER;
   BEGIN
      IF NVL (d_text_table.LAST, 0) > 0
      THEN
         d_last := LTRIM (d_text_table (d_text_table.LAST));
         IF    SUBSTR (d_last, LENGTH (d_last)) = ';'
            OR SUBSTR (d_last, LENGTH (d_last)) = '/'
         THEN
            d_pos_end :=
                      INSTR (LOWER (d_text_table (d_text_table.LAST)), 'end');
            IF d_pos_end > 0
            THEN
               IF     (   SUBSTR (d_text_table (d_text_table.LAST),
                                  d_pos_end - 1,
                                  1
                                 ) = ' '
                       OR d_pos_end = 1
                      )
                  AND (SUBSTR (d_text_table (d_text_table.LAST),
                               d_pos_end + 3,
                               1
                              ) IN (' ', ';')
                      )
               THEN
                  d_pac_or_prc_or_fun := TRUE;
               END IF;
            END IF;
            IF NOT d_pac_or_prc_or_fun
            THEN
               d_text_table (d_text_table.LAST) :=
                                       SUBSTR (d_last, 1, LENGTH (d_last) - 1);
            END IF;
         END IF;
      END IF;
      IF NVL (d_text_table.FIRST, 0) > 0
      THEN
         d_cursor := DBMS_SQL.open_cursor;
         DBMS_SQL.parse (d_cursor,
                         d_text_table,
                         d_text_table.FIRST,
                         d_text_table.LAST,
                         TRUE,
                         DBMS_SQL.native
                        );
         d_ret_val := DBMS_SQL.EXECUTE (d_cursor);
         DBMS_SQL.close_cursor (d_cursor);
      END IF;
   END sql_execute;
--------------------------------------------------------------------------------
   /******************************************************************************
    Esegue il clob dato.
    REVISIONI:.
    Rev. Data       Autore Descrizione
    ---- ---------- ------ ------------------------------------------------------
    001  28/08/2007 MM     Prima emissione.
   ******************************************************************************/
   PROCEDURE sql_execute (p_testo IN CLOB)
   IS
      d_text_table   DBMS_SQL.varchar2s;
   BEGIN
      riempi_text_table (d_text_table, p_testo);
      sql_execute (d_text_table);
   END sql_execute;
--------------------------------------------------------------------------------
   /******************************************************************************
    Esegue la sostituzione di tutte le occorrenze di p_replaceStr con p_replaceWith nel clob dato.
    REVISIONI:.
    Rev. Data       Autore Descrizione
    ---- ---------- ------ ------------------------------------------------------
    002  11/09/2007 MM     Prima emissione.
    007  30/10/2009 SNeg   Aggiunti chr(10) quando da pl/sql table genera clob.
   ******************************************************************************/
   FUNCTION replace_clob (
      p_srcclob       IN   CLOB,
      p_replacestr    IN   VARCHAR2,
      p_replacewith   IN   VARCHAR2
   )
      RETURN CLOB
   IS
      d_newclob      CLOB               := EMPTY_CLOB;
      d_text_table   DBMS_SQL.varchar2s;
   BEGIN
      DBMS_LOB.createtemporary (d_newclob, TRUE);
      riempi_text_table (d_text_table, p_srcclob);
      FOR i IN NVL (d_text_table.FIRST, 0) .. NVL (d_text_table.LAST, 0)
      LOOP
         d_text_table (i) :=
                      REPLACE (d_text_table (i), p_replacestr, p_replacewith);
         DBMS_LOB.writeappend (d_newclob,
                               LENGTH (d_text_table (i)) +1,
                               d_text_table (i) || chr(10)
                              );
      END LOOP;
      RETURN d_newclob;
   EXCEPTION
      WHEN OTHERS
      THEN
         RAISE;
   END replace_clob;
--------------------------------------------------------------------------------
   /******************************************************************************
    Esegue la funzione nvl di oracle su valore di tipo CLOB.
    REVISIONI:.
    Rev. Data       Autore Descrizione
    ---- ---------- ------ ------------------------------------------------------
    002  31/10/2007 FT     Prima emissione.
   ******************************************************************************/
   FUNCTION nvl_clob (p_check_value IN CLOB, p_then_result IN CLOB)
      RETURN CLOB
   IS
   BEGIN
      IF DBMS_LOB.getlength (lob_loc => p_check_value) > 0
      THEN
         RETURN p_check_value;
      ELSE
         RETURN p_then_result;
      END IF;
   END nvl_clob;
--------------------------------------------------------------------------------
   /******************************************************************************
    c_ADD
   ******************************************************************************/
   FUNCTION c_ADD (in_clob IN CLOB, in_text IN VARCHAR2)
      RETURN CLOB
   IS
      out_clob   CLOB             := EMPTY_CLOB ();
      len        BINARY_INTEGER   := 32000;
      text       VARCHAR2 (32000);
   BEGIN
      DBMS_LOB.createtemporary (out_clob, TRUE, DBMS_LOB.SESSION);
      IF NVL (DBMS_LOB.getlength (in_clob), 0) > 0
      THEN
         out_clob := in_clob;
      END IF;
      IF in_text IS NOT NULL
      THEN
         len := LENGTH (in_text);
         DBMS_LOB.writeappend (out_clob, len, in_text);
      END IF;
      RETURN out_clob;
   END;
   /******************************************************************************
    C_REPLACE
   ******************************************************************************/
   FUNCTION C_REPLACE (
      in_clob      IN   CLOB,
      in_search    IN   VARCHAR2,
      in_replace   IN   VARCHAR2
   )
      RETURN CLOB
   IS
      tmp_clob      CLOB             := in_clob;
      out_clob      CLOB;
      chardata      VARCHAR2 (32000);
      chunck_size   NUMBER           := 30000;
      chunck        NUMBER;
   BEGIN
      IF in_clob IS NULL
      THEN
         RETURN out_clob;
      END IF;
      IF DBMS_LOB.getlength (in_clob) = 0
      THEN
         RETURN out_clob;
      END IF;
      DBMS_LOB.createtemporary (out_clob, TRUE, DBMS_LOB.SESSION);
      FOR i IN 0 .. TRUNC (DBMS_LOB.getlength (tmp_clob) / chunck_size)
      LOOP
         chunck := chunck_size;
         EXIT WHEN (chunck * i) = DBMS_LOB.getlength (tmp_clob);
         DBMS_LOB.READ (tmp_clob, chunck, (chunck * i) + 1, chardata);
         out_clob :=
            c_ADD (out_clob,
                 REPLACE (chardata, in_search, in_replace));
      END LOOP;
      -- giro sfasato
      chunck_size := 11000;
      tmp_clob := out_clob;
      out_clob := TO_CLOB ('');
      FOR i IN 0 .. TRUNC (DBMS_LOB.getlength (tmp_clob) / chunck_size)
      LOOP
         chunck := chunck_size;
         EXIT WHEN (chunck * i) = DBMS_LOB.getlength (tmp_clob);
         DBMS_LOB.READ (tmp_clob, chunck, (chunck * i) + 1, chardata);
         out_clob :=
            c_ADD (out_clob,
                 REPLACE (chardata, in_search, in_replace));
      END LOOP;
      RETURN out_clob;
   END;
   /******************************************************************************
    set_row_len
   ******************************************************************************/
   PROCEDURE set_row_len (p_len INTEGER)
   IS
   BEGIN
      s_row_len := NVL (p_len, 255);
   END;
   /******************************************************************************
    C_SUBSTR
   ******************************************************************************/
   FUNCTION C_SUBSTR (
      in_clob     IN   CLOB,
      in_start    IN   NUMBER,
      in_amount   IN   NUMBER DEFAULT NULL
   )
      RETURN CLOB
   IS
      tmp_amount   NUMBER;
      tmp_chunk    NUMBER := 4000;
      out_clob     CLOB;
   BEGIN
      IF in_amount = 0
      THEN
         RETURN out_clob;
      END IF;
      IF in_start > DBMS_LOB.getlength (in_clob)
      THEN
         RETURN out_clob;
      END IF;
      DBMS_LOB.createtemporary (out_clob, TRUE, DBMS_LOB.SESSION);
      tmp_amount :=
                  NVL (in_amount,
                       (DBMS_LOB.getlength (in_clob) - in_start) + 1);
      tmp_chunk := LEAST (tmp_chunk, tmp_amount);
      FOR i IN 0 .. TRUNC (tmp_amount / tmp_chunk) - 1
      LOOP
         out_clob := c_add(out_clob, DBMS_LOB.SUBSTR (in_clob, tmp_chunk,in_start + (i * tmp_chunk)));
      END LOOP;
      IF MOD (tmp_amount, tmp_chunk) > 0
      THEN
         out_clob := c_add(out_clob, DBMS_LOB.SUBSTR (in_clob,
                                MOD (tmp_amount, tmp_chunk),
                                  in_start
                                + (  (TRUNC (tmp_amount / tmp_chunk))
                                   * tmp_chunk
                                  )
                               ));
      END IF;
      RETURN out_clob;
   END;
   /******************************************************************************
    C_INSTR
   ******************************************************************************/
   FUNCTION C_INSTR (
      in_clob      IN   CLOB,
      in_pattern   IN   VARCHAR2,
      in_start     IN   NUMBER DEFAULT 1,
      in_nth       IN   NUMBER DEFAULT 1,
      in_reverse   IN   NUMBER DEFAULT 0
   )
      RETURN NUMBER
   IS
      out_pos      NUMBER;
      tmp_start    NUMBER := in_start;
      tmp_start2   NUMBER := in_start;
   BEGIN
      IF in_start < 0
      THEN
         tmp_start := DBMS_LOB.getlength (in_clob) + in_start;
      END IF;
      IF in_reverse = 0
      THEN
         out_pos := DBMS_LOB.INSTR (in_clob, in_pattern, tmp_start, in_nth);
      ELSE
         tmp_start2 := tmp_start;
         LOOP
            tmp_start2 := tmp_start2 - 1;
            EXIT WHEN tmp_start = 0;
            out_pos :=
                     DBMS_LOB.INSTR (in_clob, in_pattern, tmp_start2, in_nth);
            EXIT WHEN out_pos BETWEEN 1 AND tmp_start;
         END LOOP;
      END IF;
      out_pos := NVL (out_pos, 0);
      RETURN out_pos;
   END;
   /******************************************************************************
    encode_utf8
   ******************************************************************************/
   FUNCTION encode_utf8 (in_text IN CLOB)
      RETURN CLOB
   IS
      out_text   CLOB := in_text;
   BEGIN
      -- lettere accentate
      out_text := afc_lob.c_replace (out_text, CHR (224), 'A''');             -- a
      out_text := afc_lob.c_replace (out_text, CHR (232), 'E''');             -- e
      out_text := afc_lob.c_replace (out_text, CHR (233), 'E''');             -- e
      out_text := afc_lob.c_replace (out_text, CHR (236), 'I''');             -- i
      out_text := afc_lob.c_replace (out_text, CHR (242), 'O''');             -- o
      out_text := afc_lob.c_replace (out_text, CHR (249), 'U''');             -- u
      out_text := afc_lob.c_replace (out_text, CHR (38) || '#xE8;', 'e''');
      out_text := afc_lob.c_replace (out_text, CHR (38) || '#xE0;', 'a''');
      -- caratteri speciali
      out_text := afc_lob.c_replace (out_text, CHR (38) || 'apos;', '''');
      out_text := afc_lob.c_replace (out_text, CHR (38) || 'quot;', '"');
      out_text := afc_lob.c_replace (out_text, CHR (38) || 'gt;', '>');
      out_text := afc_lob.c_replace (out_text, CHR (38) || 'lt;', '<');
--  text := replace(text,chr(38)||'amp;'  ,chr(38));
  -- eliminati perche sconosciuti
      out_text := afc_lob.c_replace (out_text, chr(176), '?');
      RETURN out_text;
   END;
END afc_lob;
/

