--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_recapito stripComments:false runOnChange:true 
 
create or replace function F_RECAPITO
/*************************************************************************
 NOME:        F_RECAPITO
 DESCRIZIONE: Funzione temporeanea.
              Richiama la funzione F_RECAPITO_CONV e, se il risultato e'
              -1 oppure uno spazio, li sostituisce con null.
              Serve ad evitare di modificare tutti i richiami della
              funzione F_RECAPITO e ad avere dei numeri civici o dei
              suffissi valorizzati a -1.
 Rev.    Date         Author      Note
 000     07/07/2020   VD          Prima emissione.
*************************************************************************/
(p_ni             number,
 p_tipo_tributo   varchar2,
 p_tipo_recapito  number,
 p_data_val       date default trunc(sysdate),
 p_campo          varchar2 default null)
RETURN varchar2
IS
  w_recapito                    varchar2(2000);
BEGIN
  w_recapito := F_RECAPITO_CONV(p_ni,p_tipo_tributo,p_tipo_recapito,
                                p_data_val,p_campo);
  -- Se il risultato della funzione è -1 oppure uno spazio
  -- si sostituisce con null in attesa di correggere tutti
  -- i richiami della funzione nella varie procedure, per
  -- evitare di avere numeri civici o interni valorizzati a -1.
  if w_recapito in ('-1',' ') then
     w_recapito := null;
  end if;
  RETURN w_recapito;
END;
/* End Function: F_RECAPITO */
/

