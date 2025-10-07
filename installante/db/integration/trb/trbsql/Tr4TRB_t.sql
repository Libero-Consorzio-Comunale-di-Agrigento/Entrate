--liquibase formatted sql
--changeset abrandolini:20250331_125538_Tr4TRB_t stripComments:false context:"TRT2 or TRV2"
--validCheckSum: 1:any

-- ============================================================
--   Database name:  TR4_TRB
--   DBMS name:      ORACLE Version for SI4
--   Created on:     10/01/2008  17.12
-- ============================================================

-- WHEN ERROR IGNORE 24344

/*	DATA: 23/03/1999	*/

create or replace procedure ANANRE_TR4_FI
(a_matricola_old		IN 	number,
 a_matricola_new		IN	number,
 a_cognome_nome             	IN	varchar2,
 a_denominazione_via        	IN	varchar2,
 a_num_civ                  	IN	number,
 a_suffisso                 	IN	varchar2,
 a_interno                  	IN	number,
 a_provincia                	IN	number,
 a_comune                  	IN	number,
 a_cap				IN	number,
 a_cod_prof			IN	number,
 a_sesso                    	IN	varchar2,
 a_data_nascita             	IN	number,
 a_provincia_nascita        	IN	number,
 a_comune_nascita           	IN	number,
 a_tipo                     	IN	varchar2,
 a_data_ult_agg             	IN	number,
 a_cod_fiscale              	IN	varchar2,
 a_partita_iva              	IN	varchar2,
 a_cod_fam			IN	number,
 a_rappresentante           	IN	varchar2,
 a_indir_rappr          	IN	varchar2,
 a_cod_pro_rappr            	IN	number,
 a_cod_com_rappr            	IN	number,
 a_carica                  	IN	varchar2,
 a_cod_fiscale_rappr        	IN	varchar2,
 a_note_1                   	IN	varchar2,
 a_note_2                   	IN	varchar2,
 a_note_3                   	IN	varchar2,
 a_esenzione               	IN	varchar2,
 a_gruppo_utente            	IN	varchar2,
 a_cf_calcolato            	IN	varchar2)
IS
w_controllo		varchar2(1);
w_tipo_carica		number(4);
w_errore		varchar2(2000);
errore			exception;

CURSOR sel_tica (des_tipo_carica varchar2) IS
       select tipo_carica
    	 from tipi_carica
        where descrizione = des_tipo_carica
       ;
