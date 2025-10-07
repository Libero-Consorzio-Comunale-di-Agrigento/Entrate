--liquibase formatted sql 
--changeset abrandolini:20250326_152401_ad4_v_province stripComments:false runOnChange:true 
 
CREATE OR REPLACE FORCE VIEW AD4_V_PROVINCE AS
SELECT PROVINCIA,
        DENOMINAZIONE,
        DENOMINAZIONE_AL1,
        DENOMINAZIONE_AL2,
        REGIONE,
        SIGLA,
        UTENTE_AGGIORNAMENTO,
        DATA_AGGIORNAMENTO
    FROM AD4_PROVINCE;
comment on table AD4_V_PROVINCE is 'ad4 v province';

