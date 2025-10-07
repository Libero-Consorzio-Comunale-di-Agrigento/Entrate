--liquibase formatted sql 
--changeset abrandolini:20250326_152423_calcolo_sanzioni_raop_tasi stripComments:false runOnChange:true 
 
create or replace procedure CALCOLO_SANZIONI_RAOP_TASI
/***************************************************************************
 NOME:        CALCOLO_SANZIONI_RAOP_TASI

 DESCRIZIONE: Calcola e inserisce in SANZIONI_PRATICA le sanzioni relative
              al ravvedimento operoso TASI

 NOTE:

 Rev.    Date         Author      Note
 10      21/03/2024   RV          #69240
                                  Aggiunto gestione data_rif_ravvedimento per scadenze
 9       28/02/2023   AB          Issue #62651
                                  Aggiunta la eliminazione sanzioni per deceduti
 8       03/08/2021   VD          Aggiunto arrotonamento imposta per
                                  evitare l'emissione del ravvedimento
                                  in caso di differenza dovute ai
                                  versamenti arrotondati.
 7       05/02/2020   VD          Nuovo sanzionamento per ravvedimento
                                  operoso "lungo"
 6       19/09/2018   VD          Eliminata gestione importi suddivisi
                                  per comune/erario sulle imposte di
                                  terreni, aree fabbricabili e altri
                                  fabbricati.
 5       27/10/2017   VD          Corretto controllo sanzioni in test
                                  di verifica esistenza pratica di
                                  ravvedimento: aggiunti nuovi codici
 4       18/01/2016   VD          Modificata gestione sanzioni per il
                                  2016: per i versamenti effettuati
                                  entro 90 gg dalla scadenza relativi
                                  a pratiche del 2016, la sanzione
                                  viene dimezzata
 3       02/12/2015   VD          Modificata gestione fabbricati "D":
                                  visto che non esiste un codice
                                  tributo specifico, si totalizzano
                                  gli importi in quelli relativi a
                                  altri fabbricati
 2       19/06/2015   AB          Ho forzato w_se_anno_fabb_d sempre
                                  a 0 altrimenti non riportava i
                                  dettagli su altri_immobili (TASI)
 1       26/01/2015   VD          Aggiunta gestione ravvedimento medio
                                  per data versamento >= 01/01/2015 e
                                  gg di ritardo compresi tra 30 e 90
 0       31/01/2014   --          Prima emissione
*************************************************************************/
(a_pratica                     in number
,a_tipo_pagam                  in varchar2
,a_data_pagam                  in date
,a_utente                      in varchar2
,a_flag_infrazione             in varchar2
) is
w_errore                       varchar2(2000);
errore                         exception;
w_data_pratica                 date;
w_data_rif_ravv                date;
w_anno                         number(4);
w_anno_scadenza                number(4);
w_se_anno_fabb_d               number(1);
w_imposta                      number;
w_imposta_acc                  number;
w_imposta_sal                  number;
w_scadenza                     date;
--w_scadenza_succ     date;
w_scadenza_acc                 date;
--w_scadenza_acc_succ date;
w_scadenza_present             date;
--w_scadenza_pres_aa  date;
w_scadenza_pres_rav            date;
w_versato                      number;
w_versato_acc                  number;
w_versato_sal                  number;
w_versato_tardivo              number;
w_versato_tard_acc             number;
w_versato_tard_sal             number;
w_num_denunce_scad             number;
w_stato_sogg                   number(2);
--
-- Differenza di Anni per proroga sulle
-- scadenze di presentazione e versamento
-- applicate in alcune personalizzazioni.
w_delta_anni                   number;
--
w_cod_fiscale                  varchar2(16);
w_cod_sanzione                 number;
w_giorni_anno                  number;
w_diff_giorni                  number;
w_diff_giorni_acc              number;
w_diff_giorni_pres             number;
w_sanzione                     number;
w_rid                          number;
w_percentuale                  number;
w_riduzione                    number;
w_riduzione_2                  number;
w_conta                        number;
w_comune                       varchar2(6);
w_giorni                       number;
w_note_sanzione                varchar2(2000);
w_errore_interessi             varchar2(2000);

-- IMU --
w_imposta_ab                   number;
w_imposta_ab_acc               number;
w_imposta_ab_sal               number;
w_n_fab_ab                     number;
w_detrazione                   number;
w_detrazione_acc               number;
w_detrazione_sal               number;
w_imposta_rur                  number;
w_imposta_rur_acc              number;
w_imposta_rur_sal              number;
w_n_fab_rur                    number;
w_imposta_ter                  number;
w_imposta_ter_acc              number;
w_imposta_ter_sal              number;
w_imposta_aree                 number;
w_imposta_aree_acc             number;
w_imposta_aree_sal             number;
w_imposta_altri                number;
w_imposta_altri_acc            number;
w_imposta_altri_sal            number;
w_n_fab_altri                  number;

w_versato_ab_acc               number;
w_versato_ab_sal               number;
w_versato_tard_ab_acc          number;
w_versato_tard_ab_sal          number;
w_versato_rur_acc              number;
w_versato_rur_sal              number;
w_versato_tard_rur_acc         number;
w_versato_tard_rur_sal         number;
w_versato_ter_acc              number;
w_versato_ter_sal              number;
w_versato_tard_ter_acc         number;
w_versato_tard_ter_sal         number;
w_versato_aree_acc             number;
w_versato_aree_sal             number;
w_versato_tard_aree_acc        number;
w_versato_tard_aree_sal        number;
w_versato_altri_acc            number;
w_versato_altri_sal            number;
w_versato_tard_altri_acc       number;
w_versato_tard_altri_sal       number;

w_sanzione_ab                  number;
w_sanzione_rur                 number;
w_sanzione_ter_com             number;
w_sanzione_ter_sta             number;
w_sanzione_aree_com            number;
w_sanzione_aree_sta            number;
w_sanzione_altri_com           number;
w_sanzione_altri_sta           number;
w_sanzione_fabb_d_com          number;
w_sanzione_fabb_d_sta          number;

-- Variabili eliminate perchè non più gestite
/*w_imposta_ter_com              number;
w_imposta_ter_com_acc          number;
w_imposta_ter_com_sal          number;
w_imposta_ter_sta              number;
w_imposta_ter_sta_acc          number;
w_imposta_ter_sta_sal          number;
w_imposta_aree_com             number;
w_imposta_aree_com_acc         number;
w_imposta_aree_com_sal         number;
w_imposta_aree_sta             number;
w_imposta_aree_sta_acc         number;
w_imposta_aree_sta_sal         number;
w_imposta_altri_com            number;
w_imposta_altri_com_acc        number;
w_imposta_altri_com_sal        number;
w_imposta_altri_sta            number;
w_imposta_altri_sta_acc        number;
w_imposta_altri_sta_sal        number;
w_imposta_fabb_d_com           number;
w_imposta_fabb_d_com_acc       number;
w_imposta_fabb_d_com_sal       number;
w_imposta_fabb_d_sta           number;
w_imposta_fabb_d_sta_acc       number;
w_imposta_fabb_d_sta_sal       number;
w_n_fab_fabb_d                 number;

w_versato_ter_com_acc          number;
w_versato_ter_com_sal          number;
w_versato_tard_ter_com_acc     number;
w_versato_tard_ter_com_sal     number;
w_versato_ter_sta_acc          number;
w_versato_ter_sta_sal          number;
w_versato_tard_ter_sta_acc     number;
w_versato_tard_ter_sta_sal     number;
w_versato_aree_com_acc         number;
w_versato_aree_com_sal         number;
w_versato_tard_aree_com_acc    number;
w_versato_tard_aree_com_sal    number;
w_versato_aree_sta_acc         number;
w_versato_aree_sta_sal         number;
w_versato_tard_aree_sta_acc    number;
w_versato_tard_aree_sta_sal    number;
w_versato_altri_com_acc        number;
w_versato_altri_com_sal        number;
w_versato_tard_altri_com_acc   number;
w_versato_tard_altri_com_sal   number;
w_versato_altri_sta_acc        number;
w_versato_altri_sta_sal        number;
w_versato_tard_altri_sta_acc   number;
w_versato_tard_altri_sta_sal   number;
w_versato_fabb_d_com_acc       number;
w_versato_fabb_d_com_sal       number;
w_versato_tard_fabb_d_com_acc  number;
w_versato_tard_fabb_d_com_sal  number;
w_versato_fabb_d_sta_acc       number;
w_versato_fabb_d_sta_sal       number;
w_versato_tard_fabb_d_sta_acc  number;
w_versato_tard_fabb_d_sta_sal  number; */


FUNCTION F_DATA_SCAD
(a_anno                 IN     number
,a_tipo_vers            IN     varchar2
,a_tipo_scad            IN     varchar2
,a_data_scadenza        IN OUT date
) return string
IS
w_err                          varchar2(2000);
w_data                         date;
BEGIN
   w_err := null;
   BEGIN
      select scad.data_scadenza
        into w_data
        from scadenze scad
       where scad.tipo_tributo    = 'TASI'
         and scad.anno            = a_anno
         and nvl(scad.tipo_versamento,' ')
                                  = nvl(a_tipo_vers,' ')
         and scad.tipo_scadenza   = a_tipo_scad
      ;
      a_data_scadenza := w_data;
      Return w_err;
   EXCEPTION
      when no_data_found then
         if a_tipo_scad = 'V' then
            w_err := 'Scadenza di pagamento TASI ';
            if a_tipo_vers = 'A' then
               w_err := w_err||'in acconto';
            elsif a_tipo_vers = 'S' then
               w_err := w_err||'a saldo';
            else
               w_err := w_err||'unico';
            end if;
            w_err := w_err||' non prevista per anno '||to_char(a_anno);
         else
            w_err := 'Scadenza di presentazione denuncia TASI non prevista per anno '||
                     to_char(a_anno);
         end if;
         Return w_err;
      WHEN others THEN
         w_err := to_char(SQLCODE)||' - '||SQLERRM;
         Return w_err;
   END;
END F_DATA_SCAD;
FUNCTION F_IMP_SANZ
--
-- (VD - 19/09/2018): la funzione F_IMP_SANZ non viene modificata.
--                    Negli importi "_com" viene passato l'importo totale
--                    per tipologia.
--                    Gli importi "_sta" e gli importi dei fabbricati di
--                    tipo "D" vengono passati a 0 (zero).
--
(a_cod_sanzione        in     number
,a_importo             in     number
,a_rid                 in     number
,a_anno                in     number
,a_importo_ab          in     number
,a_importo_rur         in     number
,a_importo_ter_com     in     number
,a_importo_ter_sta     in     number
,a_importo_aree_com    in     number
,a_importo_aree_sta    in     number
,a_importo_altri_com   in     number
,a_importo_altri_sta   in     number
,a_importo_fabb_d_com  in     number
,a_importo_fabb_d_sta  in     number
,a_percentuale         in out number
,a_riduzione           in out number
,a_riduzione_2         in out number
,a_sanzione            in out number
,a_sanzione_ab         in out number
,a_sanzione_rur        in out number
,a_sanzione_ter_com    in out number
,a_sanzione_ter_sta    in out number
,a_sanzione_aree_com   in out number
,a_sanzione_aree_sta   in out number
,a_sanzione_altri_com  in out number
,a_sanzione_altri_sta  in out number
,a_sanzione_fabb_d_com in out number
,a_sanzione_fabb_d_sta in out number
) return string
IS
w_err                 varchar2(2000);
w_impo_sanz           number;
w_sanzione            number;
w_sanzione_minima     number;
BEGIN
   w_err := null;
   BEGIN
      select round(sanz.sanzione_minima / a_rid,2)
            ,sanz.sanzione
            ,round(sanz.percentuale / a_rid,2)
            ,sanz.riduzione
            ,sanz.riduzione_2
        into w_sanzione_minima
            ,w_sanzione
            ,a_percentuale
            ,a_riduzione
            ,a_riduzione_2
        from sanzioni sanz
       where tipo_tributo   = 'TASI'
         and cod_sanzione   = a_cod_sanzione
      ;
   EXCEPTION
      WHEN others THEN
         w_err := to_char(SQLCODE)||' - '||SQLERRM;
         Return w_err;
   END;

   if a_anno < 2012 then
     -- ICI --
      w_impo_sanz := f_round((a_importo * nvl(a_percentuale,0)) / 100,0);
      IF (nvl(w_sanzione_minima,0) > w_impo_sanz) THEN
         w_impo_sanz := nvl(w_sanzione_minima,0);
      END IF;
      a_sanzione := f_round(w_impo_sanz,0);
   else
      -- IMU --
      a_sanzione_ab         := f_round((a_importo_ab        * nvl(a_percentuale,0)) / 100,0);
      a_sanzione_rur        := f_round((a_importo_rur       * nvl(a_percentuale,0)) / 100,0);
      a_sanzione_ter_com    := f_round((a_importo_ter_com   * nvl(a_percentuale,0)) / 100,0);
      a_sanzione_ter_sta    := f_round((a_importo_ter_sta   * nvl(a_percentuale,0)) / 100,0);
      a_sanzione_aree_com   := f_round((a_importo_aree_com  * nvl(a_percentuale,0)) / 100,0);
      a_sanzione_aree_sta   := f_round((a_importo_aree_sta  * nvl(a_percentuale,0)) / 100,0);
      a_sanzione_altri_com  := f_round((a_importo_altri_com * nvl(a_percentuale,0)) / 100,0);
      a_sanzione_altri_sta  := f_round((a_importo_altri_sta * nvl(a_percentuale,0)) / 100,0);
      a_sanzione_fabb_d_com := f_round((a_importo_fabb_d_com * nvl(a_percentuale,0)) / 100,0);
      a_sanzione_fabb_d_sta := f_round((a_importo_fabb_d_sta * nvl(a_percentuale,0)) / 100,0);
      a_sanzione            := nvl(a_sanzione_ab,0) + nvl(a_sanzione_rur,0)
                             + nvl(a_sanzione_ter_com,0) + nvl(a_sanzione_ter_sta,0)
                             + nvl(a_sanzione_aree_com,0) + nvl(a_sanzione_aree_sta,0)
                             + nvl(a_sanzione_altri_com,0) + nvl(a_sanzione_altri_sta,0)
                             + nvl(a_sanzione_fabb_d_com,0) + nvl(a_sanzione_fabb_d_sta,0);
    end if;
   return w_err;
END F_IMP_SANZ;
FUNCTION F_IMP_SANZ_GG
--
-- (VD - 19/09/2018): la funzione F_IMP_SANZ_GG non viene modificata.
--                    Negli importi "_com" viene passato l'importo totale
--                    per tipologia.
--                    Gli importi "_sta" e gli importi dei fabbricati di
--                    tipo "D" vengono passati a 0 (zero).
--
(a_cod_sanzione        IN     number
,a_importo             IN     number
,a_rid                 IN     number
,a_diff_gg             IN     number
,a_anno                in     number
,a_importo_ab          in     number
,a_importo_rur         in     number
,a_importo_ter_com     in     number
,a_importo_ter_sta     in     number
,a_importo_aree_com    in     number
,a_importo_aree_sta    in     number
,a_importo_altri_com   in     number
,a_importo_altri_sta   in     number
,a_importo_fabb_d_com  in     number
,a_importo_fabb_d_sta  in     number
,a_percentuale         IN OUT number
,a_riduzione           IN OUT number
,a_riduzione_2         IN OUT number
,a_sanzione            IN OUT number
,a_sanzione_ab         in out number
,a_sanzione_rur        in out number
,a_sanzione_ter_com    in out number
,a_sanzione_ter_sta    in out number
,a_sanzione_aree_com   in out number
,a_sanzione_aree_sta   in out number
,a_sanzione_altri_com  in out number
,a_sanzione_altri_sta  in out number
,a_sanzione_fabb_d_com in out number
,a_sanzione_fabb_d_sta in out number
) return string
IS
w_err               varchar2(2000);
w_impo_sanz         number;
w_sanzione          number;
w_sanzione_minima   number;
BEGIN
   w_err := null;
   BEGIN
      select round(sanz.sanzione_minima / a_rid,2)
            ,sanz.sanzione
            ,round(sanz.percentuale * a_diff_gg / a_rid,2)
            ,sanz.riduzione
            ,sanz.riduzione_2
        into w_sanzione_minima
            ,w_sanzione
            ,a_percentuale
            ,a_riduzione
            ,a_riduzione_2
        from sanzioni sanz
       where tipo_tributo   = 'TASI'
         and cod_sanzione   = a_cod_sanzione
      ;
   EXCEPTION
      WHEN others THEN
         w_err := to_char(SQLCODE)||' - '||SQLERRM;
         Return w_err;
   END;

   if a_anno < 2012 then
     -- ICI --
      w_impo_sanz := f_round((a_importo * nvl(a_percentuale,0)) / 100,0);
      IF (nvl(w_sanzione_minima,0) > w_impo_sanz) THEN
         w_impo_sanz := nvl(w_sanzione_minima,0);
      END IF;
      a_sanzione := f_round(w_impo_sanz,0);
   else
      -- IMU --
      a_sanzione_ab         := f_round((a_importo_ab        * nvl(a_percentuale,0)) / 100,0);
      a_sanzione_rur        := f_round((a_importo_rur       * nvl(a_percentuale,0)) / 100,0);
      a_sanzione_ter_com    := f_round((a_importo_ter_com   * nvl(a_percentuale,0)) / 100,0);
      a_sanzione_ter_sta    := f_round((a_importo_ter_sta   * nvl(a_percentuale,0)) / 100,0);
      a_sanzione_aree_com   := f_round((a_importo_aree_com  * nvl(a_percentuale,0)) / 100,0);
      a_sanzione_aree_sta   := f_round((a_importo_aree_sta  * nvl(a_percentuale,0)) / 100,0);
      a_sanzione_altri_com  := f_round((a_importo_altri_com * nvl(a_percentuale,0)) / 100,0);
      a_sanzione_altri_sta  := f_round((a_importo_altri_sta * nvl(a_percentuale,0)) / 100,0);
      a_sanzione_fabb_d_com := f_round((a_importo_fabb_d_com * nvl(a_percentuale,0)) / 100,0);
      a_sanzione_fabb_d_sta := f_round((a_importo_fabb_d_sta * nvl(a_percentuale,0)) / 100,0);
      a_sanzione            := nvl(a_sanzione_ab,0) + nvl(a_sanzione_rur,0)
                             + nvl(a_sanzione_ter_com,0) + nvl(a_sanzione_ter_sta,0)
                             + nvl(a_sanzione_aree_com,0) + nvl(a_sanzione_aree_sta,0)
                             + nvl(a_sanzione_altri_com,0) + nvl(a_sanzione_altri_sta,0)
                             + nvl(a_sanzione_fabb_d_com,0) + nvl(a_sanzione_fabb_d_sta,0);
   end if;
   return w_err;
