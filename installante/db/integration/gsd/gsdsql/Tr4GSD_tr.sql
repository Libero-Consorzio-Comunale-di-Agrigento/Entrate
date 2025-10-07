--liquibase formatted sql
--changeset abrandolini:20250514_124500_Tr4GSD_tr_su_GSD stripComments:false context:"TRG2 or TRV2"

-- ============================================================
--   Database name:  TR4
--   DBMS name:      ORACLE Version for SI4
--   Created on:     14/05/2025  12:03
-- ============================================================

-- Trigger ANAANA_TR4_TIU for Check DATA Integrity
--                          Check REFERENTIAL Integrity
--                            Set REFERENTIAL Integrity
--                            Set FUNCTIONAL Integrity
--                       at INSERT or UPDATE on Table ANAANA

create or replace trigger ANAANA_TR4_TIU
before INSERT
    or UPDATE
                  on ANAANA
                  for each row
declare
integrity_error  exception;
   errno            integer;
   errmsg           char(200);
   dummy            integer;
found            boolean;
begin
begin  -- Check DATA Integrity on INSERT or UPDATE
      /* NONE */ null;
end;

begin  -- Check REFERENTIAL Integrity on INSERT or UPDATE
      /*
      if UPDATING then
         ANAANA_TR4_PU(:OLD.MATRICOLA,
                         :NEW.MATRICOLA);
         null;
      end if;
      */
	if INSERTING then
         if IntegrityPackage.GetNestLevel = 0 then
            declare  --  Check UNIQUE PK Integrity per la tabella "ANAANA"
cursor cpk_anaana(var_MATRICOLA number) is
select 1
from   ANAANA
where  MATRICOLA = var_MATRICOLA;
mutating         exception;
            PRAGMA exception_init(mutating, -4091);
begin  -- Check UNIQUE Integrity on PK of "ANAANA"
               if :new.MATRICOLA is not null then
                  open  cpk_anaana(:new.MATRICOLA);
fetch cpk_anaana into dummy;
found := cpk_anaana%FOUND;
close cpk_anaana;
if found then
                     errno  := -20007;
                     errmsg := 'Identificazione "'||
                               :new.MATRICOLA||
                               '" gia'' presente in ANAANA. La registrazione  non puo'' essere inserita.';
                     raise integrity_error;
end if;
end if;
exception
               when MUTATING then null;  -- Ignora Check su UNIQUE PK Integrity
end;
end if;
end if;
end;

begin  -- Set REFERENTIAL Integrity on UPDATE
      if UPDATING then
         IntegrityPackage.NextNestLevel;
         IntegrityPackage.PreviousNestLevel;
end if;
end;

begin  -- Set FUNCTIONAL Integrity on INSERT or UPDATE
      if IntegrityPackage.GetNestLevel = 0 then
         IntegrityPackage.NextNestLevel;
begin  -- Global FUNCTIONAL Integrity at Level 0
            ANAANA_TR4_FI(:old.matricola, :new.matricola,
                          :new.cognome_nome, :new.fascia, :new.stato,
			  :new.data_ult_eve,
                          :new.sesso, :new.cod_prof, :new.pensionato,
			  :new.cod_fam, :new.rapporto_par,
                          :new.sequenza_par, :new.cod_pro_nas,
                          :new.cod_com_nas, :new.data_nas,
			  :new.cod_pro_mor, :new.cod_com_mor,
                          :new.cod_fiscale, :new.data_reg, :new.cf_calcolato);
end;
         if IntegrityPackage.Functional then
begin  -- Switched FUNCTIONAL Integrity at Level 0
               /* NONE */ null;
end;
end if;
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
/* End Trigger: ANAANA_TR4_TIU */
/

-- Tigger ANAANA_TR4_TD for Set FUNCTIONAL Integrity
--                         Check REFERENTIAL Integrity
--                         Set REFERENTIAL Integrity
--                      at DELETE on Table ANAANA

create or replace trigger ANAANA_TR4_TD
before DELETE
on ANAANA
for each row
declare
integrity_error  exception;
   errno            integer;
   errmsg           char(200);
   dummy            integer;
found            boolean;
begin
begin -- Set FUNCTIONAL Integrity on DELETE
      if IntegrityPackage.GetNestLevel = 0 then
         IntegrityPackage.NextNestLevel;
