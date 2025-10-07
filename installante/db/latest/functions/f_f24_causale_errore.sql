--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_f24_causale_errore stripComments:false runOnChange:true 
 
create or replace function F_F24_CAUSALE_ERRORE
/*************************************************************************
 NOME:        F_F24_CAUSALE_ERRORE
 DESCRIZIONE: Dato un numero pratica negativo e il tipo di risultato che
              si vuole ottenere, restituisce il codice o la descrizione
              dell'errore rilevato.
 RITORNA:     varchar2              Codice o descrizione errore
 NOTE:        Se il tipo campo passato è "C" restituisce il codice,
              altrimenti restituisce l'errore
 Rev.    Date         Author      Note
 000     25/09/2018   VD          Prima emissione.
*************************************************************************/
(p_pratica            number
,p_tipo_campo         varchar2
)
  return varchar2
is
  w_causale           varchar2(2000);
begin
  if p_tipo_campo = 'C' then    -- codice
     select decode(p_pratica,-1,'50350'
                            ,-2,'50351'
                            ,-3,'50352'
                            ,-4,'50050'
                            ,-5,'50360'
                            ,-6,'50361'
                            ,-7,'50362'
                               ,null)
       into w_causale
       from dual;
  else
     select decode(p_pratica,-1,'Versamento su violazione: Pratica non presente o incongruente'
                            ,-2,'Versamento su Violazione: Data Pagamento precedente a Data Notifica'
                            ,-3,'Versamento su Violazione: Pratica non Notificata'
                            ,-4,'Denuncia non presente o incongruente'
                            ,-5,'Pratica rateizzata: Versamento antecedente alla data rateazione'
                            ,-6,'Pratica rateizzata: Rata non prevista'
                            ,-7,'Pratica rateizzata: Rata gia'' versata'
                               ,null)
       into w_causale
       from dual;
  end if;
--
  return w_causale;
--
end;
/* End Function: F_F24_CAUSALE_ERRORE */
/

