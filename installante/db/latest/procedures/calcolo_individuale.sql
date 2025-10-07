--liquibase formatted sql 
--changeset abrandolini:20250326_152423_calcolo_individuale stripComments:false runOnChange:true 
 
create or replace procedure CALCOLO_INDIVIDUALE
/*************************************************************************
 Versione  Data              Autore    Descrizione
 10        07/12/2023        RV        #66629
                                       Escluso immobili con mesi_esclusione = mesi_possesso
                                       generati in automatico da carica_pratica_k
 9         27/10/2020        VD        Modificato calcolo saldo IMU 2020
                                       come da da art. 78 del
                                       D.L. 14 agosto 2020, n. 104 (utilizzando
                                       il campo perc_saldo presente in tabella
                                       ALIQUOTE)
 8         21/10/2020        VD        Aggiunta determinazione versamenti
                                       dell'anno
 7         07/08/2020        VD        Aggiunta gestione fabbricati merce
 5         12/05/2016        VD        Modifiche anno 2016 - gestione
                                       flag_riduzione e riduzione_imposta
                                       per concordati e comodati
                                       Modificata gestione arrotondamenti
                                       per analogia con calcolo imposta
 4         09/05/2016        VD        Mini IMU: corretto aggiornamento
                                       detrazione_std in tabella OGGETTI_IMPOSTA:
                                       detrazione del singolo record al posto
                                       della somma delle detrazioni trattate
                                       fino al momento
 3         15/01/2016        VD        Corretto calcolo Mini-IMU in presenza
                                       di detrazioni da spalmare sulle
                                       pertinenze
 2         19/11/2014        VD        Ripristino calcolo Mini-IMU
 1         15/10/2014        VD        Correzione totalizzazione pertinenze
                                       per anni < 2012
*************************************************************************/
( a_pratica                            IN     number
, a_tipo_calcolo                       IN     varchar2
, a_dep_terreni                        IN OUT number
, a_acconto_terreni                    IN OUT number
, a_saldo_terreni                      IN OUT number
, a_dep_aree                           IN OUT number
, a_acconto_aree                       IN OUT number
, a_saldo_aree                         IN OUT number
, a_dep_ab                             IN OUT number
, a_acconto_ab                         IN OUT number
, a_saldo_ab                           IN OUT number
, a_dep_altri                          IN OUT number
, a_acconto_altri                      IN OUT number
, a_saldo_altri                        IN OUT number
, a_acconto_detrazione                 IN OUT number
, a_saldo_detrazione                   IN OUT number
, a_totale_terreni                     IN OUT number
, a_numero_fabbricati                  IN OUT number
, a_acconto_terreni_erar               IN OUT number
, a_saldo_terreni_erar                 IN OUT number
, a_acconto_aree_erar                  IN OUT number
, a_saldo_aree_erar                    IN OUT number
, a_acconto_altri_erar                 IN OUT number
, a_saldo_altri_erar                   IN OUT number
, a_dep_rurali                         IN OUT number
, a_acconto_rurali                     IN OUT number
, a_saldo_rurali                       IN OUT number
, a_num_fabbricati_ab                  IN OUT number
, a_num_fabbricati_rurali              IN OUT number
, a_num_fabbricati_altri               IN OUT number
, a_acconto_uso_prod                   IN OUT number
, a_saldo_uso_prod                     IN OUT number
, a_num_fabbricati_uso_prod            IN OUT number
, a_acconto_uso_prod_erar              IN OUT number
, a_saldo_uso_prod_erar                IN OUT number
, a_saldo_detrazione_std               IN OUT number
, a_acconto_fabb_merce                 IN OUT number
, a_saldo_fabb_merce                   IN OUT number
, a_num_fabbricati_merce               IN OUT number
, a_dep_uso_prod                       IN OUT number
, a_dep_uso_prod_erar                  IN OUT number
, a_dep_terreni_erar                   IN OUT number
, a_dep_aree_erar                      IN OUT number
, a_dep_altri_erar                     IN OUT number
, a_dep_fabb_merce                     IN OUT number
, a_flag_versamenti                    IN OUT varchar2
) is
  w_cod_fiscale                 varchar2(16);
  w_anno                        number  := 0;
  w_oggetto                     number  := 9999999999;
  w_numero_fabbricati           number  := 0;
  w_num_fabbricati_ab           number  := 0;
  w_num_fabbricati_rurali       number  := 0;
  w_num_fabbricati_altri        number  := 0;
  w_num_fabbricati_merce        number  := 0;
  w_flag_pertinenze             varchar2(1);
  w_aliquota_rire               number;
  w_moltiplicatore              number;
  w_coeff_rid                   number;
  w_valore                      number  := 0;

  w_terreni_rec                 number  := 0;
  w_acconto_terreni_rec         number  := 0;
  w_acconto_terreni             number  := 0;
  w_saldo_terreni               number  := 0;

  w_aree_rec                    number  := 0;
  w_acconto_aree_rec            number  := 0;
  w_acconto_aree                number  := 0;
  w_saldo_aree                  number  := 0;

  w_abitazioni_rec              number  := 0; -- imposta di un singolo ogim (saldo + acconto)
  w_acconto_abitazioni_rec      number  := 0; -- acconto imposta di un singolo ogim
  w_acconto_abitazioni          number  := 0; -- totale acconto imposta di un cf (saldo + acconto)
  w_saldo_abitazioni            number  := 0; -- totale saldo imposta di un cf (imposta - acconto)

  w_detrazioni_rec              number  := 0; -- detrazioni applicate al totale di un singolo ogim
  w_acconto_detrazioni_rec      number  := 0; -- detrazioni applicate all'acconto di un singolo ogim
  w_acconto_detrazioni          number  := 0; -- detrazioni da applicare sull'importo in accornto totale di un cf
  w_saldo_detrazioni            number  := 0; -- detrazione da applicare sull'importo a saldo totale di un cf

  w_altri_rec                   number  := 0;
  w_acconto_altri_rec           number  := 0;
  w_acconto_altri               number  := 0;
  w_saldo_altri                 number  := 0;

  w_tot_terreni_con_rid         number  := 0;
  w_acconto_pertinenze          number  := 0;
  w_saldo_pertinenze            number  := 0;
  -- ECCEDENZE DI DETRAZIONE (DA SPALMARE SU ALTRI IMPORTI)
  w_diff_detrazioni_rec         number  := 0; --differenza tra detrazione totale di un ogim e imposta di un ogim (se negativa mette 0)
  w_diff_acconto_det_rec        number  := 0; --differenza tra detrazione acconto di un ogim e imposta acconto di un ogim (se negativa mette 0)
  w_diff_acconto_det            number  := 0; --differenza tra detrazione acconto di un cf e imposta acconto di un cf (se negativa mette 0)
  w_diff_saldo_det              number  := 0; --differenza tra detrazione saldo di un ogim e imposta saldo di un ogim (se negativa mette 0)

  w_acconto_terreni_erar        number  := 0;
  w_saldo_terreni_erar          number  := 0;
  w_acconto_aree_erar           number  := 0;
  w_saldo_aree_erar             number  := 0;
  w_acconto_altri_erar          number  := 0;
  w_saldo_altri_erar            number  := 0;
  w_acconto_rurali              number  := 0;
  w_saldo_rurali                number  := 0;

  w_rurali_rec                  number  := 0;
  w_acconto_rurali_rec          number  := 0;

  w_terreni_erar_rec            number  := 0;
  w_acconto_terreni_erar_rec    number  := 0;
  w_aree_erar_rec               number  := 0;
  w_acconto_aree_erar_rec       number  := 0;
  w_altri_erar_rec              number  := 0;
  w_acconto_altri_erar_rec      number  := 0;

  w_acconto_uso_prod            number  := 0;
  w_saldo_uso_prod              number  := 0;
  w_num_fabbricati_uso_prod     number  := 0;
  w_acconto_uso_prod_erar       number  := 0;
  w_saldo_uso_prod_erar         number  := 0;
  w_uso_prod_rec                number  := 0;
  w_acconto_uso_prod_rec        number  := 0;
  w_uso_prod_erar_rec           number  := 0;
  w_acconto_uso_prod_erar_rec   number  := 0;

  w_esiste_coco                 number;
  w_utente                      varchar2(8);
  errore                        exception;
  w_errore                      varchar2(2000);
  wf                            number;

  w_acconto_terreni_std         number  := 0;
  w_saldo_terreni_std           number  := 0;
  w_terreni_std_rec             number  := 0;
  w_acconto_terreni_std_rec     number  := 0;

  w_abitazioni_std_rec          number  := 0;
  w_acconto_abitazioni_std_rec  number  := 0;
  w_acconto_abitazioni_std      number  := 0;
  w_saldo_abitazioni_std        number  := 0;

  w_detrazioni_std_rec          number  := 0;
  w_acconto_detrazioni_std_rec  number  := 0;
  w_acconto_detrazioni_std      number  := 0;
  w_saldo_detrazioni_std        number  := 0;
  w_diff_detrazioni_std_rec     number  := 0;
  w_diff_acconto_det_std_rec    number  := 0;
  w_diff_acconto_std_det        number  := 0;
  w_diff_saldo_std_det          number  := 0;

  w_acconto_altri_std           number  := 0;
  w_saldo_altri_std             number  := 0;
  w_altri_std_rec               number  := 0;
  w_acconto_altri_std_rec       number  := 0;

  w_acconto_uso_prod_std        number  := 0;
  w_saldo_uso_prod_std          number  := 0;
  w_uso_prod_std_rec            number  := 0;
  w_acconto_uso_prod_std_rec    number  := 0;
  -- (VD -07/0/2020): Variabili per fabbricati merce
  w_flag_fabb_merce             varchar(1);
  w_fabb_merce_rec              number  := 0; -- imposta di un singolo ogim (saldo + acconto)
  w_acconto_fabb_merce_rec      number  := 0; -- acconto imposta di un singolo ogim
  w_acconto_fabb_merce          number  := 0; -- totale acconto imposta di un cf (saldo + acconto)
  w_saldo_fabb_merce            number  := 0; -- totale saldo imposta di un cf (imposta - acconto)

  w_tipo_tributo                varchar2(5);
  w_perc_occupante              number  := 0;
  w_perc_occupante_ricalcolo    number  := 0;

  w_riduzione_imp               number;

-- (VD - 21/10/2020): variabili per versamenti
  w_terreni_agricoli            number;
  w_terreni_erario              number;
  w_aree_fabbricabili           number;
  w_aree_erario                 number;
  w_ab_principale               number;
  w_rurali                      number;
  w_altri_fabbricati            number;
  w_altri_erario                number;
  w_fabbricati_d                number;
  w_fabb_d_erario               number;
  w_fabb_merce                  number;

-- (VD - 27/10/2020): variabili per calcolo saldo IMU 2020
  w_perc_saldo                  number;
  w_imposta_saldo               number;
  w_imposta_saldo_erar          number;
  w_note_saldo                  varchar2(2000);


  cursor SEL_OGCO is
  select ogge.oggetto,
         ogpr.tipo_oggetto,
         ogpr.imm_storico,
         ogge.categoria_catasto categoria_catasto_ogge,
         ogge.descrizione,
         ogco.flag_possesso,
         ogco.perc_possesso,
         ogco.mesi_possesso,
         ogco.mesi_possesso_1sem,
         ogco.flag_esclusione,
         ogco.flag_riduzione,
         ogco.flag_ab_principale,
         ogco.flag_al_ridotta,
         ogpr.valore,
         ogco.detrazione detrazione_ogco,
         ogim.tipo_aliquota tipo_aliquota_ogim,
         ogim.aliquota aliquota_ogim,
         ogco.cod_fiscale cod_fiscale_ogco,
         ogco.anno anno_ogco,
         ogim.oggetto_imposta,
         ogim.detrazione detrazione,
         ogim.detrazione_acconto detrazione_prec,
         ogpr.categoria_catasto categoria_catasto_ogpr,
         to_number(substr(ogpr.indirizzo_occ,3,6)) / 100    aliquota_prec_ogpr,
         to_number(substr(ogpr.indirizzo_occ,9,15)) / 100   detrazione_prec_ogpr,
         to_number(substr(ogpr.indirizzo_occ,24,6)) / 100   aliquota_erar_prec,
         ogim.aliquota_erariale                             aliquota_erariale_ogim,
         ogim.aliquota_std                                  aliquota_std_ogim,
         ogim.detrazione_std                                detrazione_std,
         ogpr.oggetto_pratica                               oggetto_pratica,
         ogpr.oggetto_pratica_rif_ap,
         prtr.tipo_tributo,
         ogco.tipo_rapporto_k tipo_rapporto
    from oggetti ogge,
         oggetti_imposta      ogim,
         pratiche_tributo     prtr,
         oggetti_pratica      ogpr,
         oggetti_contribuente ogco
   where ogge.oggetto          = ogpr.oggetto
     and ogim.oggetto_pratica  = ogco.oggetto_pratica
     and ogim.anno             = ogco.anno
     and ogim.cod_fiscale      = ogco.cod_fiscale
     and ogpr.oggetto_pratica  = ogco.oggetto_pratica
     and ogpr.pratica          = prtr.pratica
     and prtr.pratica          = a_pratica
     and nvl(ogco.flag_esclusione,'N') = 'N'                 -- Non tratto gli oggetti con flag esclusione (Piero 21-07-2010)
     and nvl(ogco.mesi_esclusione,0) != ogco.mesi_possesso   -- Non tratto gli oggetti con mesi eslusione = mesi possesso
   order by ogpr.categoria_catasto desc
          , ogge.oggetto asc
  ;
  cursor SEL_TERRENI_RID is
  select ogpr.oggetto
        ,decode(sum(nvl(ogco.mesi_possesso,12))
               ,0,0
                 ,sum(nvl(ogpr.valore,0) * (100 + nvl(w_aliquota_rire,0)) / 100
                      * nvl(w_moltiplicatore,0) * nvl(ogco.mesi_possesso,12)
                     ) / sum(nvl(ogco.mesi_possesso,12))
               ) terreni_rid
    from oggetti_contribuente ogco,
         oggetti_pratica ogpr,
         pratiche_tributo prtr
   where ogco.flag_riduzione    = 'S'
     and ogco.oggetto_pratica   = ogpr.oggetto_pratica
     and ogpr.pratica      = prtr.pratica
     and ogpr.tipo_oggetto = 1  -- Aggiunta da AB il 1/03/2017
     and prtr.pratica      = a_pratica
   group by
         ogpr.oggetto
  ;
  cursor SEL_OGIM is
  select ogim.oggetto_imposta
        ,ogim.imposta
        ,ogim.detrazione
        ,ogim.imposta_acconto
        ,ogim.detrazione_acconto
        ,ogim.imposta_aliquota
        ,ogim.imposta_std
        ,ogim.detrazione_std
        ,ogco.tipo_rapporto
        ,F_ORDINAMENTO_OGGETTI(ogpr.oggetto,
                               ogco.oggetto_pratica,
                               ogpr.oggetto_pratica_rif_ap,
                               ogco.flag_ab_principale,
                               ogco.flag_possesso,
                               ogco.mesi_possesso_1sem
                              ) ordinamento
    from oggetti_contribuente ogco
        ,oggetti_pratica      ogpr
        ,oggetti_imposta      ogim
   where ogco.cod_fiscale        = ogim.cod_fiscale
     and ogco.oggetto_pratica    = ogim.oggetto_pratica
     and ogpr.oggetto_pratica    = ogim.oggetto_pratica
     and ogco.flag_ab_principale = 'S'
     and ogpr.pratica            = a_pratica
   order by
         ogpr.categoria_catasto
        ,ogpr.oggetto
  ;

