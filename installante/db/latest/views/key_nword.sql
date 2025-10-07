--liquibase formatted sql 
--changeset abrandolini:20250326_152401_key_nword stripComments:false runOnChange:true 
 
create or replace force view key_nword as
select TESTO, TRADUZIONE
  from KEY_WORD
 where LINGUA = 'I';
comment on table KEY_NWORD is 'KEWO - Vista dei testi tradotti';

