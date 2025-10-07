--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_get_descr_errore stripComments:false runOnChange:true 
 
create or replace function F_GET_DESCR_ERRORE
/*************************************************************************
 NOME:        F_GET_DESCR_ERRORE
 DESCRIZIONE: Dato un codice di errore del caricamento versamenti da F24
              e il tipo di risultato che si vuole ottenere,restituisce
              la relativa descrizione o il flag di visualizzazione
              dell'identificativo operazion.
 RITORNA:     varchar2              Descrizione errore
 NOTE:        Se il tipo campo passato è "D" restituisce la descrizione,
              altrimenti restituisce il flag per visualizzare o meno
              l'identificativo operazione
 Rev.    Date         Author      Note
 001     12/10/2020   VD          Aggiunta nuova causale:
                                  50190 - Errore in creazione pratica di ravvedimento
 000     02/10/2018   VD          Prima emissione.
*************************************************************************/
(p_causale                        varchar2
,p_tipo_campo                     varchar2
)
  return varchar2
is
  w_return                        varchar2(2000);
begin
  if p_tipo_campo = 'D' then
     select decode(p_causale,'50000','Versamento gia'' Presente'
                            ,'50009','Contribuente sconosciuto'
                            ,'50010','Contribuente non Attivo'
                            ,'50050','Denuncia non presente'
                            ,'50100','Versamento su Ravvedimento gia` Presente'
                            ,'50109','Versamento su Ravvedimento: Contribuente sconosciuto'
                            ,'50150','Versamento su Ravvedimento: Pratica di Ravvedimento non Presente'
                            ,'50180','Versamento su Ravvedimento: Più di una Pratica di Ravvedimento Presente'
                            ,'50200','Versamento con codici violazione senza Ravvedimento'
                            ,'50300','Versamento con codici violazione già Presente'
                            ,'50309','Versamento con codici violazione: Contribuente sconosciuto'
                            ,'50350','Versamento con codici violazione: Pratica non presente o incongruente'
                            ,'50351','Versamento con codici violazione: Data Pagamento precedente a Data Notifica'
                            ,'50352','Versamento con codici violazione: Pratica non Notificata'
                            ,'50360','Pratica rateizzata: Versamento antecedente alla data rateazione'
                            ,'50361','Pratica rateizzata: Rata errata'
                            ,'50362','Pratica rateizzata: Rata gia'' versata'
                            ,'50400','Annullamento delega: Versamento gia` Presente'
                            ,'50409','Annullamento delega: Contribuente sconosciuto'
                            ,'50190','Errore in creazione pratica di ravvedimento'
                                    ,null
                  )
       into w_return
       from dual;
  else
     select decode(p_causale,'50000','N'
                            ,'50009','N'
                            ,'50010','S'
                            ,'50050','S'
                            ,'50100','N'
                            ,'50109','N'
                            ,'50150','S'
                            ,'50180','S'
                            ,'50200','S'
                            ,'50300','N'
                            ,'50309','N'
                            ,'50350','S'
                            ,'50351','S'
                            ,'50352','S'
                            ,'50360','S'
                            ,'50361','S'
                            ,'50362','S'
                            ,'50400','N'
                            ,'50409','N'
                            ,'50190','S'
                                    ,null
                  )
       into w_return
       from dual;
  end if;
--
  return w_return;
--
end;
/* End Function: F_GET_DESCR_ERRORE */
/

