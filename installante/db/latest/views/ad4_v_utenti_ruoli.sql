--liquibase formatted sql 
--changeset abrandolini:20250326_152401_ad4_v_utenti_ruoli stripComments:false runOnChange:true 
 
CREATE OR REPLACE FORCE VIEW AD4_V_UTENTI_RUOLI AS
SELECT utente, modulo||'_'||ruolo ruolo, istanza
    FROM AD4_DIRITTI_ACCESSO where istanza = '${istanza}';
comment on table AD4_V_UTENTI_RUOLI is 'ad4 v utenti ruoli';

