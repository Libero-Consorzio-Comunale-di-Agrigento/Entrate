--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_conta_aliquote_ogco stripComments:false runOnChange:true 
 
create or replace function F_CONTA_ALIQUOTE_OGCO
/*************************************************************************
 NOME:        F_CONTA_ALIQUOTE_OGGETTO
 DESCRIZIONE: Conta il numero delle aliquote_ogco presenti per l'oggetto_pratica
              relativi al tipo tributo e all'anno di reiferimento.
              Se il contatore e' maggiore di zero restituisce 'S'.
 RITORNA:     varchar2              'S' se esiste almeno un record,
                                       altrimenti null
 NOTE:
 Rev.    Date         Author      Note
 004     25/05/2023   AB          Modificato il controllo con le date
                                  di inizio e fine validita
                                  Si considerano gli alog con l'anno di
                                  riferimento compreso tra dal e al
 000     04/07/2019   VD          Prima emissione.
*************************************************************************/
( a_tipo_tributo           varchar2
, a_anno                   number
, a_cod_fiscale            varchar2
, a_oggetto_pratica        number
, a_data_da                date
, a_data_a                 date
) return string
is
  w_conta_record           number;
begin
  select count(*)
    into w_conta_record
    from ALIQUOTE_OGCO
   where cod_fiscale     = a_cod_fiscale
     and oggetto_pratica = a_oggetto_pratica
--     and dal            <= a_data_a
--     and al             >= a_data_da
-- AB 25/05/2023 modificato il controllo con le date di inizio e fine validita
--               Si considerano gli alog con l'anno di riferimento
--               compreso tra dal e al
     and a_anno between to_char(dal,'yyyy') and to_char(al,'yyyy')
     and tipo_tributo    = a_tipo_tributo;
--
  if w_conta_record > 0 then
     return 'S';
  else
     return null;
  end if;
end;
/* End Function: F_CONTA_ALIQUOTE_OGCO */
/

