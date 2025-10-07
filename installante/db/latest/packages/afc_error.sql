--liquibase formatted sql 
--changeset abrandolini:20250326_152429_afc_error stripComments:false runOnChange:true 
 
create or replace package AFC_Error is
/******************************************************************************
 NOME:        AFC_Error.
 DESCRIZIONE: Package for error handling (see also SI4.get_error).
 ANNOTAZIONI: .
 REVISIONI:   .
 <CODE>
 Rev.  Data        Autore  Descrizione.
 00    03/05/2005  CZ      Prima emissione.
 01    06/09/2005  FT      Gestione tabella errori t_error_table.
 02    22/02/2006  FT      Aggiunta definizione errore modified_by_other_user
 03    30/08/2006  FT      Modifica dichiarazione subtype per incompatibilità con
                           versione 7 di Oracle
 04    29/11/2006  FT      Aggiunta definizione errore exception_not_in_table
 </CODE>
******************************************************************************/
   -- Revisione
   s_revisione constant varchar2(30) := 'V1.04';
   -- Version and revisione
   function versione
   return varchar2;
   pragma restrict_references( versione, WNDS );
   -- Type of error number code associated with the exceptions
   subtype t_error_number is binary_integer;
   -- Type of initial part of the messages to be interpreted by SI4.get_error
   d_error_msg varchar2(240);
   subtype t_error_msg is d_error_msg%type;
   -- Type of table for join error codes and application errors
   type t_error_table is table of t_error_msg index by binary_integer;
   ok constant t_error_number := 1;
   -- Diagnostic for insertion of null values: violation of not null constraints raised by the db
   null_value_ins_db            exception;
   null_value_ins_db_msg        constant t_error_msg := 'null value db';
   null_value_ins_db_number     constant t_error_number := -01400;
   pragma exception_init( null_value_ins_db, -01400 );
   -- Diagnostic for update with null values: violation of not null constraints raised by the db
   null_value_upd_db            exception;
   null_value_upd_db_msg        constant t_error_msg := 'null value db';
   null_value_upd_db_number     constant t_error_number := -01407;
   pragma exception_init( null_value_upd_db, -01407 );
   -- Diagnostic for validation of attribute check violation
   CC_violated_constraint               exception;
   CC_violated_constraint_msg           constant t_error_msg := 'check constraint violated';
   CC_violated_constraint_number        constant t_error_number := -02290;
   pragma exception_init( CC_violated_constraint, -02290 );
   -- Exception for RI administration: trigger
      ----------------------------------------
   -- Diagnostic for insertion of row with attribute with FK constraint whose value is
   -- inexistent in father
   FK_insert_trigger               exception;
   FK_insert_trigger_msg           constant t_error_msg := 'not found on insert';
   FK_insert_trigger_number        constant t_error_number := -20002;
   pragma exception_init( FK_insert_trigger, -20002 );
   -- Diagnostic for modification of row with attribute with FK constraint whose value is
   -- inexistent in father
   FK_update_trigger               exception;
   FK_update_trigger_msg           constant t_error_msg := 'not found on update';
   FK_update_trigger_number        constant t_error_number := -20003;
   pragma exception_init( FK_update_trigger, -20003 );
   -- Diagnostic for existence of child rows on restrict update (FR: Foreign Referece)
   FR_update_trigger             exception;
   FR_update_trigger_msg         constant t_error_msg := 'child exists on update';
   FR_update_trigger_number      constant t_error_number := -20005;
   pragma exception_init( FR_update_trigger, -20005 );
   -- Diagnostic for existence of child rows on restrict delete (FR: Foreign Referece)
   FR_delete_trigger             exception;
   FR_delete_trigger_msg         constant t_error_msg := 'child exists on delete';
   FR_delete_trigger_number      constant t_error_number := -20006;
   pragma exception_init( FR_delete_trigger, -20006 );
   -- Exception for RI administration: constraint
      -------------------------------------------
   -- Diagnostic for insertion of row with attribute with FK constraint whose value is
   -- inexistent in father
   FK_insert_constraint               exception;
   FK_insert_constraint_msg           constant t_error_msg := 'not found on insert';
   FK_insert_constraint_number        constant t_error_number := -02291;
   pragma exception_init( FK_insert_constraint, -02291 );
   -- Diagnostic for modification of row with attribute with FK constraint whose value is
   -- inexistent in father
   FK_update_constraint               exception;
   FK_update_constraint_msg           constant t_error_msg := 'not found on update';
   FK_update_constraint_number        constant t_error_number := -02291;
   pragma exception_init( FK_update_constraint, -02291 );
   -- Diagnostic for existence of child rows on restrict update (FR: Foreign Referece)
   FR_update_constraint             exception;
   FR_update_constraint_msg         constant t_error_msg := 'child exists on update';
   FR_update_constraint_number      constant t_error_number := -02292;
   pragma exception_init( FR_update_constraint, -02292 );
   -- Diagnostic for existence of child rows on restrict delete (FR: Foreign Referece)
   FR_delete_constraint             exception;
   FR_delete_constraint_msg         constant t_error_msg := 'child exists on delete';
   FR_delete_constraint_number      constant t_error_number := -02292;
   pragma exception_init( FR_delete_constraint, -02292 );
   -- Exception for RI administration: trigger postEvent
      --------------------------------------------------
   -- Diagnostic for insertion of row with attribute with FK constraint whose value is
   -- inexistent in father
   FK_insert_postEvent               exception;
   FK_insert_postEvent_msg           constant t_error_msg := 'not found on insert';
   FK_insert_postEvent_number        constant t_error_number := -20008;
   pragma exception_init( FK_insert_postEvent, -20008 );
   -- Diagnostic for modification of row with attribute with FK constraint whose value is
   -- inexistent in father
   FK_update_postEvent               exception;
   FK_update_postEvent_msg           constant t_error_msg := 'not found on update';
   FK_update_postEvent_number        constant t_error_number := -20008;
   pragma exception_init( FK_update_postEvent, -20008 );
   -- Diagnostic for existence of child rows on restrict update (FR: Foreign Referece)
   FR_update_postEvent             exception;
   FR_update_postEvent_msg         constant t_error_msg := 'child exists on update';
   FR_update_postEvent_number      constant t_error_number := -20008;
   pragma exception_init( FR_update_postEvent, -20008 );
   -- Diagnostic for existence of child rows on restrict delete (FR: Foreign Referece)
   FR_delete_postEvent             exception;
   FR_delete_postEvent_msg         constant t_error_msg := 'child exists on delete';
   FR_delete_postEvent_number      constant t_error_number := -20008;
   pragma exception_init( FR_delete_postEvent, -20008 );
   -- Diagnostic for violation of unique constraint
   -- The value -20007 is hard-coded in the templates Si4ForOracleX
   -- wich are used by PowerDesigner to generate the TIU triggers
   unique_key              exception;
   unique_key_msg          constant t_error_msg := 'unique key';
   unique_key_number       constant t_error_number := -20007;
   pragma exception_init( unique_key, -20007 );
   -- Diagnostic for violation of unique constraints raised by the db
   unique_key_db           exception;
   unique_key_db_msg       constant t_error_msg := 'unique key db';
   unique_key_db_number    constant t_error_number := -00001;
   pragma exception_init( unique_key_db, -00001 );
   -- Diagnostic for access to a record modified by anorher user
   modified_by_other_user           exception;
   modified_by_other_user_msg       constant t_error_msg := 'Modified by another user';
   modified_by_other_user_number    constant t_error_number := -20010;
   pragma exception_init( modified_by_other_user, -20010 );
   -- Diagnostic for access to a Table_Package error inexistent in its error_table
   exception_not_in_table           exception;
   exception_not_in_table_msg       constant t_error_msg := 'Exception not in error_table';
   exception_not_in_table_number    constant t_error_number := -20011;
   pragma exception_init( exception_not_in_table, -20011 );
   -- Diagnostic for the end user
   generic_error           exception;
   generic_error_number    constant t_error_number := -20999;
   pragma exception_init( generic_error, -20999 );
   -- Generates a diagnostic message that can be interpreted by SI4.get_error
   -- structured as follows: ORA-<I>nnnnn</I>: <I> msg header </I> ( <I>table_name.constraint_name</I> )
   procedure raise_application_error
   ( p_error_number in t_error_number
   , p_table_name in varchar2
   , p_constraint_name in varchar2
   );
   pragma restrict_references( raise_application_error, WNDS );
