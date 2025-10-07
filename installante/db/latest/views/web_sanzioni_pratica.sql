--liquibase formatted sql 
--changeset abrandolini:20250326_152401_web_sanzioni_pratica stripComments:false runOnChange:true 
 
create or replace force view web_sanzioni_pratica as
select sapr.*, sapr.SEQUENZA_SANZ seq_sanz from SANZIONI_PRATICA sapr;
comment on table WEB_SANZIONI_PRATICA is 'web sanzioni pratica';
