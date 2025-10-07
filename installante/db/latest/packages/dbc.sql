--liquibase formatted sql 
--changeset abrandolini:20250326_152429_dbc stripComments:false runOnChange:true 
 
create or replace package DbC is
/******************************************************************************
 NAME:        DbC.
 DESCRIPTION: Machinery to support Design-by-Contract.
 ANNOTATIONS: .
 REVISION: .
 <CODE>
 Rev.  Date        Author  Description
 00    16/03/2005  CZecca  First release.
 01    03/01/2006  CZecca  handling of clauses which evaluate to null; version and revision
 02    12/04/2006  FT      sobstitution of ampersand character with token 'and' in revision
                           01 to solve problems during the package execution in SQL*Plus
 03    30/08/2006  FT      Modifica dichiarazione subtype per incompatibilità con
                           versione 7 di Oracle
 </CODE>
******************************************************************************/
   d_revision varchar2(30);
   subtype t_revision is d_revision%type;
   s_revisione constant t_revision := 'V1.03';
   function versione return t_revision;
   pragma restrict_references( versione, WNDS, WNPS );
   pragma restrict_references( DbC, WNDS );
   -- {%skip} pragma exception_init does NOT allow use of symbolic constants
   -- Type of numeric error codes associated to the exceptions
   subtype t_error_number is binary_integer;
   -- Diagnostics for the precondition violations
   precondition_violation           exception;
   precondition_number              constant t_error_number := -20101;
   pragma exception_init( precondition_violation, -20101 );
   -- Diagnostics for the postcondition violations
   postcondition_violation          exception;
   postcondition_number             constant number := -20102;
   pragma exception_init( postcondition_violation, -20102 );
   -- Diagnostics for the assertion violations
   assertion_violation              exception;
   assertion_number                 constant number := -20103;
   pragma exception_init( assertion_violation, -20103 );
   -- Diagnostics for the invariant violations
   invariant_violation              exception;
   invariant_number                 constant number := -20104;
   pragma exception_init( invariant_violation, -20104 );
   -- To check precondition clauses
   procedure PRE
   ( p_condition in boolean
   , p_message in varchar2 := null
   );
   pragma restrict_references( PRE, WNDS );
   -- To know if check of precondition clauses is on
   function pre_on
   return number;
   pragma restrict_references( pre_on, WNDS );
   function PreOn
   return boolean;
   pragma restrict_references( PreOn, WNDS );
   -- To switch on/off the check of precondition clauses
   procedure pre_set
   ( p_on in number
   );
   procedure PreSet
   ( p_on in boolean
   );
   -- To check postcondition clauses
   procedure POST
   ( p_condition in boolean
   , p_message in varchar2 := null
   );
   pragma restrict_references( POST, WNDS );
   -- To know if check of postcondition clauses is on
   function post_on
   return number;
   pragma restrict_references( post_on, WNDS );
   function PostOn
   return boolean;
   pragma restrict_references( PostOn, WNDS );
   -- To switch on/off the check of postcondition clauses
   procedure post_set
   ( p_on in number
   );
   procedure PostSet
   ( p_on in boolean
   );
   -- To check assertion clauses
   procedure ASSERTION
   ( p_condition in boolean
   , p_message in varchar2 := null
   );
   pragma restrict_references( ASSERTION, WNDS );
   -- To know if check of assertion clauses is on
   function assertion_on
   return number;
   pragma restrict_references( assertion_on, WNDS );
   function AssertionOn
   return boolean;
   pragma restrict_references( AssertionOn, WNDS );
   -- To switch on/off the check of assertion clauses
   procedure assertion_set
   ( p_on in number
   );
   procedure AssertionSet
   ( p_on in boolean
   );
   -- To check invariant clauses
   procedure INVARIANT
   ( p_condition in boolean
   , p_message in varchar2 := null
   );
   pragma restrict_references( INVARIANT, WNDS );
   -- To know if check of invariant clauses is on
   function invariant_on
   return number;
   pragma restrict_references( invariant_on, WNDS );
   function InvariantOn
   return boolean;
   pragma restrict_references( InvariantOn, WNDS );
   -- To switch on/off the check of invariant clauses
   procedure invariant_set
   ( p_on in number
   );
   procedure InvariantSet
   ( p_on in boolean
   );
end DbC;
/

create or replace package body DbC
is
/******************************************************************************
 NAME:        DbC
 DESCRIPTION: Machinery to support Design-by-Contract.
 ANNOTATIONS: -
 REVISION:
 Rev.  Date        Author  Description
 ----  ----------  ------  ----------------------------------------------------
 000   16/03/2005  CZecca  First release.
 001   03/01/2006  CZecca  Clauses that evaluate to null reported as exceptions; version and revision
 002   12/04/2006  FT      sostitution of ampersand character with token 'and' in revision
                           001 to solve problems during the package execution in SQL*Plus
 003   30/08/2006  FT      Modifica dichiarazione subtype per incompatibilità con
                           versione 7 di Oracle
******************************************************************************/
   s_revisione_body t_revision := '003';
   s_pre_on boolean := false;
   s_post_on boolean := false;
   s_assertion_on boolean := false;
   s_invariant_on boolean := false;
   d_message varchar2(1000);
   subtype t_message is d_message%type;
--------------------------------------------------------------------------------
function versione
return t_revision
is
/******************************************************************************
 NAME:        versione
 DESCRPTION:  returns the package release version and revision
 RETURN:      varchar2 string containing version and revision.
 NOTES:       1st number : copmpatibility version of the package.
              2nd number : specification revision of the package.
              3rd number : package body revision.
******************************************************************************/
   d_result varchar2(10);