end AFC_Error;
/

create or replace package body AFC_Error is
/******************************************************************************
 NOME:        Attivita_pkg.
 DESCRIZIONE: Gestione tabella attivita.
 ANNOTAZIONI: .
 REVISIONI:   .
 Rev.  Data        Autore  Descrizione.
 000   03/05/2005  CZ      Prima emissione.
 001   06/09/2005  FT      Gestione tabella errori t_error_table.
******************************************************************************/
   s_revisione_body           constant AFC.t_revision := '001';
--------------------------------------------------------------------------------
function versione
return varchar2 is
/******************************************************************************
 NOME:        versione.
 DESCRIZIONE: Versione e revisione di distribuzione del package.
 RITORNA:     varchar2 stringa contenente versione e revisione.
 NOTE:        Primo numero  : versione compatibilità del Package.
              Secondo numero: revisione del Package specification.
              Terzo numero  : revisione del Package body.
******************************************************************************/
begin
   return AFC.version( s_revisione, s_revisione_body );
end; -- AFC_Error.versione
--------------------------------------------------------------------------------
procedure raise_application_error
( p_error_number in t_error_number
, p_table_name in varchar2
, p_constraint_name in varchar2
)
is
   d_error_msg varchar2(2000);
   d_msg_header t_error_msg;
