--liquibase formatted sql 
--changeset abrandolini:20250326_152423_calcolo_liquidazioni_ici_nome stripComments:false runOnChange:true 
 
create or replace procedure CALCOLO_LIQUIDAZIONI_ICI_NOME
/*************************************************************************
 Rev.  Data          Autore    Descrizione
 4     20/09/2022    VM        #66699 - sostituito filtro ricerca sogg.cognome_nome
                               con sogg.cognome_nome_ric
 3     29/11/2016    VD        Inibito calcolo totali come somma degli
                               importi per tipologia oggetto
                               La sanzione per tardivo versamento in
                               acconto in presenza di eccedenza di versamento
                               a saldo e' stata spostata nella procedure
                               LIQUIDAZIONI_ICI_SANZ_VERS_711
 2     26/10/2016        VD    Versamento a saldo a parziale copertura
                               di acconto totalmente evaso: emessa
                               sanzione per parziale versamento al
                               posto di sanzione per omesso versamento
 1     18/10/2016        VD    Corretta gestione in caso di versamento
                               a saldo a parziale copertura dell'acconto
                               e acconto totalmente evaso
*************************************************************************/
(a_anno                 number,
 a_anno_rif             number, --MAI USATO
 a_data_liquidazione    date,
 a_data_rif_interessi   date,
 a_cod_fiscale          varchar2,
 a_nome                 varchar2,
 a_flag_riog            varchar2,
 a_da_data_riog         date,
 a_a_data_riog          date,
 a_da_perc_diff         number,
 a_a_perc_diff          number,
 a_importo_limite_inf   number,
 a_importo_limite_sup   number,
 a_ricalcolo            varchar2,
 a_utente               varchar2,
 a_flag_versamenti      varchar2,
 a_flag_rimborso        varchar2,
 a_flag_ravvedimenti    varchar2,
 a_cont_non_liq      IN OUT number)
IS
-- a_ricalcolo          varchar2(1) := NULL;
C_TIPO_TRIBUTO          CONSTANT varchar2(5) := 'ICI';
C_IMPO_EVASA_ACC        CONSTANT number := 1;
C_IMPO_EVASA_SAL        CONSTANT number := 21;
C_TARD_DEN_INF_30       CONSTANT number := 2;
C_TARD_DEN_SUP_30       CONSTANT number := 3;
C_OMESSO_VERS_ACC       CONSTANT number := 4;
C_OMESSO_VERS_SAL       CONSTANT number := 22;
C_PARZIALE_VERS_ACC     CONSTANT number := 5;
C_PARZIALE_VERS_SAL     CONSTANT number := 23;
C_ERRATO_CF             CONSTANT number := 11;
C_ERRATA_FIRMA          CONSTANT number := 12;
C_SPESE_NOT             CONSTANT number := 97;
C_NUOVO                 CONSTANT number := 100;
--C_TARD_VERS_ACC_INF_30   CONSTANT number := 6;  ***MAI USATO***
C_TARD_VERS_ACC_SUP_30  CONSTANT number := 7;
C_TARD_VERS_ACC_INF_15  CONSTANT number := 206;
C_TARD_VERS_ACC_INF_90  CONSTANT number := 207;
--C_TARD_VERS_ACC_SUP_90  CONSTANT number := 210;
errore                  exception;
w_errore                varchar2(2000);
w_diff_acconto          number;
w_diff_saldo            number;
w_diff_acc              number;
w_diff_sal              number;
w_cod_sanzione          number;
w_chkLiquida            number;
--w_controllo             varchar2(1); ***MAI USATO***
w_vers_cont             number;
w_vers_cont_acconto     number;
w_versamenti            number;
w_versamenti_acconto    number;
w_versamenti_saldo      number;
w_vers_ecc_saldo        number;
w_imp_dovuta            number;
w_imp_dovuta_acconto    number;
w_imp_dovuta_saldo      number;
w_imp_dovuta_dic        number;
w_imp_dovuta_acconto_dic number;
w_imp_dovuta_saldo_dic  number;
w_imp_appoggio          number;
w_imp_liq_new           number;
w_imp_liq_old           number;
w_pratica               number;
w_data_scad_acconto     date; --Data scadenza acconto
w_data_scad_saldo       date; --Data scadenza saldo
w_data_scad_denuncia    date;
w_data_rif_interessi    date;
w_imp_evasa_acconto     number;
w_imp_evasa_acconto_dic number;
w_imp_evasa_saldo       number;
w_imp_evasa_saldo_dic   number;
--w_cod_fiscale           varchar2(16); ***MAI USATO***
w_flag_firma            varchar2(1);
w_flag_cf               varchar2(1);
w_gg_pres_denuncia      number;
w_conto_corrente        number;
w_cont_non_liq          number;
w_fase_euro             number;
w_1000                  number;
w_5000                  number;
w_comune                number;  --Comune del cliente estrtatto da Dati Generali
w_provincia             number;  --Comune del cliente estrtatto da Dati Generali
w_data_pagamento_max_acc   date;
w_data_pagamento_max_sal   date;
w_versamenti_ravv       number;
w_versamenti_ravv_acc   number;
w_impo_cont             number;
w_impo_cont_acconto     number;
w_imp_dovuta_ab                number;
w_imp_dovuta_acconto_ab        number;
w_imp_dovuta_saldo_ab          number;
w_imp_dovuta_dic_ab            number;
w_imp_dovuta_acconto_dic_ab    number;
w_imp_dovuta_saldo_dic_ab      number;
w_imp_dovuta_ter               number;
w_imp_dovuta_acconto_ter       number;
w_imp_dovuta_saldo_ter         number;
w_imp_dovuta_dic_ter           number;
w_imp_dovuta_acconto_dic_ter   number;
w_imp_dovuta_saldo_dic_ter     number;
w_imp_dovuta_aree              number;
w_imp_dovuta_acconto_aree      number;
w_imp_dovuta_saldo_aree        number;
w_imp_dovuta_dic_aree          number;
w_imp_dovuta_acconto_dic_aree  number;
w_imp_dovuta_saldo_dic_aree    number;
w_imp_dovuta_altri             number;
w_imp_dovuta_acconto_altri     number;
w_imp_dovuta_saldo_altri       number;
w_imp_dovuta_dic_altri         number;
w_imp_dovuta_acconto_dic_altri number;
w_imp_dovuta_saldo_dic_altri   number;
w_imp_evasa_acconto_ab         number;
w_imp_evasa_acconto_ter        number;
w_imp_evasa_acconto_aree       number;
w_imp_evasa_acconto_altri      number;
w_imp_evasa_saldo_ab           number;
w_imp_evasa_saldo_ter          number;
w_imp_evasa_saldo_aree         number;
w_imp_evasa_saldo_altri        number;
w_imp_evasa_acconto_dic_ab     number;
w_imp_evasa_acconto_dic_ter    number;
w_imp_evasa_acconto_dic_aree   number;
w_imp_evasa_acconto_dic_altri  number;
w_imp_evasa_saldo_dic_ab       number;
w_imp_evasa_saldo_dic_ter      number;
w_imp_evasa_saldo_dic_aree     number;
w_imp_evasa_saldo_dic_altri    number;
w_versamenti_ab                number;
w_versamenti_acconto_ab        number;
w_versamenti_saldo_ab          number;
w_versamenti_ter               number;
w_versamenti_acconto_ter       number;
w_versamenti_saldo_ter         number;
w_versamenti_aree              number;
w_versamenti_acconto_aree      number;
w_versamenti_saldo_aree        number;
w_versamenti_altri             number;
w_versamenti_acconto_altri     number;
w_versamenti_saldo_altri       number;
--Contiene le pratiche non notificate se Ricalcolo del Dovuto è checkato
CURSOR sel_liq(p_anno number, p_cf varchar2, p_nome varchar2, p_ricalcolo varchar2) IS
select pratica
  from pratiche_tributo prtr
      ,contribuenti cont
      ,soggetti sogg
 where tipo_tributo          = 'ICI'
   and anno                  = p_anno
   and tipo_pratica       = 'L'
   and tipo_evento       = 'U'
   and data_notifica       is null
   and decode(p_ricalcolo,'S',NULL,numero)
                           is null
   and prtr.cod_fiscale       = cont.cod_fiscale
   and cont.ni                = sogg.ni
   and cont.cod_fiscale    like p_cf
   and sogg.cognome_nome_ric like p_nome
 order by 1
;
--Estrae: Codice Fiscale, Imposta Totale (Acconto + Saldo) ed Imposta Acconto
CURSOR sel_cont(p_anno number, p_cf varchar2, p_nome varchar2)
IS
select cont.cod_fiscale,
       sum(nvl(ogim.imposta,0)) impo_cont,
       sum(nvl(ogim.imposta_acconto,0)) impo_cont_acconto
  from oggetti_imposta   ogim,
       pratiche_tributo  prtr,
       oggetti_pratica   ogpr,
       soggetti      sogg,
       contribuenti   cont
 where prtr.tipo_tributo||''   = 'ICI'
   and prtr.pratica      = ogpr.pratica
   and nvl(prtr.stato_accertamento,'D') = 'D'
   and ogpr.oggetto_pratica   = ogim.oggetto_pratica
   and cont.ni         = sogg.ni
   and ogim.cod_fiscale      = cont.cod_fiscale
   and ogim.flag_calcolo      = 'S'
   and ogim.anno         = p_anno
   and sogg.cognome_nome_ric     like p_nome
   and cont.cod_fiscale          like p_cf
   and not exists
   (select 1
      from oggetti_pratica ogpr_liq, oggetti_contribuente ogco_liq, pratiche_tributo prtr_liq
     where ogco_liq.cod_fiscale   = ogim.cod_fiscale
       and ogpr_liq.oggetto_pratica   = ogco_liq.oggetto_pratica
       and ogpr_liq.oggetto      = ogpr.oggetto
       and prtr_liq.pratica      = ogpr_liq.pratica
       and prtr_liq.tipo_pratica      = 'L'
       and nvl(prtr_liq.stato_accertamento,'D') = 'D'
       and prtr_liq.tipo_tributo||''   = C_TIPO_TRIBUTO
       and prtr_liq.anno + 0      = p_anno
       and instr(p_cf,'%')         != 0
      )
   and(    a_flag_ravvedimenti = 'N'
       or  a_flag_ravvedimenti = 'S'
       and not exists
          (select 1
             from oggetti_imposta ogim_rav,oggetti_pratica ogpr_rav,pratiche_tributo prtr_rav
            where prtr_rav.pratica = ogpr_rav.pratica
              and ogpr_rav.oggetto_pratica = ogim_rav.oggetto_pratica
              and prtr_rav.tipo_tributo||'' = C_TIPO_TRIBUTO
              and prtr_rav.anno + 0 = p_anno
              and prtr_rav.tipo_pratica = 'V'
              and nvl(prtr_rav.stato_accertamento,'D') = 'D'
              and prtr_rav.numero is not null
              and ogim_rav.cod_fiscale = cont.cod_fiscale
          )
      )
 group by cont.cod_fiscale
 order by 1, 2
