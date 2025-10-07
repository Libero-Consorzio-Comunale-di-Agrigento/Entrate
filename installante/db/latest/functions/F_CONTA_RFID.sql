--liquibase formatted sql 
--changeset abrandolini:20250326_152438_F_CONTA_RFID stripComments:false runOnChange:true 
 
CREATE OR REPLACE function     F_CONTA_RFID
/*************************************************************************
 NOME:        F_CONTA_RFID
 DESCRIZIONE: Conta il numero di cod_rfid presenti per codice fiscale,
 RITORNA:     varchar2              'S' se esiste almeno un record,
                                     altrimenti null
 NOTE:
 Rev.    Date         Author      Note
 000     18/12/2024   AB          Prima emissione.
*************************************************************************/
( a_cod_fiscale            varchar2
, a_oggetto                number
, a_solo_attivi            varchar2 default null
) return string
is
  w_conta_record           number   :=0;
begin
--
  select count(*)
    into w_conta_record
    from codici_rfid corf
   where corf.cod_fiscale = a_cod_fiscale
     and corf.oggetto     = a_oggetto      
     and (a_solo_attivi is null or
          a_solo_attivi is not null and corf.data_restituzione is null)
  ;
  if w_conta_record > 0 then
     return 'S';
  else
     return null;
  end if;
end;
/* End Function: F_CONTA_RFID */
/
