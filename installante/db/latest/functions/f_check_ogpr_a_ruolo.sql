--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_check_ogpr_a_ruolo stripComments:false runOnChange:true 
 
create or replace function F_CHECK_OGPR_A_RUOLO
/*************************************************************************
 NOME:        F_CHECK_OGPR_A_RUOLO
 DESCRIZIONE: Data una pratica da annullare, la funzione verifica che non
              ci siano oggetti pratica gia' andati a ruolo
 NOTE:
 Rev.    Date         Author      Note
 000     07/05/2018   VD          Prima emissione.
*************************************************************************/
( a_pratica                       number )
return varchar2
is
w_ruolo                           number;
begin
  begin
    select min(ruolo)
      into w_ruolo
      from oggetti_pratica ogpr
         , oggetti_imposta ogim
     where ogpr.pratica = a_pratica
       and ogpr.oggetto_pratica = ogim.oggetto_pratica
       and ogim.ruolo is not null
     group by pratica;
  exception
    when others then
      w_ruolo := to_number(null);
  end;
return(w_ruolo);
end;
/* End Function: F_CHECK_OGPR_A_RUOLO */
/
