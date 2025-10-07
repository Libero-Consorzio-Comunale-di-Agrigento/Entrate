--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_conta_utilizzi_oggetto stripComments:false runOnChange:true 
 
create or replace function F_CONTA_UTILIZZI_OGGETTO
/*************************************************************************
 NOME:        F_CONTA_UTILIZZI_OGGETTO
 DESCRIZIONE: Conta il numero degli utilizzi presenti per l'oggetto
                relativi al tipo tributo e al periodo indicati.
                                          Se il contatore e' maggiore di zero restituisce 'S'.
 RITORNA:     varchar2              'S' se esiste almeno un record,
                                      altrimenti null
 NOTE:
 Rev.    Date         Author      Note
 004     02/01/2020   VD          Modificato test su periodo di validita
                                  degli utilizzi: si considerano gli utog
                                  con l'anno di riferimento compreso tra
                                  anno e anno scadenza della riga.
 003     05/08/2019   AB          Flag attivo per la TASI anche se ci sono
                                  utilizzi ICI
 002     11/07/2019   VD          Aggiunto test su tipo utilizzo: ora
                                  si considerano solo i tipi utilizzo 1
                                  oppure da 61 a 99
 001     09/07/2019   AB          Gestione caso utilizzo oggetto con
                                  scadenza inferiore alla data inizio
                                  periodo o inizio anno.
 000     04/07/2019   VD          Prima emissione.
*************************************************************************/
( a_tipo_tributo           varchar2
, a_anno                   number
, a_oggetto                number
, a_data_da                date
, a_data_a                 date
) return string
is
  w_conta_record           number;
begin
--
-- Si contano i record della tabella utilizzi_oggetto dell'oggetto
-- indicato, per il tipo tributo e il periodo indicati.
-- Si considerano i seguenti record:
--    - se dal e al sono valorizzati, il periodo deve intersecarsi con
--      il periodo indicato
--    - se dal e al non sono valorizzati, la data di scadenza deve essere
--      maggiore della data di inizio periodo indicato.
-- (VD - 02/01/2020): modificato test su periodo di validita degli utilizzi.
--                    Si considerano gli utog con l'anno di riferimento
--                    compreso tra anno e anno scadenza della riga.
--
  select count(*)
    into w_conta_record
    from UTILIZZI_OGGETTO utog
   where utog.oggetto = a_oggetto
     --and utog.tipo_tributo = a_tipo_tributo
     -- (AB - 05/08/2019): si attiva il flag per la TASI anche se ci sono
     --                    solo utilizzi ICI
     and utog.tipo_tributo in (a_tipo_tributo, decode(a_tipo_tributo,'TASI','ICI',''))
     -- (VD - 11/07/2019): si considerano solo i tipi utilizzo 1
     --                    oppure da 61 a 99
     and (utog.tipo_utilizzo       = 1
      or utog.tipo_utilizzo between 61 and 99
         )
     and a_anno >= utog.anno
--     and ((utog.dal is not null and utog.al is not null and
--                     utog.dal <= a_data_a and utog.al >= a_data_da)
--                  or      (utog.dal is null and utog.al is null and
--                       utog.data_scadenza >= a_data_da))
--           utog.data_scadenza >= greatest(to_date('01/01/'||a_anno,'dd/mm/yyyy'),a_data_da)));
-- (VD - 02/01/2020): modificato test su periodo validita utilizzi.
--                    Si considerano gli utog con l'anno di riferimento
--                    compreso tra anno e anno scadenza della riga.
     and a_anno <= decode(utog.data_scadenza,null,9999,
                          to_number(to_char(utog.data_scadenza,'yyyy')));
--
  if w_conta_record > 0 then
     return 'S';
  else
     return null;
  end if;
end;
/* End Function: F_CONTA_UTILIZZI_OGGETTO */
/