;
--DATA_SCADENZA_VERS
PROCEDURE data_scadenza_vers(p_anno IN number,p_tipo_trib IN varchar2,
                             p_tipo_vers IN varchar2,p_cod_fiscale IN varchar,
                             w_data_scad IN OUT date)
IS
BEGIN
   w_data_scad := f_scadenza(p_anno, p_tipo_trib, p_tipo_vers, p_cod_fiscale);
--   select data_scadenza
--     into w_data_scad
--     from scadenze
--    where anno      = p_anno
--   and tipo_tributo   = p_tipo_trib
--   and tipo_versamento   = p_tipo_vers
--   and tipo_scadenza   = 'V'
--   ;
     if w_data_scad is null THEN
        IF p_tipo_vers = 'A' THEN
        w_errore := 'Manca la data scadenza dell''acconto per l''anno indicato ('||SQLERRM||')';
        ELSE
        w_errore := 'Manca la data scadenza del saldo per l''anno indicato ('||SQLERRM||')';
        END IF;
        raise errore;
     end if;
EXCEPTION
     WHEN errore THEN RAISE;
--   WHEN no_data_found THEN
--     IF p_tipo_vers = 'A' THEN
--     w_errore := 'Manca la data scadenza dell''acconto per l''anno indicato ('||SQLERRM||')';
--     ELSE
--     w_errore := 'Manca la data scadenza del saldo per l''anno indicato ('||SQLERRM||')';
--     END IF;
--     RAISE errore;
 WHEN others THEN
      IF p_tipo_vers = 'A' THEN
      w_errore := 'Errore in ricerca Scadenze (Acconto) ('||SQLERRM||')';
      ELSE
      w_errore := 'Errore in ricerca Scadenze (Saldo) ('||SQLERRM||')';
      END IF;
      RAISE errore;
END data_scadenza_vers;
-- CALCOLO LIQUIDAZIONI ICI
BEGIN
  -- IMU  --
 if a_anno >= 2012 then
     CALCOLO_LIQUIDAZIONI_IMU
                  ( a_anno
                  , a_anno_rif
                  , a_data_liquidazione
                  , a_data_rif_interessi
                  , a_cod_fiscale
                  , a_nome
                  , a_flag_riog
                  , a_da_data_riog
                  , a_a_data_riog
                  , a_da_perc_diff
                  , a_a_perc_diff
                  , a_importo_limite_inf
                  , a_importo_limite_sup
                  , a_ricalcolo
                  , a_utente
                  , a_flag_versamenti
                  , a_flag_rimborso
                  , a_flag_ravvedimenti
                  , a_cont_non_liq);
 else
   -- ICI  --
  BEGIN
    select pro_cliente
        , com_cliente
      into w_provincia
         , w_comune
      from dati_generali
        ;
  EXCEPTION
    WHEN others THEN
        w_errore := 'Errore in estrazione comune e provincia in dati_generali ('||SQLERRM||')';
        RAISE errore;
  END;
  BEGIN
     select fase_euro
       into w_fase_euro
       from dati_generali
     ;
  EXCEPTION
     WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20999,'Mancano i Dati Generali');
  END;
  if w_fase_euro = 1 then
     --Lire
     w_1000  := 1000;
     w_5000  := 5000;
  else
     --Euro
     w_1000  := 1;
     w_5000  := 2.58;
  end if;
  a_cont_non_liq := 0;
