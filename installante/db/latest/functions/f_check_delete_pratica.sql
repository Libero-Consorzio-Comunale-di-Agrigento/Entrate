--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_check_delete_pratica stripComments:false runOnChange:true 
 
create or replace function F_CHECK_DELETE_PRATICA
/*************************************************************************
 NOME:        F_CHECK_DELETE_PRATICA
 DESCRIZIONE: Controlla se la pratica che si vuole eliminare e' stata
              caricata da un verificatore (campo importanza = 10 nella
              tabella UTENTI). Nel caso, la pratica non puo' essere
              eliminata.
 PARAMETRI:   p_pratica           Pratica da eliminare
              p_utente_new        Utente che sta eliminando la pratica
 RITORNA:     number              0 - Pratica eliminabile
                                  1 - Pratica non eliminabile
 NOTE:
 Rev.    Date         Author      Note
 000     17/01/2020   VD          Prima emissione.
*************************************************************************/
( p_pratica                number
, p_utente_new             varchar2
) return number
is
  w_utente_old             varchar2(8);
  w_importanza_old         number;
  w_importanza_new         number;
  d_result                 number;
begin
  --
  -- Si seleziona da iter_pratica l'utente che ha effettuato l'inserimento
  --
  begin
    select itpr.utente
      into w_utente_old
      from iter_pratica itpr
     where itpr.pratica = p_pratica
       and itpr.data = (select min(itpx.data)
                          from iter_pratica itpx
                         where itpx.pratica = p_pratica);
  exception
    when others then
      w_utente_old := null;
  end;
  --
  -- Si seleziona da ad4_utenti il valore del campo importanza
  -- per l'utente che ha inserito la pratica
  --
  begin
    select nvl(importanza,0)
      into w_importanza_old
      from ad4_utenti
     where utente = w_utente_old;
  exception
    when others then
      if w_utente_old like 'ADS%' then
         w_importanza_old := 10;
      else
         w_importanza_old := 0;
      end if;
  end;
  --
  -- Si seleziona da ad4_utenti il valore del campo importanza per
  -- l'utente che sta cercando di eliminare la pratica
  --
  begin
    select nvl(importanza,0)
      into w_importanza_new
      from ad4_utenti
     where utente = p_utente_new;
  exception
    when others then
      w_importanza_new := 0;
  end;
  --
  -- Se la pratica era stata inserita da un verificatore (importanza = 10),
  -- non e' possibile eliminarla
  --
  if w_importanza_old = 10 then
     if w_importanza_new = 10 then
        d_result := 0;
     else
        d_result := 1;
     end if;
  else
     d_result := 0;
  end if;
--
  return d_result;
--
end;
/* End Function: F_CHECK_DELETE_PRATICA */
/

