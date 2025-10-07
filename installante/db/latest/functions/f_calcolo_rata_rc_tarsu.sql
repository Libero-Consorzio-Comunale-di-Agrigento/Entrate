--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_calcolo_rata_rc_tarsu stripComments:false runOnChange:true 
 
create or replace function F_CALCOLO_RATA_RC_TARSU
/******************************************************************************
   NOME:        F_CALCOLO_RATA_RC_TARSU
   DESCRIZIONE: Procedure e Funzioni per integrazione con PAGONLINE
                Contrariamente a F_CALCOLO_RATA_TARSU che arrotonda all'euro
                questa procedure arrotonda al centesimo

   ANNOTAZIONI: -
   REVISIONI:
   Rev.  Data        Autore  Descrizione
   ----  ----------  ------  ----------------------------------------------------
   000   07/02/2024  RV      Prima emissione (Da F_CALCOLO_RATA_TARSU)
   001   04/06/2024  RV      #72976
                             Seconda emissione dopo modifiche per Componenti Perequative
   002   04/10/2024  RV      #73212
                             Aggiunto tipo 'Y', come 'X' ma ignora qualsiasi versato
   003   14/11/2024  RV      #71533
                             Aggiunto tipo 'R', solo Maggiorazione TARES (Componenti Perequative)
   004   14/01/2025  RV      #71531
                             Lo sgravio maggiorazione_tares veniva erroneamente applicato
                             anche sull'imposta netta
   005   13/02/2025  RV      #77805
                             Rivisto per componenti perequative spalmate
   006   10/03/2025  RV      #78970
                             Rivisto per importi eccedenze
                             Uniformato con F_CALCOLO_RATA_TARSU
******************************************************************************/
( p_cod_fiscale             varchar2
, p_ruolo                   number
, p_numero_rate             number
, p_rata                    number
, p_tipo_rata               varchar2
, p_vers_positivi           varchar2 default null
, p_data_inizio             date default to_date('01/01/1900','dd/mm/yyyy')
) return number
is
  --
  w_tipo_rata               varchar2(1);
  --
  w_anno_ruolo              number;
  --
  w_tot_imposta_nt          number;
  w_tot_imposta_cp          number;
  w_tot_imposta             number;
  w_tot_add_pro             number;
  w_tot_comp_pereq          number;
  --
  w_versato_imposta         number;
  w_versato_add_pro         number;
  --
  w_importo_scalare         number;
  w_imp_rata_imposta        number;
  w_imp_rata_add_pro        number;
  w_importo_rata            number;
  w_importo_ultima_rata     number;
  --
  w_sbil_tares_ruolo        number;
  w_sbil_tares_rata         number;
  --
  w_rounding                number;
  --
