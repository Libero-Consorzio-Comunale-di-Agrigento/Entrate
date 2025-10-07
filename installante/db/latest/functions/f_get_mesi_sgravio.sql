--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_get_mesi_sgravio stripComments:false runOnChange:true 
 
create or replace function F_GET_MESI_SGRAVIO
/*************************************************************************
 NOME:        F_GET_MESI_SGRAVIO
 DESCRIZIONE: Calcola i mesi sgravio in base ai parametri passati
 PARAMETRI:   Oggetto imposta
 RITORNA:     number              Mesi da sgravare
 NOTE:
 Rev.    Date         Author      Note
 000     12/07/2019   VD          Prima emissione.
*************************************************************************/
( p_mesi_sgravio             number
, p_da_mese                  number
, p_a_mese                   number
, p_anno_ruolo               number
, p_data_inizio              date
, p_data_fine                date
) return number
is
  w_mesi_sgravio             number;
begin
   --
   -- Calcolo mesi in base al periodo indicato nei parametri
   -- Se il da_mese e' nullo, si considerano i mesi presenti sulla tabella
   --
   if p_da_mese is null then
      w_mesi_sgravio := nvl(p_mesi_sgravio ,0);
   else
      w_mesi_sgravio := months_between(least(p_data_fine
                                            ,last_day(to_date('01'||lpad(p_a_mese,2,'0')||p_anno_ruolo,'ddmmyyyy'))
                                            ) + 1
                                      ,greatest(p_data_inizio
                                               ,to_date('01'||lpad(p_da_mese,2,'0')||p_anno_ruolo,'ddmmyyyy')
                                               )
                                      );
   end if;
--
  return w_mesi_sgravio;
--
end;
/

