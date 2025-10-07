--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_get_comune_belfiore stripComments:false runOnChange:true 
 
create or replace function F_GET_COMUNE_BELFIORE
( p_codice_belfiore        varchar2
, p_data                   date
, p_tipo_campo             varchar2
) return varchar2 is
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
         from ad4_comuni
        where sigla_cfis = p_codice_belfiore
          and data_soppressione is null;
     exception
       when others then
         w_provincia_stato := to_number(null);
         w_comune          := to_number(null);
     end;
  else
     begin
       select c1.provincia_stato
            , c1.comune
         into w_provincia_stato
            , w_comune
         from ad4_comuni c1
        where c1.sigla_cfis = p_codice_belfiore
          and nvl(c1.data_soppressione,to_date ('31122999', 'ddmmyyyy')) =
             (select min(nvl(c2.data_soppressione,to_date ('31122999', 'ddmmyyyy')))
                from ad4_comuni c2
               where c2.provincia_stato = c1.provincia_stato
                 and c2.comune = c1.comune
                 and nvl(c2.data_soppressione,to_date ('31122999', 'ddmmyyyy')) >= p_data);
     exception
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
/* End Function: F_GET_COMUNE_BELFIORE */
/

