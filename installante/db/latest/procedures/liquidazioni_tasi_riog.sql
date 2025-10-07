--liquibase formatted sql 
--changeset abrandolini:20250326_152423_liquidazioni_tasi_riog stripComments:false runOnChange:true 
 
create or replace procedure LIQUIDAZIONI_TASI_RIOG
/*************************************************************************
 Versione  Data              Autore    Descrizione
 12        14/04/2025        RV        #77608
                                       Adeguamento gestione sequenza sanzioni 
 11        30/05/2024        AB        #73009 Acquisito anche imm_storico di ogpr e inserito nella Liq
 10        25/09/2023        RV        #66351 - Accetta valore_dic null per tipi 1 e tipi 3 con Ctg. E ed F
 9         20/09/2022        VM        #66699 - sostituito filtro ricerca sogg.cognome_nome
                                       con sogg.cognome_nome_ric
 8         22/08/2023        AB        #66402 Aggiunti controlli per valorizzare correttamente
                                       mese inizio e fine, nel caso di da_mese > 12
 7         09/08/2023        AB        Aggiunti controlli per valorizzare correttamente
                                       mese inizio e fine
 6         02/08/2023        VM        #65986 - Fix calcolo mesi esclusione in base al flag esclusione
 5         08/05/2023        AB        Controllo periodi considerando data_fine >= w_anno
 4         31/01/2023        AB        Controllo date utilizzando anche periodi_riog
 3         15/12/2022        AB        Gestione del da_mese_possesso per il
                                       controllo dei riog e annullo rev 2
 2         02/08/2022        VD        Aggiunto test su flag esclusione per
                                       non trattare gli immobili esclusi
 1         22/10/2019        VD        Aggiunto motivo di non liquidabilita del
                                       contribuente in inserimento wrk_generale
 0         27/01/2015        VD        Prima emissione
*************************************************************************/
(a_anno                      IN number,
 a_cod_fiscale               IN varchar2,
 a_nome                      IN varchar2,
 a_data_liquidazione         IN date,
 a_data_rif_interessi        IN date,
 a_da_data_riog              IN date,
 a_a_data_riog               IN date,
 a_importo_limite_inf        IN number,
 a_importo_limite_sup        IN number,
 a_da_perc_diff              IN number,
 a_a_perc_diff               IN number,
 a_ricalcolo                 IN varchar2,
 a_utente                    IN varchar2,
 a_flag_versamenti           IN varchar2,
 a_flag_rimborso             IN varchar2,
 a_cont_non_liq              IN OUT number)
IS
 --
 C_TIPO_TRIBUTO              CONSTANT varchar2(5) := 'TASI';
 --
 C_IMPO_EVASA_ACC            CONSTANT number := 101;
 C_IMPO_EVASA_SAL            CONSTANT number := 121;
 C_OMESSO_VERS_ACC           CONSTANT number := 104;
 C_OMESSO_VERS_SAL           CONSTANT number := 122;
 C_DIFF_REND_30_ACC          CONSTANT number := 110;
 C_DIFF_REND_30_SAL          CONSTANT number := 120;
 --
 C_SPESE_NOT                 CONSTANT number := 197;
 --
 errore                      exception;
 w_errore                    varchar2(200);
 w_data_scad_acconto         date; --Data scadenza acconto
 w_data_scad_saldo           date; --Data scadenza saldo
 w_cod_sanzione              number;
 w_importo                   number;
 w_controllo                 varchar2(1);
 w_pratica                   number;
 w_oggetto_pratica           number;
 w_oggetto_imposta           number;
 w_imp_acconto               number;
 w_imp_saldo                 number;
 w_imp_evasa_acconto         number;
 w_imp_evasa_saldo           number;
 w_versamenti                number;
 w_versamenti_acconto        number;
 w_versamenti_saldo          number;
 w_diff_acc                  number;
 w_diff_sal                  number;
 w_detr_acconto              number;
 w_imponibile_10_acconto     number;
 w_imponibile_10_saldo       number;
 w_imp_liq_old               number;
 w_imp_liq_new               number;
 w_conto_corrente            number;
 w_perc_diff                 number;
 w_bError                    boolean := FALSE;
 w_mError                    varchar2(2000);
 w_flag_versamenti           varchar2(1);
 w_fase_euro                 number;
 w_1000                      number;
 w_num_riog                  number;
 w_min_dal_riog              date;
 w_max_al_riog               date;
 w_valore_ogpr               number;
 wf                          number;
 w_anno                      number;
 w_mese_inizio               number;
 w_mese_fine                 number;

 w_esiste_categoria          number;
 w_versamenti_ravv           number;
 w_versamenti_ravv_acc       number;