BEGIN
 IF Tr4_IntegrityPackage.GetNestLevel = 0 THEN
  IF INSERTING THEN
     BEGIN
       select 'x'
         into w_controllo
         from soggetti sogg
        where sogg.tipo_residente = 1
          and sogg.matricola	  = a_matricola_new
       ;
     EXCEPTION
       WHEN no_data_found THEN
	    OPEN sel_tica (a_carica);
	    FETCH sel_tica INTO w_tipo_carica;
            BEGIN
              insert into soggetti
		     (tipo_residente,matricola,cod_fiscale,
		      cognome_nome,sesso,cod_fam,
		      data_nas,cod_pro_nas,cod_com_nas,
		      cod_pro_res,cod_com_res,cap,cod_prof,
		      denominazione_via,num_civ,suffisso,interno,
		      partita_iva,rappresentante,
		      indirizzo_rap,cod_pro_rap,cod_com_rap,
		      cod_fiscale_rap,tipo_carica,
		      flag_esenzione,tipo,gruppo_utente,
		      flag_cf_calcolato,
                      utente,note)
              values (1,a_matricola_new,a_cod_fiscale,
 	              a_cognome_nome,a_sesso,a_cod_fam,
		      to_date(a_data_nascita,'j'),
		      a_provincia_nascita,a_comune_nascita,
	              a_provincia,a_comune,a_cap,a_cod_prof,
	              a_denominazione_via,a_num_civ,
		      a_suffisso,a_interno,
	              a_partita_iva,a_rappresentante,
	              a_indir_rappr,
		      a_cod_pro_rappr,a_cod_com_rappr,
		      a_cod_fiscale_rappr,w_tipo_carica,
		      a_esenzione,a_tipo,a_gruppo_utente,
	              a_cf_calcolato,
                      'TRB',
	              a_note_1||' '||a_note_2||' '||a_note_3)
	      ;
            EXCEPTION
              WHEN others THEN
	           CLOSE sel_tica;
	           w_errore := 'Errore in inserimento Soggetti '||
		               '('||SQLERRM||')';
                   RAISE errore;
            END;
	    CLOSE sel_tica;
     END;
  ELSIF UPDATING THEN
     OPEN sel_tica (a_carica);
     FETCH sel_tica INTO w_tipo_carica;
     BEGIN
       update soggetti
          set matricola		= a_matricola_new,
              cod_fiscale	= a_cod_fiscale,
              cognome_nome	= a_cognome_nome||substr(cognome_nome,41),
              sesso		= a_sesso,
              cod_fam		= a_cod_fam,
              data_nas		= to_date(a_data_nascita,'j'),
              cod_pro_nas	= a_provincia_nascita,
              cod_com_nas	= a_comune_nascita,
              cod_pro_res	= a_provincia,
              cod_com_res	= a_comune,
	      cap		= a_cap,
	      cod_prof		= a_cod_prof,
              denominazione_via	= a_denominazione_via,
              num_civ		= a_num_civ,
              suffisso		= a_suffisso,
              interno		= a_interno,
              partita_iva	= a_partita_iva,
              rappresentante	= a_rappresentante,
              indirizzo_rap	= a_indir_rappr,
              cod_pro_rap	= a_cod_pro_rappr,
              cod_com_rap	= a_cod_com_rappr,
              cod_fiscale_rap	= a_cod_fiscale_rappr,
              tipo_carica	= w_tipo_carica,
              flag_esenzione	= a_esenzione,
              tipo		= a_tipo,
              gruppo_utente	= a_gruppo_utente,
              flag_cf_calcolato	= a_cf_calcolato,
              utente		= 'TRB',
              note 		= a_note_1||' '||
				  a_note_2||' '||
 				  a_note_3
        where tipo_residente	= 1
          and matricola		= a_matricola_old
       ;
       IF SQL%NOTFOUND THEN
	  w_errore := 'Identificazione '||a_matricola_old||
		      ' non presente in archivio Soggetti';
	  RAISE errore;
       END IF;
     EXCEPTION
       WHEN others THEN
            CLOSE sel_tica;
            w_errore := 'Errore in aggiornamento Anagrafe Non Residenti '||
		        '('||SQLERRM||')';
            RAISE errore;
     END;
     CLOSE sel_tica;
  ELSIF DELETING THEN
     BEGIN
       delete soggetti
        where tipo_residente	= 1
          and matricola = a_matricola_old
       ;
     EXCEPTION
       WHEN others THEN
            w_errore := 'Errore in cancellazione Soggetti '||
	                '('||SQLERRM||')';
            RAISE errore;
     END;
  END IF;
 END IF;

EXCEPTION
  WHEN errore THEN
       RAISE_APPLICATION_ERROR
	 (-20999,w_errore);
  WHEN others THEN
       RAISE_APPLICATION_ERROR
	 (-20999,SQLERRM);
END;
/* End Procedure: ANANRE_TR4_FI */
/

-- Procedure ANANRE_TR4_PU for Check REFERENTIAL Integrity
--                      at UPDATE on Table ANANRE

create or replace procedure ANANRE_TR4_PU
(old_matricola IN number,
 new_matricola IN number)
