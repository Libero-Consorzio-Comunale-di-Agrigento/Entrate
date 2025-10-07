--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_f24_get_imposta stripComments:false runOnChange:true 
 
create or replace function F_F24_GET_IMPOSTA
/*************************************************************************
 NOME:        F_F24_GET_IMPOSTA
 DESCRIZIONE: Calcola gli importi da esporre sull'F24 per il contribuente,
              l'anno e il tipo tributo indicati.
              L'importo viene calcolato tenendo conto anche del tipo
              occupazione e del tipo di imposta che si vuole trattare.
 RITORNA:     number              Imposta annuale
 NOTE:        Utilizzata in PB per F24 TARSU/TOSAP/ICP dalla funzione
              "Situazione contribuente".
 Rev.    Date         Author      Note
 000     29/09/2019   VD          Prima emissione.
*************************************************************************/
( p_cod_fiscale            varchar2
, p_anno                   number
, p_tipo_tributo           varchar2
, p_tipo_occupazione       varchar2
, p_tipo_imposta           varchar2
)
return number
is
  w_descr_titr             varchar2(5);
  w_imposta_perm           number;
  w_imposta_temp           number;
  w_imposta                number;
begin
  select f_descrizione_titr(wrkp.tipo_tributo,wrkp.anno) descr_tipo_tributo,
         sum(decode(p_tipo_imposta,'A',decode(anno,p_anno,imposta_perm,0)
                                  ,'P',decode(anno,0,p_anno,imposta_perm)
                                      ,imposta_perm)) imposta_perm,
         sum(decode(p_tipo_imposta,'A',decode(anno,p_anno,imposta_temp,0)
                                  ,'P',decode(anno,0,p_anno,imposta_temp)
                                      ,imposta_temp)) imposta_temp,
         sum(imposta) imposta
    into w_descr_titr,
         w_imposta_perm,
         w_imposta_temp,
         w_imposta
    from
   (select prtr.tipo_tributo
          ,ogim.anno
          ,ogim.imposta
          ,decode(tipo_occupazione,'P',ogim.imposta,null) imposta_perm
          ,decode(tipo_occupazione,'T',ogim.imposta,null) imposta_temp
      from oggetti_imposta ogim
          ,oggetti_pratica ogpr
          ,pratiche_tributo prtr
     where ogim.cod_fiscale = p_cod_fiscale
       and ogim.oggetto_pratica = ogpr.oggetto_pratica
       and ogpr.pratica = prtr.pratica
       and (prtr.tipo_pratica = 'D'
         or (prtr.tipo_pratica = 'A'
         and ogim.anno > prtr.anno))
       and (prtr.tipo_tributo not in ('ICI', 'TASI','TARSU')
           or (prtr.tipo_tributo ||'' = 'TARSU'
              and not exists (select 'x'
                              from   ruoli ruol
                              where  ruol.ruolo =  ogim.ruolo)))) wrkp
   where wrkp.tipo_tributo = p_tipo_tributo
     and wrkp.anno         = p_anno;
--
  if p_tipo_occupazione = 'P' then
     return w_imposta_perm;
  elsif
     p_tipo_occupazione = 'T' then
     return w_imposta_temp;
  else
     return w_imposta;
  end if;
end;
/* End Function: F_F24_GET_IMPOSTA */
/

