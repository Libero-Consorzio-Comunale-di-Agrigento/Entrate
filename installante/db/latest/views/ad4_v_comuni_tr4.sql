--liquibase formatted sql 
--changeset abrandolini:20250326_152401_ad4_v_comuni_tr4 stripComments:false runOnChange:true 
 
CREATE OR REPLACE FORCE VIEW AD4_V_COMUNI_TR4 AS
SELECT TO_NUMBER (c.provincia_stato || LPAD (c.comune, 4, 0)) id_COMUNE,
        c.comune,
      c.provincia_stato
    FROM AD4_COMUNI c
union
select null, cod_com_res, cod_pro_res from soggetti
where not exists (select 1 from ad4_comuni co
where co.comune = cod_com_res
and co.provincia_stato = cod_pro_res)
and cod_com_res is not null
and cod_pro_res is not null
union
select null, cod_com_nas, cod_pro_nas from soggetti
where not exists (select 1 from ad4_comuni co
where co.comune = cod_com_nas
and co.provincia_stato = cod_pro_nas)
and cod_com_nas is not null
and cod_pro_nas is not null
union
select null, cod_com_eve, cod_pro_eve from soggetti
where not exists (select 1 from ad4_comuni co
where co.comune = cod_com_eve
and co.provincia_stato = cod_pro_eve)
and cod_com_eve is not null
and cod_pro_eve is not null
union
select null, cod_com_rap, cod_pro_rap from soggetti
where not exists (select 1 from ad4_comuni co
where co.comune = cod_com_rap
and co.provincia_stato = cod_pro_rap)
and cod_com_rap is not null
and cod_pro_rap is not null;
comment on table AD4_V_COMUNI_TR4 is 'Ad4 v comuni tr4';

