--liquibase formatted sql 
--changeset abrandolini:20250326_152423_calcolo_sgravio stripComments:false runOnChange:true 
 
create or replace procedure CALCOLO_SGRAVIO
/******************************************************************************
 Rev. Data       Autore Descrizione
 ---- ---------- ------ ------------------------------------------------------
  11  20/12/2024 RV     #71531
                        Revisione per Componenti Perequative
  10  27/02/2019 VD     Modificato calcolo importo normalizzato per
                        importi calcolati con tariffa
  9   20/11/2018 VD     Corretto calcolo per Bovezzo
                        Aggiunta nota se il risultato del calcolo e' zero.
  8   02/11/2018 VD     Aggiunta gestione importi calcolati con tariffa base
  7   18/07/2016 VD     Annullate modifiche del 22/01/2016
  6   06/07/2016 AB     Gestito w_gg_anno contenente i gg dell'anno
                        sulla base dell'ultimo giorno del mese di Febbraio
  5   22/01/2016 VD     Corretta emissione sgravi con mesi a zero (oggetti
                        non piu posseduti)
  4   18/06/2015 AB     Sistemata la ricerca del max(ogpr) per OGPR_SGRAVIO
  3   05/06/2015 VD     Aggiunta gestione nuovo campo IMPOSTA_DOVUTA in
                        tabella SGRAVI
  2   20/04/2015 VD     Aggiunta gestione nuova tabella FAMILIARI_SGRA e
                        nuovo campo DETTAGLIO_SGRA in tabella SGRAVI.
  1   22/09/2014 PM     Inserito il calcolo per giorni nel Tradizionale
                        solo per San Lazzaro
******************************************************************************/
 (a_cod_fiscale          IN       varchar2,
  a_ruolo                IN       number,
  a_sequenza             IN       number,
  a_motivo               IN       number,
  a_oggetto_pratica      IN       number,
  a_calcolo_normalizzato IN       varchar2,
  a_importo_sgravio      IN OUT   number,
  a_nota                 IN OUT   varchar2,
  a_tipo_sgravio         IN       varchar2
)
IS
  w_perc_add_eca                  number;
  w_perc_magg_eca                 number;
  w_perc_add_pro                  number;
  w_perc_iva                      number;
  w_perc_magg_tares               number;
  w_flag_magg_anno                varchar2(1);
  w_importo_lordo                 varchar2(1);
  w_consistenza_r                 number;
  w_perc_poss_r                   number;
  w_punto_raccolta_r              varchar2(1);
  w_tariffa_r                     number;
  w_limite_r                      number;
  w_tari_sup_r                    number;
  w_perc_riduzione                number;
  w_data_decorrenza_r             date;
  w_importo_r                     number;
  w_add_eca_r                     number;
  w_magg_eca_r                    number;
  w_magg_tares_r                  number;
  w_add_pro_r                     number;
  w_iva_r                         number;
  w_imp_sgravi                    number;
  w_tipo_ruolo                    number;
  w_anno_ruolo                    number;
  w_tipo_emissione                varchar2(1);
  w_consistenza                   number;
  w_tributo                       number;
  w_categoria                     number;
  w_tipo_tariffa                  number;
  w_numero_familiari              number;
  w_tariffa                       number;
  w_limite                        number;
  w_tari_sup                      number;
  w_tari_quota_fissa              number;
  w_perc_poss                     number;
  w_flag_ab_principale            varchar2(1);
  w_punto_raccolta                varchar2(1);
  w_data_decorrenza               date;
  w_data_cessazione               date;
  w_tipo_evento                   varchar2(1);
  w_tipo_evento_rif               varchar2(1);
  w_oggetto_pratica_rif           number;
  w_periodo                       number;
  w_importo                       number;
  w_add_eca                       number;
  w_magg_eca                      number;
  w_magg_tares                    number;
  w_add_pro                       number;
  w_iva                           number;
  w_tot_add                       number;
  w_tot_add_altri                 number;
  w_tot_importo                   number;
  w_tot_importo_r                 number;
  w_tot_add_r                     number;
  w_tot_importo_r_acc             number;
  w_tot_add_r_acc                 number;
  w_oggetto_pratica               number;
  w_oggetto_pratica_r             number;
  w_importo_ruolo                 number;
  w_magg_tares_ruolo              number;
  w_importo_sgravi_p              number;
  w_add_sgravi_p                  number;
  w_importo_sgravi_p_acc          number;
  w_add_sgravi_p_acc              number;
  w_importo_sgravi                number;
  w_add_eca_sgravi                number;
  w_magg_eca_sgravi               number;
  w_magg_tares_sgravi             number;
  w_add_pro_sgravi                number;
  w_iva_sgravi                    number;
  w_sequenza                      number;
  w_sequenza_sgravio              number;
  w_ordinamento                   number;
  w_flag                          number;
  w_tot_altri                     number;
  w_conta                         number;
  w_importo_r_acc                 number;
  w_add_eca_r_acc                 number;
  w_magg_eca_r_acc                number;
  w_magg_tares_r_acc              number;
  w_add_pro_r_acc                 number;
  w_iva_r_acc                     number;
  w_imp_sgravi_acc                number;
  w_add_eca_sgravi_acc            number;
  w_magg_eca_sgravi_acc           number;
  w_magg_tares_sgravi_acc         number;
  w_add_pro_sgravi_acc            number;
  w_iva_sgravi_acc                number;
  w_ogpr_sgra                     number;
  w_imposta_dovuta                number;
  w_tot_add_pro                   number;
  w_tot_add_eca                   number;
  w_tot_magg_eca                  number;
  w_tot_magg_tares                number;
  w_tot_iva                       number;
  w_tot_add_eca_r                 number;
  w_tot_magg_eca_r                number;
  w_tot_magg_tares_r              number;
  w_tot_add_pro_r                 number;
  w_tot_iva_r                     number;
  w_add_eca_sgravi_p              number;
  w_magg_eca_sgravi_p             number;
  w_magg_tares_sgravi_p           number;
  w_add_pro_sgravi_p              number;
  w_iva_sgravi_p                  number;
  w_tot_add_eca_r_acc             number;
  w_tot_magg_eca_r_acc            number;
  w_tot_magg_tares_r_acc          number;
  w_tot_add_pro_r_acc             number;
  w_tot_iva_r_acc                 number;
  w_add_eca_sgravi_p_acc          number;
  w_magg_eca_sgravi_p_acc         number;
  w_magg_tares_sgravi_p_acc       number;
  w_add_pro_sgravi_p_acc          number;
  w_iva_sgravi_p_acc              number;
  w_importo_pf                    number;
  w_importo_pv                    number;
  w_stringa_familiari             varchar2(2000);
  w_dettaglio_sgra                varchar2(2000);
  w_dettaglio_fasg                varchar2(2000);
  w_mesi_fasg                     number;
  w_mesi_fasg_2sem                number;
  w_cod_istat                     varchar2(6);
  w_tipo_tributo                  varchar2(5);
  w_da_trattare                   boolean;
  w_progr_emissione               number;
  w_da_mese_sgravio               number;
  w_a_mese_sgravio                number;
  w_ruolo_sgra                    number;
  w_mesi                          number  := 0;
  w_imp_scalare                   number;
  w_giorni_ruolo                  number;
  w_mesi_calcolo                  number;
-- (VD - 18/07/2016): annullamento modifiche del 22/01/2016
--  w_mesi_r                        number;
--  w_giorni_r                      number;
--  w_da_mese_r                     number;
--  w_a_mese_r                      number;
  errore                          exception;
  fine                            exception;
  w_errore                        varchar2(2000);
  w_gg_anno                       number;
-- (VD - 23/10/2018): Variabili per calcolo importi con tariffa base
  w_flag_tariffa_base             varchar2(1);
  w_tipo_tariffa_base             number;
  w_tariffa_domestica             number;
  w_tariffa_non_domestica         number;
  w_tariffa_base                  number;
  w_limite_base                   number;
  w_tariffa_superiore_base        number;
  w_perc_riduzione_base           number;
  w_importo_base                  number;
  w_importo_pf_base               number;
  w_importo_pv_base               number;
  w_add_eca_base                  number;
  w_magg_eca_base                 number;
  w_add_pro_base                  number;
  w_iva_base                      number;
  w_tot_add_pro_base              number;
  w_tot_add_eca_base              number;
  w_tot_magg_eca_base             number;
  w_tot_iva_base                  number;
  w_tot_add_base                  number;
  w_tot_importo_base              number;
  w_importo_r_base                number;
  w_add_eca_r_base                number;
  w_magg_eca_r_base               number;
  w_add_pro_r_base                number;
  w_iva_r_base                    number;
  w_imp_sgravi_base               number;
  w_add_eca_sgravi_base           number;
  w_magg_eca_sgravi_base          number;
  w_add_pro_sgravi_base           number;
  w_iva_sgravi_base               number;
  w_importo_r_acc_base            number;
  w_add_eca_r_acc_base            number;
  w_magg_eca_r_acc_base           number;
  w_add_pro_r_acc_base            number;
  w_iva_r_acc_base                number;
  w_imp_sgravi_acc_base           number;
  w_add_eca_sgravi_acc_base       number;
  w_magg_eca_sgravi_acc_base      number;
  w_add_pro_sgravi_acc_base       number;
  w_iva_sgravi_acc_base           number;
  w_importo_sgravi_p_base         number;
  w_add_sgravi_p_base             number;
  w_importo_sgravi_p_acc_base     number;
  w_add_sgravi_p_acc_base         number;
  w_importo_ruolo_base            number;
  w_importo_sgravi_base           number;
  w_imp_scalare_base              number;
  w_importo_sgravio_base          number;
  w_tot_importo_r_base            number;
  w_tot_add_r_base                number;
  w_tot_importo_r_acc_base        number;
  w_tot_add_r_acc_base            number;
  w_stringa_familiari_base        varchar2(2000);
  w_dettaglio_sgra_base           varchar2(2000);
  w_dettaglio_fasg_base           varchar2(2000);
-- (VD - 31/01/2019): Variabili per calcolo importi con tariffe
  w_flag_tariffe_ruolo            varchar2(1);
  w_perc_rid_pf                   number;
  w_perc_rid_pv                   number;
  w_importo_pf_rid                number;
  w_importo_pv_rid                number;
-- #71531 - Componenti Perequative
  w_magg_tares_cope               number;
  w_coeff_gg                      number;
  w_tot_importo_sgravi            number;
