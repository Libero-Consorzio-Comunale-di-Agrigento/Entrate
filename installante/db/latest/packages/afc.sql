--liquibase formatted sql 
--changeset abrandolini:20250326_152429_afc stripComments:false runOnChange:true 
 
CREATE OR REPLACE PACKAGE AFC IS
/******************************************************************************
 NOME:        AFC
 DESCRIZIONE: Procedure e Funzioni di utilita' comune.
 ANNOTAZIONI: -
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 00    20/01/2003  MM      Prima emissione.
 01    18/03/2005  MF      Adozione nello Standard AFC (nessuna modifica).
 02    26/04/2005  CZ      Aggiunte to_boolean e xor
 03    14/06/2005  MM      Creazione GET_SUBSTR ( p_stringa    IN  varchar2
                                                , p_separatore IN  varchar2
                                                , p_occorrenza IN  varchar2
                                                )
 04    01/09/2005  FT      Aggiunta dei metodi protect_wildcard, version
                           aggiunta dei subtype t_object_name, t_message,
                           t_statement, t_revision
 05    27/09/2005  MF      Cambio nomenclatura s_revisione e s_revisione_body.
                           Tolta dipendenza get_stringParm da Package Si4.
 06    24/11/2005  FT      Aggiunta di mxor
 07    04/01/2006  MM      Aggiunta is_number
 08    12/01/2006  MM      Aggiunta is_numeric e to_number(p_value in varchar2)
 09    01/02/2006  FT      Aumento di parametri per mxor
 10    22/02/2006  FT      Aggiunta dei metodi get_field_condition e decode_value
                           e del type t_ref_cursor
 11    02/03/2006  FT      Aggiunta della function SQL_execute
 12    21/03/2006  MF      Get_filed_condition: Introdotto prefix e suffix.
 13    19/05/2006  FT      Aggiunta metodo to_clob
 14    25/06/2006  MF      Parametro in to_clob per ottenere empty in caso di null.
 15    28/06/2006  FT      Aggiunta funzione date_format e parametro p_date_format
                           in get_field_condition
 16    30/08/2006  FT      Modifica dichiarazione subtype per incompatibilità con
                           versione 7 di Oracle; eliminazione della funzione to_clob
 17    19/10/2006  FT      Aggiunta funzione quote
 18    30/10/2006  FT      Aggiunta funzione countOccurrenceOf
 19    21/12/2006  FT      Aggiunta funzione init_cronologia
 20    27/02/2007  FT      Spostata funzione init_cronologia nel package SI4
 21    14/03/2007  FT      Aggiunta overloading di get_field_condition per
                           p_field_value di tipo DATE
 22    06/04/2009  MF      Aggiunte funzioni di "default_null".
 23    25/09/2009  FT      Eliminate doppie definizioni di "default_null".
 24    14/10/2009  FT      Aggiunto metodo string_extract
******************************************************************************/
   d_revision  VARCHAR2(30);
   SUBTYPE t_revision IS d_revision%TYPE;
   d_object_name  VARCHAR2(30);
   SUBTYPE t_object_name IS d_object_name%TYPE;
   d_message  VARCHAR2(1000);
   subtype t_message is d_message%TYPE;
   d_statement  VARCHAR2(32000);
   subtype t_statement is d_statement%TYPE;
   type t_ref_cursor is REF CURSOR;
   s_revisione t_revision := 'V1.24';
   function versione return t_revision;
   pragma restrict_references(versione, WNDS, WNPS);
   function version
   ( p_revisione t_revision
   , p_revisione_body t_revision
   ) return t_revision;
   pragma restrict_references(version, WNDS, WNPS );
   -- Ottiene la stringa precedente alla stringa di separazione, modificando
   -- la stringa di partenza con la parte seguente, escludendo la stringa di
   -- separazione
   function get_substr
   ( p_stringa    IN OUT varchar2
   , p_separatore IN     varchar2
   ) return VARCHAR2;
   pragma restrict_references(get_substr, WNDS);
   function get_substr
   ( p_stringa    IN  varchar2
   , p_separatore IN  varchar2
   , p_occorrenza IN  varchar2
   ) return VARCHAR2;
   pragma restrict_references(get_substr, WNDS);
   -- Estrapola un Parametro da una Stringa
   function get_stringParm
   ( p_stringa        IN VARCHAR2
   , p_identificativo IN VARCHAR2
   ) return VARCHAR2;
   pragma restrict_references(get_stringParm, WNDS);
   function string_extract
   ( p_stringa in varchar2
   , p_left in varchar2
   , p_right in varchar2
   , p_include in boolean default true
   ) return afc.t_statement;
   function countOccurrenceOf
   ( p_stringa in varchar2
   , p_sottostringa in varchar2)
   return number;
   -- Protezione dei caratteri speciali ('_' e '%') nella stringa p_stringa
   function protect_wildcard
   ( p_stringa        IN VARCHAR2
   ) return VARCHAR2;
   pragma restrict_references(protect_wildcard, WNDS);
   -- Gestione apici (aggiunta di quelli esterni e raddoppio di quelli interni)
   -- per la stringa p_stringa
   function quote
   ( p_stringa   in varchar2
   ) return varchar2;
   -- Cast number [0,1] => boolean [false, true]
   -- null arguments are NOT handled
   function to_boolean
   ( p_value in number
   ) return boolean;
   pragma restrict_references( to_boolean, WNDS );
   -- Cast boolean [false, true] => number [0,1]
   -- null arguments are NOT handled
   function to_number
   ( p_value in boolean
   ) return number;
   pragma restrict_references( to_number, WNDS );
   function to_number
   ( p_value in varchar2
   )
   return number;
   pragma restrict_references( to_number, WNDS );
   -- Esecuzione istruzione dinamica
   procedure SQL_execute
   ( p_stringa t_statement
   );
   -- Esecuzione istruzione dinamica con valore di ritorno
   function SQL_execute
   ( p_stringa t_statement
   ) return varchar2;
   -- Exclusive xor
   -- null arguments are NOT handled
   function xor
   ( p_value_1 in boolean
   , p_value_2 in boolean
   ) return boolean;
   pragma restrict_references( xor, WNDS );
   function xor
   ( p_value_1 in boolean
   , p_value_2 in boolean
   , p_value_3 in boolean
   ) return boolean;
   pragma restrict_references( xor, WNDS );
   function xor
   ( p_value_1 in boolean
   , p_value_2 in boolean
   , p_value_3 in boolean
   , p_value_4 in boolean
   ) return boolean;
   pragma restrict_references( xor, WNDS );
   -- Multiple xor
   function mxor
   ( p_value_1 in boolean
   , p_value_2 in boolean
   , p_value_3 in boolean default false
   , p_value_4 in boolean default false
   , p_value_5 in boolean default false
   , p_value_6 in boolean default false
   , p_value_7 in boolean default false
   , p_value_8 in boolean default false
   ) return boolean;
   pragma restrict_references( mxor, WNDS );
   -- Verifica che la stringa passata sia un numero
   function is_number
   ( p_char in varchar2) return number;
   pragma restrict_references( is_number, WNDS );
   -- Verifica che la stringa passata sia formata da soli numeri
   function is_numeric
   ( p_char in varchar2) return number;
   pragma restrict_references( is_numeric, WNDS );
   -- Ottiene stringa con condizione SQL
   function get_field_condition
   ( p_prefix      in varchar2
   , p_field_value in varchar2
   , p_suffix      in varchar2
   , p_flag        in number   default 0
   , p_date_format in varchar2 default null
   ) return varchar2;
   -- Ottiene stringa con condizione SQL
   -- overloading per p_field_condition di tipo DATE
   function get_field_condition
   ( p_prefix      in varchar2
   , p_field_value in date
   , p_suffix      in varchar2
   , p_flag        in number   default 0
   , p_date_format in varchar2 default null
   ) return varchar2;
   -- Istruzione "decode" per PL/SQL
   function decode_value
   ( p_check_value in varchar2
   , p_against_value in varchar2
   , p_then_result in varchar2
   , p_else_result in varchar2
   ) return varchar2;
   function date_format
   return varchar2;
   -- Memorizza nome item per gestione "default_null".
   procedure default_null
   (
    p_item_name  in varchar2 default null
   );
   -- Ritorna valore NULL per inizializzazione default value e
   -- memorizza nome item per gestione "default_null".
   function default_null
   (
    p_item_name  in varchar2 default null
   ) return varchar2;
   -- Ritorna 1 se nome item è stato valorizzato gestione "default_null".
   function is_default_null
   (
    p_item_name  in varchar2
   ) return number;
