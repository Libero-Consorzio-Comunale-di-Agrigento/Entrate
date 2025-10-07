--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_pref_nome_file stripComments:false runOnChange:true
 
create or replace function F_PREF_NOME_FILE
(a_tipo        in varchar2
,a_tipo_export in number)
return varchar2
is
sReturn varchar2(50);
begin
   if a_tipo = 'CODICE BELFIORE' then
      begin
         select comu.SIGLA_CFIS
           into sReturn
           from ad4_comuni comu, dati_generali
          where pro_cliente = provincia_stato
            and com_cliente = comune
         ;
      exception
         when no_data_found then
            sReturn := '';
      end;
   elsif a_tipo = 'NOME_VISTA' then
      begin
         select paex.ultimo_valore
           into sReturn
           from parametri_export paex
          where paex.nome_parametro = 'Nome Vista'
            and paex.tipo_export    = a_tipo_export
         ;
      exception
         when no_data_found then
            sReturn := '';
      end;
   elsif a_tipo = 'TARSU BELFIORE DATA' then
      begin
         select 'TARSU_'||comu.SIGLA_CFIS||'_'||to_char(sysdate,'yyyymmdd')
           into sReturn
           from ad4_comuni comu, dati_generali
          where pro_cliente = provincia_stato
            and com_cliente = comune
         ;
      exception
         when no_data_found then
            sReturn := '';
      end;
   elsif a_tipo = 'ICI BELFIORE DATA' then
      begin
         select 'ICI_'||comu.SIGLA_CFIS||'_'||to_char(sysdate,'yyyymmdd')
           into sReturn
           from ad4_comuni comu, dati_generali
          where pro_cliente = provincia_stato
            and com_cliente = comune
         ;
      exception
         when no_data_found then
            sReturn := '';
      end;
   elsif a_tipo = 'VICI BELFIORE DATA' then
      begin
         select 'VICI_'||comu.SIGLA_CFIS||'_'||to_char(sysdate,'yyyymmdd')
           into sReturn
           from ad4_comuni comu, dati_generali
          where pro_cliente = provincia_stato
            and com_cliente = comune
         ;
      exception
         when no_data_found then
            sReturn := '';
      end;
   elsif a_tipo = 'TIMESTAMP' then
      begin
         select to_char(sysdate,'yyyymmddhh24miss')
           into sReturn
           from dual
         ;
      exception
         when no_data_found then
            sReturn := '';
      end;
   else
      sReturn := '';
   end if;
   return sReturn;
end;
/* End Function: F_PREF_NOME_FILE */
/