CURSOR sel_riog (p_anno number, p_cod_fiscale varchar2, p_nome varchar) IS
  select ogpr.oggetto,ogpr.tipo_oggetto,ogpr.oggetto_pratica,
         f_dato_riog(ogco.cod_fiscale,ogco.oggetto_pratica,p_anno,'CA') categoria_catasto,
         f_dato_riog(ogco.cod_fiscale,ogco.oggetto_pratica,p_anno,'CL') classe_catasto,
         to_number(f_dato_riog(ogco.cod_fiscale,ogco.oggetto_pratica,p_anno,'VT')) valore,
         f_valore(nvl(f_valore_d(ogpr.oggetto_pratica,p_anno),ogpr.valore)
                 ,ogpr.tipo_oggetto
                 ,prtr.anno
                 ,p_anno
                 ,nvl(ogpr.categoria_catasto,ogge.categoria_catasto)
                 ,prtr.tipo_pratica
                 ,ogpr.FLAG_VALORE_RIVALUTATO
                 )                                            valore_dic,
         ogco.tipo_rapporto,ogco.perc_possesso,
         decode(ogco.anno,p_anno,nvl(ogco.mesi_possesso,12),12)
         mesi_possesso,
         ogco.mesi_possesso_1sem,
         decode(ogco.anno,
                p_anno,
                decode(ogco.flag_esclusione,
                      'S',
                      nvl(ogco.mesi_esclusione,nvl(ogco.mesi_possesso,12)),
                      ogco.mesi_esclusione
                ),
                decode(ogco.flag_esclusione,'S',12,0)
         )                                                    mesi_esclusione,
         decode(ogco.anno,p_anno,
         decode(ogco.flag_riduzione,'S',
         nvl(ogco.mesi_riduzione,nvl(ogco.mesi_possesso,12)),
                ogco.mesi_riduzione),
                decode(ogco.flag_riduzione,'S',12,0)) mesi_riduzione,
         decode(ogco.anno,p_anno,
            nvl(ogco.mesi_aliquota_ridotta,nvl(ogco.mesi_possesso,12)),12)
            mesi_aliquota_ridotta,
         decode(ogco.anno
               ,p_anno,nvl(ogco.da_mese_possesso,1),
                1)  da_mese_possesso,
         decode(ogco.detrazione,'','',
            nvl(made.detrazione,ogco.detrazione)) detrazione,
         ogco.flag_possesso,ogco.flag_esclusione,ogco.flag_riduzione,
         ogco.flag_ab_principale,ogco.flag_al_ridotta,
         ogim.imposta,ogim.imposta_acconto,
         ogim.imposta_dovuta, ogim.imposta_dovuta_acconto,
         ogim.detrazione detrazione_ogim,ogim.detrazione_acconto detrazione_acc_ogim,
         ogim.tipo_aliquota,ogim.aliquota,
         prtr.tipo_pratica,prtr.anno,
         ogco.cod_fiscale,
         ogpr.imm_storico,
         nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto) tipo_ogg_ogpr
   from rivalutazioni_rendita   rire,
        moltiplicatori          molt,
        maggiori_detrazioni     made,
        oggetti                 ogge,
        contribuenti            cont,
        soggetti                sogg,
        pratiche_tributo        prtr,
        oggetti_pratica         ogpr,
        oggetti_contribuente    ogco,
        oggetti_imposta         ogim
  where rire.anno     (+)          = p_anno
    and rire.tipo_oggetto (+)      = ogpr.tipo_oggetto
    and ogim.cod_fiscale           = cont.cod_fiscale
    and ogim.anno                  = p_anno
    and ogim.flag_calcolo          = 'S'
    and ogim.oggetto_pratica       = ogpr.oggetto_pratica
    and ogim.imposta              != 0
    and F_IMPOSTA_CONT_ANNO_TITR (ogco.cod_fiscale,p_anno,C_TIPO_TRIBUTO,to_number(NULL),w_conto_corrente) is not null
    and made.anno         (+) + 0  = p_anno
    and made.cod_fiscale  (+)      = ogco.cod_fiscale
    and made.tipo_tributo  (+)     = 'TASI'
    and prtr.pratica               = ogpr.pratica
    and ogco.cod_fiscale           = ogim.cod_fiscale
    and ogco.oggetto_pratica       = ogim.oggetto_pratica
    and prtr.tipo_tributo  ||''    = 'TASI'
    and cont.cod_fiscale           like p_cod_fiscale
    and sogg.cognome_nome_ric      like p_nome
    and sogg.ni                    = cont.ni
    and ogpr.oggetto               = ogge.oggetto
    and nvl(prtr.stato_accertamento,'D') = 'D'
    and ogpr.flag_contenzioso      is null
    -- (VD - 02/08/2022): aggiunto test su flag_esclusione
    -- (AB - 05/12/2022): tolto test su flag_esclusione