END AFC;
/

CREATE OR REPLACE PACKAGE BODY AFC IS
/******************************************************************************
 NOME:        AFC
 DESCRIZIONE: Procedure e Funzioni di utilita' comune.
 ANNOTAZIONI: -
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 000   20/01/2003  MM      Prima emissione.
 001   26/04/2005  CZ      Aggiunte to_boolean e xor
 002   14/06/2005  MM      Introduzione funczione GET_SUBSTR
                           (p_stringa IN varchar2, p_separatore IN  varchar2
                           , p_occorrenza IN  varchar2).
 003   01/09/2005  FT      Aggiunta dei metodi protect_wildcard, version
                           aggiunta dei subtype t_object_name, t_message,
                           t_statement, t_revision
 004   27/09/2005  MF      Cambio nomenclatura s_revisione e s_revisione_body.
                           Tolta dipendenza get_stringParm da Package Si4.
                           Inserimento SQL_execute per istruzioni dinamiche.
 005   24/11/2005  FT      Aggiunta di mxor
 006   04/01/2006  MM      Aggiunta is_number
 007   12/01/2006  MM      Aggiunte is_numeric e to_number(p_value in varchar2),
                           corretta is_number, corretta get_substr in modo che
                           gestisca stringhe fino a 32000 caratteri.
 008   01/02/2006  FT      Aumento di parametri per mxor
 009   22/02/2006  FT      Aggiunta dei metodi get_field_condition e decode_value
 010   02/03/2006  FT      Aggiunta function SQL_execute
 011   21/03/2006  MF      get_filed_condition:
                           - Introdotto prefix e suffix
                           - return type t_statement
                           decode_value:
                           - return type t_statement
 012   26/04/2006  MM      Modifica get_stringParm.
 013   19/05/2006  FT      Aggiunta metodo to_clob
 014   25/06/2006  MF      Parametro in to_clob per ottenere empty in caso di null.
 015   28/06/2006  FT      Aggiunta function date_format; in get_field_condition,
                           modificata gestione di p_field_value (gestione di operatori
                           di default e scorporo dell'operatore da p_field_value)
                           e aggiunto parametro p_date_format
 016   30/08/2006  FT      Eliminazione della funzione to_clob
 017   04/09/2006  FT      Corretto get_field_condition: aggiunta di apici a p_field_value
                           in caso di 'like' implicito; controllo con 'lower' per caso di like
 018   05/09/2006  FT      Modificata gestione 'like' implicito e raddoppio apici singoli
                           in get_field_condition
 019   19/10/2006  FT      Aggiunta funzione quote
 020   30/10/2006  FT      Aggiunta funzione countOccurrenceOf
 021   21/12/2006  FT      Aggiunta funzione init_cronologia
 022   03/01/2007  FT      Modificata logica di gestione del flag in get_field_condition
                           per permettere di passare NULL e comportarsi come fosse il valore
                           di default
 023   27/02/2007  FT      Spostata funzione init_cronologia nel package SI4
 024   14/03/2007  FT      Aggiunta overloading di get_field_condition per p_field_value di tipo DATE
 025   09/01/2008  FT      get_field_condition: aggiunta possibilita di passare l'operatore
                           anche con p_flag = 0; modificata gestione DATE
 026   18/03/2008  FT      get_field_condition: aggiunta possibilita di cercare per like
                           su campi di tipo date
 027   08/10/2008  FT      get_field_condition: aggiunta degli operatori IN, BETWEEN,
                           EXISTS e NOT
 028   06/04/2009  MF      Aggiunte funzioni di "default_null".
 029   18/05/2008  MF      Variabile d_item_name di tipo t_statement in default_null e
                           is_default_null.
 030   15/09/2009  FT      Datatype del valore di ritorno della function version
                           portato a varchar2(30)
 031   14/10/2009  FT      Aggiunto metodo string_extract; corretto get_field_condition:
                           sbagliava nel caso in cui l'operatore passato è BETWEEN
******************************************************************************/
s_revisione_body t_revision := '031';
s_default_null              t_statement;
s_default_null_object_name  t_object_name;
--------------------------------------------------------------------------------
function versione return t_revision is
/******************************************************************************
 NOME:        VERSIONE
 DESCRIZIONE: Restituisce versione e revisione di distribuzione del package.
 RITORNA:     stringa VARCHAR2 contenente versione e revisione.
 NOTE:        Primo numero  : versione compatibilita del Package.
              Secondo numero: revisione del Package specification.
              Terzo numero  : revisione del Package body.
******************************************************************************/
begin
   return version( s_revisione, s_revisione_body );
