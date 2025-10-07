--liquibase formatted sql 
--changeset abrandolini:20250326_152429_keypackage stripComments:false runOnChange:true 
 
CREATE OR REPLACE PACKAGE KeyPackage IS
/******************************************************************************
 NOME:        KeyPackage.
 DESCRIZIONE: Procedure e Funzioni di gestione Key Constraint and Error.
 ANNOTAZIONI: Gestione delle tabelle KEY_... .
 REVISIONI:
 Rev. Data       Autore Descrizione
 ---- ---------- ------ ------------------------------------------------------
 00   27/10/2003 MM     Creazione.
 01   27/09/2005 MF     Gestione Precisazione di KEY_CONSTRAINT_ERROR.
 02   12/01/2006 MF     Get_error: Aggiunto parametro esclusione Codice da messaggio.
 03   08/09/2006 FT     Compatibilità subtype varchar2 a Oracle 7.
******************************************************************************/
   s_revisione AFC.t_revision := 'V1.03';
   d_error_text varchar2(2000);
   subtype t_error_text is d_error_text%type;
   function VERSIONE return VARCHAR2;
   pragma restrict_references(versione, WNDS, WNPS);
   function GET_ERROR
   ( p_errore       varchar2
   , p_exclude_code number default 0
   ) return varchar2;
   pragma restrict_references( GET_ERROR, WNDS);
   function GET_ERRORCODE
   ( p_error    VARCHAR2
   , p_ErrorKey varchar2
   ) return varchar2;
   pragma restrict_references( GET_ERRORCODE, WNDS);
   function GET_ERROR_PRECISAZIONE
   ( p_error    VARCHAR2
   , p_ErrorKey varchar2
   ) return varchar2;
   pragma restrict_references( GET_ERROR_PRECISAZIONE, WNDS);
   function GET_NTEXT
   ( p_tabella IN varchar2
   , p_colonna IN varchar2
   , p_pk      IN varchar2
   , p_lingua  IN varchar2
   ) return varchar2;
   pragma restrict_references( GET_NTEXT, WNDS);
   function GET_NTEXT
   ( p_tabella IN VARCHAR2
   , p_colonna IN VARCHAR2
   , p_pk      IN varchar2
   ) return varchar2;
   pragma restrict_references( GET_NTEXT, WNDS);
   function GET_NTEXT
   ( p_pk      IN varchar2
   , p_lingua  IN varchar2
   ) return varchar2;
   pragma restrict_references( GET_NTEXT, WNDS);
   function  GET_NTEXT
   ( p_pk      IN varchar2
   ) return varchar2;
   pragma restrict_references( GET_NTEXT, WNDS);
   procedure SET_NTEXT
   ( p_tabella IN varchar2
   , p_colonna IN varchar2
   , p_pk      IN varchar2
   , p_lingua  IN varchar2
   , p_testo   IN varchar2
   );
   procedure SET_NTEXT
   ( p_tabella IN varchar2
   , p_colonna IN varchar2
   , p_pk      IN varchar2
   , p_testo   IN varchar2
   );
   procedure SET_NTEXT
   ( p_pk      IN varchar2
   , p_lingua  IN varchar2
   , p_testo   IN varchar2
   );
   procedure SET_NTEXT
   ( p_pk      IN varchar2
   , p_testo   IN varchar2
   );
END KeyPackage;
/

CREATE OR REPLACE PACKAGE BODY KeyPackage IS
/******************************************************************************
 NOME:        KeyPackage.
 DESCRIZIONE: Procedure e Funzioni di gestione Key Constraint and Error.
 ANNOTAZIONI: Gestione delle tabelle KEY_... .
 REVISIONI:
 Rev. Data       Autore Descrizione
 ---- ---------- ------ ------------------------------------------------------
 000  28/10/2003 MM     Prima emissione.
 001  27/09/2005 MF     Gestione Precisazione di KEY_CONSTRAINT_ERROR.
                        Function SET_NTEXT:
                        - Uso della AFC.SQL_Execute al posto della SI4.SQL_Execute.
                        - Uso della propria GET_ERROR al posto della SI4.GET_ERROR.
 002  12/01/2006 MF     Get_error: Aggiunto parametro esclusione Codice da messaggio.
******************************************************************************/
s_revisione_body        AFC.t_revision := '002';
s_errore                t_error_text;
s_precisazione          key_constraint_error.precisazione%type;
function VERSIONE return varchar2 is
/******************************************************************************
 NOME:        VERSIONE
 DESCRIZIONE: Restituisce versione e revisione di distribuzione del package.
 RITORNA:     stringa VARCHAR2 contenente versione e revisione.
 NOTE:        Primo numero  : versione compatibilita del Package.
              Secondo numero: revisione del Package specification.
              Terzo numero  : revisione del Package body.
******************************************************************************/
begin
   return AFC.version( s_revisione, s_revisione_body );