BEGIN

  FOR rec_ogco IN sel_ogco
  LOOP
    w_anno            := rec_ogco.anno_ogco;
    w_cod_fiscale     := rec_ogco.cod_fiscale_ogco;
    w_tipo_tributo    := rec_ogco.tipo_tributo;
    if w_tipo_tributo = 'TASI' then
       -- Estrazione Percentuale Occupante
       begin
         select perc_occupante
           into w_perc_occupante
           from aliquote
          where anno = w_anno
            and tipo_tributo = 'TASI'
            and tipo_aliquota = 1
         ;
          if w_perc_occupante is null then
             RAISE errore;
          end if;
       exception
         when others then
           w_errore := 'Errore: non esiste percentuale occupante';
           RAISE errore;
       end;
    end if;

    begin
      select flag_pertinenze
        into w_flag_pertinenze
        from aliquote
       where flag_ab_principale = 'S'
         and anno = w_anno
         and tipo_tributo = w_tipo_tributo
      ;
    exception
      when no_data_found or too_many_rows then
        w_errore := 'Errore in Ricerca Flag Pertinenze';
        raise errore;
    end;
    --
    -- (VD - 12/05/2016): Modifiche 2016, Si estrae l'eventuale riduzione
    --                    imposta per il tipo aliquota selezionato
    -- (VD - 07/08/2020): Aggiunta selezione flag fabbricati merce
    --
    begin
      select nvl(riduzione_imposta,100)
           , flag_fabbricati_merce
        into w_riduzione_imp
           , w_flag_fabb_merce
        from aliquote
       where anno = w_anno
         and tipo_tributo = w_tipo_tributo
         and tipo_aliquota = rec_ogco.tipo_aliquota_ogim
      ;
    exception
      when others then
        w_errore := 'Errore in Ricerca Tipo Aliquota '||to_char(rec_ogco.tipo_aliquota_ogim);
        raise errore;
    end;
    begin
      select rire.aliquota
        into w_aliquota_rire
        from rivalutazioni_rendita rire
       where anno         = rec_ogco.anno_ogco
         and tipo_oggetto = rec_ogco.tipo_oggetto
      ;
    exception
      when no_data_found then
        w_aliquota_rire := 0;
      when others then
        w_errore := 'Errore in ricerca Rivalutazioni Rendita'||
                    ' ('||sqlerrm||')';
        raise errore;
    end;

    w_valore := rec_ogco.valore * (100 + nvl(w_aliquota_rire,0)) / 100;
    begin
       select nvl(molt.moltiplicatore,1)
         into w_moltiplicatore
         from moltiplicatori molt
        where categoria_catasto = rec_ogco.categoria_catasto_ogpr
          and rec_ogco.tipo_oggetto in (1,3,55)
          and anno    = rec_ogco.anno_ogco
       ;
    exception
      when no_data_found then
        w_moltiplicatore := 1;
      when others then
        w_errore := 'Errore in ricerca Moltiplicatori'||
                    ' ('||sqlerrm||')';
        raise errore;
    end;

    if rec_ogco.tipo_oggetto in (3,55)     and
       nvl(rec_ogco.imm_storico,'N') = 'S' and
       rec_ogco.anno_ogco < 2012           then
       w_moltiplicatore := 100;
    end if;

    wf := 1;
    if rec_ogco.tipo_oggetto in (3,55,4) then
       if w_oggetto != rec_ogco.oggetto then
          w_numero_fabbricati := w_numero_fabbricati + 1;
       else
          if rec_ogco.descrizione = 'OGGETTO PER CALCOLO WEB' then
             w_numero_fabbricati := w_numero_fabbricati + 1;
          end if;
       end if;
    end if;
    w_oggetto   := rec_ogco.oggetto;
    if rec_ogco.tipo_oggetto <> 2 then -- Per le Aree non si moltiplica
       w_valore := w_valore * nvl(w_moltiplicatore,1);
    end if;

    if rec_ogco.tipo_oggetto = 1 then
    -- Terreno
       wf := 2;
       if rec_ogco.flag_riduzione is null then
       -- Terreno senza riduzione
          w_terreni_rec := f_round(((((((w_valore
                   * rec_ogco.aliquota_ogim) / 1000)
                   * rec_ogco.perc_possesso) / 100)
                   * rec_ogco.mesi_possesso) / 12),0);
          if rec_ogco.anno_ogco <= 2000 then
             w_acconto_terreni_rec := f_round(((((((((w_valore
                         * rec_ogco.aliquota_ogim) / 1000)
                         * rec_ogco.perc_possesso) / 100)
                         * nvl(rec_ogco.mesi_possesso_1sem,0)) / 12)
                         * 90) / 100),0);
          else
             w_acconto_terreni_rec := f_round(((((((((w_valore
                         * rec_ogco.aliquota_prec_ogpr) / 1000)
                         * rec_ogco.perc_possesso) / 100)
                         * nvl(rec_ogco.mesi_possesso_1sem,0)) / 12)
                         * 100) / 100),0);
          end if;

          if rec_ogco.anno_ogco >= 2012 then
             w_terreni_erar_rec := f_round(((((((w_valore
                      * rec_ogco.aliquota_erariale_ogim) / 1000)
                      * rec_ogco.perc_possesso) / 100)
                      * rec_ogco.mesi_possesso) / 12),0);
             w_acconto_terreni_erar_rec := f_round(((((((((w_valore
                            * rec_ogco.aliquota_erar_prec) / 1000)
                            * rec_ogco.perc_possesso) / 100)
                            * nvl(rec_ogco.mesi_possesso_1sem,0)) / 12)
                            * 100) / 100),0);
          end if;

       else
          wf := 3;
          -- Terreno con riduzione
          if w_tot_terreni_con_rid = 0 then
             for rec_terreni_rid in sel_terreni_rid
             loop
               w_tot_terreni_con_rid := w_tot_terreni_con_rid +
                                     f_round(rec_terreni_rid.terreni_rid,0);
             end loop;
             begin
               select decode(nvl(teri.valore,0) + nvl(w_tot_terreni_con_rid,0)
                            ,0,1
                            ,nvl(w_tot_terreni_con_rid,0) /
                               (nvl(teri.valore,0) + nvl(w_tot_terreni_con_rid,0))
                            )
                 into w_coeff_rid
                 from terreni_ridotti teri
                where teri.cod_fiscale  = rec_ogco.cod_fiscale_ogco
                  and teri.anno         = rec_ogco.anno_ogco
               ;
             exception
               when no_data_found then
                 w_coeff_rid  := 1;
               when others then
                 w_errore := 'Errore calcolo totale terreni con riduzione';
                 raise errore;
             end;
          end if;
          wf := 4;
          -- Imposta
          CALCOLO_TERRENI_RIDOTTI(w_tot_terreni_con_rid,w_tot_terreni_con_rid
                                 ,w_coeff_rid,w_coeff_rid,rec_ogco.aliquota_ogim
                                 ,rec_ogco.perc_possesso,rec_ogco.mesi_possesso
                                 ,rec_ogco.mesi_possesso_1sem,w_valore,w_valore
                                 ,rec_ogco.aliquota_prec_ogpr
                                 ,rec_ogco.anno_ogco,w_acconto_terreni_rec,w_terreni_rec);
          if rec_ogco.anno_ogco >= 2012 then
             -- Imposta Erariale
             CALCOLO_TERRENI_RIDOTTI(w_tot_terreni_con_rid,w_tot_terreni_con_rid
                                    ,w_coeff_rid,w_coeff_rid,rec_ogco.aliquota_erariale_ogim
                                    ,rec_ogco.perc_possesso,rec_ogco.mesi_possesso
                                    ,rec_ogco.mesi_possesso_1sem,w_valore,w_valore
                                    ,rec_ogco.aliquota_erariale_ogim
                                    ,rec_ogco.anno_ogco,w_acconto_terreni_erar_rec,w_terreni_erar_rec);
          end if;

          if nvl(a_tipo_calcolo,' ') = 'Mini' then
             -- Imposta Standard
             CALCOLO_TERRENI_RIDOTTI(w_tot_terreni_con_rid,w_tot_terreni_con_rid
                                    ,w_coeff_rid,w_coeff_rid,rec_ogco.aliquota_std_ogim
                                    ,rec_ogco.perc_possesso,rec_ogco.mesi_possesso
                                    ,rec_ogco.mesi_possesso_1sem,w_valore,w_valore
                                    ,rec_ogco.aliquota_erariale_ogim
                                    ,rec_ogco.anno_ogco,w_acconto_terreni_std_rec,w_terreni_std_rec);
             w_acconto_terreni_std_rec := 0;
          else
             w_acconto_terreni_std_rec := 0;
             w_terreni_std_rec         := 0;
          end if;

       end if;

       if nvl(a_tipo_calcolo,' ') = 'Mini' then
          if rec_ogco.aliquota_std_ogim is null then
             begin
               update oggetti_imposta
                  set imposta           = 0
                     ,imposta_acconto   = null
                     ,imposta_erariale          = null
                     ,imposta_erariale_acconto  = null
                where oggetto_imposta   = rec_ogco.oggetto_imposta
               ;
             exception
                 when others then
                   w_errore := 'Errore in aggiornamento Oggetti Imposta (Te) 1'||
                               ' ('||sqlerrm||')';
                  raise errore;
             end;
             w_terreni_rec         := 0;
             w_acconto_terreni_rec := 0;
             w_terreni_erar_rec         := 0;
             w_acconto_terreni_erar_rec := 0;
             w_terreni_std_rec          := 0;
             w_acconto_terreni_std_rec  := 0;
          else
             w_terreni_rec         := f_round(w_terreni_rec,0);
             w_acconto_terreni_rec := f_round(w_acconto_terreni_rec,0);
             w_acconto_terreni := nvl(w_acconto_terreni,0) +
                                  nvl(w_acconto_terreni_rec,0);
             w_saldo_terreni := nvl(w_saldo_terreni,0) +
                                nvl(w_terreni_rec,0)     -
                                nvl(w_acconto_terreni_rec,0);

             w_terreni_erar_rec         := round(w_terreni_erar_rec,2);
             w_acconto_terreni_erar_rec := 0;
             w_acconto_terreni_erar := 0;
             w_saldo_terreni_erar   := nvl(w_saldo_terreni_erar,0) +
                                       nvl(w_terreni_erar_rec,0) -
                                       nvl(w_acconto_terreni_erar_rec,0);

             w_terreni_std_rec         := round(w_terreni_std_rec,2);
             w_acconto_terreni_std_rec := 0;
             w_acconto_terreni_std     := 0;
             w_saldo_terreni_std       := nvl(w_saldo_terreni_std,0) +
                                          nvl(w_terreni_std_rec,0) -
                                          nvl(w_acconto_terreni_std_rec,0);

             begin
               update oggetti_imposta
                  set imposta           = round((nvl(w_terreni_rec,0) - nvl(w_terreni_std_rec,0)) * 0.4 ,2)
                     ,imposta_acconto   = null
                     ,imposta_erariale          = null
                     ,imposta_erariale_acconto  = null
                where oggetto_imposta   = rec_ogco.oggetto_imposta
               ;
             exception
               when others then
                 w_errore := 'Errore in aggiornamento Oggetti Imposta (Te) 2'||
                             ' ('||sqlerrm||')';
                 raise errore;
             end;
          end if;
       else
          w_terreni_rec         := nvl(f_round(w_terreni_rec,0),0);
          w_acconto_terreni_rec := f_round(w_acconto_terreni_rec,0);
          w_terreni_erar_rec         := nvl(round(w_terreni_erar_rec,2),0);
          w_acconto_terreni_erar_rec := round(w_acconto_terreni_erar_rec,2);
          -- (VD - 27/10/2020): Calcolo importo IMU a saldo come da
          --                    D.L. 14 agosto 2020, n. 104
          w_note_saldo := null;
          CALCOLO_IMU_SALDO ( w_tipo_tributo
                            , w_anno
                            , rec_ogco.tipo_aliquota_ogim
                            , w_terreni_rec
                            , w_acconto_terreni_rec
                            , w_terreni_erar_rec
                            , w_acconto_terreni_erar_rec
                            , w_perc_saldo
                            , w_imposta_saldo
                            , w_imposta_saldo_erar
                            , w_note_saldo
                            );
          if w_perc_saldo is not null then
             w_terreni_rec      := w_imposta_saldo;
             w_terreni_erar_rec := w_imposta_saldo_erar;
          end if;

          begin
            update oggetti_imposta
               set imposta           = w_terreni_rec
                  ,imposta_acconto   = w_acconto_terreni_rec
                  ,imposta_erariale          = w_terreni_erar_rec
                  ,imposta_erariale_acconto  = w_acconto_terreni_erar_rec
                  ,note              = w_note_saldo
             where oggetto_imposta   = rec_ogco.oggetto_imposta
            ;
             w_perc_occupante_ricalcolo := w_perc_occupante;
             if f_ricalcolo_tasi_per_affitto(w_tipo_tributo
                                            ,rec_ogco.tipo_rapporto
                                            ,rec_ogco.oggetto
                                            ,rec_ogco.flag_al_ridotta --SC usato per forzare che immobile e' occupato
                                            ,'N'
                                            ,w_cod_fiscale
                                            ,w_anno
                                            ,w_perc_occupante_ricalcolo
                                            ,w_terreni_rec
                                            ,w_acconto_terreni_rec
                                            ,w_terreni_erar_rec
                                            ,w_acconto_terreni_erar_rec) then
                update oggetti_imposta
                   set imposta_pre_perc            = imposta
                      ,imposta_acconto_pre_perc    = imposta_acconto
                      ,percentuale                 = w_perc_occupante_ricalcolo
                      ,tipo_rapporto               = rec_ogco.tipo_rapporto
                      ,imposta                     = w_terreni_rec
                      ,imposta_acconto             = w_acconto_terreni_rec
                      ,imposta_erariale            = w_terreni_erar_rec
                      ,imposta_erariale_acconto    = w_acconto_terreni_erar_rec
                 where oggetto_imposta   = rec_ogco.oggetto_imposta
                ;
             end if;
          exception
            when others then
              w_errore := 'Errore in aggiornamento Oggetti Imposta (Te) 3'||
                          ' ('||sqlerrm||')';
              raise errore;
          end;
       end if;
       w_acconto_terreni := nvl(w_acconto_terreni,0) +
                            nvl(w_acconto_terreni_rec,0);
       w_saldo_terreni := nvl(w_saldo_terreni,0) +
                          nvl(w_terreni_rec,0)     -
                          nvl(w_acconto_terreni_rec,0);
       w_acconto_terreni_erar := nvl(w_acconto_terreni_erar,0) +
                                 nvl(w_acconto_terreni_erar_rec,0);
       w_saldo_terreni_erar   := nvl(w_saldo_terreni_erar,0) +
                                 nvl(w_terreni_erar_rec,0) -
                                 nvl(w_acconto_terreni_erar_rec,0);
       w_terreni_rec         := 0;
       w_acconto_terreni_rec := 0;
       w_terreni_erar_rec         := 0;
       w_acconto_terreni_erar_rec := 0;
       w_terreni_std_rec          := 0;
       w_acconto_terreni_std_rec  := 0;
    elsif rec_ogco.tipo_oggetto = 2  then
    -- Area
       wf := 5;
       w_aree_rec := f_round(((((((w_valore
                   * rec_ogco.aliquota_ogim) / 1000)
                   * rec_ogco.perc_possesso) / 100)
                   * rec_ogco.mesi_possesso)  / 12),0);
       if rec_ogco.anno_ogco <= 2000 then
          w_acconto_aree_rec := f_round(((((((((w_valore
                              * rec_ogco.aliquota_ogim) / 1000)
                              * rec_ogco.perc_possesso) / 100)
                              * nvl(rec_ogco.mesi_possesso_1sem,0))  / 12)
                              * 90) / 100),0);
       else
          w_acconto_aree_rec := f_round(((((((((w_valore
                              * rec_ogco.aliquota_prec_ogpr) / 1000)
                              * rec_ogco.perc_possesso) / 100)
                              * nvl(rec_ogco.mesi_possesso_1sem,0))  / 12)
                              * 100) / 100),0);
       end if;

       if rec_ogco.anno_ogco >= 2012 then
          w_aree_erar_rec := f_round(((((((w_valore
                   * rec_ogco.aliquota_erariale_ogim) / 1000)
                   * rec_ogco.perc_possesso) / 100)
                   * rec_ogco.mesi_possesso) / 12),0);
          w_acconto_aree_erar_rec := f_round(((((((((w_valore
                         * rec_ogco.aliquota_erar_prec) / 1000)
                         * rec_ogco.perc_possesso) / 100)
                         * nvl(rec_ogco.mesi_possesso_1sem,0)) / 12)
                         * 100) / 100),0);
       end if;

       w_aree_rec                 := nvl(f_round(w_aree_rec,0),0);
       w_acconto_aree_rec         := f_round(w_acconto_aree_rec,0);
       w_aree_erar_rec            := nvl(round(w_aree_erar_rec,2),0);
       w_acconto_aree_erar_rec    := round(w_acconto_aree_erar_rec,2);
       /*
       dbms_output.put_line('Aree Categ.  - '||rec_ogco.categoria_catasto_ogpr);
       dbms_output.put_line('Aree Totale  - '||to_char(nvl(w_aree_rec,0)));
       dbms_output.put_line('Aree Acconto - '||to_char(nvl(w_acconto_aree_rec,0)));
       dbms_output.put_line(' ');
       */
       if nvl(a_tipo_calcolo,' ') = 'Mini' then
          begin
             update oggetti_imposta
                set imposta           = 0
                   ,imposta_acconto   = null
                   ,imposta_erariale          = null
                   ,imposta_erariale_acconto  = null
              where oggetto_imposta   = rec_ogco.oggetto_imposta
              ;
          exception
             when others then
                w_errore := 'Errore in aggioranamento Oggetti Imposta (Ar)'||
                            ' ('||sqlerrm||')';
                 raise errore;
          end;
          w_aree_rec         := 0;
          w_acconto_aree_rec := 0;
          w_aree_erar_rec          := 0;
          w_acconto_aree_erar_rec  := 0;
       else
          -- (VD - 27/10/2020): Calcolo importo IMU a saldo come da
          --                    D.L. 14 agosto 2020, n. 104
          w_note_saldo := null;
          CALCOLO_IMU_SALDO ( w_tipo_tributo
                            , w_anno
                            , rec_ogco.tipo_aliquota_ogim
                            , w_aree_rec
                            , w_acconto_aree_rec
                            , w_aree_erar_rec
                            , w_acconto_aree_erar_rec
                            , w_perc_saldo
                            , w_imposta_saldo
                            , w_imposta_saldo_erar
                            , w_note_saldo
                            );
          if w_perc_saldo is not null then
             w_aree_rec      := w_imposta_saldo;
             w_aree_erar_rec := w_imposta_saldo_erar;
          end if;
          begin
            update oggetti_imposta
               set imposta           = nvl(w_aree_rec,0)
                  ,imposta_acconto   = w_acconto_aree_rec
                  ,imposta_erariale          = nvl(w_aree_erar_rec,0)
                  ,imposta_erariale_acconto  = w_acconto_aree_erar_rec
                  ,note              = w_note_saldo
             where oggetto_imposta   = rec_ogco.oggetto_imposta
            ;
            w_perc_occupante_ricalcolo := w_perc_occupante;
            if f_ricalcolo_tasi_per_affitto(w_tipo_tributo,
                                            rec_ogco.tipo_rapporto,
                                            rec_ogco.oggetto,
                                            rec_ogco.flag_al_ridotta,
                                            'N',
                                            w_cod_fiscale,
                                            w_anno,
                                            w_perc_occupante_ricalcolo,
                                            w_aree_rec,
                                            w_acconto_aree_rec,
                                            w_aree_erar_rec,
                                            w_acconto_aree_erar_rec) then
               update oggetti_imposta
                 set imposta_pre_perc            = imposta
                    ,imposta_acconto_pre_perc    = imposta_acconto
                    ,percentuale                 = w_perc_occupante_ricalcolo
                    ,tipo_rapporto               = rec_ogco.tipo_rapporto
                    ,imposta                     = w_aree_rec
                    ,imposta_acconto             = w_acconto_aree_rec
                    ,imposta_erariale            = w_aree_erar_rec
                    ,imposta_erariale_acconto    = w_acconto_aree_erar_rec
              where oggetto_imposta   = rec_ogco.oggetto_imposta
              ;
            end if;
          exception
             when others then
                w_errore := 'Errore in aggioranamento Oggetti Imposta (Ar)'||
                            ' ('||sqlerrm||')';
                 raise errore;
          end;
       end if;
       w_acconto_aree := nvl(w_acconto_aree,0) +
                         nvl(w_acconto_aree_rec,0);
       w_saldo_aree   := nvl(w_saldo_aree,0) +
                         nvl(w_aree_rec,0) -
                         nvl(w_acconto_aree_rec,0);
       w_acconto_aree_erar := nvl(w_acconto_aree_erar,0) +
                              nvl(w_acconto_aree_erar_rec,0);
       w_saldo_aree_erar   := nvl(w_saldo_aree_erar,0) +
                              nvl(w_aree_erar_rec,0) -
                              nvl(w_acconto_aree_erar_rec,0);
       w_aree_rec         := 0;
       w_acconto_aree_rec := 0;
       w_aree_erar_rec          := 0;
       w_acconto_aree_erar_rec  := 0;
    elsif
       --- ABITAZIONE PRINCIPALE ---
       rec_ogco.tipo_oggetto in (3,55)
       and (rec_ogco.flag_ab_principale = 'S' or
            (nvl(rec_ogco.detrazione,0) != 0 and /*SC 22/05/2014 da capire se si potrebbe mettere rec_ogco.detrazione IS NOT NULL*/
             rec_ogco.tipo_aliquota_ogim = 2) or
            (rec_ogco.anno_ogco > 2000 and
             nvl(rec_ogco.detrazione_prec,0) != 0 and
             rec_ogco.tipo_aliquota_ogim = 2) or
            rec_ogco.oggetto_pratica_rif_ap is not null
           )
       and (    w_flag_pertinenze = 'S'
            or (w_flag_pertinenze is null and rec_ogco.categoria_catasto_ogpr like 'A%')
           ) then
       wf := 6;

       begin
         select ((((((((w_valore
                  * rec_ogco.aliquota_ogim) / 1000))
                  / decode(rec_ogco.flag_riduzione,'S',2
                          ,decode(rec_ogco.imm_storico||to_char(sign(rec_ogco.anno_ogco - 2011))
                                     ,'S1',2
                                     ,1)
                          )
                    )
                  * rec_ogco.perc_possesso) / 100)
                  * rec_ogco.mesi_possesso) / 12)
              , rec_ogco.detrazione
           into w_abitazioni_rec
              , w_detrazioni_rec
           from dual
         ;
         if rec_ogco.anno_ogco <= 2000 then
            select ((((((((((w_valore
                     * rec_ogco.aliquota_ogim) / 1000))
                     / decode(rec_ogco.flag_riduzione,'S',2,1))
                     * rec_ogco.perc_possesso) / 100)
                     * nvl(rec_ogco.mesi_possesso_1sem,0)) / 12)
                     * 90) / 100)
                 , ((((rec_ogco.detrazione
                     * nvl(rec_ogco.mesi_possesso_1sem,0))
                     / nvl(rec_ogco.mesi_possesso,0))
                     * 90) / 100)
              into w_acconto_abitazioni_rec
                 , w_acconto_detrazioni_rec
              from dual
              ;
         else
            select ((((((((((w_valore
                     * rec_ogco.aliquota_prec_ogpr) / 1000))
                     / decode(rec_ogco.flag_riduzione,'S',2
                             ,decode(rec_ogco.imm_storico||to_char(sign(rec_ogco.anno_ogco - 2011))
                                    ,'S1',2
                                    ,1)
                             )
                         )
                     * rec_ogco.perc_possesso) / 100)
                     * nvl(rec_ogco.mesi_possesso_1sem,0)) / 12)
                     * 100) / 100)
                 , rec_ogco.detrazione_prec
              into w_acconto_abitazioni_rec
                 , w_acconto_detrazioni_rec
              from dual
              ;
         end if;
         w_abitazioni_rec               := f_round(w_abitazioni_rec,0);
         w_acconto_abitazioni_rec       := f_round(w_acconto_abitazioni_rec,0);
         w_detrazioni_rec               := f_round(w_detrazioni_rec,0);
         w_acconto_detrazioni_rec       := f_round(w_acconto_detrazioni_rec,0);
       exception
         when others then
           null;
       end;

       if w_acconto_abitazioni_rec > w_abitazioni_rec then
          w_acconto_abitazioni_rec := w_abitazioni_rec;
       end if;