begin
  --
  w_tipo_rata := p_tipo_rata;
  --
  w_rounding := 2;
  --
  begin
    select max(totl.anno_ruolo) as anno_ruolo
         , round (sum(totl.tot_imposta_nt), w_rounding) as tot_imposta_nt
         , round (sum(totl.tot_imposta_cp), w_rounding) as tot_imposta_cp
         , round (sum(totl.tot_add_pro), w_rounding) as tot_add_pro
         , round (sum(totl.tot_comp_pereq), w_rounding) as tot_comp_pereq
         , max (totl.versato_imposta) as versato_imposta
         , max (totl.versato_add_pro) as versato_add_pro
         , sum (totl.sbil_tares_ruolo) as sbil_tares_ruolo
         , sum (totl.sbil_tares_rata) as sbil_tares_rata
    into w_anno_ruolo
       , w_tot_imposta_nt     -- Imposta netta
       , w_tot_imposta_cp     -- Imposta netta + Componenti Perequative
       , w_tot_add_pro        -- Addizionale Provinciale / TEFA
       , w_tot_comp_pereq     -- Componenti Perequative
       , w_versato_imposta
       , w_versato_add_pro
       , w_sbil_tares_ruolo
       , w_sbil_tares_rata
    from
        (
        select max(ruol.anno_ruolo) as anno_ruolo
             , greatest (0 ,    nvl (sum (o.imposta), 0)
                              + nvl (max (sanzioni.sanzione), 0)
                              - nvl (max (coru.compensazione_imposta), 0)
                              - nvl (max (sgra.imposta), 0)
                           ) as tot_imposta_nt
             , greatest (0 ,    nvl (sum (o.imposta), 0)
                              + nvl (max (sanzioni.sanzione), 0)
                              - nvl (max (coru.compensazione_imposta), 0)
                              - nvl (max (sgra.imposta), 0)
                                + nvl (sum (o.maggiorazione_tares), 0)    -- #72976 : Totale Componenti Perequative
                                - nvl (max (sgra.maggiorazione_tares), 0)
                           ) as tot_imposta_cp
             , greatest (0 ,    nvl (sum (o.addizionale_pro), 0)
                              - nvl (max (coru.compensazione_add_pro), 0)
                              - nvl (max (sgra.addizionale_pro), 0)
                           ) as tot_add_pro
             , greatest (0 ,    nvl (sum (o.maggiorazione_tares), 0)      -- #71533 : Totale Componenti Perequative
                              - nvl (max (sgra.maggiorazione_tares), 0)
                           ) as tot_comp_pereq
             , decode (max (ruol.tipo_emissione)
                      ,'T', max (  f_tot_vers_cont_ruol (ruol.anno_ruolo
                                                        ,p_cod_fiscale
                                                        ,ruol.tipo_tributo
                                                        ,null
                                                        ,   'VI'
                                                         || decode (nvl(p_vers_positivi,'NO')
                                                                   ,'SI', '+'
                                                                   ,''
                                                                   )
                                                        )
                                )
                      ,0
                      ) as versato_imposta
             , decode (max (ruol.tipo_emissione)
                      ,'T', max (  f_tot_vers_cont_ruol (ruol.anno_ruolo
                                                        ,p_cod_fiscale
                                                        ,ruol.tipo_tributo
                                                        ,null
                                                        ,   'VP'
                                                         || decode (nvl(p_vers_positivi,'NO')
                                                                   ,'SI', '+'
                                                                   ,''
                                                                   )
                                                        )
                                )
                      ,0
                      ) as versato_add_pro
             , f_sbilancio_tares(p_cod_fiscale,p_ruolo, 0, w_rounding,'S') as sbil_tares_ruolo
             , f_sbilancio_tares(p_cod_fiscale,p_ruolo, p_rata, w_rounding,'S') as sbil_tares_rata
          from ruoli_contribuente r
              ,oggetti_imposta o
              ,sanzioni
              ,ruoli ruol
              ,dati_generali dage
              ,(select sum (compensazione) compensazione
                      ,sum (compensazione - ((compensazione * nvl(f_get_cata_perc(coru.anno,'AP'),0)) /
                                              (100 + nvl(f_get_cata_perc(coru.anno,'AP'),0))))
                       compensazione_imposta
                      ,sum((compensazione * nvl(f_get_cata_perc(coru.anno,'AP'),0)) /
                                    (100 + nvl(f_get_cata_perc(coru.anno,'AP'),0))) compensazione_add_pro
                  from compensazioni_ruolo coru
                  where coru.ruolo = p_ruolo
                   and cod_fiscale = p_cod_fiscale) coru
              ,(select sum (nvl (sgra.importo, 0)) importo_lordo
                      ,sum (nvl (sgra.importo, 0) - nvl(sgra.addizionale_pro, 0) - nvl(sgra.maggiorazione_tares, 0)) imposta
                      ,sum (sgra.addizionale_pro) addizionale_pro
                      ,sum (sgra.maggiorazione_tares) maggiorazione_tares
                  from sgravi sgra
                 where sgra.motivo_sgravio != 99
                   and sgra.cod_fiscale = p_cod_fiscale
                   and sgra.ruolo = p_ruolo) sgra
         where r.ruolo = p_ruolo
           and o.ruolo = r.ruolo
           and ruol.ruolo = p_ruolo
           and sanzioni.cod_sanzione(+) = 115
           and sanzioni.tipo_tributo(+) = ruol.tipo_tributo
           and p_data_inizio between sanzioni.data_inizio (+) and sanzioni.data_fine (+)
           and r.oggetto_imposta = o.oggetto_imposta
           and r.cod_fiscale = p_cod_fiscale
       union
        select max (ruol.anno_ruolo) as anno_ruolo
             , sum (ruec.imposta) as tot_imposta_nt
             , sum (ruec.imposta) as tot_imposta_cp
             , sum (ruec.addizionale_pro) as tot_add_pro
             , 0 as tot_comp_pereq
             , 0 as versato_imposta
             , 0 as versato_add_pro
             , 0 as sbil_tares_ruolo
             , 0 as sbil_tares_rata
          from ruoli_eccedenze ruec,
               ruoli ruol
         where ruec.ruolo = p_ruolo
           and ruec.ruolo = ruol.ruolo
           and ruec.cod_fiscale = p_cod_fiscale
         ) totl
      ;
  exception
    when others then
      w_tot_imposta_nt := 0;
      w_tot_imposta_cp := 0;
      w_tot_add_pro := 0;
      w_tot_comp_pereq := 0;
      w_versato_imposta := 0;
      w_versato_add_pro := 0;
      w_sbil_tares_ruolo := 0;
      w_sbil_tares_rata := 0;
  end;
  --
