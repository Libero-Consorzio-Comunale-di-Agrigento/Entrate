--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_check_sostituzione_contr stripComments:false runOnChange:true 
 
create or replace function F_CHECK_SOSTITUZIONE_CONTR
/*************************************************************************
 NOME:        F_CHECK_SOSTITUZIONE_CONTR

 DESCRIZIONE: Esegue i controlli necessari prima di effettuare una 
              sostituzione contribuente 
              
 RITORNA:     0 - Controlli superati, la sostituzione si può fare
              1 - Controlli NON superati, la sostituzione NON si può fare
              2 - Attesa conferma dall'operatore per situazione 
                  potenzialmente non corretta              
 
 NOTE:        
 
 Rev.    Date         Author      Note 
 001     07/03/2023   DM          Viene ora considerato errore se entrambi
                                  i contribuenti hanno recapiti e non solo
                                  il new.
 000     28/04/2020   VD          Prima emissione
*************************************************************************/
( p_cod_fiscale_old               varchar2
, p_cod_fiscale_new               varchar2
, p_ni_old                        number
, p_ni_new                        number
, p_messaggio                     IN OUT varchar2
) return number
is
  c_flag_si                       number := 0;
  c_flag_no                       number := 1;
  c_flag_conferma                 number := 2;
  w_return                        number;
  w_conta                         number;
begin
  if p_cod_fiscale_old is null then
     p_messaggio:= 'Indicare il codice fiscale del contribuente da sostituire';
return c_flag_no;
end if;
  --
  if p_cod_fiscale_new is null then
     p_messaggio := 'Indicare il codice fiscale del nuovo contribuente';
return c_flag_no;
end if;
  -- Inizio controlli
  if p_cod_fiscale_old <> p_cod_fiscale_new then
     -- Controllo esistenza familiari_soggetto
select count (*)
into w_conta
from (select distinct anno
      from familiari_soggetto faso
      where ni = p_ni_old
      intersect
      select distinct anno
      from familiari_soggetto faso
      where ni = p_ni_new);
if nvl(w_conta,0) > 0 then
        p_messaggio := 'Nuovo Contribuente non utilizzabile, sono presenti familiari negli stessi anni';
return c_flag_no;
end if;
     -- Controllo compensazioni
select count(*)
into w_conta
from compensazioni
where cod_fiscale = p_cod_fiscale_new;
if nvl(w_conta,0) > 0 then
        p_messaggio := 'Nuovo Contribuente non utilizzabile, sono presenti compensazioni';
return c_flag_no;
end if;
     -- Controllo recapiti
select count(*)
into w_Conta
from recapiti_soggetto
where ni = p_ni_new;
-- Se il nuovo
if nvl(w_conta,0) > 0 then
select count(*)
into w_Conta
from recapiti_soggetto
where ni = p_ni_old;
-- ed il vecchio hanno recapiti
if nvl(w_conta,0) > 0 then
          p_messaggio := 'Nuovo Contribuente non utilizzabile, sono presenti recapiti';
return c_flag_no;
end if;
end if;
     -- Controllo deleghe bancarie del vecchio contribuente: se presenti, 
     -- si richiede conferma all'operatore per l'esecuzione della 
     -- sostituzione
select count(*)
into w_conta
from deleghe_bancarie
where cod_fiscale = p_cod_fiscale_old;
if nvl(w_conta,0) > 0 then
        p_messaggio := 'Il Contribuente da sostituire ha Deleghe Bancarie';
return c_flag_conferma;
end if;
end if;
--
return c_flag_si;
end;
/* End Function: F_CHECK_SOSTITUZIONE_CONTR */
/