-- DBMS_OUTPUT.PUT_LINE('*** w_detrazioni_rec '||w_detrazioni_rec);
-- DBMS_OUTPUT.PUT_LINE('*** w_abitazioni_rec '||w_abitazioni_rec);
       if nvl(a_tipo_calcolo,' ') = 'Mini' and
          rec_ogco.aliquota_std_ogim is null then
          w_abitazioni_rec := 0;
          w_acconto_abitazioni_rec := 0;
          w_detrazioni_rec := 0;
          w_acconto_detrazioni_rec := 0;
          w_diff_detrazioni_rec := 0;
          w_diff_acconto_det_rec := 0;
       else
          begin
            select greatest(nvl(w_abitazioni_rec,0) - nvl(w_detrazioni_rec,0)
                           ,0
                           )
                  ,greatest(nvl(w_acconto_abitazioni_rec,0) - nvl(w_acconto_detrazioni_rec,0)
                           ,0
                           )
                  ,least(nvl(w_abitazioni_rec,0),nvl(w_detrazioni_rec,0))
                  ,least(nvl(w_acconto_abitazioni_rec,0),nvl(w_acconto_detrazioni_rec,0))
                  ,greatest(nvl(w_detrazioni_rec,0) - nvl(w_abitazioni_rec,0)
                           ,0
                           )
                  ,greatest(nvl(w_acconto_detrazioni_rec,0) - nvl(w_acconto_abitazioni_rec,0)
                           ,0
                           )
              into w_abitazioni_rec
                  ,w_acconto_abitazioni_rec
                  ,w_detrazioni_rec
                  ,w_acconto_detrazioni_rec
                  ,w_diff_detrazioni_rec
                  ,w_diff_acconto_det_rec
              from dual
              ;
          exception
             when others then
              null;
          end;
       end if;
       --
       -- se risulta che resta una detrazione per l'acconto maggiore di quanto è la reale
       -- detrazione totale restante vuol dire che la detrazione in acconto era troppo alta
       -- ed è stata spalmata sul saldo
       w_diff_acconto_det_rec := least(w_diff_acconto_det_rec, w_diff_detrazioni_rec);

       --
       -- Calcolo con Aliquota Standard
       --
       w_acconto_abitazioni_std_rec := 0;
       w_acconto_detrazioni_std_rec := 0;
       w_diff_acconto_det_std_rec   := 0;
       w_abitazioni_std_rec         := 0;
       w_detrazioni_std_rec         := 0;
       w_diff_detrazioni_std_rec    := 0;
       if rec_ogco.aliquota_std_ogim is not null then
          begin
            select ((((((((w_valore
                     * rec_ogco.aliquota_std_ogim) / 1000))
                     / decode(rec_ogco.flag_riduzione,'S',2
                             ,decode(rec_ogco.imm_storico||to_char(sign(rec_ogco.anno_ogco - 2011))
                                        ,'S1',2
                                        ,1)
                             )
                       )
                     * rec_ogco.perc_possesso) / 100)
                     * rec_ogco.mesi_possesso) / 12)
                 , rec_ogco.detrazione_std
              into w_abitazioni_std_rec
                 , w_detrazioni_std_rec
              from dual
              ;
            w_abitazioni_std_rec           := f_round(w_abitazioni_std_rec,0);
          exception
            when others then
              null;
          end;
          begin
            select greatest(nvl(w_abitazioni_std_rec,0) - nvl(w_detrazioni_std_rec,0)
                           ,0
                           )
                  ,least(nvl(w_abitazioni_std_rec,0),nvl(w_detrazioni_std_rec,0))
                  ,greatest(nvl(w_detrazioni_std_rec,0) - nvl(w_abitazioni_std_rec,0)
                           ,0
                           )
              into w_abitazioni_std_rec
                  ,w_detrazioni_std_rec
                  ,w_diff_detrazioni_std_rec
              from dual
              ;
          exception
              when others then
               null;
          end;
       end if;

       if rec_ogco.categoria_catasto_ogpr like 'C%'
       and rec_ogco.anno_ogco < 2012 then
          declare
            w_fittizia_erar number := 0;
            w_fittizia_acconto_erar number := 0;
          begin
            w_abitazioni_rec := nvl(w_abitazioni_rec,0);
            update oggetti_imposta
               set imposta               = w_abitazioni_rec
                 , imposta_acconto       = w_acconto_abitazioni_rec
                 , detrazione            = w_detrazioni_rec
                 , detrazione_acconto    = w_acconto_detrazioni_rec
             where oggetto_imposta       = rec_ogco.oggetto_imposta
             ;
            w_perc_occupante_ricalcolo := w_perc_occupante;
            if f_ricalcolo_tasi_per_affitto(w_tipo_tributo,
                                            rec_ogco.tipo_rapporto,
                                            rec_ogco.oggetto,
                                            rec_ogco.flag_al_ridotta,
                                            'N',
                                            w_cod_fiscale,
                                            w_anno,
                                            w_perc_occupante_ricalcolo,
                                            w_abitazioni_rec,
                                            w_acconto_abitazioni_rec,
                                            w_fittizia_erar,
                                            w_fittizia_acconto_erar) then
               update oggetti_imposta
                  set imposta_pre_perc            = imposta
                     ,imposta_acconto_pre_perc    = imposta_acconto
                     ,percentuale                 = w_perc_occupante_ricalcolo
                     ,tipo_rapporto               = rec_ogco.tipo_rapporto
                     ,imposta                     = w_abitazioni_rec
                     ,imposta_acconto             = w_acconto_abitazioni_rec
                where oggetto_imposta   = rec_ogco.oggetto_imposta
                ;
            end if;
            w_acconto_pertinenze := nvl(w_acconto_pertinenze,0) +
                                    nvl(w_acconto_abitazioni_rec,0);
            w_acconto_detrazioni := nvl(w_acconto_detrazioni,0) +
                                    nvl(w_acconto_detrazioni_rec,0);
            w_saldo_pertinenze   := nvl(w_saldo_pertinenze,0) +
                                    nvl(w_abitazioni_rec,0)   -
                                    nvl(w_acconto_abitazioni_rec,0);
            w_saldo_detrazioni   := nvl(w_saldo_detrazioni,0) +
                                    nvl(w_detrazioni_rec,0)   -
                                    nvl(w_acconto_detrazioni_rec,0);
            w_diff_acconto_det   := nvl(w_diff_acconto_det,0) +
                                    nvl(w_diff_acconto_det_rec,0);
            w_diff_saldo_det     := nvl(w_diff_saldo_det,0) +
                                    nvl(w_diff_detrazioni_rec,0)   -
                                    nvl(w_diff_acconto_det_rec,0);
          exception
             when others then
                w_errore := 'Errore in aggiornamento Oggetti Imposta (AP) pertinenze'||
                            ' ('||sqlerrm||')';
                 raise errore;
          end;
          w_num_fabbricati_altri := w_num_fabbricati_altri + 1;
       else

          -- calcolo aliquota_standard --
          w_acconto_abitazioni_std := 0;
          w_acconto_detrazioni_std := 0;
          w_saldo_abitazioni_std   := nvl(w_saldo_abitazioni_std,0) +
                                      nvl(w_abitazioni_std_rec,0)   -
                                      nvl(w_acconto_abitazioni_std_rec,0);
          w_saldo_detrazioni_std   := nvl(w_saldo_detrazioni_std,0) +
                                      nvl(w_detrazioni_std_rec,0)   -
                                      nvl(w_acconto_detrazioni_std_rec,0);
          w_diff_acconto_std_det   := 0;
          w_diff_saldo_std_det     := nvl(w_diff_saldo_std_det,0) +
                                      nvl(w_diff_detrazioni_std_rec,0)   -
                                      nvl(w_diff_acconto_det_std_rec,0);

          if nvl(a_tipo_calcolo,' ') = 'Mini' then
             begin
               update oggetti_imposta
                  set imposta            = round( (nvl(w_abitazioni_rec,0) - nvl(w_abitazioni_std_rec,0)) * 0.4 ,2)
                    , imposta_acconto    = null
