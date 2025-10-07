--liquibase formatted sql 
--changeset abrandolini:20250326_152429_afc_dml stripComments:false runOnChange:true 
 
create or replace package AFC_DML is
/******************************************************************************
 NOME:        AFC_DML.
 DESCRIZIONE: General utilities for data manipulation
 ANNOTAZIONI: .
 REVISIONI: .
 <CODE>
 Rev.  Data        Autore  Descrizione.
 00    12/05/2005  CZECCA  Prima emissione.
 01    30/08/2006  FT      Aggiunta di get_ref_cursor
 02    13/08/2007  FT      Aggiunta function versione (già presente nel body)
 </CODE>
******************************************************************************/
   s_revisione constant VARCHAR2(30) := 'V1.02';
   function versione return VARCHAR2;
   pragma restrict_references( versione, WNDS, WNPS );
   procedure chk_delete
   ( p_table_name in varchar2
   , p_rowid in varchar2
   );
   function get_ref_cursor
   ( p_statement in AFC.t_statement
   ) return AFC.t_ref_cursor;
end AFC_DML;
/

create or replace package body AFC_DML is
/******************************************************************************
 NOME:        AFC_DML.
 DESCRIZIONE: General utilities for data manipulation.
 ANNOTAZIONI: .
 REVISIONI: .
 Rev.  Data        Autore  Descrizione.
 000   12/05/2005  CZECCA  Prima emissione.
 001   30/08/2006  FT      Aggiunta di get_ref_cursor
 002   04/09/2006  FT      Gestione eccezioni in get_ref_cursor
 003   02/07/2007  FT      Eliminata dipendenza su SI4
******************************************************************************/
   s_revisione_body constant VARCHAR2(30) := '003';
--------------------------------------------------------------------------------
function versione return VARCHAR2 is
/******************************************************************************
 NOME:        VERSIONE
 DESCRIZIONE: Restituisce versione e revisione di distribuzione del package.
 RITORNA:     VARCHAR2 stringa contenente versione e revisione.
 NOTE:        Primo numero  : versione compatibilita del Package.
              Secondo numero: revisione del Package specification.
              Terzo numero  : revisione del Package body.
******************************************************************************/
begin
   return s_revisione||'.'||s_revisione_body;
end versione;
--------------------------------------------------------------------------------
procedure chk_delete
( p_table_name in varchar2
, p_rowid in varchar2
) is
/******************************************************************************
 NOME:        chk_delete
 DESCRIZIONE: verifica di cancellabbilita per tentativo
 PARAMETRI:   p_table_name: nome della tabella
              p_rowid: indice di riga in formato stringa
 ECCEZIONI:   nnnnn, <ExceptionDescription>
 REVISIONI:
 Rev. Data       Autore Descrizione
 ---- ---------- ------ ------------------------------------------------------
 000   12/05/2005  CZECCA  Prima emissione.
 003   02/07/2007  FT      Eliminata dipendenza su SI4
******************************************************************************/
   d_statement varchar2(2000);
begin
   DbC.PRE( not DbC.PreOn or p_table_name is not null );
   DbC.PRE(  not DbC.PreOn
          or AFC_DDL.IsTable( p_table_name )
          or AFC_DDL.IsView( p_table_name )
          );
   savepoint chk_delete_savepoint;
   d_statement := 'delete ' || p_table_name || ' where ROWID = chartorowid( ''' || p_rowid || ''')';
   afc.sql_execute( d_statement );
   rollback to chk_delete_savepoint;
exception
   when others then
      -- all exception are re-raised to the caller
      raise;
end; -- AFC_DML.chk_delete
--------------------------------------------------------------------------------
function get_ref_cursor
( p_statement in AFC.t_statement
) return AFC.t_ref_cursor is
/******************************************************************************
 NOME:        get_ref_cursor
 DESCRIZIONE: Ritorna un ref cursor contenente l'esecuzione dello statement
              passato come parametro.
 PARAMETRI:   p_statement: statement da eseguire
 ECCEZIONI:   nnnnn, <ExceptionDescription>
 REVISIONI:
 Rev. Data       Autore Descrizione
 ---- ---------- ------ ------------------------------------------------------
 000  30/08/2006 FT     Prima emissione.
 002  04/09/2006 FT     Gestione eccezioni
******************************************************************************/
   d_ref_cursor      AFC.t_ref_cursor;
begin
   open d_ref_cursor for p_statement;
   return d_ref_cursor;
exception
   when others then
      raise_application_error( -20999, 'statement error: ' || p_statement, true );
end;
--------------------------------------------------------------------------------
end AFC_DML;
/

