--liquibase formatted sql 
--changeset abrandolini:20250326_152401_ad4_v_comuni stripComments:false runOnChange:true 
 
CREATE OR REPLACE FORCE VIEW AD4_V_COMUNI AS
SELECT TO_NUMBER (c.provincia_stato || LPAD (c.comune, 4, 0)) id,
        c.comune,
        coalesce (s.stato_territorio, 100) stato,
        CASE WHEN provincia_stato < 200 THEN provincia_stato ELSE NULL END provincia,
        c.denominazione,
        c.cap,
        c.sigla_cfis,
        c.data_soppressione
    FROM AD4_COMUNI c, ad4_stati_territori s
   WHERE s.stato_territorio(+) = c.provincia_stato;
comment on table AD4_V_COMUNI is 'ad4 V comuni';