end VERSIONE;
FUNCTION GET_ERROR
/******************************************************************************
 NOME:        GET_ERROR
 DESCRIZIONE: Ricerca descrizione errore su Table KEY_ERROR.
 PARAMETRI:   p_errore VARCHAR2 Codifica errore
 RITORNA:     VARCHAR2 Codice di errore tra parentesi quadre seguito dalla
                       descrizione.
 ANNOTAZIONI: Se codifica non trovata ritorna la stringa in ingresso.
              Formato errore da ricercare su tabella:
                 X00000  dove X    : primo carattere alfanumerico
                              00000: seguito da 5 caratteri numerici
 REVISIONI:
 Rev. Data       Autore Descrizione
 ---- ---------- ------ ------------------------------------------------------
 000  27/10/2003 MM     Prima emissione.
 002  12/01/2006 MF     Aggiunto parametro esclusione Codice da messaggio.
******************************************************************************/
( p_errore       VARCHAR2
, p_exclude_code NUMBER  default 0
) RETURN VARCHAR2
IS
d_messaggio VARCHAR2(2000);
d_nls       number;
BEGIN
   BEGIN
      select count(1)
        into d_nls
        from KEY_NTEXT
       where tabella = 'KEY_ERROR'
      ;
   EXCEPTION
      WHEN OTHERS THEN
         d_nls := 0;
   END;
   if d_nls = 0 then
      -- Cerca il codice di errore corrispondente alla Chiave di Ricerca fornita
      BEGIN
         select descrizione
           into d_messaggio
           from key_error
          where errore = p_errore
         ;
         if p_exclude_code = 0 then
            d_messaggio := '['||p_errore ||'] '||d_messaggio;
         end if;
      EXCEPTION
         WHEN OTHERS THEN
            d_messaggio := '';
      END;
   else
      -- Cerca il codice di errore corrispondente alla Chiave di Ricerca fornita
      IF  translate(substr(p_errore,2,5),'123456789','000000000') = '00000'
      AND (length(p_errore) < 7 OR substr(p_errore,7,1) = ' ') THEN
         BEGIN
            d_messaggio := GET_NTEXT('KEY_ERROR','ERRORE', p_errore);
            if d_messaggio is not null then
               if p_exclude_code = 0 then
                  d_messaggio := '['||p_errore ||'] '||d_messaggio;
               end if;
            end if;
         EXCEPTION
            WHEN OTHERS THEN
             d_messaggio := '';
         END;
      ELSE
         BEGIN
            d_messaggio := GET_NTEXT(p_errore);
         EXCEPTION
            WHEN OTHERS THEN
               d_messaggio := '';
         END;
      END IF;
   end if;
   if d_messaggio is null then
      d_messaggio := p_errore;
   end if;
   RETURN d_messaggio;
