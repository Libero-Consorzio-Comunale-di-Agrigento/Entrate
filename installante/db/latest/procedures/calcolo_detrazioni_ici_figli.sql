--liquibase formatted sql 
--changeset abrandolini:20250326_152423_calcolo_detrazioni_ici_figli stripComments:false runOnChange:true 
 
create or replace procedure CALCOLO_DETRAZIONI_ICI_FIGLI
/*************************************************************************
  NOME:        CALCOLO_DETRAZIONI_ICI_FIGLI
  DESCRIZIONE: Calcola le detrazioni ICI/IMU per figli a carico
  ANNOTAZIONI:
  REVISIONI:
  Rev.  Data        Autore  Descrizione
  ----  ----------  ------  ----------------------------------------------------
  004   07/10/2021  VD      Aggiunto parametro tipo_evento per gestione nuovi
                            ravvedimenti in acconto e a saldo
  003   21/11/2014  VD      Modificata distribuzione detrazioni
  002   17/11/2014  VD      Aggiunto campo WRK_CALCOLO per escludere oggetti
                            imposta già trattati.
  001   14/11/2014  VD      Modificata gestione detrazioni se la detrazione è
                            maggiore dell'imposta per il primo oggett.
**************************************************************************/
(a_cf           IN varchar2
,a_anno         IN number
,a_ravvedimento IN varchar2
,a_utente       IN varchar2
,a_tipo_evento  IN varchar2 default null
) is
errore                              exception;
fine                                exception;
w_errore                            varchar2(2000);
w_flag_pertinenze                   varchar2(1);
w_detrazione_max_figli              number;
w_tot_detrazione                    number;
w_tot_detrazione_acc                number;
w_tot_detrazione_d                  number;
w_tot_detrazione_acc_d              number;
w_detrazione                        number;
w_detrazione_acconto                number;
w_detrazione_d                      number;
w_detrazione_acconto_d              number;
w_cod_fiscale                       varchar2(16);
w_imposta_da_trattare               number;
w_imposta_da_trattare_d             number;
--w_impo_pert_acc                     number;
--w_impo_d_pert_acc                   number;
--w_detr_pertinenze                   number := 0;
--w_detr_pertinenze_d                 number := 0;
--w_ogim_pert1                        number := 0;
--w_ogim_pert2                        number := 0;
--
-- Selezione dei contribuenti su cui e` stata calcolata l`imposta ICI.
-- (sono quelli che hanno la data di sistema nella data di variazione
-- sugli oggetti imposta.
--
cursor sel_cf (p_cf                varchar2
              ,p_anno              number
              ,p_flag_pertinenze   varchar2
              ,p_ravvedimento      varchar2
              ,p_tipo_evento       varchar2
              )
is
select ogco.cod_fiscale            cod_fiscale
  from oggetti_contribuente        ogco
      ,oggetti_pratica             ogpr
      ,pratiche_tributo            prtr
      ,oggetti                     ogge
      ,oggetti_imposta             ogim
 where ogco.cod_fiscale            =    ogim.cod_fiscale
   and ogco.oggetto_pratica        =    ogim.oggetto_pratica
   and ogpr.oggetto_pratica        =    ogim.oggetto_pratica
   and prtr.pratica                =    ogpr.pratica
   and prtr.tipo_tributo||''       =    'ICI'
   and nvl(prtr.stato_accertamento,'D') = 'D'
   and ogge.oggetto                =    ogpr.oggetto
   and ogim.cod_fiscale         like    p_cf
   and ogim.anno                   =    p_anno
   and ogim.ruolo                 is    null
   and trunc(ogim.data_variazione) =    trunc(sysdate)
   and (  (  p_ravvedimento        =    'S'
        and prtr.tipo_evento       =    nvl(p_tipo_evento,prtr.tipo_evento)
        and prtr.tipo_pratica      =    'V'
        and not exists (select 'x'
                          from sanzioni_pratica sapr
                         where sapr.pratica = prtr.pratica)
          )
        or
          ( p_ravvedimento         =    'N'
        and prtr.tipo_pratica     in    ('D','A')
        and nvl(ogim.flag_calcolo,'N')     = 'S'
          )
       )
 group by
       ogco.cod_fiscale
 order by 1
;
--
-- Determinazione degli oggetti soggetti a detrazione sui quali spalmare
-- la detrazione figli
--
cursor sel_ogim (p_cf              varchar2
                ,p_anno            number
                ,p_flag_pertinenze varchar2
                ,p_ravvedimento    varchar2
                ,p_tipo_evento     varchar2
                )
is
select substr(F_DATO_RIOG(ogim.cod_fiscale
                         ,ogim.oggetto_pratica
                         ,ogim.anno
                         ,'CA'
                         )
             ,1,1)                 categoria_catasto
      ,decode(ogim.detrazione
             ,null,2
             ,1)                   detrazione_ogi
      ,ogco.oggetto_pratica        oggetto_pratica
      ,ogpr.oggetto                oggetto
      ,ogco.anno                   anno
      ,ogim.oggetto_imposta        oggetto_imposta
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
   and prtr.tipo_tributo||''          =    'ICI'
   and nvl(prtr.stato_accertamento,'D') = 'D'
   and ogge.oggetto                   =    ogpr.oggetto
   and ogim.cod_fiscale               =    p_cf
   and ogim.anno                      =    p_anno
   and ogim.ruolo                    is    null
   and trunc(ogim.data_variazione)    =    trunc(sysdate)
   and (  (  p_ravvedimento           =    'S'
        and prtr.tipo_pratica         =    'V'
        and prtr.tipo_evento          =    nvl(p_tipo_evento,prtr.tipo_evento)
        and not exists (select 'x'
                          from sanzioni_pratica sapr
                         where sapr.pratica = prtr.pratica)
           )
        or ( p_ravvedimento            =    'N'
        and prtr.tipo_pratica       in    ('D','A')
        and nvl(ogim.flag_calcolo,'N') =    'S'
           )
       )
   and ogim.tipo_aliquota = 2
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
 order by 1, 2, 3
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
         and tipo_tributo       = 'ICI'
      ;
   EXCEPTION
      WHEN NO_DATA_FOUND OR TOO_MANY_ROWS THEN
         w_flag_pertinenze := null;
   END;
--
-- Determinazione della detrazione MAX figli.
--
   BEGIN
      select detrazione_max_figli
        into w_detrazione_max_figli
        from detrazioni
       where anno               = a_anno
         and tipo_tributo       = 'ICI'
      ;
   EXCEPTION
      WHEN NO_DATA_FOUND OR TOO_MANY_ROWS THEN
         w_detrazione_max_figli := null;
   END;
--
-- Trattamento Contribuenti.
--
   FOR rec_cf IN sel_cf (a_cf,a_anno,w_flag_pertinenze,a_ravvedimento,a_tipo_evento)
   LOOP
      w_cod_fiscale         := rec_cf.cod_fiscale;
--
-- Dato un Contribuente, si determinano le Detrazioni Figli Totali da applicare.
--
      begin
         select sum(defi.detrazione)              detrazione
              , sum(defi.detrazione_acconto)      detrazione_acconto
           into w_tot_detrazione
              , w_tot_detrazione_acc
           from detrazioni_figli        defi
          where defi.cod_fiscale               =    w_cod_fiscale
            and defi.anno                      =    a_anno
              ;
      EXCEPTION
         WHEN NO_DATA_FOUND OR TOO_MANY_ROWS THEN
            w_tot_detrazione     := 0;
            w_tot_detrazione_acc := 0;
      end;
      if w_detrazione_max_figli is not null then
         if w_tot_detrazione > w_detrazione_max_figli then
            w_tot_detrazione := w_detrazione_max_figli;
         end if;
         if w_tot_detrazione_acc > w_detrazione_max_figli/2 then
            w_tot_detrazione_acc := w_detrazione_max_figli/2;
         end if;
      end if;
      w_tot_detrazione_d     := w_tot_detrazione;
      w_tot_detrazione_acc_d := w_tot_detrazione_acc;
--
-- Trattamento di Detrazione Figli in ACCONTO
--
      if w_tot_detrazione_acc   > 0 then
         FOR rec_ogim IN sel_ogim (w_cod_fiscale
                                  ,a_anno
                                  ,w_flag_pertinenze
                                  ,a_ravvedimento
                                  ,a_tipo_evento
                                  )
         LOOP
            w_detrazione_acconto     := least(nvl(rec_ogim.imposta,0)
                                             ,nvl(rec_ogim.imposta_acconto,0)
                                             ,nvl(w_tot_detrazione,0)
                                             ,nvl(w_tot_detrazione_acc,0)
                                             );
            w_detrazione_acconto_d   := least(nvl(rec_ogim.imposta_dovuta,0)
                                             ,nvl(rec_ogim.imposta_dovuta_acconto,0)
                                             ,nvl(w_tot_detrazione_d,0)
                                             ,nvl(w_tot_detrazione_acc_d,0)
                                             );
            w_tot_detrazione         := w_tot_detrazione        - w_detrazione_acconto;
            w_tot_detrazione_d       := w_tot_detrazione_d      - w_detrazione_acconto_d;
            w_tot_detrazione_acc     := w_tot_detrazione_acc    - w_detrazione_acconto;
            w_tot_detrazione_acc_d   := w_tot_detrazione_acc_d  - w_detrazione_acconto_d;
            update oggetti_imposta
               set detrazione             = decode(nvl(detrazione,0) + w_detrazione_acconto
                                                  ,0,to_number(null)
                                                  ,nvl(detrazione,0) + w_detrazione_acconto
                                                  )
                  ,detrazione_acconto     = decode(nvl(detrazione_acconto,0) + w_detrazione_acconto
                                                  ,0,to_number(null)
                                                  ,nvl(detrazione_acconto,0) + w_detrazione_acconto
                                                  )
                  ,detrazione_figli       = decode(nvl(detrazione_figli,0) + w_detrazione_acconto
                                                  ,0,to_number(null)
                                                  ,nvl(detrazione_figli,0) + w_detrazione_acconto
                                                  )
                  ,detrazione_figli_acconto =
                                            decode(nvl(detrazione_figli_acconto,0) + w_detrazione_acconto
                                                  ,0,to_number(null)
                                                  ,nvl(detrazione_figli_acconto,0) + w_detrazione_acconto
                                                  )
                  ,imposta                = imposta - w_detrazione_acconto
                  ,imposta_dovuta         = nvl(imposta_dovuta,0) - nvl(w_detrazione_acconto_d,0)
                  ,imposta_acconto        = nvl(imposta_acconto,0) - nvl(w_detrazione_acconto,0)
                  ,imposta_dovuta_acconto = nvl(imposta_dovuta_acconto,0) - nvl(w_detrazione_acconto_d,0)
                  ,wrk_calcolo            = 'IF'
             where oggetto_imposta        = rec_ogim.oggetto_imposta
            ;
          -- inserimento detrazioni_figli_ogim
             begin
               insert into detrazioni_figli_ogim
                      ( oggetto_imposta
                      , da_mese
                      , a_mese
                      , numero_figli
                      , detrazione
                      , detrazione_acconto
                      , utente
                      )
                 select rec_ogim.oggetto_imposta
                      , defi.da_mese
                      , defi.a_mese
                      , defi.numero_figli
                      , defi.detrazione
                      , defi.detrazione_acconto
                      , a_utente
                   from detrazioni_figli  defi
                  where defi.cod_fiscale = w_cod_fiscale
                    and defi.anno        = a_anno
                       ;
             exception
                when others then
                   w_errore := 'Errore inserimento detrazioni_figli_ogim '||w_cod_fiscale||' ('||SQLERRM||')';
                   raise errore;
             end;
         END LOOP;
      end if;
--
-- Trattamento di Detrazione Figli (SALDO)
--
      if w_tot_detrazione       > 0
      or w_tot_detrazione_acc   > 0 then
         FOR rec_ogim IN sel_ogim (w_cod_fiscale
                                  ,a_anno
                                  ,w_flag_pertinenze
                                  ,a_ravvedimento
                                  ,a_tipo_evento
                                  )
         LOOP
            w_detrazione             := least(nvl(rec_ogim.imposta,0) - nvl(rec_ogim.imposta_acconto,0)
                                             ,nvl(w_tot_detrazione,0)
                                             );
            w_detrazione_d           := least(nvl(rec_ogim.imposta_dovuta,0) - nvl(rec_ogim.imposta_dovuta_acconto,0)
                                             ,nvl(w_tot_detrazione_d,0)
                                             );
            w_detrazione_acconto     := least(nvl(rec_ogim.imposta_acconto,0)
                                             ,nvl(w_tot_detrazione_acc,0)
                                             ,w_detrazione
                                             );
            w_detrazione_acconto_d   := least(nvl(rec_ogim.imposta_dovuta_acconto,0)
                                             ,nvl(w_tot_detrazione_acc_d,0)
                                             ,w_detrazione_d
                                             );
            w_tot_detrazione         := w_tot_detrazione        - w_detrazione;
            w_tot_detrazione_d       := w_tot_detrazione_d      - w_detrazione_d;
            w_tot_detrazione_acc     := w_tot_detrazione_acc    - w_detrazione_acconto;
            w_tot_detrazione_acc_d   := w_tot_detrazione_acc_d  - w_detrazione_acconto_d;
            update oggetti_imposta
               set detrazione             = decode(nvl(detrazione,0) + w_detrazione
                                                  ,0,to_number(null)
                                                  ,nvl(detrazione,0) + w_detrazione
                                                  )
                  ,detrazione_acconto     = decode(nvl(detrazione_acconto,0) + w_detrazione_acconto
                                                  ,0,to_number(null)
                                                  ,nvl(detrazione_acconto,0) + w_detrazione_acconto
                                                  )
                  ,detrazione_figli       = decode(nvl(detrazione_figli,0) + w_detrazione
                                                  ,0,to_number(null)
                                                  ,nvl(detrazione_figli,0) + w_detrazione
                                                  )
                  ,detrazione_figli_acconto =
                                            decode(nvl(detrazione_figli_acconto,0) + w_detrazione_acconto
                                                  ,0,to_number(null)
                                                  ,nvl(detrazione_figli_acconto,0) + w_detrazione_acconto
                                                  )
                  ,imposta                = imposta - w_detrazione
                  ,imposta_dovuta         = nvl(imposta_dovuta,0) - nvl(w_detrazione_d,0)
                  ,imposta_acconto        = nvl(imposta_acconto,0) - nvl(w_detrazione_acconto,0)
                  ,imposta_dovuta_acconto = nvl(imposta_dovuta_acconto,0) - nvl(w_detrazione_acconto_d,0)
                  ,wrk_calcolo            = 'IF'
             where oggetto_imposta        = rec_ogim.oggetto_imposta
            ;
          -- inserimento detrazioni_figli_ogim
             begin
               insert into detrazioni_figli_ogim
                      ( oggetto_imposta
                      , da_mese
                      , a_mese
                      , numero_figli
                      , detrazione
                      , detrazione_acconto
                      , utente
                      )
                 select rec_ogim.oggetto_imposta
                      , defi.da_mese
                      , defi.a_mese
                      , defi.numero_figli
                      , defi.detrazione
                      , defi.detrazione_acconto
                      , a_utente
                   from detrazioni_figli  defi
                  where defi.cod_fiscale = w_cod_fiscale
                    and defi.anno        = a_anno
                    and not exists (select 'x' from detrazioni_figli_ogim defx
                                     where defx.oggetto_imposta = rec_ogim.oggetto_imposta
                                       and defx.da_mese = defi.da_mese)
                       ;
             exception
                when others then
                   w_errore := 'Errore inserimento detrazioni_figli_ogim '||w_cod_fiscale||' ('||SQLERRM||')';
                   raise errore;
             end;
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
      RAISE_APPLICATION_ERROR(-20999,'Errore in Calcolo Detrazioni ICI Figli di '||w_cod_fiscale||' ('||SQLERRM||')');
END;
/* End Procedure: CALCOLO_DETRAZIONI_ICI_FIGLI */
/