END F_IMP_SANZ_GG;
FUNCTION F_CALCOLO_INT
--
-- (VD - 19/09/2018): la funzione F_CALCOLO_INT non viene modificata.
--                    Negli importi "_com" viene passato l'importo totale
--                    per tipologia.
--                    Gli importi "_sta" e gli importi dei fabbricati di
--                    tipo "D" vengono passati a 0 (zero).
--
(a_importo              in     number
,a_dal                  in     date
,a_al                   in     date
,a_gg_anno              in     number
,a_anno                 in     number
,a_importo_ab           in     number
,a_importo_rur          in     number
,a_importo_ter_com      in     number
,a_importo_ter_sta      in     number
,a_importo_aree_com     in     number
,a_importo_aree_sta     in     number
,a_importo_altri_com    in     number
,a_importo_altri_sta    in     number
,a_importo_fabb_d_com   in     number
,a_importo_fabb_d_sta   in     number
,a_interessi            in out number
,a_interessi_ab         in out number
,a_interessi_rur        in out number
,a_interessi_ter_com    in out number
,a_interessi_ter_sta    in out number
,a_interessi_aree_com   in out number
,a_interessi_aree_sta   in out number
,a_interessi_altri_com  in out number
,a_interessi_altri_sta  in out number
,a_interessi_fabb_d_com in out number
,a_interessi_fabb_d_sta in out number
,a_note                 in out varchar2
) RETURN string
IS
w_err                          varchar2(2000);
w_dal                          date;
w_interessi                    number;
w_anno                         number(4);
w_mese                         number(2);
sTemp                          varchar2(4);
w_interesse_singolo            number;
w_note_singolo                 varchar2(2000);
w_note                         varchar2(2000) ;
w_interessi_ab                 number;
w_interessi_rur                number;
w_interessi_ter_com            number;
w_interessi_ter_sta            number;
w_interessi_aree_com           number;
w_interessi_aree_sta           number;
w_interessi_altri_com          number;
w_interessi_altri_sta          number;
w_interessi_fabb_d_com         number;
w_interessi_fabb_d_sta         number;
w_interesse_singolo_ab         number;
w_interesse_singolo_rur        number;
w_interesse_singolo_ter_com    number;
w_interesse_singolo_ter_sta    number;
w_interesse_singolo_aree_com   number;
w_interesse_singolo_aree_sta   number;
w_interesse_singolo_altri_com  number;
w_interesse_singolo_altri_sta  number;
w_interesse_singolo_fabb_d_com number;
w_interesse_singolo_fabb_d_sta number;
cursor sel_periodo (p_dal date,p_al date) is
select inte.aliquota
      ,greatest(inte.data_inizio,p_dal) dal
      ,least(inte.data_fine,p_al) al
  from interessi inte
 where inte.tipo_tributo      = 'TASI'
   and inte.data_inizio      <= p_al
   and inte.data_fine        >= p_dal
   and inte.tipo_interesse    = 'L'
;
BEGIN
   w_err                 := 'OK';
   w_interessi           := 0;
   w_interessi_ab        := 0;
   w_interessi_rur       := 0;
   w_interessi_ter_com   := 0;
   w_interessi_ter_sta   := 0;
   w_interessi_aree_com  := 0;
   w_interessi_aree_sta  := 0;
   w_interessi_altri_com := 0;
   w_interessi_altri_sta := 0;
   w_interessi_fabb_d_com := 0;
   w_interessi_fabb_d_sta := 0;
   w_note                := '';
   begin
      for rec_periodo IN sel_periodo(a_dal,a_al)
      loop
         if a_anno < 2012 then
           -- ICI --
            w_interesse_singolo := f_round(nvl(a_importo,0) * nvl(rec_periodo.aliquota,0) / 100 *
                                           (rec_periodo.al - rec_periodo.dal + 1) / a_gg_anno,0
                                          );
            w_interessi := w_interessi + w_interesse_singolo;
            w_note_singolo := 'Int: '||to_char(w_interesse_singolo)
                           ||' gg: '||to_char((rec_periodo.al - rec_periodo.dal + 1))
                           ||' dal: '||to_char(rec_periodo.dal,'dd/mm/yyyy')
                           ||' al: '||to_char(rec_periodo.al,'dd/mm/yyyy')
                           ||' aliq: '||to_char(nvl(rec_periodo.aliquota,0))
                           ||' imp: '||to_char(nvl(a_importo,0))
                           ||' - ';
            w_note := w_note || w_note_singolo;
            a_interessi := f_round(w_interessi,0);
         else
           -- IMU --
            w_interesse_singolo_ab := f_round(nvl(a_importo_ab,0) * nvl(rec_periodo.aliquota,0) / 100 *
                                           (rec_periodo.al - rec_periodo.dal + 1) / a_gg_anno,0
                                          );
            w_interessi_ab := w_interessi_ab + w_interesse_singolo_ab;

            w_interesse_singolo_rur := f_round(nvl(a_importo_rur,0) * nvl(rec_periodo.aliquota,0) / 100 *
                                           (rec_periodo.al - rec_periodo.dal + 1) / a_gg_anno,0
                                          );
            w_interessi_rur := w_interessi_rur + w_interesse_singolo_rur;

            w_interesse_singolo_ter_com := f_round(nvl(a_importo_ter_com,0) * nvl(rec_periodo.aliquota,0) / 100 *
                                           (rec_periodo.al - rec_periodo.dal + 1) / a_gg_anno,0
                                          );
            w_interessi_ter_com := w_interessi_ter_com + w_interesse_singolo_ter_com;

            w_interesse_singolo_ter_sta := f_round(nvl(a_importo_ter_sta,0) * nvl(rec_periodo.aliquota,0) / 100 *
                                           (rec_periodo.al - rec_periodo.dal + 1) / a_gg_anno,0
                                          );
            w_interessi_ter_sta := w_interessi_ter_sta + w_interesse_singolo_ter_sta;

            w_interesse_singolo_aree_com := f_round(nvl(a_importo_aree_com,0) * nvl(rec_periodo.aliquota,0) / 100 *
                                           (rec_periodo.al - rec_periodo.dal + 1) / a_gg_anno,0
                                          );
            w_interessi_aree_com := w_interessi_aree_com + w_interesse_singolo_aree_com;

            w_interesse_singolo_aree_sta := f_round(nvl(a_importo_aree_sta,0) * nvl(rec_periodo.aliquota,0) / 100 *
                                           (rec_periodo.al - rec_periodo.dal + 1) / a_gg_anno,0
                                          );
            w_interessi_aree_sta := w_interessi_aree_sta + w_interesse_singolo_aree_sta;

            w_interesse_singolo_altri_com := f_round(nvl(a_importo_altri_com,0) * nvl(rec_periodo.aliquota,0) / 100 *
                                           (rec_periodo.al - rec_periodo.dal + 1) / a_gg_anno,0
                                          );
            w_interessi_altri_com := w_interessi_altri_com + w_interesse_singolo_altri_com;

            w_interesse_singolo_altri_sta := f_round(nvl(a_importo_altri_sta,0) * nvl(rec_periodo.aliquota,0) / 100 *
                                           (rec_periodo.al - rec_periodo.dal + 1) / a_gg_anno,0
                                          );
            w_interessi_altri_sta := w_interessi_altri_sta + w_interesse_singolo_altri_sta;

            w_interesse_singolo_fabb_d_com := f_round(nvl(a_importo_fabb_d_com,0) * nvl(rec_periodo.aliquota,0) / 100 *
                                           (rec_periodo.al - rec_periodo.dal + 1) / a_gg_anno,0
                                          );
            w_interessi_fabb_d_com := w_interessi_fabb_d_com + w_interesse_singolo_fabb_d_com;

            w_interesse_singolo_fabb_d_sta := f_round(nvl(a_importo_fabb_d_sta,0) * nvl(rec_periodo.aliquota,0) / 100 *
                                           (rec_periodo.al - rec_periodo.dal + 1) / a_gg_anno,0
                                          );
            w_interessi_fabb_d_sta := w_interessi_fabb_d_sta + w_interesse_singolo_fabb_d_sta;


            w_interesse_singolo := w_interesse_singolo_ab + w_interesse_singolo_rur
                                 + w_interesse_singolo_ter_com + w_interesse_singolo_ter_sta
                                 + w_interesse_singolo_aree_com + w_interesse_singolo_aree_sta
                                 + w_interesse_singolo_altri_com + w_interesse_singolo_altri_sta
                                 + w_interesse_singolo_fabb_d_com + w_interesse_singolo_fabb_d_sta;
            w_interessi    := w_interessi + w_interesse_singolo;
            w_note_singolo := 'Int: '||to_char(w_interesse_singolo)
                           ||' gg: '||to_char((rec_periodo.al - rec_periodo.dal + 1))
                           ||' dal: '||to_char(rec_periodo.dal,'dd/mm/yyyy')
                           ||' al: '||to_char(rec_periodo.al,'dd/mm/yyyy')
                           ||' aliq: '||to_char(nvl(rec_periodo.aliquota,0))
                           ||' imp_ab: '||to_char(nvl(a_importo_ab,0))
                           ||' imp_rur: '||to_char(nvl(a_importo_rur,0))
                           ||' imp_ter_com: '||to_char(nvl(a_importo_ter_com,0))
                           ||' imp_ter_sta: '||to_char(nvl(a_importo_ter_sta,0))
                           ||' imp_aree_com: '||to_char(nvl(a_importo_aree_com,0))
                           ||' imp_aree_sta: '||to_char(nvl(a_importo_aree_sta,0))
                           ||' imp_altri_com: '||to_char(nvl(a_importo_altri_com,0))
                           ||' imp_altri_sta: '||to_char(nvl(a_importo_altri_sta,0))
                           ||' imp_fabb_d_com: '||to_char(nvl(a_importo_fabb_d_com,0))
                           ||' imp_fabb_d_sta: '||to_char(nvl(a_importo_fabb_d_sta,0))
                           ||' - ';
            w_note := w_note || w_note_singolo;
         end if;
      end loop;
      a_interessi            := f_round(w_interessi,0);
      a_interessi_ab         := f_round(w_interessi_ab,0);
      a_interessi_rur        := f_round(w_interessi_rur,0);
      a_interessi_ter_com    := f_round(w_interessi_ter_com,0);
      a_interessi_ter_sta    := f_round(w_interessi_ter_sta,0);
      a_interessi_aree_com   := f_round(w_interessi_aree_com,0);
      a_interessi_aree_sta   := f_round(w_interessi_aree_sta,0);
      a_interessi_altri_com  := f_round(w_interessi_altri_com,0);
      a_interessi_altri_sta  := f_round(w_interessi_altri_sta,0);
      a_interessi_fabb_d_com := f_round(w_interessi_fabb_d_com,0);
      a_interessi_fabb_d_sta := f_round(w_interessi_fabb_d_sta,0);
      a_note                 := w_note;
   EXCEPTION
      WHEN others THEN
         w_err := to_char(SQLCODE)||' - '||SQLERRM;
         Return w_err;
   end;
   Return w_err;
END F_CALCOLO_INT;
--
--                 R A V V E D I M E N T O
--
BEGIN
-- Salvatore ha verificato che in base alla risoluzione 296/E del 14/07/2008
-- nel calcolo degli interessi al denominatore si utilizza sempre 365 anche in caso di anni bisestili
-- (27/07/2009)
   w_giorni_anno := 365;

   w_errore := null;
   w_anno_scadenza := to_number(to_char(a_data_pagam,'yyyy'));
--
-- Si compone la stringa del comune per eventuali personalizzazioni.
--
   BEGIN
      select lpad(to_char(pro_cliente),3,'0')||
             lpad(to_char(com_cliente),3,'0')
        into w_comune
         from dati_generali
      ;
   END;

   w_data_rif_ravv := null;
   BEGIN
      select prtr.data
            ,prtr.data_rif_ravvedimento
            ,prtr.anno
            ,prtr.cod_fiscale
        into w_data_pratica
            ,w_data_rif_ravv
            ,w_anno
            ,w_cod_fiscale
        from pratiche_tributo prtr
       where prtr.pratica   = a_pratica
      ;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         w_errore := 'Pratica '||to_char(a_Pratica)||' assente';
         RAISE ERRORE;
   END;

   w_se_anno_fabb_d := 0;  -- Per la TASI lo imposto sempre a 0 (AB 19/6/15)

   --dbms_output.put_line('Data Pratica '||to_char(w_data_pratica,'dd/mm/yyyy')||' Anno '||
   --to_char(w_anno)||' Cf '||w_cod_fiscale);
   if w_anno < 1998 then
      w_errore := 'Gestione Non Prevista per Anni con Vecchio sanzionamento';
      RAISE ERRORE;
   end if;
--
-- Correttivo per Scadenze (personalizzazioni).
--
   w_delta_anni := 0;
--
   w_errore := F_DATA_SCAD(w_anno + w_delta_anni,null,'D',w_scadenza_present);
   if w_errore is not null then
      RAISE ERRORE;
   end if;
   --w_scadenza_pres_aa := w_scadenza_present;
   w_errore := F_DATA_SCAD(w_anno,'A','V',w_scadenza_acc);
   if w_errore is not null then
      RAISE ERRORE;
   end if;
   w_errore := F_DATA_SCAD(w_anno,'S','V',w_scadenza);
   if w_errore is not null then
      RAISE ERRORE;
   end if;
--dbms_output.put_line('Scadenze - Pres. '||to_char(w_scadenza_present,'dd/mm/yyyy')||' Acc. '||
--to_char(w_scadenza_acc,'dd/mm/yyyy')||' Sal. '||to_char(w_scadenza,'dd/mm/yyyy')||' delta '||
--to_char(w_delta_anni));
--
-- In questo test  si fa riferimento  con quanto concordato  con San Lazzaro  che a sua volta
-- fa riferimento alla circolare applicativa  184/E del 2001  in cui si dice che se nell`anno
-- del ravvedimento esistono denunce  dell`anno stesso con data  della pratica > alla data di
-- scadenza registrata  nei parametri  di input, la data di scadenza  entro cui ravvedersi e`
-- la data di scadenza  della presentazione  della denuncia  dell`anno successivo, altrimenti
-- e` la data di scadenza dell`anno del ravvedimento  in quanto trattasi di omesso o parziale
-- o tardivo pagamento a fronte di una denuncia senza alcuna variazione.
-- La circolare  in particolare  recita  "bisogna assumere  il termine di presentazione della
-- dichiarazione e non l`altro di un anno dall`omissione o dall`errore"  poiche` il regime di
-- autotassazione in materia di ICI e` analogo a quello previsto  per le imposte erariali sui
-- redditi.
-- Dall`indicatore  a_flag_infrazione  si sa se si e` in un caso o in un altro  poiche` viene
-- settato  solo in presenza  di denunce nell`anno con data superiore alla data di scadenza e
-- in questi casi puo` assumere solo i valore I = Infedele oppure O = Omessa.
-- In definitiva, se questo flag e` nullo non si aggiunge un anno alla data di scadenza della
-- presentazione della denuncia.
--
-- 18/10/2013 - x cambio di legislazione, in regime di IMU, la data di scadenza del ravvedimento
-- è sempre 90 giorni dopo la data di scadenza della denuncia per l'anno
--
  --
  -- 2024/03/21 (RV) : se specificata usa la data_rif_ravvedimento (obbligatoria dalla 4.9.2 #62695)
  --
  if w_data_rif_ravv is not null then
    w_scadenza_pres_rav := w_data_rif_ravv;
  else
    w_errore := F_DATA_SCAD(w_anno + w_delta_anni,null,'R',w_scadenza_pres_rav);
    if w_errore is not null then
      RAISE ERRORE;
    end if;
  end if;
  --
  if a_data_pagam > w_scadenza_pres_rav then
    w_errore := 'La Data del Ravvedimento '||to_char(a_data_pagam,'dd/mm/yyyy')||
                ' e` > alla Scadenza per Ravvedersi '||
                to_char(w_scadenza_pres_rav,'dd/mm/yyyy');
    RAISE ERRORE;
  end if;
  --

   BEGIN
      delete from sanzioni_pratica sapr
       where sapr.pratica = a_pratica
      ;
   END;
   BEGIN
      select count(*)
        into w_conta
        from sanzioni_pratica sapr
            ,pratiche_tributo prtr
       where sapr.pratica                      = prtr.pratica
         and prtr.cod_fiscale                  = w_cod_fiscale
         and prtr.anno                         = w_anno
         and prtr.tipo_tributo||''             = 'TASI'
         and nvl(prtr.stato_accertamento,'D')  ='D'
         and prtr.tipo_pratica                 = 'V'
         --
         -- (VD - 27/10/2017): aggiunti nuovi codici sanzione
         --
         and (    a_tipo_pagam                 = 'A'
              and sapr.cod_sanzione           in (151,152,155,157,158,165,166) --(151,152,155)
              or  a_tipo_pagam                 = 'S'
              and sapr.cod_sanzione           in (153,154,156,159,160,167,168) --(153,154,156)
              or  a_tipo_pagam                 = 'U'
              and sapr.cod_sanzione           in (151,152,153,154,155,
                                                  156,157,158,159,160,
                                                  165,166,167,168)             --(151,152,153,154,155,156)
             )
      ;
      if w_conta > 0 then
         w_errore := 'Esistono altre Pratiche di Ravvedimento per questo Pagamento';
         RAISE ERRORE;
      end if;
   END;
   BEGIN
      select nvl(sum(nvl(ogim.imposta_acconto,0)),0)
            ,nvl(sum(nvl(ogim.imposta,0) - nvl(ogim.imposta_acconto,0)),0)
            ,nvl(sum(nvl(ogim.imposta,0)),0)
        into w_imposta_acc
            ,w_imposta_sal
            ,w_imposta
        from oggetti_imposta  ogim
            ,oggetti_pratica  ogpr
       where ogpr.oggetto_pratica   = ogim.oggetto_pratica
         and ogpr.pratica           = a_pratica
         and ogim.imposta_mini is null
      ;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         w_imposta := 0;
   END;
   --dbms_output.put_line('Imposta - Acconto '||to_char(w_imposta_acc)||' Saldo '||
   --to_char(w_imposta_sal));
   -- TASI --
   --
   -- Modifica del 02/12/2015: le variabili relative ai fabbricati D
   --                          vengono valorizzate a zero
   --
   BEGIN
