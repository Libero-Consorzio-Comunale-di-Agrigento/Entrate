--liquibase formatted sql 
--changeset abrandolini:20250326_152423_calcolo_detrazioni_tasi_ogge stripComments:false runOnChange:true 
 
create or replace procedure CALCOLO_DETRAZIONI_TASI_OGGE
/*******************************************************************************
  NOME:        CALCOLO_DETRAZIONI_TASI_OGGE
  DESCRIZIONE: Calcola le detrazioni TASI per contribuente/oggetto
  ANNOTAZIONI:
  REVISIONI:
  Rev.  Data        Autore  Descrizione
  ----  ----------  ------  ----------------------------------------------------
  001   13/10/2021  VD      Aggiunto parametro tipo_evento che corrisponde
                            al tipo_versamento dei ravvedimenti. Necessario
                            per gestire la presenza di ravvedimento in acconto
                            e ravvedimento a saldo per lo stesso anno.
  000   XX/XX/XXXX  XX      Prima emissione.
*******************************************************************************/
(a_cf           IN varchar2
,a_anno         IN number
,a_ravvedimento IN varchar2
,a_tipo_evento  IN varchar2 default null
) is
errore                              exception;
fine                                exception;
w_errore                            varchar2(2000);
w_flag_pertinenze                   varchar2(1);
w_mesi_possesso                     number;
w_mesi_possesso_1s                  number;
w_stringa                           varchar2(18);
w_flag_possesso                     varchar2(1);
w_detrazione                        number;
w_detrazione_acconto                number;
w_detrazione_d                      number;
w_detrazione_acconto_d              number;
w_detrazione_rim                    number;
w_detrazione_rim_d                  number;
w_cod_fiscale                       varchar2(16);
w_ogpr number;
--
-- Vengono estratti solo gli oggetti_pratica che hanno una detrazione oggetto (detrazioni_ogco)
-- e sui quali ¿ stato appena fatto il Calcolo Imposta
--
cursor sel_ogco (p_cf              varchar2
                ,p_anno            number
                ,p_flag_pertinenze varchar2
                ,p_ravvedimento    varchar2
                ,p_tipo_evento     varchar2
                )
is
select decode(ogco.anno
             ,p_anno,nvl(ogco.mesi_possesso,12)
                    ,12
             )                     mesi_possesso
      ,decode(ogco.anno
             ,p_anno,decode(ogco.flag_esclusione
                           ,'S',nvl(ogco.mesi_esclusione,nvl(ogco.mesi_possesso,12))
                               ,nvl(ogco.mesi_esclusione,0)
                           )
                    ,decode(ogco.flag_esclusione,'S',12,0)
            )                      mesi_esclusione
      ,ogco.flag_possesso          flag_possesso
      ,ogco.flag_esclusione        flag_esclusione
      ,ogco.oggetto_pratica        oggetto_pratica
      ,ogpr.oggetto                oggetto
      ,ogco.anno                   anno
      ,ogim.cod_fiscale            cod_fiscale
      ,ogim.oggetto_imposta        oggetto_imposta
      ,ogim.imposta                imposta
      ,ogim.imposta_dovuta         imposta_dovuta
      ,ogim.imposta_acconto        imposta_acconto
      ,ogim.imposta_dovuta_acconto imposta_dovuta_acconto
      ,deog.detrazione             detrazione
      ,deog.detrazione_acconto     detrazione_acconto
  from oggetti_contribuente        ogco
      ,oggetti_pratica             ogpr
      ,pratiche_tributo            prtr
      ,oggetti                     ogge
      ,oggetti_imposta             ogim
      ,detrazioni_ogco             deog
 where ogco.cod_fiscale               like    p_cf
   and ogco.oggetto_pratica           =    ogim.oggetto_pratica
   and ogpr.oggetto_pratica           =    ogim.oggetto_pratica
   and prtr.pratica                   =    ogpr.pratica
   and prtr.tipo_tributo||''          =    'TASI'
   and ogge.oggetto                   =    ogpr.oggetto
   and ogim.cod_fiscale||''            =    ogco.cod_fiscale
   and ogim.anno+0                      =    p_anno
   and ogim.ruolo                    is    null
   and trunc(ogim.data_variazione)    =    trunc(sysdate)
   and deog.cod_fiscale               =    ogco.cod_fiscale
   and deog.oggetto_pratica           =    ogco.oggetto_pratica
   and deog.anno                      =    p_anno
   and deog.tipo_tributo              =    'TASI'
   and (   ( p_ravvedimento           =    'S'
         and prtr.tipo_pratica        =    'V'
         and prtr.tipo_evento         = nvl(p_tipo_evento,prtr.tipo_evento)
           )
        or ( p_ravvedimento           =    'N'
         and prtr.tipo_pratica        in    ('D','A')
           )
       )
   and (    p_flag_pertinenze         = 'S'
        and F_DATO_RIOG(ogim.cod_fiscale
                       ,ogim.oggetto_pratica
                       ,ogim.anno
                       ,'CA'
                       )           like 'C%'
        or  F_DATO_RIOG(ogim.cod_fiscale
                       ,ogim.oggetto_pratica
                       ,ogim.anno
                       ,'CA'
                       )           like 'A%'
       )
