--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_get_nome_file_tras_ruoli stripComments:false runOnChange:true 
 
create or replace function F_GET_NOME_FILE_TRAS_RUOLI
return varchar2
is
  w_cod_ente                            varchar2(5);
  w_anno                                number;
  w_progr_invio                         number;
  w_nome_file                           varchar2(30);
begin
  select min(cod_ente)
    into w_cod_ente
    from tipi_tributo;
--
  if w_cod_ente is null then
     w_nome_file := null;
     return w_nome_file;
  end if;
--
  w_anno := extract (year from sysdate);
  w_progr_invio := f_get_progr_invio_ruoli(w_anno);
  w_progr_invio := w_progr_invio + 1;
  w_nome_file := lpad(w_cod_ente,5,'0')||w_anno||'_'||lpad(w_progr_invio,3,'0')||'.txt';
  return w_nome_file;
end;
/* End Function: F_GET_NOME_FILE_TRAS_RUOLI */
/