begin  -- Global FUNCTIONAL Integrity at Level 0
            ANAANA_TR4_FI(:old.matricola, :old.matricola,
                          :old.cognome_nome, :old.fascia, :old.stato,
			  :old.data_ult_eve,
                          :old.sesso, :old.cod_prof, :old.pensionato,
			  :old.cod_fam, :old.rapporto_par,
                          :old.sequenza_par, :old.cod_pro_nas,
                          :old.cod_com_nas, :old.data_nas,
			  :old.cod_pro_mor, :old.cod_com_mor,
                          :old.cod_fiscale, :old.data_reg, :old.cf_calcolato);
end;
         IntegrityPackage.PreviousNestLevel;
end if;
end;

begin  -- Check REFERENTIAL Integrity on DELETE
      /*  Procedura non Attivata in assenza di Table CHILD in Delete Restrict
      ANAANA_PD(:OLD.MATRICOLA);
      */  null;
end;

begin  -- Set REFERENTIAL Integrity on DELETE
      IntegrityPackage.NextNestLevel;
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
/* End Trigger: ANAANA_TR4_TD */
/

-- Trigger ANAFAM_TR4_TIU for Check DATA Integrity
--                          Check REFERENTIAL Integrity
--                            Set REFERENTIAL Integrity
--                            Set FUNCTIONAL Integrity
--                       at INSERT or UPDATE on Table ANAFAM

create or replace trigger ANAFAM_TR4_TIU
before INSERT
    or UPDATE
                  on ANAFAM
                  for each row
declare
integrity_error  exception;
   errno            integer;
   errmsg           char(200);
   dummy            integer;
found            boolean;
begin
begin  -- Check DATA Integrity on INSERT or UPDATE
      /* NONE */ null;
end;

begin  -- Check REFERENTIAL Integrity on INSERT or UPDATE
      /*
      if UPDATING then
         ANAFAM_TR4_PU(:OLD.FASCIA,
                       :OLD.COD_FAM,
                         :NEW.FASCIA,
                         :NEW.COD_FAM);
         null;
      end if;
      */
	if INSERTING then
         if IntegrityPackage.GetNestLevel = 0 then
            declare  --  Check UNIQUE PK Integrity per la tabella "ANAFAM"
cursor cpk_anafam(var_FASCIA number,
                              var_COD_FAM number) is
select 1
from   ANAFAM
where  FASCIA = var_FASCIA and
    COD_FAM = var_COD_FAM;
mutating         exception;
            PRAGMA exception_init(mutating, -4091);
begin  -- Check UNIQUE Integrity on PK of "ANAFAM"
               if :new.FASCIA is not null and
                  :new.COD_FAM is not null then
                  open  cpk_anafam(:new.FASCIA,
                                   :new.COD_FAM);
fetch cpk_anafam into dummy;
found := cpk_anafam%FOUND;
close cpk_anafam;
if found then
                     errno  := -20007;
                     errmsg := 'Identificazione "'||
                               :new.FASCIA||' '||
                               :new.COD_FAM||
                               '" gia'' presente in ANAFAM. La registrazione  non puo'' essere inserita.';
                     raise integrity_error;
end if;
end if;
exception
               when MUTATING then null;  -- Ignora Check su UNIQUE PK Integrity
end;
end if;
end if;
end;

begin  -- Set REFERENTIAL Integrity on UPDATE
      if UPDATING then
         IntegrityPackage.NextNestLevel;
         IntegrityPackage.PreviousNestLevel;
end if;
end;

begin  -- Set FUNCTIONAL Integrity on INSERT or UPDATE
      if IntegrityPackage.GetNestLevel = 0 then
         IntegrityPackage.NextNestLevel;
begin  -- Global FUNCTIONAL Integrity at Level 0
            ANAFAM_TR4_FI(:old.cod_fam,:new.cod_fam,:new.fascia,:new.cod_via,:new.num_civ,
                          :new.suffisso,:new.interno,:new.scala,:new.piano,
			  :new.via_aire,:new.cod_pro_aire,
                          :new.cod_com_aire,:new.intestatario,:new.zipcode);
            /* NONE */ null;
end;
         if IntegrityPackage.Functional then
begin  -- Switched FUNCTIONAL Integrity at Level 0
               /* NONE */ null;
