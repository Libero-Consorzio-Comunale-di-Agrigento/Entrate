--liquibase formatted sql 
--changeset abrandolini:20250326_152401_ad4_v_utenti stripComments:false runOnChange:true 
 
CREATE OR REPLACE FORCE VIEW AD4_V_UTENTI AS
SELECT u.utente,
          u.nominativo,
          u.password,
          cast(DECODE (u.stato, 'U', 'Y', 'N') as char(1)) enabled,
          cast(DECODE (u.stato, 'U', 'N', 'Y') as char(1)) account_expired,
          cast(DECODE (u.stato, 'U', 'N', 'Y') as char(1)) account_locked,
          cast(DECODE (u.pwd_da_modificare, 'NO', 'N', 'Y') as char(1)) password_expired,
          u.tipo_utente,
          AD4_SOGGETTO.GET_DENOMINAZIONE (AD4_UTENTE.GET_SOGGETTO (u.utente, 'N', 0))
             nominativo_soggetto,
          cast(DECODE (AD4_UTENTE.GET_SOGGETTO (u.utente, 'N', 0), NULL, 'N', 'Y') as char(1))
             esiste_soggetto
     FROM AD4_UTENTI u;
comment on table AD4_V_UTENTI is 'ad4 v utenti';