end versione;
--------------------------------------------------------------------------------
function version
( p_revisione t_revision
, p_revisione_body t_revision
) return t_revision is
/******************************************************************************
 NOME:        VERSION
 DESCRIZIONE: Restituisce versione e revisione di distribuzione del package.
 PARAMETRI:   p_revisione      revisione del Package specification.
              p_revision_body  revisione del Package body.
 RITORNA:     stringa VARCHAR2 contenente versione e revisione.
 NOTE:        Primo numero  : versione compatibilita del Package.
              Secondo numero: revisione del Package specification.
              Terzo numero  : revisione del Package body.
******************************************************************************/
   d_result varchar2(30);
begin
   d_result := p_revisione||'.'||p_revisione_body;
   return d_result;
end version;
--------------------------------------------------------------------------------
function get_substr
( p_stringa    IN OUT varchar2
, p_separatore IN     varchar2
) return VARCHAR2 is
/******************************************************************************
 NOME:        GET_SUBSTR
 DESCRIZIONE: Ottiene la stringa precedente alla stringa di separazione, modificando
              la stringa di partenza con la parte seguente, escludendo la stringa di
              separazione.
 PARAMETRI:   p_stringa      Stringa da esaminare.
              p_separatore   Stringa di separazione.
 RITORNA:     varchar2: se trovata stringa di separazione : la sottostringa;
                        se non trovata                    : la stringa originale.
              Esempio:
                 da  stringa     ABCD.
                 con sub-stringa B.
                     ritorna A.
                     modificando l'originale in CD.
 ANNOTAZIONI: -
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ------------------------------------------------------
 000   7/01/2003   MM      Prima emissione.
******************************************************************************/
   sStringa     VARCHAR2(32000);
   iPos         INTEGER;
begin
   iPos := instr(p_stringa,p_separatore);
   if iPos = 0 then
      sStringa  := p_stringa;
      p_stringa := '';
   else
      sStringa  := substr(p_stringa,1,iPos - 1);
      p_stringa := substr(p_stringa,iPos+length(p_separatore));
   end if;
   RETURN sStringa;
end get_substr;
--------------------------------------------------------------------------------
function get_substr
( p_stringa    IN  varchar2
, p_separatore IN  varchar2
, p_occorrenza IN  varchar2
) return VARCHAR2 is
/******************************************************************************
 NOME:        GET_SUBSTR
 DESCRIZIONE: Ottiene la stringa precedente alla stringa di separazione.
 PARAMETRI:   p_stringa      Stringa da esaminare.
              p_separatore   Stringa di separazione.
           p_occorrenza   P o U a seconda che si voglia considerare la Prima
                          o l'ultima occorrenza della stringa di separazione.
 RITORNA:     varchar2: se trovata stringa di separazione : la sottostringa;
                        se non trovata                    : la stringa originale.
 ANNOTAZIONI: -
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ------------------------------------------------------
 000   14/04/2005  MM      Prima emissione.
******************************************************************************/
   sStringa     VARCHAR2(32000);
   iPos         INTEGER;
   iOcc         INTEGER;
begin
   if p_occorrenza = 'P' then
      iOcc := 1;
   elsif p_occorrenza = 'U' then
      iOcc := -1;
   else
      iOcc := 1;
   end if;
   iPos := instr(p_stringa,p_separatore,iOcc,1);
   if iPos = 0 then
      sStringa  := p_stringa;
   else
      sStringa  := substr(p_stringa,1,iPos - 1);
   end if;
   RETURN sStringa;
end get_substr;
--------------------------------------------------------------------------------
function get_stringParm
( p_stringa        IN varchar2
, p_identificativo IN varchar2
) return VARCHAR2 is
/******************************************************************************
 NOME:        GET_STRINGPARM.
 DESCRIZIONE: Estrapola un Parametro da una Stringa.
              L'identificativo puo essere :
                     /x      seguito da " " (spazio) - Case sensitive.
                     -x      seguito da " " (spazio) - Case sensitive.
                     X      seguito da "=" (uguale) - Ignore Case.
              Se il Parametro inizia con "'" (apice) o '"' (doppio apice)
                         viene estratto fino al prossimo apice o doppio apice;
              altrimenti
                         viene estratto fino allo " " (spazio).
 PARAMETRI:   p_Stringa        varchar2 Valore contenente la stringa da esaminare.
              p_Identificativo varchar2 Stringa identificativa del Parametro da estrarre.
 RITORNA:     varchar2: Valore del parametro estrapolato dalla stringa.
 ANNOTAZIONI: -
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ------------------------------------------------------
 000   17/01/2003  MM      Prima emissione.
 004   27/09/2005  MF      Tolta dipendenza get_stringParm da Package Si4.
 012   26/04/2006  MM      (BO14061) Ritorna un risultato errato se il valore del
                           parametro richiesto e nullo.
******************************************************************************/
   d_stringa   varchar2(2000);
   d_parametro varchar2(2000);
   d_termine   varchar2(2000);
   d_pos       integer;
