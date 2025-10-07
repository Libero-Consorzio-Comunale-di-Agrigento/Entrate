--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_imposta_pratica stripComments:false runOnChange:true 
 
create or replace function F_IMPOSTA_PRATICA
/*************************************************************************
 NOME:        F_IMPOSTA_PRATICA
 DESCRIZIONE: Data una pratica, calcola la somma dell'imposta calcolata/dovuta,
              in acconto/ a saldo a seconda dei parametri indicati
 PARAMETRI:   Pratica             Numero pratica
              Calcolata/Dovuta    C = imposta calcolata
                                  D = imposta dovuta
              Acconto/Saldo       A = imposta in acconto
                                  S = imposta a saldo
 RITORNA:     number              Totale imposta
 NOTE:
 Rev.    Date         Author      Note
 001     07/04/2015   VD          Prima emissione.
*************************************************************************/
( p_pratica                       pratiche_tributo.pratica%type
, p_calc_dovuta                   varchar2
, p_acconto_saldo                 varchar2
)
  return number
is
  w_totale_imposta                number(15,2);
  w_imposta                       number(15,2);
  w_imposta_dovuta                number(15,2);
  w_imposta_acconto               number(15,2);
  w_imposta_dovuta_acconto        number(15,2);
--
begin
  select sum(ogim.imposta)
       , sum(ogim.imposta_dovuta)
       , sum(ogim.imposta_acconto)
       , sum(ogim.imposta_dovuta_acconto)
    into w_imposta
       , w_imposta_dovuta
       , w_imposta_acconto
       , w_imposta_dovuta_acconto
    from oggetti_pratica ogpr
       , oggetti_imposta ogim
   where ogpr.pratica = p_pratica
     and ogpr.oggetto_pratica = ogim.oggetto_pratica;
--
  if p_calc_dovuta = 'C' then
     if p_acconto_saldo = 'A' then
        w_totale_imposta := nvl(w_imposta_acconto,0);
     else
        w_totale_imposta := nvl(w_imposta,0) - nvl(w_imposta_acconto,0);
     end if;
  else
     if p_acconto_saldo = 'A' then
        w_totale_imposta := nvl(w_imposta_dovuta_acconto,0);
     else
        w_totale_imposta := nvl(w_imposta_dovuta,0) - nvl(w_imposta_dovuta_acconto,0);
     end if;
  end if;
--
  return w_totale_imposta;
--
end;
/* End Function: F_IMPOSTA_PRATICA */
/