--------------------------------------------------
cursor rec_ruol is
select ruco.consistenza w_consistenza_r,
       ogco.perc_possesso w_perc_poss_r,
       ogco.flag_punto_raccolta w_punto_raccolta_r,
       tari.tariffa w_tariffa_r,
       tari.limite w_limite_r,
       tari.tariffa_superiore w_tari_sup_r,
       ogco.data_decorrenza w_data_decorrenza_r,
       ogim.imposta w_importo_r,
       nvl(ogim.addizionale_eca,0) w_add_eca_r,
       nvl(ogim.maggiorazione_eca,0) w_magg_eca_r,
   --  decode(a_tipo_sgravio,'R',0,nvl(ogim.maggiorazione_tares,0)) w_magg_tares_r,  -- #71531 tolto, puo' fare confusione
         nvl(ogim.maggiorazione_tares,0) w_magg_tares_r,
       nvl(ogim.addizionale_pro,0) w_add_pro_r,
       nvl(ogim.iva,0) w_iva_r,
       ogpr.tributo w_tributo,
       ogpr.categoria w_categoria,
       nvl(sum(nvl(sgra.importo,0) - nvl(sgra.addizionale_eca,0)
                                   - nvl(sgra.maggiorazione_eca,0)
                                   - nvl(sgra.addizionale_pro,0)
                                   - nvl(sgra.iva,0)
                                   - nvl(sgra.maggiorazione_tares,0)
              ),0
          ) w_imp_sgravi,
       nvl(sum(nvl(sgra.addizionale_eca,0)),0) add_eca_sgravi,
       nvl(sum(nvl(sgra.maggiorazione_eca,0)),0) magg_eca_sgravi,
   --  nvl(decode(a_tipo_sgravio,'R',0,sum(nvl(sgra.maggiorazione_tares,0))),0) magg_tares_sgravi,  -- #71531 come sopra
         sum(nvl(sgra.maggiorazione_tares,0)) magg_tares_sgravi,
       nvl(sum(nvl(sgra.addizionale_pro,0)),0) add_pro_sgravi,
       nvl(sum(nvl(sgra.iva,0)),0) iva_sgravi,
       -- (VD - 02/11/2018): aggiunta gestione importi calcolati con tariffa base
       ogim.imposta_base w_importo_base_r,
       nvl(ogim.addizionale_eca_base,0) w_add_eca_base_r,
       nvl(ogim.maggiorazione_eca_base,0) w_magg_eca_base_r,
       nvl(ogim.addizionale_pro_base,0) w_add_pro_base_r,
       nvl(ogim.iva_base,0) w_iva_base_r,
       nvl(sum(nvl(sgra.importo_base,0) - nvl(sgra.addizionale_eca_base,0)
                                        - nvl(sgra.maggiorazione_eca_base,0)
                                        - nvl(sgra.addizionale_pro_base,0)
                                        - nvl(sgra.iva_base,0)
              ),0
          ) w_imp_sgravi_base,
       nvl(sum(nvl(sgra.addizionale_eca_base,0)),0) add_eca_sgravi_base,
       nvl(sum(nvl(sgra.maggiorazione_eca_base,0)),0) magg_eca_sgravi_base,
       nvl(sum(nvl(sgra.addizionale_pro_base,0)),0) add_pro_sgravi_base,
       nvl(sum(nvl(sgra.iva_base,0)),0) iva_sgravi_base,
       --
       to_number('') w_importo_r_acc,
       to_number('') w_add_eca_r_acc,
       to_number('') w_magg_eca_r_acc,
       to_number('') w_magg_tares_r_acc,
       to_number('') w_add_pro_r_acc,
       to_number('') w_iva_r_acc,
       to_number('') w_imp_sgravi_acc,
       to_number('') w_add_eca_sgravi_acc,
       to_number('') w_magg_eca_sgravi_acc,
       to_number('') w_magg_tares_sgravi_acc,
       to_number('') w_add_pro_sgravi_acc,
       to_number('') w_iva_sgravi_acc,
       -- (VD - 02/11/2018): aggiunta gestione importi calcolati con tariffa base
       to_number('') w_importo_r_acc_base,
       to_number('') w_add_eca_r_acc_base,
       to_number('') w_magg_eca_r_acc_base,
       to_number('') w_add_pro_r_acc_base,
       to_number('') w_iva_r_acc_base,
       to_number('') w_imp_sgravi_acc_base,
       to_number('') w_add_eca_sgravi_acc_base,
       to_number('') w_magg_eca_sgravi_acc_base,
       to_number('') w_add_pro_sgravi_acc_base,
       to_number('') w_iva_sgravi_acc_base
       --
       -- (VD - 22/01/2016): selezione dati ruolo per eventuali oggetti
       --                    non piu posseduti
       --
       -- (VD - 18/07/2016): annullate modifiche precedenti
       --       ruco.mesi_ruolo,
       --       ruco.giorni_ruolo,
       --       ruco.da_mese,
       --       ruco.a_mese
  from tariffe              tari,
       oggetti_contribuente ogco,
       oggetti_pratica      ogpr,
       sgravi               sgra,
       oggetti_imposta      ogim,
       ruoli_contribuente   ruco
 where tari.tipo_tariffa       = ogpr.tipo_tariffa
   and tari.categoria          = ogpr.categoria
   and tari.tributo            = ogpr.tributo
   and tari.anno               = w_anno_ruolo
   and ogco.cod_fiscale        = ogim.cod_fiscale
   and ogco.oggetto_pratica    = ogim.oggetto_pratica
   and sgra.ruolo          (+) = ruco.ruolo
   and sgra.cod_fiscale    (+) = ruco.cod_fiscale
   and sgra.sequenza       (+) = ruco.sequenza
   and sgra.flag_automatico (+) = 'S'
   and ruco.ruolo              = a_ruolo
   and ruco.cod_fiscale        = a_cod_fiscale
   and ruco.oggetto_imposta    = ogim.oggetto_imposta
   and ogim.oggetto_pratica    = ogpr.oggetto_pratica
   and ogim.ruolo              = a_ruolo
   and nvl(ogpr.oggetto_pratica_rif,ogpr.oggetto_pratica)
                               = w_oggetto_pratica_r
 group by
       ruco.consistenza,
       ogco.perc_possesso,
       ogco.flag_punto_raccolta,
       tari.tariffa,
       tari.limite,
       tari.tariffa_superiore,
       ogco.data_decorrenza,
       ogim.imposta,
       nvl(ogim.addizionale_eca,0),
       nvl(ogim.maggiorazione_eca,0),
       nvl(ogim.addizionale_pro,0),
       nvl(ogim.iva,0),
       nvl(ogim.maggiorazione_tares,0),
       -- (VD - 02/11/2018): aggiunta gestione importi calcolati con tariffa base
       ogim.imposta_base,
       nvl(ogim.addizionale_eca_base,0),
       nvl(ogim.maggiorazione_eca_base,0),
       nvl(ogim.addizionale_pro_base,0),
       nvl(ogim.iva_base,0),
       --
       ogpr.oggetto_pratica,
       ogpr.tributo,
       ogpr.categoria
--       ruco.mesi_ruolo,
--       ruco.giorni_ruolo,
--       ruco.da_mese,
--       ruco.a_mese
union all
select to_number('') w_consistenza_r,
       to_number('') w_perc_poss_r,
       null as w_punto_raccolta_r,
       to_number('') w_tariffa_r,
       to_number('') w_limite_r,
       to_number('') w_tari_sup_r,
       to_date('') w_data_decorrenza_r,
       to_number('') w_importo_r,
       to_number('') w_add_eca_r,
       to_number('') w_magg_eca_r,
       to_number('') w_magg_tares_r,
       to_number('') w_add_pro_r,
       to_number('') w_iva_r,
       ogpr.tributo w_tributo,
       ogpr.categoria w_categoria,
       to_number('') w_imp_sgravi,
       to_number('') w_add_eca_sgravi,
       to_number('') w_magg_eca_sgravi,
       to_number('') w_magg_tares_sgravi,
       to_number('') w_add_pro_sgravi,
       to_number('') w_iva_sgravi,
       -- (VD - 02/11/2018): aggiunta gestione importi calcolati con tariffa base
       to_number('') w_importo_base_r,
       to_number('') w_add_eca_base_r,
       to_number('') w_magg_eca_base_r,
       to_number('') w_add_pro_base_r,
       to_number('') w_iva_base_r,
       to_number('') w_imp_sgravi_base,
       to_number('') w_add_eca_sgravi_base,
       to_number('') w_magg_eca_sgravi_base,
       to_number('') w_add_pro_sgravi_base,
       to_number('') w_iva_sgravi_base,
       --
       ogim.imposta w_importo_r_acc,
       nvl(ogim.addizionale_eca,0) w_add_eca_r_acc,
       nvl(ogim.maggiorazione_eca,0) w_magg_eca_r_acc,
   --  decode(a_tipo_sgravio,'R',0,nvl(ogim.maggiorazione_tares,0)) w_magg_tares_r_acc,  -- #71531 come sopra
         nvl(ogim.maggiorazione_tares,0) w_magg_tares_r_acc,
       nvl(ogim.addizionale_pro,0) w_add_pro_r_acc,
       nvl(ogim.iva,0) w_iva_r_acc,
       nvl(sum(nvl(sgra.importo,0) - nvl(sgra.addizionale_eca,0)
                                   - nvl(sgra.maggiorazione_eca,0)
                                   - nvl(sgra.addizionale_pro,0)
                                   - nvl(sgra.iva,0)
                                   - nvl(sgra.maggiorazione_tares,0)
              ),0
          ) w_imp_sgravi_acc,
       nvl(sum(nvl(sgra.addizionale_eca,0)),0) add_eca_sgravi_acc,
       nvl(sum(nvl(sgra.maggiorazione_eca,0)),0) magg_eca_sgravi_acc,
   --  nvl(decode(a_tipo_sgravio,'R',0,sum(nvl(sgra.maggiorazione_tares,0))),0) magg_tares_sgravi_acc,  -- #71531 come sopra
         sum(nvl(sgra.maggiorazione_tares,0)) magg_tares_sgravi_acc,
       nvl(sum(nvl(sgra.addizionale_pro,0)),0) add_pro_sgravi_acc,
       nvl(sum(nvl(sgra.iva,0)),0) iva_sgravi_acc,
       -- (VD - 02/11/2018): aggiunta gestione importi calcolati con tariffa base
       ogim.imposta_base w_importo_r_acc_base,
       nvl(ogim.addizionale_eca_base,0) w_add_eca_r_acc_base,
       nvl(ogim.maggiorazione_eca_base,0) w_magg_eca_r_acc_base,
       nvl(ogim.addizionale_pro_base,0) w_add_pro_r_acc_base,
       nvl(ogim.iva_base,0) w_iva_r_acc_base,
       nvl(sum(nvl(sgra.importo_base,0) - nvl(sgra.addizionale_eca_base,0)
                                        - nvl(sgra.maggiorazione_eca_base,0)
                                        - nvl(sgra.addizionale_pro_base,0)
                                        - nvl(sgra.iva_base,0)
              ),0
          ) w_imp_sgravi_acc_base,
       nvl(sum(nvl(sgra.addizionale_eca_base,0)),0) add_eca_sgravi_acc_base,
       nvl(sum(nvl(sgra.maggiorazione_eca_base,0)),0) magg_eca_sgravi_acc_base,
       nvl(sum(nvl(sgra.addizionale_pro_base,0)),0) add_pro_sgravi_acc_base,
       nvl(sum(nvl(sgra.iva_base,0)),0) iva_sgravi_acc_base
       --
