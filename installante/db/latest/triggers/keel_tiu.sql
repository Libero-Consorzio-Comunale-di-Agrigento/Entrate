--liquibase formatted sql
--changeset dmarotta:20250508_152812_keel_tiu stripComments:false runOnChange:true endDelimiter:/

/*==============================================================*/
/* Valorizza colonna error_id di KEY_ERROR_LOG se nulla.        */
/*==============================================================*/
declare
   d_id number := 0;
begin
   select count(1)
     into d_id
     from KEY_ERROR_LOG
    where error_id is null
   ;
   if d_id > 0 then
      d_id := 0;
      for c_keel in (select rowid
                       from KEY_ERROR_LOG)
      loop
         d_id := d_id + 1;
         update KEY_ERROR_LOG
            set error_id = d_id
          where rowid = c_keel.rowid
         ;
      end loop;
      commit;
   end if;
end;
/

/*==============================================================*/
/* Introdotto in Versione 2009.11                               */
/* Problema BO21721:                                            */
/* Errore in numerazione in caso di installazione DB su CLUSTER */
/*==============================================================*/
alter sequence keel_sq nocache
/

CREATE OR REPLACE TRIGGER KEY_ERROR_LOG_TIU
   before INSERT or UPDATE on KEY_ERROR_LOG
for each row
/******************************************************************************
 NOME:        KEY_ERROR_LOG_TIU
 DESCRIZIONE: Trigger for Set DATA Integrity
                          Set FUNCTIONAL Integrity
                       on Table KEY_ERROR_LOG
 REVISIONI:
 Rev. Data       Autore Descrizione
 ---- ---------- ------ ------------------------------------------------------
    0 30/01/2004 MM     Creazione.
    1 21/04/2006 MM     Recupero dell'id da associare al record tramite sequence
                        KEEL_SQ invece che tramite si4.next_id.
******************************************************************************/
declare
   integrity_error  exception;
   errno            integer;
   errmsg           char(200);
   found            boolean;
begin
   begin  -- Set DATA Integrity
      /* NONE */ null;
   end;
  begin  -- Set FUNCTIONAL Integrity
      if IntegrityPackage.GetNestLevel = 0 then
         IntegrityPackage.NextNestLevel;
         begin  -- Global FUNCTIONAL Integrity at Level 0
            /* NONE */ null;
         end;
         IntegrityPackage.PreviousNestLevel;
      end if;
      IntegrityPackage.NextNestLevel;
      begin  -- Full FUNCTIONAL Integrity at Any Level
         if :NEW.ERROR_ID IS NULL THEN
            select keel_sq.nextval
              into :NEW.ERROR_ID
              from dual;
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
/* End Trigger: KEY_ERROR_LOG_TIU */
/