--                        , detrazione         = w_detrazioni_std_rec
--                        , detrazione_std     = w_saldo_detrazioni_std   (VD - 09/05/2015)
                    , detrazione_std     = w_detrazioni_std_rec        -- (VD - 09/05/2015)
                    , detrazione_acconto = null
                    , imposta_aliquota   = nvl(w_abitazioni_rec,0)
                    , imposta_std        = nvl(w_abitazioni_std_rec,0)
                    , imposta_mini       = round( (nvl(w_abitazioni_rec,0) - nvl(w_abitazioni_std_rec,0)) * 0.4 ,2)
                where oggetto_imposta    = rec_ogco.oggetto_imposta
                ;
             exception
               when others then
                 w_errore := 'Errore in aggiornamento Oggetti Imposta (AP)'||
                             ' ('||sqlerrm||')';
                 raise errore;
             end;
          elsif rec_ogco.aliquota_std_ogim is not null then
             begin
               update oggetti_imposta
                  set imposta            = 0
                    , imposta_acconto    = null
--                        , detrazione         = w_detrazioni_std_rec
                    , detrazione_acconto = null
                where oggetto_imposta    = rec_ogco.oggetto_imposta
                ;
             exception
               when others then
                 w_errore := 'Errore in aggiornamento Oggetti Imposta (AP)'||
                             ' ('||sqlerrm||')';
                 raise errore;
             end;

             w_abitazioni_rec         := 0;
             w_detrazioni_rec         := 0;
             w_acconto_abitazioni_rec := 0;
             w_acconto_detrazioni_rec := 0;
             w_diff_detrazioni_rec    := 0;
             w_diff_acconto_det_rec   := 0;
          else
             -- (VD - 27/10/2020): Calcolo importo IMU a saldo come da
             --                    D.L. 14 agosto 2020, n. 104
             w_note_saldo := null;
             CALCOLO_IMU_SALDO ( w_tipo_tributo
                               , w_anno
                               , rec_ogco.tipo_aliquota_ogim
                               , nvl(w_abitazioni_rec,0)
                               , w_acconto_abitazioni_rec
                               , to_number(null)
                               , to_number(null)
                               , w_perc_saldo
                               , w_imposta_saldo
                               , w_imposta_saldo_erar
                               , w_note_saldo
                               );
             if w_perc_saldo is not null then
                w_abitazioni_rec := w_imposta_saldo;
             end if;
             declare
               w_fittizia_erar         number := 0;
               w_fittizia_acconto_erar number := 0;
             begin
               update oggetti_imposta
                  set imposta            = nvl(w_abitazioni_rec,0)
                    , imposta_acconto    = w_acconto_abitazioni_rec
                    , detrazione         = w_detrazioni_rec
                    , detrazione_acconto = w_acconto_detrazioni_rec
                    , note               = w_note_saldo
                where oggetto_imposta    = rec_ogco.oggetto_imposta
               ;
--                   w_abitazioni_rec := nvl(w_abitazioni_rec,0);
--                   update oggetti_imposta
--                      set imposta               = w_abitazioni_rec
--                        , imposta_acconto       = w_acconto_abitazioni_rec
--                        , detrazione            = w_detrazioni_rec
--                        , detrazione_acconto    = w_acconto_detrazioni_rec
--                    where oggetto_imposta       = rec_ogco.oggetto_imposta
--                   ;
               w_perc_occupante_ricalcolo := w_perc_occupante;
               if f_ricalcolo_tasi_per_affitto(w_tipo_tributo,
                                               rec_ogco.tipo_rapporto,
                                               rec_ogco.oggetto,
                                               rec_ogco.flag_al_ridotta,
                                               'N',
                                               w_cod_fiscale,
                                               w_anno,
                                               w_perc_occupante_ricalcolo,
                                               w_abitazioni_rec,
                                               w_acconto_abitazioni_rec,
                                               w_fittizia_erar,
                                               w_fittizia_acconto_erar) then
                  update oggetti_imposta
                     set imposta_pre_perc            = imposta
                        ,imposta_acconto_pre_perc    = imposta_acconto
                        ,percentuale                 = w_perc_occupante_ricalcolo
                        ,tipo_rapporto               = rec_ogco.tipo_rapporto
                        ,imposta                     = w_abitazioni_rec
                        ,imposta_acconto             = w_acconto_abitazioni_rec
                   where oggetto_imposta   = rec_ogco.oggetto_imposta
                   ;
               end if;
             exception
                when others then
                    w_errore := 'Errore in aggiornamento Oggetti Imposta (AP)'||
                                ' ('||SQLERRM||')';
                     raise errore;
             end;
          end if;
          w_num_fabbricati_ab := w_num_fabbricati_ab + 1;
          w_acconto_abitazioni := nvl(w_acconto_abitazioni,0) +
                                  nvl(w_acconto_abitazioni_rec,0);
          w_acconto_detrazioni := nvl(w_acconto_detrazioni,0) +
                                  nvl(w_acconto_detrazioni_rec,0);
          w_saldo_abitazioni   := nvl(w_saldo_abitazioni,0) +
                                  nvl(w_abitazioni_rec,0)   -
                                  nvl(w_acconto_abitazioni_rec,0);
          w_saldo_detrazioni   := nvl(w_saldo_detrazioni,0) +
                                  nvl(w_detrazioni_rec,0)   -
                                  nvl(w_acconto_detrazioni_rec,0);
          w_diff_acconto_det   := nvl(w_diff_acconto_det,0) +
                                  nvl(w_diff_acconto_det_rec,0);
          w_diff_saldo_det     := nvl(w_diff_saldo_det,0) +
                                  nvl(w_diff_detrazioni_rec,0)   -
                                  nvl(w_diff_acconto_det_rec,0);
       end if;

       w_abitazioni_rec         := 0;
       w_detrazioni_rec         := 0;
       w_acconto_abitazioni_rec := 0;
       w_acconto_detrazioni_rec := 0;
       w_diff_detrazioni_rec    := 0;
       w_diff_acconto_det_rec   := 0;

       w_abitazioni_std_rec         := 0;
       w_detrazioni_std_rec         := 0;
       w_acconto_abitazioni_std_rec := 0;
       w_acconto_detrazioni_std_rec := 0;
       w_diff_detrazioni_std_rec    := 0;
       w_diff_acconto_det_std_rec   := 0;
    elsif
       --- RURALI ---
       rec_ogco.tipo_oggetto in (3,55)         and
       rec_ogco.flag_ab_principale is null     and
       rec_ogco.aliquota_erariale_ogim is null and
       -- (VD - 07/08/2020): Si escludono i fabbricati merce
       w_flag_fabb_merce is null               and
       w_anno >= 2012 then
       wf := 7;
       begin
         select ((((((((w_valore
                         * rec_ogco.aliquota_ogim) / 1000)
                         / decode(rec_ogco.flag_riduzione,'S',2
                                 ,decode(rec_ogco.imm_storico||to_char(sign(rec_ogco.anno_ogco - 2011))
                                        ,'S1',2
                                        ,1)
                                 )
                            )
                         * rec_ogco.perc_possesso) / 100)
                         * rec_ogco.mesi_possesso) / 12)
       -- (VD - 16/05/2015): Modifiche 2016. Si applica la percentuale di
       --                    riduzione dell'imposta
                         * w_riduzione_imp / 100)
           into w_rurali_rec
           from dual
           ;

           select ((((((((w_valore
                           * rec_ogco.aliquota_prec_ogpr) / 1000)
                           / decode(rec_ogco.flag_riduzione,'S',2
                                   ,decode(rec_ogco.imm_storico||to_char(sign(rec_ogco.anno_ogco - 2011))
                                          ,'S1',2
                                          ,1)
                                   )
                               )
                           * rec_ogco.perc_possesso) / 100)
                           * nvl(rec_ogco.mesi_possesso_1sem,0) / 12)
       -- (VD - 16/05/2015): Modifiche 2016. Si applica la percentuale di
       --                    riduzione dell'imposta
                           * w_riduzione_imp) / 100)
             into w_acconto_rurali_rec
             from dual
             ;
       exception
         when others then
           null;
       end;

       w_rurali_rec         := nvl(f_round(w_rurali_rec,0),0);
       w_acconto_rurali_rec := f_round(w_acconto_rurali_rec,0);
       if nvl(a_tipo_calcolo,' ') = 'Mini' then
          begin
             update oggetti_imposta
                set imposta           = 0
                   ,imposta_acconto   = null
              where oggetto_imposta   = rec_ogco.oggetto_imposta
                    ;
          exception
             when others then
                w_errore := 'Errore in aggiornamento Oggetti Imposta (rurali)'||
                            ' ('||sqlerrm||')';
                raise errore;
          end;
          w_rurali_rec         := 0;
          w_acconto_rurali_rec := 0;
       else
          -- (VD - 27/10/2020): Calcolo importo IMU a saldo come da
          --                    D.L. 14 agosto 2020, n. 104
          w_note_saldo := null;
          CALCOLO_IMU_SALDO ( w_tipo_tributo
                            , w_anno
                            , rec_ogco.tipo_aliquota_ogim
                            , w_rurali_rec
                            , w_acconto_rurali_rec
                            , to_number(null)
                            , to_number(null)
                            , w_perc_saldo
                            , w_imposta_saldo
                            , w_imposta_saldo_erar
                            , w_note_saldo
                            );
          if w_perc_saldo is not null then
             w_rurali_rec := w_imposta_saldo;
          end if;
          declare
            w_fittizia_erar number := 0;
            w_acconto_fittizia_erar number := 0;
          begin
            update oggetti_imposta
               set imposta           = w_rurali_rec
                  ,imposta_acconto   = w_acconto_rurali_rec
                  ,note              = w_note_saldo
             where oggetto_imposta   = rec_ogco.oggetto_imposta
             ;
             w_perc_occupante_ricalcolo := w_perc_occupante;
             if f_ricalcolo_tasi_per_affitto(w_tipo_tributo,
                                             rec_ogco.tipo_rapporto,
                                             rec_ogco.oggetto,
                                             rec_ogco.flag_al_ridotta,
                                             'N',
                                             w_cod_fiscale,
                                             w_anno,
                                             w_perc_occupante_ricalcolo,
                                             w_rurali_rec,
                                             w_acconto_rurali_rec,
                                             w_fittizia_erar,
                                             w_acconto_fittizia_erar) then
                update oggetti_imposta
                   set imposta_pre_perc            = imposta
                      ,imposta_acconto_pre_perc    = imposta_acconto
                      ,percentuale                 = w_perc_occupante_ricalcolo
                      ,tipo_rapporto               = rec_ogco.tipo_rapporto
                      ,imposta                     = w_rurali_rec
                      ,imposta_acconto             = w_acconto_rurali_rec
                 where oggetto_imposta   = rec_ogco.oggetto_imposta
                 ;
              end if;
          exception
             when others then
                w_errore := 'Errore in aggiornamento Oggetti Imposta (rurali)'||
                            ' ('||sqlerrm||')';
                raise errore;
          end;
       end if;
       w_num_fabbricati_rurali := w_num_fabbricati_rurali + 1;
       w_acconto_rurali     := nvl(w_acconto_rurali,0) +
                               nvl(w_acconto_rurali_rec,0);
       w_saldo_rurali       := nvl(w_saldo_rurali,0) +
                               nvl(w_rurali_rec,0)    -
                               nvl(w_acconto_rurali_rec,0);
       w_rurali_rec         := 0;
       w_acconto_rurali_rec := 0;
    elsif
      -- FABBRICATI AD USO PRODUTTIVO --
       rec_ogco.tipo_aliquota_ogim = 9           and
       rec_ogco.categoria_catasto_ogpr like 'D%' and
       w_anno >= 2013                            and
       w_tipo_tributo = 'ICI' then
       BEGIN
         select f_round((((((((w_valore
                         * rec_ogco.aliquota_ogim) / 1000)
                         / decode(rec_ogco.flag_riduzione,'S',2
                                 ,decode(rec_ogco.imm_storico||to_char(sign(rec_ogco.anno_ogco - 2011))
                                        ,'S1',2
                                        ,1)
                                 )
                            )
                         * rec_ogco.perc_possesso) / 100)
                         * rec_ogco.mesi_possesso) / 12),0)
           into w_uso_prod_rec
           from dual
           ;

         select f_round(((((((((w_valore
                         * rec_ogco.aliquota_prec_ogpr) / 1000)
                         / decode(rec_ogco.flag_riduzione,'S',2
                                 ,decode(rec_ogco.imm_storico||to_char(sign(rec_ogco.anno_ogco - 2011))
                                        ,'S1',2
                                        ,1)
                                 )
                             )
                         * rec_ogco.perc_possesso) / 100)
                         * nvl(rec_ogco.mesi_possesso_1sem,0) / 12)
                         * 100) / 100),0)
           into w_acconto_uso_prod_rec
           from dual
           ;

       exception
         when others then
           null;
       end;

       if f_round(w_acconto_uso_prod_rec,0) > f_round(w_uso_prod_rec,0) then
          w_acconto_uso_prod_rec := w_uso_prod_rec;
       end if;
       -- Calcolo Erariale --
       begin
         select f_round(((((((((w_valore
                         * rec_ogco.aliquota_erariale_ogim) / 1000)
                         / decode(rec_ogco.flag_riduzione,'S',2
                                 ,decode(rec_ogco.imm_storico||to_char(sign(rec_ogco.anno_ogco - 2011))
                                        ,'S1',2
                                        ,1)
                                 )
                             )
                         * rec_ogco.perc_possesso) / 100)
                         * nvl(rec_ogco.mesi_possesso,0) / 12)
                         * 100) / 100),0)
           into w_uso_prod_erar_rec
           from dual
           ;

         select f_round(((((((((w_valore
                         * rec_ogco.aliquota_erar_prec) / 1000)
                         / decode(rec_ogco.flag_riduzione,'S',2
                                 ,decode(rec_ogco.imm_storico||to_char(sign(rec_ogco.anno_ogco - 2011))
                                        ,'S1',2
                                        ,1)
                                 )
                             )
                         * rec_ogco.perc_possesso) / 100)
                         * nvl(rec_ogco.mesi_possesso_1sem,0) / 12)
                         * 100) / 100),0)
           into w_acconto_uso_prod_erar_rec
           from dual
           ;
       exception
          when others then
            null;
       end;