end;
end if;
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
/* End Trigger: ANAFAM_TR4_TIU */
/

-- Trigger ARCVIE_TR4_TIU for Check DATA Integrity
--                          Check REFERENTIAL Integrity
--                            Set REFERENTIAL Integrity
--                            Set FUNCTIONAL Integrity
--                       at INSERT or UPDATE on Table ARCVIE

create or replace trigger ARCVIE_TR4_TIU
before INSERT
    or UPDATE
                  on ARCVIE
                  for each row
declare
integrity_error  exception;
   errno            integer;
   errmsg           char(200);
   dummy            integer;
found            boolean;
begin
begin  -- Check DATA Integrity on INSERT or UPDATE
      /* NONE */ null;
end;

begin  -- Check REFERENTIAL Integrity on INSERT or UPDATE
      /*
      if UPDATING then
         ARCVIE_PU(:OLD.COD_VIA,
                         :NEW.COD_VIA);
         null;
      end if;
      */
	if INSERTING then
         if IntegrityPackage.GetNestLevel = 0 then
            declare  --  Check UNIQUE PK Integrity per la tabella "ARCVIE"
cursor cpk_arcvie(var_COD_VIA number) is
select 1
from   ARCVIE
where  COD_VIA = var_COD_VIA;
mutating         exception;
            PRAGMA exception_init(mutating, -4091);
begin  -- Check UNIQUE Integrity on PK of "ARCVIE"
               if :new.COD_VIA is not null then
                  open  cpk_arcvie(:new.COD_VIA);
fetch cpk_arcvie into dummy;
found := cpk_arcvie%FOUND;
close cpk_arcvie;
if found then
                     errno  := -20007;
                     errmsg := 'Identificazione "'||
                               :new.COD_VIA||
                               '" gia'' presente in ARCVIE. La registrazione  non puo'' essere inserita.';
                     raise integrity_error;
end if;
end if;
exception
               when MUTATING then null;  -- Ignora Check su UNIQUE PK Integrity
end;
end if;
end if;
end;

begin  -- Set REFERENTIAL Integrity on UPDATE
      if UPDATING then
         IntegrityPackage.NextNestLevel;
         IntegrityPackage.PreviousNestLevel;
end if;
end;

begin  -- Set FUNCTIONAL Integrity on INSERT or UPDATE
      if IntegrityPackage.GetNestLevel = 0 then
         IntegrityPackage.NextNestLevel;
begin  -- Global FUNCTIONAL Integrity at Level 0
            ARCVIE_TR4_FI(:old.cod_via, :new.cod_via,
                          :new.denom_uff, :new.denom_ric, :new.denom_ord,
			  :new.inizia, :new.termina);
end;
         if IntegrityPackage.Functional then
begin  -- Switched FUNCTIONAL Integrity at Level 0
               /* NONE */ null;
end;
end if;
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
/* End Trigger: ARCVIE_TR4_TIU */
/

-- Tigger ARCVIE_TR4_TD for Set FUNCTIONAL Integrity
--                         Check REFERENTIAL Integrity
--                         Set REFERENTIAL Integrity
--                      at DELETE on Table ARCVIE

create or replace trigger ARCVIE_TR4_TD
before DELETE
on ARCVIE
for each row
declare
integrity_error  exception;
   errno            integer;
   errmsg           char(200);
   dummy            integer;
found            boolean;
begin
begin -- Set FUNCTIONAL Integrity on DELETE
      if IntegrityPackage.GetNestLevel = 0 then
         IntegrityPackage.NextNestLevel;
begin  -- Global FUNCTIONAL Integrity at Level 0
            ARCVIE_TR4_FI(:old.cod_via, :old.cod_via,
                          :old.denom_uff, :old.denom_ric, :old.denom_ord,
			  :old.inizia, :old.termina);
end;
         IntegrityPackage.PreviousNestLevel;
end if;
end;

begin  -- Check REFERENTIAL Integrity on DELETE
      /*  Procedura non Attivata in assenza di Table CHILD in Delete Restrict
      ARCVIE_PD(:OLD.COD_VIA);
      */  null;
end;

begin  -- Set REFERENTIAL Integrity on DELETE
      IntegrityPackage.NextNestLevel;
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
/* End Trigger: ARCVIE_TR4_TD */
/