--       to_number(''),       -- mesi ruolo
--       to_number(''),       -- giorni ruolo
--       to_number(''),       -- da mese ruolo
--       to_number('')        -- a mese ruolo
  from tariffe              tari,
       oggetti_contribuente ogco,
       oggetti_pratica      ogpr,
       sgravi               sgra,
       oggetti_imposta      ogim,
       ruoli_contribuente   ruco
 where tari.tipo_tariffa       = ogpr.tipo_tariffa
   and tari.categoria          = ogpr.categoria
   and tari.tributo            = ogpr.tributo
   and tari.anno               = w_anno_ruolo
   and ogco.cod_fiscale        = ogim.cod_fiscale
   and ogco.oggetto_pratica    = ogim.oggetto_pratica
   and sgra.ruolo          (+) = ruco.ruolo
   and sgra.cod_fiscale    (+) = ruco.cod_fiscale
   and sgra.sequenza       (+) = ruco.sequenza
   and sgra.flag_automatico (+) = 'S'
   and ruco.cod_fiscale        = a_cod_fiscale
   and ruco.oggetto_imposta    = ogim.oggetto_imposta
   and ogim.oggetto_pratica    = ogpr.oggetto_pratica
   and ogim.ruolo              = ruco.ruolo
   and ruco.ruolo              in (select ruol_prec.ruolo
                                   from   ruoli ruol_prec
                                   where  nvl(ruol_prec.tipo_emissione,'T')   = 'A'
                                   and ruol_prec.invio_consorzio is not null
                                   and ruol_prec.anno_ruolo       = w_anno_ruolo)
   and nvl(ogpr.oggetto_pratica_rif,ogpr.oggetto_pratica)
                               = w_oggetto_pratica_r
   and w_tipo_emissione        = 'S'
 group by
       ruco.consistenza,
       ogco.perc_possesso,
       tari.tariffa,
       tari.limite,
       tari.tariffa_superiore,
       ogco.data_decorrenza,
       ogim.imposta,
       nvl(ogim.addizionale_eca,0),
       nvl(ogim.maggiorazione_eca,0),
       nvl(ogim.addizionale_pro,0),
       nvl(ogim.iva,0),
       nvl(ogim.maggiorazione_tares,0),
       -- (VD - 02/11/2018): aggiunta gestione importi calcolati con tariffa base
       ogim.imposta_base,
       nvl(ogim.addizionale_eca_base,0),
       nvl(ogim.maggiorazione_eca_base,0),
       nvl(ogim.addizionale_pro_base,0),
       nvl(ogim.iva_base,0),
       --
       ogpr.oggetto_pratica,
       ogpr.tributo,
       ogpr.categoria
;
--------------------------------------------------
cursor rec_ogva is
select ogpr.consistenza,
       ogpr.tributo,
       ogpr.categoria,
       ogpr.tipo_tariffa,
       ogpr.numero_familiari,
       tari.tariffa,
       tari.limite,
       tari.tariffa_superiore,
       tari.tariffa_quota_fissa,
       ogco.perc_possesso,
       ogco.flag_ab_principale,
       ogco.flag_punto_raccolta,
       greatest(nvl(ogva.dal,to_date('01011900','ddmmyyyy'))
               ,to_date('0101'||lpad(to_char(ruol.anno_ruolo),4,'0'),'ddmmyyyy')
               ),
       least(nvl(ogva.al,to_date('31122999','ddmmyyyy'))
            ,to_date('3112'||lpad(to_char(ruol.anno_ruolo),4,'0'),'ddmmyyyy')
            ),
       ogva.tipo_evento,
       ruol.tipo_ruolo,
       ruol.progr_emissione,
       nvl(tari.perc_riduzione,0),
       -- (VD - 02/11/2018): aggiunta gestione importi calcolati con tariffa base
       f_get_tariffa_base(ogpr.tributo,ogpr.categoria,ruol.anno_ruolo) tipo_tariffa_base
  from tariffe              tari,
       oggetti_contribuente ogco,
       ruoli                ruol,
       oggetti_pratica      ogpr,
       oggetti_validita     ogva
 where tari.tipo_tariffa       = ogpr.tipo_tariffa
   and tari.categoria          = ogpr.categoria
   and tari.tributo            = ogpr.tributo
   and tari.anno               = ruol.anno_ruolo
   and ogpr.oggetto_pratica    = ogco.oggetto_pratica
   and ogco.cod_fiscale        = a_cod_fiscale
   and ogco.oggetto_pratica    = ogva.oggetto_pratica+0
   and ruol.ruolo              = a_ruolo
   and nvl(ogva.dal,to_date('01011900','ddmmyyyy'))
                              <= to_date('3112'||lpad(to_char(ruol.anno_ruolo),4,'0'),'ddmmyyyy')
   and nvl(ogva.al ,to_date('31122999','ddmmyyyy'))
                              >= to_date('0101'||lpad(to_char(ruol.anno_ruolo),4,'0'),'ddmmyyyy')
   and ogva.cod_fiscale        = a_cod_fiscale
   and ogva.tipo_tributo||''   = ruol.tipo_tributo
   and ogva.oggetto_pratica_rif
                               = w_oggetto_pratica_r
order by
      greatest(nvl(ogva.dal,to_date('01011900','ddmmyyyy'))
               ,to_date('0101'||lpad(to_char(ruol.anno_ruolo),4,'0'),'ddmmyyyy')
               )
;
--------------------------------------------------
cursor rec_sgra is
select 1,
       ruco.sequenza,
       ruco.ruolo,
       max(ogim.imposta),
       nvl(sum(nvl(sgra.importo,0) - nvl(sgra.addizionale_eca,0)
                                   - nvl(sgra.maggiorazione_eca,0)
                                   - nvl(sgra.addizionale_pro,0)
                                   - nvl(sgra.iva,0)
                                   - nvl(sgra.maggiorazione_tares,0)
              ),0
          ),
       max(nvl(tari.perc_riduzione,0)),
       max(ogim.maggiorazione_tares),
       sum(sgra.maggiorazione_tares),
       -- (VD - 02/11/2018): aggiunta gestione importi calcolati con tariffa base
       max(ogim.imposta_base),
       nvl(sum(nvl(sgra.importo_base,0) - nvl(sgra.addizionale_eca_base,0)
                                        - nvl(sgra.maggiorazione_eca_base,0)
                                        - nvl(sgra.addizionale_pro_base,0)
                                        - nvl(sgra.iva_base,0)
              ),0
          )
  from tariffe              tari,
       oggetti_pratica      ogpr,
       sgravi               sgra,
       ruoli                ruol,
       oggetti_imposta      ogim,
       ruoli_contribuente   ruco
 where tari.tipo_tariffa       = ogpr.tipo_tariffa
   and tari.categoria          = ogpr.categoria
   and tari.tributo            = ogpr.tributo
   and tari.anno               = ruol.anno_ruolo
   and sgra.ruolo          (+) = ruco.ruolo
   and sgra.cod_fiscale    (+) = ruco.cod_fiscale
   and sgra.sequenza       (+) = ruco.sequenza
   and ruol.ruolo              = ruco.ruolo
   and ruco.ruolo              = a_ruolo
   and ruco.cod_fiscale        = a_cod_fiscale
   and ruco.sequenza           = a_sequenza
   and ogim.oggetto_imposta    = ruco.oggetto_imposta
   and ogim.ruolo              = a_ruolo
   and ogim.oggetto_pratica    = ogpr.oggetto_pratica
   and nvl(ogpr.oggetto_pratica_rif,ogpr.oggetto_pratica)
                               = w_oggetto_pratica_r
 group by
       ruco.sequenza,
       ruco.ruolo
 union
select 2,
       ruco.sequenza,
       ruco.ruolo,
       max(ogim.imposta),
       nvl(sum(nvl(sgra.importo,0) - nvl(sgra.addizionale_eca,0)
                                   - nvl(sgra.maggiorazione_eca,0)
                                   - nvl(sgra.addizionale_pro,0)
                                   - nvl(sgra.iva,0)
                                   - nvl(sgra.maggiorazione_tares,0)
              ),0
          ),
       max(nvl(tari.perc_riduzione,0)),
       max(ogim.maggiorazione_tares),
       sum(sgra.maggiorazione_tares),
       -- (VD - 02/11/2018): aggiunta gestione importi calcolati con tariffa base
       max(ogim.imposta_base),
       nvl(sum(nvl(sgra.importo_base,0) - nvl(sgra.addizionale_eca_base,0)
                                        - nvl(sgra.maggiorazione_eca_base,0)
                                        - nvl(sgra.addizionale_pro_base,0)
                                        - nvl(sgra.iva_base,0)
              ),0
          )
  from tariffe              tari,
       oggetti_pratica      ogpr,
       sgravi               sgra,
       ruoli                ruol,
       oggetti_imposta      ogim,
       ruoli_contribuente   ruco
 where tari.tipo_tariffa       = ogpr.tipo_tariffa
   and tari.categoria          = ogpr.categoria
   and tari.tributo            = ogpr.tributo
   and tari.anno               = ruol.anno_ruolo
   and sgra.ruolo          (+) = ruco.ruolo
   and sgra.cod_fiscale    (+) = ruco.cod_fiscale
   and sgra.sequenza       (+) = ruco.sequenza
   and ruol.ruolo              = ruco.ruolo
   and ruco.ruolo              = a_ruolo
   and ruco.cod_fiscale        = a_cod_fiscale
   and ruco.sequenza          <> a_sequenza
   and ogim.oggetto_imposta    = ruco.oggetto_imposta
   and ogim.ruolo              = a_ruolo
   and ogim.oggetto_pratica    = ogpr.oggetto_pratica
   and nvl(ogpr.oggetto_pratica_rif,ogpr.oggetto_pratica)
                               = w_oggetto_pratica_r
 group by
       ruco.sequenza,
       ruco.ruolo
-- union
--select 3,
--       ruco.sequenza,
--       ruco.ruolo,
--       max(ogim.imposta),
--       nvl(sum(nvl(sgra.importo,0) - nvl(sgra.addizionale_eca,0)
--                                   - nvl(sgra.maggiorazione_eca,0)
--                                   - nvl(sgra.maggiorazione_tares,0)
--                                   - nvl(sgra.addizionale_pro,0)
--                                   - nvl(sgra.iva,0)
--              ),0
--          )
--  from oggetti_pratica      ogpr,
--       sgravi               sgra,
--       ruoli                ruol,
--       oggetti_imposta      ogim,
--       ruoli_contribuente   ruco
-- where sgra.ruolo          (+) = ruco.ruolo
--   and sgra.cod_fiscale    (+) = ruco.cod_fiscale
--   and sgra.sequenza       (+) = ruco.sequenza
--   and ruol.ruolo              = ruco.ruolo
--   and ruco.cod_fiscale        = a_cod_fiscale
--   and ogim.oggetto_imposta    = ruco.oggetto_imposta
--   and ogim.ruolo              = ruco.ruolo
--   and ogim.oggetto_pratica    = ogpr.oggetto_pratica
--   and nvl(ogpr.oggetto_pratica_rif,ogpr.oggetto_pratica)
--                               = w_oggetto_pratica_r
--   and ruco.ruolo              in (select ruol_prec.ruolo
--                                   from   ruoli ruol_prec
--                                   where  nvl(ruol_prec.tipo_emissione,'T')   = 'A'
--                                   and ruol_prec.invio_consorzio is not null
--                                   and ruol_prec.anno_ruolo       = w_anno_ruolo)
--   and w_tipo_emissione        = 'S'
-- group by
--       ruco.sequenza,
--       ruco.ruolo
 order by
       1,2
;
--------------------------------------------------
-- CALCOLO SGRAVIO
--------------------------------------------------
BEGIN
-- PRIMA PARTE : CALCOLO DELLO SGRAVIO.
  BEGIN
     select nvl(ogpr.oggetto_pratica_rif,ogpr.oggetto_pratica)
           ,ogpr.oggetto_pratica
           ,ogp2.oggetto_pratica_rif
           ,prt2.tipo_evento
       into w_oggetto_pratica_r
           ,w_oggetto_pratica
           ,w_oggetto_pratica_rif
           ,w_tipo_evento_rif
       from oggetti_pratica  ogpr
           ,oggetti_pratica  ogp2
           ,pratiche_tributo prt2
      where ogpr.oggetto_pratica = a_oggetto_pratica
        and ogp2.oggetto_pratica = nvl(ogpr.oggetto_pratica_rif,ogpr.oggetto_pratica)
        and prt2.pratica         = ogp2.pratica
     ;
  EXCEPTION
     WHEN NO_DATA_FOUND THEN
        w_errore := 'Errore in Recupero Oggetto Pratica Rif. per '||
                    to_Char(a_oggetto_pratica);
        RAISE ERRORE;
  END;
  BEGIN
     select ruol.anno_ruolo
           ,ruol.tipo_ruolo
           ,ruol.importo_lordo
           ,ruol.tipo_tributo
           ,nvl(ruol.tipo_emissione,'T')
           ,nvl(ruol.flag_calcolo_tariffa_base,'N')
           ,nvl(ruol.flag_tariffe_ruolo,'N')
       into w_anno_ruolo
           ,w_tipo_ruolo
           ,w_importo_lordo
           ,w_tipo_tributo
           ,w_tipo_emissione
           ,w_flag_tariffa_base
           ,w_flag_tariffe_ruolo
       from ruoli ruol
      where ruol.ruolo = a_ruolo
     ;
  EXCEPTION
     WHEN NO_DATA_FOUND THEN
        w_errore := 'Errore in Recupero Dati del Ruolo '||to_char(a_ruolo);
        RAISE ERRORE;
  END;
  --