--    and ogco.flag_esclusione       is null
    and molt.anno                  = p_anno
    and molt.categoria_catasto     =
              f_dato_riog(ogco.cod_fiscale,ogco.oggetto_pratica,p_anno,'CA')
    and not exists
       (select 'x'
          from pratiche_tributo pt,
               oggetti_pratica  op
         where pt.cod_fiscale        = ogco.cod_fiscale
           and pt.tipo_tributo||''   = 'TASI'
           and pt.anno + 0           = p_anno
           and nvl(pt.stato_accertamento,'D') = 'D'
           and pt.tipo_pratica       = 'L'
           and (pt.data_notifica    is not null or
                decode(a_ricalcolo, 'S', null, pt.numero) is not null)
           and pt.tipo_evento        = 'R'
           and pt.pratica            = op.pratica
           and op.oggetto + 0        = ogpr.oggetto)
  order by ogco.cod_fiscale
  ;
-- LIQUIDAZIONI_TASI_RIOG
BEGIN
--dbms_output.put_line('Liquidazione dati riog');
  wf := 0;
  w_1000  := 1;
  w_flag_versamenti := a_flag_versamenti;
  BEGIN
    select conto_corrente into w_conto_corrente
      from tipi_tributo where tipo_tributo = 'TASI';
  EXCEPTION
     WHEN no_data_found THEN
   NULL;
     WHEN others THEN
   w_errore := 'Errore in ricerca Tipi Tributo ';
  END;
  wf := 0.5;
  FOR rec_riog IN sel_riog(a_anno, a_cod_fiscale, a_nome) LOOP
  w_data_scad_acconto := f_scadenza(a_anno,'TASI', 'A', rec_riog.cod_fiscale);
  w_data_scad_saldo  := f_scadenza(a_anno,'TASI', 'A', rec_riog.cod_fiscale);
  w_mError := '';
  wf := 1;
    BEGIN
      select round(rec_riog.valore * 100
         / decode(nvl(rec_riog.valore_dic,0),
             0,1,
             rec_riog.valore_dic),2) - 100
        into w_perc_diff
        from dual
      ;
    EXCEPTION
     WHEN others THEN
    w_errore := 'Errore nella determinazione w_perc_diff ';
    END;
    IF  w_perc_diff between a_da_perc_diff and a_a_perc_diff
      AND F_IMPOSTA_CONT_ANNO_TITR (rec_riog.cod_fiscale,a_anno,C_TIPO_TRIBUTO,to_number(NULL),w_conto_corrente) IS NULL THEN
      wf := 2;
      w_bError := TRUE;
      w_mError := 'Presente variazione di rendita e imposta non calcolata per il contribuente';
    ELSIF nvl(rec_riog.mesi_possesso,12)
            < (nvl(rec_riog.mesi_riduzione,0) + nvl(rec_riog.mesi_esclusione,0)) THEN
       w_bError := TRUE;
       w_mError := 'La somma dei mesi esclusione e dei mesi riduzione è superiore ai mesi di possesso (M.E.: '
                ||rec_riog.mesi_esclusione||', M.R.: '||rec_riog.mesi_riduzione||', M.P.: '||rec_riog.mesi_possesso||')';
    ELSIF nvl(rec_riog.mesi_possesso,12)
            < nvl(rec_riog.mesi_aliquota_ridotta,0) THEN
       w_bError := TRUE;
       w_mError := 'Mesi aliquota ridotta superiori ai mesi di possesso (M.R.: '
                ||rec_riog.mesi_aliquota_ridotta||', M.P.: '||rec_riog.mesi_possesso||')';
    ELSIF rec_riog.flag_ab_principale IS NOT NULL and rec_riog.tipo_oggetto not in (3,4,55) THEN
       w_bError := TRUE;
       w_mError := 'Abitazione principale non compatibile con tipologia oggetto';
    ELSIF nvl(rec_riog.perc_possesso,0) = 0 THEN
       w_bError := TRUE;
       w_mError := 'Percentuale di possesso non presente';
    ELSIF (rec_riog.valore_dic IS NULL) AND
          (rec_riog.tipo_ogg_ogpr != 1) AND
          ((rec_riog.tipo_ogg_ogpr != 3) OR (substr(rec_riog.categoria_catasto, 1, 1) not in ('E', 'F')))
          THEN    -- blocco solo il caso null e non il caso di zero
       w_bError := TRUE;
       w_mError := 'Valore dichiarato non presente';
    ELSIF rec_riog.tipo_oggetto in (3,4,55) THEN
       begin
          select count(1)
           into w_esiste_categoria
           from categorie_catasto cate
          where cate.categoria_catasto  = rec_riog.categoria_catasto
            and cate.flag_reale = 'S'
              ;
       EXCEPTION
              WHEN others THEN
                w_errore := 'Errore in controllo categorie catasto '||SQLERRM;
                RAISE errore;
       END;
       if w_esiste_categoria = 0 then
          w_bError := TRUE;
          w_mError := 'Categoria catasto non codificata ('||rec_riog.categoria_catasto||')';
       end if;
    --    ELSIF NOT w_bError THEN
    ELSE
       w_bError := FALSE;
    END IF;
    wf := 3;
    IF w_bError THEN
    a_cont_non_liq := a_cont_non_liq + 1;
    -- Gestione dei contribuenti non Liquidabili
         BEGIN
            insert into wrk_generale
                  (tipo_trattamento,anno,progressivo,dati,note)
            values ('LIQUIDAZIONE TASI',a_anno,to_number(to_char(sysdate,'yyyymmddhhMM'))*1000 + a_cont_non_liq
                   ,a_cod_fiscale,w_mError)
            ;
         EXCEPTION
            WHEN others THEN
               w_errore := 'Errore in inserimento wrk_generale ('||SQLERRM||')';
               RAISE errore;
         END;
    ELSE
       wf := 4;
       w_controllo := '';
      BEGIN
         select 'x'
           into w_controllo
           from pratiche_tributo prtr,
                oggetti_pratica ogpr
          where prtr.cod_fiscale    = rec_riog.cod_fiscale
            and prtr.tipo_tributo||''   = 'TASI'
            and prtr.anno           = a_anno
            and prtr.tipo_pratica   = 'L'
            and nvl(prtr.stato_accertamento,'D') = 'D'
            and prtr.numero        is null
            and prtr.data_notifica is null
            and prtr.pratica        = ogpr.pratica
            and ogpr.oggetto        = rec_riog.oggetto
            and 1 < (select count(*)
                       from oggetti_pratica op
                      where op.pratica = prtr.pratica)
          ;
          RAISE too_many_rows;
      EXCEPTION
         WHEN too_many_rows THEN
           null;
         WHEN no_data_found THEN
           wf := 5;
           BEGIN
             delete pratiche_tributo
              where tipo_tributo   = 'TASI'
                and anno           = a_anno
                and tipo_pratica   = 'L'
                and nvl(stato_accertamento,'D') = 'D'
                and cod_fiscale    = rec_riog.cod_fiscale
                and numero        is null
                and data_notifica is null
                and exists (select 'x'
                              from oggetti_pratica ogpr
                             where pratiche_tributo.pratica = ogpr.pratica
                               and ogpr.oggetto_pratica_rif =
                                   rec_riog.oggetto_pratica)
             ;
           EXCEPTION
             WHEN others THEN
               w_errore := 'Errore in cancellaz. prtr (riog) ';
               RAISE errore;
           END;
         WHEN others THEN
           w_errore := 'Errore in verifica esistenza liq. multioggetto (riog) ';
           RAISE errore;
      END;
      IF w_controllo is null THEN
          w_pratica            := NULL;
         pratiche_tributo_nr(w_pratica);
         wf := 6;
        BEGIN
          insert into pratiche_tributo
                 (pratica,cod_fiscale,tipo_tributo,anno,
                  tipo_pratica,tipo_evento,data,
                  utente,data_variazione)
          values (w_pratica,rec_riog.cod_fiscale,'TASI',a_anno,
                  'L','R',a_data_liquidazione,
                  a_utente,trunc(sysdate))
          ;
        EXCEPTION
          WHEN others THEN
            w_errore := 'Errore in inserimento pratica (riog) ';
            RAISE errore;
        END;
        wf := 7;
        BEGIN
          insert into rapporti_tributo
                 (pratica,cod_fiscale)
          values (w_pratica,rec_riog.cod_fiscale)
          ;
        EXCEPTION
          WHEN others THEN
            w_errore := 'Errore in inserimento rapporto (riog) ';
            RAISE errore;
        END;
        w_oggetto_pratica := NULL;
        oggetti_pratica_nr(w_oggetto_pratica);
        w_oggetto_imposta := NULL;
        oggetti_imposta_nr(w_oggetto_imposta);
        wf := 8;
        w_anno := a_anno;
         BEGIN