is
   integrity_error  exception;
   errno            integer;
   errmsg           char(200);
   dummy            integer;
   found            boolean;
   seq              number;
   mutating         exception;
   PRAGMA exception_init(mutating, -4091);

   --  Declaration of UpdateParentRestrict constraint for "USYS_ANANRE"
   cursor cfk1_ananre(var_matricola number) is
      select 1
      from   USYS_ANANRE
      where  MATRICOLA = var_matricola
       and   var_matricola is not null;

   --  Declaration of UpdateParentRestrict constraint for "ICI_ANANRE"
   cursor cfk2_ananre(var_matricola number) is
      select 1
      from   ICI_ANANRE
      where  MATRICOLA = var_matricola
       and   var_matricola is not null;

   --  Declaration of UpdateParentRestrict constraint for "GRE_ANANRE"
   cursor cfk3_ananre(var_matricola number) is
      select 1
      from   GRE_ANANRE
      where  MATRICOLA = var_matricola
       and   var_matricola is not null;

   --  Declaration of UpdateParentRestrict constraint for "GAC_ANANRE"
   cursor cfk4_ananre(var_matricola number) is
      select 1
      from   GAC_ANANRE
      where  MATRICOLA = var_matricola
       and   var_matricola is not null;

   --  Declaration of UpdateParentRestrict constraint for "ICP_ANANRE"
   cursor cfk5_ananre(var_matricola number) is
      select 1
      from   ICP_ANANRE
      where  MATRICOLA = var_matricola
       and   var_matricola is not null;

   --  Declaration of UpdateParentRestrict constraint for "LVT_ANANRE"
   cursor cfk6_ananre(var_matricola number) is
      select 1
      from   LVT_ANANRE
      where  MATRICOLA = var_matricola
       and   var_matricola is not null;

   --  Declaration of UpdateParentRestrict constraint for "TRB_ANANRE"
   cursor cfk7_ananre(var_matricola number) is
      select 1
      from   TRB_ANANRE
      where  MATRICOLA = var_matricola
       and   var_matricola is not null;
begin
   begin  -- Check REFERENTIAL Integrity

      seq := IntegrityPackage.GetNestLevel;

      --  Chiave di "ANANRE" non modificabile se esistono referenze su "USYS_ANANRE"
      if (OLD_MATRICOLA != NEW_MATRICOLA) then
         open  cfk1_ananre(OLD_MATRICOLA);
         fetch cfk1_ananre into dummy;
         found := cfk1_ananre%FOUND;
         close cfk1_ananre;
         if found then
            errno  := -20005;
            errmsg := 'Esistono riferimenti su USYS_ANANRE. La registrazione di ANANRE non e'' modificabile.';
            raise integrity_error;
         end if;
      end if;

      --  Chiave di "ANANRE" non modificabile se esistono referenze su "ICI_ANANRE"
      if (OLD_MATRICOLA != NEW_MATRICOLA) then
         open  cfk2_ananre(OLD_MATRICOLA);
         fetch cfk2_ananre into dummy;
         found := cfk2_ananre%FOUND;
         close cfk2_ananre;
         if found then
            errno  := -20005;
            errmsg := 'Esistono riferimenti su ICI_ANANRE. La registrazione di ANANRE non e'' modificabile.';
            raise integrity_error;
         end if;
      end if;

      --  Chiave di "ANANRE" non modificabile se esistono referenze su "GRE_ANANRE"
      if (OLD_MATRICOLA != NEW_MATRICOLA) then
         open  cfk3_ananre(OLD_MATRICOLA);
         fetch cfk3_ananre into dummy;
         found := cfk3_ananre%FOUND;
         close cfk3_ananre;
         if found then
            errno  := -20005;
            errmsg := 'Esistono riferimenti su GRE_ANANRE. La registrazione di ANANRE non e'' modificabile.';
            raise integrity_error;
         end if;
      end if;

      --  Chiave di "ANANRE" non modificabile se esistono referenze su "GAC_ANANRE"
      if (OLD_MATRICOLA != NEW_MATRICOLA) then
         open  cfk4_ananre(OLD_MATRICOLA);
         fetch cfk4_ananre into dummy;
         found := cfk4_ananre%FOUND;
         close cfk4_ananre;
         if found then
            errno  := -20005;
            errmsg := 'Esistono riferimenti su GAC_ANANRE. La registrazione di ANANRE non e'' modificabile.';
            raise integrity_error;
         end if;
      end if;

      --  Chiave di "ANANRE" non modificabile se esistono referenze su "ICP_ANANRE"
      if (OLD_MATRICOLA != NEW_MATRICOLA) then
         open  cfk5_ananre(OLD_MATRICOLA);
         fetch cfk5_ananre into dummy;
         found := cfk5_ananre%FOUND;
         close cfk5_ananre;
         if found then
            errno  := -20005;
            errmsg := 'Esistono riferimenti su ICP_ANANRE. La registrazione di ANANRE non e'' modificabile.';
            raise integrity_error;
         end if;
      end if;

      --  Chiave di "ANANRE" non modificabile se esistono referenze su "LVT_ANANRE"
      if (OLD_MATRICOLA != NEW_MATRICOLA) then
         open  cfk6_ananre(OLD_MATRICOLA);
         fetch cfk6_ananre into dummy;
         found := cfk6_ananre%FOUND;
         close cfk6_ananre;
         if found then
            errno  := -20005;
            errmsg := 'Esistono riferimenti su LVT_ANANRE. La registrazione di ANANRE non e'' modificabile.';
            raise integrity_error;
         end if;
      end if;

      --  Chiave di "ANANRE" non modificabile se esistono referenze su "TRB_ANANRE"
      if (OLD_MATRICOLA != NEW_MATRICOLA) then
         open  cfk7_ananre(OLD_MATRICOLA);
         fetch cfk7_ananre into dummy;
         found := cfk7_ananre%FOUND;
         close cfk7_ananre;
         if found then
            errno  := -20005;
            errmsg := 'Esistono riferimenti su TRB_ANANRE. La registrazione di ANANRE non e'' modificabile.';
            raise integrity_error;
         end if;
      end if;
      null;
   end;