--dbms_output.put_line('Anno ruolo: '||w_anno_ruolo);
  --
  begin
    select lpad(to_char(d.pro_cliente), 3, '0') || lpad(to_char(d.com_cliente), 3, '0'),
           decode(to_char(last_day(to_date('02'||w_anno_ruolo,'mmyyyy')),'dd'), 28, 365, nvl(f_inpa_valore('GG_ANNO_BI'),366))
      into w_cod_istat,
           w_gg_anno
      from dati_generali d;
  exception
    when no_data_found then
      w_errore := 'Dati Generali non inseriti';
      raise errore;
    when others then
      w_errore := 'Errore in ricerca Dati Generali';
      raise errore;
  end;
  if w_importo_lordo = 'S' then
     BEGIN
        select nvl(cata.addizionale_eca,0)
              ,nvl(cata.maggiorazione_eca,0)
              ,nvl(cata.addizionale_pro,0)
              ,nvl(cata.aliquota,0)
              ,nvl(cata.maggiorazione_tares,0)
              ,flag_magg_anno
          into w_perc_add_eca
              ,w_perc_magg_eca
              ,w_perc_add_pro
              ,w_perc_iva
              ,w_perc_magg_tares
              ,w_flag_magg_anno
          from carichi_tarsu cata
         where cata.anno = w_anno_ruolo
        ;
     EXCEPTION
        WHEN NO_DATA_FOUND THEN
           w_perc_add_eca    := 0;
           w_perc_magg_eca   := 0;
           w_perc_magg_tares := 0;
           w_perc_add_pro    := 0;
           w_perc_iva        := 0;
     END;
  else
     w_perc_add_eca          := 0;
     w_perc_magg_eca         := 0;
     w_perc_magg_tares       := 0;
     w_perc_add_pro          := 0;
     w_perc_iva              := 0;
  end if;
  --
  w_magg_tares_cope := 0;
  BEGIN
    select sum(importo)
      into w_magg_tares_cope
      from componenti_perequative
     where anno              = w_anno_ruolo
    ;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
       null;
    WHEN others THEN
       w_errore := 'Errore in ricerca Componenti Perequative';
       RAISE errore;
  END;
  --
--dbms_output.put_line('Oggetto Pratica Rif. '||to_char(w_oggetto_pratica_r));
  --
  a_nota                     := null;
  w_tot_importo              := 0;
  w_tot_add                  := 0;
  w_tot_add_pro              := 0;
  w_tot_add_eca              := 0;
  w_tot_magg_eca             := 0;
  w_tot_magg_tares           := 0;
  w_tot_iva                  := 0;
  w_tot_importo_r            := 0;
  w_tot_add_r                := 0;
  w_importo_sgravi_p         := 0;
  w_add_sgravi_p             := 0;
  w_tot_importo_r_acc        := 0;
  w_tot_add_r_acc            := 0;
  w_importo_sgravi_p_acc     := 0;
  w_add_sgravi_p_acc         := 0;
  w_tot_add_eca_r           := 0;
  w_tot_magg_eca_r          := 0;
  w_tot_magg_tares_r        := 0;
  w_tot_add_pro_r           := 0;
  w_tot_iva_r               := 0;
  w_add_eca_sgravi_p        := 0;
  w_magg_eca_sgravi_p       := 0;
  w_magg_tares_sgravi_p     := 0;
  w_add_pro_sgravi_p        := 0;
  w_iva_sgravi_p            := 0;
  w_tot_add_eca_r_acc       := 0;
  w_tot_magg_eca_r_acc      := 0;
  w_tot_magg_tares_r_acc    := 0;
  w_tot_add_pro_r_acc       := 0;
  w_tot_iva_r_acc           := 0;
  w_add_eca_sgravi_p_acc    := 0;
  w_magg_eca_sgravi_p_acc   := 0;
  w_magg_tares_sgravi_p_acc := 0;
  w_add_pro_sgravi_p_acc    := 0;
  w_iva_sgravi_p_acc        := 0;
  -- (VD - 22/11/2018): azzeramento variabili per calcoli con tariffa base
  w_tot_importo_base        := 0;
  w_tot_add_base            := 0;
  w_tot_add_pro_base        := 0;
  w_tot_add_eca_base        := 0;
  w_tot_magg_eca_base       := 0;
  w_tot_iva_base            := 0;
  w_tot_importo_r_base       := 0;
  w_tot_add_r_base           := 0;
  w_importo_sgravi_p_base    := 0;
  w_add_sgravi_p_base        := 0;
  w_tot_importo_r_acc_base   := 0;
  w_tot_add_r_acc_base       := 0;
  w_importo_sgravi_p_acc_base := 0;
  w_add_sgravi_p_acc_base    := 0;
--  w_tot_add_eca_r_base      := 0;
--  w_tot_magg_eca_r_base     := 0;
--  w_tot_add_pro_r_base      := 0;
--  w_tot_iva_r_base          := 0;
--
--  w_add_eca_sgravi_p_base   := 0;
--  w_magg_eca_sgravi_p_base  := 0;
--  w_add_pro_sgravi_p_base   := 0;
--  w_iva_sgravi_p_base       := 0;
--
--  w_tot_add_eca_r_acc_base  := 0;
--  w_tot_magg_eca_r_acc_base := 0;
--  w_tot_add_pro_r_acc_base  := 0;
--  w_tot_iva_r_acc_base      := 0;
--
--  w_add_eca_sgravi_p_acc_base := 0;
--  w_magg_eca_sgravi_p_acc_base := 0;
--  w_add_pro_sgravi_p_acc_base    := 0;
--  w_iva_sgravi_p_acc_base   := 0;
-- inizializzata a 0 la variabile w_conta in questo modo se non ho oggetti_validità
-- e non mi entra nel loop rec_ogva riesce ad applicare uno sgravio per tutti i 12 mesi,
-- caso di cessazione al 31/12 dell'anno precedente
  w_conta                   := 0;
--dbms_output.put_line('Inizio Loop rec_ogva');
  open rec_ogva;
  LOOP
     fetch rec_ogva into w_consistenza,
                         w_tributo,
                         w_categoria,
                         w_tipo_tariffa,
                         w_numero_familiari,
                         w_tariffa,
                         w_limite,
                         w_tari_sup,
                         w_tari_quota_fissa,
                         w_perc_poss,
                         w_flag_ab_principale,
                         w_punto_raccolta,
                         w_data_decorrenza,
                         w_data_cessazione,
                         w_tipo_evento,
                         w_tipo_ruolo,
                         w_progr_emissione,
                         w_perc_riduzione,
                         w_tipo_tariffa_base
     ;
     exit when rec_ogva%NOTFOUND;
--
-- Si trattano i Ruoli Principali o i Suppletivi limitatamente al solo caso
-- di Nuova Iscrizione (o unico per accertamenti assunti come denuncia)
-- non trattata nei principali.
--
-- Controllo che l`oggetto pratica in esame non sia gia` in altro ruolo
-- suppletivo (caso di ruolo suppletivo per variazione o chiusura).
--
     w_conta := 0;
     if  w_tipo_ruolo = 2 and w_tipo_evento_rif in ('I','U')
      and w_oggetto_pratica_rif is null then
        BEGIN
           select count(*)
             into w_conta
             from oggetti_pratica    ogpr
                 ,oggetti_imposta    ogim
                 ,ruoli_contribuente ruco
                 ,ruoli              ruol
            where ogpr.oggetto_pratica  = ogim.oggetto_imposta
              and ruco.oggetto_imposta  = ogim.oggetto_imposta
              and ruco.cod_fiscale      = ogim.cod_fiscale
              and ruco.cod_fiscale      = a_cod_fiscale
              and ruol.ruolo            = ruco.ruolo
              and ruol.ruolo           <> a_ruolo
              and ruol.tipo_ruolo       = 2
              and ruol.anno_ruolo       = w_anno_ruolo
              and nvl(ogpr.oggetto_pratica_rif,ogpr.oggetto_pratica)
                                        = w_oggetto_pratica_r
           ;
        END;
     end if;
