--liquibase formatted sql
--changeset dmarotta:20250326_152438_Si4Comp_t stripComments:false
--validCheckSum: 1:any

/*==============================================================*/
/* DBMS name:      Si4 for ORACLE 8                             */
/* Created on:     29/01/2004 11.49.31                          */
/*==============================================================*/



-- Integrity Package declaration

create or replace package IntegrityPackage
/******************************************************************************
 NOME:        IntegrityPackage
 DESCRIZIONE: Oggetti per la gestione della Integrita Referenziale.
              Contiene le Procedure e function per la gestione del livello di
              annidamento dei trigger.
              Contiene le Procedure per il POSTING degli script alla fase di 
              AFTER STATEMENT.
 REVISIONI:
 Rev. Data        Autore  Descrizione
 ---- ----------  ------  ----------------------------------------------------
 1    23/01/2001  MF      Inserimento commento.
******************************************************************************/
AS
   -- Variabili per SET Switched FUNCTIONAL Integrity
   Functional boolean := TRUE;

   -- Procedure for Referential Integrity
   procedure SetFunctional;
   procedure ReSetFunctional;
   procedure InitNestLevel;
   function  GetNestLevel return number;
   procedure NextNestLevel;
   procedure PreviousNestLevel;

   /* Variabili e Procedure per IR su Relazioni Ricorsive */ 
   type t_operazione is TABLE of varchar2(32000) index by binary_integer;
   type t_messaggio  is TABLE of varchar2(2000) index by binary_integer;
   v_istruzione   t_operazione;
   v_messaggio    t_messaggio;
   v_entry        binary_integer := 0;
   procedure Set_PostEvent (a_istruzione varchar2,
                            a_messaggio  varchar2);
   procedure Exec_PostEvent;

END IntegrityPackage;
/* End Package: IntegrityPackage
   N.B.: In caso di "Generate Trigger" successive alla prima
         IGNORARE Errore di Package gia presente
*/
/

-- Integrity Package body definition

create or replace package body IntegrityPackage
AS
   NestLevel   number;

-- Procedure to Initialize Switched Functional Integrity
PROCEDURE SetFunctional
is
BEGIN
   Functional := TRUE;
END; 

-- Procedure to Reset Switched Functional Integrity
PROCEDURE ReSetFunctional
is
BEGIN
   Functional := FALSE;
END; 

-- Procedure to initialize the trigger nest level
PROCEDURE InitNestLevel
is
BEGIN
   NestLevel := 0;
   v_entry   := 0;
END; 

-- Function to return the trigger nest level
FUNCTION GetNestLevel return number
is
BEGIN
   if NestLevel is null then
      NestLevel := 0;
   end if;
   return(NestLevel);
END; 

-- Procedure to increase the trigger nest level
PROCEDURE NextNestLevel
is
BEGIN
   if NestLevel is null then
      NestLevel := 0;
   end if;
   NestLevel := NestLevel + 1;
END; 

-- Procedure to decrease the trigger nest level
PROCEDURE PreviousNestLevel
is
BEGIN
   NestLevel := NestLevel - 1;
END; 

-- Procedure Memorizzazione istruzioni da attivare in POST statement
PROCEDURE Set_PostEvent
/******************************************************************************
 NOME:        Set_PostEvent
 DESCRIZIONE: Memorizzazione istruzioni da attivare in POST statement.

 ARGOMENTI:   a_istruzione VARCHAR2 Istruzione SQL da memorizzare.
              a_messaggio  VARCHAR2 Messaggio da inviare per errore in esecuzione.
 REVISIONI:
 Rev. Data       Autore Descrizione
 ---- ---------- ------ ------------------------------------------------------
 1    23/01/2001  MF    Inserimento commento.
******************************************************************************/
( a_istruzione  varchar2
, a_messaggio   varchar2
)
IS
   actual_level    integer;
BEGIN
   actual_level := IntegrityPackage.GetNestLevel;
   v_entry := v_entry + 1;
   v_istruzione(v_entry) := a_istruzione;
   v_messaggio(v_entry)  := lpad(actual_level,2,'0')||a_messaggio;