;
--
-- e le pertinenze collegate a tali oggetti gli oggetti_pratica che hanno una detrazione oggetto (detrazioni_ogco)
-- per "spalmare" la eventuale rimanenza di detrazione
--
cursor sel_pert (p_cf              varchar2
                ,p_oggetto_pratica number
                ,p_anno            number
                ,p_flag_pertinenze varchar2
                ,p_ravvedimento    varchar2
                ,p_tipo_evento     varchar2
                )
is
select ogco.oggetto_pratica        oggetto_pratica
      ,ogpr.oggetto                oggetto
      ,ogco.anno                   anno
      ,ogim.oggetto_imposta        oggetto_imposta
      ,ogim.cod_fiscale            cod_fiscale
      ,ogim.imposta                imposta
      ,ogim.imposta_dovuta         imposta_dovuta
      ,ogim.imposta_acconto        imposta_acconto
      ,ogim.imposta_dovuta_acconto imposta_dovuta_acconto
  from oggetti_contribuente        ogco
      ,oggetti_pratica             ogpr
      ,pratiche_tributo            prtr
      ,oggetti                     ogge
      ,oggetti_imposta             ogim
 where ogco.cod_fiscale               =    ogim.cod_fiscale
   and ogco.oggetto_pratica           =    ogim.oggetto_pratica
   and ogpr.oggetto_pratica           =    ogim.oggetto_pratica
   and prtr.pratica                   =    ogpr.pratica
   and prtr.tipo_tributo||''          =    'TASI'
   and ogge.oggetto                   =    ogpr.oggetto
   and ogim.cod_fiscale||''               =    p_cf
   and ogim.anno+0                      =    p_anno
   and ogim.ruolo                    is    null
   and trunc(ogim.data_variazione)    =    trunc(sysdate)
   and ogpr.oggetto_pratica_rif_ap    =    p_oggetto_pratica
   and (   ( p_ravvedimento           =    'S'
         and prtr.tipo_pratica        =    'V'
         and prtr.tipo_evento         = nvl(p_tipo_evento,prtr.tipo_evento)
           )
        or ( p_ravvedimento           =    'N'
        and prtr.tipo_pratica         in    ('D','A')
           )
       )
   and (    p_flag_pertinenze         = 'S'
        and F_DATO_RIOG(ogim.cod_fiscale
                       ,ogim.oggetto_pratica
                       ,ogim.anno
                       ,'CA'
                       )           like 'C%'
        or  F_DATO_RIOG(ogim.cod_fiscale
                       ,ogim.oggetto_pratica
                       ,ogim.anno
                       ,'CA'
                       )           like 'A%'
       )
 order by
      ogim.imposta
;
BEGIN
--
-- Determinazione della presenza di gestione delle pertinenze.
--
   BEGIN
      select flag_pertinenze
        into w_flag_pertinenze
        from aliquote
       where flag_ab_principale = 'S'
         and anno               = a_anno
         and tipo_tributo       = 'TASI'
      ;
   EXCEPTION
      WHEN NO_DATA_FOUND OR TOO_MANY_ROWS THEN
         w_flag_pertinenze := null;
   END;
