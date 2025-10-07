--liquibase formatted sql 
--changeset abrandolini:20250326_152401_ad4_v_ruoli stripComments:false runOnChange:true 
 
CREATE OR REPLACE FORCE VIEW AD4_V_RUOLI AS
SELECT ruolo, descrizione, modulo, progetto, CAST(decode(gruppo_lavoro,'S', decode(gruppo_so, 'S', 'Y', 'N'),'N') as CHAR(1)) ruolo_applicativo
     FROM AD4_RUOLI
    UNION
   SELECT da.modulo||'_'||r.ruolo ruolo, r.descrizione, r.modulo, r.progetto, 'N' ruolo_applicativo
     FROM ad4_diritti_accesso da, AD4_RUOLI r
    WHERE da.ruolo = r.ruolo;
comment on table AD4_V_RUOLI is 'ad4 v ruoli';