END Set_PostEvent;

-- Procedure Esecuzione istruzioni memorizzate in POST Statement
PROCEDURE Exec_PostEvent
/******************************************************************************
 NOME:        Exec_PostEvent
 DESCRIZIONE: Esecuzione istruzioni memorizzate in POST Statement.

 ARGOMENTI:   -
 REVISIONI:
 Rev. Data       Autore Descrizione
 ---- ---------- ------ ------------------------------------------------------
 1    23/01/2001  MF    Inserimento commento.
******************************************************************************/
IS
cursor_id       integer;
rows_processed  integer;
actual_level    integer;
element_level   integer;
element_message varchar2(2000);
BEGIN
   actual_level := IntegrityPackage.GetNestLevel;
   FOR LoopCnt IN 1..v_entry LOOP
      element_level := to_number(substr(v_messaggio(LoopCnt), 1, 2));
      IF  element_level = actual_level
      AND v_istruzione(LoopCnt)is NOT NULL
      THEN
         IntegrityPackage.NextNestLevel;
         BEGIN
            cursor_id := dbms_sql.open_cursor;
            dbms_sql.parse(cursor_id, v_istruzione(LoopCnt), dbms_sql.native);
            IF upper(substr(ltrim(v_istruzione(LoopCnt)), 1, 6)) = 'SELECT' THEN
               rows_processed:= dbms_sql.execute_and_fetch(cursor_id);
               IF  substr(ltrim(substr(ltrim(v_istruzione(LoopCnt)), 7)), 1, 1) = 0
               AND rows_processed > 0 THEN
                  element_message := substr(v_messaggio(LoopCnt), 3);
                  IF element_message is null THEN
                     element_message := 'Sono presenti registrazioni collegate. Operazione non eseguita.';
                  END IF;
                  raise_application_error(-20008,element_message);
               ELSIF  substr(ltrim(substr(ltrim(v_istruzione(LoopCnt)),7)), 1, 1) != 0
                  AND rows_processed = 0 THEN
                  element_message := substr(v_messaggio(LoopCnt), 3);
                  IF element_message is null THEN
                     element_message := 'Non e'' presente la registrazione richiesta. Operazione non eseguita.';
                  END IF;
                  raise_application_error(-20008, element_message);
               END IF;            
            ELSE -- non statement di SELECT
               rows_processed:= dbms_sql.execute(cursor_id);
            END IF;
            dbms_sql.close_cursor(cursor_id);
         EXCEPTION
            WHEN OTHERS THEN
               dbms_sql.close_cursor(cursor_id);
            raise;
         END;
         IntegrityPackage.PreviousNestLevel;
         v_istruzione(LoopCnt) := NULL;
      END IF;
   END LOOP;
EXCEPTION   
   WHEN OTHERS THEN
      InitNestLevel;
      raise;
END Exec_PostEvent;
 
END IntegrityPackage;
/* End Package Body: IntegrityPackage */
/

-- Utility Package declaration

create or replace package UtilityPackage
/******************************************************************************
 NOME:        UtilityPackage
 DESCRIZIONE: Contiene oggetti di utilita generale.
 REVISIONI:
 Rev. Data        Autore  Descrizione
 ---- ----------  ------  ----------------------------------------------------
 1    23/01/2001  MF      Inserimento commento.
******************************************************************************/
AS
   procedure Compile_All;

END UtilityPackage;
/* End Package: UtilityPackage */
/

-- Utility Package body definition