--
-- Trattamento Contribuenti.
--
   FOR rec_ogco IN sel_ogco (a_cf,a_anno,w_flag_pertinenze,
                             a_ravvedimento,a_tipo_evento)
   LOOP
      w_cod_fiscale := rec_ogco.cod_fiscale;
            w_detrazione_rim       := 0;
            w_detrazione_rim_d     := 0;
            w_flag_possesso            := rec_ogco.flag_possesso;
            w_ogpr := rec_ogco.oggetto_pratica;
--
-- Determinazione  Mesi di Possesso  per l`intero anno e per il primo semestre.
-- La F_DATO_RIOG  restituisce una stringa  del tipo  XXYYYYYYYYZZZZZZZZ in cui
-- XX e` il numero dei mesi di possesso, YYYYYYYY e` la data di inizio possesso
-- in forma GGMMAAAA e ZZZZZZZZ e` la data di fine possesso nella stessa forma.
-- Qualora i mesi di possesso siano = 0, le date contengono il valore 00000000.
-- Per ottenere il possesso dell`intero anno l`ultimo parametro deve essere PT,
-- mentre per il possesso del primo semestre deve essere PA.
--
            w_stringa                  := F_DATO_RIOG(rec_ogco.cod_fiscale
                                                     ,rec_ogco.oggetto_pratica
                                                     ,a_anno
                                                     ,'PT'
                                                     );
            w_mesi_possesso            := to_number(substr(w_stringa,01,2));
            w_stringa                  := F_DATO_RIOG(rec_ogco.cod_fiscale
                                                     ,rec_ogco.oggetto_pratica
                                                     ,a_anno
                                                     ,'PA'
                                                     );
            w_mesi_possesso_1s         := to_number(substr(w_stringa,01,2));
               w_detrazione       := rec_ogco.detrazione;
               w_detrazione_rim   := w_detrazione;
               w_detrazione_rim_d := w_detrazione;
            if rec_ogco.detrazione_acconto is null then
                  w_detrazione_acconto := round(rec_ogco.detrazione / w_mesi_possesso * w_mesi_possesso_1s,2);
            else
              w_detrazione_acconto := rec_ogco.detrazione_acconto;
            end if;
               w_detrazione             := least(nvl(rec_ogco.imposta,0)
                                                ,nvl(w_detrazione,0)
                                                );
               w_detrazione_d           := least(nvl(rec_ogco.imposta_dovuta,0)
                                                ,nvl(w_detrazione,0)
                                                );
               w_detrazione_acconto     := least(nvl(rec_ogco.imposta_acconto,0)
                                                ,nvl(w_detrazione_acconto,0)
                                                );
               w_detrazione_acconto_d   := least(nvl(rec_ogco.imposta_dovuta_acconto,0)
                                                ,nvl(w_detrazione_acconto,0)
                                                );
               w_detrazione_rim    := w_detrazione_rim   - w_detrazione;
               w_detrazione_rim_d  := w_detrazione_rim_d - w_detrazione_d;
--
-- Aggiornamento Detrazioni e Imposte.
--
               update oggetti_imposta
                  set detrazione             = decode(nvl(detrazione,0) + w_detrazione
                                                     ,0,to_number(null)
                                                       ,nvl(detrazione,0) + w_detrazione
                                                     )
                     ,detrazione_acconto     = decode(nvl(detrazione_acconto,0) + w_detrazione_acconto
                                                     ,0,to_number(null)
                                                       ,nvl(detrazione_acconto,0) + w_detrazione_acconto
                                                     )
                     ,imposta                = imposta - w_detrazione
                     ,imposta_dovuta         = --decode(nvl(imposta_dovuta,0) - nvl(w_detrazione_d,0)
                                               --      ,0,to_number(null)
                                                       nvl(imposta_dovuta,0) - nvl(w_detrazione_d,0)
                                               --      )
                     ,imposta_acconto        = --decode(nvl(imposta_acconto,0) - nvl(w_detrazione_acconto,0)
                                               --      ,0,to_number(null)
                                                       nvl(imposta_acconto,0) - nvl(w_detrazione_acconto,0)
                                               --      )
                     ,imposta_dovuta_acconto = --decode(nvl(imposta_dovuta_acconto,0) - nvl(w_detrazione_acconto_d,0)
                                               --      ,0,to_number(null)
                                                       nvl(imposta_dovuta_acconto,0) - nvl(w_detrazione_acconto_d,0)
                                               --      )
                where oggetto_imposta        = rec_ogco.oggetto_imposta
               ;