begin
   d_stringa := lTrim(rTrim(p_stringa));
   if substr(p_identificativo,1,1) in ('/','-') then
      d_parametro := p_identificativo;
      d_pos       := instr(d_stringa,d_parametro);
   else
      d_parametro := upper(p_identificativo)||'=';
      d_pos       := instr(Upper(d_stringa),d_parametro);
   end if;
   if d_pos = 0 then
      RETURN '';
   else
     d_pos := d_pos + length(d_parametro);
   end if;
   d_stringa := rTrim(substr(d_stringa, d_pos));
   -- Carattere finale determinato in funzione del carattere iniziale
   if substr(ltrim(d_stringa),1,1) = '''' or substr(ltrim(d_stringa),1,1) = '"' then
      d_stringa := ltrim(d_stringa);
      d_termine := substr(d_stringa,1,1);
      d_stringa := substr(d_stringa,2);
   else
      d_termine := ' ';
   end if;
   d_stringa := GET_SUBSTR(d_stringa,d_termine);
   RETURN d_stringa;
end get_stringParm;
--------------------------------------------------------------------------------
function string_extract
( p_stringa in varchar2
, p_left in varchar2
, p_right in varchar2
, p_include in boolean default true
) return afc.t_statement
/******************************************************************************
 NOME:        string_extract
 DESCRIZIONE: Preleva la parte di stringa compresa/esclusa dai delimitatori indicati
              come parametro; se p_include è TRUE ritorna la parte compresa, se
              FALSE ritorna la parte esclusa
 PARAMETRI:   p_stringa
              p_left
              p_right
              p_include
 RITORNA:     varchar2
 NOTE:        -
******************************************************************************/
is
   d_result afc.t_statement;
   d_length number;
   d_chr varchar2(1);
   d_preleva number(1);
   d_left varchar2(1);
   d_right varchar2(1);
   d_n_char integer;
begin
   if p_include
   then
      d_left := p_left;
      d_right := p_right;
      d_preleva := 0;
   else
      d_left := p_right;
      d_right := p_left;
      d_preleva := 1;
   end if;
   d_length := nvl( length( p_stringa ), 0 );
   for i in 1 .. d_length
   loop
      d_chr := substr( p_stringa, i, 1 );
      if d_chr = d_left
      then
         d_preleva := 1;
      elsif d_chr = d_right
      then
         d_preleva := 0;
      else
         if d_preleva = 1
         then
            d_result := d_result || d_chr;
         end if;
      end if;
   end loop;
   return d_result;
end string_extract;
--------------------------------------------------------------------------------
function countOccurrenceOf
( p_stringa in varchar2
, p_sottostringa in varchar2)
return number
/******************************************************************************
 NOME:        countOccurrenceOf
 DESCRIZIONE: numero di occorrenze di p_sottostringa in p_stringa
 PARAMETRI:   p_stringa
              p_sottostringa
 RITORNA:     varchar2
 NOTE:        -
******************************************************************************/
is
   d_result integer:= 0;
   d_pos integer := 0;
begin
   d_pos := instr( p_stringa, p_sottostringa );
   while d_pos > 0 loop
      d_result := d_result + 1;
      d_pos := instr( p_stringa, p_sottostringa, d_pos + 1 );
   end loop;
   return d_result;
end countOccurrenceOf;
--------------------------------------------------------------------------------
function protect_wildcard
( p_stringa        in varchar2
) return varchar2 is
/******************************************************************************
 NOME:        protect_wildcard
 VISIBILITA': pubblica
 DESCRIZIONE: protezione dei caratteri speciali ('_' e '%') nella stringa p_stringa
 PARAMETRI:   p_stringa
 RITORNA:     VARCHAR2
 NOTE:        -
******************************************************************************/
   d_result varchar2(2000);
begin
   d_result := replace( p_stringa, '_', '\_' );
   d_result := replace( d_result, '%', '\%' );
   return d_result;
end protect_wildcard;
--------------------------------------------------------------------------------
function quote
( p_stringa   in varchar2
) return varchar2 is
/******************************************************************************
 NOME:        quote
 VISIBILITA': pubblica
 DESCRIZIONE: Gestione apici (aggiunta di quelli esterni e raddoppio di quelli
              interni) per la stringa p_stringa
 PARAMETRI:   p_stringa
 RITORNA:     VARCHAR2
 NOTE:        -
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ------------------------------------------------------
 019   19/10/2006  FT      Aggiunta funzione quote
******************************************************************************/
   d_result varchar2(2000);
begin
   d_result := replace( p_stringa, '''', '''''' );
   d_result := '''' || d_result || '''';
   return d_result;
end quote;
--------------------------------------------------------------------------------
function to_boolean
( p_value in number
)
return boolean is
/******************************************************************************
 NOME:        to_boolean
 VISIBILITA': pubblica
 DESCRIZIONE: conversione booleana di valori number (1,0)
 PARAMETRI:   p_value: number: 1 o 0
 RITORNA:     boolean: true se 1, false se 0
 NOTE:        accetta solo argomenti validi (non nulli: NON implementa logica
              booleana estesa al null)
******************************************************************************/
   d_result boolean;
begin
   DbC.PRE( p_value is not null );
   DbC.PRE( p_value = 1  or  p_value = 0 );
   if p_value = 1 then
      d_result := true;
   else
      d_result := false;
   end if;
   DbC.POST( d_result is not null );
   return  d_result;
end; -- AFC.to_boolean
--------------------------------------------------------------------------------
function to_number
( p_value in boolean
)
return number
/******************************************************************************
 NOME:        to_number
 VISIBILITA': pubblica
 DESCRIZIONE: conversione number di valori booleani
 PARAMETRI:   p_value: boolean: true o false
 RITORNA:     boolean: 1 se true, 0 se false
 NOTE:        accetta solo argomenti validi (non nulli: NON implementa logica
              booleana estesa al null)
******************************************************************************/
is
   d_result number;
begin
   DbC.PRE( p_value is not null );
   if p_value then
      d_result := 1;
   else
      d_result := 0;
   end if;
   DbC.POST( d_result is not null );
   DbC.POST( d_result = 1  or  d_result = 0 );
   return  d_result;
end; -- AFC.to_number
--------------------------------------------------------------------------------
function to_number
( p_value in varchar2
)
return number
/******************************************************************************
 NOME:        to_number
 VISIBILITA': pubblica
 DESCRIZIONE: conversione number di stringhe
 PARAMETRI:   p_value: varchar2
 RITORNA:     number corrispondente o exception
 NOTE:        In caso la stringa passata non sia un numero esce con eccezione
              ORA -06502.
******************************************************************************/
is
   d_result number;
begin
   d_result := standard.to_number(p_value);
   return  d_result;
end to_number;
--------------------------------------------------------------------------------
procedure SQL_execute
( p_stringa t_statement
) is
/******************************************************************************
 NOME:        SQL_execute
 DESCRIZIONE: Esegue lo statement passato.
 ARGOMENTI:   p_stringa varchar2 statement sql da eseguire
 ECCEZIONI:
 ANNOTAZIONI: -
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ------------------------------------------------------
 004   27/09/2005  MF      Cambio nomenclatura s_revisione e s_revisione_body.
                           Tolta dipendenza get_stringParm da Package Si4.
                           Inserimento SQL_execute per istruzioni dinamiche.
******************************************************************************/
   d_cursor         INTEGER;
   d_rows_processed INTEGER;
BEGIN
   d_cursor := dbms_sql.open_cursor;
   dbms_sql.parse( d_cursor, p_stringa, dbms_sql.native );
   d_rows_processed := dbms_sql.execute( d_cursor );
   dbms_sql.close_cursor( d_cursor );
EXCEPTION
   WHEN OTHERS THEN
      dbms_sql.close_cursor( d_cursor );
      raise;
END SQL_EXECUTE;
--------------------------------------------------------------------------------
function SQL_execute
( p_stringa t_statement
) return varchar2 is
/******************************************************************************
 NOME:        SQL_execute
 DESCRIZIONE: Esegue lo statement passato e rotorna il valore di ritorno.
 ARGOMENTI:   p_stringa varchar2 statement sql da eseguire
 ECCEZIONI:
 ANNOTAZIONI: -
 RITORNA:     varchar2 il valore di ritorno dello statement SQL p_stringa
******************************************************************************/
   d_cursor         INTEGER;
   d_rows_processed INTEGER;
   d_result         varchar2(32000);
begin
   d_cursor := dbms_sql.open_cursor;
   dbms_sql.parse( d_cursor, p_stringa, dbms_sql.native );
   dbms_sql.define_column( d_cursor, 1, d_result, 32000 );
   d_rows_processed := dbms_sql.execute( d_cursor );
   if dbms_sql.fetch_rows( d_cursor ) > 0
   then
      dbms_sql.column_value( d_cursor, 1, d_result );
   end if;
   dbms_sql.close_cursor( d_cursor );
   return d_result;
exception
   when others then
      dbms_sql.close_cursor( d_cursor );
      raise;
end SQL_execute;
--------------------------------------------------------------------------------
function xor
( p_value_1 in boolean
, p_value_2 in boolean
) return boolean is
/******************************************************************************
 NOME:        xor
 VISIBILITA': pubblica
 DESCRIZIONE: operatore booleano di or esclusivo
 PARAMETRI:   p_value_1: boolean
              p_value_2: boolean
 RITORNA:     boolean
 NOTE:        accetta solo argomenti validi (non nulli: NON implementa logica
              booleana estesa al null)
******************************************************************************/
   d_result boolean;
begin
   DbC.PRE( p_value_1 is not null );
   DbC.PRE( p_value_2 is not null );
   d_result := p_value_1 != p_value_2;
   DbC.POST( d_result is not null );
   return  d_result;
end; -- AFC.xor
--------------------------------------------------------------------------------
function xor
( p_value_1 in boolean
, p_value_2 in boolean
, p_value_3 in boolean
) return boolean is
/******************************************************************************
 NOME:        xor
 VISIBILITA': pubblica
 DESCRIZIONE: operatore booleano di or esclusivo
 PARAMETRI:   p_value_1: boolean
              p_value_2: boolean
 RITORNA:     boolean
 NOTE:        accetta solo argomenti validi (non nulli: NON implementa logica
              booleana estesa al null)
******************************************************************************/
   d_result boolean;
begin
   DbC.PRE( p_value_3 is not null );
   -- p_value_1 and p_value_2 checked into the binary base function
   d_result  := xor( p_value_1,  p_value_2 ) != p_value_3;
   DbC.POST( d_result is not null );
   return  d_result;
end; -- AFC.xor
--------------------------------------------------------------------------------
function xor
( p_value_1 in boolean
, p_value_2 in boolean
, p_value_3 in boolean
, p_value_4 in boolean
) return boolean is
/******************************************************************************
 NOME:        xor
 VISIBILITA': pubblica
 DESCRIZIONE: operatore booleano di or esclusivo
 PARAMETRI:   p_value_1: boolean
              p_value_2: boolean
              p_value_3: boolean
              p_value_4: boolean
 RITORNA:     boolean
 NOTE:        accetta solo argomenti validi (non nulli: NON implementa logica
              booleana estesa al null)
******************************************************************************/
   d_result boolean;
begin
   d_result  := xor( p_value_1,  p_value_2 ) != xor( p_value_3,  p_value_4 );
   DbC.POST( d_result is not null );
   return  d_result;
end; -- AFC.xor
--------------------------------------------------------------------------------
function mxor
( p_value_1 in boolean
, p_value_2 in boolean
, p_value_3 in boolean default false
, p_value_4 in boolean default false
, p_value_5 in boolean default false
, p_value_6 in boolean default false
, p_value_7 in boolean default false
, p_value_8 in boolean default false
) return boolean is
/******************************************************************************
 NOME:        mxor
 VISIBILITA': pubblica
 DESCRIZIONE: operatore booleano di or esclusivo: ritorna true se solo uno dei
              parametri e true e tutti gli altri sono false
 PARAMETRI:   p_value_1: boolean
              p_value_2: boolean
              p_value_3: boolean
              p_value_4: boolean
              p_value_5: boolean
              p_value_6: boolean
              p_value_7: boolean
              p_value_8: boolean
 RITORNA:     boolean
 NOTE:        funziona per 2, 3, 4, 5, 6, 7 e 8 operandi
******************************************************************************/
   d_result boolean;
begin
   d_result :=     p_value_1 and not p_value_2 and not p_value_3 and not p_value_4 and not p_value_5 and not p_value_6 and not p_value_7 and not p_value_8
            or not p_value_1 and     p_value_2 and not p_value_3 and not p_value_4 and not p_value_5 and not p_value_6 and not p_value_7 and not p_value_8
            or not p_value_1 and not p_value_2 and     p_value_3 and not p_value_4 and not p_value_5 and not p_value_6 and not p_value_7 and not p_value_8
            or not p_value_1 and not p_value_2 and not p_value_3 and     p_value_4 and not p_value_5 and not p_value_6 and not p_value_7 and not p_value_8
            or not p_value_1 and not p_value_2 and not p_value_3 and not p_value_4 and     p_value_5 and not p_value_6 and not p_value_7 and not p_value_8
            or not p_value_1 and not p_value_2 and not p_value_3 and not p_value_4 and not p_value_5 and     p_value_6 and not p_value_7 and not p_value_8
            or not p_value_1 and not p_value_2 and not p_value_3 and not p_value_4 and not p_value_5 and not p_value_6 and     p_value_7 and not p_value_8
            or not p_value_1 and not p_value_2 and not p_value_3 and not p_value_4 and not p_value_5 and not p_value_6 and not p_value_7 and     p_value_8
            ;
   DbC.POST( d_result is not null );
   return  d_result;
end; -- AFC.mxor
--------------------------------------------------------------------------------
function is_number
( p_char in varchar2
) return number is
/******************************************************************************
 NOME:        is_number
 VISIBILITA': pubblica
 DESCRIZIONE: Verifica che la stringa passata sia un numero.
 PARAMETRI:   p_char: varchar2 stringa da controllare.
 RITORNA:     number 1: e' un numero
                     0: NON e' un numero
 NOTE:        in caso che p_char sia nullo, la funzione ritorna 1.
******************************************************************************/
   d_result    number := 1;
   d_test      number;
begin
   d_test := to_number(p_char);
   RETURN d_result;
EXCEPTION
   WHEN OTHERS THEN
      if sqlcode = -6502 then
         RETURN 0;
      else
         raise;
      end if;
end is_number;
--------------------------------------------------------------------------------
function is_numeric
( p_char in varchar2
) return number is
/******************************************************************************
 NOME:        is_numeric
 VISIBILITA': pubblica
 DESCRIZIONE: Verifica che la stringa passata sia formata da soli numeri.
 PARAMETRI:   p_char: varchar2 stringa da controllare.
 RITORNA:     number 1: e' formata da soli numeri
                     0: NON e' formata da soli numeri
 NOTE:        in caso che p_char sia nullo, la funzione ritorna 0.
              La lunghezza massima della stringa passata e' 32000.
******************************************************************************/
   d_result    number := 0;
   d_translate varchar2(32000);
   d_compare   varchar2(32000);
   d_len       number := length(p_char);
   d_loop      number := 1;
begin
   if p_char is not null then
      d_translate := translate(p_char, '0123456789x', 'xxxxxxxxxxa');
      while d_loop <= d_len loop
         d_compare := d_compare||'x';
         d_loop := d_loop + 1;
      end loop;
      if d_compare = d_translate then
         d_result := 1;
      end if;
   end if;
   RETURN d_result;
end is_numeric;
--------------------------------------------------------------------------------
function get_field_condition
( p_prefix      in varchar2
, p_field_value in varchar2
, p_suffix      in varchar2
, p_flag        in number   default 0
, p_date_format in varchar2 default null
) return varchar2 is
/******************************************************************************
 NOME:        get_field_condition
 DESCRIZIONE: Ottiene stringa con condizione SQL.
 PARAMETRI:   p_prefix       stringa per prefissare la condizione
              p_field_value  valore da controllare
              p_suffix       stringa per suffissare la condizione
              p_flag         0 = se p_field_value inizia con un operatore viene usato quello,
                                 senno viene usato l'operatore =
                             1 = condizione indicata in valore
              p_date_format  se p_field_value e di tipo date, contiene il formato
                             da utilizzare per effettuare la conversione
 RITORNA:     varchar2 con stringa SQL
 NOTE:        Se p_field_value e NULL ritorna NULL.
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ------------------------------------------------------
 009   22/02/2006  FT      Aggiunta dei metodi get_field_condition e decode_value
 011   21/03/2006  MF      - Introdotto prefix e suffix
                           - return type t_statement
 015   28/06/2006  FT      modificata gestione di p_field_value: gestione di operatori
                           di default e scorporo dell'operatore dal valore;
                           aggiunto parametro p_date_format
 017   04/09/2006  FT      Aggiunta di apici a p_field_value in caso di 'like' implicito;
                           controllo con 'lower' per caso di like
 018   05/09/2006  FT      Modificata gestione 'like' implicito e raddoppio apici singoli
 022   03/01/2007  FT      Modificata logica di gestione di p_flag per permettere di
                           passare NULL e comportarsi come fosse il valore di default (0)
 025   09/01/2008  FT      Aggiunta possibilita di passare l'operatore
                           anche con p_flag = 0; modificata gestione DATE: se il valore
                           inizia per 'to_date(' non vengono applicate le regole di parsing
                           ma viene concatenato direttamente al risultato finale
 026   18/03/2008  FT      Aggiunta possibilita di cercare per like su campi di tipo date
 027   08/10/2008  FT      Aggiunta degli operatori IN, BETWEEN, EXISTS e NOT
 031   14/10/2009  FT      Correzione relativa al caso in cui l'operatore passato sia between
******************************************************************************/
   d_result t_statement;
   d_operator varchar2(7);
   d_char_operator number := 0;
   d_value t_statement;
   d_prefix t_statement;
   d_field_value AFC.t_statement;
   d_field_value_op AFC.t_statement;
begin
   d_field_value := ltrim( rtrim( p_field_value ) );
   d_field_value_op := lower( replace( p_field_value, ' ', '' ) );
   if d_field_value is not null
   then
      if p_flag = 0
      or p_flag is null
      then
         -- presenza del NOT iniziale
        if substr( d_field_value_op, 1, 3 ) = 'not'
         then
            d_prefix := substr( p_prefix, 1, instr( p_prefix, '(' ) - 1 )
                     || ' not '
                     || substr( p_prefix, instr( p_prefix, '(' ) )
                     ;
            d_field_value := ltrim( substr( d_field_value, 4 ) );
            d_field_value_op := ltrim( substr( d_field_value_op, 4 ) );
         else
            -- caso like generico
            d_prefix := p_prefix;
         end if;
         if substr( d_field_value_op, 1, 2 ) = '=='
         or substr( d_field_value_op, 1, 2 ) = '=>'
         or substr( d_field_value_op, 1, 2 ) = '>='
         or substr( d_field_value_op, 1, 2 ) = '<='
         or substr( d_field_value_op, 1, 2 ) = '=<'
         or substr( d_field_value_op, 1, 2 ) = '<>'
         or substr( d_field_value_op, 1, 2 ) = '!='
         or substr( d_field_value_op, 1, 2 ) = '!>'
         or substr( d_field_value_op, 1, 2 ) = '!<'
         then
            d_operator := substr( d_field_value_op, 1, 2 );
            d_char_operator := 2;
         elsif substr( d_field_value_op, 1, 1 ) = '>'
         or    substr( d_field_value_op, 1, 1 ) = '<'
         then
            d_operator := substr( d_field_value_op, 1, 1 );
            d_char_operator := 1;
         elsif substr( d_field_value_op, 1, 1 ) = '='
         then
            d_operator := '=';
            d_char_operator := 1;
         elsif substr( d_field_value_op, 1, 7 ) = 'between'
         then
            d_operator := substr( d_field_value_op, 1, 7 );
            d_char_operator := 7;
         elsif substr( d_field_value_op, 1, 7 ) = 'exists('
         then
            d_operator := substr( d_field_value_op, 1, 6 );
            d_char_operator := 6;
         elsif substr( d_field_value_op, 1, 3 ) = 'in('
         then
            d_operator := substr( d_field_value_op, 1, 2 );
            d_char_operator := 2;
         elsif(  (   instr( d_field_value_op, '_' ) != 0
                 and instr( lower( d_field_value_op ), 'to_date(' ) = 0
                 )
              or instr( d_field_value_op, '%' ) != 0
              )
         and not(   substr( d_field_value_op, 1, 1 ) = ''''
                and substr( d_field_value_op, -1 ) = ''''
                )
         then
            -- operatore 'like'
            if p_date_format is not null
            then
               -- caso like per date: trasformo in stringa il campo della tabella
               d_prefix := substr( p_prefix, 1, instr( p_prefix, '(' ) )
                        || ' to_char( '
                        || substr( p_prefix, instr( p_prefix, '(' ) + 1 )
                        || ', ''' || p_date_format || ''' ) '
                        ;
            else
               -- caso like generico
               d_prefix := p_prefix;
            end if;
            d_operator := 'like';
            d_field_value := '''' || replace( d_field_value, '''', '''''' ) || '''';
         else
            d_operator := '=';
         end if;
         if d_operator = '=='
         then
            d_operator := '=';
         elsif d_operator = '=>'
         then
            d_operator := '>=';
         elsif d_operator = '=<'
         then
            d_operator := '<=';
         end if;
         d_value := ltrim( rtrim( substr( d_field_value, d_char_operator + 1 ) ) );
         -- gestione apici
         if p_date_format is not null
         then
            if  substr( lower( d_value ), 1, 8 ) != 'to_date('
            then
               -- è stata passata una data convertita in stringa (es: '15/01/1981 00:00:00')
               d_value := 'to_date( ''' || d_value || ''', ''' || p_date_format || ''' ) ';
            end if;
         else
            if  substr( d_value, 1, 1 ) = ''''
            and substr( d_value, -1 ) = ''''
            or  lower( d_operator ) in ( 'in', 'between', 'exists' )
            then
               d_value := d_value;
            else
               d_value := '''' || replace( d_value, '''', '''''' ) || '''';
            end if;
         end if;
         d_value := d_operator || ' ' || d_value;
      elsif p_flag = 1
      then
         d_prefix := p_prefix;
         d_value := p_field_value;
      end if;
      d_result := d_prefix || ' ' || d_value || ' ' || p_suffix;
   end if;
   return d_result;