END GET_ERROR;
procedure LKP_CONSTRAINT_ERROR
( p_error    VARCHAR2
, p_errorKey varchar2
) is
/******************************************************************************
 NOME:        LKP_CONSTRAINT_ERROR
 DESCRIZIONE: Estrae eventuale codice applicativo di Table KEY_ERROR
              abbinato al codice errore di ritorno dal DataBase Server,
              depositando errore e precisazione su variabili di package body.
              Le codifiche abbinate sono registrate sulle table:
              KEY_CONSTRAINT_TYPE
              KEY_CONSTRAINT_ERROR
 PARAMETRI:   p_error     Codice dell'errore DataBase.
              p_errorKey  Nome del Constraint.
 ANNOTAZIONI: Se l'errore di DataBase non è abbinato ad un errore gestito
              nelle table di Messaggi di Errore della Appricazione, ritorna
              stringa vuota.
              Solo nel caso in cui l'errore sia un messaggio di
              RAISE_APPLICATION_ERROR proveniente da Trigger o Procedure
              ORACLE ( ORA-20... ), viene rimandato in uscita con
              formattazione corretta.
 REVISIONI:
 Rev. Data       Autore Descrizione
 ---- ---------- ------ ------------------------------------------------------
 001  27/09/2005 MF     Gestione Precisazione di KEY_CONSTRAINT_ERROR
******************************************************************************/
BEGIN
   -- Cerca il codice di errore corrispondente nella KEY_CONSTRAINT_ERROR
   -- passando per KEY_CONTRAINT_TYPE
   BEGIN
      select errore
           , precisazione
        into s_errore
           , s_precisazione
        from key_constraint_type  KCTY
           , key_constraint_error KCER
       where KCTY.db_error     = p_error
         and KCER.nome         = p_ErrorKey
         and KCER.tipo_errore in (KCTY.tipo_errore,decode(KCTY.tipo_errore,'PK','UK',''))
      ;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         s_errore := '';
         s_precisazione := '';
   END;
   -- In caso di assenza Gestione KEY_CONSTRAINT_ERROR l'errore di DB
   -- può essere decodificato sulla KEY_CONSTRAINT_ERROR con segnalazioni
   -- di Default per ogni errore intercettato dalla KEY_CONSTRAINT_TYPE.
   if s_errore is null then
      BEGIN
      select errore
           , precisazione
        into s_errore
           , s_precisazione
           from key_constraint_error KCER
              , key_constraint_type  KCTY
          where KCTY.db_error        = p_error
            and KCER.nome (+)        = KCTY.tipo_errore
            and KCER.tipo_errore (+) = KCTY.tipo_errore
         ;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            s_errore := '';
            s_precisazione := '';
      END;
      if  s_errore is not null
      and p_errorKey is not null then -- In caso di errore non specifico del Constraint
                                      -- emette il nome del Constraint tra parentesi tonde
            s_errore := s_errore || ' (' || p_ErrorKey || ')';
      end if;
   end if;
END LKP_CONSTRAINT_ERROR;
function GET_ERRORCODE
( p_error    varchar2
, p_ErrorKey varchar2
) return varchar2 is
/******************************************************************************
 NOME:        GET_ERRORCODE
 DESCRIZIONE: Ottiene la colonna ERRORE della Table KEY_CONSTRAINT_ERROR.
 PARAMETRI:   p_error   Codice dell'errore DataBase.
              p_message   Messaggio in chiaro dell'errore di DataBase.
 RITORNA:     VARCHAR2 Codice Applicativo abbinato all'errore di DataBase.
 ANNOTAZIONI: Vedi procedure LKP_CONSTRAINT_ERROR.
 REVISIONI:
 Rev. Data       Autore Descrizione
 ---- ---------- ------ ------------------------------------------------------
 000  27/10/2003 MM     Prima emissione.
 001  27/09/2005 MF     Introduzione uso procedure LKP_CONSTRAINT_ERROR.
******************************************************************************/
begin
   -- cerca l'errore e lo deposita su s_errore
   LKP_CONSTRAINT_ERROR( p_error, p_ErrorKey );
   return s_errore;
END GET_ERRORCODE;
function GET_ERROR_PRECISAZIONE
( p_error    VARCHAR2
, p_ErrorKey varchar2
) return varchar2 is
/******************************************************************************
 NOME:        GET_ERROR_PRECISAZIONE
 DESCRIZIONE: Ottiene la colonna PRECISAZIONE della Table KEY_CONSTRAINT_ERROR .
 PARAMETRI:   p_error   Codice dell'errore DataBase.
              p_message   Messaggio in chiaro dell'errore di DataBase.
 RITORNA:     VARCHAR2 Precisazione abbinata all'errore di DataBase.
 ANNOTAZIONI: Vedi procedure LKP_CONSTRAINT_ERROR.
 REVISIONI:
 Rev. Data       Autore Descrizione
 ---- ---------- ------ ------------------------------------------------------
 001  27/09/2005 MF     Prima emissione.
******************************************************************************/
begin
   -- Cerca la precisazione dell'errore e la deposita su s_precisazione
   LKP_CONSTRAINT_ERROR( p_error, p_ErrorKey );
   return s_precisazione;
