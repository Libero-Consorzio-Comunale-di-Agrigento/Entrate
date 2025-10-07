--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_web_sostituzione_oggetto stripComments:false runOnChange:true 
 
create or replace function F_WEB_SOSTITUZIONE_OGGETTO
          (a_cod_fiscale     varchar2,
           a_tipo_tributo    varchar2,
           a_attuale_oggetto number,
           a_nuovo_oggetto   number)
           RETURN VARCHAR2
IS
  w_messaggio VARCHAR2 (4000);
begin
 sostituzione_oggetto(a_cod_fiscale, a_tipo_tributo, a_attuale_oggetto, a_nuovo_oggetto);
  w_messaggio:= null;
  return w_messaggio;
exception
  when others then
  w_messaggio := sqlerrm;
  return w_messaggio;
end;
/* End Function: F_WEB_SOSTITUZIONE_OGGETTO */
/