create or replace package body UtilityPackage
AS
PROCEDURE Compile_All
/******************************************************************************
 NOME:        Compile_All
 DESCRIZIONE: Compilazione di tutti gli oggetti invalidi presenti nel DB.
 ANNOTAZIONI: Tenta la compilazione in cicli successivi.
              Termina la compilazione quando il numero degli oggetti
              invalidi non varia rispetto al ciclo precedente.
 REVISIONI:
 Rev. Data        Autore  Descrizione
 ---- ----------  ------  ----------------------------------------------------
 1    23/01/2001  MF      Inserimento commento.
******************************************************************************/
IS
   d_obj_name       varchar2(30);
   d_obj_type       varchar2(30);
   d_command        varchar2(200);
   d_cursor         integer;
   d_rows           integer;
   d_old_rows       integer;
   d_return         integer;
   cursor c_obj is
      select object_name, object_type
      from   OBJ
      where  object_type in ('PROCEDURE'
                            ,'TRIGGER'
                            ,'FUNCTION'
                            ,'PACKAGE'
                            ,'PACKAGE BODY'
                            ,'VIEW')
       and   status = 'INVALID'
      order by  decode(object_type
                      ,'PACKAGE',1
                      ,'PACKAGE BODY',2
                      ,'FUNCTION',3
                      ,'PROCEDURE',4
                      ,'VIEW',5
                             ,6)
             , object_name
      ;
BEGIN
   d_old_rows := 0;
   LOOP
      d_rows := 0;
      BEGIN
         open  c_obj;
         LOOP
            BEGIN
               fetch c_obj into d_obj_name, d_obj_type;
               EXIT WHEN c_obj%NOTFOUND;
               d_rows := d_rows + 1;
               IF d_obj_type = 'PACKAGE BODY' THEN
                  d_command := 'alter PACKAGE '||d_obj_name||' compile BODY';
               ELSE
                  d_command := 'alter '||d_obj_type||' '||d_obj_name||' compile';
               END IF;
               d_cursor  := dbms_sql.open_cursor;
               dbms_sql.parse(d_cursor,d_command,dbms_sql.native);
               d_return := dbms_sql.execute(d_cursor);
               dbms_sql.close_cursor(d_cursor);
            EXCEPTION
               WHEN OTHERS THEN null;
            END;
         END LOOP;
         close c_obj;
      END;
      if d_rows = d_old_rows then
         EXIT;
      else
         d_old_rows := d_rows;
      end if;
   END LOOP;
   if d_rows > 0 then
      raise_application_error(-20999,'Esistono n.'||to_char(d_rows)||' Oggetti di DataBase non validabili !');
   end if;
END Compile_All;
 
END UtilityPackage;
/* End Package Body: UtilityPackage */
/



-- Create Custom FUNCTIONAL Integrity Trigger on INSERT or UPDATE or DELETE
create or replace trigger SI4_ABILITAZIONI_TIU
   before INSERT or UPDATE or DELETE on SI4_ABILITAZIONI
for each row
/******************************************************************************
 NOME:        SI4_ABILITAZIONI_TIU
 DESCRIZIONE: Trigger for Check FUNCTIONAL Integrity
                            Set FUNCTIONAL Integrity
                       at INSERT or UPDATE or DELETE on Table SI4_ABILITAZIONI
 ECCEZIONI:  -20007, Identificazione CHIAVE presente in TABLE
 ANNOTAZIONI: -  
 REVISIONI:
 Rev. Data       Autore Descrizione
 ---- ---------- ------ ------------------------------------------------------
    0 __/__/____ __     
******************************************************************************/
declare
   functionalNestLevel integer;
   integrity_error  exception;
   errno            integer;
   errmsg           char(200);
   dummy            integer;
   found            boolean;