END GET_ERROR_PRECISAZIONE;
FUNCTION GET_NTEXT
/******************************************************************************
 NOME:        GET_NTEXT
 DESCRIZIONE: Ricerca il testo corrispondente al valore della colonna p_colonna
              della tabella p_tabella con chiave primaria p_pk per la lingua
              p_lingua.
 PARAMETRI:   p_tabella IN VARCHAR2 Nome della tabella su cui cercare il testo
              p_colonna IN VARCHAR2 Nome della colonna su cui cercare il testo
              p_pk      IN VARCHAR2 Chiave per cui cercare il testo
              p_lingua  IN VARCHAR2 Lingua per cui cercare il testo
 RITORNA:     VARCHAR2 testo nella lingua passata.
 ANNOTAZIONI: --
 REVISIONI:
 Rev. Data       Autore Descrizione
 ---- ---------- ------ ------------------------------------------------------
 000  28/10/2003 MM     Prima emissione.
******************************************************************************/
( p_tabella IN VARCHAR2
, p_colonna IN VARCHAR2
, p_pk      IN VARCHAR2
, p_lingua  IN VARCHAR2)
RETURN VARCHAR2
IS
   d_ErrMsg VARCHAR2(2000);
BEGIN
   IF p_lingua is null THEN
      BEGIN
         select testo
           into d_ErrMsg
           from KEY_NTEXT
          where tabella = nvl(p_tabella,'KEY_ERROR')
            and colonna = NVL(p_colonna,'DESCRIZIONE')
            and pk      = p_pk
         ;
      EXCEPTION
         WHEN OTHERS THEN
            BEGIN
               select traduzione
                 into d_ErrMsg
                 from KEY_NWORD
                where testo = p_pk
               ;
            EXCEPTION
               WHEN OTHERS THEN
                  d_ErrMsg := '';
            END;
      END;
   ELSE
      BEGIN
         select testo
           into d_ErrMsg
           from KEY_DICTIONARY
          where tabella = nvl(p_tabella,'KEY_ERROR')
            and colonna = NVL(p_colonna,'DESCRIZIONE')
            and pk      = p_pk
            and lingua  = p_lingua
         ;
      EXCEPTION
         WHEN OTHERS THEN
             BEGIN
                select traduzione
                  into d_ErrMsg
                  from KEY_WORD
                 where testo  = p_pk
                   and lingua = p_lingua
                ;
             EXCEPTION
                WHEN OTHERS THEN
                   d_ErrMsg := '';
            END;
      END;
   END IF;
   if d_ErrMsg is null and p_lingua is not null then
      BEGIN
         select testo
           into d_ErrMsg
           from KEY_DICTIONARY
          where tabella = nvl(p_tabella,'KEY_ERROR')
            and colonna = NVL(p_colonna,'DESCRIZIONE')
            and pk      = p_pk
            and lingua  = ( select lingua_al
                              from ad4_gruppi_linguistici
                             where lingua   = p_lingua
                               and sequenza = ( select nvl(min(sequenza),0)
                                                  from ad4_gruppi_linguistici
                                                 where lingua     = p_lingua
                                                   and lingua_al <> p_lingua
                                              )
                          )
         ;
      EXCEPTION
         WHEN OTHERS THEN
            d_ErrMsg := '';
      END;
   end if;
   RETURN d_ErrMsg;
EXCEPTION
   WHEN OTHERS THEN
      RETURN '';
END GET_NTEXT;
FUNCTION GET_NTEXT
/******************************************************************************
 NOME:        GET_NTEXT
 DESCRIZIONE: Ricerca il testo corrispondente al valore della colonna p_colonna
              della tabella p_tabella con chiave primaria p_pk per la lingua
              corrente.
 PARAMETRI:   p_tabella IN VARCHAR2 Nome della tabella su cui cercare il testo
              p_colonna IN VARCHAR2 Nome della colonna su cui cercare il testo
              p_pk      IN VARCHAR2 Chiave per cui cercare il testo
 RITORNA:     VARCHAR2 testo nella lingua corrente.
 ANNOTAZIONI: --
 REVISIONI:
 Rev. Data       Autore Descrizione
 ---- ---------- ------ ------------------------------------------------------
 000  28/10/2003 MM     Prima emissione.
******************************************************************************/
( p_tabella IN VARCHAR2
, p_colonna IN VARCHAR2
, p_pk      IN VARCHAR2)
RETURN VARCHAR2
IS
BEGIN
   RETURN GET_NTEXT(p_tabella,p_colonna,p_pk,'');
