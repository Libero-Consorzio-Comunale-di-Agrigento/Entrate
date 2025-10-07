--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_depag_gg_violazioni stripComments:false runOnChange:true 
 
create or replace function F_DEPAG_GG_VIOLAZIONI
/*************************************************************************
 NOME:        F_DEPAG_GG_VIOLAZIONI
 DESCRIZIONE: Integrazione TR4/DEPAG.
              Dato il tipo tributo restituisce il numero di giorni da
              sommare alla data di scadenza o alla data di sistema per
              determinare la data di scadenza avviso e la data di
              scadenza avviso PT in DEPAG.
 RITORNA:     string              codice servizio per DEPAG
 NOTE:
 Rev.    Date         Author      Note
 000     30/11/2021   VD          Prima emissione.
*************************************************************************/
(a_tipo_tributo            in varchar2
)
RETURN number
IS
  w_valore_inpa      varchar2(200);
  w_num_gg           varchar2(10); --number;
BEGIN
  begin
     select inpa.valore
       into w_valore_inpa
       from installazione_parametri inpa
      where inpa.parametro = 'DEPA_GG_V'
         ;
  exception
     when others then
       w_valore_inpa := '';
  end;
  w_num_gg := 0;
  if w_valore_inpa is not null then
     if instr(w_valore_inpa,a_tipo_tributo) > 0 then
        w_num_gg := to_number(regexp_substr(w_valore_inpa,'[0-9]+',
                                            instr(w_valore_inpa,a_tipo_tributo),1));
     end if;
  end if;
  return w_num_gg;
END;
/* End Function: F_DEPAG_GG_VIOLAZIONI */
/

