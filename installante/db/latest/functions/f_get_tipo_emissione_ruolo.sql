--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_get_tipo_emissione_ruolo stripComments:false runOnChange:true 
 
create or replace function F_GET_TIPO_EMISSIONE_RUOLO
/*************************************************************************
 NOME:        F_GET_TIPO_EMISSIONE_RUOLO
 DESCRIZIONE: Dato un ruolo (in formato stringa perche' proveniente dal
              campo NOTE della tabella OGGETTI_IMPOSTA), restituisce il
              relativo tipo emissione
 RITORNA:     varchar2              Tipo emissione
 NOTE:
 Rev.    Date         Author      Note
 000     02/02/2018   VD          Prima emissione.
*************************************************************************/
(p_ruolo              varchar2
)
  return varchar2
is
  w_tipo_emissione    varchar2(1);
begin
  --
  -- Controllo numericità della parte di stringa contenente
  -- il numero del ruolo
  --
  if ltrim(rtrim(p_ruolo)) is null or
     afc.is_numeric(ltrim(rtrim(p_ruolo))) = 0 then
     w_tipo_emissione := 'X';
  else
     begin
       select tipo_emissione
         into w_tipo_emissione
         from RUOLI
        where ruolo = to_number(p_ruolo);
     exception
       when others then
         w_tipo_emissione := 'X';
     end;
  end if;
--
  return w_tipo_emissione;
--
end;
/* End Function: F_GET_TIPO_EMISSIONE_RUOLO */
/