/*      select sum(decode(ogim.tipo_aliquota
                       ,2,nvl(ogim.imposta,0)
                       ,0
                       )
                )                                                               imposta_ab
           , sum(decode(ogim.tipo_aliquota
                       ,2,nvl(ogim.imposta_acconto,0)
                       ,0
                       )
                )                                                               imposta_ab_acc
           , sum(decode(ogim.tipo_aliquota
                       ,2,nvl(ogim.imposta,0) - nvl(ogim.imposta_acconto,0)
                       ,0
                       )
                )                                                               imposta_ab_sal
           , sum(decode(ogim.tipo_aliquota
                       ,2,1
                       ,0
                       )
                 )                                                              n_fab_ab
           , sum(nvl(ogim.detrazione,0))                                        detrazione
           , sum(nvl(ogim.detrazione_acconto,0))                                detrazione_acc
           , sum(nvl(ogim.detrazione,0) - nvl(ogim.detrazione_acconto,0))       detrazione_sal
           , sum(decode(ogim.tipo_aliquota
                       ,2,0
                       ,decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                              ,1,0
                              ,2,0
                              ,decode(aliquota_erariale
                                     ,null,nvl(ogim.imposta,0)
                                     ,0
                                     )
                              )
                        )
                 )                                                              imposta_rur
           , sum(decode(ogim.tipo_aliquota
                       ,2,0
                       ,decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                              ,1,0
                              ,2,0
                              ,decode(aliquota_erariale
                                     ,null,nvl(ogim.imposta_acconto,0)
                                     ,0
                                     )
                              )
                        )
                 )                                                              imposta_rur_acc
           , sum(decode(ogim.tipo_aliquota
                       ,2,0
                       ,decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                              ,1,0
                              ,2,0
                              ,decode(aliquota_erariale
                                     ,null,nvl(ogim.imposta,0) - nvl(ogim.imposta_acconto,0)
                                     ,0
                                     )
                              )
                        )
                 )                                                              imposta_rur_sal
           , sum(decode(ogim.tipo_aliquota
                       ,2,0
                       ,decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                              ,1,0
                              ,2,0
                              ,decode(aliquota_erariale
                                     ,null,1
                                     ,0
                                     )
                              )
                       )
                )                                                               n_fab_rur
            , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                        ,1,nvl(ogim.imposta,0) - nvl(ogim.imposta_erariale,0)
                        ,0
                        )
                 )                                                              imposta_ter_com
            , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                        ,1,nvl(ogim.imposta_acconto,0) - nvl(ogim.imposta_erariale_acconto,0)
                        ,0
                        )
                 )                                                              imposta_ter_com_acc
            , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                        ,1,(nvl(ogim.imposta,0) - nvl(ogim.imposta_acconto,0)) -
                           (nvl(ogim.imposta_erariale,0) - nvl(ogim.imposta_erariale_acconto,0))
                        ,0
                        )
                 )                                                              imposta_ter_com_sal
            , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                        ,1,nvl(ogim.imposta_erariale,0)
                        ,0
                        )
                 )                                                              imposta_ter_sta
            , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                        ,1,nvl(ogim.imposta_erariale_acconto,0)
                        ,0
                        )
                 )                                                              imposta_ter_sta_acc
            , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                        ,1,nvl(ogim.imposta_erariale,0) - nvl(ogim.imposta_erariale_acconto,0)
                        ,0
                        )
                 )                                                              imposta_ter_sta_sal

            , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                        ,2,nvl(ogim.imposta,0) - nvl(ogim.imposta_erariale,0)
                        ,0
                        )
                 )                                                              imposta_aree_com
            , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                        ,2,nvl(ogim.imposta_acconto,0) - nvl(ogim.imposta_erariale_acconto,0)
                        ,0
                        )
                 )                                                              imposta_aree_com_acc
            , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                        ,2,(nvl(ogim.imposta,0) - nvl(ogim.imposta_acconto,0)) -
                           (nvl(ogim.imposta_erariale,0) - nvl(ogim.imposta_erariale_acconto,0))
                        ,0
                        )
                 )                                                              imposta_aree_com_sal
            , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                        ,2,nvl(ogim.imposta_erariale,0)
                        ,0
                        )
                 )                                                              imposta_aree_sta
            , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                        ,2,nvl(ogim.imposta_erariale_acconto,0)
                        ,0
                        )
                 )                                                              imposta_aree_sta_acc
            , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                        ,2,nvl(ogim.imposta_erariale,0) - nvl(ogim.imposta_erariale_acconto,0)
                        ,0
                        )
                 )                                                              imposta_aree_sta_sal
            , sum(decode(ogim.tipo_aliquota
                        ,2,0
                        ,decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                               ,1,0
                               ,2,0
                               ,decode(aliquota_erariale
                                      ,null,0
                                      ,nvl(ogim.imposta,0) - nvl(ogim.imposta_erariale,0)
                                      )
                               )
                        )
                 )                                                              imposta_altri_com
            , sum(decode(ogim.tipo_aliquota
                        ,2,0
                        ,decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                               ,1,0
                               ,2,0
                               ,decode(aliquota_erariale
                                      ,null,0
                                      ,nvl(ogim.imposta_acconto,0) - nvl(ogim.imposta_erariale_acconto,0)
                                      )
                               )
                        )
                 )                                                              imposta_altri_com_acc
            , sum(decode(ogim.tipo_aliquota
                        ,2,0
                        ,decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                               ,1,0
                               ,2,0
                               ,decode(aliquota_erariale
                                      ,null,0
                                      ,(nvl(ogim.imposta,0) - nvl(ogim.imposta_erariale,0)) -
                                       (nvl(ogim.imposta_acconto,0) - nvl(ogim.imposta_erariale_acconto,0))
                                      )
                               )
                        )
                 )                                                              imposta_altri_com_sal
            , sum(decode(ogim.tipo_aliquota
                        ,2,0
                        ,decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                               ,1,0
                               ,2,0
                               ,decode(aliquota_erariale
                                      ,null,0
                                      ,nvl(ogim.imposta_erariale,0)
                                      )
                               )
                        )
                 )                                                              imposta_altri_sta
            , sum(decode(ogim.tipo_aliquota
                        ,2,0
                        ,decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                               ,1,0
                               ,2,0
                               ,decode(aliquota_erariale
                                      ,null,0
                                      ,nvl(ogim.imposta_erariale_acconto,0)
                                      )
                               )
                        )
                 )                                                              imposta_altri_sta_acc
            , sum(decode(ogim.tipo_aliquota
                        ,2,0
                        ,decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                               ,1,0
                               ,2,0
                               ,decode(aliquota_erariale
                                      ,null,0
                                      ,nvl(ogim.imposta_erariale,0) - nvl(ogim.imposta_erariale_acconto,0)
                                      )
                               )
                        )
                 )                                                              imposta_altri_sta_sal
            , sum(decode(ogim.tipo_aliquota
                        ,2,0
                        ,decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                               ,1,0
                               ,2,0
                               ,decode(aliquota_erariale
                                      ,null,0
                                      ,1
                                      )
                               )
                        )
                 )                                                              n_fab_altri
            --, sum(decode(ogim.tipo_aliquota
            --            ,9,decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
            --                     ,1,0
            --                     ,2,0
            --                     ,decode(substr(ogpr.categoria_catasto,1,1)
            --                            ,'D',decode(w_se_anno_fabb_d
            --                                      ,1,nvl(ogim.imposta,0) - nvl(ogim.imposta_erariale,0)
            --                                       ,0
            --                                       )
            --                            ,0
            --                            )
            --                     )
            --         ,0  )
            --     )                                                              imposta_fabb_d_com
            , 0                                                                 imposta_fabb_d_com
            --, sum(decode(ogim.tipo_aliquota
            --            ,9,decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
            --                     ,1,0
            --                     ,2,0
            --                     ,decode(substr(ogpr.categoria_catasto,1,1)
            --                            ,'D',decode(w_se_anno_fabb_d
            --                                       ,1,nvl(ogim.imposta_acconto,0) - nvl(ogim.imposta_erariale_acconto,0)
            --                                       ,0
            --                                       )
            --                            ,0
            --                            )
            --                     )
            --          ,0  )
            --     )                                                              imposta_fabb_d_com_acc
            , 0                                                                 imposta_fabb_d_com_acc
            --, sum(decode(ogim.tipo_aliquota
            --            ,9,decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
            --                     ,1,0
            --                     ,2,0
            --                     ,decode(substr(ogpr.categoria_catasto,1,1)
            --                            ,'D',decode(w_se_anno_fabb_d
            --                                       ,1,nvl(ogim.imposta,0) - nvl(ogim.imposta_erariale,0) -
            --                                          (nvl(ogim.imposta_acconto,0) - nvl(ogim.imposta_erariale_acconto,0))
            --                                       ,0
            --                                       )
            --                            ,0
            --                            )
            --                     )
            --          ,0  )
            --     )                                                              imposta_fabb_d_com_sal
            , 0                                                                 imposta_fabb_d_com_sal
            --, sum(decode(ogim.tipo_aliquota
            --            ,9,decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
            --                     ,1,0
            --                     ,2,0
            --                     ,decode(substr(ogpr.categoria_catasto,1,1)
            --                            ,'D',decode(w_se_anno_fabb_d
            --                                       ,1,nvl(ogim.imposta_erariale,0)
            --                                       ,0
            --                                       )
            --                            ,0
            --                            )
            --                     )
            --          ,0  )
            --     )                                                              imposta_fabb_d_sta
            , 0                                                                 imposta_fabb_d_sta
            --, sum(decode(ogim.tipo_aliquota
            --            ,9,decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
            --                     ,1,0
            --                     ,2,0
            --                     ,decode(substr(ogpr.categoria_catasto,1,1)
            --                            ,'D',decode(w_se_anno_fabb_d
            --                                       ,1,nvl(ogim.imposta_erariale_acconto,0)
            --                                       ,0
            --                                       )
            --                            ,0
            --                            )
            --                     )
            --          ,0  )
            --     )                                                              imposta_fabb_d_sta_acc
            , 0                                                                 imposta_fabb_d_sta_acc
            --, sum(decode(ogim.tipo_aliquota
            --            ,9,decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
            --                     ,1,0
            --                     ,2,0
            --                     ,decode(substr(ogpr.categoria_catasto,1,1)
            --                            ,'D',decode(w_se_anno_fabb_d
            --                                       ,1,nvl(ogim.imposta_erariale,0) -
            --                                          nvl(ogim.imposta_erariale_acconto,0)
            --                                       ,0
            --                                       )
            --                            ,0
            --                            )
            --                     )
            --          ,0  )
            --     )                                                              imposta_fabb_d_sta_sal
            , 0                                                                 imposta_fabb_d_sta_sal
            --, sum(decode(ogim.tipo_aliquota
            --            ,9,decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
            --                     ,1,0
            --                     ,2,0
            --                     ,decode(substr(ogpr.categoria_catasto,1,1)
            --                            ,'D',w_se_anno_fabb_d
            --                            ,0
            --                            )
            --                     )
            --          ,0  )
            --     )                                                              n_fab_fabb_d
            , 0                                                                 n_fab_fabb_d
        into w_imposta_ab
           , w_imposta_ab_acc
           , w_imposta_ab_sal
           , w_n_fab_ab
           , w_detrazione
           , w_detrazione_acc
           , w_detrazione_sal
           , w_imposta_rur
           , w_imposta_rur_acc
           , w_imposta_rur_sal
           , w_n_fab_rur
           , w_imposta_ter_com
           , w_imposta_ter_com_acc
           , w_imposta_ter_com_sal
           , w_imposta_ter_sta
           , w_imposta_ter_sta_acc
           , w_imposta_ter_sta_sal
           , w_imposta_aree_com
           , w_imposta_aree_com_acc
           , w_imposta_aree_com_sal
           , w_imposta_aree_sta
           , w_imposta_aree_sta_acc
           , w_imposta_aree_sta_sal
           , w_imposta_altri_com
           , w_imposta_altri_com_acc
           , w_imposta_altri_com_sal
           , w_imposta_altri_sta
           , w_imposta_altri_sta_acc
           , w_imposta_altri_sta_sal
           , w_n_fab_altri
           , w_imposta_fabb_d_com
           , w_imposta_fabb_d_com_acc
           , w_imposta_fabb_d_com_sal
           , w_imposta_fabb_d_sta
           , w_imposta_fabb_d_sta_acc
           , w_imposta_fabb_d_sta_sal
           , w_n_fab_fabb_d
        from oggetti_imposta  ogim
           , oggetti_pratica  ogpr
           , oggetti          ogge
       where ogpr.oggetto_pratica   = ogim.oggetto_pratica
         and ogpr.oggetto           = ogge.oggetto
         and ogpr.pratica           = a_pratica
         and ogim.imposta_mini is null
      ; */
      select sum(decode(ogim.tipo_aliquota
                       ,2,nvl(ogim.imposta,0)
                       ,0
                       )
                )                                                               imposta_ab
           , sum(decode(ogim.tipo_aliquota
                       ,2,nvl(ogim.imposta_acconto,0)
                       ,0
                       )
                )                                                               imposta_ab_acc
           , sum(decode(ogim.tipo_aliquota
                       ,2,nvl(ogim.imposta,0) - nvl(ogim.imposta_acconto,0)
                       ,0
                       )
                )                                                               imposta_ab_sal
           , sum(decode(ogim.tipo_aliquota
                       ,2,1
                       ,0
                       )
                 )                                                              n_fab_ab
           , sum(nvl(ogim.detrazione,0))                                        detrazione
           , sum(nvl(ogim.detrazione_acconto,0))                                detrazione_acc
           , sum(nvl(ogim.detrazione,0) - nvl(ogim.detrazione_acconto,0))       detrazione_sal
           , sum(decode(ogim.tipo_aliquota
                       ,2,0
                       ,decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                              ,1,0
                              ,2,0
                              ,decode(aliquota_erariale
                                     ,null,nvl(ogim.imposta,0)
                                     ,0
                                     )
                              )
                        )
                 )                                                              imposta_rur
           , sum(decode(ogim.tipo_aliquota
                       ,2,0
                       ,decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                              ,1,0
                              ,2,0
                              ,decode(aliquota_erariale
                                     ,null,nvl(ogim.imposta_acconto,0)
                                     ,0
                                     )
                              )
                        )
                 )                                                              imposta_rur_acc
           , sum(decode(ogim.tipo_aliquota
                       ,2,0
                       ,decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                              ,1,0
                              ,2,0
                              ,decode(aliquota_erariale
                                     ,null,nvl(ogim.imposta,0) - nvl(ogim.imposta_acconto,0)
                                     ,0
                                     )
                              )
                        )
                 )                                                              imposta_rur_sal
           , sum(decode(ogim.tipo_aliquota
                       ,2,0
                       ,decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                              ,1,0
                              ,2,0
                              ,decode(aliquota_erariale
                                     ,null,1
                                     ,0
                                     )
                              )
                       )
                )                                                               n_fab_rur
            , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                        ,1,nvl(ogim.imposta,0)
                        ,0
                        )
                 )                                                              imposta_ter
            , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                        ,1,nvl(ogim.imposta_acconto,0)
                        ,0
                        )
                 )                                                              imposta_ter_acc
            , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                        ,1,(nvl(ogim.imposta,0) - nvl(ogim.imposta_acconto,0))
                        ,0
                        )
                 )                                                              imposta_ter_sal
            , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                        ,2,nvl(ogim.imposta,0)
                        ,0
                        )
                 )                                                              imposta_aree
            , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                        ,2,nvl(ogim.imposta_acconto,0)
                        ,0
                        )
                 )                                                              imposta_aree_acc
            , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                        ,2,(nvl(ogim.imposta,0) - nvl(ogim.imposta_acconto,0))
                        ,0
                        )
                 )                                                              imposta_aree_sal
            , sum(decode(ogim.tipo_aliquota
                        ,2,0
                        ,decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                               ,1,0
                               ,2,0
                               ,decode(aliquota_erariale
                                      ,null,0
                                           ,nvl(ogim.imposta,0)
                                      )
                               )
                        )
                 )                                                              imposta_altri
            , sum(decode(ogim.tipo_aliquota
                        ,2,0
                        ,decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                               ,1,0
                               ,2,0
                               ,decode(aliquota_erariale
                                      ,null,0
                                           ,nvl(ogim.imposta_acconto,0)
                                      )
                               )
                        )
                 )                                                              imposta_altri_acc
            , sum(decode(ogim.tipo_aliquota
                        ,2,0
                        ,decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                               ,1,0
                               ,2,0
                               ,decode(aliquota_erariale
                                      ,null,0
                                           ,nvl(ogim.imposta,0) - nvl(ogim.imposta_acconto,0)
                                      )
                               )
                        )
                 )                                                              imposta_altri_sal
            , sum(decode(ogim.tipo_aliquota
                        ,2,0
                        ,decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                               ,1,0
                               ,2,0
                               ,decode(aliquota_erariale
                                      ,null,0
                                      ,1
                                      )
                               )
                        )
                 )                                                              n_fab_altri
        into w_imposta_ab
           , w_imposta_ab_acc
           , w_imposta_ab_sal
           , w_n_fab_ab
           , w_detrazione
           , w_detrazione_acc
           , w_detrazione_sal
           , w_imposta_rur
           , w_imposta_rur_acc
           , w_imposta_rur_sal
           , w_n_fab_rur
           , w_imposta_ter
           , w_imposta_ter_acc
           , w_imposta_ter_sal
           , w_imposta_aree
           , w_imposta_aree_acc
           , w_imposta_aree_sal
           , w_imposta_altri
           , w_imposta_altri_acc
           , w_imposta_altri_sal
           , w_n_fab_altri
        from oggetti_imposta  ogim
           , oggetti_pratica  ogpr
           , oggetti          ogge
       where ogpr.oggetto_pratica   = ogim.oggetto_pratica
         and ogpr.oggetto           = ogge.oggetto
         and ogpr.pratica           = a_pratica
         and ogim.imposta_mini is null
      ;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         w_imposta_ab                   := 0;
         w_imposta_ab_acc               := 0;
         w_imposta_ab_sal               := 0;
         w_n_fab_ab                     := 0;
         w_detrazione                   := 0;
         w_detrazione_acc               := 0;
         w_detrazione_sal               := 0;
         w_imposta_rur                  := 0;
         w_imposta_rur_acc              := 0;
         w_imposta_rur_sal              := 0;
         w_n_fab_rur                    := 0;
         w_imposta_ter                  := 0;
         w_imposta_ter_acc              := 0;
         w_imposta_ter_sal              := 0;
         w_imposta_aree                 := 0;
         w_imposta_aree_acc             := 0;
         w_imposta_aree_sal             := 0;
         w_imposta_altri                := 0;
         w_imposta_altri_acc            := 0;
         w_imposta_altri_sal            := 0;
         w_n_fab_altri                  := 0;
   END;
   --
   -- Per non complicare troppo la select togliamo qui dagli altri i fabbricati d (fabbricati ad uso produttivo)
   --
   -- Modifica del 02/12/2015: visto che i fabbricati D devono essere considerati
   -- insieme agli "altri fabbricati", si commentano le sottrazioni sottoindicate
   --
   --         w_imposta_altri_com            := w_imposta_altri_com - w_imposta_fabb_d_com;
   --         w_imposta_altri_com_acc        := w_imposta_altri_com_acc - w_imposta_fabb_d_com_acc;
   --         w_imposta_altri_com_sal        := w_imposta_altri_com_sal - w_imposta_fabb_d_com_sal;
   --         w_imposta_altri_sta            := w_imposta_altri_sta - w_imposta_fabb_d_sta;
   --         w_imposta_altri_sta_acc        := w_imposta_altri_sta_acc - w_imposta_fabb_d_sta_acc;
   --         w_imposta_altri_sta_sal        := w_imposta_altri_sta_sal - w_imposta_fabb_d_sta_sal;
   --         w_n_fab_altri                  := w_n_fab_altri - w_n_fab_fabb_d;

-- (VD - 03/08/2021): Arrotondamenti. Per evitare l'emissione del ravvedimento
--                    a causa dei versamenti arrotondati, si arrotondano gli
--                    importi relativi all'imposta
--                    P.S. Non ho capito a cosa servono le detrazioni, visto
--                         che non vengono mai utilizzate ...
   w_imposta_ab                   := round(w_imposta_ab,0);
   w_imposta_ab_acc               := round(w_imposta_ab_acc,0);
   w_imposta_ab_sal               := round(w_imposta_ab_sal,0);
   w_detrazione                   := round(w_detrazione,0);
   w_detrazione_acc               := round(w_detrazione_acc,0);
   w_detrazione_sal               := round(w_detrazione_sal,0);
   w_imposta_rur                  := round(w_imposta_rur,0);
   w_imposta_rur_acc              := round(w_imposta_rur_acc,0);
   w_imposta_rur_sal              := round(w_imposta_rur_sal,0);
   w_imposta_ter                  := round(w_imposta_ter,0);
   w_imposta_ter_acc              := round(w_imposta_ter_acc,0);
   w_imposta_ter_sal              := round(w_imposta_ter_sal,0);
   w_imposta_aree                 := round(w_imposta_aree,0);
   w_imposta_aree_acc             := round(w_imposta_aree_acc,0);
   w_imposta_aree_sal             := round(w_imposta_aree_sal,0);
   w_imposta_altri                := round(w_imposta_altri,0);
   w_imposta_altri_acc            := round(w_imposta_altri_acc,0);
   w_imposta_altri_sal            := round(w_imposta_altri_sal,0);
