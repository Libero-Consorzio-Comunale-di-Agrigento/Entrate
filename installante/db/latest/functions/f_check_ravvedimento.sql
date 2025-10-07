--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_check_ravvedimento stripComments:false runOnChange:true 
 
create or replace function F_CHECK_RAVVEDIMENTO
/*************************************************************************
 NOME:        F_CHECK_RAVVEDIMENTO
 DESCRIZIONE: Confronta il versato di imposta su ravvedimento con l'imposta
              dovuta per l'anno, tenendo conto di un'eventuale percentuale
              di scostamento.
 PARAMETRI:   p_cod_fiscale       Codice fiscale del contribuente da
                                  trattare
              p_anno              Anno di riferimento
              p_tipo_tributo      Tipo tributo da trattare
              p_tipo_imposta      Tipo imposta da calcolare:
                                  A - Acconto
                                  S - Saldo
                                  Null - Totale annuo
              p_perc_scostamento  Percentuale di scostamento del versato
                                  su ravvedimento rispetto all'imposta
                                  dovuta, entro la quale il ravvedimento
                                  viene considerato corretto (sia in positivo
                                  che in negativo)
 RITORNA:     0 - Il versato su ravvedimento e' congruente con l'imposta
                  dovuta
              1 - Il versato su ravvedimento è inferiore all'imposta
                  dovuta
 NOTE:
 Rev.    Date         Author      Note
 000     11/05/2020   VD          Prima emissione
*************************************************************************/
( p_cod_fiscale            varchar2
, p_anno                   number
, p_tipo_tributo           varchar2
, p_tipo_imposta           varchar2
, p_perc_scostamento       number default null
) return number
is
  w_perc_scostamento       number;
  w_conto_corrente         number;
  w_imposta_dovuta         number;
  w_versamenti             number;
  w_versamenti_ravv        number;
  w_perc_calcolata         number;
  w_result                 number;
begin
  if p_perc_scostamento is null then
     w_perc_scostamento := nvl(f_inpa_valore('PERC_RAVV'),0);
  else
     w_perc_scostamento := p_perc_scostamento;
  end if;
-- Calcolo imposta dovuta
  w_imposta_dovuta := F_IMPOSTA_CONT_ANNO_TITR_AS ( p_cod_fiscale
                                                  , p_anno
                                                  , p_tipo_tributo
                                                  , p_tipo_imposta
                                                  );
-- Calcolo versamenti effettuati
  w_versamenti := F_IMPORTO_VERS_AS ( p_cod_fiscale
                                    , p_anno
                                    , p_tipo_tributo
                                    , p_tipo_imposta
                                    );
-- Calcolo versamenti su ravvedimento
  w_versamenti_ravv := F_IMPORTO_VERS_RAVV ( p_cod_fiscale
                                           , p_tipo_tributo
                                           , p_anno
                                           , p_tipo_imposta
                                           );
--
  if nvl(w_versamenti_ravv,0) < nvl(w_imposta_dovuta,0) - nvl(w_versamenti,0) then
     if nvl(w_imposta_dovuta,0) <> 0 then
        w_perc_calcolata := round((nvl(w_imposta_dovuta,0) - nvl(w_versamenti,0) -
                                   nvl(w_versamenti_ravv,0)) *
                                  100 / nvl(w_imposta_dovuta,0),2);
        if abs(w_perc_calcolata) > abs(w_perc_scostamento) then
           w_result := 1;
        else
           w_result := 0;
        end if;
     else
        w_result := 1;
     end if;
  else
    w_result := 0;
  end if;
--
  return w_result;
--
end;
/* End Function: F_CHECK_RAVVEDIMENTO */
/