end get_field_condition;
--------------------------------------------------------------------------------
function get_field_condition
( p_prefix      in varchar2
, p_field_value in date
, p_suffix      in varchar2
, p_flag        in number   default 0
, p_date_format in varchar2 default null
) return varchar2 is
/******************************************************************************
 NOME:        get_field_condition
 DESCRIZIONE: Ottiene stringa con condizione SQL.
 PARAMETRI:   p_prefix       stringa per prefissare la condizione
              p_field_value  valore da controllare
              p_suffix       stringa per suffissare la condizione
              p_flag         0= condizione per uguale
                             1= condizione indicata in valore
              p_date_format  se p_field_value e di tipo date, contiene il formato
                             da utilizzare per effettuare la conversione
 RITORNA:     varchar2 con stringa SQL
 NOTE:        overloading per field_value di tipo DATE
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ------------------------------------------------------
 024   14/03/2007  FT      Aggiunta overloading di get_field_condition per p_field_value
                           di tipo DATE
******************************************************************************/
   d_result t_statement;
begin
   d_result := get_field_condition( p_prefix => p_prefix
                                  , p_field_value => to_char( p_field_value, date_format )
                                  , p_suffix => p_suffix
                                  , p_flag => p_flag
                                  , p_date_format => p_date_format
                                  );
   return d_result;