exception
   when integrity_error then
        IntegrityPackage.InitNestLevel;
        raise_application_error(errno, errmsg);
   when others then
        IntegrityPackage.InitNestLevel;
        raise;
end;
/* End Procedure: ANANRE_TR4_PU */
/

-- Trigger ANANRE_TR4_TIU for Check DATA Integrity
--                          Check REFERENTIAL Integrity
--                            Set REFERENTIAL Integrity
--                            Set FUNCTIONAL Integrity
--                       at INSERT or UPDATE on Table ANANRE

create or replace trigger ANANRE_TR4_TIU
before INSERT
    or UPDATE
on ANANRE
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
         ANANRE_TR4_PU(:OLD.MATRICOLA,
                             :NEW.MATRICOLA);
         null;
      end if;
      */
        if INSERTING then
         if IntegrityPackage.GetNestLevel = 0 then
            declare  --  Check UNIQUE PK Integrity per la tabella "ANANRE"
            cursor cpk_ananre(var_MATRICOLA number) is
               select 1
                 from   ANANRE
                where  MATRICOLA = var_MATRICOLA;
            mutating         exception;
            PRAGMA exception_init(mutating, -4091);
            begin  -- Check UNIQUE Integrity on PK of "ANANRE"
               if :new.MATRICOLA is not null then
                  open  cpk_ananre(:new.MATRICOLA);
                  fetch cpk_ananre into dummy;
                  found := cpk_ananre%FOUND;
                  close cpk_ananre;
                  if found then
                     errno  := -20007;
                     errmsg := 'Identificazione "'||
                               :new.MATRICOLA||
                               '" gia'' presente in ANANRE. La registrazione  non puo'' essere inserita.';
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
           ANANRE_TR4_FI(:old.matricola, :new.matricola,
                         :new.cognome_nome, :new.denominazione_via,
                         :new.num_civ, :new.suffisso, :new.interno,
			 :new.provincia, :new.comune, :new.cap,
			 :new.cod_prof, :new.sesso,
                         :new.data_nascita, :new.provincia_nascita, :new.comune_nascita,
                         :new.tipo, :new.data_ult_agg, :new.cod_fiscale, :new.partita_iva,
                         :new.cod_fam, :new.rappresentante, :new.indir_rappr,
			 :new.cod_pro_rappr, :new.cod_com_rappr,
			 :new.carica, :new.cod_fiscale_rappr,
			 :new.note_1, :new.note_2, :new.note_3,
			 :new.esenzione, :new.gruppo_utente, :new.cf_calcolato);
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
/* End Trigger: ANANRE_TR4_TIU */
/

