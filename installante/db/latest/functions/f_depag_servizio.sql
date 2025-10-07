--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_depag_servizio stripComments:false runOnChange:true 
 
create or replace function F_DEPAG_SERVIZIO
/*************************************************************************
 NOME:        F_DEPAG_SERVIZIO

 DESCRIZIONE: Integrazione TR4/DEPAG.
              Dato il tipo tributo e il tipo occupazione, la funzione
              restituisce il codice del servizio da passare a DEPAG.
              Se viene indicato il tipo occupazione, il codice del servizio
              viene composto come codice+tipo occupazione.
              Se viene indicato il flag_violazione = 'S', si restituisce
              il codice del servizio specifico per le violazioni, che
              deve essere indicato nella stringa preceduto dal valore
              VIOL=

 RITORNA:     string              codice servizio per DEPAG

 NOTE:

 Rev.    Date         Author      Note
 002     23/01/2024   RV          Aggiunta gestione servizio multibeneficiario.
 001     30/11/2021   VD          Aggiunta gestione servizio violazioni.
 000     23/06/2020   AB          Prima emissione.
*************************************************************************/
(a_tipo_tributo            in varchar2
,a_tipo_occupazione        in varchar2
,a_flag_violazione         in varchar2 default null
,a_flag_mb                 in varchar2 default null
)
RETURN varchar2
IS
  w_valore_inpa      varchar2(200);
  w_servizio         varchar2(100);
  --
  w_instr            number;
  --

BEGIN
  --
  begin
     select inpa.valore
       into w_valore_inpa
       from installazione_parametri inpa
      where inpa.parametro = 'DEPA_'||a_tipo_tributo
         ;
  exception
     when others then
       w_valore_inpa := '';
  end;
  --
  if w_valore_inpa is not null then
    w_servizio := substr(w_valore_inpa,1,instr(w_valore_inpa,' ')-1);
    if nvl(a_flag_mb,'N') = 'S' then
      w_instr := instr(w_valore_inpa,' MB=');
      if w_instr > 0 then
         w_servizio := trim(substr(w_valore_inpa,w_instr + 4));
         --
         w_instr := instr(w_servizio,' ');
         if w_instr > 0 then
             w_servizio := trim(substr(w_servizio,1,w_instr));
         end if;
      end if;
    end if;
    if substr(w_valore_inpa,instr(w_valore_inpa,'=')+1,1) = 'S' then
      w_servizio := w_servizio||a_tipo_occupazione;
    end if;
    --
    if nvl(a_flag_violazione,'N') = 'S' then
      w_instr := instr(w_valore_inpa,'VIOL=');
      if w_instr > 0 then
        w_servizio := trim(substr(w_valore_inpa,w_instr + 5));
      end if;
      --
      if nvl(a_flag_mb,'N') = 'S' then
        w_instr := instr(w_valore_inpa,'VIOL_MB=');
        if w_instr > 0 then
          w_servizio := trim(substr(w_valore_inpa,w_instr + 8));
        end if;
      end if;
      --
      w_instr := instr(w_servizio,' ');
      if w_instr > 0 then
        w_servizio := trim(substr(w_servizio,1,w_instr));
      end if;
    end if;
  else
     w_servizio := a_tipo_tributo;
  end if;
  --
  return w_servizio;
  --
END;
/* End Function: F_DEPAG_SERVIZIO */
/