--            select count(*)
--                  ,min(nvl(riog.inizio_validita,to_date('01011900','ddmmyyyy')))
--                  ,max(nvl(riog.fine_validita,to_date('31121900','ddmmyyyy')))
--              into w_num_riog
--                  ,w_min_dal_riog
--                  ,w_max_al_riog
--              from riferimenti_oggetto riog
--             where w_anno between nvl(riog.da_anno,0) and nvl(riog.a_anno,9999)
--               and riog.oggetto = rec_riog.oggetto
--            ;
                -- AB 31/01/2023 aggiunta la select da periodo_riog per avere gia il dato
                -- corretto del primo o dell'ultimo giorno del mese
                select count(*)
                      ,min(nvl(peri.inizio_validita,to_date('01011900','ddmmyyyy')))
                      ,max(nvl(peri.fine_validita,to_date('31122999','ddmmyyyy')))
                  into w_num_riog
                      ,w_min_dal_riog
                      ,w_max_al_riog
                  from periodi_riog peri, riferimenti_oggetto riog
                 where w_anno between nvl(riog.da_anno,0) and nvl(riog.a_anno,9999)
                   and riog.oggetto = peri.oggetto
                   --  and to_char(peri.fine_validita,'yyyy') >= :w_anno  --AB 08/05/2022 aggiunto controllo
                   --  and peri.inizio_validita_eff is not null
                   and w_anno between to_char(peri.inizio_validita,'yyyy') and to_char(peri.fine_validita,'yyyy')  -- AB 27/09/2022 aggiunto ulteriore controllo
                   and peri.inizio_validita_eff = riog.inizio_validita
                   and riog.oggetto = rec_riog.oggetto
                ;
         END;

         -- AB (09/08/2023) Aggiunti per gestire i casi di mese iniziuo e fine che davano errore
         -- x mesi_possesso = 0 da_mese possesso 1
         if rec_riog.da_mese_possesso < 1 then
             w_mese_inizio := 1;
         elsif rec_riog.da_mese_possesso > 12 then
             w_mese_inizio := 12;
         else
             w_mese_inizio := rec_riog.da_mese_possesso;
         end if;
         if (rec_riog.da_mese_possesso+rec_riog.mesi_possesso-1) < 1 then
             w_mese_fine := 1;
         elsif (rec_riog.da_mese_possesso+rec_riog.mesi_possesso-1) > 12 then
             w_mese_fine := 12;
         else
             w_mese_fine := (rec_riog.da_mese_possesso+rec_riog.mesi_possesso-1);
         end if;

         if  w_num_riog = 1
         and w_min_dal_riog <= to_date('01'||lpad(w_mese_inizio,2,'0')||lpad(to_char(w_anno),4,'0'),'ddmmyyyy')