--dbms_output.put_line('Sbilancio: '||w_sbil_tares_ruolo||', rata: '||w_sbil_tares_rata);
  --
  if w_tipo_rata in ('R','Y') then
    -- Ignora il versato
    w_versato_imposta := 0;
    w_versato_add_pro := 0;
  end if;
  --
  if w_tipo_rata in ('Y') then
    -- Versato già ignorato, procede come fosse 'X'
    w_tipo_rata := 'X';
  end if;
  --
     if p_rata = 0 then
        case w_tipo_rata
          when 'I' then
             w_importo_rata := w_tot_imposta_nt - w_versato_imposta;
          when 'Q' then
             w_importo_rata := w_tot_imposta_cp - w_versato_imposta;
          when 'P' then
             w_importo_rata := w_tot_add_pro - w_versato_add_pro;
          when 'R' then
             w_importo_rata := w_tot_comp_pereq;
          when 'T' then
             w_importo_rata := w_tot_imposta_nt + w_tot_add_pro -
                               w_versato_imposta - w_versato_add_pro;
          when 'X' then
             w_importo_rata := w_tot_imposta_cp + w_tot_add_pro -
                               w_versato_imposta - w_versato_add_pro;
          else
             w_importo_rata := 0;
        end case;
     else
        if w_tipo_rata in ('Q','X') then
          w_tot_imposta := w_tot_imposta_cp - w_sbil_tares_ruolo;
        elsif w_tipo_rata in ('R') then
          w_tot_imposta := w_tot_comp_pereq;
        else
          w_tot_imposta := w_tot_imposta_nt;
        end if;
        -- Quota Imposta
        if w_tipo_rata in ('I','T','Q','R','X') then
           w_imp_rata_imposta := round((w_tot_imposta / p_numero_rate), w_rounding);
           w_importo_ultima_rata := w_tot_imposta - (w_imp_rata_imposta * (p_numero_rate - 1));
           if p_rata = p_numero_rate then
              w_importo_scalare := w_tot_imposta;
           else
              w_importo_scalare := w_imp_rata_imposta * p_rata;
           end if;
           if w_versato_imposta >= w_importo_scalare then
              w_imp_rata_imposta := 0;
           else
              if p_rata = p_numero_rate then
                 w_imp_rata_imposta := least(w_importo_ultima_rata,w_importo_scalare - w_versato_imposta);
              else
                 w_imp_rata_imposta := least(w_imp_rata_imposta,w_importo_scalare - w_versato_imposta);
              end if;
           end if;
        end if;
        -- Quota Addizionali
        if w_tipo_rata in ('P','T','X') then
           w_imp_rata_add_pro := round((w_tot_add_pro / p_numero_rate), w_rounding);
           w_importo_ultima_rata  := w_tot_add_pro - (w_imp_rata_add_pro * (p_numero_rate - 1));
           if p_rata = p_numero_rate then
              w_importo_scalare := w_tot_add_pro;
           else
              w_importo_scalare := w_imp_rata_add_pro * p_rata;
           end if;
           if w_versato_add_pro >= w_importo_scalare then
              w_imp_rata_add_pro := 0;
           else
              if p_rata = p_numero_rate then
                 w_imp_rata_add_pro := least(w_importo_ultima_rata,w_importo_scalare - w_versato_add_pro);
              else
                 w_imp_rata_add_pro := least(w_imp_rata_add_pro,w_importo_scalare - w_versato_add_pro);
              end if;
           end if;
        end if;
        case w_tipo_rata
          when 'I' then w_importo_rata := w_imp_rata_imposta;
          when 'Q' then w_importo_rata := w_imp_rata_imposta + w_sbil_tares_rata;
          when 'R' then w_importo_rata := w_imp_rata_imposta;
          when 'P' then w_importo_rata := w_imp_rata_add_pro;
          when 'T' then w_importo_rata := w_imp_rata_imposta + w_imp_rata_add_pro;
          when 'X' then w_importo_rata := w_imp_rata_imposta + w_imp_rata_add_pro + w_sbil_tares_rata;
        end case;
     end if;
  --
  return w_importo_rata;
end;
/* End Function: F_CALCOLO_RATA_RC_TARSU */
/