-- Procedure ANANRE_TR4_PD for Check REFERENTIAL Integrity
--                      at DELETE on Table ANANRE

create or replace procedure ANANRE_TR4_PD
(old_matricola IN number)
is
   integrity_error  exception;
   errno            integer;
   errmsg           char(200);
   dummy            integer;
   found            boolean;

   --  Declaration of DeleteParentRestrict constraint for "USYS_ANANRE"
   cursor cfk1_ananre(var_matricola number) is
      select 1
      from   USYS_ANANRE
      where  MATRICOLA = var_matricola
       and   var_matricola is not null;

   --  Declaration of DeleteParentRestrict constraint for "ICI_ANANRE"
   cursor cfk2_ananre(var_matricola number) is
      select 1
      from   ICI_ANANRE
      where  MATRICOLA = var_matricola
       and   var_matricola is not null;

   --  Declaration of DeleteParentRestrict constraint for "GRE_ANANRE"
   cursor cfk3_ananre(var_matricola number) is
      select 1
      from   GRE_ANANRE
      where  MATRICOLA = var_matricola
       and   var_matricola is not null;

   --  Declaration of DeleteParentRestrict constraint for "GAC_ANANRE"
   cursor cfk4_ananre(var_matricola number) is
      select 1
      from   GAC_ANANRE
      where  MATRICOLA = var_matricola
       and   var_matricola is not null;

   --  Declaration of DeleteParentRestrict constraint for "ICP_ANANRE"
   cursor cfk5_ananre(var_matricola number) is
      select 1
      from   ICP_ANANRE
      where  MATRICOLA = var_matricola
       and   var_matricola is not null;

   --  Declaration of DeleteParentRestrict constraint for "LVT_ANANRE"
   cursor cfk6_ananre(var_matricola number) is
      select 1
      from   LVT_ANANRE
      where  MATRICOLA = var_matricola
       and   var_matricola is not null;

   --  Declaration of DeleteParentRestrict constraint for "TRB_ANANRE"
   cursor cfk7_ananre(var_matricola number) is
      select 1
      from   TRB_ANANRE
      where  MATRICOLA = var_matricola
       and   var_matricola is not null;