end get_field_condition;
--------------------------------------------------------------------------------
function decode_value
( p_check_value in varchar2
, p_against_value in varchar2
, p_then_result in varchar2
, p_else_result in varchar2
) return varchar2 is
/******************************************************************************
 NOME:        decode_value
 DESCRIZIONE: Istruzione "decode" per PL/SQL.
 PARAMETRI:   p_check_value    valore da controllare
              p_against_value  valore di confronto
              p_then_result    risultato per uguale
              p_else_result    risultato per diverso
 RITORNA:     varchar2
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ------------------------------------------------------
 009   22/02/2006  FT      Aggiunta dei metodi get_field_condition e decode_value
 011   21/03/2006  MF      - return type t_statement
 ******************************************************************************/
   d_result t_statement;
begin
   if p_check_value = p_against_value
   or (   p_check_value is null
      and p_against_value is null
      )
   then
      d_result := p_then_result;
   else
      d_result := p_else_result;
   end if;
   return d_result;
end decode_value;
--------------------------------------------------------------------------------
function date_format
return varchar2 is
/******************************************************************************
 NOME:        date_format
 DESCRIZIONE: Ritorna il formato standard di conversione di una data.
 PARAMETRI:   -
 RITORNA:     varchar2
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ------------------------------------------------------
 015   19/05/2006  --      Prima emissione
******************************************************************************/
   d_result  varchar2(21);
