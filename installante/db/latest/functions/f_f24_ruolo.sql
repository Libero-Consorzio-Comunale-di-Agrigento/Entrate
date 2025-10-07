--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_f24_ruolo stripComments:false runOnChange:true 
 
create or replace function F_F24_RUOLO
/*************************************************************************
 NOME:        F_F24_RUOLO
 DESCRIZIONE: Dato un identificativo operazione proveniente da file
              versamenti F24 di tipo "RUOL%", controlla l'esistenza del
              ruolo indicato e se non esiste restituisce null
 RITORNA:     number              Numero ruolo
 NOTE:        Composizione identificativo operazione:
              RUOLAAAARRNNNNNNNN
              dove
              AAAA è l'anno del ruolo
              RR è il numero della rata
              NNNNNNNN è il numero del ruolo
 Rev.    Date         Author      Note
 002     01/06/2016   VD          Gestione caso stringa non corretta:
                                  se il valore che segue "RUOL" non
                                  e' numerico, si restituisce null.
 001     01/02/2015   VD          Prima emissione.
*************************************************************************/
(p_id_operazione      varchar2
)
  return number
is
  w_ruolo             number;
begin
  --
  -- Controllo numericità della parte di stringa seguente la
  -- dicituora "RUOL"
  --
  if afc.is_numeric(substr(p_id_operazione,5,14)) = 0 then
     w_ruolo := to_number(null);
  else
     begin
       select ruolo
         into w_ruolo
         from RUOLI
        where anno_ruolo = to_number(substr(p_id_operazione,5,4))
          and ruolo = to_number(substr(p_id_operazione,11,8));
     exception
       when others then
         w_ruolo := to_number(null);
     end;
  end if;
--
  return w_ruolo;
--
end;
/* End Function: F_F24_RUOLO */
/

