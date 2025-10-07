--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_conta_familiari_soggetto stripComments:false runOnChange:true 
 
create or replace function F_CONTA_FAMILIARI_SOGGETTO
( p_cod_fiscale            varchar2
, p_anno                   number
) return number
is
  w_ni                     number;
  w_conta                  number;
begin
  -- Se l'anno è 9999, significa che non si sta trattando un anno
  -- specifico, quindi si restituisce null
  if p_anno = 9999 then
     return to_number(null);
  end if;
  -- Si seleziona l'ni abbinato al codice fiscale nella tabella contribuenti
  begin
    select ni
      into w_ni
      from contribuenti
     where cod_fiscale = p_cod_fiscale;
  exception
    when others then
      w_ni := to_number(null);
  end;
  -- Se l'ni selezionato non e' nullo, si contano le righe di
  -- familiari_soggetto relative all'ni e all'anno indicati
  if w_ni is not null then
     begin
       select count(*)
         into w_conta
         from familiari_soggetto
        where ni = w_ni
          and anno = p_anno;
     exception
       when others then
         w_conta := 0;
     end;
  end if;
  --
  return w_conta;
end;
/* End Function: F_CONTA_FAMILIARI_SOGGETTO */
/