--
   BEGIN
/*      select nvl(sum(decode(vers.tipo_versamento
                           ,'S',0
                           ,'A',nvl(vers.importo_versato,0)
                               ,decode(sign(nvl(vers.importo_versato,0) - w_imposta_acc)
                                      ,-1,nvl(vers.importo_versato,0)
                                         ,w_imposta_acc
                                      )
                           )
                    ),0
                )                                                               versato_acc
            ,nvl(sum(decode(vers.tipo_versamento
                           ,'A',0
                           ,'S',nvl(vers.importo_versato,0)
                               ,decode(sign(nvl(vers.importo_versato,0) - w_imposta_acc)
                                      ,-1,0
                                         ,nvl(vers.importo_versato,0) - w_imposta_acc
                                      )
                           )
                    ),0
                )                                                               versato_sal
            ,nvl(sum(decode(vers.tipo_versamento
                           ,'S',0
                           ,'A',decode(sign(vers.data_pagamento - w_scadenza_acc)
                                      ,1,nvl(vers.importo_versato,0)
                                        ,0
                                      )
                               ,decode(sign(vers.data_pagamento - w_scadenza_acc)
                                      ,1,decode(sign(nvl(vers.importo_versato,0) -
                                                     w_imposta_acc
                                                    )
                                               ,-1,nvl(vers.importo_versato,0)
                                                  ,0
                                               )
                                        ,0
                                      )
                           )
                    ),0
                )                                                               versato_tard_acc
            ,nvl(sum(decode(vers.tipo_versamento
                           ,'A',0
                           ,'S',decode(sign(vers.data_pagamento - w_scadenza)
                                      ,1,nvl(vers.importo_versato,0)
                                        ,0
                                      )
                               ,decode(sign(vers.data_pagamento - w_scadenza)
                                      ,1,decode(sign(nvl(vers.importo_versato,0) -
                                                     w_imposta_acc
                                                    )
                                               ,-1,0
                                                  ,nvl(vers.importo_versato,0) -
                                                   w_imposta_acc
                                               )
                                        ,0
                                      )
                           )
                    ),0
                )                                                               versato_tard_sal
           , nvl(sum(decode(vers.tipo_versamento
                           ,'S',0
                           ,'A',nvl(vers.ab_principale ,0)
                               ,decode(sign(nvl(vers.ab_principale,0) - w_imposta_ab_acc)
                                      ,-1,nvl(vers.ab_principale,0)
                                         ,w_imposta_ab_acc
                                      )
                           )
                    ),0
                )                                                               w_versato_ab_acc
            ,nvl(sum(decode(vers.tipo_versamento
                           ,'A',0
                           ,'S',nvl(vers.ab_principale,0)
                               ,decode(sign(nvl(vers.ab_principale,0) - w_imposta_ab_acc)
                                      ,-1,0
                                         ,nvl(vers.ab_principale,0) - w_imposta_ab_acc
                                      )
                           )
                    ),0
                )                                                               versato_ab_sal
            ,nvl(sum(decode(vers.tipo_versamento
                           ,'S',0
                           ,'A',decode(sign(vers.data_pagamento - w_scadenza_acc)
                                      ,1,nvl(vers.ab_principale,0)
                                        ,0
                                      )
                               ,decode(sign(vers.data_pagamento - w_scadenza_acc)
                                      ,1,decode(sign(nvl(vers.ab_principale,0) -
                                                     w_imposta_ab_acc
                                                    )
                                               ,-1,nvl(vers.ab_principale,0)
                                                  ,0
                                               )
                                        ,0
                                      )
                           )
                    ),0
                )                                                               versato_tard_ab_acc
            ,nvl(sum(decode(vers.tipo_versamento
                           ,'A',0
                           ,'S',decode(sign(vers.data_pagamento - w_scadenza)
                                      ,1,nvl(vers.ab_principale,0)
                                        ,0
                                      )
                               ,decode(sign(vers.data_pagamento - w_scadenza)
                                      ,1,decode(sign(nvl(vers.ab_principale,0) -
                                                     w_imposta_ab_acc
                                                    )
                                               ,-1,0
                                                  ,nvl(vers.ab_principale,0) -
                                                   w_imposta_ab_acc
                                               )
                                        ,0
                                      )
                           )
                    ),0
                )                                                               versato_tard_ab_sal
           , nvl(sum(decode(vers.tipo_versamento
                           ,'S',0
                           ,'A',nvl(vers.rurali ,0)
                               ,decode(sign(nvl(vers.rurali,0) - w_imposta_rur_acc)
                                      ,-1,nvl(vers.rurali,0)
                                         ,w_imposta_rur_acc
                                      )
                           )
                    ),0
                )                                                               w_versato_rur_acc
            ,nvl(sum(decode(vers.tipo_versamento
                           ,'A',0
                           ,'S',nvl(vers.rurali,0)
                               ,decode(sign(nvl(vers.rurali,0) - w_imposta_rur_acc)
                                      ,-1,0
                                         ,nvl(vers.rurali,0) - w_imposta_rur_acc
                                      )
                           )
                    ),0
                )                                                               versato_rur_sal
            ,nvl(sum(decode(vers.tipo_versamento
                           ,'S',0
                           ,'A',decode(sign(vers.data_pagamento - w_scadenza_acc)
                                      ,1,nvl(vers.rurali,0)
                                        ,0
                                      )
                               ,decode(sign(vers.data_pagamento - w_scadenza_acc)
                                      ,1,decode(sign(nvl(vers.rurali,0) -
                                                     w_imposta_rur_acc
                                                    )
                                               ,-1,nvl(vers.rurali,0)
                                                  ,0
                                               )
                                        ,0
                                      )
                           )
                    ),0
                )                                                               versato_tard_rur_acc
            ,nvl(sum(decode(vers.tipo_versamento
                           ,'A',0
                           ,'S',decode(sign(vers.data_pagamento - w_scadenza)
                                      ,1,nvl(vers.rurali,0)
                                        ,0
                                      )
                               ,decode(sign(vers.data_pagamento - w_scadenza)
                                      ,1,decode(sign(nvl(vers.rurali,0) -
                                                     w_imposta_rur_acc
                                                    )
                                               ,-1,0
                                                  ,nvl(vers.rurali,0) -
                                                   w_imposta_rur_acc
                                               )
                                        ,0
                                      )
                           )
                    ),0
                )                                                               versato_tard_rur_sal
           , nvl(sum(decode(vers.tipo_versamento
                           ,'S',0
                           ,'A',nvl(vers.terreni_comune ,0)
                               ,decode(sign(nvl(vers.terreni_comune,0) - w_imposta_ter_com_acc)
                                      ,-1,nvl(vers.terreni_comune,0)
                                         ,w_imposta_ter_com_acc
                                      )
                           )
                    ),0
                )                                                               w_versato_ter_com_acc
            ,nvl(sum(decode(vers.tipo_versamento
                           ,'A',0
                           ,'S',nvl(vers.terreni_comune,0)
                               ,decode(sign(nvl(vers.terreni_comune,0) - w_imposta_ter_com_acc)
                                      ,-1,0
                                         ,nvl(vers.terreni_comune,0) - w_imposta_ter_com_acc
                                      )
                           )
                    ),0
                )                                                               versato_ter_com_sal
            ,nvl(sum(decode(vers.tipo_versamento
                           ,'S',0
                           ,'A',decode(sign(vers.data_pagamento - w_scadenza_acc)
                                      ,1,nvl(vers.terreni_comune,0)
                                        ,0
                                      )
                               ,decode(sign(vers.data_pagamento - w_scadenza_acc)
                                      ,1,decode(sign(nvl(vers.terreni_comune,0) -
                                                     w_imposta_ter_com_acc
                                                    )
                                               ,-1,nvl(vers.terreni_comune,0)
                                                  ,0
                                               )
                                        ,0
                                      )
                           )
                    ),0
                )                                                               versato_tard_ter_com_acc
            ,nvl(sum(decode(vers.tipo_versamento
                           ,'A',0
                           ,'S',decode(sign(vers.data_pagamento - w_scadenza)
                                      ,1,nvl(vers.terreni_comune,0)
                                        ,0
                                      )
                               ,decode(sign(vers.data_pagamento - w_scadenza)
                                      ,1,decode(sign(nvl(vers.terreni_comune,0) -
                                                     w_imposta_ter_com_acc
                                                    )
                                               ,-1,0
                                                  ,nvl(vers.terreni_comune,0) -
                                                   w_imposta_ter_com_acc
                                               )
                                        ,0
                                      )
                           )
                    ),0
                )                                                               versato_tard_ter_com_sal
           , nvl(sum(decode(vers.tipo_versamento
                           ,'S',0
                           ,'A',nvl(vers.terreni_erariale ,0)
                               ,decode(sign(nvl(vers.terreni_erariale,0) - w_imposta_ter_sta_acc)
                                      ,-1,nvl(vers.terreni_erariale,0)
                                         ,w_imposta_ter_sta_acc
                                      )
                           )
                    ),0
                )                                                               w_versato_ter_sta_acc
            ,nvl(sum(decode(vers.tipo_versamento
                           ,'A',0
                           ,'S',nvl(vers.terreni_erariale,0)
                               ,decode(sign(nvl(vers.terreni_erariale,0) - w_imposta_ter_sta_acc)
                                      ,-1,0
                                         ,nvl(vers.terreni_erariale,0) - w_imposta_ter_sta_acc
                                      )
                           )
                    ),0
                )                                                               versato_ter_sta_sal
            ,nvl(sum(decode(vers.tipo_versamento
                           ,'S',0
                           ,'A',decode(sign(vers.data_pagamento - w_scadenza_acc)
                                      ,1,nvl(vers.terreni_erariale,0)
                                        ,0
                                      )
                               ,decode(sign(vers.data_pagamento - w_scadenza_acc)
                                      ,1,decode(sign(nvl(vers.terreni_erariale,0) -
                                                     w_imposta_ter_sta_acc
                                                    )
                                               ,-1,nvl(vers.terreni_erariale,0)
                                                  ,0
                                               )
                                        ,0
                                      )
                           )
                    ),0
                )                                                               versato_tard_ter_sta_acc
            ,nvl(sum(decode(vers.tipo_versamento
                           ,'A',0
                           ,'S',decode(sign(vers.data_pagamento - w_scadenza)
                                      ,1,nvl(vers.terreni_erariale,0)
                                        ,0
                                      )
                               ,decode(sign(vers.data_pagamento - w_scadenza)
                                      ,1,decode(sign(nvl(vers.terreni_erariale,0) -
                                                     w_imposta_ter_sta_acc
                                                    )
                                               ,-1,0
                                                  ,nvl(vers.terreni_erariale,0) -
                                                   w_imposta_ter_sta_acc
                                               )
                                        ,0
                                      )
                           )
                    ),0
                )                                                               versato_tard_ter_sta_sal
           , nvl(sum(decode(vers.tipo_versamento
                           ,'S',0
                           ,'A',nvl(vers.aree_comune ,0)
                               ,decode(sign(nvl(vers.aree_comune,0) - w_imposta_aree_com_acc)
                                      ,-1,nvl(vers.aree_comune,0)
                                         ,w_imposta_aree_com_acc
                                      )
                           )
                    ),0
                )                                                               w_versato_aree_com_acc
            ,nvl(sum(decode(vers.tipo_versamento
                           ,'A',0
                           ,'S',nvl(vers.aree_comune,0)
                               ,decode(sign(nvl(vers.aree_comune,0) - w_imposta_aree_com_acc)
                                      ,-1,0
                                         ,nvl(vers.aree_comune,0) - w_imposta_aree_com_acc
                                      )
                           )
                    ),0
                )                                                               versato_aree_com_sal
            ,nvl(sum(decode(vers.tipo_versamento
                           ,'S',0
                           ,'A',decode(sign(vers.data_pagamento - w_scadenza_acc)
                                      ,1,nvl(vers.aree_comune,0)
                                        ,0
                                      )
                               ,decode(sign(vers.data_pagamento - w_scadenza_acc)
                                      ,1,decode(sign(nvl(vers.aree_comune,0) -
                                                     w_imposta_aree_com_acc
                                                    )
                                               ,-1,nvl(vers.aree_comune,0)
                                                  ,0
                                               )
                                        ,0
                                      )
                           )
                    ),0
                )                                                               versato_tard_aree_com_acc
            ,nvl(sum(decode(vers.tipo_versamento
                           ,'A',0
                           ,'S',decode(sign(vers.data_pagamento - w_scadenza)
                                      ,1,nvl(vers.aree_comune,0)
                                        ,0
                                      )
                               ,decode(sign(vers.data_pagamento - w_scadenza)
                                      ,1,decode(sign(nvl(vers.aree_comune,0) -
                                                     w_imposta_aree_com_acc
                                                    )
                                               ,-1,0
                                                  ,nvl(vers.aree_comune,0) -
                                                   w_imposta_aree_com_acc
                                               )
                                        ,0
                                      )
                           )
                    ),0
                )                                                               versato_tard_aree_com_sal
           , nvl(sum(decode(vers.tipo_versamento
                           ,'S',0
                           ,'A',nvl(vers.aree_erariale ,0)
                               ,decode(sign(nvl(vers.aree_erariale,0) - w_imposta_aree_sta_acc)
                                      ,-1,nvl(vers.aree_erariale,0)
                                         ,w_imposta_aree_sta_acc
                                      )
                           )
                    ),0
                )                                                               w_versato_aree_sta_acc
            ,nvl(sum(decode(vers.tipo_versamento
                           ,'A',0
                           ,'S',nvl(vers.aree_erariale,0)
                               ,decode(sign(nvl(vers.aree_erariale,0) - w_imposta_aree_sta_acc)
                                      ,-1,0
                                         ,nvl(vers.aree_erariale,0) - w_imposta_aree_sta_acc
                                      )
                           )
                    ),0
                )                                                               versato_aree_sta_sal
            ,nvl(sum(decode(vers.tipo_versamento
                           ,'S',0
                           ,'A',decode(sign(vers.data_pagamento - w_scadenza_acc)
                                      ,1,nvl(vers.aree_erariale,0)
                                        ,0
                                      )
                               ,decode(sign(vers.data_pagamento - w_scadenza_acc)
                                      ,1,decode(sign(nvl(vers.aree_erariale,0) -
                                                     w_imposta_aree_sta_acc
                                                    )
                                               ,-1,nvl(vers.aree_erariale,0)
                                                  ,0
                                               )
                                        ,0
                                      )
                           )
                    ),0
                )                                                               versato_tard_aree_sta_acc
            ,nvl(sum(decode(vers.tipo_versamento
                           ,'A',0
                           ,'S',decode(sign(vers.data_pagamento - w_scadenza)
                                      ,1,nvl(vers.aree_erariale,0)
                                        ,0
                                      )
                               ,decode(sign(vers.data_pagamento - w_scadenza)
                                      ,1,decode(sign(nvl(vers.aree_erariale,0) -
                                                     w_imposta_aree_sta_acc
                                                    )
                                               ,-1,0
                                                  ,nvl(vers.aree_erariale,0) -
                                                   w_imposta_aree_sta_acc
                                               )
                                        ,0
                                      )
                           )
                    ),0
                )                                                               versato_tard_aree_sta_sal
           , nvl(sum(decode(vers.tipo_versamento
                           ,'S',0
                           ,'A',decode(nvl(vers.altri_comune ,0)
                                      ,0,nvl(vers.altri_fabbricati,0)
                                        ,nvl(vers.altri_comune ,0))
                               ,decode(sign(decode(nvl(vers.altri_comune ,0)
                                                  ,0,nvl(vers.altri_fabbricati,0)
                                                    ,nvl(vers.altri_comune ,0)) - w_imposta_altri_com_acc)
                                      ,-1,decode(nvl(vers.altri_comune ,0)
                                                ,0,nvl(vers.altri_fabbricati,0)
                                                  ,nvl(vers.altri_comune ,0))
                                         ,w_imposta_altri_com_acc
                                      )
                           )
                    ),0
                )                                                               w_versato_altri_com_acc
            ,nvl(sum(decode(vers.tipo_versamento
                           ,'A',0
                           ,'S',decode(nvl(vers.altri_comune ,0)
                                      ,0,nvl(vers.altri_fabbricati,0)
                                        ,nvl(vers.altri_comune ,0))
                               ,decode(sign(decode(nvl(vers.altri_comune ,0)
                                                  ,0,nvl(vers.altri_fabbricati,0)
                                                    ,nvl(vers.altri_comune ,0)) - w_imposta_altri_com_acc)
                                      ,-1,0
                                         ,decode(nvl(vers.altri_comune ,0)
                                                  ,0,nvl(vers.altri_fabbricati,0)
                                                    ,nvl(vers.altri_comune ,0)) - w_imposta_altri_com_acc
                                      )
                           )
                    ),0
                )                                                               versato_altri_com_sal
            ,nvl(sum(decode(vers.tipo_versamento
                           ,'S',0
                           ,'A',decode(sign(vers.data_pagamento - w_scadenza_acc)
                                      ,1,decode(nvl(vers.altri_comune ,0)
                                               ,0,nvl(vers.altri_fabbricati,0)
                                                 ,nvl(vers.altri_comune ,0))
                                        ,0
                                      )
                               ,decode(sign(vers.data_pagamento - w_scadenza_acc)
                                      ,1,decode(sign(decode(nvl(vers.altri_comune ,0)
                                                           ,0,nvl(vers.altri_fabbricati,0)
                                                             ,nvl(vers.altri_comune ,0)) -
                                                     w_imposta_altri_com_acc
                                                    )
                                               ,-1,decode(nvl(vers.altri_comune ,0)
                                                         ,0,nvl(vers.altri_fabbricati,0)
                                                           ,nvl(vers.altri_comune ,0))
                                                  ,0
                                               )
                                        ,0
                                      )
                           )
                    ),0
                )                                                               versato_tard_altri_com_acc
            ,nvl(sum(decode(vers.tipo_versamento
                           ,'A',0
                           ,'S',decode(sign(vers.data_pagamento - w_scadenza)
                                      ,1,decode(nvl(vers.altri_comune ,0)
                                               ,0,nvl(vers.altri_fabbricati,0)
                                                 ,nvl(vers.altri_comune ,0))
                                        ,0
                                      )
                               ,decode(sign(vers.data_pagamento - w_scadenza)
                                      ,1,decode(sign(decode(nvl(vers.altri_comune ,0)
                                                           ,0,nvl(vers.altri_fabbricati,0)
                                                             ,nvl(vers.altri_comune ,0)) -
                                                     w_imposta_altri_com_acc
                                                    )
                                               ,-1,0
                                                  ,decode(nvl(vers.altri_comune ,0)
                                                         ,0,nvl(vers.altri_fabbricati,0)
                                                           ,nvl(vers.altri_comune ,0)) -
                                                   w_imposta_altri_com_acc
                                               )
                                        ,0
                                      )
                           )
                    ),0
                )                                                               versato_tard_altri_com_sal
           , nvl(sum(decode(vers.tipo_versamento
                           ,'S',0
                           ,'A',nvl(vers.altri_erariale ,0)
                               ,decode(sign(nvl(vers.altri_erariale,0) - w_imposta_altri_sta_acc)
                                      ,-1,nvl(vers.altri_erariale,0)
                                         ,w_imposta_altri_sta_acc
                                      )
                           )
                    ),0
                )                                                               w_versato_altri_sta_acc
            ,nvl(sum(decode(vers.tipo_versamento
                           ,'A',0
                           ,'S',nvl(vers.altri_erariale,0)
                               ,decode(sign(nvl(vers.altri_erariale,0) - w_imposta_altri_sta_acc)
                                      ,-1,0
                                         ,nvl(vers.altri_erariale,0) - w_imposta_altri_sta_acc
                                      )
                           )
                    ),0
                )                                                               versato_altri_sta_sal
            ,nvl(sum(decode(vers.tipo_versamento
                           ,'S',0
                           ,'A',decode(sign(vers.data_pagamento - w_scadenza_acc)
                                      ,1,nvl(vers.altri_erariale,0)
                                        ,0
                                      )
                               ,decode(sign(vers.data_pagamento - w_scadenza_acc)
                                      ,1,decode(sign(nvl(vers.altri_erariale,0) -
                                                     w_imposta_altri_sta_acc
                                                    )
                                               ,-1,nvl(vers.altri_erariale,0)
                                                  ,0
                                               )
                                        ,0
                                      )
                           )
                    ),0
                )                                                               versato_tard_altri_sta_acc
            ,nvl(sum(decode(vers.tipo_versamento
                           ,'A',0
                           ,'S',decode(sign(vers.data_pagamento - w_scadenza)
                                      ,1,nvl(vers.altri_erariale,0)
                                        ,0
                                      )
                               ,decode(sign(vers.data_pagamento - w_scadenza)
                                      ,1,decode(sign(nvl(vers.altri_erariale,0) -
                                                     w_imposta_altri_sta_acc
                                                    )
                                               ,-1,0
                                                  ,nvl(vers.altri_erariale,0) -
                                                   w_imposta_altri_sta_acc
                                               )
                                        ,0
                                      )
                           )
                    ),0
                )                                                               versato_tard_altri_sta_sal
           , nvl(sum(decode(vers.tipo_versamento
                           ,'S',0
                           ,'A',nvl(vers.fabbricati_d_comune ,0)
                               ,decode(sign(nvl(vers.fabbricati_d_comune,0) - w_imposta_fabb_d_com_acc)
                                      ,-1,nvl(vers.fabbricati_d_comune,0)
                                         ,w_imposta_fabb_d_com_acc
                                      )
                           )
                    ),0
                )                                                               w_versato_fabb_d_com_acc
            ,nvl(sum(decode(vers.tipo_versamento
                           ,'A',0
                           ,'S',nvl(vers.fabbricati_d_comune,0)
                               ,decode(sign(nvl(vers.fabbricati_d_comune,0) - w_imposta_fabb_d_com_acc)
                                      ,-1,0
                                         ,nvl(vers.fabbricati_d_comune,0) - w_imposta_fabb_d_com_acc
                                      )
                           )
                    ),0
                )                                                               versato_fabb_d_com_sal
            ,nvl(sum(decode(vers.tipo_versamento
                           ,'S',0
                           ,'A',decode(sign(vers.data_pagamento - w_scadenza_acc)
                                      ,1,nvl(vers.fabbricati_d_comune,0)
                                        ,0
                                      )
                               ,decode(sign(vers.data_pagamento - w_scadenza_acc)
                                      ,1,decode(sign(nvl(vers.fabbricati_d_comune,0) -
                                                     w_imposta_fabb_d_com_acc
                                                    )
                                               ,-1,nvl(vers.fabbricati_d_comune,0)
                                                  ,0
                                               )
                                        ,0
                                      )
                           )
                    ),0
                )                                                               versato_tard_fabb_d_com_acc
            ,nvl(sum(decode(vers.tipo_versamento
                           ,'A',0
                           ,'S',decode(sign(vers.data_pagamento - w_scadenza)
                                      ,1,nvl(vers.fabbricati_d_comune,0)
                                        ,0
                                      )
                               ,decode(sign(vers.data_pagamento - w_scadenza)
                                      ,1,decode(sign(nvl(vers.fabbricati_d_comune,0) -
                                                     w_imposta_fabb_d_com_acc
                                                    )
                                               ,-1,0
                                                  ,nvl(vers.fabbricati_d_comune,0) -
                                                   w_imposta_fabb_d_com_acc
                                               )
                                        ,0
                                      )
                           )
                    ),0
                )                                                               versato_tard_fabb_d_com_sal
           , nvl(sum(decode(vers.tipo_versamento
                           ,'S',0
                           ,'A',nvl(vers.fabbricati_d_erariale ,0)
                               ,decode(sign(nvl(vers.fabbricati_d_erariale,0) - w_imposta_fabb_d_sta_acc)
                                      ,-1,nvl(vers.fabbricati_d_erariale,0)
                                         ,w_imposta_fabb_d_sta_acc
                                      )
                           )
                    ),0
                )                                                               w_versato_fabb_d_sta_acc
            ,nvl(sum(decode(vers.tipo_versamento
                           ,'A',0
                           ,'S',nvl(vers.fabbricati_d_erariale,0)
                               ,decode(sign(nvl(vers.fabbricati_d_erariale,0) - w_imposta_fabb_d_sta_acc)
                                      ,-1,0
                                         ,nvl(vers.fabbricati_d_erariale,0) - w_imposta_fabb_d_sta_acc
                                      )
                           )
                    ),0
                )                                                               versato_fabb_d_sta_sal
            ,nvl(sum(decode(vers.tipo_versamento
                           ,'S',0
                           ,'A',decode(sign(vers.data_pagamento - w_scadenza_acc)
                                      ,1,nvl(vers.fabbricati_d_erariale,0)
                                        ,0
                                      )
                               ,decode(sign(vers.data_pagamento - w_scadenza_acc)
                                      ,1,decode(sign(nvl(vers.fabbricati_d_erariale,0) -
                                                     w_imposta_fabb_d_sta_acc
                                                    )
                                               ,-1,nvl(vers.fabbricati_d_erariale,0)
                                                  ,0
                                               )
                                        ,0
                                      )
                           )
                    ),0
                )                                                               versato_tard_fabb_d_sta_acc
            ,nvl(sum(decode(vers.tipo_versamento
                           ,'A',0
                           ,'S',decode(sign(vers.data_pagamento - w_scadenza)
                                      ,1,nvl(vers.fabbricati_d_erariale,0)
                                        ,0
                                      )
                               ,decode(sign(vers.data_pagamento - w_scadenza)
                                      ,1,decode(sign(nvl(vers.fabbricati_d_erariale,0) -
                                                     w_imposta_fabb_d_sta_acc
                                                    )
                                               ,-1,0
                                                  ,nvl(vers.fabbricati_d_erariale,0) -
                                                   w_imposta_fabb_d_sta_acc
                                               )
                                        ,0
                                      )
                           )
                    ),0
                )                                                               versato_tard_fabb_d_sta_sal
        into w_versato_acc
           , w_versato_sal
           , w_versato_tard_acc
           , w_versato_tard_sal
           , w_versato_ab_acc
           , w_versato_ab_sal
           , w_versato_tard_ab_acc
           , w_versato_tard_ab_sal
           , w_versato_rur_acc
           , w_versato_rur_sal
           , w_versato_tard_rur_acc
           , w_versato_tard_rur_sal
           , w_versato_ter_com_acc
           , w_versato_ter_com_sal
           , w_versato_tard_ter_com_acc
           , w_versato_tard_ter_com_sal
           , w_versato_ter_sta_acc
           , w_versato_ter_sta_sal
           , w_versato_tard_ter_sta_acc
           , w_versato_tard_ter_sta_sal
           , w_versato_aree_com_acc
           , w_versato_aree_com_sal
           , w_versato_tard_aree_com_acc
           , w_versato_tard_aree_com_sal
           , w_versato_aree_sta_acc
           , w_versato_aree_sta_sal
           , w_versato_tard_aree_sta_acc
           , w_versato_tard_aree_sta_sal
           , w_versato_altri_com_acc
           , w_versato_altri_com_sal
           , w_versato_tard_altri_com_acc
           , w_versato_tard_altri_com_sal
           , w_versato_altri_sta_acc
           , w_versato_altri_sta_sal
           , w_versato_tard_altri_sta_acc
           , w_versato_tard_altri_sta_sal
           , w_versato_fabb_d_com_acc
           , w_versato_fabb_d_com_sal
           , w_versato_tard_fabb_d_com_acc
           , w_versato_tard_fabb_d_com_sal
           , w_versato_fabb_d_sta_acc
           , w_versato_fabb_d_sta_sal
           , w_versato_tard_fabb_d_sta_acc
           , w_versato_tard_fabb_d_sta_sal
        from versamenti vers
       where vers.tipo_tributo          = 'TASI'
         and vers.cod_fiscale           = w_cod_fiscale
         and vers.anno                  = w_anno
         and vers.pratica              is null
         and (    a_tipo_pagam         in ('A','S')
              and a_tipo_pagam          = vers.tipo_versamento
              or  a_tipo_pagam          = 'U'
              and vers.tipo_versamento in ('A','S','U')
             )
      ; */
      select nvl(sum(decode(vers.tipo_versamento
                           ,'S',0
                           ,'A',nvl(vers.importo_versato,0)
                               ,decode(sign(nvl(vers.importo_versato,0) - w_imposta_acc)
                                      ,-1,nvl(vers.importo_versato,0)
                                         ,w_imposta_acc
                                      )
                           )
                    ),0
                )                                                               versato_acc
            ,nvl(sum(decode(vers.tipo_versamento
                           ,'A',0
                           ,'S',nvl(vers.importo_versato,0)
                               ,decode(sign(nvl(vers.importo_versato,0) - w_imposta_acc)
                                      ,-1,0
                                         ,nvl(vers.importo_versato,0) - w_imposta_acc
                                      )
                           )
                    ),0
                )                                                               versato_sal
            ,nvl(sum(decode(vers.tipo_versamento
                           ,'S',0
                           ,'A',decode(sign(vers.data_pagamento - w_scadenza_acc)
                                      ,1,nvl(vers.importo_versato,0)
                                        ,0
                                      )
                               ,decode(sign(vers.data_pagamento - w_scadenza_acc)
                                      ,1,decode(sign(nvl(vers.importo_versato,0) -
                                                     w_imposta_acc
                                                    )
                                               ,-1,nvl(vers.importo_versato,0)
                                                  ,0
                                               )
                                        ,0
                                      )
                           )
                    ),0
                )                                                               versato_tard_acc
            ,nvl(sum(decode(vers.tipo_versamento
                           ,'A',0
                           ,'S',decode(sign(vers.data_pagamento - w_scadenza)
                                      ,1,nvl(vers.importo_versato,0)
                                        ,0
                                      )
                               ,decode(sign(vers.data_pagamento - w_scadenza)
                                      ,1,decode(sign(nvl(vers.importo_versato,0) -
                                                     w_imposta_acc
                                                    )
                                               ,-1,0
                                                  ,nvl(vers.importo_versato,0) -
                                                   w_imposta_acc
                                               )
                                        ,0
                                      )
                           )
                    ),0
                )                                                               versato_tard_sal
           , nvl(sum(decode(vers.tipo_versamento
                           ,'S',0
                           ,'A',nvl(vers.ab_principale ,0)
                               ,decode(sign(nvl(vers.ab_principale,0) - w_imposta_ab_acc)
                                      ,-1,nvl(vers.ab_principale,0)
                                         ,w_imposta_ab_acc
                                      )
                           )
                    ),0
                )                                                               w_versato_ab_acc
            ,nvl(sum(decode(vers.tipo_versamento
                           ,'A',0
                           ,'S',nvl(vers.ab_principale,0)
                               ,decode(sign(nvl(vers.ab_principale,0) - w_imposta_ab_acc)
                                      ,-1,0
                                         ,nvl(vers.ab_principale,0) - w_imposta_ab_acc
                                      )
                           )
                    ),0
                )                                                               versato_ab_sal
            ,nvl(sum(decode(vers.tipo_versamento
                           ,'S',0
                           ,'A',decode(sign(vers.data_pagamento - w_scadenza_acc)
                                      ,1,nvl(vers.ab_principale,0)
                                        ,0
                                      )
                               ,decode(sign(vers.data_pagamento - w_scadenza_acc)
                                      ,1,decode(sign(nvl(vers.ab_principale,0) -
                                                     w_imposta_ab_acc
                                                    )
                                               ,-1,nvl(vers.ab_principale,0)
                                                  ,0
                                               )
                                        ,0
                                      )
                           )
                    ),0
                )                                                               versato_tard_ab_acc
            ,nvl(sum(decode(vers.tipo_versamento
                           ,'A',0
                           ,'S',decode(sign(vers.data_pagamento - w_scadenza)
                                      ,1,nvl(vers.ab_principale,0)
                                        ,0
                                      )
                               ,decode(sign(vers.data_pagamento - w_scadenza)
                                      ,1,decode(sign(nvl(vers.ab_principale,0) -
                                                     w_imposta_ab_acc
                                                    )
                                               ,-1,0
                                                  ,nvl(vers.ab_principale,0) -
                                                   w_imposta_ab_acc
                                               )
                                        ,0
                                      )
                           )
                    ),0
                )                                                               versato_tard_ab_sal
           , nvl(sum(decode(vers.tipo_versamento
                           ,'S',0
                           ,'A',nvl(vers.rurali ,0)
                               ,decode(sign(nvl(vers.rurali,0) - w_imposta_rur_acc)
                                      ,-1,nvl(vers.rurali,0)
                                         ,w_imposta_rur_acc
                                      )
                           )
                    ),0
                )                                                               w_versato_rur_acc
            ,nvl(sum(decode(vers.tipo_versamento
                           ,'A',0
                           ,'S',nvl(vers.rurali,0)
                               ,decode(sign(nvl(vers.rurali,0) - w_imposta_rur_acc)
                                      ,-1,0
                                         ,nvl(vers.rurali,0) - w_imposta_rur_acc
                                      )
                           )
                    ),0
                )                                                               versato_rur_sal
            ,nvl(sum(decode(vers.tipo_versamento
                           ,'S',0
                           ,'A',decode(sign(vers.data_pagamento - w_scadenza_acc)
                                      ,1,nvl(vers.rurali,0)
                                        ,0
                                      )
                               ,decode(sign(vers.data_pagamento - w_scadenza_acc)
                                      ,1,decode(sign(nvl(vers.rurali,0) -
                                                     w_imposta_rur_acc
                                                    )
                                               ,-1,nvl(vers.rurali,0)
                                                  ,0
                                               )
                                        ,0
                                      )
                           )
                    ),0
                )                                                               versato_tard_rur_acc
            ,nvl(sum(decode(vers.tipo_versamento
                           ,'A',0
                           ,'S',decode(sign(vers.data_pagamento - w_scadenza)
                                      ,1,nvl(vers.rurali,0)
                                        ,0
                                      )
                               ,decode(sign(vers.data_pagamento - w_scadenza)
                                      ,1,decode(sign(nvl(vers.rurali,0) -
                                                     w_imposta_rur_acc
                                                    )
                                               ,-1,0
                                                  ,nvl(vers.rurali,0) -
                                                   w_imposta_rur_acc
                                               )
                                        ,0
                                      )
                           )
                    ),0
                )                                                               versato_tard_rur_sal
           , nvl(sum(decode(vers.tipo_versamento
                           ,'S',0
                           ,'A',nvl(vers.terreni_agricoli ,0)
                               ,decode(sign(nvl(vers.terreni_agricoli,0) - w_imposta_ter_acc)
                                      ,-1,nvl(vers.terreni_agricoli,0)
                                         ,w_imposta_ter_acc
                                      )
                           )
                    ),0
                )                                                               w_versato_ter_acc
            ,nvl(sum(decode(vers.tipo_versamento
                           ,'A',0
                           ,'S',nvl(vers.terreni_agricoli,0)
                               ,decode(sign(nvl(vers.terreni_agricoli,0) - w_imposta_ter_acc)
                                      ,-1,0
                                         ,nvl(vers.terreni_agricoli,0) - w_imposta_ter_acc
                                      )
                           )
                    ),0
                )                                                               versato_ter_sal
            ,nvl(sum(decode(vers.tipo_versamento
                           ,'S',0
                           ,'A',decode(sign(vers.data_pagamento - w_scadenza_acc)
                                      ,1,nvl(vers.terreni_agricoli,0)
                                        ,0
                                      )
                               ,decode(sign(vers.data_pagamento - w_scadenza_acc)
                                      ,1,decode(sign(nvl(vers.terreni_agricoli,0) -
                                                     w_imposta_ter_acc
                                                    )
                                               ,-1,nvl(vers.terreni_agricoli,0)
                                                  ,0
                                               )
                                        ,0
                                      )
                           )
                    ),0
                )                                                               versato_tard_ter_acc
            ,nvl(sum(decode(vers.tipo_versamento
                           ,'A',0
                           ,'S',decode(sign(vers.data_pagamento - w_scadenza)
                                      ,1,nvl(vers.terreni_agricoli,0)
                                        ,0
                                      )
                               ,decode(sign(vers.data_pagamento - w_scadenza)
                                      ,1,decode(sign(nvl(vers.terreni_agricoli,0) -
                                                     w_imposta_ter_acc
                                                    )
                                               ,-1,0
                                                  ,nvl(vers.terreni_agricoli,0) -
                                                   w_imposta_ter_acc
                                               )
                                        ,0
                                      )
                           )
                    ),0
                )                                                               versato_tard_ter_sal
           , nvl(sum(decode(vers.tipo_versamento
                           ,'S',0
                           ,'A',nvl(vers.aree_fabbricabili ,0)
                               ,decode(sign(nvl(vers.aree_fabbricabili,0) - w_imposta_aree_acc)
                                      ,-1,nvl(vers.aree_fabbricabili,0)
                                         ,w_imposta_aree_acc
                                      )
                           )
                    ),0
                )                                                               w_versato_aree_acc
            ,nvl(sum(decode(vers.tipo_versamento
                           ,'A',0
                           ,'S',nvl(vers.aree_fabbricabili,0)
                               ,decode(sign(nvl(vers.aree_fabbricabili,0) - w_imposta_aree_acc)
                                      ,-1,0
                                         ,nvl(vers.aree_fabbricabili,0) - w_imposta_aree_acc
                                      )
                           )
                    ),0
                )                                                               versato_aree_sal
            ,nvl(sum(decode(vers.tipo_versamento
                           ,'S',0
                           ,'A',decode(sign(vers.data_pagamento - w_scadenza_acc)
                                      ,1,nvl(vers.aree_fabbricabili,0)
                                        ,0
                                      )
                               ,decode(sign(vers.data_pagamento - w_scadenza_acc)
                                      ,1,decode(sign(nvl(vers.aree_fabbricabili,0) -
                                                     w_imposta_aree_acc
                                                    )
                                               ,-1,nvl(vers.aree_fabbricabili,0)
                                                  ,0
                                               )
                                        ,0
                                      )
                           )
                    ),0
                )                                                               versato_tard_aree_acc
            ,nvl(sum(decode(vers.tipo_versamento
                           ,'A',0
                           ,'S',decode(sign(vers.data_pagamento - w_scadenza)
                                      ,1,nvl(vers.aree_fabbricabili,0)
                                        ,0
                                      )
                               ,decode(sign(vers.data_pagamento - w_scadenza)
                                      ,1,decode(sign(nvl(vers.aree_fabbricabili,0) -
                                                     w_imposta_aree_acc
                                                    )
                                               ,-1,0
                                                  ,nvl(vers.aree_fabbricabili,0) -
                                                   w_imposta_aree_acc
                                               )
                                        ,0
                                      )
                           )
                    ),0
                )                                                               versato_tard_aree_sal
           , nvl(sum(decode(vers.tipo_versamento
                           ,'S',0
                           ,'A',nvl(vers.altri_fabbricati,0)
                               ,decode(sign(nvl(vers.altri_fabbricati,0) - w_imposta_altri_acc)
                                      ,-1,nvl(vers.altri_fabbricati,0)
                                         ,w_imposta_altri_acc
                                      )
                           )
                    ),0
                )                                                               versato_altri_acc
            ,nvl(sum(decode(vers.tipo_versamento
                           ,'A',0
                           ,'S',nvl(vers.altri_fabbricati,0)
                               ,decode(sign(nvl(vers.altri_fabbricati,0) - w_imposta_altri_acc)
                                      ,-1,0
                                         ,nvl(vers.altri_fabbricati,0) - w_imposta_altri_acc
                                      )
                           )
                    ),0
                )                                                               versato_altri_sal
            ,nvl(sum(decode(vers.tipo_versamento
                           ,'S',0
                           ,'A',decode(sign(vers.data_pagamento - w_scadenza_acc)
                                      ,1,nvl(vers.altri_fabbricati,0)
                                        ,0
                                      )
                               ,decode(sign(vers.data_pagamento - w_scadenza_acc)
                                      ,1,nvl(vers.altri_fabbricati,0) -
                                             w_imposta_altri_acc
                                      ,-1,nvl(vers.altri_fabbricati,0)
                                      ,0
                                      )
                           )
                    ),0
                )                                                               versato_tard_altri_acc
            ,nvl(sum(decode(vers.tipo_versamento
                           ,'A',0
                           ,'S',decode(sign(vers.data_pagamento - w_scadenza)
                                      ,1,nvl(vers.altri_fabbricati,0)
                                      )
                               ,decode(sign(vers.data_pagamento - w_scadenza)
                                      ,1,decode(sign(nvl(vers.altri_fabbricati,0) -
                                                     w_imposta_altri_acc
                                                    )
                                               ,-1,0
                                                  ,nvl(vers.altri_fabbricati,0) -
                                                   w_imposta_altri_acc
                                               )
                                        ,0
                                      )
                           )
                    ),0
                )                                                               versato_tard_altri_sal
        into w_versato_acc
           , w_versato_sal
           , w_versato_tard_acc
           , w_versato_tard_sal
           , w_versato_ab_acc
           , w_versato_ab_sal
           , w_versato_tard_ab_acc
           , w_versato_tard_ab_sal
           , w_versato_rur_acc
           , w_versato_rur_sal
           , w_versato_tard_rur_acc
           , w_versato_tard_rur_sal
           , w_versato_ter_acc
           , w_versato_ter_sal
           , w_versato_tard_ter_acc
           , w_versato_tard_ter_sal
           , w_versato_aree_acc
           , w_versato_aree_sal
           , w_versato_tard_aree_acc
           , w_versato_tard_aree_sal
           , w_versato_altri_acc
           , w_versato_altri_sal
           , w_versato_tard_altri_acc
           , w_versato_tard_altri_sal
        from versamenti vers
       where vers.tipo_tributo          = 'TASI'
         and vers.cod_fiscale           = w_cod_fiscale
         and vers.anno                  = w_anno
         and vers.pratica              is null
         and (    a_tipo_pagam         in ('A','S')
              and a_tipo_pagam          = vers.tipo_versamento
              or  a_tipo_pagam          = 'U'
              and vers.tipo_versamento in ('A','S','U')
             )
      ;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         --
         -- Nota: non essendoci group by, la select con funzioni di
         --       gruppo non fallisce mai, quindi l'azzeramento delle
         --       variabili è inutile.
         null;
      /* w_versato_acc                 := 0;
         w_versato_sal                 := 0;
         w_versato_tard_acc            := 0;
         w_versato_tard_sal            := 0;
         w_versato_ab_acc              := 0;
         w_versato_ab_sal              := 0;
         w_versato_tard_ab_acc         := 0;
         w_versato_tard_ab_sal         := 0;
         w_versato_rur_acc             := 0;
         w_versato_rur_sal             := 0;
         w_versato_tard_rur_acc        := 0;
         w_versato_tard_rur_sal        := 0;
         w_versato_ter_com_acc         := 0;
         w_versato_ter_com_sal         := 0;
         w_versato_tard_ter_com_acc    := 0;
         w_versato_tard_ter_com_sal    := 0;
         w_versato_ter_sta_acc         := 0;
         w_versato_ter_sta_sal         := 0;
         w_versato_tard_ter_sta_acc    := 0;
         w_versato_tard_ter_sta_sal    := 0;
         w_versato_aree_com_acc        := 0;
         w_versato_aree_com_sal        := 0;
         w_versato_tard_aree_com_acc   := 0;
         w_versato_tard_aree_com_sal   := 0;
         w_versato_aree_sta_acc        := 0;
         w_versato_aree_sta_sal        := 0;
         w_versato_tard_aree_sta_acc   := 0;
         w_versato_tard_aree_sta_sal   := 0;
         w_versato_altri_com_acc       := 0;
         w_versato_altri_com_sal       := 0;
         w_versato_tard_altri_com_acc  := 0;
         w_versato_tard_altri_com_sal  := 0;
         w_versato_altri_sta_acc       := 0;
         w_versato_altri_sta_sal       := 0;
         w_versato_tard_altri_sta_acc  := 0;
         w_versato_tard_altri_sta_sal  := 0;
         w_versato_fabb_d_com_acc      := 0;
         w_versato_fabb_d_com_sal      := 0;
         w_versato_tard_fabb_d_com_acc := 0;
         w_versato_tard_fabb_d_com_sal := 0;
         w_versato_fabb_d_sta_acc      := 0;
         w_versato_fabb_d_sta_sal      := 0;
         w_versato_tard_fabb_d_sta_acc := 0;
         w_versato_tard_fabb_d_sta_sal := 0; */
   END;

   -- Se il versato in acconto supera il dovuto acconto, la differenza viene riportata a Saldo
   if w_versato_acc > w_imposta_acc then
      w_versato_sal := w_versato_sal + (w_versato_acc - w_imposta_acc);
   end if;

   if w_versato_ab_acc > w_imposta_ab_acc then
      w_versato_ab_sal := w_versato_ab_sal + (w_versato_ab_acc - w_imposta_ab_acc);
   end if;

   if w_versato_rur_acc > w_imposta_rur_acc then
      w_versato_rur_sal := w_versato_rur_sal + (w_versato_rur_acc - w_imposta_rur_acc);
   end if;

   if w_versato_ter_acc > w_imposta_ter_acc then
      w_versato_ter_sal := w_versato_ter_sal + (w_versato_ter_acc - w_imposta_ter_acc);
   end if;

   if w_versato_aree_acc > w_imposta_aree_acc then
      w_versato_aree_sal := w_versato_aree_sal + (w_versato_aree_acc - w_imposta_aree_acc);
   end if;

   if w_versato_altri_acc > w_imposta_altri_acc then
      w_versato_altri_sal := w_versato_altri_sal + (w_versato_altri_acc - w_imposta_altri_acc);
   end if;