begin
   functionalNestLevel := IntegrityPackage.GetNestLevel;
   begin  -- Check FUNCTIONAL Integrity
      --  Column "ID_ABILITAZIONE" uses sequence ABIL_SQ
      if :NEW.ID_ABILITAZIONE IS NULL and not DELETING then
         select ABIL_SQ.NEXTVAL
           into :new.ID_ABILITAZIONE
           from dual;
      end if;
      begin  -- Check UNIQUE Integrity on PK of "SI4_ABILITAZIONI"
         if IntegrityPackage.GetNestLevel = 0 and not DELETING then
            declare
            cursor cpk_si4_abilitazioni(var_ID_ABILITAZIONE number) is
               select 1
                 from   SI4_ABILITAZIONI
                where  ID_ABILITAZIONE = var_ID_ABILITAZIONE;
            mutating         exception;
            PRAGMA exception_init(mutating, -4091);
            begin 
               if :new.ID_ABILITAZIONE is not null then
                  open  cpk_si4_abilitazioni(:new.ID_ABILITAZIONE);
                  fetch cpk_si4_abilitazioni into dummy;
                  found := cpk_si4_abilitazioni%FOUND;
                  close cpk_si4_abilitazioni;
                  if found then
                     errno  := -20007;
                     errmsg := 'Identificazione "'||
                               :new.ID_ABILITAZIONE||
                               '" gia'' presente in Abilitazioni. La registrazione  non puo'' essere inserita.';
                     raise integrity_error;
                  end if;
               end if;
            exception
               when MUTATING then null;  -- Ignora Check su UNIQUE PK Integrity
            end;
         end if;
      end;
      null;
   end;
   begin  -- Set FUNCTIONAL Integrity
      if functionalNestLevel = 0 then
         IntegrityPackage.NextNestLevel;
         begin  -- Global FUNCTIONAL Integrity at Level 0
            /* NONE */ null;
         end;
        IntegrityPackage.PreviousNestLevel;
      end if;
      IntegrityPackage.NextNestLevel;
      begin  -- Full FUNCTIONAL Integrity at Any Level
         /* NONE */ null;
      end;
      IntegrityPackage.PreviousNestLevel;
   end;
exception
   when integrity_error then
        IntegrityPackage.InitNestLevel;
        raise_application_error(errno, errmsg);
   when others then
        IntegrityPackage.InitNestLevel;
        raise;
end;
/* End Trigger: SI4_ABILITAZIONI_TIU */
/

-- Create Custom FUNCTIONAL Integrity Trigger on INSERT or UPDATE or DELETE
create or replace trigger SI4_COMPETENZE_TIU
   before INSERT or UPDATE or DELETE on SI4_COMPETENZE
for each row
/******************************************************************************
 NOME:        SI4_COMPETENZE_TIU
 DESCRIZIONE: Trigger for Check FUNCTIONAL Integrity
                            Set FUNCTIONAL Integrity
                       at INSERT or UPDATE or DELETE on Table SI4_COMPETENZE
 ECCEZIONI:  -20007, Identificazione CHIAVE presente in TABLE
 ANNOTAZIONI: -  
 REVISIONI:
 Rev. Data       Autore Descrizione
 ---- ---------- ------ ------------------------------------------------------
    0 __/__/____ __     
******************************************************************************/
declare
   functionalNestLevel integer;
   integrity_error  exception;
   errno            integer;
   errmsg           char(200);
   dummy            integer;
   found            boolean;
begin
   functionalNestLevel := IntegrityPackage.GetNestLevel;
   begin  -- Check FUNCTIONAL Integrity
      --  Column "ID_COMPETENZA" uses sequence COMP_SQ
      if :NEW.ID_COMPETENZA IS NULL and not DELETING then
         select COMP_SQ.NEXTVAL
           into :new.ID_COMPETENZA
           from dual;
      end if;
      begin  -- Check UNIQUE Integrity on PK of "SI4_COMPETENZE"
         if IntegrityPackage.GetNestLevel = 0 and not DELETING then
            declare
            cursor cpk_si4_competenze(var_ID_COMPETENZA number) is
               select 1
                 from   SI4_COMPETENZE
                where  ID_COMPETENZA = var_ID_COMPETENZA;
            mutating         exception;
            PRAGMA exception_init(mutating, -4091);
            begin 
               if :new.ID_COMPETENZA is not null then
                  open  cpk_si4_competenze(:new.ID_COMPETENZA);
                  fetch cpk_si4_competenze into dummy;
                  found := cpk_si4_competenze%FOUND;
                  close cpk_si4_competenze;
                  if found then
                     errno  := -20007;
                     errmsg := 'Identificazione "'||
                               :new.ID_COMPETENZA||
                               '" gia'' presente in Competenze. La registrazione  non puo'' essere inserita.';
                     raise integrity_error;
                  end if;
               end if;
            exception
               when MUTATING then null;  -- Ignora Check su UNIQUE PK Integrity
            end;
         end if;
      end;
      null;
   end;
   begin  -- Set FUNCTIONAL Integrity
      if functionalNestLevel = 0 then
         IntegrityPackage.NextNestLevel;
         begin  -- Global FUNCTIONAL Integrity at Level 0
            /* NONE */ null;
         end;
        IntegrityPackage.PreviousNestLevel;
      end if;
      IntegrityPackage.NextNestLevel;
      begin  -- Full FUNCTIONAL Integrity at Any Level
   
      if not deleting then  
         :NEW.data_aggiornamento := sysdate;
      end if;
   
      end;
      IntegrityPackage.PreviousNestLevel;
   end;