--
-- Controllo che l`oggetto pratica in esame non sia gia` in altro ruolo
-- suppletivo (caso di ruolo suppletivo per accertamento).
--
     if  w_tipo_ruolo = 2 and w_tipo_evento_rif in ('I','U')
     and w_oggetto_pratica_rif is null and w_conta = 0 then
        BEGIN
           select count(*)
             into w_conta
             from oggetti_pratica    ogpr
                 ,pratiche_tributo   prtr
                 ,ruoli_contribuente ruco
                 ,ruoli              ruol
            where prtr.pratica          = ogpr.pratica
              and ruco.pratica          = prtr.pratica
              and ruco.cod_fiscale      = a_cod_fiscale
              and ruol.ruolo            = ruco.ruolo
              and ruol.ruolo           <> a_ruolo
              and ruol.tipo_ruolo       = 2
              and ruol.anno_ruolo       = w_anno_ruolo
              and nvl(ogpr.oggetto_pratica_rif,ogpr.oggetto_pratica)
                                        = w_oggetto_pratica_r
           ;
        END;
     end if;
     if  (w_tipo_ruolo = 1 or w_tipo_evento_rif in ('I','U') and w_oggetto_pratica_rif is null)
     and w_conta = 0 then
        w_da_trattare := TRUE;
        if w_cod_istat = '012096' and w_tipo_tributo = 'TARSU' and w_anno_ruolo = 2006 then
           if nvl(w_data_cessazione,to_date('31122006','ddmmyyyy')) > to_date('30062006','ddmmyyyy') then
              w_data_cessazione := to_date('30062006','ddmmyyyy');
           end if;
           if nvl(w_data_decorrenza,to_date('01012006','ddmmyyyy')) > to_date('30062006','ddmmyyyy') then
              w_da_trattare := FALSE;
           else
              w_da_trattare := TRUE;
           end if;
        end if;
        -- Bovezzo calcolo semestrale primo semestre
        if w_cod_istat = '017025' and w_tipo_tributo = 'TARSU' and w_anno_ruolo > 2007 and w_progr_emissione = 1 then
            if nvl(w_data_cessazione,to_date('3112'||to_char(w_anno_ruolo),'ddmmyyyy')) > to_date('3006'||to_char(w_anno_ruolo),'ddmmyyyy') then
               w_data_cessazione := to_date('3006'||to_char(w_anno_ruolo),'ddmmyyyy');
            else
               w_data_cessazione := w_data_cessazione;
            end if;
            if nvl(w_data_decorrenza,to_date('0101'||to_char(w_anno_ruolo),'ddmmyyyy')) > to_date('3006'||to_char(w_anno_ruolo),'ddmmyyyy') then
               w_da_trattare := FALSE;
            else
               w_da_trattare := TRUE;
            end if;
        end if;
        if w_da_trattare then  -- se non è da trattare passo al prossimo oggetto
           if a_calcolo_normalizzato = 'S' then
            --dbms_output.put_line('----------------------');
            --dbms_output.put_line('Tributo: '||w_tributo);
            --dbms_output.put_line('Categoria: '||w_categoria);
            --dbms_output.put_line('Tipo Tariffa: '||w_tipo_tariffa);
            --dbms_output.put_line('Tariffa: '||w_tariffa);
            --dbms_output.put_line('Consistenza: '||w_consistenza);
            --dbms_output.put_line('% poss: '||w_perc_poss);
            --dbms_output.put_line('Data Decorrenza: '||to_char(w_data_decorrenza,'dd/mm/yyyy'));
            --dbms_output.put_line('Data Cessazione: '||to_char(w_data_cessazione,'dd/mm/yyyy'));
            --dbms_output.put_line('Ab. Principale: '||w_flag_ab_principale);
            --dbms_output.put_line('Punto Raccolta: '||w_punto_raccolta);
            --dbms_output.put_line('Num. Familiari: '||w_numero_familiari);
              --
              calcolo_importo_norm_tariffe(a_cod_fiscale
                                          ,null  --  ni
                                          ,w_anno_ruolo
                                          ,w_tributo
                                          ,w_categoria
                                          ,w_tipo_tariffa
                                          ,w_tariffa
                                          ,w_tari_quota_fissa
                                          ,w_consistenza
                                          ,w_perc_poss
                                          ,w_data_decorrenza
                                          ,w_data_cessazione
                                          ,w_flag_ab_principale
                                          ,w_numero_familiari
                                          ,a_ruolo
                                          ,to_number(null) -- oggetto
                                          ,w_tipo_tariffa_base
                                          ,w_importo
                                          ,w_importo_pf
                                          ,w_importo_pv
                                          ,w_importo_base
                                          ,w_importo_pf_base
                                          ,w_importo_pv_base
                                          ,w_perc_rid_pf
                                          ,w_perc_rid_pv
                                          ,w_importo_pf_rid
                                          ,w_importo_pv_rid
                                          ,w_stringa_familiari
                                          ,w_dettaglio_sgra
                                          ,w_dettaglio_sgra_base
                                          ,w_giorni_ruolo
                                          );
              w_imposta_dovuta := w_importo;
            --dbms_output.put_line('Imposta dovuta: '||w_imposta_dovuta);
            --dbms_output.put_line('Dettaglio sgra: '||w_dettaglio_sgra);
            --dbms_output.put_line('Giorni ruolo: '||w_giorni_ruolo);
              if length(w_dettaglio_sgra) > 151 then
                 w_dettaglio_fasg := w_dettaglio_sgra;
                 w_dettaglio_sgra := '';
              end if;
              if length(w_dettaglio_sgra_base) > 171 then
                 w_dettaglio_fasg_base := w_dettaglio_sgra_base;
                 w_dettaglio_sgra_base := '';
              end if;
           else
              IF (w_consistenza < w_limite) or (w_limite is NULL) THEN
                 w_importo  := w_consistenza * w_tariffa;
              ELSE
                 w_importo  := w_limite * w_tariffa +
                               (w_consistenza - w_limite) * w_tari_sup;
              END IF;
              begin
                select nvl(mesi_calcolo,2)
                  into w_mesi_calcolo
                  from carichi_tarsu
                 where anno = w_anno_ruolo
                ;
              exception
                when no_data_found then
                   w_mesi_calcolo := 2;
              end;
              if w_mesi_calcolo = 0 and w_cod_istat = '037054' then -- San Lazzaro
                 w_giorni_ruolo := w_data_cessazione - w_data_decorrenza + 1;
                 w_importo      := round(w_importo * nvl(w_perc_poss,100) / 100 * w_giorni_ruolo / w_gg_anno,2);
              else
                 w_periodo     := to_number(to_char(w_data_cessazione,'mm')) -
                                  to_number(to_char(w_data_decorrenza,'mm')) + 1;
                 w_importo     := round(w_importo * nvl(w_perc_poss,100) / 100 * w_periodo / 12,2);
              end if;
           end if;
           --
           -- (VD - 02/11/2018): gestione importi calcolati con tariffa base
           --
           /*if w_flag_tariffa_base = 'S' and w_tipo_tariffa_base is not null then
              determina_importi_base(a_cod_fiscale
                                    ,w_anno_ruolo
                                    ,a_ruolo
                                    ,w_tributo
                                    ,w_categoria
                                    ,w_tipo_tariffa_base
                                    ,a_calcolo_normalizzato
                                    ,w_consistenza
                                    ,w_perc_poss
                                    ,w_periodo
                                    ,w_data_decorrenza
                                    ,w_data_cessazione    --rec_ogpr.data_cessazione
                                    ,w_flag_ab_principale
                                    ,w_numero_familiari
                                    ,w_importo_base
                                    ,w_importo_pf_base
                                    ,w_importo_pv_base
                                    ,w_stringa_familiari_base
                                    ,w_dettaglio_sgra_base
                                    ,w_giorni_ruolo
                                    );
              if length(w_dettaglio_sgra_base) > 171 then
                 w_dettaglio_fasg_base := w_dettaglio_sgra_base;
                 w_dettaglio_sgra_base := '';
              end if;
           end if; */
           -- Bovezzo gestione secondo semestre
           -- (VD - 20/11/2018): nel caso di Bovezzo, non bisogna togliere
           --                    l'importo da scalare perchè fa riferimento
           --                    ai ruoli già emessi e non a quello ricalcolato
           /*if w_cod_istat = '017025' and w_tipo_tributo = 'TARSU' and w_anno_ruolo > 2007
              and w_progr_emissione = 7 then
              w_imp_scalare := round(f_importo_da_scalare_sem(a_ruolo
                                                             ,a_cod_fiscale
                                                             ,w_anno_ruolo
                                                             ,w_data_decorrenza
                                                             ,w_data_cessazione
                                                             ,w_tipo_tributo
                                                             ,w_oggetto_pratica_r
                                                             ,a_calcolo_normalizzato
                                                             ,'TOT'
                                                             ,1 --sgravio trattato
                                                             )
                                     ,2
                                     );
              w_importo := w_importo - w_imp_scalare;
              -- (VD - 02/11/2018): aggiunta gestione importi calcolati con tariffa base
              w_imp_scalare_base := round(f_importo_da_scalare_sem(a_ruolo
                                                                  ,a_cod_fiscale
                                                                  ,w_anno_ruolo
                                                                  ,w_data_decorrenza
                                                                  ,w_data_cessazione
                                                                  ,w_tipo_tributo
                                                                  ,w_oggetto_pratica_r
                                                                  ,a_calcolo_normalizzato
                                                                  ,'TOTB'
                                                                  ,1 --sgravio trattato
                                                                  )
                                     ,2
                                     );
              w_importo_base := w_importo_base - w_imp_scalare_base;
           end if; */
          w_mesi := to_number(to_char(w_data_cessazione,'mm')) - to_number(to_char(w_data_decorrenza,'mm')) + 1;
          w_da_mese_sgravio := to_number(to_char(w_data_decorrenza,'mm'));
          w_a_mese_sgravio  := to_number(to_char(w_data_cessazione,'mm'));
          w_add_eca  := round(w_importo * w_perc_add_eca / 100,2);
          w_magg_eca := round(w_importo * w_perc_magg_eca / 100,2);
          -- (VD - 02/11/2018): aggiunta gestione importi calcolati con tariffa base
          w_add_eca_base  := round(w_importo_base * w_perc_add_eca / 100,2);
          w_magg_eca_base := round(w_importo_base * w_perc_magg_eca / 100,2);
          --
          if w_magg_tares_cope > 0 and             -- #71531 -- Componenti Perequative > 0
             w_tipo_emissione in ('S','T') then              -- Solo Ruolo Saldo o Totale
            if w_punto_raccolta = 'S' then
              w_coeff_gg := F_COEFF_GG(w_anno_ruolo,w_data_decorrenza,w_data_cessazione);
              w_magg_tares := trunc(w_magg_tares_cope * w_coeff_gg,2);
             else
               w_magg_tares := 0;
             end if;
          else
            if w_anno_ruolo >= 2013
               and w_tipo_emissione in ('S','T')
               and a_tipo_sgravio != 'R'
               and (w_cod_istat != '017025' -- Bovezzo
                   or (w_cod_istat = '017025'
                       and w_progr_emissione = 7))
            then
              if w_flag_magg_anno is null then
                  w_magg_tares := round(w_consistenza * w_perc_magg_tares * (100 - w_perc_riduzione) / 100 *
                                        F_COEFF_GG(w_anno_ruolo,w_data_decorrenza,w_data_cessazione)
                                       ,2);
               else
                  w_magg_tares := round(w_consistenza * w_perc_magg_tares,2);
               end if;
            else
               w_magg_tares := 0;
            end if;
          end if;
          --
          w_add_pro     := round(w_importo * w_perc_add_pro / 100,2);
          w_iva         := round(w_importo * w_perc_iva / 100,2);
          w_add_pro_base := round(w_importo_base * w_perc_add_pro / 100,2);
          w_iva_base     := round(w_importo_base * w_perc_iva / 100,2);
          --if w_cod_istat = '037048' then  -- Pieve di Cento
          --   w_tot_add_pro    := w_tot_add_pro   + nvl(w_add_pro,0);
          --   w_tot_add_eca    := w_tot_add_eca   + nvl(w_add_eca,0);
          --   w_tot_magg_eca   := w_tot_magg_eca  + nvl(w_magg_eca,0);
          --   w_tot_magg_tares := w_tot_magg_tares + nvl(w_magg_tares,0);
          --   w_tot_iva        := w_tot_iva       + nvl(w_iva,0);
          --end if;
          w_tot_add     := w_tot_add + w_add_eca + w_magg_eca + w_magg_tares + w_add_pro + w_iva;
          w_tot_importo := w_tot_importo + nvl(w_importo,0);
          w_tot_magg_tares := w_tot_magg_tares + nvl(w_magg_tares,0);
          --
        --dbms_output.put_line('- Importo Ricalcolato: '||nvl(to_char(w_tot_importo),'null'));
        --dbms_output.put_line('- Add Ricalcolate: '||nvl(to_char(w_tot_add - w_magg_tares),'null'));
        --dbms_output.put_line('- Componenti Pereq.: '||nvl(to_char(w_tot_magg_tares),'null'));
          --
          -- (VD - 02/11/2018): aggiunta gestione importi calcolati con tariffa base
          w_tot_add_base     := w_tot_add_base + w_add_eca_base + w_magg_eca_base + w_add_pro_base + w_iva_base;
          w_tot_importo_base := w_tot_importo_base + nvl(w_importo_base,0);
          --dbms_output.put_line('# Importo Ricalcolato: '||nvl(to_char(w_importo),'null')||
          --                          ' Totale = '||nvl(to_char(w_tot_importo),'null'));
          --dbms_output.put_line('# Importo Ricalcolato Base: '||nvl(to_char(w_importo_base),'null')||
          --                          ' Totale Base: '||nvl(to_char(w_tot_importo_base),'null'));
        end if;  -- personalizzazione di Malnate
     else
        null;
     end if;
  END LOOP;
  --