/* if w_versato_ter_com_acc > w_imposta_ter_com_acc then
      w_versato_ter_com_sal := w_versato_ter_com_sal + (w_versato_ter_com_acc - w_imposta_ter_com_acc);
   end if;

   if w_versato_ter_sta_acc > w_imposta_ter_sta_acc then
      w_versato_ter_sta_sal := w_versato_ter_sta_sal + (w_versato_ter_sta_acc - w_imposta_ter_sta_acc);
   end if;

   if w_versato_aree_com_acc > w_imposta_aree_com_acc then
      w_versato_aree_com_sal := w_versato_aree_com_sal + (w_versato_aree_com_acc - w_imposta_aree_com_acc);
   end if;

   if w_versato_aree_sta_acc > w_imposta_aree_sta_acc then
      w_versato_aree_sta_sal := w_versato_aree_sta_sal + (w_versato_aree_sta_acc - w_imposta_aree_sta_acc);
   end if;

   if w_versato_altri_com_acc > w_imposta_altri_com_acc then
      w_versato_altri_com_sal := w_versato_altri_com_sal + (w_versato_altri_com_acc - w_imposta_altri_com_acc);
   end if;

   if w_versato_altri_sta_acc > w_imposta_altri_sta_acc then
      w_versato_altri_sta_sal := w_versato_altri_sta_sal + (w_versato_altri_sta_acc - w_imposta_altri_sta_acc);
   end if;

   if w_versato_fabb_d_com_acc > w_imposta_fabb_d_com_acc then
      w_versato_fabb_d_com_sal := w_versato_fabb_d_com_sal + (w_versato_fabb_d_com_acc - w_imposta_fabb_d_com_acc);
   end if;

   if w_versato_fabb_d_sta_acc > w_imposta_fabb_d_sta_acc then
      w_versato_fabb_d_sta_sal := w_versato_fabb_d_sta_sal + (w_versato_fabb_d_sta_acc - w_imposta_fabb_d_sta_acc);
   end if; */

   if a_tipo_pagam = 'A' then
      w_versato_sal                 := 0;
      w_versato_tard_sal            := 0;
      w_versato_ab_sal              := 0;
      w_versato_tard_ab_sal         := 0;
      w_versato_rur_sal             := 0;
      w_versato_tard_rur_sal        := 0;
      w_versato_ter_sal             := 0;
      w_versato_tard_ter_sal        := 0;
      w_versato_aree_sal            := 0;
      w_versato_tard_aree_sal       := 0;
      w_versato_altri_sal           := 0;
      w_versato_tard_altri_sal      := 0;
   /* w_versato_ter_com_sal         := 0;
      w_versato_tard_ter_com_sal    := 0;
      w_versato_ter_sta_sal         := 0;
      w_versato_tard_ter_sta_sal    := 0;
      w_versato_aree_com_sal        := 0;
      w_versato_tard_aree_com_sal   := 0;
      w_versato_aree_sta_sal        := 0;
      w_versato_tard_aree_sta_sal   := 0;
      w_versato_altri_com_sal       := 0;
      w_versato_tard_altri_com_sal  := 0;
      w_versato_altri_sta_sal       := 0;
      w_versato_tard_altri_sta_sal  := 0;
      w_versato_fabb_d_com_sal      := 0;
      w_versato_tard_fabb_d_com_sal := 0;
      w_versato_fabb_d_sta_sal      := 0;
      w_versato_tard_fabb_d_sta_sal := 0; */
   end if;
   if a_tipo_pagam = 'S' then
      w_versato_acc                 := 0;
      w_versato_tard_acc            := 0;
      w_versato_ab_acc              := 0;
      w_versato_tard_ab_acc         := 0;
      w_versato_rur_acc             := 0;
      w_versato_tard_rur_acc        := 0;
      w_versato_ter_acc             := 0;
      w_versato_tard_ter_acc        := 0;
      w_versato_aree_acc            := 0;
      w_versato_tard_aree_acc       := 0;
      w_versato_altri_acc           := 0;
      w_versato_tard_altri_acc      := 0;
   /* w_versato_ter_com_acc         := 0;
      w_versato_tard_ter_com_acc    := 0;
      w_versato_ter_sta_acc         := 0;
      w_versato_tard_ter_sta_acc    := 0;
      w_versato_aree_com_acc        := 0;
      w_versato_tard_aree_com_acc   := 0;
      w_versato_aree_sta_acc        := 0;
      w_versato_tard_aree_sta_acc   := 0;
      w_versato_altri_com_acc       := 0;
      w_versato_tard_altri_com_acc  := 0;
      w_versato_altri_sta_acc       := 0;
      w_versato_tard_altri_sta_acc  := 0;
      w_versato_fabb_d_com_acc      := 0;
      w_versato_tard_fabb_d_com_acc := 0;
      w_versato_fabb_d_sta_acc      := 0;
      w_versato_tard_fabb_d_sta_acc := 0; */
   end if;
   w_versato         := w_versato_acc      + w_versato_sal;
   w_versato_tardivo := w_versato_tard_acc + w_versato_tard_sal;
   --dbms_output.put_line('Versato - Acconto '||to_char(w_versato_acc)||' Saldo '||
   --to_char(w_versato_sal));
   --dbms_output.put_line('Tardivo - Acconto '||to_char(w_versato_tard_acc)||' Saldo '||
   --to_char(w_versato_tard_sal));

   if a_tipo_pagam in ('A','U') then
      if w_versato_acc > w_imposta_acc then
         w_imposta_acc := 0;
      else
         w_imposta_acc := w_imposta_acc - w_versato_acc;
      end if;
   end if;
   if a_tipo_pagam in ('S','U') then
      if w_versato_sal > w_imposta_sal then
         w_imposta_sal := 0;
      else
         w_imposta_sal := w_imposta_sal - w_versato_sal;
      end if;
   end if;
   w_imposta := w_imposta_acc + w_imposta_sal;
   --dbms_output.put_line('Non Versato - Acconto '||to_char(w_imposta_acc)||' Saldo '||
   --to_char(w_imposta_sal));

   if a_tipo_pagam in ('A','U') then
      if w_versato_ab_acc > w_imposta_ab_acc then
         w_imposta_ab_acc := 0;
      else
         w_imposta_ab_acc := w_imposta_ab_acc - w_versato_ab_acc;
      end if;
   end if;
   if a_tipo_pagam in ('S','U') then
      if w_versato_ab_sal > w_imposta_ab_sal then
         w_imposta_ab_sal := 0;
      else
         w_imposta_ab_sal := w_imposta_ab_sal - w_versato_ab_sal;
      end if;
   end if;
   w_imposta_ab := w_imposta_ab_acc + w_imposta_ab_sal;

   if a_tipo_pagam in ('A','U') then
      if w_versato_rur_acc > w_imposta_rur_acc then
         w_imposta_rur_acc := 0;
      else
         w_imposta_rur_acc := w_imposta_rur_acc - w_versato_rur_acc;
      end if;
   end if;
   if a_tipo_pagam in ('S','U') then
      if w_versato_rur_sal > w_imposta_rur_sal then
         w_imposta_rur_sal := 0;
      else
         w_imposta_rur_sal := w_imposta_rur_sal - w_versato_rur_sal;
      end if;
   end if;
   w_imposta_rur := w_imposta_rur_acc + w_imposta_rur_sal;

   if a_tipo_pagam in ('A','U') then
      if w_versato_ter_acc > w_imposta_ter_acc then
         w_imposta_ter_acc := 0;
      else
         w_imposta_ter_acc := w_imposta_ter_acc - w_versato_ter_acc;
      end if;
   end if;
   if a_tipo_pagam in ('S','U') then
      if w_versato_ter_sal > w_imposta_ter_sal then
         w_imposta_ter_sal := 0;
      else
         w_imposta_ter_sal := w_imposta_ter_sal - w_versato_ter_sal;
      end if;
   end if;
   w_imposta_ter := w_imposta_ter_acc + w_imposta_ter_sal;

   if a_tipo_pagam in ('A','U') then
      if w_versato_aree_acc > w_imposta_aree_acc then
         w_imposta_aree_acc := 0;
      else
         w_imposta_aree_acc := w_imposta_aree_acc - w_versato_aree_acc;
      end if;
   end if;
   if a_tipo_pagam in ('S','U') then
      if w_versato_aree_sal > w_imposta_aree_sal then
         w_imposta_aree_sal := 0;
      else
         w_imposta_aree_sal := w_imposta_aree_sal - w_versato_aree_sal;
      end if;
   end if;
   w_imposta_aree := w_imposta_aree_acc + w_imposta_aree_sal;

   if a_tipo_pagam in ('A','U') then
      if w_versato_altri_acc > w_imposta_altri_acc then
         w_imposta_altri_acc := 0;
      else
         w_imposta_altri_acc := w_imposta_altri_acc - w_versato_altri_acc;
      end if;
   end if;
   if a_tipo_pagam in ('S','U') then
      if w_versato_altri_sal > w_imposta_altri_sal then
         w_imposta_altri_sal := 0;
      else
         w_imposta_altri_sal := w_imposta_altri_sal - w_versato_altri_sal;
      end if;
   end if;
   w_imposta_altri := w_imposta_altri_acc + w_imposta_altri_sal;

