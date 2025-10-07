--liquibase formatted sql 
--changeset abrandolini:20250326_152401_web_anamov stripComments:false runOnChange:true 
 
create or replace force view web_anamov as
select ROWNUM anamov,
       matricola,
       cod_mov,
       cod_eve,
       data_eve,
       cod_pro_eve,
       cod_com_eve,
       anno_pratica,
       pratica,
       to_date(data_reg, 'J') data_reg
  from anaeve;
comment on table WEB_ANAMOV is 'WEB_ANAMOV';