--
-- Trattamento di eventuali Residui di Detrazione da "spalmare" sulle pertinenze.
--
      if w_detrazione_rim        > 0
      or w_detrazione_rim_d      > 0 then
         FOR rec_pert IN sel_pert (rec_ogco.cod_fiscale
                                ,rec_ogco.oggetto_pratica
                                  ,a_anno
                                  ,w_flag_pertinenze
                                  ,a_ravvedimento
                                  ,a_tipo_evento
                                  )
         LOOP
            w_detrazione             := least(nvl(rec_pert.imposta,0)
                                             ,nvl(w_detrazione_rim,0)
                                             );
            w_detrazione_d           := least(nvl(rec_pert.imposta_dovuta,0)
                                             ,nvl(w_detrazione_rim_d,0)
                                             );
            w_stringa                := F_DATO_RIOG(rec_pert.cod_fiscale
                                                     ,rec_pert.oggetto_pratica
                                                     ,a_anno
                                                     ,'PT'
                                                     );
            w_mesi_possesso            := to_number(substr(w_stringa,01,2));
            w_stringa                  := F_DATO_RIOG(rec_pert.cod_fiscale
                                                     ,rec_pert.oggetto_pratica
                                                     ,a_anno
                                                     ,'PA'
                                                     );
            w_mesi_possesso_1s         := to_number(substr(w_stringa,01,2));
            w_detrazione_acconto     := least(nvl(rec_pert.imposta_acconto,0)
                                             ,nvl(round(w_detrazione / w_mesi_possesso * w_mesi_possesso_1s,2),0)
                                             );
            w_detrazione_acconto_d   := least(nvl(rec_pert.imposta_dovuta_acconto,0)
                                             ,nvl(round(w_detrazione_d / w_mesi_possesso * w_mesi_possesso_1s,2),0)
                                             );
            w_detrazione_rim         := w_detrazione_rim        - w_detrazione;
            w_detrazione_rim_d       := w_detrazione_rim_d      - w_detrazione_d;
            update oggetti_imposta
               set detrazione             = decode(nvl(detrazione,0) + w_detrazione
                                                  ,0,to_number(null)
                                                    ,nvl(detrazione,0) + w_detrazione
                                                  )
                  ,detrazione_acconto     = decode(nvl(detrazione_acconto,0) + w_detrazione_acconto
                                                  ,0,to_number(null)
                                                    ,nvl(detrazione_acconto,0) + w_detrazione_acconto
                                                  )
                  ,imposta                = imposta - w_detrazione
                  ,imposta_dovuta         = --decode(nvl(imposta_dovuta,0) - nvl(w_detrazione_d,0)
                                            --      ,0,to_number(null)
                                                    nvl(imposta_dovuta,0) - nvl(w_detrazione_d,0)
                                            --      )
                  ,imposta_acconto        = --decode(nvl(imposta_acconto,0) - nvl(w_detrazione_acconto,0)
                                            --      ,0,to_number(null)
                                                    nvl(imposta_acconto,0) - nvl(w_detrazione_acconto,0)
                                            --      )
                  ,imposta_dovuta_acconto = --decode(nvl(imposta_dovuta_acconto,0) - nvl(w_detrazione_acconto_d,0)
                                            --      ,0,to_number(null)
                                                    nvl(imposta_dovuta_acconto,0) - nvl(w_detrazione_acconto_d,0)
                                            --      )
             where oggetto_imposta        = rec_pert.oggetto_imposta
            ;
         END LOOP;
      end if;
   END LOOP;
EXCEPTION
   WHEN FINE THEN null;
   WHEN ERRORE THEN
      ROLLBACK;
      RAISE_APPLICATION_ERROR(-20999,w_errore,true);
   WHEN OTHERS THEN
      ROLLBACK;
      RAISE_APPLICATION_ERROR(-20999,'Errore in Calcolo Detrazioni TASI Oggetto di '||w_cod_fiscale||' OGPR '||w_ogpr||' ('||SQLERRM||')');
END;
/* End Procedure: CALCOLO_DETRAZIONI_TASI_OGGE */
/