/*   if a_tipo_pagam in ('A','U') then
      if w_versato_ter_com_acc > w_imposta_ter_com_acc then
         w_imposta_ter_com_acc := 0;
      else
         w_imposta_ter_com_acc := w_imposta_ter_com_acc - w_versato_ter_com_acc;
      end if;
   end if;
   if a_tipo_pagam in ('S','U') then
      if w_versato_ter_com_sal > w_imposta_ter_com_sal then
         w_imposta_ter_com_sal := 0;
      else
         w_imposta_ter_com_sal := w_imposta_ter_com_sal - w_versato_ter_com_sal;
      end if;
   end if;
   w_imposta_ter_com := w_imposta_ter_com_acc + w_imposta_ter_com_sal;

   if a_tipo_pagam in ('A','U') then
      if w_versato_ter_sta_acc > w_imposta_ter_sta_acc then
         w_imposta_ter_sta_acc := 0;
      else
         w_imposta_ter_sta_acc := w_imposta_ter_sta_acc - w_versato_ter_sta_acc;
      end if;
   end if;
   if a_tipo_pagam in ('S','U') then
      if w_versato_ter_sta_sal > w_imposta_ter_sta_sal then
         w_imposta_ter_sta_sal := 0;
      else
         w_imposta_ter_sta_sal := w_imposta_ter_sta_sal - w_versato_ter_sta_sal;
      end if;
   end if;
   w_imposta_ter_sta := w_imposta_ter_sta_acc + w_imposta_ter_sta_sal;

   if a_tipo_pagam in ('A','U') then
      if w_versato_aree_com_acc > w_imposta_aree_com_acc then
         w_imposta_aree_com_acc := 0;
      else
         w_imposta_aree_com_acc := w_imposta_aree_com_acc - w_versato_aree_com_acc;
      end if;
   end if;
   if a_tipo_pagam in ('S','U') then
      if w_versato_aree_com_sal > w_imposta_aree_com_sal then
         w_imposta_aree_com_sal := 0;
      else
         w_imposta_aree_com_sal := w_imposta_aree_com_sal - w_versato_aree_com_sal;
      end if;
   end if;
   w_imposta_aree_com := w_imposta_aree_com_acc + w_imposta_aree_com_sal;

   if a_tipo_pagam in ('A','U') then
      if w_versato_aree_sta_acc > w_imposta_aree_sta_acc then
         w_imposta_aree_sta_acc := 0;
      else
         w_imposta_aree_sta_acc := w_imposta_aree_sta_acc - w_versato_aree_sta_acc;
      end if;
   end if;
   if a_tipo_pagam in ('S','U') then
      if w_versato_aree_sta_sal > w_imposta_aree_sta_sal then
         w_imposta_aree_sta_sal := 0;
      else
         w_imposta_aree_sta_sal := w_imposta_aree_sta_sal - w_versato_aree_sta_sal;
      end if;
   end if;
   w_imposta_aree_sta := w_imposta_aree_sta_acc + w_imposta_aree_sta_sal;

   if a_tipo_pagam in ('A','U') then
      if w_versato_altri_com_acc > w_imposta_altri_com_acc then
         w_imposta_altri_com_acc := 0;
      else
         w_imposta_altri_com_acc := w_imposta_altri_com_acc - w_versato_altri_com_acc;
      end if;
   end if;
   if a_tipo_pagam in ('S','U') then
      if w_versato_altri_com_sal > w_imposta_altri_com_sal then
         w_imposta_altri_com_sal := 0;
      else
         w_imposta_altri_com_sal := w_imposta_altri_com_sal - w_versato_altri_com_sal;
      end if;
   end if;
   w_imposta_altri_com := w_imposta_altri_com_acc + w_imposta_altri_com_sal;

   if a_tipo_pagam in ('A','U') then
      if w_versato_altri_sta_acc > w_imposta_altri_sta_acc then
         w_imposta_altri_sta_acc := 0;
      else
         w_imposta_altri_sta_acc := w_imposta_altri_sta_acc - w_versato_altri_sta_acc;
      end if;
   end if;
   if a_tipo_pagam in ('S','U') then
      if w_versato_altri_sta_sal > w_imposta_altri_sta_sal then
         w_imposta_altri_sta_sal := 0;
      else
         w_imposta_altri_sta_sal := w_imposta_altri_sta_sal - w_versato_altri_sta_sal;
      end if;
   end if;
   w_imposta_altri_sta := w_imposta_altri_sta_acc + w_imposta_altri_sta_sal;

   if a_tipo_pagam in ('A','U') then
      if w_versato_fabb_d_com_acc > w_imposta_fabb_d_com_acc then
         w_imposta_fabb_d_com_acc := 0;
      else
         w_imposta_fabb_d_com_acc := w_imposta_fabb_d_com_acc - w_versato_fabb_d_com_acc;
      end if;
   end if;
   if a_tipo_pagam in ('S','U') then
      if w_versato_fabb_d_com_sal > w_imposta_fabb_d_com_sal then
         w_imposta_fabb_d_com_sal := 0;
      else
         w_imposta_fabb_d_com_sal := w_imposta_fabb_d_com_sal - w_versato_fabb_d_com_sal;
      end if;
   end if;
   w_imposta_fabb_d_com := w_imposta_fabb_d_com_acc + w_imposta_fabb_d_com_sal;

   if a_tipo_pagam in ('A','U') then
      if w_versato_fabb_d_sta_acc > w_imposta_fabb_d_sta_acc then
         w_imposta_fabb_d_sta_acc := 0;
      else
         w_imposta_fabb_d_sta_acc := w_imposta_fabb_d_sta_acc - w_versato_fabb_d_sta_acc;
      end if;
   end if;
   if a_tipo_pagam in ('S','U') then
      if w_versato_fabb_d_sta_sal > w_imposta_fabb_d_sta_sal then
         w_imposta_fabb_d_sta_sal := 0;
      else
         w_imposta_fabb_d_sta_sal := w_imposta_fabb_d_sta_sal - w_versato_fabb_d_sta_sal;
      end if;
   end if;
   w_imposta_fabb_d_sta := w_imposta_fabb_d_sta_acc + w_imposta_fabb_d_sta_sal; */

   if w_imposta_acc      = 0 and w_imposta_sal      = 0 and
      w_versato_tard_acc = 0 and w_versato_tard_sal = 0 and
      a_flag_infrazione is null then
      w_errore := 'Imp nulla cf '||w_cod_fiscale;
      RAISE ERRORE;
   end if;
   BEGIN
      select a_data_pagam - w_scadenza
            ,a_data_pagam - w_scadenza_acc
            ,a_data_pagam - w_scadenza_present
        into w_diff_giorni
            ,w_diff_giorni_acc
            ,w_diff_giorni_pres
        from dual
      ;
   END;
   --dbms_output.put_line('Diff gg - Acc. '||to_char(w_diff_giorni_acc)||' Sal '||
   --to_char(w_diff_giorni)||' Pres '||to_char(w_diff_giorni_pres));

   if a_flag_infrazione in ('O','I') then
      if a_flag_infrazione = 'O' then
         w_cod_sanzione := 132;
      else
         w_cod_sanzione := 134;
      end if;
      if w_diff_giorni_pres > 90 then
         if w_anno > 1999 then
            -- D.L. 185/2008 (art.16 comma 5)
            if w_scadenza_present > to_date('31/01/2011','dd/mm/yyyy') then
               w_rid := 8;
            elsif a_data_pagam >= to_date('29/11/2008','dd/mm/yyyy') then
               w_rid := 10;
            else
               w_rid := 5;
            end if;
         else
            w_rid := 6;
         end if;
      else
         if w_scadenza_present > to_date('31/01/2011','dd/mm/yyyy') then
            w_rid := 10;
         elsif a_data_pagam >= to_date('29/11/2008','dd/mm/yyyy') then
            w_rid := 12;
         else
            w_rid := 8;
         end if;
      end if;

      if F_IMP_SANZ( w_cod_sanzione, w_imposta
                   , w_anno, w_rid
                   , w_imposta_ab, w_imposta_rur
                   --, w_imposta_ter_com, w_imposta_ter_sta
                   --, w_imposta_aree_com, w_imposta_aree_sta
                   --, w_imposta_altri_com, w_imposta_altri_sta
                   --, w_imposta_fabb_d_com, w_imposta_fabb_d_sta
                   , w_imposta_ter, 0
                   , w_imposta_aree, 0
                   , w_imposta_altri, 0
                   , 0, 0
                   , w_percentuale, w_riduzione
                   , w_riduzione_2, w_sanzione
                   , w_sanzione_ab, w_sanzione_rur
                   , w_sanzione_ter_com, w_sanzione_ter_sta
                   , w_sanzione_aree_com, w_sanzione_aree_sta
                   , w_sanzione_altri_com, w_sanzione_altri_sta
                   , w_sanzione_fabb_d_com, w_sanzione_fabb_d_sta
                   ) is not null then
         w_errore := 'Errore in Determinazione Sanzione ICI per Codice '||
                     to_char(w_cod_sanzione);
         RAISE ERRORE;
      end if;