--  data_scadenza_vers(a_anno,C_TIPO_TRIBUTO, 'A',w_data_scad_acconto);
--  data_scadenza_vers(a_anno,C_TIPO_TRIBUTO, 'S',w_data_scad_saldo);
-- Cancellazione tabella WRK_GENERALE
  begin
    delete wrk_generale
     where upper(tipo_trattamento) = 'LIQUIDAZIONE ICI'
         ;
  EXCEPTION
     WHEN others THEN
        w_errore := 'Errore in Eliminazione WRK_GENERALE ';
  end;
 -- INIZIO TRATTAMENTO STANDARD
  IF a_flag_riog is null THEN
    FOR rec_liq IN sel_liq(a_anno,a_cod_fiscale,a_nome,a_ricalcolo) LOOP
       --Cancella le pratiche non notificate da ricalcolare
       BEGIN
           delete pratiche_tributo
            where pratica = rec_liq.pratica
           ;
       EXCEPTION
           WHEN others THEN
           w_errore := 'Errore in Eliminazione Liquidazione (Pratica: '||rec_liq.pratica||')';
       END;
       COMMIT;
    END LOOP;
    --Estrazione del conto corrente su cui versare il dovuto
    BEGIN
       select conto_corrente into w_conto_corrente
       from tipi_tributo where tipo_tributo = 'ICI';
       EXCEPTION
          WHEN no_data_found THEN NULL;
          WHEN others THEN
            w_errore := 'Errore in ricerca Tipi Tributo ('||SQLERRM||')';
    END;
    FOR rec_cont IN sel_cont(a_anno,a_cod_fiscale,a_nome) LOOP
      data_scadenza_vers(a_anno,C_TIPO_TRIBUTO, 'A',rec_cont.cod_fiscale,w_data_scad_acconto);
      data_scadenza_vers(a_anno,C_TIPO_TRIBUTO, 'S',rec_cont.cod_fiscale,w_data_scad_saldo);
      IF F_IMPOSTA_CONT_ANNO_TITR(rec_cont.cod_fiscale,a_anno
                                  , C_TIPO_TRIBUTO
                                  , NULL
                                  , w_conto_corrente) IS NULL THEN
        a_cont_non_liq := a_cont_non_liq + 1;
        -- Gestione dei contribuenti non Liquidabili
        BEGIN
            insert into wrk_generale
                  (tipo_trattamento,anno,progressivo,dati)
            values ('LIQUIDAZIONE ICI',a_anno,to_number(to_char(sysdate,'yyyymmddhhMM'))*1000 + a_cont_non_liq,rec_cont.cod_fiscale)
            ;
        EXCEPTION
            WHEN others THEN
               w_errore := 'Errore in inserimento wrk_generale ('||SQLERRM||')';
               RAISE errore;
        END;
      ELSE
        BEGIN
          --Estrae l'importo versato totale e l'importo versato in acconto
          select nvl(sum(vers.importo_versato),0) importo_versato
               , nvl(sum(decode(vers.tipo_versamento
                               ,'A',vers.importo_versato
                               ,'U',vers.importo_versato
                                   ,decode(sign(vers.data_pagamento - w_data_scad_acconto)
                                          ,1,0
                                            ,vers.importo_versato
                                          )
                               )
                        ),0
                    ) importo_versato_acconto
            into w_vers_cont
                ,w_vers_cont_acconto
            from versamenti vers
           where vers.pratica          is null
             and vers.tipo_tributo||''  = 'ICI'
             and vers.cod_fiscale       = rec_cont.cod_fiscale
             and vers.anno              = a_anno
               ;
        EXCEPTION
           WHEN no_data_found THEN
                 w_vers_cont :=0;
                 w_vers_cont_acconto :=0;
               WHEN others THEN
                 w_errore := 'Errore in Calcolo Versamenti ('||SQLERRM||')';
              RAISE errore;
        END;
         -- Versamenti su ravvediemnto
        begin
           w_versamenti_ravv       := F_IMPORTO_VERS_RAVV(rec_cont.cod_fiscale,'ICI',a_anno,'U');
           w_versamenti_ravv_acc   := F_IMPORTO_VERS_RAVV(rec_cont.cod_fiscale,'ICI',a_anno,'A');
        end;
        if a_anno >= 2007 then
           w_impo_cont := round(rec_cont.impo_cont,0);
           w_impo_cont_acconto := round(rec_cont.impo_cont_acconto,0);
        else
           w_impo_cont := rec_cont.impo_cont;
           w_impo_cont_acconto := rec_cont.impo_cont_acconto;
        end if;
         w_chkLiquida := 0;
        IF w_1000 < abs( w_impo_cont - w_vers_cont - w_versamenti_ravv)
         OR w_1000 < abs( w_impo_cont_acconto - w_vers_cont_acconto - w_versamenti_ravv)
         THEN
           w_chkLiquida := 1;--Non è stato versato tutto
        ELSE
           BEGIN
                select 1 into w_chkLiquida--E' stato effettuato qualche versamento solo dopo la data di scadenza
                  from versamenti      vers
                 where vers.anno = a_anno
                   and vers.tipo_tributo   = 'ICI'
                   and vers.pratica is null
                   and vers.tipo_versamento in ('A','U','S')
                   and vers.cod_fiscale = rec_cont.cod_fiscale
                   and not exists
                   (select 1
                      from versamenti vers_sub
                     where vers_sub.anno      = vers.anno
                       and vers_sub.tipo_tributo   = vers.tipo_tributo
                       and vers_sub.cod_fiscale   = vers.cod_fiscale
                       and vers_sub.pratica      is null
                       and vers_sub.tipo_versamento   = vers.tipo_versamento
                       and vers_sub.data_pagamento   <= decode(vers.tipo_versamento
                                                              ,'S', w_data_scad_saldo, w_data_scad_acconto)
                   )
                ;
                RAISE too_many_rows;
           EXCEPTION
             WHEN no_data_found THEN
               w_chkLiquida := 0;
             WHEN too_many_rows THEN
               w_chkLiquida := 1;
             WHEN others THEN
               w_errore := 'Errore in ricerca Versamenti in Ritardo('||SQLERRM||')';
               RAISE errore;
           END;
           IF w_chkLiquida = 0 THEN
             BEGIN
                --Quando esiste una denuncia per l'anno in questione
                select 1 into w_chkLiquida
                  from dual
                      where exists
                                  (select 1
                                    from scadenze      scad,
                                         pratiche_tributo    prtr
                                   where scad.tipo_tributo   = prtr.tipo_tributo
                                     and scad.anno      = prtr.anno
                                     and scad.tipo_scadenza   = prtr.tipo_pratica
                                     and scad.data_scadenza   > prtr.data
                                     and prtr.tipo_tributo   = 'ICI'
                                     and prtr.tipo_pratica   = 'D'
                                     and prtr.anno      = a_anno
                                     and prtr.cod_fiscale   = rec_cont.cod_fiscale)
             ;
             EXCEPTION
                WHEN NO_DATA_FOUND THEN
                w_chkLiquida := 0;
                WHEN OTHERS THEN
                w_errore := 'Errore in ricerca Denuncie in ritardo ('||SQLERRM||')';
                RAISE errore;
             END;
           END IF; -- w_chkLiquida = 0
        END IF; -- w_1000 < abs( w_impo_cont - w_vers_cont - w_versamenti_ravv)
        IF w_chkLiquida = 1 THEN --Si esegue la liquidazione
            w_versamenti         := 0;
            w_versamenti_acconto := 0;
            w_versamenti_saldo   := 0;
            w_versamenti_ab            := 0;
            w_versamenti_acconto_ab    := 0;
            w_versamenti_saldo_ab      := 0;
            w_versamenti_ter           := 0;
            w_versamenti_acconto_ter   := 0;
            w_versamenti_saldo_ter     := 0;
            w_versamenti_aree          := 0;
            w_versamenti_acconto_aree  := 0;
            w_versamenti_saldo_aree    := 0;
            w_versamenti_altri         := 0;
            w_versamenti_acconto_altri := 0;
            w_versamenti_saldo_altri   := 0;
            w_imp_dovuta         := 0;
            w_imp_dovuta_acconto := 0;
            w_imp_dovuta_saldo   := 0;
            w_imp_dovuta_dic     := 0;
            w_imp_dovuta_acconto_dic := 0;
            w_imp_dovuta_saldo_dic   := 0;
            w_imp_evasa_acconto      := 0; --Non pagato
            w_imp_evasa_saldo        := 0; --Non pagato
            w_imp_evasa_acconto_dic  := 0;
            w_imp_evasa_saldo_dic    := 0;
            w_imp_dovuta_ab                   := 0;
            w_imp_dovuta_acconto_ab           := 0;
            w_imp_dovuta_saldo_ab             := 0;
            w_imp_dovuta_dic_ab               := 0;
            w_imp_dovuta_acconto_dic_ab       := 0;
            w_imp_dovuta_saldo_dic_ab         := 0;
            w_imp_dovuta_ter                  := 0;
            w_imp_dovuta_acconto_ter          := 0;
            w_imp_dovuta_saldo_ter            := 0;
            w_imp_dovuta_dic_ter              := 0;
            w_imp_dovuta_acconto_dic_ter      := 0;
            w_imp_dovuta_saldo_dic_ter        := 0;
            w_imp_dovuta_aree                 := 0;
            w_imp_dovuta_acconto_aree         := 0;
            w_imp_dovuta_saldo_aree           := 0;
            w_imp_dovuta_dic_aree             := 0;
            w_imp_dovuta_acconto_dic_aree     := 0;
            w_imp_dovuta_saldo_dic_aree       := 0;
            w_imp_dovuta_altri                := 0;
            w_imp_dovuta_acconto_altri        := 0;
            w_imp_dovuta_saldo_altri          := 0;
            w_imp_dovuta_dic_altri            := 0;
            w_imp_dovuta_acconto_dic_altri    := 0;
            w_imp_dovuta_saldo_dic_altri      := 0;
            w_imp_evasa_acconto_ab            := 0;
            w_imp_evasa_acconto_ter           := 0;
            w_imp_evasa_acconto_aree          := 0;
            w_imp_evasa_acconto_altri         := 0;
            w_imp_evasa_saldo_ab              := 0;
            w_imp_evasa_saldo_ter             := 0;
            w_imp_evasa_saldo_aree            := 0;
            w_imp_evasa_saldo_altri           := 0;
            w_imp_evasa_acconto_dic_ab        := 0;
            w_imp_evasa_acconto_dic_ter       := 0;
            w_imp_evasa_acconto_dic_aree      := 0;
            w_imp_evasa_acconto_dic_altri     := 0;
            w_imp_evasa_saldo_dic_ab          := 0;
            w_imp_evasa_saldo_dic_ter         := 0;
            w_imp_evasa_saldo_dic_aree        := 0;
            w_imp_evasa_saldo_dic_altri       := 0;
            w_gg_pres_denuncia   := 0; --prtr.data - w_data_scad_denuncia
            w_flag_cf            := '';
            w_flag_firma         := '';
            w_pratica            := NULL;  --Nr della pratica
            pratiche_tributo_nr(w_pratica); --Assegnazione Numero Progressivo
            --Totalizzazione dei versamenti e degli acconti
            BEGIN
               select nvl(sum(decode(versamenti.pratica
                                    ,null,versamenti.importo_versato
                                         ,0
                                    )
                              ),0
                          )
                      ,nvl(sum(decode(versamenti.pratica
                                     ,null,decode(versamenti.tipo_versamento
                                                 ,'A',versamenti.importo_versato
                                                 ,'U',versamenti.importo_versato
                                                     ,decode(sign(versamenti.data_pagamento -
                                                                  w_data_scad_acconto
                                                                 )
                                                                 ,1,0
                                                                   ,versamenti.importo_versato
                                                            )
                                                 ),0
                                     )
                              ),0
                          )
                    , max(decode(versamenti.pratica
                                ,null,decode(versamenti.tipo_versamento
                                            ,'A',versamenti.DATA_PAGAMENTO
                                            ,'U',versamenti.DATA_PAGAMENTO
                                            ,decode(sign(versamenti.data_pagamento - w_data_scad_acconto)
                                                   ,1,to_date('01011900','ddmmyyyy')
                                                   ,versamenti.DATA_PAGAMENTO
                                                   )
                                            )
                                ,decode(pratiche_tributo.tipo_pratica
                                       ,'V',decode(versamenti.tipo_versamento
                                            ,'S',versamenti.DATA_PAGAMENTO
                                            ,decode(sign(w_data_scad_acconto - versamenti.data_pagamento)
                                                   ,1,to_date('01011900','ddmmyyyy')
                                                   ,versamenti.DATA_PAGAMENTO
                                                   )
                                            )
                                        ,to_date('01011900','ddmmyyyy')
                                        )
                                )
                          )                               data_pagamento_max_acc
                    , max(decode(versamenti.pratica
                                ,null,decode(versamenti.tipo_versamento
                                            ,'S',versamenti.DATA_PAGAMENTO
                                            ,decode(sign(w_data_scad_acconto - versamenti.data_pagamento)
                                                   ,1,to_date('01011900','ddmmyyyy')
                                                   ,versamenti.DATA_PAGAMENTO
                                                   )
                                            )
                                ,decode(pratiche_tributo.tipo_pratica
                                       ,'V',decode(versamenti.tipo_versamento
                                            ,'S',versamenti.DATA_PAGAMENTO
                                            ,decode(sign(w_data_scad_acconto - versamenti.data_pagamento)
                                                   ,1,to_date('01011900','ddmmyyyy')
                                                   ,versamenti.DATA_PAGAMENTO
                                                   )
                                            )
                                        ,to_date('01011900','ddmmyyyy')
                                        )
                                )
                          )                                     data_pagamento_max
                      ,nvl(sum(decode(versamenti.pratica
                                    ,null,versamenti.ab_principale
                                         ,0
                                    )
                              ),0
                          )                                                     ab_principale
                      ,nvl(sum(decode(versamenti.pratica
                                     ,null,decode(versamenti.tipo_versamento
                                                 ,'A',versamenti.ab_principale
                                                 ,'U',versamenti.ab_principale
                                                     ,decode(sign(versamenti.data_pagamento -
                                                                  w_data_scad_acconto
                                                                 )
                                                                 ,1,0
                                                                   ,versamenti.ab_principale
                                                            )
                                                 ),0
                                     )
                              ),0
                          )                                                     ab_principale_acc
                      ,nvl(sum(decode(versamenti.pratica
                                    ,null,versamenti.terreni_agricoli
                                         ,0
                                    )
                              ),0
                          )                                                     terreni_agricoli
                      ,nvl(sum(decode(versamenti.pratica
                                     ,null,decode(versamenti.tipo_versamento
                                                 ,'A',versamenti.terreni_agricoli
                                                 ,'U',versamenti.terreni_agricoli
                                                     ,decode(sign(versamenti.data_pagamento -
                                                                  w_data_scad_acconto
                                                                 )
                                                                 ,1,0
                                                                   ,versamenti.terreni_agricoli
                                                            )
                                                 ),0
                                     )
                              ),0
                          )                                                     aree_fabbricabili_acc
                      ,nvl(sum(decode(versamenti.pratica
                                    ,null,versamenti.aree_fabbricabili
                                         ,0
                                    )
                              ),0
                          )                                                     aree_fabbricabili
                      ,nvl(sum(decode(versamenti.pratica
                                     ,null,decode(versamenti.tipo_versamento
                                                 ,'A',versamenti.aree_fabbricabili
                                                 ,'U',versamenti.aree_fabbricabili
                                                     ,decode(sign(versamenti.data_pagamento -
                                                                  w_data_scad_acconto
                                                                 )
                                                                 ,1,0
                                                                   ,versamenti.aree_fabbricabili
                                                            )
                                                 ),0
                                     )
                              ),0
                          )                                                     aree_fabbricabili_acc
                      ,nvl(sum(decode(versamenti.pratica
                                    ,null,versamenti.altri_fabbricati
                                         ,0
                                    )
                              ),0
                          )                                                     altri_fabbricati
                      ,nvl(sum(decode(versamenti.pratica
                                     ,null,decode(versamenti.tipo_versamento
                                                 ,'A',versamenti.altri_fabbricati
                                                 ,'U',versamenti.altri_fabbricati
                                                     ,decode(sign(versamenti.data_pagamento -
                                                                  w_data_scad_acconto
                                                                 )
                                                                 ,1,0
                                                                   ,versamenti.altri_fabbricati
                                                            )
                                                 ),0
                                     )
                              ),0
                          )                                                     altri_fabbricati_acc
                 into w_versamenti
                     ,w_versamenti_acconto
                     ,w_data_pagamento_max_acc
                     ,w_data_pagamento_max_sal
                     ,w_versamenti_ab
                     ,w_versamenti_acconto_ab
                     ,w_versamenti_ter
                     ,w_versamenti_acconto_ter
                     ,w_versamenti_aree
                     ,w_versamenti_acconto_aree
                     ,w_versamenti_altri
                     ,w_versamenti_acconto_altri
                 from versamenti
                    , pratiche_tributo
                where versamenti.anno         = a_anno
                  and versamenti.tipo_tributo = 'ICI'
                  and versamenti.cod_fiscale  = rec_cont.cod_fiscale
                  and pratiche_tributo.pratica (+) = versamenti.pratica
               ;
            EXCEPTION
              WHEN others THEN
                 w_errore := 'Errore in totalizzazione versamenti ('||SQLERRM||')';
                 RAISE errore;
            END;
        -- sommo ai totali dei versamenti i versamenti su ravvedimento
          w_versamenti          := w_versamenti + w_versamenti_ravv;
          w_versamenti_acconto  := w_versamenti_acconto + w_versamenti_ravv_acc;
          if w_comune = 40 and w_provincia = 36 then
              --Sassuolo: calcolo dell'imposta e dell'acconto dovuti e dichiarati diverso
             BEGIN
                 select f_round(sum(nvl(ogim.imposta, 0)),1)                            w_imp_dovuta2,
                        f_round(sum(nvl(ogim.imposta_acconto, 0)),1)                    w_imp_dovuta_acconto2,
                        f_round(sum(nvl(decode(ogpr.flag_provvisorio
                                              ,'S',ogim.imposta_dovuta,null)
                                              ,nvl(ogim.imposta,0))),1)                 w_imp_dovuta_dic2,
                        f_round(sum(nvl(decode(ogpr.flag_provvisorio
                                              ,'S',ogim.imposta_dovuta_acconto,null)
                                              ,nvl(ogim.imposta_acconto,0))),1)         w_imp_dovuta_acconto_dic2
                    into w_imp_dovuta,
                         w_imp_dovuta_acconto,
                         w_imp_dovuta_dic,
                         w_imp_dovuta_acconto_dic
                    from pratiche_tributo prtr,
                         oggetti_pratica ogpr,
                         oggetti_imposta ogim
                   where ogim.cod_fiscale         = rec_cont.cod_fiscale
                     and ogim.anno                = a_anno
                     and prtr.pratica             = ogpr.pratica
                     and ogim.oggetto_pratica     = ogpr.oggetto_pratica
                     and prtr.tipo_tributo||''        = 'ICI'
                     and ogim.flag_calcolo        = 'S'
                   ;
             EXCEPTION
                 WHEN others THEN
                   w_errore := 'Errore in totalizzazione imposta dovuta ('||SQLERRM||')';
                   RAISE errore;
             END;
          else
             BEGIN
                 select sum(nvl(ogim.imposta, 0))
                      , sum(nvl(ogim.imposta_acconto, 0))
                      , sum(nvl(decode(titr.flag_liq_riog
                                      ,'S',ogim.imposta
                                      ,decode(noog.anno_notifica
                                             ,null,ogim.imposta_dovuta
                                             ,ogim.imposta
                                             )
                                      )
                               ,0))
                      , sum(nvl(decode(titr.flag_liq_riog
                                      ,'S',ogim.imposta_acconto
                                      ,decode(noog.anno_notifica
                                             ,null,ogim.imposta_dovuta_acconto
                                             ,ogim.imposta_acconto
                                             )
                                      )
                               ,0))
               -- Abitazione Principale --
                      , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                  ,1,0
                                  ,2,0
                                  ,decode(ogco.flag_ab_principale||substr(ogpr.categoria_catasto,1,1)
                                         ,'SA',nvl(ogim.imposta, 0)
                                         ,0
                                         )
                                  )
                           )                                                    imp_dovuta_ab
                      , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                  ,1,0
                                  ,2,0
                                  ,decode(ogco.flag_ab_principale||substr(ogpr.categoria_catasto,1,1)
                                         ,'SA',nvl(ogim.imposta_acconto, 0)
                                         ,0
                                         )
                                  )
                           )                                                    imp_dovuta_acconto_ab
                      , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                  ,1,0
                                  ,2,0
                                  ,decode(ogco.flag_ab_principale||substr(ogpr.categoria_catasto,1,1)
                                         ,'SA',nvl(decode(titr.flag_liq_riog
                                                         ,'S',ogim.imposta
                                                         ,decode(noog.anno_notifica
                                                                ,null,ogim.imposta_dovuta
                                                                ,ogim.imposta
                                                                )
                                                         )
                                                  , 0)
                                         ,0
                                         )
                                  )
                           )                                                    imp_dovuta_dic_ab
                      , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                  ,1,0
                                  ,2,0
                                  ,decode(ogco.flag_ab_principale||substr(ogpr.categoria_catasto,1,1)
                                         ,'SA',nvl(decode(titr.flag_liq_riog
                                                         ,'S',ogim.imposta_acconto
                                                         ,decode(noog.anno_notifica
                                                                ,null,ogim.imposta_dovuta_acconto
                                                                ,ogim.imposta_acconto
                                                                )
                                                         )
                                              , 0)
                                         ,0
                                         )
                                  )
                           )                                                    imp_dovuta_acconto_dic_ab
               -- Terreni --
                      , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                  ,1,nvl(ogim.imposta, 0)
                                  ,0
                                  )
                           )                                                    imp_dovuta_ter
                      , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                  ,1,nvl(ogim.imposta_acconto, 0)
                                  ,0
                                  )
                           )                                                    imp_dovuta_acconto_ter
                      , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                  ,1,nvl(decode(titr.flag_liq_riog
                                               ,'S',ogim.imposta
                                               ,decode(noog.anno_notifica
                                                      ,null,ogim.imposta_dovuta
                                                      ,ogim.imposta
                                                      )
                                               )
                                        , 0)
                                  ,0
                                  )
                           )                                                    imp_dovuta_dic_ter
                      , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                  ,1,nvl(decode(titr.flag_liq_riog
                                               ,'S',ogim.imposta_acconto
                                               ,decode(noog.anno_notifica
                                                      ,null,ogim.imposta_dovuta_acconto
                                                      ,ogim.imposta_acconto
                                                      )
                                               )
                                        , 0)
                                  ,0
                                  )
                           )                                                    imp_dovuta_acconto_dic_ter
               -- Aree --
                      , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                  ,2,nvl(ogim.imposta, 0)
                                  ,0
                                  )
                           )                                                    imp_dovuta_aree
                      , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                  ,2,nvl(ogim.imposta_acconto, 0)
                                  ,0
                                  )
                           )                                                    imp_dovuta_acconto_aree
                      , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                  ,2,nvl(decode(titr.flag_liq_riog
                                               ,'S',ogim.imposta
                                               ,decode(noog.anno_notifica
                                                      ,null,ogim.imposta_dovuta
                                                      ,ogim.imposta
                                                      )
                                               )
                                        , 0)
                                  ,0
                                  )
                           )                                                    imp_dovuta_dic_aree
                      , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                  ,2,nvl(decode(titr.flag_liq_riog
                                               ,'S',ogim.imposta_acconto
                                               ,decode(noog.anno_notifica
                                                      ,null,ogim.imposta_dovuta_acconto
                                                      ,ogim.imposta_acconto
                                                      )
                                               )
                                        , 0)
                                  ,0
                                  )
                           )                                                    imp_dovuta_acconto_dic_aree
               -- Altri Fabbricati --
                      , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                  ,1,0
                                  ,2,0
                                  ,decode(ogco.flag_ab_principale||substr(ogpr.categoria_catasto,1,1)
                                         ,'SA',0
                                         ,nvl(ogim.imposta,0)
                                         )
                                  )
                           )                                                    imp_dovuta_altri
                      , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                  ,1,0
                                  ,2,0
                                  ,decode(ogco.flag_ab_principale||substr(ogpr.categoria_catasto,1,1)
                                         ,'SA',0
                                         ,nvl(ogim.imposta_acconto,0)
                                         )
                                  )
                           )                                                    imp_dovuta_acconto_altri
                      , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                  ,1,0
                                  ,2,0
                                  ,decode(ogco.flag_ab_principale||substr(ogpr.categoria_catasto,1,1)
                                         ,'SA',0
                                         ,nvl(decode(titr.flag_liq_riog
                                                    ,'S',ogim.imposta
                                                    ,decode(noog.anno_notifica
                                                           ,null,ogim.imposta_dovuta
                                                           ,ogim.imposta
                                                           )
                                                    )
                                             ,0)
                                         )
                                  )
                           )                                                    imp_dovuta_dic_altri
                      , sum(decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                                  ,1,0
                                  ,2,0
                                  ,decode(ogco.flag_ab_principale||substr(ogpr.categoria_catasto,1,1)
                                         ,'SA',0
                                         ,nvl(decode(titr.flag_liq_riog
                                                    ,'S',ogim.imposta_acconto
                                                    ,decode(noog.anno_notifica
                                                           ,null,ogim.imposta_dovuta_acconto
                                                           ,ogim.imposta_acconto
                                                           )
                                                    )
                                             ,0)
                                         )
                                  )
                           )                                                    imp_dovuta_acconto_dic_altri
                into w_imp_dovuta
                   , w_imp_dovuta_acconto
                   , w_imp_dovuta_dic
                   , w_imp_dovuta_acconto_dic
                   , w_imp_dovuta_ab
                   , w_imp_dovuta_acconto_ab
                   , w_imp_dovuta_dic_ab
                   , w_imp_dovuta_acconto_dic_ab
                   , w_imp_dovuta_ter
                   , w_imp_dovuta_acconto_ter
                   , w_imp_dovuta_dic_ter
                   , w_imp_dovuta_acconto_dic_ter
                   , w_imp_dovuta_aree
                   , w_imp_dovuta_acconto_aree
                   , w_imp_dovuta_dic_aree
                   , w_imp_dovuta_acconto_dic_aree
                   , w_imp_dovuta_altri
                   , w_imp_dovuta_acconto_altri
                   , w_imp_dovuta_dic_altri
                   , w_imp_dovuta_acconto_dic_altri
                from pratiche_tributo      prtr
                   , oggetti_pratica       ogpr
                   , oggetti_contribuente  ogco
                   , oggetti               ogge
                   , oggetti_imposta       ogim
                   , dati_generali         dage
                   , notifiche_oggetto     noog
                   , tipi_tributo          titr
               where ogim.cod_fiscale       = rec_cont.cod_fiscale
                 and ogim.anno              = a_anno
                 and prtr.pratica           = ogpr.pratica
                 and ogim.oggetto_pratica   = ogpr.oggetto_pratica
                 and ogim.oggetto_pratica   = ogco.oggetto_pratica
                 and ogim.cod_fiscale       = ogco.cod_fiscale
                 and ogpr.oggetto           = ogge.oggetto
                 and titr.tipo_tributo      = prtr.tipo_tributo
                 and prtr.tipo_tributo||''  = 'ICI'
                 and ogim.flag_calcolo      = 'S'
                 and noog.cod_fiscale (+)   = rec_cont.cod_fiscale
                 and noog.anno_notifica (+) < a_anno
                 and noog.oggetto (+)       = ogpr.oggetto
              group by dage.fase_euro
               ;
             EXCEPTION
               WHEN others THEN
                 w_errore := 'Errore in totalizzazione imposta dovuta ('||SQLERRM||')';
                 RAISE errore;
             END;
          end if;  --Sassuolo: calcolo dell'imposta e dell'acconto dovuti e dichiarati diverso
          --Inserimento dati in Pratiche Tributo e Rapporti Tributo
          BEGIN
               insert into pratiche_tributo
                     (pratica,cod_fiscale,tipo_tributo,anno,tipo_pratica,tipo_evento,data,
                      utente,data_variazione)
               values (w_pratica,rec_cont.cod_fiscale,'ICI',a_anno,
                      'L','U',trunc(a_data_liquidazione),a_utente,trunc(sysdate))
               ;
          EXCEPTION
               WHEN others THEN
                  w_errore := 'Errore in inserimento pratica ('||SQLERRM||')';
                  RAISE errore;
          END;
          BEGIN
               insert into rapporti_tributo(pratica,cod_fiscale)
               values (w_pratica,rec_cont.cod_fiscale);
          EXCEPTION
               WHEN others THEN
                    w_errore := 'Errore in inserimento rapporto ('||SQLERRM||')';
                 RAISE errore;
          END;
          w_cont_non_liq := a_cont_non_liq;
          LIQUIDAZIONI_ICI_RENDITA(a_anno, w_pratica, rec_cont.cod_fiscale
                     , w_imp_dovuta, w_imp_dovuta_acconto, w_imp_dovuta_dic, w_imp_dovuta_acconto_dic
                     , w_imp_dovuta_ab, w_imp_dovuta_acconto_ab, w_imp_dovuta_dic_ab, w_imp_dovuta_acconto_dic_ab
                     , w_imp_dovuta_ter, w_imp_dovuta_acconto_ter, w_imp_dovuta_dic_ter, w_imp_dovuta_acconto_dic_ter
                     , w_imp_dovuta_aree, w_imp_dovuta_acconto_aree, w_imp_dovuta_dic_aree, w_imp_dovuta_acconto_dic_aree
                     , w_imp_dovuta_altri, w_imp_dovuta_acconto_altri, w_imp_dovuta_dic_altri, w_imp_dovuta_acconto_dic_altri
                     , w_versamenti, w_versamenti_acconto, a_cont_non_liq, a_utente);
          -- Gestione Arrotondamenti
          if a_anno >= 2007 then
             w_imp_dovuta                   := round(w_imp_dovuta,0);
             w_imp_dovuta_acconto           := round(w_imp_dovuta_acconto,0);
             w_imp_dovuta_dic               := round(w_imp_dovuta_dic,0);
             w_imp_dovuta_acconto_dic       := round(w_imp_dovuta_acconto_dic,0);
             w_imp_dovuta_ab                := round(w_imp_dovuta_ab,0);
             w_imp_dovuta_acconto_ab        := round(w_imp_dovuta_acconto_ab,0);
             w_imp_dovuta_dic_ab            := round(w_imp_dovuta_dic_ab,0);
             w_imp_dovuta_acconto_dic_ab    := round(w_imp_dovuta_acconto_dic_ab,0);
             w_imp_dovuta_ter               := round(w_imp_dovuta_ter,0);
             w_imp_dovuta_acconto_ter       := round(w_imp_dovuta_acconto_ter,0);
             w_imp_dovuta_dic_ter           := round(w_imp_dovuta_dic_ter,0);
             w_imp_dovuta_acconto_dic_ter   := round(w_imp_dovuta_acconto_dic_ter,0);
             w_imp_dovuta_aree              := round(w_imp_dovuta_aree,0);
             w_imp_dovuta_acconto_aree      := round(w_imp_dovuta_acconto_aree,0);
             w_imp_dovuta_dic_aree          := round(w_imp_dovuta_dic_aree,0);
             w_imp_dovuta_acconto_dic_aree  := round(w_imp_dovuta_acconto_dic_aree,0);
             w_imp_dovuta_altri             := round(w_imp_dovuta_altri,0);
             w_imp_dovuta_acconto_altri     := round(w_imp_dovuta_acconto_altri,0);
             w_imp_dovuta_dic_altri         := round(w_imp_dovuta_dic_altri,0);
             w_imp_dovuta_acconto_dic_altri := round(w_imp_dovuta_acconto_dic_altri,0);
          end if;
            --Se nella LIQUIDAZIONI_ICI_RENDITA il numero di contribuenti la cui liquidazione
            --non è andata a buon fine non è cambiato
          IF w_cont_non_liq = a_cont_non_liq THEN
               w_imp_dovuta_saldo     := nvl(w_imp_dovuta,0) - nvl(w_imp_dovuta_acconto,0);
               w_imp_dovuta_saldo_dic := nvl(w_imp_dovuta_dic,0) - nvl(w_imp_dovuta_acconto_dic,0);
               w_versamenti_saldo     := nvl(w_versamenti,0) - nvl(w_versamenti_acconto,0);
               w_imp_dovuta_saldo_ab        := nvl(w_imp_dovuta_ab,0) - nvl(w_imp_dovuta_acconto_ab,0);
               w_imp_dovuta_saldo_dic_ab    := nvl(w_imp_dovuta_dic_ab,0) - nvl(w_imp_dovuta_acconto_dic_ab,0);
               w_versamenti_saldo_ab        := nvl(w_versamenti_ab,0) - nvl(w_versamenti_acconto_ab,0);
               w_imp_dovuta_saldo_ter       := nvl(w_imp_dovuta_ter,0) - nvl(w_imp_dovuta_acconto_ter,0);
               w_imp_dovuta_saldo_dic_ter   := nvl(w_imp_dovuta_dic_ter,0) - nvl(w_imp_dovuta_acconto_dic_ter,0);
               w_versamenti_saldo_ter       := nvl(w_versamenti_ter,0) - nvl(w_versamenti_acconto_ter,0);
               w_imp_dovuta_saldo_aree      := nvl(w_imp_dovuta_aree,0) - nvl(w_imp_dovuta_acconto_aree,0);
               w_imp_dovuta_saldo_dic_aree  := nvl(w_imp_dovuta_dic_aree,0) - nvl(w_imp_dovuta_acconto_dic_aree,0);
               w_versamenti_saldo_aree      := nvl(w_versamenti_aree,0) - nvl(w_versamenti_acconto_aree,0);
               w_imp_dovuta_saldo_altri     := nvl(w_imp_dovuta_altri,0) - nvl(w_imp_dovuta_acconto_altri,0);
               w_imp_dovuta_saldo_dic_altri := nvl(w_imp_dovuta_dic_altri,0) - nvl(w_imp_dovuta_acconto_dic_altri,0);
               w_versamenti_saldo_altri     := nvl(w_versamenti_altri,0) - nvl(w_versamenti_acconto_altri,0);
            IF w_versamenti_acconto >= w_imp_dovuta_acconto THEN
               IF w_versamenti_saldo >= w_imp_dovuta_saldo THEN
                    w_imp_evasa_acconto       := w_imp_dovuta_acconto - w_versamenti_acconto;
                    w_imp_evasa_saldo         := w_imp_dovuta_saldo - w_versamenti_saldo;
                    w_imp_evasa_acconto_ab    := w_imp_dovuta_acconto_ab - w_versamenti_acconto_ab;
                    w_imp_evasa_saldo_ab      := w_imp_dovuta_saldo_ab - w_versamenti_saldo_ab;
                    w_imp_evasa_acconto_ter   := w_imp_dovuta_acconto_ter - w_versamenti_acconto_ter;
                    w_imp_evasa_saldo_ter     := w_imp_dovuta_saldo_ter - w_versamenti_saldo_ter;
                    w_imp_evasa_acconto_aree  := w_imp_dovuta_acconto_aree - w_versamenti_acconto_aree;
                    w_imp_evasa_saldo_aree    := w_imp_dovuta_saldo_aree - w_versamenti_saldo_aree;
                    w_imp_evasa_acconto_altri := w_imp_dovuta_acconto_altri - w_versamenti_acconto_altri;
                    w_imp_evasa_saldo_altri   := w_imp_dovuta_saldo_altri - w_versamenti_saldo_altri;
               ELSIF w_versamenti >= w_imp_dovuta THEN
                    w_imp_evasa_acconto       := w_imp_dovuta - w_versamenti;
                    w_imp_evasa_saldo         := 0;
                    w_imp_evasa_acconto_ab    := w_imp_dovuta_ab - w_versamenti_ab;
                    w_imp_evasa_saldo_ab      := 0;
                    w_imp_evasa_acconto_ter   := w_imp_dovuta_ter - w_versamenti_ter;
                    w_imp_evasa_saldo_ter     := 0;
                    w_imp_evasa_acconto_aree  := w_imp_dovuta_aree - w_versamenti_aree;
                    w_imp_evasa_saldo_aree    := 0;
                    w_imp_evasa_acconto_altri := w_imp_dovuta_altri - w_versamenti_altri;
                    w_imp_evasa_saldo_altri   := 0;
               ELSE
                    w_imp_evasa_acconto       := 0;
                    w_imp_evasa_saldo         := w_imp_dovuta - w_versamenti;
                    w_imp_evasa_acconto_ab    := 0;
                    w_imp_evasa_saldo_ab      := w_imp_dovuta_ab - w_versamenti_ab;
                    w_imp_evasa_acconto_ter   := 0;
                    w_imp_evasa_saldo_ter     := w_imp_dovuta_ter - w_versamenti_ter;
                    w_imp_evasa_acconto_aree  := 0;
                    w_imp_evasa_saldo_aree    := w_imp_dovuta_aree - w_versamenti_aree;
                    w_imp_evasa_acconto_altri := 0;
                    w_imp_evasa_saldo_altri   := w_imp_dovuta_altri - w_versamenti_altri;
               END IF;
            ELSE
                IF w_versamenti_saldo < w_imp_dovuta_saldo THEN
                    w_imp_evasa_acconto       := w_imp_dovuta_acconto - w_versamenti_acconto;
                    w_imp_evasa_saldo         := w_imp_dovuta_saldo - w_versamenti_saldo;
                    w_imp_evasa_acconto_ab    := w_imp_dovuta_acconto_ab - w_versamenti_acconto_ab;
                    w_imp_evasa_saldo_ab      := w_imp_dovuta_saldo_ab - w_versamenti_saldo_ab;
                    w_imp_evasa_acconto_ter   := w_imp_dovuta_acconto_ter - w_versamenti_acconto_ter;
                    w_imp_evasa_saldo_ter     := w_imp_dovuta_saldo_ter - w_versamenti_saldo_ter;
                    w_imp_evasa_acconto_aree  := w_imp_dovuta_acconto_aree - w_versamenti_acconto_aree;
                    w_imp_evasa_saldo_aree    := w_imp_dovuta_saldo_aree - w_versamenti_saldo_aree;
                    w_imp_evasa_acconto_altri := w_imp_dovuta_acconto_altri - w_versamenti_acconto_altri;
                    w_imp_evasa_saldo_altri   := w_imp_dovuta_saldo_altri - w_versamenti_saldo_altri;
                ELSIF w_versamenti >= w_imp_dovuta THEN
                    w_imp_evasa_acconto       := 0;
                    w_imp_evasa_saldo         := w_imp_dovuta - w_versamenti;
                    w_imp_evasa_acconto_ab    := 0;
                    w_imp_evasa_saldo_ab      := w_imp_dovuta_ab - w_versamenti_ab;
                    w_imp_evasa_acconto_ter   := 0;
                    w_imp_evasa_saldo_ter     := w_imp_dovuta_ter - w_versamenti_ter;
                    w_imp_evasa_acconto_aree  := 0;
                    w_imp_evasa_saldo_aree    := w_imp_dovuta_aree - w_versamenti_aree;
                    w_imp_evasa_acconto_altri := 0;
                    w_imp_evasa_saldo_altri   := w_imp_dovuta_altri - w_versamenti_altri;
                ELSE
                    w_imp_evasa_acconto       := w_imp_dovuta - w_versamenti;
                    w_imp_evasa_saldo         := 0;
                    w_imp_evasa_acconto_ab    := w_imp_dovuta_ab - w_versamenti_ab;
                    w_imp_evasa_saldo_ab      := 0;
                    w_imp_evasa_acconto_ter   := w_imp_dovuta_ter - w_versamenti_ter;
                    w_imp_evasa_saldo_ter     := 0;
                    w_imp_evasa_acconto_aree  := w_imp_dovuta_aree - w_versamenti_aree;
                    w_imp_evasa_saldo_aree    := 0;
                    w_imp_evasa_acconto_altri := w_imp_dovuta_altri - w_versamenti_altri;
                    w_imp_evasa_saldo_altri   := 0;
                END IF;
            END IF;
            IF w_versamenti_acconto >= w_imp_dovuta_acconto_dic THEN
                IF w_versamenti_saldo >= w_imp_dovuta_saldo_dic THEN
                    w_imp_evasa_acconto_dic       := w_imp_dovuta_acconto_dic - w_versamenti_acconto;
                    w_imp_evasa_saldo_dic         := w_imp_dovuta_saldo_dic - w_versamenti_saldo;
                    w_imp_evasa_acconto_dic_ab    := w_imp_dovuta_acconto_dic_ab - w_versamenti_acconto_ab;
                    w_imp_evasa_saldo_dic_ab      := w_imp_dovuta_saldo_dic_ab - w_versamenti_saldo_ab;
                    w_imp_evasa_acconto_dic_ter   := w_imp_dovuta_acconto_dic_ter - w_versamenti_acconto_ter;
                    w_imp_evasa_saldo_dic_ter     := w_imp_dovuta_saldo_dic_ter - w_versamenti_saldo_ter;
                    w_imp_evasa_acconto_dic_aree  := w_imp_dovuta_acconto_dic_aree - w_versamenti_acconto_aree;
                    w_imp_evasa_saldo_dic_aree    := w_imp_dovuta_saldo_dic_aree - w_versamenti_saldo_aree;
                    w_imp_evasa_acconto_dic_altri := w_imp_dovuta_acconto_dic_altri - w_versamenti_acconto_altri;
                    w_imp_evasa_saldo_dic_altri   := w_imp_dovuta_saldo_dic_altri - w_versamenti_saldo_altri;
                ELSIF w_versamenti >= w_imp_dovuta_dic THEN
                       w_imp_evasa_acconto_dic := w_imp_dovuta_dic - w_versamenti;
                       w_imp_evasa_saldo_dic   := 0;
                       w_imp_evasa_acconto_dic_ab := w_imp_dovuta_dic_ab - w_versamenti_ab;
                       w_imp_evasa_saldo_dic_ab   := 0;
                       w_imp_evasa_acconto_dic_ter := w_imp_dovuta_dic_ter - w_versamenti_ter;
                       w_imp_evasa_saldo_dic_ter   := 0;
                       w_imp_evasa_acconto_dic_aree := w_imp_dovuta_dic_aree - w_versamenti_aree;
                       w_imp_evasa_saldo_dic_aree   := 0;
                       w_imp_evasa_acconto_dic_altri := w_imp_dovuta_dic_altri - w_versamenti_altri;
                       w_imp_evasa_saldo_dic_altri   := 0;
                ELSE
                       w_imp_evasa_acconto_dic       := 0;
                       w_imp_evasa_saldo_dic         := w_imp_dovuta_dic - w_versamenti;
                       w_imp_evasa_acconto_dic_ab    := 0;
                       w_imp_evasa_saldo_dic_ab      := w_imp_dovuta_dic_ab - w_versamenti_ab;
                       w_imp_evasa_acconto_dic_ter   := 0;
                       w_imp_evasa_saldo_dic_ter     := w_imp_dovuta_dic_ter - w_versamenti_ter;
                       w_imp_evasa_acconto_dic_aree  := 0;
                       w_imp_evasa_saldo_dic_aree    := w_imp_dovuta_dic_aree - w_versamenti_aree;
                       w_imp_evasa_acconto_dic_altri := 0;
                       w_imp_evasa_saldo_dic_altri   := w_imp_dovuta_dic_altri - w_versamenti_altri;
                END IF;
            ELSE
               IF w_versamenti_saldo < w_imp_dovuta_saldo_dic THEN
                   w_imp_evasa_acconto_dic       := w_imp_dovuta_acconto_dic - w_versamenti_acconto;
                   w_imp_evasa_saldo_dic         := w_imp_dovuta_saldo_dic - w_versamenti_saldo;
                   w_imp_evasa_acconto_dic_ab    := w_imp_dovuta_acconto_dic_ab - w_versamenti_acconto_ab;
                   w_imp_evasa_saldo_dic_ab      := w_imp_dovuta_saldo_dic_ab - w_versamenti_saldo_ab;
                   w_imp_evasa_acconto_dic_ter   := w_imp_dovuta_acconto_dic_ter - w_versamenti_acconto_ter;
                   w_imp_evasa_saldo_dic_ter     := w_imp_dovuta_saldo_dic_ter - w_versamenti_saldo_ter;
                   w_imp_evasa_acconto_dic_aree  := w_imp_dovuta_acconto_dic_aree - w_versamenti_acconto_aree;
                   w_imp_evasa_saldo_dic_aree    := w_imp_dovuta_saldo_dic_aree - w_versamenti_saldo_aree;
                   w_imp_evasa_acconto_dic_altri := w_imp_dovuta_acconto_dic_altri - w_versamenti_acconto_altri;
                   w_imp_evasa_saldo_dic_altri   := w_imp_dovuta_saldo_dic_altri - w_versamenti_saldo_altri;
               ELSIF w_versamenti >= w_imp_dovuta_dic THEN
                       w_imp_evasa_acconto_dic       := 0;
                       w_imp_evasa_saldo_dic         := w_imp_dovuta_dic - w_versamenti;
                       w_imp_evasa_acconto_dic_ab    := 0;
                       w_imp_evasa_saldo_dic_ab      := w_imp_dovuta_dic_ab - w_versamenti_ab;
                       w_imp_evasa_acconto_dic_ter   := 0;
                       w_imp_evasa_saldo_dic_ter     := w_imp_dovuta_dic_ter - w_versamenti_ter;
                       w_imp_evasa_acconto_dic_aree  := 0;
                       w_imp_evasa_saldo_dic_aree    := w_imp_dovuta_dic_aree - w_versamenti_aree;
                       w_imp_evasa_acconto_dic_altri := 0;
                       w_imp_evasa_saldo_dic_altri   := w_imp_dovuta_dic_altri - w_versamenti_altri;
               ELSE
                       w_imp_evasa_acconto_dic := w_imp_dovuta_dic - w_versamenti;
                       w_imp_evasa_saldo_dic   := 0;
                       w_imp_evasa_acconto_dic_ab := w_imp_dovuta_dic_ab - w_versamenti_ab;
                       w_imp_evasa_saldo_dic_ab   := 0;
                       w_imp_evasa_acconto_dic_ter := w_imp_dovuta_dic_ter - w_versamenti_ter;
                       w_imp_evasa_saldo_dic_ter   := 0;
                       w_imp_evasa_acconto_dic_aree := w_imp_dovuta_dic_aree - w_versamenti_aree;
                       w_imp_evasa_saldo_dic_aree   := 0;
                       w_imp_evasa_acconto_dic_altri := w_imp_dovuta_dic_altri - w_versamenti_altri;
                       w_imp_evasa_saldo_dic_altri   := 0;
               END IF;
            END IF;
            /*
               Gli interessi vengono calcolati sul dichiarato.
            Esempio di uso, ho una dichiarazione con in acconto da pagare 15 euro e a saldo 15 euro.
            Se faccio un versamento unico di 10 euro gli interessi vengono applicati su 5 euro per l'acconto e 15 euro per il saldo
            Se faccio un versamento unico di 20 euro gli interessi vengono applicati su 10 euro per il saldo
            Se faccio un versamento unico di 40 euro gli interessi a rimborso vengono applicati su 10 euro per l'acconto
            */
            IF w_imp_evasa_acconto != 0 and abs(w_imp_evasa_acconto + w_imp_evasa_saldo) > w_1000 THEN
              --  ANOMALIA 1 e 101
               w_cod_sanzione := C_IMPO_EVASA_ACC;
               inserimento_sanzione_liq(w_cod_sanzione,C_TIPO_TRIBUTO
                                       ,w_pratica,NULL
                                       ,NULL,w_imp_evasa_acconto
                                       ,w_imp_evasa_acconto_ab,w_imp_evasa_acconto_ter
                                       ,w_imp_evasa_acconto_aree,w_imp_evasa_acconto_altri
                                       ,a_utente);
               w_cod_sanzione := w_cod_sanzione + C_NUOVO;
               inserimento_sanzione_liq(w_cod_sanzione,C_TIPO_TRIBUTO
                                       ,w_pratica,NULL
                                       ,NULL,w_imp_evasa_acconto
                                       ,w_imp_evasa_acconto_ab,w_imp_evasa_acconto_ter
                                       ,w_imp_evasa_acconto_aree,w_imp_evasa_acconto_altri
                                       ,a_utente);
               w_diff_acc := w_imp_dovuta_acconto_dic - w_versamenti_acconto;
               IF w_imp_evasa_saldo_dic = 0 THEN
                  w_diff_acc := w_imp_dovuta_acconto_dic + w_imp_dovuta_saldo_dic - w_versamenti;
               END IF;
               IF w_diff_acc <> 0 and w_imp_evasa_acconto_dic <> 0 THEN
                  IF  abs(w_imp_dovuta_dic - w_versamenti) > w_5000
                    AND w_imp_dovuta_dic <> w_imp_dovuta
                     OR  w_imp_dovuta_dic = w_imp_dovuta   THEN
                       IF w_diff_acc > 0 THEN
                          IF w_versamenti_acconto >= 0 THEN
                             inserimento_interessi(w_pratica,NULL,w_data_scad_acconto,a_data_rif_interessi,w_diff_acc,C_TIPO_TRIBUTO,'A',a_utente);
                          ELSE
                             inserimento_interessi(w_pratica,NULL,w_data_scad_saldo,a_data_rif_interessi,w_diff_acc,C_TIPO_TRIBUTO,'A',a_utente);
                          END IF;
                       ELSE
                          inserimento_interessi(w_pratica,NULL,w_data_pagamento_max_acc,a_data_rif_interessi,w_diff_acc,C_TIPO_TRIBUTO,'A',a_utente);
                       END IF;
                  END IF;
               END IF;
               IF w_imp_dovuta  < w_imp_dovuta_dic THEN
                  -- IF a_data_rif_interessi >= to_date('01012000','ddmmyyyy') THEN
                  --     w_data_rif_interessi := to_date('31121999','ddmmyyyy') ;
                  --  ELSE
                  w_data_rif_interessi := a_data_rif_interessi;
                  --   END IF;
                  IF a_flag_rimborso = 'S' then -- 10/05/2001
                      if w_imp_evasa_saldo = 0 and w_versamenti_saldo = 0 then
                         -- inserisco l'interesse a rimborso per accorto + saldo (versamento unico)
                         inserimento_interessi(w_pratica,NULL,w_data_scad_acconto,w_data_rif_interessi,w_imp_dovuta - w_imp_dovuta_dic,C_TIPO_TRIBUTO,'A',a_utente);
                      else
                         -- inserisco l'interesse a rimborso per l'acconto
                         inserimento_interessi(w_pratica,NULL,w_data_scad_acconto,w_data_rif_interessi,w_imp_dovuta_acconto - w_imp_dovuta_acconto_dic,C_TIPO_TRIBUTO,'A',a_utente);
                      end if;
                  END IF;
               END IF;
            END IF;
            IF w_imp_evasa_saldo != 0 and abs(w_imp_evasa_acconto + w_imp_evasa_saldo) > w_1000 THEN   -- ANOMALIA 21 e 121
              w_cod_sanzione := C_IMPO_EVASA_SAL;
              inserimento_sanzione_liq(w_cod_sanzione,C_TIPO_TRIBUTO
                                      ,w_pratica,NULL
                                      ,NULL,w_imp_evasa_saldo
                                       ,w_imp_evasa_saldo_ab,w_imp_evasa_saldo_ter
                                       ,w_imp_evasa_saldo_aree,w_imp_evasa_saldo_altri
                                      ,a_utente);
              w_cod_sanzione := w_cod_sanzione + C_NUOVO;
              inserimento_sanzione_liq(w_cod_sanzione,C_TIPO_TRIBUTO
                                      ,w_pratica,NULL
                                      ,NULL,w_imp_evasa_saldo
                                      ,w_imp_evasa_saldo_ab,w_imp_evasa_saldo_ter
                                      ,w_imp_evasa_saldo_aree,w_imp_evasa_saldo_altri
                                      ,a_utente);
              w_diff_sal := (w_imp_dovuta_dic - w_imp_dovuta_acconto_dic) - (w_versamenti - w_versamenti_acconto);
              IF w_imp_evasa_acconto_dic = 0 THEN
                 w_diff_sal := w_imp_dovuta_acconto_dic + w_imp_dovuta_saldo_dic - w_versamenti;
              END IF;
              IF  abs(w_imp_dovuta_dic - w_versamenti) > w_5000
                AND w_imp_dovuta_dic <> w_imp_dovuta
                OR  w_imp_dovuta_dic = w_imp_dovuta   THEN
                  IF w_diff_sal > 0 THEN
                     IF w_diff_sal <> 0 and w_imp_evasa_saldo_dic <> 0 THEN
                        inserimento_interessi(w_pratica,NULL,w_data_scad_saldo,a_data_rif_interessi,w_diff_sal,C_TIPO_TRIBUTO,'S',a_utente);
                     END IF;
                  ELSE
                     inserimento_interessi(w_pratica,NULL,w_data_pagamento_max_sal,a_data_rif_interessi,w_diff_sal,C_TIPO_TRIBUTO,'S',a_utente);
                  END IF;
              END IF;
              IF w_imp_dovuta  < w_imp_dovuta_dic THEN
                 --  IF a_data_rif_interessi >= to_date('01012000','ddmmyyyy') THEN
                 --  w_data_rif_interessi := to_date('31121999','ddmmyyyy') ;
                 -- ELSE
                 w_data_rif_interessi := a_data_rif_interessi;
                 --  END IF;
                 IF a_flag_rimborso = 'S' then -- 10/05/2001
                   inserimento_interessi(w_pratica,NULL,w_data_scad_saldo,w_data_rif_interessi,(w_imp_dovuta - w_imp_dovuta_acconto) - (w_imp_dovuta_dic - w_imp_dovuta_acconto_dic),C_TIPO_TRIBUTO,'S',a_utente);
                 END IF;
              END IF;
            END IF;
            w_data_scad_denuncia := F_SCADENZA_DENUNCIA(C_TIPO_TRIBUTO,a_anno);
            IF w_data_scad_denuncia is NULL THEN
              w_errore := 'Errore in ricerca Scadenze (Denuncia) ('||SQLERRM||')';
              RAISE errore;
            ELSE
              BEGIN
                select prtr.data - w_data_scad_denuncia,deic.flag_cf, deic.flag_firma
                  into w_gg_pres_denuncia,w_flag_cf,w_flag_firma
                  from denunce_ici deic,pratiche_tributo prtr
                 where prtr.pratica      = deic.pratica (+)
                  and prtr.tipo_tributo = 'ICI'
                  and prtr.cod_fiscale  = rec_cont.cod_fiscale
                  and prtr.anno         = a_anno
                  and prtr.tipo_pratica = 'D'
               ;
               RAISE too_many_rows;
              EXCEPTION
               WHEN no_data_found THEN null;
                  WHEN too_many_rows THEN
                IF w_flag_cf = 'S' THEN      -- ANOMALIA 11 e 111
                    w_cod_sanzione := C_ERRATO_CF;
                    inserimento_sanzione(w_cod_sanzione,C_TIPO_TRIBUTO,w_pratica,NULL,NULL,NULL,a_utente);
                    w_cod_sanzione := w_cod_sanzione + C_NUOVO;
                    inserimento_sanzione(w_cod_sanzione,C_TIPO_TRIBUTO,w_pratica,NULL,NULL,NULL,a_utente);
                 END IF;
                 IF w_flag_firma = 'S' THEN   -- ANOMALIA 12 E 112
                    w_cod_sanzione := C_ERRATA_FIRMA;
                    inserimento_sanzione(w_cod_sanzione,C_TIPO_TRIBUTO,w_pratica,NULL,NULL,NULL,a_utente);
                    w_cod_sanzione := w_cod_sanzione + C_NUOVO;
                    inserimento_sanzione(w_cod_sanzione,C_TIPO_TRIBUTO,w_pratica,NULL,NULL,NULL,a_utente);
                 END IF;
                 IF w_gg_pres_denuncia between 1 and 30 THEN   -- ANOMALIA 2 e 102
                    w_cod_sanzione := C_TARD_DEN_INF_30;
                    inserimento_sanzione(w_cod_sanzione,C_TIPO_TRIBUTO,w_pratica,NULL,w_imp_dovuta,NULL,a_utente);
                    w_cod_sanzione := w_cod_sanzione + C_NUOVO;
                    inserimento_sanzione(w_cod_sanzione,C_TIPO_TRIBUTO,w_pratica,NULL,w_imp_dovuta,NULL,a_utente);
                 ELSIF w_gg_pres_denuncia > 30 THEN       -- ANOMALIA 3 e 103
                    w_cod_sanzione := C_TARD_DEN_SUP_30;
                    inserimento_sanzione(w_cod_sanzione,C_TIPO_TRIBUTO,w_pratica,NULL,w_imp_dovuta,NULL,a_utente);
                    w_cod_sanzione := w_cod_sanzione + C_NUOVO;
                    inserimento_sanzione(w_cod_sanzione,C_TIPO_TRIBUTO,w_pratica,NULL,w_imp_dovuta,NULL,a_utente);
                 END IF;
               WHEN others THEN
                 w_errore := 'Errore in controllo presentazione denuncia ('||SQLERRM||')';
                 RAISE errore;
              END;
            END IF; -- w_data_scad_denuncia is NULL
            IF w_imp_dovuta_dic > 0 THEN  -- Se dichiarato = 0 non esistono sanzioni su i Versamenti
               if a_data_liquidazione < to_date('06072011','ddmmyyyy') then
                  LIQUIDAZIONI_ICI_SANZ_VERS
                    (a_anno, w_pratica, rec_cont.cod_fiscale, w_data_scad_acconto, w_data_scad_saldo,
                     w_imp_dovuta_acconto, w_imp_dovuta_saldo, a_utente);
               else
                  LIQUIDAZIONI_ICI_SANZ_VERS_711
                    (a_anno, w_pratica, rec_cont.cod_fiscale, w_data_scad_acconto, w_data_scad_saldo,
                     w_imp_dovuta_acconto, w_imp_dovuta_saldo, a_utente);
               end if;
               -- Si usa w_imp_dovuta invece della w_imp_dovuta_dic se la prima e' minore
               -- della seconda, cio' accade in seguito ad una svalutazione dell'immobile
               IF w_imp_dovuta_acconto < w_imp_dovuta_acconto_dic THEN
                  w_imp_appoggio := w_imp_dovuta_acconto;
               ELSE
                  w_imp_appoggio := w_imp_dovuta_acconto_dic;
               END IF;
              w_diff_acconto   := w_imp_appoggio - w_versamenti_acconto;
              w_vers_ecc_saldo := w_versamenti_saldo - least(w_imp_dovuta_saldo_dic,w_imp_dovuta_saldo);
              w_vers_ecc_saldo := least(w_vers_ecc_saldo,w_diff_acconto);
              IF nvl(w_imp_appoggio,0) != 0 AND w_diff_acconto > 0 THEN
                if w_vers_ecc_saldo > 0 THEN
                -- La sanzione seguente viene inserita nel caso si abbia un versamento a saldo in eccedenza,,
                -- che va a coprire un eventuale imposta di acconto non pagata
                      if a_data_liquidazione < to_date('06072011','ddmmyyyy') then
                      -- ANOMALIA 7 e 107
                         w_cod_sanzione := C_TARD_VERS_ACC_SUP_30;
                         inserimento_sanzione_ici(w_cod_sanzione,C_TIPO_TRIBUTO,w_pratica,w_vers_ecc_saldo,a_utente);
                         w_cod_sanzione := w_cod_sanzione + C_NUOVO;
                         inserimento_sanzione_ici(w_cod_sanzione,C_TIPO_TRIBUTO,w_pratica,w_vers_ecc_saldo,a_utente);
                      /*else
                         --
                         -- (VD - 12/10/2016): occorre definire i giorni di ritardo rispetto all'acconto,
                         --                    perche dal 2016 cambia la percentuale e quindi il codice sanzione
                         --                    Corretta anche gestione tardivi versamenti per anni < 2016:
                         --                    in questo caso non gestiva gli scaglioni di giorni di ritardo
                         --
                         -- (VD - 29/11/2016): la gestione del versamento a saldo in
                         --                    eccedenza viene effettuata nella
                         --                    LIQUIDAZIONI_ICI_SANZ_VERS_711;
                         --                    rimane per le date anteriori al 6/7/2011
                         --
                         if a_data_liquidazione >= to_date('01012016','ddmmyyyy') then
                            if (w_data_pagamento_max_sal - w_data_scad_acconto) > 90 then
                               w_cod_sanzione := C_TARD_VERS_ACC_SUP_90; -- Anomalia 210
                            elsif (w_data_pagamento_max_sal - w_data_scad_acconto) > 15 then
                               w_cod_sanzione := C_TARD_VERS_ACC_INF_90; -- Anomalia 207
                            else
                               w_cod_sanzione := C_TARD_VERS_ACC_INF_15; -- Anomalia 206
                            end if;
                         else
                            if (w_data_pagamento_max_sal - w_data_scad_acconto) > 15 then
                               w_cod_sanzione := C_TARD_VERS_ACC_INF_90; -- Anomalia 207
                            else
                               w_cod_sanzione := C_TARD_VERS_ACC_INF_15; -- Anomalia 206
                            end if;
                         end if;
                         --w_cod_sanzione := 207;
                         inserimento_sanzione_ici(w_cod_sanzione,C_TIPO_TRIBUTO,w_pratica,w_vers_ecc_saldo,a_utente); */
                      end if;
                else
                   w_vers_ecc_saldo := 0;
                end if;
                --
                -- (VD - 12/10/2016): si detrae il versamento in eccedenza a
                --                    saldo dall'acconto residuo da pagare,
                --                    altrimenti il residuo acconto risulta
                --                    sempre uguale all'acconto totale
                --                    (w_imp_appoggio)
                --
                w_diff_acconto := w_diff_acconto - w_vers_ecc_saldo;
                IF  abs(least(w_imp_dovuta_dic,w_imp_dovuta) - w_versamenti) > w_5000 THEN
                   IF w_diff_acconto = w_imp_appoggio THEN   -- ANOMALIA 4 e 104
                      --
                      -- (VD - 26/10/2016): la sanzione viene calcolata sull'acconto evaso
                      --
                      w_cod_sanzione := C_OMESSO_VERS_ACC;
                      --inserimento_sanzione(w_cod_sanzione,C_TIPO_TRIBUTO,w_pratica,NULL,w_diff_acconto - w_vers_ecc_saldo,NULL,a_utente);
                      inserimento_sanzione(w_cod_sanzione,C_TIPO_TRIBUTO,w_pratica,NULL,w_diff_acconto,NULL,a_utente);
                      w_cod_sanzione := w_cod_sanzione + C_NUOVO;
                      --inserimento_sanzione(w_cod_sanzione,C_TIPO_TRIBUTO,w_pratica,NULL,w_diff_acconto - w_vers_ecc_saldo,NULL,a_utente);
                      inserimento_sanzione(w_cod_sanzione,C_TIPO_TRIBUTO,w_pratica,NULL,w_diff_acconto,NULL,a_utente);
                   ELSIF (w_imp_evasa_acconto + w_imp_evasa_saldo) > w_1000 THEN   -- ANOMALIA 5 e 105
                      --
                      -- (VD - 26/10/2016): la sanzione viene calcolata sull'acconto evaso
                      --
                      w_cod_sanzione := C_PARZIALE_VERS_ACC;
                      --inserimento_sanzione(w_cod_sanzione,C_TIPO_TRIBUTO,w_pratica, NULL, w_diff_acconto - w_vers_ecc_saldo, NULL, a_utente );
                      inserimento_sanzione(w_cod_sanzione,C_TIPO_TRIBUTO,w_pratica, NULL, w_diff_acconto, NULL, a_utente );
                      w_cod_sanzione := w_cod_sanzione + C_NUOVO;
                      --inserimento_sanzione(w_cod_sanzione,C_TIPO_TRIBUTO,w_pratica, NULL, w_diff_acconto - w_vers_ecc_saldo, NULL, a_utente);
                      inserimento_sanzione(w_cod_sanzione,C_TIPO_TRIBUTO,w_pratica, NULL, w_diff_acconto, NULL, a_utente );
                   END IF;
                END IF;
              END IF;
              IF w_imp_dovuta_saldo < w_imp_dovuta_saldo_dic THEN
                w_imp_appoggio := w_imp_dovuta_saldo;
              ELSE
                w_imp_appoggio := w_imp_dovuta_saldo_dic;
              END IF;
              w_diff_saldo := w_imp_appoggio - w_versamenti_saldo;
              if w_diff_acconto < 0 then
                 w_diff_saldo := w_diff_saldo + w_diff_acconto;
              end if;
              IF w_diff_saldo != 0 THEN
                 IF  abs(least(w_imp_dovuta_dic,w_imp_dovuta) - w_versamenti) > w_5000
                 AND w_imp_dovuta_dic <> w_imp_dovuta
                 OR  w_imp_dovuta_dic = w_imp_dovuta   THEN
                  IF w_diff_saldo > 0 AND w_versamenti_saldo = 0 and (w_imp_evasa_acconto + w_imp_evasa_saldo) > w_1000 THEN  -- ANOMALIA 22 e 122
                    w_cod_sanzione := C_OMESSO_VERS_SAL;
                   inserimento_sanzione(w_cod_sanzione,C_TIPO_TRIBUTO,w_pratica,NULL,w_diff_saldo,NULL,a_utente);
                   w_cod_sanzione := w_cod_sanzione + C_NUOVO;
                   inserimento_sanzione(w_cod_sanzione,C_TIPO_TRIBUTO,w_pratica,NULL,w_diff_saldo,NULL,a_utente);
                  ELSIF w_imp_appoggio != 0 AND w_versamenti_saldo != 0 AND w_diff_saldo > 0 and  (w_imp_evasa_acconto + w_imp_evasa_saldo) > w_1000  THEN   -- ANOMALIA 23 e 123
                   w_cod_sanzione := C_PARZIALE_VERS_SAL;
                   inserimento_sanzione_ici(w_cod_sanzione,C_TIPO_TRIBUTO,w_pratica,w_diff_saldo,a_utente);
                   w_cod_sanzione := w_cod_sanzione + C_NUOVO;
                   inserimento_sanzione_ici(w_cod_sanzione,C_TIPO_TRIBUTO,w_pratica,w_diff_saldo,a_utente);
                  END IF;
                END IF;
              END IF;  -- w_diff_saldo != 0
            END IF;
            BEGIN
                select nvl(sum(nvl(importo,0)),0)
                  into w_imp_liq_old
                  from sanzioni_pratica
                 where pratica      = w_pratica
                   and cod_sanzione < 100
                ;
            EXCEPTION
              WHEN others THEN
                 w_errore := 'Errore in totalizz. importo (old) ('||SQLERRM||')';
                 RAISE errore;
            END;
            BEGIN
                select nvl(sum(nvl(importo,0)),0)
                  into w_imp_liq_new
                  from sanzioni_pratica
                 where pratica      = w_pratica
                   and cod_sanzione > 100
                ;
            EXCEPTION
               WHEN others THEN
                  w_errore := 'Errore in totalizz. importo (new) ('||SQLERRM||')';
                  RAISE errore;
            END;
            --
            -- Modifica fatta il 04/05/2005 da Davide per ovviare al disguido secondo cui
            -- non veniva tenuto conto dei limiti eventuali digitati.
            --
            IF (w_imp_liq_new = 0 and w_imp_liq_old = 0)
              OR a_anno >= 1998 AND w_imp_liq_new not between nvl(a_importo_limite_inf,-999999999.99)
                 AND nvl(a_importo_limite_sup,999999999.99)
              OR a_anno < 1998 AND w_imp_liq_old not between nvl(a_importo_limite_inf,-999999999.99)
                 AND nvl(a_importo_limite_sup,999999999.99) THEN
              BEGIN
                 delete pratiche_tributo
                    where pratica = w_pratica;
              EXCEPTION
                       WHEN others THEN
                         w_errore := 'Errore in cancellaz. pratica ('||SQLERRM||')';
                         RAISE errore;
              END;
            ELSIF w_imp_liq_new > w_imp_liq_old and a_anno < 1998 THEN
              BEGIN
                 delete sanzioni_pratica
                  where pratica      = w_pratica
                    and cod_sanzione > 100;
                 w_cod_sanzione := C_SPESE_NOT;
                 inserimento_sanzione(w_cod_sanzione,C_TIPO_TRIBUTO,w_pratica,NULL,NULL,NULL,a_utente);
              EXCEPTION
                WHEN others THEN
                  w_errore := 'Errore in cancellaz. sanz. pratica new ('||SQLERRM||')';
                  RAISE errore;
              END;
            ELSIF w_imp_liq_new <= w_imp_liq_old or a_anno >= 1998 THEN
              BEGIN
                delete sanzioni_pratica
                 where pratica      = w_pratica
                   and cod_sanzione < 100
                     ;
                w_cod_sanzione := C_SPESE_NOT + C_NUOVO;
                inserimento_sanzione(w_cod_sanzione,C_TIPO_TRIBUTO,w_pratica,NULL,NULL,NULL,a_utente);
              EXCEPTION
                WHEN others THEN
                  w_errore := 'Errore in cancellaz. sanz. pratica old ('||SQLERRM||')';
                  RAISE errore;
              END;
            END IF;
            COMMIT;
          END IF; -- w_cont_non_liq = a_cont_non_liq THEN
        END IF; -- w_chkLiquida = 1
      END IF; -- F_IMPOSTA_CONT_ANNO_TITR
    END LOOP;
  ELSE --Flag Riferimenti Oggetto checkato
    LIQUIDAZIONI_ICI_RIOG(a_anno, a_cod_fiscale, a_nome, a_data_liquidazione, a_data_rif_interessi, a_da_data_riog, a_a_data_riog,
      a_importo_limite_inf, a_importo_limite_sup,
      a_da_perc_diff, a_a_perc_diff,
--      w_data_scad_acconto, w_data_scad_saldo,
      a_ricalcolo, a_utente,
      a_flag_versamenti,a_flag_rimborso,a_cont_non_liq);
  END IF;
 end if;  -- IMU --
EXCEPTION
  WHEN errore THEN
       ROLLBACK;
       RAISE_APPLICATION_ERROR (-20999,w_errore,TRUE);
  WHEN others THEN
       ROLLBACK;
       RAISE_APPLICATION_ERROR (-20999,'Errore in Calcolo Liquidazioni ICI'||'('||SQLERRM||')');
END;
/* End Procedure: CALCOLO_LIQUIDAZIONI_ICI_NOME */
/