exception
   when integrity_error then
        IntegrityPackage.InitNestLevel;
        raise_application_error(errno, errmsg);
   when others then
        IntegrityPackage.InitNestLevel;
        raise;
end;
/* End Trigger: SI4_COMPETENZE_TIU */
/

-- Create Custom FUNCTIONAL Integrity Trigger on INSERT or UPDATE or DELETE
create or replace trigger SI4_TIPI_ABILITAZIONE_TIU
   before INSERT or UPDATE or DELETE on SI4_TIPI_ABILITAZIONE
for each row
/******************************************************************************
 NOME:        SI4_TIPI_ABILITAZIONE_TIU
 DESCRIZIONE: Trigger for Check FUNCTIONAL Integrity
                            Set FUNCTIONAL Integrity
                       at INSERT or UPDATE or DELETE on Table SI4_TIPI_ABILITAZIONE
 ECCEZIONI:  -20007, Identificazione CHIAVE presente in TABLE
 ANNOTAZIONI: -  
 REVISIONI:
 Rev. Data       Autore Descrizione
 ---- ---------- ------ ------------------------------------------------------
    0 __/__/____ __     
******************************************************************************/
declare
   functionalNestLevel integer;
   integrity_error  exception;
   errno            integer;
   errmsg           char(200);
   dummy            integer;
   found            boolean;
begin
   functionalNestLevel := IntegrityPackage.GetNestLevel;
   begin  -- Check FUNCTIONAL Integrity
      --  Column "ID_TIPO_ABILITAZIONE" uses sequence TIAB_SQ
      if :NEW.ID_TIPO_ABILITAZIONE IS NULL and not DELETING then
         select TIAB_SQ.NEXTVAL
           into :new.ID_TIPO_ABILITAZIONE
           from dual;
      end if;
      begin  -- Check UNIQUE Integrity on PK of "SI4_TIPI_ABILITAZIONE"
         if IntegrityPackage.GetNestLevel = 0 and not DELETING then
            declare
            cursor cpk_si4_tipi_abilitazione(var_ID_TIPO_ABILITAZIONE number) is
               select 1
                 from   SI4_TIPI_ABILITAZIONE
                where  ID_TIPO_ABILITAZIONE = var_ID_TIPO_ABILITAZIONE;
            mutating         exception;
            PRAGMA exception_init(mutating, -4091);
            begin 
               if :new.ID_TIPO_ABILITAZIONE is not null then
                  open  cpk_si4_tipi_abilitazione(:new.ID_TIPO_ABILITAZIONE);
                  fetch cpk_si4_tipi_abilitazione into dummy;
                  found := cpk_si4_tipi_abilitazione%FOUND;
                  close cpk_si4_tipi_abilitazione;
                  if found then
                     errno  := -20007;
                     errmsg := 'Identificazione "'||
                               :new.ID_TIPO_ABILITAZIONE||
                               '" gia'' presente in Tipi Abilitazione. La registrazione  non puo'' essere inserita.';
                     raise integrity_error;
                  end if;
               end if;
            exception
               when MUTATING then null;  -- Ignora Check su UNIQUE PK Integrity
            end;
         end if;
      end;
      null;
   end;
   begin  -- Set FUNCTIONAL Integrity
      if functionalNestLevel = 0 then
         IntegrityPackage.NextNestLevel;
         begin  -- Global FUNCTIONAL Integrity at Level 0
            /* NONE */ null;
         end;
        IntegrityPackage.PreviousNestLevel;
      end if;
      IntegrityPackage.NextNestLevel;
      begin  -- Full FUNCTIONAL Integrity at Any Level
         /* NONE */ null;
      end;
      IntegrityPackage.PreviousNestLevel;
   end;
