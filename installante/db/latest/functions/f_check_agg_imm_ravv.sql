--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_check_agg_imm_ravv stripComments:false runOnChange:true 
 
create or replace function F_CHECK_AGG_IMM_RAVV
/*************************************************************************
 NOME:        F_CHECK_AGG_IMM_RAVV
 DESCRIZIONE: Controlla i dati del ravvedimento da aggiornare:
              - se esistono deog o alog per gli oggetti_contribuente
              - se esistono sanzioni_pratica
 PARAMETRI:   p_pratica           Numero pratica del ravvedimento
 RITORNA:     Messaggio di errore; se null la pratica si può aggiornare
 NOTE:
 Rev.    Date         Author      Note
 000     28/09/2020   VD          Prima emissione
*************************************************************************/
( a_pratica                number
) return varchar2
is
  w_messaggio              varchar2(2000);
  w_conta_alog             number;
  w_conta_deog             number;
  w_conta_sapr             number;
begin
  -- Si verifica l'esistenza di aliquote_ogco
  select count(*)
    into w_conta_alog
    from aliquote_ogco alog
   where (alog.cod_fiscale,alog.oggetto_pratica) in
         (select prtr.cod_fiscale, ogpr.oggetto_pratica
            from pratiche_tributo prtr,
                 oggetti_pratica  ogpr
           where prtr.pratica = a_pratica);
  -- Si verifica l'esistenza di detrazioni_ogco
  select count(*)
    into w_conta_deog
    from detrazioni_ogco deog
   where (deog.cod_fiscale,deog.oggetto_pratica,deog.anno) in
         (select prtr.cod_fiscale, ogpr.oggetto_pratica, prtr.anno
            from pratiche_tributo prtr,
                 oggetti_pratica  ogpr
           where prtr.pratica = a_pratica);
  -- Si verifica l'esistenza di sanzioni_pratica
  select count(*)
    into w_conta_sapr
    from sanzioni_pratica sapr
   where sapr.pratica = a_pratica;
  -- Composizione messaggio di errore
   if nvl(w_conta_alog,0) > 0 or
      nvl(w_conta_deog,0) > 0 or
      nvl(w_conta_sapr,0) > 0 then
      w_messaggio := 'Esistono ';
      if nvl(w_conta_alog,0) > 0 then
         w_messaggio := w_messaggio||'Aliquote Oggetto/';
      end if;
      if nvl(w_conta_deog,0) > 0 then
         w_messaggio := w_messaggio||'Detrazioni Oggetto/';
      end if;
      if nvl(w_conta_sapr,0) > 0 then
         w_messaggio := w_messaggio||'Sanzioni';
      end if;
      w_messaggio := rtrim(w_messaggio,'/')||' per il ravvedimento';
   end if;
--
  return w_messaggio;
--
end;
/* End Function: F_CHECK_AGG_IMM_RAVV */
/