--dbms_output.put_line('======================');
  --
  --  if w_cod_istat = '037048' then  -- Pieve di Cento
  --     w_tot_importo   := round(w_tot_importo,0);
  --     w_tot_add_pro   := round(w_tot_add_pro,0);
  --     w_tot_add_eca   := round(w_tot_add_eca,0);
  --     w_tot_magg_eca  := round(w_tot_magg_eca,0);
  --     w_tot_magg_tares  := round(w_tot_magg_tares,0);
  --     w_tot_iva       := round(w_tot_iva,0);
  --  end if;
  close rec_ogva;
--dbms_output.put_line('Fine Loop rec_ogva e inizio loop rec_ruol');
  open rec_ruol;
  LOOP -- Selezione parametri di calcolo dalla pratica a ruolo
     fetch rec_ruol into w_consistenza_r,
                         w_perc_poss_r,
                         w_punto_raccolta_r,
                         w_tariffa_r,
                         w_limite_r,
                         w_tari_sup_r,
                         w_data_decorrenza_r,
                         w_importo_r,
                         w_add_eca_r,
                         w_magg_eca_r,
                         w_magg_tares_r,
                         w_add_pro_r,
                         w_iva_r,
                         w_tributo,
                         w_categoria,
                         w_imp_sgravi,
                         w_add_eca_sgravi,
                         w_magg_eca_sgravi,
                         w_magg_tares_sgravi,
                         w_add_pro_sgravi,
                         w_iva_sgravi,
          -- (VD - 02/11/2018): aggiunta gestione importi calcolati con tariffa base
                         w_importo_r_base,
                         w_add_eca_r_base,
                         w_magg_eca_r_base,
                         w_add_pro_r_base,
                         w_iva_r_base,
                         w_imp_sgravi_base,
                         w_add_eca_sgravi_base,
                         w_magg_eca_sgravi_base,
                         w_add_pro_sgravi_base,
                         w_iva_sgravi_base,
          --
                         w_importo_r_acc,
                         w_add_eca_r_acc,
                         w_magg_eca_r_acc,
                         w_magg_tares_r_acc,
                         w_add_pro_r_acc,
                         w_iva_r_acc,
                         w_imp_sgravi_acc,
                         w_add_eca_sgravi_acc,
                         w_magg_eca_sgravi_acc,
                         w_magg_tares_sgravi_acc,
                         w_add_pro_sgravi_acc,
                         w_iva_sgravi_acc,
          -- (VD - 02/11/2018): aggiunta gestione importi calcolati con tariffa base
                         w_importo_r_acc_base,
                         w_add_eca_r_acc_base,
                         w_magg_eca_r_acc_base,
                         w_add_pro_r_acc_base,
                         w_iva_r_acc_base,
                         w_imp_sgravi_acc_base,
                         w_add_eca_sgravi_acc_base,
                         w_magg_eca_sgravi_acc_base,
                         w_add_pro_sgravi_acc_base,
                         w_iva_sgravi_acc_base
     -- (VD - 18/07/2016): annullamento modifiche del 22/01/2016
     --                         w_mesi_r,
     --                         w_giorni_r,
     --                         w_da_mese_r,
     --                         w_a_mese_r
     ;
     exit when rec_ruol%NOTFOUND;
   --dbms_output.put_line('Decorrenza: '||to_char(w_data_decorrenza_r,'dd/mm/yyyy')||', Importo: '||w_importo_r);
     if  (w_tipo_ruolo = 1 or w_tipo_evento_rif in ('I','U') and w_oggetto_pratica_rif is null)
     and w_conta = 0 then
        w_tot_importo_r     := w_tot_importo_r     + nvl(w_importo_r,0);
        w_tot_magg_tares_r  := w_tot_magg_tares_r  + nvl(w_magg_tares_r,0);
        w_tot_add_r         := w_tot_add_r         + nvl(w_add_eca_r,0)
                                                   + nvl(w_magg_eca_r,0)
                                                   + nvl(w_magg_tares_r,0)
                                                   + nvl(w_add_pro_r,0)
                                                   + nvl(w_iva_r,0);
        w_importo_sgravi_p  := w_importo_sgravi_p  + nvl(w_imp_sgravi,0);
        w_magg_tares_sgravi_p := w_magg_tares_sgravi_p + nvl(w_magg_tares_sgravi,0);
        w_add_sgravi_p      := w_add_sgravi_p      + nvl(w_add_eca_sgravi,0)
                                                   + nvl(w_magg_eca_sgravi,0)
                                                   + nvl(w_magg_tares_sgravi,0)
                                                   + nvl(w_add_pro_sgravi,0)
                                                   + nvl(w_iva_sgravi,0);
        w_tot_importo_r_acc := w_tot_importo_r_acc + nvl(w_importo_r_acc,0);
        w_tot_magg_tares_r_acc  := w_tot_magg_tares_r_acc  + nvl(w_magg_tares_r_acc,0);
        w_tot_add_r_acc     := w_tot_add_r_acc     + nvl(w_add_eca_r_acc,0)
                                                   + nvl(w_magg_eca_r_acc,0)
                                                   + nvl(w_magg_tares_r_acc,0)
                                                   + nvl(w_add_pro_r_acc,0)
                                                   + nvl(w_iva_r_acc,0);
        w_importo_sgravi_p_acc := w_importo_sgravi_p_acc  + nvl(w_imp_sgravi_acc,0);
        w_magg_tares_sgravi_p_acc := w_magg_tares_sgravi_p_acc + nvl(w_magg_tares_sgravi_acc,0);
        w_add_sgravi_p_acc     := w_add_sgravi_p_acc      + nvl(w_add_eca_sgravi_acc,0)
                                                          + nvl(w_magg_eca_sgravi_acc,0)
                                                          + nvl(w_magg_tares_sgravi_acc,0)
                                                          + nvl(w_add_pro_sgravi_acc,0)
                                                          + nvl(w_iva_sgravi_acc,0);
       -- (VD - 02/11/2018): aggiunta gestione importi calcolati con tariffa base
        w_tot_importo_r_base     := w_tot_importo_r_base     + nvl(w_importo_r_base,0);
        w_tot_add_r_base         := w_tot_add_r_base         + nvl(w_add_eca_r_base,0)
                                                             + nvl(w_magg_eca_r_base,0)
                                                             + nvl(w_add_pro_r_base,0)
                                                             + nvl(w_iva_r_base,0);
        w_importo_sgravi_p_base  := w_importo_sgravi_p_base  + nvl(w_imp_sgravi_base,0);
        w_add_sgravi_p_base      := w_add_sgravi_p_base      + nvl(w_add_eca_sgravi_base,0)
                                                             + nvl(w_magg_eca_sgravi_base,0)
                                                             + nvl(w_add_pro_sgravi_base,0)
                                                             + nvl(w_iva_sgravi_base,0);
        w_tot_importo_r_acc_base := w_tot_importo_r_acc_base + nvl(w_importo_r_acc_base,0);
        w_tot_add_r_acc_base     := w_tot_add_r_acc_base     + nvl(w_add_eca_r_acc_base,0)
                                                             + nvl(w_magg_eca_r_acc_base,0)
                                                             + nvl(w_add_pro_r_acc_base,0)
                                                             + nvl(w_iva_r_acc_base,0);
        w_importo_sgravi_p_acc_base := w_importo_sgravi_p_acc_base  + nvl(w_imp_sgravi_acc_base,0);
        w_add_sgravi_p_acc_base     := w_add_sgravi_p_acc_base      + nvl(w_add_eca_sgravi_acc_base,0)
                                                                    + nvl(w_magg_eca_sgravi_acc_base,0)
                                                                    + nvl(w_add_pro_sgravi_acc_base,0)
                                                                    + nvl(w_iva_sgravi_acc_base,0);
        /*if w_cod_istat = '037048' then  -- Pieve di Cento
           w_tot_add_eca_r     := w_tot_add_eca_r     + nvl(w_add_eca_r,0);
           w_tot_magg_eca_r    := w_tot_magg_eca_r    + nvl(w_magg_eca_r,0);
           w_tot_magg_tares_r  := w_tot_magg_tares_r  + nvl(w_magg_tares_r,0);
           w_tot_add_pro_r     := w_tot_add_pro_r     + nvl(w_add_pro_r,0);
           w_tot_iva_r         := w_tot_iva_r         + nvl(w_iva_r,0);
           w_add_eca_sgravi_p  := w_add_eca_sgravi_p  + nvl(w_add_eca_sgravi,0);
           w_magg_eca_sgravi_p := w_magg_eca_sgravi_p + nvl(w_magg_eca_sgravi,0);
           w_magg_tares_sgravi_p := w_magg_tares_sgravi_p + nvl(w_magg_tares_sgravi,0);
           w_add_pro_sgravi_p  := w_add_pro_sgravi_p  + nvl(w_add_pro_sgravi,0);
           w_iva_sgravi_p      := w_iva_sgravi_p      + nvl(w_iva_sgravi,0);
           w_tot_add_eca_r_acc     := w_tot_add_eca_r_acc     + nvl(w_add_eca_r_acc,0);
           w_tot_magg_eca_r_acc    := w_tot_magg_eca_r_acc    + nvl(w_magg_eca_r_acc,0);
           w_tot_magg_tares_r_acc  := w_tot_magg_tares_r_acc  + nvl(w_magg_tares_r_acc,0);
           w_tot_add_pro_r_acc     := w_tot_add_pro_r_acc     + nvl(w_add_pro_r_acc,0);
           w_tot_iva_r_acc         := w_tot_iva_r_acc         + nvl(w_iva_r_acc,0);
           w_add_eca_sgravi_p_acc  := w_add_eca_sgravi_p_acc  + nvl(w_add_eca_sgravi_acc,0);
           w_magg_eca_sgravi_p_acc := w_magg_eca_sgravi_p_acc + nvl(w_magg_eca_sgravi_acc,0);
           w_magg_tares_sgravi_p_acc := w_magg_tares_sgravi_p_acc + nvl(w_magg_tares_sgravi_acc,0);
           w_add_pro_sgravi_p_acc  := w_add_pro_sgravi_p_acc  + nvl(w_add_pro_sgravi_acc,0);
           w_iva_sgravi_p_acc      := w_iva_sgravi_p_acc      + nvl(w_iva_sgravi_acc,0);
        end if;*/
        --
        -- (VD - 22/01/2016): in caso di oggetti non piu posseduti, si
        --                    valorizzano le variabili mesi/giorni con i dati
        --                    del ruolo gia emesso
        --
        -- (VD - 18/07/2016): annullamento modifiche del 22/01/2016
        --        if w_mesi = 0 then
        --           w_mesi            := w_mesi_r;
        --           w_giorni_ruolo    := w_giorni_r;
        --           w_da_mese_sgravio := w_da_mese_r;
        --           w_a_mese_sgravio  := w_a_mese_r;
        --        end if;
     else
        null;
     end if;
  END LOOP;
  close rec_ruol;
  --dbms_output.put_line('Fine Loop rec_ruol');
  --dbms_output.put_line('Tipo Ruolo '||to_char(w_tipo_ruolo)||' Evento '||w_tipo_evento||' Ogpr.Rif '||
  --                     to_char(w_oggetto_pratica_rif));