begin
   d_result := s_revisione || '.' || s_revisione_body;
   return d_result;
end versione;
--------------------------------------------------------------------------------
function
clause_prefix
( p_clause_number in number
)
return t_message
is
   d_result t_message;
begin
   if p_clause_number = precondition_number then
      d_result := 'PRE';
   elsif p_clause_number = postcondition_number then
      d_result := 'POST';
   elsif p_clause_number = assertion_number then
      d_result := 'ASSERTION';
   else
      d_result := 'INVARIANT';
   end if;
   return d_result;
end; -- DbC.clause_prefix
--------------------------------------------------------------------------------
procedure assert
( p_condition in boolean
, p_message in varchar2
, p_error_number in t_error_number
)
is
   d_message t_message;
begin
   -- both
   -- o  null booolean conditions and
   -- o  conditions that evaluate to false
   -- will be regarded and reported as exceptions
   if p_condition is null
   or not p_condition
   then
      d_message := clause_prefix( p_error_number );
      if p_condition is null then
         d_message := d_message || ': boolean expression evaluates to null';
      elsif not p_condition then
         d_message := d_message || ' violation';
      end if;
      if p_message is not null then
         d_message := d_message || ': ' || p_message;
      end if;
      dbms_output.put_line( d_message );
      raise_application_error( p_error_number, d_message, true );
   end if;
end; -- DbC.assert
--------------------------------------------------------------------------------
procedure PRE
( p_condition in boolean
, p_message in varchar2 -- := null
)
is
begin
   if s_pre_on then
      assert( p_condition, p_message, precondition_number );
   end if;
end; -- DbC.PRE
--------------------------------------------------------------------------------
function pre_on
return number
is
   d_result number;
begin
   if PreOn then
      d_result := 1;
   else
      d_result := 0;
   end if;
   return  d_result;
end; -- DbC.pre_on
--------------------------------------------------------------------------------
function PreOn
return boolean
is
   d_result boolean := s_pre_on;
begin
   return  d_result;
end; -- DbC.PreOn
--------------------------------------------------------------------------------
procedure PreSet
( p_on in boolean
)
is
begin
   s_pre_on := p_on;
end; -- DbC.PreSet
--------------------------------------------------------------------------------
procedure pre_set
( p_on in number
)
is
begin
   if p_on = 1 then
      PreSet( true );
   else
      PreSet( false );
   end if;
end; -- DbC.PreSet
--------------------------------------------------------------------------------
procedure POST
( p_condition in boolean
, p_message in varchar2 -- := null
)
is
begin
   if s_post_on then
      assert( p_condition, p_message, postcondition_number );
   end if;
end; -- DbC.POST
--------------------------------------------------------------------------------
function post_on
return number
is
   d_result number;
begin
   if PostOn then
      d_result := 1;
   else
      d_result := 0;
   end if;
   return  d_result;
end; -- DbC.post_on
--------------------------------------------------------------------------------
function PostOn
return boolean
is
   d_result boolean := s_post_on;
begin
   return  d_result;
end; -- DbC.PostOn
--------------------------------------------------------------------------------
procedure post_set
( p_on in number
)
is
begin
   if p_on = 1 then
      PostSet( true );
   else
      PostSet( false );
   end if;
end; -- DbC.post_set
--------------------------------------------------------------------------------
procedure PostSet
( p_on in boolean
)
is
begin
   s_post_on := p_on;
end; -- DbC.PostSet
--------------------------------------------------------------------------------
procedure ASSERTION
( p_condition in boolean
, p_message in varchar2 -- := null
)
is
begin
   if s_assertion_on then
      assert( p_condition, p_message, assertion_number );
   end if;
end; -- DbC.ASSERTION
--------------------------------------------------------------------------------
function assertion_on
return number
is
   d_result number;
begin
   if AssertionOn then
      d_result := 1;
   else
      d_result := 0;
   end if;
   return  d_result;
end; -- DbC.assertion_on
--------------------------------------------------------------------------------
function AssertionOn
return boolean
is
   d_result boolean := s_assertion_on;
begin
   return  d_result;
end; -- DbC.AssertionOn
--------------------------------------------------------------------------------
procedure assertion_set
( p_on in number
)
is
begin
   if p_on = 1 then
      AssertionSet( true );
   else
      AssertionSet( false );
   end if;
end; -- DbC.assertion_set
--------------------------------------------------------------------------------
procedure AssertionSet
( p_on in boolean
)
is
begin
   s_assertion_on := p_on;
end; -- DbC.AssertionSet
--------------------------------------------------------------------------------
procedure INVARIANT
( p_condition in boolean
, p_message in varchar2 -- := null
)
is
begin
   if s_invariant_on then
      assert( p_condition, p_message, invariant_number );
   end if;
end; -- DbC.INVARIANT
--------------------------------------------------------------------------------
function invariant_on
return number
is
   d_result number;
begin
   if InvariantOn then
      d_result := 1;
   else
      d_result := 0;
   end if;
   return  d_result;
end; -- DbC.invariant_on
--------------------------------------------------------------------------------
function InvariantOn
return boolean
is
   d_result boolean := s_invariant_on;
begin
   return  d_result;
end; -- DbC.InvariantOn
--------------------------------------------------------------------------------
procedure invariant_set
( p_on in number
)
is
begin
   if p_on = 1 then
      InvariantSet( true );
   else
      InvariantSet( false );
   end if;
end; -- DbC.invariant_set
--------------------------------------------------------------------------------
procedure InvariantSet
( p_on in boolean
)
is
begin
   s_invariant_on := p_on;
end; -- DbC.InvariantSet
--------------------------------------------------------------------------------
end DbC;
/