begin
   if    p_error_number = FK_insert_trigger_number then
      d_msg_header := FK_insert_trigger_msg;
   elsif p_error_number = FK_update_trigger_number then
      d_msg_header := FK_update_trigger_msg;
   elsif p_error_number = FR_update_trigger_number then
      d_msg_header := FR_update_trigger_msg;
   elsif p_error_number = FR_delete_trigger_number then
      d_msg_header := FR_delete_trigger_msg;
   elsif p_error_number = FK_insert_constraint_number then
      d_msg_header := FK_insert_constraint_msg;
   elsif p_error_number = FK_update_constraint_number then
      d_msg_header := FK_update_constraint_msg;
   elsif p_error_number = FR_update_constraint_number then
      d_msg_header := FR_update_constraint_msg;
   elsif p_error_number = FR_delete_constraint_number then
      d_msg_header := FR_delete_constraint_msg;
   elsif p_error_number = FK_insert_postEvent_number then
      d_msg_header := FK_insert_postEvent_msg;
   elsif p_error_number = FK_update_postEvent_number then
      d_msg_header := FK_update_postEvent_msg;
   elsif p_error_number = FR_update_postEvent_number then
      d_msg_header := FR_update_postEvent_msg;
   elsif p_error_number = FR_delete_postEvent_number then
      d_msg_header := FR_delete_postEvent_msg;
   elsif p_error_number = unique_key_number then
      d_msg_header := unique_key_msg;
   elsif p_error_number = unique_key_db_number then
      d_msg_header := unique_key_db_msg;
   else
      DbC.PRE( false, 'invalid p_error_number' );
   end if;
   d_error_msg := d_msg_header || ' (' || p_table_name || '.' || p_constraint_name || ')';
   dbms_standard.raise_application_error( p_error_number, d_error_msg, true );
end; -- AFC_Error.raise_application_error
--------------------------------------------------------------------------------
end AFC_Error;
/