begin
   d_result := 'dd/mm/yyyy hh24:mi:ss';
   return d_result;
end date_format;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
procedure default_null
(
 p_item_name  in VARCHAR2 default null
) is
/******************************************************************************
 NOME:        default_null
 DESCRIZIONE: Memorizza nome item per gestione "default_null".
 ANNOTAZIONI: -
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ------------------------------------------------------
 028   6/04/2008   MF      Prima emissione.
 029   18/05/2008  MF      Variabile d_item_name di tipo t_statement.
******************************************************************************/
d_item_name   t_statement := upper(p_item_name);
d_object_name t_object_name;
begin
   if ( instr( d_item_name, '.' ) > 0 ) then
      -- Se il nome contiene oggetto.item
      d_object_name := afc.get_substr( d_item_name, '.' );
      if (  s_default_null_object_name != d_object_name
         or s_default_null_object_name is NULL
         ) then
         -- A cambio object inizializza il "defaul_value"
         s_default_null_object_name := d_object_name;
         s_default_null := NULL;
      end if;
   end if;
   if ( d_item_name is NULL ) then
      -- Se item NULL inizializza il "defaul_value"
      s_default_null_object_name := NULL;
      s_default_null := NULL;
   else
      -- Memorizza item inizializzato a NULL
      s_default_null := s_default_null || '#' || d_item_name;
   end if;