--         w_uso_prod_rec         := f_round(w_uso_prod_rec,0);
--         w_acconto_uso_prod_rec := f_round(w_acconto_uso_prod_rec,0);
--         w_acconto_uso_prod     := nvl(w_acconto_uso_prod,0) +
--                                   nvl(w_acconto_uso_prod_rec,0);
--         w_saldo_uso_prod       := nvl(w_saldo_uso_prod,0) +
--                                   nvl(w_uso_prod_rec,0)    -
--                                   nvl(w_acconto_uso_prod_rec,0);
--
--         w_uso_prod_erar_rec    := round(w_uso_prod_erar_rec,2);
--         w_acconto_uso_prod_erar_rec := round(w_acconto_uso_prod_erar_rec,2);
--         w_acconto_uso_prod_erar := nvl(w_acconto_uso_prod_erar,0) +
--                                   nvl(w_acconto_uso_prod_erar_rec,0);
--         w_saldo_uso_prod_erar   := nvl(w_saldo_uso_prod_erar,0) +
--                                   nvl(w_uso_prod_erar_rec,0) -
--                                   nvl(w_acconto_uso_prod_erar_rec,0);
       if nvl(a_tipo_calcolo,' ') = 'Mini' then
          if rec_ogco.aliquota_std_ogim is null then
             begin
               update oggetti_imposta
                  set imposta           = 0
                     ,imposta_acconto   = null
                     ,imposta_erariale          = null
                     ,imposta_erariale_acconto  = null
                where oggetto_imposta   = rec_ogco.oggetto_imposta
                ;
             exception
               when others then
                 w_errore := 'Errore in aggiornamento Oggetti Imposta (Fabb.D - Mini IMU)'||
                             ' ('||sqlerrm||')';
                 raise errore;
             end;
             w_num_fabbricati_uso_prod := w_num_fabbricati_uso_prod - 1;
             w_uso_prod_rec         := 0;
             w_acconto_uso_prod_rec := 0;
             w_uso_prod_erar_rec         := 0;
             w_acconto_uso_prod_erar_rec := 0;
             w_uso_prod_std_rec          := 0;
             w_acconto_uso_prod_std_rec  := 0;
          else
             w_uso_prod_rec         := f_round(w_uso_prod_rec,0);
             w_acconto_uso_prod_rec := f_round(w_acconto_uso_prod_rec,0);
             w_acconto_uso_prod     := nvl(w_acconto_uso_prod,0) +
                                       nvl(w_acconto_uso_prod_rec,0);
             w_saldo_uso_prod       := nvl(w_saldo_uso_prod,0) +
                                       nvl(w_uso_prod_rec,0)    -
                                       nvl(w_acconto_uso_prod_rec,0);

             w_uso_prod_erar_rec    := round(w_uso_prod_erar_rec,2);
             w_acconto_uso_prod_erar_rec := 0;
             w_acconto_uso_prod_erar := 0;
             w_saldo_uso_prod_erar   := nvl(w_saldo_uso_prod_erar,0) +
                                        nvl(w_uso_prod_erar_rec,0) -
                                        nvl(w_acconto_uso_prod_erar_rec,0);

             w_uso_prod_std_rec         := round(w_uso_prod_std_rec,2);
             w_acconto_uso_prod_std_rec := round(w_acconto_uso_prod_std_rec,2);
             w_acconto_uso_prod_std     := nvl(w_acconto_uso_prod_std,0) +
                                           nvl(w_acconto_uso_prod_std_rec,0);
             w_saldo_uso_prod_std       := nvl(w_saldo_uso_prod_std,0) +
                                           nvl(w_uso_prod_std_rec,0) -
                                           nvl(w_acconto_uso_prod_std_rec,0);
             begin
                update oggetti_imposta
                   set imposta           = round( (nvl(w_uso_prod_rec,0) - nvl(w_uso_prod_std_rec,0)) * 0.4  ,2)
                      ,imposta_acconto   = null
                      ,imposta_erariale          = null
                      ,imposta_erariale_acconto  = null
                 where oggetto_imposta   = rec_ogco.oggetto_imposta
                       ;
             exception
                when others then
                   w_errore := 'Errore in aggiornamento Oggetti Imposta (Fabb.D - Mini IMU 2)'||
                               ' ('||sqlerrm||')';
                   raise errore;
             end;
          end if;
       else
          w_uso_prod_rec         := nvl(f_round(w_uso_prod_rec,0),0);
          w_acconto_uso_prod_rec := f_round(w_acconto_uso_prod_rec,0);
          -- (VD - 27/10/2020): Calcolo importo IMU a saldo come da
          --                    D.L. 14 agosto 2020, n. 104
          w_note_saldo := null;
          CALCOLO_IMU_SALDO ( w_tipo_tributo
                            , w_anno
                            , rec_ogco.tipo_aliquota_ogim
                            , w_uso_prod_rec
                            , w_acconto_uso_prod_rec
                            , nvl(w_uso_prod_erar_rec,0)
                            , w_acconto_uso_prod_erar_rec
                            , w_perc_saldo
                            , w_imposta_saldo
                            , w_imposta_saldo_erar
                            , w_note_saldo
                            );
          if w_perc_saldo is not null then
             w_uso_prod_rec      := w_imposta_saldo;
             w_uso_prod_erar_rec := w_imposta_saldo_erar;
          end if;
          begin
            update oggetti_imposta
               set imposta           = nvl(w_uso_prod_rec,0)
                  ,imposta_acconto   = w_acconto_uso_prod_rec
                  ,imposta_erariale          = nvl(w_uso_prod_erar_rec,0)
                  ,imposta_erariale_acconto  = w_acconto_uso_prod_erar_rec
                  ,note              = w_note_saldo
             where oggetto_imposta   = rec_ogco.oggetto_imposta
             ;
             w_perc_occupante_ricalcolo := w_perc_occupante;
             if f_ricalcolo_tasi_per_affitto(w_tipo_tributo,
                                             rec_ogco.tipo_rapporto,
                                             rec_ogco.oggetto,
                                             rec_ogco.flag_al_ridotta,
                                             'N',
                                             w_cod_fiscale,
                                             w_anno,
                                             w_perc_occupante_ricalcolo,
                                             w_uso_prod_rec,
                                             w_acconto_uso_prod_rec,
                                             w_uso_prod_erar_rec,
                                             w_acconto_uso_prod_erar_rec) then
                update oggetti_imposta
                   set imposta_pre_perc            = imposta
                      ,imposta_acconto_pre_perc    = imposta_acconto
                      ,percentuale                 = w_perc_occupante_ricalcolo
                      ,tipo_rapporto               = rec_ogco.tipo_rapporto
                      ,imposta                     = w_uso_prod_rec
                      ,imposta_acconto             = w_acconto_uso_prod_rec
                      ,imposta_erariale            = w_uso_prod_erar_rec
                      ,imposta_erariale_acconto    = w_acconto_uso_prod_erar_rec
                 where oggetto_imposta   = rec_ogco.oggetto_imposta
                 ;
             end if;
          exception
            when others then
              w_errore := 'Errore in aggiornamento Oggetti Imposta (Fabb.D)'||
                          ' ('||SQLERRM||')';
              raise errore;
          end;
       end if;
       w_num_fabbricati_uso_prod := w_num_fabbricati_uso_prod + 1;
       w_acconto_uso_prod     := nvl(w_acconto_uso_prod,0) +
                                 nvl(w_acconto_uso_prod_rec,0);
       w_saldo_uso_prod       := nvl(w_saldo_uso_prod,0) +
                                 nvl(w_uso_prod_rec,0)    -
                                 nvl(w_acconto_uso_prod_rec,0);

       w_uso_prod_erar_rec    := round(w_uso_prod_erar_rec,2);
       w_acconto_uso_prod_erar_rec := round(w_acconto_uso_prod_erar_rec,2);
       w_acconto_uso_prod_erar := nvl(w_acconto_uso_prod_erar,0) +
                                  nvl(w_acconto_uso_prod_erar_rec,0);
       w_saldo_uso_prod_erar   := nvl(w_saldo_uso_prod_erar,0) +
                                  nvl(w_uso_prod_erar_rec,0) -
                                  nvl(w_acconto_uso_prod_erar_rec,0);
       w_uso_prod_rec         := 0;
       w_acconto_uso_prod_rec := 0;
       w_uso_prod_erar_rec         := 0;
       w_acconto_uso_prod_erar_rec := 0;
       w_uso_prod_std_rec          := 0;
       w_acconto_uso_prod_std_rec  := 0;
    elsif
      -- Altri fabbricati
       rec_ogco.tipo_oggetto in (3,55)       and
       rec_ogco.flag_ab_principale is null   and
       rec_ogco.aliquota_erariale_ogim is not null and
       -- (VD - 07/08/2020): Si escludono i fabbricati merce
       w_flag_fabb_merce is null THEN
       wf := 7;
       begin
         select ((((((((w_valore
                         * rec_ogco.aliquota_ogim) / 1000)
                         / decode(rec_ogco.flag_riduzione,'S',2
                                 ,decode(rec_ogco.imm_storico||to_char(sign(rec_ogco.anno_ogco - 2011))
                                        ,'S1',2
                                        ,1)
                                 )
                            )
                         * rec_ogco.perc_possesso) / 100)
                         * rec_ogco.mesi_possesso) / 12)
                         * w_riduzione_imp / 100)
           into w_altri_rec
           from dual
           ;

         if rec_ogco.anno_ogco <= 2000 then
            -- (VD - 16/05/2015) Modifiche 2016: non si applica la riduzione
            --                   negli anni <= 2000
            select ((((((((w_valore
                            * rec_ogco.aliquota_ogim) / 1000)
                            / decode(rec_ogco.flag_riduzione,'S',2,1))
                            * rec_ogco.perc_possesso) / 100)
                            * nvl(rec_ogco.mesi_possesso_1sem,0) / 12)
                            * 90) / 100)
               into w_acconto_altri_rec
              from dual
              ;
         else
            select ((((((((w_valore
                            * rec_ogco.aliquota_prec_ogpr) / 1000)
                            / decode(rec_ogco.flag_riduzione,'S',2
                                    ,decode(rec_ogco.imm_storico||to_char(sign(rec_ogco.anno_ogco - 2011))
                                           ,'S1',2
                                           ,1)
                                    )
                                )
                            * rec_ogco.perc_possesso) / 100)
                            * nvl(rec_ogco.mesi_possesso_1sem,0) / 12)
       -- (VD - 12/05/2015): Nodifiche 2016. Se il tipo_aliquota lo prevede
       --                    si applica la riduzione imposta
                            * w_riduzione_imp) / 100)
              into w_acconto_altri_rec
              from dual
              ;
         end if;
