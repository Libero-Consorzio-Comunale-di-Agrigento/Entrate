--liquibase formatted sql 
--changeset abrandolini:20250326_152401_si4_competenza_oggetti stripComments:false runOnChange:true 
 
create or replace force view si4_competenza_oggetti as
select
   COMP.ID_COMPETENZA,
   ABIL.ID_TIPO_OGGETTO,
   COMP.OGGETTO,
   COMP.UTENTE,
   COMP.ACCESSO,
   UTEN.NOMINATIVO NOMINATIVO_UTENTE,
   ABIL.ID_TIPO_ABILITAZIONE,
   COMP.DAL,
   COMP.AL
from
   SI4_COMPETENZE COMP,
   SI4_ABILITAZIONI ABIL,
   AD4_UTENTI UTEN
where
   COMP.ID_ABILITAZIONE = ABIL.ID_ABILITAZIONE
   and COMP.UTENTE = UTEN.UTENTE;