begin
   begin  -- Check REFERENTIAL Integrity

      --  Cannot delete parent "ANANRE" if children still exist in "USYS_ANANRE"
      open  cfk1_ananre(OLD_MATRICOLA);
      fetch cfk1_ananre into dummy;
      found := cfk1_ananre%FOUND;
      close cfk1_ananre;
      if found then
         errno  := -20006;
         errmsg := 'Esistono riferimenti su USYS_ANANRE. La registrazione di ANANRE non e'' eliminabile.';
         raise integrity_error;
      end if;

      --  Cannot delete parent "ANANRE" if children still exist in "ICI_ANANRE"
      open  cfk2_ananre(OLD_MATRICOLA);
      fetch cfk2_ananre into dummy;
      found := cfk2_ananre%FOUND;
      close cfk2_ananre;
      if found then
         errno  := -20006;
         errmsg := 'Esistono riferimenti su ICI_ANANRE. La registrazione di ANANRE non e'' eliminabile.';
         raise integrity_error;
      end if;

      --  Cannot delete parent "ANANRE" if children still exist in "GRE_ANANRE"
      open  cfk3_ananre(OLD_MATRICOLA);
      fetch cfk3_ananre into dummy;
      found := cfk3_ananre%FOUND;
      close cfk3_ananre;
      if found then
         errno  := -20006;
         errmsg := 'Esistono riferimenti su GRE_ANANRE. La registrazione di ANANRE non e'' eliminabile.';
         raise integrity_error;
      end if;

      --  Cannot delete parent "ANANRE" if children still exist in "GAC_ANANRE"
      open  cfk4_ananre(OLD_MATRICOLA);
      fetch cfk4_ananre into dummy;
      found := cfk4_ananre%FOUND;
      close cfk4_ananre;
      if found then
         errno  := -20006;
         errmsg := 'Esistono riferimenti su GAC_ANANRE. La registrazione di ANANRE non e'' eliminabile.';
         raise integrity_error;
      end if;

      --  Cannot delete parent "ANANRE" if children still exist in "ICP_ANANRE"
      open  cfk5_ananre(OLD_MATRICOLA);
      fetch cfk5_ananre into dummy;
      found := cfk5_ananre%FOUND;
      close cfk5_ananre;
      if found then
         errno  := -20006;
         errmsg := 'Esistono riferimenti su ICP_ANANRE. La registrazione di ANANRE non e'' eliminabile.';
         raise integrity_error;
      end if;

      --  Cannot delete parent "ANANRE" if children still exist in "LVT_ANANRE"
      open  cfk6_ananre(OLD_MATRICOLA);
      fetch cfk6_ananre into dummy;
      found := cfk6_ananre%FOUND;
      close cfk6_ananre;
      if found then
         errno  := -20006;
         errmsg := 'Esistono riferimenti su LVT_ANANRE. La registrazione di ANANRE non e'' eliminabile.';
         raise integrity_error;
      end if;

      --  Cannot delete parent "ANANRE" if children still exist in "TRB_ANANRE"
      open  cfk7_ananre(OLD_MATRICOLA);
      fetch cfk7_ananre into dummy;
      found := cfk7_ananre%FOUND;
      close cfk7_ananre;
      if found then
         errno  := -20006;
         errmsg := 'Esistono riferimenti su TRB_ANANRE. La registrazione di ANANRE non e'' eliminabile.';
         raise integrity_error;
      end if;
      null;
   end;
exception
   when integrity_error then
        IntegrityPackage.InitNestLevel;
        raise_application_error(errno, errmsg);
   when others then
        IntegrityPackage.InitNestLevel;
        raise;
end;
/* End Procedure: ANANRE_TR4_PD */
/

-- Tigger ANANRE_TR4_TD for Set FUNCTIONAL Integrity
--                         Check REFERENTIAL Integrity
--                         Set REFERENTIAL Integrity
--                      at DELETE on Table ANANRE

create or replace trigger ANANRE_TR4_TD
before DELETE
on ANANRE
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
           ANANRE_TR4_FI(:old.matricola, :new.matricola,
                         :new.cognome_nome, :new.denominazione_via,
                         :new.num_civ, :new.suffisso, :new.interno,
			 :new.provincia, :new.comune, :new.cap,
			 :new.cod_prof, :new.sesso,
                         :new.data_nascita, :new.provincia_nascita, :new.comune_nascita,
                         :new.tipo, :new.data_ult_agg, :new.cod_fiscale, :new.partita_iva,
                         :new.cod_fam, :new.rappresentante, :new.indir_rappr,
			 :new.cod_pro_rappr, :new.cod_com_rappr,
			 :new.carica, :new.cod_fiscale_rappr,
			 :new.note_1, :new.note_2, :new.note_3,
			 :new.esenzione, :new.gruppo_utente, :new.cf_calcolato);
         end;
         IntegrityPackage.PreviousNestLevel;
      end if;
   end;

   begin  -- Check REFERENTIAL Integrity on DELETE

      -- Child Restrict Table: USYS_ANANRE

      -- Child Restrict Table: ICI_ANANRE

      -- Child Restrict Table: GRE_ANANRE

      -- Child Restrict Table: GAC_ANANRE

      -- Child Restrict Table: ICP_ANANRE

      -- Child Restrict Table: LVT_ANANRE

      -- Child Restrict Table: TRB_ANANRE

      ANANRE_TR4_PD(:OLD.MATRICOLA);

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
/* End Trigger: ANANRE_TR4_TD */
/