--dbms_output.put_line('1 - a_pratica '||to_char(a_pratica)||' w_cod_sanzione '||
--to_char(w_cod_sanzione)||' w_percentuale '||to_char(w_percentuale)||
--'importo '||to_char(w_sanzione)||
--'w_riduzione '||to_char(w_riduzione));
      insert into sanzioni_pratica
            ( pratica, cod_sanzione, tipo_tributo
            , percentuale, importo, riduzione, riduzione_2
            , ab_principale ,rurali
            , terreni_comune, terreni_erariale
            , aree_comune, aree_erariale
            , altri_comune, altri_erariale
            , fabbricati_d_comune, fabbricati_d_erariale
            , utente, data_variazione, note
            )
      values( a_pratica, w_cod_sanzione, 'TASI'
            , w_percentuale, w_sanzione, w_riduzione, w_riduzione_2
            , w_sanzione_ab, w_sanzione_rur
            , w_sanzione_ter_com, w_sanzione_ter_sta
            , w_sanzione_aree_com, w_sanzione_aree_sta
            , w_sanzione_altri_com, w_sanzione_altri_sta
            , w_sanzione_fabb_d_com, w_sanzione_fabb_d_sta
            , a_utente, trunc(sysdate), null
            )
            ;
   end if;

   if a_tipo_pagam in ('A','U') and w_diff_giorni_acc > 0 then
      w_cod_sanzione := 101;
      insert into sanzioni_pratica
            ( pratica, cod_sanzione, tipo_tributo
            , percentuale, importo,riduzione, riduzione_2
            , ab_principale ,rurali
            , terreni_comune, terreni_erariale
            , aree_comune, aree_erariale
            , altri_comune, altri_erariale
            , fabbricati_d_comune, fabbricati_d_erariale
            , utente, data_variazione, note
            )
      values( a_pratica, w_cod_sanzione, 'TASI'
            , null, w_imposta_acc, null, null
            , w_imposta_ab_acc, w_imposta_rur_acc
            --, w_imposta_ter_com_acc, w_imposta_ter_sta_acc
            --, w_imposta_aree_com_acc, w_imposta_aree_sta_acc
            --, w_imposta_altri_com_acc, w_imposta_altri_sta_acc
            --, w_imposta_fabb_d_com_acc, w_imposta_fabb_d_sta_acc
            , w_imposta_ter_acc, 0
            , w_imposta_aree_acc, 0
            , w_imposta_altri_acc, 0
            , 0, 0
            ,a_utente, trunc(sysdate), null
            )
            ;
   end if;

   if a_tipo_pagam in ('S','U') and w_diff_giorni > 0 then
--dbms_output.put_line('2 - a_pratica '||to_char(a_pratica)||' w_cod_sanzione '||
--to_char(w_cod_sanzione)||' w_percentuale '||to_char(w_percentuale)||
--'importo '||to_char(w_sanzione)||
--'w_riduzione '||to_char(w_riduzione));
      w_cod_sanzione := 121;
      insert into sanzioni_pratica
            ( pratica, cod_sanzione, tipo_tributo
            , percentuale,importo, riduzione, riduzione_2
            , ab_principale ,rurali
            , terreni_comune, terreni_erariale
            , aree_comune, aree_erariale
            , altri_comune, altri_erariale
            , fabbricati_d_comune, fabbricati_d_erariale
            , utente, data_variazione, note
            )
      values( a_pratica, w_cod_sanzione, 'TASI'
            , null, w_imposta_sal, null, null
            , w_imposta_ab_sal, w_imposta_rur_sal
            --, w_imposta_ter_com_sal, w_imposta_ter_sta_sal
            --, w_imposta_aree_com_sal, w_imposta_aree_sta_sal
            --, w_imposta_altri_com_sal, w_imposta_altri_sta_sal
            --, w_imposta_fabb_d_com_sal, w_imposta_fabb_d_sta_sal
            , w_imposta_ter_sal, 0
            , w_imposta_aree_sal, 0
            , w_imposta_altri_sal, 0
            , 0, 0
            , a_utente, trunc(sysdate), null
            )
      ;
   end if;

   --dbms_output.put_line('w_diff_giorni_acc'||to_char(w_diff_giorni_acc));
   --
   -- Modifica del 26/01/2015: aggiunta gestione ravvedimento medio
   -- per data versamento >= 01/01/2015 e gg di ritardo compresi tra 30 e 90
   --
   if w_diff_giorni_acc > 0 then
      -- (VD - 05/02/2020): Ravvedimento operoso lungo
      if w_diff_giorni_acc > 730 and
         a_data_pagam >= to_date('01012020','ddmmyyyy') then
         w_cod_sanzione := 166;
         w_rid := 6;
      elsif
         w_diff_giorni_acc > 365 and
         a_data_pagam >= to_date('01012020','ddmmyyyy') then
         w_cod_sanzione := 165;
         w_rid := 7;
      elsif
         (w_diff_giorni_acc > 90 and
          a_data_pagam >= to_date('01012015','ddmmyyyy')) or
         (w_diff_giorni_acc > 30 and
          a_data_pagam < to_date('01012015','ddmmyyyy')) then
         if  sign(2 - w_anno_scadenza + w_anno) < 1 then
            w_cod_sanzione := 155;
            w_rid          := 8;
         else
            w_cod_sanzione := 152;
            w_rid          := 8;
         end if;
      elsif w_diff_giorni_acc > 30 then
         if  sign(2 - w_anno_scadenza + w_anno) < 1 then
            w_cod_sanzione := 155;
            w_rid          := 9;
         else
            w_cod_sanzione := 152;
            w_rid          := 9;
         end if;
      else
         if w_diff_giorni_acc <= 15 then
            w_cod_sanzione    := 157;
            w_rid             := 10;
         else
            w_cod_sanzione    := 158;
            w_rid             := 10;
         end if;
      end if;
      --
      -- (VD - 18/01/2016): Se la pratica e' del 2016 e il versamento e'
      --                    stato effettuato entro 90 gg dalla scadenza,
      --                    la sanzione viene dimezzata (la riduzione
      --                    viene raddoppiata)
      if w_data_pratica >= to_date('01/01/2016','dd/mm/yyyy') and
         w_diff_giorni_acc <= 90 then
         w_rid := w_rid * 2;
      end if;

     --dbms_output.put_line('ACCONTO');
     --dbms_output.put_line('w_cod_sanzione'||to_char(w_cod_sanzione));
     --dbms_output.put_line('w_rid'||to_char(w_rid));
     --dbms_output.put_line('w_versato_tard_acc'||to_char(w_versato_tard_acc));
     --dbms_output.put_line('w_rid'||to_char(w_rid));
     --dbms_output.put_line('w_percentuale'||to_char(w_percentuale));
     --dbms_output.put_line('w_riduzione'||to_char(w_riduzione));
     --dbms_output.put_line('w_sanzione'||to_char(w_sanzione));
     --dbms_output.put_line('w_imposta_acc'||to_char(w_imposta_acc));
      if a_tipo_pagam in ('A','U') and (w_versato_tard_acc > 0 or w_imposta_acc > 0) then
         if w_versato_tard_acc > 0 and w_imposta_acc = 0 then
            if w_cod_sanzione = 157 then
               -- Gestione della sanzione con percentuale che dipende dai giorni di interesse
               if F_IMP_SANZ_GG( w_cod_sanzione, w_versato_tard_acc
                               , w_rid, w_diff_giorni_acc
                               , w_anno
                               , w_versato_tard_ab_acc, w_versato_tard_rur_acc
                               --, w_versato_tard_ter_com_acc, w_versato_tard_ter_sta_acc
                               --, w_versato_tard_aree_com_acc, w_versato_tard_aree_sta_acc
                               --, w_versato_tard_altri_com_acc, w_versato_tard_altri_sta_acc
                               --, w_versato_tard_fabb_d_com_acc, w_versato_tard_fabb_d_sta_acc
                               , w_versato_tard_ter_acc, 0
                               , w_versato_tard_aree_acc, 0
                               , w_versato_tard_altri_acc, 0
                               , 0, 0
                               , w_percentuale, w_riduzione
                               , w_riduzione_2, w_sanzione
                               , w_sanzione_ab, w_sanzione_rur
                               , w_sanzione_ter_com, w_sanzione_ter_sta
                               , w_sanzione_aree_com, w_sanzione_aree_sta
                               , w_sanzione_altri_com, w_sanzione_altri_sta
                               , w_sanzione_fabb_d_com, w_sanzione_fabb_d_sta
                               ) is not null then
                  w_errore := 'Errore in Determinazione Sanzione ICI per Codice '||
                              to_char(w_cod_sanzione);
                  RAISE ERRORE;
               end if;
            else
               if F_IMP_SANZ( w_cod_sanzione, w_versato_tard_acc
                            , w_rid
                            , w_anno
                            , w_versato_tard_ab_acc, w_versato_tard_rur_acc
                            --, w_versato_tard_ter_com_acc, w_versato_tard_ter_sta_acc
                            --, w_versato_tard_aree_com_acc, w_versato_tard_aree_sta_acc
                            --, w_versato_tard_altri_com_acc, w_versato_tard_altri_sta_acc
                            --, w_versato_tard_fabb_d_com_acc, w_versato_tard_fabb_d_sta_acc
                            , w_versato_tard_ter_acc, 0
                            , w_versato_tard_aree_acc, 0
                            , w_versato_tard_altri_acc, 0
                            , 0, 0
                            , w_percentuale, w_riduzione
                            , w_riduzione_2, w_sanzione
                            , w_sanzione_ab, w_sanzione_rur
                            , w_sanzione_ter_com, w_sanzione_ter_sta
                            , w_sanzione_aree_com, w_sanzione_aree_sta
                            , w_sanzione_altri_com, w_sanzione_altri_sta
                            , w_sanzione_fabb_d_com, w_sanzione_fabb_d_sta
                            ) is not null then
                  w_errore := 'Errore in Determinazione Sanzione ICI per Codice '||
                              to_char(w_cod_sanzione);
                  RAISE ERRORE;
               end if;
            end if;
         else
            if w_cod_sanzione = 157 then
               -- Gestione della sanzione con percentuale che dipende dai giorni di interesse
               if F_IMP_SANZ_GG( w_cod_sanzione, w_imposta_acc
                               , w_rid, w_diff_giorni_acc
                               , w_anno
                               , w_imposta_ab_acc, w_imposta_rur_acc
                               --, w_imposta_ter_com_acc, w_imposta_ter_sta_acc
                               --, w_imposta_aree_com_acc, w_imposta_aree_sta_acc
                               --, w_imposta_altri_com_acc, w_imposta_altri_sta_acc
                               --, w_imposta_fabb_d_com_acc, w_imposta_fabb_d_sta_acc
                               , w_imposta_ter_acc, 0
                               , w_imposta_aree_acc, 0
                               , w_imposta_altri_acc, 0
                               , 0, 0
                               , w_percentuale, w_riduzione
                               , w_riduzione_2, w_sanzione
                               , w_sanzione_ab, w_sanzione_rur
                               , w_sanzione_ter_com, w_sanzione_ter_sta
                               , w_sanzione_aree_com, w_sanzione_aree_sta
                               , w_sanzione_altri_com, w_sanzione_altri_sta
                               , w_sanzione_fabb_d_com, w_sanzione_fabb_d_sta
                               ) is not null then
                  w_errore := 'Errore in Determinazione Sanzione ICI per Codice '||
                              to_char(w_cod_sanzione);
                  RAISE ERRORE;
               end if;
            else
               if F_IMP_SANZ( w_cod_sanzione, w_imposta_acc
                            , w_rid, w_anno
                            , w_imposta_ab_acc, w_imposta_rur_acc
                            --, w_imposta_ter_com_acc, w_imposta_ter_sta_acc
                            --, w_imposta_aree_com_acc, w_imposta_aree_sta_acc
                            --, w_imposta_altri_com_acc, w_imposta_altri_sta_acc
                            --, w_imposta_fabb_d_com_acc, w_imposta_fabb_d_sta_acc
                            , w_imposta_ter_acc, 0
                            , w_imposta_aree_acc, 0
                            , w_imposta_altri_acc, 0
                            , 0, 0
                            , w_percentuale, w_riduzione
                            , w_riduzione_2, w_sanzione
                            , w_sanzione_ab, w_sanzione_rur
                            , w_sanzione_ter_com, w_sanzione_ter_sta
                            , w_sanzione_aree_com, w_sanzione_aree_sta
                            , w_sanzione_altri_com, w_sanzione_altri_sta
                            , w_sanzione_fabb_d_com, w_sanzione_fabb_d_sta
                            ) is not null then
                  w_errore := 'Errore in Determinazione Sanzione ICI per Codice '||
                              to_char(w_cod_sanzione);
                  RAISE ERRORE;
               end if;
            end if;
         end if;

         insert into sanzioni_pratica
               (pratica, cod_sanzione, tipo_tributo
               ,percentuale, importo, riduzione, riduzione_2
               , ab_principale ,rurali
               , terreni_comune, terreni_erariale
               , aree_comune, aree_erariale
               , altri_comune, altri_erariale
               , fabbricati_d_comune, fabbricati_d_erariale
               , utente, data_variazione
               , note
               )
         values( a_pratica, w_cod_sanzione, 'TASI'
               , w_percentuale, w_sanzione, w_riduzione, w_riduzione_2
               , w_sanzione_ab, w_sanzione_rur
               , w_sanzione_ter_com, w_sanzione_ter_sta
               , w_sanzione_aree_com, w_sanzione_aree_sta
               , w_sanzione_altri_com, w_sanzione_altri_sta
               , w_sanzione_fabb_d_com, w_sanzione_fabb_d_sta
               , a_utente, trunc(sysdate)
               ,'Ulteriore riduzione di 1/'||to_char(w_rid)||' per ravvedimento operoso'
               )
         ;
         w_cod_sanzione := 198;

         if w_versato_tard_acc > 0 and w_imposta_acc = 0 then
            w_note_sanzione := '';
            w_errore_interessi := F_CALCOLO_INT( w_versato_tard_acc, w_scadenza_acc + 1
                                               , a_data_pagam, w_giorni_anno
                                               , w_anno
                                               , w_versato_tard_ab_acc, w_versato_tard_rur_acc
                                               --, w_versato_tard_ter_com_acc, w_versato_tard_ter_sta_acc
                                               --, w_versato_tard_aree_com_acc, w_versato_tard_aree_sta_acc
                                               --, w_versato_tard_altri_com_acc, w_versato_tard_altri_sta_acc
                                               --, w_versato_tard_fabb_d_com_acc, w_versato_tard_fabb_d_sta_acc
                                               , w_versato_tard_ter_acc, 0
                                               , w_versato_tard_aree_acc, 0
                                               , w_versato_tard_altri_acc, 0
                                               , 0, 0
                                               , w_sanzione
                                               , w_sanzione_ab, w_sanzione_rur
                                               , w_sanzione_ter_com, w_sanzione_ter_sta
                                               , w_sanzione_aree_com, w_sanzione_aree_sta
                                               , w_sanzione_altri_com, w_sanzione_altri_sta
                                               , w_sanzione_fabb_d_com, w_sanzione_fabb_d_sta
                                               , w_note_sanzione
                                  );
            if w_errore_interessi <> 'OK' then
               w_errore := 'Errore in Determinazione Interessi in Acconto su Pagamenti'
                           ||w_errore_interessi;
               RAISE ERRORE;
            end if;
         else
            w_note_sanzione := '';
            w_errore_interessi := F_CALCOLO_INT(w_imposta_acc, w_scadenza_acc + 1
                                               , a_data_pagam, w_giorni_anno
                                               , w_anno
                                               , w_imposta_ab_acc, w_imposta_rur_acc
                                               --, w_imposta_ter_com_acc, w_imposta_ter_sta_acc
                                               --, w_imposta_aree_com_acc, w_imposta_aree_sta_acc
                                               --, w_imposta_altri_com_acc, w_imposta_altri_sta_acc
                                               --, w_imposta_fabb_d_com_acc, w_imposta_fabb_d_sta_acc
                                               , w_imposta_ter_acc, 0
                                               , w_imposta_aree_acc, 0
                                               , w_imposta_altri_acc, 0
                                               , 0, 0
                                               , w_sanzione
                                               , w_sanzione_ab, w_sanzione_rur
                                               , w_sanzione_ter_com, w_sanzione_ter_sta
                                               , w_sanzione_aree_com, w_sanzione_aree_sta
                                               , w_sanzione_altri_com, w_sanzione_altri_sta
                                               , w_sanzione_fabb_d_com, w_sanzione_fabb_d_sta
                                               , w_note_sanzione
                                               );
            if w_errore_interessi <> 'OK' then
               w_errore := 'Errore in Determinazione Interessi in Acconto su Pagamenti'
                           ||w_errore_interessi;
               RAISE ERRORE;
            end if;
         end if;

         w_giorni := a_data_pagam - w_scadenza_acc;
         insert into sanzioni_pratica
               ( pratica, cod_sanzione, tipo_tributo
               , percentuale, importo, riduzione, riduzione_2
               , ab_principale ,rurali
               , terreni_comune, terreni_erariale
               , aree_comune, aree_erariale
               , altri_comune, altri_erariale
               , fabbricati_d_comune, fabbricati_d_erariale
               , giorni, utente, data_variazione ,note
               )
         values( a_pratica, w_cod_sanzione,'TASI'
               , null, w_sanzione, null, null
               , w_sanzione_ab, w_sanzione_rur
               , w_sanzione_ter_com, w_sanzione_ter_sta
               , w_sanzione_aree_com, w_sanzione_aree_sta
               , w_sanzione_altri_com, w_sanzione_altri_sta
               , w_sanzione_fabb_d_com, w_sanzione_fabb_d_sta
               , w_giorni, a_utente, trunc(sysdate), w_note_sanzione
               )
         ;
      end if;
   end if;