end default_null;
--------------------------------------------------------------------------------
function default_null
(
 p_item_name  in VARCHAR2
) return VARCHAR2 is
/******************************************************************************
 NOME:        default_null
 DESCRIZIONE: Ritorna valore NULL per inizializzazione default value e
              memorizza nome item per gestione "default_null".
 ANNOTAZIONI: -
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ------------------------------------------------------
 028   6/04/2008   MF      Prima emissione.
******************************************************************************/
begin
   default_null(p_item_name);
   return  NULL;
end default_null;
--------------------------------------------------------------------------------
function is_default_null
(
 p_item_name  in VARCHAR2
) return number is
/******************************************************************************
 NOME:        is_default_null
 DESCRIZIONE: Ritorna 1 se nome item è stato valorizzato con gestione "default_null".
 RITORNA:     number: 1 se item inizializzato a null
                      0 se item non inizializzato.
 ANNOTAZIONI: -
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ------------------------------------------------------
 028   6/04/2008   MF      Prima emissione.
 029   18/05/2008  MF      Variabile d_item_name di tipo t_statement.
******************************************************************************/
d_item_name   t_statement := upper(p_item_name);
d_object_name t_object_name;
begin
   if ( instr( d_item_name, '.' ) > 0 ) then
      -- Se il nome contiene oggetto.item
      d_object_name := afc.get_substr( d_item_name, '.' );
   end if;
   if (   ( d_object_name is NULL or d_object_name = s_default_null_object_name )
      and ( instr( s_default_null, '#' || d_item_name ) > 0 )
      ) then
      -- Se object non indicato o uguale a ultimo trattato
      -- e item è stato valorizzato gestione con "default_null".
      return 1;
   else
      return 0;
   end if;
end is_default_null;
END AFC;
/

