--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_get_dati_presso stripComments:false runOnChange:true 
 
create or replace function F_GET_DATI_PRESSO
( p_ni_presso              number
, p_tipo                   varchar2 default null
) return varchar2
is
  d_dati_presso            varchar2(2000);
  d_cognome_nome           varchar2(100);
  d_indirizzo              varchar2(200);
  d_localita               varchar2(200);
begin
  begin
    select replace(sogP.cognome_nome,'/',' ') cognome_nome
          ,decode(sogP.cod_via
                 ,to_number(null),sogP.denominazione_via
                 ,arvP.denom_uff
                 )
            ||' '||to_char(sogP.num_civ)
            ||decode(sogP.suffisso,'','','/'||sogP.suffisso)
            ||decode(sogP.scala,'','',' Sc.'||sogP.scala)
            ||decode(sogP.piano,'','',' P.'||sogP.piano)
            ||decode(sogP.interno,'','',' Int.'||sogP.interno) indirizzo
          ,lpad(to_char(nvl(sogP.cap,comP.cap)),5,'0')||' '
            ||substr(comP.denominazione,1,30)||' '
            ||substr(proP.sigla,1,2) localita
      into d_cognome_nome
         , d_indirizzo
         , d_localita
      from soggetti sogP
         , archivio_vie       arvP
         , ad4_comuni         comP
         , ad4_provincie      proP
         , ad4_stati_territori sttP
     where sogP.ni              (+) = p_ni_presso
       and arvP.cod_via         (+) = sogP.cod_via
       and comP.provincia_stato (+) = sogP.cod_pro_res
       and comP.comune          (+) = sogP.cod_com_res
       and proP.provincia       (+) = sogP.cod_pro_res
       and sttP.stato_territorio (+)= sogP.cod_pro_res;
  exception
    when others then
      d_cognome_nome := '';
      d_indirizzo    := '';
      d_localita     := '';
  end;
--
  if p_tipo is null then
     d_dati_presso := d_cognome_nome||' '||d_indirizzo||' '||d_localita;
  else
     d_dati_presso := d_cognome_nome||chr(10)||d_indirizzo||chr(10)||d_localita;
  end if;
--
  return d_dati_presso;
end;
/* End Function: F_GET_DATI_PRESSO */
/