--
-- Modifica del 26/01/2015: aggiunta gestione ravvedimento medio
-- per data versamento >= 01/01/2015 e gg di ritardo compresi tra 30 e 90
--
   if w_diff_giorni > 0 then
      -- (VD - 05/02/2020): Ravvedimento operoso lungo
      if w_diff_giorni > 730 and
         a_data_pagam >= to_date('01012020','ddmmyyyy') then
         w_cod_sanzione := 168;
         w_rid := 6;
      elsif
         w_diff_giorni > 365 and
         a_data_pagam >= to_date('01012020','ddmmyyyy') then
         w_cod_sanzione := 167;
         w_rid := 7;
      elsif
         (w_diff_giorni > 90 and
          a_data_pagam >= to_date('01012015','ddmmyyyy')) or
         (w_diff_giorni > 30 and
          a_data_pagam < to_date('01012015','ddmmyyyy')) then
         if  sign(2 - w_anno_scadenza + w_anno) < 1 then
            w_cod_sanzione := 156;
            w_rid := 8;
         else
            w_cod_sanzione := 154;
            w_rid := 8;
         end if;
      elsif w_diff_giorni > 30 then
         if  sign(2 - w_anno_scadenza + w_anno) < 1 then
            w_cod_sanzione := 156;
            w_rid := 9;
         else
            w_cod_sanzione := 154;
            w_rid := 9;
         end if;
      else
         if w_diff_giorni <= 15 then
            w_cod_sanzione    := 159;
            w_rid             := 10;
         else
            w_cod_sanzione    := 160;
            w_rid             := 10;
         end if;
      end if;
      --
      -- (VD - 18/01/2016): Se la pratica e' del 2016 e il versamento e'
      --                    stato effettuato entro 90 gg dalla scadenza,
      --                    la sanzione viene dimezzata (la riduzione
      --                    viene raddoppiata)
      if w_data_pratica >= to_date('01/01/2016','dd/mm/yyyy') and
         w_diff_giorni <= 90 then
         w_rid := w_rid * 2;
      end if;
--dbms_output.put_line('SALDO');
--dbms_output.put_line('w_cod_sanzione'||to_char(w_cod_sanzione));
--dbms_output.put_line('w_rid'||to_char(w_rid));
--dbms_output.put_line('w_versato_tard_sal'||to_char(w_versato_tard_sal));
--dbms_output.put_line('w_rid'||to_char(w_rid));
--dbms_output.put_line('w_percentuale'||to_char(w_percentuale));
--dbms_output.put_line('w_riduzione'||to_char(w_riduzione));
--dbms_output.put_line('w_sanzione'||to_char(w_sanzione));
--dbms_output.put_line('w_imposta_sal'||to_char(w_imposta_sal));
      if a_tipo_pagam in ('S','U') and (w_versato_tard_sal > 0 or w_imposta_sal > 0) then
         if w_versato_tard_sal > 0 and w_imposta_sal = 0 then
            if w_cod_sanzione = 159 then
               -- Gestione della sanzione con percentuale che dipende dai giorni di interesse
               if F_IMP_SANZ_GG( w_cod_sanzione, w_versato_tard_sal
                               , w_rid, w_diff_giorni
                               , w_anno
                               , w_versato_tard_ab_sal, w_versato_tard_rur_sal
                               --, w_versato_tard_ter_com_sal, w_versato_tard_ter_sta_sal
                               --, w_versato_tard_aree_com_sal, w_versato_tard_aree_sta_sal
                               --, w_versato_tard_altri_com_sal, w_versato_tard_altri_sta_sal
                               --, w_versato_tard_fabb_d_com_sal, w_versato_tard_fabb_d_sta_sal
                               , w_versato_tard_ter_sal, 0
                               , w_versato_tard_aree_sal, 0
                               , w_versato_tard_altri_sal, 0
                               , 0, 0
                               , w_percentuale, w_riduzione
                               , w_riduzione_2, w_sanzione
                               , w_sanzione_ab, w_sanzione_rur
                               , w_sanzione_ter_com, w_sanzione_ter_sta
                               , w_sanzione_aree_com, w_sanzione_aree_sta
                               , w_sanzione_altri_com, w_sanzione_altri_sta
                               , w_sanzione_fabb_d_com, w_sanzione_fabb_d_sta
                               ) is not null then
                  w_errore := 'Errore in Determinazione Sanzione ICI per Codice '||
                              to_char(w_cod_sanzione);
                  RAISE ERRORE;
               end if;
            else
               if F_IMP_SANZ( w_cod_sanzione, w_versato_tard_sal
                            , w_rid
                            , w_anno
                            , w_versato_tard_ab_sal, w_versato_tard_rur_sal
                            --, w_versato_tard_ter_com_sal, w_versato_tard_ter_sta_sal
                            --, w_versato_tard_aree_com_sal, w_versato_tard_aree_sta_sal
                            --, w_versato_tard_altri_com_sal, w_versato_tard_altri_sta_sal
                            --, w_versato_tard_fabb_d_com_sal, w_versato_tard_fabb_d_sta_sal
                            , w_versato_tard_ter_sal, 0
                            , w_versato_tard_aree_sal, 0
                            , w_versato_tard_altri_sal, 0
                            , 0, 0
                            , w_percentuale, w_riduzione
                            , w_riduzione_2, w_sanzione
                            , w_sanzione_ab, w_sanzione_rur
                            , w_sanzione_ter_com, w_sanzione_ter_sta
                            , w_sanzione_aree_com, w_sanzione_aree_sta
                            , w_sanzione_altri_com, w_sanzione_altri_sta
                            , w_sanzione_fabb_d_com, w_sanzione_fabb_d_sta
                            ) is not null then
                  w_errore := 'Errore in Determinazione Sanzione ICI per Codice '||
                              to_char(w_cod_sanzione);
                  RAISE ERRORE;
               end if;
            end if;
         else
            if w_cod_sanzione = 159 then
               -- Gestione della sanzione con percentuale che dipende dai giorni di interesse
               if F_IMP_SANZ_GG( w_cod_sanzione, w_imposta_sal
                               , w_rid, w_diff_giorni
                               , w_anno
                               , w_imposta_ab_sal, w_imposta_rur_sal
                               --, w_imposta_ter_com_sal, w_imposta_ter_sta_sal
                               --, w_imposta_aree_com_sal, w_imposta_aree_sta_sal
                               --, w_imposta_altri_com_sal, w_imposta_altri_sta_sal
                               --, w_imposta_fabb_d_com_sal, w_imposta_fabb_d_sta_sal
                               , w_imposta_ter_sal, 0
                               , w_imposta_aree_sal, 0
                               , w_imposta_altri_sal, 0
                               , 0, 0
                               , w_percentuale, w_riduzione
                               , w_riduzione_2, w_sanzione
                               , w_sanzione_ab, w_sanzione_rur
                               , w_sanzione_ter_com, w_sanzione_ter_sta
                               , w_sanzione_aree_com, w_sanzione_aree_sta
                               , w_sanzione_altri_com, w_sanzione_altri_sta
                               , w_sanzione_fabb_d_com, w_sanzione_fabb_d_sta
                               ) is not null then
                  w_errore := 'Errore in Determinazione Sanzione ICI per Codice '||
                              to_char(w_cod_sanzione);
                  RAISE ERRORE;
               end if;
            else
               if F_IMP_SANZ( w_cod_sanzione, w_imposta_sal
                            , w_rid, w_anno
                            , w_imposta_ab_sal, w_imposta_rur_sal
                            --, w_imposta_ter_com_sal, w_imposta_ter_sta_sal
                            --, w_imposta_aree_com_sal, w_imposta_aree_sta_sal
                            --, w_imposta_altri_com_sal, w_imposta_altri_sta_sal
                            --, w_imposta_fabb_d_com_sal, w_imposta_fabb_d_sta_sal
                            , w_imposta_ter_sal, 0
                            , w_imposta_aree_sal, 0
                            , w_imposta_altri_sal, 0
                            , 0, 0
                            , w_percentuale, w_riduzione
                            , w_riduzione_2, w_sanzione
                            , w_sanzione_ab, w_sanzione_rur
                            , w_sanzione_ter_com, w_sanzione_ter_sta
                            , w_sanzione_aree_com, w_sanzione_aree_sta
                            , w_sanzione_altri_com, w_sanzione_altri_sta
                            , w_sanzione_fabb_d_com, w_sanzione_fabb_d_sta
                            ) is not null then
                  w_errore := 'Errore in Determinazione Sanzione ICI per Codice '||
                              to_char(w_cod_sanzione);
                  RAISE ERRORE;
               end if;
            end if;
         end if;
         insert into sanzioni_pratica
               ( pratica, cod_sanzione, tipo_tributo
               , percentuale, importo, riduzione, riduzione_2
               , ab_principale ,rurali
               , terreni_comune, terreni_erariale
               , aree_comune, aree_erariale
               , altri_comune, altri_erariale
               , fabbricati_d_comune, fabbricati_d_erariale
               , utente, data_variazione
               , note
               )
         values( a_pratica, w_cod_sanzione, 'TASI'
               , w_percentuale, w_sanzione, w_riduzione, w_riduzione_2
               , w_sanzione_ab, w_sanzione_rur
               , w_sanzione_ter_com, w_sanzione_ter_sta
               , w_sanzione_aree_com, w_sanzione_aree_sta
               , w_sanzione_altri_com, w_sanzione_altri_sta
               , w_sanzione_fabb_d_com, w_sanzione_fabb_d_sta
               , a_utente, trunc(sysdate)
               , 'Ulteriore riduzione di 1/'||to_char(w_rid)||' per ravvedimento operoso'
               )
         ;
         w_cod_sanzione := 199;
         if w_versato_tard_sal > 0 and w_imposta_sal = 0 then
            w_errore_interessi := F_CALCOLO_INT( w_versato_tard_sal, w_scadenza + 1
                                               , a_data_pagam, w_giorni_anno
                                               , w_anno
                                               , w_versato_tard_ab_sal, w_versato_tard_rur_sal
                                               --, w_versato_tard_ter_com_sal, w_versato_tard_ter_sta_sal
                                               --, w_versato_tard_aree_com_sal, w_versato_tard_aree_sta_sal
                                               --, w_versato_tard_altri_com_sal, w_versato_tard_altri_sta_sal
                                               --, w_versato_tard_fabb_d_com_sal, w_versato_tard_fabb_d_sta_sal
                                               , w_versato_tard_ter_sal, 0
                                               , w_versato_tard_aree_sal, 0
                                               , w_versato_tard_altri_sal, 0
                                               , 0, 0
                                               , w_sanzione
                                               , w_sanzione_ab, w_sanzione_rur
                                               , w_sanzione_ter_com, w_sanzione_ter_sta
                                               , w_sanzione_aree_com, w_sanzione_aree_sta
                                               , w_sanzione_altri_com, w_sanzione_altri_sta
                                               , w_sanzione_fabb_d_com, w_sanzione_fabb_d_sta
                                               , w_note_sanzione
                                               );
            if w_errore_interessi <> 'OK' then
               w_errore := 'Errore in Determinazione Interessi a Saldo su Pagamenti'
                           ||w_errore_interessi;
               RAISE ERRORE;
            end if;
         else
            w_errore_interessi := F_CALCOLO_INT( w_imposta_sal, w_scadenza + 1
                                               , a_data_pagam, w_giorni_anno
                                               , w_anno
                                               , w_imposta_ab_sal, w_imposta_rur_sal
                                               --, w_imposta_ter_com_sal, w_imposta_ter_sta_sal
                                               --, w_imposta_aree_com_sal, w_imposta_aree_sta_sal
                                               --, w_imposta_altri_com_sal, w_imposta_altri_sta_sal
                                               --, w_imposta_fabb_d_com_sal, w_imposta_fabb_d_sta_sal
                                               , w_imposta_ter_sal, 0
                                               , w_imposta_aree_sal, 0
                                               , w_imposta_altri_sal, 0
                                               , 0, 0
                                               , w_sanzione
                                               , w_sanzione_ab, w_sanzione_rur
                                               , w_sanzione_ter_com, w_sanzione_ter_sta
                                               , w_sanzione_aree_com, w_sanzione_aree_sta
                                               , w_sanzione_altri_com, w_sanzione_altri_sta
                                               , w_sanzione_fabb_d_com, w_sanzione_fabb_d_sta
                                               , w_note_sanzione
                                               );
            if w_errore_interessi <> 'OK' then
               w_errore := 'Errore in Determinazione Interessi a Saldo su Pagamenti'
                           ||w_errore_interessi;
               RAISE ERRORE;
            end if;
         end if;
         w_giorni := a_data_pagam - w_scadenza;
         insert into sanzioni_pratica
               ( pratica, cod_sanzione, tipo_tributo
               , percentuale, importo, riduzione, riduzione_2
               , ab_principale ,rurali
               , terreni_comune, terreni_erariale
               , aree_comune, aree_erariale
               , altri_comune, altri_erariale
               , fabbricati_d_comune, fabbricati_d_erariale
               , giorni,utente, data_variazione, note
               )
         values( a_pratica, w_cod_sanzione, 'TASI'
               , null, w_sanzione, null, null
               , w_sanzione_ab, w_sanzione_rur
               , w_sanzione_ter_com, w_sanzione_ter_sta
               , w_sanzione_aree_com, w_sanzione_aree_sta
               , w_sanzione_altri_com, w_sanzione_altri_sta
               , w_sanzione_fabb_d_com, w_sanzione_fabb_d_sta
               , w_giorni, a_utente, trunc(sysdate), w_note_sanzione
               )
         ;
      end if;
   end if;
    -- (AB - 28/02/2023): se il contribuente è deceduto, si eliminano
    --                    le sanzioni lasciando solo imposta evasa,
    --                    interessi e spese di notifica
   BEGIN
      select stato
        into w_stato_sogg
        from soggetti sogg, contribuenti cont
       where sogg.ni = cont.ni
         and cont.cod_fiscale = w_cod_fiscale
      ;
   EXCEPTION
      WHEN others THEN
         w_errore := 'Errore in ricerca sOGGETTI '||SQLERRM;
         RAISE errore;
   END;
   if w_stato_sogg = 50 then
      ELIMINA_SANZ_LIQ_DECEDUTI(a_pratica);
   end if;
   COMMIT;

EXCEPTION
   WHEN ERRORE THEN
      ROLLBACK;
      RAISE_APPLICATION_ERROR(-20999,w_errore);
   WHEN OTHERS THEN
      ROLLBACK;
      RAISE_APPLICATION_ERROR(-20999,to_char(SQLCODE)||' - '||SQLERRM);
END;
/* End Procedure: CALCOLO_SANZIONI_RAOP_TASI */
/
