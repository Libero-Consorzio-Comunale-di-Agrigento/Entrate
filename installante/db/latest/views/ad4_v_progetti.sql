--liquibase formatted sql 
--changeset abrandolini:20250326_152401_ad4_v_progetti stripComments:false runOnChange:true 
 
CREATE OR REPLACE FORCE VIEW AD4_V_PROGETTI AS
SELECT p.progetto,
        p.descrizione,
        p.priorita,
        p.note
    FROM AD4_PROGETTI p;
comment on table AD4_V_PROGETTI is 'ad4 v progetti';