--          exception
--            when others then
--              null;
       end;

       w_altri_rec := f_round(w_altri_rec,0);
       w_acconto_altri_rec := f_round(w_acconto_altri_rec,0);

       if nvl(w_acconto_altri_rec,0) > nvl(w_altri_rec,0) then
          w_acconto_altri_rec := w_altri_rec;
       end if;

       if rec_ogco.anno_ogco >= 2012 then
          select f_round(((((((((w_valore
                          * rec_ogco.aliquota_erariale_ogim) / 1000)
                          / decode(rec_ogco.flag_riduzione,'S',2
                                  ,decode(rec_ogco.imm_storico||to_char(sign(rec_ogco.anno_ogco - 2011))
                                         ,'S1',2
                                         ,1)
                                  )
                              )
                          * rec_ogco.perc_possesso) / 100)
                          * nvl(rec_ogco.mesi_possesso,0) / 12)
                          * 100) / 100),0)
            into w_altri_erar_rec
            from dual
               ;

          select f_round(((((((((w_valore
                          * rec_ogco.aliquota_erar_prec) / 1000)
                          / decode(rec_ogco.flag_riduzione,'S',2
                                  ,decode(rec_ogco.imm_storico||to_char(sign(rec_ogco.anno_ogco - 2011))
                                         ,'S1',2
                                         ,1)
                                  )
                              )
                          * rec_ogco.perc_possesso) / 100)
                          * nvl(rec_ogco.mesi_possesso_1sem,0) / 12)
                          * 100) / 100),0)
            into w_acconto_altri_erar_rec
            from dual
               ;
       end if;

         -- Calcolo con Aliquota Standard --
       if nvl(a_tipo_calcolo,' ') = 'Mini' then
           select f_round((((((((w_valore
                           * rec_ogco.aliquota_std_ogim) / 1000)
                           / decode(rec_ogco.flag_riduzione,'S',2
                                   ,decode(rec_ogco.imm_storico||to_char(sign(rec_ogco.anno_ogco - 2011))
                                          ,'S1',2
                                          ,1)
                                   )
                              )
                           * rec_ogco.perc_possesso) / 100)
                           * rec_ogco.mesi_possesso) / 12),0)
             into w_altri_std_rec
             from dual
             ;
       else
          w_altri_std_rec := 0;
       end if;

       if nvl(a_tipo_calcolo,' ') = 'Mini' then
          if rec_ogco.aliquota_std_ogim is null then
             begin
               update oggetti_imposta
                  set imposta           = 0
                     ,imposta_acconto   = null
                     ,imposta_erariale          = null
                     ,imposta_erariale_acconto  = null
                where oggetto_imposta   = rec_ogco.oggetto_imposta
                ;
             exception
               when others then
                 w_errore := 'Errore in aggiornamento Oggetti Imposta (Altri Fabb. - Mini IMU)'||
                             ' ('||sqlerrm||')';
                 raise errore;
             end;
             w_num_fabbricati_altri := w_num_fabbricati_altri - 1;
             w_altri_rec         := 0;
             w_acconto_altri_rec := 0;
             w_altri_erar_rec         := 0;
             w_acconto_altri_erar_rec := 0;
             w_altri_std_rec          := 0;
             w_acconto_altri_std_rec  := 0;
          else
             w_altri_rec         := f_round(w_altri_rec,0);
             w_acconto_altri_rec := 0;
             w_acconto_altri     := 0;
             w_saldo_altri       := nvl(w_saldo_altri,0) +
                                    nvl(w_altri_rec,0)    -
                                    nvl(w_acconto_altri_rec,0);

             w_altri_erar_rec         := round(w_altri_erar_rec,2);
             w_acconto_altri_erar_rec := round(w_acconto_altri_erar_rec,2);
             w_acconto_altri_erar := nvl(w_acconto_altri_erar,0) +
                                     nvl(w_acconto_altri_erar_rec,0);
             w_saldo_altri_erar   := nvl(w_saldo_altri_erar,0) +
                                     nvl(w_altri_erar_rec,0) -
                                     nvl(w_acconto_altri_erar_rec,0);

             w_altri_std_rec         := round(w_altri_std_rec,2);
             w_acconto_altri_std_rec := 0;
             w_acconto_altri_std := 0;
             w_saldo_altri_std   := nvl(w_saldo_altri_std,0) +
                                    nvl(w_altri_std_rec,0) -
                                    nvl(w_acconto_altri_std_rec,0);

             begin
               update oggetti_imposta
                  set imposta           = round( (nvl(w_altri_rec,0) - nvl(w_altri_std_rec,0)) * 0.4 ,2)
                     ,imposta_acconto   = null
                     ,imposta_erariale          = null
                     ,imposta_erariale_acconto  = null
                where oggetto_imposta   = rec_ogco.oggetto_imposta
                ;
             exception
               when others then
                 w_errore := 'Errore in aggiornamento Oggetti Imposta (Altri Fabb. - Mini IMU 2)'||
                             ' ('||sqlerrm||')';
                 raise errore;
             end;
          end if;
       else
          w_altri_rec         := nvl(f_round(w_altri_rec,0),0);
          w_acconto_altri_rec := f_round(w_acconto_altri_rec,0);
          w_altri_erar_rec         := nvl(round(w_altri_erar_rec,2),0);
          w_acconto_altri_erar_rec := round(w_acconto_altri_erar_rec,2);
          -- (VD - 27/10/2020): Calcolo importo IMU a saldo come da
          --                    D.L. 14 agosto 2020, n. 104
          w_note_saldo := null;
          CALCOLO_IMU_SALDO ( w_tipo_tributo
                            , w_anno
                            , rec_ogco.tipo_aliquota_ogim
                            , w_altri_rec
                            , w_acconto_altri_rec
                            , w_altri_erar_rec
                            , w_acconto_altri_erar_rec
                            , w_perc_saldo
                            , w_imposta_saldo
                            , w_imposta_saldo_erar
                            , w_note_saldo
                            );
          if w_perc_saldo is not null then
             w_altri_rec      := w_imposta_saldo;
             w_altri_erar_rec := w_imposta_saldo_erar;
          end if;
          begin
            update oggetti_imposta
               set imposta           = w_altri_rec
                  ,imposta_acconto   = w_acconto_altri_rec
                  ,imposta_erariale          = w_altri_erar_rec
                  ,imposta_erariale_acconto  = w_acconto_altri_erar_rec
                  ,note              = w_note_saldo
             where oggetto_imposta   = rec_ogco.oggetto_imposta
             ;
            w_perc_occupante_ricalcolo := w_perc_occupante;
            if f_ricalcolo_tasi_per_affitto(w_tipo_tributo,
                                            rec_ogco.tipo_rapporto,
                                            rec_ogco.oggetto,
                                            rec_ogco.flag_al_ridotta,
                                            'N',
                                            w_cod_fiscale,
                                            w_anno,
                                            w_perc_occupante_ricalcolo,
                                            w_altri_rec,
                                            w_acconto_altri_rec,
                                            w_altri_erar_rec,
                                            w_acconto_altri_erar_rec) then
               update oggetti_imposta
                  set imposta_pre_perc            = imposta
                     ,imposta_acconto_pre_perc    = imposta_acconto
                     ,percentuale                 = w_perc_occupante_ricalcolo
                     ,tipo_rapporto               = rec_ogco.tipo_rapporto
                     ,imposta                     = w_altri_rec
                     ,imposta_acconto             = w_acconto_altri_rec
                     ,imposta_erariale            = w_altri_erar_rec
                     ,imposta_erariale_acconto    = w_acconto_altri_erar_rec
               where oggetto_imposta   = rec_ogco.oggetto_imposta
               ;
            end if;
          exception
             when others then
                w_errore := 'Errore in aggiornamento Oggetti Imposta (Altri Fabb. - IMU)'||
                            ' ('||sqlerrm||')';
                raise errore;
          end;
       end if;
       w_num_fabbricati_altri := w_num_fabbricati_altri + 1;
       w_acconto_altri     := nvl(w_acconto_altri,0) +
                              nvl(w_acconto_altri_rec,0);
       w_saldo_altri       := nvl(w_saldo_altri,0) +
                              nvl(w_altri_rec,0)    -
                              nvl(w_acconto_altri_rec,0);
       w_acconto_altri_erar := nvl(w_acconto_altri_erar,0) +
                               nvl(w_acconto_altri_erar_rec,0);
       w_saldo_altri_erar   := nvl(w_saldo_altri_erar,0) +
                               nvl(w_altri_erar_rec,0) -
                               nvl(w_acconto_altri_erar_rec,0);
       w_altri_rec         := 0;
       w_acconto_altri_rec := 0;
       w_altri_erar_rec         := 0;
       w_acconto_altri_erar_rec := 0;
       w_altri_std_rec          := 0;
       w_acconto_altri_std_rec  := 0;
    elsif
       --- FABBRICATI MERCE ---
       w_tipo_tributo = 'ICI'                     and
       rec_ogco.tipo_oggetto in (3,55)            and
       rec_ogco.flag_ab_principale is null        and
       nvl(rec_ogco.aliquota_erariale_ogim,0) = 0 and
       -- (VD - 07/08/2020): Si trattano i fabbricati merce
       w_flag_fabb_merce is not null              and
       w_anno >= 2020 then
       wf := 7;
       begin
         select ((((((((w_valore
                         * rec_ogco.aliquota_ogim) / 1000)
                         / decode(rec_ogco.flag_riduzione,'S',2
                                 ,decode(rec_ogco.imm_storico||to_char(sign(rec_ogco.anno_ogco - 2011))
                                        ,'S1',2
                                        ,1)
                                 )
                            )
                         * rec_ogco.perc_possesso) / 100)
                         * rec_ogco.mesi_possesso) / 12)
       -- (VD - 16/05/2015): Modifiche 2016. Si applica la percentuale di
       --                    riduzione dell'imposta
                         * w_riduzione_imp / 100)
           into w_fabb_merce_rec
           from dual
           ;

           select ((((((((w_valore
                           * rec_ogco.aliquota_prec_ogpr) / 1000)
                           / decode(rec_ogco.flag_riduzione,'S',2
                                   ,decode(rec_ogco.imm_storico||to_char(sign(rec_ogco.anno_ogco - 2011))
                                          ,'S1',2
                                          ,1)
                                   )
                               )
                           * rec_ogco.perc_possesso) / 100)
                           * nvl(rec_ogco.mesi_possesso_1sem,0) / 12)
       -- (VD - 16/05/2015): Modifiche 2016. Si applica la percentuale di
       --                    riduzione dell'imposta
                           * w_riduzione_imp) / 100)
             into w_acconto_fabb_merce_rec
             from dual
             ;
       exception
         when others then
           null;
       end;

       w_fabb_merce_rec         := nvl(f_round(w_fabb_merce_rec,0),0);
       w_acconto_fabb_merce_rec := f_round(w_acconto_fabb_merce_rec,0);
       -- (VD - 27/10/2020): Calcolo importo IMU a saldo come da
       --                    D.L. 14 agosto 2020, n. 104
       w_note_saldo := null;
       CALCOLO_IMU_SALDO ( w_tipo_tributo
                         , w_anno
                         , rec_ogco.tipo_aliquota_ogim
                         , w_fabb_merce_rec
                         , w_acconto_fabb_merce_rec
                         , to_number(null)
                         , to_number(null)
                         , w_perc_saldo
                         , w_imposta_saldo
                         , w_imposta_saldo_erar
                         , w_note_saldo
                         );
       if w_perc_saldo is not null then
          w_fabb_merce_rec  := w_imposta_saldo;
       end if;
       begin
         update oggetti_imposta
            set imposta           = w_fabb_merce_rec
               ,imposta_acconto   = w_acconto_fabb_merce_rec
               ,note              = w_note_saldo
          where oggetto_imposta   = rec_ogco.oggetto_imposta
          ;

       exception
          when others then
             w_errore := 'Errore in aggiornamento Oggetti Imposta (Fabb.Merce)'||
                         ' ('||sqlerrm||')';
             raise errore;
       end;
       w_num_fabbricati_merce := w_num_fabbricati_merce + 1;
       w_acconto_fabb_merce := nvl(w_acconto_fabb_merce,0) +
                               nvl(w_acconto_fabb_merce_rec,0);
       w_saldo_fabb_merce   := nvl(w_saldo_fabb_merce,0) +
                               nvl(w_fabb_merce_rec,0)    -
                               nvl(w_acconto_fabb_merce_rec,0);
       w_fabb_merce_rec         := 0;
       w_acconto_fabb_merce_rec := 0;
    else
       -- Altri fabbricati 2
       wf := 8;
       begin
         select ((((((((w_valore
                         * rec_ogco.aliquota_ogim) / 1000)
                         / decode(rec_ogco.flag_riduzione,'S',2
                                 ,decode(rec_ogco.imm_storico||to_char(sign(rec_ogco.anno_ogco - 2011))
                                        ,'S1',2
                                        ,1)
                                 )
                            )
                         * rec_ogco.perc_possesso) / 100)
                         * rec_ogco.mesi_possesso) / 12)
                         * w_riduzione_imp / 100)
           into w_altri_rec
           from dual
           ;
         if rec_ogco.anno_ogco <= 2000 then
            -- (VD - 16/05/2015) Modifiche 2016: non si applica la riduzione
            --                   negli anni <= 2000
            select (((((((((w_valore
                           * rec_ogco.aliquota_ogim) / 1000)
                           / decode(rec_ogco.flag_riduzione,'S',2,1))
                           * rec_ogco.perc_possesso) / 100)
                           * nvl(rec_ogco.mesi_possesso_1sem,0)) / 12)
                           * 90) / 100)
              into w_acconto_altri_rec
              from dual
              ;
         else
            select ((((((((((w_valore
                            * rec_ogco.aliquota_prec_ogpr) / 1000)
                            / decode(rec_ogco.flag_riduzione,'S',2
                                    ,decode(rec_ogco.imm_storico||to_char(sign(rec_ogco.anno_ogco - 2011))
                                        ,'S1',2
                                        ,1)
                                    )
                                 )
                            * rec_ogco.perc_possesso) / 100)
                            * nvl(rec_ogco.mesi_possesso_1sem,0)) / 12)
                            * 100) / 100)
       -- (VD - 12/05/2015): Nodifiche 2016. Se il tipo_aliquota lo prevede
       --                    si applica la riduzione imposta
                            * w_riduzione_imp / 100)
              into w_acconto_altri_rec
              from dual
              ;
         end if;
       exception
          when others then
            null;
       end;

       w_altri_rec := f_round(w_altri_rec,0);
       w_acconto_altri_rec := f_round(w_acconto_altri_rec,0);

       if nvl(w_acconto_altri_rec,0) > nvl(w_altri_rec,0) then
          w_acconto_altri_rec := w_altri_rec;
       end if;

       if rec_ogco.anno_ogco >= 2012 then
          select f_round(((((((((w_valore
                          * rec_ogco.aliquota_erariale_ogim) / 1000)
                          / decode(rec_ogco.flag_riduzione,'S',2
                                  ,decode(rec_ogco.imm_storico||to_char(sign(rec_ogco.anno_ogco - 2011))
                                         ,'S1',2
                                         ,1)
                                  )
                              )
                          * rec_ogco.perc_possesso) / 100)
                          * nvl(rec_ogco.mesi_possesso,0) / 12)
                          * 100) / 100),0)
            into w_altri_erar_rec
            from dual
               ;

          select f_round(((((((((w_valore
                          * rec_ogco.aliquota_erar_prec) / 1000)
                          / decode(rec_ogco.flag_riduzione,'S',2
                                  ,decode(rec_ogco.imm_storico||to_char(sign(rec_ogco.anno_ogco - 2011))
                                         ,'S1',2
                                         ,1)
                                  )
                              )
                          * rec_ogco.perc_possesso) / 100)
                          * nvl(rec_ogco.mesi_possesso_1sem,0) / 12)
                          * 100) / 100),0)
            into w_acconto_altri_erar_rec
            from dual
               ;
       end if;

       -- Calcolo con Aliquota Standard --
       if nvl(a_tipo_calcolo,' ') = 'Mini' then
          select f_round((((((((w_valore
                          * rec_ogco.aliquota_std_ogim) / 1000)
                          / decode(rec_ogco.flag_riduzione,'S',2
                                  ,decode(rec_ogco.imm_storico||to_char(sign(rec_ogco.anno_ogco - 2011))
                                         ,'S1',2
                                         ,1)
                                  )
                             )
                          * rec_ogco.perc_possesso) / 100)
                          * rec_ogco.mesi_possesso) / 12),0)
            into w_altri_std_rec
            from dual
            ;
       else
          w_altri_std_rec := 0;
       end if;

       if nvl(a_tipo_calcolo,' ') = 'Mini' then
          if rec_ogco.aliquota_std_ogim is null then
             begin
               update oggetti_imposta
                  set imposta           = 0
                     ,imposta_acconto   = null
                     ,imposta_erariale          = null
                     ,imposta_erariale_acconto  = null
                where oggetto_imposta   = rec_ogco.oggetto_imposta
                      ;
             exception
                when others then
                   w_errore := 'Errore in aggiornamento Oggetti Imposta (Altri Fabb.2 - Mini IMU)'||
                               ' ('||sqlerrm||')';
                   raise errore;
             end;
             w_num_fabbricati_altri   := w_num_fabbricati_altri - 1;
             w_altri_rec              := 0;
             w_acconto_altri_rec      := 0;
             w_altri_erar_rec         := 0;
             w_acconto_altri_erar_rec := 0;
             w_altri_std_rec          := 0;
             w_acconto_altri_std_rec  := 0;
          else
             w_altri_rec         := f_round(w_altri_rec,0);
             w_acconto_altri_rec := f_round(w_acconto_altri_rec,0);
             w_acconto_altri     := nvl(w_acconto_altri,0) +
                                    nvl(w_acconto_altri_rec,0);
             w_saldo_altri   := nvl(w_saldo_altri,0) +
                                nvl(w_altri_rec,0)     -
                                nvl(w_acconto_altri_rec,0);

             w_altri_erar_rec         := round(w_altri_erar_rec,2);
             w_acconto_altri_erar_rec := 0;
             w_acconto_altri_erar := 0;
             w_saldo_altri_erar   := nvl(w_saldo_altri_erar,0) +
                                       nvl(w_altri_erar_rec,0) -
                                       nvl(w_acconto_altri_erar_rec,0);

             w_altri_std_rec         := round(w_altri_std_rec,2);
             w_acconto_altri_std_rec := 0;
             w_acconto_altri_std := 0;
             w_saldo_altri_std   := nvl(w_saldo_altri_std,0) +
                                       nvl(w_altri_std_rec,0) -
                                       nvl(w_acconto_altri_std_rec,0);

             begin
               update oggetti_imposta
                  set imposta           = round( (nvl(w_altri_rec,0) - nvl(w_altri_std_rec,0)) * 0.4 ,2)
                     ,imposta_acconto   = null
                     ,imposta_erariale          = null
                     ,imposta_erariale_acconto  = null
                where oggetto_imposta   = rec_ogco.oggetto_imposta
                      ;
             exception
               when others then
                 w_errore := 'Errore in aggiornamento Oggetti Imposta (Altri Fabb.2 - Mini IMU)'||
                             ' ('||sqlerrm||')';
                 raise errore;
             end;

          end if;
       else
          w_altri_rec         := nvl(f_round(w_altri_rec,0),0);
          w_acconto_altri_rec := f_round(w_acconto_altri_rec,0);
          w_altri_erar_rec         := nvl(round(w_altri_erar_rec,2),0);
          w_acconto_altri_erar_rec := round(w_acconto_altri_erar_rec,2);
          -- (VD - 27/10/2020): Calcolo importo IMU a saldo come da
          --                    D.L. 14 agosto 2020, n. 104
          w_note_saldo := null;
          CALCOLO_IMU_SALDO ( w_tipo_tributo
                            , w_anno
                            , rec_ogco.tipo_aliquota_ogim
                            , w_altri_rec
                            , w_acconto_altri_rec
                            , w_altri_erar_rec
                            , w_acconto_altri_erar_rec
                            , w_perc_saldo
                            , w_imposta_saldo
                            , w_imposta_saldo_erar
                            , w_note_saldo
                            );
          if w_perc_saldo is not null then
             w_altri_rec      := w_imposta_saldo;
             w_altri_erar_rec := w_imposta_saldo_erar;
          end if;
          begin
            update oggetti_imposta
               set imposta           = w_altri_rec
                 , imposta_acconto   = w_acconto_altri_rec
                 , imposta_erariale          = w_altri_erar_rec
                 , imposta_erariale_acconto  = w_acconto_altri_erar_rec
                 , note              = w_note_saldo
             where oggetto_imposta   = rec_ogco.oggetto_imposta
             ;
            w_perc_occupante_ricalcolo := w_perc_occupante;
            if f_ricalcolo_tasi_per_affitto(w_tipo_tributo,
                                            rec_ogco.tipo_rapporto,
                                            rec_ogco.oggetto,
                                            rec_ogco.flag_al_ridotta,
                                            'N',
                                            w_cod_fiscale,
                                            w_anno,
                                            w_perc_occupante_ricalcolo,
                                            w_altri_rec,
                                            w_acconto_altri_rec,
                                            w_altri_erar_rec,
                                            w_acconto_altri_erar_rec) then
               update oggetti_imposta
                  set imposta_pre_perc            = imposta
                     ,imposta_acconto_pre_perc    = imposta_acconto
                     ,percentuale                 = w_perc_occupante_ricalcolo
                     ,tipo_rapporto               = rec_ogco.tipo_rapporto
                     ,imposta                     = w_altri_rec
                     ,imposta_acconto             = w_acconto_altri_rec
                     ,imposta_erariale            = w_altri_erar_rec
                     ,imposta_erariale_acconto    = w_acconto_altri_erar_rec
               where oggetto_imposta   = rec_ogco.oggetto_imposta
               ;
            end if;
          exception
             when others then
                w_errore := 'Errore in aggiornamento Oggetti Imposta (Altri Fabb.2 - IMU)'||
                            ' ('||sqlerrm||')';
                raise errore;
          end;
       end if;
       w_num_fabbricati_altri := w_num_fabbricati_altri + 1;
       w_acconto_altri     := nvl(w_acconto_altri,0) +
                              nvl(w_acconto_altri_rec,0);
       w_saldo_altri   := nvl(w_saldo_altri,0) +
                          nvl(w_altri_rec,0)     -
                          nvl(w_acconto_altri_rec,0);
       w_acconto_altri_erar := nvl(w_acconto_altri_erar,0) +
                               nvl(w_acconto_altri_erar_rec,0);
       w_saldo_altri_erar   := nvl(w_saldo_altri_erar,0) +
                               nvl(w_altri_erar_rec,0) -
                               nvl(w_acconto_altri_erar_rec,0);

       w_altri_rec         := 0;
       w_acconto_altri_rec := 0;
       w_altri_erar_rec         := 0;
       w_acconto_altri_erar_rec := 0;
       w_altri_std_rec          := 0;
       w_acconto_altri_std_rec  := 0;
    end if;
  end loop;

  wf := 9;
  if w_anno >= 2000 then
     begin
       select decode(sign(f_round(nvl(w_acconto_pertinenze,0) -
                                  nvl(w_diff_acconto_det,0),0)
                         )
                    ,1,f_round(nvl(w_acconto_pertinenze,0) -
                               nvl(w_diff_acconto_det,0),0)
                      ,0
                    )
             ,nvl(w_acconto_detrazioni,0) +
              decode(sign(f_round(nvl(w_acconto_pertinenze,0) -
                                  nvl(w_diff_acconto_det,0),0)
                         )
                    ,1,f_round(nvl(w_diff_acconto_det,0),0)
                      ,f_round(nvl(w_acconto_pertinenze,0),0)
                    )
             ,decode(sign(f_round(nvl(w_saldo_pertinenze,0) -
                                  nvl(w_diff_saldo_det,0),0)
                         )
                    ,1,f_round(nvl(w_saldo_pertinenze,0) -
                               nvl(w_diff_saldo_det,0),0)
                      ,0
                    )
             ,nvl(w_saldo_detrazioni,0) +
              decode(sign(f_round(nvl(w_saldo_pertinenze,0) -
                                  nvl(w_diff_saldo_det,0),0)
                         )
                    ,1,f_round(nvl(w_diff_saldo_det,0),0)
                      ,f_round(nvl(w_saldo_pertinenze,0),0)
                    )
         into w_acconto_pertinenze
             ,w_acconto_detrazioni
             ,w_saldo_pertinenze
             ,w_saldo_detrazioni
         from dual
         ;
     exception
       when others then
         null;
     end;
     -- DA QUI LE VAR CHIAMATE SALDO NON SI RIFERISCONO ALL'IMPORTO DEL SALDO MA AL TOTALE (SALDO + ACCONTO)
     w_diff_saldo_det   := w_diff_saldo_det   + w_diff_acconto_det;
     w_saldo_abitazioni := w_saldo_abitazioni + w_acconto_abitazioni;
     w_saldo_detrazioni := w_saldo_detrazioni + w_acconto_detrazioni;
     wf := 10;
     if w_diff_acconto_det > 0 or w_diff_saldo_det > 0 then
        for rec_ogim in sel_ogim
        loop
        --CONSIDERO I RECORD CHE HANNO ANCORA UN RESIDUO DI IMPOSTA A CUI APPLICARE LA DETRAZIONE CHE ANCORA MI RIMANE
          if nvl(rec_ogim.imposta,0) /*- nvl(rec_ogim.imposta_acconto,0)*/ > nvl(rec_ogim.detrazione,0)/* - nvl(rec_ogim.detrazione_acconto,0) */ then
             if w_diff_saldo_det > 0 then
                w_valore :=
                least(nvl(rec_ogim.imposta,0) /*- nvl(rec_ogim.imposta_acconto,0)*/  - nvl(rec_ogim.detrazione,0) /*- nvl(rec_ogim.detrazione_acconto,0)*/
                     ,w_diff_saldo_det
                     );

                update oggetti_imposta
                   set detrazione      = nvl(detrazione,0) + w_valore --+ nvl(rec_ogim.detrazione_acconto,0)
                     , imposta         = nvl(imposta,0) - w_valore -- - nvl(rec_ogim.detrazione_acconto,0)
                 where oggetto_imposta = rec_ogim.oggetto_imposta
                ;
                w_diff_saldo_det := w_diff_saldo_det - w_valore;
                w_saldo_abitazioni := nvl(w_saldo_abitazioni,0) - w_valore;
                w_saldo_detrazioni := nvl(w_saldo_detrazioni,0) + w_valore;
             end if;
          end if;
          if nvl(rec_ogim.imposta_acconto,0) > nvl(rec_ogim.detrazione_acconto,0) then
             if w_diff_acconto_det > 0 then
                w_valore :=
                least(nvl(rec_ogim.imposta_acconto,0) - nvl(rec_ogim.detrazione_acconto,0)
                     ,w_diff_acconto_det
                     );
                update oggetti_imposta
                   set detrazione_acconto = nvl(detrazione_acconto,0) + w_valore
                     , imposta_acconto    = least(nvl(imposta_acconto,0) - w_valore,nvl(imposta,0))
                    /* , detrazione = nvl(detrazione,0) + w_valore
                     , imposta    = nvl(imposta,0) + least(nvl(imposta_acconto,0) - w_valore,nvl(imposta,0))*/
                 where oggetto_imposta    = rec_ogim.oggetto_imposta
                ;
                w_diff_acconto_det := w_diff_acconto_det - w_valore;
                w_acconto_abitazioni := nvl(w_acconto_abitazioni,0) - w_valore;
                w_acconto_detrazioni := nvl(w_acconto_detrazioni,0) + w_valore;
             end if;
          end if;
        end loop;
     end if;
  end if;
  --
  -- Mini IMU: si controlla se ci sono detrazioni residue da applicare alle pertinenze
  --
  if nvl(a_tipo_calcolo,' ') = 'Mini' and
     nvl(w_diff_saldo_std_det,0) > 0 then
     for rec_ogim in sel_ogim
     loop
       -- Si trattano i record con un residuo di imposta a cui applicare la detrazione rimasta
       if nvl(rec_ogim.imposta_std,0) > nvl(rec_ogim.detrazione_std,0) then
          if w_diff_saldo_std_det > 0 then
             w_valore :=
             least(nvl(rec_ogim.imposta_std,0) - nvl(rec_ogim.detrazione_std,0)
                  ,w_diff_saldo_std_det
                  );

             update oggetti_imposta
                set detrazione_std  = nvl(detrazione_std,0) + w_valore
                  , imposta_std     = nvl(imposta_std,0) - w_valore
                  , imposta         = round((nvl(imposta_aliquota,0) - (nvl(imposta_std,0) - w_valore)) * 0.4 ,2)
                  , imposta_mini    = round((nvl(imposta_aliquota,0) - (nvl(imposta_std,0) - w_valore)) * 0.4 ,2)
              where oggetto_imposta = rec_ogim.oggetto_imposta
             ;
             w_diff_saldo_std_det   := w_diff_saldo_std_det - w_valore;
             w_saldo_abitazioni_std := nvl(w_saldo_abitazioni_std,0) - w_valore;
             w_saldo_detrazioni_std := nvl(w_saldo_detrazioni_std,0) + w_valore;
          end if;
       end if;
     end loop;
  end if;
  --
  -- Inserimento di nuovo contatto contribuente e aggiornamento della data della pratica
  --
  wf := 11;
  if w_cod_fiscale is null then --In caso di tutti oggetti esenti
     begin
       select max(ogco.cod_fiscale)
            , max(prtr.anno)
            , max(prtr.utente)
         into w_cod_fiscale
            , w_anno
            , w_utente
         from pratiche_tributo     prtr
            , oggetti_pratica      ogpr
            , oggetti_contribuente ogco
        where prtr.pratica = ogpr.pratica
          and ogpr.oggetto_pratica = ogco.oggetto_pratica
          and prtr.pratica  = a_pratica
            ;
     exception
        when others then
           w_errore := 'Errore in recupero cod_fiscale (tutti oggetti esenti)'||
                       ' ('||sqlerrm||')';
              raise errore;
     end;
  end if;

  if w_utente != 'WEB' then  -- per evitare che venga inserito quando si fa un calcolo web
     begin
       select 1
         into w_esiste_coco
         from contatti_contribuente
        where cod_fiscale      = w_cod_fiscale
          and anno             = w_anno
          and tipo_contatto    = 4
          and tipo_richiedente = 2
          and data             = trunc(sysdate)
          and tipo_tributo     = w_tipo_tributo
       ;
     exception
        when no_data_found then
           w_esiste_coco := 0;
        when too_many_rows then
           w_esiste_coco := 1;
     end;
     begin
        if w_esiste_coco = 0 then
           insert into contatti_contribuente
                 (cod_fiscale,anno,tipo_contatto,tipo_richiedente,data,tipo_tributo)
           values(w_cod_fiscale,w_anno,4,2,trunc(sysdate),w_tipo_tributo)
           ;
        end if;
        update pratiche_tributo
           set data    = trunc(sysdate)
         where pratica = a_pratica
        ;
     END;
  end if;

  if w_anno < 2012 then
     w_acconto_altri := nvl(w_acconto_altri,0) + nvl(w_acconto_pertinenze,0);
     w_saldo_altri   := nvl(w_saldo_altri,0)   + nvl(w_saldo_pertinenze,0);
  end if;