exception
   when integrity_error then
        IntegrityPackage.InitNestLevel;
        raise_application_error(errno, errmsg);
   when others then
        IntegrityPackage.InitNestLevel;
        raise;
end;
/* End Trigger: SI4_TIPI_ABILITAZIONE_TIU */
/

-- Create Custom FUNCTIONAL Integrity Trigger on INSERT or UPDATE or DELETE
create or replace trigger SI4_TIPI_OGGETTO_TIU
   before INSERT or UPDATE or DELETE on SI4_TIPI_OGGETTO
for each row
/******************************************************************************
 NOME:        SI4_TIPI_OGGETTO_TIU
 DESCRIZIONE: Trigger for Check FUNCTIONAL Integrity
                            Set FUNCTIONAL Integrity
                       at INSERT or UPDATE or DELETE on Table SI4_TIPI_OGGETTO
 ECCEZIONI:  -20007, Identificazione CHIAVE presente in TABLE
 ANNOTAZIONI: -  
 REVISIONI:
 Rev. Data       Autore Descrizione
 ---- ---------- ------ ------------------------------------------------------
    0 __/__/____ __     
******************************************************************************/
declare
   functionalNestLevel integer;
   integrity_error  exception;
   errno            integer;
   errmsg           char(200);
   dummy            integer;
   found            boolean;
begin
   functionalNestLevel := IntegrityPackage.GetNestLevel;
   begin  -- Check FUNCTIONAL Integrity
      --  Column "ID_TIPO_OGGETTO" uses sequence TIOG_SQ
      if :NEW.ID_TIPO_OGGETTO IS NULL and not DELETING then
         select TIOG_SQ.NEXTVAL
           into :new.ID_TIPO_OGGETTO
           from dual;
      end if;
      begin  -- Check UNIQUE Integrity on PK of "SI4_TIPI_OGGETTO"
         if IntegrityPackage.GetNestLevel = 0 and not DELETING then
            declare
            cursor cpk_si4_tipi_oggetto(var_ID_TIPO_OGGETTO number) is
               select 1
                 from   SI4_TIPI_OGGETTO
                where  ID_TIPO_OGGETTO = var_ID_TIPO_OGGETTO;
            mutating         exception;
            PRAGMA exception_init(mutating, -4091);
            begin 
               if :new.ID_TIPO_OGGETTO is not null then
                  open  cpk_si4_tipi_oggetto(:new.ID_TIPO_OGGETTO);
                  fetch cpk_si4_tipi_oggetto into dummy;
                  found := cpk_si4_tipi_oggetto%FOUND;
                  close cpk_si4_tipi_oggetto;
                  if found then
                     errno  := -20007;
                     errmsg := 'Identificazione "'||
                               :new.ID_TIPO_OGGETTO||
                               '" gia'' presente in Tipi Oggetto. La registrazione  non puo'' essere inserita.';
                     raise integrity_error;
                  end if;
               end if;
            exception
               when MUTATING then null;  -- Ignora Check su UNIQUE PK Integrity
            end;
         end if;
      end;
      null;
   end;
   begin  -- Set FUNCTIONAL Integrity
      if functionalNestLevel = 0 then
         IntegrityPackage.NextNestLevel;
         begin  -- Global FUNCTIONAL Integrity at Level 0
            /* NONE */ null;
         end;
        IntegrityPackage.PreviousNestLevel;
      end if;
      IntegrityPackage.NextNestLevel;
      begin  -- Full FUNCTIONAL Integrity at Any Level
         /* NONE */ null;
      end;
      IntegrityPackage.PreviousNestLevel;
   end;
exception
   when integrity_error then
        IntegrityPackage.InitNestLevel;
        raise_application_error(errno, errmsg);
   when others then
        IntegrityPackage.InitNestLevel;
        raise;
end;
/* End Trigger: SI4_TIPI_OGGETTO_TIU */
/
