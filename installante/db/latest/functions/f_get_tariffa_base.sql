--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_get_tariffa_base stripComments:false runOnChange:true 
 
create or replace function F_GET_TARIFFA_BASE
/*************************************************************************
 NOME:        F_GET_TARIFFA_BASE
 DESCRIZIONE: Dati codice tributo, categoria e anno, restituisce il tipo
              tariffa identificato da flag_tariffa_base = 'S'.
 RITORNA:     number              Tipo tariffa
 NOTE:
 Rev.    Date         Author      Note
 000     10/12/2018   VD          Prima emissione.
*************************************************************************/
( p_tributo                number
, p_categoria              number
, p_anno                   number
) return number
is
  w_tipo_tariffa           number;
begin
  select min(tipo_tariffa)
    into w_tipo_tariffa
    from tariffe
   where tributo = p_tributo
     and categoria = p_categoria
     and anno = p_anno
     and nvl(flag_tariffa_base,'N') = 'S';
--
  return w_tipo_tariffa;
--
end;
/* End Function: F_GET_TARIFFA_BASE */
/