END GET_NTEXT;
FUNCTION GET_NTEXT
/******************************************************************************
 NOME:        GET_NTEXT
 DESCRIZIONE: Ricerca il testo corrispondente al valore della colonna
              DESCRIZIONE della tabella KEY_ERROR con chiave primaria p_pk per
              la lingua  passata.
 PARAMETRI:   p_pk      IN VARCHAR2 Chiave per cui cercare il testo
              p_lingua  IN VARCHAR2 Lingua per cui cercare il testo
 RITORNA:     VARCHAR2 testo nella lingua passata.
 ANNOTAZIONI: --
 REVISIONI:
 Rev. Data       Autore Descrizione
 ---- ---------- ------ ------------------------------------------------------
 000  28/10/2003 MM     Prima emissione.
******************************************************************************/
( p_pk     IN VARCHAR2
, p_lingua IN VARCHAR2)
RETURN VARCHAR2
IS
BEGIN
   RETURN GET_NTEXT('','',p_pk,p_lingua);
END GET_NTEXT;
FUNCTION GET_NTEXT
/******************************************************************************
 NOME:        GET_NTEXT
 DESCRIZIONE: Ricerca il testo corrispondente al valore della colonna
              DESCRIZIONE della tabella KEY_ERROR con chiave primaria p_pk per
              la lingua corrente.
 PARAMETRI:   p_pk      IN VARCHAR2 Chiave per cui cercare il testo
 RITORNA:     VARCHAR2 testo nella lingua corrente.
 ANNOTAZIONI: --
 REVISIONI:
 Rev. Data       Autore Descrizione
 ---- ---------- ------ ------------------------------------------------------
 000  28/10/2003 MM     Prima emissione.
******************************************************************************/
( p_pk      IN VARCHAR2)
RETURN VARCHAR2
IS
BEGIN
   RETURN GET_NTEXT(p_pk,'');
