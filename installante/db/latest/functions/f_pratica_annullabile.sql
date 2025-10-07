--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_pratica_annullabile stripComments:false runOnChange:true 
 
create or replace function F_PRATICA_ANNULLABILE
( p_pratica                 number
)
  return varchar2
is
  w_messaggio               varchar2(2000);
  w_tipo_evento             varchar2(1);
  w_data_pratica            date;
  w_conta_ogpr              number;
/******************************************************************************
 Utilizzata in fase di annullamento pratica: se la pratica da annullare e' di
 iscrizione, si verifica che non esistano pratiche di variazioni/cessazioni
 successive (segnalazione bloccante).
 Se la pratica da annullare e' di variazione, si controlla che non esistano
 pratiche di variazione o cessazione successive (segnalazione non bloccante).
 Il tipo di segnalazione e' identificato dai primi 3 caratteri del messaggio:
 - CON: segnalazione non bloccante
 - ERR: segnalazione bloccante
 Versione  Data              Autore    Descrizione
 1         05/06/2015        VD        Prima emissione
******************************************************************************/
begin
  begin
    select tipo_evento
         , data
      into w_tipo_evento
         , w_data_pratica
      from pratiche_tributo
     where pratica = p_pratica;
  exception
    when others then
      w_messaggio := 'Pratica non presente';
  end;
--
  if w_tipo_evento = 'C' then
     w_messaggio := null;
  elsif
     w_tipo_evento = 'V' then
     select count(*)
       into w_conta_ogpr
       from oggetti_pratica ogpr
          , oggetti_pratica ogpr2
          , pratiche_tributo prtr2
      where ogpr.pratica = p_pratica
        and ogpr.oggetto_pratica_rif = ogpr2.oggetto_pratica_rif
        and ogpr2.pratica = prtr2.pratica
        and prtr2.tipo_evento in ('V','C')
        and prtr2.data > w_data_pratica
        and flag_annullamento is null;
     if w_conta_ogpr > 0 then
        w_messaggio := 'CONEsistono pratiche di variazione o cessazione successive';
     else
        w_messaggio := null;
     end if;
  else
     select count(*)
       into w_conta_ogpr
       from oggetti_pratica ogpr
          , oggetti_pratica ogpr2
          , pratiche_tributo prtr2
      where ogpr.pratica = p_pratica
        and ogpr.oggetto_pratica = ogpr2.oggetto_pratica_rif
        and ogpr2.pratica = prtr2.pratica
        and flag_annullamento is null;
     if w_conta_ogpr > 0 then
        w_messaggio := 'ERRPratica non annullabile - Esistono pratiche di variazione o cessazione';
     else
        w_messaggio := null;
     end if;
  end if;
  return w_messaggio;
end;
/* End Function: F_PRATICA_ANNULLABILE */
/

