--liquibase formatted sql 
--changeset abrandolini:20250326_152401_ad4_v_regioni stripComments:false runOnChange:true 
 
CREATE OR REPLACE FORCE VIEW AD4_V_REGIONI AS
SELECT REGIONE,
        DENOMINAZIONE,
        DENOMINAZIONE_AL1,
        DENOMINAZIONE_AL2,
        ID_REGIONE,
        UTENTE_AGGIORNAMENTO,
        DATA_AGGIORNAMENTO
    FROM AD4_REGIONI;
comment on table AD4_V_REGIONI is 'ad4 v regioni';

