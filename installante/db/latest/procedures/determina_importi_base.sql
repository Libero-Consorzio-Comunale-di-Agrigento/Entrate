--liquibase formatted sql 
--changeset abrandolini:20250326_152423_determina_importi_base stripComments:false runOnChange:true 
 
create or replace procedure DETERMINA_IMPORTI_BASE
/*************************************************************************
 NOME:        DETERMINA_IMPORTI_BASE
 DESCRIZIONE: Determinazione degli importi a ruolo calcolati con la
              tariffa base
 NOTE:
 Rev.    Date         Author      Note
 000     24/10/2018   VD          Prima emissione.
*************************************************************************/
( p_cod_fiscale                       varchar2
, p_anno_ruolo                        number
, p_ruolo                             number
, p_tributo                           number
, p_categoria                         number
, p_tipo_tariffa_base                 number
, p_flag_normalizzato                 varchar2
, p_consistenza                       number
, p_perc_possesso                     number
, p_periodo                           number
, p_data_decorrenza                   date
, p_data_cessazione                   date
, p_flag_ab_principale                varchar2
, p_numero_familiari                  number
, p_importo_base                  out number
, p_importo_pf_base               out number
, p_importo_pv_base               out number
, p_stringa_familiari_base        out varchar2
, p_dettaglio_ogim_base           out varchar2
, p_giorni_ruolo                  out number
)
is
  w_tariffa_base                  number;
  w_limite_base                   number;
  w_tariffa_superiore_base        number;
  w_perc_riduzione_base           number;
  w_importo_base                  number;
  w_importo_pf_base               number;
  w_importo_pv_base               number;
  w_stringa_familiari_base        varchar2(2000);
  w_dettaglio_ogim_base           varchar2(2000);
  w_errore                        varchar2(2000);
  errore                          exception;
begin
  --
  -- Si selezionano i dati della tariffa base
  --
  begin
    select tari.tariffa
          ,tari.limite
          ,tari.tariffa_superiore
          ,nvl(tari.perc_riduzione,0)
      into w_tariffa_base
         , w_limite_base
         , w_tariffa_superiore_base
         , w_perc_riduzione_base
      from tariffe tari
     where tari.tributo = p_tributo
       and tari.categoria = p_categoria
       and tari.anno = p_anno_ruolo
       and tari.tipo_tariffa = p_tipo_tariffa_base;
  exception
    WHEN no_data_found THEN
         w_errore := 'Tariffa base '||p_tipo_tariffa_base||' non presente in tabella';
         RAISE errore;
    WHEN others THEN
         w_errore := 'Errore in ricerca tariffa base ('||p_tipo_tariffa_base||')';
         RAISE errore;
  end;
  --
  -- Determinazione importi
  --
  IF p_flag_normalizzato is null THEN
     IF p_consistenza < w_limite_base
     or w_limite_base is NULL THEN
        w_importo_base := p_consistenza * w_tariffa_base;
     ELSE
        w_importo_base := w_limite_base * w_tariffa_base +
                          (p_consistenza - w_limite_base) * w_tariffa_superiore_base;
     END IF;
     w_importo_base := f_round(w_importo_base * (nvl(p_perc_possesso,100) / 100)
                                              * p_periodo,1
                              );
     w_importo_pf_base := to_number(null);
     w_importo_pv_base := to_number(null);
     w_stringa_familiari_base := '';
     w_dettaglio_ogim_base := '';
  ELSE
  -- Calcolo normalizzato per la tariffa base
     calcolo_importo_normalizzato(p_cod_fiscale
                                 ,null   --  ni
                                 ,p_anno_ruolo
                                 ,p_tributo
                                 ,p_categoria
                                 ,p_tipo_tariffa_base
                                 ,w_tariffa_base
                                 ,to_number(null) -- così usa la tariffa di carichi_tarsu
                                 ,p_consistenza
                                 ,p_perc_possesso
                                 ,p_data_decorrenza
                                 ,p_data_cessazione    --rec_ogpr.data_cessazione
                                 ,p_flag_ab_principale
                                 ,p_numero_familiari
                                 ,p_ruolo
                                 ,w_importo_base
                                 ,w_importo_pf_base
                                 ,w_importo_pv_base
                                 ,w_stringa_familiari_base
                                 ,w_dettaglio_ogim_base
                                 ,p_giorni_ruolo
                                 ,to_number(null)
                                 ,'S'
                                 );
  END IF;
  --
  p_importo_base                  := w_importo_base;
  p_importo_pf_base               := w_importo_pf_base;
  p_importo_pv_base               := w_importo_pv_base;
  p_stringa_familiari_base        := w_stringa_familiari_base;
  p_dettaglio_ogim_base           := w_dettaglio_ogim_base;
end;
/* End Procedure: DETERMINA_IMPORTI_BASE */
/

