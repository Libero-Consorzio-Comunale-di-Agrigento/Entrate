--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_get_dati_belfiore stripComments:false runOnChange:true 
 
create or replace function F_GET_DATI_BELFIORE
( p_codice_belfiore        varchar2
, p_data                   date
, p_tipo_campo             varchar2
) return varchar2 is
/*************************************************************************
 NOME:        F_GET_DATI_BELFIORE
 DESCRIZIONE: Sulla base del codice Belfiore ed eventualmente della data
              restituisce il comune (tipo_campo = 'C' o la provincia = 'P'
              si cerca prima sui comuni storici e poi su quello standard
              in modo da recuperare il dato anche se soppresso prima della data
              Occorre creare il nuovo synonym ad4_vista_comuni_storici
 NOTE:
 Rev.    Date         Author      Note
 000     05/03/2019   VD          Prima emissione.
 001     23/12/2022   AB          Gestione dei comuni soppressi sulla
                                  ad4_vista_storici_comuni
*************************************************************************/
  w_provincia_stato        number;
  w_comune                 number;
  w_result                 varchar2(100);
begin
  if p_data is null then
     begin
       select provincia_stato
            , comune
         into w_provincia_stato
            , w_comune
         from ad4_vista_comuni_storici
        where sigla_cfis = p_codice_belfiore
          and al is null;
     exception
       when too_many_rows then  -- potrebbe essere il caso di comuni esteri
         begin
           select provincia_stato
                , comune
             into w_provincia_stato
                , w_comune
             from ad4_vista_comuni_storici
            where sigla_cfis = p_codice_belfiore
              and substr(p_codice_belfiore,1,1) = 'Z'
              and comune = 0;
         exception
           when others then
             w_provincia_stato := to_number(null);
             w_comune          := to_number(null);
         end;
       when no_data_found then
         begin
           select provincia_stato
                , comune
             into w_provincia_stato
                , w_comune
             from ad4_comuni
            where sigla_cfis = p_codice_belfiore;
         exception
           when others then
             w_provincia_stato := to_number(null);
             w_comune          := to_number(null);
         end;
       when others then
         w_provincia_stato := to_number(null);
         w_comune          := to_number(null);
     end;
  else
     begin
       select provincia_stato
            , comune
         into w_provincia_stato
            , w_comune
         from ad4_vista_comuni_storici
        where sigla_cfis = p_codice_belfiore
          and p_data between dal and nvl(al,to_date('31/12/9999','dd/mm/yyyy'));
     exception
       when too_many_rows then  -- potrebbe essere il caso di comuni esteri
         begin
           select provincia_stato
                , comune
             into w_provincia_stato
                , w_comune
             from ad4_vista_comuni_storici
            where sigla_cfis = p_codice_belfiore
              and substr(p_codice_belfiore,1,1) = 'Z'
              and comune = 0
              and p_data between dal and nvl(al,to_date('31/12/9999','dd/mm/yyyy'));
         exception
           when others then
             w_provincia_stato := to_number(null);
             w_comune          := to_number(null);
         end;
       when no_data_found then
         begin
           select provincia_stato
                , comune
             into w_provincia_stato
                , w_comune
             from ad4_comuni
            where sigla_cfis = p_codice_belfiore;
         exception
           when others then
             w_provincia_stato := to_number(null);
             w_comune          := to_number(null);
         end;
       when others then
         w_provincia_stato := to_number(null);
         w_comune          := to_number(null);
     end;
  end if;
--
  if w_provincia_stato is not null and
     w_comune is not null then
     if p_tipo_campo = 'C' then
        if w_provincia_stato > 200 then
           w_result := ad4_stati_territori_tpk.get_denominazione(w_provincia_stato);
        else
           w_result := ad4_comune.get_denominazione(w_provincia_stato,w_comune);
        end if;
     elsif
        p_tipo_campo = 'P' then
        if w_provincia_stato > 200 then
           w_result := null;
        else
           w_result := ad4_provincia.get_sigla(w_provincia_stato);
        end if;
     end if;
  end if;
--
  return w_result;
end;
/* End Function: F_GET_DATI_BELFIORE */
/

