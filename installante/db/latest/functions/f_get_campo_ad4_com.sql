--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_get_campo_ad4_com stripComments:false runOnChange:true 
 
create or replace function F_GET_CAMPO_AD4_COM
    (a_cod_provincia    number
    ,a_cod_comune       number
    ,a_descrizione      varchar2
    ,a_flag_italiano    varchar2
    ,a_flag_estero      varchar2
    ,a_flag_attivo      varchar2
    ,a_data_rif_j       number
    ,a_campo            varchar2)
RETURN varchar
IS
w_sigla             varchar2(255);
w_descrizione        varchar2(255);
w_sigla_provincia        varchar2(255);
w_campo            varchar2(255);
w_errore            varchar2(255);
errore            exception;
begin
--
-- campi gestiti:
-- . 'CODICE_COMUNE'
-- . 'COD_PROVINCIA'
-- . 'COD_COMUNE'
-- . 'DESCRIZIONE'
-- . 'SIGLA_PROVINCIA'
-- . 'CAP'
-- . 'TRIBNALE'
-- . 'CODICE_CATASTO'
-- . 'CODICE_CONSOLATO'
-- . 'COD_CONSOLATO'
-- . 'TIPO_CONSOLATO'
-- . 'CEE'
-- . 'COD_TERRITORIO'
-- . 'DATA_SOPPRESSIONE'
-- . 'CODICE_COMUNE_FUSIONE'
-- . 'COD_PRO_FUSIONE'
-- . 'COD_COM_FUSIONE'
--
  if a_cod_provincia is not null and a_cod_comune is not null then
     w_descrizione    := '';
     w_sigla_provincia    := '';
     begin
       select decode(a_campo,
                'CODICE_COMUNE',lpad(com.provincia_stato,3,'0')||lpad(com.comune,3,'0'),
                'COD_PROVINCIA',lpad(com.provincia_stato,3,'0'),
                'COD_COMUNE',lpad(com.comune,3,'0'),
                'DESCRIZIONE',com.denominazione,
                'SIGLA_PROVINCIA',pro.sigla,
                'CAP',lpad(com.cap,5,'0'),
                'TRIBUNALE',lpad(com.provincia_tribunale,3,'0')||lpad(com.comune_tribunale,3,'0'),
                'CODICE_CATASTO',com.sigla_cfis,
                'CODICE_CONSOLATO',com.consolato||lpad(com.tipo_consolato,2,'0'),
                'COD_CONSOLATO',com.consolato,
                'TIPO_CONSOLATO',lpad(com.tipo_consolato,2,'0'),
--                'CEE',com.cee,
--                'COD_TERRITORIO',com.cod_territorio,
                'DATA_SOPPRESSIONE', to_char(com.data_soppressione),
                'CODICE_COMUNE_FUSIONE', lpad(com.provincia_fusione,3,'0')||lpad(com.comune_fusione,3,'0'),
                'COD_PRO_FUSIONE', lpad(com.provincia_fusione,3,'0'),
                'COD_COM_FUSIONE', lpad(com.comune_fusione,3,'0')
              )
         into w_campo
         from ad4_comuni com, ad4_province pro
        where com.provincia_stato  = a_cod_provincia
          and com.comune           = a_cod_comune
          and pro.provincia (+) = com.provincia_stato
       ;
     exception
       when no_data_found then
--            w_campo := 'no rows';
            raise errore;
       when too_many_rows then
--            w_campo := 'too many';
            raise errore;
       when others then
--            w_campo := SQLERRM;
            raise errore;
     end;
  else
     if a_descrizione like ')%' then
        w_sigla    := ltrim(substr(a_descrizione,instr(a_descrizione,'(')+1));
        w_sigla    := rtrim(substr(w_sigla,1,instr(w_sigla,')')-1));
        if length(w_sigla) > 3 then
           w_descrizione        := a_descrizione;
           w_sigla_provincia    := '';
        else
           w_descrizione        := rtrim(substr(a_descrizione,1,instr(a_descrizione,'(')-1));
           w_sigla_provincia    := w_sigla;
        end if;
     else
        w_descrizione    := a_descrizione;
        w_sigla_provincia    := '';
     end if;
--dbms_output.put_line('w_descrizione: '||w_descrizione);
--dbms_output.put_line('w_sigla_provincia: '||w_sigla_provincia);
     begin
       select decode(a_campo,
                'CODICE_COMUNE',lpad(com.provincia_stato,3,'0')||lpad(com.comune,3,'0'),
                'COD_PROVINCIA',lpad(com.provincia_stato,3,'0'),
                'COD_COMUNE',lpad(com.comune,3,'0'),
                'DESCRIZIONE',com.denominazione,
                'SIGLA_PROVINCIA',pro.sigla,
                'CAP',lpad(com.cap,5,'0'),
                'TRIBUNALE',lpad(com.provincia_tribunale,3,'0')||lpad(com.comune_tribunale,3,'0'),
                'CODICE_CATASTO',com.sigla_cfis,
                'CODICE_CONSOLATO',com.consolato||lpad(com.tipo_consolato,2,'0'),
                'COD_CONSOLATO',com.consolato,
                'TIPO_CONSOLATO',lpad(com.tipo_consolato,2,'0'),
--                'CEE',com.cee,
--                'COD_TERRITORIO',com.cod_territorio,
                'DATA_SOPPRESSIONE', to_char(com.data_soppressione),
                'CODICE_COMUNE_FUSIONE', lpad(com.provincia_fusione,3,'0')||lpad(com.comune_fusione,3,'0'),
                'COD_PRO_FUSIONE', lpad(com.provincia_fusione,3,'0'),
                'COD_COM_FUSIONE', lpad(com.comune_fusione,3,'0')
              )
         into w_campo
         from ad4_comuni com, ad4_province pro
        where com.denominazione             = w_descrizione
          and nvl(com.provincia_stato,' ') = nvl(nvl(w_sigla_provincia,com.provincia_stato),' ')
          and ((com.provincia_stato < 198 and a_flag_italiano = 'S')
               or
               (com.provincia_stato > 200 and a_flag_estero = 'S')
               or
               (a_flag_italiano is null and a_flag_estero is null)
              )
          and ((com.data_soppressione is null
                and com.provincia_fusione is null
                and com.comune_fusione is null
                and a_flag_attivo = 'S')
               or
                a_flag_attivo is null)
          and pro.provincia (+) = com.provincia_stato
       ;
     exception
       when no_data_found then
--            w_campo := 'no rows';
            raise errore;
       when too_many_rows then
--            w_campo := 'too many';
            raise errore;
       when others then
--            w_campo := SQLERRM;
            raise errore;
     end;
  end if;
  RETURN w_campo;
exception
  when errore then
       w_errore := 'Errore in ricerca Comuni ('||SQLERRM||')';
       RETURN w_campo;
  when others then
--       w_campo := SQLERRM;
       w_errore := 'Errore ('||SQLERRM||')';
       RETURN w_campo;
end;
/* End Function: F_GET_CAMPO_AD4_COM */
/

