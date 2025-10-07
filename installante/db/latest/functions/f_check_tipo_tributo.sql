--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_check_tipo_tributo stripComments:false runOnChange:true 
 
create or replace function F_CHECK_TIPO_TRIBUTO
/*************************************************************************
 NOME:        F_CHECK_TIPO_TRIBUTO
 DESCRIZIONE: Verifica se nell'applicativo e' prevista la gestione del
              tipo tributo passato come parametro, selezionando il dato
              presente nella tabella installazione_parametri con
              chiave 'TITR_ENTE'.
 PARAMETRI:   p_tipo_tributo      Tipo tributo da controllare
 RITORNA:     number              0 - Tipo tributo gestito
                                  1 - Tipo tributo non gestito
 NOTE:
 Rev.    Date         Author      Note
 000     06/05/2020   VD          Prima emissione.
*************************************************************************/
( p_tipo_tributo           varchar2
) return number
is
  w_valore                 varchar2(2000);
  d_result                 number;
begin
  w_valore := F_INPA_VALORE('TITR_ENTE');
--
  if w_valore is null then
     d_result := 0;
  else
     if instr(w_valore,p_tipo_tributo) > 0 then
        d_result := 0;
     else
        d_result := 1;
     end if;
  end if;
  --
  return d_result;
end;
/* End Function: F_CHECK_TIPO_TRIBUTO */
/