--dbms_output.put_line('# Importo Ruolo: '||nvl(to_char(w_tot_importo_r),'null'));
--dbms_output.put_line('# Maggiorazione Ruolo: '||nvl(to_char(w_tot_magg_tares_r),'null'));
--dbms_output.put_line('# Addizionali Ruolo: '||nvl(to_char(w_tot_add_r),'null'));
--dbms_output.put_line('# P.Racc Ruolo: '||nvl(w_punto_raccolta_r,'-'));
  --dbms_output.put_line('# Importo: '||nvl(to_char(w_tot_importo),'null'));
  --dbms_output.put_line('# Addizionali: '||nvl(to_char(w_tot_add),'null'));
  --dbms_output.put_line('# Importo Sgravi: '||nvl(to_char(w_importo_sgravi_p),'null'));
  --dbms_output.put_line('# Addizionali Sgravi: '||nvl(to_char(w_add_sgravi_p),'null'));
  --dbms_output.put_line('# Importo ruolo prec.: '||nvl(to_char(w_tot_importo_r_acc),'null'));
  --dbms_output.put_line('# Addizionali ruolo prec.: '||nvl(to_char(w_tot_add_r_acc),'null'));
  --dbms_output.put_line('# Importo Sgravi ruolo prec.: '||nvl(to_char(w_importo_sgravi_p_acc),'null'));
  --dbms_output.put_line('# Addizionali Sgravi ruolo prec.: '||nvl(to_char(w_add_sgravi_p_acc),'null'));
  --dbms_output.put_line('# Importo Ruolo Base: '||nvl(to_char(w_tot_importo_r_base),'null'));
  --dbms_output.put_line('# Addizionali Ruolo Base: '||nvl(to_char(w_tot_add_r_base),'null'));
  --dbms_output.put_line('# Importo Base: '||nvl(to_char(w_tot_importo_base),'null'));
  --dbms_output.put_line('# Addizionali Base: '||nvl(to_char(w_tot_add_base),'null'));
  --dbms_output.put_line('# Importo Sgravi Base: '||nvl(to_char(w_importo_sgravi_p_base),'null'));
  --dbms_output.put_line('# Addizionali Sgravi Base: '||nvl(to_char(w_add_sgravi_p_base),'null'));
  --dbms_output.put_line('# Importo ruolo prec. Base: '||nvl(to_char(w_tot_importo_r_acc_base),'null'));
  --dbms_output.put_line('# Addizionali ruolo prec. Base: '||nvl(to_char(w_tot_add_r_acc_base),'null'));
  --dbms_output.put_line('# Importo Sgravi ruolo prec. Base: '||nvl(to_char(w_importo_sgravi_p_acc_base),'null'));
  --dbms_output.put_line('# Addizionali Sgravi ruolo prec. Base: '||nvl(to_char(w_add_sgravi_p_acc_base),'null'));
  -- Betta T.
  -- se il ruolo è a saldo, per determinare l'importo totale ruolo da cui togliere
  -- l'importo calcolato dobbiamo prendere in considerazione anche eventuali
  -- ruoli di acconto (dovrebbe essere uno solo)
  -- l'idea di base sarebbe: visto che il calcolo determina l'importo delle variazioni
  -- per l'anno dobbiamo considerare anche l'importo a ruolo per l'anno (acconto + saldo).
  -- Lo sgravio però lo carichiamo solo sul ruolo da elaborare, quindi se il saldo non è abbastanza
  -- capiente diamo una segnalazione di errore dicendo di sgravare prima l'acconto
  if  (w_tipo_ruolo = 1 or w_tipo_evento_rif in ('I','U') and w_oggetto_pratica_rif is null)
  and w_conta = 0 THEN
     a_importo_sgravio := (nvl(w_tot_importo_r,0)    + nvl(w_tot_add_r,0))
                        + (nvl(w_tot_importo_r_acc,0)    + nvl(w_tot_add_r_acc,0))
                        - (w_tot_importo      + w_tot_add  )
                        - (nvl(w_importo_sgravi_p,0) + nvl(w_add_sgravi_p,0))
                        - (nvl(w_importo_sgravi_p_acc,0) + nvl(w_add_sgravi_p_acc,0))
     ;
     if nvl(a_importo_sgravio,0) < 0 THEN
        w_errore := 'Importo Sgravio negativo: '||a_importo_sgravio;
        RAISE errore;
     end if;
     if w_tipo_emissione = 'S'
        and a_importo_sgravio > (nvl(w_tot_importo_r,0) + nvl(w_tot_add_r,0))
                                - (nvl(w_importo_sgravi_p,0) + nvl(w_add_sgravi_p,0)) THEN
        w_errore := 'Importo Sgravio superiore all''importo del ruolo a saldo: sgravare prima l''acconto';
        RAISE errore;
     end if;
     -- (VD - 02/11/2018): aggiunta gestione importi calcolati con tariffa base
     w_importo_sgravio_base := (nvl(w_tot_importo_r_base,0)    + nvl(w_tot_add_r_base,0))
                             + (nvl(w_tot_importo_r_acc_base,0)    + nvl(w_tot_add_r_acc_base,0))
                             - (w_tot_importo_base      + w_tot_add_base  )
                             - (nvl(w_importo_sgravi_p_base,0) + nvl(w_add_sgravi_p_base,0))
                             - (nvl(w_importo_sgravi_p_acc_base,0) + nvl(w_add_sgravi_p_acc_base,0))
     ;
  else
     --dbms_output.put_line('Caso Non Gestito');
     RAISE FINE; -- Gestire lo sgravio su ruolo suppletivo
  end if;
  --dbms_output.put_line('# Sgravio: '||nvl(to_char(a_importo_sgravio),'null'));
-- SECONDA PARTE: INSERIMENTO SGRAVI.
  w_flag          := 0;
  w_tot_altri     := 0;
  w_tot_add_altri := 0;
--  w_tot_importo := w_tot_importo_r - w_tot_importo - w_importo_sgravi_p;
  w_tot_importo := nvl(w_tot_importo_r,0)
                 + nvl(w_tot_importo_r_acc,0)
                 - w_tot_importo
                 - nvl(w_importo_sgravi_p,0)
                 - nvl(w_importo_sgravi_p_acc,0);
  w_tot_magg_tares := nvl(w_tot_magg_tares_r,0)
                    + nvl(w_tot_magg_tares_r_acc,0)
                    - w_tot_magg_tares
                    - nvl(w_magg_tares_sgravi_p,0)
                    - nvl(w_magg_tares_sgravi_p_acc,0);
  -- (VD - 02/11/2018): aggiunta gestione importi calcolati con tariffa base
  w_tot_importo_base := nvl(w_tot_importo_r_base,0)
                      + nvl(w_tot_importo_r_acc_base,0)
                      - w_tot_importo_base
                      - nvl(w_importo_sgravi_p_base,0)
                      - nvl(w_importo_sgravi_p_acc_base,0);
  /*if w_cod_istat = '037048' then  -- Pieve di Cento
     w_tot_add_pro   := nvl(w_tot_add_pro_r,0) + nvl(w_tot_add_pro_r_acc,0)
                      - w_tot_add_pro   - nvl(w_add_pro_sgravi_p,0)
                      - nvl(w_add_pro_sgravi_p_acc,0);
     w_tot_add_eca   := nvl(w_tot_add_eca_r,0) + nvl(w_tot_add_eca_r_acc,0)
                      - w_tot_add_eca   - nvl(w_add_eca_sgravi_p,0)
                      - nvl(w_add_eca_sgravi_p_acc,0);
     w_tot_magg_eca  := nvl(w_tot_magg_eca_r,0) + nvl(w_tot_magg_eca_r_acc,0)
                      - w_tot_magg_eca   - nvl(w_magg_eca_sgravi_p,0)
                      - nvl(w_magg_eca_sgravi_p_acc,0);
     w_tot_magg_tares := nvl(w_tot_magg_tares_r,0) + nvl(w_tot_magg_tares_r_acc,0)
                      - w_tot_magg_tares   - nvl(w_magg_tares_sgravi_p,0)
                      - nvl(w_magg_tares_sgravi_p_acc,0);
     w_tot_iva  := nvl(w_tot_iva_r,0) + nvl(w_tot_iva_r_acc,0)
                      - w_tot_iva   - nvl(w_iva_sgravi_p,0)
                      - nvl(w_iva_sgravi_p_acc,0);
  end if;*/
  --
--dbms_output.put_line('======================');
--dbms_output.put_line('@ Sgravio Calcolato: '||nvl(to_char(a_importo_sgravio),'null'));
  --
  if a_importo_sgravio > 0 then
     w_tot_add     := 0;
   --dbms_output.put_line('@ Importo: '||nvl(to_char(w_tot_importo),'null'));
     open rec_sgra;
     LOOP
        fetch rec_sgra into w_ordinamento,w_sequenza,w_ruolo_sgra,w_importo_ruolo,w_importo_sgravi,
                            w_perc_riduzione,w_magg_tares_ruolo,w_magg_tares_sgravi,
                            w_importo_ruolo_base,w_importo_sgravi_base;
        exit  when rec_sgra%NOTFOUND;
        w_importo  := least(w_tot_importo,w_importo_ruolo - w_importo_sgravi);
        w_add_eca  := round(w_importo * w_perc_add_eca / 100,2);
        w_magg_eca := round(w_importo * w_perc_magg_eca / 100,2);
        --
        if w_magg_tares_cope > 0 and             -- #71531 -- Componenti Perequative
           w_tipo_emissione in ('S','T') then              -- Solo Ruolo Saldo o Totale
            w_magg_tares := least(nvl(w_tot_magg_tares,0),nvl(w_magg_tares_ruolo,0) - nvl(w_magg_tares_sgravi,0));
        else
          if w_anno_ruolo >= 2013
             and w_tipo_emissione in ('S','T')
             and a_tipo_sgravio != 'R'
             and (w_cod_istat != '017025' -- Bovezzo
                 or (w_cod_istat = '017025'
                     and w_progr_emissione = 7))
          then
            w_magg_tares := least(nvl(w_tot_magg_tares,0),nvl(w_magg_tares_ruolo,0) - nvl(w_magg_tares_sgravi,0));
          else
            w_magg_tares := 0;
          end if;
        end if;
        w_add_pro  := round(w_importo * w_perc_add_pro / 100,2);
        w_iva      := round(w_Importo * w_perc_iva / 100,2);
             /*if w_cod_istat = '037048' then  -- Pieve di Cento
                  w_add_pro   := w_tot_add_pro;
                  w_add_eca   := w_tot_add_eca;
                  w_magg_eca  := w_tot_magg_eca;
                  w_magg_tares  := w_tot_magg_tares;
                  w_iva       := w_tot_iva;
               end if;*/
        w_tot_add  := w_tot_add + w_add_eca + w_magg_eca + w_magg_tares + w_add_pro + w_iva;
        --
      --dbms_output.put_line('@ Sgravio Netto: '||nvl(to_char(w_importo),'null'));
      --dbms_output.put_line('@ Sgravio Addiz.: '||nvl(to_char(w_tot_add - w_magg_tares),'null'));
      --dbms_output.put_line('@ Sgravio C.Pereq: '||nvl(to_char(w_magg_tares),'null'));
      --dbms_output.put_line('@ Sgravio Totale: '||nvl(to_char(w_importo_sgravi),'null'));
        --
        -- (VD - 02/11/2018): aggiunta gestione importi calcolati con tariffa base
        if w_flag_tariffa_base = 'S' or
           w_flag_tariffe_ruolo = 'S' then
           w_importo_base  := least(w_tot_importo_base,w_importo_ruolo_base - w_importo_sgravi_base);
           w_add_eca_base  := round(w_importo_base * w_perc_add_eca / 100,2);
           w_magg_eca_base := round(w_importo_base * w_perc_magg_eca / 100,2);
           w_add_pro_base  := round(w_importo_base * w_perc_add_pro / 100,2);
           w_iva_base      := round(w_Importo_base * w_perc_iva / 100,2);
        else
           w_importo_base  := to_number(null);
           w_add_eca_base  := to_number(null);
           w_magg_eca_base := to_number(null);
           w_add_pro_base  := to_number(null);
           w_iva_base      := to_number(null);
           w_dettaglio_sgra_base := '';
        end if;
        begin
          select max(ogva.oggetto_pratica)
            into w_ogpr_sgra
            from oggetti_pratica ogpr,oggetti_validita ogva
           where ogva.oggetto_pratica_rif = nvl(ogpr.oggetto_pratica_rif,ogpr.oggetto_pratica)
             and ogpr.oggetto_pratica = a_oggetto_pratica;
        end;
        --
        w_tot_importo_sgravi := w_importo + w_add_eca + w_magg_eca + w_magg_tares + w_add_pro + w_iva;
        if w_tot_importo_sgravi > 0 then
           sgravi_nr(w_ruolo_sgra,a_cod_fiscale,w_sequenza,w_sequenza_sgravio);
           insert into sgravi
                 (ruolo,cod_fiscale,sequenza,sequenza_sgravio,motivo_sgravio,importo,
                  addizionale_eca,maggiorazione_eca,addizionale_pro,iva,maggiorazione_tares,
                  flag_automatico,mesi_sgravio,da_mese,a_mese,giorni_sgravio,tipo_sgravio,
                  dettaglio_sgra,ogpr_sgravio,imposta_dovuta,
                  importo_base,addizionale_eca_base,maggiorazione_eca_base,
                  addizionale_pro_base,iva_base,dettaglio_sgra_base)
           values(w_ruolo_sgra,a_cod_fiscale,w_sequenza,w_sequenza_sgravio,a_motivo,
                  w_importo + w_add_eca + w_magg_eca + w_magg_tares + w_add_pro + w_iva,
                  w_add_eca,w_magg_eca,w_add_pro,w_iva,w_magg_tares,
                  'S',w_mesi,w_da_mese_sgravio,w_a_mese_sgravio,w_giorni_ruolo,a_tipo_sgravio,
                  w_dettaglio_sgra,w_ogpr_sgra,w_imposta_dovuta,
                  w_importo_base + w_add_eca_base + w_magg_eca_base + w_add_pro_base + w_iva_base,
                  w_add_eca_base,w_magg_eca_base,
                  w_add_pro_base,w_iva_base,w_dettaglio_sgra_base)
           ;
           w_tot_importo      := w_tot_importo - w_importo;
           w_tot_magg_tares   := w_tot_magg_tares - w_magg_tares;
           -- (VD - 02/11/2018): aggiunta gestione importi calcolati con tariffa base
           w_tot_importo_base := w_tot_importo_base - w_importo_base;
           if w_ordinamento = 2 then
              w_tot_altri     := w_tot_altri + w_importo;
              w_tot_add_altri := w_tot_add_altri + w_add_eca + w_magg_eca
                                 + w_magg_tares + w_add_pro + w_iva;
              w_flag := 1;
           end if;