--
-- Calcolo versamenti
--
  if nvl(a_flag_versamenti,'N') = 'S' and
     nvl(a_tipo_calcolo,' ') <> 'Mini' then
     begin
        select sum(terreni_agricoli)
               +   f_importo_vers_ravv_dett(cod_fiscale
                                           ,'ICI'
                                           ,anno
                                           ,'U'
                                           ,'TEC'
                                           ,trunc(sysdate)
                                           )
               +   f_importo_vers_ravv_dett(cod_fiscale
                                           ,'ICI'
                                           ,anno
                                           ,'U'
                                           ,'TEE'
                                           ,trunc(sysdate)
                                           ),
               sum(terreni_erariale)
               +   f_importo_vers_ravv_dett(cod_fiscale
                                           ,'ICI'
                                           ,anno
                                           ,'U'
                                           ,'TEE'
                                           ,trunc(sysdate)
                                           ),
               sum(aree_fabbricabili)
               +   f_importo_vers_ravv_dett(cod_fiscale
                                           ,'ICI'
                                           ,anno
                                           ,'U'
                                           ,'ARC'
                                           ,trunc(sysdate)
                                           )
               +   f_importo_vers_ravv_dett(cod_fiscale
                                           ,'ICI'
                                           ,anno
                                           ,'U'
                                           ,'ARE'
                                           ,trunc(sysdate)
                                           ),
               sum(aree_erariale)
               +   f_importo_vers_ravv_dett(cod_fiscale
                                           ,'ICI'
                                           ,anno
                                           ,'U'
                                           ,'ARE'
                                           ,trunc(sysdate)
                                           ),
               sum(ab_principale)
               +   f_importo_vers_ravv_dett(cod_fiscale
                                           ,'ICI'
                                           ,anno
                                           ,'U'
                                           ,'ABP'
                                           ,trunc(sysdate)
                                           ),
               sum(rurali)
               +   f_importo_vers_ravv_dett(cod_fiscale
                                           ,'ICI'
                                           ,anno
                                           ,'U'
                                           ,'RUR'
                                           ,trunc(sysdate)
                                           ),
               sum(altri_fabbricati)
               +   f_importo_vers_ravv_dett(cod_fiscale
                                           ,'ICI'
                                           ,anno
                                           ,'U'
                                           ,'ALC'
                                           ,trunc(sysdate)
                                           )
               +   f_importo_vers_ravv_dett(cod_fiscale
                                           ,'ICI'
                                           ,anno
                                           ,'U'
                                           ,'ALE'
                                           ,trunc(sysdate)
                                           ),
               sum(altri_erariale)
               +   f_importo_vers_ravv_dett(cod_fiscale
                                           ,'ICI'
                                           ,anno
                                           ,'U'
                                           ,'ALE'
                                           ,trunc(sysdate)
                                           ),
               sum(fabbricati_d)
               +   f_importo_vers_ravv_dett(cod_fiscale
                                           ,'ICI'
                                           ,anno
                                           ,'U'
                                           ,'FDC'
                                           ,trunc(sysdate)
                                           )
               +   f_importo_vers_ravv_dett(cod_fiscale
                                           ,'ICI'
                                           ,anno
                                           ,'U'
                                           ,'FDE'
                                           ,trunc(sysdate)
                                           ),
               sum(fabbricati_d_erariale)
               +   f_importo_vers_ravv_dett(cod_fiscale
                                           ,'ICI'
                                           ,anno
                                           ,'U'
                                           ,'FDE'
                                           ,trunc(sysdate)
                                           ),
               sum(fabbricati_merce)
               +   f_importo_vers_ravv_dett(cod_fiscale
                                           ,'ICI'
                                           ,anno
                                           ,'U'
                                           ,'FAM'
                                           ,trunc(sysdate)
                                           )
          into w_terreni_agricoli, w_terreni_erario,
               w_aree_fabbricabili, w_aree_erario,
               w_ab_principale, w_rurali,
               w_altri_fabbricati, w_altri_erario,
               w_fabbricati_d, w_fabb_d_erario,
               w_fabb_merce
          from versamenti
         where tipo_tributo = w_tipo_tributo
           and anno         = w_anno
           and cod_fiscale  = w_cod_fiscale
           and pratica is null
         group by cod_fiscale,anno;
     exception
       when others then
         w_terreni_agricoli:= 0;
         w_terreni_erario:= 0;
         w_aree_fabbricabili:= 0;
         w_aree_erario:= 0;
         w_ab_principale:= 0;
         w_rurali:= 0;
         w_altri_fabbricati:= 0;
         w_altri_erario:= 0;
         w_fabbricati_d:= 0;
         w_fabb_d_erario:= 0;
         w_fabb_merce:= 0;
     end;
     --
     if nvl(w_terreni_agricoli,0) > 0 and
        nvl(w_acconto_terreni,0) > 0 then
        w_saldo_terreni := nvl(w_saldo_terreni,0) - (w_terreni_agricoli - nvl(w_acconto_terreni,0));
        w_acconto_terreni := w_terreni_agricoli;
     end if;
     if nvl(w_terreni_erario,0) > 0 and
        nvl(w_acconto_terreni_erar,0) > 0 then
        w_saldo_terreni_erar := nvl(w_saldo_terreni_erar,0) - (w_terreni_erario - nvl(w_acconto_terreni_erar,0));
        w_acconto_terreni_erar := w_terreni_erario;
     end if;
     if nvl(w_aree_fabbricabili,0) > 0 and
        nvl(w_acconto_aree,0) > 0 then
        w_saldo_aree := nvl(w_saldo_aree,0) - (w_aree_fabbricabili - nvl(w_acconto_aree,0));
        w_acconto_aree := w_aree_fabbricabili;
     end if;
     if nvl(w_aree_erario,0) > 0 and
        nvl(w_acconto_aree_erar,0) > 0 then
        w_saldo_aree_erar := nvl(w_saldo_aree_erar,0) - (w_aree_erario - nvl(w_acconto_aree_erar,0));
        w_acconto_aree_erar := w_aree_erario;
     end if;
     if nvl(w_ab_principale,0) > 0 and
        nvl(w_acconto_abitazioni,0) > 0 then
        w_saldo_abitazioni := nvl(w_saldo_abitazioni,0) - (w_ab_principale - nvl(w_acconto_abitazioni,0));
        w_acconto_abitazioni := w_ab_principale;
     end if;
     if nvl(w_rurali,0) > 0 and
        nvl(w_acconto_rurali,0) > 0 then
        w_saldo_rurali := nvl(w_saldo_rurali,0) - (w_rurali - nvl(w_acconto_rurali,0));
        w_acconto_rurali := w_rurali;
     end if;
     if nvl(w_altri_fabbricati,0) > 0 and
        nvl(w_acconto_altri,0) > 0 then
        w_saldo_altri := nvl(w_saldo_altri,0) - (w_altri_fabbricati - nvl(w_acconto_altri,0));
        w_acconto_altri := w_altri_fabbricati;
     end if;
     if nvl(w_altri_erario,0) > 0 and
        nvl(w_acconto_altri_erar,0) > 0 then
        w_saldo_altri_erar := nvl(w_saldo_altri_erar,0) - (w_altri_erario - nvl(w_acconto_altri_erar,0));
        w_acconto_altri_erar := w_altri_erario;
     end if;
     if nvl(w_fabbricati_d,0) > 0 and
        nvl(w_acconto_uso_prod,0) > 0 then
        w_saldo_uso_prod := nvl(w_saldo_uso_prod,0) - (w_fabbricati_d - nvl(w_acconto_uso_prod,0));
        w_acconto_uso_prod := w_fabbricati_d;
     end if;
     if nvl(w_fabb_d_erario,0) > 0 and
        nvl(w_acconto_uso_prod_erar,0) > 0 then
        w_saldo_uso_prod_erar := nvl(w_saldo_uso_prod_erar,0) - (w_fabb_d_erario - nvl(w_acconto_uso_prod_erar,0));
        w_acconto_uso_prod_erar := w_fabb_d_erario;
     end if;
     if nvl(w_fabb_merce,0) > 0 and
        nvl(w_acconto_fabb_merce,0) > 0 then
        w_saldo_fabb_merce := nvl(w_saldo_fabb_merce,0) - (w_fabb_merce - nvl(w_acconto_fabb_merce,0));
        w_acconto_fabb_merce := w_fabb_merce;
     end if;
  else
     w_terreni_agricoli       := to_number(null);
     w_terreni_erario         := to_number(null);
     w_aree_fabbricabili      := to_number(null);
     w_aree_erario            := to_number(null);
     w_ab_principale          := to_number(null);
     w_rurali                 := to_number(null);
     w_altri_fabbricati       := to_number(null);
     w_altri_erario           := to_number(null);
     w_fabbricati_d           := to_number(null);
     w_fabb_d_erario          := to_number(null);
     w_fabb_merce             := to_number(null);
  end if;