--         and w_max_al_riog  >= to_date('3112'||lpad(to_char(w_anno),4,'0'),'ddmmyyyy')
         and w_max_al_riog  >= last_day(
                                 to_date('01'||lpad(w_mese_fine,2,'0')||
                                               lpad(to_char(w_anno),4,'0'),'ddmmyyyy'))
         or  w_num_riog = 0 then
             w_valore_ogpr := rec_riog.valore;
         else
             w_valore_ogpr := null;
         end if;
         BEGIN
          insert into oggetti_pratica
                 (oggetto_pratica,oggetto,pratica,anno,
                  categoria_catasto,classe_catasto,valore,
                  oggetto_pratica_rif,utente,data_variazione,
                  tipo_oggetto,imm_storico)
          select w_oggetto_pratica,rec_riog.oggetto,w_pratica,
                  a_anno,rec_riog.categoria_catasto,
                  rec_riog.classe_catasto,
                  w_valore_ogpr,rec_riog.oggetto_pratica,
                  a_utente,trunc(sysdate),rec_riog.tipo_oggetto,
                  rec_riog.imm_storico
            from dual
          ;
         EXCEPTION
            WHEN others THEN
                  w_errore := 'Errore in inserimento oggetto pratica (riog)';
                  RAISE errore;
         END;
         BEGIN
           insert into costi_storici
                 (oggetto_pratica,anno,costo,utente,data_variazione,note)
           select w_oggetto_pratica,anno,costo,a_utente,trunc(sysdate),note
             from costi_storici
            where oggetto_pratica = rec_riog.oggetto_pratica
           ;
         EXCEPTION
                WHEN others THEN
                  w_errore := 'Errore in inserimento costi_storici (riog)';
                  RAISE errore;
         END;
         wf := 9;
         BEGIN
                insert into oggetti_contribuente
                       (cod_fiscale,oggetto_pratica,anno,
                        perc_possesso,mesi_possesso,mesi_possesso_1sem,
                        mesi_esclusione,mesi_riduzione,mesi_aliquota_ridotta,
                        detrazione,flag_possesso,flag_esclusione,
                        flag_riduzione,flag_ab_principale,
                        flag_al_ridotta,
                        utente,data_variazione)
                values (rec_riog.cod_fiscale,w_oggetto_pratica,a_anno,
                        rec_riog.perc_possesso,rec_riog.mesi_possesso,
                        rec_riog.mesi_possesso_1sem,
                        rec_riog.mesi_esclusione,rec_riog.mesi_riduzione,
                        rec_riog.mesi_aliquota_ridotta,
                        rec_riog.detrazione,rec_riog.flag_possesso,
                        rec_riog.flag_esclusione,
                        rec_riog.flag_riduzione,rec_riog.flag_ab_principale,
                        rec_riog.flag_al_ridotta,
                        a_utente,trunc(sysdate))
                ;
         EXCEPTION
                WHEN others THEN
                  w_errore := 'Errore in inserimento oggetto contribuente (riog)';
                  RAISE errore;
         END;
         wf := 10;
         BEGIN
                insert into oggetti_imposta
                       (oggetto_imposta,cod_fiscale,anno,
                        oggetto_pratica,imposta,imposta_acconto,
                        imposta_dovuta,imposta_dovuta_acconto,
                        tipo_aliquota,aliquota,
                        detrazione,detrazione_acconto,
                        utente,data_variazione,tipo_tributo)
                values (w_oggetto_imposta,rec_riog.cod_fiscale,a_anno,
                        w_oggetto_pratica,rec_riog.imposta,
                        rec_riog.imposta_acconto,
                        rec_riog.imposta_dovuta,
                        rec_riog.imposta_dovuta_acconto,
                        rec_riog.tipo_aliquota,rec_riog.aliquota,
                        rec_riog.detrazione_ogim,rec_riog.detrazione_acc_ogim,
                        a_utente,trunc(sysdate), 'TASI')
                ;
         EXCEPTION
                WHEN others THEN
                  w_errore := 'Errore in inserimento oggetto imposta (riog)';
                  RAISE errore;
         END;
         wf := 11;
         BEGIN
            select sum(vers.importo_versato),sum(decode(vers.tipo_versamento,'S',0,importo_versato))
               into w_versamenti,w_versamenti_acconto
               from versamenti       vers
                   ,pratiche_tributo prtr
              where vers.anno              = a_anno
                and vers.tipo_tributo      = 'TASI'
                and vers.cod_fiscale       = rec_riog.cod_fiscale
                and prtr.pratica (+)       = vers.pratica
                and (    vers.pratica     is null
         --            or  prtr.tipo_pratica = 'V'
                    )
           ;
         EXCEPTION
          WHEN no_data_found THEN
            null;
          WHEN others THEN
            w_errore := 'Errore in verifica versamenti TASI (riog) ';
            RAISE errore;
         END;
         -- Versamenti su ravvediemnto
         begin
           w_versamenti_ravv       := F_IMPORTO_VERS_RAVV(rec_riog.cod_fiscale,'TASI',a_anno,'U');
           w_versamenti_ravv_acc   := F_IMPORTO_VERS_RAVV(rec_riog.cod_fiscale,'TASI',a_anno,'A');
         end;
         -- sommo ai totali dei versamenti i versamenti su ravvedimento
         w_versamenti          := w_versamenti + w_versamenti_ravv;
         w_versamenti_acconto  := w_versamenti_acconto + w_versamenti_ravv_acc;
        -- Determinazione di Eventuali eccedenze di Versamento in Acconto e/o Saldo.
        BEGIN
           IF a_flag_rimborso = 'S' THEN
              w_imp_acconto        := nvl(rec_riog.imposta_acconto,0);
              w_imp_saldo          := nvl(rec_riog.imposta,0)
                                    - nvl(rec_riog.imposta_acconto,0);
           ELSE
              w_imp_acconto        := nvl(rec_riog.imposta_dovuta_acconto,0);
              w_imp_saldo          := nvl(rec_riog.imposta_dovuta,0)
                                    - nvl(rec_riog.imposta_dovuta_acconto,0);
           END IF;
           w_versamenti_acconto := nvl(w_versamenti_acconto,0);
           w_versamenti_saldo   := nvl(w_versamenti,0) - nvl(w_versamenti_acconto,0);
           w_imp_evasa_acconto  := 0;
           w_imp_evasa_saldo    := 0;
           IF w_versamenti_acconto >= w_imp_acconto THEN
              IF w_versamenti_saldo >= w_imp_saldo THEN
                 w_imp_evasa_acconto := w_imp_acconto - w_versamenti_acconto;
                 w_imp_evasa_saldo   := w_imp_saldo - w_versamenti_saldo;
              ELSIF w_versamenti >= w_imp_acconto + w_imp_saldo THEN
                 w_imp_evasa_acconto := w_imp_acconto + w_imp_saldo - w_versamenti;
                 w_imp_evasa_saldo   := 0;
              ELSE
                 w_imp_evasa_acconto := 0;
                 w_imp_evasa_saldo   := w_imp_acconto + w_imp_saldo - w_versamenti;
              END IF;
           ELSE
              IF w_versamenti_saldo < w_imp_saldo THEN
                 w_imp_evasa_acconto := w_imp_acconto - w_versamenti_acconto;
                 w_imp_evasa_saldo   := w_imp_saldo - w_versamenti_saldo;
              ELSIF w_versamenti >= w_imp_acconto + w_imp_saldo THEN
                 w_imp_evasa_acconto := 0;
                 w_imp_evasa_saldo   := w_imp_saldo - w_versamenti;
              ELSE
                 w_imp_evasa_acconto := w_imp_acconto + w_imp_saldo - w_versamenti;
                 w_imp_evasa_saldo   := 0;
              END IF;
           END IF;
        END;
        wf := 12;
         IF nvl(rec_riog.detrazione,0) != 0 THEN
            BEGIN
                 select f_round(nvl(rec_riog.imposta_acconto,0) * nvl(rec_riog.detrazione,0)
               / decode(nvl(rec_riog.imposta,0),0,1,rec_riog.imposta),0)
                  into w_detr_acconto
                  from dual
               ;
            EXCEPTION
                 WHEN others THEN
                 w_errore := 'Errore nella determinazione w_detr_acconto ';
            END;
         END IF;
         w_imponibile_10_acconto   := f_round(nvl(rec_riog.imposta_acconto,0) - nvl(rec_riog.imposta_dovuta_acconto,0),1);
         w_imponibile_10_saldo     := f_round(nvl(rec_riog.imposta,0) - nvl(rec_riog.imposta_dovuta,0),1)
                                  - w_imponibile_10_acconto;
         IF w_imponibile_10_acconto != 0 THEN
            IF w_flag_versamenti = 'S' THEN
               IF nvl(w_versamenti,0) = 0 THEN
                 w_importo := nvl(rec_riog.imposta_acconto,0);
                 w_cod_sanzione := C_OMESSO_VERS_ACC;
                 wf := 13;
                 inserimento_sanzione(w_cod_sanzione,C_TIPO_TRIBUTO,w_pratica,NULL,rec_riog.imposta_acconto,NULL,a_utente,0,w_data_scad_acconto);
               ELSE
                 w_importo := nvl(rec_riog.imposta_acconto,0) - nvl(w_versamenti_acconto,0);
               END IF;
            ELSE
               w_importo := nvl(w_imponibile_10_acconto,0);
            END IF;
            wf := 15;
            w_cod_sanzione := C_IMPO_EVASA_ACC;
            inserimento_sanzione(w_cod_sanzione,C_TIPO_TRIBUTO,w_pratica,NULL,NULL,w_importo,a_utente,0,w_data_scad_acconto);
            w_cod_sanzione := C_DIFF_REND_30_ACC;
            inserimento_sanzione(w_cod_sanzione,C_TIPO_TRIBUTO,w_pratica,NULL,w_imponibile_10_acconto,NULL,a_utente,0,w_data_scad_acconto);
            -- Se non esiste imposta a Saldo, bisogna considerare tutti i versamenti.
            IF w_imp_evasa_saldo = 0 THEN
               w_diff_acc := w_imp_acconto + w_imp_saldo - w_versamenti;
            END IF;
            -- Modifica del 09/08/2001 D.M. (solo a rimborso)
            IF w_diff_acc < 0 and abs(w_diff_acc) > w_1000 THEN
               IF w_versamenti_acconto > 0 THEN -- se versamento tutto a saldo varia la data
                  inserimento_interessi(w_pratica,NULL,w_data_scad_acconto,a_data_rif_interessi,w_diff_acc,C_TIPO_TRIBUTO,'A',a_utente,w_data_scad_acconto);
               ELSE
                  inserimento_interessi(w_pratica,NULL,w_data_scad_saldo,a_data_rif_interessi,w_diff_acc,C_TIPO_TRIBUTO,'A',a_utente,w_data_scad_saldo);
               END IF;
            END IF;
         END IF;
         IF w_imponibile_10_saldo != 0 THEN
            IF w_flag_versamenti = 'S' THEN
               IF nvl(w_versamenti,0) = 0 THEN
                  w_importo := nvl(rec_riog.imposta,0) - nvl(rec_riog.imposta_acconto,0);
                  w_cod_sanzione := C_OMESSO_VERS_SAL;
                  inserimento_sanzione(w_cod_sanzione,C_TIPO_TRIBUTO,w_pratica,NULL,NULL,w_importo,a_utente,0,w_data_scad_saldo);
               ELSE
                  w_importo := nvl(rec_riog.imposta,0) - nvl(rec_riog.imposta_acconto,0) -
                               nvl(w_versamenti,0) + nvl(w_versamenti_acconto,0);
               END IF;
            ELSE
               w_importo := nvl(w_imponibile_10_saldo,0);
            END IF;
            wf := 17;
            w_cod_sanzione := C_IMPO_EVASA_SAL;
            inserimento_sanzione(w_cod_sanzione,C_TIPO_TRIBUTO,w_pratica,NULL,NULL,w_importo,a_utente,0,w_data_scad_saldo);
            w_cod_sanzione := C_DIFF_REND_30_SAL;
            wf := 18;
            inserimento_sanzione(w_cod_sanzione,C_TIPO_TRIBUTO,w_pratica,NULL,w_imponibile_10_saldo,NULL,a_utente,0,w_data_scad_saldo);
            -- Se non esiste imposta in Acconto bisogna considerare tutti i versamenti.
            IF w_imp_evasa_acconto = 0 THEN
               w_diff_sal := w_imp_acconto + w_imp_saldo - w_versamenti;
            END IF;
            -- Modifica del 09/08/2001 D.M. (solo a rimborso)
            IF w_diff_sal < 0 and abs(w_diff_sal) > w_1000 THEN
               wf := 19;
               inserimento_interessi(w_pratica,NULL,w_data_scad_saldo,a_data_rif_interessi,w_diff_sal,C_TIPO_TRIBUTO,'S',a_utente,w_data_scad_saldo);
            END IF;
         END IF;
         wf := 20;
         BEGIN
               select nvl(sum(nvl(importo,0)),0)
                 into w_imp_liq_new
                 from sanzioni_pratica
                where pratica      = w_pratica
                  and cod_sanzione > 100
               ;
         EXCEPTION
            WHEN others THEN
            w_errore := 'Errore in totalizz. importo (new) ';
            RAISE errore;
         END;
         IF w_imp_liq_new = 0 OR
            w_imp_liq_new not between nvl(a_importo_limite_inf,-999999999)
                                  and nvl(a_importo_limite_sup,999999999) then
            wf := 22;
            BEGIN
              delete pratiche_tributo
               where pratica = w_pratica
              ;
            EXCEPTION
              WHEN others THEN
                w_errore := 'Errore in cancellaz. pratica ';
                RAISE errore;
            END;
         ELSE
            wf := 24;
            BEGIN
              w_cod_sanzione := C_SPESE_NOT;
              IF f_check_sanzione(w_pratica, w_cod_sanzione, a_data_liquidazione) = 0 THEN
                 inserimento_sanzione(w_cod_sanzione,C_TIPO_TRIBUTO,w_pratica,NULL,NULL,NULL,a_utente,0,a_data_liquidazione);
              END IF;
            EXCEPTION
              WHEN others THEN
                w_errore := 'Errore in cancellaz. sanz. pratica old ';
                RAISE errore;
            END;
          END IF;
         END IF;
      COMMIT;
    END IF;
  END LOOP;
  wf := 25;
EXCEPTION
  WHEN errore THEN
       ROLLBACK;
       RAISE_APPLICATION_ERROR (-20999,w_errore,TRUE);
  WHEN others THEN
       ROLLBACK;
       RAISE_APPLICATION_ERROR (-20999,'Errore in LIQUIDAZIONI_TASI_RIOG -'||
                               to_char(wf)||'- ('||SQLERRM||')');
END;
/* End Procedure: LIQUIDAZIONI_TASI_RIOG */
/
