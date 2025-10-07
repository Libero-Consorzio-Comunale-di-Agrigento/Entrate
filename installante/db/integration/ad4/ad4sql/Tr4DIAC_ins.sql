--liquibase formatted sql
--changeset dmarotta:20250512_172006_Tr4DIAC_ins stripComments:false
--validCheckSum: 1:any

declare
   d_esiste number;
begin
   begin
      SELECT 1
        INTO d_esiste
        FROM AD4_UTENTI
       WHERE UTENTE = 'TR4ACAMM'
      ;
   exception
      when no_data_found then
         d_esiste := 0;
   end;
   if d_esiste = 0 then
      INSERT INTO AD4_UTENTI (UTENTE, NOMINATIVO, TIPO_UTENTE) 
      VALUES('TR4ACAMM','Gruppo Accesso Amministratori TributiWeb', 'G');
   end if;
end;
/

declare
   d_esiste number;
begin
   begin
      SELECT 1
        INTO d_esiste
        FROM AD4_UTENTI
       WHERE UTENTE = 'TR4ACTRI'
      ;
   exception
      when no_data_found then
         d_esiste := 0;
   end;
   if d_esiste = 0 then
      INSERT INTO AD4_UTENTI (UTENTE, NOMINATIVO, TIPO_UTENTE) 
      VALUES('TR4ACTRI','Gruppo Accesso Uff.Tributi TributiWeb', 'G');
   end if;
end;
/