--
-- Assegnazione Variabili di Output.
--
  if nvl(a_tipo_calcolo,' ') = 'Mini' then
     a_dep_terreni             := null;
     a_acconto_terreni         := 0;
     a_saldo_terreni           := round((nvl(w_saldo_terreni,0) - nvl(w_saldo_terreni_std,0)) * 0.4 ,2);
     a_dep_aree                := null;
     a_acconto_aree            := 0;
     a_saldo_aree              := 0;
     a_dep_ab                  := null;
     a_acconto_ab              := 0;
     a_saldo_ab                := round((nvl(w_saldo_abitazioni,0) - nvl(w_saldo_abitazioni_std,0)) * 0.4 ,2);
     a_dep_altri               := null;
     a_acconto_altri           := 0;
     a_saldo_altri             := round((nvl(w_saldo_altri,0) - nvl(w_saldo_altri_std,0)) * 0.4 ,2);
     a_acconto_detrazione      := 0;
     a_saldo_detrazione        := nvl(w_saldo_detrazioni,0);
     a_totale_terreni          := 0;
     a_numero_fabbricati       := nvl(w_num_fabbricati_ab,0) + nvl(w_num_fabbricati_altri,0) + nvl(w_num_fabbricati_uso_prod,0);
     a_num_fabbricati_ab       := nvl(w_num_fabbricati_ab,0);
     a_num_fabbricati_rurali   := 0;
     a_num_fabbricati_altri    := nvl(w_num_fabbricati_altri,0);
     a_acconto_terreni_erar    := 0;
     a_saldo_terreni_erar      := 0;
     a_acconto_aree_erar       := 0;
     a_saldo_aree_erar         := 0;
     a_acconto_altri_erar      := 0;
     a_saldo_altri_erar        := 0;
     a_dep_rurali              := null;
     a_acconto_rurali          := 0;
     a_saldo_rurali            := 0;
     a_acconto_uso_prod        := 0;
     a_saldo_uso_prod          := round((nvl(w_saldo_uso_prod,0) - nvl(w_saldo_uso_prod_std,0)) * 0.4 ,2);
     a_num_fabbricati_uso_prod := nvl(w_num_fabbricati_uso_prod,0);
     a_acconto_uso_prod_erar   := 0;
     a_saldo_uso_prod_erar     := 0;
     a_saldo_detrazione_std    := nvl(w_saldo_detrazioni_std,0);
     a_acconto_fabb_merce      := to_number(null);
     a_saldo_fabb_merce        := to_number(null);
     a_num_fabbricati_merce    := to_number(null);
     a_dep_uso_prod            := to_number(null);
     a_dep_uso_prod_erar       := to_number(null);
     a_dep_terreni_erar        := to_number(null);
     a_dep_aree_erar           := to_number(null);
     a_dep_altri_erar          := to_number(null);
     a_dep_fabb_merce          := to_number(null);
  else
     a_dep_terreni             := w_terreni_agricoli;  --null;
     a_acconto_terreni         := nvl(w_acconto_terreni,0);
     a_saldo_terreni           := nvl(w_saldo_terreni,0);
     a_dep_aree                := w_aree_fabbricabili;   --null;
     a_acconto_aree            := nvl(w_acconto_aree,0);
     a_saldo_aree              := nvl(w_saldo_aree,0);
     a_dep_ab                  := w_ab_principale;      --null;
     a_acconto_ab              := nvl(w_acconto_abitazioni,0);
     a_saldo_ab                := nvl(w_saldo_abitazioni,0) - a_acconto_ab;
     a_dep_altri               := w_altri_fabbricati;   --null;
     a_acconto_altri           := nvl(w_acconto_altri,0);
     a_saldo_altri             := nvl(w_saldo_altri,0);
     a_acconto_detrazione      := nvl(w_acconto_detrazioni,0);
     a_saldo_detrazione        := nvl(w_saldo_detrazioni,0) - a_acconto_detrazione;
     a_totale_terreni          := nvl(w_tot_terreni_con_rid,0);
     a_numero_fabbricati       := nvl(w_numero_fabbricati,0);
     a_num_fabbricati_ab       := nvl(w_num_fabbricati_ab,0);
     a_num_fabbricati_rurali   := nvl(w_num_fabbricati_rurali,0);
     a_num_fabbricati_altri    := nvl(w_num_fabbricati_altri,0);
     a_acconto_terreni_erar    := nvl(w_acconto_terreni_erar,0);
     a_saldo_terreni_erar      := nvl(w_saldo_terreni_erar,0);
     a_acconto_aree_erar       := nvl(w_acconto_aree_erar,0);
     a_saldo_aree_erar         := nvl(w_saldo_aree_erar,0);
     a_acconto_altri_erar      := nvl(w_acconto_altri_erar,0);
     a_saldo_altri_erar        := nvl(w_saldo_altri_erar,0);
     a_dep_rurali              := w_rurali; --null;
     a_acconto_rurali          := nvl(w_acconto_rurali,0);
     a_saldo_rurali            := nvl(w_saldo_rurali,0);
     a_acconto_uso_prod        := nvl(w_acconto_uso_prod,0);
     a_saldo_uso_prod          := nvl(w_saldo_uso_prod,0);
     a_num_fabbricati_uso_prod := nvl(w_num_fabbricati_uso_prod,0);
     a_acconto_uso_prod_erar   := nvl(w_acconto_uso_prod_erar,0);
     a_saldo_uso_prod_erar     := nvl(w_saldo_uso_prod_erar,0);
     a_saldo_detrazione_std    := 0;
     a_acconto_fabb_merce      := nvl(w_acconto_fabb_merce,0);
     a_saldo_fabb_merce        := nvl(w_saldo_fabb_merce,0);
     a_num_fabbricati_merce    := nvl(w_num_fabbricati_merce,0);
     a_dep_uso_prod            := w_fabbricati_d;
     a_dep_uso_prod_erar       := w_fabb_d_erario;
     a_dep_terreni_erar        := w_terreni_erario;
     a_dep_aree_erar           := w_aree_erario;
     a_dep_altri_erar          := w_altri_erario;
     a_dep_fabb_merce          := w_fabb_merce;
  end if;
--  w_errore :=  'a_acconto_altri          '||a_acconto_terreni||
--   '  a_saldo_altri  '||a_saldo_uso_prod;
--     raise errore;
exception
  when errore then
       rollback;
       raise_application_error
    (-20999,w_errore);
  when others then
       rollback;
       raise_application_error
    (-20999,'Errore in calcolo individuale ('||to_char(wf)||')'||
       ' ('||sqlerrm||')');
end;
/* End Procedure: CALCOLO_INDIVIDUALE */
/