--
           WHILE length(w_stringa_familiari) > 19  LOOP
              if w_cod_istat = '017025' and w_tipo_tributo = 'TARSU' and w_anno_ruolo > 2007 -- Bovezzo
                 and w_progr_emissione = 7 then
                 if to_date(substr(w_stringa_familiari,13,8),'ddmmyyyy') > to_date('3006'||substr(w_stringa_familiari,17,4),'ddmmyyyy') then
                    if to_date(substr(w_stringa_familiari,5,8),'ddmmyyyy') > to_date('3006'||substr(w_stringa_familiari,9,4),'ddmmyyyy') then
                       --inserimento normale
                       BEGIN
                          insert into familiari_sgra
                                     (ruolo, cod_fiscale, sequenza,
                                      sequenza_sgravio, dal, al,
                                      numero_familiari, dettaglio_fasg,
                                      data_variazione,
                                      dettaglio_fasg_base
                                     )
                               values(w_ruolo_sgra, a_cod_fiscale, w_sequenza,
                                      w_sequenza_sgravio,
                                      to_date(substr(w_stringa_familiari,5,8),'ddmmyyyy'),to_date(substr(w_stringa_familiari,13,8),'ddmmyyyy'),
                                      to_number(substr(w_stringa_familiari,1,4)),
                                      substr(w_dettaglio_fasg,1,150),
                                      trunc(sysdate),
                                      substr(w_dettaglio_fasg_base,1,170)
                                     );
                       EXCEPTION
                          WHEN others THEN
                              w_errore := 'Errore in inserimento Familiari_sgra di '
                                          ||a_cod_fiscale||' ('||SQLERRM||')';
                                  RAISE ERRORE;
                       END;
                    else
                       -- inserimento con riproporzionamento
                       w_mesi_fasg      := to_number(substr(w_stringa_familiari,15,2)) + 1 - to_number(substr(w_stringa_familiari,7,2));
                       w_mesi_fasg_2sem := to_number(substr(w_stringa_familiari,15,2)) + 1 - 7;
                       --w_errore := lpad(translate(to_char(round(to_number(ltrim(translate(substr(w_dettaglio_faog,49,17),',.','.'))) / w_mesi_faog * w_mesi_faog_2sem,2),'FM99,999,999,990.00'),'.,',',.'),17);
                       --RAISE ERRORE;
                       w_dettaglio_fasg := substr(w_dettaglio_fasg,1,48)
                                         ||lpad(translate(to_char(round(to_number(ltrim(translate(translate(substr(w_dettaglio_fasg,49,17),'a.','a'),',','.'))) / w_mesi_fasg * w_mesi_fasg_2sem,2),'FM99,999,999,990.00'),'.,',',.'),17)
                                         ||substr(w_dettaglio_fasg,66,48)
                                         ||lpad(translate(to_char(round(to_number(ltrim(translate(translate(substr(w_dettaglio_fasg,114,17),'a.','a'),',','.'))) / w_mesi_fasg * w_mesi_fasg_2sem,2),'FM99,999,999,990.00'),'.,',',.'),17)
                                         ||lpad(translate(to_char(round(to_number(ltrim(translate(translate(substr(w_dettaglio_fasg,131,20),'a.','a'),',','.'))) / w_mesi_fasg * w_mesi_fasg_2sem,2),'FM9,999,999,999,990.00'),'.,',',.'),20)
                                         ||substr(w_dettaglio_fasg,151);
                       ------
                       if w_flag_tariffa_base = 'S' then
                          w_dettaglio_fasg_base := substr(w_dettaglio_fasg_base,1,58)
                                            ||lpad(translate(to_char(round(to_number(ltrim(translate(translate(substr(w_dettaglio_fasg_base,59,17),'a.','a'),',','.'))) / w_mesi_fasg * w_mesi_fasg_2sem,2),'FM99,999,999,990.00'),'.,',',.'),17)
                                            ||substr(w_dettaglio_fasg_base,76,58)
                                            ||lpad(translate(to_char(round(to_number(ltrim(translate(translate(substr(w_dettaglio_fasg_base,134,17),'a.','a'),',','.'))) / w_mesi_fasg * w_mesi_fasg_2sem,2),'FM99,999,999,990.00'),'.,',',.'),17)
                                            ||lpad(translate(to_char(round(to_number(ltrim(translate(translate(substr(w_dettaglio_fasg_base,151,20),'a.','a'),',','.'))) / w_mesi_fasg * w_mesi_fasg_2sem,2),'FM9,999,999,999,990.00'),'.,',',.'),20)
                                            ||substr(w_dettaglio_fasg_base,171);
                       end if;
                       BEGIN
                          insert into familiari_sgra
                                     (ruolo, cod_fiscale, sequenza,
                                      sequenza_sgravio, dal, al,
                                      numero_familiari, dettaglio_fasg,
                                      data_variazione,
                                      dettaglio_fasg_base
                                     )
                               values(w_ruolo_sgra, a_cod_fiscale, w_sequenza,
                                      w_sequenza_sgravio,
                                      to_date(substr(w_stringa_familiari,5,8),'ddmmyyyy'),to_date(substr(w_stringa_familiari,13,8),'ddmmyyyy'),
                                      to_number(substr(w_stringa_familiari,1,4)),
                                      substr(w_dettaglio_fasg,1,150),
                                      trunc(sysdate),
                                      substr(w_dettaglio_fasg_base,1,170)
                                     );
                       EXCEPTION
                          WHEN others THEN
                              w_errore := 'Errore in inserimento Familiari_sgra di '
                                          ||a_cod_fiscale||' ('||SQLERRM||')';
                                  RAISE ERRORE;
                       END;
                    end if;
                 else
                    -- nessun inserimento
                    null;
                 end if;
              else
--raise_application_error(-20999,w_stringa_familiari||' - '||w_dettaglio_fasg);
                 BEGIN
                    insert into familiari_sgra
                               (ruolo, cod_fiscale, sequenza,
                                sequenza_sgravio, dal, al,
                                numero_familiari, dettaglio_fasg,
                                data_variazione,
                                dettaglio_fasg_base
                               )
                         values(w_ruolo_sgra, a_cod_fiscale, w_sequenza,
                                w_sequenza_sgravio,
                                to_date(substr(w_stringa_familiari,5,8),'ddmmyyyy'),to_date(substr(w_stringa_familiari,13,8),'ddmmyyyy'),
                                to_number(substr(w_stringa_familiari,1,4)),
                                substr(w_dettaglio_fasg,1,150),
                                trunc(sysdate),
                                substr(w_dettaglio_fasg_base,1,170)
                               )
                               ;
                 EXCEPTION
                    WHEN others THEN
                        w_errore := 'Errore in inserimento Familiari_sgra di '
                                    ||a_cod_fiscale||' ('||SQLERRM||')';
                            RAISE ERRORE;
                 END;
              end if;
              w_stringa_familiari   := substr(w_stringa_familiari,21);
              w_dettaglio_fasg      := '*'||substr(w_dettaglio_fasg,152);
              w_dettaglio_fasg_base := '*'||substr(w_dettaglio_fasg_base,172);
           END LOOP;
        end if;
        if w_tot_importo <= 0 then
           exit;
        end if;
     END LOOP;
     close rec_sgra;
  end if;
  if w_tot_importo > 0 then
     w_errore := 'Importo Sgravio Calcolato '||
                 ltrim(to_char(a_importo_sgravio,'9,999,999,999,990.00'))||
                 '. Importo Sgravio superiore all`Importo a Ruolo per '||
                 ltrim(to_char((w_tot_importo + w_tot_add),'9,999,999,999,990.00'))||
                 '. Assicurarsi che Non esistano altri Sgravi.';
     RAISE ERRORE;
  end if;
  if w_tot_altri > 0 then
     a_nota := 'Importo Sgravio Calcolato '||
               ltrim(to_char(a_importo_sgravio,'9,999,999,999,990.00'))||
               '. Assegnato uno Sgravio ad altre voci dello stesso Ruolo pari a '||
               ltrim(to_char((w_tot_altri + w_tot_add_altri),'9,999,999,999,990.00'));
  end if;
  if nvl(a_importo_sgravio,0) = 0 then
     a_nota := 'Importo Sgravio non Determinabile';
  end if;
  --
--dbms_output.put_line('======================');
  --
EXCEPTION
  WHEN FINE THEN
     RAISE_APPLICATION_ERROR(-20999,'Caso non previsto');
  WHEN errore THEN
     RAISE_APPLICATION_ERROR(-20999,w_errore);
  WHEN others THEN
     RAISE_APPLICATION_ERROR(-20999,'Errore in Calcolo Sgravio '||'('||SQLERRM||')');
END;
/* End Procedure: CALCOLO_SGRAVIO */
/
