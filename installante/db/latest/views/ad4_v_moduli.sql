--liquibase formatted sql 
--changeset abrandolini:20250326_152401_ad4_v_moduli stripComments:false runOnChange:true 
 
CREATE OR REPLACE FORCE VIEW AD4_V_MODULI AS
SELECT modulo, descrizione, progetto, note
    FROM AD4_MODULI;
comment on table AD4_V_MODULI is 'ad4 v moduli';