END GET_NTEXT;
PROCEDURE SET_NTEXT
/******************************************************************************
 NOME:        SET_NTEXT
 DESCRIZIONE: Modifica con p_testo il testo corrispondente al valore della
              colonna p_colonna della tabella p_tabella con chiave primaria p_pk
              per la lingua p_lingua.
 ARGOMENTI:   p_tabella IN VARCHAR2 Nome della tabella in cui modificare il testo
              p_colonna IN VARCHAR2 Nome della colonna in cui modificare il testo
              p_pk      IN VARCHAR2 Chiave per cui modificare il testo
              p_lingua  IN VARCHAR2 Lingua in cui modificare il testo
              p_testo   IN VARCHAR2 Testo con cui modificare
 ECCEZIONI:   -
 ANNOTAZIONI:
 REVISIONI:
 Rev. Data       Autore Descrizione
 ---- ---------- ------ ------------------------------------------------------
 000  28/10/2003 MM     Prima emissione.
 001  27/09/2005 MF     - Uso della AFC.SQL_Execute al posto della SI4.SQL_Execute.
                        - Uso della propria GET_ERROR al posto della SI4.GET_ERROR.
******************************************************************************/
( p_tabella IN VARCHAR2
, p_colonna IN VARCHAR2
, p_pk      IN VARCHAR2
, p_lingua  IN VARCHAR2
, p_testo   IN VARCHAR2)
IS
d_table        VARCHAR2(2000);
d_where_lingua VARCHAR2(2000);
d_col_lingua   VARCHAR2(100);
d_execute      VARCHAR2(2000);
BEGIN
   IF p_lingua is null THEN
      d_table := 'KEY_NTEXT';
      d_where_lingua := '';
      d_col_lingua   := '';
   ELSE
      d_table := 'KEY_DICTIONARY';
      d_where_lingua := ' and lingua ='''||p_lingua||'''';
      d_col_lingua   := 'lingua, ';
   END IF;
    BEGIN
       select tname
         into d_table
         from tab
        where tname = ''''||d_table||''''
       ;
    EXCEPTION
       WHEN NO_DATA_FOUND THEN
          RAISE_APPLICATION_ERROR(-20999, GET_ERROR(''''||d_table||''' inesistente.'));
       WHEN OTHERS THEN
          raise;
   END;
   BEGIN
      d_execute := 'insert into '||d_table||'(tabella, colonna, pk, '||d_col_lingua||'testo)'||
                    ' select '''||nvl(p_tabella,'KEY_ERROR')||''', '''
                                ||NVL(p_colonna,'DESCRIZIONE')||''', '''
                                ||p_pk||''', ';
      if p_lingua is not null then
         d_execute := d_execute ||''''||p_lingua ||'''';
      end if;
      d_execute := d_execute ||''''|| p_testo ||''''||
                  '  from dual '||
                  ' where not exists (select 1 '||
                                     '  from '||d_table||
                                     ' where tabella = '''||nvl(p_tabella,'KEY_ERROR')||''''||
                                       ' and colonna = '''||NVL(p_colonna,'DESCRIZIONE')||''''||
                                       ' and pk      = '''||p_pk||''''||d_where_lingua||')';
      AFC.SQL_Execute(d_execute);
   EXCEPTION
      WHEN OTHERS THEN
        raise;
   END;
   BEGIN
      d_execute := 'update '||d_table||
                   '   set testo = '''|| p_testo ||''''||
                   ' where tabella = '''||nvl(p_tabella,'KEY_ERROR')||''''||
                     ' and colonna = '''||NVL(p_colonna,'DESCRIZIONE')||''''||
                     ' and pk      = '''||p_pk||''''||d_where_lingua;
      AFC.SQL_Execute(d_execute);
   EXCEPTION
      WHEN OTHERS THEN
         raise;
   END;
EXCEPTION
   WHEN OTHERS THEN
      raise;
END SET_NTEXT;
PROCEDURE SET_NTEXT
/******************************************************************************
 NOME:        SET_NTEXT
 DESCRIZIONE: Modifica con p_testo il testo corrispondente al valore della
              colonna p_colonna della tabella p_tabella con chiave primaria p_pk
              per la lingua corrente.
 ARGOMENTI:   p_tabella IN VARCHAR2 Nome della tabella in cui modificare il testo
              p_colonna IN VARCHAR2 Nome della colonna in cui modificare il testo
              p_pk      IN VARCHAR2 Chiave per cui modificare il testo
              p_testo   IN VARCHAR2 Testo con cui modificare
 ECCEZIONI:   -
 ANNOTAZIONI:
 REVISIONI:
 Rev. Data       Autore Descrizione
 ---- ---------- ------ ------------------------------------------------------
 000  28/10/2003 MM     Prima emissione.
******************************************************************************/
( p_tabella IN VARCHAR2
, p_colonna IN VARCHAR2
, p_pk      IN VARCHAR2
, p_testo   IN VARCHAR2)
IS
BEGIN
   SET_NTEXT(p_tabella, p_colonna, p_pk,'', p_testo);
EXCEPTION
   WHEN OTHERS THEN
      raise;
END SET_NTEXT;
PROCEDURE SET_NTEXT
/******************************************************************************
 NOME:        SET_NTEXT
 DESCRIZIONE: Modifica con p_testo il testo corrispondente al valore della
              colonna p_colonna della tabella p_tabella con chiave primaria p_pk
              per la lingua p_lingua.
 ARGOMENTI:   p_pk      IN VARCHAR2 Chiave per cui modificare il testo
              p_lingua  IN VARCHAR2 Lingua in cui modificare il testo
              p_testo   IN VARCHAR2 Testo con cui modificare
 ECCEZIONI:   -
 ANNOTAZIONI:
 REVISIONI:
 Rev. Data       Autore Descrizione
 ---- ---------- ------ ------------------------------------------------------
 000  28/10/2003 MM     Prima emissione.
******************************************************************************/
( p_pk     IN VARCHAR2
, p_lingua IN VARCHAR2
, p_testo   IN VARCHAR2)
IS
BEGIN
   SET_NTEXT('', '', p_pk, p_lingua, p_testo);
EXCEPTION
   WHEN OTHERS THEN
      raise;
END SET_NTEXT;
PROCEDURE SET_NTEXT
/******************************************************************************
 NOME:        SET_NTEXT
 DESCRIZIONE: Modifica con p_testo il testo corrispondente al valore della
              colonna p_colonna della tabella p_tabella con chiave primaria p_pk
              per la lingua corrente.
 ARGOMENTI:   p_pk      IN VARCHAR2 Chiave per cui modificare il testo
              p_testo   IN VARCHAR2 Testo con cui modificare
 ECCEZIONI:   -
 ANNOTAZIONI:
 REVISIONI:
 Rev. Data       Autore Descrizione
 ---- ---------- ------ ------------------------------------------------------
 000  28/10/2003 MM     Prima emissione.
******************************************************************************/
( p_pk      IN VARCHAR2
, p_testo   IN VARCHAR2)
IS
BEGIN
   SET_NTEXT(p_pk, '', p_testo);
EXCEPTION
   WHEN OTHERS THEN
      raise;
END SET_NTEXT;
END KeyPackage;
/

